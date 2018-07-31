local GameChatLayer =
    class(
    'GameChatLayer',
    function()
        local GameChatLayer = cc.LayerColor:create(cc.c4b(0, 0, 0, 150))
        return GameChatLayer
    end
)

local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. 'ExternalFun')
local HeadSpriteHelper = appdf.req(appdf.EXTERNAL_SRC .. 'HeadSpriteHelper')
-- 菜单枚举
local MENU_ENUM = {
    MENU_1 = 1,
    MENU_2 = 2
}

local Create_Type = {
    chat = 10, -- 聊天
    face = 11, -- 表情
    voice = 12 -- 语音
}

-- 快捷文本 -> 男
local quickChatText = {
    '哈哈 偷抓奶无人知',
    '叫友叔怕书拍学落，实际不难学个',
    '猪脑拍，这道牌硬赢个',
    '鲁就是我个队友吗',
    '朋友啊 鲁真野',
    '明天正来玩了，找睡觉了',
    '甲鲁打牌，我最开心了',
    '鲁全身是钢，下下吃会对',
    '等下 等下 我做点事就回来',
    '拿不到好牌 神仙刀无法',
    '又断线 要打到几点才完',
    '猛下仔 我要回家煮菜朵',
    '我迈 我迈 拿这浪屎牌',
    '不怕神一样的对手,就怕猪一样的队友',
    '无过鲁乡里初玛人问那 鲁物了里好',
    '道道 这道牌恶无命'
}

-- 事件监听
GameChatLayer.NET_LISTENER = {
    'AddChatRecordMsg'
}

GameChatLayer.BTN_SEND = 100
GameChatLayer.BTN_INPUT = 80

function GameChatLayer:ctor(frame)
    self:move(0, display.height)

    self:createMsgEventlistBinding()
    self:setGameFrameEngineSocket(frame)

    self.MENU_STATE = MENU_ENUM.MENU_1

    local node = ExternalFun.loadCSB('public/GameChatLayer.csb', self)
    local main = appdf.getNodeByName(self, 'main')

    local layerTouch = function(eventType, x, y)
        if eventType == 'began' then
            local node = appdf.getNodeByName(self, 'main')
            local rect = node:getBoundingBox()
            if cc.rectContainsPoint(rect, cc.p(x, y)) == false then
                self:dismiss()
            end
        end
        return true
    end

    self:setTouchEnabled(false)
    self:setSwallowsTouches(true)
    self:registerScriptTouchHandler(layerTouch)

    -- 菜单点击按钮
    local menuTouch = function(v, e)
        if e == ccui.TouchEventType.ended then
            self.MENU_STATE = v:getTag()

            self:changeViewByTag(self.MENU_STATE)
        end
    end

    for i = 1, 2 do
        local nodeName = string.format('menu_%d', i)
        local menu =
            appdf.getNodeByName(main, nodeName):setTag(i):ignoreContentAdaptWithSize(true):addTouchEventListener(
            menuTouch
        )
    end

    -- 点击事件
    local btnEvent = function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:onButtonClickedEvent(sender:getTag(), sender)
        end
    end

    local send_msg_btn =
        appdf.getNodeByName(self, 'send_msg'):setTag(GameChatLayer.BTN_SEND):addTouchEventListener(btnEvent)

    local input_clean =
        appdf.getNodeByName(self, 'input_clean'):setTag(GameChatLayer.BTN_SEND):addTouchEventListener(
        function(v, e)
            if e == ccui.TouchEventType.ended then
                local chat_Input = appdf.getNodeByName(self, 'chat_Input'):setString('')

                v:setVisible(false)

                local send_msg_btn =
                    appdf.getNodeByName(self, 'send_msg'):loadTexture('public/srjy_send.png', UI_TEX_TYPE_LOCAL)
            end
        end
    )

    local chat_Input =
        appdf.getNodeByName(self, 'chat_Input'):setTag(GameChatLayer.BTN_INPUT):addEventListener(
        function(v, e)
            -- 焦点
            if e == ccui.TextFiledEventType.attach_with_ime then
                -- 失去焦点
            elseif e == ccui.TextFiledEventType.detach_with_ime then
                -- 输入监听
            elseif e == ccui.TextFiledEventType.insert_text then
                -- 删除监听
                local inputString = v:getString()
                local strLen = ExternalFun.stringLen(inputString)
                local input_clean = appdf.getNodeByName(self, 'input_clean')
                local send_msg_btn = appdf.getNodeByName(self, 'send_msg')
                if strLen > 0 then
                    input_clean:setVisible(true)
                    send_msg_btn:loadTexture('public/srjy_send.png', UI_TEX_TYPE_LOCAL)
                end

                if strLen > 28 then
                    showToast(self, '只能输入16个中文哦!', 2)
                end
            elseif e == ccui.TextFiledEventType.delete_backward then
                local inputString = v:getString()

                local strLen = ExternalFun.stringLen(inputString)

                local input_clean = appdf.getNodeByName(self, 'input_clean')
                local send_msg_btn = appdf.getNodeByName(self, 'send_msg')
                if strLen == 0 then
                    input_clean:setVisible(false)
                    send_msg_btn:loadTexture('public/srjy_send.png', UI_TEX_TYPE_LOCAL)
                end
            end
        end
    )
    self.m_tableChatRecord = {}

    self.lastSpriteAni = nil

    self:initExpression(main)
    self:initChatRecord(main)
    self:initQuickChat(main)
end

function GameChatLayer:onButtonClickedEvent(tag, view)
    if tag == GameChatLayer.BTN_SEND then
        local input = appdf.getNodeByName(self, 'chat_Input')

        local chatstr = input:getString()

        chatstr = string.gsub(chatstr, ' ', '')

        if ExternalFun.stringLen(chatstr) > 30 then
            showToast(self, '聊天内容过长', 2)
            return
        end

        --判断emoji
        if ExternalFun.isContainEmoji(chatstr) then
            showToast(self, '聊天内容包含非法字符,请重试', 2)
            return
        end

        --敏感词过滤
        if true == ExternalFun.isContainBadWords(chatstr) then
            showToast(self, '聊天内容包含敏感词汇!', 2)
            return
        end

        if '' ~= chatstr then
            local valid, msg = self:sendQuickChatOrChatData(chatstr)
            if false == valid and type(msg) == 'string' and '' ~= msg then
                showToast(self, msg, 2)
            else
                self:dismiss()
                input:setString('')
                local input_clean = appdf.getNodeByName(self, 'input_clean'):setVisible(false)

                local send_msg_btn =
                    appdf.getNodeByName(self, 'send_msg'):loadTexture('public/srjy_send.png', UI_TEX_TYPE_LOCAL)
            end
        else
            showToast(self, '请输入文字内容!', 1)
        end
    end
end

-- 表情
function GameChatLayer:initExpression(main)
    local pageview = appdf.getNodeByName(self, 'ScrollView_1'):setVisible(false)

    local pos = cc.p(pageview:getPosition())

    local PageViewItemTouch = function(e)
        if e.name == 'clicked' then
            if e.itemIdx > 18 then
                return
            end
            if self:sendExpressionData(e.itemIdx) then
                self:dismiss()
            else
                showToast(self, '网络繁忙稍后再尝试!', 2)
            end
        -- end
        end
    end

    local contentSize = pageview:getContentSize()
    local pg =
        ccui.QuickUIPageView.new(
        {
            viewRect = cc.rect(0, 0, contentSize.width, contentSize.height),
            column = 3,
            row = 3,
            padding = {left = 0, right = 0, top = 0, bottom = 0},
            columnSpace = 0,
            rowSpace = 0,
            bCirc = false
        }
    ):setName('Top_PageView'):setPosition(cc.p(pos.x, pos.y)):onTouch(PageViewItemTouch):addTo(main)

    -- local initIndicatorRes = {
    -- 	"GameChat/Indicator_bg.png",
    -- 	"GameChat/Indicator_on_bg.png",
    -- }

    -- -- 指示器
    -- pg:setInitIndicatorRes(initIndicatorRes)

    for i = 1, 18 do
        local item = pg:newItem()
        local textureName
        local textureName = string.format('public/srjy_chatface_%d.png', i)

        local content =
            ccui.ImageView:create(textureName, ccui.TextureResType.localType):setContentSize(76, 76):ignoreContentAdaptWithSize(
            false
        ):setPosition(cc.p(63, 65))

        content:setTouchEnabled(true)
        content:setSwallowTouches(false)

        item:addChild(content, 1)
        pg:addItem(item)
    end

    pageview:removeSelf()
    pg:reload()
end

-- 点击表情回调
function GameChatLayer:setExpressionCallBack(cb)
    self._ExpressionCallBack = cb
end

-- 聊天记录
function GameChatLayer:initChatRecord(main)
    local view = appdf.getNodeByName(self, 'ScrollView_2')

    local pos = cc.p(view:getPosition())

    local contentSize = view:getContentSize()

    contentSize.width = 320
    -- view:removeSelf()
    -- cloneItem
    self.chat_record_me = appdf.getNodeByName(self, 'chat_record_me')
    self.chat_record_their = appdf.getNodeByName(self, 'chat_record_their')

    local itemContentSize = self.chat_record_me:getContentSize()
    -- itemSize
    self.chatRecordItemSize = {
        width = itemContentSize.width,
        height = 120
    }

    local tableView = cc.TableView:create(contentSize)
    tableView:setName('chatRecord_TableView')
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    tableView:setPosition(pos)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    main:addChild(tableView, 10)
    tableView:setDelegate()

    tableView:registerScriptHandler(handler(self, self.chatRecordCellTouched), cc.TABLECELL_TOUCHED)
    tableView:registerScriptHandler(handler(self, self.chatRecordCellSize), cc.TABLECELL_SIZE_FOR_INDEX)
    tableView:registerScriptHandler(handler(self, self.chatRecordCreatItem), cc.TABLECELL_SIZE_AT_INDEX)
    tableView:registerScriptHandler(handler(self, self.chatRecordCellCount), cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    tableView:setVisible(false)

    tableView:reloadData()
end

function GameChatLayer:chatRecordCellTouched(view, cell)
    local v = self.m_tableChatRecord[cell:getIdx() + 1]
end

function GameChatLayer:chatRecordCellSize(view, idx)
    return self.chatRecordItemSize.width, self.chatRecordItemSize.height
end

function GameChatLayer:chatRecordCellCount(view)
    return #self.m_tableChatRecord
end

function GameChatLayer:chatRecordCreatItem(view, idx)
    local cell = view:dequeueCell()
    if cell == nil then
        cell = cc.TableViewCell:new()
    else
        cell:removeAllChildren()
    end

    local item

    local v = self.m_tableChatRecord[idx + 1]

    if v == nil then
        return cell
    end

    if v.dwUserID == GlobalUserItem.dwUserID then
        item = self.chat_record_me:clone()
    else
        item = self.chat_record_their:clone()
    end
    item:setPosition(0, 20)
    item:setAnchorPoint(0, 0)
    item:setTag(idx + 1)
    cell:addChild(item)
    item:setVisible(true)
    local content = appdf.getNodeByName(item, 'content')
    content:setString(v.content)

    if v.content ~= nil then
        local strlen = string.len(v.content)
        local strbyte = string.byte(v.content)
        local strT = {}
        if strbyte < 128 then
            if strlen > 7 and strlen <= 14 then
                local strsub_1, strsub_2 = string.sub(v.content, 1, 7), string.sub(v.content, 7, strlen)
                strT = {strsub_1, strsub_2}
            elseif strlen > 14 then
                local strsub_1,
                    strsub_2,
                    strsub_3 =
                    string.sub(v.content, 1, 7),
                string.sub(v.content, 8, 14),
                string.sub(v.content, 15, strlen)
                strT = {strsub_1, strsub_2, strsub_3}
            else
                strT = {v.content}
            end
            local str = table.concat(strT, '\n')
            content:setString(str)
        else
            content:setString(v.content)
        end
    end

    local chat_face = appdf.getNodeByName(item, 'chat_face')
    if v.expressionIdx ~= nil then
        local facestr = string.format('public/srjy_chatface_%d.png', v.expressionIdx)
        chat_face:loadTexture(facestr)
    end

    if v.content == nil then
        chat_face:setVisible(true)
        content:setVisible(false)
    else
        chat_face:setVisible(false)
        content:setVisible(true)
    end

    local userName = appdf.getNodeByName(item, 'user_name'):setString(v.szNickName)
    local userAvatar = appdf.getNodeByName(item, 'user_avatar')
    HeadSpriteHelper:createClipMaskImg(nil, v, userAvatar, 70, nil)
    local time = appdf.getNodeByName(item, 'time'):setString(v.msgTime)
    -- local sp = display.newSprite():setName('_Sp'):setScale(0.5):setPosition(cc.p(chat_face:getPosition())):addTo(item)
    -- sp:setTexture(v.expressionIdx)

    return cell
end
-- 快捷聊天
function GameChatLayer:initQuickChat(main)
    local view = appdf.getNodeByName(self, 'ScrollView_2')

    local pos = cc.p(view:getPosition())

    local contentSize = view:getContentSize()

    view:removeSelf()

    self.Text_chat = appdf.getNodeByName(self, 'Text_chat')

    self.textChatContentSize = self.Text_chat:getContentSize()

    self.textChatSize = {
        width = self.textChatContentSize.width,
        height = 70
    }
    local tableView = cc.TableView:create(contentSize)
    tableView:setName('quickChat_TableView')
    tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL)
    tableView:setPosition(pos)
    tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
    main:addChild(tableView, 1)
    tableView:setDelegate()

    tableView:registerScriptHandler(handler(self, self.quickChatCellTouched), cc.TABLECELL_TOUCHED)
    tableView:registerScriptHandler(handler(self, self.quickChatCellSize), cc.TABLECELL_SIZE_FOR_INDEX)
    tableView:registerScriptHandler(handler(self, self.quickChatCreatItem), cc.TABLECELL_SIZE_AT_INDEX)
    tableView:registerScriptHandler(handler(self, self.quickChatCellCount), cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
    tableView:reloadData()
end

-- 快捷文本点击
function GameChatLayer:quickChatCellTouched(view, cell)
    local idx = cell:getIdx() + 1
    
    local chatData = quickChatText[idx]
    if chatData ~= nil then
        if not self:sendQuickChatOrChatData(chatData) then
            showToast(self, '发送失败!请稍后尝试!', 2)
        else
            self:dismiss()
        end
    end
end

function GameChatLayer:quickChatCellSize(view, idx)
    return self.textChatSize.width, self.textChatSize.height
end

function GameChatLayer:quickChatCellCount(view)
    return #quickChatText
end

function GameChatLayer:quickChatCreatItem(view, idx)
    local cell = view:dequeueCell()

    if cell == nil then
        cell = cc.TableViewCell:new()
    else
        cell:removeAllChildren()
    end
    local v = quickChatText[idx + 1]

    if v == nil then
        return cell
    end

    local item = self.Text_chat:clone()
    item:setString(v)
    item:setPosition(5, 10)
    item:setAnchorPoint(0, 0)
    item:setTag(idx + 1)
    cell:addChild(item)
    return cell
end

-- 添加聊天记录
function GameChatLayer:onAddChatRecordMsgListener(e)
    local result = e.msg
    if result ~= nil then
        result.chat.msgTime = os.date('%H:%M:%S', os.time())
        table.insert(self.m_tableChatRecord, result.chat)
        local tbview = appdf.getNodeByName(self, 'chatRecord_TableView'):reloadData()

        if self:isVisible() == true then
            local cur = #self.m_tableChatRecord - 4

            if cur > 0 then
                tbview:setContentOffset(cc.p(0, 0), false)
            end
        end
    end
end

-- 发送表情
function GameChatLayer:sendExpressionData(idx)
    dump('GameChatLayer:sendExpressionData(idx)')
    if nil ~= self._GameFrameEngineSocket and nil ~= self._GameFrameEngineSocket.sendBrowChat then
        return self._GameFrameEngineSocket:sendBrowChat(idx)
    end
    return false, ''
end

-- 发送快捷文本 or 聊天文本
function GameChatLayer:sendQuickChatOrChatData(msg)
    dump('GameChatLayer:sendQuickChatOrChatData(msg)')
    if self._GameFrameEngineSocket ~= nil and self._GameFrameEngineSocket.sendTextChat ~= nil then
        return self._GameFrameEngineSocket:sendTextChat(msg)
    end
    return false, ''
end

function GameChatLayer:changeViewByTag(tag)
    local chat = appdf.getNodeByName(self, 'quickChat_TableView')
    local record = appdf.getNodeByName(self, 'chatRecord_TableView')
    local chatview = appdf.getNodeByName(self, 'chatbg')
    if tag == MENU_ENUM.MENU_1 then
        record:setVisible(false)
        chat:setVisible(true)
        chatview:loadTexture('public/srjy_chatbg_02.png')
    elseif tag == MENU_ENUM.MENU_2 then
        chat:setVisible(false)
        chatview:loadTexture('public/srjy_chatbg_03.png')
        record:setVisible(true)
    end
end

-- 消息socket
function GameChatLayer:setGameFrameEngineSocket(socket)
    self._GameFrameEngineSocket = socket
    return self
end

function GameChatLayer.findQuickChatStingToIndex(str)
    local index
    for k,v in ipairs(quickChatText) do

        if v == str then
            index = k
            break
        end
    end

    return index
end

function GameChatLayer:dismiss()
    self:setVisible(false)
    self:move(0, display.height)
    local chat_Input = appdf.getNodeByName(self, 'chat_Input'):setString('')
    local input_clean = appdf.getNodeByName(self, 'input_clean'):setVisible(false)
    self:runAction(
        cc.Sequence:create(
            cc.DelayTime:create(0.2),
            cc.CallFunc:create(
                function()
                    self:setTouchEnabled(false)
                end
            )
        )
    )
end

function GameChatLayer:show()
    self:move(0, 0)

    self:setVisible(true)
    self:setTouchEnabled(true)

    local tbview = appdf.getNodeByName(self, 'chatRecord_TableView')

    local cur = #self.m_tableChatRecord - 4
    if cur > 0 then
        tbview:setContentOffset(cc.p(0, 0), true)
    end
end

-- 事件注册
function GameChatLayer:createMsgEventlistBinding()
    local msglist = rawget(self.class, 'NET_LISTENER')
    if not msglist or type(msglist) ~= 'table' then
        return
    end

    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()

    for _, rpcName in ipairs(msglist) do
        local resp = string.format('on%sListener', rpcName)

        assert(self[resp], 'event:%s has no callback.', rpcName)

        local customListenerBg = cc.EventListenerCustom:create(rpcName, handler(self, self[resp]))

        eventDispatcher:addEventListenerWithSceneGraphPriority(customListenerBg, self)
    end
end

--[[
    事件派发
]]
function GameChatLayer:dispatchMessage(key, msg)
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

return GameChatLayer
