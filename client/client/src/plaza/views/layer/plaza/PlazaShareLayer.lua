local PlazaShareLayer =
    class(
    'PlazaShareLayer',
    function(scene)
        local PlazaShareLayer = cc.LayerColor:create(cc.c4b(0, 0, 0, 0))
        return PlazaShareLayer
    end
)
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. 'MultiPlatform')
local TaskFrame = appdf.req(appdf.CLIENT_SRC .. 'plaza.models.TaskFrame')

PlazaShareLayer.WIDGET_TAG = {}
local WIDGET_TAG = PlazaShareLayer.WIDGET_TAG

function PlazaShareLayer:ctor(scene)
    appdf.registerTouchOutsideHandler(self, false, 'main', false)

    local csbNode = cc.CSLoader:createNode('share/PlazaShareLayer.csb'):move(0, -40):addTo(self)

    self.layer_main = csbNode
    self._scene = scene

    appdf.setNodeTagAndListener(csbNode, 'share_1', 'BT_SHARE_1', handler(self, self.onButtonClickedEvent))
    appdf.setNodeTagAndListener(csbNode, 'share_2', 'BT_SHARE_2', handler(self, self.onButtonClickedEvent))
end

function PlazaShareLayer:onSocketCallBack(v, m)
    -- 查询剩余次数
    if v == 400 then
        -- 获取奖励后
        local value = appdf.getNodeByName(self, 'value'):setString(tostring(m.bCount) .. "次")
    elseif v == 401 then
        if m.szNotifyContent ~= '' then
            -- 更新金币
            if m.szNotifyContent ~= '本周分享领奖次数已用完' then
                local value = appdf.getNodeByName(self, 'value'):setString(tostring(m.bCount) .. '次')
                self._scene:queryUserScoreInfo()
            end

            showToast(self, m.szNotifyContent, 1.5)
        end
    end
end

--按键监听
function PlazaShareLayer:onButtonClickedEvent(tag, sender)
    if tag == WIDGET_TAG.BT_SHARE_1 then
        local sucCallBack = function(isok)
            if type(isok) == 'string' and isok == 'true' then
                -- showToast(self, "分享成功", 2)
                self._taskFrame:onGetShareAward()
            end
        end

        MultiPlatform:getInstance():shareToTarget(
            yl.ThirdParty.WECHAT,
            sucCallBack,
            '叫友麻将',
            '快一起来玩吧!',
            appdf.CLIENT_UPDATE_URL,
            ''
        )
    elseif tag == WIDGET_TAG.BT_SHARE_2 then
        local sucCallBack = function(isok)
            if type(isok) == 'string' and isok == 'true' then
                -- showToast(self, "分享成功", 2)
                self._taskFrame:onGetShareAward()
            end
        end

        MultiPlatform:getInstance():shareToTarget(
            yl.ThirdParty.WECHAT_CIRCLE,
            sucCallBack,
            '叫友麻将',
            '快一起来玩吧!',
            appdf.CLIENT_UPDATE_URL,
            ''
        )
    end
end

function PlazaShareLayer:dismiss(cb)
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

function PlazaShareLayer:show(cb)
    self.layer_main:stopAllActions()
    self:setVisible(true)
    self:runAction(cc.Sequence:create(cc.FadeTo:create(0.3, 200)))
    self.layer_main:runAction(
        cc.Sequence:create(
            cc.MoveTo:create(0.25, cc.p(0, 0)),
            cc.CallFunc:create(
                function()
                    self:setTouchEnabled(true)
                    self._taskFrame = TaskFrame:create(self, handler(self, self.onSocketCallBack))
                    self._taskFrame:onAskShare()

                    if cb then
                        cb()
                    end
                end
            )
        )
    )
end

return PlazaShareLayer
