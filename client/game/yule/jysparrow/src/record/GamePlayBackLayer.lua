local BaseLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.game.GameVideoBaseLayer")
local GamePlayBackLayer = class("GamePlayBackLayer", BaseLayer)
local HeadSpriteHelper = appdf.req(appdf.EXTERNAL_SRC.."HeadSpriteHelper")
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")

-- 动画枚举
local CHANGE_CARD_TYPE = 
{
	CHANGE					= 1,			-- 排列左边牌
	MOVERIGHT				= 2,			-- 抽张牌置右
	SORTMOVE				= 3,			-- 左边牌 往左移动
	REVERT					= 4,		   	-- 回收摸牌
	SHUFFLING				= 5,			-- 搓牌盖牌时排列
}

-- 指令类型
local ACTION_TYPE =
{
	"OperateResult",			-- 吃碰杠
	"SendCard",					-- 发牌
	"OutCard",					-- 出牌
	"ChiHu",					-- 吃胡
	"Banker",					-- 庄家
}

-- 操作码
local OPERATE_CODE = function(code)
	local encode
	if code == 0x00 then
		encode = "WIK_NULL" 			--没有类型--0
	elseif code == 0x01 then
		encode = "WIK_LEFT" 			--左吃类型--1
	elseif code == 0x02 then
		encode = "WIK_CENTER" 			--中吃类型--2
	elseif code == 0x04 then
		encode = "WIK_RIGHT" 			--右吃类型--4
	elseif code == 0x08 then
		encode = "WIK_PENG" 			--碰牌类型--8
	elseif code == 0x10 then
		encode = "WIK_GANG" 			--杠牌类型--16
	elseif code == 0x20 then
		encode = "WIK_LISTEN" 			--听牌类型--32
	elseif code == 0x40 then
		encode = "WIK_CHI_HU" 			--吃胡类型--64
	elseif code == 0x80 then
		encode = "WIK_FANG_PAO" 		--放炮--128
	end

	return encode
end

local GANGE_CODE =
{
	"WIK_MING_GANG",			-- 明杠
	"WIK_FANG_GANG",			-- 放杠
	"WIK_AN_GANG",				-- 暗杠
}

local resPath = "game/yule/jysparrow/res/"

-- 获取牌值
local initCardData = function()
	local LocalCardData = 
	{
		0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08, 0x09,
		0x11, 0x12, 0x13, 0x14, 0x15, 0x16, 0x17, 0x18, 0x19,
		0x21, 0x22, 0x23, 0x24, 0x25, 0x26, 0x27, 0x28, 0x29,
		0x31, 0x32, 0x33, 0x34, 0x35, 0x36, 0x37
	}
	local getIdx = function(v)
		if v == 0 then
			return 0
		end
	
		local index = 0
		for i = 1, #LocalCardData do
			if LocalCardData[i] == v then
				index = i
				break
			end
		end
		
		return index
	end

	return getIdx
end

local getChairIdByViewId

-- 获取视图位置
local InitChairIdByViewId = function(data)
	local isMeChair
	local mViewId

	for k,v in ipairs(data) do
		if v.dwUserID ~= 0 then
			if v.dwUserID == GlobalUserItem.dwUserID then
				isMeChair = v.wChairID
				mViewId = 1

				break
			end
		end
	end


	local switchViewId = function(chairId)
		local viewId

		if chairId == 0 then
			-- str = "Bottom"
			viewId = 1
		elseif chairId == 1 then
			-- str = "Left"
			viewId = 2
			
		elseif chairId == 2 then
			-- str = "Right"
			viewId = 3
			
		elseif chairId == 3 then
			-- str = "Top"
			viewId = 4
		end

		return viewId
	end

	local getViewId = function(chairId)
		-- 返回我的视图
		if chairId == isMeChair then
			return 1
		end

		local viewId = switchViewId(chairId)

		-- 我用了他的视图 返回我原本的视图
		if viewId == mViewId then
			return switchViewId(isMeChair)
		end

		return viewId
	end

	return getViewId
end

-- 创建牌
local initCardRes = function()
	local resCsb_1 = 
	{
		resPath .. "card/Node_majong_my.csb",
		resPath .. "card/Node_majong_left_down.csb",
		resPath .. "card/Node_majong_right_down.csb",
		resPath .. "card/Node_majong_top_dowm.csb",
	}

	local resCsb_2 = 
	{
		resPath .. "card/Node_majong_my_downsmall.csb",
		resPath .. "card/Node_majong_left_down.csb",
		resPath .. "card/Node_majong_right_down.csb",
		resPath .. "card/Node_majong_top_dowm.csb",
	}
	
	local resValue_1 = 
	{
		resPath .. "card/my_big/tile_me_up_",
		resPath .. "card/left_right/tile_leftRight_",
		resPath .. "card/left_right/tile_leftRight_",
		resPath .. "card/my_small/tile_meUp_",
	}

	local resValue_2 = 
	{
		resPath .. "card/my_small/tile_meUp_",
		resPath .. "card/left_right/tile_leftRight_",
		resPath .. "card/left_right/tile_leftRight_",
		resPath .. "card/my_small/tile_meUp_",
	}
	
	local create = function(viewId, value, model)
		model = model or "def"
		local card
		local sprPath

		if model == "def" then
			card = cc.CSLoader:createNode(resCsb_1[viewId])
			sprPath = resValue_1[viewId]
		elseif model == "small" then
			card = cc.CSLoader:createNode(resCsb_2[viewId])
			sprPath = resValue_2[viewId]
		end

		if value < 10 then
			sprPath = sprPath .. string.format("0%d", value) .. ".png"
		else
			sprPath = sprPath .. string.format("%d", value) .. ".png"
		end

		local size = card:getChildByName("card_bg"):getContentSize()
		card:setContentSize(size)

		local sprCard = card:getChildByName("card_value")
				:setTexture(sprPath)

		return card
	end

	local getTextureRes = function(viewId, value, model)
		model = model or "def"
		local sprPath = ""

		if model == "def" then
			card = cc.CSLoader:createNode(resCsb_1[viewId])
			sprPath = resValue_1[viewId]
		elseif model == "small" then
			card = cc.CSLoader:createNode(resCsb_2[viewId])
			sprPath = resValue_2[viewId]
		end

		if value < 10 then
			sprPath = sprPath .. string.format("0%d", value) .. ".png"
		else
			sprPath = sprPath .. string.format("%d", value) .. ".png"
		end

		return sprPath
	end

	return create, getTextureRes
end

-- 获取坐标
local getXY = function(viewId, index, size, scale, startPos)
	local x
	local y

	scale = scale or 0.9
	local newSize = {width = size.width, height = size.height}
	startPos = startPos or {width = 0, height = 0}

	if viewId == 1 or viewId == 4 then
		if viewId == 1 then
			y = newSize.height * scale / 2
		else
			newSize.width = - newSize.width
			y = 0
		end

		x = startPos.width + (newSize.width * scale / 2 + 5) + (index - 1) * (newSize.width * scale)
		
	elseif viewId == 2 or viewId == 3 then
		if viewId == 2 then
			newSize.height = - newSize.height
		end

		y = startPos.height + newSize.height / 2 + (index - 1) * (newSize.height + (viewId == 2 and  12 or -12))

		x = 0
	end

	return cc.p(x, y)
end

-- 桌面牌数
local initDesktopValue = function(v, getNode)
	local mV = v 
	local atlas_last = getNode()
			:setString(mV)

	local del = function()
		mV = mV - 1
		if mV <= 0 then
			mV = 0
		end
		atlas_last:setString(mV)
	end

	return del
end

function GamePlayBackLayer:onExitTransitionStart()
    GamePlayBackLayer.super.onExitTransitionStart(self)
	PriRoom:getInstance():resetSearchPaths()
end

function GamePlayBackLayer:onEnterTransitionFinish()
end


function GamePlayBackLayer:ctor(clientScene, params)
    local csbNode = ExternalFun.loadCSB("record/GamePlayBackLayer.csb", self)
	GamePlayBackLayer.super.ctor(self, clientScene, params)
	

	if self.m_tableReplayData == nil then
		return
	end
	
	self:initVideoState(handler(self, self.onVideoStateChangeListener))
	self.getCardDataIndex = initCardData()
	self.createCardSprite, self.getCardResourcePath = initCardRes()


	self:autoPlayVideo()
end

function GamePlayBackLayer:initAllData()
	self.isRetreat = false				-- 是否回退
	self:onSetLastButtonBnable(false)	-- 是否禁用回退
	self.delDeskTopCardValue = nil		-- 删除桌面牌数函数
	self.m_tableLastParams = {}			-- 当前指令
end

-- 播放状态改变
function GamePlayBackLayer:onVideoStateChangeListener(state)
	self.m_videoState = state
	if self.m_videoState == "init" then
		self:initAllData()
		self:initPlayer()
		self:cleanMyCardsDataAndNode()
		self:cleanOutViewCardDataAndNode()
		self:cleanSpicialCardsDataAndNode()
		
	elseif self.m_videoState == "retreat" and self.delDeskTopCardValue then
		self:cleanCommand()
		-- 回退过
		self.isRetreat = true
	end
end

-- 清除指令
function GamePlayBackLayer:cleanCommand(params)
	-- 回退状态
			
	local lastParams = params or self.m_tableLastParams
			
	-- 解析
	local viewId, newData = self:parseCmdDataToTable(lastParams.wOperateUser, lastParams.cbOperateCard)

	-- 删除上一个指令内容
	local action = ACTION_TYPE[lastParams.cbActionType]
	dump(action)

	if action == "Banker" then
		self:onSetLastButtonBnable(false)

	elseif action == "SendCard" then
		self:removeCardsData(viewId, newData)

	elseif action == "OperateResult" then

		self:removeSpicialCardsByViewId(viewId, newData, function(v)
		
			-- 删除一个牌堆里牌
			table.remove(v, 1)
			self:addCardDataByViewId(viewId, v)
		
		end)

	elseif action == "OutCard" then

		self:removeOutViewCard(viewId, newData, 0)
		self:addCardDataByViewId(viewId, newData)
		
	elseif action == "ChiHu" then
		self:onSetLastButtonBnable(false)

	end
end

-- 分发指令
function GamePlayBackLayer:dispatchCommand(params)
	
	local action = ACTION_TYPE[params.cbActionType]
	-- dump(action)
	
	-- 回退时 会把新的指令已经执行过的 再执行一遍 则清除一次
	if self.isRetreat == true then
		self.isRetreat = false
		self:cleanCommand(params)
	end

	-- 解析
	local viewId, newData = self:parseCmdDataToTable(params.wOperateUser, params.cbOperateCard)

	
	-- 储存
	self.m_tableLastParams = params
	-- viewId, newData = getChairIdByViewId(wOperateUser), self.getCardDataIndex(cbOperateCard)

	-- 发牌
	if action == "SendCard" then
		self:addCardDataByViewId(viewId, newData)

		-- 摸牌数据
		viewId, newData = self:parseCmdDataToTable(params.wOperateUser, params.cbOther)
		if newData ~= nil then
			self:addCardDataByViewId(viewId, newData)
		end

		-- 减少显示牌数
		if self.delDeskTopCardValue then
			self.delDeskTopCardValue()
		end

	-- 特殊操作
	elseif action == "OperateResult" then

		local code = OPERATE_CODE(params.cbOperateCode)
		local code = OPERATE_CODE(params.cbOperateCode)

		self:removeOutViewCard(getChairIdByViewId(params.wProvideUser), newData)
		self:addSpicialCardsByViewId(viewId, newData, code, params.cbOther[1][1])
		self:removeCardsData(viewId, newData, code)

		self:showOperateAnime(viewId, code, true)
	-- 出牌
	elseif action == "OutCard" then
		-- 刷新手牌
		self:removeCardsData(viewId, newData)

		-- 添加牌堆
		self:addOutViewCardByViewId(viewId, newData)

	-- 胡
	elseif action == "ChiHu" then
		
		self:onSetLastButtonBnable(false)
		local code = OPERATE_CODE(params.cbOperateCode)

		self:removeOutViewCard(getChairIdByViewId(params.wProvideUser), newData)

		self:addCardDataByViewId(viewId, newData)
		
		self:showOperateAnime(viewId, code, false)
	-- 庄
	elseif action == "Banker" then
		self:setBankerIcon(params.wOperateUser, true)

		-- 初始桌面牌数
		self.delDeskTopCardValue = initDesktopValue(params.cbOther[1][1], function()
			local atlas_last = appdf.getNodeByName(self, "atlas_last")
			return atlas_last
		end)

		-- 可回退
		self:onSetLastButtonBnable(true)
	end
end

-- 初始玩家
function GamePlayBackLayer:initPlayer()
	local data = self.getPlayerData()

	-- 初始视图
	getChairIdByViewId = InitChairIdByViewId(data)

	for k,v in ipairs(data) do
		if v.dwUserID ~= 0 then
			local viewId = getChairIdByViewId(v.wChairID)
			local userNodeName = string.format("FileNode_%d", viewId) 
			
			local userNode = appdf.getNodeByName(self, userNodeName)
						:setVisible(true)

			local user_avatar = appdf.getNodeByName(userNode, "user_avatar")
			local user_name = appdf.getNodeByName(userNode, "user_name")
						:setString(v.szNickName)
			local score = appdf.getNodeByName(userNode, "score")
						:setString(v.lScore)
			HeadSpriteHelper:initHeadTexture(v, user_avatar, 77)

			if v.dwOwner then
				local icon_roomHolder = appdf.getNodeByName(userNode, "icon_roomHolder")
							:setVisible(true)
			end
		end
	end

	-- 牌数
	local atlas_last = appdf.getNodeByName(self, "atlas_last")
				:setString(0)
	-- 局数
	local atlas_round = appdf.getNodeByName(self, "atlas_round")
				:setString(self.m_roundId)
end

-- 设置庄家
function GamePlayBackLayer:setBankerIcon(chairId, isShow)
	local data = self.getPlayerData()

	for k,v in ipairs(data) do
		if v.wChairID == chairId then
			local viewId = getChairIdByViewId(v.wChairID)
			local userNodeName = string.format("FileNode_%d", viewId) 
			local userNode = appdf.getNodeByName(self, userNodeName)
			
			local banker_icon = appdf.getNodeByName(userNode, "banker_icon")
						:setVisible(isShow)	

			break
		end
	end
end

-- 解析cmd数据
function GamePlayBackLayer:parseCmdDataToTable(chairId ,data)
	local tb = {}
	data = data[1]

	for i = 1, #data do
		local newI = self.getCardDataIndex(data[i])
		if newI ~= 0 then
			table.insert(tb, newI)
		end
	end

	local viewId = getChairIdByViewId(chairId)
	if #tb > 1 then
		return viewId, tb
	end

	return viewId, tb[1]
end


-- 储存玩家的手牌
-- @function addViewCardDataByViewId
-- @param    wOperateUser 椅子
-- @param    cbOperateCard 一组牌 / 单张牌
function GamePlayBackLayer:addCardDataByViewId(viewId, newData)
	local mdata = self.m_tableCards[viewId]
	-- 初始数据
	if mdata == nil then
		self.m_tableCards[viewId] = {}
		mdata = self.m_tableCards[viewId]
	end

	-- 插入
	if type(newData) == "table" then
		for m,n in ipairs(newData) do
			table.insert(mdata, n)
		end
	else
		table.insert(mdata, newData)

		-- 小到大排序
		table.sort(mdata)
		-- 添加单个节点
		self:changeCardsView(viewId, newData, false)
		return
	end

	-- 添加节点
	self:refreshCardsView(viewId)
end


-- 刷新/创建牌
function GamePlayBackLayer:refreshCardsView(viewId)
	local mdata = self.m_tableCards[viewId]

	self.m_tableCardsNode[viewId] = {}
	local mNode = self.m_tableCardsNode[viewId]

	local cardNodeName = string.format("FileNode_%s_sp_card", viewId)
	local cardNode = appdf.getNodeByName(self, cardNodeName)

	-- 特殊牌的占位空间
	local startPos = cardNode:getContentSize()

	local len = #mdata

	local cardNodeName = string.format("FileNode_%s_card", viewId)
	local cardNode = appdf.getNodeByName(self, cardNodeName)
				-- :removeAllChildren()
				
	local x
	local y
	local scale = viewId == 1 and 0.95 or 1

	local nodeCount = cardNode:getChildrenCount()
	if nodeCount < len then

		for i = 1, len - nodeCount do
			local newsp = self.createCardSprite(viewId, 1)
					:setOpacity(100)
					:setVisible(false)
					:setScale(scale)
					:setName("inside")
					
			cardNode:addChild(newsp)
		end
	end

	local childList = cardNode:getChildren()

	for k,v in ipairs(childList) do
		local d = mdata[k]
		local res = self.getCardResourcePath(viewId, d)
		v:setTag(d)
		v:setVisible(true)

		local size = v:getContentSize()

		local pos = getXY(viewId, k, size, scale, startPos)

		v:getChildByName("card_value"):setTexture(res)
		v:setPosition(pos)

		-- 提高渲染层级
		if viewId == 3 then
			cardNode:reorderChild(v, len - k)
		else
			cardNode:reorderChild(v, k)
		end

		v:runAction(cc.FadeIn:create(0.09 * k))

		table.insert(mNode, v)
	end

end

-- 清理玩家特殊牌
function GamePlayBackLayer:cleanSpicialCardsDataAndNode()
	for k,v in pairs(self.m_tableSpicialCards or {}) do
		local cardNodeName = string.format("FileNode_%s_sp_card", k)
		local cardNode = appdf.getNodeByName(self, cardNodeName)
				:setContentSize(0, 0)
				:removeAllChildren()
	end

	self.m_tableSpicialCards = {}
end

-- 清理牌堆
function GamePlayBackLayer:cleanOutViewCardDataAndNode()
	for i = 1, 4 do
		local cardNodeName = string.format("FileNode_%d_out_card", i)
		local cardNode = appdf.getNodeByName(self, cardNodeName)
				:removeAllChildren()
	end
	local node = appdf.getNodeByName(self, "game_pointer")
				:stopAllActions()
				:setVisible(false)	

	local node = appdf.getNodeByName(self, "_animeSprite")
	if node then
		node:stopAllActions()
		node:removeSelf()
	end
				
end

-- 清理手牌
function GamePlayBackLayer:cleanMyCardsDataAndNode()
	for k,v in pairs(self.m_tableCards or {}) do

		local cardNodeName = string.format("FileNode_%s_card", k)
		local cardNode = appdf.getNodeByName(self, cardNodeName)
					:removeAllChildren()
	end
	self.m_tableCards = {}
	self.m_tableCardsNode = {}
end

-- 显示碰杠胡动画
function GamePlayBackLayer:showOperateAnime(viewId, code, isRemove)
	local posACtion = 
	{
		cc.p(667, 230),
		cc.p(260, 420),
		cc.p(1085, 420),
		cc.p(667, 575)
	}

	local strPath = ""
	if code == "WIK_PENG" then
		strPath = strPath.."peng"
	end
	if code == "WIK_GANG" then
		strPath = strPath.."gang"
	end
	if code == "WIK_CHI_HU" then
		strPath = strPath.."hu"
	end

	local animation = cc.Animation:create()
	
	for i = 1, 9 do
		local strPath = resPath.."game/".. strPath ..string.format("/%d.png", i)
		local spriteFrame = cc.Sprite:create(strPath):getSpriteFrame()
		if spriteFrame then
			animation:addSpriteFrame(spriteFrame)
		else
			break
		end
		animation:setLoops(2)
		animation:setDelayPerUnit(0.04)
	end

	local animate = cc.Animate:create(animation)
	local spr = cc.Sprite:create(resPath.."game/".. strPath ..string.format("/%d.png", 1))
			:setName("_animeSprite")
	spr:addTo(self)
	spr:setPosition(posACtion[viewId])

	local removeS = function()
		spr:removeFromParent()
	end

	if isRemove then
		spr:runAction(cc.Sequence:create(animate, cc.CallFunc:create(removeS)))
	else
		spr:runAction(animate)
	end
end

-- 储存玩家的特殊牌
-- @function addSpicialCardsByViewId
-- @param	viewId -> 玩家viewId
-- @param	data -> 特殊牌组
function GamePlayBackLayer:addSpicialCardsByViewId(viewId, data, state, other)
	local mdata = self.m_tableSpicialCards[viewId]
	-- dump(data)
	if mdata == nil then
		self.m_tableSpicialCards[viewId] = {}
		mdata = self.m_tableSpicialCards[viewId]
	end

	-- 特殊牌型 -> 杠
	if state == "WIK_GANG" then

		-- 牌里有没3张碰的
		for i = #mdata, 1, -1 do
			local v = mdata[i]
			if v == nil then break end
			
			-- 第一个值和 牌值相等  并且2 位 3 位 牌值相等 为碰牌
			if v[1] == data and v[3] == data and v[2] == data then
				table.remove(mdata, i)
				break
			end
		end

		local cardGroup = {
			data, data, data,data
		}
		table.insert(mdata, cardGroup)

	elseif state == "WIK_PENG" then
		local cardGroup = {
			data, data, data
		}
		table.insert(mdata, cardGroup)
	end


	self:createSpicialCardsByViewId(viewId)
end

-- 删除特殊牌
-- @function removeSpicialCardsByViewId
-- @param	viewId -> 玩家viewId
-- @param	data -> 牌值
-- @param	cb -> 删除指令时,把牌数返回给cb
function GamePlayBackLayer:removeSpicialCardsByViewId(viewId, data, cb)
	local mdata = self.m_tableSpicialCards[viewId]
	if mdata == nil then
		self.m_tableSpicialCards[viewId] = {}
		mdata = self.m_tableSpicialCards[viewId]
	end


	for i = #mdata, 1, -1 do
		local v = mdata[i]
		if v == nil then break end
		
		-- 第一个值和 牌值相等  并且2 位 3 位 牌值相等
		if v[1] == data and v[3] == data and v[2] == data then

			-- 剩余的手牌
			data = v

			-- 从特殊牌里删除
			table.remove(mdata, i)
			break
		end
	end

	self:createSpicialCardsByViewId(viewId)

	if cb then
		cb(data)
	end
end

-- 生成碰杠牌
function GamePlayBackLayer:createSpicialCardsByViewId(viewId)
	local data = self.m_tableSpicialCards[viewId]
	local groupSpacex = (viewId == 3 and 15 or 25)

	local lastPos = 0

	local cardNodeName = string.format("FileNode_%s_sp_card", viewId)
	local cardNode = appdf.getNodeByName(self, cardNodeName)
				:removeAllChildren()

	for k,v in ipairs(data) do
		for m,n in ipairs(v) do -- 生成牌
			local newsp = self.createCardSprite(viewId, n, "small")

			local size = newsp:getContentSize()
			
			local pos = getXY(viewId, m, size, 1)

			cardNode:addChild(newsp, 1)

			if viewId == 3 then
				cardNode:reorderChild(newsp, #v - m)
			else
				cardNode:reorderChild(newsp, m)
			end

			if viewId == 1 then
				newsp:setPosition(cc.p(lastPos + pos.x, pos.y))
				if m == #v then
					lastPos = lastPos + pos.x + size.width
				end
			elseif viewId == 4 then
				newsp:setPosition(cc.p(lastPos + pos.x, pos.y))

				if m == #v then
					lastPos = lastPos + pos.x - size.width
				end
			elseif viewId == 2 then
				
				newsp:setPosition(cc.p(pos.x, pos.y + lastPos))

				if m == #v then
					lastPos = lastPos + pos.y - size.height / 2
				end

			elseif viewId == 3 then
				newsp:setPosition(cc.p(pos.x, pos.y + lastPos))
				
				if m == #v then
					lastPos = lastPos + pos.y + size.height / 2
				end
			end
		end
	end

	if viewId == 1 or viewId == 4 then
		cardNode:setContentSize(lastPos, 0)
	elseif viewId == 2 or viewId == 3 then
		cardNode:setContentSize(0, lastPos)
	end
end

-- 将指针移动到指定位置
function GamePlayBackLayer:movePointerToPosition(ccp)
	local pointer = appdf.getNodeByName(self, "game_pointer")
	
	if pointer:isVisible() == false then
		pointer:setVisible(true)
	end
	pointer:stopAllActions()

	ccp.y = ccp.y + 18

	pointer:move(ccp)

	pointer:runAction(
		cc.RepeatForever:create(
			cc.JumpBy:create(2, cc.p(0,0), 15, 2)
		)
	)
end


-- 在牌堆后面添加手牌
-- @function addOutViewCardByViewId
-- @param    chairId 椅子
-- @param    data 
function GamePlayBackLayer:addOutViewCardByViewId(viewId, data)
	local mod = function(a, b)
		return 	a - math.floor(a / b) * b
	end

	local cardNodeName = string.format("FileNode_%d_out_card", viewId)
	local cardNode = appdf.getNodeByName(self, cardNodeName)
				-- :removeAllChildren()
	
	local childLen = cardNode:getChildrenCount() + 1
	local len	
	local spName = string.format("_out_%d_%d", viewId, data)
	local newsp = self.createCardSprite(viewId, data, "small")
				:setName(spName)
				:setTag(data)

				
	local x
	local y
	local scale = 1

	local size = newsp:getContentSize()

	if viewId == 1 then 
		size.height = size.height - 13
	elseif viewId == 4 then
		size.height = size.height - 12
	end

	-- 是否换行
	local lineCount = math.ceil(childLen / 11)
		
	if lineCount > 1 then
		len = mod(childLen, 11)

		if len == 0 then
			len = 11
		end
	end

	local pos = getXY(viewId, len or childLen, size, scale)

	-- 换行偏移
	if lineCount > 1 then
		lineCount = lineCount - 1
		if viewId == 1 then
			pos.y = pos.y - (size.height * lineCount)
		elseif viewId == 2 then
			pos.x = pos.x - (size.width * lineCount)
		elseif viewId == 3 then
			pos.x = pos.x + (size.width * lineCount)
		elseif viewId == 4 then
			pos.y = pos.y + (size.height * lineCount)
		end
	end

	newsp:setPosition(pos)

	cardNode:addChild(newsp, ((viewId == 4 or viewId == 3) and -childLen or childLen))

	-- 指针
	local nodeSpacePos = cardNode:convertToWorldSpaceAR(pos)

	self:movePointerToPosition(nodeSpacePos)
end

-- 移除牌堆最后一张牌
-- @function removeOutViewCard
-- @param    viewId  视图id
function GamePlayBackLayer:removeOutViewCard(viewId, data, isAnime)
	local cardNodeName = string.format("FileNode_%d_out_card", viewId)
	local cardNode = appdf.getNodeByName(self, cardNodeName)
				-- :removeAllChildren()
	local spName = string.format("_out_%d_%d", viewId, data)

	local childList = cardNode:getChildren()
	local pointer = appdf.getNodeByName(self, "game_pointer")

	

	for i = #childList, 1, -1 do
		local v = childList[i]
		if v then
			local tmpName = v:getName()
			if tmpName == spName then

				local removeFuc = function()
					v:removeSelf()
					pointer:stopAllActions()
					pointer:setVisible(false)
				end

				if isAnime == nil then
					-- 动画删除
					v:runAction(
						cc.Sequence:create(
							cc.FadeOut:create(0.2),
							cc.CallFunc:create(removeFuc)
						)
					)
				else
					v:removeSelf()
					pointer:stopAllActions()
					pointer:setVisible(false)
				end


				break
			end
		end
	end
end

-- 移除手牌
function GamePlayBackLayer:removeCardsData(viewId, newData, state)
	local mdata = self.m_tableCards[viewId]

	if type(newData) == "table" then
		for m,n in ipairs(newData) do
			for i = #mdata, 1, -1 do
				local v = mdata[i]
				if v == nil then break end

				if n == v then
					table.remove(mdata, i)
					if state == nil then
						break
					end
					-- break					
				end
			end
		end
	else
		for i = #mdata, 1, -1 do
			local v = mdata[i]
			if v == nil then break end

			if v == newData then

				table.remove(mdata, i)
				if state == nil then
					break
				end
			end				
		end
	end

	self:changeCardsView(viewId, newData, true, CHANGE_CARD_TYPE.REVERT, state)
end

-- 刷新手牌
-- @param viewId -> 视图位置
-- @param cardValue -> 牌值
-- @param isRemove -> 是否移除
-- @param moveType -> 刷新动画
function GamePlayBackLayer:changeCardsView(viewId, cardValue, isRemove, moveType, state)
	
	local mdata = self.m_tableCards[viewId]

	local nodeList = self.m_tableCardsNode[viewId]

	local len = #mdata
	local removeIndex

	-- 特殊牌
	local cardNodeName = string.format("FileNode_%s_sp_card", viewId)
	local cardNode = appdf.getNodeByName(self, cardNodeName)
	-- 特殊牌的占位空间
	local startPos = cardNode:getContentSize()

	-- 牌堆
	local outCardNodeName = string.format("FileNode_%d_out_card", viewId)
	local outCardNode = appdf.getNodeByName(self, outCardNodeName)

	-- 手牌
	local cardNodeName = string.format("FileNode_%s_card", viewId)
	local cardNode = appdf.getNodeByName(self, cardNodeName)

	-- 节点添加删除操作
	local fuc1 = function()
		-- 移除节点数据
		if isRemove == true then
			if type(cardValue) == "table" then
				for m,n in ipairs(cardValue) do
					
					for i = #nodeList, 1, -1 do
						local v = nodeList[i]
						if v == nil then break end

						local nodeValue = v:getTag()

						if n == nodeValue then
							removeIndex = i

							v:removeSelf()

							-- 移除
							table.remove(nodeList, i)

							if state == nil then
								break
							end
						end

					end

				end
			else
				for i = #nodeList, 1, -1 do
					local v = nodeList[i]
					if v == nil then break end

					local nodeValue = v:getTag()
					if cardValue == nodeValue then

						removeIndex = i

						
						v:removeSelf()

						-- 移除
						table.remove(nodeList, i)
						if state == nil then
							break
						end
					end

				end
			end

	
		-- 添加节点数据
		elseif isRemove == false then

			local x
			local y
			local scale = viewId == 1 and 0.95 or 1

			local newsp = self.createCardSprite(viewId, cardValue)
					:setScale(scale)
					:setTag(cardValue)
					:setName("outside")

			local size = newsp:getContentSize()

			pos = getXY(viewId, len, size, scale, startPos)
			
			if viewId == 1 or viewId == 4 then
				pos.x = pos.x + (viewId == 4 and -30 or 30)
			elseif viewId == 2 or viewId == 3 then
				pos.y = pos.y + (viewId == 2 and -30 or 30)
			end

			newsp:setPosition(pos)

			table.insert(nodeList, newsp)

			cardNode:addChild(newsp)

			-- 提高渲染层级
			if viewId == 3 then
				cardNode:reorderChild(newsp, 0)
			end

		end
	end
	

	-- 将牌包括右边摸的牌 重组排列动画
	local fuc2 = function()
		local x
		local y
		local scale = viewId == 1 and 0.95 or 1
		local outCard = appdf.getNodeByName(cardNode, "outside")
		local outCardValue
		if outCard then
			outCardValue = outCard:getTag()
		end
		local curIndex

		for k,v in ipairs(nodeList) do

			local name = v:getName()

			local size = v:getContentSize()
			local pos

			local cardValue = mdata[k]
			
			-- 这个被移除的牌 坐标 将是outcard的
			if curIndex == nil and cardValue == outCardValue then
				-- 记录这个坐标
				curIndex = k
			end


			if name == "inside" then
				if curIndex ~= nil then
					cardValue = mdata[k + 1]
					pos = getXY(viewId, k + 1, size, scale, startPos)
				else
					pos = getXY(viewId, k, size, scale, startPos)
				end
				
				local cardDataRes = self.getCardResourcePath(viewId, cardValue)
				
				v:setName("inside")
	
				local sp = v:getChildByName("card_value")
						:setTexture(cardDataRes)
	
				v:setPosition(pos)

				-- 提高渲染层级
				if viewId == 3 then
					v:getParent():reorderChild(v, len - k)
				else
					v:getParent():reorderChild(v, k)
				end
						
			else
				local cardDataRes = self.getCardResourcePath(viewId, cardValue)
				
				v:setName("inside")
				
				local fpos

				pos = getXY(viewId, curIndex, size, scale, startPos)

				if viewId == 1 then
					fpos = cc.p(pos.x, pos.y + 60)
				elseif viewId == 2 then
					fpos = cc.p(pos.x + 60, pos.y)
				elseif viewId == 3 then
					fpos = cc.p(pos.x - 60, pos.y)
				elseif viewId == 4 then
					fpos = cc.p(pos.x, pos.y - 60)
				end

				local cardDataRes = self.getCardResourcePath(viewId, mdata[curIndex])

				local sp = v:getChildByName("card_value")
						:setTexture(cardDataRes)
				
				local reorderZ = function()
					if viewId == 3 then
						v:getParent():reorderChild(v, len - curIndex)
					else
						v:getParent():reorderChild(v, curIndex - 1)
					end
				end

				-- 自动播放时才有动画
				if self.m_videoState == "play" then
					v:runAction(
						cc.Sequence:create(
							cc.MoveBy:create(0.2, cc.p(0, 50)),
							cc.Spawn:create(
								cc.MoveTo:create(0.2, cc.p(fpos.x, fpos.y)),
								cc.RotateTo:create(0.1, viewId == 1 and 45 or 0)
							),
							cc.Spawn:create(
								cc.RotateTo:create(0.1, 0),
								cc.MoveTo:create(0.2, pos),
								cc.CallFunc:create(reorderZ)
							)
						)
					)
				else
					reorderZ()
					v:setPosition(pos)
				end
			end
		end
	end

	fuc1()

	-- 排序动画   重排动画 /置左动画 
	if moveType == CHANGE_CARD_TYPE.REVERT then
		fuc2()
	end
end

return GamePlayBackLayer