local PlazaRankLayer = class("PlazaRankLayer", function(scene)
    local optionLayer = cc.LayerColor:create(cc.c4b(0,0,0,0))
return optionLayer
end)

local TopRankFrame = appdf.req(appdf.CLIENT_SRC.."plaza.models.TopRankFrame")

PlazaRankLayer.WIDGET_TAG = {}
local WIDGET_TAG = PlazaRankLayer.WIDGET_TAG

function PlazaRankLayer:onExitTransitionStart()
    if self.m_frame then
        self.m_frame:onCloseSocket()
    end
    return self
end

function PlazaRankLayer:onEnterTransitionFinish()
    return self
end

function PlazaRankLayer:onScoketCallBack(sub, data)
    if sub == TopRankFrame.SUB_GP_GAME_TOP_RANK_RESPONE then

        self.m_tableRankList[data.dwKindId] = data.userItem

        local view = appdf.getNodeByName(self, "content_TableView")
                :updateView()

    elseif sub == -1 then
        self.m_frame:onConnect()
    elseif sub == 0 then
        self.m_frame:sendQuery(self._kindId)
    end
end

function PlazaRankLayer:ctor(scene)
    appdf.registerNodeEvent(self)
    appdf.registerTouchOutsideHandler(self, false, "main", false)

    local csbNode = cc.CSLoader:createNode("rank/PlazaRankLayer.csb")
                    :addTo(self)
                    :move(0,- 40)
                    
    self.layer_main = csbNode
    self._scene = scene
    appdf.setNodeTagAndListener(csbNode, "btn_close", "BT_CLOSE", handler(self, self.onButtonClickedEvent))

    appdf.setNodeTagAndListener(csbNode, "item_1", "BT_ITEM_1", handler(self, self.onButtonClickedEvent))
                :setCallbackType("sr")
    appdf.setNodeTagAndListener(csbNode, "item_2", "BT_ITEM_2", handler(self, self.onButtonClickedEvent))
                :setCallbackType("jy")
    appdf.setNodeTagAndListener(csbNode, "item_3", "BT_ITEM_3", handler(self, self.onButtonClickedEvent))
                :setCallbackType("none")

    self._kindId = 602
    self.m_tableRankList = {}

    self.m_tableRankList[601] = {}
    self.m_tableRankList[602] = {}

    self:initContentTableView(csbNode)
end

function PlazaRankLayer:initContentTableView(csbNode)
    
    local item = appdf.getNodeByName(self, "clone_item")

    local m_tableview = ccui.UITableView:create({
        viewRect = cc.rect(666, 322, 970, 408),
        direction = cc.SCROLLVIEW_DIRECTION_VERTICAL,
        fill = cc.TABLEVIEW_FILL_TOPDOWN,
        interval = 0,
        createCell = handler(self, self.contentCreateCell),
        getCellCount = handler(self, self.contentGetCellsCount),
        getCellSize = nil,
    })
            :addTo(csbNode)
            :setName("content_TableView")
            :setCloneCellItem(item)
            :setTableViewTouchEnabled(false)
            -- :setTopBounceEnable(true)
            :setUltraTopDistanceRefresh(true)
            :setUltraTopDistance(100)
            :setUltraTopCallBack(function(updateView)

                
                self.m_frame:sendQuery(self._kindId)
                

                updateView()
            end)
            :setBottomBounceEnable(true)
            :initScrollHanlder()
            -- :moveToOffset_(cc.p(0, 0), false)
end

function PlazaRankLayer:contentGetCellsCount(view)
    return #self.m_tableRankList[self._kindId]
end

function PlazaRankLayer:contentCreateCell(view, item, idx)
    local showFuc = function ()
        item:setVisible(true)
    end

    if item:getPositionX() ~= 482 and item:isVisible() == false then
        item:stopAllActions()

        item:setAnchorPoint(0.5, 0.5)
        item:setPosition(482, -30)
    
        item:runAction(
            cc.Sequence:create(
                cc.DelayTime:create(0.2 * idx),
                cc.CallFunc:create(showFuc),
                cc.Spawn:create(
                    cc.MoveTo:create(0.3, cc.p(482, 30)),
                    cc.FadeTo:create(0.3, 255)
                )
            )
        )
    elseif item:isVisible() == false then
        item:setAnchorPoint(0.5, 0.5)
        item:setOpacity(255)
        item:setPosition(482, 30)
        showFuc()
    else
        item:setPosition(482, 30)
        item:setOpacity(255)
    end

    local icon = appdf.getNodeByName(item, "icon")
    
    if idx > 3 then
        icon:setVisible(false)
    else
        local textureName = string.format("rank/pm_icon_%s.png", idx)
        icon:setVisible(true)
        icon:loadTexture(textureName)
    end

    local v = self.m_tableRankList[self._kindId][idx]

    local view = appdf.getNodeByName(item, "user_name")
            :setString(v.kNickName)
    local view = appdf.getNodeByName(item, "max_score")
            :setString(v.lScore)
    
    local user_title = appdf.getNodeByName(item, "user_title")
    local icon_title = appdf.getNodeByName(item, "icon_title")
            
    local title

    if v.lScore <= 0 then
        title = "幼鸟"
    elseif v.lScore > 0 and v.lScore <= 100 then
        title = "菜鸟"

    elseif v.lScore > 100 and v.lScore <= 200 then
        title = "麻雀"

    elseif v.lScore > 200 and v.lScore <= 500 then
        title = "喜鹊"

    elseif v.lScore > 500 and v.lScore <= 1000 then
        title = "啄木鸟"

    elseif v.lScore > 1000 and v.lScore <= 2000 then
        title = "猫头鹰"

    elseif v.lScore > 2000 then
        user_title:setVisible(false)
        icon_title:setVisible(true)
    end
    
    if title ~= nil then
        user_title:setString(title)    
        icon_title:setVisible(false)
    end
end

--按键监听
function PlazaRankLayer:onButtonClickedEvent(tag,sender)
    if tag == WIDGET_TAG.BT_EXCHANGE then
    elseif tag == WIDGET_TAG.BT_CLOSE then
        self:dismiss()
    elseif tag == WIDGET_TAG.CBT_SILENCE then
    elseif tag == WIDGET_TAG.CBT_SOUND then
        
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

        if tag == 4 then
            self._kindId = 601
            local view = appdf.getNodeByName(self, 'content_TableView'):updateView()

            return
        end

        if tag == 3 then
            self._kindId = 601
            local view = appdf.getNodeByName(self, "content_TableView")
                                :updateView()
        elseif tag == 2 then
            self._kindId = 602
            self.m_frame:sendQuery(self._kindId)
        end

    end
end

function PlazaRankLayer:dismiss(cb)
    self:runAction(
        cc.Sequence:create(
            cc.FadeOut:create(0),
            cc.CallFunc:create(function()
                self:setTouchEnabled(false)
                -- self:setVisible(false)
                self:removeSelf()
            end)
        )
    )
end

function PlazaRankLayer:show(cb)
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

                    self.m_frame = TopRankFrame:create(self, handler(self, self.onScoketCallBack))
                    self.m_frame:onConnect()

                    local view = appdf.getNodeByName(self, "content_TableView")
                                :updateView()
                                :setTableViewTouchEnabled(true)
                end)
            ))
end

return PlazaRankLayer