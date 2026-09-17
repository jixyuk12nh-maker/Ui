local InfoModifier = {
    changes = {},
    originals = {},
    FIELD_ALIASES = {
        Recoil = { "ShootRecoil" },
        NoSpread = { "ShootSpread", "ShootAccuracy", "AimSpreadMultiplier" },
        FireCooldown = { "ShootCooldown", "ShootBurstCooldown" },
        MeleeCooldown = { "AttackCooldown", "SwingCooldown", "MeleeCooldown",
                          "Cooldown", "RecoveryTime", "ResetTime" },
    },
}

local function rememberField(tbl, field)
    local entry = InfoModifier.originals[tbl]
    if not entry then entry = {} InfoModifier.originals[tbl] = entry end
    if entry[field] == nil then entry[field] = tbl[field] end
end

local function applyToBlock(block, isMelee)
    if typeof(block) ~= "table" then return end
    for key, change in pairs(InfoModifier.changes) do
        local allowed = (key == "MeleeCooldown" and isMelee)
            or (key ~= "MeleeCooldown" and not isMelee)
        if allowed then
            local aliases = InfoModifier.FIELD_ALIASES[key]
            if aliases then
                for _, field in ipairs(aliases) do
                    local current = rawget(block, field)
                    if current ~= nil then
                        rememberField(block, field)
                        local base = InfoModifier.originals[block][field]
                        if change == nil then
                            block[field] = base
                        elseif change.percentage and type(base) == "number" then
                            block[field] = base * change.percentage
                        elseif change.value ~= nil then
                            block[field] = change.value
                        end
                    end
                end
            end
        end
    end
end

local function collectLiveInfos()
    local seen = {}
    local out = {}
    local fighter = LocalPlayer.Character
    local ps = LocalPlayer:FindFirstChild("PlayerScripts")
    local controllers = ps and ps:FindFirstChild("Controllers")
    local fc = controllers and controllers:FindFirstChild("FighterController")
    if fc then
        local ok, mod = pcall(require, fc)
        if ok and typeof(mod) == "table" then
            local live = rawget(mod, "LocalFighter")
            if typeof(live) == "table" then
                local items = rawget(live, "Items")
                if typeof(items) == "table" then
                    for _, item in pairs(items) do
                        local info = itemField(item, "Info")
                        if typeof(info) == "table" and not seen[info] then
                            seen[info] = true
                            table.insert(out, info)
                        end
                    end
                end
                local equipped = rawget(live, "EquippedItem")
                if typeof(equipped) == "table" then
                    local info = itemField(equipped, "Info")
                    if typeof(info) == "table" and not seen[info] then
                        seen[info] = true
                        table.insert(out, info)
                    end
                end
            end
        end
    end
    if typeof(getgc) == "function" then
        local ok = pcall(function()
            for _, obj in ipairs(getgc(true)) do
                if typeof(obj) == "table" and rawget(obj, "ShootRecoil") ~= nil
                    and rawget(obj, "ShootCooldown") ~= nil and not seen[obj] then
                    seen[obj] = true
                    table.insert(out, obj)
                end
            end
        end)
    end
    return out
end

local function itemField(item, key)
    if item == nil then return nil end
    local ok, value = pcall(function() return item[key] end)
    if ok then return value end
    return nil
end

local function reapply()
    local items = getRivalsItems()
    if items then
        for name, block in pairs(items) do
            local isMelee = MELEE_WHITELIST[name] == true
            applyToBlock(block, isMelee)
        end
    end
    for _, block in ipairs(collectLiveInfos()) do
        applyToBlock(block, false)
    end
    return true
end

local function SetChange(key, change)
    if change == nil then
        InfoModifier.changes[key] = nil
        local aliases = InfoModifier.FIELD_ALIASES[key]
        if aliases then
            for tbl, fields in pairs(InfoModifier.originals) do
                for _, field in ipairs(aliases) do
                    if fields[field] ~= nil then
                        pcall(function() tbl[field] = fields[field] end)
                        fields[field] = nil
                    end
                end
            end
        end
        return
    end
    InfoModifier.changes[key] = change
    reapply()
end

local function restoreAllItemData()
    local items = getRivalsItems()
    if items then
        for name, data in pairs(items) do
            local orig = originalData[name]
            if orig and typeof(data) == "table" then
                for k, v in pairs(orig) do
                    if v ~= nil then data[k] = v end
                end
            end
        end
    end
    table.clear(InfoModifier.originals)
end

local function reapplyItemData()
    if game.GameId ~= RIVALS_GAMEID then return end
    restoreAllItemData()
    reapply()
end
