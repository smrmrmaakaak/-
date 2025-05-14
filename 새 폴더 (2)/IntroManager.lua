-- ReplicatedStorage > Modules > IntroManager.lua

local IntroManager = {}

-- 필요한 서비스 가져오기
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- 모듈 참조 변수
local CoreUIManager

-- 인트로 프레임 참조 변수 (초기에는 nil)
local introFrame = nil
local introImage = nil

-- 모듈 초기화 함수 (UI 참조 설정 제거)
function IntroManager.Init()
	local ModuleManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ModuleManager"))
	CoreUIManager = ModuleManager:GetModule("CoreUIManager")
	print("IntroManager: Initialized (UI references will be set later).")
end

-- UI 요소 참조 설정 함수 (GuiManager에서 UI 빌드 후 호출)
function IntroManager.SetupUIReferences()
	if introFrame then return end -- 이미 설정되었으면 반환

	local player = Players.LocalPlayer
	local playerGui = player and player:WaitForChild("PlayerGui")
	local mainGui = playerGui and playerGui:WaitForChild("MainGui")
	local backgroundFrame = mainGui and mainGui:FindFirstChild("BackgroundFrame")
	local framesFolder = backgroundFrame and backgroundFrame:FindFirstChild("Frames")

	if framesFolder then
		introFrame = framesFolder:FindFirstChild("IntroFrame")
		if introFrame then
			introImage = introFrame:FindFirstChild("IntroImage")
			print("IntroManager: UI references set successfully.")
		else
			warn("IntroManager.SetupUIReferences: IntroFrame not found in Frames folder!")
		end
	else
		warn("IntroManager.SetupUIReferences: Frames folder not found!")
	end

	if not introFrame or not introImage then
		warn("IntroManager.SetupUIReferences: Failed to set UI references.")
		introFrame = nil -- 실패 시 참조 초기화
		introImage = nil
	end
end

-- 인트로 화면 보이기
function IntroManager.ShowIntro()
	if not introFrame then IntroManager.SetupUIReferences() end -- 참조 없으면 설정 시도
	if not introFrame then warn("IntroManager.ShowIntro: IntroFrame not found!"); return end

	if CoreUIManager and CoreUIManager.ShowFrame then
		CoreUIManager.ShowFrame("IntroFrame", true)
		print("IntroManager: IntroFrame shown.")
	else
		warn("IntroManager.ShowIntro: CoreUIManager not loaded!")
	end
end

-- 인트로 화면 숨기기
function IntroManager.HideIntro()
	if not introFrame then warn("IntroManager.HideIntro: IntroFrame not found!"); return end -- 숨길 프레임 없으면 종료

	if CoreUIManager and CoreUIManager.ShowFrame then
		CoreUIManager.ShowFrame("IntroFrame", false)
		print("IntroManager: IntroFrame hidden.")
	else
		warn("IntroManager.HideIntro: CoreUIManager not loaded!")
	end
end

-- 인트로 애니메이션 재생 함수
-- onCompleteCallback: 애니메이션 완료 후 호출될 함수
function IntroManager.PlayIntroAnimation(onCompleteCallback)
	if not introFrame or not introImage then IntroManager.SetupUIReferences() end -- 참조 없으면 설정 시도
	if not introFrame or not introImage then
		warn("IntroManager.PlayIntroAnimation: IntroFrame or IntroImage not found!")
		if onCompleteCallback then task.spawn(onCompleteCallback) end
		return
	end

	print("IntroManager: Playing intro animation...")

	-- 애니메이션 설정값
	local fadeInDuration = 0.8
	local zoomOutDuration = 1.2
	local zoomInDuration = 0.8
	local stayDuration = 0.5
	local fadeOutDuration = 1.0

	local startSize = UDim2.new(0.75, 0, 0.75, 0)
	local midSize = UDim2.new(0.85, 0, 0.85, 0)
	local endSize = UDim2.new(0.8, 0, 0.8, 0)

	-- 초기 상태 설정
	introImage.Size = startSize
	introImage.ImageTransparency = 1
	introFrame.BackgroundTransparency = 0

	-- 트윈 생성
	local tweenInfoFadeIn = TweenInfo.new(fadeInDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tweenFadeIn = TweenService:Create(introImage, tweenInfoFadeIn, { ImageTransparency = 0 })

	local tweenInfoZoomOut = TweenInfo.new(zoomOutDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local tweenZoomOut = TweenService:Create(introImage, tweenInfoZoomOut, { Size = midSize })

	local tweenInfoZoomIn = TweenInfo.new(zoomInDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local tweenZoomIn = TweenService:Create(introImage, tweenInfoZoomIn, { Size = endSize })

	local tweenInfoFadeOut = TweenInfo.new(fadeOutDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local tweenFadeOut = TweenService:Create(introImage, tweenInfoFadeOut, { ImageTransparency = 1 })

	-- 애니메이션 순차 실행
	tweenFadeIn:Play()
	tweenFadeIn.Completed:Connect(function()
		tweenZoomOut:Play()
	end)
	tweenZoomOut.Completed:Connect(function()
		task.wait(stayDuration / 2)
		tweenZoomIn:Play()
	end)
	tweenZoomIn.Completed:Connect(function()
		task.wait(stayDuration / 2)
		tweenFadeOut:Play()
	end)
	tweenFadeOut.Completed:Connect(function()
		print("IntroManager: Intro animation complete.")
		if onCompleteCallback then
			task.spawn(onCompleteCallback)
		end
	end)
end

return IntroManager