--[[
  SkillDatabase (ModuleScript)
  ���� �� ��� ��ų�� ������ �����ϰ� �����մϴ�.
  *** [����] ��� ��ų�� Rating �ʵ� �߰� ***
  *** [����] ���� �̻� ȿ�� ���� ��ų �߰� (�б� ���� ����) ***
  *** [����] �Ǹ��� ���� ��ų �߰� (����, �̱��̱�) �� RequiredFruit �ʵ� �߰� ***
  *** [�߰�] ��ų �ð� ȿ���� ���� EffectImageId �ʵ� �߰� ***
  *** [�߰�] ��ų ȿ���� ����� ���� SfxId �ʵ� �߰� ***
  *** [�߰�] ���� ���� ������ ���� RequiredWeaponType �ʵ� �߰� �� ���� ��ų �߰� ***
]]

local SkillDatabase = {}

SkillDatabase.Skills = {
	-- ���� ��ų
	[1] = {
		ID = 1, Name = "��Ÿ", Description = "�� �ϳ����� �⺻���� ���� ���ظ� �����ϴ�.",
		Cost = 0, Price = 0, EffectType = "DAMAGE", Power = 20, Target = "ENEMY_SINGLE",
		EffectImageId = "rbxassetid://88778755262439", SfxId = "rbxassetid://82196032638341", Rating = "Common"
	},
	[2] = {
		ID = 2, Name = "ȸ��", Description = "�ڽ��� HP�� ������ ȸ���մϴ�.",
		Cost = 15, Price = 150, EffectType = "HEAL", Power = 30, Target = "SELF",
		EffectImageId = "rbxassetid://91345354383237", SfxId = "rbxassetid://2609981431", Rating = "Common"
	},
	[4] = {
		ID = 4, Name = "�Ŀ� ��Ʈ����ũ", Description = "������ �ϰ��� ���� ū ���ظ� �ݴϴ�.",
		Cost = 25, Price = 300, EffectType = "DAMAGE", Power = 50, Target = "ENEMY_SINGLE",
		EffectImageId = "rbxassetid://132555918459142", SfxId = "rbxassetid://3802270141", Rating = "Uncommon"
	},

	-- ���� ��ų (�б� ����)
	[10] = {
		ID = 10, Name = "����� ��ȭ", Description = "����� �б⸦ �ѷ� ������ �Ͻ������� ũ�� ���Դϴ�.",
		Cost = 20, Price = 500, EffectType = "BUFF", Target = "SELF",
		StatusEffect = { ID = "Busoshoku", Duration = 3, Magnitude = 15, Type = "Buff" },
		EffectImageId = "rbxassetid://YOUR_BUSOSHOKU_EFFECT_ID", SfxId = "rbxassetid://979751563", Rating = "Rare"
	},
	[11] = {
		ID = 11, Name = "�߹��� ����", Description = "�߹��� �б⸦ ����Ͽ� ���� ������ ȸ���� Ȯ���� ���Դϴ�.",
		Cost = 18, Price = 600, EffectType = "BUFF", Target = "SELF",
		StatusEffect = { ID = "Kenbunshoku", Duration = 3, Magnitude = 30, Type = "Buff" },
		EffectImageId = "rbxassetid://YOUR_KENBUNSHOKU_EFFECT_ID", SfxId = "rbxassetid://7123371384", Rating = "Rare"
	},
	[12] = {
		ID = 12, Name = "���� ȸ��", Description = "�� �Ͽ� ���� HP�� ������ ȸ���մϴ�.",
		Cost = 22, Price = 400, EffectType = "BUFF", Target = "SELF",
		StatusEffect = { ID = "Regen", Duration = 4, Magnitude = 15, Type = "Buff" },
		EffectImageId = "rbxassetid://91345354383237", SfxId = "rbxassetid://YOUR_BUFF_SFX_ID", Rating = "Uncommon"
	},

	-- ����� ��ų
	[20] = {
		ID = 20, Name = "�� �Ȱ�", Description = "������ �� �Ȱ��� �ѷ� �� �� �������� ���ظ� �����ϴ�.",
		Cost = 15, Price = 350, EffectType = "DEBUFF", Target = "ENEMY_SINGLE",
		StatusEffect = { ID = "Poison", Duration = 3, Magnitude = 10, Type = "Debuff" },
		EffectImageId = "rbxassetid://YOUR_POISON_EFFECT_ID", SfxId = "rbxassetid://YOUR_DEBUFF_SFX_ID", Rating = "Uncommon"
	},
	[21] = {
		ID = 21, Name = "��� ����", Description = "������ ���ָ� �ɾ� ���ݷ��� ��ȭ��ŵ�ϴ�.",
		Cost = 12, Price = 300, EffectType = "DEBUFF", Target = "ENEMY_SINGLE",
		StatusEffect = { ID = "AttackDown", Duration = 3, Magnitude = -8, Type = "Debuff" },
		EffectImageId = "rbxassetid://YOUR_DEBUFF_EFFECT_ID", SfxId = "rbxassetid://YOUR_DEBUFF_SFX_ID", Rating = "Uncommon"
	},
	[22] = {
		ID = 22, Name = "�� �μ���", Description = "���� ���� ��ȭ���� ������ ���ҽ�ŵ�ϴ�.",
		Cost = 18, Price = 450, EffectType = "DEBUFF", Target = "ENEMY_SINGLE",
		StatusEffect = { ID = "DefenseDown", Duration = 3, Magnitude = -10, Type = "Debuff" },
		EffectImageId = "rbxassetid://YOUR_ARMOR_BREAK_EFFECT_ID", SfxId = "rbxassetid://82196032638341", Rating = "Rare"
	},

	-- ���� ���� ���� ��ų ����
	[100] = {
		ID = 100, Name = "��� ����", Description = "������ ���� �ֵѷ� ���ظ� �ݴϴ�.",
		Cost = 10, Price = 200, EffectType = "DAMAGE", Power = 30, Target = "ENEMY_SINGLE",
		RequiredWeaponType = "Sword", EffectImageId = "rbxassetid://PLACEHOLDER_SWORD_SLASH_EFFECT",
		SfxId = "rbxassetid://PLACEHOLDER_SWORD_SLASH_SFX", Rating = "Uncommon"
	},
	[101] = {
		ID = 101, Name = "���� Ÿ��", Description = "�⸦ ��� ������ �ָ��� �����ϴ�.",
		Cost = 15, Price = 250, EffectType = "DAMAGE", Power = 40, Target = "ENEMY_SINGLE",
		RequiredWeaponType = "Fist", EffectImageId = "rbxassetid://PLACEHOLDER_FIST_PUNCH_EFFECT",
		SfxId = "rbxassetid://PLACEHOLDER_FIST_PUNCH_SFX", Rating = "Uncommon"
	},
	[102] = {
		ID = 102, Name = "���� ���", Description = "���� ������ ��� ��Ȯ�ϰ� ����մϴ�.",
		Cost = 12, Price = 300, EffectType = "DAMAGE", Power = 35, Target = "ENEMY_SINGLE",
		RequiredWeaponType = "Gun", EffectImageId = "rbxassetid://PLACEHOLDER_GUN_SHOT_EFFECT",
		SfxId = "rbxassetid://PLACEHOLDER_GUN_SHOT_SFX", Rating = "Rare"
	},

	-- �Ǹ��� ���� ��ų (���� ����)
	["Skill_GomuGomuPistol"] = {
		ID = "Skill_GomuGomuPistol", Name = "���� �ǽ���", Description = "���� �÷� ������ ��ġ�� �����ϴ�.",
		Cost = 10, Price = 0, EffectType = "DAMAGE", Power = 35, Target = "ENEMY_SINGLE",
		RequiredFruit = "GomuGomu", EffectImageId = "rbxassetid://111832049081519",
		SfxId = "rbxassetid://YOUR_GOMUGOMU_PISTOL_SFX_ID", Rating = "Epic"
	},
	["Skill_GomuGomuRocket"] = {
		ID = "Skill_GomuGomuRocket", Name = "���� ����", Description = "���� �÷� ������ ������ �����ϸ� �����մϴ�. (���� �� �߰� ȿ�� ����)",
		Cost = 15, Price = 0, EffectType = "DAMAGE", Power = 45, Target = "ENEMY_SINGLE",
		RequiredFruit = "GomuGomu", EffectImageId = "rbxassetid://YOUR_GOMUGOMU_ROCKET_EFFECT_ID",
		SfxId = "rbxassetid://YOUR_GOMUGOMU_ROCKET_SFX_ID", Rating = "Epic"
	},

	-- �Ǹ��� ���� ��ų (�̱��̱� ����)
	["Skill_MeraMeraHiken"] = {
		ID = "Skill_MeraMeraHiken", Name = "ȭ��", Description = "�Ŵ��� �� �ָ��� ���� ������ ū ȭ�� ���ظ� �ݴϴ�.",
		Cost = 30, Price = 0, EffectType = "DAMAGE", Power = 60, Target = "ENEMY_SINGLE",
		RequiredFruit = "MeraMera", EffectImageId = "rbxassetid://92038608823441",
		SfxId = "rbxassetid://7405939280", Rating = "Legendary"
	},
	["Skill_MeraMeraKagero"] = {
		ID = "Skill_MeraMeraKagero", Name = "��������", Description = "���� ��������ó�� ����� ���� ������ ȸ���� Ȯ���� ��� ���Դϴ�.",
		Cost = 20, Price = 0, EffectType = "BUFF", Target = "SELF",
		RequiredFruit = "MeraMera", StatusEffect = { ID = "Kenbunshoku", Duration = 2, Magnitude = 50, Type = "Buff" },
		EffectImageId = "rbxassetid://YOUR_MERA_KAGERO_EFFECT_ID", SfxId = "rbxassetid://2674547670", Rating = "Legendary"
	},
	
	-- ##### [�߰�] ���� ��ų ���� #####
	["SKILL_ONI_GIRI"] = { -- ���ڿ� Ű�� ����
		ID = "SKILL_ONI_GIRI", 
		Name = "���� (С�֪�)", 
		Description = "����� �����ϸ� �����Ͽ� ���� ���� ���.",
		Cost = 20, -- MP �Ҹ� (����)
		Price = 0, -- ���� �Ǹ� ���� (0�̸� ���� �Ұ� �Ǵ� �⺻ ����)
		EffectType = "DAMAGE", -- ȿ�� ���� (������)
		Power = 40, -- ��ų ���� (������ ��� �� ���)
		Target = "ENEMY_SINGLE", -- Ÿ�� ���� (���� ��)
		RequiredWeaponType = "Sword", -- �ʿ� ���� Ÿ�� (������)
		EffectImageId = "rbxassetid://YOUR_ONI_GIRI_EFFECT_ID", -- ��ų �ð� ȿ�� ID
		SfxId = "rbxassetid://YOUR_ONI_GIRI_SFX_ID", -- ��ų ȿ���� ID
		Rating = "Rare" -- ��ų ���
	},
	["SKILL_THUNDER_TEMPO"] = { -- ���ڿ� Ű�� ����
		ID = "SKILL_THUNDER_TEMPO", 
		Name = "��� ���� (Thunder Tempo)", 
		Description = "ũ���� ��Ʈ�� �̿��� ������ ���� ������ ����� ������ ����߸���.",
		Cost = 25,
		Price = 0,
		EffectType = "DAMAGE",
		DamageType = "Magic", -- ���� ������ Ÿ�� �߰� ����
		Power = 35,
		Target = "ENEMY_SINGLE",
		RequiredWeaponType = "Staff", -- ����: ũ���� ��Ʈ
		EffectImageId = "rbxassetid://YOUR_THUNDER_TEMPO_EFFECT_ID",
		SfxId = "rbxassetid://YOUR_THUNDER_TEMPO_SFX_ID",
		Rating = "Rare"
	},
	-- ##### �߰� �� #####

}


return SkillDatabase