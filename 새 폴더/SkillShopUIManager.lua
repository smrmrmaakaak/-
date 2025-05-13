--[[
  SkillShopUIManager (ModuleScript)
  스킬 상점 UI 관련 로직 담당
  *** [수정] SetupUIReferences에서 WaitForChild 사용 및 ShowSkillDetails nil 체크 강화 ***
  *** [수정] 등급 시스템 적용: 스킬 목록 및 상세 정보에 등급별 색상 적용 ***
  *** [기능 수정] UI 창 겹침 방지를 위해 CoreUIManager.OpenMainUIPopup 사용 ***
  *** [버그 수정] TooltipManager 참조 추가 ***
]]
local SkillShopUIManager = {}

-- 필요한 서비스 및 모듈 로드
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainGui = playerGui:WaitForChild("MainGui")

local ModuleManager
local CoreUIManager
local PlayerData
local SkillDatabase
local TooltipManager -- ##### TooltipManager 참조 선언 #####
local purchaseSkillEvent
local RequestSkillListEvent
local ReceiveSkillListEvent
local SkillLearnedEvent 

local RATING_COLORS = {
	["Common"] = Color3.fromRGB(180, 180, 180),
	["Uncommon"] = Color3.fromRGB(100, 200, 100),
	["Rare"] = Color3.fromRGB(100, 150, 255),
	["Epic"] = Color3.fromRGB(180, 100, 220),
	["Legendary"] = Color3.fromRGB(255, 165, 0),
}
local DEFAULT_RATING_COLOR = RATING_COLORS["Common"]
local LEARNED_SKILL_COLOR = Color3.fromRGB(150, 255, 150) 

-- UI 요소 참조 변수 (모듈 스코프로 이동 및 skillShopFrame 추가)
local skillShopFrame = nil
local skillList = nil
local detailsFrame = nil
local skillNameLabel = nil
local skillDescriptionLabel = nil
local skillPriceLabel = nil
local learnButton = nil
local closeButton = nil -- ButtonHandler에서 처리하므로 직접적인 이벤트 연결은 제거될 수 있음
local playerGoldLabel = nil 

local selectedSkillId = nil 
local learnedSkills = {} 

-- 모듈 초기화
function SkillShopUIManager.Init()
	ModuleManager = require(ReplicatedStorage.Modules:WaitForChild("ModuleManager"))
	CoreUIManager = ModuleManager:GetModule("CoreUIManager")
	PlayerData = ModuleManager:GetModule("PlayerData")
	SkillDatabase = ModuleManager:GetModule("SkillDatabase")
	TooltipManager = ModuleManager:GetModule("TooltipManager") -- ##### TooltipManager 초기화 #####
	purchaseSkillEvent = ReplicatedStorage:WaitForChild("PurchaseSkillEvent")
	RequestSkillListEvent = ReplicatedStorage:WaitForChild("RequestSkillListEvent")
	ReceiveSkillListEvent = ReplicatedStorage:WaitForChild("ReceiveSkillListEvent")
	SkillLearnedEvent = ReplicatedStorage:WaitForChild("SkillLearnedEvent")

	if not TooltipManager then warn("SkillShopUIManager: TooltipManager module failed to load!") end

	if ReceiveSkillListEvent then
		ReceiveSkillListEvent.OnClientEvent:Connect(SkillShopUIManager.OnReceiveSkillList)
		print("SkillShopUIManager: ReceiveSkillListEvent.OnClientEvent connected.")
	else warn("SkillShopUIManager: ReceiveSkillListEvent is nil!") end
	if SkillLearnedEvent then
		SkillLearnedEvent.OnClientEvent:Connect(SkillShopUIManager.OnSkillLearned)
		print("SkillShopUIManager: SkillLearnedEvent.OnClientEvent connected.")
	else warn("SkillShopUIManager: SkillLearnedEvent is nil!") end

	SkillShopUIManager.SetupUIReferences() -- UI 참조 설정
	print("SkillShopUIManager: Initialized (Modules Loaded).")
end

-- UI 요소 참조 설정 함수
function SkillShopUIManager.SetupUIReferences()
	print("SkillShopUIManager.SetupUIReferences: 함수 시작")
	if skillShopFrame then print("SkillShopUIManager.SetupUIReferences: Already setup."); return true end

	if not mainGui then
		local p = Players.LocalPlayer
		local pg = p and p:WaitForChild("PlayerGui")
		mainGui = pg and pg:FindFirstChild("MainGui")
		if not mainGui then
			warn("SkillShopUIManager.SetupUIReferences: MainGui not found even after retry!")
			return false
		end
	end
	local backgroundFrame = mainGui:FindFirstChild("BackgroundFrame")
	if not backgroundFrame then warn("SkillShopUIManager.SetupUIReferences: BackgroundFrame not found!"); return false end

	skillShopFrame = backgroundFrame:FindFirstChild("SkillShopFrame")
	if not skillShopFrame then warn("SkillShopUIManager.SetupUIReferences: SkillShopFrame not found!"); return false end
	print("SkillShopUIManager.SetupUIReferences: SkillShopFrame 찾음")

	skillList = skillShopFrame:WaitForChild("SkillList", 2) 
	detailsFrame = skillShopFrame:WaitForChild("DetailsFrame", 2)
	closeButton = skillShopFrame:WaitForChild("CloseButton", 2) -- ButtonHandler에서 주로 처리

	if not skillList or not detailsFrame or not closeButton then warn("SkillShopUIManager.SetupUIReferences: SkillList, DetailsFrame, or CloseButton not found!"); return false end
	print("SkillShopUIManager.SetupUIReferences: SkillList, DetailsFrame, CloseButton 찾음")

	skillNameLabel = detailsFrame:WaitForChild("SkillNameLabel", 1)
	skillDescriptionLabel = detailsFrame:WaitForChild("SkillDescriptionLabel", 1)
	skillPriceLabel = detailsFrame:WaitForChild("SkillPriceLabel", 1)
	playerGoldLabel = detailsFrame:WaitForChild("PlayerGoldLabel", 1)
	learnButton = detailsFrame:WaitForChild("LearnButton", 1)

	if not skillNameLabel or not skillDescriptionLabel or not skillPriceLabel or not playerGoldLabel or not learnButton then
		warn("SkillShopUIManager.SetupUIReferences: One or more elements inside DetailsFrame not found! Check GuiBuilder names.")
		return false 
	end
	print("SkillShopUIManager.SetupUIReferences: 모든 내부 요소 찾음, 버튼 이벤트 연결 시도")

	-- ButtonHandler.lua에서 닫기 버튼 이벤트를 중앙에서 관리하므로, 여기서 직접 연결하는 코드는 제거하거나 주석 처리.
	-- if closeButton and not closeButton:FindFirstChild("ClickConnectionMarker_SkillShop") then
	-- 	closeButton.MouseButton1Click:Connect(function() SkillShopUIManager.ShowSkillShop(false) end)
	-- 	local marker = Instance.new("BoolValue"); marker.Name = "ClickConnectionMarker_SkillShop"; marker.Parent = closeButton
	-- end
	if learnButton and not learnButton:FindFirstChild("ClickConnectionMarker_LearnSkill") then
		learnButton.MouseButton1Click:Connect(SkillShopUIManager.LearnSelectedSkill)
		local marker = Instance.new("BoolValue"); marker.Name = "ClickConnectionMarker_LearnSkill"; marker.Parent = learnButton
	end

	print("SkillShopUIManager: UI References Setup Completed.")
	return true 
end

-- ##### [기능 수정] ShowSkillShop 함수에서 CoreUIManager.OpenMainUIPopup 사용 #####
function SkillShopUIManager.ShowSkillShop(show)
	print("SkillShopUIManager.ShowSkillShop: 함수 시작, show =", show)
	if not skillShopFrame or not detailsFrame then -- skillShopFrame 참조 확인
		if not SkillShopUIManager.SetupUIReferences() then
			warn("SkillShopUIManager.ShowSkillShop: UI 참조 설정 최종 실패!")
			return
		end
		if not skillShopFrame then -- 재확인
			warn("SkillShopUIManager.ShowSkillShop: skillShopFrame is still nil after setup attempt.")
			return
		end
	end

	if not CoreUIManager then
		warn("SkillShopUIManager.ShowSkillShop: CoreUIManager not loaded!")
		if skillShopFrame then skillShopFrame.Visible = show end -- Fallback
		return
	end

	if show then
		CoreUIManager.OpenMainUIPopup("SkillShopFrame") -- 다른 주요 팝업 닫고 스킬 상점 열기
		print("SkillShopUIManager: Showing Skill Shop.")
		print("SkillShopUIManager: UpdatePlayerGoldDisplay 호출 시도...")
		SkillShopUIManager.UpdatePlayerGoldDisplay()
		print("SkillShopUIManager: PopulateSkillList 호출 시도...")
		SkillShopUIManager.PopulateSkillList()
		print("SkillShopUIManager: ShowSkillDetails(nil) 호출 시도...")
		SkillShopUIManager.ShowSkillDetails(nil)
	else
		CoreUIManager.ShowFrame("SkillShopFrame", false) -- 단순히 스킬 상점 닫기
		print("SkillShopUIManager: Hiding Skill Shop.")
		if TooltipManager and TooltipManager.HideTooltip then 
			TooltipManager.HideTooltip()
		end
	end
	print("SkillShopUIManager: 스킬 상점 표시/숨김 처리 완료 =", show)
end
-- #######################################################################

function SkillShopUIManager.UpdatePlayerGoldDisplay()
	print("SkillShopUIManager.UpdatePlayerGoldDisplay: 함수 시작")
	if not playerGoldLabel then -- playerGoldLabel은 SetupUIReferences에서 설정됨
		if not SkillShopUIManager.SetupUIReferences() or not playerGoldLabel then -- 참조가 없으면 재시도 및 확인
			warn("SkillShopUIManager.UpdatePlayerGoldDisplay: playerGoldLabel is nil!")
			return
		end
	end
	if not PlayerData then warn("SkillShopUIManager.UpdatePlayerGoldDisplay: PlayerData module not available!"); return end

	local stats = PlayerData.GetStats(player)
	if stats and playerGoldLabel then
		playerGoldLabel.Text = "보유 골드: " .. (stats.Gold or 0) .. " G"
		print("SkillShopUIManager.UpdatePlayerGoldDisplay: 골드 업데이트 완료:", playerGoldLabel.Text)
	elseif playerGoldLabel then
		warn("SkillShopUIManager: Failed to get player stats for gold display.")
		playerGoldLabel.Text = "보유 골드: ? G"
	end
end

function SkillShopUIManager.PopulateSkillList()
	print("SkillShopUIManager.PopulateSkillList: 함수 시작")
	if not skillList then -- skillList는 SetupUIReferences에서 설정됨
		if not SkillShopUIManager.SetupUIReferences() or not skillList then
			warn("SkillShopUIManager.PopulateSkillList: SkillList is nil after setup attempt.")
			return
		end
	end
	if not SkillDatabase or not SkillDatabase.Skills then
		warn("SkillShopUIManager.PopulateSkillList: SkillDatabase not available.")
		return
	end
	print("SkillShopUIManager.PopulateSkillList: 필요한 요소 확인 완료")

	for _, child in ipairs(skillList:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
	print("SkillShopUIManager.PopulateSkillList: 기존 버튼 제거 완료")

	if RequestSkillListEvent then
		print("SkillShopUIManager.PopulateSkillList: 서버에 스킬 목록 요청 이벤트 발동...")
		RequestSkillListEvent:FireServer()
		print("SkillShopUIManager.PopulateSkillList: 요청 이벤트 발동 완료.")
	else warn("SkillShopUIManager.PopulateSkillList: RequestSkillListEvent not found!") end
end

function SkillShopUIManager.OnReceiveSkillList(receivedSkills)
	print("SkillShopUIManager.OnReceiveSkillList: 서버로부터 스킬 목록 수신:", receivedSkills)
	if not skillList then 
		if not SkillShopUIManager.SetupUIReferences() or not skillList then 
			warn("SkillShopUIManager.OnReceiveSkillList: SkillList is nil.")
			return 
		end 
	end
	if not SkillDatabase or not SkillDatabase.Skills then warn("SkillShopUIManager.OnReceiveSkillList: SkillDatabase not available."); return end

	if typeof(receivedSkills) ~= "table" then warn("SkillShopUIManager.OnReceiveSkillList: Invalid skill data received."); receivedSkills = {} end
	learnedSkills = receivedSkills
	print("SkillShopUIManager.OnReceiveSkillList: 클라이언트 측 배운 스킬 목록 업데이트 완료:", learnedSkills)
	for _, child in ipairs(skillList:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
	local order = 1; local numSkills = 0;
	for skillId, skillData in pairs(SkillDatabase.Skills) do
		if skillData.Price and skillData.Price > 0 then
			numSkills = numSkills + 1;
			local skillButton = Instance.new("TextButton");
			skillButton.Name = "SkillEntry_" .. skillId;
			skillButton.Text = skillData.Name;
			skillButton.Size = UDim2.new(1, -10, 0, 30);
			skillButton.BackgroundColor3 = Color3.fromRGB(70, 70, 90);
			skillButton.Font = Enum.Font.SourceSansBold; 
			skillButton.TextScaled = true; 
			skillButton.LayoutOrder = order;
			skillButton.Parent = skillList;

			local rating = skillData.Rating or "Common"
			local ratingColor = RATING_COLORS[rating] or DEFAULT_RATING_COLOR
			local isLearned = false; for _, learnedId in ipairs(learnedSkills) do if learnedId == skillId then isLearned = true; break end end

			if isLearned then
				skillButton.TextColor3 = LEARNED_SKILL_COLOR; 
				skillButton.Selectable = false
			else
				skillButton.TextColor3 = ratingColor;
				skillButton.MouseButton1Click:Connect(function() SkillShopUIManager.ShowSkillDetails(skillId) end)
			end
			order = order + 1
		end
	end
	print("SkillShopUIManager.OnReceiveSkillList: 스킬 버튼 생성 완료")
	local listLayout = skillList:FindFirstChildOfClass("UIListLayout"); if listLayout then local itemHeight = 30; local padding = listLayout.Padding.Offset; local totalHeight = numSkills * itemHeight + math.max(0, numSkills - 1) * padding + padding * 2; skillList.CanvasSize = UDim2.new(0, 0, 0, totalHeight); print("SkillShopUIManager.OnReceiveSkillList: CanvasSize 업데이트:", skillList.CanvasSize) end
	print("SkillShopUIManager: Skill list UI updated after receiving from server.")
end

function SkillShopUIManager.ShowSkillDetails(skillId)
	print("SkillShopUIManager.ShowSkillDetails: 함수 시작, SkillID:", skillId)
	if not (detailsFrame and skillNameLabel and skillDescriptionLabel and skillPriceLabel and learnButton) then -- 참조 확인
		if not SkillShopUIManager.SetupUIReferences() or not (detailsFrame and skillNameLabel and skillDescriptionLabel and skillPriceLabel and learnButton) then
			warn("SkillShopUIManager.ShowSkillDetails: 필요한 UI 요소 참조가 설정되지 않았습니다. (재시도 후)")
			return
		end
	end
	print("SkillShopUIManager.ShowSkillDetails: 필요한 요소 확인 완료")

	selectedSkillId = skillId
	local skillData = skillId and SkillDatabase and SkillDatabase.Skills[skillId] or nil

	if skillData then
		print("SkillShopUIManager.ShowSkillDetails: 표시할 스킬 정보:", skillData)
		local rating = skillData.Rating or "Common"
		local ratingColor = RATING_COLORS[rating] or DEFAULT_RATING_COLOR

		if skillNameLabel then
			skillNameLabel.Text = skillData.Name or "스킬 이름"
			skillNameLabel.TextColor3 = ratingColor
		else warn("skillNameLabel is nil") end

		if skillDescriptionLabel then skillDescriptionLabel.Text = skillData.Description or "스킬 설명" else warn("skillDescriptionLabel is nil") end
		if skillPriceLabel then skillPriceLabel.Text = "가격: " .. (skillData.Price or 0) .. " G" else warn("skillPriceLabel is nil") end

		local isLearned = false; for _, learnedId in ipairs(learnedSkills) do if learnedId == skillId then isLearned = true; break end end
		local stats = PlayerData.GetStats(player); local canAfford = stats and skillData.Price and stats.Gold >= skillData.Price

		if learnButton then
			if isLearned then learnButton.Text = "습득 완료"; learnButton.Selectable = false; learnButton.BackgroundColor3 = Color3.fromRGB(100, 150, 100)
			elseif not canAfford then learnButton.Text = "골드 부족"; learnButton.Selectable = false; learnButton.BackgroundColor3 = Color3.fromRGB(150, 100, 100)
			else learnButton.Text = "배우기"; learnButton.Selectable = true; learnButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100) end
			learnButton.Visible = true
		else warn("learnButton is nil") end

		if detailsFrame then detailsFrame.Visible = true end
		print("SkillShopUIManager.ShowSkillDetails: 스킬 상세 정보 표시 완료")
	else
		print("SkillShopUIManager.ShowSkillDetails: 유효하지 않은 skillId 또는 데이터 없음, UI 초기화")
		selectedSkillId = nil
		if skillNameLabel then
			skillNameLabel.Text = "스킬 선택"
			skillNameLabel.TextColor3 = Color3.new(1,1,1) 
		end
		if skillDescriptionLabel then skillDescriptionLabel.Text = "목록에서 스킬을 선택하세요." end
		if skillPriceLabel then skillPriceLabel.Text = "가격: -" end
		if learnButton then learnButton.Text = "배우기"; learnButton.Selectable = false; learnButton.BackgroundColor3 = Color3.fromRGB(120, 120, 120); learnButton.Visible = false end
		if detailsFrame then detailsFrame.Visible = true end
	end
end

function SkillShopUIManager.LearnSelectedSkill()
	if not selectedSkillId then warn("SkillShopUIManager.LearnSelectedSkill: No skill selected!"); return end
	if not purchaseSkillEvent then warn("SkillShopUIManager.LearnSelectedSkill: purchaseSkillEvent is nil!"); return end
	print("SkillShopUIManager: Requesting to learn skill ID:", selectedSkillId)
	purchaseSkillEvent:FireServer(selectedSkillId)
end

function SkillShopUIManager.OnSkillLearned(learnedSkillId)
	print("SkillShopUIManager.OnSkillLearned: Received confirmation for learning skill ID:", learnedSkillId)
	table.insert(learnedSkills, learnedSkillId)
	if skillList then
		local skillButton = skillList:FindFirstChild("SkillEntry_" .. learnedSkillId)
		if skillButton and skillButton:IsA("TextButton") then
			skillButton.TextColor3 = LEARNED_SKILL_COLOR;
			skillButton.Selectable = false
			if selectedSkillId == learnedSkillId then SkillShopUIManager.ShowSkillDetails(learnedSkillId) end
		end
	end
	SkillShopUIManager.UpdatePlayerGoldDisplay()
end

function SkillShopUIManager.OnPlayerStatsUpdated()
	if skillShopFrame and skillShopFrame.Visible then
		print("SkillShopUIManager: Player stats updated, refreshing gold display.")
		SkillShopUIManager.UpdatePlayerGoldDisplay()
	end
end

return SkillShopUIManager