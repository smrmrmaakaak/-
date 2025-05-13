-- CoreUIManager.lua

local CoreUIManager = {}

-- �ʿ��� ���� �� ��� �ε�
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local ModuleManager
local GuiUtils
local mainGui = nil
local screenFadeFrame = nil

-- ##### [��� �߰�/����] ���� Ȱ��ȭ�� �ֿ� �˾� UI ������ ���� #####
local currentActiveMainUIPopupFrame = nil
local mainUIPopupFrameNames = { -- �ֿ� �˾����� ���ֵ� ������ �̸� ���
	"InventoryFrame", "EquipmentFrame", "StatsFrame", "ShopFrame", "CraftingFrame",
	"GachaFrame", "SkillShopFrame", "EnhancementFrame", "SettingsFrame",
	"CompanionFrame", "LeaderboardFrame", "DialogueFrame", "CombatResultsFrame"
	-- "ConsumableItemListFrame" -- �� �������� �ٸ� ���� �˾��� ���� �ʵ��� ���⼭ �����մϴ�.
}
-- ##############################################################

-- ��� �ʱ�ȭ
function CoreUIManager.Init()
	ModuleManager = require(ReplicatedStorage.Modules:WaitForChild("ModuleManager"))
	GuiUtils = ModuleManager:GetModule("GuiUtils")
	local player = Players.LocalPlayer
	local playerGui = player and player:WaitForChild("PlayerGui")
	mainGui = playerGui and playerGui:WaitForChild("MainGui")
	if not mainGui then warn("CoreUIManager.Init: MainGui�� ã�� �� �����ϴ�!") return end

	screenFadeFrame = mainGui:FindFirstChild("ScreenFadeFrame")
	if not screenFadeFrame then
		screenFadeFrame = Instance.new("Frame")
		screenFadeFrame.Name = "ScreenFadeFrame"
		screenFadeFrame.Parent = mainGui
		screenFadeFrame.Size = UDim2.new(1, 0, 1, 0)
		screenFadeFrame.Position = UDim2.new(0, 0, 0, 0)
		screenFadeFrame.BackgroundColor3 = Color3.new(0, 0, 0)
		screenFadeFrame.BackgroundTransparency = 1
		screenFadeFrame.ZIndex = 500
		screenFadeFrame.Visible = true
		print("CoreUIManager: ScreenFadeFrame ������.")
	end

	print("CoreUIManager: Initialized and modules loaded.")
end

local function getCoreUIElements()
	if not mainGui then
		local player = Players.LocalPlayer
		local playerGui = player and player:WaitForChild("PlayerGui")
		mainGui = playerGui and playerGui:FindFirstChild("MainGui")
		if not mainGui then
			warn("CoreUIManager.getCoreUIElements: MainGui is still nil after re-check!")
			return nil, nil, nil
		end
	end
	local bg = mainGui:FindFirstChild("BackgroundFrame")
	local ff = bg and bg:FindFirstChild("Frames")
	return mainGui, bg, ff
end

function CoreUIManager.ShowFrame(frameName, show)
	local currentMainGui, bgFrame, fFolder = getCoreUIElements()
	if not bgFrame then
		warn("CoreUIManager.ShowFrame: BackgroundFrame not found for frame: " .. frameName)
		return
	end

	local frame = nil
	if fFolder then
		frame = fFolder:FindFirstChild(frameName)
	end
	if not frame then
		frame = bgFrame:FindFirstChild(frameName)
	end
	-- ConsumableItemListFrame�� CompanionFrame ���ο� ���� �� ����
	if not frame and frameName == "ConsumableItemListFrame" then
		local compFrame = bgFrame:FindFirstChild("CompanionFrame") -- Frames ������ �ƴ� BackgroundFrame �ٷ� �Ʒ��� CompanionFrame�� ���� �� ����
		if not compFrame and fFolder then compFrame = fFolder:FindFirstChild("CompanionFrame") end

		if compFrame then
			frame = compFrame:FindFirstChild("ConsumableItemListFrame")
		end
	end


	if frame then
		frame.Visible = show
		print("CoreUIManager: Frame '"..frameName.."' visibility set to", show)

		local isMainPopup = false
		for _, name in ipairs(mainUIPopupFrameNames) do
			if name == frameName then
				isMainPopup = true
				break
			end
		end

		if not show and currentActiveMainUIPopupFrame == frame and isMainPopup then
			currentActiveMainUIPopupFrame = nil
		end
	else
		warn("CoreUIManager.ShowFrame: Frame '"..frameName.."' not found!")
	end
end

-- ������ OpenMainUIPopup �Լ�
function CoreUIManager.OpenMainUIPopup(frameNameToOpen)
	print("CoreUIManager.OpenMainUIPopup: Request to open", frameNameToOpen)
	local currentMainGui, bgFrame, fFolder = getCoreUIElements()
	if not bgFrame then warn("CoreUIManager.OpenMainUIPopup: BackgroundFrame not found!"); return end

	local frameToOpenInstance = nil
	if fFolder then frameToOpenInstance = fFolder:FindFirstChild(frameNameToOpen) end
	if not frameToOpenInstance then frameToOpenInstance = bgFrame:FindFirstChild(frameNameToOpen) end

	-- ConsumableItemListFrame ó�� (CompanionFrame ���ο� ���� ���)
	if not frameToOpenInstance and frameNameToOpen == "ConsumableItemListFrame" then
		local compFrame = bgFrame:FindFirstChild("CompanionFrame")
		if not compFrame and fFolder then compFrame = fFolder:FindFirstChild("CompanionFrame") end
		if compFrame then
			frameToOpenInstance = compFrame:FindFirstChild("ConsumableItemListFrame")
			if frameToOpenInstance then
				print("CoreUIManager.OpenMainUIPopup: Found ConsumableItemListFrame inside CompanionFrame.")
			end
		end
	end

	if not frameToOpenInstance then
		warn("CoreUIManager.OpenMainUIPopup: Frame to open '"..frameNameToOpen.."' not found!")
		return
	end

	local isFrameLegitMainPopup = false
	for _, name in ipairs(mainUIPopupFrameNames) do
		if name == frameNameToOpen then
			isFrameLegitMainPopup = true
			break
		end
	end

	if not isFrameLegitMainPopup and frameNameToOpen ~= "ConsumableItemListFrame" then
		warn("CoreUIManager.OpenMainUIPopup: '" .. frameNameToOpen .. "' is not registered as a main UI popup. Use ShowFrame directly if this is intended.")
		CoreUIManager.ShowFrame(frameNameToOpen, true)
		return
	end

	-- ConsumableItemListFrame�� �ƴϰ�, ���� ���� �ֿ� �˾��� �ְ�, ���� ������ �˾��� �ٸ� ���� ���� �˾� �ݱ�
	if isFrameLegitMainPopup and currentActiveMainUIPopupFrame and currentActiveMainUIPopupFrame.Name ~= frameNameToOpen then
		print("CoreUIManager.OpenMainUIPopup: Closing currently active main popup -", currentActiveMainUIPopupFrame.Name)

		local managerToCall = nil
		local functionToCall = nil
		local functionArgs = {false} -- �⺻������ 'false' ���ڸ� �����Ͽ� �ݵ��� ��

		local activeFrameName = currentActiveMainUIPopupFrame.Name

		-- ������ �̸��� ���� �Ŵ��� �� �Լ� ���� (�� ��Ȯ�� ���� ���)
		local frameManagerMapping = {
			["DialogueFrame"] = {module = "DialogueManager", func = "EndDialogue", args = {}},
			["InventoryFrame"] = {module = "InventoryUIManager", func = "ShowInventory"},
			["EquipmentFrame"] = {module = "InventoryUIManager", func = "ShowEquipment"}, -- EquipmentFrame�� InventoryUIManager�� ����
			["StatsFrame"] = {module = "StatsUIManager", func = "ShowStatsFrame"},
			["ShopFrame"] = {module = "ShopUIManager", func = "ShowShop"},
			["CraftingFrame"] = {module = "CraftingUIManager", func = "ShowCrafting"},
			["GachaFrame"] = {module = "GachaUIManager", func = "ShowGacha"},
			["SkillShopFrame"] = {module = "SkillShopUIManager", func = "ShowSkillShop"},
			["EnhancementFrame"] = {module = "EnhancementUIManager", func = "ShowEnhancementWindow"},
			["SettingsFrame"] = {module = "SettingsUIManager", func = "ShowSettings"},
			["CompanionFrame"] = {module = "CompanionUIManager", func = "ShowCompanionUI"},
			["LeaderboardFrame"] = {module = "LeaderboardUIManager", func = "ShowLeaderboardUI"},
			["CombatResultsFrame"] = {module = "CombatUIManager", func = "OnCombatEnded"} -- CombatResultsFrame�� CombatUIManager�� ���� �ݴ� ������ ���� �� ������, �ϴ��� ShowFrame(false)�� ó���� �� �ֵ��� ����� (�Ʒ� �������� fallback). OnCombatEnded�� �������� ����.
			-- CombatResultsFrame�� MiscUIBuilder���� �����ǹǷ�, Ư�� UIManager�� Show �Լ��� ������ ���� �� ����. �� ��� fallback ���� (Visible=false)�� Ÿ�� ��.
		}

		local mappingInfo = frameManagerMapping[activeFrameName]

		if mappingInfo then
			managerToCall = ModuleManager:GetModule(mappingInfo.module)
			functionToCall = managerToCall and managerToCall[mappingInfo.func]
			if mappingInfo.args then functionArgs = mappingInfo.args end
		else
			-- �Ϲ����� ��Ģ (FrameName -> FrameUIManager, ShowFrameName) �õ�
			local managerName = activeFrameName:gsub("Frame", "UIManager")
			managerToCall = ModuleManager:GetModule(managerName)
			local showFunctionName = "Show" .. activeFrameName:gsub("Frame", "")
			functionToCall = managerToCall and managerToCall[showFunctionName]
		end

		if managerToCall and functionToCall then
			print("CoreUIManager.OpenMainUIPopup: Calling " .. mappingInfo.module .. "." .. mappingInfo.func .. " for cleanup.")
			local success, err
			-- ��κ��� Show... �Լ��� (self, show) �Ǵ� (show) ����. EndDialogue�� ���� ����.
			-- pcall�� ù��° ���ڴ� �Լ�, �ι�°���ʹ� �ش� �Լ��� ���޵� ���ڵ�.
			-- ��� �Լ��̹Ƿ� managerToCall�� ù ���ڷ� �ѱ��� ����.
			success, err = pcall(functionToCall, unpack(functionArgs))
			if not success then
				warn("Error during cleanup call to", mappingInfo.module, ".", mappingInfo.func, ":", err)
				if currentActiveMainUIPopupFrame then currentActiveMainUIPopupFrame.Visible = false end
			end
		else
			currentActiveMainUIPopupFrame.Visible = false -- Fallback
			print("CoreUIManager.OpenMainUIPopup: No specific manager/function for "..activeFrameName..", directly hiding.")
		end
		currentActiveMainUIPopupFrame = nil
	end

	frameToOpenInstance.Visible = true
	if isFrameLegitMainPopup then
		currentActiveMainUIPopupFrame = frameToOpenInstance
		print("CoreUIManager.OpenMainUIPopup: Opened and set as active main popup -", frameNameToOpen)
	else
		print("CoreUIManager.OpenMainUIPopup: Opened non-main popup (or ConsumableItemListFrame) -", frameNameToOpen)
	end

	if ModuleManager then
		local TooltipManager = ModuleManager:GetModule("TooltipManager")
		if TooltipManager and TooltipManager.HideTooltip then
			TooltipManager.HideTooltip()
		end
	end
end


function CoreUIManager.CloseAllMainUIPopups()
	print("CoreUIManager.CloseAllMainUIPopups: Closing all main UI popups.")
	if currentActiveMainUIPopupFrame and currentActiveMainUIPopupFrame.Visible then
		local activeFrameName = currentActiveMainUIPopupFrame.Name
		local managerToCall = nil
		local functionToCall = nil
		local functionArgs = {false}

		local frameManagerMapping = { -- OpenMainUIPopup�� ������ ���� ���
			["DialogueFrame"] = {module = "DialogueManager", func = "EndDialogue", args = {}},
			["InventoryFrame"] = {module = "InventoryUIManager", func = "ShowInventory"},
			["EquipmentFrame"] = {module = "InventoryUIManager", func = "ShowEquipment"},
			["StatsFrame"] = {module = "StatsUIManager", func = "ShowStatsFrame"},
			["ShopFrame"] = {module = "ShopUIManager", func = "ShowShop"},
			["CraftingFrame"] = {module = "CraftingUIManager", func = "ShowCrafting"},
			["GachaFrame"] = {module = "GachaUIManager", func = "ShowGacha"},
			["SkillShopFrame"] = {module = "SkillShopUIManager", func = "ShowSkillShop"},
			["EnhancementFrame"] = {module = "EnhancementUIManager", func = "ShowEnhancementWindow"},
			["SettingsFrame"] = {module = "SettingsUIManager", func = "ShowSettings"},
			["CompanionFrame"] = {module = "CompanionUIManager", func = "ShowCompanionUI"},
			["LeaderboardFrame"] = {module = "LeaderboardUIManager", func = "ShowLeaderboardUI"},
			["CombatResultsFrame"] = {module = nil, func = nil} -- CombatResultsFrame�� ShowFrame(false)�� ���� ó��
		}
		local mappingInfo = frameManagerMapping[activeFrameName]

		if mappingInfo and mappingInfo.module and mappingInfo.func then
			managerToCall = ModuleManager:GetModule(mappingInfo.module)
			functionToCall = managerToCall and managerToCall[mappingInfo.func]
			if mappingInfo.args then functionArgs = mappingInfo.args end

			if managerToCall and functionToCall then
				print("CoreUIManager.CloseAllMainUIPopups: Calling " .. mappingInfo.module .. "." .. mappingInfo.func .. " with args for cleanup.")
				local success, err = pcall(functionToCall, unpack(functionArgs))
				if not success then warn("Error during cleanup call in CloseAllMainUIPopups: ", err) end
			else
				currentActiveMainUIPopupFrame.Visible = false
			end
		else
			currentActiveMainUIPopupFrame.Visible = false -- �Ϲ����� ��Ģ�̳� ���ο� ���� ���
			print("CoreUIManager.CloseAllMainUIPopups: No specific manager/function for "..activeFrameName..", directly hiding.")
		end
		currentActiveMainUIPopupFrame = nil
	end

	-- ConsumableItemListFrame�� �߰������� �ݱ� (���� �����ִٸ�)
	local _, bgFrame, fFolder = getCoreUIElements()
	local consumableFrameInstance = nil
	local compFrame = bgFrame and bgFrame:FindFirstChild("CompanionFrame")
	if not compFrame and fFolder then compFrame = fFolder:FindFirstChild("CompanionFrame") end
	if compFrame then consumableFrameInstance = compFrame:FindFirstChild("ConsumableItemListFrame") end

	if consumableFrameInstance and consumableFrameInstance.Visible then
		local compUIMgr = ModuleManager:GetModule("CompanionUIManager")
		if compUIMgr and compUIMgr.ShowConsumableItemList then
			pcall(compUIMgr.ShowConsumableItemList, false) -- ���⼭�� manager�� ù ���ڷ� �ѱ��� ����
			print("CoreUIManager.CloseAllMainUIPopups: Explicitly closed ConsumableItemListFrame.")
		else
			consumableFrameInstance.Visible = false
		end
	end
end


function CoreUIManager.SwitchFrame(frameName)
	local isMainPopup = false
	for _, name in ipairs(mainUIPopupFrameNames) do
		if name == frameName then
			isMainPopup = true
			break
		end
	end

	if isMainPopup then
		CoreUIManager.OpenMainUIPopup(frameName)
	else
		-- MainMenu, CombatScreen, MapFrame ���� �ֿ� �˾��� ��� �ݰ� ǥ��
		if frameName == "MainMenu" or frameName == "CombatScreen" or frameName == "MapFrame" then
			CoreUIManager.CloseAllMainUIPopups()
		end
		-- currentActiveMainUIPopupFrame�� OpenMainUIPopup���� �̹� nil�� ó���ǰų�,
		-- ShowFrame�� ���� currentActiveMainUIPopupFrame�� �������� �����Ƿ�,
		-- ���⼭ �ٽ� nil�� ������ �ʿ�� ���� ����.
		-- (��, CloseAllMainUIPopups�� ȣ����� �ʴ� ��츦 ����� currentActiveMainUIPopupFrame�� nil�� �����ϴ� ������ �ʿ��� ���� ����)
		CoreUIManager.ShowFrame(frameName, true)
	end
end

function CoreUIManager.GetCurrentFrame()
	return currentActiveMainUIPopupFrame
end

function CoreUIManager.UpdatePlayerHUD(stats) if not stats then return end; local _,bgFrame=getCoreUIElements(); if not bgFrame then return end; local hud=bgFrame:FindFirstChild("PlayerHUD"); if not hud then return end; local name=hud:FindFirstChild("NameLabel"); local lvl=hud:FindFirstChild("LevelLabel"); local gold=hud:FindFirstChild("GoldLabel"); local hp=hud:FindFirstChild("HPLabel"); if name then name.Text=stats.Name or "Player" end; if lvl then lvl.Text="Lv. "..(stats.Level or 1) end; if gold then gold.Text="Gold: "..(stats.Gold or 0) end; if hp then hp.Text=string.format("HP: %d/%d",math.floor(stats.CurrentHP or 0),math.floor(stats.MaxHP or 0)) end; local mpBG=hud:FindFirstChild("MPBarBackground"); local mpLbl=mpBG and mpBG:FindFirstChild("MPLabel"); local mpBar=mpBG and mpBG:FindFirstChild("MPBar"); if mpLbl then mpLbl.Text=string.format("MP: %d/%d",math.floor(stats.CurrentMP or 0),math.floor(stats.MaxMP or 0)) end; if mpBar then local cur=stats.CurrentMP or 0; local max=stats.MaxMP; if max and max>0 then local r=math.clamp(cur/max,0,1); mpBar.Size=UDim2.new(r,0,1,0) else mpBar.Size=UDim2.new(0,0,1,0) end end; local expBG=hud:FindFirstChild("ExpBarBackground"); local expLbl=expBG and expBG:FindFirstChild("ExpLabel"); local expBar=expBG and expBG:FindFirstChild("ExpBar"); if expLbl then expLbl.Text=string.format("Exp: %d/%d",math.floor(stats.Exp or 0),math.floor(stats.MaxExp or 100)) end; if expBar then local cur=stats.Exp or 0; local max=stats.MaxExp; if max and max>0 then local r=math.clamp(cur/max,0,1); expBar.Size=UDim2.new(r,0,1,0) else expBar.Size=UDim2.new(0,0,1,0) end end end

function CoreUIManager.ShowPopupMessage(title, message, duration)
	print(string.format("DEBUG: CoreUIManager: ShowPopupMessage ȣ��� - ����: %s, ����: %s", tostring(title), tostring(message)))
	local currentMainGui, _, _ = getCoreUIElements()
	if not currentMainGui then warn("No MainGui for PopupMessage!"); return end
	duration=duration or 3;
	local popupFrame=Instance.new("Frame"); popupFrame.Name="PopupMessageFrame"; popupFrame.Size=UDim2.new(0.4,0,0.1,0); popupFrame.Position=UDim2.new(0.5,0,0.1,0); popupFrame.AnchorPoint=Vector2.new(0.5,0); popupFrame.BackgroundColor3=Color3.fromRGB(30,30,40); popupFrame.BackgroundTransparency=1; popupFrame.BorderSizePixel=1; popupFrame.BorderColor3=Color3.fromRGB(150,150,180); popupFrame.ZIndex=200; popupFrame.Parent=currentMainGui;
	Instance.new("UICorner",popupFrame).CornerRadius=UDim.new(0,6);
	local popupText=Instance.new("TextLabel"); popupText.Name="PopupText"; popupText.Size=UDim2.new(1,-10,1,-10); popupText.Position=UDim2.new(0.5,0,0.5,0); popupText.AnchorPoint=Vector2.new(0.5,0.5); popupText.BackgroundTransparency=1; popupText.TextColor3=Color3.fromRGB(230,230,230); popupText.Font=Enum.Font.SourceSans; popupText.TextSize=16; popupText.TextWrapped=true; popupText.RichText=true;
	popupText.Text=string.format("<font size='18'><b>[%s]</b></font>\n%s",tostring(title or "�˸�"),message or "");
	popupText.TextTransparency=1; popupText.ZIndex=popupFrame.ZIndex+1; popupText.Parent=popupFrame;
	local fadeInDuration=0.3; local fadeOutDuration=0.5; local stayDuration=duration;
	local tweenInfoFadeIn=TweenInfo.new(fadeInDuration,Enum.EasingStyle.Quad,Enum.EasingDirection.Out);
	local tweenInfoFadeOut=TweenInfo.new(fadeOutDuration,Enum.EasingStyle.Quad,Enum.EasingDirection.In,0,false,stayDuration);
	local fadeInGoal={BackgroundTransparency=0.2,TextTransparency=0};
	local fadeOutGoal={BackgroundTransparency=1,TextTransparency=1};
	local fadeInFrameTween=TweenService:Create(popupFrame,tweenInfoFadeIn,{BackgroundTransparency=fadeInGoal.BackgroundTransparency});
	local fadeInTextTween=TweenService:Create(popupText,tweenInfoFadeIn,{TextTransparency=fadeInGoal.TextTransparency});
	local fadeOutFrameTween=TweenService:Create(popupFrame,tweenInfoFadeOut,{BackgroundTransparency=fadeOutGoal.BackgroundTransparency});
	local fadeOutTextTween=TweenService:Create(popupText,tweenInfoFadeOut,{TextTransparency=fadeOutGoal.TextTransparency});
	fadeInFrameTween:Play(); fadeInTextTween:Play();
	fadeInTextTween.Completed:Connect(function() fadeOutFrameTween:Play(); fadeOutTextTween:Play() end);
	fadeOutTextTween.Completed:Connect(function() pcall(function() popupFrame:Destroy() end) end);
	print("CoreUIManager: Popup message animation started.")
end

function CoreUIManager.ShowConfirmationPopup(title, message, onConfirmCallback)
	local currentMainGui, _, _ = getCoreUIElements()
	if not currentMainGui then warn("No MainGui for ConfirmationPopup!"); return end
	if not GuiUtils then warn("CoreUIManager: GuiUtils not loaded for ConfirmationPopup!"); return end
	local existingPopup = currentMainGui:FindFirstChild("ConfirmationPopupFrame"); if existingPopup then existingPopup:Destroy() end
	local popupFrame = Instance.new("Frame"); popupFrame.Name = "ConfirmationPopupFrame"; popupFrame.Size = UDim2.new(0.4, 0, 0.25, 0); popupFrame.Position = UDim2.new(0.5, 0, 0.5, 0); popupFrame.AnchorPoint = Vector2.new(0.5, 0.5); popupFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 55); popupFrame.BackgroundTransparency = 0.1; popupFrame.BorderSizePixel = 1; popupFrame.BorderColor3 = Color3.fromRGB(180, 180, 200); popupFrame.ZIndex = 201; popupFrame.Parent = currentMainGui; Instance.new("UICorner",popupFrame).CornerRadius=UDim.new(0,8);
	GuiUtils.CreateTextLabel(popupFrame, "TitleLabel", UDim2.new(0.5, 0, 0.1, 0), UDim2.new(0.9, 0, 0.15, 0), title or "Ȯ��", Vector2.new(0.5, 0), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 18);
	local messageLabel = GuiUtils.CreateTextLabel(popupFrame, "MessageLabel",	UDim2.new(0.5, 0, 0.45, 0), UDim2.new(0.9, 0, 0.4, 0),	message or "����Ͻðڽ��ϱ�?", Vector2.new(0.5, 0.5), Enum.TextXAlignment.Center, Enum.TextYAlignment.Center, 14); messageLabel.TextWrapped = true;
	local buttonContainer = Instance.new("Frame"); buttonContainer.Name = "ButtonContainer"; buttonContainer.Size = UDim2.new(1, 0, 0.3, 0); buttonContainer.Position = UDim2.new(0.5, 0, 0.85, 0); buttonContainer.AnchorPoint = Vector2.new(0.5, 1); buttonContainer.BackgroundTransparency = 1; buttonContainer.Parent = popupFrame; local buttonLayout = Instance.new("UIListLayout"); buttonLayout.FillDirection = Enum.FillDirection.Horizontal; buttonLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center; buttonLayout.VerticalAlignment = Enum.VerticalAlignment.Center; buttonLayout.Padding = UDim.new(0, 20); buttonLayout.Parent = buttonContainer;
	local noButton = GuiUtils.CreateButton(buttonContainer, "NoButton",	UDim2.new(0, 0, 0, 0), UDim2.new(0, 100, 1, -10), nil, "�ƴϿ�", nil, popupFrame.ZIndex + 1); noButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100); Instance.new("UICorner", noButton).CornerRadius = UDim.new(0, 4);
	noButton.MouseButton1Click:Connect(function() local fadeOutInfo = TweenInfo.new(0.2); local fadeOutTween = TweenService:Create(popupFrame, fadeOutInfo, {BackgroundTransparency = 1}); fadeOutTween:Play(); fadeOutTween.Completed:Connect(function() pcall(function() popupFrame:Destroy() end) end)	end)
	local yesButton = GuiUtils.CreateButton(buttonContainer, "YesButton", UDim2.new(0, 0, 0, 0), UDim2.new(0, 100, 1, -10),nil, "��", nil, popupFrame.ZIndex + 1); yesButton.BackgroundColor3 = Color3.fromRGB(200, 80, 80); Instance.new("UICorner", yesButton).CornerRadius = UDim.new(0, 4);
	yesButton.MouseButton1Click:Connect(function() if onConfirmCallback and typeof(onConfirmCallback) == "function" then pcall(onConfirmCallback) end; local fadeOutInfo = TweenInfo.new(0.2); local fadeOutTween = TweenService:Create(popupFrame, fadeOutInfo, {BackgroundTransparency = 1}); fadeOutTween:Play(); fadeOutTween.Completed:Connect(function() pcall(function() popupFrame:Destroy() end) end) end)
	popupFrame.BackgroundTransparency = 1; local fadeInInfo = TweenInfo.new(0.3); local fadeInTween = TweenService:Create(popupFrame, fadeInInfo, {BackgroundTransparency = 0.1}); fadeInTween:Play();
	print("CoreUIManager: Confirmation popup displayed.")
end

function CoreUIManager.FadeScreen(fadeIn, duration, callback)
	if not screenFadeFrame then
		warn("CoreUIManager.FadeScreen: ScreenFadeFrame�� �ʱ�ȭ���� �ʾҽ��ϴ�!")
		if callback then task.spawn(callback) end
		return
	end

	local targetTransparency = fadeIn and 1 or 0
	local startTransparency = screenFadeFrame.BackgroundTransparency

	print(string.format("CoreUIManager: FadeScreen called. fadeIn: %s, duration: %.2f, targetTrans: %.2f, startTrans: %.2f",
		tostring(fadeIn), duration, targetTransparency, startTransparency))

	if startTransparency == targetTransparency then
		if callback then task.spawn(callback) end
		return
	end

	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	local properties = { BackgroundTransparency = targetTransparency }
	local fadeTween = TweenService:Create(screenFadeFrame, tweenInfo, properties)

	if callback then
		local connection
		connection = fadeTween.Completed:Connect(function()
			connection:Disconnect()
			print("CoreUIManager: FadeScreen tween completed.")
			pcall(callback)
		end)
	end

	fadeTween:Play()
	print("CoreUIManager: FadeScreen tween playing.")
end

function CoreUIManager.ShowDamagePopup(targetGuiObject, amount, isHeal) if not targetGuiObject or not targetGuiObject.Parent then return end; local popup=Instance.new("TextLabel"); popup.Name="DamagePopup"; popup.Size=UDim2.new(0,100,0,30); popup.Position=UDim2.new(0.5,0,0.5,-20); popup.AnchorPoint=Vector2.new(0.5,1); popup.BackgroundTransparency=1; popup.Font=Enum.Font.SourceSansBold; popup.TextScaled=true; popup.TextStrokeTransparency=0.5; popup.ZIndex=targetGuiObject.ZIndex+10; if isHeal then popup.TextColor3=Color3.fromRGB(0,255,0); popup.Text="+"..tostring(amount) else popup.TextColor3=Color3.fromRGB(255,50,50); popup.Text=tostring(amount) end; popup.Parent=targetGuiObject; local info=TweenInfo.new(1.0,Enum.EasingStyle.Quad,Enum.EasingDirection.Out); local goal={Position=popup.Position+UDim2.fromOffset(0,-50),TextTransparency=1}; local tween=TweenService:Create(popup,info,goal); tween:Play(); tween.Completed:Connect(function() pcall(popup.Destroy,popup) end) end
function CoreUIManager.FlashTarget(targetGuiObject, flashColor, duration) if not targetGuiObject or not targetGuiObject:IsA("GuiObject") or not targetGuiObject.Parent then return end; local origColor=targetGuiObject.BackgroundColor3; local flash=flashColor or Color3.new(1,1,1); local dur=duration or 0.1; local info=TweenInfo.new(dur/2,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,0,true); local tween=TweenService:Create(targetGuiObject,info,{BackgroundColor3=flash}); tween:Play() end
function CoreUIManager.ShakeGui(intensity, duration) local _,bgFrame=getCoreUIElements(); local frame=bgFrame; if not frame then return end; local start=tick(); local initPos=frame.Position; while tick()-start<duration do local ox=math.random(-intensity,intensity); local oy=math.random(-intensity,intensity); frame.Position=initPos+UDim2.fromOffset(ox,oy); task.wait() end; frame.Position=initPos end

return CoreUIManager