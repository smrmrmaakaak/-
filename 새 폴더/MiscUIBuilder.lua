--[[
  MiscUIBuilder (ModuleScript)
  ��Ÿ UI ��ҵ� (���� ���, ����� ����, ����� ��� ��)�� �����մϴ�.
]]
local MiscUIBuilder = {}

function MiscUIBuilder.Build(mainGui, backgroundFrame, framesFolder, GuiUtils)
	print("MiscUIBuilder: ��Ÿ UI ��� ���� ����...")

	local cornerRadius = UDim.new(0, 8)
	local smallCornerRadius = UDim.new(0, 4)

	-- ���� ��� â ������ ����
	local resultsFrame = Instance.new("Frame")
	resultsFrame.Name = "CombatResultsFrame"
	resultsFrame.Parent = backgroundFrame -- BackgroundFrame �Ʒ��� ��ġ (�˾� ����)
	resultsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	resultsFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	resultsFrame.Size = UDim2.new(0.4, 0, 0.5, 0)
	resultsFrame.BackgroundColor3 = Color3.fromRGB(50, 60, 50)
	resultsFrame.BorderColor3 = Color3.fromRGB(180, 200, 180)
	resultsFrame.BorderSizePixel = 2
	resultsFrame.Visible = false
	resultsFrame.ZIndex = 200 -- �ٸ� UI ���� ���̵���
	Instance.new("UICorner", resultsFrame).CornerRadius = cornerRadius
	print("MiscUIBuilder: CombatResultsFrame ������")

	local resultsTitle = GuiUtils.CreateTextLabel(resultsFrame, "ResultsTitle",
		UDim2.new(0.5, 0, 0.1, 0), UDim2.new(0.8, 0, 0.15, 0),
		"���� ���", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 22, Color3.fromRGB(255, 255, 180), Enum.Font.SourceSansBold)
	print("MiscUIBuilder: CombatResultsFrame Title ������")

	local goldRewardLabel = GuiUtils.CreateTextLabel(resultsFrame, "GoldRewardLabel",
		UDim2.new(0.1, 0, 0.3, 0), UDim2.new(0.8, 0, 0.1, 0),
		"ȹ�� ���: 0", Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 16)
	print("MiscUIBuilder: CombatResultsFrame GoldRewardLabel ������")

	local expRewardLabel = GuiUtils.CreateTextLabel(resultsFrame, "ExpRewardLabel",
		UDim2.new(0.1, 0, 0.4, 0), UDim2.new(0.8, 0, 0.1, 0),
		"ȹ�� ����ġ: 0", Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 16)
	print("MiscUIBuilder: CombatResultsFrame ExpRewardLabel ������")

	local resultsItemList = Instance.new("ScrollingFrame")
	resultsItemList.Name = "ResultsItemList"
	resultsItemList.Parent = resultsFrame
	resultsItemList.AnchorPoint = Vector2.new(0.5, 0)
	resultsItemList.Position = UDim2.new(0.5, 0, 0.55, 0)
	resultsItemList.Size = UDim2.new(0.8, 0, 0.3, 0)
	resultsItemList.BackgroundColor3 = Color3.fromRGB(40, 50, 40)
	resultsItemList.BorderSizePixel = 1
	resultsItemList.CanvasSize = UDim2.new(0, 0, 0, 0)
	resultsItemList.ScrollBarThickness = 6
	Instance.new("UICorner", resultsItemList).CornerRadius = smallCornerRadius
	print("MiscUIBuilder: CombatResultsFrame ItemList ������")
	local resultsListLayout = Instance.new("UIListLayout")
	resultsListLayout.Parent = resultsItemList
	resultsListLayout.Padding = UDim.new(0, 3)
	resultsListLayout.FillDirection = Enum.FillDirection.Vertical
	resultsListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	resultsListLayout.SortOrder = Enum.SortOrder.LayoutOrder

	local closeResultsButton = Instance.new("TextButton")
	closeResultsButton.Name = "CloseResultsButton"
	closeResultsButton.Parent = resultsFrame
	closeResultsButton.AnchorPoint = Vector2.new(0.5, 1)
	closeResultsButton.Position = UDim2.new(0.5, 0, 0.95, 0)
	closeResultsButton.Size = UDim2.new(0.4, 0, 0.1, 0)
	closeResultsButton.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
	closeResultsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeResultsButton.TextScaled = true
	closeResultsButton.Font = Enum.Font.SourceSansBold
	closeResultsButton.Text = "Ȯ��"
	closeResultsButton.BorderSizePixel = 0
	closeResultsButton.ZIndex = resultsFrame.ZIndex + 1
	Instance.new("UICorner", closeResultsButton).CornerRadius = cornerRadius
	print("MiscUIBuilder: CombatResultsFrame CloseButton ������")

	-- ����� ���� ������ ����
	local huntingGroundFrame = Instance.new("Frame")
	huntingGroundFrame.Name = "HuntingGroundSelectionFrame"
	huntingGroundFrame.Parent = framesFolder -- Frames ���� �Ʒ��� ��ġ
	huntingGroundFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	huntingGroundFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	huntingGroundFrame.Size = UDim2.new(0.5, 0, 0.7, 0)
	huntingGroundFrame.BackgroundColor3 = Color3.fromRGB(50, 60, 70)
	huntingGroundFrame.BorderColor3 = Color3.fromRGB(180, 190, 200)
	huntingGroundFrame.BorderSizePixel = 2
	huntingGroundFrame.Visible = false
	huntingGroundFrame.ZIndex = 4
	Instance.new("UICorner", huntingGroundFrame).CornerRadius = cornerRadius
	print("MiscUIBuilder: HuntingGroundSelectionFrame ������")

	GuiUtils.CreateTextLabel(huntingGroundFrame, "TitleLabel", UDim2.new(0.5, 0, 0.05, 0), UDim2.new(0.9, 0, 0.1, 0), "����� ���� (���� ����)", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 20)

	local groundListFrame = Instance.new("ScrollingFrame")
	groundListFrame.Name = "GroundList"
	groundListFrame.Parent = huntingGroundFrame
	groundListFrame.AnchorPoint = Vector2.new(0.5, 0)
	groundListFrame.Position = UDim2.new(0.5, 0, 0.15, 0)
	groundListFrame.Size = UDim2.new(0.9, 0, 0.7, 0)
	groundListFrame.BackgroundColor3 = Color3.fromRGB(40, 50, 60)
	groundListFrame.BorderSizePixel = 1
	groundListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	groundListFrame.ScrollBarThickness = 8
	Instance.new("UICorner", groundListFrame).CornerRadius = cornerRadius
	print("MiscUIBuilder: GroundList ScrollingFrame ������")

	local backButton = Instance.new("TextButton")
	backButton.Name = "BackButton"
	backButton.Parent = huntingGroundFrame
	backButton.AnchorPoint = Vector2.new(0.5, 1)
	backButton.Position = UDim2.new(0.5, 0, 0.95, 0)
	backButton.Size = UDim2.new(0.3, 0, 0.1, 0)
	backButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	backButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	backButton.TextScaled = true
	backButton.Font = Enum.Font.SourceSansBold
	backButton.Text = "�ڷΰ���"
	backButton.BorderSizePixel = 0
	backButton.ZIndex = 5
	Instance.new("UICorner", backButton).CornerRadius = cornerRadius
	print("MiscUIBuilder: HuntingGroundSelectionFrame BackButton ������")

	-- ����� ��Ʈ�� ��� ��ư
	local toggleMobileControlsButton = Instance.new("TextButton")
	toggleMobileControlsButton.Name = "ToggleMobileControlsButton"
	toggleMobileControlsButton.Parent = backgroundFrame -- BackgroundFrame �ٷ� �Ʒ�
	toggleMobileControlsButton.Size = UDim2.new(0, 100, 0, 30)
	toggleMobileControlsButton.AnchorPoint = Vector2.new(1, 0)
	toggleMobileControlsButton.Position = UDim2.new(0.98, 0, 0.02, 0)
	toggleMobileControlsButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	toggleMobileControlsButton.TextColor3 = Color3.fromRGB(220, 220, 220)
	toggleMobileControlsButton.Text = "Ű�е� �����"
	toggleMobileControlsButton.Font = Enum.Font.SourceSansBold
	toggleMobileControlsButton.TextSize = 12
	toggleMobileControlsButton.ZIndex = 200
	toggleMobileControlsButton.Visible = false
	toggleMobileControlsButton.Active = true
	toggleMobileControlsButton.Draggable = true
	Instance.new("UICorner", toggleMobileControlsButton).CornerRadius = smallCornerRadius
	print("MiscUIBuilder: ToggleMobileControlsButton ������")

	-- ��ų ���� ������ (CombatUIBuilder���� �Űܿ�)
	local skillSelectionFrame = Instance.new("Frame")
	skillSelectionFrame.Name = "SkillSelectionFrame"
	skillSelectionFrame.Parent = backgroundFrame -- BackgroundFrame �Ʒ��� ��ġ (�˾� ����)
	skillSelectionFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	skillSelectionFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	skillSelectionFrame.Size = UDim2.new(0.5, 0, 0.6, 0)
	skillSelectionFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
	skillSelectionFrame.BorderColor3 = Color3.fromRGB(180, 180, 210)
	skillSelectionFrame.BorderSizePixel = 2
	skillSelectionFrame.Visible = false
	skillSelectionFrame.ZIndex = 153 -- �ٸ� UI ���� ���̵��� ZIndex ����
	Instance.new("UICorner", skillSelectionFrame).CornerRadius = cornerRadius
	print("MiscUIBuilder: SkillSelectionFrame ������")
	GuiUtils.CreateTextLabel(skillSelectionFrame, "TitleLabel", UDim2.new(0.5, 0, 0.05, 0), UDim2.new(0.9, 0, 0.1, 0), "��ų ����", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 18)
	local skillListFrame = Instance.new("ScrollingFrame")
	skillListFrame.Name = "SkillList"
	skillListFrame.Parent = skillSelectionFrame
	skillListFrame.AnchorPoint = Vector2.new(0.5, 0)
	skillListFrame.Position = UDim2.new(0.5, 0, 0.15, 0)
	skillListFrame.Size = UDim2.new(0.9, 0, 0.7, 0)
	skillListFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
	skillListFrame.BorderSizePixel = 1
	skillListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	skillListFrame.ScrollBarThickness = 8
	Instance.new("UICorner", skillListFrame).CornerRadius = cornerRadius
	print("MiscUIBuilder: SkillList ScrollingFrame ������")
	local listLayout = Instance.new("UIListLayout")
	listLayout.Parent = skillListFrame
	listLayout.Padding = UDim.new(0, 5)
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	print("MiscUIBuilder: SkillList UIListLayout ������")
	local cancelSkillButton = Instance.new("TextButton")
	cancelSkillButton.Name = "CancelSkillButton"
	cancelSkillButton.Parent = skillSelectionFrame
	cancelSkillButton.AnchorPoint = Vector2.new(0.5, 1)
	cancelSkillButton.Position = UDim2.new(0.5, 0, 0.95, 0)
	cancelSkillButton.Size = UDim2.new(0.3, 0, 0.1, 0)
	cancelSkillButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	cancelSkillButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	cancelSkillButton.TextScaled = true
	cancelSkillButton.Font = Enum.Font.SourceSansBold
	cancelSkillButton.Text = "���"
	cancelSkillButton.BorderSizePixel = 0
	cancelSkillButton.ZIndex = skillSelectionFrame.ZIndex + 1
	Instance.new("UICorner", cancelSkillButton).CornerRadius = cornerRadius
	print("MiscUIBuilder: CancelSkillButton ������")

	-- ���� ������ ���� ������ (CombatUIBuilder���� �Űܿ�)
	local combatItemSelectionFrame = Instance.new("Frame")
	combatItemSelectionFrame.Name = "CombatItemSelectionFrame"
	combatItemSelectionFrame.Parent = backgroundFrame -- BackgroundFrame �Ʒ��� ��ġ (�˾� ����)
	combatItemSelectionFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	combatItemSelectionFrame.Position = UDim2.new(0.5, 0, 0.5, 0) -- ȭ�� �߾�
	combatItemSelectionFrame.Size = UDim2.new(0.5, 0, 0.6, 0) -- ��ų ���� â�� ������ ũ��
	combatItemSelectionFrame.BackgroundColor3 = Color3.fromRGB(65, 45, 45) -- �ణ �ٸ� ����
	combatItemSelectionFrame.BorderColor3 = Color3.fromRGB(210, 180, 180)
	combatItemSelectionFrame.BorderSizePixel = 2
	combatItemSelectionFrame.Visible = false
	combatItemSelectionFrame.ZIndex = 153 -- �ٸ� UI ���� ���̵���
	Instance.new("UICorner", combatItemSelectionFrame).CornerRadius = cornerRadius
	print("MiscUIBuilder: CombatItemSelectionFrame ������")

	GuiUtils.CreateTextLabel(combatItemSelectionFrame, "TitleLabel", UDim2.new(0.5, 0, 0.05, 0), UDim2.new(0.9, 0, 0.1, 0), "������ ����", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 18)

	local combatItemListFrame = Instance.new("ScrollingFrame")
	combatItemListFrame.Name = "ItemList" -- CombatUIManager ���� �� �̸����� ã��
	combatItemListFrame.Parent = combatItemSelectionFrame
	combatItemListFrame.AnchorPoint = Vector2.new(0.5, 0)
	combatItemListFrame.Position = UDim2.new(0.5, 0, 0.15, 0)
	combatItemListFrame.Size = UDim2.new(0.9, 0, 0.7, 0)
	combatItemListFrame.BackgroundColor3 = Color3.fromRGB(50, 30, 30)
	combatItemListFrame.BorderSizePixel = 1
	combatItemListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	combatItemListFrame.ScrollBarThickness = 8
	Instance.new("UICorner", combatItemListFrame).CornerRadius = cornerRadius
	print("MiscUIBuilder: Combat ItemList ScrollingFrame ������")

	local combatItemListLayout = Instance.new("UIGridLayout") -- �׸��� ���̾ƿ� ��� (�κ��丮ó��)
	combatItemListLayout.Parent = combatItemListFrame
	combatItemListLayout.CellPadding = UDim2.new(0, 5, 0, 5)
	combatItemListLayout.CellSize = UDim2.new(0, 64, 0, 64) -- �κ��丮 ���԰� ������ ũ��
	combatItemListLayout.StartCorner = Enum.StartCorner.TopLeft
	combatItemListLayout.FillDirection = Enum.FillDirection.Horizontal
	combatItemListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	combatItemListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	combatItemListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	print("MiscUIBuilder: Combat ItemList UIGridLayout ������")

	local cancelItemButton = Instance.new("TextButton")
	cancelItemButton.Name = "CancelItemButton"
	cancelItemButton.Parent = combatItemSelectionFrame
	cancelItemButton.AnchorPoint = Vector2.new(0.5, 1)
	cancelItemButton.Position = UDim2.new(0.5, 0, 0.95, 0)
	cancelItemButton.Size = UDim2.new(0.3, 0, 0.1, 0)
	cancelItemButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	cancelItemButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	cancelItemButton.TextScaled = true
	cancelItemButton.Font = Enum.Font.SourceSansBold
	cancelItemButton.Text = "���"
	cancelItemButton.BorderSizePixel = 0
	cancelItemButton.ZIndex = combatItemSelectionFrame.ZIndex + 1
	Instance.new("UICorner", cancelItemButton).CornerRadius = cornerRadius
	print("MiscUIBuilder: CancelItemButton ������")


	print("MiscUIBuilder: ��Ÿ UI ��� ���� �Ϸ�.")
end

return MiscUIBuilder
