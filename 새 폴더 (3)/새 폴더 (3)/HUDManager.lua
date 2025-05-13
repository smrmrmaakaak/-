--[[
  HUDManager (ModuleScript)
  �÷��̾� HUD UI ��� ������Ʈ�� ����ϴ� ��� (Ŭ���̾�Ʈ ��).
  *** [����] �ʱ� 10�ʰ� �ֱ��� HUD ������Ʈ �߰� ***
  *** [���� ����] SetupHUDListenersAndRefresh���� �� ValueObject�� WaitForChild �����Ͽ� ���� ���� ���� �ذ� �õ� ***
]]
local HUDManager = {}

-- �ʿ��� ���� �� ��� �ε�
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local player = Players.LocalPlayer

local ModuleManager
local CoreUIManager -- HUD UI ��� ������Ʈ �Լ� ȣ���
local PlayerData -- Ŭ���̾�Ʈ �� GetStats ȣ���

local playerHUD = nil -- PlayerHUD Frame ����

-- ��� �ʱ�ȭ
function HUDManager.Init()
	ModuleManager = require(ReplicatedStorage.Modules:WaitForChild("ModuleManager"))
	CoreUIManager = ModuleManager:GetModule("CoreUIManager")
	PlayerData = ModuleManager:GetModule("PlayerData")
	print("HUDManager: Initialized.")

	-- �ʱ� HUD ������Ʈ �õ� (�񵿱������� PlayerStats ���� ��ٸ�)
	HUDManager.SetupHUDListenersAndRefresh()
end

-- HUD ������Ʈ �Լ� (���� ����)
function HUDManager.RefreshHUD()
	if not CoreUIManager or not PlayerData then warn("HUDManager: RefreshHUD - CoreUIManager �Ǵ� PlayerData ��� ��� �Ұ�"); return end
	if not playerHUD then local mainGui = player:FindFirstChild("PlayerGui") and player.PlayerGui:FindFirstChild("MainGui"); local backgroundFrame = mainGui and mainGui:FindFirstChild("BackgroundFrame"); playerHUD = backgroundFrame and backgroundFrame:FindFirstChild("PlayerHUD"); if not playerHUD then return end end
	local statsFolder = player:FindFirstChild(PlayerData.STATS_FOLDER_NAME); if not statsFolder then return end
	local currentStats = PlayerData.GetStats(player); if currentStats then CoreUIManager.UpdatePlayerHUD(currentStats) else warn("HUDManager: refreshHUD - GetStats ȣ�� ����") end
end

-- PlayerStats ���� �� Value ��ü ������ ����, �ʱ� HUD ���� (������: WaitForChild ���)
function HUDManager.SetupHUDListenersAndRefresh()
	task.spawn(function()
		print("HUDManager: SetupHUDListenersAndRefresh ������ ����")
		while not PlayerData do print("HUDManager: Waiting for PlayerData module..."); task.wait(0.5) end
		local statsFolderName = PlayerData.STATS_FOLDER_NAME
		if not statsFolderName then warn("HUDManager: PlayerData ��⿡�� STATS_FOLDER_NAME �� ã�� �� �����ϴ�."); return end

		-- PlayerHUD Frame ���� ����
		local mainGui = player:WaitForChild("PlayerGui"):WaitForChild("MainGui")
		local backgroundFrame = mainGui:WaitForChild("BackgroundFrame")
		playerHUD = backgroundFrame:WaitForChild("PlayerHUD")
		if not playerHUD then warn("HUDManager: SetupHUDListenersAndRefresh - PlayerHUD �������� ã�� �� �����ϴ�!"); return end
		print("HUDManager: PlayerHUD ������ ���� ���� �Ϸ�.")

		-- PlayerStats ���� Ȯ�� (������ ����)
		local statsFolder = player:WaitForChild(statsFolderName, 30)
		if not statsFolder then warn("HUDManager: PlayerStats ������ ã�� �� ���� HUD �����ʸ� ������ �� �����ϴ�."); return end
		print("HUDManager: PlayerStats ���� ã��! HUD ������Ʈ ������ ���� �õ�.")

		-- *** ����: Value ��ü ���� ������ ���� �� WaitForChild ��� ***
		local statsToWatch = {
			"Level", "Exp", "MaxExp", "CurrentHP", "MaxHP", "CurrentMP", "MaxMP", "Gold", -- CurrentHP/MP �߰�
			"STR", "AGI", "INT", "LUK", "StatPoints" -- �⺻ ���� �� ����Ʈ
			-- �Ļ� ���� �� HUD�� ���� ǥ�õ��� �ʴ� ���� �����ص� �� (�ʿ�� �߰�)
		}
		local allListenersConnected = true -- ��� ������ ���� ���� �÷���

		for _, statName in ipairs(statsToWatch) do
			-- �� ValueObject�� ������ ������ �ִ� 10�� ���
			local valueObject = statsFolder:WaitForChild(statName, 10)

			if valueObject and valueObject:IsA("ValueBase") then
				-- ValueObject�� ã���� Changed �̺�Ʈ ����
				valueObject.Changed:Connect(HUDManager.RefreshHUD)
				print("HUDManager: Listener connected for " .. statName)
			else
				-- ������ �ð� �ȿ� ã�� ���ϸ� ��� ���
				warn("HUDManager: Timed out waiting for ValueObject '" .. statName .. "' in PlayerStats folder.")
				allListenersConnected = false -- �ϳ��� �����ϸ� �÷��� false
			end
		end

		if allListenersConnected then
			print("HUDManager: ��� �ʼ� HUD ������ ���� �Ϸ�.")
		else
			warn("HUDManager: �Ϻ� HUD ������ ���� ����.")
		end
		-- *** ���� �� ***

		-- �ʱ� HUD ������Ʈ �õ� (������ ���� ����)
		HUDManager.RefreshHUD()
		print("HUDManager: ������ ���� �� �ʱ� HUD ������Ʈ �õ� �Ϸ�.")

		-- �ʱ� 10�ʰ� �ֱ��� ������Ʈ (���� ����)
		print("HUDManager: �ʱ� 10�ʰ� �ֱ��� HUD ������Ʈ ����...")
		for i = 1, 10 do
			task.wait(1)
			if not player or not player.Parent or not statsFolder or not statsFolder.Parent then print("HUDManager: �ֱ��� ������Ʈ �ߴ� (�÷��̾�/���� ��ȿ���� ����)"); break end
			HUDManager.RefreshHUD()
		end
		print("HUDManager: �ʱ� 10�ʰ� �ֱ��� HUD ������Ʈ ����.")

	end)
end

return HUDManager