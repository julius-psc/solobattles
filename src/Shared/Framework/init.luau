--? Dependencies
local RunService = game:GetService("RunService");

--? Types
type constructor = {

}

type methods = {
    resolve: (self: class) -> any;
}

type class = typeof(setmetatable) & constructor & methods

return setmetatable({
    Name = "Framework"
    ,Version = "1.0.0"
    ,Description = "A framework for Roblox Lua"
    ,Author = "blacksmith"
    ,Modules = script:FindFirstChild("Modules") or script:WaitForChild("Modules")
}, (function(self)
    self.__index = self;
    return self;
end)({
    resolve = function(self)
        for _, module in self.Modules:GetChildren() do
            local success, response = pcall(RunService[`Is{module.Name}`], RunService);

            if (success and response) then
                return require(module)();
            end;
        end;
    end;
} :: methods)) :: class;
