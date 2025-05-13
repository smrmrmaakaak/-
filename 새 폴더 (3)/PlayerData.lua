-- PlayerData.lua

local PlayerData = {}

local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService") -- JSONEncode를 위해 추가

local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local ItemDatabase = require(modulesFolder:WaitForChild("ItemDatabase"))
local SkillDatabase = require(modulesFolder:WaitForChild("SkillDatabase"))
-- CompanionDatabase도 필요할 수 있지만, 여기서는 PlayerData 구조에만 집중합니다.
-- local CompanionDatabase = require(modulesFolder:WaitForChild("CompanionDatabase"))

local playerSessionData = {}

-- 기본 플레이어 데이터
local DEFAULT_PLAYER_DATA = {
	Name = "", Level = 1, Exp = 0, MaxExp = 100, Gold = 100, StatPoints = 0,
	STR = 1, AGI = 1, INT = 1, LUK = 1,
	DF = 0, Sword = 0, Gun = 0,
	CurrentHP = 100, CurrentMP = 10, CurrentTP = 0,
	Skills = {1},
	Inventory = {
		{itemId = 1, quantity = 5},
		{itemId = 106, quantity = 1, enhancementLevel = 0}
	},
	Equipped = { Weapon = nil, Armor = nil, Accessory1 = nil, Accessory2 = nil, Accessory3 = nil },
	ActiveDevilFruit = nil,

	OwnedCompanions = {},
	CurrentParty = { Player = true, Slot1 = nil, Slot2 = nil }
}
PlayerData.DEFAULT_PLAYER_DATA = DEFAULT_PLAYER_DATA
PlayerData.STATS_FOLDER_NAME = "PlayerStats"

local function updateValueObject(parent, name, value)
	local vo = parent:FindFirstChild(name)
	local vt = typeof(value)
	if name == "ActiveDevilFruit" and value == nil then value = ""; vt = "string" end

	if not vo then
		if vt == "number" then vo = Instance.new("NumberValue")
		elseif vt == "string" then vo = Instance.new("StringValue")
		elseif vt == "boolean" then vo = Instance.new("BoolValue")
		else
			warn("updateValueObject: Cannot create ValueObject for type", vt, "Name:", name)
			return
		end
		vo.Name = name
		vo.Parent = parent
		print("PlayerData: Created ValueObject:", name, "Type:", vo.ClassName)
	end

	if vo:IsA("NumberValue") and vt ~= "number" then warn("updateValueObject: Type mismatch for", name, "- Expected number, got", vt); return end
	if vo:IsA("StringValue") and vt ~= "string" then warn("updateValueObject: Type mismatch for", name, "- Expected string, got", vt); return end
	if vo:IsA("BoolValue") and vt ~= "boolean" then warn("updateValueObject: Type mismatch for", name, "- Expected boolean, got", vt); return end

	if vo.Value ~= value then
		vo.Value = value
	end
end

local function _RecalculateDerivedStats(player)
	print(string.format("===== [DEBUG] PlayerData._RecalculateDerivedStats 시작: Player: %s =====", player.Name))

	if not RunService:IsServer() then print("[DEBUG] _RecalculateDerivedStats: Not server!"); print("===== [DEBUG] PlayerData._RecalculateDerivedStats 종료 (실패: 서버 전용) ====="); return end
	local uid = player.UserId; local pData = playerSessionData[uid]; if not pData then print("[DEBUG] _RecalculateDerivedStats: No session data!"); print("===== [DEBUG] PlayerData._RecalculateDerivedStats 종료 (실패: 세션 데이터 없음) ====="); return end
	if not ItemDatabase then warn("PlayerData._RecalculateDerivedStats: ItemDatabase is still nil!"); print("===== [DEBUG] PlayerData._RecalculateDerivedStats 종료 (실패: ItemDatabase nil) ====="); return end

	local equipmentStats = {STR=0,AGI=0,INT=0,LUK=0,MaxHP=0,MaxMP=0,Defense=0,MagicDefense=0,MeleeAttack=0,RangedAttack=0,MagicAttack=0,EvasionRate=0,AccuracyRate=0,CritChance=0,CritDamage=0,DropRateBonus=0,ExpBonus=0,GoldBonus=0}
	local equippedWeaponAttack = 0
	local equippedWeaponType = nil

	pData.Equipped = pData.Equipped or {}
	print("[DEBUG] _RecalculateDerivedStats: Current Equipped Data:", pData.Equipped)

	local slotNames = {"Weapon", "Armor", "Accessory1", "Accessory2", "Accessory3"}
	for _, slotName in ipairs(slotNames) do
		local equippedItemData = pData.Equipped[slotName]
		local equippedItemDataString = "nil" -- 디버깅용 문자열 초기화
		if equippedItemData then -- 테이블일 경우 JSONEncode 시도
			local successEncode, encodedString = pcall(HttpService.JSONEncode, HttpService, equippedItemData)
			equippedItemDataString = successEncode and encodedString or tostring(equippedItemData)
		end
		print(string.format("  [DEBUG] _RecalculateDerivedStats: Checking slot '%s', Data: %s", slotName, equippedItemDataString))


		if equippedItemData and typeof(equippedItemData) == 'table' and equippedItemData.itemId then
			local itemId = equippedItemData.itemId
			print(string.format("    [DEBUG] _RecalculateDerivedStats: Found item in slot %s - ItemID: %s", slotName, tostring(itemId)))
			local itemInfo = ItemDatabase.GetItemInfo(itemId)

			if itemInfo then
				if itemInfo.Stats then
					for statNameValue, value in pairs(itemInfo.Stats) do
						if slotName == "Weapon" and statNameValue == "Attack" then
							equippedWeaponAttack = value
						elseif equipmentStats[statNameValue] then
							equipmentStats[statNameValue] = equipmentStats[statNameValue] + value
						end
					end
				end
				if slotName == "Weapon" then equippedWeaponType = itemInfo.WeaponType end

				if itemInfo.Enhanceable then
					local currentLevel = equippedItemData.enhancementLevel or 0
					if currentLevel > 0 then
						local enhanceStat = itemInfo.EnhanceStat
						local valuePerLevel = itemInfo.EnhanceValuePerLevel or 0
						local enhancementBonus = valuePerLevel * currentLevel
						if enhanceStat then
							print(string.format("      [DEBUG] Enhancement Bonus: ItemID=%s, Level=%d, Stat=%s, Bonus=%s", tostring(itemId), currentLevel, enhanceStat, tostring(enhancementBonus)))
							if slotName == "Weapon" and enhanceStat == "Attack" then
								equippedWeaponAttack = equippedWeaponAttack + enhancementBonus
							elseif equipmentStats[enhanceStat] then
								equipmentStats[enhanceStat] = equipmentStats[enhanceStat] + enhancementBonus
							else warn(string.format("Enhancement Bonus Error: Cannot apply bonus for undefined stat '%s' on item %d", enhanceStat, itemId)) end
						else warn(string.format("Enhancement Error: EnhanceStat not defined for enhanceable item %d", itemId)) end
					end
				end
			else
				warn("PlayerData._RecalculateDerivedStats: Could not find item info in ItemDatabase for ID:", itemId)
			end
		elseif equippedItemData then
			warn(string.format("  [DEBUG] _RecalculateDerivedStats: Invalid data format in slot '%s': %s", slotName, equippedItemDataString))
		end
	end

	local baseSTR = pData.STR or 1; local baseAGI = pData.AGI or 1; local baseINT = pData.INT or 1; local baseLUK = pData.LUK or 1
	local totalSTR = baseSTR + equipmentStats.STR; local totalAGI = baseAGI + equipmentStats.AGI; local totalINT = baseINT + equipmentStats.INT; local totalLUK = baseLUK + equipmentStats.LUK
	pData.TotalSTR = totalSTR; pData.TotalAGI = totalAGI; pData.TotalINT = totalINT; pData.TotalLUK = totalLUK
	local level = pData.Level or 1
	local calculatedMaxHP = 100 + (totalSTR * 5) + (level * 10) + equipmentStats.MaxHP; local calculatedMaxMP = 10 + (totalINT * 5) + (level * 2) + equipmentStats.MaxMP; local calculatedMaxTP = 100
	local baseAttack = 10; local meleeBonus = (totalSTR * 2); local rangedBonus = (totalAGI * 2)
	local calculatedMeleeAttack = baseAttack + meleeBonus + equippedWeaponAttack + equipmentStats.MeleeAttack; local calculatedRangedAttack = baseAttack + rangedBonus + equippedWeaponAttack + equipmentStats.RangedAttack; local calculatedMagicAttack = (totalINT * 2) + equipmentStats.MagicAttack
	local calculatedDefense = 0 + equipmentStats.Defense; local calculatedMagicDefense = 0 + equipmentStats.MagicDefense
	local calculatedAccuracyRate = 50 + (totalLUK * 0.02) + equipmentStats.AccuracyRate; local calculatedEvasionRate = 0 + (totalAGI * 0.02) + (totalLUK * 0.01) + equipmentStats.EvasionRate
	local calculatedDropRateBonus = (totalLUK * 0.05) + equipmentStats.DropRateBonus; local calculatedExpBonus = (totalLUK * 0.02) + equipmentStats.ExpBonus; local calculatedGoldBonus = (totalLUK * 0.02) + equipmentStats.GoldBonus
	local calculatedCritChance = 0 + (totalLUK * 0.02) + equipmentStats.CritChance; local calculatedCritDamage = 150 + (totalLUK * 0.1) + equipmentStats.CritDamage
	pData.MaxHP=calculatedMaxHP; pData.MaxMP=calculatedMaxMP; pData.MaxTP=calculatedMaxTP; pData.MeleeAttack=calculatedMeleeAttack; pData.RangedAttack=calculatedRangedAttack; pData.MagicAttack=calculatedMagicAttack; pData.Defense=calculatedDefense; pData.MagicDefense=calculatedMagicDefense; pData.AccuracyRate=calculatedAccuracyRate; pData.EvasionRate=calculatedEvasionRate; pData.DropRateBonus=calculatedDropRateBonus; pData.ExpBonus=calculatedExpBonus; pData.GoldBonus=calculatedGoldBonus; pData.CritChance=calculatedCritChance; pData.CritDamage=calculatedCritDamage

	print("[DEBUG] _RecalculateDerivedStats: Calculated Stats - MaxHP:", calculatedMaxHP, "MaxMP:", calculatedMaxMP, "MeleeAtk:", calculatedMeleeAttack, "Defense:", calculatedDefense)
	print("  -> TotalSTR:", totalSTR, "TotalAGI:", totalAGI, "TotalINT:", totalINT, "TotalLUK:", totalLUK)

	local statsFolder = player:FindFirstChild(PlayerData.STATS_FOLDER_NAME)
	if statsFolder then
		print(string.format("[DEBUG] PlayerData: Updating Total Stats VOs - STR:%d, AGI:%d, INT:%d, LUK:%d", totalSTR, totalAGI, totalINT, totalLUK))
		updateValueObject(statsFolder,"TotalSTR",totalSTR); updateValueObject(statsFolder,"TotalAGI",totalAGI); updateValueObject(statsFolder,"TotalINT",totalINT); updateValueObject(statsFolder,"TotalLUK",totalLUK);
		updateValueObject(statsFolder,"MaxHP",calculatedMaxHP); updateValueObject(statsFolder,"MaxMP",calculatedMaxMP); updateValueObject(statsFolder,"MaxTP",calculatedMaxTP); updateValueObject(statsFolder,"MeleeAttack",calculatedMeleeAttack); updateValueObject(statsFolder,"RangedAttack",calculatedRangedAttack); updateValueObject(statsFolder,"MagicAttack",calculatedMagicAttack); updateValueObject(statsFolder,"Defense",calculatedDefense); updateValueObject(statsFolder,"MagicDefense",calculatedMagicDefense); updateValueObject(statsFolder,"AccuracyRate",calculatedAccuracyRate); updateValueObject(statsFolder,"EvasionRate",calculatedEvasionRate); updateValueObject(statsFolder,"DropRateBonus",calculatedDropRateBonus); updateValueObject(statsFolder,"ExpBonus",calculatedExpBonus); updateValueObject(statsFolder,"GoldBonus",calculatedGoldBonus); updateValueObject(statsFolder,"CritChance",calculatedCritChance); updateValueObject(statsFolder,"CritDamage",calculatedCritDamage)
	else
		warn("[DEBUG] _RecalculateDerivedStats: PlayerStats folder not found, cannot update ValueObjects.")
	end

	PlayerData.UpdateStat(player,"CurrentHP",pData.CurrentHP); PlayerData.UpdateStat(player,"CurrentMP",pData.CurrentMP); PlayerData.UpdateStat(player,"CurrentTP",pData.CurrentTP)

	local playerStatsUpdatedEvent = ReplicatedStorage:FindFirstChild("PlayerStatsUpdatedEvent"); if playerStatsUpdatedEvent then playerStatsUpdatedEvent:FireClient(player) end
	print("PlayerData: Derived stats recalculated (incl. enhancement) for", player.Name)
	print("===== [DEBUG] PlayerData._RecalculateDerivedStats 종료 (성공) =====")
end
PlayerData._RecalculateDerivedStats = _RecalculateDerivedStats

function PlayerData.LoadData(player)
	print(string.format("===== [DEBUG] PlayerData.LoadData 시작: Player: %s (UserID: %s) =====", player.Name, player.UserId))

	if not RunService:IsServer() then print("[DEBUG] LoadData: Not server!"); print("===== [DEBUG] PlayerData.LoadData 종료 (실패: 서버 전용) ====="); return nil end
	local DataStoreService = game:GetService("DataStoreService"); local playerDataStore = DataStoreService:GetDataStore("PlayerDataStore_V2"); local userId = player.UserId; local dataKey = "Player_"..userId
	print("PlayerData: Loading data for UserID:", userId); if playerSessionData[userId] then warn("PlayerData: Data already loaded") end

	local loadedData = nil; local success, result = pcall(function() return playerDataStore:GetAsync(dataKey) end)

	if success then
		local resultString = "nil" -- 디버깅용 문자열 초기화
		if result then -- 테이블일 경우 JSONEncode 시도
			local successEncode, encodedString = pcall(HttpService.JSONEncode, HttpService, result)
			resultString = successEncode and encodedString or tostring(result)
		end
		print("[DEBUG] LoadData: DataStore GetAsync Success. Result:", resultString)

		if result and typeof(result) == 'table' then
			loadedData = result; print("PlayerData: Loaded existing data");

			print("[DEBUG] LoadData: Validating and migrating loaded data...")
			local defaultData = DEFAULT_PLAYER_DATA
			for key, defaultValue in pairs(defaultData) do
				if loadedData[key] == nil then
					-- ##### 수정된 부분: defaultValue를 tostring()으로 감쌈 #####
					print(string.format("  [DEBUG] LoadData: Key '%s' missing, using default: %s", key, tostring(defaultValue)))
					loadedData[key] = defaultValue
				elseif typeof(loadedData[key]) ~= typeof(defaultValue) then
					if key=="ActiveDevilFruit" and loadedData[key]==nil then
						print(string.format("  [DEBUG] LoadData: Key '%s' is nil, setting to default empty string.", key))
						loadedData[key] = ""
					else
						-- ##### 수정된 부분: defaultValue를 tostring()으로 감쌈 #####
						print(string.format("  [DEBUG] LoadData: Type mismatch for key '%s'. Expected %s, got %s. Using default: %s", key, typeof(defaultValue), typeof(loadedData[key]), tostring(defaultValue)))
						loadedData[key] = defaultValue
					end
				elseif typeof(loadedData[key]) == 'table' then
					if key == "Equipped" then
						print("  [DEBUG] LoadData: Validating 'Equipped' table...")
						local defaultEquipped = defaultData.Equipped
						for slotKey, defaultSlotValue in pairs(defaultEquipped) do
							local equippedValue = loadedData.Equipped[slotKey]
							if equippedValue == nil then
								print(string.format("    [DEBUG] Equipped slot '%s' is nil, ensuring it remains nil.", slotKey))
								loadedData.Equipped[slotKey] = nil
							elseif typeof(equippedValue) == 'number' then
								print(string.format("    [DEBUG] Equipped slot '%s' has old format (number: %d). Converting to new format.", slotKey, equippedValue))
								loadedData.Equipped[slotKey] = {itemId = equippedValue, enhancementLevel = 0}
							elseif typeof(equippedValue) == 'table' then
								if equippedValue.itemId == nil then
									print(string.format("    [DEBUG] Equipped slot '%s' is a table but missing itemId. Resetting to nil.", slotKey))
									loadedData.Equipped[slotKey] = nil
								elseif equippedValue.enhancementLevel == nil then
									print(string.format("    [DEBUG] Equipped slot '%s' table is missing enhancementLevel. Adding default 0.", slotKey))
									equippedValue.enhancementLevel = 0
								end
							else
								print(string.format("    [DEBUG] Equipped slot '%s' has unexpected type (%s). Resetting to nil.", slotKey, typeof(equippedValue)))
								loadedData.Equipped[slotKey] = nil
							end
						end
					elseif key == "Inventory" then
						print("  [DEBUG] LoadData: Validating 'Inventory' table...")
						for i = #loadedData.Inventory, 1, -1 do
							local itemSlot = loadedData.Inventory[i]
							local itemSlotString = "nil"
							if itemSlot then local sucEnc, encStr = pcall(HttpService.JSONEncode, HttpService, itemSlot); itemSlotString = sucEnc and encStr or tostring(itemSlot) end

							if itemSlot and typeof(itemSlot)=='table' and itemSlot.itemId then
								local itemInfo = ItemDatabase.GetItemInfo(itemSlot.itemId)
								if itemInfo and itemInfo.Type=="Equipment" and itemInfo.Enhanceable and itemSlot.enhancementLevel == nil then
									print(string.format("    [DEBUG] Inventory item (ID: %s) at index %d missing enhancementLevel. Adding default 0.", tostring(itemSlot.itemId), i))
									itemSlot.enhancementLevel = 0
								end
							else
								warn(string.format("    [DEBUG] Invalid inventory slot data at index %d: %s. Removing slot.", i, itemSlotString))
								table.remove(loadedData.Inventory, i)
							end
						end
					elseif key == "OwnedCompanions" then
						print("  [DEBUG] LoadData: Validating 'OwnedCompanions' table...")
						if typeof(loadedData.OwnedCompanions) ~= 'table' then
							print("    [DEBUG] OwnedCompanions is not a table, resetting to default empty table.")
							loadedData.OwnedCompanions = {}
						end
					elseif key == "CurrentParty" then
						print("  [DEBUG] LoadData: Validating 'CurrentParty' table...")
						if typeof(loadedData.CurrentParty) ~= 'table' then
							print("    [DEBUG] CurrentParty is not a table, resetting to default.")
							loadedData.CurrentParty = { Player = true, Slot1 = nil, Slot2 = nil }
						else
							if loadedData.CurrentParty.Player == nil then loadedData.CurrentParty.Player = true end
							if loadedData.CurrentParty.Slot1 == nil then loadedData.CurrentParty.Slot1 = nil end
							if loadedData.CurrentParty.Slot2 == nil then loadedData.CurrentParty.Slot2 = nil end
						end
					end
				end
			end
			print("[DEBUG] LoadData: Data validation and migration complete.")

		else print("PlayerData: No valid data found or data is not a table. Initializing default."); loadedData = {}; for key, value in pairs(DEFAULT_PLAYER_DATA) do loadedData[key] = value end; loadedData.Name = player.Name; loadedData.CurrentHP = DEFAULT_PLAYER_DATA.CurrentHP; loadedData.CurrentMP = DEFAULT_PLAYER_DATA.CurrentMP; loadedData.CurrentTP = DEFAULT_PLAYER_DATA.CurrentTP end
	else warn("PlayerData: Failed to load data! Error:", result); loadedData = {}; for key, value in pairs(DEFAULT_PLAYER_DATA) do loadedData[key] = value end; loadedData.Name = player.Name; loadedData.CurrentHP = DEFAULT_PLAYER_DATA.CurrentHP; loadedData.CurrentMP = DEFAULT_PLAYER_DATA.CurrentMP; loadedData.CurrentTP = DEFAULT_PLAYER_DATA.CurrentTP end

	playerSessionData[userId] = loadedData;
	print("PlayerData: Session data established")

	local equippedDataString = loadedData.Equipped and HttpService:JSONEncode(loadedData.Equipped) or "nil"
	local inventoryDataString = loadedData.Inventory and HttpService:JSONEncode(loadedData.Inventory) or "nil"
	local ownedCompanionsString = loadedData.OwnedCompanions and HttpService:JSONEncode(loadedData.OwnedCompanions) or "nil"
	local currentPartyString = loadedData.CurrentParty and HttpService:JSONEncode(loadedData.CurrentParty) or "nil"

	print("[DEBUG] LoadData: Final Loaded Equipped Data Structure:", equippedDataString)
	print("[DEBUG] LoadData: Final Loaded Inventory Data Structure:", inventoryDataString)
	print("[DEBUG] LoadData: Final Loaded OwnedCompanions Data Structure:", ownedCompanionsString)
	print("[DEBUG] LoadData: Final Loaded CurrentParty Data Structure:", currentPartyString)

	local statsFolder = player:FindFirstChild(PlayerData.STATS_FOLDER_NAME); if not statsFolder then statsFolder=Instance.new("Folder"); statsFolder.Name=PlayerData.STATS_FOLDER_NAME; statsFolder.Parent=player end
	updateValueObject(statsFolder,"Level",loadedData.Level); updateValueObject(statsFolder,"Exp",loadedData.Exp); updateValueObject(statsFolder,"MaxExp",loadedData.MaxExp); updateValueObject(statsFolder,"Gold",loadedData.Gold); updateValueObject(statsFolder,"StatPoints",loadedData.StatPoints); updateValueObject(statsFolder,"STR",loadedData.STR); updateValueObject(statsFolder,"AGI",loadedData.AGI); updateValueObject(statsFolder,"INT",loadedData.INT); updateValueObject(statsFolder,"LUK",loadedData.LUK); updateValueObject(statsFolder,"DF",loadedData.DF); updateValueObject(statsFolder,"Sword",loadedData.Sword); updateValueObject(statsFolder,"Gun",loadedData.Gun); updateValueObject(statsFolder,"CurrentHP",loadedData.CurrentHP); updateValueObject(statsFolder,"CurrentMP",loadedData.CurrentMP); updateValueObject(statsFolder,"CurrentTP",loadedData.CurrentTP); updateValueObject(statsFolder,"ActiveDevilFruit",loadedData.ActiveDevilFruit)
	local derivedAndTotalStats = {"MaxHP","MaxMP","MaxTP","MeleeAttack","RangedAttack","MagicAttack","Defense","MagicDefense","EvasionRate","AccuracyRate","CritChance","CritDamage","DropRateBonus","ExpBonus","GoldBonus","TotalSTR","TotalAGI","TotalINT","TotalLUK"}
	for _, statName in ipairs(derivedAndTotalStats) do
		if not statsFolder:FindFirstChild(statName) then
			local defaultValue = 0
			if statName == "TotalSTR" then defaultValue = loadedData.STR or 1
			elseif statName == "TotalAGI" then defaultValue = loadedData.AGI or 1
			elseif statName == "TotalINT" then defaultValue = loadedData.INT or 1
			elseif statName == "TotalLUK" then defaultValue = loadedData.LUK or 1
			elseif statName == "MaxHP" then defaultValue = 100
			elseif statName == "MaxMP" then defaultValue = 10
			elseif statName == "MaxTP" then defaultValue = 100
			elseif statName == "MeleeAttack" or statName == "RangedAttack" then defaultValue = 10
			elseif statName == "AccuracyRate" then defaultValue = 50
			elseif statName == "CritDamage" then defaultValue = 150
			end
			updateValueObject(statsFolder, statName, defaultValue)
		end
	end
	_RecalculateDerivedStats(player)
	print("PlayerData: Data load/initialization complete.")
	print(string.format("===== [DEBUG] PlayerData.LoadData 종료: Player: %s =====", player.Name))
	return playerSessionData[userId]
end

function PlayerData.SaveData(player)
	if not RunService:IsServer() then return end
	local DataStoreService = game:GetService("DataStoreService")
	local playerDataStore = DataStoreService:GetDataStore("PlayerDataStore_V2")
	local userId = player.UserId
	local sessionData = playerSessionData[userId]
	if not sessionData then warn("SaveData: No session data", userId); return end
	local dataToSave = {}
	local saveKeys = {
		"Name","Level","Exp","MaxExp","Gold","StatPoints",
		"STR","AGI","INT","LUK","DF","Sword","Gun",
		"CurrentHP","CurrentMP","CurrentTP",
		"Skills","Inventory","Equipped","ActiveDevilFruit",
		"OwnedCompanions", "CurrentParty"
	}
	for _, key in ipairs(saveKeys) do
		if sessionData[key] ~= nil then dataToSave[key] = sessionData[key] end
	end
	local dataToSaveString = HttpService:JSONEncode(dataToSave) -- 테이블 직접 출력 대신 JSON 문자열로 변환
	print("Attempting save:", userId, "Data:", dataToSaveString)
	local dataKey = "Player_"..userId
	local success, errorMessage = pcall(function() playerDataStore:SetAsync(dataKey, dataToSave) end)
	if success then print("Save success:", userId) else warn("Save failed:", userId, errorMessage) end
end

function PlayerData.ClearSessionData(player) if not RunService:IsServer() then return end; local userId = player.UserId; if playerSessionData[userId] then print("Clearing session:", userId); playerSessionData[userId] = nil end end
function PlayerData.GetSessionData(player) if not RunService:IsServer() then warn("GetSessionData server only"); return nil end; if not player or not player:IsA("Player") then return nil end; return playerSessionData[player.UserId] end
function PlayerData.GetStats(player) if RunService:IsServer() then local userId=player.UserId; local sessionData=playerSessionData[userId]; if not sessionData then return nil end; local statsCopy={}; for key,value in pairs(sessionData) do statsCopy[key]=value end; return statsCopy else local statsFolder=player:WaitForChild(PlayerData.STATS_FOLDER_NAME,15); if not statsFolder then warn("GetStats(Client): No Stats folder!"); return {} end; local currentStats={}; local function getValueFromObject(statName, defaultValue) local valueObject=statsFolder:FindFirstChild(statName); if valueObject and valueObject:IsA("ValueBase") then local val = valueObject.Value; if statName=="ActiveDevilFruit" and val=="" then return nil end; if typeof(defaultValue)=='number' and val==nil then return defaultValue end; return val else return defaultValue end end; local allStatKeys={"Name","Level","Exp","MaxExp","Gold","StatPoints","STR","AGI","INT","LUK","TotalSTR","TotalAGI","TotalINT","TotalLUK","DF","Sword","Gun","CurrentHP","CurrentMP","CurrentTP","ActiveDevilFruit","MaxHP","MaxMP","MaxTP","MeleeAttack","RangedAttack","MagicAttack","Defense","MagicDefense","EvasionRate","AccuracyRate","CritChance","CritDamage","DropRateBonus","ExpBonus","GoldBonus"}; currentStats.Name=player.Name; for _, key in ipairs(allStatKeys) do if key~="Name" then local defaultValue=DEFAULT_PLAYER_DATA[key]; if defaultValue==nil then if key:sub(1,5)=="Total" then defaultValue=1 elseif key=="MaxHP" then defaultValue=100 elseif key=="MaxMP" then defaultValue=10 elseif key=="MaxTP" then defaultValue=100 elseif key=="MeleeAttack" or key=="RangedAttack" then defaultValue=10 elseif key=="AccuracyRate" then defaultValue=50 elseif key=="CritDamage" then defaultValue=150 else defaultValue=0 end end; currentStats[key]=getValueFromObject(key, defaultValue) end end; currentStats.Skills={}; currentStats.Inventory={}; currentStats.Equipped={}; return currentStats end end
function PlayerData.GetSkill(skillId) if SkillDatabase and SkillDatabase.Skills and SkillDatabase.Skills[skillId] then local skillCopy={}; for k,v in pairs(SkillDatabase.Skills[skillId]) do skillCopy[k]=v end; return skillCopy else return nil end end
function PlayerData.UpdateStat(player, statName, value) if not RunService:IsServer() then return false end; local userId=player.UserId; local sessionData=playerSessionData[userId]; if not sessionData then return false end; local nonUpdatableStats={TotalSTR=true,TotalAGI=true,TotalINT=true,TotalLUK=true,MaxHP=true,MaxMP=true,MaxTP=true,MeleeAttack=true,RangedAttack=true,MagicAttack=true,Defense=true,MagicDefense=true,EvasionRate=true,AccuracyRate=true,CritChance=true,CritDamage=true,DropRateBonus=true,ExpBonus=true,GoldBonus=true,Skills=true,Inventory=true,Equipped=true,ActiveDevilFruit=true}; if nonUpdatableStats[statName] then warn("UpdateStat: Cannot directly update:", statName); return false end; if typeof(value)=='table' then warn("UpdateStat: Cannot set table:", statName); return false end; local currentValue=sessionData[statName]; if currentValue==nil then warn("UpdateStat: Stat does not exist:", statName); return false end; if typeof(currentValue)=='number' and typeof(value)~='number' then value=tonumber(value) or currentValue end; if typeof(currentValue)~=typeof(value) then warn("UpdateStat: Type mismatch:", statName); return false end; if typeof(value)=='number' then if statName=="CurrentHP" then value=math.clamp(value,0,sessionData.MaxHP or 0) elseif statName=="CurrentMP" then value=math.clamp(value,0,sessionData.MaxMP or 0) elseif statName=="CurrentTP" then value=math.clamp(value,0,sessionData.MaxTP or 100) elseif statName=="Exp" or statName=="Gold" or statName=="StatPoints" or statName=="Level" or statName=="STR" or statName=="AGI" or statName=="INT" or statName=="LUK" or statName=="DF" or statName=="Sword" or statName=="Gun" then value=math.max(0, value) end; value=math.floor(value + 0.5) end; if sessionData[statName]~=value then sessionData[statName]=value; local statsFolder=player:FindFirstChild(PlayerData.STATS_FOLDER_NAME); if statsFolder then updateValueObject(statsFolder, statName, value) end; if ({STR=1,AGI=1,INT=1,LUK=1})[statName] then _RecalculateDerivedStats(player) end; return true else return true end end
function PlayerData.AddExp(player, amount) if not RunService:IsServer() then return end; local userId=player.UserId; local sessionData=playerSessionData[userId]; if not sessionData then return end; if typeof(amount)~='number' or amount<=0 then return end; local currentLevel=sessionData.Level; local currentExp=sessionData.Exp+amount; local currentStatPoints=sessionData.StatPoints; local currentMaxExp=sessionData.MaxExp; local leveledUp=false; local statPointsGained=0; while currentExp>=currentMaxExp do currentLevel=currentLevel+1; currentExp=currentExp-currentMaxExp; currentMaxExp=math.floor(currentMaxExp*1.5); statPointsGained=statPointsGained+3; leveledUp=true; print("Level Up!",currentLevel) end; PlayerData.UpdateStat(player,"Level",currentLevel); PlayerData.UpdateStat(player,"Exp",currentExp); if leveledUp then PlayerData.UpdateStat(player,"MaxExp",currentMaxExp); PlayerData.UpdateStat(player,"StatPoints",currentStatPoints+statPointsGained); _RecalculateDerivedStats(player); PlayerData.UpdateStat(player,"CurrentHP",sessionData.MaxHP); PlayerData.UpdateStat(player,"CurrentMP",sessionData.MaxMP); PlayerData.UpdateStat(player,"CurrentTP",sessionData.MaxTP); print("Level up process complete."); local notifyEvent=ReplicatedStorage:FindFirstChild("NotifyPlayerEvent"); if notifyEvent then notifyEvent:FireClient(player,"레벨 업!",string.format("레벨 %d 달성! 스탯 포인트 %d 획득!",currentLevel,statPointsGained)) end end; local playerStatsUpdatedEvent=ReplicatedStorage:FindFirstChild("PlayerStatsUpdatedEvent"); if playerStatsUpdatedEvent then playerStatsUpdatedEvent:FireClient(player) end end
function PlayerData.LearnSkill(player, skillId) if not RunService:IsServer() then return false end; local userId=player.UserId; local sessionData=playerSessionData[userId]; if not sessionData then return false end; sessionData.Skills = sessionData.Skills or {}; local learnedSkills=sessionData.Skills; for _, learnedId in ipairs(learnedSkills) do if learnedId==skillId then return false end end; if not SkillDatabase or not SkillDatabase.Skills or not SkillDatabase.Skills[skillId] then warn("LearnSkill: Invalid Skill ID:", skillId); return false end; table.insert(learnedSkills, skillId); print("Learned skill ID:", skillId); return true end
function PlayerData.SpendStatPoint(player, statToIncrease) print("SpendStatPoint:", statToIncrease); if not RunService:IsServer() then warn("SpendStatPoint server only"); return false end; local playerData=PlayerData.GetSessionData(player); if not playerData then warn("SpendStatPoint no session data"); return false end; local validStatsToIncrease={STR=true,AGI=true,INT=true,LUK=true}; if not statToIncrease or typeof(statToIncrease)~="string" or not validStatsToIncrease[statToIncrease] then warn("SpendStatPoint invalid stat:", statToIncrease); return false end; if not playerData.StatPoints or playerData.StatPoints<=0 then print("SpendStatPoint no points"); return false end; print("Spending point. Current:", playerData.StatPoints); local currentPoints=playerData.StatPoints; local pointsUpdated=PlayerData.UpdateStat(player,"StatPoints",currentPoints-1); print("UpdateStat(StatPoints) returned:", pointsUpdated); if not pointsUpdated then warn("SpendStatPoint point deduction failed!"); return false end; local currentStatValue=playerData[statToIncrease]; local statIncreased=PlayerData.UpdateStat(player,statToIncrease,currentStatValue+1); print("UpdateStat("..statToIncrease..") returned:", statIncreased); if not statIncreased then warn("SpendStatPoint stat increase failed! Rolling back..."); PlayerData.UpdateStat(player,"StatPoints",currentPoints); return false end; print("SpendStatPoint success! New points:", playerData.StatPoints); return true end
function PlayerData.UpdateRequirementStat(player, statName, value) if not RunService:IsServer() then return false end; local validReq={DF=true,Sword=true,Gun=true}; if not validReq[statName] then warn("UpdateRequirementStat invalid name:", statName); return false end; if typeof(value)~='number' or value<0 then warn("UpdateRequirementStat invalid value:", value); return false end; local success=PlayerData.UpdateStat(player, statName, value); if success then local playerStatsUpdatedEvent=ReplicatedStorage:FindFirstChild("PlayerStatsUpdatedEvent"); if playerStatsUpdatedEvent then playerStatsUpdatedEvent:FireClient(player) end end; return success end

return PlayerData