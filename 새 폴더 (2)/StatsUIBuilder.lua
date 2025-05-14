--[[
  StatsUIBuilder (ModuleScript)
  스탯 창 UI를 생성합니다. (신규 스탯 시스템 반영)
  - 기본 스탯 (STR, AGI, INT, LUK) 투자 UI 생성
  - 요구 스탯 (DF, Sword, Gun) 표시 레이블 추가
  - 세부 능력치 표시 영역 (기본 틀) 추가
]]
local StatsUIBuilder = {}

function StatsUIBuilder.Build(mainGui, backgroundFrame, framesFolder, GuiUtils)
	print("StatsUIBuilder: 스탯 창 UI 생성 시작 (신규 시스템)...")

	local cornerRadius = UDim.new(0, 8)

	-- 스탯 창 기본 프레임
	local statsFrame = Instance.new("Frame")
	statsFrame.Name = "StatsFrame"
	statsFrame.Parent = backgroundFrame
	statsFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	statsFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	statsFrame.Size = UDim2.new(0.5, 0, 0.7, 0) -- 크기 조정 (세부 정보 공간 확보)
	statsFrame.BackgroundColor3 = Color3.fromRGB(50, 70, 70)
	statsFrame.BorderColor3 = Color3.fromRGB(180, 200, 200)
	statsFrame.BorderSizePixel = 2
	statsFrame.Visible = false
	statsFrame.ZIndex = 5
	Instance.new("UICorner", statsFrame).CornerRadius = cornerRadius
	print("StatsUIBuilder: StatsFrame 생성됨")

	-- 제목 및 기본 정보 레이블
	GuiUtils.CreateTextLabel(statsFrame, "TitleLabel", UDim2.new(0.5, 0, 0.03, 0), UDim2.new(0.9, 0, 0.07, 0), "능력치", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 20)
	local statPointsLabel = GuiUtils.CreateTextLabel(statsFrame, "StatPointsLabel", UDim2.new(0.5, 0, 0.1, 0), UDim2.new(0.9, 0, 0.05, 0), "남은 포인트: 0", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 16)

	-- 요구 스탯 표시 레이블 (StatPointsLabel 아래)
	local requirementStatsFrame = Instance.new("Frame")
	requirementStatsFrame.Name = "RequirementStatsFrame"
	requirementStatsFrame.Parent = statsFrame
	requirementStatsFrame.BackgroundTransparency = 1
	requirementStatsFrame.Size = UDim2.new(0.9, 0, 0.08, 0)
	requirementStatsFrame.Position = UDim2.new(0.5, 0, 0.16, 0) -- 위치 조정
	requirementStatsFrame.AnchorPoint = Vector2.new(0.5, 0)
	local reqLayout = Instance.new("UIListLayout")
	reqLayout.FillDirection = Enum.FillDirection.Horizontal
	reqLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	reqLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	reqLayout.Padding = UDim.new(0, 10)
	reqLayout.Parent = requirementStatsFrame

	GuiUtils.CreateTextLabel(requirementStatsFrame, "DFLabel", UDim2.new(0.3, 0, 1, 0), UDim2.new(0.3, -5, 0.9, 0), "악마열매: 0", Vector2.new(0, 0.5), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 12, Color3.fromRGB(220, 200, 255))
	GuiUtils.CreateTextLabel(requirementStatsFrame, "SwordLabel", UDim2.new(0.3, 0, 1, 0), UDim2.new(0.3, -5, 0.9, 0), "검술: 0", Vector2.new(0, 0.5), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 12, Color3.fromRGB(200, 200, 200))
	GuiUtils.CreateTextLabel(requirementStatsFrame, "GunLabel", UDim2.new(0.3, 0, 1, 0), UDim2.new(0.3, -5, 0.9, 0), "총술: 0", Vector2.new(0, 0.5), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 12, Color3.fromRGB(200, 200, 200))
	print("StatsUIBuilder: 요구 스탯 레이블 추가됨")

	-- 기본 스탯 투자 영역 (왼쪽 절반)
	local baseStatsFrame = Instance.new("Frame")
	baseStatsFrame.Name = "BaseStatsFrame"
	baseStatsFrame.Parent = statsFrame
	baseStatsFrame.Size = UDim2.new(0.45, 0, 0.6, 0) -- 너비 조정
	baseStatsFrame.Position = UDim2.new(0.05, 0, 0.25, 0) -- 왼쪽 배치
	baseStatsFrame.AnchorPoint = Vector2.new(0, 0)
	baseStatsFrame.BackgroundTransparency = 1
	local baseStatsLayout = Instance.new("UIListLayout")
	baseStatsLayout.Padding = UDim.new(0, 8)
	baseStatsLayout.FillDirection = Enum.FillDirection.Vertical
	baseStatsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	baseStatsLayout.SortOrder = Enum.SortOrder.LayoutOrder
	baseStatsLayout.Parent = baseStatsFrame
	print("StatsUIBuilder: BaseStatsFrame 생성됨")

	-- 기본 스탯 라인 생성 함수 (내부용)
	local function createBaseStatLine(parent, statId, statDisplayName)
		local lineFrame = Instance.new("Frame")
		lineFrame.Name = statId .. "Line"
		lineFrame.Size = UDim2.new(1, 0, 0, 40) -- 높이 고정
		lineFrame.BackgroundTransparency = 1
		lineFrame.Parent = parent

		GuiUtils.CreateTextLabel(lineFrame, statId .. "Label", UDim2.new(0.05, 0, 0.5, 0), UDim2.new(0.4, 0, 0.8, 0), statDisplayName .. ":", Vector2.new(0, 0.5), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 14)
		local valueLabel = GuiUtils.CreateTextLabel(lineFrame, statId .. "ValueLabel", UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.2, 0, 0.8, 0), "1", Vector2.new(0, 0.5), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 14)
		valueLabel.Name = statId .. "ValueLabel" -- 이름 명확히 설정

		local increaseButton = Instance.new("TextButton")
		increaseButton.Name = "Increase" .. statId .. "Button"
		increaseButton.Size = UDim2.new(0, 30, 0, 30) -- 정사각형 버튼
		increaseButton.AnchorPoint = Vector2.new(1, 0.5)
		increaseButton.Position = UDim2.new(0.95, 0, 0.5, 0)
		increaseButton.BackgroundColor3 = Color3.fromRGB(80, 150, 80)
		increaseButton.TextColor3 = Color3.fromRGB(255, 255, 255)
		increaseButton.Text = "+"
		increaseButton.Font = Enum.Font.SourceSansBold
		increaseButton.TextSize = 18
		increaseButton.Visible = true -- 기본 표시 (StatsUIManager에서 관리)
		increaseButton.Parent = lineFrame
		Instance.new("UICorner", increaseButton).CornerRadius = UDim.new(1, 0) -- 원형 버튼

		return lineFrame
	end

	-- 새로운 기본 스탯 라인 추가
	createBaseStatLine(baseStatsFrame, "STR", "힘").LayoutOrder = 1
	createBaseStatLine(baseStatsFrame, "AGI", "민첩").LayoutOrder = 2
	createBaseStatLine(baseStatsFrame, "INT", "지능").LayoutOrder = 3
	createBaseStatLine(baseStatsFrame, "LUK", "운").LayoutOrder = 4
	print("StatsUIBuilder: 기본 스탯 라인 추가됨")

	-- 세부 능력치 표시 영역 (오른쪽 절반)
	local detailedStatsFrame = Instance.new("ScrollingFrame")
	detailedStatsFrame.Name = "DetailedStatsFrame"
	detailedStatsFrame.Parent = statsFrame
	detailedStatsFrame.Size = UDim2.new(0.45, 0, 0.6, 0) -- 너비 조정
	detailedStatsFrame.Position = UDim2.new(0.95, 0, 0.25, 0) -- 오른쪽 배치
	detailedStatsFrame.AnchorPoint = Vector2.new(1, 0)
	detailedStatsFrame.BackgroundColor3 = Color3.fromRGB(40, 60, 60)
	detailedStatsFrame.BorderSizePixel = 1
	detailedStatsFrame.BorderColor3 = Color3.fromRGB(150, 180, 180)
	detailedStatsFrame.CanvasSize = UDim2.new(0, 0, 0, 0) -- 내용은 UIManager에서 채움
	detailedStatsFrame.ScrollBarThickness = 6
	Instance.new("UICorner", detailedStatsFrame).CornerRadius = cornerRadius
	print("StatsUIBuilder: DetailedStatsFrame 생성됨")

	GuiUtils.CreateTextLabel(detailedStatsFrame, "DetailedTitle", UDim2.new(0.5, 0, 0.03, 0), UDim2.new(0.9, 0, 0.07, 0), "세부 능력치", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 16, Color3.fromRGB(200, 220, 220))
	-- 세부 능력치 내용은 StatsUIManager에서 동적으로 생성

	-- 닫기 버튼
	local closeStatsButton = Instance.new("TextButton")
	closeStatsButton.Name = "CloseButton" -- 이름 유지 (ButtonHandler 호환)
	closeStatsButton.Parent = statsFrame
	closeStatsButton.AnchorPoint = Vector2.new(0.5, 1) -- 중앙 하단으로 변경
	closeStatsButton.Position = UDim2.new(0.5, 0, 0.95, 0) -- 위치 조정
	closeStatsButton.Size = UDim2.new(0.3, 0, 0.08, 0) -- 크기 조정
	closeStatsButton.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	closeStatsButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeStatsButton.Font = Enum.Font.SourceSansBold
	closeStatsButton.Text = "닫기"
	closeStatsButton.TextScaled = true
	closeStatsButton.BorderSizePixel = 0
	closeStatsButton.ZIndex = 6
	Instance.new("UICorner", closeStatsButton).CornerRadius = cornerRadius
	print("StatsUIBuilder: StatsFrame CloseButton 생성됨")

	print("StatsUIBuilder: 스탯 창 UI 생성 완료 (신규 시스템).")
end

return StatsUIBuilder