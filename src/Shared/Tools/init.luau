return setmetatable({
    Name = "Tools"
    ,Version = "1.0.0"
    ,Description = "A collection of tools for Roblox Lua"
    ,Author = "blacksmith"
    ,Settings = {
        ["MP5"] = {
            ["Damage"] = 20
            ,["FireRate"] = 0.1
            ,["Range"] = 100
            ,["Accuracy"] = 0.1
        }
    }
    ,Dependencies = {}
}, (function(self)
    self.__index = self;
    return self;
end)({
    __call = function(self, name: string)
        local Setting = self.Settings[name];
        Setting.Module = require(script:FindFirstChild(name) or script:WaitForChild(name));

        return Setting.Module(self, Setting);
    end,
}));
