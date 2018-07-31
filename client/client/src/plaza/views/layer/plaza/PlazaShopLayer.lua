local PlazaShopLayer =
    class(
    'PlazaShopLayer',
    function(scene)
        local optionLayer = cc.LayerColor:create(cc.c4b(0, 0, 0, 0))
        return optionLayer
    end
)

local ClientConfig = appdf.req('base.src.app.models.ClientConfig')
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. 'ExternalFun')
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. 'MultiPlatform')

PlazaShopLayer.WIDGET_TAG = {}
local WIDGET_TAG = PlazaShopLayer.WIDGET_TAG

function PlazaShopLayer:ctor(scene)
    appdf.registerTouchOutsideHandler(self, false, 'main', false)

    local csbNode = cc.CSLoader:createNode('shop/PlazaShopLayer.csb'):addTo(self):move(0, -40)

    self._scene = scene
    self.layer_main = csbNode
    local texStr = ""
    if GlobalUserItem.lRoomCard > 99999 then
        texStr = ExternalFun.formatScoreText(GlobalUserItem.lRoomCard)
    else
        texStr = tostring(GlobalUserItem.lRoomCard)
    end
    appdf.getNodeByName(csbNode, 'tex_cardNum'):setString(texStr)

    appdf.setNodeTagAndListener(csbNode, 'btn_close', 'BT_CLOSE', handler(self, self.onButtonClickedEvent))
    appdf.setNodeTagAndListener(csbNode, 'btn_item1', 'BTN_ITEM_1', handler(self, self.onButtonClickedEvent))
    appdf.setNodeTagAndListener(csbNode, 'btn_item2', 'BTN_ITEM_2', handler(self, self.onButtonClickedEvent))
    appdf.setNodeTagAndListener(csbNode, 'btn_item3', 'BTN_ITEM_3', handler(self, self.onButtonClickedEvent))
    appdf.setNodeTagAndListener(csbNode, 'btn_item4', 'BTN_ITEM_4', handler(self, self.onButtonClickedEvent))
end

--按键监听
function PlazaShopLayer:onButtonClickedEvent(tag, sender)
    if tag == WIDGET_TAG.BT_CLOSE then
        self:dismiss()
    else
        --钻石数
        local amount = 0
        --价格
        local total = 0

        if tag == WIDGET_TAG.BTN_ITEM_1 then
            amount = 108
            total = 28
        elseif tag == WIDGET_TAG.BTN_ITEM_2 then
            amount = 268
            total = 68
        elseif tag == WIDGET_TAG.BTN_ITEM_3 then
            amount = 368
            total = 88
        elseif tag == WIDGET_TAG.BTN_ITEM_4 then
            amount = 488
            total = 108
        end

        if ClientConfig.UPDATE_TO_APPSTORE == true then
            -- 苹果支付
            self:doIpaPay(amount, total)
        else
            -- 微信支付
            self:doWxPay(amount, total)
        end
    end
end

function PlazaShopLayer:doIpaPay(amount, price)
    if device.platform ~= 'windows' then
        -- 苹果后台商品id
        local productid = "0"
        
        if price == 28 then
            productid = "00028"
        elseif price == 68 then
            productid = "00068"
        elseif price == 88 then
            productid = "000368"
        elseif price == 108 then
            productid = "000488"
        end

        local payparam = {}
        -- 沙盒测试地址
        -- payparam.http_url = "https://sandbox.itunes.apple.com/verifyReceipt"

        -- 正式地址
        payparam.http_url = 'https://buy.itunes.apple.com/verifyReceipt'

        payparam.uid = GlobalUserItem.dwUserID
        payparam.productid = productid
        payparam.price = price

        local function payCallBack(param)
            self:dismissPopWait()

            if type(param) == 'string' and 'true' == param then
                showToast(self._scene, '支付成功,游戏愉快!', 2)
                self:queryUserScoreInfo()
                self:dismiss()
            else
                showToast(self, 'iTunes Store支付异常！', 2)
            end
        end

        self:showPopWait()

        showToast(self, '正在支付中...', 99)

        self.clickPrice = amount

        MultiPlatform:getInstance():thirdPartyPay(yl.ThirdParty.IAP, payparam, payCallBack)
    end
end

function PlazaShopLayer:doWxPay(PresentCurrency, price)
    if device.platform ~= 'windows' then

        local payUrl =
            string.format(
            'http://pay.chaoren6.com:6662/jyqp/wxpay/jump.php?userId=%s&payType=weixin&amount=%s&total=%s',
            GlobalUserItem.dwUserID,
            PresentCurrency,
            price
        )

        
        MultiPlatform:getInstance():openBrowser(payUrl)
        


        -- 请求订单
        -- appdf.onHttpJsionTable(
        --     payUrl,
        --     'GET',
        --     '',
        --     function(sjstable, sjsdata)
        --         self:dismissPopWait()
        --         if sjstable.code == 'true' then
        --             showToast(self, '正在调用微信支付...', 1)

        --             local function payCallBack(param)
        --                 self:dismissPopWait()

        --                 if type(param) == 'string' and 'true' == param then
        --                     showToast(self._scene, '支付成功!游戏愉快!', 2)

        --                     self:dismiss(
        --                         function()
        --                             self._scene:queryUserScoreInfo()
        --                         end
        --                     )
        --                 else
        --                     showToast(self, '支付异常,如有问题请联系客服!', 2)
        --                 end
        --             end

        --             MultiPlatform:getInstance():thirdPartyPay(yl.ThirdParty.WECHAT, sjstable, payCallBack)
        --         else
        --             showToast(self, '生成订单失败...如有问题请联系客服!', 2)
        --         end
        --     end
        -- )
    end
end

function PlazaShopLayer:showPopWait()
    self._scene:showPopWait()
end

function PlazaShopLayer:dismissPopWait()
    self._scene:dismissPopWait()
end

function PlazaShopLayer:queryUserScoreInfo()
    if nil ~= self._scene.updateInfomation then
        GlobalUserItem.lRoomCard = GlobalUserItem.lRoomCard + self.clickPrice
        self._scene:updateInfomation()
    end

    self.clickPrice = nil
end

function PlazaShopLayer:updateScoreInfo()
    self:dismissPopWait()

    -- 钻石
    appdf.getNodeByName(self, 'tex_cardNum'):setString(ExternalFun.formatScoreText(GlobalUserItem.lRoomCard))
end

function PlazaShopLayer:dismiss(cb)
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

function PlazaShopLayer:show(cb)
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

return PlazaShopLayer
