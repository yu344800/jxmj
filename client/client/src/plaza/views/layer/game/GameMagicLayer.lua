
--
-- Author: zhong
-- Date: 2016-07-22 13:27:18
--
--[[
* 通用显示玩家信息
]]

local GameMagicLayer = class("GameMagicLayer",function()
	local GameMagicLayer = cc.LayerColor:create(cc.c4b(0,0,0,0))
	return GameMagicLayer
end)
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local HeadSpriteHelper = appdf.req(appdf.EXTERNAL_SRC.."HeadSpriteHelper")

function GameMagicLayer:ctor(userItem, cb, getUserTable)
	self:setName("GameMagicLayer")
	self.m_userId = userItem.dwUserID
	self.sendRequest = cb
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

	-- 获取距离
	local initGetDistanceBetween = function()
		local EARTH_RADIUS = 6378.137

		local getP = function(value)
			return value * math.pi / 180.0
		end

		local getDis = function(pointA, radLat1, radLat2, pointB)
			return 2 * math.asin(math.sqrt(math.pow(math.sin(pointA / 2), 2) + math.cos(radLat1) * math.cos(radLat2) * math.pow(math.sin(pointB / 2), 2)))
		end

		return function(location1, location2)
			local a = getP(location1.la)
			local b = getP(location2.la)

			local pointA = a - b
			local pointB = getP(location1.lo) - getP(location2.lo)
			
			
			return getDis(pointA, a, b, pointB) * EARTH_RADIUS
		end
	end

	self.getDistanceBetween = initGetDistanceBetween()


	self.layer_main = ExternalFun.loadCSB("public/GameMagicLayer.csb", self)
					:move(0,- 40)

	-- ip地址解析
	local ipAdress = userItem.szIpAddress or ""
	if nil ~= userItem.dwIpAddress then
		if 0 == userItem.dwIpAddress then
			userItem.dwIpAddress = ExternalFun.random_longip()
		end
		local ipTable = ExternalFun.long2ip(userItem.dwIpAddress)
		local r1 = ipTable.b
		local r2 = ipTable.s
		local r3 = ipTable.m
		local r4 = ipTable.p
		if nil == r1 or nil == r2 or nil == r3 or nil == r4 then
			userItem.szIpAddress = ""
		else
			userItem.szIpAddress = r1 .. "." .. r2 .. "." .. r3 .. "." .. r4
		end
		ipAdress = userItem.szIpAddress
	end

	local userName = appdf.getNodeByName(self, "user_name")
				:setString(userItem.szNickName)
	local user_id = appdf.getNodeByName(self, "user_id")
				:setString(userItem.dwUserID)
	local user_ip = appdf.getNodeByName(self, "user_ip")
				:setString(ipAdress)
	local userAvatar = appdf.getNodeByName(self, "userAvatar")
	HeadSpriteHelper:createClipMaskImg("public/mofa-touxiangkuang-01.png", userItem, userAvatar, 82, nil)

	local m_tableLocation = {}

	local m_tableUserList = getUserTable()
	
	-- 循环用户
	for k,v in pairs(m_tableUserList) do
		local k = k + 1

		--小地图信息
		local nodeName = string.format("userAvatar_%d", k)
		local userAvatar_1 = appdf.getNodeByName(self, nodeName)
		HeadSpriteHelper:createClipMaskImg("public/mofa-touxiangkuang-03.png", v, userAvatar_1, 48, nil)
		
		-- 如果有定位
		if v.location then
			m_tableLocation[k] = v.location
		else
			m_tableLocation[k] = {la = 0, lo = 0}
		end

	end

	-- 定位表
	for k,v in pairs(m_tableLocation) do
		local isUpdateLocation = true
		local nodeName = string.format("Text_%d", k)
		local stateName = appdf.getNodeByName(self, nodeName)

		-- 如果没有定位
		if v.la == 0 and v.lo == 0 then
			isUpdateLocation = false
			
			stateName:setString("未知")	
		end
	
		-- 遍历对比
		for i = 1, #m_tableLocation, 1 do
			-- 不循环自己
			if i ~= k then
				local mdata = m_tableLocation[i]
				if mdata ~= nil then
					local disName = string.format("dis%d_%d", i, k)
					local disbg = string.format("dis%d_%d_bg", i, k)
					
					local disText = appdf.getNodeByName(self, disName)
					local disSprite = appdf.getNodeByName(self, disbg)

					if disText == nil then
						local disName = string.format("dis%d_%d", k, i)
						disText = appdf.getNodeByName(self, disName)
					end
					if disSprite == nil then
						local disbg = string.format("dis%d_%d_bg", k, i)
						disSprite = appdf.getNodeByName(self, disbg)
					end

					disSprite:setVisible(true)

					-- 如果没有定位  两者的距离为???
					if mdata.la == 0 and mdata.lo == 0 or isUpdateLocation == false then
						disText:setString("???")
						disSprite:loadTexture("public/mofa-kuang-02.png")
					else

						local strDis

						-- 有定位
						local distance = self.getDistanceBetween(v, mdata)

						if distance < 1 then
							-- 米为单位
							distance = math.ceil(distance * 1000)
							strDis = string.format('%dm',distance)

						elseif distance >= 1 and distance < 999 then
							-- 保留一位小数
							distance = math.floor(distance * 10) * 0.1
							strDis = string.format('%dkm',distance)
						else
							-- 取整
							distance = math.ceil(distance)
							strDis = string.format('%dkm',distance)
							
						end
						if distance <= 100 then
							disSprite:loadTexture("public/mofa-kuang-02.png")
						else
							disSprite:loadTexture("public/mofa-kuang-03.png")
						end

						disText:setString(strDis)

					end

				end

			end

		end

	end
	
	local btnClickCallBack = function(sender, eventType)
		if eventType == ccui.TouchEventType.ended then
			if self.m_userId == GlobalUserItem.dwUserID then
				showToast(self, "不能对自己使用魔法表情!!", 1.5)
				return
			end

			if self.sendRequest ~= nil then
				self.sendRequest(self.m_userId, sender:getTag())
				self:dismiss()
			end
		end
	end

	for i = 1, 5 do
		local nodeName = string.format("btn_%d", i)
		local node = appdf.getNodeByName(self, nodeName)
		node:setTag(i)
		node:addTouchEventListener(btnClickCallBack)
	end

end

function GameMagicLayer:show()
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
				end)
			))

end

function GameMagicLayer:dismiss()
	self:runAction(
        cc.Sequence:create(
			cc.FadeOut:create(0),
			cc.CallFunc:create(function()
				self:removeSelf()
			end)
		)
    )
         
end


return GameMagicLayer