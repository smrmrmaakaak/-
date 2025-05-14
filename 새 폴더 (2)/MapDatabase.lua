--[[
  MapDatabase (ModuleScript)
  게임 맵 데이터 저장
  *** [수정] 테이블 정의 마지막 쉼표 제거 및 높이 테스트 맵 추가 ***
  *** [수정] 각 맵 데이터에 BGM 필드 추가 ***
]]
local MapDatabase = {}

-- *** 공통 타일 속성 정의 (새 타일 추가) ***
local defaultTileProperties = {
	[0] = { Name = "Grass", Walkable = true, Color = Color3.fromRGB(80, 160, 80), Height = 0 }, -- 기본 잔디 (높이 0)
	[1] = { Name = "Path", Walkable = true, Color = Color3.fromRGB(180, 160, 120), Height = 0 }, -- 길 (높이 0)
	[2] = { Name = "Wall", Walkable = false, Color = Color3.fromRGB(100, 100, 100), Height = 1 }, -- 벽 (높이 1)
	[3] = { Name = "Water", Walkable = false, Color = Color3.fromRGB(100, 100, 200), Height = 0 }, -- 물
	[4] = { Name = "House", Walkable = false, Color = Color3.fromRGB(150, 100, 80), Height = 1 }, -- 집 (높이 1 가정)
	[5] = { Name = "Portal", Walkable = true, Color = Color3.fromRGB(200, 100, 255), Height = 0 }, -- 포탈
	[6] = { Name = "Tree", Walkable = false, Color = Color3.fromRGB(50, 100, 50), Height = 1 }, -- 나무 (높이 1 가정)
	[7] = { Name = "Rock", Walkable = false, Color = Color3.fromRGB(140, 140, 140), Height = 0 }, -- 바위
	[8] = { Name = "Tent", Walkable = false, Color = Color3.fromRGB(100, 70, 50), Height = 1 }, -- 텐트 (높이 1 가정)
	[9] = { Name = "Sand", Walkable = true, Color = Color3.fromRGB(230, 210, 170), Height = 0 }, -- 모래
	[10] = { Name = "ShallowWater", Walkable = true, Color = Color3.fromRGB(130, 180, 220), Height = 0 }, -- 얕은 물
	[11] = { Name = "Deck", Walkable = true, Color = Color3.fromRGB(160, 120, 80), Height = 0 }, -- 갑판
	[12] = { Name = "FortWall", Walkable = false, Color = Color3.fromRGB(180, 180, 180), Height = 1 }, -- 요새 벽
	[13] = { Name = "Dock", Walkable = true, Color = Color3.fromRGB(140, 110, 70), Height = 0 }, -- 부두
	-- *** [신규] 높이 표현용 타일 ***
	[14] = { Name = "CliffTopGrass", Walkable = true, Color = Color3.fromRGB(100, 180, 100), Height = 1 }, -- 높은 잔디 (높이 1)
	[15] = { Name = "CliffSide", Walkable = false, Color = Color3.fromRGB(110, 110, 110), Height = 0, ImageId = "rbxassetid://YOUR_CLIFF_SIDE_IMAGE_ID" }, -- 절벽 옆면 (높이 정보는 렌더링 시 사용, ImageId 추가)
	[16] = { Name = "HigherGrass", Walkable = true, Color = Color3.fromRGB(120, 200, 120), Height = 2 } -- 더 높은 잔디 (높이 2)
}

-- 맵 데이터 정의
MapDatabase.Maps = {
	["DefaultMap"] = { -- 시작 마을
		Name = "시작 마을",
		Width = 20, Height = 15,
		BGM = "rbxassetid://124424308588755", -- <<< 시작 마을 BGM ID
		Tiles = {
			{2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2}, -- y = 1
			{2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2}, -- y = 2
			{2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2}, -- y = 3
			{2,0,0,4,4,0,0,1,1,1,1,1,0,0,4,4,0,0,0,2}, -- y = 4
			{2,0,0,4,4,0,0,1,0,0,0,1,0,0,4,4,0,0,0,2}, -- y = 5
			{2,0,0,0,0,0,0,1,0,3,3,1,0,0,0,0,0,0,0,2}, -- y = 6
			{2,0,0,0,0,0,0,1,0,3,3,1,0,0,0,0,0,0,0,2}, -- y = 7
			{2,5,1,1,1,1,1,1,0,3,3,0,1,1,1,1,1,1,5,2}, -- y = 8
			{2,0,0,0,0,0,0,1,0,3,3,0,0,0,0,0,0,0,0,2}, -- y = 9
			{2,0,0,0,0,0,0,1,0,3,3,0,0,0,0,0,0,0,0,2}, -- y = 10
			{2,0,0,4,4,0,0,1,0,0,0,0,0,4,4,0,0,0,0,2}, -- y = 11
			{2,0,0,4,4,0,0,1,1,1,1,1,1,4,4,0,0,0,0,2}, -- y = 12
			{2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2}, -- y = 13
			{2,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,2}, -- y = 14
			{2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2}, -- y = 15
		},
		TileProperties = defaultTileProperties,
		NPCs = {
			{ ID = "Shopkeeper1", Name = "상점주인", X = 7, Y = 5, Type = "Shop", IconColor = Color3.fromRGB(100, 100, 255), ImageId = "rbxassetid://74486170102025" },
			{ ID = "QuestGiver1", Name = "모험가 길드", X = 13, Y = 5, Type = "Quest", IconColor = Color3.fromRGB(255, 150, 50), ImageId = "rbxassetid://124322925675412" },
			{ ID = "Blacksmith1", Name = "대장장이", X = 4, Y = 10, Type = "Crafting", IconColor = Color3.fromRGB(150, 150, 150), ImageId = "rbxassetid://134405990928788" },
			{ ID = "GachaMerchant1", Name = "뽑기 상인", X = 16, Y = 11, Type = "Gacha", IconColor = Color3.fromRGB(220, 220, 80), ImageId = "rbxassetid://92115220902306" },
			{ ID = "FruitGachaMerchant1", Name = "열매 뽑기 상인", X = 10, Y = 13, Type = "FruitGacha", IconColor = Color3.fromRGB(200, 80, 200), ImageId = "rbxassetid://97315285719404" },
		},
		Mobs = {},
		Portals = {
			{ TargetMap = "HuntingGround1", TargetX = 1, TargetY = 7, X = 19, Y = 8 },
			{ TargetMap = "TestHeightMap", TargetX = 14, TargetY = 2, X = 2, Y = 8 },
		},
		PlayerStart = { X = 10, Y = 8 }
	},

	["TestHeightMap"] = {
		Name = "높이 테스트 맵",
		Width = 15, Height = 10,
		BGM = "rbxassetid://YOUR_CAVE_OR_TEST_BGM_ID", -- <<< 테스트 맵 BGM ID
		Tiles = {
			{15,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
			{0,0,0,14,14,14,0,0,0,16,16,16,0,5,0},
			{0,0,0,14,14,14,0,0,0,16,16,16,0,0,0},
			{0,0,0,14,14,14,0,0,0,16,16,16,0,0,0},
			{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
			{0,1,1,1,1,1,1,1,1,1,1,1,1,1,0},
			{0,1,14,14,1,1,1,1,1,1,14,14,1,1,0},
			{0,1,14,14,1,1,1,1,1,1,14,14,1,1,0},
			{0,1,1,1,1,1,1,1,1,1,1,1,1,1,0},
			{0,0,0,0,0,0,0,0,0,0,0,0,0,0,0},
		},
		TileProperties = {
			[0] = defaultTileProperties[0], [1] = defaultTileProperties[1], [5] = defaultTileProperties[5],
			[14] = defaultTileProperties[14], [16] = defaultTileProperties[16], [15] = defaultTileProperties[15] -- 옆면 정보도 포함
		},
		NPCs = {}, Mobs = {},
		Portals = { { TargetMap = "DefaultMap", TargetX = 2, TargetY = 8, X = 14, Y = 2 } },
		PlayerStart = { X = 2, Y = 6 }
	},

	["HuntingGround1"] = { -- 초보 사냥터
		Name = "초보 사냥터",
		Width = 15, Height = 10,
		BGM = "rbxassetid://116003091779368", -- <<< 사냥터 BGM ID
		Tiles = {
			{2,2,2,2,2,2,2,2,2,2,2,2,2,2,2},
			{2,0,0,0,0,0,0,0,0,0,0,0,0,0,2},
			{2,0,6,6,0,0,0,0,0,0,0,6,6,0,2},
			{2,0,6,0,0,1,1,1,1,1,0,0,6,0,2},
			{2,0,0,0,1,1,1,1,1,1,1,0,0,0,2},
			{2,0,0,1,1,1,1,1,1,1,1,1,0,0,2},
			{5,1,1,1,0,0,0,0,0,0,0,1,1,1,5},
			{2,0,0,0,0,6,0,0,0,6,0,0,0,0,2},
			{2,0,0,0,0,6,6,0,6,6,0,0,0,0,2},
			{2,2,2,2,2,2,2,2,2,2,2,2,2,2,2},
		},
		TileProperties = {
			[0] = defaultTileProperties[0], [1] = defaultTileProperties[1], [2] = defaultTileProperties[2],
			[5] = defaultTileProperties[5], [6] = defaultTileProperties[6],
		},
		NPCs = {},
		Mobs = {
			{ InstanceID = "Slime1", EnemyID = 1, X = 5, Y = 5, IconColor = Color3.fromRGB(180, 220, 100), ImageId = "rbxassetid://139610831731863" },
			{ InstanceID = "Slime2", EnemyID = 1, X = 10, Y = 5, IconColor = Color3.fromRGB(180, 220, 100), ImageId = "rbxassetid://139610831731863" },
			{ InstanceID = "Slime3", EnemyID = 1, X = 7, Y = 8, IconColor = Color3.fromRGB(180, 220, 100), ImageId = "rbxassetid://139610831731863" },
			{ InstanceID = "Bat1", EnemyID = 2, X = 4, Y = 3, IconColor = Color3.fromRGB(100, 100, 120), ImageId = "rbxassetid://208066789012345" },
			{ InstanceID = "Bat2", EnemyID = 2, X = 12, Y = 3, IconColor = Color3.fromRGB(100, 100, 120), ImageId = "rbxassetid://208066789012345" },
		},
		Portals = {
			{ TargetMap = "DefaultMap", TargetX = 19, TargetY = 8, X = 1, Y = 7 },
			{ TargetMap = "GoblinForest", TargetX = 1, TargetY = 8, X = 15, Y = 7 },
		},
		PlayerStart = { X = 2, Y = 7 }
	},
	["GoblinForest"] = {
		Name = "고블린 숲",
		Width = 18, Height = 12,
		BGM = "rbxassetid://86197550802994", -- <<< 고블린 숲 BGM ID
		Tiles = {
			{2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2},
			{2,6,6,0,0,0,0,0,0,0,0,0,0,6,6,6,6,2},
			{2,6,0,0,0,1,1,1,1,1,1,0,0,0,0,6,6,2},
			{2,0,0,0,1,1,6,6,6,6,1,1,0,0,0,0,0,2},
			{2,0,0,1,1,6,6,0,0,6,6,1,1,0,0,0,0,2},
			{2,0,0,1,6,0,0,0,0,0,0,6,1,0,0,6,6,2},
			{2,0,0,1,6,0,0,0,0,0,0,6,1,0,0,6,6,2},
			{5,1,1,1,6,6,0,0,0,0,6,6,1,1,1,1,1,5},
			{2,0,0,0,0,6,0,0,0,0,6,0,0,0,0,0,0,2},
			{2,6,0,0,0,0,0,0,0,0,0,0,0,0,0,6,6,2},
			{2,6,6,6,0,0,0,0,0,0,0,0,0,0,6,6,6,2},
			{2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2},
		},
		TileProperties = {
			[0] = defaultTileProperties[0], [1] = defaultTileProperties[1], [2] = defaultTileProperties[2],
			[5] = defaultTileProperties[5], [6] = defaultTileProperties[6],
		},
		NPCs = {},
		Mobs = {
			{ InstanceID = "Goblin1", EnemyID = 4, X = 5, Y = 5, IconColor = Color3.fromRGB(100, 150, 80), ImageId = "rbxassetid://109033948393929" },
			{ InstanceID = "Goblin2", EnemyID = 4, X = 13, Y = 5, IconColor = Color3.fromRGB(100, 150, 80), ImageId = "rbxassetid://109033948393929" },
			{ InstanceID = "Goblin3", EnemyID = 4, X = 8, Y = 9, IconColor = Color3.fromRGB(100, 150, 80), ImageId = "rbxassetid://109033948393929" },
			{ InstanceID = "Skeleton1", EnemyID = 3, X = 10, Y = 3, IconColor = Color3.fromRGB(200, 200, 200), ImageId = "rbxassetid://86654621036939" },
		},
		Portals = {
			{ TargetMap = "HuntingGround1", TargetX = 14, TargetY = 7, X = 1, Y = 8 },
			{ TargetMap = "OrcCamp", TargetX = 1, TargetY = 6, X = 18, Y = 8 },
		},
		PlayerStart = { X = 2, Y = 8 }
	},
	["OrcCamp"] = {
		Name = "오크 캠프",
		Width = 20, Height = 15,
		BGM = "rbxassetid://74276928769001", -- <<< 오크 캠프 BGM ID
		Tiles = {
			{2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2},
			{2,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,2},
			{2,7,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,7,2},
			{2,7,0,8,8,0,1,1,1,1,1,1,0,8,8,0,0,0,7,2},
			{2,7,0,8,8,0,1,6,6,6,6,1,0,8,8,0,0,0,7,2},
			{5,1,1,1,1,1,1,6,0,0,6,1,1,1,1,1,1,1,5,2},
			{2,7,0,0,0,0,1,6,0,0,6,1,0,0,0,0,0,0,7,2},
			{2,7,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0,0,7,2},
			{2,7,0,8,8,0,0,0,0,0,0,0,0,8,8,0,0,0,7,2},
			{2,7,0,8,8,0,0,0,0,0,0,0,0,8,8,0,0,0,7,2},
			{2,7,0,0,0,0,1,1,1,1,1,1,0,0,0,0,0,0,7,2},
			{2,7,0,0,0,0,1,6,6,6,6,1,0,0,0,0,0,0,7,2},
			{2,7,0,0,0,0,1,0,0,0,0,1,0,0,0,0,0,0,7,2},
			{2,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,7,2},
			{2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2,2},
		},
		TileProperties = {
			[0] = defaultTileProperties[0], [1] = defaultTileProperties[1], [2] = defaultTileProperties[2],
			[5] = defaultTileProperties[5], [6] = defaultTileProperties[6], [7] = defaultTileProperties[7],
			[8] = defaultTileProperties[8],
		},
		NPCs = {},
		Mobs = {
			{ InstanceID = "Orc1", EnemyID = 5, X = 7, Y = 8, IconColor = Color3.fromRGB(80, 120, 80), ImageId = "rbxassetid://136237872671206" },
			{ InstanceID = "Orc2", EnemyID = 5, X = 14, Y = 8, IconColor = Color3.fromRGB(80, 120, 80), ImageId = "rbxassetid://136237872671206" },
			{ InstanceID = "Orc3", EnemyID = 5, X = 10, Y = 4, IconColor = Color3.fromRGB(80, 120, 80), ImageId = "rbxassetid://136237872671206" },
			{ InstanceID = "Goblin4", EnemyID = 4, X = 4, Y = 12, IconColor = Color3.fromRGB(100, 150, 80), ImageId = "rbxassetid://109033948393929" },
		},
		Portals = {
			{ TargetMap = "GoblinForest", TargetX = 17, TargetY = 8, X = 1, Y = 6 },
			{ TargetMap = "PirateIsland", TargetX = 1, TargetY = 10, X = 19, Y = 6 },
		},
		PlayerStart = { X = 2, Y = 6 }
	},

	["PirateIsland"] = {
		Name = "해적섬",
		Width = 25, Height = 20,
		BGM = "rbxassetid://102713147917305", -- <<< 해적섬 BGM ID
		Tiles = {
			{3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3},
			{3,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,3},
			{3,10,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,10,3},
			{3,10,9,6,6,9,9,11,11,11,9,9,6,6,9,9,11,11,11,9,9,6,6,10,3},
			{3,10,9,6,6,9,11,8,8,11,9,6,6,9,9,11,8,8,11,9,6,6,9,10,3},
			{3,10,9,9,9,9,11,11,11,11,9,9,9,9,9,11,11,11,11,9,9,9,9,10,3},
			{3,10,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,10,3},
			{3,10,9,9,6,6,6,9,9,1,1,1,1,1,1,9,9,6,6,6,9,9,9,10,3},
			{3,10,9,9,6,0,0,6,9,1,0,0,0,0,1,9,6,0,0,6,9,9,9,10,3},
			{5,13,13,13,6,0,0,6,9,1,0,0,0,0,1,9,6,0,0,6,13,13,13,13,5},
			{3,10,9,9,6,0,0,6,9,1,0,0,0,0,1,9,6,0,0,6,9,9,9,10,3},
			{3,10,9,9,6,6,6,9,9,1,1,1,1,1,1,9,9,6,6,6,9,9,9,10,3},
			{3,10,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,10,3},
			{3,10,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,9,10,3},
			{3,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,3},
			{3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3},
			{3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3},
			{3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3},
			{3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3},
			{3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3},
		},
		TileProperties = {
			[0] = defaultTileProperties[0], [1] = defaultTileProperties[1], [3] = defaultTileProperties[3],
			[5] = defaultTileProperties[5], [6] = defaultTileProperties[6], [8] = defaultTileProperties[8],
			[9] = defaultTileProperties[9], [10] = defaultTileProperties[10], [11] = defaultTileProperties[11],
			[13] = defaultTileProperties[13],
		},
		NPCs = {
			{ ID = "PirateInfo", Name = "늙은 해적", X = 10, Y = 5, Type = "Info", ImageId = "rbxassetid://105400828986934" },
		},
		Mobs = {
			{ InstanceID = "Pirate1", EnemyID = 6, X = 15, Y = 7, ImageId = "rbxassetid://127349921664378" },
			{ InstanceID = "Pirate2", EnemyID = 6, X = 20, Y = 4, ImageId = "rbxassetid://127349921664378" },
			{ InstanceID = "Cannon1", EnemyID = 7, X = 8, Y = 13, ImageId = "rbxassetid://112535677076979" },
		},
		Portals = {
			{ TargetMap = "OrcCamp", TargetX = 19, TargetY = 6, X = 1, Y = 10 }, -- 포탈 위치 수정 반영
			{ TargetMap = "MarineBase", TargetX = 1, TargetY = 4, X = 25, Y = 10 },
		},
		PlayerStart = { X = 2, Y = 10 }
	},

	["MarineBase"] = {
		Name = "해군 기지",
		Width = 22, Height = 18,
		BGM = "rbxassetid://137133193014242", -- <<< 해군 기지 BGM ID
		Tiles = {
			{3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3},
			{3,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,3},
			{3,10,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,13,10,3},
			{5,13,12,12,12,12,12,12,12,12,1,12,12,12,12,12,12,12,12,12,13,5},
			{3,10,12,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,12,10,3},
			{3,10,12,1,4,4,1,1,1,1,1,1,1,1,1,4,4,1,1,12,10,3},
			{3,10,12,1,4,4,1,1,1,11,11,11,11,1,1,4,4,1,1,12,10,3},
			{3,10,12,1,1,1,1,1,1,11,11,11,11,1,1,1,1,1,1,12,10,3},
			{3,10,12,1,1,1,1,1,1,11,11,11,11,1,1,1,1,1,1,12,10,3},
			{3,10,12,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,12,10,3},
			{3,10,12,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,12,10,3},
			{3,10,12,1,1,4,4,1,1,1,1,1,1,1,4,4,1,1,1,12,10,3},
			{3,10,12,1,1,4,4,1,1,1,1,1,1,1,4,4,1,1,1,12,10,3},
			{3,10,12,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,1,12,10,3},
			{3,10,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,12,10,3},
			{3,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,10,3},
			{3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3},
			{3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3,3},
		},
		TileProperties = {
			[1] = defaultTileProperties[1], [3] = defaultTileProperties[3], [4] = defaultTileProperties[4],
			[5] = defaultTileProperties[5], [10] = defaultTileProperties[10], [11] = defaultTileProperties[11],
			[12] = defaultTileProperties[12], [13] = defaultTileProperties[13],
		},
		NPCs = {
			{ ID = "MarineCaptain", Name = "해군 대위", X = 11, Y = 6, Type = "Quest", ImageId = "rbxassetid://109066111748123" },
		},
		Mobs = {
			{ InstanceID = "Marine1", EnemyID = 8, X = 5, Y = 10, ImageId = "rbxassetid://122841225189417" },
			{ InstanceID = "Marine2", EnemyID = 8, X = 17, Y = 10, ImageId = "rbxassetid://122841225189417" },
			{ InstanceID = "Officer1", EnemyID = 9, X = 11, Y = 13, ImageId = "rbxassetid://139037740235144" },
		},
		Portals = {
			{ TargetMap = "PirateIsland", TargetX = 24, TargetY = 10, X = 1, Y = 4 },
			-- { TargetMap = "???", TargetX = ?, TargetY = ?, X = 22, Y = 4 },
		},
		PlayerStart = { X = 2, Y = 4 }
	},
}

return MapDatabase
