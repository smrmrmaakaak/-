-- ItemDatabase.lua (수정된 전체 코드)

--[[
  ItemDatabase (ModuleScript)
  게임 내 모든 아이템의 정보를 저장하고 관리합니다.
  *** [수정] 모든 아이템에 Rating 필드 추가 ***
  *** [수정] 일부 아이템에 요구 스탯 필드 추가 (requiredSword, requiredGun, requiredDF) ***
  *** [추가] 강화 가능 장비에 강화 관련 필드 추가 (Enhanceable, MaxEnhanceLevel, EnhanceStat, EnhanceValuePerLevel) ***
]]
local ItemDatabase = {}

ItemDatabase.Items = {
	-- 소모품 (수정 없음)
	[1] = { ID = 1, Name = "HP 포션",
		Description = "HP를 50 회복합니다.",
		Type = "Consumable", Effect = { Stat = "HP", Value = 50 }, Stackable = true, Price = 50, SellPrice = 25, ImageId = "rbxassetid://110762008410456", ConsumedOnUse = true, Rating = "Common" },
	[2] = { ID = 2, Name = "MP 포션",
		Description = "MP를 30 회복합니다.",
		Type = "Consumable", Effect = { Stat = "MP", Value = 30 }, Stackable = true, Price = 70, SellPrice = 35, ImageId = "rbxassetid://127915573929076", ConsumedOnUse = true, Rating = "Common" },
	[101] = { ID = 101, Name = "이상한포션",
		Description = "HP를 약간 회복시킨다.",
		Type = "Consumable", Effect = { Stat = "HP", Value = 50 }, Stackable = true, Price = 50, SellPrice = 10, ImageId = "rbxassetid://107948162867712", ConsumedOnUse = true, Rating = "Common" },
	[3] = { ID = 3, Name = "엘릭서",
		Description = "HP와 MP를 모두 크게 회복합니다.",
		Type = "Consumable",
		Effect = { Stat = "HPMP", Value = 150 },
		Stackable = true,
		Price = 300, SellPrice = 150,
		ImageId = "rbxassetid://136892959937909",
		ConsumedOnUse = true, Rating = "Rare" },
	[4] = { ID = 4, Name = "럼주",
		Description = "해적들이 좋아하는 술. 마시면 잠시 공격력이 오르지만 방어력이 약간 감소한다.", Type = "Consumable", Effect = { Type = "BuffDebuff", Buff = {Stat = "Attack", Value = 5, Duration = 3}, Debuff = {Stat = "Defense", Value = -2, Duration = 3} }, Stackable = true, Price = 80, SellPrice = 40, ImageId = "rbxassetid://105307866340527", ConsumedOnUse = true, Rating = "Uncommon" }, -- Debuff Stat 수정: DEF -> Defense

	-- 장비
	[102] = { ID = 102, Name = "낡은 단검", Description = "날이 무딘 오래된 단검입니다.", Type = "Equipment", Slot = "Weapon", WeaponType = "Sword", Stats = { Attack = 3 }, Stackable = false, Price = 70, SellPrice = 35, ImageId = "rbxassetid://121089420845762", ConsumedOnUse = false, Rating = "Common",
		-- *** 강화 정보 추가 (예시) ***
		Enhanceable = true, MaxEnhanceLevel = 5, EnhanceStat = "Attack", EnhanceValuePerLevel = 1
	},
	[103] = { ID = 103, Name = "강철 검", Description = "잘 벼려진 강철 검입니다. 제법 쓸만합니다.", Type = "Equipment", Slot = "Weapon", WeaponType = "Sword", Stats = { Attack = 8 }, Stackable = false, Price = 250, SellPrice = 125, ImageId = "rbxassetid://131972999247967", ConsumedOnUse = false, Rating = "Uncommon", requiredSword = 10,
		-- *** 강화 정보 추가 (예시) ***
		Enhanceable = true, MaxEnhanceLevel = 7, EnhanceStat = "Attack", EnhanceValuePerLevel = 2
	},
	[201] = { ID = 201, Name = "기본 검", Description = "기본적인 공격용 검.", Type = "Equipment", Slot = "Weapon", WeaponType = "Sword", Stats = { Attack = 5 }, Stackable = false, Price = 100, SellPrice = 20, ImageId = "rbxassetid://114430077185745", ConsumedOnUse = false, Rating = "Common",
		-- *** 강화 정보 추가 (예시) ***
		Enhanceable = true, MaxEnhanceLevel = 5, EnhanceStat = "Attack", EnhanceValuePerLevel = 1
	},
	[202] = { ID = 202, Name = "가죽 갑옷", Description = "가볍고 기본적인 방어력을 제공하는 가죽 갑옷입니다.", Type = "Equipment", Slot = "Armor", Stats = { Defense = 3 }, Stackable = false, Price = 150, SellPrice = 75, ImageId = "rbxassetid://116466664504363", ConsumedOnUse = false, Rating = "Common",
		-- *** 강화 정보 추가 (예시) ***
		Enhanceable = true, MaxEnhanceLevel = 5, EnhanceStat = "Defense", EnhanceValuePerLevel = 1
	},
	[203] = { ID = 203, Name = "철 갑옷", Description = "견고한 철로 만들어진 갑옷입니다. 꽤 튼튼합니다.", Type = "Equipment", Slot = "Armor", Stats = { Defense = 8 }, Stackable = false, Price = 400, SellPrice = 200, ImageId = "rbxassetid://89685543061050", ConsumedOnUse = false, Rating = "Uncommon",
		-- *** 강화 정보 추가 (예시) ***
		Enhanceable = true, MaxEnhanceLevel = 7, EnhanceStat = "Defense", EnhanceValuePerLevel = 2
	},
	-- 마법사의 로브, 악세사리 등은 강화 불가능하게 설정 (Enhanceable = false 또는 필드 생략)
	[204] = { ID = 204, Name = "마법사의 로브", Description = "지능과 최대 MP를 올려주는 로브입니다.", Type = "Equipment", Slot = "Armor", Stats = { INT = 3, MaxMP = 20 }, Stackable = false, Price = 350, SellPrice = 175, ImageId = "rbxassetid://129481683345846", ConsumedOnUse = false, Rating = "Uncommon", Enhanceable = false },
	[301] = { ID = 301, Name = "힘의 반지", Description = "착용자의 힘을 약간 올려주는 반지입니다.", Type = "Equipment", Slot = "Accessory", Stats = { STR = 2 }, Stackable = false, Price = 200, SellPrice = 100, ImageId = "rbxassetid://106567997832253", ConsumedOnUse = false, Rating = "Uncommon", Enhanceable = false },
	[302] = { ID = 302, Name = "체력의 목걸이", Description = "착용자의 최대 HP를 약간 올려주는 목걸이입니다.", Type = "Equipment", Slot = "Accessory", Stats = { MaxHP = 15 }, Stackable = false, Price = 180, SellPrice = 90, ImageId = "rbxassetid://86203317389088", ConsumedOnUse = false, Rating = "Uncommon", Enhanceable = false },
	[303] = { ID = 303, Name = "민첩의 장갑", Description = "착용자의 민첩성을 향상시킵니다.", Type = "Equipment", Slot = "Accessory", Stats = { AGI = 3 }, Stackable = false, Price = 220, SellPrice = 110, ImageId = "rbxassetid://74032276041549", ConsumedOnUse = false, Rating = "Uncommon", Enhanceable = false },

	[104] = { ID = 104, Name = "해적 커틀러스", Description = "해적들이 즐겨 사용하는 구부러진 칼.", Type = "Equipment", Slot = "Weapon", WeaponType = "Sword", Stats = { Attack = 12, AGI = 1 }, Stackable = false, Price = 500, SellPrice = 250, ImageId = "rbxassetid://99511281395130", ConsumedOnUse = false, Rating = "Rare",
		Enhanceable = true, MaxEnhanceLevel = 8, EnhanceStat = "Attack", EnhanceValuePerLevel = 3
	},
	[205] = { ID = 205, Name = "해적 선장 코트", Description = "위풍당당한 해적 선장의 코트.", Type = "Equipment", Slot = "Armor", Stats = { Defense = 10, INT = 1 }, Stackable = false, Price = 600, SellPrice = 300, ImageId = "rbxassetid://PLACEHOLDER_PIRATE_COAT", ConsumedOnUse = false, Rating = "Epic",
		Enhanceable = true, MaxEnhanceLevel = 8, EnhanceStat = "Defense", EnhanceValuePerLevel = 3
	},
	[304] = { ID = 304, Name = "해적 안대", Description = "한쪽 눈을 가리는 안대.", Type = "Equipment", Slot = "Accessory", Stats = { STR = 1, MaxHP = 10 }, Stackable = false, Price = 150, SellPrice = 75, ImageId = "rbxassetid://PLACEHOLDER_EYEPATCH", ConsumedOnUse = false, Rating = "Uncommon", Enhanceable = false },

	[105] = { ID = 105, Name = "해군 제식 소총", Description = "해군에게 지급되는 표준 소총.", Type = "Equipment", Slot = "Weapon", WeaponType = "Gun", Stats = { Attack = 10, AGI = 2 }, Stackable = false, Price = 450, SellPrice = 225, ImageId = "rbxassetid://PLACEHOLDER_MARINE_RIFLE", ConsumedOnUse = false, Rating = "Rare", requiredGun = 5,
		Enhanceable = true, MaxEnhanceLevel = 7, EnhanceStat = "Attack", EnhanceValuePerLevel = 2
	},
	[206] = { ID = 206, Name = "해군 제복", Description = "깔끔하고 튼튼한 해군 제복.", Type = "Equipment", Slot = "Armor", Stats = { Defense = 12 }, Stackable = false, Price = 700, SellPrice = 350, ImageId = "rbxassetid://PLACEHOLDER_MARINE_UNIFORM", ConsumedOnUse = false, Rating = "Epic",
		Enhanceable = true, MaxEnhanceLevel = 9, EnhanceStat = "Defense", EnhanceValuePerLevel = 3
	},
	[305] = { ID = 305, Name = "해군 인식표", Description = "해군의 신분을 증명하는 인식표.", Type = "Equipment", Slot = "Accessory", Stats = { MaxHP = 25 }, Stackable = false, Price = 120, SellPrice = 60, ImageId = "rbxassetid://135612708767031", ConsumedOnUse = false, Rating = "Uncommon", Enhanceable = false },

	[106] = { ID = 106, Name = "낡은 글러브", Description = "오래 사용하여 닳은 글러브.", Type = "Equipment", Slot = "Weapon", WeaponType = "Fist", Stats = { Attack = 4 }, Stackable = false, Price = 50, SellPrice = 25, ImageId = "rbxassetid://81471471515945", ConsumedOnUse = false, Rating = "Common",
		Enhanceable = true, MaxEnhanceLevel = 5, EnhanceStat = "Attack", EnhanceValuePerLevel = 1
	},
	[107] = { ID = 107, Name = "강철 너클", Description = "주먹에 끼워 파괴력을 높이는 강철 너클.", Type = "Equipment", Slot = "Weapon", WeaponType = "Fist", Stats = { Attack = 9, STR = 1 }, Stackable = false, Price = 280, SellPrice = 140, ImageId = "rbxassetid://110341468360359", ConsumedOnUse = false, Rating = "Uncommon",
		Enhanceable = true, MaxEnhanceLevel = 7, EnhanceStat = "Attack", EnhanceValuePerLevel = 2
	},

	-- 재료 (수정 없음)
	[1001] = { ID = 1001, Name = "젤리", Description = "슬라임 흔적.", Type = "Material", Stackable = true, SellPrice = 1, Price = 2, ImageId = "rbxassetid://133645646714060", ConsumedOnUse = false, Rating = "Common" },
	[1002] = { ID = 1002, Name = "철광석", Description = "철 광석.", Type = "Material", Stackable = true, SellPrice = 3, Price = 6, ImageId = "rbxassetid://90226349090319", ConsumedOnUse = false, Rating = "Common" },
	[1003] = { ID = 1003, Name = "나무 장작", Description = "땔감이나 재료.", Type = "Material", Stackable = true, SellPrice = 1, Price = 2, ImageId = "rbxassetid://84031957599394", ConsumedOnUse = false, Rating = "Common" },
	[402] = { ID = 402, Name = "박쥐 날개", Description = "박쥐 날개.", Type = "Material", Stackable = true, Price = 8, SellPrice = 4, ImageId = "rbxassetid://80989619780409", ConsumedOnUse = false, Rating = "Common" },
	[403] = { ID = 403, Name = "부러진 뼈", Description = "몬스터 뼈.", Type = "Material", Stackable = true, Price = 3, SellPrice = 1, ImageId = "rbxassetid://107786181150802", ConsumedOnUse = false, Rating = "Common" },
	[1004] = { ID = 1004, Name = "마력의 돌", Description = "마력이 느껴지는 돌.", Type = "Material", Stackable = true, Price = 50, SellPrice = 25, ImageId = "rbxassetid://111811519735527", ConsumedOnUse = false, Rating = "Rare" },
	[1005] = { ID = 1005, Name = "낡은 해도 조각", Description = "오래된 해도의 조각.", Type = "Material", Stackable = true, Price = 20, SellPrice = 10, ImageId = "rbxassetid://103879649442552", ConsumedOnUse = false, Rating = "Uncommon" },
	[1006] = { ID = 1006, Name = "해군의 단추", Description = "해군 제복 단추.", Type = "Material", Stackable = true, Price = 5, SellPrice = 2, ImageId = "rbxassetid://118836642440971", ConsumedOnUse = false, Rating = "Common" },
	-- *** [추가] 강화석 아이템 예시 ***
	[1101] = { ID = 1101, Name = "하급 강화석", Description = "장비 강화에 사용되는 기본적인 돌.", Type = "Material", Stackable = true, Price = 100, SellPrice = 50, ImageId = "rbxassetid://107719128481590", Rating = "Common" },
	[1102] = { ID = 1102, Name = "중급 강화석", Description = "보다 높은 레벨의 강화에 사용되는 돌.", Type = "Material", Stackable = true, Price = 500, SellPrice = 250, ImageId = "rbxassetid://91144641717852", Rating = "Uncommon" },
	[1103] = { ID = 1103, Name = "상급 강화석", Description = "희귀하고 강력한 강화에 필요한 돌.", Type = "Material", Stackable = true, Price = 2000, SellPrice = 1000, ImageId = "rbxassetid://110904666073810", Rating = "Rare" },


	-- 기타 (수정 없음)
	[9001] = { ID = 9001, Name = "잡동사니", Description = "쓸모 없어 보이는 물건.", Type = "Etc", Stackable = true, SellPrice = 1, Price = 0, ImageId = "rbxassetid://86494166041349", ConsumedOnUse = false, Rating = "Common" },

	-- 악마의 열매 (수정 없음)
	[5001] = { ID = 5001, Name = "고무고무 열매", Description = "몸이 고무처럼 늘어나는 능력을 얻는다.", Type = "DevilFruit", ImageId = "rbxassetid://103681930908823", Stackable = false, ConsumedOnUse = true, Effect = "GrantDevilFruit", FruitID = "GomuGomu", Price = 1000000, SellPrice = 1, Rating = "Legendary", requiredDF = 10 },
	[5002] = { ID = 5002, Name = "이글이글 열매", Description = "불을 다루는 능력을 얻는다.", Type = "DevilFruit", ImageId = "rbxassetid://105570803146618", Stackable = false, ConsumedOnUse = true, Effect = "GrantDevilFruit", FruitID = "MeraMera", Price = 80000000, SellPrice = 1, Rating = "Legendary" },
}

-- GetItemInfo 함수 (수정 없음)
if not ItemDatabase.GetItemInfo then
	function ItemDatabase.GetItemInfo(itemId)
		local key = tonumber(itemId) or tostring(itemId)
		if ItemDatabase.Items[key] then
			-- 반환 전에 복사본을 만들어 원본 데이터 수정을 방지 (선택적이지만 권장)
			local itemInfoCopy = {}
			for k, v in pairs(ItemDatabase.Items[key]) do
				itemInfoCopy[k] = v
			end
			return itemInfoCopy
		else
			warn("ItemDatabase: 아이템 정보를 찾을 수 없습니다. ID:", itemId)
			return nil
		end
	end
end


return ItemDatabase