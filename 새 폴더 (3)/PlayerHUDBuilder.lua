-- PlayerHUDBuilder.lua

local PlayerHUDBuilder = {}

function PlayerHUDBuilder.Build(mainGui, backgroundFrame, framesFolder, GuiUtils)
	print("PlayerHUDBuilder: �÷��̾� HUD UI ���� ����...")

	local cornerRadius = UDim.new(0, 8)
	local smallCornerRadius = UDim.new(0, 4)

	local playerHUD = Instance.new("Frame")
	playerHUD.Name = "PlayerHUD"
	playerHUD.Parent = backgroundFrame
	playerHUD.AnchorPoint = Vector2.new(0, 0.5)
	playerHUD.Position = UDim2.new(0.02, 0, 0.5, 0)
	playerHUD.Size = UDim2.new(0.25, 0, 0.3, 0)
	playerHUD.BackgroundColor3 = Color3.fromRGB(40, 40, 60)
	playerHUD.BorderColor3 = Color3.fromRGB(150, 150, 200)
	playerHUD.BorderSizePixel = 1
	playerHUD.Visible = true
	playerHUD.ZIndex = 151
	playerHUD.Active = true
	playerHUD.Draggable = true
	Instance.new("UICorner", playerHUD).CornerRadius = cornerRadius
	print("PlayerHUDBuilder: PlayerHUD ������")

	local yPos = 0.05
	local yInc = 0.15
	GuiUtils.CreateTextLabel(playerHUD, "NameLabel", UDim2.new(0.05, 0, yPos, 0), UDim2.new(0.9, 0, yInc, 0), "Player Name", Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Top, 16)
	yPos = yPos + yInc
	GuiUtils.CreateTextLabel(playerHUD, "LevelLabel", UDim2.new(0.05, 0, yPos, 0), UDim2.new(0.4, 0, yInc, 0), "Lv. 1", Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 14)
	GuiUtils.CreateTextLabel(playerHUD, "GoldLabel", UDim2.new(0.5, 0, yPos, 0), UDim2.new(0.45, 0, yInc, 0), "Gold: 0", Vector2.new(0, 0), Enum.TextXAlignment.Right, Enum.TextYAlignment.Center, 14)
	yPos = yPos + yInc
	GuiUtils.CreateTextLabel(playerHUD, "HPLabel", UDim2.new(0.05, 0, yPos, 0), UDim2.new(0.9, 0, yInc, 0), "HP: 100 / 100", Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 14)
	yPos = yPos + yInc
	local mpBarBG = GuiUtils.CreateResourceBar(playerHUD, "MP", UDim2.new(0.05, 0, yPos, 0), UDim2.new(0.9, 0, 0.1, 0), Vector2.new(0, 0), Color3.fromRGB(80, 80, 200), Color3.fromRGB(255, 255, 255))
	if mpBarBG then Instance.new("UICorner", mpBarBG).CornerRadius = smallCornerRadius end
	yPos = yPos + 0.1 + 0.02
	local expBarBG = GuiUtils.CreateResourceBar(playerHUD, "Exp", UDim2.new(0.05, 0, yPos, 0), UDim2.new(0.9, 0, 0.1, 0), Vector2.new(0, 0), Color3.fromRGB(100, 200, 255), Color3.fromRGB(0, 0, 0))
	if expBarBG then Instance.new("UICorner", expBarBG).CornerRadius = smallCornerRadius end
	yPos = yPos + 0.1 + 0.04

	local hudButtonContainer = Instance.new("Frame")
	hudButtonContainer.Name = "HudButtonContainer"
	hudButtonContainer.Size = UDim2.new(1, -10, 0, 30)
	hudButtonContainer.Position = UDim2.new(0.5, 0, yPos, 0)
	hudButtonContainer.AnchorPoint = Vector2.new(0.5, 0)
	hudButtonContainer.BackgroundTransparency = 1
	hudButtonContainer.Parent = playerHUD
	local hudButtonLayout = Instance.new("UIListLayout")
	hudButtonLayout.FillDirection = Enum.FillDirection.Horizontal
	hudButtonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	hudButtonLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	hudButtonLayout.Padding = UDim.new(0, 2) -- << ��ư ���� �ణ ����
	hudButtonLayout.Parent = hudButtonContainer
	print("PlayerHUDBuilder: HudButtonContainer ������")

	local hudInfoButton = Instance.new("TextButton")
	hudInfoButton.Name = "HudInfoButton"
	hudInfoButton.Size = UDim2.new(0, 45, 1, 0) -- << ��ư ũ�� �ణ ����
	hudInfoButton.BackgroundColor3 = Color3.fromRGB(100, 100, 120)
	hudInfoButton.TextColor3 = Color3.fromRGB(230, 230, 255)
	hudInfoButton.Text = "����"
	hudInfoButton.Font = Enum.Font.SourceSansBold
	hudInfoButton.TextSize = 12 -- << �ؽ�Ʈ ũ�� �ణ ����
	hudInfoButton.Parent = hudButtonContainer
	Instance.new("UICorner", hudInfoButton).CornerRadius = smallCornerRadius

	local hudStatsButton = Instance.new("TextButton")
	hudStatsButton.Name = "HudStatsButton"
	hudStatsButton.Size = UDim2.new(0, 45, 1, 0)
	hudStatsButton.BackgroundColor3 = Color3.fromRGB(120, 100, 100)
	hudStatsButton.TextColor3 = Color3.fromRGB(255, 230, 230)
	hudStatsButton.Text = "����"
	hudStatsButton.Font = Enum.Font.SourceSansBold
	hudStatsButton.TextSize = 12
	hudStatsButton.Visible = false
	hudStatsButton.Parent = hudButtonContainer
	Instance.new("UICorner", hudStatsButton).CornerRadius = smallCornerRadius

	local hudInventoryButton = Instance.new("TextButton")
	hudInventoryButton.Name = "HudInventoryButton"
	hudInventoryButton.Size = UDim2.new(0, 45, 1, 0)
	hudInventoryButton.BackgroundColor3 = Color3.fromRGB(100, 120, 100)
	hudInventoryButton.TextColor3 = Color3.fromRGB(230, 255, 230)
	hudInventoryButton.Text = "����"
	hudInventoryButton.Font = Enum.Font.SourceSansBold
	hudInventoryButton.TextSize = 12
	hudInventoryButton.Visible = false
	hudInventoryButton.Parent = hudButtonContainer
	Instance.new("UICorner", hudInventoryButton).CornerRadius = smallCornerRadius
	print("PlayerHUDBuilder: HudInventoryButton ������")

	local hudEquipmentButton = Instance.new("TextButton")
	hudEquipmentButton.Name = "HudEquipmentButton"
	hudEquipmentButton.Size = UDim2.new(0, 45, 1, 0)
	hudEquipmentButton.BackgroundColor3 = Color3.fromRGB(120, 100, 120)
	hudEquipmentButton.TextColor3 = Color3.fromRGB(255, 230, 255)
	hudEquipmentButton.Text = "���"
	hudEquipmentButton.Font = Enum.Font.SourceSansBold
	hudEquipmentButton.TextSize = 12
	hudEquipmentButton.Visible = false
	hudEquipmentButton.Parent = hudButtonContainer
	Instance.new("UICorner", hudEquipmentButton).CornerRadius = smallCornerRadius
	print("PlayerHUDBuilder: HudEquipmentButton ������")

	local hudCompanionButton = Instance.new("TextButton")
	hudCompanionButton.Name = "HudCompanionButton"
	hudCompanionButton.Size = UDim2.new(0, 45, 1, 0)
	hudCompanionButton.BackgroundColor3 = Color3.fromRGB(100, 120, 120)
	hudCompanionButton.TextColor3 = Color3.fromRGB(230, 255, 255)
	hudCompanionButton.Text = "����"
	hudCompanionButton.Font = Enum.Font.SourceSansBold
	hudCompanionButton.TextSize = 12
	hudCompanionButton.Visible = false
	hudCompanionButton.Parent = hudButtonContainer
	Instance.new("UICorner", hudCompanionButton).CornerRadius = smallCornerRadius
	print("PlayerHUDBuilder: HudCompanionButton ������")

	-- ##### �������� ��ư �߰� #####
	local hudLeaderboardButton = Instance.new("TextButton")
	hudLeaderboardButton.Name = "HudLeaderboardButton"
	hudLeaderboardButton.Size = UDim2.new(0, 45, 1, 0) -- �ٸ� ��ư�� ������ ũ��
	hudLeaderboardButton.BackgroundColor3 = Color3.fromRGB(120, 120, 100) -- �ٸ� ����
	hudLeaderboardButton.TextColor3 = Color3.fromRGB(255, 255, 230)
	hudLeaderboardButton.Text = "��ŷ"
	hudLeaderboardButton.Font = Enum.Font.SourceSansBold
	hudLeaderboardButton.TextSize = 12
	hudLeaderboardButton.Visible = false -- HudInfoButton Ŭ�� �� ���̵��� ����
	hudLeaderboardButton.Parent = hudButtonContainer
	Instance.new("UICorner", hudLeaderboardButton).CornerRadius = smallCornerRadius
	print("PlayerHUDBuilder: HudLeaderboardButton ������")
	-- ###########################

	print("PlayerHUDBuilder: �÷��̾� HUD UI ���� �Ϸ�.")
end

return PlayerHUDBuilder