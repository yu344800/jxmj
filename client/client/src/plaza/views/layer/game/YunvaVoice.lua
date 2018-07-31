local YunvaVoice = class("YunvaVoice", cc.Node)
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")

-- 登录状态标识
local LOGIN_ENUM = {
	NO_LOGIN			= 0,				-- 未登录
	IS_LOGIN			= 1,				-- 已登录
	LOGIN_FAILED		= 2,				-- 登录失败
}

-- 播放状态
local RECORD_ENUM = {
	STANBY 			= 10,					-- 未播放
	PLAYING 		= 11,					-- 播放中
	SPEAKING		= 12,					-- 录音中
}

-- 事件监听
YunvaVoice.NET_LISTENER = {
	"StartRecord",
	"StopRecord",
	"PushVoiceRequest",
}

function YunvaVoice:onExit()
end

-- 云娃语音
-- voice module 
function YunvaVoice:ctor()
	self:createMsgEventlistBinding()

	self:registerScriptHandler(function(eventType)
		if eventType == "enterTransitionFinish" then	-- 进入场景而且过渡动画结束时候触发。			
			self:onEnterTransitionFinish()			
		elseif eventType == "exitTransitionStart" then	-- 退出场景而且开始过渡动画时候触发。
			self:onExitTransitionStart()
		elseif eventType == "exit" then
			self:onExit()
		end
	end)

	
	-- 未登录标识
	self.LOGIN_STATE = LOGIN_ENUM.NO_LOGIN
	-- 播放状态
	self.RECORD_STATE = RECORD_ENUM.STANBY
	-- 登录失败 次数
	self._AutoLogin = 3

	-- 权限检查
	self.isCheckPermission = false
	
end

-- 登录
function YunvaVoice:login()

	if device.platform == "windows" then
		return
	end

	if voice == nil then
		return
	end

	local eventCallBackFuc = function(e, ...)
		-- 登录监听事件
		if e == "onLoginListern" then

			local ret = unpack({...})
			if ret == "ok" then
				-- 登录成功
				self.LOGIN_STATE = LOGIN_ENUM.IS_LOGIN
			else
				-- 登录失败
				self.LOGIN_STATE = LOGIN_ENUM.LOGIN_FAILED
				self:_autoLoginByLoginFailed()
				
			end

		-- 停止录音事件
		elseif e == "onStopRecordListern" then
			self:_uploadVoiceToServer(...)
			
		-- 上传录音完成事件
		elseif e == "onUpLoadFileListern" then
			local result, msg, tag, percent = unpack({...})
			if result == 0 then

				-- 要上传url的socket
				if self._socket ~= nil then
					msg = msg .. string.format(' %s', tag)
					self._socket(msg)
				else
					print("VoiceSocket is nil! didn't send data!")
				end
			else
				self:onVoiceToast("网络异常啦!语音发送失败...")
			end

		-- 录音播放完成事件
		elseif e == "onFinishPlayListern" then
			local result, msg, tag = unpack({...})
			self:_playRecordSuccess(tag)

		elseif e == "onDownloadVoiceListern" then

		end
		
	end

	voice.loginVoice(GlobalUserItem.szNickName, tostring(GlobalUserItem.dwUserID), eventCallBackFuc)

	self:checkPermission()

	-- 储存callback队列
	self.m_tableAniCallBack = {}
	
	-- 储存播放队列
	self.m_tablePlayVoice = {}
end

-- 开始录音
function YunvaVoice:onStartRecordListener()
	if self:checkLoginState(true) == false then return end

	-- 权限检查
	if self.isCheckPermission == false then
		self:checkPermission()
		return
	end

	if self:checkisPlaying() == true then
		voice.stopPlayVoice()
	end

	self.RECORD_STATE = RECORD_ENUM.SPEAKING

	self:onStartRecordAni()
	
	local nowtime = os.time()
	local filename = string.format('%d_%d_voice', GlobalUserItem.dwUserID, nowtime)
	filename = device.writablePath .. filename .. '.amr'

	AudioEngine.pause()
	voice.startVoice(filename, filename)
end


-- 停止录音
function YunvaVoice:onStopRecordListener()
	if self.RECORD_STATE ~= RECORD_ENUM.SPEAKING then return end

	self.RECORD_STATE = RECORD_ENUM.STANBY
	
	self:onStopRecordAni()
	voice.stopVoice()
	AudioEngine.resume()

	self:notifyVoiceQueue()
end


-- 上传语音
function YunvaVoice:_uploadVoiceToServer(...)
	local time, path, ext = unpack({...})
	local tag
	if time ~= nil then
		tag = string.format('time:%d', time)
	else
		tag = "12345"
	end

	voice.uploadVoice(path, tag)
end


-- 播放语音
function YunvaVoice:playRecordByUrl(url, key)

	voice.stopPlayVoice()
	
	voice.playFromUrl(url, key)
end


-- 播放完成
function YunvaVoice:_playRecordSuccess(key)
	
	if key ~= nil then
		self:stopAniCallBackByKey(key)
	end


	self:notifyVoiceQueue()
end

function YunvaVoice:stopAniCallBackByKey(key)
	local mdata = self.m_tableAniCallBack
	for i = #mdata, 1, -1 do
		local v = mdata[i]
		if v ~= nil then
			if v.key == key then
				if v.aniEndFunction ~= nil then
					v.aniEndFunction()
				end

				table.remove(mdata, i)
				break
			end
		end
	end
end

-- 播放请求
function YunvaVoice:onPushVoiceRequestListener(e)
	if device.platform == "windows" then
		return
	end

	local result = e.msg
	
	if result == nil or result.url == "" then
		print("Request data error")
		return
	end


	local url = result.url
	local uid = result.id
	local cb1 = result.startcb
	local cb2 = result.endcb
	
	
	if result.runningNow == true then

		voice.stopPlayVoice()
		-- voice.playFromUrl(url, "record")

		-- return
	end


	local time = tostring(os.time()) .. uid or ""

	local info = {
		key = time,
		requestUrl = url,
		aniStartFunction = cb1,
		aniEndFunction = cb2,
	}

	table.insert(self.m_tableAniCallBack, info)
	table.insert(self.m_tablePlayVoice, info) 

	if self:checkisPlaying() == true then return end
	self:notifyVoiceQueue()
end

-- 播放队列
function YunvaVoice:notifyVoiceQueue()
	if self.RECORD_STATE == RECORD_ENUM.SPEAKING then return end
	
	local mdata = self.m_tablePlayVoice

	local request

	for k,v in ipairs(mdata) do
		request = v
		table.remove(mdata, k)
	end

	if request ~= nil then
		if request.aniStartFunction ~= nil then
			request.aniStartFunction()
		end

		if self:checkisPlaying() == false then
			AudioEngine.pause()
			
			self.RECORD_STATE = RECORD_ENUM.PLAYING
		end
	
		self:playRecordByUrl(request.requestUrl, request.key)
	else

		if self:checkisPlaying() == true then
			self.RECORD_STATE = RECORD_ENUM.STANBY
			AudioEngine.resume()
		end
	
	end
end

-- 检测语音状态
function YunvaVoice:checkLoginState(isShow)
	-- 没有登录
	if self.LOGIN_STATE ~= LOGIN_ENUM.IS_LOGIN then
		if isShow ~= nil and isShow == true then
			self:onVoiceToast("网络繁忙,请稍后再试!")
		end
		return false
	end

	return true
end

-- 检测权限
function YunvaVoice:checkPermission()
	-- 权限检查
	local bRequest = cc.UserDefault:getInstance():getBoolForKey("recordpermissionreq",false)

	if false == bRequest then
		-- 权限请求
		if true == MultiPlatform:getInstance():checkRecordPermission() then
			cc.UserDefault:getInstance():setBoolForKey("recordpermissionreq",true)

			self.isCheckPermission = true
		
			return true
		end
		
	else
		self.isCheckPermission = true

		return true
	end

	self:onVoiceToast("当前未获得麦克风权限,无法进行语音聊天!")

	return false
end

-- 检测播放状态
function YunvaVoice:checkisPlaying()
	if self.RECORD_STATE ~= RECORD_ENUM.STANBY then 
		-- voice.stopPlayVoice()
		-- self.RECORD_STATE = RECORD_ENUM.STANBY
		return true
	end

	return false
end

-- 登录失败重试
function YunvaVoice:_autoLoginByLoginFailed()
	if self.autoLoginFuc ~= nil then
		display.unscheduleGlobal(self.autoLoginFuc)
	end

	if self._AutoLogin > 0 then
		self._AutoLogin = self._AutoLogin - 1
		
		-- self:showToastMsg("尝试重新登录语音.." .. self._AutoLogin)
	else

		return
	end

	local timeFuc = function()
		self:login()
		self.autoLoginFuc = nil
	end
	
	self.autoLoginFuc = display.performWithDelayGlobal(timeFuc, 3)
end


-- 开始动画
function YunvaVoice:onStartRecordAni()
    -- 加载csb资源
    local csbNode = ExternalFun.loadCSB("plaza/VoiceRecordLayer.csb", self)
    local ac = ExternalFun.loadTimeLine( "plaza/VoiceRecordLayer.csb" )
    ac:gotoFrameAndPlay(0,true)
    self:runAction(ac)

    local timeTips = csbNode:getChildByName("txt_tips")
    timeTips:setString("松开手指结束录音")
end

-- 移除
function YunvaVoice:onStopRecordAni()
	self:stopAllActions()
	self:removeAllChildren()
end

-- 显示错误信息
function YunvaVoice:onVoiceToast(msg)
	if type(msg) ~= "string" then
		msg = tostring(msg)
    end
    
	local runScene = cc.Director:getInstance():getRunningScene()
	if nil ~= runScene then
	
		showToastNoFade(runScene, msg, 2)
	end
end

-- 网络处理引用
function YunvaVoice:setSocketCallBack(cb)
	self._socket = cb
end

--[[
    事件派发
]]
function YunvaVoice:dispatchMessage(key, msg)
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

-- 事件注册
function YunvaVoice:createMsgEventlistBinding()
    local msglist = rawget(self.class, "NET_LISTENER")
    if not msglist or type(msglist) ~= "table" then return end

    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    
    for _, rpcName in ipairs(msglist) do

        local resp = string.format("on%sListener", rpcName)

        assert(self[resp], "event:%s has no callback.", rpcName)

        local customListenerBg = cc.EventListenerCustom:create(rpcName, handler(self, self[resp]))
        
        eventDispatcher:addEventListenerWithSceneGraphPriority(customListenerBg, self)
    end
end

return YunvaVoice
