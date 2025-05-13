-- MobileControlsManager.lua (수정: 확인 버튼에서 MapManager 직접 require 시도)

local MobileControlsManager = {}

-- 필요한 서비스 가져오기
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- *** 수정: ModuleManager 직접 require (MapInputHandler도 여기서 로드) ***
local ModuleManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("ModuleManager"))
local MapInputHandler = ModuleManager:GetModule("MapInputHandler")

-- 참조할 모듈 변수 (Init 함수에서 설정)
local GuiUtils = nil
--[[ 제거: Init에서 받지만 Interact 버튼에서는 직접 로드 시도
local MapManager = nil
]]

-- 상태 변수
local isMobile = true -- UserInputService.TouchEnabled and not UserInputService.MouseEnabled
print("[DEBUG] MobileControlsManager: isMobile forced to:", isMobile)

local isManuallyHidden = false
local isMapActive = false
local controlsFrame = nil
local upButton, downButton, leftButton, rightButton, interactButton, toggleButton -- UI 요소 참조

-- 내부 함수: 버튼 생성 (동일)
local function createButton(name, parent, position, size, text, anchorPoint)
	local button = Instance.new("TextButton")
	button.Name = name; button.Parent = parent; button.Size = size; button.Position = position; button.AnchorPoint = anchorPoint or Vector2.new(0, 0)
	button.Text = text; button.BackgroundColor3 = Color3.fromRGB(80, 80, 100); button.TextColor3 = Color3.fromRGB(255, 255, 255); button.Font = Enum.Font.SourceSansBold
	button.TextSize = 24; button.AutoButtonColor = true; button.BorderSizePixel = 0
	local corner = Instance.new("UICorner"); corner.CornerRadius = UDim.new(0, 8); corner.Parent = button
	return button
end

-- 모듈 초기화 함수 (MapInputHandler 인자 제거, MapManager는 일단 받음)
function MobileControlsManager.Init(mapManagerInstance, guiUtilsInstance) -- <<< mapInputHandlerInstance 제거
	print("[DEBUG] MobileControlsManager.Init called. Received MapManager type:", typeof(mapManagerInstance))
	if not mapManagerInstance then warn("MobileControlsManager.Init: mapManagerInstance is nil!") end
	if not guiUtilsInstance then warn("MobileControlsManager.Init: guiUtilsInstance is nil!") end

	MobileControlsManager.MapManager = mapManagerInstance -- Interact 버튼 외 다른 곳에서 쓸 수 있으므로 일단 저장
	MobileControlsManager.GuiUtils = guiUtilsInstance
	print("MobileControlsManager: Initialized. IsMobile:", isMobile)
	print("[DEBUG] MobileControlsManager.Init: Stored MapManager type:", typeof(MobileControlsManager.MapManager), "Directly required MapInputHandler type:", typeof(MapInputHandler))
end

-- 모바일 조작 UI 생성 함수 (확인 버튼 콜백 수정)
function MobileControlsManager.CreateControls(parentGui)
	if controlsFrame then warn("MobileControlsManager: Controls already created."); return end

	-- *** 수정: MapInputHandler 직접 로드 확인 ***
	if not MobileControlsManager.MapManager or not MapInputHandler then
		warn("MobileControlsManager: MapManager or (directly required) MapInputHandler reference missing. Cannot create controls.")
		print("[DEBUG] MobileControlsManager.CreateControls: Failed check! MapManager type:", typeof(MobileControlsManager.MapManager), "Direct MapInputHandler type:", typeof(MapInputHandler))
		return
	end

	print("MobileControlsManager: Creating mobile controls UI...")

	-- UI 생성 (동일)
	controlsFrame = Instance.new("Frame"); controlsFrame.Name = "MobileControlsFrame"; controlsFrame.Size = UDim2.new(1, 0, 1, 0); controlsFrame.Position = UDim2.new(0, 0, 0, 0); controlsFrame.BackgroundTransparency = 1; controlsFrame.Parent = parentGui; controlsFrame.Visible = false; controlsFrame.ZIndex = 100
	local dpadFrame = Instance.new("Frame"); dpadFrame.Name = "DPadFrame"; dpadFrame.Size = UDim2.new(0, 150, 0, 150); dpadFrame.Position = UDim2.new(0.01, 0, 1, -10); dpadFrame.AnchorPoint = Vector2.new(0, 1); dpadFrame.BackgroundTransparency = 1; dpadFrame.Parent = controlsFrame
	local dpadButtonSize = UDim2.new(0, 50, 0, 50)
	upButton = createButton("UpButton", dpadFrame, UDim2.new(0.5, 0, 0, 0), dpadButtonSize, "↑", Vector2.new(0.5, 0))
	downButton = createButton("DownButton", dpadFrame, UDim2.new(0.5, 0, 1, 0), dpadButtonSize, "↓", Vector2.new(0.5, 1))
	leftButton = createButton("LeftButton", dpadFrame, UDim2.new(0, 0, 0.5, 0), dpadButtonSize, "←", Vector2.new(0, 0.5))
	rightButton = createButton("RightButton", dpadFrame, UDim2.new(1, 0, 0.5, 0), dpadButtonSize, "→", Vector2.new(1, 0.5))
	interactButton = createButton("InteractButton", controlsFrame, UDim2.new(1, -10, 1, -35), UDim2.new(0, 75, 0, 75),"확인", Vector2.new(1, 1)); interactButton.BackgroundColor3 = Color3.fromRGB(100, 180, 100)

	-- 방향키 버튼 이벤트 연결 (직접 require한 MapInputHandler 사용 - 이전과 동일)
	upButton.MouseButton1Click:Connect(function() print("[DEBUG] UpButton Clicked."); if MapInputHandler and MapInputHandler.MovePlayer then MapInputHandler.MovePlayer("Up") else warn("MobileControls: MapInputHandler or MovePlayer is nil!") end end)
	downButton.MouseButton1Click:Connect(function() print("[DEBUG] DownButton Clicked."); if MapInputHandler and MapInputHandler.MovePlayer then MapInputHandler.MovePlayer("Down") else warn("MobileControls: MapInputHandler or MovePlayer is nil!") end end)
	leftButton.MouseButton1Click:Connect(function() print("[DEBUG] LeftButton Clicked."); if MapInputHandler and MapInputHandler.MovePlayer then MapInputHandler.MovePlayer("Left") else warn("MobileControls: MapInputHandler or MovePlayer is nil!") end end)
	rightButton.MouseButton1Click:Connect(function() print("[DEBUG] RightButton Clicked."); if MapInputHandler and MapInputHandler.MovePlayer then MapInputHandler.MovePlayer("Right") else warn("MobileControls: MapInputHandler or MovePlayer is nil!") end end)

	-- *** 확인 버튼 이벤트 연결 수정: 클릭 시 MapManager 직접 require ***
	interactButton.MouseButton1Click:Connect(function()
		print("[DEBUG] InteractButton Clicked. Requiring MapManager directly...")
		-- 클릭 시점에 MapManager 모듈을 다시 로드/참조
		local CurrentMapManager = ModuleManager:GetModule("MapManager")
		print("[DEBUG] typeof(CurrentMapManager):", typeof(CurrentMapManager))
		print("[DEBUG] typeof(CurrentMapManager.HandleInteraction):", typeof(CurrentMapManager and CurrentMapManager.HandleInteraction))

		if CurrentMapManager and CurrentMapManager.HandleInteraction then
			CurrentMapManager.HandleInteraction() -- 직접 로드한 참조로 함수 호출
		else
			warn("MobileControls: Failed to get MapManager or HandleInteraction on click!")
		end
	end)

	print("MobileControlsManager: Mobile controls UI created and events connected.")
end

-- 토글 버튼 설정 함수 (동일)
function MobileControlsManager.SetupToggleButton(buttonInstance)
	toggleButton = buttonInstance
	if toggleButton then
		toggleButton.Visible = true
		toggleButton.MouseButton1Click:Connect(MobileControlsManager.ToggleManualVisibility)
		print("MobileControlsManager: Toggle button setup complete.")
	else
		warn("MobileControlsManager.SetupToggleButton: Button instance is nil.")
	end
end

-- 수동 표시/숨기기 토글 함수 (동일)
function MobileControlsManager.ToggleManualVisibility()
	if not controlsFrame or not toggleButton then return end
	isManuallyHidden = not isManuallyHidden
	if isManuallyHidden then
		controlsFrame.Visible = false; toggleButton.Text = "키패드 보이기"
		print("MobileControlsManager: Controls manually hidden.")
	else
		if isMapActive then controlsFrame.Visible = true end
		toggleButton.Text = "키패드 숨기기"
		print("MobileControlsManager: Controls manually shown (visible if map is active).")
	end
end

-- 모바일 조작 UI 보이기/숨기기 함수 (동일 - isMobile 강제 true 유지)
function MobileControlsManager.ShowControls(show)
	if not controlsFrame then warn("MobileControlsManager.ShowControls: controlsFrame is nil!"); return end
	isMapActive = show
	if toggleButton then toggleButton.Visible = true end
	if show then
		if not isManuallyHidden then
			controlsFrame.Visible = true
			if toggleButton then toggleButton.Text = "키패드 숨기기" end
		else
			controlsFrame.Visible = false
			if toggleButton then toggleButton.Text = "키패드 보이기" end
		end
		print("MobileControlsManager: ShowControls(true) called. Controls visible:", controlsFrame.Visible)
	else
		controlsFrame.Visible = false
		if toggleButton then
			toggleButton.Text = isManuallyHidden and "키패드 보이기" or "키패드 숨기기"
		end
		print("MobileControlsManager: ShowControls(false) called. Controls hidden.")
	end
end

return MobileControlsManager