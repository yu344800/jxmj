--
-- Author: zhong
-- Date: 2016-10-21 18:57:06
--

------
-- extra_command.lua 用于执行额外命令的脚本
-- v10.0版本
-- 用途:用于更新base部分的logo资源
------

--脚本版本
local extra_command = {}

local EXTRA_COMMAND_WAIT_SP = "__extra_cmd_wait_sp_node__"
-- 执行脚本
-- param: 本地版本号
function extra_command.excute(isUpdate, listener, url)

    -- 小于当前版本不执行
    if not isUpdate then
        print("cmd did not need to update")
        return false
    end

    print("extra_command.excute")
    
    extra_command.showWait()
    --更新
    extra_command.updateCommand(listener, url)
    return true
end

--更新命令
function extra_command.updateCommand(listener, url)
    local basepath = device.writablePath .. "/baseupdate/"
    local updateList = 
    {
        {
            filename = "AppDF.luac",
            subpath = "/base/src/app/models/",
        },
        {
            filename = "ClientConfig.luac",
            subpath = "/base/src/app/models/",
        },
    }
    local startidx = 1
    url = url or ""
    local retryCount = 3
    local function updateWork()
        if startidx > #updateList then
            extra_command.hideWait()
            listener:onCommandExcuted()
            return
        end
        --下载信息
        local filename = updateList[startidx].filename
        local dstpath = basepath .. updateList[startidx].subpath
        local fileurl = url .. updateList[startidx].subpath .. filename
        print(fileurl)

        --调用C++下载
        downFileAsync(fileurl, filename, dstpath, function(main,sub)
            --下载回调
            if main == appdf.DOWN_PRO_INFO then --进度信息
                
            elseif main == appdf.DOWN_COMPELETED then --下载完毕
                retryCount = 3
                startidx = startidx + 1
                updateWork()
            else
                print("down " .. fileurl .. " fail!")
                if sub == 28 and retryCount > 0 then
                    retryCount = retryCount - 1
                    updateWork()
                else
                    extra_command.hideWait()
                    cc.FileUtils:getInstance():removeFile(dstpath .. filename)
                    listener:onCommandExcuted()
                end
            end
        end)
    end
    updateWork()
end

function extra_command.showWait()
    local runScene = cc.Director:getInstance():getRunningScene()
    local waitSp = cc.Sprite:create("wait_round.png")
    if nil ~= waitSp and nil ~= runScene then
        waitSp:addTo(runScene)
            :setName(EXTRA_COMMAND_WAIT_SP)
            :move(appdf.WIDTH/2,appdf.HEIGHT/2 )    
            :runAction(cc.RepeatForever:create(cc.RotateBy:create(2 , 360)))
    end
end

function extra_command.hideWait()
    local runScene = cc.Director:getInstance():getRunningScene()
    if nil ~= runScene then
        runScene:removeChildByName(EXTRA_COMMAND_WAIT_SP, true)
    end
end
return extra_command