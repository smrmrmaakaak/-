-- GuiBuilder.lua

local GuiBuilder = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local GuiUtils -- Init 함수에서 로드

-- 모듈 초기화 함수
function GuiBuilder.Init()
	local success, utils = pcall(require, modulesFolder:WaitForChild("GuiUtils", 5))
	if success then
		GuiUtils = utils
		print("GuiBuilder: Initialized and GuiUtils loaded.")
	else
		warn("GuiBuilder: Failed to load GuiUtils!", utils)
	end
end

-- 기본 UI 요소들을 생성하고 mainGui 아래에 배치하는 함수
function GuiBuilder.BuildBaseUI(mainGui)
	if not GuiUtils then GuiBuilder.Init() end -- GuiUtils 로드 재시도 또는 확인
	if not GuiUtils then warn("GuiBuilder.BuildBaseUI: Cannot proceed without GuiUtils!"); return end

	print("GuiBuilder: 기본 UI 생성 시작...")

	-- 배경 프레임과 Frames 폴더 생성
	local backgroundFrame = mainGui:FindFirstChild("BackgroundFrame")
	if not backgroundFrame then
		backgroundFrame = Instance.new("Frame")
		backgroundFrame.Name = "BackgroundFrame"
		backgroundFrame.Parent = mainGui
		backgroundFrame.BackgroundColor3 = Color3.fromRGB(20, 20, 30)
		backgroundFrame.BorderSizePixel = 0
		backgroundFrame.Size = UDim2.new(1, 0, 1, 0)
		backgroundFrame.ZIndex = 1
		print("GuiBuilder: BackgroundFrame 생성됨")
	end

	local framesFolder = backgroundFrame:FindFirstChild("Frames")
	if not framesFolder then
		framesFolder = Instance.new("Folder")
		framesFolder.Name = "Frames"
		framesFolder.Parent = backgroundFrame
		print("GuiBuilder: Frames 폴더 생성됨")
	end

	-- 각 UI 빌더 모듈 이름 목록
	local builders = {
		"IntroBuilder",         -- 인트로
		"LoadingScreenBuilder", -- 로딩 화면
		"MainMenuBuilder",      -- 메인 메뉴
		"PlayerHUDBuilder",     -- 플레이어 HUD
		"CombatUIBuilder",      -- 전투 화면
		"ShopUIBuilder",        -- 상점
		"InventoryUIBuilder",   -- 인벤토리
		"EquipmentUIBuilder",   -- 장비
		"CraftingUIBuilder",    -- 제작
		"GachaUIBuilder",       -- 뽑기
		"StatsUIBuilder",       -- 스탯
		"DialogueUIBuilder",    -- 대화
		"SkillShopUIBuilder",   -- 스킬 상점
		"MiscUIBuilder",        -- 기타 UI (결과창 등)
		"EnhancementUIBuilder",
		"SettingsUIBuilder",
		"CompanionUIBuilder",
		"LeaderboardUIBuilder", -- <<< 리더보드 빌더 추가
	}

	local successCount = 0
	local buildResults = {} -- 빌더가 반환하는 프레임 저장용

	-- 각 UI 빌더 실행
	for _, builderName in ipairs(builders) do
		local success, builderModule = pcall(require, modulesFolder:WaitForChild(builderName, 10))
		if success and builderModule then
			if builderModule.Build and typeof(builderModule.Build) == "function" then -- Build 함수 존재 및 타입 확인
				local buildSuccess, resultFrameOrError = pcall(builderModule.Build, mainGui, backgroundFrame, framesFolder, GuiUtils)
				if buildSuccess then
					print("GuiBuilder: '" .. builderName .. "' UI 빌드 완료.")
					buildResults[builderName] = resultFrameOrError
					successCount = successCount + 1
				else
					warn("GuiBuilder: '" .. builderName .. "' 빌드 중 오류 발생!", resultFrameOrError)
				end
			else
				warn("GuiBuilder: '" .. builderName .. "' 모듈에 유효한 Build 함수가 없습니다!")
			end
		elseif not success then
			warn("GuiBuilder: '" .. builderName .. "' 모듈 로드 실패!", builderModule)
		else
			warn("GuiBuilder: '" .. builderName .. "' 모듈 로드 성공했으나 유효하지 않음?")
		end
	end

	print("GuiBuilder: 기본 UI 생성 완료. (" .. successCount .. "/" .. #builders .. " 빌더 성공)")
	-- return buildResults
end

return GuiBuilder