-- ==========================================================================
-- ===== DevilFruitManager.lua =====
-- ==========================================================================
--[[
  DevilFruitManager 모듈 스크립트
  - 악마의 열매 사용, 제거, 뽑기 로직 처리
  - EatFruit 함수에 요구 스탯 확인 로직 포함됨
]]

local DevilFruitManager = {}

-- 필요한 다른 모듈들을 불러옵니다.
local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local ItemDatabase = require(modulesFolder:WaitForChild("ItemDatabase"))
local DevilFruitDatabase = require(modulesFolder:WaitForChild("DevilFruitDatabase"))
local PlayerData = require(modulesFolder:WaitForChild("PlayerData"))
local InventoryManager = require(modulesFolder:WaitForChild("InventoryManager"))
local GachaDatabase = require(modulesFolder:WaitForChild("GachaDatabase"))

-- 설정값
local DEBUG_MODE = true
local REMOVAL_COST = 10000
local FRUIT_GACHA_POOL_ID = "DevilFruitPool"

--[[
  EatFruit 함수
  플레이어가 악마의 열매 아이템을 먹으려고 시도할 때 호출됩니다.
  (요구 스탯 확인 포함됨)
]]
function DevilFruitManager.EatFruit(player, itemId)
	if DEBUG_MODE then print("DevilFruitManager: EatFruit 호출됨 - Player:", player.Name, "ItemID:", itemId) end
	local itemInfo = ItemDatabase.Items[itemId]; if not itemInfo then warn("DevilFruitManager: 유효하지 않은 아이템 ID:", itemId); return false, "유효하지 않은 아이템입니다." end
	if itemInfo.Type ~= "DevilFruit" then warn("DevilFruitManager: 악마의 열매 타입이 아닌 아이템 시도:", itemId, itemInfo.Type); return false, "악마의 열매가 아닙니다." end
	local playerData = PlayerData.GetSessionData(player); if not playerData then warn("DevilFruitManager: 플레이어 세션 데이터를 찾을 수 없음:", player.Name); return false, "플레이어 데이터를 불러올 수 없습니다." end
	if playerData.ActiveDevilFruit and playerData.ActiveDevilFruit ~= "" and playerData.ActiveDevilFruit ~= nil then if DEBUG_MODE then print("DevilFruitManager:", player.Name, "는 이미 능력이 있습니다:", playerData.ActiveDevilFruit) end; return false, "이미 악마의 열매 능력을 가지고 있습니다." end
	local fruitId = itemInfo.FruitID; local fruitInfo = DevilFruitDatabase.GetFruitInfo(fruitId); if not fruitInfo then warn("DevilFruitManager: DevilFruitDatabase에서 FruitID 정보를 찾을 수 없음:", fruitId); return false, "알 수 없는 악마의 열매입니다." end

	-- 요구 스탯(DF) 확인
	local requiredDF = itemInfo.requiredDF
	if requiredDF and requiredDF > 0 then
		local playerDF = playerData.DF or 0
		if playerDF < requiredDF then
			warn(string.format("DevilFruitManager: EatFruit - 요구 DF 스탯 부족! ItemID: %d, 요구: %d, 현재: %d", itemId, requiredDF, playerDF))

			-- ########## 기능 추가 시작 ##########
			local failMessage = string.format("이 열매를 먹으려면 악마의 열매 스탯 %d 이상 필요합니다.", requiredDF)
			-- NotifyPlayerEvent 참조 (안전하게 확인)
			local NotifyPlayerEvent = ReplicatedStorage:FindFirstChild("NotifyPlayerEvent")
			if NotifyPlayerEvent then
				NotifyPlayerEvent:FireClient(player, "사용 불가", failMessage) -- 알림 발송!
				print("DevilFruitManager: Sent 'Stat Requirement Not Met' notification to player.") -- 디버그 로그
			else
				warn("DevilFruitManager: EatFruit - NotifyPlayerEvent not found!")
			end
			-- ########## 기능 추가 끝 ##########

			-- 요구 스탯 부족 시 실패 메시지 반환 (기존 코드 유지)
			return false, failMessage
		end
		if DEBUG_MODE then print("DevilFruitManager: EatFruit - DF 요구 스탯 충족 (요구:", requiredDF, ", 현재:", playerDF, ")") end
	end

	-- 능력 부여
	playerData.ActiveDevilFruit = fruitId
	local statsFolder = player:FindFirstChild(PlayerData.STATS_FOLDER_NAME)
	if statsFolder then local vo=statsFolder:FindFirstChild("ActiveDevilFruit"); if vo and vo:IsA("StringValue") then vo.Value=fruitId else local nvo=Instance.new("StringValue"); nvo.Name="ActiveDevilFruit"; nvo.Value=fruitId; nvo.Parent=statsFolder end else warn("DevilFruitManager: EatFruit - PlayerStats 폴더 없음") end
	if DEBUG_MODE then print("DevilFruitManager:", player.Name, "에게", fruitInfo.Name, "능력 부여됨 (FruitID:", fruitId, ")") end

	-- 아이템 제거
	local success, message = InventoryManager.RemoveItem(player, itemId, 1)
	if not success then
		warn("DevilFruitManager: 아이템 제거 실패! 능력 부여 롤백:", player.Name, itemId, message or "")
		playerData.ActiveDevilFruit = nil;
		if statsFolder then local vo=statsFolder:FindFirstChild("ActiveDevilFruit"); if vo then vo.Value="" end end
		return false, message or "아이템을 제거하는 데 실패했습니다." -- 제거 실패 메시지 반환
	end

	if DEBUG_MODE then print("DevilFruitManager:", player.Name, "의 인벤토리에서", itemInfo.Name, "(ID:", itemId, ") 제거 완료") end
	if fruitInfo.GrantedSkills and PlayerData.LearnSkill then for _, skillIdToLearn in ipairs(fruitInfo.GrantedSkills) do PlayerData.LearnSkill(player, skillIdToLearn) end end
	if DEBUG_MODE then print("DevilFruitManager: EatFruit 성공 - Player:", player.Name, "Fruit:", fruitInfo.Name) end
	return true, nil -- 성공 시 메시지 없이 true 반환
end

-- 능력 제거 함수 (수정 없음)
function DevilFruitManager.RemoveFruit(player) if DEBUG_MODE then print("RemoveFruit 호출됨:",player.Name) end; local pData=PlayerData.GetSessionData(player); if not pData then return false,"플레이어 데이터 없음" end; local curFruit=pData.ActiveDevilFruit; if not curFruit or curFruit=="" then return false,"제거할 능력 없음" end; local gold=pData.Gold or 0; if gold<REMOVAL_COST then return false,string.format("제거 비용 %d 골드 부족",REMOVAL_COST) end; local goldOk=PlayerData.UpdateStat(player,"Gold",gold-REMOVAL_COST); if not goldOk then return false,"비용 지불 오류" end; local fInfo=DevilFruitDatabase.GetFruitInfo(curFruit); local fName=fInfo and fInfo.Name or "알수없음"; pData.ActiveDevilFruit=nil; local statsFolder=player:FindFirstChild(PlayerData.STATS_FOLDER_NAME); if statsFolder then local vo=statsFolder:FindFirstChild("ActiveDevilFruit"); if vo and vo:IsA("StringValue") then vo.Value="" end end; if DEBUG_MODE then print(fName,"능력 제거 완료") end; return true,string.format("%s 능력 제거 완료.",fName) end

-- 악마의 열매 뽑기 함수 (수정 없음)
function DevilFruitManager.PullRandomFruit(player) if DEBUG_MODE then print("PullRandomFruit 호출됨:",player.Name) end; local pool=GachaDatabase.GachaPools[FRUIT_GACHA_POOL_ID]; if not pool then return false,"뽑기 풀 없음" end; local cost=pool.Cost; if not cost or cost.Currency~="Gold" or not cost.Amount or cost.Amount<=0 then return false,"비용 정보 오류" end; local pullCost=cost.Amount; local pData=PlayerData.GetSessionData(player); if not pData then return false,"플레이어 데이터 없음" end; local gold=pData.Gold or 0; if gold<pullCost then return false,string.format("뽑기 비용 %d 골드 부족",pullCost) end; local goldOk=PlayerData.UpdateStat(player,"Gold",gold-pullCost); if not goldOk then return false,"비용 지불 오류" end; local pulledId=GachaDatabase.PullItem(FRUIT_GACHA_POOL_ID); if not pulledId then warn("GachaDatabase.PullItem 실패! 롤백..."); PlayerData.UpdateStat(player,"Gold",gold); return false,"뽑기 실패." end; local added,msg=InventoryManager.AddItem(player,pulledId,1); if not added then warn("아이템 지급 실패! 롤백...",msg); PlayerData.UpdateStat(player,"Gold",gold); return false,"뽑은 열매 지급 오류." end; local itemInfo=ItemDatabase.Items[pulledId]; local itemName=itemInfo and itemInfo.Name or ("아이템 #"..pulledId); if DEBUG_MODE then print("뽑기 성공:",itemName,"(ID:",pulledId,")") end; local NotifyPlayerEvent=ReplicatedStorage:FindFirstChild("NotifyPlayerEvent"); if NotifyPlayerEvent then NotifyPlayerEvent:FireClient(player,"뽑기 결과",string.format("%s (을)를 뽑았습니다!",itemName)) end; return true,string.format("%s (을)를 뽑았습니다!",itemName) end -- 뽑기 결과 메시지 반환은 유지

return DevilFruitManager