-- ReplicatedStorage > Modules > FullScreenEffectBuilder.lua

local FullScreenEffectBuilder = {}

function FullScreenEffectBuilder.Build(mainGui, backgroundFrame, framesFolder, GuiUtils)
	if not GuiUtils then
		local ModuleManager = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("ModuleManager"))
		GuiUtils = ModuleManager:GetModule("GuiUtils")
		if not GuiUtils then warn("FullScreenEffectBuilder: GuiUtils �ε� ����!"); return nil end
	end
	print("FullScreenEffectBuilder: ��ü ȭ�� ��ȭ ����Ʈ UI ���� ���� (��ƼŬ ���� ����� - ����ũ �ؽ�ó)...")

	local cornerRadius = UDim.new(0, 8)

	local fullScreenEffectFrame = Instance.new("Frame")
	fullScreenEffectFrame.Name = "FullScreenEnhancementEffectFrame"
	fullScreenEffectFrame.Parent = framesFolder
	fullScreenEffectFrame.Size = UDim2.new(1, 0, 1, 0)
	fullScreenEffectFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	fullScreenEffectFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	fullScreenEffectFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- ������: ������ ���� ������ (������)
	fullScreenEffectFrame.BackgroundTransparency = 0.8
	fullScreenEffectFrame.Visible = false
	fullScreenEffectFrame.ZIndex = 190
	print("FullScreenEffectBuilder: FullScreenEnhancementEffectFrame ������ (������ ������ ���)")

	local emitterPositionMarker = Instance.new("Frame")
	emitterPositionMarker.Name = "EmitterPositionMarker"
	emitterPositionMarker.Parent = fullScreenEffectFrame
	emitterPositionMarker.Size = UDim2.new(0, 20, 0, 20)
	emitterPositionMarker.Position = UDim2.new(0.5, 0, 0.5, 0) -- ȭ�� �߾�
	emitterPositionMarker.AnchorPoint = Vector2.new(0.5, 0.5)
	emitterPositionMarker.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- ���� �ʷϻ�
	emitterPositionMarker.BorderSizePixel = 0
	emitterPositionMarker.ZIndex = fullScreenEffectFrame.ZIndex + 2
	print("FullScreenEffectBuilder: EmitterPositionMarker ������")

	local effectParticleEmitter = Instance.new("ParticleEmitter")
	effectParticleEmitter.Name = "FullScreenParticle"
	effectParticleEmitter.Parent = fullScreenEffectFrame -- ��ƼŬ �̹����� �θ�� fullScreenEffectFrame�� �߾�

	-- FullScreenEffectBuilder.lua �� effectParticleEmitter ���� �κи� ��ü

	local effectParticleEmitter = Instance.new("ParticleEmitter")
	effectParticleEmitter.Name = "FullScreenParticle"
	effectParticleEmitter.Parent = fullScreenEffectFrame -- �θ�� ��ü ȭ�� ������

	-- �ؽ�ó ID (���� �⺻���� Roblox �ΰ� �� �ϳ� �Ǵ� ���� ���ε��� �ܼ��� ��� �� �̹��� ID)
	-- effectParticleEmitter.Texture = "rbxassetid://605197384" -- ���� �õ� ID
	effectParticleEmitter.Texture = "rbxassetid://287439428" -- �ſ� �ܼ��� �κ�Ͻ� '��' ������ (�׽�Ʈ��)
	print("FullScreenEffectBuilder: Particle Texture ID set to: " .. effectParticleEmitter.Texture)

	-- === ��ƼŬ�� ȭ�� �߾ӿ� '��'ó���̶� �������� Ȯ���ϱ� ���� �ش��� ���� ===
	effectParticleEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 0)) -- �ſ� ���� �����
	effectParticleEmitter.LightEmission = 1 
	effectParticleEmitter.Size = NumberSequence.new(100) -- �ſ� ū ���� ũ�� (�ȼ�)
	effectParticleEmitter.Transparency = NumberSequence.new(0) -- �׻� ������ ������
	effectParticleEmitter.Lifetime = NumberRange.new(10, 10) -- ��ƼŬ ���� �ſ� �ſ� ��� (10��)
	effectParticleEmitter.Rate = 5 -- �ʴ� 5���� ���� (���� ����)
	effectParticleEmitter.Speed = NumberRange.new(0, 0) -- �ӵ� 0 (���� ���ڸ�)
	effectParticleEmitter.SpreadAngle = Vector2.new(0, 0) -- ���� ������ ����
	effectParticleEmitter.Rotation = NumberRange.new(0, 0) 
	effectParticleEmitter.RotSpeed = NumberRange.new(0, 0)
	effectParticleEmitter.Acceleration = Vector3.new(0, 0, 0) 
	effectParticleEmitter.Drag = 0

	-- !!! �߿�: �� �׽�Ʈ������ �̹��Ͱ� �׻� ���� �ֵ��� �մϴ�. !!!
	effectParticleEmitter.Enabled = true -- <<< �׽�Ʈ�� ���� ���� �� �ٷ� Ȱ��ȭ

	print("FullScreenEffectBuilder: FullScreenParticle ������ (�ش��� ����� ����, Enabled=true)")
	-- === ��ƼŬ ����� �Ӽ� ���� �� ===

	local effectTextLabel = GuiUtils.CreateTextLabel(fullScreenEffectFrame, "EffectStatusText",
		UDim2.new(0.5, 0, 0.8, 0), UDim2.new(0.6, 0, 0.1, 0),
		"�� ȭ ��...",
		Vector2.new(0.5, 0.5), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center,
		36, Color3.fromRGB(255, 255, 220), Enum.Font.SourceSansBold)
	effectTextLabel.TextStrokeTransparency = 0.3
	effectTextLabel.ZIndex = fullScreenEffectFrame.ZIndex + 1
	print("FullScreenEffectBuilder: EffectStatusText ������")

	print("FullScreenEffectBuilder: ��ü ȭ�� ��ȭ ����Ʈ UI ���� �Ϸ�.")
	return fullScreenEffectFrame
end

return FullScreenEffectBuilder