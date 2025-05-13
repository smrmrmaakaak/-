-- DialogueManager.lua (수정: HandleAction 시 배경 유지, 각 UI 닫을 때 배경 초기화, UI 창 겹침 방지 로직 적용)

local DialogueManager = {}

-- 필요한 서비스 및 모듈 로드
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainGui = playerGui:WaitForChild("MainGui") 

local ModuleManager
local CoreUIManager -- CoreUIManager 참조 선언
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
-- local TooltipManager -- 필요시 추가

local currentDialogueData = nil
local currentNodeId = nil
local dialogueFrame = nil -- 모듈 스코프로 이동
local npcNameLabel = nil
local dialogueTextLabel = nil
local responseButtonsFrame = nil
local responseButtonTemplate = nil
local npcPortraitImage = nil
local isDialoguePausedForOtherUI = false

local DEFAULT_DIALOGUE_BACKGROUND_IMAGE_ID = "" 

-- 모듈 초기화
function DialogueManager.Init()
	ModuleManager = require(ReplicatedStorage.Modules:WaitForChild("ModuleManager"))
	CoreUIManager = ModuleManager:GetModule("CoreUIManager") -- CoreUIManager 초기화
	DialogueDatabase = ModuleManager:GetModule("DialogueDatabase")
	GuiUtils = ModuleManager:GetModule("GuiUtils")
	MapManager = ModuleManager:GetModule("MapManager")
	ShopUIManager = ModuleManager:GetModule("ShopUIManager")
	CraftingUIManager = ModuleManager:GetModule("CraftingUIManager")
	GachaUIManager = ModuleManager:GetModule("GachaUIManager")
	SkillShopUIManager = ModuleManager:GetModule("SkillShopUIManager")
	MobileControlsManager = ModuleManager:GetModule("MobileControlsManager")
	EnhancementUIManager = ModuleManager:GetModule("EnhancementUIManager")
	-- TooltipManager = ModuleManager:GetModule("TooltipManager") -- 필요시 초기화
	RequestTestFruitEvent = ReplicatedStorage:WaitForChild("RequestTestFruitEvent")
	RequestRemoveDevilFruitEvent = ReplicatedStorage:WaitForChild("RequestRemoveDevilFruitEvent")
	RequestPullDevilFruitEvent = ReplicatedStorage:WaitForChild("RequestPullDevilFruitEvent")

	DialogueManager.SetupUIReferences() -- UI 참조 설정
	print("DialogueManager: Initialized (Modules Loaded).")
end

-- UI 요소 참조 설정 함수
function DialogueManager.SetupUIReferences()
	if dialogueFrame and npcNameLabel then -- 주요 내부 요소도 확인
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

	dialogueFrame = backgroundFrame:FindFirstChild("DialogueFrame") -- 모듈 스코프 변수에 할당
	if dialogueFrame then
		npcNameLabel = dialogueFrame:FindFirstChild("NpcNameLabel")
		dialogueTextLabel = dialogueFrame:FindFirstChild("DialogueTextLabel")
		responseButtonsFrame = dialogueFrame:FindFirstChild("ResponseButtonsFrame")
		npcPortraitImage = dialogueFrame:FindFirstChild("NpcPortraitImage")

		if not (npcNameLabel and dialogueTextLabel and responseButtonsFrame and npcPortraitImage) then
			warn("DialogueManager.SetupUIReferences: DialogueFrame 내부 요소를 찾을 수 없습니다!")
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
		warn("DialogueManager.SetupUIReferences: DialogueFrame을 찾을 수 없습니다!")
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

-- ##### [기능 수정] StartDialogue 함수에서 CoreUIManager.OpenMainUIPopup 사용 #####
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
	if not DialogueDatabase then warn("DialogueManager.StartDialogue: DialogueDatabase가 로드되지 않았습니다!"); return end
	if not CoreUIManager then warn("DialogueManager.StartDialogue: CoreUIManager not loaded!"); return end

	currentDialogueData = DialogueDatabase.GetDialogueData(npcId)
	if not currentDialogueData then print("DialogueManager: NPC ID '" .. npcId .. "'에 대한 대화 데이터가 없습니다."); return end

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
	CoreUIManager.OpenMainUIPopup("DialogueFrame") -- 다른 주요 팝업 닫고 대화창 열기

	currentNodeId = currentDialogueData.InitialNode
	DialogueManager.ShowDialogueNode(currentNodeId)
end
-- #######################################################################

function DialogueManager.ShowDialogueNode(nodeId)
	if not dialogueFrame or not dialogueTextLabel or not responseButtonsFrame or not responseButtonTemplate then
		warn("DialogueManager.ShowDialogueNode: Dialogue UI 요소가 유효하지 않습니다."); DialogueManager.EndDialogue(); return
	end
	if not currentDialogueData or not nodeId or not currentDialogueData.Nodes[nodeId] then
		warn("DialogueManager.ShowDialogueNode: 유효하지 않은 노드 ID:", nodeId); DialogueManager.EndDialogue(); return
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
			newButton.Name = "ResponseButton_" .. i; newButton.Text = responseData.Text or ("응답 " .. i)
			newButton.Visible = true; newButton.Parent = responseButtonsFrame
			if gridLayout then newButton.LayoutOrder = i end
			buttonsCreated = buttonsCreated + 1
			newButton.MouseButton1Click:Connect(function() DialogueManager.SelectResponse(i) end)
		end
	elseif nodeData.IsEnd then
		local gridLayout = responseButtonsFrame:FindFirstChild("ResponseGridLayout")
		local closeButton = responseButtonTemplate:Clone()
		closeButton.Name = "CloseButton"; closeButton.Text = "닫기"; closeButton.Visible = true
		closeButton.Parent = responseButtonsFrame
		if gridLayout then closeButton.LayoutOrder = 1 end
		buttonsCreated = buttonsCreated + 1
		closeButton.MouseButton1Click:Connect(function() DialogueManager.EndDialogue() end)
	else
		warn("DialogueManager: 노드에 응답이 없지만 종료 노드도 아닙니다:", nodeId)
		local gridLayout = responseButtonsFrame:FindFirstChild("ResponseGridLayout")
		local closeButton = responseButtonTemplate:Clone()
		closeButton.Name = "CloseButton"; closeButton.Text = "닫기"; closeButton.Visible = true
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

-- ##### [기능 수정] HandleAction 함수에서 CoreUIManager.ShowFrame 사용 #####
function DialogueManager.HandleAction(action)
	print("DialogueManager: Handling action:", action)
	isDialoguePausedForOtherUI = true 

	-- 대화창을 먼저 닫고, 다른 UI 매니저가 CoreUIManager.OpenMainUIPopup을 호출하도록 함
	if dialogueFrame and CoreUIManager then 
		CoreUIManager.ShowFrame("DialogueFrame", false) -- DialogueFrame만 닫음
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
		if SkillShopUIManager and SkillShopUIManager.ShowSkillShop then SkillShopUIManager.ShowSkillShop(true); actionHandledByOpeningUI = true else warn("DialogueManager: SkillShopUIManager 또는 ShowSkillShop 함수를 찾을 수 없습니다!"); end
	elseif action == "OpenEnhancement" then
		if EnhancementUIManager and EnhancementUIManager.ShowEnhancementWindow then
			EnhancementUIManager.ShowEnhancementWindow(true); actionHandledByOpeningUI = true
		else warn("DialogueManager: EnhancementUIManager 또는 ShowEnhancementWindow 함수를 찾을 수 없습니다!") end
	elseif action == "GetTestFruit" then 
		print("DialogueManager: Requesting test fruit..."); if RequestTestFruitEvent then RequestTestFruitEvent:FireServer() end; DialogueManager.EndDialogue() 
	elseif action == "RemoveFruit" then 
		print("DialogueManager: Requesting devil fruit removal..."); if RequestRemoveDevilFruitEvent then RequestRemoveDevilFruitEvent:FireServer() end; DialogueManager.EndDialogue() 
	elseif action == "PullFruit" then 
		print("DialogueManager: Requesting devil fruit pull..."); if RequestPullDevilFruitEvent then RequestPullDevilFruitEvent:FireServer() end; DialogueManager.EndDialogue() 
	else
		warn("DialogueManager: 알 수 없거나 처리되지 않은 액션:", action)
		DialogueManager.EndDialogue() 
	end

	if not actionHandledByOpeningUI and isDialoguePausedForOtherUI then
		print("DialogueManager: Action did not open a new UI, but dialogue was paused. Ending dialogue and resetting background.")
		DialogueManager.EndDialogue()
	elseif actionHandledByOpeningUI then
		-- 다른 UI가 열렸으므로, 대화창 배경은 유지될 필요 없음 (각 UI는 자신의 배경/투명도 관리)
		-- 하지만, ResetDialogueBackgroundToDefault를 호출하여 게임 기본 배경으로 돌릴 수 있음
		-- DialogueManager.ResetDialogueBackgroundToDefault() -- 선택 사항
		print("DialogueManager: Another UI opened via action. Dialogue background might persist or be overridden by the new UI.")
	end
end
-- ######################################################################

-- ##### [기능 수정] EndDialogue 함수에서 CoreUIManager.ShowFrame 사용 #####
function DialogueManager.EndDialogue()
	print("DialogueManager: Ending dialogue.")
	isDialoguePausedForOtherUI = false 

	if dialogueFrame and dialogueFrame.Visible then -- CoreUIManager를 통해 닫기
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
	-- if TooltipManager and TooltipManager.HideTooltip then TooltipManager.HideTooltip() end -- 필요시 추가

	currentDialogueData = nil
	currentNodeId = nil
end
-- #######################################################################

function DialogueManager.IsDialoguePaused()
	return isDialoguePausedForOtherUI
end

return DialogueManager