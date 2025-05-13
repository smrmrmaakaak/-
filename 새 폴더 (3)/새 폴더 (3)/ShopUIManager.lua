--[[
  ShopUIManager (ModuleScript)
  ���� UI ���� ��� (��� ǥ��, ��� ���� ��) ���
  *** [����] �Ǹ� ��� ���� �� ItemDatabase�� ���� ������ �ǳʶٱ� ***
  *** [����] ��� �ý��� ����: ���� ��� ������ �̸��� ��޺� ���� ���� ***
  *** [��� ����] UI â ��ħ ������ ���� CoreUIManager.OpenMainUIPopup ��� ***
]]

local ShopUIManager = {}

-- �ʿ��� ���� �� ��� �ε�
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService") -- URL ���ڵ� ���� �߰�
local UserInputService = game:GetService("UserInputService") -- ���콺 ��ġ ���� ���� �߰�

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainGui = playerGui:WaitForChild("MainGui") -- mainGui ����

local ModuleManager
local ItemDatabase
local TooltipManager
local GuiUtils
local getPlayerInventoryFunction
local purchaseItemEvent
local sellItemEvent
local CoreUIManager -- CoreUIManager ���� ����

local RATING_COLORS = {
	["Common"] = Color3.fromRGB(180, 180, 180),
	["Uncommon"] = Color3.fromRGB(100, 200, 100),
	["Rare"] = Color3.fromRGB(100, 150, 255),
	["Epic"] = Color3.fromRGB(180, 100, 220),
	["Legendary"] = Color3.fromRGB(255, 165, 0),
}
local DEFAULT_RATING_COLOR = RATING_COLORS["Common"]

local currentShopMode = "Buy"
local shopFrame = nil -- shopFrame ������ ��� �������� �̵�

-- ��� �ʱ�ȭ �Լ�
function ShopUIManager.Init()
	ModuleManager = require(ReplicatedStorage.Modules:WaitForChild("ModuleManager"))
	ItemDatabase = ModuleManager:GetModule("ItemDatabase")
	TooltipManager = ModuleManager:GetModule("TooltipManager")
	GuiUtils = ModuleManager:GetModule("GuiUtils")
	CoreUIManager = ModuleManager:GetModule("CoreUIManager") -- CoreUIManager �ʱ�ȭ
	getPlayerInventoryFunction = ReplicatedStorage:WaitForChild("GetPlayerInventoryFunction")
	purchaseItemEvent = ReplicatedStorage:WaitForChild("PurchaseItemEvent")
	sellItemEvent = ReplicatedStorage:WaitForChild("SellItemEvent")

	ShopUIManager.SetupUIReferences() -- UI ���� ����
	print("ShopUIManager: Initialized and modules loaded.")
end

-- ##### [��� �߰�] UI ������ ������ ���� �Լ� #####
function ShopUIManager.SetupUIReferences()
	if not mainGui then 
		local p = Players.LocalPlayer
		local pg = p and p:WaitForChild("PlayerGui")
		mainGui = pg and pg:FindFirstChild("MainGui")
		if not mainGui then
			warn("ShopUIManager.SetupUIReferences: MainGui not found even after retry!")
			return
		end
	end
	local backgroundFrame = mainGui:FindFirstChild("BackgroundFrame")
	if backgroundFrame then
		shopFrame = backgroundFrame:FindFirstChild("ShopFrame")
		if not shopFrame then warn("ShopUIManager.SetupUIReferences: ShopFrame not found!") end
	else
		warn("ShopUIManager.SetupUIReferences: BackgroundFrame not found!")
	end
end
-- #################################################

-- ���� ��� ���� �Լ�
function ShopUIManager.SetShopMode(mode)
	if mode ~= "Buy" and mode ~= "Sell" then warn("ShopUIManager.SetShopMode: Invalid mode specified:", mode); return end

	if not shopFrame then -- shopFrame�� nil�̸� ���� �õ�
		ShopUIManager.SetupUIReferences()
		if not shopFrame then
			warn("ShopUIManager.SetShopMode: ShopFrame is nil, cannot set mode.")
			return
		end
	end

	local modeChanged = (mode ~= currentShopMode)
	currentShopMode = mode
	print("ShopUIManager: Setting shop mode to", mode)

	local tabFrame = shopFrame:FindFirstChild("TabFrame")
	local buyTabButton = tabFrame and tabFrame:FindFirstChild("BuyTabButton")
	local sellTabButton = tabFrame and tabFrame:FindFirstChild("SellTabButton")

	if modeChanged and buyTabButton and sellTabButton then
		local activeColor = Color3.fromRGB(80, 100, 80); local activeTextColor = Color3.fromRGB(255, 255, 255)
		local inactiveColor = Color3.fromRGB(50, 70, 50); local inactiveTextColor = Color3.fromRGB(200, 200, 200)
		if mode == "Buy" then
			buyTabButton.BackgroundColor3 = activeColor; buyTabButton.TextColor3 = activeTextColor
			sellTabButton.BackgroundColor3 = inactiveColor; sellTabButton.TextColor3 = inactiveTextColor
		elseif mode == "Sell" then
			buyTabButton.BackgroundColor3 = inactiveColor; buyTabButton.TextColor3 = inactiveTextColor
			sellTabButton.BackgroundColor3 = activeColor; sellTabButton.TextColor3 = activeTextColor
		end
	end
	print("ShopUIManager: Refreshing shop item list for mode:", mode)
	ShopUIManager.PopulateShopItems(currentShopMode)
end

-- ���� ������ ��� ä��� �Լ�
function ShopUIManager.PopulateShopItems(mode)
	mode = mode or currentShopMode
	if not shopFrame then 
		ShopUIManager.SetupUIReferences()
		if not shopFrame then
			warn("ShopUIManager.PopulateShopItems: ShopFrame is nil.")
			return
		end
	end
	local itemList = shopFrame:FindFirstChild("ItemList")
	if not itemList then return end
	local shopListLayout = itemList:FindFirstChildOfClass("UIListLayout")
	for _, item in ipairs(itemList:GetChildren()) do if item:IsA("Frame") then item:Destroy() end end

	local itemsToShow = {}
	if mode == "Buy" then
		itemsToShow = { 1, 2, 3, 4, 102, 103, 104, 105, 202, 203, 205, 206, 301, 302, 303, 304, 305, 1001, 1002, 1003, 1005, 1006,
			1101, 1102, 1103}
		print("ShopUIManager: Populating shop for BUY mode. Items:", itemsToShow)
	elseif mode == "Sell" then
		local success, inventoryData = pcall(getPlayerInventoryFunction.InvokeServer, getPlayerInventoryFunction)
		if success and typeof(inventoryData) == "table" then itemsToShow = inventoryData; print("ShopUIManager: Populating shop for SELL mode. Inventory:", itemsToShow)
		else warn("ShopUIManager: Failed to get player inventory for sell mode:", inventoryData); itemsToShow = {} end
	else warn("ShopUIManager: Invalid shop mode for population:", mode); return end

	if not itemsToShow or #itemsToShow == 0 then print("ShopUIManager: ǥ���� �������� �����ϴ�. Mode:", mode); itemList.CanvasSize = UDim2.new(0, 0, 0, 0); return end
	local itemHeight = 50; local imageSize = itemHeight - 10; local padding = shopListLayout and shopListLayout.Padding.Offset or 5; local numItems = 0;
	for i, itemData in ipairs(itemsToShow) do
		local itemId, quantity; if mode == "Buy" then itemId = itemData; quantity = 1 else itemId = itemData.itemId; quantity = itemData.quantity end

		local itemInfo = ItemDatabase and ItemDatabase.Items[itemId] or nil
		if itemInfo then
			local shouldDisplay = true; if mode == "Sell" and (not itemInfo.SellPrice or itemInfo.SellPrice <= 0) then shouldDisplay = false end
			if shouldDisplay then
				numItems = numItems + 1; local itemFrame = Instance.new("Frame"); itemFrame.Name = "Item_" .. itemId; itemFrame.Parent = itemList; itemFrame.Size = UDim2.new(1, -10, 0, itemHeight); itemFrame.BackgroundColor3 = Color3.fromRGB(50, 70, 50); itemFrame.BorderSizePixel = 0; itemFrame.LayoutOrder = i; Instance.new("UICorner", itemFrame).CornerRadius = UDim.new(0, 4);
				local itemImage = Instance.new("ImageLabel"); itemImage.Name = "ItemImage"; itemImage.Size = UDim2.new(0, imageSize, 0, imageSize); itemImage.Position = UDim2.new(0, 5, 0.5, 0); itemImage.AnchorPoint = Vector2.new(0, 0.5); itemImage.BackgroundTransparency = 1; itemImage.ScaleType = Enum.ScaleType.Fit; itemImage.ZIndex = 2; itemImage.Parent = itemFrame;
				if itemInfo.ImageId and itemInfo.ImageId ~= "" and not itemInfo.ImageId:match("PLACEHOLDER") then itemImage.Image = itemInfo.ImageId else local encodedName = HttpService:UrlEncode(itemInfo.Name); itemImage.Image = string.format("https://placehold.co/%dx%d/cccccc/333333?text=%s", imageSize, imageSize, encodedName) end; Instance.new("UICorner", itemImage).CornerRadius = UDim.new(0, 4);

				local rating = itemInfo.Rating or "Common"
				local ratingColor = RATING_COLORS[rating] or DEFAULT_RATING_COLOR

				local tooltipTriggerButton = Instance.new("TextButton"); tooltipTriggerButton.Name = "TooltipTrigger"; tooltipTriggerButton.Size = UDim2.new(0.7, 0, 1, 0); tooltipTriggerButton.Position = UDim2.new(0, 0, 0, 0); tooltipTriggerButton.BackgroundTransparency = 1; tooltipTriggerButton.Text = ""; tooltipTriggerButton.ZIndex = 3; tooltipTriggerButton.Parent = itemFrame;
				tooltipTriggerButton.MouseButton1Click:Connect(function() if TooltipManager and TooltipManager.ShowTooltip then local mousePos = UserInputService:GetMouseLocation(); TooltipManager.ShowTooltip(itemInfo, false, mousePos, mode) else warn("ShopUIManager: TooltipManager �Ǵ� ShowTooltip �Լ��� ã�� �� �����ϴ�.") end end);

				local infoText = itemInfo.Name; if mode == "Buy" then infoText = string.format("%s - ����: %d G", itemInfo.Name, itemInfo.Price or 0) elseif mode == "Sell" then infoText = string.format("%s (x%d) - �ǸŰ�: %d G", itemInfo.Name, quantity or 0, itemInfo.SellPrice or 0) end
				local infoLabel = GuiUtils and GuiUtils.CreateTextLabel(itemFrame, "InfoLabel", UDim2.new(0, imageSize + 10, 0.5, 0), UDim2.new(0.55, 0, 0.8, 0), infoText, Vector2.new(0, 0.5), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 14) or nil;
				if infoLabel then
					infoLabel.TextColor3 = ratingColor
					infoLabel.ZIndex = 2
				end;

				if mode == "Buy" then
					local buyButton = Instance.new("TextButton"); buyButton.Name = "BuyButton"; buyButton.Parent = itemFrame; buyButton.AnchorPoint = Vector2.new(1, 0.5); buyButton.Position = UDim2.new(0.95, 0, 0.5, 0); buyButton.Size = UDim2.new(0.25, 0, 0.8, 0); buyButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100); buyButton.TextColor3 = Color3.fromRGB(0, 50, 0); buyButton.Font = Enum.Font.SourceSansBold; buyButton.TextScaled = true; buyButton.Text = "����"; buyButton.ZIndex = 3; Instance.new("UICorner", buyButton).CornerRadius = UDim.new(0, 4);
					buyButton.MouseButton1Click:Connect(function() print("ShopUIManager: ���� ��ư Ŭ���� - ItemID:", itemId); if purchaseItemEvent then purchaseItemEvent:FireServer(itemId) else warn("ShopUIManager: PurchaseItemEvent not found!") end; if TooltipManager and TooltipManager.HideTooltip then TooltipManager.HideTooltip() end end)
				elseif mode == "Sell" then
					local sellButton = Instance.new("TextButton"); sellButton.Name = "SellButton"; sellButton.Parent = itemFrame; sellButton.AnchorPoint = Vector2.new(1, 0.5); sellButton.Position = UDim2.new(0.95, 0, 0.5, 0); sellButton.Size = UDim2.new(0.25, 0, 0.8, 0); sellButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100); sellButton.TextColor3 = Color3.fromRGB(50, 0, 0); sellButton.Font = Enum.Font.SourceSansBold; sellButton.TextScaled = true; sellButton.Text = "�Ǹ�"; sellButton.ZIndex = 3; Instance.new("UICorner", sellButton).CornerRadius = UDim.new(0, 4);
					sellButton.MouseButton1Click:Connect(function() print("ShopUIManager: �Ǹ� ��ư Ŭ���� - ItemID:", itemId); if sellItemEvent then sellItemEvent:FireServer(itemId, 1) else warn("ShopUIManager: SellItemEvent not found!") end; if TooltipManager and TooltipManager.HideTooltip then TooltipManager.HideTooltip() end end)
				end
			end
		else
			warn("ShopUIManager: ItemDatabase���� ID�� " .. tostring(itemId) .. "�� ������ ������ ã�� �� �����ϴ�. (�κ��丮 ������ ���� ���ɼ�)")
		end
	end
	local totalContentHeight = (itemHeight * numItems) + (padding * math.max(0, numItems - 1)) + (padding * 2); itemList.CanvasSize = UDim2.new(0, 0, 0, totalContentHeight); print("ShopUIManager: ���� ��� ä��� �Ϸ�. Mode:", mode, "CanvasSize:", itemList.CanvasSize)
end

-- ##### [��� ����] ShowShop �Լ����� CoreUIManager.OpenMainUIPopup ��� #####
function ShopUIManager.ShowShop(show)
	if not CoreUIManager then 
		warn("ShopUIManager.ShowShop: CoreUIManager module not loaded!")
		if shopFrame then shopFrame.Visible = show end -- Fallback
		return 
	end
	if not shopFrame then 
		ShopUIManager.SetupUIReferences()
		if not shopFrame then
			warn("ShopUIManager.ShowShop: ShopFrame is still nil after setup.")
			return
		end
	end

	if show then 
		CoreUIManager.OpenMainUIPopup("ShopFrame") -- �ٸ� �ֿ� �˾� �ݰ� ���� ����
		ShopUIManager.SetShopMode("Buy") 
	else 
		CoreUIManager.ShowFrame("ShopFrame", false) -- �ܼ��� ���� �ݱ�
		if TooltipManager and TooltipManager.HideTooltip then TooltipManager.HideTooltip() end 
	end
	print("ShopUIManager: ShopFrame visibility process for", show)
end
-- #####################################################################

-- ���� â�� ���̰� �Ǹ� ����� �� ��� ���ΰ�ħ
function ShopUIManager.RefreshShopListIfVisible()
	if not shopFrame then return end -- shopFrame�� ������ �ƹ��͵� �� ��

	if shopFrame.Visible and currentShopMode == "Sell" then
		print("ShopUIManager: Refreshing shop list because it's visible and in Sell mode.")
		ShopUIManager.PopulateShopItems("Sell")
	end
end

return ShopUIManager