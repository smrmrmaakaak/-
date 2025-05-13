-- LeaderboardUIManager.lua
-- *** [��� ����] UI â ��ħ ������ ���� CoreUIManager.OpenMainUIPopup ��� ***

local LeaderboardUIManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local modulesFolder = ReplicatedStorage:WaitForChild("Modules")

-- �ʿ��� ��� �ε�
local ModuleManager = require(modulesFolder:WaitForChild("ModuleManager"))
local CoreUIManager -- Init �� �ε�
local GuiUtils -- Init �� �ε�

-- RemoteFunction ����
local getLeaderboardDataFunction = nil

-- UI ��� ���� ���� (��� ���̺��� ����� �̹� ��� ��)
-- LeaderboardUIManager.leaderboardFrame = nil -- Init���� SetupUIReferences�� ���� �Ҵ��
-- LeaderboardUIManager.playerListFrame = nil
-- LeaderboardUIManager.playerEntryTemplate = nil

local lastUpdateTime = 0
local refreshInterval = 10 
local isLeaderboardVisible = false
local mainGui = nil -- mainGui ������ ���� ��� ������ ����

-- ��� �ʱ�ȭ
function LeaderboardUIManager.Init()
	CoreUIManager = ModuleManager:GetModule("CoreUIManager")
	GuiUtils = ModuleManager:GetModule("GuiUtils")
	getLeaderboardDataFunction = ReplicatedStorage:WaitForChild("GetLeaderboardDataFunction")

	if not getLeaderboardDataFunction then
		warn("LeaderboardUIManager: GetLeaderboardDataFunction RemoteFunction�� ã�� �� �����ϴ�!")
	end

	-- mainGui ���� �ʱ�ȭ
	local player = Players.LocalPlayer
	local playerGui = player and player:WaitForChild("PlayerGui")
	mainGui = playerGui and playerGui:FindFirstChild("MainGui")
	if not mainGui then
		warn("LeaderboardUIManager.Init: MainGui�� ã�� �� �����ϴ�!")
	end

	LeaderboardUIManager.SetupUIReferences() -- UI ���� ����

	print("LeaderboardUIManager: Initialized.")

	RunService.Heartbeat:Connect(function(deltaTime)
		if isLeaderboardVisible then
			lastUpdateTime = lastUpdateTime + deltaTime
			if lastUpdateTime >= refreshInterval then
				LeaderboardUIManager.RefreshLeaderboard()
				lastUpdateTime = 0
			end
		else
			lastUpdateTime = 0
		end
	end)
end

-- UI ��� ���� ����
function LeaderboardUIManager.SetupUIReferences()
	if LeaderboardUIManager.leaderboardFrame and LeaderboardUIManager.playerListFrame and LeaderboardUIManager.playerEntryTemplate then -- �̹� �����Ǿ����� Ȯ��
		print("LeaderboardUIManager.SetupUIReferences: �̹� ������.")
		return true 
	end
	print("LeaderboardUIManager.SetupUIReferences: UI ���� ���� �õ�...")

	if not mainGui then -- mainGui�� ������ nil�̸� �ٽ� �õ�
		local player = Players.LocalPlayer
		local playerGui = player and player:WaitForChild("PlayerGui")
		mainGui = playerGui and playerGui:FindFirstChild("MainGui")
		if not mainGui then
			warn("LeaderboardUIManager.SetupUIReferences: MainGui�� ��õ� �Ŀ��� ã�� �� �����ϴ�!")
			return false
		end
	end

	local backgroundFrame = mainGui:FindFirstChild("BackgroundFrame")
	if not backgroundFrame then
		warn("LeaderboardUIManager.SetupUIReferences: BackgroundFrame�� ã�� �� �����ϴ�!")
		return false
	end

	LeaderboardUIManager.leaderboardFrame = backgroundFrame:FindFirstChild("LeaderboardFrame")

	if LeaderboardUIManager.leaderboardFrame then
		print("LeaderboardUIManager.SetupUIReferences: LeaderboardFrame ã��.")
		LeaderboardUIManager.playerListFrame = LeaderboardUIManager.leaderboardFrame:FindFirstChild("PlayerListFrame")
		if LeaderboardUIManager.playerListFrame then
			LeaderboardUIManager.playerListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
			LeaderboardUIManager.playerListFrame.CanvasSize = UDim2.new(0,0,0,0)
		end
		LeaderboardUIManager.playerEntryTemplate = LeaderboardUIManager.playerListFrame and LeaderboardUIManager.playerListFrame:FindFirstChild("PlayerEntryTemplate")

		if not LeaderboardUIManager.playerListFrame then warn("LeaderboardUIManager.SetupUIReferences: PlayerListFrame ����!") end
		if not LeaderboardUIManager.playerEntryTemplate then warn("LeaderboardUIManager.SetupUIReferences: PlayerEntryTemplate ����!") end

		if not (LeaderboardUIManager.playerListFrame and LeaderboardUIManager.playerEntryTemplate) then
			warn("LeaderboardUIManager: �������� ���� UI ��Ҹ� ã�� �� �����ϴ�! LeaderboardUIBuilder Ȯ�� �ʿ�.")
			LeaderboardUIManager.leaderboardFrame = nil; return false
		end
		print("LeaderboardUIManager: UI ���� ���� �Ϸ�.")
		return true
	else
		warn("LeaderboardUIManager: LeaderboardFrame�� ã�� �� �����ϴ�!"); return false
	end
end

-- �������� ������ ä���
function LeaderboardUIManager.PopulateLeaderboard(leaderboardData)
	if not LeaderboardUIManager.playerListFrame or not LeaderboardUIManager.playerEntryTemplate then
		warn("LeaderboardUIManager.PopulateLeaderboard: UI ��� ������ �������� �ʾҽ��ϴ�.")
		if not LeaderboardUIManager.SetupUIReferences() then return end
	end
	if not LeaderboardUIManager.playerListFrame or not LeaderboardUIManager.playerEntryTemplate then
		warn("LeaderboardUIManager.PopulateLeaderboard: playerListFrame �Ǵ� playerEntryTemplate ������ ������ nil�Դϴ�.")
		return
	end

	print("[DEBUG] LeaderboardUIManager: PopulateLeaderboard ����") 

	for _, child in ipairs(LeaderboardUIManager.playerListFrame:GetChildren()) do
		if child.Name ~= "PlayerEntryTemplate" and not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
	print("[DEBUG] LeaderboardUIManager: ���� �׸� ���� �Ϸ�")

	if not leaderboardData or #leaderboardData == 0 then
		local emptyMsg = LeaderboardUIManager.playerListFrame:FindFirstChild("EmptyMessage")
		if not emptyMsg then
			GuiUtils.CreateTextLabel(LeaderboardUIManager.playerListFrame, "EmptyMessage",
				UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.9, 0, 0, 30),
				"�������� ������ �����ϴ�.", Vector2.new(0.5,0.5), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 14).LayoutOrder = 1
		end
		print("[DEBUG] LeaderboardUIManager: ǥ���� ������ ����, �� �޽��� ǥ��")
		LeaderboardUIManager.playerListFrame.CanvasSize = UDim2.new(0,0,0,50) -- �ּ� ����
		return
	else
		local emptyMsg = LeaderboardUIManager.playerListFrame:FindFirstChild("EmptyMessage")
		if emptyMsg then emptyMsg:Destroy() end
		print("[DEBUG] LeaderboardUIManager: ������ ��:", #leaderboardData)
	end

	table.sort(leaderboardData, function(a,b)
		if a.level == b.level then
			return (a.gold or 0) > (b.gold or 0)
		end
		return a.level > b.level
	end)
	print("[DEBUG] LeaderboardUIManager: ������ ���� �Ϸ�")

	local listLayout = LeaderboardUIManager.playerListFrame:FindFirstChildOfClass("UIListLayout")
	local totalHeight = 0
	local entryHeight = 30 -- PlayerEntryTemplate�� ���� ����
	local padding = listLayout and listLayout.Padding.Offset or 3

	for i, playerDataItem in ipairs(leaderboardData) do
		print(string.format("[DEBUG] LeaderboardUIManager: �׸� %d ���� �� - Player: %s", i, playerDataItem.name))
		local entryClone = LeaderboardUIManager.playerEntryTemplate:Clone()
		entryClone.Name = "PlayerEntry_" .. i
		entryClone.Visible = true
		entryClone.Parent = LeaderboardUIManager.playerListFrame
		if listLayout then entryClone.LayoutOrder = i end

		local goldLabel = entryClone:FindFirstChild("GoldLabel")
		local levelLabel = entryClone:FindFirstChild("LevelLabel")
		local nameLabel = entryClone:FindFirstChild("NameLabel")
		local rankLabel = entryClone:FindFirstChild("RankLabel")

		if goldLabel then goldLabel.Text = string.format("%d G", playerDataItem.gold or 0) else warn(string.format("  [DEBUG] �׸� %d: GoldLabel ã�� �� ����!", i)) end
		if levelLabel then levelLabel.Text = "Lv." .. tostring(playerDataItem.level or 0) else warn(string.format("  [DEBUG] �׸� %d: LevelLabel ã�� �� ����!", i)) end
		if nameLabel then nameLabel.Text = playerDataItem.name or "N/A" else warn(string.format("  [DEBUG] �׸� %d: NameLabel ã�� �� ����!", i)) end
		if rankLabel then rankLabel.Text = tostring(i) else warn(string.format("  [DEBUG] �׸� %d: RankLabel ã�� �� ����!", i)) end
		totalHeight = totalHeight + entryHeight + padding
	end
	if #leaderboardData > 0 then totalHeight = totalHeight - padding end -- ������ �׸� �е� ����
	LeaderboardUIManager.playerListFrame.CanvasSize = UDim2.new(0,0,0,math.max(50, totalHeight))


	task.wait()
	print("LeaderboardUIManager: �������� ä��� �Ϸ�.")
end

-- �������� ���ΰ�ħ
function LeaderboardUIManager.RefreshLeaderboard()
	if not isLeaderboardVisible then
		return
	end

	if not getLeaderboardDataFunction then
		warn("LeaderboardUIManager.RefreshLeaderboard: getLeaderboardDataFunction�� ����� �� �����ϴ�.")
		return
	end
	print("LeaderboardUIManager: �������� ���ΰ�ħ ��...")
	local success, data = pcall(getLeaderboardDataFunction.InvokeServer, getLeaderboardDataFunction)
	if success then
		if typeof(data) == "table" then
			LeaderboardUIManager.PopulateLeaderboard(data)
		else
			warn("LeaderboardUIManager.RefreshLeaderboard: �����κ��� �߸��� ������ ���� ����:", typeof(data))
		end
	else
		warn("LeaderboardUIManager.RefreshLeaderboard: �������� ������ ��û ����:", data)
	end
end

-- ##### [��� ����] ShowLeaderboardUI �Լ����� CoreUIManager.OpenMainUIPopup ��� #####
function LeaderboardUIManager.ShowLeaderboardUI(show)
	if not LeaderboardUIManager.leaderboardFrame then
		if not LeaderboardUIManager.SetupUIReferences() or not LeaderboardUIManager.leaderboardFrame then
			warn("LeaderboardUIManager.ShowLeaderboardUI: UI ���� ���� ���� �Ǵ� leaderboardFrame�� ������ nil, ǥ�� �Ұ�")
			return
		end
	end
	if not CoreUIManager then
		warn("LeaderboardUIManager.ShowLeaderboardUI: CoreUIManager not available!")
		if LeaderboardUIManager.leaderboardFrame then LeaderboardUIManager.leaderboardFrame.Visible = show end -- Fallback
		return
	end

	isLeaderboardVisible = show
	if show then
		CoreUIManager.OpenMainUIPopup("LeaderboardFrame") -- �ٸ� �ֿ� �˾� �ݰ� �������� ����
		lastUpdateTime = 0 
		LeaderboardUIManager.RefreshLeaderboard()
	else
		CoreUIManager.ShowFrame("LeaderboardFrame", false) -- �ܼ��� �������� �ݱ�
		lastUpdateTime = 0 
	end
	print("LeaderboardUIManager: �������� UI ǥ�� ���� ���� ->", show)
end
-- ########################################################################

return LeaderboardUIManager