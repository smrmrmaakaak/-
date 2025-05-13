-- ReplicatedStorage > Modules > IntroBuilder.lua

local IntroBuilder = {}

-- �ʿ��� ���� ��������
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService") -- �ִϸ��̼ǿ� �ʿ�

-- ��� ���� ����
local GuiUtils

-- ��� �ʱ�ȭ �Լ�
function IntroBuilder.Init()
	local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
	GuiUtils = require(modulesFolder:WaitForChild("GuiUtils"))
	print("IntroBuilder: Initialized.")
end

-- ��Ʈ�� UI ���� �Լ�
-- mainGui: ��� ScreenGui
-- backgroundFrame: ��� UI�� �θ� �� ��� ������
-- framesFolder: Ư�� �˾�/ȭ�� �����ӵ��� ���� ����
function IntroBuilder.Build(mainGui, backgroundFrame, framesFolder)
	if not GuiUtils then IntroBuilder.Init() end -- GuiUtils �ε� ����
	if not GuiUtils then warn("IntroBuilder.Build: GuiUtils not loaded!"); return end

	print("IntroBuilder: ��Ʈ�� UI ���� ����...")

	-- ��Ʈ�� ȭ�� ��ü�� ���� ������
	local introFrame = Instance.new("Frame")
	introFrame.Name = "IntroFrame"
	introFrame.Parent = framesFolder -- ������ �����ӵ��� ��Ƶδ� Frames ���� �Ʒ��� ��ġ
	introFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	introFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	introFrame.Size = UDim2.new(1, 0, 1, 0) -- ȭ�� ��ü ũ��
	introFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- �⺻ ������ ���
	introFrame.BorderSizePixel = 0
	introFrame.Visible = false -- ó������ ���ܵ�
	introFrame.ZIndex = 200 -- �ٸ� ��� UI ��ҵ麸�� ���� ���̵��� ����

	-- ��Ʈ�� �̹��� (Ŀ���� �۾����� ȿ���� �� ���)
	local introImage = Instance.new("ImageLabel")
	introImage.Name = "IntroImage"
	introImage.Parent = introFrame
	introImage.AnchorPoint = Vector2.new(0.5, 0.5)
	introImage.Position = UDim2.new(0.5, 0, 0.5, 0) -- ������ �߾ӿ� ��ġ
	introImage.Size = UDim2.new(0.8, 0, 0.8, 0) -- ȭ���� 80% ũ��� ���� (�ִϸ��̼� ���� ũ��� �ٸ� �� ����)
	-- <<< �߿�: �Ʒ� 'YOUR_INTRO_IMAGE_ID' �κп� ���� ����� ��Ʈ�� �̹����� Asset ID�� �� �־��ּ���! (��: "rbxassetid://123456789") >>>
	introImage.Image = "rbxassetid://108021409421865"
	introImage.ScaleType = Enum.ScaleType.Fit -- �̹��� ���� ����
	introImage.BackgroundTransparency = 1 -- �̹��� ����� �����ϰ�
	introImage.ImageTransparency = 1 -- �̹����� ó���� ������ �����ϰ� ����

	print("IntroBuilder: ��Ʈ�� UI ���� �Ϸ�.")
	return introFrame -- ������ ������ ��ȯ (GuiManager ��� �����ϱ� ����)
end

-- ����: ��Ʈ�� �ִϸ��̼� ��� ������ IntroManager ��⿡�� ó���մϴ�.

return IntroBuilder