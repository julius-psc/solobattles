local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared");

local Framework = require(Shared:WaitForChild("Framework"));
Framework:resolve();
