--
-- Author: zhong
-- Date: 2016-12-17 09:39:30
--
-- 私人房 ID 输入界面
local RoomIdInputLayer = class("RoomIdInputLayer", function()
    local RoomIdInputLayer = cc.LayerColor:create(cc.c4b(0,0,0,0))
return RoomIdInputLayer
end)

RoomIdInputLayer.WIDGET_TAG = {}
local WIDGET_TAG = RoomIdInputLayer.WIDGET_TAG

function RoomIdInputLayer:ctor()
    appdf.registerTouchOutsideHandler(self, false, "main", false)

    -- 加载csb资源
    local csbNode = cc.CSLoader:createNode("joinInput/RoomIdInputLayer.csb")
                    :addTo(self)
                    :move(0,- 40)

    self.layer_main = csbNode

    for i = 1, 9 do
        local nodeName = string.format("bt_%s", i)
        appdf.setNodeTagAndListener(csbNode, nodeName, nodeName, handler(self, self.onNumButtonClickedEvent))
    end
    appdf.setNodeTagAndListener(csbNode, "bt_0", "bt_0", handler(self, self.onNumButtonClickedEvent))
    

    appdf.setNodeTagAndListener(csbNode, "bt_del", "BT_DEL", handler(self, self.onButtonClickedEvent))
    appdf.setNodeTagAndListener(csbNode, "bt_clean", "BT_CLEAN", handler(self, self.onButtonClickedEvent))
    appdf.setNodeTagAndListener(csbNode, "bt_close", "BT_CLOSE", handler(self, self.onButtonClickedEvent))
    
    self.m_atlasRoomId = appdf.getNodeByName(csbNode, "room_id")
end

function RoomIdInputLayer:onNumButtonClickedEvent( tag, sender )
    if tag == 10 then
        tag = 0
    end

    local roomid = self.m_atlasRoomId:getString()
    if string.len(roomid) < 6 then
        roomid = roomid .. tag
        self.m_atlasRoomId:setString(roomid)
    end

    if self.isTryJoin == true then
        self.m_atlasRoomId:setString(tag)
        self.isTryJoin = false
        return
    end

    if string.len(roomid) == 6 then        
        -- self:dismiss(function()
            self.isTryJoin = true
            -- PriRoom:getInstance():showPopWait()
            PriRoom:getInstance():getNetFrame():onSearchRoom(roomid)
        -- end)
    end
end

function RoomIdInputLayer:onButtonClickedEvent( tag, sender )
    if WIDGET_TAG.BT_CLEAN == tag then
        self.m_atlasRoomId:setString("")
    elseif WIDGET_TAG.BT_DEL == tag then
        local roomid = self.m_atlasRoomId:getString()
        local len = string.len(roomid)
        if len > 0 then
            roomid = string.sub(roomid, 1, len - 1)
        end
        self.m_atlasRoomId:setString(roomid)        
        if self.isTryJoin == true then
            self.isTryJoin = false
        end
    elseif WIDGET_TAG.BT_CLOSE == tag then
        self:dismiss()
    end
end

function RoomIdInputLayer:dismiss(cb)
    self:runAction(
        cc.Sequence:create(
            cc.FadeOut:create(0),
            cc.CallFunc:create(function()
                self:setTouchEnabled(false)
                if cb then
                    cb()
                end
                -- self:setVisible(false)
                self:removeSelf()
            end)
        )
    )
end

function RoomIdInputLayer:show(cb)
    self.layer_main:stopAllActions()
    self:setVisible(true)
    self:runAction(
        cc.Sequence:create(
            cc.FadeTo:create(0.3, 200)
        )

    )
    self.layer_main:runAction(
        cc.Sequence:create(
            cc.MoveTo:create(0.25,cc.p(0,0)),
            cc.CallFunc:create(function()
                    self:setTouchEnabled(true)
                    if cb then
                        cb()
                    end
                end)
            ))

end

return RoomIdInputLayer