--[[
  CraftingUIBuilder (ModuleScript)
  제작 창 UI를 생성합니다.
]]
local CraftingUIBuilder = {}

function CraftingUIBuilder.Build(mainGui, backgroundFrame, framesFolder, GuiUtils)
	print("CraftingUIBuilder: 제작 창 UI 생성 시작...")

	local cornerRadius = UDim.new(0, 8)

	local craftingFrame = Instance.new("Frame")
	craftingFrame.Name = "CraftingFrame"
	craftingFrame.Parent = backgroundFrame -- BackgroundFrame 아래에 배치 (팝업 형태)
	craftingFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	craftingFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	craftingFrame.Size = UDim2.new(0.7, 0, 0.7, 0)
	craftingFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	craftingFrame.BorderColor3 = Color3.fromRGB(190, 190, 220)
	craftingFrame.BorderSizePixel = 2
	craftingFrame.Visible = false
	craftingFrame.ZIndex = 5
	Instance.new("UICorner", craftingFrame).CornerRadius = cornerRadius
	print("CraftingUIBuilder: CraftingFrame 생성됨")

	GuiUtils.CreateTextLabel(craftingFrame, "TitleLabel", UDim2.new(0.5, 0, 0.05, 0), UDim2.new(0.9, 0, 0.1, 0), "제작", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 20)

	local recipeList = Instance.new("ScrollingFrame")
	recipeList.Name = "RecipeList"
	recipeList.Size = UDim2.new(0.4, 0, 0.7, 0)
	recipeList.Position = UDim2.new(0.05, 0, 0.15, 0)
	recipeList.AnchorPoint = Vector2.new(0, 0)
	recipeList.BackgroundColor3 = Color3.fromRGB(45, 45, 60)
	recipeList.BorderSizePixel = 1
	recipeList.CanvasSize = UDim2.new(0, 0, 0, 0)
	recipeList.ScrollBarThickness = 8
	recipeList.Parent = craftingFrame
	Instance.new("UICorner", recipeList).CornerRadius = cornerRadius
	local recipeListLayout = Instance.new("UIListLayout")
	recipeListLayout.Padding = UDim.new(0, 3)
	recipeListLayout.FillDirection = Enum.FillDirection.Vertical
	recipeListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	recipeListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	recipeListLayout.Parent = recipeList
	print("CraftingUIBuilder: Crafting RecipeList 생성됨")

	local detailsFrame = Instance.new("Frame")
	detailsFrame.Name = "DetailsFrame"
	detailsFrame.Size = UDim2.new(0.45, 0, 0.7, 0)
	detailsFrame.Position = UDim2.new(0.5, 0, 0.15, 0)
	detailsFrame.AnchorPoint = Vector2.new(0, 0)
	detailsFrame.BackgroundTransparency = 1
	detailsFrame.Parent = craftingFrame
	print("CraftingUIBuilder: Crafting DetailsFrame 생성됨")

	local resultImage = Instance.new("ImageLabel")
	resultImage.Name = "ResultImage"
	resultImage.Size = UDim2.new(0, 64, 0, 64)
	resultImage.Position = UDim2.new(0.5, 0, 0.1, 0)
	resultImage.AnchorPoint = Vector2.new(0.5, 0)
	resultImage.BackgroundColor3 = Color3.fromRGB(80, 80, 100)
	resultImage.ScaleType = Enum.ScaleType.Fit
	resultImage.Parent = detailsFrame
	Instance.new("UICorner", resultImage).CornerRadius = cornerRadius

	local resultNameLabel = GuiUtils.CreateTextLabel(detailsFrame, "ResultNameLabel", UDim2.new(0.5, 0, 0.3, 0), UDim2.new(0.9, 0, 0.1, 0), "결과물 이름", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 16)
	local materialsLabel = GuiUtils.CreateTextLabel(detailsFrame, "MaterialsLabel", UDim2.new(0.5, 0, 0.45, 0), UDim2.new(0.9, 0, 0.08, 0), "필요 재료:", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 14)

	local materialList = Instance.new("ScrollingFrame")
	materialList.Name = "MaterialList"
	materialList.Size = UDim2.new(0.9, 0, 0.25, 0)
	materialList.Position = UDim2.new(0.5, 0, 0.55, 0)
	materialList.AnchorPoint = Vector2.new(0.5, 0)
	materialList.BackgroundColor3 = Color3.fromRGB(50, 50, 70)
	materialList.BorderSizePixel = 1
	materialList.CanvasSize = UDim2.new(0, 0, 0, 0)
	materialList.ScrollBarThickness = 6
	materialList.Parent = detailsFrame
	Instance.new("UICorner", materialList).CornerRadius = cornerRadius
	local materialListLayout = Instance.new("UIListLayout")
	materialListLayout.Padding = UDim.new(0, 2)
	materialListLayout.FillDirection = Enum.FillDirection.Vertical
	materialListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	materialListLayout.Parent = materialList
	print("CraftingUIBuilder: Crafting MaterialList 생성됨")

	local craftButton = Instance.new("TextButton")
	craftButton.Name = "CraftButton"
	craftButton.Size = UDim2.new(0.6, 0, 0.1, 0)
	craftButton.Position = UDim2.new(0.5, 0, 0.9, 0)
	craftButton.AnchorPoint = Vector2.new(0.5, 1)
	craftButton.BackgroundColor3 = Color3.fromRGB(80, 150, 80)
	craftButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	craftButton.Text = "제작"
	craftButton.Font = Enum.Font.SourceSansBold
	craftButton.TextScaled = true
	craftButton.Parent = detailsFrame
	Instance.new("UICorner", craftButton).CornerRadius = cornerRadius
	print("CraftingUIBuilder: CraftButton 생성됨")

	local closeCraftingButton = Instance.new("TextButton")
	closeCraftingButton.Name = "CloseButton"
	closeCraftingButton.Parent = craftingFrame
	closeCraftingButton.AnchorPoint = Vector2.new(1, 1)
	closeCraftingButton.Position = UDim2.new(0.95, 0, 0.95, 0)
	closeCraftingButton.Size = UDim2.new(0.2, 0, 0.1, 0)
	closeCraftingButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	closeCraftingButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeCraftingButton.TextScaled = true
	closeCraftingButton.Font = Enum.Font.SourceSansBold
	closeCraftingButton.Text = "닫기"
	closeCraftingButton.BorderSizePixel = 0
	closeCraftingButton.ZIndex = 6
	Instance.new("UICorner", closeCraftingButton).CornerRadius = cornerRadius
	print("CraftingUIBuilder: CraftingFrame CloseButton 생성됨")

	print("CraftingUIBuilder: 제작 창 UI 생성 완료.")
end

return CraftingUIBuilder
