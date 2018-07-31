local GameVideoBaseLayer = class("GameVideoBaseLayer", function()
    local GameVideoBaseLayer = cc.LayerColor:create(cc.c4b(0,0,0,0))
    return GameVideoBaseLayer
end)

-- 播放状态
local initVideoState = function(state, cb)
    local mState
    local notifyStateCallBack

    local set = function(state)
        mState = state
        if notifyStateCallBack then
            notifyStateCallBack(mState)
        end
    end

    local get = function()
        return mState
    end

    set(state)
    if cb then
        notifyStateCallBack = cb
        notifyStateCallBack(mState)
    end
    
    return set, get
end

-- 玩家
local initPlayerData = function(tb)
    local mPlayerData = {}

    for k,v in ipairs(tb.playerData) do
        if v.dwUserID == tb.dwOwner then v.dwOwner = true end
        table.insert(mPlayerData, v)
    end

    assert(#mPlayerData, 0)

    local get = function()

        return mPlayerData
    end

    return get
end

-- 规则
local initRuleData = function(tb)
    local mRuleData = {}

    for k,v in ipairs(tb.szTableAttr) do
        table.insert(mRuleData, v)
    end

    assert(#mRuleData, 0)

    local get = function()

        return mRuleData
    end

    return get
end


GameVideoBaseLayer.BT_PLAY = 1
GameVideoBaseLayer.BT_STOP = 2
GameVideoBaseLayer.BT_NEXT = 3
GameVideoBaseLayer.BT_LAST = 4
GameVideoBaseLayer.BT_BACK = 5

-- 速度
local SPEED_TAG = {
	TOO_SLOW	= 2.8,			-- 超慢
	SLOW 		= 2.1,			-- 慢速
	MEDIUM  	= 1.4 ,			-- 中速
	FAST 		= 0.7 ,			-- 快速
}

-- 播放状态
local REPLAY_STATE = {
	INIT 			= "init",			-- 初始化
	PLAY 			= "play",			-- 播放
	STOP 			= "stop",			-- 暂停
	PLAYFINISH		= "playfinish",			-- 播放完成
	RETREAT			= "retreat",			-- 上一个指令
	FORWARD			= "forward",			-- 下一个指令
}

function GameVideoBaseLayer:onEnterTransitionFinish()
    self:setVideoScheduler()
    return self
end

function GameVideoBaseLayer:onExitTransitionStart()
    self:unVideoScheduler()
    return self
end

function GameVideoBaseLayer:onExit()
end

function GameVideoBaseLayer:ctor(clientScene, params)
    self:registerScriptHandler(function(eventType)
        if eventType == "enterTransitionFinish" then	-- 进入场景而且过渡动画结束时候触发。			
            self:onEnterTransitionFinish()			
        elseif eventType == "exitTransitionStart" then	-- 退出场景而且开始过渡动画时候触发。
            self:onExitTransitionStart()
        elseif eventType == "exit" then
            self:onExit()
        end
    end)

    local layerTouch = function(eventType, x, y)
        return true
    end

    self:setTouchEnabled(true)
    self:setSwallowsTouches(true)
    self:registerScriptTouchHandler(layerTouch)
    
    self.clientScene_ = clientScene

    self.m_tableReplayData = self:loadReplayDataFile_(params)
    if self.m_tableReplayData == nil then
        showToast(self, "该录像初始化失败!即将返回大厅...", 2)

        display.performWithDelayGlobal(function()
            self:dismiss()
        end, 1.8)

        return
    end

    self.getPlayerData = initPlayerData(self.m_tableReplayData)
    self.getRuleData = initRuleData(self.m_tableReplayData)

    local csbNode = cc.CSLoader:createNode("video/GameVideoBaseLayer.csb")
                :addTo(self)

    self.layer_main = csbNode
    
    appdf.setNodeTagAndListener(csbNode, "back", GameVideoBaseLayer.BT_BACK, handler(self, self.dismiss))
    appdf.setNodeTagAndListener(csbNode, "next", GameVideoBaseLayer.BT_NEXT, handler(self, self.nextCommand))
                    :setTouchEnabled(false)
    appdf.setNodeTagAndListener(csbNode, "last", GameVideoBaseLayer.BT_NEXT, handler(self, self.lastCommand))
                    :setTouchEnabled(false)

    appdf.setNodeTagAndListener(csbNode, "play", GameVideoBaseLayer.BT_PLAY , handler(self, self.autoPlayVideo))

    appdf.setNodeTagAndListener(csbNode, "stop", GameVideoBaseLayer.BT_STOP, handler(self, self.stopPlay))
    
end

-- 播放状态监听
function GameVideoBaseLayer:initVideoState(cb)
    self.setVideoState_, self.getVideoState_ = initVideoState(0, cb)
end

function GameVideoBaseLayer:loadReplayDataFile_(params)
    local fullPath = string.format("%s\\recordfile\\%d_%d", device.writablePath, params.recordId, params.roundId)
    local fileUtils = cc.FileUtils:getInstance()
    if true == fileUtils:isFileExist(fullPath) then
        local data = fileUtils:getStringFromFile(fullPath)
        
        if data == "" then
            return nil
        end

        data = json.decode(data)  
        
        return data
    end
    
    return nil
end

function GameVideoBaseLayer:reset()
    self.m_opIndex = 0
    self.m_videoData =  self.m_tableReplayData.operateData
    self.m_maxIndex = #self.m_videoData
    self.m_roundId = self.m_tableReplayData.RoundID
    self.m_lastButtonState = true
    self.m_speed = SPEED_TAG.MEDIUM

    local node = appdf.getNodeByName(self.layer_main, "play")
    
    if node:isVisible() == false then
        node:setVisible(true)
        local node = appdf.getNodeByName(self.layer_main, "stop")
                        :setVisible(false)
    end

    local node = appdf.getNodeByName(self.layer_main, "next")

    if node:isTouchEnabled() == true then
        node:loadTexture("video/btn_forward.png")
        node:setTouchEnabled(false)
    end

    local node = appdf.getNodeByName(self.layer_main, "last")

    if node:isTouchEnabled() == true then
        node:loadTexture("video/btn_retreat_1.png")
        node:setTouchEnabled(false)
    end
end

function GameVideoBaseLayer:setButtonState_()
    if self.m_opIndex == 1 then
        local node = appdf.getNodeByName(self.layer_main, "next")

        if node:isTouchEnabled() == false then
            node:loadTexture("video/btn_forward.png")
            node:setTouchEnabled(true)
        end

        local node = appdf.getNodeByName(self.layer_main, "last")

        if node:isTouchEnabled() == true then
            node:loadTexture("video/btn_retreat_1.png")
            node:setTouchEnabled(false)
        end

    elseif self.m_opIndex > 1 then
        local node = appdf.getNodeByName(self.layer_main, "last")
        
        if node:isTouchEnabled() == false and self.m_lastButtonState == true then
            node:loadTexture("video/btn_retreat.png")
            node:setTouchEnabled(true)
        elseif self.m_lastButtonState == false then
            node:loadTexture("video/btn_retreat_1.png")
            node:setTouchEnabled(false)
        end

        if self.m_opIndex >= self.m_maxIndex then
            local node = appdf.getNodeByName(self.layer_main, "next")

            if node:isTouchEnabled() == true then
                node:loadTexture("video/btn_forward_1.png")
                node:setTouchEnabled(false)
            end

        elseif self.m_opIndex < self.m_maxIndex then
            local node = appdf.getNodeByName(self.layer_main, "next")

            if node:isTouchEnabled() == false then
                node:loadTexture("video/btn_forward.png")
                node:setTouchEnabled(true)
            end
        end
    end


    if self.getVideoState_() == REPLAY_STATE.PLAY then
        local node = appdf.getNodeByName(self.layer_main, "play")
    
        if node:isVisible() == true then
            node:setVisible(false)
            local node = appdf.getNodeByName(self.layer_main, "stop")
                            :setVisible(true)
        end
    end
end

-- 获取指令
function GameVideoBaseLayer:getVideoCommand(cb)
    -- print("getVideoCommand获取指令...")
	if self.getVideoState_() == REPLAY_STATE.FORWARD or self.getVideoState_() == REPLAY_STATE.PLAY then
		self.m_opIndex = self.m_opIndex + 1
    else
        self.m_opIndex = self.m_opIndex - 1
    end

    -- 设置按钮状态
    self:setButtonState_()

    if self.m_opIndex <= #self.m_videoData and self.m_opIndex > 0 then
        self:dispatchCommand(self.m_videoData[self.m_opIndex])
        
        if cb then
            cb()
        end
    else
        if self.getVideoState_() == REPLAY_STATE.RETREAT then
            
            if cb then
                cb()
            end
            return
        end

		-- 播放完成
		self:unVideoScheduler()
        self.setVideoState_(REPLAY_STATE.PLAYFINISH)
        self:reset()
    end
end

-- 自动播放
function GameVideoBaseLayer:autoPlayVideo()
    -- 启动定时器
	if self.getVideoState_() == REPLAY_STATE.PLAYFINISH or self.getVideoState_() == 0 then

		-- 初始化
        self:reset()

        self.setVideoState_(REPLAY_STATE.INIT)
        
    end
    
	self.setVideoState_(REPLAY_STATE.PLAY)
    

    local node = appdf.getNodeByName(self.layer_main, "stop")

    if node:isVisible() == false then
        node:setVisible(true)
        local node = appdf.getNodeByName(self.layer_main, "play")
                        :setVisible(false)
    end


    -- 获取指令
    self:getVideoCommand(function()
    
        -- 恢复定时器
        self:setVideoScheduler()
    end)
	
end

-- 停止
function GameVideoBaseLayer:stopPlay()
    self:unVideoScheduler()
    
	self.setVideoState_(REPLAY_STATE.STOP)

    local node = appdf.getNodeByName(self.layer_main, "play")
    
    if node:isVisible() == false then
        node:setVisible(true)
        local node = appdf.getNodeByName(self.layer_main, "stop")
                        :setVisible(false)
    end
end

-- 下一个指令
function GameVideoBaseLayer:nextCommand()
	if self.getVideoState_() == REPLAY_STATE.PLAY then
		self:unVideoScheduler()
    end

    self.setVideoState_(REPLAY_STATE.FORWARD)
    
    -- 获取指令
    self:getVideoCommand(function()
    
        -- 恢复定时器
        self:setVideoScheduler()
    end)
end

-- 上一个指令
function GameVideoBaseLayer:lastCommand()
    if self.getVideoState_() == REPLAY_STATE.PLAY then
		self:unVideoScheduler()
    end
    
    self.setVideoState_(REPLAY_STATE.RETREAT)
    
    -- 获取指令
    self:getVideoCommand(function()
        -- 恢复定时器
        self:setVideoScheduler()
    end)

end

-- 是否可以关闭上一个指令按钮
function GameVideoBaseLayer:onSetLastButtonBnable(v)
    self.m_lastButtonState = v
    self:setButtonState_()
end

-- 是否可以关闭下一个指令按钮
function GameVideoBaseLayer:onSetNextButtonBnable(v)
    self.m_nextButtonState = v

end

-- 分发指令
function GameVideoBaseLayer:dispatchCommand()
    print("notifyListener_接收指令...")
end

-- 设置定时器
function GameVideoBaseLayer:setVideoScheduler()
	self:unVideoScheduler()
	
    self.m_videoFuc = display.scheduleGlobal(function()
        
        if self.getVideoState_() ~= REPLAY_STATE.PLAY then
            self.setVideoState_(REPLAY_STATE.PLAY)
        end

        self:getVideoCommand()
    end, self.m_speed, false)
end

-- 取消定时器
function GameVideoBaseLayer:unVideoScheduler()
    if self.m_videoFuc then
        display.unscheduleGlobal(self.m_videoFuc)
        self.m_videoFuc = nil
    end
end

function GameVideoBaseLayer:dismiss(cb)
    self:runAction(
        cc.Sequence:create(
            cc.FadeOut:create(0),
            cc.CallFunc:create(function()
                self.clientScene_:onKeyBack()
            end)
        )
    )
end

return GameVideoBaseLayer