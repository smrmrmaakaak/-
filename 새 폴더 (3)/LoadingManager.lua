-- ReplicatedStorage > Modules > LoadingManager.lua

local LoadingManager = {}

-- 필요한 서비스 가져오기
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- 모듈 참조 변수
local CoreUIManager

-- 로딩 프레임 참조 변수 (초기에는 nil)
local loadingFrame = nil
local loadingText = nil
local spinnerImage = nil
local spinnerTween = nil

-- 모듈 초기화 함수 (UI 참조 설정 제거)
function LoadingManager.Init()
	local ModuleManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ModuleManager"))
	CoreUIManager = ModuleManager:GetModule("CoreUIManager")
	print("LoadingManager: Initialized (UI references will be set later).")
end

-- UI 요소 참조 설정 함수 (GuiManager에서 UI 빌드 후 호출)
function LoadingManager.SetupUIReferences()
	if loadingFrame then return end -- 이미 설정되었으면 반환

	local player = Players.LocalPlayer
	local playerGui = player and player:WaitForChild("PlayerGui")
	local mainGui = playerGui and playerGui:WaitForChild("MainGui")
	local backgroundFrame = mainGui and mainGui:FindFirstChild("BackgroundFrame")
	local framesFolder = backgroundFrame and backgroundFrame:FindFirstChild("Frames")

	if framesFolder then
		loadingFrame = framesFolder:FindFirstChild("LoadingFrame")
		if loadingFrame then
			loadingText = loadingFrame:FindFirstChild("LoadingText")
			spinnerImage = loadingFrame:FindFirstChild("SpinnerImage") -- 빌더에서 추가했다면 찾음
			print("LoadingManager: UI references set successfully.")
		else
			warn("LoadingManager.SetupUIReferences: LoadingFrame not found in Frames folder!")
		end
	else
		warn("LoadingManager.SetupUIReferences: Frames folder not found!")
	end

	if not loadingFrame then
		warn("LoadingManager.SetupUIReferences: Failed to set LoadingFrame reference.")
	end
end

-- 로딩 화면 보이기
function LoadingManager.ShowLoading(message)
	if not loadingFrame then LoadingManager.SetupUIReferences() end -- 참조 없으면 설정 시도
	if not loadingFrame then warn("LoadingManager.ShowLoading: LoadingFrame not found!"); return end

	if CoreUIManager and CoreUIManager.ShowFrame then
		if loadingText then
			loadingText.Text = message or "로딩 중..." -- 메시지 설정
		end
		CoreUIManager.ShowFrame("LoadingFrame", true)
		print("LoadingManager: LoadingFrame shown.")

		-- 스피너 애니메이션 시작 (선택적)
		if spinnerImage then
			if spinnerTween then spinnerTween:Cancel() end
			spinnerImage.Rotation = 0 -- 회전 초기화
			local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
			spinnerTween = TweenService:Create(spinnerImage, tweenInfo, { Rotation = 360 })
			spinnerTween:Play()
			print("LoadingManager: Spinner animation started.")
		end

	else
		warn("LoadingManager.ShowLoading: CoreUIManager not loaded!")
	end
end

-- 로딩 화면 숨기기
function LoadingManager.HideLoading()
	if not loadingFrame then warn("LoadingManager.HideLoading: LoadingFrame not found!"); return end

	if CoreUIManager and CoreUIManager.ShowFrame then
		CoreUIManager.ShowFrame("LoadingFrame", false)
		print("LoadingManager: LoadingFrame hidden.")

		-- 스피너 애니메이션 중지 (선택적)
		if spinnerTween then
			spinnerTween:Cancel()
			spinnerTween = nil
			print("LoadingManager: Spinner animation stopped.")
		end
		if spinnerImage then
			spinnerImage.Rotation = 0 -- 회전 초기화
		end

	else
		warn("LoadingManager.HideLoading: CoreUIManager not loaded!")
	end
end

-- (선택 사항) 로딩 진행률 업데이트 함수
-- function LoadingManager.UpdateProgress(progress, message)
--	 if not loadingFrame or not loadingText then return end
--	 loadingText.Text = message or string.format("로딩 중... (%.0f%%)", progress * 100)
-- end

return LoadingManager