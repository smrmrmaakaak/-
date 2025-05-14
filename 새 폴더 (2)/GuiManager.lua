-- GuiManager.lua

-- StarterGui > MainGui > GuiManager (LocalScript)

-- 필요한 서비스 가져오기
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

-- 플레이어 및 GUI 객체 참조
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainGui = script.Parent

-- 모듈 폴더 참조
local modulesFolder = ReplicatedStorage:WaitForChild("Modules", 20)
if not modulesFolder then warn("GuiManager: CRITICAL - Modules 폴더를 찾을 수 없습니다! UI 초기화 불가."); return end

-- *** 1단계: 핵심 모듈 로드 ***
print("GuiManager: 1단계 - 핵심 모듈 로드 시작")
local ModuleManager = require(modulesFolder:WaitForChild("ModuleManager", 15)); if not ModuleManager then warn("GuiManager: CRITICAL - ModuleManager 로드 실패!"); return end
local GuiUtils = ModuleManager:GetModule("GuiUtils"); if not GuiUtils then warn("GuiManager: CRITICAL - GuiUtils 로드 실패!"); return end
local GuiBuilder = ModuleManager:GetModule("GuiBuilder"); if not GuiBuilder then warn("GuiManager: CRITICAL - GuiBuilder 로드 실패!"); return end
local CoreUIManager = ModuleManager:GetModule("CoreUIManager"); if not CoreUIManager then warn("GuiManager: CRITICAL - CoreUIManager 로드 실패!"); return end
print("GuiManager: 1단계 - 핵심 모듈 로드 완료")

-- *** 2단계: 기본 UI 생성 ***
print("GuiManager: 2단계 - 기본 UI 생성 시작")
mainGui.IgnoreGuiInset = true
local backgroundFrame
if GuiBuilder and GuiBuilder.BuildBaseUI then
	if GuiBuilder.Init then GuiBuilder.Init() end
	local success, err = pcall(GuiBuilder.BuildBaseUI, mainGui)
	if not success then warn("GuiManager: CRITICAL - GuiBuilder.BuildBaseUI 실행 중 오류 발생!", err); return end
	backgroundFrame = mainGui:FindFirstChild("BackgroundFrame")

	if backgroundFrame then
		local mainBackgroundImage = backgroundFrame:FindFirstChild("MainBackgroundImage")
		if not mainBackgroundImage then
			mainBackgroundImage = Instance.new("ImageLabel")
			mainBackgroundImage.Name = "MainBackgroundImage"
			mainBackgroundImage.Parent = backgroundFrame
			mainBackgroundImage.Size = UDim2.new(1, 0, 1, 0)
			mainBackgroundImage.Position = UDim2.new(0, 0, 0, 0)
			mainBackgroundImage.AnchorPoint = Vector2.new(0, 0)
			mainBackgroundImage.ScaleType = Enum.ScaleType.Stretch
			mainBackgroundImage.ZIndex = 0
			mainBackgroundImage.BackgroundTransparency = 1
			mainBackgroundImage.Image = ""
			mainBackgroundImage.Visible = true
			print("GuiManager: MainBackgroundImage 생성됨")
		end
	else
		warn("GuiManager: backgroundFrame을 찾을 수 없어 MainBackgroundImage를 생성/설정할 수 없습니다.")
	end
	print("GuiManager: 2단계 - 기본 UI 생성 완료")
else warn("GuiManager: CRITICAL - GuiBuilder 또는 BuildBaseUI 함수를 찾을 수 없어 UI를 생성할 수 없습니다."); return end

-- *** 3단계: 나머지 모든 모듈 로드 ***
print("GuiManager: 3단계 - 나머지 모듈 로드 시작")
local ButtonHandler = ModuleManager:GetModule("ButtonHandler")
local TooltipManager = ModuleManager:GetModule("TooltipManager")
local IntroManager = ModuleManager:GetModule("IntroManager")
local LoadingManager = ModuleManager:GetModule("LoadingManager")
local PlayerData = ModuleManager:GetModule("PlayerData")
local SoundManager = ModuleManager:GetModule("SoundManager")
local ShopUIManager = ModuleManager:GetModule("ShopUIManager")
local InventoryUIManager = ModuleManager:GetModule("InventoryUIManager")
local CraftingUIManager = ModuleManager:GetModule("CraftingUIManager")
local CombatUIManager = ModuleManager:GetModule("CombatUIManager")
local GachaUIManager = ModuleManager:GetModule("GachaUIManager")
local StatsUIManager = ModuleManager:GetModule("StatsUIManager")
local DialogueManager = ModuleManager:GetModule("DialogueManager")
local SkillShopUIManager = ModuleManager:GetModule("SkillShopUIManager")
local HUDManager = ModuleManager:GetModule("HUDManager")
local MapManager = ModuleManager:GetModule("MapManager")
local MapRenderer = ModuleManager:GetModule("MapRenderer")
local MapInputHandler = ModuleManager:GetModule("MapInputHandler")
local MapInteractor = ModuleManager:GetModule("MapInteractor")
local MobileControlsManager = ModuleManager:GetModule("MobileControlsManager")
local EnhancementUIManager = ModuleManager:GetModule("EnhancementUIManager") -- EnhancementUIManager 로드
local SettingsUIManager = ModuleManager:GetModule("SettingsUIManager")
local PurchaseNotifications = ModuleManager:GetModule("PurchaseNotifications")
local EnhancementNotifications = ModuleManager:GetModule("EnhancementNotifications") -- EnhancementNotifications 로드
local CompanionUIManager = ModuleManager:GetModule("CompanionUIManager")
local LeaderboardUIManager = ModuleManager:GetModule("LeaderboardUIManager")
print("GuiManager: 3단계 - 나머지 모듈 로드 완료 시도")

-- 서버 이벤트 참조
print("GuiManager: 서버 이벤트 참조 시작 (WaitForChild)")
local eventWaitTimeout = 15
local inventoryUpdatedEvent = ReplicatedStorage:WaitForChild("InventoryUpdatedEvent", eventWaitTimeout)
local playerStatsUpdatedEvent = ReplicatedStorage:WaitForChild("PlayerStatsUpdatedEvent", eventWaitTimeout)
print("GuiManager: Debug - playerStatsUpdatedEvent type:", typeof(playerStatsUpdatedEvent), "IsA RemoteEvent:", playerStatsUpdatedEvent and playerStatsUpdatedEvent:IsA("RemoteEvent") or "N/A")
local combatEndedClientEvent = ReplicatedStorage:WaitForChild("CombatEndedClientEvent", eventWaitTimeout)
local SkillLearnedEvent = ReplicatedStorage:WaitForChild("SkillLearnedEvent", eventWaitTimeout)
local NotifyPlayerEvent = ReplicatedStorage:WaitForChild("NotifyPlayerEvent", eventWaitTimeout)
local RequestStartCombatEvent = ReplicatedStorage:WaitForChild("RequestStartCombatEvent", eventWaitTimeout)
local companionUpdatedEvent = ReplicatedStorage:WaitForChild("CompanionUpdatedEvent", eventWaitTimeout)
print("GuiManager: 서버 이벤트 참조 완료")

-- *** 4단계: 모듈 초기화 ***
print("GuiManager: 4단계 - 모듈 초기화 시작")
local function tryInit(module, moduleName, ...)
	if module then
		if module.Init and typeof(module.Init) == "function" then
			local success, err = pcall(module.Init, ...)
			if not success then warn("GuiManager: " .. moduleName .. ".Init() 실행 중 오류!", err) end
		end
	else
		warn("GuiManager: " .. moduleName .. " 모듈이 nil이므로 Init() 호출 불가.")
	end
end
tryInit(CoreUIManager, "CoreUIManager");
tryInit(SettingsUIManager, "SettingsUIManager");
tryInit(IntroManager, "IntroManager");
tryInit(LoadingManager, "LoadingManager");
tryInit(PlayerData, "PlayerData");
tryInit(SoundManager, "SoundManager");
tryInit(ShopUIManager, "ShopUIManager");
tryInit(InventoryUIManager, "InventoryUIManager");
tryInit(CraftingUIManager, "CraftingUIManager");
tryInit(CombatUIManager, "CombatUIManager");
tryInit(GachaUIManager, "GachaUIManager");
tryInit(StatsUIManager, "StatsUIManager");
tryInit(DialogueManager, "DialogueManager");
tryInit(SkillShopUIManager, "SkillShopUIManager");
tryInit(HUDManager, "HUDManager");
tryInit(TooltipManager, "TooltipManager");
tryInit(EnhancementUIManager, "EnhancementUIManager"); -- EnhancementUIManager 초기화
tryInit(CompanionUIManager, "CompanionUIManager")
tryInit(LeaderboardUIManager, "LeaderboardUIManager")

local interactorDependencies = {
	DialogueManager = DialogueManager,
	CombatUIManager = CombatUIManager,
	ShopUIManager = ShopUIManager,
	CraftingUIManager = CraftingUIManager,
	GachaUIManager = GachaUIManager,
	SkillShopUIManager = SkillShopUIManager,
	CoreUIManager = CoreUIManager,
	RequestStartCombatEvent = RequestStartCombatEvent,
	EnhancementUIManager = EnhancementUIManager
}

print(string.format("[DEBUG] GuiManager: Checking dependencies before MapManager.Init. ShopUIManager type: %s", typeof(ShopUIManager)))
if interactorDependencies then
	print(string.format("[DEBUG] GuiManager: Dependencies table ShopUIManager type: %s", typeof(interactorDependencies.ShopUIManager)))
	print(string.format("[DEBUG] GuiManager: Dependencies table EnhancementUIManager type: %s", typeof(interactorDependencies.EnhancementUIManager)))
end

if MapManager and MapManager.Init then
	local s,e = pcall(MapManager.Init, interactorDependencies)
	if s then
		print("[DEBUG] GuiManager: MapManager.Init completed successfully.")
	else
		warn("MapManager.Init 오류!", e)
	end
elseif not MapManager then
	warn("MapManager 모듈 nil, Init 불가")
end

tryInit(MapRenderer, "MapRenderer");
if MapInputHandler and MapInputHandler.Init then local s,e = pcall(MapInputHandler.Init); if not s then warn("MapInputHandler.Init 오류!", e) end elseif not MapInputHandler then warn("MapInputHandler 모듈 nil, Init 불가") end
if MapInteractor and MapInteractor.Init then local s,e = pcall(MapInteractor.Init, MapManager, interactorDependencies); if not s then warn("MapInteractor.Init 오류!", e) end elseif not MapInteractor then warn("MapInteractor 모듈 nil, Init 불가") end
print("[DEBUG] GuiManager: Preparing to init MobileControlsManager. Type of MapManager:", typeof(MapManager))
tryInit(MobileControlsManager, "MobileControlsManager", MapManager, GuiUtils)
print("GuiManager: 4단계 - 모듈 초기화 완료")

-- *** 5단계: UI 생성 후 필요한 참조 설정 ***
print("GuiManager: 5단계 - UI 참조 설정 시작")
local function trySetupUI(module, moduleName)
	if module and module.SetupUIReferences then
		local success, err = pcall(module.SetupUIReferences)
		if not success then warn("GuiManager: " .. moduleName .. ".SetupUIReferences() 오류!", err) end
	end
end
trySetupUI(IntroManager, "IntroManager"); trySetupUI(LoadingManager, "LoadingManager"); trySetupUI(DialogueManager, "DialogueManager"); trySetupUI(SkillShopUIManager, "SkillShopUIManager"); trySetupUI(EnhancementUIManager, "EnhancementUIManager");
trySetupUI(CompanionUIManager, "CompanionUIManager")
trySetupUI(LeaderboardUIManager, "LeaderboardUIManager")

if TooltipManager and TooltipManager.CreateTooltipFrame then
	local s,e = pcall(TooltipManager.CreateTooltipFrame, mainGui)
	if not s then warn("TooltipManager.CreateTooltipFrame 오류!", e) end
end
if MobileControlsManager and MobileControlsManager.CreateControls then
	local success, err = pcall(MobileControlsManager.CreateControls, mainGui)
	if not success then warn("GuiManager: MobileControlsManager.CreateControls() 실행 중 오류!", err) end
else warn("GuiManager: MobileControlsManager 또는 CreateControls 함수를 찾을 수 없습니다.") end
print("GuiManager: 5단계 - UI 참조 설정 완료")

task.wait(0.2)

-- *** 6단계: 버튼 이벤트 연결 ***
print("GuiManager: 6단계 - 버튼 이벤트 연결 시작")
if ButtonHandler and ButtonHandler.SetupButtonEvents then
	print("GuiManager: ButtonHandler 와 SetupButtonEvents 함수를 찾았습니다. 연결 시도...")
	local success, err = pcall(ButtonHandler.SetupButtonEvents, mainGui)
	if success then print("GuiManager: 버튼 이벤트 연결 성공.") else warn("GuiManager: ButtonHandler.SetupButtonEvents 실행 중 오류 발생!", err) end
else
	warn("GuiManager: ButtonHandler 또는 SetupButtonEvents 함수를 찾을 수 없어 버튼 이벤트를 연결할 수 없습니다.")
	if not ButtonHandler then warn("GuiManager: ButtonHandler 모듈이 nil 입니다.") elseif not ButtonHandler.SetupButtonEvents then warn("GuiManager: ButtonHandler.SetupButtonEvents 함수가 없습니다.") end
end
task.spawn(function()
	task.wait(0.5)
	print("[DEBUG] GuiManager: Waiting for ToggleMobileControlsButton...")
	local toggleButton = backgroundFrame and backgroundFrame:WaitForChild("ToggleMobileControlsButton", 3)
	if toggleButton then
		print("[DEBUG] GuiManager: Found ToggleMobileControlsButton. Type:", typeof(toggleButton))
		if MobileControlsManager and MobileControlsManager.SetupToggleButton then
			print("[DEBUG] GuiManager: Calling MobileControlsManager.SetupToggleButton...")
			local success, err = pcall(MobileControlsManager.SetupToggleButton, toggleButton)
			if not success then warn("GuiManager: MobileControlsManager.SetupToggleButton() 실행 중 오류!", err) end
		else
			if not MobileControlsManager then warn("GuiManager: MobileControlsManager가 로드되지 않았습니다!") end
			if not MobileControlsManager.SetupToggleButton then warn("GuiManager: MobileControlsManager.SetupToggleButton 함수가 없습니다!") end
		end
	else
		warn("GuiManager: ToggleMobileControlsButton을 찾을 수 없습니다! (WaitForChild Timeout)")
	end
end)
print("GuiManager: 6단계 - 버튼 이벤트 연결 시도 완료")

-- *** 7단계: 게임 시작 흐름 ***
print("GuiManager: 7단계 - 게임 시작 흐름 시작")
if IntroManager and LoadingManager and CoreUIManager then
	IntroManager.ShowIntro()
	local success, err = pcall(IntroManager.PlayIntroAnimation, function()
		IntroManager.HideIntro()
		LoadingManager.ShowLoading("게임을 준비 중입니다...")
		task.wait(1)
		LoadingManager.HideLoading()
		if CoreUIManager and CoreUIManager.SwitchFrame then
			CoreUIManager.SwitchFrame("MainMenu")
			print("GuiManager: Game started, showing MainMenu.")
		else
			warn("GuiManager: CoreUIManager.SwitchFrame 없음, 메인 메뉴 표시 불가")
		end
	end)
	if not success then warn("GuiManager: IntroManager.PlayIntroAnimation 실행 중 오류!", err) end
else
	warn("GuiManager: IntroManager, LoadingManager, 또는 CoreUIManager 가 로드되지 않아 게임 시작 흐름을 진행할 수 없습니다.")
	if CoreUIManager and CoreUIManager.SwitchFrame then CoreUIManager.SwitchFrame("MainMenu") else warn("GuiManager: 메인 메뉴 표시 불가 (CoreUIManager 없음)") end
end
print("GuiManager: 7단계 - 게임 시작 흐름 시작됨")

-- *** 이벤트 리스너 연결 ***
print("GuiManager: 이벤트 리스너 연결 시작")
if inventoryUpdatedEvent then
	inventoryUpdatedEvent.OnClientEvent:Connect(function()
		print("GuiManager: InventoryUpdatedEvent received on client.")
		local enhFrame = EnhancementUIManager and EnhancementUIManager.enhancementFrame; local enhVisible = enhFrame and enhFrame.Visible
		local compFrame = CompanionUIManager and CompanionUIManager.companionFrame; local compVisible = compFrame and compFrame.Visible

		pcall(function() if InventoryUIManager and InventoryUIManager.RefreshInventoryDisplay then InventoryUIManager.RefreshInventoryDisplay() end end)
		pcall(function() if ShopUIManager and ShopUIManager.RefreshShopListIfVisible then ShopUIManager.RefreshShopListIfVisible() end end)
		pcall(function() if CraftingUIManager and CraftingUIManager.RefreshCraftingDetailsIfVisible then CraftingUIManager.RefreshCraftingDetailsIfVisible() end end)
		pcall(function() if GachaUIManager and GachaUIManager.UpdateCurrencyDisplay then GachaUIManager.UpdateCurrencyDisplay() end end)

		if enhVisible and EnhancementUIManager then
			if EnhancementUIManager.DisplayItemForEnhancement then 
				pcall(EnhancementUIManager.DisplayItemForEnhancement, EnhancementUIManager.currentSelectedItemInventoryIndex) 
			end
			if EnhancementUIManager.PopulateEnhanceableItems then 
				pcall(EnhancementUIManager.PopulateEnhanceableItems) 
			end
		end

		if CompanionUIManager and compVisible then
			pcall(CompanionUIManager.PopulateOwnedCompanionList)
			pcall(CompanionUIManager.PopulatePartySlots)
		end
		if LeaderboardUIManager and LeaderboardUIManager.leaderboardFrame and LeaderboardUIManager.leaderboardFrame.Visible then
			pcall(LeaderboardUIManager.RefreshLeaderboard)
		end
	end)
else warn("GuiManager: inventoryUpdatedEvent 없음") end

if playerStatsUpdatedEvent then
	playerStatsUpdatedEvent.OnClientEvent:Connect(function()
		print("GuiManager: Debug - playerStatsUpdatedEvent received!")
		local success, err = pcall(function()
			local function safeCall(module, funcName, ...)
				if module and module[funcName] and typeof(module[funcName]) == "function" then
					local isMethod = false
					if module == PurchaseNotifications or module == EnhancementNotifications or module == SkillShopUIManager or module == CompanionUIManager or module == DialogueManager then 
						isMethod = true
					end

					local callSuccess, callErr
					if isMethod then
						callSuccess, callErr = pcall(module[funcName], module, ...)
					else
						callSuccess, callErr = pcall(module[funcName], ...)
					end
					if not callSuccess then warn(string.format("Error calling %s.%s: %s", tostring(module), funcName, tostring(callErr))) end
				else
					warn(string.format("Module or function invalid/nil: %s.%s (Module Type: %s, Function Type: %s)", tostring(module), funcName, typeof(module), typeof(module and module[funcName])))
				end
			end
			print("GuiManager: Debug - Calling HUDManager.RefreshHUD. HUDManager is:", typeof(HUDManager)); safeCall(HUDManager, "RefreshHUD")
			print("GuiManager: Debug - Calling StatsUIManager.UpdateStatsDisplay. StatsUIManager is:", typeof(StatsUIManager)); safeCall(StatsUIManager, "UpdateStatsDisplay")
			print("GuiManager: Debug - Calling GachaUIManager.UpdateCurrencyDisplay. GachaUIManager is:", typeof(GachaUIManager)); safeCall(GachaUIManager, "UpdateCurrencyDisplay")
			print("GuiManager: Debug - Calling CraftingUIManager.RefreshCraftingDetailsIfVisible. CraftingUIManager is:", typeof(CraftingUIManager)); safeCall(CraftingUIManager, "RefreshCraftingDetailsIfVisible")
			print("GuiManager: Debug - Calling SkillShopUIManager.OnPlayerStatsUpdated. SkillShopUIManager is:", typeof(SkillShopUIManager)); safeCall(SkillShopUIManager, "OnPlayerStatsUpdated")

			local enhFrame = EnhancementUIManager and EnhancementUIManager.enhancementFrame; local isEnhVisible = enhFrame and enhFrame.Visible
			if isEnhVisible and EnhancementUIManager then
				print("GuiManager: Debug - Player stats updated, refreshing enhancement UI if visible.")
				safeCall(EnhancementUIManager, "DisplayItemForEnhancement", EnhancementUIManager.currentSelectedItemInventoryIndex)
				safeCall(EnhancementUIManager, "PopulateEnhanceableItems")
			end

			local compFrame = CompanionUIManager and CompanionUIManager.companionFrame; local compVisible = compFrame and compFrame.Visible
			if CompanionUIManager and compVisible then
				print("GuiManager: Debug - Player stats updated, refreshing companion UI details if visible.")
				if CompanionUIManager.selectedOwnedCompanionDbId then
					safeCall(CompanionUIManager, "ShowCompanionDetails", CompanionUIManager.selectedOwnedCompanionDbId)
				end
				safeCall(CompanionUIManager, "PopulatePartySlots")
			end
			if LeaderboardUIManager and LeaderboardUIManager.leaderboardFrame and LeaderboardUIManager.leaderboardFrame.Visible then
				print("GuiManager: Debug - Player stats updated, refreshing leaderboard if visible.")
				safeCall(LeaderboardUIManager, "RefreshLeaderboard")
			end
			print("GuiManager: Debug - playerStatsUpdatedEvent handler finished execution.")
		end); if not success then warn("GuiManager: Error inside playerStatsUpdatedEvent handler function:", err) end
	end)
else warn("GuiManager: playerStatsUpdatedEvent 없음") end

if SkillLearnedEvent then SkillLearnedEvent.OnClientEvent:Connect(function(learnedSkillId) if SkillShopUIManager and SkillShopUIManager.OnSkillLearned then pcall(SkillShopUIManager.OnSkillLearned, SkillShopUIManager, learnedSkillId) end end) else warn("GuiManager: SkillLearnedEvent 없음") end
if combatEndedClientEvent then combatEndedClientEvent.OnClientEvent:Connect(function() print("[GuiManager] 전투 종료됨."); if MapManager and MapManager.ShowMapFrame then pcall(MapManager.ShowMapFrame, true) else warn("[GuiManager] MapManager.ShowMapFrame 없음"); if CoreUIManager then CoreUIManager.SwitchFrame("MainMenu") end end; if MobileControlsManager and MobileControlsManager.ShowControls then pcall(MobileControlsManager.ShowControls, true) end end) else warn("GuiManager: combatEndedClientEvent 없음") end

if NotifyPlayerEvent then
	NotifyPlayerEvent.OnClientEvent:Connect(function(notificationType, data)
		print(string.format("DEBUG: 클라이언트: NotifyPlayerEvent 수신! 타입: %s", tostring(notificationType)))
		if data then
			local dataType = type(data)
			local dataStr = tostring(data)
			if dataType == "table" then
				local parts = {}
				for k, v in pairs(data) do table.insert(parts, string.format("%s=%s", tostring(k), tostring(v))) end
				dataStr = "{" .. table.concat(parts, ", ") .. "}"
			end
			print(string.format("DEBUG: 클라이언트: 수신 데이터 (%s): %s", dataType, dataStr))
		end

		local handled = false -- 팝업 알림이 처리되었는지 여부

		if notificationType == "PurchaseFailed" then
			if PurchaseNotifications and data and data.reason == "NotEnoughGold" then
				print("DEBUG: 클라이언트: PurchaseNotifications.ShowNotEnoughGold 호출 시도")
				pcall(PurchaseNotifications.ShowNotEnoughGold, PurchaseNotifications)
				handled = true
			end
		elseif notificationType == "ItemPurchased" then
			if PurchaseNotifications and data and data.itemName then
				print(string.format("DEBUG: 클라이언트: PurchaseNotifications.ShowItemPurchased 호출 시도 - 아이템명: %s", data.itemName))
				pcall(PurchaseNotifications.ShowItemPurchased, PurchaseNotifications, data.itemName)
				handled = true
			end
		elseif notificationType == "EnhancementResult" then
			if EnhancementNotifications and data then
				if data.success and data.itemName and data.newLevel then
					print(string.format("DEBUG: 클라이언트: EnhancementNotifications.ShowEnhancementSuccess 호출 시도 - 아이템: %s, 레벨: %s", tostring(data.itemName), tostring(data.newLevel)))
					local successCall, errCall = pcall(EnhancementNotifications.ShowEnhancementSuccess, data.itemName, data.newLevel) 
					if not successCall then warn("Error calling ShowEnhancementSuccess:", errCall) end
					handled = true 
				elseif not data.success and data.itemName and data.reason then
					print(string.format("DEBUG: 클라이언트: EnhancementNotifications.ShowEnhancementFailed 호출 시도 - 아이템: %s, 이유: %s", tostring(data.itemName), tostring(data.reason)))
					local successCall, errCall = pcall(EnhancementNotifications.ShowEnhancementFailed, data.itemName, data.reason)
					if not successCall then warn("Error calling ShowEnhancementFailed:", errCall) end
					handled = true 
				else
					print("DEBUG: 클라이언트: EnhancementResult 데이터 필드 부족 또는 success 값 불일치 (팝업용)")
				end
			else
				print("DEBUG: 클라이언트: EnhancementNotifications 모듈 또는 데이터 없음 (팝업용)")
			end

			-- 강화 창 UI 업데이트 (EnhancementUIManager 모듈 호출)
			if EnhancementUIManager and EnhancementUIManager.HandleEnhancementResult then
				print("DEBUG: 클라이언트: GuiManager에서 EnhancementUIManager.HandleEnhancementResult 호출 시도 (data):", data)
				local uiUpdateSuccess, uiUpdateErr = pcall(EnhancementUIManager.HandleEnhancementResult, data) 
				if not uiUpdateSuccess then 
					warn("Error calling EnhancementUIManager.HandleEnhancementResult:", uiUpdateErr) 
				else
					print("DEBUG: 클라이언트: GuiManager에서 EnhancementUIManager.HandleEnhancementResult 호출 성공")
				end
			else
				print("DEBUG: 클라이언트: EnhancementUIManager 또는 HandleEnhancementResult 함수 없음 (UI 업데이트용)")
				if not EnhancementUIManager then warn("DEBUG: EnhancementUIManager 모듈 자체가 nil입니다. (GuiManager > NotifyPlayerEvent)") end
				if EnhancementUIManager and not EnhancementUIManager.HandleEnhancementResult then warn("DEBUG: EnhancementUIManager.HandleEnhancementResult 함수가 nil입니다. (GuiManager > NotifyPlayerEvent)") end
			end
			-- handled = true; -- 팝업이 이미 handled 플래그를 설정했을 것이므로, 여기서는 UI 업데이트만 책임짐.

		elseif notificationType == "EquipFailed" then
			if CoreUIManager and CoreUIManager.ShowPopupMessage and data and data.reason then
				print("DEBUG: 클라이언트: CoreUIManager.ShowPopupMessage 호출 시도 (EquipFailed)")
				pcall(CoreUIManager.ShowPopupMessage, "장착 실패", data.reason)
				handled = true
			end
		elseif notificationType == "UnequipFailed" then
			if CoreUIManager and CoreUIManager.ShowPopupMessage and data and data.reason then
				print("DEBUG: 클라이언트: CoreUIManager.ShowPopupMessage 호출 시도 (UnequipFailed)")
				pcall(CoreUIManager.ShowPopupMessage, "해제 실패", data.reason)
				handled = true
			end
		elseif notificationType == "DevilFruitUseFailed" then
			if CoreUIManager and CoreUIManager.ShowPopupMessage and data and data.reason then
				print("DEBUG: 클라이언트: CoreUIManager.ShowPopupMessage 호출 시도 (DevilFruitUseFailed)")
				pcall(CoreUIManager.ShowPopupMessage, "사용 불가", data.reason)
				handled = true
			end
		elseif notificationType == "DevilFruitRemoved" then
			if CoreUIManager and CoreUIManager.ShowPopupMessage and data and data.message then
				print("DEBUG: 클라이언트: CoreUIManager.ShowPopupMessage 호출 시도 (DevilFruitRemoved)")
				pcall(CoreUIManager.ShowPopupMessage, "능력 제거", data.message)
				handled = true
			end
		elseif notificationType == "DevilFruitPulled" then
			if CoreUIManager and CoreUIManager.ShowPopupMessage and data and data.message then
				print("DEBUG: 클라이언트: CoreUIManager.ShowPopupMessage 호출 시도 (DevilFruitPulled)")
				pcall(CoreUIManager.ShowPopupMessage, "뽑기 결과", data.message)
				handled = true
			end
		elseif notificationType == "ActionFailed" then
			if CoreUIManager and CoreUIManager.ShowPopupMessage and data and data.reason then
				print("DEBUG: 클라이언트: CoreUIManager.ShowPopupMessage 호출 시도 (ActionFailed)")
				pcall(CoreUIManager.ShowPopupMessage, "실패", data.reason)
				handled = true
			end
		elseif notificationType == "PartyUpdateFailed" then
			if CoreUIManager and CoreUIManager.ShowPopupMessage and data and data.reason then
				print("DEBUG: 클라이언트: CoreUIManager.ShowPopupMessage 호출 시도 (PartyUpdateFailed)")
				pcall(CoreUIManager.ShowPopupMessage, "파티 변경 실패", data.reason)
				handled = true
			end
		end

		if not handled then
			print("[DEBUG] GuiManager: Notification not handled by specific modules, showing generic popup.")
			if CoreUIManager and CoreUIManager.ShowPopupMessage then
				local messageContent = data
				if type(data) == "table" then
					local parts = {}
					for k, v in pairs(data) do table.insert(parts, tostring(k)..": "..tostring(v)) end
					messageContent = table.concat(parts, ", ")
				end
				local titleText = type(notificationType) == "string" and notificationType or "알림"
				print(string.format("DEBUG: 클라이언트: CoreUIManager.ShowPopupMessage 호출 시도 (Generic) - 제목: %s, 내용: %s", titleText, tostring(messageContent)))
				pcall(CoreUIManager.ShowPopupMessage, titleText, tostring(messageContent))
			else
				warn("[GuiManager] CoreUIManager.ShowPopupMessage 없음")
			end
		end
	end)
	print("GuiManager: Enhanced NotifyPlayerEvent listener connected.")
else
	warn("GuiManager: NotifyPlayerEvent 없음")
end

print("GuiManager: 초기화 및 이벤트 리스너 설정 완료.")