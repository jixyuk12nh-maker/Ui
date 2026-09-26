--!nonstrict
local Library = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/jixyuk12nh-maker/Ui/refs/heads/main/Minho_Hub_Obsidian_UI.lua"
))()

local Players     = game:GetService("Players")
local RunService  = game:GetService("RunService")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer

local Window = Library:CreateWindow({
    Title = "Minho Hub",
    Footer = "Full Spoofer",
    Size = UDim2.fromOffset(950, 600),
    ToggleKeybind = Enum.KeyCode.RightControl,
})

local Spoofer = Window:AddTab("Spoofer")

local Trove = {}
Trove.__index = Trove
function Trove.new() return setmetatable({ _objects = {} }, Trove) end
function Trove:Add(obj) table.insert(self._objects, obj); return obj end
function Trove:Destroy()
    for i = #self._objects, 1, -1 do
        pcall(function()
            local obj = self._objects[i]
            if typeof(obj) == "RBXScriptConnection" then obj:Disconnect()
            elseif typeof(obj) == "Instance" then obj:Destroy()
            elseif type(obj) == "function" then obj()
            elseif type(obj) == "thread" then task.cancel(obj) end
        end)
    end
    self._objects = {}
end
local SpoofTrove = Trove.new()

local PlayerScripts = LocalPlayer:WaitForChild("PlayerScripts", 10)
local Controllers = PlayerScripts:WaitForChild("Controllers", 10)

local ControllerCache = {}
local function getController(name)
    if ControllerCache[name] ~= nil then return ControllerCache[name] or nil end
    local mod = Controllers:FindFirstChild(name)
    if not mod then ControllerCache[name] = false return nil end
    local ok, result = pcall(require, mod)
    ControllerCache[name] = ok and result or false
    return ok and result or nil
end

local PlayerDataCtrl = getController("PlayerDataController")
local CameraCtrl = getController("CameraController")

local State = {
    charEnabled = false,
    charUserId = nil,
    charApplied = nil,
    charCache = {},
    spoofLocks = setmetatable({}, { __mode = "k" }),

    currentUrl = nil,
    currentDisplayName = nil,
    currentUsername = nil,

    resetWatchConn = nil,
    hideConn = nil,

    _partScanAcc = 0,
    _lastPov = nil,
    _spoofing = false,
    _profileWatchers = setmetatable({}, { __mode = "k" }),

    _originalSnapshot = nil,
    _restoreThread = nil,

    _lastInputValue = "",
    _inputDebounce = nil,

    profileHideEnabled = true,
}

getgenv().SpooferState = State

local Cfg = {
    Name = { on = false, val = "Minho" },
    DisplayName = { on = false, val = "Minho" },
    Winstreak = { on = false, val = 999 },
    Level = { on = false, val = 999 },
    CasualWins = { on = false, val = 9999 },
    RankedWins = { on = false, val = 9999 },
    CasualWinPercent = { on = false, val = 100 },
    RankedWinPercent = { on = false, val = 100 },
    RankedElo = { on = false, val = 3600 },
    FavoriteMap = { on = false, val = "Arena" },
    NametagStatus = { on = false, val = "Prime" },
    RankTier = { on = false, val = "Archnemesis" },
    Influencer = { on = false },
    RobloxEmployee = { on = false },
    NosniyTeam = { on = false },
}

local MAPS = {
    "Arena", "Big Arena", "Backrooms", "Big Backrooms", "Legacy Backrooms",
    "Battleground", "Bridge", "Chess", "Dimension",
    "Docks", "Legacy Docks", "Gate",
    "Graveyard", "Big Graveyard", "Iceberg", "Museum",
    "Onyx", "Big Onyx", "Legacy Onyx",
    "Playground", "Rooftop", "Sandbox", "Spleef",
    "Station", "Big Station", "Studio", "Temple",
    "Village", "Westown", "Zombie Tower",
}
local TIERS = {"Unranked","Bronze 1","Bronze 2","Bronze 3","Silver 1","Silver 2","Silver 3","Gold 1","Gold 2","Gold 3","Platinum 1","Platinum 2","Platinum 3","Diamond 1","Diamond 2","Diamond 3","Onyx 1","Onyx 2","Onyx 3","Nemesis","Archnemesis"}
local TAGS = {"Prime","Contraband"}

local function isSpoofActive()
    return State.charEnabled == true
       and State.charUserId ~= nil
       and State.charApplied ~= nil
end

local function anyTextSpoofOn()
    return State.charEnabled or Cfg.Name.on or Cfg.DisplayName.on
end

local held = setmetatable({}, { __mode = "k" })

local function releaseHeld(obj)
    local conn = held[obj]
    if conn then
        pcall(function() conn:Disconnect() end)
        held[obj] = nil
    end
    pcall(function()
        if not obj or not obj.Parent then return end
        if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
            local orig = obj:GetAttribute("_OrigImgTransparency")
            if orig ~= nil then
                obj.ImageTransparency = orig
                obj:SetAttribute("_OrigImgTransparency", nil)
            else
                obj.ImageTransparency = 0
            end
        elseif obj:IsA("TextLabel") then
            local orig = obj:GetAttribute("_OrigTextTransparency")
            if orig ~= nil then
                obj.TextTransparency = orig
                obj:SetAttribute("_OrigTextTransparency", nil)
            else
                obj.TextTransparency = 0
            end
        end
    end)
end

local function releaseAllHeld()
    for obj, conn in pairs(held) do
        if typeof(conn) == "RBXScriptConnection" then
            pcall(function() conn:Disconnect() end)
        end
        pcall(function()
            if not obj or not obj.Parent then return end
            if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
                local orig = obj:GetAttribute("_OrigImgTransparency")
                if orig ~= nil then
                    obj.ImageTransparency = orig
                    obj:SetAttribute("_OrigImgTransparency", nil)
                else
                    obj.ImageTransparency = 0
                end
            elseif obj:IsA("TextLabel") then
                local orig = obj:GetAttribute("_OrigTextTransparency")
                if orig ~= nil then
                    obj.TextTransparency = orig
                    obj:SetAttribute("_OrigTextTransparency", nil)
                else
                    obj.TextTransparency = 0
                end
            end
        end)
        held[obj] = nil
    end
    held = setmetatable({}, { __mode = "k" })
end

local function hideSlotNow(obj)
    if not obj or not obj.Parent then return end
    if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
        if obj:GetAttribute("_OrigImgTransparency") == nil then
            obj:SetAttribute("_OrigImgTransparency", obj.ImageTransparency)
        end
        if obj.ImageTransparency ~= 1 then obj.ImageTransparency = 1 end
    elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
        if obj:GetAttribute("_OrigTextTransparency") == nil then
            obj:SetAttribute("_OrigTextTransparency", obj.TextTransparency)
        end
        if obj.TextTransparency ~= 1 then obj.TextTransparency = 1 end
    end
end

local function showSlotNow(obj)
    if not obj or not obj.Parent then return end
    if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
        local orig = obj:GetAttribute("_OrigImgTransparency")
        obj.ImageTransparency = orig ~= nil and orig or 0
        obj:SetAttribute("_OrigImgTransparency", nil)
    elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
        local orig = obj:GetAttribute("_OrigTextTransparency")
        obj.TextTransparency = orig ~= nil and orig or 0
        obj:SetAttribute("_OrigTextTransparency", nil)
    end
end

local function lockText(label, value)
    if not label or not label:IsA("TextLabel") then return end

    if label:GetAttribute("_OrigTextTransparency") == nil then
        label:SetAttribute("_OrigTextTransparency", label.TextTransparency)
    end

    if label.Text ~= value then label.Text = value end

    if held[label] then return end
    held[label] = label:GetPropertyChangedSignal("Text"):Connect(function()
        if not anyTextSpoofOn() then
            releaseHeld(label)
            return
        end
        if label.Text ~= value then label.Text = value end
    end)
end

local function lockImage(img, value)
    if not img or not (img:IsA("ImageLabel") or img:IsA("ImageButton")) then return end

    if img:GetAttribute("_OrigImgTransparency") == nil then
        img:SetAttribute("_OrigImgTransparency", img.ImageTransparency)
    end

    if img.ImageTransparency ~= 1 then
        img.ImageTransparency = 1
    end

    if img.Image ~= value then img.Image = value end

    task.defer(function()
        if not isSpoofActive() then return end
        if img and img.Parent and img.ImageTransparency ~= 0 then
            img.ImageTransparency = 0
        end
    end)

    if held[img] then return end
    held[img] = img:GetPropertyChangedSignal("Image"):Connect(function()
        if not State.charEnabled then
            releaseHeld(img)
            return
        end
        if img.Image ~= value then
            img.ImageTransparency = 1
            img.Image = value
            task.defer(function()
                if img and img.Parent and isSpoofActive() then
                    img.ImageTransparency = 0
                end
            end)
        end
    end)
end

local function spoofImageSlot(obj, url)
    if not obj or not (obj:IsA("ImageLabel") or obj:IsA("ImageButton")) then return end
    hideSlotNow(obj)
    lockImage(obj, url)
end

local function spoofTextSlot(obj, value)
    if not obj or not (obj:IsA("TextLabel") or obj:IsA("TextButton")) then return end
    hideSlotNow(obj)
    lockText(obj, value)
    task.defer(function()
        if obj and obj.Parent and anyTextSpoofOn() then
            showSlotNow(obj)
        end
    end)
end

local SLOT_PARENT_NAMES = {
    ViewProfile = true,
    Player = true,
    SideParty = true,
    Party = true,
    PartyMemberSlot = true,
    LobbyButtonSlot = true,
    JoinQueuePadPlayerSlot = true,
    JoinQueuePadSlot = true,
    LocalQueuePlayerSlot = true,
    TeammateSlot = true,
    Career = true,
    DuelScoresTeamSlot = true,
    Teammates = true,
    QueuePadBoardGui = true,
    PartyDisplay = true,
    JoinQueuePadTeamSlot = true,
    BaseMatchmakingQueueSlot = true,
    PartyInviteSlot = true,
}

local IMAGE_SLOT_NAMES = {
    Headshot = true,
    Icon = true,
    PlayerIcon = true,
    Avatar = true,
    Portrait = true,
}

local TEXT_SLOT_NAMES = {
    DisplayName = true,
    Username = true,
    Player = true,
}

local function isMyImageSlot(img)
    if not img or not (img:IsA("ImageLabel") or img:IsA("ImageButton")) then
        return false
    end

    local cur = img.Image or ""
    if string.find(cur, tostring(LocalPlayer.UserId), 1, true) then
        return true
    end

    if IMAGE_SLOT_NAMES[img.Name] then
        local p = img.Parent
        local depth = 0
        while p and depth < 8 do
            if SLOT_PARENT_NAMES[p.Name] then
                return true
            end
            p = p.Parent
            depth = depth + 1
        end
    end

    return false
end

local function isMyTextSlot(lbl)
    if not lbl or not lbl:IsA("TextLabel") then return false end

    local txt = lbl.Text or ""
    if txt == LocalPlayer.Name or txt == LocalPlayer.DisplayName then
        return true
    end
    if txt == "@" .. LocalPlayer.Name then
        return true
    end

    if TEXT_SLOT_NAMES[lbl.Name] then
        local p = lbl.Parent
        local depth = 0
        while p and depth < 8 do
            if SLOT_PARENT_NAMES[p.Name] then
                return true
            end
            p = p.Parent
            depth = depth + 1
        end
    end

    return false
end

local function getUserIdFromName(username)
    if not username or username == "" then return nil end
    local ok, result = pcall(function()
        local body = HttpService:JSONEncode({ usernames = { username }, excludeBannedUsers = false })
        return HttpService:JSONDecode(game:HttpPost("https://users.roblox.com/v1/usernames/users", body, "application/json", true))
    end)
    if ok and result and result.data and result.data[1] then
        return result.data[1].id, result.data[1].name, result.data[1].displayName
    end
    return nil
end

local function getServerPlayerList()
    local list = {"None"}
    for _, p in ipairs(Players:GetPlayers()) do
        if p ~= LocalPlayer then table.insert(list, p.Name .. " (" .. tostring(p.UserId) .. ")") end
    end
    return list
end

local function parseUserId(str)
    if not str or str == "None" then return nil end
    local id = string.match(str, "%((%d+)%)")
    return id and tonumber(id) or nil
end

local R15_PARTS = {"Head","UpperTorso","LowerTorso","LeftUpperArm","LeftLowerArm","LeftHand","RightUpperArm","RightLowerArm","RightHand","LeftUpperLeg","LeftLowerLeg","LeftFoot","RightUpperLeg","RightLowerLeg","RightFoot"}

local function getCharParts(char)
    local c = {}
    if not char then return c end
    for _, name in ipairs(R15_PARTS) do c[name] = char:FindFirstChild(name) end
    return c
end

local function getAppearanceParts(app)
    local c = {}
    if not app then return c end
    for _, name in ipairs(R15_PARTS) do
        local p = app:FindFirstChild(name)
        if p then
            local isMesh = p:IsA("MeshPart")
            c[name] = { isMeshPart = isMesh, MeshId = isMesh and p.MeshId or nil, TextureID = isMesh and p.TextureID or nil, Color = p.Color }
        end
    end
    return c
end

local function attachAccessory(character, humanoid, accessory)
    local handle = accessory:FindFirstChild("Handle")
    if not handle then
        accessory.Parent = character
        return
    end

    handle.CanCollide = false
    handle.CanTouch = false
    handle.CanQuery = false
    handle.Massless = true
    handle.CastShadow = false

    local attachName = nil
    for _, att in ipairs(handle:GetChildren()) do
        if att:IsA("Attachment") then
            attachName = att.Name
            break
        end
    end

    accessory.Parent = character

    if attachName then
        local tAtt = character:FindFirstChild(attachName, true)
        if tAtt then
            local tPart = tAtt.Parent
            handle.CFrame = tAtt.WorldCFrame

            local weld = Instance.new("Weld")
            weld.Name = "AccessoryWeld"
            weld.Part0 = tPart
            weld.Part1 = handle

            local hAtt = handle:FindFirstChildOfClass("Attachment")
            weld.C0 = tAtt.CFrame
            weld.C1 = hAtt and hAtt.CFrame or CFrame.new()
            weld.Parent = handle
        end
    end

    handle.LocalTransparencyModifier = 0
    handle.Transparency = 0
end

local function fastApplyParts(char, app)
    if not char or not app then return end
    local charParts = getCharParts(char)
    local appParts = getAppearanceParts(app)
    for _, partName in ipairs(R15_PARTS) do
        local dst = charParts[partName]
        local src = appParts[partName]
        if dst and src and src.isMeshPart and dst:IsA("MeshPart") then
            if src.MeshId and src.MeshId ~= "" and dst.MeshId ~= src.MeshId then
                pcall(function() dst.MeshId = src.MeshId end)
            end
            if src.TextureID and src.TextureID ~= "" and dst.TextureID ~= src.TextureID then
                pcall(function() dst.TextureID = src.TextureID end)
            end
        end
    end
end

local function getLobbyAvatarPaths()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    local mf = pg and pg:FindFirstChild("MainGui") and pg.MainGui:FindFirstChild("MainFrame")
    if not mf then return {} end
    return {
        function()
            local a = mf:FindFirstChild("Lobby")
            a = a and a:FindFirstChild("Buttons")
            a = a and a:FindFirstChild("Container")
            a = a and a:FindFirstChild("List")
            a = a and a:FindFirstChild("LobbyButtonSlot")
            a = a and a:FindFirstChild("Button")
            a = a and a:FindFirstChild("Container")
            return a and a:FindFirstChild("Icon")
        end,
        function()
            local a = mf:FindFirstChild("Lobby")
            a = a and a:FindFirstChild("Party")
            a = a and a:FindFirstChild("BottomDisplay")
            a = a and a:FindFirstChild("Container")
            a = a and a:FindFirstChild("PartyMemberSlot")
            a = a and a:FindFirstChild("Button")
            return a and a:FindFirstChild("Icon")
        end,
        function()
            local a = mf:FindFirstChild("Pages")
            a = a and a:FindFirstChild("SideParty")
            a = a and a:FindFirstChild("Container")
            a = a and a:FindFirstChild("PartyMemberSlot")
            a = a and a:FindFirstChild("Button")
            return a and a:FindFirstChild("Icon")
        end,
        function()
            local a = mf:FindFirstChild("Lobby")
            a = a and a:FindFirstChild("Requests")
            a = a and a:FindFirstChild("Container")
            a = a and a:FindFirstChild("JoinQueuePadSlot")
            a = a and a:FindFirstChild("Container")
            a = a and a:FindFirstChild("Details")
            a = a and a:FindFirstChild("JoinQueuePadTeamSlot")
            a = a and a:FindFirstChild("Container")
            a = a and a:FindFirstChild("JoinQueuePadPlayerSlot")
            return a and a:FindFirstChild("Headshot")
        end,
        function()
            local a = mf:FindFirstChild("Equipment")
            a = a and a:FindFirstChild("Right")
            a = a and a:FindFirstChild("List")
            a = a and a:FindFirstChild("Container")
            a = a and a:FindFirstChild("PrimaryActions")
            a = a and a:FindFirstChild("Container")
            a = a and a:FindFirstChild("Career")
            return a and a:FindFirstChild("Icon")
        end,
        function()
            local a = mf:FindFirstChild("Queue")
            a = a and a:FindFirstChild("Container")
            a = a and a:FindFirstChild("Details")
            a = a and a:FindFirstChild("LocalQueuePlayerSlot")
            a = a and a:FindFirstChild("Container")
            a = a and a:FindFirstChild("TeammateSlot")
            a = a and a:FindFirstChild("Container")
            return a and a:FindFirstChild("Headshot")
        end,
        function()
            local a = mf:FindFirstChild("Queue")
            a = a and a:FindFirstChild("Container")
            a = a and a:FindFirstChild("Details")
            a = a and a:FindFirstChild("BaseMatchmakingQueueSlot")
            a = a and a:FindFirstChild("Container")
            a = a and a:FindFirstChild("TeammateSlot")
            a = a and a:FindFirstChild("Container")
            return a and a:FindFirstChild("Headshot")
        end,
        function()
            local a = mf:FindFirstChild("Lobby")
            a = a and a:FindFirstChild("Requests")
            a = a and a:FindFirstChild("Container")
            a = a and a:FindFirstChild("PartyInviteSlot")
            a = a and a:FindFirstChild("Button")
            a = a and a:FindFirstChild("Container")
            return a and a:FindFirstChild("Icon")
        end,
    }
end

local function hideSpoofedSlots()
    if not State.profileHideEnabled then return end
    if not isSpoofActive() then return end

    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then return end
    local mf = pg:FindFirstChild("MainGui") and pg.MainGui:FindFirstChild("MainFrame")
    if not mf then return end

    local MY_ID = tostring(LocalPlayer.UserId)
    local MY_NAME = LocalPlayer.Name
    local MY_DISPLAY = LocalPlayer.DisplayName

    local function check(obj)
        if not obj or not obj.Parent then return end
        if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
            local cur = obj.Image or ""
            if string.find(cur, MY_ID, 1, true) then
                obj.ImageTransparency = 1
            end
        elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
            local txt = obj.Text or ""
            if txt == MY_NAME or txt == MY_DISPLAY or txt == "@" .. MY_NAME then
                obj.TextTransparency = 1
            end
        end
    end

    local pages = mf:FindFirstChild("Pages")
    local vp = pages and pages:FindFirstChild("ViewProfile")
    local active = vp and vp:FindFirstChild("Active")
    if active then
        for _, v in ipairs(active:GetDescendants()) do check(v) end
    end

    local targets = {
        pages and pages:FindFirstChild("SideParty"),
        mf:FindFirstChild("Lobby") and mf.Lobby:FindFirstChild("Party"),
        mf:FindFirstChild("Lobby") and mf.Lobby:FindFirstChild("Requests"),
        mf:FindFirstChild("Queue"),
        mf:FindFirstChild("DuelInterfaces"),
        pg:FindFirstChild("PlayerList"),
    }
    for _, t in ipairs(targets) do
        if t then
            for _, v in ipairs(t:GetDescendants()) do check(v) end
        end
    end
end

local function spoofProfileUI()
    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then return end
    local mf = pg:FindFirstChild("MainGui") and pg.MainGui:FindFirstChild("MainFrame")
    if not mf then return end

    local pages = mf:FindFirstChild("Pages")
    local vp = pages and pages:FindFirstChild("ViewProfile")
    local active = vp and vp:FindFirstChild("Active")
    if not active then return end
    local player = active:FindFirstChild("Player")
    if not player then return end

    for _, v in ipairs(player:GetDescendants()) do
        if v:IsA("TextLabel") or v:IsA("TextButton") then
            local name = v.Name
            local txt = v.Text or ""

            if name == "Level" or name == "LevelValue" then
                if Cfg.Level.on then
                    spoofTextSlot(v, tostring(Cfg.Level.val))
                else
                    releaseHeld(v)
                end
            end

            if string.find(name, "Streak", 1, true) or string.find(name, "Winstreak", 1, true) or string.find(name, "WinStreak", 1, true) then
                if Cfg.Winstreak.on then
                    spoofTextSlot(v, tostring(Cfg.Winstreak.val))
                else
                    releaseHeld(v)
                end
            end

            if name == "Wins" or name == "CasualWins" or name == "DuelsWon" then
                if Cfg.CasualWins.on then
                    spoofTextSlot(v, tostring(Cfg.CasualWins.val))
                else
                    releaseHeld(v)
                end
            end

            if name == "WinPercent" or name == "WinRate" or name == "Percent" then
                if Cfg.CasualWinPercent.on then
                    spoofTextSlot(v, tostring(Cfg.CasualWinPercent.val) .. "%")
                else
                    releaseHeld(v)
                end
            end

            if name == "RankedWins" or string.find(name, "RankedWon", 1, true) then
                if Cfg.RankedWins.on then
                    spoofTextSlot(v, tostring(Cfg.RankedWins.val))
                else
                    releaseHeld(v)
                end
            end

            if string.find(name, "Ranked", 1, true) and (name == "WinPercent" or name == "WinRate") then
                if Cfg.RankedWinPercent.on then
                    spoofTextSlot(v, tostring(Cfg.RankedWinPercent.val) .. "%")
                else
                    releaseHeld(v)
                end
            end

            if name == "ELO" or name == "Elo" or name == "DisplayELO" or name == "Rating" then
                if Cfg.RankedElo.on then
                    spoofTextSlot(v, tostring(Cfg.RankedElo.val))
                else
                    releaseHeld(v)
                end
            end

            if name == "Rank" or name == "RankTier" or name == "Tier" or name == "RankName" then
                if Cfg.RankTier.on then
                    spoofTextSlot(v, Cfg.RankTier.val)
                else
                    releaseHeld(v)
                end
            end

            if name == "Map" or name == "FavoriteMap" then
                if Cfg.FavoriteMap.on and txt ~= "" then
                    spoofTextSlot(v, Cfg.FavoriteMap.val)
                else
                    releaseHeld(v)
                end
            end

            if name == "Status" or name == "Tag" or name == "NametagStatus" then
                if Cfg.NametagStatus.on then
                    spoofTextSlot(v, Cfg.NametagStatus.val)
                else
                    releaseHeld(v)
                end
            end
        end
    end

    local MY_NAME = LocalPlayer.Name
    local MY_DISPLAY = LocalPlayer.DisplayName

    local function isMyBadgeContainer(c)
        local p = c
        local depth = 0
        while p and depth < 8 do
            if p.Name == "Player" or p.Name == "ViewProfile" or p.Name == "Active" then
                return true
            end
            p = p.Parent
            depth = depth + 1
        end
        return false
    end

    local badgeContainers = {}
    local playerNode = active:FindFirstChild("Player")
    if playerNode then
        table.insert(badgeContainers, playerNode)
        for _, c in ipairs(playerNode:GetDescendants()) do
            if (c:IsA("Frame") or c:IsA("Folder")) and isMyBadgeContainer(c) then
                table.insert(badgeContainers, c)
            end
        end
    end

    for _, container in ipairs(badgeContainers) do
        for _, b in ipairs(container:GetDescendants()) do
            if b:IsA("ImageLabel") or b:IsA("ImageButton") then
                local n = string.lower(b.Name)
                local isBadge =
                    string.find(n, "influencer", 1, true)
                    or string.find(n, "employee", 1, true)
                    or string.find(n, "roblox", 1, true)
                    or string.find(n, "nosniy", 1, true)
                    or string.find(n, "team", 1, true)
                    or string.find(n, "verified", 1, true)
                    or string.find(n, "badge", 1, true)
                    or string.find(n, "tag", 1, true)
                    or string.find(n, "status", 1, true)

                if isBadge then
                    if b:GetAttribute("_OrigVisible") == nil then
                        b:SetAttribute("_OrigVisible", b.Visible)
                    end

                    local wantOn = false
                    if Cfg.Influencer.on and string.find(n, "influencer", 1, true) then
                        wantOn = true
                    elseif Cfg.RobloxEmployee.on and (string.find(n, "employee", 1, true) or string.find(n, "roblox", 1, true)) then
                        wantOn = true
                    elseif Cfg.NosniyTeam.on and (string.find(n, "nosniy", 1, true) or string.find(n, "team", 1, true)) then
                        wantOn = true
                    end

                    if wantOn then
                        b.Visible = true
                    else
                        local orig = b:GetAttribute("_OrigVisible")
                        if orig ~= nil then
                            b.Visible = orig
                        end
                    end
                end
            end
        end
    end
end

local function spoofStats()
    if PlayerDataCtrl then
        local data = PlayerDataCtrl.CurrentData and PlayerDataCtrl.CurrentData.Data
        if data then
            local function safeSet(key, val)
                pcall(function()
                    if PlayerDataCtrl.Set then PlayerDataCtrl:Set(key, val)
                    else data[key] = val end
                end)
            end

            if Cfg.Level.on then safeSet("Level", Cfg.Level.val) end
            if Cfg.Winstreak.on then
                safeSet("StatisticDuelsWinStreak", Cfg.Winstreak.val)
                safeSet("DuelsWinStreak", Cfg.Winstreak.val)
                safeSet("WinStreak", Cfg.Winstreak.val)
            end
            if Cfg.CasualWins.on then safeSet("StatisticDuelsWon", Cfg.CasualWins.val) end
            if Cfg.CasualWinPercent.on then safeSet("StatisticDuelsWinPercent", Cfg.CasualWinPercent.val / 100) end
            if Cfg.RankedWins.on then safeSet("StatisticRankedDuelsWon", Cfg.RankedWins.val) end
            if Cfg.RankedWinPercent.on then safeSet("StatisticRankedDuelsWinPercent", Cfg.RankedWinPercent.val / 100) end
            if Cfg.RankedElo.on then safeSet("RankedCurrentELO", Cfg.RankedElo.val) safeSet("DisplayELO", Cfg.RankedElo.val) end
            if Cfg.FavoriteMap.on then safeSet("StatisticFavoriteMap", Cfg.FavoriteMap.val) end
            if Cfg.Influencer.on then safeSet("IsInfluencer", true) end
            if Cfg.RobloxEmployee.on then safeSet("IsRobloxEmployee", true) end
            if Cfg.NosniyTeam.on then safeSet("GroupRank", 255) end
            if Cfg.RankTier.on then
                safeSet("RankTier", Cfg.RankTier.val)
                safeSet("DisplayRank", Cfg.RankTier.val)
            end
        end
    end

    pcall(function()
        if Cfg.Level.on then LocalPlayer:SetAttribute("Level", Cfg.Level.val) end
        if Cfg.Winstreak.on then LocalPlayer:SetAttribute("StatisticDuelsWinStreak", Cfg.Winstreak.val) end
        if Cfg.RankedElo.on then LocalPlayer:SetAttribute("DisplayELO", Cfg.RankedElo.val) end
        if Cfg.NametagStatus.on then LocalPlayer:SetAttribute("PlayerStatus", Cfg.NametagStatus.val) end
        if Cfg.RankTier.on then LocalPlayer:SetAttribute("RankTier", Cfg.RankTier.val) end
    end)

    pcall(spoofProfileUI)
end

local function cleanCharacter()
    local char = LocalPlayer.Character
    if not char then return end

    State.spoofLocks = setmetatable({}, { __mode = "k" })

    if State.hideConn then
        pcall(function() State.hideConn:Disconnect() end)
        State.hideConn = nil
    end

    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Accessory") or child:IsA("Hat")
            or child:IsA("Shirt") or child:IsA("Pants")
            or child:IsA("ShirtGraphic") or child:IsA("BodyColors")
            or child:IsA("CharacterMesh") then
            pcall(function() child:Destroy() end)
        end
    end

    local head = char:FindFirstChild("Head")
    if head then
        for _, child in ipairs(head:GetChildren()) do
            if child:IsA("Decal") and child.Name == "face" then
                pcall(function() child:Destroy() end)
            end
        end
    end

    for _, part in ipairs(char:GetDescendants()) do
        if part:IsA("BasePart") then
            pcall(function()
                part.Transparency = 0
                part.LocalTransparencyModifier = 0
            end)
        end
    end
end

local function applyCharacterParts(userId)
    local char = LocalPlayer.Character
    if not char then return end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    pcall(function()
        LocalPlayer.CharacterAppearanceId = userId
    end)

    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Accessory") or child:IsA("Shirt")
            or child:IsA("Pants") or child:IsA("ShirtGraphic")
            or child:IsA("BodyColors") or child:IsA("CharacterMesh") then
            child:Destroy()
        end
    end

    local appearance = State.charCache[userId]
    if not appearance then
        local ok, result = pcall(function()
            return Players:GetCharacterAppearanceAsync(userId)
        end)
        if ok and result then
            State.charCache[userId] = result
            appearance = result
        end
    end

    if not appearance then return end

    local charParts = getCharParts(char)
    local appParts = getAppearanceParts(appearance)
    for _, partName in ipairs(R15_PARTS) do
        local dst = charParts[partName]
        local src = appParts[partName]
        if dst and src and src.isMeshPart and dst:IsA("MeshPart") then
            if src.MeshId and src.MeshId ~= "" then
                pcall(function() dst.MeshId = src.MeshId end)
            end
            if src.TextureID and src.TextureID ~= "" then
                pcall(function() dst.TextureID = src.TextureID end)
            end
            if src.Color then
                pcall(function() dst.Color = src.Color end)
            end
        end
    end

    for _, v in ipairs(appearance:GetChildren()) do
        if v:IsA("Accessory") then
            local clone = v:Clone()
            pcall(function() attachAccessory(char, humanoid, clone) end)
        elseif v:IsA("Shirt") or v:IsA("Pants")
            or v:IsA("ShirtGraphic") or v:IsA("BodyColors") then
            v:Clone().Parent = char
        end
    end

    local head = char:FindFirstChild("Head")
    if head then
        local face = appearance:FindFirstChild("Head")
        if face then
            for _, dec in ipairs(face:GetChildren()) do
                if dec:IsA("Decal") then
                    local ex = head:FindFirstChild("face")
                    if ex then ex.Texture = dec.Texture
                    else
                        local nf = Instance.new("Decal")
                        nf.Name = "face" nf.Texture = dec.Texture nf.Parent = head
                    end
                    break
                end
            end
        end
    end
end

local function takeSnapshot()
    local char = LocalPlayer.Character
    if not char then return nil end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return nil end

    local snap = {
        userId = LocalPlayer.UserId,
        appearanceId = LocalPlayer.CharacterAppearanceId,
        parts = {},
        accessories = {},
        shirts = {},
        pants = {},
        graphics = {},
        bodyColors = nil,
        charMeshes = {},
        face = nil,
        humanoidDesc = nil,
    }

    pcall(function()
        snap.humanoidDesc = humanoid:GetAppliedDescription()
    end)

    for _, partName in ipairs(R15_PARTS) do
        local part = char:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            snap.parts[partName] = {
                className = part.ClassName,
                Color = part.Color,
                Transparency = part.Transparency,
                Size = part.Size,
                isMesh = part:IsA("MeshPart"),
                MeshId = part:IsA("MeshPart") and part.MeshId or nil,
                TextureID = part:IsA("MeshPart") and part.TextureID or nil,
                Material = part.Material,
            }
        end
    end

    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Accessory") or child:IsA("Hat") then
            table.insert(snap.accessories, {
                name = child.Name,
                className = child.ClassName,
                clone = child:Clone(),
            })
        elseif child:IsA("Shirt") then
            table.insert(snap.shirts, { name = child.Name, tpl = child.ShirtTemplate })
        elseif child:IsA("Pants") then
            table.insert(snap.pants, { name = child.Name, tpl = child.PantsTemplate })
        elseif child:IsA("ShirtGraphic") then
            table.insert(snap.graphics, { name = child.Name, tpl = child.Graphic })
        elseif child:IsA("BodyColors") then
            snap.bodyColors = child:Clone()
        elseif child:IsA("CharacterMesh") then
            table.insert(snap.charMeshes, child:Clone())
        end
    end

    local head = char:FindFirstChild("Head")
    if head then
        local face = head:FindFirstChild("face")
        if face and face:IsA("Decal") then
            snap.face = { name = face.Name, texture = face.Texture }
        end
    end

    return snap
end

local function applySnapshotOnce(snap)
    if not snap then return false end
    local char = LocalPlayer.Character
    if not char then return false end
    local humanoid = char:FindFirstChildOfClass("Humanoid")
    if not humanoid then return false end

    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Accessory") or child:IsA("Hat")
            or child:IsA("Shirt") or child:IsA("Pants")
            or child:IsA("ShirtGraphic") or child:IsA("BodyColors")
            or child:IsA("CharacterMesh") then
            pcall(function() child:Destroy() end)
        end
    end

    local head = char:FindFirstChild("Head")
    if head then
        for _, child in ipairs(head:GetChildren()) do
            if child:IsA("Decal") and child.Name == "face" then
                pcall(function() child:Destroy() end)
            end
        end
    end

    task.wait(0.05)

    for partName, pdata in pairs(snap.parts) do
        local part = char:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            pcall(function()
                part.Color = pdata.Color
                part.Transparency = pdata.Transparency
                part.Size = pdata.Size
                part.Material = pdata.Material
                part.LocalTransparencyModifier = 0
            end)
            if pdata.isMesh and part:IsA("MeshPart") then
                if pdata.MeshId and pdata.MeshId ~= "" then
                    pcall(function() part.MeshId = pdata.MeshId end)
                end
                if pdata.TextureID and pdata.TextureID ~= "" then
                    pcall(function() part.TextureID = pdata.TextureID end)
                end
            end
        end
    end

    for _, accData in ipairs(snap.accessories) do
        local clone = accData.clone:Clone()
        pcall(function() attachAccessory(char, humanoid, clone) end)
    end

    for _, s in ipairs(snap.shirts) do
        local shirt = Instance.new("Shirt")
        shirt.Name = s.name
        shirt.ShirtTemplate = s.tpl
        pcall(function() shirt.Parent = char end)
    end
    for _, p in ipairs(snap.pants) do
        local pants = Instance.new("Pants")
        pants.Name = p.name
        pants.PantsTemplate = p.tpl
        pcall(function() pants.Parent = char end)
    end
    for _, g in ipairs(snap.graphics) do
        local sg = Instance.new("ShirtGraphic")
        sg.Name = g.name
        sg.Graphic = g.tpl
        pcall(function() sg.Parent = char end)
    end

    if snap.bodyColors then
        pcall(function() snap.bodyColors:Clone().Parent = char end)
    end

    for _, cm in ipairs(snap.charMeshes) do
        pcall(function() cm:Clone().Parent = char end)
    end

    if head and snap.face then
        local face = head:FindFirstChild("face")
        if face then
            pcall(function() face.Texture = snap.face.texture end)
        else
            local nf = Instance.new("Decal")
            nf.Name = snap.face.name or "face"
            nf.Texture = snap.face.texture
            pcall(function() nf.Parent = head end)
        end
    end

    if snap.humanoidDesc then
        pcall(function()
            humanoid:ApplyDescription(snap.humanoidDesc, Enum.HumanoidDescriptionPriority.Player)
        end)
    end

    task.wait(0.2)

    for _, partName in ipairs(R15_PARTS) do
        local part = char:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            pcall(function()
                part.LocalTransparencyModifier = 0
                if part.Transparency >= 1 then
                    part.Transparency = 0
                end
            end)
        end
    end
    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Accessory") or child:IsA("Hat") then
            local h = child:FindFirstChild("Handle")
            if h then
                pcall(function()
                    h.LocalTransparencyModifier = 0
                    if h.Transparency >= 1 then
                        h.Transparency = 0
                    end
                end)
            end
        end
    end

    return true
end

local function lockPart(part, src)
    if not part or not src or not src.isMeshPart or not part:IsA("MeshPart") then return end
    if State.spoofLocks[part] then return end
    State.spoofLocks[part] = true
    part:GetPropertyChangedSignal("MeshId"):Connect(function()
        if not (State.charEnabled and State.charApplied) then return end
        if part.Parent and src.MeshId and src.MeshId ~= "" and part.MeshId ~= src.MeshId then
            pcall(function() part.MeshId = src.MeshId end)
        end
    end)
    part:GetPropertyChangedSignal("TextureID"):Connect(function()
        if not (State.charEnabled and State.charApplied) then return end
        if part.Parent and src.TextureID and src.TextureID ~= "" and part.TextureID ~= src.TextureID then
            pcall(function() part.TextureID = src.TextureID end)
        end
    end)
end

local function lockAllParts()
    local char = LocalPlayer.Character
    if not char then return end
    local userId = tonumber(State.charUserId)
    if not userId then return end
    local app = State.charCache[userId]
    if not app then return end
    local charParts = getCharParts(char)
    local appParts = getAppearanceParts(app)
    for _, partName in ipairs(R15_PARTS) do
        local part = charParts[partName]
        local src = appParts[partName]
        if part and src then lockPart(part, src) end
    end
end

local function applyPOVVisibility()
    if not (State.charEnabled and State.charUserId and State.charApplied) then return end
    local char = LocalPlayer.Character
    if not char then return end

    local isFirstPerson = false
    if CameraCtrl and CameraCtrl.CameraState then
        local ok, pov = pcall(function()
            return CameraCtrl.CameraState:GetPublicState()
        end)
        if ok and pov ~= nil then
            local states = CameraCtrl.CameraState.States
            if states and states.ThirdPerson then
                isFirstPerson = (pov ~= states.ThirdPerson)
            end
        end
    end

    if State._lastPov == isFirstPerson then return end
    State._lastPov = isFirstPerson

    local targetValue = isFirstPerson and 1 or 0

    for _, partName in ipairs(R15_PARTS) do
        local part = char:FindFirstChild(partName)
        if part and part:IsA("BasePart") then
            if part.LocalTransparencyModifier ~= targetValue then
                part.LocalTransparencyModifier = targetValue
            end
        end
    end

    for _, child in ipairs(char:GetChildren()) do
        if child:IsA("Accessory") then
            local handle = child:FindFirstChild("Handle")
            if handle and handle.LocalTransparencyModifier ~= targetValue then
                handle.LocalTransparencyModifier = targetValue
            end
        end
    end
end

SpoofTrove:Add(RunService.Heartbeat:Connect(function()
    if not (State.charEnabled and State.charUserId and State.charApplied) then return end
    applyPOVVisibility()
end))

local function applyAll(userId, data)
    if not isSpoofActive() then return end

    if not State.currentUrl then
        State.currentUrl = "https://www.roblox.com/headshot-thumbnail/image?userId=" .. userId .. "&width=420&height=420&format=png"
        State.currentDisplayName = data and (data.displayName or data.name) or "User"
        State.currentUsername = data and ("@" .. (data.name or ("User" .. data.id))) or "@User"
    end

    local url = State.currentUrl
    local newDisplayName = State.currentDisplayName
    local newUsername = State.currentUsername
    local MY_ID = tostring(LocalPlayer.UserId)
    local MY_NAME = LocalPlayer.Name
    local MY_DISPLAY = LocalPlayer.DisplayName

    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then return end
    local mf = pg:FindFirstChild("MainGui") and pg.MainGui:FindFirstChild("MainFrame")

    pcall(function()
        local pages = mf and mf:FindFirstChild("Pages")
        if not pages then return end
        local vp = pages:FindFirstChild("ViewProfile")
        local active = vp and vp:FindFirstChild("Active")
        local player = active and active:FindFirstChild("Player")
        if not player then return end

        local headshot = player:FindFirstChild("Headshot")
        if headshot then spoofImageSlot(headshot, url) end

        local dn = player:FindFirstChild("DisplayName")
        if dn then spoofTextSlot(dn, newDisplayName) end

        local un = player:FindFirstChild("Username")
        if un then spoofTextSlot(un, newUsername) end

        for _, v in ipairs(player:GetDescendants()) do
            if (v:IsA("ImageLabel") or v:IsA("ImageButton")) and v.Name == "Headshot" then
                spoofImageSlot(v, url)
            end
        end
    end)

    for _, getter in ipairs(getLobbyAvatarPaths()) do
        local img = getter()
        if img then spoofImageSlot(img, url) end
    end

    for _, gui in ipairs(pg:GetChildren()) do
        if gui:IsA("SurfaceGui") and string.find(gui.Name, "QueuePadBoardGui", 1, true) then
            for _, v in ipairs(gui:GetDescendants()) do
                if v:IsA("ImageLabel") or v:IsA("ImageButton") then
                    local cur = v.Image or ""
                    if string.find(cur, MY_ID, 1, true) or v.Name == "Headshot" or v.Name == "Icon" then
                        spoofImageSlot(v, url)
                    end
                elseif (v:IsA("TextLabel") or v:IsA("TextButton")) then
                    if v.Text == MY_NAME or v.Text == MY_DISPLAY then
                        spoofTextSlot(v, newDisplayName)
                    elseif v.Text == "@" .. MY_NAME then
                        spoofTextSlot(v, newUsername)
                    end
                end
            end
        end
    end

    if not mf then return end

    pcall(function()
        local di = mf:FindFirstChild("DuelInterfaces")
        local duel = di and di:FindFirstChild("DuelInterface")
        local top = duel and duel:FindFirstChild("Top")
        local scores = top and top:FindFirstChild("Scores")
        local teams = scores and scores:FindFirstChild("Teams")
        if not teams then return end
        for _, sideName in ipairs({"Left", "Right"}) do
            local side = teams:FindFirstChild(sideName)
            if side then
                local slot = side:FindFirstChild("DuelScoresTeamSlot")
                local cont = slot and slot:FindFirstChild("Container")
                local teammates = cont and cont:FindFirstChild("Teammates")
                if teammates then
                    for _, ts in ipairs(teammates:GetChildren()) do
                        if ts.Name == "TeammateSlot" then
                            local c = ts:FindFirstChild("Container")
                            local hs = c and c:FindFirstChild("Headshot")
                            if hs then
                                local cur = hs.Image or ""
                                if string.find(cur, MY_ID, 1, true) then
                                    spoofImageSlot(hs, url)
                                end
                            end
                        end
                    end
                end
            end
        end
    end)

    pcall(function()
        local bs = mf:FindFirstChild("BottomStack")
        local spec = bs and bs:FindFirstChild("Spectate")
        local scont = spec and spec:FindFirstChild("Container")
        local pl = scont and scont:FindFirstChild("Player")
        if pl and (pl.Text == MY_NAME or pl.Text == MY_DISPLAY) then
            spoofTextSlot(pl, newDisplayName)
        end
    end)

    pcall(function()
        local ii = mf:FindFirstChild("ItemInterfaces")
        if ii and data then
            for _, child in ipairs(ii:GetChildren()) do
                if string.find(child.Name, MY_NAME, 1, true) then
                    local newName = string.gsub(child.Name, MY_NAME, data.name or ("User" .. data.id))
                    pcall(function() child.Name = newName end)
                end
            end
        end
    end)

    pcall(function()
        local fi = mf:FindFirstChild("FighterInterfaces")
        if fi and data then
            for _, child in ipairs(fi:GetChildren()) do
                if child.Name == MY_NAME then
                    pcall(function() child.Name = data.name or ("User" .. data.id) end)
                end
            end
        end
    end)

    pcall(function()
        local pl = pg:FindFirstChild("PlayerList")
        if not pl then return end
        for _, v in ipairs(pl:GetDescendants()) do
            if v:IsA("TextLabel") then
                if v.Text == MY_NAME or v.Text == MY_DISPLAY then
                    spoofTextSlot(v, newDisplayName)
                elseif v.Text == "@" .. MY_NAME then
                    spoofTextSlot(v, newUsername)
                end
            elseif v:IsA("ImageLabel") then
                local cur = v.Image or ""
                if string.find(cur, MY_ID, 1, true) then
                    spoofImageSlot(v, url)
                end
            end
        end
    end)

    pcall(function()
        local frames = {}
        local pages = mf:FindFirstChild("Pages")
        local sp = pages and pages:FindFirstChild("SideParty")
        if sp then table.insert(frames, sp) end
        local lp = mf:FindFirstChild("Lobby") and mf.Lobby:FindFirstChild("Party")
        if lp then table.insert(frames, lp) end
        for _, frame in ipairs(frames) do
            for _, v in ipairs(frame:GetDescendants()) do
                if v:IsA("TextLabel") then
                    if v.Text == MY_NAME or v.Text == MY_DISPLAY then
                        spoofTextSlot(v, newDisplayName)
                    elseif v.Text == "@" .. MY_NAME then
                        spoofTextSlot(v, newUsername)
                    end
                elseif v:IsA("ImageLabel") then
                    local cur = v.Image or ""
                    if string.find(cur, MY_ID, 1, true) then
                        spoofImageSlot(v, url)
                    end
                end
            end
        end
    end)

    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local nametag = hrp:FindFirstChild("NametagGui")
        if not nametag then return end
        local elements = nametag:FindFirstChild("Elements")
        local nd = elements and elements:FindFirstChild("NameDisplay")
        if not nd then return end
        local dnL = nd:FindFirstChild("DisplayName")
        local unL = nd:FindFirstChild("Username")
        if dnL then spoofTextSlot(dnL, newDisplayName) end
        if unL then spoofTextSlot(unL, newUsername) end
    end)

    pcall(function()
        local char = LocalPlayer.Character
        if not char then return end
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local label = hrp:FindFirstChild("TeammateLabel")
        if not label then return end
        for _, c in ipairs(label:GetDescendants()) do
            if c:IsA("ImageLabel") then
                local cur = c.Image or ""
                if string.find(cur, MY_ID, 1, true) then
                    spoofImageSlot(c, url)
                end
            end
        end
    end)
end

local function attachContainerWatcher(container)
    if not container then return end
    if State._profileWatchers[container] then return end
    State._profileWatchers[container] = true

    SpoofTrove:Add(container.Destroying:Connect(function()
        State._profileWatchers[container] = nil
    end))

    local pending = false
    SpoofTrove:Add(container.DescendantAdded:Connect(function(child)
        if not isSpoofActive() then return end
        if not container.Visible then return end

        local isMine = false
        if isMyImageSlot(child) or isMyTextSlot(child) then
            isMine = true
            hideSlotNow(child)
        end
        if not isMine then return end

        if pending then return end
        pending = true
        task.delay(0.1, function()
            pending = false
            if isSpoofActive() then
                pcall(function() applyAll(State.charUserId, State.charApplied) end)
            end
        end)
    end))
end

local function attachProfileWatcher()
    if not isSpoofActive() then return end

    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    local mf = pg and pg:FindFirstChild("MainGui") and pg.MainGui:FindFirstChild("MainFrame")
    if not mf then return end
    local pages = mf:FindFirstChild("Pages")
    local vp = pages and pages:FindFirstChild("ViewProfile")
    if not vp then return end

    local active = vp:FindFirstChild("Active")
    if not active then return end

    attachContainerWatcher(active)

    if State._profileWatchers[active .. "_visible"] then return end
    State._profileWatchers[active .. "_visible"] = true

    SpoofTrove:Add(active:GetPropertyChangedSignal("Visible"):Connect(function()
        if not isSpoofActive() then return end
        if not active.Visible then return end

        task.spawn(function()
            local tries = 0
            local startTime = tick()
            while tries < 15 and (tick() - startTime) < 2 do
                if not isSpoofActive() then break end
                pcall(function() applyAll(State.charUserId, State.charApplied) end)
                pcall(spoofStats)
                pcall(spoofProfileUI)
                task.wait(0.03)
                tries = tries + 1
            end
        end)
    end))
end

local function attachAllWatchers()
    if not isSpoofActive() then return end

    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    if not pg then return end
    local mf = pg:FindFirstChild("MainGui") and pg.MainGui:FindFirstChild("MainFrame")
    if not mf then return end
    local pages = mf:FindFirstChild("Pages")

    attachProfileWatcher()

    local vp = pages and pages:FindFirstChild("ViewProfile")
    local vpActive = vp and vp:FindFirstChild("Active")
    if vpActive then
        attachContainerWatcher(vpActive)
        SpoofTrove:Add(vpActive.DescendantAdded:Connect(function()
            if not isSpoofActive() then return end
            task.defer(function()
                pcall(spoofStats)
                pcall(spoofProfileUI)
            end)
        end))
    end

    local sp = pages and pages:FindFirstChild("SideParty")
    if sp then attachContainerWatcher(sp) end

    local lp = mf:FindFirstChild("Lobby") and mf.Lobby:FindFirstChild("Party")
    if lp then attachContainerWatcher(lp) end

    local lr = mf:FindFirstChild("Lobby") and mf.Lobby:FindFirstChild("Requests")
    if lr then attachContainerWatcher(lr) end

    local q = mf:FindFirstChild("Queue")
    if q then attachContainerWatcher(q) end

    local di = mf:FindFirstChild("DuelInterfaces")
    if di then attachContainerWatcher(di) end

    local pl = pg:FindFirstChild("PlayerList")
    if pl then attachContainerWatcher(pl) end

    for _, gui in ipairs(pg:GetChildren()) do
        if gui:IsA("SurfaceGui") and string.find(gui.Name, "QueuePadBoardGui", 1, true) then
            attachContainerWatcher(gui)
        end
    end
end

SpoofTrove:Add(task.spawn(function()
    while task.wait(1) do
        if isSpoofActive() then
            pcall(attachAllWatchers)
        end
    end
end))

local function startCharResetWatcher(char)
    if not char then return end
    if State.resetWatchConn then
        pcall(function() State.resetWatchConn:Disconnect() end)
    end
    State.resetWatchConn = char.DescendantAdded:Connect(function(child)
        if not (State.charEnabled and State.charApplied) then return end
        if child:IsA("MeshPart") or child:IsA("Accessory") then
            local app = State.charCache[tonumber(State.charUserId)]
            if app then
                task.defer(function() fastApplyParts(char, app) end)
            end
        end
    end)
    SpoofTrove:Add(State.resetWatchConn)
end

SpoofTrove:Add(LocalPlayer.CharacterAdded:Connect(function(char)
    State.spoofLocks = setmetatable({}, { __mode = "k" })
    State._lastPov = nil
    if not (State.charEnabled and State.charUserId) then return end

    local userId = tonumber(State.charUserId)
    if not userId then return end

    task.spawn(function()
        local humanoid = char:WaitForChild("Humanoid", 5)
        if not humanoid then return end

        local startTime = tick()
        while tick() - startTime < 3 do
            if not State.charEnabled then break end
            if not char.Parent then break end
            local ready = true
            for _, partName in ipairs(R15_PARTS) do
                if not char:FindFirstChild(partName) then
                    ready = false
                    break
                end
            end
            if ready then break end
            task.wait(0.02)
        end

        if not State.charEnabled then return end

        applyCharacterParts(userId)
        applyAll(userId, State.charApplied)
        State._lastPov = nil
        applyPOVVisibility()
    end)
end))

SpoofTrove:Add(RunService.Heartbeat:Connect(function(dt)
    if not (State.charEnabled and State.charUserId and State.charApplied) then return end
    local char = LocalPlayer.Character
    if not char then return end
    local app = State.charCache[tonumber(State.charUserId)]
    if not app then return end

    State._partScanAcc = (State._partScanAcc or 0) + dt
    if State._partScanAcc >= 0.1 then
        State._partScanAcc = 0
        fastApplyParts(char, app)
    end
end))

local charTargetInput
local playerDropRef

local function resetDropdownToNone()
    if not playerDropRef then return end
    pcall(function()
        if playerDropRef.Set then
            playerDropRef:Set("None")
        elseif playerDropRef.SetValue then
            playerDropRef:SetValue("None")
        end
    end)
end

local function applyCharSpoof()
    if not State.charEnabled or not State.charUserId then return end

    if not State._originalSnapshot then
        local snap = takeSnapshot()
        if snap then
            State._originalSnapshot = snap
            Library:Notify("Original appearance saved", 2)
        end
    end

    if State._spoofing then
        State._spoofing = false
        task.wait(0.2)
    end
    State._spoofing = true

    task.spawn(function()
        local userId = tonumber(State.charUserId)
        if not userId then
            State._spoofing = false
            return
        end

        if State.charApplied then
            cleanCharacter()
            task.wait(0.15)
        end

        local data = State.charCache["user_" .. userId]
        if not data then
            data = { id = userId, name = "User" .. userId, displayName = "User" .. userId }
            pcall(function()
                local raw = game:HttpGet("https://users.roblox.com/v1/users/" .. tostring(userId), true)
                local dec = HttpService:JSONDecode(raw)
                if type(dec) == "table" and dec.id then
                    data = { id = dec.id, name = dec.name or ("User"..userId), displayName = dec.displayName or dec.name or ("User"..userId) }
                end
            end)
            State.charCache["user_" .. userId] = data
        end

        State.charApplied = data
        State.currentUrl = nil
        State.currentDisplayName = nil
        State.currentUsername = nil
        State._lastPov = nil

        applyCharacterParts(userId)
        applyAll(userId, data)
        task.wait(0.3)
        lockAllParts()
        applyPOVVisibility()

        local char = LocalPlayer.Character
        if char then
            startCharResetWatcher(char)
        end

        State._spoofing = false
        Library:Notify("Spoofed: " .. (data.displayName or data.name), 3)
    end)
end

local function restoreCharSpoof()
    State._spoofing = false
    State.charEnabled = false
    State.charApplied = nil
    State.spoofLocks = setmetatable({}, { __mode = "k" })
    State.currentUrl = nil
    State.currentDisplayName = nil
    State.currentUsername = nil
    State._lastPov = nil

    if State.resetWatchConn then
        pcall(function() State.resetWatchConn:Disconnect() end)
        State.resetWatchConn = nil
    end
    if State.hideConn then
        pcall(function() State.hideConn:Disconnect() end)
        State.hideConn = nil
    end

    releaseAllHeld()

    pcall(function()
        LocalPlayer.CharacterAppearanceId = LocalPlayer.UserId
    end)

    local snap = State._originalSnapshot
    if not snap then
        Library:Notify("Spoofer disabled", 2)
        return
    end

    if State._restoreThread then
        pcall(function() task.cancel(State._restoreThread) end)
        State._restoreThread = nil
    end

    task.spawn(function()
        pcall(function() applySnapshotOnce(snap) end)
        State._originalSnapshot = nil
        State._restoreThread = nil
        Library:Notify("Original character restored", 2)
    end)
end

local applyAcc = 0
SpoofTrove:Add(RunService.Heartbeat:Connect(function(dt)
    if not isSpoofActive() then return end

    applyAcc = applyAcc + dt
    if applyAcc < 0.5 then return end
    applyAcc = 0

    local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
    local mf = pg and pg.MainGui and pg.MainGui.MainFrame
    if not mf then return end

    local lobby = mf:FindFirstChild("Lobby")
    local pages = mf:FindFirstChild("Pages")
    local sideParty = pages and pages:FindFirstChild("SideParty")
    local vp = pages and pages:FindFirstChild("ViewProfile")
    local vpActive = vp and vp:FindFirstChild("Active")

    local uiOpen = (lobby and lobby.Visible)
        or (sideParty and sideParty.Visible)
        or (vpActive and vpActive.Visible)

    if not uiOpen then return end

    applyAll(State.charUserId, State.charApplied)
end))

local statsAcc = 0
SpoofTrove:Add(RunService.Heartbeat:Connect(function(dt)
    statsAcc = statsAcc + dt
    if statsAcc < 0.5 then return end
    statsAcc = 0

    if Cfg.Level.on or Cfg.Winstreak.on or Cfg.CasualWins.on or Cfg.RankedWins.on
       or Cfg.CasualWinPercent.on or Cfg.RankedWinPercent.on or Cfg.RankedElo.on
       or Cfg.FavoriteMap.on or Cfg.NametagStatus.on or Cfg.Influencer.on
       or Cfg.RobloxEmployee.on or Cfg.NosniyTeam.on or Cfg.RankTier.on then
        spoofStats()
    end
end))

SpoofTrove:Add(RunService.Heartbeat:Connect(function()
    pcall(hideSpoofedSlots)
end))

local identityAcc = 0
SpoofTrove:Add(RunService.Heartbeat:Connect(function(dt)
    identityAcc = identityAcc + dt
    if identityAcc < 1 then return end
    identityAcc = 0
    if Cfg.Name.on and LocalPlayer.Name ~= tostring(Cfg.Name.val) then
        pcall(function() LocalPlayer.Name = tostring(Cfg.Name.val) end)
    end
    if Cfg.DisplayName.on and LocalPlayer.DisplayName ~= tostring(Cfg.DisplayName.val) then
        pcall(function() LocalPlayer.DisplayName = tostring(Cfg.DisplayName.val) end)
    end
end))

local CharBox = Spoofer:AddGroupbox({ Name = "Character Spoofer", Side = 2 })
CharBox:AddToggle("CharSpoofEnable", {
    Text = "Enable", Default = false,
    Callback = function(v)
        State.charEnabled = v
        if v then applyCharSpoof() else restoreCharSpoof() end
    end,
})

charTargetInput = CharBox:AddInput("CharTargetInput", {
    Text = "Username or User ID", Default = "", Placeholder = "e.g. builderman or 1",
    Finished = true,
    Callback = function(v)
        if not v or v == "" then return end

        if State._inputDebounce then
            pcall(function() task.cancel(State._inputDebounce) end)
            State._inputDebounce = nil
        end

        resetDropdownToNone()

        State._lastInputValue = v

        State._inputDebounce = task.delay(0.35, function()
            State._inputDebounce = nil

            local asNum = tonumber(v)
            if asNum and asNum > 0 then
                State.charUserId = asNum
                Library:Notify("User ID: " .. asNum, 3)
            else
                Library:Notify("Searching: " .. v, 2)
                local id, name, display = getUserIdFromName(v)
                if id then
                    State.charUserId = id
                    Library:Notify("Found: " .. (display or name) .. " (" .. id .. ")", 3)
                else
                    Library:Notify("User not found: " .. v, 3)
                    return
                end
            end
            if State.charEnabled then applyCharSpoof() end
        end)
    end,
})

playerDropRef = CharBox:AddDropdown("CharTargetDrop", {
    Text = "Server Player",
    Values = getServerPlayerList(),
    Default = "None",
    Multi = false,
    Callback = function(v)
        if not v or v == "None" then return end

        local id = parseUserId(v)
        if id then
            State.charUserId = id
            State._lastInputValue = v

            if charTargetInput then
                pcall(function()
                    if charTargetInput.Set then
                        charTargetInput:Set("")
                    elseif charTargetInput.SetValue then
                        charTargetInput:SetValue("")
                    end
                end)
            end

            if State.charEnabled then applyCharSpoof() end
        end
    end,
})

CharBox:AddButton("RefreshPlayerList", {
    Text = "Refresh",
    Callback = function()
        if playerDropRef then
            local list = getServerPlayerList()
            if playerDropRef.Refresh then pcall(function() playerDropRef:Refresh(list) end)
            elseif playerDropRef.SetValues then pcall(function() playerDropRef:SetValues(list) end) end
        end
    end,
})

local IDBox = Spoofer:AddGroupbox({ Name = "Identity", Side = 2 })
IDBox:AddToggle("NameToggle", { Text = "Name", Default = false, Callback = function(v) Cfg.Name.on = v end })
IDBox:AddInput("NameInput", { Text = "Name", Default = "Minho", Finished = true, Callback = function(v) Cfg.Name.val = v end })
IDBox:AddToggle("DNToggle", { Text = "Display Name", Default = false, Callback = function(v) Cfg.DisplayName.on = v end })
IDBox:AddInput("DNInput", { Text = "Display Name", Default = "Minho", Finished = true, Callback = function(v) Cfg.DisplayName.val = v end })

local ProfBox = Spoofer:AddGroupbox({ Name = "Profile", Side = 2 })
ProfBox:AddToggle("FMToggle", { Text = "Favorite Map", Default = false, Callback = function(v) Cfg.FavoriteMap.on = v spoofStats() end })
ProfBox:AddDropdown("FMDrop", { Text = "Map", Values = MAPS, Default = "Arena", Multi = false, Callback = function(v) Cfg.FavoriteMap.val = v spoofStats() end })
ProfBox:AddToggle("NTToggle", { Text = "Nametag Status", Default = false, Callback = function(v) Cfg.NametagStatus.on = v spoofStats() end })
ProfBox:AddDropdown("NTDrop", { Text = "Status", Values = TAGS, Default = "Prime", Multi = false, Callback = function(v) Cfg.NametagStatus.val = v spoofStats() end })

local RankBox = Spoofer:AddGroupbox({ Name = "Rank", Side = 2 })
RankBox:AddToggle("RankToggle", { Text = "Rank Tier", Default = false, Callback = function(v) Cfg.RankTier.on = v spoofStats() end })
RankBox:AddDropdown("RankDrop", { Text = "Tier", Values = TIERS, Default = "Archnemesis", Multi = false, Callback = function(v) Cfg.RankTier.val = v spoofStats() end })
RankBox:AddToggle("ELOToggle", { Text = "Ranked ELO", Default = false, Callback = function(v) Cfg.RankedElo.on = v spoofStats() end })
RankBox:AddInput("ELOInput", { Text = "Ranked ELO", Default = "3600", Numeric = true, Finished = true, Callback = function(v) local n=tonumber(v) if n then Cfg.RankedElo.val = n spoofStats() end end })

local StatBox = Spoofer:AddGroupbox({ Name = "Stats", Side = 1 })
StatBox:AddToggle("LevelToggle", { Text = "Level", Default = false, Callback = function(v) Cfg.Level.on = v spoofStats() end })
StatBox:AddInput("LevelInput", { Text = "Level", Default = "999", Numeric = true, Finished = true, Callback = function(v) local n=tonumber(v) if n then Cfg.Level.val = n spoofStats() end end })
StatBox:AddToggle("WSToggle", { Text = "Winstreak", Default = false, Callback = function(v) Cfg.Winstreak.on = v spoofStats() end })
StatBox:AddInput("WSInput", { Text = "Winstreak", Default = "999", Numeric = true, Finished = true, Callback = function(v) local n=tonumber(v) if n then Cfg.Winstreak.val = n spoofStats() end end })
StatBox:AddToggle("CWinsToggle", { Text = "Casual Wins", Default = false, Callback = function(v) Cfg.CasualWins.on = v spoofStats() end })
StatBox:AddInput("CWinsInput", { Text = "Casual Wins", Default = "9999", Numeric = true, Finished = true, Callback = function(v) local n=tonumber(v) if n then Cfg.CasualWins.val = n spoofStats() end end })
StatBox:AddToggle("CWPToggle", { Text = "Casual Win %", Default = false, Callback = function(v) Cfg.CasualWinPercent.on = v spoofStats() end })
StatBox:AddSlider("CWPInput", { Text = "Casual Win %", Default = 100, Min = 0, Max = 100, Rounding = 1, Suffix = "%", Callback = function(v) Cfg.CasualWinPercent.val = v spoofStats() end })
StatBox:AddToggle("RWinsToggle", { Text = "Ranked Wins", Default = false, Callback = function(v) Cfg.RankedWins.on = v spoofStats() end })
StatBox:AddInput("RWinsInput", { Text = "Ranked Wins", Default = "9999", Numeric = true, Finished = true, Callback = function(v) local n=tonumber(v) if n then Cfg.RankedWins.val = n spoofStats() end end })
StatBox:AddToggle("RWPToggle", { Text = "Ranked Win %", Default = false, Callback = function(v) Cfg.RankedWinPercent.on = v spoofStats() end })
StatBox:AddSlider("RWPInput", { Text = "Ranked Win %", Default = 100, Min = 0, Max = 100, Rounding = 1, Suffix = "%", Callback = function(v) Cfg.RankedWinPercent.val = v spoofStats() end })

local BadgeBox = Spoofer:AddGroupbox({ Name = "Badges", Side = 1 })
BadgeBox:AddToggle("InfToggle", { Text = "Influencer", Default = false, Callback = function(v) Cfg.Influencer.on = v spoofStats() end })
BadgeBox:AddToggle("RobToggle", { Text = "Roblox Employee", Default = false, Callback = function(v) Cfg.RobloxEmployee.on = v spoofStats() end })
BadgeBox:AddToggle("NosToggle", { Text = "Nosniy Team", Default = false, Callback = function(v) Cfg.NosniyTeam.on = v spoofStats() end })

local HideBox = Spoofer:AddGroupbox({ Name = "Hide", Side = 1 })
HideBox:AddToggle("HideSpoofedToggle", {
    Text = "Hide Spoofed Slots",
    Default = true,
    Callback = function(v)
        State.profileHideEnabled = v
        if not v and isSpoofActive() then
            local pg = LocalPlayer:FindFirstChildOfClass("PlayerGui")
            if pg then
                for _, obj in ipairs(pg:GetDescendants()) do
                    if obj:IsA("ImageLabel") or obj:IsA("ImageButton") then
                        if obj:GetAttribute("_OrigImgTransparency") ~= nil then
                            obj.ImageTransparency = obj:GetAttribute("_OrigImgTransparency")
                            obj:SetAttribute("_OrigImgTransparency", nil)
                        end
                    elseif obj:IsA("TextLabel") or obj:IsA("TextButton") then
                        if obj:GetAttribute("_OrigTextTransparency") ~= nil then
                            obj.TextTransparency = obj:GetAttribute("_OrigTextTransparency")
                            obj:SetAttribute("_OrigTextTransparency", nil)
                        end
                    end
                end
            end
        end
    end,
})

if Library and Library.OnUnload then
    Library:OnUnload(function()
        if State._restoreThread then
            pcall(function() task.cancel(State._restoreThread) end)
        end
        if State._inputDebounce then
            pcall(function() task.cancel(State._inputDebounce) end)
        end
        releaseAllHeld()
        SpoofTrove:Destroy()
    end)
end
