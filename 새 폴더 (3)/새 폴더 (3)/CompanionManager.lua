-- ReplicatedStorage > Modules > CompanionManager.lua

--[[
  CompanionManager (ModuleScript)
  ���� ȹ��, ��Ƽ ���� �� ���� ���� ������ ó���ϴ� ��� (���� ��).
  *** [���� ����] AcquireCompanion �Լ����� ���� Stats ���̺� CurrentHP, CurrentMP ����� �ʱ�ȭ �߰� ***
  *** [��� �߰�] ���ῡ�� ������ ��� ȿ���� �����ϴ� ApplyItemEffectToCompanion �Լ� �߰� ***
  *** [���� ����] ApplyItemEffectToCompanion���� ���� ���� ��ȭ�� ���� ���� �������� �Ҹ��ϵ��� ���� ***
]]

local CompanionManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService") -- JSONEncode�� ���� �߰�
local modulesFolder = ReplicatedStorage:WaitForChild("Modules")

-- �ʿ��� ��� �ε�
local PlayerData = require(modulesFolder:WaitForChild("PlayerData"))
local CompanionDatabase = require(modulesFolder:WaitForChild("CompanionDatabase"))
local ItemDatabase = require(modulesFolder:WaitForChild("ItemDatabase"))
local InventoryManager = require(modulesFolder:WaitForChild("InventoryManager")) -- �κ��丮 ������ ���� �߰�
local SkillDatabase = require(modulesFolder:WaitForChild("SkillDatabase")) 

-- �̺�Ʈ ����
local companionUpdatedEvent = ReplicatedStorage:FindFirstChild("CompanionUpdatedEvent")
if not companionUpdatedEvent then
	warn("CompanionManager: CompanionUpdatedEvent RemoteEvent not found in ReplicatedStorage! Client updates might not work.")
end
local NotifyPlayerEvent = ReplicatedStorage:FindFirstChild("NotifyPlayerEvent") -- �˸��� �̺�Ʈ ����
if not NotifyPlayerEvent then
	warn("CompanionManager: NotifyPlayerEvent RemoteEvent not found in ReplicatedStorage!")
end
local inventoryUpdatedEvent = ReplicatedStorage:FindFirstChild("InventoryUpdatedEvent")
if not inventoryUpdatedEvent then
	warn("CompanionManager: InventoryUpdatedEvent RemoteEvent not found in ReplicatedStorage!")
end


-- �ʱ�ȭ �Լ�
function CompanionManager.Init()
	print("CompanionManager: Initialized (Server-side)")
end

-- �÷��̾ ������ ���� ��� ��������
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

-- �÷��̾��� ���� ��Ƽ ���� ��������
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

-- ���ο� ���� ȹ�� ó�� �Լ�
function CompanionManager.AcquireCompanion(player, companionDbId)
	print(string.format("CompanionManager.AcquireCompanion: Called for player %s, companionDbId %s", player.Name, tostring(companionDbId)))
	local pData = PlayerData.GetSessionData(player)
	if not pData then
		warn("CompanionManager.AcquireCompanion: Player data not found for", player.Name)
		return false, "�÷��̾� �����͸� ã�� �� �����ϴ�."
	end

	pData.OwnedCompanions = pData.OwnedCompanions or {}

	if pData.OwnedCompanions[companionDbId] then
		warn("CompanionManager.AcquireCompanion:", player.Name, "already owns companion", companionDbId)
		return false, "�̹� ������ �����Դϴ�."
	end

	local companionInfo = CompanionDatabase.GetCompanionInfo(companionDbId)
	if not companionInfo then
		warn("CompanionManager.AcquireCompanion: Companion info not found in CompanionDatabase for ID:", companionDbId)
		return false, "�������� �ʴ� �����Դϴ�."
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

	return true, companionInfo.Name .. " ���Ḧ ������ϴ�!"
end

-- ��Ƽ ���� �Լ�
function CompanionManager.SetParty(player, partyConfig)
	print(string.format("CompanionManager.SetParty: Called for player %s with partyConfig: %s", player.Name, partyConfig and HttpService:JSONEncode(partyConfig) or "nil"))
	local pData = PlayerData.GetSessionData(player)
	if not pData then
		warn("CompanionManager.SetParty: Player data not found for", player.Name)
		return false, "�÷��̾� �����͸� ã�� �� �����ϴ�."
	end

	pData.OwnedCompanions = pData.OwnedCompanions or {}
	local currentParty = pData.CurrentParty or { Player = true, Slot1 = nil, Slot2 = nil }
	print(string.format("CompanionManager.SetParty: Current party before change: %s", HttpService:JSONEncode(currentParty)))

	local maxPartySlots = 2 
	if partyConfig and typeof(partyConfig) == 'table' and #partyConfig > maxPartySlots then
		warn("CompanionManager.SetParty: Party configuration array exceeds maximum slots. Length:", #partyConfig)
		return false, "��Ƽ ������ �ʰ��߽��ϴ�. (�ִ� " .. maxPartySlots .. "��)"
	end
	if typeof(partyConfig) ~= 'table' then
		warn("CompanionManager.SetParty: partyConfig is not a table. Received:", typeof(partyConfig))
		return false, "�߸��� ��Ƽ ���� ��û�Դϴ�."
	end

	local newPartyFormation = { Player = true, Slot1 = nil, Slot2 = nil }
	local tempValidPartyMembers = {} 

	for i = 1, maxPartySlots do
		local companionId = partyConfig[i]
		if companionId then
			print(string.format("CompanionManager.SetParty: Checking companionId '%s' for slot %d", tostring(companionId), i))
			if not pData.OwnedCompanions[companionId] then
				warn(string.format("CompanionManager.SetParty: Player %s does not own companion %s.", player.Name, tostring(companionId)))
				return false, companionId .. " ���Ḧ �����ϰ� ���� �ʽ��ϴ�."
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

	return true, "��Ƽ�� ���������� ����Ǿ����ϴ�."
end

-- ##### [���� ����] ���ῡ�� ������ ȿ�� ���� �Լ� (ȿ�� ���� ���� ������ �Ҹ�) #####
function CompanionManager.ApplyItemEffectToCompanion(player, companionDbId, itemId)
	print(string.format("CompanionManager.ApplyItemEffectToCompanion: Player: %s, CompanionDbID: %s, ItemID: %s", player.Name, tostring(companionDbId), tostring(itemId)))

	local pData = PlayerData.GetSessionData(player)
	if not pData then
		warn("CompanionManager.ApplyItemEffectToCompanion: Player data not found for", player.Name)
		return false, "�÷��̾� �����͸� ã�� �� �����ϴ�."
	end

	local itemInfo = ItemDatabase.GetItemInfo(itemId)
	if not itemInfo then
		warn("CompanionManager.ApplyItemEffectToCompanion: Item info not found for ItemID:", itemId)
		return false, "�� �� ���� �������Դϴ�."
	end

	if itemInfo.Type ~= "Consumable" then
		warn("CompanionManager.ApplyItemEffectToCompanion: Item is not a consumable:", itemInfo.Name)
		return false, itemInfo.Name .. "��(��) ����� �� ���� �������Դϴ�."
	end

	if InventoryManager.CountItem(player, itemId) < 1 then
		warn("CompanionManager.ApplyItemEffectToCompanion: Player does not have item:", itemInfo.Name)
		return false, itemInfo.Name .. " �������� �����մϴ�."
	end

	if not pData.OwnedCompanions or not pData.OwnedCompanions[companionDbId] then
		warn("CompanionManager.ApplyItemEffectToCompanion: Companion not owned or data not found for DbID:", companionDbId)
		return false, "�ش� ���Ḧ �����ϰ� ���� �ʰų� ������ ã�� �� �����ϴ�."
	end
	local companionData = pData.OwnedCompanions[companionDbId]
	if not companionData.Stats then 
		companionData.Stats = { CurrentHP = 0, MaxHP = 1, CurrentMP = 0, MaxMP = 1 } 
		warn("CompanionManager.ApplyItemEffectToCompanion: Companion Stats table was missing for", companionDbId, "initializing.")
	end

	local effectApplied = false -- ���� ���� ��ȭ�� �־����� ����
	local effectStat = itemInfo.Effect and itemInfo.Effect.Stat
	local effectValue = itemInfo.Effect and itemInfo.Effect.Value
	local notificationMessage = "" -- Ŭ���̾�Ʈ�� ���� ���� �޽���

	if not effectStat or not effectValue then
		warn("CompanionManager.ApplyItemEffectToCompanion: Item has no valid effect:", itemInfo.Name)
		return false, itemInfo.Name .. "���� Ư���� ȿ���� �����ϴ�."
	end

	local originalHP = companionData.Stats.CurrentHP or 0
	local originalMP = companionData.Stats.CurrentMP or 0

	if effectStat == "HP" then
		local newHP = math.min(companionData.Stats.MaxHP or 0, originalHP + effectValue)
		if newHP > originalHP then 
			companionData.Stats.CurrentHP = newHP
			notificationMessage = string.format("%s�� HP�� %d ȸ���Ǿ����ϴ�.", companionData.Name, newHP - originalHP)
			effectApplied = true
		else
			notificationMessage = companionData.Name .. "�� HP�� �̹� ���� á���ϴ�."
			-- effectApplied�� false�� ���� (���� ���� ��ȭ ����)
		end
	elseif effectStat == "MP" then
		local newMP = math.min(companionData.Stats.MaxMP or 0, originalMP + effectValue)
		if newMP > originalMP then
			companionData.Stats.CurrentMP = newMP
			notificationMessage = string.format("%s�� MP�� %d ȸ���Ǿ����ϴ�.", companionData.Name, newMP - originalMP)
			effectApplied = true
		else
			notificationMessage = companionData.Name .. "�� MP�� �̹� ���� á���ϴ�."
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
			notificationMessage = string.format("%s�� HP�� %d, MP�� %d ȸ���Ǿ����ϴ�.", companionData.Name, recoveredHP, recoveredMP)
			effectApplied = true
		else
			notificationMessage = companionData.Name .. "�� HP�� MP�� �̹� ���� á���ϴ�."
		end
	else
		warn("CompanionManager.ApplyItemEffectToCompanion: Unsupported item effect stat for companion:", effectStat)
		return false, itemInfo.Name .. " ȿ���� ���ῡ�� ������ �� �����ϴ�."
	end

	-- ���� ȿ���� ����� ��쿡�� �������� �Ҹ�
	if effectApplied then
		local removed, removeMsg = InventoryManager.RemoveItem(player, itemId, 1)
		if not removed then
			warn("CompanionManager.ApplyItemEffectToCompanion: Failed to remove item from inventory! Rolling back companion stats.", removeMsg or "")
			-- ȿ�� �ѹ�
			companionData.Stats.CurrentHP = originalHP
			companionData.Stats.CurrentMP = originalMP
			-- UI ������Ʈ �̺�Ʈ�� ����ϰų� �ѹ�� ������ ������ �� �� ���� (���⼭�� ������ ���� ��ȯ)
			return false, "������ ��� �� ������ �߻��߽��ϴ� (������ ���� ����)."
		end
		print(string.format("CompanionManager: Used '%s' on %s. HP: %s -> %s, MP: %s -> %s. Item consumed.", 
			itemInfo.Name, companionData.Name, 
			tostring(originalHP), tostring(companionData.Stats.CurrentHP),
			tostring(originalMP), tostring(companionData.Stats.CurrentMP)
			))
		if inventoryUpdatedEvent then inventoryUpdatedEvent:FireClient(player) end -- �κ��丮 UI ������Ʈ
	else
		print(string.format("CompanionManager: Item '%s' effect not applied to %s (e.g. already full). Item NOT consumed.", itemInfo.Name, companionData.Name))
	end

	-- Ŭ���̾�Ʈ �˸� (ȿ�� ���� ���ο� ������� �޽����� ����)
	if NotifyPlayerEvent then
		NotifyPlayerEvent:FireClient(player, "ItemUsedOnCompanionResult", {
			success = effectApplied, -- ���� ���� ��ȭ�� �־����� ����
			companionName = companionData.Name or "����",
			itemName = itemInfo.Name,
			message = notificationMessage 
		})
	end

	-- ���� ���� UI ������Ʈ�� ���� ������ �־��� ����
	if effectApplied and companionUpdatedEvent then
		print("CompanionManager.ApplyItemEffectToCompanion: Firing CompanionUpdatedEvent (CompanionStatUpdated) for", companionDbId)
		companionUpdatedEvent:FireClient(player, { type = "CompanionStatUpdated", companionDbId = companionDbId, updatedStats = companionData.Stats })
	end

	return true, notificationMessage -- �۾� �õ� ��ü�� �������� �����ϰ�, �޽����� ���� �� ��� ����
end
-- ########################################################################

return CompanionManager