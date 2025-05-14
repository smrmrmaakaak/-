-- ReplicatedStorage > Modules > CompanionUIBuilder.lua

local CompanionUIBuilder = {}

function CompanionUIBuilder.Build(mainGui, backgroundFrame, framesFolder, GuiUtils)
	if not GuiUtils then
		local ModuleManager = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("ModuleManager"))
		GuiUtils = ModuleManager:GetModule("GuiUtils")
		if not GuiUtils then warn("CompanionUIBuilder: GuiUtils �ε� ����!"); return nil end
	end
	print("CompanionUIBuilder: ���� ���� UI ���� ����...")

	local cornerRadius = UDim.new(0, 8)
	local smallCornerRadius = UDim.new(0, 4) -- ##### [�߰�] ���� UI ��ҿ� #####

	local companionFrame = Instance.new("Frame")
	companionFrame.Name = "CompanionFrame"
	companionFrame.Parent = backgroundFrame
	companionFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	companionFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	companionFrame.Size = UDim2.new(0.8, 0, 0.75, 0)
	companionFrame.BackgroundColor3 = Color3.fromRGB(50, 60, 70)
	companionFrame.BorderColor3 = Color3.fromRGB(180, 190, 200)
	companionFrame.BorderSizePixel = 2
	companionFrame.Visible = false
	companionFrame.ZIndex = 7
	Instance.new("UICorner", companionFrame).CornerRadius = cornerRadius
	print("CompanionUIBuilder: CompanionFrame ������")

	GuiUtils.CreateTextLabel(companionFrame, "TitleLabel",
		UDim2.new(0.5, 0, 0.05, 0), UDim2.new(0.9, 0, 0.08, 0),
		"���� ����", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 22)

	local companionListFrame = Instance.new("ScrollingFrame")
	companionListFrame.Name = "CompanionListFrame"
	companionListFrame.Parent = companionFrame
	companionListFrame.Position = UDim2.new(0.03, 0, 0.15, 0)
	companionListFrame.Size = UDim2.new(0.3, 0, 0.8, 0)
	companionListFrame.BackgroundColor3 = Color3.fromRGB(40, 50, 60)
	companionListFrame.BorderSizePixel = 1
	companionListFrame.CanvasSize = UDim2.new(0,0,0,0)
	companionListFrame.ScrollBarThickness = 6
	Instance.new("UICorner", companionListFrame).CornerRadius = cornerRadius

	local companionListLayout = Instance.new("UIListLayout")
	companionListLayout.Padding = UDim.new(0, 5)
	companionListLayout.FillDirection = Enum.FillDirection.Vertical
	companionListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	companionListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	companionListLayout.Parent = companionListFrame
	print("CompanionUIBuilder: CompanionListFrame ������")

	local detailsFrame = Instance.new("ScrollingFrame") 
	detailsFrame.Name = "CompanionDetailsFrame"
	detailsFrame.Parent = companionFrame
	detailsFrame.Position = UDim2.new(0.35, 0, 0.15, 0)
	detailsFrame.Size = UDim2.new(0.3, 0, 0.8, 0)
	detailsFrame.BackgroundColor3 = Color3.fromRGB(45, 55, 65)
	detailsFrame.BorderSizePixel = 1 
	detailsFrame.BorderColor3 = Color3.fromRGB(180, 190, 200) 
	detailsFrame.CanvasSize = UDim2.new(0,0,0,0) 
	detailsFrame.ScrollBarThickness = 6 
	Instance.new("UICorner", detailsFrame).CornerRadius = cornerRadius

	local detailsListLayout = Instance.new("UIListLayout")
	detailsListLayout.Name = "DetailsListLayout" 
	detailsListLayout.Padding = UDim.new(0, 5)
	detailsListLayout.FillDirection = Enum.FillDirection.Vertical
	detailsListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center 
	detailsListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	detailsListLayout.SortOrder = Enum.SortOrder.LayoutOrder 
	detailsListLayout.Parent = detailsFrame 
	print("CompanionUIBuilder: CompanionDetailsFrame (ScrollingFrame) ������")

	-- ##### [��� �߰�] ���ῡ�� ����� ������ ����� ǥ���� ������ #####
	local consumableItemListFrame = Instance.new("ScrollingFrame")
	consumableItemListFrame.Name = "ConsumableItemListFrame"
	consumableItemListFrame.Parent = companionFrame -- CompanionFrame �ٷ� �Ʒ��� ��ġ (���� �� ���� �� �Ǵ� ���� �˾�ó��)
	consumableItemListFrame.AnchorPoint = Vector2.new(0.5, 0.5) -- �߾� ����
	consumableItemListFrame.Position = UDim2.new(0.5, 0, 0.5, 0) -- CompanionFrame �߾ӿ� �˾�ó��
	consumableItemListFrame.Size = UDim2.new(0.4, 0, 0.5, 0) -- ũ��� ������ ����
	consumableItemListFrame.BackgroundColor3 = Color3.fromRGB(35, 40, 50)
	consumableItemListFrame.BorderColor3 = Color3.fromRGB(150, 160, 170)
	consumableItemListFrame.BorderSizePixel = 2
	consumableItemListFrame.Visible = false -- �⺻������ ����
	consumableItemListFrame.ZIndex = companionFrame.ZIndex + 5 -- �ٸ� UI�麸�� ���� ������
	Instance.new("UICorner", consumableItemListFrame).CornerRadius = cornerRadius
	print("CompanionUIBuilder: ConsumableItemListFrame ������")

	GuiUtils.CreateTextLabel(consumableItemListFrame, "ItemListTitle",
		UDim2.new(0.5, 0, 0.05, 0), UDim2.new(0.9, 0, 0.1, 0),
		"����� ������ ����", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 18)

	local itemListScrollContent = Instance.new("Frame") -- ���� ������ ��ư���� �� ������ (��ũ�� ����)
	itemListScrollContent.Name = "ItemListScrollContent"
	itemListScrollContent.Parent = consumableItemListFrame
	itemListScrollContent.Size = UDim2.new(1, 0, 0, 0) -- �ʺ�� �θ� ���߰� ���̴� �ڵ� ����
	itemListScrollContent.AutomaticSize = Enum.AutomaticSize.Y
	itemListScrollContent.BackgroundTransparency = 1
	local itemListLayout = Instance.new("UIGridLayout")
	itemListLayout.Parent = itemListScrollContent
	itemListLayout.CellPadding = UDim2.new(0, 5, 0, 5)
	itemListLayout.CellSize = UDim2.new(0, 64, 0, 64) -- �κ��丮 ���԰� ������ ũ��
	itemListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	print("CompanionUIBuilder: ConsumableItemListFrame ���� ���̾ƿ� ������")

	local itemButtonTemplate = Instance.new("ImageButton") -- ������ ���ÿ� ��ư ���ø�
	itemButtonTemplate.Name = "ItemButtonTemplate"
	itemButtonTemplate.Size = UDim2.new(0, 60, 0, 60) -- CellSize���� �ణ �۰� (�е� ���)
	itemButtonTemplate.BackgroundColor3 = Color3.fromRGB(70, 65, 55)
	itemButtonTemplate.BorderSizePixel = 1
	itemButtonTemplate.BorderColor3 = Color3.fromRGB(120,110,100)
	itemButtonTemplate.Visible = false -- ���ø��̹Ƿ� ����
	itemButtonTemplate.Parent = consumableItemListFrame -- �ӽ� �θ�, ���� ��� �� �����Ͽ� ScrollContent�� ����
	Instance.new("UICorner", itemButtonTemplate).CornerRadius = smallCornerRadius
	local itemQuantityLabelTemplate = GuiUtils.CreateTextLabel(itemButtonTemplate, "QuantityLabel",
		UDim2.new(1,-2,1,-2), UDim2.new(0.4,0,0.3,0), "x99", Vector2.new(1,1), Enum.TextXAlignment.Right, Enum.TextYAlignment.Bottom, 10)
	itemQuantityLabelTemplate.TextColor3 = Color3.fromRGB(255,255,180)
	print("CompanionUIBuilder: ItemButtonTemplate ������")

	local cancelItemSelectionButton = GuiUtils.CreateButton(consumableItemListFrame, "CancelItemSelectionButton",
		UDim2.new(0.5, 0, 0.95, 0), UDim2.new(0.4, 0, 0.08, 0),
		Vector2.new(0.5, 1), "���", nil, consumableItemListFrame.ZIndex + 1)
	cancelItemSelectionButton.BackgroundColor3 = Color3.fromRGB(180, 80, 80)
	Instance.new("UICorner", cancelItemSelectionButton).CornerRadius = smallCornerRadius
	print("CompanionUIBuilder: CancelItemSelectionButton ������")
	-- #############################################################

	local partyFrame = GuiUtils.CreateFrame(companionFrame, "PartyFrame",
		UDim2.new(0.67, 0, 0.15, 0), UDim2.new(0.3, 0, 0.8, 0),
		nil, Color3.fromRGB(40, 50, 60), 0, companionFrame.ZIndex + 1)
	Instance.new("UICorner", partyFrame).CornerRadius = cornerRadius
	GuiUtils.CreateTextLabel(partyFrame, "PartyTitleLabel", UDim2.new(0.5,0,0.05,0), UDim2.new(0.9,0,0.08,0), "���� ��Ƽ", Vector2.new(0.5,0))

	local partySlotsContainer = Instance.new("Frame")
	partySlotsContainer.Name = "PartySlotsContainer"
	partySlotsContainer.Parent = partyFrame
	partySlotsContainer.BackgroundTransparency = 1
	partySlotsContainer.Position = UDim2.new(0.5, 0, 0.15, 0)
	partySlotsContainer.AnchorPoint = Vector2.new(0.5, 0)
	partySlotsContainer.Size = UDim2.new(0.9, 0, 0.8, 0)

	local partySlotsLayout = Instance.new("UIListLayout")
	partySlotsLayout.Padding = UDim.new(0, 10)
	partySlotsLayout.FillDirection = Enum.FillDirection.Vertical
	partySlotsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	partySlotsLayout.Parent = partySlotsContainer
	print("CompanionUIBuilder: PartyFrame ������")

	for i = 1, 3 do
		local slotTemplate = GuiUtils.CreateFrame(partySlotsContainer, "PartySlot_"..i,
			UDim2.new(0.5, 0, 0, 0), UDim2.new(0.9, 0, 0.2, 0),
			Vector2.new(0.5,0), Color3.fromRGB(30,40,50),0, partyFrame.ZIndex+1)
		slotTemplate.LayoutOrder = i
		Instance.new("UICorner", slotTemplate).CornerRadius = cornerRadius

		local slotImage = GuiUtils.CreateImageLabel(slotTemplate, "SlotPlayerImage", 
			UDim2.new(0.2, 0, 0.5, 0), UDim2.new(0, 40, 0, 40), 
			Vector2.new(0.5, 0.5), "", Enum.ScaleType.Fit, slotTemplate.ZIndex + 1)
		slotImage.BackgroundColor3 = Color3.fromRGB(20,20,25)
		slotImage.BackgroundTransparency = 0.5
		Instance.new("UICorner", slotImage).CornerRadius = UDim.new(0,4)

		GuiUtils.CreateTextLabel(slotTemplate, "CompanionNameLabel", 
			UDim2.new(0.6,0,0.5,0), UDim2.new(0.55,0,0.6,0), 
			i==1 and "�÷��̾�" or "(�������)",
			Vector2.new(0.5,0.5), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 12)
	end

	local closeButton = GuiUtils.CreateButton(companionFrame, "CloseButton",
		UDim2.new(1, -10, 1, -10), UDim2.new(0, 100, 0, 35),
		Vector2.new(1, 1), "�ݱ�", nil, companionFrame.ZIndex + 2)
	closeButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	Instance.new("UICorner", closeButton).CornerRadius = cornerRadius

	print("CompanionUIBuilder: ���� ���� UI ���� �Ϸ�.")
	return companionFrame
end

return CompanionUIBuilder