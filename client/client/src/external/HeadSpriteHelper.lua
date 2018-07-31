local HeadSpriteHelper = class("HeadSpriteHelper")

-- 下载状态标识
local DOWN_ENUM = {
	CreateDown 		= 0,				-- 创建下载
	Downloading		= 1,				-- 下载中
	DownSuccess		= 2,				-- 下载完成
}

-- 下载状态标识
local TEXTURE_ENUM = {
	IsSetTexture 		= 10,				-- 已设置
	NoSetTexture		= 11,				-- 未设置
}

-- 设置头像纹理 
-- @useritem -> 用户的数据
-- @view -> ImageView or Sprite  Sprite必须要有texture存在 否则无法设置图集
-- @size -> 精灵尺寸
-- @touchCallBack -> 触摸事件回调
function HeadSpriteHelper:initHeadTexture(useritem, view, size, touchCallBack, cb)
	if nil == useritem then
		return
	end
	
	if view == nil then
		view = {}
	end

	view.isDown = view.isDown or DOWN_ENUM.CreateDown

	if view.isDown == DOWN_ENUM.Downloading then

		return
	end


	-- 设置默认头像
	local SetDefTextureFuc = function()
		-- 更改标记 -> 下载完了
		view.isDown = DOWN_ENUM.DownSuccess

		local textureName = self.getTextureNameById(useritem.wFaceID)
		local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame(textureName)

		if cb then
			cb(frame:getTexture())
			return
		end

		if view.getDescription == nil then return end
		
		if nil ~= frame then
			-- 节点类型
			if view:getDescription() == "ImageView" then
				-- ImageView
				view:ignoreContentAdaptWithSize(false)
				view:loadTexture(textureName, ccui.TextureResType.localType)
			else
				-- Sprite
				view:setTexture(frame:getTexture())
			end

		end

		if nil ~= touchCallBack then
			-- 添加触摸
			
			self.addTouchEventListener(view, touchCallBack)
		end

		-- 缩放比例
		if size ~= nil then
			self.setHeadScale(view, size)
		end
	end

	-- 设置下载完成的头像
	-- @param texturepath,texture - > path or texture2D
	local SetTextureFuc = function(texturepath, texture, type)
		-- 更改标记 -> 下载完了
		view.isDown = DOWN_ENUM.DownSuccess
		
		if cb then
			cb(texture)
			return
		end

		if texturepath == nil or texture == nil then
			SetDefTextureFuc()
			return
		end

		if view.getDescription == nil then return end

		local type = type ~= nil and ccui.TextureResType.plistType or ccui.TextureResType.localType
		-- 节点类型
		if view:getDescription() == "ImageView" then
			-- ImageView
			view:ignoreContentAdaptWithSize(false)
			
			view:loadTexture(texturepath, type)
		else
			-- Sprite
			view:setTexture(texture)
		end

		if nil ~= touchCallBack then
			-- 添加触摸
			self.addTouchEventListener(view, touchCallBack)
		
		end

		-- 缩放比例
		if size ~= nil then
			self.setHeadScale(view, size)
		end
	end

	-- 检测/初始用户信息
	useritem = HeadSpriteHelper.checkData(useritem)
	-- SetDefTextureFuc()

	if useritem.dwUserID == GlobalUserItem.dwUserID 
		and GlobalUserItem.bThirdPartyLogin == true 
		and nil ~= GlobalUserItem.szThirdPartyUrl 
		and string.len(GlobalUserItem.szThirdPartyUrl) > 0 then
			
		local filename = string.format("%d_WeChat_%d.png", GlobalUserItem.dwUserID, 1)
		local filePath = device.writablePath .. "face/" .. GlobalUserItem.dwUserID
		local texturepath = GlobalUserItem.dwUserID.."/" .. filename
		local fullPath = filePath.."/"..filename
		local url = GlobalUserItem.szThirdPartyUrl

		-- 检测缓存
		local texture = display.getImage(texturepath)
		if nil ~= texture then
			
			SetTextureFuc(texturepath, texture)
			return
		end

		local isNewUrl = self.checkAvatarUrl(url)
		local isFileExist = self.searchFile(texturepath)

		local UpdateFaceToServer

		-- if isNewUrl == false and useritem.dwCustomID == nil and useritem.dwCustomID == 0 then
		-- 	-- 上传头像
		-- 	UpdateFaceToServer = function()
		-- 		self.upLoadFile(fullPath, useritem)
		-- 	end
		-- end

		-- 检测是否新头像地址
		if isNewUrl == false then
			-- 上传头像
			UpdateFaceToServer = function()
				self.upLoadFile(fullPath, useritem)
			end
		end
		
		-- 没有缓存
		-- 检测文件/最新头像
		if isFileExist == true and isNewUrl == true then

			local texture = display.loadImage(texturepath)

			-- 文件残缺
			if texture == nil then
				-- 更改标记 -> 下载中
				view.isDown = DOWN_ENUM.Downloading

				if isFileExist == true then
					-- 删除旧头像
					
					cc.FileUtils:getInstance():removeFile(fullPath)
				end

				self.downloadFace(url, filePath, filename, texturepath, SetTextureFuc, UpdateFaceToServer)
			else

				SetTextureFuc(texturepath, texture)
			end
			
		else
			-- 更改标记 -> 下载中
			view.isDown = DOWN_ENUM.Downloading

			if isFileExist == true then
				-- 删除旧头像
				
				cc.FileUtils:getInstance():removeFile(fullPath)
			end

			-- 保存新头像地址
			cc.UserDefault:getInstance():setStringForKey("szThirdPartyUrl",url)
			-- 下载
			self.downloadFace(url, filePath, filename, texturepath, SetTextureFuc, UpdateFaceToServer)
		end

	-- 不是第三方
	elseif useritem.bThirdPartyLogin == nil or useritem.bThirdPartyLogin == false then
		-- 没有头像
		if useritem.dwCustomID == 0 then
			
			SetDefTextureFuc()

		else
			local filename = useritem.dwUserID .. "_custom_" .. useritem.dwCustomID .. ".jpg"
			local fullPath = device.writablePath .. "face/" .. useritem.dwUserID
			local texturepath = useritem.dwUserID.."/" .. filename
			local bmpFilePath = fullPath.."/"..filename
			local infofile = fullPath .. "/faceCache.ry"
			
			
			-- 解析图片
			local createByBMPFile = function(value)

				--保存头像信息
				if value ~= true then
					-- 更改标记 -> 下载完成
					view.isDown = DOWN_ENUM.DownSuccess

					local infotable = {}
					--导入新的图片信息
					table.insert(infotable, bmpFilePath)
					local jsonStr = cjson.encode(infotable)
					cc.FileUtils:getInstance():writeStringToFile(jsonStr, infofile)
				end

				-- 解析texture2d
				local texture = display.loadImage(texturepath)
				
				-- 解析失败 -->文件有问题
				if texture == nil then

					SetTextureFuc()
				else

					SetTextureFuc(texturepath, texture)
				
				end
				
			end

			-- 检测缓存
			local texture = display.loadImage(texturepath)
			if nil ~= texture then
				SetTextureFuc(texturepath, texture)
				return
			end
			
			local url = yl.HTTP_URL .. "/WS/UserFace.ashx?customid=" .. useritem.dwCustomID

			-- 检测文件
			if self.searchFile(texturepath) == true then
				createByBMPFile(true)

			else
				-- 更改标记 -> 下载中
				view.isDown = DOWN_ENUM.Downloading
				
				-- 删除缓存
				if cc.FileUtils:getInstance():isFileExist(infofile) then
					local oldfile = cc.FileUtils:getInstance():getStringFromFile(infofile)
					local ok, datatable = pcall(function()
							return cjson.decode(oldfile)
					end)
					if ok and type(datatable) == "table" then
						for k ,v in pairs(datatable) do
							if v ~= bmpFilePath then
								cc.FileUtils:getInstance():removeFile(v)
							end
						end
					end
				end	
				
				self.downloadFace(url, fullPath, filename, texturepath, nil, createByBMPFile)
			end
		end

	end

end


-- 查找文件
function HeadSpriteHelper.searchFile(path)
	local fileUtils = cc.FileUtils:getInstance()
	-- 3.14版本才带有key方式添加贴图
	if fileUtils:isFileExist(path) then

		-- 文件是否完整
		local fileStr = fileUtils:getStringFromFile(path)
		if fileStr == nil or string.len(fileStr) < 1 then return false end

		return true
	end

	return false
end

-- 是否是新的微信头像地址
function HeadSpriteHelper.checkAvatarUrl(url)
	local avatarUrl = cc.UserDefault:getInstance():getStringForKey("szThirdPartyUrl","")
	if string.len(avatarUrl) > 0 then
		if url == avatarUrl then

			return true
		end
	end

	return false
end

-- 默认头像
function HeadSpriteHelper.getTextureNameById(faceid)
	if faceid == nil or faceid > 199 then
		faceid = 0
	end
	local textureName = string.format("Avatar%d.png",faceid)
	
	return "public/Avatar.png"
end

function HeadSpriteHelper.setHeadScale(view, size)
	-- 缩放比例
	size = size or 96
	local scale = size / view:getContentSize().width

	view:setScale(scale)
end

-- 处理用户信息
function HeadSpriteHelper.checkData(useritem)
	useritem = useritem or {}
	
	useritem.dwUserID = useritem.dwUserID or 0
	if useritem.dwUserID == GlobalUserItem.dwUserID then
		useritem.dwCustomID = GlobalUserItem.dwCustomID
	else
		useritem.dwCustomID = useritem.dwCustomID or 0
	end
	useritem.wFaceID = useritem.wFaceID or 0
		
	if useritem.wFaceID > 199 then
		useritem.wFaceID = 0
	end
	
	return useritem
end

-- 点击函数
function HeadSpriteHelper.addTouchEventListener(view, cb)
	-- 节点类型
	if view:getDescription() == "ImageView" then
		-- ImageView
		if view.isTouchListener ~= true then
			if view:isTouchEnabled() == false then

				view:setTouchEnabled(true)
			end

			-- 触摸事件函数
			local onTouchListener = function(sender, eventType)
				if eventType ~= ccui.TouchEventType.began and eventType ~= ccui.TouchEventType.moved then
					if eventType == ccui.TouchEventType.ended then

						if nil ~= cb then
							cb(sender)
						end
					end
				end
			end
			view:addTouchEventListener(onTouchListener)
			view.isTouchListener = true
		end
	else
		-- Sprite
			
		if view:isTouchEnabled() == false then
			-- 触摸事件函数
			local onTouchListener = function(e)
				if e.name == "began" then
					
					return true
				elseif e.name == "ended" then
					
					if nil ~= cb then
						cb(e.view)
					end
				end
			end
			view:setTouchMode(cc.TOUCHES_ONE_BY_ONE)
			view:addNodeEventListener(cc.NODE_TOUCH_EVENT, onTouchListener)
			view:setTouchEnabled(true)
			-- touchNode:setTouchSwallowEnabled(true)
		end
	end

end

-- 裁剪圆形图片
-- @param maskFile -> 裁剪类型素材
-- @param useritem -> 用户信息
-- @param view -> UI控件  ImageView or Sprite  Sprite必须要有texture存在 否则无法设置图集
-- @param size -> 大小
-- @param touchCallBack -> 点击函数
function HeadSpriteHelper:createClipMaskImg(maskFile, useritem, view, size, touchCallBack)
	view.isSetTexture = view.isSetTexture or TEXTURE_ENUM.NoSetTexture

	if view.isSetTexture == TEXTURE_ENUM.isSetTexture then
		return
	end

	if size == nil then
		size = view:getContentSize().width
	end
	
	useritem = HeadSpriteHelper.checkData(useritem)

	local filename = string.format("%d_ClipAvatar_%d.png",useritem.dwUserID ,size)
	local spriteFrameCache = cc.SpriteFrameCache:getInstance()
	
	-- 设置精灵
	local setTexture = function(texture, textureName, isInPlist)
		
		-- 节点类型
		if view:getDescription() == "ImageView" then
			-- ImageView
			view:ignoreContentAdaptWithSize(false)
			view:loadTexture(textureName, ccui.TextureResType.plistType)
		else
			-- Sprite
			view:setTexture(texture)
		end

		if nil ~= touchCallBack then
			-- 添加触摸
			self.addTouchEventListener(view, touchCallBack)
		end

		-- 缩放比例
		if size ~= nil then
			self.setHeadScale(view, size)
		end

		view:setFlippedY(true)
		
		view.isSetTexture = TEXTURE_ENUM.isSetTexture
	end

	-- 检测缓存
	local spriteFrame = spriteFrameCache:getSpriteFrame(filename)
	if nil ~= spriteFrame then
		setTexture(spriteFrame:getTexture(), filename)	
		return
	end

	maskFile = maskFile or "public/head_bg.png"
	
	-- 截取texture
	local setSprite = function(texture)

		local mask = display.newSprite(maskFile)
		local size_mask = mask:getContentSize()  

		local sp = cc.Sprite:createWithTexture(texture)
		local size_src = sp:getContentSize()  
	  
		local canva = cc.RenderTexture:create(size_mask.width, size_mask.height, cc.TEXTURE2_D_PIXEL_FORMAT_RGB_A8888)  
		  
		local ratiow = size_mask.width / size_src.width  
		local ratioh = size_mask.height / size_src.height  
		sp:setScaleX(ratiow)  
		sp:setScaleY(ratioh)  
	  
		mask:setPosition(size_mask.width / 2, size_mask.height / 2)  
		sp:setPosition(size_mask.width / 2, size_mask.height / 2)  
	  
		mask:setBlendFunc({src = gl.ONE, dst =  gl.ZERO})  
		sp:setBlendFunc({src = gl.DST_ALPHA, dst =  gl.ZERO})  
	  
		canva:begin()  
		mask:visit()  
		sp:visit()  
		canva:endToLua()  

		local canvaTexture = canva:getSprite():getTexture():setAntiAliasTexParameters()
		local ct = canvaTexture:getContentSize()
		local spriteFrame = cc.SpriteFrame:createWithTexture(canvaTexture, cc.rect(0,0,ct.width,ct.height))

		spriteFrameCache:addSpriteFrame(spriteFrame, filename)

		setTexture(spriteFrame:getTexture(), filename)
	end

	self:initHeadTexture(useritem, nil, nil, nil, setSprite)
    
end

-- 上传头像
function HeadSpriteHelper.upLoadFile(filepath, useritem)
	local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. "MultiPlatform")
	
	--发送上传头像
	local url = yl.HTTP_URL .. "/WS/Account.ashx?action=uploadface"
	local uploader = CurlAsset:createUploader(url,filepath)
	if nil == uploader then
		return
	end

	local nres = uploader:addToFileForm("file", filepath, "image/png")
	--用户标示
	nres = uploader:addToForm("userID", useritem.dwUserID or "thrid")
	--登陆时间差
	local delta = tonumber(currentTime()) - tonumber(GlobalUserItem.LogonTime)
	print("time delta " .. delta)
	nres = uploader:addToForm("time", delta .. "")
	--客户端ip
	local ip = MultiPlatform:getInstance():getClientIpAdress() or "192.168.1.1"
	nres = uploader:addToForm("clientIP", ip)
	--机器码
	local machine = useritem.szMachine or "A501164B366ECFC9E249163873094D50"
	nres = uploader:addToForm("machineID", machine)

	--会话签名
	nres = uploader:addToForm("signature", GlobalUserItem:getSignature(delta))
	if 0 ~= nres then
		return
	end
 
	uploader:uploadFile(function(sender, ncode, msg)
		print(msg)
	end)
end

--下载头像
function HeadSpriteHelper.downloadFace(url, filepath, filename, path, SetTextureFuc, callback)
	downFileAsync(url,filename,filepath,function(main,sub)
		--下载回调
		if main == appdf.DOWN_PRO_INFO then --进度信息
			
			return
		elseif main == appdf.DOWN_COMPELETED then --下载完毕
			if SetTextureFuc then
				
				SetTextureFuc(path, display.loadImage(path))
			end
			if callback then
				callback()
			end
			-- 太模糊
			-- reSizeGivenFile(filepath.."/"..filename, filepath.."/"..filename, "g_FaceResizeListener", 96)
	
		else
			if sub == 28 then
				-- self._retryCount = self._retryCount - 1
				-- this._listener:runAction(cc.CallFunc:create(function()
				-- 	this:UpdateFile()
				-- end))
			else
				if SetTextureFuc then
					SetTextureFuc()
				end
				dump("下载失败了", sub)
			end
		end
	end)
end

function HeadSpriteHelper.initDefAvatarSpriteFrame()
	local cache = cc.SpriteFrameCache:getInstance()
	if nil == cache:getSpriteFrame("public/Avatar.png") then
		local defaultFrame = cc.Sprite:create("public/Avatar.png"):getSpriteFrame()									
		cache:addSpriteFrame(defaultFrame, "public/Avatar.png")
		defaultFrame:retain()
	end

	-- if false == cc.SpriteFrameCache:getInstance():isSpriteFramesWithFileLoaded("public/im_head_frame.plist") then
	-- 	cache:addSpriteFrames("public/im_head_frame.plist")
	-- 	local frame = cc.SpriteFrameCache:getInstance():getSpriteFrame("head_mask.png")
	-- 	if nil ~= frame then
	-- 		frame:retain()
	-- 	end
	-- end
end

HeadSpriteHelper.initDefAvatarSpriteFrame()

return HeadSpriteHelper