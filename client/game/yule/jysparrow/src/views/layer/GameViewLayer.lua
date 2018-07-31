local cmd = appdf.req(appdf.GAME_SRC .. 'yule.jysparrow.src.models.CMD_Game')

local GameViewLayer =
    class(
    'GameViewLayer',
    function(scene)
        local gameViewLayer = cc.CSLoader:createNode(cmd.RES_PATH .. 'game/GameScene.csb')
        return gameViewLayer
    end
)

local ExternalFun = require(appdf.EXTERNAL_SRC .. 'ExternalFun')
local GameLogic = appdf.req(appdf.GAME_SRC .. 'yule.jysparrow.src.models.GameLogic')
local CardLayer = appdf.req(appdf.GAME_SRC .. 'yule.jysparrow.src.views.layer.CardLayer')
local ResultLayer = appdf.req(appdf.GAME_SRC .. 'yule.jysparrow.src.views.layer.ResultLayer')
local GameChatLayer = appdf.req(appdf.CLIENT_SRC .. 'plaza.views.layer.game.GameChatLayer')
local PlayerInfo = appdf.req(appdf.GAME_SRC .. 'yule.jysparrow.src.views.layer.PlayerInfo')
local SettingLayer = appdf.req(appdf.GAME_SRC .. 'yule.jysparrow.src.views.layer.SettingLayer')
local ClipText = appdf.req(appdf.EXTERNAL_SRC .. 'ClipText')
local IntroduceLayer = appdf.req(appdf.GAME_SRC .. 'yule.jysparrow.src.views.layer.IntroduceLayer')
local RuleLayer = appdf.req(appdf.GAME_SRC .. 'yule.jysparrow.src.views.layer.RuleLayer')
local ShareResultLayer = appdf.req(appdf.GAME_SRC .. 'yule.jysparrow.src.views.layer.ShareResultLayer')
local AnimationMgr = appdf.req(appdf.EXTERNAL_SRC .. 'AnimationMgr')

local anchorPointHead = {cc.p(1, 1), cc.p(0, 0.5), cc.p(0, 0), cc.p(1, 0.5)}
local posHead = {cc.p(577, 295), cc.p(165, 332), cc.p(166, 257), cc.p(724, 273)}
local posReady = {cc.p(-333, 0), cc.p(135, 0), cc.p(516, -80), cc.p(-134, 0)}
local posPlate = {cc.p(667, 589), cc.p(237, 464), cc.p(667, 174), cc.p(1093, 455)}
local posChat = {cc.p(873, 660), cc.p(229, 558), cc.p(270, 285), cc.p(1095, 528)}
local dirPos = {cc.p(28.53, 82.5), cc.p(83, 28.41), cc.p(137.36, 83), cc.p(83, 138.63)}
--

local VOICE_BTN_NAME = '__voice_record_button__' --语音按钮名字，可以获取语音按钮，控制显示与否

-- GameViewLayer.BT_MENU				= 10 				--按钮开关按钮
GameViewLayer.BT_CHAT = 11 --聊天按钮
GameViewLayer.BT_SET = 12 --设置
GameViewLayer.CBX_SOUNDOFF = 13 --声音开关
GameViewLayer.BT_EXIT = 14 --退出按钮
GameViewLayer.BT_TRUSTEE = 15 --托管按钮
GameViewLayer.BT_HOWPLAY = 16 --玩法按钮
GameViewLayer.BT_RULE = 17 --规则按钮

GameViewLayer.BT_START = 20 --开始按钮

GameViewLayer.TAG_GUI_DI = 30 --癞子 底
GameViewLayer.TAG_GUI_1 = 31 --鬼牌1
GameViewLayer.TAG_GUI_2 = 32 --鬼牌2

GameViewLayer.NODE_INFO_TAG = 100 --信息界面

GameViewLayer.BT_CHI = 30 --游戏操作按钮吃
GameViewLayer.BT_GANG = 31 --游戏操作按钮杠
GameViewLayer.BT_PENG = 32 --游戏操作按钮碰
GameViewLayer.BT_HU = 33 --游戏操作按钮胡
GameViewLayer.BT_GUO = 34 --游戏操作按钮过
GameViewLayer.BT_TING = 35 --游戏操作按钮听

GameViewLayer.ZORDER_OUTCARD = 40 -- 麻将
GameViewLayer.ZORDER_ACTION = 50 -- 操作提示  如:胡/碰/杠等表现
GameViewLayer.ZORDER_CHAT = 60 -- 聊天内容，表情
GameViewLayer.ZORDER_SETTING = 70
GameViewLayer.ZORDER_INFO = 90
GameViewLayer.ZORDER_RESULT = 100
GameViewLayer.ZORDER_SHARE_RESULT = 110

function GameViewLayer:onInitData()
    self.cbActionCard = 0
    self.cbOutCardTemp = 0
    self.bListenBtnEnabled = false
    self.chatDetails = {}
    self.cbAppearCardIndex = {}
    self.bChoosingHu = false
    self.m_bNormalState = {}
    self.m_nLeftCard = 0
    self.m_nAllCard = 0

    -- 用户头像
    self.m_tabUserHead = {}

    --房卡需要
    self.m_UserItem = {}

    self.curPointToChair = INVALID_CHAIR

    -- 语音动画
    AnimationMgr.loadAnimationFromFrame('record_play_ani_%d.png', 1, 3, cmd.VOICE_ANIMATION_KEY)
end

function GameViewLayer:onResetData()
    self._cardLayer:onResetData()

    self.bChoosingHu = false
    self.cbOutCardTemp = 0
    self.cbAppearCardIndex = {}

    self.m_nLeftCard = 0

    self.TrustShadow:setVisible(false)

    self.nCardLeft = self.m_nAllCard
    self.labelCardLeft:setString(string.format('%d', self.nCardLeft))
    self:ShowGameBtn(GameLogic.WIK_NULL)

    for i = 1, cmd.GAME_MAX_PLAYER do
        if nil ~= self.m_tabUserHead[i] then
            self.m_tabUserHead[i]:showBank(false)
        end
    end

    self._cardLayer:onResetData()

    self.curPointToChair = INVALID_CHAIR

    self:resetMagicInfo()
end

function GameViewLayer:onExit()
    self.m_UserItem = {}
    AnimationMgr.removeCachedAnimation(cmd.VOICE_ANIMATION_KEY)
end

function GameViewLayer:getParentNode()
    return self._scene
end

local this
function GameViewLayer:ctor(scene)
    this = self
    self._scene = scene
    self:onInitData()
    self:preloadUI()
    self:initButtons()
    self:initUserInfo()
    self._cardLayer = CardLayer:create(self):addTo(self:getChildByName('Node_MaJong')) --牌图层
    self._resultLayer = ResultLayer:create(self):addTo(self, GameViewLayer.ZORDER_RESULT):hideLayer() --结算框
    self._chatLayer = GameChatLayer:create(self._scene._gameFrame):addTo(self, GameViewLayer.ZORDER_CHAT) --聊天框
    self._shareResultLayer = ShareResultLayer:create(self):addTo(self, GameViewLayer.ZORDER_SHARE_RESULT):hideLayer()
    --特殊结局分享界面
    self._ruleLayer = RuleLayer:create(self):setVisible(false):addTo(self)

    --左上角游戏信息
    --local CsbgameInfoNode = self:getChildByName("FileNode_info")

    --播放背景音乐
    if GlobalUserItem.bVoiceAble == true then
        ExternalFun.playGameBackgroudAudio()
    end

    -- self.gameInfoNode = cc.CSLoader:createNode(cmd.RES_PATH.."game/NodeInfo.csb"):addTo(self, GameViewLayer.ZORDER_INFO)
    -- self.gameInfoNode:setPosition(cc.p(0, 750))

    --剩余牌数
    self.nCardLeft = 0
    self.labelCardLeft = appdf.getNodeByName(self, 'atlas_last')
    self.labelCardLeft:setString(string.format('%d', self.nCardLeft))
    self.labelCardLeft:setString('00')

    --指针
    self.userPoint = appdf.getNodeByName(self, 'sp_clock')

    local dir = {
        {'东', 270},
        {'南', 0},
        {'西', 90},
        {'北', 180}
    }

    local chair = self._scene:GetMeChairID()
    self.userPoint:setRotation(dir[chair + 1][2])
    self:resetDirection()
    --倒计时
    self.labelClock = appdf.getNodeByName(self, 'AsLab_time')

    --出牌界面
    self.sprOutCardBg = cc.Sprite:create(cmd.RES_PATH .. 'game/outCardBg.png'):addTo(self, GameViewLayer.ZORDER_OUTCARD)
    self.sprOutCardBg:setVisible(false)
    self.sprMajong = self._cardLayer:createMyActiveCardSprite(0x35, false):addTo(self.sprOutCardBg)
    self.sprMajong:setPosition(
        self.sprOutCardBg:getContentSize().width / 2,
        self.sprOutCardBg:getContentSize().height / 2
    )

    --黄庄
    self.sprNoWin = cc.Sprite:create(cmd.RES_PATH .. 'gameResult/kuang-07.png'):addTo(self, GameViewLayer.ZORDER_RESULT)
    self.sprNoWin:setPosition(cc.p(667, 400))
    self.sprNoWin:setVisible(false)

    --黄庄图片
    local icon = cc.Sprite:create(cmd.RES_PATH .. 'gameResult/huangzhuang.png')
    icon:addTo(self.sprNoWin)
    icon:setPosition(cc.p(249, 230))

    --准备按钮
    local btnReady =
        ccui.Button:create(
        cmd.RES_PATH .. 'game/csmj_btn_play.png',
        cmd.RES_PATH .. 'game/csmj_btn_play.png',
        cmd.RES_PATH .. 'game/csmj_btn_play.png'
    )
    btnReady:addTo(self.sprNoWin)
    btnReady:setPosition(cc.p(249, 70))

    --按钮回调
    local btnReadyCallback = function(ref, eventType)
        if eventType == ccui.TouchEventType.ended then
            -- 准备
            self._scene:sendGameStart()
            self:showNoWin(false)
            self:onResetData()

            --显示总结算
            if PriRoom:getInstance()._priView.showPrivateGameEnd then
                PriRoom:getInstance()._priView.showPrivateGameEnd()
            end
        end
    end

    btnReady:addTouchEventListener(btnReadyCallback)

    --节点事件
    local function onNodeEvent(event)
        if event == 'exit' then
            self:onExit()
        end
    end
    self:registerScriptHandler(onNodeEvent)

    --托管覆盖层
    self.TrustShadow = ccui.ImageView:create(cmd.RES_PATH .. 'game/btn_trustShadow.png')
    self.TrustShadow:addTo(self)
    self.TrustShadow:setTouchEnabled(true)
    -- self.TrustShadow:setSwallowsTouches(false)
    self.TrustShadow:setPosition(cc.p(667, 100))
    self.TrustShadow:setVisible(false)
    --取消托管按钮
    local btnExitTrust =
        ccui.Button:create(
        cmd.RES_PATH .. 'game/btn_trustCancel1.png',
        cmd.RES_PATH .. 'game/btn_trustCancel2.png',
        cmd.RES_PATH .. 'game/btn_trustCancel1.png'
    )
    btnExitTrust:addTo(self.TrustShadow)
    btnExitTrust:setPosition(cc.p(1175, 62))
    --按钮回调
    local btnCallback = function(ref, eventType)
        if eventType == ccui.TouchEventType.ended then
            -- 取消托管
            self._scene:sendUserTrustee()
            self.TrustShadow:setVisible(false)
        end
    end
    btnExitTrust:addTouchEventListener(btnCallback)

    --玩家胡牌提示
    self.nodeTips = cc.Node:create()
    self.nodeTips:addTo(self, GameViewLayer.ZORDER_ACTION)
    self.nodeTips:setPosition(cc.p(667, 215))
    self:ChangeGameBg()
end
function GameViewLayer:ChangeGameBg()
    local imgbg1 = string.format('game/csmj_%s.png', GlobalUserItem.GameBg)
    local gamebg = appdf.getNodeByName(self, 'background')
    gamebg:setTexture(imgbg1)
    local imgbg2 = string.format('game/csmj_icon1_%s.png', GlobalUserItem.GameBg)
    local Sprite_2 = appdf.getNodeByName(gamebg, 'Sprite_2')
    Sprite_2:setTexture(imgbg2)
    local imgbg3 = string.format('game/csmj_icon2_%s.png', GlobalUserItem.GameBg)
    local sp_clock = appdf.getNodeByName(gamebg, 'sp_clock')
    sp_clock:setTexture(imgbg3)
end
function GameViewLayer:addPrivateGameLayer(layer)
    self:getChildByName('background'):addChild(layer)
end

function GameViewLayer:preloadUI()
    --导入动画
    local animationCache = cc.AnimationCache:getInstance()
    for i = 1, 12 do
        local strColor = ''
        local index = 0
        if i <= 6 then
            strColor = 'white'
            index = i
        else
            strColor = 'red'
            index = i - 6
        end
        local animation = cc.Animation:create()
        animation:setDelayPerUnit(0.1)
        animation:setLoops(1)
        for j = 1, 9 do
            local strFile = cmd.RES_PATH .. 'Animate_sice_' .. strColor .. string.format('/sice_%d.png', index)
            local spFrame = cc.SpriteFrame:create(strFile, cc.rect(133 * (j - 1), 0, 133, 207))
            animation:addSpriteFrame(spFrame)
        end

        local strName = 'sice_' .. strColor .. string.format('_%d', index)
        animationCache:addAnimation(animation, strName)
    end
end

--初始化玩家信息
function GameViewLayer:initUserInfo()
    local nodeName = {
        'FileNode_3',
        'FileNode_4',
        'FileNode_2',
        'FileNode_1'
    }

    --准备状态
    local posACtion = {
        cc.p(100, -30),
        cc.p(0, -140),
        cc.p(0, -140),
        cc.p(-100, -30)
    }

    self.nodePlayer = {}
    self.readySpr = {}

    local faceNode = self:getChildByName('Node_User')
    for i = 1, cmd.GAME_MAX_PLAYER do
        local userFace = faceNode:getChildByName(nodeName[i])
        if userFace ~= nil then
            self.nodePlayer[i] = userFace
            -- self.nodePlayer[i]:setLocalZOrder(1)
            self.nodePlayer[i]:setVisible(true)

            local sprPath = cmd.RES_PATH .. 'game/Ready_ok.png'
            local sprReady = ccui.ImageView:create(sprPath)
            sprReady:addTo(userFace)
            sprReady:setVisible(false)
            sprReady:setPosition(posACtion[i])
            table.insert(self.readySpr, sprReady)
        end
    end
end

--显示房间规则
function GameViewLayer:showRules(bShow, rules, mode)
    self._ruleLayer:showRule(bShow, rules, mode)
end

--更新玩家准备状态
function GameViewLayer:showUserState(viewid, isReady)
    print('更新用户状态', viewid, isReady, #self.readySpr)
    local spr = self.readySpr[viewid]
    if nil ~= spr then
        spr:setVisible(isReady)
    end
end

--初始化界面上button
function GameViewLayer:initButtons()
    --按钮回调
    local btnCallback = function(ref, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:onButtonClickedEvent(ref:getTag(), ref)
        elseif eventType == ccui.TouchEventType.began and ref:getTag() == GameViewLayer.BT_VOICE then
        --self:onButtonClickedEvent(GameViewLayer.BT_VOICEOPEN, ref)
        end
    end

    local mainBackGround = appdf.getNodeByName(self, 'background')

    self.layoutShield = self:getChildByName('Image_Touch')
    self.layoutShield:setTouchEnabled(true)

    local btSet = appdf.getNodeByName(self, 'bt_set')
    btSet:addTouchEventListener(btnCallback)
    btSet:setTag(GameViewLayer.CBX_SOUNDOFF)

    local btHowPlay = appdf.getNodeByName(self, 'bt_help') --玩法
    btHowPlay:addTouchEventListener(btnCallback)
    btHowPlay:setTag(GameViewLayer.BT_HOWPLAY)

    --开始
    self.btStart = self:getChildByName('bt_start'):setLocalZOrder(2):setVisible(false)
    self.btStart:addTouchEventListener(btnCallback)
    self.btStart:setTag(GameViewLayer.BT_START)

    -- 聊天按钮
    local btnChat =
        ccui.Button:create(
        cmd.RES_PATH .. 'game/csmj_btn_chat.png',
        cmd.RES_PATH .. 'game/csmj_btn_chat.png',
        cmd.RES_PATH .. 'game/csmj_btn_chat.png'
    ):move(1268, 290):addTo(mainBackGround)
    btnChat:setTag(GameViewLayer.BT_CHAT)
    btnChat:addTouchEventListener(btnCallback)

    -- 语音按钮 gameviewlayer -> gamelayer -> clientscene
    self:getParentNode():getParentNode():createVoiceBtn(
        cmd.RES_PATH .. 'game/csmj_btn_yy.png',
        cmd.RES_PATH .. 'game/csmj_btn_yy.png',
        cc.p(1268, 200),
        0,
        mainBackGround
    )

    --游戏操作按钮
    --获取操作按钮node
    local nodeOpBar = self:getChildByName('FileNode_Op')
    --广东麻将只有4个，不同游戏自行添加
    local btGang = nodeOpBar:getChildByName('Button_gang') --杠
    btGang:setEnabled(false)
    btGang:addTouchEventListener(btnCallback)
    btGang:setTag(GameViewLayer.BT_GANG)

    local btPeng = nodeOpBar:getChildByName('Button_pen') --碰
    btPeng:setEnabled(false)
    btPeng:addTouchEventListener(btnCallback)
    btPeng:setTag(GameViewLayer.BT_PENG)

    local btHu = nodeOpBar:getChildByName('Button_hu') --胡
    btHu:setEnabled(false)
    btHu:addTouchEventListener(btnCallback)
    btHu:setTag(GameViewLayer.BT_HU)

    local btGuo = nodeOpBar:getChildByName('Button_guo') --过
    btGuo:setEnabled(false)
    btGuo:addTouchEventListener(btnCallback)
    btGuo:setTag(GameViewLayer.BT_GUO)
end

--按钮控制（下拉菜单下拉，隐藏语音按钮）
function GameViewLayer:showMenu(bVisible)
    -- 按钮背景
    local menuBg = self:getChildByName('sp_tableBtBg')
    if menuBg:isVisible() == bVisible then
        return false
    end

    self.curShowMenu = bVisible

    local btnMenu = self:getChildByName('bt_menu')
    self.layoutShield:setTouchEnabled(true)
    menuBg:setVisible(bVisible)

    if bVisible == true then
        btnMenu:loadTextureNormal('game/button-04.png')
    elseif bVisible == false then
        btnMenu:loadTextureNormal('game/button-03.png')
    end

    return true
end

--更新用户显示
function GameViewLayer:OnUpdateUser(viewId, userItem)

    if not viewId or viewId == yl.INVALID_CHAIR then
        print('OnUpdateUser viewId is nil')
        return
    end

    if nil == userItem then
        return
    end
    self.m_UserItem[viewId] = userItem

    if nil == self.m_tabUserHead[viewId] then
        local sendMagicMsg = function(idx, toId)
            self._scene._gameFrame:sendMagicBrowChat(idx, toId)
        end

        local getUserTable = function()
            return self.m_UserItem
        end

        local playerInfo = PlayerInfo:create(userItem, viewId, sendMagicMsg, getUserTable)
        self.m_tabUserHead[viewId] = playerInfo
        self.nodePlayer[viewId]:addChild(playerInfo)
    else
        self.m_tabUserHead[viewId].m_userItem = userItem
        self.m_tabUserHead[viewId]:updateStatus()
    end

    --掉线头像变灰
    local avatar = appdf.getNodeByName(self.nodePlayer[viewId], 'user_avatar')
    if userItem.cbUserStatus == yl.US_OFFLINE then
        convertToGraySprite(avatar)
    else
        convertToNormalSprite(avatar)
    end
end

function GameViewLayer:refreshStartButton(visInvite)
    if visInvite == false then
        self.btStart:setPositionX(display.width / 2)
    else
        self.btStart:setPositionX(802)
    end
end

--玩家退出，移除头像信息
function GameViewLayer:OnUpdateUserExit(viewId)
    print('移除用户', viewId)
    if nil ~= self.m_tabUserHead[viewId] then
        self.m_tabUserHead[viewId] = nil --退出依然保存信息
        self.nodePlayer[viewId]:removeAllChildren()
        self.m_UserItem[viewId] = nil
        self.readySpr[viewId] = nil
    end
end

-- 文本聊天
function GameViewLayer:onUserChat(chatdata, viewId)
    local playerItem = self.m_tabUserHead[viewId]
    if nil ~= playerItem then
        playerItem:textChat(chatdata.szChatString)
    -- self._chatLayer:showGameChat(false)
    end
end

-- 表情聊天
function GameViewLayer:onUserExpression(chatdata, viewId)
    local playerItem = self.m_tabUserHead[viewId]
    if nil ~= playerItem then
        playerItem:browChat(chatdata.wItemIndex)
    -- self._chatLayer:showGameChat(false)
    end
end

function GameViewLayer:userMagicExpression(dwSendViewID, dwTargerViewID, wItemIndex)
    -- boom00    17     5
    -- chiken00  19     2
    -- rose00    20     3
    -- tomato00  18     1
    -- water00   18     4

    local sendHead = self.nodePlayer[dwSendViewID]
    local targerHead = self.nodePlayer[dwTargerViewID]
    if targerHead == nil or sendHead == nil then
        return
    end
    local res = {'tomato', 'chiken', 'rose', 'water', 'boom'}
    local juli =
        cc.pGetDistance(
        cc.p(sendHead:getPositionX(), sendHead:getPositionY()),
        cc.p(targerHead:getPositionX(), targerHead:getPositionY())
    )
    --print("距离 = "..juli)
    local time = 0
    if juli > 1000 then
        time = 1.0
    elseif juli < 250 then
        time = 0.4
    else
        time = 0.8
    end
    --print("道具  = ".."public/ico_"..res[wItemIndex]..".png")
    local itemSprite = cc.Sprite:create('public/ico_' .. res[wItemIndex] .. '.png')
    itemSprite:setPosition(cc.p(sendHead:getPositionX(), sendHead:getPositionY()))
    self:addChild(itemSprite, 1000000)

    local delayTime = cc.DelayTime:create(0.2)
    local moveTo = cc.MoveTo:create(time, cc.p(targerHead:getPositionX(), targerHead:getPositionY()))
    local rotate = cc.RotateBy:create(time, 3600)
    local spawn = cc.Spawn:create(moveTo, rotate)
    itemSprite:runAction(
        cc.Sequence:create(
            delayTime,
            spawn,
            cc.RemoveSelf:create(),
            cc.CallFunc:create(
                function()
                    AudioEngine.playEffect('public/' .. res[wItemIndex] .. '.mp3')
                    local framesNum = {18, 19, 20, 18, 17}
                    local str = '#' .. res[wItemIndex] .. '00' .. '.png'
                    -- print("str = "..str)
                    local siceAni1 = display.newSprite(str):addTo(targerHead)
                    siceAni1:setLocalZOrder(1000)
                    siceAni1:setPosition(targerHead:getContentSize().width / 2, targerHead:getContentSize().height / 2)

                    -- 实现精灵帧动画
                    -- str = res[wItemIndex].."%02d.png"
                    local frames = display.newFrames(res[wItemIndex] .. '%02d.png', 0, framesNum[wItemIndex])
                    local animation = display.newAnimation(frames, 0.1)

                    local args = {
                        showDelay = 0,
                        delay = 0,
                        removeSelf = 1,
                        onComplete = callback
                    }
                    siceAni1:playAnimationOnce(animation, args)
                end
            )
        )
    )
end

--显示语音
function GameViewLayer:ShowUserVoice(viewid, isPlay)
    --取消文字，表情
    local playerItem = self.m_tabUserHead[viewid]
    if nil ~= playerItem then
        if isPlay then
            playerItem:onUserVoiceStart()
        else
            playerItem:onUserVoiceEnded()
        end
    end
end

--按键事件
function GameViewLayer:onButtonClickedEvent(tag, ref)
    if tag == GameViewLayer.BT_START then
        self.btStart:setVisible(false)
        self._scene:sendGameStart()

        if self.removeGuiInfo then
            self.removeGuiInfo()
        end

        self._resultLayer:hideLayer()
    elseif tag == GameViewLayer.BT_CHAT then
        -- self:showMenu(false)
        self._chatLayer:show()
    elseif tag == GameViewLayer.CBX_SOUNDOFF then
        -- self:showMenu(false)
        local set =
            SettingLayer:create(
            self,
            function()
                self:ChangeGameBg()
            end,
            function()
                self:Changegpbackground()
            end
        )
        self:addChild(set, GameViewLayer.ZORDER_SETTING) --70
        set:show()
    elseif tag == GameViewLayer.BT_HOWPLAY then
        local introduce = IntroduceLayer:create(self._scene)
        self:addChild(introduce, 41)
        introduce:show()
    elseif tag == GameViewLayer.BT_TRUSTEE then
        self._scene:sendUserTrustee()
    elseif tag == GameViewLayer.BT_PENG then
        --发送碰牌
        local cbOperateCard = {self.cbActionCard, self.cbActionCard, self.cbActionCard}
        self._scene:sendOperateCard(GameLogic.WIK_PENG, cbOperateCard)

        self:ShowGameBtn(GameLogic.WIK_NULL)
    elseif tag == GameViewLayer.BT_GANG then
        local cbOperateCard = {self.cbActionCard, self.cbActionCard, self.cbActionCard}
        self._scene:sendOperateCard(GameLogic.WIK_GANG, cbOperateCard)

        self:ShowGameBtn(GameLogic.WIK_NULL)
    elseif tag == GameViewLayer.BT_HU then
        local cbOperateCard = {self.cbActionCard, 0, 0}
        self._scene:sendOperateCard(GameLogic.WIK_CHI_HU, cbOperateCard)

        self:ShowGameBtn(GameLogic.WIK_NULL)
    elseif tag == GameViewLayer.BT_GUO then
        if not self.bListenBtnEnabled and not self._cardLayer.bChoosingOutCard and not self.bChoosingHu then
            local cbOperateCard = {0, 0, 0}
            self._scene:sendOperateCard(GameLogic.WIK_NULL, cbOperateCard)
        end

        self:ShowGameBtn(GameLogic.WIK_NULL)
    else
    end
end

--更新操作按钮状态
function GameViewLayer:ShowGameBtn(cbActionMask, cbGangData, gangInfo)
    --获取node
    local OpNode = self:getChildByName('FileNode_Op')
    local btGang = OpNode:getChildByName('Button_gang') --杠
    local btPeng = OpNode:getChildByName('Button_pen') --碰
    local btHu = OpNode:getChildByName('Button_hu') --胡
    local btGuo = OpNode:getChildByName('Button_guo') --过
    local Gang3 = OpNode:getChildByName('Image_1') --3杠
    local Gang2 = OpNode:getChildByName('Image_2') --2杠

    OpNode:setVisible(true)
    if cbActionMask == GameLogic.WIK_NULL then
        OpNode:setVisible(false)
        btGang:setEnabled(false)
        btPeng:setEnabled(false)
        btHu:setEnabled(false)
        btGuo:setEnabled(false)
        return
    end

    local otherAction = 0 --0无操作 1碰 2杠  3胡

    local gangCallback = function(ref, eventType)
        if eventType == ccui.TouchEventType.ended then
            local tag = ref:getTag()
            print('TAG:' .. tag)
            local cbOperateCard = {cbGangData[tag], cbGangData[tag], cbGangData[tag]}
            self._scene:sendOperateCard(GameLogic.WIK_GANG, cbOperateCard)
        end
    end

    --通过动作码，判断操作按钮状态
    if bit:_and(cbActionMask, GameLogic.WIK_GANG) ~= GameLogic.WIK_NULL then
        btGang:setEnabled(true)
        otherAction = 2
    end

    if otherAction == 2 and cbGangData then
        assert(type(cbGangData) == 'table')

        local pos
        local tarBg = nil
        if #cbGangData == 2 then
            Gang2:setVisible(true)
            Gang3:setVisible(false)

            pos = {cc.p(30, 70), cc.p(150, 70)}
            tarBg = Gang2

            for i = 1, 2 do
                local gang =
                    tarBg:getChildByName('Panel_' .. i):setTag(i):setTouchEnabled(true):addTouchEventListener(
                    gangCallback
                )
            end
        elseif #cbGangData == 3 then
            Gang3:setVisible(true)
            Gang2:setVisible(false)

            pos = {cc.p(30, 70), cc.p(150, 70), cc.p(270, 70)}
            tarBg = Gang3

            for i = 1, 3 do
                local gang =
                    tarBg:getChildByName('Panel_' .. i):setTag(i):setTouchEnabled(true):addTouchEventListener(
                    gangCallback
                )
            end
        end

        for i = 1, #cbGangData do
            local p2a = pos[i]

            local cards =
                self._cardLayer:createActiveCardInfo(
                cmd.MY_VIEWID,
                {cbCardNum = 4, cbCardValue = {cbGangData[i]}, cbType = gangInfo[i]}
            )
            for j = 1, #cards do
                cards[j]:setScale(0.8)
                cards[j]:setPosition(cc.pAdd(cc.p(cards[j]:getPosition()), p2a))

                tarBg:addChild(cards[j])
            end
        end
    else
        -- 非杠牌
        Gang3:setVisible(false)
        Gang2:setVisible(false)
    end

    if bit:_and(cbActionMask, GameLogic.WIK_PENG) ~= GameLogic.WIK_NULL then
        btPeng:setEnabled(true)
        otherAction = 1
    end

    if bit:_and(cbActionMask, GameLogic.WIK_CHI_HU) ~= GameLogic.WIK_NULL then
        btHu:setEnabled(true)
        otherAction = 3
    end

    -- 无任何操作，不显示操作栏
    if otherAction == 0 then
        OpNode:setVisible(false)
    end

    btGuo:setEnabled(true)
end
--根据自己的椅子号来重新规整东南西北
function GameViewLayer:resetDirection()
    --local dirPos = {cc.p(28.53, 82.5), cc.p(83, 28.41), cc.p(137.36, 83), cc.p(83, 138.63)}--东南西北方向的位置
    local dirName = {
        'point1_1',
        'point2_2',
        'point3_3',
        'point4_4'
    }
    local playerNum = PriRoom:getInstance():getChairCount()
    if playerNum == 2 then
        if self._scene:GetMeChairID() ~= 0 then
            local sprPointW = self.userPoint:getChildByName(dirName[1])
            local sprPointE = self.userPoint:getChildByName(dirName[3])
            sprPointW:setPosition(dirPos[3])
            sprPointE:setPosition(dirPos[1])
            sprPointE:setScale(-1)
            sprPointW:setScale(-1)
        end
    elseif playerNum == 3 then
        --1换西北,3换东北
        if self._scene:GetMeChairID() == 0 then
            local sprPointE = self.userPoint:getChildByName(dirName[3])
            local sprPointN = self.userPoint:getChildByName(dirName[4])
            sprPointE:setPosition(dirPos[4])
            sprPointN:setPosition(dirPos[3])
            sprPointE:setRotation(0)
            sprPointN:setRotation(180)
        elseif self._scene:GetMeChairID() == 2 then
            local sprPointW = self.userPoint:getChildByName(dirName[1])
            local sprPointN = self.userPoint:getChildByName(dirName[4])
            sprPointW:setPosition(dirPos[4])
            sprPointN:setPosition(dirPos[1])
            sprPointW:setRotation(180)
            sprPointN:setRotation(360)
        end
    end
end
--玩家指向刷新
function GameViewLayer:OnUpdataClockPointView(viewId)
    if self.curPointToChair == viewId then
        return
    end
    local chair = self._scene:SwitchViewChairID(viewId)
    self.curPointToChair = viewId

    -- 东南西北
    local viewImage = {
        'point1_1',
        'point2_2',
        'point3_3',
        'point4_4'
    }

    for i = 1, 4 do
        local sprPoint = self.userPoint:getChildByName(viewImage[i])
        if nil ~= sprPoint then
            local light = sprPoint:getChildByName('point_s')
            if viewId == i - 1 then
                sprPoint:setEnabled(false)
                light:setVisible(true)
                light:runAction(
                    cc.RepeatForever:create(cc.Sequence:create(cc.FadeOut:create(1.0), cc.FadeIn:create(0.02)))
                )
            else
                sprPoint:setEnabled(true)
                light:setVisible(false)
            end
        end
    end
end

--设置转盘时间
function GameViewLayer:OnUpdataClockTime(time)
    if 10 > time then
        self.labelClock:setString(string.format('0%d', time))
    else
        self.labelClock:setString(string.format('%d', time))
    end
end

--刷新剩余牌数
function GameViewLayer:onUpdataLeftCard(numCard)
    self.nCardLeft = numCard
    self.labelCardLeft:setString(string.format('%d', self.nCardLeft))
end

--消息操作处理
function GameViewLayer:resetMagicInfo()
    -- local majongNode = self.gameInfoNode:getChildByName("magicBg_4")
    -- majongNode:setVisible(false)
    -- for i=1,2 do
    -- 	local card = majongNode:getChildByName(string.format("majongNode_%d", i))
    -- 	card:setVisible(false)
    -- end
end

--显示癞子信息
function GameViewLayer:onUpdataMagicCard(cbCardIndex, isAni) --此处为索引
    dump('显示癞子信息')
    --是否是鬼牌场
    local isMagic = false
    local isMagicWhite = false
    local cbMagicIndex = cbCardIndex
    -- 鬼牌数据
    local count = 0
    if cbMagicIndex[1] == 34 and cbMagicIndex[2] == 33 then
        isMagicWhite = true
    end

    for i = 1, #cbMagicIndex do
        if cbMagicIndex[i] ~= nil and cbMagicIndex[i] ~= 34 then
            isMagic = true
        end
    end

    -- 无鬼
    if isMagic == false then
        return
    end

    -- 鬼牌个数
    for i = 1, #cbMagicIndex do
        if cbMagicIndex[i] ~= 34 then
            count = count + 1
        end
    end

    --判断本局是不是鬼牌模式
    if count == 1 then
        self.gp = 1
    else
        self.gp = nil
    end
    local source
    local target = {}
    -- count == 1 属于翻鬼模式
    if count == 1 then
        if cbCardIndex[1] == 0 then
            source = GameLogic.SwitchToCardData(cbMagicIndex[1] + 1)
        else
            source = GameLogic.SwitchToCardData(cbMagicIndex[1])
        end
        table.insert(target, GameLogic.SwitchToCardData(cbMagicIndex[1] + 1))

    -- elseif count == 2 then
    --     source = GameLogic.SwitchToCardData((cbMagicIndex[1] + 1))
    --     table.insert(target, GameLogic.SwitchToCardData(cbMagicIndex[2] + 1))
    --     table.insert(target, GameLogic.SwitchToCardData(cbMagicIndex[3] + 1))
    end
    -- 动画完成回调
    local actionComplete =
        function()
        -- table.remove(cbMagicIndex, 1)
        self._cardLayer.cbMagicData = cbMagicIndex
        self._cardLayer:sortHandCard(cmd.MY_VIEWID)

        self._cardLayer:offsetLastHandCard(cmd.MY_VIEWID)

        if not isAni or isMagicWhite then
            local diName = ''
            if count == 1 then
                -- 随机翻牌做鬼
                diName = 'game/csmj_icon3_' .. GlobalUserItem.GameBg .. '.png'
                local gui =
                    self._cardLayer:createOutOrActiveCardSprite(cmd.MY_VIEWID, target[1], false, true):addTo(self):setScale(
                    0.8
                ):setLocalZOrder(2):setPosition(83, 670):setTag(GameViewLayer.TAG_GUI_1)
                local di =
                    display.newSprite(diName):addTo(self):setPosition(70, 670):setLocalZOrder(1):setTag(
                    GameViewLayer.TAG_GUI_DI
                )
            -- elseif count == 2 then
            --     diName = 'game/kuang-10.png'

            --     for i = 1, 2 do
            --         local gui =
            --             self._cardLayer:createOutOrActiveCardSprite(cmd.MY_VIEWID, target[i], false):addTo(self):setScale(
            --             0.8
            --         ):setLocalZOrder(1 + i):move(65 + (i - 1) * 40, 670):setTag(
            --             i == 1 and GameViewLayer.TAG_GUI_1 or GameViewLayer.TAG_GUI_2
            --         )
            --     end
            end
        end

        self.removeGuiInfo = function()
            self:removeChildByTag(GameViewLayer.TAG_GUI_DI)
            self:removeChildByTag(GameViewLayer.TAG_GUI_1)
            -- self:removeChildByTag(GameViewLayer.TAG_GUI_2)
        end
    end

    -- 断线重连进入 或者 白板做鬼，直接亮鬼
    if not isAni or isMagicWhite == true then
        actionComplete()
    elseif isMagic == true then
        local card =
            self._cardLayer:createOutOrActiveCardSprite(cmd.MY_VIEWID, source, false):addTo(self):setScale(1.5):setPosition(
            display.width / 2,
            display.height / 2
        )

        self._cardLayer:showActiveCardBack(cmd.MY_VIEWID, card)
        -- 翻转
        card:runAction(
            cc.Sequence:create(
                cc.ScaleTo:create(0.3, -1.5, 1.5),
                cc.CallFunc:create(
                    function()
                        -- 显示第一张牌
                        local fan =
                            self._cardLayer:createOutOrActiveCardSprite(cmd.MY_VIEWID, source, false):addTo(self):setScale(
                            1.5
                        ):setPosition(display.width / 2, display.height / 2)
                        card:removeSelf()
                        -- 延迟时间后，显示真正的鬼牌
                        display.performWithDelayGlobal(
                            function()
                                fan:runAction(
                                    cc.Sequence:create(
                                        cc.ScaleTo:create(0.3, 0.5, 0.5),
                                        cc.CallFunc:create(
                                            function()
                                                fan:removeSelf()

                                                if count == 1 then
                                                    -- 显示鬼牌
                                                    local gui =
                                                        self._cardLayer:createOutOrActiveCardSprite(
                                                        cmd.MY_VIEWID,
                                                        target[1],
                                                        false,
                                                        true
                                                    ):addTo(self):setScale(0.8):setLocalZOrder(2):setTag(
                                                        GameViewLayer.TAG_GUI_1
                                                    ):setPosition(display.width / 2, display.height / 2)
                                                    gui:runAction(
                                                        cc.Sequence:create(
                                                            cc.ScaleTo:create(0.3, 1.5, 1.5),
                                                            cc.DelayTime:create(0.8),
                                                            cc.Spawn:create(
                                                                cc.MoveTo:create(0.5, cc.p(83, 670)),
                                                                cc.ScaleTo:create(0.5, 0.8)
                                                            ),
                                                            cc.CallFunc:create(
                                                                function()
                                                                    --底框
                                                                    local spName =
                                                                        'game/csmj_icon3_' ..
                                                                        GlobalUserItem.GameBg .. '.png'
                                                                    local di =
                                                                        display.newSprite(spName):addTo(self):setPosition(
                                                                        70,
                                                                        670
                                                                    ):setLocalZOrder(1):setTag(GameViewLayer.TAG_GUI_DI)
                                                                    actionComplete()
                                                                end
                                                            )
                                                        )
                                                    )

                                                -- elseif count == 2 then
                                                --     dump('count = 2')
                                                --     for i = 1, 2 do
                                                --         local gui =
                                                --             self._cardLayer:createOutOrActiveCardSprite(
                                                --             cmd.MY_VIEWID,
                                                --             target[i],
                                                --             false
                                                --         ):addTo(self):setScale(0.5):setLocalZOrder(1 + i):setTag(
                                                --             i == 1 and GameViewLayer.TAG_GUI_1 or
                                                --                 GameViewLayer.TAG_GUI_2
                                                --         )

                                                --         local pos = cc.p(display.width / 2, display.height / 2)
                                                --         gui:setPosition(pos)

                                                --         if i == 1 then
                                                --             pos.x = pos.x - 60
                                                --         else
                                                --             pos.x = pos.x + 60
                                                --         end

                                                --         gui:runAction(
                                                --             cc.Sequence:create(
                                                --                 cc.Spawn:create(
                                                --                     cc.MoveTo:create(0.5, pos),
                                                --                     cc.FadeIn:create(0.5),
                                                --                     cc.ScaleTo:create(0.5, 1.5)
                                                --                 ),
                                                --                 cc.CallFunc:create(
                                                --                     function()
                                                --                         --底框
                                                --                         local di =
                                                --                             display.newSprite('game/kuang-10.png'):addTo(
                                                --                             self
                                                --                         ):setPosition(70, 670):setLocalZOrder(1):setTag(
                                                --                             GameViewLayer.TAG_GUI_DI
                                                --                         )
                                                --                     end
                                                --                 ),
                                                --                 cc.DelayTime:create(0.5),
                                                --                 cc.Spawn:create(
                                                --                     cc.MoveTo:create(0.5, cc.p(65 + (i - 1) * 40, 670)),
                                                --                     cc.ScaleTo:create(0.5, 0.8)
                                                --                 ),
                                                --                 cc.CallFunc:create(
                                                --                     function()
                                                --                         actionComplete()
                                                --                     end
                                                --                 )
                                                --             )
                                                --         )
                                                --     end
                                                end
                                            end
                                        )
                                    )
                                )
                            end,
                            0.8
                        )
                    end
                )
            )
        )
    end
end

function GameViewLayer:Changegpbackground()
    local bgName = 'game/csmj_icon3_' .. GlobalUserItem.GameBg .. '.png'
    if self.gp == nil then
        return
    else
        display.newSprite(bgName):addTo(self):setPosition(70, 670)
    end
end

-- --显示出牌
-- function GameViewLayer:showOutCard(viewid, value, isShow)

-- 	if not isShow then
-- 		self.sprOutCardBg:setVisible(false)
-- 		return
-- 	end

-- 	if nil == value then  --无效值
-- 		return
-- 	end

-- 	local posOurCard =
-- 	{
-- 		cc.p(667, 230),
-- 		cc.p(1085, 420),
-- 		cc.p(260, 420),
-- 		cc.p(667, 575)
-- 	}
-- 	print("玩家出牌， 位置，卡牌数值", viewid, value)
-- 	self.sprOutCardBg:setVisible(isShow)
-- 	self.sprOutCardBg:setPosition(posOurCard[viewid])
-- 	--获取数值
-- 	local cardIndex = GameLogic.SwitchToCardIndex(value)
-- 	local sprPath = cmd.RES_PATH.."card/my_normal/tile_me_"
-- 	if cardIndex < 10 then
-- 		sprPath = sprPath..string.format("0%d", cardIndex)..".png"
-- 	else
-- 		sprPath = sprPath..string.format("%d", cardIndex)..".png"
-- 	end
-- 	local spriteValue = display.newSprite(sprPath)
-- 	--获取精灵
-- 	local sprCard = self.sprMajong:getChildByName("card_value")
-- 	if nil ~= sprCard then
-- 		sprCard:setSpriteFrame(spriteValue:getSpriteFrame())
-- 	end
-- end

--用户操作动画
function GameViewLayer:showOperateAction(viewId, actionCode)
    -- body
    local posACtion = {
        cc.p(667, 230),
        cc.p(1085, 420),
        cc.p(260, 420),
        cc.p(667, 575)
    }
    local strPath = ''
    if actionCode == GameLogic.WIK_PENG then
        strPath = strPath .. 'peng'
    end
    if actionCode == GameLogic.WIK_GANG then
        strPath = strPath .. 'gang'
    end
    if actionCode == GameLogic.WIK_CHI_HU then
        strPath = strPath .. 'hu'
    end
    local animation = cc.Animation:create()
    for i = 1, 9 do
        local strPath = cmd.RES_PATH .. 'game/' .. strPath .. string.format('/%d.png', i)
        print('动画资源路径', strPath, viewId, actionCode)
        local spriteFrame = cc.Sprite:create(strPath):getSpriteFrame()
        if spriteFrame then
            animation:addSpriteFrame(spriteFrame)
        else
            break
        end
        animation:setLoops(2)
        animation:setDelayPerUnit(0.04)
    end
    local animate = cc.Animate:create(animation)
    local spr = cc.Sprite:create(cmd.RES_PATH .. 'game/' .. strPath .. string.format('/%d.png', 1))
    spr:addTo(self, GameViewLayer.ZORDER_ACTION)
    spr:setPosition(posACtion[viewId])
    spr:runAction(
        cc.Sequence:create(
            animate,
            cc.CallFunc:create(
                function()
                    spr:removeFromParent()
                end
            )
        )
    )
end

--用户胡牌提示 tagHuInfo
function GameViewLayer:showHuTips(cbHuInfo)
    local infoShow = 0
    local allCard = false
    local isTooMuchCard = false
    if #cbHuInfo == 34 then
        infoShow = 1
        allCard = true
    elseif #cbHuInfo > 7 then
        infoShow = #cbHuInfo
        isTooMuchCard = true
    else
        infoShow = #cbHuInfo
    end
    --判断个数奇
    local pos = cc.p(0, 0)
    if 0 == math.mod(infoShow, 2) then --偶数
        pos = cc.p(-90, 0)
    end
    if allCard then
        local huNode = cc.CSLoader:createNode(cmd.RES_PATH .. 'game/Node_tips.csb')
        huNode:addTo(self.nodeTips)
        huNode:setPosition(pos)
    elseif isTooMuchCard then
        local huNode = cc.CSLoader:createNode(cmd.RES_PATH .. 'game/Node_tips.csb')
        huNode:addTo(self.nodeTips)
        huNode:setPosition(pos)

        local tips_all = huNode:getChildByName('tips_all')
        if nil ~= tips_all then
            tips_all:setVisible(false)
        end

        --显示张数
        local node = huNode:getChildByName('Node_num')
        if nil ~= node then
            node:setVisible(true)
            --张数
            local num = node:getChildByName('label_num')
            if nil ~= num then
                num:setString(string.format('%d', infoShow))
            end
        end
    else
        for i = 1, infoShow do
            local huNode = cc.CSLoader:createNode(cmd.RES_PATH .. 'game/Node_tips.csb')
            huNode:addTo(self.nodeTips)
            print('用户胡牌提示1', pos.x, pos.y)
            local posTag = pos
            if 0 == math.mod(i, 2) then
                posTag = cc.p(pos.x + math.floor(i / 2) * 180, pos.y)
            else
                posTag = cc.p(pos.x - math.floor(i / 2) * 180, pos.y)
            end
            print('用户胡牌提示2', posTag.x, posTag.y)
            huNode:setPosition(posTag)

            --信息
            local huInfo = cbHuInfo[i]
            local tips_fan = huNode:getChildByName('tips_fan')
            if nil ~= tips_fan then
                tips_fan:setVisible(true)
            end
            local tips_huCardNum = huNode:getChildByName('tips_huCardNum')
            if nil ~= tips_huCardNum then
                tips_huCardNum:setVisible(true)
            end
            local tips_all = huNode:getChildByName('tips_all')
            if nil ~= tips_all then
                tips_all:setVisible(false)
            end
            local Node_Majong = huNode:getChildByName('Node_Majong')
            if nil ~= Node_Majong then
                Node_Majong:setVisible(true)
                --获取数值
                local cardIndex = GameLogic.SwitchToCardIndex(huInfo.cbCardValue)
                local sprPath = cmd.RES_PATH .. 'card/my_small/tile_meUp_'
                if cardIndex < 10 then
                    sprPath = sprPath .. string.format('0%d', cardIndex) .. '.png'
                else
                    sprPath = sprPath .. string.format('%d', cardIndex) .. '.png'
                end
                local spriteValue = display.newSprite(sprPath)
                --获取精灵
                local sprCard = Node_Majong:getChildByName('card_value')
                if nil ~= sprCard then
                    sprCard:setSpriteFrame(spriteValue:getSpriteFrame())
                end
            end

            local label_Fan = huNode:getChildByName('label_Fan')
            if nil ~= label_Fan then
                label_Fan:setVisible(true)
                label_Fan:setString(string.format('%d', huInfo.cbFan))
            end
            local label_Num = huNode:getChildByName('label_Num')
            if nil ~= label_Num then
                label_Num:setVisible(true)
                label_Num:setString(string.format('%d', huInfo.cbNum))
            end
        end
    end
end
--总结算
function GameViewLayer:createGameResult(cmd_data)
    local exitRoom = function()
        self._GameFrame:onExitRoom()
    end

    local main = appdf.getNodeByName(self, 'activity_panel')

    self:runAction(
        cc.Sequence:create(
            cc.DelayTime:create(1.5),
            cc.CallFunc:create(
                function()
                    local layer = GameResultLayer:create(cmd_data, exitRoom):addTo(main)
                    self.showGameEndResult = function()
                        layer:show()
                        self.showGameEndResult = nil
                    end
                end
            )
        )
    )
end

--用户摸马动画
function GameViewLayer:showMoMaAction(
    bankChair,
    huChair,
    viewId,
    maNum,
    maData,
    validMaNum,
    validMaData,
    endDelayTime,
    cb)
    local moMaNode = cc.CSLoader:createNode(cmd.RES_PATH .. 'game/Node_moma.csb')
    moMaNode:addTo(self, GameViewLayer.ZORDER_RESULT + 1)
    moMaNode:runAction(
        cc.Sequence:create(
            cc.DelayTime:create(2.0),
            cc.Show:create(),
            cc.CallFunc:create(
                function()
                    --关闭
                    moMaNode:removeFromParent()

                    if cb then
                        cb()
                    end
                end
            )
        )
    )

    --设置姓名
    local userItem = self.m_tabUserHead[viewId].m_userItem
    local userName = appdf.getNodeByName(moMaNode, 'Text_name')
    userName:setString(userItem.szNickName)

    --摸马倍数
    local txt_MaNum = appdf.getNodeByName(moMaNode, 'text_maNum')
    txt_MaNum:setString('')

    --摸马动画
    local cardNode = appdf.getNodeByName(moMaNode, 'Node_majong')

    for i = 1, maNum do
        local card = self._cardLayer:createMyActiveCardSprite(maData[i], false)
        card:addTo(cardNode)
        card:setVisible(true)
        card:setPosition(100 * (i - 1), 0)

        local isValidMa = false
        for j = 1, validMaNum do
            if maData[i] == validMaData[j] then
                isValidMa = true
                break
            end
        end

        if isValidMa == false then
            card:setColor(cc.c3b(127, 127, 127))
        end
    end

    display.performWithDelayGlobal(
        function()
            txt_MaNum:setString(tostring(validMaNum))
        end,
        1.0
    )
end

--判断胡牌玩家是否买中了马
function GameViewLayer:isValidMa(bankChair, huChair, cardData)
    local MaData = {
        {0x01, 0x05, 0x09, 0x11, 0x15, 0x19, 0x21, 0x25, 0x29, 0x31},
        {0x02, 0x06, 0x12, 0x16, 0x22, 0x26, 0x32, 0x35},
        {0x04, 0x08, 0x14, 0x18, 0x24, 0x28, 0x34, 0x37},
        {0x03, 0x07, 0x13, 0x17, 0x23, 0x27, 0x33, 0x36}
    }
    --转换
    local tag = yl.INVALID_CHAIR
    local nChairCount = 4
    --self._scene._gameFrame:GetChairCount()

    local right = bankChair + 1
    right = right >= nChairCount and right - nChairCount or right

    local left = bankChair - 1
    left = left < 0 and nChairCount or left

    local top = bankChair + 2
    top = top >= nChairCount and top - nChairCount or top

    if huChair == bankChair then
        tag = cmd.MY_VIEWID
    elseif huChair == right then
        tag = cmd.RIGHT_VIEWID
    elseif huChair == left then
        tag = cmd.LEFT_VIEWID
    elseif huChair == top then
        tag = cmd.TOP_VIEWID
    end
    for i = 1, #MaData[tag] do
        if cardData == MaData[tag][i] then
            return true
        end
    end
    return false
end

--显示荒庄
function GameViewLayer:showNoWin(isShow)
    self.sprNoWin:setVisible(isShow)
end

--开始
function GameViewLayer:gameStart(startViewId, cbCardData, cbCardCount, cbUserAction, cbMagicData, cbSendCard)
    --每次发四张,第四次一张
    local viewid = startViewId
    local tableView = {1, 2, 4, 3} --对面索引为3
    local cardIndex = 1 --读取自己卡牌的索引
    local actionList = {}
    for i = 1, 4 do
        local cardCount = (i == 4 and 1 or 4)
        for k = 1, cmd.GAME_MAX_PLAYER do
            --[[ 			if k>cmd.GAME_PLAYER then
                break
			end ]]
            if 5 == viewid then
                viewid = 1
            end
            local myCardDate = {}
            if viewid == cmd.MY_VIEWID then
                for j = 1, cardCount do
                    print('开始发牌,我的卡牌', cardIndex, cbCardData[cardIndex])
                    myCardDate[j] = cbCardData[cardIndex]
                    cardIndex = cardIndex + 1
                end
            end

            function callbackWithArgs(viewid, myCardDate, cardCount)
                local ret = function()
                    self._cardLayer:sendCardToPlayer(viewid, myCardDate, cardCount)
                    self:onUpdataLeftCard(self.nCardLeft - cardCount)
                end
                return ret
            end
            -- local callFun = cc.CallFunc:create(callbackWithArgs(tableView[viewid], myCardDate, cardCount))
            -- table.insert(actionList, cc.DelayTime:create(0.2))
            -- table.insert(actionList, callFun)

            callbackWithArgs(tableView[viewid], myCardDate, cardCount)()

            --如果是我要发卡牌信息过去
            viewid = viewid + 1
        end
    end
    --发完手牌给庄家发牌
    local myCardDate = {}
    if startViewId == cmd.MY_VIEWID then
        myCardDate[1] = cbCardData[14]
        --如果我是庄家，允许触摸
        self._cardLayer:setMyCardTouchEnabled(true)
    end
    function callbackWithArgs(viewid, myCardDate, cardCount, cbUserAction, cbMagicData)
        local ret =
            function()
            self:onUpdataLeftCard(self.nCardLeft - cardCount)
            self._cardLayer:sendCardToPlayer(viewid, myCardDate, cardCount)

            self:onUpdataMagicCard(cbMagicData, true)

            if viewid == cmd.MY_VIEWID then
                --判断有没有操作
                if cbUserAction ~= GameLogic.WIK_NULL then
                    if bit:_and(GameLogic.WIK_GANG, cbUserAction) ~= GameLogic.WIK_NULL then
                        local cardGang,
                            gangInfo =
                            self._scene:findUserGangCard(self._cardLayer.cbCardData[cmd.MY_VIEWID], cbSendCard)
                        if #cardGang > 1 then
                            self:ShowGameBtn(cmd_data.cbActionMask, cardGang, gangInfo)
                        else
                            self.cbActionMask = cbUserAction
                            self.cbActionCard = cardGang[1]
                            self:ShowGameBtn(cbUserAction)
                        end
                    else
                        self:ShowGameBtn(cbUserAction)
                    end
                end
            end
        end
        return ret
    end

    -- local callFun = cc.CallFunc:create(callbackWithArgs(startViewId, myCardDate, 1, cbUserAction, cbMagicData))
    -- table.insert(actionList, cc.DelayTime:create(0.2))
    -- table.insert(actionList, callFun)
    -- self:runAction(cc.Sequence:create(actionList))

    callbackWithArgs(startViewId, myCardDate, 1, cbUserAction, cbMagicData)()
end
--用户出牌
function GameViewLayer:gameOutCard(viewId, card, bIsSysOut)
    print('用户出牌', viewId, card)
    if viewId ~= cmd.MY_VIEWID then
        self._cardLayer:outCard(viewId, card)
    elseif self._scene.bTrustee or bIsSysOut then
        self._cardLayer:outCardTrustee(card)
    end

    self.cbOutCardTemp = card
    self.cbOutUserTemp = viewId
    --self._cardLayer:discard(viewId, card)
end
--用户抓牌
function GameViewLayer:gameSendCard(viewId, card)
    --发牌
    if viewId == cmd.MY_VIEWID then
        self._cardLayer:setMyCardTouchEnabled(true)
    end
    self:onUpdataLeftCard(self.nCardLeft - 1)
    self._cardLayer:sendCardToPlayer(viewId, {card}, 1)
end
return GameViewLayer
