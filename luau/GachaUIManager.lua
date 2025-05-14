--[[
  GachaUIManager (ModuleScript)
  �̱�(��í) �ý��� UI ���� ���� ���
  (â ����/�ݱ�, ��ȭ ǥ��, ��� ǥ�� ��)
  *** [��� ����] UI â ��ħ ������ ���� CoreUIManager.OpenMainUIPopup ��� ***
]]
local GachaUIManager = {}

-- �ʿ��� ���� �� ��� �ε�
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService") 
local HttpService = game:GetService("HttpService") 

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainGui = playerGui:WaitForChild("MainGui") -- mainGui ����

local ModuleManager
local CoreUIManager -- CoreUIManager ���� ����
local PlayerData
local ItemDatabase

local gachaFrame = nil -- gachaFrame ������ ��� �������� �̵�

-- ��� �ʱ�ȭ
function GachaUIManager.Init()
	ModuleManager = require(ReplicatedStorage.Modules:WaitForChild("ModuleManager"))
	CoreUIManager = ModuleManager:GetModule("CoreUIManager") -- CoreUIManager �ʱ�ȭ
	PlayerData = ModuleManager:GetModule("PlayerData")
	ItemDatabase = ModuleManager:GetModule("ItemDatabase")
	GachaUIManager.SetupUIReferences() -- UI ���� ����
	print("GachaUIManager: Initialized.")
end

-- ##### [��� �߰�] UI ������ ������ ���� �Լ� #####
function GachaUIManager.SetupUIReferences()
	if not mainGui then 
		local p = Players.LocalPlayer
		local pg = p and p:WaitForChild("PlayerGui")
		mainGui = pg and pg:FindFirstChild("MainGui")
		if not mainGui then
			warn("GachaUIManager.SetupUIReferences: MainGui not found even after retry!")
			return
		end
	end
	local backgroundFrame = mainGui:FindFirstChild("BackgroundFrame")
	if backgroundFrame then
		gachaFrame = backgroundFrame:FindFirstChild("GachaFrame")
		if not gachaFrame then 
			warn("GachaUIManager.SetupUIReferences: GachaFrame not found!")
		else
			print("GachaUIManager: GachaFrame reference established.")
		end
	else
		warn("GachaUIManager.SetupUIReferences: BackgroundFrame not found!")
	end
end
-- #################################################


-- ��ȭ(���) ǥ�� ������Ʈ
function GachaUIManager.UpdateCurrencyDisplay()
	if not gachaFrame then 
		GachaUIManager.SetupUIReferences()
		if not gachaFrame then
			warn("GachaUIManager.UpdateCurrencyDisplay: GachaFrame is nil.")
			return
		end
	end
	local currencyLabel = gachaFrame:FindFirstChild("PlayerCurrencyLabel")
	if not currencyLabel or not PlayerData then return end

	local stats = PlayerData.GetStats(player) 
	if stats then
		currencyLabel.Text = "���� ���: " .. (stats.Gold or "???")
	else
		currencyLabel.Text = "���� ���: ????"
		warn("GachaUIManager: Failed to get player stats for currency display.")
	end
end

-- �̱� ��� ǥ��
function GachaUIManager.ShowPullResult(itemId)
	if not gachaFrame then 
		GachaUIManager.SetupUIReferences()
		if not gachaFrame then
			warn("GachaUIManager.ShowPullResult: GachaFrame is nil.")
			return
		end
	end

	local resultDisplayFrame = gachaFrame:FindFirstChild("ResultDisplayFrame")
	if not resultDisplayFrame then return end
	local resultImage = resultDisplayFrame:FindFirstChild("ResultItemImage")
	local resultNameLabel = resultDisplayFrame:FindFirstChild("ResultItemName")

	if not resultImage or not resultNameLabel then
		warn("GachaUIManager: Result display elements not found!")
		return
	end

	resultImage.Visible = false
	resultNameLabel.Visible = false
	resultNameLabel.Text = ""

	if not itemId then
		print("GachaUIManager: No item ID provided to ShowPullResult, hiding results.")
		return
	end

	if not ItemDatabase then
		warn("GachaUIManager.ShowPullResult: ItemDatabase not loaded!")
		return
	end

	local itemInfo = ItemDatabase.Items[itemId]
	if itemInfo then
		print("GachaUIManager: Displaying result for ItemID:", itemId, "Name:", itemInfo.Name)
		resultNameLabel.Text = itemInfo.Name
		if itemInfo.ImageId and itemInfo.ImageId ~= "" then
			resultImage.Image = itemInfo.ImageId
		else
			local encodedName = HttpService:UrlEncode(itemInfo.Name)
			resultImage.Image = string.format("https://placehold.co/80x80/cccccc/333333?text=%s", encodedName)
		end
		resultImage.Visible = true
		resultNameLabel.Visible = true

		resultDisplayFrame.BackgroundTransparency = 0.8
		resultImage.ImageTransparency = 1
		resultNameLabel.TextTransparency = 1
		local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local goal_image = { ImageTransparency = 0 }
		local goal_text = { TextTransparency = 0 }
		local tween = TweenService:Create(resultImage, tweenInfo, goal_image)
		local tween2 = TweenService:Create(resultNameLabel, tweenInfo, goal_text)
		tween:Play()
		tween2:Play()
	else
		warn("GachaUIManager: Item info not found for pulled ItemID:", itemId)
		resultNameLabel.Text = "�� �� ���� ������"
		resultNameLabel.Visible = true
	end
end

-- �̱� â ���̱�/�����
function GachaUIManager.ShowGacha(show)
	if not CoreUIManager then
		warn("GachaUIManager.ShowGacha: CoreUIManager not loaded!")
		if gachaFrame then gachaFrame.Visible = show end -- Fallback
		return
	end
	if not gachaFrame then
		GachaUIManager.SetupUIReferences()
		if not gachaFrame then
			warn("GachaUIManager.ShowGacha: GachaFrame is still nil after setup.")
			return
		end
	end

	if show then
		CoreUIManager.OpenMainUIPopup("GachaFrame") -- �ٸ� �ֿ� �˾� �ݰ� �̱� â ����
		GachaUIManager.UpdateCurrencyDisplay()
		GachaUIManager.ShowPullResult(nil) 
	else
		CoreUIManager.ShowFrame("GachaFrame", false) -- �ܼ��� �̱� â �ݱ�
		GachaUIManager.ShowPullResult(nil)
	end
	print("GachaUIManager: ShowGacha called with", show)
end

return GachaUIManager