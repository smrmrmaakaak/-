-- InventoryUIManager.lua (수정: ShowTooltipForEquippedSlot에서 isEquipped 명시적 전달, UI 창 겹침 방지 로직 적용)

local InventoryUIManager = {}

-- 필요한 서비스 및 모듈 로드
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService") -- URL 인코딩 위해 추가
local UserInputService = game:GetService("UserInputService") -- 마우스 위치 감지 위해 추가

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainGui = playerGui:WaitForChild("MainGui") -- mainGui 참조 수정 (모듈 스코프에서 직접 할당)

local ModuleManager
local ItemDatabase
local TooltipManager
local GuiUtils
local CoreUIManager -- CoreUIManager 참조 선언
local getPlayerInventoryFunction
local getEquippedItemsFunction

-- 등급별 색상 정의
local RATING_COLORS = {
	["Common"] = Color3.fromRGB(180, 180, 180),
	["Uncommon"] = Color3.fromRGB(100, 200, 100),
	["Rare"] = Color3.fromRGB(100, 150, 255),
	["Epic"] = Color3.fromRGB(180, 100, 220),
	["Legendary"] = Color3.fromRGB(255, 165, 0),
}
local DEFAULT_RATING_COLOR = RATING_COLORS["Common"]

-- UI 프레임 참조 변수 (Init 후 SetupUIReferences에서 설정)
local inventoryFrame = nil
local equipmentFrame = nil

-- 모듈 초기화 함수
function InventoryUIManager.Init()
	ModuleManager = require(ReplicatedStorage.Modules:WaitForChild("ModuleManager"))
	ItemDatabase = ModuleManager:GetModule("ItemDatabase")
	TooltipManager = ModuleManager:GetModule("TooltipManager")
	GuiUtils = ModuleManager:GetModule("GuiUtils")
	CoreUIManager = ModuleManager:GetModule("CoreUIManager") -- CoreUIManager 초기화
	getPlayerInventoryFunction = ReplicatedStorage:WaitForChild("GetPlayerInventoryFunction")
	getEquippedItemsFunction = ReplicatedStorage:WaitForChild("GetEquippedItems")

	-- UI 프레임 참조 설정
	InventoryUIManager.SetupUIReferences()
	print("InventoryUIManager: Initialized and modules loaded.")
end

-- ##### [기능 추가] UI 프레임 참조를 위한 함수 #####
function InventoryUIManager.SetupUIReferences()
	if not mainGui then -- mainGui가 nil이면 다시 시도
		local p = Players.LocalPlayer
		local pg = p and p:WaitForChild("PlayerGui")
		mainGui = pg and pg:FindFirstChild("MainGui")
		if not mainGui then
			warn("InventoryUIManager.SetupUIReferences: MainGui not found even after retry!")
			return
		end
	end
	local backgroundFrame = mainGui:FindFirstChild("BackgroundFrame")
	if backgroundFrame then
		inventoryFrame = backgroundFrame:FindFirstChild("InventoryFrame")
		equipmentFrame = backgroundFrame:FindFirstChild("EquipmentFrame")
		if not inventoryFrame then warn("InventoryUIManager.SetupUIReferences: InventoryFrame not found!") end
		if not equipmentFrame then warn("InventoryUIManager.SetupUIReferences: EquipmentFrame not found!") end
	else
		warn("InventoryUIManager.SetupUIReferences: BackgroundFrame not found!")
	end
end
-- #################################################


-- 인벤토리 아이템 목록 채우기 함수
function InventoryUIManager.PopulateInventoryItems(inventoryData, equippedItems)
	-- inventoryFrame 참조 확인 및 설정
	if not inventoryFrame then 
		InventoryUIManager.SetupUIReferences()
		if not inventoryFrame then
			warn("InventoryUIManager.PopulateInventoryItems: InventoryFrame is still nil after setup.")
			return
		end
	end
	local inventoryList = inventoryFrame:FindFirstChild("InventoryList")
	if not inventoryList then return end

	for _, item in ipairs(inventoryList:GetChildren()) do
		if item:IsA("ImageButton") or item:IsA("Frame") or item:IsA("TextLabel") then
			if not item:IsA("UIGridLayout") then
				item:Destroy()
			end
		end
	end

	print("InventoryUIManager: 인벤토리 목록 채우기 시작. 데이터:", inventoryData)

	if not inventoryData or #inventoryData == 0 then
		print("InventoryUIManager: 인벤토리가 비어있습니다.")
		if GuiUtils and GuiUtils.CreateTextLabel then
			local emptyLabel = GuiUtils.CreateTextLabel(inventoryList, "EmptyLabel",
				UDim2.new(0.5, 0, 0.1, 0), UDim2.new(0.9, 0, 0.1, 0), "인벤토리가 비어 있습니다.",
				Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 16)
			if emptyLabel then emptyLabel.TextColor3 = Color3.fromRGB(200, 200, 200) end
		end
		inventoryList.CanvasSize = UDim2.new(0,0,0,0)
		return
	end

	for i, itemSlotData in ipairs(inventoryData) do
		local itemId = itemSlotData.itemId
		local quantity = itemSlotData.quantity
		local itemInfo = ItemDatabase and ItemDatabase.GetItemInfo(itemId) or nil

		if itemInfo then
			local itemSlot = Instance.new("ImageButton")
			itemSlot.Name = tostring(itemId) .. "_" .. i
			itemSlot.Parent = inventoryList
			itemSlot.BackgroundColor3 = Color3.fromRGB(90, 70, 70)
			itemSlot.BorderSizePixel = 0
			itemSlot.LayoutOrder = i
			Instance.new("UICorner", itemSlot).CornerRadius = UDim.new(0, 4)

			if itemInfo.ImageId and itemInfo.ImageId ~= "" then
				itemSlot.Image = itemInfo.ImageId
			else
				local encodedName = HttpService:UrlEncode(itemInfo.Name)
				itemSlot.Image = string.format("https://placehold.co/64x64/cccccc/333333?text=%s", encodedName)
			end
			itemSlot.ScaleType = Enum.ScaleType.Fit

			if quantity > 1 and itemInfo.Stackable then
				if GuiUtils and GuiUtils.CreateTextLabel then
					local quantityLabel = GuiUtils.CreateTextLabel(itemSlot, "QuantityLabel",
						UDim2.new(1, -2, 1, -2), UDim2.new(0.4, 0, 0.3, 0), tostring(quantity),
						Vector2.new(1, 1), Enum.TextXAlignment.Right, Enum.TextYAlignment.Bottom, 12)
					if quantityLabel then
						quantityLabel.TextColor3 = Color3.fromRGB(255, 255, 180)
						quantityLabel.TextStrokeTransparency = 0.5
						quantityLabel.ZIndex = itemSlot.ZIndex + 1
						quantityLabel.TextScaled = false
						quantityLabel.TextSize = 12
					end
				end
			end

			if itemSlotData.enhancementLevel and itemSlotData.enhancementLevel > 0 then
				if GuiUtils and GuiUtils.CreateTextLabel then
					local levelLabel = GuiUtils.CreateTextLabel(itemSlot, "LevelLabel",
						UDim2.new(1, -2, 0, 2), UDim2.new(0.3, 10, 0.2, 0),
						"+" .. itemSlotData.enhancementLevel,
						Vector2.new(1, 0), Enum.TextXAlignment.Right, Enum.TextYAlignment.Top, 10, Color3.fromRGB(255, 230, 150))
					if levelLabel then
						levelLabel.TextStrokeTransparency = 0.5
						levelLabel.ZIndex = itemSlot.ZIndex + 2
					end
				end
			end

			local rating = itemInfo.Rating or "Common"
			local ratingColor = RATING_COLORS[rating] or DEFAULT_RATING_COLOR
			local ratingStroke = itemSlot:FindFirstChild("RatingStroke")
			if not ratingStroke then
				ratingStroke = Instance.new("UIStroke")
				ratingStroke.Name = "RatingStroke"
				ratingStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
				ratingStroke.LineJoinMode = Enum.LineJoinMode.Round
				ratingStroke.Thickness = 2
				ratingStroke.Parent = itemSlot
			end
			ratingStroke.Color = ratingColor
			ratingStroke.Transparency = 0

			itemSlot.MouseButton1Click:Connect(function()
				print("InventoryUIManager: 인벤토리 아이템 클릭됨 (툴팁 표시) - ItemID:", itemId, "Name:", itemInfo.Name)
				if TooltipManager and TooltipManager.ShowTooltip then
					local mousePos = UserInputService:GetMouseLocation()
					local tooltipInfo = ItemDatabase.GetItemInfo(itemId)
					if tooltipInfo then
						tooltipInfo.enhancementLevel = itemSlotData.enhancementLevel 
						TooltipManager.ShowTooltip(tooltipInfo, false, mousePos, "Inventory")
					end
				else
					warn("InventoryUIManager: TooltipManager 또는 ShowTooltip 함수를 찾을 수 없습니다.")
				end
			end)

		else
			warn("InventoryUIManager: ItemDatabase에서 ID가 " .. itemId .. "인 아이템 정보를 찾을 수 없습니다.")
		end
	end

	local gridLayout = inventoryList:FindFirstChildOfClass("UIGridLayout")
	if gridLayout then
		local numActualItems = 0
		for _, child in ipairs(inventoryList:GetChildren()) do
			if child:IsA("ImageButton") or child:IsA("Frame") then
				if not child:IsA("UIGridLayout") then
					numActualItems = numActualItems + 1
				end
			end
		end
		local itemsPerRow = math.floor(inventoryList.AbsoluteSize.X / (gridLayout.CellSize.X.Offset + gridLayout.CellPadding.X.Offset)); itemsPerRow = math.max(1, itemsPerRow)
		local numRows = math.ceil(numActualItems / itemsPerRow); local totalGridHeight = numRows * (gridLayout.CellSize.Y.Offset + gridLayout.CellPadding.Y.Offset) + gridLayout.CellPadding.Y.Offset
		inventoryList.CanvasSize = UDim2.new(0, 0, 0, totalGridHeight)
		print("InventoryUIManager: 인벤토리 목록 CanvasSize 업데이트:", inventoryList.CanvasSize)
	end

	print("InventoryUIManager: 인벤토리 목록 채우기 완료.")
end

function InventoryUIManager.RefreshInventoryDisplay()
	print("InventoryUIManager: Refreshing inventory display...")
	local successInv, inventoryData = pcall(getPlayerInventoryFunction.InvokeServer, getPlayerInventoryFunction)
	local successEqp, equippedItems = pcall(getEquippedItemsFunction.InvokeServer, getEquippedItemsFunction)

	if successInv and successEqp then
		if typeof(inventoryData) == "table" and typeof(equippedItems) == "table" then
			InventoryUIManager.PopulateInventoryItems(inventoryData, equippedItems)
			InventoryUIManager.UpdateEquipmentFrame()
		else
			warn("InventoryUIManager: RefreshInventoryDisplay - 서버로부터 잘못된 데이터 수신:", inventoryData, equippedItems)
			InventoryUIManager.PopulateInventoryItems({}, {})
			InventoryUIManager.UpdateEquipmentFrame()
		end
	else
		warn("InventoryUIManager: RefreshInventoryDisplay - 서버 데이터 요청 실패:", inventoryData, equippedItems)
		InventoryUIManager.PopulateInventoryItems({}, {})
		InventoryUIManager.UpdateEquipmentFrame()
	end
end

-- ##### [기능 수정] ShowInventory 함수에서 CoreUIManager.OpenMainUIPopup 사용 #####
function InventoryUIManager.ShowInventory(show)
	if not inventoryFrame then 
		InventoryUIManager.SetupUIReferences() -- 참조 재설정 시도
		if not inventoryFrame then
			warn("InventoryUIManager.ShowInventory: InventoryFrame is still nil after setup.")
			return
		end
	end

	if not CoreUIManager then
		warn("InventoryUIManager.ShowInventory: CoreUIManager not loaded!")
		if inventoryFrame then inventoryFrame.Visible = show end -- Fallback
		return
	end

	if show then
		CoreUIManager.OpenMainUIPopup("InventoryFrame") -- 다른 주요 팝업 닫고 인벤토리 열기
		InventoryUIManager.RefreshInventoryDisplay()
	else
		CoreUIManager.ShowFrame("InventoryFrame", false) -- 단순히 인벤토리 닫기
		if TooltipManager and TooltipManager.HideTooltip then TooltipManager.HideTooltip() end
	end
	print("InventoryUIManager: InventoryFrame visibility process for", show)
end
-- ######################################################################

function InventoryUIManager.UpdateEquipmentFrame()
	print("InventoryUIManager: Updating Equipment Frame...")
	if not equipmentFrame then
		InventoryUIManager.SetupUIReferences()
		if not equipmentFrame then
			warn("InventoryUIManager.UpdateEquipmentFrame: EquipmentFrame is still nil after setup.")
			return
		end
	end

	local slots = { Weapon = equipmentFrame:FindFirstChild("WeaponSlot"), Armor = equipmentFrame:FindFirstChild("ArmorSlot"), Accessory1 = equipmentFrame:FindFirstChild("AccessorySlot1"), Accessory2 = equipmentFrame:FindFirstChild("AccessorySlot2"), Accessory3 = equipmentFrame:FindFirstChild("AccessorySlot3") }
	for slotName, slotButton in pairs(slots) do if not slotButton then warn("InventoryUIManager: Equipment slot UI element '" .. slotName .. "' not found!"); return end end

	local success, equippedItems = pcall(getEquippedItemsFunction.InvokeServer, getEquippedItemsFunction)
	if not success or not equippedItems then warn("InventoryUIManager: Failed to get equipped items from server:", equippedItems); equippedItems = {} end

	for slotName, slotButton in pairs(slots) do
		local itemData = equippedItems[slotName]
		local itemId = itemData and itemData.itemId
		local ratingStroke = slotButton:FindFirstChild("RatingStroke")
		if not ratingStroke then ratingStroke = Instance.new("UIStroke"); ratingStroke.Name = "RatingStroke"; ratingStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; ratingStroke.LineJoinMode = Enum.LineJoinMode.Round; ratingStroke.Thickness = 2; ratingStroke.Parent = slotButton end
		ratingStroke.Transparency = 1
		local levelLabel = slotButton:FindFirstChild("LevelLabel")
		if not levelLabel then if GuiUtils and GuiUtils.CreateTextLabel then levelLabel = GuiUtils.CreateTextLabel(slotButton, "LevelLabel", UDim2.new(1,-2,0,2), UDim2.new(0.3,10,0.2,0),"",Vector2.new(1,0),Enum.TextXAlignment.Right,Enum.TextYAlignment.Top,10,Color3.fromRGB(255,230,150)); if levelLabel then levelLabel.TextStrokeTransparency=0.5; levelLabel.ZIndex=slotButton.ZIndex+2 end end end


		if itemId then
			local itemInfo = ItemDatabase and ItemDatabase.GetItemInfo(itemId) or nil
			if itemInfo then
				if itemInfo.ImageId and itemInfo.ImageId ~= "" then slotButton.Image = itemInfo.ImageId else local encodedName = HttpService:UrlEncode(itemInfo.Name); slotButton.Image = string.format("https://placehold.co/64x64/90EE90/333333?text=%s", encodedName) end
				local rating = itemInfo.Rating or "Common"; local ratingColor = RATING_COLORS[rating] or DEFAULT_RATING_COLOR; ratingStroke.Color = ratingColor; ratingStroke.Transparency = 0
				if levelLabel then local currentLevel = itemData.enhancementLevel or 0; if currentLevel > 0 then levelLabel.Text = "+" .. currentLevel; levelLabel.Visible = true else levelLabel.Visible = false end end
			else 
				warn("InventoryUIManager: Item info not found for equipped item ID:", itemId, "in slot", slotName)
				slotButton.Image = ""
				if levelLabel then levelLabel.Visible = false end 
			end
		else 
			slotButton.Image = ""
			if levelLabel then levelLabel.Visible = false end 
		end
	end
	print("InventoryUIManager: Equipment Frame Updated.")
end

-- ##### [기능 수정] ShowEquipment 함수에서 CoreUIManager.OpenMainUIPopup 사용 #####
function InventoryUIManager.ShowEquipment(show)
	print("InventoryUIManager: ShowEquipment called with", show)
	if not equipmentFrame then
		InventoryUIManager.SetupUIReferences()
		if not equipmentFrame then
			warn("InventoryUIManager.ShowEquipment: EquipmentFrame is still nil after setup.")
			return
		end
	end

	if not CoreUIManager then
		warn("InventoryUIManager.ShowEquipment: CoreUIManager not loaded!")
		if equipmentFrame then equipmentFrame.Visible = show end -- Fallback
		return
	end

	if show then 
		CoreUIManager.OpenMainUIPopup("EquipmentFrame") -- 다른 주요 팝업 닫고 장비창 열기
		InventoryUIManager.UpdateEquipmentFrame() 
	else 
		CoreUIManager.ShowFrame("EquipmentFrame", false) -- 단순히 장비창 닫기
		if TooltipManager and TooltipManager.HideTooltip then TooltipManager.HideTooltip() end 
	end
end
-- ########################################################################

function InventoryUIManager.ShowTooltipForEquippedSlot(slotName, position)
	print("InventoryUIManager: Requesting tooltip for equipped slot:", slotName)
	if not slotName then warn("InventoryUIManager.ShowTooltipForEquippedSlot: slotName is nil"); return end

	local success, equippedItems = pcall(getEquippedItemsFunction.InvokeServer, getEquippedItemsFunction)
	if not success or not equippedItems then warn("InventoryUIManager: Failed to get equipped items from server:", equippedItems); return end

	local itemData = equippedItems[slotName] 
	local itemId = itemData and itemData.itemId

	if itemId then
		local itemInfo = ItemDatabase and ItemDatabase.GetItemInfo(itemId) or nil
		if itemInfo then
			if TooltipManager and TooltipManager.ShowTooltip then
				itemInfo.Slot = slotName 
				itemInfo.enhancementLevel = itemData.enhancementLevel 
				TooltipManager.ShowTooltip(itemInfo, true, position, "EquipmentSlot") 
			else
				warn("InventoryUIManager: TooltipManager 또는 ShowTooltip 함수를 찾을 수 없습니다.")
			end
		else
			warn("InventoryUIManager: Item info not found for equipped item ID:", itemId)
			if TooltipManager and TooltipManager.HideTooltip then TooltipManager.HideTooltip() end
		end
	else
		print("InventoryUIManager: Slot", slotName, "is empty, hiding tooltip.")
		if TooltipManager and TooltipManager.HideTooltip then TooltipManager.HideTooltip() end
	end
end

return InventoryUIManager