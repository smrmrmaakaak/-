-- CombatManager.lua

--[[
  CombatManager (ModuleScript)
  ���� ������ �����ϴ� ��� (���� ��).
  *** [���� ����] StartNewCombat���� clientCompanions ������ ���� �� �ʵ��(hp, mp) ���� ***
  *** [���� ����] StartPlayerTurn, StartEnemyTurn���� playerStatus�� ��� �ʼ� ���� ���� ���� ***
  *** [��� �߰�] PlayerUseItem �Լ����� ���ῡ�� ������ ��� ���� �߰� ***
]]

local CombatManager = {}

-- �ʿ��� ���� �� ��� �ε�
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService") 

local modulesFolder = ReplicatedStorage:FindFirstChild("Modules")
if not modulesFolder then
	print("CombatManager: Modules ���� ��� ��...")
	modulesFolder = ReplicatedStorage:WaitForChild("Modules", 60) 
end

if not modulesFolder then
	warn("CombatManager: Modules ������ ã�� �� �����ϴ�! ��ũ��Ʈ ���� �ߴ�.")
	return nil 
end
print("CombatManager: Modules ���� �ε� �Ϸ�.")

local ModuleManager = require(modulesFolder:WaitForChild("ModuleManager", 10))
local successEnemyDB, EnemyDatabase = pcall(function() return require(modulesFolder:WaitForChild("EnemyDatabase", 10)) end)
if not successEnemyDB then warn("CombatManager: EnemyDatabase �ε� ����!", EnemyDatabase); EnemyDatabase = nil end
local PlayerData = require(modulesFolder:WaitForChild("PlayerData", 10))
local InventoryManager = require(modulesFolder:WaitForChild("InventoryManager", 10))
local ItemDatabase = require(modulesFolder:WaitForChild("ItemDatabase", 10))
local SkillDatabase = require(modulesFolder:WaitForChild("SkillDatabase", 10))
local CompanionDatabase = require(modulesFolder:WaitForChild("CompanionDatabase", 10))
local CompanionManagerServer = require(modulesFolder:WaitForChild("CompanionManager", 10)) 
if not CompanionDatabase then warn("CombatManager: CompanionDatabase �ε� ����!") end
if not CompanionManagerServer then warn("CombatManager: ������ CompanionManager �ε� ����!") end

local combatStartedEvent = ReplicatedStorage:WaitForChild("CombatStartedEvent")
local combatEndedEvent = ReplicatedStorage:WaitForChild("CombatEndedEvent")
local playerTurnEvent = ReplicatedStorage:WaitForChild("PlayerTurnEvent")
local enemyTurnEvent = ReplicatedStorage:WaitForChild("EnemyTurnEvent")
local combatLogEvent = ReplicatedStorage:WaitForChild("CombatLogEvent")
local combatEndedClientEvent = ReplicatedStorage:WaitForChild("CombatEndedClientEvent")
local updateCombatUIEvent = ReplicatedStorage:WaitForChild("UpdateCombatUIEvent")
local inventoryUpdatedEvent = ReplicatedStorage:WaitForChild("InventoryUpdatedEvent")
local combatDamageEvent = ReplicatedStorage:WaitForChild("CombatDamageEvent")

local activeCombats = {}
local nextEnemyInstanceId = 1
local nextCompanionInstanceId = 1000 

local function AddStatusEffect(tbl, id, dur, mag, type) if not tbl or not id or not dur or not mag or not type then return end; local existing=nil; for _,e in ipairs(tbl) do if e.id==id then existing=e; break end end; if existing then existing.duration=math.max(existing.duration, dur); existing.magnitude=mag else table.insert(tbl,{id=id,duration=dur,magnitude=mag,type=type}) end end
local function RemoveStatusEffect(tbl, id) if not tbl or not id then return end; for i=#tbl,1,-1 do if tbl[i].id==id then table.remove(tbl,i); return end end end
local function GetStatusEffectValue(tbl, id) local total=0; if tbl then for _,e in ipairs(tbl) do if e.id==id then total=total+e.magnitude end end end; return total end
local function sendCombatLog(p, msg) if combatLogEvent then combatLogEvent:FireClient(p, msg) else warn("CombatLogEvent ����!") end end

local function createCombatState(player, enemyIds)
	if not EnemyDatabase or not EnemyDatabase.Enemies then warn("EnemyDatabase �ε� ����!"); return nil end
	if not CompanionDatabase or not CompanionDatabase.Companions then warn("CompanionDatabase �ε� ����!"); return nil end

	if typeof(enemyIds)~='table' then enemyIds={enemyIds} end
	local enemies={}; local validEnemies=false
	for _,id in ipairs(enemyIds) do
		local tmpl=EnemyDatabase.Enemies[id]
		if not tmpl then warn("�˼����� EnemyID:",id)
		else
			local data={}; for k,v in pairs(tmpl) do data[k]=v end
			data.CurrentHP=tmpl.MaxHP
			data.statusEffects={}
			data.instanceId=nextEnemyInstanceId
			nextEnemyInstanceId=nextEnemyInstanceId+1
			table.insert(enemies,data)
			validEnemies=true
			print("�� �ν��Ͻ� �߰�:",data.instanceId, data.Name)
		end
	end
	if not validEnemies then warn("��ȿ�� �� ����"); return nil end

	local pData = PlayerData.GetSessionData(player)
	local partyData = pData and pData.CurrentParty or {}
	local combatCompanions = {}

	for slotNum = 1, 2 do
		local companionDbId = partyData["Slot" .. slotNum]
		if companionDbId then
			local ownedCompanionData = pData.OwnedCompanions and pData.OwnedCompanions[companionDbId]
			local staticCompanionInfo = CompanionDatabase.GetCompanionInfo(companionDbId)

			if ownedCompanionData and staticCompanionInfo then
				print(string.format("CombatManager: Adding companion %s (DbID: %s) from Slot%d to combat.", staticCompanionInfo.Name, companionDbId, slotNum))

				local defaultMaxHP = (staticCompanionInfo.BaseStats and staticCompanionInfo.BaseStats.MaxHP) or 100
				local defaultCurrentHP = (ownedCompanionData.Stats and ownedCompanionData.Stats.CurrentHP) or defaultMaxHP
				local defaultMaxMP = (staticCompanionInfo.BaseStats and staticCompanionInfo.BaseStats.MaxMP) or 10
				local defaultCurrentMP = (ownedCompanionData.Stats and ownedCompanionData.Stats.CurrentMP) or defaultMaxMP
				local defaultAttack = (staticCompanionInfo.BaseStats and staticCompanionInfo.BaseStats.STR) or 5
				local defaultDefense = (staticCompanionInfo.BaseStats and staticCompanionInfo.BaseStats.AGI) or 2
				local defaultCurrentTP = (ownedCompanionData.Stats and ownedCompanionData.Stats.CurrentTP) or 0 
				local defaultMaxTP = (ownedCompanionData.Stats and ownedCompanionData.Stats.MaxTP) or 100 

				local companionCombatInstance = {
					companionDbId = companionDbId,
					instanceId = nextCompanionInstanceId,
					Name = staticCompanionInfo.Name,
					Level = ownedCompanionData.Level or 1,
					MaxHP = (ownedCompanionData.Stats and ownedCompanionData.Stats.MaxHP) or defaultMaxHP, 
					CurrentHP = defaultCurrentHP,
					MaxMP = (ownedCompanionData.Stats and ownedCompanionData.Stats.MaxMP) or defaultMaxMP,
					CurrentMP = defaultCurrentMP,
					MaxTP = defaultMaxTP,     
					CurrentTP = defaultCurrentTP, 
					Attack = (ownedCompanionData.Stats and ownedCompanionData.Stats.STR) or defaultAttack, 
					Defense = (ownedCompanionData.Stats and ownedCompanionData.Stats.AGI) or defaultDefense, 
					Skills = table.clone(ownedCompanionData.Skills or {}), 
					statusEffects = {}, 
					AppearanceId = staticCompanionInfo.AppearanceId,
					Role = staticCompanionInfo.Role
				}
				nextCompanionInstanceId = nextCompanionInstanceId + 1
				table.insert(combatCompanions, companionCombatInstance)
				print(string.format("���� ���� �ν��Ͻ� �߰� (Slot%d): ID=%d, �̸�=%s, HP=%d/%d, MP=%d/%d, TP=%d/%d", 
					slotNum, companionCombatInstance.instanceId, companionCombatInstance.Name, 
					companionCombatInstance.CurrentHP, companionCombatInstance.MaxHP, 
					companionCombatInstance.CurrentMP, companionCombatInstance.MaxMP,
					companionCombatInstance.CurrentTP, companionCombatInstance.MaxTP))
			else
				warn(string.format("CombatManager: Slot%d�� �ִ� ����(ID: %s)�� ������ ã�� �� �����ϴ�. OwnedData: %s, StaticInfo: %s", 
					slotNum, tostring(companionDbId), tostring(ownedCompanionData), tostring(staticCompanionInfo)))
			end
		end
	end

	local state={player=player, enemies=enemies, companions=combatCompanions, isPlayerTurn=true, combatEnded=false, turnNumber=1, playerStatusEffects={}, currentTargetInstanceId=enemies[1].instanceId}
	return state
end

local function ApplyTurnStartEffects(combatState)
	local p=combatState.player
	local pFX=combatState.playerStatusEffects
	local enemies=combatState.enemies
	local companions = combatState.companions 

	local uiUpdate={playerStatus={effects={}},enemiesStatus={}, companionsStatus={}} 
	local pDied=false
	local allEDied=true
	local allCDied=true 

	-- Player effects
	local playerCurrentStatsForTurnStart = PlayerData.GetStats(p) 
	for i=#pFX,1,-1 do 
		local e=pFX[i]
		if e.id=="Poison" or e.id=="Burn" then 
			local dot=e.magnitude
			local newHP=math.max(0,playerCurrentStatsForTurnStart.CurrentHP-dot)
			PlayerData.UpdateStat(p,"CurrentHP",newHP)
			sendCombatLog(p,string.format("<font color='#FF8888'>%s</font> ȿ��! <font color='#FF5555'>%d</font> ����!",e.id,dot))
			if combatDamageEvent then combatDamageEvent:FireClient(p,"Player",dot,false) end
			if newHP<=0 then pDied=true end
			playerCurrentStatsForTurnStart.CurrentHP = newHP 
		elseif e.id=="Regen" then 
			local heal=e.magnitude
			local newHP=math.min(playerCurrentStatsForTurnStart.MaxHP,playerCurrentStatsForTurnStart.CurrentHP+heal)
			PlayerData.UpdateStat(p,"CurrentHP",newHP)
			sendCombatLog(p,string.format("<font color='#90EE90'>%s</font> ȿ��! HP <font color='#90EE90'>%d</font> ȸ��!",e.id,heal))
			if combatDamageEvent then combatDamageEvent:FireClient(p,"Player",heal,true) end
			playerCurrentStatsForTurnStart.CurrentHP = newHP 
		end
		e.duration=e.duration-1
		if e.duration<=0 then sendCombatLog(p,string.format("�÷��̾� <font color='#CCCCCC'>%s</font> ȿ�� �����.",e.id)); table.remove(pFX,i) end 
	end
	if pDied then CombatManager.EndCombat(p,"lose"); return true end

	-- Enemy effects
	for idx=#enemies,1,-1 do 
		local enemy=enemies[idx]
		if enemy.CurrentHP>0 then 
			allEDied=false
			local eFX=enemy.statusEffects
			local diedInLoop=false
			for i=#eFX,1,-1 do 
				local e=eFX[i]
				if e.id=="Poison" or e.id=="Burn" then 
					local dot=e.magnitude
					enemy.CurrentHP=math.max(0,enemy.CurrentHP-dot)
					sendCombatLog(p,string.format("%s <font color='#FF8888'>%s</font> ȿ��! <font color='#FFFF88'>%d</font> ����!",enemy.Name,e.id,dot))
					if combatDamageEvent then combatDamageEvent:FireClient(p,"Enemy",dot,false,enemy.instanceId) end
					if enemy.CurrentHP<=0 then diedInLoop=true end 
				elseif e.id=="Regen" then 
					local heal=e.magnitude
					enemy.CurrentHP=math.min(enemy.MaxHP,enemy.CurrentHP+heal)
					sendCombatLog(p,string.format("%s <font color='#90EE90'>%s</font> ȿ��! HP <font color='#90EE90'>%d</font> ȸ��!",enemy.Name,e.id,heal))
					if combatDamageEvent then combatDamageEvent:FireClient(p,"Enemy",heal,true,enemy.instanceId) end 
				end
				e.duration=e.duration-1
				if e.duration<=0 then sendCombatLog(p,string.format("%s <font color='#CCCCCC'>%s</font> ȿ�� �����.",enemy.Name,e.id)); table.remove(eFX,i) end 
			end
			local fxCopy={}; for _,ef in ipairs(eFX) do table.insert(fxCopy,{id=ef.id,duration=ef.duration}) end
			uiUpdate.enemiesStatus[enemy.instanceId]={hp=enemy.CurrentHP,maxHp=enemy.MaxHP,effects=fxCopy, instanceId=enemy.instanceId, enemyId=enemy.ID, name=enemy.Name, imageId=enemy.ImageId}
			if diedInLoop then sendCombatLog(p,string.format("<font color='#FF5555'>%s</font> ������!",enemy.Name)) end 
		end 
	end
	allEDied=true; for _,e in ipairs(enemies) do if e.CurrentHP>0 then allEDied=false; break end end
	if allEDied then CombatManager.EndCombat(p,"win"); return true end

	-- Companion effects
	if companions then
		for _, comp in ipairs(companions) do
			if comp.CurrentHP > 0 then
				allCDied = false 
				local cFX = comp.statusEffects or {} 
				local compDiedInLoop = false
				for i = #cFX, 1, -1 do
					local e = cFX[i]
					e.duration = e.duration - 1
					if e.duration <= 0 then
						sendCombatLog(p, string.format("%s <font color='#CCCCCC'>%s</font> ȿ�� �����.", comp.Name, e.id))
						table.remove(cFX, i)
					end
				end
				local fxCopy = {}; for _, ef in ipairs(cFX) do table.insert(fxCopy, { id = ef.id, duration = ef.duration }) end
				uiUpdate.companionsStatus[comp.instanceId] = { 
					hp = comp.CurrentHP, maxHp = comp.MaxHP, 
					mp = comp.CurrentMP, maxMp = comp.MaxMP, 
					tp = comp.CurrentTP or 0, 
					effects = fxCopy, 
					instanceId = comp.instanceId, companionDbId = comp.companionDbId, 
					name = comp.Name, appearanceId = comp.AppearanceId, level = comp.Level, role = comp.Role
				}
				if compDiedInLoop then sendCombatLog(p, string.format("<font color='#FF5555'>%s</font> ������!", comp.Name)) end
			end
		end
	end
	local allPlayerSideDied = pDied
	if not pDied and companions and #companions > 0 and allCDied then 
		allPlayerSideDied = true
	elseif not pDied and (not companions or #companions == 0) then 
		allPlayerSideDied = pDied
	end

	if allPlayerSideDied and not allEDied then 
		CombatManager.EndCombat(p,"lose")
		return true
	end

	local pfxCopy={}; for _,e in ipairs(pFX) do table.insert(pfxCopy,{id=e.id,duration=e.duration}) end
	local latestPlayerStats = PlayerData.GetStats(p)
	uiUpdate.playerStatus = {
		name = latestPlayerStats.Name,
		hp = latestPlayerStats.CurrentHP,
		maxHp = latestPlayerStats.MaxHP,
		mp = latestPlayerStats.CurrentMP,
		maxMp = latestPlayerStats.MaxMP,
		tp = latestPlayerStats.CurrentTP or 0,
		effects = pfxCopy
	}
	if updateCombatUIEvent then updateCombatUIEvent:FireClient(p,uiUpdate) end
	return false
end

function CombatManager.StartNewCombat(player, enemyIdOrIds)
	if activeCombats[player] then return end
	local ids=enemyIdOrIds; if typeof(ids)~='table' then ids={ids} end
	local state=createCombatState(player,ids)
	if not state then return end
	activeCombats[player]=state
	print("���� ����! Player:",player.Name)
	sendCombatLog(player,state.enemies[1].Name.." �׷�� ���� ����!")

	local clientEnemies={}; 
	for _,e in ipairs(state.enemies) do 
		local enemyEffectsCopy = {}
		if e.statusEffects then
			for _, effect in ipairs(e.statusEffects) do
				table.insert(enemyEffectsCopy, {id = effect.id, duration = effect.duration}) 
			end
		end
		table.insert(clientEnemies,{
			instanceId=e.instanceId, enemyId=e.ID, name=e.Name, level=e.Level,
			maxHp=e.MaxHP, currentHp=e.CurrentHP, 
			imageId=e.ImageId, statusEffects=enemyEffectsCopy 
		}) 
	end

	local clientCompanions = {}
	if state.companions then
		for _, c in ipairs(state.companions) do 
			local effectsCopy = {}
			if c.statusEffects then
				for _, effect in ipairs(c.statusEffects) do
					table.insert(effectsCopy, {id = effect.id, duration = effect.duration})
				end
			end
			table.insert(clientCompanions, {
				instanceId = c.instanceId, companionDbId = c.companionDbId, name = c.Name, level = c.Level,
				maxHp = c.MaxHP, 
				hp = c.CurrentHP, 
				maxMp = c.MaxMP, 
				mp = c.CurrentMP, 
				tp = c.CurrentTP or 0, 
				appearanceId = c.AppearanceId, statusEffects = effectsCopy, role = c.Role
			})
		end
	end

	local initialPlayerStats = PlayerData.GetStats(player)
	local playerStatusEffectsCopy = {}
	if state.playerStatusEffects then
		for _, effect in ipairs(state.playerStatusEffects) do
			table.insert(playerStatusEffectsCopy, {id = effect.id, duration = effect.duration})
		end
	end

	local uiData={
		playerStatus = { 
			name = initialPlayerStats.Name,
			hp = initialPlayerStats.CurrentHP,
			maxHp = initialPlayerStats.MaxHP,
			mp = initialPlayerStats.CurrentMP,
			maxMp = initialPlayerStats.MaxMP,
			tp = initialPlayerStats.CurrentTP or 0,
			effects = playerStatusEffectsCopy
		},
		companionsStatus = clientCompanions,
	} 
	print("CombatManager.StartNewCombat: Sending initial uiData to client:", HttpService:JSONEncode(uiData))
	if combatStartedEvent then combatStartedEvent:FireClient(player, clientEnemies, uiData) end
	CombatManager.StartPlayerTurn(player)
end

function CombatManager.EndCombat(player, result)
	local state=activeCombats[player]; if not state or state.combatEnded then return end
	state.combatEnded=true; print("���� ����! Result:",result)
	RemoveStatusEffect(state.playerStatusEffects,"Defending")
	local rewards={gold=0,exp=0}; local drops={}; local dropped=false
	if result=="win" then
		local gold,exp=0,0
		for _,e in ipairs(state.enemies) do gold=gold+(e.GoldReward or 0); exp=exp+(e.ExpReward or 0); if e.Drops then for _,d in ipairs(e.Drops) do if d.ItemID and d.Chance then if math.random()<=d.Chance then local qty=d.Quantity or 1; if InventoryManager and InventoryManager.AddItem then local ok,msg=InventoryManager.AddItem(player,d.ItemID,qty); if ok then dropped=true; table.insert(drops,{itemId=d.ItemID,quantity=qty}); local iInfo=ItemDatabase.Items[d.ItemID]; local iName=iInfo and iInfo.Name or ("Item #"..d.ItemID); sendCombatLog(player,string.format("<font color='#90EE90'>%s</font>(x%d) ȹ��!",iName,qty)) end end end end end end end
		rewards.gold=gold; rewards.exp=exp
		local stats=PlayerData.GetStats(player)
		if stats then PlayerData.UpdateStat(player,"Gold",stats.Gold+rewards.gold) end
		PlayerData.AddExp(player,rewards.exp)
		sendCombatLog(player,"�¸�! G+"..rewards.gold..", Exp+"..rewards.exp)

	elseif result=="lose" then sendCombatLog(player,"�й�...")
	elseif result=="flee" then sendCombatLog(player,"����ħ.") end
	if combatEndedEvent then combatEndedEvent:FireClient(player,result,rewards,drops) end
	if dropped then if inventoryUpdatedEvent then inventoryUpdatedEvent:FireClient(player) end end
	if combatEndedClientEvent then combatEndedClientEvent:FireClient(player) end

	if state.companions then
		local pData = PlayerData.GetSessionData(player)
		if pData and pData.OwnedCompanions then
			for _, combatComp in ipairs(state.companions) do
				local ownedComp = pData.OwnedCompanions[combatComp.companionDbId]
				if ownedComp and ownedComp.Stats then
					ownedComp.Stats.CurrentHP = combatComp.CurrentHP
					ownedComp.Stats.CurrentMP = combatComp.CurrentMP
					print(string.format("CombatManager: Saving companion %s's HP: %d, MP: %d after combat.", combatComp.Name, combatComp.CurrentHP, combatComp.CurrentMP))
				end
			end
		end
	end
	activeCombats[player]=nil
	print("���� ���� ����:", player.Name)
end

function CombatManager.StartPlayerTurn(player)
	local state=activeCombats[player]; if not state or state.combatEnded or not state.isPlayerTurn then return end
	print("Player Turn:",player.Name,"Turn",state.turnNumber)
	sendCombatLog(player,"�� �÷��̾� ��")
	RemoveStatusEffect(state.playerStatusEffects,"Defending")
	local endCombat=ApplyTurnStartEffects(state); if endCombat then return end

	local enemiesStatus={}; 
	for _,e in ipairs(state.enemies) do 
		local eEffects = {}
		if e.statusEffects then for _,fx in ipairs(e.statusEffects) do table.insert(eEffects,{id=fx.id,duration=fx.duration}) end end
		enemiesStatus[e.instanceId]={instanceId=e.instanceId, enemyId=e.ID, name=e.Name, imageId=e.ImageId, hp=e.CurrentHP,maxHp=e.MaxHP,effects=eEffects}
	end
	local companionsStatus = {}
	if state.companions then
		for _, c in ipairs(state.companions) do
			local cEffects = {}
			if c.statusEffects then for _,fx in ipairs(c.statusEffects) do table.insert(cEffects,{id=fx.id,duration=fx.duration}) end end
			companionsStatus[c.instanceId] = {
				instanceId = c.instanceId, companionDbId = c.companionDbId, name = c.Name, level = c.Level,
				hp = c.CurrentHP, maxHp = c.MaxHP, mp = c.CurrentMP, maxMp = c.MaxMP,
				tp = c.CurrentTP or 0,
				appearanceId = c.AppearanceId, effects = cEffects, role = c.Role
			}
		end
	end

	local playerCurrentStats = PlayerData.GetStats(player)
	local playerStatusForClient = {
		name = playerCurrentStats.Name,
		hp = playerCurrentStats.CurrentHP,
		maxHp = playerCurrentStats.MaxHP,
		mp = playerCurrentStats.CurrentMP,
		maxMp = playerCurrentStats.MaxMP,
		tp = playerCurrentStats.CurrentTP or 0,
		effects = {}
	}
	if state.playerStatusEffects then for _,fx in ipairs(state.playerStatusEffects) do table.insert(playerStatusForClient.effects,{id=fx.id,duration=fx.duration}) end end

	local payload = {playerStatus=playerStatusForClient, enemiesStatus=enemiesStatus, companionsStatus=companionsStatus}
	print("CombatManager.StartPlayerTurn: Sending payload:", HttpService:JSONEncode(payload))
	if playerTurnEvent then playerTurnEvent:FireClient(player, payload) end
end

local function ExecuteCompanionTurn(player)
	local combatState = activeCombats[player]
	if not combatState or combatState.combatEnded or combatState.isPlayerTurn then return false end 

	if not combatState.companions or #combatState.companions == 0 then
		print("CombatManager: No companions in party to execute turn.")
		return false 
	end

	local companionDidAction = false
	for _, comp in ipairs(combatState.companions) do
		if combatState.combatEnded then break end 
		if comp.CurrentHP > 0 then
			companionDidAction = true
			task.wait(0.5) 
			sendCombatLog(player, string.format("- %s�� �� -", comp.Name))

			local livingEnemies = {}
			for _, enemy in ipairs(combatState.enemies) do
				if enemy.CurrentHP > 0 then table.insert(livingEnemies, enemy) end
			end

			if #livingEnemies == 0 then
				print(string.format("CombatManager: %s's turn, but no living enemies.", comp.Name))
				continue 
			end

			local targetEnemy = livingEnemies[math.random(#livingEnemies)] 
			if not targetEnemy then
				warn(string.format("CombatManager: %s failed to select a random target.", comp.Name))
				continue
			end
			sendCombatLog(player, string.format("%s��(��) %s��(��) ����!", comp.Name, targetEnemy.Name))

			local compAttack = comp.Attack or 1 
			local enemyDefense = targetEnemy.DEF or 0
			local damage = math.max(1, compAttack - enemyDefense)

			sendCombatLog(player, string.format("%s���� <font color='#FFD700'>%d</font>�� ������!", targetEnemy.Name, damage))
			if combatDamageEvent then combatDamageEvent:FireClient(player, "Enemy", damage, false, targetEnemy.instanceId) end
			targetEnemy.CurrentHP = math.max(0, targetEnemy.CurrentHP - damage)

			local finalEnemyEffectsCopy={}; if targetEnemy.statusEffects then for _,eff in ipairs(targetEnemy.statusEffects) do table.insert(finalEnemyEffectsCopy,{id=eff.id,duration=eff.duration}) end end
			local uiUpdateData = {
				enemiesStatus = {
					[targetEnemy.instanceId] = { hp = targetEnemy.CurrentHP, maxHp = targetEnemy.MaxHP, effects = finalEnemyEffectsCopy, instanceId=targetEnemy.instanceId, enemyId=targetEnemy.ID, name=targetEnemy.Name, imageId=targetEnemy.ImageId }
				}
			}
			if updateCombatUIEvent then updateCombatUIEvent:FireClient(player, uiUpdateData) end

			if targetEnemy.CurrentHP <= 0 then
				sendCombatLog(player, string.format("<font color='#FF5555'>%s</font> ������!", targetEnemy.Name))
				local allEnemiesDied = true
				for _, e in ipairs(combatState.enemies) do if e.CurrentHP > 0 then allEnemiesDied = false; break end end
				if allEnemiesDied then
					CombatManager.EndCombat(player, "win")
					return true 
				end
			end
		end
	end
	return companionDidAction 
end

function CombatManager.StartEnemyTurn(player)
	local combatState = activeCombats[player]
	if not combatState or combatState.combatEnded or combatState.isPlayerTurn then return end

	print("CombatManager: Enemy Turn Started (Turn", combatState.turnNumber, ")")
	sendCombatLog(player, "�� �� ��")

	local combatShouldEnd = ApplyTurnStartEffects(combatState)
	if combatShouldEnd then return end

	local enemiesStatusData = {}; 
	for _, enemyData_iter in ipairs(combatState.enemies) do 
		local eEffects = {}
		if enemyData_iter.statusEffects then for _, eff in ipairs(enemyData_iter.statusEffects) do table.insert(eEffects, {id=eff.id, duration=eff.duration}) end end
		enemiesStatusData[enemyData_iter.instanceId] = {instanceId=enemyData_iter.instanceId, enemyId=enemyData_iter.ID, name=enemyData_iter.Name, imageId=enemyData_iter.ImageId, hp = enemyData_iter.CurrentHP, maxHp = enemyData_iter.MaxHP, effects = eEffects}
	end
	local companionsStatusData = {}
	if combatState.companions then
		for _, cData in ipairs(combatState.companions) do
			local cEffects = {}
			if cData.statusEffects then for _,eff in ipairs(cData.statusEffects) do table.insert(cEffects,{id=eff.id,duration=eff.duration}) end end
			companionsStatusData[cData.instanceId] = {
				instanceId = cData.instanceId, companionDbId = cData.companionDbId, name = cData.Name, level = cData.Level,
				hp = cData.CurrentHP, maxHp = cData.MaxHP, mp = cData.CurrentMP, maxMp = cData.MaxMP,
				tp = cData.CurrentTP or 0, 
				appearanceId = cData.AppearanceId, effects = cEffects, role = cData.Role
			}
		end
	end

	local playerCurrentStats_enemyTurn = PlayerData.GetStats(player)
	local playerStatusForClient_enemyTurn = {
		name = playerCurrentStats_enemyTurn.Name, hp = playerCurrentStats_enemyTurn.CurrentHP, maxHp = playerCurrentStats_enemyTurn.MaxHP,
		mp = playerCurrentStats_enemyTurn.CurrentMP, maxMp = playerCurrentStats_enemyTurn.MaxMP, tp = playerCurrentStats_enemyTurn.CurrentTP or 0,
		effects = {}
	}
	if combatState.playerStatusEffects then for _,fx in ipairs(combatState.playerStatusEffects) do table.insert(playerStatusForClient_enemyTurn.effects,{id=fx.id,duration=fx.duration}) end end

	local payload_enemyTurn = {playerStatus = playerStatusForClient_enemyTurn, enemiesStatus = enemiesStatusData, companionsStatus = companionsStatusData}
	print("CombatManager.StartEnemyTurn: Sending payload:", HttpService:JSONEncode(payload_enemyTurn))
	if enemyTurnEvent then enemyTurnEvent:FireClient(player, payload_enemyTurn) else warn("CombatManager: enemyTurnEvent not found!") end

	for _, enemyData in ipairs(combatState.enemies) do
		if combatState.combatEnded then break end
		if enemyData.CurrentHP > 0 then
			task.wait(1)
			sendCombatLog(player, "- " .. enemyData.Name .. "�� �ൿ -")

			local possibleTargets = {}
			local playerStats = PlayerData.GetStats(player) 
			if playerStats and (playerStats.CurrentHP or 0) > 0 then
				table.insert(possibleTargets, {type = "Player", data = player, name = player.Name, currentHP = playerStats.CurrentHP})
			end
			if combatState.companions then
				for _, comp in ipairs(combatState.companions) do
					if comp.CurrentHP > 0 then
						table.insert(possibleTargets, {type = "Companion", data = comp, name = comp.Name, currentHP = comp.CurrentHP, instanceId = comp.instanceId})
					end
				end
			end

			if #possibleTargets == 0 then 
				print("CombatManager: No valid targets for enemy", enemyData.Name)
				continue
			end

			local targetInfo = possibleTargets[math.random(#possibleTargets)] 
			local targetName = targetInfo.name
			local targetCurrentHP = targetInfo.currentHP
			local targetType = targetInfo.type
			local targetInstanceId = targetInfo.instanceId 

			sendCombatLog(player, string.format("%s��(��) %s��(��) ����!", enemyData.Name, targetName))

			local enemyAccuracy = 90 
			local targetEvasionRate = 0
			if targetType == "Player" then
				targetEvasionRate = playerStats.EvasionRate or 0
			elseif targetType == "Companion" then
				local compDataForEvasion = nil
				for _, c in ipairs(combatState.companions) do
					if c.instanceId == targetInstanceId then
						compDataForEvasion = c
						break
					end
				end
				if compDataForEvasion and compDataForEvasion.Stats and compDataForEvasion.Stats.AGI then
					targetEvasionRate = (compDataForEvasion.Stats.AGI * 0.1) 
				else  
					targetEvasionRate = 0
				end
			end

			local hitChance = math.clamp(((enemyAccuracy) - targetEvasionRate) / 100, 0.01, 1.0)
			local hitRoll = math.random()

			print(string.format("Enemy Turn: %s attacks %s. HitChance=%.2f (EnemyAcc:%d - TargetEva:%.2f), Roll=%.2f",
				enemyData.Name, targetName, hitChance * 100, enemyAccuracy, targetEvasionRate, hitRoll * 100))

			if hitRoll > hitChance then
				sendCombatLog(player, string.format("%s�� ����! ������ <font color='#88FFFF'>%s</font>��(��) ȸ���ߴ�!", enemyData.Name, targetName))
			else
				local enemyBaseAttack = enemyData.Attack or 0
				local enemyBuffAttack = GetStatusEffectValue(enemyData.statusEffects, "AttackUp")
				local enemyDebuffAttack = GetStatusEffectValue(enemyData.statusEffects, "AttackDown")
				local enemyAttack = enemyBaseAttack + enemyBuffAttack + enemyDebuffAttack

				local targetDefense = 0
				local targetStatusEffects = {}
				if targetType == "Player" then
					targetDefense = (playerStats.Defense or 0)
					targetStatusEffects = combatState.playerStatusEffects
				elseif targetType == "Companion" then
					targetDefense = (targetInfo.data.Defense or 0) 
					targetStatusEffects = targetInfo.data.statusEffects or {}
				end
				local targetBuffDefense = GetStatusEffectValue(targetStatusEffects, "Busoshoku") + GetStatusEffectValue(targetStatusEffects, "Defending")
				local targetDebuffDefense = GetStatusEffectValue(targetStatusEffects, "DefenseDown")
				local finalTargetDefense = targetDefense + targetBuffDefense + targetDebuffDefense

				local enemyCritChance = 5
				local enemyCritDamagePercent = 150
				local isCrit = (math.random() <= (enemyCritChance / 100))
				local rawDamage = math.max(1, enemyAttack - finalTargetDefense)
				local finalDamage = isCrit and math.floor(rawDamage * (enemyCritDamagePercent / 100)) or rawDamage

				if isCrit then
					sendCombatLog(player, string.format("<font color='#FF5555'>ġ��Ÿ!</font> %s�� ����! %s���� <font color='#FF0000'>%d</font>�� ������!", enemyData.Name, targetName, finalDamage))
				else
					sendCombatLog(player, string.format("%s�� ����! %s���� <font color='#FF5555'>%d</font>�� ������!", enemyData.Name, targetName, finalDamage))
				end

				if combatDamageEvent then combatDamageEvent:FireClient(player, targetType, finalDamage, false, targetInstanceId) end

				local newTargetHP = targetCurrentHP - finalDamage
				if targetType == "Player" then
					PlayerData.UpdateStat(player, "CurrentHP", newTargetHP)
					if newTargetHP <= 0 then CombatManager.EndCombat(player, "lose"); return end
				elseif targetType == "Companion" then
					targetInfo.data.CurrentHP = math.max(0, newTargetHP) 
					if newTargetHP <= 0 then
						sendCombatLog(player, string.format("<font color='#FF5555'>%s</font> ������!", targetName))
						local allPlayerSideDead = true
						if (playerStats.CurrentHP or 0) > 0 then allPlayerSideDead = false end
						if not allPlayerSideDead and combatState.companions then
							local anyCompanionAlive = false
							for _, c in ipairs(combatState.companions) do if c.CurrentHP > 0 then anyCompanionAlive = true; break end end
							if anyCompanionAlive then allPlayerSideDead = false end
						end
						if allPlayerSideDead then CombatManager.EndCombat(player, "lose"); return end
					end
				end
			end
		end
	end

	if combatState.combatEnded then return end
	task.wait(0.1)
	combatState.turnNumber = combatState.turnNumber + 1 
	combatState.isPlayerTurn = true
	CombatManager.StartPlayerTurn(player)
end

function CombatManager.PlayerAttack(player, targetInstanceId)
	local combatState = activeCombats[player]; if not combatState or combatState.combatEnded or not combatState.isPlayerTurn then return end
	local targetEnemyData = nil; for _, enemy in ipairs(combatState.enemies) do if enemy.instanceId == targetInstanceId then targetEnemyData = enemy; break end end
	if not targetEnemyData then warn("PlayerAttack: Invalid targetId:", targetInstanceId); CombatManager.StartPlayerTurn(player); return end 
	if targetEnemyData.CurrentHP <= 0 then sendCombatLog(player, targetEnemyData.Name .. "��(��) �̹� ������."); CombatManager.StartPlayerTurn(player); return end
	print("Player Attack:", player.Name, "Target:", targetEnemyData.instanceId)

	local playerStats = PlayerData.GetStats(player); local playerSession = PlayerData.GetSessionData(player); if not playerStats or not playerSession then warn("PlayerAttack: ����/���� ���� ����"); CombatManager.StartPlayerTurn(player); return end
	local playerAccuracyRate = playerStats.AccuracyRate or 50; local enemyEvasionRate = targetEnemyData.EvasionRate or 5; local hitChance = math.clamp(((playerAccuracyRate) - enemyEvasionRate) / 100, 0.01, 1.0); local hitRoll = math.random()
	print(string.format("Player Attack Hit Calc: HitChance=%.2f (PlayerAcc:%.2f - EnemyEva:%.2f), Roll=%.2f", hitChance * 100, playerAccuracyRate, enemyEvasionRate, hitRoll * 100))

	if hitRoll > hitChance then
		sendCombatLog(player, string.format("�÷��̾��� ����! ������ %s��(��) ȸ���ߴ�!", targetEnemyData.Name))
	else
		local weaponId = playerSession.Equipped and playerSession.Equipped.Weapon and playerSession.Equipped.Weapon.itemId or nil 
		local weaponInfo = weaponId and ItemDatabase.Items[weaponId] or nil; local weaponType = weaponInfo and weaponInfo.WeaponType or "Fist"
		local baseAttackPower = 0; if weaponType == "Sword" or weaponType == "Fist" then baseAttackPower = playerStats.MeleeAttack or 10 elseif weaponType == "Gun" then baseAttackPower = playerStats.RangedAttack or 10 else baseAttackPower = playerStats.MeleeAttack or 10 end
		local playerBuffAttack = GetStatusEffectValue(combatState.playerStatusEffects, "AttackUp"); local playerDebuffAttack = GetStatusEffectValue(combatState.playerStatusEffects, "AttackDown"); local finalPlayerAttack = baseAttackPower + playerBuffAttack + playerDebuffAttack
		local enemyDefense = (targetEnemyData.DEF or 0) + GetStatusEffectValue(targetEnemyData.statusEffects, "DefenseUp") + GetStatusEffectValue(targetEnemyData.statusEffects, "DefenseDown"); local rawDamage = math.max(1, finalPlayerAttack - enemyDefense)
		local playerCritChance = playerStats.CritChance or 0; local playerCritDamagePercent = playerStats.CritDamage or 150; local isCrit = (math.random() <= (playerCritChance / 100)); local finalDamage = isCrit and math.floor(rawDamage * (playerCritDamagePercent / 100)) or rawDamage
		if isCrit then sendCombatLog(player, string.format("<font color='#FFFF00'>ũ��Ƽ��!</font> �÷��̾��� ����! %s���� <font color='#FFFF88'>%d</font>�� ������!", targetEnemyData.Name, finalDamage)) else sendCombatLog(player, string.format("�÷��̾��� ����! %s���� <font color='#FFFF88'>%d</font>�� ������!", targetEnemyData.Name, finalDamage)) end
		if combatDamageEvent then combatDamageEvent:FireClient(player, "Enemy", finalDamage, false, targetInstanceId) end
		targetEnemyData.CurrentHP = math.max(0, targetEnemyData.CurrentHP - finalDamage)
		local finalEnemyEffectsCopy={}; if targetEnemyData.statusEffects then for _, eff in ipairs(targetEnemyData.statusEffects) do table.insert(finalEnemyEffectsCopy,{id=eff.id,duration=eff.duration}) end end
		local uiUpdateData = {enemiesStatus = {[targetInstanceId] = {hp = targetEnemyData.CurrentHP, maxHp = targetEnemyData.MaxHP, effects = finalEnemyEffectsCopy, instanceId=targetEnemyData.instanceId, enemyId=targetEnemyData.ID, name=targetEnemyData.Name, imageId=targetEnemyData.ImageId}}}; if updateCombatUIEvent then updateCombatUIEvent:FireClient(player, uiUpdateData) end
		if targetEnemyData.CurrentHP <= 0 then sendCombatLog(player,string.format("<font color='#FF5555'>%s</font> ������!",targetEnemyData.Name)) end
		local allEnemiesDied = true; for _, enemy in ipairs(combatState.enemies) do if enemy.CurrentHP > 0 then allEnemiesDied = false; break end end
		if allEnemiesDied then CombatManager.EndCombat(player, "win"); return end
	end

	combatState.isPlayerTurn = false
	local companionActed = ExecuteCompanionTurn(player) 
	if not combatState.combatEnded then 
		CombatManager.StartEnemyTurn(player)
	end
end

function CombatManager.PlayerUseSkill(player, skillId, targetInstanceId)
	local combatState = activeCombats[player]; if not combatState or combatState.combatEnded or not combatState.isPlayerTurn then return end
	local playerStats = PlayerData.GetStats(player); local playerSession = PlayerData.GetSessionData(player); local skillInfo = SkillDatabase.Skills[skillId]; if not playerStats or not playerSession then warn("����/���� ���� ����"); CombatManager.StartPlayerTurn(player); return end; if not skillInfo then warn("��ų ���� ����:", skillId); CombatManager.StartPlayerTurn(player); return end
	local cost = skillInfo.Cost or 0; if playerStats.CurrentMP < cost then sendCombatLog(player, "MP ����!"); CombatManager.StartPlayerTurn(player); return end
	local reqFruit = skillInfo.RequiredFruit; if reqFruit and reqFruit ~= "" then if (playerSession.ActiveDevilFruit or "") ~= reqFruit then sendCombatLog(player,skillInfo.Name.." ��ų�� "..reqFruit.." �ɷ��� ����!"); CombatManager.StartPlayerTurn(player); return end end
	local reqWeapon = skillInfo.RequiredWeaponType; if reqWeapon then local wepId=playerSession.Equipped and playerSession.Equipped.Weapon and playerSession.Equipped.Weapon.itemId or nil; local wepInfo=wepId and ItemDatabase.Items[wepId] or nil; local wepType=wepInfo and wepInfo.WeaponType or nil; if wepType ~= reqWeapon then sendCombatLog(player,skillInfo.Name.." ��ų�� "..reqWeapon.." �迭 ���� �ʿ�!"); CombatManager.StartPlayerTurn(player); return end end
	local mpConsumed = PlayerData.UpdateStat(player, "CurrentMP", playerStats.CurrentMP - cost); if not mpConsumed then warn("MP �Ҹ� ����!"); CombatManager.StartPlayerTurn(player); return end
	local currentPDataForUI = PlayerData.GetStats(player); local pfxCopy={}; if combatState.playerStatusEffects then for _,e in ipairs(combatState.playerStatusEffects) do table.insert(pfxCopy,{id=e.id,duration=e.duration}) end end; if updateCombatUIEvent then updateCombatUIEvent:FireClient(player, { playerStats = currentPDataForUI, playerStatus = {effects=pfxCopy} }) end
	sendCombatLog(player, string.format("%s <font color='#88CCFF'>%s</font> ���! (MP -%d)", player.Name, skillInfo.Name, cost))

	local turnEnded = false; local uiUpdateData = { playerStatus = { effects = {} }, enemiesStatus = {} }; local targetEnemyData = nil;
	if skillInfo.Target == "ENEMY_SINGLE" then if not targetInstanceId then warn("��� �ʿ�"); CombatManager.StartPlayerTurn(player); return end; for _,e in ipairs(combatState.enemies) do if e.instanceId==targetInstanceId then targetEnemyData=e; break end end; if not targetEnemyData then warn("�߸��� ��� ID"); CombatManager.StartPlayerTurn(player); return end; if targetEnemyData.CurrentHP<=0 then sendCombatLog(player,targetEnemyData.Name.."��(��) �̹� ������."); CombatManager.StartPlayerTurn(player); return end end

	if skillInfo.EffectType == "DAMAGE" and skillInfo.Power then
		if not targetEnemyData then warn("DAMAGE ��ų�� ��� �ʿ�"); CombatManager.StartPlayerTurn(player); return end
		local damageType = skillInfo.DamageType or "Physical"; local playerAttackPower = 0; local enemyDefensePower = 0
		if damageType == "Magic" then playerAttackPower = playerStats.MagicAttack or 0; enemyDefensePower = targetEnemyData.MagicDefense or 0
		else local weaponId = playerSession.Equipped and playerSession.Equipped.Weapon and playerSession.Equipped.Weapon.itemId or nil; local weaponInfo = weaponId and ItemDatabase.Items[weaponId] or nil; local weaponType = weaponInfo and weaponInfo.WeaponType or "Fist"; if weaponType == "Gun" then playerAttackPower = playerStats.RangedAttack or 10 else playerAttackPower = playerStats.MeleeAttack or 10 end; enemyDefensePower = targetEnemyData.DEF or 0 end
		local playerAccuracyRate = playerStats.AccuracyRate or 50; local enemyEvasionRate = targetEnemyData.EvasionRate or 5; local hitChance = math.clamp(((playerAccuracyRate) - enemyEvasionRate) / 100, 0.01, 1.0); local hitRoll = math.random()
		if hitRoll > hitChance then sendCombatLog(player, string.format("<font color='#88CCFF'>%s</font> ��ų! ������ %s��(��) ȸ���ߴ�!", skillInfo.Name, targetEnemyData.Name))
		else
			local finalPlayerAttack = playerAttackPower + GetStatusEffectValue(combatState.playerStatusEffects, "AttackUp") + GetStatusEffectValue(combatState.playerStatusEffects, "AttackDown"); local finalEnemyDefense = enemyDefensePower + GetStatusEffectValue(targetEnemyData.statusEffects, "DefenseUp") + GetStatusEffectValue(targetEnemyData.statusEffects, "DefenseDown"); local rawDamage = math.max(1, math.floor(finalPlayerAttack + skillInfo.Power) - finalEnemyDefense)
			local playerCritChance = playerStats.CritChance or 0; local playerCritDamagePercent = playerStats.CritDamage or 150; local isCrit = (math.random() <= (playerCritChance / 100)); local finalDamage = isCrit and math.floor(rawDamage * (playerCritDamagePercent / 100)) or rawDamage
			local damageColor = (damageType == "Magic") and "AAAAFF" or "FFFF88"; if isCrit then sendCombatLog(player, string.format("<font color='#FFFF00'>ũ��Ƽ��!</font> %s���� <font color='#%s'>%d</font>�� %s ������!", targetEnemyData.Name, damageColor, finalDamage, damageType)) else sendCombatLog(player, string.format("%s���� <font color='#%s'>%d</font>�� %s ������!", targetEnemyData.Name, damageColor, finalDamage, damageType)) end
			if combatDamageEvent then combatDamageEvent:FireClient(player, "Enemy", finalDamage, false, targetInstanceId) end
			targetEnemyData.CurrentHP = math.max(0, targetEnemyData.CurrentHP - finalDamage)
			local finalEnemyEffectsCopy={}; if targetEnemyData.statusEffects then for _,e in ipairs(targetEnemyData.statusEffects) do table.insert(finalEnemyEffectsCopy,{id=e.id,duration=e.duration}) end end
			uiUpdateData.enemiesStatus[targetInstanceId] = { hp=targetEnemyData.CurrentHP, maxHp=targetEnemyData.MaxHP, effects=finalEnemyEffectsCopy, instanceId=targetEnemyData.instanceId, enemyId=targetEnemyData.ID, name=targetEnemyData.Name, imageId=targetEnemyData.ImageId }
			if targetEnemyData.CurrentHP <= 0 then sendCombatLog(player,string.format("<font color='#FF5555'>%s</font> ������!",targetEnemyData.Name)) end
			local allDied=true; for _,e in ipairs(combatState.enemies) do if e.CurrentHP>0 then allDied=false; break end end; if allDied then CombatManager.EndCombat(player,"win"); return end
		end; turnEnded=true
	elseif skillInfo.EffectType == "HEAL" and skillInfo.Power then local healAmount = skillInfo.Power; local newPlayerHP = math.min(playerStats.MaxHP, playerStats.CurrentHP + healAmount); PlayerData.UpdateStat(player, "CurrentHP", newPlayerHP); sendCombatLog(player, string.format("HP <font color='#90EE90'>%d</font> ȸ��!", healAmount)); if combatDamageEvent then combatDamageEvent:FireClient(player, "Player", healAmount, true) end; turnEnded = true
	elseif (skillInfo.EffectType == "BUFF" or skillInfo.EffectType == "DEBUFF") and skillInfo.StatusEffect then local effectInfo = skillInfo.StatusEffect; local targetTable = nil; local targetName = ""; local targetIdForUI = nil; if skillInfo.Target == "SELF" then targetTable = combatState.playerStatusEffects; targetName = "�÷��̾�"; targetIdForUI = "Player" elseif skillInfo.Target == "ENEMY_SINGLE" then if not targetEnemyData then warn("BUFF/DEBUFF ��� ����"); CombatManager.StartPlayerTurn(player); return end; targetTable = targetEnemyData.statusEffects; targetName = targetEnemyData.Name; targetIdForUI = targetEnemyData.instanceId end; if targetTable then AddStatusEffect(targetTable, effectInfo.ID, effectInfo.Duration, effectInfo.Magnitude, effectInfo.Type); local color = (effectInfo.Type == "Buff") and "90EE90" or "FF8888"; sendCombatLog(player, string.format("%s���� <font color='#%s'>%s</font> ȿ�� �ο�!", targetName, color, effectInfo.ID)); local pfxCopyB={}; if combatState.playerStatusEffects then for _,e in ipairs(combatState.playerStatusEffects) do table.insert(pfxCopyB,{id=e.id,duration=e.duration}) end end; uiUpdateData.playerStatus.effects = pfxCopyB; if targetIdForUI ~= "Player" and targetEnemyData then local efxCopyB={}; if targetEnemyData.statusEffects then for _,e in ipairs(targetEnemyData.statusEffects) do table.insert(efxCopyB,{id=e.id,duration=e.duration}) end end; uiUpdateData.enemiesStatus[targetIdForUI] = { hp=targetEnemyData.CurrentHP, maxHp=targetEnemyData.MaxHP, effects=efxCopyB, instanceId=targetEnemyData.instanceId, enemyId=targetEnemyData.ID, name=targetEnemyData.Name, imageId=targetEnemyData.ImageId } end end; turnEnded = true
	else sendCombatLog(player, "(�̱��� ��ų)"); turnEnded = true end

	local finalPDataForUI = PlayerData.GetStats(player); local finalPfxCopy={}; if combatState.playerStatusEffects then for _,e in ipairs(combatState.playerStatusEffects) do table.insert(finalPfxCopy,{id=e.id,duration=e.duration}) end end; uiUpdateData.playerStats = finalPDataForUI; uiUpdateData.playerStatus.effects = finalPfxCopy;
	if updateCombatUIEvent then updateCombatUIEvent:FireClient(player, uiUpdateData) end
	if turnEnded then combatState.isPlayerTurn = false; local companionActed = ExecuteCompanionTurn(player); if not combatState.combatEnded then CombatManager.StartEnemyTurn(player) end end
end

function CombatManager.PlayerDefend(player)
	local state=activeCombats[player]; if not state or state.combatEnded or not state.isPlayerTurn then return end
	print("Player Defend:", player.Name); local stats=PlayerData.GetStats(player); local bonus=math.floor((stats.Defense or 0)*0.5); AddStatusEffect(state.playerStatusEffects,"Defending",1,bonus,"Buff"); sendCombatLog(player,"��� �¼�!")
	local pfxCopy={}; if state.playerStatusEffects then for _,e in ipairs(state.playerStatusEffects) do table.insert(pfxCopy,{id=e.id,duration=e.duration}) end end; local uiData={playerStatus={effects=pfxCopy}}; if updateCombatUIEvent then updateCombatUIEvent:FireClient(player,uiData) end
	state.isPlayerTurn=false; local companionActed = ExecuteCompanionTurn(player); if not state.combatEnded then CombatManager.StartEnemyTurn(player) end
end

-- ##### [��� �߰�] PlayerUseItem �Լ� ���� #####
function CombatManager.PlayerUseItem(player, itemId, targetInstanceId)
	local state = activeCombats[player]
	if not state or state.combatEnded or not state.isPlayerTurn then return end

	print("CombatManager PlayerUseItem: Player:", player.Name, "ItemID:", itemId, "TargetInstanceID:", targetInstanceId)
	local itemInfo = ItemDatabase.Items[itemId]
	if not itemInfo then
		sendCombatLog(player, "�� �� ���� �������Դϴ�.")
		CombatManager.StartPlayerTurn(player)
		return
	end
	if itemInfo.Type ~= "Consumable" then
		sendCombatLog(player, itemInfo.Name .. "��(��) ���� �� ����� �� �����ϴ�.")
		CombatManager.StartPlayerTurn(player)
		return
	end

	local removed, removeMsg = InventoryManager.RemoveItem(player, itemId, 1)
	if not removed then
		sendCombatLog(player, itemInfo.Name .. " �������� �����մϴ�. (" .. (removeMsg or "") .. ")")
		CombatManager.StartPlayerTurn(player)
		return
	end
	sendCombatLog(player, string.format("%s ������ ���!", itemInfo.Name))

	local effectApplied = false
	local uiUpdateData = { playerStatus = {}, enemiesStatus = {}, companionsStatus = {} }

	if itemInfo.Effect then
		local effectStat = itemInfo.Effect.Stat
		local effectValue = itemInfo.Effect.Value
		local targetName = ""
		local damageEventTargetType = "" -- "Player" �Ǵ� "Companion"

		-- ��� ����: targetInstanceId�� ������ �ش� ���, ������ �÷��̾� �ڽ�
		local actualTargetIsPlayer = (targetInstanceId == nil or targetInstanceId == player.UserId)

		if actualTargetIsPlayer then
			targetName = player.Name
			damageEventTargetType = "Player"
			local playerStats = PlayerData.GetStats(player)
			if effectStat == "HP" then
				local newHP = math.min(playerStats.MaxHP, playerStats.CurrentHP + effectValue)
				PlayerData.UpdateStat(player, "CurrentHP", newHP)
				effectApplied = true
			elseif effectStat == "MP" then
				local newMP = math.min(playerStats.MaxMP, playerStats.CurrentMP + effectValue)
				PlayerData.UpdateStat(player, "CurrentMP", newMP)
				effectApplied = true
			elseif effectStat == "HPMP" then
				local newHP = math.min(playerStats.MaxHP, playerStats.CurrentHP + effectValue)
				local newMP = math.min(playerStats.MaxMP, playerStats.CurrentMP + effectValue)
				PlayerData.UpdateStat(player, "CurrentHP", newHP)
				PlayerData.UpdateStat(player, "CurrentMP", newMP)
				effectApplied = true
			elseif itemInfo.Effect.Type == "BuffDebuff" then -- �÷��̾� ��� ����/�����
				local buff = itemInfo.Effect.Buff
				local debuff = itemInfo.Effect.Debuff
				if buff then AddStatusEffect(state.playerStatusEffects, buff.Stat, buff.Duration, buff.Value, "Buff") end
				if debuff then AddStatusEffect(state.playerStatusEffects, debuff.Stat, debuff.Duration, debuff.Value, "Debuff") end
				effectApplied = true
			end
			if effectApplied then
				sendCombatLog(player, string.format("%s���� %s ȿ��! (��: %d)", targetName, effectStat, effectValue))
				if combatDamageEvent and (effectStat == "HP" or effectStat == "HPMP") then
					combatDamageEvent:FireClient(player, damageEventTargetType, effectValue, true, player.UserId)
				end
			end
		else -- ����� ������ ���
			local targetCompanion = nil
			if state.companions then
				for _, comp in ipairs(state.companions) do
					if comp.instanceId == targetInstanceId then
						targetCompanion = comp
						break
					end
				end
			end

			if targetCompanion then
				targetName = targetCompanion.Name
				damageEventTargetType = "Companion"
				if effectStat == "HP" then
					targetCompanion.CurrentHP = math.min(targetCompanion.MaxHP, targetCompanion.CurrentHP + effectValue)
					effectApplied = true
				elseif effectStat == "MP" then
					targetCompanion.CurrentMP = math.min(targetCompanion.MaxMP, targetCompanion.CurrentMP + effectValue)
					effectApplied = true
				elseif effectStat == "HPMP" then
					targetCompanion.CurrentHP = math.min(targetCompanion.MaxHP, targetCompanion.CurrentHP + effectValue)
					targetCompanion.CurrentMP = math.min(targetCompanion.MaxMP, targetCompanion.CurrentMP + effectValue)
					effectApplied = true
					-- ���� ��� ����/����� (�ʿ�� StatusEffect �ʵ� Ȯ�� �� AddStatusEffect ȣ��)
					-- elseif itemInfo.Effect.Type == "BuffDebuff" then ... end 
				end
				if effectApplied then
					sendCombatLog(player, string.format("%s���� %s ȿ��! (��: %d)", targetName, effectStat, effectValue))
					if combatDamageEvent and (effectStat == "HP" or effectStat == "HPMP") then
						combatDamageEvent:FireClient(player, damageEventTargetType, effectValue, true, targetCompanion.instanceId)
					end
				end
			else
				sendCombatLog(player, "�߸��� ����Դϴ�. �������� �ǵ��� �޽��ϴ�.")
				InventoryManager.AddItem(player, itemId, 1) -- ������ ����
			end
		end
	else -- �����ۿ� ȿ���� ���� ��� (��: �ܼ� �Ҹ�ǰ������ ������ ���� X)
		effectApplied = true -- ����� �� ������ ó��
	end

	if inventoryUpdatedEvent then inventoryUpdatedEvent:FireClient(player) end

	if effectApplied then
		-- UI ������Ʈ ������ ����
		local finalPDataForUI = PlayerData.GetStats(player)
		local pfxCopy = {}
		if state.playerStatusEffects then for _,e in ipairs(state.playerStatusEffects) do table.insert(pfxCopy,{id=e.id,duration=e.duration}) end end
		uiUpdateData.playerStats = finalPDataForUI
		uiUpdateData.playerStatus = {name=finalPDataForUI.Name, hp=finalPDataForUI.CurrentHP, maxHp=finalPDataForUI.MaxHP, mp=finalPDataForUI.CurrentMP, maxMp=finalPDataForUI.MaxMP, tp=finalPDataForUI.CurrentTP, effects=pfxCopy}

		if state.companions then
			for _, comp in ipairs(state.companions) do
				local cEffects = {}
				if comp.statusEffects then for _,fx in ipairs(comp.statusEffects) do table.insert(cEffects,{id=fx.id,duration=fx.duration}) end end
				uiUpdateData.companionsStatus[comp.instanceId] = {
					instanceId = comp.instanceId, companionDbId = comp.companionDbId, name = comp.Name, level = comp.Level,
					hp = comp.CurrentHP, maxHp = comp.MaxHP, mp = comp.CurrentMP, maxMp = comp.MaxMP,
					tp = comp.CurrentTP or 0, appearanceId = comp.AppearanceId, effects = cEffects, role = comp.Role
				}
			end
		end
		-- �� ���´� ������ ������� ���� ������� �����Ƿ� ���� ����

		if updateCombatUIEvent then updateCombatUIEvent:FireClient(player, uiUpdateData) end

		state.isPlayerTurn = false
		local companionActed = ExecuteCompanionTurn(player)
		if not state.combatEnded then
			CombatManager.StartEnemyTurn(player)
		end
	else
		-- ȿ�� ���� ���� �� (��: ��� ����), ���� �ٽ� �÷��̾�� �ѱ�ų�, ������ ó��
		-- ����� �����۸� �����ϰ� ���� �ѱ��� ����. �ʿ�� CombatManager.StartPlayerTurn(player) ȣ��
		print("CombatManager PlayerUseItem: ȿ�� ���� ����, �� ���� ���ɼ� (����� �� �ѱ�)")
		-- ���� ���� �����ϰ� �ʹٸ�, �Ʒ� 3���� �ּ� ó���ϰų� ������ �߰��ؾ� �մϴ�.
		state.isPlayerTurn = false 
		local companionActed = ExecuteCompanionTurn(player) 
		if not state.combatEnded then CombatManager.StartEnemyTurn(player) end
	end
end
-- ####################################################

return CombatManager