-- SoundManager.lua

local SoundManager = {}

local SoundService = game:GetService("SoundService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- SoundGroup �ν��Ͻ� (��� �ε� �� ����)
local MasterBGMGroup = Instance.new("SoundGroup")
MasterBGMGroup.Name = "MasterBGMGroup"
MasterBGMGroup.Parent = SoundService
MasterBGMGroup.Volume = 0.5 -- �⺻ BGM ����

local MasterSFXGroup = Instance.new("SoundGroup")
MasterSFXGroup.Name = "MasterSFXGroup"
MasterSFXGroup.Parent = SoundService
MasterSFXGroup.Volume = 0.8 -- �⺻ SFX ����

-- ��� ����(BGM) ����� ���� Sound �ν��Ͻ�
local bgmSound = Instance.new("Sound")
bgmSound.Name = "BackgroundMusic"
bgmSound.Looped = true
bgmSound.Volume = 1 -- ���� BGM ���� ������ 1�� �ΰ�, SoundGroup �������� ��ü ����
bgmSound.SoundGroup = MasterBGMGroup -- BGM SoundGroup�� �Ҵ�
bgmSound.Parent = SoundService -- SoundService �ٷ� �Ʒ��� ��ġ (SoundGroup ������ �ƴ�)

local currentBgmId = nil

-- ��� ����(BGM) ��� �Լ�
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

-- ��� ����(BGM) ���� �Լ�
function SoundManager.StopBGM()
	if bgmSound.IsPlaying then
		print("SoundManager: Stopping BGM explicitly:", currentBgmId)
		bgmSound:Stop()
		currentBgmId = nil
	end
end

-- ȿ����(SFX) ��� �Լ�
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
	sfxSound.Volume = volume or 1 -- ���� SFX ���� ���� (SoundGroup ������ ������)
	sfxSound.SoundGroup = MasterSFXGroup -- SFX SoundGroup�� �Ҵ�
	sfxSound.Parent = SoundService -- SoundService �Ʒ��� �ӽ� ��ġ (SoundGroup ������ �ƴ�)

	print("SoundManager: Playing SFX:", soundId, "with base volume:", sfxSound.Volume, "via Group:", MasterSFXGroup.Name)
	sfxSound:Play()

	task.spawn(function()
		sfxSound.Ended:Wait()
		print("SoundManager: SFX finished, destroying sound instance:", sfxSound.Name)
		pcall(function() sfxSound:Destroy() end)
	end)
end

-- BGM �׷� ���� ���� �Լ�
-- @param volume (number): 0.0 ~ 1.0 ������ ��
function SoundManager.SetMasterBGMVolume(volume)
	local newVolume = math.clamp(volume, 0, 1)
	MasterBGMGroup.Volume = newVolume
	print("SoundManager: Master BGM Group Volume set to", newVolume)
end

-- SFX �׷� ���� ���� �Լ�
-- @param volume (number): 0.0 ~ 1.0 ������ ��
function SoundManager.SetMasterSFXVolume(volume)
	local newVolume = math.clamp(volume, 0, 1)
	MasterSFXGroup.Volume = newVolume
	print("SoundManager: Master SFX Group Volume set to", newVolume)
end

-- ���� BGM �׷� ���� �������� �Լ�
function SoundManager.GetMasterBGMVolume()
	return MasterBGMGroup.Volume
end

-- ���� SFX �׷� ���� �������� �Լ�
function SoundManager.GetMasterSFXVolume()
	return MasterSFXGroup.Volume
end


print("SoundManager: Module loaded. BGM Group Volume:", MasterBGMGroup.Volume, "SFX Group Volume:", MasterSFXGroup.Volume)
return SoundManager