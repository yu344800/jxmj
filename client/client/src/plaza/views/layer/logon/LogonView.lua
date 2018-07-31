local LogonView = class("LogonView",function()
		local logonView =  display.newLayer()
    return logonView
end)
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. "ExternalFun")
local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")
local ClientConfig = appdf.req('base.src.app.models.ClientConfig')

LogonView.BT_LOGON = 1
LogonView.BT_REGISTER = 2
LogonView.CBT_RECORD = 3
LogonView.CBT_AUTO = 4
LogonView.BT_VISITOR = 5
LogonView.BT_WEIBO = 6
LogonView.BT_QQ	= 7
LogonView.BT_THIRDPARTY	= 8
LogonView.BT_WECHAT	= 9
LogonView.BT_FGPW = 10 	-- 忘记密码
LogonView.BT_SHOWPW = 11 -- 显示密码
LogonView.BT_HIDEPW = 12 -- 隐藏密码
LogonView.CBX_AGREE = 13
LogonView.BTN_AGREEMENT = 14

function LogonView:ctor(serverConfig, versionMng)
	local this = self
	self:setContentSize(yl.WIDTH,yl.HEIGHT)
	--ExternalFun.registerTouchEvent(self)

	local  btcallback = function(ref, type)
        if type == ccui.TouchEventType.ended then
         	this:onButtonClickedEvent(ref:getTag(),ref)
        end
    end
	local cbtlistener = function (sender,eventType)
    	this:onSelectedEvent(sender,eventType)
    end

    local editHanlder = function ( name, sender )
		self:onEditEvent(name, sender)
	end
    
	local targetPlatform = cc.Application:getInstance():getTargetPlatform()
	
	if device.platform ~= "windows" then
		if ClientConfig.UPDATE_TO_APPSTORE == false then
			--微信登陆
			ccui.Button:create("Logon/thrid_part_wx_0.png", "", "")
						:setTag(LogonView.BT_WECHAT)
						:move(680, display.bottom + 230)
						:setVisible(true)
						:setEnabled(true)
						:setName("btn_3")
						:addTo(self)
						:addTouchEventListener(btcallback)
		else
			--游客登录
			ccui.Button:create("Logon/visitor_button_0.png", "", "")
						:setTag(LogonView.BT_VISITOR)   --BT_LOGON  BT_VISITOR
						:move(680, display.bottom + 230)
						:setEnabled(true)
						:setVisible(true)
						:setName("btn_2")
						:addTo(self)
						:addTouchEventListener(btcallback)
		end

	elseif device.platform == "windows" then
		-- tips
		local lable = cc.Label:createWithTTF("选择服务器登录:", "fonts/round_body.ttf", 20)
				:setTextColor(cc.c4b(68,136,221,255))
				:setAnchorPoint(cc.p(1,0))
				:enableOutline(cc.c4b(0,0,0,255), 1)
				:move(display.cx - 100, display.cy - 100)
				:addTo(self)

		local touch = function(e)
			if e.name == "began" then
				yl.CURRENT_INDEX = e.view:getTag()
				yl.LOGONSERVER = yl.SERVER_LIST[yl.CURRENT_INDEX]
				yl.HTTP_URL = yl.HTTP_URL_LIST[yl.CURRENT_INDEX]
				self:onButtonClickedEvent(LogonView.BT_VISITOR)
				return true
			end
		end

		local count = 0
		local y = display.cy - 100
		-- 服务器列表
		for k,v in ipairs(yl.SERVER_LIST) do
			count = count + 1

			if count == 3  then
				y = y + (k - 1 * 50 )
				count = 0
			end

			local lable = cc.Label:createWithTTF(tostring(v), "fonts/round_body.ttf", 20)
					:setTag(k)
					:setTextColor(cc.c4b(144,238,144,255))
					:setAnchorPoint(cc.p(1,0))
					:enableOutline(cc.c4b(0,0,0,255), 1)
					:addTo(self)

			lable:move(display.cx - 100 + 150 * count, y)
			lable:setContentSize(lable:getContentSize())
			lable:setTouchMode(cc.TOUCHES_ONE_BY_ONE)
			lable:addNodeEventListener(cc.NODE_TOUCH_EVENT, touch)
			lable:setTouchEnabled(true)
		end
	end

	--文网文信息
    local wwwInfo = cc.Sprite:create("denglu-kuang-01.png")
    wwwInfo:setPosition(appdf.WIDTH/2, 38)
    wwwInfo:addTo(self, 1000)

	local c_version = versionMng:getVersion() or appdf.BASE_C_VERSION
	local r_version = versionMng:getResVersion() or appdf.BASE_C_RESVERSION

    --版本号
	self.verTips = cc.Label:createWithTTF("版本号:" .. c_version .. "." .. r_version, "fonts/round_body.ttf", 24)
		:setAnchorPoint(1, 0.5)
        :setTextColor(cc.c4b(234, 255, 255, 255))
        :enableOutline(cc.c4b(0, 0, 0, 255), 2)
        :setPosition(cc.p(display.width , 20))
		:addTo(self)
	
	local layerTouch = function(eventType, x, y)
		if eventType == 'began' then
			--local node = appdf.getNodeByName(self._mainlayer, "sp_bg")
			local rect = self._mainlayer:getBoundingBox()
			if cc.rectContainsPoint(rect, cc.p(x, y)) == false then
				self._mainlayer:setVisible(false)
				self._touchLayer:setTouchEnabled(false)
				self._touchLayer:setSwallowsTouches(false)
				self.cbx:setTouchEnabled(true)
				--self._mainlayer:setVisible
			end
		end
		return true
	end
	local layer = display.newLayer()
	self:addChild(layer,2000)
	local rootLayer, csbNode = ExternalFun.loadRootCSB("Login/Agreement.csb", layer)
	self._mainlayer = appdf.getNodeByName(csbNode,"sp_bg")
	self._touchLayer = layer
	self._mainlayer:setTouchEnabled(false)
	layer:setTouchEnabled(false)
	layer:registerScriptTouchHandler(layerTouch)

	local cbx_agree = appdf.getNodeByName(csbNode,"cbx_agre")
	local btn_agreement = appdf.getNodeByName(csbNode,"btn_agreement")
    self.cbx = cbx_agree

	cbx_agree:setTag(LogonView.CBX_AGREE)
	cbx_agree:addTouchEventListener(btcallback)
	btn_agreement:setTag(LogonView.BTN_AGREEMENT)
	btn_agreement:addTouchEventListener(btcallback)

end

function LogonView:refreshBtnList( )
	for i = 1, 3 do
		local btn = self:getChildByName("btn_" .. i)
		if btn ~= nil then
			btn:setVisible(false)
			btn:setEnabled(false)
		end
	end

	local btnpos = 
	{
		{cc.p(667, 70), cc.p(0, 0), cc.p(0, 0)},
		{cc.p(463, 70), cc.p(868, 70), cc.p(0, 0)},
		{cc.p(222, 70), cc.p(667, 70), cc.p(1112, 70)}
	}	

	-- 登陆限定
	local loginConfig = self.m_serverConfig.moblieLogonMode or 0
	loginConfig = 2
	-- 1:帐号 2:游客 4:微信
	local btnlist = {}
	if (1 == bit:_and(loginConfig, 1)) then
		table.insert(btnlist, "btn_1")
	else
		-- 隐藏帐号输入信息
		-- self:hideAccountInfo()
	end
	
	if false == GlobalUserItem.getBindingAccount() and (2 == bit:_and(loginConfig, 2)) then
		table.insert(btnlist, "btn_2")
	end

	local enableWeChat = self.m_serverConfig["wxLogon"] or 1
	if 4 == bit:_and(loginConfig, 4) then
		table.insert(btnlist, "btn_3")
	end

	local poslist = btnpos[#btnlist]
	for k,v in pairs(btnlist) do
		local tmp = self:getChildByName(v)
		if nil ~= tmp then
			tmp:setEnabled(true)
			tmp:setVisible(true)

			local pos = poslist[k]
            if nil ~= pos then
            	tmp:setPosition(pos)
            end
		end
	end
end

function LogonView:onEditEvent(name, editbox)
	--print(name)
	if "changed" == name then
		if editbox:getText() ~= GlobalUserItem.szAccount then
			self.edit_Password:setText("")
		end		
	end
end

function LogonView:onReLoadUser()
	if GlobalUserItem.szAccount ~= nil and GlobalUserItem.szAccount ~= "" then
		self.edit_Account:setText(GlobalUserItem.szAccount)
	else
		self.edit_Account:setPlaceHolder("请输入您的游戏帐号")
	end

	if GlobalUserItem.szPassword ~= nil and GlobalUserItem.szPassword ~= "" then
		self.edit_Password:setText(GlobalUserItem.szPassword)
	else
		self.edit_Password:setPlaceHolder("请输入您的游戏密码")
	end
end

function LogonView:onButtonClickedEvent(tag,ref)
	if tag == LogonView.BT_REGISTER then
		GlobalUserItem.bVisitor = false
		self:getParent():getParent():onShowRegister()
	elseif tag == LogonView.BT_VISITOR then
		if appdf.getNodeByName(self._touchLayer,"cbx_agre"):isSelected() == false then
			showToast(self,"请同意用户协议",3)
			return 
		end
		GlobalUserItem.bVisitor = true
		self:getParent():getParent():onVisitor()
	elseif tag == LogonView.BT_LOGON then
		GlobalUserItem.bVisitor = false
		local szAccount = string.gsub(self.edit_Account:getText(), " ", "")
		local szPassword = string.gsub(self.edit_Password:getText(), " ", "")
		local bAuto = self:getChildByTag(LogonView.CBT_RECORD):isSelected()
		local bSave = self:getChildByTag(LogonView.CBT_RECORD):isSelected()
		self:getParent():getParent():onLogon(szAccount,szPassword,bSave,bAuto)
	elseif tag == LogonView.BT_THIRDPARTY then
		self.m_spThirdParty:setVisible(true)
	elseif tag == LogonView.BT_WECHAT then
		--平台判定
		local targetPlatform = cc.Application:getInstance():getTargetPlatform()
		if (cc.PLATFORM_OS_IPHONE == targetPlatform) or (cc.PLATFORM_OS_IPAD == targetPlatform) or (cc.PLATFORM_OS_ANDROID == targetPlatform) then
			if appdf.getNodeByName(self._touchLayer,"cbx_agre"):isSelected() then
			    self:getParent():getParent():thirdPartyLogin(yl.ThirdParty.WECHAT)
			else
                showToast(self,"请同意用户协议",3)
			end
		else
			showToast(self, "不支持的登录平台 ==> " .. targetPlatform, 2)
		end
	elseif tag == LogonView.BT_FGPW then
		MultiPlatform:getInstance():openBrowser(yl.HTTP_URL .. "/Mobile/RetrievePassword.aspx")
	elseif tag == LogonView.BT_SHOWPW then
		self.m_btnShowPasswd:loadTextureDisabled("Logon/login_btn_showpw_0.png")
    	self.m_btnShowPasswd:loadTextureNormal("Logon/login_btn_showpw_0.png")
    	self.m_btnShowPasswd:loadTexturePressed("Logon/login_btn_showpw_1.png")
    	self.m_btnShowPasswd:setTag(LogonView.BT_HIDEPW)

		--[[self.edit_Password:setInputFlag(cc.EDITBOX_INPUT_FLAG_NO_PASSWORD)
		self.edit_Password:setText(self.edit_Password:getText())]]

		local txt = self.edit_Password:getText()
		self.edit_Password:removeFromParent()
		--密码输入	
		self.edit_Password = ccui.EditBox:create(cc.size(490,67), "Logon/text_field_frame.png")
			:move(yl.WIDTH/2,280)
			:setAnchorPoint(cc.p(0.5,0.5))
			:setFontName("fonts/round_body.ttf")
			:setPlaceholderFontName("fonts/round_body.ttf")
			:setFontSize(24)
			:setPlaceholderFontSize(24)
			:setMaxLength(26)
			:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)		
			:addTo(self)
			:setText(txt)
	elseif tag == LogonView.BT_HIDEPW then
		self.m_btnShowPasswd:loadTextureDisabled("Logon/login_btn_hidepw_0.png")
    	self.m_btnShowPasswd:loadTextureNormal("Logon/login_btn_hidepw_0.png")
    	self.m_btnShowPasswd:loadTexturePressed("Logon/login_btn_hidepw_1.png")
    	self.m_btnShowPasswd:setTag(LogonView.BT_SHOWPW)

		--[[self.edit_Password:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
		self.edit_Password:setText(self.edit_Password:getText())]]

		local txt = self.edit_Password:getText()
		self.edit_Password:removeFromParent()
		--密码输入	
		self.edit_Password = ccui.EditBox:create(cc.size(490,67), "Logon/text_field_frame.png")
			:move(yl.WIDTH/2,280)
			:setAnchorPoint(cc.p(0.5,0.5))
			:setFontName("fonts/round_body.ttf")
			:setPlaceholderFontName("fonts/round_body.ttf")
			:setFontSize(24)
			:setPlaceholderFontSize(24)
			:setMaxLength(26)
			:setInputFlag(cc.EDITBOX_INPUT_FLAG_PASSWORD)
			:setInputMode(cc.EDITBOX_INPUT_MODE_SINGLELINE)		
			:addTo(self)
			:setText(txt)
	elseif tag == LogonView.CBX_AGREE then
		--local cs_hua = appdf.getNodeByName(self, 'CheckBox_2'):setSelected(false)
	elseif tag == LogonView.BTN_AGREEMENT then
		self._mainlayer:setVisible(true)
		self._touchLayer:setSwallowsTouches(true)
		self._touchLayer:setTouchEnabled(true)
		self.cbx:setTouchEnabled(false)
	end
end

function LogonView:onTouchBegan(touch, event)
	return self:isVisible()
end

function LogonView:onTouchEnded(touch, event)
	local pos = touch:getLocation();
	local m_spBg = self.m_spThirdParty
    pos = m_spBg:convertToNodeSpace(pos)
    local rec = cc.rect(0, 0, m_spBg:getContentSize().width, m_spBg:getContentSize().height)
    if false == cc.rectContainsPoint(rec, pos) then
        self.m_spThirdParty:setVisible(false)
    end
end

function LogonView:hideAccountInfo()
	self.m_spAccount:setVisible(false)
	--账号输入
	self.edit_Account:setVisible(false)
	self.edit_Account:setEnabled(false)

	self.m_spPasswd:setVisible(false)
	-- 密码输入
	self.edit_Password:setVisible(false)
	self.edit_Password:setEnabled(false)

	-- 查看密码
	self.m_btnShowPasswd:setVisible(false)
	self.m_btnShowPasswd:setEnabled(false)

	-- 忘记密码
	self.m_btnFgPasswd:setVisible(false)
	self.m_btnFgPasswd:setEnabled(false)

	-- 记住密码
	self.cbt_Record:setVisible(false)
	self.cbt_Record:setEnabled(false)

	-- 注册账号
	self.m_btnRegister:setVisible(false)
	self.m_btnRegister:setEnabled(false)

end

return LogonView