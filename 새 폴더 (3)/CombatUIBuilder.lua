-- CombatUIBuilder.lua

--[[
  CombatUIBuilder (ModuleScript)
  전투 화면 UI (배경, 캐릭터 이미지, 적 영역, 하단 메뉴 등)를 생성합니다.
  스킬/아이템 선택 창, 전투 결과 창은 MiscUIBuilder에서 처리합니다.
  *** [수정] 파티원 상태 템플릿에 TPLabel 추가 ***
  *** [수정] 모바일 화면 잘림 현상 개선을 위해 BottomUIArea 및 내부 요소 Scale 조정 ***
  *** [수정] 동료 UI 요소 추가: PartyStatusFrame 구조 변경 및 전투 필드 동료 이미지 영역 추가 ***
  *** [수정] Padding 속성에 UDim 값 사용 (UDim2 오류 수정) ***
  *** [버그 수정] PartyStatusFrame 내 레이블들이 InnerLayout Frame 아래에 생성되도록 수정 ***
]]
local CombatUIBuilder = {}

function CombatUIBuilder.Build(mainGui, backgroundFrame, framesFolder, GuiUtils)
	print("CombatUIBuilder: 전투 UI 생성 시작...")

	local cornerRadius = UDim.new(0, 8)
	local smallCornerRadius = UDim.new(0, 4)
	local verySmallCornerRadius = UDim.new(0, 2)

	local COMBAT_BACKGROUND_IMAGE_ID = "rbxassetid://117785920984118" -- <<< 전투 배경 이미지 ID

	local combatScreenFrame = Instance.new("Frame")
	combatScreenFrame.Name = "CombatScreen"
	combatScreenFrame.Parent = framesFolder -- Frames 폴더 아래에 배치
	combatScreenFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	combatScreenFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	combatScreenFrame.Size = UDim2.new(1, 0, 1, 0)
	combatScreenFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	combatScreenFrame.BackgroundTransparency = 1 -- 배경 투명
	combatScreenFrame.BorderSizePixel = 0
	combatScreenFrame.Visible = false
	combatScreenFrame.ZIndex = 152
	print("CombatUIBuilder: CombatScreen 프레임 생성됨")

	-- 전투 배경 이미지
	local combatBackgroundImage = Instance.new("ImageLabel")
	combatBackgroundImage.Name = "CombatBackgroundImage"
	combatBackgroundImage.Parent = combatScreenFrame
	combatBackgroundImage.Size = UDim2.new(1, 0, 1, 0)
	combatBackgroundImage.Position = UDim2.new(0, 0, 0, 0)
	combatBackgroundImage.Image = COMBAT_BACKGROUND_IMAGE_ID
	combatBackgroundImage.ScaleType = Enum.ScaleType.Stretch
	combatBackgroundImage.ZIndex = combatScreenFrame.ZIndex - 1
	print("CombatUIBuilder: CombatBackgroundImage 생성됨")

	-- 플레이어 캐릭터 이미지
	local playerCharacterImage = Instance.new("ImageLabel")
	playerCharacterImage.Name = "PlayerCharacterImage"
	playerCharacterImage.Parent = combatScreenFrame
	playerCharacterImage.AnchorPoint = Vector2.new(0.5, 1)
	playerCharacterImage.Position = UDim2.new(0.7, 0, 0.7, 0) -- 플레이어 위치
	playerCharacterImage.Size = UDim2.new(0.15, 0, 0.3, 0) -- 플레이어 크기
	playerCharacterImage.BackgroundTransparency = 1
	playerCharacterImage.ScaleType = Enum.ScaleType.Fit
	playerCharacterImage.ZIndex = combatScreenFrame.ZIndex + 2
	print("CombatUIBuilder: PlayerCharacterImage 생성됨")
	local playerHitOverlay = Instance.new("Frame")
	playerHitOverlay.Name = "HitOverlay"
	playerHitOverlay.Parent = playerCharacterImage
	playerHitOverlay.Size = UDim2.new(1, 0, 1, 0)
	playerHitOverlay.Position = UDim2.new(0, 0, 0, 0)
	playerHitOverlay.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
	playerHitOverlay.BackgroundTransparency = 1
	playerHitOverlay.ZIndex = playerCharacterImage.ZIndex + 1
	print("CombatUIBuilder: Player HitOverlay 생성됨")

	-- 동료 캐릭터 이미지 영역 추가
	local companionBaseXScale = playerCharacterImage.Position.X.Scale
	local companionBaseYScale = playerCharacterImage.Position.Y.Scale
	local companionXOffsetIncrement = 0.12 -- 동료 간 X축 간격
	local companionYOffset = -0.05 -- 플레이어보다 약간 위
	local companionSizeXScale = 0.12
	local companionSizeYScale = 0.24

	for i = 1, 2 do
		local compImg = Instance.new("ImageLabel")
		compImg.Name = "CompanionCharacterImage_" .. i
		compImg.Parent = combatScreenFrame
		compImg.AnchorPoint = Vector2.new(0.5, 1)
		-- 플레이어 기준 왼쪽으로 배치
		compImg.Position = UDim2.new(companionBaseXScale - (companionXOffsetIncrement * i), 0, companionBaseYScale + companionYOffset, 0)
		compImg.Size = UDim2.new(companionSizeXScale, 0, companionSizeYScale, 0)
		compImg.BackgroundTransparency = 1
		compImg.ScaleType = Enum.ScaleType.Fit
		compImg.ZIndex = playerCharacterImage.ZIndex -- 플레이어와 같거나 살짝 뒤
		compImg.ImageTransparency = 1
		compImg.Visible = false -- 처음엔 숨김
		print("CombatUIBuilder: CompanionCharacterImage_" .. i .. " 생성됨")

		local compHitOverlay = Instance.new("Frame")
		compHitOverlay.Name = "HitOverlay"
		compHitOverlay.Parent = compImg
		compHitOverlay.Size = UDim2.new(1,0,1,0); compHitOverlay.Position = UDim2.new(0,0,0,0)
		compHitOverlay.BackgroundColor3 = Color3.fromRGB(255,50,50); compHitOverlay.BackgroundTransparency = 1
		compHitOverlay.ZIndex = compImg.ZIndex + 1
	end

	local enemyAreaFrame = Instance.new("ScrollingFrame")
	enemyAreaFrame.Name = "EnemyAreaFrame"
	enemyAreaFrame.Parent = combatScreenFrame
	enemyAreaFrame.AnchorPoint = Vector2.new(0, 1)
	enemyAreaFrame.Position = UDim2.new(0.05, 0, 0.7, 0) -- 적 영역 위치
	enemyAreaFrame.Size = UDim2.new(0.4, 0, 0.35, 0) -- 적 영역 크기
	enemyAreaFrame.BackgroundTransparency = 1
	enemyAreaFrame.BorderSizePixel = 0
	enemyAreaFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	enemyAreaFrame.ScrollBarThickness = 0
	enemyAreaFrame.ZIndex = combatScreenFrame.ZIndex + 1
	print("CombatUIBuilder: EnemyAreaFrame 생성됨")

	local enemyAreaLayout = Instance.new("UIListLayout")
	enemyAreaLayout.FillDirection = Enum.FillDirection.Horizontal
	enemyAreaLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	enemyAreaLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
	enemyAreaLayout.Padding = UDim.new(0, 5)
	enemyAreaLayout.Parent = enemyAreaFrame

	local enemyUITemplate = Instance.new("Frame")
	enemyUITemplate.Name = "EnemyUITemplate"
	enemyUITemplate.Size = UDim2.new(0.3, 0, 0.9, 0) -- 적 UI 템플릿 크기
	enemyUITemplate.BackgroundTransparency = 1
	enemyUITemplate.Visible = false
	enemyUITemplate.Parent = enemyAreaFrame

	local enemyImage = Instance.new("ImageLabel"); enemyImage.Name = "EnemyImage"; enemyImage.Parent = enemyUITemplate; enemyImage.AnchorPoint = Vector2.new(0.5, 1); enemyImage.Position = UDim2.new(0.5, 0, 0.8, 0); enemyImage.Size = UDim2.new(0.8, 0, 0.6, 0); enemyImage.BackgroundTransparency = 1; enemyImage.ScaleType = Enum.ScaleType.Fit; enemyImage.ZIndex = enemyUITemplate.ZIndex + 1
	local enemyHitOverlay = Instance.new("Frame"); enemyHitOverlay.Name = "HitOverlay"; enemyHitOverlay.Parent = enemyImage; enemyHitOverlay.Size = UDim2.new(1, 0, 1, 0); enemyHitOverlay.Position = UDim2.new(0, 0, 0, 0); enemyHitOverlay.BackgroundColor3 = Color3.fromRGB(255, 50, 50); enemyHitOverlay.BackgroundTransparency = 1; enemyHitOverlay.ZIndex = enemyImage.ZIndex + 1
	local enemyInfoContainer = Instance.new("Frame"); enemyInfoContainer.Name = "InfoContainer"; enemyInfoContainer.Parent = enemyUITemplate; enemyInfoContainer.AnchorPoint = Vector2.new(0.5, 1); enemyInfoContainer.Position = UDim2.new(0.5, 0, 1, 0); enemyInfoContainer.Size = UDim2.new(1, 0, 0.35, 0); enemyInfoContainer.BackgroundTransparency = 1
	local enemyNameLabel = GuiUtils.CreateTextLabel(enemyInfoContainer, "NameLabel", UDim2.new(0.5, 0, 0.15, 0), UDim2.new(0.9, 0, 0.3, 0), "Enemy Name", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 12); enemyNameLabel.TextColor3 = Color3.fromRGB(255, 200, 200)
	local enemyHPBarBG = GuiUtils.CreateResourceBar(enemyInfoContainer, "HP", UDim2.new(0.5, 0, 0.55, 0), UDim2.new(0.8, 0, 0.25, 0), Vector2.new(0.5, 0), Color3.fromRGB(200, 80, 80), Color3.new(1, 1, 1)); enemyHPBarBG.Size = UDim2.new(0.8, 0, 0.25, 0)
	local hpLabel = enemyHPBarBG:FindFirstChild("HPLabel"); if hpLabel then hpLabel.TextScaled = false; hpLabel.TextSize = 10 end; if enemyHPBarBG then Instance.new("UICorner", enemyHPBarBG).CornerRadius = verySmallCornerRadius end
	local enemyStatusFrame = GuiUtils.CreateFrame(enemyInfoContainer, "StatusEffectsFrame", UDim2.new(0.5,0,0.85,0), UDim2.new(0.9,0,0.15,0), Vector2.new(0.5,0), nil, 1); enemyStatusFrame.ZIndex = enemyInfoContainer.ZIndex +1
	if enemyStatusFrame then Instance.new("UIListLayout", enemyStatusFrame).FillDirection = Enum.FillDirection.Horizontal; Instance.new("UICorner", enemyStatusFrame).CornerRadius = verySmallCornerRadius end
	local enemyTargetButton = Instance.new("ImageButton"); enemyTargetButton.Name = "TargetButton"; enemyTargetButton.Parent = enemyUITemplate; enemyTargetButton.Size = UDim2.new(1, 0, 1, 0); enemyTargetButton.BackgroundTransparency = 1; enemyTargetButton.ZIndex = enemyUITemplate.ZIndex + 2; enemyTargetButton.Image = ""; enemyTargetButton.ImageTransparency = 1; enemyTargetButton.ScaleType = Enum.ScaleType.Fit
	print("CombatUIBuilder: EnemyUITemplate 생성됨")

	local skillEffectImage = Instance.new("ImageLabel"); skillEffectImage.Name = "SkillEffectImage"; skillEffectImage.Parent = combatScreenFrame; skillEffectImage.AnchorPoint = Vector2.new(0.5, 0.5); skillEffectImage.Position = UDim2.new(0.5, 0, 0.4, 0); skillEffectImage.Size = UDim2.new(0.2, 0, 0.3, 0); skillEffectImage.BackgroundTransparency = 1; skillEffectImage.ScaleType = Enum.ScaleType.Fit; skillEffectImage.Visible = false; skillEffectImage.ZIndex = combatScreenFrame.ZIndex + 50
	print("CombatUIBuilder: SkillEffectImage 생성됨")

	local bottomUIArea = Instance.new("Frame"); bottomUIArea.Name = "BottomUIArea"; bottomUIArea.Parent = combatScreenFrame; bottomUIArea.AnchorPoint = Vector2.new(0, 1); bottomUIArea.Position = UDim2.new(0, 0, 1, 0); bottomUIArea.Size = UDim2.new(1, 0, 0.25, 0); bottomUIArea.BackgroundColor3 = Color3.fromRGB(30, 30, 45); bottomUIArea.BorderSizePixel = 1; bottomUIArea.BorderColor3 = Color3.fromRGB(100, 100, 120); bottomUIArea.ZIndex = combatScreenFrame.ZIndex + 10; Instance.new("UICorner", bottomUIArea).CornerRadius = smallCornerRadius
	print("CombatUIBuilder: BottomUIArea 생성됨")

	local actionMenuFrame = Instance.new("Frame"); actionMenuFrame.Name = "ActionMenuFrame"; actionMenuFrame.Parent = bottomUIArea; actionMenuFrame.Position = UDim2.new(0.02, 0, 0.5, 0); actionMenuFrame.AnchorPoint = Vector2.new(0, 0.5); actionMenuFrame.Size = UDim2.new(0.22, 0, 0.9, 0); actionMenuFrame.BackgroundColor3 = Color3.fromRGB(45, 45, 60); actionMenuFrame.BorderSizePixel = 1; actionMenuFrame.BorderColor3 = Color3.fromRGB(120, 120, 150); Instance.new("UICorner", actionMenuFrame).CornerRadius = smallCornerRadius
	print("CombatUIBuilder: ActionMenuFrame 생성됨")
	local actionMenuLayout = Instance.new("UIListLayout")
	actionMenuLayout.Padding = UDim.new(0, 5)
	actionMenuLayout.FillDirection = Enum.FillDirection.Vertical; actionMenuLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; actionMenuLayout.VerticalAlignment = Enum.VerticalAlignment.Center; actionMenuLayout.Parent = actionMenuFrame
	local buttonWidthScale = 0.9; local buttonHeightScale = 0.2
	local attackButtonNew = GuiUtils.CreateButton(actionMenuFrame, "AttackButton", nil, UDim2.new(buttonWidthScale, 0, buttonHeightScale, 0), nil, "공격", nil, actionMenuFrame.ZIndex + 1); attackButtonNew.BackgroundColor3 = Color3.fromRGB(180, 70, 70); Instance.new("UICorner", attackButtonNew).CornerRadius = verySmallCornerRadius
	local skillButtonNew = GuiUtils.CreateButton(actionMenuFrame, "SkillButton", nil, UDim2.new(buttonWidthScale, 0, buttonHeightScale, 0), nil, "스킬", nil, actionMenuFrame.ZIndex + 1); skillButtonNew.BackgroundColor3 = Color3.fromRGB(70, 70, 180); Instance.new("UICorner", skillButtonNew).CornerRadius = verySmallCornerRadius
	local defendButton = GuiUtils.CreateButton(actionMenuFrame, "DefendButton", nil, UDim2.new(buttonWidthScale, 0, buttonHeightScale, 0), nil, "보호", nil, actionMenuFrame.ZIndex + 1); defendButton.BackgroundColor3 = Color3.fromRGB(70, 180, 70); Instance.new("UICorner", defendButton).CornerRadius = verySmallCornerRadius
	local itemButton = GuiUtils.CreateButton(actionMenuFrame, "ItemButton", nil, UDim2.new(buttonWidthScale, 0, buttonHeightScale, 0), nil, "아이템", nil, actionMenuFrame.ZIndex + 1); itemButton.BackgroundColor3 = Color3.fromRGB(180, 180, 70); Instance.new("UICorner", itemButton).CornerRadius = verySmallCornerRadius
	print("CombatUIBuilder: 액션 메뉴 버튼들 생성됨 (Scale 조정됨)")

	local partyStatusFrame = Instance.new("Frame"); partyStatusFrame.Name = "PartyStatusFrame"; partyStatusFrame.Parent = bottomUIArea; partyStatusFrame.Position = UDim2.new(1 - 0.02, 0, 0.5, 0); partyStatusFrame.AnchorPoint = Vector2.new(1, 0.5); partyStatusFrame.Size = UDim2.new(0.73, 0, 0.9, 0); partyStatusFrame.BackgroundColor3 = Color3.fromRGB(60, 45, 45); partyStatusFrame.BorderSizePixel = 1; partyStatusFrame.BorderColor3 = Color3.fromRGB(150, 120, 120); Instance.new("UICorner", partyStatusFrame).CornerRadius = smallCornerRadius
	print("CombatUIBuilder: PartyStatusFrame 생성됨")

	local partyStatusLayout = Instance.new("UIListLayout")
	partyStatusLayout.Padding = UDim.new(0, 5) 
	partyStatusLayout.FillDirection = Enum.FillDirection.Vertical; partyStatusLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; partyStatusLayout.VerticalAlignment = Enum.VerticalAlignment.Center; partyStatusLayout.Parent = partyStatusFrame

	local memberSlotHeightScale = 0.3; local memberSlotWidthScale = 0.95
	for i = 1, 3 do
		local slotName; if i == 1 then slotName = "PartySlot_Player" else slotName = "PartySlot_Companion" .. (i - 1) end
		local memberFrame = GuiUtils.CreateFrame(partyStatusFrame, slotName, nil, UDim2.new(memberSlotWidthScale, 0, memberSlotHeightScale, 0), nil, Color3.fromRGB(50, 35, 35), 0.3, partyStatusFrame.ZIndex + 1); memberFrame.LayoutOrder = i; Instance.new("UICorner", memberFrame).CornerRadius = verySmallCornerRadius

		-- ##### InnerLayout Frame 추가 #####
		local innerLayoutFrame = GuiUtils.CreateFrame(memberFrame, "InnerLayout", 
			UDim2.new(0.5,0,0.5,0), UDim2.new(0.95,0,0.9,0), -- memberFrame 중앙에 배치, 약간의 내부 여백
			Vector2.new(0.5,0.5), nil, 1)
		innerLayoutFrame.BackgroundTransparency = 1 -- InnerLayout은 투명하게
		-- ##############################

		local innerHorizontalLayout = Instance.new("UIListLayout"); innerHorizontalLayout.FillDirection = Enum.FillDirection.Horizontal; innerHorizontalLayout.VerticalAlignment = Enum.VerticalAlignment.Center; innerHorizontalLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left;
		innerHorizontalLayout.Padding = UDim.new(0, 3) 
		innerHorizontalLayout.Parent = innerLayoutFrame -- 수정: innerHorizontalLayout의 부모를 innerLayoutFrame으로

		local labelHeightScaleInner = 0.8
		-- 수정: 모든 레이블의 부모를 innerLayoutFrame으로 변경
		GuiUtils.CreateTextLabel(innerLayoutFrame, "CompanionNameLabel", nil, UDim2.new(0.25, 0, labelHeightScaleInner, 0), "이름", nil, Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 12).LayoutOrder = 1
		GuiUtils.CreateTextLabel(innerLayoutFrame, "HPLabel", nil, UDim2.new(0.28, 0, labelHeightScaleInner, 0), "HP", nil, Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 11).LayoutOrder = 2
		GuiUtils.CreateTextLabel(innerLayoutFrame, "MPLabel", nil, UDim2.new(0.23, 0, labelHeightScaleInner, 0), "MP", nil, Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 11).LayoutOrder = 3
		local tpLabel = GuiUtils.CreateTextLabel(innerLayoutFrame, "TPLabel", nil, UDim2.new(0.20, 0, labelHeightScaleInner, 0), "TP", nil, Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 11); tpLabel.LayoutOrder = 4; tpLabel.TextColor3 = Color3.fromRGB(255,215,0)

		-- StatusEffectsFrame은 memberFrame 바로 아래에 유지 (CombatUIManager.UpdatePartyMemberStatus 참조 구조 고려)
		local statusFrame = GuiUtils.CreateFrame(memberFrame, "StatusEffectsFrame", UDim2.new(0.95, 0, 0.1, 0), UDim2.new(0.8, 0, 0.15, 0), Vector2.new(1,0), Color3.fromRGB(0,0,0), 0.7, memberFrame.ZIndex + 1); statusFrame.SizeConstraint = Enum.SizeConstraint.RelativeYY; Instance.new("UIListLayout", statusFrame).FillDirection = Enum.FillDirection.Horizontal; local statusPadding = Instance.new("UIPadding",statusFrame); statusPadding.PaddingRight = UDim.new(0,2)
		print("CombatUIBuilder: "..slotName.." 생성됨 (InnerLayout 구조로 변경)")
	end

	local combatLogFrame = Instance.new("ScrollingFrame"); combatLogFrame.Name = "CombatLogFrame"; combatLogFrame.Parent = combatScreenFrame; combatLogFrame.AnchorPoint = Vector2.new(1, 0); combatLogFrame.Position = UDim2.new(0.98, 0, 0.02, 0); combatLogFrame.Size = UDim2.new(0.3, 0, 0.3, 0); combatLogFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 45); combatLogFrame.BackgroundTransparency = 0.3; combatLogFrame.BorderSizePixel = 1; combatLogFrame.BorderColor3 = Color3.fromRGB(120, 120, 130); combatLogFrame.CanvasSize = UDim2.new(0, 0, 0, 0); combatLogFrame.ScrollBarThickness = 6; combatLogFrame.ZIndex = combatScreenFrame.ZIndex + 15; Instance.new("UICorner", combatLogFrame).CornerRadius = smallCornerRadius
	print("CombatUIBuilder: CombatLogFrame 생성됨")
	local combatLogLayout = Instance.new("UIListLayout"); combatLogLayout.Name = "LogLayout";
	combatLogLayout.Padding = UDim.new(0, 2) 
	combatLogLayout.FillDirection = Enum.FillDirection.Vertical; combatLogLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left; combatLogLayout.SortOrder = Enum.SortOrder.LayoutOrder; combatLogLayout.Parent = combatLogFrame
	print("CombatUIBuilder: CombatLogFrame UIListLayout 생성됨")

	print("CombatUIBuilder: 전투 UI 생성 완료.")
end

return CombatUIBuilder