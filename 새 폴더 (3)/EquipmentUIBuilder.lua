--[[
  EquipmentUIBuilder (ModuleScript)
  ��� â UI�� �����մϴ�.
  *** [����] �Ǽ��縮 ���� 3���� ���� �� UI ��ġ ���� ***
]]
local EquipmentUIBuilder = {}

function EquipmentUIBuilder.Build(mainGui, backgroundFrame, framesFolder, GuiUtils)
	print("EquipmentUIBuilder: ��� â UI ���� ����...")

	local cornerRadius = UDim.new(0, 8)

	local equipmentFrame = Instance.new("Frame")
	equipmentFrame.Name = "EquipmentFrame"
	equipmentFrame.Parent = backgroundFrame -- BackgroundFrame �Ʒ��� ��ġ (�˾� ����)
	equipmentFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	equipmentFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	-- *** ����: ���� 5���� ǥ���ϱ� ���� ������ ���� ũ�� �ø� ***
	equipmentFrame.Size = UDim2.new(0.4, 0, 0.65, 0)
	equipmentFrame.BackgroundColor3 = Color3.fromRGB(70, 50, 70)
	equipmentFrame.BorderColor3 = Color3.fromRGB(200, 180, 200)
	equipmentFrame.BorderSizePixel = 2
	equipmentFrame.Visible = false
	equipmentFrame.ZIndex = 5
	Instance.new("UICorner", equipmentFrame).CornerRadius = cornerRadius
	print("EquipmentUIBuilder: EquipmentFrame ������")

	GuiUtils.CreateTextLabel(equipmentFrame, "TitleLabel", UDim2.new(0.5, 0, 0.05, 0), UDim2.new(0.9, 0, 0.1, 0), "���", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 20)

	-- ���� ���� ����
	local slotSize = UDim2.new(0, 64, 0, 64) -- ���� ũ��
	local slotStartX = 0.2 -- ���� X ���� ��ġ
	local slotStartY = 0.15 -- ���� Y ���� ��ġ
	local slotSpacingY = 0.18 -- ���� �� ���� ����
	local labelOffsetX = 0.25 -- ���� �� ���̺� X ����

	-- ���� ����
	local weaponSlot = Instance.new("ImageButton")
	weaponSlot.Name = "WeaponSlot"
	weaponSlot.Size = slotSize
	weaponSlot.Position = UDim2.new(slotStartX, 0, slotStartY, 0) -- Y: 0.15
	weaponSlot.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	weaponSlot.BorderSizePixel = 1
	weaponSlot.Parent = equipmentFrame
	Instance.new("UICorner", weaponSlot).CornerRadius = cornerRadius
	GuiUtils.CreateTextLabel(equipmentFrame, "WeaponSlotLabel", UDim2.new(slotStartX + labelOffsetX, 0, slotStartY, 0), UDim2.new(0.3, 0, slotSize.Y.Offset, 0), "����", Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 14)
	print("EquipmentUIBuilder: WeaponSlot ������")

	-- �� ����
	local armorSlot = Instance.new("ImageButton")
	armorSlot.Name = "ArmorSlot"
	armorSlot.Size = slotSize
	armorSlot.Position = UDim2.new(slotStartX, 0, slotStartY + slotSpacingY, 0) -- Y: 0.15 + 0.18 = 0.33
	armorSlot.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	armorSlot.BorderSizePixel = 1
	armorSlot.Parent = equipmentFrame
	Instance.new("UICorner", armorSlot).CornerRadius = cornerRadius
	GuiUtils.CreateTextLabel(equipmentFrame, "ArmorSlotLabel", UDim2.new(slotStartX + labelOffsetX, 0, slotStartY + slotSpacingY, 0), UDim2.new(0.3, 0, slotSize.Y.Offset, 0), "��", Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 14)
	print("EquipmentUIBuilder: ArmorSlot ������")

	-- �Ǽ��縮 ���� 1
	local accessorySlot1 = Instance.new("ImageButton")
	accessorySlot1.Name = "AccessorySlot1" -- �̸� ����
	accessorySlot1.Size = slotSize
	accessorySlot1.Position = UDim2.new(slotStartX, 0, slotStartY + slotSpacingY * 2, 0) -- Y: 0.15 + 0.18*2 = 0.51
	accessorySlot1.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	accessorySlot1.BorderSizePixel = 1
	accessorySlot1.Parent = equipmentFrame
	Instance.new("UICorner", accessorySlot1).CornerRadius = cornerRadius
	GuiUtils.CreateTextLabel(equipmentFrame, "AccessorySlotLabel1", UDim2.new(slotStartX + labelOffsetX, 0, slotStartY + slotSpacingY * 2, 0), UDim2.new(0.4, 0, slotSize.Y.Offset, 0), "�Ǽ��縮 1", Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 14)
	print("EquipmentUIBuilder: AccessorySlot1 ������")

	-- �Ǽ��縮 ���� 2
	local accessorySlot2 = Instance.new("ImageButton")
	accessorySlot2.Name = "AccessorySlot2" -- �� �̸�
	accessorySlot2.Size = slotSize
	accessorySlot2.Position = UDim2.new(slotStartX, 0, slotStartY + slotSpacingY * 3, 0) -- Y: 0.15 + 0.18*3 = 0.69
	accessorySlot2.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	accessorySlot2.BorderSizePixel = 1
	accessorySlot2.Parent = equipmentFrame
	Instance.new("UICorner", accessorySlot2).CornerRadius = cornerRadius
	GuiUtils.CreateTextLabel(equipmentFrame, "AccessorySlotLabel2", UDim2.new(slotStartX + labelOffsetX, 0, slotStartY + slotSpacingY * 3, 0), UDim2.new(0.4, 0, slotSize.Y.Offset, 0), "�Ǽ��縮 2", Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 14)
	print("EquipmentUIBuilder: AccessorySlot2 ������")

	-- �Ǽ��縮 ���� 3
	local accessorySlot3 = Instance.new("ImageButton")
	accessorySlot3.Name = "AccessorySlot3" -- �� �̸�
	accessorySlot3.Size = slotSize
	accessorySlot3.Position = UDim2.new(slotStartX, 0, slotStartY + slotSpacingY * 4, 0) -- Y: 0.15 + 0.18*4 = 0.87
	accessorySlot3.BackgroundColor3 = Color3.fromRGB(50, 50, 50)
	accessorySlot3.BorderSizePixel = 1
	accessorySlot3.Parent = equipmentFrame
	Instance.new("UICorner", accessorySlot3).CornerRadius = cornerRadius
	GuiUtils.CreateTextLabel(equipmentFrame, "AccessorySlotLabel3", UDim2.new(slotStartX + labelOffsetX, 0, slotStartY + slotSpacingY * 4, 0), UDim2.new(0.4, 0, slotSize.Y.Offset, 0), "�Ǽ��縮 3", Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 14)
	print("EquipmentUIBuilder: AccessorySlot3 ������")

	-- �ݱ� ��ư ��ġ ���� (������ ũ�Ⱑ Ŀ�����Ƿ� ���� ��ġ �����ص� �� �� ����)
	local closeEquipmentButton = Instance.new("TextButton")
	closeEquipmentButton.Name = "CloseButton" -- ButtonHandler ���� �� �̸����� ã��
	closeEquipmentButton.Parent = equipmentFrame
	closeEquipmentButton.AnchorPoint = Vector2.new(1, 1)
	closeEquipmentButton.Position = UDim2.new(0.95, 0, 0.95, 0)
	closeEquipmentButton.Size = UDim2.new(0.2, 0, 0.08, 0) -- ũ�� ���� (������ ���� ��� ����)
	closeEquipmentButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	closeEquipmentButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeEquipmentButton.TextScaled = true
	closeEquipmentButton.Font = Enum.Font.SourceSansBold
	closeEquipmentButton.Text = "�ݱ�"
	closeEquipmentButton.BorderSizePixel = 0
	closeEquipmentButton.ZIndex = 6
	Instance.new("UICorner", closeEquipmentButton).CornerRadius = cornerRadius
	print("EquipmentUIBuilder: EquipmentFrame CloseButton ������")

	print("EquipmentUIBuilder: ��� â UI ���� �Ϸ�.")
end

return EquipmentUIBuilder