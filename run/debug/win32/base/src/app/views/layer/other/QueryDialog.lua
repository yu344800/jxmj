--[[
	询问对话框
		2016_04_27 C.P
	功能：确定/取消 对话框 与用户交互
]]
local QueryDialog = class("QueryDialog", function(msg,callback)
		local queryDialog = cc.LayerColor:create(cc.c4b(0,0,0,0))
    return queryDialog
end)

--默认字体大小
QueryDialog.DEF_TEXT_SIZE 	= 28

--UI标识
QueryDialog.DG_QUERY_EXIT 	=  2 
QueryDialog.BT_CANCEL		=  0   
QueryDialog.BT_CONFIRM		=  1


-- 对话框类型
QueryDialog.QUERY_SURE 			= 1
QueryDialog.QUERY_SURE_CANCEL 	= 2
QueryDialog.QUERY_AGGRE_ORNO 	= 3 	--拒绝  同意
QueryDialog.QUERY_WAIT_REPLY 	= 4 	--等待

-- 进入场景而且过渡动画结束时候触发。
function QueryDialog:onEnterTransitionFinish()
    return self
end

-- 退出场景而且开始过渡动画时候触发。
function QueryDialog:onExitTransitionStart()
	if self._lastScheduler then
		display.unscheduleGlobal(self._lastScheduler)
		self._lastScheduler = nil
	end

	self:unregisterScriptTouchHandler()
    return self
end

--窗外触碰
function QueryDialog:setCanTouchOutside(canTouchOutside)
	self._canTouchOutside = canTouchOutside
	return self
end

--msg 显示信息
--callback 交互回调
--txtsize 字体大小
function QueryDialog:ctor(msg, callback, txtsize, queryType, argc)
	queryType = queryType or QueryDialog.QUERY_SURE_CANCEL
	self._callback = callback
	self._canTouchOutside = true

	self:setContentSize(appdf.WIDTH,appdf.HEIGHT)
	self:move(0, 0)

	--回调函数
	self:registerScriptHandler(function(eventType)
		if eventType == "enterTransitionFinish" then	-- 进入场景而且过渡动画结束时候触发。
			self:onEnterTransitionFinish()
		elseif eventType == "exitTransitionStart" then	-- 退出场景而且开始过渡动画时候触发。
			self:onExitTransitionStart()
		end
	end)

	--按键监听
	local  btcallback = function(ref, type)
        if type == ccui.TouchEventType.ended then
         	self:onButtonClickedEvent(ref:getTag(),ref)
        end
    end

	--区域外取消显示
	local  onQueryExitTouch = function(eventType, x, y)
		if not self._canTouchOutside then
			return true
		end

		if self._dismiss == true then
			return true
		end

		if eventType == "began" then
			local rect = self:getChildByTag(QueryDialog.DG_QUERY_EXIT):getBoundingBox()
        	if cc.rectContainsPoint(rect,cc.p(x,y)) == false then
        		self:dismiss()
    		end
		end
    	return true
    end
	self:setTouchEnabled(true)
	self:registerScriptTouchHandler(onQueryExitTouch)

	self.layer_main = display.newSprite("query_bg.png")
		:setTag(QueryDialog.DG_QUERY_EXIT)
		:move(display.cx, display.cy - 30)
		:addTo(self)

	local mainContentSize = self.layer_main:getContentSize()

	if QueryDialog.QUERY_SURE == queryType then
		ccui.ImageView:create("bt_query_confirm_0.png")
			:setTouchEnabled(true)
			:move(mainContentSize.width / 2 , 65 )
			:setTag(QueryDialog.BT_CONFIRM)
			:addTo(self.layer_main)
			:addTouchEventListener(btcallback)
	elseif QueryDialog.QUERY_WAIT_REPLY == queryType then


	elseif QueryDialog.QUERY_SURE_CANCEL == queryType then
		ccui.ImageView:create("bt_query_confirm_0.png")
			:setTouchEnabled(true)
			:move(mainContentSize.width / 2 + 120 , 65 )
			:setTag(QueryDialog.BT_CONFIRM)
			:addTo(self.layer_main)
			:addTouchEventListener(btcallback)

		ccui.ImageView:create("bt_query_cancel_0.png")
			:setTouchEnabled(true)
			:move(mainContentSize.width / 2 - 120 ,65 )
			:setTag(QueryDialog.BT_CANCEL)
			:addTo(self.layer_main)
			:addTouchEventListener(btcallback)
	elseif QueryDialog.QUERY_AGGRE_ORNO == queryType then
		ccui.ImageView:create("bt_query_agree_0.png")
			:setTouchEnabled(true)
			:move(mainContentSize.width / 2 + 140 , 65 )
			:setTag(QueryDialog.BT_CONFIRM)
			:addTo(self.layer_main)
			:addTouchEventListener(btcallback)

		ccui.ImageView:create("bt_query_refuse_0.png")
			:setTouchEnabled(true)
			:move(mainContentSize.width / 2 - 140 ,65 )
			:setTag(QueryDialog.BT_CANCEL)
			:addTo(self.layer_main)
			:addTouchEventListener(btcallback)

		local text = ''
		if argc and argc.time then
			text = string.format('%2d', argc.time / 1000)
		end
		
		local node_text = ccui.TextAtlas:create(text, 'bt_query_font_1.png', 18, 23, '0')
			:move(mainContentSize.width / 2 + 140 + 23 , 66 )
			:setString(text)
			:addTo(self.layer_main)

		if self._lastScheduler then
			display.unscheduleGlobal(self._lastScheduler)
			self._lastScheduler = nil
		end

		self._lastScheduler = display.scheduleGlobal(function()
			argc.time = argc.time - 1
			text = string.format('%2d', argc.time)
			node_text:setString(text)
		end, 1.0)
	end

	cc.Label:createWithTTF(msg, "fonts/siyuanheiti.ttf", not txtsize and QueryDialog.DEF_TEXT_SIZE or txtsize)
		:setTextColor(cc.c4b(77, 23, 22, 255))
		:setAnchorPoint(cc.p(0.5,0.5))
		:setDimensions(500, 180)
		:setHorizontalAlignment(cc.TEXT_ALIGNMENT_CENTER)
		:setVerticalAlignment(cc.VERTICAL_TEXT_ALIGNMENT_CENTER)
		:move(mainContentSize.width / 2 , mainContentSize.height / 2 + 25 )
		:addTo(self.layer_main)
	self._dismiss  = false

	self:show()
	-- self:runAction(cc.MoveBy:create(0.1,cc.p(0,40)))
end

function QueryDialog:show(cb)
	self.layer_main:stopAllActions()
    self:setVisible(true)
    self:runAction(
        cc.Sequence:create(
            cc.FadeTo:create(0.3, 180)
        )

    )
    self.layer_main:runAction(
        cc.Sequence:create(
            cc.MoveBy:create(0.25,cc.p(0, 50)),
            cc.CallFunc:create(function()
                    self:setTouchEnabled(true)
                    if cb then
                        cb()
                    end
                end)
            ))
end

--按键点击
function QueryDialog:onButtonClickedEvent(tag,ref)
	if self._dismiss == true then
		return
	end
	
	--取消显示
	self:dismiss(tag)

	
end

--取消消失
function QueryDialog:dismiss(tag)
	self._dismiss = true

	self:stopAllActions()
	self:runAction(
        cc.Sequence:create(
            cc.FadeOut:create(0),
            cc.CallFunc:create(function()
                self:setTouchEnabled(false)
				-- self:setVisible(false)
				--通知回调
				if self._callback then
					self._callback(tag == QueryDialog.BT_CONFIRM)
				end

				self:removeSelf()
            end)
        )
	)
	
end

return QueryDialog
