-- ReplicatedStorage > Modules > LoadingScreenBuilder.lua

local LoadingScreenBuilder = {}

-- 필요한 서비스 가져오기
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- 모듈 참조 변수
local GuiUtils

-- 모듈 초기화 함수
function LoadingScreenBuilder.Init()
	local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
	GuiUtils = require(modulesFolder:WaitForChild("GuiUtils"))
	print("LoadingScreenBuilder: Initialized.")
end

-- 로딩 화면 UI 생성 함수
function LoadingScreenBuilder.Build(mainGui, backgroundFrame, framesFolder)
	if not GuiUtils then LoadingScreenBuilder.Init() end
	if not GuiUtils then warn("LoadingScreenBuilder.Build: GuiUtils not loaded!"); return end

	print("LoadingScreenBuilder: 로딩 화면 UI 생성 시작...")

	-- 로딩 화면 전체를 덮는 프레임
	local loadingFrame = Instance.new("Frame")
	loadingFrame.Name = "LoadingFrame"
	loadingFrame.Parent = framesFolder -- Frames 폴더 아래에 배치
	loadingFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	loadingFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	loadingFrame.Size = UDim2.new(1, 0, 1, 0) -- 화면 전체 크기
	loadingFrame.BackgroundColor3 = Color3.fromRGB(10, 10, 20) -- 약간 어두운 파란색 배경
	loadingFrame.BorderSizePixel = 0
	loadingFrame.Visible = false -- 처음에는 숨겨둠
	loadingFrame.ZIndex = 190 -- 인트로보다는 아래, 다른 UI보다는 위에

	-- 로딩 텍스트 레이블
	local loadingText = GuiUtils.CreateTextLabel(loadingFrame, "LoadingText",
		UDim2.new(0.5, 0, 0.8, 0), -- 화면 하단 중앙 근처
		UDim2.new(0.5, 0, 0.1, 0), -- 텍스트 크기
		"로딩 중...",
		Vector2.new(0.5, 0.5), -- 중앙 정렬
		Enum.TextXAlignment.Center,
		Enum.TextYAlignment.Center,
		24, -- 텍스트 크기
		Color3.fromRGB(220, 220, 220) -- 밝은 회색 텍스트
	)
	loadingText.Font = Enum.Font.SourceSansBold

	-- (선택 사항) 여기에 로딩 바 또는 스피너 이미지 등을 추가할 수 있습니다.
	-- 예시: 로딩 스피너 이미지
	-- local spinnerImage = Instance.new("ImageLabel")
	-- spinnerImage.Name = "SpinnerImage"
	-- spinnerImage.Parent = loadingFrame
	-- spinnerImage.AnchorPoint = Vector2.new(0.5, 0.5)
	-- spinnerImage.Position = UDim2.new(0.5, 0, 0.5, 0) -- 중앙에 배치
	-- spinnerImage.Size = UDim2.new(0, 100, 0, 100)
	-- spinnerImage.Image = "rbxassetid://YOUR_SPINNER_IMAGE_ID" -- <<< 스피너 이미지 ID 입력
	-- spinnerImage.BackgroundTransparency = 1
	-- -- 스피너 회전 애니메이션은 LoadingManager 에서 처리할 수 있습니다.

	print("LoadingScreenBuilder: 로딩 화면 UI 생성 완료.")
	return loadingFrame
end

return LoadingScreenBuilder