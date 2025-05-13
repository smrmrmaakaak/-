-- InventoryManager.lua

local InventoryManager = {}

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService") -- JSONEncode�� ���� �߰�

-- ��� �ε�
local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local PlayerData = require(modulesFolder:WaitForChild("PlayerData"))
local ItemDatabase = require(modulesFolder:WaitForChild("ItemDatabase"))
local CraftingDatabase = require(modulesFolder:WaitForChild("CraftingDatabase"))
local EnhancementDatabase = require(modulesFolder:WaitForChild("EnhancementDatabase"))

-- �̺�Ʈ ����
local inventoryUpdatedEvent = ReplicatedStorage:FindFirstChild("InventoryUpdatedEvent")
local playerStatsUpdatedEvent = ReplicatedStorage:FindFirstChild("PlayerStatsUpdatedEvent")
local EnhancementResultEvent = ReplicatedStorage:FindFirstChild("EnhancementResultEvent") -- �� �̺�Ʈ�� NotifyPlayerEvent�� ��ü�� �� ����
local NotifyPlayerEvent = ReplicatedStorage:FindFirstChild("NotifyPlayerEvent") -- <<< �˸� �̺�Ʈ ����

-- ������ �߰� �Լ� (����� Print �߰�)
function InventoryManager.AddItem(player, itemId, quantity, optionalItemData)
	print("InventoryManager: AddItem called. Player:", player.Name, "ItemID:", itemId, "Qty:", quantity)
	if optionalItemData then print("  -> with optionalItemData:", optionalItemData) end

	if not RunService:IsServer() then print("AddItem: Not server!"); return false, "���� ����" end
	if not PlayerData or not ItemDatabase then print("AddItem: Module load error!"); return false, "��� �ε� ����" end
	local pData = PlayerData.GetSessionData(player); if not pData then print("AddItem: No player data!"); return false, "�÷��̾� ������ ����" end
	local itemInfo = ItemDatabase.Items[itemId]; if not itemInfo then print("AddItem: Unknown item:", itemId); return false, "�˼����� ������" end
	if typeof(quantity) ~= 'number' or quantity <= 0 then print("AddItem: Invalid quantity:", quantity); return false, "�߸��� ����" end

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
				newItemSlot.enhancementLevel = 0 -- ��ȭ ���� 0���� �ʱ�ȭ
			end
			table.insert(inventory, newItemSlot)
		end
	end

	print("InventoryManager: Added item", itemId, "x", quantity, "to", player.Name)
	if inventoryUpdatedEvent then inventoryUpdatedEvent:FireClient(player) end
	print("InventoryManager: AddItem returning true.")
	return true, "������ �߰� ����"
end


-- ������ ���� ���� ���� �Լ� (����)
function InventoryManager.CountItem(player, itemId) if not PlayerData then return 0 end; local pData=PlayerData.GetSessionData(player); if not pData or not pData.Inventory then return 0 end; local count=0; for _, slotData in ipairs(pData.Inventory) do if slotData.itemId==itemId then count=count+(slotData.quantity or 0) end end; return count end

-- ������ ���� �Լ� (����)
function InventoryManager.RemoveItem(player, itemId, quantity)
	if not RunService:IsServer() then return false,"���� ����" end
	if not PlayerData or not ItemDatabase then return false,"��� �ε� ����" end
	local pData=PlayerData.GetSessionData(player); if not pData then return false,"�÷��̾� ������ ����" end
	local itemInfo=ItemDatabase.Items[itemId]; if not itemInfo then return false,"�˼����� ������" end
	if typeof(quantity)~='number' or quantity<=0 then return false,"�߸��� ����" end

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
				-- ���� �������̰� �κ��丮 ���Կ� �����Ͱ� �ִٸ�
				if slotData.quantity >= 1 then -- ������ 1 �̻����� Ȯ�� (���� ����)
					table.remove(inventory, i)
					remainingQuantity = remainingQuantity - 1
					itemsRemoved = true
					if remainingQuantity <= 0 then
						break
					end
				else -- ���� �������ε� ������ 0 ���ϸ� ���� ������ ���� ���ɼ�
					warn("InventoryManager.RemoveItem: Non-stackable item slot has quantity <= 0. Removing slot. Index:", i, "ItemID:", itemId)
					table.remove(inventory, i) -- �ϴ� ����
				end
			end
		end
	end

	if remainingQuantity > 0 then
		warn("RemoveItem: Not enough items", itemId, "needed", quantity, "removed?", itemsRemoved)
		return false,"������ ���� ����"
	end

	print("Removed item", itemId, "x", quantity, "from", player.Name); if itemsRemoved and inventoryUpdatedEvent then inventoryUpdatedEvent:FireClient(player) end
	return true, "������ ���� ����"
end


-- ������ ���� �Լ� (����� print �� ���� ����)
function InventoryManager.EquipItem(player, itemId)
	print(string.format("===== [DEBUG] InventoryManager.EquipItem ����: Player: %s, ItemID: %s =====", player.Name, tostring(itemId)))

	if not RunService:IsServer() then warn("EquipItem ���� ����!"); print("===== [DEBUG] InventoryManager.EquipItem ���� (����: ���� ����) ====="); return false,"���� ����" end
	if not PlayerData or not ItemDatabase then warn("EquipItem ��� �ε� ����!"); print("===== [DEBUG] InventoryManager.EquipItem ���� (����: ��� �ε� ����) ====="); return false,"��� �ε� ����" end

	local playerData=PlayerData.GetSessionData(player);
	if not playerData then warn("EquipItem ���� ������ ����"); print("===== [DEBUG] InventoryManager.EquipItem ���� (����: ���� ������ ����) ====="); return false,"�÷��̾� ������ ����" end

	print("[DEBUG] EquipItem: ���� Equipped ����:", playerData.Equipped and HttpService:JSONEncode(playerData.Equipped) or "nil")
	print("[DEBUG] EquipItem: ���� Inventory ����:", playerData.Inventory and HttpService:JSONEncode(playerData.Inventory) or "nil")

	local itemInfo=ItemDatabase.Items[itemId];
	if not itemInfo then warn("EquipItem �� �� ���� ������:",itemId); print("===== [DEBUG] InventoryManager.EquipItem ���� (����: �� �� ���� ������) ====="); return false,"�� �� ���� ������" end
	if itemInfo.Type~="Equipment" or not itemInfo.Slot then warn("EquipItem ���� �Ұ� ������:",itemId); print("===== [DEBUG] InventoryManager.EquipItem ���� (����: ���� �Ұ� ������) ====="); return false,"���� �Ұ� ������" end

	-- �䱸 ���� üũ
	local requirementMet=true; local failMessage=""; local requirements={Sword=itemInfo.requiredSword,Gun=itemInfo.requiredGun,DF=itemInfo.requiredDF};
	for statName,requiredValue in pairs(requirements) do
		if requiredValue and requiredValue>0 then
			local playerStatValue=playerData[statName] or 0;
			print(string.format("[DEBUG] EquipItem Requirement Check: ItemID=%d, Stat=%s, Required=%s, PlayerHas=%s", itemId, statName, tostring(requiredValue), tostring(playerStatValue)))
			if playerStatValue<requiredValue then
				requirementMet=false;
				failMessage=string.format("�䱸 ���� ����: %s %d (���� %d)",statName,requiredValue,playerStatValue);
				break
			end
		end
	end;

	if not requirementMet then
		warn("EquipItem �䱸 ���� ����:",failMessage);
		print("[DEBUG] EquipItem: Requirement not met. Checking NotifyPlayerEvent...")
		print("[DEBUG] EquipItem: Value of NotifyPlayerEvent is:", NotifyPlayerEvent)
		if NotifyPlayerEvent then print("[DEBUG] InventoryManager.EquipItem: Firing NotifyPlayerEvent for unmet requirement:", failMessage); NotifyPlayerEvent:FireClient(player,"EquipFailed",{reason = failMessage}); print("[DEBUG] InventoryManager.EquipItem: NotifyPlayerEvent fired.") -- �˸� Ÿ�� ����
		else print("[DEBUG] InventoryManager.EquipItem: NotifyPlayerEvent is nil! Cannot fire notification.") end;
		print("===== [DEBUG] InventoryManager.EquipItem ���� (����: �䱸 ���� ����) =====");
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
			itemDataToEquip.quantity = 1 -- ���� �� ������ �׻� 1
			itemInventoryIndex = i
			print(string.format("  [DEBUG] EquipItem: Found item in inventory at index %d. Data to equip: %s", i, HttpService:JSONEncode(itemDataToEquip)))
			break
		end
	end

	if not itemDataToEquip then
		warn("EquipItem �κ� ������ ����:",itemId);
		print("===== [DEBUG] InventoryManager.EquipItem ���� (����: �κ��丮�� ������ ����) =====");
		return false,"�κ��丮�� �������� �����ϴ�." -- �޽��� ����
	end

	local targetSlot = nil;
	if itemInfo.Slot=="Weapon" or itemInfo.Slot=="Armor" then targetSlot=itemInfo.Slot
	elseif itemInfo.Slot=="Accessory" then
		local accessorySlotsToTry={"Accessory1","Accessory2","Accessory3"};
		for _,slotName in ipairs(accessorySlotsToTry) do
			if not playerData.Equipped[slotName] then targetSlot=slotName; break end
		end;
		if not targetSlot then
			warn("EquipItem: ��� �Ǽ��縮 ���� ���� ��");
			if NotifyPlayerEvent then NotifyPlayerEvent:FireClient(player,"EquipFailed",{reason = "��� �Ǽ��縮 ������ ���� á���ϴ�."}) end -- �˸� �߰�
			print("===== [DEBUG] InventoryManager.EquipItem ���� (����: �Ǽ��縮 ���� ����) =====");
			return false,"��� �Ǽ��縮 ������ ���� á���ϴ�." -- �޽��� ����
		end
	else warn("EquipItem �� �� ���� ���� Ÿ��:",itemInfo.Slot); print("===== [DEBUG] InventoryManager.EquipItem ���� (����: �� �� ���� ���� Ÿ��) ====="); return false,"�� �� ���� ���� Ÿ���Դϴ�." end

	print(string.format("[DEBUG] EquipItem: Determined target slot: %s", targetSlot))

	-- 1. �κ��丮���� ������ ���� (���� �Լ� ���)
	print(string.format("[DEBUG] EquipItem: Removing item from inventory index %d using RemoveItem", itemInventoryIndex))
	-- RemoveItem �Լ��� ���������� inventoryUpdatedEvent�� �߻���Ű�Ƿ� ���⼭ ���� �߻���ų �ʿ� ����
	local removeSuccess, removeMsg = InventoryManager.RemoveItem(player, itemId, 1)
	if not removeSuccess then
		warn("EquipItem �κ� ������ ���� ����! Index:", itemInventoryIndex, "Reason:", removeMsg)
		if NotifyPlayerEvent then NotifyPlayerEvent:FireClient(player,"EquipFailed",{reason = removeMsg or "�κ��丮���� �������� ������ �� �����ϴ�."}) end
		print("===== [DEBUG] InventoryManager.EquipItem ���� (����: �κ��丮 ������ ���� ����) =====");
		return false, removeMsg or "�κ��丮 ������ ���� ����"
	end
	print("[DEBUG] EquipItem: Successfully removed item from inventory.")

	-- 2. ���� ������ ���� �� �κ��丮 �߰�
	local previousItemData = playerData.Equipped[targetSlot]
	print(string.format("[DEBUG] EquipItem: Previous item in slot %s: %s", targetSlot, previousItemData and HttpService:JSONEncode(previousItemData) or "nil"))
	if previousItemData then
		print(string.format("[DEBUG] EquipItem: Adding previous item back to inventory: %s", HttpService:JSONEncode(previousItemData)))
		-- AddItem�� ���������� inventoryUpdatedEvent�� �߻���Ŵ
		local addedBackSuccess, addBackMsg = InventoryManager.AddItem(player, previousItemData.itemId, 1, previousItemData)
		if not addedBackSuccess then
			warn("EquipItem ���� ������ �κ� ���� ����! �ѹ�...", addBackMsg or "")
			print("[DEBUG] EquipItem: Rolling back inventory removal...")
			-- �ѹ�: �����ߴ� �������� �ٽ� �κ��� �߰� (���� remove�� ���������Ƿ� �ٽ� add)
			local rollbackAddSuccess, rollbackAddMsg = InventoryManager.AddItem(player, itemId, 1, itemDataToEquip)
			if not rollbackAddSuccess then warn("EquipItem: Inventory rollback failed!", rollbackAddMsg) end
			print("===== [DEBUG] InventoryManager.EquipItem ���� (����: ���� ������ ���� ����) =====");
			return false, "���� ������ ����(�κ� ����) ����. ("..(addBackMsg or "")..")"
		end
		print("[DEBUG] EquipItem: Successfully added previous item back to inventory.")
	end

	-- 3. �� ������ ����
	print(string.format("[DEBUG] EquipItem: Equipping new item to slot %s: %s", targetSlot, HttpService:JSONEncode(itemDataToEquip)))
	playerData.Equipped[targetSlot] = itemDataToEquip
	print("Equipped item",itemId,"to slot",targetSlot,"Enh:",itemDataToEquip.enhancementLevel or 0)

	-- 4. ���� ����
	print("[DEBUG] EquipItem: Recalculating derived stats...")
	if PlayerData._RecalculateDerivedStats then PlayerData._RecalculateDerivedStats(player) else warn("EquipItem: _RecalculateDerivedStats ����!") end

	print(string.format("===== [DEBUG] InventoryManager.EquipItem ����: ItemID: %s -> Slot: %s =====", tostring(itemId), targetSlot));
	return true, nil
end


-- ������ ���� �Լ� (����� print �߰�)
function InventoryManager.UnequipItem(player, slot, internalCall)
	print(string.format("===== [DEBUG] InventoryManager.UnequipItem ����: Player: %s, Slot: %s, InternalCall: %s =====", player.Name, tostring(slot), tostring(internalCall)))

	if not RunService:IsServer() then print("UnequipItem: Not server!"); print("===== [DEBUG] InventoryManager.UnequipItem ���� (����: ���� ����) ====="); return false,"���� ����" end
	if not PlayerData or not ItemDatabase then print("UnequipItem: Module load error!"); print("===== [DEBUG] InventoryManager.UnequipItem ���� (����: ��� �ε� ����) ====="); return false,"��� �ε� ����" end

	local playerData=PlayerData.GetSessionData(player);
	if not playerData then print("UnequipItem: No player data!"); print("===== [DEBUG] InventoryManager.UnequipItem ���� (����: ���� ������ ����) ====="); return false,"�÷��̾� ������ ����" end
	if not slot or typeof(slot)~="string" then print("UnequipItem: Invalid slot type:", typeof(slot)); print("===== [DEBUG] InventoryManager.UnequipItem ���� (����: �߸��� ����) ====="); return false,"�߸��� ����" end

	playerData.Equipped = playerData.Equipped or {}
	print("[DEBUG] UnequipItem: ���� Equipped ����:", HttpService:JSONEncode(playerData.Equipped)) -- ���� ���� ���� ���

	local itemDataToUnequip = playerData.Equipped[slot]
	print("[DEBUG] UnequipItem: ������ ������ Ȯ�� for slot '"..slot.."':", itemDataToUnequip and HttpService:JSONEncode(itemDataToUnequip) or "nil")

	if not itemDataToUnequip then print("UnequipItem: Slot is empty:", slot); print("===== [DEBUG] InventoryManager.UnequipItem ���� (����: ���� �������) ====="); return false,"�ش� ���� �������" end
	if typeof(itemDataToUnequip) ~= 'table' or not itemDataToUnequip.itemId then
		warn("UnequipItem: Invalid data in equipped slot:", slot, itemDataToUnequip);
		playerData.Equipped[slot] = nil;
		print("[DEBUG] UnequipItem: Invalid data found, cleared slot:", slot);
		print("===== [DEBUG] InventoryManager.UnequipItem ���� (����: ���� ���� ������ ����) =====");
		return false, "���� ���� ������ ����"
	end

	print("[DEBUG] UnequipItem: Clearing equipped slot:", slot)
	playerData.Equipped[slot]=nil

	print("[DEBUG] UnequipItem: Calling AddItem to return item to inventory:", HttpService:JSONEncode(itemDataToUnequip))
	local itemAddedSuccess, addMessage = InventoryManager.AddItem(player, itemDataToUnequip.itemId, 1, itemDataToUnequip)
	print("[DEBUG] UnequipItem: AddItem result - Success:", itemAddedSuccess, "Message:", addMessage)

	if not itemAddedSuccess then
		print("[DEBUG] UnequipItem: AddItem FAILED! Rolling back slot clear...")
		warn("UnequipItem �κ� �߰� ����! �ѹ�... -", addMessage or "")
		playerData.Equipped[slot] = itemDataToUnequip
		print("===== [DEBUG] InventoryManager.UnequipItem ���� (����: �κ� �߰� �Ұ�) =====");
		return false, addMessage or "�κ��丮�� �߰��� �� �����ϴ�." -- �޽��� ����
	end

	print("Unequipped item from slot",slot,"(ItemID:", itemDataToUnequip.itemId, "Enh:", itemDataToUnequip.enhancementLevel or 0,")")

	if not internalCall then
		print("[DEBUG] UnequipItem: Recalculating derived stats (not internal call)...")
		if PlayerData._RecalculateDerivedStats then PlayerData._RecalculateDerivedStats(player) else warn("UnequipItem: _RecalculateDerivedStats ����!") end
	else
		print("[DEBUG] UnequipItem: Skipping stat recalculation (internal call).")
	end

	print(string.format("===== [DEBUG] InventoryManager.UnequipItem ����: Slot: %s =====", tostring(slot)));
	return true, nil
end


-- ������ �Ǹ� �Լ� (����)
function InventoryManager.SellItem(player, itemId, quantity) if not RunService:IsServer() then return false end; if not PlayerData or not ItemDatabase then return false end; local pData=PlayerData.GetSessionData(player); if not pData then return false end; local itemInfo=ItemDatabase.Items[itemId]; if not itemInfo then return false end; if typeof(quantity)~='number' or quantity<=0 then return false end; local sellPrice=itemInfo.SellPrice; if sellPrice==nil then sellPrice=math.floor((itemInfo.Price or 0)/2) end; if sellPrice<=0 then warn("Cannot sell item:",itemId); return false end; local currentQuantity=InventoryManager.CountItem(player,itemId); if currentQuantity<quantity then return false end; local removedSuccess,removeMessage=InventoryManager.RemoveItem(player,itemId,quantity); if not removedSuccess then warn("Failed to remove item during selling:",removeMessage or ""); return false end; local goldToGain=sellPrice*quantity; local currentGold=pData.Gold or 0; local updateGoldSuccess=PlayerData.UpdateStat(player,"Gold",currentGold+goldToGain); if not updateGoldSuccess then warn("Failed to update gold! Rolling back..."); InventoryManager.AddItem(player,itemId,quantity); return false end; print("Sold item",itemId,"x",quantity,"for",goldToGain,"gold. Player:",player.Name); if playerStatsUpdatedEvent then playerStatsUpdatedEvent:FireClient(player) end; return true end

-- ������ ���� �Լ� (����)
function InventoryManager.CraftItem(player, recipeId) if not RunService:IsServer() then return false end; if not PlayerData or not ItemDatabase or not CraftingDatabase then return false end; local pData=PlayerData.GetSessionData(player); if not pData then return false end; local recipe=CraftingDatabase.Recipes[recipeId]; if not recipe then return false end; print("Attempting craft:",recipeId); local canCraft=true; local materialsToRemove={}; if recipe.Materials then pData.Inventory = pData.Inventory or {}; for _,materialInfo in ipairs(recipe.Materials) do local requiredItemId=materialInfo.ItemID; local requiredQuantity=materialInfo.Quantity; local currentQuantity=InventoryManager.CountItem(player, requiredItemId); if currentQuantity<requiredQuantity then print("Not enough material:",requiredItemId); canCraft=false; break end; table.insert(materialsToRemove,{ItemID=requiredItemId,Quantity=requiredQuantity}) end else warn("Recipe has no materials:",recipeId); canCraft=false end; if not canCraft then return false end; local removedSuccessfully=true; local itemsToRemoveRollback={}; for _,materialToRemove in ipairs(materialsToRemove) do local removeSuccess,removeMsg=InventoryManager.RemoveItem(player,materialToRemove.ItemID,materialToRemove.Quantity); if not removeSuccess then warn("Failed to remove material:",materialToRemove.ItemID,"Error:",removeMsg or ""); removedSuccessfully=false; break else table.insert(itemsToRemoveRollback,materialToRemove) end end; if not removedSuccessfully then print("Rolling back material removal..."); for _,itemToRollback in ipairs(itemsToRemoveRollback) do InventoryManager.AddItem(player,itemToRollback.ItemID,itemToRollback.Quantity) end; print("Rollback complete."); return false end; local resultItemId=recipe.ResultItemID; local resultQuantity=recipe.ResultQuantity or 1; local addedSuccessfully,addMsg=InventoryManager.AddItem(player,resultItemId,resultQuantity); if not addedSuccessfully then warn("Failed to add result item:",resultItemId,"Error:",addMsg or ""); print("Rolling back material removal..."); for _,materialToRemove in ipairs(materialsToRemove) do InventoryManager.AddItem(player,materialToRemove.ItemID,materialToRemove.Quantity) end; print("Rollback complete."); return false end; print("Crafting successful! Recipe:",recipeId,"Result:",resultItemId,"x",resultQuantity); return true end

-- ##### ������ ��ȭ �Լ� ���� (NotifyPlayerEvent ��� + ����� �α� �߰�) #####
function InventoryManager.EnhanceItem(player, inventorySlotIndex)
	print(string.format("DEBUG: EnhanceItem ȣ��� - Player: %s, Index: %s", player.Name, tostring(inventorySlotIndex))) -- ����� �α� �߰�
	if not RunService:IsServer() then return false, "���� ����" end
	if not PlayerData or not ItemDatabase or not EnhancementDatabase then warn("EnhanceItem: �ʼ� ��� �ε� ����!"); return false, "��ȭ �ý��� ����" end

	local pData = PlayerData.GetSessionData(player)
	if not pData then return false, "�÷��̾� ������ ����" end
	pData.Inventory = pData.Inventory or {}
	pData.Equipped = pData.Equipped or {}

	if not inventorySlotIndex or not pData.Inventory[inventorySlotIndex] then
		warn("EnhanceItem: �߸��� �κ��丮 �ε���:", inventorySlotIndex)
		if NotifyPlayerEvent then
			print("DEBUG: ����: �߸��� ������ ���� �̺�Ʈ �߼� �õ�") -- ����� �α� �߰�
			NotifyPlayerEvent:FireClient(player, "EnhancementResult", {success=false, reason="�߸��� ������ ����"})
		end
		return false, "�߸��� ������ ����"
	end

	local itemSlotData = pData.Inventory[inventorySlotIndex]
	local itemId = itemSlotData.itemId
	local currentLevel = itemSlotData.enhancementLevel or 0
	local itemInfo = ItemDatabase.GetItemInfo(itemId)

	if not itemInfo then
		if NotifyPlayerEvent then
			print("DEBUG: ����: �� �� ���� ������ �̺�Ʈ �߼� �õ�") -- ����� �α� �߰�
			NotifyPlayerEvent:FireClient(player, "EnhancementResult", {success=false, reason="�� �� ���� ������"})
		end;
		return false, "�� �� ���� ������"
	end
	if not itemInfo.Enhanceable then
		if NotifyPlayerEvent then
			print("DEBUG: ����: ��ȭ �Ұ� ������ �̺�Ʈ �߼� �õ�") -- ����� �α� �߰�
			NotifyPlayerEvent:FireClient(player, "EnhancementResult", {success=false, reason="��ȭ�� �� ���� �������Դϴ�."})
		end;
		return false, "��ȭ�� �� ���� �������Դϴ�."
	end

	local maxLevel = itemInfo.MaxEnhanceLevel or 0
	if currentLevel >= maxLevel then
		if NotifyPlayerEvent then
			print("DEBUG: ����: �ִ� ���� ���� �̺�Ʈ �߼� �õ�") -- ����� �α� �߰�
			NotifyPlayerEvent:FireClient(player, "EnhancementResult", {success=false, reason="�̹� �ִ� �����Դϴ�."})
		end;
		return false, "�̹� �ִ� �����Դϴ�."
	end

	local nextLevel = currentLevel + 1
	local levelInfo = EnhancementDatabase.GetLevelInfo(nextLevel)
	if not levelInfo then
		warn("EnhanceItem: ���� ���� ��ȭ ���� ����:", nextLevel);
		if NotifyPlayerEvent then
			print("DEBUG: ����: �� �̻� ��ȭ �Ұ� �̺�Ʈ �߼� �õ�") -- ����� �α� �߰�
			NotifyPlayerEvent:FireClient(player, "EnhancementResult", {success=false, reason="�� �̻� ��ȭ�� �� �����ϴ�."})
		end;
		return false, "�� �̻� ��ȭ�� �� �����ϴ�."
	end

	local requiredMaterials = levelInfo.Materials or {}; local goldCost = levelInfo.GoldCost or 0; local successRate = levelInfo.SuccessRate or 0; local canAfford = true; local failReason = ""
	if (pData.Gold or 0) < goldCost then canAfford = false; failReason = "��� ����" end
	if canAfford then for _, matData in ipairs(requiredMaterials) do local ownedQty = InventoryManager.CountItem(player, matData.ItemID); if ownedQty < matData.Quantity then canAfford = false; local matInfo = ItemDatabase.GetItemInfo(matData.ItemID); failReason = (matInfo and matInfo.Name or ("������ #"..matData.ItemID)) .. " ����"; break end end end
	if not canAfford then
		print("EnhanceItem: ��ȭ �Ұ� -", failReason);
		if NotifyPlayerEvent then
			print(string.format("DEBUG: ����: ��ȭ ���/��� ���� �̺�Ʈ �߼� �õ� - ����: %s", failReason)) -- ����� �α� �߰�
			NotifyPlayerEvent:FireClient(player, "EnhancementResult", {success=false, reason=failReason})
		end;
		return false, failReason
	end

	local consumedItems = {}; local consumedGold = false; local originalGold = pData.Gold
	local goldUpdateSuccess = PlayerData.UpdateStat(player, "Gold", originalGold - goldCost); if not goldUpdateSuccess then warn("EnhanceItem: ��� �Ҹ� ����!"); if NotifyPlayerEvent then NotifyPlayerEvent:FireClient(player, "EnhancementResult", {success=false, reason="��� �Ҹ� ����"}) end; return false, "��� �Ҹ� ����" end; consumedGold = true
	local materialsConsumeSuccess = true; for _, matData in ipairs(requiredMaterials) do local removeSuccess, removeMsg = InventoryManager.RemoveItem(player, matData.ItemID, matData.Quantity); if not removeSuccess then materialsConsumeSuccess = false; failReason = removeMsg or "��� �Ҹ� ����"; warn("EnhanceItem: ��� �Ҹ� ����!", matData.ItemID, failReason); break else table.insert(consumedItems, {itemId = matData.ItemID, quantity = matData.Quantity}) end end
	if not materialsConsumeSuccess then print("EnhanceItem: ��� �Ҹ� ����, �ѹ� ����..."); if consumedGold then PlayerData.UpdateStat(player, "Gold", originalGold) end; for _, consumedItem in ipairs(consumedItems) do InventoryManager.AddItem(player, consumedItem.itemId, consumedItem.quantity) end; print("EnhanceItem: �ѹ� �Ϸ�."); if NotifyPlayerEvent then NotifyPlayerEvent:FireClient(player, "EnhancementResult", {success=false, reason=failReason}) end; return false, failReason end

	local roll = math.random(); local enhanceSuccess = (roll <= successRate);

	if enhanceSuccess then
		local newLevel = nextLevel
		itemSlotData.enhancementLevel = newLevel -- �κ��丮 ������ ���� ������Ʈ
		print("EnhanceItem: ��ȭ ����! Inventory", itemId, "+", newLevel)

		-- <<< ��ȭ ���� NotifyPlayerEvent �߼� >>>
		if NotifyPlayerEvent then
			print(string.format("DEBUG: ����: ��ȭ ���� �̺�Ʈ �߼� �õ� - ������: %s, �� ����: %d", itemInfo.Name or "������", newLevel)) -- ����� �α� �߰�
			NotifyPlayerEvent:FireClient(player, "EnhancementResult", {
				success = true,
				itemName = itemInfo.Name or "������",
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
		local failReasonText = "��ȭ ����..."
		print("EnhanceItem: ��ȭ ����.", itemId)

		-- <<< ��ȭ ���� NotifyPlayerEvent �߼� >>>
		if NotifyPlayerEvent then
			print(string.format("DEBUG: ����: ��ȭ ���� �̺�Ʈ �߼� �õ� - ������: %s, ����: %s", itemInfo.Name or "������", failReasonText)) -- ����� �α� �߰�
			NotifyPlayerEvent:FireClient(player, "EnhancementResult", {
				success = false,
				itemName = itemInfo.Name or "������",
				reason = failReasonText
			})
		end
	end

	-- EnhancementResultEvent�� ���� ������� ����
	-- if EnhancementResultEvent then ... end

	if inventoryUpdatedEvent then inventoryUpdatedEvent:FireClient(player) end

	-- ##### ������ ��ȯ �κ� #####
	if enhanceSuccess then
		return true, nil -- ���� ��: true�� nil ��ȯ
	else
		return false, "��ȭ ����..." -- ���� ��: false�� ���� �޽��� ��ȯ
	end
	-- ##### ���� �� #####
end
-- #####################################################


return InventoryManager