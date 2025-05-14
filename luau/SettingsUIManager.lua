-- ReplicatedStorage > Modules > SettingsUIManager.lua
-- *** [��� ����] UI â ��ħ ������ ���� CoreUIManager.OpenMainUIPopup ��� ***

local SettingsUIManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ModuleManager
local CoreUIManager -- CoreUIManager ���� ����
local SoundManager
local SettingsFrame = nil -- ��� �������� �̵� �� �ʱ�ȭ
local RequestDataResetEvent = nil

local bgmVolumeValueLabel = nil
local bgmDecreaseButton = nil
local bgmIncreaseButton = nil
local bgmMuteButton = nil

local sfxVolumeValueLabel = nil
local sfxDecreaseButton = nil
local sfxIncreaseButton = nil
local sfxMuteButton = nil

local previousBGMVolume = 0.5
local previousSFXVolume = 0.8
local isBGMMuted = false
local isSFXMuted = false
local VOLUME_STEP = 0.05 

-- ##### [��� ����] UI ������ ������ ���� �Լ� (���� ������ ����, SettingsFrame ������ ��� ������ ����) #####
local function SetupUIReferences() -- �Լ� �̸� ���� ���� (���ο�)
	if SettingsUIManager.SettingsFrame and bgmVolumeValueLabel then -- SettingsUIManager.SettingsFrame ���, �ٸ� ���� UI ��ҵ� Ȯ��
		print("SettingsUIManager.SetupUIReferences: Already setup.")
		return true 
	end
	print("SettingsUIManager.SetupUIReferences: Attempting setup...")

	local player = Players.LocalPlayer
	local playerGui = player and player:WaitForChild("PlayerGui")
	local mainGui = playerGui and playerGui:FindFirstChild("MainGui")
	if not mainGui then warn("SettingsUIManager.SetupUIReferences: MainGui not found!"); return false end
	local backgroundFrame = mainGui:FindFirstChild("BackgroundFrame")
	local framesFolder = backgroundFrame and backgroundFrame:FindFirstChild("Frames")
	SettingsUIManager.SettingsFrame = framesFolder and framesFolder:FindFirstChild("SettingsFrame") -- ��� ������ ������ �Ҵ�

	if SettingsUIManager.SettingsFrame then
		local contentFrame = SettingsUIManager.SettingsFrame:FindFirstChild("ContentFrame")
		if contentFrame then
			local bgmContainer = contentFrame:FindFirstChild("BGMVolumeContainer")
			if bgmContainer then
				bgmVolumeValueLabel = bgmContainer:FindFirstChild("BGMVolumeValueLabel")
				bgmDecreaseButton = bgmContainer:FindFirstChild("BGMDecreaseButton")
				bgmIncreaseButton = bgmContainer:FindFirstChild("BGMIncreaseButton")
				bgmMuteButton = bgmContainer:FindFirstChild("BGMMuteButton")
			else warn("SettingsUIManager: BGMVolumeContainer ��ã��") end

			local sfxContainer = contentFrame:FindFirstChild("SFXVolumeContainer")
			if sfxContainer then
				sfxVolumeValueLabel = sfxContainer:FindFirstChild("SFXVolumeValueLabel")
				sfxDecreaseButton = sfxContainer:FindFirstChild("SFXDecreaseButton")
				sfxIncreaseButton = sfxContainer:FindFirstChild("SFXIncreaseButton")
				sfxMuteButton = sfxContainer:FindFirstChild("SFXMuteButton")
			else warn("SettingsUIManager: SFXVolumeContainer ��ã��") end
		else warn("SettingsUIManager: ContentFrame ��ã��") end

		if not (bgmVolumeValueLabel and bgmDecreaseButton and bgmIncreaseButton and bgmMuteButton and
			sfxVolumeValueLabel and sfxDecreaseButton and sfxIncreaseButton and sfxMuteButton) then
			warn("SettingsUIManager: ����� ���� UI ��� �� �Ϻθ� ã�� �� �����ϴ�!")
			SettingsUIManager.SettingsFrame = nil; -- ���� �� ���� �ʱ�ȭ
			return false
		end
		print("SettingsUIManager: ����� UI ���� ���� �Ϸ�.")
		return true
	else
		warn("SettingsUIManager.SetupUIReferences: SettingsFrame�� ã�� �� �����ϴ�!")
		return false
	end
end
-- #######################################################################################

function SettingsUIManager.LoadAudioSettingsToUI()
	if not SoundManager then print("SettingsUIManager: SoundManager not loaded!"); return end
	if not SettingsUIManager.SettingsFrame then -- ��� �������� SettingsFrame ����
		if not SetupUIReferences() or not SettingsUIManager.SettingsFrame then 
			print("SettingsUIManager.LoadAudioSettingsToUI: UI references not set up or SettingsFrame still nil!")
			return 
		end
	end

	local currentBGMVol = SoundManager.GetMasterBGMVolume()
	local currentSFXVol = SoundManager.GetMasterSFXVolume()

	isBGMMuted = (currentBGMVol == 0)
	if currentBGMVol > 0 then previousBGMVolume = currentBGMVol end 

	isSFXMuted = (currentSFXVol == 0)
	if currentSFXVol > 0 then previousSFXVolume = currentSFXVol end

	if bgmVolumeValueLabel then bgmVolumeValueLabel.Text = string.format("%.0f%%", currentBGMVol * 100) end
	if bgmMuteButton then bgmMuteButton.Text = isBGMMuted and "BGM �ѱ�" or "BGM ����" end

	if sfxVolumeValueLabel then sfxVolumeValueLabel.Text = string.format("%.0f%%", currentSFXVol * 100) end
	if sfxMuteButton then sfxMuteButton.Text = isSFXMuted and "SFX �ѱ�" or "SFX ����" end

	print("SettingsUIManager: Audio settings loaded to UI. BGM Vol:", currentBGMVol, "SFX Vol:", currentSFXVol, "BGM Muted:", isBGMMuted, "SFX Muted:", isSFXMuted)
end

function SettingsUIManager.Init()
	ModuleManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ModuleManager"))
	CoreUIManager = ModuleManager:GetModule("CoreUIManager") -- CoreUIManager �ʱ�ȭ
	SoundManager = ModuleManager:GetModule("SoundManager")
	RequestDataResetEvent = ReplicatedStorage:WaitForChild("RequestDataResetEvent")
	if not SoundManager then warn("SettingsUIManager.Init: SoundManager �ε� ����!") end
	if not RequestDataResetEvent then warn("SettingsUIManager.Init: RequestDataResetEvent�� ã�� �� �����ϴ�!") end

	SetupUIReferences() -- UI ���� ���� (��� ���� SettingsFrame�� ����)
	print("SettingsUIManager: Initialized.")
end

-- ##### [��� ����] ShowSettings �Լ����� CoreUIManager.OpenMainUIPopup ��� #####
function SettingsUIManager.ShowSettings(show)
	if not CoreUIManager then 
		warn("SettingsUIManager.ShowSettings: CoreUIManager not loaded!")
		if SettingsUIManager.SettingsFrame then SettingsUIManager.SettingsFrame.Visible = show end -- Fallback
		return
	end
	if not SettingsUIManager.SettingsFrame then -- ��� �������� SettingsFrame ���
		if not SetupUIReferences() or not SettingsUIManager.SettingsFrame then
			warn("SettingsUIManager.ShowSettings: SettingsFrame ���� ���� ����, ǥ�� �Ұ� (��õ� ��)")
			return
		end
	end

	if show then
		CoreUIManager.OpenMainUIPopup("SettingsFrame") -- �ٸ� �ֿ� �˾� �ݰ� ���� â ����
		SettingsUIManager.LoadAudioSettingsToUI()
	else
		CoreUIManager.ShowFrame("SettingsFrame", false) -- �ܼ��� ���� â �ݱ�
	end
	print("SettingsUIManager: ShowSettings called with", show)
end
-- #####################################################################

function SettingsUIManager.ChangeBGMVolume(increase)
	if not SoundManager then return end
	if not SettingsUIManager.SettingsFrame then if not SetupUIReferences() or not SettingsUIManager.SettingsFrame then return end end

	local currentVol = SoundManager.GetMasterBGMVolume()
	local newVol
	if increase then
		newVol = math.min(1, currentVol + VOLUME_STEP)
	else
		newVol = math.max(0, currentVol - VOLUME_STEP)
	end

	SoundManager.SetMasterBGMVolume(newVol)
	if bgmVolumeValueLabel then bgmVolumeValueLabel.Text = string.format("%.0f%%", newVol * 100) end

	isBGMMuted = (newVol == 0)
	if bgmMuteButton then bgmMuteButton.Text = isBGMMuted and "BGM �ѱ�" or "BGM ����" end
	if not isBGMMuted then previousBGMVolume = newVol end
	print("SettingsUIManager: BGM Volume Changed to", newVol, "Muted:", isBGMMuted)
end

function SettingsUIManager.ChangeSFXVolume(increase)
	if not SoundManager then return end
	if not SettingsUIManager.SettingsFrame then if not SetupUIReferences() or not SettingsUIManager.SettingsFrame then return end end

	local currentVol = SoundManager.GetMasterSFXVolume()
	local newVol
	if increase then
		newVol = math.min(1, currentVol + VOLUME_STEP)
	else
		newVol = math.max(0, currentVol - VOLUME_STEP)
	end

	SoundManager.SetMasterSFXVolume(newVol)
	if sfxVolumeValueLabel then sfxVolumeValueLabel.Text = string.format("%.0f%%", newVol * 100) end

	isSFXMuted = (newVol == 0)
	if sfxMuteButton then sfxMuteButton.Text = isSFXMuted and "SFX �ѱ�" or "SFX ����" end
	if not isSFXMuted then previousSFXVolume = newVol end
	print("SettingsUIManager: SFX Volume Changed to", newVol, "Muted:", isSFXMuted)
end

function SettingsUIManager.ToggleBGMMute()
	if not SoundManager then return end
	if not SettingsUIManager.SettingsFrame then if not SetupUIReferences() or not SettingsUIManager.SettingsFrame then return end end

	isBGMMuted = not isBGMMuted
	local targetVolume
	if isBGMMuted then
		local currentActualVolume = SoundManager.GetMasterBGMVolume()
		if currentActualVolume > 0 then 
			previousBGMVolume = currentActualVolume
		end
		targetVolume = 0
		if bgmMuteButton then bgmMuteButton.Text = "BGM �ѱ�" end
	else
		targetVolume = previousBGMVolume 
		if bgmMuteButton then bgmMuteButton.Text = "BGM ����" end
	end
	SoundManager.SetMasterBGMVolume(targetVolume)
	if bgmVolumeValueLabel then bgmVolumeValueLabel.Text = string.format("%.0f%%", targetVolume * 100) end
	print("SettingsUIManager: Toggled BGM Mute. Muted:", isBGMMuted, "Volume set to:", targetVolume)
end

function SettingsUIManager.ToggleSFXMute()
	if not SoundManager then return end
	if not SettingsUIManager.SettingsFrame then if not SetupUIReferences() or not SettingsUIManager.SettingsFrame then return end end

	isSFXMuted = not isSFXMuted
	local targetVolume
	if isSFXMuted then
		local currentActualVolume = SoundManager.GetMasterSFXVolume()
		if currentActualVolume > 0 then
			previousSFXVolume = currentActualVolume
		end
		targetVolume = 0
		if sfxMuteButton then sfxMuteButton.Text = "SFX �ѱ�" end
	else
		targetVolume = previousSFXVolume
		if sfxMuteButton then sfxMuteButton.Text = "SFX ����" end
	end
	SoundManager.SetMasterSFXVolume(targetVolume)
	if sfxVolumeValueLabel then sfxVolumeValueLabel.Text = string.format("%.0f%%", targetVolume * 100) end
	print("SettingsUIManager: Toggled SFX Mute. Muted:", isSFXMuted, "Volume set to:", targetVolume)
end

function SettingsUIManager.RequestDataResetConfirmation()
	print("SettingsUIManager: Requesting data reset confirmation...")
	if not CoreUIManager or not CoreUIManager.ShowConfirmationPopup then
		warn("SettingsUIManager: CoreUIManager �Ǵ� Ȯ�� �˾� �Լ��� ����� �� �����ϴ�.")
		return
	end
	if not RequestDataResetEvent then
		warn("SettingsUIManager: RequestDataResetEvent�� ã�� �� �����ϴ�. ���� ��û �Ұ�.")
		CoreUIManager.ShowPopupMessage("����", "������ �ʱ�ȭ ��û�� ���� �� �����ϴ�.", 3)
		return
	end

	local title = "������ �ʱ�ȭ Ȯ��"
	local message = "������ ��� ���� ��Ȳ�� �ʱ�ȭ�Ͻðڽ��ϱ�?\n<font color='#FF5555'>�� �۾��� �ǵ��� �� �����ϴ�!</font>"

	local confirmCallback = function()
		print("SettingsUIManager: User confirmed data reset. Firing event to server...")
		RequestDataResetEvent:FireServer()
		if CoreUIManager and CoreUIManager.ShowPopupMessage then
			CoreUIManager.ShowPopupMessage("�˸�", "������ �ʱ�ȭ ��û�� ���½��ϴ�. ��� �� ���ӿ��� �������ϴ�.", 4)
		end
		SettingsUIManager.ShowSettings(false) -- ���� â �ݱ�
	end

	CoreUIManager.ShowConfirmationPopup(title, message, confirmCallback)
end

return SettingsUIManager