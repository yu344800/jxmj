local BaseFrame = appdf.req(appdf.CLIENT_SRC .. 'plaza.models.BaseFrame')
local GameFrameEngine = class('GameFrameEngine', BaseFrame)

local UserItem = appdf.req(appdf.CLIENT_SRC .. 'plaza.models.ClientUserItem')
local game_cmd = appdf.req(appdf.HEADER_SRC .. 'CMD_GameServer')
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. 'ExternalFun')
local GameChatLayer = appdf.req(appdf.CLIENT_SRC.."plaza.views.layer.game.GameChatLayer")

GameFrameEngine.NET_LISTENER = {
    'UpdateUserLocation'
}

function GameFrameEngine:ctor(view, callbcak)
    GameFrameEngine.super.ctor(self, view, callbcak)
    self._kindID = 0
    self._kindVersion = 0

    -- 短连接服务
    self._shotFrame = nil

    self:onInitData()

    self:createMsgEventlistBinding()
end
--设置类信息
function GameFrameEngine:setKindInfo(id, version)
    self._kindID = id
    self._kindVersion = version
    return self
end
--初始数据
function GameFrameEngine:onInitData()
    --房间信息 以后转移
    self._wTableCount = 0
    self._wChairCount = 0
    self._wServerType = 0
    self._dwServerRule = 0
    self._UserList = {}
    self._tableUserList = {}
    self._tableStatus = {}
    self._delayEnter = false

    self._wTableID = PriRoom:getInstance().m_dwTableID or yl.INVALID_TABLE
    self._wChairID = yl.INVALID_CHAIR
    self._cbTableLock = 0
    self._cbGameStatus = 0
    self._cbAllowLookon = 0
    self.bChangeDesk = false
    self.bEnterAntiCheatRoom = false --进入防作弊房间
    GlobalUserItem.bWaitQuit = false -- 退出等待
end

function GameFrameEngine:setEnterAntiCheatRoom(bEnter)
    self.bEnterAntiCheatRoom = bEnter
end

--连接房间
function GameFrameEngine:onLogonRoom()
    self._roomInfo = GlobalUserItem.GetRoomInfo()

    if not self._roomInfo and nil ~= self._callBack then
        self._callBack(-1, '获取房间信息失败！')
        return
    end
    print('登录房间：' .. self._roomInfo.szServerAddr .. '#' .. self._roomInfo.wServerPort)
    if not self:onCreateSocket(self._roomInfo.szServerAddr, self._roomInfo.wServerPort) and nil ~= self._callBack then
        self._callBack(-1, '建立连接失败！')
    end
end
--连接结果
function GameFrameEngine:onConnectCompeleted()
    if nil ~= self._socket then
        self._socket:setdelaytime(0)
    -- self._socket:setovertime(86400000)
    end

    local targetPlatform = cc.Application:getInstance():getTargetPlatform()

    local dataBuffer = CCmd_Data:create(213)

    --初始化参数
    self:onInitData()

    dataBuffer:setcmdinfo(yl.MDM_GR_LOGON, yl.SUB_GR_LOGON_MOBILE)
    dataBuffer:pushword(self._kindID)
    dataBuffer:pushdword(self._kindVersion)

    dataBuffer:pushbyte(yl.DEVICE_TYPE_LIST[targetPlatform])
    dataBuffer:pushword(0x0011)
    dataBuffer:pushword(255)

    dataBuffer:pushdword(GlobalUserItem.dwUserID)
    dataBuffer:pushstring(GlobalUserItem.szDynamicPass, 33)
    dataBuffer:pushstring(GlobalUserItem.szRoomPasswd, 33)
    dataBuffer:pushstring(GlobalUserItem.szMachine, 33)

    if not self:sendSocketData(dataBuffer) and nil ~= self._callBack then
        self._callBack(-1, '发送登录失败！')
    else
        self._callBack(900)
    end
end

--网络信息
function GameFrameEngine:onSocketEvent(main, sub, dataBuffer)
    print('GameFrameEngine:onSocketEvent ==> ' .. main .. '##' .. sub)
    --登录信息
    if main == yl.MDM_GR_LOGON then
        --配置信息
        self:onSocketLogonEvent(sub, dataBuffer)
    elseif main == yl.MDM_GR_CONFIG then
        --用户信息
        self:onSocketConfigEvent(sub, dataBuffer)
    elseif main == yl.MDM_GR_USER then
        --状态信息
        self:onSocketUserEvent(sub, dataBuffer)
    elseif main == yl.MDM_GR_STATUS then
        self:onSocketStatusEvent(sub, dataBuffer)
    elseif main == yl.MDM_GF_FRAME then
        self:onSocketFrameEvent(sub, dataBuffer)
    elseif main == yl.MDM_GF_GAME then
        if self._viewFrame and self._viewFrame.onEventGameMessage then
            self._viewFrame:onEventGameMessage(sub, dataBuffer)
        end
    elseif main == game_cmd.MDM_GR_INSURE then
        --[[elseif main == game_cmd.MDM_GR_TASK 
		or main == game_cmd.MDM_GR_PROPERTY 
		then
		-- 短连接服务
		if nil ~= self._shotFrame and nil ~= self._shotFrame.onGameSocketEvent then
			self._shotFrame:onGameSocketEvent(main,sub,dataBuffer)
		end]]
        if self._viewFrame and self._viewFrame.onSocketInsureEvent then
            self._viewFrame:onSocketInsureEvent(sub, dataBuffer)
        end

        -- 短连接服务
        if nil ~= self._shotFrame and nil ~= self._shotFrame.onGameSocketEvent then
            self._shotFrame:onGameSocketEvent(main, sub, dataBuffer)
        end
    else
        -- 短连接服务
        if nil ~= self._shotFrame and nil ~= self._shotFrame.onGameSocketEvent then
            self._shotFrame:onGameSocketEvent(main, sub, dataBuffer)
        end
        -- 私人房
        if PriRoom then
            PriRoom:getInstance():getNetFrame():onGameSocketEvent(main, sub, dataBuffer)
        end
    end
end
--登录连接
function GameFrameEngine:onSocketLogonEvent(sub, dataBuffer)
    --登录完成
    if sub == game_cmd.SUB_GR_LOGON_FINISH then
        -- 登录成功
        self:onSocketLogonFinish()
    elseif sub == game_cmd.SUB_GR_LOGON_SUCCESS then
        --登录失败
        local cmd_table = ExternalFun.read_netdata(game_cmd.CMD_GR_LogonSuccess, dataBuffer)
        dump(cmd_table, 'CMD_GR_LogonSuccess', 4)
    elseif sub == game_cmd.SUB_GR_LOGON_FAILURE then
        --升级提示
        local errorCode = dataBuffer:readint()
        local msg = dataBuffer:readstring()
        print('登录房间失败:' .. errorCode .. '#' .. msg)
        self:onCloseSocket()
        if nil ~= self._callBack then
            self._callBack(-1, '登录房间失败:' .. errorCode .. '#' .. msg)
        end
    elseif sub == game_cmd.SUB_GR_UPDATE_NOTIFY then
        if nil ~= self._callBack then
            self._callBack(-1, '版本信息错误')
        end
    end
end

--登录完成
function GameFrameEngine:onSocketLogonFinish()
    if self._delayEnter == true then
        return
    end

    local myUserItem = self:GetMeUserItem()
    if not myUserItem and nil ~= self._callBack then
        self._callBack(-1, '获取自己信息失败！')
        return
    end
    if GlobalUserItem.bPrivateRoom and PriRoom then
        PriRoom:getInstance():onLoginPriRoomFinish()
    else
        if self._wTableID ~= yl.INVALID_TABLE then
            if self._viewFrame and self._viewFrame.onEnterTable then
                self._viewFrame:onEnterTable()
            --showToast(self._viewFrame,"找到游戏桌子，正在获取场景中...",1)
            end
            self:SendGameOption()
        else
            --[[if self._viewFrame and self._viewFrame.onEnterRoom then
				self._viewFrame:onEnterRoom()
			end]]
        end
    end

    -- 清理锁表
    GlobalUserItem.dwLockServerID = 0
    GlobalUserItem.dwLockKindID = 0
end

--房间配置
function GameFrameEngine:onSocketConfigEvent(sub, dataBuffer)
    --房间配置
    if sub == yl.SUB_GR_CONFIG_SERVER then
        --配置完成
        self._wTableCount = dataBuffer:readword()
        self._wChairCount = dataBuffer:readword()
        self._wServerType = dataBuffer:readword()
        self._dwServerRule = dataBuffer:readdword()
        GlobalUserItem.dwServerRule = self._dwServerRule

        --是否进入防作弊
        self:setEnterAntiCheatRoom(GlobalUserItem.isAntiCheat())
        print(
            '房间配置[table:' ..
                self._wTableCount ..
                    '][chair:' ..
                        self._wChairCount .. '][type:' .. self._wServerType .. '][rule:' .. self._dwServerRule .. ']'
        )
    elseif sub == yl.SUB_GR_CONFIG_FINISH then
    end
end
--获取table数量
function GameFrameEngine:GetTableCount()
    return self._wTableCount
end
--获取椅子数量
function GameFrameEngine:GetChairCount()
    return self._wChairCount
end
--获取服务器类型
function GameFrameEngine:GetServerType()
    return self._wServerType
end
-- 获取服务器规则/协议？
function GameFrameEngine:GetServerRule()
    return self._dwServerRule
end

--房间取款准许
function GameFrameEngine:OnRoomAllowBankTake()
    return bit:_and(self._dwServerRule, 0x00010000) ~= 0
end

--房间存款准许
function GameFrameEngine:OnRoomAllowBankSave()
    return bit:_and(self._dwServerRule, 0x00040000) ~= 0
end

--游戏取款准许
function GameFrameEngine:OnGameAllowBankTake()
    return bit:_and(self._dwServerRule, 0x00020000) ~= 0
end

--游戏存款准许
function GameFrameEngine:OnGameAllowBankSave()
    return bit:_and(self._dwServerRule, 0x00080000) ~= 0
end

function GameFrameEngine:IsAllowAvertCheatMode()
    return bit:_and(self._dwServerRule, yl.SR_ALLOW_AVERT_CHEAT_MODE) ~= 0
end

--是否更新大厅游戏币
function GameFrameEngine:IsAllowPlazzScoreChange()
    return (self._wServerType ~= yl.GAME_GENRE_SCORE) and (self._wServerType ~= yl.GAME_GENRE_EDUCATE)
end

--游戏赠送准许
function GameFrameEngine:OnGameAllowBankTransfer()
    return false
end

--用户信息
function GameFrameEngine:onSocketUserEvent(sub, dataBuffer)
    --等待分配
    if sub == game_cmd.SUB_GR_USER_WAIT_DISTRIBUTE then
        --用户进入
        --showToast(self._viewFrame, "正在进行分组,请稍后...", 3)
        print('正在进行分组,请稍后...')
    elseif sub == yl.SUB_GR_USER_ENTER then
        --用户积分
        self:onSocketUserEnter(dataBuffer)
    elseif sub == yl.SUB_GR_USER_SCORE then
        --用户状态
        self:onSocketUserScore(dataBuffer)
    elseif sub == yl.SUB_GR_USER_STATUS then
        self:onSocketUserStatus(dataBuffer)
    elseif sub == yl.SUB_GR_REQUEST_FAILURE then
        --请求失败
        self:onSocketReQuestFailure(dataBuffer)
    end
end
--用户进入
function GameFrameEngine:onSocketUserEnter(dataBuffer)
    local userItem = UserItem:create()

    userItem.dwGameID = dataBuffer:readdword()
    userItem.dwUserID = dataBuffer:readdword()

    --自己判断
    local bMySelfInfo = (userItem.dwUserID == GlobalUserItem.dwUserID)

    local int64 = Integer64.new()

    --读取信息
    userItem.wFaceID = dataBuffer:readword()
    userItem.dwCustomID = dataBuffer:readdword()

    userItem.cbGender = dataBuffer:readbyte()
    userItem.cbMemberOrder = dataBuffer:readbyte()

    userItem.wTableID = dataBuffer:readword()
    userItem.wChairID = dataBuffer:readword()
    userItem.cbUserStatus = dataBuffer:readbyte()

    userItem.lScore = dataBuffer:readscore(int64):getvalue()
    userItem.lIngot = dataBuffer:readscore(int64):getvalue()
    userItem.dBeans = dataBuffer:readdouble()

    userItem.dwWinCount = dataBuffer:readdword()
    userItem.dwLostCount = dataBuffer:readdword()
    userItem.dwDrawCount = dataBuffer:readdword()
    userItem.dwFleeCount = dataBuffer:readdword()
    userItem.dwExperience = dataBuffer:readdword()
    userItem.lIntegralCount = dataBuffer:readscore(int64):getvalue()
    userItem.dwAgentID = dataBuffer:readdword()
    userItem.dwIpAddress = dataBuffer:readdword() -- ip地址
    userItem.dwDistance = nil -- 距离

    local curlen = dataBuffer:getcurlen()
    local datalen = dataBuffer:getlen()
    local tmpSize
    local tmpCmd
    while curlen < datalen do
        tmpSize = dataBuffer:readword()
        tmpCmd = dataBuffer:readword()
        if not tmpSize or not tmpCmd then
            break
        end
        if tmpCmd == yl.DTP_GR_NICK_NAME then
            userItem.szNickName = dataBuffer:readstring(tmpSize / 2)

            if
                not userItem.szNickName or
                    (self:IsAllowAvertCheatMode() == true and userItem.dwUserID ~= GlobalUserItem.dwUserID)
             then
                userItem.szNickName = '游戏玩家'
            end
        elseif tmpCmd == yl.DTP_GR_UNDER_WRITE then
            userItem.szSign = dataBuffer:readstring(tmpSize / 2)
            if
                not userItem.szSign or
                    (self:IsAllowAvertCheatMode() == true and userItem.dwUserID ~= GlobalUserItem.dwUserID)
             then
                userItem.szSign = '此人很懒，没有签名'
            end
        elseif tmpCmd == 0 then
            break
        else
            for i = 1, tmpSize do
                if not dataBuffer:readbyte() then
                    break
                end
            end
        end
        curlen = dataBuffer:getcurlen()
    end
    -- print("GameFrameEngine enter ==> ", userItem.szNickName, userItem.dwIpAddress, userItem.dwDistance)

    -- userItem:testlog()
    dump(userItem)
    --记录自己桌椅号
    if userItem.dwUserID == GlobalUserItem.dwUserID then
        self._wChairID = userItem.wChairID
        self._wTableID = userItem.wTableID

        if self._delayEnter == true then
            self._delayEnter = false
        end
    end

    --添加/更新到缓存
    local bAdded
    local item = self._UserList[userItem.dwUserID]
    if item ~= nil then
        item.dwGameID = userItem.dwGameID
        item.lScore = userItem.lScore
        item.lIngot = userItem.lIngot
        item.dBeans = userItem.dBeans
        item.wFaceID = userItem.wFaceID
        item.dwCustomID = userItem.dwCustomID
        item.cbGender = userItem.cbGender
        item.cbMemberOrder = userItem.cbMemberOrder
        item.wTableID = userItem.wTableID
        item.wChairID = userItem.wChairID
        item.cbUserStatus = userItem.cbUserStatus
        item.dwWinCount = userItem.dwWinCount
        item.dwLostCount = userItem.dwLostCount
        item.dwDrawCount = userItem.dwDrawCount
        item.dwFleeCount = userItem.dwFleeCount
        item.dwExperience = userItem.dwExperience
        item.szNickName = userItem.szNickName
        bAdded = true
    end

    if not bAdded then
        self._UserList[userItem.dwUserID] = userItem
        if self._wTableID == userItem.wTableID then
            self:dispatchMessage('GetUserLocation', {dwUserID = userItem.dwUserID})
        end
    end

    if userItem.wTableID ~= yl.INVALID_TABLE and userItem.cbUserStatus ~= yl.US_LOOKON then
        self:onUpDataTableUser(userItem.wTableID, userItem.wChairID, userItem)

        if self._viewFrame and self._viewFrame.onEventUserEnter and userItem.wTableID == self._wTableID then
            self._viewFrame:onEventUserEnter(userItem)
        end
    end
end
--用户积分
function GameFrameEngine:onSocketUserScore(dataBuffer)
    local dwUserID = dataBuffer:readdword()

    local int64 = Integer64.new()
    local item = self._UserList[dwUserID]
    if item ~= nil then
        --更新数据
        item.lScore = dataBuffer:readscore(int64):getvalue()
        item.dBeans = dataBuffer:readdouble()

        item.dwWinCount = dataBuffer:readdword()
        item.dwLostCount = dataBuffer:readdword()
        item.dwDrawCount = dataBuffer:readdword()
        item.dwFleeCount = dataBuffer:readdword()

        item.dwExperience = dataBuffer:readdword()

        --自己信息
        if item.dwUserID == GlobalUserItem.dwUserID and self:IsAllowPlazzScoreChange() then
            GlobalUserItem.lUserScore = item.lScore
            GlobalUserItem.dUserBeans = item.dBeans
        end

        --通知更新界面
        if
            self._wTableID ~= yl.INVALID_TABLE and self._viewFrame and self._viewFrame.onEventUserScore and
                item.wTableID == self._wTableID
         then
            self._viewFrame:onEventUserScore(item)
        end
    end
end

--用户状态
function GameFrameEngine:onSocketUserStatus(dataBuffer)
    dump("用户状态")
    --读取信息
    local dwUserID = dataBuffer:readdword()
    local newstatus = {}
    newstatus.wTableID = dataBuffer:readword()
    newstatus.wChairID = dataBuffer:readword()
    newstatus.cbUserStatus = dataBuffer:readbyte()

    --过滤观看
    if newstatus.cbUserStatus == yl.US_LOOKON then
        return
    end

    local useritem = self._UserList[dwUserID]

    --找不到用户
    if useritem == nil then
        return
    end

    -- 记录旧状态
    local oldstatus = {}
    oldstatus.wTableID = useritem.wTableID
    oldstatus.wChairID = useritem.wChairID
    oldstatus.cbUserStatus = useritem.cbUserStatus
    --更新信息
    useritem.cbUserStatus = newstatus.cbUserStatus
    useritem.wTableID = newstatus.wTableID
    useritem.wChairID = newstatus.wChairID

    --清除旧桌子椅子记录
    if oldstatus.wTableID ~= yl.INVALID_TABLE then
        --新旧桌子不同 新旧椅子不同
        if (oldstatus.wTableID ~= newstatus.wTableID) or (oldstatus.wChairID ~= newstatus.wChairID) then
            self:onUpDataTableUser(oldstatus.wTableID, oldstatus.wChairID, nil)
        end
    end
    --新桌子记录
    if newstatus.wTableID ~= yl.INVALID_TABLE then
        self:onUpDataTableUser(newstatus.wTableID, newstatus.wChairID, useritem)
    end

    --自己状态
    if dwUserID == GlobalUserItem.dwUserID then
        --他人状态
        self._wTableID = newstatus.wTableID
        self._wChairID = newstatus.wChairID
        --离开
        if newstatus.cbUserStatus == yl.US_NULL then
            --起立
            if self._viewFrame and self._viewFrame.onExitRoom and not GlobalUserItem.bWaitQuit then
                self._viewFrame:onExitRoom()
            end
        elseif newstatus.cbUserStatus == yl.US_FREE and oldstatus.cbUserStatus > yl.US_FREE then
            --坐下
            if self._viewFrame and self._viewFrame.onExitTable and not GlobalUserItem.bWaitQuit then
                if self.bEnterAntiCheatRoom then
                    self:OnResetGameEngine()
                elseif not self.bChangeDesk then
                    self._viewFrame:onExitTable()
                else
                    self.bChangeDesk = false
                    self:OnResetGameEngine()
                end
            end
        elseif newstatus.cbUserStatus > yl.US_FREE and oldstatus.cbUserStatus < yl.US_SIT then
            self.bChangeDesk = false
            if self._viewFrame and self._viewFrame.onEnterTable then
                self._viewFrame:onEnterTable()
            end
            --showToast(self._viewFrame,"找到游戏桌子，正在获取场景中...",1)
            self:SendGameOption()
            if self._viewFrame and self._viewFrame.onEventUserStatus then
                self._viewFrame:onEventUserStatus(useritem, newstatus, oldstatus)
            end
        elseif newstatus.wTableID ~= yl.INVALID_TABLE and self.bChangeDesk == true then
            if self._viewFrame and self._viewFrame.onEnterTable then
                self._viewFrame:onEnterTable()
            end
            --showToast(self._viewFrame,"找到游戏桌子，正在获取场景中...",1)
            self:SendGameOption()
            if self._viewFrame and self._viewFrame.onEventUserStatus then
                self._viewFrame:onEventUserStatus(useritem, newstatus, oldstatus)
            end
        else
            print('自己新状态:' .. newstatus.cbUserStatus)
            if self._viewFrame and self._viewFrame.onEventUserStatus then
                self._viewFrame:onEventUserStatus(useritem, newstatus, oldstatus)
            end
        end
    else
        --更新用户
        if oldstatus.wTableID ~= yl.INVALID_TABLE or newstatus.wTableID ~= yl.INVALID_TABLE then
            if self._viewFrame and self._viewFrame.onEventUserStatus and oldstatus.wTableID == self._wTableID then
                self._viewFrame:onEventUserStatus(useritem, newstatus, oldstatus)
            end
        end
        --删除用户
        if newstatus.cbUserStatus == yl.US_NULL then
            self:onRemoveUser(dwUserID)
        end
    end
end

--请求失败
function GameFrameEngine:onSocketReQuestFailure(dataBuffer)
    local cmdtable = ExternalFun.read_netdata(game_cmd.CMD_GR_RequestFailure, dataBuffer)
    dump(cmdtable, 'onSocketReQuestFailure', 6)

    if self:isSocketServer() == true then
        self:onCloseSocket()
    end

    if self._viewFrame and self._viewFrame.onReQueryFailure then
        self._viewFrame:onReQueryFailure(cmdtable.lErrorCode, cmdtable.szDescribeString)
    else
        PriRoom:getInstance():popMessage(cmdtable.szDescribeString)
        self._viewFrame:onExitTable()
    end

    if self.bChangeDesk == true then
        self.bChangeDesk = false
        if self._viewFrame and self._viewFrame.onExitTable and not GlobalUserItem.bWaitQuit then
            self._viewFrame:onExitTable()
        end
    end

    -- 清理锁表
    GlobalUserItem.dwLockServerID = 0
    GlobalUserItem.dwLockKindID = 0
end

--状态信息
function GameFrameEngine:onSocketStatusEvent(sub, dataBuffer)
    if sub == yl.SUB_GR_TABLE_INFO then
        local wTableCount = dataBuffer:readword()
        for i = 1, wTableCount do
            self._tableStatus[i] = {}
            self._tableStatus[i].cbTableLock = dataBuffer:readbyte()
            self._tableStatus[i].cbPlayStatus = dataBuffer:readbyte()
            self._tableStatus[i].lCellScore = dataBuffer:readint()
        end
        if not GlobalUserItem.bPrivateRoom and not GlobalUserItem.bMatch then
            if self._viewFrame and self._viewFrame.onEnterRoom then
                self._viewFrame:onEnterRoom()
            end
        end

        if self._viewFrame and self._viewFrame.onGetTableInfo then
            self._viewFrame:onGetTableInfo()
        end
    elseif sub == yl.SUB_GR_TABLE_STATUS then --桌子状态
        local wTableID = dataBuffer:readword() + 1
        self._tableStatus[wTableID] = {}
        self._tableStatus[wTableID].cbTableLock = dataBuffer:readbyte()
        self._tableStatus[wTableID].cbPlayStatus = dataBuffer:readbyte()
        self._tableStatus[wTableID].lCellScore = dataBuffer:readint()

        if self._viewFrame and self._viewFrame.upDataTableStatus then
            self._viewFrame:upDataTableStatus(wTableID)
        end
    end
end

--框架信息
function GameFrameEngine:onSocketFrameEvent(sub, dataBuffer)
    --游戏状态
    if sub == yl.SUB_GF_GAME_STATUS then
        --游戏场景
        self._cbGameStatus = dataBuffer:readword()
        self._cbAllowLookon = dataBuffer:readword()

        if GlobalUserItem.bPrivateRoom then
            if self._viewFrame and self._viewFrame.onEnterTable then
                self._viewFrame:onEnterTable()
            end
        end
    elseif sub == yl.SUB_GF_GAME_SCENE then
        --系统消息
        if self._viewFrame and self._viewFrame.onEventGameScene then
            self._viewFrame:onEventGameScene(self._cbGameStatus, dataBuffer)
        else
            print('game scene did not respon')
            if not self._viewFrame then
                print('viewframe is nl')
            else
                print('onEventGameScene is ni viewframe is' .. self._viewFrame:getTag())
            end
        end
    elseif sub == yl.SUB_GF_SYSTEM_MESSAGE then
        --动作消息
        self:onSocketSystemMessage(dataBuffer)
    elseif sub == yl.SUB_GF_ACTION_MESSAGE then
        --用户聊天
        self:onSocketActionMessage(dataBuffer)
    elseif sub == game_cmd.SUB_GF_USER_CHAT then
        --用户表情
        local chat = ExternalFun.read_netdata(game_cmd.CMD_GF_S_UserChat, dataBuffer)
        dump(chat)
        --获取玩家昵称
        local useritem = self._UserList[chat.dwSendUserID]
        if not useritem then
            return
        end

        if self._wTableID == yl.INVALID_CHAIR or self._wTableID ~= useritem.wTableID then
            return
        end

        chat.szNick = useritem.szNickName

        local chatInfo = {}
        chatInfo.content = chat.szChatString
        chatInfo.contentLen = chat.wChatLength
        chatInfo.dwUserID = useritem.dwUserID
        chatInfo.szNickName = useritem.szNickName
        chatInfo.dwCustomID = useritem.dwCustomID
        chatInfo.wFaceID = useritem.wFaceID
        chatInfo.msgType = game_cmd.SUB_GF_USER_CHAT

        --快捷文本语音
        ExternalFun.playGameSoundEffect(GameChatLayer.findQuickChatStingToIndex(chat.szChatString))

        if nil ~= self._viewFrame and nil ~= self._viewFrame.onUserChat then
            self._viewFrame:onUserChat(chat, useritem.wChairID)
        end

        self:dispatchMessage('AddChatRecordMsg', {chat = chatInfo})
    elseif sub == game_cmd.SUB_GF_USER_EXPRESSION then
        -- 用户语音
        local expression = ExternalFun.read_netdata(game_cmd.CMD_GF_S_UserExpression, dataBuffer)

        --获取玩家昵称
        local useritem = self._UserList[expression.dwSendUserID]

        if not useritem then
            return
        end

        if self._wTableID == yl.INVALID_CHAIR or self._wTableID ~= useritem.wTableID then
            return
        end

        expression.szNick = useritem.szNickName

        local chatInfo = {}
        chatInfo.expressionIdx = expression.wItemIndex
        chatInfo.dwUserID = useritem.dwUserID
        chatInfo.szNickName = useritem.szNickName
        chatInfo.dwCustomID = useritem.dwCustomID
        chatInfo.wFaceID = useritem.wFaceID
        chatInfo.msgType = game_cmd.SUB_GF_USER_EXPRESSION

        -- GameChatLayer.addChatRecordWith(expression, true)
        if nil ~= self._viewFrame and nil ~= self._viewFrame.onUserExpression then
            self._viewFrame:onUserExpression(expression, useritem.wChairID)
        end

        self:dispatchMessage('AddChatRecordMsg', {chat = chatInfo})
    elseif sub == game_cmd.SUB_GF_USER_VOICE then
        local sendUserId = dataBuffer:readdword()
        local toUserId = dataBuffer:readdword()
        local voiceUrl = dataBuffer:readstring()

        local useritem = self._UserList[sendUserId]
        local chairId = useritem.wChairID

        local url, time = string.match(voiceUrl, '(.+) time:(%d+)')

        local playStart = function()
            if nil ~= self._viewFrame and nil ~= self._viewFrame.onUserVoiceStart then
                self._viewFrame:onUserVoiceStart(chairId)
            end
        end

        local playEnd = function()
            if nil ~= self._viewFrame and nil ~= self._viewFrame.onUserVoiceEnded then
                self._viewFrame:onUserVoiceEnded(chairId)
            end
        end

        local chatInfo = {}
        chatInfo.voiceUrl = url
        chatInfo.voiceLen = time / 1000
        chatInfo.dwUserID = useritem.dwUserID
        chatInfo.szNickName = useritem.szNickName
        chatInfo.dwCustomID = useritem.dwCustomID
        chatInfo.wFaceID = useritem.wFaceID
        chatInfo.msgType = game_cmd.SUB_GF_USER_VOICE

        self:dispatchMessage(
            'PushVoiceRequest',
            {url = voiceUrl, id = useritem.dwUserID, startcb = playStart, endcb = playEnd}
        )

        self:dispatchMessage('AddChatRecordMsg', {chat = chatInfo})
    elseif sub == game_cmd.SUB_GF_USER_EXPRESSION_MAGIC then
        -- 通知玩家准备
        local magicExpression = ExternalFun.read_netdata(game_cmd.CMD_GF_S_UserExpression, dataBuffer)

        -- dump(magicExpression, '魔法表情')
        local userItem1 = self._UserList[magicExpression.dwSendUserID]
        local useritem = self._UserList[magicExpression.dwTargerUserID]
        if not useritem then
            return
        end

        if self._wTableID == yl.INVALID_CHAIR or self._wTableID ~= useritem.wTableID then
            return
        end

        if nil ~= self._viewFrame and nil ~= self._viewFrame.onUserMagicExpression then
            self._viewFrame:onUserMagicExpression(userItem1.wChairID, useritem.wChairID, magicExpression.wItemIndex)
        end
    elseif sub == game_cmd.SUB_GF_NOTICE_READ then
        if nil ~= self._viewFrame and nil ~= self._viewFrame.onGetNoticeReady then
            self._viewFrame:onGetNoticeReady()
        end
    end
end

--系统消息
function GameFrameEngine:onSocketSystemMessage(dataBuffer)
    local wType = dataBuffer:readword()
    local wLength = dataBuffer:readword()
    local szString = dataBuffer:readstring()
    print('系统消息#' .. wType .. '#' .. szString)
    local bCloseRoom = bit:_and(wType, yl.SMT_CLOSE_ROOM)
    local bCloseGame = bit:_and(wType, yl.SMT_CLOSE_GAME)
    local bCloseLink = bit:_and(wType, yl.SMT_CLOSE_LINK)
    if self._viewFrame then
    --showToast(self._viewFrame,szString,2,cc.c3b(250,0,0))
    end
    print('bCloseRoom ==> ', bCloseRoom)
    print('bCloseGame ==> ', bCloseGame)
    print('bCloseLink ==> ', bCloseLink)
    if bCloseRoom ~= 0 or bCloseGame ~= 0 or bCloseLink ~= 0 then
        if 515 == wType or 501 == wType then
            if self._viewFrame and self._viewFrame.onSystemMessage then
                self._viewFrame:onSystemMessage(wType, szString)
            end
        else
            self:setEnterAntiCheatRoom(false)
            if self._viewFrame and self._viewFrame.onExitRoom and not GlobalUserItem.bWaitQuit then
                self._viewFrame:onExitRoom()
            else
                self:onCloseSocket()
            end
        end
    end
end

--系统动作
function GameFrameEngine:onSocketActionMessage(dataBuffer)
    local wType = dataBuffer:readword()
    local wLength = dataBuffer:readword()
    local nButtonType = dataBuffer:readint()
    local szString = dataBuffer:readstring()
    print('系统动作#' .. wType .. '#' .. szString)

    local bCloseRoom = bit:_and(wType, yl.SMT_CLOSE_ROOM)
    local bCloseGame = bit:_and(wType, yl.SMT_CLOSE_GAME)
    local bCloseLink = bit:_and(wType, yl.SMT_CLOSE_LINK)

    if self._viewFrame then
    --showToast(self._viewFrame,szString,2,cc.c3b(250,0,0))
    end
    if bCloseRoom ~= 0 or bCloseGame ~= 0 or bCloseLink ~= 0 then
        self:setEnterAntiCheatRoom(false)
        if self._viewFrame and self._viewFrame.onExitRoom and not GlobalUserItem.bWaitQuit then
            self._viewFrame:onExitRoom()
        else
            self:onCloseSocket()
        end
    end
end

--更新桌椅用户
function GameFrameEngine:onUpDataTableUser(tableid, chairid, useritem)
    local id = tableid + 1
    local idex = chairid + 1
    if not self._tableUserList[id] then
        self._tableUserList[id] = {}
    end
    if useritem then
        self._tableUserList[id][idex] = useritem.dwUserID
    else
        self._tableUserList[id][idex] = nil
    end
end

--获取桌子用户
function GameFrameEngine:getTableUserItem(tableid, chairid)
    local id = tableid + 1
    local idex = chairid + 1
    if self._tableUserList[id] then
        local userid = self._tableUserList[id][idex]
        if userid then
            return self._UserList[userid]
        end
    end
end

function GameFrameEngine:getTableInfo(index)
    if index > 0 then
        return self._tableStatus[index]
    end
end

--获取自己游戏信息
function GameFrameEngine:GetMeUserItem()
    if GlobalUserItem.bVideo then
        return self._UserList[GlobalUserItem.dwVideoUserID]
    else
        return self._UserList[GlobalUserItem.dwUserID]
    end
end

--获取游戏状态
function GameFrameEngine:GetGameStatus()
    return self._cbGameStatus
end

--设置游戏状态
function GameFrameEngine:SetGameStatus(cbGameStatus)
    self._cbGameStatus = cbGameStatus
end

--获取桌子ID
function GameFrameEngine:GetTableID()
    return self._wTableID
end

--获取椅子ID
function GameFrameEngine:GetChairID()
    return self._wChairID
end

--移除用户
function GameFrameEngine:onRemoveUser(dwUserID)
    self._UserList[dwUserID] = nil
end

--坐下请求
function GameFrameEngine:SitDown(table, chair, password)
    local dataBuffer = CCmd_Data:create(70)
    dataBuffer:setcmdinfo(yl.MDM_GR_USER, yl.SUB_GR_USER_SITDOWN)
    dataBuffer:pushword(table)
    dataBuffer:pushword(chair)
    if password then
        dataBuffer:pushstring(password, yl.LEN_PASSWORD)
    end

    --记录坐下信息
    if nil ~= GlobalUserItem.m_tabEnterGame and type(GlobalUserItem.m_tabEnterGame) == 'table' then
        dump('update game info')
        GlobalUserItem.m_tabEnterGame.nSitTable = table
        GlobalUserItem.m_tabEnterGame.nSitChair = chair
    end
    return self:sendSocketData(dataBuffer)
end
--旁观请求
function GameFrameEngine:lookon(table, chair)
    local dataBuffer = ExternalFun.create_netdata(game_cmd.CMD_GR_UserLookon)
    dataBuffer:setcmdinfo(yl.MDM_GR_USER, game_cmd.SUB_GR_USER_LOOKON)
    dataBuffer:pushword(table)
    dataBuffer:pushword(chair)
    self._wTableID = table--记录tableID
    return self:sendSocketData(dataBuffer)
end
--查询用户
function GameFrameEngine:QueryUserInfo(table, chair)
    local dataBuffer = CCmd_Data:create(4)
    dataBuffer:setcmdinfo(yl.MDM_GR_USER, yl.SUB_GR_USER_CHAIR_INFO_REQ)
    dataBuffer:pushword(table)
    dataBuffer:pushword(chair)
    return self:sendSocketData(dataBuffer)
end

--换位请求
function GameFrameEngine:QueryChangeDesk()
    self.bChangeDesk = true
    local dataBuffer = CCmd_Data:create(0)
    dataBuffer:setcmdinfo(yl.MDM_GR_USER, yl.SUB_GR_USER_CHAIR_REQ)
    return self:sendSocketData(dataBuffer)
end

--起立请求
function GameFrameEngine:StandUp(bForce)
    local dataBuffer = CCmd_Data:create(5)
    dataBuffer:setcmdinfo(yl.MDM_GR_USER, yl.SUB_GR_USER_STANDUP)
    dataBuffer:pushword(self:GetTableID())
    dataBuffer:pushword(self:GetChairID())
    dataBuffer:pushbyte(not bForce and 0 or 1)
    return self:sendSocketData(dataBuffer)
end

--发送准备
function GameFrameEngine:SendUserReady(dataBuffer)
    local userReady = dataBuffer
    if not userReady then
        userReady = CCmd_Data:create(0)
    end
    userReady:setcmdinfo(yl.MDM_GF_FRAME, yl.SUB_GF_USER_READY)
    return self:sendSocketData(userReady)
end

--场景规则
function GameFrameEngine:SendGameOption()
    local dataBuffer = CCmd_Data:create(9)
    dataBuffer:setcmdinfo(yl.MDM_GF_FRAME, yl.SUB_GF_GAME_OPTION)
    dataBuffer:pushbyte(0)
    dataBuffer:pushdword(appdf.VersionValue(6, 7, 0, 1))
    dataBuffer:pushdword(self._kindVersion)
    return self:sendSocketData(dataBuffer)
end

--加密桌子
function GameFrameEngine:SendEncrypt(pass)
    local passlen = string.len(pass) * 2 --14--(ExternalFun.stringLen(pass)) * 2
    print('passlen ==> ' .. passlen)
    local len = passlen + 4 + 13
    --(sizeof game_cmd.CMD_GR_UserRule)
    print('len ==> ' .. len)
    local cmddata = CCmd_Data:create(len)
    cmddata:setcmdinfo(game_cmd.MDM_GR_USER, game_cmd.SUB_GR_USER_RULE)
    cmddata:pushbyte(0)
    cmddata:pushword(0)
    cmddata:pushword(0)
    cmddata:pushint(0)
    cmddata:pushint(0)
    cmddata:pushword(passlen)
    cmddata:pushword(game_cmd.DTP_GR_TABLE_PASSWORD)
    cmddata:pushstring(pass, passlen / 2)

    return self:sendSocketData(cmddata)
end

--发送文本聊天 game_cmd.CMD_GF_C_UserChat
--[msg] 聊天内容
--[tagetUser] 目标用户
function GameFrameEngine:sendTextChat(msg, tagetUser, color)
    if type(msg) ~= 'string' then
        print('聊天内容异常')
        return false, '聊天内容异常!'
    end
    -- --敏感词判断
    -- if true == ExternalFun.isContainBadWords(msg) then
    --     print('聊天内容包含敏感词汇')
    --     return false, '聊天内容包含敏感词汇!'
    -- end
    msg = msg .. '\0'

    tagetUser = tagetUser or yl.INVALID_USERID
    color = color or 16777215 --appdf.ValueToColor( 255,255,255 )
    local msgLen = string.len(msg)
    local defineLen = yl.LEN_USER_CHAT * 2

    local cmddata = CCmd_Data:create(266 - defineLen + msgLen * 2)
    cmddata:setcmdinfo(game_cmd.MDM_GF_FRAME, game_cmd.SUB_GF_USER_CHAT)
    cmddata:pushword(msgLen)
    cmddata:pushdword(color)
    cmddata:pushdword(tagetUser)
    cmddata:pushstring(msg, msgLen)

    return self:sendSocketData(cmddata)
end

--发送表情聊天 game_cmd.CMD_GF_C_UserExpressio
--[idx] 表情图片索引
--[tagetUser] 目标用户
function GameFrameEngine:sendBrowChat(idx, tagetUser)
    tagetUser = tagetUser or yl.INVALID_USERID

    local cmddata = CCmd_Data:create(6)
    cmddata:setcmdinfo(game_cmd.MDM_GF_FRAME, game_cmd.SUB_GF_USER_EXPRESSION)
    cmddata:pushword(idx)
    cmddata:pushdword(tagetUser)

    return self:sendSocketData(cmddata)
end

function GameFrameEngine:OnResetGameEngine()
    if self._viewFrame and self._viewFrame.OnResetGameEngine then
        self._viewFrame:OnResetGameEngine()
    end
end

-- 发送语音数据
function GameFrameEngine:sendDataByVoice(url)
    local cmddata = CCmd_Data:create(512 + 4)
    cmddata:setcmdinfo(game_cmd.MDM_GF_FRAME, game_cmd.SUB_GF_USER_VOICE)
    cmddata:pushdword(GlobalUserItem.dwUserID)
    cmddata:pushstring(url, 128)
    cmddata:pushstring(url, 128)

    self:sendSocketData(cmddata)
end

-- 发送魔法表情
function GameFrameEngine:sendMagicBrowChat(tagetUser, idx)
    if self.sendMagicBlock == false then
        showToast(self._viewFrame, '稍等一会儿再操作...', 1.5)
        return
    end

    self.sendMagicBlock = false

    tagetUser = tagetUser or yl.INVALID_USERID

    local cmddata = CCmd_Data:create(6)
    cmddata:setcmdinfo(game_cmd.MDM_GF_FRAME, game_cmd.SUB_GF_USER_EXPRESSION_MAGIC)
    cmddata:pushword(idx)
    cmddata:pushdword(tagetUser)

    if self:sendSocketData(cmddata) then
        display.performWithDelayGlobal(
            function()
                self.sendMagicBlock = true
            end,
            5
        )

        return true
    else
        return false
    end
end

-- 更新用户定位信息
function GameFrameEngine:onUpdateUserLocationListener(e)
    local info = e.msg
    local findUserItem = self._UserList[info.dwUserID]
    if findUserItem ~= nil then
        self._UserList[info.dwUserID].location = {la = info.la, lo = info.lo}
        --通知更新界面
        if self._wTableID ~= yl.INVALID_TABLE and self._viewFrame and self._viewFrame.onEventUserScore then
            self._viewFrame:onEventUserScore(findUserItem)
        end
    end
end

-- 事件注册
function GameFrameEngine:createMsgEventlistBinding()
    local msglist = rawget(self.class, 'NET_LISTENER')
    if not msglist or type(msglist) ~= 'table' then
        return
    end

    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()

    for _, rpcName in ipairs(msglist) do
        local resp = string.format('on%sListener', rpcName)

        assert(self[resp], 'event:%s has no callback.', rpcName)

        local customListenerBg = cc.EventListenerCustom:create(rpcName, handler(self, self[resp]))

        eventDispatcher:addEventListenerWithSceneGraphPriority(customListenerBg, self._viewFrame)
    end
end

--[[
    事件派发
]]
function GameFrameEngine:dispatchMessage(key, msg)
    if type(key) ~= 'string' then
        key = tostring(key)
    end

    local eventDispatcher = cc.Director:getInstance():getEventDispatcher()
    local event = cc.EventCustom:new(key)
    if msg then
        event.msg = msg
    end
    eventDispatcher:dispatchEvent(event)
end

return GameFrameEngine
