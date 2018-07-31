
local BaseFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.BaseFrame")
local RecordFrame = class("RecordFrame",BaseFrame)
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")

-- 用户服务
RecordFrame.MDM_GP_USER_SERVICE				= 3									--用户服务

-- 战绩
RecordFrame.SUB_GR_QUERY_ROUND_RECORD     	= 410								-- 查询单局结算记录
RecordFrame.SUB_GR_QUERY_ROUND_RECORD_RESULT  = 411								-- 查询单局结算记录回包

RecordFrame.SUB_GR_QUERY_ROUND_OP_RECORD		= 412								-- 查询单局记录
RecordFrame.SUB_GR_QUERY_ROUND_OP_RECORD_RESULT = 413								-- 查询单局回放回包

-- start --
-- 查询单局结算记录
RecordFrame.CMD_GR_QueryRoundRecord = 
{
	{t = "dword", k = "dwRecordID"}
}

-- 个人信息
RecordFrame.gameRoundPersonalRecord = 
{
	{t = "string", k = "kNickName", s = 32},
	{t = "score", k = "lScore"},
	{t = "dword", k = "dwUserID"}
}

-- 结算记录
RecordFrame.GameRoundRecord = 
{
	{t = "dword", k = "dwRoundID"},
	{t = "table", k = "gameRoundPersonalRecord", d = RecordFrame.gameRoundPersonalRecord, l = {6}},
}

-- 查询单局结算记录回包
RecordFrame.CMD_GR_QueryRoundRecordResult = {
	{t = "table", k = "gameRoundRecord", d = RecordFrame.GameRoundRecord, l = {20}},
}
-- end --


-- start --
-- 查詢房間單局操作記錄
RecordFrame.CMD_GR_QueryRoundOPRecord =
{
	{t = "dword", k = "dwRecordID"},
	{t = "dword", k = "dwRoundID"},
}

-- 玩家信息
RecordFrame.tagGameRecordPlayer =
{
	{t = "dword", k = "dwUserID"},
	{t = "word", k = "wChairID"},
	{t = "score", k = "lScore"},
	{t = "dword", k = "dwCustomID"},
	{t = "string", k = "szNickName", s = 32},
}

-- 單局回放數據
RecordFrame.tagGameRecordOperateResult =
{
	{t = "byte", k = "cbActionType"},
	{t = "word", k = "wOperateUser"},
	{t = "word", k = "wProvideUser"},
	{t = "byte", k = "cbOperateCode"},
	{t = "byte", k = "cbOperateCard", l = {34}},
	{t = "byte", k = "cbOther", l = {34}},
}

-- end --

function RecordFrame:ctor(view, callback)
    RecordFrame.super.ctor(self, view, callback)
    
end

function RecordFrame:onConnect()
	if not self:onCreateSocket(yl.LOGONSERVER,yl.LOGONPORT) and nil ~= self._callBack then
		self._callBack(-1)
	end
	return self
end

function RecordFrame:onConnectCompeleted()
	self._callBack(0)
end


--网络信息
function RecordFrame:onSocketEvent(main,sub,pData)
	print("============RecordFrame:onSocketEvent============")
    print("*socket event:"..main.."#"..sub) 
    if sub == RecordFrame.SUB_GR_QUERY_ROUND_RECORD_RESULT then

		local cmddata = {}

		cmddata.gameRoundRecord = {}

		for i = 1, 20 do
			local v = ExternalFun.read_netdata(RecordFrame.GameRoundRecord, pData)
			
			if v.dwRoundID ~= 0 and v.dwRoundID <= 20 then
				table.insert(cmddata.gameRoundRecord, v)
			else
				break
			end
		end

		table.sort(cmddata.gameRoundRecord, function (a, b)
			if a.dwRoundID < b.dwRoundID then
				return true
			end
		end)

		cmddata.RecordID = self._sendRecordID

		self._callBack(sub, cmddata)
	elseif sub == RecordFrame.SUB_GR_QUERY_ROUND_OP_RECORD_RESULT then
				
		-- 操作數據
		-- RecordFrame.CMD_GR_QueryRoundRecordOpResult =
		-- {
			-- {t = "string", k = "wTableID", s = 7},
			-- {t = "dword", k = "dwOwner"},
			-- {t = "byte", k = "szTableAttr", l = {100}},
			-- {t = "dword", k = "dwActionCount"},
			-- {t = "table", k = "playerData", d = RecordFrame.tagGameRecordPlayer, l = {6}},
			-- {t = "table", k = "operateData", d = RecordFrame.tagGameRecordOperateResult, l = {200}}
		-- }

		local cmddata = {}

		local wTableID = pData:readstring(7)
		cmddata["wTableID"] = wTableID
		
		local dwOwner = pData:readdword()
		cmddata["dwOwner"] = dwOwner

		local szTableAttr = {}
		for i = 1, 100 do
			local v = pData:readbyte()
			table.insert(szTableAttr, v)
		end
		cmddata["szTableAttr"] = szTableAttr
		

		local dwActionCount = pData:readdword()

		local playerData = {}

		for i = 1, 6 do
			local tagGameRecordPlayer = ExternalFun.read_netdata(RecordFrame.tagGameRecordPlayer, pData)
			table.insert(playerData, tagGameRecordPlayer)
		end
		cmddata["playerData"] = playerData
		

		local operateData = {}

		for i = 1, dwActionCount do
			local tagGameRecordOperateResult = ExternalFun.read_netdata(RecordFrame.tagGameRecordOperateResult, pData)
			table.insert(operateData, tagGameRecordOperateResult)
		end
		cmddata["operateData"] = operateData

		cmddata["RoundID"] = self._sendRoundId
		
		self._callBack(sub, cmddata)
    end
    -- self:onCloseSocket()
end


function RecordFrame:sendQueryRoundRecord(dwRecordID)
	local sendMsgData = ExternalFun.create_netdata(RecordFrame.CMD_GR_QueryRoundRecord)
	sendMsgData:setcmdinfo(RecordFrame.MDM_GP_USER_SERVICE, RecordFrame.SUB_GR_QUERY_ROUND_RECORD)
	sendMsgData:pushdword(dwRecordID)
	self._sendRecordID = dwRecordID
	
	if not self:sendSocketData(sendMsgData) then

	end
end

function RecordFrame:sendQueryRoundResult(dwRecordID ,dwRoundID)
	local sendMsgData = ExternalFun.create_netdata(RecordFrame.CMD_GR_QueryRoundOPRecord)
	sendMsgData:setcmdinfo(RecordFrame.MDM_GP_USER_SERVICE, RecordFrame.SUB_GR_QUERY_ROUND_OP_RECORD)
	sendMsgData:pushdword(dwRecordID)
	sendMsgData:pushdword(dwRoundID)

	self._sendRoundId = dwRoundID
	
	if not self:sendSocketData(sendMsgData) then

	end
end

return RecordFrame