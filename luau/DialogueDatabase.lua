-- DialogueDatabase.lua (수정: NPC별 대화 배경 이미지 ID 필드 추가)

local DialogueDatabase = {}

DialogueDatabase.Dialogues = {
	["Shopkeeper1"] = {
		PortraitImageId = "rbxassetid://129325963305444", -- 상점 주인 초상화 ID
		DialogueBackgroundImageId = "rbxassetid://91001138952053", -- <<< [추가] 상점 주인과 대화 시 배경 ID
		InitialNode = "Start",
		Nodes = {
			["Start"] = {
				NPCText = "어서 오세요! 저희 상점에는 좋은 물건들이 많답니다. 무엇을 보여드릴까요?",
				Responses = {
					{ Text = "물건을 사고 싶습니다.", Action = "OpenShop_Buy" },
					{ Text = "물건을 팔고 싶습니다.", Action = "OpenShop_Sell" },
					{ Text = "요즘 마을은 어떤가요?", NextNode = "AskAboutTown_Shop" },
					{ Text = "다음에 오겠습니다.", NextNode = "Goodbye_Shop" },
				}
			},
			["AskAboutTown_Shop"] = {
				NPCText = "글쎄요, 동쪽 숲에 고블린들이 나타나서 다들 걱정이 많아요. 물건이라도 팔아서 생계를 유지해야죠.",
				Responses = {
					{ Text = "그렇군요...", NextNode = "Start" },
				}
			},
			["Goodbye_Shop"] = {
				NPCText = "네, 필요한 게 있으면 언제든 다시 들러주세요!",
				IsEnd = true
			},
		}
	},
	["Blacksmith1"] = {
		PortraitImageId = "rbxassetid://75728334726894", -- 대장장이 초상화 ID
		DialogueBackgroundImageId = "rbxassetid://100261058333994", -- <<< [추가] 대장장이와 대화 시 배경 ID
		InitialNode = "Start",
		Nodes = {
			["Start"] = {
				NPCText = "흠... 뭘 도와줄까? 장비 제작이나 강화가 필요하면 말해.",
				Responses = {
					{ Text = "아이템 제작을 하고 싶습니다.", Action = "OpenCrafting" },
					{ Text = "장비를 강화하고 싶습니다.", Action = "OpenEnhancement" },
					{ Text = "괜찮습니다.", NextNode = "Goodbye_Smith" },
				}
			},
			["Goodbye_Smith"] = {
				NPCText = "그래, 몸 조심하고.",
				IsEnd = true
			},
		}
	},
	["GachaMerchant1"] = {
		PortraitImageId = "rbxassetid://126088103319367", -- 뽑기 상인 초상화 ID
		DialogueBackgroundImageId = "rbxassetid://125525891411220", -- <<< [추가] 뽑기 상인과 대화 시 배경 ID
		InitialNode = "Start",
		Nodes = {
			["Start"] = {
				NPCText = "자자, 뽑기 한 판 어때? 운이 좋으면 대박 아이템을 얻을 수도 있다고!",
				Responses = {
					{ Text = "아이템 뽑기를 하고 싶습니다.", Action = "OpenGacha" },
					{ Text = "관심 없습니다.", NextNode = "Goodbye_Gacha" },
				}
			},
			["Goodbye_Gacha"] = {
				NPCText = "에잉, 재미없긴. 다음에 다시 와!",
				IsEnd = true
			},
		}
	},
	["QuestGiver1"] = {
		PortraitImageId = "rbxassetid://85210904157204", -- 길드원 초상화 ID
		DialogueBackgroundImageId = "rbxassetid://72994432802332", -- <<< [추가] 길드원과 대화 시 배경 ID
		InitialNode = "Start",
		Nodes = {
			["Start"] = {
				NPCText = "모험가 길드에 온 걸 환영한다! 무슨 일로 왔나?",
				Responses = {
					{ Text = "[테스트] 악마의 열매 받기 (고무고무)", Action = "GetTestFruit" },
					{ Text = "스킬을 배우고 싶습니다.", Action = "OpenSkillShop" },
					{ Text = "이 마을에 대해 알려주세요.", NextNode = "AskAboutTown_Guild" },
					{ Text = "딱히 없습니다.", NextNode = "Goodbye_Guild" },
				}
			},
			["AskAboutTown_Guild"] = {
				NPCText = "여긴 시작 마을이지. 모험가들의 첫걸음을 돕는 곳이야. 동쪽 숲은 초보자들이 경험 쌓기 좋지만, 최근 고블린 때문에 위험해졌으니 조심하게.",
				Responses = {
					{ Text = "명심하겠습니다.", NextNode = "Start" },
				}
			},
			["Goodbye_Guild"] = {
				NPCText = "그래, 언제든 도움이 필요하면 찾아오게.",
				IsEnd = true
			},
		}
	},
	["FruitGachaMerchant1"] = {
		PortraitImageId = "rbxassetid://97315285719404", -- 열매 상인 초상화 ID
		DialogueBackgroundImageId = "rbxassetid://85795553376650", -- <<< [추가] 열매 상인과 대화 시 배경 ID
		InitialNode = "Start",
		Nodes = {
			["Start"] = {
				NPCText = "크큭... 어서 와. 아주 특별한 '열매'에 관심 있나? 아니면... 네 안의 '능력'을 버리고 싶나?",
				Responses = {
					{ Text = "악마의 열매를 뽑고 싶습니다. (100,000 G)", Action = "PullFruit" },
					{ Text = "악마의 열매 능력을 제거하고 싶습니다. (10,000 G)", NextNode = "ConfirmRemove" },
					{ Text = "당신은 누구죠?", NextNode = "AskWho" },
					{ Text = "볼일 없습니다.", NextNode = "Goodbye_GachaMerchant" },
				}
			},
			["ConfirmRemove"] = {
				NPCText = "정말 후회하지 않겠나? 한번 제거하면 되돌릴 수 없어. 비용은 10,000 골드다.",
				Responses = {
					{ Text = "네, 제거해주세요.", Action = "RemoveFruit" },
					{ Text = "아니요, 다시 생각해보겠습니다.", NextNode = "Start" },
				}
			},
			["AskWho"] = {
				NPCText = "나는 그저... 길 잃은 힘들을 모아 새로운 주인을 찾아주는 장사꾼일 뿐이지. 크크큭...",
				Responses = {
					{ Text = "알겠습니다...", NextNode = "Start" },
				}
			},
			["Goodbye_GachaMerchant"] = {
				NPCText = "흥, 다음에 다시 찾아오라고. 더 좋은 '열매'가 들어올지도 모르니...",
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