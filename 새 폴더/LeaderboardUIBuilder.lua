-- LeaderboardUIBuilder.lua

local LeaderboardUIBuilder = {}

function LeaderboardUIBuilder.Build(mainGui, backgroundFrame, framesFolder, GuiUtils)
	if not GuiUtils then
		local ModuleManager = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("ModuleManager"))
		GuiUtils = ModuleManager:GetModule("GuiUtils")
		if not GuiUtils then warn("LeaderboardUIBuilder: GuiUtils 로드 실패! (일부 기능에 영향 가능)"); end
	end
	print("LeaderboardUIBuilder: 리더보드 UI 생성 시작 (헤더 직접 생성 방식)...")

	local cornerRadius = UDim.new(0, 8)
	local smallCornerRadius = UDim.new(0, 4)

	local leaderboardFrame = Instance.new("Frame")
	leaderboardFrame.Name = "LeaderboardFrame"
	leaderboardFrame.Parent = backgroundFrame
	leaderboardFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	leaderboardFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	leaderboardFrame.Size = UDim2.new(0.6, 0, 0.75, 0)
	leaderboardFrame.BackgroundColor3 = Color3.fromRGB(45, 55, 65)
	leaderboardFrame.BorderColor3 = Color3.fromRGB(170, 180, 190)
	leaderboardFrame.BorderSizePixel = 2
	leaderboardFrame.Visible = false
	leaderboardFrame.ZIndex = 10
	Instance.new("UICorner", leaderboardFrame).CornerRadius = cornerRadius

	if GuiUtils then
		GuiUtils.CreateTextLabel(leaderboardFrame, "TitleLabel",
			UDim2.new(0.5, 0, 0.05, 0), UDim2.new(0.9, 0, 0.08, 0),
			"리더보드", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 22)
	else
		local titleLabel = Instance.new("TextLabel")
		titleLabel.Name = "TitleLabel"
		titleLabel.Parent = leaderboardFrame
		titleLabel.AnchorPoint = Vector2.new(0.5, 0)
		titleLabel.Position = UDim2.new(0.5, 0, 0.05, 0)
		titleLabel.Size = UDim2.new(0.9, 0, 0.08, 0)
		titleLabel.Text = "리더보드"
		titleLabel.Font = Enum.Font.SourceSansBold
		titleLabel.TextSize = 22
		titleLabel.TextColor3 = Color3.new(1,1,1)
		titleLabel.TextXAlignment = Enum.TextXAlignment.Center
		titleLabel.TextYAlignment = Enum.TextYAlignment.Center
		titleLabel.BackgroundTransparency = 1
	end


	local headerFrame = Instance.new("Frame") -- GuiUtils 대신 직접 생성
	headerFrame.Name = "HeaderFrame"
	headerFrame.Parent = leaderboardFrame
	headerFrame.AnchorPoint = Vector2.new(0, 0)
	headerFrame.Position = UDim2.new(0.05, 0, 0.15, 0)
	headerFrame.Size = UDim2.new(0.9, 0, 0.07, 0)
	headerFrame.BackgroundColor3 = Color3.fromRGB(55, 65, 75)
	headerFrame.BackgroundTransparency = 0
	headerFrame.BorderSizePixel = 0
	headerFrame.ZIndex = leaderboardFrame.ZIndex + 1
	Instance.new("UICorner", headerFrame).CornerRadius = smallCornerRadius

	-- ##### HeaderFrame 내부 레이블 직접 생성 및 UIListLayout 제거 #####
	-- local headerLayout = Instance.new("UIListLayout") -- 이 부분 제거
	-- headerLayout.FillDirection = Enum.FillDirection.Horizontal
	-- headerLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	-- headerLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	-- headerLayout.Padding = UDim.new(0,0)
	-- headerLayout.Parent = headerFrame

	local goldWidthScale = 0.30
	local levelWidthScale = 0.15
	local nameWidthScale = 0.40
	local rankWidthScale = 0.15
	local currentHeaderXScale = 0

	local goldHeader = Instance.new("TextLabel")
	goldHeader.Name = "GoldHeader"
	goldHeader.Parent = headerFrame
	goldHeader.AnchorPoint = Vector2.new(0,0)
	goldHeader.Position = UDim2.new(currentHeaderXScale, 0, 0, 0)
	goldHeader.Size = UDim2.new(goldWidthScale, 0, 1, 0)
	goldHeader.Text = "골드"
	goldHeader.Font = Enum.Font.SourceSansBold
	goldHeader.TextSize = 14
	goldHeader.TextColor3 = Color3.new(1,1,1)
	goldHeader.TextXAlignment = Enum.TextXAlignment.Center
	goldHeader.TextYAlignment = Enum.TextYAlignment.Center
	goldHeader.BackgroundTransparency = 1
	currentHeaderXScale = currentHeaderXScale + goldWidthScale

	local levelHeader = Instance.new("TextLabel")
	levelHeader.Name = "LevelHeader"
	levelHeader.Parent = headerFrame
	levelHeader.AnchorPoint = Vector2.new(0,0)
	levelHeader.Position = UDim2.new(currentHeaderXScale, 0, 0, 0)
	levelHeader.Size = UDim2.new(levelWidthScale, 0, 1, 0)
	levelHeader.Text = "레벨"
	levelHeader.Font = Enum.Font.SourceSansBold
	levelHeader.TextSize = 14
	levelHeader.TextColor3 = Color3.new(1,1,1)
	levelHeader.TextXAlignment = Enum.TextXAlignment.Center
	levelHeader.TextYAlignment = Enum.TextYAlignment.Center
	levelHeader.BackgroundTransparency = 1
	currentHeaderXScale = currentHeaderXScale + levelWidthScale

	local nameHeader = Instance.new("TextLabel")
	nameHeader.Name = "NameHeader"
	nameHeader.Parent = headerFrame
	nameHeader.AnchorPoint = Vector2.new(0,0)
	nameHeader.Position = UDim2.new(currentHeaderXScale, 0, 0, 0)
	nameHeader.Size = UDim2.new(nameWidthScale, 0, 1, 0)
	nameHeader.Text = "이름"
	nameHeader.Font = Enum.Font.SourceSansBold
	nameHeader.TextSize = 14
	nameHeader.TextColor3 = Color3.new(1,1,1)
	nameHeader.TextXAlignment = Enum.TextXAlignment.Center
	nameHeader.TextYAlignment = Enum.TextYAlignment.Center
	nameHeader.BackgroundTransparency = 1
	currentHeaderXScale = currentHeaderXScale + nameWidthScale

	local rankHeader = Instance.new("TextLabel")
	rankHeader.Name = "RankHeader"
	rankHeader.Parent = headerFrame
	rankHeader.AnchorPoint = Vector2.new(0,0)
	rankHeader.Position = UDim2.new(currentHeaderXScale, 0, 0, 0)
	rankHeader.Size = UDim2.new(rankWidthScale, 0, 1, 0)
	rankHeader.Text = "순위"
	rankHeader.Font = Enum.Font.SourceSansBold
	rankHeader.TextSize = 14
	rankHeader.TextColor3 = Color3.new(1,1,1)
	rankHeader.TextXAlignment = Enum.TextXAlignment.Center
	rankHeader.TextYAlignment = Enum.TextYAlignment.Center
	rankHeader.BackgroundTransparency = 1
	-- #####################################################

	local playerListFrame = Instance.new("ScrollingFrame")
	playerListFrame.Name = "PlayerListFrame"
	playerListFrame.Parent = leaderboardFrame
	playerListFrame.Position = UDim2.new(0.05, 0, 0.23, 0)
	playerListFrame.Size = UDim2.new(0.9, 0, 0.65, 0)
	playerListFrame.AnchorPoint = Vector2.new(0,0)
	playerListFrame.BackgroundColor3 = Color3.fromRGB(40, 50, 60)
	playerListFrame.BorderSizePixel = 1
	playerListFrame.BorderColor3 = Color3.fromRGB(160, 170, 180)
	playerListFrame.ScrollingDirection = Enum.ScrollingDirection.Y
	playerListFrame.CanvasSize = UDim2.new(0,0,0,0)
	playerListFrame.ScrollBarThickness = 6
	Instance.new("UICorner", playerListFrame).CornerRadius = smallCornerRadius

	local playerListLayout = Instance.new("UIListLayout")
	playerListLayout.Padding = UDim.new(0, 3)
	playerListLayout.FillDirection = Enum.FillDirection.Vertical
	playerListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	playerListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	playerListLayout.Parent = playerListFrame

	local playerEntryTemplate = Instance.new("Frame")
	playerEntryTemplate.Name = "PlayerEntryTemplate"
	playerEntryTemplate.Parent = playerListFrame
	playerEntryTemplate.Size = UDim2.new(1, 0, 0, 30)
	playerEntryTemplate.BackgroundTransparency = 1
	playerEntryTemplate.Visible = false

	local currentXScaleEntry = 0
	local entryLabelHeightScale = 1

	local goldLabel_T = Instance.new("TextLabel")
	goldLabel_T.Name = "GoldLabel"
	goldLabel_T.Parent = playerEntryTemplate
	goldLabel_T.AnchorPoint = Vector2.new(0,0)
	goldLabel_T.Position = UDim2.new(currentXScaleEntry, 0, 0, 0)
	goldLabel_T.Size = UDim2.new(goldWidthScale, 0, entryLabelHeightScale, 0)
	goldLabel_T.Text = "0 G"; goldLabel_T.Font = Enum.Font.SourceSans; goldLabel_T.TextSize = 12; goldLabel_T.TextColor3 = Color3.new(1,1,1); goldLabel_T.TextXAlignment = Enum.TextXAlignment.Right; goldLabel_T.TextYAlignment = Enum.TextYAlignment.Center; goldLabel_T.BackgroundTransparency = 1; goldLabel_T.BorderSizePixel = 0
	currentXScaleEntry = currentXScaleEntry + goldWidthScale

	local levelLabel_T = Instance.new("TextLabel")
	levelLabel_T.Name = "LevelLabel"
	levelLabel_T.Parent = playerEntryTemplate
	levelLabel_T.AnchorPoint = Vector2.new(0,0)
	levelLabel_T.Position = UDim2.new(currentXScaleEntry, 0, 0, 0)
	levelLabel_T.Size = UDim2.new(levelWidthScale, 0, entryLabelHeightScale, 0)
	levelLabel_T.Text = "Lv.0"; levelLabel_T.Font = Enum.Font.SourceSans; levelLabel_T.TextSize = 12; levelLabel_T.TextColor3 = Color3.new(1,1,1); levelLabel_T.TextXAlignment = Enum.TextXAlignment.Center; levelLabel_T.TextYAlignment = Enum.TextYAlignment.Center; levelLabel_T.BackgroundTransparency = 1; levelLabel_T.BorderSizePixel = 0
	currentXScaleEntry = currentXScaleEntry + levelWidthScale

	local nameLabel_T = Instance.new("TextLabel")
	nameLabel_T.Name = "NameLabel"
	nameLabel_T.Parent = playerEntryTemplate
	nameLabel_T.AnchorPoint = Vector2.new(0,0)
	nameLabel_T.Position = UDim2.new(currentXScaleEntry, 0, 0, 0)
	nameLabel_T.Size = UDim2.new(nameWidthScale, 0, entryLabelHeightScale, 0)
	nameLabel_T.Text = "Player"; nameLabel_T.Font = Enum.Font.SourceSans; nameLabel_T.TextSize = 12; nameLabel_T.TextColor3 = Color3.new(1,1,1); nameLabel_T.TextXAlignment = Enum.TextXAlignment.Left; nameLabel_T.TextYAlignment = Enum.TextYAlignment.Center; nameLabel_T.BackgroundTransparency = 1; nameLabel_T.BorderSizePixel = 0
	currentXScaleEntry = currentXScaleEntry + nameWidthScale

	local rankLabel_T = Instance.new("TextLabel")
	rankLabel_T.Name = "RankLabel"
	rankLabel_T.Parent = playerEntryTemplate
	rankLabel_T.AnchorPoint = Vector2.new(0,0)
	rankLabel_T.Position = UDim2.new(currentXScaleEntry, 0, 0, 0)
	rankLabel_T.Size = UDim2.new(rankWidthScale, 0, entryLabelHeightScale, 0)
	rankLabel_T.Text = "0"; rankLabel_T.Font = Enum.Font.SourceSans; rankLabel_T.TextSize = 12; rankLabel_T.TextColor3 = Color3.new(1,1,1); rankLabel_T.TextXAlignment = Enum.TextXAlignment.Center; rankLabel_T.TextYAlignment = Enum.TextYAlignment.Center; rankLabel_T.BackgroundTransparency = 1; rankLabel_T.BorderSizePixel = 0

	if GuiUtils then -- GuiUtils가 로드되었을 경우에만 사용
		local closeButton = GuiUtils.CreateButton(leaderboardFrame, "CloseButton",
			UDim2.new(0.5, 0, 0.92, 0), UDim2.new(0.3, 0, 0.07, 0),
			Vector2.new(0.5, 0), "닫기", nil, leaderboardFrame.ZIndex + 1)
		if closeButton then
			closeButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
			Instance.new("UICorner", closeButton).CornerRadius = cornerRadius
		end
	end

	print("LeaderboardUIBuilder: 리더보드 UI 생성 완료 (헤더 및 템플릿 내부 직접 생성).")
	return leaderboardFrame
end

return LeaderboardUIBuilder