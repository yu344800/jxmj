local RuleLayer = class("RuleLayer", function(scene)
    local RuleLayer = cc.LayerColor:create(cc.c4b(0,0,0,0))
return RuleLayer
end)
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")

RuleLayer.BT_CLOSE        = 1
RuleLayer.BT_LEFT_1       = 2

function RuleLayer:ctor(scene)
    self:registerScriptHandler(function(eventType)
        if eventType == "enterTransitionFinish" then	-- 进入场景而且过渡动画结束时候触发。			
            self:onEnterTransitionFinish()			
        elseif eventType == "exitTransitionStart" then	-- 退出场景而且开始过渡动画时候触发。
            self:onExitTransitionStart()
        elseif eventType == "exit" then
            self:onExit()
        end
    end)

    local layerTouch = function(eventType, x, y)
        if eventType == "began" then
            local node = appdf.getNodeByName(self,"main")
            local rect = node:getBoundingBox()
            if cc.rectContainsPoint(rect,cc.p(x,y)) == false then
                self:dismiss()
            end
        end
        return true
    end

    self:setTouchEnabled(true)
    self:setSwallowsTouches(true)
    self:registerScriptTouchHandler(layerTouch)

    local csbNode = ExternalFun.loadCSB( "rule/RuleLayer.csb", self )
                    :move(0,- 40)
                    
    self.layer_main = csbNode
    self._scene = scene

    local cbtlistener = function (sender,eventType)
        this:onSelectedEvent(sender:getTag(),sender,eventType)
    end

    local btcallback = function(sender, eventType)
        if eventType == ccui.TouchEventType.ended then
            self:onButtonClickedEvent(sender:getTag(), sender)
        end
    end

    -- 关闭按钮
    local exit_btn = appdf.getNodeByName(self, "btn_close")
                :setTag(RuleLayer.BT_CLOSE)
                :addTouchEventListener(btcallback)

    local left_btn_1 = appdf.getNodeByName(self, "left_btn_1")
                :setTag(RuleLayer.BT_LEFT_1)
                :addTouchEventListener(btcallback)
                
end

--按键监听
function RuleLayer:onButtonClickedEvent(tag,sender)
    if tag == RuleLayer.BT_CLOSE then
        self:dismiss()
    end
end

function RuleLayer:dismiss(cb)
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

function RuleLayer:show(cb)
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

return RuleLayer