local ReplicatedStorage = game:GetService("ReplicatedStorage")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

type settings = {
    Damage: number,
    FireRate: number,
    Range: number,
    Accuracy: number
};

return function(self, settings: settings)
    local weapon = setmetatable({
        Connections =  {},
        Entities = {},
        IsEquipped = false,
        IsShooting = false,
        FireRate = settings.FireRate,
        Damage = settings.Damage,
        Range = settings.Range,
    }, {
        __index = self,
    })

    -- Function to apply damage to a target
local function applyDamage(target)
    -- Get the parent model of the hit part
    local model = target:FindFirstAncestorOfClass("Model")
    if not model then
        warn("Hit object has no parent model:", target.Name)
        return
    end

    -- Check if the model has a Humanoid
    local humanoid = model:FindFirstChild("Humanoid")
    if humanoid then
        humanoid:TakeDamage(weapon.Damage)
        -- Clamp health to 0
        humanoid.Health = math.max(0, humanoid.Health)
        print("Damaged:", model.Name, "Health:", humanoid.Health)
        return
    end

    -- Check if the model has a custom health system (e.g., a NumberValue named "Health")
    local healthValue = model:FindFirstChild("Health")
    if healthValue and healthValue:IsA("NumberValue") then
        healthValue.Value = math.max(0, healthValue.Value - weapon.Damage)
        print("Damaged:", model.Name, "Health:", healthValue.Value)
        return
    end

    warn("Target has no valid health system:", model.Name)
end

    function weapon:Connect(name: string, connection: RBXScriptConnection)
        self.Connections[name] = connection
        return connection
    end

    function weapon:Disconnect(name: string)
        if self.Connections[name] then
            self.Connections[name]:Disconnect()
            self.Connections[name] = nil
        end
    end

    function weapon:DisconnectAll()
        for name, connection in pairs(self.Connections) do
            connection:Disconnect()
            self.Connections[name] = nil
        end
    end

    function weapon:Unequip()
        if not self.IsEquipped then return end

        print("Unequipped MP5")
        UserInputService.MouseIconEnabled = true
        self:DisconnectAll()

        if self.Entities.ViewModel then
            self.Entities.ViewModel:Destroy()
            self.Entities.ViewModel = nil
        end

        self.IsEquipped = false
    end

    function weapon:Equip()
        if self.IsEquipped then return end

        print("Equipped MP5")
        self.IsEquipped = true

        UserInputService.MouseIconEnabled = false

        local Assets = ReplicatedStorage:WaitForChild("Assets")
        local ViewModels = Assets:WaitForChild("ViewModels")
        local ViewModel = ViewModels:WaitForChild("Model_1"):Clone()
        ViewModel.Parent = workspace.CurrentCamera

        self.Entities.ViewModel = ViewModel

        local Models = Assets:WaitForChild("Models")
        local Tool = Models:WaitForChild("MP5")

        local Animations = Tool:WaitForChild("Animations")
        local Model = Tool:WaitForChild("Model"):Clone()
        Model.Parent = ViewModel

        local Humanoid = ViewModel:WaitForChild("Humanoid")
        local Animator: Animator = Humanoid:WaitForChild("Animator")

        local Motor6D = Instance.new("Motor6D", ViewModel)
        Motor6D.Part0 = ViewModel.HumanoidRootPart
        Motor6D.Part1 = Model.Main
        Motor6D.C0 = CFrame.new(0.027, 0.571, -0.169) * CFrame.Angles(math.rad(0.002), math.rad(-90.503), -0)

        local function createPreviewAnimation(keyframeSequence)
            local hashId = KeyframeSequenceProvider:RegisterKeyframeSequence(keyframeSequence)
            local Animation = Instance.new("Animation")
            Animation.AnimationId = hashId
            return Animation
        end

        local Idle = createPreviewAnimation(Animations:WaitForChild("Idle"))
        local Shoot = createPreviewAnimation(Animations:WaitForChild("Shoot"))
        local Reload = createPreviewAnimation(Animations:WaitForChild("Basic Reload"))

        local reloadAnimation = Animator:LoadAnimation(Reload)
        local shootAnimation = Animator:LoadAnimation(Shoot)
        local idleAnimation = Animator:LoadAnimation(Idle)
        idleAnimation:Play()

        -- Function to handle shooting
        local function shoot()
            if self.IsShooting then return end
            self.IsShooting = true

            -- Find the muzzle part in the cloned gun model
            local muzzle = self.Entities.ViewModel.Model.Muzzle
            if not muzzle then
                warn("Muzzle part not found in the gun model!")
                return
            end

            -- Play shoot animation
            shootAnimation:Play()

            -- Raycasting
            local camera = workspace.CurrentCamera
            local origin = muzzle.Position
            local direction = camera.CFrame.LookVector * self.Range

            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
            raycastParams.FilterDescendantsInstances = {self.Entities.ViewModel, Players.LocalPlayer.Character}

            local raycastResult = workspace:Raycast(origin, direction, raycastParams)

            if raycastResult then
                local hit = raycastResult.Instance
                print("Hit:", hit.Name)

                -- Apply damage to the hit target
                applyDamage(hit)
            end

            -- Cooldown for firing rate
            task.wait(self.FireRate)
            self.IsShooting = false
        end

        -- Input handling
        self:Connect("InputBegan", UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                shoot()
            end

            if input.KeyCode == Enum.KeyCode.R and not reloadAnimation.IsPlaying then
                reloadAnimation:Play(0.4)
            end
        end))

        self:Connect("RenderStepped", RunService.RenderStepped:Connect(function()
            ViewModel:SetPrimaryPartCFrame(workspace.CurrentCamera.CFrame * CFrame.new(0, 0, -1))
        end))
    end

    -- Add global E key listener to equip/re-equip the weapon
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.E then
            if not weapon.IsEquipped then
                weapon:Equip()
            end
        end
    end)

    -- Add global H key listener to unequip the weapon
    UserInputService.InputBegan:Connect(function(input)
        if input.KeyCode == Enum.KeyCode.H then
            if weapon.IsEquipped then
                weapon:Unequip()
            end
        end
    end)

    return weapon
end