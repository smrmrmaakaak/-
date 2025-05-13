-- ReplicatedStorage > Modules > CompanionUIManager.lua
-- *** [��� ����] UI â ��ħ ������ ���� CoreUIManager.OpenMainUIPopup ��� ***

local CompanionUIManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService") 

local modulesFolder = ReplicatedStorage:WaitForChild("Modules")

-- �ʿ��� ��� �ε�
local ModuleManager = require(modulesFolder:WaitForChild("ModuleManager"))
local CoreUIManager -- Init���� �ʱ�ȭ
print("CompanionUIManager: CoreUIManager �ε� �õ�...")
local PlayerData = ModuleManager:GetModule("PlayerData")
print("CompanionUIManager: PlayerData loaded?", PlayerData)
local CompanionDatabase = ModuleManager:GetModule("CompanionDatabase")
print("CompanionUIManager: CompanionDatabase loaded?", CompanionDatabase)
local GuiUtils = ModuleManager:GetModule("GuiUtils")
print("CompanionUIManager: GuiUtils loaded?", GuiUtils)
local TooltipManager -- Init���� �ʱ�ȭ
print("CompanionUIManager: TooltipManager �ε� �õ�...")
local SkillDatabase = ModuleManager:GetModule("SkillDatabase")
print("CompanionUIManager: SkillDatabase loaded?", SkillDatabase)
local ItemDatabase -- Init���� �ε�

-- RemoteEvent/Function ����
local getOwnedCompanionsFunction = ReplicatedStorage:WaitForChild("GetOwnedCompanionsFunction")
local getCurrentPartyFunction = ReplicatedStorage:WaitForChild("GetCurrentPartyFunction")
local setPartyEvent = ReplicatedStorage:WaitForChild("SetPartyEvent")
local companionUpdatedEvent = ReplicatedStorage:WaitForChild("CompanionUpdatedEvent")
local UseItemOnCompanionEvent = ReplicatedStorage:FindFirstChild("UseItemOnCompanionEvent") 
if not UseItemOnCompanionEvent then
	warn("CompanionUIManager: UseItemOnCompanionEvent RemoteEvent�� ã�� �� �����ϴ�! �� ����� ������ ����� �� �����ϴ�.")
end
local getPlayerInventoryFunction 

-- UI ��� ���� ���� (��� �������� �̵� �Ǵ� SetupUIReferences���� �ϰ��ǰ� �Ҵ�)
local companionFrame = nil
local companionListFrame = nil
local companionDetailsFrame = nil
local partyFrame = nil
local partySlotsContainer = nil
local consumableItemListFrame = nil
local itemListScrollContent = nil
local itemButtonTemplate = nil
local cancelItemSelectionButton = nil
local mainGui = nil -- mainGui ���� �߰�

local selectedOwnedCompanionDbId = nil
local ownedCompanionButtons = {}

-- ��� �ʱ�ȭ
function CompanionUIManager.Init()
	CoreUIManager = ModuleManager:GetModule("CoreUIManager") -- CoreUIManager �ʱ�ȭ
	TooltipManager = ModuleManager:GetModule("TooltipManager") -- TooltipManager �ʱ�ȭ
	ItemDatabase = ModuleManager:GetModule("ItemDatabase")
	print("CompanionUIManager: ItemDatabase loaded?", ItemDatabase)
	getPlayerInventoryFunction = ReplicatedStorage:WaitForChild("GetPlayerInventoryFunction") 
	if not getPlayerInventoryFunction then warn("CompanionUIManager: GetPlayerInventoryFunction RemoteFunction�� ã�� �� �����ϴ�!") end
	if not CoreUIManager then warn("CompanionUIManager: CoreUIManager module failed to load!") end
	if not TooltipManager then warn("CompanionUIManager: TooltipManager module failed to load!") end

	print("CompanionUIManager: Initialized (Client-side)")
	if companionUpdatedEvent then
		companionUpdatedEvent.OnClientEvent:Connect(function(updateInfo)
			print("CompanionUIManager: Received CompanionUpdatedEvent. Data:", updateInfo and HttpService:JSONEncode(updateInfo) or "nil")
			local refreshAll = true
			if updateInfo and updateInfo.type then
				if updateInfo.type == "OwnedListUpdated" or updateInfo.type == "FullRefresh" then
					print("CompanionUIManager: Refreshing owned list due to event.")
					CompanionUIManager.PopulateOwnedCompanionList()
					refreshAll = false
				end
				if updateInfo.type == "PartyUpdated" or updateInfo.type == "FullRefresh" then
					print("CompanionUIManager: Refreshing party slots due to event.")
					CompanionUIManager.PopulatePartySlots()
					refreshAll = false
				end
				if updateInfo.type == "CompanionStatUpdated" and updateInfo.companionDbId and updateInfo.companionDbId == selectedOwnedCompanionDbId then
					print("CompanionUIManager: Refreshing details for specific companion due to CompanionStatUpdated event:", selectedOwnedCompanionDbId)
					CompanionUIManager.ShowCompanionDetails(selectedOwnedCompanionDbId) 
					refreshAll = false
				end
			end
			if refreshAll then
				print("CompanionUIManager: Performing full refresh due to event.")
				CompanionUIManager.PopulateOwnedCompanionList()
				CompanionUIManager.PopulatePartySlots()
			end
			if selectedOwnedCompanionDbId and refreshAll then 
				print("CompanionUIManager: Refreshing details for selected companion after full refresh:", selectedOwnedCompanionDbId)
				CompanionUIManager.ShowCompanionDetails(selectedOwnedCompanionDbId)
			end
		end)
	else
		warn("CompanionUIManager: CompanionUpdatedEvent not found!")
	end
	CompanionUIManager.SetupUIReferences() -- Init �������� ȣ���Ͽ� mainGui �� ���� ����
end

-- UI ��� ���� ����
function CompanionUIManager.SetupUIReferences()
	if companionFrame and consumableItemListFrame then print("CompanionUIManager.SetupUIReferences: Already setup."); return true end 
	print("CompanionUIManager.SetupUIReferences: Attempting to setup UI references...")
	local player = Players.LocalPlayer
	local playerGui = player and player:WaitForChild("PlayerGui")
	mainGui = playerGui and playerGui:FindFirstChild("MainGui") -- ���⼭ mainGui �Ҵ�
	if not mainGui then
		warn("CompanionUIManager.SetupUIReferences: MainGui not found!")
		return false
	end
	local backgroundFrame = mainGui:FindFirstChild("BackgroundFrame")
	if not backgroundFrame then
		warn("CompanionUIManager.SetupUIReferences: BackgroundFrame not found!")
		return false
	end
	companionFrame = backgroundFrame:FindFirstChild("CompanionFrame")

	if companionFrame then
		print("CompanionUIManager.SetupUIReferences: Found CompanionFrame.")
		companionListFrame = companionFrame:FindFirstChild("CompanionListFrame")
		companionDetailsFrame = companionFrame:FindFirstChild("CompanionDetailsFrame") 
		partyFrame = companionFrame:FindFirstChild("PartyFrame")
		partySlotsContainer = partyFrame and partyFrame:FindFirstChild("PartySlotsContainer")

		consumableItemListFrame = companionFrame:FindFirstChild("ConsumableItemListFrame")
		if consumableItemListFrame then
			itemListScrollContent = consumableItemListFrame:FindFirstChild("ItemListScrollContent")
			itemButtonTemplate = consumableItemListFrame:FindFirstChild("ItemButtonTemplate") 
			cancelItemSelectionButton = consumableItemListFrame:FindFirstChild("CancelItemSelectionButton")

			if not itemListScrollContent then warn("CompanionUIManager.SetupUIReferences: ItemListScrollContent is nil!") end
			if not itemButtonTemplate then warn("CompanionUIManager.SetupUIReferences: ItemButtonTemplate is nil!") end
			if not cancelItemSelectionButton then warn("CompanionUIManager.SetupUIReferences: CancelItemSelectionButton is nil!") end

			if cancelItemSelectionButton then
				local conn = cancelItemSelectionButton:FindFirstChild("ClickConnection_CancelItem")
				if conn then conn:Destroy() end

				local newConn = cancelItemSelectionButton.MouseButton1Click:Connect(function()
					CompanionUIManager.ShowConsumableItemList(false)
				end)
				local marker = Instance.new("BindableEvent") 
				marker.Name = "ClickConnection_CancelItem"
				marker.Parent = cancelItemSelectionButton
			end
		else
			warn("CompanionUIManager.SetupUIReferences: ConsumableItemListFrame is nil!")
		end

		if not (companionListFrame and companionDetailsFrame and partyFrame and partySlotsContainer and consumableItemListFrame and itemListScrollContent and itemButtonTemplate and cancelItemSelectionButton) then
			warn("CompanionUIManager: CompanionFrame �Ǵ� �� ���� �ֿ� UI ��Ҹ� ã�� �� �����ϴ�! CompanionUIBuilder Ȯ�� �ʿ�.")
			if not companionListFrame then companionFrame = nil end
			if not consumableItemListFrame then consumableItemListFrame = nil end 
			return false
		end
		print("CompanionUIManager: UI References Setup Completed successfully.")
		return true
	else
		warn("CompanionUIManager: CompanionFrame�� ã�� �� �����ϴ�!"); return false
	end
end

function CompanionUIManager.ShowConsumableItemList(show)
	if not consumableItemListFrame then
		warn("CompanionUIManager.ShowConsumableItemList: consumableItemListFrame is nil! Attempting setup...")
		if not CompanionUIManager.SetupUIReferences() or not consumableItemListFrame then
			warn("CompanionUIManager.ShowConsumableItemList: Failed to setup or find consumableItemListFrame after attempt.")
			return
		end
	end

	-- ##### [��� ����] CoreUIManager�� ���� ConsumableItemListFrame ���� �ݱ� #####
	if not CoreUIManager then
		warn("CompanionUIManager.ShowConsumableItemList: CoreUIManager is nil!")
		if consumableItemListFrame then consumableItemListFrame.Visible = show end -- Fallback
		return
	end

	if show then
		CoreUIManager.OpenMainUIPopup("ConsumableItemListFrame") -- �ٸ� �ֿ� �˾� �ݰ� ������ ��� ����
		print("CompanionUIManager: Showing consumable item list for companion.")
		CompanionUIManager.PopulateConsumableItemList()
	else
		CoreUIManager.ShowFrame("ConsumableItemListFrame", false) -- ������ ��� �ݱ�
		print("CompanionUIManager: Hiding consumable item list.")
		if itemListScrollContent then 
			for _, child in ipairs(itemListScrollContent:GetChildren()) do
				if child.Name ~= "UIGridLayout" then 
					child:Destroy()
				end
			end
			consumableItemListFrame.CanvasSize = UDim2.new(0,0,0,80) 
		end
	end
	-- ####################################################################
end

function CompanionUIManager.PopulateConsumableItemList()
	if not itemListScrollContent or not itemButtonTemplate then
		warn("CompanionUIManager.PopulateConsumableItemList: UI elements (itemListScrollContent or itemButtonTemplate) are nil!")
		return
	end
	if not consumableItemListFrame then 
		warn("CompanionUIManager.PopulateConsumableItemList: consumableItemListFrame (parent ScrollingFrame) is nil!")
		return
	end
	if not getPlayerInventoryFunction then
		warn("CompanionUIManager.PopulateConsumableItemList: getPlayerInventoryFunction is nil!")
		return
	end
	if not ItemDatabase then
		warn("CompanionUIManager.PopulateConsumableItemList: ItemDatabase is nil!")
		return
	end

	for _, child in ipairs(itemListScrollContent:GetChildren()) do
		if child.Name ~= "UIGridLayout" then
			child:Destroy()
		end
	end

	local success, inventoryData = pcall(getPlayerInventoryFunction.InvokeServer, getPlayerInventoryFunction)
	if not success or not inventoryData or typeof(inventoryData) ~= "table" then
		warn("CompanionUIManager.PopulateConsumableItemList: Failed to get player inventory or invalid data format -", inventoryData)
		if GuiUtils then GuiUtils.CreateTextLabel(itemListScrollContent, "ErrorLabel", UDim2.new(0.5,0,0.1,0), UDim2.new(0.9,0,0.1,0), "�κ��丮 ������ ������ �� �����ϴ�.", Vector2.new(0.5,0)) end
		consumableItemListFrame.CanvasSize = UDim2.new(0,0,0,80) 
		return
	end

	print("CompanionUIManager: Populating consumable item list. Inventory Data:", HttpService:JSONEncode(inventoryData))
	local itemsAdded = 0
	local gridLayout = itemListScrollContent:FindFirstChildOfClass("UIGridLayout")

	for _, itemSlotData in ipairs(inventoryData) do
		local itemId = itemSlotData.itemId
		local quantity = itemSlotData.quantity
		local itemInfo = ItemDatabase.GetItemInfo(itemId)

		if itemInfo and itemInfo.Type == "Consumable" and itemInfo.Effect and 
			(itemInfo.Effect.Stat == "HP" or itemInfo.Effect.Stat == "MP" or itemInfo.Effect.Stat == "HPMP") then

			itemsAdded = itemsAdded + 1
			local newItemButton = itemButtonTemplate:Clone()
			newItemButton.Name = "Item_" .. tostring(itemId) .. "_" .. itemsAdded 
			newItemButton.Image = itemInfo.ImageId or ""
			newItemButton.Visible = true
			newItemButton.Parent = itemListScrollContent
			if gridLayout then newItemButton.LayoutOrder = itemsAdded end

			local qtyLabel = newItemButton:FindFirstChild("QuantityLabel")
			if qtyLabel then
				qtyLabel.Text = "x" .. tostring(quantity)
			end

			newItemButton.MouseEnter:Connect(function()
				if TooltipManager and TooltipManager.ShowTooltip then
					TooltipManager.ShowTooltip(itemInfo, false, UserInputService:GetMouseLocation(), "CompanionItemSelect")
				end
			end)
			newItemButton.MouseLeave:Connect(function()
				if TooltipManager and TooltipManager.HideTooltip then TooltipManager.HideTooltip() end
			end)

			newItemButton.MouseButton1Click:Connect(function()
				print(string.format("CompanionUIManager: Selected item %s (ID: %d) for companion %s", itemInfo.Name, itemId, selectedOwnedCompanionDbId))
				if UseItemOnCompanionEvent and selectedOwnedCompanionDbId then
					UseItemOnCompanionEvent:FireServer(itemId, selectedOwnedCompanionDbId)
					CompanionUIManager.ShowConsumableItemList(false) 
					if CoreUIManager and CoreUIManager.ShowPopupMessage then CoreUIManager.ShowPopupMessage("�˸�", selectedOwnedCompanionDbId.."���� "..itemInfo.Name.." ��� �õ�...", 2) end
				elseif not selectedOwnedCompanionDbId then
					warn("CompanionUIManager: No companion selected to use item on.")
					if CoreUIManager and CoreUIManager.ShowPopupMessage then CoreUIManager.ShowPopupMessage("�˸�", "�������� ����� ���ᰡ ���õ��� �ʾҽ��ϴ�.") end
				else
					warn("CompanionUIManager: UseItemOnCompanionEvent is nil. Cannot use item.")
				end
			end)
		end
	end

	if itemsAdded == 0 then
		if GuiUtils then GuiUtils.CreateTextLabel(itemListScrollContent, "EmptyLabel", UDim2.new(0.5,0,0.1,0), UDim2.new(0.9,0,0.2,0), "��� ������ �Ҹ�ǰ�� �����ϴ�.", Vector2.new(0.5,0)) end
		consumableItemListFrame.CanvasSize = UDim2.new(0,0,0,80) 
	else
		if gridLayout then
			task.wait() 
			local contentHeight = itemListScrollContent.AbsoluteSize.Y
			local titleHeight = 0
			local cancelBtnHeight = 0
			local titleLabel = consumableItemListFrame:FindFirstChild("ItemListTitle")
			local cancelBtn = consumableItemListFrame:FindFirstChild("CancelItemSelectionButton")
			if titleLabel then titleHeight = titleLabel.AbsoluteSize.Y + 10 end 
			if cancelBtn then cancelBtnHeight = cancelBtn.AbsoluteSize.Y + 10 end 

			consumableItemListFrame.CanvasSize = UDim2.new(0, 0, 0, contentHeight + titleHeight + cancelBtnHeight + 20) 
			print("CompanionUIManager: Consumable item list populated. Items added:", itemsAdded, "Content Height:", contentHeight, "Parent CanvasSize Y:", consumableItemListFrame.CanvasSize.Y.Offset)
		end
	end
end

-- ##### [��� ����] ShowCompanionUI �Լ����� CoreUIManager.OpenMainUIPopup ��� #####
function CompanionUIManager.ShowCompanionUI(show)
	print(string.format("CompanionUIManager.ShowCompanionUI: Called with show = %s", tostring(show)))
	if not companionFrame then
		print("CompanionUIManager.ShowCompanionUI: companionFrame is nil, attempting to setup references.")
		if not CompanionUIManager.SetupUIReferences() or not companionFrame then
			warn("CompanionUIManager.ShowCompanionUI: UI ���� ���� ���� �Ǵ� companionFrame�� ������ nil, ǥ�� �Ұ�"); return
		end
	end
	if not CoreUIManager then
		warn("CompanionUIManager.ShowCompanionUI: CoreUIManager not available!")
		if companionFrame then companionFrame.Visible = show end -- Fallback
		return
	end

	if show then
		print("CompanionUIManager: Showing Companion UI. Populating lists...")
		CoreUIManager.OpenMainUIPopup("CompanionFrame") -- �ٸ� �ֿ� �˾� �ݰ� ���� â ����
		CompanionUIManager.PopulateOwnedCompanionList()
		CompanionUIManager.PopulatePartySlots()
		CompanionUIManager.ShowCompanionDetails(nil) 
		CompanionUIManager.ShowConsumableItemList(false) 
	else
		print("CompanionUIManager: Hiding Companion UI.")
		CoreUIManager.ShowFrame("CompanionFrame", false) -- �ܼ��� ���� â �ݱ�
		selectedOwnedCompanionDbId = nil 
		CompanionUIManager.ShowConsumableItemList(false) 
		if TooltipManager and TooltipManager.HideTooltip then TooltipManager.HideTooltip() end
	end
end
-- ############################################################################

function CompanionUIManager.PopulateOwnedCompanionList()
	print("CompanionUIManager.PopulateOwnedCompanionList: Function called.")
	if not companionListFrame then 
		if not CompanionUIManager.SetupUIReferences() or not companionListFrame then
			warn("CompanionUIManager.PopulateOwnedCompanionList: companionListFrame is nil after setup attempt!"); return
		end
	end
	if not getOwnedCompanionsFunction then warn("CompanionUIManager.PopulateOwnedCompanionList: getOwnedCompanionsFunction is nil!"); return end
	if not GuiUtils then warn("CompanionUIManager.PopulateOwnedCompanionList: GuiUtils is nil!"); return end
	if not CompanionDatabase then warn("CompanionUIManager.PopulateOwnedCompanionList: CompanionDatabase is nil!"); return end

	for _, btn in pairs(ownedCompanionButtons) do if btn and btn.Parent then btn:Destroy() end end
	ownedCompanionButtons = {}
	for _, child in ipairs(companionListFrame:GetChildren()) do
		if child:IsA("TextButton") or child:IsA("ImageButton") then child:Destroy() end
	end
	print("CompanionUIManager.PopulateOwnedCompanionList: Cleared old buttons.")

	local success, ownedCompanionsData = pcall(getOwnedCompanionsFunction.InvokeServer, getOwnedCompanionsFunction)
	if not success then
		warn("CompanionUIManager.PopulateOwnedCompanionList: Failed to get owned companions from server -", ownedCompanionsData); return
	end
	if not ownedCompanionsData or typeof(ownedCompanionsData) ~= "table" then
		warn("CompanionUIManager.PopulateOwnedCompanionList: Invalid data received for owned companions."); return
	end

	print("CompanionUIManager: Populating owned companion list. Data:", HttpService:JSONEncode(ownedCompanionsData))
	local listLayout = companionListFrame:FindFirstChildOfClass("UIListLayout")
	local itemsAdded = 0

	for companionDbId, companionInstanceData in pairs(ownedCompanionsData) do
		print(string.format("CompanionUIManager.PopulateOwnedCompanionList: Processing companionDbId: %s", tostring(companionDbId)))
		local staticInfo = CompanionDatabase.GetCompanionInfo(companionDbId)
		if staticInfo then
			print(string.format("CompanionUIManager.PopulateOwnedCompanionList: Static info found for %s: %s", companionDbId, staticInfo.Name))
			itemsAdded = itemsAdded + 1
			local btn = Instance.new("ImageButton")
			btn.Name = companionDbId
			btn.Size = UDim2.new(0.95, 0, 0, 60) 
			btn.BackgroundColor3 = Color3.fromRGB(70, 80, 90)
			btn.Image = staticInfo.AppearanceId or ""
			btn.ScaleType = Enum.ScaleType.Fit
			btn.ImageRectOffset = Vector2.new(5,5)
			btn.ImageRectSize = Vector2.new(50,50)
			Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 6)

			local nameLabel = GuiUtils.CreateTextLabel(btn, "NameLabel",
				UDim2.new(0.5,0,0.3,0), UDim2.new(0.9,0,0.4,0),
				staticInfo.Name,
				Vector2.new(0.5,0.5), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 16)
			if nameLabel then nameLabel.TextColor3 = Color3.fromRGB(230,230,240); nameLabel.Font = Enum.Font.SourceSansBold end

			local levelLabel = GuiUtils.CreateTextLabel(btn, "LevelLabel",
				UDim2.new(0.5,0,0.7,0), UDim2.new(0.9,0,0.3,0),
				"Lv." .. (companionInstanceData.Level or 1),
				Vector2.new(0.5,0.5), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 12)
			if levelLabel then levelLabel.TextColor3 = Color3.fromRGB(180,180,190) end

			if listLayout then btn.LayoutOrder = itemsAdded end
			btn.Parent = companionListFrame
			ownedCompanionButtons[companionDbId] = btn

			btn.MouseButton1Click:Connect(function()
				print(string.format("CompanionUIManager.PopulateOwnedCompanionList: Button for %s clicked.", companionDbId))
				if selectedOwnedCompanionDbId == companionDbId then
					CompanionUIManager.ShowCompanionDetails(nil)
					btn.BackgroundColor3 = Color3.fromRGB(70, 80, 90)
					selectedOwnedCompanionDbId = nil
				else
					CompanionUIManager.ShowCompanionDetails(companionDbId)
					for id, otherBtn in pairs(ownedCompanionButtons) do
						otherBtn.BackgroundColor3 = (id == companionDbId) and Color3.fromRGB(90, 100, 120) or Color3.fromRGB(70, 80, 90)
					end
					selectedOwnedCompanionDbId = companionDbId 
				end
			end)
		else
			warn(string.format("CompanionUIManager.PopulateOwnedCompanionList: No static info for companionDbId: %s", tostring(companionDbId)))
		end
	end
	if itemsAdded == 0 then
		if GuiUtils and GuiUtils.CreateTextLabel then GuiUtils.CreateTextLabel(companionListFrame, "EmptyMsg", UDim2.new(0.5,0,0.1,0), UDim2.new(0.9,0,0.2,0), "������ ���ᰡ �����ϴ�.", Vector2.new(0.5,0)) end
	end
	if listLayout then
		task.wait() 
		print("CompanionUIManager.PopulateOwnedCompanionList: Updating CanvasSize. AbsoluteContentSize.Y:", listLayout.AbsoluteContentSize.Y)
		companionListFrame.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
	end
	print("CompanionUIManager.PopulateOwnedCompanionList: Finished.")
end

function CompanionUIManager.PopulatePartySlots()
	print("CompanionUIManager.PopulatePartySlots: Function called.")
	if not partySlotsContainer then 
		if not CompanionUIManager.SetupUIReferences() or not partySlotsContainer then
			warn("CompanionUIManager.PopulatePartySlots: partySlotsContainer is nil after setup attempt!"); return
		end
	end
	if not getCurrentPartyFunction then warn("CompanionUIManager.PopulatePartySlots: getCurrentPartyFunction is nil!"); return end
	if not GuiUtils then warn("CompanionUIManager.PopulatePartySlots: GuiUtils is nil!"); return end
	if not CompanionDatabase then warn("CompanionUIManager.PopulatePartySlots: CompanionDatabase is nil!"); return end

	local success, currentPartyData = pcall(getCurrentPartyFunction.InvokeServer, getCurrentPartyFunction)
	if not success then
		warn("CompanionUIManager.PopulatePartySlots: Failed to get current party from server -", currentPartyData); return
	end
	if not currentPartyData or typeof(currentPartyData) ~= "table" then
		warn("CompanionUIManager.PopulatePartySlots: Invalid data received for current party."); return
	end
	print("CompanionUIManager: Populating party slots. Data:", HttpService:JSONEncode(currentPartyData))

	local playerSlotFrame = partySlotsContainer:FindFirstChild("PartySlot_1")
	if playerSlotFrame then
		local nameLabel = playerSlotFrame:FindFirstChild("CompanionNameLabel") 
		local imageLabel = playerSlotFrame:FindFirstChild("SlotPlayerImage")
		if nameLabel then nameLabel.Text = Players.LocalPlayer.Name .. " (�÷��̾�)" end
		if imageLabel then
			local userId = Players.LocalPlayer.UserId
			local thumbType = Enum.ThumbnailType.HeadShot
			local thumbSize = Enum.ThumbnailSize.Size48x48 
			local successThumb, content = pcall(Players.GetUserThumbnailAsync, Players, userId, thumbType, thumbSize)
			if successThumb and content then imageLabel.Image = content else imageLabel.Image = "" end
		end
	else
		warn("CompanionUIManager.PopulatePartySlots: PartySlot_1 (Player slot) not found!")
	end

	for i = 1, 2 do
		local slotFrameName = "PartySlot_" .. (i + 1) 
		local slotFrame = partySlotsContainer:FindFirstChild(slotFrameName)
		local nameLabel = slotFrame and slotFrame:FindFirstChild("CompanionNameLabel")
		local imageLabel = slotFrame and slotFrame:FindFirstChild("SlotPlayerImage")

		if slotFrame and nameLabel and imageLabel then
			print(string.format("CompanionUIManager.PopulatePartySlots: Processing %s", slotFrameName))
			local companionDbId = currentPartyData["Slot" .. i] 
			print(string.format("CompanionUIManager.PopulatePartySlots: Companion ID for Slot%d is %s", i, tostring(companionDbId)))
			if companionDbId then
				local staticInfo = CompanionDatabase.GetCompanionInfo(companionDbId)
				nameLabel.Text = staticInfo and staticInfo.Name or "�� �� ���� ����"
				imageLabel.Image = staticInfo and staticInfo.AppearanceId or ""
				print(string.format("CompanionUIManager.PopulatePartySlots: Slot %d set to %s", i, staticInfo and staticInfo.Name or "Unknown"))
			else
				nameLabel.Text = "(�������)"
				imageLabel.Image = ""
				print(string.format("CompanionUIManager.PopulatePartySlots: Slot %d is empty", i))
			end
		elseif slotFrame then
			warn("CompanionUIManager.PopulatePartySlots: UI elements (CompanionNameLabel or SlotPlayerImage) not found in", slotFrameName)
		else
			warn("CompanionUIManager.PopulatePartySlots: Slot frame not found:", slotFrameName)
		end
	end
	print("CompanionUIManager.PopulatePartySlots: Finished.")
end

function CompanionUIManager.ShowCompanionDetails(companionDbId)
	print(string.format("CompanionUIManager.ShowCompanionDetails: Called with companionDbId = %s (Type: %s)", tostring(companionDbId), typeof(companionDbId)))
	selectedOwnedCompanionDbId = companionDbId

	if not companionDetailsFrame then 
		if not CompanionUIManager.SetupUIReferences() or not companionDetailsFrame then
			warn("CompanionUIManager.ShowCompanionDetails: companionDetailsFrame is nil after setup attempt!"); return
		end
	end
	if not GuiUtils then warn("CompanionUIManager.ShowCompanionDetails: GuiUtils is nil!"); return end
	if not SkillDatabase then warn("CompanionUIManager.ShowCompanionDetails: SkillDatabase is nil! Skill names may not appear."); end
	if not CompanionDatabase then warn("CompanionUIManager.ShowCompanionDetails: CompanionDatabase is nil!"); return end
	if not ItemDatabase then warn("CompanionUIManager.ShowCompanionDetails: ItemDatabase is nil! Cannot implement UseItemOnCompanion yet."); return end

	for _, child in ipairs(companionDetailsFrame:GetChildren()) do
		if child.Name ~= "DetailsListLayout" then 
			child:Destroy()
		else 
			for _, layoutChild in ipairs(child:GetChildren()) do
				layoutChild:Destroy()
			end
		end
	end
	local existingListLayout = companionDetailsFrame:FindFirstChild("DetailsListLayout")
	if existingListLayout then 
		print("CompanionUIManager.ShowCompanionDetails: Removing existing DetailsListLayout as we are manually positioning elements.")
		existingListLayout:Destroy() 
	end

	companionDetailsFrame.CanvasPosition = Vector2.new(0,0)
	print("CompanionUIManager.ShowCompanionDetails: Cleared companionDetailsFrame children and reset CanvasPosition.")

	if not companionDbId then
		print("CompanionUIManager.ShowCompanionDetails: companionDbId is nil. Displaying placeholder.")
		if GuiUtils.CreateTextLabel then
			local placeholder = GuiUtils.CreateTextLabel(companionDetailsFrame, "DetailsPlaceholder", 
				UDim2.new(0.5,0,0.1,0), UDim2.new(0.9,0,0,30), 
				"���Ḧ �����ϼ���", Vector2.new(0.5,0))
			if placeholder then print("CompanionUIManager.ShowCompanionDetails: Placeholder label created.") else warn("CompanionUIManager.ShowCompanionDetails: Failed to create placeholder label.") end
		else
			warn("CompanionUIManager.ShowCompanionDetails: GuiUtils.CreateTextLabel is nil, cannot create placeholder.")
		end
		companionDetailsFrame.CanvasSize = UDim2.new(0,0,0,50)
		print("CompanionUIManager.ShowCompanionDetails: Set CanvasSize for placeholder state.")
		return
	end

	print("CompanionUIManager.ShowCompanionDetails: Attempting to get owned companions data from server...")
	local successOwned, ownedCompanionsData = pcall(getOwnedCompanionsFunction.InvokeServer, getOwnedCompanionsFunction)

	if not successOwned then
		warn("CompanionUIManager.ShowCompanionDetails: Failed to invoke getOwnedCompanionsFunction:", ownedCompanionsData)
	end
	print(string.format("CompanionUIManager.ShowCompanionDetails: getOwnedCompanionsFunction success: %s, Data type: %s", tostring(successOwned), typeof(ownedCompanionsData)))

	if not successOwned or not ownedCompanionsData or typeof(ownedCompanionsData) ~= "table" or not ownedCompanionsData[companionDbId] then
		warn("CompanionUIManager.ShowCompanionDetails: Could not get valid data for companion ID:", companionDbId, ownedCompanionsData)
		if GuiUtils.CreateTextLabel then
			local errPlaceholder = GuiUtils.CreateTextLabel(companionDetailsFrame, "ErrorPlaceholder", 
				UDim2.new(0.5,0,0.1,0), UDim2.new(0.9,0,0,30), 
				"���� ������ �ҷ��� �� �����ϴ�.", Vector2.new(0.5,0))
			if errPlaceholder then print("CompanionUIManager.ShowCompanionDetails: Error placeholder label created.") else warn("CompanionUIManager.ShowCompanionDetails: Failed to create error placeholder label.") end
		else
			warn("CompanionUIManager.ShowCompanionDetails: GuiUtils.CreateTextLabel is nil, cannot create error placeholder.")
		end
		companionDetailsFrame.CanvasSize = UDim2.new(0,0,0,50)
		print("CompanionUIManager.ShowCompanionDetails: Set CanvasSize for error state.")
		return
	end

	local companionInstanceData = ownedCompanionsData[companionDbId]
	local staticInfo = CompanionDatabase.GetCompanionInfo(companionDbId)
	print("CompanionUIManager.ShowCompanionDetails: Fetched instance data:", HttpService:JSONEncode(companionInstanceData))
	print("CompanionUIManager.ShowCompanionDetails: Fetched static info:", HttpService:JSONEncode(staticInfo))

	if not staticInfo then
		warn("CompanionUIManager.ShowCompanionDetails: Static info not found in CompanionDatabase for ID:", companionDbId); return
	end

	local currentYOffset = 10 
	local elementSpacing = 8 
	local order = 1 

	local function addDetailElement(elementType, nameSuffix, textOrImageId, sizeOrNilForText, textSize, isTitle)
		local element = nil
		local actualHeight = 0
		local elementName = nameSuffix .. "_" .. order 

		if elementType == "Text" then
			if not GuiUtils or not GuiUtils.CreateTextLabel then warn("addDetailElement: GuiUtils.CreateTextLabel is nil!"); return nil, 0 end
			textSize = textSize or 14
			local tempLabel = Instance.new("TextLabel")
			tempLabel.Text = textOrImageId
			tempLabel.Font = isTitle and Enum.Font.SourceSansBold or Enum.Font.SourceSans
			tempLabel.TextSize = textSize
			tempLabel.TextWrapped = not isTitle
			tempLabel.Size = UDim2.new(0.9, 0, 0, 1000) 
			tempLabel.Parent = companionDetailsFrame 
			local textBounds = tempLabel.TextBounds
			tempLabel:Destroy()
			actualHeight = math.max(textSize + (isTitle and 10 or 6), textBounds.Y + (isTitle and 4 or 2))
			print(string.format("CompanionUIManager.addDetailElement (Text): Text='%s', TextSize=%d, isTitle=%s, TextBounds.Y=%s, Calculated actualHeight=%d", textOrImageId, textSize, tostring(isTitle), tostring(textBounds.Y), actualHeight))

			element = GuiUtils.CreateTextLabel(companionDetailsFrame, elementName,
				UDim2.new(0.05, 0, 0, currentYOffset),
				UDim2.new(0.9, 0, 0, actualHeight), 
				textOrImageId,
				Vector2.new(0,0), 
				Enum.TextXAlignment.Left)
			if element then
				element.TextSize = textSize
				if isTitle then 
					element.Font = Enum.Font.SourceSansBold
					element.TextColor3 = Color3.fromRGB(220,220,250)
				end
				element.TextWrapped = not isTitle
			end

		elseif elementType == "Image" then
			if not GuiUtils or not GuiUtils.CreateImageLabel then warn("addDetailElement: GuiUtils.CreateImageLabel is nil!"); return nil, 0 end
			element = GuiUtils.CreateImageLabel(companionDetailsFrame, elementName,
				UDim2.new(0.5, 0, 0, currentYOffset), 
				sizeOrNilForText, 
				Vector2.new(0.5,0), 
				textOrImageId)
			if element then
				element.BackgroundColor3 = Color3.fromRGB(60,70,80)
				element.BackgroundTransparency = 0.5
				Instance.new("UICorner", element).CornerRadius = UDim.new(0,4)
				actualHeight = sizeOrNilForText.Y.Offset 
			end
		elseif elementType == "Button" then
			if not GuiUtils or not GuiUtils.CreateButton then warn("addDetailElement: GuiUtils.CreateButton is nil!"); return nil, 0 end
			element = GuiUtils.CreateButton(companionDetailsFrame, elementName,
				UDim2.new(0.5, 0, 0, currentYOffset), 
				sizeOrNilForText, 
				Vector2.new(0.5,0), 
				textOrImageId)
			if element then
				actualHeight = sizeOrNilForText.Y.Offset
			end
		end

		if element then
			print(string.format("CompanionUIManager.addDetailElement: %s '%s' created at Y: %d, Height: %d, Text/Img: %s", elementType, elementName, currentYOffset, actualHeight, tostring(textOrImageId)))
			currentYOffset = currentYOffset + actualHeight + elementSpacing
			order = order + 1
		else
			warn(string.format("CompanionUIManager.addDetailElement: Failed to create %s: %s", elementType, elementName))
		end
		return element
	end

	addDetailElement("Text", "NameLabel", staticInfo.Name .. " (Lv." .. (companionInstanceData.Level or 1) .. ")", nil, 20, true)
	addDetailElement("Image", "CompanionImage", staticInfo.AppearanceId, UDim2.new(0,120,0,120))
	addDetailElement("Text", "RoleLabel", "����: " .. (staticInfo.Role or "�� �� ����"))
	addDetailElement("Text", "RarityLabel", "��͵�: " .. (staticInfo.Rarity or "Common"))
	addDetailElement("Text", "ExpLabel", "����ġ: " .. (companionInstanceData.Exp or 0) .. " / ???")

	if companionInstanceData.Stats then
		addDetailElement("Text", "StatsHeader", "--- ���� ---", nil, 16, true)
		for statName, value in pairs(companionInstanceData.Stats) do
			if statName ~= "CurrentHP" and statName ~= "CurrentMP" then
				addDetailElement("Text", statName.."Label", statName .. ": " .. tostring(value))
			end
		end
		addDetailElement("Text", "CurrentHPLabel", "CurrentHP: " .. tostring(companionInstanceData.Stats.CurrentHP or (staticInfo.BaseStats and staticInfo.BaseStats.MaxHP) or 0) .. " / " .. tostring(companionInstanceData.Stats.MaxHP or 0))
		addDetailElement("Text", "CurrentMPLabel", "CurrentMP: " .. tostring(companionInstanceData.Stats.CurrentMP or (staticInfo.BaseStats and staticInfo.BaseStats.MaxMP) or 0) .. " / " .. tostring(companionInstanceData.Stats.MaxMP or 0))
	else
		warn("CompanionUIManager.ShowCompanionDetails: companionInstanceData.Stats is nil for companion:", companionDbId)
	end

	if companionInstanceData.Skills and #companionInstanceData.Skills > 0 then
		addDetailElement("Text", "SkillsHeader", "--- ��ų ---", nil, 16, true)
		for _, skillId in ipairs(companionInstanceData.Skills) do
			if SkillDatabase and SkillDatabase.Skills and SkillDatabase.Skills[skillId] then 
				local skillInfo = SkillDatabase.Skills[skillId] 
				addDetailElement("Text", skillId.."Label", skillInfo.Name or "�̸� ���� ��ų") 
			else
				warn("CompanionUIManager.ShowCompanionDetails: SkillDatabase.Skills or specific skill is nil for ID:", skillId)
				addDetailElement("Text", skillId.."Label_Error", "��ų ���� �ε� �Ұ� (" .. tostring(skillId) .. ")")
			end
		end
	else
		print("CompanionUIManager.ShowCompanionDetails: No skills found for companion:", companionDbId)
	end

	local successParty, currentPartyData = pcall(getCurrentPartyFunction.InvokeServer, getCurrentPartyFunction)
	local isInParty = false
	if successParty and currentPartyData then
		if currentPartyData.Slot1 == companionDbId or currentPartyData.Slot2 == companionDbId then
			isInParty = true
		end
	end
	print(string.format("CompanionUIManager.ShowCompanionDetails: Companion %s is in party: %s", companionDbId, tostring(isInParty)))

	local partyButtonText = isInParty and "��Ƽ���� ����" or "��Ƽ�� �߰�"
	local partyButton = addDetailElement("Button", "PartyButton", partyButtonText, UDim2.new(0.8,0,0,35))

	if not partyButton then
		warn("CompanionUIManager.ShowCompanionDetails: Failed to create partyButton!")
	else
		partyButton.BackgroundColor3 = isInParty and Color3.fromRGB(180,80,80) or Color3.fromRGB(80,180,80)
		print("CompanionUIManager.ShowCompanionDetails: Party button created.")

		partyButton.MouseButton1Click:Connect(function()
			print("CompanionUIManager.ShowCompanionDetails: PartyButton clicked. Current party data:", HttpService:JSONEncode(currentPartyData))
			local currentSlot1 = currentPartyData and currentPartyData.Slot1 or nil
			local currentSlot2 = currentPartyData and currentPartyData.Slot2 or nil
			local finalServerConfig = {nil, nil}

			if isInParty then
				print("CompanionUIManager: Attempting to remove companion", companionDbId)
				if currentSlot1 == companionDbId then
					finalServerConfig = {currentSlot2, nil}
				elseif currentSlot2 == companionDbId then
					finalServerConfig = {currentSlot1, nil}
				else
					warn("CompanionUIManager: isInParty true, but companionDbId not found in slots during removal logic.")
					finalServerConfig = {currentSlot1, currentSlot2} 
				end
			else 
				print("CompanionUIManager: Attempting to add companion", companionDbId)
				if not currentSlot1 then
					finalServerConfig = {companionDbId, currentSlot2}
				elseif not currentSlot2 then
					finalServerConfig = {currentSlot1, companionDbId}
				else
					if CoreUIManager and CoreUIManager.ShowPopupMessage then CoreUIManager.ShowPopupMessage("�˸�", "��Ƽ ������ ���� á���ϴ�. �ٸ� ���Ḧ ���� �������ּ���.", 3) end
					return
				end
			end
			print("CompanionUIManager: Sending SetPartyEvent with config:", HttpService:JSONEncode(finalServerConfig))
			setPartyEvent:FireServer(finalServerConfig)
		end)
	end

	local useItemButton = addDetailElement("Button", "UseItemButton", "������ ���", UDim2.new(0.8, 0, 0, 35))
	if useItemButton then
		useItemButton.BackgroundColor3 = Color3.fromRGB(100, 150, 200) 
		useItemButton.MouseButton1Click:Connect(function()
			print(string.format("CompanionUIManager: UseItemButton clicked for companion %s. Showing item list.", companionDbId))
			if not selectedOwnedCompanionDbId then
				warn("CompanionUIManager: �������� ����� ���ᰡ ���õ��� �ʾҽ��ϴ� (selectedOwnedCompanionDbId is nil).")
				if CoreUIManager and CoreUIManager.ShowPopupMessage then CoreUIManager.ShowPopupMessage("����", "���� ���Ḧ �������ּ���.") end
				return
			end
			CompanionUIManager.ShowConsumableItemList(true) 
		end)
	else
		warn("CompanionUIManager: Failed to create UseItemButton!")
	end

	companionDetailsFrame.CanvasSize = UDim2.new(0, 0, 0, currentYOffset + 10) 
	print("CompanionUIManager.ShowCompanionDetails: Details CanvasSize updated to", companionDetailsFrame.CanvasSize.Y.Offset)
	print(string.format("CompanionUIManager.ShowCompanionDetails: Finished for companionDbId = %s", tostring(companionDbId)))
end

return CompanionUIManager