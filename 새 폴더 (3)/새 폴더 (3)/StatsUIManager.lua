-- StatsUIManager.lua (수정: 기본 스탯 보너스 표시 로직 수정 및 nil 체크 강화, UI 창 겹침 방지 로직 적용)

local StatsUIManager = {}

-- 필요한 서비스 및 모듈 로드
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService") -- 필요시

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainGui = playerGui:WaitForChild("MainGui") -- mainGui 참조

local ModuleManager
local CoreUIManager -- CoreUIManager 참조 선언
local PlayerData 
local GuiUtils 
local spendStatPointEvent 

local statPointsValueObject = nil 
local statPointsChangedConnection = nil 

-- UI 요소 참조 변수 (모듈 스코프로 이동)
local statsFrame = nil
local baseStatsFrame = nil
local detailedStatsFrame = nil
local statPointsLabel = nil
local requirementStatsFrame = nil


-- 모듈 초기화
function StatsUIManager.Init()
	ModuleManager = require(ReplicatedStorage.Modules:WaitForChild("ModuleManager"))
	CoreUIManager = ModuleManager:GetModule("CoreUIManager") -- CoreUIManager 초기화
	PlayerData = ModuleManager:GetModule("PlayerData")
	GuiUtils = ModuleManager:GetModule("GuiUtils") 
	spendStatPointEvent = ReplicatedStorage:WaitForChild("SpendStatPointEvent")

	StatsUIManager.SetupUIReferences() -- UI 참조 설정
	print("StatsUIManager: Initialized (신규 시스템).")
	StatsUIManager.SetupStatPointsListener()
end

-- ##### [기능 추가] UI 프레임 참조를 위한 함수 #####
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
				warn("StatsUIManager.SetupUIReferences: StatsFrame 내부 일부 요소 없음!")
			end
		else
			warn("StatsUIManager.SetupUIReferences: StatsFrame not found!")
		end
	else
		warn("StatsUIManager.SetupUIReferences: BackgroundFrame not found!")
	end
end
-- #################################################

-- StatPoints 값 변경 리스너 설정 함수
function StatsUIManager.SetupStatPointsListener()
	task.spawn(function()
		while not PlayerData do print("StatsUIManager (Listener): Waiting for PlayerData module..."); task.wait(0.5) end
		local statsFolderName = PlayerData.STATS_FOLDER_NAME
		if not statsFolderName then warn("StatsUIManager.SetupStatPointsListener: PlayerData 모듈에서 STATS_FOLDER_NAME을 찾을 수 없습니다."); return end
		local currentStatsFolder = player:WaitForChild(statsFolderName, 30) -- 변수명 변경 (statsFolder -> currentStatsFolder)
		if not currentStatsFolder then warn("StatsUIManager: SetupStatPointsListener - PlayerStats 폴더를 찾을 수 없습니다."); return end
		statPointsValueObject = currentStatsFolder:WaitForChild("StatPoints", 10)
		if statPointsValueObject and statPointsValueObject:IsA("ValueBase") then
			print("StatsUIManager: Found StatPoints ValueObject. Current value:", statPointsValueObject.Value)
			if statPointsChangedConnection then statPointsChangedConnection:Disconnect(); statPointsChangedConnection = nil; print("StatsUIManager: Disconnected previous StatPoints listener.") end
			statPointsChangedConnection = statPointsValueObject.Changed:Connect(function(newValue)
				print("StatsUIManager: StatPoints.Changed event fired! New value:", newValue)
				if not statsFrame or not statsFrame.Parent then -- statsFrame 참조가 유효한지 확인
					StatsUIManager.SetupUIReferences() -- 없다면 다시 설정 시도
					if not statsFrame then return end -- 그래도 없으면 종료
				end
				if statsFrame.Visible then print("StatsUIManager: StatPoints.Changed 감지, 스탯 창 업데이트 호출."); StatsUIManager.UpdateStatsDisplay()
				else print("StatsUIManager: StatPoints.Changed 감지했으나 스탯 창이 보이지 않아 UI 업데이트 건너뜀.") end
			end)
			print("StatsUIManager: StatPoints 값 변경 리스너 연결됨.")
		else warn("StatsUIManager: SetupStatPointsListener - StatPoints Value 객체를 찾을 수 없습니다.") end
	end)
end


-- 스탯 정보 업데이트 및 표시
function StatsUIManager.UpdateStatsDisplay()
	if not statsFrame or not baseStatsFrame or not detailedStatsFrame or not statPointsLabel or not requirementStatsFrame then -- 참조가 하나라도 없으면 설정 시도
		StatsUIManager.SetupUIReferences()
		if not (statsFrame and baseStatsFrame and detailedStatsFrame and statPointsLabel and requirementStatsFrame) then
			warn("StatsUIManager.UpdateStatsDisplay: 필수 UI 요소를 찾을 수 없습니다. (재시도 후)")
			return
		end
	end

	if not PlayerData then warn("StatsUIManager.UpdateStatsDisplay: PlayerData 모듈이 로드되지 않았습니다!"); return end
	if not GuiUtils then warn("StatsUIManager.UpdateStatsDisplay: GuiUtils 모듈이 로드되지 않았습니다!"); return end

	local stats = PlayerData.GetStats(player) 
	if not stats then warn("StatsUIManager: 플레이어 스탯 정보를 가져오지 못했습니다."); return end

	local remainingPoints = stats.StatPoints or 0
	statPointsLabel.Text = "남은 포인트: " .. remainingPoints

	local dfLabel = requirementStatsFrame:FindFirstChild("DFLabel"); local swordLabel = requirementStatsFrame:FindFirstChild("SwordLabel"); local gunLabel = requirementStatsFrame:FindFirstChild("GunLabel")
	if dfLabel then dfLabel.Text = "악마열매: " .. (stats.DF or 0) end
	if swordLabel then swordLabel.Text = "검술: " .. (stats.Sword or 0) end
	if gunLabel then gunLabel.Text = "총술: " .. (stats.Gun or 0) end

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
		else warn("StatsUIManager: "..statId.." Line 프레임을 찾을 수 없습니다.") end
	end

	detailedStatsFrame:ClearAllChildren()
	GuiUtils.CreateTextLabel(detailedStatsFrame, "DetailedTitle", UDim2.new(0.5, 0, 0.03, 0), UDim2.new(0.9, 0, 0.07, 0), "세부 능력치", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 16, Color3.fromRGB(200, 220, 220)).LayoutOrder = 0
	local detailYPos = 0.1; local detailYInc = 0.06; local detailXPos = 0.05; local detailWidth = 0.9; local detailHeight = 0.05;
	local function createDetailLabel(name, value, order) local formattedValue = value; if type(value) == "number" then if value ~= math.floor(value) then formattedValue = string.format("%.2f", value) end; if name:find("Rate") or name:find("Bonus") or name:find("Chance") or name:find("Damage") then formattedValue = formattedValue .. "%" end end; local label = GuiUtils.CreateTextLabel(detailedStatsFrame, name .. "DetailLabel", UDim2.new(detailXPos, 0, detailYPos + (order-1) * detailYInc, 0), UDim2.new(detailWidth, 0, detailHeight, 0), string.format("%s: %s", name, formattedValue), Vector2.new(0, 0), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 12, Color3.fromRGB(210, 210, 210)); label.LayoutOrder = order; return label end
	local detailedStatOrder = {{Name = "최대 HP", Key = "MaxHP"}, {Name = "최대 MP", Key = "MaxMP"}, {Name = "근접 공격력", Key = "MeleeAttack"}, {Name = "원거리 공격력", Key = "RangedAttack"}, {Name = "마법 공격력", Key = "MagicAttack"}, {Name = "방어력", Key = "Defense"}, {Name = "마법 방어력", Key = "MagicDefense"}, {Name = "명중률", Key = "AccuracyRate"}, {Name = "회피율", Key = "EvasionRate"}, {Name = "치명타 확률", Key = "CritChance"}, {Name = "치명타 데미지", Key = "CritDamage"}, {Name = "드랍 보너스", Key = "DropRateBonus"}, {Name = "경험치 보너스", Key = "ExpBonus"}, {Name = "골드 보너스", Key = "GoldBonus"}}
	local currentOrder = 1; for _, detailInfo in ipairs(detailedStatOrder) do createDetailLabel(detailInfo.Name, stats[detailInfo.Key] or 0, currentOrder); currentOrder = currentOrder + 1 end
	local cellHeight = 20 ; local padding = 5; local totalHeight = (currentOrder - 1) * cellHeight + math.max(0, currentOrder - 2) * padding + padding * 2
	detailedStatsFrame.CanvasSize = UDim2.new(0, 0, 0, totalHeight)

	print("StatsUIManager: Stats display updated.")
end

-- ##### [기능 수정] ShowStatsFrame 함수에서 CoreUIManager.OpenMainUIPopup 사용 #####
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
		CoreUIManager.OpenMainUIPopup("StatsFrame") -- 다른 주요 팝업 닫고 스탯창 열기
		print("StatsUIManager: 스탯 창 열림, 정보 업데이트 시도.")
		StatsUIManager.UpdateStatsDisplay() 
	else 
		CoreUIManager.ShowFrame("StatsFrame", false) -- 단순히 스탯창 닫기
	end
end
-- ########################################################################

-- 스탯 증가 버튼 클릭 처리 함수
function StatsUIManager.IncreaseStat(statName)
	if not spendStatPointEvent then warn("StatsUIManager: SpendStatPointEvent not found!"); return end
	if not statName then warn("StatsUIManager.IncreaseStat: statName is nil!"); return end
	print("StatsUIManager: Requesting to spend point on", statName)
	spendStatPointEvent:FireServer(statName)
end

return StatsUIManager