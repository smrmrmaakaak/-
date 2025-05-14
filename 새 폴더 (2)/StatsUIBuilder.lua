--[[
  StatsUIBuilder (ModuleScript)
  ���� â UI�� �����մϴ�. (�ű� ���� �ý��� �ݿ�)
  - �⺻ ���� (STR, AGI, INT, LUK) ���� UI ����
  - �䱸 ���� (DF, Sword, Gun) ǥ�� ���̺� �߰�
  - ���� �ɷ�ġ ǥ�� ���� (�⺻ Ʋ) �߰�
]]
local StatsUIBuilder = {}

function StatsUIBuilder.Build(mainGui, backgroundFrame, framesFolder, GuiUtils)
	print("StatsUIBuilder: ���� â UI ���� ���� (�ű� �ý���)...")

	local cornerRadius = UDim.new(0, 8)

	-- ���� â �⺻ ������
	local statsFrame = Instance.new("Frame")
	statsFrame.Name = "StatsFrame"
	statsFrame.Parent = backgroundFrame
	statsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	statsFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	statsFrame.Size = UDim2.new(0.5, 0, 0.7, 0) -- ũ�� ���� (���� ���� ���� Ȯ��)
	statsFrame.BackgroundColor3 = Color3.fromRGB(50, 70, 70)
	statsFrame.BorderColor3 = Color3.fromRGB(180, 200, 200)
	statsFrame.BorderSizePixel = 2
	statsFrame.Visible = false
	statsFrame.ZIndex = 5
	Instance.new("UICorner", statsFrame).CornerRadius = cornerRadius
	print("StatsUIBuilder: StatsFrame ������")

	-- ���� �� �⺻ ���� ���̺�
	GuiUtils.CreateTextLabel(statsFrame, "TitleLabel", UDim2.new(0.5, 0, 0.03, 0), UDim2.new(0.9, 0, 0.07, 0), "�ɷ�ġ", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 20)
	local statPointsLabel = GuiUtils.CreateTextLabel(statsFrame, "StatPointsLabel", UDim2.new(0.5, 0, 0.1, 0), UDim2.new(0.9, 0, 0.05, 0), "���� ����Ʈ: 0", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 16)

	-- �䱸 ���� ǥ�� ���̺� (StatPointsLabel �Ʒ�)
	local requirementStatsFrame = Instance.new("Frame")
	requirementStatsFrame.Name = "RequirementStatsFrame"
	requirementStatsFrame.Parent = statsFrame
	requirementStatsFrame.BackgroundTransparency = 1
	requirementStatsFrame.Size = UDim2.new(0.9, 0, 0.08, 0)
	requirementStatsFrame.Position = UDim2.new(0.5, 0, 0.16, 0) -- ��ġ ����
	requirementStatsFrame.AnchorPoint = Vector2.new(0.5, 0)
	local reqLayout = Instance.new("UIListLayout")
	reqLayout.FillDirection = Enum.FillDirection.Horizontal
	reqLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	reqLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	reqLayout.Padding = UDim.new(0, 10)
	reqLayout.Parent = requirementStatsFrame

	GuiUtils.CreateTextLabel(requirementStatsFrame, "DFLabel", UDim2.new(0.3, 0, 1, 0), UDim2.new(0.3, -5, 0.9, 0), "�Ǹ�����: 0", Vector2.new(0, 0.5), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 12, Color3.fromRGB(220, 200, 255))
	GuiUtils.CreateTextLabel(requirementStatsFrame, "SwordLabel", UDim2.new(0.3, 0, 1, 0), UDim2.new(0.3, -5, 0.9, 0), "�˼�: 0", Vector2.new(0, 0.5), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 12, Color3.fromRGB(200, 200, 200))
	GuiUtils.CreateTextLabel(requirementStatsFrame, "GunLabel", UDim2.new(0.3, 0, 1, 0), UDim2.new(0.3, -5, 0.9, 0), "�Ѽ�: 0", Vector2.new(0, 0.5), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 12, Color3.fromRGB(200, 200, 200))
	print("StatsUIBuilder: �䱸 ���� ���̺� �߰���")

	-- �⺻ ���� ���� ���� (���� ����)
	local baseStatsFrame = Instance.new("Frame")
	baseStatsFrame.Name = "BaseStatsFrame"
	baseStatsFrame.Parent = statsFrame
	baseStatsFrame.Size = UDim2.new(0.45, 0, 0.6, 0) -- �ʺ� ����
	baseStatsFrame.Position = UDim2.new(0.05, 0, 0.25, 0) -- ���� ��ġ
	baseStatsFrame.AnchorPoint = Vector2.new(0, 0)
	baseStatsFrame.BackgroundTransparency = 1
	local baseStatsLayout = Instance.new("UIListLayout")
	baseStatsLayout.Padding = UDim.new(0, 8)
	baseStatsLayout.FillDirection = Enum.FillDirection.Vertical
	baseStatsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	baseStatsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	baseStatsLayout.Parent = baseStatsFrame
	print("StatsUIBuilder: BaseStatsFrame ������")

	-- �⺻ ���� ���� ���� �Լ� (���ο�)
	local function createBaseStatLine(parent, statId, statDisplayName)
		local lineFrame = Instance.new("Frame")
		lineFrame.Name = statId .. "Line"
		lineFrame.Size = UDim2.new(1, 0, 0, 40) -- ���� ����
		lineFrame.BackgroundTransparency = 1
		lineFrame.Parent = parent

		GuiUtils.CreateTextLabel(lineFrame, statId .. "Label", UDim2.new(0.05, 0, 0.5, 0), UDim2.new(0.4, 0, 0.8, 0), statDisplayName .. ":", Vector2.new(0, 0.5), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 14)
		local valueLabel = GuiUtils.CreateTextLabel(lineFrame, statId .. "ValueLabel", UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.2, 0, 0.8, 0), "1", Vector2.new(0, 0.5), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 14)
		valueLabel.Name = statId .. "ValueLabel" -- �̸� ��Ȯ�� ����

		local increaseButton = Instance.new("TextButton")
		increaseButton.Name = "Increase" .. statId .. "Button"
		increaseButton.Size = UDim2.new(0, 30, 0, 30) -- ���簢�� ��ư
		increaseButton.AnchorPoint = Vector2.new(1, 0.5)
		increaseButton.Position = UDim2.new(0.95, 0, 0.5, 0)
		increaseButton.BackgroundColor3 = Color3.fromRGB(80, 150, 80)
		increaseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		increaseButton.Text = "+"
		increaseButton.Font = Enum.Font.SourceSansBold
		increaseButton.TextSize = 18
		increaseButton.Visible = true -- �⺻ ǥ�� (StatsUIManager���� ����)
		increaseButton.Parent = lineFrame
		Instance.new("UICorner", increaseButton).CornerRadius = UDim.new(1, 0) -- ���� ��ư

		return lineFrame
	end

	-- ���ο� �⺻ ���� ���� �߰�
	createBaseStatLine(baseStatsFrame, "STR", "��").LayoutOrder = 1
	createBaseStatLine(baseStatsFrame, "AGI", "��ø").LayoutOrder = 2
	createBaseStatLine(baseStatsFrame, "INT", "����").LayoutOrder = 3
	createBaseStatLine(baseStatsFrame, "LUK", "��").LayoutOrder = 4
	print("StatsUIBuilder: �⺻ ���� ���� �߰���")

	-- ���� �ɷ�ġ ǥ�� ���� (������ ����)
	local detailedStatsFrame = Instance.new("ScrollingFrame")
	detailedStatsFrame.Name = "DetailedStatsFrame"
	detailedStatsFrame.Parent = statsFrame
	detailedStatsFrame.Size = UDim2.new(0.45, 0, 0.6, 0) -- �ʺ� ����
	detailedStatsFrame.Position = UDim2.new(0.95, 0, 0.25, 0) -- ������ ��ġ
	detailedStatsFrame.AnchorPoint = Vector2.new(1, 0)
	detailedStatsFrame.BackgroundColor3 = Color3.fromRGB(40, 60, 60)
	detailedStatsFrame.BorderSizePixel = 1
	detailedStatsFrame.BorderColor3 = Color3.fromRGB(150, 180, 180)
	detailedStatsFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- ������ UIManager���� ä��
	detailedStatsFrame.ScrollBarThickness = 6
	Instance.new("UICorner", detailedStatsFrame).CornerRadius = cornerRadius
	print("StatsUIBuilder: DetailedStatsFrame ������")

	GuiUtils.CreateTextLabel(detailedStatsFrame, "DetailedTitle", UDim2.new(0.5, 0, 0.03, 0), UDim2.new(0.9, 0, 0.07, 0), "���� �ɷ�ġ", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 16, Color3.fromRGB(200, 220, 220))
	-- ���� �ɷ�ġ ������ StatsUIManager���� �������� ����

	-- �ݱ� ��ư
	local closeStatsButton = Instance.new("TextButton")
	closeStatsButton.Name = "CloseButton" -- �̸� ���� (ButtonHandler ȣȯ)
	closeStatsButton.Parent = statsFrame
	closeStatsButton.AnchorPoint = Vector2.new(0.5, 1) -- �߾� �ϴ����� ����
	closeStatsButton.Position = UDim2.new(0.5, 0, 0.95, 0) -- ��ġ ����
	closeStatsButton.Size = UDim2.new(0.3, 0, 0.08, 0) -- ũ�� ����
	closeStatsButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	closeStatsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeStatsButton.Font = Enum.Font.SourceSansBold
	closeStatsButton.Text = "�ݱ�"
	closeStatsButton.TextScaled = true
	closeStatsButton.BorderSizePixel = 0
	closeStatsButton.ZIndex = 6
	Instance.new("UICorner", closeStatsButton).CornerRadius = cornerRadius
	print("StatsUIBuilder: StatsFrame CloseButton ������")

	print("StatsUIBuilder: ���� â UI ���� �Ϸ� (�ű� �ý���).")
end

return StatsUIBuilder