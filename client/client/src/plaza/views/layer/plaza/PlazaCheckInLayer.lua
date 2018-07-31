local PlazaCheckInLayer =
    class(
    'PlazaCheckInLayer',
    function(scene)
        local optionLayer = cc.LayerColor:create(cc.c4b(0, 0, 0, 0))
        return optionLayer
    end
)
local PlazaCheckInFrame = appdf.req(appdf.CLIENT_SRC .. 'plaza.models.PlazaCheckInFrame')
PlazaCheckInLayer.WIDGET_TAG = {}
local WIDGET_TAG = PlazaCheckInLayer.WIDGET_TAG

-- 进入场景而且过渡动画结束时候触发
function PlazaCheckInLayer:onEnterTransitionFinish()
    self.m_tabInfoTips = {}
    self._tipIndex = 1
    self.m_nNotifyId = 0
    -- 系统公告列表
    self.m_tabSystemNotice = {}
    self._sysIndex = 1
    -- 公告是否运行
    self.m_bNotifyRunning = false

    local url = yl.HTTP_URL .. '/WS/MobileInterface.ashx?action=getcheckinnotice'
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
                                item.id = 0
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


    return self
end
-- 退出场景而且开始过渡动画时候触发
function PlazaCheckInLayer:onExitTransitionStart()
    if self.m_socketFrame:isSocketServer() then
        self.m_socketFrame:onCloseSocket()
    end

    return self
end

function PlazaCheckInLayer:ctor(scene)
    appdf.registerTouchOutsideHandler(self, false, 'main', false)
    appdf.registerNodeEvent(self)
    local csbNode = cc.CSLoader:createNode('checkIn/PlazaCheckInLayer.csb'):addTo(self):move(0, -40)

    self.layer_main = csbNode
    self._scene = scene

    appdf.setNodeTagAndListener(csbNode, 'btn_close', 'BT_CLOSE', handler(self, self.onButtonClickedEvent))
    appdf.setNodeTagAndListener(csbNode, 'btn_enter', 'BT_CHECK', handler(self, self.onButtonClickedEvent))

    -- 起始下标
    local fristIndex = os.date('%w', os.time() - (os.date('%d') - 1) * 24 * 60 * 60)

    -- 总天数
    local dayCount = os.date('%d', os.time({year = os.date('%Y'), month = os.date('%m') + 1, day = 0}))

    -- 当天
    local today = os.date('%d')
    self._today = tonumber(today)

    fristIndex = tonumber(fristIndex)
    dayCount = tonumber(dayCount)

    if fristIndex == 0 then
        fristIndex = fristIndex + 7
    end

    self.m_tableDay = {}

    local t = self.m_tableDay
    local nowDay = 1
    local lastDayCount = os.date('%d', os.time({year = os.date('%Y'), month = os.date('%m'), day = 0}))
    lastDayCount = tonumber(lastDayCount) - fristIndex
    local nextDayCount = 1

    fristIndex = fristIndex + 1
    self.beginIdxOfMoth = fristIndex
    --dump(self.beginIdxOfMoth)
    for i = 1, 42 do
        t[i] = {}
        if i < fristIndex then
            lastDayCount = lastDayCount + 1
            t[i].value = lastDayCount
        elseif i >= fristIndex and dayCount >= nowDay then
            t[i].isCheck = false
            t[i].value = nowDay
            nowDay = nowDay + 1
        else
            t[i].value = nextDayCount
            nextDayCount = nextDayCount + 1
        end
    end

    self:initContentTableView(csbNode)

    --喇叭
    self._notify = appdf.getNodeByName(csbNode, 'tips')

    local size = self._notify:getContentSize()

    local stencil = display.newSprite():setAnchorPoint(cc.p(0, 0.5))
    stencil:setTextureRect(cc.rect(0, 0, size.width - 160, size.height))
    self._notifyClip = cc.ClippingNode:create(stencil):setAnchorPoint(cc.p(0, 0.5))
    self._notifyClip:setInverted(false)
    self._notifyClip:move(80, 21)
    self._notifyClip:addTo(self._notify)

    self._notifyText =
        cc.Label:createWithTTF('', 'fonts/round_body.ttf', 24):addTo(self._notifyClip):setTextColor(
        cc.c4b(255, 191, 123, 255)
    ):setAnchorPoint(cc.p(0, 0.5)):enableOutline(cc.c4b(79, 48, 35, 255), 1)
end

function PlazaCheckInLayer:initContentTableView(csbNode)
    self.clone_item = appdf.getNodeByName(self, 'clone_item')

    local contentSize = self.clone_item:getContentSize()

    self.contentItemSize = {
        width = contentSize.width
    }

    local m_tableview =
        ccui.UITableView:create(
        {
            viewRect = cc.rect(677, 336, 780, 280),
            direction = cc.SCROLLVIEW_DIRECTION_VERTICAL,
            fill = cc.TABLEVIEW_FILL_TOPDOWN,
            interval = 0,
            createCell = handler(self, self.contentCreateCell),
            getCellCount = handler(self, self.contentGetCellsCount),
            getCellSize = nil,
            override = true
        }
    ):addTo(csbNode):setName('content_TableView'):setCloneCellItem(self.clone_item):setTableViewTouchEnabled(false):updateView(

    )
end

function PlazaCheckInLayer:contentGetCellsCount(view)
    return 6
end

function PlazaCheckInLayer:contentCreateCell(view, idx)
    local cell = view:dequeueCell()

    local item

    if cell == nil then
        cell = cc.TableViewCell:new()
    else
        cell:removeAllChildren()
    end

    for count = 1, 7 do
        local idx = idx * 7 + count
        local v = self.m_tableDay[idx]

        local item = self.clone_item:clone()
        local text = appdf.getNodeByName(item, 'day_value'):setString(v.value)

        if v.isCheck ~= nil and v.isCheck == true then
            local icon = appdf.getNodeByName(item, 'icon'):setVisible(true)
        end

        local x = self.contentItemSize.width * (count - 1)

        item:setAnchorPoint(0, 0)
        item:setPosition(x, 0)
        item:setTag(idx)
        cell:addChild(item)
    end

    return cell
end

--按键监听
function PlazaCheckInLayer:onButtonClickedEvent(tag, sender)
    if tag == WIDGET_TAG.BT_CLOSE then
        self:dismiss()
    end

    if tag == WIDGET_TAG.BT_CHECK then
        self.m_socketFrame:onCheckinDone()
    end
end

function PlazaCheckInLayer:onCheckCallBack(sub, message)
    --dump(self.m_tableDay)
    local bres = false
    if sub == '签到信息' then

        self._bTodayChecked = message.bTodayChecked
        local checkday = message.wSeriesDate
        
        if message.bTodayChecked == true then
            showToast(self, "今天已经签到啦~明天再来!", 1.5)
        end

        local check_day = appdf.getNodeByName(self, 'check_day'):setString(checkday)
        local stratIndex
        local endIndex

        for k, v in ipairs(self.m_tableDay) do
            if v.value == self._today and v.isCheck == false then
                if checkday ~= 0 then
                    if self._bTodayChecked == true then
                        stratIndex = k - checkday + 1
                        endIndex = k
                    else
                        stratIndex = k - checkday
                        endIndex = k - 1
                    end
                end
                break
            end
        end
        
        
        for i=1,31 do
            if i+self.beginIdxOfMoth-1 > 42 then
                break
            end
            self.m_tableDay[i+self.beginIdxOfMoth-1].isCheck = (message.bMonthChecked[1][i] == 1 and true or false)
        end
        --dump(self.m_tableDay)
--[[         if checkday ~= 0 then
            for i = stratIndex, endIndex do
                local v = self.m_tableDay[i]

                v.isCheck = true
            end
        end ]]

        local view = appdf.getNodeByName(self, 'content_TableView'):updateView()

        if self._bTodayChecked == true then
            local btn_enter = appdf.getNodeByName(self, 'btn_enter'):setTouchEnabled(false)
        end
    end

    if sub == '签到结果' then
        local checkresult = message.bSuccessed
        local szNotifyContent = message.szNotifyContent
        showToast(self, szNotifyContent, 2)
        local checkday = message.wSeriesDate
        if checkresult == true then
            self._scene:queryUserScoreInfo()

            local check_day = appdf.getNodeByName(self, 'check_day'):setString(checkday)
            local btn_enter = appdf.getNodeByName(self, 'btn_enter'):setTouchEnabled(false)

            local index
            for k, v in ipairs(self.m_tableDay) do
                if v.value == self._today and v.isCheck == false then
                    index = k
                    break
                end
            end
            self.m_tableDay[index].isCheck = true
            local view = appdf.getNodeByName(self, 'content_TableView'):updateView()
        end
    end
end

--跑马灯更新
function PlazaCheckInLayer:onChangeNotify(msg)
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
                    self._notifyText:move(yl.WIDTH - 760, 0)
                    self._notifyText:setVisible(true)
                end
            ),
            cc.MoveTo:create(10 + (tmpWidth / 172), cc.p(0 - tmpWidth, 0)),
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

function PlazaCheckInLayer:dismiss(cb)
    self:runAction(
        cc.Sequence:create(
            cc.FadeOut:create(0),
            cc.CallFunc:create(
                function()
                    self:setTouchEnabled(false)
                    -- self:setVisible(false)
                    self:removeSelf()
                end
            )
        )
    )
end

function PlazaCheckInLayer:show(cb)
    self.layer_main:stopAllActions()
    self:setVisible(true)
    self:runAction(cc.Sequence:create(cc.FadeTo:create(0.3, 200)))

    self.layer_main:runAction(
        cc.Sequence:create(
            cc.MoveTo:create(0.25, cc.p(0, 0)),
            cc.CallFunc:create(
                function()
                    self:setTouchEnabled(true)
                    self.m_socketFrame = PlazaCheckInFrame:create(self, handler(self, self.onCheckCallBack))

                    self.m_socketFrame:onQueryCheckin()

                    if cb then
                        cb()
                    end
                end
            )
        )
    )
end

return PlazaCheckInLayer
