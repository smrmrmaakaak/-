-- NotificationSystem.lua (������ ��ü �ڵ�)

local NotificationSystem = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
-- modulesFolder�� �ʿ� ������ require ���ο��� ó���ϰų� ��ܿ��� �ѹ��� �ε�
local modulesFolder = ReplicatedStorage:WaitForChild("Modules")

local notificationModules = {}

NotificationSystem.DisplayType = {
	POPUP = "Popup",
	CHAT = "Chat",
	LOG = "Log"
}

function NotificationSystem.RegisterModule(moduleName, module)
	if notificationModules[moduleName] then
		warn("NotificationSystem: �̹� ��ϵ� �˸� ���:", moduleName)
		return
	end
	notificationModules[moduleName] = module
	print("NotificationSystem: �˸� ��� ��ϵ�:", moduleName)
end

function NotificationSystem.UnregisterModule(moduleName)
	notificationModules[moduleName] = nil
	print("NotificationSystem: �˸� ��� ������:", moduleName)
end

function NotificationSystem.ShowNotification(displayType, message, options)
	if not displayType or not message then
		warn("NotificationSystem: �߸��� �˸� ��û (type:", displayType, ", message:", message, ")")
		return
	end

	if displayType == NotificationSystem.DisplayType.POPUP then
		-- CoreUIManager ��� ���� (�ʿ� ������ �ε�)
		local CoreUIManager = require(modulesFolder:WaitForChild("CoreUIManager"))
		if CoreUIManager and CoreUIManager.ShowPopupMessage then
			-- ##### ����: �ݷ�(:) ��� ��(.) ��� #####
			pcall(CoreUIManager.ShowPopupMessage, message, options and options.duration or 3) -- ���� ���� ����, �⺻ ���� "�˸�"�� ShowPopupMessage ���ο��� ó���ϵ��� ���� �����ϰų�, ���⼭ ���� ����
			-- �Ǵ� ������ �����Ϸ���: pcall(CoreUIManager.ShowPopupMessage, "�˸�", message, options and options.duration or 3)
		else
			warn("NotificationSystem: CoreUIManager �� ã�� �� �����ϴ�!")
		end
	elseif displayType == NotificationSystem.DisplayType.CHAT then
		print("[CHAT]", message)
	elseif displayType == NotificationSystem.DisplayType.LOG then
		print("[LOG]", message)
	else
		warn("NotificationSystem: �������� �ʴ� ǥ�� ���:", displayType)
	end
end

return NotificationSystem