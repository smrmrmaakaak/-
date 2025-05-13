-- GuiUtils.lua

local GuiUtils = {}

-- 기본 Frame 생성 함수
function GuiUtils.CreateFrame(parent, name, position, size, anchorPoint, color, transparency, zIndex)
	local frame = Instance.new("Frame")
	frame.Name = name
	frame.Parent = parent
	frame.AnchorPoint = anchorPoint or Vector2.new(0, 0)
	frame.Position = position or UDim2.new(0, 0, 0, 0)
	frame.Size = size or UDim2.new(0, 100, 0, 100)
	frame.BackgroundColor3 = color or Color3.new(0.5, 0.5, 0.5)
	frame.BackgroundTransparency = transparency or 0
	frame.BorderSizePixel = 0
	frame.ZIndex = zIndex or 1
	return frame
end

-- ImageLabel 생성 함수
function GuiUtils.CreateImageLabel(parent, name, position, size, anchorPoint, image, scaleType, zIndex)
	local imageLabel = Instance.new("ImageLabel")
	imageLabel.Name = name
	imageLabel.Parent = parent
	imageLabel.AnchorPoint = anchorPoint or Vector2.new(0, 0)
	imageLabel.Position = position or UDim2.new(0, 0, 0, 0)
	imageLabel.Size = size or UDim2.new(0, 50, 0, 50)
	imageLabel.Image = image or ""
	imageLabel.ScaleType = scaleType or Enum.ScaleType.Fit
	imageLabel.BackgroundTransparency = 1
	imageLabel.BorderSizePixel = 0
	imageLabel.ZIndex = zIndex or 1
	return imageLabel
end

-- TextButton 생성 함수
function GuiUtils.CreateButton(parent, name, position, size, anchorPoint, text, callback, zIndex)
	local button = Instance.new("TextButton")
	button.Name = name
	button.Parent = parent
	button.AnchorPoint = anchorPoint or Vector2.new(0, 0)
	button.Position = position or UDim2.new(0, 0, 0, 0)
	button.Size = size or UDim2.new(0, 100, 0, 30)
	button.Text = text or "Button"
	button.Font = Enum.Font.SourceSansBold
	button.TextScaled = true
	button.TextColor3 = Color3.new(1, 1, 1)
	button.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
	button.BorderSizePixel = 0
	button.ZIndex = zIndex or 1
	if callback then
		button.MouseButton1Click:Connect(callback)
	end
	return button
end

-- TextLabel 생성 함수 (수정됨)
function GuiUtils.CreateTextLabel(parent, name, position, size, text, anchorPoint, textXAlign, textYAlign, textSize, textColor, font, textScaled)
	local label = Instance.new("TextLabel")
	label.Name = name
	label.Parent = parent
	label.AnchorPoint = anchorPoint or Vector2.new(0, 0)
	label.Position = position or UDim2.new(0, 0, 0, 0)

	-- ##### 중요 수정: 전달된 size 인자가 있으면 그것을 사용, 없으면 기본값 사용 #####
	if size then
		label.Size = size
	else
		label.Size = UDim2.new(0, 100, 0, 30) -- 기본값
	end
	-- ######################################################################

	label.Text = text or "Label"
	label.Font = font or Enum.Font.SourceSans
	label.TextSize = textSize or 14
	label.TextColor3 = textColor or Color3.new(1, 1, 1)

	-- TextScaled는 일반적으로 레이아웃을 고정해야 할 때 false로 설정합니다.
	-- true로 설정하면 명시적인 Size가 무시될 수 있습니다.
	label.TextScaled = textScaled or false 

	label.TextXAlignment = textXAlign or Enum.TextXAlignment.Center
	label.TextYAlignment = textYAlign or Enum.TextYAlignment.Center
	label.BackgroundTransparency = 1
	label.BorderSizePixel = 0
	return label
end


-- 리소스 바 (HP, MP, EXP 등) 생성 함수
function GuiUtils.CreateResourceBar(parent, resourceName, position, size, anchorPoint, barColor, textColor)
	-- 배경 프레임 생성
	local background = Instance.new("Frame")
	background.Name = resourceName .. "BarBackground"
	background.Parent = parent
	background.AnchorPoint = anchorPoint or Vector2.new(0, 0)
	background.Position = position or UDim2.new(0, 0, 0, 0)
	background.Size = size or UDim2.new(1, 0, 0, 20)
	background.BackgroundColor3 = Color3.fromRGB(50, 50, 50) -- 어두운 배경색
	background.BorderSizePixel = 1
	background.BorderColor3 = Color3.fromRGB(200, 200, 200)

	-- 실제 바 프레임 생성
	local bar = Instance.new("Frame")
	bar.Name = resourceName .. "Bar"
	bar.Parent = background
	bar.Size = UDim2.new(1, 0, 1, 0) -- 초기에는 꽉 참
	bar.BackgroundColor3 = barColor or Color3.fromRGB(0, 200, 0) -- 기본 초록색
	bar.BorderSizePixel = 0

	-- 텍스트 레이블 생성 (예: "HP: 100 / 100")
	local textLabel = Instance.new("TextLabel")
	textLabel.Name = resourceName .. "Label"
	textLabel.Parent = background
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.BackgroundTransparency = 1
	textLabel.Font = Enum.Font.SourceSansBold
	textLabel.TextScaled = true
	textLabel.TextColor3 = textColor or Color3.new(1, 1, 1)
	textLabel.ZIndex = background.ZIndex + 1
	textLabel.Text = resourceName .. ": ? / ?" -- 초기 텍스트

	return background -- 배경 프레임을 반환하여 위치/크기 조절 용이하게 함
end

return GuiUtils