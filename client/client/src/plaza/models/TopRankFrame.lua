local BaseFrame = appdf.req(appdf.CLIENT_SRC .. 'plaza.models.BaseFrame')
local TopRankFrame = class('TopRankFrame', BaseFrame)
local ExternalFun = appdf.req(appdf.EXTERNAL_SRC .. 'ExternalFun')

-- 用户服务
TopRankFrame.MDM_GP_USER_SERVICE = 3 --用户服务

-- 排行
TopRankFrame.SUB_GP_GAME_TOP_RANK = 470 --获取游戏排行数据
TopRankFrame.SUB_GP_GAME_TOP_RANK_RESPONE = 471 --获取游戏排行数据

-- start --
-- 查询游戏积分排行
TopRankFrame.CMD_GR_GET_RANK_BY_KIND = {
    {t = 'dword', k = 'dwKindId'}
}

-- 个人信息
TopRankFrame.CMD_GR_GAME_RANK_MODEL = {
    {t = 'string', k = 'kNickName', s = 32},
    {t = 'score', k = 'lScore'}
}
-- end --

function TopRankFrame:xtor(view, callback)
    TopRankFrame.super.ctor(self, view, callback)
end

function TopRankFrame:onConnect()
    if not self:onCreateSocket(yl.LOGONSERVER, yl.LOGONPORT) and nil ~= self._callBack then
        self._callBack(-1)
    end
    return self
end

function TopRankFrame:onConnectCompeleted()
    self._callBack(0)
end

--网络信息
function TopRankFrame:onSocketEvent(main, sub, pData)
    print('============TopRankFrame:onSocketEvent============')
    print('*socket event:' .. main .. '#' .. sub)
    if sub == TopRankFrame.SUB_GP_GAME_TOP_RANK_RESPONE then
        local cmddata = {}
        cmddata.userItem = {}
        cmddata.dwKindId = self._dwKindId

        local count = pData:readword()

        for i = 1, count do
            local v = ExternalFun.read_netdata(TopRankFrame.CMD_GR_GAME_RANK_MODEL, pData)
            table.insert(cmddata.userItem, v)
        end

        self._callBack(sub, cmddata)
    end
    -- self:onCloseSocket()
end

function TopRankFrame:sendQuery(dwKindId)
    local sendMsgData = ExternalFun.create_netdata(TopRankFrame.CMD_GR_GET_RANK_BY_KIND)
    sendMsgData:setcmdinfo(TopRankFrame.MDM_GP_USER_SERVICE, TopRankFrame.SUB_GP_GAME_TOP_RANK)
    sendMsgData:pushdword(dwKindId)

    self._dwKindId = dwKindId
    if not self:sendSocketData(sendMsgData) then
        self._callBack(-1)
    end
end

return TopRankFrame
