-- ReplicatedStorage > Modules > LoadingScreenBuilder.lua

local LoadingScreenBuilder = {}

-- �ʿ��� ���� ��������
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- ��� ���� ����
local GuiUtils

-- ��� �ʱ�ȭ �Լ�
function LoadingScreenBuilder.Init()
	local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
	GuiUtils = require(modulesFolder:WaitForChild("GuiUtils"))
	print("LoadingScreenBuilder: Initialized.")
end

-- �ε� ȭ�� UI ���� �Լ�
function LoadingScreenBuilder.Build(mainGui, backgroundFrame, framesFolder)
	if not GuiUtils then LoadingScreenBuilder.Init() end
	if not GuiUtils then warn("LoadingScreenBuilder.Build: GuiUtils not loaded!"); return end

	print("LoadingScreenBuilder: �ε� ȭ�� UI ���� ����...")

	-- �ε� ȭ�� ��ü�� ���� ������
	local loadingFrame = Instance.new("Frame")
	loadingFrame.Name = "LoadingFrame"
	loadingFrame.Parent = framesFolder -- Frames ���� �Ʒ��� ��ġ
	loadingFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	loadingFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	loadingFrame.Size = UDim2.new(1, 0, 1, 0) -- ȭ�� ��ü ũ��
	loadingFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20) -- �ణ ��ο� �Ķ��� ���
	loadingFrame.BorderSizePixel = 0
	loadingFrame.Visible = false -- ó������ ���ܵ�
	loadingFrame.ZIndex = 190 -- ��Ʈ�κ��ٴ� �Ʒ�, �ٸ� UI���ٴ� ����

	-- �ε� �ؽ�Ʈ ���̺�
	local loadingText = GuiUtils.CreateTextLabel(loadingFrame, "LoadingText",
		UDim2.new(0.5, 0, 0.8, 0), -- ȭ�� �ϴ� �߾� ��ó
		UDim2.new(0.5, 0, 0.1, 0), -- �ؽ�Ʈ ũ��
		"�ε� ��...",
		Vector2.new(0.5, 0.5), -- �߾� ����
		Enum.TextXAlignment.Center,
		Enum.TextYAlignment.Center,
		24, -- �ؽ�Ʈ ũ��
		Color3.fromRGB(220, 220, 220) -- ���� ȸ�� �ؽ�Ʈ
	)
	loadingText.Font = Enum.Font.SourceSansBold

	-- (���� ����) ���⿡ �ε� �� �Ǵ� ���ǳ� �̹��� ���� �߰��� �� �ֽ��ϴ�.
	-- ����: �ε� ���ǳ� �̹���
	-- local spinnerImage = Instance.new("ImageLabel")
	-- spinnerImage.Name = "SpinnerImage"
	-- spinnerImage.Parent = loadingFrame
	-- spinnerImage.AnchorPoint = Vector2.new(0.5, 0.5)
	-- spinnerImage.Position = UDim2.new(0.5, 0, 0.5, 0) -- �߾ӿ� ��ġ
	-- spinnerImage.Size = UDim2.new(0, 100, 0, 100)
	-- spinnerImage.Image = "rbxassetid://YOUR_SPINNER_IMAGE_ID" -- <<< ���ǳ� �̹��� ID �Է�
	-- spinnerImage.BackgroundTransparency = 1
	-- -- ���ǳ� ȸ�� �ִϸ��̼��� LoadingManager ���� ó���� �� �ֽ��ϴ�.

	print("LoadingScreenBuilder: �ε� ȭ�� UI ���� �Ϸ�.")
	return loadingFrame
end

return LoadingScreenBuilder