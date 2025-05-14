-- MapManager.lua

local MapManager = {}

-- 필요한 서비스 로드 (상단에도 유지)
local PlayersService = game:GetService("Players") -- 변수 이름 변경 (혼동 방지)
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

-- 필요한 모듈 참조 변수 (기존과 동일)
MapManager.ModuleManager = nil
MapManager.CoreUIManager = nil -- CoreUIManager 참조 확인
MapManager.MapDatabase = nil
MapManager.GuiUtils = nil
MapManager.ShopUIManager = nil
MapManager.CraftingUIManager = nil
MapManager.GachaUIManager = nil
MapManager.DialogueManager = nil
MapManager.RequestStartCombatEvent = nil
MapManager.SoundManager = nil
MapManager.SkillShopUIManager = nil
MapManager.MobileControlsManager = nil

-- 모듈 상태 변수 (기존과 동일)
MapManager.currentMapId = nil
MapManager.playerMapX = 0
MapManager.playerMapY = 0
MapManager.playerIcon = nil
MapManager.tileSizeUDim = UDim2.new(0,0,0,0)
MapManager.inputConnection = nil
MapManager.npcIcons = {}
MapManager.mobIcons = {}

-- === 내부 헬퍼 함수 (기존과 동일) ===
local function getMapUIElements()
	local Players = game:GetService("Players")
	if not Players then
		warn("getMapUIElements: Failed to get Players service!")
		return nil, nil, nil
	end
	local player = Players.LocalPlayer
	local playerGui = player and player:FindFirstChild("PlayerGui")
	local mainGui = playerGui and playerGui:FindFirstChild("MainGui")
	local backgroundFrame = mainGui and mainGui:FindFirstChild("BackgroundFrame")
	local mapFrame = backgroundFrame and backgroundFrame:FindFirstChild("MapFrame")
	return mainGui, backgroundFrame, mapFrame
end

-- === 모듈 함수 직접 정의 ('.' 사용) ===

function MapManager.Init(interactorDependencies)
	print(string.format("[DEBUG] MapManager.Init received dependencies. Type: %s", typeof(interactorDependencies)))
	if interactorDependencies then
		print(string.format("[DEBUG] MapManager.Init: Checking received ShopUIManager. Type: %s", typeof(interactorDependencies.ShopUIManager)))
	end

	MapManager.ModuleManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ModuleManager"))
	MapManager.CoreUIManager = MapManager.ModuleManager:GetModule("CoreUIManager") -- 여기서 CoreUIManager 로드 확인
	MapManager.MapDatabase = MapManager.ModuleManager:GetModule("MapDatabase")
	MapManager.GuiUtils = MapManager.ModuleManager:GetModule("GuiUtils")
	MapManager.SoundManager = MapManager.ModuleManager:GetModule("SoundManager")
	if interactorDependencies then
		print("[DEBUG] MapManager.Init: About to assign ShopUIManager...")
		print(string.format("[DEBUG] MapManager.Init: Value in interactorDependencies.ShopUIManager just before assignment: %s", typeof(interactorDependencies.ShopUIManager)))
		MapManager.ShopUIManager = interactorDependencies.ShopUIManager
		print(string.format("[DEBUG] MapManager.Init: Value assigned to MapManager.ShopUIManager: %s", typeof(MapManager.ShopUIManager)))

		MapManager.CraftingUIManager = interactorDependencies.CraftingUIManager
		MapManager.GachaUIManager = interactorDependencies.GachaUIManager
		MapManager.DialogueManager = interactorDependencies.DialogueManager
		MapManager.RequestStartCombatEvent = interactorDependencies.RequestStartCombatEvent
		MapManager.SkillShopUIManager = interactorDependencies.SkillShopUIManager
	else
		warn("MapManager.Init: interactorDependencies is nil!")
	end
	MapManager.MobileControlsManager = MapManager.ModuleManager:GetModule("MobileControlsManager")

	print(string.format("[DEBUG] MapManager.Init: Finished assigning dependencies. Final Stored ShopUIManager type: %s", typeof(MapManager.ShopUIManager)))
	if not MapManager.CoreUIManager then warn("MapManager.Init: CoreUIManager is nil after module loading!") end -- 추가 확인

	print("MapManager: Initialized.")
end

-- (GetCurrentMapData, GetPlayerPosition, SetPlayerPosition, UpdatePlayerIconPosition, CreateMapFrame, LoadAndRenderMap, ConnectInput, DisconnectInput 함수들은 기존 코드 유지)
function MapManager.GetCurrentMapData()
	if MapManager.currentMapId and MapManager.MapDatabase and MapManager.MapDatabase.Maps then
		return MapManager.MapDatabase.Maps[MapManager.currentMapId]
	end
	return nil
end

function MapManager.GetPlayerPosition()
	return MapManager.playerMapX, MapManager.playerMapY
end

function MapManager.SetPlayerPosition(x, y)
	MapManager.playerMapX = x
	MapManager.playerMapY = y
end

function MapManager.UpdatePlayerIconPosition()
	if not MapManager.playerIcon then return end
	if MapManager.tileSizeUDim.X.Scale == 0 or MapManager.tileSizeUDim.Y.Scale == 0 then return end
	local posX = MapManager.tileSizeUDim.X.Scale * (MapManager.playerMapX - 1)
	local posY = MapManager.tileSizeUDim.Y.Scale * (MapManager.playerMapY - 1)
	MapManager.playerIcon.Position = UDim2.new(posX, 0, posY, 0)
	MapManager.playerIcon.Size = MapManager.tileSizeUDim
	local mapData = MapManager.GetCurrentMapData()
	local mapFrame = MapManager.playerIcon.Parent
	if mapData and mapFrame then
		local tileProperties = mapData.TileProperties; local tilesData = mapData.Tiles
		if tilesData and tilesData[MapManager.playerMapY] and tilesData[MapManager.playerMapY][MapManager.playerMapX] then
			local playerTileId = tilesData[MapManager.playerMapY][MapManager.playerMapX]
			local playerTileHeight = (tileProperties and tileProperties[playerTileId] and tileProperties[playerTileId].Height or 0)
			MapManager.playerIcon.ZIndex = mapFrame.ZIndex + MapManager.playerMapY + MapManager.playerMapX + playerTileHeight + 100
		else
			MapManager.playerIcon.ZIndex = mapFrame.ZIndex + 1000
			warn("MapManager.UpdatePlayerIconPosition: Invalid player position for ZIndex calculation:", MapManager.playerMapX, MapManager.playerMapY)
		end
	else
		if not mapFrame then warn("MapManager.UpdatePlayerIconPosition: mapFrame is nil! PlayerIcon Parent:", MapManager.playerIcon and MapManager.playerIcon.Parent) end
	end
end

function MapManager.CreateMapFrame()
	local mainGui, backgroundFrame = getMapUIElements()
	if not backgroundFrame then warn("MapManager.CreateMapFrame: BackgroundFrame not found!"); return nil end
	local existingMapFrame = backgroundFrame:FindFirstChild("MapFrame"); if existingMapFrame then return existingMapFrame end
	print("MapManager: Creating MapFrame...")
	local mapFrame = Instance.new("Frame"); mapFrame.Name = "MapFrame"; mapFrame.Parent = backgroundFrame; mapFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	mapFrame.Position = UDim2.new(0.5, 0, 0.5, 0); mapFrame.Size = UDim2.new(0.8, 0, 0.8, 0); mapFrame.BackgroundTransparency = 0; mapFrame.BackgroundColor3 = Color3.fromRGB(30, 40, 30); mapFrame.BorderSizePixel = 1
	mapFrame.BorderColor3 = Color3.fromRGB(100, 120, 100); mapFrame.Visible = false; mapFrame.ZIndex = 150; mapFrame.ClipsDescendants = true
	if MapManager.GuiUtils then Instance.new("UICorner", mapFrame).CornerRadius = UDim.new(0, 8) end
	print("MapManager: MapFrame created.")
	return mapFrame
end

function MapManager.LoadAndRenderMap(mapId, startX, startY)
	MapManager.DisconnectInput() 
	print(string.format("MapManager: Input disconnected for loading map %s", mapId))

	local mainGui, backgroundFrame, mapFrame = getMapUIElements()
	if not mapFrame then mapFrame = MapManager.CreateMapFrame(); if not mapFrame then MapManager.ConnectInput(); return end end
	if not MapManager.MapDatabase or not MapManager.MapDatabase.Maps or not MapManager.MapDatabase.Maps[mapId] then warn("MapManager.LoadAndRenderMap: Map data issue for mapId:", mapId); MapManager.ConnectInput(); return end

	local mapData = MapManager.MapDatabase.Maps[mapId]
	local tileProperties = mapData.TileProperties; local tilesData = mapData.Tiles; local npcsData = mapData.NPCs; local mobsData = mapData.Mobs
	local mapWidth = mapData.Width; local mapHeight = mapData.Height; local mapBgmId = mapData.BGM; local mapName = mapData.Name or "알 수 없는 지역"
	if not tileProperties or not tilesData or not mapWidth or not mapHeight or mapWidth <= 0 or mapHeight <= 0 then warn("MapManager.LoadAndRenderMap: Incomplete or invalid map data for mapId:", mapId); MapManager.ConnectInput(); return end

	print("MapManager: Rendering map:", mapId, "(", mapWidth, "x", mapHeight, ")")
	MapManager.currentMapId = mapId

	if MapManager.CoreUIManager and MapManager.CoreUIManager.ShowPopupMessage then MapManager.CoreUIManager.ShowPopupMessage("지역 이동", mapName .. " 에 도착했습니다.") else warn("[MapManager] CoreUIManager or ShowPopupMessage function not found!") end
	if MapManager.SoundManager and MapManager.SoundManager.PlayBGM then MapManager.SoundManager.PlayBGM(mapBgmId) else warn("MapManager: SoundManager or PlayBGM function not found!") end

	for _, child in ipairs(mapFrame:GetChildren()) do if child.Name:match("^Tile_") or child.Name:match("^TileSide_") or child.Name == "PlayerIcon" or (MapManager.npcIcons and MapManager.npcIcons[child.Name]) or (MapManager.mobIcons and MapManager.mobIcons[child.Name]) then pcall(function() child:Destroy() end) end end
	if MapManager.playerIcon then pcall(function() MapManager.playerIcon:Destroy() end); MapManager.playerIcon = nil end
	MapManager.npcIcons = {}; MapManager.mobIcons = {}

	MapManager.tileSizeUDim = UDim2.new(1 / mapWidth, 0, 1 / mapHeight, 0)
	local sideTileId = 15; local sideProperties = tileProperties and tileProperties[sideTileId] or {}
	for y = 1, mapHeight do
		if not tilesData[y] then break end
		for x = 1, mapWidth do
			local tileId = tilesData[y][x]; local properties = tileProperties and tileProperties[tileId] or {}; local tileHeight = properties.Height or 0; local tileObject
			if tileHeight > 0 and sideProperties.ImageId and sideProperties.ImageId ~= "" and sideProperties.ImageId ~= "rbxassetid://YOUR_CLIFF_SIDE_IMAGE_ID" then
				for i = 1, tileHeight do local sideTile = Instance.new("ImageLabel"); sideTile.Name = string.format("TileSide_%d_%d_%d", x, y, i); sideTile.Size = MapManager.tileSizeUDim; sideTile.Position = UDim2.new(MapManager.tileSizeUDim.X.Scale * (x - 1), 0, MapManager.tileSizeUDim.Y.Scale * (y - 1 + i), 0); sideTile.Image = sideProperties.ImageId; sideTile.ScaleType = Enum.ScaleType.Stretch; sideTile.BackgroundTransparency = 1; sideTile.BorderSizePixel = 0; sideTile.Parent = mapFrame; sideTile.ZIndex = mapFrame.ZIndex + y + x + i; sideTile:SetAttribute("Walkable", false) end
			end
			if properties.ImageId and properties.ImageId ~= "" and properties.ImageId ~= "rbxassetid://YOUR_PATH_IMAGE_ID" then tileObject = Instance.new("ImageLabel"); tileObject.Image = properties.ImageId; tileObject.ScaleType = Enum.ScaleType.Tile; tileObject.TileSize = UDim2.new(0, 32, 0, 32); tileObject.BackgroundTransparency = 1
			else tileObject = Instance.new("Frame"); tileObject.BackgroundColor3 = properties.Color or Color3.fromRGB(255, 0, 255); tileObject.BackgroundTransparency = 0 end
			tileObject.Name = string.format("Tile_%d_%d", x, y); tileObject.Size = MapManager.tileSizeUDim; tileObject.Position = UDim2.new(MapManager.tileSizeUDim.X.Scale * (x - 1), 0, MapManager.tileSizeUDim.Y.Scale * (y - 1), 0); tileObject.BorderSizePixel = 0; tileObject.Parent = mapFrame; tileObject.ZIndex = mapFrame.ZIndex + y + x + tileHeight + 1
			tileObject:SetAttribute("Walkable", properties.Walkable or false); tileObject:SetAttribute("TileID", tileId); tileObject:SetAttribute("TileX", x); tileObject:SetAttribute("TileY", y)
			if MapManager.GuiUtils then 
				if tileId == 1 then local g=Instance.new("UIGradient"); g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(190,170,130)),ColorSequenceKeypoint.new(1,Color3.fromRGB(170,150,110))}); g.Rotation=90; g.Parent=tileObject; local s=Instance.new("UIStroke"); s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Color=Color3.fromRGB(130,110,80); s.Thickness=1; s.Transparency=0.5; s.Parent=tileObject
				elseif tileId == 0 or tileId == 14 or tileId == 16 then local g=Instance.new("UIGradient"); g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(90,170,90)),ColorSequenceKeypoint.new(1,Color3.fromRGB(70,150,70))}); g.Rotation=90; g.Parent=tileObject
				elseif tileId == 2 or tileId == 12 then local g=Instance.new("UIGradient"); g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(120,120,120)),ColorSequenceKeypoint.new(1,Color3.fromRGB(80,80,80))}); g.Rotation=90; g.Parent=tileObject; local s=Instance.new("UIStroke"); s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Color=Color3.fromRGB(50,50,50); s.Thickness=2; s.Parent=tileObject
				elseif tileId == 3 then local g=Instance.new("UIGradient"); g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(110,110,220)),ColorSequenceKeypoint.new(1,Color3.fromRGB(90,90,180))}); g.Rotation=90; g.Parent=tileObject
				elseif tileId == 6 then local g=Instance.new("UIGradient"); g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(60,110,60)),ColorSequenceKeypoint.new(1,Color3.fromRGB(40,90,40))}); g.Rotation=90; g.Parent=tileObject; local s=Instance.new("UIStroke"); s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Color=Color3.fromRGB(30,70,30); s.Thickness=1; s.Parent=tileObject
				elseif tileId == 7 then local g=Instance.new("UIGradient"); g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(150,150,150)),ColorSequenceKeypoint.new(1,Color3.fromRGB(130,130,130))}); g.Rotation=0; g.Parent=tileObject
				elseif tileId == 8 then local g=Instance.new("UIGradient"); g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(110,80,60)),ColorSequenceKeypoint.new(1,Color3.fromRGB(90,60,40))}); g.Rotation=90; g.Parent=tileObject
				elseif tileId == 9 then local g=Instance.new("UIGradient"); g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(240,220,180)),ColorSequenceKeypoint.new(1,Color3.fromRGB(220,200,160))}); g.Rotation=45; g.Parent=tileObject
				elseif tileId == 10 then local g=Instance.new("UIGradient"); g.Color=ColorSequence.new({ColorSequenceKeypoint.new(0,Color3.fromRGB(140,190,230)),ColorSequenceKeypoint.new(1,Color3.fromRGB(120,170,210))}); g.Rotation=90; g.Parent=tileObject
				elseif tileId == 11 then local s=Instance.new("UIStroke"); s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Color=Color3.fromRGB(130,90,50); s.Thickness=1; s.Parent=tileObject
				elseif tileId == 13 then local s=Instance.new("UIStroke"); s.ApplyStrokeMode=Enum.ApplyStrokeMode.Border; s.Color=Color3.fromRGB(110,80,40); s.Thickness=1; s.Parent=tileObject
				end
			end
		end
	end

	if npcsData then for _, npcData in ipairs(npcsData) do local npcIconImage = Instance.new("ImageLabel"); npcIconImage.Name = npcData.ID; npcIconImage.Size = MapManager.tileSizeUDim; local npcX, npcY = npcData.X, npcData.Y; npcIconImage.Position = UDim2.new(MapManager.tileSizeUDim.X.Scale * (npcX - 1), 0, MapManager.tileSizeUDim.Y.Scale * (npcY - 1), 0); npcIconImage.Image = npcData.ImageId or ""; npcIconImage.ScaleType = Enum.ScaleType.Fit; npcIconImage.BackgroundTransparency = 1; npcIconImage.BorderSizePixel = 0; local npcTileId = (tilesData and tilesData[npcY] and tilesData[npcY][npcX]) or 0; local npcTileHeight = (tileProperties and tileProperties[npcTileId] and tileProperties[npcTileId].Height or 0); npcIconImage.ZIndex = mapFrame.ZIndex + npcY + npcX + npcTileHeight + 50; npcIconImage.Parent = mapFrame; npcIconImage:SetAttribute("NPCType", npcData.Type or "None"); npcIconImage:SetAttribute("NPCName", npcData.Name or "NPC"); npcIconImage:SetAttribute("NPCX", npcX); npcIconImage:SetAttribute("NPCY", npcY); MapManager.npcIcons[npcData.ID] = npcIconImage end end
	if mobsData then for _, mobData in ipairs(mobsData) do local mobIconImage = Instance.new("ImageLabel"); mobIconImage.Name = mobData.InstanceID; mobIconImage.Size = MapManager.tileSizeUDim; local mobX, mobY = mobData.X, mobData.Y; mobIconImage.Position = UDim2.new(MapManager.tileSizeUDim.X.Scale * (mobX - 1), 0, MapManager.tileSizeUDim.Y.Scale * (mobY - 1), 0); mobIconImage.Image = mobData.ImageId or ""; mobIconImage.ScaleType = Enum.ScaleType.Fit; mobIconImage.BackgroundTransparency = 1; mobIconImage.BorderSizePixel = 0; local mobTileId = (tilesData and tilesData[mobY] and tilesData[mobY][mobX]) or 0; local mobTileHeight = (tileProperties and tileProperties[mobTileId] and tileProperties[mobTileId].Height or 0); mobIconImage.ZIndex = mapFrame.ZIndex + mobY + mobX + mobTileHeight + 50; mobIconImage.Parent = mapFrame; mobIconImage:SetAttribute("EnemyID", mobData.EnemyID); mobIconImage:SetAttribute("InstanceID", mobData.InstanceID); mobIconImage:SetAttribute("MobX", mobX); mobIconImage:SetAttribute("MobY", mobY); MapManager.mobIcons[mobData.InstanceID] = mobIconImage end end

	if startX and startY then MapManager.playerMapX = startX; MapManager.playerMapY = startY; print("MapManager: Player starting at portal target:", MapManager.playerMapX, MapManager.playerMapY)
	else local startPos = mapData.PlayerStart or {X = 1, Y = 1}; MapManager.playerMapX = startPos.X; MapManager.playerMapY = startPos.Y; print("MapManager: Player starting at map default:", MapManager.playerMapX, MapManager.playerMapY) end

	MapManager.playerIcon = Instance.new("ImageLabel"); MapManager.playerIcon.Name = "PlayerIcon"; MapManager.playerIcon.Size = MapManager.tileSizeUDim; MapManager.playerIcon.Position = UDim2.new(MapManager.tileSizeUDim.X.Scale * (MapManager.playerMapX - 1), 0, MapManager.tileSizeUDim.Y.Scale * (MapManager.playerMapY - 1), 0); MapManager.playerIcon.BackgroundTransparency = 1; MapManager.playerIcon.BorderSizePixel = 0; MapManager.playerIcon.Parent = mapFrame; MapManager.playerIcon.ScaleType = Enum.ScaleType.Fit
	local localPlayer = game:GetService("Players").LocalPlayer
	if localPlayer then local success, content, isReady = pcall(function() return game:GetService("Players"):GetUserThumbnailAsync(localPlayer.UserId, Enum.ThumbnailType.HeadShot, Enum.ThumbnailSize.Size48x48) end); if success and isReady then MapManager.playerIcon.Image = content else warn("MapManager: Failed to get player thumbnail."); MapManager.playerIcon.Image = "" end else MapManager.playerIcon.Image = "" end

	MapManager.UpdatePlayerIconPosition()
	print("MapManager: Map rendering complete for", mapId)

	task.wait(0.2)
	MapManager.ConnectInput()
	print(string.format("MapManager: Input connected after loading map %s", mapId))
end

function MapManager.ConnectInput()
	if MapManager.inputConnection then return end
	local MIH = MapManager.ModuleManager and MapManager.ModuleManager:GetModule("MapInputHandler")
	MapManager.inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then return end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Space then
				MapManager.HandleInteraction()
			end
		end
	end)
	print("MapManager: Input connected.")
	if MIH and MIH.ConnectInput then MIH.ConnectInput() end
end

function MapManager.DisconnectInput()
	if MapManager.inputConnection then MapManager.inputConnection:Disconnect(); MapManager.inputConnection = nil; print("MapManager: Input disconnected.") end
	local MIH = MapManager.ModuleManager and MapManager.ModuleManager:GetModule("MapInputHandler")
	if MIH and MIH.DisconnectInput then MIH.DisconnectInput() end
end


-- ShowMapFrame 함수 수정: 페이드 인 효과 추가
function MapManager.ShowMapFrame(show)
	local mainGui, backgroundFrame, mapFrame = getMapUIElements()
	if not backgroundFrame then warn("MapManager.ShowMapFrame: BackgroundFrame not found!"); return end
	if not mapFrame and show then mapFrame = MapManager.CreateMapFrame() end
	if not mapFrame then return end

	if MapManager.CoreUIManager and MapManager.CoreUIManager.FadeScreen then
		if show then
			mapFrame.Visible = true -- 페이드 전에 일단 보이게 설정
			MapManager.CoreUIManager.FadeScreen(true, 0.3, function() -- 0.3초 동안 밝아짐
				print("MapManager: Map screen faded in.")
				if not MapManager.currentMapId then MapManager.LoadAndRenderMap("DefaultMap")
				else MapManager.LoadAndRenderMap(MapManager.currentMapId, MapManager.playerMapX, MapManager.playerMapY) end
				-- ConnectInput은 LoadAndRenderMap 내부에서 호출됨
				local mapData = MapManager.GetCurrentMapData(); local mapBgmId = mapData and mapData.BGM
				if MapManager.SoundManager and MapManager.SoundManager.PlayBGM then MapManager.SoundManager.PlayBGM(mapBgmId) end
				if MapManager.MobileControlsManager and MapManager.MobileControlsManager.ShowControls then pcall(MapManager.MobileControlsManager.ShowControls, true) end
			end)
		else
			-- 맵 숨길 때는 즉시 또는 페이드 아웃 (전투 시작 시 페이드 아웃은 HandleInteraction에서 별도 처리)
			mapFrame.Visible = false
			MapManager.DisconnectInput()
			if MapManager.SoundManager and MapManager.SoundManager.StopBGM then MapManager.SoundManager.StopBGM() end
			if MapManager.MobileControlsManager and MapManager.MobileControlsManager.ShowControls then pcall(MapManager.MobileControlsManager.ShowControls, false) end
		end
	else
		warn("MapManager.ShowMapFrame: CoreUIManager 또는 FadeScreen 함수를 찾을 수 없습니다. 즉시 표시/숨김 처리합니다.")
		mapFrame.Visible = show -- Fallback
		if show then
			if not MapManager.currentMapId then MapManager.LoadAndRenderMap("DefaultMap")
			else MapManager.LoadAndRenderMap(MapManager.currentMapId, MapManager.playerMapX, MapManager.playerMapY) end
			local mapData = MapManager.GetCurrentMapData(); local mapBgmId = mapData and mapData.BGM
			if MapManager.SoundManager and MapManager.SoundManager.PlayBGM then MapManager.SoundManager.PlayBGM(mapBgmId) end
			if MapManager.MobileControlsManager and MapManager.MobileControlsManager.ShowControls then pcall(MapManager.MobileControlsManager.ShowControls, true) end
		else
			MapManager.DisconnectInput()
			if MapManager.SoundManager and MapManager.SoundManager.StopBGM then MapManager.SoundManager.StopBGM() end
			if MapManager.MobileControlsManager and MapManager.MobileControlsManager.ShowControls then pcall(MapManager.MobileControlsManager.ShowControls, false) end
		end
	end
end

function MapManager.GetNpcDataAt(x, y)
	local mapData = MapManager.GetCurrentMapData()
	if not mapData or not mapData.NPCs then return nil end
	for _, npcData in ipairs(mapData.NPCs) do if npcData.X == x and npcData.Y == y then return npcData end end
	return nil
end

-- HandleInteraction 함수 수정: 전투 시작 시 페이드 아웃 로직 추가
function MapManager.HandleInteraction()
	print(string.format("[DEBUG] MapManager.HandleInteraction: Entered. Checking ShopUIManager at start. Type: %s", typeof(MapManager.ShopUIManager)))
	if not MapManager.CoreUIManager then warn("MapManager.HandleInteraction: CoreUIManager is nil!"); return end


	local mapData = MapManager.GetCurrentMapData()
	if not mapData then warn("MapManager.HandleInteraction: Current map data not available!"); return end
	local playerX, playerY = MapManager.GetPlayerPosition()
	if not playerX or not playerY then warn("MapManager.HandleInteraction: Failed to get player position."); return end

	local npcsData = mapData.NPCs; local portalsData = mapData.Portals; local mobsData = mapData.Mobs
	local player = game:GetService("Players").LocalPlayer
	if not player then warn("MapManager.HandleInteraction: LocalPlayer not found!"); return end

	print("MapManager: Interaction key pressed at", playerX, ",", playerY)

	local targetNpc = MapManager.GetNpcDataAt(playerX, playerY)
	if targetNpc then
		-- (NPC 상호작용 로직은 기존과 동일)
		print("MapManager: Interacting with NPC:", targetNpc.ID, "Name:", targetNpc.Name)
		if MapManager.DialogueManager and MapManager.DialogueManager.StartDialogue then
			pcall(MapManager.DialogueManager.StartDialogue, targetNpc.ID, targetNpc.Name)
		else
			warn("MapManager: DialogueManager not available! Using fallback interaction.")
			local npcType = targetNpc.Type or "None"
			if npcType == "Shop" then
				if MapManager.ShopUIManager and MapManager.ShopUIManager.ShowShop then MapManager.ShopUIManager.ShowShop(true); MapManager.ShowMapFrame(false)
				else warn("MapManager Fallback: ShopUIManager or ShowShop function is nil!") end
			elseif npcType == "Crafting" then
				if MapManager.CraftingUIManager and MapManager.CraftingUIManager.ShowCrafting then MapManager.CraftingUIManager.ShowCrafting(true); MapManager.ShowMapFrame(false)
				else warn("MapManager Fallback: CraftingUIManager or ShowCrafting function is nil!") end
			elseif npcType == "Gacha" then
				if MapManager.GachaUIManager and MapManager.GachaUIManager.ShowGacha then MapManager.GachaUIManager.ShowGacha(true); MapManager.ShowMapFrame(false)
				else warn("MapManager Fallback: GachaUIManager or ShowGacha function is nil!") end
			elseif npcType == "SkillShop" then
				if MapManager.SkillShopUIManager and MapManager.SkillShopUIManager.ShowSkillShop then MapManager.SkillShopUIManager.ShowSkillShop(true); MapManager.ShowMapFrame(false)
				else warn("MapManager Fallback: SkillShopUIManager or ShowSkillShop function is nil!") end
			end
		end
		return
	end

	local targetPortal = nil; if portalsData then for _, portalData in ipairs(portalsData) do if portalData.X == playerX and portalData.Y == playerY then targetPortal = portalData; break end end end
	if targetPortal then
		-- (포탈 이동 로직은 기존과 동일)
		local targetMapId = targetPortal.TargetMap; local targetX = targetPortal.TargetX; local targetY = targetPortal.TargetY; print("MapManager: Interacting with Portal to", targetMapId, "at", targetX, ",", targetY); if targetMapId then MapManager.LoadAndRenderMap(targetMapId, targetX, targetY) else warn("MapManager: Portal data is missing TargetMap!") end; return
	end

	local targetMob = nil; if mobsData then for _, mobData in ipairs(mobsData) do if mobData.X == playerX and mobData.Y == playerY then targetMob = mobData; break end end end
	if targetMob then
		print("MapManager: Interacting with Mob:", targetMob.InstanceID, "EnemyID:", targetMob.EnemyID);
		if MapManager.RequestStartCombatEvent and MapManager.CoreUIManager and MapManager.CoreUIManager.FadeScreen then
			print("MapManager: Fading out map screen to start combat...")
			MapManager.DisconnectInput() -- 입력 먼저 중지
			if MapManager.MobileControlsManager and MapManager.MobileControlsManager.ShowControls then
				pcall(MapManager.MobileControlsManager.ShowControls, false) -- 모바일 컨트롤 숨기기
			end
			if MapManager.SoundManager and MapManager.SoundManager.StopBGM then
				MapManager.SoundManager.StopBGM() -- 현재 맵 BGM 중지
			end

			MapManager.CoreUIManager.FadeScreen(false, 0.5, function() -- 0.5초 동안 어두워짐
				print("MapManager: Map screen faded out. Requesting combat start.")
				local enemyIdsToFight = {targetMob.EnemyID};
				MapManager.RequestStartCombatEvent:FireServer(enemyIdsToFight)
				MapManager.ShowMapFrame(false) -- 맵 UI 요소 정리 (실제로는 이미 안보임)
				-- 전투 화면 표시는 CombatUIManager.OnCombatStarted에서 처리
			end)
		else
			warn("MapManager: RequestStartCombatEvent 또는 CoreUIManager.FadeScreen 함수를 찾을 수 없습니다! 즉시 전투 시작 시도.")
			-- Fallback: 즉시 전투 시작
			MapManager.ShowMapFrame(false)
			local enemyIdsToFight = {targetMob.EnemyID};
			MapManager.RequestStartCombatEvent:FireServer(enemyIdsToFight)
		end;
		return
	end

	if not targetNpc and not targetPortal and not targetMob then print("MapManager: Nothing to interact with at current location.") end
end

return MapManager