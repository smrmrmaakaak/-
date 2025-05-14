-- ReplicatedStorage > Modules > FullScreenEffectBuilder.lua

local FullScreenEffectBuilder = {}

function FullScreenEffectBuilder.Build(mainGui, backgroundFrame, framesFolder, GuiUtils)
	if not GuiUtils then
		local ModuleManager = require(game:GetService("ReplicatedStorage"):WaitForChild("Modules"):WaitForChild("ModuleManager"))
		GuiUtils = ModuleManager:GetModule("GuiUtils")
		if not GuiUtils then warn("FullScreenEffectBuilder: GuiUtils 로드 실패!"); return nil end
	end
	print("FullScreenEffectBuilder: 전체 화면 강화 이펙트 UI 생성 시작 (파티클 집중 디버그 - 스모크 텍스처)...")

	local cornerRadius = UDim.new(0, 8)

	local fullScreenEffectFrame = Instance.new("Frame")
	fullScreenEffectFrame.Name = "FullScreenEnhancementEffectFrame"
	fullScreenEffectFrame.Parent = framesFolder
	fullScreenEffectFrame.Size = UDim2.new(1, 0, 1, 0)
	fullScreenEffectFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	fullScreenEffectFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	fullScreenEffectFrame.BackgroundColor3 = Color3.fromRGB(255, 0, 0) -- 디버깅용: 프레임 영역 빨간색 (반투명)
	fullScreenEffectFrame.BackgroundTransparency = 0.8
	fullScreenEffectFrame.Visible = false
	fullScreenEffectFrame.ZIndex = 190
	print("FullScreenEffectBuilder: FullScreenEnhancementEffectFrame 생성됨 (빨간색 반투명 배경)")

	local emitterPositionMarker = Instance.new("Frame")
	emitterPositionMarker.Name = "EmitterPositionMarker"
	emitterPositionMarker.Parent = fullScreenEffectFrame
	emitterPositionMarker.Size = UDim2.new(0, 20, 0, 20)
	emitterPositionMarker.Position = UDim2.new(0.5, 0, 0.5, 0) -- 화면 중앙
	emitterPositionMarker.AnchorPoint = Vector2.new(0.5, 0.5)
	emitterPositionMarker.BackgroundColor3 = Color3.fromRGB(0, 255, 0) -- 밝은 초록색
	emitterPositionMarker.BorderSizePixel = 0
	emitterPositionMarker.ZIndex = fullScreenEffectFrame.ZIndex + 2
	print("FullScreenEffectBuilder: EmitterPositionMarker 생성됨")

	local effectParticleEmitter = Instance.new("ParticleEmitter")
	effectParticleEmitter.Name = "FullScreenParticle"
	effectParticleEmitter.Parent = fullScreenEffectFrame -- 파티클 이미터의 부모는 fullScreenEffectFrame의 중앙

	-- FullScreenEffectBuilder.lua 내 effectParticleEmitter 설정 부분만 교체

	local effectParticleEmitter = Instance.new("ParticleEmitter")
	effectParticleEmitter.Name = "FullScreenParticle"
	effectParticleEmitter.Parent = fullScreenEffectFrame -- 부모는 전체 화면 프레임

	-- 텍스처 ID (가장 기본적인 Roblox 로고 중 하나 또는 직접 업로드한 단순한 흰색 점 이미지 ID)
	-- effectParticleEmitter.Texture = "rbxassetid://605197384" -- 기존 시도 ID
	effectParticleEmitter.Texture = "rbxassetid://287439428" -- 매우 단순한 로블록스 '점' 아이콘 (테스트용)
	print("FullScreenEffectBuilder: Particle Texture ID set to: " .. effectParticleEmitter.Texture)

	-- === 파티클이 화면 중앙에 '점'처럼이라도 찍히는지 확인하기 위한 극단적 설정 ===
	effectParticleEmitter.Color = ColorSequence.new(Color3.fromRGB(255, 255, 0)) -- 매우 밝은 노란색
	effectParticleEmitter.LightEmission = 1 
	effectParticleEmitter.Size = NumberSequence.new(100) -- 매우 큰 고정 크기 (픽셀)
	effectParticleEmitter.Transparency = NumberSequence.new(0) -- 항상 완전히 불투명
	effectParticleEmitter.Lifetime = NumberRange.new(10, 10) -- 파티클 수명 매우 매우 길게 (10초)
	effectParticleEmitter.Rate = 5 -- 초당 5개만 방출 (관찰 용이)
	effectParticleEmitter.Speed = NumberRange.new(0, 0) -- 속도 0 (완전 제자리)
	effectParticleEmitter.SpreadAngle = Vector2.new(0, 0) -- 전혀 퍼지지 않음
	effectParticleEmitter.Rotation = NumberRange.new(0, 0) 
	effectParticleEmitter.RotSpeed = NumberRange.new(0, 0)
	effectParticleEmitter.Acceleration = Vector3.new(0, 0, 0) 
	effectParticleEmitter.Drag = 0

	-- !!! 중요: 이 테스트에서는 이미터가 항상 켜져 있도록 합니다. !!!
	effectParticleEmitter.Enabled = true -- <<< 테스트를 위해 빌드 시 바로 활성화

	print("FullScreenEffectBuilder: FullScreenParticle 생성됨 (극단적 디버그 설정, Enabled=true)")
	-- === 파티클 디버그 속성 수정 끝 ===

	local effectTextLabel = GuiUtils.CreateTextLabel(fullScreenEffectFrame, "EffectStatusText",
		UDim2.new(0.5, 0, 0.8, 0), UDim2.new(0.6, 0, 0.1, 0),
		"강 화 중...",
		Vector2.new(0.5, 0.5), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center,
		36, Color3.fromRGB(255, 255, 220), Enum.Font.SourceSansBold)
	effectTextLabel.TextStrokeTransparency = 0.3
	effectTextLabel.ZIndex = fullScreenEffectFrame.ZIndex + 1
	print("FullScreenEffectBuilder: EffectStatusText 생성됨")

	print("FullScreenEffectBuilder: 전체 화면 강화 이펙트 UI 생성 완료.")
	return fullScreenEffectFrame
end

return FullScreenEffectBuilder