-- GuiBuilder.lua (수정: FullScreenEffectBuilder 추가)

local GuiBuilder = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local GuiUtils -- Init 함수에서 로드

function GuiBuilder.Init()
	local success, utils = pcall(require, modulesFolder:WaitForChild("GuiUtils", 5))
	if success then
		GuiUtils = utils
		print("GuiBuilder: Initialized and GuiUtils loaded.")
	else
		warn("GuiBuilder: Failed to load GuiUtils!", utils)
	end
end

function GuiBuilder.BuildBaseUI(mainGui)
	if not GuiUtils then GuiBuilder.Init() end
	if not GuiUtils then warn("GuiBuilder.BuildBaseUI: Cannot proceed without GuiUtils!"); return end

	print("GuiBuilder: 기본 UI 생성 시작...")

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

	local builders = {
		"IntroBuilder",
		"LoadingScreenBuilder",
		"MainMenuBuilder",
		"PlayerHUDBuilder",
		"CombatUIBuilder",
		"ShopUIBuilder",
		"InventoryUIBuilder",
		"EquipmentUIBuilder",
		"CraftingUIBuilder",
		"GachaUIBuilder",
		"StatsUIBuilder",
		"DialogueUIBuilder",
		"SkillShopUIBuilder",
		"EnhancementUIBuilder",
		"SettingsUIBuilder",
		"CompanionUIBuilder",
		"LeaderboardUIBuilder",
		"MiscUIBuilder",
		"FullScreenEffectBuilder" -- <<< 여기 추가됨
	}

	local successCount = 0
	local buildResults = {}

	for _, builderName in ipairs(builders) do
		local success, builderModule = pcall(require, modulesFolder:WaitForChild(builderName, 10))
		if success and builderModule then
			if builderModule.Build and typeof(builderModule.Build) == "function" then
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
end

return GuiBuilder