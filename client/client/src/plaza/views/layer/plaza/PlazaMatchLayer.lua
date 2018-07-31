local PlazaMatchLayer =
    class(
    'PlazaMatchLayer',
    function(scene)
        local optionLayer = cc.LayerColor:create(cc.c4b(0, 0, 0, 0))
        return optionLayer
    end
)

PlazaMatchLayer.WIDGET_TAG = {}
local WIDGET_TAG = PlazaMatchLayer.WIDGET_TAG

function PlazaMatchLayer:ctor(scene)
    appdf.registerTouchOutsideHandler(self, false, 'main', false)

    local csbNode = cc.CSLoader:createNode('match/PlazaMatchLayer.csb'):addTo(self):move(0, -40)

    self.layer_main = csbNode
    appdf.setNodeTagAndListener(csbNode, 'btn_close', 'BT_CLOSE', handler(self, self.onButtonClickedEvent))
end

--按键监听
function PlazaMatchLayer:onButtonClickedEvent(tag, sender)
    if tag == WIDGET_TAG.BT_CLOSE then
        self:dismiss()
    end
end

function PlazaMatchLayer:dismiss(cb)
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

function PlazaMatchLayer:show(cb)
    self.layer_main:stopAllActions()
    self:setVisible(true)
    self:runAction(cc.Sequence:create(cc.FadeTo:create(0.3, 200)))

    self.layer_main:runAction(
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

return PlazaMatchLayer
