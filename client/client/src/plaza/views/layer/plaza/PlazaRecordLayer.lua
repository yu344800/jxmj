local PlazaRecordLayer = class("PlazaRecordLayer", function(scene)
    local PlazaRecordLayer = cc.LayerColor:create(cc.c4b(0,0,0,0))
    return PlazaRecordLayer
end)
local RecordFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.RecordFrame")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. 'ExternalFun')

local fileUtils = cc.FileUtils:getInstance()

local initTable = function()
    local m_tb = {}
    local insert = table.insert
    local tag = 0

    local push = function(v) insert(m_tb, v) end

    local getItemByIdx = function(idx) return m_tb[idx] or nil end

    local getList = function() return m_tb or nil end
        
    local clean = function() m_tb = {} end

    local setTag = function(v) tag = v end

    local getTag = function() return tag end

    return push, getItemByIdx, getList, clean, setTag, getTag
end

PlazaRecordLayer.WIDGET_TAG = {}
local WIDGET_TAG = PlazaRecordLayer.WIDGET_TAG

function PlazaRecordLayer:onEnterTransitionFinish()
    return self
end

function PlazaRecordLayer:onScoketCallBack(key, data)
    if key == 411 then
        data.RecordID = tostring(data.RecordID)
        self.m_tableRecordInfo[data.RecordID] = {}
        self.m_tableRecordInfo[data.RecordID] = data.gameRoundRecord

        for k,v in ipairs(data.gameRoundRecord) do
            self.pushRound_(v)
        end
        
        -- 更新
        local view = appdf.getNodeByName(self, "content_TableView")
                    :updateView()

    elseif key == 413 then
        self:saveRoundInfo(data)
        self._scene:dismissPopWait()
        
        self:startPlayBack(self.getRoundRecordId_(), data.RoundID)
    elseif key == 0 then
        if GlobalUserItem.GameRecordInfo ~= nil and GlobalUserItem.GameRecordInfo.RecordId ~= nil then
            self._scene:showPopWait()
            showToast(self, "正在加载战绩请稍候...", 99)
            self.m_frame:sendQueryRoundResult(GlobalUserItem.GameRecordInfo.RecordId, GlobalUserItem.GameRecordInfo.RoundId)
            GlobalUserItem.GameRecordInfo = nil
        end
    elseif key == -1 then
        self.m_frame:onConnect()
    end
end

-- 检测房间战绩单局储存上限
function PlazaRecordLayer:initRecordCache()
    self.m_tableRecordInfo = {}

    local allDataFile = string.format("%s\\recordfile", device.writablePath)

    if cc.FileUtils:getInstance():isDirectoryExist(allDataFile) == false then
        cc.FileUtils:getInstance():createDirectory(allDataFile)
        return
    end

    local file = string.format("%s\\recordfile\\%s_RecordCache.json", device.writablePath, self._kindId)
    -- 获取缓存
    if cc.FileUtils:getInstance():isFileExist(file) then
        local oldfile = cc.FileUtils:getInstance():getStringFromFile(file)
        local ok, datatable = pcall(function()
            return cjson.decode(oldfile)
        end)

        if ok and type(datatable) == "table" then
            -- 文件缓存上限判断
            if #datatable > 30 then
                cc.FileUtils:getInstance():removeFile(allDataFile)

                cc.FileUtils:getInstance():createDirectory(allDataFile)
            else
                self.m_tableRecordInfo = datatable
            end
        end
    end
end

-- 储存战绩所有局数
function PlazaRecordLayer:saveRecordInfoToFile()
    local fullPath = string.format("%s\\recordfile\\%s_RecordCache.json", device.writablePath, self._kindId)
    local encodeData = json.encode(self.m_tableRecordInfo)
    fileUtils:writeStringToFile(encodeData, fullPath)
end

-- 储存单局回放
function PlazaRecordLayer:saveRoundInfo(data)
    local fullPath = string.format("%s\\recordfile\\%d_%d", device.writablePath, self.getRoundRecordId_(), data.RoundID)
    local encodeData = json.encode(data)
    fileUtils:writeStringToFile(encodeData, fullPath)
end

-- 获取单条战绩所有局数
function PlazaRecordLayer:getRecordInfoToCache(RecordID)
    local s = tostring(RecordID)
    local v = self.m_tableRecordInfo[s]
    return v == nil and nil or v
end

-- 获取单局回放
function PlazaRecordLayer:getRoundInfoToFile(recordId, roundId)
    local fullPath = string.format("%s\\recordfile\\%d_%d", device.writablePath, recordId, roundId)
    if true == fileUtils:isFileExist(fullPath) then
        return true
    end
    return nil
end

function PlazaRecordLayer:onExitTransitionStart()
    self:saveRecordInfoToFile()
    if self.m_frame then
        self.m_frame:onCloseSocket()
    end
    return self
end

function PlazaRecordLayer:ctor(scene, gameList)
    appdf.registerNodeEvent(self)
    appdf.registerTouchOutsideHandler(self, false, "main", false)

    local csbNode = cc.CSLoader:createNode("record/PlazaRecordLayer.csb")
                    :addTo(self)
                    :move(0,- 40)

    appdf.setNodeTagAndListener(csbNode, "btn_close", "BT_CLOSE", handler(self, self.onButtonClickedEvent))

    self.layer_main = csbNode
    self._scene = scene
    self.m_gameList = gameList
    self:setName("PlazaRecordLayer")
    -- 游戏战绩选择标识
    self.m_selectLeftItemTag = 2
    -- 内容选择标识
    self.m_selectContentTag = 1
    -- 游戏标识
    self._kindId = 602

    self:initContentTableView(csbNode)

    self.pushRecord_, self.getRecordInfo_, self.getRecordList_, self.resetRecordList_ = initTable()
    self.pushRound_, self.getRoundInfo_, self.getRoundList_, self.resetRoundList_, self.setRoundRecordId_, self.getRoundRecordId_ = initTable()

    appdf.setNodeTagAndListener(csbNode, "item_1", "BT_ITEM_1", handler(self, self.onButtonClickedEvent))
                :setCallbackType("jy")
    appdf.setNodeTagAndListener(csbNode, "item_2", "BT_ITEM_2", handler(self, self.onButtonClickedEvent))
                :setCallbackType("sr")
    appdf.setNodeTagAndListener(csbNode, "item_3", "BT_ITEM_3", handler(self, self.onButtonClickedEvent))
                :setCallbackType("none")

end

function PlazaRecordLayer:initContentTableView(csbNode)
    
    local item = appdf.getNodeByName(self, "clone_item")

    local m_tableview = ccui.UITableView:create({
        viewRect = cc.rect(667, 358, 970, 500),
        direction = cc.SCROLLVIEW_DIRECTION_VERTICAL,
        fill = cc.TABLEVIEW_FILL_TOPDOWN,
        interval = 8,
        createCell = handler(self, self.contentCreateCell),
        getCellCount = handler(self, self.contentGetCellsCount),
        getCellSize = nil,
    })
            :addTo(csbNode)
            :setName("content_TableView")
            :setCloneCellItem(item)
            :setUltraBottomDistanceRefresh(true)
            :setUltraBottomDistance(140)
            :setUltraBottomCallBack(function(updateView)

                
                

                updateView()
            end)
            -- :setScrollingCallBack(function()
            --     self.m_isStopScroll = true
            -- end)
            -- :setScrollEndCallBack(function()
            --     self.m_isStopScroll = false
            -- end)
            :setTableViewTouchEnabled(false)
            :setTopBounceEnable(true)
            -- :setBottomBounceEnable(true)
            :initScrollHanlder()
            -- :updateView()
end

function PlazaRecordLayer:contentGetCellsCount(view)
    if self.m_selectContentTag == 1 then
        return #self.getRecordList_()
    end
    return #self.getRoundList_()
end

function PlazaRecordLayer:contentCreateCell(view, item, idx)
    local showFuc = function ()
        item:setVisible(true)
    end

    if item:getPositionX() ~= 480 then
        item:stopAllActions()

        item:setAnchorPoint(0.5, 0.5)
        item:setPosition(480, -20)
    
        item:runAction(
            cc.Sequence:create(
                cc.DelayTime:create(0.2 * idx),
                cc.CallFunc:create(showFuc),
                cc.Spawn:create(
                    cc.MoveTo:create(0.3, cc.p(480, 50)),
                    cc.FadeTo:create(0.3, 255)
                )
            )
        )
    elseif item:isVisible() == false then
        item:setAnchorPoint(0.5, 0.5)
        item:setOpacity(255)
        item:setPosition(480, 50)
        showFuc()
    else
        item:setPosition(480, 50)
        item:setOpacity(255)
    end


    -- 房间
    if self.m_selectContentTag == 1 then
        local v = self.getRecordInfo_(idx)
        self:loadGameRoomRecordList(item, v, idx)
    else
        local v = self.getRoundInfo_(idx)
        -- 局数
        self:loadGameRoundRecordList(item, v, idx)
    end
end

function PlazaRecordLayer:onContentItemClickListener(tag, v)
    local view = appdf.getNodeByName(self, "content_TableView")
    
    -- 保存偏移值
    self.m_lastContentOffset = view:getTableView():getContentOffset()
    
    local mData = self.getRecordList_()

    self.resetRoundList_()
   
    local id = mData[tag].RecordID
    dump(id)
    -- 设置单局所有数据
    local recordInfo = self:getRecordInfoToCache(id)

    if recordInfo == nil then
        -- 查询数据
        self.m_frame:sendQueryRoundRecord(id)
    else
        for k,v in ipairs(recordInfo) do
            if v.dwRoundID ~= 0 then
                self.pushRound_(v)
            end
        end
    end

    self.setRoundRecordId_(id)

    self.m_selectContentTag = 2
    view:updateView()

end

-- 加载战绩列表
function PlazaRecordLayer:loadGameRoomRecordList(item, v, idx)
    local tmp = string.format("房间号:%s", v.RoomID)
    local roomInfo = appdf.getNodeByName(item, "roomInfo")
                :setString(tmp)

    tmp = v.CreateTime
    local timeInfo = appdf.getNodeByName(item, "timeInfo")
                :setString(tmp)

    tmp = string.format("局数:%d", type(v.TotalRoundCount) == "number" and v.TotalRoundCount or 0)
    local gameCount = appdf.getNodeByName(item, "gameCount")
                :setString(tmp)

    for k,v in ipairs(v.PlayerData) do
        if v.Name ~= "" then
            local userStr = string.format("user_%d", k)
            local nameStr = ExternalFun.GetShortString(v.Name,18)
            local userName = appdf.getNodeByName(item, userStr)
                            :setString(nameStr)

            if v.Userid == GlobalUserItem.dwUserID then
                userName:setTextColor(cc.c3b(171,77,41))
                -- userName:setTextColor(cc.c3b(15,150,179))
            else
                userName:setTextColor(cc.c3b(38,36,35))
            end
            
            userStr = string.format("user_%d_score", k)
            userName = appdf.getNodeByName(item, userStr)
                        :setString(v.Score)

            if v.Score > 0 then
                userName:setTextColor(cc.c3b(238,0,0))
            else
                userName:setTextColor(cc.c3b(21,169,38))
            end
        end
    end

    local view = appdf.setNodeTagAndListener(item, "share_info", idx, handler(self, self.onShareRecordListener))
                :setVisible(false)

    local view = appdf.setNodeTagAndListener(item, "show_info", idx, handler(self, self.onContentItemClickListener))
                :ignoreContentAdaptWithSize(true)
                :loadTexture("record/zj_bt_2.png")

    -- 没有战绩不让查看
    if type(v.RecordID) ~= "number" then
        view:setVisible(false)
    else
        view:setVisible(true)
    end
end

-- 加载局数列表
function PlazaRecordLayer:loadGameRoundRecordList(item, v, idx)
    local tmp = string.format("当前局数:%s", v.dwRoundID)
    local roomInfo = appdf.getNodeByName(item, "roomInfo")
                :setString(tmp)

    local timeInfo = appdf.getNodeByName(item, "timeInfo")
                :setString("")

    local gameCount = appdf.getNodeByName(item, "gameCount")
                :setString("")

    local v = v.gameRoundPersonalRecord[1]
    
    for m,n in ipairs(v) do
        if m <= 4 and n.kNickName ~= "" then
            local userStr = string.format("user_%d", m)
            local userNameStr = ExternalFun.GetShortString(n.kNickName,18)
            local userName = appdf.getNodeByName(item, userStr)
                            :setString(userNameStr)

            if n.dwUserID == GlobalUserItem.dwUserID then
                userName:setTextColor(cc.c3b(171,77,41))
                -- userName:setTextColor(cc.c3b(15,150,179))
            else
                userName:setTextColor(cc.c3b(38,36,35))
            end
            
            userStr = string.format("user_%d_score", m)
            userName = appdf.getNodeByName(item, userStr)
                        :setString(n.lScore)

            if n.lScore > 0 then
                userName:setTextColor(cc.c3b(238,0,0))
            else
                userName:setTextColor(cc.c3b(21,169,38))
            end

        end
    end

    local view = appdf.setNodeTagAndListener(item, "show_info", idx, handler(self, self.onPlayBackListener))
                :ignoreContentAdaptWithSize(true)
                :loadTexture("record/zj_bt_1.png")
                :setVisible(true)
                :setScale(1)

    local view = appdf.setNodeTagAndListener(item, "share_info", idx, handler(self, self.onShareRecordListener))
                :setVisible(true)
                :setScale(1)
                
end

-- 获取游戏战绩列表
function PlazaRecordLayer:getHttpListByKind()
    self._scene:showPopWait()

    local url = yl.HTTP_URL .. "/WS/MobileInterface.ashx"
    local action = string.format("action=GetRecordRoomList&dwUserID=%s&dwKind=%s&wpage=0", GlobalUserItem.dwUserID, self._kindId)

    appdf.onHttpJsionTable(url ,"GET", action, function(sjstable,sjsdata)
        local view = appdf.getNodeByName(self, "content_TableView")
        view:setTableViewTouchEnabled(false)

        self.resetRecordList_()
        
        if sjstable then
            if #sjstable > 0 then
                for k,v in ipairs(sjstable) do
                    -- if type(v.RecordID) == "number" then
                        v.PlayerData[1] = v.PlayerData[1]["1"]
                        v.PlayerData[2] = v.PlayerData[2]["2"]
                        v.PlayerData[3] = v.PlayerData[3]["3"]
                        v.PlayerData[4] = v.PlayerData[4]["4"]
                        v.PlayerData[5] = v.PlayerData[5]["5"]
                        v.PlayerData[6] = v.PlayerData[6]["6"]
                        v.dataType = 0
                        self.pushRecord_(v)
                    -- end
                end
                view:setTableViewTouchEnabled(true)
            end
        end

        view:updateView()
        dump("httpRequst")
        self._scene:dismissPopWait()
    end)

    self:initRecordCache()
end

function PlazaRecordLayer:onShareRecordListener(tag, v)
    local id = self:getRoundRecordId_()

    local shareId = string.format("%s_%s", id, tag)
    
    self._scene:popTargetShare(
        function(target, bMyFriend)
            local function sharecall(isok)
                if type(isok) == 'string' and isok == 'true' then
                    showToast(self, '分享成功', 2)
                end
                GlobalUserItem.bAutoConnect = true
            end

            local share = "快来围观我吊炸天的战绩,横扫场内所有玩家所相匹敌!"

            local url = string.format('%s?roomid=%s', appdf.LINK_URL, shareId)

            MultiPlatform:getInstance():shareToTarget(target, sharecall, '叫友麻将', share, url, '', false, "shareId", shareId)
        end
    )
end

function PlazaRecordLayer:onPlayBackListener(tag, v)
    local id = self:getRoundRecordId_()
    local roundInfo = self:getRoundInfoToFile(id, tag)

    if roundInfo == true then
        self:startPlayBack(id, tag)
    else
        self.m_frame:sendQueryRoundResult(id, tag)
    end
end

--按键监听
function PlazaRecordLayer:onButtonClickedEvent(tag, sender)
    if tag == WIDGET_TAG.BT_CLOSE then
        if self.m_selectContentTag == 2 then
            self.m_selectContentTag = 1
            local view = appdf.getNodeByName(self, "content_TableView")
                        :updateView()
            
            view:moveToOffset_(self.m_lastContentOffset, false)
        else
            self:dismiss()
        end
    else

        for i = 1, 3 do
            local nodeName = string.format("item_%s", i)
            local v = appdf.getNodeByName(self.layer_main, nodeName)
            local textureName

            if v:getTag() ~= tag then
                textureName = string.format("record/zj_icon_%s.png", v:getCallbackType())
            else
                textureName = string.format("record/zj_icon_%s_on.png", v:getCallbackType())
            end

            v:loadTexture(textureName)
        end
        self.resetRecordList_()
        self.resetRoundList_()
        self.m_selectContentTag = 1
        if tag == 4 then
            local view = appdf.getNodeByName(self, "content_TableView")
            :updateView()
            return
        end
        self:saveRecordInfoToFile()

        if tag == 2 then
            self._kindId = 601
        elseif tag == 3 then
            self._kindId = 602
        end

        self:getHttpListByKind()
    end
end

function PlazaRecordLayer:startPlayBack(id, tag)
--[[     self:dismiss(function()
        self._scene:onChangeShowMode(yl.SCENE_PLAYBACK, { kind = self._kindId, roundId = tag, recordId = id})
    end) ]]
    appdf.getNodeByName(self,"content_TableView"):setTableViewTouchEnabled(false)
    self:setSwallowsTouches(false) 
    self:setTouchEnabled(false)
    self._scene:onChangeShowMode(yl.SCENE_PLAYBACK, { kind = self._kindId, roundId = tag, recordId = id})
    

    self:setVisible(false)
end

function PlazaRecordLayer:dismiss(cb)
    self:runAction(
        cc.Sequence:create(
            cc.FadeOut:create(0),
            cc.CallFunc:create(function()
                self:setTouchEnabled(false)
                if cb then
                    cb()
                end
                self:removeSelf()
            end)
        )
    )
end

function PlazaRecordLayer:show(cb)
    self.layer_main:stopAllActions()
    self:setVisible(true)
    self:runAction(
        cc.Sequence:create(
            cc.FadeTo:create(0.3, 200)
        )
    )
    
    self.layer_main:runAction(
        cc.Sequence:create(
            cc.MoveTo:create(0.25,cc.p(0,0)),
            cc.CallFunc:create(function()
                    self:setTouchEnabled(true)

                    if cb then
                        cb()
                    end

                    self:getHttpListByKind(self._kindId)

                    self.m_frame = RecordFrame:create(self, handler(self, self.onScoketCallBack))
                    self.m_frame:onConnect()

                end)
            ))
end

return PlazaRecordLayer