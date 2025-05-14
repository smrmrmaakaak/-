-- InventoryUIManager.lua (����: ShowTooltipForEquippedSlot���� isEquipped ����� ����, UI â ��ħ ���� ���� ����, ��� ���� ������ ���� �ݿ�)

local InventoryUIManager = {}

-- �ʿ��� ���� �� ��� �ε�
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService") -- URL ���ڵ� ���� �߰�
local UserInputService = game:GetService("UserInputService") -- ���콺 ��ġ ���� ���� �߰�

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainGui = playerGui:WaitForChild("MainGui")

local ModuleManager
local ItemDatabase
local TooltipManager
local GuiUtils
local CoreUIManager
local getPlayerInventoryFunction
local getEquippedItemsFunction

-- ��޺� ���� ����
local RATING_COLORS = {
	["Common"] = Color3.fromRGB(180, 180, 180),
	["Uncommon"] = Color3.fromRGB(100, 200, 100),
	["Rare"] = Color3.fromRGB(100, 150, 255),
	["Epic"] = Color3.fromRGB(180, 100, 220),
	["Legendary"] = Color3.fromRGB(255, 165, 0),
}
local DEFAULT_RATING_COLOR = RATING_COLORS["Common"]

-- <<< �߰�: �⺻ ���� �̹��� ID �� ���� (EquipmentUIBuilder�� �����ϰ� ���� �Ǵ� ���� ��⿡�� ��������) >>>
-- �߿�: �Ʒ� ID���� ���� ����Ͻô� �̹��� ID�� �ݵ�� ��ü�ؾ� �մϴ�!
local defaultWeaponSlotImage = "rbxassetid://122953630794668"
local defaultArmorSlotImage = "rbxassetid://107446706579540"
local defaultAccessorySlotImage = "rbxassetid://102260956806130"
local defaultSlotTransparency = 0.3 -- �� ������ �� �̹��� ����

-- UI ������ ���� ����
local inventoryFrame = nil
local equipmentFrame = nil

-- ��� �ʱ�ȭ �Լ�
function InventoryUIManager.Init()
	ModuleManager = require(ReplicatedStorage.Modules:WaitForChild("ModuleManager"))
	ItemDatabase = ModuleManager:GetModule("ItemDatabase")
	TooltipManager = ModuleManager:GetModule("TooltipManager")
	GuiUtils = ModuleManager:GetModule("GuiUtils")
	CoreUIManager = ModuleManager:GetModule("CoreUIManager")
	getPlayerInventoryFunction = ReplicatedStorage:WaitForChild("GetPlayerInventoryFunction")
	getEquippedItemsFunction = ReplicatedStorage:WaitForChild("GetEquippedItems")

	InventoryUIManager.SetupUIReferences()
	print("InventoryUIManager: Initialized and modules loaded.")
end

function InventoryUIManager.SetupUIReferences()
	if not mainGui then
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

-- �κ��丮 ������ ��� ä��� �Լ� (���� �ڵ� ����)
function InventoryUIManager.PopulateInventoryItems(inventoryData, equippedItems)
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

	if not inventoryData or #inventoryData == 0 then
		if GuiUtils and GuiUtils.CreateTextLabel then
			local emptyLabel = GuiUtils.CreateTextLabel(inventoryList, "EmptyLabel",
				UDim2.new(0.5, 0, 0.1, 0), UDim2.new(0.9, 0, 0.1, 0), "�κ��丮�� ��� �ֽ��ϴ�.",
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
				if TooltipManager and TooltipManager.ShowTooltip then
					local mousePos = UserInputService:GetMouseLocation()
					local tooltipInfo = ItemDatabase.GetItemInfo(itemId)
					if tooltipInfo then
						tooltipInfo.enhancementLevel = itemSlotData.enhancementLevel
						TooltipManager.ShowTooltip(tooltipInfo, false, mousePos, "Inventory")
					end
				else
					warn("InventoryUIManager: TooltipManager �Ǵ� ShowTooltip �Լ��� ã�� �� �����ϴ�.")
				end
			end)
		else
			warn("InventoryUIManager: ItemDatabase���� ID�� " .. itemId .. "�� ������ ������ ã�� �� �����ϴ�.")
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
	end
end

function InventoryUIManager.RefreshInventoryDisplay()
	print("InventoryUIManager: Refreshing inventory display...")
	local successInv, inventoryData = pcall(getPlayerInventoryFunction.InvokeServer, getPlayerInventoryFunction)
	local successEqp, equippedItems = pcall(getEquippedItemsFunction.InvokeServer, getEquippedItemsFunction)

	if successInv and successEqp then
		if typeof(inventoryData) == "table" and typeof(equippedItems) == "table" then
			InventoryUIManager.PopulateInventoryItems(inventoryData, equippedItems)
			InventoryUIManager.UpdateEquipmentFrame() -- ���â�� �Բ� ������Ʈ
		else
			warn("InventoryUIManager: RefreshInventoryDisplay - �����κ��� �߸��� ������ ����:", inventoryData, equippedItems)
			InventoryUIManager.PopulateInventoryItems({}, {})
			InventoryUIManager.UpdateEquipmentFrame()
		end
	else
		warn("InventoryUIManager: RefreshInventoryDisplay - ���� ������ ��û ����:", inventoryData, equippedItems)
		InventoryUIManager.PopulateInventoryItems({}, {})
		InventoryUIManager.UpdateEquipmentFrame()
	end
end

function InventoryUIManager.ShowInventory(show)
	if not inventoryFrame then
		InventoryUIManager.SetupUIReferences()
		if not inventoryFrame then
			warn("InventoryUIManager.ShowInventory: InventoryFrame is still nil after setup.")
			return
		end
	end
	if not CoreUIManager then
		warn("InventoryUIManager.ShowInventory: CoreUIManager not loaded!")
		if inventoryFrame then inventoryFrame.Visible = show end
		return
	end

	if show then
		CoreUIManager.OpenMainUIPopup("InventoryFrame")
		InventoryUIManager.RefreshInventoryDisplay()
	else
		CoreUIManager.ShowFrame("InventoryFrame", false)
		if TooltipManager and TooltipManager.HideTooltip then TooltipManager.HideTooltip() end
	end
	print("InventoryUIManager: InventoryFrame visibility process for", show)
end

-- ##### UpdateEquipmentFrame �Լ� ���� #####
-- InventoryUIManager.lua ���� ���� �� �Լ��� ã�Ƽ� �Ʒ� �������� �ٲ��ּ���.

-- ##### UpdateEquipmentFrame �Լ� ���� (�׵θ� ����, ������ �и� ����) #####
function InventoryUIManager.UpdateEquipmentFrame()
	print("InventoryUIManager: Updating Equipment Frame (���� ������ ���� - ������ �и� ����)...")
	if not equipmentFrame then
		InventoryUIManager.SetupUIReferences()
		if not equipmentFrame then
			warn("InventoryUIManager.UpdateEquipmentFrame: EquipmentFrame is still nil after setup.")
			return
		end
	end

	local slots = {
		Weapon = equipmentFrame:FindFirstChild("WeaponSlot"),
		Armor = equipmentFrame:FindFirstChild("ArmorSlot"),
		Accessory1 = equipmentFrame:FindFirstChild("AccessorySlot1"),
		Accessory2 = equipmentFrame:FindFirstChild("AccessorySlot2"),
		Accessory3 = equipmentFrame:FindFirstChild("AccessorySlot3")
	}

	for slotName, slotButton in pairs(slots) do
		if not slotButton then
			warn("InventoryUIManager: Equipment slot UI element '" .. slotName .. "' not found!")
			return -- �߿��� UI ��Ұ� ������ �ߴ�
		end
	end

	local success, equippedItems = pcall(getEquippedItemsFunction.InvokeServer, getEquippedItemsFunction)
	if not success or not equippedItems then
		warn("InventoryUIManager: Failed to get equipped items from server:", equippedItems)
		equippedItems = {}
	end

	for slotName, slotButton in pairs(slots) do
		-- ���� ��ư ������ DefaultSlotIcon�� EquippedItemIcon ImageLabel ����
		local defaultIconLabel = slotButton:FindFirstChild("DefaultSlotIcon")
		local equippedItemIconLabel = slotButton:FindFirstChild("EquippedItemIcon")
		local ratingStroke = slotButton:FindFirstChild("RatingStroke") -- UIStroke�� slotButton�� ���� �����
		local levelLabel = slotButton:FindFirstChild("LevelLabel") -- ��ȭ ���� ǥ�ÿ� (Builder���� ����)

		-- �ʼ� UI ��ҵ��� �ִ��� Ȯ��
		if not (defaultIconLabel and equippedItemIconLabel and ratingStroke) then
			warn("InventoryUIManager: Slot '" .. slotName .. "' is missing essential child elements (DefaultSlotIcon, EquippedItemIcon, or RatingStroke)!")
			-- �� ���Կ� ���� ó���� �ǳʶٰ� ���� �������� �Ѿ
		else
			local itemData = equippedItems[slotName]
			local itemId = itemData and itemData.itemId

			-- ��ȭ ���� ���̺� �ʱ�ȭ
			if levelLabel then levelLabel.Visible = false end
			-- ��� �׵θ� �ʱ�ȭ (�⺻ �׵θ��� ImageButton�� BorderSizePixel�� �׻� ����)
			ratingStroke.Transparency = 1 -- ������ ��� �׵θ��� �ϴ� ����

			if itemId then
				local itemInfo = ItemDatabase and ItemDatabase.GetItemInfo(itemId)
				if itemInfo then
					-- ������ ������: �⺻ ������ �����, ������ ������ ������ ǥ��
					defaultIconLabel.Visible = false

					equippedItemIconLabel.Image = itemInfo.ImageId or ""
					equippedItemIconLabel.ImageTransparency = 0 -- �����ϰ�
					equippedItemIconLabel.Visible = true

					-- ������ ��� �׵θ� ǥ��
					local rating = itemInfo.Rating or "Common"
					local ratingColor = RATING_COLORS[rating] or DEFAULT_RATING_COLOR
					ratingStroke.Color = ratingColor
					ratingStroke.Transparency = 0 -- ��� �׵θ� ǥ��

					-- ��ȭ ���� ǥ��
					if levelLabel then
						local currentLevel = itemData.enhancementLevel or 0
						if currentLevel > 0 then
							levelLabel.Text = "+" .. currentLevel
							levelLabel.Visible = true
						end
					end
				else
					-- ������ ������ ������ DB�� ���� ���: �⺻ ������ ǥ�� (���� ��Ȳ)
					warn("InventoryUIManager: Item info not found in DB for equipped item ID:", itemId, "in slot", slotName)
					equippedItemIconLabel.Visible = false
					equippedItemIconLabel.Image = ""
					defaultIconLabel.Visible = true -- �⺻ ������ �ٽ� ǥ��
					-- �⺻ ������ �̹����� �������� ���������Ƿ� ���⼭�� Visible�� ����
				end
			else
				-- ������ �����: ������ ������ ������ �����, �⺻ ������ ǥ��
				equippedItemIconLabel.Visible = false
				equippedItemIconLabel.Image = ""

				defaultIconLabel.Visible = true
				-- �⺻ ������ �̹����� EquipmentUIBuilder���� �̹� ���������Ƿ� ���⼭�� Visible�� ����
				-- �⺻ �������� ImageTransparency�� EquipmentUIBuilder���� ������ ���� ���� (��: �����ϰ� 0)
			end
		end
	end
	print("InventoryUIManager: Equipment Frame Updated (������ �и� �� �׵θ� ���� �����).")
end
-- ####################################

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
		if equipmentFrame then equipmentFrame.Visible = show end
		return
	end

	if show then
		CoreUIManager.OpenMainUIPopup("EquipmentFrame")
		InventoryUIManager.UpdateEquipmentFrame()
	else
		CoreUIManager.ShowFrame("EquipmentFrame", false)
		if TooltipManager and TooltipManager.HideTooltip then TooltipManager.HideTooltip() end
	end
end

function InventoryUIManager.ShowTooltipForEquippedSlot(slotName, position)
	print("InventoryUIManager: Requesting tooltip for equipped slot:", slotName)
	if not slotName then warn("InventoryUIManager.ShowTooltipForEquippedSlot: slotName is nil"); return end

	local success, equippedItems = pcall(getEquippedItemsFunction.InvokeServer, getEquippedItemsFunction)
	if not success or not equippedItems then warn("InventoryUIManager: Failed to get equipped items from server:", equippedItems); return end

	local itemData = equippedItems[slotName]
	local itemId = itemData and itemData.itemId

	if itemId then
		local itemInfo = ItemDatabase and ItemDatabase.GetItemInfo(itemId)
		if itemInfo then
			if TooltipManager and TooltipManager.ShowTooltip then
				itemInfo.Slot = slotName
				itemInfo.enhancementLevel = itemData.enhancementLevel
				TooltipManager.ShowTooltip(itemInfo, true, position, "EquipmentSlot")
			else
				warn("InventoryUIManager: TooltipManager �Ǵ� ShowTooltip �Լ��� ã�� �� �����ϴ�.")
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