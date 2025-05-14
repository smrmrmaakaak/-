-- PurchaseNotifications.lua (ModuleScript, NotificationModules 폴더에 저장)

local PurchaseNotifications = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local NotificationSystem = require(modulesFolder:WaitForChild("NotificationSystem"))

local PURCHASE_MESSAGES = {
	["ITEM_PURCHASED"] = "<font color='#88CCFF'>%s</font> 구매!",
	["NOT_ENOUGH_GOLD"] = "골드가 부족합니다.",
	-- 필요한 메시지 추가...
}

function PurchaseNotifications:ShowItemPurchased(itemName) -- <<< self 인자 추가 또는 모듈 직접 참조
	-- <<< 디버그 로그 추가 >>>
	print(string.format("DEBUG: PurchaseNotifications: ShowItemPurchased 호출됨, 아이템명: %s", tostring(itemName)))
	local message = PURCHASE_MESSAGES["ITEM_PURCHASED"]
	if message then
		-- <<< 디버그 로그 추가 >>>
		print("DEBUG: PurchaseNotifications: NotificationSystem.ShowNotification 호출 시도 (ItemPurchased)")
		NotificationSystem.ShowNotification(NotificationSystem.DisplayType.POPUP, string.format(message, itemName))
	else
		warn("PurchaseNotifications: ITEM_PURCHASED 메시지 없음!")
	end
end

function PurchaseNotifications:ShowNotEnoughGold() -- <<< self 인자 추가 또는 모듈 직접 참조
	-- <<< 디버그 로그 추가 >>>
	print("DEBUG: PurchaseNotifications: ShowNotEnoughGold 호출됨")
	local message = PURCHASE_MESSAGES["NOT_ENOUGH_GOLD"]
	if message then
		-- <<< 디버그 로그 추가 >>>
		print("DEBUG: PurchaseNotifications: NotificationSystem.ShowNotification 호출 시도 (NotEnoughGold)")
		NotificationSystem.ShowNotification(NotificationSystem.DisplayType.POPUP, message)
	else
		warn("PurchaseNotifications: NOT_ENOUGH_GOLD 메시지 없음!")
	end
end

return PurchaseNotifications