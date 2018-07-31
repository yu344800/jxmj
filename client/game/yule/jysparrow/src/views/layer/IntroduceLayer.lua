--
-- Author: zhong
-- Date: 2017-01-05 10:22:19
--
-- 玩法介绍
local IntroduceLayer =
    class(
    'IntroduceLayer',
    function(scene)
        local IntroduceLayer = cc.LayerColor:create(cc.c4b(0, 0, 0, 0))
        return IntroduceLayer
    end
)


local TAG_MASK = 101
local BTN_CLOSE = 102
local BTN_CHAOSHAN = 110 
local BTN_TUIDAOHU = 111

function IntroduceLayer:ctor(scene, url )
    
  
        -- 设置触摸事件拦截
    appdf.registerTouchOutsideHandler(self, false, 'Sprite_1', false)


    self._scene = scene
    url = url or yl.HTTP_URL
    -- 加载csb资源
    local csbNode = cc.CSLoader:createNode("rule/RuleLayer.csb"):addTo(self)
    self.layermain = csbNode
    local touchFunC = function(ref, tType)
        if tType == ccui.TouchEventType.ended then
            self:onButtonClickedEvent(ref:getTag(), ref)            
        end
    end
   

    -- local image_bg = csbNode:getChildByName("Sprite_1")
   

    -- 游戏列表
    self.gameList = {}
    local games = appdf.getNodeByName(self,"ListView_1")
    local btn = games:getChildByName('Button_1')    --潮汕麻将
    btn:setTag(BTN_CHAOSHAN)
    btn:addTouchEventListener(touchFunC)
    btn:getChildByName('Image_1')--:setVisible(true)
    self.gameList[BTN_CHAOSHAN] = btn

    btn = games:getChildByName('Button_2')          --推到胡
    btn:setTag(BTN_TUIDAOHU)
    btn:addTouchEventListener(touchFunC)
    btn:getChildByName('Image_1')--:setVisible(false)
    self.gameList[BTN_TUIDAOHU] = btn

    --规则
    local rules = appdf.getNodeByName(self,'ListView_2')
    self.ruleBg = appdf.getNodeByName(rules, 'Image_1')

    -- btn = appdf.getNodeByName(self,"Button_5")
    -- btn:setTag(BTN_CLOSE)
    -- btn:addTouchEventListener(touchFunC)
end

function IntroduceLayer:onButtonClickedEvent(tag, ref)
    -- if TAG_MASK == tag or BTN_CLOSE == tag then
    --     self:removeFromParent()
    if tag == BTN_CHAOSHAN then
        self.gameList[BTN_TUIDAOHU]:setEnabled(true)
        self.gameList[BTN_TUIDAOHU]:getChildByName('Image_1')--:setVisible(false)

        self.gameList[BTN_CHAOSHAN]:setEnabled(false)
        self.gameList[BTN_CHAOSHAN]:getChildByName('Image_1')--:setVisible(true)

        self.ruleBg:loadTexture('rule/csmj_csmj.png')
    elseif tag == BTN_TUIDAOHU then
        self.gameList[BTN_TUIDAOHU]:setEnabled(false)
        self.gameList[BTN_TUIDAOHU]:getChildByName('Image_1')--:setVisible(true)

        self.gameList[BTN_CHAOSHAN]:setEnabled(true)
        self.gameList[BTN_CHAOSHAN]:getChildByName('Image_1')--:setVisible(false)
        self.ruleBg:loadTexture('rule/csmj_tdh.png')
    end
end

function IntroduceLayer:dismiss(cb)
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

function IntroduceLayer:show(cb)
    self.layermain:stopAllActions()
    self:setVisible(true)
    self:runAction(
        cc.Sequence:create(
            cc.FadeTo:create(0.3, 200)
        )
    )

    self.layermain:runAction(
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


return IntroduceLayer