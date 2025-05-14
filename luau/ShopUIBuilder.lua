--[[
  ShopUIBuilder (ModuleScript)
  ���� UI�� �����մϴ�.
]]
local ShopUIBuilder = {}

function ShopUIBuilder.Build(mainGui, backgroundFrame, framesFolder, GuiUtils)
	print("ShopUIBuilder: ���� UI ���� ����...")

	local cornerRadius = UDim.new(0, 8)
	local smallCornerRadius = UDim.new(0, 4)

	local shopFrame = Instance.new("Frame")
	shopFrame.Name = "ShopFrame"
	shopFrame.Parent = backgroundFrame -- BackgroundFrame �Ʒ��� ��ġ (�˾� ����)
	shopFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	shopFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	shopFrame.Size = UDim2.new(0.6, 0, 0.7, 0)
	shopFrame.BackgroundColor3 = Color3.fromRGB(60, 80, 60)
	shopFrame.BorderColor3 = Color3.fromRGB(190, 220, 190)
	shopFrame.BorderSizePixel = 2
	shopFrame.Visible = false
	shopFrame.ZIndex = 5
	Instance.new("UICorner", shopFrame).CornerRadius = cornerRadius
	print("ShopUIBuilder: ShopFrame ������")

	GuiUtils.CreateTextLabel(shopFrame, "TitleLabel", UDim2.new(0.5, 0, 0.05, 0), UDim2.new(0.9, 0, 0.1, 0), "����", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 20)

	local tabFrame = Instance.new("Frame")
	tabFrame.Name = "TabFrame"
	tabFrame.Size = UDim2.new(1, -20, 0, 30)
	tabFrame.Position = UDim2.new(0.5, 0, 0.15, 0)
	tabFrame.AnchorPoint = Vector2.new(0.5, 0)
	tabFrame.BackgroundTransparency = 1
	tabFrame.Parent = shopFrame
	print("ShopUIBuilder: Shop TabFrame ������")
	local tabLayout = Instance.new("UIListLayout")
	tabLayout.FillDirection = Enum.FillDirection.Horizontal
	tabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	tabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	tabLayout.Padding = UDim.new(0, 10)
	tabLayout.Parent = tabFrame

	local buyTabButton = Instance.new("TextButton")
	buyTabButton.Name = "BuyTabButton"
	buyTabButton.Size = UDim2.new(0, 100, 1, 0)
	buyTabButton.BackgroundColor3 = Color3.fromRGB(80, 100, 80) -- �⺻ Ȱ�� ����
	buyTabButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	buyTabButton.Text = "����"
	buyTabButton.Font = Enum.Font.SourceSansBold
	buyTabButton.TextSize = 16
	buyTabButton.Parent = tabFrame
	Instance.new("UICorner", buyTabButton).CornerRadius = smallCornerRadius

	local sellTabButton = Instance.new("TextButton")
	sellTabButton.Name = "SellTabButton"
	sellTabButton.Size = UDim2.new(0, 100, 1, 0)
	sellTabButton.BackgroundColor3 = Color3.fromRGB(50, 70, 50) -- �⺻ ��Ȱ�� ����
	sellTabButton.TextColor3 = Color3.fromRGB(200, 200, 200)
	sellTabButton.Text = "�Ǹ�"
	sellTabButton.Font = Enum.Font.SourceSansBold
	sellTabButton.TextSize = 16
	sellTabButton.Parent = tabFrame
	Instance.new("UICorner", sellTabButton).CornerRadius = smallCornerRadius

	local itemListFrame = Instance.new("ScrollingFrame")
	itemListFrame.Name = "ItemList"
	itemListFrame.Parent = shopFrame
	itemListFrame.AnchorPoint = Vector2.new(0.5, 0)
	itemListFrame.Position = UDim2.new(0.5, 0, 0.25, 0)
	itemListFrame.Size = UDim2.new(0.9, 0, 0.6, 0)
	itemListFrame.BackgroundColor3 = Color3.fromRGB(40, 60, 40)
	itemListFrame.BorderSizePixel = 1
	itemListFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
	itemListFrame.ScrollBarThickness = 8
	Instance.new("UICorner", itemListFrame).CornerRadius = cornerRadius
	print("ShopUIBuilder: ItemList ScrollingFrame ������")
	local shopListLayout = Instance.new("UIListLayout")
	shopListLayout.Parent = itemListFrame
	shopListLayout.Padding = UDim.new(0, 5)
	shopListLayout.FillDirection = Enum.FillDirection.Vertical
	shopListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	shopListLayout.SortOrder = Enum.SortOrder.LayoutOrder
	print("ShopUIBuilder: ItemList UIListLayout ������")

	local closeShopButton = Instance.new("TextButton")
	closeShopButton.Name = "CloseShopButton"
	closeShopButton.Parent = shopFrame
	closeShopButton.AnchorPoint = Vector2.new(1, 1)
	closeShopButton.Position = UDim2.new(0.95, 0, 0.95, 0)
	closeShopButton.Size = UDim2.new(0.2, 0, 0.1, 0)
	closeShopButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	closeShopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeShopButton.TextScaled = true
	closeShopButton.Font = Enum.Font.SourceSansBold
	closeShopButton.Text = "�ݱ�"
	closeShopButton.BorderSizePixel = 0
	closeShopButton.ZIndex = 6
	Instance.new("UICorner", closeShopButton).CornerRadius = cornerRadius
	print("ShopUIBuilder: CloseShopButton ������")

	print("ShopUIBuilder: ���� UI ���� �Ϸ�.")
end

return ShopUIBuilder
