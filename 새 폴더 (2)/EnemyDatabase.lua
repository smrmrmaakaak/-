--[[
  EnemyDatabase (ModuleScript)
  게임에 등장하는 적(몬스터) 데이터 저장
  *** [수정] 해적/해군 테마 몬스터 추가 ***
  *** [수정] 슬라임(ID:1) 데이터에 ImageId 필드 추가 ***
]]
local EnemyDatabase = {}

EnemyDatabase.Enemies = {
	-- 기존 몬스터
	[1] = { -- 슬라임
		ID = 1, Name = "슬라임", Level = 1, MaxHP = 30, Attack = 5, DEF = 2,
		ExpReward = 10000, GoldReward = 50000, -- 경험치 보상 조정
		ImageId = "rbxassetid://139610831731863", -- *** 추가: 슬라임 이미지 ID (실제 ID로 교체 필요) ***
		Drops = {
			{ ItemID = 1001, Chance = 0.7, Quantity = 1 }, -- 젤리 70%
			{ ItemID = 1, Chance = 0.1, Quantity = 1 }    -- HP 포션 10%
		}
	},
	[2] = { -- 박쥐
		ID = 2, Name = "박쥐", Level = 3, MaxHP = 70, Attack = 8, DEF = 4,
		ExpReward = 25, GoldReward = 12,
		ImageId = "rbxassetid://208066789012345", -- 박쥐 이미지 ID (예시)
		Drops = {
			{ ItemID = 402, Chance = 0.6, Quantity = 1 }, -- 박쥐 날개 60%
			{ ItemID = 2, Chance = 0.05, Quantity = 1 }   -- MP 포션 5%
		}
	},
	[3] = { -- 스켈레톤
		ID = 3, Name = "스켈레톤", Level = 5, MaxHP = 120, Attack = 12, DEF = 6,
		ExpReward = 40, GoldReward = 20,
		ImageId = "rbxassetid://86654621036939", -- 스켈레톤 이미지 ID (예시)
		Drops = {
			{ ItemID = 403, Chance = 0.5, Quantity = 1 }, -- 부러진 뼈 50%
			{ ItemID = 102, Chance = 0.05, Quantity = 1}  -- 낡은 단검 5%
		}
	},
	[4] = { -- 고블린
		ID = 4, Name = "고블린", Level = 4, MaxHP = 90, Attack = 10, DEF = 5,
		ExpReward = 35, GoldReward = 15,
		ImageId = "rbxassetid://109033948393929", -- 고블린 이미지 ID (예시)
		Drops = {
			{ ItemID = 1002, Chance = 0.3, Quantity = 1 }, -- 철광석 30%
			{ ItemID = 9001, Chance = 0.2, Quantity = 1 }, -- 잡동사니 20%
			{ ItemID = 202, Chance = 0.03, Quantity = 1 }, -- 가죽 갑옷 3%
		}
	},
	[5] = { -- 오크
		ID = 5, Name = "오크", Level = 7, MaxHP = 200, Attack = 18, DEF = 10,
		ExpReward = 70, GoldReward = 40,
		ImageId = "rbxassetid://136237872671206", -- 오크 이미지 ID (예시)
		Drops = {
			{ ItemID = 1003, Chance = 0.4, Quantity = 2 }, -- 나무 장작 40% (2개)
			{ ItemID = 1004, Chance = 0.1, Quantity = 1 }, -- 마력의 돌 10%
			{ ItemID = 103, Chance = 0.02, Quantity = 1 }, -- 강철 검 2%
		}
	},

	-- *** [신규] 해적 테마 몬스터 ***
	[6] = { -- 해적 칼잡이
		ID = 6, Name = "해적 칼잡이", Level = 8, MaxHP = 250, Attack = 22, DEF = 8,
		ExpReward = 85, GoldReward = 50,
		ImageId = "rbxassetid://127349921664378", -- 해적 이미지 ID (예시)
		-- Skills = { ... }, -- 필요시 스킬 추가
		Drops = {
			{ ItemID = 4, Chance = 0.2, Quantity = 1 },    -- 럼주 20%
			{ ItemID = 1005, Chance = 0.1, Quantity = 1 }, -- 낡은 해도 조각 10%
			{ ItemID = 104, Chance = 0.03, Quantity = 1 }, -- 해적 커틀러스 3%
		}
	},
	[7] = { -- 해적 포병
		ID = 7, Name = "해적 포병", Level = 9, MaxHP = 220, Attack = 25, DEF = 6, -- 공격력 높고 방어력 낮음
		ExpReward = 90, GoldReward = 55,
		ImageId = "rbxassetid://112535677076979", -- 포병 이미지 ID (예시)
		Drops = {
			{ ItemID = 4, Chance = 0.15, Quantity = 1 },   -- 럼주 15%
			{ ItemID = 9001, Chance = 0.3, Quantity = 1 },  -- 잡동사니 30%
			{ ItemID = 304, Chance = 0.02, Quantity = 1 }, -- 해적 안대 2%
		}
	},

	-- *** [신규] 해군 테마 몬스터 ***
	[8] = { -- 해군 보병
		ID = 8, Name = "해군 보병", Level = 10, MaxHP = 300, Attack = 20, DEF = 15, -- 방어력 높음
		ExpReward = 100, GoldReward = 60,
		ImageId = "rbxassetid://122841225189417", -- 해군 보병 이미지 ID (예시)
		Drops = {
			{ ItemID = 1, Chance = 0.1, Quantity = 2 },    -- HP 포션 10% (2개)
			{ ItemID = 1006, Chance = 0.2, Quantity = 1 }, -- 해군의 단추 20%
			{ ItemID = 105, Chance = 0.02, Quantity = 1 }, -- 해군 제식 소총 2%
		}
	},
	[9] = { -- 해군 장교
		ID = 9, Name = "해군 장교", Level = 12, MaxHP = 350, Attack = 24, DEF = 18,
		ExpReward = 150, GoldReward = 80,
		ImageId = "rbxassetid://139037740235144", -- 해군 장교 이미지 ID (예시)
		-- Skills = { ... }, -- 필요시 스킬 추가 (예: 아군 버프)
		Drops = {
			{ ItemID = 3, Chance = 0.05, Quantity = 1 },    -- 엘릭서 5%
			{ ItemID = 305, Chance = 0.1, Quantity = 1 },  -- 해군 인식표 10%
			{ ItemID = 206, Chance = 0.01, Quantity = 1 }, -- 해군 제복 1% (희귀)
		}
	},
}

return EnemyDatabase
