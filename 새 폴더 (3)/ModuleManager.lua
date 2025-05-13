--[[
  **2. ReplicatedStorage > Modules > ModuleManager (ModuleScript)**
  �ٸ� ������ ���� �ҷ��� �� �ְ� �����ִ� ������ ����Դϴ�.
]]

-- ModuleManager (ModuleScript)
local ModuleManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local modulesFolder = ReplicatedStorage:WaitForChild("Modules")

-- �ε�� ������ ������ ���̺�
local loadedModules = {}

-- ����� �̸����� ã�� �ε��ϰ� ��ȯ�ϴ� �Լ�
function ModuleManager:GetModule(moduleName)
	if loadedModules[moduleName] then
		return loadedModules[moduleName]
	else
		local success, moduleScript = pcall(function()
			-- **[����]** FindFirstChild ��� WaitForChild ��� (Ÿ�Ӿƿ� �߰�)
			return modulesFolder:WaitForChild(moduleName, 10)
		end)

		if not success then
			warn("ModuleManager: ��� �˻�/��� �� ���� �߻�! '" .. moduleName .. "' - " .. tostring(moduleScript))
			return nil
		end

		if moduleScript and moduleScript:IsA("ModuleScript") then
			local requireSuccess, module = pcall(require, moduleScript)
			if requireSuccess then
				loadedModules[moduleName] = module
				print("ModuleManager: '" .. moduleName .. "' ��� �ε��")
				return module
			else
				warn("ModuleManager: '" .. moduleName .. "' ��� �ε� �� ���� �߻�! - " .. tostring(module))
				return nil
			end
		else
			-- WaitForChild ���� Ÿ�Ӿƿ��Ǹ� moduleScript�� nil�� �� ����
			warn("ModuleManager: '" .. moduleName .. "' ����� ã�� �� ���ų� �ε��� �� �����ϴ�! (Timeout �Ǵ� ModuleScript �ƴ�)")
			return nil
		end
	end
end

return ModuleManager