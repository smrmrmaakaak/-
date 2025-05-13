--[[
  EnemyDatabase (ModuleScript)
  ���ӿ� �����ϴ� ��(����) ������ ����
  *** [����] ����/�ر� �׸� ���� �߰� ***
  *** [����] ������(ID:1) �����Ϳ� ImageId �ʵ� �߰� ***
]]
local EnemyDatabase = {}

EnemyDatabase.Enemies = {
	-- ���� ����
	[1] = { -- ������
		ID = 1, Name = "������", Level = 1, MaxHP = 30, Attack = 5, DEF = 2,
		ExpReward = 10000, GoldReward = 50000, -- ����ġ ���� ����
		ImageId = "rbxassetid://139610831731863", -- *** �߰�: ������ �̹��� ID (���� ID�� ��ü �ʿ�) ***
		Drops = {
			{ ItemID = 1001, Chance = 0.7, Quantity = 1 }, -- ���� 70%
			{ ItemID = 1, Chance = 0.1, Quantity = 1 }    -- HP ���� 10%
		}
	},
	[2] = { -- ����
		ID = 2, Name = "����", Level = 3, MaxHP = 70, Attack = 8, DEF = 4,
		ExpReward = 25, GoldReward = 12,
		ImageId = "rbxassetid://208066789012345", -- ���� �̹��� ID (����)
		Drops = {
			{ ItemID = 402, Chance = 0.6, Quantity = 1 }, -- ���� ���� 60%
			{ ItemID = 2, Chance = 0.05, Quantity = 1 }   -- MP ���� 5%
		}
	},
	[3] = { -- ���̷���
		ID = 3, Name = "���̷���", Level = 5, MaxHP = 120, Attack = 12, DEF = 6,
		ExpReward = 40, GoldReward = 20,
		ImageId = "rbxassetid://86654621036939", -- ���̷��� �̹��� ID (����)
		Drops = {
			{ ItemID = 403, Chance = 0.5, Quantity = 1 }, -- �η��� �� 50%
			{ ItemID = 102, Chance = 0.05, Quantity = 1}  -- ���� �ܰ� 5%
		}
	},
	[4] = { -- ���
		ID = 4, Name = "���", Level = 4, MaxHP = 90, Attack = 10, DEF = 5,
		ExpReward = 35, GoldReward = 15,
		ImageId = "rbxassetid://109033948393929", -- ��� �̹��� ID (����)
		Drops = {
			{ ItemID = 1002, Chance = 0.3, Quantity = 1 }, -- ö���� 30%
			{ ItemID = 9001, Chance = 0.2, Quantity = 1 }, -- �⵿��� 20%
			{ ItemID = 202, Chance = 0.03, Quantity = 1 }, -- ���� ���� 3%
		}
	},
	[5] = { -- ��ũ
		ID = 5, Name = "��ũ", Level = 7, MaxHP = 200, Attack = 18, DEF = 10,
		ExpReward = 70, GoldReward = 40,
		ImageId = "rbxassetid://136237872671206", -- ��ũ �̹��� ID (����)
		Drops = {
			{ ItemID = 1003, Chance = 0.4, Quantity = 2 }, -- ���� ���� 40% (2��)
			{ ItemID = 1004, Chance = 0.1, Quantity = 1 }, -- ������ �� 10%
			{ ItemID = 103, Chance = 0.02, Quantity = 1 }, -- ��ö �� 2%
		}
	},

	-- *** [�ű�] ���� �׸� ���� ***
	[6] = { -- ���� Į����
		ID = 6, Name = "���� Į����", Level = 8, MaxHP = 250, Attack = 22, DEF = 8,
		ExpReward = 85, GoldReward = 50,
		ImageId = "rbxassetid://127349921664378", -- ���� �̹��� ID (����)
		-- Skills = { ... }, -- �ʿ�� ��ų �߰�
		Drops = {
			{ ItemID = 4, Chance = 0.2, Quantity = 1 },    -- ���� 20%
			{ ItemID = 1005, Chance = 0.1, Quantity = 1 }, -- ���� �ص� ���� 10%
			{ ItemID = 104, Chance = 0.03, Quantity = 1 }, -- ���� ĿƲ���� 3%
		}
	},
	[7] = { -- ���� ����
		ID = 7, Name = "���� ����", Level = 9, MaxHP = 220, Attack = 25, DEF = 6, -- ���ݷ� ���� ���� ����
		ExpReward = 90, GoldReward = 55,
		ImageId = "rbxassetid://112535677076979", -- ���� �̹��� ID (����)
		Drops = {
			{ ItemID = 4, Chance = 0.15, Quantity = 1 },   -- ���� 15%
			{ ItemID = 9001, Chance = 0.3, Quantity = 1 },  -- �⵿��� 30%
			{ ItemID = 304, Chance = 0.02, Quantity = 1 }, -- ���� �ȴ� 2%
		}
	},

	-- *** [�ű�] �ر� �׸� ���� ***
	[8] = { -- �ر� ����
		ID = 8, Name = "�ر� ����", Level = 10, MaxHP = 300, Attack = 20, DEF = 15, -- ���� ����
		ExpReward = 100, GoldReward = 60,
		ImageId = "rbxassetid://122841225189417", -- �ر� ���� �̹��� ID (����)
		Drops = {
			{ ItemID = 1, Chance = 0.1, Quantity = 2 },    -- HP ���� 10% (2��)
			{ ItemID = 1006, Chance = 0.2, Quantity = 1 }, -- �ر��� ���� 20%
			{ ItemID = 105, Chance = 0.02, Quantity = 1 }, -- �ر� ���� ���� 2%
		}
	},
	[9] = { -- �ر� �屳
		ID = 9, Name = "�ر� �屳", Level = 12, MaxHP = 350, Attack = 24, DEF = 18,
		ExpReward = 150, GoldReward = 80,
		ImageId = "rbxassetid://139037740235144", -- �ر� �屳 �̹��� ID (����)
		-- Skills = { ... }, -- �ʿ�� ��ų �߰� (��: �Ʊ� ����)
		Drops = {
			{ ItemID = 3, Chance = 0.05, Quantity = 1 },    -- ������ 5%
			{ ItemID = 305, Chance = 0.1, Quantity = 1 },  -- �ر� �ν�ǥ 10%
			{ ItemID = 206, Chance = 0.01, Quantity = 1 }, -- �ر� ���� 1% (���)
		}
	},
}

return EnemyDatabase
