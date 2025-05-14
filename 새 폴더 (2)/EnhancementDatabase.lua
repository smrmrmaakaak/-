-- EnhancementDatabase.lua (신규 파일)

local EnhancementDatabase = {}

-- 강화 레벨별 설정
-- 키: 강화 시도 레벨 (예: 1 은 +0 -> +1 강화 시도)
EnhancementDatabase.Levels = {
	[1] = { -- +0 -> +1 강화 시도
		Materials = { {ItemID = 1101, Quantity = 1} }, -- 하급 강화석 1개
		GoldCost = 100,
		SuccessRate = 0.95 -- 95% 성공 확률
		-- FailPenalty = { MaterialLoss = true } -- 실패 시 재료만 소모 (기본값)
	},
	[2] = { -- +1 -> +2 강화 시도
		Materials = { {ItemID = 1101, Quantity = 2} }, -- 하급 강화석 2개
		GoldCost = 250,
		SuccessRate = 0.90 -- 90%
	},
	[3] = { -- +2 -> +3 강화 시도
		Materials = { {ItemID = 1101, Quantity = 3} }, -- 하급 강화석 3개
		GoldCost = 500,
		SuccessRate = 0.80 -- 80%
	},
	[4] = { -- +3 -> +4 강화 시도
		Materials = { {ItemID = 1101, Quantity = 5}, {ItemID = 1002, Quantity = 2} }, -- 하급 5개, 철광석 2개
		GoldCost = 1000,
		SuccessRate = 0.70 -- 70%
	},
	[5] = { -- +4 -> +5 강화 시도
		Materials = { {ItemID = 1102, Quantity = 1} }, -- 중급 강화석 1개
		GoldCost = 2000,
		SuccessRate = 0.60 -- 60%
		-- FailPenalty = { MaterialLoss = true, LevelDecrease = 1 } -- 실패 시 재료 소모 및 레벨 1 하락 (선택적)
	},
	[6] = { -- +5 -> +6 강화 시도
		Materials = { {ItemID = 1102, Quantity = 2} }, -- 중급 강화석 2개
		GoldCost = 4000,
		SuccessRate = 0.50 -- 50%
	},
	[7] = { -- +6 -> +7 강화 시도
		Materials = { {ItemID = 1102, Quantity = 3}, {ItemID = 1004, Quantity = 1} }, -- 중급 3개, 마력의 돌 1개
		GoldCost = 8000,
		SuccessRate = 0.40 -- 40%
	},
	[8] = { -- +7 -> +8 강화 시도
		Materials = { {ItemID = 1103, Quantity = 1} }, -- 상급 강화석 1개
		GoldCost = 15000,
		SuccessRate = 0.30 -- 30%
		-- FailPenalty = { MaterialLoss = true, DestroyItem = 0.1 } -- 실패 시 재료 소모, 10% 확률로 아이템 파괴 (선택적)
	},
	[9] = { -- +8 -> +9 강화 시도
		Materials = { {ItemID = 1103, Quantity = 2} },
		GoldCost = 30000,
		SuccessRate = 0.20 -- 20%
	},
	[10] = { -- +9 -> +10 강화 시도
		Materials = { {ItemID = 1103, Quantity = 3} },
		GoldCost = 50000,
		SuccessRate = 0.10 -- 10%
	},
	-- 필요에 따라 더 높은 레벨 추가
}

-- 특정 강화 레벨에 대한 정보 반환 함수
function EnhancementDatabase.GetLevelInfo(level)
	return EnhancementDatabase.Levels[level]
end

return EnhancementDatabase