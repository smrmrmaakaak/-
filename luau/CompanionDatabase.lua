-- ReplicatedStorage > Modules > CompanionDatabase.lua

local CompanionDatabase = {}

CompanionDatabase.Companions = {
	["COMP001"] = { -- ����� �ڷ�
		Name = "����� �ڷ�",
		Description = "������ �˻� ���� ���� �����ְ��� �˻�. ��˷��� ����ϴ� �˻�.",
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
		-- <<< �׽�Ʈ�� ����Ʈ/���� ID �߰� >>>
		AttackEffectImageId = "rbxassetid://122821729104808", -- �÷��̾� �⺻ ���� ����Ʈ ��Ȱ�� (�׽�Ʈ��)
		AttackSfxId = "rbxassetid://8899349982",          -- �÷��̾� �⺻ ���� �Ҹ� ��Ȱ�� (�׽�Ʈ��)
	},
	["COMP002"] = { -- ���̸�
		Name = "���̸�",
		Description = "���� ���������п� ���� ������ ���� �ʺ� ���ػ� ���� ���� ������ ��� ������ �׸��°�. ������ �ٷ�� �ɷ��� �پ��.",
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
		-- <<< �׽�Ʈ�� ����Ʈ/���� ID �߰� >>>
		AttackEffectImageId = "rbxassetid://91345354383237", -- ȸ�� ��ų ����Ʈ ��Ȱ�� (�׽�Ʈ��, �ٸ� �̹����� ��ü ����)
		AttackSfxId = "rbxassetid://2609981431",           -- ȸ�� ��ų �Ҹ� ��Ȱ�� (�׽�Ʈ��, �ٸ� �Ҹ��� ��ü ����)
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
		warn("CompanionDatabase: ���� ������ ã�� �� �����ϴ�. ID:", companionId)
		return nil
	end
end

return CompanionDatabase