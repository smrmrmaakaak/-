-- DialogueUIBuilder.lua (수정: 초상화 위치 조정 및 콘텐츠 영역 재조정)

local DialogueUIBuilder = {}

function DialogueUIBuilder.Build(mainGui, backgroundFrame, framesFolder, GuiUtils)
	print("DialogueUIBuilder: 대화 창 UI 생성 시작...")

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
	print("DialogueUIBuilder: DialogueFrame 생성됨 (크기 확장됨)")

	-- NPC 초상화
	local portraitWidthPixels = 150
	-- <<< [수정] NpcPortraitImage X 위치 조정 (예: 왼쪽으로 더 붙임) >>>
	local npcPortraitImage = GuiUtils.CreateImageLabel(dialogueFrame, "NpcPortraitImage",
		UDim2.new(0.015, 0, 0.5, 0), -- X 스케일을 0.03 -> 0.015 또는 0.02 정도로 변경
		UDim2.new(0, portraitWidthPixels, 0.85, 0),
		Vector2.new(0, 0.5),
		"", Enum.ScaleType.Fit, dialogueFrame.ZIndex + 1)
	npcPortraitImage.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
	npcPortraitImage.BackgroundTransparency = 0.5
	npcPortraitImage.Visible = false
	Instance.new("UICorner", npcPortraitImage).CornerRadius = smallCornerRadius
	print("DialogueUIBuilder: NpcPortraitImage 생성됨 (X 위치 조정됨)")

	-- <<< [수정] 초상화 오른쪽 콘텐츠 시작 X 위치 재조정 >>>
	-- 초상화의 새 X 위치(예: 0.015 스케일) + 초상화 너비에 해당하는 스케일 + 여백 스케일
	-- 또는 간단하게 오프셋 기준으로 재계산
	local portraitXScale = 0.015 -- 위에서 설정한 값과 동일하게
	local portraitRightEdgeScale = portraitXScale + (portraitWidthPixels / dialogueFrame.AbsoluteSize.X) -- 초상화 오른쪽 끝 스케일 값 (AbsoluteSize는 0일 수 있으니 주의)
	-- 좀 더 안전하게 오프셋 기준으로 contentStartXOffset을 잡고, 다른 요소들의 X Position도 오프셋으로 설정하는 것을 고려
	local contentStartMarginPixels = 10 -- 초상화와 콘텐츠 사이 여백 (픽셀)
	local contentStartXOffset = portraitWidthPixels + (dialogueFrame.AbsoluteSize.X * portraitXScale) + contentStartMarginPixels
	-- 만약 dialogueFrame.AbsoluteSize.X가 0이면 문제가 될 수 있으므로, 처음엔 상대값으로만 가고, 실제 테스트하며 조정하는게 좋습니다.
	-- 여기서는 좀 더 간단하게, 이전처럼 초상화 너비 + 고정 여백으로 설정합니다.
	-- 초상화의 왼쪽 끝을 기준으로 하므로, (초상화의 왼쪽 X Position Offset) + portraitWidthPixels + 여백
	local npcPortraitXOffset = dialogueFrame.AbsoluteSize.X * 0.015 -- 초상화의 왼쪽 시작 X 오프셋 (대략적)
	-- contentStartXOffset = npcPortraitXOffset + portraitWidthPixels + 15 -- 이렇게 하면 너무 복잡해짐.
	-- 그냥 초상화의 오른쪽 끝을 기준으로 여백을 두고 시작하도록 Positon UDim2의 X Offset을 사용
	local portraitRightEdgeOffset = portraitWidthPixels + 10 -- 초상화 너비 + 약간의 왼쪽 여백 (이 값은 초상화의 X Position Offset이 0일때 기준)
	-- 지금은 초상화 X Position의 Scale이 있으므로, 그 부분을 감안해야 함.
	-- 가장 간단한 방법: 초상화의 오른쪽 X 스케일 위치 + 약간의 여백 스케일
	local contentStartXScaleAdjusted = 0.015 + (portraitWidthPixels / 1200) + 0.015 -- (1200은 화면 너비 예시, 실제론 dialogueFrame.AbsoluteSize.X 사용해야하나 빌드 시점엔 0일 수 있음)
	-- => UDim2.new(contentStartXScaleAdjusted, 0, ... )

	-- === 더 간단하고 확실한 방법 ===
	-- 초상화는 왼쪽에서부터 특정 픽셀만큼 떨어져서 시작 (예: 20px)
	-- 콘텐츠는 초상화의 오른쪽 끝에서부터 특정 픽셀만큼 떨어져서 시작 (예: 초상화 너비 150px + 여백 15px = 165px 지점에서 시작)

	npcPortraitImage.Position = UDim2.new(0, 20, 0.5, 0) -- 왼쪽에서 20px 떨어짐
	local finalContentStartXOffset = 20 + portraitWidthPixels + 15 -- 최종 콘텐츠 시작 X 오프셋

	-- NPC 이름 레이블
	local npcNameLabel = GuiUtils.CreateTextLabel(dialogueFrame, "NpcNameLabel",
		UDim2.new(0, finalContentStartXOffset, 0.05, 0), -- 초상화 오른쪽에 배치
		UDim2.new(0.4, 0, 0.1, 0),
		"NPC 이름", Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center,
		20, Color3.new(1,1,1), Enum.Font.SourceSansBold)
	npcNameLabel.BackgroundColor3 = Color3.fromRGB(60, 60, 80)
	npcNameLabel.BackgroundTransparency = 0.5
	Instance.new("UICorner", npcNameLabel).CornerRadius = smallCornerRadius
	print("DialogueUIBuilder: NpcNameLabel 생성됨 (콘텐츠 시작 위치 조정됨)")

	-- 대화 텍스트 레이블
	local dialogueTextLabel = GuiUtils.CreateTextLabel(dialogueFrame, "DialogueTextLabel",
		UDim2.new(0, finalContentStartXOffset, 0.18, 0),
		UDim2.new(1, -(finalContentStartXOffset + 20), 0.45, 0), -- 너비는 프레임 끝까지 (오른쪽 여백 20px)
		"대화 내용...", Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Top,
		18, Color3.new(1,1,1), Enum.Font.SourceSans)
	dialogueTextLabel.TextWrapped = true
	dialogueTextLabel.RichText = true
	print("DialogueUIBuilder: DialogueTextLabel 생성됨 (콘텐츠 시작 위치 조정됨)")

	-- 응답 버튼 스크롤링 프레임
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
	print("DialogueUIBuilder: ResponseButtonsFrame 생성됨 (콘텐츠 시작 위치 조정됨)")

	local responseLayout = Instance.new("UIGridLayout")
	responseLayout.Name = "ResponseGridLayout"
	responseLayout.FillDirection = Enum.FillDirection.Horizontal
	responseLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
	responseLayout.VerticalAlignment = Enum.VerticalAlignment.Top
	responseLayout.SortOrder = Enum.SortOrder.LayoutOrder
	responseLayout.CellPadding = UDim2.new(0, 8, 0, 8)
	responseLayout.CellSize = UDim2.new(0.32, 0, 0, 40)
	responseLayout.Parent = responseButtonsFrame
	print("DialogueUIBuilder: ResponseGridLayout 생성됨")

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
	print("DialogueUIBuilder: ResponseButtonTemplate 생성됨")

	print("DialogueUIBuilder: 대화 창 UI 생성 완료.")
end

return DialogueUIBuilder