--[[
  SkillShopUIBuilder (ModuleScript)
  스킬 상점 창 UI를 생성합니다.
]]
local SkillShopUIBuilder = {}

function SkillShopUIBuilder.Build(mainGui, backgroundFrame, framesFolder, GuiUtils)
	print("SkillShopUIBuilder: 스킬 상점 UI 생성 시작...")

	local cornerRadius = UDim.new(0, 8)

	local skillShopFrame = Instance.new("Frame")
	skillShopFrame.Name = "SkillShopFrame"
	skillShopFrame.Parent = backgroundFrame -- BackgroundFrame 아래에 배치 (팝업 형태)
	skillShopFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	skillShopFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	skillShopFrame.Size = UDim2.new(0.7, 0, 0.75, 0)
	skillShopFrame.BackgroundColor3 = Color3.fromRGB(60, 60, 90)
	skillShopFrame.BorderColor3 = Color3.fromRGB(190, 190, 230)
	skillShopFrame.BorderSizePixel = 2
	skillShopFrame.Visible = false
	skillShopFrame.ZIndex = 5
	Instance.new("UICorner", skillShopFrame).CornerRadius = cornerRadius
	print("SkillShopUIBuilder: SkillShopFrame 생성됨")

	GuiUtils.CreateTextLabel(skillShopFrame, "TitleLabel",
		UDim2.new(0.5, 0, 0.05, 0), UDim2.new(0.9, 0, 0.1, 0),
		"스킬 상점", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 20)

	local skillList = Instance.new("ScrollingFrame")
	skillList.Name = "SkillList"
	skillList.Size = UDim2.new(0.4, 0, 0.7, 0)
	skillList.Position = UDim2.new(0.05, 0, 0.15, 0)
	skillList.AnchorPoint = Vector2.new(0, 0)
	skillList.BackgroundColor3 = Color3.fromRGB(45, 45, 70)
	skillList.BorderSizePixel = 1
	skillList.CanvasSize = UDim2.new(0, 0, 0, 0)
	skillList.ScrollBarThickness = 8
	skillList.Parent = skillShopFrame
	Instance.new("UICorner", skillList).CornerRadius = cornerRadius
	local skillListLayout = Instance.new("UIListLayout")
	skillListLayout.Padding = UDim.new(0, 3)
	skillListLayout.FillDirection = Enum.FillDirection.Vertical
	skillListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	skillListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	skillListLayout.Parent = skillList
	print("SkillShopUIBuilder: SkillShop SkillList 생성됨")

	local detailsFrame = Instance.new("Frame")
	detailsFrame.Name = "DetailsFrame"
	detailsFrame.Size = UDim2.new(0.45, 0, 0.7, 0)
	detailsFrame.Position = UDim2.new(0.5, 0, 0.15, 0)
	detailsFrame.AnchorPoint = Vector2.new(0, 0)
	detailsFrame.BackgroundTransparency = 1
	detailsFrame.Parent = skillShopFrame
	print("SkillShopUIBuilder: SkillShop DetailsFrame 생성됨")

	local skillNameLabel = GuiUtils.CreateTextLabel(detailsFrame, "SkillNameLabel",
		UDim2.new(0.5, 0, 0.1, 0), UDim2.new(0.9, 0, 0.1, 0),
		"스킬 이름", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 18, Color3.new(1,1,1), Enum.Font.SourceSansBold)

	local skillDescriptionLabel = GuiUtils.CreateTextLabel(detailsFrame, "SkillDescriptionLabel",
		UDim2.new(0.05, 0, 0.25, 0), UDim2.new(0.9, 0, 0.3, 0),
		"스킬 설명...", Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Top, 14)
	skillDescriptionLabel.TextWrapped = true

	local skillPriceLabel = GuiUtils.CreateTextLabel(detailsFrame, "SkillPriceLabel",
		UDim2.new(0.5, 0, 0.6, 0), UDim2.new(0.9, 0, 0.1, 0),
		"비용: ??? G", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 16)

	local playerGoldLabel = GuiUtils.CreateTextLabel(detailsFrame, "PlayerGoldLabel",
		UDim2.new(0.5, 0, 0.7, 0), UDim2.new(0.9, 0, 0.1, 0),
		"보유 골드: ??? G", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 14, Color3.fromRGB(255, 230, 150))
	print("SkillShopUIBuilder: SkillShop PlayerGoldLabel 생성됨")

	local learnButton = Instance.new("TextButton")
	learnButton.Name = "LearnButton"
	learnButton.Size = UDim2.new(0.6, 0, 0.1, 0)
	learnButton.Position = UDim2.new(0.5, 0, 0.85, 0)
	learnButton.AnchorPoint = Vector2.new(0.5, 0)
	learnButton.BackgroundColor3 = Color3.fromRGB(80, 150, 80)
	learnButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	learnButton.Text = "배우기"
	learnButton.Font = Enum.Font.SourceSansBold
	learnButton.TextScaled = true
	learnButton.Visible = false
	learnButton.Parent = detailsFrame
	Instance.new("UICorner", learnButton).CornerRadius = cornerRadius
	print("SkillShopUIBuilder: SkillShop LearnButton 생성됨")

	local closeSkillShopButton = Instance.new("TextButton")
	closeSkillShopButton.Name = "CloseButton"
	closeSkillShopButton.Parent = skillShopFrame
	closeSkillShopButton.AnchorPoint = Vector2.new(1, 1)
	closeSkillShopButton.Position = UDim2.new(0.95, 0, 0.95, 0)
	closeSkillShopButton.Size = UDim2.new(0.2, 0, 0.1, 0)
	closeSkillShopButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	closeSkillShopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeSkillShopButton.TextScaled = true
	closeSkillShopButton.Font = Enum.Font.SourceSansBold
	closeSkillShopButton.Text = "닫기"
	closeSkillShopButton.BorderSizePixel = 0
	closeSkillShopButton.ZIndex = 6
	Instance.new("UICorner", closeSkillShopButton).CornerRadius = cornerRadius
	print("SkillShopUIBuilder: SkillShopFrame CloseButton 생성됨")

	print("SkillShopUIBuilder: 스킬 상점 UI 생성 완료.")
end

return SkillShopUIBuilder
