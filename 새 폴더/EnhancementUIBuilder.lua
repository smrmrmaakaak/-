-- EnhancementUIBuilder.lua (����: ��ȭ ���� ������ ��� ���� �߰�, ��ȭ �� ȿ�� UI �߰�)

local EnhancementUIBuilder = {}

function EnhancementUIBuilder.Build(mainGui, backgroundFrame, framesFolder, GuiUtils)
	if not GuiUtils then 
		local ModuleManager = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("ModuleManager"))
		GuiUtils = ModuleManager:GetModule("GuiUtils")
		if not GuiUtils then warn("EnhancementUIBuilder: GuiUtils �ε� ����!"); return nil end
	end
	print("EnhancementUIBuilder: ��ȭ â UI ���� ����...")

	local cornerRadius = UDim.new(0, 8)
	local smallCornerRadius = UDim.new(0, 4)

	local enhancementFrame = Instance.new("Frame")
	enhancementFrame.Name = "EnhancementFrame"
	enhancementFrame.Parent = backgroundFrame
	enhancementFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	enhancementFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	enhancementFrame.Size = UDim2.new(0.7, 0, 0.7, 0) 
	enhancementFrame.BackgroundColor3 = Color3.fromRGB(65, 60, 50)
	enhancementFrame.BorderColor3 = Color3.fromRGB(200, 190, 170)
	enhancementFrame.BorderSizePixel = 2
	enhancementFrame.Visible = false
	enhancementFrame.ZIndex = 6
	Instance.new("UICorner", enhancementFrame).CornerRadius = cornerRadius
	print("EnhancementUIBuilder: EnhancementFrame ������")

	GuiUtils.CreateTextLabel(enhancementFrame, "TitleLabel",
		UDim2.new(0.5, 0, 0.05, 0), UDim2.new(0.9, 0, 0.1, 0),
		"��� ��ȭ", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 20)

	local enhanceableItemList = Instance.new("ScrollingFrame")
	enhanceableItemList.Name = "EnhanceableItemList"
	enhanceableItemList.Parent = enhancementFrame
	enhanceableItemList.Position = UDim2.new(0.05, 0, 0.18, 0) 
	enhanceableItemList.Size = UDim2.new(0.4, 0, 0.7, 0) 
	enhanceableItemList.BackgroundColor3 = Color3.fromRGB(50, 45, 35)
	enhanceableItemList.BorderSizePixel = 1
	enhanceableItemList.BorderColor3 = Color3.fromRGB(150, 140, 120)
	enhanceableItemList.CanvasSize = UDim2.new(0, 0, 0, 0)
	enhanceableItemList.ScrollBarThickness = 6
	Instance.new("UICorner", enhanceableItemList).CornerRadius = smallCornerRadius

	local itemListLayout = Instance.new("UIGridLayout")
	itemListLayout.Parent = enhanceableItemList
	itemListLayout.CellPadding = UDim2.new(0, 5, 0, 5)
	itemListLayout.CellSize = UDim2.new(0, 64, 0, 64) 
	itemListLayout.StartCorner = Enum.StartCorner.TopLeft
	itemListLayout.FillDirection = Enum.FillDirection.Horizontal
	itemListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	itemListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	itemListLayout.SortOrder = Enum.SortOrder.LayoutOrder 
	print("EnhancementUIBuilder: EnhanceableItemList ������")

	local detailsDisplayFrame = GuiUtils.CreateFrame(enhancementFrame, "DetailsDisplayFrame",
		UDim2.new(0.52, 0, 0.18, 0), UDim2.new(0.43, 0, 0.7, 0), 
		nil, nil, 1)

	local itemDisplayFrame = GuiUtils.CreateFrame(detailsDisplayFrame, "ItemDisplayFrame",
		UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0.25, 0), 
		nil, nil, 1)

	local selectedItemImage = GuiUtils.CreateImageLabel(itemDisplayFrame, "SelectedItemImage",
		UDim2.new(0.1, 0, 0.5, 0), UDim2.new(0, 64, 0, 64),
		Vector2.new(0, 0.5), nil, Enum.ScaleType.Fit, detailsDisplayFrame.ZIndex + 1)
	selectedItemImage.BackgroundColor3 = Color3.fromRGB(40, 40, 30); selectedItemImage.BackgroundTransparency = 0.3
	Instance.new("UICorner", selectedItemImage).CornerRadius = smallCornerRadius

	local itemInfoLabel = GuiUtils.CreateTextLabel(itemDisplayFrame, "ItemInfoLabel",
		UDim2.new(0.1 + (64/ (detailsDisplayFrame.AbsoluteSize.X * 0.43) ), 15, 0.5, 0), -- �θ� ũ�� ������� X ������ ��� �� ����
		UDim2.new(1, -(64+20), 0.8, 0), 
		"��ȭ�� �������� ��Ͽ��� �����ϼ���.", Vector2.new(0, 0.5), Enum.TextXAlignment.Left, Enum.TextYAlignment.Top, 14)
	itemInfoLabel.TextWrapped = true

	local infoDisplayFrame = GuiUtils.CreateFrame(detailsDisplayFrame, "InfoDisplayFrame",
		UDim2.new(0, 0, 0.3, 0), UDim2.new(1, 0, 0.4, 0), 
		nil, nil, 1)

	GuiUtils.CreateTextLabel(infoDisplayFrame, "MaterialsHeader",
		UDim2.new(0, 0, 0.05, 0), UDim2.new(1, 0, 0.1, 0),
		"�ʿ� ���:", Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 14)

	local materialList = Instance.new("ScrollingFrame")
	materialList.Name = "MaterialList"
	materialList.Parent = infoDisplayFrame
	materialList.Position = UDim2.new(0, 0, 0.18, 0)
	materialList.Size = UDim2.new(1, 0, 0.5, 0) 
	materialList.BackgroundColor3 = Color3.fromRGB(50, 45, 35); materialList.BorderSizePixel = 1
	materialList.CanvasSize = UDim2.new(0, 0, 0, 0); materialList.ScrollBarThickness = 4
	Instance.new("UICorner", materialList).CornerRadius = smallCornerRadius
	local materialListLayout = Instance.new("UIListLayout"); materialListLayout.Padding = UDim.new(0, 2); materialListLayout.FillDirection = Enum.FillDirection.Vertical; materialListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left; materialListLayout.Parent = materialList

	local costLabel = GuiUtils.CreateTextLabel(infoDisplayFrame, "CostLabel",
		UDim2.new(0, 0, 0.75, 0), UDim2.new(0.5, 0, 0.1, 0),
		"���: - G", Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 14)

	local successRateLabel = GuiUtils.CreateTextLabel(infoDisplayFrame, "SuccessRateLabel",
		UDim2.new(0, 0, 0.88, 0), UDim2.new(0.5, 0, 0.1, 0),
		"���� Ȯ��: - %", Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 14)

	local enhanceButton = GuiUtils.CreateButton(detailsDisplayFrame, "EnhanceButton",
		UDim2.new(0.5, 0, 0.9, 0), UDim2.new(0.6, 0, 0.1, 0), 
		Vector2.new(0.5, 1), "��ȭ", nil, detailsDisplayFrame.ZIndex + 1)
	enhanceButton.BackgroundColor3 = Color3.fromRGB(180, 140, 80); enhanceButton.Visible = false
	Instance.new("UICorner", enhanceButton).CornerRadius = cornerRadius

	-- ##### ��ȭ �� ȿ�� ������ �߰� #####
	local processingOverlay = GuiUtils.CreateFrame(detailsDisplayFrame, "ProcessingOverlay",
		enhanceButton.Position, -- ��ȭ ��ư�� ������ ��ġ
		enhanceButton.Size,     -- ��ȭ ��ư�� ������ ũ��
		enhanceButton.AnchorPoint,
		Color3.fromRGB(0, 0, 0), -- ������ ���
		0.5, -- ������
		detailsDisplayFrame.ZIndex + 2) -- ��ȭ ��ư���� ���� ǥ��
	processingOverlay.Visible = false -- �⺻������ ����
	Instance.new("UICorner", processingOverlay).CornerRadius = cornerRadius -- ��ȭ ��ư�� ������ �ڳ�

	local processingText = GuiUtils.CreateTextLabel(processingOverlay, "ProcessingText",
		UDim2.new(0.5, 0, 0.5, 0), UDim2.new(1, 0, 1, 0),
		"��ȭ ��...",
		Vector2.new(0.5, 0.5), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center,
		16, Color3.new(1,1,1), Enum.Font.SourceSansBold)
	processingText.ZIndex = processingOverlay.ZIndex + 1
	print("EnhancementUIBuilder: ProcessingOverlay ������")
	-- ##### ��ȭ �� ȿ�� ������ �߰� �� #####

	local closeButton = GuiUtils.CreateButton(enhancementFrame, "CloseButton",
		UDim2.new(1, -5, 1, -5), UDim2.new(0, 80, 0, 30),
		Vector2.new(1, 1), "�ݱ�", nil, enhancementFrame.ZIndex + 1)
	closeButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50); Instance.new("UICorner", closeButton).CornerRadius = smallCornerRadius

	print("EnhancementUIBuilder: ��ȭ â UI ���� �Ϸ�.")
	return enhancementFrame
end

return EnhancementUIBuilder