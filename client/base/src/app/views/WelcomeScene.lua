--[[
	欢迎界面
			2015_12_03 C.P
	功能：本地版本记录读取，如无记录，则解压原始大厅及附带游戏
--]]
local WelcomeScene = class('WelcomeScene', cc.load('mvc').ViewBase)

local ClientUpdate = appdf.req('base.src.app.controllers.ClientUpdate')
local QueryDialog = appdf.req('base.src.app.views.layer.other.QueryDialog')

local URL_REQUEST = 'http://47.96.90.32:8080' --@xu
--local URL_REQUEST = 'http://192.168.2.138:8080' --@xu
--全局toast函数(ios/android端调用)
cc.exports.g_NativeToast = function(msg)
    local runScene = cc.Director:getInstance():getRunningScene()
    if nil ~= runScene then
        showToastNoFade(runScene, msg, 2)
    end
end

function WelcomeScene:onCreate()
    local this = self
    self:setTag(1)
    --背景

    self.mBackGround = cc.Sprite:create('background_1.png')

    self.mBackGround:setPosition(appdf.WIDTH / 2, appdf.HEIGHT / 2)
    self:addChild(self.mBackGround)

    --提示文本
    self._txtTips =
        cc.Label:createWithTTF('', 'fonts/round_body.ttf', 24):setTextColor(cc.c4b(234, 255, 255, 255)):enableOutline(
        cc.c4b(7, 90, 100, 255),
        2
    ):setAnchorPoint(cc.p(1, 0)):move(appdf.WIDTH, 0):addTo(self)

    self.m_progressLayer = display.newLayer(cc.c4b(0, 0, 0, 0))
    self:addChild(self.m_progressLayer)
    self.m_progressLayer:setVisible(false)
    --总进度
    local total_bg = cc.Sprite:create('wait_frame_0.png')
    self.m_spTotalBg = total_bg
    self.m_progressLayer:addChild(total_bg)
    total_bg:setPosition(appdf.WIDTH / 2, 80)
    self.m_totalBar = ccui.LoadingBar:create()
    self.m_totalBar:loadTexture('wait_frame_2.png')
    self.m_progressLayer:addChild(self.m_totalBar)
    self.m_totalBar:setPosition(appdf.WIDTH / 2, 80)
    self._totalTips =
        cc.Label:createWithTTF('', 'fonts/round_body.ttf', 24):setTextColor(cc.c4b(234, 255, 255, 255)):setName(
        'text_tip'
    ):enableOutline(cc.c4b(0, 0, 0, 255), 2):move(
        self.m_totalBar:getContentSize().width * 0.5,
        self.m_totalBar:getContentSize().height * 0.5
    ):addTo(self.m_totalBar)
    self.m_totalThumb = cc.Sprite:create('thumb_0.png')
    self.m_totalBar:addChild(self.m_totalThumb)
    self.m_totalThumb:setPositionY(self.m_totalBar:getContentSize().height * 0.5)
    self:updateBar(self.m_totalBar, self.m_totalThumb, 0)

    -- 资源同步队列
    self.m_tabUpdateQueue = {}

    local fristTime

    -- windows不闪屏
    if device.platform == 'windows' then
        fristTime = 0
    else
        fristTime = 2
    end

    -- 闪屏动画
    self.mBackGround:runAction(
        cc.Sequence:create(
            cc.DelayTime:create(fristTime),
            cc.CallFunc:create(
                function()
                    self.mBackGround:setTexture('background_2.png')

                    -- if LOCAL_DEVELOP == 1 then
                    -- 	local v = (appdf.VersionValue(6,7,0,1))..""
                    -- 	self:getApp()._gameList = {}
                    -- 	self:getApp()._updateUrl = URL_REQUEST .. "/"
                    -- 	self._newVersion = v
                    -- 	self:getApp()._version:setVersion(self._newVersion)
                    -- 	self:getApp()._version:save()
                    -- 	self:httpNewVersionCallBack()
                    -- else
                    --无版本信息或不对应 解压自带ZIP
                    local nResversion = tonumber(self:getApp()._version:getResVersion())
                    if nil == nResversion then
                        self:onUnZipBase()
                    else
                        --版本同步
                        self:httpNewVersion()
                    end
                    -- end
                end
            )
        )
    )
end

--重置 base.src.app.models
function WelcomeScene:OnUpdateAfterReloadPackage()
    for k, v in pairs(package.loaded) do
        if k ~= nil then
            if type(k) == 'string' then
                if string.find(k, 'base.src.app.models.') ~= nil then
                    print('package kill:' .. k)
                    package.loaded[k] = nil
                    require(k)
                end
            end
        end
    end
end

--进入登录界面
function WelcomeScene:EnterClient()
    -- 保存版本信息
    self:getApp()._version:save()

    --重置lua package
    for k, v in pairs(package.loaded) do
        if k ~= nil then
            if type(k) == 'string' then
                if string.find(k, 'plaza.') ~= nil or string.find(k, 'game.') ~= nil then
                    print('package kill:' .. k)
                    package.loaded[k] = nil
                end
            end
        end
    end

    --无动画切换
    self:getApp():enterSceneEx(appdf.CLIENT_SRC .. 'plaza.views.LogonScene')
    --FADE切换
    -- self:getApp():enterSceneEx(appdf.CLIENT_SRC.."plaza.views.LogonScene","FADE",1)
end

--解压自带ZIP
function WelcomeScene:onUnZipBase()
    local this = self
    -- 状态提示
    self._txtTips:setString('正在解压,解压无需消耗流量...')

    if self._unZip == nil then --大厅解压
        self._unZip = 0

        --解压
        local dst = device.writablePath
        unZipAsync(
            cc.FileUtils:getInstance():fullPathForFilename('client.zip'),
            dst,
            function(result)
                this:onUnZipBase()
            end
        )
    elseif self._unZip == 0 then --默认游戏解压
        self._unZip = 1

        --解压
        local dst = device.writablePath
        unZipAsync(
            cc.FileUtils:getInstance():fullPathForFilename('game.zip'),
            dst,
            function(result)
                this:onUnZipBase()
            end
        )
    else
        -- 解压完成
        self._txtTips:setString('正在检查版本更新...')

        self._unZip = nil

        --更新本地版本号
        self:getApp()._version:setResVersion(appdf.BASE_C_RESVERSION)
        self:getApp()._version:setCmdVersion(appdf.CMD_VERSION)
        self:getApp()._version:setBaseResVersion(appdf.BASE_B_VERSION)
        for k, v in pairs(appdf.BASE_GAME) do
            self:getApp()._version:setResVersion(v.version, v.kind)
        end

        -- 保存版本信息
        self:getApp()._version:save()

        --版本同步
        self:httpNewVersion()
        return
    end
end

--执行附加脚本
function WelcomeScene:excuteExtraCmd(newVersion)
    local url = self:getApp()._updateUrl .. '/command/extra_command.luac'
    local savePath = device.writablePath .. 'command/'
    local extramodule = 'command.extra_command'

    local localver = self:getApp()._version:getCmdVersion() or appdf.CMD_VERSION

    local targetPlatform = cc.Application:getInstance():getTargetPlatform()
    if cc.PLATFORM_OS_WINDOWS == targetPlatform then
        savePath = device.writablePath .. 'download/command/'
    end

    local extra = savePath .. '/extra_command'

    -- 版本号大于本地版本 or 没有这个文件
    if newVersion > localver or not cc.FileUtils:getInstance():isFileExist(extra .. '.luac') then
        --调用C++下载
        downFileAsync(
            url,
            'extra_command.luac',
            savePath,
            function(main, sub)
                --下载回调
                if main == appdf.DOWN_PRO_INFO then --进度信息
                elseif main == appdf.DOWN_COMPELETED then --下载完毕
                    print('extra_cmd download')
                    --执行、下载附加命令脚本
                    local extra = savePath .. '/extra_command'
                    if cc.FileUtils:getInstance():isFileExist(extra .. '.luac') then
                        print('cmd exist')
                        local extracmd = appdf.req(extramodule)
                        --dump(extracmd, "extracmd", 4)
                        if
                            (nil == extracmd.excute) or
                                (false == extracmd.excute(newVersion > localver, self, self:getApp()._updateUrl))
                         then
                            --跳过执行
                            self:httpNewVersionCallBack()
                        end
                    else
                        print('cmd not exist')
                        --跳过执行
                        self:httpNewVersionCallBack()
                    end
                else
                    print('down error')
                    cc.FileUtils:getInstance():removeFile(savePath .. 'extra_command.luac')
                    --跳过执行
                    self:httpNewVersionCallBack()
                end
            end
        )
    else
        local extracmd = appdf.req(extramodule)

        if (nil == extracmd.excute) or (false == extracmd.excute(newVersion > localver, self, self:getApp()._updateUrl)) then
            --跳过执行
            self:httpNewVersionCallBack()
        end
    end
end

--同步版本
function WelcomeScene:httpNewVersion()
    local this = self

    --数据解析
    local vcallback =
        function(datatable)
        local succeed = false
		local msg = '网络连接异常...'
		
        if type(datatable) == 'table' then
            msg = nil
            local databuffer = datatable['data']
            if databuffer then
                dump(databuffer, 'databuffer', 6)

                

                --返回结果
                succeed = databuffer['valid']
                --提示文字
                local tips = datatable['msg']
                if tips and tips ~= cjson.null then
                    msg = tips
                end
                --获取信息
                if succeed == true then
                    this:getApp()._serverConfig = databuffer
                    --下载地址
                    this:getApp()._updateUrl = databuffer['downloadurl'] --test zhong "http://172.16.4.140/download/"
                    this:getApp()._updateUrl = this:getApp()._updateUrl .. '/appstore/'
                    --大厅版本
                    this._newVersion = tonumber(databuffer['clientversion']) --test zhong  0
                    --大厅资源版本
                    this._newResVersion = tonumber(databuffer['resversion'])
                    --苹果大厅更新地址
                    this._iosUpdateUrl = databuffer['ios_url']

                    local nNewV = self._newResVersion
                    local nCurV = tonumber(self:getApp()._version:getResVersion())
                    if nNewV and nCurV then
                        if nNewV > nCurV then
                            -- 更新配置
                            local updateConfig = {}
                            updateConfig.isClient = true
                            updateConfig.newfileurl = this:getApp()._updateUrl .. '/client/res/filemd5List.json'
                            updateConfig.downurl = this:getApp()._updateUrl .. '/'
                            updateConfig.dst = device.writablePath
                            local targetPlatform = cc.Application:getInstance():getTargetPlatform()
                            -- if cc.PLATFORM_OS_WINDOWS == targetPlatform then
                            -- 	updateConfig.dst = device.writablePath .. "download/client/"
                            -- end
                            updateConfig.src = device.writablePath .. 'client/res/filemd5List.json'
                            table.insert(self.m_tabUpdateQueue, updateConfig)
                        end
                    end

                    --游戏列表
                    local rows = databuffer['gamelist']
                    this:getApp()._gameList = {}
                    for k, v in pairs(rows) do
                        local gameinfo = {}
                        gameinfo._KindID = v['KindID']
                        gameinfo._KindName = string.lower(v['ModuleName']) .. '.'
                        gameinfo._Module = string.gsub(gameinfo._KindName, '[.]', '/')
                        gameinfo._KindVersion = v['ClientVersion']
                        gameinfo._ServerResVersion = tonumber(v['ResVersion'])
                        gameinfo._Type = gameinfo._Module
                        --检查本地文件是否存在
                        local path = device.writablePath .. 'game/' .. gameinfo._Module
                        gameinfo._Active = cc.FileUtils:getInstance():isDirectoryExist(path)
                        local e = string.find(gameinfo._KindName, '[.]')
                        if e then
                            gameinfo._Type = string.sub(gameinfo._KindName, 1, e - 1)
                        end
                        -- 排序
                        gameinfo._SortId = tonumber(v['SortID']) or 0

                        table.insert(this:getApp()._gameList, gameinfo)
                    end

                    table.sort(
                        this:getApp()._gameList,
                        function(a, b)
                            return a._SortId < b._SortId
                        end
                    )

                    -- 单个游戏
                    if 1 == #this:getApp()._gameList then
                        local gameInfo = this:getApp()._gameList[1]
                        local version = tonumber(this:getApp():getVersionMgr():getResVersion(gameInfo._KindID))
                        if not version or gameInfo._ServerResVersion > version then
                            local updateConfig2 = {}
                            updateConfig2.isClient = false
                            updateConfig2.newfileurl =
                                this:getApp()._updateUrl .. '/game/' .. gameInfo._Module .. '/res/filemd5List.json'
                            updateConfig2.downurl = this:getApp()._updateUrl .. '/game/' .. gameInfo._Type .. '/'
                            updateConfig2.dst = device.writablePath .. 'game/' .. gameInfo._Type .. '/'
                            -- if cc.PLATFORM_OS_WINDOWS == targetPlatform then
                            -- 	updateConfig2.dst = device.writablePath .. "download/game/" .. gameInfo._Type .. "/"
                            -- end
                            updateConfig2.src =
                                device.writablePath .. 'game/' .. gameInfo._Module .. '/res/filemd5List.json'
                            updateConfig2._ServerResVersion = gameInfo._ServerResVersion
                            updateConfig2._KindID = gameInfo._KindID
                            table.insert(self.m_tabUpdateQueue, updateConfig2)
                        end
                    end

                    -- base版本
                    this._newBaseVersion = tonumber(databuffer['baseversion'])
                    local nNewV = self._newBaseVersion
                    local nCurV = tonumber(self:getApp()._version:getBaseResVersion()) or appdf.BASE_B_VERSION
                    if nNewV and nCurV then
                        if nNewV > nCurV then
                            -- 更新配置
                            local updateConfig = {}
                            updateConfig.isBase = true
                            updateConfig.newfileurl = this:getApp()._updateUrl .. '/base/res/filemd5List.json'
                            updateConfig.downurl = this:getApp()._updateUrl .. '/'
                            updateConfig.dst = device.writablePath .. '/baseupdate/'
                            local targetPlatform = cc.Application:getInstance():getTargetPlatform()
                            -- if cc.PLATFORM_OS_WINDOWS == targetPlatform then
                            -- 	updateConfig.dst = device.writablePath .. "download/"
                            -- end
                            updateConfig.src = device.writablePath .. 'base/res/filemd5List.json'

                            table.insert(self.m_tabUpdateQueue, updateConfig)
                        end
                    end

                    -- cmd版本
					this._newCmdVersion = tonumber(databuffer['cmdversion'])
					
					-- 更新配置文件
					self:excuteExtraCmd(self._newCmdVersion)
                end
            end
		end
		
        self._txtTips:setString('')
        --if succeed then
        --else
        -- this:httpNewVersionCallBack(succeed,msg)
        --end

        if msg then
            QueryDialog:create(
                msg,
                function(bReTry)
                    if bReTry == true then
                        os.exit(0)
                    end
                end,
                nil,
                1
            ):setCanTouchOutside(false):addTo(self)
        end
    end

    appdf.onHttpJsionTable(URL_REQUEST .. '/WS/MobileInterface.ashx', 'get', 'action=getgamelist', vcallback)
    --appdf.onHttpJsionTable("http://172.16.4.140/gamelist.php","get","",vcallback)
end

--服务器版本返回
function WelcomeScene:httpNewVersionCallBack()
	local ClientConfig = appdf.req('base.src.app.models.ClientConfig')
	
	if device.platform == 'windows' then
		
		self:getApp()._version:setBaseResVersion(self._newBaseVersion)
		self:getApp()._version:setResVersion(self._newResVersion)
		self:getApp()._version:setCmdVersion(self._newCmdVersion)
		self:EnterClient()
	elseif ClientConfig.UPDATE_TO_APPSTORE == true then
		
		self:EnterClient()
	else
		self:doUpdate()
	end
end

function WelcomeScene:doUpdate()
    --升级判断
    local bUpdate = false
    local targetPlatform = cc.Application:getInstance():getTargetPlatform()

    if cc.PLATFORM_OS_WINDOWS ~= targetPlatform then
        bUpdate = self:updateClient()
    else
    end

    if not bUpdate then
        --进入登录界面
        self._txtTips:setString('正在进入游戏...')
        self:runAction(
            cc.Sequence:create(
                cc.DelayTime:create(1),
                cc.CallFunc:create(
                    function()
                        self:EnterClient()
                    end
                )
            )
        )
    end
end

--升级大厅
function WelcomeScene:updateClient()
    self.mBackGround:setTexture('background_2.png')
    local newV = self._newVersion
    local curV = appdf.BASE_C_VERSION
    if newV and curV then
        --更新APP
        if newV > curV then
            -- if device.platform == "ios" and (type(self._iosUpdateUrl) ~= "string" or self._iosUpdateUrl == "") then
            -- print("ios update fail, url is nil or empty")
            -- else

            self._txtTips:setString('')
            QueryDialog:create(
                '有新的版本，是否现在下载升级？',
                function(bConfirm)
                    if bConfirm == true then
                        self:upDateBaseApp()
                    else
                        os.exit(0)
                    end
                end
            ):setCanTouchOutside(false):addTo(self)
            return true

        -- end
        end
    end

    --资源同步
    --[[local nNewV = self._newResVersion
	local nCurV = tonumber(self:getApp()._version:getResVersion())
	if nNewV and nCurV then
		if nNewV > nCurV then
			self:goUpdate()
			return true
		end
	end]]
    if 0 ~= #self.m_tabUpdateQueue then
        self:goUpdate()
        return true
    end
    print('version did not need to update')
end

function WelcomeScene:upDateBaseApp()
    -- self.m_progressLayer:setVisible(true)
    -- self.m_totalBar:setVisible(false)
    -- self.m_spTotalBg:setVisible(false)
    -- self.m_fileBar:setVisible(true)
    -- self.m_spFileBg:setVisible(true)

    if device.platform == 'android' then
        local MultiPlatform = appdf.req(appdf.EXTERNAL_SRC .. 'MultiPlatform')
        local result = MultiPlatform:getInstance():openBrowser(appdf.CLIENT_UPDATE_URL)
        if result == true then
            os.exit(0)
        end
    elseif device.platform == 'ios' then
        local luaoc = require 'cocos.cocos2d.luaoc'
        local ok, ret = luaoc.callStaticMethod('AppController', 'updateBaseClient', {url = appdf.CLIENT_UPDATE_URL})
        if not ok then
            print('luaoc error:' .. ret)
        else
            os.exit(0)
        end
    end
end

--开始下载
function WelcomeScene:goUpdate()
    self.m_progressLayer:setVisible(true)

    local config = self.m_tabUpdateQueue[1]
    if nil == config then
        self.m_progressLayer:setVisible(false)
        self._txtTips:setString('正在进入游戏...')
        self:runAction(
            cc.Sequence:create(
                cc.DelayTime:create(1),
                cc.CallFunc:create(
                    function()
                        self:EnterClient()
                    end
                )
            )
        )
    else
        ClientUpdate:create(config.newfileurl, config.dst, config.src, config.downurl):upDateClient(self)
    end
end

--下载进度
function WelcomeScene:updateProgress(sub, msg, mainpersent)
    self:updateBar(self.m_fileBar, self.m_fileThumb, sub)
    self:updateBar(self.m_totalBar, self.m_totalThumb, mainpersent)
end

--下载结果
function WelcomeScene:updateResult(result, msg)
    local this = self
    if result == true then
        self:updateBar(self.m_fileBar, self.m_fileThumb, 0)
        self:updateBar(self.m_totalBar, self.m_totalThumb, 0)

        local config = self.m_tabUpdateQueue[1]
        if nil ~= config then
            if true == config.isClient then
                --更新本地大厅版本
                self:getApp()._version:setResVersion(self._newResVersion)
            elseif true == config.isBase then
                self:getApp()._version:setBaseResVersion(self._newBaseVersion)
                self:OnUpdateAfterReloadPackage()
            else
                self:getApp()._version:setResVersion(config._ServerResVersion, config._KindID)
                for k, v in pairs(self:getApp()._gameList) do
                    if v._KindID == config._KindID then
                        v._Active = true
                    end
                end
            end
            table.remove(self.m_tabUpdateQueue, 1)
            self:goUpdate()
        else
            --进入登录界面
            self._txtTips:setString('正在进入游戏...')
            self:runAction(
                cc.Sequence:create(
                    cc.DelayTime:create(1),
                    cc.CallFunc:create(
                        function()
                            this:EnterClient()
                        end
                    )
                )
            )
        end
    else
        self.m_progressLayer:setVisible(false)
        self:updateBar(self.m_fileBar, self.m_fileThumb, 0)
        self:updateBar(self.m_totalBar, self.m_totalThumb, 0)

        --重试询问
        self._txtTips:setString('')
        QueryDialog:create(
            msg .. '\n是否重试？',
            function(bReTry)
                if bReTry == true then
                    this:goUpdate()
                else
                    os.exit(0)
                end
            end
        ):setCanTouchOutside(false):addTo(self)
    end
end

function WelcomeScene:updateBar(bar, thumb, percent)
    if nil == bar or nil == thumb then
        return
    end
    local text_tip = bar:getChildByName('text_tip')
    if nil ~= text_tip then
        local str = string.format('%d%%', percent)
        text_tip:setString(str)
    end

    bar:setPercent(percent)
    local size = bar:getVirtualRendererSize()
    thumb:setPositionX(size.width * percent / 100)
end

-- 附加脚本执行完毕
function WelcomeScene:onCommandExcuted()
    self:getApp()._version:setCmdVersion(self._newCmdVersion)

    self:OnUpdateAfterReloadPackage()

    --同步、更新
    self:httpNewVersionCallBack()
end

return WelcomeScene
