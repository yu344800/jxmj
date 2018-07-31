--
-- Author: zhong
-- Date: 2016-12-17 10:32:26
--
-- 房间记录界面

local RoomRecordLayer = class("RoomRecordLayer", cc.Layer)
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local ClipText = appdf.req(appdf.EXTERNAL_SRC .. "ClipText")
local RoomDetailLayer = appdf.req(PriRoom.MODULE.PLAZAMODULE .. "views.RoomDetailLayer")
local cmd_private = appdf.req(PriRoom.MODULE.PRIHEADER .. "CMD_Private")

local ROOMDETAIL_NAME = "__pri_room_detail_layer_name__"

local CBT_CLOSE     = 10 
local CBT_RETURN    = 11

local CBT_REPLAY    = 12
local CBT_LOOKUP    = 13

local CBT_GAME_CHAOSHAN     = 101
local CBT_GAME_TUIDAOHU     = 102


function RoomRecordLayer:ctor( scene )
    ExternalFun.registerNodeEvent(self)

    self.scene = scene
    -- 加载csb资源
    local rootLayer, csbNode = ExternalFun.loadRootCSB("room/RecordLayer.csb", self)

    local touchFunC = function(ref, tType)
        if tType == ccui.TouchEventType.ended then
            self:onButtonClickedEvent(ref:getTag(), ref)            
        end
    end
    
    -- 游戏列表
    self._viewGameList = appdf.getNodeByName(csbNode, 'ListView_1')

    self.gameList = {}

    for i=1, 2 do
        local game = self._viewGameList:getChildByName('game_' .. i)
        game:setTag(CBT_GAME_CHAOSHAN + i - 1)
        game:addTouchEventListener(touchFunC)
        self.gameList[CBT_GAME_CHAOSHAN + i - 1] = game
    end

    self.gameList[CBT_GAME_CHAOSHAN]:setEnabled(false)

    -- 房间列表
    self._viewRoomList = appdf.getNodeByName(csbNode, 'ListView_2')
    self._viewRoomList:setVisible(false)

    -- 回合列表
    self._viewRoundList = appdf.getNodeByName(csbNode, 'round_bg')
    self._viewRoundList:setVisible(false)

    --无战绩提示
    self._viewPrompt = appdf.getNodeByName(csbNode, 'Sprite_8')
    -- self._viewPrompt:setVisible(false)

    self._btnClose = appdf.getNodeByName(csbNode, 'btn_close')
    self._btnClose:setTag(CBT_CLOSE)
    self._btnClose:addTouchEventListener(touchFunC)

    self._btnReturn = appdf.getNodeByName(csbNode, 'btn_return')
    self._btnReturn:setTag(CBT_RETURN)
    self._btnReturn:addTouchEventListener(touchFunC)

    self.initRoomItem = self:make_initRoomItem()
    self.initRoundList = self:make_initRoundList()
end

function RoomRecordLayer:onButtonClickedEvent( tag, sender )
    if tag == CBT_CLOSE then
        self.scene:onKeyBack()
    elseif tag == CBT_RETURN then
        self._viewRoomList:setVisible(true)
        self._viewRoundList:setVisible(false)

        self:onReloadRecordList()
    elseif tag == CBT_GAME_CHAOSHAN then
        self.gameList[CBT_GAME_CHAOSHAN]:setEnabled(false)
        self.gameList[CBT_GAME_TUIDAOHU]:setEnabled(true)

    elseif tag == CBT_GAME_TUIDAOHU then
        self.gameList[CBT_GAME_TUIDAOHU]:setEnabled(false)
        self.gameList[CBT_GAME_CHAOSHAN]:setEnabled(true)

    end
    
end

function RoomRecordLayer:onEnterTransitionFinish()
    print('请求战绩...')
    PriRoom:getInstance():showPopWait()
    -- 请求记录列表
    PriRoom:getInstance():getNetFrame():onQueryJoinList()
end

function RoomRecordLayer:onExit()
    -- 清除缓存
    PriRoom:getInstance().m_tabJoinRecord = {}
    PriRoom:getInstance().m_tabCreateRecord = {}
end

function RoomRecordLayer:onReloadRecordList()
    -- print('onReloadRecordList')
    local recordlist = PriRoom:getInstance().m_tabJoinRecord
    if #recordlist == 0 then
        self._viewPrompt:setVisible(true)
    else
        self._viewPrompt:setVisible(false)

        self._viewRoomList:removeAllChildren()
        self._viewRoomList:setVisible(true)

        for i=1, #recordlist do 
            local room = self.initRoomItem(i, recordlist[i])

            self._viewRoomList:pushBackCustomItem(room)
        end
    end
    
    self._btnClose:setVisible(true)
    self._btnReturn:setVisible(false)
end

function RoomRecordLayer:make_initRoomItem()

    local template = self._viewRoomList:getChildByName('game_1')
    template:retain()

    --@index: 房间序号 
    --@data： 房间信息
    return function(index, data)
        -- dump(data)

        -- for i = 1, 8 do
        --     dump(data['PersonalUserScoreInfo'][1][i])
        -- end

        local room = template:clone()
        -- 索引
        local idx = appdf.getNodeByName(room, 'Text_1')
        idx:setString(tostring(index))

        -- 房间号
        local id = appdf.getNodeByName(room, 'Text_2')
        id:setString(data.szRoomID)

        -- 时间
        local time = appdf.getNodeByName(room, 'Text_3')
        time:setString(string.format("%d:%d", data.sysDissumeTime.wMinute - data.sysCreateTime.wMinute, data.sysDissumeTime.wSecond - data.sysCreateTime.wSecond))

        -- 个人信息
        for i = 1, 4 do
            local personal = data.PersonalUserScoreInfo[1][i]

            local name = appdf.getNodeByName(room, 'Text_name'..i)
            local score = name:getChildByName('Text_score')

            name:setString(personal.szUserNicname)
            score:setString(personal.lScore)

            if personal.lScore > 0 then
                score:setTextColor(cc.c4b(224,39,2,255))
            else
                score:setTextColor(cc.c4b(38,170,19,255))
            end
        end
        
        room:addTouchEventListener(function(ref, tType)
            if tType == ccui.TouchEventType.ended then
                -- 屏蔽 查看局信息列表
                -- self:initRoundList(data)
            end
        end)
        return room
    end
end

function RoomRecordLayer:make_initRoundList()
    self._viewRounds = self._viewRoundList:getChildByName('ListView_rounds')

    local template = self._viewRounds:getChildByName('Image_1')
    template:retain()

    return function(room)
        -- dump(room)
        self._viewRoomList:setVisible(false)
        self._viewRoundList:setVisible(true)

        self._btnClose:setVisible(false)
        self._btnReturn:setVisible(true)

        for i=1, 4 do
            local name = self._viewRoundList:getChildByName('Text_name'..i)
            -- print(name)
        end

        self._viewRounds:removeAllChildren()

        local round = template:clone()

        -- 设置round信息
        -- id
        local id = round:getChildByName("Text_1")
        local time = round:getChildByName("Text_2")

        for i=1, 4 do
            local score = round:getChildByName('Text_score%d'..i)
        end

        local replay = round:getChildByName('Button_replay')
        local lookup = round:getChildByName('Button_lookup')

        self._viewRounds:pushBackCustomItem(round)
    end
end

function RoomRecordLayer.cellSizeForTable( view, idx )
    return 1130,50
end

function RoomRecordLayer:numberOfCellsInTableView( view )
    if self.m_checkSwitch:isSelected() then
        return #(PriRoom:getInstance().m_tabCreateRecord)
    else
        return #(PriRoom:getInstance().m_tabJoinRecord)
    end
end

function RoomRecordLayer:tableCellAtIndex( view, idx )
    local cell = view:dequeueCell()
    if not cell then        
        cell = cc.TableViewCell:new()
    else
        cell:removeAllChildren()
    end

    if self.m_checkSwitch:isSelected() then
        local tabData = PriRoom:getInstance().m_tabCreateRecord[idx + 1]
        local item = self:createRecordItem(tabData)
        item:setPosition(view:getViewSize().width * 0.5, 25)
        cell:addChild(item)
    else
        local tabData = PriRoom:getInstance().m_tabJoinRecord[idx + 1]
        local item = self:joinRecordItem(tabData)
        item:setPosition(view:getViewSize().width * 0.5, 25)
        cell:addChild(item)
    end

    return cell
end

-- 创建记录
function RoomRecordLayer:createRecordItem( tabData )
    --tabData = tagPersonalRoomInfo
    local item = ccui.Widget:create()
    item:setContentSize(cc.size(1130, 50))
    
    -- 线
    local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("pri_sp_listline.png")
    if nil ~= frame then
        local sp = cc.Sprite:createWithSpriteFrame(frame)
        item:addChild(sp)
        sp:setPosition(565, 0)
    end
    
    -- 创建时间
    local tabTime = tabData.sysCreateTime
    local strTime = string.format("%d-%02d-%02d %02d:%02d:%02d", tabTime.wYear, tabTime.wMonth, tabTime.wDay, tabTime.wHour, tabTime.wMinute, tabTime.wSecond)
    local createtime = cc.Label:createWithTTF(strTime,"fonts/round_body.ttf",20)
    createtime:setTextColor(cc.c3b(244,237,182))
    item:addChild(createtime)
    createtime:setPosition(self.m_creCreateTime:getPositionX(), 25)

    -- 房间ID
    local roomid = cc.Label:createWithTTF(tabData.szRoomID,"fonts/round_body.ttf",20)
    roomid:setTextColor(cc.c3b(244,237,182))
    item:addChild(roomid)
    roomid:setPosition(self.m_creRoomID:getPositionX(), 25)

    -- 房间限制
    local roomlimit = cc.Label:createWithTTF(tabData.dwPlayTurnCount .. "","fonts/round_body.ttf",20)
    roomlimit:setTextColor(cc.c3b(244,237,182))
    item:addChild(roomlimit)
    roomlimit:setPosition(self.m_creRoomLimit:getPositionX(), 25)

    local feeType = "房卡"
    if tabData.cbCardOrBean == 0 then
        feeType = "游戏豆"
    end
    -- 创建消耗
    local cost = cc.Label:createWithTTF(tabData.lFeeCardOrBeanCount .. feeType,"fonts/round_body.ttf",20)
    cost:setTextColor(cc.c3b(244,237,182))
    item:addChild(cost)
    cost:setPosition(self.m_creCost:getPositionX(), 25)

    -- 奖励
    local award = cc.Label:createWithTTF(tabData.lScore .. "游戏币","fonts/round_body.ttf",20)
    award:setTextColor(cc.c3b(244,237,182))
    item:addChild(award)
    award:setPosition(self.m_creAward:getPositionX(), 25)

    -- 房间状态
    local bOnGame = false
    local status = cc.Label:createWithTTF("","fonts/round_body.ttf",20)
    if tabData.cbIsDisssumRoom == 1 then -- 解散
        status:setTextColor(cc.c3b(23,170,255))
        status:setString("已解散")
        tabTime = tabData.sysDissumeTime
        strTime = string.format("%d-%02d-%02d %02d:%02d:%02d", tabTime.wYear, tabTime.wMonth, tabTime.wDay, tabTime.wHour, tabTime.wMinute, tabTime.wSecond)
    else -- 游戏中
        status:setTextColor(cc.c3b(255,21,21))
        status:setString("游戏中")
        bOnGame = true
        strTime = ""
    end    
    item:addChild(status)
    status:setPosition(self.m_creStatus:getPositionX(), 25)

    -- 解散时间    
    local distime = cc.Label:createWithTTF(strTime,"fonts/round_body.ttf",20)
    distime:setTextColor(cc.c3b(244,237,182))
    item:addChild(distime)
    distime:setPosition(self.m_creDisTime:getPositionX(), 25)

    item:setTouchEnabled(true)
    item:setSwallowTouches(false)
    local itemFunC = function(ref, tType)
        if tType == ccui.TouchEventType.ended then
            local tabDetail = tabData
            tabDetail.onGame = bOnGame
            tabDetail.enableDismiss = true
            local rd = RoomDetailLayer:create(tabDetail)
            rd:setName(ROOMDETAIL_NAME)
            self:addChild(rd)
        end
    end
    item:addTouchEventListener( itemFunC )
    return item
end

-- 参与记录
function RoomRecordLayer:joinRecordItem( tabData )
    --tabData = tagQueryPersonalRoomUserScore
    local item = ccui.Widget:create()
    item:setContentSize(cc.size(1130, 50))

    -- 线
    local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("pri_sp_listline.png")
    if nil ~= frame then
        local sp = cc.Sprite:createWithSpriteFrame(frame)
        item:addChild(sp)
        sp:setPosition(565, 0)
    end
    
    -- 创建时间
    local tabTime = tabData.sysCreateTime
    local strTime = string.format("%d-%02d-%02d %02d:%02d:%02d", tabTime.wYear, tabTime.wMonth, tabTime.wDay, tabTime.wHour, tabTime.wMinute, tabTime.wSecond)
    local createtime = cc.Label:createWithTTF(strTime,"fonts/round_body.ttf",20)
    createtime:setTextColor(cc.c3b(244,237,182))
    item:addChild(createtime)
    createtime:setPosition(self.m_joinCreateTime:getPositionX(), 25)

    -- 房间ID
    local roomid = cc.Label:createWithTTF(tabData.szRoomID,"fonts/round_body.ttf",20)
    roomid:setTextColor(cc.c3b(244,237,182))
    item:addChild(roomid)
    roomid:setPosition(self.m_joinRoomID:getPositionX(), 25)

    -- 创建玩家
    local createusr = ClipText:createClipText(cc.size(120, 30), tabData.szUserNicname, "fonts/round_body.ttf", 20)
    createusr:setAnchorPoint(cc.p(0.5, 0.5))
    createusr:setTextColor(cc.c4b(244,237,182,255))
    item:addChild(createusr)
    createusr:setPosition(self.m_joinCreateUser:getPositionX(), 25)

    local scorestr = "+" .. tabData.lScore
    if tabData.lScore < 0 then
        scorestr = "" .. tabData.lScore
    end
    if tabData.bFlagOnGame then
        scorestr = ""
    end
    -- 个人战绩
    local uinfo = ClipText:createClipText(cc.size(150, 30), scorestr, "fonts/round_body.ttf", 20)
    uinfo:setAnchorPoint(cc.p(0.5, 0.5))
    uinfo:setTextColor(cc.c4b(244,237,182,255))
    item:addChild(uinfo)
    uinfo:setPosition(self.m_joinUinfo:getPositionX(), 25)

    -- 解散时间
    tabTime = tabData.sysDissumeTime
    strTime = string.format("%d-%02d-%02d %02d:%02d:%02d", tabTime.wYear, tabTime.wMonth, tabTime.wDay, tabTime.wHour, tabTime.wMinute, tabTime.wSecond)
    local distime = cc.Label:createWithTTF(strTime,"fonts/round_body.ttf",20)
    distime:setTextColor(cc.c3b(244,237,182))
    if tabData.bFlagOnGame then
        distime:setString("游戏中")
        distime:setTextColor(cc.c3b(255,21,21))
    end
    item:addChild(distime)
    distime:setPosition(self.m_joinDisTime:getPositionX(), 25)

    item:setTouchEnabled(true)
    item:setSwallowTouches(false)
    local itemFunC = function(ref, tType)
        if tType == ccui.TouchEventType.ended then
            local tabDetail = tabData
            tabDetail.onGame = tabData.bFlagOnGame or false 
            tabDetail.enableDismiss = false
            local rd = RoomDetailLayer:create(tabDetail)
            rd:setName(ROOMDETAIL_NAME)
            self:addChild(rd)            
        end
    end
    item:addTouchEventListener( itemFunC )
    return item
end

return RoomRecordLayer