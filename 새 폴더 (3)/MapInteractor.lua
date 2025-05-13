-- ReplicatedStorage > Modules > MapInputHandler.lua
-- (���� ������ ���� - ���� ����)

local MapInputHandler = {}

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModuleManager

local MapDatabase = nil

local inputConnection = nil
local isInputConnected = false

function MapInputHandler:Init() -- ':' ���
	if not ModuleManager then
		ModuleManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ModuleManager"))
		if not ModuleManager then
			warn("MapInputHandler.Init: Failed to load ModuleManager!")
			return
		end
	end
	if not MapDatabase then
		MapDatabase = ModuleManager:GetModule("MapDatabase")
		if not MapDatabase then
			warn("MapInputHandler.Init: Failed to load MapDatabase via ModuleManager!")
		end
	end
	print("MapInputHandler: Initialized.")
end

function MapInputHandler:MovePlayer(direction) -- ':' ���
	if not ModuleManager then warn("MapInputHandler.MovePlayer: ModuleManager not ready!"); return end
	local MapManager = ModuleManager:GetModule("MapManager")

	if not MapManager or not MapManager.GetCurrentMapData or not MapManager.GetPlayerPosition or not MapManager.SetPlayerPosition or not MapManager.UpdatePlayerIconPosition then
		warn("MapInputHandler.MovePlayer: MapManager not ready or required functions missing. Type:", typeof(MapManager))
		return
	end

	-- MapManager �Լ� ȣ�� �� ':' ��� ���� Ȯ�� �ʿ� - ���⼭�� '.'���� �����ϰ� ȣ��
	local mapData = MapManager.GetCurrentMapData(MapManager)
	local currentX, currentY = MapManager.GetPlayerPosition(MapManager)

	if not mapData or not currentX or not currentY then
		warn("MapInputHandler.MovePlayer: Failed to get current map data or player position.")
		return
	end

	local tilesData = mapData.Tiles
	local tileProperties = mapData.TileProperties
	local mapWidth = mapData.Width
	local mapHeight = mapData.Height

	local targetX = currentX
	local targetY = currentY

	if direction == "Up" then targetY = currentY - 1
	elseif direction == "Down" then targetY = currentY + 1
	elseif direction == "Left" then targetX = currentX - 1
	elseif direction == "Right" then targetX = currentX + 1
	else return end

	if targetX < 1 or targetX > mapWidth or targetY < 1 or targetY > mapHeight then
		return
	end

	local targetTileId = (tilesData and tilesData[targetY] and tilesData[targetY][targetX]) or -1
	local currentTileProps = tileProperties and tileProperties[targetTileId] or {}
	if not currentTileProps.Walkable then
		return
	end

	MapManager.SetPlayerPosition(MapManager, targetX, targetY) -- '.' ����
	MapManager.UpdatePlayerIconPosition(MapManager) -- '.' ����
end

local function handleInteractionInput()
	if not ModuleManager then warn("MapInputHandler.handleInteractionInput: ModuleManager not ready!"); return end
	local MapManager = ModuleManager:GetModule("MapManager")

	if MapManager and MapManager.HandleInteraction then
		MapManager:HandleInteraction() -- ':' �޼ҵ� ȣ�� (MapManager���� ':'���� ���������Ƿ�)
	else
		warn("MapInputHandler: Failed to load MapManager or HandleInteraction function!")
	end
end

function MapInputHandler:DisconnectInput() -- ':' ���
	if inputConnection then
		inputConnection:Disconnect()
		inputConnection = nil
	end
	isInputConnected = false
	print("MapInputHandler: Keyboard input disconnected.")
end

function MapInputHandler:ConnectInput() -- ':' ���
	if isInputConnected then return end
	self:DisconnectInput() -- ':' �޼ҵ� ȣ��

	inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then return end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Up or input.KeyCode == Enum.KeyCode.W then
				self:MovePlayer("Up") -- ':' �޼ҵ� ȣ��
			elseif input.KeyCode == Enum.KeyCode.Down or input.KeyCode == Enum.KeyCode.S then
				self:MovePlayer("Down") -- ':' �޼ҵ� ȣ��
			elseif input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.A then
				self:MovePlayer("Left") -- ':' �޼ҵ� ȣ��
			elseif input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.D then
				self:MovePlayer("Right") -- ':' �޼ҵ� ȣ��
			elseif input.KeyCode == Enum.KeyCode.Space then
				handleInteractionInput() -- ���� �Լ� ȣ��
			end
		end
	end)
	isInputConnected = true
	print("MapInputHandler: Keyboard input connected.")
end


return MapInputHandler