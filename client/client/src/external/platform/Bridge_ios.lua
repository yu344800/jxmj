--
-- Author: zhong
-- Date: 2016-07-29 17:45:46
--
local Bridge_ios = {}

local luaoc = require "cocos.cocos2d.luaoc"
local BRIDGE_CLASS = "AppController"

--获取设备id
function Bridge_ios.getMachineId()
    local ok,ret = luaoc.callStaticMethod(BRIDGE_CLASS,"getUUID")
    if not ok then
        print("luaj error:" .. ret)
        return "A501164B366ECFC9E249163873094D50"
    else
        print("The ret is:" .. ret)
        return md5(ret)
    end
end

--获取设备ip
function Bridge_ios.getClientIpAdress()
    local ok,ret = luaoc.callStaticMethod(BRIDGE_CLASS,"getHostAdress")
    if not ok then
        print("luaj error:" .. ret)
        return "192.168.1.1"
    else
        print("The ret is:" .. ret)
        return ret
    end
end

--选择图片
function Bridge_ios.triggerPickImg( callback, needClip )
	needClip = needClip or false
    local args = { scriptHandler = callback, needClip = needClip }
    if nil == callback or type(callback) ~= "function" then
        print("user default callback fun")

        local function callbackLua(param)
            if type(param) == "string" then
                print(param)
            end        
        end
        args = { scriptHandler = callback, needClip = needClip }
    end    
    
    local ok,ret  = luaoc.callStaticMethod(BRIDGE_CLASS,"pickImg",args)
    if not ok then
        print("luaoc error:" .. ret)       
    end
end

--配置支付、登陆相关
function Bridge_ios.thirdPartyConfig(thirdparty, configTab)
    configTab._nidx = thirdparty
    local ok,ret  = luaoc.callStaticMethod(BRIDGE_CLASS,"thirdPartyConfig",configTab)
    if not ok then
        print("luaoc error:" .. ret)        
    end
end

function Bridge_ios.configSocial(socialTab)
    local ok,ret  = luaoc.callStaticMethod(BRIDGE_CLASS,"socialShareConfig",socialTab)
    if not ok then
        print("luaoc error:" .. ret)        
    end
end

--第三方登陆
function Bridge_ios.thirdPartyLogin(thirdparty, callback)
    local args = { _nidx = thirdparty, scriptHandler = callback }
    local ok,ret  = luaoc.callStaticMethod(BRIDGE_CLASS,"thirdLogin",args)
    if not ok then
        local msg = "luaoc error:" .. ret
        print(msg)  
        return false, msg   
    else  
        return true     
    end
end

-- 分享到指定平台
function Bridge_ios.shareToTarget( target, title, content, url, img, imgOnly, callback, _shareKey, _shareValue)
    local t = 
    {
        target = target,
        title = title,
        content = content,
        url = url,
        img = img,
        imageOnly = imgOnly,
        scriptHandler = callback,
        shareKey = _shareKey,
        shareValue = _shareValue
    }
    local ok,ret  = luaoc.callStaticMethod(BRIDGE_CLASS,"shareToTarget",t)
    if not ok then
        local msg = "luaoc error:" .. ret
        print(msg)  
        return false, msg   
    else  
        return true     
    end
end

--第三方支付
function Bridge_ios.thirdPartyPay(thirdparty, payparamTab, callback)
    payparamTab._nidx = thirdparty
    payparamTab.scriptHandler = callback
    local ok,ret  = luaoc.callStaticMethod(BRIDGE_CLASS,"thirdPartyPay",payparamTab)
    if not ok then
        local msg = "luaoc error:" .. ret
        print(msg)  
        return false, msg   
    else  
        return true     
    end
end

function Bridge_ios.isPlatformInstalled(thirdparty)
    local paramtab = { _nidx = thirdparty }
    local ok,ret  = luaoc.callStaticMethod(BRIDGE_CLASS,"isPlatformInstalled",paramtab)
    if not ok then
        local msg = "luaoc error:" .. ret
        print(msg)  
        return false, msg   
    else  
        return ret
    end
end

function Bridge_ios.saveImgToSystemGallery(filepath, filename)
    local args = { _filepath = filepath, _filename = filename }
    local ok,ret  = luaoc.callStaticMethod(BRIDGE_CLASS,"saveImgToSystemGallery",args)
    if not ok then
        local msg = "luaoc error:" .. ret
        print(msg)  
        return false, msg   
    else  
        return ret
    end
end

function Bridge_ios.checkRecordPermission()
    local args = { }
    local ok,ret = luaoc.callStaticMethod(BRIDGE_CLASS,"isHaveRecordPermission",args)
    if not ok then
        local msg = "luaoc error:" .. ret
        print(msg)  
        return false, msg   
    else  
        return ret
    end
end

function Bridge_ios.requestContact( callback )
    local paramtab = {scriptHandler = callback}
    local ok,ret = luaoc.callStaticMethod(BRIDGE_CLASS,"requestContact", paramtab)
    if not ok then
        local msg = "luaoc error:" .. ret
        print(msg)  
        return false, msg   
    else  
        return ret
    end
end

function Bridge_ios.openBrowser(url)
    local paramtab = {url = url}
    local ok,ret = luaoc.callStaticMethod(BRIDGE_CLASS,"openBrowser", paramtab)
    if not ok then
        local msg = "luaoc error:" .. ret
        print(msg)  
        return false, msg   
    else  
        return ret
    end
end

function Bridge_ios.copyToClipboard( msg )
    local paramtab = {msg = msg}
    local ok,ret = luaoc.callStaticMethod(BRIDGE_CLASS,"copyToClipboard", paramtab)
    if not ok then
        local msg = "luaoc error:" .. ret
        print(msg)  
        return 0, msg   
    else 
        print(ret)
        return ret
    end
end

function Bridge_ios.isAuthorized( thirdparty )
    local paramtab = { _nidx = thirdparty }
    local ok,ret  = luaoc.callStaticMethod(BRIDGE_CLASS,"isAuthorized",paramtab)
    if not ok then
        local msg = "luaoc error:" .. ret
        print(msg)  
        return false, msg   
    else  
        return ret
    end
end

function Bridge_ios.delAuthorized( thirdparty, callback )
    local args = { _nidx = thirdparty, scriptHandler = callback }
    local ok,ret  = luaoc.callStaticMethod(BRIDGE_CLASS,"deleteThirdPartyAuthorization",args)
    if not ok then
        local msg = "luaoc error:" .. ret
        print(msg)  
        return false, msg   
    else  
        return ret
    end
end


function Bridge_ios.getBatteryLevel() 
    local args = {  }
    local ok,ret  = luaoc.callStaticMethod(BRIDGE_CLASS,"getBatteryLevel",args)
    if not ok then
        local msg = "luaoc error:" .. ret
        print(msg)  
        return false, msg   
    else  
        return ret
    end
end

function Bridge_ios.getAppVersion() 
    local args = {  }
    local ok,ret  = luaoc.callStaticMethod(BRIDGE_CLASS,"getAppVersion",args)
    if not ok then
        local msg = "luaoc error:" .. ret
        print(msg)  
        return false, msg   
    else  
        return ret
    end
end

function Bridge_ios.getDeviceIdfv() 
    local args = {  }
    local ok,ret  = luaoc.callStaticMethod(BRIDGE_CLASS,"getDeviceIdfv",args)
    if not ok then
        local msg = "luaoc error:" .. ret
        print(msg)  
        return false, msg   
    else  
        return ret
    end
end

function Bridge_ios.getMagicWindowValue() 
    local args = {  }
    local ok,ret  = luaoc.callStaticMethod(BRIDGE_CLASS,"getMagicWindowValue",args)
    if not ok then
        local msg = "luaoc error:" .. ret
        print(msg)  
        return false, msg   
    else  
        return ret
    end
end

-- 初始定位
function Bridge_ios.initLocationManager()
    local args = {  }
    local ok,ret  = luaoc.callStaticMethod(BRIDGE_CLASS,"initLocationManager",args)
    if not ok then
        local msg = "luaj error:" .. ret
        print(msg)  
        return false, msg   
    else  
        return ret
    end
end

-- 获取定位信息
function Bridge_ios.getUserLocation()
    local args = {  }
    local ok,ret  = luaoc.callStaticMethod(BRIDGE_CLASS,"getUserLocation",args)
    if not ok then
        local msg = "luaj error:" .. ret
        print(msg)  
        return false, msg   
    else  
        return ret
    end
end

return Bridge_ios