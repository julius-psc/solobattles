local ReplicatedStorage = game:GetService("ReplicatedStorage")
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local RemoteEvents = ReplicatedStorage.Shared.RemoteEvents
local ShootEvent = RemoteEvents:WaitForChild("ShootEvent")
local EquipEvent = RemoteEvents:WaitForChild("EquipEvent")

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
        IsReloading = false,
        FireRate = settings.FireRate,
        Damage = settings.Damage,
        Range = settings.Range,
        MaxAmmo = 30, -- Max ammo in the magazine
        CurrentAmmo = 30, -- Current ammo in the magazine
        ReserveAmmo = 120, -- Total reserve ammo
    }, {
        __index = self,
    })

    -- Function to update the ammo UI
    local function updateAmmoUI(currentAmmo, reserveAmmo)
        local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
        local ammoUI = playerGui:WaitForChild("AmmoUI")
        local currentAmmoLabel = ammoUI:WaitForChild("CurrentAmmo")
        local reserveAmmoLabel = ammoUI:WaitForChild("ReserveAmmo")

        currentAmmoLabel.Text = tostring(currentAmmo)
        reserveAmmoLabel.Text = tostring(reserveAmmo)
    end

    -- Function to apply damage to a target
    local function applyDamage(target)
        local model = target:FindFirstAncestorOfClass("Model")
        if not model then
            warn("Hit object has no parent model:", target.Name)
            return
        end

        local humanoid = model:FindFirstChild("Humanoid")
        if humanoid then
            humanoid:TakeDamage(weapon.Damage)
            humanoid.Health = math.max(0, humanoid.Health)
            print("Damaged:", model.Name, "Health:", humanoid.Health)
            return
        end

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

    -- RemoteEvents for 3D animations


    function weapon:Equip()
        if self.IsEquipped then return end
        print("Equipped MP5")
        self.IsEquipped = true

        UserInputService.MouseIconEnabled = false

        -- Initialize UI
        updateAmmoUI(self.CurrentAmmo, self.ReserveAmmo)

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

        -- Viewmodel animations (unchanged)
        local Idle = createPreviewAnimation(Animations:WaitForChild("Idle"))
        local Shoot = createPreviewAnimation(Animations:WaitForChild("Shoot"))
        local Reload = createPreviewAnimation(Animations:WaitForChild("Reload"))

        local reloadAnimation = Animator:LoadAnimation(Reload)
        local shootAnimation = Animator:LoadAnimation(Shoot)
        local idleAnimation = Animator:LoadAnimation(Idle)
        idleAnimation:Play()


        -- Function to handle shooting
        local function shoot()
            if self.IsShooting or self.CurrentAmmo <= 0 or self.IsReloading then return end
            self.IsShooting = true

            -- Decrement ammo
            self.CurrentAmmo = self.CurrentAmmo - 1
            print("Ammo:", self.CurrentAmmo)

            -- Update UI
            updateAmmoUI(self.CurrentAmmo, self.ReserveAmmo)

            -- Play viewmodel shoot animation
            shootAnimation:Play()
            ShootEvent:FireServer()


            -- Find the muzzle part in the cloned gun model
            local muzzle = self.Entities.ViewModel.Model.Muzzle
            if not muzzle then
                warn("Muzzle part not found in the gun model!")
                return
            end

            -- Raycasting
            local camera = workspace.CurrentCamera
            local origin = muzzle.Position
            local direction = camera.CFrame.LookVector * self.Range

            local raycastParams = RaycastParams.new()
            raycastParams.FilterType = Enum.RaycastFilterType.Blacklist
            raycastParams.FilterDescendantsInstances = {self.Entities.ViewModel, Players.LocalPlayer.Character}

            local raycastResult = workspace:Raycast(origin, direction, raycastParams)

            -- Spawn bullet tracer
            local tracer = Tool:WaitForChild("BulletTracer"):Clone()
            tracer.Parent = workspace

            -- Get the Beam and its Attachments
            local beam = tracer:FindFirstChildOfClass("Beam")
            local attachment0 = tracer:FindFirstChild("Attachment0")
            local attachment1 = tracer:FindFirstChild("Attachment1")

            if beam and attachment0 and attachment1 then
                -- Position the tracer at the muzzle
                tracer.CFrame = CFrame.lookAt(origin, origin + direction)

                -- Calculate the distance to the hit point or maximum range
                local distance = raycastResult and (raycastResult.Position - origin).Magnitude or self.Range

                -- Set the start and end positions of the Beam
                attachment0.WorldPosition = origin
                attachment1.WorldPosition = origin + (direction * distance)

                -- Destroy the tracer after a short delay
                task.delay(0.1, function()
                    tracer:Destroy()
                end)
            else
                warn("BulletTracer is missing Beam or Attachments!")
                if not beam then warn("Beam is missing!") end
                if not attachment0 then warn("Attachment0 is missing!") end
                if not attachment1 then warn("Attachment1 is missing!") end
                tracer:Destroy()
            end

            -- Apply damage to the hit target
            if raycastResult then
                local hit = raycastResult.Instance
                print("Hit:", hit.Name)
                applyDamage(hit)
            end

            -- Cooldown for firing rate
            task.wait(self.FireRate)
            self.IsShooting = false
        end

        -- Function to handle reloading
        local function reload()
            if self.CurrentAmmo == self.MaxAmmo or self.ReserveAmmo <= 0 or self.IsReloading then return end

            -- Set reloading state
            self.IsReloading = true

            -- Play viewmodel reload animation
            reloadAnimation:Play()

            -- Wait for the reload animation to finish
            task.wait(reloadAnimation.Length)

            -- Calculate ammo to reload
            local ammoNeeded = self.MaxAmmo - self.CurrentAmmo
            local ammoToReload = math.min(ammoNeeded, self.ReserveAmmo)

            -- Update ammo counts
            self.CurrentAmmo = self.CurrentAmmo + ammoToReload
            self.ReserveAmmo = self.ReserveAmmo - ammoToReload

            -- Update UI
            updateAmmoUI(self.CurrentAmmo, self.ReserveAmmo)

            -- Reset reloading state
            self.IsReloading = false
        end

        -- Input handling
        self:Connect("InputBegan", UserInputService.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 then
                shoot()
            end

            if input.KeyCode == Enum.KeyCode.R and not self.IsReloading then
                reload()
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
                EquipEvent:FireServer()
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