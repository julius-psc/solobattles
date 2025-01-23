local ReplicatedStorage = game:GetService("ReplicatedStorage");
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

type settings = {
    Damage: number,
    FireRate: number,
    Range: number,
    Accuracy: number
};

return (function(self, settings: settings)
    return setmetatable({
        Connections =  {},
        Entities = {},
    }, (function(self)
        self.__index = self;
        return self;
    end)({
        Connect = function(self, name: string, connection: RBXScriptConnection)
            return rawset(self.Connections, name, connection);
        end,
        Disconnect = function(self, name: string)
            self.Connections[name]:Disconnect();
            return rawset(self.Connections, name, nil);
        end,
        DisconnectAll = function(self)
            for name, connection in pairs(self.Connections) do
                connection:Disconnect();
                self.Connections[name] = nil;
            end;
        end,
        Unequip = function(self)
            print("Unequipped MP5");
            game:GetService("UserInputService").MouseIconEnabled = true;
            self:DisconnectAll();
            self.Entities.ViewModel:Destroy();
        end,
        Equip = function(self)
            print("Equipped MP5");

            game:GetService("UserInputService").MouseIconEnabled = false;

            local Assets = ReplicatedStorage:WaitForChild("Assets");
            local ViewModels = Assets:WaitForChild("ViewModels");
            local ViewModel = ViewModels:WaitForChild("Model_1"):Clone();
            ViewModel.Parent = workspace.CurrentCamera;

            self.Entities.ViewModel = ViewModel;

            local Models = Assets:WaitForChild("Models");
            local Tool = Models:WaitForChild("MP5");

            local Animations = Tool:WaitForChild("Animations");
            local Model = Tool:WaitForChild("Model"):Clone();
            Model.Parent = ViewModel;

            local Humanoid = ViewModel:WaitForChild("Humanoid");
            local Animator: Animator = Humanoid:WaitForChild("Animator");

            local Motor6D = Instance.new("Motor6D", ViewModel);
            Motor6D.Part0 = ViewModel.HumanoidRootPart;
            Motor6D.Part1 = Model.Main;
            Motor6D.C0 = CFrame.new(0.027, 0.571, -0.169) * CFrame.Angles(math.rad(0.002), math.rad(-90.503), -0);

            local function createPreviewAnimation(keyframeSequence)
                local hashId = KeyframeSequenceProvider:RegisterKeyframeSequence(keyframeSequence)
                local Animation = Instance.new("Animation")
                Animation.AnimationId = hashId
                return Animation
            end

            local Idle = createPreviewAnimation(Animations:WaitForChild("Idle"))
            local Shoot = createPreviewAnimation(Animations:WaitForChild("Shoot"))
            local Reload = createPreviewAnimation(Animations:WaitForChild("Basic Reload"))

            local reloadAnimation = Animator:LoadAnimation(Reload);
            local shootAnimation = Animator:LoadAnimation(Shoot);
            local idleAnimation = Animator:LoadAnimation(Idle);
            idleAnimation:Play();

            self:Connect("RenderStepped", game:GetService("RunService").RenderStepped:Connect(function()
                ViewModel:SetPrimaryPartCFrame(workspace.CurrentCamera.CFrame * CFrame.new(0, 0, -1));
            end));

            self:Connect("InputBegan", game:GetService("UserInputService").InputBegan:Connect(function(input)
                if (input.UserInputType == Enum.UserInputType.MouseButton1) then
                    shootAnimation:Play(0.1);
                end;

                if (input.KeyCode == Enum.KeyCode.R) and not reloadAnimation.IsPlaying then
                    reloadAnimation:Play(0.1);
                end;

                if (input.KeyCode == Enum.KeyCode.H) then
                    self:Unequip();
                end;
            end));

            self:Connect("InputEnded", game:GetService("UserInputService").InputEnded:Connect(function(input)
                if (input.UserInputType == Enum.UserInputType.MouseButton1) then
                    shootAnimation:Stop(0.1);
                end;
            end));
        end
    }))
end);
