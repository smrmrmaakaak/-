-- SoundManager.lua

local SoundManager = {}

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- SoundGroup 인스턴스 (모듈 로드 시 생성)
local MasterBGMGroup = Instance.new("SoundGroup")
MasterBGMGroup.Name = "MasterBGMGroup"
MasterBGMGroup.Parent = SoundService
MasterBGMGroup.Volume = 0.5 -- 기본 BGM 볼륨

local MasterSFXGroup = Instance.new("SoundGroup")
MasterSFXGroup.Name = "MasterSFXGroup"
MasterSFXGroup.Parent = SoundService
MasterSFXGroup.Volume = 0.8 -- 기본 SFX 볼륨

-- 배경 음악(BGM) 재생을 위한 Sound 인스턴스
local bgmSound = Instance.new("Sound")
bgmSound.Name = "BackgroundMusic"
bgmSound.Looped = true
bgmSound.Volume = 1 -- 개별 BGM 사운드 볼륨은 1로 두고, SoundGroup 볼륨으로 전체 제어
bgmSound.SoundGroup = MasterBGMGroup -- BGM SoundGroup에 할당
bgmSound.Parent = SoundService -- SoundService 바로 아래에 배치 (SoundGroup 하위가 아님)

local currentBgmId = nil

-- 배경 음악(BGM) 재생 함수
function SoundManager.PlayBGM(soundId)
	if soundId == currentBgmId then
		if not bgmSound.IsPlaying then
			print("SoundManager: Resuming BGM:", soundId)
			bgmSound:Play()
		end
		return
	end

	if bgmSound.IsPlaying then
		print("SoundManager: Stopping current BGM:", currentBgmId)
		bgmSound:Stop()
	end

	if soundId and soundId ~= "" then
		bgmSound.SoundId = soundId
		currentBgmId = soundId
		print("SoundManager: Playing new BGM:", soundId, "via Group:", MasterBGMGroup.Name)
		bgmSound:Play()
	else
		currentBgmId = nil
		print("SoundManager: No BGM specified, stopping music.")
	end
end

-- 배경 음악(BGM) 중지 함수
function SoundManager.StopBGM()
	if bgmSound.IsPlaying then
		print("SoundManager: Stopping BGM explicitly:", currentBgmId)
		bgmSound:Stop()
		currentBgmId = nil
	end
end

-- 효과음(SFX) 재생 함수
function SoundManager.PlaySFX(soundId, volume)
	if not soundId or soundId == "" then
		warn("SoundManager.PlaySFX: Invalid soundId provided.")
		return
	end

	local sfxSound = Instance.new("Sound")
	local soundDigits = soundId:match("%d+")
	if soundDigits then
		sfxSound.Name = "SFX_" .. soundDigits
	else
		local namePart = soundId:match("([^/]+)$")
		sfxSound.Name = "SFX_" .. (namePart or "Unknown")
		warn("SoundManager.PlaySFX: Could not extract digits from soundId: ", soundId, ". Using name: ", sfxSound.Name)
	end

	sfxSound.SoundId = soundId
	sfxSound.Looped = false
	sfxSound.Volume = volume or 1 -- 개별 SFX 사운드 볼륨 (SoundGroup 볼륨과 곱해짐)
	sfxSound.SoundGroup = MasterSFXGroup -- SFX SoundGroup에 할당
	sfxSound.Parent = SoundService -- SoundService 아래에 임시 배치 (SoundGroup 하위가 아님)

	print("SoundManager: Playing SFX:", soundId, "with base volume:", sfxSound.Volume, "via Group:", MasterSFXGroup.Name)
	sfxSound:Play()

	task.spawn(function()
		sfxSound.Ended:Wait()
		print("SoundManager: SFX finished, destroying sound instance:", sfxSound.Name)
		pcall(function() sfxSound:Destroy() end)
	end)
end

-- BGM 그룹 볼륨 설정 함수
-- @param volume (number): 0.0 ~ 1.0 사이의 값
function SoundManager.SetMasterBGMVolume(volume)
	local newVolume = math.clamp(volume, 0, 1)
	MasterBGMGroup.Volume = newVolume
	print("SoundManager: Master BGM Group Volume set to", newVolume)
end

-- SFX 그룹 볼륨 설정 함수
-- @param volume (number): 0.0 ~ 1.0 사이의 값
function SoundManager.SetMasterSFXVolume(volume)
	local newVolume = math.clamp(volume, 0, 1)
	MasterSFXGroup.Volume = newVolume
	print("SoundManager: Master SFX Group Volume set to", newVolume)
end

-- 현재 BGM 그룹 볼륨 가져오기 함수
function SoundManager.GetMasterBGMVolume()
	return MasterBGMGroup.Volume
end

-- 현재 SFX 그룹 볼륨 가져오기 함수
function SoundManager.GetMasterSFXVolume()
	return MasterSFXGroup.Volume
end


print("SoundManager: Module loaded. BGM Group Volume:", MasterBGMGroup.Volume, "SFX Group Volume:", MasterSFXGroup.Volume)
return SoundManager