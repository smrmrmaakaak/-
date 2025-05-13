-- ==========================================================================
-- ===== GachaDatabase.lua =====
-- ==========================================================================
--[[
  GachaDatabase (ModuleScript)
  �̱�(��í) �ý����� ��ǰ ��ϰ� Ȯ�� ������ �����մϴ�.
  *** [����] �Ǹ��� ���� �̱� Ǯ �߰� ***
]]
local GachaDatabase = {}

-- GachaPools ���̺�: ���� ������ �̱⸦ ������ �� �ֽ��ϴ�.
-- �� �̱�(Pool)�� ���� ID, �̸�, �̱� ���, ��ǰ ���(Items)�� �����ϴ�.
GachaDatabase.GachaPools = {
	["NormalEquip"] = { -- ���� �Ϲ� ��� �̱�
		PoolID = "NormalEquip",
		Name = "�Ϲ� ��� �̱�", -- UI�� ǥ�õ� �̸�
		Cost = { Currency = "Gold", Amount = 100 }, -- ���: ��� 100 (Currency�� "Item"�̸� ItemID �ʿ�)
		Items = {
			-- ItemID = ItemDatabase�� ������ ID
			-- Weight = Ȯ�� ����ġ (�� Ǯ ���� ��� Weight �հ� ��� ������ Ȯ�� ����)
			{ ItemID = 101, Weight = 100 }, -- �⺻ �� (����)
			{ ItemID = 102, Weight = 100 }, -- ���� �ܰ� (����)
			{ ItemID = 201, Weight = 80 },  -- ���� �⺻ �� (���� �� ����)
			{ ItemID = 202, Weight = 80 },  -- ���� ���� (���� �� ����)
			{ ItemID = 1, Weight = 50 },    -- HP ���� (���� ����)
			{ ItemID = 2, Weight = 50 },    -- MP ���� (���� ����)
			{ ItemID = 103, Weight = 20 },  -- ��ö �� (���)
			{ ItemID = 301, Weight = 15 },  -- ���� ���� (���)
			{ ItemID = 1001, Weight = 150 }, -- ���� (�ſ� ����)
			{ ItemID = 402, Weight = 120 }, -- ���� ���� (�ſ� ����)
			{ ItemID = 403, Weight = 120 }, -- �η��� �� (�ſ� ����)
		}
	},
	-- ["PremiumEquip"] = { -- ��� �̱� ���� (���߿� �߰� ����)
	--  PoolID = "PremiumEquip",
	--  Name = "��� ��� �̱�",
	--  Cost = { Currency = "Item", ItemID = 501, Amount = 1 }, -- ���: �̱�� ������ 1�� (ItemID 501 ����)
	--  Items = {
	--      { ItemID = 103, Weight = 100 }, -- ��ö ��
	--      { ItemID = 202, Weight = 80 },  -- ö ����
	--      { ItemID = 302, Weight = 70 },  -- ü���� �����
	--      -- { ItemID = ???, Weight = 10 }, -- �� ����� ������
	--  }
	-- },

	-- *** [�ű�] �Ǹ��� ���� �̱� Ǯ ***
	["DevilFruitPool"] = {
		PoolID = "DevilFruitPool",
		Name = "�Ǹ��� ���� �̱�",
		Cost = { Currency = "Gold", Amount = 100000 }, -- �̱� ���: 100,000 ���
		Items = {
			-- ���⿡ ItemDatabase�� ���ǵ� �Ǹ��� ���� ������ ID�� Ȯ�� ����ġ(Weight)�� �ֽ��ϴ�.
			-- ����:
			{ ItemID = 5001, Weight = 50 }, -- ���� ���� (����ġ 50)
			{ ItemID = 5002, Weight = 40 }, -- �̱��̱� ���� (����ġ 40)
			-- { ItemID = 5003, Weight = 30 }, -- �ٸ� ��� ���� (����ġ ����)
			-- { ItemID = 5004, Weight = 5 },  -- �ſ� ����� ���� (����ġ �ſ� ����)

			-- "��" �������� ���� ���� �ֽ��ϴ� (���� ����).
			{ ItemID = 9001, Weight = 100 } -- �⵿��� (�� ����, ����ġ ����)
		}
	},
}

-- Ư�� Ǯ���� Ȯ���� ���� ������ ID �ϳ��� �̴� �Լ�
function GachaDatabase.PullItem(poolId)
	local pool = GachaDatabase.GachaPools[poolId]
	if not pool or not pool.Items or #pool.Items == 0 then
		warn("GachaDatabase.PullItem: Invalid or empty pool ID:", poolId)
		return nil -- ��ȿ���� �ʰų� ����ִ� Ǯ
	end

	local totalWeight = 0
	for _, item in ipairs(pool.Items) do
		totalWeight = totalWeight + (item.Weight or 0)
	end

	if totalWeight <= 0 then
		warn("GachaDatabase.PullItem: Total weight is zero or negative for pool:", poolId)
		return nil -- ���� �������� ���� (��� ����ġ�� 0 ����)
	end

	-- 0 �̻� totalWeight �̸��� ���� ����
	local randomWeight = math.random() * totalWeight
	if randomWeight >= totalWeight then randomWeight = totalWeight - 0.00001 end -- math.random()�� 1.0�� ��ȯ�ϴ� ���� �幮 ��� ���

	local cumulativeWeight = 0
	for _, item in ipairs(pool.Items) do
		local currentWeight = item.Weight or 0
		if currentWeight > 0 then -- ����ġ�� 0���� ū ��쿡�� ���� �� Ȯ��
			cumulativeWeight = cumulativeWeight + currentWeight
			if randomWeight < cumulativeWeight then
				print("GachaDatabase.PullItem: Pulled ItemID", item.ItemID, "from pool", poolId)
				return item.ItemID -- ��÷�� ������ ID ��ȯ
			end
		end
	end

	-- ������ �������Դٸ� (��� ����ġ�� 0�̰ų� �ε� �Ҽ��� ���� ��)
	warn("GachaDatabase.PullItem: Failed to select an item based on weight, returning nil for pool:", poolId)
	return nil -- �����ϰ� nil ��ȯ
end


return GachaDatabase