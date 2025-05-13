-- ReplicatedStorage > Modules > CompanionDatabase.lua

local CompanionDatabase = {}

CompanionDatabase.Companions = {
	["COMP001"] = { -- 놀러나간 자루
		Name = "놀러나간 자루",
		Description = "떠돌이 검사 그의 꿈은 세계최고의 검사. 삼검류를 사용하는 검사.",
		AppearanceId = "rbxassetid://135576235330122", 
		Rarity = "Epic",
		Role = "Attacker",

		InitialLevel = 1,
		BaseStats = {
			MaxHP = 150, MaxMP = 20,
			STR = 12, AGI = 8, INT = 3, LUK = 5,
		},
		StatGrowth = {
			HP_PerLevel = 15, MP_PerLevel = 2,
			STR_PerLevel = 2, AGI_PerLevel = 1, INT_PerLevel = 0.5, LUK_PerLevel = 0.5,
		},

		EquippableSlots = {"Weapon", "Accessory1"},
		AllowedWeaponTypes = {"Sword"},

		InitialSkills = {"SKILL_ONI_GIRI"}, 
		-- <<< 테스트용 이펙트/사운드 ID 추가 >>>
		AttackEffectImageId = "rbxassetid://122821729104808", -- 플레이어 기본 공격 이펙트 재활용 (테스트용)
		AttackSfxId = "rbxassetid://8899349982",          -- 플레이어 기본 공격 소리 재활용 (테스트용)
	},
	["COMP002"] = { -- 나미리
		Name = "나미리",
		Description = "향해 국비지원학원 에서 교육을 받은 초보 향해사 그의 꿈은 세계의 모든 지도를 그리는것. 날씨를 다루는 능력이 뛰어나다.",
		AppearanceId = "rbxassetid://134454850695294", 
		Rarity = "Rare",
		Role = "Supporter",

		InitialLevel = 1,
		BaseStats = {
			MaxHP = 90, MaxMP = 60,
			STR = 4, AGI = 10, INT = 15, LUK = 8,
		},
		StatGrowth = {
			HP_PerLevel = 8, MP_PerLevel = 6,
			STR_PerLevel = 0.5, AGI_PerLevel = 1, INT_PerLevel = 2, LUK_PerLevel = 1,
		},
		EquippableSlots = {"Weapon", "Accessory1", "Accessory2"},
		AllowedWeaponTypes = {"Staff", "Rod"},

		InitialSkills = {"SKILL_THUNDER_TEMPO"}, 
		-- <<< 테스트용 이펙트/사운드 ID 추가 >>>
		AttackEffectImageId = "rbxassetid://91345354383237", -- 회복 스킬 이펙트 재활용 (테스트용, 다른 이미지로 교체 권장)
		AttackSfxId = "rbxassetid://2609981431",           -- 회복 스킬 소리 재활용 (테스트용, 다른 소리로 교체 권장)
	},
}

function CompanionDatabase.GetCompanionInfo(companionId)
	local template = CompanionDatabase.Companions[companionId]
	if template then
		local copy = {}
		for k, v in pairs(template) do
			if type(v) == "table" then
				local innerCopy = {}
				for ik, iv in pairs(v) do innerCopy[ik] = iv end
				copy[k] = innerCopy
			else
				copy[k] = v
			end
		end
		return copy
	else
		warn("CompanionDatabase: 동료 정보를 찾을 수 없습니다. ID:", companionId)
		return nil
	end
end

return CompanionDatabase