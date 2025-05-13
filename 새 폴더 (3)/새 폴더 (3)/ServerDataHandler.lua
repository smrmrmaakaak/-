-- ServerDataHandler.lua

-- 필요한 서비스 가져오기
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")

-- <<< 수정: 모듈 로드를 먼저 수행 >>>
print("ServerDataHandler: Loading modules...")
local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local PlayerData = require(modulesFolder:WaitForChild("PlayerData"))
local InventoryManager = require(modulesFolder:WaitForChild("InventoryManager"))
local successCombatMgr, CombatManager = pcall(function() return require(modulesFolder:WaitForChild("CombatManager")) end); if not successCombatMgr then warn("CombatManager 로드 실패", CombatManager) end
local SkillDatabase = require(modulesFolder:WaitForChild("SkillDatabase"))
local ItemDatabase = require(modulesFolder:WaitForChild("ItemDatabase"))
local GachaDatabase = require(modulesFolder:WaitForChild("GachaDatabase"))
local CraftingDatabase = require(modulesFolder:WaitForChild("CraftingDatabase"))
local DevilFruitManager = require(modulesFolder:WaitForChild("DevilFruitManager"))
local CompanionManager = require(modulesFolder:WaitForChild("CompanionManager")) -- 서버 측 CompanionManager
print("ServerDataHandler: Core modules loaded.")
-- <<< 모듈 로드 끝 >>>

-- <<< RemoteEvent/Function 참조도 미리 수행 >>>
print("ServerDataHandler: Referencing RemoteEvents/Functions...")
local remoteTimeout = 10
local getPlayerInventoryFunction = ReplicatedStorage:WaitForChild("GetPlayerInventoryFunction", remoteTimeout)
local purchaseItemEvent = ReplicatedStorage:WaitForChild("PurchaseItemEvent", remoteTimeout)
local useItemEvent = ReplicatedStorage:WaitForChild("UseItemEvent", remoteTimeout)
local inventoryUpdatedEvent = ReplicatedStorage:WaitForChild("InventoryUpdatedEvent", remoteTimeout)
local playerStatsUpdatedEvent = ReplicatedStorage:WaitForChild("PlayerStatsUpdatedEvent", remoteTimeout)
local equipItemEvent_ref = ReplicatedStorage:WaitForChild("EquipItemEvent", remoteTimeout)
local unequipItemEvent_ref = ReplicatedStorage:WaitForChild("UnequipItemEvent", remoteTimeout)
local getEquippedItemsFunction = ReplicatedStorage:WaitForChild("GetEquippedItems", remoteTimeout)
local sellItemEvent = ReplicatedStorage:WaitForChild("SellItemEvent", remoteTimeout)
local craftItemEvent = ReplicatedStorage:WaitForChild("CraftItemEvent", remoteTimeout)
local pullGachaFunction = ReplicatedStorage:WaitForChild("PullGachaFunction", remoteTimeout)
local spendStatPointEvent = ReplicatedStorage:WaitForChild("SpendStatPointEvent", remoteTimeout)
local debugLevelUpEvent = ReplicatedStorage:WaitForChild("DebugLevelUpEvent", remoteTimeout)
local debugAddGoldEvent = ReplicatedStorage:WaitForChild("DebugAddGoldEvent", remoteTimeout)
local debugAddExpEvent = ReplicatedStorage:WaitForChild("DebugAddExpEvent", remoteTimeout)
local requestStartCombatEvent = ReplicatedStorage:WaitForChild("RequestStartCombatEvent", remoteTimeout)
local requestPlayerAttackEvent = ReplicatedStorage:WaitForChild("RequestPlayerAttackEvent", remoteTimeout)
local requestPlayerUseSkillEvent = ReplicatedStorage:WaitForChild("RequestPlayerUseSkillEvent", remoteTimeout)
local purchaseSkillEvent = ReplicatedStorage:WaitForChild("PurchaseSkillEvent", remoteTimeout)
local SkillLearnedEvent = ReplicatedStorage:WaitForChild("SkillLearnedEvent", remoteTimeout)
local RequestSkillListEvent = ReplicatedStorage:WaitForChild("RequestSkillListEvent", remoteTimeout)
local ReceiveSkillListEvent = ReplicatedStorage:WaitForChild("ReceiveSkillListEvent", remoteTimeout)
local useDevilFruitEvent = ReplicatedStorage:WaitForChild("UseDevilFruitEvent", remoteTimeout)
local requestTestFruitEvent = ReplicatedStorage:WaitForChild("RequestTestFruitEvent", remoteTimeout)
local requestRemoveDevilFruitEvent = ReplicatedStorage:WaitForChild("RequestRemoveDevilFruitEvent", remoteTimeout)
local requestPullDevilFruitEvent = ReplicatedStorage:WaitForChild("RequestPullDevilFruitEvent", remoteTimeout)
local requestPlayerDefendEvent = ReplicatedStorage:WaitForChild("RequestPlayerDefendEvent", remoteTimeout)
local requestPlayerUseItemEvent = ReplicatedStorage:WaitForChild("RequestPlayerUseItemEvent", remoteTimeout)
local NotifyPlayerEvent = ReplicatedStorage:WaitForChild("NotifyPlayerEvent", remoteTimeout)
local EnhanceItemEvent = ReplicatedStorage:WaitForChild("EnhanceItemEvent", remoteTimeout)
local EnhancementResultEvent = ReplicatedStorage:WaitForChild("EnhancementResultEvent", remoteTimeout)

local getOwnedCompanionsFunction = ReplicatedStorage:WaitForChild("GetOwnedCompanionsFunction", remoteTimeout)
local getCurrentPartyFunction = ReplicatedStorage:WaitForChild("GetCurrentPartyFunction", remoteTimeout)
local setPartyEvent = ReplicatedStorage:WaitForChild("SetPartyEvent", remoteTimeout)

-- ##### 리더보드 데이터 RemoteFunction 참조 추가 #####
local getLeaderboardDataFunction = ReplicatedStorage:WaitForChild("GetLeaderboardDataFunction", remoteTimeout)
-- #################################################

-- ##### [기능 추가] 동료에게 아이템 사용 이벤트 참조 #####
local UseItemOnCompanionEvent = ReplicatedStorage:FindFirstChild("UseItemOnCompanionEvent")
if not UseItemOnCompanionEvent then
	warn("ServerDataHandler: UseItemOnCompanionEvent RemoteEvent를 찾을 수 없습니다! Studio에서 ReplicatedStorage에 생성해야 합니다.")
else
	print("ServerDataHandler: UseItemOnCompanionEvent 참조 성공.")
end
-- #####################################################

print("ServerDataHandler: RemoteEvents/Functions referenced.")
-- <<< 참조 끝 >>>


-- 플레이어 접속/종료/서버 종료 함수 정의 (이제 PlayerData가 로드된 후 정의됨)
local function onPlayerAdded(player)
	print("... onPlayerAdded for", player.Name);
	PlayerData.LoadData(player)
	if CompanionManager and CompanionManager.AcquireCompanion then
		local pData = PlayerData.GetSessionData(player)
		if pData and pData.OwnedCompanions and not pData.OwnedCompanions["COMP001"] then
			CompanionManager.AcquireCompanion(player, "COMP001")
		end
		if pData and pData.OwnedCompanions and not pData.OwnedCompanions["COMP002"] then
			CompanionManager.AcquireCompanion(player, "COMP002")
		end
	end
end

local function onPlayerRemoving(player)
	print("... onPlayerRemoving for", player.Name);
	PlayerData.SaveData(player);
	PlayerData.ClearSessionData(player)
end

local function onServerShutdown()
	print("... onServerShutdown");
	if Players then
		local currentPlayers = Players:GetPlayers()
		for _, p in ipairs(currentPlayers) do
			pcall(function()
				if PlayerData then
					PlayerData.SaveData(p);
					PlayerData.ClearSessionData(p)
				end
			end)
		end
	end
end

task.wait(0.1)

if Players then
	print("ServerDataHandler DEBUG: Handling existing players...");
	local success, playersList = pcall(function() return Players:GetPlayers() end)
	if success and playersList then
		for _, player in ipairs(playersList) do
			task.spawn(onPlayerAdded, player)
		end
	else
		warn("ServerDataHandler: Failed to get players list or Players service is invalid at initial handling.")
	end
	print("...existing players handled.")

	local playerAddedConnection, playerRemovingConnection
	playerAddedConnection = Players.PlayerAdded:Connect(onPlayerAdded)
	playerRemovingConnection = Players.PlayerRemoving:Connect(onPlayerRemoving)
	game:BindToClose(function()
		onServerShutdown()
		if playerAddedConnection then playerAddedConnection:Disconnect() end
		if playerRemovingConnection then playerRemovingConnection:Disconnect() end
	end)
else
	warn("ServerDataHandler: Players service is nil even after waiting! Cannot handle players or connect events.")
	return
end

print("ServerDataHandler: Player handling and core event connections complete.")

-- 이벤트 핸들러 함수들 정의 (이제 안전하게 모듈 참조 가능)
function onGetPlayerInventory(player) return PlayerData.GetSessionData(player).Inventory or {} end
function onPurchaseItemRequest(player,itemId) print("구매 요청:",itemId); if typeof(itemId)~='number' then return end; local item=ItemDatabase.Items[itemId]; if not item or not item.Price or item.Price<=0 then return end; local stats=PlayerData.GetSessionData(player); if not stats then return end; if stats.Gold < item.Price then print("DEBUG: 구매 실패 - 골드 부족. Player:", player.Name, "Item:", itemId); if NotifyPlayerEvent then print("DEBUG: 서버: NotEnoughGold 이벤트 발송 시도"); NotifyPlayerEvent:FireClient(player, "PurchaseFailed", { reason = "NotEnoughGold" }) else warn("ServerDataHandler: NotifyPlayerEvent not found, cannot notify client about insufficient gold.") end; return end; local gold=stats.Gold; local goldOk=PlayerData.UpdateStat(player,"Gold",gold-item.Price); if not goldOk then return end; local added,msg=InventoryManager.AddItem(player,itemId,1); if added then if playerStatsUpdatedEvent then playerStatsUpdatedEvent:FireClient(player) end; if NotifyPlayerEvent then print(string.format("DEBUG: 서버: ItemPurchased 이벤트 발송 시도 - 아이템명: %s", item.Name or "아이템")); NotifyPlayerEvent:FireClient(player, "ItemPurchased", { itemName = item.Name or "아이템", quantity = 1 }) end else PlayerData.UpdateStat(player,"Gold",gold); if playerStatsUpdatedEvent then playerStatsUpdatedEvent:FireClient(player) end; if NotifyPlayerEvent then print(string.format("DEBUG: 서버: PurchaseFailed 이벤트 발송 시도 - 이유: %s", msg or "아이템 추가 실패")); NotifyPlayerEvent:FireClient(player, "PurchaseFailed", { reason = msg or "아이템 추가 실패" }) end end end
function onUseItemRequest(player, itemId) 
	print("플레이어 아이템 사용 요청 (비전투):", player.Name, "ItemID:", itemId)
	if typeof(itemId) ~= 'number' then return end
	local itemInfo = ItemDatabase.Items[itemId]
	if not itemInfo or itemInfo.Type ~= "Consumable" then 
		if NotifyPlayerEvent then NotifyPlayerEvent:FireClient(player, "ActionFailed", {reason = "사용할 수 없는 아이템입니다."}) end
		return 
	end

	local playerData = PlayerData.GetSessionData(player)
	if not playerData then return end

	local hasItem = InventoryManager.CountItem(player, itemId) > 0
	if not hasItem then
		if NotifyPlayerEvent then NotifyPlayerEvent:FireClient(player, "ActionFailed", {reason = itemInfo.Name .. " 아이템이 부족합니다."}) end
		return
	end

	local effectApplied = false
	local uiUpdateData = { playerStats = {}, playerStatus = { effects = {} } }

	if itemInfo.Effect then
		local statToChange = itemInfo.Effect.Stat
		local valueChange = itemInfo.Effect.Value
		local currentStats = PlayerData.GetStats(player) -- 최신 스탯 가져오기

		if statToChange == "HP" and valueChange then
			local newHP = math.min(currentStats.MaxHP, currentStats.CurrentHP + valueChange)
			if PlayerData.UpdateStat(player, "CurrentHP", newHP) then effectApplied = true end
		elseif statToChange == "MP" and valueChange then
			local newMP = math.min(currentStats.MaxMP, currentStats.CurrentMP + valueChange)
			if PlayerData.UpdateStat(player, "CurrentMP", newMP) then effectApplied = true end
		elseif statToChange == "HPMP" and valueChange then
			local hpOk = PlayerData.UpdateStat(player, "CurrentHP", math.min(currentStats.MaxHP, currentStats.CurrentHP + valueChange))
			local mpOk = PlayerData.UpdateStat(player, "CurrentMP", math.min(currentStats.MaxMP, currentStats.CurrentMP + valueChange))
			if hpOk and mpOk then effectApplied = true end
			-- TODO: 비전투 버프/디버프 아이템 효과 로직 추가 (필요하다면)
			-- elseif itemInfo.Effect.Type == "BuffDebuff" then ... end
		end
	end

	if effectApplied then
		local removed, remMsg = InventoryManager.RemoveItem(player, itemId, 1)
		if removed then
			print("비전투 아이템 사용 완료:", player.Name, itemInfo.Name)
			if NotifyPlayerEvent then NotifyPlayerEvent:FireClient(player, "ItemUsed", {itemName = itemInfo.Name}) end

			-- UI 업데이트를 위해 최신 플레이어 스탯 전송
			local updatedStats = PlayerData.GetStats(player)
			uiUpdateData.playerStats = updatedStats -- HUDManager 등에서 사용
			-- 비전투 상태 효과는 현재 playerStatusEffects에 직접 관리하지 않으므로 빈 테이블 전달 또는 다른 방식 고려
			uiUpdateData.playerStatus.effects = playerData.statusEffects or {} -- PlayerData에 statusEffects가 있다면 사용

			if playerStatsUpdatedEvent then playerStatsUpdatedEvent:FireClient(player) end -- 스탯 변경 알림
			if inventoryUpdatedEvent then inventoryUpdatedEvent:FireClient(player) end -- 인벤토리 변경 알림

		else
			warn("비전투 아이템 사용 후 제거 실패:", remMsg, "롤백 시도 안함 (이미 효과 적용됨)")
			-- 참고: 이 경우 이미 스탯 효과가 적용되었을 수 있으므로, 롤백이 복잡할 수 있습니다.
			-- 아이템 제거 실패 시 효과를 적용하지 않거나, 더 정교한 트랜잭션 관리가 필요할 수 있습니다.
			if NotifyPlayerEvent then NotifyPlayerEvent:FireClient(player, "ActionFailed", {reason = "아이템 사용 중 오류가 발생했습니다 (제거 실패)."}) end
		end
	else
		print("비전투 아이템 효과 적용 실패 (또는 효과 없음):", player.Name, itemInfo.Name)
		-- 효과가 없거나 적용에 실패했어도 아이템 소모는 이미 위에서 처리 (RemoveItem 호출 전)
		-- 만약 효과 적용 실패 시 아이템을 돌려주려면 여기서 AddItem 로직 추가
		if NotifyPlayerEvent then NotifyPlayerEvent:FireClient(player, "ActionFailed", {reason = itemInfo.Name .. " 효과를 적용할 수 없습니다."}) end
	end
end

function onEquipItemRequest(player, itemId) print(string.format("===== [DEBUG] ServerDataHandler: EquipItemEvent 수신! Player: %s, ItemID: %s =====", player.Name, tostring(itemId))); print("[ServerDataHandler] 장착 요청 받음 (ItemID: " .. tostring(itemId) .. ")"); if typeof(itemId)~="number" then warn("잘못된 ItemID 타입"); return end; print(string.format("[DEBUG] ServerDataHandler: Calling InventoryManager.EquipItem for Player: %s, ItemID: %s", player.Name, tostring(itemId))); local success,message=InventoryManager.EquipItem(player,itemId); print(string.format("[DEBUG] ServerDataHandler: InventoryManager.EquipItem returned - Success: %s, Message: %s", tostring(success), tostring(message))); if not success and message and NotifyPlayerEvent then print(string.format("[DEBUG] ServerDataHandler: Firing NotifyPlayerEvent (Equip Failed) - Player: %s, Type: %s, Reason: %s", player.Name, "EquipFailed", message)); NotifyPlayerEvent:FireClient(player,"EquipFailed",{reason = message}) end; print(string.format("===== [DEBUG] ServerDataHandler: EquipItemEvent 처리 완료 for ItemID: %s =====", tostring(itemId))) end
function onUnequipItemRequest(player, slot) print(string.format("===== [DEBUG] ServerDataHandler: UnequipItemEvent 수신! Player: %s, Slot: %s =====", player.Name, tostring(slot))); print("[ServerDataHandler] Received UnequipItemEvent from player: " .. player.Name .. " for slot: " .. tostring(slot)); if typeof(slot)~="string" then warn("잘못된 Slot 타입"); return end; print(string.format("[DEBUG] ServerDataHandler: Calling InventoryManager.UnequipItem for Player: %s, Slot: %s", player.Name, tostring(slot))); local success,message=InventoryManager.UnequipItem(player,slot); print(string.format("[DEBUG] ServerDataHandler: InventoryManager.UnequipItem returned - Success: %s, Message: %s", tostring(success), tostring(message))); if not success and message and NotifyPlayerEvent then print(string.format("[DEBUG] ServerDataHandler: Firing NotifyPlayerEvent (Unequip Failed) - Player: %s, Type: %s, Reason: %s", player.Name, "UnequipFailed", message)); NotifyPlayerEvent:FireClient(player,"UnequipFailed",{reason = message}) end; print(string.format("===== [DEBUG] ServerDataHandler: UnequipItemEvent 처리 완료 for Slot: %s =====", tostring(slot))) end
function onGetEquippedItems(player) return PlayerData.GetSessionData(player).Equipped or {} end
function onSellItemRequest(player,itemId,quantity) print("판매:",itemId,quantity);if typeof(itemId)~='number' or typeof(quantity)~='number' or quantity<=0 then return end; InventoryManager.SellItem(player,itemId,quantity) end
function onCraftItemRequest(player,recipeId) print("제작:",recipeId);if typeof(recipeId)~='number' then return end; InventoryManager.CraftItem(player,recipeId) end
function onPullGachaRequest(player,poolId) print("뽑기:",poolId);if typeof(poolId)~='string' then return end;local pool=GachaDatabase.GachaPools[poolId];if not pool then return end;local cost=pool.Cost;if not cost then return end;local stats=PlayerData.GetSessionData(player);if not stats then return end;local enough=false;if cost.Currency=="Gold" then enough=(stats.Gold>=cost.Amount) end;if not enough then return end;local consumed=false;local curCost=0;if cost.Currency=="Gold" then curCost=stats.Gold;consumed=PlayerData.UpdateStat(player,"Gold",curCost-cost.Amount) end;if not consumed then return end;local pulled=GachaDatabase.PullItem(poolId);if not pulled then PlayerData.UpdateStat(player,"Gold",curCost); return end;local added=InventoryManager.AddItem(player,pulled,1);if not added then PlayerData.UpdateStat(player,"Gold",curCost); return end;if playerStatsUpdatedEvent then playerStatsUpdatedEvent:FireClient(player) end;return pulled end
function onSpendStatPointRequest(player,statToIncrease) print("스탯 투자 요청:",statToIncrease);local valid={STR=true,AGI=true,INT=true,LUK=true};if typeof(statToIncrease)~='string' or not valid[statToIncrease] then return end; PlayerData.SpendStatPoint(player,statToIncrease) end
function onDebugLevelUp(player) local stats=PlayerData.GetSessionData(player); if stats then local needed=(stats.MaxExp-stats.Exp)+1; PlayerData.AddExp(player,needed) end end
function onDebugAddGold(player, amount) if typeof(amount)~='number' or amount<=0 then return end; local stats=PlayerData.GetSessionData(player); if stats then PlayerData.UpdateStat(player,"Gold",stats.Gold+amount); if playerStatsUpdatedEvent then playerStatsUpdatedEvent:FireClient(player) end end end
function onDebugAddExp(player, amount) if typeof(amount)~='number' or amount<=0 then return end; PlayerData.AddExp(player,amount) end
function onRequestStartCombat(player, enemyIdOrIds) if typeof(enemyIdOrIds)~='number' and typeof(enemyIdOrIds)~='table' then return end; if CombatManager then CombatManager.StartNewCombat(player,enemyIdOrIds) end end
function onRequestPlayerAttack(player, targetId) if typeof(targetId)~='number' then return end; if CombatManager then CombatManager.PlayerAttack(player,targetId) end end
function onRequestPlayerUseSkill(player, skillId, targetId) if (typeof(skillId)~='number' and typeof(skillId)~='string') or (targetId~=nil and typeof(targetId)~='number') then return end; if CombatManager then CombatManager.PlayerUseSkill(player,skillId,targetId) end end
function onRequestSkillList(player) local skills={};local _,stats=pcall(PlayerData.GetSessionData,player);if stats and stats.Skills then skills=stats.Skills end;if ReceiveSkillListEvent then ReceiveSkillListEvent:FireClient(player,skills) end end
function onPurchaseSkillRequest(player,skillId) if typeof(skillId)~='number' and typeof(skillId)~='string' then return end;local skill=SkillDatabase.Skills[skillId];if not skill or not skill.Price or skill.Price<=0 then return end;local stats=PlayerData.GetSessionData(player);if not stats then return end;local learned=false;if stats.Skills then for _,id in ipairs(stats.Skills) do if id==skillId then learned=true;break end end end;if learned then return end; if stats.Gold<skill.Price then if NotifyPlayerEvent then NotifyPlayerEvent:FireClient(player, "PurchaseFailed", { reason = "NotEnoughGold" }) end; return end;local gold=stats.Gold;local goldOk=PlayerData.UpdateStat(player,"Gold",gold-skill.Price);if not goldOk then return end;local learnOk=PlayerData.LearnSkill(player,skillId);if learnOk then if playerStatsUpdatedEvent then playerStatsUpdatedEvent:FireClient(player) end;if SkillLearnedEvent then SkillLearnedEvent:FireClient(player,skillId) end else PlayerData.UpdateStat(player,"Gold",gold) end end
function onUseDevilFruitRequest(player, itemId) print("ServerDataHandler: 악마열매 사용 요청 (ItemID: "..tostring(itemId)..")"); if typeof(itemId)~="number" then warn("잘못된 ItemID 타입"); return end; if DevilFruitManager and DevilFruitManager.EatFruit then local success,message=DevilFruitManager.EatFruit(player,itemId); if not success and message and NotifyPlayerEvent then NotifyPlayerEvent:FireClient(player,"DevilFruitUseFailed",{reason=message}) end end end
function onRequestTestFruit(player) local fruitId=5001; if InventoryManager then InventoryManager.AddItem(player,fruitId,1) end end
function onRequestRemoveDevilFruit(player) if DevilFruitManager then local ok,msg=DevilFruitManager.RemoveFruit(player); if ok then if playerStatsUpdatedEvent then playerStatsUpdatedEvent:FireClient(player) end; if NotifyPlayerEvent then NotifyPlayerEvent:FireClient(player, "DevilFruitRemoved", { message = msg }) end else print("능력 제거 실패:",msg); if NotifyPlayerEvent then NotifyPlayerEvent:FireClient(player, "ActionFailed", { reason = msg }) end end end end
function onRequestPullDevilFruit(player) if DevilFruitManager then local ok,msg=DevilFruitManager.PullRandomFruit(player); if ok then if playerStatsUpdatedEvent then playerStatsUpdatedEvent:FireClient(player) end; if NotifyPlayerEvent then NotifyPlayerEvent:FireClient(player, "DevilFruitPulled", { message = msg }) end else print("뽑기 실패:",msg); if NotifyPlayerEvent then NotifyPlayerEvent:FireClient(player, "ActionFailed", { reason = msg }) end end end end
function onRequestPlayerDefend(player) if CombatManager then CombatManager.PlayerDefend(player) end end
function onRequestPlayerUseItem(player, itemId, targetId) if typeof(itemId)~='number' or (targetId~=nil and typeof(targetId)~='number') then return end; if CombatManager then CombatManager.PlayerUseItem(player,itemId,targetId) end end
function onEnhanceItemRequest(player, inventorySlotIndex) print("ServerDataHandler: 강화 요청 받음 - Player:", player.Name, "Index:", inventorySlotIndex); if typeof(inventorySlotIndex) ~= 'number' then warn("ServerDataHandler: 잘못된 인벤토리 인덱스 타입:", inventorySlotIndex); if EnhancementResultEvent then EnhancementResultEvent:FireClient(player, {success=false, reason="잘못된 요청입니다."}) end; return end; if InventoryManager and InventoryManager.EnhanceItem then InventoryManager.EnhanceItem(player, inventorySlotIndex) else warn("ServerDataHandler: InventoryManager.EnhanceItem 함수를 찾을 수 없습니다!"); if EnhancementResultEvent then EnhancementResultEvent:FireClient(player, {success=false, reason="강화 시스템 오류입니다."}) end end end

function onGetOwnedCompanions(player)
	if CompanionManager and CompanionManager.GetOwnedCompanions then
		return CompanionManager.GetOwnedCompanions(player)
	end
	warn("ServerDataHandler: CompanionManager.GetOwnedCompanions is not available.")
	return {}
end

function onGetCurrentParty(player)
	if CompanionManager and CompanionManager.GetCurrentParty then
		return CompanionManager.GetCurrentParty(player)
	end
	warn("ServerDataHandler: CompanionManager.GetCurrentParty is not available.")
	return {}
end

function onSetPartyRequest(player, partyConfig)
	print("ServerDataHandler: SetPartyEvent 수신 - Player:", player.Name, "Config:", partyConfig)
	if CompanionManager and CompanionManager.SetParty then
		local success, message = CompanionManager.SetParty(player, partyConfig)
		if not success and message and NotifyPlayerEvent then
			NotifyPlayerEvent:FireClient(player, "PartyUpdateFailed", { reason = message })
		end
	else
		warn("ServerDataHandler: CompanionManager.SetParty is not available.")
	end
end

-- ##### 리더보드 데이터 가져오기 함수 추가 #####
function onGetLeaderboardData(requestingPlayer)
	print("ServerDataHandler: GetLeaderboardDataFunction 호출됨 by", requestingPlayer.Name)
	local leaderboard = {}
	local allPlayers = Players:GetPlayers()

	for _, playerInstance in ipairs(allPlayers) do
		local pData = PlayerData.GetSessionData(playerInstance)
		if pData then
			table.insert(leaderboard, {
				userId = playerInstance.UserId, 
				name = playerInstance.Name,
				level = pData.Level or 1,
				gold = pData.Gold or 0
			})
		else
			warn("ServerDataHandler: GetLeaderboardData - 플레이어 " .. playerInstance.Name .. "의 세션 데이터 없음")
		end
	end
	print("ServerDataHandler: 리더보드 데이터 생성 완료, 플레이어 수:", #leaderboard)
	return leaderboard
end
-- ##########################################

-- ##### [기능 추가] 동료에게 아이템 사용 요청 처리 함수 #####
function onUseItemOnCompanionRequest(player, itemId, companionDbId)
	print(string.format("ServerDataHandler: UseItemOnCompanionEvent 수신! Player: %s, ItemID: %s, CompanionDbID: %s", player.Name, tostring(itemId), tostring(companionDbId)))
	if typeof(itemId) ~= "number" or typeof(companionDbId) ~= "string" then -- 동료 ID는 문자열일 수 있음 (COMP001 등)
		warn("ServerDataHandler: UseItemOnCompanion - 잘못된 매개변수 타입입니다.")
		if NotifyPlayerEvent then NotifyPlayerEvent:FireClient(player, "ActionFailed", {reason = "잘못된 요청입니다."}) end
		return
	end

	if CompanionManager and CompanionManager.ApplyItemEffectToCompanion then
		-- CompanionManager에 실제 로직을 구현할 함수 호출 (다음 단계에서 CompanionManager.lua에 생성 예정)
		local success, message = CompanionManager.ApplyItemEffectToCompanion(player, companionDbId, itemId)
		if not success and message then
			if NotifyPlayerEvent then NotifyPlayerEvent:FireClient(player, "ActionFailed", {reason = message}) end
		end
		-- 성공 시 알림은 ApplyItemEffectToCompanion 내부에서 처리하거나, 여기서 추가 가능
	else
		warn("ServerDataHandler: CompanionManager.ApplyItemEffectToCompanion 함수를 찾을 수 없습니다!")
		if NotifyPlayerEvent then NotifyPlayerEvent:FireClient(player, "ActionFailed", {reason = "아이템 사용 처리 중 오류가 발생했습니다."}) end
	end
end
-- #####################################################


-- 이벤트 연결
print("ServerDataHandler: Connecting remaining events...")

if RequestSkillListEvent and RequestSkillListEvent:IsA("RemoteEvent") then print("[DEBUG] Connecting RequestSkillListEvent:", RequestSkillListEvent); RequestSkillListEvent.OnServerEvent:Connect(onRequestSkillList) else warn("ServerDataHandler: RequestSkillListEvent is nil or not a RemoteEvent!") end
if getPlayerInventoryFunction and getPlayerInventoryFunction:IsA("RemoteFunction") then print("[DEBUG] Connecting GetPlayerInventoryFunction:", getPlayerInventoryFunction); getPlayerInventoryFunction.OnServerInvoke = onGetPlayerInventory; print("ServerDataHandler: GetPlayerInventoryFunction.OnServerInvoke connected.") else warn("ServerDataHandler: Failed to connect GetPlayerInventoryFunction - Instance is nil or not a RemoteFunction:", getPlayerInventoryFunction) end
if purchaseItemEvent and purchaseItemEvent:IsA("RemoteEvent") then print("[DEBUG] Connecting PurchaseItemEvent:", purchaseItemEvent); if onPurchaseItemRequest and typeof(onPurchaseItemRequest) == "function" then purchaseItemEvent.OnServerEvent:Connect(onPurchaseItemRequest); print("ServerDataHandler: PurchaseItemEvent.OnServerEvent connected.") else warn("ServerDataHandler: Failed to connect PurchaseItemEvent - onPurchaseItemRequest is not a function:", typeof(onPurchaseItemRequest)) end else warn("ServerDataHandler: Failed to connect PurchaseItemEvent - Instance is nil or not a RemoteEvent:", purchaseItemEvent) end
if useItemEvent and useItemEvent:IsA("RemoteEvent") then print("[DEBUG] Connecting UseItemEvent:", useItemEvent); useItemEvent.OnServerEvent:Connect(onUseItemRequest) else warn("useItemEvent is invalid") end
local currentEquipEvent = ReplicatedStorage:FindFirstChild("EquipItemEvent"); if currentEquipEvent and currentEquipEvent:IsA("RemoteEvent") then if onEquipItemRequest and typeof(onEquipItemRequest) == "function" then currentEquipEvent.OnServerEvent:Connect(onEquipItemRequest); print("ServerDataHandler: EquipItemEvent connected.") else warn("ServerDataHandler: Cannot connect EquipItemEvent, handler is not a function:", typeof(onEquipItemRequest)) end else warn("ServerDataHandler: equipItemEvent is invalid or not a RemoteEvent (re-check failed):", currentEquipEvent) end
local currentUnequipEvent = ReplicatedStorage:FindFirstChild("UnequipItemEvent"); if currentUnequipEvent and currentUnequipEvent:IsA("RemoteEvent") then if onUnequipItemRequest and typeof(onUnequipItemRequest) == "function" then currentUnequipEvent.OnServerEvent:Connect(onUnequipItemRequest); print("ServerDataHandler: UnequipItemEvent connected.") else warn("ServerDataHandler: Cannot connect UnequipItemEvent, handler is not a function:", typeof(onUnequipItemRequest)) end else warn("ServerDataHandler: unequipItemEvent is invalid or not a RemoteEvent (re-check failed):", currentUnequipEvent) end
if getEquippedItemsFunction and getEquippedItemsFunction:IsA("RemoteFunction") then print("[DEBUG] Connecting GetEquippedItemsFunction:", getEquippedItemsFunction); getEquippedItemsFunction.OnServerInvoke = onGetEquippedItems else warn("getEquippedItemsFunction is invalid") end
if sellItemEvent and sellItemEvent:IsA("RemoteEvent") then print("[DEBUG] Connecting SellItemEvent:", sellItemEvent); sellItemEvent.OnServerEvent:Connect(onSellItemRequest) else warn("sellItemEvent is invalid") end
if craftItemEvent and craftItemEvent:IsA("RemoteEvent") then print("[DEBUG] Connecting CraftItemEvent:", craftItemEvent); craftItemEvent.OnServerEvent:Connect(onCraftItemRequest) else warn("craftItemEvent is invalid") end
if pullGachaFunction and pullGachaFunction:IsA("RemoteFunction") then print("[DEBUG] Connecting PullGachaFunction:", pullGachaFunction); pullGachaFunction.OnServerInvoke = onPullGachaRequest else warn("pullGachaFunction is invalid") end
if spendStatPointEvent and spendStatPointEvent:IsA("RemoteEvent") then print("[DEBUG] Connecting SpendStatPointEvent:", spendStatPointEvent); spendStatPointEvent.OnServerEvent:Connect(onSpendStatPointRequest) else warn("spendStatPointEvent is invalid") end
if debugLevelUpEvent and debugLevelUpEvent:IsA("RemoteEvent") then print("[DEBUG] Connecting DebugLevelUpEvent:", debugLevelUpEvent); debugLevelUpEvent.OnServerEvent:Connect(onDebugLevelUp) else warn("debugLevelUpEvent is invalid") end
if debugAddGoldEvent and debugAddGoldEvent:IsA("RemoteEvent") then print("[DEBUG] Connecting DebugAddGoldEvent:", debugAddGoldEvent); debugAddGoldEvent.OnServerEvent:Connect(onDebugAddGold) else warn("debugAddGoldEvent is invalid") end
if debugAddExpEvent and debugAddExpEvent:IsA("RemoteEvent") then print("[DEBUG] Connecting DebugAddExpEvent:", debugAddExpEvent); debugAddExpEvent.OnServerEvent:Connect(onDebugAddExp) else warn("debugAddExpEvent is invalid") end
if requestStartCombatEvent and requestStartCombatEvent:IsA("RemoteEvent") then print("[DEBUG] Connecting RequestStartCombatEvent:", requestStartCombatEvent); requestStartCombatEvent.OnServerEvent:Connect(onRequestStartCombat) else warn("requestStartCombatEvent is invalid") end
if requestPlayerAttackEvent and requestPlayerAttackEvent:IsA("RemoteEvent") then print("[DEBUG] Connecting RequestPlayerAttackEvent:", requestPlayerAttackEvent); requestPlayerAttackEvent.OnServerEvent:Connect(onRequestPlayerAttack) else warn("requestPlayerAttackEvent is invalid") end
if requestPlayerUseSkillEvent and requestPlayerUseSkillEvent:IsA("RemoteEvent") then print("[DEBUG] Connecting RequestPlayerUseSkillEvent:", requestPlayerUseSkillEvent); requestPlayerUseSkillEvent.OnServerEvent:Connect(onRequestPlayerUseSkill) else warn("requestPlayerUseSkillEvent is invalid") end
if purchaseSkillEvent and purchaseSkillEvent:IsA("RemoteEvent") then print("[DEBUG] Connecting PurchaseSkillEvent:", purchaseSkillEvent); purchaseSkillEvent.OnServerEvent:Connect(onPurchaseSkillRequest) else warn("purchaseSkillEvent is invalid") end
if useDevilFruitEvent and useDevilFruitEvent:IsA("RemoteEvent") then print("[DEBUG] Connecting UseDevilFruitEvent:", useDevilFruitEvent); useDevilFruitEvent.OnServerEvent:Connect(onUseDevilFruitRequest); print("UseDevilFruitEvent connected.") else warn("useDevilFruitEvent is invalid") end
if requestTestFruitEvent and requestTestFruitEvent:IsA("RemoteEvent") then print("[DEBUG] Connecting RequestTestFruitEvent:", requestTestFruitEvent); requestTestFruitEvent.OnServerEvent:Connect(onRequestTestFruit); print("RequestTestFruitEvent connected.") else warn("requestTestFruitEvent is invalid") end
if requestRemoveDevilFruitEvent and requestRemoveDevilFruitEvent:IsA("RemoteEvent") then print("[DEBUG] Connecting RequestRemoveDevilFruitEvent:", requestRemoveDevilFruitEvent); requestRemoveDevilFruitEvent.OnServerEvent:Connect(onRequestRemoveDevilFruit); print("RequestRemoveDevilFruitEvent connected.") else warn("requestRemoveDevilFruitEvent is invalid") end
if requestPullDevilFruitEvent and requestPullDevilFruitEvent:IsA("RemoteEvent") then print("[DEBUG] Connecting RequestPullDevilFruitEvent:", requestPullDevilFruitEvent); requestPullDevilFruitEvent.OnServerEvent:Connect(onRequestPullDevilFruit); print("ServerDataHandler: RequestPullDevilFruitEvent.OnServerEvent connected.") else warn("requestPullDevilFruitEvent is invalid") end
if requestPlayerDefendEvent and requestPlayerDefendEvent:IsA("RemoteEvent") then print("[DEBUG] Connecting RequestPlayerDefendEvent:", requestPlayerDefendEvent); requestPlayerDefendEvent.OnServerEvent:Connect(onRequestPlayerDefend); print("ServerDataHandler: RequestPlayerDefendEvent connected.") else warn("requestPlayerDefendEvent is invalid") end
if requestPlayerUseItemEvent and requestPlayerUseItemEvent:IsA("RemoteEvent") then print("[DEBUG] Connecting RequestPlayerUseItemEvent:", requestPlayerUseItemEvent); requestPlayerUseItemEvent.OnServerEvent:Connect(onRequestPlayerUseItem); print("ServerDataHandler: RequestPlayerUseItemEvent connected.") else warn("requestPlayerUseItemEvent is invalid") end
if EnhanceItemEvent and EnhanceItemEvent:IsA("RemoteEvent") then print("[DEBUG] Connecting EnhanceItemEvent:", EnhanceItemEvent); EnhanceItemEvent.OnServerEvent:Connect(onEnhanceItemRequest); print("ServerDataHandler: EnhanceItemEvent connected.") else warn("ServerDataHandler: EnhanceItemEvent 를 찾을 수 없어 연결할 수 없습니다!") end

if getOwnedCompanionsFunction and getOwnedCompanionsFunction:IsA("RemoteFunction") then
	print("[DEBUG] Connecting GetOwnedCompanionsFunction:", getOwnedCompanionsFunction)
	getOwnedCompanionsFunction.OnServerInvoke = onGetOwnedCompanions
	print("ServerDataHandler: GetOwnedCompanionsFunction.OnServerInvoke connected.")
else
	warn("ServerDataHandler: Failed to connect GetOwnedCompanionsFunction - Instance is nil or not a RemoteFunction:", getOwnedCompanionsFunction)
end

if getCurrentPartyFunction and getCurrentPartyFunction:IsA("RemoteFunction") then
	print("[DEBUG] Connecting GetCurrentPartyFunction:", getCurrentPartyFunction)
	getCurrentPartyFunction.OnServerInvoke = onGetCurrentParty
	print("ServerDataHandler: GetCurrentPartyFunction.OnServerInvoke connected.")
else
	warn("ServerDataHandler: Failed to connect GetCurrentPartyFunction - Instance is nil or not a RemoteFunction:", getCurrentPartyFunction)
end

if setPartyEvent and setPartyEvent:IsA("RemoteEvent") then
	print("[DEBUG] Connecting SetPartyEvent:", setPartyEvent)
	setPartyEvent.OnServerEvent:Connect(onSetPartyRequest)
	print("ServerDataHandler: SetPartyEvent.OnServerEvent connected.")
else
	warn("ServerDataHandler: Failed to connect SetPartyEvent - Instance is nil or not a RemoteEvent:", setPartyEvent)
end

-- ##### 리더보드 데이터 함수 연결 추가 #####
if getLeaderboardDataFunction and getLeaderboardDataFunction:IsA("RemoteFunction") then
	print("[DEBUG] Connecting GetLeaderboardDataFunction:", getLeaderboardDataFunction)
	getLeaderboardDataFunction.OnServerInvoke = onGetLeaderboardData
	print("ServerDataHandler: GetLeaderboardDataFunction.OnServerInvoke connected.")
else
	warn("ServerDataHandler: Failed to connect GetLeaderboardDataFunction - Instance is nil or not a RemoteFunction:", getLeaderboardDataFunction)
end
-- ##########################################

-- ##### [기능 추가] 동료에게 아이템 사용 이벤트 연결 #####
if UseItemOnCompanionEvent and UseItemOnCompanionEvent:IsA("RemoteEvent") then
	if typeof(onUseItemOnCompanionRequest) == "function" then
		UseItemOnCompanionEvent.OnServerEvent:Connect(onUseItemOnCompanionRequest)
		print("ServerDataHandler: UseItemOnCompanionEvent.OnServerEvent connected.")
	else
		warn("ServerDataHandler: Failed to connect UseItemOnCompanionEvent - onUseItemOnCompanionRequest is not a function:", typeof(onUseItemOnCompanionRequest))
	end
else
	warn("ServerDataHandler: Failed to connect UseItemOnCompanionEvent - Instance is nil, not a RemoteEvent, or was not found earlier.")
end
-- #####################################################


print("ServerDataHandler: 모든 기능 및 이벤트 연결 완료.")