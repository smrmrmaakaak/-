-- ButtonHandler.lua

local ButtonHandler = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local modulesFolder = ReplicatedStorage:WaitForChild("Modules")

-- 필요한 이벤트 및 함수 참조 (기존 코드 유지)
local unequipItemEvent = ReplicatedStorage:WaitForChild("UnequipItemEvent"); local craftItemEvent = ReplicatedStorage:WaitForChild("CraftItemEvent"); local pullGachaFunction = ReplicatedStorage:WaitForChild("PullGachaFunction"); local spendStatPointEvent = ReplicatedStorage:WaitForChild("SpendStatPointEvent"); local debugLevelUpEvent = ReplicatedStorage:WaitForChild("DebugLevelUpEvent"); local debugAddGoldEvent = ReplicatedStorage:WaitForChild("DebugAddGoldEvent"); local debugAddExpEvent = ReplicatedStorage:WaitForChild("DebugAddExpEvent"); local requestPlayerDefendEvent = ReplicatedStorage:WaitForChild("RequestPlayerDefendEvent"); local requestPlayerUseItemEvent = ReplicatedStorage:WaitForChild("RequestPlayerUseItemEvent")

local ModuleManager

-- 관리자 모듈 참조 변수
local CoreUIManager; local ShopUIManager; local InventoryUIManager; local CraftingUIManager; local CombatUIManager; local GachaUIManager; local StatsUIManager; local SkillShopUIManager; local MapManager; local MobileControlsManager; local SoundManager; local EnhancementUIManager;
local SettingsUIManager;
local DialogueManager
local CompanionUIManager
local LeaderboardUIManager -- <<< 리더보드 UI 매니저 참조 추가

-- 공통 닫기 로직 함수 (기존 코드 유지)
local function closeCurrentUIAndReturnToMap()
	if DialogueManager and DialogueManager.IsDialoguePaused and DialogueManager.IsDialoguePaused() then
		if DialogueManager.ResetDialogueBackgroundToDefault then
			DialogueManager.ResetDialogueBackgroundToDefault()
		end
	end
	if MapManager and MapManager.ShowMapFrame then MapManager.ShowMapFrame(true) end
	if MobileControlsManager and MobileControlsManager.ShowControls then MobileControlsManager.ShowControls(true) end
end

-- 버튼 이벤트를 설정하는 함수
function ButtonHandler.SetupButtonEvents(gui)
	if not ModuleManager then ModuleManager = require(modulesFolder:WaitForChild("ModuleManager")) end
	-- 모든 관리자 모듈 로드
	if not CoreUIManager then CoreUIManager = ModuleManager:GetModule("CoreUIManager") end;
	if not ShopUIManager then ShopUIManager = ModuleManager:GetModule("ShopUIManager") end;
	if not InventoryUIManager then InventoryUIManager = ModuleManager:GetModule("InventoryUIManager") end;
	if not CraftingUIManager then CraftingUIManager = ModuleManager:GetModule("CraftingUIManager") end;
	if not CombatUIManager then CombatUIManager = ModuleManager:GetModule("CombatUIManager") end;
	if not GachaUIManager then GachaUIManager = ModuleManager:GetModule("GachaUIManager") end;
	if not StatsUIManager then StatsUIManager = ModuleManager:GetModule("StatsUIManager") end;
	if not SkillShopUIManager then SkillShopUIManager = ModuleManager:GetModule("SkillShopUIManager") end;
	if not MapManager then MapManager = ModuleManager:GetModule("MapManager") end;
	if not MobileControlsManager then MobileControlsManager = ModuleManager:GetModule("MobileControlsManager") end;
	if not SoundManager then SoundManager = ModuleManager:GetModule("SoundManager") end;
	if not EnhancementUIManager then EnhancementUIManager = ModuleManager:GetModule("EnhancementUIManager") end;
	if not SettingsUIManager then SettingsUIManager = ModuleManager:GetModule("SettingsUIManager") end
	if not DialogueManager then DialogueManager = ModuleManager:GetModule("DialogueManager") end
	if not CompanionUIManager then CompanionUIManager = ModuleManager:GetModule("CompanionUIManager") end
	if not LeaderboardUIManager then LeaderboardUIManager = ModuleManager:GetModule("LeaderboardUIManager") end -- <<< 리더보드 UI 매니저 로드

	print("ButtonHandler: SetupButtonEvents 함수 시작...")
	local backgroundFrame = gui:WaitForChild("BackgroundFrame"); if not backgroundFrame then warn("BG Frame 없음!"); return end
	local framesFolder = backgroundFrame:FindFirstChild("Frames")

	-- ==================== MainMenu ====================
	local mainMenuFrame = framesFolder and framesFolder:FindFirstChild("MainMenu")
	if mainMenuFrame then
		local startBtn = mainMenuFrame:FindFirstChild("GameStartButton")
		local setBtn = mainMenuFrame:FindFirstChild("SettingsButton")
		-- ##### 리더보드 버튼 추가 (MainMenuBuilder.lua에 "LeaderboardButton" 이름으로 버튼 생성 필요) #####
		local leaderboardBtn = mainMenuFrame:FindFirstChild("LeaderboardButton")
		if startBtn then startBtn.MouseButton1Click:Connect(function() print("GameStart Clicked"); if CoreUIManager then CoreUIManager.ShowFrame("MainMenu",false) end; closeCurrentUIAndReturnToMap() end) end
		if setBtn then setBtn.MouseButton1Click:Connect(function() print("Settings Button Clicked"); if SettingsUIManager then SettingsUIManager.ShowSettings(true) end; if CoreUIManager then CoreUIManager.ShowFrame("MainMenu", false) end end) end
		if leaderboardBtn then
			leaderboardBtn.MouseButton1Click:Connect(function()
				print("MainMenu Leaderboard Button Clicked")
				if LeaderboardUIManager then LeaderboardUIManager.ShowLeaderboardUI(true) end
				if CoreUIManager then CoreUIManager.ShowFrame("MainMenu", false) end
				-- 이 경우 맵으로 바로 돌아가지 않고 리더보드를 보여줍니다.
			end)
		else
			warn("ButtonHandler: MainMenu의 LeaderboardButton을 찾을 수 없습니다. (MainMenuBuilder.lua 확인 필요)")
		end
	else warn("ButtonHandler: MainMenu 프레임 없음") end

	-- ==================== Combat Screen Buttons ====================
	local combatScreenFrame = framesFolder and framesFolder:FindFirstChild("CombatScreen")
	if combatScreenFrame then
		local bottomUI = combatScreenFrame:WaitForChild("BottomUIArea", 5); local actionMenu = bottomUI and bottomUI:WaitForChild("ActionMenuFrame", 5)
		if actionMenu then
			local atkBtn=actionMenu:FindFirstChild("AttackButton"); local sklBtn=actionMenu:FindFirstChild("SkillButton"); local defBtn=actionMenu:FindFirstChild("DefendButton"); local itmBtn=actionMenu:FindFirstChild("ItemButton");
			if atkBtn then atkBtn.MouseButton1Click:Connect(function() if CombatUIManager then print("공격 버튼 클릭됨"); CombatUIManager.EnableActionButtons(false); if CombatUIManager.StartTargetSelection then CombatUIManager.StartTargetSelection("attack") else warn("StartTargetSelection 없음"); CombatUIManager.EnableActionButtons(true) end else warn("CombatUIManager 없음") end end) end
			if sklBtn then sklBtn.MouseButton1Click:Connect(function() if CombatUIManager then print("스킬 버튼 클릭됨"); CombatUIManager.EnableActionButtons(false); if CombatUIManager.ShowSkillSelection then CombatUIManager.ShowSkillSelection(true) else warn("ShowSkillSelection 없음"); CombatUIManager.EnableActionButtons(true) end else warn("CombatUIManager 없음") end end) end
			if defBtn then defBtn.MouseButton1Click:Connect(function() if CombatUIManager then print("보호 버튼 클릭됨"); CombatUIManager.EnableActionButtons(false); if requestPlayerDefendEvent then requestPlayerDefendEvent:FireServer() else warn("DefendEvent 없음"); CombatUIManager.EnableActionButtons(true) end else warn("CombatUIManager 없음") end end) end
			if itmBtn then itmBtn.MouseButton1Click:Connect(function() if CombatUIManager then print("아이템 버튼 클릭됨"); CombatUIManager.EnableActionButtons(false); if CombatUIManager.ShowCombatItemSelection then CombatUIManager.ShowCombatItemSelection(true) else warn("ShowCombatItemSelection 없음"); CombatUIManager.EnableActionButtons(true) end else warn("CombatUIManager 없음") end end) end
		else warn("ActionMenuFrame 없음") end
	else warn("CombatScreen 없음 (나중에 로드될 수 있음)") end

	task.spawn(function()
		local skillSel = backgroundFrame:WaitForChild("SkillSelectionFrame", 10); if skillSel then local cancel = skillSel:WaitForChild("CancelSkillButton", 5); if cancel then cancel.MouseButton1Click:Connect(function() print("스킬 취소 클릭됨"); if CombatUIManager then CombatUIManager.ShowSkillSelection(false); CombatUIManager.CancelTargetSelection(false); CombatUIManager.EnableActionButtons(true) end end) end end
		local itemSel = backgroundFrame:WaitForChild("CombatItemSelectionFrame", 10); if itemSel then local cancel = itemSel:WaitForChild("CancelItemButton", 5); if cancel then cancel.MouseButton1Click:Connect(function() print("아이템 취소 클릭됨"); if CombatUIManager then CombatUIManager.ShowCombatItemSelection(false); CombatUIManager.CancelTargetSelection(false); CombatUIManager.EnableActionButtons(true) end end) end end
	end)

	local shopFrame = backgroundFrame:FindFirstChild("ShopFrame")
	if shopFrame then
		local closeBtn=shopFrame:FindFirstChild("CloseShopButton"); local tabs=shopFrame:FindFirstChild("TabFrame"); local buyBtn=tabs and tabs:FindFirstChild("BuyTabButton"); local sellBtn=tabs and tabs:FindFirstChild("SellTabButton");
		if closeBtn then closeBtn.MouseButton1Click:Connect(function() print("상점 닫기"); if ShopUIManager then ShopUIManager.ShowShop(false) end; closeCurrentUIAndReturnToMap() end) end
		if buyBtn then buyBtn.MouseButton1Click:Connect(function() if ShopUIManager then ShopUIManager.SetShopMode("Buy") end end) end
		if sellBtn then sellBtn.MouseButton1Click:Connect(function() if ShopUIManager then ShopUIManager.SetShopMode("Sell") end end) end
	else warn("ShopFrame 없음") end

	local invFrame = backgroundFrame:FindFirstChild("InventoryFrame")
	if invFrame then
		local closeBtn=invFrame:FindFirstChild("CloseInventoryButton")
		if closeBtn then closeBtn.MouseButton1Click:Connect(function() print("인벤 닫기"); if InventoryUIManager then InventoryUIManager.ShowInventory(false) end; closeCurrentUIAndReturnToMap() end) end
	else warn("InventoryFrame 없음") end

	local huntFrame = framesFolder and framesFolder:FindFirstChild("HuntingGroundSelectionFrame")
	if huntFrame then
		local backBtn=huntFrame:FindFirstChild("BackButton")
		if backBtn then backBtn.MouseButton1Click:Connect(function() print("사냥터 뒤로가기"); if CoreUIManager then CoreUIManager.ShowFrame("HuntingGroundSelectionFrame",false); CoreUIManager.SwitchFrame("MainMenu") end; closeCurrentUIAndReturnToMap() end) end
	else warn("HuntingGroundSelectionFrame 없음") end

	local equipFrame = backgroundFrame:FindFirstChild("EquipmentFrame")
	if equipFrame then
		local closeBtn = equipFrame:FindFirstChild("CloseButton"); local wSlot = equipFrame:FindFirstChild("WeaponSlot"); local aSlot = equipFrame:FindFirstChild("ArmorSlot"); local accSlot1 = equipFrame:FindFirstChild("AccessorySlot1"); local accSlot2 = equipFrame:FindFirstChild("AccessorySlot2"); local accSlot3 = equipFrame:FindFirstChild("AccessorySlot3");
		if closeBtn then closeBtn.MouseButton1Click:Connect(function() print("장비 닫기"); if InventoryUIManager then InventoryUIManager.ShowEquipment(false) end; closeCurrentUIAndReturnToMap() end) end
		if wSlot then wSlot.MouseButton1Click:Connect(function() local pos=UserInputService:GetMouseLocation(); if InventoryUIManager then InventoryUIManager.ShowTooltipForEquippedSlot("Weapon",pos) end end) end
		if aSlot then aSlot.MouseButton1Click:Connect(function() local pos=UserInputService:GetMouseLocation(); if InventoryUIManager then InventoryUIManager.ShowTooltipForEquippedSlot("Armor",pos) end end) end
		if accSlot1 then accSlot1.MouseButton1Click:Connect(function() local pos=UserInputService:GetMouseLocation(); if InventoryUIManager then InventoryUIManager.ShowTooltipForEquippedSlot("Accessory1",pos) end end) end
		if accSlot2 then accSlot2.MouseButton1Click:Connect(function() local pos=UserInputService:GetMouseLocation(); if InventoryUIManager then InventoryUIManager.ShowTooltipForEquippedSlot("Accessory2",pos) end end) end
		if accSlot3 then accSlot3.MouseButton1Click:Connect(function() local pos=UserInputService:GetMouseLocation(); if InventoryUIManager then InventoryUIManager.ShowTooltipForEquippedSlot("Accessory3",pos) end end) end
	else warn("EquipmentFrame 없음") end

	local craftFrame = backgroundFrame:FindFirstChild("CraftingFrame")
	if craftFrame then
		local closeBtn=craftFrame:FindFirstChild("CloseButton"); local details=craftFrame:FindFirstChild("DetailsFrame"); local craftBtn=details and details:FindFirstChild("CraftButton");
		if closeBtn then closeBtn.MouseButton1Click:Connect(function() print("제작 닫기"); if CraftingUIManager then CraftingUIManager.ShowCrafting(false) end; closeCurrentUIAndReturnToMap() end) end
		if craftBtn then craftBtn.MouseButton1Click:Connect(function() print("제작 버튼 클릭"); if CraftingUIManager then local id=CraftingUIManager.GetSelectedCraftingRecipeId(); if id then if craftItemEvent then craftItemEvent:FireServer(id) else warn("CraftItemEvent 없음") end else warn("선택된 레시피 없음") end else warn("CraftingUIManager 없음") end end) end
	else warn("CraftingFrame 없음") end

	local gachaFrame = backgroundFrame:FindFirstChild("GachaFrame")
	if gachaFrame then
		local closeBtn=gachaFrame:FindFirstChild("CloseButton"); local opts=gachaFrame:FindFirstChild("PullOptionsFrame"); local pullBtn=opts and opts:FindFirstChild("PullNormal1Button");
		if closeBtn then closeBtn.MouseButton1Click:Connect(function() print("뽑기 닫기"); if GachaUIManager then GachaUIManager.ShowGacha(false) end; closeCurrentUIAndReturnToMap() end) end
		if pullBtn then pullBtn.MouseButton1Click:Connect(function() local pool="NormalEquip"; print("뽑기 버튼 클릭:", pool); if pullGachaFunction then local ok,res=pcall(pullGachaFunction.InvokeServer,pullGachaFunction,pool); if ok then if GachaUIManager then GachaUIManager.ShowPullResult(res) end else warn("뽑기 Invoke 오류:",res) end else warn("PullGachaFunction 없음") end end) end
	else warn("GachaFrame 없음") end

	local statsFrame = backgroundFrame:FindFirstChild("StatsFrame")
	if statsFrame then
		local closeStatsButton = statsFrame:FindFirstChild("CloseButton"); local baseStatsFrame = statsFrame:FindFirstChild("BaseStatsFrame");
		if closeStatsButton then closeStatsButton.MouseButton1Click:Connect(function() print("스탯 창 닫기"); if StatsUIManager then StatsUIManager.ShowStatsFrame(false) end; closeCurrentUIAndReturnToMap() end) end
		if baseStatsFrame then
			local statsToConnect = {"STR", "AGI", "INT", "LUK"};
			for _, statName in ipairs(statsToConnect) do
				local lineFrame = baseStatsFrame:FindFirstChild(statName .. "Line");
				if lineFrame then
					local increaseButton = lineFrame:FindFirstChild("Increase" .. statName .. "Button");
					if increaseButton and increaseButton:IsA("TextButton") then
						local connection = increaseButton:FindFirstChild("ButtonClickConnection"); if connection then connection:Destroy() end
						increaseButton.MouseButton1Click:Connect(function() if StatsUIManager and StatsUIManager.IncreaseStat then StatsUIManager.IncreaseStat(statName) else warn("StatsUIManager.IncreaseStat 없음") end end)
						local marker = Instance.new("BoolValue"); marker.Name = "ButtonClickConnection"; marker.Parent = increaseButton
					else warn("Increase button 없음:", statName) end
				else warn("Line frame 없음:", statName) end
			end
		else warn("BaseStatsFrame 없음") end
	else warn("StatsFrame 없음") end

	local skillShopFrame = backgroundFrame:FindFirstChild("SkillShopFrame")
	if skillShopFrame then
		local closeBtn=skillShopFrame:FindFirstChild("CloseButton")
		if closeBtn then closeBtn.MouseButton1Click:Connect(function() print("스킬 상점 닫기"); if SkillShopUIManager then SkillShopUIManager.ShowSkillShop(false) end; closeCurrentUIAndReturnToMap() end) end
	else warn("SkillShopFrame 없음") end

	local playerHUD = backgroundFrame:FindFirstChild("PlayerHUD")
	if playerHUD then
		local btnCont=playerHUD:FindFirstChild("HudButtonContainer")
		if btnCont then
			local infoBtn=btnCont:FindFirstChild("HudInfoButton"); local statBtn=btnCont:FindFirstChild("HudStatsButton"); local invBtn=btnCont:FindFirstChild("HudInventoryButton"); local equipBtn=btnCont:FindFirstChild("HudEquipmentButton");
			local companionBtn = btnCont:FindFirstChild("HudCompanionButton")
			-- ##### HUD에 리더보드 버튼 추가 (PlayerHUDBuilder.lua에 "HudLeaderboardButton" 이름으로 버튼 생성 필요) #####
			local hudLeaderboardBtn = btnCont:FindFirstChild("HudLeaderboardButton")


			if infoBtn and statBtn and invBtn and equipBtn and companionBtn and hudLeaderboardBtn then -- hudLeaderboardBtn 조건 추가
				infoBtn.MouseButton1Click:Connect(function()
					local vis=not statBtn.Visible;
					statBtn.Visible=vis;
					invBtn.Visible=vis;
					equipBtn.Visible=vis;
					companionBtn.Visible=vis
					hudLeaderboardBtn.Visible = vis -- 리더보드 버튼도 함께 토글
				end)
			end
			if statBtn then statBtn.MouseButton1Click:Connect(function() if StatsUIManager then StatsUIManager.ShowStatsFrame(true) end; if MapManager then MapManager.ShowMapFrame(false) end; if MobileControlsManager then MobileControlsManager.ShowControls(false) end; statBtn.Visible=false; if invBtn then invBtn.Visible=false end; if equipBtn then equipBtn.Visible=false end; if companionBtn then companionBtn.Visible=false end; if hudLeaderboardBtn then hudLeaderboardBtn.Visible=false end end) end
			if invBtn then invBtn.MouseButton1Click:Connect(function() if InventoryUIManager then InventoryUIManager.ShowInventory(true) end; if MapManager then MapManager.ShowMapFrame(false) end; if MobileControlsManager then MobileControlsManager.ShowControls(false) end; if statBtn then statBtn.Visible=false end; invBtn.Visible=false; if equipBtn then equipBtn.Visible=false end; if companionBtn then companionBtn.Visible=false end; if hudLeaderboardBtn then hudLeaderboardBtn.Visible=false end end) end
			if equipBtn then equipBtn.MouseButton1Click:Connect(function() if InventoryUIManager then InventoryUIManager.ShowEquipment(true) end; if MapManager then MapManager.ShowMapFrame(false) end; if MobileControlsManager then MobileControlsManager.ShowControls(false) end; if statBtn then statBtn.Visible=false end; if invBtn then invBtn.Visible=false end; equipBtn.Visible=false; if companionBtn then companionBtn.Visible=false end; if hudLeaderboardBtn then hudLeaderboardBtn.Visible=false end end) end
			if companionBtn then
				companionBtn.MouseButton1Click:Connect(function()
					print("HUD 동료 버튼 클릭됨")
					if CompanionUIManager then CompanionUIManager.ShowCompanionUI(true) end
					if MapManager then MapManager.ShowMapFrame(false) end
					if MobileControlsManager then MobileControlsManager.ShowControls(false) end
					if statBtn then statBtn.Visible=false end
					if invBtn then invBtn.Visible=false end
					if equipBtn then equipBtn.Visible=false end
					companionBtn.Visible = false
					if hudLeaderboardBtn then hudLeaderboardBtn.Visible=false end
				end)
			end
			if hudLeaderboardBtn then -- 리더보드 버튼 이벤트
				hudLeaderboardBtn.MouseButton1Click:Connect(function()
					print("HUD 리더보드 버튼 클릭됨")
					if LeaderboardUIManager then LeaderboardUIManager.ShowLeaderboardUI(true) end
					if MapManager then MapManager.ShowMapFrame(false) end
					if MobileControlsManager then MobileControlsManager.ShowControls(false) end
					if statBtn then statBtn.Visible=false end
					if invBtn then invBtn.Visible=false end
					if equipBtn then equipBtn.Visible=false end
					if companionBtn then companionBtn.Visible=false end
					hudLeaderboardBtn.Visible = false
				end)
			else
				warn("ButtonHandler: PlayerHUD의 HudLeaderboardButton을 찾을 수 없습니다. (PlayerHUDBuilder.lua 확인 필요)")
			end
		else warn("HudButtonContainer 없음") end
	end

	local resultsFrame = backgroundFrame:FindFirstChild("CombatResultsFrame")
	if resultsFrame then
		local closeBtn = resultsFrame:FindFirstChild("CloseResultsButton")
		if closeBtn then closeBtn.MouseButton1Click:Connect(function() if CoreUIManager then CoreUIManager.ShowFrame("CombatResultsFrame", false) end; closeCurrentUIAndReturnToMap() end) else warn("CombatResultsFrame CloseButton 없음") end
	else warn("CombatResultsFrame 없음") end

	local enhancementFrame = backgroundFrame:FindFirstChild("EnhancementFrame")
	if enhancementFrame then
		local closeBtn = enhancementFrame:FindFirstChild("CloseButton")
		if closeBtn then closeBtn.MouseButton1Click:Connect(function() print("Enhancement Close Button Clicked"); if EnhancementUIManager then EnhancementUIManager.ShowEnhancementWindow(false) end; closeCurrentUIAndReturnToMap() end) end
	else warn("EnhancementFrame 없음") end

	-- ==================== Settings (오디오 버튼 추가) ====================
	local settingsFrame = framesFolder and framesFolder:FindFirstChild("SettingsFrame")
	if settingsFrame then
		local closeBtn = settingsFrame:FindFirstChild("CloseButton")
		if closeBtn then closeBtn.MouseButton1Click:Connect(function() print("Settings Close Button Clicked"); if SettingsUIManager then SettingsUIManager.ShowSettings(false) end; if CoreUIManager then CoreUIManager.SwitchFrame("MainMenu") end; closeCurrentUIAndReturnToMap() end) end

		local contentFrame = settingsFrame:FindFirstChild("ContentFrame")
		if contentFrame then
			local resetBtn = contentFrame:FindFirstChild("ResetDataButton")
			if resetBtn then resetBtn.MouseButton1Click:Connect(function() print("Reset Data Button Clicked"); if SettingsUIManager and SettingsUIManager.RequestDataResetConfirmation then SettingsUIManager.RequestDataResetConfirmation() end end) end

			local bgmContainer = contentFrame:FindFirstChild("BGMVolumeContainer")
			if bgmContainer then
				local bgmDecrease = bgmContainer:FindFirstChild("BGMDecreaseButton")
				local bgmIncrease = bgmContainer:FindFirstChild("BGMIncreaseButton")
				local bgmMute = bgmContainer:FindFirstChild("BGMMuteButton")

				if bgmDecrease then bgmDecrease.MouseButton1Click:Connect(function() if SettingsUIManager then SettingsUIManager.ChangeBGMVolume(false) end end) end
				if bgmIncrease then bgmIncrease.MouseButton1Click:Connect(function() if SettingsUIManager then SettingsUIManager.ChangeBGMVolume(true) end end) end
				if bgmMute then bgmMute.MouseButton1Click:Connect(function() if SettingsUIManager then SettingsUIManager.ToggleBGMMute() end end) end
			else warn("ButtonHandler: BGMVolumeContainer 없음") end

			local sfxContainer = contentFrame:FindFirstChild("SFXVolumeContainer")
			if sfxContainer then
				local sfxDecrease = sfxContainer:FindFirstChild("SFXDecreaseButton")
				local sfxIncrease = sfxContainer:FindFirstChild("SFXIncreaseButton")
				local sfxMute = sfxContainer:FindFirstChild("SFXMuteButton")

				if sfxDecrease then sfxDecrease.MouseButton1Click:Connect(function() if SettingsUIManager then SettingsUIManager.ChangeSFXVolume(false) end end) end
				if sfxIncrease then sfxIncrease.MouseButton1Click:Connect(function() if SettingsUIManager then SettingsUIManager.ChangeSFXVolume(true) end end) end
				if sfxMute then sfxMute.MouseButton1Click:Connect(function() if SettingsUIManager then SettingsUIManager.ToggleSFXMute() end end) end
			else warn("ButtonHandler: SFXVolumeContainer 없음") end
		else warn("ButtonHandler: Settings ContentFrame 없음") end
	else warn("ButtonHandler: SettingsFrame 없음") end

	-- ==================== Companion UI ====================
	local companionFrameInstance = backgroundFrame:FindFirstChild("CompanionFrame")
	if companionFrameInstance then
		local closeCompanionBtn = companionFrameInstance:FindFirstChild("CloseButton")
		if closeCompanionBtn then
			closeCompanionBtn.MouseButton1Click:Connect(function()
				print("동료 UI 닫기 버튼 클릭됨")
				if CompanionUIManager then CompanionUIManager.ShowCompanionUI(false) end
				closeCurrentUIAndReturnToMap()
			end)
		else
			warn("ButtonHandler: CompanionFrame의 CloseButton을 찾을 수 없습니다.")
		end
	else
		warn("ButtonHandler: CompanionFrame을 찾을 수 없습니다.")
	end

	-- ==================== Leaderboard UI ====================
	local leaderboardFrameInstance = backgroundFrame:FindFirstChild("LeaderboardFrame")
	if leaderboardFrameInstance then
		local closeLeaderboardBtn = leaderboardFrameInstance:FindFirstChild("CloseButton")
		if closeLeaderboardBtn then
			closeLeaderboardBtn.MouseButton1Click:Connect(function()
				print("리더보드 UI 닫기 버튼 클릭됨")
				if LeaderboardUIManager then LeaderboardUIManager.ShowLeaderboardUI(false) end
				-- 리더보드를 닫을 때, 이전 UI 상태에 따라 적절한 동작 수행
				-- 예: 메인 메뉴에서 열었으면 메인 메뉴로, HUD에서 열었으면 맵으로
				-- 여기서는 일단 맵으로 돌아가도록 함
				local currentFrame = CoreUIManager and CoreUIManager.GetCurrentFrame()
				if currentFrame and currentFrame.Name == "MainMenu" then -- 만약 메인 메뉴가 닫히지 않았다면
					-- CoreUIManager.SwitchFrame("MainMenu") -- 필요에 따라 메인 메뉴를 다시 활성화
				else
					closeCurrentUIAndReturnToMap()
				end
			end)
		else
			warn("ButtonHandler: LeaderboardFrame의 CloseButton을 찾을 수 없습니다.")
		end
	else
		warn("ButtonHandler: LeaderboardFrame을 찾을 수 없습니다.")
	end

	print("ButtonHandler: 버튼 이벤트 설정 완료.")
end

print("ButtonHandler: SetupButtonEvents function defined.")
return ButtonHandler