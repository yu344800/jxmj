
cc.FileUtils:getInstance():setPopupNotify(false)
-- cc.FileUtils:getInstance():addSearchPath("base/src/")
-- cc.FileUtils:getInstance():addSearchPath("base/res/")

local writePath = cc.FileUtils:getInstance():getWritablePath()
local resSearchPaths = {
    writePath .. "baseupdate/",
	"base/src/",
	"base/res/",
	writePath .. "base/res/",
    writePath .. "base/src/",
	writePath .. "client/",
    writePath .. "client/src/",
    writePath .. "client/res/",
    writePath .. "face/",
    writePath,
}
cc.FileUtils:getInstance():setSearchPaths(resSearchPaths)


require "config"
require "cocos.init"

local function main()
    
    require("app.MyApp"):create():run()
end

local status, msg = xpcall(main, __G__TRACKBACK__)
if not status then
    print(msg)
end
