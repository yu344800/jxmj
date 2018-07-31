local NewGameListLayer = class("NewGameListLayer", function()
	local NewGameListLayer = display.newLayer()
	return NewGameListLayer
end)
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local Update = appdf.req(appdf.BASE_SRC.."app.controllers.ClientUpdate")
local QueryDialog = appdf.req(appdf.BASE_SRC.."app.views.layer.other.QueryDialog")

-- 进入场景而且过渡动画结束时候触发。
function NewGameListLayer:onEnterTransitionFinish()
	return self
end

-- 退出场景而且开始过渡动画时候触发。
function NewGameListLayer:onExitTransitionStart()
	return self
end

-- 游戏模式选择层
function NewGameListLayer:ctor(clientScene, app)
	self:registerScriptHandler(function(eventType)
		if eventType == "enterTransitionFinish" then	-- 进入场景而且过渡动画结束时候触发。			
			self:onEnterTransitionFinish()			
		elseif eventType == "exitTransitionStart" then	-- 退出场景而且开始过渡动画时候触发。
			self:onExitTransitionStart()
		elseif eventType == "exit" then
			self:onExit()
		end
	end)
	
	self._clientScene = clientScene
	self._app = app
	self._gameList = self._app._gameList
	self._updateUrl = self._app._updateUrl
	self.isLoad = true

	-- 热门排序
	table.sort(self._gameList, function(a, b)
		return a._SortId < b._SortId
	end)

	local csbNode = ExternalFun.loadCSB( "hotGame/NewGameListLayer.csb", self )

	self:initTableView()
end

function NewGameListLayer:initTableView()
	self._cloneCell = appdf.getNodeByName(self, "game_clone")
	
	local contentSize = self._cloneCell:getContentSize()

	self.cellSizeFor = {
		width = contentSize.width,
		height = contentSize.height + 15,
	}

	local tableView = cc.TableView:create(cc.size(self.cellSizeFor.width + 90, self.cellSizeFor.height * 3.1))
	tableView:setDirection(cc.SCROLLVIEW_DIRECTION_VERTICAL) 
	tableView:setVerticalFillOrder(cc.TABLEVIEW_FILL_TOPDOWN)
	tableView:setPosition(cc.p(840, 115))
	tableView:setName("left_tabView")
	tableView:setDelegate()
	tableView:addTo(self)
	tableView:registerScriptHandler(handler(self, self.cellTouch), cc.TABLECELL_TOUCHED)
	tableView:registerScriptHandler(handler(self, self.getCellSize), cc.TABLECELL_SIZE_FOR_INDEX)
	tableView:registerScriptHandler(handler(self, self.createCell), cc.TABLECELL_SIZE_AT_INDEX)
	tableView:registerScriptHandler(handler(self, self.cellCounts), cc.NUMBER_OF_CELLS_IN_TABLEVIEW)
end

function NewGameListLayer:cellTouch(view, cell)

	local gameIdx = cell:getIdx() + 1
	local gameInfo = self._gameList[gameIdx]
	-- if tonumber(gameInfo._KindID) == 104 then 
	--     showToast(self,"即将开放，敬请期待!", 1)
	--     return
	-- end

	local version = tonumber(self._app:getVersionMgr():getResVersion(gameInfo._KindID))
	
	if not version or gameInfo._ServerResVersion > version then

		if device.platform == "windows" then
			self._app:getVersionMgr():setResVersion(gameInfo._ServerResVersion, gameInfo._KindID)
		else
			self:onGameUpdate(gameInfo, gameIdx)
			return
		end
	end
	
	self._clientScene:updateEnterGameInfo(gameInfo)
	
	local gameNumber = tonumber(gameInfo._KindID)
	
	GlobalUserItem.nCurGameKind = gameNumber
	GlobalUserItem.szCurGameName = gameInfo._KindName


	self._clientScene:createPriRoomCreateLayer()
	
end

function NewGameListLayer:getCellSize(view, idx)
	return self.cellSizeFor.width, self.cellSizeFor.height
end

function NewGameListLayer:createCell(view, idx)
	local cell = view:dequeueCell()
	
	if cell == nil then        
		cell = cc.TableViewCell:new()
	else
		cell:removeAllChildren()
	end

	local v = self._gameList[idx + 1]
	if v == nil then

		return cell
	end
	local name = string.match(v._KindName, "%a+.(%a+).")  
	local textureName = string.format("hotGame/game_%s.png", name)
	local toPos = cc.p(- (idx * 10) + 20 + 200, 70)
	
	local item = self._cloneCell:clone()
			:loadTexture(textureName)
			:setAnchorPoint(0.5, 0.5)

	local item2 = self._cloneCell:clone()
			:setName("_mask")
			:loadTexture(textureName)
			:setScale(1)
			:setOpacity(120)
			:setColor(cc.BLACK)
			:setAnchorPoint(0.5, 0.5)
			:setPosition(toPos)
			:setVisible(false)

	local spinner_circle = display.newSprite("GameList/spinner_circle.png")
			:setName("_circle")
			:setAnchorPoint(0.5, 0.5)
			:setPosition(toPos)
			:setVisible(false)

	local lab = cc.Label:createWithTTF("", "fonts/round_body.ttf", 28)
			:setName("_circleText")
			:setTextColor(cc.c4b(255,255,255,255))
			:setPosition(toPos)
			:setVisible(false)
	
	if self.isUpdateIdx ~= nil and self.isUpdateIdx == idx + 1 then
		
		item2:setVisible(true)
		spinner_circle:setVisible(true)
		spinner_circle:runAction(cc.RepeatForever:create(cc.RotateBy:create(0.8, 360)))
	end

	if self.isLoad == nil then
		item:setScale(1)
		item:setOpacity(255)
		item:setPosition(toPos)
	else
		item:setPosition((idx * 10) + 20 + 200, 70)
		item:runAction(
			cc.Sequence:create(
				cc.DelayTime:create(idx * 0.1),
				cc.Spawn:create(
					cc.FadeIn:create(0.1),
					cc.MoveTo:create(0.3, toPos),
					cc.ScaleTo:create(0.1, 1)
				)
			)
		)
	end
	
	if idx + 1 == #self._gameList and self.isLoad ~= nil then
		self.isLoad = nil
	end

	cell:addChild(item)
	cell:addChild(item2)
	cell:addChild(spinner_circle)
	cell:addChild(lab)
		
	return cell
end

function NewGameListLayer:cellCounts(view)
	return #self._gameList
end	

function NewGameListLayer:showGameUpdateWait()
	self.m_bGameUpdate = true
	ExternalFun.popupTouchFilter(1, false, "游戏更新中,请稍候！")
end

function NewGameListLayer:dismissGameUpdateWait()
	self.m_bGameUpdate = false
	ExternalFun.dismissTouchFilter()
end

function NewGameListLayer:fingGameIndexByGameList(gameinfo)
	for k,v in ipairs(self._gameList) do
		if v._KindID == gameinfo._KindID then
			return k
		end
	end

	return nil
end

function NewGameListLayer:onGameUpdate(gameinfo, gameIdx)

	if gameIdx == nil then
		gameIdx = self:fingGameIndexByGameList(gameinfo)
	end

	local view = appdf.getNodeByName(self, "left_tabView")
	local itemView = view:cellAtIndex(gameIdx - 1)
	local _mask = appdf.getNodeByName(itemView, "_mask")
	_mask:setVisible(true)
	local _circle = appdf.getNodeByName(itemView, "_circle")
	_circle:setVisible(true)
	_circle:runAction(cc.RepeatForever:create(cc.RotateBy:create(0.8, 360)))

	self._circleText = appdf.getNodeByName(itemView, "_circleText")
			:setVisible(true)
					
	self.isUpdateIdx = gameIdx

	--失败重试
	if not gameinfo and self._update ~= nil then
		self:showGameUpdateWait()
		self._update:UpdateFile()
		return 
	end

	if not gameinfo then 
		showToast(self,"无效游戏信息！",1)
		return
	end

	self:showGameUpdateWait()

	--记录
	if gameinfo ~= nil then
		self._downgameinfo = gameinfo
	end

	--更新参数
	local newfileurl = self._updateUrl.."/game/"..self._downgameinfo._Module.."/res/filemd5List.json"
	local dst = device.writablePath .. "game/" .. self._downgameinfo._Type .. "/"
	local targetPlatform = cc.Application:getInstance():getTargetPlatform()
	if cc.PLATFORM_OS_WINDOWS == targetPlatform then
		dst = device.writablePath .. "download/game/" .. self._downgameinfo._Type .. "/"
	end
	
	local src = device.writablePath.."game/"..self._downgameinfo._Module.."/res/filemd5List.json"
	local downurl = self._updateUrl .. "/game/" .. self._downgameinfo._Type .. "/"

	--创建更新
	self._update = Update:create(newfileurl,dst,src,downurl)
	self._update:upDateClient(self)
end


function NewGameListLayer:updateProgress(sub, msg, mainpersent)
	local permsg = string.format("%d%%", mainpersent)
	if self._circleText ~= nil then
		self._circleText:setString(permsg)
	end
end


function NewGameListLayer:updateResult(result,msg)
	self:dismissGameUpdateWait()

	if result == true then
		local app = self._app
		--更新版本号
		for k,v in pairs(app._gameList) do
			if v._KindID == self._downgameinfo._KindID then
				app:getVersionMgr():setResVersion(v._ServerResVersion, v._KindID)
				v._Active = true
				break
			end
		end
		self._update = nil

		app:getVersionMgr():save()

		showToast(self._clientScene, "更新完成!可以愉快的游戏了!", 2)
		self.isUpdateIdx = -1
		local view = appdf.getNodeByName(self, "left_tabView")

		if view ~= nil then
			view:reloadData()
		end

		-- 还原游戏场景
		local isIn = PriRoom:getInstance():onLoginRoom(GlobalUserItem.dwLockServerID, true)
		if isIn == false then
			local lockRoom = GlobalUserItem.GetGameRoomInfo(GlobalUserItem.dwLockServerID)
			if GlobalUserItem.dwLockKindID == GlobalUserItem.nCurGameKind and nil ~= lockRoom then
				GlobalUserItem.nCurRoomIndex = lockRoom._nRoomIndex
				local entergame = self._clientScene:getGameInfo(GlobalUserItem.dwLockKindID)
				self._clientScene:updateEnterGameInfo(entergame)
				
				if GlobalUserItem.dwLockKindID ~= 504 then
					self._clientScene:onStartGame()
				end
			end
		end
	else
		QueryDialog:create(msg.."\n是否重试？",function(bReTry)
				if bReTry == true then
					self:onGameUpdate(self._downgameinfo, self.isUpdateIdx)
				else
					self.isUpdateIdx = -1
					local view = appdf.getNodeByName(self, "left_tabView")
			
					if view ~= nil then
						view:reloadData()
					end
			
				end
			end)
			:addTo(self)
	end

end

function NewGameListLayer:onSceneAniFinish()
	-- display.performWithDelayGlobal(function()
		local view = appdf.getNodeByName(self, "left_tabView")
					 :reloadData()
	-- end, 0.5)
end

return NewGameListLayer