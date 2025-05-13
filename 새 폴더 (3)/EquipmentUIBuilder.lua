--[[
  EquipmentUIBuilder (ModuleScript)
  장비 창 UI를 생성합니다.
  *** [수정] 악세사리 슬롯 3개로 변경 및 UI 배치 조정 ***
]]
local EquipmentUIBuilder = {}

function EquipmentUIBuilder.Build(mainGui, backgroundFrame, framesFolder, GuiUtils)
	print("EquipmentUIBuilder: 장비 창 UI 생성 시작...")

	local cornerRadius = UDim.new(0, 8)

	local equipmentFrame = Instance.new("Frame")
	equipmentFrame.Name = "EquipmentFrame"
	equipmentFrame.Parent = backgroundFrame -- BackgroundFrame 아래에 배치 (팝업 형태)
	equipmentFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	equipmentFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	-- *** 수정: 슬롯 5개를 표시하기 위해 프레임 세로 크기 늘림 ***
	equipmentFrame.Size = UDim2.new(0.4, 0, 0.65, 0)
	equipmentFrame.BackgroundColor3 = Color3.fromRGB(70, 50, 70)
	equipmentFrame.BorderColor3 = Color3.fromRGB(200, 180, 200)
	equipmentFrame.BorderSizePixel = 2
	equipmentFrame.Visible = false
	equipmentFrame.ZIndex = 5
	Instance.new("UICorner", equipmentFrame).CornerRadius = cornerRadius
	print("EquipmentUIBuilder: EquipmentFrame 생성됨")

	GuiUtils.CreateTextLabel(equipmentFrame, "TitleLabel", UDim2.new(0.5, 0, 0.05, 0), UDim2.new(0.9, 0, 0.1, 0), "장비", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 20)

	-- 슬롯 공통 설정
	local slotSize = UDim2.new(0, 64, 0, 64) -- 슬롯 크기
	local slotStartX = 0.2 -- 슬롯 X 시작 위치
	local slotStartY = 0.15 -- 슬롯 Y 시작 위치
	local slotSpacingY = 0.18 -- 슬롯 간 세로 간격
	local labelOffsetX = 0.25 -- 슬롯 옆 레이블 X 간격

	-- 무기 슬롯
	local weaponSlot = Instance.new("ImageButton")
	weaponSlot.Name = "WeaponSlot"
	weaponSlot.Size = slotSize
	weaponSlot.Position = UDim2.new(slotStartX, 0, slotStartY, 0) -- Y: 0.15
	weaponSlot.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	weaponSlot.BorderSizePixel = 1
	weaponSlot.Parent = equipmentFrame
	Instance.new("UICorner", weaponSlot).CornerRadius = cornerRadius
	GuiUtils.CreateTextLabel(equipmentFrame, "WeaponSlotLabel", UDim2.new(slotStartX + labelOffsetX, 0, slotStartY, 0), UDim2.new(0.3, 0, slotSize.Y.Offset, 0), "무기", Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 14)
	print("EquipmentUIBuilder: WeaponSlot 생성됨")

	-- 방어구 슬롯
	local armorSlot = Instance.new("ImageButton")
	armorSlot.Name = "ArmorSlot"
	armorSlot.Size = slotSize
	armorSlot.Position = UDim2.new(slotStartX, 0, slotStartY + slotSpacingY, 0) -- Y: 0.15 + 0.18 = 0.33
	armorSlot.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	armorSlot.BorderSizePixel = 1
	armorSlot.Parent = equipmentFrame
	Instance.new("UICorner", armorSlot).CornerRadius = cornerRadius
	GuiUtils.CreateTextLabel(equipmentFrame, "ArmorSlotLabel", UDim2.new(slotStartX + labelOffsetX, 0, slotStartY + slotSpacingY, 0), UDim2.new(0.3, 0, slotSize.Y.Offset, 0), "방어구", Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 14)
	print("EquipmentUIBuilder: ArmorSlot 생성됨")

	-- 악세사리 슬롯 1
	local accessorySlot1 = Instance.new("ImageButton")
	accessorySlot1.Name = "AccessorySlot1" -- 이름 변경
	accessorySlot1.Size = slotSize
	accessorySlot1.Position = UDim2.new(slotStartX, 0, slotStartY + slotSpacingY * 2, 0) -- Y: 0.15 + 0.18*2 = 0.51
	accessorySlot1.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	accessorySlot1.BorderSizePixel = 1
	accessorySlot1.Parent = equipmentFrame
	Instance.new("UICorner", accessorySlot1).CornerRadius = cornerRadius
	GuiUtils.CreateTextLabel(equipmentFrame, "AccessorySlotLabel1", UDim2.new(slotStartX + labelOffsetX, 0, slotStartY + slotSpacingY * 2, 0), UDim2.new(0.4, 0, slotSize.Y.Offset, 0), "악세사리 1", Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 14)
	print("EquipmentUIBuilder: AccessorySlot1 생성됨")

	-- 악세사리 슬롯 2
	local accessorySlot2 = Instance.new("ImageButton")
	accessorySlot2.Name = "AccessorySlot2" -- 새 이름
	accessorySlot2.Size = slotSize
	accessorySlot2.Position = UDim2.new(slotStartX, 0, slotStartY + slotSpacingY * 3, 0) -- Y: 0.15 + 0.18*3 = 0.69
	accessorySlot2.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	accessorySlot2.BorderSizePixel = 1
	accessorySlot2.Parent = equipmentFrame
	Instance.new("UICorner", accessorySlot2).CornerRadius = cornerRadius
	GuiUtils.CreateTextLabel(equipmentFrame, "AccessorySlotLabel2", UDim2.new(slotStartX + labelOffsetX, 0, slotStartY + slotSpacingY * 3, 0), UDim2.new(0.4, 0, slotSize.Y.Offset, 0), "악세사리 2", Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 14)
	print("EquipmentUIBuilder: AccessorySlot2 생성됨")

	-- 악세사리 슬롯 3
	local accessorySlot3 = Instance.new("ImageButton")
	accessorySlot3.Name = "AccessorySlot3" -- 새 이름
	accessorySlot3.Size = slotSize
	accessorySlot3.Position = UDim2.new(slotStartX, 0, slotStartY + slotSpacingY * 4, 0) -- Y: 0.15 + 0.18*4 = 0.87
	accessorySlot3.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	accessorySlot3.BorderSizePixel = 1
	accessorySlot3.Parent = equipmentFrame
	Instance.new("UICorner", accessorySlot3).CornerRadius = cornerRadius
	GuiUtils.CreateTextLabel(equipmentFrame, "AccessorySlotLabel3", UDim2.new(slotStartX + labelOffsetX, 0, slotStartY + slotSpacingY * 4, 0), UDim2.new(0.4, 0, slotSize.Y.Offset, 0), "악세사리 3", Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 14)
	print("EquipmentUIBuilder: AccessorySlot3 생성됨")

	-- 닫기 버튼 위치 조정 (프레임 크기가 커졌으므로 기존 위치 유지해도 될 수 있음)
	local closeEquipmentButton = Instance.new("TextButton")
	closeEquipmentButton.Name = "CloseButton" -- ButtonHandler 에서 이 이름으로 찾음
	closeEquipmentButton.Parent = equipmentFrame
	closeEquipmentButton.AnchorPoint = Vector2.new(1, 1)
	closeEquipmentButton.Position = UDim2.new(0.95, 0, 0.95, 0)
	closeEquipmentButton.Size = UDim2.new(0.2, 0, 0.08, 0) -- 크기 조정 (프레임 높이 대비 비율)
	closeEquipmentButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	closeEquipmentButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeEquipmentButton.TextScaled = true
	closeEquipmentButton.Font = Enum.Font.SourceSansBold
	closeEquipmentButton.Text = "닫기"
	closeEquipmentButton.BorderSizePixel = 0
	closeEquipmentButton.ZIndex = 6
	Instance.new("UICorner", closeEquipmentButton).CornerRadius = cornerRadius
	print("EquipmentUIBuilder: EquipmentFrame CloseButton 생성됨")

	print("EquipmentUIBuilder: 장비 창 UI 생성 완료.")
end

return EquipmentUIBuilder