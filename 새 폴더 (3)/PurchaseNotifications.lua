-- PurchaseNotifications.lua (ModuleScript, NotificationModules ������ ����)

local PurchaseNotifications = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local NotificationSystem = require(modulesFolder:WaitForChild("NotificationSystem"))

local PURCHASE_MESSAGES = {
	["ITEM_PURCHASED"] = "<font color='#88CCFF'>%s</font> ����!",
	["NOT_ENOUGH_GOLD"] = "��尡 �����մϴ�.",
	-- �ʿ��� �޽��� �߰�...
}

function PurchaseNotifications:ShowItemPurchased(itemName) -- <<< self ���� �߰� �Ǵ� ��� ���� ����
	-- <<< ����� �α� �߰� >>>
	print(string.format("DEBUG: PurchaseNotifications: ShowItemPurchased ȣ���, �����۸�: %s", tostring(itemName)))
	local message = PURCHASE_MESSAGES["ITEM_PURCHASED"]
	if message then
		-- <<< ����� �α� �߰� >>>
		print("DEBUG: PurchaseNotifications: NotificationSystem.ShowNotification ȣ�� �õ� (ItemPurchased)")
		NotificationSystem.ShowNotification(NotificationSystem.DisplayType.POPUP, string.format(message, itemName))
	else
		warn("PurchaseNotifications: ITEM_PURCHASED �޽��� ����!")
	end
end

function PurchaseNotifications:ShowNotEnoughGold() -- <<< self ���� �߰� �Ǵ� ��� ���� ����
	-- <<< ����� �α� �߰� >>>
	print("DEBUG: PurchaseNotifications: ShowNotEnoughGold ȣ���")
	local message = PURCHASE_MESSAGES["NOT_ENOUGH_GOLD"]
	if message then
		-- <<< ����� �α� �߰� >>>
		print("DEBUG: PurchaseNotifications: NotificationSystem.ShowNotification ȣ�� �õ� (NotEnoughGold)")
		NotificationSystem.ShowNotification(NotificationSystem.DisplayType.POPUP, message)
	else
		warn("PurchaseNotifications: NOT_ENOUGH_GOLD �޽��� ����!")
	end
end

return PurchaseNotifications