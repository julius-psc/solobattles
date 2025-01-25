local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Framework = require(Shared:WaitForChild("Framework"))
Framework:resolve()

-- Services
local KeyframeSequenceProvider = game:GetService("KeyframeSequenceProvider")

-- RemoteEvents
local RemoteEvents = Shared:WaitForChild("RemoteEvents")
local ShootEvent = RemoteEvents:WaitForChild("ShootEvent")
local EquipEvent = RemoteEvents:WaitForChild("EquipEvent")

-- Function to convert KeyframeSequence to Animation
local function createPreviewAnimation(keyframeSequence)
    local hashId = KeyframeSequenceProvider:RegisterKeyframeSequence(keyframeSequence)
    local animation = Instance.new("Animation")     
    animation.AnimationId = hashId
    return animation
end

-- Function to play 3D animations on a character
local function playAnimation(character, animationName)
    local humanoid = character:FindFirstChild("Humanoid")
    if not humanoid then
        warn("Character has no Humanoid:", character.Name)
        return
    end

    local animator = humanoid:FindFirstChild("Animator")
    if not animator then
        animator = Instance.new("Animator", humanoid)
    end

    -- Load animation from ServerStorage/RBX_ANIMSAVES
    local keyframeSequence = ServerStorage:WaitForChild("RBX_ANIMSAVES"):FindFirstChild(animationName)
    if not keyframeSequence then
        warn("Animation not found:", animationName)
        return
    end

    -- Convert KeyframeSequence to Animation
    local animationId = game:GetService("KeyframeSequenceProvider"):RegisterKeyframeSequence(keyframeSequence)
    local animation = Instance.new("Animation")
    animation.AnimationId = animationId

    -- Load and play
    local track = animator:LoadAnimation(animation)
    track:Play()
    return track
end


