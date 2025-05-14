-- ReplicatedStorage > Modules > LoadingManager.lua

local LoadingManager = {}

-- �ʿ��� ���� ��������
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- ��� ���� ����
local CoreUIManager

-- �ε� ������ ���� ���� (�ʱ⿡�� nil)
local loadingFrame = nil
local loadingText = nil
local spinnerImage = nil
local spinnerTween = nil

-- ��� �ʱ�ȭ �Լ� (UI ���� ���� ����)
function LoadingManager.Init()
	local ModuleManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ModuleManager"))
	CoreUIManager = ModuleManager:GetModule("CoreUIManager")
	print("LoadingManager: Initialized (UI references will be set later).")
end

-- UI ��� ���� ���� �Լ� (GuiManager���� UI ���� �� ȣ��)
function LoadingManager.SetupUIReferences()
	if loadingFrame then return end -- �̹� �����Ǿ����� ��ȯ

	local player = Players.LocalPlayer
	local playerGui = player and player:WaitForChild("PlayerGui")
	local mainGui = playerGui and playerGui:WaitForChild("MainGui")
	local backgroundFrame = mainGui and mainGui:FindFirstChild("BackgroundFrame")
	local framesFolder = backgroundFrame and backgroundFrame:FindFirstChild("Frames")

	if framesFolder then
		loadingFrame = framesFolder:FindFirstChild("LoadingFrame")
		if loadingFrame then
			loadingText = loadingFrame:FindFirstChild("LoadingText")
			spinnerImage = loadingFrame:FindFirstChild("SpinnerImage") -- �������� �߰��ߴٸ� ã��
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

-- �ε� ȭ�� ���̱�
function LoadingManager.ShowLoading(message)
	if not loadingFrame then LoadingManager.SetupUIReferences() end -- ���� ������ ���� �õ�
	if not loadingFrame then warn("LoadingManager.ShowLoading: LoadingFrame not found!"); return end

	if CoreUIManager and CoreUIManager.ShowFrame then
		if loadingText then
			loadingText.Text = message or "�ε� ��..." -- �޽��� ����
		end
		CoreUIManager.ShowFrame("LoadingFrame", true)
		print("LoadingManager: LoadingFrame shown.")

		-- ���ǳ� �ִϸ��̼� ���� (������)
		if spinnerImage then
			if spinnerTween then spinnerTween:Cancel() end
			spinnerImage.Rotation = 0 -- ȸ�� �ʱ�ȭ
			local tweenInfo = TweenInfo.new(2, Enum.EasingStyle.Linear, Enum.EasingDirection.InOut, -1)
			spinnerTween = TweenService:Create(spinnerImage, tweenInfo, { Rotation = 360 })
			spinnerTween:Play()
			print("LoadingManager: Spinner animation started.")
		end

	else
		warn("LoadingManager.ShowLoading: CoreUIManager not loaded!")
	end
end

-- �ε� ȭ�� �����
function LoadingManager.HideLoading()
	if not loadingFrame then warn("LoadingManager.HideLoading: LoadingFrame not found!"); return end

	if CoreUIManager and CoreUIManager.ShowFrame then
		CoreUIManager.ShowFrame("LoadingFrame", false)
		print("LoadingManager: LoadingFrame hidden.")

		-- ���ǳ� �ִϸ��̼� ���� (������)
		if spinnerTween then
			spinnerTween:Cancel()
			spinnerTween = nil
			print("LoadingManager: Spinner animation stopped.")
		end
		if spinnerImage then
			spinnerImage.Rotation = 0 -- ȸ�� �ʱ�ȭ
		end

	else
		warn("LoadingManager.HideLoading: CoreUIManager not loaded!")
	end
end

-- (���� ����) �ε� ����� ������Ʈ �Լ�
-- function LoadingManager.UpdateProgress(progress, message)
--	 if not loadingFrame or not loadingText then return end
--	 loadingText.Text = message or string.format("�ε� ��... (%.0f%%)", progress * 100)
-- end

return LoadingManager