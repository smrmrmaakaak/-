-- DialogueUIBuilder.lua (����: �ʻ�ȭ ��ġ ���� �� ������ ���� ������)

local DialogueUIBuilder = {}

function DialogueUIBuilder.Build(mainGui, backgroundFrame, framesFolder, GuiUtils)
	print("DialogueUIBuilder: ��ȭ â UI ���� ����...")

	local cornerRadius = UDim.new(0, 8)
	local smallCornerRadius = UDim.new(0, 4)

	local dialogueFrame = Instance.new("Frame")
	dialogueFrame.Name = "DialogueFrame"
	dialogueFrame.Parent = backgroundFrame
	dialogueFrame.AnchorPoint = Vector2.new(0.5, 1)
	dialogueFrame.Size = UDim2.new(0.9, 0, 0.40, 0)
	dialogueFrame.Position = UDim2.new(0.5, 0, 0.98, 0)
	dialogueFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	dialogueFrame.BorderColor3 = Color3.fromRGB(180, 180, 200)
	dialogueFrame.BorderSizePixel = 2
	dialogueFrame.Visible = false
	dialogueFrame.ZIndex = 6
	Instance.new("UICorner", dialogueFrame).CornerRadius = cornerRadius
	print("DialogueUIBuilder: DialogueFrame ������ (ũ�� Ȯ���)")

	-- NPC �ʻ�ȭ
	local portraitWidthPixels = 150
	-- <<< [����] NpcPortraitImage X ��ġ ���� (��: �������� �� ����) >>>
	local npcPortraitImage = GuiUtils.CreateImageLabel(dialogueFrame, "NpcPortraitImage",
		UDim2.new(0.015, 0, 0.5, 0), -- X �������� 0.03 -> 0.015 �Ǵ� 0.02 ������ ����
		UDim2.new(0, portraitWidthPixels, 0.85, 0),
		Vector2.new(0, 0.5),
		"", Enum.ScaleType.Fit, dialogueFrame.ZIndex + 1)
	npcPortraitImage.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	npcPortraitImage.BackgroundTransparency = 0.5
	npcPortraitImage.Visible = false
	Instance.new("UICorner", npcPortraitImage).CornerRadius = smallCornerRadius
	print("DialogueUIBuilder: NpcPortraitImage ������ (X ��ġ ������)")

	-- <<< [����] �ʻ�ȭ ������ ������ ���� X ��ġ ������ >>>
	-- �ʻ�ȭ�� �� X ��ġ(��: 0.015 ������) + �ʻ�ȭ �ʺ� �ش��ϴ� ������ + ���� ������
	-- �Ǵ� �����ϰ� ������ �������� ����
	local portraitXScale = 0.015 -- ������ ������ ���� �����ϰ�
	local portraitRightEdgeScale = portraitXScale + (portraitWidthPixels / dialogueFrame.AbsoluteSize.X) -- �ʻ�ȭ ������ �� ������ �� (AbsoluteSize�� 0�� �� ������ ����)
	-- �� �� �����ϰ� ������ �������� contentStartXOffset�� ���, �ٸ� ��ҵ��� X Position�� ���������� �����ϴ� ���� ���
	local contentStartMarginPixels = 10 -- �ʻ�ȭ�� ������ ���� ���� (�ȼ�)
	local contentStartXOffset = portraitWidthPixels + (dialogueFrame.AbsoluteSize.X * portraitXScale) + contentStartMarginPixels
	-- ���� dialogueFrame.AbsoluteSize.X�� 0�̸� ������ �� �� �����Ƿ�, ó���� ��밪���θ� ����, ���� �׽�Ʈ�ϸ� �����ϴ°� �����ϴ�.
	-- ���⼭�� �� �� �����ϰ�, ����ó�� �ʻ�ȭ �ʺ� + ���� �������� �����մϴ�.
	-- �ʻ�ȭ�� ���� ���� �������� �ϹǷ�, (�ʻ�ȭ�� ���� X Position Offset) + portraitWidthPixels + ����
	local npcPortraitXOffset = dialogueFrame.AbsoluteSize.X * 0.015 -- �ʻ�ȭ�� ���� ���� X ������ (�뷫��)
	-- contentStartXOffset = npcPortraitXOffset + portraitWidthPixels + 15 -- �̷��� �ϸ� �ʹ� ��������.
	-- �׳� �ʻ�ȭ�� ������ ���� �������� ������ �ΰ� �����ϵ��� Positon UDim2�� X Offset�� ���
	local portraitRightEdgeOffset = portraitWidthPixels + 10 -- �ʻ�ȭ �ʺ� + �ణ�� ���� ���� (�� ���� �ʻ�ȭ�� X Position Offset�� 0�϶� ����)
	-- ������ �ʻ�ȭ X Position�� Scale�� �����Ƿ�, �� �κ��� �����ؾ� ��.
	-- ���� ������ ���: �ʻ�ȭ�� ������ X ������ ��ġ + �ణ�� ���� ������
	local contentStartXScaleAdjusted = 0.015 + (portraitWidthPixels / 1200) + 0.015 -- (1200�� ȭ�� �ʺ� ����, ������ dialogueFrame.AbsoluteSize.X ����ؾ��ϳ� ���� ������ 0�� �� ����)
	-- => UDim2.new(contentStartXScaleAdjusted, 0, ... )

	-- === �� �����ϰ� Ȯ���� ��� ===
	-- �ʻ�ȭ�� ���ʿ������� Ư�� �ȼ���ŭ �������� ���� (��: 20px)
	-- �������� �ʻ�ȭ�� ������ ���������� Ư�� �ȼ���ŭ �������� ���� (��: �ʻ�ȭ �ʺ� 150px + ���� 15px = 165px �������� ����)

	npcPortraitImage.Position = UDim2.new(0, 20, 0.5, 0) -- ���ʿ��� 20px ������
	local finalContentStartXOffset = 20 + portraitWidthPixels + 15 -- ���� ������ ���� X ������

	-- NPC �̸� ���̺�
	local npcNameLabel = GuiUtils.CreateTextLabel(dialogueFrame, "NpcNameLabel",
		UDim2.new(0, finalContentStartXOffset, 0.05, 0), -- �ʻ�ȭ �����ʿ� ��ġ
		UDim2.new(0.4, 0, 0.1, 0),
		"NPC �̸�", Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center,
		20, Color3.new(1,1,1), Enum.Font.SourceSansBold)
	npcNameLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	npcNameLabel.BackgroundTransparency = 0.5
	Instance.new("UICorner", npcNameLabel).CornerRadius = smallCornerRadius
	print("DialogueUIBuilder: NpcNameLabel ������ (������ ���� ��ġ ������)")

	-- ��ȭ �ؽ�Ʈ ���̺�
	local dialogueTextLabel = GuiUtils.CreateTextLabel(dialogueFrame, "DialogueTextLabel",
		UDim2.new(0, finalContentStartXOffset, 0.18, 0),
		UDim2.new(1, -(finalContentStartXOffset + 20), 0.45, 0), -- �ʺ�� ������ ������ (������ ���� 20px)
		"��ȭ ����...", Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Top,
		18, Color3.new(1,1,1), Enum.Font.SourceSans)
	dialogueTextLabel.TextWrapped = true
	dialogueTextLabel.RichText = true
	print("DialogueUIBuilder: DialogueTextLabel ������ (������ ���� ��ġ ������)")

	-- ���� ��ư ��ũ�Ѹ� ������
	local responseButtonsFrame = Instance.new("ScrollingFrame")
	responseButtonsFrame.Name = "ResponseButtonsFrame"
	responseButtonsFrame.Size = UDim2.new(1, -(finalContentStartXOffset + 20), 0.30, 0)
	responseButtonsFrame.Position = UDim2.new(0, finalContentStartXOffset, 0.65, 0)
	responseButtonsFrame.AnchorPoint = Vector2.new(0, 0)
	responseButtonsFrame.BackgroundTransparency = 1
	responseButtonsFrame.BorderSizePixel = 0
	responseButtonsFrame.CanvasSize = UDim2.new(0,0,0,0)
	responseButtonsFrame.ScrollBarThickness = 6
	responseButtonsFrame.Parent = dialogueFrame
	print("DialogueUIBuilder: ResponseButtonsFrame ������ (������ ���� ��ġ ������)")

	local responseLayout = Instance.new("UIGridLayout")
	responseLayout.Name = "ResponseGridLayout"
	responseLayout.FillDirection = Enum.FillDirection.Horizontal
	responseLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	responseLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	responseLayout.SortOrder = Enum.SortOrder.LayoutOrder
	responseLayout.CellPadding = UDim2.new(0, 8, 0, 8)
	responseLayout.CellSize = UDim2.new(0.32, 0, 0, 40)
	responseLayout.Parent = responseButtonsFrame
	print("DialogueUIBuilder: ResponseGridLayout ������")

	local responseButtonTemplate = Instance.new("TextButton")
	responseButtonTemplate.Name = "ResponseButtonTemplate"
	responseButtonTemplate.Size = UDim2.new(1, 0, 1, 0)
	responseButtonTemplate.BackgroundColor3 = Color3.fromRGB(70, 90, 130)
	responseButtonTemplate.TextColor3 = Color3.fromRGB(220, 220, 255)
	responseButtonTemplate.Font = Enum.Font.SourceSans
	responseButtonTemplate.TextSize = 18
	responseButtonTemplate.TextWrapped = true
	responseButtonTemplate.Visible = false
	responseButtonTemplate.Parent = responseButtonsFrame
	Instance.new("UICorner", responseButtonTemplate).CornerRadius = smallCornerRadius
	print("DialogueUIBuilder: ResponseButtonTemplate ������")

	print("DialogueUIBuilder: ��ȭ â UI ���� �Ϸ�.")
end

return DialogueUIBuilder