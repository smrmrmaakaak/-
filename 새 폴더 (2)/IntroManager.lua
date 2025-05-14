-- ReplicatedStorage > Modules > IntroManager.lua

local IntroManager = {}

-- �ʿ��� ���� ��������
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- ��� ���� ����
local CoreUIManager

-- ��Ʈ�� ������ ���� ���� (�ʱ⿡�� nil)
local introFrame = nil
local introImage = nil

-- ��� �ʱ�ȭ �Լ� (UI ���� ���� ����)
function IntroManager.Init()
	local ModuleManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ModuleManager"))
	CoreUIManager = ModuleManager:GetModule("CoreUIManager")
	print("IntroManager: Initialized (UI references will be set later).")
end

-- UI ��� ���� ���� �Լ� (GuiManager���� UI ���� �� ȣ��)
function IntroManager.SetupUIReferences()
	if introFrame then return end -- �̹� �����Ǿ����� ��ȯ

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
		introFrame = nil -- ���� �� ���� �ʱ�ȭ
		introImage = nil
	end
end

-- ��Ʈ�� ȭ�� ���̱�
function IntroManager.ShowIntro()
	if not introFrame then IntroManager.SetupUIReferences() end -- ���� ������ ���� �õ�
	if not introFrame then warn("IntroManager.ShowIntro: IntroFrame not found!"); return end

	if CoreUIManager and CoreUIManager.ShowFrame then
		CoreUIManager.ShowFrame("IntroFrame", true)
		print("IntroManager: IntroFrame shown.")
	else
		warn("IntroManager.ShowIntro: CoreUIManager not loaded!")
	end
end

-- ��Ʈ�� ȭ�� �����
function IntroManager.HideIntro()
	if not introFrame then warn("IntroManager.HideIntro: IntroFrame not found!"); return end -- ���� ������ ������ ����

	if CoreUIManager and CoreUIManager.ShowFrame then
		CoreUIManager.ShowFrame("IntroFrame", false)
		print("IntroManager: IntroFrame hidden.")
	else
		warn("IntroManager.HideIntro: CoreUIManager not loaded!")
	end
end

-- ��Ʈ�� �ִϸ��̼� ��� �Լ�
-- onCompleteCallback: �ִϸ��̼� �Ϸ� �� ȣ��� �Լ�
function IntroManager.PlayIntroAnimation(onCompleteCallback)
	if not introFrame or not introImage then IntroManager.SetupUIReferences() end -- ���� ������ ���� �õ�
	if not introFrame or not introImage then
		warn("IntroManager.PlayIntroAnimation: IntroFrame or IntroImage not found!")
		if onCompleteCallback then task.spawn(onCompleteCallback) end
		return
	end

	print("IntroManager: Playing intro animation...")

	-- �ִϸ��̼� ������
	local fadeInDuration = 0.8
	local zoomOutDuration = 1.2
	local zoomInDuration = 0.8
	local stayDuration = 0.5
	local fadeOutDuration = 1.0

	local startSize = UDim2.new(0.75, 0, 0.75, 0)
	local midSize = UDim2.new(0.85, 0, 0.85, 0)
	local endSize = UDim2.new(0.8, 0, 0.8, 0)

	-- �ʱ� ���� ����
	introImage.Size = startSize
	introImage.ImageTransparency = 1
	introFrame.BackgroundTransparency = 0

	-- Ʈ�� ����
	local tweenInfoFadeIn = TweenInfo.new(fadeInDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
	local tweenFadeIn = TweenService:Create(introImage, tweenInfoFadeIn, { ImageTransparency = 0 })

	local tweenInfoZoomOut = TweenInfo.new(zoomOutDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local tweenZoomOut = TweenService:Create(introImage, tweenInfoZoomOut, { Size = midSize })

	local tweenInfoZoomIn = TweenInfo.new(zoomInDuration, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
	local tweenZoomIn = TweenService:Create(introImage, tweenInfoZoomIn, { Size = endSize })

	local tweenInfoFadeOut = TweenInfo.new(fadeOutDuration, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	local tweenFadeOut = TweenService:Create(introImage, tweenInfoFadeOut, { ImageTransparency = 1 })

	-- �ִϸ��̼� ���� ����
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