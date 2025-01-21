local ReplicatedStorage = game:GetService("ReplicatedStorage");

type settings = {
    Damage: number,
    FireRate: number,
    Range: number,
    Accuracy: number
};

return (function(settings: settings)
    return {
        Unequip = function()
            print("Unequipped MP5");3
        end,
        Equip = function()
            print("Equipped MP5");

            local Assets = ReplicatedStorage:WaitForChild("Assets");
            local ViewModels = Assets:WaitForChild("ViewModels");
            local ViewModel = ViewModels:WaitForChild("Model_1"):Clone();
            ViewModel.Parent = workspace.CurrentCamera;

            game:GetService("RunService").RenderStepped:Connect(function()
                ViewModel:SetPrimaryPartCFrame(workspace.CurrentCamera.CFrame * CFrame.new(0, 0, -1));
            end);
        end
    };
end);
