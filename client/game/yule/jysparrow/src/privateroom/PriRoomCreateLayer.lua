local PriRoomCreateLayer =
    class(
    'PriRoomCreateLayer',
    function(scene)
        local layer = cc.LayerColor:create(cc.c4b(0, 0, 0, 0))
        return layer
    end
)

local BTN_CLOSE = 1
local BTN_CREATE = 2

local CBT_MJITEM_BEGIN = 100

local CBT_KOUFEI_BEGIN = 200 --扣费
local CBT_JUSHU_BEGIN = 210 --局数
local CBT_RENSHU_BEGIN = 220 --人数
local CBT_WANFA_BEGIN = 230 --玩法
local CBT_PAIXING_BEGIN = 240 --牌型
local CBT_GUIPAI_BEGIN = 300 --鬼牌
local CBT_MAPAI_BEGIN = 310 --马牌
local CBT_MAX = 330

local Mode_CSMJ = 1 --潮汕麻将
local Mode_TDH = 2 --推到胡
local CBT_CHEAT_OPEN = 3 --开启防作弊功能
local initNodeConfig = {
    -- 潮汕麻将
    {
        kf = {'ffSelected', 1},
        js = {'jsSelected', 1},
        rs = {'rsSelected', 3},
        wf = {'wfSelected', 3},
        px = {'pxSelected', {1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1, 1}},
        gp = {'gpSelected', 1},
        mp = {'mpSelected', {1, 0, 1, 1}}
    },
    -- 推到胡
    {
        kf = {'ffSelected', 1},
        js = {'jsSelected', 1},
        rs = {'rsSelected', 3},
        wf = {'wfSelected', 3},
        px = {'pxSelected', {1, 1, 1, 1, 1, 1}},
        gp = {'gpSelected', {1, 0}},
        mp = {'mpSelected', {1, 0, 0, 0}}
    }
}

function PriRoomCreateLayer:ctor(scene)
    self._scene = scene
    -- 加载csb资源
    appdf.registerTouchOutsideHandler(self, false, 'Sprite_1', false)

    local csbNode = cc.CSLoader:createNode('room/PrivateRoomCreateLayer.csb'):addTo(self):move(0, -40)
    self.m_csbNode = csbNode

    local function btncallback(ref, tType)
        if tType == ccui.TouchEventType.ended then
            self:onButtonClickedEvent(ref:getTag(), ref)
        end
    end

    local closeBtn = csbNode:getChildByName('Button_2'):setTag(BTN_CLOSE):addTouchEventListener(btncallback)

    local createBtn = csbNode:getChildByName('Button_1'):setTag(BTN_CREATE):addTouchEventListener(btncallback)

    local view = appdf.getNodeByName(self, 'left_listview')

    self.GameModeItems = {}
    for i = 1, 10 do
        local item = view:getChildByName('item_' .. i)
        if item then
            item:setTag(CBT_MJITEM_BEGIN + i)
            item:addTouchEventListener(btncallback)
            self.GameModeItems[CBT_MJITEM_BEGIN + i] = item
        end
    end
    --鬼牌
    local di_8 = appdf.getNodeByName(self, 'di_prop_8')
    local gptext = di_8:getChildByName('Text_1')
    local gpselect = gptext:getChildByName('CheckBox_1'):setTag(CBT_GUIPAI_BEGIN):addTouchEventListener(btncallback)

    local di_6 = appdf.getNodeByName(self, 'di_prop_6')
    local kx_ = appdf.getNodeByName(di_6, 'CheckBox_1'):setTag(CBT_CHEAT_OPEN)
    kx_:addTouchEventListener(btncallback)

    self.curCheat = true
    self.gpSelected = 1
    self:recoveryFromCache()
    self.GameModeItems[CBT_MJITEM_BEGIN + self.CurModeItem]:setEnabled(false)
end

function PriRoomCreateLayer:TextColor(boolean_, nodeName)
    local v = boolean_
    if v == true then
        nodeName:setTextColor(cc.c3b(233, 32, 28))
    else
        nodeName:setTextColor(cc.c3b(127, 15, 11))
    end
end
--鬼牌
function PriRoomCreateLayer:GpSelected()
    local gp = appdf.getNodeByName(self, 'di_prop_8')
    local gptext = gp:getChildByName('Text_1')
    local checkbox = gptext:getChildByName('CheckBox_1')
    local text = checkbox:getChildByName('Text_1')
    if checkbox:isSelected() == true then
        self:TextColor(true, text)
        self.gpSelected = 3
    else
        self.gpSelected = 1
        self:TextColor(false, text)
    end
end

function PriRoomCreateLayer:initGameModeSelections()
    self.CurModeItem = self.CurModeItem or 1
    local model = self.CurModeItem

    -- 规则根节点
    local cbtlistener = function(sender, eventType)
        self:onSelectedEvent(sender:getTag(), sender)
    end

    local txtlistener = function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:onSelectedEvent(sender:getParent():getTag(), sender:getParent())
        end
    end

    self.ruleView = appdf.getNodeByName(self.m_csbNode, 'ListView_2')

    local csmj = appdf.getNodeByName(self.m_csbNode, 'Node_mj')
    self.csmj = csmj

    -- 扣费规则
    local ff = csmj:getChildByName('di_prop_1')

    self.ffCheckbox = {}
    for i = 1, 2 do
        local checkbox = appdf.getNodeByName(ff, 'CheckBox_' .. i)
        checkbox:addEventListener(cbtlistener)
        checkbox:setTag(CBT_KOUFEI_BEGIN + i)
        checkbox:setSelected(false)

        local text = checkbox:getChildByName('Text_1')
        text:setTextColor(cc.c4b(106, 69, 50, 255))
        text:setTouchEnabled(true)
        text:addTouchEventListener(txtlistener)

        self.ffCheckbox[CBT_KOUFEI_BEGIN + i] = checkbox
    end

    -- 局数
    local js = csmj:getChildByName('di_prop_2')

    self.jsCheckbox = {}
    self.jsFeeText = {
        {text = '8局(房卡×%d)'},
        {text = '16局(房卡×%d)'}
    }

    for i = 1, 2 do
        local checkbox = appdf.getNodeByName(js, 'CheckBox_' .. i)
        checkbox:addEventListener(cbtlistener)
        checkbox:setTag(CBT_JUSHU_BEGIN + i)
        checkbox:setSelected(false)

        local text = checkbox:getChildByName('Text_1')
        text:setTextColor(cc.c4b(106, 69, 50, 255))
        text:setTouchEnabled(true)
        text:addTouchEventListener(txtlistener)

        self.jsCheckbox[CBT_JUSHU_BEGIN + i] = checkbox
        self.jsFeeText[i].node = checkbox:getChildByName('Text_1')
    end

    -- 人数
    local rs = csmj:getChildByName('di_prop_3')
    self.rsCheckbox = {}

    for i = 1, 3 do
        local checkbox = appdf.getNodeByName(rs, 'CheckBox_' .. i)
        checkbox:addEventListener(cbtlistener)
        checkbox:setTag(CBT_RENSHU_BEGIN + i)
        checkbox:setSelected(false)

        local text = checkbox:getChildByName('Text_1')
        text:setTextColor(cc.c4b(106, 69, 50, 255))
        text:setTouchEnabled(true)
        text:addTouchEventListener(txtlistener)

        self.rsCheckbox[CBT_RENSHU_BEGIN + i] = checkbox
    end

    --[[     -- 禁用2人，3人房间
    for i=1, 2 do 
        self.rsCheckbox[CBT_RENSHU_BEGIN + i]:setSelected(false)
        self.rsCheckbox[CBT_RENSHU_BEGIN + i]:setEnabled(false)
    end ]]
    -- 玩法
    local wf = csmj:getChildByName('di_prop_4')

    self.wfCheckbox = {}
    for i = 1, 2 do
        local checkbox = appdf.getNodeByName(wf, 'CheckBox_' .. i)
        checkbox:addEventListener(cbtlistener)
        checkbox:setTag(CBT_WANFA_BEGIN + i)
        checkbox:setSelected(false)

        local text = checkbox:getChildByName('Text_1')
        text:setTextColor(cc.c4b(106, 69, 50, 255))
        text:setTouchEnabled(true)
        text:addTouchEventListener(txtlistener)

        self.wfCheckbox[CBT_WANFA_BEGIN + i] = checkbox
    end

    -- 牌型
    local px = self.csmj:getChildByName('di_prop_5_' .. model)
    local o_px = self.csmj:getChildByName('di_prop_5_' .. (3 - model))

    px:setVisible(true)
    o_px:setVisible(false)

    self.pxCheckbox = {}
    local total = model == 1 and 20 or 6

    for i = 1, total do
        local checkbox = appdf.getNodeByName(px, 'CheckBox_' .. i)
        checkbox:addEventListener(cbtlistener)
        checkbox:setTag(CBT_PAIXING_BEGIN + i)
        checkbox:setSelected(false)

        local text = checkbox:getChildByName('Text_1')
        text:setTextColor(cc.c4b(106, 69, 50, 255))
        text:setTouchEnabled(true)
        text:addTouchEventListener(txtlistener)

        self.pxCheckbox[CBT_PAIXING_BEGIN + i] = checkbox
    end

    --[[-- 鬼牌
    local gp = self.csmj:getChildByName('di_prop_6_' .. model)
    local o_gp = self.csmj:getChildByName('di_prop_6_' .. (3 - model))

    gp:removeSelf()
    o_gp:removeSelf()

    total = model == 1 and 3 or 5

    self.gpCheckbox = {}
    for i=1,total do
        local checkbox = appdf.getNodeByName(gp, 'CheckBox_' .. i)
        checkbox:addEventListener(cbtlistener)
        checkbox:setTag(CBT_GUIPAI_BEGIN + i)
        checkbox:setSelected(false)

        local text = checkbox:getChildByName('Text_1')
        text:setTextColor(cc.c4b(106, 69, 50, 255))
        text:setTouchEnabled(true)
        text:addTouchEventListener(txtlistener)

        self.gpCheckbox[CBT_GUIPAI_BEGIN + i] = checkbox

        if i ~= 1 then
            checkbox:setEnabled(false)
        end
    end

    self.gpSelected = {1, 0}    --1:无鬼/双鬼/白板做鬼/翻鬼 2:是否 无鬼翻倍 
    self.gpCheckbox[CBT_GUIPAI_BEGIN + self.gpSelected[1] ]:setSelected(true)
    self.gpCheckbox[CBT_GUIPAI_BEGIN + self.gpSelected[1] ]:getChildByName('Text_1'):setTextColor(cc.c4b(229, 68, 43, 255))
    -- ]]
    -- 马牌
    --潮汕麻将：@fir: 1：无马 2：买马 3 抓马  @sec：[无马/抓马：0   买马：索引1,2,3] @trd：马跟底分 0/1 @fou：马跟杠 0/1
    --推到胡：@fir: 1: 马数 2：占位 3：马跟底分  4：马跟杠
    local mp = self.csmj:getChildByName('di_prop_7_' .. model)
    local o_mp = self.csmj:getChildByName('di_prop_7_' .. (3 - model))

    mp:setVisible(true)
    o_mp:setVisible(false)

    total = model == 1 and 8 or 6

    self.mpCheckbox = {}
    for i = 1, total do
        local checkbox = appdf.getNodeByName(mp, 'CheckBox_' .. i)
        checkbox:addEventListener(cbtlistener)
        checkbox:setTag(CBT_MAPAI_BEGIN + i)
        checkbox:setSelected(false)

        local text = checkbox:getChildByName('Text_1')
        text:setTextColor(cc.c4b(106, 69, 50, 255))
        text:setTouchEnabled(true)
        text:addTouchEventListener(txtlistener)

        self.mpCheckbox[CBT_MAPAI_BEGIN + i] = checkbox
    end

    if model == 1 then
        for i = 4, 8 do
            self.mpCheckbox[CBT_MAPAI_BEGIN + i]:setEnabled(false)
        end
    elseif model == 2 then
        for i = 5, 6 do
            self.mpCheckbox[CBT_MAPAI_BEGIN + i]:setEnabled(false)
        end
    end
end

function PriRoomCreateLayer:recoveryFromCache(tar)
    local getModeTag = function(m)
        local mode = ''
        if m == 1 then
            mode = 'csmj'
        elseif m == 2 then
            mode = 'tdh'
        end
        return mode
    end

    if not tar then
        -- 全部恢复，从文件恢复 或 缺省配置

        local ModelCache = self:loadJsonFile('MajiangModel')
        if ModelCache == nil then
            self.CurModeItem = 1
            self.ModelCfg = {}

            for i = 1, #initNodeConfig do -- 2
                if initNodeConfig[i] then
                    local mode = getModeTag(i)
                    self.ModelCfg[mode] = {}

                    for k, v in pairs(initNodeConfig[i]) do
                        self.ModelCfg[mode][k] = v[2]
                    end
                end
            end

            -- dump(self.CurModeItem, '初始所有默认配置')
            -- dump(self.ModelCfg)

            local mode = getModeTag(self.CurModeItem)
            for k, v in pairs(initNodeConfig[self.CurModeItem]) do
                self[v[1]] = self.ModelCfg[mode][k]
            end
        else
            self.CurModeItem = ModelCache['curMode']

            self.ModelCfg = {}

            self.ModelCfg['curMode'] = self.CurModeItem
            for k, v in pairs(initNodeConfig) do
                local mode = getModeTag(k)

                self.ModelCfg[mode] = ModelCache[mode]
            end

            -- dump(self.CurModeItem, '解析本地配置')
            -- dump(self.ModelCfg)

            local mode = getModeTag(self.CurModeItem)
            for k, v in pairs(initNodeConfig[self.CurModeItem]) do
                self[v[1]] = self.ModelCfg[mode][k]
            end
        end
    else
        -- print(string.format('切换模式 %d -> %d.', self.CurModeItem, tar))

        -- 恢复目标模式 缓存
        self.ModelCfg = self.ModelCfg or {}

        -- 1、先缓存当前模式
        local mode = getModeTag(self.CurModeItem)

        self.ModelCfg[mode] = self.ModelCfg[mode] or {}
        local t = self.ModelCfg[mode]

        -- print(string.format('mode:%s cache to ===>', mode))
        for k, v in pairs(initNodeConfig[self.CurModeItem]) do
            t[k] = self[v[1]]
        end

        -- 2、恢复目标模式
        self.CurModeItem = tar
        mode = getModeTag(tar)
        t = self.ModelCfg[mode]

        -- print(string.format('mode:%s load  ===>', mode))
        for k, v in pairs(initNodeConfig[tar]) do
            self[v[1]] = t[k]
        end
    end

    self:initGameModeSelections()
    self:cfg2NodeEvent()
end

function PriRoomCreateLayer:writeToCache()
    self.ModelCfg['curMode'] = self.CurModeItem

    local getModeTag = function(m)
        local mode = ''
        if m == 1 then
            mode = 'csmj'
        elseif m == 2 then
            mode = 'tdh'
        end
        return mode
    end

    local t = self.ModelCfg[getModeTag(self.CurModeItem)]
    for k, v in pairs(initNodeConfig[self.CurModeItem]) do
        t[k] = self[v[1]]
    end

    self:writeJsonToFile('MajiangModel', self.ModelCfg)
end

function PriRoomCreateLayer:cfg2NodeEvent()
    -- 付费
    local tag = CBT_KOUFEI_BEGIN + self.ffSelected

    self:onSelectedEvent(tag, self.ffCheckbox[tag])

    -- 局数
    tag = CBT_JUSHU_BEGIN + self.jsSelected
    self:onSelectedEvent(tag, self.jsCheckbox[tag])

    -- 人数
    tag = CBT_RENSHU_BEGIN + self.rsSelected
    self:onSelectedEvent(tag, self.rsCheckbox[tag])

    -- 玩法 3:整副麻将 2:无万 1:无风
    self.wfOption = {0, 0}
    if self.wfSelected == 2 then
        self.wfOption[1] = 1
    elseif self.wfSelected == 1 then
        self.wfOption[2] = 1
    end

    for k, v in ipairs(self.wfOption) do
        if v == 1 then
            self.wfOption[k] = 0

            tag = CBT_WANFA_BEGIN + k
            self:onSelectedEvent(tag, self.wfCheckbox[tag])
        end
    end

    -- 牌型
    -- dump(self.pxSelected)
    for k, v in ipairs(self.pxSelected) do
        tag = CBT_PAIXING_BEGIN + k

        self.pxSelected[k] = 1 - v
        self:onSelectedEvent(tag, self.pxCheckbox[tag])
    end

    -- 鬼牌不处理

    -- 马牌

    if self.CurModeItem == 1 then
        tag = CBT_MAPAI_BEGIN + self.mpSelected[1]
        self:onSelectedEvent(tag, self.mpCheckbox[tag], true)

        if self.mpSelected[2] ~= 0 then
            tag = CBT_MAPAI_BEGIN + 4 + self.mpSelected[2]
            self:onSelectedEvent(tag, self.mpCheckbox[tag])
        end

        if self.mpSelected[3] == 1 then
            self.mpSelected[3] = 0

            tag = CBT_MAPAI_BEGIN + 4
            self:onSelectedEvent(tag, self.mpCheckbox[tag])
        end

        if self.mpSelected[4] == 1 then
            self.mpSelected[4] = 0
            tag = CBT_MAPAI_BEGIN + 8
            self:onSelectedEvent(tag, self.mpCheckbox[tag])
        end
    elseif self.CurModeItem == 2 then
        tag = CBT_MAPAI_BEGIN + self.mpSelected[1]
        self:onSelectedEvent(tag, self.mpCheckbox[tag])

        if self.mpSelected[3] == 1 then
            self.mpSelected[3] = 0

            tag = CBT_MAPAI_BEGIN + 5
            self:onSelectedEvent(tag, self.mpCheckbox[tag])
        end

        if self.mpSelected[4] == 1 then
            self.mpSelected[4] = 0
            tag = CBT_MAPAI_BEGIN + 6
            self:onSelectedEvent(tag, self.mpCheckbox[tag])
        end
    end
end

function PriRoomCreateLayer:onLoginPriRoomFinish()
    local round = {8, 16}
    local people = {2, 3, 4}
    -- 创建登陆
    local buffer = CCmd_Data:create(188)
    buffer:setcmdinfo(210, 1)
    buffer:pushscore(1)
    buffer:pushdword(round[self.jsSelected]) --局数
    buffer:pushdword(0)
    buffer:pushword(people[self.rsSelected]) --人数
    buffer:pushdword(0)
    buffer:pushstring('', yl.LEN_PASSWORD)

    --游戏额外规则
    --@1 : 是否设置规则
    buffer:pushbyte(1)
    --@1 : 游戏局数
    --@2 : 是否AA付费
    --@10：参与游戏人数
    --@49: 房间模式
    --@50: 是否房卡类型
    for i = 1, 99 do
        if i == 1 then
            buffer:pushbyte(round[self.jsSelected])
        elseif i == 2 then
            local ff = {0, 1}
            buffer:pushbyte(ff[self.ffSelected])
        elseif i == 10 then
            buffer:pushbyte(people[self.rsSelected]) --人数
            print('创建房间时发送的人数为:', people[self.rsSelected])
        elseif i == 48 then
            buffer:pushbyte(self.curCheat == true and 1 or 0) --是否开启防作弊模式
        elseif i == 49 then
            buffer:pushbyte(self.CurModeItem) -- 模式 1：潮汕麻将 2：推到胡
        elseif i == 50 then --是否房卡类型
            buffer:pushbyte(1)
        elseif i == 51 then
            buffer:pushbyte(self.wfSelected) --玩法 3:整副麻将 2:无万 1:无风

            if self.CurModeItem == 1 then
                -- '[可接炮胡]',               '[碰碰胡]',            '[七小对]',
                -- '[混一色]',                 '[清一色]',            '[豪华7对]',
                -- '[十三幺]',                 '[双豪华7对]',         '[三豪华7对]',
                -- '[小三元]',                 '[小四喜]',            '[大三元]',
                -- '[大四喜]',                 '[一九胡]',            '[字一色]',
                -- '[清一九]',                 '[十八罗汉]',          '[天地胡]',
                -- '[抢杠胡]',                 '[杠上开花]',
                for j = 1, 20 do --牌型
                    buffer:pushbyte(self.pxSelected[j])
                end
            else
                -- '[碰碰胡]',                    '[七小对]',                    '[一九胡]',
                -- '[清一九]',                    '[抢杠胡]',                    '[杠上开花]',
                for j = 1, 20 do
                    if j <= #self.pxSelected then
                        buffer:pushbyte(self.pxSelected[j])
                    else
                        buffer:pushbyte(0)
                    end
                end
            end
            self:GpSelected()
            buffer:pushbyte(self.gpSelected) --鬼牌         @72

            -- buffer:pushbyte(self.gpSelected[2]) --无鬼翻倍

            --潮汕麻将：@1:无马/买马/抓马        @2:买马时,马配置索引2马，4马，6马]     @3:是否马跟底分       @4:是否马跟杠
            --推到胡:  @1:无马/2马/4马/6马      @2空置        @3:马跟底分         @4:马跟杠
            for i = 1, 3 do
                buffer:pushbyte(self.mpSelected[i]) --马牌
                dump(self.mpSelected[i])
            end
        elseif i >= 52 and i <= 77 then
            -- i==51  已经处理
        else
            buffer:pushbyte(0)
        end
    end

    print(
        string.format(
            '开房:%d局 %d人 %s.',
            round[self.jsSelected],
            people[self.rsSelected],
            (self.ffSelected == 1 and '房主付费' or 'AA付费')
        )
    )
    PriRoom:getInstance():getNetFrame():sendGameServerMsg(buffer)
    PriRoom:getInstance():setChairCount(people[self.rsSelected])
    return true
end
function PriRoomCreateLayer:onRoomCreateSuccess()
    dump('PriRoomCreateLayer:onRoomCreateSuccess')
end

function PriRoomCreateLayer:getInviteShareMsg(roomDetailInfo)
    local shareTxt = '局数:' .. roomDetailInfo.dwPlayTurnCount
    local friendC = '广东麻将房间ID:' .. roomDetailInfo.szRoomID .. ' 局数:' .. roomDetailInfo.dwPlayTurnCount
    return {
        title = '【约战房间:' .. roomDetailInfo.szRoomID .. '】',
        content = shareTxt .. ' 广东麻将精彩刺激, 一起来玩吧! ',
        friendContent = friendC
    }
end

function PriRoomCreateLayer:onButtonClickedEvent(tag, sender, manual)
    if BTN_CLOSE == tag then
        -- 缓存配置
        self:dismiss()
    elseif BTN_CREATE == tag then
        local roomFee = self:getTabSelectConfig(self.jsSelected, self.ffSelected)
        if roomFee and roomFee.lFeeScore > GlobalUserItem.lRoomCard then
            local QueryDialog = appdf.req('app.views.layer.other.QueryDialog')
            local query =
                QueryDialog:create(
                '您的钻石余额不足，请充值后再游戏!',
                function(ok)
                    if ok == true then
                        --self:setVisible(false)
                        self._scene:onChangeShowMode(yl.SCENE_HOT_GAMELIST)
                        self:dismiss()
                    end
                    query = nil
                end,
                nil,
                QueryDialog.QUERY_SURE
            ):setCanTouchOutside(false):addTo(self)
        else
            PriRoom:getInstance():showPopWait()
            PriRoom:getInstance():getNetFrame():onCreateRoom()
        end
    elseif CBT_CHEAT_OPEN == tag then
        self.curCheat = not self.curCheat
    elseif CBT_MJITEM_BEGIN < tag and tag < CBT_KOUFEI_BEGIN then -- 潮汕麻将   推到胡
        if self.CurModeItem == tag - CBT_MJITEM_BEGIN and manual == false then
            return
        end

        sender:setEnabled(false)
        sender:stopAllActions()
        sender:runAction(cc.Sequence:create(cc.ScaleTo:create(0.1, 1.1, 1.1), cc.ScaleTo:create(0.1, 1, 1)))

        -- sender:getChildByName('Image_1'):setVisible(true)

        for k, v in pairs(self.GameModeItems) do
            if tag ~= k then
                v:setEnabled(true)
            -- v:getChildByName('Image_1'):setVisible(false)
            end
        end

        local di_porp_6 = appdf.getNodeByName(self, 'di_prop_6')
        local icon = di_porp_6:getChildByName('icon')
        if tag == 101 then
            icon:setVisible(true)
        elseif tag == 102 then
            icon:setVisible(false)
        end

        local next = tag - CBT_MJITEM_BEGIN
        print(next == 1 and '潮汕麻将' or '推到胡')
        self:recoveryFromCache(next)
        self.ruleView:jumpToTop()
    elseif CBT_GUIPAI_BEGIN == tag then
        self:GpSelected()
    end
end

-- 根据选择 获取房间付费配置
-- @round 选择的回合索引
-- @pay 选择的付费方式
function PriRoomCreateLayer:getTabSelectConfig(round, pay)
    -- 房间付费配置
    local FeeTbl = {
        {1, 1, '八局房 房主付费', 3},
        {1, 2, '八局房 AA付费', 1},
        {2, 1, '十六局房 房主付费', 6},
        {2, 2, '十六局房 AA付费', 2}
    }

    local idx
    for k, v in ipairs(FeeTbl) do
        if v[1] == round and v[2] == pay then
            idx = k
            break
        end
    end

    if idx then
        local cfgs = PriRoom:getInstance().m_tabFeeConfigList or {}
        if #cfgs == 0 then
            return {lFeeScore = FeeTbl[idx][4]}, FeeTbl[idx][3]
        else
            return cfgs[idx], FeeTbl[idx][3]
        end
    end
    assert(0, 'PriRoomCreateLayer:getTabSelectConfig failed.')
    return nil
end

function PriRoomCreateLayer:onSelectedEvent(tag, sender, manual)
    -- print('tag:' .. tag .. 'CBT_PAIXING_BEGIN:' .. CBT_PAIXING_BEGIN )
    -- local   CBT_KOUFEI_BEGIN        = 200   --扣费
    -- local   CBT_JUSHU_BEGIN         = 210   --局数
    -- local   CBT_RENSHU_BEGIN        = 220   --人数
    -- local   CBT_WANFA_BEGIN         = 230   --玩法
    -- local   CBT_PAIXING_BEGIN       = 240   --牌型
    -- local   CBT_GUIPAI_BEGIN        = 300   --鬼牌
    -- local   CBT_MAPAI_BEGIN         = 310   --马牌

    if tag > CBT_KOUFEI_BEGIN and tag < CBT_JUSHU_BEGIN then --扣费
        sender:setSelected(true)
        if self.ffSelected == tag - CBT_KOUFEI_BEGIN then
            return
        end

        self.ffSelected = tag - CBT_KOUFEI_BEGIN
        sender:getChildByName('Text_1'):setTextColor(cc.c4b(229, 68, 43, 255))

        for k, v in pairs(self.ffCheckbox) do
            if k ~= tag and k > CBT_KOUFEI_BEGIN and k < CBT_JUSHU_BEGIN then
                v:setSelected(false)
                v:getChildByName('Text_1'):setTextColor(cc.c4b(106, 69, 50, 255))
            end
        end
        print(tag == CBT_KOUFEI_BEGIN + 1 and '房主扣费' or 'AA付费')

        -- 影响价格
        for i = 1, 2 do
            -- 局数索引 + 付费索引
            local fee = self:getTabSelectConfig(i, self.ffSelected)

            self.jsFeeText[i].node:setString(string.format(self.jsFeeText[i].text, fee.lFeeScore))
        end
    elseif tag > CBT_JUSHU_BEGIN and tag < CBT_RENSHU_BEGIN then --局数
        sender:setSelected(true)
        if self.jsSelected == tag - CBT_JUSHU_BEGIN then
            return
        end

        self.jsSelected = tag - CBT_JUSHU_BEGIN
        sender:getChildByName('Text_1'):setTextColor(cc.c4b(229, 68, 43, 255))

        for k, v in pairs(self.jsCheckbox) do
            if k ~= tag and k > CBT_JUSHU_BEGIN and k < CBT_RENSHU_BEGIN then
                v:setSelected(false)
                v:getChildByName('Text_1'):setTextColor(cc.c4b(106, 69, 50, 255))
            end
        end
        print(tag == CBT_JUSHU_BEGIN + 1 and '8局' or '16局')
    elseif tag > CBT_RENSHU_BEGIN and tag < CBT_WANFA_BEGIN then --人数
        sender:setSelected(true)
        if self.rsSelected == tag - CBT_RENSHU_BEGIN then
            return
        end

        self.rsSelected = tag - CBT_RENSHU_BEGIN
        sender:getChildByName('Text_1'):setTextColor(cc.c4b(229, 68, 43, 255))

        for k, v in pairs(self.rsCheckbox) do
            if k ~= tag and k > CBT_RENSHU_BEGIN and k < CBT_WANFA_BEGIN then
                v:setSelected(false)
                v:getChildByName('Text_1'):setTextColor(cc.c4b(106, 69, 50, 255))
            end
        end

        local people = {
            '2人',
            '3人',
            '4人'
        }
        print('人数:' .. people[self.rsSelected])
    elseif tag > CBT_WANFA_BEGIN and tag < CBT_PAIXING_BEGIN then --玩法
        if self.wfOption[tag - CBT_WANFA_BEGIN] == 0 then
            -- 此项没被选中
            self.wfOption[tag - CBT_WANFA_BEGIN] = 1
            sender:setSelected(true)
            sender:getChildByName('Text_1'):setTextColor(cc.c4b(229, 68, 43, 255))

            -- 设置其他选项 非选中
            for k, v in pairs(self.wfCheckbox) do
                if k ~= tag and k > CBT_WANFA_BEGIN and k < CBT_PAIXING_BEGIN then
                    v:setSelected(false)
                    v:getChildByName('Text_1'):setTextColor(cc.c4b(106, 69, 50, 255))

                    self.wfOption[k - CBT_WANFA_BEGIN] = 0
                end
            end
        else
            self.wfOption[tag - CBT_WANFA_BEGIN] = 0
            sender:setSelected(false)
            sender:getChildByName('Text_1'):setTextColor(cc.c4b(106, 69, 50, 255))
        end

        if self.wfOption[1] == 1 then
            print('无万牌')
            self.wfSelected = 2
        elseif self.wfOption[2] == 1 then
            print('无风牌')
            self.wfSelected = 1
        else
            print('整副牌')
            self.wfSelected = 3
        end

        -- 关联牌型
        if self.CurModeItem == 1 then
            local glpx = {
                {7},
                {7, 10, 11, 12, 13, 15},
                {10, 11, 12, 13, 15}
                --用于修复选择无风牌后再选择无万牌出现的BUG
            }

            if tag == CBT_WANFA_BEGIN + 1 then
                --无万
                local enable = (self.wfOption[1] == 0 and true or false)

                for i = 1, #glpx[1] do
                    local idx = glpx[1][i]
                    self.pxSelected[idx] = (enable and 1 or 0)

                    self.pxCheckbox[CBT_PAIXING_BEGIN + idx]:setSelected(enable)
                    self.pxCheckbox[CBT_PAIXING_BEGIN + idx]:setEnabled(enable)

                    if enable then
                        self.pxCheckbox[CBT_PAIXING_BEGIN + idx]:getChildByName('Text_1'):setTextColor(
                            cc.c4b(229, 68, 43, 255)
                        )
                    else
                        self.pxCheckbox[CBT_PAIXING_BEGIN + idx]:getChildByName('Text_1'):setTextColor(
                            cc.c4b(106, 69, 50, 255)
                        )
                    end
                end
                for i = 1, #glpx[3] do --修复选择无风牌后再选择无万牌出现的BUG
                    local idx = glpx[3][i]
                    self.pxSelected[idx] = 1

                    self.pxCheckbox[CBT_PAIXING_BEGIN + idx]:setSelected(true)
                    self.pxCheckbox[CBT_PAIXING_BEGIN + idx]:setEnabled(true)

                    self.pxCheckbox[CBT_PAIXING_BEGIN + idx]:getChildByName('Text_1'):setTextColor(
                        cc.c4b(229, 68, 43, 255)
                    )
                end
            elseif tag == CBT_WANFA_BEGIN + 2 then
                --无风
                local enable = (self.wfOption[2] == 0 and true or false)

                for i = 1, #glpx[2] do
                    local idx = glpx[2][i]
                    self.pxSelected[idx] = (enable and 1 or 0)

                    self.pxCheckbox[CBT_PAIXING_BEGIN + idx]:setSelected(enable)
                    self.pxCheckbox[CBT_PAIXING_BEGIN + idx]:setEnabled(enable)

                    if enable then
                        self.pxCheckbox[CBT_PAIXING_BEGIN + idx]:getChildByName('Text_1'):setTextColor(
                            cc.c4b(229, 68, 43, 255)
                        )
                    else
                        self.pxCheckbox[CBT_PAIXING_BEGIN + idx]:getChildByName('Text_1'):setTextColor(
                            cc.c4b(106, 69, 50, 255)
                        )
                    end
                end
            end
        end
    elseif tag > CBT_PAIXING_BEGIN and tag < CBT_GUIPAI_BEGIN then --牌型
        --[[
        local px
        local pxString = '选中牌型:'

        if self.CurModeItem == 1 then
            px = {
                '[可接炮胡]',               '[碰碰胡]',            '[七小对]',
                '[混一色]',                 '[清一色]',            '[豪华7对]',
                '[十三幺]',                 '[双豪华7对]',         '[三豪华7对]',
                '[小三元]',                 '[小四喜]',            '[大三元]',
                '[大四喜]',                 '[一九胡]',            '[字一色]',
                '[清一九]',                 '[十八罗汉]',          '[天地胡]',
                '[抢杠胡]',                 '[杠上开花]',
            }

            for i=1,20 do
                if self.pxSelected[i] == 1 then
                    pxString = pxString .. px[i]
                end
            end
        elseif self.CurModeItem == 2 then
            px = {
                '[碰碰胡]',                    '[七小对]',                    '[一九胡]',
                '[清一九]',                    '[抢杠胡]',                    '[杠上开花]',
            }

            for i=1,6 do
                if self.pxSelected[i] == 1 then
                    pxString = pxString .. px[i]
                end
            end
        end
        print(pxString)
    ]]
        --[[elseif tag > CBT_GUIPAI_BEGIN and tag < CBT_MAPAI_BEGIN then        --鬼牌
        if self.CurModeItem == 1 then
            if self.gpSelected[1] == tag - CBT_GUIPAI_BEGIN then
                sender:setSelected(true)
                return
            end

            self.gpSelected[1] = tag - CBT_GUIPAI_BEGIN

            sender:setSelected(true)
            sender:getChildByName('Text_1'):setTextColor(cc.c4b(229, 68, 43, 255))

            for k,v in pairs(self.gpCheckbox) do
                if k ~= tag and k > CBT_GUIPAI_BEGIN and k < CBT_MAPAI_BEGIN then
                    v:setSelected(false)
                    v:getChildByName('Text_1'):setTextColor(cc.c4b(106, 69, 50, 255))
                end
            end

            
            local gui = 
            {
                '无鬼', '白板做鬼', '翻鬼'
            }
            print('鬼牌:' .. gui[self.gpSelected[1] ])
        elseif self.CurModeItem == 2 then
            if tag - CBT_GUIPAI_BEGIN > 0 and tag - CBT_GUIPAI_BEGIN < 5 then
                if self.gpSelected[1] == tag - CBT_GUIPAI_BEGIN then
                    sender:setSelected(true)
                    return
                end

                self.gpSelected[1] = tag - CBT_GUIPAI_BEGIN

                sender:setSelected(true)
                sender:getChildByName('Text_1'):setTextColor(cc.c4b(229, 68, 43, 255))

                for k,v in pairs(self.gpCheckbox) do
                    if k ~= tag and k > CBT_GUIPAI_BEGIN and k < CBT_GUIPAI_BEGIN + 5 then
                        v:setSelected(false)
                        v:getChildByName('Text_1'):setTextColor(cc.c4b(106, 69, 50, 255))
                    end
                end

                if self.gpSelected[1] == 1 then
                    self.gpCheckbox[CBT_GUIPAI_BEGIN + 5]:setSelected(false)
                    self.gpCheckbox[CBT_GUIPAI_BEGIN + 5]:setEnabled(false)
                    self.gpCheckbox[CBT_GUIPAI_BEGIN + 5]:getChildByName('Text_1'):setTextColor(cc.c4b(106, 69, 50, 255))
                    self.gpSelected[2] = 0
                else
                    self.gpCheckbox[CBT_GUIPAI_BEGIN + 5]:setEnabled(true)
                end
            elseif tag - CBT_GUIPAI_BEGIN == 5 then
                self.gpSelected[2] = 1 - self.gpSelected[2]

                if self.gpSelected[2] == 1  then
                    sender:setSelected(true)
                    sender:getChildByName('Text_1'):setTextColor(cc.c4b(229, 68, 43, 255))
                else 
                    sender:setSelected(false)
                    sender:getChildByName('Text_1'):setTextColor(cc.c4b(106, 69, 50, 255))
                end
            end
            
            local gui = 
            {
                '无鬼', '白板做鬼', '翻鬼', '双鬼', 
            }
            print('鬼牌:' .. gui[self.gpSelected[1] ] .. '     翻倍:' .. (self.gpSelected[2] == 1 and '无鬼翻倍' or '空'))
        end
    -- ]]
        if self.pxSelected[tag - CBT_PAIXING_BEGIN] == 0 then
            self.pxSelected[tag - CBT_PAIXING_BEGIN] = 1
            sender:setSelected(true)
            sender:getChildByName('Text_1'):setTextColor(cc.c4b(229, 68, 43, 255))
        else
            self.pxSelected[tag - CBT_PAIXING_BEGIN] = 0
            sender:setSelected(false)
            sender:getChildByName('Text_1'):setTextColor(cc.c4b(106, 69, 50, 255))
        end
    elseif tag > CBT_MAPAI_BEGIN and tag < CBT_MAX then --马牌
        if self.CurModeItem == 1 then
            if tag == CBT_MAPAI_BEGIN + 1 or tag == CBT_MAPAI_BEGIN + 3 then
                -- 无马 / 抓马
                self.mpSelected[1] = tag - CBT_MAPAI_BEGIN
                self.mpSelected[2] = 0
                self.mpSelected[3] = 0
                self.mpSelected[4] = 0

                sender:setSelected(true)
                sender:getChildByName('Text_1'):setTextColor(cc.c4b(229, 68, 43, 255))

                for i = 1, 3 do
                    if i ~= tag - CBT_MAPAI_BEGIN then
                        self.mpCheckbox[CBT_MAPAI_BEGIN + i]:setSelected(false)
                        self.mpCheckbox[CBT_MAPAI_BEGIN + i]:getChildByName('Text_1'):setTextColor(
                            cc.c4b(106, 69, 50, 255)
                        )
                    end
                end

                for i = 4, 8 do
                    self.mpCheckbox[CBT_MAPAI_BEGIN + i]:setSelected(false)
                    self.mpCheckbox[CBT_MAPAI_BEGIN + i]:setEnabled(false)
                    self.mpCheckbox[CBT_MAPAI_BEGIN + i]:getChildByName('Text_1'):setTextColor(cc.c4b(106, 69, 50, 255))
                end
            elseif tag == CBT_MAPAI_BEGIN + 2 then -- 买马
                self.mpSelected[1] = 2

                if not manual then
                    self.mpSelected[2] = 1
                end

                sender:setSelected(true)
                sender:getChildByName('Text_1'):setTextColor(cc.c4b(229, 68, 43, 255))

                for i = 1, 3 do
                    if i ~= tag - CBT_MAPAI_BEGIN then
                        self.mpCheckbox[CBT_MAPAI_BEGIN + i]:setSelected(false)
                        self.mpCheckbox[CBT_MAPAI_BEGIN + i]:getChildByName('Text_1'):setTextColor(
                            cc.c4b(106, 69, 50, 255)
                        )
                    end
                end

                for i = 4, 8 do
                    self.mpCheckbox[CBT_MAPAI_BEGIN + i]:setSelected(false)
                    self.mpCheckbox[CBT_MAPAI_BEGIN + i]:setEnabled(true)
                    self.mpCheckbox[CBT_MAPAI_BEGIN + i]:getChildByName('Text_1'):setTextColor(cc.c4b(106, 69, 50, 255))
                end

                self.mpCheckbox[CBT_MAPAI_BEGIN + 5]:setSelected(true)
                self.mpCheckbox[CBT_MAPAI_BEGIN + 5]:getChildByName('Text_1'):setTextColor(cc.c4b(229, 68, 43, 255))
            elseif tag == CBT_MAPAI_BEGIN + 4 then
                self.mpSelected[3] = 1 - self.mpSelected[3]

                if self.mpSelected[3] == 1 then
                    sender:setEnabled(true)
                    sender:setSelected(true)
                    sender:getChildByName('Text_1'):setTextColor(cc.c4b(229, 68, 43, 255))
                else
                    --sender:setEnabled(false)
                    sender:setSelected(false)
                    sender:getChildByName('Text_1'):setTextColor(cc.c4b(106, 69, 50, 255))
                end
            elseif tag == CBT_MAPAI_BEGIN + 8 then
                self.mpSelected[4] = 1 - self.mpSelected[4]

                if self.mpSelected[4] == 1 then
                    sender:setEnabled(true)
                    sender:setSelected(true)
                    sender:getChildByName('Text_1'):setTextColor(cc.c4b(229, 68, 43, 255))
                else
                    --sender:setEnabled(false)
                    sender:setSelected(false)
                    sender:getChildByName('Text_1'):setTextColor(cc.c4b(106, 69, 50, 255))
                end
            else
                self.mpSelected[2] = tag - CBT_MAPAI_BEGIN - 4

                sender:setSelected(true)
                sender:getChildByName('Text_1'):setTextColor(cc.c4b(229, 68, 43, 255))

                for k, v in pairs(self.mpCheckbox) do
                    if k ~= tag and k > CBT_MAPAI_BEGIN + 4 and k < CBT_MAPAI_BEGIN + 8 then
                        v:setSelected(false)
                        v:getChildByName('Text_1'):setTextColor(cc.c4b(106, 69, 50, 255))
                    end
                end
            end

            local mapai = {
                {'无马', '买马', '抓马'},
                {'买2马', '买4马', '买6马'},
                '马跟底分',
                '马跟杠'
            }

            local str =
                string.format(
                '马牌:%s [%s] [%s] [%s]',
                mapai[1][self.mpSelected[1]],
                self.mpSelected[2] == 0 and '空' or mapai[2][self.mpSelected[2]],
                self.mpSelected[3] == 1 and mapai[3] or '空1',
                self.mpSelected[4] == 1 and mapai[4] or '空2'
            )
            print(str)
        else
            if tag > CBT_MAPAI_BEGIN and tag < CBT_MAPAI_BEGIN + 5 then
                --[[                 for i = 1, 3 do
                    if i ~= tag - CBT_MAPAI_BEGIN then
                        self.mpCheckbox[CBT_MAPAI_BEGIN + i]:setSelected(false)
                        self.mpCheckbox[CBT_MAPAI_BEGIN + i]:getChildByName('Text_1'):setTextColor(cc.c4b(106, 69, 50, 255))
                    end
                end

                for i=4, 8 do
                    self.mpCheckbox[CBT_MAPAI_BEGIN + i]:setSelected(false)
                    self.mpCheckbox[CBT_MAPAI_BEGIN + i]:setEnabled(false)
                    self.mpCheckbox[CBT_MAPAI_BEGIN + i]:getChildByName('Text_1'):setTextColor(cc.c4b(106, 69, 50, 255))
                end ]]
                print('xxxxxxxx马牌xxxx1')
                if self.mpSelected[1] == tag - CBT_MAPAI_BEGIN then
                    sender:setSelected(true)
                    print('xxxxxxxx///////\\\\\\///')
                    return
                end
                print('xxxxxxxx///////')
                self.mpSelected[1] = tag - CBT_MAPAI_BEGIN
                sender:setSelected(true)
                sender:getChildByName('Text_1'):setTextColor(cc.c4b(229, 68, 43, 255))

                for k, v in pairs(self.mpCheckbox) do
                    if k ~= tag and k > CBT_MAPAI_BEGIN and k < CBT_MAPAI_BEGIN + 5 then
                        v:setSelected(false)
                        v:getChildByName('Text_1'):setTextColor(cc.c4b(106, 69, 50, 255))
                    end
                end

                -- 买x马
                if tag == CBT_MAPAI_BEGIN + 1 then
                    print('xxxxxx1')
                    self.mpCheckbox[CBT_MAPAI_BEGIN + 5]:setSelected(false)
                    self.mpCheckbox[CBT_MAPAI_BEGIN + 5]:setEnabled(false)
                    self.mpCheckbox[CBT_MAPAI_BEGIN + 5]:getChildByName('Text_1'):setTextColor(cc.c4b(106, 69, 50, 255))

                    self.mpCheckbox[CBT_MAPAI_BEGIN + 6]:setSelected(false)
                    self.mpCheckbox[CBT_MAPAI_BEGIN + 6]:setEnabled(false)
                    self.mpCheckbox[CBT_MAPAI_BEGIN + 6]:getChildByName('Text_1'):setTextColor(cc.c4b(106, 69, 50, 255))

                    self.mpSelected[3] = 0
                    self.mpSelected[4] = 0
                elseif tag < CBT_MAPAI_BEGIN + 5 then
                    print('xxxxxx2', tag)
                    self.mpCheckbox[CBT_MAPAI_BEGIN + 5]:setEnabled(true)
                    self.mpCheckbox[CBT_MAPAI_BEGIN + 6]:setEnabled(true)
                end
            elseif tag == CBT_MAPAI_BEGIN + 5 then
                print('xxxxxxxx马牌xxxx2')
                -- 马跟底分
                self.mpSelected[3] = 1 - self.mpSelected[3]

                if self.mpSelected[3] == 1 then
                    sender:setEnabled(true)
                    sender:setSelected(true)
                    sender:getChildByName('Text_1'):setTextColor(cc.c4b(229, 68, 43, 255))
                else
                    --sender:setEnabled(false)
                    sender:setSelected(false)
                    sender:getChildByName('Text_1'):setTextColor(cc.c4b(106, 69, 50, 255))
                end
            elseif tag == CBT_MAPAI_BEGIN + 6 then
                print('xxxxxxxx马牌xxxx3')
                -- 马跟杠
                self.mpSelected[4] = 1 - self.mpSelected[4]

                if self.mpSelected[4] == 1 then
                    sender:setEnabled(true)
                    sender:setSelected(true)
                    sender:getChildByName('Text_1'):setTextColor(cc.c4b(229, 68, 43, 255))
                else
                    --sender:setEnabled(false)
                    sender:setSelected(false)
                    sender:getChildByName('Text_1'):setTextColor(cc.c4b(106, 69, 50, 255))
                end
            end

            local mapai = {
                {'无马', '买2马', '买4马', '买6马'},
                '',
                '马跟底分',
                '马跟杠'
            }

            local str =
                string.format(
                '马牌:%s [%s] [%s]',
                mapai[1][self.mpSelected[1]],
                self.mpSelected[3] == 1 and mapai[3] or '空1',
                self.mpSelected[4] == 1 and mapai[4] or '空2'
            )
            print(str)
        end
    end
end

function PriRoomCreateLayer:loadJsonFile(filename)
    local fullPath = string.format('%s\\cmodeconfig\\%s', device.writablePath, filename)
    local fileUtils = cc.FileUtils:getInstance()

    if true == fileUtils:isFileExist(fullPath) then
        local data = fileUtils:getStringFromFile(fullPath)

        if data == '' then
            return nil
        end

        data = json.decode(data)
        return data
    else
        local fullPath = string.format('%s\\cmodeconfig', device.writablePath)

        if false == cc.FileUtils:getInstance():isDirectoryExist(fullPath) then
            cc.FileUtils:getInstance():createDirectory(fullPath)
        end
    end

    return nil
end

-- @param fileName -> 文件名
-- @param data -> table
function PriRoomCreateLayer:writeJsonToFile(fileName, data)
    local fileUtils = cc.FileUtils:getInstance()

    local fullPath = string.format('%s\\cmodeconfig\\%s', device.writablePath, fileName)
    data = json.encode(data)
    fileUtils:writeStringToFile(data, fullPath)
end

function PriRoomCreateLayer:dismiss(cb)
    self:runAction(
        cc.Sequence:create(
            cc.FadeOut:create(0),
            cc.CallFunc:create(
                function()
                    -- 缓存配置
                    self:writeToCache()
                    self:setTouchEnabled(false)
                    -- self:setVisible(false)
                    self:removeSelf()
                end
            )
        )
    )
end

function PriRoomCreateLayer:show(cb)
    self.m_csbNode:stopAllActions()
    self:setVisible(true)
    self:runAction(cc.Sequence:create(cc.FadeTo:create(0.3, 200)))

    self.m_csbNode:runAction(
        cc.Sequence:create(
            cc.MoveTo:create(0.25, cc.p(0, 0)),
            cc.CallFunc:create(
                function()
                    self:setTouchEnabled(true)
                    if cb then
                        cb()
                    end
                end
            )
        )
    )
end

return PriRoomCreateLayer
