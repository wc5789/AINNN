local Library = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

Library.Version = "16.1.0"

Library.Theme = {
    Accent = Color3.fromRGB(104, 122, 162),
    AccentSoft = Color3.fromRGB(233, 236, 244),
    AccentDeep = Color3.fromRGB(78, 94, 130),
    AccentInk = Color3.fromRGB(255, 255, 255),

    Background = Color3.fromRGB(235, 233, 229),
    Surface = Color3.fromRGB(250, 249, 247),
    Surface2 = Color3.fromRGB(245, 244, 241),
    Surface3 = Color3.fromRGB(232, 230, 226),

    Border = Color3.fromRGB(206, 203, 197),
    BorderSoft = Color3.fromRGB(222, 220, 214),

    Text = Color3.fromRGB(37, 39, 45),
    Text2 = Color3.fromRGB(94, 96, 106),
    Muted = Color3.fromRGB(142, 143, 152),
    White = Color3.fromRGB(255, 255, 255),

    Success = Color3.fromRGB(88, 146, 110),
    Warning = Color3.fromRGB(198, 148, 72),
    Error = Color3.fromRGB(196, 92, 96),

    Dim = Color3.fromRGB(238, 237, 234),
    DimTransparency = 0.94,
}

Library.FontFamily = "rbxasset://fonts/families/BuilderSans.json"

Library.Config = {
    MobileBreakpoint = 560,
    DesktopWidth = 560,
    DesktopHeight = 388,
    MobileWidth = 0.92,
    MobileHeight = 0.80,
    WindowRadius = 12,
    BubbleRadius = 16,
    Animation = 0.14,
    SpringAnimation = 0.26,
    SnapAnimation = 0.09,
    OpenDuration = 0.46,
    CloseDuration = 0.36,
    TabSwitchDuration = 0.32,
    TabIndicatorDuration = 0.34,
    TabSlideOffset = 28,
    TapThreshold = 12,
}

local function parentGui()
    local ok, core = pcall(function() return game:GetService("CoreGui") end)
    if ok and core then return core end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function tween(object, duration, style, direction, properties)
    if not object or not object.Parent then return end
    local t = TweenService:Create(object, TweenInfo.new(duration or Library.Config.Animation, style or Enum.EasingStyle.Quad, direction or Enum.EasingDirection.Out), properties)
    t:Play()
    return t
end

local function spring(object, duration, properties, direction)
    return tween(object, duration or Library.Config.SpringAnimation, Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out, properties)
end

local function snap(object, properties)
    return tween(object, Library.Config.SnapAnimation, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, properties)
end

local function safeCall(fn, ...)
    if type(fn) ~= "function" then return end
    local args = table.pack(...)
    task.spawn(function()
        pcall(function() fn(table.unpack(args, 1, args.n)) end)
    end)
end

local function font(object, weight)
    pcall(function()
        object.FontFace = Font.new(Library.FontFamily, weight or Enum.FontWeight.Medium, Enum.FontStyle.Normal)
    end)
end

local function keyName(key)
    if key == nil then return "None" end
    if typeof(key) == "EnumItem" then return key.Name end
    return tostring(key)
end

local function clampNumber(v, a, b)
    if a > b then a, b = b, a end
    return math.clamp(tonumber(v) or a, a, b)
end

local function addCorner(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 2)
    c.Parent = object
    return c
end

local function addStroke(object, color, transparency, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Library.Theme.Border
    s.Transparency = transparency == nil and 0.5 or transparency
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = object
    return s
end

local function addPadding(object, l, r, t, b)
    local p = Instance.new("UIPadding")
    p.PaddingLeft = UDim.new(0, l or 0)
    p.PaddingRight = UDim.new(0, r or l or 0)
    p.PaddingTop = UDim.new(0, t or l or 0)
    p.PaddingBottom = UDim.new(0, b or t or l or 0)
    p.Parent = object
    return p
end

local function createLabel(parent, text, size, color, weight)
    local l = Instance.new("TextLabel")
    l.BackgroundTransparency = 1
    l.Text = text or ""
    l.TextSize = size or 11
    l.TextColor3 = color or Library.Theme.Text
    l.TextXAlignment = Enum.TextXAlignment.Left
    l.TextYAlignment = Enum.TextYAlignment.Center
    l.AutoLocalize = false
    font(l, weight or Enum.FontWeight.Medium)
    l.Parent = parent
    return l
end

local function hitZone(parent)
    local b = Instance.new("TextButton")
    b.Name = "HitZone"
    b.BackgroundColor3 = Color3.new(1, 1, 1)
    b.BackgroundTransparency = 0.995
    b.BorderSizePixel = 0
    b.Text = ""
    b.AutoButtonColor = false
    b.ZIndex = 60
    b.Parent = parent
    return b
end

local function Maid()
    local self = { tasks = {}, dead = false }
    function self:Add(item)
        if self.dead then
            if typeof(item) == "RBXScriptConnection" then item:Disconnect() elseif type(item) == "function" then item() elseif typeof(item) == "Instance" then item:Destroy() end
            return item
        end
        table.insert(self.tasks, item)
        return item
    end
    function self:Destroy()
        if self.dead then return end
        self.dead = true
        for i = #self.tasks, 1, -1 do
            local item = self.tasks[i]
            pcall(function()
                if typeof(item) == "RBXScriptConnection" then item:Disconnect()
                elseif typeof(item) == "Instance" then item:Destroy()
                elseif type(item) == "function" then item()
                elseif type(item) == "table" and item.Destroy then item:Destroy() end
            end)
        end
        table.clear(self.tasks)
    end
    return self
end

local PointerSessions = {}
local MouseOwner = nil

local function sessionForOwner(owner)
    for input, session in pairs(PointerSessions) do
        if session.owner == owner then return input, session end
    end
    return nil, nil
end

local function beginPointer(owner, input, move, ended)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if MouseOwner then return false end
        MouseOwner = owner
    elseif PointerSessions[input] then
        return false
    end
    PointerSessions[input] = { owner = owner, move = move, ended = ended }
    return true
end

local function endPointer(owner)
    local input, session = sessionForOwner(owner)
    if input then PointerSessions[input] = nil end
    if MouseOwner == owner then MouseOwner = nil end
    return session
end

UserInputService.InputChanged:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseMovement then
        if MouseOwner then
            local _, session = sessionForOwner(MouseOwner)
            if session and session.move then pcall(session.move, input) end
        end
        return
    end
    local session = PointerSessions[input]
    if session and session.move then pcall(session.move, input) end
end)

local function releaseInput(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        if not MouseOwner then return end
        local _, session = sessionForOwner(MouseOwner)
        endPointer(MouseOwner)
        if session and session.ended then pcall(session.ended, input) end
        return
    end
    local session = PointerSessions[input]
    if session then
        PointerSessions[input] = nil
        if session.ended then pcall(session.ended, input) end
    end
end

UserInputService.InputEnded:Connect(releaseInput)

local function surface(object, radius, opts)
    opts = opts or {}
    object.BackgroundColor3 = opts.color or Library.Theme.Surface2
    object.BackgroundTransparency = opts.transparency == nil and 0 or opts.transparency
    object.BorderSizePixel = 0
    addCorner(object, radius or 2)
    if opts.stroke ~= false then
        addStroke(object, opts.strokeColor or Library.Theme.BorderSoft, opts.strokeTransparency == nil and 0.35 or opts.strokeTransparency, opts.strokeThickness or 1)
    end
    return object
end

local function logoMark(parent, px, accent)
    local holder = Instance.new("Frame")
    holder.Size = UDim2.new(0, px, 0, px)
    holder.BackgroundTransparency = 1
    holder.Parent = parent
    local a = Instance.new("Frame")
    a.Name = "AccentMark"
    a.Size = UDim2.new(0.55, 0, 0.55, 0)
    a.Position = UDim2.new(0, 0, 0, 0)
    a.BackgroundColor3 = accent
    a.BorderSizePixel = 0
    a.Parent = holder
    addCorner(a, 3)
    local b = Instance.new("Frame")
    b.Size = UDim2.new(0.55, 0, 0.55, 0)
    b.Position = UDim2.new(0.45, 0, 0.45, 0)
    b.BackgroundColor3 = Library.Theme.Surface
    b.BorderSizePixel = 0
    b.Parent = holder
    addCorner(b, 3)
    addStroke(b, Library.Theme.Border, 0.4)
    return holder
end

local NotificationGui
local NotificationList
local NotificationMaid = Maid()
local notificationCounter = 0

local function ensureNotifications()
    if NotificationGui and NotificationGui.Parent then return NotificationList end
    NotificationGui = Instance.new("ScreenGui")
    NotificationGui.Name = "QWQNotifications"
    NotificationGui.ResetOnSpawn = false
    NotificationGui.IgnoreGuiInset = true
    NotificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    NotificationGui.DisplayOrder = 999
    NotificationGui.Parent = parentGui()
    NotificationMaid:Add(NotificationGui)

    NotificationList = Instance.new("Frame")
    NotificationList.AnchorPoint = Vector2.new(0.5, 0)
    NotificationList.Position = UDim2.new(0.5, 0, 0, 44)
    NotificationList.BackgroundTransparency = 1
    NotificationList.Parent = NotificationGui

    local function fitList()
        local camera = workspace.CurrentCamera
        local vp = camera and camera.ViewportSize or Vector2.new(800, 600)
        NotificationList.Size = UDim2.new(0, math.min(320, math.max(180, vp.X - 32)), 0, math.min(400, vp.Y - 80))
    end
    fitList()
    local camera = workspace.CurrentCamera
    if camera then
        NotificationMaid:Add(camera:GetPropertyChangedSignal("ViewportSize"):Connect(fitList))
    end

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    layout.VerticalAlignment = Enum.VerticalAlignment.Top
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = NotificationList
    return NotificationList
end

local function makeNotification(title, message, duration, kind)
    local list = ensureNotifications()
    notificationCounter += 1
    local colors = { info = Library.Theme.Accent, success = Library.Theme.Success, warn = Library.Theme.Warning, error = Library.Theme.Error }
    local accentColor = colors[kind] or colors.info

    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(1, 0, 0, 50)
    toast.BackgroundColor3 = Library.Theme.Surface
    toast.BackgroundTransparency = 0
    toast.BorderSizePixel = 0
    toast.ClipsDescendants = true
    toast.LayoutOrder = notificationCounter
    toast.Parent = list
    addCorner(toast, 14)
    local stroke = addStroke(toast, accentColor, 0.72, 1)

    local iconBg = Instance.new("Frame")
    iconBg.Size = UDim2.new(0, 30, 0, 30)
    iconBg.Position = UDim2.new(0, 10, 0.5, -15)
    iconBg.BackgroundColor3 = accentColor
    iconBg.BackgroundTransparency = 0.86
    iconBg.BorderSizePixel = 0
    iconBg.Parent = toast
    addCorner(iconBg, 15)

    local iconDot = Instance.new("Frame")
    iconDot.Size = UDim2.new(0, 8, 0, 8)
    iconDot.AnchorPoint = Vector2.new(0.5, 0.5)
    iconDot.Position = UDim2.new(0.5, 0, 0.5, 0)
    iconDot.BackgroundColor3 = accentColor
    iconDot.BorderSizePixel = 0
    iconDot.Parent = iconBg
    addCorner(iconDot, 4)

    local titleLabel = createLabel(toast, tostring(title):upper(), 10, Library.Theme.Text, Enum.FontWeight.Bold)
    titleLabel.Position = UDim2.new(0, 50, 0, 7)
    titleLabel.Size = UDim2.new(1, -64, 0, 14)
    titleLabel.TextTruncate = Enum.TextTruncate.AtEnd

    local descLabel = createLabel(toast, tostring(message), 9, Library.Theme.Text2, Enum.FontWeight.Medium)
    descLabel.Position = UDim2.new(0, 50, 0, 23)
    descLabel.Size = UDim2.new(1, -64, 0, 14)
    descLabel.TextTruncate = Enum.TextTruncate.AtEnd

    local barBg = Instance.new("Frame")
    barBg.Position = UDim2.new(0, 50, 1, -6)
    barBg.Size = UDim2.new(1, -64, 0, 2)
    barBg.BackgroundColor3 = Library.Theme.Surface3
    barBg.BorderSizePixel = 0
    barBg.Parent = toast
    addCorner(barBg, 1)

    local barFill = Instance.new("Frame")
    barFill.Size = UDim2.fromScale(1, 1)
    barFill.BackgroundColor3 = accentColor
    barFill.BorderSizePixel = 0
    barFill.Parent = barBg
    addCorner(barFill, 1)

    toast.Position = UDim2.new(0, 0, 0, -60)
    toast.BackgroundTransparency = 1
    spring(toast, 0.36, { Position = UDim2.new(0, 0, 0, 0), BackgroundTransparency = 0 })
    tween(stroke, 0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Transparency = 0.72 })

    local totalTime = math.max(0.1, duration or 3)
    barFill.Size = UDim2.fromScale(0, 1)
    tween(barFill, totalTime, Enum.EasingStyle.Linear, Enum.EasingDirection.Out, { Size = UDim2.fromScale(1, 1) })

    task.delay(totalTime, function()
        if not toast.Parent then return end
        tween(stroke, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Transparency = 1 })
        local out = spring(toast, 0.30, { Position = UDim2.new(0, 0, 0, -60), BackgroundTransparency = 1 }, Enum.EasingDirection.In)
        if out then out.Completed:Connect(function() if toast.Parent then toast:Destroy() end end) end
    end)
end

function Library:Notify(title, message, duration, kind)
    makeNotification(title or "Library", message or "", duration or 3, kind or "info")
end
function Library:Success(message, duration) self:Notify("Success", message, duration or 2.6, "success") end
function Library:Warn(message, duration) self:Notify("Warning", message, duration or 3, "warn") end
function Library:Error(message, duration) self:Notify("Error", message, duration or 3.4, "error") end

function Library:CreateWindow(titleText, accentColor)
    local windowMaid = Maid()
    local oldWindows = {}
    local guiParent = parentGui()
    for _, child in ipairs(guiParent:GetChildren()) do
        if child.Name:match("^QWQWindow_") then table.insert(oldWindows, child) end
    end
    for _, old in ipairs(oldWindows) do old:Destroy() end

    local accent = accentColor or Library.Theme.Accent
    Library.Theme.Accent = accent

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "QWQWindow_" .. tostring(math.random(10000, 99999))
    ScreenGui.ResetOnSpawn = false
    ScreenGui.IgnoreGuiInset = true
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 100
    ScreenGui.Parent = guiParent
    windowMaid:Add(ScreenGui)

    local Dimmer = Instance.new("Frame")
    Dimmer.Name = "Veil"
    Dimmer.Size = UDim2.fromScale(1, 1)
    Dimmer.BackgroundColor3 = Library.Theme.Dim
    Dimmer.BackgroundTransparency = 1
    Dimmer.BorderSizePixel = 0
    Dimmer.ZIndex = 1
    Dimmer.Parent = ScreenGui

    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.Position = UDim2.fromScale(0.5, 0.5)
    Main.Size = UDim2.fromOffset(54, 54)
    Main.BackgroundColor3 = Library.Theme.Surface
    Main.BackgroundTransparency = 0
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = false
    Main.Active = true
    Main.ZIndex = 10
    Main.Parent = ScreenGui
    local MainCorner = addCorner(Main, Library.Config.BubbleRadius)

    local MainClip = Instance.new("Frame")
    MainClip.Name = "MainClip"
    MainClip.Size = UDim2.fromScale(1, 1)
    MainClip.BackgroundTransparency = 1
    MainClip.ClipsDescendants = true
    MainClip.ZIndex = 11
    MainClip.Parent = Main
    local MainClipCorner = addCorner(MainClip, Library.Config.BubbleRadius)

    local MainStroke = addStroke(Main, Library.Theme.Border, 0.3)

    local MainGradient = Instance.new("UIGradient")
    MainGradient.Rotation = 90
    MainGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Library.Theme.Surface),
        ColorSequenceKeypoint.new(1, Library.Theme.Surface2),
    })
    MainGradient.Parent = Main

    local Bubble = Instance.new("Frame")
    Bubble.Size = UDim2.fromScale(1, 1)
    Bubble.BackgroundTransparency = 1
    Bubble.ZIndex = 12
    Bubble.Parent = MainClip
    local bubbleLayout = Instance.new("UIListLayout")
    bubbleLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    bubbleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    bubbleLayout.Parent = Bubble
    local bubbleLogo = logoMark(Bubble, 22, accent)

    local BubbleButton = Instance.new("TextButton")
    BubbleButton.Name = "BubbleButton"
    BubbleButton.Size = UDim2.fromScale(1, 1)
    BubbleButton.BackgroundTransparency = 1
    BubbleButton.BorderSizePixel = 0
    BubbleButton.Text = ""
    BubbleButton.AutoButtonColor = false
    BubbleButton.Active = true
    BubbleButton.ZIndex = 70
    BubbleButton.Parent = MainClip

    local Content = Instance.new("Frame")
    Content.Size = UDim2.fromScale(1, 1)
    Content.BackgroundTransparency = 1
    Content.ClipsDescendants = true
    Content.Visible = false
    Content.ZIndex = 12
    Content.Parent = MainClip

    local isOpen = false
    local closing = false
    local transitioning = false
    local floatingPosition = UDim2.fromScale(0.5, 0.5)

    local function viewport()
        local camera = workspace.CurrentCamera
        return camera and camera.ViewportSize or Vector2.new(800, 600)
    end

    local function isMobile()
        return viewport().X < Library.Config.MobileBreakpoint
    end

    local function floatingSize()
        return isMobile() and 48 or 52
    end

    local function clampFloating(pos, size)
        local vp = viewport()
        local halfX = size.X / 2
        local halfY = size.Y / 2
        local x = math.clamp(pos.X.Offset, halfX + 8, math.max(halfX + 8, vp.X - halfX - 8))
        local y = math.clamp(pos.Y.Offset, halfY + 8, math.max(halfY + 8, vp.Y - halfY - 8))
        return UDim2.fromOffset(x, y)
    end

    local function windowSize()
        local vp = viewport()
        if vp.X < Library.Config.MobileBreakpoint then
            return UDim2.new(Library.Config.MobileWidth, 0, Library.Config.MobileHeight, 0)
        end
        local w = math.min(Library.Config.DesktopWidth, vp.X - 28)
        local h = math.min(Library.Config.DesktopHeight, vp.Y - 28)
        return UDim2.fromOffset(w, h)
    end

    local function centeredPosition()
        local vp = viewport()
        return UDim2.fromOffset(vp.X / 2, vp.Y / 2)
    end

    local TabButtons = {}
    local CurrentPage

    local refreshTabRail
    local updateLayoutMetrics
    local updateIndicatorPosition

    local function fitToViewport()
        if not Main.Parent then return end
        if isOpen then
            if transitioning then return end
            snap(Main, { Size = windowSize(), Position = centeredPosition() })
            if updateLayoutMetrics then updateLayoutMetrics() end
        else
            local fs = floatingSize()
            Main.Size = UDim2.fromOffset(fs, fs)
            floatingPosition = clampFloating(floatingPosition, Vector2.new(fs, fs))
            Main.Position = floatingPosition
        end
    end

    local currentCameraConn
    local function attachCamera(camera)
        if currentCameraConn then currentCameraConn:Disconnect(); currentCameraConn = nil end
        if camera then
            currentCameraConn = camera:GetPropertyChangedSignal("ViewportSize"):Connect(fitToViewport)
            windowMaid:Add(currentCameraConn)
        end
    end
    attachCamera(workspace.CurrentCamera)
    windowMaid:Add(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        task.defer(function()
            attachCamera(workspace.CurrentCamera)
            fitToViewport()
        end)
    end))

    do
        local vp = viewport()
        local fs = floatingSize()
        Main.Size = UDim2.fromOffset(fs, fs)
        local cx = vp.X - fs / 2 - 20
        local cy = math.clamp(vp.Y * 0.5, fs / 2 + 60, vp.Y - fs / 2 - 60)
        floatingPosition = UDim2.fromOffset(cx, cy)
        Main.Position = floatingPosition
    end

    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 56)
    Header.BackgroundTransparency = 1
    Header.BorderSizePixel = 0
    Header.ClipsDescendants = true
    Header.ZIndex = 12
    Header.Parent = Content
    local headerLine = Instance.new("Frame")
    headerLine.Position = UDim2.new(0, 16, 1, -1)
    headerLine.Size = UDim2.new(1, -32, 0, 1)
    headerLine.BackgroundColor3 = Library.Theme.BorderSoft
    headerLine.BackgroundTransparency = 0.4
    headerLine.BorderSizePixel = 0
    headerLine.Parent = Header

    local Brand = Instance.new("Frame")
    Brand.Size = UDim2.new(1, -100, 1, 0)
    Brand.BackgroundTransparency = 1
    Brand.Parent = Header
    local headerLogo = logoMark(Brand, 18, accent)
    headerLogo.Position = UDim2.new(0, 16, 0, 10)

    local title = createLabel(Brand, titleText or "Library", 13, Library.Theme.Text, Enum.FontWeight.Bold)
    title.Position = UDim2.new(0, 42, 0, 4)
    title.Size = UDim2.new(1, -50, 0, 26)
    title.TextYAlignment = Enum.TextYAlignment.Bottom

    local headerMeta = createLabel(Brand, "STUDIO UI", 7, Library.Theme.Muted, Enum.FontWeight.Bold)
    headerMeta.Position = UDim2.new(0, 42, 0, 30)
    headerMeta.Size = UDim2.new(1, -50, 0, 12)

    local function headerButton(symbol, x, callback)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 28, 0, 28)
        b.Position = UDim2.new(1, x, 0, 14)
        b.BackgroundColor3 = Library.Theme.Surface3
        b.BackgroundTransparency = 0
        b.Text = symbol
        b.TextColor3 = Library.Theme.Text2
        b.TextSize = 14
        b.AutoButtonColor = false
        font(b, Enum.FontWeight.Bold)
        b.Parent = Header
        addCorner(b, 6)
        addStroke(b, Library.Theme.Border, 0.55)
        b.MouseEnter:Connect(function()
            tween(b, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { TextColor3 = accent, BackgroundColor3 = Library.Theme.AccentSoft, Rotation = 8 })
        end)
        b.MouseLeave:Connect(function()
            tween(b, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { TextColor3 = Library.Theme.Text2, BackgroundColor3 = Library.Theme.Surface3, Rotation = 0 })
        end)
        b.Activated:Connect(callback)
        return b
    end

    local minimizeButton
    local closeButton

    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Position = UDim2.new(0, 0, 0, 56)
    Sidebar.Size = UDim2.new(0, 140, 1, -56)
    Sidebar.BackgroundColor3 = Library.Theme.Background
    Sidebar.BackgroundTransparency = 0
    Sidebar.BorderSizePixel = 0
    Sidebar.ClipsDescendants = false
    Sidebar.ZIndex = 12
    Sidebar.Parent = Content
    local sidebarLine = Instance.new("Frame")
    sidebarLine.Position = UDim2.new(1, -1, 0, 14)
    sidebarLine.Size = UDim2.new(0, 1, 1, -28)
    sidebarLine.BackgroundColor3 = Library.Theme.BorderSoft
    sidebarLine.BackgroundTransparency = 0.4
    sidebarLine.BorderSizePixel = 0
    sidebarLine.Parent = Sidebar

    local TabsScroll = Instance.new("ScrollingFrame")
    TabsScroll.Position = UDim2.new(0, 8, 0, 14)
    TabsScroll.Size = UDim2.new(1, -16, 1, -74)
    TabsScroll.BackgroundTransparency = 1
    TabsScroll.BorderSizePixel = 0
    TabsScroll.ScrollBarThickness = 0
    TabsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabsScroll.ClipsDescendants = true
    TabsScroll.Parent = Sidebar
    local tabsLayout = Instance.new("UIListLayout")
    tabsLayout.Padding = UDim.new(0, 4)
    tabsLayout.Parent = TabsScroll
    tabsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if refreshTabRail then
            task.defer(function()
                if refreshTabRail then refreshTabRail(isMobile()) end
            end)
        end
    end)

    local IndicatorLayer = Instance.new("Frame")
    IndicatorLayer.Name = "IndicatorLayer"
    IndicatorLayer.Position = TabsScroll.Position
    IndicatorLayer.Size = TabsScroll.Size
    IndicatorLayer.BackgroundTransparency = 1
    IndicatorLayer.ClipsDescendants = true
    IndicatorLayer.ZIndex = 40
    IndicatorLayer.Parent = Sidebar

    local TabIndicator = Instance.new("Frame")
    TabIndicator.Name = "TabIndicator"
    TabIndicator.Size = UDim2.fromOffset(3, 20)
    TabIndicator.Position = UDim2.fromOffset(0, 0)
    TabIndicator.BackgroundColor3 = accent
    TabIndicator.BorderSizePixel = 0
    TabIndicator.Visible = false
    TabIndicator.ZIndex = 41
    TabIndicator.Parent = IndicatorLayer
    addCorner(TabIndicator, 2)

    local Status = Instance.new("Frame")
    Status.Position = UDim2.new(0, 8, 1, -52)
    Status.Size = UDim2.new(1, -16, 0, 42)
    Status.BackgroundColor3 = Library.Theme.Surface2
    Status.BorderSizePixel = 0
    Status.Parent = Sidebar
    addCorner(Status, 8)
    addStroke(Status, Library.Theme.BorderSoft, 0.5)
    local statusDot = Instance.new("Frame")
    statusDot.Name = "AccentMark"
    statusDot.Size = UDim2.new(0, 5, 0, 5)
    statusDot.Position = UDim2.new(0, 10, 0, 10)
    statusDot.BackgroundColor3 = accent
    statusDot.BorderSizePixel = 0
    statusDot.Parent = Status
    addCorner(statusDot, 3)
    local statusLabel = createLabel(Status, "ONLINE", 8, accent, Enum.FontWeight.Bold)
    statusLabel.Position = UDim2.new(0, 22, 0, 4)
    statusLabel.Size = UDim2.new(1, -30, 0, 12)
    local fpsLabel = createLabel(Status, "-- FPS", 8, Library.Theme.Muted, Enum.FontWeight.Medium)
    fpsLabel.Position = UDim2.new(0, 22, 0, 22)
    fpsLabel.Size = UDim2.new(1, -30, 0, 12)

    local Body = Instance.new("Frame")
    Body.Name = "Body"
    Body.Position = UDim2.new(0, 140, 0, 56)
    Body.Size = UDim2.new(1, -140, 1, -56)
    Body.BackgroundTransparency = 1
    Body.ClipsDescendants = true
    Body.ZIndex = 12
    Body.Parent = Content

    updateIndicatorPosition = function(animate)
        if not CurrentPage or not CurrentPage.button or not CurrentPage.button.Parent then
            TabIndicator.Visible = false
            return
        end
        local targetBtn = CurrentPage.button
        local btnAbsPos = targetBtn.AbsolutePosition
        local btnAbsSize = targetBtn.AbsoluteSize
        local layerAbsPos = IndicatorLayer.AbsolutePosition

        local relX = btnAbsPos.X - layerAbsPos.X
        local relY = btnAbsPos.Y - layerAbsPos.Y

        local compact = isMobile()
        local targetPos, targetSize
        if compact then
            targetPos = UDim2.fromOffset(relX, relY + btnAbsSize.Y - 2)
            targetSize = UDim2.fromOffset(btnAbsSize.X, 2)
        else
            targetPos = UDim2.fromOffset(0, relY + (btnAbsSize.Y - 20) / 2)
            targetSize = UDim2.fromOffset(3, 20)
        end

        TabIndicator.Visible = true

        if animate then
            tween(TabIndicator, Library.Config.TabIndicatorDuration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                Position = targetPos,
                Size = targetSize,
            })
        else
            TabIndicator.Position = targetPos
            TabIndicator.Size = targetSize
        end
    end

    refreshTabRail = function(compact)
        tabsLayout.FillDirection = compact and Enum.FillDirection.Horizontal or Enum.FillDirection.Vertical
        TabsScroll.ScrollingDirection = compact and Enum.ScrollingDirection.X or Enum.ScrollingDirection.Y
        TabsScroll.ScrollBarThickness = 0
        for i, record in ipairs(TabButtons) do
            local b = record.button
            if compact then
                b.Size = UDim2.fromOffset(104, 34)
                record.label.Position = UDim2.new(0, 10, 0, 0)
                record.label.Size = UDim2.new(1, -18, 1, 0)
                record.label.TextSize = 10
                record.tabIndex.Visible = false
            else
                b.Size = UDim2.new(1, 0, 0, 40)
                record.label.Position = UDim2.new(0, 16, 0, 0)
                record.label.Size = UDim2.new(1, -24, 1, 0)
                record.label.TextSize = 10
                record.tabIndex.Visible = true
                record.tabIndex.Position = UDim2.new(0, 10, 0, 0)
                record.tabIndex.Size = UDim2.new(0, 18, 1, 0)
            end
        end

        IndicatorLayer.Position = TabsScroll.Position
        IndicatorLayer.Size = TabsScroll.Size

        if compact then
            local x = tabsLayout.AbsoluteContentSize.X + 10
            TabsScroll.CanvasSize = UDim2.new(0, x, 0, 0)
        else
            local y = tabsLayout.AbsoluteContentSize.Y + 10
            TabsScroll.CanvasSize = UDim2.new(0, 0, 0, y)
        end

        if CurrentPage and CurrentPage.button and CurrentPage.button.Parent then
            task.defer(function()
                updateIndicatorPosition(false)
            end)
        end
    end

    updateLayoutMetrics = function()
        if not Content.Parent then return end
        local compact = isMobile()
        local headerHeight = compact and 50 or 56
        Header.Size = UDim2.new(1, 0, 0, headerHeight)

        if compact then
            Sidebar.Position = UDim2.new(0, 0, 0, headerHeight)
            Sidebar.Size = UDim2.new(1, 0, 0, 46)
            Sidebar.BackgroundColor3 = Library.Theme.Surface
            sidebarLine.Position = UDim2.new(0, 10, 1, -1)
            sidebarLine.Size = UDim2.new(1, -20, 0, 1)
            TabsScroll.Position = UDim2.new(0, 6, 0, 4)
            TabsScroll.Size = UDim2.new(1, -12, 0, 38)
            Status.Visible = false
            Body.Position = UDim2.new(0, 0, 0, headerHeight + 46)
            Body.Size = UDim2.new(1, 0, 1, -(headerHeight + 46))
        else
            local side = 140
            Sidebar.Position = UDim2.new(0, 0, 0, headerHeight)
            Sidebar.Size = UDim2.new(0, side, 1, -headerHeight)
            Sidebar.BackgroundColor3 = Library.Theme.Background
            sidebarLine.Position = UDim2.new(1, -1, 0, 14)
            sidebarLine.Size = UDim2.new(0, 1, 1, -28)
            TabsScroll.Position = UDim2.new(0, 8, 0, 14)
            TabsScroll.Size = UDim2.new(1, -16, 1, -74)
            Status.Visible = true
            Body.Position = UDim2.new(0, side, 0, headerHeight)
            Body.Size = UDim2.new(1, -side, 1, -headerHeight)
        end

        refreshTabRail(compact)
    end
    updateLayoutMetrics()

    TabsScroll:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        if CurrentPage then
            updateIndicatorPosition(false)
        end
    end)

    local function selectTab(record)
        if CurrentPage == record then return end

        local previous = CurrentPage

        for _, item in ipairs(TabButtons) do
            local active = item == record
            tween(item.button, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
                BackgroundTransparency = active and 0 or 1,
                BackgroundColor3 = active and Library.Theme.AccentSoft or Library.Theme.Surface2,
            })
            tween(item.label, 0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
                TextColor3 = active and Library.Theme.Text or Library.Theme.Text2,
            })
            if item.tabIndex then
                tween(item.tabIndex, 0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
                    TextColor3 = active and accent or Library.Theme.Muted,
                })
            end
        end

        task.defer(function()
            updateIndicatorPosition(true)
        end)

        if previous then
            local oldPage = previous.page
            local newPage = record.page

            newPage.Position = UDim2.new(0, Library.Config.TabSlideOffset, 0, 0)
            newPage.Visible = true

            tween(oldPage, Library.Config.TabSwitchDuration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                Position = UDim2.new(0, -Library.Config.TabSlideOffset, 0, 0),
            })

            tween(newPage, Library.Config.TabSwitchDuration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
                Position = UDim2.new(0, 0, 0, 0),
            })

            task.delay(Library.Config.TabSwitchDuration, function()
                if oldPage.Parent then
                    oldPage.Visible = false
                    oldPage.Position = UDim2.new(0, 0, 0, 0)
                end
            end)
        else
            local newPage = record.page
            newPage.Visible = true
            newPage.Position = UDim2.new(0, 0, 0, 0)
        end

        if record.scrollRail then
            record.scrollRail.Visible = true
            task.defer(function()
                if record.updateScrollIndicator then record.updateScrollIndicator() end
            end)
        end
        if previous and previous.scrollRail then
            previous.scrollRail.Visible = false
        end

        CurrentPage = record
    end

    local function makeCard(parent, height)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, height)
        surface(card, 8, {
            color = Library.Theme.Surface2,
            strokeColor = Library.Theme.BorderSoft,
            strokeTransparency = 0.15,
        })
        card.Parent = parent

        local notch = Instance.new("Frame")
        notch.Name = "AccentMark"
        notch.Size = UDim2.new(0, 22, 0, 3)
        notch.Position = UDim2.new(0, 14, 0, 0)
        notch.BackgroundColor3 = accent
        notch.BackgroundTransparency = 0.25
        notch.BorderSizePixel = 0
        notch.Parent = card
        addCorner(notch, 2)

        local edge = Instance.new("Frame")
        edge.Name = "CardEdge"
        edge.AnchorPoint = Vector2.new(1, 0.5)
        edge.Position = UDim2.new(1, 0, 0.5, 0)
        edge.Size = UDim2.new(0, 2, 0.5, 0)
        edge.BackgroundColor3 = accent
        edge.BackgroundTransparency = 0.9
        edge.BorderSizePixel = 0
        edge.Parent = card
        addCorner(edge, 1)

        return card, { notch }, edge
    end

    local function cardHover(hoverSource, brackets, edge)
        hoverSource.MouseEnter:Connect(function()
            tween(edge, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = 0.5 })
            for _, b in ipairs(brackets) do
                tween(b, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = 0.05 })
            end
        end)
        hoverSource.MouseLeave:Connect(function()
            tween(edge, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = 0.9 })
            for _, b in ipairs(brackets) do
                tween(b, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = 0.25 })
            end
        end)
    end

    local function elementAPI(page)
        local API = {}

        function API:CreateLabel(text)
            local holder = Instance.new("Frame")
            holder.Size = UDim2.new(1, 0, 0, 22)
            holder.BackgroundTransparency = 1
            holder.Parent = page
            local l = createLabel(holder, text, 10, Library.Theme.Text2, Enum.FontWeight.SemiBold)
            l.Size = UDim2.fromScale(1, 1)
            return l
        end

        function API:CreateSection(text)
            local holder = Instance.new("Frame")
            holder.Size = UDim2.new(1, 0, 0, 26)
            holder.BackgroundTransparency = 1
            holder.Parent = page
            local mark = Instance.new("Frame")
            mark.Name = "AccentMark"
            mark.Size = UDim2.new(0, 4, 0, 4)
            mark.Position = UDim2.new(0, 1, 0.5, -2)
            mark.BackgroundColor3 = accent
            mark.BorderSizePixel = 0
            mark.Parent = holder
            addCorner(mark, 2)
            local l = createLabel(holder, tostring(text):upper(), 9, Library.Theme.Text2, Enum.FontWeight.Bold)
            l.Position = UDim2.new(0, 12, 0, 0)
            l.Size = UDim2.new(1, -14, 1, 0)
            local rule = Instance.new("Frame")
            rule.AnchorPoint = Vector2.new(1, 0.5)
            rule.Position = UDim2.new(1, 0, 0.5, 0)
            rule.Size = UDim2.new(0.3, 0, 0, 1)
            rule.BackgroundColor3 = Library.Theme.BorderSoft
            rule.BackgroundTransparency = 0.3
            rule.BorderSizePixel = 0
            rule.Parent = holder
            return holder
        end

        function API:CreateDivider()
            local holder = Instance.new("Frame")
            holder.Size = UDim2.new(1, 0, 0, 8)
            holder.BackgroundTransparency = 1
            holder.Parent = page
            local line = Instance.new("Frame")
            line.AnchorPoint = Vector2.new(0.5, 0.5)
            line.Position = UDim2.new(0.5, 0, 0.5, 0)
            line.Size = UDim2.new(1, -20, 0, 1)
            line.BackgroundColor3 = Library.Theme.BorderSoft
            line.BackgroundTransparency = 0.3
            line.BorderSizePixel = 0
            line.Parent = holder
            return holder
        end

        function API:CreateParagraph(text, height)
            local card, brackets, edge = makeCard(page, height or 64)
            cardHover(card, brackets, edge)
            local l = createLabel(card, text, 10, Library.Theme.Text2, Enum.FontWeight.Medium)
            l.Position = UDim2.new(0, 16, 0, 10)
            l.Size = UDim2.new(1, -32, 1, -20)
            l.TextWrapped = true
            l.TextYAlignment = Enum.TextYAlignment.Top
            return { Frame = card, SetText = function(_, value) l.Text = tostring(value) end }
        end

        function API:CreateButton(text, callback)
            local card, brackets, edge = makeCard(page, 40)
            local hit = hitZone(card)
            hit.Size = UDim2.fromScale(1, 1)

            local bar = Instance.new("Frame")
            bar.Name = "AccentMark"
            bar.Size = UDim2.new(0, 3, 0, 14)
            bar.Position = UDim2.new(0, 14, 0.5, -7)
            bar.BackgroundColor3 = accent
            bar.BackgroundTransparency = 0.4
            bar.BorderSizePixel = 0
            bar.Parent = card
            addCorner(bar, 2)

            local label = createLabel(card, text, 11, Library.Theme.Text, Enum.FontWeight.SemiBold)
            label.Position = UDim2.new(0, 26, 0, 0)
            label.Size = UDim2.new(1, -72, 1, 0)

            local meta = createLabel(card, "RUN", 8, Library.Theme.Muted, Enum.FontWeight.Bold)
            meta.Position = UDim2.new(1, -56, 0, 5)
            meta.Size = UDim2.new(0, 42, 0, 10)
            meta.TextXAlignment = Enum.TextXAlignment.Right

            cardHover(hit, brackets, edge)
            hit.MouseEnter:Connect(function()
                tween(label, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { TextColor3 = accent })
                tween(meta, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { TextColor3 = accent })
                tween(bar, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Size = UDim2.new(0, 3, 0, 22), Position = UDim2.new(0, 14, 0.5, -11), BackgroundTransparency = 0 })
            end)
            hit.MouseLeave:Connect(function()
                tween(label, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { TextColor3 = Library.Theme.Text })
                tween(meta, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { TextColor3 = Library.Theme.Muted })
                tween(bar, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Size = UDim2.new(0, 3, 0, 14), Position = UDim2.new(0, 14, 0.5, -7), BackgroundTransparency = 0.4 })
            end)
            local pressScale = Instance.new("UIScale")
            pressScale.Scale = 1
            pressScale.Parent = card
            hit.MouseButton1Down:Connect(function()
                tween(pressScale, 0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Scale = 0.985 })
                tween(card, 0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundColor3 = Library.Theme.AccentSoft })
            end)
            hit.MouseButton1Up:Connect(function()
                spring(pressScale, 0.20, { Scale = 1 })
                tween(card, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundColor3 = Library.Theme.Surface2 })
            end)
            hit.Activated:Connect(function() safeCall(callback) end)
            return hit
        end

        function API:CreateToggle(text, default, callback)
            local state = default == true
            local card, brackets, edge = makeCard(page, 46)
            local click = hitZone(card)
            click.Size = UDim2.fromScale(1, 1)

            local label = createLabel(card, text, 11, Library.Theme.Text, Enum.FontWeight.SemiBold)
            label.Position = UDim2.new(0, 22, 0, 0)
            label.Size = UDim2.new(1, -108, 1, 0)

            local stateText = createLabel(card, "OFF", 8, Library.Theme.Muted, Enum.FontWeight.Bold)
            stateText.Position = UDim2.new(1, -108, 0, 5)
            stateText.Size = UDim2.new(0, 38, 0, 10)
            stateText.TextXAlignment = Enum.TextXAlignment.Right

            local switch = Instance.new("Frame")
            switch.Size = UDim2.new(0, 48, 0, 24)
            switch.Position = UDim2.new(1, -62, 0.5, -12)
            switch.BackgroundColor3 = Library.Theme.Surface3
            switch.BorderSizePixel = 0
            switch.Parent = card
            addCorner(switch, 12)
            local switchStroke = addStroke(switch, Library.Theme.Border, 0.4)

            local block = Instance.new("Frame")
            block.Size = UDim2.new(0, 18, 0, 18)
            block.AnchorPoint = Vector2.new(0, 0.5)
            block.Position = UDim2.new(0, 3, 0.5, 0)
            block.BackgroundColor3 = Library.Theme.Muted
            block.BorderSizePixel = 0
            block.Parent = switch
            addCorner(block, 9)

            cardHover(click, brackets, edge)

            local function render(instant)
                local duration = instant and 0 or 0.24
                local style = instant and Enum.EasingStyle.Linear or Enum.EasingStyle.Quint
                local x = state and 27 or 3
                tween(block, duration, style, Enum.EasingDirection.Out, {
                    Position = UDim2.new(0, x, 0.5, 0),
                    BackgroundColor3 = state and Library.Theme.AccentInk or Library.Theme.Muted,
                })
                tween(switch, duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
                    BackgroundColor3 = state and accent or Library.Theme.Surface3,
                })
                tween(switchStroke, duration * 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
                    Color = state and accent or Library.Theme.Border,
                    Transparency = state and 0.3 or 0.4,
                })
                tween(stateText, duration * 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
                    TextColor3 = state and accent or Library.Theme.Muted,
                })
                stateText.Text = state and "ON" or "OFF"
            end
            render(true)
            local function toggle()
                state = not state
                render(false)
                safeCall(callback, state)
            end
            click.Activated:Connect(toggle)
            return { Get = function() return state end, Set = function(_, value) state = value == true; render(false); safeCall(callback, state) end }
        end

        function API:CreateSlider(text, min, max, default, callback)
            min = tonumber(min) or 0
            max = tonumber(max) or 100
            if min == max then max = min + 1 end
            local value = clampNumber(default == nil and min or default, min, max)
            local card, brackets, edge = makeCard(page, 56)
            local label = createLabel(card, text, 10, Library.Theme.Text, Enum.FontWeight.SemiBold)
            label.Position = UDim2.new(0, 22, 0, 4)
            label.Size = UDim2.new(1, -84, 0, 16)
            local valueLabel = createLabel(card, string.format("%g", value), 10, accent, Enum.FontWeight.Bold)
            valueLabel.Position = UDim2.new(1, -68, 0, 4)
            valueLabel.Size = UDim2.new(0, 52, 0, 16)
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right

            local track = Instance.new("Frame")
            track.Position = UDim2.new(0, 22, 0, 34)
            track.Size = UDim2.new(1, -40, 0, 4)
            track.BackgroundColor3 = Library.Theme.Surface3
            track.BorderSizePixel = 0
            track.Parent = card
            addCorner(track, 2)
            local fill = Instance.new("Frame")
            fill.Name = "AccentFill"
            fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            fill.BackgroundColor3 = accent
            fill.BorderSizePixel = 0
            fill.Parent = track
            addCorner(fill, 2)
            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 12, 0, 12)
            knob.AnchorPoint = Vector2.new(0.5, 0.5)
            knob.Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0)
            knob.BackgroundColor3 = accent
            knob.BorderSizePixel = 0
            knob.ZIndex = 5
            knob.Parent = track
            addCorner(knob, 6)
            local knobCore = Instance.new("Frame")
            knobCore.Size = UDim2.new(0, 4, 0, 4)
            knobCore.AnchorPoint = Vector2.new(0.5, 0.5)
            knobCore.Position = UDim2.fromScale(0.5, 0.5)
            knobCore.BackgroundColor3 = Library.Theme.AccentInk
            knobCore.BorderSizePixel = 0
            knobCore.ZIndex = 6
            knobCore.Parent = knob
            addCorner(knobCore, 2)

            local function setValue(v, fire)
                value = clampNumber(v, min, max)
                local pct = (value - min) / (max - min)
                tween(fill, 0.11, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Size = UDim2.new(pct, 0, 1, 0) })
                spring(knob, 0.20, { Position = UDim2.new(pct, 0, 0.5, 0) })
                valueLabel.Text = string.format("%g", value)
                if fire then safeCall(callback, value) end
            end

            local pad = hitZone(card)
            pad.Position = UDim2.new(0, 14, 0, 22)
            pad.Size = UDim2.new(1, -28, 0, 26)
            cardHover(pad, brackets, edge)

            local owner = {}
            local function update(input)
                if track.AbsoluteSize.X <= 0 then return end
                local pct = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                setValue(min + (max - min) * pct, true)
            end
            pad.InputBegan:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
                if beginPointer(owner, input, update, function()
                    if page and page.Parent then page.ScrollingEnabled = true end
                end) then
                    if page and page.Parent then page.ScrollingEnabled = false end
                    update(input)
                end
            end)
            return { Get = function() return value end, Set = function(_, v) setValue(v, true) end }
        end

        function API:CreateInput(placeholder, callback)
            local card, brackets, edge = makeCard(page, 40)
            local box = Instance.new("TextBox")
            box.Size = UDim2.new(1, -40, 1, 0)
            box.Position = UDim2.new(0, 22, 0, 0)
            box.BackgroundTransparency = 1
            box.PlaceholderText = placeholder or "enter value..."
            box.PlaceholderColor3 = Library.Theme.Muted
            box.Text = ""
            box.TextColor3 = Library.Theme.Text
            box.TextSize = 11
            box.ClearTextOnFocus = false
            box.TextXAlignment = Enum.TextXAlignment.Left
            font(box, Enum.FontWeight.Medium)
            box.Parent = card
            local prompt = createLabel(card, ">", 10, accent, Enum.FontWeight.Bold)
            prompt.Position = UDim2.new(0, 10, 0, 0)
            prompt.Size = UDim2.new(0, 10, 1, 0)
            local stroke = card:FindFirstChildOfClass("UIStroke")
            box.Focused:Connect(function()
                if stroke then tween(stroke, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Color = accent, Transparency = 0.2 }) end
            end)
            box.FocusLost:Connect(function()
                if stroke then tween(stroke, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Color = Library.Theme.BorderSoft, Transparency = 0.45 }) end
                safeCall(callback, box.Text)
            end)
            return { GetText = function() return box.Text end, SetText = function(_, value) box.Text = tostring(value) end }
        end

        function API:CreateDropdown(text, options, callback)
            options = options or {}
            local selected, open = nil, false
            local optionHeight, headerHeight, maxVisible = 28, 42, 6
            local card, brackets, edge = makeCard(page, headerHeight)
            card.ClipsDescendants = true
            local click = hitZone(card)
            click.Size = UDim2.new(1, 0, 0, headerHeight)

            local label = createLabel(card, text, 11, Library.Theme.Text, Enum.FontWeight.SemiBold)
            label.Position = UDim2.new(0, 22, 0, 0)
            label.Size = UDim2.new(1, -124, 0, headerHeight)
            local valueLabel = createLabel(card, "SELECT", 8, Library.Theme.Muted, Enum.FontWeight.Bold)
            valueLabel.Position = UDim2.new(1, -118, 0, 6)
            valueLabel.Size = UDim2.new(0, 64, 0, 10)
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right
            local arrow = createLabel(card, "+", 14, Library.Theme.Text2, Enum.FontWeight.Bold)
            arrow.Position = UDim2.new(1, -36, 0, 0)
            arrow.Size = UDim2.new(0, 20, 0, headerHeight)
            arrow.TextXAlignment = Enum.TextXAlignment.Center
            local line = Instance.new("Frame")
            line.Position = UDim2.new(0, 22, 0, headerHeight - 1)
            line.Size = UDim2.new(1, -40, 0, 1)
            line.BackgroundColor3 = Library.Theme.BorderSoft
            line.BackgroundTransparency = 0.4
            line.BorderSizePixel = 0
            line.Parent = card

            local optionsFrame = Instance.new("ScrollingFrame")
            optionsFrame.Position = UDim2.new(0, 22, 0, headerHeight + 6)
            optionsFrame.Size = UDim2.new(1, -40, 0, 0)
            optionsFrame.BackgroundTransparency = 1
            optionsFrame.BorderSizePixel = 0
            optionsFrame.ScrollBarThickness = 2
            optionsFrame.ScrollBarImageColor3 = accent
            optionsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
            optionsFrame.ClipsDescendants = true
            optionsFrame.Parent = card
            local list = Instance.new("UIListLayout")
            list.Padding = UDim.new(0, 3)
            list.Parent = optionsFrame

            local function bodyHeight()
                if #options == 0 then return 8 end
                local visible = math.min(#options, maxVisible)
                return visible * optionHeight + (visible - 1) * 3 + 8
            end
            local function renderOpen(v)
                open = v
                local h = open and headerHeight + bodyHeight() or headerHeight
                spring(card, 0.28, { Size = UDim2.new(1, 0, 0, h) })
                spring(arrow, 0.24, { Rotation = open and 45 or 0 })
                tween(line, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundColor3 = open and accent or Library.Theme.BorderSoft })
                tween(arrow, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { TextColor3 = open and accent or Library.Theme.Text2 })
            end
            local function rebuild()
                for _, child in ipairs(optionsFrame:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                optionsFrame.CanvasSize = UDim2.new(0, 0, 0, #options * optionHeight + math.max(0, #options - 1) * 3 + 4)
                optionsFrame.Size = UDim2.new(1, -40, 0, bodyHeight())
                for _, option in ipairs(options) do
                    local b = Instance.new("TextButton")
                    b.Size = UDim2.new(1, 0, 0, optionHeight)
                    b.BackgroundColor3 = Library.Theme.Surface3
                    b.BackgroundTransparency = 0
                    b.BorderSizePixel = 0
                    b.Text = tostring(option)
                    b.TextColor3 = Library.Theme.Text2
                    b.TextSize = 10
                    b.TextXAlignment = Enum.TextXAlignment.Left
                    b.AutoButtonColor = false
                    font(b, Enum.FontWeight.Medium)
                    b.Parent = optionsFrame
                    addCorner(b, 4)
                    addPadding(b, 10, 8, 0, 0)
                    b.MouseEnter:Connect(function()
                        tween(b, 0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { TextColor3 = accent, BackgroundColor3 = Library.Theme.AccentSoft })
                    end)
                    b.MouseLeave:Connect(function()
                        tween(b, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { TextColor3 = Library.Theme.Text2, BackgroundColor3 = Library.Theme.Surface3 })
                    end)
                    b.Activated:Connect(function()
                        selected = option
                        valueLabel.Text = tostring(option):upper()
                        valueLabel.TextColor3 = accent
                        renderOpen(false)
                        safeCall(callback, option)
                    end)
                end
            end
            rebuild()
            cardHover(click, brackets, edge)
            click.Activated:Connect(function() renderOpen(not open) end)
            return {
                Get = function() return selected end,
                Refresh = function(_, newOptions) options = newOptions or {}; rebuild(); if open then renderOpen(true) end end,
                Set = function(_, value) selected = value; valueLabel.Text = tostring(value):upper(); valueLabel.TextColor3 = accent; safeCall(callback, value) end,
            }
        end

        function API:CreateMultiDropdown(text, options, callback)
            options = options or {}
            local selected = {}
            local open = false
            local optionHeight, headerHeight, maxVisible = 28, 44, 6
            local card, brackets, edge = makeCard(page, headerHeight)
            card.ClipsDescendants = true
            local click = hitZone(card)
            click.Size = UDim2.new(1, 0, 0, headerHeight)

            local label = createLabel(card, text, 11, Library.Theme.Text, Enum.FontWeight.SemiBold)
            label.Position = UDim2.new(0, 22, 0, 0)
            label.Size = UDim2.new(1, -144, 0, headerHeight)

            local valueLabel = createLabel(card, "0 SELECTED", 8, Library.Theme.Muted, Enum.FontWeight.Bold)
            valueLabel.Position = UDim2.new(1, -114, 0, 0)
            valueLabel.Size = UDim2.new(0, 78, 0, headerHeight)
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right

            local arrow = createLabel(card, "+", 14, Library.Theme.Text2, Enum.FontWeight.Bold)
            arrow.Position = UDim2.new(1, -36, 0, 0)
            arrow.Size = UDim2.new(0, 20, 0, headerHeight)
            arrow.TextXAlignment = Enum.TextXAlignment.Center

            local line = Instance.new("Frame")
            line.Position = UDim2.new(0, 22, 0, headerHeight - 1)
            line.Size = UDim2.new(1, -40, 0, 1)
            line.BackgroundColor3 = Library.Theme.BorderSoft
            line.BackgroundTransparency = 0.4
            line.BorderSizePixel = 0
            line.Parent = card

            local optionsFrame = Instance.new("ScrollingFrame")
            optionsFrame.Position = UDim2.new(0, 22, 0, headerHeight + 6)
            optionsFrame.Size = UDim2.new(1, -40, 0, 0)
            optionsFrame.BackgroundTransparency = 1
            optionsFrame.BorderSizePixel = 0
            optionsFrame.ScrollBarThickness = 2
            optionsFrame.ScrollBarImageColor3 = accent
            optionsFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
            optionsFrame.ClipsDescendants = true
            optionsFrame.Parent = card

            local list = Instance.new("UIListLayout")
            list.Padding = UDim.new(0, 3)
            list.Parent = optionsFrame

            local function getValues()
                local values = {}
                for _, option in ipairs(options) do
                    if selected[tostring(option)] then table.insert(values, option) end
                end
                return values
            end

            local function updateSummary()
                local count = #getValues()
                valueLabel.Text = string.format("%d SELECTED", count)
                valueLabel.TextColor3 = count > 0 and accent or Library.Theme.Muted
            end

            local function bodyHeight()
                if #options == 0 then return 8 end
                local visible = math.min(#options, maxVisible)
                return visible * optionHeight + (visible - 1) * 3 + 8
            end

            local function renderOpen(value)
                open = value
                local h = open and headerHeight + bodyHeight() or headerHeight
                spring(card, 0.26, { Size = UDim2.new(1, 0, 0, h) })
                tween(arrow, 0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, { Rotation = open and 45 or 0, TextColor3 = open and accent or Library.Theme.Text2 })
                tween(line, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundColor3 = open and accent or Library.Theme.BorderSoft })
            end

            local function rebuild()
                for _, child in ipairs(optionsFrame:GetChildren()) do
                    if child:IsA("TextButton") then child:Destroy() end
                end
                optionsFrame.CanvasSize = UDim2.new(0, 0, 0, #options * optionHeight + math.max(0, #options - 1) * 3 + 4)
                optionsFrame.Size = UDim2.new(1, -40, 0, bodyHeight())

                for index, option in ipairs(options) do
                    local key = tostring(option)
                    local isSelected = selected[key] == true
                    local row = Instance.new("TextButton")
                    row.Size = UDim2.new(1, 0, 0, optionHeight)
                    row.BackgroundColor3 = isSelected and Library.Theme.AccentSoft or Library.Theme.Surface3
                    row.BorderSizePixel = 0
                    row.Text = ""
                    row.AutoButtonColor = false
                    row.Parent = optionsFrame
                    addCorner(row, 4)

                    local number = createLabel(row, string.format("%02d", index), 8, isSelected and accent or Library.Theme.Muted, Enum.FontWeight.Bold)
                    number.Position = UDim2.new(0, 10, 0, 0)
                    number.Size = UDim2.new(0, 22, 1, 0)

                    local nameLabel = createLabel(row, key, 10, isSelected and Library.Theme.Text or Library.Theme.Text2, Enum.FontWeight.SemiBold)
                    nameLabel.Position = UDim2.new(0, 38, 0, 0)
                    nameLabel.Size = UDim2.new(1, -78, 1, 0)
                    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd

                    local markLabel = createLabel(row, isSelected and "✓" or "○", 11, isSelected and accent or Library.Theme.Muted, Enum.FontWeight.Bold)
                    markLabel.Position = UDim2.new(1, -32, 0, 0)
                    markLabel.Size = UDim2.new(0, 22, 1, 0)
                    markLabel.TextXAlignment = Enum.TextXAlignment.Center

                    row.MouseEnter:Connect(function()
                        if not selected[key] then
                            tween(row, 0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundColor3 = Library.Theme.AccentSoft })
                        end
                    end)
                    row.MouseLeave:Connect(function()
                        if not selected[key] then
                            tween(row, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundColor3 = Library.Theme.Surface3 })
                        else
                            tween(row, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundColor3 = Library.Theme.AccentSoft })
                        end
                    end)
                    row.Activated:Connect(function()
                        selected[key] = not selected[key]
                        updateSummary()
                        task.defer(rebuild)
                        safeCall(callback, getValues())
                    end)
                end
                updateSummary()
            end

            cardHover(click, brackets, edge)
            rebuild()
            click.Activated:Connect(function() renderOpen(not open) end)

            return {
                Get = function()
                    return getValues()
                end,
                Set = function(_, values)
                    table.clear(selected)
                    if type(values) == "table" then
                        for _, value in ipairs(values) do selected[tostring(value)] = true end
                    end
                    rebuild()
                    safeCall(callback, getValues())
                end,
                Refresh = function(_, newOptions)
                    options = newOptions or {}
                    local allowed = {}
                    for _, value in ipairs(options) do allowed[tostring(value)] = true end
                    for key in pairs(selected) do
                        if not allowed[key] then selected[key] = nil end
                    end
                    rebuild()
                    if open then renderOpen(true) end
                end,
                Toggle = function() renderOpen(not open) end,
                IsOpen = function() return open end,
                SelectAll = function()
                    for _, option in ipairs(options) do selected[tostring(option)] = true end
                    rebuild()
                    safeCall(callback, getValues())
                end,
                Clear = function()
                    table.clear(selected)
                    rebuild()
                    safeCall(callback, getValues())
                end,
            }
        end

        function API:CreateMultiSelectDropdown(text, options, callback)
            return self:CreateMultiDropdown(text, options, callback)
        end

        function API:CreateKeybind(text, default, callback)
            local current = default
            local listening = false
            local listenConn
            local card, brackets, edge = makeCard(page, 44)
            local label = createLabel(card, text, 11, Library.Theme.Text, Enum.FontWeight.SemiBold)
            label.Position = UDim2.new(0, 22, 0, 0)
            label.Size = UDim2.new(1, -122, 1, 0)
            local button = Instance.new("TextButton")
            button.Size = UDim2.new(0, 84, 0, 24)
            button.Position = UDim2.new(1, -100, 0.5, -12)
            button.BackgroundColor3 = Library.Theme.Surface3
            button.Text = keyName(current)
            button.TextColor3 = accent
            button.TextSize = 10
            button.AutoButtonColor = false
            font(button, Enum.FontWeight.Bold)
            button.Parent = card
            addCorner(button, 7)
            local stroke = addStroke(button, Library.Theme.Border, 0.55)
            cardHover(button, brackets, edge)
            local function stopListening()
                listening = false
                if listenConn then listenConn:Disconnect(); listenConn = nil end
                button.Text = keyName(current)
                tween(stroke, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Color = Library.Theme.Border, Transparency = 0.55 })
            end
            button.Activated:Connect(function()
                if listening then stopListening(); return end
                listening = true
                button.Text = "PRESS KEY"
                tween(stroke, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Color = accent, Transparency = 0.15 })
                listenConn = UserInputService.InputBegan:Connect(function(input, processed)
                    if not listening then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        current = input.KeyCode
                        stopListening()
                        safeCall(callback, current)
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 then
                        local target = input.Target
                        if target and (target == button or target:IsDescendantOf(button)) then return end
                        current = input.UserInputType
                        stopListening()
                        safeCall(callback, current)
                    end
                end)
            end)
            windowMaid:Add(function() if listenConn then listenConn:Disconnect() end end)
            return { Get = function() return current end, Set = function(_, key) current = key; button.Text = keyName(key) end }
        end

        function API:CreateColorPicker(text, default, callback)
            local current = default or accent
            local h, s, v = Color3.toHSV(current)
            local alphaValue = 0

            local card, brackets, edge = makeCard(page, 220)
            cardHover(card, brackets, edge)

            local label = createLabel(card, text, 11, Library.Theme.Text, Enum.FontWeight.SemiBold)
            label.Position = UDim2.new(0, 22, 0, 10)
            label.Size = UDim2.new(1, -74, 0, 18)

            local preview = Instance.new("Frame")
            preview.Size = UDim2.new(0, 44, 0, 24)
            preview.Position = UDim2.new(1, -62, 0, 8)
            preview.BackgroundColor3 = current
            preview.BorderSizePixel = 0
            preview.Parent = card
            addCorner(preview, 6)
            addStroke(preview, Library.Theme.Border, 0.3)

            local svPanel = Instance.new("Frame")
            svPanel.Position = UDim2.new(0, 22, 0, 38)
            svPanel.Size = UDim2.new(1, -84, 0, 92)
            svPanel.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
            svPanel.BorderSizePixel = 0
            svPanel.ClipsDescendants = true
            svPanel.Parent = card
            addCorner(svPanel, 6)

            local whiteGrad = Instance.new("UIGradient")
            whiteGrad.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(h, 1, 1))
            whiteGrad.Transparency = NumberSequence.new(0, 1)
            whiteGrad.Parent = svPanel

            local blackOverlay = Instance.new("Frame")
            blackOverlay.Size = UDim2.fromScale(1, 1)
            blackOverlay.BackgroundColor3 = Color3.new(0, 0, 0)
            blackOverlay.BackgroundTransparency = 0
            blackOverlay.BorderSizePixel = 0
            blackOverlay.Parent = svPanel

            local blackGrad = Instance.new("UIGradient")
            blackGrad.Rotation = 90
            blackGrad.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(1, 0),
            })
            blackGrad.Parent = blackOverlay

            local svCursor = Instance.new("Frame")
            svCursor.Size = UDim2.new(0, 12, 0, 12)
            svCursor.AnchorPoint = Vector2.new(0.5, 0.5)
            svCursor.BackgroundTransparency = 1
            svCursor.BorderSizePixel = 0
            svCursor.ZIndex = 8
            svCursor.Parent = svPanel
            addStroke(svCursor, Color3.new(1, 1, 1), 0, 2)
            addCorner(svCursor, 6)

            local hueBar = Instance.new("Frame")
            hueBar.Position = UDim2.new(0, 22, 0, 138)
            hueBar.Size = UDim2.new(1, -84, 0, 14)
            hueBar.BackgroundColor3 = Color3.new(1, 1, 1)
            hueBar.BorderSizePixel = 0
            hueBar.ClipsDescendants = true
            hueBar.Parent = card
            addCorner(hueBar, 7)

            local hueGrad = Instance.new("UIGradient")
            local hueKeypoints = {}
            for i = 0, 6 do
                table.insert(hueKeypoints, ColorSequenceKeypoint.new(i / 6, Color3.fromHSV(i / 6, 1, 1)))
            end
            hueGrad.Color = ColorSequence.new(hueKeypoints)
            hueGrad.Parent = hueBar

            local hueCursor = Instance.new("Frame")
            hueCursor.Size = UDim2.new(0, 4, 1, 4)
            hueCursor.AnchorPoint = Vector2.new(0.5, 0.5)
            hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
            hueCursor.BackgroundColor3 = Color3.new(1, 1, 1)
            hueCursor.BorderSizePixel = 0
            hueCursor.ZIndex = 8
            hueCursor.Parent = hueBar
            addStroke(hueCursor, Library.Theme.Text, 0.3, 2)
            addCorner(hueCursor, 3)

            local alphaBar = Instance.new("Frame")
            alphaBar.Position = UDim2.new(0, 22, 0, 160)
            alphaBar.Size = UDim2.new(1, -84, 0, 12)
            alphaBar.BackgroundColor3 = Color3.new(1, 1, 1)
            alphaBar.BorderSizePixel = 0
            alphaBar.ClipsDescendants = true
            alphaBar.Parent = card
            addCorner(alphaBar, 6)

            local checker = Instance.new("Frame")
            checker.Size = UDim2.fromScale(1, 1)
            checker.BackgroundColor3 = Library.Theme.Surface3
            checker.BorderSizePixel = 0
            checker.Parent = alphaBar

            local checkerGrad = Instance.new("UIGradient")
            checkerGrad.Rotation = 90
            checkerGrad.Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, Library.Theme.Surface3),
                ColorSequenceKeypoint.new(0.5, Library.Theme.Surface),
                ColorSequenceKeypoint.new(1, Library.Theme.Surface3),
            })
            checkerGrad.Parent = checker

            local alphaOverlay = Instance.new("Frame")
            alphaOverlay.Size = UDim2.fromScale(1, 1)
            alphaOverlay.BackgroundColor3 = current
            alphaOverlay.BackgroundTransparency = 0
            alphaOverlay.BorderSizePixel = 0
            alphaOverlay.Parent = alphaBar

            local alphaGrad = Instance.new("UIGradient")
            alphaGrad.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 0),
                NumberSequenceKeypoint.new(1, 1),
            })
            alphaGrad.Parent = alphaOverlay

            local alphaCursor = Instance.new("Frame")
            alphaCursor.Size = UDim2.new(0, 3, 1, 4)
            alphaCursor.AnchorPoint = Vector2.new(0.5, 0.5)
            alphaCursor.Position = UDim2.new(0, 0, 0.5, 0)
            alphaCursor.BackgroundColor3 = Color3.new(1, 1, 1)
            alphaCursor.BorderSizePixel = 0
            alphaCursor.ZIndex = 8
            alphaCursor.Parent = alphaBar
            addStroke(alphaCursor, Library.Theme.Text, 0.3, 2)
            addCorner(alphaCursor, 3)

            local swatchRow = Instance.new("Frame")
            swatchRow.Position = UDim2.new(0, 22, 0, 178)
            swatchRow.Size = UDim2.new(1, -44, 0, 16)
            swatchRow.BackgroundTransparency = 1
            swatchRow.Parent = card
            local swatchLayout = Instance.new("UIListLayout")
            swatchLayout.FillDirection = Enum.FillDirection.Horizontal
            swatchLayout.Padding = UDim.new(0, 4)
            swatchLayout.Parent = swatchRow

            local hexRow = Instance.new("Frame")
            hexRow.Position = UDim2.new(0, 22, 0, 198)
            hexRow.Size = UDim2.new(1, -44, 0, 18)
            hexRow.BackgroundTransparency = 1
            hexRow.Parent = card
            local hexLayout = Instance.new("UIListLayout")
            hexLayout.FillDirection = Enum.FillDirection.Horizontal
            hexLayout.Padding = UDim.new(0, 5)
            hexLayout.Parent = hexRow

            local hexBox = Instance.new("TextBox")
            hexBox.Size = UDim2.new(0.45, -3, 1, 0)
            hexBox.BackgroundColor3 = Library.Theme.Surface3
            hexBox.BorderSizePixel = 0
            hexBox.Text = "#" .. current:ToHex()
            hexBox.TextColor3 = Library.Theme.Text
            hexBox.TextSize = 9
            hexBox.ClearTextOnFocus = false
            hexBox.TextXAlignment = Enum.TextXAlignment.Center
            font(hexBox, Enum.FontWeight.Bold)
            hexBox.Parent = hexRow
            addCorner(hexBox, 5)

            local rgbBox = Instance.new("TextBox")
            rgbBox.Size = UDim2.new(0.55, -2, 1, 0)
            rgbBox.BackgroundColor3 = Library.Theme.Surface3
            rgbBox.BorderSizePixel = 0
            rgbBox.Text = string.format("%d, %d, %d",
                math.floor(current.R * 255 + 0.5),
                math.floor(current.G * 255 + 0.5),
                math.floor(current.B * 255 + 0.5))
            rgbBox.TextColor3 = Library.Theme.Text
            rgbBox.TextSize = 9
            rgbBox.ClearTextOnFocus = false
            rgbBox.TextXAlignment = Enum.TextXAlignment.Center
            font(rgbBox, Enum.FontWeight.Bold)
            rgbBox.Parent = hexRow
            addCorner(rgbBox, 5)

            local presets = {
                Color3.fromRGB(229, 57, 53),
                Color3.fromRGB(244, 143, 66),
                Color3.fromRGB(253, 216, 53),
                Color3.fromRGB(67, 160, 71),
                Color3.fromRGB(30, 136, 229),
                Color3.fromRGB(142, 68, 173),
                Color3.fromRGB(255, 255, 255),
                Color3.fromRGB(33, 33, 33),
            }
            for _, presetColor in ipairs(presets) do
                local swatch = Instance.new("TextButton")
                swatch.Size = UDim2.new(0, 14, 1, 0)
                swatch.BackgroundColor3 = presetColor
                swatch.Text = ""
                swatch.AutoButtonColor = false
                swatch.Parent = swatchRow
                addCorner(swatch, 5)
                addStroke(swatch, Library.Theme.Border, 0.6)
                swatch.MouseEnter:Connect(function()
                    tween(swatch, 0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Size = UDim2.new(0, 17, 1, 0) })
                end)
                swatch.MouseLeave:Connect(function()
                    tween(swatch, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Size = UDim2.new(0, 14, 1, 0) })
                end)
                swatch.Activated:Connect(function()
                    current = presetColor
                    h, s, v = Color3.toHSV(current)
                    applyColor()
                end)
            end

            local function applyColor()
                preview.BackgroundColor3 = current
                alphaOverlay.BackgroundColor3 = current
                svPanel.BackgroundColor3 = Color3.fromHSV(h, 1, 1)
                whiteGrad.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromHSV(h, 1, 1))
                svCursor.Position = UDim2.new(s, 0, 1 - v, 0)
                hueCursor.Position = UDim2.new(h, 0, 0.5, 0)
                alphaCursor.Position = UDim2.new(alphaValue, 0, 0.5, 0)
                hexBox.Text = "#" .. current:ToHex()
                rgbBox.Text = string.format("%d, %d, %d",
                    math.floor(current.R * 255 + 0.5),
                    math.floor(current.G * 255 + 0.5),
                    math.floor(current.B * 255 + 0.5))
                safeCall(callback, current, alphaValue)
            end

            local svOwner = {}
            local function svUpdate(input)
                if svPanel.AbsoluteSize.X <= 0 then return end
                local nx = math.clamp((input.Position.X - svPanel.AbsolutePosition.X) / svPanel.AbsoluteSize.X, 0, 1)
                local ny = math.clamp((input.Position.Y - svPanel.AbsolutePosition.Y) / svPanel.AbsoluteSize.Y, 0, 1)
                s, v = nx, 1 - ny
                current = Color3.fromHSV(h, s, v)
                applyColor()
            end
            svPanel.InputBegan:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
                if beginPointer(svOwner, input, svUpdate, function()
                    if page and page.Parent then page.ScrollingEnabled = true end
                end) then
                    if page and page.Parent then page.ScrollingEnabled = false end
                    svUpdate(input)
                end
            end)

            local hueOwner = {}
            local function hueUpdate(input)
                if hueBar.AbsoluteSize.X <= 0 then return end
                local nx = math.clamp((input.Position.X - hueBar.AbsolutePosition.X) / hueBar.AbsoluteSize.X, 0, 1)
                h = nx
                current = Color3.fromHSV(h, s, v)
                applyColor()
            end
            hueBar.InputBegan:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
                if beginPointer(hueOwner, input, hueUpdate, function()
                    if page and page.Parent then page.ScrollingEnabled = true end
                end) then
                    if page and page.Parent then page.ScrollingEnabled = false end
                    hueUpdate(input)
                end
            end)

            local alphaOwner = {}
            local function alphaUpdate(input)
                if alphaBar.AbsoluteSize.X <= 0 then return end
                alphaValue = math.clamp((input.Position.X - alphaBar.AbsolutePosition.X) / alphaBar.AbsoluteSize.X, 0, 1)
                applyColor()
            end
            alphaBar.InputBegan:Connect(function(input)
                if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
                if beginPointer(alphaOwner, input, alphaUpdate, function()
                    if page and page.Parent then page.ScrollingEnabled = true end
                end) then
                    if page and page.Parent then page.ScrollingEnabled = false end
                    alphaUpdate(input)
                end
            end)

            hexBox.FocusLost:Connect(function()
                local raw = hexBox.Text:gsub("#", ""):gsub("%s", ""):gsub("%c", "")
                if #raw == 6 then
                    local ok, parsed = pcall(Color3.fromHex, raw)
                    if ok and parsed then
                        current = parsed
                        h, s, v = Color3.toHSV(current)
                        applyColor()
                    else
                        hexBox.Text = "#" .. current:ToHex()
                    end
                else
                    hexBox.Text = "#" .. current:ToHex()
                end
            end)

            rgbBox.FocusLost:Connect(function()
                local parts = {}
                for part in rgbBox.Text:gmatch("%d+") do table.insert(parts, tonumber(part)) end
                if #parts == 3 then
                    local r = math.clamp(parts[1], 0, 255)
                    local g = math.clamp(parts[2], 0, 255)
                    local b = math.clamp(parts[3], 0, 255)
                    current = Color3.fromRGB(r, g, b)
                    h, s, v = Color3.toHSV(current)
                    applyColor()
                else
                    rgbBox.Text = string.format("%d, %d, %d",
                        math.floor(current.R * 255 + 0.5),
                        math.floor(current.G * 255 + 0.5),
                        math.floor(current.B * 255 + 0.5))
                end
            end)

            applyColor()

            return {
                Get = function() return current end,
                GetAlpha = function() return alphaValue end,
                Set = function(_, color, alpha)
                    current = color
                    h, s, v = Color3.toHSV(current)
                    if alpha ~= nil then alphaValue = math.clamp(alpha, 0, 1) end
                    applyColor()
                end,
            }
        end

        function API:CreateMultiButton(items)
            items = items or {}
            local holder = Instance.new("Frame")
            holder.Size = UDim2.new(1, 0, 0, 38)
            holder.BackgroundTransparency = 1
            holder.Parent = page
            local list = Instance.new("UIListLayout")
            list.FillDirection = Enum.FillDirection.Horizontal
            list.Padding = UDim.new(0, 6)
            list.Parent = holder
            local count = math.max(1, #items)
            for i, item in ipairs(items) do
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(1 / count, -6, 1, 0)
                b.BackgroundColor3 = Library.Theme.Surface2
                b.BackgroundTransparency = 0
                b.Text = tostring(item.text or ("Button " .. i))
                b.TextColor3 = Library.Theme.Text
                b.TextSize = 10
                b.AutoButtonColor = false
                font(b, Enum.FontWeight.Bold)
                b.Parent = holder
                addCorner(b, 8)
                local s = addStroke(b, Library.Theme.BorderSoft, 0.4)
                b.MouseEnter:Connect(function()
                    tween(b, 0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { TextColor3 = accent })
                    tween(s, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Color = accent, Transparency = 0.25 })
                end)
                b.MouseLeave:Connect(function()
                    tween(b, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { TextColor3 = Library.Theme.Text })
                    tween(s, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Color = Library.Theme.BorderSoft, Transparency = 0.4 })
                end)
                b.MouseButton1Down:Connect(function()
                    tween(b, 0.09, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundColor3 = Library.Theme.Surface3 })
                end)
                b.MouseButton1Up:Connect(function()
                    tween(b, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundColor3 = Library.Theme.Surface2 })
                end)
                b.Activated:Connect(function() safeCall(item.callback) end)
            end
            return holder
        end

        return API
    end

    local function createTab(tabName)
        tabName = tostring(tabName or "Tab")
        local page = Instance.new("ScrollingFrame")
        page.Name = tabName .. "Page"
        page.Size = UDim2.fromScale(1, 1)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 0
        page.ElasticBehavior = Enum.ElasticBehavior.Never
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.Visible = false
        page.Position = UDim2.new(0, 0, 0, 0)
        page.Parent = Body

        local scrollRail = Instance.new("Frame")
        scrollRail.Name = "ScrollRail"
        scrollRail.AnchorPoint = Vector2.new(1, 0)
        scrollRail.Position = UDim2.new(1, -4, 0, 10)
        scrollRail.Size = UDim2.new(0, 2, 1, -20)
        scrollRail.BackgroundColor3 = Library.Theme.BorderSoft
        scrollRail.BackgroundTransparency = 0.3
        scrollRail.BorderSizePixel = 0
        scrollRail.ZIndex = 30
        scrollRail.Visible = false
        scrollRail.Parent = Body
        addCorner(scrollRail, 1)

        local scrollThumb = Instance.new("Frame")
        scrollThumb.Name = "ScrollThumb"
        scrollThumb.Size = UDim2.new(1, 0, 0, 34)
        scrollThumb.Position = UDim2.new(0, 0, 0, 0)
        scrollThumb.BackgroundColor3 = accent
        scrollThumb.BackgroundTransparency = 0
        scrollThumb.BorderSizePixel = 0
        scrollThumb.ZIndex = 31
        scrollThumb.Parent = scrollRail
        addCorner(scrollThumb, 1)

        local function updateScrollIndicator()
            if not page.Parent then return end
            local viewportH = page.AbsoluteWindowSize.Y
            local content = page.AbsoluteCanvasSize.Y
            local track = math.max(1, scrollRail.AbsoluteSize.Y)
            if content <= viewportH + 2 then
                scrollRail.Visible = false
                return
            end
            scrollRail.Visible = page.Visible
            local ratio = math.clamp(viewportH / content, 0.12, 1)
            local thumbHeight = math.max(22, track * ratio)
            local maxTravel = math.max(0, track - thumbHeight)
            local maxCanvas = math.max(1, content - viewportH)
            local pct = math.clamp(page.CanvasPosition.Y / maxCanvas, 0, 1)
            scrollThumb.Size = UDim2.new(1, 0, 0, thumbHeight)
            scrollThumb.Position = UDim2.new(0, 0, 0, maxTravel * pct)
        end

        page:GetPropertyChangedSignal("CanvasPosition"):Connect(updateScrollIndicator)
        page:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(updateScrollIndicator)
        page:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(updateScrollIndicator)
        scrollRail:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateScrollIndicator)

        addPadding(page, 12, 16, 12, 12)
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 6)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = page
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 16)
        end)

        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 40)
        button.BackgroundColor3 = Library.Theme.AccentSoft
        button.BackgroundTransparency = 1
        button.Text = ""
        button.AutoButtonColor = false
        button.ZIndex = 20
        button.Parent = TabsScroll
        addCorner(button, 8)
        local tabIndex = createLabel(button, string.format("%02d", #TabButtons + 1), 8, Library.Theme.Muted, Enum.FontWeight.Bold)
        tabIndex.Position = UDim2.new(0, 10, 0, 0)
        tabIndex.Size = UDim2.new(0, 18, 1, 0)
        local label = createLabel(button, tabName, 10, Library.Theme.Text2, Enum.FontWeight.SemiBold)
        label.Position = UDim2.new(0, 16, 0, 0)
        label.Size = UDim2.new(1, -24, 1, 0)

        local record = {
            name = tabName,
            page = page,
            button = button,
            label = label,
            tabIndex = tabIndex,
            scrollRail = scrollRail,
            updateScrollIndicator = updateScrollIndicator,
        }
        table.insert(TabButtons, record)
        button.Activated:Connect(function() selectTab(record) end)
        if not CurrentPage then selectTab(record) end
        return elementAPI(page)
    end

    local tabNames = {}
    local originalCreateTab = createTab
    createTab = function(name)
        local base = tostring(name or "Tab")
        local final = base
        local n = 2
        while tabNames[final] do final = base .. " " .. n; n += 1 end
        tabNames[final] = true
        return originalCreateTab(final)
    end

    local function openWindow()
        if closing or transitioning or isOpen then return end
        isOpen = true
        transitioning = true

        local startPos = Main.Position
        local startSize = Main.AbsoluteSize.X
        local targetSize = windowSize()
        local targetPos = centeredPosition()

        Bubble.Visible = false
        BubbleButton.Visible = false

        Dimmer.Visible = true
        tween(Dimmer, 0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = Library.Theme.DimTransparency })
        tween(MainStroke, 0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Color = accent, Transparency = 0.7 })
        spring(MainCorner, 0.36, { CornerRadius = UDim.new(0, Library.Config.WindowRadius) })
        spring(MainClipCorner, 0.36, { CornerRadius = UDim.new(0, Library.Config.WindowRadius) })

        Main.Size = UDim2.fromOffset(startSize, startSize)
        Main.Position = startPos

        local t = tween(Main, Library.Config.OpenDuration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out, {
            Size = targetSize,
            Position = targetPos,
        })
        if t then
            t.Completed:Connect(function()
                Content.Visible = true
                transitioning = false
                fitToViewport()
            end)
        else
            Content.Visible = true
            transitioning = false
        end
    end

    local function minimizeWindow()
        if transitioning or closing or not isOpen then return end
        isOpen = false
        transitioning = true

        Content.Visible = false

        local fs = floatingSize()
        floatingPosition = clampFloating(floatingPosition, Vector2.new(fs, fs))
        local targetPos = floatingPosition

        tween(Dimmer, 0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { BackgroundTransparency = 1 })
        task.delay(0.22, function() if Dimmer.Parent and not isOpen then Dimmer.Visible = false end end)
        tween(MainStroke, 0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Color = Library.Theme.Border, Transparency = 0.3 })
        spring(MainCorner, 0.32, { CornerRadius = UDim.new(0, Library.Config.BubbleRadius) })
        spring(MainClipCorner, 0.32, { CornerRadius = UDim.new(0, Library.Config.BubbleRadius) })

        local t = tween(Main, Library.Config.CloseDuration, Enum.EasingStyle.Quint, Enum.EasingDirection.InOut, {
            Size = UDim2.fromOffset(fs, fs),
            Position = targetPos,
        })
        if t then
            t.Completed:Connect(function()
                transitioning = false
                Bubble.Visible = true
                BubbleButton.Visible = true
                fitToViewport()
            end)
        else
            transitioning = false
            Bubble.Visible = true
            BubbleButton.Visible = true
        end
    end

    minimizeButton = headerButton("−", -74, minimizeWindow)
    closeButton = headerButton("×", -40, function()
        if closing then return end
        closing = true
        transitioning = true
        Dimmer.BackgroundTransparency = 1
        local vp = viewport()
        tween(MainStroke, 0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.In, { Transparency = 1, Color = accent })
        local t = tween(Main, 0.32, Enum.EasingStyle.Back, Enum.EasingDirection.In, {
            Size = UDim2.fromOffset(6, 6),
            Position = UDim2.fromOffset(vp.X / 2, vp.Y / 2),
            BackgroundTransparency = 1,
            Rotation = 32,
        })
        if t then t.Completed:Connect(function() windowMaid:Destroy() end) else windowMaid:Destroy() end
    end)

    local dragOwner = {}
    local clickStart
    local dragStart
    local dragging = false

    BubbleButton.InputBegan:Connect(function(input)
        if isOpen or closing or transitioning then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        clickStart = input.Position
        dragStart = Main.AbsolutePosition + Main.AbsoluteSize / 2
        dragging = false
        if not beginPointer(dragOwner, input, function(moveInput)
            if not clickStart then return end
            local delta = moveInput.Position - clickStart
            if not dragging and delta.Magnitude > Library.Config.TapThreshold * 0.4 then
                dragging = true
                local fs = floatingSize()
                spring(Main, 0.20, { Size = UDim2.fromOffset(fs + 4, fs + 4) })
                tween(MainStroke, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Color = accent, Transparency = 0.4 })
            end
            if dragging then
                local targetCenter = dragStart + delta
                local fs = floatingSize() + 4
                local newPos = clampFloating(UDim2.fromOffset(targetCenter.X, targetCenter.Y), Vector2.new(fs, fs))
                Main.Position = newPos
                floatingPosition = newPos
            end
        end, function(endInput)
            if clickStart then
                local moved = (endInput.Position - clickStart).Magnitude
                if moved < Library.Config.TapThreshold then
                    openWindow()
                else
                    local fs = floatingSize()
                    floatingPosition = clampFloating(Main.Position, Vector2.new(fs, fs))
                    spring(Main, 0.28, { Position = floatingPosition, Size = UDim2.fromOffset(fs, fs) })
                    tween(MainStroke, 0.20, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Color = Library.Theme.Border, Transparency = 0.3 })
                end
            end
            clickStart, dragStart, dragging = nil, nil, false
        end) then
            clickStart, dragStart = nil, nil
        end
    end)

    local DragHandle = hitZone(Header)
    DragHandle.Name = "DragHandle"
    DragHandle.Position = UDim2.new(0, 0, 0, 0)
    DragHandle.Size = UDim2.new(1, -88, 1, 0)
    local headerDragOwner = {}
    DragHandle.InputBegan:Connect(function(input)
        if not isOpen or closing or transitioning then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        local startInput = input.Position
        local startCenter = Main.AbsolutePosition + Main.AbsoluteSize / 2
        beginPointer(headerDragOwner, input, function(moveInput)
            local delta = moveInput.Position - startInput
            local vp = viewport()
            local half = Main.AbsoluteSize / 2
            local cx = math.clamp(startCenter.X + delta.X, half.X + 8, math.max(half.X + 8, vp.X - half.X - 8))
            local cy = math.clamp(startCenter.Y + delta.Y, half.Y + 8, math.max(half.Y + 8, vp.Y - half.Y - 8))
            Main.Position = UDim2.fromOffset(cx, cy)
            floatingPosition = Main.Position
        end, function() end)
    end)

    local frames, last = 0, os.clock()
    local fpsConn = RunService.Heartbeat:Connect(function()
        if not isOpen or closing then return end
        frames += 1
        local now = os.clock()
        if now - last >= 1 then
            fpsLabel.Text = string.format("%d FPS", math.floor(frames / (now - last)))
            frames, last = 0, now
        end
    end)
    windowMaid:Add(fpsConn)

    local Window = {}
    function Window:SetVisible(value)
        if value then openWindow() else minimizeWindow() end
    end
    function Window:IsOpen() return isOpen end
    function Window:CreateTab(name) return createTab(name) end
    function Window:SelectTab(name)
        for _, item in ipairs(TabButtons) do
            if item.name == tostring(name) then selectTab(item); return true end
        end
        return false
    end
    function Window:GetTabs()
        local out = {}
        for _, item in ipairs(TabButtons) do table.insert(out, item.name) end
        return out
    end
    function Window:Destroy()
        if not closing then closing = true end
        endPointer(dragOwner)
        endPointer(headerDragOwner)
        windowMaid:Destroy()
    end
    function Window:GetScreenGui() return ScreenGui end
    function Window:SetStatus(text) statusLabel.Text = tostring(text) end
    function Window:SetAccent(color)
        if typeof(color) ~= "Color3" then return end
        accent = color
        Library.Theme.Accent = color
        statusLabel.TextColor3 = color
        TabIndicator.BackgroundColor3 = color
        for _, item in ipairs(TabButtons) do
            if item.tabIndex then
                item.tabIndex.TextColor3 = item == CurrentPage and color or Library.Theme.Muted
            end
        end
        for _, obj in ipairs(ScreenGui:GetDescendants()) do
            if obj.Name == "AccentMark" or obj.Name == "CardEdge" or obj.Name == "AccentFill" or obj.Name == "ScrollThumb" then
                if obj:IsA("GuiObject") then obj.BackgroundColor3 = color end
            end
        end
    end

    return Window
end

function Library:SetCustomFont(fontAssetId)
    local family
    if typeof(fontAssetId) == "number" then
        local ok, f = pcall(Font.fromId, fontAssetId)
        if ok and f then family = f.Family end
    elseif type(fontAssetId) == "string" then
        family = fontAssetId
    end
    if not family then return false end
    Library.FontFamily = family
    local root = parentGui()
    for _, gui in ipairs(root:GetChildren()) do
        if gui.Name:match("^QWQWindow_") or gui.Name == "QWQNotifications" then
            for _, item in ipairs(gui:GetDescendants()) do
                if item:IsA("TextLabel") or item:IsA("TextButton") or item:IsA("TextBox") then
                    font(item, Enum.FontWeight.Medium)
                end
            end
        end
    end
    return true
end

Library.Compatibility = {
    Version = "16.x",
    PreservesV4API = true,
    MobileFirst = true,
}

return Library