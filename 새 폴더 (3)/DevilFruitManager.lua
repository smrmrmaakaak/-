-- ==========================================================================
-- ===== DevilFruitManager.lua =====
-- ==========================================================================
--[[
  DevilFruitManager ��� ��ũ��Ʈ
  - �Ǹ��� ���� ���, ����, �̱� ���� ó��
  - EatFruit �Լ��� �䱸 ���� Ȯ�� ���� ���Ե�
]]

local DevilFruitManager = {}

-- �ʿ��� �ٸ� ������ �ҷ��ɴϴ�.
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local ItemDatabase = require(modulesFolder:WaitForChild("ItemDatabase"))
local DevilFruitDatabase = require(modulesFolder:WaitForChild("DevilFruitDatabase"))
local PlayerData = require(modulesFolder:WaitForChild("PlayerData"))
local InventoryManager = require(modulesFolder:WaitForChild("InventoryManager"))
local GachaDatabase = require(modulesFolder:WaitForChild("GachaDatabase"))

-- ������
local DEBUG_MODE = true
local REMOVAL_COST = 10000
local FRUIT_GACHA_POOL_ID = "DevilFruitPool"

--[[
  EatFruit �Լ�
  �÷��̾ �Ǹ��� ���� �������� �������� �õ��� �� ȣ��˴ϴ�.
  (�䱸 ���� Ȯ�� ���Ե�)
]]
function DevilFruitManager.EatFruit(player, itemId)
	if DEBUG_MODE then print("DevilFruitManager: EatFruit ȣ��� - Player:", player.Name, "ItemID:", itemId) end
	local itemInfo = ItemDatabase.Items[itemId]; if not itemInfo then warn("DevilFruitManager: ��ȿ���� ���� ������ ID:", itemId); return false, "��ȿ���� ���� �������Դϴ�." end
	if itemInfo.Type ~= "DevilFruit" then warn("DevilFruitManager: �Ǹ��� ���� Ÿ���� �ƴ� ������ �õ�:", itemId, itemInfo.Type); return false, "�Ǹ��� ���Ű� �ƴմϴ�." end
	local playerData = PlayerData.GetSessionData(player); if not playerData then warn("DevilFruitManager: �÷��̾� ���� �����͸� ã�� �� ����:", player.Name); return false, "�÷��̾� �����͸� �ҷ��� �� �����ϴ�." end
	if playerData.ActiveDevilFruit and playerData.ActiveDevilFruit ~= "" and playerData.ActiveDevilFruit ~= nil then if DEBUG_MODE then print("DevilFruitManager:", player.Name, "�� �̹� �ɷ��� �ֽ��ϴ�:", playerData.ActiveDevilFruit) end; return false, "�̹� �Ǹ��� ���� �ɷ��� ������ �ֽ��ϴ�." end
	local fruitId = itemInfo.FruitID; local fruitInfo = DevilFruitDatabase.GetFruitInfo(fruitId); if not fruitInfo then warn("DevilFruitManager: DevilFruitDatabase���� FruitID ������ ã�� �� ����:", fruitId); return false, "�� �� ���� �Ǹ��� �����Դϴ�." end

	-- �䱸 ����(DF) Ȯ��
	local requiredDF = itemInfo.requiredDF
	if requiredDF and requiredDF > 0 then
		local playerDF = playerData.DF or 0
		if playerDF < requiredDF then
			warn(string.format("DevilFruitManager: EatFruit - �䱸 DF ���� ����! ItemID: %d, �䱸: %d, ����: %d", itemId, requiredDF, playerDF))

			-- ########## ��� �߰� ���� ##########
			local failMessage = string.format("�� ���Ÿ� �������� �Ǹ��� ���� ���� %d �̻� �ʿ��մϴ�.", requiredDF)
			-- NotifyPlayerEvent ���� (�����ϰ� Ȯ��)
			local NotifyPlayerEvent = ReplicatedStorage:FindFirstChild("NotifyPlayerEvent")
			if NotifyPlayerEvent then
				NotifyPlayerEvent:FireClient(player, "��� �Ұ�", failMessage) -- �˸� �߼�!
				print("DevilFruitManager: Sent 'Stat Requirement Not Met' notification to player.") -- ����� �α�
			else
				warn("DevilFruitManager: EatFruit - NotifyPlayerEvent not found!")
			end
			-- ########## ��� �߰� �� ##########

			-- �䱸 ���� ���� �� ���� �޽��� ��ȯ (���� �ڵ� ����)
			return false, failMessage
		end
		if DEBUG_MODE then print("DevilFruitManager: EatFruit - DF �䱸 ���� ���� (�䱸:", requiredDF, ", ����:", playerDF, ")") end
	end

	-- �ɷ� �ο�
	playerData.ActiveDevilFruit = fruitId
	local statsFolder = player:FindFirstChild(PlayerData.STATS_FOLDER_NAME)
	if statsFolder then local vo=statsFolder:FindFirstChild("ActiveDevilFruit"); if vo and vo:IsA("StringValue") then vo.Value=fruitId else local nvo=Instance.new("StringValue"); nvo.Name="ActiveDevilFruit"; nvo.Value=fruitId; nvo.Parent=statsFolder end else warn("DevilFruitManager: EatFruit - PlayerStats ���� ����") end
	if DEBUG_MODE then print("DevilFruitManager:", player.Name, "����", fruitInfo.Name, "�ɷ� �ο��� (FruitID:", fruitId, ")") end

	-- ������ ����
	local success, message = InventoryManager.RemoveItem(player, itemId, 1)
	if not success then
		warn("DevilFruitManager: ������ ���� ����! �ɷ� �ο� �ѹ�:", player.Name, itemId, message or "")
		playerData.ActiveDevilFruit = nil;
		if statsFolder then local vo=statsFolder:FindFirstChild("ActiveDevilFruit"); if vo then vo.Value="" end end
		return false, message or "�������� �����ϴ� �� �����߽��ϴ�." -- ���� ���� �޽��� ��ȯ
	end

	if DEBUG_MODE then print("DevilFruitManager:", player.Name, "�� �κ��丮����", itemInfo.Name, "(ID:", itemId, ") ���� �Ϸ�") end
	if fruitInfo.GrantedSkills and PlayerData.LearnSkill then for _, skillIdToLearn in ipairs(fruitInfo.GrantedSkills) do PlayerData.LearnSkill(player, skillIdToLearn) end end
	if DEBUG_MODE then print("DevilFruitManager: EatFruit ���� - Player:", player.Name, "Fruit:", fruitInfo.Name) end
	return true, nil -- ���� �� �޽��� ���� true ��ȯ
end

-- �ɷ� ���� �Լ� (���� ����)
function DevilFruitManager.RemoveFruit(player) if DEBUG_MODE then print("RemoveFruit ȣ���:",player.Name) end; local pData=PlayerData.GetSessionData(player); if not pData then return false,"�÷��̾� ������ ����" end; local curFruit=pData.ActiveDevilFruit; if not curFruit or curFruit=="" then return false,"������ �ɷ� ����" end; local gold=pData.Gold or 0; if gold<REMOVAL_COST then return false,string.format("���� ��� %d ��� ����",REMOVAL_COST) end; local goldOk=PlayerData.UpdateStat(player,"Gold",gold-REMOVAL_COST); if not goldOk then return false,"��� ���� ����" end; local fInfo=DevilFruitDatabase.GetFruitInfo(curFruit); local fName=fInfo and fInfo.Name or "�˼�����"; pData.ActiveDevilFruit=nil; local statsFolder=player:FindFirstChild(PlayerData.STATS_FOLDER_NAME); if statsFolder then local vo=statsFolder:FindFirstChild("ActiveDevilFruit"); if vo and vo:IsA("StringValue") then vo.Value="" end end; if DEBUG_MODE then print(fName,"�ɷ� ���� �Ϸ�") end; return true,string.format("%s �ɷ� ���� �Ϸ�.",fName) end

-- �Ǹ��� ���� �̱� �Լ� (���� ����)
function DevilFruitManager.PullRandomFruit(player) if DEBUG_MODE then print("PullRandomFruit ȣ���:",player.Name) end; local pool=GachaDatabase.GachaPools[FRUIT_GACHA_POOL_ID]; if not pool then return false,"�̱� Ǯ ����" end; local cost=pool.Cost; if not cost or cost.Currency~="Gold" or not cost.Amount or cost.Amount<=0 then return false,"��� ���� ����" end; local pullCost=cost.Amount; local pData=PlayerData.GetSessionData(player); if not pData then return false,"�÷��̾� ������ ����" end; local gold=pData.Gold or 0; if gold<pullCost then return false,string.format("�̱� ��� %d ��� ����",pullCost) end; local goldOk=PlayerData.UpdateStat(player,"Gold",gold-pullCost); if not goldOk then return false,"��� ���� ����" end; local pulledId=GachaDatabase.PullItem(FRUIT_GACHA_POOL_ID); if not pulledId then warn("GachaDatabase.PullItem ����! �ѹ�..."); PlayerData.UpdateStat(player,"Gold",gold); return false,"�̱� ����." end; local added,msg=InventoryManager.AddItem(player,pulledId,1); if not added then warn("������ ���� ����! �ѹ�...",msg); PlayerData.UpdateStat(player,"Gold",gold); return false,"���� ���� ���� ����." end; local itemInfo=ItemDatabase.Items[pulledId]; local itemName=itemInfo and itemInfo.Name or ("������ #"..pulledId); if DEBUG_MODE then print("�̱� ����:",itemName,"(ID:",pulledId,")") end; local NotifyPlayerEvent=ReplicatedStorage:FindFirstChild("NotifyPlayerEvent"); if NotifyPlayerEvent then NotifyPlayerEvent:FireClient(player,"�̱� ���",string.format("%s (��)�� �̾ҽ��ϴ�!",itemName)) end; return true,string.format("%s (��)�� �̾ҽ��ϴ�!",itemName) end -- �̱� ��� �޽��� ��ȯ�� ����

return DevilFruitManager