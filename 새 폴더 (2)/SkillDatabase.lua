--[[
  SkillDatabase (ModuleScript)
  게임 내 모든 스킬의 정보를 저장하고 관리합니다.
  *** [수정] 모든 스킬에 Rating 필드 추가 ***
  *** [수정] 상태 이상 효과 관련 스킬 추가 (패기 컨셉 포함) ***
  *** [수정] 악마의 열매 스킬 추가 (고무고무, 이글이글) 및 RequiredFruit 필드 추가 ***
  *** [추가] 스킬 시각 효과를 위한 EffectImageId 필드 추가 ***
  *** [추가] 스킬 효과음 재생을 위한 SfxId 필드 추가 ***
  *** [추가] 무기 종류 연동을 위한 RequiredWeaponType 필드 추가 및 예시 스킬 추가 ***
]]

local SkillDatabase = {}

SkillDatabase.Skills = {
	-- 기존 스킬
	[1] = {
		ID = 1, Name = "강타", Description = "적 하나에게 기본적인 물리 피해를 입힙니다.",
		Cost = 0, Price = 0, EffectType = "DAMAGE", Power = 20, Target = "ENEMY_SINGLE",
		EffectImageId = "rbxassetid://88778755262439", SfxId = "rbxassetid://82196032638341", Rating = "Common"
	},
	[2] = {
		ID = 2, Name = "회복", Description = "자신의 HP를 일정량 회복합니다.",
		Cost = 15, Price = 150, EffectType = "HEAL", Power = 30, Target = "SELF",
		EffectImageId = "rbxassetid://91345354383237", SfxId = "rbxassetid://2609981431", Rating = "Common"
	},
	[4] = {
		ID = 4, Name = "파워 스트라이크", Description = "강력한 일격을 날려 큰 피해를 줍니다.",
		Cost = 25, Price = 300, EffectType = "DAMAGE", Power = 50, Target = "ENEMY_SINGLE",
		EffectImageId = "rbxassetid://132555918459142", SfxId = "rbxassetid://3802270141", Rating = "Uncommon"
	},

	-- 버프 스킬 (패기 컨셉)
	[10] = {
		ID = 10, Name = "무장색 강화", Description = "무장색 패기를 둘러 방어력을 일시적으로 크게 높입니다.",
		Cost = 20, Price = 500, EffectType = "BUFF", Target = "SELF",
		StatusEffect = { ID = "Busoshoku", Duration = 3, Magnitude = 15, Type = "Buff" },
		EffectImageId = "rbxassetid://YOUR_BUSOSHOKU_EFFECT_ID", SfxId = "rbxassetid://979751563", Rating = "Rare"
	},
	[11] = {
		ID = 11, Name = "견문색 발현", Description = "견문색 패기를 사용하여 적의 공격을 회피할 확률을 높입니다.",
		Cost = 18, Price = 600, EffectType = "BUFF", Target = "SELF",
		StatusEffect = { ID = "Kenbunshoku", Duration = 3, Magnitude = 30, Type = "Buff" },
		EffectImageId = "rbxassetid://YOUR_KENBUNSHOKU_EFFECT_ID", SfxId = "rbxassetid://7123371384", Rating = "Rare"
	},
	[12] = {
		ID = 12, Name = "지속 회복", Description = "몇 턴에 걸쳐 HP를 서서히 회복합니다.",
		Cost = 22, Price = 400, EffectType = "BUFF", Target = "SELF",
		StatusEffect = { ID = "Regen", Duration = 4, Magnitude = 15, Type = "Buff" },
		EffectImageId = "rbxassetid://91345354383237", SfxId = "rbxassetid://YOUR_BUFF_SFX_ID", Rating = "Uncommon"
	},

	-- 디버프 스킬
	[20] = {
		ID = 20, Name = "독 안개", Description = "적에게 독 안개를 뿌려 매 턴 지속적인 피해를 입힙니다.",
		Cost = 15, Price = 350, EffectType = "DEBUFF", Target = "ENEMY_SINGLE",
		StatusEffect = { ID = "Poison", Duration = 3, Magnitude = 10, Type = "Debuff" },
		EffectImageId = "rbxassetid://YOUR_POISON_EFFECT_ID", SfxId = "rbxassetid://YOUR_DEBUFF_SFX_ID", Rating = "Uncommon"
	},
	[21] = {
		ID = 21, Name = "쇠약 저주", Description = "적에게 저주를 걸어 공격력을 약화시킵니다.",
		Cost = 12, Price = 300, EffectType = "DEBUFF", Target = "ENEMY_SINGLE",
		StatusEffect = { ID = "AttackDown", Duration = 3, Magnitude = -8, Type = "Debuff" },
		EffectImageId = "rbxassetid://YOUR_DEBUFF_EFFECT_ID", SfxId = "rbxassetid://YOUR_DEBUFF_SFX_ID", Rating = "Uncommon"
	},
	[22] = {
		ID = 22, Name = "방어구 부수기", Description = "적의 방어구를 약화시켜 방어력을 감소시킵니다.",
		Cost = 18, Price = 450, EffectType = "DEBUFF", Target = "ENEMY_SINGLE",
		StatusEffect = { ID = "DefenseDown", Duration = 3, Magnitude = -10, Type = "Debuff" },
		EffectImageId = "rbxassetid://YOUR_ARMOR_BREAK_EFFECT_ID", SfxId = "rbxassetid://82196032638341", Rating = "Rare"
	},

	-- 무기 종류 연동 스킬 예시
	[100] = {
		ID = 100, Name = "쾌속 베기", Description = "빠르게 검을 휘둘러 피해를 줍니다.",
		Cost = 10, Price = 200, EffectType = "DAMAGE", Power = 30, Target = "ENEMY_SINGLE",
		RequiredWeaponType = "Sword", EffectImageId = "rbxassetid://PLACEHOLDER_SWORD_SLASH_EFFECT",
		SfxId = "rbxassetid://PLACEHOLDER_SWORD_SLASH_SFX", Rating = "Uncommon"
	},
	[101] = {
		ID = 101, Name = "집중 타격", Description = "기를 모아 강력한 주먹을 날립니다.",
		Cost = 15, Price = 250, EffectType = "DAMAGE", Power = 40, Target = "ENEMY_SINGLE",
		RequiredWeaponType = "Fist", EffectImageId = "rbxassetid://PLACEHOLDER_FIST_PUNCH_EFFECT",
		SfxId = "rbxassetid://PLACEHOLDER_FIST_PUNCH_SFX", Rating = "Uncommon"
	},
	[102] = {
		ID = 102, Name = "조준 사격", Description = "적의 약점을 노려 정확하게 사격합니다.",
		Cost = 12, Price = 300, EffectType = "DAMAGE", Power = 35, Target = "ENEMY_SINGLE",
		RequiredWeaponType = "Gun", EffectImageId = "rbxassetid://PLACEHOLDER_GUN_SHOT_EFFECT",
		SfxId = "rbxassetid://PLACEHOLDER_GUN_SHOT_SFX", Rating = "Rare"
	},

	-- 악마의 열매 스킬 (고무고무 열매)
	["Skill_GomuGomuPistol"] = {
		ID = "Skill_GomuGomuPistol", Name = "고무고무 피스톨", Description = "팔을 늘려 강력한 펀치를 날립니다.",
		Cost = 10, Price = 0, EffectType = "DAMAGE", Power = 35, Target = "ENEMY_SINGLE",
		RequiredFruit = "GomuGomu", EffectImageId = "rbxassetid://111832049081519",
		SfxId = "rbxassetid://YOUR_GOMUGOMU_PISTOL_SFX_ID", Rating = "Epic"
	},
	["Skill_GomuGomuRocket"] = {
		ID = "Skill_GomuGomuRocket", Name = "고무고무 로켓", Description = "몸을 늘려 적에게 빠르게 접근하며 공격합니다. (구현 시 추가 효과 가능)",
		Cost = 15, Price = 0, EffectType = "DAMAGE", Power = 45, Target = "ENEMY_SINGLE",
		RequiredFruit = "GomuGomu", EffectImageId = "rbxassetid://YOUR_GOMUGOMU_ROCKET_EFFECT_ID",
		SfxId = "rbxassetid://YOUR_GOMUGOMU_ROCKET_SFX_ID", Rating = "Epic"
	},

	-- 악마의 열매 스킬 (이글이글 열매)
	["Skill_MeraMeraHiken"] = {
		ID = "Skill_MeraMeraHiken", Name = "화권", Description = "거대한 불 주먹을 날려 적에게 큰 화염 피해를 줍니다.",
		Cost = 30, Price = 0, EffectType = "DAMAGE", Power = 60, Target = "ENEMY_SINGLE",
		RequiredFruit = "MeraMera", EffectImageId = "rbxassetid://92038608823441",
		SfxId = "rbxassetid://7405939280", Rating = "Legendary"
	},
	["Skill_MeraMeraKagero"] = {
		ID = "Skill_MeraMeraKagero", Name = "아지랑이", Description = "몸을 아지랑이처럼 만들어 적의 공격을 회피할 확률을 잠시 높입니다.",
		Cost = 20, Price = 0, EffectType = "BUFF", Target = "SELF",
		RequiredFruit = "MeraMera", StatusEffect = { ID = "Kenbunshoku", Duration = 2, Magnitude = 50, Type = "Buff" },
		EffectImageId = "rbxassetid://YOUR_MERA_KAGERO_EFFECT_ID", SfxId = "rbxassetid://2674547670", Rating = "Legendary"
	},
	
	-- ##### [추가] 동료 스킬 정의 #####
	["SKILL_ONI_GIRI"] = { -- 문자열 키로 정의
		ID = "SKILL_ONI_GIRI", 
		Name = "귀참 (鬼斬り)", 
		Description = "삼검을 교차하며 돌진하여 적을 베는 기술.",
		Cost = 20, -- MP 소모량 (예시)
		Price = 0, -- 상점 판매 가격 (0이면 구매 불가 또는 기본 습득)
		EffectType = "DAMAGE", -- 효과 유형 (데미지)
		Power = 40, -- 스킬 위력 (데미지 계산 시 사용)
		Target = "ENEMY_SINGLE", -- 타겟 유형 (단일 적)
		RequiredWeaponType = "Sword", -- 필요 무기 타입 (선택적)
		EffectImageId = "rbxassetid://YOUR_ONI_GIRI_EFFECT_ID", -- 스킬 시각 효과 ID
		SfxId = "rbxassetid://YOUR_ONI_GIRI_SFX_ID", -- 스킬 효과음 ID
		Rating = "Rare" -- 스킬 등급
	},
	["SKILL_THUNDER_TEMPO"] = { -- 문자열 키로 정의
		ID = "SKILL_THUNDER_TEMPO", 
		Name = "썬더 템포 (Thunder Tempo)", 
		Description = "크리마 택트를 이용해 적에게 작은 뇌운을 만들어 번개를 떨어뜨린다.",
		Cost = 25,
		Price = 0,
		EffectType = "DAMAGE",
		DamageType = "Magic", -- 마법 데미지 타입 추가 가능
		Power = 35,
		Target = "ENEMY_SINGLE",
		RequiredWeaponType = "Staff", -- 예시: 크리마 택트
		EffectImageId = "rbxassetid://YOUR_THUNDER_TEMPO_EFFECT_ID",
		SfxId = "rbxassetid://YOUR_THUNDER_TEMPO_SFX_ID",
		Rating = "Rare"
	},
	-- ##### 추가 끝 #####

}


return SkillDatabase