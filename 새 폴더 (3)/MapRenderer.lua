-- ReplicatedStorage > Modules > MapRenderer.lua
-- ����: �� ������ ��� GUI ������ ��� (Ÿ��, NPC, ����, �÷��̾� ������ ��)

local MapRenderer = {}

-- �ʿ��� ���� �� ��� �ε�
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService") -- �÷��̽�Ȧ�� �̹�����

local ModuleManager -- Init �� �ε�
local MapDatabase -- Init���� �ε�
local GuiUtils -- Init���� �ε�

-- ��� ���� ���� (������ ����)
local npcIcons = {} -- ������ NPC ������ ���� ���� (������)
local mobIcons = {} -- ������ ���� ������ ���� ���� (������)
local playerIcon = nil -- ������ �÷��̾� ������ ���� ����

-- ��� �ʱ�ȭ
function MapRenderer.Init()
	-- ModuleManager�� GuiManager���� �̹� �ε�Ǿ����Ƿ� ���⼭ �ٽ� �ε��� �ʿ� ����
	-- ��, �����ϰ� �ϱ� ���� require ���
	ModuleManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ModuleManager"))
	MapDatabase = ModuleManager:GetModule("MapDatabase")
	GuiUtils = ModuleManager:GetModule("GuiUtils")
	if not MapDatabase then warn("MapRenderer.Init: Failed to load MapDatabase!") end
	if not GuiUtils then warn("MapRenderer.Init: Failed to load GuiUtils!") end
	print("MapRenderer: Initialized.")
end

-- �� ������ �ʱ�ȭ (���� ���� ����)
function MapRenderer.ClearMapFrame(mapFrame)
	if not mapFrame then return end
	for _, child in ipairs(mapFrame:GetChildren()) do
		if child.Name:match("^Tile_") or child.Name:match("^TileSide_") or child.Name:match("^NPC_") or child.Name:match("^Mob_") or child.Name == "PlayerIcon" then
			child:Destroy()
		end
	end
	npcIcons = {}
	mobIcons = {}
	playerIcon = nil
	-- print("MapRenderer: Map frame cleared.") -- �ʹ� ���� ȣ��� �� �����Ƿ� �ּ� ó��
end

-- �� Ÿ�� ������ �Լ� (���� ����)
function MapRenderer.RenderTiles(mapFrame, mapData, tileSizeUDim)
	if not mapFrame or not mapData or not tileSizeUDim then warn("MapRenderer.RenderTiles: Invalid arguments."); return end
	if not MapDatabase or not MapDatabase.Maps then warn("MapRenderer.RenderTiles: MapDatabase not loaded."); return end
	local tileProperties = mapData.TileProperties; local tilesData = mapData.Tiles; local mapWidth = mapData.Width; local mapHeight = mapData.Height
	if not tileProperties or not tilesData or not mapWidth or not mapHeight or mapWidth <= 0 or mapHeight <= 0 then warn("MapRenderer.RenderTiles: Incomplete or invalid map data."); return end
	-- print("MapRenderer: Rendering tiles...") -- �ʹ� ���� ȣ��� �� �����Ƿ� �ּ� ó��
	local sideTileId = 15; local sideProperties = tileProperties[sideTileId] or {}
	for y = 1, mapHeight do
		if not tilesData[y] then break end
		for x = 1, mapWidth do
			local tileId = tilesData[y][x]; local properties = tileProperties[tileId] or {}; local tileHeight = properties.Height or 0; local tileObject
			if tileHeight > 0 and sideProperties.ImageId and sideProperties.ImageId ~= "" and sideProperties.ImageId ~= "rbxassetid://YOUR_CLIFF_SIDE_IMAGE_ID" then
				for i = 1, tileHeight do
					local sideTile = Instance.new("ImageLabel"); sideTile.Name = string.format("TileSide_%d_%d_%d", x, y, i); sideTile.Size = tileSizeUDim
					sideTile.Position = UDim2.new(tileSizeUDim.X.Scale * (x - 1), 0, tileSizeUDim.Y.Scale * (y - 1 + i), 0); sideTile.Image = sideProperties.ImageId
					sideTile.ScaleType = Enum.ScaleType.Stretch; sideTile.BackgroundTransparency = 1; sideTile.BorderSizePixel = 0; sideTile.Parent = mapFrame
					sideTile.ZIndex = mapFrame.ZIndex + y + x + i; sideTile:SetAttribute("Walkable", false)
				end
			end
			if properties.ImageId and properties.ImageId ~= "" and properties.ImageId ~= "rbxassetid://YOUR_PATH_IMAGE_ID" then
				tileObject = Instance.new("ImageLabel"); tileObject.Image = properties.ImageId; tileObject.ScaleType = Enum.ScaleType.Tile
				tileObject.TileSize = UDim2.new(0, 32, 0, 32); tileObject.BackgroundTransparency = 1
			else
				tileObject = Instance.new("Frame"); tileObject.BackgroundColor3 = properties.Color or Color3.fromRGB(255, 0, 255); tileObject.BackgroundTransparency = 0
			end
			tileObject.Name = string.format("Tile_%d_%d", x, y); tileObject.Size = tileSizeUDim; tileObject.Position = UDim2.new(tileSizeUDim.X.Scale * (x - 1), 0, tileSizeUDim.Y.Scale * (y - 1), 0)
			tileObject.BorderSizePixel = 0; tileObject.Parent = mapFrame; tileObject.ZIndex = mapFrame.ZIndex + y + x + tileHeight + 1
			tileObject:SetAttribute("Walkable", properties.Walkable or false); tileObject:SetAttribute("TileID", tileId); tileObject:SetAttribute("TileX", x); tileObject:SetAttribute("TileY", y)
			if GuiUtils then
				if tileId == 0 or tileId == 14 or tileId == 16 then local g = Instance.new("UIGradient"); g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 170, 90)), ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 150, 70))}); g.Rotation = 90; g.Parent = tileObject
				elseif tileId == 1 then local g = Instance.new("UIGradient"); g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(190, 170, 130)), ColorSequenceKeypoint.new(1, Color3.fromRGB(170, 150, 110))}); g.Rotation = 90; g.Parent = tileObject; local s = Instance.new("UIStroke"); s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Color = Color3.fromRGB(130, 110, 80); s.Thickness = 1; s.Transparency = 0.5; s.Parent = tileObject
				elseif tileId == 2 or tileId == 12 then local g = Instance.new("UIGradient"); g.Color = ColorSequence.new({ColorSequenceKeypoint.new(0, Color3.fromRGB(120, 120, 120)), ColorSequenceKeypoint.new(1, Color3.fromRGB(80, 80, 80))}); g.Rotation = 90; g.Parent = tileObject; local s = Instance.new("UIStroke"); s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border; s.Color = Color3.fromRGB(50, 50, 50); s.Thickness = 2; s.Parent = tileObject end
				-- ... (�ٸ� Ÿ�� ȿ���� �߰�) ...
			end
		end
	end
	-- print("MapRenderer: Tile rendering complete.")
end

-- NPC ������ ������ �Լ� (���� ����)
function MapRenderer.RenderNPCs(mapFrame, mapData, tileSizeUDim)
	if not mapFrame or not mapData or not mapData.NPCs or not tileSizeUDim then return end
	if not MapDatabase or not MapDatabase.Maps then warn("MapRenderer.RenderNPCs: MapDatabase not loaded."); return end
	-- print("MapRenderer: Rendering NPCs...")
	local npcsData = mapData.NPCs; local tilesData = mapData.Tiles; local tileProperties = mapData.TileProperties
	for _, npcData in ipairs(npcsData) do
		local npcIconImage = Instance.new("ImageLabel"); npcIconImage.Name = "NPC_" .. npcData.ID; npcIconImage.Size = tileSizeUDim
		local npcX, npcY = npcData.X, npcData.Y; npcIconImage.Position = UDim2.new(tileSizeUDim.X.Scale * (npcX - 1), 0, tileSizeUDim.Y.Scale * (npcY - 1), 0)
		npcIconImage.Image = npcData.ImageId or ""; npcIconImage.ScaleType = Enum.ScaleType.Fit; npcIconImage.BackgroundTransparency = 1; npcIconImage.BorderSizePixel = 0
		local npcTileId = (tilesData and tilesData[npcY] and tilesData[npcY][npcX]) or 0; local npcTileHeight = (tileProperties[npcTileId] and tileProperties[npcTileId].Height or 0)
		npcIconImage.ZIndex = mapFrame.ZIndex + npcY + npcX + npcTileHeight + 50; npcIconImage.Parent = mapFrame
		npcIconImage:SetAttribute("NPCType", npcData.Type or "None"); npcIconImage:SetAttribute("NPCName", npcData.Name or "NPC"); npcIconImage:SetAttribute("NPCX", npcX); npcIconImage:SetAttribute("NPCY", npcY); npcIconImage:SetAttribute("NPCID", npcData.ID)
		npcIcons[npcData.ID] = npcIconImage
	end
	-- print("MapRenderer: NPC rendering complete.")
end

-- ���� ������ ������ �Լ� (���� ����)
function MapRenderer.RenderMobs(mapFrame, mapData, tileSizeUDim)
	if not mapFrame or not mapData or not mapData.Mobs or not tileSizeUDim then return end
	if not MapDatabase or not MapDatabase.Maps then warn("MapRenderer.RenderMobs: MapDatabase not loaded."); return end
	-- print("MapRenderer: Rendering Mobs...")
	local mobsData = mapData.Mobs; local tilesData = mapData.Tiles; local tileProperties = mapData.TileProperties
	for _, mobData in ipairs(mobsData) do
		local mobIconImage = Instance.new("ImageLabel"); mobIconImage.Name = "Mob_" .. mobData.InstanceID; mobIconImage.Size = tileSizeUDim
		local mobX, mobY = mobData.X, mobData.Y; mobIconImage.Position = UDim2.new(tileSizeUDim.X.Scale * (mobX - 1), 0, tileSizeUDim.Y.Scale * (mobY - 1), 0)
		mobIconImage.Image = mobData.ImageId or ""; mobIconImage.ScaleType = Enum.ScaleType.Fit; mobIconImage.BackgroundTransparency = 1; mobIconImage.BorderSizePixel = 0
		local mobTileId = (tilesData and tilesData[mobY] and tilesData[mobY][mobX]) or 0; local mobTileHeight = (tileProperties[mobTileId] and tileProperties[mobTileId].Height or 0)
		mobIconImage.ZIndex = mapFrame.ZIndex + mobY + mobX + mobTileHeight + 50; mobIconImage.Parent = mapFrame
		mobIconImage:SetAttribute("EnemyID", mobData.EnemyID); mobIconImage:SetAttribute("InstanceID", mobData.InstanceID); mobIconImage:SetAttribute("MobX", mobX); mobIconImage:SetAttribute("MobY", mobY)
		mobIcons[mobData.InstanceID] = mobIconImage
	end
	-- print("MapRenderer: Mob rendering complete.")
end

-- �÷��̾� ������ ���� �Լ� (���� ����)
function MapRenderer.CreatePlayerIcon(mapFrame, tileSizeUDim)
	if not mapFrame or not tileSizeUDim then return nil end
	if playerIcon then playerIcon:Destroy(); playerIcon = nil end
	playerIcon = Instance.new("ImageLabel"); playerIcon.Name = "PlayerIcon"; playerIcon.Size = tileSizeUDim; playerIcon.Position = UDim2.new(0, 0, 0, 0)
	playerIcon.BackgroundTransparency = 1; playerIcon.BorderSizePixel = 0; playerIcon.Parent = mapFrame; playerIcon.ScaleType = Enum.ScaleType.Fit; playerIcon.ZIndex = mapFrame.ZIndex + 1000
	local localPlayer = Players.LocalPlayer
	if localPlayer then
		local thumbType = Enum.ThumbnailType.HeadShot; local thumbSize = Enum.ThumbnailSize.Size48x48
		local success, content, isReady = pcall(function() return Players:GetUserThumbnailAsync(localPlayer.UserId, thumbType, thumbSize) end)
		if success and isReady then playerIcon.Image = content else warn("MapRenderer: Failed to get player thumbnail. Error:", content); playerIcon.Image = "rbxassetid://188661731" end
	else warn("MapRenderer: LocalPlayer not found for thumbnail."); playerIcon.Image = "rbxassetid://188661731" end
	print("MapRenderer: Player icon created.")
	return playerIcon
end

-- �÷��̾� ������ ��ġ �� ZIndex ������Ʈ �Լ� (���� ����)
function MapRenderer.UpdatePlayerIconPosition(mapFrame, playerIconInstance, playerMapX, playerMapY, tileSizeUDim, mapData)
	if not mapFrame or not playerIconInstance or not playerMapX or not playerMapY or not tileSizeUDim or not mapData then return end
	if not MapDatabase or not MapDatabase.Maps then warn("MapRenderer.UpdatePlayerIconPosition: MapDatabase not loaded."); return end
	local posX = tileSizeUDim.X.Scale * (playerMapX - 1); local posY = tileSizeUDim.Y.Scale * (playerMapY - 1)
	playerIconInstance.Position = UDim2.new(posX, 0, posY, 0); playerIconInstance.Size = tileSizeUDim
	local tileProperties = mapData.TileProperties; local tilesData = mapData.Tiles
	if tilesData and tilesData[playerMapY] and tilesData[playerMapY][playerMapX] then
		local playerTileId = tilesData[playerMapY][playerMapX]; local playerTileHeight = (tileProperties[playerTileId] and tileProperties[playerTileId].Height or 0)
		playerIconInstance.ZIndex = mapFrame.ZIndex + playerMapY + playerMapX + playerTileHeight + 100
	else playerIconInstance.ZIndex = mapFrame.ZIndex + 1000; warn("MapRenderer.UpdatePlayerIconPosition: Invalid player position for ZIndex calculation:", playerMapX, playerMapY) end
end

-- *** ���� ���� Init() ȣ�� ���� ***
-- MapRenderer.Init()

return MapRenderer
