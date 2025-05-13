--[[
  HUDManager (ModuleScript)
  플레이어 HUD UI 요소 업데이트를 담당하는 모듈 (클라이언트 측).
  *** [수정] 초기 10초간 주기적 HUD 업데이트 추가 ***
  *** [버그 수정] SetupHUDListenersAndRefresh에서 각 ValueObject에 WaitForChild 적용하여 복제 지연 문제 해결 시도 ***
]]
local HUDManager = {}

-- 필요한 서비스 및 모듈 로드
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local ModuleManager
local CoreUIManager -- HUD UI 요소 업데이트 함수 호출용
local PlayerData -- 클라이언트 측 GetStats 호출용

local playerHUD = nil -- PlayerHUD Frame 참조

-- 모듈 초기화
function HUDManager.Init()
	ModuleManager = require(ReplicatedStorage.Modules:WaitForChild("ModuleManager"))
	CoreUIManager = ModuleManager:GetModule("CoreUIManager")
	PlayerData = ModuleManager:GetModule("PlayerData")
	print("HUDManager: Initialized.")

	-- 초기 HUD 업데이트 시도 (비동기적으로 PlayerStats 폴더 기다림)
	HUDManager.SetupHUDListenersAndRefresh()
end

-- HUD 업데이트 함수 (수정 없음)
function HUDManager.RefreshHUD()
	if not CoreUIManager or not PlayerData then warn("HUDManager: RefreshHUD - CoreUIManager 또는 PlayerData 모듈 사용 불가"); return end
	if not playerHUD then local mainGui = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("MainGui"); local backgroundFrame = mainGui and mainGui:FindFirstChild("BackgroundFrame"); playerHUD = backgroundFrame and backgroundFrame:FindFirstChild("PlayerHUD"); if not playerHUD then return end end
	local statsFolder = player:FindFirstChild(PlayerData.STATS_FOLDER_NAME); if not statsFolder then return end
	local currentStats = PlayerData.GetStats(player); if currentStats then CoreUIManager.UpdatePlayerHUD(currentStats) else warn("HUDManager: refreshHUD - GetStats 호출 실패") end
end

-- PlayerStats 폴더 및 Value 객체 리스너 설정, 초기 HUD 갱신 (수정됨: WaitForChild 사용)
function HUDManager.SetupHUDListenersAndRefresh()
	task.spawn(function()
		print("HUDManager: SetupHUDListenersAndRefresh 스레드 시작")
		while not PlayerData do print("HUDManager: Waiting for PlayerData module..."); task.wait(0.5) end
		local statsFolderName = PlayerData.STATS_FOLDER_NAME
		if not statsFolderName then warn("HUDManager: PlayerData 모듈에서 STATS_FOLDER_NAME 을 찾을 수 없습니다."); return end

		-- PlayerHUD Frame 참조 설정
		local mainGui = player:WaitForChild("PlayerGui"):WaitForChild("MainGui")
		local backgroundFrame = mainGui:WaitForChild("BackgroundFrame")
		playerHUD = backgroundFrame:WaitForChild("PlayerHUD")
		if not playerHUD then warn("HUDManager: SetupHUDListenersAndRefresh - PlayerHUD 프레임을 찾을 수 없습니다!"); return end
		print("HUDManager: PlayerHUD 프레임 참조 설정 완료.")

		-- PlayerStats 폴더 확인 (기존과 동일)
		local statsFolder = player:WaitForChild(statsFolderName, 30)
		if not statsFolder then warn("HUDManager: PlayerStats 폴더를 찾을 수 없어 HUD 리스너를 설정할 수 없습니다."); return end
		print("HUDManager: PlayerStats 폴더 찾음! HUD 업데이트 리스너 설정 시도.")

		-- *** 수정: Value 객체 변경 리스너 연결 시 WaitForChild 사용 ***
		local statsToWatch = {
			"Level", "Exp", "MaxExp", "CurrentHP", "MaxHP", "CurrentMP", "MaxMP", "Gold", -- CurrentHP/MP 추가
			"STR", "AGI", "INT", "LUK", "StatPoints" -- 기본 스탯 및 포인트
			-- 파생 스탯 중 HUD에 직접 표시되지 않는 것은 제외해도 됨 (필요시 추가)
		}
		local allListenersConnected = true -- 모든 리스너 연결 성공 플래그

		for _, statName in ipairs(statsToWatch) do
			-- 각 ValueObject가 생성될 때까지 최대 10초 대기
			local valueObject = statsFolder:WaitForChild(statName, 10)

			if valueObject and valueObject:IsA("ValueBase") then
				-- ValueObject를 찾으면 Changed 이벤트 연결
				valueObject.Changed:Connect(HUDManager.RefreshHUD)
				print("HUDManager: Listener connected for " .. statName)
			else
				-- 지정된 시간 안에 찾지 못하면 경고 출력
				warn("HUDManager: Timed out waiting for ValueObject '" .. statName .. "' in PlayerStats folder.")
				allListenersConnected = false -- 하나라도 실패하면 플래그 false
			end
		end

		if allListenersConnected then
			print("HUDManager: 모든 필수 HUD 리스너 설정 완료.")
		else
			warn("HUDManager: 일부 HUD 리스너 설정 실패.")
		end
		-- *** 수정 끝 ***

		-- 초기 HUD 업데이트 시도 (리스너 설정 직후)
		HUDManager.RefreshHUD()
		print("HUDManager: 리스너 설정 후 초기 HUD 업데이트 시도 완료.")

		-- 초기 10초간 주기적 업데이트 (기존 유지)
		print("HUDManager: 초기 10초간 주기적 HUD 업데이트 시작...")
		for i = 1, 10 do
			task.wait(1)
			if not player or not player.Parent or not statsFolder or not statsFolder.Parent then print("HUDManager: 주기적 업데이트 중단 (플레이어/폴더 유효하지 않음)"); break end
			HUDManager.RefreshHUD()
		end
		print("HUDManager: 초기 10초간 주기적 HUD 업데이트 종료.")

	end)
end

return HUDManager