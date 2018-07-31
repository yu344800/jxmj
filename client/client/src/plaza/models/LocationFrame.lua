local chat_cmd = appdf.req(appdf.HEADER_SRC.."CMD_ChatServer")
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local cjson = appdf.req("cjson")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")

local LocationFrame = class("LocationFrame")

LocationFrame.NET_LISTENER = {
	"GetUserLocation"
}

function LocationFrame:ctor(view)
	self._viewFrame = view
	self:init()
	self:createMsgEventlistBinding()
end

function LocationFrame:init()
	if self.m_Socket then
		self.m_Socket:relaseSocket()
	end

	self.m_Socket = nil
    self.m_CallBack = nil;

	--断线自动重连次数
	self.m_nAutoLoginCount = 1

	--数据缓存队列(用户缓存网络异常时未发送的数据)
	self.m_sendCache = {}
end
--获取位置信息
function LocationFrame:getLocationInfo()
	if device.platform == "windows" then
		self:sendUpdateCoordinate(0, 0)
		return
	end
	
    local location = MultiPlatform:getInstance():getUserLocation()
    local info = cjson.decode(location)

    info.code = tonumber(info.code)
    info.la = tonumber(info.la)
    info.lo = tonumber(info.lo)

    if info.code ~= -1 then
        self:sendUpdateCoordinate(info.la, info.lo)
	else
		-- 发送默认坐标
		self:sendUpdateCoordinate(0, 0)
    end
end
--获取用户位置监听
function LocationFrame:onGetUserLocationListener(e)
    if PriRoom:getInstance():isCurrentGameOpenPri(GlobalUserItem.nCurGameKind) then
		local dwUserID = e.msg.dwUserID
		self:sendQueryUserLocation(dwUserID)
	end
end

--连接成功
function LocationFrame:onConnectCompeleted()
	self.m_Socket:setdelaytime(0)

	-- 发送登录
    self:login()
end

-- 设置sleep
function LocationFrame:setWaitTime( var )
	if nil ~= self.m_Socket then
		self.m_Socket:setwaittime(var)
	end
end

--网络消息回调
function LocationFrame:onSocketCallBack(pData)
	--无效数据
	if pData == nil or nil == self.m_Socket then 
		return
	end
	-- 连接命令
	local main = pData:getmain()
	local sub =pData:getsub()
	
	if main == yl.MAIN_SOCKET_INFO then 		--网络状态
		if sub == yl.SUB_SOCKET_CONNECT then
			self:onConnectCompeleted()
		elseif sub == yl.SUB_SOCKET_ERROR then	--网络错误			
			-- self:onSocketError(pData)
			self:reConnect()
		else
			self:onCloseSocket()
		end
	else		
		self:onSocketEvent(main,sub,pData);
	end
end

--网络信息
function LocationFrame:onSocketEvent(main,sub,pData)
	print("============LocationFrame:onSocketEvent============")
	print("*socket event:"..main.."#"..sub) 
	-- 登录信息
    if main == chat_cmd.MDM_GC_LOGON then

        if sub == chat_cmd.SUB_GC_LOGON_SUCCESS then
            -- dump("登录成功")
        elseif sub == chat_cmd.SUB_S_LOGON_FINISH then
            -- dump("登录完成")

            self:getLocationInfo()

            -- self:onCloseSocket()
        end
    -- 用户信息
    elseif main == chat_cmd.MDM_GC_USER then

        if sub == chat_cmd.SUB_GC_UPDATE_COORDINATE_ECHO then

            local cmddata = ExternalFun.read_netdata(chat_cmd.CMD_GC_Update_CoordinateEcho, pData)
            if cmddata.lErrorCode and cmddata.lErrorCode == 0 then

                -- dump("更新成功")
				-- self:dispatchMessage()
			end
			
        elseif sub == chat_cmd.SUB_GC_QUERY_NEARUSER_RESULT then
            -- dump("查询成功")

            local cmddata = ExternalFun.read_netdata(chat_cmd.CMD_GC_Query_NearuserResult, pData)
            if cmddata.cbUserCount > 0 then
                local userInfoTable = cmddata.NearUserInfo
                
                self:dispatchMessage("UpdateUserLocation", {dwUserID = userInfoTable.dwUserID, la = userInfoTable.dLatitude, lo = userInfoTable.dLongitude})
			end
		elseif sub == chat_cmd.SUB_GC_GET_USER_TITLE then
			local cmddata = ExternalFun.read_netdata(chat_cmd.CMD_GC_UserTitle, pData)
			dump(cmddata)
			local event = cc.EventCustom:new("UPDATE_USER_LEVEL")
			event.levelNum = cmddata.lKindScore
            event.dwUserID = cmddata.dwUserID
			cc.Director:getInstance():getEventDispatcher():dispatchEvent(event)
        end
	end
	
	self:popCacheMessage()
end

--网络错误
function LocationFrame:onSocketError(pData)	
	
	-- self:onCloseSocket()
	-- if not pData then
	-- 	print("网络断开！")
	-- elseif type(pData) == "string" then
	-- 	print(pData)
	-- else
	-- 	local errorcode = pData:readword()
	-- 	if errorcode == nil then
	-- 		print("网络断开！")
	-- 	elseif errorcode == 3 then
	-- 		print("网络连接超时, 请重试!")
	-- 	else
	-- 		print("网络错误，code："..errorcode)			
	-- 	end
	-- end

end

--好友登陆
function LocationFrame:login()
	local friendData = CCmd_Data:create()
	friendData:setcmdinfo(chat_cmd.MDM_GC_LOGON,chat_cmd.SUB_GC_MB_LOGON_USERID)
	friendData:pushdword(GlobalUserItem.dwUserID);
	friendData:pushstring(md5(GlobalUserItem.szPassword),yl.LEN_PASSWORD);
	friendData:pushstring("手机型号",chat_cmd.LEN_PHONE_MODE);

	if not self:sendSocketData(friendData) then
		print("LocationFrame:login 登录好友系统失败！！！")
		return
	end

end

-- 发送更新坐标
function LocationFrame:sendUpdateCoordinate(lLongitude, lLatitude)
	local sendMsgData = ExternalFun.create_netdata(chat_cmd.CMD_GC_Update_Coordinate)
	sendMsgData:setcmdinfo(chat_cmd.MDM_GC_USER,chat_cmd.SUB_GC_UPDATE_COORDINATE)
	sendMsgData:pushdword(GlobalUserItem.dwUserID)
	sendMsgData:pushdouble(lLongitude)
	sendMsgData:pushdouble(lLatitude)

	if not self:sendSocketData(sendMsgData) then
		print("发送更新坐标失败！");
		-- sendMsgData:retain()
		table.insert(self.m_sendCache, sendMsgData)
	end
end

-- 发送指定用户查询
function LocationFrame:sendQueryUserLocation( dwTargetUserID )
	local sendMsgData = ExternalFun.create_netdata(chat_cmd.CMD_GC_Query_Nearuser)
	sendMsgData:setcmdinfo(chat_cmd.MDM_GC_USER,chat_cmd.SUB_GC_QUERY_NEARUSER)
	sendMsgData:pushdword(GlobalUserItem.dwUserID)
	sendMsgData:pushdword(dwTargetUserID)
	if not self:sendSocketData(sendMsgData) then
		-- print("发送查询位置失败！");
		-- sendMsgData:retain()
		table.insert(self.m_sendCache, sendMsgData)
	end
end

--发送查询头号等级
function LocationFrame:sendQueryUserLevel(gameKind,userId)
	print(gameKind,userId)
	local sendMsgData = ExternalFun.create_netdata(chat_cmd.CMD_GC_QueryUserTitle)
	sendMsgData:setcmdinfo(chat_cmd.MDM_GC_USER,chat_cmd.SUB_GC_QUERY_USER_TITLE)
	sendMsgData:pushdword(gameKind)
	sendMsgData:pushdword(userId)
	if not self:sendSocketData(sendMsgData) then
        table.insert(self.m_sendCache,sendMsgData)
	end
	--SUB_GC_GET_USER_TITLE
end

--发送数据
function LocationFrame:sendSocketData(pData)
	-- dump(debug.traceback())
	if self.m_Socket == nil then
		return false
	end
	--self:showPopWait()
	if not self.m_Socket:sendData(pData) then
		--
		self:onCloseSocket()
		return false
	end
	return true
end

function LocationFrame:connect()

	if self:isConnected() then
		self:onCloseSocket()
	end

	self.m_Socket = CClientSocket:createSocket(function(pData)
		self:onSocketCallBack(pData)
	end)

	if not self.m_Socket:connectSocket(yl.LOGONSERVER,yl.FRIENDPORT, yl.VALIDATE) then
		--todo
		self:reConnect()
	end

	return self
end

--关闭网络
function LocationFrame:onCloseSocket()
	if self.m_Socket then
		self.m_Socket:relaseSocket()
		self.m_Socket = nil
	end
end

--判断是否有网络连接
function LocationFrame:isConnected(  )
	return nil ~= self.m_Socket
end

function LocationFrame:reConnect( )
	if self.m_nAutoLoginCount == 0 then return end

	self.m_nAutoLoginCount = self.m_nAutoLoginCount - 1
	self:connect()
end

--重置并断开网络连接
function LocationFrame:reSetAndDisconnect(  )
	self.m_nAutoLoginCount = 0
	self:onCloseSocket()
	--清空缓存
	for k,v in pairs(self.m_sendCache) do
		v:release()
	end
	self.m_sendCache = {}	
end

--处理缓存未发送消息
function LocationFrame:popCacheMessage()
	--处理未发送的缓存数据
	for k,v in pairs(self.m_sendCache) do
		if self:sendSocketData(v) then
			v:release()
			self.m_sendCache[k] = nil
		end
	end
end

-- 事件注册
function LocationFrame:createMsgEventlistBinding()
    local msglist = rawget(self.class, "NET_LISTENER")
    if not msglist or type(msglist) ~= "table" then return end

    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    
    for _, rpcName in ipairs(msglist) do

        local resp = string.format("on%sListener", rpcName)

        assert(self[resp], "event:%s has no callback.", rpcName)

        local customListenerBg = cc.EventListenerCustom:create(rpcName, handler(self, self[resp]))
        
        eventDispatcher:addEventListenerWithSceneGraphPriority(customListenerBg, self._viewFrame)
    end
end

function LocationFrame:dispatchMessage(key, msg)
    if type(key) ~= "string" then
        key = tostring(key)
    end
    
    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    local event = cc.EventCustom:new(key)
    if msg then
        event.msg = msg
    end
    eventDispatcher:dispatchEvent(event) 
end


return LocationFrame