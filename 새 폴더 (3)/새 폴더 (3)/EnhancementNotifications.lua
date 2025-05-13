-- EnhancementNotifications.lua (ModuleScript, NotificationModules 폴더에 저장)

local EnhancementNotifications = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local modulesFolder = ReplicatedStorage:WaitForChild("Modules")
local NotificationSystem = require(modulesFolder:WaitForChild("NotificationSystem"))

-- 강화 관련 알림 메시지 정의 (모듈 내부에서 관리)
local ENHANCEMENT_MESSAGES = {
	["ENHANCEMENT_SUCCESS"] = "<font color='#90EE90'>%s</font> (+%d) 강화 성공!",
	["ENHANCEMENT_FAILED"] = "<font color='#FF8888'>%s</font> 강화 실패: %s",
	["NOT_ENOUGH_MATERIALS"] = "재료가 부족합니다.",
	["MAX_LEVEL_REACHED"] = "최대 레벨입니다.",
	-- 필요한 메시지 추가...
}

-- 강화 성공 알림 표시 함수
-- @param itemName (string): 강화된 아이템 이름
-- @param newLevel (number): 강화된 레벨
function EnhancementNotifications.ShowEnhancementSuccess(itemName, newLevel)
	local message = ENHANCEMENT_MESSAGES["ENHANCEMENT_SUCCESS"]
	if message then
		NotificationSystem.ShowNotification(NotificationSystem.DisplayType.POPUP, string.format(message, itemName, newLevel))
	else
		warn("EnhancementNotifications: ENHANCEMENT_SUCCESS 메시지 없음!")
	end
end

-- 강화 실패 알림 표시 함수
-- @param itemName (string): 강화 시도한 아이템 이름
-- @param reason (string): 실패 이유
function EnhancementNotifications.ShowEnhancementFailed(itemName, reason)
	local message = ENHANCEMENT_MESSAGES["ENHANCEMENT_FAILED"]
	if message then
		NotificationSystem.ShowNotification(NotificationSystem.DisplayType.POPUP, string.format(message, itemName, reason))
	else
		warn("EnhancementNotifications: ENHANCEMENT_FAILED 메시지 없음!")
	end
end

-- 재료 부족 알림 표시 함수
function EnhancementNotifications.ShowNotEnoughMaterials()
	local message = ENHANCEMENT_MESSAGES["NOT_ENOUGH_MATERIALS"]
	if message then
		NotificationSystem.ShowNotification(NotificationSystem.DisplayType.POPUP, message)
	else
		warn("EnhancementNotifications: NOT_ENOUGH_MATERIALS 메시지 없음!")
	end
end

-- 최대 레벨 도달 알림 표시 함수
function EnhancementNotifications.ShowMaxLevelReached()
	local message = ENHANCEMENT_MESSAGES["MAX_LEVEL_REACHED"]
	if message then
		NotificationSystem.ShowNotification(NotificationSystem.DisplayType.POPUP, message)
	else
		warn("EnhancementNotifications: MAX_LEVEL_REACHED 메시지 없음!")
	end
end

return EnhancementNotifications