local OptionLayer =
    class(
    'OptionLayer',
    function(scene)
        local optionLayer = cc.LayerColor:create(cc.c4b(0, 0, 0, 0))
        return optionLayer
    end
)

OptionLayer.WIDGET_TAG = {}
local WIDGET_TAG = OptionLayer.WIDGET_TAG

function OptionLayer:ctor(scene)
    appdf.registerTouchOutsideHandler(self, false, 'main', false)

    local csbNode = cc.CSLoader:createNode('Option/OptionLayer.csb'):addTo(self):move(0, -40)

    self.layer_main = csbNode
    self._scene = scene

    appdf.setNodeTagAndListener(csbNode, 'btn_close', 'BT_CLOSE', handler(self, self.onButtonClickedEvent))
    appdf.setNodeTagAndListener(csbNode, 'btn_exit', 'BT_EXCHANGE', handler(self, self.onButtonClickedEvent))

    local btn_music =
        function()
        local view =
            appdf.setNodeTagAndListener(csbNode, 'btn_music', 'CBT_SILENCE', handler(self, self.onButtonClickedEvent))

        local update = function()
            if GlobalUserItem.bVoiceAble == false then
                view:loadTexture('Option/srjy_icon_close.png', ccui.TextureResType.localType)
            else
                view:loadTexture('Option/srjy_icon_open.png', ccui.TextureResType.localType)
            end
        end

        update()

        return update
    end

    local btn_sound =
        function()
        local view =
            appdf.setNodeTagAndListener(csbNode, 'btn_sound', 'CBT_SOUND', handler(self, self.onButtonClickedEvent))

        local update = function()
            if GlobalUserItem.bSoundAble == false then
                view:loadTexture('Option/srjy_icon_close.png', ccui.TextureResType.localType)
            else
                view:loadTexture('Option/srjy_icon_open.png', ccui.TextureResType.localType)
            end
        end

        update()

        return update
    end

    self.updateMusic = btn_music()
    self.updateSound = btn_sound()

    local setSoundFuc = function(tag, e, v)
        local value = v:getPercent()

        if tag == WIDGET_TAG.music_slider then
            if value == 0 then
                GlobalUserItem.setVoiceAble(false)
            else
                if GlobalUserItem.bVoiceAble ~= true then
                    AudioEngine.playMusic(cc.FileUtils:getInstance():fullPathForFilename('sound/backgroud01.mp3'), true)
                end
                GlobalUserItem.setVoiceAble(true)
            end

            GlobalUserItem.setMusicVolume(value)
            self.updateMusic()
        else
            if value == 0 then
                GlobalUserItem.setSoundAble(false)
            else
                GlobalUserItem.setSoundAble(true)
            end
            GlobalUserItem.setEffectsVolume(value)
            self.updateSound()
        end
    end

    appdf.setNodeTagAndListener(csbNode, 'music_slider', 'music_slider', setSoundFuc):setPercent(GlobalUserItem.nMusic)
    appdf.setNodeTagAndListener(csbNode, 'sound_slider', 'sound_slider', setSoundFuc):setPercent(GlobalUserItem.nSound)

    appdf.setNodeTagAndListener(csbNode, 'item_1', 'BG_01', handler(self, self.onButtonClickedEvent), self):setCallbackType(
        'bg1'
    )
    appdf.setNodeTagAndListener(csbNode, 'item_2', 'BG_02', handler(self, self.onButtonClickedEvent), self):setCallbackType(
        'bg2'
    )
    appdf.setNodeTagAndListener(csbNode, 'item_3', 'BG_03', handler(self, self.onButtonClickedEvent), self):setCallbackType(
        'bg3'
    )
    appdf.setNodeTagAndListener(csbNode, 'item_4', 'BG_04', handler(self, self.onButtonClickedEvent), self):setCallbackType(
        'bg4'
    )
    for i = 1, 4 do
        local nodename = string.format('item_%d', i)
        local v = appdf.getNodeByName(self, nodename)
        local textureName
        if GlobalUserItem.GameBg ~= v:getCallbackType() then
            textureName = string.format('Option/srjy_%s_off.png', v:getCallbackType())
        else
            textureName = string.format('Option/srjy_%s_on.png', v:getCallbackType())
        end
        v:loadTexture(textureName)
    end
    local pt_hua =
        appdf.setNodeTagAndListener(csbNode, 'CheckBox_1', 'PT_HUA', handler(self, self.onButtonClickedEvent), self)
    local cs_hua =
        appdf.setNodeTagAndListener(csbNode, 'CheckBox_2', 'CS_HUA', handler(self, self.onButtonClickedEvent), self)

    if GlobalUserItem.GameSoundLanguage == 'cs' then
        cs_hua:setSelected(true)
        pt_hua:setSelected(false)
    end
end

--按键监听
function OptionLayer:onButtonClickedEvent(tag, sender)
    if tag == WIDGET_TAG.BT_EXCHANGE then
        -- 删除微信登录数据
        local wxDataFile = string.format('%s\\%s', device.writablePath, 'wxOauthData')

        if cc.FileUtils:getInstance():isFileExist(wxDataFile) then
            cc.FileUtils:getInstance():removeFile(wxDataFile)
        end

        self._scene:ExitClient()
    elseif tag == WIDGET_TAG.BT_CLOSE then
        -- self._scene:onKeyBack()
        self:dismiss()
    elseif tag == WIDGET_TAG.CBT_SILENCE then
        GlobalUserItem.setVoiceAble(not GlobalUserItem.bVoiceAble)
        self.updateMusic()

        if GlobalUserItem.bVoiceAble then
            AudioEngine.playMusic(cc.FileUtils:getInstance():fullPathForFilename('sound/backgroud01.mp3'), true)
        end
    elseif tag == WIDGET_TAG.CBT_SOUND then
        GlobalUserItem.setSoundAble(not GlobalUserItem.bSoundAble)
        self.updateSound()
    elseif tag == WIDGET_TAG.PT_HUA then
        GlobalUserItem.setGameSoundLanguage('pt')
        local pt_hua = appdf.getNodeByName(self, 'CheckBox_1'):setSelected(true)
        local cs_hua = appdf.getNodeByName(self, 'CheckBox_2'):setSelected(false)
    elseif tag == WIDGET_TAG.CS_HUA then
        GlobalUserItem.setGameSoundLanguage('cs')
        local pt_hua = appdf.getNodeByName(self, 'CheckBox_1'):setSelected(false)
        local cs_hua = appdf.getNodeByName(self, 'CheckBox_2'):setSelected(true)
    else
        for i = 1, 4 do
            local nodename = string.format('item_%d', i)
            local v = appdf.getNodeByName(self, nodename)
            local textureName

            if v:getTag() ~= tag then
                textureName = string.format('Option/srjy_%s_off.png', v:getCallbackType())
            else
                textureName = string.format('Option/srjy_%s_on.png', v:getCallbackType())
            end
            v:loadTexture(textureName)
        end
        local bg1_tag, bg2_tag, bg3_tag, bg4_tag = 7, 8, 9, 10
        if tag == bg1_tag then
            GlobalUserItem.SetGameBg('bg1')
        elseif tag == bg2_tag then
            GlobalUserItem.SetGameBg('bg2')
        elseif tag == bg3_tag then
            GlobalUserItem.SetGameBg('bg3')
        elseif tag == bg4_tag then
            GlobalUserItem.SetGameBg('bg4')
        end
    end
end

function OptionLayer:dismiss(cb)
    self:runAction(
        cc.Sequence:create(
            cc.FadeOut:create(0),
            cc.CallFunc:create(
                function()
                    self:setTouchEnabled(false)
                    -- self:setVisible(false)
                    self:removeSelf()
                end
            )
        )
    )
end

function OptionLayer:show(cb)
    self.layer_main:stopAllActions()
    self:setVisible(true)
    self:runAction(cc.Sequence:create(cc.FadeTo:create(0.3, 200)))

    self.layer_main:runAction(
        cc.Sequence:create(
            cc.MoveTo:create(0.25, cc.p(0, 0)),
            cc.CallFunc:create(
                function()
                    self:setTouchEnabled(true)
                    if cb then
                        cb()
                    end
                end
            )
        )
    )
end

return OptionLayer
