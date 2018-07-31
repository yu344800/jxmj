--
-- Author: David
-- Date: 2017-3-16
--
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. 'ExternalFun')
local ClipText = appdf.req(appdf.EXTERNAL_SRC .. 'ClipText')
local AnimationMgr = appdf.req(appdf.EXTERNAL_SRC .. 'AnimationMgr')
local GameMagicLayer = appdf.req(appdf.CLIENT_SRC .. 'plaza.views.layer.game.GameMagicLayer')

local cmd = appdf.req(appdf.GAME_SRC .. 'yule.jysparrow.src.models.CMD_Game')

local popPosition = {}
popPosition[cmd.LEFT_VIEWID] = cc.p(210, 350)
popPosition[cmd.RIGHT_VIEWID] = cc.p(750, 350)
popPosition[cmd.MY_VIEWID] = cc.p(145, 175)
popPosition[cmd.TOP_VIEWID] = cc.p(600, 350)
local popAnchor = {}
popAnchor[cmd.LEFT_VIEWID] = cc.p(0, 0)
popAnchor[cmd.RIGHT_VIEWID] = cc.p(1, 0)
popAnchor[cmd.MY_VIEWID] = cc.p(0, 0)
popAnchor[cmd.TOP_VIEWID] = cc.p(1, 1)

local posChatView = {cc.p(150, 90), cc.p(-150, 0), cc.p(150, 90), cc.p(-140, -20)}
local posText = {cc.p(150, 90), cc.p(-150, 75), cc.p(150, 90), cc.p(-110, -136)}

local TAG_USER_AVATAR = 'user_avatar'

local PlayerInfo = class('PlayerInfo', cc.Node)

function PlayerInfo:ctor(userItem, viewId, sendMsgCallback, getUserTable)
    -- ExternalFun.registerNodeEvent(self)
    self.m_nViewId = viewId
    self.m_userItem = userItem
    self.m_bNormalState = (self.m_userItem.cbUserStatus ~= yl.US_OFFLINE)
    self.m_clipScore = nil
    self.m_clipNick = nil
    -- 加载csb资源
    self.csbNode = ExternalFun.loadCSB('game/nodeUser.csb', self)

    self.getUserTable = getUserTable
    self.sendMsgCallback = sendMsgCallback
    -- 用户头像
    -- local head = PopupInfoHead:createNormal(userItem, 90)
    -- head:enableInfoPop(true, popPosition[viewId], popAnchor[viewId])
    -- head:enableHeadFrame(true, {_framefile = "land_headframe.png", _zorder = -1, _scaleRate = 0.75, _posPer = cc.p(0.5, 0.63)})
    -- self.m_popHead = head

    local userAvatar = display.newSprite('public/Avatar.png')
    userAvatar:setContentSize(95, 95)
    userAvatar:setName(TAG_USER_AVATAR)

    local HeadSpriteHelper = appdf.req(appdf.EXTERNAL_SRC .. 'HeadSpriteHelper')
    HeadSpriteHelper:initHeadTexture(userItem, userAvatar, 77)

    --获取头像NODE
    local nodeFace = self.csbNode:getChildByName('Node_face')
    nodeFace:addChild(userAvatar)

    -- 头像点击
    local btn = self.csbNode:getChildByName('btn')
    btn:addTouchEventListener(
        function(ref, tType)
            if tType == ccui.TouchEventType.ended then
                local infoLayer = GameMagicLayer:create(self.m_userItem, self.sendMsgCallback, self.getUserTable)
                local runScene = cc.Director:getInstance():getRunningScene()
                runScene:addChild(infoLayer, 1)

                infoLayer:show()
            end
        end
    )

    --游戏币框
    if viewId == cmd.MY_VIEWID then
        self.scoreBg = self.csbNode:getChildByName('Node_mycion')
        self.scoreBg:setVisible(true)
        self.csbNode:getChildByName('Node_othercoin'):setVisible(false)
    else
        self.scoreBg = self.csbNode:getChildByName('Node_othercoin')
        self.scoreBg:setVisible(true)
        self.csbNode:getChildByName('Node_mycion'):setVisible(false)
    end

    -- 昵称
    self.m_clipNick = self.csbNode:getChildByName('Text_nickname')
    if nil == self.m_clipNick then
        self.m_clipNick = ClipText:createClipText(cc.size(110, 20), self.m_userItem.szNickName)
        self.m_clipNick:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_clipNick:setPosition(0, 65)
        self:addChild(self.m_clipNick)
    else
        self.m_clipNick:setString(self.m_userItem.szNickName)
    end

    -- 游戏币
    local labScore = self.scoreBg:getChildByName('text_coins')
    if nil ~= labScore then
        labScore:setString(self.m_userItem.lScore)

        self.m_labScore = labScore
    -- 游戏币
    -- if nil == self.m_clipScore then
    --     self.m_clipScore = ClipText:createClipText(cc.size(100, 20), self:getScoreString(self.m_userItem.lScore) .. "")
    --      --ClipText:createClipText(cc.size(100, 20), self.m_userItem.lScore .. "")
    --     if viewId == cmd.MY_VIEWID then
    --         self.m_clipScore:setAnchorPoint(cc.p(0, 0.5))
    --     else
    --         self.m_clipScore:setAnchorPoint(cc.p(0.5, 0.5))
    --     end
    --     self.m_clipScore:setTextColor(cc.YELLOW)
    --     self.m_clipScore:setPosition(labScore:getPosition())
    --     self.scoreBg:addChild(self.m_clipScore)
    -- else
    --     self.m_clipScore:setString(self:getScoreString(self.m_userItem.lScore))
    -- end
    end

    -- 聊天气泡
    self.m_spChatBg = self.csbNode:getChildByName('voice_animBg')
    self.m_spChatBg:setVisible(false)

    -- 聊天内容
    if nil == self.m_labChat then
        self.m_labChat = cc.LabelTTF:create('', 'fonts/siyuanheiti.ttf', 24, cc.size(160, 0), cc.TEXT_ALIGNMENT_CENTER)
        -- self.m_labChat:setTextColor(cc.c4b(77, 23, 22, 255))
        self.m_labChat:setFontFillColor(cc.c4b(255,255,255,255))
        self.m_spChatBg:addChild(self.m_labChat)
    end

    -- 聊天动画
    local sc = cc.ScaleTo:create(0.1, 1.0, 1.0)
    local show = cc.Show:create()
    local spa = cc.Spawn:create(sc, show)
    self.m_actTip =
        cc.Sequence:create(spa, cc.DelayTime:create(2.0), cc.ScaleTo:create(0.1, 0.00001, 1.0), cc.Hide:create())
    self.m_actTip:retain()

    -- 语音动画
    local param = AnimationMgr.getAnimationParam()
    param.m_fDelay = 0.1
    param.m_strName = cmd.VOICE_ANIMATION_KEY
    local animate = AnimationMgr.getAnimate(param)
    self.m_actVoiceAni = cc.RepeatForever:create(animate)
    self.m_actVoiceAni:retain()

    --语音动画
    if nil == self.m_spVoice then
        self.m_spVoice = display.newSprite('public/blank.png')
        self.m_spVoice:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_spVoice:runAction(self.m_actVoiceAni)
        self.m_spVoice:setRotation(180)
        self.m_spVoice:addTo(self.m_spChatBg)
        self.m_spVoice:setPosition(
            self.m_spChatBg:getContentSize().width * 0.5,
            self.m_spChatBg:getContentSize().height * 0.5 + 7
        )
    end

    self:updateStatus()
end

function PlayerInfo:onExit()
    self.m_actTip:release()
    self.m_actTip = nil
    self.m_actVoiceAni:release()
    self.m_actVoiceAni = nil
end

function PlayerInfo:reSet()
    self.m_popHead:setVisible(true)
end

function PlayerInfo:showBank(isBanker)
    --庄家图标
    self.csbNode:getChildByName('Sprite_banker'):setVisible(isBanker)
end

function PlayerInfo:showRoomHolder(isRoomHolder)
    --房主图标
    self.csbNode:getChildByName('icon_roomHolder'):setVisible(isRoomHolder)
end

function PlayerInfo:switeGameState(isBanker)
    self.m_popHead:setVisible(false)
    -- 昵称
    if nil == self.m_clipNick then
        self.m_clipNick = ClipText:createClipText(cc.size(90, 20), self.m_userItem.szNickName)
        self.m_clipNick:setAnchorPoint(cc.p(0.5, 0.5))
        self.m_clipNick:setPosition(0, 70)
        self:addChild(self.m_clipNick)
    else
        self.m_clipNick:setString(self.m_userItem.szNickName)
    end

    -- 游戏币
    -- self.scoreBg = self.csbNode:getChildByName("Node_mycion")
    -- local labScore = self.scoreBg:getChildByName("text_coins")
    if nil ~= self.m_labScore then
        --labScore:setString(self.m_userItem.lScore)
        self.m_labScore:setString(self:getScoreString(self.m_userItem.lScore))
    end

    --庄家图标
    self.csbNode:getChildByName('Sprite_banker'):setVisible(isBanker)

    self:runAction(
        cc.Sequence:create(
            cc.DelayTime:create(1),
            cc.CallFunc:create(
                function()
                    self:updateStatus()
                end
            )
        )
    )
end

function PlayerInfo:textChat(str)
    print('玩家头像上聊天信息', self.m_spChatBg, str)
    self.m_spChatBg:setVisible(true)
    self.m_spVoice:setVisible(false)

    self.m_labChat:setString(str)

    self:changeChatPos('text')
    self.m_labChat:setVisible(true)
    -- 尺寸调整
    local labSize = self.m_labChat:getContentSize()
    if labSize.height >= 40 then
        self.m_spChatBg:setContentSize(170, labSize.height + 54)
    else
        self.m_spChatBg:setContentSize(170, 74)
    end
    self.m_labChat:setPosition(
        self.m_spChatBg:getContentSize().width * 0.5,
        self.m_spChatBg:getContentSize().height * 0.5 + 7
    )

    if cmd.TOP_VIEWID == self.m_nViewId then --在顶部旋转了，子串不旋转
        self.m_labChat:setScale(-1)
    elseif cmd.RIGHT_VIEWID == self.m_nViewId then
        self.m_labChat:setScaleX(-1)
    else
        self.m_labChat:setScale(1)
    end
    self.m_spChatBg:stopAllActions()
    self.m_spChatBg:runAction(cc.Sequence:create(cc.DelayTime:create(3.0), cc.Hide:create()))
end

function PlayerInfo:browChat(idx)
    if nil ~= self.m_labChat then
        self.m_labChat:setVisible(false)
    end
    self:changeChatPos('brow')
    self.m_spChatBg:setVisible(true)

    self.m_spChatBg:setContentSize(0, 0)

    local textureName

    local str = string.format('public/srjy_chatface_%d.png', idx)

    local sp = appdf.getNodeByName(self.m_spChatBg, '_browChatSp')

    if sp ~= nil then
        sp:stopAllActions()
        sp:removeSelf()
    end

    sp = display.newSprite(str):setName('_browChatSp'):addTo(self.m_spChatBg):setPosition(10, 0)

    if sp ~= nil then
        sp:runAction(
            cc.Sequence:create(
                cc.DelayTime:create(2),
                cc.RemoveSelf:create(),
                cc.CallFunc:create(
                    function()
                        sp:setVisible(false)
                    end
                )
            )
        )
    end
end

function PlayerInfo:onUserVoiceStart()
    if nil ~= self.m_labChat then
        self.m_labChat:setVisible(false)
    end
    self:changeChatPos('voice')
    self.m_spChatBg:setContentSize(170, 74)
    self.m_spChatBg:stopAllActions()
    self.m_spChatBg:setVisible(true)
    if nil ~= self.m_spVoice then
        -- 语音动画
        local sp =
            display.newSprite('public/liaotian-yinliang-01.png'):setName('_voiceSp'):setScale(0.9):setAnchorPoint(
            1,
            0.5
        ):setFlippedX(true):addTo(self.m_spVoice)

        if cmd.RIGHT_VIEWID == self.m_nViewId or cmd.TOP_VIEWID == self.m_nViewId then
            sp:setPosition(60, 30)
        elseif cmd.LEFT_VIEWID == self.m_nViewId or cmd.MY_VIEWID == self.m_nViewId then
            sp:setPosition(60, 27)
        end

        local frames = {}

        for i = 1, 3 do
            local textureName = string.format('public/liaotian-yinliang-0%d.png', i)
            local sp = display.newSprite(textureName)
            local frame = sp:getSpriteFrame()
            frames[#frames + 1] = frame
        end

        local animation = display.newAnimation(frames, 0.2)

        local animate = cc.Animate:create(animation)
        local action = cc.RepeatForever:create(animate)

        sp:runAction(action)

        self.m_spVoice:setVisible(true)
    end
end

function PlayerInfo:onUserVoiceEnded()
    self.m_spChatBg:setVisible(false)
    if nil ~= self.m_spVoice then
        local sp = appdf.getNodeByName(self.m_spVoice, '_voiceSp')
        if sp ~= nil then
            sp:stopAllActions()
            sp:removeSelf()
        end
        self.m_spVoice:setVisible(false)
    end
end

function PlayerInfo:changeChatPos(tag)
    -- print("聊天气泡位置", posChatView[self.m_nViewId].x, posChatView[self.m_nViewId].y)
    self.m_spChatBg:setPosition(posChatView[self.m_nViewId])
    if cmd.RIGHT_VIEWID == self.m_nViewId then
        self.m_spChatBg:setScaleX(-1)
    elseif cmd.TOP_VIEWID == self.m_nViewId and tag ~= 'brow' then
        -- 聊天表情无需翻转
        self.m_spChatBg:setScale(-1)
    else
        self.m_spChatBg:setScale(1)
    end
end

function PlayerInfo:updateScore()
    if nil ~= self.m_labScore then
        self.m_labScore:setString(self:getScoreString(self.m_userItem.lScore))
        --判断积分房
        if PriRoom and GlobalUserItem.bPrivateRoom then
            if PriRoom:getInstance().m_tabPriData.cbIsGoldOrGameScore then
                if PriRoom:getInstance().m_tabPriData.cbIsGoldOrGameScore == 1 then
                    self.m_labScore:setString(self.m_userItem.lScore)
                end
            else
                self.m_labScore:setString('0')
            end
        end
    end
end

function PlayerInfo:updateStatus()
    print('更新用户分数')
    if self.m_userItem.cbUserStatus == yl.US_OFFLINE then
        self.m_bNormalState = false
        if nil ~= convertToGraySprite then
            -- 灰度图
            if nil ~= self.m_popHead and nil ~= self.m_popHead.m_head and nil ~= self.m_popHead.m_head.m_spRender then
                convertToGraySprite(self.m_popHead.m_head.m_spRender)
            end
        end
    else
        if not self.m_bNormalState then
            self.m_bNormalState = true
            -- 普通图
            if nil ~= convertToNormalSprite then
                -- 灰度图
                if nil ~= self.m_popHead and nil ~= self.m_popHead.m_head and nil ~= self.m_popHead.m_head.m_spRender then
                    convertToNormalSprite(self.m_popHead.m_head.m_spRender)
                end
            end
        end
    end
    self:updateScore()
end
function PlayerInfo:getScoreString(score)
    local strScore = ''
    if score < 100000 then
        strScore = strScore .. score
    elseif score < 100000000 then
        print('分数转换1', score / 10000)
        strScore = strScore .. string.format('%.2f', score / 10000) .. '万'
    else
        print('分数转换2', score / 100000000)
        strScore = strScore .. string.format('%.2f', score / 100000000) .. '亿'
    end
    print('分数转换', score, strScore)
    return strScore
end

return PlayerInfo
