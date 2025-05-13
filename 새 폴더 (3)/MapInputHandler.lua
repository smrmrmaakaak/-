-- ReplicatedStorage > Modules > MapInputHandler.lua
-- (수정: MovePlayer 함수 내부에 상세 디버깅 로그 추가)

local MapInputHandler = {}

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ModuleManager

local MapDatabase = nil

local inputConnection = nil
local isInputConnected = false

function MapInputHandler.Init()
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

-- ##### MovePlayer 함수에 디버깅 로그 추가 #####
function MapInputHandler.MovePlayer(direction)
	-- <<< 디버깅 로그 추가 >>>
	print(string.format("DEBUG: MapInputHandler.MovePlayer: Called with direction '%s'", direction))

	if not ModuleManager then warn("MapInputHandler.MovePlayer: ModuleManager not ready!"); return end
	local MapManager = ModuleManager:GetModule("MapManager")
	-- <<< 디버깅 로그 추가 >>>
	print(string.format("DEBUG: MapInputHandler.MovePlayer: Got MapManager. Type: %s", typeof(MapManager)))

	if not MapManager or not MapManager.GetCurrentMapData or not MapManager.GetPlayerPosition or not MapManager.SetPlayerPosition or not MapManager.UpdatePlayerIconPosition then
		warn("MapInputHandler.MovePlayer: MapManager not ready or required functions missing.")
		-- <<< 디버깅 로그 추가 >>>
		if MapManager then
			print(string.format("DEBUG: MapManager Function Types: GetCurrentMapData=%s, GetPlayerPosition=%s, SetPlayerPosition=%s, UpdatePlayerIconPosition=%s",
				typeof(MapManager.GetCurrentMapData), typeof(MapManager.GetPlayerPosition), typeof(MapManager.SetPlayerPosition), typeof(MapManager.UpdatePlayerIconPosition)))
		end
		return
	end

	local mapData = MapManager.GetCurrentMapData()
	local currentX, currentY = MapManager.GetPlayerPosition()
	-- <<< 디버깅 로그 추가 >>>
	print(string.format("DEBUG: MapInputHandler.MovePlayer: Current Pos=(%s, %s), MapData Type=%s", tostring(currentX), tostring(currentY), typeof(mapData)))


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

	-- <<< 디버깅 로그 추가 >>>
	print(string.format("DEBUG: MapInputHandler.MovePlayer: Target Pos=(%d, %d)", targetX, targetY))

	if targetX < 1 or targetX > mapWidth or targetY < 1 or targetY > mapHeight then
		print("DEBUG: MapInputHandler.MovePlayer: Target out of bounds.") -- 디버깅 로그 추가
		return
	end

	local targetTileId = (tilesData and tilesData[targetY] and tilesData[targetY][targetX]) or -1
	local currentTileProps = tileProperties and tileProperties[targetTileId] or {}
	-- <<< 디버깅 로그 추가 >>>
	print(string.format("DEBUG: MapInputHandler.MovePlayer: Target Tile ID=%s, Walkable=%s", tostring(targetTileId), tostring(currentTileProps.Walkable)))

	if not currentTileProps.Walkable then
		return
	end

	-- <<< 디버깅 로그 추가 >>>
	print("DEBUG: MapInputHandler.MovePlayer: Attempting to set position and update icon...")
	MapManager.SetPlayerPosition(targetX, targetY)
	MapManager.UpdatePlayerIconPosition()
	print("DEBUG: MapInputHandler.MovePlayer: Position and icon update called.") -- 디버깅 로그 추가
end
-- #########################################

local function handleInteractionInput()
	if not ModuleManager then warn("MapInputHandler.handleInteractionInput: ModuleManager not ready!"); return end
	local MapManager = ModuleManager:GetModule("MapManager")

	if MapManager and MapManager.HandleInteraction then
		MapManager.HandleInteraction()
	else
		warn("MapInputHandler: Failed to load MapManager or HandleInteraction function!")
	end
end

function MapInputHandler.DisconnectInput()
	if inputConnection then
		inputConnection:Disconnect()
		inputConnection = nil
	end
	isInputConnected = false
	print("MapInputHandler: Keyboard input disconnected.")
end

function MapInputHandler.ConnectInput()
	if isInputConnected then return end
	MapInputHandler.DisconnectInput()

	inputConnection = UserInputService.InputBegan:Connect(function(input, gameProcessedEvent)
		if gameProcessedEvent then return end
		if input.UserInputType == Enum.UserInputType.Keyboard then
			if input.KeyCode == Enum.KeyCode.Up or input.KeyCode == Enum.KeyCode.W then
				MapInputHandler.MovePlayer("Up")
			elseif input.KeyCode == Enum.KeyCode.Down or input.KeyCode == Enum.KeyCode.S then
				MapInputHandler.MovePlayer("Down")
			elseif input.KeyCode == Enum.KeyCode.Left or input.KeyCode == Enum.KeyCode.A then
				MapInputHandler.MovePlayer("Left")
			elseif input.KeyCode == Enum.KeyCode.Right or input.KeyCode == Enum.KeyCode.D then
				MapInputHandler.MovePlayer("Right")
			elseif input.KeyCode == Enum.KeyCode.Space then
				handleInteractionInput()
			end
		end
	end)
	isInputConnected = true
	print("MapInputHandler: Keyboard input connected.")
end


return MapInputHandler