--[[
  CraftingUIManager (ModuleScript)
  ���� â UI ���� ���� ��� (Ŭ���̾�Ʈ ��)
  (������ ��� ǥ��, �� ���� ǥ��, ��� Ȯ�� ��)
  *** [����] ��� �ý��� ����: ������ ��� �� �� ������ ��� ������ ��� ���� ���� ***
  *** [��� ����] UI â ��ħ ������ ���� CoreUIManager.OpenMainUIPopup ��� ***
  *** [���� ����] TooltipManager ���� ���� ���� ***
]]
local CraftingUIManager = {}

-- �ʿ��� ���� �� ��� �ε�
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer 
local playerGui = player:WaitForChild("PlayerGui") 
local mainGui = playerGui:WaitForChild("MainGui") 

local ModuleManager
local CoreUIManager 
local PlayerData 
local ItemDatabase
local CraftingDatabase
local GuiUtils
local getPlayerInventoryFunction 
local TooltipManager -- ##### TooltipManager ���� ���� #####

local RATING_COLORS = {
	["Common"] = Color3.fromRGB(180, 180, 180),
	["Uncommon"] = Color3.fromRGB(100, 200, 100),
	["Rare"] = Color3.fromRGB(100, 150, 255),
	["Epic"] = Color3.fromRGB(180, 100, 220),
	["Legendary"] = Color3.fromRGB(255, 165, 0),
}
local DEFAULT_RATING_COLOR = RATING_COLORS["Common"]

local selectedRecipeId = nil 
local craftingFrame = nil 

-- ��� �ʱ�ȭ
function CraftingUIManager.Init()
	ModuleManager = require(ReplicatedStorage.Modules:WaitForChild("ModuleManager"))
	CoreUIManager = ModuleManager:GetModule("CoreUIManager") 
	PlayerData = ModuleManager:GetModule("PlayerData")
	ItemDatabase = ModuleManager:GetModule("ItemDatabase")
	CraftingDatabase = ModuleManager:GetModule("CraftingDatabase")
	GuiUtils = ModuleManager:GetModule("GuiUtils") 
	getPlayerInventoryFunction = ReplicatedStorage:WaitForChild("GetPlayerInventoryFunction") 
	TooltipManager = ModuleManager:GetModule("TooltipManager") -- ##### TooltipManager �ʱ�ȭ #####

	if not GuiUtils then
		warn("CraftingUIManager: GuiUtils module failed to load!")
	end
	if not getPlayerInventoryFunction then
		warn("CraftingUIManager: GetPlayerInventoryFunction not found!")
	end
	if not TooltipManager then -- ##### TooltipManager �ε� Ȯ�� #####
		warn("CraftingUIManager: TooltipManager module failed to load!")
	end
	CraftingUIManager.SetupUIReferences() 
	print("CraftingUIManager: Initialized and modules loaded.")
end

function CraftingUIManager.SetupUIReferences()
	if not mainGui then 
		local p = Players.LocalPlayer
		local pg = p and p:WaitForChild("PlayerGui")
		mainGui = pg and pg:FindFirstChild("MainGui")
		if not mainGui then
			warn("CraftingUIManager.SetupUIReferences: MainGui not found even after retry!")
			return
		end
	end
	local backgroundFrame = mainGui:FindFirstChild("BackgroundFrame")
	if backgroundFrame then
		craftingFrame = backgroundFrame:FindFirstChild("CraftingFrame")
		if not craftingFrame then 
			warn("CraftingUIManager.SetupUIReferences: CraftingFrame not found!")
		else
			print("CraftingUIManager: CraftingFrame reference established.")
		end
	else
		warn("CraftingUIManager.SetupUIReferences: BackgroundFrame not found!")
	end
end

function CraftingUIManager.ShowCrafting(show)
	if not craftingFrame then 
		CraftingUIManager.SetupUIReferences()
		if not craftingFrame then
			warn("CraftingUIManager.ShowCrafting: CraftingFrame is still nil after setup.")
			return
		end
	end
	if not CoreUIManager then
		warn("CraftingUIManager.ShowCrafting: CoreUIManager not available!")
		if craftingFrame then craftingFrame.Visible = show end 
		return
	end

	if show then
		CoreUIManager.OpenMainUIPopup("CraftingFrame") 
		CraftingUIManager.UpdateRecipeList() 
		selectedRecipeId = nil 
		CraftingUIManager.ShowCraftingDetails(nil) 
	else
		CoreUIManager.ShowFrame("CraftingFrame", false) 
		if TooltipManager and TooltipManager.HideTooltip then -- TooltipManager ���� Ȯ�� �� ȣ��
			TooltipManager.HideTooltip()
		end
	end
	print("CraftingUIManager: CraftingFrame visibility process for", show)
end

function CraftingUIManager.UpdateRecipeList()
	if not craftingFrame then warn("CraftingUIManager.UpdateRecipeList: CraftingFrame is nil!"); return end
	local recipeList = craftingFrame:FindFirstChild("RecipeList")
	if not recipeList then warn("CraftingUIManager.UpdateRecipeList: RecipeList is nil!"); return end

	if not CraftingDatabase or not CraftingDatabase.Recipes then warn("CraftingUIManager.UpdateRecipeList: CraftingDatabase not loaded or has no recipes!"); return end
	if not ItemDatabase or not ItemDatabase.Items then warn("CraftingUIManager.UpdateRecipeList: ItemDatabase not loaded!"); return end

	for _, child in ipairs(recipeList:GetChildren()) do
		if child:IsA("TextButton") then
			child:Destroy()
		end
	end

	local order = 1
	for recipeId, recipeData in pairs(CraftingDatabase.Recipes) do
		local resultItemInfo = ItemDatabase.Items[recipeData.ResultItemID]
		local buttonText = resultItemInfo and resultItemInfo.Name or ("Recipe " .. recipeId)
		local rating = resultItemInfo and resultItemInfo.Rating or "Common"
		local ratingColor = RATING_COLORS[rating] or DEFAULT_RATING_COLOR

		local recipeButton = Instance.new("TextButton")
		recipeButton.Name = "RecipeButton_" .. recipeId
		recipeButton.Text = buttonText
		recipeButton.Size = UDim2.new(1, -10, 0, 35) 
		recipeButton.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
		recipeButton.TextColor3 = ratingColor
		recipeButton.TextScaled = true
		recipeButton.Font = Enum.Font.SourceSansBold 
		recipeButton.LayoutOrder = order
		recipeButton.Parent = recipeList

		recipeButton.MouseButton1Click:Connect(function()
			CraftingUIManager.ShowCraftingDetails(recipeId)
		end)
		order = order + 1
	end

	local listLayout = recipeList:FindFirstChildOfClass("UIListLayout")
	if listLayout then
		local numItems = 0
		for _, c in ipairs(recipeList:GetChildren()) do if c:IsA("TextButton") then numItems = numItems + 1 end end
		local itemHeight = 35 
		local padding = listLayout.Padding.Offset
		recipeList.CanvasSize = UDim2.new(0, 0, 0, numItems * itemHeight + math.max(0, numItems - 1) * padding)
	end
	print("CraftingUIManager: Recipe list updated.")
end

function CraftingUIManager.ShowCraftingDetails(recipeId)
	if not craftingFrame then warn("CraftingUIManager.ShowCraftingDetails: CraftingFrame is nil!"); return end
	local detailsFrame = craftingFrame:FindFirstChild("DetailsFrame")
	local resultImage = detailsFrame and detailsFrame:FindFirstChild("ResultImage")
	local resultNameLabel = detailsFrame and detailsFrame:FindFirstChild("ResultNameLabel")
	local materialsLabel = detailsFrame and detailsFrame:FindFirstChild("MaterialsLabel")
	local materialList = detailsFrame and detailsFrame:FindFirstChild("MaterialList")
	local craftButton = detailsFrame and detailsFrame:FindFirstChild("CraftButton")

	if not (detailsFrame and resultImage and resultNameLabel and materialsLabel and materialList and craftButton) then
		warn("CraftingUIManager.ShowCraftingDetails: One or more detail elements not found!")
		return
	end
	if not PlayerData then warn("CraftingUIManager.ShowCraftingDetails: PlayerData module not loaded!"); return end
	if not ItemDatabase or not ItemDatabase.Items then warn("CraftingUIManager.ShowCraftingDetails: ItemDatabase not loaded!"); return end

	selectedRecipeId = recipeId 

	materialList:ClearAllChildren()

	if not recipeId or not CraftingDatabase or not CraftingDatabase.Recipes or not CraftingDatabase.Recipes[recipeId] then
		resultImage.Image = ""
		resultImage.Visible = false
		resultNameLabel.Text = "������ ����"
		resultNameLabel.TextColor3 = Color3.fromRGB(255, 255, 255) 
		materialsLabel.Text = "�ʿ� ���:"
		craftButton.Visible = false
		materialList.CanvasSize = UDim2.new(0,0,0,0)
		return
	end

	local recipeData = CraftingDatabase.Recipes[recipeId]
	local resultItemInfo = ItemDatabase.Items[recipeData.ResultItemID]
	local rating = resultItemInfo and resultItemInfo.Rating or "Common"
	local ratingColor = RATING_COLORS[rating] or DEFAULT_RATING_COLOR

	resultImage.Image = resultItemInfo and resultItemInfo.ImageId or "" 
	resultImage.Visible = true
	resultNameLabel.Text = resultItemInfo and resultItemInfo.Name or "Unknown Item"
	resultNameLabel.TextColor3 = ratingColor
	materialsLabel.Text = "�ʿ� ���:"
	craftButton.Visible = true

	local totalMaterialHeight = 0
	local canCraft = true
	local playerInventory = {} 
	if getPlayerInventoryFunction then
		local success, result = pcall(function()
			return getPlayerInventoryFunction:InvokeServer() 
		end)
		if success and typeof(result) == "table" then
			playerInventory = result
		elseif not success then
			warn("CraftingUIManager: Error invoking GetPlayerInventoryFunction:", result)
		else
			warn("CraftingUIManager: GetPlayerInventoryFunction returned unexpected type:", typeof(result))
		end
	else
		warn("CraftingUIManager: GetPlayerInventoryFunction not found!")
	end

	if recipeData.Materials and #recipeData.Materials > 0 then
		for i, materialData in ipairs(recipeData.Materials) do
			local materialItemInfo = ItemDatabase.Items[materialData.ItemID]
			local itemName = materialItemInfo and materialItemInfo.Name or ("Item " .. materialData.ItemID)
			local requiredQty = materialData.Quantity
			local currentQty = 0

			for _, slotData in ipairs(playerInventory) do
				if slotData.itemId == materialData.ItemID then
					currentQty = currentQty + slotData.quantity
				end
			end

			if GuiUtils and GuiUtils.CreateTextLabel then
				local label = GuiUtils.CreateTextLabel(materialList, "Material_"..i,
					UDim2.new(0, 5, 0, totalMaterialHeight), 
					UDim2.new(1, -10, 0, 20), 
					string.format("%s: %d / %d", itemName, currentQty, requiredQty),
					nil, Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 14)

				if label then
					label.TextColor3 = (currentQty >= requiredQty) and Color3.new(1, 1, 1) or Color3.fromRGB(255, 100, 100)
					totalMaterialHeight = totalMaterialHeight + 20
				else
					warn("CraftingUIManager.ShowCraftingDetails: Failed to create material label using GuiUtils.")
				end
			else
				warn("CraftingUIManager.ShowCraftingDetails: GuiUtils or GuiUtils.CreateTextLabel is nil!")
			end

			if currentQty < requiredQty then
				canCraft = false
			end
		end
	else
		if GuiUtils and GuiUtils.CreateTextLabel then
			GuiUtils.CreateTextLabel(materialList, "Material_None", UDim2.new(0, 5, 0, 0), UDim2.new(1, -10, 0, 20), "��� �ʿ� ����", nil, Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 14)
		end
		totalMaterialHeight = 20
	end

	materialList.CanvasSize = UDim2.new(0, 0, 0, totalMaterialHeight)
	craftButton.Selectable = canCraft
	craftButton.BackgroundColor3 = canCraft and Color3.fromRGB(80, 150, 80) or Color3.fromRGB(100, 100, 100)

	print("CraftingUIManager: Details shown for recipe", recipeId, "Can Craft:", canCraft)
end

function CraftingUIManager.GetSelectedCraftingRecipeId()
	return selectedRecipeId
end

function CraftingUIManager.RefreshCraftingDetailsIfVisible()
	if not craftingFrame then return end 
	if craftingFrame.Visible and selectedRecipeId then
		print("CraftingUIManager: Refreshing crafting details due to inventory update.")
		CraftingUIManager.ShowCraftingDetails(selectedRecipeId)
	end
end

return CraftingUIManager