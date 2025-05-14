-- EnhancementUIManager.lua (수정: 전체 화면 파티클 이펙트 사용 - 이전 답변과 동일)

local EnhancementUIManager = {}

-- 필요한 서비스 및 모듈 로드
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainGui = playerGui:WaitForChild("MainGui")

local ModuleManager
local CoreUIManager
local ItemDatabase
local EnhancementDatabase
local PlayerData
local GuiUtils
local getPlayerInventoryFunction
local EnhanceItemEvent
local NotifyPlayerEvent

-- UI 요소 참조 변수
local enhancementFrame = nil
local enhanceableItemList = nil
local selectedItemImage = nil
local itemInfoLabel = nil
local materialList = nil
local costLabel = nil
local successRateLabel = nil
local enhanceButton = nil
local closeButton = nil

local fullScreenEffectFrame = nil
local fullScreenParticleEmitter = nil
local fullScreenEffectText = nil

local currentSelectedItemInventoryIndex = nil
local isProcessingEnhancement = false
local MIN_EFFECT_DURATION = 1.5
local lastEnhancementServerResult = nil

local RATING_COLORS = { Common=Color3.fromRGB(180,180,180), Uncommon=Color3.fromRGB(100,200,100), Rare=Color3.fromRGB(100,150,255), Epic=Color3.fromRGB(180,100,220), Legendary=Color3.fromRGB(255,165,0) }
local DEFAULT_RATING_COLOR = RATING_COLORS["Common"]

local function FinalizeEnhancementUI(resultData)
	print("EnhancementUIManager: Finalizing UI with result:", resultData)
	if fullScreenParticleEmitter then
		fullScreenParticleEmitter.Enabled = false
		print("EnhancementUIManager: FinalizeEnhancementUI - Full screen particle effect stopped.")
	end
	if fullScreenEffectFrame then
		fullScreenEffectFrame.Visible = false
		print("EnhancementUIManager: FinalizeEnhancementUI - FullScreenEnhancementEffectFrame hidden.")
	end

	if enhanceButton then
		enhanceButton.Selectable = true
		enhanceButton.Text = "강화"
		print("EnhancementUIManager: FinalizeEnhancementUI - Enhance button (in EnhancementFrame) reset.")
	end

	EnhancementUIManager.DisplayItemForEnhancement(currentSelectedItemInventoryIndex)
	EnhancementUIManager.PopulateEnhanceableItems()

	isProcessingEnhancement = false
	lastEnhancementServerResult = nil
	print("EnhancementUIManager: FinalizeEnhancementUI - UI update routines finished, processing state reset.")
end

function EnhancementUIManager.HandleEnhancementResult(resultPayload)
	print("EnhancementUIManager: HandleEnhancementResult CALLED with payload:", resultPayload)
	lastEnhancementServerResult = resultPayload

	if not isProcessingEnhancement then
		print("EnhancementUIManager: HandleEnhancementResult - Not currently in client-side processing state, finalizing UI immediately with server result.")
		FinalizeEnhancementUI(lastEnhancementServerResult)
	else
		print("EnhancementUIManager: HandleEnhancementResult - Client-side processing state is active. Server result stored. Timer will finalize UI.")
	end
end

function EnhancementUIManager.Init()
	ModuleManager = require(ReplicatedStorage.Modules:WaitForChild("ModuleManager"))
	CoreUIManager = ModuleManager:GetModule("CoreUIManager")
	ItemDatabase = ModuleManager:GetModule("ItemDatabase")
	EnhancementDatabase = ModuleManager:GetModule("EnhancementDatabase")
	PlayerData = ModuleManager:GetModule("PlayerData")
	GuiUtils = ModuleManager:GetModule("GuiUtils")
	getPlayerInventoryFunction = ReplicatedStorage:WaitForChild("GetPlayerInventoryFunction")
	EnhanceItemEvent = ReplicatedStorage:WaitForChild("EnhanceItemEvent")
	NotifyPlayerEvent = ReplicatedStorage:WaitForChild("NotifyPlayerEvent")

	EnhancementUIManager.SetupUIReferences()
	print("EnhancementUIManager: Initialized.")
end

function EnhancementUIManager.SetupUIReferences()
	if enhancementFrame and fullScreenEffectFrame then return true end
	if not mainGui then
		local p = Players.LocalPlayer
		local pg = p and p:WaitForChild("PlayerGui")
		mainGui = pg and pg:FindFirstChild("MainGui")
		if not mainGui then warn("EnhancementUIManager.SetupUIReferences: MainGui not found!"); return false end
	end
	local backgroundFrame = mainGui:FindFirstChild("BackgroundFrame")
	local framesFolder = backgroundFrame and backgroundFrame:FindFirstChild("Frames")

	enhancementFrame = backgroundFrame and backgroundFrame:FindFirstChild("EnhancementFrame")

	if framesFolder then
		fullScreenEffectFrame = framesFolder:FindFirstChild("FullScreenEnhancementEffectFrame")
		if fullScreenEffectFrame then
			fullScreenParticleEmitter = fullScreenEffectFrame:FindFirstChild("FullScreenParticle")
			fullScreenEffectText = fullScreenEffectFrame:FindFirstChild("EffectStatusText")
			if not fullScreenParticleEmitter then warn("EnhancementUIManager: FullScreenParticle 이미터를 찾지 못했습니다!") end
			if not fullScreenEffectText then warn("EnhancementUIManager: EffectStatusText 레이블을 찾지 못했습니다!") end
		else
			warn("EnhancementUIManager: FullScreenEnhancementEffectFrame을 Frames 폴더에서 찾을 수 없습니다!")
		end
	elseif backgroundFrame then
		fullScreenEffectFrame = backgroundFrame:FindFirstChild("FullScreenEnhancementEffectFrame")
		if fullScreenEffectFrame then
			fullScreenParticleEmitter = fullScreenEffectFrame:FindFirstChild("FullScreenParticle")
			fullScreenEffectText = fullScreenEffectFrame:FindFirstChild("EffectStatusText")
		else
			warn("EnhancementUIManager: FullScreenEnhancementEffectFrame을 backgroundFrame에서 찾을 수 없습니다!")
		end
	else
		warn("EnhancementUIManager.SetupUIReferences: BackgroundFrame not found!")
	end

	if enhancementFrame then
		enhanceableItemList = enhancementFrame:FindFirstChild("EnhanceableItemList")
		local detailsDisplay = enhancementFrame:FindFirstChild("DetailsDisplayFrame")
		if detailsDisplay then
			local itemDisplay = detailsDisplay:FindFirstChild("ItemDisplayFrame")
			selectedItemImage = itemDisplay and itemDisplay:FindFirstChild("SelectedItemImage")
			itemInfoLabel = itemDisplay and itemDisplay:FindFirstChild("ItemInfoLabel")
			local infoDisplay = detailsDisplay:FindFirstChild("InfoDisplayFrame")
			materialList = infoDisplay and infoDisplay:FindFirstChild("MaterialList")
			costLabel = infoDisplay and infoDisplay:FindFirstChild("CostLabel")
			successRateLabel = infoDisplay and infoDisplay:FindFirstChild("SuccessRateLabel")
			enhanceButton = detailsDisplay:FindFirstChild("EnhanceButton")
		end
		closeButton = enhancementFrame:FindFirstChild("CloseButton")
		if not (enhanceableItemList and selectedItemImage and itemInfoLabel and materialList and costLabel and successRateLabel and enhanceButton and closeButton) then
			warn("EnhancementUIManager: 강화 UI (EnhancementFrame) 내부 요소 중 일부를 찾을 수 없습니다!")
			enhancementFrame = nil
		end
	else
		warn("EnhancementUIManager: EnhancementFrame을 찾을 수 없습니다!")
	end

	if not (enhancementFrame and fullScreenEffectFrame and fullScreenParticleEmitter and fullScreenEffectText) then
		warn("EnhancementUIManager: 필수 UI 요소(기존 강화창 또는 전체화면 이펙트 프레임/파티클) 참조 설정 실패!")
		return false
	end

	if enhanceButton and not enhanceButton:FindFirstChild("ClickConnection_Enhance") then
		enhanceButton.MouseButton1Click:Connect(function()
			if isProcessingEnhancement then
				print("EnhancementUIManager: Enhance button clicked, but already processing.")
				return
			end

			if enhanceButton.Selectable and currentSelectedItemInventoryIndex then
				print("EnhancementUIManager: Enhance button clicked for index:", currentSelectedItemInventoryIndex)
				isProcessingEnhancement = true
				lastEnhancementServerResult = nil

				EnhanceItemEvent:FireServer(currentSelectedItemInventoryIndex)

				if fullScreenEffectFrame then
					if fullScreenEffectText then fullScreenEffectText.Text = "강 화 시 도 중..." end
					fullScreenEffectFrame.Visible = true
					if fullScreenParticleEmitter then
						fullScreenParticleEmitter.Enabled = true
						print("EnhancementUIManager: Full screen particle effect started.")
					end
				else
					warn("EnhancementUIManager: fullScreenEffectFrame is nil, cannot show full screen effect.")
				end

				enhanceButton.Selectable = false
				enhanceButton.Text = "처리중"

				task.delay(MIN_EFFECT_DURATION, function()
					if isProcessingEnhancement then
						print("EnhancementUIManager: MIN_EFFECT_DURATION elapsed. Finalizing UI.")
						FinalizeEnhancementUI(lastEnhancementServerResult)
					end
				end)
			else
				print("EnhancementUIManager: Enhance button clicked but not ready or no item selected.")
			end
		end)
		local marker = Instance.new("BoolValue")
		marker.Name = "ClickConnection_Enhance"
		marker.Parent = enhanceButton
	end
	print("EnhancementUIManager: UI References Setup Completed (Full screen effect integration).")
	return true
end

function EnhancementUIManager.PopulateEnhanceableItems()
	if not enhanceableItemList then
		if not EnhancementUIManager.SetupUIReferences() or not enhanceableItemList then
			warn("EnhancementUIManager.PopulateEnhanceableItems: EnhanceableItemList frame is nil after setup attempt!")
			return
		end
	end
	if not ItemDatabase then warn("EnhancementUIManager: ItemDatabase not loaded!"); return end
	if not GuiUtils then warn("EnhancementUIManager.PopulateEnhanceableItems: GuiUtils not loaded!"); return end

	if enhanceableItemList then
		for _, child in ipairs(enhanceableItemList:GetChildren()) do
			if child:IsA("ImageButton") or (child.Name == "EmptyMsg" and child:IsA("TextLabel")) then
				child:Destroy()
			end
		end
	end

	local playerInventory = {}
	local successInv, invResult = pcall(function() return getPlayerInventoryFunction:InvokeServer() end)
	if successInv and typeof(invResult) == 'table' then playerInventory = invResult
	else warn("EnhancementUIManager: 인벤토리 정보 로드 실패!", invResult); return end

	local itemsAdded = 0
	for index, itemSlotData in ipairs(playerInventory) do
		if itemSlotData and itemSlotData.itemId then
			local itemId = itemSlotData.itemId
			local itemInfo = ItemDatabase.GetItemInfo(itemId)

			if itemInfo and itemInfo.Type == "Equipment" and itemInfo.Enhanceable then
				itemsAdded = itemsAdded + 1
				local currentLevel = itemSlotData.enhancementLevel or 0

				local itemButton = Instance.new("ImageButton")
				itemButton.Name = "Item_" .. index
				itemButton.Size = UDim2.new(0, 64, 0, 64)
				itemButton.BackgroundColor3 = Color3.fromRGB(70, 65, 55)
				itemButton.BorderSizePixel = 0
				itemButton.LayoutOrder = index
				itemButton.Parent = enhanceableItemList

				local itemImage = Instance.new("ImageLabel")
				itemImage.Name = "Icon"
				itemImage.Size = UDim2.new(1, -4, 1, -4)
				itemImage.Position = UDim2.new(0.5, 0, 0.5, 0)
				itemImage.AnchorPoint = Vector2.new(0.5, 0.5)
				itemImage.BackgroundTransparency = 1
				itemImage.Image = itemInfo.ImageId or ""
				itemImage.ScaleType = Enum.ScaleType.Fit
				itemImage.Parent = itemButton

				local levelLabel = GuiUtils.CreateTextLabel(itemButton, "LevelLabel",
					UDim2.new(1, -2, 0, 2), UDim2.new(0.3, 10, 0.2, 0),
					"+" .. currentLevel,
					Vector2.new(1, 0), Enum.TextXAlignment.Right, Enum.TextYAlignment.Top, 10, Color3.fromRGB(255, 230, 150))
				if levelLabel then
					levelLabel.TextStrokeTransparency = 0.5
					levelLabel.ZIndex = itemButton.ZIndex + 2
				end

				local rating = itemInfo.Rating or "Common"
				local ratingColor = RATING_COLORS[rating] or DEFAULT_RATING_COLOR
				local ratingStroke = itemButton:FindFirstChild("RatingStroke") or Instance.new("UIStroke")
				ratingStroke.Name = "RatingStroke"; ratingStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; ratingStroke.LineJoinMode = Enum.LineJoinMode.Round; ratingStroke.Thickness = 2; ratingStroke.Color = ratingColor; ratingStroke.Transparency = 0; ratingStroke.Parent = itemButton

				itemButton.MouseButton1Click:Connect(function()
					if isProcessingEnhancement then return end
					print("EnhancementUIManager: Selected item at index", index, "ItemID:", itemId)
					EnhancementUIManager.SelectItemForEnhancement(index)
				end)
			end
		end
	end

	task.wait()
	local gridLayout = enhanceableItemList:FindFirstChildOfClass("UIGridLayout")
	if gridLayout then
		local contentHeight = gridLayout.AbsoluteContentSize.Y
		enhanceableItemList.CanvasSize = UDim2.new(0, 0, 0, contentHeight + 10)
	end

	if itemsAdded == 0 then
		GuiUtils.CreateTextLabel(enhanceableItemList, "EmptyMsg", UDim2.new(0.5,0,0.1,0), UDim2.new(0.9,0,0.2,0), "강화 가능한 아이템이 없습니다.", Vector2.new(0.5,0))
	end

	print("EnhancementUIManager: Enhanceable item list populated.")
end

function EnhancementUIManager.SelectItemForEnhancement(inventoryIndex)
	if isProcessingEnhancement then return end
	if not inventoryIndex then return end
	EnhancementUIManager.DisplayItemForEnhancement(inventoryIndex)
end

function EnhancementUIManager.ShowEnhancementWindow(show)
	if not enhancementFrame then
		if not EnhancementUIManager.SetupUIReferences() or not enhancementFrame then
			warn("EnhancementUIManager.ShowEnhancementWindow: EnhancementFrame is still nil after setup attempt.")
			return
		end
	end
	if not CoreUIManager then
		warn("EnhancementUIManager.ShowEnhancementWindow: CoreUIManager not available!")
		if enhancementFrame then enhancementFrame.Visible = show end
		return
	end

	if show then
		print("EnhancementUIManager: 강화 창 열기 시도")
		CoreUIManager.OpenMainUIPopup("EnhancementFrame")
		EnhancementUIManager.PopulateEnhanceableItems()
		EnhancementUIManager.DisplayItemForEnhancement(nil)
		isProcessingEnhancement = false
		lastEnhancementServerResult = nil
		if fullScreenEffectFrame then fullScreenEffectFrame.Visible = false end
		if fullScreenParticleEmitter then fullScreenParticleEmitter.Enabled = false end
		if enhanceButton then enhanceButton.Selectable = false; enhanceButton.Text = "강화" end
	else
		print("EnhancementUIManager: 강화 창 닫기")
		CoreUIManager.ShowFrame("EnhancementFrame", false)
		currentSelectedItemInventoryIndex = nil
		isProcessingEnhancement = false
		lastEnhancementServerResult = nil
		if fullScreenEffectFrame then fullScreenEffectFrame.Visible = false end
		if fullScreenParticleEmitter then fullScreenParticleEmitter.Enabled = false end
	end
end

function EnhancementUIManager.DisplayItemForEnhancement(inventoryIndex)
	currentSelectedItemInventoryIndex = inventoryIndex

	if not enhancementFrame or not enhancementFrame.Visible then
		if selectedItemImage then selectedItemImage.Image = ""; selectedItemImage.Visible = false end
		if itemInfoLabel then itemInfoLabel.Text = "강화할 아이템을 목록에서 선택하세요." end
		if materialList then materialList:ClearAllChildren(); materialList.CanvasSize = UDim2.new() end
		if costLabel then costLabel.Text = "비용: - G" end
		if successRateLabel then successRateLabel.Text = "성공 확률: - %" end
		if enhanceButton then enhanceButton.Visible = false; enhanceButton.Text = "강화"; enhanceButton.Selectable = false; end
		if fullScreenParticleEmitter then fullScreenParticleEmitter.Enabled = false end
		if fullScreenEffectFrame then fullScreenEffectFrame.Visible = false end
		return
	end

	if fullScreenParticleEmitter then fullScreenParticleEmitter.Enabled = false end

	if not currentSelectedItemInventoryIndex then
		if selectedItemImage then selectedItemImage.Image=""; selectedItemImage.Visible=false end
		if itemInfoLabel then itemInfoLabel.Text="강화할 아이템을 목록에서 선택하세요." end
		if materialList then materialList:ClearAllChildren(); materialList.CanvasSize=UDim2.new() end
		if costLabel then costLabel.Text="비용: - G" end
		if successRateLabel then successRateLabel.Text="성공 확률: - %" end
		if enhanceButton then enhanceButton.Visible=false; enhanceButton.Text="강화"; enhanceButton.Selectable = false; end
		print("EnhancementUIManager: DisplayItemForEnhancement - No item selected, UI reset.")
		return
	end

	local playerInventory = {}; local successInv, invResult = pcall(function() return getPlayerInventoryFunction:InvokeServer() end); if successInv and typeof(invResult)=='table' then playerInventory = invResult else warn("EnhancementUIManager: 인벤토리 정보 로드 실패!", invResult); return end
	local itemSlotData = playerInventory[currentSelectedItemInventoryIndex];
	if not itemSlotData then
		warn("EnhancementUIManager: 선택된 인덱스("..tostring(currentSelectedItemInventoryIndex)..")에 해당하는 아이템이 인벤토리에 없습니다.")
		EnhancementUIManager.DisplayItemForEnhancement(nil)
		return
	end
	local itemId = itemSlotData.itemId; local currentLevel = itemSlotData.enhancementLevel or 0; local itemInfo = ItemDatabase.GetItemInfo(itemId); if not itemInfo then warn("EnhancementUIManager: ItemDatabase 정보 로드 실패:", itemId); EnhancementUIManager.DisplayItemForEnhancement(nil); return end

	if not itemInfo.Enhanceable then
		if selectedItemImage then selectedItemImage.Image=itemInfo.ImageId or ""; selectedItemImage.Visible=true end
		if itemInfoLabel then itemInfoLabel.Text=string.format("%s\n(강화 불가)", itemInfo.Name) end
		if materialList then materialList:ClearAllChildren(); materialList.CanvasSize=UDim2.new() end
		if costLabel then costLabel.Text="비용: -" end
		if successRateLabel then successRateLabel.Text="성공 확률: -" end
		if enhanceButton then enhanceButton.Visible=false; enhanceButton.Text="강화"; enhanceButton.Selectable = false; end
		print("EnhancementUIManager: DisplayItemForEnhancement - 강화 불가 아이템:", itemId)
		return
	end

	if selectedItemImage then selectedItemImage.Image=itemInfo.ImageId or ""; selectedItemImage.Visible=true end
	if itemInfoLabel then itemInfoLabel.Text=string.format("%s (+%d)", itemInfo.Name, currentLevel) end

	local nextLevel = currentLevel + 1
	local maxLevel = itemInfo.MaxEnhanceLevel or 0
	local nextLevelInfo = nil
	if nextLevel <= maxLevel then
		nextLevelInfo = EnhancementDatabase.GetLevelInfo(nextLevel)
	end

	if materialList then materialList:ClearAllChildren() end
	local totalMaterialHeight = 0
	local canEnhance = true

	if nextLevelInfo then
		local requiredGold = nextLevelInfo.GoldCost or 0
		local playerStats = PlayerData.GetStats(player)
		local playerGold = playerStats and playerStats.Gold or 0

		if costLabel then
			costLabel.Text=string.format("비용: %d G", requiredGold)
			costLabel.TextColor3 = (playerGold >= requiredGold) and Color3.new(1,1,1) or Color3.fromRGB(255,100,100)
		end
		if playerGold < requiredGold then canEnhance = false end

		if successRateLabel then
			successRateLabel.Text=string.format("성공 확률: %.0f %%", (nextLevelInfo.SuccessRate or 0)*100)
		end

		if nextLevelInfo.Materials and #nextLevelInfo.Materials > 0 and materialList and GuiUtils then
			for i, matData in ipairs(nextLevelInfo.Materials) do
				local matInfo = ItemDatabase.GetItemInfo(matData.ItemID)
				local matName = matInfo and matInfo.Name or ("아이템 #"..matData.ItemID)
				local requiredQty = matData.Quantity
				local currentQty = 0
				for _, invSlotData in ipairs(playerInventory) do
					if invSlotData.itemId == matData.ItemID then
						currentQty=currentQty+invSlotData.quantity
					end
				end
				local label=GuiUtils.CreateTextLabel(materialList,"Material_"..i,UDim2.new(0,5,0,totalMaterialHeight),UDim2.new(1,-10,0,20),string.format("%s: %d / %d",matName,currentQty,requiredQty),nil,Enum.TextXAlignment.Left,Enum.TextYAlignment.Center,12)
				if label then
					label.TextColor3=(currentQty>=requiredQty) and Color3.new(1,1,1) or Color3.fromRGB(255,100,100)
					totalMaterialHeight=totalMaterialHeight+20
					if currentQty<requiredQty then canEnhance=false end
				end
			end
		else
			if materialList and GuiUtils then
				GuiUtils.CreateTextLabel(materialList,"Material_None",UDim2.new(0,5,0,0),UDim2.new(1,-10,0,20),"필요 재료 없음",nil,Enum.TextXAlignment.Left,Enum.TextYAlignment.Center,12)
				totalMaterialHeight=20
			end
		end

		if materialList then materialList.CanvasSize = UDim2.new(0, 0, 0, totalMaterialHeight) end

		if enhanceButton then
			enhanceButton.Visible=true
			enhanceButton.Selectable=canEnhance
			enhanceButton.BackgroundColor3=canEnhance and Color3.fromRGB(180,140,80) or Color3.fromRGB(100,100,100)
			enhanceButton.Text = "강화"
		end
	else
		if costLabel then costLabel.Text="비용: -" end
		if successRateLabel then successRateLabel.Text="최대 레벨" end
		if enhanceButton then enhanceButton.Visible=false; enhanceButton.Text = "강화"; enhanceButton.Selectable = false; end
		if materialList then materialList:ClearAllChildren(); materialList.CanvasSize=UDim2.new() end
		canEnhance=false
		print("EnhancementUIManager: DisplayItemForEnhancement - 최대 강화 레벨 도달:", itemId)
	end
	print("EnhancementUIManager: Displayed item for enhancement:", itemId, "Current Level:", currentLevel, "Can Enhance:", canEnhance)
end

return EnhancementUIManager