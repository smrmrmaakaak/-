-- StatsUIManager.lua (����: �⺻ ���� ���ʽ� ǥ�� ���� ���� �� nil üũ ��ȭ, UI â ��ħ ���� ���� ����)

local StatsUIManager = {}

-- �ʿ��� ���� �� ��� �ε�
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService") -- �ʿ��

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainGui = playerGui:WaitForChild("MainGui") -- mainGui ����

local ModuleManager
local CoreUIManager -- CoreUIManager ���� ����
local PlayerData 
local GuiUtils 
local spendStatPointEvent 

local statPointsValueObject = nil 
local statPointsChangedConnection = nil 

-- UI ��� ���� ���� (��� �������� �̵�)
local statsFrame = nil
local baseStatsFrame = nil
local detailedStatsFrame = nil
local statPointsLabel = nil
local requirementStatsFrame = nil


-- ��� �ʱ�ȭ
function StatsUIManager.Init()
	ModuleManager = require(ReplicatedStorage.Modules:WaitForChild("ModuleManager"))
	CoreUIManager = ModuleManager:GetModule("CoreUIManager") -- CoreUIManager �ʱ�ȭ
	PlayerData = ModuleManager:GetModule("PlayerData")
	GuiUtils = ModuleManager:GetModule("GuiUtils") 
	spendStatPointEvent = ReplicatedStorage:WaitForChild("SpendStatPointEvent")

	StatsUIManager.SetupUIReferences() -- UI ���� ����
	print("StatsUIManager: Initialized (�ű� �ý���).")
	StatsUIManager.SetupStatPointsListener()
end

-- ##### [��� �߰�] UI ������ ������ ���� �Լ� #####
function StatsUIManager.SetupUIReferences()
	if not mainGui then 
		local p = Players.LocalPlayer
		local pg = p and p:WaitForChild("PlayerGui")
		mainGui = pg and pg:FindFirstChild("MainGui")
		if not mainGui then
			warn("StatsUIManager.SetupUIReferences: MainGui not found even after retry!")
			return
		end
	end
	local backgroundFrame = mainGui:FindFirstChild("BackgroundFrame")
	if backgroundFrame then
		statsFrame = backgroundFrame:FindFirstChild("StatsFrame")
		if statsFrame then
			baseStatsFrame = statsFrame:FindFirstChild("BaseStatsFrame")
			detailedStatsFrame = statsFrame:FindFirstChild("DetailedStatsFrame")
			statPointsLabel = statsFrame:FindFirstChild("StatPointsLabel")
			requirementStatsFrame = statsFrame:FindFirstChild("RequirementStatsFrame")
			if not (baseStatsFrame and detailedStatsFrame and statPointsLabel and requirementStatsFrame) then
				warn("StatsUIManager.SetupUIReferences: StatsFrame ���� �Ϻ� ��� ����!")
			end
		else
			warn("StatsUIManager.SetupUIReferences: StatsFrame not found!")
		end
	else
		warn("StatsUIManager.SetupUIReferences: BackgroundFrame not found!")
	end
end
-- #################################################

-- StatPoints �� ���� ������ ���� �Լ�
function StatsUIManager.SetupStatPointsListener()
	task.spawn(function()
		while not PlayerData do print("StatsUIManager (Listener): Waiting for PlayerData module..."); task.wait(0.5) end
		local statsFolderName = PlayerData.STATS_FOLDER_NAME
		if not statsFolderName then warn("StatsUIManager.SetupStatPointsListener: PlayerData ��⿡�� STATS_FOLDER_NAME�� ã�� �� �����ϴ�."); return end
		local currentStatsFolder = player:WaitForChild(statsFolderName, 30) -- ������ ���� (statsFolder -> currentStatsFolder)
		if not currentStatsFolder then warn("StatsUIManager: SetupStatPointsListener - PlayerStats ������ ã�� �� �����ϴ�."); return end
		statPointsValueObject = currentStatsFolder:WaitForChild("StatPoints", 10)
		if statPointsValueObject and statPointsValueObject:IsA("ValueBase") then
			print("StatsUIManager: Found StatPoints ValueObject. Current value:", statPointsValueObject.Value)
			if statPointsChangedConnection then statPointsChangedConnection:Disconnect(); statPointsChangedConnection = nil; print("StatsUIManager: Disconnected previous StatPoints listener.") end
			statPointsChangedConnection = statPointsValueObject.Changed:Connect(function(newValue)
				print("StatsUIManager: StatPoints.Changed event fired! New value:", newValue)
				if not statsFrame or not statsFrame.Parent then -- statsFrame ������ ��ȿ���� Ȯ��
					StatsUIManager.SetupUIReferences() -- ���ٸ� �ٽ� ���� �õ�
					if not statsFrame then return end -- �׷��� ������ ����
				end
				if statsFrame.Visible then print("StatsUIManager: StatPoints.Changed ����, ���� â ������Ʈ ȣ��."); StatsUIManager.UpdateStatsDisplay()
				else print("StatsUIManager: StatPoints.Changed ���������� ���� â�� ������ �ʾ� UI ������Ʈ �ǳʶ�.") end
			end)
			print("StatsUIManager: StatPoints �� ���� ������ �����.")
		else warn("StatsUIManager: SetupStatPointsListener - StatPoints Value ��ü�� ã�� �� �����ϴ�.") end
	end)
end


-- ���� ���� ������Ʈ �� ǥ��
function StatsUIManager.UpdateStatsDisplay()
	if not statsFrame or not baseStatsFrame or not detailedStatsFrame or not statPointsLabel or not requirementStatsFrame then -- ������ �ϳ��� ������ ���� �õ�
		StatsUIManager.SetupUIReferences()
		if not (statsFrame and baseStatsFrame and detailedStatsFrame and statPointsLabel and requirementStatsFrame) then
			warn("StatsUIManager.UpdateStatsDisplay: �ʼ� UI ��Ҹ� ã�� �� �����ϴ�. (��õ� ��)")
			return
		end
	end

	if not PlayerData then warn("StatsUIManager.UpdateStatsDisplay: PlayerData ����� �ε���� �ʾҽ��ϴ�!"); return end
	if not GuiUtils then warn("StatsUIManager.UpdateStatsDisplay: GuiUtils ����� �ε���� �ʾҽ��ϴ�!"); return end

	local stats = PlayerData.GetStats(player) 
	if not stats then warn("StatsUIManager: �÷��̾� ���� ������ �������� ���߽��ϴ�."); return end

	local remainingPoints = stats.StatPoints or 0
	statPointsLabel.Text = "���� ����Ʈ: " .. remainingPoints

	local dfLabel = requirementStatsFrame:FindFirstChild("DFLabel"); local swordLabel = requirementStatsFrame:FindFirstChild("SwordLabel"); local gunLabel = requirementStatsFrame:FindFirstChild("GunLabel")
	if dfLabel then dfLabel.Text = "�Ǹ�����: " .. (stats.DF or 0) end
	if swordLabel then swordLabel.Text = "�˼�: " .. (stats.Sword or 0) end
	if gunLabel then gunLabel.Text = "�Ѽ�: " .. (stats.Gun or 0) end

	local baseStatsToUpdate = {"STR", "AGI", "INT", "LUK"}
	for _, statId in ipairs(baseStatsToUpdate) do
		local lineFrame = baseStatsFrame:FindFirstChild(statId .. "Line")
		if lineFrame then
			local valueLabel = lineFrame:FindFirstChild(statId .. "ValueLabel")
			local increaseButton = lineFrame:FindFirstChild("Increase" .. statId .. "Button")

			if valueLabel then
				local baseValue = stats[statId]
				local totalValue = stats["Total" .. statId]
				if baseValue == nil then baseValue = 1 end
				if totalValue == nil then totalValue = baseValue end
				local bonusValue = totalValue - baseValue
				print(string.format("[DEBUG] StatsUI: Updating %s - Base: %s, Total: %s, Bonus: %s", statId, tostring(baseValue), tostring(totalValue), tostring(bonusValue)))
				if bonusValue > 0 then
					valueLabel.Text = string.format("%d (+%d)", totalValue, bonusValue)
					valueLabel.TextColor3 = Color3.fromRGB(180, 255, 180)
				else
					valueLabel.Text = tostring(totalValue)
					valueLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
				end
			end
			if increaseButton then increaseButton.Visible = (remainingPoints > 0) end
		else warn("StatsUIManager: "..statId.." Line �������� ã�� �� �����ϴ�.") end
	end

	detailedStatsFrame:ClearAllChildren()
	GuiUtils.CreateTextLabel(detailedStatsFrame, "DetailedTitle", UDim2.new(0.5, 0, 0.03, 0), UDim2.new(0.9, 0, 0.07, 0), "���� �ɷ�ġ", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 16, Color3.fromRGB(200, 220, 220)).LayoutOrder = 0
	local detailYPos = 0.1; local detailYInc = 0.06; local detailXPos = 0.05; local detailWidth = 0.9; local detailHeight = 0.05;
	local function createDetailLabel(name, value, order) local formattedValue = value; if type(value) == "number" then if value ~= math.floor(value) then formattedValue = string.format("%.2f", value) end; if name:find("Rate") or name:find("Bonus") or name:find("Chance") or name:find("Damage") then formattedValue = formattedValue .. "%" end end; local label = GuiUtils.CreateTextLabel(detailedStatsFrame, name .. "DetailLabel", UDim2.new(detailXPos, 0, detailYPos + (order-1) * detailYInc, 0), UDim2.new(detailWidth, 0, detailHeight, 0), string.format("%s: %s", name, formattedValue), Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 12, Color3.fromRGB(210, 210, 210)); label.LayoutOrder = order; return label end
	local detailedStatOrder = {{Name = "�ִ� HP", Key = "MaxHP"}, {Name = "�ִ� MP", Key = "MaxMP"}, {Name = "���� ���ݷ�", Key = "MeleeAttack"}, {Name = "���Ÿ� ���ݷ�", Key = "RangedAttack"}, {Name = "���� ���ݷ�", Key = "MagicAttack"}, {Name = "����", Key = "Defense"}, {Name = "���� ����", Key = "MagicDefense"}, {Name = "���߷�", Key = "AccuracyRate"}, {Name = "ȸ����", Key = "EvasionRate"}, {Name = "ġ��Ÿ Ȯ��", Key = "CritChance"}, {Name = "ġ��Ÿ ������", Key = "CritDamage"}, {Name = "��� ���ʽ�", Key = "DropRateBonus"}, {Name = "����ġ ���ʽ�", Key = "ExpBonus"}, {Name = "��� ���ʽ�", Key = "GoldBonus"}}
	local currentOrder = 1; for _, detailInfo in ipairs(detailedStatOrder) do createDetailLabel(detailInfo.Name, stats[detailInfo.Key] or 0, currentOrder); currentOrder = currentOrder + 1 end
	local cellHeight = 20 ; local padding = 5; local totalHeight = (currentOrder - 1) * cellHeight + math.max(0, currentOrder - 2) * padding + padding * 2
	detailedStatsFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)

	print("StatsUIManager: Stats display updated.")
end

-- ##### [��� ����] ShowStatsFrame �Լ����� CoreUIManager.OpenMainUIPopup ��� #####
function StatsUIManager.ShowStatsFrame(show)
	if not statsFrame then 
		StatsUIManager.SetupUIReferences()
		if not statsFrame then
			warn("StatsUIManager.ShowStatsFrame: StatsFrame is still nil after setup.")
			return
		end
	end
	if not CoreUIManager then 
		warn("StatsUIManager.ShowStatsFrame: CoreUIManager not loaded!")
		if statsFrame then statsFrame.Visible = show end -- Fallback
		return 
	end

	if show then 
		CoreUIManager.OpenMainUIPopup("StatsFrame") -- �ٸ� �ֿ� �˾� �ݰ� ����â ����
		print("StatsUIManager: ���� â ����, ���� ������Ʈ �õ�.")
		StatsUIManager.UpdateStatsDisplay() 
	else 
		CoreUIManager.ShowFrame("StatsFrame", false) -- �ܼ��� ����â �ݱ�
	end
end
-- ########################################################################

-- ���� ���� ��ư Ŭ�� ó�� �Լ�
function StatsUIManager.IncreaseStat(statName)
	if not spendStatPointEvent then warn("StatsUIManager: SpendStatPointEvent not found!"); return end
	if not statName then warn("StatsUIManager.IncreaseStat: statName is nil!"); return end
	print("StatsUIManager: Requesting to spend point on", statName)
	spendStatPointEvent:FireServer(statName)
end

return StatsUIManager