--
-- Author: zhong
-- Date: 2016-12-17 09:48:44
--
-- 私人房数据管理 全局模式

PriRoom = PriRoom or class('PriRoom')
local private_define = appdf.req(appdf.CLIENT_SRC .. 'privatemode.header.Define_Private')
local cmd_private = appdf.req(appdf.CLIENT_SRC .. 'privatemode.header.CMD_Private')
local QueryDialog = appdf.req('app.views.layer.other.QueryDialog')

-- 私人房模块
local MODULE = private_define.tabModule
PriRoom.MODULE = MODULE
-- 私人房界面tag
local LAYTAG = private_define.tabLayTag
PriRoom.LAYTAG = LAYTAG
-- 游戏服务器登陆操作定义
local L_ACTION = private_define.tabLoginAction
PriRoom.L_ACTION = L_ACTION
-- 登陆服务器CMD
local cmd_pri_login = cmd_private.login
-- 游戏服务器CMD
local cmd_pri_game = cmd_private.game

local PriFrame = appdf.req(MODULE.PLAZAMODULE .. 'models.PriFrame')

-- roomID 输入界面
local NAME_ROOMID_INPUT = '___private_roomid_input_layername___'

local targetPlatform = cc.Application:getInstance():getTargetPlatform()
function PriRoom:ctor()
    -- 私人房大厅资源搜索路径
    -- self._searchPath = device.writablePath.."client/src/privatemode/plaza/res"
    -- cc.FileUtils:getInstance():addSearchPath(self._searchPath)
    -- 私人房游戏资源搜索路径
    -- self._gameSearchPath = ""

    --网络回调
    local privateCallBack = function(command, message, dataBuffer, notShow)
        if type(command) == 'table' then
            if command.m == cmd_pri_login.MDM_MB_PERSONAL_SERVICE then
                return self:onPrivateLoginServerMessage(command.s, message, dataBuffer, notShow)
            elseif command.m == cmd_pri_game.MDM_GR_PERSONAL_TABLE then
                return self:onPrivateGameServerMessage(command.s, message, dataBuffer, notShow)
            end
        else
            self:popMessage(message, notShow)
            if -1 == command then
                self:dismissPopWait()
            end
        end
    end
    self._priFrame = PriFrame:create(self, privateCallBack)

    self:reSet()
end

-- 实现单例
PriRoom._instance = nil
function PriRoom:getInstance()
    if nil == PriRoom._instance then
        print('new instance')
        PriRoom._instance = PriRoom:create()
    end
    return PriRoom._instance
end

function PriRoom:reSet()
    -- 私人房模式游戏列表
    self.m_tabPriModeGame = {}
    -- 私人房列表
    self.m_tabPriRoomList = {}
    -- 创建记录
    self.m_tabCreateRecord = {}
    -- 参与记录
    self.m_tabJoinRecord = {}
    -- 私人房数据  CMD_GR_PersonalTableTip
    self.m_tabPriData = {}
    -- 私人房属性 tagPersonalRoomOption
    self.m_tabRoomOption = {}
    -- 私人房费用配置 tagPersonalTableParameter
    self.m_tabFeeConfigList = {}
    -- 是否自己房主
    self.m_bIsMyRoomOwner = false
    -- 私人房桌子号( 进入/查到到的 )
    self.m_dwTableID = yl.INVALID_TABLE
    -- 选择的私人房配置信息
    self.m_tabSelectRoomConfig = {}

    -- 大厅场景
    self._scene = nil
    -- 网络消息处理层
    self._viewFrame = nil
    -- 私人房信息层
    self._priView = nil

    -- 游戏服务器登陆动作
    self.m_nLoginAction = L_ACTION.ACT_NULL
    self.cbIsJoinGame = 0
    -- 是否已经取消桌子/退出
    self.m_bCancelTable = false
    -- 是否收到结算消息
    self.m_bRoomEnd = false
    -- 参与游戏记录(用于暂离游戏时能返回游戏)
    self.m_tabJoinGameRecord = {}
    --是加入还是观战
    self.isCanJoinGame = true
end

-- 当前游戏是否开启私人房模式
function PriRoom:isCurrentGameOpenPri(nKindID)
    return (self.m_tabPriModeGame[nKindID] or false)
end

-- 获取私人房
function PriRoom:getPriRoomByServerID(dwServerID)
    -- 优先找serverID
    for k, v in pairs(self.m_tabPriRoomList) do
        if v[1].wServerID == dwServerID and v[1].wServerType == yl.GAME_GENRE_PERSONAL then
            return v[1]
        end
    end

    local currentGameRoomList = self.m_tabPriRoomList[GlobalUserItem.nCurGameKind]
    if currentGameRoomList == nil then
        return nil
    end

    for k, v in pairs(currentGameRoomList) do
        if v.wServerID == dwServerID and v.wServerType == yl.GAME_GENRE_PERSONAL then
            return v
        end
    end

    return nil
end

-- 登陆私人房
function PriRoom:onLoginRoom(dwServerID, bLockEnter)
    local pServer = self:getPriRoomByServerID(dwServerID)
    if nil == pServer then
        print('PriRoom server null')
        local curTag = nil
        if nil ~= self._scene and nil ~= self._scene._sceneRecord then
            curTag = self._scene._sceneRecord[#self._scene._sceneRecord]
        end
        if curTag == LAYTAG.LAYER_ROOMLIST and GlobalUserItem.bPrivateRoom then
            showToast(self._scene, '房间未找到, 请重试!', 2)
        end
        return false
    end

    -- 登陆房间
    if nil ~= self._priFrame and nil ~= self._priFrame._gameFrame then
        local info = self._scene:getGameInfo(pServer.wKindID)
        self._scene:updateEnterGameInfo(info)
        GlobalUserItem.nCurGameKind = tonumber(info._KindID)
        GlobalUserItem.szCurGameName = info._KindName

        bLockEnter = bLockEnter or false
        -- 锁表进入
        if bLockEnter then
            -- 动作定义
            self.m_nLoginAction = PriRoom.L_ACTION.ACT_SEARCHROOM
        end
        self:showPopWait()
        GlobalUserItem.bPrivateRoom = pServer.wServerType == yl.GAME_GENRE_PERSONAL
        self._priFrame._gameFrame:setEnterAntiCheatRoom(false)
        GlobalUserItem.nCurRoomIndex = pServer._nRoomIndex
        self._scene:onStartGame()
        self.m_bCancelTable = false
        return true
    end
    return false
end

--
function PriRoom:onEnterPlaza(scene, gameFrame)
    self._scene = scene
    self._priFrame._gameFrame = gameFrame
end

function PriRoom:onExitPlaza()
    if nil ~= self._priFrame._gameFrame then
        self._priFrame._gameFrame = nil
    end
    cc.Director:getInstance():getTextureCache():removeUnusedTextures()
    cc.SpriteFrameCache:getInstance():removeUnusedSpriteFrames()
end

function PriRoom:onEnterPlazaFinish()
    -- 判断锁表
    if GlobalUserItem.dwLockServerID ~= 0 then
        GlobalUserItem.nCurGameKind = GlobalUserItem.dwLockKindID
        -- 更新逻辑
        -- if not self._scene:updateGame(GlobalUserItem.dwLockKindID)
        if not self._scene:loadGameList(GlobalUserItem.dwLockKindID) then
            --
            local entergame = self._scene:getGameInfo(GlobalUserItem.dwLockKindID)
            if nil ~= entergame then
                self._scene:updateEnterGameInfo(entergame)
                --启动游戏
                print('PriRoom:onEnterPlazaFinish ==> lock pri game')
                return true, false, self:onLoginRoom(GlobalUserItem.dwLockServerID, true)
            end
        end
        print('PriRoom:onEnterPlazaFinish ==> lock and update game')
        return true, true, false
    end
    print('PriRoom:onEnterPlazaFinish ==> not lock game')
    return false, false, false
end

-- 登陆后进入房间列表
function PriRoom:onLoginEnterRoomList()
    -- 判断是否开启私人房
    if false == self:isCurrentGameOpenPri(GlobalUserItem.nCurGameKind) then
        print('PriRoom:onLoginEnterRoomList: not open prigame')
        return false
    end

    if GlobalUserItem.dwLockServerID ~= 0 and GlobalUserItem.dwLockKindID == GlobalUserItem.nCurGameKind then
        print('PriRoom:onLoginEnterRoomList: onLoginRoom')
        --启动游戏
        return self:onLoginRoom(GlobalUserItem.dwLockServerID, true)
    else
        print('PriRoom:onLoginEnterRoomList: self._scene:onChangeShowMode(PriRoom.LAYTAG.LAYER_ROOMLIST)')
        self._scene:onChangeShowMode(PriRoom.LAYTAG.LAYER_ROOMLIST)
        return true
    end
end

function PriRoom:onLoginPriRoomFinish()
    local onLoginPriRoomFinish = false
    -- 登录后回调创建界面 发送创建指令
    if nil ~= self._viewFrame and nil ~= self._viewFrame.onLoginPriRoomFinish then
        onLoginPriRoomFinish = self._viewFrame:onLoginPriRoomFinish()
        return
    end

    -- 清理锁表
    GlobalUserItem.dwLockServerID = 0
    GlobalUserItem.dwLockKindID = 0

    local meUser = self:getMeUserItem()
    if nil == meUser or onLoginPriRoomFinish == true then
        return
    end
    dump(meUser.cbUserStatus)
    if (meUser.cbUserStatus == yl.US_FREE or meUser.cbUserStatus == yl.US_NULL) then
        -- 搜索登陆
        if self.m_nLoginAction == L_ACTION.ACT_SEARCHROOM then
            -- 解散登陆
            print('PriRoom:onLoginPriRoomFinish [sendEnterPrivateGame]')
            self:showPopWait()

            --没坐下不进入场景
            -- self._scene:onEnterTable()

            -- 坐下
            self:getNetFrame():sendEnterPrivateGame()
        elseif self.m_nLoginAction == PriRoom.L_ACTION.ACT_DISSUMEROOM then
            print('PriRoom:onLoginPriRoomFinish [sendDissumeGame]')
            self:showPopWait()
            -- 发送解散
            self:getNetFrame():sendDissumeGame(self.m_dwTableID)
        elseif self.m_nLoginAction == PriRoom.L_ACTION.ACT_CREATEROOM then
            -- 切换游戏场景
            self._scene:onEnterTable()
            -- 发送配置
            self._priFrame._gameFrame:SendGameOption()
        else
            self:popMessage('私人房间已经解散！')
            self._priFrame._gameFrame:onCloseSocket()
            self._priFrame:onCloseSocket()
            GlobalUserItem.nCurRoomIndex = -1

            -- 退出游戏房间
            self._scene:onKeyBack()
        end
    elseif
        meUser.cbUserStatus == yl.US_PLAYING or meUser.cbUserStatus == yl.US_READY or meUser.cbUserStatus == yl.US_SIT
     then
        -- 搜索登陆/创建登录
        if
            self.m_nLoginAction == PriRoom.L_ACTION.ACT_SEARCHROOM or
                self.m_nLoginAction == PriRoom.L_ACTION.ACT_ENTERTABLE or
                self.m_nLoginAction == PriRoom.L_ACTION.ACT_CREATEROOM
         then
            -- 解散登陆
            print('PriRoom:onLoginPriRoomFinish [SendGameOption]')
            self:showPopWait()
            -- 切换游戏场景
            self._scene:onEnterTable()
            -- 发送配置
            self._priFrame._gameFrame:SendGameOption()
        elseif self.m_nLoginAction == PriRoom.L_ACTION.ACT_DISSUMEROOM then
            print('PriRoom:onLoginPriRoomFinish [sendDissumeGame]')
            self:showPopWait()
            -- 发送解散
            self:getNetFrame():sendDissumeGame(self.m_dwTableID)
        end
    end
end

-- 用户状态变更( 进入、离开、准备 等)
function PriRoom:onEventUserState(viewid, useritem, bLeave)
    bLeave = bLeave or false
    if self.m_bCancelTable then
        return
    end
    if nil ~= self._priView and nil ~= self._priView.onRefreshInviteBtn then
        self._priView:onRefreshInviteBtn()
    end
end

function PriRoom:popMessage(message, notShow)
    notShow = notShow or false
    if type(message) == 'string' and '' ~= message then
        if notShow or nil == self._scene then
            print(message)
        elseif nil ~= self._scene then
            showToast(self._scene, message, 2)
        end
    end
end

function PriRoom:onPrivateLoginServerMessage(result, message, dataBuffer, notShow)
    -- self:popMessage(message, notShow)

    -- if cmd_pri_login.SUB_MB_QUERY_PERSONAL_ROOM_LIST_RESULT == result
    --     or cmd_pri_login.SUB_GR_USER_QUERY_ROOM_SCORE_RESULT == result then
    --     -- 列表记录
    --     if nil ~= self._viewFrame and nil ~= self._viewFrame.onReloadRecordList then
    --         self._viewFrame:onReloadRecordList()
    --     end
    -- elseif cmd_pri_login.SUB_MB_PERSONAL_FEE_PARAMETER == result then
    --     print("PriRoom fee list call back")
    -- end
    self:dismissPopWait()
end

function PriRoom:onPrivateGameServerMessage(result, message, dataBuffer, notShow)
    self:popMessage(message, notShow)
    self:dismissPopWait()
    self.message = message
    if cmd_pri_game.SUB_GR_CREATE_SUCCESS == result then
        -- 创建成功
        if self.m_tabRoomOption.cbIsJoinGame == 1 then
            -- 必须加入
            self._viewFrame:dismiss()
            self:setViewFrame(nil)

            self:onLoginPriRoomFinish()
        elseif nil ~= self._viewFrame and nil ~= self._viewFrame.onRoomCreateSuccess then
            self._viewFrame:onRoomCreateSuccess()
        end
    elseif cmd_pri_game.SUB_GR_CANCEL_TABLE == result then
        print('PriRoom  SUB_GR_CANCEL_TABLE')
        GlobalUserItem.bWaitQuit = true
        self.m_bCancelTable = true
        -- 清理暂离记录
        self.m_tabJoinGameRecord[GlobalUserItem.nCurGameKind] = {}
        -- 解散桌子
        local curTag = nil
        if nil ~= self._scene and nil ~= self._scene._sceneRecord then
            curTag = self._scene._sceneRecord[#self._scene._sceneRecord]
        end
        if curTag == yl.SCENE_GAME and not self.m_bRoomEnd then
            local zorder = 0
            if nil ~= self._viewFrame.priGameLayerZorder then
                zorder = self._viewFrame:priGameLayerZorder() - 1
            end

            QueryDialog:create(
                message.szDescribeString,
                function(ok)
                    GlobalUserItem.bWaitQuit = false
                    if nil ~= self._viewFrame and nil ~= self._viewFrame.onExitRoom then
                        self._viewFrame:onExitRoom()
                    end
                end
            ):setLocalZOrder(zorder):setCanTouchOutside(false):addTo(self._viewFrame)
        else
            showToast(self._viewFrame, message.szDescribeString, 2)
        end
        self.m_bRoomEnd = false
    elseif cmd_pri_game.SUB_GR_CANCEL_REQUEST == result then
        -- 请求解散
        local request = message.CancelRequest
        local useritem = self._priFrame._gameFrame._UserList[request.dwUserID]
        if nil == useritem then
            return
        end
        local curTag = nil
        if nil ~= self._scene and nil ~= self._scene._sceneRecord then
            curTag = self._scene._sceneRecord[#self._scene._sceneRecord]
        end

        if curTag == yl.SCENE_GAME then
            self.waitCancelReply =
                QueryDialog:create(
                useritem.szNickName .. '请求解散房间, 是否同意?',
                function(ok)
                    if ok then
                        self:getNetFrame():sendRequestReply(1)

                        self.waitCancelReply =
                            QueryDialog:create('等待其他玩家同意解散房间...'):setCanTouchOutside(false):addTo(self._viewFrame)
                    else
                        self:getNetFrame():sendRequestReply(0)
                    end
                end,
                30,
                QueryDialog.QUERY_AGGRE_ORNO,
                {time = message.CancelRequestTime}
            ):setCanTouchOutside(false):addTo(self._viewFrame)
        else
        end
    elseif cmd_pri_game.SUB_GR_REQUEST_REPLY == result then
        -- 请求答复
        -- message = game.CMD_GR_RequestReply
        local useritem = self._priFrame._gameFrame._UserList[message.dwUserID]
        if nil == useritem then
            return
        end
        local bHandled = false
        if nil ~= self._viewFrame and nil ~= self._viewFrame.onCancellApply then
            bHandled = self._viewFrame:onCancellApply(useritem, message)
        end
        if not bHandled then
            local tips = '同意解散'
            if 0 == message.cbAgree then
                tips = '不同意解散'
            end
            local curTag = nil
            if nil ~= self._scene and nil ~= self._scene._sceneRecord then
                curTag = self._scene._sceneRecord[#self._scene._sceneRecord]
            end
            if curTag == yl.SCENE_GAME then
                showToast(self._viewFrame, useritem.szNickName .. tips, 2)
            end
        end
    elseif cmd_pri_game.SUB_GR_REQUEST_RESULT == result then
        -- 请求结果
        -- message = game.CMD_GR_RequestResult
        if 0 == message.cbResult then
            local curTag = nil
            if nil ~= self._scene and nil ~= self._scene._sceneRecord then
                curTag = self._scene._sceneRecord[#self._scene._sceneRecord]
            end
            if curTag == yl.SCENE_GAME then
                showToast(self._viewFrame, '解散房间请求未通过', 2)

                if self.waitCancelReply and self.waitCancelReply.dismiss then
                    self.waitCancelReply:dismiss()
                    self.waitCancelReply = nil
                end
            end
            return
        end
        self.m_bCancelTable = true
        local bHandled = false
        if nil ~= self._viewFrame and nil ~= self._viewFrame.onCancelResult then
            bHandled = self._viewFrame:onCancelResult(message)
        end
        if not bHandled then
        end

        self.m_bRoomEnd = true
    elseif cmd_pri_game.SUB_GR_WAIT_OVER_TIME == result then
        -- 超时提示
        -- message = game.CMD_GR_WaitOverTime
        local useritem = self._priFrame._gameFrame._UserList[message.dwUserID]
        if nil == useritem then
            return
        end
        local curTag = nil
        if nil ~= self._scene and nil ~= self._scene._sceneRecord then
            curTag = self._scene._sceneRecord[#self._scene._sceneRecord]
        end
        if curTag == yl.SCENE_GAME then
            QueryDialog:create(
                useritem.szNickName .. '断线等待超时, 是否继续等待?',
                function(ok)
                    if ok then
                        self:getNetFrame():sendRequestReply(0)
                    else
                        self:getNetFrame():sendRequestReply(1)
                    end
                    --self:showPopWait()
                end
            ):setCanTouchOutside(false):addTo(self._viewFrame)
        end
    elseif cmd_pri_game.SUB_GR_PERSONAL_TABLE_TIP == result then
        -- 游戏信息
        if nil ~= self._priView and nil ~= self._priView.onRefreshInfo then
            self._priView:onRefreshInfo()
        end
    elseif cmd_pri_game.SUB_GR_PERSONAL_TABLE_END == result then
        GlobalUserItem.bWaitQuit = true
        -- 屏蔽重连功能
        GlobalUserItem.bAutoConnect = false
        -- 清理暂离记录
        self.m_tabJoinGameRecord[GlobalUserItem.nCurGameKind] = {}

        self.m_bRoomEnd = true

        -- 结束消息 _viewFrame GameLayer
        if nil ~= self._viewFrame and nil ~= self._viewFrame.onPriGameEnd then
            -- dump('结束')
            self._viewFrame:onPriGameEnd(message, self.m_bRoomEnd)
        elseif nil ~= self._priView and nil ~= self._priView.onPriGameEnd then
            self._priView:onPriGameEnd(message, self.m_bRoomEnd)
        end

        if self.waitCancelReply and self.waitCancelReply.dismiss then
            self.waitCancelReply:dismiss()
            self.waitCancelReply = nil
        end
    elseif cmd_pri_game.SUB_GR_CANCEL_TABLE_RESULT == result then
        -- 解散结果
        -- message = game.CMD_GR_DissumeTable
        if 1 == message.cbIsDissumSuccess then
            showToast(self._viewFrame, '解散成功', 2)

            if self.waitCancelReply and self.waitCancelReply.dismiss then
                self.waitCancelReply:dismiss()
                self.waitCancelReply = nil
            end
        end
    elseif cmd_pri_game.SUB_GF_PERSONAL_MESSAGE == result then
        if nil == self._viewFrame then
            self._scene:onKeyBack()
            return
        end
        QueryDialog:create(
            message.szMessage,
            function(ok)
                if nil ~= self._viewFrame and nil ~= self._viewFrame.onExitRoom then
                    self._viewFrame:onExitRoom()
                end
            end,
            nil,
            1
        ):setCanTouchOutside(false):addTo(self._viewFrame)
    elseif cmd_pri_game.SUB_GR_CURRECE_ROOMCARD_AND_BEAN == result then
        -- 解散后游戏信息
        if nil ~= self._viewFrame and nil ~= self._viewFrame.onRefreshInfo then
            self._viewFrame:onRefreshInfo()
        end
    end
end

-- 网络管理
function PriRoom:getNetFrame()
    return self._priFrame
end

-- 设置网络消息处理层
function PriRoom:setViewFrame(viewFrame)
    self._viewFrame = viewFrame
end

-- 获取自己数据
function PriRoom:getMeUserItem()
    return self._priFrame._gameFrame:GetMeUserItem()
end

-- 获取游戏玩家数(椅子数)
function PriRoom:getChairCount()
    return self._priFrame._gameFrame:GetChairCount()
end

-- 设置游戏玩家数(椅子数)
function PriRoom:setChairCount(_chairCount)
    self._priFrame._gameFrame._wChairCount = _chairCount
end

-- 获取大厅场景
function PriRoom:getPlazaScene()
    return self._scene
end

-- 界面切换
function PriRoom:getTagLayer(tag, param, scene)
    return nil
end

-- 进入游戏房间
function PriRoom:enterRoom(scene)
    self:exitRoom()
    local entergame = scene:getEnterGameInfo()
    local bPirMode = self:isCurrentGameOpenPri(GlobalUserItem.nCurGameKind)
    if nil ~= entergame and true == bPirMode then
        local modulestr = string.gsub(entergame._KindName, '%.', '/')
        local path = device.writablePath .. 'game/' .. modulestr .. 'res/privateroom/'
        cc.FileUtils:getInstance():addSearchPath(path)

        -- 初始游戏设置
        self.m_tabPriData = {}
    end
    return bPirMode
end

function PriRoom:exitRoom()
    if self._viewFrame == nil then
        return
    end

    --重置搜索路径
    -- self._gameSearchPath = ""

    -- 重置游戏设置记录
    self.m_tabPriData = nil
    self.m_nLoginAction = nil
    self.m_tabRoomOption = nil
    -- 清理暂离记录
    self.m_tabJoinGameRecord = {}

    self:resetSearchPaths()
    self:setViewFrame(nil)
end

function PriRoom:resetSearchPaths()
    local writePath = device.writablePath
    local resSearchPaths = {
        writePath .. 'baseupdate/',
        'base/src/',
        'base/res/',
        writePath .. 'base/res/',
        writePath .. 'base/src/',
        writePath .. 'client/',
        writePath .. 'client/src',
        writePath .. 'client/res/',
        writePath .. 'face/',
        writePath
    }
    cc.FileUtils:getInstance():setSearchPaths(resSearchPaths)
end

-- 进入游戏界面
function PriRoom:createPriRoomScene(modulestr, scene)
    if self:enterRoom(scene) == false then
        return
    end

    local gamePriLayerPath = ''

    local modulestr_2 = string.gsub(modulestr, '%.', '/')

    if cc.PLATFORM_OS_WINDOWS == targetPlatform then
        gamePriLayerPath = 'game/' .. modulestr_2 .. 'src/privateroom/PriGameLayer.lua'
    else
        gamePriLayerPath = 'game/' .. modulestr_2 .. 'src/privateroom/PriGameLayer.luac'
    end

    local lay

    if cc.FileUtils:getInstance():isFileExist(gamePriLayerPath) then
        lay = appdf.req(gamePriLayerPath):create()
    end

    local gameLayer = appdf.req(appdf.GAME_SRC .. modulestr .. 'src.views.GameLayer'):create(scene._gameFrame, scene)

    if lay ~= nil then
        lay._gameLayer = gameLayer
        gameLayer:addPrivateGameLayer(lay)
        gameLayer._gameView._priView = lay
        self._priView = lay
    end

    self.m_bRoomEnd = false

    -- 绑定回调
    self:setViewFrame(gameLayer)

    return gameLayer
end

-- 退出游戏界面
function PriRoom:exitGame()
    self._priView = nil
    self._viewFrame = nil
end

function PriRoom:showPopWait()
    if nil ~= self._scene then
        self._scene:showPopWait()
    end
end

function PriRoom:dismissPopWait()
    if nil ~= self._scene then
        self._scene:dismissPopWait()
    end
end

-- 请求解散房间
function PriRoom:queryDismissRoom()
    if self.m_bCancelTable then
        print('PriRoom:queryDismissRoom 已经取消!')
        return
    end
    -- 观战/ 经过解散 房间已经不存在    /  解散后 or 进入游戏服某原因被踢 导致游戏服已经断开
    if not self.isCanJoinGame or self.m_bRoomEnd == true or self._priFrame._gameFrame:isSocketServer() == false then
        self._viewFrame:onExitTable()
        return
    end

    local tip = ''

    if 1 == self.cbIsJoinGame and self.m_bIsMyRoomOwner then
        tip = '你是房主, 是否要解散该房间?'
    else
        tip = '是否要退出房间?'
    end
    -- if 1 == self.cbIsJoinGame and self.m_bIsMyRoomOwner and GlobalUserItem.GameSelect == 'dkRoom' then
    --     tip = '是否要退出代开房间?'
    -- end
    if 0 ~= self.m_tabPriData.dwPlayCount then
        tip = '约战房在游戏中退出需其他玩家同意, 是否申请解散房间?'
    end

    QueryDialog:create(
        tip,
        function(ok)
            if ok == true then
                    
                if self.m_tabPriData.dwPlayCount == 0 then
                   
                    if 1 == self.cbIsJoinGame and self.m_bIsMyRoomOwner then --and GlobalUserItem.GameSelect == '' then
                        --elseif 1 == self.cbIsJoinGame and self.m_bIsMyRoomOwner and GlobalUserItem.GameSelect == 'dkRoom' then
                        --self._viewFrame:onExitTable()
                        -- self:getNetFrame():sendDissumeGame(self.m_dwTableID)
                        -- 游戏已经开始
                        self:getNetFrame():sendRequestDissumeGame()
                    else
                        --dump('退出')
                        self._viewFrame:onExitTable()
                    end
                else
                    -- 游戏已经开始
                    self:getNetFrame():sendRequestDissumeGame()

                    tip = '等待其他玩家同意解散房间...'

                    self.waitCancelReply = QueryDialog:create(tip):setCanTouchOutside(false):addTo(self._viewFrame)
                end
            end
        end
    ):setCanTouchOutside(false):addTo(self._viewFrame)
end

-- 获取邀请分享内容
function PriRoom:getInviteShareMsg(roomDetailInfo)
    local entergame = self._scene:getEnterGameInfo()
    if nil ~= entergame then
        local modulestr = string.gsub(entergame._KindName, '%.', '/')
        local gameFile = ''
        if cc.PLATFORM_OS_WINDOWS == targetPlatform then
            gameFile = 'game/' .. modulestr .. 'src/privateroom/PriRoomCreateLayer.lua'
        else
            gameFile = 'game/' .. modulestr .. 'src/privateroom/PriRoomCreateLayer.luac'
        end
        if cc.FileUtils:getInstance():isFileExist(gameFile) then
            return appdf.req(gameFile):getInviteShareMsg(roomDetailInfo)
        end
    end
    return {title = '', content = ''}
end

-- 私人房邀请好友
function PriRoom:priInviteFriend(frienddata, gameKind, wServerNumber, tableId, inviteMsg)
    if nil == frienddata or nil == self._scene.inviteFriend then
        return
    end
    if not gameKind then
        gameKind = GlobalUserItem.nCurGameKind
    else
        gameKind = tonumber(gameKind)
    end
    local id = frienddata.dwUserID
    if nil == id then
        return
    end
    local tab = {}
    tab.dwInvitedUserID = id
    tab.wKindID = gameKind
    tab.wServerNumber = wServerNumber or 0
    tab.wTableID = tableId or 0
    tab.szInviteMsg = inviteMsg or ''
    if FriendMgr:getInstance():sendInvitePrivateGame(tab) then
        local runScene = cc.Director:getInstance():getRunningScene()
        if nil ~= runScene then
            showToast(runScene, '邀请消息已发送!', 1)
        end
    end
end

-- 分享图片给好友
function PriRoom:imageShareToFriend(frienddata, imagepath, sharemsg)
    if nil == frienddata or nil == self._scene.imageShareToFriend then
        return
    end
    local id = frienddata.dwUserID
    if nil == id then
        return
    end
    self._scene:imageShareToFriend(id, imagepath, sharemsg)
end

-- 暂离游戏
-- @param[nKindId] 游戏kindid
-- @param[szRoomId] 房间id
function PriRoom:tempLeaveGame(nKindId, szRoomId)
    nKindId = nKindId or GlobalUserItem.nCurGameKind
    szRoomId = szRoomId or self.m_tabPriData.szServerID
    local joinGame = {roomid = szRoomId}
    self.m_tabJoinGameRecord[nKindId] = joinGame

    self:getNetFrame()._gameFrame:setEnterAntiCheatRoom(false)
    self:getNetFrame()._gameFrame:onCloseSocket()
end
