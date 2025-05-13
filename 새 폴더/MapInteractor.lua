-- ReplicatedStorage > Modules > MapInputHandler.lua
-- (이전 수정과 동일 - 변경 없음)

local MapInputHandler = {}

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModuleManager

local MapDatabase = nil

local inputConnection = nil
local isInputConnected = false

function MapInputHandler:Init() -- ':' 사용
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

function MapInputHandler:MovePlayer(direction) -- ':' 사용
	if not ModuleManager then warn("MapInputHandler.MovePlayer: ModuleManager not ready!"); return end
	local MapManager = ModuleManager:GetModule("MapManager")

	if not MapManager or not MapManager.GetCurrentMapData or not MapManager.GetPlayerPosition or not MapManager.SetPlayerPosition or not MapManager.UpdatePlayerIconPosition then
		warn("MapInputHandler.MovePlayer: MapManager not ready or required functions missing. Type:", typeof(MapManager))
		return
	end

	-- MapManager 함수 호출 시 ':' 사용 여부 확인 필요 - 여기서는 '.'으로 가정하고 호출
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

	MapManager.SetPlayerPosition(MapManager, targetX, targetY) -- '.' 가정
	MapManager.UpdatePlayerIconPosition(MapManager) -- '.' 가정
end

local function handleInteractionInput()
	if not ModuleManager then warn("MapInputHandler.handleInteractionInput: ModuleManager not ready!"); return end
	local MapManager = ModuleManager:GetModule("MapManager")

	if MapManager and MapManager.HandleInteraction then
		MapManager:HandleInteraction() -- ':' 메소드 호출 (MapManager에서 ':'으로 정의했으므로)
	else
		warn("MapInputHandler: Failed to load MapManager or HandleInteraction function!")
	end
end

function MapInputHandler:DisconnectInput() -- ':' 사용
	if inputConnection then
		inputConnection:Disconnect()
		inputConnection = nil
	end
	isInputConnected = false
	print("MapInputHandler: Keyboard input disconnected.")
end

function MapInputHandler:ConnectInput() -- ':' 사용
	if isInputConnected then return end
	self:DisconnectInput() -- ':' 메소드 호출

	inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then return end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Up or input.KeyCode == Enum.KeyCode.W then
				self:MovePlayer("Up") -- ':' 메소드 호출
			elseif input.KeyCode == Enum.KeyCode.Down or input.KeyCode == Enum.KeyCode.S then
				self:MovePlayer("Down") -- ':' 메소드 호출
			elseif input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.A then
				self:MovePlayer("Left") -- ':' 메소드 호출
			elseif input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.D then
				self:MovePlayer("Right") -- ':' 메소드 호출
			elseif input.KeyCode == Enum.KeyCode.Space then
				handleInteractionInput() -- 로컬 함수 호출
			end
		end
	end)
	isInputConnected = true
	print("MapInputHandler: Keyboard input connected.")
end


return MapInputHandler