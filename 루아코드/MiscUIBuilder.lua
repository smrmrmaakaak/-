--[[
  MiscUIBuilder (ModuleScript)
  기타 UI 요소들 (전투 결과, 사냥터 선택, 모바일 토글 등)을 생성합니다.
]]
local MiscUIBuilder = {}

function MiscUIBuilder.Build(mainGui, backgroundFrame, framesFolder, GuiUtils)
	print("MiscUIBuilder: 기타 UI 요소 생성 시작...")

	local cornerRadius = UDim.new(0, 8)
	local smallCornerRadius = UDim.new(0, 4)

	-- 전투 결과 창 프레임 생성
	local resultsFrame = Instance.new("Frame")
	resultsFrame.Name = "CombatResultsFrame"
	resultsFrame.Parent = backgroundFrame -- BackgroundFrame 아래에 배치 (팝업 형태)
	resultsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	resultsFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	resultsFrame.Size = UDim2.new(0.4, 0, 0.5, 0)
	resultsFrame.BackgroundColor3 = Color3.fromRGB(50, 60, 50)
	resultsFrame.BorderColor3 = Color3.fromRGB(180, 200, 180)
	resultsFrame.BorderSizePixel = 2
	resultsFrame.Visible = false
	resultsFrame.ZIndex = 200 -- 다른 UI 위에 보이도록
	Instance.new("UICorner", resultsFrame).CornerRadius = cornerRadius
	print("MiscUIBuilder: CombatResultsFrame 생성됨")

	local resultsTitle = GuiUtils.CreateTextLabel(resultsFrame, "ResultsTitle",
		UDim2.new(0.5, 0, 0.1, 0), UDim2.new(0.8, 0, 0.15, 0),
		"전투 결과", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 22, Color3.fromRGB(255, 255, 180), Enum.Font.SourceSansBold)
	print("MiscUIBuilder: CombatResultsFrame Title 생성됨")

	local goldRewardLabel = GuiUtils.CreateTextLabel(resultsFrame, "GoldRewardLabel",
		UDim2.new(0.1, 0, 0.3, 0), UDim2.new(0.8, 0, 0.1, 0),
		"획득 골드: 0", Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 16)
	print("MiscUIBuilder: CombatResultsFrame GoldRewardLabel 생성됨")

	local expRewardLabel = GuiUtils.CreateTextLabel(resultsFrame, "ExpRewardLabel",
		UDim2.new(0.1, 0, 0.4, 0), UDim2.new(0.8, 0, 0.1, 0),
		"획득 경험치: 0", Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 16)
	print("MiscUIBuilder: CombatResultsFrame ExpRewardLabel 생성됨")

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
	print("MiscUIBuilder: CombatResultsFrame ItemList 생성됨")
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
	closeResultsButton.Text = "확인"
	closeResultsButton.BorderSizePixel = 0
	closeResultsButton.ZIndex = resultsFrame.ZIndex + 1
	Instance.new("UICorner", closeResultsButton).CornerRadius = cornerRadius
	print("MiscUIBuilder: CombatResultsFrame CloseButton 생성됨")

	-- 사냥터 선택 프레임 생성
	local huntingGroundFrame = Instance.new("Frame")
	huntingGroundFrame.Name = "HuntingGroundSelectionFrame"
	huntingGroundFrame.Parent = framesFolder -- Frames 폴더 아래에 배치
	huntingGroundFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	huntingGroundFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	huntingGroundFrame.Size = UDim2.new(0.5, 0, 0.7, 0)
	huntingGroundFrame.BackgroundColor3 = Color3.fromRGB(50, 60, 70)
	huntingGroundFrame.BorderColor3 = Color3.fromRGB(180, 190, 200)
	huntingGroundFrame.BorderSizePixel = 2
	huntingGroundFrame.Visible = false
	huntingGroundFrame.ZIndex = 4
	Instance.new("UICorner", huntingGroundFrame).CornerRadius = cornerRadius
	print("MiscUIBuilder: HuntingGroundSelectionFrame 생성됨")

	GuiUtils.CreateTextLabel(huntingGroundFrame, "TitleLabel", UDim2.new(0.5, 0, 0.05, 0), UDim2.new(0.9, 0, 0.1, 0), "사냥터 선택 (구현 예정)", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 20)

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
	print("MiscUIBuilder: GroundList ScrollingFrame 생성됨")

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
	backButton.Text = "뒤로가기"
	backButton.BorderSizePixel = 0
	backButton.ZIndex = 5
	Instance.new("UICorner", backButton).CornerRadius = cornerRadius
	print("MiscUIBuilder: HuntingGroundSelectionFrame BackButton 생성됨")

	-- 모바일 컨트롤 토글 버튼
	local toggleMobileControlsButton = Instance.new("TextButton")
	toggleMobileControlsButton.Name = "ToggleMobileControlsButton"
	toggleMobileControlsButton.Parent = backgroundFrame -- BackgroundFrame 바로 아래
	toggleMobileControlsButton.Size = UDim2.new(0, 100, 0, 30)
	toggleMobileControlsButton.AnchorPoint = Vector2.new(1, 0)
	toggleMobileControlsButton.Position = UDim2.new(0.98, 0, 0.02, 0)
	toggleMobileControlsButton.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	toggleMobileControlsButton.TextColor3 = Color3.fromRGB(220, 220, 220)
	toggleMobileControlsButton.Text = "키패드 숨기기"
	toggleMobileControlsButton.Font = Enum.Font.SourceSansBold
	toggleMobileControlsButton.TextSize = 12
	toggleMobileControlsButton.ZIndex = 200
	toggleMobileControlsButton.Visible = false
	toggleMobileControlsButton.Active = true
	toggleMobileControlsButton.Draggable = true
	Instance.new("UICorner", toggleMobileControlsButton).CornerRadius = smallCornerRadius
	print("MiscUIBuilder: ToggleMobileControlsButton 생성됨")

	-- 스킬 선택 프레임 (CombatUIBuilder에서 옮겨옴)
	local skillSelectionFrame = Instance.new("Frame")
	skillSelectionFrame.Name = "SkillSelectionFrame"
	skillSelectionFrame.Parent = backgroundFrame -- BackgroundFrame 아래에 배치 (팝업 형태)
	skillSelectionFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	skillSelectionFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	skillSelectionFrame.Size = UDim2.new(0.5, 0, 0.6, 0)
	skillSelectionFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 65)
	skillSelectionFrame.BorderColor3 = Color3.fromRGB(180, 180, 210)
	skillSelectionFrame.BorderSizePixel = 2
	skillSelectionFrame.Visible = false
	skillSelectionFrame.ZIndex = 153 -- 다른 UI 위에 보이도록 ZIndex 높임
	Instance.new("UICorner", skillSelectionFrame).CornerRadius = cornerRadius
	print("MiscUIBuilder: SkillSelectionFrame 생성됨")
	GuiUtils.CreateTextLabel(skillSelectionFrame, "TitleLabel", UDim2.new(0.5, 0, 0.05, 0), UDim2.new(0.9, 0, 0.1, 0), "스킬 선택", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 18)
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
	print("MiscUIBuilder: SkillList ScrollingFrame 생성됨")
	local listLayout = Instance.new("UIListLayout")
	listLayout.Parent = skillListFrame
	listLayout.Padding = UDim.new(0, 5)
	listLayout.FillDirection = Enum.FillDirection.Vertical
	listLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	listLayout.SortOrder = Enum.SortOrder.LayoutOrder
	print("MiscUIBuilder: SkillList UIListLayout 생성됨")
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
	cancelSkillButton.Text = "취소"
	cancelSkillButton.BorderSizePixel = 0
	cancelSkillButton.ZIndex = skillSelectionFrame.ZIndex + 1
	Instance.new("UICorner", cancelSkillButton).CornerRadius = cornerRadius
	print("MiscUIBuilder: CancelSkillButton 생성됨")

	-- 전투 아이템 선택 프레임 (CombatUIBuilder에서 옮겨옴)
	local combatItemSelectionFrame = Instance.new("Frame")
	combatItemSelectionFrame.Name = "CombatItemSelectionFrame"
	combatItemSelectionFrame.Parent = backgroundFrame -- BackgroundFrame 아래에 배치 (팝업 형태)
	combatItemSelectionFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	combatItemSelectionFrame.Position = UDim2.new(0.5, 0, 0.5, 0) -- 화면 중앙
	combatItemSelectionFrame.Size = UDim2.new(0.5, 0, 0.6, 0) -- 스킬 선택 창과 유사한 크기
	combatItemSelectionFrame.BackgroundColor3 = Color3.fromRGB(65, 45, 45) -- 약간 다른 배경색
	combatItemSelectionFrame.BorderColor3 = Color3.fromRGB(210, 180, 180)
	combatItemSelectionFrame.BorderSizePixel = 2
	combatItemSelectionFrame.Visible = false
	combatItemSelectionFrame.ZIndex = 153 -- 다른 UI 위에 보이도록
	Instance.new("UICorner", combatItemSelectionFrame).CornerRadius = cornerRadius
	print("MiscUIBuilder: CombatItemSelectionFrame 생성됨")

	GuiUtils.CreateTextLabel(combatItemSelectionFrame, "TitleLabel", UDim2.new(0.5, 0, 0.05, 0), UDim2.new(0.9, 0, 0.1, 0), "아이템 선택", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 18)

	local combatItemListFrame = Instance.new("ScrollingFrame")
	combatItemListFrame.Name = "ItemList" -- CombatUIManager 에서 이 이름으로 찾음
	combatItemListFrame.Parent = combatItemSelectionFrame
	combatItemListFrame.AnchorPoint = Vector2.new(0.5, 0)
	combatItemListFrame.Position = UDim2.new(0.5, 0, 0.15, 0)
	combatItemListFrame.Size = UDim2.new(0.9, 0, 0.7, 0)
	combatItemListFrame.BackgroundColor3 = Color3.fromRGB(50, 30, 30)
	combatItemListFrame.BorderSizePixel = 1
	combatItemListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	combatItemListFrame.ScrollBarThickness = 8
	Instance.new("UICorner", combatItemListFrame).CornerRadius = cornerRadius
	print("MiscUIBuilder: Combat ItemList ScrollingFrame 생성됨")

	local combatItemListLayout = Instance.new("UIGridLayout") -- 그리드 레이아웃 사용 (인벤토리처럼)
	combatItemListLayout.Parent = combatItemListFrame
	combatItemListLayout.CellPadding = UDim2.new(0, 5, 0, 5)
	combatItemListLayout.CellSize = UDim2.new(0, 64, 0, 64) -- 인벤토리 슬롯과 동일한 크기
	combatItemListLayout.StartCorner = Enum.StartCorner.TopLeft
	combatItemListLayout.FillDirection = Enum.FillDirection.Horizontal
	combatItemListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	combatItemListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	combatItemListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	print("MiscUIBuilder: Combat ItemList UIGridLayout 생성됨")

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
	cancelItemButton.Text = "취소"
	cancelItemButton.BorderSizePixel = 0
	cancelItemButton.ZIndex = combatItemSelectionFrame.ZIndex + 1
	Instance.new("UICorner", cancelItemButton).CornerRadius = cornerRadius
	print("MiscUIBuilder: CancelItemButton 생성됨")


	print("MiscUIBuilder: 기타 UI 요소 생성 완료.")
end

return MiscUIBuilder
