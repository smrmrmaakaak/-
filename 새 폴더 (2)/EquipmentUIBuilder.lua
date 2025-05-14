-- EquipmentUIBuilder.lua

--[[
  EquipmentUIBuilder (ModuleScript)
  ��� â UI�� �����մϴ�.
  *** [����] ���� ��ü ��ġ ���� ����, ���� ������ ���� (�׵θ� ����, ������ �и�) ***
]]
local EquipmentUIBuilder = {}

function EquipmentUIBuilder.Build(mainGui, backgroundFrame, framesFolder, GuiUtils)
	print("EquipmentUIBuilder: ��� â UI ���� ���� (���� ��ü ��ġ ���� ����)...")

	local cornerRadius = UDim.new(0, 8)

	-- �⺻ ���� ������ �̹��� ID (���� ID�� ��ü �ʿ�)
	local defaultWeaponSlotIconImage = "rbxassetid://122953630794668"
	local defaultArmorSlotIconImage = "rbxassetid://107446706579540"
	local defaultAccessorySlotIconImage = "rbxassetid://102260956806130"
	local defaultIconTransparency = 0 -- �⺻ ������ �����ϰ� (0 = ������)

	local equipmentFrame = Instance.new("Frame")
	equipmentFrame.Name = "EquipmentFrame"
	equipmentFrame.Parent = backgroundFrame
	equipmentFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	equipmentFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	equipmentFrame.Size = UDim2.new(0.4, 0, 0.75, 0) -- ���� ũ��� ���� ������ ����
	equipmentFrame.BackgroundColor3 = Color3.fromRGB(70, 50, 70)
	equipmentFrame.BorderColor3 = Color3.fromRGB(200, 180, 200)
	equipmentFrame.BorderSizePixel = 2
	equipmentFrame.Visible = false
	equipmentFrame.ZIndex = 5
	Instance.new("UICorner", equipmentFrame).CornerRadius = cornerRadius
	print("EquipmentUIBuilder: EquipmentFrame ������")

	local padding = Instance.new("UIPadding")
	padding.Parent = equipmentFrame
	padding.PaddingTop = UDim.new(0, 10)
	padding.PaddingBottom = UDim.new(0, 10)
	padding.PaddingLeft = UDim.new(0, 10)
	padding.PaddingRight = UDim.new(0, 10)

	local titleLabel = GuiUtils.CreateTextLabel(equipmentFrame, "TitleLabel",
		UDim2.new(0.5, 0, 0, padding.PaddingTop.Offset + 5), -- PaddingTop ���� �ణ�� ����
		UDim2.new(1, -(padding.PaddingLeft.Offset + padding.PaddingRight.Offset), 0, 30), -- �ʺ�� �е� ���
		"���", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 20
	)
	-- Ÿ��Ʋ ���̺��� ���� ���̸� �������ų� ����Ǵ� ���̸� ����մϴ�.
	-- GuiUtils.CreateTextLabel�� ��ȯ�ϴ� TextLabel�� AbsoluteSize.Y�� �� �������� 0�� �� �����Ƿ�,
	-- Size.Y.Offset (30)�� ����մϴ�.
	local titleLabelHeight = titleLabel.Size.Y.Offset
	local titleBottomYOffset = padding.PaddingTop.Offset + titleLabelHeight + 10 -- Ÿ��Ʋ �ϴ� Y ������ + �߰� ����

	local slotSize = UDim2.new(0, 64, 0, 64)
	local slotStartXScale = 0.3 -- ������ ���ο����� ����� X ��ġ (�е� ��� �� ���� �ʿ��� �� ����)
	-- �Ǵ� UDim2.new(0, padding.PaddingLeft.Offset + ���ϴ�X������, ...)

	-- <<< slotStartYOffset ����: ���Ե��� ��ü������ ���� �ø��ϴ� >>>
	-- ���� ��: local slotStartYOffset = titleBottomYOffset (Ÿ��Ʋ �ٷ� �Ʒ� 10px ����)
	-- ���� �� ���� �ø����� �� ���� ���Դϴ�. ��: Ÿ��Ʋ �ٷ� �Ʒ� 5px ����
	local slotStartYOffset = padding.PaddingTop.Offset + titleLabelHeight + 4
	-- �Ǵ� ���������� �� ����: local slotStartYOffset = 30 (���� �������� ���� �ö�, PaddingTop���ٴ� Ŀ�� ��)

	local slotSpacingYPixels = 75 -- �� ������ ������ Y ������ ���� (���� ���� 64px + ���� 11px)
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

		-- ��ȭ ���� ǥ�ÿ� TextLabel �߰� (InventoryUIManager���� ���� ������Ʈ)
		local levelLabel = GuiUtils.CreateTextLabel(slotButton, "LevelLabel",
			UDim2.new(1, -2, 0, 2), UDim2.new(0.3, 10, 0.2, 0), -- ������ ���� �۰� ǥ��
			"", Vector2.new(1,0), Enum.TextXAlignment.Right, Enum.TextYAlignment.Top, 10, Color3.fromRGB(255,230,150)
		)
		levelLabel.TextStrokeTransparency = 0.5
		levelLabel.ZIndex = slotButton.ZIndex + 3 -- �����ܺ��� ���� ǥ��
		levelLabel.Visible = false -- �ʱ⿡�� ����

		GuiUtils.CreateTextLabel(parent, name.."Label",
			UDim2.new(slotYPos.X.Scale + labelOffsetX, slotYPos.X.Offset, slotYPos.Y.Scale, slotYPos.Y.Offset),
			UDim2.new(0.3, 0, slotSize.Y.Offset, 0), labelText, Vector2.new(0, 0),
			Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 14
		)
		print("EquipmentUIBuilder: "..name.." ������ (Y��ġ: " .. slotYPos.Y.Offset .. ")")
		return slotButton
	end

	createEquipmentSlot(equipmentFrame, "WeaponSlot", 0, "����", defaultWeaponSlotIconImage)
	createEquipmentSlot(equipmentFrame, "ArmorSlot", 1, "��", defaultArmorSlotIconImage)
	createEquipmentSlot(equipmentFrame, "AccessorySlot1", 2, "�Ǽ��縮 1", defaultAccessorySlotIconImage)
	createEquipmentSlot(equipmentFrame, "AccessorySlot2", 3, "�Ǽ��縮 2", defaultAccessorySlotIconImage)
	createEquipmentSlot(equipmentFrame, "AccessorySlot3", 4, "�Ǽ��縮 3", defaultAccessorySlotIconImage)

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
	closeEquipmentButton.Text = "�ݱ�"
	closeEquipmentButton.BorderSizePixel = 0
	closeEquipmentButton.ZIndex = 6
	Instance.new("UICorner", closeEquipmentButton).CornerRadius = cornerRadius
	print("EquipmentUIBuilder: EquipmentFrame CloseButton ������")

	print("EquipmentUIBuilder: ��� â UI ���� �Ϸ� (���� ��ü ��ġ ���� ������).")
end

return EquipmentUIBuilder