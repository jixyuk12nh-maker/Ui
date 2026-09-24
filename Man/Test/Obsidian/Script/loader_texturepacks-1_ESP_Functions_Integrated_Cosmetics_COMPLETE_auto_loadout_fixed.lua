local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/jixyuk12nh-maker/Ui/refs/heads/main/Minho_Hub_Obsidian_UI.lua"
))()

local ThemeManager = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/jixyuk12nh-maker/Ui/refs/heads/main/ThemeManager.lua"
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

-- Cosmetics backend
-- Imported from Notes_260923_214520.txt
-- ============================================================
local CosmeticsWrap = {}
CosmeticsWrap._cache = {}

function CosmeticsWrap._require(key, fn)
local hit = CosmeticsWrap._cache[key]
if hit ~= nil then return hit ~= false and hit or nil end
local ok, value = pcall(fn)
if ok and value ~= nil then
CosmeticsWrap._cache[key] = value
return value
end
return nil
end

function CosmeticsWrap.dataController()
return CosmeticsWrap._require("PlayerDataController", function()
return require(LocalPlayer.PlayerScripts.Controllers.PlayerDataController)
end)
end

function CosmeticsWrap.fighterController()
return CosmeticsWrap._require("FighterController", function()
return require(LocalPlayer.PlayerScripts.Controllers.FighterController)
end)
end

function CosmeticsWrap.localFighter()
local ctrl = CosmeticsWrap.fighterController()
if ctrl == nil then return nil end
return rawget(ctrl, "LocalFighter")
end

function CosmeticsWrap.playerDataUtility()
return CosmeticsWrap._require("PlayerDataUtility", function()
return require(ReplicatedStorage.Modules.PlayerDataUtility)
end)
end

function CosmeticsWrap.enumLibrary()
return CosmeticsWrap._require("EnumLibrary", function()
return require(ReplicatedStorage.Modules.EnumLibrary)
end)
end

function CosmeticsWrap.clientItem()
return CosmeticsWrap._require("ClientItem", function()
local classes = LocalPlayer.PlayerScripts.Modules.ClientReplicatedClasses
return require(classes.ClientFighter.ClientItem)
end)
end

function CosmeticsWrap.clientViewModel()
return CosmeticsWrap._require("ClientViewModel", function()
local classes = LocalPlayer.PlayerScripts.Modules.ClientReplicatedClasses
return require(classes.ClientFighter.ClientItem.ClientViewModel)
end)
end

function CosmeticsWrap.equipmentModule()
return CosmeticsWrap._require("Equipment", function()
local ui = LocalPlayer.PlayerScripts.Modules.UserInterface
return require(ui.Equipment)
end)
end

function CosmeticsWrap.lobbyModule()
return CosmeticsWrap._require("Lobby", function()
local ui = LocalPlayer.PlayerScripts.Modules.UserInterface
return require(ui.Lobby)
end)
end

function CosmeticsWrap.itemLibrary()
return CosmeticsWrap._require("ItemLibrary", function()
return require(ReplicatedStorage.Modules.ItemLibrary)
end)
end

function CosmeticsWrap.cosmeticLibrary()
return CosmeticsWrap._require("CosmeticLibrary", function()
return require(ReplicatedStorage.Modules.CosmeticLibrary)
end)
end

function CosmeticsWrap.assetsFolder(sub)
local ps = LocalPlayer:FindFirstChild("PlayerScripts")
local assets = ps and ps:FindFirstChild("Assets")
if not assets then return nil end
if sub == nil then return assets end
return assets:FindFirstChild(sub)
end

function CosmeticsWrap.wrapPreviewAsset()
return CosmeticsWrap._require("WrapPreviewAsset", function()
local misc = CosmeticsWrap.assetsFolder("Misc")
if not misc then return nil end
return misc:FindFirstChild("Wrap")
end)
end

function CosmeticsWrap.wrapTextureAssets()
return CosmeticsWrap._require("WrapTextureAssets", function()
return CosmeticsWrap.assetsFolder("WrapTextures")
end)
end

function CosmeticsWrap.charmAssets()
return CosmeticsWrap._require("CharmAssets", function()
return CosmeticsWrap.assetsFolder("Charms")
end)
end

CosmeticsWrap.DataHook = {
spoofs = {},
restore = nil,
conn = nil,
loaded = false,
_signalCache = {},
}

function CosmeticsWrap.DataHook.load(current)
local hook = CosmeticsWrap.DataHook
local inner = rawget(current, "Data")
if inner == nil then return false end
if hook.restore ~= nil then
if hook.restore.current == current then return true end
CosmeticsWrap.DataHook.revert()
end
local proxy = setmetatable({}, {
__index = function(_, key)
local spoof = hook.spoofs[key]
if spoof ~= nil then return spoof(inner[key]) end
return inner[key]
end,
__newindex = function(_, key, value) inner[key] = value end,
__len = function() return #inner end,
__iter = function() return next, inner end,
})
rawset(current, "Data", proxy)
hook.restore = { current = current, inner = inner }
hook._signalCache = {}
return true
end

function CosmeticsWrap.DataHook._revert()
local hook = CosmeticsWrap.DataHook
local restore = hook.restore
if restore == nil then return end
hook.restore = nil
hook._signalCache = {}
rawset(restore.current, "Data", restore.inner)
end

function CosmeticsWrap.DataHook.initialize()
local hook = CosmeticsWrap.DataHook
if hook.loaded then return true end
local controller = CosmeticsWrap.dataController()
if controller == nil then return false end
local added = rawget(controller, "PlayerDataAdded")
if added ~= nil then
local ok, conn = pcall(function()
return added:Connect(function()
local current = rawget(controller, "CurrentData")
if current ~= nil then hook.load(current) end
end)
end)
if ok then hook.conn = conn end
end
hook.loaded = true
local current = rawget(controller, "CurrentData")
if current ~= nil then return hook.load(current) end
return false
end

function CosmeticsWrap.DataHook.set(field, fn)
CosmeticsWrap.DataHook.spoofs[field] = fn
CosmeticsWrap.DataHook.initialize()
end

function CosmeticsWrap.DataHook.unset(field)
CosmeticsWrap.DataHook.spoofs[field] = nil
end

function CosmeticsWrap.DataHook.getOriginal(field)
local restore = CosmeticsWrap.DataHook.restore
if restore == nil then
local controller = CosmeticsWrap.dataController()
local current = controller ~= nil and rawget(controller, "CurrentData") or nil
local data = current ~= nil and rawget(current, "Data") or nil
return data ~= nil and data[field] or nil
end
return restore.inner[field]
end

function CosmeticsWrap.DataHook._signal(current, field)
local cache = CosmeticsWrap.DataHook._signalCache
local hit = cache[field]
if hit ~= nil then return hit ~= false and hit or nil end
local ok, sig = pcall(function() return current:GetDataChangedSignal(field) end)
if ok and sig ~= nil then
cache[field] = sig
return sig
end
cache[field] = false
return nil
end

function CosmeticsWrap.DataHook.trigger(field)
local hook = CosmeticsWrap.DataHook
local current = hook.restore and hook.restore.current
if current == nil then
local controller = CosmeticsWrap.dataController()
current = controller and rawget(controller, "CurrentData") or nil
end
if current == nil then return end
local sig = CosmeticsWrap.DataHook._signal(current, field)
if sig ~= nil then
pcall(function() sig:Fire(current.Data[field], field) end)
end
end

function CosmeticsWrap.DataHook.destroy()
local hook = CosmeticsWrap.DataHook
local fields = {}
for field in pairs(hook.spoofs) do fields[#fields + 1] = field end
table.clear(hook.spoofs)
hook._revert()
if hook.conn ~= nil then
pcall(function() hook.conn:Disconnect() end)
hook.conn = nil
end
hook.loaded = false
for _, field in ipairs(fields) do hook.trigger(field) end
end

CosmeticsWrap.ItemHook = {
ALIAS = "GetWeaponData\0ohaio",
restore = nil,
_targetFn = nil,
}

function CosmeticsWrap.ItemHook.target()
if CosmeticsWrap.ItemHook._targetFn ~= nil then
return CosmeticsWrap.ItemHook._targetFn
end
local controller = CosmeticsWrap.dataController()
if controller == nil then return nil end
local mt = getmetatable(controller)
local index = typeof(mt) == "table" and rawget(mt, "__index") or nil
if typeof(index) ~= "table" then return nil end
local fn = rawget(index, "GetWeaponData")
if typeof(fn) == "function" then
CosmeticsWrap.ItemHook._targetFn = fn
return fn
end
return nil
end

function CosmeticsWrap.ItemHook.findOriginal(weaponName)
local inventory = CosmeticsWrap.DataHook.getOriginal("WeaponInventory")
if typeof(inventory) ~= "table" then return nil end
for _, entry in pairs(inventory) do
if typeof(entry) == "table" and entry.Name == weaponName then return entry end
end
return nil
end

function CosmeticsWrap.ItemHook.applyCosmetics(data, selection)
if selection == nil then return data, false end
if data == nil then data = {} end
local changed = false
for _, kind in ipairs({ "Skin", "Wrap", "Charm", "Finisher" }) do
local slot = string.lower(kind)
local value = selection[slot]
if value ~= nil then
if kind == "Wrap" then
data[kind] = { Name = value.name, Inverted = value.inverted == true }
else
data[kind] = { Name = value }
end
changed = true
end
end
return data, changed
end

function CosmeticsWrap.ItemHook.getWeaponData(_self, controller, weaponName)
local original = CosmeticsWrap.ItemHook.findOriginal(weaponName)
if original == nil then return nil end
local selection = CosmeticsWrap.selections[weaponName]
if selection == nil then return original end
local patched, changed = CosmeticsWrap.ItemHook.applyCosmetics(
table.clone(original), selection)
if not changed then return original end
patched.Level = original.Level
patched.Prestige = original.Prestige
patched.XP = original.XP
return patched
end

function CosmeticsWrap.ItemHook.load()
if CosmeticsWrap.ItemHook.restore ~= nil then return true end
if debug.getconstants == nil or debug.setconstant == nil then
return false, "executor has no constant access"
end
local fn = CosmeticsWrap.ItemHook.target()
if fn == nil then return false, "GetWeaponData function unavailable" end
local utility = CosmeticsWrap.playerDataUtility()
if utility == nil then return false, "PlayerDataUtility unavailable" end
local ok, constants = pcall(debug.getconstants, fn)
if not ok or typeof(constants) ~= "table" then return false, "constants unreadable" end
for index, value in pairs(constants) do
if value == "GetWeaponData" then
CosmeticsWrap.ItemHook.restore = { fn = fn, index = index, original = value, utility = utility }
pcall(debug.setconstant, fn, index, CosmeticsWrap.ItemHook.ALIAS)
break
end
end
if CosmeticsWrap.ItemHook.restore == nil then
return false, "GetWeaponData constant not found"
end
rawset(utility, CosmeticsWrap.ItemHook.ALIAS, CosmeticsWrap.ItemHook.getWeaponData)
return true
end

function CosmeticsWrap.ItemHook.revert()
local restore = CosmeticsWrap.ItemHook.restore
if restore == nil then return end
CosmeticsWrap.ItemHook.restore = nil
pcall(debug.setconstant, restore.fn, restore.index, restore.original)
if restore.utility ~= nil then
rawset(restore.utility, CosmeticsWrap.ItemHook.ALIAS, nil)
end
end

CosmeticsWrap.Scene = {
_equipmentQueued = false,
_selectionQueued = false,
_objectsCache = nil,
_objectsCacheTime = 0,
}

function CosmeticsWrap.Scene.thunk(object, methodName)
if object == nil then return nil end
local mt = getmetatable(object)
local index = typeof(mt) == "table" and rawget(mt, "__index") or nil
local method = typeof(index) == "table" and rawget(index, methodName) or nil
if method == nil then method = rawget(object, methodName) end
if typeof(method) ~= "function" then return nil end
return function() coroutine.wrap(method)(object) end
end

function CosmeticsWrap.Scene.run(thunks)
local co = coroutine.create(function()
if getthreadidentity == nil or setthreadidentity == nil then
for _, thunk in ipairs(thunks) do
if thunk ~= nil then pcall(thunk) end
end
return
end
local identity = getthreadidentity()
local raised = pcall(setthreadidentity, 2)
for _, thunk in ipairs(thunks) do
if thunk ~= nil then pcall(thunk) end
end
if raised then pcall(setthreadidentity, identity) end
end)
local ok, err = coroutine.resume(co)
if not ok then warn("[CosmeticsWrap] scene: " .. tostring(err)) end
end

function CosmeticsWrap.Scene.objects()
local now = os.clock()
if CosmeticsWrap.Scene._objectsCache and now - CosmeticsWrap.Scene._objectsCacheTime < 5 then
return CosmeticsWrap.Scene._objectsCache
end
local out = {}
local equipment = CosmeticsWrap.equipmentModule()
if equipment ~= nil then
local interface = rawget(equipment, "Interface")
if typeof(interface) == "table" then
local customize = rawget(interface, "Customize")
out.cosmetics = typeof(customize) == "table" and rawget(customize, "Cosmetics") or nil
out.left = rawget(interface, "Left")
end
out.floatingModel = rawget(equipment, "FloatingModel")
end
local lobby = CosmeticsWrap.lobbyModule()
if lobby ~= nil then
out.buttons = rawget(lobby, "Buttons")
end
if next(out) == nil then return nil end
CosmeticsWrap.Scene._objectsCache = out
CosmeticsWrap.Scene._objectsCacheTime = now
return out
end

function CosmeticsWrap.Scene.equipment()
if CosmeticsWrap.Scene._equipmentQueued then return end
CosmeticsWrap.Scene._equipmentQueued = true
task.defer(function()
CosmeticsWrap.Scene._equipmentQueued = false
local objects = CosmeticsWrap.Scene.objects()
if objects == nil then return end
CosmeticsWrap.Scene.run({
CosmeticsWrap.Scene.thunk(objects.cosmetics, "_BulkUpdateEquipped"),
CosmeticsWrap.Scene.thunk(objects.buttons, "_UpdateButtonInformation"),
CosmeticsWrap.Scene.thunk(objects.left, "_GenerateDeferred"),
})
end)
end

function CosmeticsWrap.Scene.selection()
if CosmeticsWrap.Scene._selectionQueued then return end
CosmeticsWrap.Scene._selectionQueued = true
task.defer(function()
CosmeticsWrap.Scene._selectionQueued = false
local objects = CosmeticsWrap.Scene.objects()
if objects == nil then return end
CosmeticsWrap.Scene.run({
CosmeticsWrap.Scene.thunk(objects.cosmetics, "OnStateChanged"),
CosmeticsWrap.Scene.thunk(objects.floatingModel, "_GenerateViewModel"),
})
end)
end

function CosmeticsWrap.Scene.encodeKeys(tbl)
local enums = CosmeticsWrap.enumLibrary()
if enums == nil then return tbl end
local out = {}
for key, value in pairs(tbl) do
local ok, encoded = pcall(function() return enums:ToEnum(key) end)
out[(ok and encoded) or key] = value
end
return out
end

function CosmeticsWrap.Scene.buildViewModelData(itemName, selection)
local name = itemName
local skin = selection ~= nil and selection.skin or nil
if skin ~= nil and skin ~= "RANDOM_COSMETIC"
and not string.match(skin, "^NONE_COSMETIC") then
name = skin
end
local record = { Name = name }
local wrap = selection ~= nil and selection.wrap or nil
if wrap ~= nil and wrap.name ~= nil
and not string.match(wrap.name, "^NONE_COSMETIC") then
record.Wrap = { Name = wrap.name, Inverted = wrap.inverted == true }
end
local charm = selection ~= nil and selection.charm or nil
if charm ~= nil and not string.match(charm, "^NONE_COSMETIC") then
record.Charm = { Name = charm }
end
return CosmeticsWrap.Scene.encodeKeys({ Data = CosmeticsWrap.Scene.encodeKeys(record) })
end

function CosmeticsWrap.Scene.reloadViewModel(item, itemName, selection)
if typeof(item) ~= "table" then return false end
local viewModel = rawget(item, "ViewModel")
if viewModel == nil then return false end
if rawget(viewModel, "Data") == nil then return false end

local clientItem = CosmeticsWrap.clientItem()
local clientViewModel = CosmeticsWrap.clientViewModel()
if clientItem == nil or clientViewModel == nil then return false end

local source = CosmeticsWrap.Scene.buildViewModelData(itemName, selection)

local created
CosmeticsWrap.Scene.run({ function()
pcall(function() coroutine.wrap(clientViewModel.Destroy)(viewModel) end)
pcall(function()
created = coroutine.wrap(clientItem._CreateViewModel)(item, source)
end)
if created == nil then
pcall(function()
created = coroutine.wrap(clientItem._CreateViewModel)(item,
CosmeticsWrap.Scene.buildViewModelData(itemName, nil))
end)
if created ~= nil then rawset(item, "ViewModel", created) end
return
end
rawset(item, "ViewModel", created)
local fighter = rawget(item, "ClientFighter") or CosmeticsWrap.localFighter()
if fighter ~= nil then
local mt = getmetatable(fighter)
local index = typeof(mt) == "table" and rawget(mt, "__index") or nil
local getArms = typeof(index) == "table" and rawget(index, "GetArmsData") or nil
if getArms ~= nil then
local arms = table.pack(coroutine.wrap(getArms)(fighter))
pcall(function()
coroutine.wrap(clientViewModel.SetArmsData)(created, table.unpack(arms, 1, arms.n))
end)
end
end
pcall(function() coroutine.wrap(clientViewModel.Equip)(created, true) end)
local spring = rawget(created, "_equip_spring")
if spring ~= nil then
rawset(spring, "_position0", 0)
rawset(spring, "_velocity0", 0)
end
end })
return true
end

function CosmeticsWrap.Scene.reloadAll(itemName, selection)
local fighter = CosmeticsWrap.localFighter()
if fighter == nil then return false end
local items = rawget(fighter, "Items")
if typeof(items) ~= "table" then return false end
local any = false
for _, item in pairs(items) do
if typeof(item) == "table" and rawget(item, "Name") == itemName then
if CosmeticsWrap.Scene.reloadViewModel(item, itemName, selection) then any = true end
end
end
return any
end

function CosmeticsWrap.Scene.reloadEquipped()
local fighter = CosmeticsWrap.localFighter()
if fighter == nil then return end
local items = rawget(fighter, "Items")
if typeof(items) ~= "table" then return end
for _, item in pairs(items) do
if typeof(item) == "table" and rawget(item, "IsEquipped") == true then
local itemName = rawget(item, "Name")
if itemName ~= nil then
local selection = CosmeticsWrap.selections[itemName]
CosmeticsWrap.Scene.reloadViewModel(item, itemName, selection)
end
end
end
end

function CosmeticsWrap.Scene.refreshEquipmentView()
    local objects = CosmeticsWrap.Scene.objects()
    if objects == nil then return end

    CosmeticsWrap.Scene.run({
        CosmeticsWrap.Scene.thunk(objects.cosmetics, "_BulkUpdateEquipped"),
        CosmeticsWrap.Scene.thunk(objects.cosmetics, "OnStateChanged"),
        CosmeticsWrap.Scene.thunk(objects.cosmetics, "_UpdateSelectorGrid"),
        CosmeticsWrap.Scene.thunk(objects.buttons,   "_UpdateButtonInformation"),
        CosmeticsWrap.Scene.thunk(objects.buttons,   "_GenerateDeferred"),
        CosmeticsWrap.Scene.thunk(objects.left,      "_GenerateDeferred"),
        CosmeticsWrap.Scene.thunk(objects.left,      "_GenerateWeaponButtons"),
        CosmeticsWrap.Scene.thunk(objects.floatingModel, "_GenerateViewModel"),
    })
end

CosmeticsWrap.Scene._refreshQueued = false
function CosmeticsWrap.Scene.requestRefresh()
    if CosmeticsWrap.Scene._refreshQueued then return end
    CosmeticsWrap.Scene._refreshQueued = true
    task.defer(function()
        CosmeticsWrap.Scene._refreshQueued = false
        CosmeticsWrap.Scene.refreshEquipmentView()
    end)
end

function CosmeticsWrap.Scene.installViewModelProvider()
    if CosmeticsWrap.Scene._providerInstalled then return end
    CosmeticsWrap.Scene._providerInstalled = true

    local clientItem = CosmeticsWrap.clientItem()
    if clientItem == nil or type(clientItem._CreateViewModel) ~= "function" then
        CosmeticsWrap.Scene._providerInstalled = false
        return
    end

    local originalCreate = clientItem._CreateViewModel
    CosmeticsWrap.Scene._originalCreate = originalCreate

    local function wrappedCreate(self, vmref)
        local fighter = rawget(self, "ClientFighter")
        local owner = fighter and rawget(fighter, "Player")
        local itemName = rawget(self, "Name")

        if owner == LocalPlayer and itemName ~= nil then
            local selection = CosmeticsWrap.selections[itemName]
            if selection ~= nil then
                local patched = CosmeticsWrap.Scene.buildViewModelData(itemName, selection)
                local enumLib = CosmeticsWrap.enumLibrary()
                if enumLib ~= nil then
                    local dataKey = enumLib:ToEnum("Data")
                    vmref[dataKey] = patched[dataKey]
                    vmref.Data = nil
                else
                    vmref.Data = patched.Data
                end
            end
        end
        return originalCreate(self, vmref)
    end

    if newcclosure then
        local ok, wrapped = pcall(newcclosure, wrappedCreate)
        if ok and wrapped then wrappedCreate = wrapped end
    end

    clientItem._CreateViewModel = wrappedCreate
end

function CosmeticsWrap.Scene.uninstallViewModelProvider()
    if not CosmeticsWrap.Scene._providerInstalled then return end
    local clientItem = CosmeticsWrap.clientItem()
    if clientItem ~= nil and CosmeticsWrap.Scene._originalCreate ~= nil then
        clientItem._CreateViewModel = CosmeticsWrap.Scene._originalCreate
    end
    CosmeticsWrap.Scene._originalCreate = nil
    CosmeticsWrap.Scene._providerInstalled = false
end

function CosmeticsWrap.Scene.installIconProvider()
    if CosmeticsWrap.Scene._iconInstalled then return end
    local ilib = CosmeticsWrap.itemLibrary()
    if ilib == nil or type(ilib.GetViewModelImageFromWeaponData) ~= "function" then
        return
    end
    CosmeticsWrap.Scene._iconInstalled = true
    local original = ilib.GetViewModelImageFromWeaponData
    CosmeticsWrap.Scene._originalIcon = original

    local function wrappedIcon(self, weaponData, hires)
        if type(weaponData) == "table" then
            local weaponName = weaponData.Name
            local selection = weaponName and CosmeticsWrap.selections[weaponName]
            local skin = selection and selection.skin
            if skin ~= nil and skin ~= "RANDOM_COSMETIC"
                and not string.match(skin, "^NONE_COSMETIC") then
                local viewModels = self.ViewModels
                local info = viewModels and viewModels[skin]
                if info ~= nil then
                    if hires then
                        return info.ImageHighResolution or info.Image or ""
                    end
                    return info.Image or ""
                end
            end
        end
        return original(self, weaponData, hires)
    end

    if newcclosure then
        local ok, wrapped = pcall(newcclosure, wrappedIcon)
        if ok and wrapped then wrappedIcon = wrapped end
    end

    ilib.GetViewModelImageFromWeaponData = wrappedIcon
end

function CosmeticsWrap.Scene.uninstallIconProvider()
    if not CosmeticsWrap.Scene._iconInstalled then return end
    local ilib = CosmeticsWrap.itemLibrary()
    if ilib ~= nil and CosmeticsWrap.Scene._originalIcon ~= nil then
        ilib.GetViewModelImageFromWeaponData = CosmeticsWrap.Scene._originalIcon
    end
    CosmeticsWrap.Scene._originalIcon = nil
    CosmeticsWrap.Scene._iconInstalled = false
end

CosmeticsWrap.selections = {}
CosmeticsWrap._enabled = false

function CosmeticsWrap.enable()
    if CosmeticsWrap._enabled then
        return true
    end

    CosmeticsWrap.DataHook.initialize()
    CosmeticsWrap.Scene.installViewModelProvider()
    CosmeticsWrap.Scene.installIconProvider()

    local ok, err = CosmeticsWrap.ItemHook.load()
    if not ok then
        warn("[CosmeticsWrap] ItemHook load failed: " .. tostring(err))
        return false
    end

    CosmeticsWrap._enabled = true
    return true
end

function CosmeticsWrap.disable()
    if not CosmeticsWrap._enabled then
        return true
    end

    CosmeticsWrap.Scene.uninstallIconProvider()
    CosmeticsWrap.Scene.uninstallViewModelProvider()
    CosmeticsWrap.ItemHook.revert()
    CosmeticsWrap.DataHook.destroy()
    CosmeticsWrap._enabled = false
    return true
end

CosmeticsWrap._reloadQueued = false

function CosmeticsWrap._queueReload(weaponName, selection)
if CosmeticsWrap._reloadQueued then return end
CosmeticsWrap._reloadQueued = true
task.defer(function()
CosmeticsWrap._reloadQueued = false
CosmeticsWrap.Scene.reloadAll(weaponName, selection)
CosmeticsWrap.Scene.reloadEquipped()
end)
end

function CosmeticsWrap.set(weaponName, selection)
    CosmeticsWrap.selections[weaponName] = selection
    CosmeticsWrap.DataHook.trigger("WeaponInventory")
    CosmeticsWrap.DataHook.trigger("CosmeticInventory")
    CosmeticsWrap._queueReload(weaponName, selection)
    CosmeticsWrap.Scene.requestRefresh()

    task.defer(function()
        CosmeticsWrap.Scene.reloadAll(weaponName, selection)
        CosmeticsWrap.Scene.requestRefresh()
    end)
    task.delay(0.5, function()
        CosmeticsWrap.Scene.reloadAll(weaponName, selection)
        CosmeticsWrap.Scene.requestRefresh()
    end)
end

function CosmeticsWrap.clear(weaponName)
    CosmeticsWrap.selections[weaponName] = nil
    CosmeticsWrap.DataHook.trigger("WeaponInventory")
    CosmeticsWrap.DataHook.trigger("CosmeticInventory")
    CosmeticsWrap._queueReload(weaponName, nil)
    CosmeticsWrap.Scene.requestRefresh()
end

function CosmeticsWrap.applyAll()
for weaponName, selection in pairs(CosmeticsWrap.selections) do
CosmeticsWrap.Scene.reloadAll(weaponName, selection)
end
CosmeticsWrap.Scene.reloadEquipped()
end

_G.CosmeticsWrap = CosmeticsWrap

CosmeticsWrap.enable()

if LocalPlayer.CharacterAdded then
LocalPlayer.CharacterAdded:Connect(function()
task.wait(1.5)
CosmeticsWrap.applyAll()
end)
end

local lastEquipped = nil
task.spawn(function()
while task.wait(1) do
local fighter = CosmeticsWrap.localFighter()
if fighter then
local item = rawget(fighter, "EquippedItem")
if item then
local itemName = rawget(item, "Name")
if itemName ~= lastEquipped then
lastEquipped = itemName
local selection = CosmeticsWrap.selections[itemName]
if selection then
CosmeticsWrap.Scene.reloadViewModel(item, itemName, selection)
end
end
end
end
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
local Cosmetics = Window:AddTab("Cosmetics")
local Misc      = Window:AddTab("Misc")
local Settings  = Window:AddTab("Settings")

ThemeManager:ApplyToTab(Settings)

-- Misc / Auto Loadout
-- ============================================================
local AutoLoadoutBox = Misc:AddGroupbox({ Name = "Auto Loadout", Side = 1 })

local function weaponSelectorField(obj, key)
    if obj == nil then return nil end
    local ok, value = pcall(function() return obj[key] end)
    return ok and value or nil
end

local function weaponSelectorGetLibrary()
    local modules = ReplicatedStorage:FindFirstChild("Modules")
    local itemModule = modules and modules:FindFirstChild("ItemLibrary")
    if not itemModule then return nil end

    local ok, Items = pcall(require, itemModule)
    if not ok or type(Items) ~= "table" then return nil end
    return Items
end

local LOADOUT_CLASSES = {
    { key = "Primary",   text = "Primary" },
    { key = "Secondary", text = "Secondary" },
    { key = "Melee",     text = "Melee" },
    { key = "Utility",   text = "Utility" },
}

local function weaponSelectorGetList(className)
    local weapons = {}
    local Items = weaponSelectorGetLibrary()
    if not Items or type(Items.Items) ~= "table" then return weapons end

    for name, data in pairs(Items.Items) do
        if type(name) == "string" and type(data) == "table" and data.Class == className then
            table.insert(weapons, name)
        end
    end

    table.sort(weapons)
    return weapons
end

local function weaponSelectorGetInfo(weaponName)
    local Items = weaponSelectorGetLibrary()
    return Items and Items.Items and Items.Items[weaponName] or nil
end

local function weaponSelectorGetFighterController()
    local ok, controller = pcall(function()
        return require(LocalPlayer.PlayerScripts.Controllers.FighterController)
    end)
    return ok and controller or nil
end

local function weaponSelectorGetFighter()
    local controller = weaponSelectorGetFighterController()
    return controller and weaponSelectorField(controller, "LocalFighter") or nil
end

local function weaponSelectorGetItems()
    local fighter = weaponSelectorGetFighter()
    if not fighter then return nil end

    local items = weaponSelectorField(fighter, "Items")
    return type(items) == "table" and items or nil
end

local function weaponSelectorEquipOwned(weaponName)
    local items = weaponSelectorGetItems()
    if not items then return false, "Fighter unavailable" end

    for slot, item in pairs(items) do
        if weaponSelectorField(item, "Name") == weaponName then
            local fighter = weaponSelectorGetFighter()
            local data = weaponSelectorField(item, "Data")
            local index = weaponSelectorField(data, "ItemIndex") or slot

            if fighter and index ~= nil then
                local ok = pcall(function()
                    fighter:EquipItem(index)
                end)
                if ok then return true, "Equipped" end
            end

            local ok = pcall(function()
                item:Equip()
            end)
            if ok then return true, "Equipped" end
        end
    end

    return false, "Not in inventory"
end

local function weaponSelectorSwitchSlot(weaponName)
    local remotes = ReplicatedStorage:FindFirstChild("Remotes")
    local duels = remotes and remotes:FindFirstChild("Duels")
    local switchRemote = duels and duels:FindFirstChild("SwitchItems")
    if not switchRemote then return false, "SwitchItems remote unavailable" end

    local info = weaponSelectorGetInfo(weaponName)
    if not info then return false, "Weapon info unavailable" end

    -- The supplied source defines server slot mapping for Primary/Secondary/Melee.
    -- Utility is selectable here, but is not assigned an invented server slot.
    local slot
    if info.Class == "Primary" then
        slot = 1
    elseif info.Class == "Secondary" then
        slot = 2
    elseif info.Class == "Melee" then
        slot = 3
    elseif info.Class == "Utility" then
        return false, "Utility slot mapping is not provided by the source"
    end

    if not slot then return false, "Unsupported weapon class" end

    local ok, err = pcall(function()
        switchRemote:FireServer(slot, weaponName)
    end)

    if ok then
        return true, "Slot " .. tostring(slot) .. " requested"
    end

    return false, tostring(err)
end

local AutoLoadoutEnabled = false
local AutoLoadoutSelections = {
    Primary = nil,
    Secondary = nil,
    Melee = nil,
    Utility = nil,
}

local AutoLoadoutDropdowns = {}
local AutoLoadoutRefreshQueued = false

local function autoLoadoutApplyWeapon(weaponName)
    if not AutoLoadoutEnabled or not weaponName then return end

    local ok = weaponSelectorEquipOwned(weaponName)
    if not ok then
        weaponSelectorSwitchSlot(weaponName)
    end
end

local function autoLoadoutApplyAll()
    if not AutoLoadoutEnabled then return end

    for _, category in ipairs(LOADOUT_CLASSES) do
        local weaponName = AutoLoadoutSelections[category.key]
        if weaponName then
            autoLoadoutApplyWeapon(weaponName)
        end
    end
end

AutoLoadoutBox:AddCheckbox("AutoLoadoutEnabled", {
    Text = "Enabled",
    Default = false,
    Callback = function(value)
        AutoLoadoutEnabled = value == true
        if AutoLoadoutEnabled then
            autoLoadoutApplyAll()
        end
    end,
})

local function createAutoLoadoutDropdown(category)
    local values = weaponSelectorGetList(category.key)
    local defaultValue = values[1]
    AutoLoadoutSelections[category.key] = defaultValue

    AutoLoadoutDropdowns[category.key] = AutoLoadoutBox:AddDropdown(
        "AutoLoadout_" .. category.key,
        {
            Text = category.text,
            Values = values,
            Default = defaultValue,
            Multi = false,
            Searchable = true,
            Callback = function(value)
                AutoLoadoutSelections[category.key] = value
                if AutoLoadoutEnabled and value then
                    autoLoadoutApplyWeapon(value)
                end
            end,
        }
    )
end

for _, category in ipairs(LOADOUT_CLASSES) do
    createAutoLoadoutDropdown(category)
end

local function refreshAutoLoadoutDropdowns()
    if AutoLoadoutRefreshQueued then return end
    AutoLoadoutRefreshQueued = true

    task.defer(function()
        AutoLoadoutRefreshQueued = false

        for _, category in ipairs(LOADOUT_CLASSES) do
            local dropdown = AutoLoadoutDropdowns[category.key]
            if dropdown then
                local values = weaponSelectorGetList(category.key)
                local selected = AutoLoadoutSelections[category.key]
                local hasSelected = selected and table.find(values, selected) ~= nil
                local nextValue = hasSelected and selected or values[1]
                AutoLoadoutSelections[category.key] = nextValue
                pcall(function()
                    dropdown:SetValues(values)
                    if nextValue then
                        dropdown:SetValue(nextValue)
                    end
                end)
            end
        end
    end)
end

LocalPlayer.CharacterAdded:Connect(function()
    task.delay(1, function()
        refreshAutoLoadoutDropdowns()
        if AutoLoadoutEnabled then
            task.delay(0.5, autoLoadoutApplyAll)
        end
    end)
end)

task.spawn(function()
    while task.wait(2) do
        refreshAutoLoadoutDropdowns()
    end
end)

-- Cosmetics UI
-- ============================================================
local Group = Cosmetics:AddGroupbox({ Name = "Rivals Cosmetics", Side = 1 })

--// None = 기본 스킨 (아무것도 안 낀 상태) \--
local NONE_LABEL = "None"

local function collectData()
local byClass = {}
local modules = ReplicatedStorage:FindFirstChild("Modules")
local itemModule = modules and modules:FindFirstChild("ItemLibrary")
local cosModule = modules and modules:FindFirstChild("CosmeticLibrary")
if not itemModule or not cosModule then return byClass end

local okI, itemLib = pcall(require, itemModule)
local okC, cosLib = pcall(require, cosModule)
if not okI or not okC then return byClass end

local weaponClass = {}
for name, data in pairs(itemLib.Items or {}) do
if type(data) == "table" and data.Class then
weaponClass[name] = data.Class
end
end

local function extractVisual(data, name)
if type(data) ~= "table" then return nil end
local image = data.Image
if type(image) == "string" and image ~= "" then
return { kind = "image", value = image }
end
if type(data.ImageHighResolution) == "string" and data.ImageHighResolution ~= "" then
return { kind = "image", value = data.ImageHighResolution }
end
if data.Type == "Wrap" then
return { kind = "wrap3d", value = name }
end
if data.Type == "Charm" then
return { kind = "charm3d", charmName = name }
end
return { kind = "named", value = name }
end

local function addEntry(kind, name, visual, weapon)
if not visual then return end
local targetWeapon = (kind == "Skin") and weapon or "All"
if not targetWeapon then return end
local class = (kind == "Skin")
and (weaponClass[targetWeapon] or "Other")
or "All"
byClass[class] = byClass[class] or {}
byClass[class][targetWeapon] = byClass[class][targetWeapon] or {}
byClass[class][targetWeapon][kind] = byClass[class][targetWeapon][kind] or {}
table.insert(byClass[class][targetWeapon][kind], {
name = name, visual = visual, kind = kind,
})
end

for name, data in pairs(cosLib.Cosmetics or {}) do
if type(data) == "table" and data.Type and data.Type ~= "Reward"
and data.Type ~= "Emote" then
local visual = extractVisual(data, name)
if visual then addEntry(data.Type, name, visual, data.ItemName) end
end
end

for _, weaponMap in pairs(byClass) do
for _, kindMap in pairs(weaponMap) do
for _, list in pairs(kindMap) do
table.sort(list, function(a, b) return a.name < b.name end)
end
end
end

return byClass
end

local function toAsset(id)
if type(id) == "number" then return "rbxassetid://" .. id
elseif type(id) == "string" then
if id:match("^rbxassetid://") or id:match("^rbxasset://") then return id
elseif id:match("^%d+$") then return "rbxassetid://" .. id
end
return id
end
return nil
end

local byClass = collectData()

local CLASS_ORDER = { "Primary", "Secondary", "Melee", "Utility" }
local classNames = {}
for class in pairs(byClass) do
if class ~= "All" then table.insert(classNames, class) end
end
table.sort(classNames, function(a, b)
local ai = table.find(CLASS_ORDER, a) or 999
local bi = table.find(CLASS_ORDER, b) or 999
if ai ~= bi then return ai < bi end
return a < b
end)

if #classNames == 0 then
Group:AddLabel("No cosmetic data found.")
else

-- Emote 제외
local KINDS = { "Skin", "Wrap", "Charm", "Finisher" }

local function weaponsOfClass(class)
local names = {}
if byClass[class] then
for weapon in pairs(byClass[class]) do table.insert(names, weapon) end
end
table.sort(names)
return names
end

local function kindsOfWeapon(class, weapon)
local kinds = {}
if byClass[class] and byClass[class][weapon] then
for kind in pairs(byClass[class][weapon]) do kinds[kind] = true end
end
if byClass["All"] and byClass["All"]["All"] then
for kind in pairs(byClass["All"]["All"]) do kinds[kind] = true end
end
local out = {}
for kind in pairs(kinds) do table.insert(out, kind) end
table.sort(out, function(a, b)
local ai = table.find(KINDS, a) or 999
local bi = table.find(KINDS, b) or 999
return ai < bi
end)
return out
end

local function cosmeticsOf(class, weapon, kind)
local names = { NONE_LABEL }
if byClass[class] and byClass[class][weapon] and byClass[class][weapon][kind] then
for _, entry in ipairs(byClass[class][weapon][kind]) do
table.insert(names, entry.name)
end
end
if byClass["All"] and byClass["All"]["All"] and byClass["All"]["All"][kind] then
for _, entry in ipairs(byClass["All"]["All"][kind]) do
table.insert(names, entry.name)
end
end
return names
end

local function entryByName(class, weapon, kind, name)
if name == NONE_LABEL then return nil end
if byClass[class] and byClass[class][weapon] and byClass[class][weapon][kind] then
for _, entry in ipairs(byClass[class][weapon][kind]) do
if entry.name == name then return entry end
end
end
if byClass["All"] and byClass["All"]["All"] and byClass["All"]["All"][kind] then
for _, entry in ipairs(byClass["All"]["All"][kind]) do
if entry.name == name then return entry end
end
end
return nil
end

local function weaponImageOf(class, weapon)
if not byClass[class] or not byClass[class][weapon] then return nil end
local skinList = byClass[class][weapon]["Skin"]
if not skinList or #skinList == 0 then return nil end
local first = skinList[1]
if first.visual and first.visual.kind == "image" then
return first.visual.value
end
return nil
end

local ClassDropdown, WeaponDropdown, KindDropdown, CosmeticDropdown
local ViewerImage, InfoLabel
local updateVisual

local function showImage(asset)
if not ViewerImage then return end
ViewerImage:SetImage(asset or "rbxassetid://0")
end

local function setViewerImageVisible(on)
if not ViewerImage then return end
if ViewerImage.SetVisible then
ViewerImage:SetVisible(on)
elseif ViewerImage.Holder then
ViewerImage.Holder.Visible = on
elseif ViewerImage.ImageLabel then
ViewerImage.ImageLabel.Visible = on
end
end

ViewerImage = Group:AddImage("ViewerImage", {
Image = "rbxassetid://0",
Height = 220,
ScaleType = Enum.ScaleType.Fit,
Color = Color3.new(1, 1, 1),
})

local CharmViewport = Instance.new("ViewportFrame")
CharmViewport.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
CharmViewport.BorderSizePixel = 0
CharmViewport.Size = UDim2.new(1, 0, 0, 220)
CharmViewport.Visible = false
CharmViewport.Active = false
CharmViewport.Parent = Group.Container

local charmCorner = Instance.new("UICorner")
charmCorner.CornerRadius = UDim.new(0, 6)
charmCorner.Parent = CharmViewport

local charmWorld = Instance.new("WorldModel")
charmWorld.Parent = CharmViewport

local charmCamera = Instance.new("Camera")
charmCamera.FieldOfView = 40
charmCamera.Parent = CharmViewport
CharmViewport.CurrentCamera = charmCamera

charmCamera.CFrame = CFrame.new(0, 0, 2.4)

local charmModel = nil
local charmSpin = 0
local charmAutoRotate = true
local charmRotateSpeed = 0.02

local function loadCharmModel(name)
local charmAssets = CosmeticsWrap.charmAssets()
if not charmAssets then return nil end
local source = charmAssets:FindFirstChild(name)
if not source then
for _, child in ipairs(charmAssets:GetChildren()) do
if string.find(string.lower(child.Name), string.lower(name), 1, true) then
source = child
break
end
end
end
if not source then return nil end

local clone = source:Clone()
local hook = clone:FindFirstChild("Hook", true)
if hook then hook:Destroy() end

local cf, size = clone:GetBoundingBox()
local maxDim = math.max(size.X, size.Y, size.Z, 0.001)
local scale = (1 / maxDim) * 1.6
local ok = pcall(function() clone:ScaleTo(scale) end)
if not ok then
for _, part in ipairs(clone:GetDescendants()) do
if part:IsA("BasePart") then
part.Size = part.Size * scale
end
end
end

local newCf = clone:GetBoundingBox()
clone:PivotTo(CFrame.new(-newCf.Position))
return clone
end

task.spawn(function()
while task.wait() do
if CharmViewport.Visible and charmModel and charmAutoRotate then
charmSpin = charmSpin + charmRotateSpeed
charmModel:PivotTo(CFrame.Angles(0, charmSpin, 0))
end
end
end)

local WrapViewport = Instance.new("ViewportFrame")
WrapViewport.BackgroundColor3 = Color3.fromRGB(20, 20, 25)
WrapViewport.BorderSizePixel = 0
WrapViewport.Size = UDim2.new(1, 0, 0, 220)
WrapViewport.Visible = false
WrapViewport.Active = false
WrapViewport.Parent = Group.Container

local wrapVpCorner = Instance.new("UICorner")
wrapVpCorner.CornerRadius = UDim.new(0, 6)
wrapVpCorner.Parent = WrapViewport

local wrapVpWorld = Instance.new("WorldModel")
wrapVpWorld.Parent = WrapViewport

local wrapVpCamera = Instance.new("Camera")
wrapVpCamera.FieldOfView = 40
wrapVpCamera.Parent = WrapViewport
WrapViewport.CurrentCamera = wrapVpCamera

wrapVpCamera.CFrame = CFrame.new(0, 0, 2.4)

local wrapModel = nil
local wrapSpin = 0
local wrapAutoRotate = true
local wrapRotateSpeed = 0.02

local function applyWrapGroups(model, groups)
if not model or not groups then return end
local wrapTextureAssets = CosmeticsWrap.wrapTextureAssets()
for _, obj in ipairs(model:GetDescendants()) do
if obj:IsA("BasePart") then
local wrapGroup = obj:GetAttribute("WrapGroup")
local group = groups[wrapGroup] or groups[1] or {}
if typeof(group.Color) == "Color3" then obj.Color = group.Color end
if group.Transparency ~= nil then obj.Transparency = group.Transparency end
if group.Reflectance ~= nil then obj.Reflectance = group.Reflectance end
if group.Material then obj.Material = group.Material end
pcall(function()
obj.MaterialVariant = group.MaterialVariant or ""
end)
if obj:IsA("MeshPart") then
pcall(function()
obj.TextureID = ""
end)
end
if group.Textures and wrapTextureAssets then
local folder = wrapTextureAssets:FindFirstChild(group.Textures)
if folder then
for _, texture in ipairs(folder:GetChildren()) do
pcall(function()
local clonedTexture = texture:Clone()
if clonedTexture.LocalTransparencyModifier ~= nil then
clonedTexture.LocalTransparencyModifier = obj.LocalTransparencyModifier
end
clonedTexture.Parent = obj
end)
end
end
end
end
end
end

local function makeFallbackWrap(groups)
local model = Instance.new("Model")
model.Name = "WrapPreview"
local sliceCount = math.max(1, math.min(3, #groups))
for i = 1, sliceCount do
local group = groups[i]
local color = group and group.Color or Color3.fromRGB(150, 150, 150)
if typeof(color) ~= "Color3" then color = Color3.fromRGB(150, 150, 150) end
local slice = Instance.new("Part")
slice.Anchored = true
slice.CanCollide = false
slice.Material = (group and group.Material) or Enum.Material.SmoothPlastic
slice.Color = color
slice.Transparency = group and group.Transparency or 0
slice.Reflectance = group and group.Reflectance or 0
slice.Size = Vector3.new(1.8 / sliceCount, 1.55, 0.22)
slice.CFrame = CFrame.new((i - (sliceCount + 1) / 2) * (1.8 / sliceCount), 0, 0)
slice.Parent = model
end
return model
end

local function loadWrapModel(name)
local cosLib = CosmeticsWrap.cosmeticLibrary()
if not cosLib then return nil end
local data = cosLib.Cosmetics and cosLib.Cosmetics[name]
if not data then return nil end
local groups = data.WrapGroups
if not groups then return nil end

local model = nil
local wrapPreviewAsset = CosmeticsWrap.wrapPreviewAsset()
if wrapPreviewAsset then
local ok, cloned = pcall(function() return wrapPreviewAsset:Clone() end)
if ok and cloned then
model = cloned
end
end

if not model then
model = makeFallbackWrap(groups)
end

applyWrapGroups(model, groups)

for _, obj in ipairs(model:GetDescendants()) do
if obj:IsA("BasePart") then
obj.Anchored = true
obj.CanCollide = false
end
end

local _, size = model:GetBoundingBox()
local scale = math.max(size.X, size.Y, size.Z, 0.001)
model:PivotTo(CFrame.new(0, 0, 0))
wrapVpCamera.CFrame = CFrame.new(0, 0, math.clamp(scale * 0.95, 1.6, 3.2))

return model
end

task.spawn(function()
while task.wait() do
if WrapViewport.Visible and wrapModel and wrapAutoRotate then
wrapSpin = wrapSpin + wrapRotateSpeed
wrapModel:PivotTo(CFrame.Angles(0, wrapSpin, 0))
end
end
end)

InfoLabel = Group:AddLabel({ Text = "" })
InfoLabel.TextLabel.Visible = false

updateVisual = function(class, weapon, kind, name)
CharmViewport.Visible = false
WrapViewport.Visible = false
InfoLabel.TextLabel.Visible = false
for _, c in ipairs(charmWorld:GetChildren()) do c:Destroy() end
for _, c in ipairs(wrapVpWorld:GetChildren()) do c:Destroy() end
charmModel = nil
wrapModel = nil

if name == NONE_LABEL or name == nil then
setViewerImageVisible(true)
local weaponImg = weaponImageOf(class, weapon)
showImage(weaponImg and toAsset(weaponImg) or "rbxassetid://0")
return
end

local entry = entryByName(class, weapon, kind, name)
if not entry or not entry.visual then return end

local v = entry.visual

if v.kind == "image" then
setViewerImageVisible(true)
showImage(toAsset(v.value))

elseif v.kind == "wrap3d" then
setViewerImageVisible(false)
local model = loadWrapModel(v.value)
if model then
model.Parent = wrapVpWorld
wrapModel = model
wrapSpin = 0
wrapAutoRotate = true
WrapViewport.Visible = true
else
InfoLabel:Set("Wrap: " .. tostring(v.value))
InfoLabel.TextLabel.Visible = true
end

elseif v.kind == "charm3d" then
setViewerImageVisible(false)
local model = loadCharmModel(v.charmName)
if model then
model.Parent = charmWorld
charmModel = model
charmSpin = 0
charmAutoRotate = true
CharmViewport.Visible = true
else
InfoLabel:Set("Charm: " .. v.charmName .. "\n(no 3D model)")
InfoLabel.TextLabel.Visible = true
end

elseif v.kind == "named" then
setViewerImageVisible(true)
local weaponImg = weaponImageOf(class, weapon)
showImage(weaponImg and toAsset(weaponImg) or "rbxassetid://0")
InfoLabel:Set(tostring(kind) .. ": " .. tostring(v.value))
InfoLabel.TextLabel.Visible = true
end
end

ClassDropdown = Group:AddDropdown("ClassSelect", {
Text = "Weapon Type", Values = classNames, Default = classNames[1],
Multi = false,
Searchable = true,
Callback = function(class)
local weapons = weaponsOfClass(class)
if WeaponDropdown then WeaponDropdown:SetValues(weapons) end
if weapons[1] then
local kinds = kindsOfWeapon(class, weapons[1])
if KindDropdown then KindDropdown:SetValues(kinds) end
if kinds[1] then
local list = cosmeticsOf(class, weapons[1], kinds[1])
if CosmeticDropdown then
CosmeticDropdown:SetValues(list)
CosmeticDropdown:SetValue(NONE_LABEL)
end
updateVisual(class, weapons[1], kinds[1], NONE_LABEL)
end
end
end,
})

WeaponDropdown = Group:AddDropdown("WeaponSelect", {
Text = "Weapon",
Values = weaponsOfClass(classNames[1]),
Default = weaponsOfClass(classNames[1])[1],
Multi = false,
Searchable = true,
Callback = function(weapon)
local class = ClassDropdown.Value
local kinds = kindsOfWeapon(class, weapon)
if KindDropdown then KindDropdown:SetValues(kinds) end
if kinds[1] then
local list = cosmeticsOf(class, weapon, kinds[1])
if CosmeticDropdown then
CosmeticDropdown:SetValues(list)
CosmeticDropdown:SetValue(NONE_LABEL)
end
updateVisual(class, weapon, kinds[1], NONE_LABEL)
end
end,
})

KindDropdown = Group:AddDropdown("KindSelect", {
Text = "Cosmetics",
Values = kindsOfWeapon(classNames[1], weaponsOfClass(classNames[1])[1]),
Default = kindsOfWeapon(classNames[1], weaponsOfClass(classNames[1])[1])[1],
Multi = false,
Searchable = true,
Callback = function(kind)
local class = ClassDropdown.Value
local weapon = WeaponDropdown.Value
local list = cosmeticsOf(class, weapon, kind)
if CosmeticDropdown then
CosmeticDropdown:SetValues(list)
CosmeticDropdown:SetValue(NONE_LABEL)
end
updateVisual(class, weapon, kind, NONE_LABEL)
end,
})

CosmeticDropdown = Group:AddDropdown("CosmeticSelect", {
Text = "Skin",
Values = cosmeticsOf(classNames[1], weaponsOfClass(classNames[1])[1],
kindsOfWeapon(classNames[1], weaponsOfClass(classNames[1])[1])[1]),
Default = NONE_LABEL,
Multi = false,
Searchable = true,
Callback = function(name)
local class = ClassDropdown.Value
local weapon = WeaponDropdown.Value
local kind = KindDropdown.Value
updateVisual(class, weapon, kind, name)
end,
})

Group:AddButton("Apply", function()
local weapon = WeaponDropdown.Value
local kind = KindDropdown.Value
local name = CosmeticDropdown.Value

if not weapon or weapon == "All" then
return
end

local selection = CosmeticsWrap.selections[weapon] or {}
local slot = string.lower(kind)

if name == NONE_LABEL or name == nil then
selection[slot] = nil
else
if kind == "Wrap" then
selection.wrap = { name = name, inverted = false }
else
selection[slot] = name
end
end

if next(selection) == nil then
CosmeticsWrap.clear(weapon)
else
CosmeticsWrap.set(weapon, selection)
end
end)

Group:AddButton("Reset All", function()
for weapon in pairs(CosmeticsWrap.selections) do
CosmeticsWrap.clear(weapon)
end
CosmeticsWrap.selections = {}
end)

task.defer(function()
local firstClass = classNames[1]
local firstWeapon = weaponsOfClass(firstClass)[1]
if firstWeapon then
local kinds = kindsOfWeapon(firstClass, firstWeapon)
if kinds[1] then
if CosmeticDropdown then
CosmeticDropdown:SetValue(NONE_LABEL)
end
updateVisual(firstClass, firstWeapon, kinds[1], NONE_LABEL)
end
end
end)
end

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
local meleeSpeedOn = false

local fireValue = 100
local fireOn = false
local meleeValue = 100
local meleeOn = false

local function applyFireCooldown()
    local items = getRivalsItems()
    if not items then return end
    local mult = fireValue / 100
    for name, data in pairs(items) do
        if typeof(data) == "table" and not GUN_BLACKLIST[name] and not MELEE_WHITELIST[name] then
            local orig = originalData[name]
            if orig then
                if orig.ShootCooldown ~= nil then data.ShootCooldown = orig.ShootCooldown * mult end
                if orig.ShootBurstCooldown ~= nil then data.ShootBurstCooldown = orig.ShootBurstCooldown * mult end
            end
        end
    end
end

local function applyMeleeCooldown()
    local items = getRivalsItems()
    if not items then return end
    local mult = meleeValue / 100
    for name, data in pairs(items) do
        if typeof(data) == "table" and MELEE_WHITELIST[name] then
            local orig = originalData[name]
            if orig then
                if orig.AttackCooldown ~= nil then data.AttackCooldown = orig.AttackCooldown * mult end
                if orig.SwingCooldown ~= nil then data.SwingCooldown = orig.SwingCooldown * mult end
                if orig.MeleeCooldown ~= nil then data.MeleeCooldown = orig.MeleeCooldown * mult end
                if orig.Cooldown ~= nil then data.Cooldown = orig.Cooldown * mult end
                if orig.RecoveryTime ~= nil then data.RecoveryTime = orig.RecoveryTime * mult end
                if orig.ResetTime ~= nil then data.ResetTime = orig.ResetTime * mult end
            end
        end
    end
end

local function reapplyItemData()
    if game.GameId ~= RIVALS_GAMEID then return end
    restoreAllItemData()
    if fireRateOn then applyFireRate() end
    if meleeSpeedOn then applyMeleeSpeed() end
    if fireOn then applyFireCooldown() end
    if meleeOn then applyMeleeCooldown() end
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
    ["None"]="",
    ["Anime girl laugh"]="rbxassetid://103966419660274",
    ["Mambo umamusume"]="rbxassetid://72270862303024",
    ["sata andagii"]="rbxassetid://111397769122554",
}
local HIT_SOUNDS = {
    ["None"]="",["Neverlose"]="rbxassetid://6607204501",
    ["Gamesense"]="rbxassetid://4817809188",["Skeet"]="rbxassetid://5447626464",
    ["Rust"]="rbxassetid://5043539486",["Bell"]="rbxassetid://6534947240",
    ["Bubble"]="rbxassetid://6534947588",["Minecraft"]="rbxassetid://4018616850",
    ["Osu"]="rbxassetid://7149255551",["TF2"]="rbxassetid://2868331684",
    ["Click Hit Sound"]="rbxassetid://8053704437",
    ["Hit"]="rbxassetid://1347140027",
    ["CSGO"]="rbxassetid://5764885315",
}
local soundState = getgenv().__MinhoSoundState or {
    HitEnabled=false, HitSelected="None", HitVolume=0.5, HitPitch=1,
    HitRemoveDefault=true,
    KillEnabled=false, KillSelected="Default", KillVolume=0.5, KillPitch=1,
}
getgenv().__MinhoSoundState = soundState
soundState.HitRemoveDefault = soundState.HitRemoveDefault ~= false
if soundState.HitSelected == "Default" or soundState.HitSelected == nil then soundState.HitSelected = "None" end
if soundState.KillSelected == "Default" or soundState.KillSelected == nil then soundState.KillSelected = "None" end

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
    Installed = false,
    Enabled = false,
    Hooked = false,
    OriginalPlayHitmarkerSound = nil,
}
getgenv().__MinhoHitSoundState = hitSoundState

local function installHitSound()
    if hitSoundState.Hooked then
        hitSoundState.Enabled = true
        hitSoundState.Installed = true
        return true
    end

    local ok, viewmodelModule = pcall(function()
        return require(LocalPlayer.PlayerScripts.Modules.ClientReplicatedClasses
            .ClientFighter.ClientItem.ClientViewModel)
    end)

    if not ok
        or type(viewmodelModule) ~= "table"
        or type(viewmodelModule.PlayHitmarkerSound) ~= "function" then
        return false
    end

    hitSoundState.OriginalPlayHitmarkerSound =
        hitSoundState.OriginalPlayHitmarkerSound
        or viewmodelModule.PlayHitmarkerSound

    viewmodelModule.PlayHitmarkerSound = function(self, crit, divisor, ...)
        if hitSoundState.Enabled then
            local id = HIT_SOUNDS[soundState.HitSelected] or ""

            if id ~= "" then
                playCustomSound(
                    id,
                    soundState.HitVolume,
                    soundState.HitPitch
                )
            end
        end

        -- Remove the game's original hitmarker sound when enabled.
        -- When disabled, keep the original game sound.
        if soundState.HitRemoveDefault then
            return
        end

        return hitSoundState.OriginalPlayHitmarkerSound(
            self,
            crit,
            divisor,
            ...
        )
    end

    hitSoundState.Hooked = true
    hitSoundState.Installed = true
    hitSoundState.Enabled = true

    return true
end

local function uninstallHitSound()
    hitSoundState.Enabled = false
    hitSoundState.Installed = false

    if hitSoundState.Hooked then
        pcall(function()
            local ok, viewmodelModule = pcall(function()
                return require(LocalPlayer.PlayerScripts.Modules.ClientReplicatedClasses
                    .ClientFighter.ClientItem.ClientViewModel)
            end)

            if ok
                and type(viewmodelModule) == "table"
                and hitSoundState.OriginalPlayHitmarkerSound then
                viewmodelModule.PlayHitmarkerSound =
                    hitSoundState.OriginalPlayHitmarkerSound
            end
        end)
    end

    hitSoundState.Hooked = false
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
    Text = "UE Assisted Rage",
    Default = nil,
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
    Default = nil,
    Mode = "Toggle",
    SyncToggleState = true,
})


local SpeedControl = Main:AddGroupbox({ Name = "Speed Control", Side = 1 })

-- Recoil = 연사 (Full Auto)
SpeedControl:AddCheckbox("Recoil", {
    Text = "Recoil",
    Default = false,
    Callback = function(Value)
        weaponState.FullAuto = Value
        updateWeaponState()
    end
})

SpeedControl:AddCheckbox("NoSpread", {
    Text = "No Spread",
    Default = false,
    Callback = function(Value)
        weaponState.NoSpread = Value
        updateWeaponState()
    end
})

SpeedControl:AddCheckbox("FireCooldownEnabled", {
    Text = "Fire Cooldown (Guns)",
    Default = false,
    Callback = function(Value)
        fireOn = Value
        restoreAllItemData()
        if fireOn then applyFireCooldown() end
        if meleeOn then applyMeleeCooldown() end
    end
})

SpeedControl:AddSlider("FireCooldownValue", {
    Text = "Fire Cooldown Multiplier",
    Default = 100,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Suffix = "%",
    Callback = function(Value)
        fireValue = Value
        if fireOn then
            restoreAllItemData()
            applyFireCooldown()
            if meleeOn then applyMeleeCooldown() end
        end
    end
})

SpeedControl:AddCheckbox("MeleeCooldownEnabled", {
    Text = "Melee Cooldown (Melee)",
    Default = false,
    Callback = function(Value)
        meleeOn = Value
        restoreAllItemData()
        if fireOn then applyFireCooldown() end
        if meleeOn then applyMeleeCooldown() end
    end
})

SpeedControl:AddSlider("MeleeCooldownValue", {
    Text = "Melee Cooldown Multiplier",
    Default = 100,
    Min = 0,
    Max = 100,
    Rounding = 1,
    Suffix = "%",
    Callback = function(Value)
        meleeValue = Value
        if meleeOn then
            restoreAllItemData()
            if fireOn then applyFireCooldown() end
            applyMeleeCooldown()
        end
    end
})

local Skybox = World:AddGroupbox({ Name = "Skybox", Side = 1 })

--// Skybox state
--// "None" always restores the exact Lighting/Sky state from before the FPS skybox
--// was applied. Changing the dropdown applies the new selection immediately.
local previousSkyboxBackend = getgenv().__MinhoSkyboxBackend
if previousSkyboxBackend and type(previousSkyboxBackend.Restore) == "function" then
    pcall(previousSkyboxBackend.Restore)
end

local skyboxState = getgenv().__MinhoSkyboxState or {
    Selected = "None",
}
skyboxState.Selected = skyboxState.Selected or "None"
getgenv().__MinhoSkyboxState = skyboxState

local skyboxOriginal = nil
local skyboxCreated = false
local skyboxActive = false

local function captureSkyboxOriginals()
    if skyboxOriginal then return end

    local sky = Lighting:FindFirstChildOfClass("Sky")

    skyboxOriginal = {
        HasSky = sky ~= nil,
        Sky = sky,
        SkyProperties = sky and {
            SkyboxUp = sky.SkyboxUp,
            SkyboxFt = sky.SkyboxFt,
            SkyboxLf = sky.SkyboxLf,
            SkyboxDn = sky.SkyboxDn,
            SkyboxBk = sky.SkyboxBk,
            SkyboxRt = sky.SkyboxRt,
            SunAngularSize = sky.SunAngularSize,
            MoonAngularSize = sky.MoonAngularSize,
            StarCount = sky.StarCount,
        } or nil,
        GlobalShadows = Lighting.GlobalShadows,
        FogEnd = Lighting.FogEnd,
        PostEffects = {},
    }

    for _, object in ipairs(Lighting:GetChildren()) do
        if object:IsA("PostEffect") then
            skyboxOriginal.PostEffects[object] = object.Enabled
        end
    end
end

local function restoreSkybox()
    if not skyboxOriginal then
        skyboxActive = false
        return
    end

    local sky = skyboxOriginal.Sky

    if skyboxOriginal.HasSky and sky and sky.Parent then
        local props = skyboxOriginal.SkyProperties
        if props then
            pcall(function()
                sky.SkyboxUp = props.SkyboxUp
                sky.SkyboxFt = props.SkyboxFt
                sky.SkyboxLf = props.SkyboxLf
                sky.SkyboxDn = props.SkyboxDn
                sky.SkyboxBk = props.SkyboxBk
                sky.SkyboxRt = props.SkyboxRt
                sky.SunAngularSize = props.SunAngularSize
                sky.MoonAngularSize = props.MoonAngularSize
                sky.StarCount = props.StarCount
            end)
        end
    elseif skyboxCreated and sky and sky.Parent then
        pcall(function() sky:Destroy() end)
    end

    pcall(function() Lighting.GlobalShadows = skyboxOriginal.GlobalShadows end)
    pcall(function() Lighting.FogEnd = skyboxOriginal.FogEnd end)

    for object, enabled in pairs(skyboxOriginal.PostEffects) do
        if object and object.Parent then
            pcall(function() object.Enabled = enabled end)
        end
    end

    skyboxActive = false
    skyboxCreated = false
end

local function applyFPSLighting()
    captureSkyboxOriginals()

    local sky = Lighting:FindFirstChildOfClass("Sky")
    if not sky then
        sky = Instance.new("Sky")
        sky.Parent = Lighting
        skyboxCreated = true
    end

    pcall(function()
        sky.SkyboxUp = "rbxassetid://11457548274"
        sky.SkyboxFt = "rbxassetid://11457548274"
        sky.SkyboxLf = "rbxassetid://11457548274"
        sky.SkyboxDn = "rbxassetid://11457548274"
        sky.SkyboxBk = "rbxassetid://11457548274"
        sky.SkyboxRt = "rbxassetid://11457548274"
        sky.SunAngularSize = 0
        sky.MoonAngularSize = 0
        sky.StarCount = 0
    end)

    for _, object in ipairs(Lighting:GetChildren()) do
        if object:IsA("PostEffect") then
            object.Enabled = false
        end
    end

    Lighting.GlobalShadows = false
    Lighting.FogEnd = 100000
    skyboxActive = true
end

local function setSkyboxSelection(value)
    skyboxState.Selected = value

    if value == "None" then
        restoreSkybox()
    elseif value == "FPS Skybox" then
        applyFPSLighting()
    end
end

getgenv().__MinhoSkyboxBackend = {
    Restore = restoreSkybox,
}

Skybox:AddCheckbox("SkyboxEnabled", {
    Text = "Skybox",
    Default = skyboxState.Enabled == true,
    Callback = function(Value)
        skyboxState.Enabled = Value
        if Value then
            local selected = skyboxState.Selected or "None"
            if selected ~= "None" then
                applySkyboxSelection(selected)
            end
        else
            restoreSkybox()
        end
    end
})

Skybox:AddDropdown("SkyboxType", {
    Text = "Skybox",
    Values = { "None", "FPS Skybox" },
    Default = skyboxState.Selected,
    Multi = false,
    Callback = function(Value)
        setSkyboxSelection(Value)
    end
})

-- Apply the saved selection immediately, so changing/re-running the script
-- never leaves a stale FPS skybox active when the selection is "None".
if skyboxState.Selected == "FPS Skybox" then
    applyFPSLighting()
else
    restoreSkybox()
end

local TexturePackBox = World:AddGroupbox({ Name = "Texture Pack", Side = 2 })

-- ====================== TEXTURA DEL MAPA ======================
local function getAsset(url: string): string
    local success, result = pcall(function()
        if writefile and isfile and getcustomasset then
            local fileName = "mc_" .. tostring(#url % 100000) .. ".asset"

            if not isfile(fileName) then
                local data = game:HttpGet(url)
                if data and #data > 80 then
                    writefile(fileName, data)
                end
            end

            local asset = getcustomasset(fileName)
            if asset and asset ~= "" then
                return asset
            end
        end
        return url
    end)
    return (success and result) or url
end

local MAP_TEXTURE_ID = "7658055825"

local TEXTURE_PACKS = {
    ["Minecraft"] = {
        {ids = {7658055825}, url = getAsset("https://raw.githubusercontent.com/jixyuk12nh-maker/Ui/main/texture_pack/Minecraft.png")},
    },
    ["Grods"] = {
        {ids = {7658055825}, url = getAsset("https://raw.githubusercontent.com/jixyuk12nh-maker/Ui/main/texture_pack/Grods.png")},
    },
}

local texturePackState = getgenv().__MinhoTexturePackState or {
    Selected = "None",
    Enabled = false,
    Applied = false,
    OriginalTextures = {},
    Connections = {},
}
getgenv().__MinhoTexturePackState = texturePackState

local function saveOriginalTexture(obj)
    if not obj then return end
    local key = obj:GetDebugId()
    if not texturePackState.OriginalTextures[key] then
        texturePackState.OriginalTextures[key] = {
            Object = obj,
            Texture = obj.Texture,
        }
    end
end

local function restoreOriginalTextures()
    for key, data in pairs(texturePackState.OriginalTextures) do
        if data.Object and data.Object.Parent then
            pcall(function() data.Object.Texture = data.Texture end)
        end
        texturePackState.OriginalTextures[key] = nil
    end
    texturePackState.Applied = false
end

local function applyTexturePack(packName)
    restoreOriginalTextures()

    for _, conn in ipairs(texturePackState.Connections) do
        pcall(function() conn:Disconnect() end)
    end
    texturePackState.Connections = {}

    if packName == "None" then
        texturePackState.Selected = "None"
        return
    end

    local pack = TEXTURE_PACKS[packName]
    if not pack then return end
    texturePackState.Selected = packName

    local function processObject(obj)
        if obj:IsA("Decal") or obj:IsA("Texture") then
            local success, value = pcall(function() return obj.Texture end)
            if success and type(value) == "string" then
                local id = string.match(value, "%d+")
                if id == MAP_TEXTURE_ID then
                    for _, texData in ipairs(pack) do
                        for _, targetId in ipairs(texData.ids) do
                            if tonumber(id) == targetId then
                                saveOriginalTexture(obj)
                                pcall(function() obj.Texture = texData.url end)
                                return
                            end
                        end
                    end
                end
            end
        elseif obj:IsA("MeshPart") then
            local success, value = pcall(function() return obj.TextureID end)
            if success and type(value) == "string" then
                local id = string.match(value, "%d+")
                if id == MAP_TEXTURE_ID then
                    for _, texData in ipairs(pack) do
                        for _, targetId in ipairs(texData.ids) do
                            if tonumber(id) == targetId then
                                pcall(function() obj.TextureID = texData.url end)
                                return
                            end
                        end
                    end
                end
            end
        end
    end

    for _, obj in ipairs(game:GetDescendants()) do
        pcall(processObject, obj)
    end

    local conn = game.DescendantAdded:Connect(function(obj)
        task.defer(processObject, obj)
    end)
    table.insert(texturePackState.Connections, conn)
    texturePackState.Applied = true
end

TexturePackBox:AddCheckbox("TexturePackEnabled", {
    Text = "Texture Pack",
    Default = false,
    Callback = function(Value)
        texturePackState.Enabled = Value
        if Value then
            if texturePackState.Selected and texturePackState.Selected ~= "None" then
                applyTexturePack(texturePackState.Selected)
            end
        else
            restoreOriginalTextures()
            for _, conn in ipairs(texturePackState.Connections) do
                pcall(function() conn:Disconnect() end)
            end
            texturePackState.Connections = {}
        end
    end
})

TexturePackBox:AddDropdown("TexturePack", {
    Text = "Texture Pack",
    Values = { "None", "Minecraft", "Grods" },
    Default = "None",
    Multi = false,
    Callback = function(Value)
        texturePackState.Selected = Value
        if texturePackState.Enabled then
            if Value == "None" then
                restoreOriginalTextures()
            else
                applyTexturePack(Value)
            end
        end
    end
})

-- 저장된 선택 복원
if texturePackState.Selected ~= "None" then
    applyTexturePack(texturePackState.Selected)
end
if texturePackState.Selected ~= "Default" then
    applyTexturePack(texturePackState.Selected)
end

local CONFIG = {
Enabled = true,
MaxDistance = 500,
RefreshInterval = 30,

TextHeightRatio = 0.5,
OffsetX = 6,
TextColor = Color3.fromRGB(255, 255, 255),
NameColor = Color3.fromRGB(255, 255, 255),
MinTextSize = 8,
MaxTextSize = 40,

ShowBox = false,
BoxColor = Color3.fromRGB(255, 255, 255),
BoxThickness = 2,
BoxTransparency = 0,
BoxOutline = true,

ShowSkeleton = false,
SkeletonColor = Color3.fromRGB(255, 255, 255),
SkeletonThickness = 2,
SkeletonTransparency = 0,
SkeletonOutline = true,

ShowHealth = false,
HealthColor = Color3.fromRGB(0, 255, 0),
HealthLow = Color3.fromRGB(255, 0, 0),

ShowName = false,
ShowDistance = false,
ShowWeapon = false,
WeaponColor = Color3.fromRGB(255, 200, 100),
ShowLevel = false,
ShowELO = false,
ShowStreak = false,
}

local TIERS = {
{ min = 0, name = "Unranked" },
{ min = 1, name = "Bronze 1" },
{ min = 200, name = "Bronze 2" },
{ min = 400, name = "Bronze 3" },
{ min = 600, name = "Silver 1" },
{ min = 800, name = "Silver 2" },
{ min = 1000, name = "Silver 3" },
{ min = 1200, name = "Gold 1" },
{ min = 1400, name = "Gold 2" },
{ min = 1600, name = "Gold 3" },
{ min = 1800, name = "Platinum 1" },
{ min = 2000, name = "Platinum 2" },
{ min = 2200, name = "Platinum 3" },
{ min = 2400, name = "Diamond 1" },
{ min = 2600, name = "Diamond 2" },
{ min = 2800, name = "Diamond 3" },
{ min = 3000, name = "Onyx 1" },
{ min = 3200, name = "Onyx 2" },
{ min = 3400, name = "Onyx 3" },
{ min = 3600, name = "Nemesis" },
}

local LeaderboardCache = {}

local function refreshLeaderboard()
local ok, ctrl = pcall(function()
return require(LocalPlayer.PlayerScripts.Controllers.LeaderboardController)
end)
if not ok or not ctrl then return end
local serials = ctrl.LeaderboardSerials
if not serials then return end

local newCache = {}
local function ingest(boardName, rankKey)
local board = serials[boardName]
if not board or not board.Players then return end
for rank, data in pairs(board.Players) do
if type(data) == "table" and data.key and type(rank) == "number" then
local userId = data.key
if not newCache[userId] then newCache[userId] = {} end
newCache[userId][rankKey] = rank
if rankKey == "eloRank" then
newCache[userId].elo = data.value
end
end
end
end

ingest("Highest ELO", "eloRank")
ingest("Highest Level", "levelRank")
ingest("Current Highest Win Streak", "streakRank")

LeaderboardCache = newCache
end

task.spawn(function()
task.wait(5)
while true do
pcall(refreshLeaderboard)
task.wait(CONFIG.RefreshInterval)
end
end)

local function getTierName(elo, userId)
if userId then
local lb = LeaderboardCache[userId]
if lb and lb.eloRank then
if lb.eloRank >= 1 and lb.eloRank <= 200 then
return "Archnemesis"
end
if lb.eloRank >= 201 and lb.eloRank <= 250 then
return "Nemesis"
end
end
end
if type(elo) ~= "number" then return nil end
local name = TIERS[1].name
for _, t in ipairs(TIERS) do
if elo >= t.min then name = t.name end
end
return name
end

local function withRank(value, rank)
if value == nil then return "?" end
local text = tostring(math.floor(value))
if type(rank) == "number" and rank > 0 then
text = text .. " (#" .. rank .. ")"
end
return text
end

local ATTR_LEVEL = "Level"
local ATTR_ELO = "DisplayELO"
local ATTR_STREAK = "StatisticDuelsWinStreak"
local ATTR_TEAM = "TeamID"
local ATTR_ENV = "EnvironmentID"

local function getAttr(inst, name)
if not inst then return nil end
local ok, v = pcall(function() return inst:GetAttribute(name) end)
return ok and v or nil
end

local function vec2floor(v)
return Vector2.new(math.floor(v.X), math.floor(v.Y))
end

local FONT_ID = "rbxassetid://12187365364"
local Fonts = {
Main = Font.new(FONT_ID, Enum.FontWeight.Regular, Enum.FontStyle.Normal),
}

local gui = Instance.new("ScreenGui")
gui.Name = "RivalsTierESP"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
pcall(function() gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling end)
pcall(function() gui.DisplayOrder = 999 end)

local parentOk = pcall(function() gui.Parent = game:GetService("CoreGui") end)
if not parentOk or not gui.Parent then
gui.Parent = LocalPlayer:WaitForChild("PlayerGui")
end

local function makeLabel(color, align)
local lbl = Instance.new("TextLabel")
lbl.BackgroundTransparency = 1
lbl.BorderSizePixel = 0
lbl.Size = UDim2.fromOffset(0, 0)
lbl.AutomaticSize = Enum.AutomaticSize.XY
lbl.AnchorPoint = Vector2.new(0, 0)
lbl.TextSize = 14
lbl.FontFace = Fonts.Main
lbl.TextColor3 = color or CONFIG.TextColor
lbl.TextStrokeTransparency = 0
lbl.TextStrokeColor3 = Color3.new(0, 0, 0)
lbl.TextXAlignment = align or Enum.TextXAlignment.Left
lbl.TextYAlignment = Enum.TextYAlignment.Top
lbl.Visible = false
lbl.Parent = gui
return lbl
end

local function makeCenterLabel(color)
local lbl = makeLabel(color)
lbl.AnchorPoint = Vector2.new(0.5, 1)
lbl.TextXAlignment = Enum.TextXAlignment.Center
return lbl
end

local function makeRightLabel(color)
local lbl = makeLabel(color)
lbl.AnchorPoint = Vector2.new(1, 0)
lbl.TextXAlignment = Enum.TextXAlignment.Right
return lbl
end

local labels = {}

local function onPlayerAdded(player)
if player == LocalPlayer then return end
if labels[player] then return end
labels[player] = {
level = makeLabel(CONFIG.TextColor),
elo = makeLabel(CONFIG.TextColor),
streak = makeLabel(CONFIG.TextColor),
health = makeRightLabel(CONFIG.HealthColor),
name = makeCenterLabel(CONFIG.NameColor),
weapon = makeCenterLabel(CONFIG.WeaponColor),
distance = makeCenterLabel(CONFIG.TextColor),
}
end

local function onPlayerRemoving(player)
local set = labels[player]
if set then
for _, lbl in pairs(set) do lbl:Destroy() end
end
labels[player] = nil
end

for _, p in ipairs(Players:GetPlayers()) do onPlayerAdded(p) end
Players.PlayerAdded:Connect(onPlayerAdded)
Players.PlayerRemoving:Connect(onPlayerRemoving)

local Reference = {}
local Records = {}

local SKELETON_R15 = {
{ "Head", "UpperTorso" }, { "UpperTorso", "LowerTorso" },
{ "UpperTorso", "LeftUpperArm" }, { "LeftUpperArm", "LeftLowerArm" }, { "LeftLowerArm", "LeftHand" },
{ "UpperTorso", "RightUpperArm" }, { "RightUpperArm", "RightLowerArm" }, { "RightLowerArm", "RightHand" },
{ "LowerTorso", "LeftUpperLeg" }, { "LeftUpperLeg", "LeftLowerLeg" }, { "LeftLowerLeg", "LeftFoot" },
{ "LowerTorso", "RightUpperLeg" }, { "RightUpperLeg", "RightLowerLeg" }, { "RightLowerLeg", "RightFoot" },
}
local SKELETON_R6 = {
{ "Head", "Torso" }, { "Torso", "Left Arm" }, { "Torso", "Right Arm" },
{ "Torso", "Left Leg" }, { "Torso", "Right Leg" },
}
local MAX_BONES = 15

local function bindCharacter(record, character)
record.Character = character
record.Root = nil
record.Head = nil
record.Humanoid = nil
record.Parts = {}
record.SkeletonLinks = {}
record.HipHeight = 2
if not character then return end

local function rebuild()
record.Parts = {}
record.SkeletonLinks = {}
for _, part in ipairs(character:GetChildren()) do
if part:IsA("BasePart") then
record.Parts[part.Name] = part
local motor = part:FindFirstChildOfClass("Motor6D")
if motor and motor.Part0 and motor.Part1 then
table.insert(record.SkeletonLinks, { motor.Part0, motor.Part1 })
end
end
end
end
rebuild()

record.Root = character:FindFirstChild("HumanoidRootPart")
or character:FindFirstChild("Torso")
or character.PrimaryPart
record.Humanoid = character:FindFirstChildOfClass("Humanoid")
record.Head = character:FindFirstChild("HitboxHead")
or character:FindFirstChild("Head")
or record.Root
if record.Humanoid then
record.HipHeight = record.Humanoid.HipHeight or 2
end

record._conns = record._conns or {}
for _, c in ipairs(record._conns) do c:Disconnect() end
record._conns = {}
table.insert(record._conns, character.DescendantAdded:Connect(function(d)
if d:IsA("BasePart") or d:IsA("Motor6D") then task.defer(rebuild) end
end))
table.insert(record._conns, character.DescendantRemoving:Connect(function(d)
if d:IsA("BasePart") or d:IsA("Motor6D") then task.defer(rebuild) end
end))
end

local function ensureRecord(player)
local record = Records[player]
if record then return record end
record = {
Player = player,
Character = nil, Root = nil, Head = nil, Humanoid = nil,
Parts = {}, SkeletonLinks = {},
HipHeight = 2,
}
Records[player] = record
player.CharacterAdded:Connect(function(char)
bindCharacter(record, char)
task.delay(0.5, function()
if record.Character == char then bindCharacter(record, char) end
end)
end)
if player.Character then bindCharacter(record, player.Character) end
return record
end

local function ensureDrawings(player)
if Reference[player] then return Reference[player] end
if not Drawing then return nil end

local set = { box = {}, skeleton = {} }

set.box.Main = Drawing.new("Square")
set.box.Main.Transparency = 1
set.box.Main.ZIndex = 2
set.box.Main.Filled = false
set.box.Main.Thickness = CONFIG.BoxThickness
set.box.Main.Color = CONFIG.BoxColor

set.box.Border = Drawing.new("Square")
set.box.Border.Transparency = 0.35
set.box.Border.ZIndex = 1
set.box.Border.Thickness = CONFIG.BoxThickness + 1
set.box.Border.Filled = false
set.box.Border.Color = Color3.new(0, 0, 0)

set.box.HealthLine = Drawing.new("Line")
set.box.HealthLine.Thickness = 2
set.box.HealthLine.ZIndex = 3
set.box.HealthLine.Color = CONFIG.HealthColor

set.box.HealthBorder = Drawing.new("Line")
set.box.HealthBorder.Thickness = 4
set.box.HealthBorder.ZIndex = 2
set.box.HealthBorder.Color = Color3.new(0, 0, 0)

for i = 1, MAX_BONES do
local backer = Drawing.new("Line")
backer.Thickness = CONFIG.SkeletonThickness + 2
backer.Color = Color3.new(0, 0, 0)
backer.ZIndex = 1

local line = Drawing.new("Line")
line.Thickness = CONFIG.SkeletonThickness
line.Color = CONFIG.SkeletonColor
line.ZIndex = 2

set.skeleton[i] = { backer = backer, color = line }
end

Reference[player] = set
return set
end

local function hideDrawings(set)
if not set then return end
set.box.Main.Visible = false
set.box.Border.Visible = false
set.box.HealthLine.Visible = false
set.box.HealthBorder.Visible = false
for _, bone in ipairs(set.skeleton) do
bone.backer.Visible = false
bone.color.Visible = false
end
end

local function removeDrawings(player)
local set = Reference[player]
if not set then return end
pcall(function() set.box.Main:Remove() end)
pcall(function() set.box.Border:Remove() end)
pcall(function() set.box.HealthLine:Remove() end)
pcall(function() set.box.HealthBorder:Remove() end)
for _, bone in ipairs(set.skeleton) do
pcall(function() bone.backer:Remove() end)
pcall(function() bone.color:Remove() end)
end
Reference[player] = nil
end

Players.PlayerRemoving:Connect(function(player)
removeDrawings(player)
Records[player] = nil
end)

for _, p in ipairs(Players:GetPlayers()) do
if p ~= LocalPlayer then ensureRecord(p) end
end
Players.PlayerAdded:Connect(function(p)
if p ~= LocalPlayer then ensureRecord(p) end
end)

if not Drawing then
warn("[ESP] Drawing API unavailable — box/skeleton skipped")
end

local function getWeaponName(player)
if not player then return nil end
local char = player.Character
if not char then return nil end
local weapon = char:GetAttribute("EquippedItem")
if weapon and weapon ~= "" then return tostring(weapon) end
return nil
end

RunService.RenderStepped:Connect(function()
if not CONFIG.Enabled then
for _, set in pairs(labels) do
for _, lbl in pairs(set) do lbl.Visible = false end
end
for _, set in pairs(Reference) do hideDrawings(set) end
return
end

Camera = Workspace.CurrentCamera
if not Camera then return end

local myEnv = getAttr(LocalPlayer, ATTR_ENV)
local myTeam = getAttr(LocalPlayer, ATTR_TEAM)
if myTeam == "" then myTeam = nil end

if myEnv == nil then
for _, set in pairs(labels) do
for _, lbl in pairs(set) do lbl.Visible = false end
end
for _, set in pairs(Reference) do hideDrawings(set) end
return
end

local camPos = Camera.CFrame.Position

for player, record in pairs(Records) do
local set = labels[player]
if not set then continue end

local char = record.Character
local root = record.Root
local hum = record.Humanoid

if not char or not char.Parent then
char = player.Character
if char and char.Parent then
bindCharacter(record, char)
root = record.Root
hum = record.Humanoid
end
end

local function hideAll()
for _, lbl in pairs(set) do lbl.Visible = false end
local dset = Reference[player]
if dset then hideDrawings(dset) end
end

if not char or not root or not root.Parent then
hideAll()
continue
end

if hum and hum.Health <= 0 then
hideAll()
continue
end

local dist = (root.Position - camPos).Magnitude
if dist > CONFIG.MaxDistance then
hideAll()
continue
end

local theirEnv = getAttr(player, ATTR_ENV)
if theirEnv ~= myEnv then
hideAll()
continue
end

local theirTeam = getAttr(player, ATTR_TEAM)
if theirTeam == "" then theirTeam = nil end
if myTeam ~= nil and theirTeam ~= nil and myTeam == theirTeam then
hideAll()
continue
end

local rootPos, rootVis = Camera:WorldToViewportPoint(root.Position)
if not rootVis or rootPos.Z <= 0 then
hideAll()
continue
end

local boxRightX, boxLeftX, boxTopY, boxBottomY, sizey = nil, nil, nil, nil, nil
local boxCenterX = nil

if Drawing then
local dset = ensureDrawings(player)
if dset then
if CONFIG.ShowBox then
local topPos = Camera:WorldToViewportPoint(
(CFrame.lookAlong(root.Position, Camera.CFrame.LookVector)
* CFrame.new(2, record.HipHeight, 0)).Position
)
local bottomPos = Camera:WorldToViewportPoint(
(CFrame.lookAlong(root.Position, Camera.CFrame.LookVector)
* CFrame.new(-2, -record.HipHeight - 1, 0)).Position
)

local sizex = math.abs(topPos.X - bottomPos.X)
sizey = math.abs(topPos.Y - bottomPos.Y)

if sizex >= 2 and sizey >= 2 then
local posx = rootPos.X - sizex / 2
local posy = math.min(topPos.Y, bottomPos.Y)

dset.box.Main.Visible = true
dset.box.Main.Color = CONFIG.BoxColor
dset.box.Main.Transparency = 1 - CONFIG.BoxTransparency
dset.box.Main.Thickness = CONFIG.BoxThickness
dset.box.Main.Position = vec2floor(Vector2.new(posx, posy))
dset.box.Main.Size = vec2floor(Vector2.new(sizex, sizey))

dset.box.Border.Visible = CONFIG.BoxOutline
dset.box.Border.Position = vec2floor(Vector2.new(posx - 1, posy + 1))
dset.box.Border.Size = vec2floor(Vector2.new(sizex + 2, sizey - 2))
dset.box.Border.Thickness = CONFIG.BoxThickness + 1

boxRightX = posx + sizex
boxLeftX = posx
boxTopY = posy
boxBottomY = posy + sizey
boxCenterX = posx + sizex / 2

if CONFIG.ShowHealth and hum then
local healthRatio = math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1)
local healthHeight = sizey * healthRatio
local barX = posx - 8

dset.box.HealthBorder.Visible = true
dset.box.HealthBorder.From = vec2floor(Vector2.new(barX, posy))
dset.box.HealthBorder.To = vec2floor(Vector2.new(barX, posy + sizey))

dset.box.HealthLine.Visible = true
dset.box.HealthLine.Color = CONFIG.HealthLow:Lerp(CONFIG.HealthColor, healthRatio)
dset.box.HealthLine.From = vec2floor(Vector2.new(barX, posy + sizey - healthHeight))
dset.box.HealthLine.To = vec2floor(Vector2.new(barX, posy + sizey))
else
dset.box.HealthBorder.Visible = false
dset.box.HealthLine.Visible = false
end
else
dset.box.Main.Visible = false
dset.box.Border.Visible = false
dset.box.HealthBorder.Visible = false
dset.box.HealthLine.Visible = false
end
else
dset.box.Main.Visible = false
dset.box.Border.Visible = false
dset.box.HealthBorder.Visible = false
dset.box.HealthLine.Visible = false
end

if CONFIG.ShowSkeleton then
local links = record.SkeletonLinks
local motorLinks = #links > 0
local parts = record.Parts
local bones = motorLinks and links
or (parts.UpperTorso and SKELETON_R15 or SKELETON_R6)

for i = 1, MAX_BONES do
local bone = dset.skeleton[i]
local link = bones[i]
if link then
local a, b
if motorLinks then
a, b = link[1], link[2]
else
a, b = parts[link[1]], parts[link[2]]
end
if a and b and a.Parent and b.Parent then
local pa = Camera:WorldToViewportPoint(a.Position)
local pb = Camera:WorldToViewportPoint(b.Position)
if pa.Z > 0 and pb.Z > 0 then
local from = Vector2.new(pa.X, pa.Y)
local to = Vector2.new(pb.X, pb.Y)

bone.backer.Visible = CONFIG.SkeletonOutline
bone.backer.From = from
bone.backer.To = to
bone.backer.Thickness = CONFIG.SkeletonThickness + 2
bone.backer.Color = Color3.new(0, 0, 0)
bone.backer.Transparency = 1 - CONFIG.SkeletonTransparency

bone.color.Visible = true
bone.color.From = from
bone.color.To = to
bone.color.Thickness = CONFIG.SkeletonThickness
bone.color.Color = CONFIG.SkeletonColor
bone.color.Transparency = 1 - CONFIG.SkeletonTransparency
else
bone.backer.Visible = false
bone.color.Visible = false
end
else
bone.backer.Visible = false
bone.color.Visible = false
end
else
bone.backer.Visible = false
bone.color.Visible = false
end
end
else
for i = 1, MAX_BONES do
local bone = dset.skeleton[i]
bone.backer.Visible = false
bone.color.Visible = false
end
end
end
end

local levelVal = getAttr(player, ATTR_LEVEL)
local eloVal = getAttr(player, ATTR_ELO)
local streakVal = getAttr(player, ATTR_STREAK)
local userId = player.UserId
local lb = LeaderboardCache[userId] or {}

local baseX, baseY, lineH, textSize

if boxRightX and boxTopY and sizey then
baseX = boxRightX + CONFIG.OffsetX
baseY = boxTopY

local totalTextHeight = sizey * CONFIG.TextHeightRatio
textSize = math.clamp(
math.floor((totalTextHeight / 3) * 0.85 + 0.5),
CONFIG.MinTextSize,
CONFIG.MaxTextSize
)
lineH = totalTextHeight / 3
else
baseX = rootPos.X + 20
baseY = rootPos.Y - 20
textSize = CONFIG.MaxTextSize
lineH = textSize * 1.2
end

set.level.TextSize = textSize
set.level.Text = "Level " .. withRank(levelVal, lb.levelRank)
set.level.Position = UDim2.fromOffset(baseX, baseY)
set.level.Visible = CONFIG.ShowLevel

local tierName = getTierName(eloVal, userId)
local eloText
if eloVal ~= nil then
eloText = "ELO " .. tostring(math.floor(eloVal))
if tierName then
eloText = eloText .. " (" .. tierName .. ")"
end
else
eloText = "ELO ?"
end
if type(lb.eloRank) == "number" and lb.eloRank > 0 then
eloText = eloText .. " #" .. lb.eloRank
end
set.elo.TextSize = textSize
set.elo.Text = eloText
set.elo.Position = UDim2.fromOffset(baseX, baseY + lineH)
set.elo.Visible = CONFIG.ShowELO

set.streak.TextSize = textSize
set.streak.Text = "Streak " .. withRank(streakVal, lb.streakRank)
set.streak.Position = UDim2.fromOffset(baseX, baseY + lineH * 2)
set.streak.Visible = CONFIG.ShowStreak

local flagSize = math.max(CONFIG.MinTextSize, math.floor(textSize * 0.75))
local flagLineH = flagSize + 2

if CONFIG.ShowHealth and hum and boxLeftX and boxTopY and sizey then
local healthColor = CONFIG.HealthLow:Lerp(CONFIG.HealthColor, math.clamp(hum.Health / math.max(hum.MaxHealth, 1), 0, 1))
set.health.TextSize = flagSize
set.health.Text = tostring(math.floor(hum.Health + 0.5))
set.health.TextColor3 = healthColor
set.health.Position = UDim2.fromOffset(boxLeftX - 12, boxTopY + sizey / 2 - flagSize / 2)
set.health.Visible = true
else
set.health.Visible = false
end

if CONFIG.ShowName and boxCenterX and boxTopY then
set.name.TextSize = textSize
set.name.Text = player.DisplayName
set.name.Position = UDim2.fromOffset(boxCenterX, boxTopY - 4)
set.name.Visible = true
else
set.name.Visible = false
end

if CONFIG.ShowWeapon and boxCenterX and boxBottomY then
local weapon = getWeaponName(player)
if weapon and weapon ~= "" then
set.weapon.TextSize = flagSize
set.weapon.Text = weapon
set.weapon.Position = UDim2.fromOffset(boxCenterX, boxBottomY + flagLineH)
set.weapon.Visible = true
else
set.weapon.Visible = false
end
else
set.weapon.Visible = false
end

if CONFIG.ShowDistance and boxCenterX and boxBottomY then
local yOffset = flagLineH
if CONFIG.ShowWeapon then
local weapon = getWeaponName(player)
if weapon and weapon ~= "" then
yOffset = flagLineH * 2
end
end
set.distance.TextSize = flagSize
set.distance.Text = tostring(math.floor(dist)) .. "m"
set.distance.Position = UDim2.fromOffset(boxCenterX, boxBottomY + yOffset)
set.distance.Visible = true
else
set.distance.Visible = false
end
end
end)

local ESPBox = Visuals:AddGroupbox({ Name = "ESP", Side = 1 })

ESPBox:AddCheckbox("ESPBox", {
    Text = "Box",
    Default = false,
    Callback = function(Value)
        CONFIG.ShowBox = Value
    end
})

ESPBox:AddCheckbox("ESPSkeleton", {
    Text = "Skeleton",
    Default = false,
    Callback = function(Value)
        CONFIG.ShowSkeleton = Value
    end
})

ESPBox:AddCheckbox("ESPName", {
    Text = "Name",
    Default = false,
    Callback = function(Value)
        CONFIG.ShowName = Value
    end
})

ESPBox:AddCheckbox("ESPHealth", {
    Text = "Health",
    Default = false,
    Callback = function(Value)
        CONFIG.ShowHealth = Value
    end
})

ESPBox:AddCheckbox("ESPWeapon", {
    Text = "Weapon",
    Default = false,
    Callback = function(Value)
        CONFIG.ShowWeapon = Value
    end
})

ESPBox:AddCheckbox("ESPLevel", {
    Text = "Level",
    Default = false,
    Callback = function(Value)
        CONFIG.ShowLevel = Value
    end
})

ESPBox:AddCheckbox("ESPELO", {
    Text = "ELO",
    Default = false,
    Callback = function(Value)
        CONFIG.ShowELO = Value
    end
})

ESPBox:AddCheckbox("ESPStreak", {
    Text = "Streak",
    Default = false,
    Callback = function(Value)
        CONFIG.ShowStreak = Value
    end
})

local HitSoundBox = Visuals:AddGroupbox({ Name = "Hit Sound", Side = 1 })

HitSoundBox:AddCheckbox("HitSoundEnabled", {
    Text = "Hit Sound", Default = false,
    Callback = function(Value)
        soundState.HitEnabled = Value
        hitSoundState.Enabled = Value
        if Value then installHitSound() else uninstallHitSound() end
    end
})

HitSoundBox:AddDropdown("HitSoundSelect", {
    Text = "Hit Sound Type",
    Values = { "None","Neverlose","Gamesense","Skeet","Rust","Bell","Bubble","Minecraft","Osu","TF2", "Click Hit Sound", "Hit", "CSGO" },
    Default = "None", Multi = false,
    Callback = function(Value) soundState.HitSelected = Value end
})

HitSoundBox:AddSlider("HitSoundVolume", {
    Text = "Hit Volume", Default = 0.5, Min = 0, Max = 2, Rounding = 1, Suffix = "",
    Callback = function(Value) soundState.HitVolume = Value end
})

HitSoundBox:AddSlider("HitSoundPitch", {
    Text = "Hit Pitch", Default = 1, Min = 0.1, Max = 3, Rounding = 1, Suffix = "",
    Callback = function(Value) soundState.HitPitch = Value end
})

HitSoundBox:AddCheckbox("HitSoundRemoveDefault", {
    Text = "Remove Default Hit Sound", Default = true,
    Callback = function(Value) soundState.HitRemoveDefault = Value end
})

local KillSoundBox = Visuals:AddGroupbox({ Name = "Kill Sound", Side = 2 })

KillSoundBox:AddCheckbox("KillSoundEnabled", {
    Text = "Kill Sound", Default = false,
    Callback = function(Value)
        soundState.KillEnabled = Value
        if Value then installKillSoundSystem() else uninstallKillSoundSystem() end
    end
})

KillSoundBox:AddDropdown("KillSoundSelect", {
    Text = "Kill Sound Type",
    Values = { "None","Anime girl laugh","Mambo umamusume","sata andagii" },
    Default = "None", Multi = false,
    Callback = function(Value) soundState.KillSelected = Value end
})

KillSoundBox:AddSlider("KillSoundVolume", {
    Text = "Kill Volume", Default = 0.5, Min = 0, Max = 2, Rounding = 1, Suffix = "",
    Callback = function(Value) soundState.KillVolume = Value end
})

KillSoundBox:AddSlider("KillSoundPitch", {
    Text = "Kill Pitch", Default = 1, Min = 0.1, Max = 3, Rounding = 1, Suffix = "",
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
    Default = nil,
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
    Default = nil,
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
    Default = false,
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
