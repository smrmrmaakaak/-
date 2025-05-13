-- LeaderboardUIManager.lua
-- *** [기능 수정] UI 창 겹침 방지를 위해 CoreUIManager.OpenMainUIPopup 사용 ***

local LeaderboardUIManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local modulesFolder = ReplicatedStorage:WaitForChild("Modules")

-- 필요한 모듈 로드
local ModuleManager = require(modulesFolder:WaitForChild("ModuleManager"))
local CoreUIManager -- Init 시 로드
local GuiUtils -- Init 시 로드

-- RemoteFunction 참조
local getLeaderboardDataFunction = nil

-- UI 요소 참조 변수 (모듈 테이블의 멤버로 이미 사용 중)
-- LeaderboardUIManager.leaderboardFrame = nil -- Init에서 SetupUIReferences를 통해 할당됨
-- LeaderboardUIManager.playerListFrame = nil
-- LeaderboardUIManager.playerEntryTemplate = nil

local lastUpdateTime = 0
local refreshInterval = 10 
local isLeaderboardVisible = false
local mainGui = nil -- mainGui 참조를 위한 모듈 스코프 변수

-- 모듈 초기화
function LeaderboardUIManager.Init()
	CoreUIManager = ModuleManager:GetModule("CoreUIManager")
	GuiUtils = ModuleManager:GetModule("GuiUtils")
	getLeaderboardDataFunction = ReplicatedStorage:WaitForChild("GetLeaderboardDataFunction")

	if not getLeaderboardDataFunction then
		warn("LeaderboardUIManager: GetLeaderboardDataFunction RemoteFunction을 찾을 수 없습니다!")
	end

	-- mainGui 참조 초기화
	local player = Players.LocalPlayer
	local playerGui = player and player:WaitForChild("PlayerGui")
	mainGui = playerGui and playerGui:FindFirstChild("MainGui")
	if not mainGui then
		warn("LeaderboardUIManager.Init: MainGui를 찾을 수 없습니다!")
	end

	LeaderboardUIManager.SetupUIReferences() -- UI 참조 설정

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

-- UI 요소 참조 설정
function LeaderboardUIManager.SetupUIReferences()
	if LeaderboardUIManager.leaderboardFrame and LeaderboardUIManager.playerListFrame and LeaderboardUIManager.playerEntryTemplate then -- 이미 설정되었는지 확인
		print("LeaderboardUIManager.SetupUIReferences: 이미 설정됨.")
		return true 
	end
	print("LeaderboardUIManager.SetupUIReferences: UI 참조 설정 시도...")

	if not mainGui then -- mainGui가 여전히 nil이면 다시 시도
		local player = Players.LocalPlayer
		local playerGui = player and player:WaitForChild("PlayerGui")
		mainGui = playerGui and playerGui:FindFirstChild("MainGui")
		if not mainGui then
			warn("LeaderboardUIManager.SetupUIReferences: MainGui를 재시도 후에도 찾을 수 없습니다!")
			return false
		end
	end

	local backgroundFrame = mainGui:FindFirstChild("BackgroundFrame")
	if not backgroundFrame then
		warn("LeaderboardUIManager.SetupUIReferences: BackgroundFrame을 찾을 수 없습니다!")
		return false
	end

	LeaderboardUIManager.leaderboardFrame = backgroundFrame:FindFirstChild("LeaderboardFrame")

	if LeaderboardUIManager.leaderboardFrame then
		print("LeaderboardUIManager.SetupUIReferences: LeaderboardFrame 찾음.")
		LeaderboardUIManager.playerListFrame = LeaderboardUIManager.leaderboardFrame:FindFirstChild("PlayerListFrame")
		if LeaderboardUIManager.playerListFrame then
			LeaderboardUIManager.playerListFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
			LeaderboardUIManager.playerListFrame.CanvasSize = UDim2.new(0,0,0,0)
		end
		LeaderboardUIManager.playerEntryTemplate = LeaderboardUIManager.playerListFrame and LeaderboardUIManager.playerListFrame:FindFirstChild("PlayerEntryTemplate")

		if not LeaderboardUIManager.playerListFrame then warn("LeaderboardUIManager.SetupUIReferences: PlayerListFrame 없음!") end
		if not LeaderboardUIManager.playerEntryTemplate then warn("LeaderboardUIManager.SetupUIReferences: PlayerEntryTemplate 없음!") end

		if not (LeaderboardUIManager.playerListFrame and LeaderboardUIManager.playerEntryTemplate) then
			warn("LeaderboardUIManager: 리더보드 내부 UI 요소를 찾을 수 없습니다! LeaderboardUIBuilder 확인 필요.")
			LeaderboardUIManager.leaderboardFrame = nil; return false
		end
		print("LeaderboardUIManager: UI 참조 설정 완료.")
		return true
	else
		warn("LeaderboardUIManager: LeaderboardFrame을 찾을 수 없습니다!"); return false
	end
end

-- 리더보드 데이터 채우기
function LeaderboardUIManager.PopulateLeaderboard(leaderboardData)
	if not LeaderboardUIManager.playerListFrame or not LeaderboardUIManager.playerEntryTemplate then
		warn("LeaderboardUIManager.PopulateLeaderboard: UI 요소 참조가 설정되지 않았습니다.")
		if not LeaderboardUIManager.SetupUIReferences() then return end
	end
	if not LeaderboardUIManager.playerListFrame or not LeaderboardUIManager.playerEntryTemplate then
		warn("LeaderboardUIManager.PopulateLeaderboard: playerListFrame 또는 playerEntryTemplate 참조가 여전히 nil입니다.")
		return
	end

	print("[DEBUG] LeaderboardUIManager: PopulateLeaderboard 시작") 

	for _, child in ipairs(LeaderboardUIManager.playerListFrame:GetChildren()) do
		if child.Name ~= "PlayerEntryTemplate" and not child:IsA("UIListLayout") then
			child:Destroy()
		end
	end
	print("[DEBUG] LeaderboardUIManager: 기존 항목 제거 완료")

	if not leaderboardData or #leaderboardData == 0 then
		local emptyMsg = LeaderboardUIManager.playerListFrame:FindFirstChild("EmptyMessage")
		if not emptyMsg then
			GuiUtils.CreateTextLabel(LeaderboardUIManager.playerListFrame, "EmptyMessage",
				UDim2.new(0.5, 0, 0.5, 0), UDim2.new(0.9, 0, 0, 30),
				"리더보드 정보가 없습니다.", Vector2.new(0.5,0.5), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 14).LayoutOrder = 1
		end
		print("[DEBUG] LeaderboardUIManager: 표시할 데이터 없음, 빈 메시지 표시")
		LeaderboardUIManager.playerListFrame.CanvasSize = UDim2.new(0,0,0,50) -- 최소 높이
		return
	else
		local emptyMsg = LeaderboardUIManager.playerListFrame:FindFirstChild("EmptyMessage")
		if emptyMsg then emptyMsg:Destroy() end
		print("[DEBUG] LeaderboardUIManager: 데이터 수:", #leaderboardData)
	end

	table.sort(leaderboardData, function(a,b)
		if a.level == b.level then
			return (a.gold or 0) > (b.gold or 0)
		end
		return a.level > b.level
	end)
	print("[DEBUG] LeaderboardUIManager: 데이터 정렬 완료")

	local listLayout = LeaderboardUIManager.playerListFrame:FindFirstChildOfClass("UIListLayout")
	local totalHeight = 0
	local entryHeight = 30 -- PlayerEntryTemplate의 예상 높이
	local padding = listLayout and listLayout.Padding.Offset or 3

	for i, playerDataItem in ipairs(leaderboardData) do
		print(string.format("[DEBUG] LeaderboardUIManager: 항목 %d 생성 중 - Player: %s", i, playerDataItem.name))
		local entryClone = LeaderboardUIManager.playerEntryTemplate:Clone()
		entryClone.Name = "PlayerEntry_" .. i
		entryClone.Visible = true
		entryClone.Parent = LeaderboardUIManager.playerListFrame
		if listLayout then entryClone.LayoutOrder = i end

		local goldLabel = entryClone:FindFirstChild("GoldLabel")
		local levelLabel = entryClone:FindFirstChild("LevelLabel")
		local nameLabel = entryClone:FindFirstChild("NameLabel")
		local rankLabel = entryClone:FindFirstChild("RankLabel")

		if goldLabel then goldLabel.Text = string.format("%d G", playerDataItem.gold or 0) else warn(string.format("  [DEBUG] 항목 %d: GoldLabel 찾을 수 없음!", i)) end
		if levelLabel then levelLabel.Text = "Lv." .. tostring(playerDataItem.level or 0) else warn(string.format("  [DEBUG] 항목 %d: LevelLabel 찾을 수 없음!", i)) end
		if nameLabel then nameLabel.Text = playerDataItem.name or "N/A" else warn(string.format("  [DEBUG] 항목 %d: NameLabel 찾을 수 없음!", i)) end
		if rankLabel then rankLabel.Text = tostring(i) else warn(string.format("  [DEBUG] 항목 %d: RankLabel 찾을 수 없음!", i)) end
		totalHeight = totalHeight + entryHeight + padding
	end
	if #leaderboardData > 0 then totalHeight = totalHeight - padding end -- 마지막 항목 패딩 제거
	LeaderboardUIManager.playerListFrame.CanvasSize = UDim2.new(0,0,0,math.max(50, totalHeight))


	task.wait()
	print("LeaderboardUIManager: 리더보드 채우기 완료.")
end

-- 리더보드 새로고침
function LeaderboardUIManager.RefreshLeaderboard()
	if not isLeaderboardVisible then
		return
	end

	if not getLeaderboardDataFunction then
		warn("LeaderboardUIManager.RefreshLeaderboard: getLeaderboardDataFunction을 사용할 수 없습니다.")
		return
	end
	print("LeaderboardUIManager: 리더보드 새로고침 중...")
	local success, data = pcall(getLeaderboardDataFunction.InvokeServer, getLeaderboardDataFunction)
	if success then
		if typeof(data) == "table" then
			LeaderboardUIManager.PopulateLeaderboard(data)
		else
			warn("LeaderboardUIManager.RefreshLeaderboard: 서버로부터 잘못된 데이터 형식 수신:", typeof(data))
		end
	else
		warn("LeaderboardUIManager.RefreshLeaderboard: 리더보드 데이터 요청 실패:", data)
	end
end

-- ##### [기능 수정] ShowLeaderboardUI 함수에서 CoreUIManager.OpenMainUIPopup 사용 #####
function LeaderboardUIManager.ShowLeaderboardUI(show)
	if not LeaderboardUIManager.leaderboardFrame then
		if not LeaderboardUIManager.SetupUIReferences() or not LeaderboardUIManager.leaderboardFrame then
			warn("LeaderboardUIManager.ShowLeaderboardUI: UI 참조 설정 실패 또는 leaderboardFrame이 여전히 nil, 표시 불가")
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
		CoreUIManager.OpenMainUIPopup("LeaderboardFrame") -- 다른 주요 팝업 닫고 리더보드 열기
		lastUpdateTime = 0 
		LeaderboardUIManager.RefreshLeaderboard()
	else
		CoreUIManager.ShowFrame("LeaderboardFrame", false) -- 단순히 리더보드 닫기
		lastUpdateTime = 0 
	end
	print("LeaderboardUIManager: 리더보드 UI 표시 상태 변경 ->", show)
end
-- ########################################################################

return LeaderboardUIManager