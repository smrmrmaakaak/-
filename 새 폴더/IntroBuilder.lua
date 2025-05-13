-- ReplicatedStorage > Modules > IntroBuilder.lua

local IntroBuilder = {}

-- 필요한 서비스 가져오기
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService") -- 애니메이션에 필요

-- 모듈 참조 변수
local GuiUtils

-- 모듈 초기화 함수
function IntroBuilder.Init()
	local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
	GuiUtils = require(modulesFolder:WaitForChild("GuiUtils"))
	print("IntroBuilder: Initialized.")
end

-- 인트로 UI 생성 함수
-- mainGui: 대상 ScreenGui
-- backgroundFrame: 모든 UI의 부모가 될 배경 프레임
-- framesFolder: 특정 팝업/화면 프레임들을 담을 폴더
function IntroBuilder.Build(mainGui, backgroundFrame, framesFolder)
	if not GuiUtils then IntroBuilder.Init() end -- GuiUtils 로드 보장
	if not GuiUtils then warn("IntroBuilder.Build: GuiUtils not loaded!"); return end

	print("IntroBuilder: 인트로 UI 생성 시작...")

	-- 인트로 화면 전체를 덮는 프레임
	local introFrame = Instance.new("Frame")
	introFrame.Name = "IntroFrame"
	introFrame.Parent = framesFolder -- 생성될 프레임들을 모아두는 Frames 폴더 아래에 배치
	introFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	introFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	introFrame.Size = UDim2.new(1, 0, 1, 0) -- 화면 전체 크기
	introFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0) -- 기본 검은색 배경
	introFrame.BorderSizePixel = 0
	introFrame.Visible = false -- 처음에는 숨겨둠
	introFrame.ZIndex = 200 -- 다른 모든 UI 요소들보다 위에 보이도록 설정

	-- 인트로 이미지 (커졌다 작아지는 효과를 줄 대상)
	local introImage = Instance.new("ImageLabel")
	introImage.Name = "IntroImage"
	introImage.Parent = introFrame
	introImage.AnchorPoint = Vector2.new(0.5, 0.5)
	introImage.Position = UDim2.new(0.5, 0, 0.5, 0) -- 프레임 중앙에 위치
	introImage.Size = UDim2.new(0.8, 0, 0.8, 0) -- 화면의 80% 크기로 시작 (애니메이션 시작 크기는 다를 수 있음)
	-- <<< 중요: 아래 'YOUR_INTRO_IMAGE_ID' 부분에 실제 사용할 인트로 이미지의 Asset ID를 꼭 넣어주세요! (예: "rbxassetid://123456789") >>>
	introImage.Image = "rbxassetid://108021409421865"
	introImage.ScaleType = Enum.ScaleType.Fit -- 이미지 비율 유지
	introImage.BackgroundTransparency = 1 -- 이미지 배경은 투명하게
	introImage.ImageTransparency = 1 -- 이미지는 처음에 완전히 투명하게 시작

	print("IntroBuilder: 인트로 UI 생성 완료.")
	return introFrame -- 생성된 프레임 반환 (GuiManager 등에서 참조하기 위함)
end

-- 참고: 인트로 애니메이션 재생 로직은 IntroManager 모듈에서 처리합니다.

return IntroBuilder