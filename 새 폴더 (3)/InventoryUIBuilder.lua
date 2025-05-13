--[[
  InventoryUIBuilder (ModuleScript)
  �κ��丮 UI�� �����մϴ�.
]]
local InventoryUIBuilder = {}

function InventoryUIBuilder.Build(mainGui, backgroundFrame, framesFolder, GuiUtils)
	print("InventoryUIBuilder: �κ��丮 UI ���� ����...")

	local cornerRadius = UDim.new(0, 8)

	local inventoryFrame = Instance.new("Frame")
	inventoryFrame.Name = "InventoryFrame"
	inventoryFrame.Parent = backgroundFrame -- BackgroundFrame �Ʒ��� ��ġ (�˾� ����)
	inventoryFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	inventoryFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	inventoryFrame.Size = UDim2.new(0.7, 0, 0.7, 0)
	inventoryFrame.BackgroundColor3 = Color3.fromRGB(80, 60, 60)
	inventoryFrame.BorderColor3 = Color3.fromRGB(220, 190, 190)
	inventoryFrame.BorderSizePixel = 2
	inventoryFrame.Visible = false
	inventoryFrame.ZIndex = 5
	Instance.new("UICorner", inventoryFrame).CornerRadius = cornerRadius
	print("InventoryUIBuilder: InventoryFrame ������")

	GuiUtils.CreateTextLabel(inventoryFrame, "TitleLabel", UDim2.new(0.5, 0, 0.05, 0), UDim2.new(0.9, 0, 0.1, 0), "�κ��丮", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 20)

	local inventoryListFrame = Instance.new("ScrollingFrame")
	inventoryListFrame.Name = "InventoryList"
	inventoryListFrame.Parent = inventoryFrame
	inventoryListFrame.AnchorPoint = Vector2.new(0.5, 0)
	inventoryListFrame.Position = UDim2.new(0.5, 0, 0.15, 0)
	inventoryListFrame.Size = UDim2.new(0.9, 0, 0.7, 0)
	inventoryListFrame.BackgroundColor3 = Color3.fromRGB(60, 40, 40)
	inventoryListFrame.BorderSizePixel = 1
	inventoryListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	inventoryListFrame.ScrollBarThickness = 8
	Instance.new("UICorner", inventoryListFrame).CornerRadius = cornerRadius
	print("InventoryUIBuilder: InventoryList ScrollingFrame ������")

	local inventoryGridLayout = Instance.new("UIGridLayout")
	inventoryGridLayout.Parent = inventoryListFrame
	inventoryGridLayout.CellPadding = UDim2.new(0, 5, 0, 5)
	inventoryGridLayout.CellSize = UDim2.new(0, 64, 0, 64)
	inventoryGridLayout.StartCorner = Enum.StartCorner.TopLeft
	inventoryGridLayout.FillDirection = Enum.FillDirection.Horizontal
	inventoryGridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	inventoryGridLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	inventoryGridLayout.SortOrder = Enum.SortOrder.LayoutOrder
	print("InventoryUIBuilder: InventoryList UIGridLayout ������")

	local closeInventoryButton = Instance.new("TextButton")
	closeInventoryButton.Name = "CloseInventoryButton"
	closeInventoryButton.Parent = inventoryFrame
	closeInventoryButton.AnchorPoint = Vector2.new(1, 1)
	closeInventoryButton.Position = UDim2.new(0.95, 0, 0.95, 0)
	closeInventoryButton.Size = UDim2.new(0.2, 0, 0.1, 0)
	closeInventoryButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	closeInventoryButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeInventoryButton.TextScaled = true
	closeInventoryButton.Font = Enum.Font.SourceSansBold
	closeInventoryButton.Text = "�ݱ�"
	closeInventoryButton.BorderSizePixel = 0
	closeInventoryButton.ZIndex = 6
	Instance.new("UICorner", closeInventoryButton).CornerRadius = cornerRadius
	print("InventoryUIBuilder: CloseInventoryButton ������")

	print("InventoryUIBuilder: �κ��丮 UI ���� �Ϸ�.")
end

return InventoryUIBuilder
