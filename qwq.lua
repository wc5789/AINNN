--[[
    QWQ UI Library V8
    Rebuilt commercial-style mobile-first Roblox UI framework
    Focus: consistent design system, deterministic cleanup, touch-safe input,
    responsive layout, extensible component API.
]]

local Library = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

Library.Version = "8.0.0"
Library.Theme = {
    Accent = Color3.fromRGB(104, 92, 224),
    AccentSoft = Color3.fromRGB(231, 227, 255),
    AccentDeep = Color3.fromRGB(75, 63, 175),
    Background = Color3.fromRGB(248, 247, 244),
    Surface = Color3.fromRGB(255, 255, 255),
    Surface2 = Color3.fromRGB(239, 238, 234),
    Surface3 = Color3.fromRGB(224, 224, 220),
    Border = Color3.fromRGB(202, 201, 197),
    BorderSoft = Color3.fromRGB(220, 219, 214),
    Text = Color3.fromRGB(39, 39, 43),
    Text2 = Color3.fromRGB(100, 99, 103),
    Muted = Color3.fromRGB(151, 149, 145),
    White = Color3.fromRGB(255, 255, 255),
    Success = Color3.fromRGB(43, 164, 105),
    Warning = Color3.fromRGB(222, 146, 45),
    Error = Color3.fromRGB(211, 72, 83),
    Dim = Color3.fromRGB(64, 68, 80),
    DimTransparency = 0.86,
}

Library.FontFamily = "rbxasset://fonts/families/BuilderSans.json"
Library.Config = {
    MobileBreakpoint = 560,
    DesktopWidth = 600,
    DesktopHeight = 410,
    MobileWidth = 0.92,
    MobileHeight = 0.80,
    Animation = 0.14,
    SpringAnimation = 0.30,
    SnapAnimation = 0.09,
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
    return tween(object, duration or Library.Config.SpringAnimation, Enum.EasingStyle.Back, direction or Enum.EasingDirection.Out, properties)
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

local function round(v, decimals)
    local p = 10 ^ (decimals or 0)
    return math.floor(v * p + 0.5) / p
end

local function addCorner(object, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
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

-- ================================================================
-- Cleanup / lifecycle
-- ================================================================
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

-- Input ownership is explicit, but each drag tracks its initiating input.
-- This avoids mouse/touch crossover and prevents a slider or window from stealing a drag.
local Pointer = { owner = nil, input = nil, move = nil, ended = nil }
local pointerMoveConn = UserInputService.InputChanged:Connect(function(input)
    if not Pointer.owner then return end
    if Pointer.input and input.UserInputType == Enum.UserInputType.MouseMovement then
        Pointer.move(input)
    elseif Pointer.input and input == Pointer.input then
        Pointer.move(input)
    end
end)
local pointerEndConn = UserInputService.InputEnded:Connect(function(input)
    if not Pointer.owner then return end
    local matches = input == Pointer.input or input.UserInputType == Enum.UserInputType.MouseButton1
    if matches then
        local ended = Pointer.ended
        Pointer.owner, Pointer.input, Pointer.move, Pointer.ended = nil, nil, nil, nil
        if ended then pcall(ended, input) end
    end
end)

local function beginPointer(owner, input, move, ended)
    if Pointer.owner then return false end
    Pointer.owner, Pointer.input, Pointer.move, Pointer.ended = owner, input, move, ended
    return true
end

local function endPointer(owner)
    if Pointer.owner == owner then
        Pointer.owner, Pointer.input, Pointer.move, Pointer.ended = nil, nil, nil, nil
    end
end

-- ================================================================
-- Surface system
-- ================================================================
local function surface(object, radius, opts)
    opts = opts or {}
    object.BackgroundColor3 = opts.color or Library.Theme.Surface
    object.BackgroundTransparency = opts.transparency == nil and 0.04 or opts.transparency
    object.BorderSizePixel = 0
    addCorner(object, radius or 3)
    if opts.stroke ~= false then
        addStroke(object, opts.strokeColor or Library.Theme.BorderSoft, opts.strokeTransparency == nil and 0.42 or opts.strokeTransparency, opts.strokeThickness or 1)
    end
    return object
end

local function pressable(button, normal, hover, pressed)
    button.AutoButtonColor = false
    button.MouseEnter:Connect(function()
        if hover then tween(button, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, hover) end
    end)
    button.MouseLeave:Connect(function()
        if normal then tween(button, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, normal) end
    end)
    button.MouseButton1Down:Connect(function()
        if pressed then tween(button, 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, pressed) end
    end)
    button.MouseButton1Up:Connect(function()
        if hover then tween(button, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, hover) end
    end)
end

-- ================================================================
-- Notifications
-- ================================================================
local NotificationGui
local NotificationList
local NotificationMaid = Maid()

local function ensureNotifications()
    if NotificationGui and NotificationGui.Parent then return NotificationList end
    NotificationGui = Instance.new("ScreenGui")
    NotificationGui.Name = "QWQNotifications"
    NotificationGui.ResetOnSpawn = false
    NotificationGui.IgnoreGuiInset = true
    NotificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    NotificationGui.Parent = parentGui()
    NotificationMaid:Add(NotificationGui)

    NotificationList = Instance.new("Frame")
    NotificationList.AnchorPoint = Vector2.new(1, 1)
    NotificationList.Position = UDim2.new(1, -14, 1, -14)
    NotificationList.Size = UDim2.new(0, 310, 0, 420)
    NotificationList.BackgroundTransparency = 1
    NotificationList.Parent = NotificationGui

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = NotificationList
    return NotificationList
end

local function makeNotification(title, message, duration, kind)
    local list = ensureNotifications()
    local colors = {info=Library.Theme.Accent, success=Library.Theme.Success, warn=Library.Theme.Warning, error=Library.Theme.Error}
    local accent = colors[kind] or colors.info

    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(1, 0, 0, 58)
    toast.BackgroundColor3 = Library.Theme.Surface
    toast.BackgroundTransparency = 1
    toast.BorderSizePixel = 0
    toast.ClipsDescendants = true
    toast.LayoutOrder = os.clock() * 1000
    toast.Parent = list
    addCorner(toast, 3)
    local stroke = addStroke(toast, Library.Theme.Border, 1)

    local code = createLabel(toast, kind == "success" and "OK" or kind == "error" and "ERR" or kind == "warn" and "WARN" or "INFO", 7, accent, Enum.FontWeight.Bold)
    code.Position = UDim2.new(0, 10, 0, 7)
    code.Size = UDim2.new(0, 20, 0, 10)
    local titleLabel = createLabel(toast, tostring(title):upper(), 10, Library.Theme.Text, Enum.FontWeight.Bold)
    titleLabel.Position = UDim2.new(0, 48, 0, 5)
    titleLabel.Size = UDim2.new(1, -60, 0, 14)
    local descLabel = createLabel(toast, tostring(message), 9, Library.Theme.Text2, Enum.FontWeight.Medium)
    descLabel.Position = UDim2.new(0, 48, 0, 21)
    descLabel.Size = UDim2.new(1, -60, 0, 28)
    descLabel.TextWrapped = true
    descLabel.TextYAlignment = Enum.TextYAlignment.Top

    local rule = Instance.new("Frame")
    rule.Position = UDim2.new(0, 10, 1, -5)
    rule.Size = UDim2.new(1, -20, 0, 1)
    rule.BackgroundColor3 = Library.Theme.BorderSoft
    rule.BorderSizePixel = 0
    rule.Parent = toast
    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(0,1)
    fill.BackgroundColor3 = accent
    fill.BorderSizePixel = 0
    fill.Parent = rule

    local startSize = UDim2.new(1,0,0,0)
    toast.Size = startSize
    spring(toast, 0.34, {Size = UDim2.new(1,0,0,58), BackgroundTransparency = 0.04})
    tween(stroke, 0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Transparency = 0.48})
    tween(fill, math.max(0.1,duration or 3), Enum.EasingStyle.Linear, Enum.EasingDirection.Out, {Size = UDim2.new(1,0,1,0)})

    task.delay(duration or 3, function()
        if not toast.Parent then return end
        tween(stroke, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.In, {Transparency = 1})
        local out=spring(toast,0.28,{Size=UDim2.new(1,0,0,0),BackgroundTransparency=1},Enum.EasingDirection.In)
        if out then out.Completed:Connect(function() if toast.Parent then toast:Destroy() end end) end
    end)
end

function Library:Notify(title, message, duration, kind)
    makeNotification(title or "QWQ", message or "", duration or 3, kind or "info")
end
function Library:Success(message, duration) self:Notify("Success", message, duration or 2.6, "success") end
function Library:Warn(message, duration) self:Notify("Warning", message, duration or 3, "warn") end
function Library:Error(message, duration) self:Notify("Error", message, duration or 3.4, "error") end

-- ================================================================
-- Window
-- ================================================================
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
    ScreenGui.Parent = guiParent
    windowMaid:Add(ScreenGui)

    local Dimmer = Instance.new("Frame")
    Dimmer.Size = UDim2.fromScale(1, 1)
    Dimmer.BackgroundColor3 = Library.Theme.Dim
    Dimmer.BackgroundTransparency = 1
    Dimmer.BorderSizePixel = 0
    Dimmer.ZIndex = 1
    Dimmer.Parent = ScreenGui

    local Main = Instance.new("Frame")
    Main.Name = "Main"
    Main.AnchorPoint = Vector2.new(0, 0)
    Main.Position = UDim2.fromOffset(0, 0)
    Main.Size = UDim2.new(0, 56, 0, 56)
    Main.BackgroundColor3 = Library.Theme.Surface
    Main.BackgroundTransparency = 0
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Main.ZIndex = 10
    Main.Parent = ScreenGui
    local MainCorner = addCorner(Main, 8)
    local MainStroke = addStroke(Main, Library.Theme.Border, 0.12)

    local UIScale = Instance.new("UIScale")
    UIScale.Scale = 1
    UIScale.Parent = Main

    local Bubble = Instance.new("Frame")
    Bubble.Size = UDim2.fromScale(1, 1)
    Bubble.BackgroundTransparency = 1
    Bubble.Parent = Main
    local bubbleLayout = Instance.new("UIListLayout")
    bubbleLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
    bubbleLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    bubbleLayout.Parent = Bubble
    local BubbleMark = Instance.new("Frame")
    BubbleMark.Size = UDim2.new(0, 26, 0, 26)
    BubbleMark.BackgroundTransparency = 1
    BubbleMark.Parent = Bubble
    local markA = Instance.new("Frame")
    markA.Size = UDim2.new(0, 18, 0, 3)
    markA.Position = UDim2.new(0, 4, 0, 5)
    markA.BackgroundColor3 = Library.Theme.Text
    markA.BorderSizePixel = 0
    markA.Parent = BubbleMark
    local markB = Instance.new("Frame")
    markB.Size = UDim2.new(0, 10, 0, 3)
    markB.Position = UDim2.new(0, 4, 0, 11)
    markB.BackgroundColor3 = accent
    markB.BorderSizePixel = 0
    markB.Parent = BubbleMark
    local markC = Instance.new("Frame")
    markC.Size = UDim2.new(0, 18, 0, 3)
    markC.Position = UDim2.new(0, 4, 0, 17)
    markC.BackgroundColor3 = Library.Theme.Text
    markC.BorderSizePixel = 0
    markC.Parent = BubbleMark

    local Content = Instance.new("Frame")
    Content.Size = UDim2.fromScale(1, 1)
    Content.BackgroundTransparency = 1
    Content.ClipsDescendants = true
    Content.Visible = false
    Content.Parent = Main

    local isOpen = false
    local closing = false
    local transitioning = false
    local floatingPosition = UDim2.fromOffset(0, 0)

    local function isMobile()
        local camera = workspace.CurrentCamera
        return camera and camera.ViewportSize.X < Library.Config.MobileBreakpoint
    end

    local function floatingSize()
        return isMobile() and 52 or 56
    end

    local function updateResponsive()
        if not Main.Parent or isOpen then return end
        local fs = floatingSize()
        Main.Size = UDim2.new(0, fs, 0, fs)
    end
    local cameraConn = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        task.defer(function()
            updateResponsive()
            if not Main.Parent then return end
            local camera = workspace.CurrentCamera
            if not camera then return end
            local vp = camera.ViewportSize
            local sx, sy = Main.AbsoluteSize.X, Main.AbsoluteSize.Y
            if not isOpen then
                local p = Main.Position
                local x = math.clamp(p.X.Offset, 8, math.max(8, vp.X - sx - 8))
                local y = math.clamp(p.Y.Offset, 8, math.max(8, vp.Y - sy - 8))
                floatingPosition = UDim2.fromOffset(x, y)
                Main.Position = floatingPosition
            end
        end)
    end)
    windowMaid:Add(cameraConn)
    updateResponsive()
    do
        local camera = workspace.CurrentCamera
        local vp = camera and camera.ViewportSize or Vector2.new(800, 600)
        local bw = floatingSize()
        floatingPosition = UDim2.fromOffset(math.max(10, vp.X - bw - 18), math.max(10, vp.Y - bw - 74))
        Main.Position = floatingPosition
    end

    local function windowSize()
        local camera = workspace.CurrentCamera
        local vp = camera and camera.ViewportSize or Vector2.new(800, 600)
        if vp.X < Library.Config.MobileBreakpoint then
            return UDim2.new(Library.Config.MobileWidth, 0, Library.Config.MobileHeight, 0)
        end
        local w = math.min(Library.Config.DesktopWidth, vp.X - 28)
        local h = math.min(Library.Config.DesktopHeight, vp.Y - 28)
        return UDim2.new(0, w, 0, h)
    end

    -- Header
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, 58)
    Header.BackgroundColor3 = Library.Theme.Surface
    Header.BackgroundTransparency = 0.0
    Header.BorderSizePixel = 0
    Header.ClipsDescendants = true
    Header.Parent = Content
    local headerLine = Instance.new("Frame")
    headerLine.Position = UDim2.new(0, 12, 1, -1)
    headerLine.Size = UDim2.new(1, -24, 0, 1)
    headerLine.BackgroundColor3 = Library.Theme.Border
    headerLine.BorderSizePixel = 0
    headerLine.Parent = Header

    local Brand = Instance.new("Frame")
    Brand.Size = UDim2.new(1, -100, 1, 0)
    Brand.BackgroundTransparency = 1
    Brand.Parent = Header
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 5, 0, 5)
    dot.Position = UDim2.new(0, 17, 0.5, -2)
    dot.BackgroundColor3 = accent
    dot.BorderSizePixel = 0
    dot.Parent = Brand
    addCorner(dot, 2)
    -- Deliberately static status indicator: subtle products do not constantly pulse.

    local title = createLabel(Brand, titleText or "QWQ", 13, Library.Theme.Text, Enum.FontWeight.Bold)
    title.Position = UDim2.new(0, 29, 0, 0)
    title.Size = UDim2.new(1, -38, 0, 34)
    title.TextYAlignment = Enum.TextYAlignment.Bottom

    local headerMeta = createLabel(Brand, "QWQ / STUDIO UI", 7, Library.Theme.Muted, Enum.FontWeight.Bold)
    headerMeta.Position = UDim2.new(0, 29, 0, 34)
    headerMeta.Size = UDim2.new(1, -38, 0, 13)
    headerMeta.TextXAlignment = Enum.TextXAlignment.Left

    local function headerButton(symbol, x, callback)
        local b = Instance.new("TextButton")
        b.Size = UDim2.new(0, 28, 0, 28)
        b.Position = UDim2.new(1, x, 0.5, -14)
        b.BackgroundColor3 = Library.Theme.Surface2
        b.BackgroundTransparency = 0.1
        b.Text = symbol
        b.TextColor3 = Library.Theme.Text2
        b.TextSize = 13
        b.AutoButtonColor = false
        font(b, Enum.FontWeight.Bold)
        b.Parent = Header
        addCorner(b, 3)
        pressable(b, {BackgroundTransparency = 0.1}, {BackgroundTransparency = 0}, {BackgroundTransparency = 0})
        b.Activated:Connect(callback)
        return b
    end

    local tabsButton
    local minimizeButton
    local closeButton

    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Position = UDim2.new(0, 0, 0, 58)
    Sidebar.Size = UDim2.new(0, 144, 1, -58)
    Sidebar.BackgroundColor3 = Library.Theme.Background
    Sidebar.BackgroundTransparency = 0.25
    Sidebar.ClipsDescendants = true
    Sidebar.Parent = Content

    local TabsScroll = Instance.new("ScrollingFrame")
    TabsScroll.Position = UDim2.new(0, 10, 0, 12)
    TabsScroll.Size = UDim2.new(1, -20, 1, -70)
    TabsScroll.BackgroundTransparency = 1
    TabsScroll.BorderSizePixel = 0
    TabsScroll.ScrollBarThickness = 0
    TabsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabsScroll.ClipsDescendants = true
    TabsScroll.Parent = Sidebar
    local tabsLayout = Instance.new("UIListLayout")
    tabsLayout.Padding = UDim.new(0, 3)
    tabsLayout.Parent = TabsScroll
    tabsLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        TabsScroll.CanvasSize = UDim2.new(0, 0, 0, tabsLayout.AbsoluteContentSize.Y + 8)
    end)

    local Status = Instance.new("Frame")
    Status.Position = UDim2.new(0, 10, 1, -52)
    Status.Size = UDim2.new(1, -20, 0, 40)
    Status.BackgroundColor3 = Library.Theme.Surface2
    Status.BackgroundTransparency = 0.25
    Status.Parent = Sidebar
    addCorner(Status, 2)
    addStroke(Status, Library.Theme.Border, 0.75)
    local statusLabel = createLabel(Status, "ONLINE", 9, accent, Enum.FontWeight.Bold)
    statusLabel.Position = UDim2.new(0, 9, 0, 4)
    statusLabel.Size = UDim2.new(1, -18, 0, 13)
    local fpsLabel = createLabel(Status, "-- FPS", 9, Library.Theme.Muted, Enum.FontWeight.Medium)
    fpsLabel.Position = UDim2.new(0, 9, 0, 21)
    fpsLabel.Size = UDim2.new(1, -18, 0, 13)

    -- Layout is declared before the responsive pass to keep responsive metrics deterministic.
    local Body = Instance.new("Frame")
    Body.Name = "Body"
    Body.Position = UDim2.new(0, 144, 0, 58)
    Body.Size = UDim2.new(1, -144, 1, -58)
    Body.BackgroundTransparency = 1
    Body.ClipsDescendants = true
    Body.Parent = Content

    local cameraResponsive = workspace.CurrentCamera
    local function updateLayoutMetrics()
        if not Content.Parent then return end
        local camera = workspace.CurrentCamera
        local vp = camera and camera.ViewportSize or Vector2.new(800, 600)
        local compact = vp.X < Library.Config.MobileBreakpoint
        local side = compact and 102 or 150
        local headerHeight = compact and 54 or 58
        Sidebar.Position = UDim2.new(0, 0, 0, headerHeight)
        Sidebar.Size = UDim2.new(0, side, 1, -headerHeight)
        TabsScroll.Position = UDim2.new(0, compact and 5 or 8, 0, 12)
        TabsScroll.Size = UDim2.new(1, -(compact and 10 or 16), 1, -70)
        Status.Position = UDim2.new(0, compact and 5 or 8, 1, -50)
        Status.Size = UDim2.new(1, -(compact and 10 or 16), 0, 40)
        Body.Position = UDim2.new(0, side, 0, headerHeight)
        Body.Size = UDim2.new(1, -side, 1, -headerHeight)
    end
    updateLayoutMetrics()
    if cameraResponsive then
        windowMaid:Add(cameraResponsive:GetPropertyChangedSignal("ViewportSize"):Connect(updateLayoutMetrics))
    end
    windowMaid:Add(workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        task.defer(function()
            local camera = workspace.CurrentCamera
            if camera then
                windowMaid:Add(camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateLayoutMetrics))
            end
            updateLayoutMetrics()
        end)
    end))

    local Pages = {}
    local TabButtons = {}
    local CurrentPage

    local function selectTab(record)
        for _, item in ipairs(TabButtons) do
            local active = item == record
            tween(item.button, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
                BackgroundTransparency = active and 0.05 or 1,
            })
            tween(item.label, 0.17, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
                TextColor3 = active and Library.Theme.Text or Library.Theme.Text2,
            })
            if item.tabIndex then
                tween(item.tabIndex, 0.17, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
                    TextColor3 = active and accent or Library.Theme.Muted,
                })
            end
            spring(item.marker, 0.25, {
                BackgroundTransparency = active and 0 or 1,
                Size = active and UDim2.new(0, 3, 0, 22) or UDim2.new(0, 2, 0, 20),
            })
            item.page.Visible = active
            if item.scrollRail then
                item.scrollRail.Visible = active
                task.defer(function()
                    if item.updateScrollIndicator then item.updateScrollIndicator() end
                end)
            end
        end
        CurrentPage = record
    end

    local cardIndex = 0
    local function makeCard(parent, height)
        cardIndex += 1
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, height)
        surface(card, 5, {transparency = 0.0, strokeTransparency = 0.22})
        card.Parent = parent

        local cornerMark = Instance.new("Frame")
        cornerMark.Name = "AccentMark"
        cornerMark.Size = UDim2.new(0, 7, 0, 7)
        cornerMark.Position = UDim2.new(0, 0, 0, 0)
        cornerMark.BackgroundColor3 = accent
        cornerMark.BorderSizePixel = 0
        cornerMark.Parent = card

        local edge = Instance.new("Frame")
        edge.Name = "CardEdge"
        edge.Size = UDim2.new(1, -18, 0, 1)
        edge.Position = UDim2.new(0, 9, 0, 0)
        edge.BackgroundColor3 = accent
        edge.BackgroundTransparency = 0.82
        edge.BorderSizePixel = 0
        edge.Parent = card

        card.MouseEnter:Connect(function()
            tween(edge, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 0.48})
            tween(cornerMark, 0.16, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {Size = UDim2.new(0, 10, 0, 10)})
        end)
        card.MouseLeave:Connect(function()
            tween(edge, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 0.82})
            tween(cornerMark, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Size = UDim2.new(0, 7, 0, 7)})
        end)
        return card
    end

    local function elementAPI(page)
        local API = {}

        function API:CreateLabel(text)
            local holder = Instance.new("Frame")
            holder.Size = UDim2.new(1, 0, 0, 22)
            holder.BackgroundTransparency = 1
            holder.Parent = page
            local l = createLabel(holder, text, 11, Library.Theme.Text2, Enum.FontWeight.SemiBold)
            l.Size = UDim2.fromScale(1, 1)
            return l
        end

        function API:CreateSection(text)
            local holder = Instance.new("Frame")
            holder.Size = UDim2.new(1, 0, 0, 28)
            holder.BackgroundTransparency = 1
            holder.Parent = page
            local mark = Instance.new("Frame")
            mark.Size = UDim2.new(0, 2, 0, 11)
            mark.Position = UDim2.new(0, 0, 0.5, -5.5)
            mark.BackgroundColor3 = accent
            mark.BorderSizePixel = 0
            mark.Parent = holder
            addCorner(mark, 2)
            local l = createLabel(holder, tostring(text), 9, Library.Theme.Text2, Enum.FontWeight.Bold)
            l.Position = UDim2.new(0, 9, 0, 0)
            l.Size = UDim2.new(1, -10, 1, 0)
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
            line.Size = UDim2.new(1, -18, 0, 1)
            line.BackgroundColor3 = Library.Theme.Border
            line.BackgroundTransparency = 0.25
            line.BorderSizePixel = 0
            line.Parent = holder
            return holder
        end

        function API:CreateParagraph(text, height)
            local card = makeCard(page, height or 64)
            local l = createLabel(card, text, 10, Library.Theme.Text2, Enum.FontWeight.Medium)
            l.Position = UDim2.new(0, 12, 0, 8)
            l.Size = UDim2.new(1, -24, 1, -16)
            l.TextWrapped = true
            l.TextYAlignment = Enum.TextYAlignment.Top
            return {Frame = card, SetText = function(_, value) l.Text = tostring(value) end}
        end

        function API:CreateButton(text, callback)
            local b = makeCard(page, 40)
            b.Name = "ActionRow"
            local hit = Instance.new("TextButton")
            hit.Size = UDim2.fromScale(1, 1)
            hit.BackgroundTransparency = 1
            hit.Text = ""
            hit.AutoButtonColor = false
            hit.Parent = b

            local label = createLabel(b, text, 11, Library.Theme.Text, Enum.FontWeight.SemiBold)
            label.Position = UDim2.new(0, 20, 0, 0)
            label.Size = UDim2.new(1, -62, 1, 0)

            local meta = createLabel(b, "EXEC", 7, Library.Theme.Muted, Enum.FontWeight.Bold)
            meta.Position = UDim2.new(1, -62, 0, 5)
            meta.Size = UDim2.new(0, 42, 0, 10)
            meta.TextXAlignment = Enum.TextXAlignment.Right

            local line = Instance.new("Frame")
            line.AnchorPoint = Vector2.new(1, 0.5)
            line.Position = UDim2.new(1, -13, 0.5, 7)
            line.Size = UDim2.new(0, 20, 0, 1)
            line.BackgroundColor3 = Library.Theme.Border
            line.BorderSizePixel = 0
            line.Parent = b

            hit.MouseEnter:Connect(function()
                tween(label, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextColor3 = Library.Theme.White})
                tween(line, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Size = UDim2.new(0, 30, 0, 1), BackgroundColor3 = accent})
                tween(meta, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextColor3 = accent})
            end)
            hit.MouseLeave:Connect(function()
                tween(label, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextColor3 = Library.Theme.Text})
                tween(line, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Size = UDim2.new(0, 20, 0, 1), BackgroundColor3 = Library.Theme.Border})
                tween(meta, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextColor3 = Library.Theme.Muted})
            end)
            hit.MouseButton1Down:Connect(function()
                tween(b, 0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 0.00})
            end)
            hit.MouseButton1Up:Connect(function()
                tween(b, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 0.02})
            end)
            hit.Activated:Connect(function() safeCall(callback) end)
            return hit
        end

        function API:CreateToggle(text, default, callback)
            local state = default == true
            local card = makeCard(page, 46)
            local click = Instance.new("TextButton")
            click.Size = UDim2.fromScale(1, 1)
            click.BackgroundTransparency = 1
            click.Text = ""
            click.AutoButtonColor = false
            click.Parent = card

            local label = createLabel(card, text, 11, Library.Theme.Text, Enum.FontWeight.SemiBold)
            label.Position = UDim2.new(0, 20, 0, 0)
            label.Size = UDim2.new(1, -106, 1, 0)

            local stateText = createLabel(card, "OFF", 7, Library.Theme.Muted, Enum.FontWeight.Bold)
            stateText.Position = UDim2.new(1, -124, 0, 6)
            stateText.Size = UDim2.new(0, 42, 0, 10)
            stateText.TextXAlignment = Enum.TextXAlignment.Right

            local switch = Instance.new("Frame")
            switch.Size = UDim2.new(0, 54, 0, 22)
            switch.Position = UDim2.new(1, -68, 0.5, -11)
            switch.BackgroundColor3 = Library.Theme.Surface3
            switch.BorderSizePixel = 0
            switch.Parent = card
            addCorner(switch, 5)
            local switchStroke = addStroke(switch, Library.Theme.Border, 0.35)

            local track = Instance.new("Frame")
            track.Size = UDim2.new(1, -10, 0, 2)
            track.Position = UDim2.new(0, 5, 0.5, -1)
            track.BackgroundColor3 = Library.Theme.Border
            track.BorderSizePixel = 0
            track.Parent = switch

            local active = Instance.new("Frame")
            active.Name = "ActiveRail"
            active.Size = UDim2.new(0, 0, 1, 0)
            active.BackgroundColor3 = accent
            active.BorderSizePixel = 0
            active.Parent = track

            local block = Instance.new("Frame")
            block.Size = UDim2.new(0, 12, 0, 12)
            block.AnchorPoint = Vector2.new(0.5, 0.5)
            block.Position = UDim2.new(0, 8, 0.5, 0)
            block.BackgroundColor3 = Library.Theme.Text2
            block.BorderSizePixel = 0
            block.Parent = switch
            addCorner(block, 3)
            local blockStroke = addStroke(block, Library.Theme.Border, 0.05)

            local notch = Instance.new("Frame")
            notch.Size = UDim2.new(0, 3, 0, 3)
            notch.AnchorPoint = Vector2.new(0.5, 0.5)
            notch.Position = UDim2.fromScale(0.5, 0.5)
            notch.BackgroundColor3 = Library.Theme.Surface
            notch.BorderSizePixel = 0
            notch.Parent = block

            local function render(instant)
                local duration = instant and 0 or Library.Config.SpringAnimation
                local style = instant and Enum.EasingStyle.Linear or Enum.EasingStyle.Back
                local x = state and 44 or 10
                tween(block, duration, style, Enum.EasingDirection.Out, {Position = UDim2.new(0, x, 0.5, 0), BackgroundColor3 = state and Library.Theme.White or Library.Theme.Text2})
                tween(active, duration, style, Enum.EasingDirection.Out, {Size = UDim2.new(0, state and 39 or 0, 1, 0)})
                tween(switchStroke, duration * 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = state and accent or Library.Theme.Border, Transparency = state and 0.18 or 0.35})
                tween(blockStroke, duration * 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = state and accent or Library.Theme.Border, Transparency = state and 0 or 0.05})
                tween(stateText, duration * 0.7, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextColor3 = state and accent or Library.Theme.Muted})
                stateText.Text = state and "ON" or "OFF"
            end
            render(true)
            local function toggle()
                state = not state
                render(false)
                safeCall(callback, state)
            end
            click.Activated:Connect(toggle)
            return {Get=function() return state end, Set=function(_, value) state=value==true; render(false); safeCall(callback,state) end}
        end

        function API:CreateSlider(text, min, max, default, callback)
            min = tonumber(min) or 0
            max = tonumber(max) or 100
            if min == max then max = min + 1 end
            local value = clampNumber(default == nil and min or default, min, max)
            local card = makeCard(page, 54)
            local label = createLabel(card, text, 10, Library.Theme.Text, Enum.FontWeight.SemiBold)
            label.Position = UDim2.new(0, 20, 0, 3)
            label.Size = UDim2.new(1, -70, 0, 16)
            local valueLabel = createLabel(card, string.format("%g", value), 9, accent, Enum.FontWeight.Bold)
            valueLabel.Position = UDim2.new(1, -58, 0, 3)
            valueLabel.Size = UDim2.new(0, 45, 0, 16)
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right

            local track = Instance.new("Frame")
            track.Position = UDim2.new(0, 20, 0, 30)
            track.Size = UDim2.new(1, -33, 0, 3)
            track.BackgroundColor3 = Library.Theme.Surface3
            track.BorderSizePixel = 0
            track.Parent = card
            local fill = Instance.new("Frame")
            fill.Size = UDim2.new((value-min)/(max-min),0,1,0)
            fill.BackgroundColor3 = accent
            fill.BorderSizePixel = 0
            fill.Parent = track
            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 11, 0, 11)
            knob.AnchorPoint = Vector2.new(0.5,0.5)
            knob.Position = UDim2.new((value-min)/(max-min),0,0.5,0)
            knob.BackgroundColor3 = Library.Theme.White
            knob.BorderSizePixel = 0
            knob.Parent = track
            addCorner(knob, 2)
            knob.Rotation = 45
            addStroke(knob, accent, 0.05)
            for i=0,10 do
                local tick=Instance.new("Frame")
                tick.Size=UDim2.new(0,1,0,3)
                tick.Position=UDim2.new(i/10,0,0.5,-1)
                tick.BackgroundColor3=Library.Theme.Muted
                tick.BackgroundTransparency=(i==0 or i==10) and 0.55 or 0.78
                tick.BorderSizePixel=0
                tick.Parent=track
            end
            local function setValue(v,fire)
                value=clampNumber(v,min,max)
                local pct=(value-min)/(max-min)
                tween(fill,0.10,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,{Size=UDim2.new(pct,0,1,0)})
                spring(knob,0.20,{Position=UDim2.new(pct,0,0.5,0)})
                valueLabel.Text=string.format("%g",value)
                if fire then safeCall(callback,value) end
            end
            local owner={}
            local function update(input)
                if track.AbsoluteSize.X<=0 then return end
                local pct=math.clamp((input.Position.X-track.AbsolutePosition.X)/track.AbsoluteSize.X,0,1)
                setValue(min+(max-min)*pct,true)
            end
            track.InputBegan:Connect(function(input)
                if input.UserInputType==Enum.UserInputType.MouseButton1 or input.UserInputType==Enum.UserInputType.Touch then
                    if beginPointer(owner, input, update, function() end) then update(input) end
                end
            end)
            return {Get=function() return value end,Set=function(_,v) setValue(v,true) end}
        end

        function API:CreateInput(placeholder, callback)
            local card = makeCard(page, 40)
            local box = Instance.new("TextBox")
            box.Size = UDim2.new(1, -32, 1, 0)
            box.Position = UDim2.new(0, 20, 0, 0)
            box.BackgroundTransparency = 1
            box.PlaceholderText = placeholder or "Enter value..."
            box.PlaceholderColor3 = Library.Theme.Muted
            box.Text = ""
            box.TextColor3 = Library.Theme.Text
            box.TextSize = 11
            box.ClearTextOnFocus = false
            box.TextXAlignment = Enum.TextXAlignment.Left
            font(box, Enum.FontWeight.Medium)
            box.Parent = card
            local stroke = addStroke(card, Library.Theme.Border, 0.65)
            box.Focused:Connect(function() tween(stroke, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = accent, Transparency = 0.35}) end)
            box.FocusLost:Connect(function() tween(stroke, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = Library.Theme.Border, Transparency = 0.65}) safeCall(callback, box.Text) end)
            return {GetText = function() return box.Text end, SetText = function(_, value) box.Text = tostring(value) end}
        end

        function API:CreateDropdown(text, options, callback)
            options = options or {}
            local selected, open = nil, false
            local optionHeight, headerHeight = 27, 42
            local card = makeCard(page, headerHeight)
            card.ClipsDescendants = true
            local click = Instance.new("TextButton")
            click.Size = UDim2.new(1,0,0,headerHeight)
            click.BackgroundTransparency=1; click.Text=""; click.AutoButtonColor=false; click.Parent=card
            local label=createLabel(card,text,11,Library.Theme.Text,Enum.FontWeight.SemiBold)
            label.Position=UDim2.new(0,34,0,0); label.Size=UDim2.new(1,-115,0,headerHeight)
            local valueLabel=createLabel(card,"SELECT",7,Library.Theme.Muted,Enum.FontWeight.Bold)
            valueLabel.Position=UDim2.new(1,-88,0,6); valueLabel.Size=UDim2.new(0,52,0,10); valueLabel.TextXAlignment=Enum.TextXAlignment.Right
            local arrow=createLabel(card,"+",15,Library.Theme.Text2,Enum.FontWeight.Bold)
            arrow.Position=UDim2.new(1,-38,0,0); arrow.Size=UDim2.new(0,25,0,headerHeight); arrow.TextXAlignment=Enum.TextXAlignment.Center
            local line=Instance.new("Frame")
            line.Position=UDim2.new(0,34,1,-1); line.Size=UDim2.new(1,-33,0,1); line.BackgroundColor3=Library.Theme.BorderSoft; line.BorderSizePixel=0; line.Parent=card
            local optionsFrame=Instance.new("Frame")
            optionsFrame.Position=UDim2.new(0,34,0,headerHeight+5); optionsFrame.Size=UDim2.new(1,-33,0,0); optionsFrame.BackgroundTransparency=1; optionsFrame.Parent=card
            local list=Instance.new("UIListLayout"); list.Padding=UDim.new(0,2); list.Parent=optionsFrame
            local function bodyHeight() return (#options==0 and 6 or (#options*optionHeight+(#options-1)*2+6)) end
            local function renderOpen(v)
                open=v
                local h=open and headerHeight+bodyHeight() or headerHeight
                spring(card,0.30,{Size=UDim2.new(1,0,0,h)})
                spring(arrow,0.24,{Rotation=open and 45 or 0})
                tween(line,0.16,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,{BackgroundColor3=open and accent or Library.Theme.BorderSoft})
            end
            local function rebuild()
                for _,child in ipairs(optionsFrame:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
                for _,option in ipairs(options) do
                    local b=Instance.new("TextButton")
                    b.Size=UDim2.new(1,0,0,optionHeight); b.BackgroundColor3=Library.Theme.Surface2; b.BackgroundTransparency=0.02; b.BorderSizePixel=0
                    b.Text=tostring(option); b.TextColor3=Library.Theme.Text2; b.TextSize=9; b.TextXAlignment=Enum.TextXAlignment.Left; b.AutoButtonColor=false; font(b,Enum.FontWeight.Medium); b.Parent=optionsFrame
                    addCorner(b,3); addPadding(b,9,8,0,0)
                    b.MouseEnter:Connect(function() tween(b,0.10,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,{BackgroundColor3=Library.Theme.Surface3,TextColor3=Library.Theme.Text}) end)
                    b.MouseLeave:Connect(function() tween(b,0.14,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,{BackgroundColor3=Library.Theme.Surface2,TextColor3=Library.Theme.Text2}) end)
                    b.Activated:Connect(function()
                        selected=option; valueLabel.Text=tostring(option):upper(); valueLabel.TextColor3=accent; renderOpen(false); safeCall(callback,option)
                    end)
                end
            end
            rebuild(); click.Activated:Connect(function() renderOpen(not open) end)
            return {Get=function() return selected end,Refresh=function(_,newOptions) options=newOptions or {}; rebuild(); if open then renderOpen(true) end end,Set=function(_,value) selected=value; valueLabel.Text=tostring(value):upper(); valueLabel.TextColor3=accent; safeCall(callback,value) end}
        end

        function API:CreateKeybind(text, default, callback)
            local current = default
            local listening = false
            local listenConn
            local card = makeCard(page, 44)
            local label = createLabel(card, text, 11, Library.Theme.Text, Enum.FontWeight.SemiBold)
            label.Position = UDim2.new(0, 20, 0, 0)
            label.Size = UDim2.new(1, -112, 1, 0)
            local button = Instance.new("TextButton")
            button.Size = UDim2.new(0, 82, 0, 25)
            button.Position = UDim2.new(1, -95, 0.5, -12)
            button.BackgroundColor3 = Library.Theme.Surface2
            button.Text = keyName(current)
            button.TextColor3 = accent
            button.TextSize = 10
            button.AutoButtonColor = false
            font(button, Enum.FontWeight.Bold)
            button.Parent = card
            addCorner(button, 2)
            local stroke = addStroke(button, Library.Theme.Border, 0.7)
            local function stopListening()
                listening = false
                if listenConn then listenConn:Disconnect(); listenConn = nil end
                button.Text = keyName(current)
                tween(stroke, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = Library.Theme.Border, Transparency = 0.7})
            end
            button.Activated:Connect(function()
                if listening then stopListening(); return end
                listening = true
                button.Text = "PRESS KEY"
                tween(stroke, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = accent, Transparency = 0.25})
                listenConn = UserInputService.InputBegan:Connect(function(input, processed)
                    if processed or not listening then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        current = input.KeyCode
                        stopListening()
                        safeCall(callback, current)
                    elseif input.UserInputType == Enum.UserInputType.MouseButton1 then
                        current = input.UserInputType
                        stopListening()
                        safeCall(callback, current)
                    end
                end)
            end)
            windowMaid:Add(function() if listenConn then listenConn:Disconnect() end end)
            return {Get = function() return current end, Set = function(_, key) current = key button.Text = keyName(key) end}
        end

        function API:CreateColorPicker(text, default, callback)
            local current = default or accent
            local card = makeCard(page, 54)
            local label = createLabel(card, text, 11, Library.Theme.Text, Enum.FontWeight.SemiBold)
            label.Position = UDim2.new(0, 20, 0, 5)
            label.Size = UDim2.new(1, -66, 0, 18)
            local preview = Instance.new("TextButton")
            preview.Size = UDim2.new(0, 42, 0, 23)
            preview.Position = UDim2.new(1, -55, 0, 4)
            preview.BackgroundColor3 = current
            preview.Text = ""
            preview.AutoButtonColor = false
            preview.Parent = card
            addCorner(preview, 3)
            addStroke(preview, Library.Theme.White, 0.45)

            local row = Instance.new("Frame")
            row.Position = UDim2.new(0, 20, 0, 29)
            row.Size = UDim2.new(1, -47, 0, 15)
            row.BackgroundTransparency = 1
            row.Parent = card
            local layout = Instance.new("UIListLayout")
            layout.FillDirection = Enum.FillDirection.Horizontal
            layout.Padding = UDim.new(0, 5)
            layout.Parent = row

            local channels = {
                {"R", "R"}, {"G", "G"}, {"B", "B"}
            }
            local channelButtons = {}
            local function render()
                preview.BackgroundColor3 = current
                local r, g, b = math.floor(current.R * 255), math.floor(current.G * 255), math.floor(current.B * 255)
                local vals = {r, g, b}
                for i, item in ipairs(channelButtons) do item.value.Text = tostring(vals[i]) end
            end
            for i, pair in ipairs(channels) do
                local holder = Instance.new("Frame")
                holder.Size = UDim2.new(1/3, -4, 1, 0)
                holder.BackgroundColor3 = Library.Theme.Surface2
                holder.Parent = row
                addCorner(holder, 3)
                local name = createLabel(holder, pair[1], 8, Library.Theme.Muted, Enum.FontWeight.Bold)
                name.Position = UDim2.new(0, 5, 0, 0)
                name.Size = UDim2.new(0, 12, 1, 0)
                local box = Instance.new("TextBox")
                box.Size = UDim2.new(1, -18, 1, 0)
                box.Position = UDim2.new(0, 17, 0, 0)
                box.BackgroundTransparency = 1
                box.TextColor3 = Library.Theme.Text
                box.TextSize = 8
                box.Text = "0"
                box.ClearTextOnFocus = false
                box.TextXAlignment = Enum.TextXAlignment.Right
                font(box, Enum.FontWeight.SemiBold)
                box.Parent = holder
                channelButtons[i] = {value = box, channel = i}
                box.FocusLost:Connect(function()
                    local n = math.clamp(tonumber(box.Text) or 0, 0, 255)
                    local r, g, b = math.floor(current.R * 255), math.floor(current.G * 255), math.floor(current.B * 255)
                    if i == 1 then r = n elseif i == 2 then g = n else b = n end
                    current = Color3.fromRGB(r, g, b)
                    render()
                    safeCall(callback, current)
                end)
            end
            render()
            return {Get = function() return current end, Set = function(_, color) current = color render() safeCall(callback, current) end}
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
                b.Size = UDim2.new(1/count, -6, 1, 0)
                b.BackgroundColor3 = Library.Theme.Surface
                b.BackgroundTransparency = 0.04
                b.Text = tostring(item.text or ("Button " .. i))
                b.TextColor3 = Library.Theme.Text
                b.TextSize = 10
                b.AutoButtonColor = false
                font(b, Enum.FontWeight.Bold)
                b.Parent = holder
                addCorner(b, 3)
                addStroke(b, Library.Theme.Border, 0.7)
                pressable(b, {BackgroundTransparency = 0.04}, {BackgroundTransparency = 0.00}, {BackgroundTransparency = 0.08})
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
        -- Native scrollbar is hidden. V7 uses a deliberately designed micro-scroll rail
        -- so the scrollbar belongs to the library instead of looking like Roblox default UI.
        page.ScrollBarThickness = 0
        page.ElasticBehavior = Enum.ElasticBehavior.Never
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.Visible = false
        page.Parent = Body

        local scrollRail = Instance.new("Frame")
        scrollRail.Name = "ScrollRail"
        scrollRail.AnchorPoint = Vector2.new(1, 0)
        scrollRail.Position = UDim2.new(1, -5, 0, 10)
        scrollRail.Size = UDim2.new(0, 2, 1, -20)
        scrollRail.BackgroundColor3 = Library.Theme.Border
        scrollRail.BackgroundTransparency = 0.35
        scrollRail.BorderSizePixel = 0
        scrollRail.ZIndex = 30
        scrollRail.Visible = false
        scrollRail.Parent = Body
        addCorner(scrollRail, 2)

        local scrollThumb = Instance.new("Frame")
        scrollThumb.Name = "ScrollThumb"
        scrollThumb.Size = UDim2.new(1, 0, 0, 34)
        scrollThumb.Position = UDim2.new(0, 0, 0, 0)
        scrollThumb.BackgroundColor3 = accent
        scrollThumb.BackgroundTransparency = 0
        scrollThumb.BorderSizePixel = 0
        scrollThumb.ZIndex = 31
        scrollThumb.Parent = scrollRail
        addCorner(scrollThumb, 2)

        local function updateScrollIndicator()
            if not page.Parent then return end
            local viewport = page.AbsoluteWindowSize.Y
            local content = page.AbsoluteCanvasSize.Y
            local track = math.max(1, scrollRail.AbsoluteSize.Y)
            if content <= viewport + 2 then
                scrollRail.Visible = false
                return
            end
            scrollRail.Visible = page.Visible
            local ratio = math.clamp(viewport / content, 0.12, 1)
            local thumbHeight = math.max(22, track * ratio)
            local maxTravel = math.max(0, track - thumbHeight)
            local maxCanvas = math.max(1, content - viewport)
            local pct = math.clamp(page.CanvasPosition.Y / maxCanvas, 0, 1)
            scrollThumb.Size = UDim2.new(1, 0, 0, thumbHeight)
            scrollThumb.Position = UDim2.new(0, 0, 0, maxTravel * pct)
        end

        page:GetPropertyChangedSignal("CanvasPosition"):Connect(updateScrollIndicator)
        page:GetPropertyChangedSignal("AbsoluteCanvasSize"):Connect(updateScrollIndicator)
        page:GetPropertyChangedSignal("AbsoluteWindowSize"):Connect(updateScrollIndicator)
        scrollRail:GetPropertyChangedSignal("AbsoluteSize"):Connect(updateScrollIndicator)

        addPadding(page, 10, 12, 11, 12)
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 5)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = page
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 16)
        end)

        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 39)
        button.BackgroundColor3 = Library.Theme.Surface
        button.BackgroundTransparency = 1
        button.Text = ""
        button.AutoButtonColor = false
        button.Parent = TabsScroll
        addCorner(button, 2)
        local marker = Instance.new("Frame")
        marker.Size = UDim2.new(0, 2, 0, 20)
        marker.Position = UDim2.new(0, 0, 0.5, -10)
        marker.BackgroundColor3 = accent
        marker.BackgroundTransparency = 1
        marker.BorderSizePixel = 0
        marker.Parent = button
        addCorner(marker, 1)
        local tabIndex = createLabel(button, string.format("%02d", #TabButtons + 1), 7, Library.Theme.Muted, Enum.FontWeight.Bold)
        tabIndex.Position = UDim2.new(0, 7, 0, 0)
        tabIndex.Size = UDim2.new(0, 18, 1, 0)
        local label = createLabel(button, tabName, 10, Library.Theme.Text2, Enum.FontWeight.SemiBold)
        label.Position = UDim2.new(0, 29, 0, 0)
        label.Size = UDim2.new(1, -35, 1, 0)

        local record = {
            name = tabName,
            page = page,
            button = button,
            marker = marker,
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

    -- Public tab API
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

    -- Header buttons are created after content exists.
    minimizeButton = headerButton("–", -66, function()
        if transitioning or closing then return end
        isOpen = false
        transitioning = true
        Content.Visible = false
        tween(Dimmer, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 1})
        spring(MainCorner, 0.30, {CornerRadius = UDim.new(0, 7)}, Enum.EasingDirection.In)
        local t = spring(Main, 0.40, {Size = UDim2.new(0, floatingSize(), 0, floatingSize()), Position = floatingPosition}, Enum.EasingDirection.In)
        if t then t.Completed:Connect(function() transitioning = false Bubble.Visible = true end) end
    end)
    closeButton = headerButton("×", -34, function()
        if closing then return end
        closing = true
        transitioning = true
        Dimmer.BackgroundTransparency = 1
        local center = Main.AbsolutePosition + Main.AbsoluteSize / 2
        local t = tween(Main, 0.24, Enum.EasingStyle.Quad, Enum.EasingDirection.In, {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0, center.X, 0, center.Y),
            BackgroundTransparency = 1,
        })
        tween(MainStroke, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In, {Transparency = 1})
        if t then t.Completed:Connect(function() windowMaid:Destroy() end) else windowMaid:Destroy() end
    end)

    local function centeredWindowPosition(size)
        local camera = workspace.CurrentCamera
        local vp = camera and camera.ViewportSize or Vector2.new(800, 600)
        local w = size.X.Offset > 0 and size.X.Offset or vp.X * size.X.Scale
        local h = size.Y.Offset > 0 and size.Y.Offset or vp.Y * size.Y.Scale
        return UDim2.fromOffset(math.max(10, (vp.X - w) * 0.5), math.max(10, (vp.Y - h) * 0.5))
    end

    local function openWindow()
        if closing or transitioning or isOpen then return end
        isOpen = true
        transitioning = true
        floatingPosition = Main.Position
        Bubble.Visible = false
        Main.BackgroundTransparency = 0
        MainStroke.Transparency = 0.5
        local size = windowSize()
        tween(Dimmer, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = Library.Theme.DimTransparency})
        spring(MainCorner, 0.30, {CornerRadius = UDim.new(0, 8)})
        local t = spring(Main, 0.46, {Size = size, Position = centeredWindowPosition(size)})
        if t then t.Completed:Connect(function() Content.Visible = true transitioning = false end) end
    end

    -- Floating button: tap opens; a real drag moves it. Movement is clamped continuously.
    local dragOwner = {}
    local clickStart
    local dragStart
    Main.InputBegan:Connect(function(input)
        if isOpen or closing or transitioning then return end
        if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then return end
        clickStart = input.Position
        dragStart = Main.Position
        if not beginPointer(dragOwner, input, function(moveInput)
            local delta = moveInput.Position - clickStart
            local camera = workspace.CurrentCamera
            local vp = camera and camera.ViewportSize or Vector2.new(800, 600)
            local sx, sy = Main.AbsoluteSize.X, Main.AbsoluteSize.Y
            local x = math.clamp(dragStart.X.Offset + delta.X, 10, math.max(10, vp.X - sx - 10))
            local y = math.clamp(dragStart.Y.Offset + delta.Y, 10, math.max(10, vp.Y - sy - 10))
            Main.Position = UDim2.fromOffset(x, y)
            floatingPosition = Main.Position
        end, function(endInput)
            local moved = (endInput.Position - clickStart).Magnitude
            if moved < 8 then
                openWindow()
            else
                local camera = workspace.CurrentCamera
                local vp = camera and camera.ViewportSize or Vector2.new(800, 600)
                local p = Main.AbsolutePosition
                local s = Main.AbsoluteSize
                local x = math.clamp(p.X, 10, vp.X - s.X - 10)
                local y = math.clamp(p.Y, 10, vp.Y - s.Y - 10)
                floatingPosition = UDim2.fromOffset(x, y)
                snap(Main, {Position = floatingPosition})
            end
            clickStart, dragStart = nil, nil
        end) then
            clickStart, dragStart = nil, nil
        end
    end)

    -- Dedicated drag zone: header buttons and title controls never steal drag ownership.
    local DragHandle = Instance.new("TextButton")
    DragHandle.Name = "DragHandle"
    DragHandle.BackgroundTransparency = 1
    DragHandle.BorderSizePixel = 0
    DragHandle.Text = ""
    DragHandle.AutoButtonColor = false
    DragHandle.Position = UDim2.new(0, 0, 0, 0)
    DragHandle.Size = UDim2.new(1, -108, 1, 0)
    DragHandle.Parent = Header
    local headerDragOwner = {}
    DragHandle.InputBegan:Connect(function(input)
        if not isOpen or closing or transitioning then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            local startInput = input.Position
            local startPos = Main.Position
            beginPointer(headerDragOwner, input, function(moveInput)
                local delta = moveInput.Position - startInput
                local camera = workspace.CurrentCamera
                local vp = camera and camera.ViewportSize or Vector2.new(800, 600)
                local sx, sy = Main.AbsoluteSize.X, Main.AbsoluteSize.Y
                local x = math.clamp(startPos.X.Offset + delta.X, 8, math.max(8, vp.X - sx - 8))
                local y = math.clamp(startPos.Y.Offset + delta.Y, 8, math.max(8, vp.Y - sy - 8))
                Main.Position = UDim2.fromOffset(x, y)
                floatingPosition = Main.Position
            end, function() end)
        end
    end)

    -- FPS is sampled only while the window exists, and connection is cleaned with the window.
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

    -- Initial demo state: minimized floating control. Public methods expose deterministic state.
    local Window = {}
    function Window:SetVisible(value)
        if value then openWindow() elseif isOpen then
            isOpen = false
            transitioning = true
            Content.Visible = false
            tween(Dimmer, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 1})
            local t = spring(Main, 0.34, {Size = UDim2.new(0, floatingSize(), 0, floatingSize()), Position = floatingPosition}, Enum.EasingDirection.In)
            if t then t.Completed:Connect(function() transitioning = false Bubble.Visible = true end) end
        end
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
        MainStroke.Color = Library.Theme.Border
        dot.BackgroundColor3 = color
        markB.BackgroundColor3 = color
        statusLabel.TextColor3 = color
        for _, item in ipairs(TabButtons) do
            if item.marker then item.marker.BackgroundColor3 = color end
            if item.tabIndex then
                item.tabIndex.TextColor3 = item == CurrentPage and color or Library.Theme.Muted
            end
        end
        for _, obj in ipairs(ScreenGui:GetDescendants()) do
            if obj.Name == "AccentRail" or obj.Name == "AccentMark" or obj.Name == "CardEdge" or obj.Name == "ActiveRail" or obj.Name == "ScrollThumb" then
                obj.BackgroundColor3 = color
            elseif obj.Name == "Indicator" then
                local stroke = obj:FindFirstChildOfClass("UIStroke")
                if stroke then stroke.Color = color end
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
    Version = "7.x",
    PreservesV4API = true,
    MobileFirst = true,
}

return Library
