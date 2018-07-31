--
-- Author: David
-- Date: 2017-4-11 11:13:57
--
-- 私人房游戏顶层
local PrivateLayerModel = appdf.req(PriRoom.MODULE.PLAZAMODULE .. 'models.PrivateLayerModel')
local PriGameLayer = class('PriGameLayer', PrivateLayerModel)
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. 'ExternalFun')
local ClipText = appdf.req(appdf.EXTERNAL_SRC .. 'ClipText')
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. 'MultiPlatform')

local BTN_DISMISS = 101
local BTN_INVITE = 102
local BTN_SHARE = 103
local BTN_QUIT = 104
local BTN_ZANLI = 105
local BTN_RULE = 106
local BTN_COPY = 107
local CBT_PERSONAL_SCORE = 110
local CBT_PERSONAL_PLUS = 111
local ClientConfig = appdf.req('base.src.app.models.ClientConfig')

function PriGameLayer:ctor(gameLayer)
    PriGameLayer.super.ctor(self, gameLayer)
    -- 加载csb资源
    local rootLayer, csbNode = ExternalFun.loadRootCSB('game/PrivateGameLayer.csb', self)
    self.m_rootLayer = rootLayer

    -- 房间ID
    self.m_atlasRoomID = appdf.getNodeByName(csbNode, 'num_roomID')
    self.m_atlasRoomID:setString('000000')

    -- 局数
    self.m_atlasCount = appdf.getNodeByName(csbNode, 'atlas_round')
    self.m_atlasCount:setString('0 / 0')

    local function btncallback(ref, tType)
        if tType == ccui.TouchEventType.ended then
            self:onButtonClickedEvent(ref:getTag(), ref)
        end
    end
    -- -- 解散按钮
    -- local btn = appdf.getNodeByName(csbNode, 'bt_dismiss')
    -- btn:setTag(BTN_DISMISS)g(BTN_DISMISS)
    -- btn:addTouchEventListener(btncallback)

    -- -- 暂离按钮
    -- btn = appdf.getNodeByName(csbNode, 'bt_zanli')
    -- btn:setTag(BTN_ZANLI)
    -- btn:addTouchEventListener(btncallback)

    -- 邀请按钮
    self.m_btnInvite = appdf.getNodeByName(csbNode, 'bt_invite')

    if ClientConfig.UPDATE_TO_APPSTORE == false then
        self.m_btnInvite:setTag(BTN_INVITE)
        self.m_btnInvite:addTouchEventListener(btncallback)
    else
        self.m_btnInvite:setVisible(false)
    end

    -- 复制房间号
    self.m_btnCopy = appdf.getNodeByName(csbNode, 'bt_copy')
    self.m_btnCopy:setTag(BTN_COPY)
    self.m_btnCopy:addTouchEventListener(btncallback)

    -- 规则界面
    self.m_btnRule = appdf.getNodeByName(csbNode, 'Button_rule')
    self.m_btnRule:setTag(BTN_RULE)
    self.m_btnRule:addTouchEventListener(btncallback)
end

function PriGameLayer:onButtonClickedEvent(tag, sender)
    if BTN_DISMISS == tag then -- 请求解散游戏
        PriRoom:getInstance():queryDismissRoom()
    elseif BTN_INVITE == tag then
        PriRoom:getInstance():getPlazaScene():popTargetShare(
            function(target, bMyFriend)
                bMyFriend = bMyFriend or false
                local function sharecall(isok)
                    if type(isok) == 'string' and isok == 'true' then
                        showToast(self, '分享成功', 2)
                    end
                    GlobalUserItem.bAutoConnect = true
                end
                local roomid = self.m_atlasRoomID:getString()
                local rules, mode, simple = self._gameLayer:formatRoomRules()
                local share = string.format('我在 [叫友棋牌] 开好房间了,广东麻将 房间号:%s  %s,快来一起玩吧!', roomid, simple)

                local url = string.format('%s?roomid=%s', appdf.LINK_URL, roomid)

                if bMyFriend then
                    PriRoom:getInstance():getTagLayer(
                        PriRoom.LAYTAG.LAYER_FRIENDLIST,
                        function(frienddata)
                            local serverid = tonumber(PriRoom:getInstance().m_tabPriData.szServerID) or 0
                            PriRoom:getInstance():priInviteFriend(
                                frienddata,
                                GlobalUserItem.nCurGameKind,
                                serverid,
                                yl.INVALID_TABLE,
                                friendC
                            )
                        end
                    )
                elseif nil ~= target then
                    GlobalUserItem.bAutoConnect = false
                    MultiPlatform:getInstance():shareToTarget(
                        target,
                        sharecall,
                        '叫友棋牌',
                        share,
                        url,
                        '',
                        false,
                        'roomId',
                        roomid
                    )
                end
            end
        )
    elseif BTN_COPY == tag then
        local rules, mode, simple = self._gameLayer:formatRoomRules()
        local share = string.format('我在 [叫友棋牌] 开好房间了,房间号:%s  %s,快来一起玩吧!', self.m_atlasRoomID:getString(), simple)

        local res, msg = MultiPlatform:getInstance():copyToClipboard(share)
        if true == res then
            showToast(self, '复制到剪贴板成功!', 1)
        else
            if type(msg) == 'string' then
                showToast(self, msg, 1, cc.c3b(250, 0, 0))
            end
        end
    elseif BTN_SHARE == tag then
        PriRoom:getInstance():getPlazaScene():popTargetShare(
            function(target, bMyFriend)
                bMyFriend = bMyFriend or false
                local function sharecall(isok)
                    if type(isok) == 'string' and isok == 'true' then
                        showToast(self, '分享成功', 2)
                    end
                    GlobalUserItem.bAutoConnect = true
                end
                local url = appdf.CLIENT_UPDATE_URL
                -- 截图分享
                local framesize = cc.Director:getInstance():getOpenGLView():getFrameSize()
                local area = cc.rect(0, 0, framesize.width, framesize.height)
                local imagename = 'grade_share.jpg'
                if bMyFriend then
                    imagename = 'grade_share_' .. os.time() .. '.jpg'
                end
                ExternalFun.popupTouchFilter(0, false)
                captureScreenWithArea(
                    area,
                    imagename,
                    function(ok, savepath)
                        ExternalFun.dismissTouchFilter()
                        if ok then
                            if bMyFriend then
                                PriRoom:getInstance():getTagLayer(
                                    PriRoom.LAYTAG.LAYER_FRIENDLIST,
                                    function(frienddata)
                                        PriRoom:getInstance():imageShareToFriend(frienddata, savepath, '分享我的约战房战绩')
                                    end
                                )
                            elseif nil ~= target then
                                GlobalUserItem.bAutoConnect = false
                                MultiPlatform:getInstance():shareToTarget(
                                    target,
                                    sharecall,
                                    '我的约战房战绩',
                                    '分享我的约战房战绩',
                                    url,
                                    savepath,
                                    'true'
                                )
                            end
                        end
                    end
                )
            end
        )
    elseif BTN_QUIT == tag then
        GlobalUserItem.bWaitQuit = false
        self.showPrivateGameEnd = nil
        self._gameLayer:onExitRoom()
    elseif BTN_ZANLI == tag then
        PriRoom:getInstance():tempLeaveGame()
        self._gameLayer:onExitRoom()
    elseif BTN_RULE == tag then
        local rules, mode = self._gameLayer:formatRoomRules()
        self._gameLayer._gameView:showRules(true, rules, mode)
    end
end

------
-- 继承/覆盖
------
-- 刷新界面
function PriGameLayer:onRefreshInfo()
    -- 房间ID
    self.m_atlasRoomID:setString(PriRoom:getInstance().m_tabPriData.szServerID or '000000')

    -- 局数
    local strcount =
        PriRoom:getInstance().m_tabPriData.dwPlayCount .. ' / ' .. PriRoom:getInstance().m_tabPriData.dwDrawCountLimit
    self.m_atlasCount:setString(strcount)

    self:onRefreshInviteBtn()
end

--@return: 当前邀请好友按钮是否课件
function PriGameLayer:onRefreshInviteBtn(notSee)
    if ClientConfig.UPDATE_TO_APPSTORE == true then
        self.m_btnInvite:setVisible(false)

        return
    end
    -- print(self._gameLayer.m_cbGameStatus, self._gameLayer.onGetSitUserNum, self._gameLayer:onGetSitUserNum())

    if notSee == false or self._gameLayer.m_cbGameStatus ~= 0 then --空闲场景
        self.m_btnInvite:setVisible(false)
        self.m_btnCopy:setVisible(false)

        if self._gameLayer._gameView.refreshStartButton then
            self._gameLayer._gameView:refreshStartButton(false)
        end
        return false
    end

    -- 邀请按钮
    if nil ~= self._gameLayer.onGetSitUserNum then
        local chairCount = PriRoom:getInstance():getChairCount()
        print('邀请按钮,系统下发，坐下人数', chairCount, self._gameLayer:onGetSitUserNum())
        if self._gameLayer:onGetSitUserNum() == chairCount then
            self.m_btnInvite:setVisible(false)
            self.m_btnCopy:setVisible(false)

            if self._gameLayer._gameView.refreshStartButton then
                self._gameLayer._gameView:refreshStartButton(false)
            end
            return false
        end
    end
    self.m_btnInvite:setVisible(true)
    self.m_btnCopy:setVisible(true)
    if self._gameLayer._gameView.refreshStartButton then
        self._gameLayer._gameView:refreshStartButton(true)
    end
    return true
end

-- 私人房游戏结束
function PriGameLayer:onPriGameEnd(cmd_table)
    
    dump(cmd_table)
    self._gameLayer.isPriOver = true
    self._gameLayer._gameView:removeChildByName('private_end_layer')

    local csbNode = ExternalFun.loadCSB('privateroom/game/PrivateGameEndLayer.csb', self._gameLayer._gameView)
    csbNode:setVisible(false)
    csbNode:setName('private_end_layer')
    csbNode:setGlobalZOrder(1)

    -- 外部调用  显示结算界面
    self.showPrivateGameEnd = function()
        csbNode:setVisible(true)
    end

    local function btncallback(ref, tType)
        if tType == ccui.TouchEventType.ended then
            self:onButtonClickedEvent(ref:getTag(), ref)
        end
    end

    local chairCount = PriRoom:getInstance():getChairCount()
    -- 玩家成绩,大赢家座位号
    local winner = 0
    local maxWin = 0
    local scoreList

    for i = 1, #cmd_table do
        scoreList = cmd_table[i].userItem.lScore
        
        if scoreList > maxWin then
            maxWin = scoreList
            winner = i
        end
    end
    print('winner', winner, 'chairCount', chairCount)
    --游戏记录
    local tabUserRecord = self._gameLayer:getDetailScore()
    local HeadSpriteHelper = appdf.req(appdf.EXTERNAL_SRC .. 'HeadSpriteHelper')
    --玩家结算项之间距离
    local distance, firstX = 148.25, 84.83

    for i = 1, 4 do
        local nodeFace = appdf.getNodeByName(csbNode, 'FileNode_' .. i)
        if i <= chairCount then
            nodeFace:setPositionX(firstX + distance * (2 - chairCount + 2 * i))
            nodeFace:setVisible(true)
            local useritem = self._gameLayer:getUserInfoByChairID(i)

            --头像
            local userAvatar = appdf.getNodeByName(nodeFace, 'Image_1')

            HeadSpriteHelper:initHeadTexture(useritem, userAvatar, 77)

            local cellbg = appdf.getNodeByName(nodeFace, 'Sprite_1')
            if nil ~= cellbg then
                cellbg:setVisible(true)
                local cellsize = cellbg:getContentSize()

                cellbg:removeChildByTag(CBT_PERSONAL_SCORE)
                cellbg:removeChildByTag(CBT_PERSONAL_PLUS)

                if nil ~= useritem then
                    -- 昵称
                    local textNickname = appdf.getNodeByName(cellbg, 'Text_name')
                    local strNickname =
                        string.EllipsisByConfig(useritem.szNickName, 190, string.getConfig('fonts/round_body.ttf', 21))
                    textNickname:setString(strNickname)
                    -- --玩家ID
                    -- local textUserId = cellbg:getChildByName("Text_ID")
                    -- textUserId:setString(useritem.dwGameID)
                    --点炮次数
                    local textPaoNum = appdf.getNodeByName(cellbg, 'Text_Pao')
                    textPaoNum:setString(tabUserRecord[i].cbDianPao)
                    --胡牌次数
                    local textHuNum = appdf.getNodeByName(cellbg, 'Text_Hu')
                    textHuNum:setString(tabUserRecord[i].cbHuCount)
                    --公杠次数
                    local text_MingGang = appdf.getNodeByName(cellbg, 'Text_MingGang')
                    text_MingGang:setString(tabUserRecord[i].cbMingGang)
                    --暗杠次数
                    local textAnGang = appdf.getNodeByName(cellbg, 'Text_Angang')
                    textAnGang:setString(tabUserRecord[i].cbAnGang)
                    -- --中码个数
                    -- local textMaNum = cellbg:getChildByName("Text_Ma")
                    -- textMaNum:setString(tabUserRecord[i].cbMaCount)
                    --大赢家
                    local maxWinner = appdf.getNodeByName(cellbg, 'Sprite_3')
                    if winner == i then
                        cellbg:setTexture('privateroom/game/csmj_jsbg01.png')

                        maxWinner:setVisible(true)
                    else
                        maxWinner:setVisible(false)
                    end
                    --总成绩
                    if not scoreList then
                    else
                        local lScore = tonumber(scoreList)
                        if lScore > 0 then
                            display.newSprite('gameResult/jiesuan-font-04.png'):addTo(cellbg):setTag(CBT_PERSONAL_PLUS):setPosition(
                                cc.p(82, 51)
                            )

                            ccui.TextAtlas:create(
                                tostring(math.abs(lScore)),
                                'gameResult/jiesuan-font-02.png',
                                32,
                                42,
                                '0'
                            ):addTo(cellbg):setTag(CBT_PERSONAL_SCORE):setPosition(cc.p(140, 51))
                        elseif lScore < 0 then
                            display.newSprite('gameResult/jiesuan-font-03.png'):addTo(cellbg):setTag(CBT_PERSONAL_PLUS):setPosition(
                                cc.p(82, 51)
                            )

                            ccui.TextAtlas:create(
                                tostring(math.abs(lScore)),
                                'gameResult/jiesuan-font-01.png',
                                32,
                                42,
                                '0'
                            ):addTo(cellbg):setTag(CBT_PERSONAL_SCORE):setPosition(cc.p(140, 51))
                        elseif lScore == 0 then
                            ccui.TextAtlas:create('0', 'gameResult/jiesuan-font-02.png', 32, 42, '0'):addTo(cellbg):setTag(
                                CBT_PERSONAL_SCORE
                            ):setPosition(cc.p(130, 51))
                        end
                    end
                else
                    cellbg:setVisible(false)
                end
            end
        else
            nodeFace:setVisible(false)
        end
    end

    -- 分享按钮
    local btn = appdf.getNodeByName(csbNode, 'btn_share')
    if ClientConfig.UPDATE_TO_APPSTORE == false then
        btn:setTag(BTN_SHARE)
        btn:addTouchEventListener(btncallback)
    else
        btn:setVisible(false)
    end

    -- 退出按钮
    btn = appdf.getNodeByName(csbNode, 'btn_quit')
    btn:setTag(BTN_QUIT)
    btn:addTouchEventListener(btncallback)

    -- 待开始状态的解散
    if self._gameLayer.m_cbGameStatus == 0 then
        if self.showPrivateGameEnd ~= nil then
            self.showPrivateGameEnd()
        end
    end

    -- csbNode:runAction(cc.Sequence:create(cc.DelayTime:create(3.0),
    --     cc.CallFunc:create(function()
    --         csbNode:setVisible(true)
    --     end)))
end

function PriGameLayer:onExit()
end

return PriGameLayer
