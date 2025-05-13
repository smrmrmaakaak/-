-- DialogueManager.lua (����: HandleAction �� ��� ����, �� UI ���� �� ��� �ʱ�ȭ, UI â ��ħ ���� ���� ����)

local DialogueManager = {}

-- �ʿ��� ���� �� ��� �ε�
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainGui = playerGui:WaitForChild("MainGui") 

local ModuleManager
local CoreUIManager -- CoreUIManager ���� ����
local DialogueDatabase
local GuiUtils
local MapManager
local ShopUIManager
local CraftingUIManager
local GachaUIManager
local SkillShopUIManager
local MobileControlsManager
local RequestTestFruitEvent
local RequestRemoveDevilFruitEvent
local RequestPullDevilFruitEvent
local EnhancementUIManager
-- local TooltipManager -- �ʿ�� �߰�

local currentDialogueData = nil
local currentNodeId = nil
local dialogueFrame = nil -- ��� �������� �̵�
local npcNameLabel = nil
local dialogueTextLabel = nil
local responseButtonsFrame = nil
local responseButtonTemplate = nil
local npcPortraitImage = nil
local isDialoguePausedForOtherUI = false

local DEFAULT_DIALOGUE_BACKGROUND_IMAGE_ID = "" 

-- ��� �ʱ�ȭ
function DialogueManager.Init()
	ModuleManager = require(ReplicatedStorage.Modules:WaitForChild("ModuleManager"))
	CoreUIManager = ModuleManager:GetModule("CoreUIManager") -- CoreUIManager �ʱ�ȭ
	DialogueDatabase = ModuleManager:GetModule("DialogueDatabase")
	GuiUtils = ModuleManager:GetModule("GuiUtils")
	MapManager = ModuleManager:GetModule("MapManager")
	ShopUIManager = ModuleManager:GetModule("ShopUIManager")
	CraftingUIManager = ModuleManager:GetModule("CraftingUIManager")
	GachaUIManager = ModuleManager:GetModule("GachaUIManager")
	SkillShopUIManager = ModuleManager:GetModule("SkillShopUIManager")
	MobileControlsManager = ModuleManager:GetModule("MobileControlsManager")
	EnhancementUIManager = ModuleManager:GetModule("EnhancementUIManager")
	-- TooltipManager = ModuleManager:GetModule("TooltipManager") -- �ʿ�� �ʱ�ȭ
	RequestTestFruitEvent = ReplicatedStorage:WaitForChild("RequestTestFruitEvent")
	RequestRemoveDevilFruitEvent = ReplicatedStorage:WaitForChild("RequestRemoveDevilFruitEvent")
	RequestPullDevilFruitEvent = ReplicatedStorage:WaitForChild("RequestPullDevilFruitEvent")

	DialogueManager.SetupUIReferences() -- UI ���� ����
	print("DialogueManager: Initialized (Modules Loaded).")
end

-- UI ��� ���� ���� �Լ�
function DialogueManager.SetupUIReferences()
	if dialogueFrame and npcNameLabel then -- �ֿ� ���� ��ҵ� Ȯ��
		print("DialogueManager.SetupUIReferences: Already setup.")
		return 
	end

	if not mainGui then
		local p = Players.LocalPlayer
		local pg = p and p:WaitForChild("PlayerGui")
		mainGui = pg and pg:FindFirstChild("MainGui")
		if not mainGui then
			warn("DialogueManager.SetupUIReferences: MainGui not found!")
			return
		end
	end
	local backgroundFrame = mainGui:FindFirstChild("BackgroundFrame")
	if not backgroundFrame then
		warn("DialogueManager.SetupUIReferences: BackgroundFrame not found!")
		return
	end

	dialogueFrame = backgroundFrame:FindFirstChild("DialogueFrame") -- ��� ������ ������ �Ҵ�
	if dialogueFrame then
		npcNameLabel = dialogueFrame:FindFirstChild("NpcNameLabel")
		dialogueTextLabel = dialogueFrame:FindFirstChild("DialogueTextLabel")
		responseButtonsFrame = dialogueFrame:FindFirstChild("ResponseButtonsFrame")
		npcPortraitImage = dialogueFrame:FindFirstChild("NpcPortraitImage")

		if not (npcNameLabel and dialogueTextLabel and responseButtonsFrame and npcPortraitImage) then
			warn("DialogueManager.SetupUIReferences: DialogueFrame ���� ��Ҹ� ã�� �� �����ϴ�!")
			dialogueFrame = nil; return
		end

		responseButtonTemplate = responseButtonsFrame:FindFirstChild("ResponseButtonTemplate")
		if not responseButtonTemplate then
			responseButtonTemplate = Instance.new("TextButton")
			responseButtonTemplate.Name = "ResponseButtonTemplate"; responseButtonTemplate.Size = UDim2.new(1,0,1,0)
			responseButtonTemplate.BackgroundColor3 = Color3.fromRGB(70,90,130); responseButtonTemplate.TextColor3 = Color3.fromRGB(220,220,255)
			responseButtonTemplate.Font = Enum.Font.SourceSans; responseButtonTemplate.TextSize = 18
			responseButtonTemplate.TextWrapped = true; responseButtonTemplate.Visible = false; responseButtonTemplate.Parent = responseButtonsFrame
			Instance.new("UICorner", responseButtonTemplate).CornerRadius = UDim.new(0,4)
			print("DialogueManager.SetupUIReferences: ResponseButtonTemplate created.")
		end
		print("DialogueManager: UI References Setup Completed.")
	else
		warn("DialogueManager.SetupUIReferences: DialogueFrame�� ã�� �� �����ϴ�!")
	end
end

function DialogueManager.ResetDialogueBackgroundToDefault()
	if not mainGui then return end
	local backgroundFrame = mainGui:FindFirstChild("BackgroundFrame")
	local mainBackgroundImage = backgroundFrame and backgroundFrame:FindFirstChild("MainBackgroundImage")
	if mainBackgroundImage then
		if DEFAULT_DIALOGUE_BACKGROUND_IMAGE_ID and DEFAULT_DIALOGUE_BACKGROUND_IMAGE_ID ~= "" then
			mainBackgroundImage.Image = DEFAULT_DIALOGUE_BACKGROUND_IMAGE_ID
			mainBackgroundImage.Visible = true
			print("DialogueManager: Reset dialogue background to default image.")
		else
			mainBackgroundImage.Image = ""
			mainBackgroundImage.Visible = true 
			print("DialogueManager: Reset dialogue background to empty (BackgroundFrame color will show).")
		end
	else
		warn("DialogueManager: MainBackgroundImage not found. Cannot reset background.")
	end
end

-- ##### [��� ����] StartDialogue �Լ����� CoreUIManager.OpenMainUIPopup ��� #####
function DialogueManager.StartDialogue(npcId, npcName)
	if not dialogueFrame then 
		DialogueManager.SetupUIReferences()
		if not dialogueFrame then 
			warn("DialogueManager.StartDialogue: DialogueFrame is nil after setup attempt.")
			return 
		end 
	end
	if not npcPortraitImage then 
		DialogueManager.SetupUIReferences()
		if not npcPortraitImage then 
			warn("DialogueManager.StartDialogue: npcPortraitImage is nil after setup attempt.")
			return 
		end 
	end
	if not DialogueDatabase then warn("DialogueManager.StartDialogue: DialogueDatabase�� �ε���� �ʾҽ��ϴ�!"); return end
	if not CoreUIManager then warn("DialogueManager.StartDialogue: CoreUIManager not loaded!"); return end

	currentDialogueData = DialogueDatabase.GetDialogueData(npcId)
	if not currentDialogueData then print("DialogueManager: NPC ID '" .. npcId .. "'�� ���� ��ȭ �����Ͱ� �����ϴ�."); return end

	print("DialogueManager: Starting dialogue with NPC ID:", npcId, "Name:", npcName)
	isDialoguePausedForOtherUI = false 

	if npcNameLabel then npcNameLabel.Text = npcName or "NPC" end
	if dialogueTextLabel then dialogueTextLabel.Text = "" end

	if npcPortraitImage then
		local portraitId = currentDialogueData.PortraitImageId
		if portraitId and type(portraitId) == "string" and portraitId ~= "" and not portraitId:match("YOUR_") then
			npcPortraitImage.Image = portraitId; npcPortraitImage.Visible = true
			print("DialogueManager: Set portrait image to:", portraitId)
		else
			npcPortraitImage.Image = ""; npcPortraitImage.Visible = false
			print("DialogueManager: Portrait image ID is empty or placeholder for NPC:", npcId)
		end
	end

	if mainGui then
		local backgroundFrame = mainGui:FindFirstChild("BackgroundFrame")
		local mainBackgroundImage = backgroundFrame and backgroundFrame:FindFirstChild("MainBackgroundImage")
		if mainBackgroundImage then
			local npcBgId = currentDialogueData.DialogueBackgroundImageId
			if npcBgId and type(npcBgId) == "string" and npcBgId ~= "" and not npcBgId:match("YOUR_") then
				mainBackgroundImage.Image = npcBgId; mainBackgroundImage.Visible = true
				print("DialogueManager: Set dialogue background to NPC specific:", npcBgId)
			else
				DialogueManager.ResetDialogueBackgroundToDefault() 
			end
		else warn("DialogueManager: MainBackgroundImage not found!") end
	end

	if MapManager then MapManager.ShowMapFrame(false) end
	if MobileControlsManager then MobileControlsManager.ShowControls(false) end
	CoreUIManager.OpenMainUIPopup("DialogueFrame") -- �ٸ� �ֿ� �˾� �ݰ� ��ȭâ ����

	currentNodeId = currentDialogueData.InitialNode
	DialogueManager.ShowDialogueNode(currentNodeId)
end
-- #######################################################################

function DialogueManager.ShowDialogueNode(nodeId)
	if not dialogueFrame or not dialogueTextLabel or not responseButtonsFrame or not responseButtonTemplate then
		warn("DialogueManager.ShowDialogueNode: Dialogue UI ��Ұ� ��ȿ���� �ʽ��ϴ�."); DialogueManager.EndDialogue(); return
	end
	if not currentDialogueData or not nodeId or not currentDialogueData.Nodes[nodeId] then
		warn("DialogueManager.ShowDialogueNode: ��ȿ���� ���� ��� ID:", nodeId); DialogueManager.EndDialogue(); return
	end

	local nodeData = currentDialogueData.Nodes[nodeId]
	dialogueTextLabel.Text = nodeData.NPCText or "..."

	for _, child in ipairs(responseButtonsFrame:GetChildren()) do
		if child:IsA("TextButton") and child.Name ~= "ResponseButtonTemplate" then child:Destroy() end
	end

	local buttonsCreated = 0
	if nodeData.Responses and #nodeData.Responses > 0 then
		local gridLayout = responseButtonsFrame:FindFirstChild("ResponseGridLayout")
		if not gridLayout then warn("DialogueManager: ResponseGridLayout not found!") end
		for i, responseData in ipairs(nodeData.Responses) do
			local newButton = responseButtonTemplate:Clone()
			newButton.Name = "ResponseButton_" .. i; newButton.Text = responseData.Text or ("���� " .. i)
			newButton.Visible = true; newButton.Parent = responseButtonsFrame
			if gridLayout then newButton.LayoutOrder = i end
			buttonsCreated = buttonsCreated + 1
			newButton.MouseButton1Click:Connect(function() DialogueManager.SelectResponse(i) end)
		end
	elseif nodeData.IsEnd then
		local gridLayout = responseButtonsFrame:FindFirstChild("ResponseGridLayout")
		local closeButton = responseButtonTemplate:Clone()
		closeButton.Name = "CloseButton"; closeButton.Text = "�ݱ�"; closeButton.Visible = true
		closeButton.Parent = responseButtonsFrame
		if gridLayout then closeButton.LayoutOrder = 1 end
		buttonsCreated = buttonsCreated + 1
		closeButton.MouseButton1Click:Connect(function() DialogueManager.EndDialogue() end)
	else
		warn("DialogueManager: ��忡 ������ ������ ���� ��嵵 �ƴմϴ�:", nodeId)
		local gridLayout = responseButtonsFrame:FindFirstChild("ResponseGridLayout")
		local closeButton = responseButtonTemplate:Clone()
		closeButton.Name = "CloseButton"; closeButton.Text = "�ݱ�"; closeButton.Visible = true
		closeButton.Parent = responseButtonsFrame
		if gridLayout then closeButton.LayoutOrder = 1 end
		buttonsCreated = buttonsCreated + 1
		closeButton.MouseButton1Click:Connect(function() DialogueManager.EndDialogue() end)
	end

	task.spawn(function()
		task.wait(0.05)
		local gridLayout = responseButtonsFrame:FindFirstChild("ResponseGridLayout")
		if gridLayout and buttonsCreated > 0 then
			local itemsPerRow = 3
			if gridLayout.AbsoluteContentSize.X > 0 and gridLayout.CellSize.X.Scale > 0 then
				itemsPerRow = math.max(1, math.floor(responseButtonsFrame.AbsoluteSize.X / (responseButtonsFrame.AbsoluteSize.X * gridLayout.CellSize.X.Scale + gridLayout.CellPadding.X.Offset)))
			elseif gridLayout.AbsoluteContentSize.X > 0 and gridLayout.CellSize.X.Offset > 0 then
				itemsPerRow = math.max(1, math.floor(responseButtonsFrame.AbsoluteSize.X / (gridLayout.CellSize.X.Offset + gridLayout.CellPadding.X.Offset)))
			end
			itemsPerRow = math.max(1, itemsPerRow)
			local numberOfRows = math.ceil(buttonsCreated / itemsPerRow)
			local cellHeight = gridLayout.CellSize.Y.Offset
			local paddingY = gridLayout.CellPadding.Y.Offset
			local totalHeight = (numberOfRows * cellHeight) + (math.max(0, numberOfRows - 1) * paddingY) + paddingY
			responseButtonsFrame.CanvasSize = UDim2.new(0, 0, 0, math.max(cellHeight + paddingY*2, totalHeight))
		elseif buttonsCreated == 0 then
			responseButtonsFrame.CanvasSize = UDim2.new(0,0,0,0)
		end
	end)
end

function DialogueManager.SelectResponse(responseIndex)
	if not currentDialogueData or not currentNodeId or not currentDialogueData.Nodes[currentNodeId] then return end
	local nodeData = currentDialogueData.Nodes[currentNodeId]
	local responses = nodeData.Responses
	if not responses or not responses[responseIndex] then return end
	local selectedResponse = responses[responseIndex]
	print("DialogueManager: Player selected response:", responseIndex, "-", selectedResponse.Text)
	if selectedResponse.NextNode then
		currentNodeId = selectedResponse.NextNode; DialogueManager.ShowDialogueNode(currentNodeId)
	elseif selectedResponse.Action then
		DialogueManager.HandleAction(selectedResponse.Action)
	else
		DialogueManager.EndDialogue()
	end
end

-- ##### [��� ����] HandleAction �Լ����� CoreUIManager.ShowFrame ��� #####
function DialogueManager.HandleAction(action)
	print("DialogueManager: Handling action:", action)
	isDialoguePausedForOtherUI = true 

	-- ��ȭâ�� ���� �ݰ�, �ٸ� UI �Ŵ����� CoreUIManager.OpenMainUIPopup�� ȣ���ϵ��� ��
	if dialogueFrame and CoreUIManager then 
		CoreUIManager.ShowFrame("DialogueFrame", false) -- DialogueFrame�� ����
	end
	if npcPortraitImage then npcPortraitImage.Visible = false end

	local actionHandledByOpeningUI = false
	if action == "OpenShop_Buy" then 
		if ShopUIManager then ShopUIManager.ShowShop(true); ShopUIManager.SetShopMode("Buy"); actionHandledByOpeningUI = true end
	elseif action == "OpenShop_Sell" then 
		if ShopUIManager then ShopUIManager.ShowShop(true); ShopUIManager.SetShopMode("Sell"); actionHandledByOpeningUI = true end
	elseif action == "OpenCrafting" then 
		if CraftingUIManager then CraftingUIManager.ShowCrafting(true); actionHandledByOpeningUI = true end
	elseif action == "OpenGacha" then 
		if GachaUIManager then GachaUIManager.ShowGacha(true); actionHandledByOpeningUI = true end
	elseif action == "OpenSkillShop" then 
		if SkillShopUIManager and SkillShopUIManager.ShowSkillShop then SkillShopUIManager.ShowSkillShop(true); actionHandledByOpeningUI = true else warn("DialogueManager: SkillShopUIManager �Ǵ� ShowSkillShop �Լ��� ã�� �� �����ϴ�!"); end
	elseif action == "OpenEnhancement" then
		if EnhancementUIManager and EnhancementUIManager.ShowEnhancementWindow then
			EnhancementUIManager.ShowEnhancementWindow(true); actionHandledByOpeningUI = true
		else warn("DialogueManager: EnhancementUIManager �Ǵ� ShowEnhancementWindow �Լ��� ã�� �� �����ϴ�!") end
	elseif action == "GetTestFruit" then 
		print("DialogueManager: Requesting test fruit..."); if RequestTestFruitEvent then RequestTestFruitEvent:FireServer() end; DialogueManager.EndDialogue() 
	elseif action == "RemoveFruit" then 
		print("DialogueManager: Requesting devil fruit removal..."); if RequestRemoveDevilFruitEvent then RequestRemoveDevilFruitEvent:FireServer() end; DialogueManager.EndDialogue() 
	elseif action == "PullFruit" then 
		print("DialogueManager: Requesting devil fruit pull..."); if RequestPullDevilFruitEvent then RequestPullDevilFruitEvent:FireServer() end; DialogueManager.EndDialogue() 
	else
		warn("DialogueManager: �� �� ���ų� ó������ ���� �׼�:", action)
		DialogueManager.EndDialogue() 
	end

	if not actionHandledByOpeningUI and isDialoguePausedForOtherUI then
		print("DialogueManager: Action did not open a new UI, but dialogue was paused. Ending dialogue and resetting background.")
		DialogueManager.EndDialogue()
	elseif actionHandledByOpeningUI then
		-- �ٸ� UI�� �������Ƿ�, ��ȭâ ����� ������ �ʿ� ���� (�� UI�� �ڽ��� ���/���� ����)
		-- ������, ResetDialogueBackgroundToDefault�� ȣ���Ͽ� ���� �⺻ ������� ���� �� ����
		-- DialogueManager.ResetDialogueBackgroundToDefault() -- ���� ����
		print("DialogueManager: Another UI opened via action. Dialogue background might persist or be overridden by the new UI.")
	end
end
-- ######################################################################

-- ##### [��� ����] EndDialogue �Լ����� CoreUIManager.ShowFrame ��� #####
function DialogueManager.EndDialogue()
	print("DialogueManager: Ending dialogue.")
	isDialoguePausedForOtherUI = false 

	if dialogueFrame and dialogueFrame.Visible then -- CoreUIManager�� ���� �ݱ�
		if CoreUIManager then
			CoreUIManager.ShowFrame("DialogueFrame", false)
		else
			dialogueFrame.Visible = false -- Fallback
		end
	end
	if npcPortraitImage then
		npcPortraitImage.Visible = false
		npcPortraitImage.Image = ""
	end

	DialogueManager.ResetDialogueBackgroundToDefault()

	if MapManager then MapManager.ShowMapFrame(true) end
	if MobileControlsManager then MobileControlsManager.ShowControls(true) end
	-- if TooltipManager and TooltipManager.HideTooltip then TooltipManager.HideTooltip() end -- �ʿ�� �߰�

	currentDialogueData = nil
	currentNodeId = nil
end
-- #######################################################################

function DialogueManager.IsDialoguePaused()
	return isDialoguePausedForOtherUI
end

return DialogueManager