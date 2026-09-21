--[[
    Rivals Profiles HUD - Mobile Compatible Version
    - PC 전용 기능 (Discord RPC, queue_on_teleport, F3) 자동 감지 후 스킵
    - 모바일에서는 터치 버튼으로 토글
    - http.request 미지원 환경 대응
]]

-- ========== 환경 감지 ==========
local UserInputService = game:GetService('UserInputService')
local Players = game:GetService('Players')
local ReplicatedStorage = game:GetService('ReplicatedStorage')
local RunService = game:GetService('RunService')

local isPC = UserInputService.KeyboardEnabled and not UserInputService.TouchEnabled
local isMobile = UserInputService.TouchEnabled
local hasHttpRequest = (typeof(http) == 'table' and typeof(http.request) == 'function')
local hasQueueOnTeleport = (typeof(queue_on_teleport) == 'function')

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild('PlayerGui')

-- ========== 중복 실행 방지 ==========
if _G.ProfilesHUDLoaded then
    local old = PlayerGui:FindFirstChild('RivalsHUD')
    if old then old:Destroy() end
    local old2 = PlayerGui:FindFirstChild('RivalsInfoHUD')
    if old2 then old2:Destroy() end
end
_G.ProfilesHUDLoaded = true

-- ========== 유저 설정 ==========
_G.HiddenUsers = _G.HiddenUsers or {
    -- [1] = 'FriendsUsernameHere',
}

-- ========== 랭크 색상 ==========
_G.RankColors = {
    Diamond      = '#3573e6',
    Silver       = '#C0C0C0',
    Bronze       = '#CD7F32',
    Unranked     = '#ffffff',
    Gold         = '#FFD700',
    Archnemesis  = '#1900ff',
    Nemesis      = '#b700ff',
    Onyx         = '#41315e',
    Platinum     = '#00fbff',
}

-- ========== Discord RPC (PC + http.request 지원 시에만) ==========
if isPC and hasHttpRequest then
    task.spawn(function()
        local ok = pcall(function()
            local HttpService = game:GetService('HttpService')
            local body = HttpService:JSONEncode({
                cmd = 'INVITE_BROWSER',
                nonce = HttpService:GenerateGUID(false),
                args = { code = '4QDg5SGUMK' },
            })
            http.request({
                Body = body,
                Url = 'http://127.0.0.1:6463/rpc?v=1',
                Method = 'POST',
                Headers = {
                    Origin = 'https://discord.com',
                    ['Content-Type'] = 'application/json',
                },
            })
        end)
        if not ok then
            warn('[Rivals HUD] Discord RPC 실패 (무시 가능)')
        end
    end)
else
    warn('[Rivals HUD] Discord RPC 스킵 (모바일 또는 http.request 미지원)')
end

-- ========== 색상 팔레트 ==========
local COLOR_BG_DARK      = Color3.fromRGB(10, 10, 10)
local COLOR_BG_PANEL     = Color3.fromRGB(20, 20, 20)
local COLOR_ACCENT       = Color3.fromRGB(74, 124, 155)
local COLOR_TEXT         = Color3.fromRGB(160, 160, 160)
local COLOR_TEXT_DIM     = Color3.fromRGB(102, 102, 102)
local COLOR_SUCCESS      = Color3.fromRGB(76, 175, 80)
local COLOR_ERROR        = Color3.fromRGB(200, 80, 80)

-- ========== 리모트 ==========
local RequestProfile
pcall(function()
    RequestProfile = ReplicatedStorage:WaitForChild('Remotes', 10)
        :WaitForChild('Misc', 10)
        :WaitForChild('RequestProfile', 10)
end)

-- ========== 화면 크기 (모바일 대응) ==========
local viewport = workspace.CurrentCamera.ViewportSize
local isSmallScreen = viewport.X < 900 or viewport.Y < 600

-- 모바일이면 크기/위치 조정
local hudWidth  = isSmallScreen and 220 or 300
local hudHeight = isSmallScreen and 320 or 400

-- ========== 메인 HUD ==========
local RivalsHUD = Instance.new('ScreenGui')
RivalsHUD.Name = 'RivalsHUD'
RivalsHUD.ResetOnSpawn = false
RivalsHUD.DisplayOrder = 999999
RivalsHUD.IgnoreGuiInset = true
RivalsHUD.Parent = PlayerGui

local InfoHUD = Instance.new('ScreenGui')
InfoHUD.Name = 'RivalsInfoHUD'
InfoHUD.ResetOnSpawn = false
InfoHUD.DisplayOrder = 999998
InfoHUD.IgnoreGuiInset = true
InfoHUD.Parent = PlayerGui

-- ========== 메인 패널 ==========
local MainPanel = Instance.new('Frame')
MainPanel.Name = 'MainPanel'
MainPanel.Size = UDim2.new(0, hudWidth, 0, hudHeight)
MainPanel.Position = UDim2.new(1, -(hudWidth + 15), 0, isSmallScreen and 90 or 420)
MainPanel.BackgroundColor3 = COLOR_BG_PANEL
MainPanel.BackgroundTransparency = 0.05
MainPanel.BorderSizePixel = 0
MainPanel.Active = true          -- 모바일 드래그용
MainPanel.Draggable = true       -- 모바일 드래그 지원
MainPanel.Parent = RivalsHUD

Instance.new('UICorner', MainPanel).CornerRadius = UDim.new(0, 16)

local mainStroke = Instance.new('UIStroke', MainPanel)
mainStroke.Color = COLOR_ACCENT
mainStroke.Transparency = 0.8
mainStroke.Thickness = 1

local header = Instance.new('Frame')
header.Size = UDim2.new(1, -12, 0, 32)
header.Position = UDim2.new(0, 6, 0, 6)
header.BackgroundColor3 = COLOR_BG_DARK
header.BackgroundTransparency = 0.1
header.BorderSizePixel = 0
header.Parent = MainPanel

Instance.new('UICorner', header).CornerRadius = UDim.new(0, 12)

local titleLbl = Instance.new('TextLabel')
titleLbl.Size = UDim2.new(0, 60, 1, 0)
titleLbl.Position = UDim2.new(0, 12, 0, 0)
titleLbl.BackgroundTransparency = 1
titleLbl.Font = Enum.Font.GothamBold
titleLbl.TextSize = 12
titleLbl.TextColor3 = COLOR_ACCENT
titleLbl.Text = 'RIVALS'
titleLbl.TextXAlignment = Enum.TextXAlignment.Left
titleLbl.Parent = header

local subtitleLbl = Instance.new('TextLabel')
subtitleLbl.Size = UDim2.new(1, -80, 1, 0)
subtitleLbl.Position = UDim2.new(0, 75, 0, 0)
subtitleLbl.BackgroundTransparency = 1
subtitleLbl.Font = Enum.Font.Gotham
subtitleLbl.TextSize = 11
subtitleLbl.TextColor3 = COLOR_TEXT
subtitleLbl.Text = 'Player Profiles'
subtitleLbl.TextXAlignment = Enum.TextXAlignment.Left
subtitleLbl.Parent = header

local scroll = Instance.new('ScrollingFrame')
scroll.Size = UDim2.new(1, -12, 1, -46)
scroll.Position = UDim2.new(0, 6, 0, 42)
scroll.BackgroundTransparency = 1
scroll.ScrollBarThickness = 4
scroll.ScrollBarImageColor3 = COLOR_ACCENT
scroll.BorderSizePixel = 0
scroll.CanvasSize = UDim2.new(0, 0, 0, 0)
scroll.Parent = MainPanel

local listLayout = Instance.new('UIListLayout')
listLayout.Padding = UDim.new(0, 6)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scroll

listLayout:GetPropertyChangedSignal('AbsoluteContentSize'):Connect(function()
    scroll.CanvasSize = UDim2.new(0, 0, 0, listLayout.AbsoluteContentSize.Y + 10)
end)

-- ========== Info 패널 ==========
local InfoPanel = Instance.new('Frame')
InfoPanel.Name = 'InfoPanel'
InfoPanel.Size = UDim2.new(0, hudWidth, 0, 90)
InfoPanel.Position = UDim2.new(1, -(hudWidth + 15), 0, (isSmallScreen and 90 or 420) + hudHeight + 10)
InfoPanel.BackgroundColor3 = COLOR_BG_PANEL
InfoPanel.BackgroundTransparency = 0.05
InfoPanel.BorderSizePixel = 0
InfoPanel.Active = true
InfoPanel.Draggable = true
InfoPanel.Parent = InfoHUD

Instance.new('UICorner', InfoPanel).CornerRadius = UDim.new(0, 16)

local infoStroke = Instance.new('UIStroke', InfoPanel)
infoStroke.Color = COLOR_ACCENT
infoStroke.Transparency = 0.8
infoStroke.Thickness = 1

local infoHeader = Instance.new('Frame')
infoHeader.Size = UDim2.new(1, -12, 0, 26)
infoHeader.Position = UDim2.new(0, 6, 0, 6)
infoHeader.BackgroundColor3 = COLOR_BG_DARK
infoHeader.BackgroundTransparency = 0.1
infoHeader.BorderSizePixel = 0
infoHeader.Parent = InfoPanel

Instance.new('UICorner', infoHeader).CornerRadius = UDim.new(0, 10)

local infoTitle = Instance.new('TextLabel')
infoTitle.Size = UDim2.new(0, 60, 1, 0)
infoTitle.Position = UDim2.new(0, 10, 0, 0)
infoTitle.BackgroundTransparency = 1
infoTitle.Font = Enum.Font.GothamBold
infoTitle.TextSize = 10
infoTitle.TextColor3 = COLOR_ACCENT
infoTitle.Text = 'RIVALS'
infoTitle.TextXAlignment = Enum.TextXAlignment.Left
infoTitle.Parent = infoHeader

local infoSubtitle = Instance.new('TextLabel')
infoSubtitle.Size = UDim2.new(1, -80, 1, 0)
infoSubtitle.Position = UDim2.new(0, 70, 0, 0)
infoSubtitle.BackgroundTransparency = 1
infoSubtitle.Font = Enum.Font.Gotham
infoSubtitle.TextSize = 10
infoSubtitle.TextColor3 = COLOR_TEXT
infoSubtitle.Text = 'Info'
infoSubtitle.TextXAlignment = Enum.TextXAlignment.Left
infoSubtitle.Parent = infoHeader

local statusDot = Instance.new('Frame')
statusDot.Size = UDim2.new(0, 6, 0, 6)
statusDot.Position = UDim2.new(1, -16, 0.5, -3)
statusDot.BackgroundColor3 = COLOR_SUCCESS
statusDot.BorderSizePixel = 0
statusDot.Parent = infoHeader
Instance.new('UICorner', statusDot).CornerRadius = UDim.new(0, 3)

local infoText = Instance.new('TextLabel')
infoText.Size = UDim2.new(1, -16, 1, -38)
infoText.Position = UDim2.new(0, 10, 0, 34)
infoText.BackgroundTransparency = 1
infoText.TextColor3 = COLOR_TEXT
infoText.Font = Enum.Font.Gotham
infoText.TextSize = 11
infoText.TextXAlignment = Enum.TextXAlignment.Left
infoText.TextYAlignment = Enum.TextYAlignment.Top
infoText.TextWrapped = true
infoText.Text = 'Loading...'
infoText.Parent = InfoPanel

-- ========== 모바일 토글 버튼 (F3 대체) ==========
local toggleBtn = Instance.new('TextButton')
toggleBtn.Name = 'ToggleButton'
toggleBtn.Size = UDim2.new(0, 50, 0, 50)
toggleBtn.Position = UDim2.new(0, 20, 0, 120)
toggleBtn.BackgroundColor3 = COLOR_BG_PANEL
toggleBtn.BackgroundTransparency = 0.1
toggleBtn.TextColor3 = COLOR_ACCENT
toggleBtn.Font = Enum.Font.GothamBold
toggleBtn.TextSize = 12
toggleBtn.Text = 'HUD'
toggleBtn.AutoButtonColor = true
toggleBtn.Active = true
toggleBtn.Draggable = true
toggleBtn.Parent = RivalsHUD

Instance.new('UICorner', toggleBtn).CornerRadius = UDim.new(1, 0)

local toggleStroke = Instance.new('UIStroke', toggleBtn)
toggleStroke.Color = COLOR_ACCENT
toggleStroke.Transparency = 0.5
toggleStroke.Thickness = 1

local hudVisible = true

local function setHudVisible(state)
    hudVisible = state
    MainPanel.Visible = state
    InfoPanel.Visible = state
    toggleBtn.Text = state and 'HUD' or 'OFF'
    toggleBtn.TextColor3 = state and COLOR_ACCENT or COLOR_TEXT_DIM
end

toggleBtn.MouseButton1Click:Connect(function()
    setHudVisible(not hudVisible)
end)

-- ========== PC용 F3 토글 (있으면 추가) ==========
if isPC then
    UserInputService.InputBegan:Connect(function(input, gp)
        if gp then return end
        if input.KeyCode == Enum.KeyCode.F3 then
            setHudVisible(not hudVisible)
        end
    end)
end

-- ========== Hidden 필터 ==========
local function isHidden(name)
    for _, v in pairs(_G.HiddenUsers or {}) do
        if v == name then return true end
    end
    return false
end

-- ========== 색상 변환 유틸 ==========
local function hexToColor3(hex)
    if not hex then return Color3.new(1,1,1) end
    hex = hex:gsub('#', '')
    local r = tonumber(hex:sub(1,2), 16) or 255
    local g = tonumber(hex:sub(3,4), 16) or 255
    local b = tonumber(hex:sub(5,6), 16) or 255
    return Color3.fromRGB(r, g, b)
end

-- ========== 플레이어 카드 생성 ==========
local function createPlayerCard(player)
    if not player or not player.Parent then return end
    if isHidden(player.Name) then return end
    if scroll:FindFirstChild('PlayerCard_' .. player.UserId) then return end

    local card = Instance.new('Frame')
    card.Name = 'PlayerCard_' .. player.UserId
    card.Size = UDim2.new(1, -6, 0, isSmallScreen and 80 or 94)
    card.BackgroundColor3 = COLOR_BG_DARK
    card.BorderSizePixel = 0
    card.LayoutOrder = 9999
    card.Parent = scroll

    Instance.new('UICorner', card).CornerRadius = UDim.new(0, 10)

    local stroke = Instance.new('UIStroke', card)
    stroke.Color = COLOR_ACCENT
    stroke.Transparency = 0.88
    stroke.Thickness = 1

    -- 아바타
    local avatar = Instance.new('ImageLabel')
    avatar.Name = 'Avatar'
    avatar.Size = UDim2.new(0, isSmallScreen and 40 or 50, 0, isSmallScreen and 40 or 50)
    avatar.Position = UDim2.new(0, 8, 0, 8)
    avatar.BackgroundColor3 = COLOR_BG_PANEL
    avatar.BorderSizePixel = 0
    avatar.Image = 'rbxthumb://type=AvatarHeadShot&id=' .. player.UserId .. '&w=150&h=150'
    avatar.Parent = card

    Instance.new('UICorner', avatar).CornerRadius = UDim.new(0, 8)

    -- 이름
    local nameLbl = Instance.new('TextLabel')
    nameLbl.Name = 'Name'
    nameLbl.Size = UDim2.new(1, -(isSmallScreen and 66 or 76), 0, 16)
    nameLbl.Position = UDim2.new(0, isSmallScreen and 56 or 66, 0, 8)
    nameLbl.BackgroundTransparency = 1
    nameLbl.Font = Enum.Font.GothamBold
    nameLbl.TextSize = isSmallScreen and 11 or 13
    nameLbl.TextColor3 = Color3.fromRGB(230, 230, 230)
    nameLbl.TextXAlignment = Enum.TextXAlignment.Left
    nameLbl.TextTruncate = Enum.TextTruncate.AtEnd
    nameLbl.Text = player.Name
    nameLbl.Parent = card

    -- 랭크
    local rankLbl = Instance.new('TextLabel')
    rankLbl.Name = 'Rank'
    rankLbl.Size = UDim2.new(1, -(isSmallScreen and 66 or 76), 0, 14)
    rankLbl.Position = UDim2.new(0, isSmallScreen and 56 or 66, 0, 24)
    rankLbl.BackgroundTransparency = 1
    rankLbl.Font = Enum.Font.Gotham
    rankLbl.TextSize = isSmallScreen and 10 or 11
    rankLbl.TextColor3 = COLOR_TEXT
    rankLbl.TextXAlignment = Enum.TextXAlignment.Left
    rankLbl.Text = 'Unranked'
    rankLbl.Parent = card

    -- 통계
    local statsLbl = Instance.new('TextLabel')
    statsLbl.Name = 'Stats'
    statsLbl.Size = UDim2.new(1, -16, 0, isSmallScreen and 30 or 44)
    statsLbl.Position = UDim2.new(0, 8, 1, isSmallScreen and -36 or -50)
    statsLbl.BackgroundTransparency = 1
    statsLbl.Font = Enum.Font.Gotham
    statsLbl.TextSize = isSmallScreen and 9 or 10
    statsLbl.TextColor3 = COLOR_TEXT_DIM
    statsLbl.TextXAlignment = Enum.TextXAlignment.Left
    statsLbl.TextYAlignment = Enum.TextYAlignment.Top
    statsLbl.TextWrapped = true
    statsLbl.Text = 'Loading profile...'
    statsLbl.Parent = card

    -- 프로필 요청
    if RequestProfile then
        task.spawn(function()
            local ok, data = pcall(function()
                return RequestProfile:InvokeServer(player)
            end)

            if not card.Parent then return end

            if ok and type(data) == 'table' then
                local rankName = data.Rank or data.RankName or 'Unranked'
                local rankHex = _G.RankColors[rankName] or '#ffffff'
                rankLbl.Text = 'Rank: ' .. tostring(rankName)
                rankLbl.TextColor3 = hexToColor3(rankHex)

                local kills   = data.Kills or data.TotalKills or 0
                local wins    = data.Wins or data.TotalWins or 0
                local level   = data.Level or data.SeasonLevel or 1

                statsLbl.Text = string.format(
                    'Kills: %s  ·  Wins: %s\nLevel: %s',
                    tostring(kills), tostring(wins), tostring(level)
                )
            else
                rankLbl.Text = 'Rank: N/A'
                statsLbl.Text = 'Failed to load profile'
                statsLbl.TextColor3 = COLOR_ERROR
            end
        end)
    else
        rankLbl.Text = 'Remotes unavailable'
        statsLbl.Text = 'RequestProfile remote not found'
        statsLbl.TextColor3 = COLOR_ERROR
    end
end

-- ========== 카드 제거 ==========
local function removePlayerCard(player)
    local card = scroll:FindFirstChild('PlayerCard_' .. player.UserId)
    if card then card:Destroy() end
end

-- ========== 기존 플레이어들 처리 ==========
for _, player in ipairs(Players:GetPlayers()) do
    task.spawn(createPlayerCard, player)
end

-- ========== 이벤트 연결 ==========
Players.PlayerAdded:Connect(function(player)
    task.wait(1)
    createPlayerCard(player)
end)

Players.PlayerRemoving:Connect(function(player)
    removePlayerCard(player)
end)

-- ========== 런타임 / Info 업데이트 ==========
local startTime = tick()

task.spawn(function()
    while task.wait(1) do
        if not InfoHUD.Parent then break end
        local elapsed = tick() - startTime
        local h = math.floor(elapsed / 3600)
        local m = math.floor((elapsed % 3600) / 60)
        local s = math.floor(elapsed % 60)

        local deviceLabel = isMobile and 'Mobile' or (isPC and 'PC' or 'Console')

        infoText.Text = string.format(
            'Runtime: %02d:%02d:%02d\nDevice: %s\nToggle: tap HUD button\n@unrevenged',
            h, m, s, deviceLabel
        )
    end
end)

-- ========== queue_on_teleport (지원 시에만) ==========
if hasQueueOnTeleport then
    pcall(function()
        queue_on_teleport([[loadstring(game:HttpGet("https://raw.githubusercontent.com/jixyuk12nh-maker/Ui/refs/heads/main/Rivals.lua"))()]])
    end)
else
    warn('[Rivals HUD] queue_on_teleport 미지원 - 텔레포트 지속성 없음')
end

print('[Rivals HUD] 모바일 호환 버전 로드 완료. 장치:', isMobile and 'Mobile' or (isPC and 'PC' or 'Unknown'))
