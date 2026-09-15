local HOME_DIR = "Minho Hub/"
local CONFIG_DIR = HOME_DIR .. "Config/"
local function ensureFolder(path)
    if makefolder then
        if isfolder then
            if not isfolder(path) then pcall(makefolder, path) end
        else
            pcall(makefolder, path)
        end
    end
end
ensureFolder(HOME_DIR)
ensureFolder(CONFIG_DIR)

-- Source
do
    repeat task.wait() until game:IsLoaded()

    local function safeRef(ref)
    	return cloneref and cloneref(ref) or ref
    end

    local setidentity = setthreadcontext or setthreadidentity or set_thread_identity or set_thread_context or setidentity

    local RunService= safeRef(game:GetService("RunService"))
    local UserInputService= safeRef(game:GetService("UserInputService"))
    local CoreGui= safeRef(game:GetService("CoreGui"))
    local HttpService= safeRef(game:GetService("HttpService"))

    LPH_NO_VIRTUALIZE = function(f) return f end
    LPH_NO_UPVALUES = function(f) return f end

    local Trove = LPH_NO_VIRTUALIZE(function()

    local FN_MARKER = newproxy()
    local THREAD_MARKER = newproxy()
    local GENERIC_OBJECT_CLEANUP_METHODS = table.freeze({ "Destroy", "Disconnect", "destroy", "disconnect" })

    local function GetObjectCleanupFunction(object, cleanupMethod)
    	local t = typeof(object)

    	if t == "function" then
    		return FN_MARKER
    	elseif t == "thread" then
    		return THREAD_MARKER
    	end

    	if cleanupMethod then
    		return cleanupMethod
    	end

    	if t == "Instance" then
    		return "Destroy"
    	elseif t == "RBXScriptConnection" then
    		return "Disconnect"
    	elseif t == "table" then
    		for _, genericCleanupMethod in GENERIC_OBJECT_CLEANUP_METHODS do
    			if typeof(object[genericCleanupMethod]) == "function" then
    				return genericCleanupMethod
    			end
    		end
    	end

    	error(("failed to get cleanup function for object %s: %s"):format(t, object), 3)
    end

    local function AssertPromiseLike(object)
    	if
    		typeof(object) ~= "table"
    		or typeof(object.getStatus) ~= "function"
    		or typeof(object.finally) ~= "function"
    		or typeof(object.cancel) ~= "function"
    	then
    		error("did not receive a promise as an argument", 3)
    	end
    end
    local Trove = {}
    Trove.__index = Trove
    function Trove.new()
    local self = setmetatable({}, Trove)

    	self._objects = {}
    	self._cleaning = false

    	return (self )
    end






    function Trove.Add(self, object, cleanupMethod)
    if self._cleaning then
    		error("cannot call trove:Add() while cleaning", 2)
    	end

    	local cleanup = GetObjectCleanupFunction(object, cleanupMethod)
    	table.insert(self._objects, { object, cleanup })

    	return object
    end
    function Trove.Clone(self, instance)
    if self._cleaning then
    		error("cannot call trove:Clone() while cleaning", 2)
    	end

    	return self:Add(instance:Clone())
    end



    function Trove.Construct(self, class, ...)
    	if self._cleaning then
    		error("Cannot call trove:Construct() while cleaning", 2)
    	end

    	local object = nil
    	local t = type(class)
    	if t == "table" then
    		object = (class ).new(...)
    	elseif t == "function" then
    		object = (class )(...)
    	end

    	return self:Add(object)
    end
    function Trove.Connect(self, signal, fn)
    	if self._cleaning then
    		error("Cannot call trove:Connect() while cleaning", 2)
    	end

    	return self:Add(signal:Connect(fn))
    end

    function Trove.BindToRenderStep(self, name, priority, fn)
    	if self._cleaning then
    		error("cannot call trove:BindToRenderStep() while cleaning", 2)
    	end

    	RunService:BindToRenderStep(name, priority, fn)

    	self:Add(function()
    		RunService:UnbindFromRenderStep(name)
    	end)
    end


    function Trove.AddPromise(self, promise)
    	if self._cleaning then
    		error("cannot call trove:AddPromise() while cleaning", 2)
    	end
    	AssertPromiseLike(promise)

    	if promise:getStatus() == "Started" then
    		promise:finally(function()
    			if self._cleaning then
    				return
    			end
    			self:_findAndRemoveFromObjects(promise, false)
    		end)

    		self:Add(promise, "cancel")
    	end

    	return promise
    end

    function Trove.Remove(self, object)
    if self._cleaning then
    		error("cannot call trove:Remove() while cleaning", 2)
    	end

    	return self:_findAndRemoveFromObjects(object, true)
    end

    function Trove.Extend(self)
    	if self._cleaning then
    		error("cannot call trove:Extend() while cleaning", 2)
    	end

    	return self:Construct(Trove)
    end

    function Trove.Clean(self)
    	if self._cleaning then
    		return
    	end

    	self._cleaning = true

    	for _, obj in self._objects do
    		self:_cleanupObject(obj[1], obj[2])
    	end

    	table.clear(self._objects)
    	self._cleaning = false
    end

    function Trove._findAndRemoveFromObjects(self, object, cleanup)
    local objects = self._objects

    	for i, obj in ipairs(objects) do
    		if obj[1] == object then
    			local n = #objects
    			objects[i] = objects[n]
    			objects[n] = nil

    			if cleanup then
    				self:_cleanupObject(obj[1], obj[2])
    			end

    			return true
    		end
    	end

    	return false
    end

    function Trove._cleanupObject(self, object, cleanupMethod)
    	if cleanupMethod == FN_MARKER then
    		object()
    	elseif cleanupMethod == THREAD_MARKER then
    		pcall(task.cancel, object)
    	else
    		object[cleanupMethod](object)
    	end
    end

    function Trove.AttachToInstance(self, instance)
    	if self._cleaning then
    		error("cannot call trove:AttachToInstance() while cleaning", 2)
    	elseif not instance:IsDescendantOf(game) then
    		error("instance is not a descendant of the game hierarchy", 2)
    	end

    	return self:Connect(instance.Destroying, function()
    		self:Destroy()
    	end)
    end

    function Trove.Destroy(self)
    	self:Clean()
    end

    return {
    	new = Trove.new,
    }
    end)()


    local Signal = LPH_NO_VIRTUALIZE(function()



    local freeRunnerThread = nil
    local function acquireRunnerThreadAndCallEventHandler(fn, ...)
    	local acquiredRunnerThread = freeRunnerThread
    	freeRunnerThread = nil
    	fn(...)

    	freeRunnerThread = acquiredRunnerThread
    end

    local function runEventHandlerInFreeThread(...)
    	acquireRunnerThreadAndCallEventHandler(...)
    	while true do
    		acquireRunnerThreadAndCallEventHandler(coroutine.yield())
    	end
    end


    local Connection = {}
    Connection.__index = Connection

    function Connection:Disconnect()
    	if not self.Connected then
    		return
    	end
    	self.Connected = false


    	if self._signal._handlerListHead == self then
    		self._signal._handlerListHead = self._next
    	else
    		local prev = self._signal._handlerListHead
    		while prev and prev._next ~= self do
    			prev = prev._next
    		end
    		if prev then
    			prev._next = self._next
    		end
    	end
    end

    Connection.Destroy = Connection.Disconnect


    setmetatable(Connection, {
    	__index = function(_tb, key)
    		error(("Attempt to get Connection::%s (not a valid member)"):format(tostring(key)), 2)
    	end,
    	__newindex = function(_tb, key, _value)
    		error(("Attempt to set Connection::%s (not a valid member)"):format(tostring(key)), 2)
    	end,
    })



    local Signal = {}
    Signal.__index = Signal
    function Signal.new()
    local self = setmetatable({
    		_handlerListHead = false,
    		_proxyHandler = nil,
    		_yieldedThreads = nil,
    	}, Signal)

    	return self
    end


    function Signal.Wrap(rbxScriptSignal)
    assert(
    		typeof(rbxScriptSignal) == "RBXScriptSignal",
    		"Argument #1 to Signal.Wrap must be a RBXScriptSignal; got " .. typeof(rbxScriptSignal)
    	)

    	local signal = Signal.new()
    	signal._proxyHandler = rbxScriptSignal:Connect(function(...)
    		signal:Fire(...)
    	end)

    	return signal
    end

    function Signal.Is(obj)
    return type(obj) == "table" and getmetatable(obj) == Signal
    end


    function Signal:Connect(fn)
    	local connection = setmetatable({
    		Connected = true,
    		_signal = self,
    		_fn = fn,
    		_next = false,
    	}, Connection)

    	if self._handlerListHead then
    		connection._next = self._handlerListHead
    		self._handlerListHead = connection
    	else
    		self._handlerListHead = connection
    	end

    	return connection
    end
    function Signal:ConnectOnce(fn)
    	return self:Once(fn)
    end

    function Signal:Once(fn)
    	local connection
    	local done = false

    	connection = self:Connect(function(...)
    		if done then
    			return
    		end

    		done = true
    		connection:Disconnect()
    		fn(...)
    	end)

    	return connection
    end

    function Signal:GetConnections()
    	local items = {}

    	local item = self._handlerListHead
    	while item do
    		table.insert(items, item)
    		item = item._next
    	end

    	return items
    end
    function Signal:DisconnectAll()
    	local item = self._handlerListHead
    	while item do
    		item.Connected = false
    		item = item._next
    	end
    	self._handlerListHead = false

    	local yieldedThreads = rawget(self, "_yieldedThreads")
    	if yieldedThreads then
    		for thread in yieldedThreads do
    			if coroutine.status(thread) == "suspended" then
    				warn(debug.traceback(thread, "signal disconnected; yielded thread cancelled", 2))
    				task.cancel(thread)
    			end
    		end
    		table.clear(self._yieldedThreads)
    	end
    end

    function Signal:Fire(...)
    	local item = self._handlerListHead
    	while item do
    		if item.Connected then
    			if not freeRunnerThread then
    				freeRunnerThread = coroutine.create(runEventHandlerInFreeThread)
    			end
    			task.spawn(freeRunnerThread, item._fn, ...)
    		end
    		item = item._next
    	end
    end
    function Signal:FireDeferred(...)
    	local item = self._handlerListHead
    	while item do
    		local conn = item
    		task.defer(function(...)
    			if conn.Connected then
    				conn._fn(...)
    			end
    		end, ...)
    		item = item._next
    	end
    end

    function Signal:Wait()
    	local yieldedThreads = rawget(self, "_yieldedThreads")
    	if not yieldedThreads then
    		yieldedThreads = {}
    		rawset(self, "_yieldedThreads", yieldedThreads)
    	end

    	local thread = coroutine.running()
    	yieldedThreads[thread] = true

    	self:Once(function(...)
    		yieldedThreads[thread] = nil
    		task.spawn(thread, ...)
    	end)

    	return coroutine.yield()
    end

    function Signal:Destroy()
    	self:DisconnectAll()

    	local proxyHandler = rawget(self, "_proxyHandler")
    	if proxyHandler then
    		proxyHandler:Disconnect()
    	end
    end


    setmetatable(Signal, {
    	__index = function(_tb, key)
    		error(("Attempt to get Signal::%s (not a valid member)"):format(tostring(key)), 2)
    	end,
    	__newindex = function(_tb, key, _value)
    		error(("Attempt to set Signal::%s (not a valid member)"):format(tostring(key)), 2)
    	end,
    })

    return table.freeze({
    	new = Signal.new,
    	Wrap = Signal.Wrap,
    	Is = Signal.Is,
    })
    end)()


    local function inside(x, y, pX, pY, sX, sY)
    return x > pX and x < pX + sX and y > pY and y < pY + sY
    end

    local function insideFrame(input, frame)
    	local position = frame.AbsolutePosition
    	local size = frame.AbsoluteSize

    	return inside(input.X, input.Y, position.X, position.Y, size.X, size.Y)
    end

    local function deepCopy(t)
    local copy = {}

    	for k, v in t do
    		if type(v) == "table" then
    			v = deepCopy(v)
    		end

    		copy[k] = v
    	end

    	return copy
    end







-- =========================================================
-- Obsidian UI + Minho Hub compatibility layer
-- UI library is loaded locally; no GitHub UI download.
-- =========================================================
local Library
do
    local LibraryURL = "https://raw.githubusercontent.com/jixyuk12nh-maker/Minho_Hub/main/Library-4-Obsidian-UI.lua"

    -- Executor compatibility: some environments expose loadstring,
    -- while others expose load. Never call a missing function.
    local compile = rawget(_G, "loadstring") or rawget(_G, "load")
    if type(compile) ~= "function" then
        error("Minho Hub: this executor does not provide loadstring/load; cannot load the GitHub UI library", 0)
    end

    local httpGet = game.HttpGet
    if type(httpGet) ~= "function" then
        error("Minho Hub: game:HttpGet is unavailable in this executor", 0)
    end

    local ok, src = pcall(function()
        return game:HttpGet(LibraryURL)
    end)
    if not ok or type(src) ~= "string" or #src == 0 then
        error("Minho Hub: failed to download Obsidian UI library from GitHub", 0)
    end

    local okCompile, chunk = pcall(function()
        return compile(src)
    end)
    if not okCompile or type(chunk) ~= "function" then
        error("Minho Hub: GitHub UI library could not be compiled", 0)
    end

    local okRun, result = pcall(chunk)
    if not okRun or type(result) ~= "table" then
        error("Minho Hub: Obsidian UI library failed while initializing", 0)
    end

    Library = result
end

local Window = Library:CreateWindow({
    Title = "Minho Hub", Footer = "Minho Hub", Size = UDim2.fromOffset(1000, 550),
    Center = true, AutoShow = true, Resizable = true, ShowMobileButtons = true,
})

local base = { features = {}, instances = {}, visible = true, menus = {}, _trove = nil }
base.instances.gui = Library.ScreenGui
function base:setVisible(v) self.visible = v == true; pcall(function() Window:Toggle(self.visible) end) end
function base:Finish() end

local function Signal()
    local s = { _c = {} }
    function s:Connect(fn)
        local c = { Connected = true }
        function c:Disconnect() c.Connected = false end
        table.insert(self._c, {fn=fn, c=c})
        return c
    end
    function s:Fire(v)
        for _, x in ipairs(self._c) do if x.c.Connected then pcall(x.fn, v) end end
    end
    return s
end

local function feature(flag, default)
    local f = { value = default, changed = Signal(), active = default, label = flag }
    function f:set(v)
        if type(v) == "table" and v.rgb then self.value = {rgb=v.rgb, alpha=v.alpha or 1}
        else self.value = v end
        self.active = self.value
        self.changed:Fire(self.value)
        return self
    end
    function f:add(v) self.value=v; self.changed:Fire(v); return self end
    base.features[flag] = f
    return f
end

local function bindToggle(box, flag, text, default)
    local f = feature(flag, default or false)
    box:AddToggle(flag, {Text=text, Default=f.value, Callback=function(v) f:set(v) end})
    return f
end
local function bindSlider(box, flag, text, min, max, default, rounding)
    local f = feature(flag, default)
    box:AddSlider(flag, {Text=text, Min=min, Max=max, Default=default, Rounding=rounding or 1, Suffix="", Callback=function(v) f:set(v) end})
    return f
end
local function bindDropdown(box, flag, text, values, default)
    local f = feature(flag, default)
    box:AddDropdown(flag, {Text=text, Values=values, Default=default, Callback=function(v) f:set(v) end})
    return f
end
local function bindInput(box, flag, text, default)
    local f = feature(flag, default or "")
    box:AddInput(flag, {Text=text, Default=f.value, Callback=function(v) f:set(v) end})
    return f
end
local function bindColor(parent, flag, title, default)
    local f = feature(flag, {rgb=default, alpha=1})
    parent:AddColorPicker(flag, {Title=title, Default=default, Callback=function(v) f:set({rgb=v, alpha=1}) end})
    return f
end
local function bindButton(box, flag, text, callback)
    local f = feature(flag, false)
    box:AddButton(flag, function() f.changed:Fire(true); if callback then pcall(callback) end end)
    return f
end

local function addGroups(tab, title, side) return side == 2 and tab:AddRightGroupbox(title) or tab:AddLeftGroupbox(title) end

local Main = Window:AddTab("Main", "home")
local World = Window:AddTab("World", "globe")
local Visuals = Window:AddTab("Visuals", "eye")
local Character = Window:AddTab("Character", "user")
local Misc = Window:AddTab("Misc", "wrench")
local Spoofer = Window:AddTab("Spoofer", "user-cog")
local Settings = Window:AddTab("Settings", "settings")

-- Main / Rage
local rage = addGroups(Main, "Rage", 1)
bindToggle(rage, "main/rage/enabled", "Enable Rage", false)

-- World
local env = addGroups(World, "World", 1)
bindToggle(env,"world_brightness","World Brightness",false)
bindSlider(env,"world_brightness_value","Brightness",0,5,2,2)
bindToggle(env,"remove_shadows","Remove Shadows",false)
bindToggle(env,"world_exposure","World Exposure",false)
bindSlider(env,"world_exposure_value","Exposure",-2,3,0,2)
bindToggle(env,"world_ambient","World Ambient",false)
bindColor(env,"world_ambient_color","Ambient Color",game:GetService("Lighting").Ambient)
bindToggle(env,"world_time","World Time",false)
bindSlider(env,"world_time_value","Time",0,24,game:GetService("Lighting").ClockTime,2)
bindToggle(env,"fog_changer","World Fog",false)
bindColor(env,"fog_color","Fog Color",game:GetService("Lighting").FogColor)
bindSlider(env,"fog_start","Fog Start",1,5000,game:GetService("Lighting").FogStart,1)
bindSlider(env,"fog_end","Fog End",1,5000,game:GetService("Lighting").FogEnd,1)
local sky = addGroups(World, "Skybox", 2)
bindToggle(sky,"world/skybox/enabled","Skybox",false)
bindDropdown(sky,"world/skybox/preset","Preset",{"Default","Minecraft","Space","Night"},"Default")
local tex = addGroups(World, "Texture Pack", 2)
bindToggle(tex,"world/texture_pack/enabled","Texture Pack",false)
bindDropdown(tex,"world/texture_pack/pack","Pack",{"Minecraft","Grods"},"Minecraft")

-- Sounds
local hs = addGroups(World,"Hit Sound",2)
bindToggle(hs,"world/sound/hit_enabled","Hit Sound Replacement",false)
bindDropdown(hs,"world/sound/hit_sound","Hit Sound",{"Successful Hit","Ender Dragon Hit"},"Successful Hit")
bindSlider(hs,"world/sound/hit_volume","Hit Sound Volume",0,2,1,2)
local ks = addGroups(World,"Kill Sound",2)
bindToggle(ks,"world/sound/kill_enabled","Kill Sound Replacement",false)
bindDropdown(ks,"world/sound/kill_sound","Kill Sound",{"Silverfish Headshot","Zombie Hurt","Ghast Death","Wither Death"},"Silverfish Headshot")
bindSlider(ks,"world/sound/kill_volume","Kill Sound Volume",0,2,1,2)

-- Visuals / ESP
local esp = addGroups(Visuals,"Player ESP",1)
for _,x in ipairs({{"esp/enabled","Enable"},{"esp/box","Box"},{"esp/box_fill","Box Fill"},{"esp/name","Name"},{"esp/health","Health Bar"},{"esp/distance","Distance"},{"esp/highlight","Highlight"},{"esp/display_name","Display Name"}}) do bindToggle(esp,x[1],x[2],false) end
local colors = addGroups(Visuals,"Colors / Style",2)
bindColor(colors,"esp/box_color","Box Color",Color3.new(1,1,1))
bindColor(colors,"esp/box_fill_color","Box Fill Color",Color3.new(1,1,1))
bindColor(colors,"esp/name_color","Name Color",Color3.new(1,1,1))
bindColor(colors,"esp/health_color","Health Color",Color3.fromRGB(153,196,39))
bindColor(colors,"esp/highlight_color","Highlight Color",Color3.fromRGB(153,196,39))
bindSlider(colors,"esp/box_transparency","Box Transparency",0,1,0,2)
bindSlider(colors,"esp/fill_transparency","Fill Transparency",0,1,0.75,2)
bindSlider(colors,"esp/name_size","Name Size",10,24,14,1)

local hud = addGroups(Visuals,"Crosshair",1)
bindToggle(hud,"hud/crosshair","Crosshair",false)
bindSlider(hud,"drawing_crosshair_length","Length",1,20,5,1)
bindSlider(hud,"drawing_crosshair_gap","Gap",0,30,5,1)
bindToggle(hud,"drawing_crosshair_spin","Spin",false)
bindSlider(hud,"drawing_crosshair_speed","Spin Speed",1,20,5,1)
bindDropdown(hud,"drawing_crosshair_location","Location",{"Mouse","Center"},"Mouse")
bindColor(hud,"hud/crosshair_color","Crosshair Color",Color3.new(1,1,1))
local target = addGroups(Visuals,"Target Info",2)
bindToggle(target,"hud/target_info","Target Info",false)
bindDropdown(target,"hud/target_location","Location",{"Mouse","Center"},"Center")
local notif = addGroups(Visuals,"Notifications",1)
bindToggle(notif,"hud/notifications","Notifications",false)
bindDropdown(notif,"notification_style","Style",{"Default","Minimalistic","Eclipse"},"Default")
bindSlider(notif,"notification_y_offset","Y Offset",0,500,50,1)
local keyb = addGroups(Visuals,"Keybind List",2)
bindToggle(keyb,"hud/keybinds","Keybinds",false)
bindSlider(keyb,"keybind_x","X Position",0,2000,500,1)
bindSlider(keyb,"keybind_y","Y Position",0,2000,500,1)
local wm = addGroups(Visuals,"Watermark",1)
bindToggle(wm,"hud/watermark","Watermark",false)
bindInput(wm,"watermark_text","Text","mihno.win")
bindDropdown(wm,"watermark_location","Location",{"Center","Mouse"},"Center")
bindSlider(wm,"watermark_x_offset","X Offset",-1000,1000,0,1)
bindSlider(wm,"watermark_y_offset","Y Offset",-1000,1000,0,1)

-- Character
local movement = addGroups(Character,"Movement",1)
bindToggle(movement,"misc/movement/no_slide_cooldown","No Slide Cooldown",false)
bindToggle(movement,"misc/movement/speed_multiplier/enabled","Enable Speed Multiplier",false)
bindSlider(movement,"misc/movement/speed_multiplier/mult","Speed Multiplier",1,10,2,2)
bindToggle(movement,"misc/movement/jump_height/enabled","Jump Height Multiplier",false)
bindSlider(movement,"misc/movement/jump_height/mult","Jump Height Multiplier",1,10,2,2)
bindToggle(movement,"misc/movement/infinite_jump","Infinite Jump",false)
local guns = addGroups(Character,"Guns",2)
bindToggle(guns,"misc/guns/no_recoil","No Recoil",false)
bindToggle(guns,"misc/guns/no_spread","No Spread",false)
bindToggle(guns,"misc/guns/no_shoot_cooldown","No Shoot Cooldown",false)
bindSlider(guns,"misc/guns/shoot_cooldown","Shoot Cooldown",10,100,10,1)

-- Misc
local util = addGroups(Misc,"Utilities",1)
bindToggle(util,"misc/utilities/name_spoofer","Name Spoofer",false)
bindInput(util,"misc/utilities/name_spoofer_text","Name","")
bindToggle(util,"misc/utilities/info_spoofer","Info Spoofer",false)
bindDropdown(util,"misc/utilities/info_spoofer_platform","Platform",{"Windows","Android","iOS"},"Windows")
bindToggle(util,"misc/utilities/auto_queue","Auto Queue",false)
local cosmetics = addGroups(Misc,"Cosmetics",2)
bindToggle(cosmetics,"misc/cosmetics/show_changer","Cosmetics",false)

-- Spoofer
local sp = addGroups(Spoofer,"Spoofer",1)
sp:AddLabel("Spoofer controls are available in Misc > Utilities.")

-- Settings / config
local menu = addGroups(Settings,"Menu",1)
local accent = bindColor(menu,"settings/menu/accent","Accent",Color3.fromRGB(55,175,225))
bindSlider(menu,"settings/menu/text_size","Text Size",1,26,16,1)
local unload = bindButton(menu,"settings/menu/unload","Unload")
bindToggle(menu,"settings/menu/debug_mode","Debug Mode",false)
bindToggle(menu,"settings/menu/keybind_menu","Keybind Menu",false)
bindToggle(menu,"settings/menu/auto_reconnect","Auto Reconnect",false)
bindToggle(menu,"settings/menu/auto_run_script","Auto Run Script",false)
bindToggle(menu,"settings/menu/auto_load","Auto Load",false)
local cfg = addGroups(Settings,"Configuration",2)
bindInput(cfg,"settings/config/name","Config Name","default")
local configList = feature("settings/config/list", "default.json")
cfg:AddDropdown("settings/config/list", {Text="Config", Values={"default.json"}, Default="default.json", Callback=function(v) configList:set(v) end})
bindButton(cfg,"settings/config/create","Create")
bindButton(cfg,"settings/config/load","Load")
bindButton(cfg,"settings/config/save","Save")
bindButton(cfg,"settings/config/delete","Delete")
bindToggle(cfg,"settings/config/auto_save","Auto Save To Config",false)

-- Runtime expects these legacy objects.
base.visibilityChanged = Signal()
base.instances.gui = Library.ScreenGui


        -- ====================== HIT / KILL SOUNDS ======================
        -- Replace the game's matching Sound before playback. No Humanoid events,
        -- no RemoteEvent, no new Sound, and no direct :Play().

        local assetCache = {}
        local assetLoading = {}

        local HitSoundRules = {
            { ids = {17138490999}, url = "https://66mods-assets.pages.dev/repos/InventivetalentDev/minecraft-assets/assets/minecraft/sounds/random/successful_hit.ogg" },
            { ids = {138975587469438}, url = "https://66mods-assets.pages.dev/repos/66buncer/Rivals-Pack-Assets/sniper_candidate_enderdragon_hit.ogg" },
        }

        local KillSoundRules = {
            { ids = {15109829804}, url = "https://66mods-assets.pages.dev/repos/66buncer/Rivals-Pack-Assets/headshot_silverfish_kill.ogg" },
            { ids = {16530229616}, url = "https://66mods-assets.pages.dev/repos/66buncer/Rivals-Pack-Assets/kill1_zombie_hurt.ogg" },
            { ids = {16530229541}, url = "https://66mods-assets.pages.dev/repos/66buncer/Rivals-Pack-Assets/kill2_ghast_death.ogg" },
            { ids = {16530229695}, url = "https://66mods-assets.pages.dev/repos/66buncer/Rivals-Pack-Assets/kill3_wither_death.ogg" },
        }

        local function makeFileName(url)
            local hash = 2166136261
            for i = 1, #url do
                hash = bit32.bxor(hash, string.byte(url, i))
                hash = (hash * 16777619) % 4294967296
            end
            return "MinhoHub_Audio_" .. tostring(hash) .. ".ogg"
        end

        local function getAsset(url)
            if not url then return nil end
            if assetCache[url] then return assetCache[url] end
            if assetLoading[url] then
                local started = os.clock()
                while assetLoading[url] and os.clock() - started < 8 do task.wait() end
                return assetCache[url]
            end

            assetLoading[url] = true
            local result = nil
            pcall(function()
                local loader = getcustomasset or getsynasset
                if not (writefile and isfile and loader) then return end
                local fileName = makeFileName(url)
                if not isfile(fileName) then
                    local data = game:HttpGet(url)
                    if type(data) ~= "string" or #data <= 80 then return end
                    writefile(fileName, data)
                end
                local asset = loader(fileName)
                if type(asset) == "string" and asset ~= "" then result = asset end
            end)
            assetCache[url] = result
            assetLoading[url] = nil
            return result
        end

        local hitSoundToggle = base.features["world/sound/hit_enabled"]
        local killSoundToggle = base.features["world/sound/kill_enabled"]
        local hitSoundDropdown = base.features["world/sound/hit_sound"]
        local killSoundDropdown = base.features["world/sound/kill_sound"]
        local hitVolume = base.features["world/sound/hit_volume"]
        local killVolume = base.features["world/sound/kill_volume"]

        local HitIds, KillIds = {}, {}
        for _, rule in ipairs(HitSoundRules) do
            for _, id in ipairs(rule.ids) do HitIds[tostring(id)] = true end
        end
        for _, rule in ipairs(KillSoundRules) do
            for _, id in ipairs(rule.ids) do KillIds[tostring(id)] = true end
        end

        local function selectedUrl(category)
            if category == "hit" then
                local selected = hitSoundDropdown and hitSoundDropdown.value
                if selected == "Ender Dragon Hit" then return HitSoundRules[2].url end
                return HitSoundRules[1].url
            end
            local selected = killSoundDropdown and killSoundDropdown.value
            if selected == "Zombie Hurt" then return KillSoundRules[2].url end
            if selected == "Ghast Death" then return KillSoundRules[3].url end
            if selected == "Wither Death" then return KillSoundRules[4].url end
            return KillSoundRules[1].url
        end

        local function enabled(category)
            return category == "hit"
                and hitSoundToggle and hitSoundToggle.value
                or category == "kill" and killSoundToggle and killSoundToggle.value
        end

        local function categoryFromId(id)
            if HitIds[id] then return "hit" end
            if KillIds[id] then return "kill" end
            return nil
        end

        local replacing = setmetatable({}, {__mode = "k"})
        local watched = setmetatable({}, {__mode = "k"})
        local replacedCategory = setmetatable({}, {__mode = "k"})

        local function applyVolume(sound, category)
            local feature = category == "hit" and hitVolume or killVolume
            local value = feature and tonumber(feature.value) or 1
            pcall(function() sound.Volume = math.clamp(value, 0, 2) end)
        end

        local function tryReplace(sound)
            if replacing[sound] or not sound or not sound.Parent then return end
            local id = string.match(sound.SoundId or "", "%d+")
            local category = id and categoryFromId(id)
            if not category or not enabled(category) then return end

            -- IMPORTANT: this runs when the game assigns the original SoundId,
            -- before waiting for IsPlaying, so the current hit/kill playback uses
            -- the replacement instead of changing the Sound after it already started.
            local asset = getAsset(selectedUrl(category))
            if not asset then return end

            replacing[sound] = true
            pcall(function()
                sound.SoundId = asset
                replacedCategory[sound] = category
                applyVolume(sound, category)
            end)
            replacing[sound] = nil
        end

        local function watchSound(sound)
            if not sound or not sound:IsA("Sound") or watched[sound] then return end
            watched[sound] = true

            sound:GetPropertyChangedSignal("SoundId"):Connect(function()
                if not replacing[sound] then
                    tryReplace(sound)
                end
            end)

            -- Existing idle matching Sounds are prepared now. Sounds already playing
            -- are left alone, preventing replacement-triggered startup audio.
            if not sound.IsPlaying then
                tryReplace(sound)
            end
        end

        for _, obj in ipairs(game:GetDescendants()) do
            if obj:IsA("Sound") then watchSound(obj) end
        end

        game.DescendantAdded:Connect(function(obj)
            if obj:IsA("Sound") then
                task.defer(function()
                    if obj and obj.Parent then watchSound(obj) end
                end)
            end
        end)

        -- Changing dropdowns never plays or immediately rewrites active Sounds.
        -- The next time the game assigns a matching original SoundId, the new choice applies.

        if hitVolume then
            hitVolume.changed:Connect(function()
                for sound, category in pairs(replacedCategory) do
                    if category == "hit" and sound and sound.Parent then applyVolume(sound, category) end
                end
            end)
        end

        if killVolume then
            killVolume.changed:Connect(function()
                for sound, category in pairs(replacedCategory) do
                    if category == "kill" and sound and sound.Parent then applyVolume(sound, category) end
                end
            end)
        end

        -- ====================== WORLD MODIFIER ======================
        -- World runtime, based on the supplied World file.
        local Lighting = game:GetService("Lighting")
        local original = {
            Brightness = Lighting.Brightness,
            ExposureCompensation = Lighting.ExposureCompensation,
            Ambient = Lighting.Ambient,
            ClockTime = Lighting.ClockTime,
            GlobalShadows = Lighting.GlobalShadows,
            FogColor = Lighting.FogColor,
            FogStart = Lighting.FogStart,
            FogEnd = Lighting.FogEnd,
        }

        local World = {}

        function World.brightness(value)
            if type(value) ~= "number" then return end
            Lighting.Brightness = math.clamp(value, 0, 5)
        end
        function World.exposure(value)
            if type(value) ~= "number" then return end
            Lighting.ExposureCompensation = math.clamp(value, -2, 3)
        end
        function World.ambient(color)
            if typeof(color) ~= "Color3" then return end
            Lighting.Ambient = color
        end
        function World.removeShadows(bool)
            Lighting.GlobalShadows = not bool
        end
        function World.time(hour)
            if type(hour) ~= "number" then return end
            Lighting.ClockTime = math.clamp(hour, 0, 24)
        end
        function World.fog(color, startDist, endDist)
            if color then Lighting.FogColor = color end
            if startDist then Lighting.FogStart = math.clamp(startDist, 1, 5000) end
            if endDist then Lighting.FogEnd = math.clamp(endDist, 1, 5000) end
        end
        function World.fogStart(value)
            if type(value) ~= "number" then return end
            Lighting.FogStart = math.clamp(value, 1, 5000)
        end
        function World.fogEnd(value)
            if type(value) ~= "number" then return end
            Lighting.FogEnd = math.clamp(value, 1, 5000)
        end
        function World.fullBright()
            Lighting.Brightness = 5
            Lighting.ExposureCompensation = 1
            Lighting.Ambient = Color3.fromRGB(255, 255, 255)
            Lighting.GlobalShadows = false
            Lighting.FogEnd = 100000
        end
        function World.nightVision()
            Lighting.Brightness = 5
            Lighting.Ambient = Color3.fromRGB(0, 255, 0)
            Lighting.ExposureCompensation = 2
            Lighting.FogColor = Color3.fromRGB(0, 100, 0)
        end
        function World.hellMode()
            Lighting.Ambient = Color3.fromRGB(150, 0, 0)
            Lighting.FogColor = Color3.fromRGB(255, 50, 0)
            Lighting.FogStart = 10
            Lighting.FogEnd = 300
            Lighting.Brightness = 2
        end
        function World.iceMode()
            Lighting.Ambient = Color3.fromRGB(100, 150, 255)
            Lighting.FogColor = Color3.fromRGB(200, 230, 255)
            Lighting.FogStart = 5
            Lighting.FogEnd = 150
            Lighting.Brightness = 3
        end
        function World.radioactive()
            Lighting.Ambient = Color3.fromRGB(0, 100, 0)
            Lighting.FogColor = Color3.fromRGB(100, 255, 0)
            Lighting.FogStart = 20
            Lighting.FogEnd = 400
            Lighting.Brightness = 1
        end
        function World.horror()
            Lighting.Brightness = 0
            Lighting.ClockTime = 0
            Lighting.Ambient = Color3.fromRGB(0, 0, 0)
            Lighting.FogColor = Color3.fromRGB(20, 20, 20)
            Lighting.FogStart = 1
            Lighting.FogEnd = 50
        end
        function World.night()
            Lighting.ClockTime = 0
            Lighting.Ambient = Color3.fromRGB(0, 0, 100)
            Lighting.FogColor = Color3.fromRGB(20, 20, 60)
            Lighting.Brightness = 1
        end
        function World.day()
            Lighting.ClockTime = 12
            Lighting.Brightness = 2
            Lighting.FogEnd = 100000
        end
        function World.restore()
            Lighting.Brightness = original.Brightness
            Lighting.ExposureCompensation = original.ExposureCompensation
            Lighting.Ambient = original.Ambient
            Lighting.ClockTime = original.ClockTime
            Lighting.GlobalShadows = original.GlobalShadows
            Lighting.FogColor = original.FogColor
            Lighting.FogStart = original.FogStart
            Lighting.FogEnd = original.FogEnd
        end
        pcall(function() getgenv().World = World end)

        local function feature(name) return base.features[name] end
        local brightnessToggle, brightnessValue = feature("world_brightness"), feature("world_brightness_value")
        local exposureToggle, exposureValue = feature("world_exposure"), feature("world_exposure_value")
        local timeToggle, timeValue = feature("world_time"), feature("world_time_value")
        local shadowsToggle = feature("remove_shadows")
        local ambientToggle, ambientColor = feature("world_ambient"), feature("world_ambient_color")
        local fogToggle, fogColor = feature("fog_changer"), feature("fog_color")
        local fogStartValue, fogEndValue = feature("fog_start"), feature("fog_end")

        -- Local Skybox runtime. The UI and state live in this file; nothing loads a UI from GitHub.
        local skyboxToggle = feature("world/skybox/enabled")
        local skyboxPreset = feature("world/skybox/preset")
        local skyboxOriginal = {}
        local skyboxObject = nil
        local skyboxCreated = false

        local SKYBOX_PRESETS = {
            Minecraft = {
                SkyboxBk = "rbxassetid://271042516", SkyboxDn = "rbxassetid://271077243",
                SkyboxFt = "rbxassetid://271042556", SkyboxLf = "rbxassetid://271042310",
                SkyboxRt = "rbxassetid://271042467", SkyboxUp = "rbxassetid://271077958",
            },
            Space = {
                SkyboxBk = "rbxassetid://159454299", SkyboxDn = "rbxassetid://159454296",
                SkyboxFt = "rbxassetid://159454293", SkyboxLf = "rbxassetid://159454286",
                SkyboxRt = "rbxassetid://159454300", SkyboxUp = "rbxassetid://159454288",
            },
            Night = {
                SkyboxBk = "rbxassetid://12064107", SkyboxDn = "rbxassetid://12064152",
                SkyboxFt = "rbxassetid://12064121", SkyboxLf = "rbxassetid://12063984",
                SkyboxRt = "rbxassetid://12064115", SkyboxUp = "rbxassetid://12064131",
            },
        }

        local function getSkybox()
            local existing = Lighting:FindFirstChildOfClass("Sky")
            if existing then
                return existing
            end
            local sky = Instance.new("Sky")
            sky.Name = "MinhoHubSkybox"
            sky.Parent = Lighting
            skyboxCreated = true
            return sky
        end

        local function captureSkybox(sky)
            if skyboxOriginal.Captured then return end
            skyboxOriginal.Captured = true
            skyboxOriginal.SkyboxBk = sky.SkyboxBk
            skyboxOriginal.SkyboxDn = sky.SkyboxDn
            skyboxOriginal.SkyboxFt = sky.SkyboxFt
            skyboxOriginal.SkyboxLf = sky.SkyboxLf
            skyboxOriginal.SkyboxRt = sky.SkyboxRt
            skyboxOriginal.SkyboxUp = sky.SkyboxUp
        end

        local function applySkybox()
            if not skyboxToggle or not skyboxPreset then return end
            if not skyboxToggle.value then
                if skyboxObject and skyboxObject.Parent then
                    if skyboxCreated then
                        skyboxObject:Destroy()
                    elseif skyboxOriginal.Captured then
                        skyboxObject.SkyboxBk = skyboxOriginal.SkyboxBk
                        skyboxObject.SkyboxDn = skyboxOriginal.SkyboxDn
                        skyboxObject.SkyboxFt = skyboxOriginal.SkyboxFt
                        skyboxObject.SkyboxLf = skyboxOriginal.SkyboxLf
                        skyboxObject.SkyboxRt = skyboxOriginal.SkyboxRt
                        skyboxObject.SkyboxUp = skyboxOriginal.SkyboxUp
                    end
                end
                skyboxObject = nil
                skyboxCreated = false
                return
            end

            local preset = skyboxPreset.value or "Default"
            local existing = Lighting:FindFirstChildOfClass("Sky")
            if existing and existing.Name ~= "MinhoHubSkybox" then
                captureSkybox(existing)
                skyboxObject = existing
            else
                skyboxObject = skyboxObject or getSkybox()
            end

            if preset == "Default" then
                if skyboxOriginal.Captured then
                    skyboxObject.SkyboxBk = skyboxOriginal.SkyboxBk
                    skyboxObject.SkyboxDn = skyboxOriginal.SkyboxDn
                    skyboxObject.SkyboxFt = skyboxOriginal.SkyboxFt
                    skyboxObject.SkyboxLf = skyboxOriginal.SkyboxLf
                    skyboxObject.SkyboxRt = skyboxOriginal.SkyboxRt
                    skyboxObject.SkyboxUp = skyboxOriginal.SkyboxUp
                elseif skyboxCreated then
                    skyboxObject:Destroy()
                    skyboxObject = nil
                    skyboxCreated = false
                end
                return
            end

            local data = SKYBOX_PRESETS[preset]
            if not data then return end
            for property, value in pairs(data) do
                skyboxObject[property] = value
            end
        end

        local function applyBrightness()
            if brightnessToggle.value then World.brightness(tonumber(brightnessValue.value) or original.Brightness)
            else Lighting.Brightness = original.Brightness end
        end
        local function applyExposure()
            if exposureToggle.value then World.exposure(tonumber(exposureValue.value) or original.ExposureCompensation)
            else Lighting.ExposureCompensation = original.ExposureCompensation end
        end
        local function applyTime()
            if timeToggle.value then World.time(tonumber(timeValue.value) or original.ClockTime)
            else Lighting.ClockTime = original.ClockTime end
        end
        local function applyShadows()
            World.removeShadows(shadowsToggle.value)
            if not shadowsToggle.value then Lighting.GlobalShadows = original.GlobalShadows end
        end
        local function applyAmbient()
            if ambientToggle.value and ambientColor.value then World.ambient(ambientColor.value.rgb)
            else Lighting.Ambient = original.Ambient end
        end
        local function applyFog()
            if fogToggle.value and fogColor.value then
                World.fog(fogColor.value.rgb, tonumber(fogStartValue.value), tonumber(fogEndValue.value))
            else
                Lighting.FogColor, Lighting.FogStart, Lighting.FogEnd = original.FogColor, original.FogStart, original.FogEnd
            end
        end

        brightnessToggle.changed:Connect(applyBrightness)
        brightnessValue.changed:Connect(applyBrightness)
        exposureToggle.changed:Connect(applyExposure)
        exposureValue.changed:Connect(applyExposure)
        timeToggle.changed:Connect(applyTime)
        timeValue.changed:Connect(applyTime)
        shadowsToggle.changed:Connect(applyShadows)
        ambientToggle.changed:Connect(applyAmbient)
        ambientColor.changed:Connect(applyAmbient)
        fogToggle.changed:Connect(applyFog)
        fogColor.changed:Connect(applyFog)
        fogStartValue.changed:Connect(applyFog)
        fogEndValue.changed:Connect(applyFog)
        if skyboxToggle and skyboxPreset then
            skyboxToggle.changed:Connect(applySkybox)
            skyboxPreset.changed:Connect(applySkybox)
        end

        task.defer(function()
            applyBrightness(); applyExposure(); applyTime(); applyShadows(); applyAmbient(); applyFog(); applySkybox()
        end)

        -- World Texture Pack
        -- Switches the map texture cleanly: restore the original first, then apply the new pack.
        local worldTextureToggle = base.features["world/texture_pack/enabled"]
        local worldTextureDropdown = base.features["world/texture_pack/pack"]

        local WORLD_TEXTURE_ID = "7658055825"

        local WORLD_TEXTURES = {
            Minecraft = "https://raw.githubusercontent.com/jixyuk12nh-maker/World/main/texture_pack/item_slot_3_blue_hollow.png",
            Grods = "https://raw.githubusercontent.com/jixyuk12nh-maker/World/main/texture_pack/grods.png",
        }

        local worldTextureCache = {}
        local worldTextureOriginals = {}
        local worldTextureTargets = {}

        local function getWorldTexture(url)
            if worldTextureCache[url] then
                return worldTextureCache[url]
            end

            local success, result = pcall(function()
                if writefile and isfile and getcustomasset then
                    local fileName = "minho_world_" .. tostring(#url % 1000000) .. ".png"

                    if not isfile(fileName) then
                        local data = game:HttpGet(url)
                        if data and #data > 80 then
                            writefile(fileName, data)
                        end
                    end

                    if isfile(fileName) then
                        local asset = getcustomasset(fileName)
                        if asset and asset ~= "" then
                            return asset
                        end
                    end
                end

                return url
            end)

            local asset = (success and result) or url
            worldTextureCache[url] = asset
            return asset
        end

        local function getWorldTextureProperty(obj)
            if obj:IsA("Decal") or obj:IsA("Texture") then
                return "Texture"
            elseif obj:IsA("MeshPart") then
                return "TextureID"
            end
            return nil
        end

        local function getWorldTextureId(value)
            if type(value) ~= "string" then
                return nil
            end
            return string.match(value, "%d+")
        end

        local function rememberWorldTextureTarget(obj, property, original)
            worldTextureOriginals[obj] = original
            worldTextureTargets[obj] = property
        end

        local function findWorldTextureTargets()
            for _, obj in ipairs(game:GetDescendants()) do
                local property = getWorldTextureProperty(obj)
                if property then
                    local success, value = pcall(function()
                        return obj[property]
                    end)

                    if success and type(value) == "string" then
                        -- Only register the actual map texture, not every Decal/Texture/MeshPart.
                        if getWorldTextureId(value) == WORLD_TEXTURE_ID then
                            if worldTextureOriginals[obj] == nil then
                                rememberWorldTextureTarget(obj, property, value)
                            end
                        end
                    end
                end
            end
        end

        local function restoreWorldTextures()
            for obj, original in pairs(worldTextureOriginals) do
                if obj and obj.Parent then
                    local property = worldTextureTargets[obj] or getWorldTextureProperty(obj)
                    if property then
                        pcall(function()
                            -- Remove the currently applied pack before restoring the original.
                            obj[property] = ""
                            obj[property] = original
                        end)
                    end
                end
            end
        end

        local function clearWorldTextureTracking()
            table.clear(worldTextureOriginals)
            table.clear(worldTextureTargets)
        end

        local function getSelectedWorldTexture()
            local selected = worldTextureDropdown and worldTextureDropdown.value or "Minecraft"
            if type(selected) == "table" then
                selected = selected[1]
            end
            return tostring(selected)
        end

        local function applyWorldTexture()
            if not worldTextureToggle or not worldTextureToggle.value then
                return
            end

            local selected = getSelectedWorldTexture()
            local url = WORLD_TEXTURES[selected] or WORLD_TEXTURES.Minecraft

            -- Download/load once BEFORE touching the map. This removes most of the visible delay.
            local asset = getWorldTexture(url)

            findWorldTextureTargets()

            for obj, property in pairs(worldTextureTargets) do
                if obj and obj.Parent then
                    pcall(function()
                        -- Clear the old texture first, then assign the newly selected texture.
                        obj[property] = ""
                        obj[property] = asset
                    end)
                end
            end
        end

        local function switchWorldTexture()
            if not worldTextureToggle or not worldTextureToggle.value then
                return
            end

            -- 1. Remove the currently applied texture and restore the original.
            restoreWorldTextures()
            clearWorldTextureTracking()

            -- 2. Load/apply the newly selected texture.
            applyWorldTexture()
        end

        if worldTextureToggle and worldTextureToggle.changed then
            worldTextureToggle.changed:Connect(function()
                if worldTextureToggle.value then
                    applyWorldTexture()
                else
                    restoreWorldTextures()
                    clearWorldTextureTracking()
                end
            end)
        end

        if worldTextureDropdown and worldTextureDropdown.changed then
            worldTextureDropdown.changed:Connect(function()
                if worldTextureToggle and worldTextureToggle.value then
                    switchWorldTexture()
                end
            end)
        end

        game.DescendantAdded:Connect(function(obj)
            if not worldTextureToggle or not worldTextureToggle.value then
                return
            end

            task.defer(function()
                local property = getWorldTextureProperty(obj)
                if not property then
                    return
                end

                local success, value = pcall(function()
                    return obj[property]
                end)

                if not success or type(value) ~= "string" then
                    return
                end

                if getWorldTextureId(value) == WORLD_TEXTURE_ID then
                    if worldTextureOriginals[obj] == nil then
                        rememberWorldTextureTarget(obj, property, value)
                    end

                    local selected = getSelectedWorldTexture()
                    local url = WORLD_TEXTURES[selected] or WORLD_TEXTURES.Minecraft
                    local asset = getWorldTexture(url)

                    pcall(function()
                        obj[property] = ""
                        obj[property] = asset
                    end)
                end
            end)
        end)

        local nameBox = base.features["settings/config/name"]
        local createButton = base.features["settings/config/create"]
        local loadButton = base.features["settings/config/load"]
        local saveButton = base.features["settings/config/save"]
        local deleteButton = base.features["settings/config/delete"]
        local autoSaveToggle = base.features["settings/config/auto_save"]
        local configList = base.features["settings/config/list"]

        local selectedConfig = "default.json"
        local knownConfigs = {}

        -- Normalize names so "KK" becomes "KK.json" exactly once.
        local function configName(name)
            name = tostring(name or "")
            name = name:gsub("%.json$", "")
            name = name:gsub("[^%w%._%-]", "")
            name = name:gsub("%.json$", "")
            if name == "" then name = "default" end
            return name .. ".json"
        end

        local function configPath(name)
            return CONFIG_DIR .. configName(name)
        end

        local function addConfigToList(filename)
            filename = configName(filename)
            if knownConfigs[filename] then return end
            knownConfigs[filename] = true
            if configList and configList.add then
                pcall(function() configList:add(filename) end)
            end
        end

        local function getSelectedConfig()
            local value = configList and configList.value
            if type(value) == "table" then value = value[1] end
            if value and tostring(value) ~= "" then return configName(value) end
            return selectedConfig
        end

        local function saveConfig(name)
            if not writefile then return false end
            local filename = configName(name)
            local ok = pcall(function()
                writefile(configPath(filename), base:encodeJSON())
            end)
            if ok then
                selectedConfig = filename
                addConfigToList(filename)
            end
            return ok
        end

        local function loadConfig(name)
            if not readfile or not isfile then return false end
            local filename = configName(name)
            local path = configPath(filename)
            if not isfile(path) then return false end
            local ok = pcall(function()
                base:decodeJSON(readfile(path))
            end)
            if ok then
                selectedConfig = filename
                addConfigToList(filename)
            end
            return ok
        end

        -- Load existing .json configs into the list on startup.
        addConfigToList("default.json")
        if listfiles then
            pcall(function()
                for _, path in ipairs(listfiles(CONFIG_DIR)) do
                    local filename = tostring(path):match("([^/\\]+)$")
                    if filename and filename:match("%.json$") then
                        addConfigToList(filename)
                    end
                end
            end)
        end

        createButton.changed:Connect(function()
            local rawName = tostring(nameBox.value or ""):gsub("^%s+", ""):gsub("%s+$", "")
            if rawName == "" then return end
            saveConfig(configName(rawName))
        end)

        saveButton.changed:Connect(function()
            local rawName = tostring(nameBox.value or ""):gsub("^%s+", ""):gsub("%s+$", "")
            saveConfig(rawName ~= "" and rawName or selectedConfig)
        end)

        loadButton.changed:Connect(function()
            loadConfig(getSelectedConfig())
        end)

        deleteButton.changed:Connect(function()
            -- Always keep at least one config in the list.
            local configCount = 0
            for _ in pairs(knownConfigs) do
                configCount += 1
            end

            if configCount <= 1 then
                return
            end

            local filename = getSelectedConfig()
            if delfile and isfile and isfile(configPath(filename)) then
                pcall(delfile, configPath(filename))
            end
            if configList and configList.remove then
                pcall(function() configList:remove(filename) end)
            end
            knownConfigs[filename] = nil
            if selectedConfig == filename then
                selectedConfig = "default.json"
            end
        end)

        for flag, feature in next, base.features do
            if flag ~= "settings/config/auto_save"
                and feature.changed
                and feature.changed.Connect then
                feature.changed:Connect(function()
                    if autoSaveToggle.value then
                        saveConfig(selectedConfig)
                    end
                end)
            end
        end
    end

    -- Live Settings: default text size 16, original blue accent.
    local originalAccent = Color3.fromRGB(55, 175, 225)
    local currentAccent = originalAccent

    local function applyMenuSettings()
        local accentFeature = base.features["settings/menu/accent"]
        local sizeFeature = base.features["settings/menu/text_size"]
        local accent = originalAccent
        if accentFeature and accentFeature.value and accentFeature.value.rgb then
            accent = accentFeature.value.rgb
        end
        local textSize = math.clamp(tonumber(sizeFeature and sizeFeature.value) or 16, 1, 26)
        local gui = base.instances.gui
        if not gui then return end

        local objects = {gui}
        for _, obj in ipairs(gui:GetDescendants()) do
            table.insert(objects, obj)
        end
        for _, obj in ipairs(objects) do
            if obj:IsA("TextLabel") or obj:IsA("TextButton") or obj:IsA("TextBox") then
                obj.TextSize = textSize
                if obj.TextColor3 == currentAccent or obj.TextColor3 == originalAccent then
                    obj.TextColor3 = accent
                end
            elseif obj:IsA("Frame") then
                if obj.BackgroundColor3 == currentAccent or obj.BackgroundColor3 == originalAccent then
                    obj.BackgroundColor3 = accent
                end
            elseif obj:IsA("ScrollingFrame") then
                if obj.ScrollBarImageColor3 == currentAccent or obj.ScrollBarImageColor3 == originalAccent then
                    obj.ScrollBarImageColor3 = accent
                end
            end
        end
        currentAccent = accent
    end

    if base.features["settings/menu/accent"] then
        base.features["settings/menu/accent"].changed:Connect(applyMenuSettings)
    end
    if base.features["settings/menu/text_size"] then
        base.features["settings/menu/text_size"].changed:Connect(applyMenuSettings)
    end
    task.defer(applyMenuSettings)


    -- ═══════════════════════════════════════════════════
    -- HUD runtime (based on the supplied Hud file)
    -- ═══════════════════════════════════════════════════
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local LocalPlayer = Players.LocalPlayer

    local function getFeature(name)
        return base.features and base.features[name] or nil
    end

    local function getValue(name, fallback)
        local feature = getFeature(name)
        if not feature then return fallback end
        local value = feature.value
        if value == nil then return fallback end
        return value
    end

    local function safeDrawing(kind)
        if not Drawing or type(Drawing.new) ~= "function" then return nil end
        local ok, object = pcall(Drawing.new, kind)
        if ok then return object end
        return nil
    end

    local crosshairDrawings = {}
    for i = 1, 4 do
        local line = safeDrawing("Line")
        local outline = safeDrawing("Line")
        if line then
            line.Thickness = 1
            line.Visible = false
        end
        if outline then
            outline.Thickness = 3
            outline.Color = Color3.new(0,0,0)
            outline.Visible = false
        end
        crosshairDrawings[i] = {line, outline}
    end

    local function hideCrosshair()
        for _, pair in ipairs(crosshairDrawings) do
            if pair[1] then pair[1].Visible = false end
            if pair[2] then pair[2].Visible = false end
        end
    end

    local function getCrosshairLocation()
        local mode = getValue("drawing_crosshair_location", "Mouse")
        local camera = workspace.CurrentCamera
        if not camera then return nil end
        if mode == "Center" then
            return camera.ViewportSize / 2
        elseif mode == "Target" then
            local ok, target = pcall(function() return aimbot.target end)
            if ok and target and player_data and player_data[target] then
                local parts = player_data[target].character_parts
                local hrp = parts and parts.HumanoidRootPart
                if hrp then
                    local pos, visible = camera:WorldToViewportPoint(hrp.Position)
                    if visible then return Vector2.new(pos.X, pos.Y) end
                end
            end
        end
        local mouse = UserInputService:GetMouseLocation()
        return Vector2.new(mouse.X, mouse.Y)
    end

    local spinAngle = 0
    local crosshairConnection
    crosshairConnection = RunService.RenderStepped:Connect(function(dt)
        local ok = pcall(function()
            local toggle = getFeature("hud/crosshair")
            if not toggle or not toggle.value or not Drawing then
                hideCrosshair()
                return
            end

            local location = getCrosshairLocation()
            if not location then hideCrosshair() return end

            local length = getValue("drawing_crosshair_length", 5) * 5
            local gap = getValue("drawing_crosshair_gap", 5)
            local spinning = getValue("drawing_crosshair_spin", false)
            local speed = getValue("drawing_crosshair_speed", 5)
            spinAngle = spinning and (spinAngle + math.rad((speed * 5) * dt)) or 0

            local colorFeature = getFeature("hud/crosshair_color")
            local customColor = colorFeature and colorFeature.value and colorFeature.value.rgb or Color3.new(1,1,1)
            local angles = {0.0, math.pi/2, math.pi, math.pi*1.5}
            local rainbowTime = os.clock() * math.max(0.1, speed * 0.45)

            for i = 1, 4 do
                local line, outline = crosshairDrawings[i][1], crosshairDrawings[i][2]
                if line and outline then
                    local dir = Vector2.new(math.cos(spinAngle + angles[i]), math.sin(spinAngle + angles[i]))
                    line.From = location + dir * gap
                    line.To = line.From + dir * length
                    line.Color = Color3.fromHSV((rainbowTime + (i - 1) * 0.25) % 1, 1, 1)
                    outline.From = location + dir * math.max(0, gap - 1)
                    outline.To = outline.From + dir * (length + 1)
                    line.Visible = true
                    outline.Visible = true
                end
            end
        end)
        if not ok then hideCrosshair() end
    end)

    -- Target-info panel from the supplied HUD source.
    local targetInfoDrawings = {}
    if Drawing then
        local function newText()
            local d = safeDrawing("Text")
            if d then
                d.Size, d.Font, d.Outline = 16, 2, true
                d.Visible = false
            end
            return d
        end
        local bg = safeDrawing("Square")
        local title, targetText, healthText, armorText, gunText = newText(), newText(), newText(), newText(), newText()
        if bg and title and targetText and healthText and armorText and gunText then
            bg.Filled, bg.Visible = true, false
            bg.Size = Vector2.new(240, 100)
            bg.Color = Color3.fromRGB(12,12,12)
            title.Text, targetText.Text = "target info", "no one"
            healthText.Text, armorText.Text = "100/100", "100/130"
            gunText.Text = ""
            title.Center = true
            targetInfoDrawings = {bg,title,targetText,healthText,armorText,gunText}
        else
            for _, d in ipairs({bg,title,targetText,healthText,armorText,gunText}) do
                if d and d.Remove then pcall(function() d:Remove() end) end
            end
        end
    end

    local function hideTargetInfo()
        for _, d in ipairs(targetInfoDrawings) do d.Visible = false end
    end

    local function updateTargetInfo()
        local toggle = getFeature("hud/target_info")
        if not toggle or not toggle.value or #targetInfoDrawings == 0 then
            hideTargetInfo()
            return
        end
        local camera = workspace.CurrentCamera
        local target
        pcall(function() target = aimbot.target end)
        if not target or not player_data or not player_data[target] then
            hideTargetInfo()
            return
        end
        local parts = player_data[target].character_parts
        local hrp = parts and parts.HumanoidRootPart
        local hum = parts and parts.Humanoid
        if not hrp then hideTargetInfo() return end
        local pos, visible = camera:WorldToViewportPoint(hrp.Position)
        if not visible then hideTargetInfo() return end

        local basePos = Vector2.new(pos.X + 20, pos.Y + 20)
        local box = targetInfoDrawings[1]
        box.Position = basePos
        box.Visible = true

        local name = typeof(target) == "Instance" and target.Name or tostring(target)
        targetInfoDrawings[2].Position = basePos + Vector2.new(120,10)
        targetInfoDrawings[2].Text = "target info"
        targetInfoDrawings[2].Center = true
        targetInfoDrawings[2].Visible = true
        targetInfoDrawings[3].Position = basePos + Vector2.new(12,38)
        targetInfoDrawings[3].Text = name
        targetInfoDrawings[3].Visible = true
        targetInfoDrawings[4].Position = basePos + Vector2.new(12,56)
        targetInfoDrawings[4].Text = "health"
        targetInfoDrawings[4].Visible = true
        targetInfoDrawings[5].Position = basePos + Vector2.new(12,74)
        targetInfoDrawings[5].Text = "armor"
        targetInfoDrawings[5].Visible = true
        targetInfoDrawings[6].Position = basePos + Vector2.new(12,92)
        targetInfoDrawings[6].Text = hum and (math.floor(hum.Health).."/"..math.floor(hum.MaxHealth)) or ""
        targetInfoDrawings[6].Visible = true
    end

    -- Watermark: editable text, based on the supplied HUD behavior.
    local watermarkDrawings = {}
    if Drawing then
        local text = safeDrawing("Text")
        if text then
            text.Text = "mihno.win"
            text.Size = 14
            text.Font = 2
            text.Color = Color3.fromRGB(226,226,226)
            text.Outline = true
            text.Center = true
            text.Visible = false
            watermarkDrawings = {text}
        end
    end

    local function updateWatermark()
        local toggle = getFeature("hud/watermark")
        local drawing = watermarkDrawings[1]
        if not toggle or not toggle.value or not drawing then
            if drawing then drawing.Visible = false end
            return
        end

        local camera = workspace.CurrentCamera
        if not camera then drawing.Visible = false return end

        local location = getValue("watermark_location", "Center")
        local pos = camera.ViewportSize / 2
        if location == "Mouse" then
            local m = UserInputService:GetMouseLocation()
            pos = Vector2.new(m.X, m.Y)
        elseif location == "Target" then
            local ok, target = pcall(function() return aimbot.target end)
            if ok and target and player_data and player_data[target] then
                local parts = player_data[target].character_parts
                local hrp = parts and parts.HumanoidRootPart
                if hrp then
                    local p2, on = camera:WorldToViewportPoint(hrp.Position)
                    if on then pos = Vector2.new(p2.X, p2.Y) end
                end
            end
        end

        pos += Vector2.new(getValue("watermark_x_offset", 0), getValue("watermark_y_offset", 0))
        local customText = getValue("watermark_text", "mihno.win")
        customText = tostring(customText or "mihno.win")
        if customText == "" then customText = "mihno.win" end
        drawing.Text = customText
        drawing.Position = pos
        drawing.Visible = true
    end

    RunService.RenderStepped:Connect(function()
        pcall(updateTargetInfo)
        pcall(updateWatermark)
    end)

    -- ═══════════════════════════════════════════════════
    -- Player ESP (fields and object layout based on supplied file)
    -- ═══════════════════════════════════════════════════
    local espObjects = {}

    local function espColor(name, fallback)
        local f = getFeature(name)
        return f and f.value and f.value.rgb or fallback
    end

    local function createESPObjects(player)
        if player == LocalPlayer or not Drawing then return nil end
        local box = safeDrawing("Square")
        local fill = safeDrawing("Square")
        local name = safeDrawing("Text")
        local health = safeDrawing("Line")
        if not (box and fill and name and health) then
            for _, d in ipairs({box, fill, name, health}) do
                if d and d.Remove then pcall(function() d:Remove() end) end
            end
            return nil
        end
        local highlight
        pcall(function()
            highlight = Instance.new("Highlight")
            highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
            highlight.Enabled = false
            highlight.Parent = gethui and gethui() or game:GetService("CoreGui")
        end)
        return {box=box, fill=fill, name=name, health=health, highlight=highlight}
    end

    local function removeESP(player)
        local obj = espObjects[player]
        if not obj then return end
        for _, d in pairs(obj) do
            if typeof(d) == "Instance" then pcall(function() d:Destroy() end)
            elseif d and d.Remove then pcall(function() d:Remove() end) end
        end
        espObjects[player] = nil
    end

    local function updateESP()
        local enabled = getFeature("esp/enabled")
        if not enabled or not enabled.value then
            for _, obj in pairs(espObjects) do
                obj.box.Visible, obj.fill.Visible, obj.name.Visible, obj.health.Visible = false,false,false,false
                if obj.highlight then obj.highlight.Enabled = false end
            end
            return
        end

        local camera = workspace.CurrentCamera
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local character = player.Character
                local hum = character and character:FindFirstChildOfClass("Humanoid")
                local root = character and character:FindFirstChild("HumanoidRootPart")
                if character and hum and root and hum.Health > 0 then
                    local obj = espObjects[player] or createESPObjects(player)
                    espObjects[player] = obj
                    if obj then
                        local cf, size = character:GetBoundingBox()
                        local corners = {}
                        for _, sx in ipairs({-1,1}) do
                            for _, sy in ipairs({-1,1}) do
                                for _, sz in ipairs({-1,1}) do
                                    local wp = (cf * CFrame.new(size.X*sx/2,size.Y*sy/2,size.Z*sz/2)).Position
                                    local sp, on = camera:WorldToViewportPoint(wp)
                                    if on then table.insert(corners, Vector2.new(sp.X,sp.Y)) end
                                end
                            end
                        end
                        if #corners > 0 then
                            local minX,maxX,minY,maxY = corners[1].X,corners[1].X,corners[1].Y,corners[1].Y
                            for _, v in ipairs(corners) do minX,maxX = math.min(minX,v.X),math.max(maxX,v.X); minY,maxY = math.min(minY,v.Y),math.max(maxY,v.Y) end
                            local size2 = Vector2.new(maxX-minX,maxY-minY)
                            local boxColor = espColor("esp/box_color",Color3.new(1,1,1))
                            local fillColor = espColor("esp/box_fill_color",Color3.new(1,1,1))
                            local nameColor = espColor("esp/name_color",Color3.new(1,1,1))
                            local healthColor = espColor("esp/health_color",Color3.fromRGB(153,196,39))

                            local boxOn = getValue("esp/box", false)
                            obj.box.Position, obj.box.Size = Vector2.new(minX,minY), size2
                            obj.box.Color, obj.box.Thickness, obj.box.Visible = boxColor,1,boxOn

                            local fillOn = getValue("esp/box_fill", false)
                            obj.fill.Position, obj.fill.Size = Vector2.new(minX,minY), size2
                            obj.fill.Color = fillColor
                            obj.fill.Transparency = getValue("esp/fill_transparency", 0.75)
                            obj.fill.Filled, obj.fill.Visible = true,fillOn

                            local nameOn = getValue("esp/name", false)
                            obj.name.Text = (getValue("esp/display_name", false) and player.DisplayName or player.Name)
                            obj.name.Size = getValue("esp/name_size", 14)
                            obj.name.Color = nameColor
                            obj.name.Center, obj.name.Outline = true,true
                            obj.name.Position, obj.name.Visible = Vector2.new((minX+maxX)/2,minY-16),nameOn

                            local healthOn = getValue("esp/health", false)
                            local ratio = math.clamp(hum.Health/math.max(hum.MaxHealth,1),0,1)
                            obj.health.From = Vector2.new(minX-5,maxY)
                            obj.health.To = Vector2.new(minX-5,maxY-(maxY-minY)*ratio)
                            obj.health.Color, obj.health.Thickness, obj.health.Visible = healthColor,2,healthOn

                            if obj.highlight then
                                obj.highlight.Adornee = character
                                obj.highlight.FillColor = espColor("esp/highlight_color",Color3.fromRGB(153,196,39))
                                obj.highlight.FillTransparency = 0.5
                                obj.highlight.OutlineColor = boxColor
                                obj.highlight.Enabled = getValue("esp/highlight", false)
                            end
                        end
                    end
                else
                    if espObjects[player] then
                        espObjects[player].box.Visible,espObjects[player].fill.Visible,espObjects[player].name.Visible,espObjects[player].health.Visible=false,false,false,false
                        if espObjects[player].highlight then espObjects[player].highlight.Enabled=false end
                    end
                end
            end
        end
    end

    RunService.RenderStepped:Connect(function()
        pcall(updateESP)
    end)
    Players.PlayerRemoving:Connect(removeESP)

    base:Finish()
    local unload = base.features["settings/menu/unload"]
    if unload then
        unload.changed:Connect(function()
            if base.instances.gui then
                base.instances.gui:Destroy()
            end
            base.visible = false
        end)
    end
end
