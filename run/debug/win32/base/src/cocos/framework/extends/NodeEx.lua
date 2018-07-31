--[[

Copyright (c) 2011-2014 chukong-inc.com

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

]]

local Node = cc.Node

function Node:add(child, zorder, tag)
    if tag then
        self:addChild(child, zorder, tag)
    elseif zorder then
        self:addChild(child, zorder)
    else
        self:addChild(child)
    end
    return self
end

function Node:addTo(parent, zorder, tag)
    if tag then
        parent:addChild(self, zorder, tag)
    elseif zorder then
        parent:addChild(self, zorder)
    else
        parent:addChild(self)
    end
    return self
end

function Node:removeSelf()
    self:removeFromParent()
    return self
end

function Node:align(anchorPoint, x, y)
    self:setAnchorPoint(anchorPoint)
    return self:move(x, y)
end

function Node:show()
    self:setVisible(true)
    return self
end

function Node:hide()
    self:setVisible(false)
    return self
end

function Node:move(x, y)
    if y then
        self:setPosition(x, y)
    else
        self:setPosition(x)
    end
    return self
end

function Node:moveTo(args)
    transition.moveTo(self, args)
    return self
end

function Node:moveBy(args)
    transition.moveBy(self, args)
    return self
end

function Node:fadeIn(args)
    transition.fadeIn(self, args)
    return self
end

function Node:fadeOut(args)
    transition.fadeOut(self, args)
    return self
end

function Node:fadeTo(args)
    transition.fadeTo(self, args)
    return self
end

function Node:rotate(rotation)
    self:setRotation(rotation)
    return self
end

function Node:rotateTo(args)
    transition.rotateTo(self, args)
    return self
end

function Node:rotateBy(args)
    transition.rotateBy(self, args)
    return self
end

function Node:scaleTo(args)
    transition.scaleTo(self, args)
    return self
end

function Node:onUpdate(callback)
    self:scheduleUpdateWithPriorityLua(callback, 0)
    return self
end

Node.scheduleUpdate = Node.onUpdate

function Node:onEnter()
end

function Node:onExit()
end

function Node:onEnterTransitionFinish()
end

function Node:onExitTransitionStart()
end

function Node:onCleanup()
end

local c = cc

-- cocos2dx events
c.NODE_EVENT                 = 1
c.NODE_ENTER_FRAME_EVENT     = 2
c.NODE_TOUCH_EVENT           = 3
c.KEYPAD_EVENT               = 4

-- touch
c.TOUCH_MODE_ALL_AT_ONCE              = cc.TOUCHES_ALL_AT_ONCE
c.TOUCH_MODE_ONE_BY_ONE               = cc.TOUCHES_ONE_BY_ONE

local function isPointIn( rc, pt )
    local rect = c.rect(rc.x, rc.y, rc.width, rc.height)
    return c.rectContainsPoint(rect, pt)
end

function Node:align(anchorPoint, x, y)
    self:setAnchorPoint(display.ANCHOR_POINTS[anchorPoint])
    if x and y then self:setPosition(x, y) end
    return self
end


--[[--

测试一个点是否在当前结点区域中

@param tabel point cc.p的点位置,世界坐标
@return boolean 是否在结点区域中

]]
function Node:hitTest(point)
    local nsp = self:convertToNodeSpace(point)
    local rect = self:getContentSize()
    rect.x = 0
    rect.y = 0
    if c.rectContainsPoint(rect, nsp) then
        return true
    end
    return false
end

function Node:setTouchMode(mode)
	if mode ~= c.TOUCH_MODE_ALL_AT_ONCE and mode ~= c.TOUCHES_ONE_BY_ONE then
		print("== wrong mode", mode)
		return
	end
	self._luaTouchMode = mode
end

--[[
    @function addNodeEventListener后 开启触摸监听
    @param enable -> true or false
]]
function Node:setTouchEnabled(enable)

	-- remove old
	local eventDispatcher = self:getEventDispatcher()
	if self._luaTouchListener ~= nil then
		eventDispatcher:removeEventListener(self._luaTouchListener)
        self._luaTouchListener = nil
	end

    -- false 
    if not enable then
        self.thisTouchEnabled = false
        return
    end

	assert(self._LuaListeners, "Error: addNodeEventListener(cc.NODE_TOUCH_EVENT, func) first!")
	assert(self._LuaListeners[c.NODE_TOUCH_EVENT], "Error: addNodeEventListener(cc.NODE_TOUCH_EVENT, func) first!")

	local isSingle = true
	if self._luaTouchMode and self._luaTouchMode == c.TOUCH_MODE_ALL_AT_ONCE then
		isSingle = false
	end

	-- add new
	if isSingle then
		self._luaTouchListener = c.EventListenerTouchOneByOne:create()
		self._luaTouchListener:setSwallowTouches(true)
		local dealFunc = function(touch, name)
			local tp = touch:getLocation()
			local pp = touch:getPreviousLocation()

			if name == "began" then
				if not self:isVisible() or not self:hitTest(tp) then
					return false
				end
			end

			-- call listener
			return self._LuaListeners[c.NODE_TOUCH_EVENT]{
				name = name,
				x = tp.x,
				y = tp.y,
				prevX = pp.x,
				prevY = pp.y,
                view = self,
			}
		end
		self._luaTouchListener:registerScriptHandler(function(touch, event)
			return dealFunc(touch, "began")
		end, c.Handler.EVENT_TOUCH_BEGAN)
		self._luaTouchListener:registerScriptHandler(function(touch, event)
			dealFunc(touch, "moved")
		end, c.Handler.EVENT_TOUCH_MOVED)
		self._luaTouchListener:registerScriptHandler(function(touch, event)
			dealFunc(touch, "ended")
		end, c.Handler.EVENT_TOUCH_ENDED)
		self._luaTouchListener:registerScriptHandler(function(touch, event)
			dealFunc(touch, "cancelled")
		end, c.Handler.EVENT_TOUCH_CANCELLED)
	end
    eventDispatcher:addEventListenerWithSceneGraphPriority(self._luaTouchListener, self)
    
    self.thisTouchEnabled = true

    return self
end

function Node:isTouchEnabled()
    self.thisTouchEnabled = self.thisTouchEnabled or false
    
    return self.thisTouchEnabled
end

--[[
    @function 触摸事件吞噬
]]
function Node:setTouchSwallowEnabled(enable)
	if self._luaTouchListener then
		self._luaTouchListener:setSwallowTouches(enable)
    end
    return self
end

function Node:addNodeEventListener(evt, hdl)
    if not self._LuaListeners then
        self._LuaListeners = {}
		if evt == c.NODE_EVENT then
			self._baseNodeEventListener = function(evt)
				-- call listener
				self._LuaListeners[c.NODE_EVENT]{name = evt}
			end
			self:registerScriptHandler(self._baseNodeEventListener)
		end
    end

    self._LuaListeners[evt] = hdl
    
    return self
end

function Node:removeNodeEventListener(evt)
    if not self._LuaListeners then return end

	if evt == c.KEYPAD_EVENT then
		self:setKeypadEnabled(false)
	elseif evt == c.NODE_EVENT then
		self:unregisterScriptHandler(self._baseNodeEventListener)
	elseif evt == c.NODE_ENTER_FRAME_EVENT then
		self:unscheduleUpdate()
	elseif evt == c.NODE_TOUCH_EVENT then
		self:setTouchEnabled(false)
	end

	self._LuaListeners[evt] = nil
end

function Node:removeAllNodeEventListeners()
    self:removeNodeEventListener(c.NODE_EVENT)
    self:removeNodeEventListener(c.NODE_ENTER_FRAME_EVENT)
    self:removeNodeEventListener(c.NODE_TOUCH_EVENT)
    self:removeNodeEventListener(c.KEYPAD_EVENT)
end