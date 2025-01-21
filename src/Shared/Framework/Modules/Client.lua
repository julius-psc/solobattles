local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared");

return (function()
    local Tools = require(Shared:WaitForChild("Tools"));

    local MP5 = Tools("MP5");
    MP5:Equip();
end)
