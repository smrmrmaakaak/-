-- ==========================================================================
-- ===== GachaDatabase.lua =====
-- ==========================================================================
--[[
  GachaDatabase (ModuleScript)
  뽑기(가챠) 시스템의 상품 목록과 확률 정보를 정의합니다.
  *** [수정] 악마의 열매 뽑기 풀 추가 ***
]]
local GachaDatabase = {}

-- GachaPools 테이블: 여러 종류의 뽑기를 정의할 수 있습니다.
-- 각 뽑기(Pool)는 고유 ID, 이름, 뽑기 비용, 상품 목록(Items)을 가집니다.
GachaDatabase.GachaPools = {
	["NormalEquip"] = { -- 기존 일반 장비 뽑기
		PoolID = "NormalEquip",
		Name = "일반 장비 뽑기", -- UI에 표시될 이름
		Cost = { Currency = "Gold", Amount = 100 }, -- 비용: 골드 100 (Currency가 "Item"이면 ItemID 필요)
		Items = {
			-- ItemID = ItemDatabase의 아이템 ID
			-- Weight = 확률 가중치 (이 풀 내의 모든 Weight 합계 대비 비율로 확률 결정)
			{ ItemID = 101, Weight = 100 }, -- 기본 검 (흔함)
			{ ItemID = 102, Weight = 100 }, -- 낡은 단검 (흔함)
			{ ItemID = 201, Weight = 80 },  -- 제작 기본 검 (조금 덜 흔함)
			{ ItemID = 202, Weight = 80 },  -- 가죽 갑옷 (조금 덜 흔함)
			{ ItemID = 1, Weight = 50 },    -- HP 포션 (가끔 나옴)
			{ ItemID = 2, Weight = 50 },    -- MP 포션 (가끔 나옴)
			{ ItemID = 103, Weight = 20 },  -- 강철 검 (희귀)
			{ ItemID = 301, Weight = 15 },  -- 힘의 반지 (희귀)
			{ ItemID = 1001, Weight = 150 }, -- 젤리 (매우 흔함)
			{ ItemID = 402, Weight = 120 }, -- 박쥐 날개 (매우 흔함)
			{ ItemID = 403, Weight = 120 }, -- 부러진 뼈 (매우 흔함)
		}
	},
	-- ["PremiumEquip"] = { -- 고급 뽑기 예시 (나중에 추가 가능)
	--  PoolID = "PremiumEquip",
	--  Name = "고급 장비 뽑기",
	--  Cost = { Currency = "Item", ItemID = 501, Amount = 1 }, -- 비용: 뽑기권 아이템 1개 (ItemID 501 가정)
	--  Items = {
	--      { ItemID = 103, Weight = 100 }, -- 강철 검
	--      { ItemID = 202, Weight = 80 },  -- 철 갑옷
	--      { ItemID = 302, Weight = 70 },  -- 체력의 목걸이
	--      -- { ItemID = ???, Weight = 10 }, -- 더 희귀한 아이템
	--  }
	-- },

	-- *** [신규] 악마의 열매 뽑기 풀 ***
	["DevilFruitPool"] = {
		PoolID = "DevilFruitPool",
		Name = "악마의 열매 뽑기",
		Cost = { Currency = "Gold", Amount = 100000 }, -- 뽑기 비용: 100,000 골드
		Items = {
			-- 여기에 ItemDatabase에 정의된 악마의 열매 아이템 ID와 확률 가중치(Weight)를 넣습니다.
			-- 예시:
			{ ItemID = 5001, Weight = 50 }, -- 고무고무 열매 (가중치 50)
			{ ItemID = 5002, Weight = 40 }, -- 이글이글 열매 (가중치 40)
			-- { ItemID = 5003, Weight = 30 }, -- 다른 희귀 열매 (가중치 낮게)
			-- { ItemID = 5004, Weight = 5 },  -- 매우 희귀한 열매 (가중치 매우 낮게)

			-- "꽝" 아이템을 넣을 수도 있습니다 (선택 사항).
			{ ItemID = 9001, Weight = 100 } -- 잡동사니 (꽝 역할, 가중치 높게)
		}
	},
}

-- 특정 풀에서 확률에 따라 아이템 ID 하나를 뽑는 함수
function GachaDatabase.PullItem(poolId)
	local pool = GachaDatabase.GachaPools[poolId]
	if not pool or not pool.Items or #pool.Items == 0 then
		warn("GachaDatabase.PullItem: Invalid or empty pool ID:", poolId)
		return nil -- 유효하지 않거나 비어있는 풀
	end

	local totalWeight = 0
	for _, item in ipairs(pool.Items) do
		totalWeight = totalWeight + (item.Weight or 0)
	end

	if totalWeight <= 0 then
		warn("GachaDatabase.PullItem: Total weight is zero or negative for pool:", poolId)
		return nil -- 뽑을 아이템이 없음 (모든 가중치가 0 이하)
	end

	-- 0 이상 totalWeight 미만의 난수 생성
	local randomWeight = math.random() * totalWeight
	if randomWeight >= totalWeight then randomWeight = totalWeight - 0.00001 end -- math.random()이 1.0을 반환하는 극히 드문 경우 대비

	local cumulativeWeight = 0
	for _, item in ipairs(pool.Items) do
		local currentWeight = item.Weight or 0
		if currentWeight > 0 then -- 가중치가 0보다 큰 경우에만 누적 및 확인
			cumulativeWeight = cumulativeWeight + currentWeight
			if randomWeight < cumulativeWeight then
				print("GachaDatabase.PullItem: Pulled ItemID", item.ItemID, "from pool", poolId)
				return item.ItemID -- 당첨된 아이템 ID 반환
			end
		end
	end

	-- 루프를 빠져나왔다면 (모든 가중치가 0이거나 부동 소수점 오류 등)
	warn("GachaDatabase.PullItem: Failed to select an item based on weight, returning nil for pool:", poolId)
	return nil -- 안전하게 nil 반환
end


return GachaDatabase