local Library = loadstring(game:HttpGet("https://raw.githubusercontent.com/jixyuk12nh-maker/Ui/main/Minho_Hub_Obsidian_UI.lua"))()

local Window = Library:CreateWindow({
    Title = "Minho Hub",
    Footer = "Discord.gg/minho-hub • Minho Hub",
    Size = UDim2.fromOffset(1000, 550)
})

local Main = Window:AddTab("Main")
local World = Window:AddTab("World")
local Visuals = Window:AddTab("Visuals")
local Character = Window:AddTab("Character")
local Spoofer = Window:AddTab("Spoofer")
local Misc = Window:AddTab("Misc")
local Settings = Window:AddTab("Settings")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local LocalPlayer = Players.LocalPlayer

-- =========================================================
-- Rivals: Fire Rate / Attack Speed
-- =========================================================
local RIVALS_GAMEID = 6035872082
local originalData = {}
local rivalsItems = nil

local GUN_BLACKLIST = {
    ["Molotov"] = true, ["Warpstone"] = true, ["Smoke Grenade"] = true,
    ["Satchel"] = true, ["Flashbang"] = true, ["Freeze Ray"] = true,
    ["War Horn"] = true, ["Grenade"] = true, ["Jump Pad"] = true,
    ["Subspace Tripmine"] = true, ["Medkit"] = true, ["Grappler"] = true,
    ["RNG Dice"] = true, ["MISSING_WEAPON"] = true,
}

local MELEE_WHITELIST = {
    ["Knife"] = true, ["Katana"] = true, ["Scythe"] = true,
    ["Scepter"] = true, ["Maul"] = true, ["Battle Axe"] = true,
    ["Chainsaw"] = true, ["Spear"] = true, ["Fists"] = true,
    ["Trowel"] = true, ["Riot Shield"] = true,
}

local function backupOriginals(items)
    for name, data in pairs(items) do
        if typeof(data) == "table" and not originalData[name] then
            originalData[name] = {
                ShootSpread = data.ShootSpread, ShootAccuracy = data.ShootAccuracy,
                ShootRecoil = data.ShootRecoil, ShootCooldown = data.ShootCooldown,
                ShootBurstCooldown = data.ShootBurstCooldown,
                AttackCooldown = data.AttackCooldown, SwingCooldown = data.SwingCooldown,
                MeleeCooldown = data.MeleeCooldown, Cooldown = data.Cooldown,
                RecoveryTime = data.RecoveryTime, ResetTime = data.ResetTime,
            }
        end
    end
end

local function getRivalsItems()
    if game.GameId ~= RIVALS_GAMEID then return nil end
    if rivalsItems then return rivalsItems end
    local ok, result = pcall(function()
        return require(game:GetService("ReplicatedStorage").Modules.ItemLibrary).Items
    end)
    if ok then
        rivalsItems = result
        backupOriginals(rivalsItems)
        return rivalsItems
    else
        warn("Rivals ItemLibrary 로드 실패:", result)
        return nil
    end
end

local function applyFireRate()
    local items = getRivalsItems()
    if not items then return end
    for name, data in pairs(items) do
        if typeof(data) == "table" and not GUN_BLACKLIST[name] then
            if data.ShootSpread then data.ShootSpread = 0 end
            if data.ShootAccuracy then data.ShootAccuracy = 0 end
            if data.ShootRecoil then data.ShootRecoil = 0 end
            if data.ShootCooldown then data.ShootCooldown = 0.001 end
            if data.ShootBurstCooldown then data.ShootBurstCooldown = 0.001 end
        end
    end
end

local function applyMeleeSpeed()
    local items = getRivalsItems()
    if not items then return end
    for name, data in pairs(items) do
        if typeof(data) == "table" and MELEE_WHITELIST[name] then
            if data.AttackCooldown then data.AttackCooldown = 0.001 end
            if data.SwingCooldown then data.SwingCooldown = 0.001 end
            if data.MeleeCooldown then data.MeleeCooldown = 0.001 end
            if data.Cooldown then data.Cooldown = 0.001 end
            if data.RecoveryTime then data.RecoveryTime = 0.001 end
            if data.ResetTime then data.ResetTime = 0.001 end
        end
    end
end

local function restoreAllItemData()
    local items = getRivalsItems()
    if not items then return end
    for name, data in pairs(items) do
        local orig = originalData[name]
        if orig and typeof(data) == "table" then
            for k, v in pairs(orig) do
                if v ~= nil then data[k] = v end
            end
        end
    end
end

-- =========================================================
-- No Spread + Full Auto
-- =========================================================
local weaponState = getgenv().__MinhoWeaponState or {
    Enabled = false, Installed = false, NoSpread = false, FullAuto = false,
    FullAutoItems = setmetatable({}, {__mode = "k"}),
    OriginalInput = nil, OriginalGunStartShooting = nil,
    ClientItem = nil, GunItem = nil,
}
getgenv().__MinhoWeaponState = weaponState

if weaponState.ClientItem and weaponState.OriginalInput then
    pcall(function() weaponState.ClientItem.Input = weaponState.OriginalInput end)
end
if weaponState.GunItem and weaponState.OriginalGunStartShooting then
    pcall(function() weaponState.GunItem.StartShooting = weaponState.OriginalGunStartShooting end)
end
weaponState.Installed = false

local function isLocalItem(item)
    local fighter = item and item.ClientFighter
    if not fighter then return false end
    if fighter.IsLocalPlayer == true then return true end
    return fighter.Player == LocalPlayer
end

local function getFullAutoDelay(item)
    local remaining = type(item._shoot_cooldown) == "number"
        and math.max(item._shoot_cooldown - tick(), 0) or 0
    if remaining > 0 then return math.clamp(remaining, 0.01, 1) end
    local info = item.Info
    local cooldown = info and tonumber(info.ShootCooldown) or 0
    if info and tonumber(info.BurstCount) and info.BurstCount > 1 then
        cooldown = tonumber(info.BurstCooldown) or cooldown
    end
    return math.clamp(cooldown > 0 and cooldown or (1 / 60), 1 / 60, 1)
end

local function startFullAuto(item, input)
    if weaponState.FullAutoItems[item] then return end
    weaponState.FullAutoItems[item] = true
    task.spawn(function()
        while weaponState.Enabled and weaponState.FullAuto and item
            and isLocalItem(item)
            and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1) do
            task.wait(getFullAutoDelay(item))
            if not (weaponState.Enabled and weaponState.FullAuto and isLocalItem(item)
                and UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton1)) then break end
            pcall(function() weaponState.OriginalInput(item, input) end)
        end
        weaponState.FullAutoItems[item] = nil
    end)
end

local function installWeaponHooks()
    if weaponState.Installed then return true end
    local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts", 10)
    if not PlayerScripts then return false end
    local modules = PlayerScripts:WaitForChild("Modules", 10)
    if not modules then return false end
    local itemTypes = modules:WaitForChild("ItemTypes", 10)
    if not itemTypes then return false end

    local ok1, ClientItem = pcall(require,
        modules:WaitForChild("ClientReplicatedClasses", 10)
            :WaitForChild("ClientFighter", 10):WaitForChild("ClientItem", 10))
    local ok2, GunItem = pcall(require, itemTypes:WaitForChild("Gun", 10))
    if not ok1 or not ok2 then
        warn("[Minho] Weapon hooks failed"); return false
    end

    weaponState.ClientItem = ClientItem
    weaponState.GunItem = GunItem

    weaponState.OriginalInput = ClientItem.Input
    ClientItem.Input = function(self, input, ...)
        local result = {weaponState.OriginalInput(self, input, ...)}
        if weaponState.Enabled and weaponState.FullAuto
            and input == "StartShooting" and isLocalItem(self) then
            startFullAuto(self, input)
        end
        return unpack(result)
    end

    weaponState.OriginalGunStartShooting = GunItem.StartShooting
    GunItem.StartShooting = function(self, ...)
        local result = {weaponState.OriginalGunStartShooting(self, ...)}
        if weaponState.Enabled and weaponState.NoSpread and isLocalItem(self)
            and typeof(result[3]) == "table" then
            result[4] = true
        end
        return unpack(result)
    end

    weaponState.Installed = true
    return true
end

local function updateWeaponState()
    local enabled = weaponState.NoSpread or weaponState.FullAuto
    weaponState.Enabled = enabled
    if enabled then
        installWeaponHooks()
    else
        if weaponState.ClientItem and weaponState.OriginalInput then
            pcall(function() weaponState.ClientItem.Input = weaponState.OriginalInput end)
        end
        if weaponState.GunItem and weaponState.OriginalGunStartShooting then
            pcall(function() weaponState.GunItem.StartShooting = weaponState.OriginalGunStartShooting end)
        end
        weaponState.Installed = false
    end
end

-- =========================================================
-- UE Assisted Rage
-- =========================================================
local TELEPORT_CFRAME = CFrame.new(9000, 9000, 9000)
local trackedParts = {}
local ueEnabled = false

local function setUERage(state)
    ueEnabled = state
    if not ueEnabled then trackedParts = {} end
end

workspace.ChildAdded:Connect(function(o)
    if not ueEnabled then return end
    if not o:IsA("BasePart") then return end
    if o.Name == "CoreProjectile" then
        trackedParts[o] = true
    elseif o.Name == "Part" then
        task.defer(function()
            if o and o.Parent and o.AssemblyLinearVelocity.Magnitude > 50 then
                trackedParts[o] = true
            end
        end)
    end
end)

workspace.ChildRemoved:Connect(function(o) trackedParts[o] = nil end)

RunService.Heartbeat:Connect(function()
    if not ueEnabled then return end
    pcall(function()
        for _, p in pairs(Players:GetPlayers()) do
            if p ~= LocalPlayer and p.Character then
                local h = p.Character:FindFirstChild("HumanoidRootPart")
                if h then
                    h.CFrame = TELEPORT_CFRAME
                    h.AssemblyLinearVelocity = Vector3.zero
                    h.AssemblyAngularVelocity = Vector3.zero
                end
            end
        end
        for _, o in pairs(workspace:GetChildren()) do
            if o.Name == "CoreProjectile" and o:IsA("BasePart") then
                o.CFrame = TELEPORT_CFRAME
                o.AssemblyLinearVelocity = Vector3.zero
            end
        end
        for p in pairs(trackedParts) do
            if p and p.Parent then
                p.CFrame = TELEPORT_CFRAME
                p.AssemblyLinearVelocity = Vector3.zero
            else
                trackedParts[p] = nil
            end
        end
    end)
end)

-- =========================================================
-- 상태값
-- =========================================================
local fireRateOn = false
local meleeOn = false

local function reapplyItemData()
    if game.GameId ~= RIVALS_GAMEID then return end
    restoreAllItemData()
    if fireRateOn then applyFireRate() end
    if meleeOn    then applyMeleeSpeed() end
end

-- =========================================================
-- CHARACTER: Movement
-- =========================================================
local movementState = getgenv().__MinhoMovementState or {
    Mechanics = nil, SlideOriginals = {}, ItemOriginals = {},
    OldSlide = nil, OldDoubleJump = nil, OldHighJump = nil,
    Hooked = false, HookedMechanics = nil,
    VelocityEnabled = false, VelocitySpeed = 50, VelocityConn = nil,
    SlideBoostEnabled = false, SlideBoostValue = 1, SlideBoostConn = nil,
    DoubleJumpEnabled = false, DoubleJumpValue = 1,
    MaulSlamEnabled = false, MaulSlamValue = 1, MaulSlamConn = nil,
    InfiniteDoubleJump = false, InfiniteDJConn = nil,
}
getgenv().__MinhoMovementState = movementState

do
    local mech = movementState.HookedMechanics
    if mech then
        if movementState.OldSlide and type(mech.Slide) == "function" then
            pcall(function() mech.Slide = movementState.OldSlide end)
        end
        if movementState.OldDoubleJump and type(mech.DoubleJump) == "function" then
            pcall(function() mech.DoubleJump = movementState.OldDoubleJump end)
        end
        if movementState.OldHighJump and type(mech.HighJump) == "function" then
            pcall(function() mech.HighJump = movementState.OldHighJump end)
        end
    end
    movementState.Hooked = false
    movementState.HookedMechanics = nil
end

local function getMechanics()
    if movementState.Mechanics then return movementState.Mechanics end
    local ok, mech = pcall(function()
        return require(LocalPlayer.PlayerScripts.Controllers.MechanicsController)
    end)
    if ok and mech then movementState.Mechanics = mech return mech end
end

local function getMovementRootHum()
    local char = LocalPlayer.Character
    if not char then return end
    return char:FindFirstChild("HumanoidRootPart"), char:FindFirstChildOfClass("Humanoid")
end

local function isMovementAirborne(hum, root)
    if not hum then return false end
    local stateType = hum:GetState()
    if stateType == Enum.HumanoidStateType.Jumping
        or stateType == Enum.HumanoidStateType.Freefall
        or stateType == Enum.HumanoidStateType.FallingDown
        or stateType == Enum.HumanoidStateType.Physics
        or stateType == Enum.HumanoidStateType.PlatformStanding then
        return true
    end
    if hum.FloorMaterial == Enum.Material.Air then return true end
    return root and math.abs(root.AssemblyLinearVelocity.Y) > 3 or false
end

local function isMovementSliding(hum)
    local mech = getMechanics()
    if mech and mech.IsSliding then return true end
    local fighter = mech and mech.LocalFighter
    if fighter and fighter.IsSlidingLocally then return true end
    return false
end

local function applyMovementVelocity()
    if not movementState.VelocityEnabled then return false end
    local root, hum = getMovementRootHum()
    if not root or not hum or hum.Health <= 0 then return false end
    if isMovementSliding(hum) then return false end
    local move = hum.MoveDirection
    if move.Magnitude > 0.1 then
        local dir = Vector3.new(move.X, 0, move.Z).Unit
        local speed = movementState.VelocitySpeed or 50
        root.AssemblyLinearVelocity = Vector3.new(dir.X * speed, root.AssemblyLinearVelocity.Y, dir.Z * speed)
    else
        if isMovementAirborne(hum, root) then return false end
        root.AssemblyLinearVelocity = Vector3.new(0, root.AssemblyLinearVelocity.Y, 0)
    end
    return true
end

local function restoreSlideBoost()
    for fighter, value in pairs(movementState.SlideOriginals) do
        pcall(function()
            if fighter and type(fighter.Set) == "function" then
                fighter:Set("SlidingSpeedMax", value)
            end
        end)
        movementState.SlideOriginals[fighter] = nil
    end
end

local function applySlideBoost(fighter)
    if not fighter or not movementState.SlideBoostEnabled then return end
    local ok, current = pcall(function() return fighter:Get("SlidingSpeedMax") end)
    local base = (movementState.SlideOriginals[fighter] ~= nil and movementState.SlideOriginals[fighter])
        or (ok and current) or 3
    movementState.SlideOriginals[fighter] = base
    pcall(function() fighter:Set("SlidingSpeedMax", base * movementState.SlideBoostValue) end)
end

local function restoreMovementItemInfo()
    for info, values in pairs(movementState.ItemOriginals) do
        if info then
            for key, value in pairs(values) do
                pcall(function() info[key] = value end)
            end
        end
        movementState.ItemOriginals[info] = nil
    end
end

local function saveMovementInfoValue(info, key)
    movementState.ItemOriginals[info] = movementState.ItemOriginals[info] or {}
    if movementState.ItemOriginals[info][key] == nil then
        movementState.ItemOriginals[info][key] = info[key]
    end
end

local function patchMovementEquippedItem()
    local mech = getMechanics()
    local fighter = mech and mech.LocalFighter
    local item = fighter and fighter.EquippedItem
    local info = item and item.Info
    if not info then return end
    if movementState.InfiniteDoubleJump then
        saveMovementInfoValue(info, "MaxDoubleJumps")
        info.MaxDoubleJumps = math.huge
        local objectId
        pcall(function() objectId = item:Get("ObjectID") end)
        if objectId and mech._double_jumps_used then
            mech._double_jumps_used[objectId] = 0
        end
    end
    if movementState.MaulSlamEnabled then
        for _, key in ipairs({"SlamDamage", "SlamRadius"}) do
            if type(info[key]) == "number" then
                saveMovementInfoValue(info, key)
                info[key] = movementState.ItemOriginals[info][key] * movementState.MaulSlamValue
            end
        end
    end
end

local function installMovementHooks()
    local mech = getMechanics()
    if not mech then return end
    if movementState.Hooked and movementState.HookedMechanics == mech then return end
    movementState.Hooked = true
    movementState.HookedMechanics = mech

    if type(mech.Slide) == "function" and not movementState.OldSlide then
        movementState.OldSlide = mech.Slide
        mech.Slide = function(self, ...)
            applySlideBoost(self and self.LocalFighter)
            return movementState.OldSlide(self, ...)
        end
    end
    if type(mech.DoubleJump) == "function" and not movementState.OldDoubleJump then
        movementState.OldDoubleJump = mech.DoubleJump
        mech.DoubleJump = function(self, ...)
            local result = movementState.OldDoubleJump(self, ...)
            if movementState.DoubleJumpEnabled then
                local fighter = self and self.LocalFighter
                local root = fighter and fighter.Entity and fighter.Entity.RootPart
                if root then
                    local vel = root.Velocity
                    root.Velocity = Vector3.new(vel.X, vel.Y * movementState.DoubleJumpValue, vel.Z)
                end
            end
            return result
        end
    end
end

-- =========================================================
-- Fly & Noclip (+ Third Person)
-- =========================================================
local noclipState = getgenv().__MinhoNoclipState or { Enabled = false, Conn = nil }
getgenv().__MinhoNoclipState = noclipState

if noclipState.Conn then
    pcall(function() noclipState.Conn:Disconnect() end)
    noclipState.Conn = nil
end

local function startNoclip()
    if noclipState.Conn then return end
    noclipState.Conn = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = false end
        end
    end)
end

local function stopNoclip()
    if noclipState.Conn then noclipState.Conn:Disconnect() noclipState.Conn = nil end
    local char = LocalPlayer.Character
    if char then
        for _, part in ipairs(char:GetDescendants()) do
            if part:IsA("BasePart") then part.CanCollide = true end
        end
    end
end

local flyState = getgenv().__MinhoFlyState or {
    Enabled = false, Gyro = nil, Velocity = nil,
    Speed = 50, KeyState = {w=0,s=0,a=0,d=0,up=0,down=0},
    InputBeganConn = nil, InputEndedConn = nil, RenderConn = nil,
}
getgenv().__MinhoFlyState = flyState

do
    if flyState.InputBeganConn then pcall(function() flyState.InputBeganConn:Disconnect() end) flyState.InputBeganConn = nil end
    if flyState.InputEndedConn then pcall(function() flyState.InputEndedConn:Disconnect() end) flyState.InputEndedConn = nil end
    if flyState.RenderConn then pcall(function() flyState.RenderConn:Disconnect() end) flyState.RenderConn = nil end
    if flyState.Gyro then pcall(function() flyState.Gyro:Destroy() end) flyState.Gyro = nil end
    if flyState.Velocity then pcall(function() flyState.Velocity:Destroy() end) flyState.Velocity = nil end
end

local function isFlyAlive()
    local char = LocalPlayer.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0 and char.PrimaryPart
end

local function cleanupFly()
    if flyState.Gyro then flyState.Gyro:Destroy() flyState.Gyro = nil end
    if flyState.Velocity then flyState.Velocity:Destroy() flyState.Velocity = nil end
    if flyState.InputBeganConn then flyState.InputBeganConn:Disconnect() flyState.InputBeganConn = nil end
    if flyState.InputEndedConn then flyState.InputEndedConn:Disconnect() flyState.InputEndedConn = nil end
    if flyState.RenderConn then flyState.RenderConn:Disconnect() flyState.RenderConn = nil end
    if isFlyAlive() then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
    flyState.KeyState = {w=0,s=0,a=0,d=0,up=0,down=0}
end

local function startFly()
    if flyState.Gyro then flyState.Gyro:Destroy() flyState.Gyro = nil end
    if flyState.Velocity then flyState.Velocity:Destroy() flyState.Velocity = nil end
    if not isFlyAlive() then return end
    local char = LocalPlayer.Character
    local hum = char:FindFirstChildOfClass("Humanoid")
    local root = char:FindFirstChild("HumanoidRootPart")
    if not hum or not root then return end

    flyState.Gyro = Instance.new("BodyGyro")
    flyState.Gyro.P = 9e4
    flyState.Gyro.MaxTorque = Vector3.new(9e9, 9e9, 9e9)
    flyState.Gyro.CFrame = root.CFrame
    flyState.Gyro.Parent = root

    flyState.Velocity = Instance.new("BodyVelocity")
    flyState.Velocity.MaxForce = Vector3.new(9e9, 9e9, 9e9)
    flyState.Velocity.Velocity = Vector3.zero
    flyState.Velocity.Parent = root

    hum.PlatformStand = true
end

local function setFlyInput(input, state)
    if UserInputService:GetFocusedTextBox() then return end
    if input.KeyCode == Enum.KeyCode.W then flyState.KeyState.w = state and 1 or 0
    elseif input.KeyCode == Enum.KeyCode.S then flyState.KeyState.s = state and 1 or 0
    elseif input.KeyCode == Enum.KeyCode.A then flyState.KeyState.a = state and 1 or 0
    elseif input.KeyCode == Enum.KeyCode.D then flyState.KeyState.d = state and 1 or 0
    elseif input.KeyCode == Enum.KeyCode.Space or input.KeyCode == Enum.KeyCode.E then
        flyState.KeyState.up = state and 1 or 0
    elseif input.KeyCode == Enum.KeyCode.LeftControl or input.KeyCode == Enum.KeyCode.Q then
        flyState.KeyState.down = state and 1 or 0
    end
end

-- =========================================================
-- Third Person
-- =========================================================
local thirdPersonState = getgenv().__MinhoThirdPersonState or {
    Enabled = false, Task = nil,
}
getgenv().__MinhoThirdPersonState = thirdPersonState

if thirdPersonState.Task then
    pcall(task.cancel, thirdPersonState.Task)
    thirdPersonState.Task = nil
end

local function getCameraController()
    local ok, ctrl = pcall(function()
        return require(LocalPlayer.PlayerScripts.Controllers.CameraController)
    end)
    return ok and ctrl or nil
end

local function stopThirdPerson()
    if thirdPersonState.Task then
        pcall(task.cancel, thirdPersonState.Task)
        thirdPersonState.Task = nil
    end
    local gun = getCameraController()
    if gun and gun.CameraState then
        pcall(function() gun.CameraState:_SetPOVState(gun.CameraState.States.FirstPerson) end)
    end
end

-- =========================================================
-- Anti Aim
-- =========================================================
local antiAimState = getgenv().__MinhoAntiAimState or {
    Enabled = false, Pitch = "disabled", Yaw = "disabled", Underground = false,
    Task = nil, MTInstalled = false, MT = nil, OldNamecall = nil,
}
getgenv().__MinhoAntiAimState = antiAimState

if antiAimState.Task then pcall(task.cancel, antiAimState.Task) antiAimState.Task = nil end

if antiAimState.MTInstalled and antiAimState.MT and antiAimState.OldNamecall then
    pcall(function()
        antiAimState.MT.__namecall = antiAimState.OldNamecall
    end)
    antiAimState.MTInstalled = false
end

_G.AntiAimPoseConfig = nil

local function installAntiAimHook()
    if antiAimState.MTInstalled then return true end
    if not getrawmetatable or not setreadonly then
        warn("[Minho] hookmetamethod 지원 안 됨")
        return false
    end
    local ok, util = pcall(function() return require(ReplicatedStorage.Modules.Utility) end)
    if not ok or not util then return false end
    local ok2, camCtrl = pcall(function() return require(LocalPlayer.PlayerScripts.Controllers.CameraController) end)
    if not ok2 or not camCtrl then return false end

    local mt = getrawmetatable(game)
    local oldNamecall = mt.__namecall
    antiAimState.MT = mt
    antiAimState.OldNamecall = oldNamecall

    setreadonly(mt, false)
    mt.__namecall = newcclosure(function(self, ...)
        local method = getnamecallmethod()
        if method == "FireServer" and antiAimState.Enabled then
            local remoteName = self.Name
            if remoteName == "UpdateCameraRotation" then
                local cfg = _G.AntiAimPoseConfig
                if cfg and cfg.enabled then
                    local currentRotation = camCtrl.Rotation or Vector2.zero
                    local pitch, yaw = currentRotation.X or 0, currentRotation.Y or 0
                    if cfg.pitch == "up" then pitch = math.rad(-89)
                    elseif cfg.pitch == "down" then pitch = math.rad(179)
                    elseif cfg.pitch == "zero" then pitch = 0
                    elseif cfg.pitch == "random" then pitch = math.rad(math.random(-89, 179)) end
                    if cfg.yaw == "backwards" then yaw = yaw + math.rad(180)
                    elseif cfg.yaw == "spin" then yaw = math.rad((tick() * 720) % 360)
                    elseif cfg.yaw == "random" then yaw = math.rad(math.random(0, 359)) end
                    local rotation = Vector2.new(pitch, yaw)
                    local encoded = util:EncodeCameraRotation(rotation)
                    return oldNamecall(self, encoded, nil)
                end
            end
        end
        return oldNamecall(self, ...)
    end)
    setreadonly(mt, true)

    antiAimState.MTInstalled = true
    return true
end

local function uninstallAntiAimHook()
    if not antiAimState.MTInstalled then return end
    if antiAimState.MT and antiAimState.OldNamecall then
        pcall(function()
            setreadonly(antiAimState.MT, false)
            antiAimState.MT.__namecall = antiAimState.OldNamecall
            setreadonly(antiAimState.MT, true)
        end)
    end
    antiAimState.MTInstalled = false
end

-- =========================================================
-- Animation Player
-- =========================================================
local animState = getgenv().__MinhoAnimState or {
    Enabled = false, CurrentTrack = nil, CurrentAnimation = nil,
    CurrentHumanoid = nil, CurrentAnimator = nil,
    ReplayToken = 0, LastReplay = 0,
    Selected = "Floss", Custom = "", Speed = 1,
    EmoteAdded = false, HumanoidRef = nil,
}
getgenv().__MinhoAnimState = animState

local animations = {
    ["Bodybuilder"] = "3994130516", ["Crawling in a Circle"] = "116935126100338",
    ["Dolphin Dance"] = "5938365243", ["Dance"] = "507771019",
    ["Dance Break"] = "94258912028011", ["French Confidence"] = "116968182519797",
    ["Floss"] = "72174079036035", ["Frosty Flair"] = "10214406616",
    ["Full Wiggle"] = "86520127496722", ["Ghost Floating"] = "75911227509248",
    ["Gun"] = "81100102810594", ["Gangnam Style"] = "78801539668900",
    ["Hip Bounce"] = "123602332785269", ["Hype Dance"] = "93079641847306",
    ["Kicking Feet"] = "109814083870185", ["Line Dance"] = "4049646104",
    ["Lay Floating"] = "126579240140537", ["Let's Drive"] = "17360720445",
    ["Long Legs"] = "82416741608012", ["Rock Out"] = "18225077553",
    ["Samba"] = "6869813008", ["Still Standing"] = "11435177473",
    ["Spiral"] = "81926730031709", ["Solar System"] = "118314972618293",
    ["Twirl"] = "3716633898", ["Take Me Under"] = "6797938823",
    ["The Worm"] = "99563207397301", ["Take the L"] = "110664723286332",
    ["Zesty"] = "102901317133934",
}

local animationList = {
    "Bodybuilder", "Custom", "Crawling in a Circle", "Dolphin Dance", "Dance",
    "Dance Break", "French Confidence", "Floss", "Frosty Flair", "Full Wiggle",
    "Ghost Floating", "Gun", "Gangnam Style", "Hip Bounce", "Hype Dance",
    "Kicking Feet", "Line Dance", "Lay Floating", "Let's Drive", "Long Legs",
    "Rock Out", "Samba", "Still Standing", "Spiral", "Solar System", "Twirl",
    "Take Me Under", "The Worm", "Take the L", "Zesty",
}

local function stopAnimation()
    animState.ReplayToken = animState.ReplayToken + 1
    if animState.CurrentTrack then
        pcall(animState.CurrentTrack.Stop, animState.CurrentTrack, 0.1)
        pcall(animState.CurrentTrack.Destroy, animState.CurrentTrack)
        animState.CurrentTrack = nil
    end
    if animState.CurrentAnimation then
        animState.CurrentAnimation:Destroy()
        animState.CurrentAnimation = nil
    end
    animState.CurrentHumanoid = nil
    animState.CurrentAnimator = nil
    animState.EmoteAdded = false
    animState.HumanoidRef = nil
end

local function selectedAnimId()
    if animState.Selected == "Custom" then
        return tostring(animState.Custom):match("%d+")
    end
    return animations[animState.Selected]
end

local function playSelectedAnimation()
    if not animState.Enabled then return end
    local id = selectedAnimId()
    if not id or id == "" then stopAnimation() return end

    local character = LocalPlayer.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then return end

    if animState.HumanoidRef ~= humanoid then
        animState.EmoteAdded = false
        animState.HumanoidRef = humanoid
    end

    stopAnimation()
    animState.HumanoidRef = humanoid
    animState.ReplayToken = animState.ReplayToken + 1
    local token = animState.ReplayToken
    local track, animation

    if animState.Selected ~= "Custom" then
        local description = humanoid:FindFirstChildOfClass("HumanoidDescription")
        if not description then
            description = Instance.new("HumanoidDescription")
            description.Parent = humanoid
        end

        if not animState.EmoteAdded then
            pcall(function()
                pcall(description.RemoveEmote, description, "MinhoAnim")
                description:AddEmote("MinhoAnim", tonumber(id))
            end)
            animState.EmoteAdded = true
        end

        local captured
        local connection = animator.AnimationPlayed:Connect(function(t)
            captured = t
        end)

        pcall(function() humanoid:PlayEmote("MinhoAnim") end)

        local timeout = os.clock() + 2
        while not captured and os.clock() < timeout do
            RunService.Heartbeat:Wait()
        end
        connection:Disconnect()
        track = captured
    else
        animation = Instance.new("Animation")
        animation.AnimationId = "rbxassetid://" .. id
        local ok
        ok, track = pcall(animator.LoadAnimation, animator, animation)
        if not ok then track = nil end
    end

    if not track then
        if animation then animation:Destroy() end
        return
    end

    animState.CurrentAnimation = animation
    animState.CurrentTrack = track
    animState.CurrentHumanoid = humanoid
    animState.CurrentAnimator = animator
    animState.LastReplay = os.clock()
    track.Priority = Enum.AnimationPriority.Action4
    track.Looped = true
    track:Play(0.1, 1, animState.Speed)

    task.spawn(function()
        while token == animState.ReplayToken
            and animState.CurrentTrack == track
            and animState.Enabled do
            if not track.IsPlaying then
                track:Play(0.05, 1, animState.Speed)
            end
            track:AdjustSpeed(animState.Speed)
            track:AdjustWeight(1, 0)
            RunService.Heartbeat:Wait()
        end
    end)
end

-- =========================================================
-- UI
-- =========================================================
local Rage = Main:AddGroupbox({ Name = "Rage", Side = 1 })

Rage:AddCheckbox("UEAssistedRage", {
    Text = "UE Assisted Rage",
    Default = false,
    Callback = function(Value) setUERage(Value) end
})

local SpeedControl = Main:AddGroupbox({ Name = "Speed Control", Side = 1 })

SpeedControl:AddCheckbox("FireRateEnabled", {
    Text = "Fire Rate (Guns)",
    Default = false,
    Callback = function(Value) fireRateOn = Value reapplyItemData() end
})

SpeedControl:AddCheckbox("AttackSpeedEnabled", {
    Text = "Attack Speed (Melee)",
    Default = false,
    Callback = function(Value) meleeOn = Value reapplyItemData() end
})

SpeedControl:AddCheckbox("NoSpread", {
    Text = "No Spread",
    Default = false,
    Callback = function(Value) weaponState.NoSpread = Value updateWeaponState() end
})

SpeedControl:AddCheckbox("FullAuto", {
    Text = "Full Auto",
    Default = false,
    Callback = function(Value) weaponState.FullAuto = Value updateWeaponState() end
})

-- =========================================================
-- WORLD TAB UI
-- =========================================================
local Skybox = World:AddGroupbox({ Name = "Skybox", Side = 1 })

Skybox:AddCheckbox("SkyboxEnabled", {
    Text = "Enabled",
    Default = false,
    Callback = function(Value) print("Skybox Enabled:", Value) end
})

Skybox:AddDropdown("SkyboxType", {
    Text = "Skybox",
    Values = { "Default", "Galaxy", "Nebula", "Night", "Sunset" },
    Default = "Default",
    Multi = false,
    Callback = function(Value) print("Skybox:", Value) end
})

local TexturePackBox = World:AddGroupbox({ Name = "Texture Pack", Side = 2 })

TexturePackBox:AddDropdown("TexturePack", {
    Text = "Texture Pack",
    Values = { "Default", "Neon", "Cartoon", "Realistic", "Anime", "Flat" },
    Default = "Default",
    Multi = false,
    Callback = function(Value) print("Texture Pack:", Value) end
})

-- =========================================================
-- CHARACTER TAB UI
-- =========================================================
local MovementBox = Character:AddGroupbox({ Name = "Movement", Side = 1 })

MovementBox:AddCheckbox("VelocityEnabled", {
    Text = "Velocity",
    Default = false,
    Callback = function(Value)
        movementState.VelocityEnabled = Value
        if Value then
            installMovementHooks()
            if movementState.VelocityConn then movementState.VelocityConn:Disconnect() end
            movementState.VelocityConn = RunService.Heartbeat:Connect(applyMovementVelocity)
        else
            if movementState.VelocityConn then
                movementState.VelocityConn:Disconnect()
                movementState.VelocityConn = nil
            end
        end
    end
})

MovementBox:AddSlider("VelocitySpeed", {
    Text = "Velocity Speed",
    Default = 50, Min = 0, Max = 250, Rounding = 0,
    Callback = function(Value) movementState.VelocitySpeed = Value end
})

MovementBox:AddCheckbox("SlideBoostEnabled", {
    Text = "Slide Boost",
    Default = false,
    Callback = function(Value)
        movementState.SlideBoostEnabled = Value
        if Value then
            installMovementHooks()
            if movementState.SlideBoostConn then movementState.SlideBoostConn:Disconnect() end
            movementState.SlideBoostConn = RunService.Heartbeat:Connect(function()
                local mech = getMechanics()
                if mech then applySlideBoost(mech.LocalFighter) end
            end)
        else
            if movementState.SlideBoostConn then
                movementState.SlideBoostConn:Disconnect()
                movementState.SlideBoostConn = nil
            end
            restoreSlideBoost()
        end
    end
})

MovementBox:AddSlider("SlideBoostValue", {
    Text = "Slide Boost",
    Default = 1, Min = 1, Max = 5, Rounding = 1,
    Callback = function(Value)
        movementState.SlideBoostValue = Value
        restoreSlideBoost()
    end
})

MovementBox:AddCheckbox("DoubleJumpEnabled", {
    Text = "Double Jump Height",
    Default = false,
    Callback = function(Value)
        movementState.DoubleJumpEnabled = Value
        if Value then installMovementHooks() end
    end
})

MovementBox:AddSlider("DoubleJumpValue", {
    Text = "Double Jump Height",
    Default = 1, Min = 1, Max = 10, Rounding = 1,
    Callback = function(Value) movementState.DoubleJumpValue = Value end
})

MovementBox:AddCheckbox("MaulSlamEnabled", {
    Text = "Maul Slam Multiplier",
    Default = false,
    Callback = function(Value)
        movementState.MaulSlamEnabled = Value
        if Value then
            installMovementHooks()
            if movementState.MaulSlamConn then movementState.MaulSlamConn:Disconnect() end
            movementState.MaulSlamConn = RunService.Heartbeat:Connect(patchMovementEquippedItem)
        else
            if movementState.MaulSlamConn then
                movementState.MaulSlamConn:Disconnect()
                movementState.MaulSlamConn = nil
            end
            restoreMovementItemInfo()
        end
    end
})

MovementBox:AddSlider("MaulSlamValue", {
    Text = "Maul Slam Multiplier",
    Default = 1, Min = 1, Max = 10, Rounding = 1,
    Callback = function(Value)
        movementState.MaulSlamValue = Value
        restoreMovementItemInfo()
    end
})

MovementBox:AddCheckbox("InfiniteDoubleJump", {
    Text = "Infinite Double Jump",
    Default = false,
    Callback = function(Value)
        movementState.InfiniteDoubleJump = Value
        if Value then
            installMovementHooks()
            if movementState.InfiniteDJConn then movementState.InfiniteDJConn:Disconnect() end
            movementState.InfiniteDJConn = RunService.Heartbeat:Connect(patchMovementEquippedItem)
        else
            if movementState.InfiniteDJConn then
                movementState.InfiniteDJConn:Disconnect()
                movementState.InfiniteDJConn = nil
            end
            restoreMovementItemInfo()
        end
    end
})

local FlyNoclipBox = Character:AddGroupbox({ Name = "Fly & Noclip", Side = 1 })

FlyNoclipBox:AddCheckbox("Noclip", {
    Text = "Noclip",
    Default = false,
    Callback = function(Value)
        noclipState.Enabled = Value
        if Value then startNoclip() else stopNoclip() end
    end
})

FlyNoclipBox:AddCheckbox("FlyEnabled", {
    Text = "Fly",
    Default = false,
    Callback = function(Value)
        flyState.Enabled = Value
        if Value then
            startFly()
            flyState.InputBeganConn = UserInputService.InputBegan:Connect(function(input, processed)
                if not processed then setFlyInput(input, true) end
            end)
            flyState.InputEndedConn = UserInputService.InputEnded:Connect(function(input) setFlyInput(input, false) end)
            flyState.RenderConn = RunService.RenderStepped:Connect(function()
                if not flyState.Enabled then return end
                if not isFlyAlive() then return end
                if not flyState.Gyro or not flyState.Velocity
                    or not flyState.Gyro.Parent or not flyState.Velocity.Parent then
                    startFly()
                    return
                end
                local camera = workspace.CurrentCamera
                local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
                if hum then hum.PlatformStand = true end
                if camera then
                    flyState.Gyro.CFrame = camera.CFrame
                    local ks = flyState.KeyState
                    local move = (camera.CFrame.LookVector * (ks.w - ks.s))
                        + (camera.CFrame.RightVector * (ks.d - ks.a))
                        + (camera.CFrame.UpVector * (ks.up - ks.down))
                    flyState.Velocity.Velocity = move.Magnitude > 0
                        and (move.Unit * flyState.Speed) or Vector3.zero
                end
            end)
        else
            cleanupFly()
        end
    end
})

FlyNoclipBox:AddSlider("FlySpeed", {
    Text = "Fly Speed",
    Default = 50, Min = 50, Max = 300, Rounding = 0,
    Callback = function(Value) flyState.Speed = Value end
})

FlyNoclipBox:AddCheckbox("ThirdPerson", {
    Text = "Third Person",
    Default = false,
    Callback = function(Value)
        thirdPersonState.Enabled = Value
        if Value then
            if thirdPersonState.Task then pcall(task.cancel, thirdPersonState.Task) end
            thirdPersonState.Task = task.spawn(function()
                while thirdPersonState.Enabled do
                    local gun = getCameraController()
                    if gun and gun.CameraState then
                        pcall(function() gun.CameraState:_SetPOVState(gun.CameraState.States.ThirdPerson) end)
                    end
                    task.wait(0.1)
                end
            end)
        else
            stopThirdPerson()
        end
    end
})

local AntiAimBox = Character:AddGroupbox({ Name = "Anti Aim", Side = 2 })

AntiAimBox:AddCheckbox("AntiAimEnabled", {
    Text = "Enabled",
    Default = false,
    Callback = function(Value)
        antiAimState.Enabled = Value
        _G.AntiAimPoseConfig = {
            enabled = Value,
            pitch = antiAimState.Pitch,
            yaw = antiAimState.Yaw,
            underground = antiAimState.Underground,
        }
        if Value then
            installAntiAimHook()
        else
            _G.AntiAimPoseConfig = nil
            uninstallAntiAimHook()
        end
    end
})

AntiAimBox:AddDropdown("AntiAimPitch", {
    Text = "Pitch",
    Values = { "disabled", "up", "down", "zero", "random" },
    Default = "disabled",
    Multi = false,
    Callback = function(Value)
        antiAimState.Pitch = Value
        if _G.AntiAimPoseConfig then _G.AntiAimPoseConfig.pitch = Value end
    end
})

AntiAimBox:AddDropdown("AntiAimYaw", {
    Text = "Yaw",
    Values = { "disabled", "backwards", "spin", "random" },
    Default = "disabled",
    Multi = false,
    Callback = function(Value)
        antiAimState.Yaw = Value
        if _G.AntiAimPoseConfig then _G.AntiAimPoseConfig.yaw = Value end
    end
})

AntiAimBox:AddCheckbox("AntiAimUnderground", {
    Text = "Underground",
    Default = false,
    Callback = function(Value)
        antiAimState.Underground = Value
        if _G.AntiAimPoseConfig then _G.AntiAimPoseConfig.underground = Value end
    end
})

local AnimationBox = Character:AddGroupbox({ Name = "Animation Player", Side = 2 })

AnimationBox:AddCheckbox("AnimationEnabled", {
    Text = "Enabled",
    Default = false,
    Callback = function(Value)
        animState.Enabled = Value
        if Value then playSelectedAnimation() else stopAnimation() end
    end
})

AnimationBox:AddDropdown("AnimationSelected", {
    Text = "Animation",
    Values = animationList,
    Default = "Floss",
    Multi = false,
    Callback = function(Value)
        animState.Selected = Value
        animState.EmoteAdded = false
        if animState.Enabled then playSelectedAnimation() end
    end
})

AnimationBox:AddInput("AnimationCustom", {
    Text = "Custom Animation ID",
    Default = "",
    Placeholder = "ex: 4049646104",
    Callback = function(Value)
        animState.Custom = Value
        if animState.Enabled and animState.Selected == "Custom" then
            playSelectedAnimation()
        end
    end
})

AnimationBox:AddSlider("AnimationSpeed", {
    Text = "Speed",
    Default = 1, Min = 1, Max = 5, Rounding = 1,
    Callback = function(Value)
        animState.Speed = Value
        if animState.CurrentTrack then
            pcall(function() animState.CurrentTrack:AdjustSpeed(Value) end)
        end
    end
})
