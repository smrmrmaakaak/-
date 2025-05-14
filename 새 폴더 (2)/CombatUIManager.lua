-- CombatUIManager.lua

--[[
  CombatUIManager (ModuleScript)
  전투 관련 UI 요소들을 관리하고 업데이트하는 모듈 (클라이언트 측).
  *** [수정] OnCombatEnded에서 UIBuilder가 생성한 고정틀은 제거하지 않고 내용만 초기화하도록 변경 ***
  *** [수정] OnCombatStarted에서 고정틀을 재참조하고 데이터 채우도록 수정 ***
  *** [버그 수정] UpdatePartyMemberStatus에서 InnerLayout 참조 추가 ***
  *** [버그 수정] OnCombatStarted에서 companionCharacterImages 키 값 수정 (instanceId 사용) ***
  *** [버그 수정] OnCombatStarted의 동료 정보 업데이트 루프에서 companionUIFrames 참조 방식 수정 ***
  *** [버그 수정] 전투 시작 시 동료 정보 즉시 표시를 위한 combatUIFullyInitialized 플래그 추가 ***
  *** [기능 추가] 동료에게 아이템 사용을 위한 아군 타겟팅 로직 추가 시작 ***
]]
local CombatUIManager = {}

-- 필요한 서비스 및 모듈 로드
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainGui = playerGui:WaitForChild("MainGui")

local ModuleManager
local CoreUIManager
local PlayerData
local SkillDatabase
local ItemDatabase
local EnemyDatabase
local GuiUtils
local SoundManager
local TooltipManager
local CompanionDatabase

local RequestSkillListEvent
local ReceiveSkillListEvent
local getPlayerInventoryFunction
local requestPlayerAttackEvent
local requestPlayerUseSkillEvent

-- 이벤트 참조
local combatStartedEvent
local combatEndedEvent
local playerTurnEvent
local enemyTurnEvent
local combatLogEvent
local updateCombatUIEvent
local combatDamageEvent
local requestPlayerUseItemEvent -- 이미 참조하고 있음

-- 상태 이상 아이콘 정보
local StatusEffectIcons = {
	["Busoshoku"] = "rbxassetid://144018315083897", ["Kenbunshoku"] = "rbxassetid://144018341074659",
	["Regen"] = "rbxassetid://144018364234243", ["Poison"] = "rbxassetid://144018382009546",
	["Burn"] = "rbxassetid://144018399696878", ["AttackDown"] = "rbxassetid://144018416214874",
	["DefenseDown"] = "rbxassetid://144018435238478", ["Defending"] = "rbxassetid://YOUR_DEFEND_ICON_ID", 
	["Default"] = "rbxassetid://144018458653033"
}

local ATTACK_EFFECT_IMAGE_ID = "rbxassetid://122821729104808"
CombatUIManager.ATTACK_SFX_ID = "rbxassetid://8899349982"
local COMBAT_BGM_ID = "rbxassetid://114370744499905"

local playerCharacterImage = nil
local enemyAreaFrame = nil
local enemyUITemplate = nil
local skillEffectImage = nil
local combatLogFrame = nil
local skillSelectionFrame = nil
local skillList = nil
local combatLogLayout = nil
local actionMenuFrame = nil
local partyStatusFrame = nil
local combatItemSelectionFrame = nil
local combatItemList = nil
local enemyUIFrames = {}
local companionUIFrames = {} 
local companionCharacterImages = {} 

local isTargeting = false -- 적 대상 선택 상태
local currentActionType = nil
local currentSkillIdForTargeting = nil
local combatUIFullyInitialized = false

-- ##### [기능 추가] 아이템 사용을 위한 아군 타겟팅 상태 변수 #####
local isAllyTargetingForItem = false
local currentItemIdForAllyTargeting = nil
local allyTargetButtons = {} -- 생성된 아군 타겟팅 버튼 저장
-- ########################################################

function CombatUIManager.Init()
	ModuleManager = require(ReplicatedStorage.Modules:WaitForChild("ModuleManager"))
	CoreUIManager = ModuleManager:GetModule("CoreUIManager")
	PlayerData = ModuleManager:GetModule("PlayerData")
	SkillDatabase = ModuleManager:GetModule("SkillDatabase")
	ItemDatabase = ModuleManager:GetModule("ItemDatabase")
	EnemyDatabase = ModuleManager:GetModule("EnemyDatabase")
	GuiUtils = ModuleManager:GetModule("GuiUtils")
	SoundManager = ModuleManager:GetModule("SoundManager")
	TooltipManager = ModuleManager:GetModule("TooltipManager")
	CompanionDatabase = ModuleManager:GetModule("CompanionDatabase") 

	RequestSkillListEvent = ReplicatedStorage:WaitForChild("RequestSkillListEvent")
	ReceiveSkillListEvent = ReplicatedStorage:WaitForChild("ReceiveSkillListEvent")
	combatStartedEvent = ReplicatedStorage:WaitForChild("CombatStartedEvent")
	combatEndedEvent = ReplicatedStorage:WaitForChild("CombatEndedEvent")
	playerTurnEvent = ReplicatedStorage:WaitForChild("PlayerTurnEvent")
	enemyTurnEvent = ReplicatedStorage:WaitForChild("EnemyTurnEvent")
	combatLogEvent = ReplicatedStorage:WaitForChild("CombatLogEvent")
	updateCombatUIEvent = ReplicatedStorage:WaitForChild("UpdateCombatUIEvent")
	combatDamageEvent = ReplicatedStorage:WaitForChild("CombatDamageEvent")
	requestPlayerUseItemEvent = ReplicatedStorage:WaitForChild("RequestPlayerUseItemEvent")
	getPlayerInventoryFunction = ReplicatedStorage:WaitForChild("GetPlayerInventoryFunction")
	requestPlayerAttackEvent = ReplicatedStorage:WaitForChild("RequestPlayerAttackEvent")
	requestPlayerUseSkillEvent = ReplicatedStorage:WaitForChild("RequestPlayerUseSkillEvent")

	combatStartedEvent.OnClientEvent:Connect(CombatUIManager.OnCombatStarted)
	combatEndedEvent.OnClientEvent:Connect(CombatUIManager.OnCombatEnded)
	playerTurnEvent.OnClientEvent:Connect(CombatUIManager.OnPlayerTurn)
	enemyTurnEvent.OnClientEvent:Connect(CombatUIManager.OnEnemyTurn)
	combatLogEvent.OnClientEvent:Connect(CombatUIManager.AddCombatLogMessage)
	updateCombatUIEvent.OnClientEvent:Connect(CombatUIManager.OnUpdateCombatUI)
	combatDamageEvent.OnClientEvent:Connect(CombatUIManager.OnCombatDamage)
	if ReceiveSkillListEvent then ReceiveSkillListEvent.OnClientEvent:Connect(CombatUIManager.OnReceiveSkillList); print("CombatUIManager: ReceiveSkillListEvent.OnClientEvent connected.") else warn("CombatUIManager: ReceiveSkillListEvent not found!") end

	print("CombatUIManager: Initialized and events connected.")
end

local function AnimateAttack(guiObject)
	if not guiObject or not guiObject:IsA("GuiObject") then return end
	local originalPosition = guiObject.Position
	local originalSize = guiObject.Size
	local moveOffset = UDim2.new(0, 20, 0, 0)
	if guiObject:FindFirstAncestorWhichIsA("Frame") and guiObject.Parent.Name:match("^Enemy_") then
		moveOffset = UDim2.new(0, -20, 0, 0)
	elseif guiObject.Name:match("^CompanionCharacterImage_") then
		moveOffset = UDim2.new(0, 15, 0, 0)
	end
	local scaleMultiplier = 1.1
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, 0, true)
	local tweenForward = TweenService:Create(guiObject, tweenInfo, {
		Position = originalPosition + moveOffset,
		Size = UDim2.new(originalSize.X.Scale * scaleMultiplier, originalSize.X.Offset, originalSize.Y.Scale * scaleMultiplier, originalSize.Y.Offset)
	})
	tweenForward:Play()
end

function CombatUIManager.AnimateHit(characterImage)
	if not characterImage or not characterImage:IsA("ImageLabel") then return end
	local hitOverlay = characterImage:FindFirstChild("HitOverlay")
	if not hitOverlay or not hitOverlay:IsA("Frame") then
		hitOverlay = Instance.new("Frame"); hitOverlay.Name = "HitOverlay"; hitOverlay.Size = UDim2.new(1,0,1,0); hitOverlay.Position = UDim2.new(0,0,0,0); hitOverlay.BackgroundColor3 = Color3.fromRGB(255,50,50); hitOverlay.BackgroundTransparency = 1; hitOverlay.ZIndex = characterImage.ZIndex + 1; hitOverlay.Parent = characterImage
	end
	local tweenInfo = TweenInfo.new(0.2, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, 1, true, 0)
	local goal = { BackgroundTransparency = 0.5 }; local existingTween = hitOverlay:FindFirstChild("HitTween")
	if existingTween and existingTween:IsA("Tween") then existingTween:Cancel(); existingTween:Destroy() end
	hitOverlay.BackgroundTransparency = 1; local hitTween = TweenService:Create(hitOverlay, tweenInfo, goal)
	hitTween.Name = "HitTween"; hitTween.Parent = hitOverlay; hitTween:Play()
	hitTween.Completed:Connect(function() pcall(function() if hitTween and hitTween.Parent then hitTween:Destroy() end end) end)
end

function CombatUIManager.ShowSkillEffect(skillId, targetInstanceId)
	local currentCombatScreen = playerGui:FindFirstChild("MainGui") and playerGui.MainGui:FindFirstChild("BackgroundFrame") and playerGui.MainGui.BackgroundFrame:FindFirstChild("Frames") and playerGui.MainGui.BackgroundFrame.Frames:FindFirstChild("CombatScreen")
	if not currentCombatScreen then warn("ShowSkillEffect: CombatScreen 없음."); return end
	local currentSkillEffectImage = currentCombatScreen:FindFirstChild("SkillEffectImage")
	if not currentSkillEffectImage then warn("ShowSkillEffect: SkillEffectImage 없음!"); return end
	if not SkillDatabase or not SkillDatabase.Skills then warn("ShowSkillEffect: SkillDatabase 사용 불가."); return end
	local skillInfo = SkillDatabase.Skills[skillId]; if not skillInfo or not skillInfo.EffectImageId or skillInfo.EffectImageId == "" then return end
	if not currentSkillEffectImage or not currentSkillEffectImage:IsA("ImageLabel") then warn("ShowSkillEffect: skillEffectImage 참조 유효하지 않음!"); return end
	currentSkillEffectImage.Image = skillInfo.EffectImageId; local targetPosition = nil
	if skillInfo.Target == "SELF" then if playerCharacterImage then targetPosition = playerCharacterImage.Position - UDim2.new(0, 0, playerCharacterImage.Size.Y.Scale * 0.5, 0) end
	elseif skillInfo.Target == "ENEMY_SINGLE" and targetInstanceId then local targetEnemyUI = enemyUIFrames[targetInstanceId]; if targetEnemyUI then local enemyImage = targetEnemyUI:FindFirstChild("EnemyImage"); if enemyImage then local screenPos = enemyImage.AbsolutePosition; local screenParentPos = currentCombatScreen.AbsolutePosition; local relativePos = screenPos - screenParentPos + Vector2.new(enemyImage.AbsoluteSize.X / 2, -enemyImage.AbsoluteSize.Y / 2); targetPosition = UDim2.fromOffset(relativePos.X, relativePos.Y) end end
	elseif skillInfo.Target == "ALLY_SINGLE" and targetInstanceId then local targetCompanionImage = companionCharacterImages[targetInstanceId]; if targetCompanionImage then local screenPos = targetCompanionImage.AbsolutePosition; local screenParentPos = currentCombatScreen.AbsolutePosition; local relativePos = screenPos - screenParentPos + Vector2.new(targetCompanionImage.AbsoluteSize.X / 2, -targetCompanionImage.AbsoluteSize.Y / 2); targetPosition = UDim2.fromOffset(relativePos.X, relativePos.Y) end end
	if not targetPosition then targetPosition = UDim2.new(0.5, 0, 0.4, 0) end
	currentSkillEffectImage.Position = targetPosition; currentSkillEffectImage.Visible = true; currentSkillEffectImage.ImageTransparency = 1; currentSkillEffectImage.Rotation = math.random(-15, 15)
	local appearDuration = 0.1; local stayDuration = 0.4; local fadeDuration = 0.5
	local tweenInfoAppear = TweenInfo.new(appearDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out); local tweenInfoFade = TweenInfo.new(fadeDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, stayDuration)
	local originalSize = currentSkillEffectImage.Size; currentSkillEffectImage.Size = UDim2.new(originalSize.X.Scale * 0.8, originalSize.X.Offset, originalSize.Y.Scale * 0.8, originalSize.Y.Offset)
	local appearTween = TweenService:Create(currentSkillEffectImage, tweenInfoAppear, { ImageTransparency = 0, Size = originalSize }); local fadeTween = TweenService:Create(currentSkillEffectImage, tweenInfoFade, { ImageTransparency = 1 })
	appearTween:Play(); appearTween.Completed:Connect(function() fadeTween:Play() end); fadeTween.Completed:Connect(function() currentSkillEffectImage.Visible = false end)
end

function CombatUIManager.ShowAttackEffect(targetInstanceId, isCompanionAttacker, attackerInstanceId)
	local currentCombatScreen = playerGui:FindFirstChild("MainGui") and playerGui.MainGui:FindFirstChild("BackgroundFrame") and playerGui.MainGui.BackgroundFrame:FindFirstChild("Frames") and playerGui.MainGui.BackgroundFrame.Frames:FindFirstChild("CombatScreen")
	if not currentCombatScreen then warn("ShowAttackEffect: CombatScreen 없음."); return end
	local currentSkillEffectImage = currentCombatScreen:FindFirstChild("SkillEffectImage")
	if not currentSkillEffectImage then warn("ShowAttackEffect: SkillEffectImage (for attack) 없음!"); return end
	if not ATTACK_EFFECT_IMAGE_ID or ATTACK_EFFECT_IMAGE_ID == "" then warn("ShowAttackEffect: ATTACK_EFFECT_IMAGE_ID 설정 안됨!"); return end
	if not currentSkillEffectImage or not currentSkillEffectImage:IsA("ImageLabel") then warn("ShowAttackEffect: skillEffectImage 참조 유효하지 않음!"); return end
	currentSkillEffectImage.Image = ATTACK_EFFECT_IMAGE_ID; local targetPosition = UDim2.new(0.5, 0, 0.4, 0)
	if targetInstanceId then
		local targetUI = enemyUIFrames[targetInstanceId]
		if targetUI then local imageToPositionOver = targetUI:FindFirstChild("EnemyImage"); if imageToPositionOver then local screenPos = imageToPositionOver.AbsolutePosition; local screenParentPos = currentCombatScreen.AbsolutePosition; local relativePos = screenPos - screenParentPos + Vector2.new(imageToPositionOver.AbsoluteSize.X / 2, -imageToPositionOver.AbsoluteSize.Y / 2); targetPosition = UDim2.fromOffset(relativePos.X, relativePos.Y) end
		elseif playerCharacterImage and targetInstanceId == player.UserId then local screenPos = playerCharacterImage.AbsolutePosition; local screenParentPos = currentCombatScreen.AbsolutePosition; local relativePos = screenPos - screenParentPos + Vector2.new(playerCharacterImage.AbsoluteSize.X / 2, -playerCharacterImage.AbsoluteSize.Y / 2); targetPosition = UDim2.fromOffset(relativePos.X, relativePos.Y)
		elseif companionCharacterImages[targetInstanceId] then local compImg = companionCharacterImages[targetInstanceId]; local screenPos = compImg.AbsolutePosition; local screenParentPos = currentCombatScreen.AbsolutePosition; local relativePos = screenPos - screenParentPos + Vector2.new(compImg.AbsoluteSize.X / 2, -compImg.AbsoluteSize.Y / 2); targetPosition = UDim2.fromOffset(relativePos.X, relativePos.Y) end
	end
	currentSkillEffectImage.Position = targetPosition; currentSkillEffectImage.Visible = true; currentSkillEffectImage.ImageTransparency = 1; currentSkillEffectImage.Rotation = math.random(-5, 5)
	local appearDuration = 0.05; local stayDuration = 0.2; local fadeDuration = 0.3;
	local tweenInfoAppear = TweenInfo.new(appearDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out); local tweenInfoFade = TweenInfo.new(fadeDuration, Enum.EasingStyle.Linear, Enum.EasingDirection.In, 0, false, stayDuration)
	local originalSize = currentSkillEffectImage.Size; currentSkillEffectImage.Size = UDim2.new(originalSize.X.Scale * 0.9, originalSize.X.Offset, originalSize.Y.Scale * 0.9, originalSize.Y.Offset)
	local appearTween = TweenService:Create(currentSkillEffectImage, tweenInfoAppear, { ImageTransparency = 0, Size = originalSize }); local fadeTween = TweenService:Create(currentSkillEffectImage, tweenInfoFade, { ImageTransparency = 1 })
	appearTween:Play(); appearTween.Completed:Connect(function() fadeTween:Play() end); fadeTween.Completed:Connect(function() currentSkillEffectImage.Visible = false end)
end

local function UpdateStatusIcons(statusFrame, effectsTable)
	if not statusFrame then return end
	local layout = statusFrame:FindFirstChildOfClass("UIListLayout")
	if not layout then layout = Instance.new("UIListLayout"); layout.FillDirection = Enum.FillDirection.Horizontal; layout.HorizontalAlignment = Enum.HorizontalAlignment.Center; layout.VerticalAlignment = Enum.VerticalAlignment.Center; layout.Padding = UDim.new(0, 2); layout.Parent = statusFrame end
	for _, child in ipairs(statusFrame:GetChildren()) do if child:IsA("ImageLabel") then child:Destroy() end end
	if not effectsTable or #effectsTable == 0 then return end
	local iconSize = UDim2.new(0, 16, 0, 16)
	for i, effectData in ipairs(effectsTable) do
		if not effectData or typeof(effectData) ~= "table" or not effectData.id or not effectData.duration then warn("UpdateStatusIcons: 유효하지 않은 효과 데이터:", effectData)
		else
			local iconImageId = StatusEffectIcons[effectData.id] or StatusEffectIcons["Default"]
			local iconLabel = Instance.new("ImageLabel"); iconLabel.Name = effectData.id .. "_Icon"; iconLabel.Size = iconSize; iconLabel.Image = iconImageId; iconLabel.BackgroundTransparency = 1; iconLabel.ScaleType = Enum.ScaleType.Fit; iconLabel.LayoutOrder = i; iconLabel.Parent = statusFrame
			local tooltipText = string.format("%s (%d턴 남음)", effectData.id, effectData.duration)
			iconLabel.MouseEnter:Connect(function() 
				if TooltipManager and TooltipManager.ShowTooltip then
					-- 임시 툴팁 아이템 정보 생성
					local fakeItemInfo = {
						Name = effectData.id,
						Description = string.format("지속시간: %d턴 남음\n(효과 상세 설명은 여기에 추가)", effectData.duration),
						Rating = "Common", -- 또는 효과 등급
						ImageId = iconImageId -- 상태 아이콘 표시
					}
					TooltipManager.ShowTooltip(fakeItemInfo, false, UserInputService:GetMouseLocation(), "StatusEffect")
				end
			end)
			iconLabel.MouseLeave:Connect(function() 
				if TooltipManager and TooltipManager.HideTooltip then
					TooltipManager.HideTooltip()
				end
			end)
		end
	end
end

function CombatUIManager.UpdatePartyMemberStatus(memberType, id, memberData)
	if memberType == "Companion" then
		print(string.format("UpdatePartyMemberStatus for Companion ID: %s", tostring(id)))
		if memberData then
			print(string.format("  MemberData received: Name=%s, HP=%s, MaxHP=%s, MP=%s, MaxMP=%s, TP=%s",
				tostring(memberData.name), tostring(memberData.hp), tostring(memberData.maxHp),
				tostring(memberData.mp), tostring(memberData.maxMp), tostring(memberData.tp)
				))
			if memberData.effects then
				print(string.format("  MemberData Effects Count: %d", #memberData.effects))
			end
		else
			print("  MemberData is nil")
		end
	end

	if not partyStatusFrame then
		local currentCombatScreen = playerGui:FindFirstChild("MainGui") and playerGui.MainGui:FindFirstChild("BackgroundFrame") and playerGui.MainGui.BackgroundFrame:FindFirstChild("Frames") and playerGui.MainGui.BackgroundFrame.Frames:FindFirstChild("CombatScreen")
		local bottomUI = currentCombatScreen and currentCombatScreen:FindFirstChild("BottomUIArea")
		partyStatusFrame = bottomUI and bottomUI:FindFirstChild("PartyStatusFrame")
	end
	if not partyStatusFrame then warn("UpdatePartyMemberStatus: partyStatusFrame 없음!"); return end

	local memberFrameToUpdate = nil
	local isPlayer = (memberType == "Player")

	if isPlayer then
		memberFrameToUpdate = partyStatusFrame:FindFirstChild("PartySlot_Player")
	else 
		if companionUIFrames[id] and companionUIFrames[id].Frame then
			memberFrameToUpdate = companionUIFrames[id].Frame
		else
			if combatUIFullyInitialized then 
				warn("UpdatePartyMemberStatus (UI Initialized): memberFrameToUpdate를 찾지 못함 (동료): ID:", tostring(id), "companionUIFrames entry:", companionUIFrames[id])
			end
			return 
		end
	end

	if not memberFrameToUpdate then
		warn("UpdatePartyMemberStatus: memberFrameToUpdate를 최종적으로 찾지 못함: Type:", memberType, "ID:", tostring(id))
		return
	end

	local innerLayout = memberFrameToUpdate:FindFirstChild("InnerLayout")
	if not innerLayout then
		warn("UpdatePartyMemberStatus: InnerLayout Frame을 찾을 수 없습니다 in:", memberFrameToUpdate.Name)
		return
	end

	local nameLabel = innerLayout:FindFirstChild("CompanionNameLabel")
	local hpLabel = innerLayout:FindFirstChild("HPLabel")
	local mpLabel = innerLayout:FindFirstChild("MPLabel")
	local tpLabel = innerLayout:FindFirstChild("TPLabel")
	local statusFrame = memberFrameToUpdate:FindFirstChild("StatusEffectsFrame")

	if nameLabel and memberData.name then nameLabel.Text = memberData.name end
	if hpLabel and memberData.hp ~= nil and memberData.maxHp ~= nil then hpLabel.Text = string.format("HP: %d/%d", math.floor(memberData.hp), math.floor(memberData.maxHp)) else if hpLabel then hpLabel.Text = "HP: -/-" end end
	if mpLabel and memberData.mp ~= nil and memberData.maxMp ~= nil then mpLabel.Text = string.format("MP: %d/%d", math.floor(memberData.mp), math.floor(memberData.maxMp)) else if mpLabel then mpLabel.Text = "MP: -/-" end end
	if tpLabel then
		if isPlayer and PlayerData then
			local pStats = PlayerData.GetStats(player)
			if pStats and pStats.CurrentTP ~= nil then tpLabel.Text = string.format("TP: %d", math.floor(pStats.CurrentTP)) else tpLabel.Text = "TP: -" end
		elseif memberData.tp ~= nil then
			tpLabel.Text = string.format("TP: %d", math.floor(memberData.tp))
		else
			tpLabel.Text = "TP: -"
		end
	end
	if statusFrame and memberData.effects then UpdateStatusIcons(statusFrame, memberData.effects) else if statusFrame then UpdateStatusIcons(statusFrame, {}) end end
end

function CombatUIManager.UpdateSingleEnemyInfo(instanceId, enemyData)
	local enemyUI = enemyUIFrames[instanceId]
	if not enemyUI then return end
	local infoContainer = enemyUI:FindFirstChild("InfoContainer"); if not infoContainer then warn("UpdateSingleEnemyInfo: InfoContainer 없음 enemy:", instanceId); return end
	local nameLabel = infoContainer:FindFirstChild("NameLabel"); local hpBarBG = infoContainer:FindFirstChild("HPBarBackground"); local hpLabel = hpBarBG and hpBarBG:FindFirstChild("HPLabel"); local hpBar = hpBarBG and hpBarBG:FindFirstChild("HPBar"); local enemyImage = enemyUI:FindFirstChild("EnemyImage"); local targetButton = enemyUI:FindFirstChild("TargetButton")
	local statusFrame = infoContainer:FindFirstChild("StatusEffectsFrame")

	if nameLabel and enemyData.name then nameLabel.Text = enemyData.name end
	local currentHP = enemyData.hp; local maxHP = enemyData.maxHp or 1
	if hpLabel then local displayHP = currentHP; if displayHP == nil then displayHP = maxHP end; hpLabel.Text = string.format("%d/%d", math.floor(displayHP), math.floor(maxHP)) end
	if hpBar then if maxHP > 0 and currentHP ~= nil then hpBar.Size = UDim2.new(math.clamp(currentHP / maxHP, 0, 1), 0, 1, 0) else hpBar.Size = UDim2.new(1, 0, 1, 0) end end
	if enemyImage and enemyData.imageId then enemyImage.Image = enemyData.imageId end
	if statusFrame and enemyData.effects then UpdateStatusIcons(statusFrame, enemyData.effects) end

	local isDead = false; if currentHP ~= nil and currentHP <= 0 then isDead = true end
	if isDead then if enemyImage then enemyImage.ImageColor3 = Color3.fromRGB(100, 100, 100); enemyImage.ImageTransparency = 0.5 end; if targetButton then targetButton.Selectable = false; targetButton.Visible = false; targetButton.Active = false end; enemyUI.BackgroundTransparency = 1
	else if enemyImage then enemyImage.ImageColor3 = Color3.new(1, 1, 1); enemyImage.ImageTransparency = 0 end; if targetButton then targetButton.Selectable = true; targetButton.Visible = isTargeting; targetButton.Active = isTargeting end; if isTargeting then enemyUI.BackgroundColor3 = Color3.fromRGB(255, 255, 100); enemyUI.BackgroundTransparency = 0.7 else enemyUI.BackgroundTransparency = 1 end end
end

function CombatUIManager.EnableActionButtons(enable)
	if isTargeting and enable then enable = false end
	-- ##### [기능 추가] 아군 타겟팅 중일 때도 액션 버튼 비활성화 #####
	if isAllyTargetingForItem and enable then enable = false end
	-- ########################################################
	if not actionMenuFrame then local backgroundFrame = mainGui:FindFirstChild("BackgroundFrame"); local currentCombatScreen = backgroundFrame and backgroundFrame:FindFirstChild("Frames") and backgroundFrame.Frames:FindFirstChild("CombatScreen"); local bottomUI = currentCombatScreen and currentCombatScreen:WaitForChild("BottomUIArea", 1); actionMenuFrame = bottomUI and bottomUI:WaitForChild("ActionMenuFrame", 1) end
	if not actionMenuFrame then warn("EnableActionButtons: ActionMenuFrame 없음!"); return end
	local attackButton = actionMenuFrame:WaitForChild("AttackButton", 0.5); local skillButton = actionMenuFrame:WaitForChild("SkillButton", 0.5); local defendButton = actionMenuFrame:WaitForChild("DefendButton", 0.5); local itemButton = actionMenuFrame:WaitForChild("ItemButton", 0.5)
	if attackButton and attackButton:IsA("TextButton") then attackButton.Selectable = enable; attackButton.BackgroundColor3 = enable and Color3.fromRGB(180, 70, 70) or Color3.fromRGB(100, 100, 100) end
	if skillButton and skillButton:IsA("TextButton") then skillButton.Selectable = enable; skillButton.BackgroundColor3 = enable and Color3.fromRGB(70, 70, 180) or Color3.fromRGB(100, 100, 100) end
	if defendButton and defendButton:IsA("TextButton") then defendButton.Selectable = enable; defendButton.BackgroundColor3 = enable and Color3.fromRGB(70, 180, 70) or Color3.fromRGB(100, 100, 100) end
	if itemButton and itemButton:IsA("TextButton") then itemButton.Selectable = enable; itemButton.BackgroundColor3 = enable and Color3.fromRGB(180, 180, 70) or Color3.fromRGB(100, 100, 100) end
end

function CombatUIManager.TriggerPlayerActionAnimation()
	if playerCharacterImage then AnimateAttack(playerCharacterImage) else warn("TriggerPlayerActionAnimation: playerCharacterImage 없음.") end
end

function CombatUIManager.TriggerCompanionActionAnimation(companionInstanceId)
	local companionImage = companionCharacterImages[companionInstanceId]
	if companionImage then AnimateAttack(companionImage) else warn("TriggerCompanionActionAnimation: 동료 이미지 없음 instanceId:", companionInstanceId) end
end

function CombatUIManager.TriggerEnemyHitAnimation(instanceId)
	local enemyUI = enemyUIFrames[instanceId]
	if enemyUI then local enemyImage = enemyUI:FindFirstChild("EnemyImage"); if enemyImage then CombatUIManager.AnimateHit(enemyImage) else warn("TriggerEnemyHitAnimation: EnemyImage 없음 instanceId:", instanceId) end
	else warn("TriggerEnemyHitAnimation: UI 없음 enemy instanceId:", instanceId) end
end

function CombatUIManager.TriggerCompanionHitAnimation(companionInstanceId)
	local companionImage = companionCharacterImages[companionInstanceId]
	if companionImage then CombatUIManager.AnimateHit(companionImage) else warn("TriggerCompanionHitAnimation: 동료 이미지 없음 instanceId:", companionInstanceId) end
end

function CombatUIManager.ShowSkillSelection(show)
	if not skillSelectionFrame then local bgFrame = mainGui:FindFirstChild("BackgroundFrame"); skillSelectionFrame = bgFrame and bgFrame:FindFirstChild("SkillSelectionFrame") end
	if not skillSelectionFrame then warn("ShowSkillSelection: SkillSelectionFrame 없음!"); return end
	if show then CombatUIManager.UpdateSkillList(); skillSelectionFrame.Visible = true else skillSelectionFrame.Visible = false end
end

function CombatUIManager.UpdateSkillList()
	if not skillList then if skillSelectionFrame then skillList = skillSelectionFrame:FindFirstChild("SkillList") end end
	if not skillList then warn("UpdateSkillList: SkillList frame 없음!"); return end
	for _, child in ipairs(skillList:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
	if RequestSkillListEvent then RequestSkillListEvent:FireServer() else warn("UpdateSkillList: RequestSkillListEvent 없음!") end
end

function CombatUIManager.OnReceiveSkillList(receivedSkills)
	local currentCombatScreen = playerGui:FindFirstChild("MainGui") and playerGui.MainGui:FindFirstChild("BackgroundFrame") and playerGui.MainGui.BackgroundFrame:FindFirstChild("Frames") and playerGui.MainGui.BackgroundFrame.Frames:FindFirstChild("CombatScreen")
	if not currentCombatScreen or not currentCombatScreen.Visible then warn("OnReceiveSkillList: CombatScreen 준비안됨/안보임. 스킬 목록 채우기 건너뜀."); return end
	if not skillList or not skillSelectionFrame or not SkillDatabase or not SkillDatabase.Skills then warn("OnReceiveSkillList: SkillList, SkillSelectionFrame, 또는 SkillDatabase 사용 불가."); return end
	if typeof(receivedSkills) ~= "table" then warn("OnReceiveSkillList: 잘못된 스킬 목록 데이터 수신:", receivedSkills); receivedSkills = {} end
	for _, child in ipairs(skillList:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
	local order = 1; local playerStats = PlayerData.GetStats(player); local currentMP = playerStats and playerStats.CurrentMP or 0; local playerFruit = playerStats and playerStats.ActiveDevilFruit or nil
	for _, skillId in ipairs(receivedSkills) do
		local skillData = SkillDatabase.Skills[skillId]
		if skillData then
			local skillButton = Instance.new("TextButton"); skillButton.Name = "SkillButton_" .. skillId; local cost = skillData.Cost or 0; skillButton.Text = string.format("%s (MP: %d)", skillData.Name, cost); skillButton.Size = UDim2.new(1, -10, 0, 40)
			local canUseSkill = true; local reason = ""; if currentMP < cost then canUseSkill = false; reason = "MP 부족" end
			if canUseSkill then local requiredFruit = skillData.RequiredFruit; if requiredFruit and requiredFruit ~= "" then if not playerFruit or playerFruit ~= requiredFruit then canUseSkill = false; reason = requiredFruit .. " 능력 필요" end end end
			skillButton.BackgroundColor3 = canUseSkill and Color3.fromRGB(70, 70, 150) or Color3.fromRGB(100, 100, 100); skillButton.TextColor3 = canUseSkill and Color3.new(1, 1, 1) or Color3.fromRGB(180, 180, 180); skillButton.Selectable = canUseSkill; skillButton.TextScaled = true; skillButton.LayoutOrder = order; skillButton.Parent = skillList
			if canUseSkill then skillButton.MouseButton1Click:Connect(function() CombatUIManager.ShowSkillSelection(false); CombatUIManager.EnableActionButtons(false); if skillData.Target == "ENEMY_SINGLE" then CombatUIManager.StartTargetSelection("skill", skillId) else CombatUIManager.EnableActionButtons(false); if SoundManager and SoundManager.PlaySFX then local sfxId = skillData.SfxId; if sfxId and sfxId ~= "" then SoundManager.PlaySFX(sfxId) else warn("SfxId 없음 skill:", skillId) end else warn("SoundManager/PlaySFX 없음!") end; CombatUIManager.TriggerPlayerActionAnimation(); CombatUIManager.ShowSkillEffect(skillId); task.wait(0.3); if requestPlayerUseSkillEvent then requestPlayerUseSkillEvent:FireServer(skillId, nil) else warn("RequestPlayerUseSkillEvent 없음!") end end end)
			else skillButton.MouseEnter:Connect(function() print("스킬 사용 불가:", reason) end) end; order = order + 1
		end
	end
	local listLayout = skillList:FindFirstChildOfClass("UIListLayout"); if listLayout then local numItems = 0; for _, c in ipairs(skillList:GetChildren()) do if c:IsA("TextButton") then numItems = numItems + 1 end end; local itemHeight = 40; local padding = listLayout.Padding.Offset; skillList.CanvasSize = UDim2.new(0, 0, 0, numItems * itemHeight + math.max(0, numItems - 1) * padding) end
end

function CombatUIManager.ShowCombatItemSelection(show)
	if not combatItemSelectionFrame then local bgFrame = mainGui:FindFirstChild("BackgroundFrame"); combatItemSelectionFrame = bgFrame and bgFrame:FindFirstChild("CombatItemSelectionFrame") end
	if not combatItemSelectionFrame then warn("ShowCombatItemSelection: CombatItemSelectionFrame 없음!"); return end
	if show then CombatUIManager.PopulateCombatItems(); combatItemSelectionFrame.Visible = true else combatItemSelectionFrame.Visible = false; if TooltipManager and TooltipManager.HideTooltip then TooltipManager.HideTooltip() end end
end

function CombatUIManager.PopulateCombatItems()
	if not combatItemList then if combatItemSelectionFrame then combatItemList = combatItemSelectionFrame:FindFirstChild("ItemList") end end
	if not combatItemList then warn("PopulateCombatItems: combatItemList 없음!"); return end
	if not ItemDatabase or not ItemDatabase.Items then warn("PopulateCombatItems: ItemDatabase 없음!"); return end
	if not getPlayerInventoryFunction then warn("PopulateCombatItems: getPlayerInventoryFunction 없음!"); return end
	for _, item in ipairs(combatItemList:GetChildren()) do if item:IsA("ImageButton") or item:IsA("Frame") or item:IsA("TextLabel") then if not item:IsA("UIGridLayout") then item:Destroy() end end end
	local success, inventoryData = pcall(getPlayerInventoryFunction.InvokeServer, getPlayerInventoryFunction); if not success or not inventoryData or typeof(inventoryData) ~= "table" then warn("PopulateCombatItems: 인벤토리 데이터 로드 실패:", inventoryData); return end
	local itemsAdded = 0
	for i, itemSlotData in ipairs(inventoryData) do
		local itemId = itemSlotData.itemId; local quantity = itemSlotData.quantity; local itemInfo = ItemDatabase.Items[itemId]
		if itemInfo and itemInfo.Type == "Consumable" then
			itemsAdded = itemsAdded + 1; local itemSlot = Instance.new("ImageButton"); itemSlot.Name = tostring(itemId); itemSlot.Parent = combatItemList; itemSlot.BackgroundColor3 = Color3.fromRGB(90, 70, 70); itemSlot.BorderSizePixel = 1; itemSlot.LayoutOrder = itemsAdded
			if itemInfo.ImageId and itemInfo.ImageId ~= "" then itemSlot.Image = itemInfo.ImageId else local encodedName = HttpService:UrlEncode(itemInfo.Name); itemSlot.Image = string.format("https://placehold.co/64x64/cccccc/333333?text=%s", encodedName) end
			itemSlot.ScaleType = Enum.ScaleType.Fit; Instance.new("UICorner", itemSlot).CornerRadius = UDim.new(0, 4)
			if GuiUtils and GuiUtils.CreateTextLabel then local quantityLabel = GuiUtils.CreateTextLabel(itemSlot, "QuantityLabel", UDim2.new(1, -2, 1, -2), UDim2.new(0.4, 0, 0.3, 0), tostring(quantity), Vector2.new(1, 1), Enum.TextXAlignment.Right, Enum.TextYAlignment.Bottom, 12); if quantityLabel then quantityLabel.TextColor3 = Color3.fromRGB(255, 255, 180); quantityLabel.TextStrokeTransparency = 0.5; quantityLabel.ZIndex = itemSlot.ZIndex + 1 end end

			-- ##### [기능 추가] 아이템 클릭 시 대상 선택 시작 #####
			itemSlot.MouseButton1Click:Connect(function()
				print("CombatUIManager: Consumable item clicked - ItemID:", itemId)
				CombatUIManager.ShowCombatItemSelection(false) -- 아이템 선택 창 닫기
				CombatUIManager.EnableActionButtons(false)   -- 액션 버튼 비활성화
				CombatUIManager.StartAllyTargetSelectionForItem(itemId) -- 아군 대상 선택 시작
			end)
			-- ##############################################

			itemSlot.MouseEnter:Connect(function() if TooltipManager and TooltipManager.ShowTooltip then local mousePos = UserInputService:GetMouseLocation(); TooltipManager.ShowTooltip(itemInfo, false, mousePos, "CombatItem") end end)
			itemSlot.MouseLeave:Connect(function() if TooltipManager and TooltipManager.HideTooltip then TooltipManager.HideTooltip() end end)
		end
	end
	local gridLayout = combatItemList:FindFirstChildOfClass("UIGridLayout"); if gridLayout then local itemsPerRow = math.floor(combatItemList.AbsoluteSize.X / (gridLayout.CellSize.X.Offset + gridLayout.CellPadding.X.Offset)); itemsPerRow = math.max(1, itemsPerRow); local numRows = math.ceil(itemsAdded / itemsPerRow); local totalGridHeight = numRows * (gridLayout.CellSize.Y.Offset + gridLayout.CellPadding.Y.Offset) + gridLayout.CellPadding.Y.Offset; combatItemList.CanvasSize = UDim2.new(0, 0, 0, totalGridHeight) end
	if itemsAdded == 0 then if GuiUtils and GuiUtils.CreateTextLabel then local emptyLabel = GuiUtils.CreateTextLabel(combatItemList, "EmptyLabel", UDim2.new(0.5, 0, 0.1, 0), UDim2.new(0.9, 0, 0.1, 0), "사용 가능한 아이템이 없습니다.", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 16); if emptyLabel then emptyLabel.TextColor3 = Color3.fromRGB(200, 200, 200) end end end
end

function CombatUIManager.AddCombatLogMessage(message)
	if not combatLogFrame then
		local backgroundFrame = mainGui:FindFirstChild("BackgroundFrame")
		local currentCombatScreen = backgroundFrame and backgroundFrame:FindFirstChild("Frames") and backgroundFrame.Frames:FindFirstChild("CombatScreen")
		combatLogFrame = currentCombatScreen and currentCombatScreen:FindFirstChild("CombatLogFrame")
	end
	if combatLogFrame and not combatLogLayout then
		combatLogLayout = combatLogFrame:FindFirstChild("LogLayout")
	end

	if not combatLogFrame or not combatLogLayout then
		warn("AddCombatLogMessage: CombatLogFrame/Layout 없음! 메시지 표시 불가:", message)
		return
	end

	local newLogEntry = Instance.new("TextLabel")
	newLogEntry.Name = "LogEntry"
	newLogEntry.Text = message
	newLogEntry.Font = Enum.Font.SourceSans
	newLogEntry.TextSize = 14
	newLogEntry.TextColor3 = Color3.fromRGB(220, 220, 220)
	newLogEntry.TextWrapped = true
	newLogEntry.RichText = true
	newLogEntry.TextXAlignment = Enum.TextXAlignment.Left
	newLogEntry.TextYAlignment = Enum.TextYAlignment.Top
	newLogEntry.Size = UDim2.new(1, -10, 0, 0) 
	newLogEntry.AutomaticSize = Enum.AutomaticSize.Y 
	newLogEntry.BackgroundTransparency = 1
	newLogEntry.Parent = combatLogFrame

	if SoundManager and SoundManager.PlaySFX and CombatUIManager.TriggerCompanionActionAnimation and CombatUIManager.TriggerEnemyHitAnimation and CombatUIManager.ShowAttackEffect then
		local compName, enemyName = message:match("<font color='#.+%'>([^<]+)</font>이%(가%) <font color='#.+%'>([^<]+)</font>을%(를%) 공격!") 
		if compName and enemyName then
			local attackerCompId = nil
			for instId, compFrameData in pairs(companionUIFrames) do
				if compFrameData and compFrameData.Frame then 
					local nameLabelInSlot = compFrameData.Frame:FindFirstChild("InnerLayout") and compFrameData.Frame.InnerLayout:FindFirstChild("CompanionNameLabel")
					if nameLabelInSlot and nameLabelInSlot.Text == compName then
						attackerCompId = instId
						break
					end
				end
			end
			local targetEnemyId = nil
			for instId, enemyFrame in pairs(enemyUIFrames) do
				local nameLbl = enemyFrame:FindFirstChild("InfoContainer") and enemyFrame.InfoContainer:FindFirstChild("NameLabel")
				if nameLbl and nameLbl.Text == enemyName then
					targetEnemyId = instId
					break
				end
			end

			if attackerCompId and targetEnemyId then
				CombatUIManager.TriggerCompanionActionAnimation(attackerCompId)
				CombatUIManager.ShowAttackEffect(targetEnemyId, true, attackerCompId) 
				CombatUIManager.TriggerEnemyHitAnimation(targetEnemyId)
			end
		end
	end

	local logs = combatLogFrame:GetChildren()
	local maxLogs = 30
	local logCount = 0
	local entries = {}
	for _, child in ipairs(logs) do
		if child:IsA("TextLabel") and child.Name == "LogEntry" then
			logCount = logCount + 1
			table.insert(entries, child)
		end
	end

	if logCount > maxLogs then
		table.sort(entries, function(a,b) return a.LayoutOrder < b.LayoutOrder end)
		if entries[1] then
			entries[1]:Destroy()
		end
	end

	task.spawn(function()
		task.wait(0.1)
		if combatLogFrame and combatLogLayout then
			local contentHeight = combatLogLayout.AbsoluteContentSize.Y
			combatLogFrame.CanvasSize = UDim2.new(0, 0, 0, contentHeight + 10)
			combatLogFrame.CanvasPosition = Vector2.new(0, math.max(0, combatLogFrame.CanvasSize.Y.Offset - combatLogFrame.AbsoluteSize.Y))
		end
	end)
end

function CombatUIManager.OnCombatStarted(enemiesDataForClient, initialUIData)
	print("CombatUIManager: OnCombatStarted received. Starting transition...")
	combatUIFullyInitialized = false 
	isTargeting = false; enemyUIFrames = {}; companionUIFrames = {}; companionCharacterImages = {}
	isAllyTargetingForItem = false; currentItemIdForAllyTargeting = nil; -- 아군 타겟팅 상태 초기화

	if not CoreUIManager then warn("OnCombatStarted: CoreUIManager 없음!"); return end
	local backgroundFrame = mainGui:FindFirstChild("BackgroundFrame"); local framesFolder = backgroundFrame and backgroundFrame:WaitForChild("Frames", 5); if not framesFolder then warn("OnCombatStarted: Frames 폴더 없음!"); return end
	local currentCombatScreen = framesFolder:WaitForChild("CombatScreen", 5); if not currentCombatScreen then warn("OnCombatStarted: CombatScreen 없음!"); return end

	CoreUIManager.ShowFrame("CombatScreen", true)
	local combatBackgroundImage = currentCombatScreen:FindFirstChild("CombatBackgroundImage"); if combatBackgroundImage then combatBackgroundImage.ImageTransparency = 1 end

	playerCharacterImage = currentCombatScreen:FindFirstChild("PlayerCharacterImage") 
	enemyAreaFrame = currentCombatScreen:FindFirstChild("EnemyAreaFrame")
	enemyUITemplate = enemyAreaFrame and enemyAreaFrame:FindFirstChild("EnemyUITemplate")
	skillEffectImage = currentCombatScreen:FindFirstChild("SkillEffectImage")
	combatLogFrame = currentCombatScreen:FindFirstChild("CombatLogFrame")
	combatLogLayout = combatLogFrame and combatLogFrame:FindFirstChild("LogLayout")
	skillSelectionFrame = backgroundFrame and backgroundFrame:FindFirstChild("SkillSelectionFrame")
	skillList = skillSelectionFrame and skillSelectionFrame:FindFirstChild("SkillList")
	combatItemSelectionFrame = backgroundFrame and backgroundFrame:FindFirstChild("CombatItemSelectionFrame")
	combatItemList = combatItemSelectionFrame and combatItemSelectionFrame:FindFirstChild("ItemList")
	local bottomUI = currentCombatScreen:FindFirstChild("BottomUIArea")
	actionMenuFrame = bottomUI and bottomUI:FindFirstChild("ActionMenuFrame")
	partyStatusFrame = bottomUI and bottomUI:FindFirstChild("PartyStatusFrame")

	if not (playerCharacterImage and enemyAreaFrame and enemyUITemplate and bottomUI and actionMenuFrame and partyStatusFrame) then warn("OnCombatStarted: 전투 UI 필수 요소 부족!"); return end

	if combatLogFrame then for _, child in ipairs(combatLogFrame:GetChildren()) do if child:IsA("TextLabel") and child.Name == "LogEntry" then child:Destroy() end end; combatLogFrame.CanvasSize = UDim2.new(); combatLogFrame.CanvasPosition = Vector2.new(); end
	if enemyAreaFrame then for _, child in ipairs(enemyAreaFrame:GetChildren()) do if child.Name ~= "EnemyUITemplate" and not child:IsA("UIListLayout") then child:Destroy() end end end

	if playerCharacterImage then playerCharacterImage.ImageTransparency = 1; playerCharacterImage.Position = UDim2.new(0.7, 0, 0.8, 0); playerCharacterImage.Visible = true end
	if bottomUI then bottomUI.BackgroundTransparency = 1; bottomUI.Position = UDim2.new(0,0,1.1,0); if actionMenuFrame then actionMenuFrame.BackgroundTransparency = 1 end; if partyStatusFrame then partyStatusFrame.BackgroundTransparency = 1 end end

	for i = 1, 2 do
		local compFieldImg = currentCombatScreen:FindFirstChild("CompanionCharacterImage_" .. i)
		if compFieldImg then
			compFieldImg.Image = ""
			compFieldImg.ImageTransparency = 1
			compFieldImg.Visible = false
		else
			warn("OnCombatStarted: CompanionCharacterImage_" .. i .. " 없음!")
		end
	end
	if partyStatusFrame then
		local playerSlotUI = partyStatusFrame:FindFirstChild("PartySlot_Player")
		if playerSlotUI then CombatUIManager.UpdatePartyMemberStatus("Player", player.UserId, {name="", hp=0,maxHp=0,mp=0,maxMp=0,tp=0,effects={}}) end
		for i=1,2 do
			local compSlotUI = partyStatusFrame:FindFirstChild("PartySlot_Companion"..i)
			if compSlotUI then 
				local innerC = compSlotUI:FindFirstChild("InnerLayout")
				if innerC then
					local nameL = innerC:FindFirstChild("CompanionNameLabel"); if nameL then nameL.Text = "(비어있음)" end
					local hpL = innerC:FindFirstChild("HPLabel"); if hpL then hpL.Text = "HP: -/-" end
					local mpL = innerC:FindFirstChild("MPLabel"); if mpL then mpL.Text = "MP: -/-" end
					local tpL = innerC:FindFirstChild("TPLabel"); if tpL then tpL.Text = "TP: -" end
				end
				local statusF = compSlotUI:FindFirstChild("StatusEffectsFrame"); if statusF then UpdateStatusIcons(statusF, {}) end 
				compSlotUI:SetAttribute("CompanionInstanceId", nil)
			end
		end
	end

	CoreUIManager.FadeScreen(true, 0.5, function()
		if SoundManager and SoundManager.PlayBGM then SoundManager.PlayBGM(COMBAT_BGM_ID) else warn("SoundManager/PlayBGM 없음!") end
		if combatBackgroundImage then TweenService:Create(combatBackgroundImage, TweenInfo.new(0.3), {ImageTransparency = 0}):Play() end

		if playerCharacterImage then
			local localPlayer = Players.LocalPlayer
			if localPlayer then local success, content, isReady = pcall(function() return Players:GetUserThumbnailAsync(localPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size100x100) end); if success and isReady then playerCharacterImage.Image = content; else warn("플레이어 썸네일 로드 실패:", content); playerCharacterImage.Image = "" end else warn("로컬 플레이어 없음."); playerCharacterImage.Image = "" end
			local playerAppearTween = TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out); TweenService:Create(playerCharacterImage, playerAppearTween, {ImageTransparency = 0, Position = UDim2.new(0.7, 0, 0.7, 0)}):Play()
		end

		local enemyDelay = 0.2
		if enemyAreaFrame and enemyUITemplate and enemiesDataForClient and typeof(enemiesDataForClient) == "table" then
			for i, enemyData in ipairs(enemiesDataForClient) do
				local enemyUI = enemyUITemplate:Clone(); enemyUI.Name = "Enemy_" .. enemyData.instanceId; enemyUI.Visible = true; enemyUI.LayoutOrder = i; enemyUI.Parent = enemyAreaFrame; enemyUIFrames[enemyData.instanceId] = enemyUI
				CombatUIManager.UpdateSingleEnemyInfo(enemyData.instanceId, enemyData)
				local enemyImg = enemyUI:FindFirstChild("EnemyImage"); if enemyImg then enemyImg.ImageTransparency = 1; enemyImg.Position = UDim2.new(0.5, 0, 0.9, 0) end
				local targetButton = enemyUI:FindFirstChild("TargetButton"); if targetButton then targetButton.MouseButton1Click:Connect(function() CombatUIManager.SelectTarget(enemyData.instanceId) end); targetButton.Active = false end
				task.delay(enemyDelay * (i-1), function() if enemyImg then local enemyAppearTween = TweenInfo.new(0.3, Enum.EasingStyle.Sine, Enum.EasingDirection.Out); TweenService:Create(enemyImg, enemyAppearTween, {ImageTransparency = 0, Position = UDim2.new(0.5, 0, 0.8, 0)}):Play() end end)
			end
		else warn("OnCombatStarted: 적 UI 생성 실패 (참조/데이터 오류).") end

		local playerSlotUI = partyStatusFrame:FindFirstChild("PartySlot_Player")
		if playerSlotUI then
			local playerStats = PlayerData.GetStats(player)
			if playerStats then
				local playerStatusEffects = (initialUIData and initialUIData.playerStatus and initialUIData.playerStatus.effects) or {}
				local playerDataForUI = {
					name = playerStats.Name, hp = playerStats.CurrentHP, maxHp = playerStats.MaxHP,
					mp = playerStats.CurrentMP, maxMp = playerStats.MaxMP, tp = playerStats.CurrentTP,
					effects = playerStatusEffects, appearanceId = playerCharacterImage.Image 
				}
				CombatUIManager.UpdatePartyMemberStatus("Player", player.UserId, playerDataForUI)
				playerSlotUI:SetAttribute("MemberInstanceId", player.UserId)
				playerSlotUI:SetAttribute("MemberType", "Player")
			end
		else warn("OnCombatStarted: PartySlot_Player UI 없음!") end

		if initialUIData and initialUIData.companionsStatus and typeof(initialUIData.companionsStatus) == "table" then
			local companionSlotNumber = 1 
			for _, compDataFromServer in ipairs(initialUIData.companionsStatus) do 
				if companionSlotNumber > 2 then break end 

				local serverInstanceId = compDataFromServer.instanceId 

				local compFieldImage = currentCombatScreen:FindFirstChild("CompanionCharacterImage_" .. companionSlotNumber)
				if compFieldImage then
					compFieldImage.Image = compDataFromServer.appearanceId or ""
					compFieldImage.ImageTransparency = 1 
					compFieldImage.Visible = true

					local targetXScale = playerCharacterImage.Position.X.Scale - (0.12 * companionSlotNumber) 
					local targetYScale = playerCharacterImage.Position.Y.Scale - 0.05 
					local targetPosition = UDim2.new(targetXScale, 0, targetYScale, 0)
					TweenService:Create(compFieldImage, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out, 0.2 * companionSlotNumber), {Position = targetPosition, ImageTransparency = 0}):Play()

					companionCharacterImages[serverInstanceId] = compFieldImage 
					compFieldImage:SetAttribute("CompanionInstanceId", serverInstanceId) 
				else warn("OnCombatStarted: CompanionCharacterImage_" .. companionSlotNumber .. " 없음!") end

				local compPartySlotUI = partyStatusFrame:FindFirstChild("PartySlot_Companion" .. companionSlotNumber)
				if compPartySlotUI then
					companionUIFrames[serverInstanceId] = { Frame = compPartySlotUI } 
					compPartySlotUI:SetAttribute("CompanionInstanceId", serverInstanceId)
					compPartySlotUI:SetAttribute("MemberType", "Companion")
				else warn("OnCombatStarted: PartySlot_Companion"..companionSlotNumber.." UI 없음!") end
				companionSlotNumber = companionSlotNumber + 1
			end

			print("OnCombatStarted: 동료 UI 프레임 참조 저장 완료. 이제 정보 업데이트 시작.")
			for _, compDataToUpdate in ipairs(initialUIData.companionsStatus) do 
				local actualCompanionInstanceId = compDataToUpdate.instanceId 
				if companionUIFrames[actualCompanionInstanceId] and companionUIFrames[actualCompanionInstanceId].Frame then
					print("OnCombatStarted: Updating status for companion:", actualCompanionInstanceId)
					CombatUIManager.UpdatePartyMemberStatus("Companion", actualCompanionInstanceId, compDataToUpdate) 
				else
					warn("OnCombatStarted: 동료 정보 업데이트 시 companionUIFrames[" .. tostring(actualCompanionInstanceId) .. "] 또는 .Frame 참조 없음.")
				end
			end
		end

		task.wait(0.5 + (enemiesDataForClient and #enemiesDataForClient or 0) * enemyDelay)
		if bottomUI then local bottomUIAppearTween = TweenInfo.new(0.5, Enum.EasingStyle.Quint, Enum.EasingDirection.Out); TweenService:Create(bottomUI, bottomUIAppearTween, {BackgroundTransparency = 0, Position = UDim2.new(0,0,1,0)}):Play(); if actionMenuFrame then TweenService:Create(actionMenuFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play() end; if partyStatusFrame then TweenService:Create(partyStatusFrame, TweenInfo.new(0.5), {BackgroundTransparency = 0}):Play() end end
		print("CombatUIManager.OnCombatStarted: 전투 장면 설정 및 전환 완료.")
		combatUIFullyInitialized = true 
	end)
end

function CombatUIManager.OnCombatEnded(result, rewards, droppedItemsList)
	combatUIFullyInitialized = false 
	print("OnCombatEnded 결과:", result); if CoreUIManager and CoreUIManager.ShowFrame then local bgFrame = mainGui:FindFirstChild("BackgroundFrame"); local framesFolder = bgFrame and bgFrame:FindFirstChild("Frames"); local combatScreen = framesFolder and framesFolder:FindFirstChild("CombatScreen"); if combatScreen then CoreUIManager.ShowFrame("CombatScreen", false) else warn("OnCombatEnded: CombatScreen 없음!") end else warn("CoreUIManager 없음, CombatScreen 숨기기 불가!") end
	CombatUIManager.CancelTargetSelection(); CombatUIManager.ShowSkillSelection(false); CombatUIManager.ShowCombatItemSelection(false); if SoundManager and SoundManager.StopBGM then SoundManager.StopBGM() end
	-- ##### [기능 추가] 아군 타겟팅 상태 초기화 #####
	CombatUIManager.CancelAllyTargetSelection(false)
	-- ##############################################
	local backgroundFrame = mainGui:FindFirstChild("BackgroundFrame"); local resultsFrame = backgroundFrame and backgroundFrame:WaitForChild("CombatResultsFrame", 5); if not resultsFrame then warn("OnCombatEnded: CombatResultsFrame 없음!"); return end
	local resultsTitle = resultsFrame:FindFirstChild("ResultsTitle"); local goldLabel = resultsFrame:FindFirstChild("GoldRewardLabel"); local expLabel = resultsFrame:FindFirstChild("ExpRewardLabel"); local itemListFrame = resultsFrame:FindFirstChild("ResultsItemList"); local listLayout = itemListFrame and itemListFrame:FindFirstChildOfClass("UIListLayout")
	if not (resultsTitle and goldLabel and expLabel and itemListFrame and listLayout) then warn("OnCombatEnded: CombatResultsFrame 내부 요소 없음!"); return end

	for _, child in ipairs(itemListFrame:GetChildren()) do if child:IsA("Frame") or child:IsA("TextLabel") or child:IsA("ImageLabel") then if not child:IsA("UIListLayout") then child:Destroy() end end end

	if result == "win" then
		resultsTitle.Text = "전투 승리!"; resultsTitle.TextColor3 = Color3.fromRGB(180, 255, 180); goldLabel.Text = "획득 골드: " .. (rewards and rewards.gold or 0); expLabel.Text = "획득 경험치: " .. (rewards and rewards.exp or 0)
		local itemEntryHeight = 35; local itemImageSize = itemEntryHeight - 5; local totalItemHeight = 0; local itemsAddedToResult = 0
		if droppedItemsList and #droppedItemsList > 0 then
			for i, dropData in ipairs(droppedItemsList) do
				local itemId = dropData.itemId; local quantity = dropData.quantity; local itemInfo = ItemDatabase and ItemDatabase.Items[itemId]
				if itemInfo then itemsAddedToResult = itemsAddedToResult + 1; local itemEntryFrame = Instance.new("Frame"); itemEntryFrame.Name = "ItemEntry_" .. itemId; itemEntryFrame.Size = UDim2.new(1, -10, 0, itemEntryHeight); itemEntryFrame.BackgroundColor3 = Color3.fromRGB(55, 65, 55); itemEntryFrame.BorderSizePixel = 0; itemEntryFrame.LayoutOrder = i; itemEntryFrame.Parent = itemListFrame; Instance.new("UICorner", itemEntryFrame).CornerRadius = UDim.new(0, 3); local itemIcon = Instance.new("ImageLabel"); itemIcon.Name = "ItemIcon"; itemIcon.Size = UDim2.new(0, itemImageSize, 0, itemImageSize); itemIcon.Position = UDim2.new(0, 5, 0.5, 0); itemIcon.AnchorPoint = Vector2.new(0, 0.5); itemIcon.BackgroundTransparency = 1; itemIcon.ScaleType = Enum.ScaleType.Fit; if itemInfo.ImageId and itemInfo.ImageId ~= "" then itemIcon.Image = itemInfo.ImageId else local encodedName = HttpService:UrlEncode(itemInfo.Name); itemIcon.Image = string.format("https://placehold.co/%dx%d/cccccc/333333?text=%s", itemImageSize, itemImageSize, encodedName) end; itemIcon.Parent = itemEntryFrame; local itemText = string.format("%s x%d", itemInfo.Name, quantity); local nameLbl = GuiUtils.CreateTextLabel(itemEntryFrame, "ItemNameLabel", UDim2.new(0, itemImageSize + 10, 0.5, 0), UDim2.new(1, -(itemImageSize + 15), 1, 0), itemText, Vector2.new(0, 0.5), Enum.TextXAlignment.Left, Enum.TextYAlignment.Center, 14); nameLbl.TextColor3 = Color3.fromRGB(210, 240, 210); totalItemHeight = totalItemHeight + itemEntryHeight + (listLayout and listLayout.Padding.Offset or 0)
				else warn("OnCombatEnded: 드랍 아이템 정보 없음 ID:", itemId) end
			end
		end
		if itemsAddedToResult == 0 then local noItemLabel = GuiUtils.CreateTextLabel(itemListFrame, "NoItemLabel", UDim2.new(0.5, 0, 0.1, 0), UDim2.new(0.9, 0, 0.2, 0), "(획득한 아이템 없음)", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 14); noItemLabel.TextColor3 = Color3.fromRGB(180, 180, 180); totalItemHeight = 30 end
		itemListFrame.CanvasSize = UDim2.new(0, 0, 0, totalItemHeight)
	elseif result == "lose" then resultsTitle.Text = "전투 패배..."; resultsTitle.TextColor3 = Color3.fromRGB(255, 180, 180); goldLabel.Text = "획득 골드: 0"; expLabel.Text = "획득 경험치: 0"; itemListFrame.CanvasSize = UDim2.new(0,0,0,0);
	else resultsTitle.Text = "전투 종료"; resultsTitle.TextColor3 = Color3.fromRGB(200, 200, 200); goldLabel.Text = "획득 골드: 0"; expLabel.Text = "획득 경험치: 0"; itemListFrame.CanvasSize = UDim2.new(0,0,0,0); end
	if CoreUIManager and CoreUIManager.ShowFrame then CoreUIManager.ShowFrame("CombatResultsFrame", true) else warn("CoreUIManager 없음, 결과창 표시 불가!") end

	if playerCharacterImage then playerCharacterImage.Image = ""; playerCharacterImage.ImageTransparency = 1; playerCharacterImage.Visible = false end
	for _, compImg in pairs(companionCharacterImages) do if compImg and compImg.Parent then compImg.Image = ""; compImg.ImageTransparency = 1; compImg.Visible = false end end
	for _, enemyUI in pairs(enemyUIFrames) do if enemyUI and enemyUI.Parent then enemyUI:Destroy() end end 

	if partyStatusFrame then
		local playerSlot = partyStatusFrame:FindFirstChild("PartySlot_Player")
		if playerSlot then 
			local innerPlayer = playerSlot:FindFirstChild("InnerLayout")
			if innerPlayer then
				CombatUIManager.UpdatePartyMemberStatus("Player", player.UserId, {name="", hp=0,maxHp=0,mp=0,maxMp=0,tp=0,effects={}}) 
			end
		end
		for i=1,2 do
			local compSlot = partyStatusFrame:FindFirstChild("PartySlot_Companion"..i)
			if compSlot then
				local innerComp = compSlot:FindFirstChild("InnerLayout")
				if innerComp then
					local nameLbl = innerComp:FindFirstChild("CompanionNameLabel"); if nameLbl then nameLbl.Text = "(비어있음)" end
					local hpLbl = innerComp:FindFirstChild("HPLabel"); if hpLbl then hpLbl.Text = "HP: -/-" end
					local mpLbl = innerComp:FindFirstChild("MPLabel"); if mpLbl then mpLbl.Text = "MP: -/-" end
					local tpLbl = innerComp:FindFirstChild("TPLabel"); if tpLbl then tpLbl.Text = "TP: -" end
				end
				local statusFrm = compSlot:FindFirstChild("StatusEffectsFrame"); if statusFrm then UpdateStatusIcons(statusFrm, {}) end 
				compSlot:SetAttribute("CompanionInstanceId", nil)
			end
		end
	end

	enemyUIFrames = {}; companionUIFrames = {}; companionCharacterImages = {}
	print("CombatUIManager: 전투 UI 참조 정리 및 초기화됨.")
end

function CombatUIManager.OnPlayerTurn(turnData)
	if not combatUIFullyInitialized then 
		print("OnPlayerTurn: Combat UI not fully initialized yet. Skipping full companion update.")
	end
	CombatUIManager.CancelTargetSelection(); CombatUIManager.EnableActionButtons(true)
	-- ##### [기능 추가] 아군 타겟팅 상태 초기화 #####
	CombatUIManager.CancelAllyTargetSelection(false) -- 플레이어 턴 시작 시 아군 타겟팅 취소
	-- ##############################################
	if turnData and typeof(turnData) == "table" then
		if turnData.playerStatus then CombatUIManager.UpdatePartyMemberStatus("Player", player.UserId, turnData.playerStatus) end
		if turnData.enemiesStatus then for instanceId, enemyStatusData in pairs(turnData.enemiesStatus) do CombatUIManager.UpdateSingleEnemyInfo(tonumber(instanceId), enemyStatusData) end end
		if turnData.companionsStatus then 
			if combatUIFullyInitialized then 
				for instanceId, compStatusData in pairs(turnData.companionsStatus) do CombatUIManager.UpdatePartyMemberStatus("Companion", tonumber(instanceId), compStatusData) end
			end
		end
	end
end

function CombatUIManager.OnEnemyTurn(turnData)
	if not combatUIFullyInitialized then 
		print("OnEnemyTurn: Combat UI not fully initialized yet. Skipping full companion update.")
	end
	CombatUIManager.CancelTargetSelection(); CombatUIManager.EnableActionButtons(false); CombatUIManager.ShowSkillSelection(false); CombatUIManager.ShowCombatItemSelection(false)
	-- ##### [기능 추가] 아군 타겟팅 상태 초기화 #####
	CombatUIManager.CancelAllyTargetSelection(false) -- 적 턴 시작 시 아군 타겟팅 취소
	-- ##############################################
	if turnData and typeof(turnData) == "table" then
		if turnData.playerStatus then CombatUIManager.UpdatePartyMemberStatus("Player", player.UserId, turnData.playerStatus) end
		if turnData.enemiesStatus then for instanceId, enemyStatusData in pairs(turnData.enemiesStatus) do CombatUIManager.UpdateSingleEnemyInfo(tonumber(instanceId), enemyStatusData) end end
		if turnData.companionsStatus then
			if combatUIFullyInitialized then 
				for instanceId, compStatusData in pairs(turnData.companionsStatus) do CombatUIManager.UpdatePartyMemberStatus("Companion", tonumber(instanceId), compStatusData) end
			end
		end
	end
	task.wait(0.5)
	if enemyAreaFrame then local firstLivingEnemyUI = nil; for id, ui in pairs(enemyUIFrames) do local hpBar = ui:FindFirstChild("InfoContainer"):FindFirstChild("HPBarBackground"):FindFirstChild("HPBar"); if hpBar and hpBar.Size.X.Scale > 0 then firstLivingEnemyUI = ui:FindFirstChild("EnemyImage"); break end end; if firstLivingEnemyUI then AnimateAttack(firstLivingEnemyUI) end end
end

function CombatUIManager.OnUpdateCombatUI(updateData)
	if not combatUIFullyInitialized then 
		print("OnUpdateCombatUI: Combat UI not fully initialized yet. Skipping full companion update.")
	end
	if typeof(updateData) ~= "table" then return end
	if updateData.playerStats then 
		local playerEffects = (updateData.playerStatus and updateData.playerStatus.effects) or (PlayerData.GetStats(player) and PlayerData.GetStats(player).statusEffects) or {}
		CombatUIManager.UpdatePartyMemberStatus("Player", player.UserId, {name = updateData.playerStats.Name, hp = updateData.playerStats.CurrentHP, maxHp = updateData.playerStats.MaxHP, mp = updateData.playerStats.CurrentMP, maxMp = updateData.playerStats.MaxMP, tp = updateData.playerStats.CurrentTP, effects = playerEffects})
	elseif updateData.playerStatus then 
		CombatUIManager.UpdatePartyMemberStatus("Player", player.UserId, updateData.playerStatus)
	end
	if updateData.enemiesStatus then for instanceId, enemyStatusData in pairs(updateData.enemiesStatus) do CombatUIManager.UpdateSingleEnemyInfo(tonumber(instanceId), enemyStatusData) end end
	if updateData.companionsStatus then
		if combatUIFullyInitialized then 
			for instanceId, compStatusData in pairs(updateData.companionsStatus) do CombatUIManager.UpdatePartyMemberStatus("Companion", tonumber(instanceId), compStatusData) end
		end
	end
end

function CombatUIManager.OnCombatDamage(targetType, amount, isHeal, instanceId)
	local currentCombatScreen = playerGui:FindFirstChild("MainGui") and playerGui.MainGui:FindFirstChild("BackgroundFrame") and playerGui.MainGui.BackgroundFrame:FindFirstChild("Frames") and playerGui.MainGui.BackgroundFrame.Frames:FindFirstChild("CombatScreen")
	if not currentCombatScreen or not CoreUIManager or not CoreUIManager.ShowDamagePopup then return end
	local targetGuiObject = nil
	if targetType == "Player" then targetGuiObject = playerCharacterImage
	elseif targetType == "Enemy" and instanceId then local enemyUI = enemyUIFrames[instanceId]; if enemyUI then targetGuiObject = enemyUI:FindFirstChild("EnemyImage") end
	elseif targetType == "Companion" and instanceId then 
		targetGuiObject = companionCharacterImages[instanceId] 
		if not targetGuiObject then
			warn("OnCombatDamage: Companion GUI를 찾을 수 없음 (instanceId: " .. tostring(instanceId) .. "). companionCharacterImages:", companionCharacterImages)
		end
	end
	if targetGuiObject then CoreUIManager.ShowDamagePopup(targetGuiObject, amount, isHeal) else warn("OnCombatDamage: Target GUI 없음 type:", targetType, "InstanceID:", tostring(instanceId)) end
end

function CombatUIManager.StartTargetSelection(action, skillId) if isTargeting then CombatUIManager.CancelTargetSelection() end; isTargeting = true; currentActionType = action; currentSkillIdForTargeting = skillId; CombatUIManager.EnableActionButtons(false); CombatUIManager.ShowCombatItemSelection(false); CombatUIManager.ShowSkillSelection(false); for id, enemyUI in pairs(enemyUIFrames) do local targetButton = enemyUI:FindFirstChild("TargetButton"); local infoContainer = enemyUI:FindFirstChild("InfoContainer"); local hpBarBG = infoContainer and infoContainer:FindFirstChild("HPBarBackground"); local hpBar = hpBarBG and hpBarBG:FindFirstChild("HPBar"); local enemyImage = enemyUI:FindFirstChild("EnemyImage"); if targetButton and hpBar and hpBar.Size.X.Scale > 0 then targetButton.Visible = true; targetButton.Selectable = true; targetButton.Active = true; targetButton.BackgroundColor3 = Color3.fromRGB(255, 255, 0); targetButton.BackgroundTransparency = 0.5; if enemyImage then enemyImage.ImageTransparency = 0.2 end elseif targetButton then targetButton.Visible = false; targetButton.Selectable = false; targetButton.Active = false; targetButton.BackgroundTransparency = 1; if enemyImage then enemyImage.ImageTransparency = 0 end end end; if CombatUIManager.AddCombatLogMessage then CombatUIManager.AddCombatLogMessage("<font color='#FFFF88'>공격할 대상을 선택하세요.</font>") else warn("StartTargetSelection: AddCombatLogMessage 없음!") end end
function CombatUIManager.SelectTarget(instanceId) if not isTargeting then return end; if not instanceId then warn("SelectTarget: instanceId nil!"); CombatUIManager.CancelTargetSelection(false); return end; local selectedInstanceId = instanceId; local actionToPerform = currentActionType; local skillToUse = currentSkillIdForTargeting; CombatUIManager.CancelTargetSelection(true); if not actionToPerform then warn("SelectTarget: currentActionType nil! 취소."); CombatUIManager.CancelTargetSelection(false); return end; if actionToPerform == "attack" then if SoundManager and SoundManager.PlaySFX then SoundManager.PlaySFX(CombatUIManager.ATTACK_SFX_ID) end; CombatUIManager.TriggerPlayerActionAnimation(); CombatUIManager.ShowAttackEffect(selectedInstanceId); CombatUIManager.TriggerEnemyHitAnimation(selectedInstanceId); task.wait(0.3); if requestPlayerAttackEvent then requestPlayerAttackEvent:FireServer(selectedInstanceId) else warn("RequestPlayerAttackEvent 없음!") end elseif actionToPerform == "skill" and skillToUse then local skillData = SkillDatabase.Skills[skillToUse]; if not skillData then warn("SelectTarget: 잘못된 스킬 데이터 ID:", skillToUse); CombatUIManager.CancelTargetSelection(false); return end; if SoundManager and SoundManager.PlaySFX then local sfxId = skillData.SfxId; if sfxId and sfxId ~= "" then SoundManager.PlaySFX(sfxId) else warn("SfxId 없음 skill:", skillToUse) end else warn("SoundManager/PlaySFX 없음!") end; CombatUIManager.TriggerPlayerActionAnimation(); CombatUIManager.ShowSkillEffect(skillToUse, selectedInstanceId); if skillData.EffectType == "DAMAGE" then CombatUIManager.TriggerEnemyHitAnimation(selectedInstanceId) end; task.wait(0.3); if requestPlayerUseSkillEvent then requestPlayerUseSkillEvent:FireServer(skillToUse, selectedInstanceId) else warn("RequestPlayerUseSkillEvent 없음!") end else warn("SelectTarget: 잘못된 action type/skill ID:", actionToPerform, skillToUse); CombatUIManager.CancelTargetSelection(false) end end
function CombatUIManager.CancelTargetSelection(keepButtonsDisabled) isTargeting = false; currentActionType = nil; currentSkillIdForTargeting = nil; for id, enemyUI in pairs(enemyUIFrames) do local targetButton = enemyUI:FindFirstChild("TargetButton"); local enemyImage = enemyUI:FindFirstChild("EnemyImage"); if targetButton then targetButton.Visible = false; targetButton.Selectable = false; targetButton.Active = false; targetButton.BackgroundTransparency = 1; targetButton.BackgroundColor3 = Color3.new(1, 1, 1) end; if enemyImage then enemyImage.ImageTransparency = 0 end; enemyUI.BackgroundTransparency = 1 end; if not keepButtonsDisabled then CombatUIManager.EnableActionButtons(true) end end

-- ##### [기능 추가] 아군 대상 선택 시작 함수 #####
function CombatUIManager.StartAllyTargetSelectionForItem(itemId)
	print("CombatUIManager: StartAllyTargetSelectionForItem called for ItemID:", itemId)
	if isAllyTargetingForItem then CombatUIManager.CancelAllyTargetSelection() end -- 이전 타겟팅 취소

	isAllyTargetingForItem = true
	currentItemIdForAllyTargeting = itemId
	CombatUIManager.EnableActionButtons(false) -- 다른 액션 버튼 비활성화
	CombatUIManager.ShowCombatItemSelection(false) -- 아이템 선택창 닫기

	-- 기존 타겟팅 버튼 제거
	for _, btn in pairs(allyTargetButtons) do
		if btn and btn.Parent then btn:Destroy() end
	end
	allyTargetButtons = {}

	local currentCombatScreen = playerGui:FindFirstChild("MainGui"):FindFirstChild("BackgroundFrame"):FindFirstChild("Frames"):FindFirstChild("CombatScreen")
	if not currentCombatScreen then
		warn("StartAllyTargetSelectionForItem: CombatScreen not found!")
		CombatUIManager.CancelAllyTargetSelection(false)
		return
	end

	local function createTargetButton(parentGui, name, targetType, instanceId, text)
		local button = Instance.new("TextButton")
		button.Name = name
		button.Size = UDim2.new(0.8, 0, 0.2, 0) -- 크기는 임시
		button.Position = UDim2.new(0.5, 0, -0.25, 0) -- 대상 이미지 위에 표시 (조정 필요)
		button.AnchorPoint = Vector2.new(0.5, 1)
		button.Text = text or "선택"
		button.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
		button.TextColor3 = Color3.new(1,1,1)
		button.Font = Enum.Font.SourceSansBold
		button.TextSize = 14
		button.ZIndex = parentGui.ZIndex + 10
		button.Parent = parentGui

		button.MouseButton1Click:Connect(function()
			CombatUIManager.SelectAllyTarget(targetType, instanceId, currentItemIdForAllyTargeting)
		end)
		return button
	end

	-- 플레이어 타겟 버튼
	if playerCharacterImage and playerCharacterImage.Visible then
		allyTargetButtons["Player_" .. player.UserId] = createTargetButton(playerCharacterImage, "TargetPlayerButton", "Player", player.UserId, "본인 선택")
	end

	-- 동료 타겟 버튼
	for compInstanceId, compImage in pairs(companionCharacterImages) do
		if compImage and compImage.Visible then
			local compData = nil -- 실제 동료 이름 등을 가져오려면 CombatState 필요 (클라이언트에는 제한적)
			-- 서버로부터 받은 initialUIData.companionsStatus 등을 활용하여 이름을 가져올 수 있으나, 여기서는 간단히 InstanceId로 표시
			allyTargetButtons["Companion_" .. compInstanceId] = createTargetButton(compImage, "TargetCompButton_" .. compInstanceId, "Companion", compInstanceId, "동료 선택")
		end
	end

	-- 취소 버튼 (선택적) - 액션 메뉴 등에 추가하거나, 우클릭 등으로 취소
	if CombatUIManager.AddCombatLogMessage then CombatUIManager.AddCombatLogMessage("<font color='#88FFFF'>아이템을 사용할 대상을 선택하세요.</font>") end
end

-- ##### [기능 추가] 아군 대상 선택 취소 함수 #####
function CombatUIManager.CancelAllyTargetSelection(keepButtonsDisabled)
	print("CombatUIManager: CancelAllyTargetSelection called.")
	isAllyTargetingForItem = false
	currentItemIdForAllyTargeting = nil

	for _, button in pairs(allyTargetButtons) do
		if button and button.Parent then
			button:Destroy()
		end
	end
	allyTargetButtons = {}

	if not keepButtonsDisabled then
		CombatUIManager.EnableActionButtons(true) -- 액션 버튼 다시 활성화
	end
end

-- ##### [기능 추가] 선택된 아군에게 아이템 사용 요청 함수 #####
function CombatUIManager.SelectAllyTarget(targetType, instanceId, itemId)
	print(string.format("CombatUIManager: SelectAllyTarget - Type: %s, InstanceID: %s, ItemID: %s", targetType, tostring(instanceId), tostring(itemId)))
	if not isAllyTargetingForItem or not itemId then
		warn("SelectAllyTarget: Not in ally targeting mode or itemId is nil.")
		CombatUIManager.CancelAllyTargetSelection(false)
		return
	end

	if not requestPlayerUseItemEvent then
		warn("SelectAllyTarget: requestPlayerUseItemEvent is nil!")
		CombatUIManager.CancelAllyTargetSelection(false)
		return
	end

	-- 아군 타겟팅 UI 정리
	CombatUIManager.CancelAllyTargetSelection(true) -- 버튼 비활성화 유지하며 타겟팅 UI만 제거

	-- 서버로 아이템 사용 요청 (대상 ID 포함)
	requestPlayerUseItemEvent:FireServer(itemId, instanceId)

	-- (애니메이션 등은 서버의 PlayerUseItem 후 CombatDamageEvent 등으로 처리될 것)
	-- 필요시 여기서 플레이어의 아이템 사용 모션만 미리 보여줄 수 있음
	-- CombatUIManager.TriggerPlayerActionAnimation()
end
-- ########################################################


CombatUIManager.ATTACK_SFX_ID = "rbxassetid://8899349982"
return CombatUIManager