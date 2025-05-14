-- EnhancementDatabase.lua (�ű� ����)

local EnhancementDatabase = {}

-- ��ȭ ������ ����
-- Ű: ��ȭ �õ� ���� (��: 1 �� +0 -> +1 ��ȭ �õ�)
EnhancementDatabase.Levels = {
	[1] = { -- +0 -> +1 ��ȭ �õ�
		Materials = { {ItemID = 1101, Quantity = 1} }, -- �ϱ� ��ȭ�� 1��
		GoldCost = 100,
		SuccessRate = 0.95 -- 95% ���� Ȯ��
		-- FailPenalty = { MaterialLoss = true } -- ���� �� ��Ḹ �Ҹ� (�⺻��)
	},
	[2] = { -- +1 -> +2 ��ȭ �õ�
		Materials = { {ItemID = 1101, Quantity = 2} }, -- �ϱ� ��ȭ�� 2��
		GoldCost = 250,
		SuccessRate = 0.90 -- 90%
	},
	[3] = { -- +2 -> +3 ��ȭ �õ�
		Materials = { {ItemID = 1101, Quantity = 3} }, -- �ϱ� ��ȭ�� 3��
		GoldCost = 500,
		SuccessRate = 0.80 -- 80%
	},
	[4] = { -- +3 -> +4 ��ȭ �õ�
		Materials = { {ItemID = 1101, Quantity = 5}, {ItemID = 1002, Quantity = 2} }, -- �ϱ� 5��, ö���� 2��
		GoldCost = 1000,
		SuccessRate = 0.70 -- 70%
	},
	[5] = { -- +4 -> +5 ��ȭ �õ�
		Materials = { {ItemID = 1102, Quantity = 1} }, -- �߱� ��ȭ�� 1��
		GoldCost = 2000,
		SuccessRate = 0.60 -- 60%
		-- FailPenalty = { MaterialLoss = true, LevelDecrease = 1 } -- ���� �� ��� �Ҹ� �� ���� 1 �϶� (������)
	},
	[6] = { -- +5 -> +6 ��ȭ �õ�
		Materials = { {ItemID = 1102, Quantity = 2} }, -- �߱� ��ȭ�� 2��
		GoldCost = 4000,
		SuccessRate = 0.50 -- 50%
	},
	[7] = { -- +6 -> +7 ��ȭ �õ�
		Materials = { {ItemID = 1102, Quantity = 3}, {ItemID = 1004, Quantity = 1} }, -- �߱� 3��, ������ �� 1��
		GoldCost = 8000,
		SuccessRate = 0.40 -- 40%
	},
	[8] = { -- +7 -> +8 ��ȭ �õ�
		Materials = { {ItemID = 1103, Quantity = 1} }, -- ��� ��ȭ�� 1��
		GoldCost = 15000,
		SuccessRate = 0.30 -- 30%
		-- FailPenalty = { MaterialLoss = true, DestroyItem = 0.1 } -- ���� �� ��� �Ҹ�, 10% Ȯ���� ������ �ı� (������)
	},
	[9] = { -- +8 -> +9 ��ȭ �õ�
		Materials = { {ItemID = 1103, Quantity = 2} },
		GoldCost = 30000,
		SuccessRate = 0.20 -- 20%
	},
	[10] = { -- +9 -> +10 ��ȭ �õ�
		Materials = { {ItemID = 1103, Quantity = 3} },
		GoldCost = 50000,
		SuccessRate = 0.10 -- 10%
	},
	-- �ʿ信 ���� �� ���� ���� �߰�
}

-- Ư�� ��ȭ ������ ���� ���� ��ȯ �Լ�
function EnhancementDatabase.GetLevelInfo(level)
	return EnhancementDatabase.Levels[level]
end

return EnhancementDatabase