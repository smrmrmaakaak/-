-- InventoryManager.lua

local InventoryManager = {}

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService") -- JSONEncode를 위해 추가

-- 모듈 로드
local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local PlayerData = require(modulesFolder:WaitForChild("PlayerData"))
local ItemDatabase = require(modulesFolder:WaitForChild("ItemDatabase"))
local CraftingDatabase = require(modulesFolder:WaitForChild("CraftingDatabase"))
local EnhancementDatabase = require(modulesFolder:WaitForChild("EnhancementDatabase"))

-- 이벤트 참조
local inventoryUpdatedEvent = ReplicatedStorage:FindFirstChild("InventoryUpdatedEvent")
local playerStatsUpdatedEvent = ReplicatedStorage:FindFirstChild("PlayerStatsUpdatedEvent")
local EnhancementResultEvent = ReplicatedStorage:FindFirstChild("EnhancementResultEvent") -- 이 이벤트는 NotifyPlayerEvent로 대체될 수 있음
local NotifyPlayerEvent = ReplicatedStorage:FindFirstChild("NotifyPlayerEvent") -- <<< 알림 이벤트 참조

-- 아이템 추가 함수 (디버그 Print 추가)
function InventoryManager.AddItem(player, itemId, quantity, optionalItemData)
	print("InventoryManager: AddItem called. Player:", player.Name, "ItemID:", itemId, "Qty:", quantity)
	if optionalItemData then print("  -> with optionalItemData:", optionalItemData) end

	if not RunService:IsServer() then print("AddItem: Not server!"); return false, "서버 전용" end
	if not PlayerData or not ItemDatabase then print("AddItem: Module load error!"); return false, "모듈 로드 오류" end
	local pData = PlayerData.GetSessionData(player); if not pData then print("AddItem: No player data!"); return false, "플레이어 데이터 없음" end
	local itemInfo = ItemDatabase.Items[itemId]; if not itemInfo then print("AddItem: Unknown item:", itemId); return false, "알수없는 아이템" end
	if typeof(quantity) ~= 'number' or quantity <= 0 then print("AddItem: Invalid quantity:", quantity); return false, "잘못된 수량" end

	pData.Inventory = pData.Inventory or {}
	local inventory = pData.Inventory

	if optionalItemData and typeof(optionalItemData) == 'table' and optionalItemData.itemId == itemId then
		table.insert(inventory, optionalItemData)
		print("InventoryManager: Restored item instance", itemId, "Level:", optionalItemData.enhancementLevel or 0)
	elseif itemInfo.Stackable then
		local foundSlot = false
		for i, slotData in ipairs(inventory) do
			if slotData.itemId == itemId then
				slotData.quantity = (slotData.quantity or 0) + quantity
				foundSlot = true; break
			end
		end
		if not foundSlot then
			table.insert(inventory, {itemId = itemId, quantity = quantity})
		end
	else
		for i = 1, quantity do
			local newItemSlot = {itemId = itemId, quantity = 1}
			if itemInfo.Type == "Equipment" and itemInfo.Enhanceable then
				newItemSlot.enhancementLevel = 0 -- 강화 레벨 0으로 초기화
			end
			table.insert(inventory, newItemSlot)
		end
	end

	print("InventoryManager: Added item", itemId, "x", quantity, "to", player.Name)
	if inventoryUpdatedEvent then inventoryUpdatedEvent:FireClient(player) end
	print("InventoryManager: AddItem returning true.")
	return true, "아이템 추가 성공"
end


-- 아이템 개수 세는 헬퍼 함수 (동일)
function InventoryManager.CountItem(player, itemId) if not PlayerData then return 0 end; local pData=PlayerData.GetSessionData(player); if not pData or not pData.Inventory then return 0 end; local count=0; for _, slotData in ipairs(pData.Inventory) do if slotData.itemId==itemId then count=count+(slotData.quantity or 0) end end; return count end

-- 아이템 제거 함수 (동일)
function InventoryManager.RemoveItem(player, itemId, quantity)
	if not RunService:IsServer() then return false,"서버 전용" end
	if not PlayerData or not ItemDatabase then return false,"모듈 로드 오류" end
	local pData=PlayerData.GetSessionData(player); if not pData then return false,"플레이어 데이터 없음" end
	local itemInfo=ItemDatabase.Items[itemId]; if not itemInfo then return false,"알수없는 아이템" end
	if typeof(quantity)~='number' or quantity<=0 then return false,"잘못된 수량" end

	pData.Inventory = pData.Inventory or {}
	local inventory = pData.Inventory
	local remainingQuantity = quantity
	local itemsRemoved = false

	for i = #inventory, 1, -1 do
		local slotData = inventory[i]
		if slotData.itemId == itemId then
			if itemInfo.Stackable then
				if slotData.quantity >= remainingQuantity then
					slotData.quantity = slotData.quantity - remainingQuantity
					remainingQuantity = 0
					if slotData.quantity == 0 then
						table.remove(inventory, i)
					end
					itemsRemoved = true
					break
				else
					remainingQuantity = remainingQuantity - slotData.quantity
					table.remove(inventory, i)
					itemsRemoved = true
				end
			else
				-- 비스택 아이템이고 인벤토리 슬롯에 데이터가 있다면
				if slotData.quantity >= 1 then -- 수량이 1 이상인지 확인 (오류 방지)
					table.remove(inventory, i)
					remainingQuantity = remainingQuantity - 1
					itemsRemoved = true
					if remainingQuantity <= 0 then
						break
					end
				else -- 비스택 아이템인데 수량이 0 이하면 슬롯 데이터 오류 가능성
					warn("InventoryManager.RemoveItem: Non-stackable item slot has quantity <= 0. Removing slot. Index:", i, "ItemID:", itemId)
					table.remove(inventory, i) -- 일단 제거
				end
			end
		end
	end

	if remainingQuantity > 0 then
		warn("RemoveItem: Not enough items", itemId, "needed", quantity, "removed?", itemsRemoved)
		return false,"아이템 수량 부족"
	end

	print("Removed item", itemId, "x", quantity, "from", player.Name); if itemsRemoved and inventoryUpdatedEvent then inventoryUpdatedEvent:FireClient(player) end
	return true, "아이템 제거 성공"
end


-- 아이템 장착 함수 (디버깅 print 및 오류 수정)
function InventoryManager.EquipItem(player, itemId)
	print(string.format("===== [DEBUG] InventoryManager.EquipItem 시작: Player: %s, ItemID: %s =====", player.Name, tostring(itemId)))

	if not RunService:IsServer() then warn("EquipItem 서버 전용!"); print("===== [DEBUG] InventoryManager.EquipItem 종료 (실패: 서버 전용) ====="); return false,"서버 전용" end
	if not PlayerData or not ItemDatabase then warn("EquipItem 모듈 로드 오류!"); print("===== [DEBUG] InventoryManager.EquipItem 종료 (실패: 모듈 로드 오류) ====="); return false,"모듈 로드 오류" end

	local playerData=PlayerData.GetSessionData(player);
	if not playerData then warn("EquipItem 세션 데이터 없음"); print("===== [DEBUG] InventoryManager.EquipItem 종료 (실패: 세션 데이터 없음) ====="); return false,"플레이어 데이터 없음" end

	print("[DEBUG] EquipItem: 현재 Equipped 상태:", playerData.Equipped and HttpService:JSONEncode(playerData.Equipped) or "nil")
	print("[DEBUG] EquipItem: 현재 Inventory 상태:", playerData.Inventory and HttpService:JSONEncode(playerData.Inventory) or "nil")

	local itemInfo=ItemDatabase.Items[itemId];
	if not itemInfo then warn("EquipItem 알 수 없는 아이템:",itemId); print("===== [DEBUG] InventoryManager.EquipItem 종료 (실패: 알 수 없는 아이템) ====="); return false,"알 수 없는 아이템" end
	if itemInfo.Type~="Equipment" or not itemInfo.Slot then warn("EquipItem 장착 불가 아이템:",itemId); print("===== [DEBUG] InventoryManager.EquipItem 종료 (실패: 장착 불가 아이템) ====="); return false,"장착 불가 아이템" end

	-- 요구 스탯 체크
	local requirementMet=true; local failMessage=""; local requirements={Sword=itemInfo.requiredSword,Gun=itemInfo.requiredGun,DF=itemInfo.requiredDF};
	for statName,requiredValue in pairs(requirements) do
		if requiredValue and requiredValue>0 then
			local playerStatValue=playerData[statName] or 0;
			print(string.format("[DEBUG] EquipItem Requirement Check: ItemID=%d, Stat=%s, Required=%s, PlayerHas=%s", itemId, statName, tostring(requiredValue), tostring(playerStatValue)))
			if playerStatValue<requiredValue then
				requirementMet=false;
				failMessage=string.format("요구 스탯 부족: %s %d (현재 %d)",statName,requiredValue,playerStatValue);
				break
			end
		end
	end;

	if not requirementMet then
		warn("EquipItem 요구 스탯 부족:",failMessage);
		print("[DEBUG] EquipItem: Requirement not met. Checking NotifyPlayerEvent...")
		print("[DEBUG] EquipItem: Value of NotifyPlayerEvent is:", NotifyPlayerEvent)
		if NotifyPlayerEvent then print("[DEBUG] InventoryManager.EquipItem: Firing NotifyPlayerEvent for unmet requirement:", failMessage); NotifyPlayerEvent:FireClient(player,"EquipFailed",{reason = failMessage}); print("[DEBUG] InventoryManager.EquipItem: NotifyPlayerEvent fired.") -- 알림 타입 수정
		else print("[DEBUG] InventoryManager.EquipItem: NotifyPlayerEvent is nil! Cannot fire notification.") end;
		print("===== [DEBUG] InventoryManager.EquipItem 종료 (실패: 요구 스탯 부족) =====");
		return false,failMessage
	end

	playerData.Equipped = playerData.Equipped or {Weapon=nil,Armor=nil,Accessory1=nil,Accessory2=nil,Accessory3=nil}
	playerData.Inventory = playerData.Inventory or {}

	print(string.format("[DEBUG] EquipItem: Searching inventory for ItemID %s", tostring(itemId)))
	local itemDataToEquip = nil
	local itemInventoryIndex = -1
	for i, slotData in ipairs(playerData.Inventory) do
		local slotDataString = "nil"
		if slotData then local success, encoded = pcall(HttpService.JSONEncode, HttpService, slotData); slotDataString = success and encoded or tostring(slotData) end
		print(string.format("  [DEBUG] EquipItem: Checking inventory slot %d: %s", i, slotDataString))

		if slotData and typeof(slotData) == 'table' and slotData.itemId == itemId then
			itemDataToEquip = {}
			for k, v in pairs(slotData) do itemDataToEquip[k] = v end
			itemDataToEquip.quantity = 1 -- 장착 시 수량은 항상 1
			itemInventoryIndex = i
			print(string.format("  [DEBUG] EquipItem: Found item in inventory at index %d. Data to equip: %s", i, HttpService:JSONEncode(itemDataToEquip)))
			break
		end
	end

	if not itemDataToEquip then
		warn("EquipItem 인벤 아이템 없음:",itemId);
		print("===== [DEBUG] InventoryManager.EquipItem 종료 (실패: 인벤토리에 아이템 없음) =====");
		return false,"인벤토리에 아이템이 없습니다." -- 메시지 수정
	end

	local targetSlot = nil;
	if itemInfo.Slot=="Weapon" or itemInfo.Slot=="Armor" then targetSlot=itemInfo.Slot
	elseif itemInfo.Slot=="Accessory" then
		local accessorySlotsToTry={"Accessory1","Accessory2","Accessory3"};
		for _,slotName in ipairs(accessorySlotsToTry) do
			if not playerData.Equipped[slotName] then targetSlot=slotName; break end
		end;
		if not targetSlot then
			warn("EquipItem: 모든 악세사리 슬롯 가득 참");
			if NotifyPlayerEvent then NotifyPlayerEvent:FireClient(player,"EquipFailed",{reason = "모든 악세사리 슬롯이 가득 찼습니다."}) end -- 알림 추가
			print("===== [DEBUG] InventoryManager.EquipItem 종료 (실패: 악세사리 슬롯 없음) =====");
			return false,"모든 악세사리 슬롯이 가득 찼습니다." -- 메시지 수정
		end
	else warn("EquipItem 알 수 없는 슬롯 타입:",itemInfo.Slot); print("===== [DEBUG] InventoryManager.EquipItem 종료 (실패: 알 수 없는 슬롯 타입) ====="); return false,"알 수 없는 슬롯 타입입니다." end

	print(string.format("[DEBUG] EquipItem: Determined target slot: %s", targetSlot))

	-- 1. 인벤토리에서 아이템 제거 (제거 함수 사용)
	print(string.format("[DEBUG] EquipItem: Removing item from inventory index %d using RemoveItem", itemInventoryIndex))
	-- RemoveItem 함수는 내부적으로 inventoryUpdatedEvent를 발생시키므로 여기서 따로 발생시킬 필요 없음
	local removeSuccess, removeMsg = InventoryManager.RemoveItem(player, itemId, 1)
	if not removeSuccess then
		warn("EquipItem 인벤 아이템 제거 실패! Index:", itemInventoryIndex, "Reason:", removeMsg)
		if NotifyPlayerEvent then NotifyPlayerEvent:FireClient(player,"EquipFailed",{reason = removeMsg or "인벤토리에서 아이템을 제거할 수 없습니다."}) end
		print("===== [DEBUG] InventoryManager.EquipItem 종료 (실패: 인벤토리 아이템 제거 실패) =====");
		return false, removeMsg or "인벤토리 아이템 제거 실패"
	end
	print("[DEBUG] EquipItem: Successfully removed item from inventory.")

	-- 2. 기존 아이템 해제 및 인벤토리 추가
	local previousItemData = playerData.Equipped[targetSlot]
	print(string.format("[DEBUG] EquipItem: Previous item in slot %s: %s", targetSlot, previousItemData and HttpService:JSONEncode(previousItemData) or "nil"))
	if previousItemData then
		print(string.format("[DEBUG] EquipItem: Adding previous item back to inventory: %s", HttpService:JSONEncode(previousItemData)))
		-- AddItem은 내부적으로 inventoryUpdatedEvent를 발생시킴
		local addedBackSuccess, addBackMsg = InventoryManager.AddItem(player, previousItemData.itemId, 1, previousItemData)
		if not addedBackSuccess then
			warn("EquipItem 기존 아이템 인벤 복원 실패! 롤백...", addBackMsg or "")
			print("[DEBUG] EquipItem: Rolling back inventory removal...")
			-- 롤백: 제거했던 아이템을 다시 인벤에 추가 (이전 remove가 성공했으므로 다시 add)
			local rollbackAddSuccess, rollbackAddMsg = InventoryManager.AddItem(player, itemId, 1, itemDataToEquip)
			if not rollbackAddSuccess then warn("EquipItem: Inventory rollback failed!", rollbackAddMsg) end
			print("===== [DEBUG] InventoryManager.EquipItem 종료 (실패: 기존 아이템 복원 실패) =====");
			return false, "기존 아이템 해제(인벤 복원) 실패. ("..(addBackMsg or "")..")"
		end
		print("[DEBUG] EquipItem: Successfully added previous item back to inventory.")
	end

	-- 3. 새 아이템 장착
	print(string.format("[DEBUG] EquipItem: Equipping new item to slot %s: %s", targetSlot, HttpService:JSONEncode(itemDataToEquip)))
	playerData.Equipped[targetSlot] = itemDataToEquip
	print("Equipped item",itemId,"to slot",targetSlot,"Enh:",itemDataToEquip.enhancementLevel or 0)

	-- 4. 스탯 재계산
	print("[DEBUG] EquipItem: Recalculating derived stats...")
	if PlayerData._RecalculateDerivedStats then PlayerData._RecalculateDerivedStats(player) else warn("EquipItem: _RecalculateDerivedStats 없음!") end

	print(string.format("===== [DEBUG] InventoryManager.EquipItem 성공: ItemID: %s -> Slot: %s =====", tostring(itemId), targetSlot));
	return true, nil
end


-- 아이템 해제 함수 (디버깅 print 추가)
function InventoryManager.UnequipItem(player, slot, internalCall)
	print(string.format("===== [DEBUG] InventoryManager.UnequipItem 시작: Player: %s, Slot: %s, InternalCall: %s =====", player.Name, tostring(slot), tostring(internalCall)))

	if not RunService:IsServer() then print("UnequipItem: Not server!"); print("===== [DEBUG] InventoryManager.UnequipItem 종료 (실패: 서버 전용) ====="); return false,"서버 전용" end
	if not PlayerData or not ItemDatabase then print("UnequipItem: Module load error!"); print("===== [DEBUG] InventoryManager.UnequipItem 종료 (실패: 모듈 로드 오류) ====="); return false,"모듈 로드 오류" end

	local playerData=PlayerData.GetSessionData(player);
	if not playerData then print("UnequipItem: No player data!"); print("===== [DEBUG] InventoryManager.UnequipItem 종료 (실패: 세션 데이터 없음) ====="); return false,"플레이어 데이터 없음" end
	if not slot or typeof(slot)~="string" then print("UnequipItem: Invalid slot type:", typeof(slot)); print("===== [DEBUG] InventoryManager.UnequipItem 종료 (실패: 잘못된 슬롯) ====="); return false,"잘못된 슬롯" end

	playerData.Equipped = playerData.Equipped or {}
	print("[DEBUG] UnequipItem: 현재 Equipped 상태:", HttpService:JSONEncode(playerData.Equipped)) -- 현재 장착 상태 출력

	local itemDataToUnequip = playerData.Equipped[slot]
	print("[DEBUG] UnequipItem: 아이템 데이터 확인 for slot '"..slot.."':", itemDataToUnequip and HttpService:JSONEncode(itemDataToUnequip) or "nil")

	if not itemDataToUnequip then print("UnequipItem: Slot is empty:", slot); print("===== [DEBUG] InventoryManager.UnequipItem 종료 (실패: 슬롯 비어있음) ====="); return false,"해당 슬롯 비어있음" end
	if typeof(itemDataToUnequip) ~= 'table' or not itemDataToUnequip.itemId then
		warn("UnequipItem: Invalid data in equipped slot:", slot, itemDataToUnequip);
		playerData.Equipped[slot] = nil;
		print("[DEBUG] UnequipItem: Invalid data found, cleared slot:", slot);
		print("===== [DEBUG] InventoryManager.UnequipItem 종료 (실패: 장착 슬롯 데이터 오류) =====");
		return false, "장착 슬롯 데이터 오류"
	end

	print("[DEBUG] UnequipItem: Clearing equipped slot:", slot)
	playerData.Equipped[slot]=nil

	print("[DEBUG] UnequipItem: Calling AddItem to return item to inventory:", HttpService:JSONEncode(itemDataToUnequip))
	local itemAddedSuccess, addMessage = InventoryManager.AddItem(player, itemDataToUnequip.itemId, 1, itemDataToUnequip)
	print("[DEBUG] UnequipItem: AddItem result - Success:", itemAddedSuccess, "Message:", addMessage)

	if not itemAddedSuccess then
		print("[DEBUG] UnequipItem: AddItem FAILED! Rolling back slot clear...")
		warn("UnequipItem 인벤 추가 실패! 롤백... -", addMessage or "")
		playerData.Equipped[slot] = itemDataToUnequip
		print("===== [DEBUG] InventoryManager.UnequipItem 종료 (실패: 인벤 추가 불가) =====");
		return false, addMessage or "인벤토리에 추가할 수 없습니다." -- 메시지 수정
	end

	print("Unequipped item from slot",slot,"(ItemID:", itemDataToUnequip.itemId, "Enh:", itemDataToUnequip.enhancementLevel or 0,")")

	if not internalCall then
		print("[DEBUG] UnequipItem: Recalculating derived stats (not internal call)...")
		if PlayerData._RecalculateDerivedStats then PlayerData._RecalculateDerivedStats(player) else warn("UnequipItem: _RecalculateDerivedStats 없음!") end
	else
		print("[DEBUG] UnequipItem: Skipping stat recalculation (internal call).")
	end

	print(string.format("===== [DEBUG] InventoryManager.UnequipItem 성공: Slot: %s =====", tostring(slot)));
	return true, nil
end


-- 아이템 판매 함수 (동일)
function InventoryManager.SellItem(player, itemId, quantity) if not RunService:IsServer() then return false end; if not PlayerData or not ItemDatabase then return false end; local pData=PlayerData.GetSessionData(player); if not pData then return false end; local itemInfo=ItemDatabase.Items[itemId]; if not itemInfo then return false end; if typeof(quantity)~='number' or quantity<=0 then return false end; local sellPrice=itemInfo.SellPrice; if sellPrice==nil then sellPrice=math.floor((itemInfo.Price or 0)/2) end; if sellPrice<=0 then warn("Cannot sell item:",itemId); return false end; local currentQuantity=InventoryManager.CountItem(player,itemId); if currentQuantity<quantity then return false end; local removedSuccess,removeMessage=InventoryManager.RemoveItem(player,itemId,quantity); if not removedSuccess then warn("Failed to remove item during selling:",removeMessage or ""); return false end; local goldToGain=sellPrice*quantity; local currentGold=pData.Gold or 0; local updateGoldSuccess=PlayerData.UpdateStat(player,"Gold",currentGold+goldToGain); if not updateGoldSuccess then warn("Failed to update gold! Rolling back..."); InventoryManager.AddItem(player,itemId,quantity); return false end; print("Sold item",itemId,"x",quantity,"for",goldToGain,"gold. Player:",player.Name); if playerStatsUpdatedEvent then playerStatsUpdatedEvent:FireClient(player) end; return true end

-- 아이템 제작 함수 (동일)
function InventoryManager.CraftItem(player, recipeId) if not RunService:IsServer() then return false end; if not PlayerData or not ItemDatabase or not CraftingDatabase then return false end; local pData=PlayerData.GetSessionData(player); if not pData then return false end; local recipe=CraftingDatabase.Recipes[recipeId]; if not recipe then return false end; print("Attempting craft:",recipeId); local canCraft=true; local materialsToRemove={}; if recipe.Materials then pData.Inventory = pData.Inventory or {}; for _,materialInfo in ipairs(recipe.Materials) do local requiredItemId=materialInfo.ItemID; local requiredQuantity=materialInfo.Quantity; local currentQuantity=InventoryManager.CountItem(player, requiredItemId); if currentQuantity<requiredQuantity then print("Not enough material:",requiredItemId); canCraft=false; break end; table.insert(materialsToRemove,{ItemID=requiredItemId,Quantity=requiredQuantity}) end else warn("Recipe has no materials:",recipeId); canCraft=false end; if not canCraft then return false end; local removedSuccessfully=true; local itemsToRemoveRollback={}; for _,materialToRemove in ipairs(materialsToRemove) do local removeSuccess,removeMsg=InventoryManager.RemoveItem(player,materialToRemove.ItemID,materialToRemove.Quantity); if not removeSuccess then warn("Failed to remove material:",materialToRemove.ItemID,"Error:",removeMsg or ""); removedSuccessfully=false; break else table.insert(itemsToRemoveRollback,materialToRemove) end end; if not removedSuccessfully then print("Rolling back material removal..."); for _,itemToRollback in ipairs(itemsToRemoveRollback) do InventoryManager.AddItem(player,itemToRollback.ItemID,itemToRollback.Quantity) end; print("Rollback complete."); return false end; local resultItemId=recipe.ResultItemID; local resultQuantity=recipe.ResultQuantity or 1; local addedSuccessfully,addMsg=InventoryManager.AddItem(player,resultItemId,resultQuantity); if not addedSuccessfully then warn("Failed to add result item:",resultItemId,"Error:",addMsg or ""); print("Rolling back material removal..."); for _,materialToRemove in ipairs(materialsToRemove) do InventoryManager.AddItem(player,materialToRemove.ItemID,materialToRemove.Quantity) end; print("Rollback complete."); return false end; print("Crafting successful! Recipe:",recipeId,"Result:",resultItemId,"x",resultQuantity); return true end

-- ##### 아이템 강화 함수 수정 (NotifyPlayerEvent 사용 + 디버그 로그 추가) #####
function InventoryManager.EnhanceItem(player, inventorySlotIndex)
	print(string.format("DEBUG: EnhanceItem 호출됨 - Player: %s, Index: %s", player.Name, tostring(inventorySlotIndex))) -- 디버그 로그 추가
	if not RunService:IsServer() then return false, "서버 전용" end
	if not PlayerData or not ItemDatabase or not EnhancementDatabase then warn("EnhanceItem: 필수 모듈 로드 실패!"); return false, "강화 시스템 오류" end

	local pData = PlayerData.GetSessionData(player)
	if not pData then return false, "플레이어 데이터 없음" end
	pData.Inventory = pData.Inventory or {}
	pData.Equipped = pData.Equipped or {}

	if not inventorySlotIndex or not pData.Inventory[inventorySlotIndex] then
		warn("EnhanceItem: 잘못된 인벤토리 인덱스:", inventorySlotIndex)
		if NotifyPlayerEvent then
			print("DEBUG: 서버: 잘못된 아이템 선택 이벤트 발송 시도") -- 디버그 로그 추가
			NotifyPlayerEvent:FireClient(player, "EnhancementResult", {success=false, reason="잘못된 아이템 선택"})
		end
		return false, "잘못된 아이템 선택"
	end

	local itemSlotData = pData.Inventory[inventorySlotIndex]
	local itemId = itemSlotData.itemId
	local currentLevel = itemSlotData.enhancementLevel or 0
	local itemInfo = ItemDatabase.GetItemInfo(itemId)

	if not itemInfo then
		if NotifyPlayerEvent then
			print("DEBUG: 서버: 알 수 없는 아이템 이벤트 발송 시도") -- 디버그 로그 추가
			NotifyPlayerEvent:FireClient(player, "EnhancementResult", {success=false, reason="알 수 없는 아이템"})
		end;
		return false, "알 수 없는 아이템"
	end
	if not itemInfo.Enhanceable then
		if NotifyPlayerEvent then
			print("DEBUG: 서버: 강화 불가 아이템 이벤트 발송 시도") -- 디버그 로그 추가
			NotifyPlayerEvent:FireClient(player, "EnhancementResult", {success=false, reason="강화할 수 없는 아이템입니다."})
		end;
		return false, "강화할 수 없는 아이템입니다."
	end

	local maxLevel = itemInfo.MaxEnhanceLevel or 0
	if currentLevel >= maxLevel then
		if NotifyPlayerEvent then
			print("DEBUG: 서버: 최대 레벨 도달 이벤트 발송 시도") -- 디버그 로그 추가
			NotifyPlayerEvent:FireClient(player, "EnhancementResult", {success=false, reason="이미 최대 레벨입니다."})
		end;
		return false, "이미 최대 레벨입니다."
	end

	local nextLevel = currentLevel + 1
	local levelInfo = EnhancementDatabase.GetLevelInfo(nextLevel)
	if not levelInfo then
		warn("EnhanceItem: 다음 레벨 강화 정보 없음:", nextLevel);
		if NotifyPlayerEvent then
			print("DEBUG: 서버: 더 이상 강화 불가 이벤트 발송 시도") -- 디버그 로그 추가
			NotifyPlayerEvent:FireClient(player, "EnhancementResult", {success=false, reason="더 이상 강화할 수 없습니다."})
		end;
		return false, "더 이상 강화할 수 없습니다."
	end

	local requiredMaterials = levelInfo.Materials or {}; local goldCost = levelInfo.GoldCost or 0; local successRate = levelInfo.SuccessRate or 0; local canAfford = true; local failReason = ""
	if (pData.Gold or 0) < goldCost then canAfford = false; failReason = "골드 부족" end
	if canAfford then for _, matData in ipairs(requiredMaterials) do local ownedQty = InventoryManager.CountItem(player, matData.ItemID); if ownedQty < matData.Quantity then canAfford = false; local matInfo = ItemDatabase.GetItemInfo(matData.ItemID); failReason = (matInfo and matInfo.Name or ("아이템 #"..matData.ItemID)) .. " 부족"; break end end end
	if not canAfford then
		print("EnhanceItem: 강화 불가 -", failReason);
		if NotifyPlayerEvent then
			print(string.format("DEBUG: 서버: 강화 재료/골드 부족 이벤트 발송 시도 - 이유: %s", failReason)) -- 디버그 로그 추가
			NotifyPlayerEvent:FireClient(player, "EnhancementResult", {success=false, reason=failReason})
		end;
		return false, failReason
	end

	local consumedItems = {}; local consumedGold = false; local originalGold = pData.Gold
	local goldUpdateSuccess = PlayerData.UpdateStat(player, "Gold", originalGold - goldCost); if not goldUpdateSuccess then warn("EnhanceItem: 골드 소모 실패!"); if NotifyPlayerEvent then NotifyPlayerEvent:FireClient(player, "EnhancementResult", {success=false, reason="골드 소모 오류"}) end; return false, "골드 소모 오류" end; consumedGold = true
	local materialsConsumeSuccess = true; for _, matData in ipairs(requiredMaterials) do local removeSuccess, removeMsg = InventoryManager.RemoveItem(player, matData.ItemID, matData.Quantity); if not removeSuccess then materialsConsumeSuccess = false; failReason = removeMsg or "재료 소모 오류"; warn("EnhanceItem: 재료 소모 실패!", matData.ItemID, failReason); break else table.insert(consumedItems, {itemId = matData.ItemID, quantity = matData.Quantity}) end end
	if not materialsConsumeSuccess then print("EnhanceItem: 재료 소모 실패, 롤백 시작..."); if consumedGold then PlayerData.UpdateStat(player, "Gold", originalGold) end; for _, consumedItem in ipairs(consumedItems) do InventoryManager.AddItem(player, consumedItem.itemId, consumedItem.quantity) end; print("EnhanceItem: 롤백 완료."); if NotifyPlayerEvent then NotifyPlayerEvent:FireClient(player, "EnhancementResult", {success=false, reason=failReason}) end; return false, failReason end

	local roll = math.random(); local enhanceSuccess = (roll <= successRate);

	if enhanceSuccess then
		local newLevel = nextLevel
		itemSlotData.enhancementLevel = newLevel -- 인벤토리 아이템 레벨 업데이트
		print("EnhanceItem: 강화 성공! Inventory", itemId, "+", newLevel)

		-- <<< 강화 성공 NotifyPlayerEvent 발송 >>>
		if NotifyPlayerEvent then
			print(string.format("DEBUG: 서버: 강화 성공 이벤트 발송 시도 - 아이템: %s, 새 레벨: %d", itemInfo.Name or "아이템", newLevel)) -- 디버그 로그 추가
			NotifyPlayerEvent:FireClient(player, "EnhancementResult", {
				success = true,
				itemName = itemInfo.Name or "아이템",
				newLevel = newLevel
			})
		end

		local statsNeedRecalculation = false
		for slotName, equippedData in pairs(pData.Equipped) do
			if equippedData and equippedData.itemId == itemId then
				equippedData.enhancementLevel = newLevel
				statsNeedRecalculation = true
				print("EnhanceItem: Same ItemID found in equipped slot:", slotName, ". Updated level and triggering stat recalculation.")
			end
		end

		if statsNeedRecalculation then
			if PlayerData._RecalculateDerivedStats then PlayerData._RecalculateDerivedStats(player); print("EnhanceItem: Stats recalculated.")
			else warn("EnhanceItem: _RecalculateDerivedStats function not found!") end
		end

	else
		local failReasonText = "강화 실패..."
		print("EnhanceItem: 강화 실패.", itemId)

		-- <<< 강화 실패 NotifyPlayerEvent 발송 >>>
		if NotifyPlayerEvent then
			print(string.format("DEBUG: 서버: 강화 실패 이벤트 발송 시도 - 아이템: %s, 이유: %s", itemInfo.Name or "아이템", failReasonText)) -- 디버그 로그 추가
			NotifyPlayerEvent:FireClient(player, "EnhancementResult", {
				success = false,
				itemName = itemInfo.Name or "아이템",
				reason = failReasonText
			})
		end
	end

	-- EnhancementResultEvent는 이제 사용하지 않음
	-- if EnhancementResultEvent then ... end

	if inventoryUpdatedEvent then inventoryUpdatedEvent:FireClient(player) end

	-- ##### 수정된 반환 부분 #####
	if enhanceSuccess then
		return true, nil -- 성공 시: true와 nil 반환
	else
		return false, "강화 실패..." -- 실패 시: false와 실패 메시지 반환
	end
	-- ##### 수정 끝 #####
end
-- #####################################################


return InventoryManager