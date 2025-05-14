--[[
  SkillShopUIManager (ModuleScript)
  ��ų ���� UI ���� ���� ���
  *** [����] SetupUIReferences���� WaitForChild ��� �� ShowSkillDetails nil üũ ��ȭ ***
  *** [����] ��� �ý��� ����: ��ų ��� �� �� ������ ��޺� ���� ���� ***
  *** [��� ����] UI â ��ħ ������ ���� CoreUIManager.OpenMainUIPopup ��� ***
  *** [���� ����] TooltipManager ���� �߰� ***
]]
local SkillShopUIManager = {}

-- �ʿ��� ���� �� ��� �ε�
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainGui = playerGui:WaitForChild("MainGui")

local ModuleManager
local CoreUIManager
local PlayerData
local SkillDatabase
local TooltipManager -- ##### TooltipManager ���� ���� #####
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

-- UI ��� ���� ���� (��� �������� �̵� �� skillShopFrame �߰�)
local skillShopFrame = nil
local skillList = nil
local detailsFrame = nil
local skillNameLabel = nil
local skillDescriptionLabel = nil
local skillPriceLabel = nil
local learnButton = nil
local closeButton = nil -- ButtonHandler���� ó���ϹǷ� �������� �̺�Ʈ ������ ���ŵ� �� ����
local playerGoldLabel = nil 

local selectedSkillId = nil 
local learnedSkills = {} 

-- ��� �ʱ�ȭ
function SkillShopUIManager.Init()
	ModuleManager = require(ReplicatedStorage.Modules:WaitForChild("ModuleManager"))
	CoreUIManager = ModuleManager:GetModule("CoreUIManager")
	PlayerData = ModuleManager:GetModule("PlayerData")
	SkillDatabase = ModuleManager:GetModule("SkillDatabase")
	TooltipManager = ModuleManager:GetModule("TooltipManager") -- ##### TooltipManager �ʱ�ȭ #####
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

	SkillShopUIManager.SetupUIReferences() -- UI ���� ����
	print("SkillShopUIManager: Initialized (Modules Loaded).")
end

-- UI ��� ���� ���� �Լ�
function SkillShopUIManager.SetupUIReferences()
	print("SkillShopUIManager.SetupUIReferences: �Լ� ����")
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
	print("SkillShopUIManager.SetupUIReferences: SkillShopFrame ã��")

	skillList = skillShopFrame:WaitForChild("SkillList", 2) 
	detailsFrame = skillShopFrame:WaitForChild("DetailsFrame", 2)
	closeButton = skillShopFrame:WaitForChild("CloseButton", 2) -- ButtonHandler���� �ַ� ó��

	if not skillList or not detailsFrame or not closeButton then warn("SkillShopUIManager.SetupUIReferences: SkillList, DetailsFrame, or CloseButton not found!"); return false end
	print("SkillShopUIManager.SetupUIReferences: SkillList, DetailsFrame, CloseButton ã��")

	skillNameLabel = detailsFrame:WaitForChild("SkillNameLabel", 1)
	skillDescriptionLabel = detailsFrame:WaitForChild("SkillDescriptionLabel", 1)
	skillPriceLabel = detailsFrame:WaitForChild("SkillPriceLabel", 1)
	playerGoldLabel = detailsFrame:WaitForChild("PlayerGoldLabel", 1)
	learnButton = detailsFrame:WaitForChild("LearnButton", 1)

	if not skillNameLabel or not skillDescriptionLabel or not skillPriceLabel or not playerGoldLabel or not learnButton then
		warn("SkillShopUIManager.SetupUIReferences: One or more elements inside DetailsFrame not found! Check GuiBuilder names.")
		return false 
	end
	print("SkillShopUIManager.SetupUIReferences: ��� ���� ��� ã��, ��ư �̺�Ʈ ���� �õ�")

	-- ButtonHandler.lua���� �ݱ� ��ư �̺�Ʈ�� �߾ӿ��� �����ϹǷ�, ���⼭ ���� �����ϴ� �ڵ�� �����ϰų� �ּ� ó��.
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

-- ##### [��� ����] ShowSkillShop �Լ����� CoreUIManager.OpenMainUIPopup ��� #####
function SkillShopUIManager.ShowSkillShop(show)
	print("SkillShopUIManager.ShowSkillShop: �Լ� ����, show =", show)
	if not skillShopFrame or not detailsFrame then -- skillShopFrame ���� Ȯ��
		if not SkillShopUIManager.SetupUIReferences() then
			warn("SkillShopUIManager.ShowSkillShop: UI ���� ���� ���� ����!")
			return
		end
		if not skillShopFrame then -- ��Ȯ��
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
		CoreUIManager.OpenMainUIPopup("SkillShopFrame") -- �ٸ� �ֿ� �˾� �ݰ� ��ų ���� ����
		print("SkillShopUIManager: Showing Skill Shop.")
		print("SkillShopUIManager: UpdatePlayerGoldDisplay ȣ�� �õ�...")
		SkillShopUIManager.UpdatePlayerGoldDisplay()
		print("SkillShopUIManager: PopulateSkillList ȣ�� �õ�...")
		SkillShopUIManager.PopulateSkillList()
		print("SkillShopUIManager: ShowSkillDetails(nil) ȣ�� �õ�...")
		SkillShopUIManager.ShowSkillDetails(nil)
	else
		CoreUIManager.ShowFrame("SkillShopFrame", false) -- �ܼ��� ��ų ���� �ݱ�
		print("SkillShopUIManager: Hiding Skill Shop.")
		if TooltipManager and TooltipManager.HideTooltip then 
			TooltipManager.HideTooltip()
		end
	end
	print("SkillShopUIManager: ��ų ���� ǥ��/���� ó�� �Ϸ� =", show)
end
-- #######################################################################

function SkillShopUIManager.UpdatePlayerGoldDisplay()
	print("SkillShopUIManager.UpdatePlayerGoldDisplay: �Լ� ����")
	if not playerGoldLabel then -- playerGoldLabel�� SetupUIReferences���� ������
		if not SkillShopUIManager.SetupUIReferences() or not playerGoldLabel then -- ������ ������ ��õ� �� Ȯ��
			warn("SkillShopUIManager.UpdatePlayerGoldDisplay: playerGoldLabel is nil!")
			return
		end
	end
	if not PlayerData then warn("SkillShopUIManager.UpdatePlayerGoldDisplay: PlayerData module not available!"); return end

	local stats = PlayerData.GetStats(player)
	if stats and playerGoldLabel then
		playerGoldLabel.Text = "���� ���: " .. (stats.Gold or 0) .. " G"
		print("SkillShopUIManager.UpdatePlayerGoldDisplay: ��� ������Ʈ �Ϸ�:", playerGoldLabel.Text)
	elseif playerGoldLabel then
		warn("SkillShopUIManager: Failed to get player stats for gold display.")
		playerGoldLabel.Text = "���� ���: ? G"
	end
end

function SkillShopUIManager.PopulateSkillList()
	print("SkillShopUIManager.PopulateSkillList: �Լ� ����")
	if not skillList then -- skillList�� SetupUIReferences���� ������
		if not SkillShopUIManager.SetupUIReferences() or not skillList then
			warn("SkillShopUIManager.PopulateSkillList: SkillList is nil after setup attempt.")
			return
		end
	end
	if not SkillDatabase or not SkillDatabase.Skills then
		warn("SkillShopUIManager.PopulateSkillList: SkillDatabase not available.")
		return
	end
	print("SkillShopUIManager.PopulateSkillList: �ʿ��� ��� Ȯ�� �Ϸ�")

	for _, child in ipairs(skillList:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
	print("SkillShopUIManager.PopulateSkillList: ���� ��ư ���� �Ϸ�")

	if RequestSkillListEvent then
		print("SkillShopUIManager.PopulateSkillList: ������ ��ų ��� ��û �̺�Ʈ �ߵ�...")
		RequestSkillListEvent:FireServer()
		print("SkillShopUIManager.PopulateSkillList: ��û �̺�Ʈ �ߵ� �Ϸ�.")
	else warn("SkillShopUIManager.PopulateSkillList: RequestSkillListEvent not found!") end
end

function SkillShopUIManager.OnReceiveSkillList(receivedSkills)
	print("SkillShopUIManager.OnReceiveSkillList: �����κ��� ��ų ��� ����:", receivedSkills)
	if not skillList then 
		if not SkillShopUIManager.SetupUIReferences() or not skillList then 
			warn("SkillShopUIManager.OnReceiveSkillList: SkillList is nil.")
			return 
		end 
	end
	if not SkillDatabase or not SkillDatabase.Skills then warn("SkillShopUIManager.OnReceiveSkillList: SkillDatabase not available."); return end

	if typeof(receivedSkills) ~= "table" then warn("SkillShopUIManager.OnReceiveSkillList: Invalid skill data received."); receivedSkills = {} end
	learnedSkills = receivedSkills
	print("SkillShopUIManager.OnReceiveSkillList: Ŭ���̾�Ʈ �� ��� ��ų ��� ������Ʈ �Ϸ�:", learnedSkills)
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
	print("SkillShopUIManager.OnReceiveSkillList: ��ų ��ư ���� �Ϸ�")
	local listLayout = skillList:FindFirstChildOfClass("UIListLayout"); if listLayout then local itemHeight = 30; local padding = listLayout.Padding.Offset; local totalHeight = numSkills * itemHeight + math.max(0, numSkills - 1) * padding + padding * 2; skillList.CanvasSize = UDim2.new(0, 0, 0, totalHeight); print("SkillShopUIManager.OnReceiveSkillList: CanvasSize ������Ʈ:", skillList.CanvasSize) end
	print("SkillShopUIManager: Skill list UI updated after receiving from server.")
end

function SkillShopUIManager.ShowSkillDetails(skillId)
	print("SkillShopUIManager.ShowSkillDetails: �Լ� ����, SkillID:", skillId)
	if not (detailsFrame and skillNameLabel and skillDescriptionLabel and skillPriceLabel and learnButton) then -- ���� Ȯ��
		if not SkillShopUIManager.SetupUIReferences() or not (detailsFrame and skillNameLabel and skillDescriptionLabel and skillPriceLabel and learnButton) then
			warn("SkillShopUIManager.ShowSkillDetails: �ʿ��� UI ��� ������ �������� �ʾҽ��ϴ�. (��õ� ��)")
			return
		end
	end
	print("SkillShopUIManager.ShowSkillDetails: �ʿ��� ��� Ȯ�� �Ϸ�")

	selectedSkillId = skillId
	local skillData = skillId and SkillDatabase and SkillDatabase.Skills[skillId] or nil

	if skillData then
		print("SkillShopUIManager.ShowSkillDetails: ǥ���� ��ų ����:", skillData)
		local rating = skillData.Rating or "Common"
		local ratingColor = RATING_COLORS[rating] or DEFAULT_RATING_COLOR

		if skillNameLabel then
			skillNameLabel.Text = skillData.Name or "��ų �̸�"
			skillNameLabel.TextColor3 = ratingColor
		else warn("skillNameLabel is nil") end

		if skillDescriptionLabel then skillDescriptionLabel.Text = skillData.Description or "��ų ����" else warn("skillDescriptionLabel is nil") end
		if skillPriceLabel then skillPriceLabel.Text = "����: " .. (skillData.Price or 0) .. " G" else warn("skillPriceLabel is nil") end

		local isLearned = false; for _, learnedId in ipairs(learnedSkills) do if learnedId == skillId then isLearned = true; break end end
		local stats = PlayerData.GetStats(player); local canAfford = stats and skillData.Price and stats.Gold >= skillData.Price

		if learnButton then
			if isLearned then learnButton.Text = "���� �Ϸ�"; learnButton.Selectable = false; learnButton.BackgroundColor3 = Color3.fromRGB(100, 150, 100)
			elseif not canAfford then learnButton.Text = "��� ����"; learnButton.Selectable = false; learnButton.BackgroundColor3 = Color3.fromRGB(150, 100, 100)
			else learnButton.Text = "����"; learnButton.Selectable = true; learnButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100) end
			learnButton.Visible = true
		else warn("learnButton is nil") end

		if detailsFrame then detailsFrame.Visible = true end
		print("SkillShopUIManager.ShowSkillDetails: ��ų �� ���� ǥ�� �Ϸ�")
	else
		print("SkillShopUIManager.ShowSkillDetails: ��ȿ���� ���� skillId �Ǵ� ������ ����, UI �ʱ�ȭ")
		selectedSkillId = nil
		if skillNameLabel then
			skillNameLabel.Text = "��ų ����"
			skillNameLabel.TextColor3 = Color3.new(1,1,1) 
		end
		if skillDescriptionLabel then skillDescriptionLabel.Text = "��Ͽ��� ��ų�� �����ϼ���." end
		if skillPriceLabel then skillPriceLabel.Text = "����: -" end
		if learnButton then learnButton.Text = "����"; learnButton.Selectable = false; learnButton.BackgroundColor3 = Color3.fromRGB(120, 120, 120); learnButton.Visible = false end
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