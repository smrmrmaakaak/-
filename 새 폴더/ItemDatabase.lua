-- ItemDatabase.lua (������ ��ü �ڵ�)

--[[
  ItemDatabase (ModuleScript)
  ���� �� ��� �������� ������ �����ϰ� �����մϴ�.
  *** [����] ��� �����ۿ� Rating �ʵ� �߰� ***
  *** [����] �Ϻ� �����ۿ� �䱸 ���� �ʵ� �߰� (requiredSword, requiredGun, requiredDF) ***
  *** [�߰�] ��ȭ ���� ��� ��ȭ ���� �ʵ� �߰� (Enhanceable, MaxEnhanceLevel, EnhanceStat, EnhanceValuePerLevel) ***
]]
local ItemDatabase = {}

ItemDatabase.Items = {
	-- �Ҹ�ǰ (���� ����)
	[1] = { ID = 1, Name = "HP ����",
		Description = "HP�� 50 ȸ���մϴ�.",
		Type = "Consumable", Effect = { Stat = "HP", Value = 50 }, Stackable = true, Price = 50, SellPrice = 25, ImageId = "rbxassetid://110762008410456", ConsumedOnUse = true, Rating = "Common" },
	[2] = { ID = 2, Name = "MP ����",
		Description = "MP�� 30 ȸ���մϴ�.",
		Type = "Consumable", Effect = { Stat = "MP", Value = 30 }, Stackable = true, Price = 70, SellPrice = 35, ImageId = "rbxassetid://127915573929076", ConsumedOnUse = true, Rating = "Common" },
	[101] = { ID = 101, Name = "�̻�������",
		Description = "HP�� �ణ ȸ����Ų��.",
		Type = "Consumable", Effect = { Stat = "HP", Value = 50 }, Stackable = true, Price = 50, SellPrice = 10, ImageId = "rbxassetid://107948162867712", ConsumedOnUse = true, Rating = "Common" },
	[3] = { ID = 3, Name = "������",
		Description = "HP�� MP�� ��� ũ�� ȸ���մϴ�.",
		Type = "Consumable",
		Effect = { Stat = "HPMP", Value = 150 },
		Stackable = true,
		Price = 300, SellPrice = 150,
		ImageId = "rbxassetid://136892959937909",
		ConsumedOnUse = true, Rating = "Rare" },
	[4] = { ID = 4, Name = "����",
		Description = "�������� �����ϴ� ��. ���ø� ��� ���ݷ��� �������� ������ �ణ �����Ѵ�.", Type = "Consumable", Effect = { Type = "BuffDebuff", Buff = {Stat = "Attack", Value = 5, Duration = 3}, Debuff = {Stat = "Defense", Value = -2, Duration = 3} }, Stackable = true, Price = 80, SellPrice = 40, ImageId = "rbxassetid://105307866340527", ConsumedOnUse = true, Rating = "Uncommon" }, -- Debuff Stat ����: DEF -> Defense

	-- ���
	[102] = { ID = 102, Name = "���� �ܰ�", Description = "���� ���� ������ �ܰ��Դϴ�.", Type = "Equipment", Slot = "Weapon", WeaponType = "Sword", Stats = { Attack = 3 }, Stackable = false, Price = 70, SellPrice = 35, ImageId = "rbxassetid://121089420845762", ConsumedOnUse = false, Rating = "Common",
		-- *** ��ȭ ���� �߰� (����) ***
		Enhanceable = true, MaxEnhanceLevel = 5, EnhanceStat = "Attack", EnhanceValuePerLevel = 1
	},
	[103] = { ID = 103, Name = "��ö ��", Description = "�� ������ ��ö ���Դϴ�. ���� �����մϴ�.", Type = "Equipment", Slot = "Weapon", WeaponType = "Sword", Stats = { Attack = 8 }, Stackable = false, Price = 250, SellPrice = 125, ImageId = "rbxassetid://131972999247967", ConsumedOnUse = false, Rating = "Uncommon", requiredSword = 10,
		-- *** ��ȭ ���� �߰� (����) ***
		Enhanceable = true, MaxEnhanceLevel = 7, EnhanceStat = "Attack", EnhanceValuePerLevel = 2
	},
	[201] = { ID = 201, Name = "�⺻ ��", Description = "�⺻���� ���ݿ� ��.", Type = "Equipment", Slot = "Weapon", WeaponType = "Sword", Stats = { Attack = 5 }, Stackable = false, Price = 100, SellPrice = 20, ImageId = "rbxassetid://114430077185745", ConsumedOnUse = false, Rating = "Common",
		-- *** ��ȭ ���� �߰� (����) ***
		Enhanceable = true, MaxEnhanceLevel = 5, EnhanceStat = "Attack", EnhanceValuePerLevel = 1
	},
	[202] = { ID = 202, Name = "���� ����", Description = "������ �⺻���� ������ �����ϴ� ���� �����Դϴ�.", Type = "Equipment", Slot = "Armor", Stats = { Defense = 3 }, Stackable = false, Price = 150, SellPrice = 75, ImageId = "rbxassetid://116466664504363", ConsumedOnUse = false, Rating = "Common",
		-- *** ��ȭ ���� �߰� (����) ***
		Enhanceable = true, MaxEnhanceLevel = 5, EnhanceStat = "Defense", EnhanceValuePerLevel = 1
	},
	[203] = { ID = 203, Name = "ö ����", Description = "�߰��� ö�� ������� �����Դϴ�. �� ưư�մϴ�.", Type = "Equipment", Slot = "Armor", Stats = { Defense = 8 }, Stackable = false, Price = 400, SellPrice = 200, ImageId = "rbxassetid://89685543061050", ConsumedOnUse = false, Rating = "Uncommon",
		-- *** ��ȭ ���� �߰� (����) ***
		Enhanceable = true, MaxEnhanceLevel = 7, EnhanceStat = "Defense", EnhanceValuePerLevel = 2
	},
	-- �������� �κ�, �Ǽ��縮 ���� ��ȭ �Ұ����ϰ� ���� (Enhanceable = false �Ǵ� �ʵ� ����)
	[204] = { ID = 204, Name = "�������� �κ�", Description = "���ɰ� �ִ� MP�� �÷��ִ� �κ��Դϴ�.", Type = "Equipment", Slot = "Armor", Stats = { INT = 3, MaxMP = 20 }, Stackable = false, Price = 350, SellPrice = 175, ImageId = "rbxassetid://129481683345846", ConsumedOnUse = false, Rating = "Uncommon", Enhanceable = false },
	[301] = { ID = 301, Name = "���� ����", Description = "�������� ���� �ణ �÷��ִ� �����Դϴ�.", Type = "Equipment", Slot = "Accessory", Stats = { STR = 2 }, Stackable = false, Price = 200, SellPrice = 100, ImageId = "rbxassetid://106567997832253", ConsumedOnUse = false, Rating = "Uncommon", Enhanceable = false },
	[302] = { ID = 302, Name = "ü���� �����", Description = "�������� �ִ� HP�� �ణ �÷��ִ� ������Դϴ�.", Type = "Equipment", Slot = "Accessory", Stats = { MaxHP = 15 }, Stackable = false, Price = 180, SellPrice = 90, ImageId = "rbxassetid://86203317389088", ConsumedOnUse = false, Rating = "Uncommon", Enhanceable = false },
	[303] = { ID = 303, Name = "��ø�� �尩", Description = "�������� ��ø���� ����ŵ�ϴ�.", Type = "Equipment", Slot = "Accessory", Stats = { AGI = 3 }, Stackable = false, Price = 220, SellPrice = 110, ImageId = "rbxassetid://74032276041549", ConsumedOnUse = false, Rating = "Uncommon", Enhanceable = false },

	[104] = { ID = 104, Name = "���� ĿƲ����", Description = "�������� ��� ����ϴ� ���η��� Į.", Type = "Equipment", Slot = "Weapon", WeaponType = "Sword", Stats = { Attack = 12, AGI = 1 }, Stackable = false, Price = 500, SellPrice = 250, ImageId = "rbxassetid://99511281395130", ConsumedOnUse = false, Rating = "Rare",
		Enhanceable = true, MaxEnhanceLevel = 8, EnhanceStat = "Attack", EnhanceValuePerLevel = 3
	},
	[205] = { ID = 205, Name = "���� ���� ��Ʈ", Description = "��ǳ����� ���� ������ ��Ʈ.", Type = "Equipment", Slot = "Armor", Stats = { Defense = 10, INT = 1 }, Stackable = false, Price = 600, SellPrice = 300, ImageId = "rbxassetid://PLACEHOLDER_PIRATE_COAT", ConsumedOnUse = false, Rating = "Epic",
		Enhanceable = true, MaxEnhanceLevel = 8, EnhanceStat = "Defense", EnhanceValuePerLevel = 3
	},
	[304] = { ID = 304, Name = "���� �ȴ�", Description = "���� ���� ������ �ȴ�.", Type = "Equipment", Slot = "Accessory", Stats = { STR = 1, MaxHP = 10 }, Stackable = false, Price = 150, SellPrice = 75, ImageId = "rbxassetid://PLACEHOLDER_EYEPATCH", ConsumedOnUse = false, Rating = "Uncommon", Enhanceable = false },

	[105] = { ID = 105, Name = "�ر� ���� ����", Description = "�ر����� ���޵Ǵ� ǥ�� ����.", Type = "Equipment", Slot = "Weapon", WeaponType = "Gun", Stats = { Attack = 10, AGI = 2 }, Stackable = false, Price = 450, SellPrice = 225, ImageId = "rbxassetid://PLACEHOLDER_MARINE_RIFLE", ConsumedOnUse = false, Rating = "Rare", requiredGun = 5,
		Enhanceable = true, MaxEnhanceLevel = 7, EnhanceStat = "Attack", EnhanceValuePerLevel = 2
	},
	[206] = { ID = 206, Name = "�ر� ����", Description = "����ϰ� ưư�� �ر� ����.", Type = "Equipment", Slot = "Armor", Stats = { Defense = 12 }, Stackable = false, Price = 700, SellPrice = 350, ImageId = "rbxassetid://PLACEHOLDER_MARINE_UNIFORM", ConsumedOnUse = false, Rating = "Epic",
		Enhanceable = true, MaxEnhanceLevel = 9, EnhanceStat = "Defense", EnhanceValuePerLevel = 3
	},
	[305] = { ID = 305, Name = "�ر� �ν�ǥ", Description = "�ر��� �ź��� �����ϴ� �ν�ǥ.", Type = "Equipment", Slot = "Accessory", Stats = { MaxHP = 25 }, Stackable = false, Price = 120, SellPrice = 60, ImageId = "rbxassetid://135612708767031", ConsumedOnUse = false, Rating = "Uncommon", Enhanceable = false },

	[106] = { ID = 106, Name = "���� �۷���", Description = "���� ����Ͽ� ���� �۷���.", Type = "Equipment", Slot = "Weapon", WeaponType = "Fist", Stats = { Attack = 4 }, Stackable = false, Price = 50, SellPrice = 25, ImageId = "rbxassetid://81471471515945", ConsumedOnUse = false, Rating = "Common",
		Enhanceable = true, MaxEnhanceLevel = 5, EnhanceStat = "Attack", EnhanceValuePerLevel = 1
	},
	[107] = { ID = 107, Name = "��ö ��Ŭ", Description = "�ָԿ� ���� �ı����� ���̴� ��ö ��Ŭ.", Type = "Equipment", Slot = "Weapon", WeaponType = "Fist", Stats = { Attack = 9, STR = 1 }, Stackable = false, Price = 280, SellPrice = 140, ImageId = "rbxassetid://110341468360359", ConsumedOnUse = false, Rating = "Uncommon",
		Enhanceable = true, MaxEnhanceLevel = 7, EnhanceStat = "Attack", EnhanceValuePerLevel = 2
	},

	-- ��� (���� ����)
	[1001] = { ID = 1001, Name = "����", Description = "������ ����.", Type = "Material", Stackable = true, SellPrice = 1, Price = 2, ImageId = "rbxassetid://133645646714060", ConsumedOnUse = false, Rating = "Common" },
	[1002] = { ID = 1002, Name = "ö����", Description = "ö ����.", Type = "Material", Stackable = true, SellPrice = 3, Price = 6, ImageId = "rbxassetid://90226349090319", ConsumedOnUse = false, Rating = "Common" },
	[1003] = { ID = 1003, Name = "���� ����", Description = "�����̳� ���.", Type = "Material", Stackable = true, SellPrice = 1, Price = 2, ImageId = "rbxassetid://84031957599394", ConsumedOnUse = false, Rating = "Common" },
	[402] = { ID = 402, Name = "���� ����", Description = "���� ����.", Type = "Material", Stackable = true, Price = 8, SellPrice = 4, ImageId = "rbxassetid://80989619780409", ConsumedOnUse = false, Rating = "Common" },
	[403] = { ID = 403, Name = "�η��� ��", Description = "���� ��.", Type = "Material", Stackable = true, Price = 3, SellPrice = 1, ImageId = "rbxassetid://107786181150802", ConsumedOnUse = false, Rating = "Common" },
	[1004] = { ID = 1004, Name = "������ ��", Description = "������ �������� ��.", Type = "Material", Stackable = true, Price = 50, SellPrice = 25, ImageId = "rbxassetid://111811519735527", ConsumedOnUse = false, Rating = "Rare" },
	[1005] = { ID = 1005, Name = "���� �ص� ����", Description = "������ �ص��� ����.", Type = "Material", Stackable = true, Price = 20, SellPrice = 10, ImageId = "rbxassetid://103879649442552", ConsumedOnUse = false, Rating = "Uncommon" },
	[1006] = { ID = 1006, Name = "�ر��� ����", Description = "�ر� ���� ����.", Type = "Material", Stackable = true, Price = 5, SellPrice = 2, ImageId = "rbxassetid://118836642440971", ConsumedOnUse = false, Rating = "Common" },
	-- *** [�߰�] ��ȭ�� ������ ���� ***
	[1101] = { ID = 1101, Name = "�ϱ� ��ȭ��", Description = "��� ��ȭ�� ���Ǵ� �⺻���� ��.", Type = "Material", Stackable = true, Price = 100, SellPrice = 50, ImageId = "rbxassetid://107719128481590", Rating = "Common" },
	[1102] = { ID = 1102, Name = "�߱� ��ȭ��", Description = "���� ���� ������ ��ȭ�� ���Ǵ� ��.", Type = "Material", Stackable = true, Price = 500, SellPrice = 250, ImageId = "rbxassetid://91144641717852", Rating = "Uncommon" },
	[1103] = { ID = 1103, Name = "��� ��ȭ��", Description = "����ϰ� ������ ��ȭ�� �ʿ��� ��.", Type = "Material", Stackable = true, Price = 2000, SellPrice = 1000, ImageId = "rbxassetid://110904666073810", Rating = "Rare" },


	-- ��Ÿ (���� ����)
	[9001] = { ID = 9001, Name = "�⵿���", Description = "���� ���� ���̴� ����.", Type = "Etc", Stackable = true, SellPrice = 1, Price = 0, ImageId = "rbxassetid://86494166041349", ConsumedOnUse = false, Rating = "Common" },

	-- �Ǹ��� ���� (���� ����)
	[5001] = { ID = 5001, Name = "���� ����", Description = "���� ��ó�� �þ�� �ɷ��� ��´�.", Type = "DevilFruit", ImageId = "rbxassetid://103681930908823", Stackable = false, ConsumedOnUse = true, Effect = "GrantDevilFruit", FruitID = "GomuGomu", Price = 1000000, SellPrice = 1, Rating = "Legendary", requiredDF = 10 },
	[5002] = { ID = 5002, Name = "�̱��̱� ����", Description = "���� �ٷ�� �ɷ��� ��´�.", Type = "DevilFruit", ImageId = "rbxassetid://105570803146618", Stackable = false, ConsumedOnUse = true, Effect = "GrantDevilFruit", FruitID = "MeraMera", Price = 80000000, SellPrice = 1, Rating = "Legendary" },
}

-- GetItemInfo �Լ� (���� ����)
if not ItemDatabase.GetItemInfo then
	function ItemDatabase.GetItemInfo(itemId)
		local key = tonumber(itemId) or tostring(itemId)
		if ItemDatabase.Items[key] then
			-- ��ȯ ���� ���纻�� ����� ���� ������ ������ ���� (������������ ����)
			local itemInfoCopy = {}
			for k, v in pairs(ItemDatabase.Items[key]) do
				itemInfoCopy[k] = v
			end
			return itemInfoCopy
		else
			warn("ItemDatabase: ������ ������ ã�� �� �����ϴ�. ID:", itemId)
			return nil
		end
	end
end


return ItemDatabase