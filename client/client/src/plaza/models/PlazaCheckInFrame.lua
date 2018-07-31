--[[
	签到接口
	2018_04_18 
]]

local BaseFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.BaseFrame")
local PlazaCheckInFrame = class("PlazaCheckInFrame",BaseFrame)
local logincmd = appdf.req(appdf.HEADER_SRC .. "CMD_LogonServer")
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")

function PlazaCheckInFrame:ctor(view,callbcak)
    PlazaCheckInFrame.super.ctor(self,view,callbcak)
    self._oprateCode = -1
    self._szMachine = MultiPlatform:getInstance():getMachineId()
end

PlazaCheckInFrame.QUERYCHECKIN          = 0                 --查询签到
PlazaCheckInFrame.CHECKININFO           = 1                 --签到信息
PlazaCheckInFrame.CHECKINDONE           = 2                 --执行签到
PlazaCheckInFrame.CHECKINRESULT         = 3                 --签到结果



--连接结果
function PlazaCheckInFrame:onConnectCompeleted()

	print("============Checkin onConnectCompeleted============")
	--print("PlazaCheckInFrame:onConnectCompeleted oprateCode="..self._oprateCode)

	if self._oprateCode == PlazaCheckInFrame.QUERYCHECKIN then			 --查询签到
		self:sendQueryCheckin()
       
    elseif self._oprateCode == PlazaCheckInFrame.CHECKINDONE then		 --执行签到
		self:sendCheckinDone()
		
	end

end



--网络信息
function PlazaCheckInFrame:onSocketEvent(main,sub,pData)
	print("============Checkin onSocketEvent============")
	print("*socket event:"..main.."#"..sub) 
	local bRes = false
	if main == logincmd.MDM_GP_USER_SERVICE then                        --用户服务
        
        if sub == logincmd.SUB_GP_CHECKIN_INFO then 					--签到信息
			bRes = self:onSubCheckinInfo(pData)
		elseif sub == logincmd.SUB_GP_CHECKIN_RESULT then 				--签到结果
			bRes = self:onSubCheckinResult(pData)
		else
			local message = string.format("未知命令码：%d-%d",main,sub)
			if nil ~= self._callBack then
				self._callBack(-1,message)
			end			
		end
	end

	if not bRes then
		self:onCloseSocket()
	end	
end


--查询签到
function PlazaCheckInFrame:sendQueryCheckin()
    local QueryCheckin = CCmd_Data:create(4)
    QueryCheckin:setcmdinfo(logincmd.MDM_GP_USER_SERVICE, logincmd.SUB_GP_CHECKIN_QUERY)	
    QueryCheckin:pushdword(GlobalUserItem.dwUserID)
    
 
   
    --发送失败
    if not self:sendSocketData(QueryCheckin) and nil ~= self._callBack then
        self._callBack(-1,"发送查询签到失败")
       
    end     

end 



--执行签到
function PlazaCheckInFrame:sendCheckinDone()

    local CheckinDone = CCmd_Data:create(4)
    CheckinDone:setcmdinfo(logincmd.MDM_GP_USER_SERVICE,logincmd.SUB_GP_CHECKIN_DONE)
    CheckinDone:pushdword(GlobalUserItem.dwUserID)
   


    --发送失败
    if  not  self:sendSocketData(CheckinDone) and nil ~= self._callBack then
        self._callBack(-1,"发送执行签到失败")

    end 
   
end 



--签到信息
function PlazaCheckInFrame:onSubCheckinInfo(pData)

	local cmddata = ExternalFun.read_netdata(logincmd.CMD_GP_CheckInInfo, pData)

	dump(cmddata)

	if nil ~= self._callBack then
        self._callBack("签到信息",cmddata)

    end 

end 




--签到结果
function PlazaCheckInFrame:onSubCheckinResult(pData)
    
	local cmddata = ExternalFun.read_netdata(logincmd.CMD_GP_CheckInResult,pData)	
	
	dump(cmddata)


	if nil ~= self._callBack then
	   
		self._callBack("签到结果",cmddata)

    end 


end 




--查询签到
function PlazaCheckInFrame:onQueryCheckin()
	--操作记录
	self._oprateCode = PlazaCheckInFrame.QUERYCHECKIN
	if not self:onCreateSocket(yl.LOGONSERVER,yl.LOGONPORT) and nil ~= self._callBack then
		self._callBack(-1,"建立连接失败！")
	end
end

--执行签到
function PlazaCheckInFrame:onCheckinDone()
    
    
    --操作记录
	self._oprateCode = PlazaCheckInFrame.CHECKINDONE
	if not self:onCreateSocket(yl.LOGONSERVER,yl.LOGONPORT) and nil ~= self._callBack then
		self._callBack(-1,"建立连接失败！")
	end
end

return PlazaCheckInFrame
