-- DevilFruitDatabase ��� ��ũ��Ʈ
-- ����: ���� �� ��� �Ǹ��� ���� ������ �����ϰ� �����մϴ�.
-- ��ġ: ServerScriptService �Ǵ� ReplicatedStorage

local DevilFruitDatabase = {}

-- Fruits ���̺�: ��� �Ǹ��� ���� ������ �����ϴ� ���Դϴ�.
-- �� ���Ŵ� ������ ID (��: "GomuGomu")�� Ű(key)�� �����ϴ�.
DevilFruitDatabase.Fruits = {
	["GomuGomu"] = { -- ���� ������ ���� ID
		Name = "���� ����", -- ������ �̸� (UI � ǥ�õ� �̸�)
		Description = "���� ��ó�� �þ�� �ɷ��� ��´�.", -- ���ſ� ���� ����
		Type = "���ΰ�", -- ������ �迭 (��: ���ΰ�, �ڿ���, ������)
		GrantedSkills = {"Skill_GomuGomuPistol", "Skill_GomuGomuRocket"} -- �� ���Ÿ� �Ծ��� �� ��� �Ǵ� ��ų���� ID ��� (SkillDatabase.lua �� ���ǵ� ID)
		-- �ʿ��ϴٸ� ���⿡ �߰� �������� �� ���� �� �ֽ��ϴ�.
		-- ��: Icon = "rbxassetid://...", -- ���� ������ �̹��� ID
		-- ��: Rarity = "Legendary", -- ��͵�
	},
	["MeraMera"] = { -- �̱��̱� ������ ���� ID
		Name = "�̱��̱� ����",
		Description = "������ ���� �ٷ�� �ɷ��� ��´�.",
		Type = "�ڿ���",
		GrantedSkills = {"Skill_MeraMeraHiken", "Skill_MeraMeraKagero"}
	},
	-- [[ ���⿡ �ٸ� �Ǹ��� ���� �������� �߰��ϼ��� ]]
	-- ����:
	-- ["BaraBara"] = {
	--     Name = "�������� ����",
	--     Description = "���� �������� �и��Ǵ� �ɷ��� ��´�.",
	--     Type = "���ΰ�",
	--     GrantedSkills = {"Skill_BaraBaraFestival", "Skill_BaraBaraHo"}
	-- },
}

-- GetFruitInfo �Լ�: ������ ���� ID�� �Է¹޾� �ش� ������ ���� ���̺��� ��ȯ�մϴ�.
-- �ٸ� ��ũ��Ʈ���� Ư�� ������ ������ ������ �� ���˴ϴ�.
-- ��� ����: local gomuGomuInfo = DevilFruitDatabase.GetFruitInfo("GomuGomu")
function DevilFruitDatabase.GetFruitInfo(fruitId)
	-- ���� Fruits ���̺� �ȿ� �ش� fruitId�� ���� ���� ������ �ִٸ�
	if DevilFruitDatabase.Fruits[fruitId] then
		-- �ش� ���� ���� ���̺��� ��ȯ�մϴ�.
		return DevilFruitDatabase.Fruits[fruitId]
	else
		-- ���� �ش� fruitId�� ���� ���� ������ ���ٸ�, ��� �޽����� ����ϰ� nil�� ��ȯ�մϴ�.
		warn("Warning: �Ǹ��� ���� ������ ã�� �� �����ϴ� - ID:", fruitId)
		return nil
	end
end

-- �� ��� ��ũ��Ʈ ��ü(DevilFruitDatabase ���̺�)�� ��ȯ�մϴ�.
-- �ٸ� ��ũ��Ʈ���� require() �Լ��� ���� �� ����� �ҷ��� ����� �� �ְ� �մϴ�.
return DevilFruitDatabase
