-- MainMenuBuilder.lua

local MainMenuBuilder = {}

function MainMenuBuilder.Build(mainGui, backgroundFrame, framesFolder, GuiUtils)
	print("MainMenuBuilder: 메인 메뉴 UI 생성 시작...")

	local cornerRadius = UDim.new(0, 8)

	local mainMenuFrame = Instance.new("Frame")
	mainMenuFrame.Name = "MainMenu"
	mainMenuFrame.Parent = framesFolder -- Frames 폴더 아래에 배치
	mainMenuFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mainMenuFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	mainMenuFrame.Size = UDim2.new(0.4, 0, 0.6, 0) -- << 높이 약간 늘림
	mainMenuFrame.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
	mainMenuFrame.BorderSizePixel = 0
	mainMenuFrame.Visible = false -- 기본 숨김
	mainMenuFrame.ZIndex = 2
	Instance.new("UICorner", mainMenuFrame).CornerRadius = cornerRadius
	print("MainMenuBuilder: MainMenu 프레임 생성됨")

	local buttonHeight = 0.15 -- << 버튼 높이 비율
	local buttonSpacing = 0.04 -- << 버튼 간격 비율
	local currentY = 0.15 -- << 시작 Y 위치 조정
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
	gameStartButton.Text = "게임 시작"
	gameStartButton.BorderSizePixel = 0
	gameStartButton.ZIndex = 3
	Instance.new("UICorner", gameStartButton).CornerRadius = cornerRadius
	print("MainMenuBuilder: GameStartButton 생성됨")

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
	settingsButton.Text = "설정"
	settingsButton.BorderSizePixel = 0
	settingsButton.ZIndex = 3
	Instance.new("UICorner", settingsButton).CornerRadius = cornerRadius
	print("MainMenuBuilder: SettingsButton 생성됨")

	currentY = currentY + (buttonHeight * 0.8) + buttonSpacing -- << 다음 버튼 Y 위치 계산

	-- ##### 리더보드 버튼 추가 #####
	local leaderboardButton = Instance.new("TextButton")
	leaderboardButton.Name = "LeaderboardButton"
	leaderboardButton.Parent = mainMenuFrame
	leaderboardButton.AnchorPoint = Vector2.new(0.5, 0)
	leaderboardButton.Position = UDim2.new(0.5, 0, currentY, 0)
	leaderboardButton.Size = UDim2.new(buttonWidth * 0.8, 0, buttonHeight * 0.8, 0) -- 설정 버튼과 유사한 크기
	leaderboardButton.BackgroundColor3 = Color3.fromRGB(80, 120, 180) -- 다른 색상
	leaderboardButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	leaderboardButton.TextScaled = true
	leaderboardButton.Font = Enum.Font.SourceSansBold
	leaderboardButton.Text = "리더보드"
	leaderboardButton.BorderSizePixel = 0
	leaderboardButton.ZIndex = 3
	Instance.new("UICorner", leaderboardButton).CornerRadius = cornerRadius
	print("MainMenuBuilder: LeaderboardButton 생성됨")
	-- ###########################

	print("MainMenuBuilder: 메인 메뉴 UI 생성 완료.")
end

return MainMenuBuilder