--[[
  GachaUIManager (ModuleScript)
  뽑기(가챠) 시스템 UI 관련 로직 담당
  (창 열기/닫기, 재화 표시, 결과 표시 등)
  *** [기능 수정] UI 창 겹침 방지를 위해 CoreUIManager.OpenMainUIPopup 사용 ***
]]
local GachaUIManager = {}

-- 필요한 서비스 및 모듈 로드
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService") 
local HttpService = game:GetService("HttpService") 

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local mainGui = playerGui:WaitForChild("MainGui") -- mainGui 참조

local ModuleManager
local CoreUIManager -- CoreUIManager 참조 선언
local PlayerData
local ItemDatabase

local gachaFrame = nil -- gachaFrame 참조를 모듈 스코프로 이동

-- 모듈 초기화
function GachaUIManager.Init()
	ModuleManager = require(ReplicatedStorage.Modules:WaitForChild("ModuleManager"))
	CoreUIManager = ModuleManager:GetModule("CoreUIManager") -- CoreUIManager 초기화
	PlayerData = ModuleManager:GetModule("PlayerData")
	ItemDatabase = ModuleManager:GetModule("ItemDatabase")
	GachaUIManager.SetupUIReferences() -- UI 참조 설정
	print("GachaUIManager: Initialized.")
end

-- ##### [기능 추가] UI 프레임 참조를 위한 함수 #####
function GachaUIManager.SetupUIReferences()
	if not mainGui then 
		local p = Players.LocalPlayer
		local pg = p and p:WaitForChild("PlayerGui")
		mainGui = pg and pg:FindFirstChild("MainGui")
		if not mainGui then
			warn("GachaUIManager.SetupUIReferences: MainGui not found even after retry!")
			return
		end
	end
	local backgroundFrame = mainGui:FindFirstChild("BackgroundFrame")
	if backgroundFrame then
		gachaFrame = backgroundFrame:FindFirstChild("GachaFrame")
		if not gachaFrame then 
			warn("GachaUIManager.SetupUIReferences: GachaFrame not found!")
		else
			print("GachaUIManager: GachaFrame reference established.")
		end
	else
		warn("GachaUIManager.SetupUIReferences: BackgroundFrame not found!")
	end
end
-- #################################################


-- 재화(골드) 표시 업데이트
function GachaUIManager.UpdateCurrencyDisplay()
	if not gachaFrame then 
		GachaUIManager.SetupUIReferences()
		if not gachaFrame then
			warn("GachaUIManager.UpdateCurrencyDisplay: GachaFrame is nil.")
			return
		end
	end
	local currencyLabel = gachaFrame:FindFirstChild("PlayerCurrencyLabel")
	if not currencyLabel or not PlayerData then return end

	local stats = PlayerData.GetStats(player) 
	if stats then
		currencyLabel.Text = "보유 골드: " .. (stats.Gold or "???")
	else
		currencyLabel.Text = "보유 골드: ????"
		warn("GachaUIManager: Failed to get player stats for currency display.")
	end
end

-- 뽑기 결과 표시
function GachaUIManager.ShowPullResult(itemId)
	if not gachaFrame then 
		GachaUIManager.SetupUIReferences()
		if not gachaFrame then
			warn("GachaUIManager.ShowPullResult: GachaFrame is nil.")
			return
		end
	end

	local resultDisplayFrame = gachaFrame:FindFirstChild("ResultDisplayFrame")
	if not resultDisplayFrame then return end
	local resultImage = resultDisplayFrame:FindFirstChild("ResultItemImage")
	local resultNameLabel = resultDisplayFrame:FindFirstChild("ResultItemName")

	if not resultImage or not resultNameLabel then
		warn("GachaUIManager: Result display elements not found!")
		return
	end

	resultImage.Visible = false
	resultNameLabel.Visible = false
	resultNameLabel.Text = ""

	if not itemId then
		print("GachaUIManager: No item ID provided to ShowPullResult, hiding results.")
		return
	end

	if not ItemDatabase then
		warn("GachaUIManager.ShowPullResult: ItemDatabase not loaded!")
		return
	end

	local itemInfo = ItemDatabase.Items[itemId]
	if itemInfo then
		print("GachaUIManager: Displaying result for ItemID:", itemId, "Name:", itemInfo.Name)
		resultNameLabel.Text = itemInfo.Name
		if itemInfo.ImageId and itemInfo.ImageId ~= "" then
			resultImage.Image = itemInfo.ImageId
		else
			local encodedName = HttpService:UrlEncode(itemInfo.Name)
			resultImage.Image = string.format("https://placehold.co/80x80/cccccc/333333?text=%s", encodedName)
		end
		resultImage.Visible = true
		resultNameLabel.Visible = true

		resultDisplayFrame.BackgroundTransparency = 0.8
		resultImage.ImageTransparency = 1
		resultNameLabel.TextTransparency = 1
		local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
		local goal_image = { ImageTransparency = 0 }
		local goal_text = { TextTransparency = 0 }
		local tween = TweenService:Create(resultImage, tweenInfo, goal_image)
		local tween2 = TweenService:Create(resultNameLabel, tweenInfo, goal_text)
		tween:Play()
		tween2:Play()
	else
		warn("GachaUIManager: Item info not found for pulled ItemID:", itemId)
		resultNameLabel.Text = "알 수 없는 아이템"
		resultNameLabel.Visible = true
	end
end

-- 뽑기 창 보이기/숨기기
function GachaUIManager.ShowGacha(show)
	if not CoreUIManager then
		warn("GachaUIManager.ShowGacha: CoreUIManager not loaded!")
		if gachaFrame then gachaFrame.Visible = show end -- Fallback
		return
	end
	if not gachaFrame then
		GachaUIManager.SetupUIReferences()
		if not gachaFrame then
			warn("GachaUIManager.ShowGacha: GachaFrame is still nil after setup.")
			return
		end
	end

	if show then
		CoreUIManager.OpenMainUIPopup("GachaFrame") -- 다른 주요 팝업 닫고 뽑기 창 열기
		GachaUIManager.UpdateCurrencyDisplay()
		GachaUIManager.ShowPullResult(nil) 
	else
		CoreUIManager.ShowFrame("GachaFrame", false) -- 단순히 뽑기 창 닫기
		GachaUIManager.ShowPullResult(nil)
	end
	print("GachaUIManager: ShowGacha called with", show)
end

return GachaUIManager