-- EquipmentUIBuilder.lua

--[[
  EquipmentUIBuilder (ModuleScript)
  장비 창 UI를 생성합니다.
  *** [수정] 슬롯 전체 위치 위로 조정, 슬롯 디자인 개선 (테두리 유지, 아이콘 분리) ***
]]
local EquipmentUIBuilder = {}

function EquipmentUIBuilder.Build(mainGui, backgroundFrame, framesFolder, GuiUtils)
	print("EquipmentUIBuilder: 장비 창 UI 생성 시작 (슬롯 전체 위치 위로 조정)...")

	local cornerRadius = UDim.new(0, 8)

	-- 기본 슬롯 아이콘 이미지 ID (실제 ID로 교체 필요)
	local defaultWeaponSlotIconImage = "rbxassetid://122953630794668"
	local defaultArmorSlotIconImage = "rbxassetid://107446706579540"
	local defaultAccessorySlotIconImage = "rbxassetid://102260956806130"
	local defaultIconTransparency = 0 -- 기본 아이콘 선명하게 (0 = 불투명)

	local equipmentFrame = Instance.new("Frame")
	equipmentFrame.Name = "EquipmentFrame"
	equipmentFrame.Parent = backgroundFrame
	equipmentFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	equipmentFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	equipmentFrame.Size = UDim2.new(0.4, 0, 0.75, 0) -- 세로 크기는 이전 조정값 유지
	equipmentFrame.BackgroundColor3 = Color3.fromRGB(70, 50, 70)
	equipmentFrame.BorderColor3 = Color3.fromRGB(200, 180, 200)
	equipmentFrame.BorderSizePixel = 2
	equipmentFrame.Visible = false
	equipmentFrame.ZIndex = 5
	Instance.new("UICorner", equipmentFrame).CornerRadius = cornerRadius
	print("EquipmentUIBuilder: EquipmentFrame 생성됨")

	local padding = Instance.new("UIPadding")
	padding.Parent = equipmentFrame
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)

	local titleLabel = GuiUtils.CreateTextLabel(equipmentFrame, "TitleLabel",
		UDim2.new(0.5, 0, 0, padding.PaddingTop.Offset + 5), -- PaddingTop 이후 약간의 여유
		UDim2.new(1, -(padding.PaddingLeft.Offset + padding.PaddingRight.Offset), 0, 30), -- 너비는 패딩 고려
		"장비", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 20
	)
	-- 타이틀 레이블의 실제 높이를 가져오거나 예상되는 높이를 사용합니다.
	-- GuiUtils.CreateTextLabel이 반환하는 TextLabel의 AbsoluteSize.Y는 이 시점에서 0일 수 있으므로,
	-- Size.Y.Offset (30)을 사용합니다.
	local titleLabelHeight = titleLabel.Size.Y.Offset
	local titleBottomYOffset = padding.PaddingTop.Offset + titleLabelHeight + 10 -- 타이틀 하단 Y 오프셋 + 추가 여백

	local slotSize = UDim2.new(0, 64, 0, 64)
	local slotStartXScale = 0.3 -- 프레임 내부에서의 상대적 X 위치 (패딩 고려 시 조정 필요할 수 있음)
	-- 또는 UDim2.new(0, padding.PaddingLeft.Offset + 원하는X오프셋, ...)

	-- <<< slotStartYOffset 조정: 슬롯들을 전체적으로 위로 올립니다 >>>
	-- 이전 값: local slotStartYOffset = titleBottomYOffset (타이틀 바로 아래 10px 여백)
	-- 조금 더 위로 올리려면 이 값을 줄입니다. 예: 타이틀 바로 아래 5px 여백
	local slotStartYOffset = padding.PaddingTop.Offset + titleLabelHeight + 4
	-- 또는 고정값으로 더 위로: local slotStartYOffset = 30 (값이 작을수록 위로 올라감, PaddingTop보다는 커야 함)

	local slotSpacingYPixels = 75 -- 각 슬롯의 시작점 Y 오프셋 간격 (슬롯 높이 64px + 간격 11px)
	local labelOffsetX = 0.25
	local slotBackgroundColor = Color3.fromRGB(40, 40, 45)
	local slotBorderColor = Color3.fromRGB(100,100,100)

	local function createEquipmentSlot(parent, name, slotIndex, labelText, defaultIconId)
		local slotYPos = UDim2.new(slotStartXScale, 0, 0, slotStartYOffset + (slotIndex * slotSpacingYPixels))

		local slotButton = Instance.new("ImageButton")
		slotButton.Name = name
		slotButton.Size = slotSize
		slotButton.Position = slotYPos
		slotButton.BackgroundColor3 = slotBackgroundColor
		slotButton.BackgroundTransparency = 0
		slotButton.BorderSizePixel = 1
		slotButton.BorderColor3 = slotBorderColor
		slotButton.AutoButtonColor = false
		slotButton.Image = ""
		slotButton.Parent = parent
		Instance.new("UICorner", slotButton).CornerRadius = cornerRadius

		local defaultIcon = Instance.new("ImageLabel")
		defaultIcon.Name = "DefaultSlotIcon"
		defaultIcon.Parent = slotButton
		defaultIcon.Size = UDim2.new(1, -4, 1, -4)
		defaultIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
		defaultIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		defaultIcon.Image = defaultIconId
		defaultIcon.ImageTransparency = defaultIconTransparency
		defaultIcon.BackgroundTransparency = 1
		defaultIcon.ScaleType = Enum.ScaleType.Fit
		defaultIcon.ZIndex = slotButton.ZIndex + 1
		defaultIcon.Visible = true

		local equippedIcon = Instance.new("ImageLabel")
		equippedIcon.Name = "EquippedItemIcon"
		equippedIcon.Parent = slotButton
		equippedIcon.Size = UDim2.new(1, 0, 1, 0)
		equippedIcon.Position = UDim2.new(0.5, 0, 0.5, 0)
		equippedIcon.AnchorPoint = Vector2.new(0.5, 0.5)
		equippedIcon.Image = ""
		equippedIcon.ImageTransparency = 0
		equippedIcon.BackgroundTransparency = 1
		equippedIcon.ScaleType = Enum.ScaleType.Fit
		equippedIcon.ZIndex = slotButton.ZIndex + 2
		equippedIcon.Visible = false

		local ratingStroke = Instance.new("UIStroke")
		ratingStroke.Name = "RatingStroke"
		ratingStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
		ratingStroke.LineJoinMode = Enum.LineJoinMode.Round
		ratingStroke.Thickness = 2
		ratingStroke.Color = Color3.fromRGB(180,180,180)
		ratingStroke.Transparency = 1
		ratingStroke.Parent = slotButton

		-- 강화 레벨 표시용 TextLabel 추가 (InventoryUIManager에서 내용 업데이트)
		local levelLabel = GuiUtils.CreateTextLabel(slotButton, "LevelLabel",
			UDim2.new(1, -2, 0, 2), UDim2.new(0.3, 10, 0.2, 0), -- 오른쪽 위에 작게 표시
			"", Vector2.new(1,0), Enum.TextXAlignment.Right, Enum.TextYAlignment.Top, 10, Color3.fromRGB(255,230,150)
		)
		levelLabel.TextStrokeTransparency = 0.5
		levelLabel.ZIndex = slotButton.ZIndex + 3 -- 아이콘보다 위에 표시
		levelLabel.Visible = false -- 초기에는 숨김

		GuiUtils.CreateTextLabel(parent, name.."Label",
			UDim2.new(slotYPos.X.Scale + labelOffsetX, slotYPos.X.Offset, slotYPos.Y.Scale, slotYPos.Y.Offset),
			UDim2.new(0.3, 0, slotSize.Y.Offset, 0), labelText, Vector2.new(0, 0),
			Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 14
		)
		print("EquipmentUIBuilder: "..name.." 생성됨 (Y위치: " .. slotYPos.Y.Offset .. ")")
		return slotButton
	end

	createEquipmentSlot(equipmentFrame, "WeaponSlot", 0, "무기", defaultWeaponSlotIconImage)
	createEquipmentSlot(equipmentFrame, "ArmorSlot", 1, "방어구", defaultArmorSlotIconImage)
	createEquipmentSlot(equipmentFrame, "AccessorySlot1", 2, "악세사리 1", defaultAccessorySlotIconImage)
	createEquipmentSlot(equipmentFrame, "AccessorySlot2", 3, "악세사리 2", defaultAccessorySlotIconImage)
	createEquipmentSlot(equipmentFrame, "AccessorySlot3", 4, "악세사리 3", defaultAccessorySlotIconImage)

	local closeEquipmentButton = Instance.new("TextButton")
	closeEquipmentButton.Name = "CloseButton"
	closeEquipmentButton.Parent = equipmentFrame
	closeEquipmentButton.AnchorPoint = Vector2.new(1, 1)
	closeEquipmentButton.Position = UDim2.new(1, -padding.PaddingRight.Offset, 1, -padding.PaddingBottom.Offset)
	closeEquipmentButton.Size = UDim2.new(0.25, 0, 0, 35)
	closeEquipmentButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	closeEquipmentButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeEquipmentButton.TextScaled = true
	closeEquipmentButton.Font = Enum.Font.SourceSansBold
	closeEquipmentButton.Text = "닫기"
	closeEquipmentButton.BorderSizePixel = 0
	closeEquipmentButton.ZIndex = 6
	Instance.new("UICorner", closeEquipmentButton).CornerRadius = cornerRadius
	print("EquipmentUIBuilder: EquipmentFrame CloseButton 생성됨")

	print("EquipmentUIBuilder: 장비 창 UI 생성 완료 (슬롯 전체 위치 위로 조정됨).")
end

return EquipmentUIBuilder
