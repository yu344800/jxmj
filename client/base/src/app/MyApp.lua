require("base.src.app.models.bit")
require("base.src.app.models.AppDF")
-- require("base.src.app.Toolkits.TimerProxy") --added ycc
appdf.req("base.src.app.views.layer.other.Toast")
cjson = require("cjson")

--本地调试
-- LOCAL_DEVELOP = 0

local Version = import("base.src.app.models.Version")

local MyApp = class("MyApp", cc.load("mvc").AppBase)

function MyApp:onCreate()
	
	--版本信息
	self._version = Version:create()
	--游戏信息
	self._gameList = {}
	--更新地址
	self._updateUrl = ""
	--初次启动获取的配置信息
	self._serverConfig = {}
end

function MyApp:getVersionMgr()
	return self._version
end

return MyApp
