-- EnhancementUIBuilder.lua (수정: 강화 가능 아이템 목록 영역 추가)

--[[
  EnhancementUIBuilder (ModuleScript)
  장비 강화 창 UI를 생성합니다.
  *** [수정] 강화 가능 아이템 목록 표시용 ScrollingFrame 추가 ***
  *** [수정] 아이템 정보 표시 영역 위치 조정 ***
]]
local EnhancementUIBuilder = {}

function EnhancementUIBuilder.Build(mainGui, backgroundFrame, framesFolder, GuiUtils)
	if not GuiUtils then print("EnhancementUIBuilder: GuiUtils is required!"); return end
	print("EnhancementUIBuilder: 강화 창 UI 생성 시작...")

	local cornerRadius = UDim.new(0, 8)
	local smallCornerRadius = UDim.new(0, 4)

	-- 강화 창 기본 프레임
	local enhancementFrame = Instance.new("Frame")
	enhancementFrame.Name = "EnhancementFrame"
	enhancementFrame.Parent = backgroundFrame
	enhancementFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	enhancementFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	enhancementFrame.Size = UDim2.new(0.7, 0, 0.7, 0) -- 너비 증가, 높이 유지 (조절 가능)
	enhancementFrame.BackgroundColor3 = Color3.fromRGB(65, 60, 50)
	enhancementFrame.BorderColor3 = Color3.fromRGB(200, 190, 170)
	enhancementFrame.BorderSizePixel = 2
	enhancementFrame.Visible = false
	enhancementFrame.ZIndex = 6
	Instance.new("UICorner", enhancementFrame).CornerRadius = cornerRadius
	print("EnhancementUIBuilder: EnhancementFrame 생성됨")

	-- 제목
	GuiUtils.CreateTextLabel(enhancementFrame, "TitleLabel",
		UDim2.new(0.5, 0, 0.05, 0), UDim2.new(0.9, 0, 0.1, 0),
		"장비 강화", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 20)

	-- *** 추가: 강화 가능 아이템 목록 스크롤 프레임 ***
	local enhanceableItemList = Instance.new("ScrollingFrame")
	enhanceableItemList.Name = "EnhanceableItemList"
	enhanceableItemList.Parent = enhancementFrame
	enhanceableItemList.Position = UDim2.new(0.05, 0, 0.18, 0) -- 왼쪽 영역
	enhanceableItemList.Size = UDim2.new(0.4, 0, 0.7, 0) -- 너비 40%, 높이 70%
	enhanceableItemList.BackgroundColor3 = Color3.fromRGB(50, 45, 35)
	enhanceableItemList.BorderSizePixel = 1
	enhanceableItemList.BorderColor3 = Color3.fromRGB(150, 140, 120)
	enhanceableItemList.CanvasSize = UDim2.new(0, 0, 0, 0)
	enhanceableItemList.ScrollBarThickness = 6
	Instance.new("UICorner", enhanceableItemList).CornerRadius = smallCornerRadius

	-- 아이템 목록 레이아웃 (Grid 또는 List 선택) - 여기서는 Grid 사용
	local itemListLayout = Instance.new("UIGridLayout")
	itemListLayout.Parent = enhanceableItemList
	itemListLayout.CellPadding = UDim2.new(0, 5, 0, 5)
	itemListLayout.CellSize = UDim2.new(0, 64, 0, 64) -- 인벤토리 슬롯과 유사한 크기
	itemListLayout.StartCorner = Enum.StartCorner.TopLeft
	itemListLayout.FillDirection = Enum.FillDirection.Horizontal
	itemListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	itemListLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	itemListLayout.SortOrder = Enum.SortOrder.LayoutOrder -- 필요시 Name 등으로 변경 가능
	print("EnhancementUIBuilder: EnhanceableItemList 생성됨")
	-- *** 아이템 목록 영역 추가 끝 ***

	-- *** 수정: 아이템 정보 및 강화 정보 표시 영역 (오른쪽으로 이동) ***
	local detailsDisplayFrame = GuiUtils.CreateFrame(enhancementFrame, "DetailsDisplayFrame",
		UDim2.new(0.52, 0, 0.18, 0), UDim2.new(0.43, 0, 0.7, 0), -- 오른쪽 영역
		nil, nil, 1)

	-- 강화할 아이템 표시 영역
	local itemDisplayFrame = GuiUtils.CreateFrame(detailsDisplayFrame, "ItemDisplayFrame",
		UDim2.new(0, 0, 0, 0), UDim2.new(1, 0, 0.25, 0), -- 상단 25%
		nil, nil, 1)

	local selectedItemImage = GuiUtils.CreateImageLabel(itemDisplayFrame, "SelectedItemImage",
		UDim2.new(0.1, 0, 0.5, 0), UDim2.new(0, 64, 0, 64),
		Vector2.new(0, 0.5), nil, Enum.ScaleType.Fit, detailsDisplayFrame.ZIndex + 1)
	selectedItemImage.BackgroundColor3 = Color3.fromRGB(40, 40, 30); selectedItemImage.BackgroundTransparency = 0.3
	Instance.new("UICorner", selectedItemImage).CornerRadius = smallCornerRadius

	local itemInfoLabel = GuiUtils.CreateTextLabel(itemDisplayFrame, "ItemInfoLabel",
		UDim2.new(0.1 + (64/itemDisplayFrame.AbsoluteSize.X), 15, 0.5, 0), -- 이미지 오른쪽에 배치 (AbsoluteSize 기반은 로딩 순서 문제 있을 수 있음, 필요시 조정)
		UDim2.new(1, -(64+20), 0.8, 0), -- 너비 조정
		"강화할 아이템을 목록에서 선택하세요.", Vector2.new(0, 0.5), Enum.TextXAlignment.Left, Enum.TextYAlignment.Top, 14)
	itemInfoLabel.TextWrapped = true

	-- 강화 정보 표시 영역
	local infoDisplayFrame = GuiUtils.CreateFrame(detailsDisplayFrame, "InfoDisplayFrame",
		UDim2.new(0, 0, 0.3, 0), UDim2.new(1, 0, 0.4, 0), -- 아이템 표시 아래 영역
		nil, nil, 1)

	GuiUtils.CreateTextLabel(infoDisplayFrame, "MaterialsHeader",
		UDim2.new(0, 0, 0.05, 0), UDim2.new(1, 0, 0.1, 0),
		"필요 재료:", Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 14)

	local materialList = Instance.new("ScrollingFrame")
	materialList.Name = "MaterialList"
	materialList.Parent = infoDisplayFrame
	materialList.Position = UDim2.new(0, 0, 0.18, 0)
	materialList.Size = UDim2.new(1, 0, 0.5, 0) -- 크기 조정
	materialList.BackgroundColor3 = Color3.fromRGB(50, 45, 35); materialList.BorderSizePixel = 1
	materialList.CanvasSize = UDim2.new(0, 0, 0, 0); materialList.ScrollBarThickness = 4
	Instance.new("UICorner", materialList).CornerRadius = smallCornerRadius
	local materialListLayout = Instance.new("UIListLayout"); materialListLayout.Padding = UDim.new(0, 2); materialListLayout.FillDirection = Enum.FillDirection.Vertical; materialListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left; materialListLayout.Parent = materialList

	local costLabel = GuiUtils.CreateTextLabel(infoDisplayFrame, "CostLabel",
		UDim2.new(0, 0, 0.75, 0), UDim2.new(0.5, 0, 0.1, 0),
		"비용: - G", Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 14)

	local successRateLabel = GuiUtils.CreateTextLabel(infoDisplayFrame, "SuccessRateLabel",
		UDim2.new(0, 0, 0.88, 0), UDim2.new(0.5, 0, 0.1, 0),
		"성공 확률: - %", Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 14)

	-- 강화 버튼 (위치 조정)
	local enhanceButton = GuiUtils.CreateButton(detailsDisplayFrame, "EnhanceButton",
		UDim2.new(0.5, 0, 0.9, 0), UDim2.new(0.6, 0, 0.1, 0), -- DetailsDisplayFrame 하단 중앙
		Vector2.new(0.5, 1), "강화", nil, detailsDisplayFrame.ZIndex + 1)
	enhanceButton.BackgroundColor3 = Color3.fromRGB(180, 140, 80); enhanceButton.Visible = false
	Instance.new("UICorner", enhanceButton).CornerRadius = cornerRadius
	-- *** 정보 표시 영역 수정 끝 ***

	-- 닫기 버튼 (위치 조정 없음)
	local closeButton = GuiUtils.CreateButton(enhancementFrame, "CloseButton",
		UDim2.new(1, -5, 1, -5), UDim2.new(0, 80, 0, 30),
		Vector2.new(1, 1), "닫기", nil, enhancementFrame.ZIndex + 1)
	closeButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50); Instance.new("UICorner", closeButton).CornerRadius = smallCornerRadius

	print("EnhancementUIBuilder: 강화 창 UI 생성 완료.")
	return enhancementFrame
end

return EnhancementUIBuilder