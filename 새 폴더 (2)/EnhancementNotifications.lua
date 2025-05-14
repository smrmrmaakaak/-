-- EnhancementNotifications.lua (ModuleScript, NotificationModules ������ ����)

local EnhancementNotifications = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local NotificationSystem = require(modulesFolder:WaitForChild("NotificationSystem"))

-- ��ȭ ���� �˸� �޽��� ���� (��� ���ο��� ����)
local ENHANCEMENT_MESSAGES = {
	["ENHANCEMENT_SUCCESS"] = "<font color='#90EE90'>%s</font> (+%d) ��ȭ ����!",
	["ENHANCEMENT_FAILED"] = "<font color='#FF8888'>%s</font> ��ȭ ����: %s",
	["NOT_ENOUGH_MATERIALS"] = "��ᰡ �����մϴ�.",
	["MAX_LEVEL_REACHED"] = "�ִ� �����Դϴ�.",
	-- �ʿ��� �޽��� �߰�...
}

-- ��ȭ ���� �˸� ǥ�� �Լ�
-- @param itemName (string): ��ȭ�� ������ �̸�
-- @param newLevel (number): ��ȭ�� ����
function EnhancementNotifications.ShowEnhancementSuccess(itemName, newLevel)
	print("DEBUG: EnhancementNotifications.ShowEnhancementSuccess CALLED. Item:", itemName, "NewLevel:", newLevel) -- �߰�
	local message = ENHANCEMENT_MESSAGES["ENHANCEMENT_SUCCESS"]
	if message then
		local formattedMessage = string.format(message, itemName, newLevel)
		print("DEBUG: EnhancementNotifications - Calling NotificationSystem.ShowNotification with message (Success):", formattedMessage) -- �߰�
		NotificationSystem.ShowNotification(NotificationSystem.DisplayType.POPUP, formattedMessage)
	else
		warn("EnhancementNotifications: ENHANCEMENT_SUCCESS �޽��� ����!")
	end
end

-- ��ȭ ���� �˸� ǥ�� �Լ�
-- @param itemName (string): ��ȭ �õ��� ������ �̸�
-- @param reason (string): ���� ����
function EnhancementNotifications.ShowEnhancementFailed(itemName, reason)
	print("DEBUG: EnhancementNotifications.ShowEnhancementFailed CALLED. Item:", itemName, "Reason:", reason) -- �߰�
	local message = ENHANCEMENT_MESSAGES["ENHANCEMENT_FAILED"]
	if message then
		local formattedMessage = string.format(message, itemName, reason)
		print("DEBUG: EnhancementNotifications - Calling NotificationSystem.ShowNotification with message (Failed):", formattedMessage) -- �߰�
		NotificationSystem.ShowNotification(NotificationSystem.DisplayType.POPUP, formattedMessage)
	else
		warn("EnhancementNotifications: ENHANCEMENT_FAILED �޽��� ����!")
	end
end

-- ��� ���� �˸� ǥ�� �Լ�
function EnhancementNotifications.ShowNotEnoughMaterials()
	print("DEBUG: EnhancementNotifications.ShowNotEnoughMaterials CALLED.") -- �߰�
	local message = ENHANCEMENT_MESSAGES["NOT_ENOUGH_MATERIALS"]
	if message then
		print("DEBUG: EnhancementNotifications - Calling NotificationSystem.ShowNotification with message (No Materials):", message) -- �߰�
		NotificationSystem.ShowNotification(NotificationSystem.DisplayType.POPUP, message)
	else
		warn("EnhancementNotifications: NOT_ENOUGH_MATERIALS �޽��� ����!")
	end
end

-- �ִ� ���� ���� �˸� ǥ�� �Լ�
function EnhancementNotifications.ShowMaxLevelReached()
	print("DEBUG: EnhancementNotifications.ShowMaxLevelReached CALLED.") -- �߰�
	local message = ENHANCEMENT_MESSAGES["MAX_LEVEL_REACHED"]
	if message then
		print("DEBUG: EnhancementNotifications - Calling NotificationSystem.ShowNotification with message (Max Level):", message) -- �߰�
		NotificationSystem.ShowNotification(NotificationSystem.DisplayType.POPUP, message)
	else
		warn("EnhancementNotifications: MAX_LEVEL_REACHED �޽��� ����!")
	end
end

return EnhancementNotifications