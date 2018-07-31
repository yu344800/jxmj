local cmd = appdf.req(appdf.GAME_SRC.."yule.jysparrow.src.models.CMD_Game")
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC.."ExternalFun")
local CardLayer = appdf.req(appdf.GAME_SRC.."yule.jysparrow.src.views.layer.CardLayer")
local GameLogic = appdf.req(appdf.GAME_SRC.."yule.jysparrow.src.models.GameLogic")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")

local ShareResultLayer = class("ShareResultLayer", function(scene)
	local RstLayer = cc.Layer:create()
	return RstLayer
end)

local UserItem_Begin 		= 10
local CBT_CONTINUE 			= 20
local CBT_SHARE             = 30
function ShareResultLayer:onInitData()

end

function ShareResultLayer:onResetData()
    
end

function ShareResultLayer:ctor(scene)
    --print("创建结算分享界面")
	self._viewLayer = scene
    self._endData = {}
	self:onInitData()
	
	local layerTouch = function(eventType, x, y)
		return true
	end

	self:setTouchEnabled(false)
	self:setSwallowsTouches(true)
    self:registerScriptTouchHandler(layerTouch)
	-- ExternalFun.registerTouchEvent(self, true)

	local csbNode = ExternalFun.loadCSB("shareResult/ShareResultNode.csb", self)

	local btn_continue = appdf.getNodeByName(csbNode, 'btn_continue')
    local btn_share = appdf.getNodeByName(csbNode, 'btn_share')
    --按键监听
	local  btcallback = function(ref, type)
        if type == ccui.TouchEventType.ended then
         	self:onButtonClickedEvent(ref:getTag(),ref)
        end
    end

	-- 分享游戏
	btn_share:setTag(CBT_SHARE)
	btn_share:addTouchEventListener(btcallback)

	-- 继续游戏
	btn_continue:setTag(CBT_CONTINUE)
	btn_continue:addTouchEventListener(btcallback)
end

function ShareResultLayer:onButtonClickedEvent(tag, type)
    if tag == CBT_CONTINUE then
        print("点击继续")
        self._viewLayer._resultLayer:showLayer(self._endData[1], self._endData[2], self._endData[3], self._endData[4])
        self:hideLayer()
    elseif tag == CBT_SHARE then
		print("点击分享")
		PriRoom:getInstance():getPlazaScene():popTargetShare(function(target, bMyFriend)
            bMyFriend = bMyFriend or false
            local function sharecall( isok )
                if type(isok) == "string" and isok == "true" then
                    showToast(self, "分享成功", 2)
                end
                GlobalUserItem.bAutoConnect = true
            end
            local url = appdf.FIR_UPDATE_URL
            -- 截图分享
            local framesize = cc.Director:getInstance():getOpenGLView():getFrameSize()
            local area = cc.rect(0, 0, framesize.width, framesize.height)
            local imagename = "grade_share.jpg"
            if bMyFriend then
                imagename = "grade_share_" .. os.time() .. ".jpg"
            end
            ExternalFun.popupTouchFilter(0, false)
            captureScreenWithArea(area, imagename, function(ok, savepath)
                ExternalFun.dismissTouchFilter()
                if ok then
                    if bMyFriend then
                        PriRoom:getInstance():getTagLayer(PriRoom.LAYTAG.LAYER_FRIENDLIST, function( frienddata )
                            PriRoom:getInstance():imageShareToFriend(frienddata, savepath, "分享我的约战房战绩")
                        end)
                    elseif nil ~= target then
                        GlobalUserItem.bAutoConnect = false
                        MultiPlatform:getInstance():shareToTarget(target, sharecall, "我的约战房战绩", "分享我的约战房战绩", url, savepath, "true")
                    end            
                end
            end)
        end)
	end
end

function ShareResultLayer:showLayer(endData,userName,userScore,cardList,typeResName)
    print("显示")
    self._endData = endData
    self:move(0, 0)
    self:setVisible(true)
	self:setTouchEnabled(true)
	--设置显示特殊牌型的类型
	local image_cardType = appdf.getNodeByName(self,"result_type")
	image_cardType:loadTexture(typeResName)
	--显示名字
	local tex_userName = appdf.getNodeByName(self,"tex_userName")
	tex_userName:setString(userName)
	--显示分数
	local tex_atl_userScore = appdf.getNodeByName(self,"tex_atl_userScore")
	tex_atl_userScore:setString(tostring(userScore))
	--显示手牌
	if not cardList then
		print("返回")
        return
	end
	--先隐藏四个碰扛牌
	for i = 1, 4 , 1 do
		local nodeName = "card_kang_" .. tostring(i)
		local node = appdf.getNodeByName(self,nodeName)
		node:setVisible(false)
	end
	local count = 0
	local activeCards = cardList.cbActiveCardData 
	dump(activeCards, '碰杠牌')
	for i=1, #activeCards do
		local active = activeCards[i]
		if active then

			for j=1, active.cbCardNum do
				local cardValue = (active.cbCardValue[j] == 0 and active.cbCardValue[1] or active.cbCardValue[j])
				--设置坐标
				if j == 4 and (active.cbType >= GameLogic.SHOW_MING_GANG or active.cbType <= GameLogic.SHOW_AN_GANG) then
					--sprCard:setPosition(cc.p(pos.x - width+6, pos.y + 10))
                    self:setMjShowData(i+100,cardValue)
				else

					--sprCard:setPosition(cc.p(pos.x + width, pos.y))
					--pos.x = pos.x + width

					count = count + 1
					self:setMjShowData(count,cardValue)
				end
				
			end
		end
	end

	local handCards = cardList.cbCardData
	dump(handCards, '手牌')
	for j=1,#handCards do
		local cardValue = handCards[j]
		count = count + 1
		if j>14 then
			break
		end
		self:setMjShowData(count,cardValue)
	end
end

function ShareResultLayer:hideLayer()
	self:setVisible(false)
	self:move(0,display.height)
	
	self:runAction(cc.Sequence:create(
			cc.DelayTime:create(0.2),
			cc.CallFunc:create(function()
 
				self:setTouchEnabled(false)
				self:onResetData()
			end)
		)
	)
	return self
end
 
function ShareResultLayer:setMjShowData(index,value)

	local sprPath = cmd.RES_PATH.."card/my_normal/tile_me_"

	--获取数值
	local cardIndex = GameLogic.SwitchToCardIndex(value)
	if cardIndex < 10 then
		sprPath = sprPath..string.format("0%d", cardIndex)..".png"
	else
		sprPath = sprPath..string.format("%d", cardIndex)..".png"
	end
	--local spriteValue = display.newSprite(sprPath)
	--获取精灵
	local mjName = ""
	if index <= 100 then--普通牌
	    mjName = "card_" .. tostring(index)
	else--碰扛牌
	    mjName = "card_kang_" .. tostring(index-100)
	end
	local card = appdf.getNodeByName(self,mjName)
	card:setVisible(true)
	local sprCard = card:getChildByName("card_value")
	if nil ~= sprCard then
		sprCard:setTexture(sprPath)
	end
	local sprFlag = card:getChildByName("flag")
--[[ 	if nil ~=  sprFlag then
		sprFlag:setVisible(self:isMagicCard(value))
	end ]]

end

return ShareResultLayer