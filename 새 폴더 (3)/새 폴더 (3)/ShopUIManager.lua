--[[
  ShopUIManager (ModuleScript)
  상점 UI 관련 기능 (목록 표시, 모드 변경 등) 담당
  *** [수정] 판매 목록 생성 시 ItemDatabase에 없는 아이템 건너뛰기 ***
  *** [수정] 등급 시스템 적용: 상점 목록 아이템 이름에 등급별 색상 적용 ***
  *** [기능 수정] UI 창 겹침 방지를 위해 CoreUIManager.OpenMainUIPopup 사용 ***
]]

local ShopUIManager = {}

-- 필요한 서비스 및 모듈 로드
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService") -- URL 인코딩 위해 추가
local UserInputService = game:GetService("UserInputService") -- 마우스 위치 감지 위해 추가

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainGui = playerGui:WaitForChild("MainGui") -- mainGui 참조

local ModuleManager
local ItemDatabase
local TooltipManager
local GuiUtils
local getPlayerInventoryFunction
local purchaseItemEvent
local sellItemEvent
local CoreUIManager -- CoreUIManager 참조 선언

local RATING_COLORS = {
	["Common"] = Color3.fromRGB(180, 180, 180),
	["Uncommon"] = Color3.fromRGB(100, 200, 100),
	["Rare"] = Color3.fromRGB(100, 150, 255),
	["Epic"] = Color3.fromRGB(180, 100, 220),
	["Legendary"] = Color3.fromRGB(255, 165, 0),
}
local DEFAULT_RATING_COLOR = RATING_COLORS["Common"]

local currentShopMode = "Buy"
local shopFrame = nil -- shopFrame 참조를 모듈 스코프로 이동

-- 모듈 초기화 함수
function ShopUIManager.Init()
	ModuleManager = require(ReplicatedStorage.Modules:WaitForChild("ModuleManager"))
	ItemDatabase = ModuleManager:GetModule("ItemDatabase")
	TooltipManager = ModuleManager:GetModule("TooltipManager")
	GuiUtils = ModuleManager:GetModule("GuiUtils")
	CoreUIManager = ModuleManager:GetModule("CoreUIManager") -- CoreUIManager 초기화
	getPlayerInventoryFunction = ReplicatedStorage:WaitForChild("GetPlayerInventoryFunction")
	purchaseItemEvent = ReplicatedStorage:WaitForChild("PurchaseItemEvent")
	sellItemEvent = ReplicatedStorage:WaitForChild("SellItemEvent")

	ShopUIManager.SetupUIReferences() -- UI 참조 설정
	print("ShopUIManager: Initialized and modules loaded.")
end

-- ##### [기능 추가] UI 프레임 참조를 위한 함수 #####
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

-- 상점 모드 설정 함수
function ShopUIManager.SetShopMode(mode)
	if mode ~= "Buy" and mode ~= "Sell" then warn("ShopUIManager.SetShopMode: Invalid mode specified:", mode); return end

	if not shopFrame then -- shopFrame이 nil이면 참조 시도
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

-- 상점 아이템 목록 채우기 함수
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

	if not itemsToShow or #itemsToShow == 0 then print("ShopUIManager: 표시할 아이템이 없습니다. Mode:", mode); itemList.CanvasSize = UDim2.new(0, 0, 0, 0); return end
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
				tooltipTriggerButton.MouseButton1Click:Connect(function() if TooltipManager and TooltipManager.ShowTooltip then local mousePos = UserInputService:GetMouseLocation(); TooltipManager.ShowTooltip(itemInfo, false, mousePos, mode) else warn("ShopUIManager: TooltipManager 또는 ShowTooltip 함수를 찾을 수 없습니다.") end end);

				local infoText = itemInfo.Name; if mode == "Buy" then infoText = string.format("%s - 가격: %d G", itemInfo.Name, itemInfo.Price or 0) elseif mode == "Sell" then infoText = string.format("%s (x%d) - 판매가: %d G", itemInfo.Name, quantity or 0, itemInfo.SellPrice or 0) end
				local infoLabel = GuiUtils and GuiUtils.CreateTextLabel(itemFrame, "InfoLabel", UDim2.new(0, imageSize + 10, 0.5, 0), UDim2.new(0.55, 0, 0.8, 0), infoText, Vector2.new(0, 0.5), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 14) or nil;
				if infoLabel then
					infoLabel.TextColor3 = ratingColor
					infoLabel.ZIndex = 2
				end;

				if mode == "Buy" then
					local buyButton = Instance.new("TextButton"); buyButton.Name = "BuyButton"; buyButton.Parent = itemFrame; buyButton.AnchorPoint = Vector2.new(1, 0.5); buyButton.Position = UDim2.new(0.95, 0, 0.5, 0); buyButton.Size = UDim2.new(0.25, 0, 0.8, 0); buyButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100); buyButton.TextColor3 = Color3.fromRGB(0, 50, 0); buyButton.Font = Enum.Font.SourceSansBold; buyButton.TextScaled = true; buyButton.Text = "구매"; buyButton.ZIndex = 3; Instance.new("UICorner", buyButton).CornerRadius = UDim.new(0, 4);
					buyButton.MouseButton1Click:Connect(function() print("ShopUIManager: 구매 버튼 클릭됨 - ItemID:", itemId); if purchaseItemEvent then purchaseItemEvent:FireServer(itemId) else warn("ShopUIManager: PurchaseItemEvent not found!") end; if TooltipManager and TooltipManager.HideTooltip then TooltipManager.HideTooltip() end end)
				elseif mode == "Sell" then
					local sellButton = Instance.new("TextButton"); sellButton.Name = "SellButton"; sellButton.Parent = itemFrame; sellButton.AnchorPoint = Vector2.new(1, 0.5); sellButton.Position = UDim2.new(0.95, 0, 0.5, 0); sellButton.Size = UDim2.new(0.25, 0, 0.8, 0); sellButton.BackgroundColor3 = Color3.fromRGB(200, 100, 100); sellButton.TextColor3 = Color3.fromRGB(50, 0, 0); sellButton.Font = Enum.Font.SourceSansBold; sellButton.TextScaled = true; sellButton.Text = "판매"; sellButton.ZIndex = 3; Instance.new("UICorner", sellButton).CornerRadius = UDim.new(0, 4);
					sellButton.MouseButton1Click:Connect(function() print("ShopUIManager: 판매 버튼 클릭됨 - ItemID:", itemId); if sellItemEvent then sellItemEvent:FireServer(itemId, 1) else warn("ShopUIManager: SellItemEvent not found!") end; if TooltipManager and TooltipManager.HideTooltip then TooltipManager.HideTooltip() end end)
				end
			end
		else
			warn("ShopUIManager: ItemDatabase에서 ID가 " .. tostring(itemId) .. "인 아이템 정보를 찾을 수 없습니다. (인벤토리 데이터 오류 가능성)")
		end
	end
	local totalContentHeight = (itemHeight * numItems) + (padding * math.max(0, numItems - 1)) + (padding * 2); itemList.CanvasSize = UDim2.new(0, 0, 0, totalContentHeight); print("ShopUIManager: 상점 목록 채우기 완료. Mode:", mode, "CanvasSize:", itemList.CanvasSize)
end

-- ##### [기능 수정] ShowShop 함수에서 CoreUIManager.OpenMainUIPopup 사용 #####
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
		CoreUIManager.OpenMainUIPopup("ShopFrame") -- 다른 주요 팝업 닫고 상점 열기
		ShopUIManager.SetShopMode("Buy") 
	else 
		CoreUIManager.ShowFrame("ShopFrame", false) -- 단순히 상점 닫기
		if TooltipManager and TooltipManager.HideTooltip then TooltipManager.HideTooltip() end 
	end
	print("ShopUIManager: ShopFrame visibility process for", show)
end
-- #####################################################################

-- 상점 창이 보이고 판매 모드일 때 목록 새로고침
function ShopUIManager.RefreshShopListIfVisible()
	if not shopFrame then return end -- shopFrame이 없으면 아무것도 안 함

	if shopFrame.Visible and currentShopMode == "Sell" then
		print("ShopUIManager: Refreshing shop list because it's visible and in Sell mode.")
		ShopUIManager.PopulateShopItems("Sell")
	end
end

return ShopUIManager