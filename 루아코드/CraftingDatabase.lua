--[[
  CraftingDatabase (ModuleScript)
  ������ ���� ������ ���� ����
]]
local CraftingDatabase = {}

CraftingDatabase.Recipes = {
	[1] = { -- ������ ID
		ResultItemID = 101, -- ��� ������ ID (��: ����, ItemDatabase�� ���� �ʿ�)
		ResultQuantity = 1, -- ��� ������ ����
		Materials = { -- **[����]** �ʿ� ��� ��� �߰�
			{ItemID = 1001, Quantity = 2} -- ��: ���� (ItemID 1001) 2�� �ʿ� (ItemDatabase�� ���� �ʿ�)
		},
		Category = "Potion" -- ���� UI �з��� (������)
	},
	[2] = {
		ResultItemID = 201, -- ��: �⺻ �� (ItemDatabase�� ���� �ʿ�)
		ResultQuantity = 1,
		Materials = {
			{ItemID = 1002, Quantity = 5}, -- ��: ö���� 5�� (ItemDatabase�� ���� �ʿ�)
			{ItemID = 1003, Quantity = 1}  -- ��: ���� ���� 1�� (ItemDatabase�� ���� �ʿ�)
		},
		Category = "Weapon"
	},
	-- �ٸ� ������ �߰�...
}

return CraftingDatabase
