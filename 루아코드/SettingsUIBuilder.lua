-- ReplicatedStorage > Modules > SettingsUIBuilder.lua

local SettingsUIBuilder = {}

function SettingsUIBuilder.Build(mainGui, backgroundFrame, framesFolder, GuiUtils)
	if not GuiUtils then print("SettingsUIBuilder: GuiUtils is required!"); return nil end
	print("SettingsUIBuilder: 설정 창 UI 생성 시작...")

	local cornerRadius = UDim.new(0, 8)
	-- local smallCornerRadius = UDim.new(0, 4) -- 슬라이더 등 작은 요소용 (이제 불필요할 수 있음)

	local settingsFrame = Instance.new("Frame")
	settingsFrame.Name = "SettingsFrame"
	settingsFrame.Parent = framesFolder
	settingsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	settingsFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	settingsFrame.Size = UDim2.new(0.5, 0, 0.7, 0)
	settingsFrame.BackgroundColor3 = Color3.fromRGB(55, 55, 65)
	settingsFrame.BorderColor3 = Color3.fromRGB(180, 180, 190)
	settingsFrame.BorderSizePixel = 2
	settingsFrame.Visible = false
	settingsFrame.ZIndex = 7
	Instance.new("UICorner", settingsFrame).CornerRadius = cornerRadius
	print("SettingsUIBuilder: SettingsFrame 생성됨")

	GuiUtils.CreateTextLabel(settingsFrame, "TitleLabel",
		UDim2.new(0.5, 0, 0.05, 0), UDim2.new(0.9, 0, 0.1, 0),
		"설정", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 20)

	local contentFrame = Instance.new("Frame")
	contentFrame.Name = "ContentFrame"
	contentFrame.Parent = settingsFrame
	contentFrame.Size = UDim2.new(0.9, 0, 0.75, 0)
	contentFrame.Position = UDim2.new(0.5, 0, 0.15, 0)
	contentFrame.AnchorPoint = Vector2.new(0.5, 0)
	contentFrame.BackgroundTransparency = 1
	contentFrame.ClipsDescendants = true
	local contentLayout = Instance.new("UIListLayout")
	contentLayout.Padding = UDim.new(0, 15)
	contentLayout.FillDirection = Enum.FillDirection.Vertical
	contentLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	contentLayout.Parent = contentFrame
	print("SettingsUIBuilder: ContentFrame 및 UIListLayout 생성됨")

	local audioSettingsLabel = GuiUtils.CreateTextLabel(contentFrame, "AudioSettingsLabel",
		UDim2.new(0.5, 0, 0, 0), UDim2.new(0.9, 0, 0, 25),
		"오디오 설정", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 18)
	audioSettingsLabel.LayoutOrder = 1
	audioSettingsLabel.TextColor3 = Color3.fromRGB(220, 220, 250)
	print("SettingsUIBuilder: AudioSettingsLabel 생성됨")

	-- BGM 볼륨 조절부 (버튼과 값 표시 레이블 사용)
	local bgmVolumeContainer = GuiUtils.CreateFrame(contentFrame, "BGMVolumeContainer",
		UDim2.new(0.5, 0, 0, 0), UDim2.new(0.9, 0, 0, 40), -- 높이 약간 줄임
		Vector2.new(0.5, 0), nil, 1)
	bgmVolumeContainer.LayoutOrder = 2
	local bgmListLayout = Instance.new("UIListLayout") -- 가로 정렬용
	bgmListLayout.FillDirection = Enum.FillDirection.Horizontal
	bgmListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	bgmListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	bgmListLayout.Padding = UDim.new(0,5)
	bgmListLayout.Parent = bgmVolumeContainer

	GuiUtils.CreateTextLabel(bgmVolumeContainer, "BGMVolumeTextLabel",
		UDim2.new(0,0,0.5,0), UDim2.new(0.25, 0, 1, 0), -- 너비 조정
		"배경음악:", Vector2.new(0, 0.5), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 14).LayoutOrder = 1

	local bgmDecreaseButton = GuiUtils.CreateButton(bgmVolumeContainer, "BGMDecreaseButton", UDim2.new(0,0,0.5,0), UDim2.new(0.1,0,0.8,0), Vector2.new(0,0.5), "-", nil, bgmVolumeContainer.ZIndex+1)
	bgmDecreaseButton.TextSize = 18; bgmDecreaseButton.LayoutOrder = 2
	local bgmVolumeValueLabel = GuiUtils.CreateTextLabel(bgmVolumeContainer, "BGMVolumeValueLabel", UDim2.new(0,0,0.5,0), UDim2.new(0.2, 0, 0.8, 0), "50%", Vector2.new(0.5,0.5), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 14)
	bgmVolumeValueLabel.LayoutOrder = 3
	local bgmIncreaseButton = GuiUtils.CreateButton(bgmVolumeContainer, "BGMIncreaseButton", UDim2.new(0,0,0.5,0), UDim2.new(0.1,0,0.8,0), Vector2.new(0,0.5), "+", nil, bgmVolumeContainer.ZIndex+1)
	bgmIncreaseButton.TextSize = 18; bgmIncreaseButton.LayoutOrder = 4

	local bgmMuteButton = GuiUtils.CreateButton(bgmVolumeContainer, "BGMMuteButton",
		UDim2.new(0,0,0.5,0), UDim2.new(0.2, 0, 0.8, 0), -- 너비 조정
		Vector2.new(0, 0.5), "끄기", nil, bgmVolumeContainer.ZIndex + 1)
	bgmMuteButton.TextSize = 12; bgmMuteButton.LayoutOrder = 5
	print("SettingsUIBuilder: BGM 볼륨 조절 버튼들 생성됨")

	-- SFX 볼륨 조절부 (버튼과 값 표시 레이블 사용)
	local sfxVolumeContainer = GuiUtils.CreateFrame(contentFrame, "SFXVolumeContainer",
		UDim2.new(0.5, 0, 0, 0), UDim2.new(0.9, 0, 0, 40),
		Vector2.new(0.5, 0), nil, 1)
	sfxVolumeContainer.LayoutOrder = 3
	local sfxListLayout = Instance.new("UIListLayout") -- 가로 정렬용
	sfxListLayout.FillDirection = Enum.FillDirection.Horizontal
	sfxListLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	sfxListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	sfxListLayout.Padding = UDim.new(0,5)
	sfxListLayout.Parent = sfxVolumeContainer

	GuiUtils.CreateTextLabel(sfxVolumeContainer, "SFXVolumeTextLabel",
		UDim2.new(0,0,0.5,0), UDim2.new(0.25, 0, 1, 0),
		"효과음:", Vector2.new(0, 0.5), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 14).LayoutOrder = 1

	local sfxDecreaseButton = GuiUtils.CreateButton(sfxVolumeContainer, "SFXDecreaseButton", UDim2.new(0,0,0.5,0), UDim2.new(0.1,0,0.8,0), Vector2.new(0,0.5), "-", nil, sfxVolumeContainer.ZIndex+1)
	sfxDecreaseButton.TextSize = 18; sfxDecreaseButton.LayoutOrder = 2
	local sfxVolumeValueLabel = GuiUtils.CreateTextLabel(sfxVolumeContainer, "SFXVolumeValueLabel", UDim2.new(0,0,0.5,0), UDim2.new(0.2, 0, 0.8, 0), "80%", Vector2.new(0.5,0.5), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 14)
	sfxVolumeValueLabel.LayoutOrder = 3
	local sfxIncreaseButton = GuiUtils.CreateButton(sfxVolumeContainer, "SFXIncreaseButton", UDim2.new(0,0,0.5,0), UDim2.new(0.1,0,0.8,0), Vector2.new(0,0.5), "+", nil, sfxVolumeContainer.ZIndex+1)
	sfxIncreaseButton.TextSize = 18; sfxIncreaseButton.LayoutOrder = 4

	local sfxMuteButton = GuiUtils.CreateButton(sfxVolumeContainer, "SFXMuteButton",
		UDim2.new(0,0,0.5,0), UDim2.new(0.2, 0, 0.8, 0),
		Vector2.new(0, 0.5), "끄기", nil, sfxVolumeContainer.ZIndex + 1)
	sfxMuteButton.TextSize = 12; sfxMuteButton.LayoutOrder = 5
	print("SettingsUIBuilder: SFX 볼륨 조절 버튼들 생성됨")


	local resetButton = GuiUtils.CreateButton(contentFrame, "ResetDataButton",
		UDim2.new(0.5, 0, 0, 0),
		UDim2.new(0.5, 0, 0, 40),
		Vector2.new(0.5, 0),
		"데이터 초기화", nil, contentFrame.ZIndex + 1)
	resetButton.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
	resetButton.LayoutOrder = 4
	Instance.new("UICorner", resetButton).CornerRadius = cornerRadius
	print("SettingsUIBuilder: ResetDataButton 생성됨 (UIListLayout 사용)")

	local closeButton = GuiUtils.CreateButton(settingsFrame, "CloseButton",
		UDim2.new(0.5, 0, 0.92, 0), UDim2.new(0.3, 0, 0.08, 0),
		Vector2.new(0.5, 1), "닫기", nil, settingsFrame.ZIndex + 1)
	closeButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
	Instance.new("UICorner", closeButton).CornerRadius = cornerRadius
	print("SettingsUIBuilder: SettingsFrame CloseButton 생성됨 (위치 조정)")

	print("SettingsUIBuilder: 설정 창 UI 생성 완료.")
	return settingsFrame
end

return SettingsUIBuilder