-- EnhancementUIManager.lua (����: ������ ���� ���� �߰�, UI â ��ħ ���� ���� ����)

local EnhancementUIManager = {}

-- �ʿ��� ���� �� ��� �ε�
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService") 

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainGui = playerGui:WaitForChild("MainGui")

local ModuleManager
local CoreUIManager -- CoreUIManager ���� ����
local ItemDatabase
local EnhancementDatabase
local PlayerData
local GuiUtils
local getPlayerInventoryFunction
local EnhanceItemEvent
local EnhancementResultEvent
-- local TooltipManager -- �ʿ�� �߰� (����� ������� ����)

-- UI ��� ���� ���� (��� �������� �̵�)
local enhancementFrame = nil
local enhanceableItemList = nil 
local selectedItemImage = nil
local itemInfoLabel = nil
local materialList = nil
local costLabel = nil
local successRateLabel = nil
local enhanceButton = nil
local closeButton = nil -- ButtonHandler���� ó��

local currentSelectedItemInventoryIndex = nil 

local RATING_COLORS = { Common=Color3.fromRGB(180,180,180), Uncommon=Color3.fromRGB(100,200,100), Rare=Color3.fromRGB(100,150,255), Epic=Color3.fromRGB(180,100,220), Legendary=Color3.fromRGB(255,165,0) }
local DEFAULT_RATING_COLOR = RATING_COLORS["Common"]

local function HandleEnhancementResult(resultPayload) 
	print("EnhancementUIManager: Received enhancement result:", resultPayload)
	if not enhancementFrame or not enhancementFrame.Visible then return end
	if enhanceButton then enhanceButton.Selectable=true; enhanceButton.Text="��ȭ" end
	if resultPayload and typeof(resultPayload)=='table' then 
		if resultPayload.success then 
			local newItemInfo=ItemDatabase.GetItemInfo(resultPayload.itemId)
			local successMsg=string.format("%s (+%d) ��ȭ ����!",newItemInfo and newItemInfo.Name or "������",resultPayload.newLevel or "?")
			if CoreUIManager and CoreUIManager.ShowPopupMessage then CoreUIManager.ShowPopupMessage("��ȭ ����",successMsg,2) else warn("No CoreUIManager") end
			task.wait(0.1)
			EnhancementUIManager.DisplayItemForEnhancement(currentSelectedItemInventoryIndex) 
		else 
			local failMsg=resultPayload.reason or "�� �� ���� ������ ��ȭ ����"
			if CoreUIManager and CoreUIManager.ShowPopupMessage then CoreUIManager.ShowPopupMessage("��ȭ ����",failMsg,2) else warn("No CoreUIManager") end
			task.wait(0.1)
			EnhancementUIManager.DisplayItemForEnhancement(currentSelectedItemInventoryIndex) 
		end 
	else 
		warn("�߸��� ��ȭ ��� ������:", resultPayload) 
	end 
end

-- ��� �ʱ�ȭ
function EnhancementUIManager.Init()
	ModuleManager = require(ReplicatedStorage.Modules:WaitForChild("ModuleManager"))
	CoreUIManager = ModuleManager:GetModule("CoreUIManager") -- CoreUIManager �ʱ�ȭ
	ItemDatabase = ModuleManager:GetModule("ItemDatabase")
	EnhancementDatabase = ModuleManager:GetModule("EnhancementDatabase")
	PlayerData = ModuleManager:GetModule("PlayerData")
	GuiUtils = ModuleManager:GetModule("GuiUtils")
	-- TooltipManager = ModuleManager:GetModule("TooltipManager") -- �ʿ�� �ʱ�ȭ
	getPlayerInventoryFunction = ReplicatedStorage:WaitForChild("GetPlayerInventoryFunction")
	EnhanceItemEvent = ReplicatedStorage:WaitForChild("EnhanceItemEvent")
	EnhancementResultEvent = ReplicatedStorage:WaitForChild("EnhancementResultEvent")
	if not getPlayerInventoryFunction then warn("EnhancementUIManager: GetPlayerInventoryFunction not found!") end
	if not EnhanceItemEvent then warn("EnhancementUIManager: EnhanceItemEvent not found!") end
	if not EnhancementResultEvent then warn("EnhancementUIManager: EnhancementResultEvent not found!")
	else EnhancementResultEvent.OnClientEvent:Connect(HandleEnhancementResult); print("EnhancementUIManager: EnhancementResultEvent listener connected.") end

	EnhancementUIManager.SetupUIReferences() -- UI ���� ����
	print("EnhancementUIManager: Initialized.")
end

-- UI ��� ���� ���� �Լ�
function EnhancementUIManager.SetupUIReferences()
	if enhancementFrame then return true end
	if not mainGui then
		local p = Players.LocalPlayer
		local pg = p and p:WaitForChild("PlayerGui")
		mainGui = pg and pg:FindFirstChild("MainGui")
		if not mainGui then
			warn("EnhancementUIManager.SetupUIReferences: MainGui not found!")
			return false
		end
	end
	local backgroundFrame = mainGui:FindFirstChild("BackgroundFrame")
	enhancementFrame = backgroundFrame and backgroundFrame:FindFirstChild("EnhancementFrame")
	if enhancementFrame then
		enhanceableItemList = enhancementFrame:FindFirstChild("EnhanceableItemList") 
		local detailsDisplay = enhancementFrame:FindFirstChild("DetailsDisplayFrame")
		if detailsDisplay then
			local itemDisplay = detailsDisplay:FindFirstChild("ItemDisplayFrame"); selectedItemImage = itemDisplay and itemDisplay:FindFirstChild("SelectedItemImage"); itemInfoLabel = itemDisplay and itemDisplay:FindFirstChild("ItemInfoLabel")
			local infoDisplay = detailsDisplay:FindFirstChild("InfoDisplayFrame"); materialList = infoDisplay and infoDisplay:FindFirstChild("MaterialList"); costLabel = infoDisplay and infoDisplay:FindFirstChild("CostLabel"); successRateLabel = infoDisplay and infoDisplay:FindFirstChild("SuccessRateLabel")
			enhanceButton = detailsDisplay:FindFirstChild("EnhanceButton") 
		end
		closeButton = enhancementFrame:FindFirstChild("CloseButton") -- ButtonHandler���� �ַ� ó��
		if not (enhanceableItemList and selectedItemImage and itemInfoLabel and materialList and costLabel and successRateLabel and enhanceButton and closeButton) then 
			warn("EnhancementUIManager: ��ȭ UI ���� ��� �� �Ϻθ� ã�� �� �����ϴ�!")
			enhancementFrame = nil
			return false 
		end

		-- enhanceButton �̺�Ʈ ������ �� ���� ����
		if enhanceButton and not enhanceButton:FindFirstChild("ClickConnection_Enhance") then
			enhanceButton.MouseButton1Click:Connect(function() 
				if enhanceButton.Selectable and currentSelectedItemInventoryIndex then 
					print("EnhancementUIManager: Enhance button clicked for index:", currentSelectedItemInventoryIndex)
					EnhanceItemEvent:FireServer(currentSelectedItemInventoryIndex)
					enhanceButton.Selectable = false
					enhanceButton.Text = "��ȭ ��..." 
				else 
					print("EnhancementUIManager: Enhance button clicked but not ready or no item selected.") 
				end 
			end)
			local marker = Instance.new("BoolValue")
			marker.Name = "ClickConnection_Enhance"
			marker.Parent = enhanceButton
		end
		print("EnhancementUIManager: UI References Setup Completed.")
		return true
	else 
		warn("EnhancementUIManager: EnhancementFrame�� ã�� �� �����ϴ�!")
		return false 
	end
end

function EnhancementUIManager.PopulateEnhanceableItems()
	if not enhanceableItemList then 
		if not EnhancementUIManager.SetupUIReferences() or not enhanceableItemList then
			warn("EnhancementUIManager.PopulateEnhanceableItems: EnhanceableItemList frame is nil after setup attempt!")
			return
		end
	end
	if not ItemDatabase then warn("EnhancementUIManager: ItemDatabase not loaded!"); return end

	enhanceableItemList:ClearAllChildren() 

	local playerInventory = {}
	local successInv, invResult = pcall(function() return getPlayerInventoryFunction:InvokeServer() end)
	if successInv and typeof(invResult) == 'table' then playerInventory = invResult
	else warn("EnhancementUIManager: �κ��丮 ���� �ε� ����!", invResult); return end

	local itemsAdded = 0
	for index, itemSlotData in ipairs(playerInventory) do
		if itemSlotData and itemSlotData.itemId then
			local itemId = itemSlotData.itemId
			local itemInfo = ItemDatabase.GetItemInfo(itemId)

			if itemInfo and itemInfo.Type == "Equipment" and itemInfo.Enhanceable then
				itemsAdded = itemsAdded + 1
				local currentLevel = itemSlotData.enhancementLevel or 0

				local itemButton = Instance.new("ImageButton")
				itemButton.Name = "Item_" .. index 
				itemButton.Size = UDim2.new(0, 64, 0, 64) 
				itemButton.BackgroundColor3 = Color3.fromRGB(70, 65, 55)
				itemButton.BorderSizePixel = 0
				itemButton.LayoutOrder = index 
				itemButton.Parent = enhanceableItemList

				local itemImage = Instance.new("ImageLabel")
				itemImage.Name = "Icon"
				itemImage.Size = UDim2.new(1, -4, 1, -4) 
				itemImage.Position = UDim2.new(0.5, 0, 0.5, 0)
				itemImage.AnchorPoint = Vector2.new(0.5, 0.5)
				itemImage.BackgroundTransparency = 1
				itemImage.Image = itemInfo.ImageId or ""
				itemImage.ScaleType = Enum.ScaleType.Fit
				itemImage.Parent = itemButton

				local levelLabel = GuiUtils.CreateTextLabel(itemButton, "LevelLabel",
					UDim2.new(1, -2, 0, 2), UDim2.new(0.3, 10, 0.2, 0), 
					"+" .. currentLevel,
					Vector2.new(1, 0), Enum.TextXAlignment.Right, Enum.TextYAlignment.Top, 10, Color3.fromRGB(255, 230, 150))
				if levelLabel then 
					levelLabel.TextStrokeTransparency = 0.5
					levelLabel.ZIndex = itemButton.ZIndex + 2
				end

				local rating = itemInfo.Rating or "Common"
				local ratingColor = RATING_COLORS[rating] or DEFAULT_RATING_COLOR
				local ratingStroke = itemButton:FindFirstChild("RatingStroke") or Instance.new("UIStroke")
				ratingStroke.Name = "RatingStroke"; ratingStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; ratingStroke.LineJoinMode = Enum.LineJoinMode.Round; ratingStroke.Thickness = 2; ratingStroke.Color = ratingColor; ratingStroke.Transparency = 0; ratingStroke.Parent = itemButton

				itemButton.MouseButton1Click:Connect(function()
					print("EnhancementUIManager: Selected item at index", index, "ItemID:", itemId)
					EnhancementUIManager.SelectItemForEnhancement(index)
				end)
			end
		end
	end

	task.wait() -- ���̾ƿ� ������Ʈ ���
	local gridLayout = enhanceableItemList:FindFirstChildOfClass("UIGridLayout")
	if gridLayout then
		local contentHeight = gridLayout.AbsoluteContentSize.Y
		enhanceableItemList.CanvasSize = UDim2.new(0,0,0, contentHeight + 10) -- �ϴ� ���� �߰�
	end

	if itemsAdded == 0 then
		GuiUtils.CreateTextLabel(enhanceableItemList, "EmptyMsg", UDim2.new(0.5,0,0.1,0), UDim2.new(0.9,0,0.2,0), "��ȭ ������ �������� �����ϴ�.", Vector2.new(0.5,0))
	end

	print("EnhancementUIManager: Enhanceable item list populated.")
end

function EnhancementUIManager.SelectItemForEnhancement(inventoryIndex)
	if not inventoryIndex then return end
	EnhancementUIManager.DisplayItemForEnhancement(inventoryIndex) 
end

-- ##### [��� ����] ShowEnhancementWindow �Լ����� CoreUIManager.OpenMainUIPopup ��� #####
function EnhancementUIManager.ShowEnhancementWindow(show) 
	if not enhancementFrame then 
		if not EnhancementUIManager.SetupUIReferences() or not enhancementFrame then 
			warn("EnhancementUIManager.ShowEnhancementWindow: EnhancementFrame is still nil after setup attempt.")
			return 
		end 
	end
	if not CoreUIManager then
		warn("EnhancementUIManager.ShowEnhancementWindow: CoreUIManager not available!")
		if enhancementFrame then enhancementFrame.Visible = show end -- Fallback
		return
	end

	if show then
		print("EnhancementUIManager: ��ȭ â ���� �õ�")
		CoreUIManager.OpenMainUIPopup("EnhancementFrame") -- �ٸ� �ֿ� �˾� �ݰ� ��ȭ â ����
		EnhancementUIManager.PopulateEnhanceableItems() 
		EnhancementUIManager.DisplayItemForEnhancement(nil) 
	else
		print("EnhancementUIManager: ��ȭ â �ݱ�")
		CoreUIManager.ShowFrame("EnhancementFrame", false) -- �ܼ��� ��ȭ â �ݱ�
		currentSelectedItemInventoryIndex = nil
		-- if TooltipManager and TooltipManager.HideTooltip then TooltipManager.HideTooltip() end -- �ʿ�� �߰�
	end
end
-- ##################################################################################

function EnhancementUIManager.DisplayItemForEnhancement(inventoryIndex) 
	currentSelectedItemInventoryIndex = inventoryIndex 

	if not enhancementFrame or not enhancementFrame.Visible then return end
	if not currentSelectedItemInventoryIndex then 
		if selectedItemImage then selectedItemImage.Image=""; selectedItemImage.Visible=false end
		if itemInfoLabel then itemInfoLabel.Text="��ȭ�� �������� ��Ͽ��� �����ϼ���." end 
		if materialList then materialList:ClearAllChildren(); materialList.CanvasSize=UDim2.new() end
		if costLabel then costLabel.Text="���: - G" end
		if successRateLabel then successRateLabel.Text="���� Ȯ��: - %" end
		if enhanceButton then enhanceButton.Visible=false; enhanceButton.Text="��ȭ" end
		print("EnhancementUIManager: DisplayItemForEnhancement - No item selected, UI reset.")
		return
	end

	local playerInventory = {}; local successInv, invResult = pcall(function() return getPlayerInventoryFunction:InvokeServer() end); if successInv and typeof(invResult)=='table' then playerInventory = invResult else warn("EnhancementUIManager: �κ��丮 ���� �ε� ����!", invResult); return end
	local itemSlotData = playerInventory[currentSelectedItemInventoryIndex]; if not itemSlotData then warn("EnhancementUIManager: ���õ� �ε��� ������ ����:", currentSelectedItemInventoryIndex); EnhancementUIManager.DisplayItemForEnhancement(nil); return end
	local itemId = itemSlotData.itemId; local currentLevel = itemSlotData.enhancementLevel or 0; local itemInfo = ItemDatabase.GetItemInfo(itemId); if not itemInfo then warn("EnhancementUIManager: ItemDatabase ���� �ε� ����:", itemId); EnhancementUIManager.DisplayItemForEnhancement(nil); return end
	if not itemInfo.Enhanceable then if selectedItemImage then selectedItemImage.Image=itemInfo.ImageId or ""; selectedItemImage.Visible=true end; if itemInfoLabel then itemInfoLabel.Text=string.format("%s\n(��ȭ �Ұ�)", itemInfo.Name) end; if materialList then materialList:ClearAllChildren(); materialList.CanvasSize=UDim2.new() end; if costLabel then costLabel.Text="���: -" end; if successRateLabel then successRateLabel.Text="���� Ȯ��: -" end; if enhanceButton then enhanceButton.Visible=false; enhanceButton.Text="��ȭ" end; print("EnhancementUIManager: DisplayItemForEnhancement - ��ȭ �Ұ� ������:", itemId); return end
	if selectedItemImage then selectedItemImage.Image=itemInfo.ImageId or ""; selectedItemImage.Visible=true end; if itemInfoLabel then itemInfoLabel.Text=string.format("%s (+%d)", itemInfo.Name, currentLevel) end
	local nextLevel = currentLevel + 1; local maxLevel = itemInfo.MaxEnhanceLevel or 0; local nextLevelInfo = nil; if nextLevel <= maxLevel then nextLevelInfo = EnhancementDatabase.GetLevelInfo(nextLevel) end
	if materialList then materialList:ClearAllChildren() end; local totalMaterialHeight = 0; local canEnhance = true
	if nextLevelInfo then local requiredGold = nextLevelInfo.GoldCost or 0; local playerGold = PlayerData.GetStats(player).Gold or 0; if costLabel then costLabel.Text=string.format("���: %d G", requiredGold); costLabel.TextColor3 = (playerGold >= requiredGold) and Color3.new(1,1,1) or Color3.fromRGB(255,100,100) end; if playerGold < requiredGold then canEnhance = false; end; if successRateLabel then successRateLabel.Text=string.format("���� Ȯ��: %.0f %%", (nextLevelInfo.SuccessRate or 0)*100) end
		if nextLevelInfo.Materials and #nextLevelInfo.Materials > 0 and materialList and GuiUtils then for i, matData in ipairs(nextLevelInfo.Materials) do local matInfo = ItemDatabase.GetItemInfo(matData.ItemID); local matName = matInfo and matInfo.Name or ("������ #"..matData.ItemID); local requiredQty = matData.Quantity; local currentQty = 0; for _, invSlotData in ipairs(playerInventory) do if invSlotData.itemId == matData.ItemID then currentQty=currentQty+invSlotData.quantity end end; local label=GuiUtils.CreateTextLabel(materialList,"Material_"..i,UDim2.new(0,5,0,totalMaterialHeight),UDim2.new(1,-10,0,20),string.format("%s: %d / %d",matName,currentQty,requiredQty),nil,Enum.TextXAlignment.Left,Enum.TextYAlignment.Center,12); if label then label.TextColor3=(currentQty>=requiredQty) and Color3.new(1,1,1) or Color3.fromRGB(255,100,100); totalMaterialHeight=totalMaterialHeight+20; if currentQty<requiredQty then canEnhance=false end end end
		else if materialList and GuiUtils then GuiUtils.CreateTextLabel(materialList,"Material_None",UDim2.new(0,5,0,0),UDim2.new(1,-10,0,20),"�ʿ� ��� ����",nil,Enum.TextXAlignment.Left,Enum.TextYAlignment.Center,12); totalMaterialHeight=20 end end
		if materialList then materialList.CanvasSize = UDim2.new(0, 0, 0, totalMaterialHeight) end
		if enhanceButton then enhanceButton.Visible=true; enhanceButton.Selectable=canEnhance; enhanceButton.BackgroundColor3=canEnhance and Color3.fromRGB(180,140,80) or Color3.fromRGB(100,100,100); enhanceButton.Text = "��ȭ" end
	else if costLabel then costLabel.Text="���: -" end; if successRateLabel then successRateLabel.Text="�ִ� ����" end; if enhanceButton then enhanceButton.Visible=false; enhanceButton.Text = "��ȭ" end; if materialList then materialList:ClearAllChildren(); materialList.CanvasSize=UDim2.new() end; canEnhance=false; print("EnhancementUIManager: DisplayItemForEnhancement - �ִ� ��ȭ ���� ����:", itemId) end
	print("EnhancementUIManager: Displayed item for enhancement:", itemId, "Current Level:", currentLevel, "Can Enhance:", canEnhance)
end

return EnhancementUIManager