-- ReplicatedStorage > Modules > CompanionManager.lua

--[[
  CompanionManager (ModuleScript)
  동료 획득, 파티 설정 등 동료 관련 로직을 처리하는 모듈 (서버 측).
  *** [버그 수정] AcquireCompanion 함수에서 동료 Stats 테이블에 CurrentHP, CurrentMP 명시적 초기화 추가 ***
  *** [기능 추가] 동료에게 아이템 사용 효과를 적용하는 ApplyItemEffectToCompanion 함수 추가 ***
  *** [로직 변경] ApplyItemEffectToCompanion에서 실제 스탯 변화가 있을 때만 아이템을 소모하도록 수정 ***
]]

local CompanionManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService") -- JSONEncode를 위해 추가
local modulesFolder = ReplicatedStorage:WaitForChild("Modules")

-- 필요한 모듈 로드
local PlayerData = require(modulesFolder:WaitForChild("PlayerData"))
local CompanionDatabase = require(modulesFolder:WaitForChild("CompanionDatabase"))
local ItemDatabase = require(modulesFolder:WaitForChild("ItemDatabase"))
local InventoryManager = require(modulesFolder:WaitForChild("InventoryManager")) -- 인벤토리 관리를 위해 추가
local SkillDatabase = require(modulesFolder:WaitForChild("SkillDatabase")) 

-- 이벤트 참조
local companionUpdatedEvent = ReplicatedStorage:FindFirstChild("CompanionUpdatedEvent")
if not companionUpdatedEvent then
	warn("CompanionManager: CompanionUpdatedEvent RemoteEvent not found in ReplicatedStorage! Client updates might not work.")
end
local NotifyPlayerEvent = ReplicatedStorage:FindFirstChild("NotifyPlayerEvent") -- 알림용 이벤트 참조
if not NotifyPlayerEvent then
	warn("CompanionManager: NotifyPlayerEvent RemoteEvent not found in ReplicatedStorage!")
end
local inventoryUpdatedEvent = ReplicatedStorage:FindFirstChild("InventoryUpdatedEvent")
if not inventoryUpdatedEvent then
	warn("CompanionManager: InventoryUpdatedEvent RemoteEvent not found in ReplicatedStorage!")
end


-- 초기화 함수
function CompanionManager.Init()
	print("CompanionManager: Initialized (Server-side)")
end

-- 플레이어가 소유한 동료 목록 가져오기
function CompanionManager.GetOwnedCompanions(player)
	print(string.format("CompanionManager.GetOwnedCompanions: Called for player %s", player.Name))
	local pData = PlayerData.GetSessionData(player)
	if not pData then
		warn("CompanionManager.GetOwnedCompanions: Player data not found for", player.Name)
		return {}
	end
	if pData.OwnedCompanions and typeof(pData.OwnedCompanions) == 'table' then
		print(string.format("CompanionManager.GetOwnedCompanions: Returning owned companions for %s: %s", player.Name, HttpService:JSONEncode(pData.OwnedCompanions)))
		return pData.OwnedCompanions
	else
		print(string.format("CompanionManager.GetOwnedCompanions: OwnedCompanions not found or not a table for %s, initializing.", player.Name))
		pData.OwnedCompanions = {}
		return pData.OwnedCompanions
	end
end

-- 플레이어의 현재 파티 정보 가져오기
function CompanionManager.GetCurrentParty(player)
	print(string.format("CompanionManager.GetCurrentParty: Called for player %s", player.Name))
	local pData = PlayerData.GetSessionData(player)
	if not pData then
		warn("CompanionManager.GetCurrentParty: Player data not found for", player.Name)
		return { Player = true, Slot1 = nil, Slot2 = nil } 
	end
	if pData.CurrentParty and typeof(pData.CurrentParty) == 'table' then
		print(string.format("CompanionManager.GetCurrentParty: Returning current party for %s: %s", player.Name, HttpService:JSONEncode(pData.CurrentParty)))
		return pData.CurrentParty
	else
		print(string.format("CompanionManager.GetCurrentParty: CurrentParty not found or not a table for %s, initializing.", player.Name))
		pData.CurrentParty = { Player = true, Slot1 = nil, Slot2 = nil }
		return pData.CurrentParty
	end
end

-- 새로운 동료 획득 처리 함수
function CompanionManager.AcquireCompanion(player, companionDbId)
	print(string.format("CompanionManager.AcquireCompanion: Called for player %s, companionDbId %s", player.Name, tostring(companionDbId)))
	local pData = PlayerData.GetSessionData(player)
	if not pData then
		warn("CompanionManager.AcquireCompanion: Player data not found for", player.Name)
		return false, "플레이어 데이터를 찾을 수 없습니다."
	end

	pData.OwnedCompanions = pData.OwnedCompanions or {}

	if pData.OwnedCompanions[companionDbId] then
		warn("CompanionManager.AcquireCompanion:", player.Name, "already owns companion", companionDbId)
		return false, "이미 보유한 동료입니다."
	end

	local companionInfo = CompanionDatabase.GetCompanionInfo(companionDbId)
	if not companionInfo then
		warn("CompanionManager.AcquireCompanion: Companion info not found in CompanionDatabase for ID:", companionDbId)
		return false, "존재하지 않는 동료입니다."
	end

	local newCompanionData = {
		ID = companionDbId,
		Name = companionInfo.Name,
		Level = companionInfo.InitialLevel or 1,
		Exp = 0,
		Stats = {}, 
		Skills = {},
		EquippedItems = {}
	}

	if companionInfo.BaseStats and typeof(companionInfo.BaseStats) == 'table' then
		for statName, value in pairs(companionInfo.BaseStats) do
			newCompanionData.Stats[statName] = value
		end
		newCompanionData.Stats.CurrentHP = newCompanionData.Stats.MaxHP or 100 
		newCompanionData.Stats.CurrentMP = newCompanionData.Stats.MaxMP or 10  
		print(string.format("CompanionManager.AcquireCompanion: Initialized stats for %s - HP: %d/%d, MP: %d/%d", 
			newCompanionData.Name, newCompanionData.Stats.CurrentHP, newCompanionData.Stats.MaxHP,
			newCompanionData.Stats.CurrentMP, newCompanionData.Stats.MaxMP))
	else
		newCompanionData.Stats.MaxHP = 100
		newCompanionData.Stats.CurrentHP = 100
		newCompanionData.Stats.MaxMP = 10
		newCompanionData.Stats.CurrentMP = 10
		newCompanionData.Stats.STR = 5
		newCompanionData.Stats.AGI = 5
		newCompanionData.Stats.INT = 5
		newCompanionData.Stats.LUK = 5
		print(string.format("CompanionManager.AcquireCompanion: Initialized with DEFAULT stats for %s as BaseStats missing.", newCompanionData.Name))
	end

	if companionInfo.InitialSkills and typeof(companionInfo.InitialSkills) == 'table' then
		for _, skillId in ipairs(companionInfo.InitialSkills) do
			table.insert(newCompanionData.Skills, skillId)
		end
	end

	if companionInfo.EquippableSlots and typeof(companionInfo.EquippableSlots) == 'table' then
		for _, slotName in ipairs(companionInfo.EquippableSlots) do
			newCompanionData.EquippedItems[slotName] = nil
		end
	end

	pData.OwnedCompanions[companionDbId] = newCompanionData
	print(string.format("CompanionManager.AcquireCompanion: %s acquired companion '%s'. New OwnedCompanions: %s", player.Name, companionInfo.Name, HttpService:JSONEncode(pData.OwnedCompanions)))

	if companionUpdatedEvent then
		print("CompanionManager.AcquireCompanion: Firing CompanionUpdatedEvent (OwnedListUpdated)")
		companionUpdatedEvent:FireClient(player, { type = "OwnedListUpdated" })
	end

	return true, companionInfo.Name .. " 동료를 얻었습니다!"
end

-- 파티 설정 함수
function CompanionManager.SetParty(player, partyConfig)
	print(string.format("CompanionManager.SetParty: Called for player %s with partyConfig: %s", player.Name, partyConfig and HttpService:JSONEncode(partyConfig) or "nil"))
	local pData = PlayerData.GetSessionData(player)
	if not pData then
		warn("CompanionManager.SetParty: Player data not found for", player.Name)
		return false, "플레이어 데이터를 찾을 수 없습니다."
	end

	pData.OwnedCompanions = pData.OwnedCompanions or {}
	local currentParty = pData.CurrentParty or { Player = true, Slot1 = nil, Slot2 = nil }
	print(string.format("CompanionManager.SetParty: Current party before change: %s", HttpService:JSONEncode(currentParty)))

	local maxPartySlots = 2 
	if partyConfig and typeof(partyConfig) == 'table' and #partyConfig > maxPartySlots then
		warn("CompanionManager.SetParty: Party configuration array exceeds maximum slots. Length:", #partyConfig)
		return false, "파티 슬롯을 초과했습니다. (최대 " .. maxPartySlots .. "명)"
	end
	if typeof(partyConfig) ~= 'table' then
		warn("CompanionManager.SetParty: partyConfig is not a table. Received:", typeof(partyConfig))
		return false, "잘못된 파티 설정 요청입니다."
	end

	local newPartyFormation = { Player = true, Slot1 = nil, Slot2 = nil }
	local tempValidPartyMembers = {} 

	for i = 1, maxPartySlots do
		local companionId = partyConfig[i]
		if companionId then
			print(string.format("CompanionManager.SetParty: Checking companionId '%s' for slot %d", tostring(companionId), i))
			if not pData.OwnedCompanions[companionId] then
				warn(string.format("CompanionManager.SetParty: Player %s does not own companion %s.", player.Name, tostring(companionId)))
				return false, companionId .. " 동료를 보유하고 있지 않습니다."
			end
			local alreadyAdded = false
			for _, existingId in ipairs(tempValidPartyMembers) do
				if existingId == companionId then
					alreadyAdded = true
					break
				end
			end
			if not alreadyAdded then
				table.insert(tempValidPartyMembers, companionId)
			else
				warn(string.format("CompanionManager.SetParty: CompanionId %s is duplicated in partyConfig.", tostring(companionId)))
			end
		end
	end
	print(string.format("CompanionManager.SetParty: Valid members after filtering from partyConfig: %s", HttpService:JSONEncode(tempValidPartyMembers)))

	if tempValidPartyMembers[1] then
		newPartyFormation.Slot1 = tempValidPartyMembers[1]
	end
	if tempValidPartyMembers[2] then
		newPartyFormation.Slot2 = tempValidPartyMembers[2]
	end

	pData.CurrentParty = newPartyFormation
	print(string.format("CompanionManager.SetParty: %s's party updated to: %s", player.Name, HttpService:JSONEncode(pData.CurrentParty)))

	if companionUpdatedEvent then
		print("CompanionManager.SetParty: Firing CompanionUpdatedEvent (PartyUpdated)")
		companionUpdatedEvent:FireClient(player, { type = "PartyUpdated" })
	end

	return true, "파티가 성공적으로 변경되었습니다."
end

-- ##### [로직 변경] 동료에게 아이템 효과 적용 함수 (효과 있을 때만 아이템 소모) #####
function CompanionManager.ApplyItemEffectToCompanion(player, companionDbId, itemId)
	print(string.format("CompanionManager.ApplyItemEffectToCompanion: Player: %s, CompanionDbID: %s, ItemID: %s", player.Name, tostring(companionDbId), tostring(itemId)))

	local pData = PlayerData.GetSessionData(player)
	if not pData then
		warn("CompanionManager.ApplyItemEffectToCompanion: Player data not found for", player.Name)
		return false, "플레이어 데이터를 찾을 수 없습니다."
	end

	local itemInfo = ItemDatabase.GetItemInfo(itemId)
	if not itemInfo then
		warn("CompanionManager.ApplyItemEffectToCompanion: Item info not found for ItemID:", itemId)
		return false, "알 수 없는 아이템입니다."
	end

	if itemInfo.Type ~= "Consumable" then
		warn("CompanionManager.ApplyItemEffectToCompanion: Item is not a consumable:", itemInfo.Name)
		return false, itemInfo.Name .. "은(는) 사용할 수 없는 아이템입니다."
	end

	if InventoryManager.CountItem(player, itemId) < 1 then
		warn("CompanionManager.ApplyItemEffectToCompanion: Player does not have item:", itemInfo.Name)
		return false, itemInfo.Name .. " 아이템이 부족합니다."
	end

	if not pData.OwnedCompanions or not pData.OwnedCompanions[companionDbId] then
		warn("CompanionManager.ApplyItemEffectToCompanion: Companion not owned or data not found for DbID:", companionDbId)
		return false, "해당 동료를 소유하고 있지 않거나 정보를 찾을 수 없습니다."
	end
	local companionData = pData.OwnedCompanions[companionDbId]
	if not companionData.Stats then 
		companionData.Stats = { CurrentHP = 0, MaxHP = 1, CurrentMP = 0, MaxMP = 1 } 
		warn("CompanionManager.ApplyItemEffectToCompanion: Companion Stats table was missing for", companionDbId, "initializing.")
	end

	local effectApplied = false -- 실제 스탯 변화가 있었는지 여부
	local effectStat = itemInfo.Effect and itemInfo.Effect.Stat
	local effectValue = itemInfo.Effect and itemInfo.Effect.Value
	local notificationMessage = "" -- 클라이언트에 보낼 최종 메시지

	if not effectStat or not effectValue then
		warn("CompanionManager.ApplyItemEffectToCompanion: Item has no valid effect:", itemInfo.Name)
		return false, itemInfo.Name .. "에는 특별한 효과가 없습니다."
	end

	local originalHP = companionData.Stats.CurrentHP or 0
	local originalMP = companionData.Stats.CurrentMP or 0

	if effectStat == "HP" then
		local newHP = math.min(companionData.Stats.MaxHP or 0, originalHP + effectValue)
		if newHP > originalHP then 
			companionData.Stats.CurrentHP = newHP
			notificationMessage = string.format("%s의 HP가 %d 회복되었습니다.", companionData.Name, newHP - originalHP)
			effectApplied = true
		else
			notificationMessage = companionData.Name .. "의 HP가 이미 가득 찼습니다."
			-- effectApplied는 false로 유지 (실제 스탯 변화 없음)
		end
	elseif effectStat == "MP" then
		local newMP = math.min(companionData.Stats.MaxMP or 0, originalMP + effectValue)
		if newMP > originalMP then
			companionData.Stats.CurrentMP = newMP
			notificationMessage = string.format("%s의 MP가 %d 회복되었습니다.", companionData.Name, newMP - originalMP)
			effectApplied = true
		else
			notificationMessage = companionData.Name .. "의 MP가 이미 가득 찼습니다."
		end
	elseif effectStat == "HPMP" then
		local recoveredHP = 0
		local recoveredMP = 0
		local newHP_hpmp = math.min(companionData.Stats.MaxHP or 0, originalHP + effectValue)
		if newHP_hpmp > originalHP then 
			recoveredHP = newHP_hpmp - originalHP
			companionData.Stats.CurrentHP = newHP_hpmp 
		end

		local newMP_hpmp = math.min(companionData.Stats.MaxMP or 0, originalMP + effectValue)
		if newMP_hpmp > originalMP then 
			recoveredMP = newMP_hpmp - originalMP
			companionData.Stats.CurrentMP = newMP_hpmp 
		end

		if recoveredHP > 0 or recoveredMP > 0 then
			notificationMessage = string.format("%s의 HP가 %d, MP가 %d 회복되었습니다.", companionData.Name, recoveredHP, recoveredMP)
			effectApplied = true
		else
			notificationMessage = companionData.Name .. "의 HP와 MP가 이미 가득 찼습니다."
		end
	else
		warn("CompanionManager.ApplyItemEffectToCompanion: Unsupported item effect stat for companion:", effectStat)
		return false, itemInfo.Name .. " 효과를 동료에게 적용할 수 없습니다."
	end

	-- 실제 효과가 적용된 경우에만 아이템을 소모
	if effectApplied then
		local removed, removeMsg = InventoryManager.RemoveItem(player, itemId, 1)
		if not removed then
			warn("CompanionManager.ApplyItemEffectToCompanion: Failed to remove item from inventory! Rolling back companion stats.", removeMsg or "")
			-- 효과 롤백
			companionData.Stats.CurrentHP = originalHP
			companionData.Stats.CurrentMP = originalMP
			-- UI 업데이트 이벤트도 취소하거나 롤백된 정보를 보내야 할 수 있음 (여기서는 간단히 오류 반환)
			return false, "아이템 사용 중 오류가 발생했습니다 (아이템 제거 실패)."
		end
		print(string.format("CompanionManager: Used '%s' on %s. HP: %s -> %s, MP: %s -> %s. Item consumed.", 
			itemInfo.Name, companionData.Name, 
			tostring(originalHP), tostring(companionData.Stats.CurrentHP),
			tostring(originalMP), tostring(companionData.Stats.CurrentMP)
			))
		if inventoryUpdatedEvent then inventoryUpdatedEvent:FireClient(player) end -- 인벤토리 UI 업데이트
	else
		print(string.format("CompanionManager: Item '%s' effect not applied to %s (e.g. already full). Item NOT consumed.", itemInfo.Name, companionData.Name))
	end

	-- 클라이언트 알림 (효과 적용 여부와 관계없이 메시지는 전송)
	if NotifyPlayerEvent then
		NotifyPlayerEvent:FireClient(player, "ItemUsedOnCompanionResult", {
			success = effectApplied, -- 실제 스탯 변화가 있었는지 여부
			companionName = companionData.Name or "동료",
			itemName = itemInfo.Name,
			message = notificationMessage 
		})
	end

	-- 동료 스탯 UI 업데이트는 실제 변경이 있었을 때만
	if effectApplied and companionUpdatedEvent then
		print("CompanionManager.ApplyItemEffectToCompanion: Firing CompanionUpdatedEvent (CompanionStatUpdated) for", companionDbId)
		companionUpdatedEvent:FireClient(player, { type = "CompanionStatUpdated", companionDbId = companionDbId, updatedStats = companionData.Stats })
	end

	return true, notificationMessage -- 작업 시도 자체는 성공으로 간주하고, 메시지를 통해 상세 결과 전달
end
-- ########################################################################

return CompanionManager