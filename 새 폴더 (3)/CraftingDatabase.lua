--[[
  CraftingDatabase (ModuleScript)
  아이템 제작 레시피 정보 저장
]]
local CraftingDatabase = {}

CraftingDatabase.Recipes = {
	[1] = { -- 레시피 ID
		ResultItemID = 101, -- 결과 아이템 ID (예: 포션, ItemDatabase에 정의 필요)
		ResultQuantity = 1, -- 결과 아이템 수량
		Materials = { -- **[수정]** 필요 재료 목록 추가
			{ItemID = 1001, Quantity = 2} -- 예: 젤리 (ItemID 1001) 2개 필요 (ItemDatabase에 정의 필요)
		},
		Category = "Potion" -- 제작 UI 분류용 (선택적)
	},
	[2] = {
		ResultItemID = 201, -- 예: 기본 검 (ItemDatabase에 정의 필요)
		ResultQuantity = 1,
		Materials = {
			{ItemID = 1002, Quantity = 5}, -- 예: 철광석 5개 (ItemDatabase에 정의 필요)
			{ItemID = 1003, Quantity = 1}  -- 예: 나무 장작 1개 (ItemDatabase에 정의 필요)
		},
		Category = "Weapon"
	},
	-- 다른 레시피 추가...
}

return CraftingDatabase
