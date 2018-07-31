--------------------------------
-- @module UITableView

--[[--

UITableView控件

]]

local UITableView = class("UITableView", function()
	local node = display.newNode()
	return node
end)

function UITableView:onExit()
	if self.m_checkScrollingFuc then
		display.unscheduleGlobal(self.m_checkScrollingFuc)
	end

	return self
end

-- start --

--------------------------------
-- UITableView构建函数
-- @function [parent=#UITableView] new
-- @param table params 参数表

--[[--

UITableView构建函数

可用参数有：

-   SCROLLVIEW_DIRECTION        滚动方向  cc.SCROLLVIEW_DIRECTION_HORIZONTAL
-   TABLEVIEW_FILL              排列方式  cc.TABLEVIEW_FILL_TOPDOWN
-   viewRect                    cc.rect
-	interval					间隔
-   createCell                  tableview cell 创建
-   getCellCount                tableview cell 个数
-   getCellSize                 tableview cell size

]]


--[[
	创建示例代码

	local m_tableview = ccui.UITableView:create({
            viewRect = cc.rect(670, 293.91, 1210, 525),
            direction = cc.SCROLLVIEW_DIRECTION_VERTICAL,
            fill = cc.TABLEVIEW_FILL_TOPDOWN,
            interval = 8,
            createCell = handler(self, self.createList),
            getCellCount = function()
                return 3
            end,
            getCellSize = function()
                return 100, 100
            end
    })
]]


-- 小bug 在禁止边界时会不刷新视图  movecount = 1
-- 横向视图 禁止边界功能上不完整

-- end --

local init = function(value)
	local mValue = value

	local get = function( value )
		if value then
			value = mValue + value
			return value
		end

		return mValue
	end

	return get
end

local initTable = function(value)
	local m_tb = {}

	local set = function(value)
		if value then
			table.insert(m_tb, value)
		end
	end

	local get = function()
		return m_tb
	end

	local remove = function(value)
		if value then
			for i = #m_tb, 1, -1 do
				local v = m_tb[i]
				if v == value then
					table.remove(m_tb, i)
					break
				end
			end
		end
	end

	return set, get, remove
end

-- 触摸状态
local TouchEventType = {
	BEGAN = 1,
	MOVE = 2,
	END = 3,
}

-- 刷新状态
local RefreshState = {
	TOP = 1,
	BOTTOM = 2,
}

-- 禁止边界状态
local BounceState = {
	TOP = "scrollTop",
	BOTTOM = "scrollBottom",
	LEFT = "scrollLeft",
	RIGHT = "scrollRight",
}

function UITableView:ctor(params)

	self.viewRect_ = params.viewRect or cc.rect(0, 0, display.width, display.height)
	self.direction_ = params.direction or cc.SCROLLVIEW_DIRECTION_NONE
	self.fill_ = params.fill or cc.TABLEVIEW_FILL_TOPDOWN
	self.interval_ = params.interval or {}

	local override = params.override or false
	self.createCell_ = params.createCell or nil
	self.getCellCount_ = params.getCellCount or nil
	self.getCellSize_ = params.getCellSize or nil


	-- 响应时间
	self.echoTime_ = 0.1
	-- 移动误触阀值
	self.refreshValue_ = 1
	-- 是否达到刷新距离
	self.isMoveDistance_ = false
	-- 触摸状态
	self.touchState_ = 0
	-- 滚动状态
	self.m_isStopScroll = true

	-- 上下拉状态
	self.ultraState_ = 0
	-- 上下刷新
	self.ultraTop_ = false
	self.ultraBottom_ = false

	-- 边界禁止滑动
	self.setBounceState_ ,self.getBounceState_, self.removeBounceState_ = initTable()
	
	self:registerScriptHandler(function(eventType)
		if eventType == "exit" then
			self:onExit()
		end
	end)

	self:setContentSize(self.viewRect_.width, self.viewRect_.height)
	self:setAnchorPoint(0.5, 0.5)
	self:setPosition(cc.p(self.viewRect_.x, self.viewRect_.y))
	
	self:addNodeEventListener(cc.NODE_TOUCH_EVENT, function (event)
		return self:onTouch_(event)
	end)

	self:setTouchEnabled(true)
	
	self.args_ = {params}

	
	local tableView = cc.TableView:create(cc.size(self.viewRect_.width, self.viewRect_.height))
	tableView:setDirection(self.direction_)
	tableView:setAnchorPoint(0, 0)
	tableView:setPosition(cc.p(0, 0))
	tableView:setVerticalFillOrder(self.fill_)
	tableView:setDelegate()

	tableView:registerScriptHandler(handler(self, self.cellViewSize_), cc.TABLECELL_SIZE_FOR_INDEX)

	-- 是否重写
	if override == false then
		tableView:registerScriptHandler(handler(self, self.createCellView_), cc.TABLECELL_SIZE_AT_INDEX)
	else
		tableView:registerScriptHandler(self.createCell_, cc.TABLECELL_SIZE_AT_INDEX)
	end

	tableView:registerScriptHandler(handler(self, self.cellViewCount_), cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
	
	self:addChild(tableView)

	-- 包围盒
	self.m_tableBox = tableView:getBoundingBox()

	self.m_tableview = tableView


	self.m_createCell = function(view, idx)
		local cell = view:dequeueCell()
    
		local item
	
		if cell == nil then        
			cell = cc.TableViewCell:new()
		else
			item = appdf.getNodeByName(cell, "_UICellItem")
		end
	
		local idx = idx + 1
		
		if item == nil then
			item = self.clone_item:clone()
			item:setAnchorPoint(0, 0)
			item:setPosition(0,0)
			cell:addChild(item)
		end
		
		item:setTag(idx)

		local bindData = function()
			if self.createCell_ then
				self.createCell_(cell, item, idx)
			end

			return cell
		end

		local getDefView = function()
			return cell
		end

		return bindData, getDefView
	end
end

-- TableView实例
function UITableView:getTableView()
	return self.m_tableview or nil
end

function UITableView:setTableViewTouchEnabled(enb)
	self.m_tableview:setTouchEnabled(enb)
	return self
end

function UITableView:setMainTouchEnabled(enb)
	self:setTouchEnabled(enb)
	return self
end

-- 滚动完成的响应时间
function UITableView:setEchoTime(time)

	if type(time) ~= "number" then
		time = tonumber(time)
	end

	self.echoTime_ = time
end

-- 移动误触阀值
function UITableView:setRefreshValue(value)

	if type(value) ~= "number" then
		value = tonumber(value)
	end

	self.refreshValue_ = value
end

-- 克隆对象
function UITableView:setCloneCellItem(item)
	self.clone_item = item
	self.clone_item:setName("_UICellItem")
	self.m_cellSize = self.clone_item:getContentSize()

	if self.direction_ == cc.SCROLLVIEW_DIRECTION_HORIZONTAL then

		-- 间隔
		self.m_cellSize.width = self.m_cellSize.width + self.interval_

	elseif self.direction_ == cc.SCROLLVIEW_DIRECTION_VERTICAL then
		-- 间隔
		self.m_cellSize.height = self.m_cellSize.height + self.interval_

	end

	
	return self
end

-- cell宽高
function UITableView:cellViewSize_(view, idx)
	if self.getCellSize_ then
		return self.getCellSize_(view, idx)
	end

	return self.m_cellSize.width, self.m_cellSize.height
end

-- cell个数
function UITableView:cellViewCount_(view)
	if self.getCellCount_ then
		return self.getCellCount_(view)
	end
	return 0
end

-- 创建cell
-- @tips 实现多模版创建 重写该函数createCellView_
function UITableView:createCellView_(view, idx)
	
	local bindData, defModel = self.m_createCell(view, idx)
	-- if self.m_isStopScroll == false then
	-- 	return defModel()
	-- else
		return bindData()
	-- end
end

-- 更新视图
function UITableView:updateView()
	-- if self.clone_item == nil then
	-- 	print("plz call setCloneCellItem first!")
	-- 	return 
	-- end


	self.m_isRefreshView = true
	self.m_tableview:reloadData()


	-- 初始移动边界
	if self.direction_ == cc.SCROLLVIEW_DIRECTION_HORIZONTAL then


		-- 右边边界计算 不完善
		self.m_leftlimit = self.m_tableview:getContentOffset().x
		local showCount = math.floor(self.viewRect_.width / self.m_cellSize.width)
		self.m_rightlimit = (self.getCellCount_() - showCount) * self.m_cellSize.width

	elseif self.direction_ == cc.SCROLLVIEW_DIRECTION_VERTICAL then
		
		
		local now_height = self.m_tableview:getContentSize().height
		
		if now_height <= self.viewRect_.height then
			self.isFullArea_ = false
		else
			self.isFullArea_ = true
		end
		
		self.m_toplimit = self.m_tableview:getContentOffset().y
		self.m_bottomlimit = 0

		if self.ultraBottom_ then
			self.ultraBottomDistance_ = self.getUltraBottomDistance_()
		end
		
		if self.ultraTop_ then
			self.ultraTopDistance_ = self.getUltraTopDistance_(self.m_toplimit)
		end
		
	end

	self.m_isRefreshView = false


	return self
end

-- 移动视图
function UITableView:moveToOffset_(ccp, isAnima)
	self.m_isRefreshView = true
	self.m_tableview:stopAllActions()
	self.m_tableview:setContentOffset(ccp, isAnima)
	self.m_isRefreshView = false
	return self
end

function UITableView:isTouchInViewRect_(event, rect)
	rect = rect or self.m_tableBox
	local viewRect = self:convertToWorldSpace(cc.p(rect.x, rect.y))
	viewRect.width = rect.width
	viewRect.height = rect.height

	return cc.rectContainsPoint(viewRect, cc.p(event.x, event.y))
end

function UITableView:onTouch_(event)
	if "began" == event.name
		and not self:isTouchInViewRect_(event) then
		printInfo("UITableView - touch didn't in viewRect")
		return false
	end

	if "began" == event.name then
		if self.m_isRefreshView == false then
			self.m_touchEnb = true
			-- self.m_bounceState = nil
		end
		self.touchState_ = TouchEventType.BEGAN

	elseif "moved" == event.name then

		self.touchState_ = TouchEventType.MOVE




	elseif "ended" == event.name then
		self.touchState_ = TouchEventType.END
	
	end
	return true
end

-- 顶部边界
function UITableView:setTopBounceEnable(enb)
	-- if self.m_initScroll ~= true then
	-- 	dump("error: call initScrollHanlder first!")
	-- 	return
	-- end
	if enb == true then
		self.setBounceState_(BounceState.TOP)
	elseif enb == false then
		self.removeBounceState_(BounceState.TOP)
	end
	return self
end

-- 底部边界
function UITableView:setBottomBounceEnable(enb)
	-- if self.m_initScroll ~= true then
	-- 	dump("error: call initScrollHanlder first!")
	-- 	return
	-- end
	if enb == true then
		self.setBounceState_(BounceState.BOTTOM)
	elseif enb == false then
		self.removeBounceState_(BounceState.BOTTOM)
	end
	return self
end

-- 左边边界
function UITableView:setLeftBounceEnable(enb)
	-- if self.m_initScroll ~= true then
	-- 	dump("error: call initScrollHanlder first!")
	-- 	return
	-- end
	if enb == true then
		self.setBounceState_(BounceState.LEFT)
	elseif enb == false then
		self.removeBounceState_(BounceState.LEFT)
	end
	return self
end

-- 右边边界
function UITableView:setRightBounceEnable(enb)
	-- if self.m_initScroll ~= true then
	-- 	dump("error: call initScrollHanlder first!")
	-- 	return
	-- end
	if enb == true then
		self.setBounceState_(BounceState.RIGHT)
	elseif enb == false then
		self.removeBounceState_(BounceState.RIGHT)
	end
	return self
end

-- 设置下拉刷新
function UITableView:setUltraTopDistanceRefresh(enb)
	if cc.SCROLLVIEW_DIRECTION_VERTICAL ~= self.direction_ then return end
	
	self.ultraTop_ = enb
	return self
end

-- 设置往下拉距离
function UITableView:setUltraTopDistance(offset)
	if self.ultraTop_ == false then
		dump("error: set setUltraTopDistanceRefresh first!")
		return
	end

	if type(offset) ~= "number" then
		offset = tonumber(offset)
	end

	self.getUltraTopDistance_ = init(- offset)
	return self
end

-- 往下拉监听
function UITableView:setUltraTopCallBack(cb)
	self.m_ultraTopCallBack = cb
	return self
end

-- 设置上拉加载
function UITableView:setUltraBottomDistanceRefresh(enb)
	if cc.SCROLLVIEW_DIRECTION_VERTICAL ~= self.direction_ then return end

	self.ultraBottom_ = enb
	return self
end

-- 设置往上拉距离
function UITableView:setUltraBottomDistance(offset)
	if self.ultraBottom_ == false then
		dump("error: set setUltraBottomDistanceRefresh first!")
		return
	end

	if type(offset) ~= "number" then
		offset = tonumber(offset)
	end

	self.getUltraBottomDistance_ = init(offset)
	
	return self
end

-- 往上拉监听
function UITableView:setUltraBottomCallBack(cb)
	self.m_ultraBottomCallBack = cb
	return self
end

-- 整个item点击监听
function UITableView:setItemTouchCallBack(cb)
	self.m_touchListener = cb

	-- end 第一个监听 点中item
	self.m_tableview:registerScriptHandler(function(v, c)
		
		if self.m_touchListener then
			-- 返回点击下标
			-- c -> cell
			self.m_touchListener(c:getIdx() + 1, c)

		end
		-- dump(self.m_tableview:getContentOffset())
		-- self.touchState_ = TouchEventType.END
		
	end, cc.TABLECELL_TOUCHED)

	-- -- end 第二个监听 没点中item
	-- self.m_tableview:registerScriptHandler(function(v, c)
	-- 	self.touchState_ = TouchEventType.END
	-- end, cc.TABLECELL_UNHIGH_LIGHT)
	

	-- self:setTouchBeganListener_()

	return self
end

-- 如果设置itemTouch 则使用该函数来开启滚动检测
function UITableView:setTouchBeganListener_()

	-- 注册tableview touchBegan监听
	-- self.m_tableview:registerScriptHandler(function(v, c)

	-- 	if self.m_isRefreshView == false then
	-- 		self.m_touchEnb = true
	-- 		self.m_bounceState = nil
	-- 	end
	-- 	self.touchState_ = TouchEventType.BEGAN
		
	-- end, cc.TABLECELL_HIGH_LIGHT)

	-- 关闭node自身的监听
	-- self:setTouchEnabled(false)
end

-- 滚动中监听
function UITableView:setScrollingCallBack(cb)
	-- if self.m_initScroll ~= true then
	-- 	dump("error: call initScrollHanlder first!")
	-- 	return
	-- end
	self.m_scrollingListener = cb
	return self
end

-- 滚动完成监听
function UITableView:setScrollEndCallBack(cb)
	-- if self.m_initScroll ~= true then
	-- 	dump("error: call initScrollHanlder first!")
	-- 	return
	-- end
	self.m_scrollEndListener = cb
	return self
end

-- 滚动到顶部监听
function UITableView:setScrollToTopCallBack(cb)
	-- if self.m_initScroll ~= true then
	-- 	dump("error: call initScrollHanlder first!")
	-- 	return
	-- end
	self.m_scrollToTopListener = cb
	return self
end

-- 滚动到底部监听
function UITableView:setScrollToBottomCallBack(cb)
	-- if self.m_initScroll ~= true then
	-- 	dump("error: call initScrollHanlder first!")
	-- 	return
	-- end
	self.m_scrollToBottomListener = cb
	return self
end

-- 滚动到最左边监听
function UITableView:setScrollToLeftCallBack(cb)
	-- if self.m_initScroll ~= true then
	-- 	dump("error: call initScrollHanlder first!")
	-- 	return
	-- end
	self.m_scrollToLeftListener = cb
	return self
end

-- 滚动到最右边监听
function UITableView:setScrollToRightCallBack(cb)
	-- if self.m_initScroll ~= true then
	-- 	dump("error: call initScrollHanlder first!")
	-- 	return
	-- end
	self.m_scrollToRightListener = cb
	return self
end

-- 通知
function UITableView:notifyListener_(name, contentOffset)
	-- dump(name)
	
	if name == "scrolling" then
		if self.m_scrollingListener then
			self.m_scrollingListener(self.m_tableview)
		end
	elseif name == "scrollEnd" then
		if self.m_scrollEndListener then
			self.m_scrollEndListener(self.m_tableview)
		end

	-- 触碰边界状态
	elseif self.m_bounceState == nil then		-- 防止多次通知
		if name == "scrollTop" then
			if self.m_scrollToTopListener then
				self.m_scrollToTopListener(self.m_tableview)
			end 
		elseif name == "scrollBottom" then
			if self.m_scrollToBottomListener then
				self.m_scrollToBottomListener(self.m_tableview)
			end 
		elseif name == "scrollLeft" then
			if self.m_scrollToLeftListener then
				self.m_scrollToLeftListener(self.m_tableview)
			end 
		elseif name == "scrollRight" then
			if self.m_scrollToRightListener then
				self.m_scrollToRightListener(self.m_tableview)
			end
		end
	end

	
	-- 特殊处理

	-- 边界区间
	if contentOffset and self.m_toplimit and contentOffset < self.m_toplimit
		and self.ultraTop_ == true then
			-- 下拉
			self:checkUltraTopDistance_(contentOffset)
	elseif contentOffset and self.m_bottomlimit and contentOffset > self.m_bottomlimit
		and self.ultraBottom_ == true and self.isFullArea_ == true then
			
			-- 上拉
			self:checkUltraBottomDistance_(contentOffset)
	-- elseif (self.ultraBottom_ == false or self.ultraTop_ == false) and self.ultraState_ == 0 then
	elseif self.ultraState_ == 0 then
		-- 边界禁止滚动
		for k,v in ipairs(self.getBounceState_()) do
			if v == name then
				self:disabledBounce_(name)
			end
		end
	end
	
end

-- 边界禁止滚动
function UITableView:disabledBounce_(name)
	self.m_bounceState = 1
	if self.isFullArea_ == false then
		if self.direction_ == cc.SCROLLVIEW_DIRECTION_HORIZONTAL then
			name = "scrollRight"

		elseif self.direction_ == cc.SCROLLVIEW_DIRECTION_VERTICAL then
			name = "scrollTop"
		end
	end

	if name == "scrollTop" then
		self:moveToOffset_(cc.p(0, self.m_toplimit), false)
		
	elseif name == "scrollBottom" then
		self:moveToOffset_(cc.p(0, self.m_bottomlimit), false)
		
	elseif name == "scrollRight" then
		
		self:moveToOffset_(cc.p(self.m_rightlimit, 0), false)
		
	elseif name == "scrollLeft" then
		self:moveToOffset_(cc.p(self.m_leftlimit, 0), false)
		
	else
		self.m_bounceState = nil
	end
end

-- 通知下拉处理逻辑
function UITableView:notifyUltraTopListener()

	if self.m_ultraTopCallBack == nil then
		return
	end
	
	-- 通知已上拉
	self.m_ultraTopCallBack(function()
		
		self:updateView()

	end)
	
end


-- 通知上拉处理逻辑
function UITableView:notifyUltraBottomListener()

	if self.m_ultraBottomCallBack == nil then
		return
	end
	
	local cellViewCount = self:cellViewCount_()
	
	-- 通知已上拉
	self.m_ultraBottomCallBack(function()
		local curOffset = {x = 0, y = 0}
		
		local newCellViewCount = self:cellViewCount_()
		
		self:updateView()

		-- 没有变化
		if cellViewCount == newCellViewCount then
			return self:moveToOffset_(curOffset, false)
		else
			local curIndex = (cellViewCount - (newCellViewCount / 2) * 2 + 1)

			-- 记录当前位置
			curOffset.y = curIndex * self.m_cellSize.height

			return self:moveToOffset_(curOffset, false)
		end

	end)
end

-- 下拉处理  上往下
function UITableView:checkUltraTopDistance_(contentOffset)
	-- 移动状态
	if self.touchState_ == TouchEventType.MOVE then
		-- 是否已超过上拉距离
		if self.isMoveDistance_ == true then
			-- 小于下拉距离
			if contentOffset > self.ultraTopDistance_ then
				self.isMoveDistance_ = false
				self.ultraState_ = 0
			end
		end
	elseif self.touchState_ == TouchEventType.END then
		if self.isMoveDistance_ == false then
			if contentOffset < self.ultraTopDistance_ then
				self.isMoveDistance_ = true
				self.ultraState_ = RefreshState.TOP
			end
		end


		-- 锁位置/修正位置 
		if self.isMoveDistance_ == true then
			self:moveToOffset_(cc.p(0, self.ultraTopDistance_), false)
		end

	end

end

-- 上拉处理 下往上
function UITableView:checkUltraBottomDistance_(contentOffset)
	-- 移动状态
	if self.touchState_ == TouchEventType.MOVE then
		-- 是否已超过下拉距离
		if self.isMoveDistance_ == true then
			-- 小于下拉距离
			if contentOffset < self.ultraBottomDistance_ then
				self.isMoveDistance_ = false
				self.ultraState_ = 0
			end
		end
	elseif self.touchState_ == TouchEventType.END then
		if self.isMoveDistance_ == false then
			if contentOffset > self.ultraBottomDistance_ then
				self.isMoveDistance_ = true
				self.ultraState_ = RefreshState.BOTTOM
			end
		end


		-- 锁位置/修正位置 
		if self.isMoveDistance_ == true then
			self:moveToOffset_(cc.p(0, self.ultraBottomDistance_), false)
		end

	end

end

-- 注册滚动监听
function UITableView:initScrollHanlder()
	if self.m_initScroll == true then return end

	self.m_initScroll = true

	self.m_tableview:registerScriptHandler(function()
		-- 刷新视图中
		if self.m_isRefreshView == true then return end

		-- 视图偏移值
			
		if self.direction_ == cc.SCROLLVIEW_DIRECTION_HORIZONTAL then
			local contentOffset = self.m_tableview:getContentOffset().x
			
			if contentOffset > 0 then
				self:notifyListener_("scrollRight", contentOffset)
			elseif contentOffset < self.m_leftlimit then
				self:notifyListener_("scrollLeft", contentOffset)
			else
				self.m_bounceState = nil
			end
		elseif self.direction_ == cc.SCROLLVIEW_DIRECTION_VERTICAL then
			local contentOffset = self.m_tableview:getContentOffset().y
			
			if contentOffset > 0 and self.isFullArea_ == true then
				self:notifyListener_("scrollBottom", contentOffset)
			elseif contentOffset < self.m_toplimit then
				self:notifyListener_("scrollTop", contentOffset)
			else
				self.m_bounceState = nil
			end
		end

		-- 触碰边界状态
		-- 如果在边界中不响应滚动
		if self.m_bounceState == nil then
			self:notifyListener_("scrolling", contentOffset)

			if self.m_isStopScroll then
				self.m_isStopScroll = false
			end

			self.m_moveCount = self.m_moveCount + 1
		end
		
	end, cc.SCROLLVIEW_SCRIPT_SCROLL)

	-- 上次移动计数
	self.m_lastMoveCount = 0

	-- 总移动计数
	self.m_moveCount = 0

	-- 停止移动计数
	self.m_stopScrollCount = 0

	-- 开启滚动检测
	self.m_touchEnb = false

	-- 停止滚动
	self.m_isStopScroll = true

	self.m_checkScrollingFuc = display.scheduleGlobal(function()
		-- 开启了检测
		if self.m_touchEnb == true then
			-- dump(self.m_touchEnb)
			-- 当前移动计数 与 上次计数相同
			if self.m_moveCount == self.m_lastMoveCount then

				-- 可能暂停滚动了
				-- 计数
				if self.m_stopScrollCount >= 2 then

					-- 移动过
					if self.m_moveCount > 0 then
						self:notifyListener_("scrollEnd")
					end

					-- 已停止滚动
					self.m_isStopScroll = true

					-- 已放开触摸
					if self.touchState_ == TouchEventType.END then
						-- 关闭检测
						self.m_touchEnb = false
					end

					-- 大于误操作值     /下拉锁位置时 不刷新    /还原位置时刷新
					if self.m_moveCount > self.refreshValue_ and self.isMoveDistance_ == false then
						-- 当前内容位置
						local curOffset = self.m_tableview:getContentOffset()
						self:updateView()
						-- 还原位置
						self:moveToOffset_(curOffset, false)
					end

					-- 触发
					if self.isMoveDistance_ == true then
						self.isMoveDistance_ = false

						-- 触发刷新状态
						if self.ultraState_ == RefreshState.BOTTOM then
								
							self:notifyUltraBottomListener()
								
						elseif self.ultraState_ == RefreshState.TOP then

							self:notifyUltraTopListener()

						end
						self.ultraState_ = 0
					end

					-- 清零
					self.m_moveCount = 0
					self.m_lastMoveCount = 0
					self.m_stopScrollCount = 0
					
				else
					self.m_stopScrollCount = self.m_stopScrollCount + 1
				end
			else
				-- 还在滚动中
				self.m_lastMoveCount = self.m_moveCount
			end
		end
	end, self.echoTime_)

	return self
end

-- 反注册滚动监听
function UITableView:unRegisterScrollHanlder()
	self.m_initScroll = false

	self.m_tableview:unregisterScriptHandler(cc.SCROLLVIEW_SCRIPT_SCROLL)
	if self.m_checkScrollingFuc then
		display.unscheduleGlobal(self.m_checkScrollingFuc)
	end
end

return UITableView