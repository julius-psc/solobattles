local ReplicatedStorage = game:GetService("ReplicatedStorage");
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

type settings = {
    Damage: number,
    FireRate: number,
    Range: number,
    Accuracy: number
};

return (function(settings: settings)
    return {
        Unequip = function()
            print("Unequipped MP5");
        end,
        Equip = function()
            print("Equipped MP5");

            local Assets = ReplicatedStorage:WaitForChild("Assets");
            local ViewModels = Assets:WaitForChild("ViewModels");
            local ViewModel = ViewModels:WaitForChild("Model_1"):Clone();
            ViewModel.Parent = workspace.CurrentCamera;

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

            game:GetService("RunService").RenderStepped:Connect(function()
                ViewModel:SetPrimaryPartCFrame(workspace.CurrentCamera.CFrame * CFrame.new(0, 0, -1));
            end);

            game:GetService("UserInputService").InputBegan:Connect(function(input)
                if (input.UserInputType == Enum.UserInputType.MouseButton1) then
                    shootAnimation:Play(0.1);
                end;

                if (input.KeyCode == Enum.KeyCode.R) and not reloadAnimation.IsPlaying then
                    reloadAnimation:Play(0.1);
                end;
            end);

            game:GetService("UserInputService").InputEnded:Connect(function(input)
                if (input.UserInputType == Enum.UserInputType.MouseButton1) then
                    shootAnimation:Stop(0.1);
                end;
            end);
        end
    };
end);
