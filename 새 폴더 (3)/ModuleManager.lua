--[[
  **2. ReplicatedStorage > Modules > ModuleManager (ModuleScript)**
  다른 모듈들을 쉽게 불러올 수 있게 도와주는 관리자 모듈입니다.
]]

-- ModuleManager (ModuleScript)
local ModuleManager = {}

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local modulesFolder = ReplicatedStorage:WaitForChild("Modules")

-- 로드된 모듈들을 저장할 테이블
local loadedModules = {}

-- 모듈을 이름으로 찾아 로드하고 반환하는 함수
function ModuleManager:GetModule(moduleName)
	if loadedModules[moduleName] then
		return loadedModules[moduleName]
	else
		local success, moduleScript = pcall(function()
			-- **[수정]** FindFirstChild 대신 WaitForChild 사용 (타임아웃 추가)
			return modulesFolder:WaitForChild(moduleName, 10)
		end)

		if not success then
			warn("ModuleManager: 모듈 검색/대기 중 오류 발생! '" .. moduleName .. "' - " .. tostring(moduleScript))
			return nil
		end

		if moduleScript and moduleScript:IsA("ModuleScript") then
			local requireSuccess, module = pcall(require, moduleScript)
			if requireSuccess then
				loadedModules[moduleName] = module
				print("ModuleManager: '" .. moduleName .. "' 모듈 로드됨")
				return module
			else
				warn("ModuleManager: '" .. moduleName .. "' 모듈 로딩 중 오류 발생! - " .. tostring(module))
				return nil
			end
		else
			-- WaitForChild 에서 타임아웃되면 moduleScript가 nil일 수 있음
			warn("ModuleManager: '" .. moduleName .. "' 모듈을 찾을 수 없거나 로드할 수 없습니다! (Timeout 또는 ModuleScript 아님)")
			return nil
		end
	end
end

return ModuleManager