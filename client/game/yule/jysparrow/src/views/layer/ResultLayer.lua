local cmd = appdf.req(appdf.GAME_SRC .. 'yule.jysparrow.src.models.CMD_Game')
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. 'ExternalFun')
local CardLayer = appdf.req(appdf.GAME_SRC .. 'yule.jysparrow.src.views.layer.CardLayer')
local GameLogic = appdf.req(appdf.GAME_SRC .. 'yule.jysparrow.src.models.GameLogic')
local HeadSpriteHelper = appdf.req(appdf.EXTERNAL_SRC .. 'HeadSpriteHelper')
local GameLogic = appdf.req(appdf.GAME_SRC .. 'yule.jysparrow.src.models.GameLogic')

local ResultLayer =
    class(
    'ResultLayer',
    function(scene)
        local RstLayer = cc.LayerColor:create(cc.c4b(0, 0, 0, 150))
        return RstLayer
    end
)

ResultLayer.WINNER_ORDER = 1
local UserItem_Begin = 10
local CBT_CONTINUE = 20
local CBT_TOTAL_SCORE = 21
local CBT_TOTAL_PLUS = 22
local CBT_PERSONAL_SCORE = 23
local CBT_PERSONAL_PLUS = 24

function ResultLayer:onInitData()
end

function ResultLayer:onResetData()
    -- self:removeChildByTag(CBT_TOTAL_SCORE)
    -- self:removeChildByTag(CBT_TOTAL_PLUS)
    -- for i=1, 4 do
    -- 	local node = appdf.getNodeByName(self, 'FileNode_' .. i)
    -- 	node:removeChildByTag(CBT_PERSONAL_SCORE)
    -- 	node:removeChildByTag(CBT_PERSONAL_PLUS)
    -- 	self.btn_users[i]:setEnabled(true)
    -- end
end

function ResultLayer:ctor(scene)
    self._viewLayer = scene
    self:onInitData()
    -- ExternalFun.registerTouchEvent(self, true)

    local csbNode = ExternalFun.loadCSB('gameResult/GameResultLayer.csb', self)

    local width = 44 * 0.9
    local height = 67

    local make_initUserNode =
        function(idx, root)
        local head = appdf.getNodeByName(root, 'Image_1')
        local bg = appdf.getNodeByName(root, 'Image_2')
        local text_nick = appdf.getNodeByName(root, 'Text_1')
        local spr_banker = appdf.getNodeByName(root, 'zhuang')
        local node_mj = appdf.getNodeByName(root, 'Node_Majiang')
        local text_des = appdf.getNodeByName(root, 'Text_2')
        local score_tag = appdf.getNodeByName(root, 'Image_41')
        local score_txt = appdf.getNodeByName(root, 'AtlasLabel_1')
        local tag_end = appdf.getNodeByName(root, 'Image_3')

        return function(
            userData,
            useritem,
            owner,
            banker,
            myChirID,
            score,
            tag,
            cbProvideCard,
            cbGangInfo,
            cbZhongMaCount)
            if not useritem then
                root:setVisible(false)
            else
                root:setVisible(true)
                node_mj:removeAllChildren()
                node_mj:setVisible(true)
                --头像
                local userAvatar = appdf.getNodeByName(root, 'Image_1')

                HeadSpriteHelper:initHeadTexture(useritem, userAvatar, 75)
                --
                -- print(useritem.wChairID, owner, banker, myChirID)
                --昵称
                text_nick:setString(useritem.szNickName)
                if myChirID == useritem.wChairID then
                    text_nick:setTextColor(cc.c3b(10, 116, 100, 255))
                    bg:loadTexture('gameResult/jiesuan-kuang-05.png', ccui.TextureResType.localType)
                else
                    text_nick:setTextColor(cc.c3b(105, 63, 38, 255))
                    bg:loadTexture('gameResult/jiesuan-kuang-04.png', ccui.TextureResType.localType)
                end

                --庄家标识
                spr_banker:setVisible(useritem.wChairID == banker)
                --描述
                local stringTable, num, fan = GameLogic.getChiHuRightInfo(userData.dwChiHuRight)
                --杠牌
                local minGang = 0
                local anGang = 0
                local dianGang = 0

                local gangs = cbGangInfo
                for i = 1, #gangs do
                    if gangs[i].wCurrentUser == useritem.wChairID then
                        if
                            gangs[i].cbGangType == GameLogic.WIK_MING_GANG or
                                gangs[i].cbGangType == GameLogic.WIK_FANG_GANG
                         then
                            minGang = minGang + 1
                        elseif gangs[i].cbGangType == GameLogic.WIK_AN_GANG then
                            anGang = anGang + 1
                        end
                    elseif gangs[i].wProvideGangUser == useritem.wChairID then
                        dianGang = dianGang + 1
                    end
                end

                if minGang > 0 then
                    table.insert(stringTable, string.format('明杠×%d次', minGang))
                end

                if dianGang > 0 then
                    table.insert(stringTable, string.format('点杠×%d次', dianGang))
                end

                if anGang > 0 then
                    table.insert(stringTable, string.format('暗杠×%d次', anGang))
                end

                if userData.lHuScore > 0 and cbZhongMaCount > 0 then
                    table.insert(stringTable, string.format('中马×%d次', cbZhongMaCount))
                end

                text_des:setString(table.concat(stringTable, '  '))

                --手牌
                local count = 0
                local pos = cc.p(-width * 1.5, -5)
                local activeCards = userData.cbActiveCardData
                dump(activeCards, '碰杠牌')
                for i = 1, #activeCards do
                    local active = activeCards[i]
                    if active then
                        for j = 1, active.cbCardNum do
                            local cardValue =
                                (active.cbCardValue[j] == 0 and active.cbCardValue[1] or active.cbCardValue[j])
                            local sprCard =
                                self._viewLayer._cardLayer:createOutOrActiveCardSprite(cmd.MY_VIEWID, cardValue, false)
                            if nil ~= sprCard then
                                sprCard:setScale(0.9)
                                node_mj:addChild(sprCard)

                                -- 暗杠显示背面
                                if j ~= active.cbCardNum and active.cbType == GameLogic.SHOW_AN_GANG then
                                    self._viewLayer._cardLayer:showActiveCardBack(cmd.MY_VIEWID, sprCard)
                                end

                                --设置坐标
                                if
                                    j == 4 and
                                        (active.cbType >= GameLogic.SHOW_MING_GANG or
                                            active.cbType <= GameLogic.SHOW_AN_GANG)
                                 then
                                    sprCard:setPosition(cc.p(pos.x - width + 6, pos.y + 10))
                                else
                                    sprCard:setPosition(cc.p(pos.x + width, pos.y))
                                    pos.x = pos.x + width

                                    count = count + 1
                                end
                            end
                        end
                        pos.x = pos.x + width / 2
                    end
                end

                local handCards = userData.cbCardData
                dump(handCards, '手牌')
                for j = 1, #handCards do
                    local sprCard =
                        self._viewLayer._cardLayer:createOutOrActiveCardSprite(cmd.MY_VIEWID, handCards[j], false)
                    if nil ~= sprCard then
                        node_mj:addChild(sprCard)
                        sprCard:setScale(0.9)
                        sprCard:setPosition(cc.p(pos.x + width, pos.y))

                        pos.x = pos.x + width
                        count = count + 1

                        if count == 14 then
                            sprCard:setPositionX(sprCard:getPositionX() + 10)
                        end
                    end
                end

                --积分变更事件 点炮 点杠 等
                --积分
                local lScore = tonumber(score)
                if lScore > 0 then
                    score_tag:setVisible(true)
                    score_tag:setTexture('gameResult/jiesuan-font-04.png')
                    score_txt:setProperty(tostring(math.abs(lScore)), 'gameResult/jiesuan-font-02.png', 32, 42, '0')
                elseif lScore < 0 then
                    score_tag:setVisible(true)
                    score_tag:setTexture('gameResult/jiesuan-font-03.png')
                    score_txt:setProperty(tostring(math.abs(lScore)), 'gameResult/jiesuan-font-01.png', 32, 42, '0')
                elseif lScore == 0 then
                    score_tag:setVisible(false)
                    score_txt:setProperty('0', 'gameResult/jiesuan-font-02.png', 32, 42, '0')
                end

                --点炮 胡牌标识
                if tag ~= '' then
                    tag_end:setVisible(true) --加载图片不变形
                    tag_end:loadTexture(string.format('gameResult/%s', tag), ccui.TextureResType.localType):ignoreContentAdaptWithSize(
                        true
                    )
                else
                    tag_end:setVisible(false)
                end
            end
        end
    end

    --玩家信息
    self.initUserNode = {}
    for i = 1, 4 do
        local node = appdf.getNodeByName(self, 'FileNode_' .. i)

        self.initUserNode[i] = make_initUserNode(i, node)
    end

    --本局 马  鬼 信息
    self.guiPai = appdf.getNodeByName(self, 'Text_gui')
    self.maPai = appdf.getNodeByName(self, 'Sprite_mapai')
    self.maText = appdf.getNodeByName(self, 'Sprite_text')

    --按键监听
    local btcallback = function(ref, type)
        if type == ccui.TouchEventType.ended then
            self:onButtonClickedEvent(ref:getTag(), ref)
        end
    end

    -- 继续游戏
    local btnExit = appdf.getNodeByName(self, 'Button_1')
    btnExit:setTag(CBT_CONTINUE)
    btnExit:addTouchEventListener(btcallback)

    local layerTouch = function(eventType, x, y)
        return true
    end

    self:setTouchEnabled(false)
    self:setSwallowsTouches(true)
    self:registerScriptTouchHandler(layerTouch)
end

function ResultLayer:onTouchBegan(touch, event)
    local pos = touch:getLocation()
    --print(pos.x, pos.y)
    local rect = cc.rect(122, 25, 976, 680)
    if not cc.rectContainsPoint(rect, pos) then
        self:hideLayer()
    end
    return self.bShield
end

function ResultLayer:onButtonClickedEvent(tag, type)
    if tag == CBT_CONTINUE then
        print('继续游戏')
        self:hideLayer()

        --bShieldself._viewFrame.onPriGameEnd
        --显示总结算
        if PriRoom:getInstance()._priView.showPrivateGameEnd then
            PriRoom:getInstance()._priView.showPrivateGameEnd()
            print('==========总结算=============')
        else
            print('=====================退出房间================')
            self._viewLayer:onButtonClickedEvent(self._viewLayer.BT_START)
        end
    end
end

function ResultLayer:showLayer(resultList, wBankerChairId, myChirID, cmd_data, playerNum)
    assert(type(resultList) == 'table')

    self:move(0, 0)
    self:setVisible(true)
    self:setTouchEnabled(true)

    self.resultList = resultList

    local Tag = {
        'jiesuan-icon-04.png', --胡
        'jiesuan-icon-05.png', --点炮
        'jiesuan-icon-06.png', --自摸
        'jiesuan-icon-06.png', --抢杠胡
        'jiesuan-icon-06.png' --杠上开花
    }

    for i = 1, cmd.GAME_MAX_PLAYER do
        if i <= cmd.GAME_PLAYER then
            local userItem = resultList[i].userItem

            local tag = ''
            if resultList[i].lHuScore > 0 then
                -- end
                -- -- 是否抢杠胡
                -- if bit:_and(GameLogic.CHR_QIANG_GANG_HU, cmd_data.dwChiHuRight) ~= GameLogic.WIK_NULL then
                -- 	tag = Tag[4]
                -- elseif bit:_and(GameLogic.CHR_GANG_SHANG_HUA, cmd_data.dwChiHuRight) ~= GameLogic.WIK_NULL then
                -- 	tag = Tag[5]
                -- else
                if cmd_data.wProvideUser + 1 == i then
                    tag = Tag[3]
                else
                    tag = Tag[1]
                end
            elseif cmd_data.wProvideUser + 1 == i then
                tag = Tag[2]
            end

            -- 单局输赢分数
            local single = resultList[i].lScore
            self.initUserNode[i](
                resultList[i],
                userItem,
                0,
                wBankerChairId,
                myChirID,
                single,
                tag,
                cmd_data.cbProvideCard,
                cmd_data.cbGangInfo[1],
                cmd_data.cbZhongMaCount[1][i]
            )
        else
            local node = appdf.getNodeByName(self, 'FileNode_' .. i)
            node:setVisible(false)
        end
    end

    --输赢平标识
    local winTag = appdf.getNodeByName(self, 'Image_total')
    local meResult = resultList[myChirID + 1]
    if meResult then
        local tags = {
            'jiesuan-icon-01.png', --赢
            'jiesuan-icon-02.png', --失败
            'jiesuan-icon-03.png' --平
        }

        local meTag = 3
        if meResult.lScore > 0 then
            meTag = 1
            print('赢了')
        elseif meResult.lScore < 0 then
            meTag = 2
            print('输了')
        elseif meResult.lScore == 0 then
            meTag = 3
            print('平局')
        end

        winTag:loadTexture(string.format('gameResult/%s', tags[meTag]), ccui.TextureResType.localType)
    end

    local width = 44 * 0.9
    local height = 30

    dump(cmd_data.cbMaData, '马牌')
    --马牌
    if cmd_data.cbMaCount > 0 then
        self.maText:setVisible(true)
        self.maPai:setVisible(true)
        self.maPai:removeAllChildren()

        local validMaData = {}
        for i = 1, cmd.GAME_PLAYER do
            for j = 1, cmd.MAX_MA_COUNT do
                if cmd_data.cbZhongMaData[i][j] ~= 0 then
                    validMaData[#validMaData + 1] = cmd_data.cbZhongMaData[i][j]
                end
            end
        end

        local pos = cc.p(95, 0)
        for i = 1, cmd_data.cbMaCount do
            local sprCard =
                self._viewLayer._cardLayer:createOutOrActiveCardSprite(cmd.MY_VIEWID, cmd_data.cbMaData[1][i], false)
            if nil ~= sprCard then
                self.maPai:addChild(sprCard)
                sprCard:setScale(0.9)
                sprCard:setPosition(cc.p(pos.x, height))

                --是否中马
                local isValidMa = false
                for j = 1, #validMaData do
                    if cmd_data.cbMaData[1][i] == validMaData[j] then
                        isValidMa = true
                        break
                    end
                end

                if isValidMa == false then
                    sprCard:setColor(cc.c3b(127, 127, 127))
                end

                pos.x = pos.x + width
            end
        end
    else
        self.maText:setVisible(false)
        self.maPai:setVisible(false)
    end

    --鬼牌
    dump(cmd_data.cbMagicCard, '鬼牌')
    local cbGuiCount = 0
    for i = 1, 2 do
        if cmd_data.cbMagicCard[1][i] ~= 0 then
            cbGuiCount = cbGuiCount + 1
        end
    end

    if cbGuiCount > 0 and cmd_data.cbMagicCard[1][1] < 34 then
        self.guiPai:setVisible(true)
        self.guiPai:removeAllChildren()
        local pos = cc.p(95, 0)
        for i = 1, 2 do
			local sprCard = nil
			if cmd_data.cbMagicCard[1][i] ~= 0 then
                local magic_gui = GameLogic.SwitchToCardData(cmd_data.cbMagicCard[1][1] + 1)
                sprCard = self._viewLayer._cardLayer:createOutOrActiveCardSprite(cmd.MY_VIEWID, magic_gui, false)
            end
            if nil ~= sprCard then
                self.guiPai:addChild(sprCard)
                sprCard:setPosition(cc.p(pos.x, height))
                pos.x = pos.x + width + 10
				break
			end

        end
    else
        self.guiPai:setVisible(false)
    end
end

function ResultLayer:hideLayer()
    self:setVisible(false)
    self:move(0, display.height)

    self:runAction(
        cc.Sequence:create(
            cc.DelayTime:create(0.2),
            cc.CallFunc:create(
                function()
                    self:setTouchEnabled(false)
                    self:onResetData()
                end
            )
        )
    )
    return self
end

return ResultLayer
