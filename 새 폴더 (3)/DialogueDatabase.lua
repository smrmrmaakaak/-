-- DialogueDatabase.lua (����: NPC�� ��ȭ ��� �̹��� ID �ʵ� �߰�)

local DialogueDatabase = {}

DialogueDatabase.Dialogues = {
	["Shopkeeper1"] = {
		PortraitImageId = "rbxassetid://129325963305444", -- ���� ���� �ʻ�ȭ ID
		DialogueBackgroundImageId = "rbxassetid://91001138952053", -- <<< [�߰�] ���� ���ΰ� ��ȭ �� ��� ID
		InitialNode = "Start",
		Nodes = {
			["Start"] = {
				NPCText = "� ������! ���� �������� ���� ���ǵ��� ����ϴ�. ������ �����帱���?",
				Responses = {
					{ Text = "������ ��� �ͽ��ϴ�.", Action = "OpenShop_Buy" },
					{ Text = "������ �Ȱ� �ͽ��ϴ�.", Action = "OpenShop_Sell" },
					{ Text = "���� ������ �����?", NextNode = "AskAboutTown_Shop" },
					{ Text = "������ ���ڽ��ϴ�.", NextNode = "Goodbye_Shop" },
				}
			},
			["AskAboutTown_Shop"] = {
				NPCText = "�۽��, ���� ���� ������� ��Ÿ���� �ٵ� ������ ���ƿ�. �����̶� �ȾƼ� ���踦 �����ؾ���.",
				Responses = {
					{ Text = "�׷�����...", NextNode = "Start" },
				}
			},
			["Goodbye_Shop"] = {
				NPCText = "��, �ʿ��� �� ������ ������ �ٽ� �鷯�ּ���!",
				IsEnd = true
			},
		}
	},
	["Blacksmith1"] = {
		PortraitImageId = "rbxassetid://75728334726894", -- �������� �ʻ�ȭ ID
		DialogueBackgroundImageId = "rbxassetid://100261058333994", -- <<< [�߰�] �������̿� ��ȭ �� ��� ID
		InitialNode = "Start",
		Nodes = {
			["Start"] = {
				NPCText = "��... �� �����ٱ�? ��� �����̳� ��ȭ�� �ʿ��ϸ� ����.",
				Responses = {
					{ Text = "������ ������ �ϰ� �ͽ��ϴ�.", Action = "OpenCrafting" },
					{ Text = "��� ��ȭ�ϰ� �ͽ��ϴ�.", Action = "OpenEnhancement" },
					{ Text = "�������ϴ�.", NextNode = "Goodbye_Smith" },
				}
			},
			["Goodbye_Smith"] = {
				NPCText = "�׷�, �� �����ϰ�.",
				IsEnd = true
			},
		}
	},
	["GachaMerchant1"] = {
		PortraitImageId = "rbxassetid://126088103319367", -- �̱� ���� �ʻ�ȭ ID
		DialogueBackgroundImageId = "rbxassetid://125525891411220", -- <<< [�߰�] �̱� ���ΰ� ��ȭ �� ��� ID
		InitialNode = "Start",
		Nodes = {
			["Start"] = {
				NPCText = "����, �̱� �� �� �? ���� ������ ��� �������� ���� ���� �ִٰ�!",
				Responses = {
					{ Text = "������ �̱⸦ �ϰ� �ͽ��ϴ�.", Action = "OpenGacha" },
					{ Text = "���� �����ϴ�.", NextNode = "Goodbye_Gacha" },
				}
			},
			["Goodbye_Gacha"] = {
				NPCText = "����, ��̾���. ������ �ٽ� ��!",
				IsEnd = true
			},
		}
	},
	["QuestGiver1"] = {
		PortraitImageId = "rbxassetid://85210904157204", -- ���� �ʻ�ȭ ID
		DialogueBackgroundImageId = "rbxassetid://72994432802332", -- <<< [�߰�] ������ ��ȭ �� ��� ID
		InitialNode = "Start",
		Nodes = {
			["Start"] = {
				NPCText = "���谡 ��忡 �� �� ȯ���Ѵ�! ���� �Ϸ� �Գ�?",
				Responses = {
					{ Text = "[�׽�Ʈ] �Ǹ��� ���� �ޱ� (����)", Action = "GetTestFruit" },
					{ Text = "��ų�� ���� �ͽ��ϴ�.", Action = "OpenSkillShop" },
					{ Text = "�� ������ ���� �˷��ּ���.", NextNode = "AskAboutTown_Guild" },
					{ Text = "���� �����ϴ�.", NextNode = "Goodbye_Guild" },
				}
			},
			["AskAboutTown_Guild"] = {
				NPCText = "���� ���� ��������. ���谡���� ù������ ���� ���̾�. ���� ���� �ʺ��ڵ��� ���� �ױ� ������, �ֱ� ��� ������ ������������ �����ϰ�.",
				Responses = {
					{ Text = "����ϰڽ��ϴ�.", NextNode = "Start" },
				}
			},
			["Goodbye_Guild"] = {
				NPCText = "�׷�, ������ ������ �ʿ��ϸ� ã�ƿ���.",
				IsEnd = true
			},
		}
	},
	["FruitGachaMerchant1"] = {
		PortraitImageId = "rbxassetid://97315285719404", -- ���� ���� �ʻ�ȭ ID
		DialogueBackgroundImageId = "rbxassetid://85795553376650", -- <<< [�߰�] ���� ���ΰ� ��ȭ �� ��� ID
		InitialNode = "Start",
		Nodes = {
			["Start"] = {
				NPCText = "ũŪ... � ��. ���� Ư���� '����'�� ���� �ֳ�? �ƴϸ�... �� ���� '�ɷ�'�� ������ �ͳ�?",
				Responses = {
					{ Text = "�Ǹ��� ���Ÿ� �̰� �ͽ��ϴ�. (100,000 G)", Action = "PullFruit" },
					{ Text = "�Ǹ��� ���� �ɷ��� �����ϰ� �ͽ��ϴ�. (10,000 G)", NextNode = "ConfirmRemove" },
					{ Text = "����� ������?", NextNode = "AskWho" },
					{ Text = "���� �����ϴ�.", NextNode = "Goodbye_GachaMerchant" },
				}
			},
			["ConfirmRemove"] = {
				NPCText = "���� ��ȸ���� �ʰڳ�? �ѹ� �����ϸ� �ǵ��� �� ����. ����� 10,000 ����.",
				Responses = {
					{ Text = "��, �������ּ���.", Action = "RemoveFruit" },
					{ Text = "�ƴϿ�, �ٽ� �����غ��ڽ��ϴ�.", NextNode = "Start" },
				}
			},
			["AskWho"] = {
				NPCText = "���� ����... �� ���� ������ ��� ���ο� ������ ã���ִ� ������ ������. ũũŪ...",
				Responses = {
					{ Text = "�˰ڽ��ϴ�...", NextNode = "Start" },
				}
			},
			["Goodbye_GachaMerchant"] = {
				NPCText = "��, ������ �ٽ� ã�ƿ����. �� ���� '����'�� �������� �𸣴�...",
				IsEnd = true
			},
		}
	},
}

function DialogueDatabase.GetDialogueData(npcId)
	local dialogue = DialogueDatabase.Dialogues[npcId]
	if dialogue then
		local copy = {}
		for k, v in pairs(dialogue) do
			copy[k] = v
		end
		return copy
	end
	return nil
end

return DialogueDatabase