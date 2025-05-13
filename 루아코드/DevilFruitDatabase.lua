-- DevilFruitDatabase 모듈 스크립트
-- 역할: 게임 내 모든 악마의 열매 정보를 저장하고 제공합니다.
-- 위치: ServerScriptService 또는 ReplicatedStorage

local DevilFruitDatabase = {}

-- Fruits 테이블: 모든 악마의 열매 정보를 저장하는 곳입니다.
-- 각 열매는 고유한 ID (예: "GomuGomu")를 키(key)로 가집니다.
DevilFruitDatabase.Fruits = {
	["GomuGomu"] = { -- 고무고무 열매의 고유 ID
		Name = "고무고무 열매", -- 열매의 이름 (UI 등에 표시될 이름)
		Description = "몸이 고무처럼 늘어나는 능력을 얻는다.", -- 열매에 대한 설명
		Type = "초인계", -- 열매의 계열 (예: 초인계, 자연계, 동물계)
		GrantedSkills = {"Skill_GomuGomuPistol", "Skill_GomuGomuRocket"} -- 이 열매를 먹었을 때 얻게 되는 스킬들의 ID 목록 (SkillDatabase.lua 에 정의될 ID)
		-- 필요하다면 여기에 추가 정보들을 더 넣을 수 있습니다.
		-- 예: Icon = "rbxassetid://...", -- 열매 아이콘 이미지 ID
		-- 예: Rarity = "Legendary", -- 희귀도
	},
	["MeraMera"] = { -- 이글이글 열매의 고유 ID
		Name = "이글이글 열매",
		Description = "몸에서 불을 다루는 능력을 얻는다.",
		Type = "자연계",
		GrantedSkills = {"Skill_MeraMeraHiken", "Skill_MeraMeraKagero"}
	},
	-- [[ 여기에 다른 악마의 열매 정보들을 추가하세요 ]]
	-- 예시:
	-- ["BaraBara"] = {
	--     Name = "동강동강 열매",
	--     Description = "몸이 동강동강 분리되는 능력을 얻는다.",
	--     Type = "초인계",
	--     GrantedSkills = {"Skill_BaraBaraFestival", "Skill_BaraBaraHo"}
	-- },
}

-- GetFruitInfo 함수: 열매의 고유 ID를 입력받아 해당 열매의 정보 테이블을 반환합니다.
-- 다른 스크립트에서 특정 열매의 정보를 가져올 때 사용됩니다.
-- 사용 예시: local gomuGomuInfo = DevilFruitDatabase.GetFruitInfo("GomuGomu")
function DevilFruitDatabase.GetFruitInfo(fruitId)
	-- 만약 Fruits 테이블 안에 해당 fruitId를 가진 열매 정보가 있다면
	if DevilFruitDatabase.Fruits[fruitId] then
		-- 해당 열매 정보 테이블을 반환합니다.
		return DevilFruitDatabase.Fruits[fruitId]
	else
		-- 만약 해당 fruitId를 가진 열매 정보가 없다면, 경고 메시지를 출력하고 nil을 반환합니다.
		warn("Warning: 악마의 열매 정보를 찾을 수 없습니다 - ID:", fruitId)
		return nil
	end
end

-- 이 모듈 스크립트 자체(DevilFruitDatabase 테이블)를 반환합니다.
-- 다른 스크립트에서 require() 함수를 통해 이 모듈을 불러와 사용할 수 있게 합니다.
return DevilFruitDatabase
