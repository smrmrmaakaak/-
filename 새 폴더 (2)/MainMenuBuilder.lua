-- MainMenuBuilder.lua

local MainMenuBuilder = {}

function MainMenuBuilder.Build(mainGui, backgroundFrame, framesFolder, GuiUtils)
	print("MainMenuBuilder: ���� �޴� UI ���� ����...")

	local cornerRadius = UDim.new(0, 8)

	local mainMenuFrame = Instance.new("Frame")
	mainMenuFrame.Name = "MainMenu"
	mainMenuFrame.Parent = framesFolder -- Frames ���� �Ʒ��� ��ġ
	mainMenuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainMenuFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainMenuFrame.Size = UDim2.new(0.4, 0, 0.6, 0) -- << ���� �ణ �ø�
	mainMenuFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
	mainMenuFrame.BorderSizePixel = 0
	mainMenuFrame.Visible = false -- �⺻ ����
	mainMenuFrame.ZIndex = 2
	Instance.new("UICorner", mainMenuFrame).CornerRadius = cornerRadius
	print("MainMenuBuilder: MainMenu ������ ������")

	local buttonHeight = 0.15 -- << ��ư ���� ����
	local buttonSpacing = 0.04 -- << ��ư ���� ����
	local currentY = 0.15 -- << ���� Y ��ġ ����
	local buttonWidth = 0.7

	local gameStartButton = Instance.new("TextButton")
	gameStartButton.Name = "GameStartButton"
	gameStartButton.Parent = mainMenuFrame
	gameStartButton.AnchorPoint = Vector2.new(0.5, 0)
	gameStartButton.Position = UDim2.new(0.5, 0, currentY, 0)
	gameStartButton.Size = UDim2.new(buttonWidth, 0, buttonHeight, 0)
	gameStartButton.BackgroundColor3 = Color3.fromRGB(80, 180, 80)
	gameStartButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	gameStartButton.TextScaled = true
	gameStartButton.Font = Enum.Font.SourceSansBold
	gameStartButton.Text = "���� ����"
	gameStartButton.BorderSizePixel = 0
	gameStartButton.ZIndex = 3
	Instance.new("UICorner", gameStartButton).CornerRadius = cornerRadius
	print("MainMenuBuilder: GameStartButton ������")

	currentY = currentY + buttonHeight + buttonSpacing

	local settingsButton = Instance.new("TextButton")
	settingsButton.Name = "SettingsButton"
	settingsButton.Parent = mainMenuFrame
	settingsButton.AnchorPoint = Vector2.new(0.5, 0)
	settingsButton.Position = UDim2.new(0.5, 0, currentY, 0)
	settingsButton.Size = UDim2.new(buttonWidth * 0.8, 0, buttonHeight * 0.8, 0)
	settingsButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	settingsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	settingsButton.TextScaled = true
	settingsButton.Font = Enum.Font.SourceSansBold
	settingsButton.Text = "����"
	settingsButton.BorderSizePixel = 0
	settingsButton.ZIndex = 3
	Instance.new("UICorner", settingsButton).CornerRadius = cornerRadius
	print("MainMenuBuilder: SettingsButton ������")

	currentY = currentY + (buttonHeight * 0.8) + buttonSpacing -- << ���� ��ư Y ��ġ ���

	-- ##### �������� ��ư �߰� #####
	local leaderboardButton = Instance.new("TextButton")
	leaderboardButton.Name = "LeaderboardButton"
	leaderboardButton.Parent = mainMenuFrame
	leaderboardButton.AnchorPoint = Vector2.new(0.5, 0)
	leaderboardButton.Position = UDim2.new(0.5, 0, currentY, 0)
	leaderboardButton.Size = UDim2.new(buttonWidth * 0.8, 0, buttonHeight * 0.8, 0) -- ���� ��ư�� ������ ũ��
	leaderboardButton.BackgroundColor3 = Color3.fromRGB(80, 120, 180) -- �ٸ� ����
	leaderboardButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	leaderboardButton.TextScaled = true
	leaderboardButton.Font = Enum.Font.SourceSansBold
	leaderboardButton.Text = "��������"
	leaderboardButton.BorderSizePixel = 0
	leaderboardButton.ZIndex = 3
	Instance.new("UICorner", leaderboardButton).CornerRadius = cornerRadius
	print("MainMenuBuilder: LeaderboardButton ������")
	-- ###########################

	print("MainMenuBuilder: ���� �޴� UI ���� �Ϸ�.")
end

return MainMenuBuilder