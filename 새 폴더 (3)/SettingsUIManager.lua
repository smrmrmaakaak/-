-- ReplicatedStorage > Modules > SettingsUIManager.lua
-- *** [기능 수정] UI 창 겹침 방지를 위해 CoreUIManager.OpenMainUIPopup 사용 ***

local SettingsUIManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local ModuleManager
local CoreUIManager -- CoreUIManager 참조 선언
local SoundManager
local SettingsFrame = nil -- 모듈 스코프로 이동 및 초기화
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

-- ##### [기능 수정] UI 프레임 참조를 위한 함수 (내부 로직은 유지, SettingsFrame 참조를 모듈 변수로 설정) #####
local function SetupUIReferences() -- 함수 이름 변경 없음 (내부용)
	if SettingsUIManager.SettingsFrame and bgmVolumeValueLabel then -- SettingsUIManager.SettingsFrame 사용, 다른 내부 UI 요소도 확인
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
	SettingsUIManager.SettingsFrame = framesFolder and framesFolder:FindFirstChild("SettingsFrame") -- 모듈 스코프 변수에 할당

	if SettingsUIManager.SettingsFrame then
		local contentFrame = SettingsUIManager.SettingsFrame:FindFirstChild("ContentFrame")
		if contentFrame then
			local bgmContainer = contentFrame:FindFirstChild("BGMVolumeContainer")
			if bgmContainer then
				bgmVolumeValueLabel = bgmContainer:FindFirstChild("BGMVolumeValueLabel")
				bgmDecreaseButton = bgmContainer:FindFirstChild("BGMDecreaseButton")
				bgmIncreaseButton = bgmContainer:FindFirstChild("BGMIncreaseButton")
				bgmMuteButton = bgmContainer:FindFirstChild("BGMMuteButton")
			else warn("SettingsUIManager: BGMVolumeContainer 못찾음") end

			local sfxContainer = contentFrame:FindFirstChild("SFXVolumeContainer")
			if sfxContainer then
				sfxVolumeValueLabel = sfxContainer:FindFirstChild("SFXVolumeValueLabel")
				sfxDecreaseButton = sfxContainer:FindFirstChild("SFXDecreaseButton")
				sfxIncreaseButton = sfxContainer:FindFirstChild("SFXIncreaseButton")
				sfxMuteButton = sfxContainer:FindFirstChild("SFXMuteButton")
			else warn("SettingsUIManager: SFXVolumeContainer 못찾음") end
		else warn("SettingsUIManager: ContentFrame 못찾음") end

		if not (bgmVolumeValueLabel and bgmDecreaseButton and bgmIncreaseButton and bgmMuteButton and
			sfxVolumeValueLabel and sfxDecreaseButton and sfxIncreaseButton and sfxMuteButton) then
			warn("SettingsUIManager: 오디오 설정 UI 요소 중 일부를 찾을 수 없습니다!")
			SettingsUIManager.SettingsFrame = nil; -- 실패 시 참조 초기화
			return false
		end
		print("SettingsUIManager: 오디오 UI 참조 설정 완료.")
		return true
	else
		warn("SettingsUIManager.SetupUIReferences: SettingsFrame을 찾을 수 없습니다!")
		return false
	end
end
-- #######################################################################################

function SettingsUIManager.LoadAudioSettingsToUI()
	if not SoundManager then print("SettingsUIManager: SoundManager not loaded!"); return end
	if not SettingsUIManager.SettingsFrame then -- 모듈 스코프의 SettingsFrame 참조
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
	if bgmMuteButton then bgmMuteButton.Text = isBGMMuted and "BGM 켜기" or "BGM 끄기" end

	if sfxVolumeValueLabel then sfxVolumeValueLabel.Text = string.format("%.0f%%", currentSFXVol * 100) end
	if sfxMuteButton then sfxMuteButton.Text = isSFXMuted and "SFX 켜기" or "SFX 끄기" end

	print("SettingsUIManager: Audio settings loaded to UI. BGM Vol:", currentBGMVol, "SFX Vol:", currentSFXVol, "BGM Muted:", isBGMMuted, "SFX Muted:", isSFXMuted)
end

function SettingsUIManager.Init()
	ModuleManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ModuleManager"))
	CoreUIManager = ModuleManager:GetModule("CoreUIManager") -- CoreUIManager 초기화
	SoundManager = ModuleManager:GetModule("SoundManager")
	RequestDataResetEvent = ReplicatedStorage:WaitForChild("RequestDataResetEvent")
	if not SoundManager then warn("SettingsUIManager.Init: SoundManager 로드 실패!") end
	if not RequestDataResetEvent then warn("SettingsUIManager.Init: RequestDataResetEvent를 찾을 수 없습니다!") end

	SetupUIReferences() -- UI 참조 설정 (모듈 변수 SettingsFrame을 위함)
	print("SettingsUIManager: Initialized.")
end

-- ##### [기능 수정] ShowSettings 함수에서 CoreUIManager.OpenMainUIPopup 사용 #####
function SettingsUIManager.ShowSettings(show)
	if not CoreUIManager then 
		warn("SettingsUIManager.ShowSettings: CoreUIManager not loaded!")
		if SettingsUIManager.SettingsFrame then SettingsUIManager.SettingsFrame.Visible = show end -- Fallback
		return
	end
	if not SettingsUIManager.SettingsFrame then -- 모듈 스코프의 SettingsFrame 사용
		if not SetupUIReferences() or not SettingsUIManager.SettingsFrame then
			warn("SettingsUIManager.ShowSettings: SettingsFrame 참조 설정 실패, 표시 불가 (재시도 후)")
			return
		end
	end

	if show then
		CoreUIManager.OpenMainUIPopup("SettingsFrame") -- 다른 주요 팝업 닫고 설정 창 열기
		SettingsUIManager.LoadAudioSettingsToUI()
	else
		CoreUIManager.ShowFrame("SettingsFrame", false) -- 단순히 설정 창 닫기
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
	if bgmMuteButton then bgmMuteButton.Text = isBGMMuted and "BGM 켜기" or "BGM 끄기" end
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
	if sfxMuteButton then sfxMuteButton.Text = isSFXMuted and "SFX 켜기" or "SFX 끄기" end
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
		if bgmMuteButton then bgmMuteButton.Text = "BGM 켜기" end
	else
		targetVolume = previousBGMVolume 
		if bgmMuteButton then bgmMuteButton.Text = "BGM 끄기" end
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
		if sfxMuteButton then sfxMuteButton.Text = "SFX 켜기" end
	else
		targetVolume = previousSFXVolume
		if sfxMuteButton then sfxMuteButton.Text = "SFX 끄기" end
	end
	SoundManager.SetMasterSFXVolume(targetVolume)
	if sfxVolumeValueLabel then sfxVolumeValueLabel.Text = string.format("%.0f%%", targetVolume * 100) end
	print("SettingsUIManager: Toggled SFX Mute. Muted:", isSFXMuted, "Volume set to:", targetVolume)
end

function SettingsUIManager.RequestDataResetConfirmation()
	print("SettingsUIManager: Requesting data reset confirmation...")
	if not CoreUIManager or not CoreUIManager.ShowConfirmationPopup then
		warn("SettingsUIManager: CoreUIManager 또는 확인 팝업 함수를 사용할 수 없습니다.")
		return
	end
	if not RequestDataResetEvent then
		warn("SettingsUIManager: RequestDataResetEvent를 찾을 수 없습니다. 서버 요청 불가.")
		CoreUIManager.ShowPopupMessage("오류", "데이터 초기화 요청을 보낼 수 없습니다.", 3)
		return
	end

	local title = "데이터 초기화 확인"
	local message = "정말로 모든 진행 상황을 초기화하시겠습니까?\n<font color='#FF5555'>이 작업은 되돌릴 수 없습니다!</font>"

	local confirmCallback = function()
		print("SettingsUIManager: User confirmed data reset. Firing event to server...")
		RequestDataResetEvent:FireServer()
		if CoreUIManager and CoreUIManager.ShowPopupMessage then
			CoreUIManager.ShowPopupMessage("알림", "데이터 초기화 요청을 보냈습니다. 잠시 후 게임에서 나가집니다.", 4)
		end
		SettingsUIManager.ShowSettings(false) -- 설정 창 닫기
	end

	CoreUIManager.ShowConfirmationPopup(title, message, confirmCallback)
end

return SettingsUIManager