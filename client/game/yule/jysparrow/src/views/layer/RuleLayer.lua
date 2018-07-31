--
-- Author: David
-- Date: 2017-4-6 18:39:13
--
--私人房规则界面
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC.."ExternalFun")
local GameLogic = appdf.req(appdf.GAME_SRC.."yule.jysparrow.src.models.GameLogic")
local cmd = appdf.req(appdf.GAME_SRC.."yule.jysparrow.src.models.CMD_Game")

local RuleLayer = class("RuleLayer", cc.Layer)

--构造
function RuleLayer:ctor( parent )
    self.m_parent = parent
    print("在这是规则")
    --加载csb资源
    local csbNode = ExternalFun.loadCSB("game/NodeRule.csb", self)
    self.csbNode = csbNode
    appdf.registerTouchOutsideHandler(self, false, 'bg_rule', false)

end

function RuleLayer:onTouchBegan(touch, event)
    return self:isVisible()
end

function RuleLayer:onTouchEnded(touch, event)
end

-- 显示房间规则
function RuleLayer:showRule(bShow, rules, mode)
    if bShow == true then
        self:setVisible(true)
        self:setTouchEnabled(true)

        -- 加载房间选项
        for i=1, #rules do 
            local text = appdf.getNodeByName(self.csbNode, 'Text_' .. i)
            if i == 4 then 
                local list = rules[i]

                for j=1, 20 do 
                    local t = text:getChildByName('Text_d' .. j)
                    if list[j] then 
                        t:setVisible(true)
                        t:setString(list[j])
                    else 
                        t:setVisible(false)
                    end 
                end

                -- 马牌位置偏移
                -- local t = appdf.getNodeByName(self.csbNode, 'Text_' .. 5)
                -- local py = t:getPositionY()
                -- t:setPositionY(py + (20 - #list) / 3 * 30 )
            else 
                local desc = text:getChildByName('Text_desc')
                desc:setString(rules[i])
            end 
        end
    else 
        self:dismiss()
    end
end

function RuleLayer:dismiss()

    self:setVisible(false)
	
	self:runAction(
		cc.Sequence:create(
			cc.DelayTime:create(0.2),
			cc.CallFunc:create(function()
				self:setTouchEnabled(false)
			end)
		)
	)
end

return RuleLayer