-- 全部使用 AudioEngine 播放

local M = {}

-- 背景音乐ID
local backgroudId = -1
-- 背景音乐音量
local backgroudVolum = 1

-- 语音ID
local voiceId = -1
-- 语音音量
local voiceVolum = 0

-- 音效音量
local effectVolum = 1


function M.getMusicVolume()
    return backgroudVolum
end


function M.getEffectsVolume()
    return effectVolum
end

function M.setMusicVolume(volume)
    ccexp.AudioEngine:setVolume(backgroudId, volume)
    backgroudVolum = volume
end


function M.stopMusic(isReleaseData)
    local releaseDataValue = false
    if nil ~= isReleaseData then
        releaseDataValue = isReleaseData
    end
    ccexp.AudioEngine:stop(backgroudId)
end

function M.pause()
    if backgroudId == nil then
        return
    end
    ccexp.AudioEngine:pause(backgroudId)
end

function M.resume()
    if backgroudId == nil then
        return
    end
    ccexp.AudioEngine:resume(backgroudId)
end

function M.playMusic(filename, isLoop)
    local loopValue = false
    if nil ~= isLoop then
        loopValue = isLoop
    end
    ccexp.AudioEngine:stop(backgroudId)
    backgroudId = ccexp.AudioEngine:play2d(filename, isLoop)
end


function M.playEffect(filename, isLoop)
    local loopValue = false
    if nil ~= isLoop then
        loopValue = isLoop
    end
    return ccexp.AudioEngine:play2d(filename, loopValue, effectVolum)
end

-- 播放语音 使用play2d播放
function M.playVoice( filename, isLoop )
    local loopValue = false
    if nil ~= isLoop then
        loopValue = isLoop
    end
    ccexp.AudioEngine:stop(voiceId)
    voiceId = ccexp.AudioEngine:play2d(filename, loopValue)
    return voiceId
end

function M.setVoiceVolume( volume )
    ccexp.AudioEngine:setVolume(voiceId, volume)
    voiceVolum = volume
end

function M.setEffectsVolume(volume, effectid)
    if nil == effectid then
        effectVolum = volume
    end   
    ccexp.AudioEngine:setVolume(backgroudId, backgroudVolum)
    if nil ~= effectid then
        ccexp.AudioEngine:setVolume(effectid, volume)
    end
end

AudioEngine = M
