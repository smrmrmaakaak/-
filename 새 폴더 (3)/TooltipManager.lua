-- TooltipManager.lua (수정: 해제 버튼 표시 로직 및 강화 스탯 계산 로직 재수정 + 디버그 Print 추가)

local TooltipManager = {}

-- 필요한 서비스 로드
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")

-- 모듈 로드
local Modules = ReplicatedStorage:WaitForChild("Modules", 15)
if not Modules then warn("TooltipManager: Modules 폴더 로드 실패!"); return nil end
local GuiUtils = require(Modules:WaitForChild("GuiUtils", 10))
if not GuiUtils then warn("TooltipManager: GuiUtils 로드 실패!"); return nil end
local ItemDatabase = require(Modules:WaitForChild("ItemDatabase", 10))
if not ItemDatabase then warn("TooltipManager: ItemDatabase 로드 실패!"); return nil end

-- 이벤트 참조 (디버그를 위해 로드 시점 확인)
local unequipItemEvent = ReplicatedStorage:FindFirstChild("UnequipItemEvent")
print("TooltipManager: Loaded UnequipItemEvent reference:", unequipItemEvent) -- 이벤트 로드 확인

-- 등급별 색상 정의
local RATING_COLORS = { ["Common"]=Color3.fromRGB(180,180,180), ["Uncommon"]=Color3.fromRGB(100,200,100), ["Rare"]=Color3.fromRGB(100,150,255), ["Epic"]=Color3.fromRGB(180,100,220), ["Legendary"]=Color3.fromRGB(255,165,0) }
local DEFAULT_RATING_COLOR = RATING_COLORS["Common"]

-- 스탯 표시 이름 매핑
local STAT_DISPLAY_NAMES = { Attack="공격력", Defense="방어력", MaxHP="최대 HP", MaxMP="최대 MP", STR="힘", AGI="민첩", INT="지능", LUK="운", CritChance="치명타 확률(%)", CritDamage="치명타 데미지(%)", EvasionRate="회피율(%)", AccuracyRate="명중률(%)" }

TooltipManager.tooltipFrame = nil
local currentTooltipItemId = nil
local currentTooltipSlot = nil

-- 툴팁 UI 프레임 생성 함수 (디버그 Print 추가)
function TooltipManager.CreateTooltipFrame(parentGui)
	print("TooltipManager: CreateTooltipFrame 함수 시작됨.")
	if TooltipManager.tooltipFrame then print("TooltipManager: 툴팁 프레임 이미 존재함."); return end

	local success, err = pcall(function()
		local useItemEvent = ReplicatedStorage:FindFirstChild("UseItemEvent")
		local equipItemEvent = ReplicatedStorage:FindFirstChild("EquipItemEvent") -- << equipItemEvent 참조
		local useDevilFruitEvent = ReplicatedStorage:FindFirstChild("UseDevilFruitEvent")
		unequipItemEvent = ReplicatedStorage:FindFirstChild("UnequipItemEvent") -- 다시 한번 참조 확인
		print("TooltipManager.CreateTooltipFrame: UnequipItemEvent reference inside pcall:", unequipItemEvent) -- 함수 내에서도 확인

		if not useItemEvent or not equipItemEvent or not unequipItemEvent or not useDevilFruitEvent then warn("TooltipManager.CreateTooltipFrame: Required RemoteEvents not found!") end

		print("TooltipManager: Creating Tooltip Frame...")
		local frame = Instance.new("Frame"); frame.Name = "ItemTooltipFrame"; frame.Size = UDim2.new(0, 250, 0, 100); frame.Position = UDim2.new(0,0,0,0); frame.AnchorPoint = Vector2.new(0,0); frame.BackgroundColor3 = Color3.fromRGB(30,30,45); frame.BorderColor3 = Color3.fromRGB(150,150,180); frame.BorderSizePixel = 1; frame.Visible = false; frame.ZIndex = 150; frame.Parent = parentGui; frame.ClipsDescendants = true; frame.AutomaticSize = Enum.AutomaticSize.Y
		local padding = Instance.new("UIPadding"); padding.PaddingTop=UDim.new(0,5); padding.PaddingBottom=UDim.new(0,30); padding.PaddingLeft=UDim.new(0,5); padding.PaddingRight=UDim.new(0,5); padding.Parent = frame
		local itemImage = Instance.new("ImageLabel"); itemImage.Name="TooltipItemImage"; itemImage.Size=UDim2.new(0,48,0,48); itemImage.Position=UDim2.new(0,5,0,5); itemImage.AnchorPoint=Vector2.new(0,0); itemImage.BackgroundTransparency=1; itemImage.ScaleType=Enum.ScaleType.Fit; itemImage.ZIndex=frame.ZIndex+1; itemImage.Parent=frame
		local textLabel = Instance.new("TextLabel"); textLabel.Name="TooltipText"; textLabel.Size=UDim2.new(1,-63,0,0); textLabel.Position=UDim2.new(0,58,0,5); textLabel.AnchorPoint=Vector2.new(0,0); textLabel.BackgroundTransparency=1; textLabel.TextColor3=Color3.fromRGB(230,230,230); textLabel.Font=Enum.Font.SourceSans; textLabel.TextSize=14; textLabel.TextWrapped=true; textLabel.RichText=true; textLabel.TextXAlignment=Enum.TextXAlignment.Left; textLabel.TextYAlignment=Enum.TextYAlignment.Top; textLabel.AutomaticSize=Enum.AutomaticSize.Y; textLabel.Parent=frame
		local buttonSize = UDim2.new(0,50,0,20); local buttonPosition = UDim2.new(1,-5,1,-5); local buttonAnchor = Vector2.new(1,1); local buttonTextSize = 12
		local useButton = Instance.new("TextButton"); useButton.Name="UseButton"; useButton.Size=buttonSize; useButton.Position=buttonPosition; useButton.AnchorPoint=buttonAnchor; useButton.BackgroundColor3=Color3.fromRGB(80,180,80); useButton.TextColor3=Color3.fromRGB(255,255,255); useButton.Font=Enum.Font.SourceSansBold; useButton.Text="사용"; useButton.TextSize=buttonTextSize; useButton.Visible=false; useButton.ZIndex=frame.ZIndex+1; useButton.Parent=frame
		useButton.MouseButton1Click:Connect(function() if currentTooltipItemId then local itemInfo = ItemDatabase.Items[currentTooltipItemId]; if itemInfo then if itemInfo.Type == "DevilFruit" then if useDevilFruitEvent then useDevilFruitEvent:FireServer(currentTooltipItemId) end elseif itemInfo.Type == "Consumable" then if useItemEvent then useItemEvent:FireServer(currentTooltipItemId) end end end; TooltipManager.HideTooltip() end end)
		local equipButton = Instance.new("TextButton"); equipButton.Name="EquipButton"; equipButton.Size=buttonSize; equipButton.Position=buttonPosition; equipButton.AnchorPoint=buttonAnchor; equipButton.BackgroundColor3=Color3.fromRGB(80,120,200); equipButton.TextColor3=Color3.fromRGB(255,255,255); equipButton.Font=Enum.Font.SourceSansBold; equipButton.Text="장착"; equipButton.TextSize=buttonTextSize; equipButton.Visible=false; equipButton.ZIndex=frame.ZIndex+1; equipButton.Parent=frame

		-- ########## 장착 버튼 클릭 이벤트 (디버그 Print 추가) ##########
		equipButton.MouseButton1Click:Connect(function()
			-- <<< 추가 디버그 Print >>>
			print("[DEBUG] TooltipManager: EquipButton clicked!")
			print("[DEBUG] TooltipManager: currentTooltipItemId is:", currentTooltipItemId)
			print("[DEBUG] TooltipManager: equipItemEvent is:", equipItemEvent)
			-- <<< 추가 디버그 Print 끝 >>>

			if currentTooltipItemId then
				if equipItemEvent then
					equipItemEvent:FireServer(currentTooltipItemId)
					print("[DEBUG] TooltipManager: Fired EquipItemEvent with ID:", currentTooltipItemId) -- 발송 확인
				else
					warn("TooltipManager: equipItemEvent is nil!")
				end
				TooltipManager.HideTooltip()
			else
				warn("TooltipManager: currentTooltipItemId is nil!")
			end
		end)
		-- ########## 장착 버튼 클릭 이벤트 끝 ##########

		-- <<< 해제 버튼 생성 및 이벤트 연결 (디버그 Print 추가) >>>
		local unequipButton = Instance.new("TextButton"); unequipButton.Name="UnequipButton"; unequipButton.Size=buttonSize; unequipButton.Position=buttonPosition; unequipButton.AnchorPoint=buttonAnchor; unequipButton.BackgroundColor3=Color3.fromRGB(200,80,80); unequipButton.TextColor3=Color3.fromRGB(255,255,255); unequipButton.Font=Enum.Font.SourceSansBold; unequipButton.Text="해제"; unequipButton.TextSize=buttonTextSize; unequipButton.Visible=false; unequipButton.ZIndex=frame.ZIndex+1; unequipButton.Parent=frame
		unequipButton.MouseButton1Click:Connect(function()
			-- <<< 디버그 Print 추가 >>>
			print("TooltipManager: UnequipButton clicked. currentTooltipSlot:", currentTooltipSlot, "unequipItemEvent:", unequipItemEvent)

			if currentTooltipSlot then
				if unequipItemEvent then
					-- <<< 디버그 Print 추가 >>>
					print("TooltipManager: Attempting to fire UnequipItemEvent for slot: " .. tostring(currentTooltipSlot))
					unequipItemEvent:FireServer(currentTooltipSlot) -- 서버에 이벤트 발동
				else
					-- <<< 디버그 Print 추가 >>>
					warn("TooltipManager: Cannot fire UnequipItemEvent because the reference is nil!")
				end
				TooltipManager.HideTooltip() -- 툴팁 숨기기
			else
				-- <<< 디버그 Print 추가 >>>
				warn("TooltipManager: Unequip button clicked but currentTooltipSlot is nil.")
			end
		end)
		-- <<< 해제 버튼 로직 끝 >>>

		local closeTooltipButton = Instance.new("TextButton"); closeTooltipButton.Name="CloseTooltipButton"; closeTooltipButton.Size=UDim2.new(0,20,0,20); closeTooltipButton.Position=UDim2.new(1,-2,0,2); closeTooltipButton.AnchorPoint=Vector2.new(1,0); closeTooltipButton.BackgroundColor3=Color3.fromRGB(180,60,60); closeTooltipButton.TextColor3=Color3.fromRGB(255,255,255); closeTooltipButton.Font=Enum.Font.SourceSansBold; closeTooltipButton.Text="X"; closeTooltipButton.TextSize=12; closeTooltipButton.ZIndex=frame.ZIndex+1; closeTooltipButton.Parent=frame
		closeTooltipButton.MouseButton1Click:Connect(function() TooltipManager.HideTooltip() end)
		TooltipManager.tooltipFrame = frame
		print("TooltipManager: Tooltip Frame Created successfully inside pcall.")
	end)
	if not success then warn("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"); warn("TooltipManager.CreateTooltipFrame 내부에서 오류 발생!", err); warn("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!") end
	print("TooltipManager: CreateTooltipFrame 함수 종료.")
end

-- 툴팁 표시 함수 (강화 스탯 표시 및 버튼 로직 수정 + 슬롯 정보 저장 확인)
function TooltipManager.ShowTooltip(itemInfo, isEquipped, position, context)
	if not TooltipManager.tooltipFrame then warn("TooltipManager.ShowTooltip: Tooltip frame not created yet!"); return end
	if not itemInfo then warn("TooltipManager.ShowTooltip: Invalid itemInfo received!"); return end
	context = context or "Inventory" -- 기본 컨텍스트

	local baseItemInfo = ItemDatabase.GetItemInfo(itemInfo.ID) -- GetItemInfo 사용
	if not baseItemInfo then warn("TooltipManager.ShowTooltip: Base item info not found in ItemDatabase for ID:", itemInfo.ID); return end

	local frame = TooltipManager.tooltipFrame
	local itemImage = frame:FindFirstChild("TooltipItemImage"); local textLabel = frame:FindFirstChild("TooltipText"); local useButton = frame:FindFirstChild("UseButton"); local equipButton = frame:FindFirstChild("EquipButton"); local unequipButton = frame:FindFirstChild("UnequipButton")
	if not textLabel or not useButton or not equipButton or not unequipButton or not itemImage then warn("TooltipManager.ShowTooltip: Tooltip internal elements not found!"); return end

	currentTooltipItemId = itemInfo.ID
	-- *** 수정: 해제 버튼을 위해 슬롯 정보 저장 (isEquipped 확인) ***
	currentTooltipSlot = isEquipped and itemInfo.Slot or nil
	print("TooltipManager.ShowTooltip: Set currentTooltipSlot to:", currentTooltipSlot, "(isEquipped:", isEquipped, ", itemInfo.Slot:", itemInfo.Slot, ")") -- 슬롯 정보 저장 확인

	-- 아이템 이름 (+ 강화 레벨)
	local itemNameText = itemInfo.Name
	local currentLevel = itemInfo.enhancementLevel or 0
	if baseItemInfo.Enhanceable and currentLevel > 0 then
		itemNameText = string.format("%s (+%d)", itemInfo.Name, currentLevel)
	end
	local tooltipText = string.format("**%s**\n", itemNameText);

	tooltipText = tooltipText .. string.format("<font color='#AAAAAA'>%s</font>\n", itemInfo.Description or "")

	-- 등급
	local rating = itemInfo.Rating or "Common"; local ratingColor = RATING_COLORS[rating] or DEFAULT_RATING_COLOR; local ratingColorHex = string.format("#%02X%02X%02X", ratingColor.R*255, ratingColor.G*255, ratingColor.B*255)
	tooltipText = tooltipText .. string.format("\n<font color='%s'>등급: %s</font>", ratingColorHex, rating)

	-- 소모품/열매 효과 (동일)
	if itemInfo.Type == "Consumable" and itemInfo.Effect then local effectText = ""; if itemInfo.Effect.Stat == "HP" then effectText = "HP "..itemInfo.Effect.Value.." 회복" elseif itemInfo.Effect.Stat == "MP" then effectText = "MP "..itemInfo.Effect.Value.." 회복" elseif itemInfo.Effect.Stat == "HPMP" then effectText = "HP/MP "..itemInfo.Effect.Value.." 회복" end; if effectText ~= "" then tooltipText = tooltipText .. string.format("\n<font color='#88FF88'>효과: %s</font>", effectText) end end
	if itemInfo.Type == "DevilFruit" and itemInfo.Effect == "GrantDevilFruit" and itemInfo.FruitID then local DevilFruitDatabase = require(Modules:WaitForChild("DevilFruitDatabase")); local fruitInfo = DevilFruitDatabase and DevilFruitDatabase.GetFruitInfo(itemInfo.FruitID); local effectText = "효과: " .. (fruitInfo and fruitInfo.Description or "특별한 능력을 얻는다."); tooltipText = tooltipText .. string.format("\n<font color='#88FF88'>%s</font>", effectText) end

	-- 장비 효과 (강화 수치 계산 포함 - 이전 수정 유지)
	if itemInfo.Type == "Equipment" then
		local statsText = "\n<font color='#87CEEB'>장비 효과:</font>"
		local statAdded = false
		local displayedStats = {}
		if itemInfo.Stats then
			for statName, baseValue in pairs(itemInfo.Stats) do
				if baseValue ~= 0 then
					local currentValue = baseValue; local isEnhancedStat = false
					if baseItemInfo.Enhanceable and currentLevel > 0 then local enhanceStat = baseItemInfo.EnhanceStat; local valuePerLevel = baseItemInfo.EnhanceValuePerLevel or 0; if enhanceStat and enhanceStat == statName then local enhancementBonus = valuePerLevel * currentLevel; currentValue = baseValue + enhancementBonus; isEnhancedStat = true end end
					local displayName = STAT_DISPLAY_NAMES[statName] or statName; local valueString = ""; if currentValue > 0 then valueString = "+" .. tostring(currentValue) else valueString = tostring(currentValue) end; if statName:find("Rate") or statName:find("Chance") or statName:find("Damage") then valueString = valueString .. "%" end
					local colorTag = isEnhancedStat and "<font color='#90EE90'>" or ""; local endColorTag = isEnhancedStat and "</font>" or ""
					statsText = statsText .. string.format("\n  %s%s %s%s", colorTag, displayName, valueString, endColorTag); displayedStats[statName] = true; statAdded = true
				end
			end
		end
		if baseItemInfo.Enhanceable and currentLevel > 0 then local enhanceStat = baseItemInfo.EnhanceStat; if enhanceStat and not displayedStats[enhanceStat] then local valuePerLevel = baseItemInfo.EnhanceValuePerLevel or 0; local enhancementBonus = valuePerLevel * currentLevel; if enhancementBonus ~= 0 then local displayName = STAT_DISPLAY_NAMES[enhanceStat] or enhanceStat; local valueString = ""; if enhancementBonus > 0 then valueString = "+" .. tostring(enhancementBonus) else valueString = tostring(enhancementBonus) end; if enhanceStat:find("Rate") or enhanceStat:find("Chance") or enhanceStat:find("Damage") then valueString = valueString .. "%" end; local colorTag = "<font color='#90EE90'>"; local endColorTag = "</font>"; statsText = statsText .. string.format("\n  %s%s %s%s (강화)", colorTag, displayName, valueString, endColorTag); statAdded = true end end end
		if statAdded then tooltipText = tooltipText .. statsText end
	end

	-- 아이템 타입 (동일)
	if itemInfo.Type == "Equipment" then local typeText = string.format("\n<font color='#BBBBFF'>타입: 장비 (%s)</font>", itemInfo.Slot or "알 수 없음"); if baseItemInfo.WeaponType then typeText = typeText .. string.format("\n<font color='#FFBBBB'>무기 종류: %s</font>", baseItemInfo.WeaponType) end; tooltipText = tooltipText .. typeText elseif itemInfo.Type == "Consumable" then tooltipText = tooltipText .. "\n<font color='#FFBBBB'>타입: 소모품</font>" elseif itemInfo.Type == "DevilFruit" then tooltipText = tooltipText .. "\n<font color='#FFD700'>타입: 악마의 열매</font>" end

	textLabel.Text = tooltipText
	if itemInfo.ImageId and itemInfo.ImageId ~= "" then itemImage.Image = itemInfo.ImageId; itemImage.Visible = true else itemImage.Visible = false end

	-- *** 버튼 가시성 로직 수정 ***
	useButton.Visible = false
	equipButton.Visible = false
	unequipButton.Visible = false

	if itemInfo.Type == "Consumable" then
		if context == "Inventory" then useButton.Visible = true; useButton.Text = "사용" end
	elseif itemInfo.Type == "DevilFruit" then
		if context == "Inventory" then useButton.Visible = true; useButton.Text = "먹기" end
	elseif itemInfo.Type == "Equipment" then
		if isEquipped then -- 장비 슬롯에서 열었거나 이미 장착된 아이템 툴팁이면
			if currentTooltipSlot then -- 해제할 슬롯 정보가 있으면
				unequipButton.Visible = true -- '해제' 버튼 표시
			else
				warn("TooltipManager: Cannot show unequip button because currentTooltipSlot is nil (for equipped item).")
			end
		else -- 인벤토리에서 열었으면
			equipButton.Visible = true -- '장착' 버튼 표시
		end
	end
	-- *** 버튼 가시성 로직 수정 끝 ***


	-- 툴팁 위치 조정 (동일)
	if typeof(position) == "Vector2" then local tooltipSize = frame.AbsoluteSize; local screenWidth = frame.Parent.AbsoluteSize.X; local screenHeight = frame.Parent.AbsoluteSize.Y; local xPos = position.X + 15; local yPos = position.Y + 15; if xPos + tooltipSize.X > screenWidth then xPos = position.X - tooltipSize.X - 15 end; if yPos + tooltipSize.Y > screenHeight then yPos = position.Y - tooltipSize.Y - 15 end; frame.Position = UDim2.fromOffset(math.max(0, xPos), math.max(0, yPos)) end

	frame.Visible = true
end

-- 툴팁 숨기기 함수 (동일)
function TooltipManager.HideTooltip()
	if TooltipManager.tooltipFrame then TooltipManager.tooltipFrame.Visible = false; local useButton=TooltipManager.tooltipFrame:FindFirstChild("UseButton"); local equipButton=TooltipManager.tooltipFrame:FindFirstChild("EquipButton"); local unequipButton=TooltipManager.tooltipFrame:FindFirstChild("UnequipButton"); if useButton then useButton.Visible=false end; if equipButton then equipButton.Visible=false end; if unequipButton then unequipButton.Visible=false end; currentTooltipItemId=nil; currentTooltipSlot=nil end
end

return TooltipManager