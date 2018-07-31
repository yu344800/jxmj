--[[	手游大厅界面
	2015_12_03 C.P
]]
local ClientScene = class('ClientScene', cc.load('mvc').ViewBase)

local PopWait = appdf.req(appdf.BASE_SRC .. 'app.views.layer.other.PopWait')

local Option = appdf.req(appdf.CLIENT_SRC .. 'plaza.views.layer.other.OptionLayer')

local GameListView = appdf.req(appdf.CLIENT_SRC .. 'plaza.views.layer.plaza.GameListLayer')

local RoomList = appdf.req(appdf.CLIENT_SRC .. 'plaza.views.layer.plaza.RoomListLayer')

local CheckinFrame = appdf.req(appdf.CLIENT_SRC .. 'plaza.models.CheckinFrame')
local LevelFrame = appdf.req(appdf.CLIENT_SRC .. 'plaza.models.LevelFrame')
local ShopDetailFrame = appdf.req(appdf.CLIENT_SRC .. 'plaza.models.ShopDetailFrame')
local TaskFrame = appdf.req(appdf.CLIENT_SRC .. 'plaza.models.TaskFrame')

local GameFrameEngine = appdf.req(appdf.CLIENT_SRC .. 'plaza.models.GameFrameEngine')
local LocationFrame = appdf.req(appdf.CLIENT_SRC .. 'plaza.models.LocationFrame')

local Room = appdf.req(appdf.CLIENT_SRC .. 'plaza.views.layer.room.RoomLayer')

local NewGameListLayer = appdf.req(appdf.CLIENT_SRC .. 'plaza.views.layer.plaza.NewGameListLayer')
local QueryDialog = appdf.req('base.src.app.views.layer.other.QueryDialog')

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. 'ExternalFun')
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. 'MultiPlatform')

ClientScene.WIDGET_TAG = {}
local WIDGET_TAG = ClientScene.WIDGET_TAG

-- 隐藏所有
ClientScene.ACTION_HIDE_ALL = 200
-- 隐藏顶部菜单
ClientScene.ACTION_HIDE_TOP = 201
-- 隐藏退出按钮
ClientScene.ACTION_HIDE_EXIT = 202
-- 隐藏底部菜单
ClientScene.ACTION_HIDE_BOTTOM = 203

cc.exports.g_NetWorkNotify = function(param)
    if type(param) == 'string' and param ~= '' then
        local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
        local event = cc.EventCustom:new('NetWorkState')

        -- 无网络状态
        if param == '0' then
            -- 已有网络状态
            event.msg = { netWorkState = 0 }
        elseif param == '1' then
            event.msg = { netWorkState = 1 }
        end
        eventDispatcher:dispatchEvent(event)
    end
end

local ClientConfig = appdf.req('base.src.app.models.ClientConfig')

-- 重写widget addTouchEventListener
local addTouchEventListener_ = ccui.Widget.addTouchEventListener

ccui.Widget.addTouchEventListener = function(tar, callback)
    addTouchEventListener_(
    tar,
    function(sender, state)
        local viewName = sender:getDescription()

        if state == 0 then
            --播放默认音效
            ExternalFun.playClickEffect()

            if viewName == 'ImageView' then
                sender:runAction(cc.ScaleTo:create(0.1, 0.9, 0.9))
            end
        elseif state == 2 or state == 3 then
            if viewName == 'ImageView' then
                sender:stopAllActions()
                sender:runAction(cc.Sequence:create(cc.ScaleTo:create(0.1, 1.1, 1.1), cc.ScaleTo:create(0.1, 1, 1)))
            end
        end

        callback(sender, state)
    end
    )
end

-- 进入场景而且过渡动画结束时候触发。
function ClientScene:onEnterTransitionFinish()
    -- 快捷输入
    if device.platform == 'windows' then
        self._windowsInput = ''

        local function keyboardReleased(keyCode, event)
            if keyCode == cc.KeyCode.KEY_R then
                --重置lua package
                for k, v in pairs(package.loaded) do
                    if k ~= nil then
                        if type(k) == 'string' then
                            if string.find(k, 'plaza.') ~= nil or string.find(k, 'game.') ~= nil then
                                package.loaded[k] = nil
                                appdf.req(k)
                                print('reload package:' .. k)
                            end
                        end
                    end
                end
                showToast(self, '已重置lua引用环境', 1.5)
                self:ExitClient()
                return
            end

            if keyCode == cc.KeyCode.KEY_DELETE then
                self._windowsInput = ''
                showToast(self, '已清除房间号', 1.5)
                return
            end

            local num = ''
            if cc.KeyCode.KEY_0 == keyCode then
                num = '0'
            elseif cc.KeyCode.KEY_1 == keyCode then
                num = '1'
            elseif cc.KeyCode.KEY_2 == keyCode then
                num = '2'
            elseif cc.KeyCode.KEY_3 == keyCode then
                num = '3'
            elseif cc.KeyCode.KEY_4 == keyCode then
                num = '4'
            elseif cc.KeyCode.KEY_5 == keyCode then
                num = '5'
            elseif cc.KeyCode.KEY_6 == keyCode then
                num = '6'
            elseif cc.KeyCode.KEY_7 == keyCode then
                num = '7'
            elseif cc.KeyCode.KEY_8 == keyCode then
                num = '8'
            elseif cc.KeyCode.KEY_9 == keyCode then
                num = '9'
            end

            if num == '' then
                return
            end

            self._windowsInput = self._windowsInput .. num
            showToast(self, self._windowsInput, 1.5)
            if string.len(self._windowsInput) == 6 then
                PriRoom:getInstance():getNetFrame():onSearchRoom(self._windowsInput)
                self._windowsInput = ''
            end
        end

        local listener = cc.EventListenerKeyboard:create()
        listener:registerScriptHandler(keyboardReleased, cc.Handler.EVENT_KEYBOARD_RELEASED)
        local eventDispatcher = self:getEventDispatcher()
        eventDispatcher:addEventListenerWithSceneGraphPriority(listener, self)
		if GlobalUserItem.dwLockServerID == 0 then
			 appdf.req(appdf.CLIENT_SRC .. 'plaza.views.layer.plaza.PlazaNoticeLayer'):create(self):addTo(self):show()
		end
	
	
	end

    if not GlobalUserItem.bIsAngentAccount then
        -- 	-- 查询赠送
        self._shopDetailFrame:onQuerySend()
    else
        if nil ~= self.m_touchFilter then
            self.m_touchFilter:dismiss()
            self.m_touchFilter = nil
        end
    end

    -- 设置用户头像
    local userAvatar = appdf.getNodeByName(self, 'user_avatar')

    local HeadSpriteHelper = appdf.req(appdf.EXTERNAL_SRC .. 'HeadSpriteHelper')
    HeadSpriteHelper:createClipMaskImg('plaza/plaza_mask.png', { dwUserID = GlobalUserItem.dwUserID }, userAvatar, 59)

    --请求公告
    self:requestNotice()
    return self
end

-- 退出场景而且开始过渡动画时候触发。
function ClientScene:onExitTransitionStart()
    self._sceneLayer:unregisterScriptKeypadHandler()


    return self
end

function ClientScene:onExit()
    if self._gameFrame:isSocketServer() then
        self._gameFrame:onCloseSocket()
    end
    self:disconnectFrame()

    -- ExternalFun.SAFE_RELEASE(self.m_actBoxAni)
    -- self.m_actBoxAni = nil
    -- ExternalFun.SAFE_RELEASE(self.m_actStartBtnAni)
    -- self.m_actStartBtnAni = nil
    -- ExternalFun.SAFE_RELEASE(self.m_actChargeBtnAni)
    -- self.m_actChargeBtnAni = nil
    -- ExternalFun.SAFE_RELEASE(self.m_actCoinAni)
    -- self.m_actCoinAni = nil
    -- self:releasePublicRes()
    self:removeListener()

    -- self:unregisterNotify()
    removebackgroundcallback()

    if PriRoom then
        PriRoom:getInstance():onExitPlaza()
    end
    return self
end

-- 初始化界面
function ClientScene:onCreate()
    self.m_listener = nil
    -- self:cachePublicRes()
    -- self.m_actBoxAni = nil
    -- self.m_actStartBtnAni = nil
    -- self.m_actChargeBtnAni = nil
    GlobalUserItem.setHasLogon()
    GlobalUserItem.bHasLogon = true

    local this = self
    --保存进入的游戏记录信息
    GlobalUserItem.m_tabEnterGame = nil
    --上一个场景
    self.m_nPreTag = nil
    --喇叭发送界面
    self.m_trumpetLayer = nil
    self._gameFrame =    GameFrameEngine:create(
    self,
    function(code, result)
        this:onRoomCallBack(code, result)
    end
    )

    -- 聊天服务器
    self.socket_location = LocationFrame:create(self):connect()

    self:getApp()._gameFrameEngine = self._gameFrame

    if PriRoom then
        PriRoom:getInstance():onEnterPlaza(self, self._gameFrame)
    end

    self:registerScriptHandler(
    function(eventType)
        if eventType == 'enterTransitionFinish' then -- 进入场景而且过渡动画结束时候触发。
            self:onEnterTransitionFinish()
        elseif eventType == 'exitTransitionStart' then -- 退出场景而且开始过渡动画时候触发。
            self:onExitTransitionStart()
        elseif eventType == 'exit' then
            self:onExit()
        end
    end
    )

    -- 背景
    self._bg = ccui.ImageView:create('plaza/backgroud_plazz.png'):move(display.center):addTo(self)

    self._sceneRecord = {}

    self._sceneLayer = display.newLayer():setContentSize(yl.WIDTH, yl.HEIGHT):addTo(self)

    --返回键事件
    self._sceneLayer:registerScriptKeypadHandler(
    function(event)
        if event == 'backClicked' then
            if this._popWait == nil then
                if #self._sceneRecord > 0 then
                    local cur_layer = this._sceneLayer:getChildByTag(self._sceneRecord[#self._sceneRecord])
                    if cur_layer and cur_layer.onKeyBack then
                        if cur_layer:onKeyBack() == true then
                            return
                        end
                    end
                end
                this:onKeyBack()
            end
        end
    end
    )

    self._sceneLayer:setKeyboardEnabled(true)

    local VoiceSdk =    appdf.req(appdf.CLIENT_SRC .. 'plaza.views.layer.game.YunvaVoice'):create():setName('VoiceSdk'):addTo(
    self._sceneLayer,
    10
    )

    --加载csb资源
    local csbNode = cc.CSLoader:createNode('plaza/PlazzLayer.csb'):addTo(self)
    self.m_plazaLayer = csbNode

    self.m_touchFilter = PopWait:create():show(self, '请稍候！')
    -- 定时关闭
    self.m_touchFilter:runAction(
    cc.Sequence:create(
    cc.DelayTime:create(30),
    cc.CallFunc:create(
    function()
        if nil ~= self.m_touchFilter then
            self.m_touchFilter:dismiss()
            self.m_touchFilter = nil
        end

        -- 网络断开
        self:disconnectFrame()
    end
    )
    )
    )

    --顶部区域
    local areaTop = csbNode:getChildByName('top_bg')
    self._AreaTop = areaTop

    appdf.setNodeTagAndListener(areaTop, 'btn_share', 'BT_SHARE', handler(self, self.onButtonClickedEvent), self)
    appdf.setNodeTagAndListener(areaTop, 'btn_bulletin', 'BT_BULLETIN', handler(self, self.onButtonClickedEvent), self)
    appdf.setNodeTagAndListener(areaTop, 'btn_rule', 'BT_RULE', handler(self, self.onButtonClickedEvent), self)
    appdf.setNodeTagAndListener(areaTop, 'btn_activity', 'BT_ACTIVITY', handler(self, self.onButtonClickedEvent), self)
    appdf.setNodeTagAndListener(areaTop, 'btn_set', 'BT_CONFIG', handler(self, self.onButtonClickedEvent), self)

    appdf.getNodeByName(areaTop, 'user_name'):setString(GlobalUserItem.szNickName)
    appdf.getNodeByName(areaTop, 'user_id'):setString(GlobalUserItem.dwUserID)

    --钻石
    self._txtDiamond = appdf.getNodeByName(areaTop, 'atlas_diamond')

    -- btn_addDi
    appdf.setNodeTagAndListener(areaTop, 'diamond', 'BT_PAY', handler(self, self.onButtonClickedEvent), self)

    --底部区域
    local areaBottom = csbNode:getChildByName('bottom_bg')
    self._AreaBottom = areaBottom

    appdf.setNodeTagAndListener(areaBottom, 'btn_pay', 'BT_PAY', handler(self, self.onButtonClickedEvent), self)
    appdf.setNodeTagAndListener(areaBottom, 'btn_shop', 'BT_SHOP', handler(self, self.onButtonClickedEvent), self)
    appdf.setNodeTagAndListener(areaBottom, 'btn_check', 'BT_CHECK', handler(self, self.onButtonClickedEvent), self)
    appdf.setNodeTagAndListener(areaBottom, 'btn_record', 'BT_RECORD', handler(self, self.onButtonClickedEvent), self)
    appdf.setNodeTagAndListener(areaBottom, 'btn_match', 'BT_MATCH', handler(self, self.onButtonClickedEvent), self)
    appdf.setNodeTagAndListener(areaBottom, 'btn_rank', 'BT_RANK', handler(self, self.onButtonClickedEvent), self)

    -- 加入房间
    appdf.setNodeTagAndListener(
    csbNode,
    'btn_join_room',
    'BT_INPUT_ROOMID',
    handler(self, self.onButtonClickedEvent),
    self
    )

    --喇叭
    self._notify = csbNode:getChildByName('sp_trumpet_bg')

    local stencil = display.newSprite():setAnchorPoint(cc.p(0, 0.5))
    stencil:setTextureRect(cc.rect(0, 0, 730, 30))
    self._notifyClip = cc.ClippingNode:create(stencil):setAnchorPoint(cc.p(0, 0.5))
    self._notifyClip:setInverted(false)
    self._notifyClip:move(34, 18)
    self._notifyClip:addTo(self._notify)

    self._notifyText =    cc.Label:createWithTTF('', 'fonts/round_body.ttf', 24):addTo(self._notifyClip):setTextColor(
    cc.c4b(255, 191, 123, 255)
    ):setAnchorPoint(cc.p(0, 0.5)):enableOutline(cc.c4b(79, 48, 35, 255), 1)

    self.m_tabInfoTips = {}
    self._tipIndex = 1
    self.m_nNotifyId = 0
    -- 系统公告列表
    self.m_tabSystemNotice = {}
    self._sysIndex = 1
    -- 公告是否运行
    self.m_bNotifyRunning = false

    self.m_bSingleGameMode = false

    local shopDetail = function(result, msg)
        if result == yl.SUB_GP_QUERY_BACKPACKET_RESULT then
            self._shopDetailFrame = nil
        end

        -- 是否处理锁表
        local bHandleLockGame = true
        if PriRoom then
            -- 是否锁表、是否更新游戏、是否锁私人房
            local lockGame, updateGame, lockPriGame = PriRoom:getInstance():onEnterPlazaFinish()
            if lockGame then
                if not updateGame and not lockPriGame then
                    bHandleLockGame = false
                end
                if nil ~= self._checkInFrame then
                    self._checkInFrame:onCloseSocket()
                    self._checkInFrame = nil
                end

                if nil ~= self.m_touchFilter then
                    self.m_touchFilter:dismiss()
                    self.m_touchFilter = nil
                end
            else
                bHandleLockGame = false
            end
        else
            bHandleLockGame = false
        end

        if MatchRoom then
            -- 是否锁表、是否更新游戏、是否锁比赛房
            local lockGame, updateGame, lockMatchGame = MatchRoom:getInstance():onEnterPlazaFinish()
            lockGameall = lockGame
            if lockGame then
                if not updateGame and not lockMatchGame then
                    bHandleLockGame = false
                end
                if nil ~= self._checkInFrame then
                    self._checkInFrame:onCloseSocket()
                    self._checkInFrame = nil
                end

                if nil ~= self.m_touchFilter then
                    self.m_touchFilter:dismiss()
                    self.m_touchFilter = nil
                end
            end
        else
            bHandleLockGame = false
        end

        if GlobalUserItem.dwLockServerID == 0 then
            -- 任务信息查询
            -- self:queryTaskInfo()
            -- if true == GlobalUserItem.bEnableCheckIn then
            -- 	--签到页面
            -- 	self._checkInFrame:onCheckinQuery()
            -- else
            if nil ~= self.m_touchFilter then
                self.m_touchFilter:dismiss()
                self.m_touchFilter = nil
            end
            -- -- 显示广告
            -- if GlobalUserItem.isShowAdNotice() then
            -- 	local webview = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.plaza.WebViewLayer"):create(self)
            -- 	local runScene = cc.Director:getInstance():getRunningScene()
            -- 	if nil ~= runScene then
            -- 		runScene:addChild(webview, yl.ZORDER.Z_AD_WEBVIEW)
            -- 	end
            -- end
            -- end
        end

        if not bHandleLockGame then
            -- 普通房锁表登陆
            print('ClinetScene normal lock login')
            local lockRoom = GlobalUserItem.GetGameRoomInfo(GlobalUserItem.dwLockServerID)
            if GlobalUserItem.dwLockKindID == GlobalUserItem.nCurGameKind and nil ~= lockRoom then
                -- else
                -- 	self:disconnectFrame()
                -- 	-- self:getApp():enterSceneEx(appdf.CLIENT_SRC .. "plaza.views.ForestDanceScene","FADE",0.2)
                -- end
                GlobalUserItem.nCurRoomIndex = lockRoom._nRoomIndex
                local entergame = self:getGameInfo(GlobalUserItem.dwLockKindID)
                self:updateEnterGameInfo(entergame)

                if GlobalUserItem.dwLockKindID ~= 504 then
                    self:onStartGame()
                end
            else
                self:checkMagicWindowValue()
            end
        end
    end
    self._shopDetailFrame = ShopDetailFrame:create(self, shopDetail)

    local checkInInfo =    function(result, msg, subMessage)
        local bRes = false
        if result == 1 then
            if false == GlobalUserItem.bTodayChecked then
                self:onChangeShowMode(
                yl.SCENE_CHECKIN,
                nil,
                function()
                    -- 广告显示在签到界面之上
                    if GlobalUserItem.isShowAdNotice() then
                        local webview =                        appdf.req(appdf.CLIENT_SRC .. 'plaza.views.layer.plaza.WebViewLayer'):create(self)
                        local runScene = cc.Director:getInstance():getRunningScene()
                        if nil ~= runScene then
                            runScene:addChild(webview, yl.ZORDER.Z_AD_WEBVIEW)
                        end
                    end
                end
                )
                self._checkInFrame = nil
            elseif GlobalUserItem.cbMemberOrder ~= 0 then
                self._checkInFrame:sendCheckMemberGift()
                bRes = true
            else
                -- 显示广告
                if GlobalUserItem.isShowAdNotice() then
                    local webview = appdf.req(appdf.CLIENT_SRC .. 'plaza.views.layer.plaza.WebViewLayer'):create(self)
                    local runScene = cc.Director:getInstance():getRunningScene()
                    if nil ~= runScene then
                        runScene:addChild(webview, yl.ZORDER.Z_AD_WEBVIEW)
                    end
                end
                self._checkInFrame = nil
            end
        elseif result == self._checkInFrame.QUERYMEMBERGIFT then
        else
            self._checkInFrame = nil
        end
        if nil ~= self._checkInFrame and self._checkInFrame.QUERYMEMBERGIFT == result then
            if true == subMessage then
                self:onChangeShowMode(yl.SCENE_CHECKIN)
            else
                -- 显示广告
                if GlobalUserItem.isShowAdNotice() then
                    local webview = appdf.req(appdf.CLIENT_SRC .. 'plaza.views.layer.plaza.WebViewLayer'):create(self)
                    local runScene = cc.Director:getInstance():getRunningScene()
                    if nil ~= runScene then
                        runScene:addChild(webview, yl.ZORDER.Z_AD_WEBVIEW)
                    end
                end
            end
            self._checkInFrame = nil
        end

        if nil == self._checkInFrame then
            if nil ~= self.m_touchFilter then
                self.m_touchFilter:dismiss()
                self.m_touchFilter = nil
            end
        end
        return bRes
    end
    -- self._checkInFrame = CheckinFrame:create(self, checkInInfo)
    self.m_bFirstQueryCheckIn = true

    setbackgroundcallback(
    function(bEnter)
        if type(self.onBackgroundCallBack) == 'function' then
            self:onBackgroundCallBack(bEnter)
        end
    end
    )

    self:initListener()

    --快速开始
    -- self.m_bQuickStart = false
    --游戏喇叭列表
    self.m_gameTrumpetList = {}
    self.m_spGameTrumpetBg = nil

    -- 回退
    self.m_bEnableKeyBack = true

    -- 游戏断线重新连接次数
    self.m_connSocketSum = 6
    -- 连接状态
    self.m_connState = 0
    -- 是否切入后台
    -- self.m_enterBackground = nil
    self:onChangeShowMode(yl.SCENE_HOT_GAMELIST)
end

function ClientScene:registerNotifyList()
    -- 代理帐号不显示
    if GlobalUserItem.bIsAngentAccount then
        return
    end

    -- --聊天
    -- local notify = NotifyMgr:getInstance():createNotify(chat_cmd.MDM_GC_USER, chat_cmd.SUB_GC_USER_CHAT_NOTIFY)
    -- notify.name = "client_friend_chat"
    -- notify.group = "client_friend"
    -- notify.fun = handler(self,self.onNotify)
    -- NotifyMgr:getInstance():registerNotify(notify)
    -- --申请好友通知
    -- local notify2 = NotifyMgr:getInstance():createNotify(chat_cmd.MDM_GC_USER, chat_cmd.SUB_GC_APPLYFOR_NOTIFY)
    -- notify2.name = "client_friend_apply"
    -- notify2.group = "client_friend"
    -- notify2.fun = handler(self,self.onNotify)
    -- NotifyMgr:getInstance():registerNotify(notify2)
    -- --回应通知
    -- local notify3 = NotifyMgr:getInstance():createNotify(chat_cmd.MDM_GC_USER, chat_cmd.SUB_GC_RESPOND_NOTIFY)
    -- notify3.name = "client_friend_response"
    -- notify3.group = "client_friend"
    -- notify3.fun = handler(self,self.onNotify)
    -- NotifyMgr:getInstance():registerNotify(notify3)
    -- --邀请通知
    -- local notify4 = NotifyMgr:getInstance():createNotify(chat_cmd.MDM_GC_USER, chat_cmd.SUB_GC_INVITE_GAME_NOTIFY)
    -- notify4.name = "client_friend_invite"
    -- notify4.group = "client_friend"
    -- notify4.fun = handler(self,self.onNotify)
    -- NotifyMgr:getInstance():registerNotify(notify4)
    -- --私人房邀请
    -- local notify5 = NotifyMgr:getInstance():createNotify(chat_cmd.MDM_GC_USER, chat_cmd.SUB_GC_INVITE_PERSONAL_NOTIFY)
    -- notify5.name = "client_pri_friend_invite"
    -- notify5.fun = handler(self,self.onNotify)
    -- notify5.group = "client_friend"
    -- NotifyMgr:getInstance():registerNotify(notify5)
    -- --分享通知
    -- local notify6 = NotifyMgr:getInstance():createNotify(chat_cmd.MDM_GC_USER, chat_cmd.SUB_GC_USER_SHARE_NOTIFY)
    -- notify6.name = "client_friend_share"
    -- notify6.fun = handler(self,self.onNotify)
    -- notify6.group = "client_friend"
    -- NotifyMgr:getInstance():registerNotify(notify6)
    -- --喇叭通知
    -- local notify7 = NotifyMgr:getInstance():createNotify(chat_cmd.MDM_GC_USER, chat_cmd.SUB_GC_TRUMPET_NOTIFY)
    -- notify7.name = "trumpet"
    -- notify7.group = "client_trumpet"
    -- notify7.fun = handler(self,self.onNotify)
    -- NotifyMgr:getInstance():registerNotify(notify7)
    -- -- 任务
    -- local notify8 = NotifyMgr:getInstance():createNotify(yl.MDM_GP_USER_SERVICE, yl.SUB_GP_TASK_INFO)
    -- notify8.name = "client_task_info"
    -- notify8.group = "client_task"
    -- notify8.fun = handler(self,self.onNotify)
    -- NotifyMgr:getInstance():registerNotify(notify8)
    -- --判断是否有未读消息通知(针对消息通知界面)
    -- local tmp = FriendMgr:getInstance():getUnReadNotify()
    -- if #tmp > 0 then
    --     NotifyMgr:getInstance():excute(chat_cmd.MDM_GC_USER, chat_cmd.SUB_GC_APPLYFOR_NOTIFY, nil)
    -- end
end

function ClientScene:unregisterNotify()
    -- 代理帐号不显示
    if GlobalUserItem.bIsAngentAccount then
        return
    end

    -- NotifyMgr:getInstance():unregisterNotify(chat_cmd.MDM_GC_USER, chat_cmd.SUB_GC_USER_CHAT_NOTIFY, "client_friend_chat")
    -- NotifyMgr:getInstance():unregisterNotify(chat_cmd.MDM_GC_USER, chat_cmd.SUB_GC_APPLYFOR_NOTIFY, "client_friend_apply")
    -- NotifyMgr:getInstance():unregisterNotify(chat_cmd.MDM_GC_USER, chat_cmd.SUB_GC_RESPOND_NOTIFY, "client_friend_response")
    -- NotifyMgr:getInstance():unregisterNotify(chat_cmd.MDM_GC_USER, chat_cmd.SUB_GC_INVITE_GAME_NOTIFY, "client_friend_invite")
    -- NotifyMgr:getInstance():unregisterNotify(chat_cmd.MDM_GC_USER, chat_cmd.SUB_GC_USER_SHARE_NOTIFY, "client_friend_share")
    -- NotifyMgr:getInstance():unregisterNotify(chat_cmd.MDM_GC_USER, chat_cmd.SUB_GC_INVITE_PERSONAL_NOTIFY, "client_pri_friend_invite")
    -- NotifyMgr:getInstance():unregisterNotify(chat_cmd.MDM_GC_USER, chat_cmd.SUB_GC_TRUMPET_NOTIFY, "trumpet")
    -- NotifyMgr:getInstance():unregisterNotify(yl.MDM_GP_USER_SERVICE, yl.SUB_GP_TASK_INFO, "client_task_info")
end

function ClientScene:onBackgroundCallBack(bEnter)
    if not bEnter then
        -- if self.m_enterBackground == true then
        -- 	self.m_enterBackground = false
        -- end
        --关闭好友服务器
        -- FriendMgr:getInstance():reSetAndDisconnect()
        -- self:dismissPopWait()
        -- 关闭介绍
        -- local runScene = cc.Director:getInstance():getRunningScene()
        -- if nil ~= runScene and nil ~= runScene:getChildByName(HELP_LAYER_NAME) then
        -- 	runScene:removeChildByName(HELP_LAYER_NAME)
        -- end
        print('onBackgroundCallBack not bEnter')
        -- local curScene = self._sceneRecord[#self._sceneRecord]
        -- if curScene == yl.SCENE_GAME then
        -- 	--[[--离开游戏
        -- 	local gamelayer = self._sceneLayer:getChildByTag(curScene)
        -- 	if gamelayer and gamelayer.standUpAndQuit then
        -- 		gamelayer:standUpAndQuit()
        -- 	end]]
        -- end
        -- if curScene == yl.SCENE_ROOM then
        -- 	self:onKeyBack()
        -- end
        if nil ~= self._gameFrame and self._gameFrame:isSocketServer() and GlobalUserItem.bAutoConnect then
            self._gameFrame:onCloseSocket()
        end

        self:disconnectFrame()
    else
        -- if PriRoom then
        -- 	PriRoom:getInstance():onEnterPlazaFinish()
        -- end
        --连接好友服务器
        -- FriendMgr:getInstance():reSetAndLogin()
        --查询财富
        -- if GlobalUserItem.bJftPay then
        -- 	--通知查询
        --     local eventListener = cc.EventCustom:new(yl.RY_JFTPAY_NOTIFY)
        --     cc.Director:getInstance():getEventDispatcher():dispatchEvent(eventListener)
        -- end
        -- self.m_enterBackground = true
        print('onBackgroundCallBack  bEnter')
        if #self._sceneRecord > 0 then
            local curScene = self._sceneRecord[#self._sceneRecord]
            if curScene == yl.SCENE_GAME then
                if self._gameFrame:isSocketServer() == false and GlobalUserItem.bAutoConnect then
                    self._gameFrame:OnResetGameEngine()
                    self:onStartGame()
                end
            end
        end
        -- 		end
        -- 	end
        -- end
        self:checkMagicWindowValue()
        self:queryUserScoreInfo()
    end
end

-- 游戏服网络监听
function ClientScene:onRoomCallBack(code, message)
    -- print("onRoomCallBack:"..code)
    if message then
        showToast(self, message, 2)
    end
    if code == -1 then
        -- 连接上了
        -- self:dismissPopWait()
        local curScene = self._sceneRecord[#self._sceneRecord]

        -- 在游戏内
        if curScene == yl.SCENE_GAME then
            self:onAutoConnServer()
        else
            self:onChangeShowMode(yl.SCENE_HOT_GAMELIST)
        end
    elseif code == 900 then
        -- 重置重连次数
        self.m_connSocketSum = 3
    end
end

function ClientScene:onAutoConnServer()
    self:showPopWait()

    if self._gameFrame:isSocketServer() == true then
        self._gameFrame:onCloseSocket()
    end

    -- socket异常处理
    if self.m_connState == 1 then
        return
    end

    if self.m_connSocketSum == 0 then
        local clickFuc = function(bReTry)
            -- self:showPopWait()
            -- showToast(self, "正在搜寻网络中...", 99)
            -- self.m_netWorkDialog = nil
            -- self.m_netWorkTipsFuc = display.performWithDelayGlobal(function()
            -- 	showToast(self, "连接失败,请重新登录游戏...", 2)
            -- end, 97)
            -- self.m_netWorkReLoginFuc = display.performWithDelayGlobal(function()
            self:ExitClient()
            -- end, 99)
        end

        self:dismissPopWait()
        -- showToast(self, "连接失败,请重新登录游戏...", 2)
        self.m_netWorkDialog =        QueryDialog:create('当前网络连接不可用,请将网络设置切换至wifi或4g状态下!', clickFuc, nil, 1):setCanTouchOutside(false):addTo(self)

        -- showToast(self, "重连失败,请重新登录游戏...", 2)
        -- display.performWithDelayGlobal(function()
        -- 	self:ExitClient()
        -- end, 2.5)
        self.m_connState = 0

        return
    end

    self.m_connState = 1
    self.m_connSocketSum = self.m_connSocketSum - 1

    showToast(self, '正在重新连接游戏服务器...', 2.5)

    display.performWithDelayGlobal(
    function()
        self._gameFrame:OnResetGameEngine()
        self._gameFrame:onLogonRoom()
        self.m_connState = 0
    end,
    2.5
    )
end

function ClientScene:onReQueryFailure(code, msg)
    self:dismissPopWait()
    if nil ~= msg and type(msg) == 'string' then
        showToast(self, msg, 2)
    end
end

function ClientScene:onEnterRoom()
    print('client onEnterRoom')
    self:dismissPopWait()
    -- 防作弊房间
    if GlobalUserItem.isAntiCheat() then
        print('防作弊')
        if self._gameFrame:SitDown(yl.INVALID_TABLE, yl.INVALID_CHAIR) then
            self:showPopWait2(
            '正为您配桌, 请稍后...',
            function()
                self._gameFrame:onCloseSocket()
            end
            )
        end
        return
    end

    --如果是快速游戏
    local entergame = self:getEnterGameInfo()
    if self.m_bQuickStart and nil ~= entergame then
        self.m_bQuickStart = false
        local t, c = yl.INVALID_TABLE, yl.INVALID_CHAIR
        -- 找桌
        local bGet = false
        for k, v in pairs(self._gameFrame._tableStatus) do
            -- 未锁 未玩
            if v.cbTableLock == 0 and v.cbPlayStatus == 0 then
                local st = k - 1
                local chaircount = self._gameFrame._wChairCount
                for i = 1, chaircount do
                    local sc = i - 1
                    if nil == self._gameFrame:getTableUserItem(st, sc) then
                        t = st
                        c = sc
                        bGet = true
                        break
                    end
                end
            end

            if bGet then
                break
            end
        end
        print(' fast enter ' .. t .. ' ## ' .. c)
        if self._gameFrame:SitDown(t, c) then
            self:showPopWait()
        end
    else
        --自定义房间界面处理登陆成功消息
        local entergame = self:getEnterGameInfo()
        if nil ~= entergame then
            local modulestr = string.gsub(entergame._KindName, '%.', '/')
            local targetPlatform = cc.Application:getInstance():getTargetPlatform()
            local customRoomFile = ''
            if cc.PLATFORM_OS_WINDOWS == targetPlatform then
                customRoomFile = 'game/' .. modulestr .. 'src/views/GameRoomListLayer.lua'
            else
                customRoomFile = 'game/' .. modulestr .. 'src/views/GameRoomListLayer.luac'
            end
            if cc.FileUtils:getInstance():isFileExist(customRoomFile) then
                if (appdf.req(customRoomFile):onEnterRoom(self._gameFrame)) then
                    self:showPopWait()
                    return
                else
                    --断网、退出房间
                    if nil ~= self._gameFrame then
                        self._gameFrame:onCloseSocket()
                        GlobalUserItem.nCurRoomIndex = -1
                    end
                end
            end
        end

        if #self._sceneRecord > 0 then
            if self._sceneRecord[#self._sceneRecord] == yl.SCENE_GAME then
                self:onChangeShowMode()
            elseif self._sceneRecord[#self._sceneRecord] == yl.SCENE_ROOM then
                self._gameFrame:setViewFrame(self._sceneLayer:getChildByTag(yl.SCENE_ROOM))
            else
                self:onChangeShowMode(yl.SCENE_ROOM, self.m_bQuickStart)
                self.m_bQuickStart = false
            end
        end
    end
end

function ClientScene:onEnterTable()
    print('ClientScene onEnterTable')

    if PriRoom and GlobalUserItem.bPrivateRoom then
        -- 动作记录
        PriRoom:getInstance().m_nLoginAction = PriRoom.L_ACTION.ACT_ENTERTABLE
    end
    local tag = self._sceneRecord[#self._sceneRecord]
    if tag == yl.SCENE_GAME then
        self._gameFrame:setViewFrame(self._sceneLayer:getChildByTag(yl.SCENE_GAME))
    else
        self:onChangeShowMode(yl.SCENE_GAME)
    end
end

--启动游戏
function ClientScene:onStartGame()
    local view = appdf.getNodeByName(self, '_RoomIdInputLayer')
    if view ~= nil then
        view:dismiss()
    end

    local entergame = self:getEnterGameInfo()
    if nil == entergame then
        showToast(self, '游戏信息获取失败', 3)
        return
    end

    if self:updateGame() then
        return
    end

    self:getEnterGameInfo().nEnterRoomIndex = GlobalUserItem.nCurRoomIndex
    if nil ~= self.m_touchFilter then
        self.m_touchFilter:dismiss()
        self.m_touchFilter = nil
    end

    self:showPopWait()
    self._gameFrame:onInitData()
    self._gameFrame:setKindInfo(GlobalUserItem.nCurGameKind, entergame._KindVersion)
    local curScene = self._sceneRecord[#self._sceneRecord]
    self._gameFrame:setViewFrame(self)

    if self._gameFrame:isSocketServer() == true then
        self._gameFrame:onCloseSocket()
    end
    self._gameFrame:onLogonRoom()
end

function ClientScene:onCleanPackage(name)
    if not name then
        return
    end
    for k, v in pairs(package.loaded) do
        if k ~= nil then
            if type(k) == 'string' then
                if string.find(k, name) ~= nil or string.find(k, name) ~= nil then
                    print('package kill:' .. k)
                    package.loaded[k] = nil
                end
            end
        end
    end
end

function ClientScene:onLevelCallBack(result, msg)
--[[if type(msg) == "string" and "" ~= msg then
		showToast(self, msg, 2)
	end

	self:dismissPopWait()
	self._level:setString(GlobalUserItem.wCurrLevelID.."")

	if GlobalUserItem.dwUpgradeExperience > 0 then
		local scalex = GlobalUserItem.dwExperience/GlobalUserItem.dwUpgradeExperience
		if scalex > 1 then
			scalex = 1
		end
		self._levelpro:setPercent(100 * scalex)
	else
		self._levelpro:setPercent(1)
	end

	if 1 == result then
		if nil ~= self._levelFrame and self._levelFrame:isSocketServer() then
			self._levelFrame:onCloseSocket()
			self._levelFrame = nil
		end
	end]]
end

function ClientScene:onUserInfoChange(event)
    print('----------userinfo change notify------------')

    local msgWhat = event.obj

    if nil ~= msgWhat and msgWhat == yl.RY_MSG_USERHEAD then
        --更新头像
        if nil ~= self._head then
            self._head:updateHead(GlobalUserItem)
        end
    end

    if nil ~= msgWhat and msgWhat == yl.RY_MSG_USERWEALTH then
        --更新财富
        self:updateInfomation()
    end
end

function ClientScene:initListener()
    self.m_listener = cc.EventListenerCustom:create(yl.RY_USERINFO_NOTIFY, handler(self, self.onUserInfoChange))
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(self.m_listener, self)

    local listener = cc.EventListenerCustom:create('NetWorkState', handler(self, self.onNetWorkStateListener))
    cc.Director:getInstance():getEventDispatcher():addEventListenerWithSceneGraphPriority(listener, self)
end

function ClientScene:removeListener()
    if nil ~= self.m_listener then
        cc.Director:getInstance():getEventDispatcher():removeEventListener(self.m_listener)
        self.m_listener = nil
    end
end

function ClientScene:onKeyBack()
    if not self.m_bEnableKeyBack then
        return
    end

    local curScene = self._sceneRecord[#self._sceneRecord]
    if curScene then
        if curScene == yl.SCENE_ROOM then
            self._gameFrame:onCloseSocket()
            GlobalUserItem.nCurRoomIndex = -1
        elseif curScene == yl.SCENE_GAMELIST then
            if PriRoom then
                PriRoom:getInstance():exitRoom()
            end
        end
    end
    self:onChangeShowMode()
end

--跑马灯更新
function ClientScene:onChangeNotify(msg)
    self._notifyText:stopAllActions()
    if not msg or not msg.str or #msg.str == 0 then
        self._notifyText:setString('')
        self.m_bNotifyRunning = false
        self._tipIndex = 1
        self._sysIndex = 1
        return
    end
    self.m_bNotifyRunning = true
    local msgcolor = msg.color or cc.c4b(255, 191, 123, 255)
    self._notifyText:setVisible(false)
    self._notifyText:setString(msg.str)
    self._notifyText:setTextColor(msgcolor)

    if true == msg.autoremove then
        msg.showcount = msg.showcount or 0
        msg.showcount = msg.showcount - 1
        if msg.showcount <= 0 then
            self:removeNoticeById(msg.id)
        end
    end

    local tmpWidth = self._notifyText:getContentSize().width
    self._notifyText:runAction(
    cc.Sequence:create(
    cc.CallFunc:create(
    function()
        self._notifyText:move(yl.WIDTH - 600, 0)
        self._notifyText:setVisible(true)
    end
    ),
    cc.MoveTo:create(16 + (tmpWidth / 172), cc.p(0 - tmpWidth, 0)),
    cc.CallFunc:create(
    function()
        local tipsSize = 0
        local tips = {}
        local index = 1
        if 0 ~= #self.m_tabInfoTips then
            -- 喇叭等
            local tmp = self._tipIndex + 1
            if tmp > #self.m_tabInfoTips then
                tmp = 1
            end
            self._tipIndex = tmp
            self:onChangeNotify(self.m_tabInfoTips[self._tipIndex])
        else
            -- 系统公告
            local tmp = self._sysIndex + 1
            if tmp > #self.m_tabSystemNotice then
                tmp = 1
            end
            self._sysIndex = tmp
            self:onChangeNotify(self.m_tabSystemNotice[self._sysIndex])
        end
    end
    )
    )
    )
end

function ClientScene:ExitClient()
    self._sceneLayer:setKeyboardEnabled(false)
    GlobalUserItem.nCurRoomIndex = -1
    self:updateEnterGameInfo(nil)
    self:getApp():enterSceneEx(appdf.CLIENT_SRC .. 'plaza.views.LogonScene', 'FADE', 1)

    self.socket_location:onCloseSocket()

    GlobalUserItem.reSetData()
    --读取配置
    GlobalUserItem.LoadData()
    --断开好友服务器
    -- FriendMgr:getInstance():reSetAndDisconnect()
    --通知管理
    -- NotifyMgr:getInstance():clear()
    -- 私人房数据
    if PriRoom then
        PriRoom:getInstance():reSet()
    end
end

--按钮事件
function ClientScene:onButtonClickedEvent(tag, ref)
    if tag == WIDGET_TAG.BT_EXIT then
        self:onKeyBack()
    elseif tag == WIDGET_TAG.BT_INPUT_ROOMID then
        local roomidLayer =        appdf.req(appdf.CLIENT_SRC .. 'plaza.views.layer.plaza.RoomIdInputLayer'):create():setName(
        '_RoomIdInputLayer'
        ):addTo(self)

        roomidLayer:show()
    elseif tag == WIDGET_TAG.BT_CONFIG then
        local optionView =        appdf.req(appdf.CLIENT_SRC .. 'plaza.views.layer.other.OptionLayer'):create(self):addTo(self):show()
    elseif tag == WIDGET_TAG.BT_RECORD then
        local PlazaRecordLayer =        appdf.req(appdf.CLIENT_SRC .. 'plaza.views.layer.plaza.PlazaRecordLayer'):create(
        self,
        self:getApp()._gameList
        ):addTo(self)
        PlazaRecordLayer:show()
    elseif tag == WIDGET_TAG.BT_SHARE then
        local PlazaShareLayer =        appdf.req(appdf.CLIENT_SRC .. 'plaza.views.layer.plaza.PlazaShareLayer'):create(self):addTo(self)
        PlazaShareLayer:show()
    elseif tag == WIDGET_TAG.BT_ADD_GOLD then
    elseif tag == WIDGET_TAG.BT_ADD_DIAMOND then
    elseif tag == WIDGET_TAG.BT_CLUB then
        local ClubHomeLayer =        appdf.req(appdf.CLIENT_SRC .. 'plaza.views.layer.club.ClubHomeLayer'):create(self):addTo(self)
    elseif tag == WIDGET_TAG.BT_RANK then
        local PlazaRankLayer =        appdf.req(appdf.CLIENT_SRC .. 'plaza.views.layer.plaza.PlazaRankLayer'):create(self):addTo(self):show()
    elseif tag == WIDGET_TAG.BT_CHECK then
        local PlazaCheckInLayer =        appdf.req(appdf.CLIENT_SRC .. 'plaza.views.layer.plaza.PlazaCheckInLayer'):create(self):addTo(self):show()
    elseif tag == WIDGET_TAG.BT_RULE then
        local PlazaGameRuleLayer =        appdf.req(appdf.CLIENT_SRC .. 'plaza.views.layer.plaza.PlazaGameRuleLayer'):create(self):addTo(self):show()
    elseif tag == WIDGET_TAG.BT_ACTIVITY then
        local PlazaRromotionLayer =        appdf.req(appdf.CLIENT_SRC .. 'plaza.views.layer.plaza.PlazaRromotionLayer'):create(self):addTo(self):show()
    elseif tag == WIDGET_TAG.BT_BULLETIN then
        local PlazaNoticeLayer =        appdf.req(appdf.CLIENT_SRC .. 'plaza.views.layer.plaza.PlazaNoticeLayer'):create(self):addTo(self):show()
    elseif tag == WIDGET_TAG.BT_SHOP then
        local PlazaShopLayer =        appdf.req(appdf.CLIENT_SRC .. 'plaza.views.layer.plaza.PlazaShopLayer'):create(self):addTo(self):show()
    elseif tag == WIDGET_TAG.BT_PAY then
        local PlazaShopLayer =        appdf.req(appdf.CLIENT_SRC .. 'plaza.views.layer.plaza.PlazaShopLayer'):create(self):addTo(self):show()
    elseif tag == WIDGET_TAG.BT_MATCH then
        local PlazaMatchLayer =        appdf.req(appdf.CLIENT_SRC .. 'plaza.views.layer.plaza.PlazaMatchLayer'):create(self):addTo(self):show()
    else
        showToast(self, '功能尚未开放，敬请期待！', 2)
    end
end

-- 改动浮动菜单
function ClientScene:changFloatingMenu(tag)
    local topPosY = self._AreaTop:getPositionY()
    local bottomPosY = self._AreaBottom:getPositionY()

    -- 隐藏所有
    if tag == ClientScene.ACTION_HIDE_ALL then
        -- 隐藏顶部
        if topPosY == 750 then
            self._AreaTop:runAction(cc.MoveTo:create(0.3, cc.p(0, 930)))
        end

        if bottomPosY == 0 then
            self._AreaBottom:runAction(cc.MoveTo:create(0.3, cc.p(666, -150)))
        end
    elseif tag == ClientScene.ACTION_HIDE_TOP then
        -- 隐藏底部
    elseif tag == ClientScene.ACTION_HIDE_BOTTOM then
        -- 显示所有
    elseif tag == ClientScene.ACTION_SHOW_ALL then
        -- 隐藏退出按钮
        if topPosY > 750 then
            self._AreaTop:runAction(cc.Sequence:create(cc.MoveTo:create(0.1, cc.p(0, 750))))
        end

        if bottomPosY < 0 then
            self._AreaBottom:runAction(
            cc.Sequence:create(cc.MoveTo:create(0.15, cc.p(666, 25)), cc.MoveBy:create(0.3, cc.p(0, -25)))
            )
        end
    elseif tag == ClientScene.ACTION_HIDE_EXIT then
        if topPosY > 750 then
            self._AreaTop:runAction(cc.Sequence:create(cc.MoveTo:create(0.1, cc.p(0, 750))))
        end

        if bottomPosY < 0 then
            self._AreaBottom:runAction(
            cc.Sequence:create(cc.MoveTo:create(0.15, cc.p(666, 25)), cc.MoveBy:create(0.3, cc.p(0, -25)))
            )
        end
    end
end

--切换页面
function ClientScene:onChangeShowMode(nTag, param, transitionCallBack)
    local tag = nTag
    local curtag  --当前页面ID
    local bIn  --进入判断
    --当前页面
    if #self._sceneRecord > 0 then
        curtag = self._sceneRecord[#self._sceneRecord]
    end
    ExternalFun.dismissTouchFilter()

    --退出判断
    if not tag then
        --返回登录
        if #self._sceneRecord < 2 then
            self:ExitClient()
            return
        end
        --清除记录
        local cur = self._sceneRecord[#self._sceneRecord]
        self._sceneRecord[#self._sceneRecord] = nil
        --上一页面
        tag = self._sceneRecord[#self._sceneRecord]
        --当前为游戏界面
        if cur == yl.SCENE_GAME then
            --防作弊房间
            if GlobalUserItem.isAntiCheat() then
                -- 私人房
                tag = yl.SCENE_ROOMLIST
                local bHaveRoomList = false
                local tmpRecord = {}
                for i = 1, #self._sceneRecord do
                    if self._sceneRecord[i] ~= yl.SCENE_ROOM then
                        table.insert(tmpRecord, self._sceneRecord[i])
                    end

                    if self._sceneRecord[i] == yl.SCENE_ROOMLIST then
                        bHaveRoomList = true
                    end
                end
                if false == bHaveRoomList then
                    tmpRecord[#tmpRecord + 1] = yl.SCENE_ROOMLIST
                end
                self._sceneRecord = tmpRecord

                self._gameFrame:onCloseSocket()
            elseif GlobalUserItem.bPrivateRoom then
                --网络已经关闭 回退到房间列表
                if PriRoom then
                    tag = yl.SCENE_HOT_GAMELIST
                    -- 清理记录
                    self._sceneRecord = {}
                    if not self.m_bSingleGameMode then
                        -- 非单游戏模式, 保存游戏列表界面记录
                        -- self._sceneRecord[1] = yl.SCENE_HOT_GAMELIST
                    else
                        -- 单游戏,有比赛
                        if MatchRoom and MatchRoom:getInstance():isCurrentGameOpenMatch(GlobalUserItem.nCurGameKind) then
                            self._sceneRecord[1] = MatchRoom:getInstance().LAYTAG.MATCH_TYPELIST
                        end
                    end
                    self._sceneRecord[#self._sceneRecord + 1] = tag
                    PriRoom:getInstance():exitRoom()
                end
                self._gameFrame:onCloseSocket()
            elseif self._gameFrame:isSocketServer() ~= true then
                tag = yl.SCENE_ROOMLIST
                local bHaveRoomList = false
                local tmpRecord = {}
                for i = 1, #self._sceneRecord do
                    if self._sceneRecord[i] ~= yl.SCENE_ROOM then
                        table.insert(tmpRecord, self._sceneRecord[i])
                    end

                    if self._sceneRecord[i] == yl.SCENE_ROOMLIST then
                        bHaveRoomList = true
                    end
                end
                if false == bHaveRoomList then
                    tmpRecord[#tmpRecord + 1] = yl.SCENE_ROOMLIST
                end
                self._sceneRecord = tmpRecord
            elseif tag ~= yl.SCENE_ROOM then --回退到房间桌子界面
                self._sceneRecord[#self._sceneRecord + 1] = yl.SCENE_ROOM
                tag = yl.SCENE_ROOM
            end

            -- 任务查询
            -- self:queryTaskInfo()
            -- 游戏喇叭关闭
            if nil ~= self.m_spGameTrumpetBg then
                self.m_spGameTrumpetBg:stopAllActions()
                self.m_spGameTrumpetBg:removeFromParent()
                self.m_spGameTrumpetBg = nil
                self.m_gameTrumpetList = {}
            end

            -- 游戏弹窗
            local runScene = cc.Director:getInstance():getRunningScene()
            local layer = appdf.getNodeByName(runScene, 'GameMagicLayer')
            if layer then
                layer:removeSelf()
            end
            -- -- 移除语音
            -- self:cancelVoiceRecord()
            -- if nil ~= self._gameFrame and type(self._gameFrame.clearVoiceQueue) == "function" then
            -- 	self._gameFrame:clearVoiceQueue()
            -- end
            -- 清理游戏资源
            cc.Director:getInstance():getTextureCache():removeUnusedTextures()
            cc.SpriteFrameCache:getInstance():removeUnusedSpriteFrames()
        elseif cur == yl.SCENE_PLAYBACK then
            local recordLayer = appdf.getNodeByName(self, "PlazaRecordLayer")
            if recordLayer then
                self:reorderChild(recordLayer, 1)
                --print("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXddd")
                recordLayer:setTouchEnabled(true)
                recordLayer:setSwallowsTouches(true)
                appdf.getNodeByName(recordLayer, "content_TableView"):setTableViewTouchEnabled(true)
                recordLayer:setVisible(true)
            end
        end
        -- 游戏币查询
        self:queryUserScoreInfo()
    else
        --查找已有
        local oldIndex
        for i = 1, #self._sceneRecord do
            if self._sceneRecord[i] == tag then
                oldIndex = i
                break
            end
        end

        if not oldIndex then --新界面
            bIn = true --进入判断
            self._sceneRecord[#self._sceneRecord + 1] = tag --记录ID
        else
            --重复过滤
            if oldIndex == #self._sceneRecord then
                return
            end

            --回退至已有记录
            for i = #self._sceneRecord, oldIndex + 1, -1 do
                table.remove(self._sceneRecord, i)
            end
        end
    end
    --上一个页面
    self.m_nPreTag = self._sceneRecord[#self._sceneRecord]
    -- dump(self._sceneRecord)
    local this = self
    --当前页面
    if curtag then
        local cur_layer = self._sceneLayer:getChildByTag(curtag)
        if cur_layer then
            cur_layer:stopAllActions()
            --游戏界面不触发切换动画
            if tag == yl.SCENE_GAME or curtag == yl.SCENE_GAME then
                cur_layer:removeFromParent()
                ExternalFun.playPlazzBackgroudAudio()
            else
                --动画判断
                local curAni
                if not bIn then
                    curAni = cc.MoveTo:create(0.25, cc.p(yl.WIDTH, 0)) --退出动画
                else
                    curAni = cc.MoveTo:create(0.25, cc.p(-yl.WIDTH, 0)) --返回动画
                end
                cur_layer:runAction(cc.Sequence:create(curAni, cc.RemoveSelf:create(true)))
            end
        end
    end

    self._AreaBottom:stopAllActions()
    self._AreaTop:stopAllActions()

    -- 主页
    if tag == yl.SCENE_HOT_GAMELIST then
        -- self._btExit:loadTexture('plaza/dating-button-06.png')
        -- 私人房列表 or 金币场
        self:changFloatingMenu(ClientScene.ACTION_HIDE_EXIT)
    elseif tag == PriRoom.LAYTAG.LAYER_ROOMLIST or tag == yl.SCENE_ROOMLIST then
        -- self._btExit:loadTexture('plaza/dating-button-05.png')
        self:changFloatingMenu(ClientScene.ACTION_SHOW_ALL)
    else
        self:changFloatingMenu(ClientScene.ACTION_HIDE_ALL)
    end

    --目标页面
    local dst_layer = self:getTagLayer(tag, param)
    if dst_layer then
        if tag == yl.SCENE_PLAYBACK then
            local recordLayer = appdf.getNodeByName(self, "PlazaRecordLayer")
            if recordLayer then
                self:reorderChild(recordLayer, -1)
                --recordLayer:setVisible(true)
            end
        end
        --游戏界面不触发切换动画
        if tag == yl.SCENE_GAME then
            self._sceneLayer:setKeyboardEnabled(false)
            dst_layer:addTo(self._sceneLayer)
            if dst_layer.onSceneAniFinish then
                dst_layer:onSceneAniFinish()
            end
            this._sceneLayer:setKeyboardEnabled(true)
        else
            --触摸过滤
            ExternalFun.popupTouchFilter()
            self._sceneLayer:setKeyboardEnabled(false)
            if not bIn then
                dst_layer:move(-yl.WIDTH, 0)
            else
                dst_layer:move(yl.WIDTH, 0)
            end

            dst_layer:addTo(self._sceneLayer)
            dst_layer:stopAllActions()
            dst_layer:runAction(
            cc.Sequence:create(
            cc.MoveTo:create(0.3, cc.p(0, 0)),
            cc.CallFunc:create(
            function()
                if dst_layer.onSceneAniFinish then
                    dst_layer:onSceneAniFinish()
                end
                this._sceneLayer:setKeyboardEnabled(true)
                ExternalFun.dismissTouchFilter()
                if type(transitionCallBack) == 'function' then
                    transitionCallBack()
                end
            end
            )
            )
            )
        end
    else
        -- dump("当前层级tag",tag)
        -- dump(debug.traceback())
        -- 回到上一层
        self:onChangeShowMode(curtag)
        -- showToast(self, "该游戏服务器尚未开启!", 1.5)
        -- print("dst_layer is nil")
        -- self:ExitClient()
        return
    end

    if tag == yl.SCENE_GAME or tag == yl.SCENE_ROOM then
        self._gameFrame:setViewFrame(dst_layer)
        cc.SpriteFrameCache:getInstance():addSpriteFrames('public/mofabiaoqing.plist')
    end

    -- 层
    local infoShow =    (tag == yl.SCENE_TABLE or tag == yl.SCENE_GAME or tag == PriRoom.LAYTAG.LAYER_CREATEPRIROOME or
    tag == yl.SCENE_PLAYBACK)

    local actionMng = self._notifyText:getActionManager()

    -- 公告
    if infoShow == true then
        self._notify:setVisible(false)
        actionMng:pauseTarget(self._notifyText)
    else
        if self._notify:isVisible() == false then
            self._notify:setVisible(true)
            actionMng:resumeTarget(self._notifyText)
        end

        self:updateInfomation()
    end

    --游戏信息
    GlobalUserItem.bEnterGame = (tag == yl.SCENE_GAME)
    if tag == yl.SCENE_ROOMLIST then
        GlobalUserItem.dwServerRule = 0
    end
end

--获取页面
function ClientScene:getTagLayer(tag, param)
    local dst
    if tag == yl.SCENE_PLAYBACK then
        if param.kind ~= 0 then
            local entergame = self:getGameInfo(param.kind)
            local modulestr = string.gsub(entergame._KindName, '%.', '/')
            local customRoomFile = ''
            if device.platform == 'windows' then
                customRoomFile = 'game/' .. modulestr .. 'src/record/GamePlayBackLayer.lua'
            else
                customRoomFile = 'game/' .. modulestr .. 'src/record/GamePlayBackLayer.luac'
            end
            if cc.FileUtils:getInstance():isFileExist(customRoomFile) then
                -- 添加搜索路径
                cc.FileUtils:getInstance():addSearchPath(device.writablePath .. 'game/' .. modulestr .. '/res/')

                dst = appdf.req(customRoomFile):create(self, param)
            else
                showToast(self, '该游戏未开放录像回放功能!', 2)
            end
        end
    elseif tag == yl.SCENE_HOT_GAMELIST then
        dst = NewGameListLayer:create(self, self:getApp())
    elseif tag == yl.SCENE_GAMELIST then
        dst = GameListView:create(self:getApp()._gameList)
    elseif tag == yl.SCENE_ROOMLIST then
        --是否有自定义房间列表
        local entergame = self:getEnterGameInfo()
        if nil ~= entergame then
            local modulestr = string.gsub(entergame._KindName, '%.', '/')
            local targetPlatform = cc.Application:getInstance():getTargetPlatform()
            local customRoomFile = ''
            if cc.PLATFORM_OS_WINDOWS == targetPlatform then
                customRoomFile = 'game/' .. modulestr .. 'src/views/GameRoomListLayer.lua'
            else
                customRoomFile = 'game/' .. modulestr .. 'src/views/GameRoomListLayer.luac'
            end
            if cc.FileUtils:getInstance():isFileExist(customRoomFile) then
                dst = appdf.req(customRoomFile):create(self, self._gameFrame, param)
            end
        end
        if nil == dst then
            dst = RoomList:create(self, param)
        end
    elseif tag == yl.SCENE_OPTION then
        dst = Option:create(self)
    elseif tag == yl.SCENE_ROOM then
        dst = Room:create(self._gameFrame, self, param)
    elseif tag == yl.SCENE_GAME then
        local entergame = self:getEnterGameInfo()
        if nil ~= entergame then
            local modulestr = entergame._KindName

            dst = PriRoom:getInstance():createPriRoomScene(modulestr, self)

            if dst == nil then
                local gameScene = appdf.req(appdf.GAME_SRC .. modulestr .. 'src.views.GameLayer')
                if gameScene then
                    dst = gameScene:create(self._gameFrame, self)
                end
            end
        else
            print('游戏记录错误')
        end
    elseif PriRoom then
        dst = PriRoom:getInstance():getTagLayer(tag, param, self)
    end
    if dst then
        dst:setTag(tag)
    end
    return dst
end

--显示等待
function ClientScene:showPopWait(isTransparent)
    if not self._popWait then
        self._popWait = PopWait:create(isTransparent):show(self, '请稍候！')
        self._popWait:setLocalZOrder(yl.MAX_INT)
    end
end

--关闭等待
function ClientScene:dismissPopWait()
    if self._popWait then
        self._popWait:dismiss()
        self._popWait = nil
    end

    if nil ~= self.m_maskPopWait then
        self.m_maskPopWait:removeFromParent()
        self.m_maskPopWait = nil
    end
end

-- 显示可关等待
function ClientScene:showPopWait2(szTips, callfun)
    if nil ~= self.m_maskPopWait then
        self.m_maskPopWait:removeFromParent()
        self.m_maskPopWait = nil
        return
    end
    szTips = szTips or ''
    -- 屏蔽层
    local mask = ccui.Layout:create()
    mask:setTouchEnabled(true)
    mask:setContentSize(appdf.WIDTH, appdf.HEIGHT)
    self:addChild(mask, yl.MAX_INT)
    self.m_maskPopWait = mask

    -- 提示背景
    --[[local bg = ccui.ImageView:create("General/frame_1.png")
	bg:move(appdf.WIDTH/2,appdf.HEIGHT/2)
	bg:addTo(mask)
	bg:setScale9Enabled(true)]]
    local bg = display.newSprite('query_bg.png'):move(appdf.WIDTH / 2, appdf.HEIGHT / 2):addTo(mask)
    cc.Label:createWithTTF('系统消息', 'fonts/round_body.ttf', 36):setTextColor(cc.c4b(255, 221, 65, 255)):setAnchorPoint(
    cc.p(0.5, 0.5)
    ):setDimensions(600, 120):setHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER):setVerticalAlignment(
    cc.VERTICAL_TEXT_ALIGNMENT_CENTER
    ):move(appdf.WIDTH / 2, 545):addTo(mask)
    cc.Label:createWithTTF(szTips, 'fonts/round_body.ttf', 32):setTextColor(cc.c4b(255, 255, 255, 255)):setAnchorPoint(
    cc.p(0.5, 0.5)
    ):setDimensions(600, 180):setHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER):setVerticalAlignment(
    cc.VERTICAL_TEXT_ALIGNMENT_CENTER
    ):move(appdf.WIDTH / 2, 375):addTo(mask)

    --[[-- 提示内容
	local lab = cc.Label:createWithTTF(szTips, "fonts/round_body.ttf", 24, cc.size(930,0))
	lab:setHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
	lab:addTo(bg)
	local labSize = lab:getContentSize()]]
    -- 取消按钮
    local btn = ccui.Button:create('bt_query_cancel_0.png', 'bt_query_cancel_1.png')
    btn:addTo(mask)
    btn:move(appdf.WIDTH / 2, 200)
    btn:addTouchEventListener(
    function(ref, tType)
        if tType == ccui.TouchEventType.ended then
            self.m_maskPopWait:removeFromParent()
            self.m_maskPopWait = nil
            if type(callfun) == 'function' then
                callfun()
            end
        end
    end
    )
    --bg:setContentSize(cc.size(appdf.WIDTH, 64 + labSize.height))
    --lab:move(appdf.WIDTH * 0.5, bg:getContentSize().height * 0.5)
    --btn:move(appdf.WIDTH * 0.5 + labSize.width * 0.5 + 100,bg:getContentSize().height * 0.5 )
end

--更新进入游戏记录
function ClientScene:updateEnterGameInfo(info)
    GlobalUserItem.m_tabEnterGame = info
end

function ClientScene:getEnterGameInfo()
    return GlobalUserItem.m_tabEnterGame
end

--获取游戏信息
function ClientScene:getGameInfo(wKindID)
    for k, v in pairs(self:getApp()._gameList) do
        if tonumber(v._KindID) == tonumber(wKindID) then
            return v
        end
    end
    return nil
end

--获取喇叭发送界面
function ClientScene:getTrumpetSendLayer()
    if nil == self.m_trumpetLayer then
        self.m_trumpetLayer = TrumpetSendLayer:create(self)
        self.m_plazaLayer:addChild(self.m_trumpetLayer)
    end
    self.m_trumpetLayer:showLayer(true)
end

function ClientScene:getSceneRecord()
    return self._sceneRecord
end

function ClientScene:updateInfomation()
    -- local str = string.formatNumberThousands(GlobalUserItem.lUserScore,true,"/")
    -- if string.len(str) > 11 then
    -- 	str = string.sub(str, 1, 11) .. "..."
    -- end
    -- self._nodeGold:setString(ExternalFun.formatScoreText(GlobalUserItem.lUserScore))
    -- str = string.formatNumberThousands(GlobalUserItem.dUserBeans,true,"/")
    -- if string.len(str) > 11 then
    -- 	str = string.sub(str, 1, 11) .. "..."
    -- end
    -- self._txtDiamond:setString(str)
    -- str = string.formatNumberThousands(GlobalUserItem.lUserIngot,true,"/")
    -- if string.len(str) > 11 then
    -- 	str = string.sub(str, 1, 11) .. "..."
    -- end
    -- self._ingot:setString(str)
    local texStr = ""
    if GlobalUserItem.lRoomCard > 99999 then
        texStr = ExternalFun.formatScoreText(GlobalUserItem.lRoomCard)
    else
        texStr = tostring(GlobalUserItem.lRoomCard)
    end
    self._txtDiamond:setString(texStr)
end

--输出日志
function ClientScene:logData(msg, addExtral)
    addExtral = addExtral or false
    local logtable = {}
    local entergame = self:getEnterGameInfo()
    if nil ~= entergame then
        logtable.name = entergame._KindName
        logtable.id = entergame._KindID
    end
    logtable.msg = msg
    local jsonStr = cjson.encode(logtable)
    LogAsset:getInstance():logData(jsonStr, true)
end

--快速登录逻辑
function ClientScene:quickStartGame()
    --进入游戏房间/进入第一个桌子
    local gamelist = self._sceneLayer:getChildByTag(yl.SCENE_GAMELIST)
    local gameinfo = self:getEnterGameInfo()
    if nil ~= gamelist and nil ~= gameinfo then
        --进入游戏第一个房间
        GlobalUserItem.nCurRoomIndex = gameinfo.nEnterRoomIndex
        if nil == GlobalUserItem.nCurRoomIndex or -1 == GlobalUserItem.nCurRoomIndex then
            GlobalUserItem.nCurRoomIndex = GlobalUserItem.normalRoomIndex(gameinfo._KindID)
        end
        if not GlobalUserItem.nCurRoomIndex then
            showToast(self, '未找到房间信息!', 2)
            return
        end

        --获取更新
        if not self:updateGame() then
            --获取房间信息
            local roomCount = GlobalUserItem.GetRoomCount(gameinfo._KindID)
            if not roomCount or 0 == roomCount then
                --gamelist:onLoadGameList(gameinfo._KindID)
                print('ClientScene:quickStartGame 房间列表为空')
            end
            GlobalUserItem.nCurGameKind = tonumber(gameinfo._KindID)
            GlobalUserItem.szCurGameName = gameinfo._KindName

            local roominfo = GlobalUserItem.GetRoomInfo(GlobalUserItem.nCurRoomIndex)
            if roominfo.wServerType == yl.GAME_GENRE_PERSONAL then
                --showToast(self, "房卡房间不支持快速开始！", 2)
                return
            end
            if self:roomEnterCheck() then
                --启动游戏
                self:onStartGame()
            end
        end
    end
end

-- 游戏更新处理
function ClientScene:updateGame(dwKindID)
    local gameinfo = self:getEnterGameInfo()
    if nil ~= dwKindID then
        gameinfo = self:getGameInfo(dwKindID)
    end
    if nil == gameinfo then
        return false
    end
    local gamelist = self._sceneLayer:getChildByTag(yl.SCENE_HOT_GAMELIST)

    if nil == gamelist then
        return false
    end

    --获取更新
    local app = self:getApp()
    local version = tonumber(app:getVersionMgr():getResVersion(gameinfo._KindID))
    if not version or gameinfo._ServerResVersion > version then
        showToast(self, '该游戏需要更新!请稍等!正在下载中...', 2.5)
        gamelist:onGameUpdate(gameinfo)
        return true
    end
    return false
end

-- 链接游戏
function ClientScene:loadGameList(dwKindID)
    local gameinfo = self:getEnterGameInfo()
    if nil ~= dwKindID then
        gameinfo = self:getGameInfo(dwKindID)
    end
    if nil == gameinfo then
        return false
    end
    local gamelist = self._sceneLayer:getChildByTag(yl.SCENE_GAMELIST)
    if nil == gamelist then
        return false
    end

    self:updateEnterGameInfo(gameinfo)
    local roomCount = GlobalUserItem.GetRoomCount(gameinfo._KindID)
    if not roomCount or 0 == roomCount then
        --gamelist:onLoadGameList(gameinfo._KindID)
        print('ClientScene:loadGameList 房间列表为空')
        return true
    end
    return false
end

function ClientScene:roomEnterCheck()
    local roominfo = GlobalUserItem.GetRoomInfo(GlobalUserItem.nCurRoomIndex)

    -- 密码
    if bit:_and(roominfo.wServerKind, yl.SERVER_GENRE_PASSWD) ~= 0 then
        self.m_bEnableKeyBack = false
        self:createPasswordEdit(
        '请输入房间密码',
        function(pass)
            self.m_bEnableKeyBack = true
            GlobalUserItem.szRoomPasswd = pass
            self:onStartGame()
        end,
        'RoomList/sp_pwroom_title.png'
        )
        return false
    end

    -- 比赛
    if bit:_and(roominfo.wServerType, yl.GAME_GENRE_MATCH) ~= 0 then
        showToast(self, '暂不支持比赛房间！', 1)
        return false
    end
    return true
end

--网络通知
function ClientScene:onNotify(msg)
    local bHandled = false
    local main = msg.main or 0
    local sub = msg.sub or 0
    local name = msg.name or ''
    local param = msg.param
    local group = msg.group

    if group == 'client_trumpet' and type(msg.param) == 'table' then
        --喇叭消息获取		--
        local item = {}
        item.str = msg.param.szNickName .. '说:' .. string.gsub(msg.param.szMessageContent, '\n', '')
        item.color = cc.c4b(255, 191, 123, 255)
        item.autoremove = true
        item.showcount = 1
        item.bNotice = false
        item.id = self:getNoticeId()
        self:addNotice(item)
        bHandled = true

        --当前场景为游戏
        local curScene = self._sceneRecord[#self._sceneRecord]
        if curScene == yl.SCENE_GAME then
            table.insert(self.m_gameTrumpetList, item.str)

            local chat = {}
            chat.szNick = msg.param.szNickName
            chat.szChatString = msg.param.szMessageContent
            -- GameChatLayer.addChatRecordWith(chat)
            if nil == self.m_spGameTrumpetBg then
                local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame('sp_trumpet_bg.png')
                if nil ~= frame then
                    local trumpetBg = cc.Sprite:createWithSpriteFrame(frame)
                    local runScene = cc.Director:getInstance():getRunningScene()
                    if nil ~= runScene and nil ~= trumpetBg then
                        self.m_spGameTrumpetBg = trumpetBg
                        trumpetBg:setScaleX(0.0001)
                        runScene:addChild(trumpetBg)
                        local trumpetsize = trumpetBg:getContentSize()
                        trumpetBg:setPosition(appdf.WIDTH * 0.5, appdf.HEIGHT - trumpetsize.height * 0.5)
                        local stencil = display.newSprite():setAnchorPoint(cc.p(0, 0.5))
                        stencil:setTextureRect(cc.rect(0, 0, 700, 50))
                        local notifyClip = cc.ClippingNode:create(stencil):setAnchorPoint(cc.p(0, 0.5))
                        notifyClip:setInverted(false)
                        notifyClip:move(50, 30)
                        notifyClip:addTo(trumpetBg)
                        local notifyText =                        cc.Label:createWithTTF('', 'fonts/round_body.ttf', 24):addTo(notifyClip):setTextColor(
                        cc.c4b(255, 191, 123, 255)
                        ):setAnchorPoint(cc.p(0, 0.5)):enableOutline(cc.c4b(79, 48, 35, 255), 1):move(700, 0)
                        self.m_spGameTrumpetBg.trumpetText = notifyText

                        trumpetBg:runAction(
                        cc.Sequence:create(
                        cc.ScaleTo:create(0.5, 1),
                        cc.CallFunc:create(
                        function()
                            self:onGameTrumpet()
                        end
                        )
                        )
                        )
                    end
                end
            end
        else
            self.m_gameTrumpetList = {}
        end
    elseif group == 'client_task' then -- 任务
        bHandled = true
        --当前场景非任务
        local curScene = self._sceneRecord[#self._sceneRecord]
        if curScene ~= yl.SCENE_TASK and true == GlobalUserItem.bEnableTask then
            NotifyMgr:getInstance():showNotify(self.m_btnTask, msg, cc.p(254, 88))
        end
    elseif group == 'client_friend' then
        bHandled = true
        local curScene = self._sceneRecord[#self._sceneRecord]
        if curScene ~= yl.SCENE_FRIEND then
            NotifyMgr:getInstance():showNotify(self.m_btnFriend, msg, cc.p(254, 88))
        end
    end
    return bHandled
end

function ClientScene:onGameTrumpet()
    if nil ~= self.m_spGameTrumpetBg and 0 ~= #self.m_gameTrumpetList then
        local str = self.m_gameTrumpetList[1]
        table.remove(self.m_gameTrumpetList, 1)
        local text = self.m_spGameTrumpetBg.trumpetText
        if nil ~= text then
            text:setString(str)
            text:setPosition(cc.p(700, 0))
            text:stopAllActions()
            local tmpWidth = text:getContentSize().width
            text:runAction(
            cc.Sequence:create(
            cc.MoveTo:create(16 + (tmpWidth / 172), cc.p(0 - text:getContentSize().width, 0)),
            cc.CallFunc:create(
            function()
                if 0 ~= #self.m_gameTrumpetList then
                    self:onGameTrumpet()
                else
                    self.m_spGameTrumpetBg:runAction(
                    cc.Sequence:create(
                    cc.ScaleTo:create(0.5, 0.0001, 1),
                    cc.CallFunc:create(
                    function()
                        self.m_spGameTrumpetBg:removeFromParent()
                        self.m_spGameTrumpetBg = nil
                    end
                    )
                    )
                    )
                end
            end
            )
            )
            )
        end
    end
end

--请求公告
function ClientScene:requestNotice()
    local url = yl.HTTP_URL .. '/WS/MobileInterface.ashx?action=GetMobileRollNotice'
    appdf.onHttpJsionTable(
    url,
    'GET',
    '',
    function(jstable, jsdata)
        if type(jstable) == 'table' then
            local data = jstable['data']
            local msg = jstable['msg']
            if type(data) == 'table' then
                local valid = data['valid']
                if nil ~= valid and true == valid then
                    local list = data['notice']
                    if type(list) == 'table' then
                        local listSize = #list
                        self.m_nNoticeCount = listSize
                        for i = 1, listSize do
                            local item = {}
                            item.str = list[i].content or ''
                            item.id = self:getNoticeId()
                            item.color = cc.c4b(255, 191, 123, 255)
                            item.autoremove = false
                            item.showcount = 0
                            table.insert(self.m_tabSystemNotice, item)
                        end
                        self:onChangeNotify(self.m_tabSystemNotice[self._sysIndex])
                    end
                end
            end
            if type(msg) == 'string' and '' ~= msg then
                showToast(self, msg, 3)
            end
        end
    end
    )
end

function ClientScene:addNotice(item)
    if nil == item then
        return
    end
    table.insert(self.m_tabInfoTips, 1, item)
    if not self.m_bNotifyRunning then
        self:onChangeNotify(self.m_tabInfoTips[self._tipIndex])
    end
end

function ClientScene:removeNoticeById(id)
    if nil == id then
        return
    end

    local idx = nil
    for k, v in pairs(self.m_tabInfoTips) do
        if nil ~= v.id and v.id == id then
            idx = k
            break
        end
    end

    if nil ~= idx then
        table.remove(self.m_tabInfoTips, idx)
    end
end

function ClientScene:getNoticeId()
    local tmp = self.m_nNotifyId
    self.m_nNotifyId = self.m_nNotifyId + 1
    return tmp
end

function ClientScene:queryUserScoreInfo(queryCallBack)
    local ostime = os.time()
    local url = yl.HTTP_URL .. '/WS/MobileInterface.ashx'

    -- self:showPopWait()
    appdf.onHttpJsionTable(
    url,
    'GET',
    'action=GetScoreInfo&userid=' ..
    GlobalUserItem.dwUserID .. '&time=' .. ostime .. '&signature=' .. GlobalUserItem:getSignature(ostime),
    function(sjstable, sjsdata)
        self:dismissPopWait()
        dump(sjstable, 'sjstable', 5)
        if type(sjstable) == 'table' then
            local data = sjstable['data']
            if type(data) == 'table' then
                local valid = data['valid']
                if true == valid then
                    local score = tonumber(data['Score']) or 0
                    local bean = tonumber(data['Currency']) or 0
                    local ingot = tonumber(data['UserMedal']) or 0
                    local roomcard = tonumber(data['RoomCard']) or 0

                    local needupdate = false
                    if
                    score ~= GlobalUserItem.lUserScore or bean ~= GlobalUserItem.dUserBeans or
                    ingot ~= GlobalUserItem.lUserIngot or
                    roomcard ~= GlobalUserItem.lRoomCard
                    then
                        GlobalUserItem.dUserBeans = bean
                        GlobalUserItem.lUserScore = score
                        GlobalUserItem.lUserIngot = ingot
                        GlobalUserItem.lRoomCard = roomcard
                        needupdate = true
                    end
                    if needupdate then
                        print('update score')
                        --通知更新
                        local eventListener = cc.EventCustom:new(yl.RY_USERINFO_NOTIFY)
                        eventListener.obj = yl.RY_MSG_USERWEALTH
                        cc.Director:getInstance():getEventDispatcher():dispatchEvent(eventListener)
                    end
                    if type(queryCallBack) == 'function' then
                        queryCallBack(needupdate)
                    end
                end
            end
        end
    end
    )
end

function ClientScene:queryTaskInfo()
    local taskResult =    function(result, msg)
        if result == 1 then -- 获取到 SUB_GP_TASK_INFO
            if self.m_bFirstQueryCheckIn and nil ~= self._checkInFrame then
                self.m_bFirstQueryCheckIn = false
                if true == GlobalUserItem.bEnableCheckIn then
                    --签到页面
                    self._checkInFrame:onCheckinQuery()
                else
                    if nil ~= self.m_touchFilter then
                        self.m_touchFilter:dismiss()
                        self.m_touchFilter = nil
                    end
                    -- 显示广告
                    if GlobalUserItem.isShowAdNotice() then
                        local webview =                        appdf.req(appdf.CLIENT_SRC .. 'plaza.views.layer.plaza.WebViewLayer'):create(self)
                        local runScene = cc.Director:getInstance():getRunningScene()
                        if nil ~= runScene then
                            runScene:addChild(webview, yl.ZORDER.Z_AD_WEBVIEW)
                        end
                    end
                end
            end
            -- self:queryLevelInfo()
            if nil ~= self._taskFrame._gameFrame then
                self._taskFrame._gameFrame._shotFrame = nil
                self._taskFrame._gameFrame = nil
            end
            self._taskFrame = nil
        end
    end
    self._taskFrame = TaskFrame:create(self, taskResult)
    self._taskFrame._gameFrame = self._gameFrame
    if nil ~= self._gameFrame then
        self._gameFrame._shotFrame = self._taskFrame
    end
    self._taskFrame:onTaskLoad()
end

function ClientScene:queryLevelInfo()
--[[local levelCallBack = function(result,msg)
			self:onLevelCallBack(result,msg)
		end
	self._levelFrame = LevelFrame:create(self,levelCallBack)	
	self._levelFrame:onLoadLevel()]]
end

function ClientScene:disconnectFrame()
    print('ClientScene:disconnectFrame')
    if nil ~= self._shopDetailFrame and self._shopDetailFrame:isSocketServer() then
        self._shopDetailFrame:onCloseSocket()
        self._shopDetailFrame = nil
    end

    --[[if nil ~= self._levelFrame and self._levelFrame:isSocketServer() then
		self._levelFrame:onCloseSocket()
		self._levelFrame = nil
	end]]
    if nil ~= self._checkInFrame and self._checkInFrame:isSocketServer() then
        self._checkInFrame:onCloseSocket()
        self._checkInFrame = nil
    end

    if nil ~= self._taskFrame and self._taskFrame:isSocketServer() then
        self._taskFrame:onCloseSocket()

        if nil ~= self._taskFrame._gameFrame then
            self._taskFrame._gameFrame._shotFrame = nil
            self._taskFrame._gameFrame = nil
        end
        self._taskFrame = nil
    end
end

function ClientScene:coinDropDownAni(funC)
    local runScene = cc.Director:getInstance():getRunningScene()
    if nil == runScene then
        return
    end
    ExternalFun.popupTouchFilter(1, false)
    if nil == self.m_nodeCoinAni then
        self.m_nodeCoinAni = ExternalFun.loadCSB('plaza/CoinAni.csb', runScene)
        self.m_nodeCoinAni:setPosition(30, yl.HEIGHT + 30)

        self.m_actCoinAni = ExternalFun.loadTimeLine('plaza/CoinAni.csb')
        ExternalFun.SAFE_RETAIN(self.m_actCoinAni)
    end
    local function onFrameEvent(frame)
        if nil == frame then
            return
        end
        local str = frame:getEvent()
        print('frame event ==> ' .. str)
        if str == 'drop_over' then
            self.m_nodeCoinAni:setVisible(false)
            self.m_nodeCoinAni:stopAllActions()
            if type(funC) == 'function' then
                funC()
            end
            ExternalFun.dismissTouchFilter()
        end
    end
    self.m_actCoinAni:setFrameEventCallFunc(onFrameEvent)

    local child = runScene:getChildren() or {}
    local childCount = #child
    self.m_nodeCoinAni:setVisible(true)
    self.m_nodeCoinAni:setLocalZOrder(childCount + 1)
    self.m_nodeCoinAni:stopAllActions()
    self.m_actCoinAni:gotoFrameAndPlay(0, false)
    self.m_nodeCoinAni:runAction(self.m_actCoinAni)
end

-- bNotInsideFriend 非内部好友分享
function ClientScene:popTargetShare(callback, bNotInsideFriend)
    bNotInsideFriend = bNotInsideFriend or false
    local TargetShareLayer = appdf.req(appdf.CLIENT_SRC .. 'plaza.views.layer.plaza.TargetShareLayer')
    local lay = TargetShareLayer:create(callback, bNotInsideFriend)
    self:addChild(lay)
    lay:setLocalZOrder(yl.ZORDER.Z_TARGET_SHARE)
end

function ClientScene:createVoiceBtn(defimg, clickimg, pos, zorder, parent)
    if ClientConfig.UPDATE_TO_APPSTORE == true then
        return
    end

    local sendDataFuc = function(url)
        if url == nil then
            return
        end
        if self._gameFrame ~= nil and self._gameFrame:isSocketServer() == true then
            self._gameFrame:sendDataByVoice(url)
        end
        -- showToast(self, url, 3)
    end

    local VoiceSdk = appdf.getNodeByName(self, 'VoiceSdk')

    VoiceSdk:login()
    VoiceSdk:setSocketCallBack(sendDataFuc)

    parent = parent or self
    zorder = zorder or yl.ZORDER.Z_VOICE_BUTTON
    local function btncallback(ref, tType)
        if tType == ccui.TouchEventType.began then
            self:startVoiceRecord()
        elseif tType == ccui.TouchEventType.ended or tType == ccui.TouchEventType.canceled then
            self:stopVoiceRecord()
        end
    end
    pos = pos or cc.p(100, 100)
    local btn = ccui.Button:create(defimg, clickimg, clickimg)
    btn:setPosition(pos)
    btn:addTo(parent)
    btn:setLocalZOrder(zorder)
    btn:addTouchEventListener(btncallback)
end

function ClientScene:startVoiceRecord()
    self:dispatchMessage('StartRecord')
end

function ClientScene:stopVoiceRecord()
    self:dispatchMessage('StopRecord')
end

function ClientScene:cancelVoiceRecord()
end

-- 检查魔窗值
function ClientScene:checkMagicWindowValue()

    if device.platform == 'windows' or ClientConfig.UPDATE_TO_APPSTORE == true then
        return
    end

    local funC =    function()
        if GlobalUserItem.MagicWindowRoomId == nil then
            local value = MultiPlatform:getInstance():getMagicWindowValue()
            if device.platform == "android" then
                if value ~= '' then
                    local tmp = string.match(value, '%d+')
    
                    if tmp ~= nil and string.len(value) == 6 then
                        -- 房间号
                        GlobalUserItem.MagicWindowRoomId = value
                    elseif string.match(tmp, '^%d+_%d+') ~= nil then
                        -- 匹配战绩数字
                        local record, round = string.match(tmp, '^(%d+)_(%d+)')
    
                        GlobalUserItem.GameRecordInfo = {}
                        GlobalUserItem.GameRecordInfo.RecordId = record
                        GlobalUserItem.GameRecordInfo.RoundId = round
                    end
                end
            elseif device.platform == "ios" then
                local ok, datatable = pcall(function()
                    return cjson.decode(value)
                end)

                if datatable and datatable.roomId and string.len(datatable.roomId) == 6 then                    
                    GlobalUserItem.MagicWindowRoomId = datatable.roomId
                elseif datatable.shareId and string.match(datatable.shareId, '^%d+_%d+') ~= nil then
                    -- 匹配战绩数字
                    local record, round = string.match(tmp, '^(%d+)_(%d+)')

                    GlobalUserItem.GameRecordInfo = {}
                    GlobalUserItem.GameRecordInfo.RecordId = record
                    GlobalUserItem.GameRecordInfo.RoundId = round
                end                
            end
        end

        local curScene = self._sceneRecord[#self._sceneRecord]

        if nil ~= GlobalUserItem.MagicWindowRoomId then
            if curScene ~= yl.SCENE_GAME then
                showToast(self, '加入房间中...', 3)

                PriRoom:getInstance():getNetFrame():onSearchRoom(GlobalUserItem.MagicWindowRoomId)
                GlobalUserItem.MagicWindowRoomId = nil
            else
                GlobalUserItem.MagicWindowRoomId = nil
                showToast(self, '快速进入房间需要您在大厅内才能加入哦!', 2.2)
            end
        elseif GlobalUserItem.GameRecordInfo ~= nil and GlobalUserItem.GameRecordInfo.RecordId ~= nil then
            if curScene ~= yl.SCENE_GAME then
                local PlazaRecordLayer =                appdf.req(appdf.CLIENT_SRC .. 'plaza.views.layer.plaza.PlazaRecordLayer'):create(
                self,
                self:getApp()._gameList
                ):addTo(self)
                PlazaRecordLayer:show()
            else
                GlobalUserItem.GameRecordInfo = nil
                showToast(self, '查看他人战绩功能需要您在大厅内才使用哦!', 2.2)
            end
        end
    end
    if device.platform == 'ios' then
        display.performWithDelayGlobal(funC, 0.25)
    elseif device.platform == 'android' then
        funC()
    end
end

-- 网络监听事件
function ClientScene:onNetWorkStateListener(e)
    local v = e.msg

    if v.netWorkState == nil or v.netWorkState == self.m_networkState then
        return
    end

    local curScene = self._sceneRecord[#self._sceneRecord]

    if v.netWorkState == 0 then
        self.m_networkState = 0

        showToast(self, '检测到您设备网络已断开!', 2)

        if self.m_connState == 1 then
            return
        end

        if curScene == yl.SCENE_GAME then
            self.m_netWorkDialog = nil

            self:onAutoConnServer()
        end
    elseif v.netWorkState == 1 then
        -- 第一次通知
        if self.m_networkState == nil then
            self.m_networkState = 1
            return
        end

        if self.m_netWorkDialog then
            self.m_netWorkDialog:removeSelf()
        end

        -- if self.m_netWorkTipsFuc then
        --     display.unscheduleGlobal(self.m_netWorkTipsFuc)
        -- end
        -- if self.m_netWorkReLoginFuc then
        --     display.unscheduleGlobal(self.m_netWorkReLoginFuc)
        -- end
        self.m_networkState = 1

        if self.m_connState == 1 then
            return
        end

        -- 在游戏中
        if curScene == yl.SCENE_GAME then
            self:showPopWait()

            self.m_connState = 1

            showToast(self, '正在重新连接游戏服务器...', 2)

            display.performWithDelayGlobal(
            function()
                self._gameFrame:OnResetGameEngine()
                self._gameFrame:onLogonRoom()
                self.m_connState = 0
            end,
            2.1
            )
        end
    end
end

function ClientScene:createPriRoomCreateLayer()
    local pri = PriRoom:getInstance()

    if pri:enterRoom(self) == false then
        showToast(self, '该游戏尚未开启私人房模式!', 1.5)
        return
    end

    local lay
    local entergame = self:getEnterGameInfo()
    if nil ~= entergame then
        local modulestr = string.gsub(entergame._KindName, '%.', '/')
        local roomCreateFile = ''

        if device.platform == 'windows' then
            roomCreateFile = 'game/' .. modulestr .. 'src/privateroom/PriRoomCreateLayer.lua'
        else
            roomCreateFile = 'game/' .. modulestr .. 'src/privateroom/PriRoomCreateLayer.luac'
        end

        if cc.FileUtils:getInstance():isFileExist(roomCreateFile) then
            lay = appdf.req(roomCreateFile):create(self)
            -- 绑定回调
            pri:setViewFrame(lay)
        end
    end

    if lay then
        lay:addTo(self)
        lay:show(
        function()
            -- 获取配置信息
            pri:getNetFrame():onGetRoomParameter()
        end
        )
    else
        showToast(self, '该游戏目录不存在!', 1.5)
    end
end

--[[    事件派发
]]
function ClientScene:dispatchMessage(key, msg)
    if type(key) ~= 'string' then
        key = tostring(key)
    end

    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    local event = cc.EventCustom:new(key)
    if msg then
        event.msg = msg
    end
    eventDispatcher:dispatchEvent(event)
end

return ClientScene