-- GuiManager.lua

-- StarterGui > MainGui > GuiManager (LocalScript)

-- �ʿ��� ���� ��������
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

-- �÷��̾� �� GUI ��ü ����
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainGui = script.Parent

-- ��� ���� ����
local modulesFolder = ReplicatedStorage:WaitForChild("Modules", 20)
if not modulesFolder then warn("GuiManager: CRITICAL - Modules ������ ã�� �� �����ϴ�! UI �ʱ�ȭ �Ұ�."); return end

-- *** 1�ܰ�: �ٽ� ��� �ε� ***
print("GuiManager: 1�ܰ� - �ٽ� ��� �ε� ����")
local ModuleManager = require(modulesFolder:WaitForChild("ModuleManager", 15)); if not ModuleManager then warn("GuiManager: CRITICAL - ModuleManager �ε� ����!"); return end
local GuiUtils = ModuleManager:GetModule("GuiUtils"); if not GuiUtils then warn("GuiManager: CRITICAL - GuiUtils �ε� ����!"); return end
local GuiBuilder = ModuleManager:GetModule("GuiBuilder"); if not GuiBuilder then warn("GuiManager: CRITICAL - GuiBuilder �ε� ����!"); return end
local CoreUIManager = ModuleManager:GetModule("CoreUIManager"); if not CoreUIManager then warn("GuiManager: CRITICAL - CoreUIManager �ε� ����!"); return end
print("GuiManager: 1�ܰ� - �ٽ� ��� �ε� �Ϸ�")

-- *** 2�ܰ�: �⺻ UI ���� ***
print("GuiManager: 2�ܰ� - �⺻ UI ���� ����")
mainGui.IgnoreGuiInset = true
local backgroundFrame
if GuiBuilder and GuiBuilder.BuildBaseUI then
	if GuiBuilder.Init then GuiBuilder.Init() end
	local success, err = pcall(GuiBuilder.BuildBaseUI, mainGui)
	if not success then warn("GuiManager: CRITICAL - GuiBuilder.BuildBaseUI ���� �� ���� �߻�!", err); return end
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
			print("GuiManager: MainBackgroundImage ������")
		end
	else
		warn("GuiManager: backgroundFrame�� ã�� �� ���� MainBackgroundImage�� ����/������ �� �����ϴ�.")
	end
	print("GuiManager: 2�ܰ� - �⺻ UI ���� �Ϸ�")
else warn("GuiManager: CRITICAL - GuiBuilder �Ǵ� BuildBaseUI �Լ��� ã�� �� ���� UI�� ������ �� �����ϴ�."); return end

-- *** 3�ܰ�: ������ ��� ��� �ε� ***
print("GuiManager: 3�ܰ� - ������ ��� �ε� ����")
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
local EnhancementUIManager = ModuleManager:GetModule("EnhancementUIManager") -- EnhancementUIManager �ε�
local SettingsUIManager = ModuleManager:GetModule("SettingsUIManager")
local PurchaseNotifications = ModuleManager:GetModule("PurchaseNotifications")
local EnhancementNotifications = ModuleManager:GetModule("EnhancementNotifications") -- EnhancementNotifications �ε�
local CompanionUIManager = ModuleManager:GetModule("CompanionUIManager")
local LeaderboardUIManager = ModuleManager:GetModule("LeaderboardUIManager")
print("GuiManager: 3�ܰ� - ������ ��� �ε� �Ϸ� �õ�")

-- ���� �̺�Ʈ ����
print("GuiManager: ���� �̺�Ʈ ���� ���� (WaitForChild)")
local eventWaitTimeout = 15
local inventoryUpdatedEvent = ReplicatedStorage:WaitForChild("InventoryUpdatedEvent", eventWaitTimeout)
local playerStatsUpdatedEvent = ReplicatedStorage:WaitForChild("PlayerStatsUpdatedEvent", eventWaitTimeout)
print("GuiManager: Debug - playerStatsUpdatedEvent type:", typeof(playerStatsUpdatedEvent), "IsA RemoteEvent:", playerStatsUpdatedEvent and playerStatsUpdatedEvent:IsA("RemoteEvent") or "N/A")
local combatEndedClientEvent = ReplicatedStorage:WaitForChild("CombatEndedClientEvent", eventWaitTimeout)
local SkillLearnedEvent = ReplicatedStorage:WaitForChild("SkillLearnedEvent", eventWaitTimeout)
local NotifyPlayerEvent = ReplicatedStorage:WaitForChild("NotifyPlayerEvent", eventWaitTimeout)
local RequestStartCombatEvent = ReplicatedStorage:WaitForChild("RequestStartCombatEvent", eventWaitTimeout)
local companionUpdatedEvent = ReplicatedStorage:WaitForChild("CompanionUpdatedEvent", eventWaitTimeout)
print("GuiManager: ���� �̺�Ʈ ���� �Ϸ�")

-- *** 4�ܰ�: ��� �ʱ�ȭ ***
print("GuiManager: 4�ܰ� - ��� �ʱ�ȭ ����")
local function tryInit(module, moduleName, ...)
	if module then
		if module.Init and typeof(module.Init) == "function" then
			local success, err = pcall(module.Init, ...)
			if not success then warn("GuiManager: " .. moduleName .. ".Init() ���� �� ����!", err) end
		end
	else
		warn("GuiManager: " .. moduleName .. " ����� nil�̹Ƿ� Init() ȣ�� �Ұ�.")
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
tryInit(EnhancementUIManager, "EnhancementUIManager"); -- EnhancementUIManager �ʱ�ȭ
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
		warn("MapManager.Init ����!", e)
	end
elseif not MapManager then
	warn("MapManager ��� nil, Init �Ұ�")
end

tryInit(MapRenderer, "MapRenderer");
if MapInputHandler and MapInputHandler.Init then local s,e = pcall(MapInputHandler.Init); if not s then warn("MapInputHandler.Init ����!", e) end elseif not MapInputHandler then warn("MapInputHandler ��� nil, Init �Ұ�") end
if MapInteractor and MapInteractor.Init then local s,e = pcall(MapInteractor.Init, MapManager, interactorDependencies); if not s then warn("MapInteractor.Init ����!", e) end elseif not MapInteractor then warn("MapInteractor ��� nil, Init �Ұ�") end
print("[DEBUG] GuiManager: Preparing to init MobileControlsManager. Type of MapManager:", typeof(MapManager))
tryInit(MobileControlsManager, "MobileControlsManager", MapManager, GuiUtils)
print("GuiManager: 4�ܰ� - ��� �ʱ�ȭ �Ϸ�")

-- *** 5�ܰ�: UI ���� �� �ʿ��� ���� ���� ***
print("GuiManager: 5�ܰ� - UI ���� ���� ����")
local function trySetupUI(module, moduleName)
	if module and module.SetupUIReferences then
		local success, err = pcall(module.SetupUIReferences)
		if not success then warn("GuiManager: " .. moduleName .. ".SetupUIReferences() ����!", err) end
	end
end
trySetupUI(IntroManager, "IntroManager"); trySetupUI(LoadingManager, "LoadingManager"); trySetupUI(DialogueManager, "DialogueManager"); trySetupUI(SkillShopUIManager, "SkillShopUIManager"); trySetupUI(EnhancementUIManager, "EnhancementUIManager");
trySetupUI(CompanionUIManager, "CompanionUIManager")
trySetupUI(LeaderboardUIManager, "LeaderboardUIManager")

if TooltipManager and TooltipManager.CreateTooltipFrame then
	local s,e = pcall(TooltipManager.CreateTooltipFrame, mainGui)
	if not s then warn("TooltipManager.CreateTooltipFrame ����!", e) end
end
if MobileControlsManager and MobileControlsManager.CreateControls then
	local success, err = pcall(MobileControlsManager.CreateControls, mainGui)
	if not success then warn("GuiManager: MobileControlsManager.CreateControls() ���� �� ����!", err) end
else warn("GuiManager: MobileControlsManager �Ǵ� CreateControls �Լ��� ã�� �� �����ϴ�.") end
print("GuiManager: 5�ܰ� - UI ���� ���� �Ϸ�")

task.wait(0.2)

-- *** 6�ܰ�: ��ư �̺�Ʈ ���� ***
print("GuiManager: 6�ܰ� - ��ư �̺�Ʈ ���� ����")
if ButtonHandler and ButtonHandler.SetupButtonEvents then
	print("GuiManager: ButtonHandler �� SetupButtonEvents �Լ��� ã�ҽ��ϴ�. ���� �õ�...")
	local success, err = pcall(ButtonHandler.SetupButtonEvents, mainGui)
	if success then print("GuiManager: ��ư �̺�Ʈ ���� ����.") else warn("GuiManager: ButtonHandler.SetupButtonEvents ���� �� ���� �߻�!", err) end
else
	warn("GuiManager: ButtonHandler �Ǵ� SetupButtonEvents �Լ��� ã�� �� ���� ��ư �̺�Ʈ�� ������ �� �����ϴ�.")
	if not ButtonHandler then warn("GuiManager: ButtonHandler ����� nil �Դϴ�.") elseif not ButtonHandler.SetupButtonEvents then warn("GuiManager: ButtonHandler.SetupButtonEvents �Լ��� �����ϴ�.") end
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
			if not success then warn("GuiManager: MobileControlsManager.SetupToggleButton() ���� �� ����!", err) end
		else
			if not MobileControlsManager then warn("GuiManager: MobileControlsManager�� �ε���� �ʾҽ��ϴ�!") end
			if not MobileControlsManager.SetupToggleButton then warn("GuiManager: MobileControlsManager.SetupToggleButton �Լ��� �����ϴ�!") end
		end
	else
		warn("GuiManager: ToggleMobileControlsButton�� ã�� �� �����ϴ�! (WaitForChild Timeout)")
	end
end)
print("GuiManager: 6�ܰ� - ��ư �̺�Ʈ ���� �õ� �Ϸ�")

-- *** 7�ܰ�: ���� ���� �帧 ***
print("GuiManager: 7�ܰ� - ���� ���� �帧 ����")
if IntroManager and LoadingManager and CoreUIManager then
	IntroManager.ShowIntro()
	local success, err = pcall(IntroManager.PlayIntroAnimation, function()
		IntroManager.HideIntro()
		LoadingManager.ShowLoading("������ �غ� ���Դϴ�...")
		task.wait(1)
		LoadingManager.HideLoading()
		if CoreUIManager and CoreUIManager.SwitchFrame then
			CoreUIManager.SwitchFrame("MainMenu")
			print("GuiManager: Game started, showing MainMenu.")
		else
			warn("GuiManager: CoreUIManager.SwitchFrame ����, ���� �޴� ǥ�� �Ұ�")
		end
	end)
	if not success then warn("GuiManager: IntroManager.PlayIntroAnimation ���� �� ����!", err) end
else
	warn("GuiManager: IntroManager, LoadingManager, �Ǵ� CoreUIManager �� �ε���� �ʾ� ���� ���� �帧�� ������ �� �����ϴ�.")
	if CoreUIManager and CoreUIManager.SwitchFrame then CoreUIManager.SwitchFrame("MainMenu") else warn("GuiManager: ���� �޴� ǥ�� �Ұ� (CoreUIManager ����)") end
end
print("GuiManager: 7�ܰ� - ���� ���� �帧 ���۵�")

-- *** �̺�Ʈ ������ ���� ***
print("GuiManager: �̺�Ʈ ������ ���� ����")
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
else warn("GuiManager: inventoryUpdatedEvent ����") end

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
else warn("GuiManager: playerStatsUpdatedEvent ����") end

if SkillLearnedEvent then SkillLearnedEvent.OnClientEvent:Connect(function(learnedSkillId) if SkillShopUIManager and SkillShopUIManager.OnSkillLearned then pcall(SkillShopUIManager.OnSkillLearned, SkillShopUIManager, learnedSkillId) end end) else warn("GuiManager: SkillLearnedEvent ����") end
if combatEndedClientEvent then combatEndedClientEvent.OnClientEvent:Connect(function() print("[GuiManager] ���� �����."); if MapManager and MapManager.ShowMapFrame then pcall(MapManager.ShowMapFrame, true) else warn("[GuiManager] MapManager.ShowMapFrame ����"); if CoreUIManager then CoreUIManager.SwitchFrame("MainMenu") end end; if MobileControlsManager and MobileControlsManager.ShowControls then pcall(MobileControlsManager.ShowControls, true) end end) else warn("GuiManager: combatEndedClientEvent ����") end

if NotifyPlayerEvent then
	NotifyPlayerEvent.OnClientEvent:Connect(function(notificationType, data)
		print(string.format("DEBUG: Ŭ���̾�Ʈ: NotifyPlayerEvent ����! Ÿ��: %s", tostring(notificationType)))
		if data then
			local dataType = type(data)
			local dataStr = tostring(data)
			if dataType == "table" then
				local parts = {}
				for k, v in pairs(data) do table.insert(parts, string.format("%s=%s", tostring(k), tostring(v))) end
				dataStr = "{" .. table.concat(parts, ", ") .. "}"
			end
			print(string.format("DEBUG: Ŭ���̾�Ʈ: ���� ������ (%s): %s", dataType, dataStr))
		end

		local handled = false -- �˾� �˸��� ó���Ǿ����� ����

		if notificationType == "PurchaseFailed" then
			if PurchaseNotifications and data and data.reason == "NotEnoughGold" then
				print("DEBUG: Ŭ���̾�Ʈ: PurchaseNotifications.ShowNotEnoughGold ȣ�� �õ�")
				pcall(PurchaseNotifications.ShowNotEnoughGold, PurchaseNotifications)
				handled = true
			end
		elseif notificationType == "ItemPurchased" then
			if PurchaseNotifications and data and data.itemName then
				print(string.format("DEBUG: Ŭ���̾�Ʈ: PurchaseNotifications.ShowItemPurchased ȣ�� �õ� - �����۸�: %s", data.itemName))
				pcall(PurchaseNotifications.ShowItemPurchased, PurchaseNotifications, data.itemName)
				handled = true
			end
		elseif notificationType == "EnhancementResult" then
			if EnhancementNotifications and data then
				if data.success and data.itemName and data.newLevel then
					print(string.format("DEBUG: Ŭ���̾�Ʈ: EnhancementNotifications.ShowEnhancementSuccess ȣ�� �õ� - ������: %s, ����: %s", tostring(data.itemName), tostring(data.newLevel)))
					local successCall, errCall = pcall(EnhancementNotifications.ShowEnhancementSuccess, data.itemName, data.newLevel) 
					if not successCall then warn("Error calling ShowEnhancementSuccess:", errCall) end
					handled = true 
				elseif not data.success and data.itemName and data.reason then
					print(string.format("DEBUG: Ŭ���̾�Ʈ: EnhancementNotifications.ShowEnhancementFailed ȣ�� �õ� - ������: %s, ����: %s", tostring(data.itemName), tostring(data.reason)))
					local successCall, errCall = pcall(EnhancementNotifications.ShowEnhancementFailed, data.itemName, data.reason)
					if not successCall then warn("Error calling ShowEnhancementFailed:", errCall) end
					handled = true 
				else
					print("DEBUG: Ŭ���̾�Ʈ: EnhancementResult ������ �ʵ� ���� �Ǵ� success �� ����ġ (�˾���)")
				end
			else
				print("DEBUG: Ŭ���̾�Ʈ: EnhancementNotifications ��� �Ǵ� ������ ���� (�˾���)")
			end

			-- ��ȭ â UI ������Ʈ (EnhancementUIManager ��� ȣ��)
			if EnhancementUIManager and EnhancementUIManager.HandleEnhancementResult then
				print("DEBUG: Ŭ���̾�Ʈ: GuiManager���� EnhancementUIManager.HandleEnhancementResult ȣ�� �õ� (data):", data)
				local uiUpdateSuccess, uiUpdateErr = pcall(EnhancementUIManager.HandleEnhancementResult, data) 
				if not uiUpdateSuccess then 
					warn("Error calling EnhancementUIManager.HandleEnhancementResult:", uiUpdateErr) 
				else
					print("DEBUG: Ŭ���̾�Ʈ: GuiManager���� EnhancementUIManager.HandleEnhancementResult ȣ�� ����")
				end
			else
				print("DEBUG: Ŭ���̾�Ʈ: EnhancementUIManager �Ǵ� HandleEnhancementResult �Լ� ���� (UI ������Ʈ��)")
				if not EnhancementUIManager then warn("DEBUG: EnhancementUIManager ��� ��ü�� nil�Դϴ�. (GuiManager > NotifyPlayerEvent)") end
				if EnhancementUIManager and not EnhancementUIManager.HandleEnhancementResult then warn("DEBUG: EnhancementUIManager.HandleEnhancementResult �Լ��� nil�Դϴ�. (GuiManager > NotifyPlayerEvent)") end
			end
			-- handled = true; -- �˾��� �̹� handled �÷��׸� �������� ���̹Ƿ�, ���⼭�� UI ������Ʈ�� å����.

		elseif notificationType == "EquipFailed" then
			if CoreUIManager and CoreUIManager.ShowPopupMessage and data and data.reason then
				print("DEBUG: Ŭ���̾�Ʈ: CoreUIManager.ShowPopupMessage ȣ�� �õ� (EquipFailed)")
				pcall(CoreUIManager.ShowPopupMessage, "���� ����", data.reason)
				handled = true
			end
		elseif notificationType == "UnequipFailed" then
			if CoreUIManager and CoreUIManager.ShowPopupMessage and data and data.reason then
				print("DEBUG: Ŭ���̾�Ʈ: CoreUIManager.ShowPopupMessage ȣ�� �õ� (UnequipFailed)")
				pcall(CoreUIManager.ShowPopupMessage, "���� ����", data.reason)
				handled = true
			end
		elseif notificationType == "DevilFruitUseFailed" then
			if CoreUIManager and CoreUIManager.ShowPopupMessage and data and data.reason then
				print("DEBUG: Ŭ���̾�Ʈ: CoreUIManager.ShowPopupMessage ȣ�� �õ� (DevilFruitUseFailed)")
				pcall(CoreUIManager.ShowPopupMessage, "��� �Ұ�", data.reason)
				handled = true
			end
		elseif notificationType == "DevilFruitRemoved" then
			if CoreUIManager and CoreUIManager.ShowPopupMessage and data and data.message then
				print("DEBUG: Ŭ���̾�Ʈ: CoreUIManager.ShowPopupMessage ȣ�� �õ� (DevilFruitRemoved)")
				pcall(CoreUIManager.ShowPopupMessage, "�ɷ� ����", data.message)
				handled = true
			end
		elseif notificationType == "DevilFruitPulled" then
			if CoreUIManager and CoreUIManager.ShowPopupMessage and data and data.message then
				print("DEBUG: Ŭ���̾�Ʈ: CoreUIManager.ShowPopupMessage ȣ�� �õ� (DevilFruitPulled)")
				pcall(CoreUIManager.ShowPopupMessage, "�̱� ���", data.message)
				handled = true
			end
		elseif notificationType == "ActionFailed" then
			if CoreUIManager and CoreUIManager.ShowPopupMessage and data and data.reason then
				print("DEBUG: Ŭ���̾�Ʈ: CoreUIManager.ShowPopupMessage ȣ�� �õ� (ActionFailed)")
				pcall(CoreUIManager.ShowPopupMessage, "����", data.reason)
				handled = true
			end
		elseif notificationType == "PartyUpdateFailed" then
			if CoreUIManager and CoreUIManager.ShowPopupMessage and data and data.reason then
				print("DEBUG: Ŭ���̾�Ʈ: CoreUIManager.ShowPopupMessage ȣ�� �õ� (PartyUpdateFailed)")
				pcall(CoreUIManager.ShowPopupMessage, "��Ƽ ���� ����", data.reason)
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
				local titleText = type(notificationType) == "string" and notificationType or "�˸�"
				print(string.format("DEBUG: Ŭ���̾�Ʈ: CoreUIManager.ShowPopupMessage ȣ�� �õ� (Generic) - ����: %s, ����: %s", titleText, tostring(messageContent)))
				pcall(CoreUIManager.ShowPopupMessage, titleText, tostring(messageContent))
			else
				warn("[GuiManager] CoreUIManager.ShowPopupMessage ����")
			end
		end
	end)
	print("GuiManager: Enhanced NotifyPlayerEvent listener connected.")
else
	warn("GuiManager: NotifyPlayerEvent ����")
end

print("GuiManager: �ʱ�ȭ �� �̺�Ʈ ������ ���� �Ϸ�.")