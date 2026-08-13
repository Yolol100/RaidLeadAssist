local _, ns = ...

local AudioService = {
    database = nil,
    voiceID = nil,
}

function AudioService:Initialize(database)
    self.database = database
    self:RefreshVoice()
end

function AudioService:RefreshVoice()
    self.voiceID = nil

    if C_TTSSettings and type(C_TTSSettings.GetVoiceOptionID) == "function"
        and Enum and Enum.TtsVoiceType and Enum.TtsVoiceType.Standard ~= nil then
        local ok, voiceID = pcall(C_TTSSettings.GetVoiceOptionID, Enum.TtsVoiceType.Standard)
        if ok and type(voiceID) == "number" and voiceID > 0 then
            self.voiceID = voiceID
            return
        end
    end

    if not C_VoiceChat or type(C_VoiceChat.GetTtsVoices) ~= "function" then return end
    local ok, voices = pcall(C_VoiceChat.GetTtsVoices)
    if ok and type(voices) == "table" and voices[1] and type(voices[1].voiceID) == "number" then
        self.voiceID = voices[1].voiceID
    end
end

function AudioService:IsEnabled()
    return self.database and self.database.audioEnabled ~= false
end

function AudioService:Speak(text)
    if not self:IsEnabled() or type(text) ~= "string" or text == "" then return end
    if not self.voiceID then self:RefreshVoice() end

    if self.voiceID and C_VoiceChat and type(C_VoiceChat.SpeakText) == "function" then
        local rate, volume = 0, 100
        if C_TTSSettings and type(C_TTSSettings.GetSpeechRate) == "function" then
            local ok, value = pcall(C_TTSSettings.GetSpeechRate)
            if ok and type(value) == "number" then rate = value end
        end
        if C_TTSSettings and type(C_TTSSettings.GetSpeechVolume) == "function" then
            local ok, value = pcall(C_TTSSettings.GetSpeechVolume)
            if ok and type(value) == "number" then volume = value end
        end

        local ok = pcall(C_VoiceChat.SpeakText, self.voiceID, text, rate, volume, false)
        if ok then return end
    end

    if SOUNDKIT and SOUNDKIT.RAID_WARNING then
        PlaySound(SOUNDKIT.RAID_WARNING, "Master")
    end
end

function AudioService:Prepare(call)
    self:Speak("Prepare " .. (call.voice or call.ability))
end

function AudioService:Press(call)
    self:Speak((call.voice or call.ability) .. ". Press now.")
end

ns:RegisterModule("Services.AudioService", AudioService)
