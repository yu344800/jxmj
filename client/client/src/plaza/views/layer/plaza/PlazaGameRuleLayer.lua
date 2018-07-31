local PlazaGameRuleLayer = class("PlazaGameRuleLayer", function(scene)
    local optionLayer = cc.LayerColor:create(cc.c4b(0,0,0,0))
return optionLayer
end)

PlazaGameRuleLayer.WIDGET_TAG = {}
local WIDGET_TAG = PlazaGameRuleLayer.WIDGET_TAG

function PlazaGameRuleLayer:ctor(scene)
    appdf.registerTouchOutsideHandler(self, false, "main", false)

    local csbNode = cc.CSLoader:createNode("rule/PlazaGameRuleLayer.csb")
                    :addTo(self)
                    :move(0,- 40)
                    
    self.layer_main = csbNode
    self._scene = scene

    appdf.setNodeTagAndListener(csbNode, "item_1", "BT_ITEM_1", handler(self, self.onButtonClickedEvent))
                :setCallbackType("sr")
    appdf.setNodeTagAndListener(csbNode, "item_2", "BT_ITEM_2", handler(self, self.onButtonClickedEvent))
                :setCallbackType("jy")
    appdf.setNodeTagAndListener(csbNode, "item_3", "BT_ITEM_3", handler(self, self.onButtonClickedEvent))
                :setCallbackType("none")

    appdf.setNodeTagAndListener(csbNode, "btn_close", "BT_CLOSE", handler(self, self.onButtonClickedEvent))
    

    self:initContent(WIDGET_TAG.BT_ITEM_1)
end

function PlazaGameRuleLayer:initContent(tag)
    local sp
    local scrollView = appdf.getNodeByName(self, "content")
                :removeAllChildren()

    if tag == WIDGET_TAG.BT_ITEM_1 then
        sp = cc.Sprite:create("rule/wfjm_texture_1.png")
                :addTo(scrollView)
                :setAnchorPoint(0, 0)
                :setPosition(40, 10)
    end

    if sp then
        local size = sp:getContentSize()

        size = {
            width = size.width,
            height = size.height + 20
        }

        scrollView:setInnerContainerSize(size)
    end
end

--按键监听
function PlazaGameRuleLayer:onButtonClickedEvent(tag,sender)
    if tag == WIDGET_TAG.BT_CLOSE then
        self:dismiss()
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
        self:initContent(tag)
    end
end

function PlazaGameRuleLayer:dismiss(cb)
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

function PlazaGameRuleLayer:show(cb)
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
                end)
            ))
end

return PlazaGameRuleLayer