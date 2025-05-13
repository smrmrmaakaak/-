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
	local message = ENHANCEMENT_MESSAGES["ENHANCEMENT_SUCCESS"]
	if message then
		NotificationSystem.ShowNotification(NotificationSystem.DisplayType.POPUP, string.format(message, itemName, newLevel))
	else
		warn("EnhancementNotifications: ENHANCEMENT_SUCCESS �޽��� ����!")
	end
end

-- ��ȭ ���� �˸� ǥ�� �Լ�
-- @param itemName (string): ��ȭ �õ��� ������ �̸�
-- @param reason (string): ���� ����
function EnhancementNotifications.ShowEnhancementFailed(itemName, reason)
	local message = ENHANCEMENT_MESSAGES["ENHANCEMENT_FAILED"]
	if message then
		NotificationSystem.ShowNotification(NotificationSystem.DisplayType.POPUP, string.format(message, itemName, reason))
	else
		warn("EnhancementNotifications: ENHANCEMENT_FAILED �޽��� ����!")
	end
end

-- ��� ���� �˸� ǥ�� �Լ�
function EnhancementNotifications.ShowNotEnoughMaterials()
	local message = ENHANCEMENT_MESSAGES["NOT_ENOUGH_MATERIALS"]
	if message then
		NotificationSystem.ShowNotification(NotificationSystem.DisplayType.POPUP, message)
	else
		warn("EnhancementNotifications: NOT_ENOUGH_MATERIALS �޽��� ����!")
	end
end

-- �ִ� ���� ���� �˸� ǥ�� �Լ�
function EnhancementNotifications.ShowMaxLevelReached()
	local message = ENHANCEMENT_MESSAGES["MAX_LEVEL_REACHED"]
	if message then
		NotificationSystem.ShowNotification(NotificationSystem.DisplayType.POPUP, message)
	else
		warn("EnhancementNotifications: MAX_LEVEL_REACHED �޽��� ����!")
	end
end

return EnhancementNotifications