--
-- Author: zhong
-- Date: 2016-12-12 18:54:32
--
local _M = {}

-- 传一个false的clientConfig.luac文件 在服务器更新目录下 就可以了


-- 提审时把appdf CMD_VERSION 版本大于后台设置的版本 和  _M.UPDATE_TO_APPSTORE					= true
-- 过了提审后再把后台版本号升上来

_M.UPDATE_TO_APPSTORE					= false									-- 提审模式


return _M