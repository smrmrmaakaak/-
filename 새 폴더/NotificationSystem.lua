-- NotificationSystem.lua (수정된 전체 코드)

local NotificationSystem = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- modulesFolder는 필요 시점에 require 내부에서 처리하거나 상단에서 한번만 로드
local modulesFolder = ReplicatedStorage:WaitForChild("Modules")

local notificationModules = {}

NotificationSystem.DisplayType = {
	POPUP = "Popup",
	CHAT = "Chat",
	LOG = "Log"
}

function NotificationSystem.RegisterModule(moduleName, module)
	if notificationModules[moduleName] then
		warn("NotificationSystem: 이미 등록된 알림 모듈:", moduleName)
		return
	end
	notificationModules[moduleName] = module
	print("NotificationSystem: 알림 모듈 등록됨:", moduleName)
end

function NotificationSystem.UnregisterModule(moduleName)
	notificationModules[moduleName] = nil
	print("NotificationSystem: 알림 모듈 해제됨:", moduleName)
end

function NotificationSystem.ShowNotification(displayType, message, options)
	if not displayType or not message then
		warn("NotificationSystem: 잘못된 알림 요청 (type:", displayType, ", message:", message, ")")
		return
	end

	if displayType == NotificationSystem.DisplayType.POPUP then
		-- CoreUIManager 모듈 참조 (필요 시점에 로드)
		local CoreUIManager = require(modulesFolder:WaitForChild("CoreUIManager"))
		if CoreUIManager and CoreUIManager.ShowPopupMessage then
			-- ##### 수정: 콜론(:) 대신 점(.) 사용 #####
			pcall(CoreUIManager.ShowPopupMessage, message, options and options.duration or 3) -- 제목 인자 제거, 기본 제목 "알림"은 ShowPopupMessage 내부에서 처리하도록 변경 가능하거나, 여기서 직접 전달
			-- 또는 제목을 유지하려면: pcall(CoreUIManager.ShowPopupMessage, "알림", message, options and options.duration or 3)
		else
			warn("NotificationSystem: CoreUIManager 를 찾을 수 없습니다!")
		end
	elseif displayType == NotificationSystem.DisplayType.CHAT then
		print("[CHAT]", message)
	elseif displayType == NotificationSystem.DisplayType.LOG then
		print("[LOG]", message)
	else
		warn("NotificationSystem: 지원하지 않는 표시 방식:", displayType)
	end
end

return NotificationSystem