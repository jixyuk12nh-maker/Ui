local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/jixyuk12nh-maker/Ui/main/Minho_Hub_Obsidian_UI.lua"
))()

local ThemeManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/deividcomsono/Obsidian/main/Addons/ThemeManager.lua"
))()
ThemeManager:SetLibrary(Library)

local SaveManagerURL = "https://raw.githubusercontent.com/jixyuk12nh-maker/Ui/refs/heads/main/SaveManager.lua"
local RawCode = game:HttpGet(SaveManagerURL)
local SaveManagerFunc = loadstring(RawCode)

local SaveManager = nil
if SaveManagerFunc then
    SaveManager = SaveManagerFunc()
end

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ReplicatedFirst   = game:GetService("ReplicatedFirst")
local UserInputService  = game:GetService("UserInputService")
local RunService        = game:GetService("RunService")
local SoundService      = game:GetService("SoundService")
local Lighting          = game:GetService("Lighting")
local Debris            = game:GetService("Debris")
local LocalPlayer       = Players.LocalPlayer

local cloneref = cloneref or function(o) return o end
local _identity = getthreadidentity and getthreadidentity() or 8
local function asExploit(fn, ...)
    if setthreadidentity then pcall(setthreadidentity, _identity) end
    local ok, a, b, c = pcall(fn, ...)
    return ok, a, b, c
end
local function asGame(fn, ...)
    if setthreadidentity then pcall(setthreadidentity, 2) end
    local ok, a, b, c = pcall(fn, ...)
    if setthreadidentity then pcall(setthreadidentity, _identity) end
    return ok, a, b, c
end

task.spawn(function()
    if not game:IsLoaded() then game.Loaded:Wait() end
    local player = Players.LocalPlayer
    while not player do
        Players:GetPropertyChangedSignal("LocalPlayer"):Wait()
        player = Players.LocalPlayer
    end
    local playerGui = player:WaitForChild("PlayerGui")
    local coreGui   = game:GetService("CoreGui")
    local function isLoadingGui(o)
        local n = o.Name:lower():gsub("[%s_%-]", "")
        if not n:find("loadingscreen", 1, true) then return false end
        local cur = o
        while cur and cur ~= playerGui and cur ~= coreGui do
            if cur:IsA("LayerCollector") and not cur.Enabled then return false end
            if cur:IsA("GuiObject") and not cur.Visible then return false end
            cur = cur.Parent
        end
        return true
    end
    local clearSince
    repeat
        local loading = false
        for _, root in ipairs({playerGui, coreGui}) do
            for _, o in ipairs(root:GetDescendants()) do
                if isLoadingGui(o) then loading = true break end
            end
            if loading then break end
        end
        clearSince = loading and nil or (clearSince or os.clock())
        task.wait(0.1)
    until clearSince and os.clock() - clearSince >= 0.5
end)

if not getgenv().__MinhoStartupHooks then
    getgenv().__MinhoStartupHooks = true

    if setthreadidentity then pcall(setthreadidentity, 8) end

    local okEnv, renv = pcall(getrenv)
    local realSetmetatable = okEnv and renv and renv.setmetatable
    if hookfunction and realSetmetatable then
        local oldSM = realSetMetatable
        pcall(hookfunction, realSetMetatable, newcclosure(function(T, MT)
            if MT and type(MT) == "table" and rawget(MT, "__mode") then
                local m = rawget(MT, "__mode")
                if m == "kv" or m == "v" or m == "k" then
                    local okT, tr = pcall(debug.traceback)
                    if okT and (tr:find("MiscellaneousController", 1, true)
                        or tr:find("CameraSecurity", 1, true)
                        or tr:find("AnalyticsPipelineController", 1, true)) then
                        return oldSM({1, 2, 3}, {})
                    end
                end
            end
            return oldSM(T, MT)
        end))
    end

    local okPlr, lp = pcall(function()
        return cloneref(game:GetService("Players")).LocalPlayer
    end)
    if okPlr and lp and hookfunction then
        pcall(function()
            local oldKick
            oldKick = hookfunction(lp.Kick, newcclosure(function(self, ...)
                if self == lp then return nil end
                return oldKick(self, ...)
            end))
        end)
        pcall(function()
            local oldGetMouse
            oldGetMouse = hookfunction(lp.GetMouse, newcclosure(function(self, ...)
                if self == lp then
                    local okT, tr = pcall(debug.traceback)
                    if okT and tr:find("MiscellaneousController", 1, true) then
                        local realMouse = oldGetMouse(self, ...)
                        local fake = {}
                        setmetatable(fake, {
                            __index = function(_, key)
                                if key == "X" or key == "Y" then
                                    local loc = UserInputService:GetMouseLocation()
                                    return key == "X" and loc.X or loc.Y
                                end
                                local v = realMouse[key]
                                if type(v) == "function" then
                                    return function(_, ...) return v(realMouse, ...) end
                                end
                                return v
                            end,
                            __newindex = function(_, k, v) realMouse[k] = v end,
                        })
                        return fake
                    end
                end
                return oldGetMouse(self, ...)
            end))
        end)
    end
end

pcall(function()
    local lp = cloneref(game:GetService("Players")).LocalPlayer
    local camSec = require(lp.PlayerScripts.Modules.CameraSecurity)
    local mt = getrawmetatable(camSec)
    mt.__index    = function() return nil end
    mt.__tostring = function() return "LocalPlayer = nil" end
    mt.__newindex = function(E, G, V) return rawset(E, G, V) end
end)

task.spawn(function()
    local ServerPing = workspace:WaitForChild("ServerPing", 30)
    if not ServerPing then return end
    local Remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local PingRemote = Remotes and Remotes:FindFirstChild("Ping")
    while task.wait(12 * math.random()) do
        local rnd = math.random(1, 9999)
        local value = (rnd == 6961) and 2137 or (rnd == ServerPing.Value) and 2138 or rnd
        if PingRemote then
            pcall(function() PingRemote:FireServer(value) end)
        end
    end
end)

for _, svc in pairs({Players, workspace, ReplicatedStorage, ReplicatedFirst}) do
    pcall(function() svc.Name = svc.Name .. " " end)
end

task.spawn(function()
    local Modules = ReplicatedStorage:WaitForChild("Modules", 10)
    if not Modules then return end
    local UtilityMod = Modules:WaitForChild("Utility", 10)
    if not UtilityMod then return end
    local Utility = require(UtilityMod)

    if hookfunction and type(Utility.IsWithinPart) == "function" then
        local oldPart = Utility.IsWithinPart
        Utility.IsWithinPart = newcclosure(function(...)
            if shared.RagebotActive then
                for _, v in ipairs({...}) do
                    if typeof(v) == "Instance" and v:IsA("BasePart") then
                        local n = string.lower(v.Name)
                        if n:find("map") or n:find("bound") or n:find("safe") then
                            return true
                        end
                    end
                end
                return false
            end
            return oldPart(...)
        end)
    end

    if hookfunction and type(Utility.IsWithinTaggedParts) == "function" then
        local oldTagged = Utility.IsWithinTaggedParts
        Utility.IsWithinTaggedParts = newcclosure(function(self, tag, pos, size, returnAll)
            if shared.RagebotActive and type(tag) == "string" then
                local lt = string.lower(tag)
                if lt:find("map") or lt:find("bound") or lt:find("safe") then
                    return returnAll and {workspace.Terrain} or workspace.Terrain
                end
                return returnAll and {} or nil
            end
            return oldTagged(self, tag, pos, size, returnAll)
        end)
    end
end)

local Window = Library:CreateWindow({
    Title = "Minho Hub",
    Footer = "Discord.gg/minho-hub • Minho Hub",
    Size = UDim2.fromOffset(1000, 550),
    ToggleKeybind = Enum.KeyCode.RightControl,
})

local Main      = Window:AddTab("Main")
local World     = Window:AddTab("World")
local Visuals   = Window:AddTab("Visuals")
local Character = Window:AddTab("Character")
local Spoofer   = Window:AddTab("Spoofer")
local Misc      = Window:AddTab("Misc")
local Settings  = Window:AddTab("Settings")

ThemeManager:ApplyToTab(Settings)

local RIVALS_GAMEID = 6035872082
local originalData = {}
local rivalsItems = nil

local GUN_BLACKLIST = {
    ["Molotov"]=true,["Warpstone"]=true,["Smoke Grenade"]=true,
    ["Satchel"]=true,["Flashbang"]=true,["Freeze Ray"]=true,
    ["War Horn"]=true,["Grenade"]=true,["Jump Pad"]=true,
    ["Subspace Tripmine"]=true,["Medkit"]=true,["Grappler"]=true,
    ["RNG Dice"]=true,["MISSING_WEAPON"]=true,
}
local MELEE_WHITELIST = {
    ["Knife"]=true,["Katana"]=true,["Scythe"]=true,["Scepter"]=true,
    ["Maul"]=true,["Battle Axe"]=true,["Chainsaw"]=true,["Spear"]=true,
    ["Fists"]=true,["Trowel"]=true,["Riot Shield"]=true,
}

local function backupOriginals(items)
    for name, data in pairs(items) do
        if typeof(data) == "table" and not originalData[name] then
            originalData[name] = {
                ShootSpread=data.ShootSpread, ShootAccuracy=data.ShootAccuracy,
                ShootRecoil=data.ShootRecoil, ShootCooldown=data.ShootCooldown,
                ShootBurstCooldown=data.ShootBurstCooldown,
                AttackCooldown=data.AttackCooldown, SwingCooldown=data.SwingCooldown,
                MeleeCooldown=data.MeleeCooldown, Cooldown=data.Cooldown,
                RecoveryTime=data.RecoveryTime, ResetTime=data.ResetTime,
            }
        end
    end
end

local function getRivalsItems()
    if game.GameId ~= RIVALS_GAMEID then return nil end
    if rivalsItems then return rivalsItems end
    local ok, result = pcall(function()
        return require(ReplicatedStorage.Modules.ItemLibrary).Items
    end)
    if ok then
        rivalsItems = result
        backupOriginals(rivalsItems)
        return rivalsItems
    end
    warn("Rivals ItemLibrary load failed:", result)
    return nil
end

local function applyFireRate()
    local items = getRivalsItems()
    if not items then return end
    for name, data in pairs(items) do
        if typeof(data) == "table" and not GUN_BLACKLIST[name] then
            if data.ShootSpread  then data.ShootSpread  = 0 end
            if data.ShootAccuracy then data.ShootAccuracy = 0 end
            if data.ShootRecoil  then data.ShootRecoil  = 0 end
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
            if data.AttackCooldown  then data.AttackCooldown  = 0.001 end
            if data.SwingCooldown   then data.SwingCooldown   = 0.001 end
            if data.MeleeCooldown   then data.MeleeCooldown   = 0.001 end
            if data.Cooldown        then data.Cooldown        = 0.001 end
            if data.RecoveryTime    then data.RecoveryTime    = 0.001 end
            if data.ResetTime       then data.ResetTime       = 0.001 end
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

local weaponState = getgenv().__MinhoWeaponState or {
    Enabled=false, Installed=false, NoSpread=false, FullAuto=false,
    FullAutoItems=setmetatable({}, {__mode="k"}),
    OriginalInput=nil, OriginalGunStartShooting=nil,
    ClientItem=nil, GunItem=nil,
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
    return math.clamp(cooldown > 0 and cooldown or (1/60), 1/60, 1)
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
    local ps = LocalPlayer:WaitForChild("PlayerScripts", 10); if not ps then return false end
    local modules = ps:WaitForChild("Modules", 10); if not modules then return false end
    local itemTypes = modules:WaitForChild("ItemTypes", 10); if not itemTypes then return false end

    local ok1, ClientItem = pcall(require,
        modules:WaitForChild("ClientReplicatedClasses", 10)
            :WaitForChild("ClientFighter", 10):WaitForChild("ClientItem", 10))
    local ok2, GunItem = pcall(require, itemTypes:WaitForChild("Gun", 10))
    if not ok1 or not ok2 then warn("[Minho] Weapon hooks failed"); return false end

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

local TELEPORT_CFRAME = CFrame.new(9000, 9000, 9000)
local trackedParts = {}
local ueEnabled = false

local function setUERage(state)
    ueEnabled = state
    shared.RagebotActive = state
    if not state then trackedParts = {} end
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

local undergroundState = getgenv().__MinhoUndergroundState or {
    Active = false,
    Conn = nil,
    NoclipConn = nil,
    GroundY = nil,
    Phase = 0,
}
getgenv().__MinhoUndergroundState = undergroundState

local UNDERGROUND_DEPTH = 6
local UNDERGROUND_MOVE_SPEED = 50
local UNDERGROUND_STRAFE_RANGE = 10.5
local UNDERGROUND_STRAFE_SPEED = 30
local UNDERGROUND_NOCLIP = true

local function getUndergroundRoot()
    local char = LocalPlayer.Character
    return char and char:FindFirstChild("HumanoidRootPart")
end

local function getUndergroundHumanoid()
    local char = LocalPlayer.Character
    return char and char:FindFirstChildOfClass("Humanoid")
end

local function enableUndergroundNoclip()
    if not UNDERGROUND_NOCLIP or undergroundState.NoclipConn then return end
    undergroundState.NoclipConn = RunService.Stepped:Connect(function()
        local char = LocalPlayer.Character
        if not char then return end
        for _, part in char:GetDescendants() do
            if part:IsA("BasePart") then
                part.CanCollide = false
            end
        end
    end)
end

local function disableUndergroundNoclip()
    if undergroundState.NoclipConn then
        undergroundState.NoclipConn:Disconnect()
        undergroundState.NoclipConn = nil
    end
    local char = LocalPlayer.Character
    if char then
        for _, part in char:GetDescendants() do
            if part:IsA("BasePart") then
                part.CanCollide = true
            end
        end
    end
end

local function stopUnderground()
    undergroundState.Active = false
    if undergroundState.Conn then
        undergroundState.Conn:Disconnect()
        undergroundState.Conn = nil
    end
    disableUndergroundNoclip()
    undergroundState.GroundY = nil
    undergroundState.Phase = 0
end

local function startUnderground()
    if undergroundState.Active then return end
    undergroundState.Active = true

    undergroundState.Conn = RunService.Heartbeat:Connect(function(dt)
        if not undergroundState.Active then return end
        local root = getUndergroundRoot()
        local hum = getUndergroundHumanoid()
        if not root or not hum then return end

        if not undergroundState.GroundY then
            undergroundState.GroundY = root.Position.Y - UNDERGROUND_DEPTH
        end

        local moveDir = hum.MoveDirection
        if moveDir.Magnitude > 0.1 then
            local flat = Vector3.new(moveDir.X, 0, moveDir.Z).Unit
            root.AssemblyLinearVelocity = Vector3.new(flat.X * UNDERGROUND_MOVE_SPEED, 0, flat.Z * UNDERGROUND_MOVE_SPEED)
        else
            root.AssemblyLinearVelocity = Vector3.new(0, 0, 0)
        end

        undergroundState.Phase += dt * UNDERGROUND_STRAFE_SPEED
        local cam = workspace.CurrentCamera
        local rightVec = cam and cam.CFrame.RightVector or Vector3.new(1, 0, 0)
        rightVec = Vector3.new(rightVec.X, 0, rightVec.Z).Unit
        local strafeOffset = math.sin(undergroundState.Phase) * UNDERGROUND_STRAFE_RANGE

        local currentPos = root.Position
        local targetX = currentPos.X + rightVec.X * strafeOffset * dt * 10
        local targetZ = currentPos.Z + rightVec.Z * strafeOffset * dt * 10

        root.CFrame = CFrame.new(targetX, undergroundState.GroundY, targetZ) * (root.CFrame - root.CFrame.Position)
        root.AssemblyAngularVelocity = Vector3.zero
    end)

    enableUndergroundNoclip()
end

getgenv().__UndergroundStop = stopUnderground

LocalPlayer.CharacterAdded:Connect(function()
    undergroundState.GroundY = nil
    undergroundState.Phase = 0
    if undergroundState.Active then
        enableUndergroundNoclip()
    end
end)

local fireRateOn = false
local meleeOn    = false

local function reapplyItemData()
    if game.GameId ~= RIVALS_GAMEID then return end
    restoreAllItemData()
    if fireRateOn then applyFireRate() end
    if meleeOn    then applyMeleeSpeed() end
end

local movementState = getgenv().__MinhoMovementState or {
    Mechanics=nil, SlideOriginals={}, ItemOriginals={},
    OldSlide=nil, OldDoubleJump=nil, OldHighJump=nil,
    Hooked=false, HookedMechanics=nil,
    VelocityEnabled=false, VelocitySpeed=50, VelocityConn=nil,
    SlideBoostEnabled=false, SlideBoostValue=1, SlideBoostConn=nil,
    DoubleJumpEnabled=false, DoubleJumpValue=1,
    MaulSlamEnabled=false, MaulSlamValue=1, MaulSlamConn=nil,
    InfiniteDoubleJump=false, InfiniteDJConn=nil,
}
getgenv().__MinhoMovementState = movementState

do
    local mech = movementState.HookedMechanics
    if mech then
        if movementState.OldSlide and type(mech.Slide)=="function" then
            pcall(function() mech.Slide = movementState.OldSlide end)
        end
        if movementState.OldDoubleJump and type(mech.DoubleJump)=="function" then
            pcall(function() mech.DoubleJump = movementState.OldDoubleJump end)
        end
        if movementState.OldHighJump and type(mech.HighJump)=="function" then
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
    local s = hum:GetState()
    if s == Enum.HumanoidStateType.Jumping or s == Enum.HumanoidStateType.Freefall
        or s == Enum.HumanoidStateType.FallingDown or s == Enum.HumanoidStateType.Physics
        or s == Enum.HumanoidStateType.PlatformStanding then return true end
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
        root.AssemblyLinearVelocity = Vector3.new(dir.X*speed, root.AssemblyLinearVelocity.Y, dir.Z*speed)
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

local noclipState = getgenv().__MinhoNoclipState or { Enabled=false, Conn=nil }
getgenv().__MinhoNoclipState = noclipState
if noclipState.Conn then pcall(function() noclipState.Conn:Disconnect() end) noclipState.Conn = nil end

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
    Enabled=false, Gyro=nil, Velocity=nil, Speed=50,
    KeyState={w=0,s=0,a=0,d=0,up=0,down=0},
    InputBeganConn=nil, InputEndedConn=nil, RenderConn=nil,
}
getgenv().__MinhoFlyState = flyState

do
    if flyState.InputBeganConn then pcall(function() flyState.InputBeganConn:Disconnect() end) flyState.InputBeganConn=nil end
    if flyState.InputEndedConn then pcall(function() flyState.InputEndedConn:Disconnect() end) flyState.InputEndedConn=nil end
    if flyState.RenderConn then pcall(function() flyState.RenderConn:Disconnect() end) flyState.RenderConn=nil end
    if flyState.Gyro then pcall(function() flyState.Gyro:Destroy() end) flyState.Gyro=nil end
    if flyState.Velocity then pcall(function() flyState.Velocity:Destroy() end) flyState.Velocity=nil end
end

local function isFlyAlive()
    local char = LocalPlayer.Character
    if not char then return false end
    local hum = char:FindFirstChildOfClass("Humanoid")
    return hum and hum.Health > 0 and char.PrimaryPart
end

local function cleanupFly()
    if flyState.Gyro then flyState.Gyro:Destroy() flyState.Gyro=nil end
    if flyState.Velocity then flyState.Velocity:Destroy() flyState.Velocity=nil end
    if flyState.InputBeganConn then flyState.InputBeganConn:Disconnect() flyState.InputBeganConn=nil end
    if flyState.InputEndedConn then flyState.InputEndedConn:Disconnect() flyState.InputEndedConn=nil end
    if flyState.RenderConn then flyState.RenderConn:Disconnect() flyState.RenderConn=nil end
    if isFlyAlive() then
        local hum = LocalPlayer.Character:FindFirstChildOfClass("Humanoid")
        if hum then hum.PlatformStand = false end
    end
    flyState.KeyState = {w=0,s=0,a=0,d=0,up=0,down=0}
end

local function startFly()
    if flyState.Gyro then flyState.Gyro:Destroy() flyState.Gyro=nil end
    if flyState.Velocity then flyState.Velocity:Destroy() flyState.Velocity=nil end
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

local thirdPersonState = getgenv().__MinhoThirdPersonState or { Enabled=false, Task=nil }
getgenv().__MinhoThirdPersonState = thirdPersonState
if thirdPersonState.Task then pcall(task.cancel, thirdPersonState.Task) thirdPersonState.Task=nil end

local function getCameraController()
    local ok, ctrl = pcall(function()
        return require(LocalPlayer.PlayerScripts.Controllers.CameraController)
    end)
    return ok and ctrl or nil
end

local function stopThirdPerson()
    if thirdPersonState.Task then pcall(task.cancel, thirdPersonState.Task) thirdPersonState.Task=nil end
    local gun = getCameraController()
    if gun and gun.CameraState then
        pcall(function() gun.CameraState:_SetPOVState(gun.CameraState.States.FirstPerson) end)
    end
end

local animState = getgenv().__MinhoAnimState or {
    Enabled=false, CurrentTrack=nil, CurrentAnimation=nil,
    CurrentHumanoid=nil, CurrentAnimator=nil,
    ReplayToken=0, LastReplay=0,
    Selected="Floss", Custom="", Speed=1,
    EmoteAdded=false, HumanoidRef=nil,
}
getgenv().__MinhoAnimState = animState

local animations = {
    ["Bodybuilder"]="3994130516",["Crawling in a Circle"]="116935126100338",
    ["Dolphin Dance"]="5938365243",["Dance"]="507771019",
    ["Dance Break"]="94258912028011",["French Confidence"]="116968182519797",
    ["Floss"]="72174079036035",["Frosty Flair"]="10214406616",
    ["Full Wiggle"]="86520127496722",["Ghost Floating"]="75911227509248",
    ["Gun"]="81100102810594",["Gangnam Style"]="78801539668900",
    ["Hip Bounce"]="123602332785269",["Hype Dance"]="93079641847306",
    ["Kicking Feet"]="109814083870185",["Line Dance"]="4049646104",
    ["Lay Floating"]="126579240140537",["Let's Drive"]="17360720445",
    ["Long Legs"]="82416741608012",["Rock Out"]="18225077553",
    ["Samba"]="6869813008",["Still Standing"]="11435177473",
    ["Spiral"]="81926730031709",["Solar System"]="118314972618293",
    ["Twirl"]="3716633898",["Take Me Under"]="6797938823",
    ["The Worm"]="99563207397301",["Take the L"]="110664723286332",
    ["Zesty"]="102901317133934",
}
local animationList = {
    "Bodybuilder","Custom","Crawling in a Circle","Dolphin Dance","Dance",
    "Dance Break","French Confidence","Floss","Frosty Flair","Full Wiggle",
    "Ghost Floating","Gun","Gangnam Style","Hip Bounce","Hype Dance",
    "Kicking Feet","Line Dance","Lay Floating","Let's Drive","Long Legs",
    "Rock Out","Samba","Still Standing","Spiral","Solar System","Twirl",
    "Take Me Under","The Worm","Take the L","Zesty",
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
        local connection = animator.AnimationPlayed:Connect(function(t) captured = t end)
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

local KILL_SOUNDS = {
    ["Default"]="",
    ["Anime girl laugh"]="rbxassetid://103966419660274",
    ["Mambo umamusume"]="rbxassetid://72270862303024",
    ["sata andagii"]="rbxassetid://111397769122554",
}
local HIT_SOUNDS = {
    ["Default"]="",["Neverlose"]="rbxassetid://6607204501",
    ["Gamesense"]="rbxassetid://4817809188",["Skeet"]="rbxassetid://5447626464",
    ["Rust"]="rbxassetid://5043539486",["Bell"]="rbxassetid://6534947240",
    ["Bubble"]="rbxassetid://6534947588",["Minecraft"]="rbxassetid://4018616850",
    ["Osu"]="rbxassetid://7149255551",["TF2"]="rbxassetid://2868331684",
}
local soundState = getgenv().__MinhoSoundState or {
    HitEnabled=false, HitSelected="Default", HitVolume=0.5, HitPitch=1,
    KillEnabled=false, KillSelected="Default", KillVolume=0.5, KillPitch=1,
}
getgenv().__MinhoSoundState = soundState

local function playCustomSound(soundId, volume, pitch)
    if not soundId or soundId == "" then return end
    local s = Instance.new("Sound")
    s.SoundId = soundId
    s.Volume = math.clamp(volume or 0.5, 0, 10)
    s.PlaybackSpeed = math.clamp(pitch or 1, 0.1, 5)
    s.Parent = SoundService
    s:Play()
    Debris:AddItem(s, 5)
end

local hitSoundState = getgenv().__MinhoHitSoundState or {
    Installed=false, OriginalDamageEffect=nil, Enabled=false,
}
getgenv().__MinhoHitSoundState = hitSoundState

if hitSoundState.Installed and hitSoundState.OriginalDamageEffect then
    pcall(function()
        local ok, ii = pcall(function()
            return require(LocalPlayer.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem.ItemInterface)
        end)
        if ok and type(ii) == "table" then ii.DamageEffect = hitSoundState.OriginalDamageEffect end
    end)
    hitSoundState.Installed = false
end

local function installHitSound()
    if hitSoundState.Installed then return true end
    local ok, ii = pcall(function()
        return require(LocalPlayer.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem.ItemInterface)
    end)
    if not ok or type(ii) ~= "table" or type(ii.DamageEffect) ~= "function" then return false end
    hitSoundState.OriginalDamageEffect = ii.DamageEffect
    ii.DamageEffect = function(self, ...)
        if hitSoundState.Enabled then
            local id = HIT_SOUNDS[soundState.HitSelected] or ""
            if id ~= "" then playCustomSound(id, soundState.HitVolume, soundState.HitPitch) end
        end
        return hitSoundState.OriginalDamageEffect(self, ...)
    end
    hitSoundState.Installed = true
    return true
end

local function uninstallHitSound()
    hitSoundState.Enabled = false
    if hitSoundState.Installed and hitSoundState.OriginalDamageEffect then
        pcall(function()
            local ok, ii = pcall(function()
                return require(LocalPlayer.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem.ItemInterface)
            end)
            if ok and type(ii) == "table" then ii.DamageEffect = hitSoundState.OriginalDamageEffect end
        end)
        hitSoundState.Installed = false
    end
end

local killSoundState = getgenv().__MinhoKillSoundState or {
    LastHitAtByPlayer={}, LastPlayedAt={}, HitWindow=4, Cooldown=0.35,
    Enabled=false, HitTrackerInstalled=false, OriginalDamageEffect=nil,
    PlayerConnections={}, PlayerAddedConn=nil, PlayerRemovingConn=nil,
    HookedPlayers={},
}
getgenv().__MinhoKillSoundState = killSoundState

local function cleanupKillSoundSystem()
    for plr, conns in pairs(killSoundState.PlayerConnections) do
        for _, conn in ipairs(conns) do pcall(function() conn:Disconnect() end) end
        killSoundState.PlayerConnections[plr] = nil
    end
    killSoundState.HookedPlayers = {}
    if killSoundState.PlayerAddedConn then
        pcall(function() killSoundState.PlayerAddedConn:Disconnect() end)
        killSoundState.PlayerAddedConn = nil
    end
    if killSoundState.PlayerRemovingConn then
        pcall(function() killSoundState.PlayerRemovingConn:Disconnect() end)
        killSoundState.PlayerRemovingConn = nil
    end
    if killSoundState.HitTrackerInstalled and killSoundState.OriginalDamageEffect then
        pcall(function()
            local ok, ii = pcall(function()
                return require(LocalPlayer.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem.ItemInterface)
            end)
            if ok and type(ii) == "table" then ii.DamageEffect = killSoundState.OriginalDamageEffect end
        end)
        killSoundState.HitTrackerInstalled = false
    end
    table.clear(killSoundState.LastHitAtByPlayer)
    table.clear(killSoundState.LastPlayedAt)
end

cleanupKillSoundSystem()

local function playKillSound()
    local id = KILL_SOUNDS[soundState.KillSelected] or ""
    if id == "" then return end
    playCustomSound(id, soundState.KillVolume, soundState.KillPitch)
end

local function shouldCreditKill(plr)
    if not plr or plr == LocalPlayer then return false end
    local last = killSoundState.LastHitAtByPlayer[plr]
    return last ~= nil and tick() - last < killSoundState.HitWindow
end

local function tryKillSound(plr, lastHp, newHp)
    if not killSoundState.Enabled then return end
    if (newHp or 0) > 0 then return end
    if (lastHp or 0) <= 0 then return end
    if not shouldCreditKill(plr) then return end
    local now = tick()
    if now - (killSoundState.LastPlayedAt[plr] or 0) < killSoundState.Cooldown then return end
    killSoundState.LastPlayedAt[plr] = now
    playKillSound()
    killSoundState.LastHitAtByPlayer[plr] = nil
end

local function installKillHitTracker()
    if killSoundState.HitTrackerInstalled then return true end
    local ok, ii = pcall(function()
        return require(LocalPlayer.PlayerScripts.Modules.ClientReplicatedClasses.ClientFighter.ClientItem.ItemInterface)
    end)
    if not ok or type(ii) ~= "table" or type(ii.DamageEffect) ~= "function" then return false end
    killSoundState.OriginalDamageEffect = ii.DamageEffect
    ii.DamageEffect = function(self, ...)
        local args = {...}
        for _, v in ipairs(args) do
            if typeof(v) == "Instance" then
                local char = v:FindFirstAncestorOfClass("Model")
                if char then
                    local plr = Players:GetPlayerFromCharacter(char)
                    if plr and plr ~= LocalPlayer then
                        killSoundState.LastHitAtByPlayer[plr] = tick()
                    end
                end
            elseif typeof(v) == "table" then
                for _, inner in pairs(v) do
                    if typeof(inner) == "Instance" then
                        local char = inner:FindFirstAncestorOfClass("Model")
                        if char then
                            local plr = Players:GetPlayerFromCharacter(char)
                            if plr and plr ~= LocalPlayer then
                                killSoundState.LastHitAtByPlayer[plr] = tick()
                            end
                        end
                    end
                end
            end
        end
        return killSoundState.OriginalDamageEffect(self, ...)
    end
    killSoundState.HitTrackerInstalled = true
    return true
end

local function watchPlayerForKill(plr)
    if plr == LocalPlayer then return end
    if killSoundState.HookedPlayers[plr] then return end
    killSoundState.HookedPlayers[plr] = true
    killSoundState.PlayerConnections[plr] = killSoundState.PlayerConnections[plr] or {}

    local function hookCharacter(char)
        local hum = char:WaitForChild("Humanoid", 5)
        if not hum then return end
        local lastHp = hum.Health
        local c1 = hum.HealthChanged:Connect(function(newHp)
            if newHp <= 0 and lastHp > 0 then tryKillSound(plr, lastHp, newHp) end
            lastHp = newHp
        end)
        table.insert(killSoundState.PlayerConnections[plr], c1)
        local c2 = hum.Died:Connect(function() tryKillSound(plr, lastHp, 0) end)
        table.insert(killSoundState.PlayerConnections[plr], c2)
    end

    if plr.Character then hookCharacter(plr.Character) end
    local c = plr.CharacterAdded:Connect(hookCharacter)
    table.insert(killSoundState.PlayerConnections[plr], c)
end

local function installKillSoundSystem()
    cleanupKillSoundSystem()
    killSoundState.Enabled = true
    installKillHitTracker()
    for _, plr in Players:GetPlayers() do watchPlayerForKill(plr) end
    killSoundState.PlayerAddedConn = Players.PlayerAdded:Connect(watchPlayerForKill)
    killSoundState.PlayerRemovingConn = Players.PlayerRemoving:Connect(function(plr)
        if killSoundState.PlayerConnections[plr] then
            for _, conn in ipairs(killSoundState.PlayerConnections[plr]) do
                pcall(function() conn:Disconnect() end)
            end
            killSoundState.PlayerConnections[plr] = nil
        end
        killSoundState.HookedPlayers[plr] = nil
        killSoundState.LastHitAtByPlayer[plr] = nil
        killSoundState.LastPlayedAt[plr] = nil
    end)
end

local function uninstallKillSoundSystem()
    killSoundState.Enabled = false
    cleanupKillSoundSystem()
end

local Rage = Main:AddGroupbox({ Name = "Rage", Side = 1 })

local UERage_Toggle = Rage:AddToggle("UEAssistedRage", {
    Text = "UE Assisted Rage",
    Default = false,
    Callback = function(Value) setUERage(Value) end
})
UERage_Toggle:AddKeyPicker("UERageKey", {
    Text = "UE Rage",
    Default = "R",
    Mode = "Toggle",
    SyncToggleState = true,
})

local Underground_Toggle = Rage:AddToggle("Underground", {
    Text = "Underground",
    Default = false,
    Callback = function(Value)
        if Value then
            startUnderground()
        else
            stopUnderground()
        end
    end
})
Underground_Toggle:AddKeyPicker("UndergroundKey", {
    Text = "Underground",
    Default = "G",
    Mode = "Toggle",
    SyncToggleState = true,
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

local Skybox = World:AddGroupbox({ Name = "Skybox", Side = 1 })
Skybox:AddCheckbox("SkyboxEnabled", {
    Text = "Enabled", Default = false,
    Callback = function(Value) print("Skybox Enabled:", Value) end
})
Skybox:AddDropdown("SkyboxType", {
    Text = "Skybox",
    Values = { "Default", "Galaxy", "Nebula", "Night", "Sunset" },
    Default = "Default", Multi = false,
    Callback = function(Value) print("Skybox:", Value) end
})

local TexturePackBox = World:AddGroupbox({ Name = "Texture Pack", Side = 2 })
TexturePackBox:AddDropdown("TexturePack", {
    Text = "Texture Pack",
    Values = { "Default", "Neon", "Cartoon", "Realistic", "Anime", "Flat" },
    Default = "Default", Multi = false,
    Callback = function(Value) print("Texture Pack:", Value) end
})

local SoundsBox = Visuals:AddGroupbox({ Name = "Sounds", Side = 1 })

SoundsBox:AddCheckbox("HitSoundEnabled", {
    Text = "Hit Sound", Default = false,
    Callback = function(Value)
        soundState.HitEnabled = Value
        hitSoundState.Enabled = Value
        if Value then installHitSound() else uninstallHitSound() end
    end
})

SoundsBox:AddDropdown("HitSoundSelect", {
    Text = "Hit Sound Type",
    Values = { "Default","Neverlose","Gamesense","Skeet","Rust","Bell","Bubble","Minecraft","Osu","TF2" },
    Default = "Default", Multi = false,
    Callback = function(Value) soundState.HitSelected = Value end
})

SoundsBox:AddSlider("HitSoundVolume", {
    Text = "Hit Volume", Default = 0.5, Min = 0, Max = 2, Rounding = 1, Suffix = "dB",
    Callback = function(Value) soundState.HitVolume = Value end
})

SoundsBox:AddSlider("HitSoundPitch", {
    Text = "Hit Pitch", Default = 1, Min = 0.1, Max = 3, Rounding = 1, Suffix = "x",
    Callback = function(Value) soundState.HitPitch = Value end
})

SoundsBox:AddCheckbox("KillSoundEnabled", {
    Text = "Kill Sound", Default = false,
    Callback = function(Value)
        soundState.KillEnabled = Value
        if Value then installKillSoundSystem() else uninstallKillSoundSystem() end
    end
})

SoundsBox:AddDropdown("KillSoundSelect", {
    Text = "Kill Sound Type",
    Values = { "Default","Anime girl laugh","Mambo umamusume","sata andagii" },
    Default = "Default", Multi = false,
    Callback = function(Value) soundState.KillSelected = Value end
})

SoundsBox:AddSlider("KillSoundVolume", {
    Text = "Kill Volume", Default = 0.5, Min = 0, Max = 2, Rounding = 1, Suffix = "dB",
    Callback = function(Value) soundState.KillVolume = Value end
})

SoundsBox:AddSlider("KillSoundPitch", {
    Text = "Kill Pitch", Default = 1, Min = 0.1, Max = 3, Rounding = 1, Suffix = "x",
    Callback = function(Value) soundState.KillPitch = Value end
})

local MovementBox = Character:AddGroupbox({ Name = "Movement", Side = 1 })

MovementBox:AddCheckbox("VelocityEnabled", {
    Text = "Velocity", Default = false,
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
    Text = "Velocity Speed", Default = 50, Min = 0, Max = 250, Rounding = 0,
    Callback = function(Value) movementState.VelocitySpeed = Value end
})

MovementBox:AddCheckbox("SlideBoostEnabled", {
    Text = "Slide Boost", Default = false,
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
    Text = "Slide Boost", Default = 1, Min = 1, Max = 5, Rounding = 1,
    Callback = function(Value) movementState.SlideBoostValue = Value restoreSlideBoost() end
})

MovementBox:AddCheckbox("DoubleJumpEnabled", {
    Text = "Double Jump Height", Default = false,
    Callback = function(Value)
        movementState.DoubleJumpEnabled = Value
        if Value then installMovementHooks() end
    end
})

MovementBox:AddSlider("DoubleJumpValue", {
    Text = "Double Jump Height", Default = 1, Min = 1, Max = 10, Rounding = 1,
    Callback = function(Value) movementState.DoubleJumpValue = Value end
})

MovementBox:AddCheckbox("MaulSlamEnabled", {
    Text = "Maul Slam Multiplier", Default = false,
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
    Text = "Maul Slam Multiplier", Default = 1, Min = 1, Max = 10, Rounding = 1,
    Callback = function(Value) movementState.MaulSlamValue = Value restoreMovementItemInfo() end
})

MovementBox:AddCheckbox("InfiniteDoubleJump", {
    Text = "Infinite Double Jump", Default = false,
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

local Noclip_Toggle = FlyNoclipBox:AddToggle("Noclip", {
    Text = "Noclip", Default = false,
    Callback = function(Value)
        noclipState.Enabled = Value
        if Value then startNoclip() else stopNoclip() end
    end
})
Noclip_Toggle:AddKeyPicker("NoclipKey", {
    Text = "Noclip",
    Default = "V",
    Mode = "Toggle",
    SyncToggleState = true,
})

local Fly_Toggle = FlyNoclipBox:AddToggle("FlyEnabled", {
    Text = "Fly", Default = false,
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
Fly_Toggle:AddKeyPicker("FlyKey", {
    Text = "Fly",
    Default = "F",
    Mode = "Toggle",
    SyncToggleState = true,
})

FlyNoclipBox:AddSlider("FlySpeed", {
    Text = "Fly Speed", Default = 50, Min = 50, Max = 300, Rounding = 0,
    Callback = function(Value) flyState.Speed = Value end
})

FlyNoclipBox:AddCheckbox("ThirdPerson", {
    Text = "Third Person", Default = false,
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

local AnimationBox = Character:AddGroupbox({ Name = "Animation Player", Side = 2 })

AnimationBox:AddCheckbox("AnimationEnabled", {
    Text = "Enabled", Default = false,
    Callback = function(Value)
        animState.Enabled = Value
        if Value then playSelectedAnimation() else stopAnimation() end
    end
})

AnimationBox:AddDropdown("AnimationSelected", {
    Text = "Animation", Values = animationList, Default = "Floss", Multi = false,
    Callback = function(Value)
        animState.Selected = Value
        animState.EmoteAdded = false
        if animState.Enabled then playSelectedAnimation() end
    end
})

AnimationBox:AddInput("AnimationCustom", {
    Text = "Custom Animation ID", Default = "",
    Placeholder = "ex: 4049646104",
    Callback = function(Value)
        animState.Custom = Value
        if animState.Enabled and animState.Selected == "Custom" then
            playSelectedAnimation()
        end
    end
})

AnimationBox:AddSlider("AnimationSpeed", {
    Text = "Speed", Default = 1, Min = 1, Max = 5, Rounding = 1,
    Callback = function(Value)
        animState.Speed = Value
        if animState.CurrentTrack then
            pcall(function() animState.CurrentTrack:AdjustSpeed(Value) end)
        end
    end
})

local SettingsBox = Settings:AddGroupbox({ Name = "Keybinds", Side = 1 })

SettingsBox:AddCheckbox("ShowKeybindsWindow", {
    Text = "키바인드 창 표시",
    Default = true,
    Callback = function(Value)
        if Library.KeybindFrame then
            Library.KeybindFrame.Visible = Value
        end
    end
})

if SaveManager then
    SaveManager:SetLibrary(Library)
    SaveManager:BuildConfigSection(Settings, "folder-cog")
    SaveManager:LoadAutoloadConfig()
else
    warn("SaveManager 로드 실패. Configuration 섹션을 건너뜁니다.")
end

LocalPlayer.AncestryChanged:Connect(function()
    if not LocalPlayer:IsDescendantOf(game) then
        pcall(function() stopNoclip() end)
        pcall(function() cleanupFly() end)
        pcall(function() stopThirdPerson() end)
        pcall(function() stopAnimation() end)
        pcall(function() uninstallKillSoundSystem() end)
        pcall(function() uninstallHitSound() end)
        pcall(function() stopUnderground() end)
    end
end)

return true
