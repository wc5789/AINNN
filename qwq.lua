--[[
    QWQ UI Library V2
    Commercial-style mobile-first Roblox UI framework
    Focus: consistent design system, deterministic cleanup, touch-safe input,
    responsive layout, extensible component API.
]]

local Library = {}

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

Library.Version = "3.0.0"
Library.Theme = {
    Accent = Color3.fromRGB(224, 116, 148),
    AccentSoft = Color3.fromRGB(247, 220, 229),
    AccentDeep = Color3.fromRGB(188, 82, 116),
    Background = Color3.fromRGB(247, 245, 248),
    Surface = Color3.fromRGB(252, 250, 253),
    Surface2 = Color3.fromRGB(244, 241, 246),
    Border = Color3.fromRGB(226, 218, 226),
    Text = Color3.fromRGB(54, 48, 57),
    Text2 = Color3.fromRGB(119, 109, 121),
    Muted = Color3.fromRGB(164, 151, 165),
    White = Color3.fromRGB(255, 255, 255),
    Success = Color3.fromRGB(72, 174, 119),
    Warning = Color3.fromRGB(219, 153, 67),
    Error = Color3.fromRGB(213, 83, 105),
    Dim = Color3.fromRGB(18, 14, 21),
    DimTransparency = 0.48,
}

Library.FontFamily = "rbxasset://fonts/families/BuilderSans.json"
Library.Config = {
    MobileBreakpoint = 560,
    DesktopWidth = 540,
    DesktopHeight = 370,
    MobileWidth = 0.92,
    MobileHeight = 0.82,
    Animation = 0.22,
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

-- One global pointer, but ownership is explicit. A slider cannot steal a window drag.
local Pointer = { owner = nil, move = nil, ended = nil }
local pointerMoveConn = UserInputService.InputChanged:Connect(function(input)
    if Pointer.owner and Pointer.move and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
        Pointer.move(input)
    end
end)
local pointerEndConn = UserInputService.InputEnded:Connect(function(input)
    if Pointer.owner and (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch) then
        local ended = Pointer.ended
        Pointer.owner, Pointer.move, Pointer.ended = nil, nil, nil
        if ended then pcall(ended, input) end
    end
end)

local function beginPointer(owner, move, ended)
    if Pointer.owner then return false end
    Pointer.owner, Pointer.move, Pointer.ended = owner, move, ended
    return true
end

local function endPointer(owner)
    if Pointer.owner == owner then
        Pointer.owner, Pointer.move, Pointer.ended = nil, nil, nil
    end
end

-- ================================================================
-- Surface system
-- ================================================================
local function surface(object, radius, opts)
    opts = opts or {}
    object.BackgroundColor3 = opts.color or Library.Theme.Surface
    object.BackgroundTransparency = opts.transparency == nil and 0.18 or opts.transparency
    object.BorderSizePixel = 0
    addCorner(object, radius or 12)
    if opts.stroke ~= false then
        addStroke(object, opts.strokeColor or Library.Theme.Border, opts.strokeTransparency == nil and 0.55 or opts.strokeTransparency, opts.strokeThickness or 1)
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
    layout.Padding = UDim.new(0, 7)
    layout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    layout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = NotificationList
    return NotificationList
end

local function makeNotification(title, message, duration, kind)
    local list = ensureNotifications()
    local colors = {
        info = Library.Theme.Accent,
        success = Library.Theme.Success,
        warn = Library.Theme.Warning,
        error = Library.Theme.Error,
    }
    local accent = colors[kind] or colors.info

    local toast = Instance.new("Frame")
    toast.Size = UDim2.new(1, 0, 0, 64)
    toast.BackgroundColor3 = Library.Theme.Surface
    toast.BackgroundTransparency = 1
    toast.BorderSizePixel = 0
    toast.ClipsDescendants = true
    toast.LayoutOrder = os.clock() * 1000
    toast.Parent = list
    addCorner(toast, 12)
    local stroke = addStroke(toast, accent, 0.72)

    local bar = Instance.new("Frame")
    bar.Position = UDim2.new(0, 0, 0, 0)
    bar.Size = UDim2.new(0, 3, 1, 0)
    bar.BackgroundColor3 = accent
    bar.BorderSizePixel = 0
    bar.Parent = toast
    addCorner(bar, 3)

    local titleLabel = createLabel(toast, tostring(title):upper(), 11, accent, Enum.FontWeight.Bold)
    titleLabel.Position = UDim2.new(0, 15, 0, 8)
    titleLabel.Size = UDim2.new(1, -24, 0, 16)
    titleLabel.TextTransparency = 1

    local descLabel = createLabel(toast, tostring(message), 10, Library.Theme.Text2, Enum.FontWeight.Medium)
    descLabel.Position = UDim2.new(0, 15, 0, 27)
    descLabel.Size = UDim2.new(1, -24, 0, 28)
    descLabel.TextWrapped = true
    descLabel.TextYAlignment = Enum.TextYAlignment.Top
    descLabel.TextTransparency = 1

    local track = Instance.new("Frame")
    track.Position = UDim2.new(0, 15, 1, -5)
    track.Size = UDim2.new(1, -24, 0, 2)
    track.BackgroundColor3 = Library.Theme.Surface2
    track.BorderSizePixel = 0
    track.Parent = toast
    addCorner(track, 2)
    local fill = Instance.new("Frame")
    fill.Size = UDim2.fromScale(1, 1)
    fill.BackgroundColor3 = accent
    fill.BorderSizePixel = 0
    fill.Parent = track
    addCorner(fill, 2)

    tween(toast, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 0.08})
    tween(titleLabel, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextTransparency = 0})
    tween(descLabel, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {TextTransparency = 0})
    tween(fill, math.max(0.1, duration or 3), Enum.EasingStyle.Linear, Enum.EasingDirection.Out, {Size = UDim2.new(0, 0, 1, 0)})

    task.delay(duration or 3, function()
        if not toast.Parent then return end
        tween(stroke, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In, {Transparency = 1})
        tween(titleLabel, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In, {TextTransparency = 1})
        tween(descLabel, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In, {TextTransparency = 1})
        local out = tween(toast, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.In, {BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0)})
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
    Main.AnchorPoint = Vector2.new(0.5, 0.5)
    Main.Position = UDim2.fromScale(0.5, 0.5)
    Main.Size = UDim2.new(0, 56, 0, 56)
    Main.BackgroundColor3 = Library.Theme.Surface
    Main.BackgroundTransparency = 0.05
    Main.BorderSizePixel = 0
    Main.ClipsDescendants = true
    Main.ZIndex = 10
    Main.Parent = ScreenGui
    local MainCorner = addCorner(Main, 28)
    local MainStroke = addStroke(Main, accent, 0.5)

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
    local BubbleGlyph = createLabel(Bubble, "≡", 22, accent, Enum.FontWeight.Bold)
    BubbleGlyph.Size = UDim2.new(0, 30, 0, 30)
    BubbleGlyph.TextXAlignment = Enum.TextXAlignment.Center

    local Content = Instance.new("Frame")
    Content.Size = UDim2.fromScale(1, 1)
    Content.BackgroundTransparency = 1
    Content.Visible = false
    Content.Parent = Main

    local isOpen = false
    local closing = false
    local transitioning = false
    local floatingPosition = UDim2.fromScale(0.92, 0.78)

    local function isMobile()
        local camera = workspace.CurrentCamera
        return camera and camera.ViewportSize.X < Library.Config.MobileBreakpoint
    end

    local function updateResponsive()
        if not Main.Parent then return end
        local mobile = isMobile()
        if not isOpen then
            Main.Size = UDim2.new(0, mobile and 52 or 56, 0, mobile and 52 or 56)
            return
        end
        local camera = workspace.CurrentCamera
        local vp = camera and camera.ViewportSize or Vector2.new(800, 600)
        local compact = vp.X < Library.Config.MobileBreakpoint
        Sidebar.Size = UDim2.new(0, compact and 92 or 126, 1, -50)
        Body.Position = UDim2.new(0, compact and 92 or 126, 0, 50)
        Body.Size = UDim2.new(1, -(compact and 92 or 126), 1, -50)
        TabsScroll.Size = UDim2.new(1, -16, 1, -70)
    end
    local cameraConn = workspace:GetPropertyChangedSignal("CurrentCamera"):Connect(function()
        task.defer(updateResponsive)
    end)
    windowMaid:Add(cameraConn)
    task.defer(function()
        local camera = workspace.CurrentCamera
        if camera then
            windowMaid:Add(camera:GetPropertyChangedSignal("ViewportSize"):Connect(updateResponsive))
        end
    end)
    updateResponsive()

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
    Header.Size = UDim2.new(1, 0, 0, 50)
    Header.BackgroundColor3 = Library.Theme.Surface
    Header.BackgroundTransparency = 0.02
    Header.BorderSizePixel = 0
    Header.Parent = Content
    local headerLine = Instance.new("Frame")
    headerLine.Position = UDim2.new(0, 16, 1, -1)
    headerLine.Size = UDim2.new(1, -32, 0, 1)
    headerLine.BackgroundColor3 = Library.Theme.Border
    headerLine.BorderSizePixel = 0
    headerLine.Parent = Header

    local Brand = Instance.new("Frame")
    Brand.Size = UDim2.new(1, -100, 1, 0)
    Brand.BackgroundTransparency = 1
    Brand.Parent = Header
    local dot = Instance.new("Frame")
    dot.Size = UDim2.new(0, 7, 0, 7)
    dot.Position = UDim2.new(0, 16, 0.5, -3)
    dot.BackgroundColor3 = accent
    dot.BorderSizePixel = 0
    dot.Parent = Brand
    addCorner(dot, 4)
    local pulse = TweenService:Create(dot, TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), {BackgroundTransparency = 0.5})
    pulse:Play()
    windowMaid:Add(function() pulse:Cancel() end)

    local title = createLabel(Brand, titleText or "QWQ", 13, Library.Theme.Text, Enum.FontWeight.Bold)
    title.Position = UDim2.new(0, 31, 0, 0)
    title.Size = UDim2.new(1, -38, 1, 0)

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
        addCorner(b, 9)
        pressable(b, {BackgroundTransparency = 0.1}, {BackgroundTransparency = 0}, {BackgroundTransparency = 0})
        b.Activated:Connect(callback)
        return b
    end

    local tabsButton
    local minimizeButton
    local closeButton

    local Sidebar = Instance.new("Frame")
    Sidebar.Name = "Sidebar"
    Sidebar.Position = UDim2.new(0, 0, 0, 50)
    Sidebar.Size = UDim2.new(0, 126, 1, -50)
    Sidebar.BackgroundTransparency = 1
    Sidebar.Parent = Content

    local TabsScroll = Instance.new("ScrollingFrame")
    TabsScroll.Position = UDim2.new(0, 10, 0, 12)
    TabsScroll.Size = UDim2.new(1, -20, 1, -70)
    TabsScroll.BackgroundTransparency = 1
    TabsScroll.BorderSizePixel = 0
    TabsScroll.ScrollBarThickness = 0
    TabsScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabsScroll.Parent = Sidebar
    local tabsLayout = Instance.new("UIListLayout")
    tabsLayout.Padding = UDim.new(0, 5)
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
    addCorner(Status, 10)
    addStroke(Status, Library.Theme.Border, 0.75)
    local statusLabel = createLabel(Status, "READY", 9, accent, Enum.FontWeight.Bold)
    statusLabel.Position = UDim2.new(0, 11, 0, 4)
    statusLabel.Size = UDim2.new(1, -22, 0, 14)
    local fpsLabel = createLabel(Status, "-- FPS", 9, Library.Theme.Muted, Enum.FontWeight.Medium)
    fpsLabel.Position = UDim2.new(0, 11, 0, 20)
    fpsLabel.Size = UDim2.new(1, -22, 0, 14)

    local Body = Instance.new("Frame")
    Body.Name = "Body"
    Body.Position = UDim2.new(0, 126, 0, 50)
    Body.Size = UDim2.new(1, -126, 1, -50)
    Body.BackgroundTransparency = 1
    Body.Parent = Content

    local Pages = {}
    local TabButtons = {}
    local CurrentPage

    local function selectTab(record)
        for _, item in ipairs(TabButtons) do
            local active = item == record
            tween(item.button, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
                BackgroundTransparency = active and 0.08 or 1,
            })
            tween(item.label, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
                TextColor3 = active and accent or Library.Theme.Text2,
            })
            tween(item.marker, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
                BackgroundTransparency = active and 0 or 1,
            })
            item.page.Visible = active
        end
        CurrentPage = record
    end

    local function makeCard(parent, height)
        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, height)
        surface(card, 11, {transparency = 0.22})
        card.Parent = parent
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
            mark.Size = UDim2.new(0, 3, 0, 12)
            mark.Position = UDim2.new(0, 0, 0.5, -6)
            mark.BackgroundColor3 = accent
            mark.BorderSizePixel = 0
            mark.Parent = holder
            addCorner(mark, 2)
            local l = createLabel(holder, tostring(text):upper(), 9, Library.Theme.Text2, Enum.FontWeight.Bold)
            l.Position = UDim2.new(0, 10, 0, 0)
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
            line.Position = UDim2.fromScale(0.5, 0.5)
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
            local b = Instance.new("TextButton")
            b.Size = UDim2.new(1, 0, 0, 38)
            b.BackgroundColor3 = Library.Theme.Surface
            b.BackgroundTransparency = 0.2
            b.Text = text
            b.TextColor3 = Library.Theme.Text
            b.TextSize = 11
            font(b, Enum.FontWeight.Bold)
            b.Parent = page
            addCorner(b, 10)
            local stroke = addStroke(b, Library.Theme.Border, 0.65)
            pressable(b,
                {BackgroundTransparency = 0.2},
                {BackgroundTransparency = 0.06},
                {BackgroundTransparency = 0.12}
            )
            b.MouseEnter:Connect(function() tween(stroke, 0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = accent, Transparency = 0.55}) end)
            b.MouseLeave:Connect(function() tween(stroke, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = Library.Theme.Border, Transparency = 0.65}) end)
            b.Activated:Connect(function() safeCall(callback) end)
            return b
        end

        function API:CreateToggle(text, default, callback)
            local state = default == true
            local card = makeCard(page, 42)
            local click = Instance.new("TextButton")
            click.Size = UDim2.fromScale(1, 1)
            click.BackgroundTransparency = 1
            click.Text = ""
            click.Parent = card
            local label = createLabel(card, text, 11, Library.Theme.Text, Enum.FontWeight.SemiBold)
            label.Position = UDim2.new(0, 13, 0, 0)
            label.Size = UDim2.new(1, -78, 1, 0)

            local track = Instance.new("Frame")
            track.Size = UDim2.new(0, 42, 0, 24)
            track.Position = UDim2.new(1, -55, 0.5, -12)
            track.BackgroundColor3 = state and accent or Library.Theme.Surface2
            track.Parent = card
            addCorner(track, 12)
            local trackStroke = addStroke(track, state and accent or Library.Theme.Border, state and 0.45 or 0.7)
            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 18, 0, 18)
            knob.BackgroundColor3 = Library.Theme.White
            knob.Parent = track
            addCorner(knob, 9)

            local function render(instant)
                local targetPos = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
                local dur = instant and 0 or 0.18
                tween(track, dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundColor3 = state and accent or Library.Theme.Surface2})
                tween(trackStroke, dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Color = state and accent or Library.Theme.Border, Transparency = state and 0.45 or 0.7})
                tween(knob, dur, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Position = targetPos})
            end
            render(true)
            click.Activated:Connect(function()
                state = not state
                render(false)
                safeCall(callback, state)
            end)
            return {
                Get = function() return state end,
                Set = function(_, value) state = value == true render(false) safeCall(callback, state) end,
            }
        end

        function API:CreateSlider(text, min, max, default, callback)
            min = tonumber(min) or 0
            max = tonumber(max) or 100
            if min == max then max = min + 1 end
            local value = clampNumber(default == nil and min or default, min, max)
            local card = makeCard(page, 46)
            local label = createLabel(card, text, 10, Library.Theme.Text, Enum.FontWeight.SemiBold)
            label.Position = UDim2.new(0, 13, 0, 4)
            label.Size = UDim2.new(1, -72, 0, 17)
            local valueLabel = createLabel(card, tostring(round(value, 0)), 10, accent, Enum.FontWeight.Bold)
            valueLabel.Position = UDim2.new(1, -58, 0, 4)
            valueLabel.Size = UDim2.new(0, 45, 0, 17)
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right
            local track = Instance.new("Frame")
            track.Position = UDim2.new(0, 13, 0, 29)
            track.Size = UDim2.new(1, -26, 0, 5)
            track.BackgroundColor3 = Library.Theme.Surface2
            track.BorderSizePixel = 0
            track.Parent = card
            addCorner(track, 3)
            local fill = Instance.new("Frame")
            fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            fill.BackgroundColor3 = accent
            fill.BorderSizePixel = 0
            fill.Parent = track
            addCorner(fill, 3)
            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, 12, 0, 12)
            knob.AnchorPoint = Vector2.new(0.5, 0.5)
            knob.Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0)
            knob.BackgroundColor3 = Library.Theme.White
            knob.Parent = track
            addCorner(knob, 6)
            addStroke(knob, accent, 0.35)

            local function setValue(v, fire)
                value = clampNumber(v, min, max)
                local pct = (value - min) / (max - min)
                fill.Size = UDim2.new(pct, 0, 1, 0)
                knob.Position = UDim2.new(pct, 0, 0.5, 0)
                valueLabel.Text = tostring(round(value, 0))
                if fire then safeCall(callback, value) end
            end
            local owner = {}
            local function update(input)
                if track.AbsoluteSize.X <= 0 then return end
                local pct = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                setValue(min + (max - min) * pct, true)
            end
            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    if beginPointer(owner, update, function() end) then update(input) end
                end
            end)
            return {Get = function() return value end, Set = function(_, v) setValue(v, true) end}
        end

        function API:CreateInput(placeholder, callback)
            local card = makeCard(page, 38)
            local box = Instance.new("TextBox")
            box.Size = UDim2.new(1, -22, 1, 0)
            box.Position = UDim2.new(0, 11, 0, 0)
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
            local selected = nil
            local open = false
            local optionHeight = 29
            local headerHeight = 40
            local card = makeCard(page, headerHeight)
            card.ClipsDescendants = true
            local click = Instance.new("TextButton")
            click.Size = UDim2.new(1, 0, 0, headerHeight)
            click.BackgroundTransparency = 1
            click.Text = ""
            click.Parent = card
            local label = createLabel(card, text, 11, Library.Theme.Text, Enum.FontWeight.SemiBold)
            label.Position = UDim2.new(0, 13, 0, 0)
            label.Size = UDim2.new(1, -65, 0, headerHeight)
            local arrow = createLabel(card, "⌄", 15, Library.Theme.Text2, Enum.FontWeight.Bold)
            arrow.Position = UDim2.new(1, -42, 0, 0)
            arrow.Size = UDim2.new(0, 28, 0, headerHeight)
            arrow.TextXAlignment = Enum.TextXAlignment.Center

            local optionsFrame = Instance.new("Frame")
            optionsFrame.Position = UDim2.new(0, 9, 0, headerHeight + 2)
            optionsFrame.Size = UDim2.new(1, -18, 0, 0)
            optionsFrame.BackgroundTransparency = 1
            optionsFrame.Parent = card
            local list = Instance.new("UIListLayout")
            list.Padding = UDim.new(0, 4)
            list.Parent = optionsFrame

            local function bodyHeight()
                if #options == 0 then return 6 end
                return (#options * optionHeight) + ((#options - 1) * 4) + 7
            end
            local function rebuild()
                for _, child in ipairs(optionsFrame:GetChildren()) do if child:IsA("TextButton") then child:Destroy() end end
                for _, option in ipairs(options) do
                    local b = Instance.new("TextButton")
                    b.Size = UDim2.new(1, 0, 0, optionHeight)
                    b.BackgroundColor3 = Library.Theme.Surface2
                    b.BackgroundTransparency = 0.1
                    b.Text = tostring(option)
                    b.TextColor3 = Library.Theme.Text2
                    b.TextSize = 10
                    b.TextXAlignment = Enum.TextXAlignment.Left
                    b.AutoButtonColor = false
                    font(b, Enum.FontWeight.Medium)
                    b.Parent = optionsFrame
                    addCorner(b, 8)
                    addPadding(b, 10, 8, 0, 0)
                    b.Activated:Connect(function()
                        selected = option
                        label.Text = tostring(text) .. "  ·  " .. tostring(option)
                        open = false
                        tween(card, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Size = UDim2.new(1, 0, 0, headerHeight)})
                        tween(arrow, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Rotation = 0})
                        safeCall(callback, option)
                    end)
                end
            end
            rebuild()
            click.Activated:Connect(function()
                open = not open
                local h = open and (headerHeight + bodyHeight()) or headerHeight
                tween(card, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Size = UDim2.new(1, 0, 0, h)})
                tween(arrow, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Rotation = open and 180 or 0})
            end)
            return {
                Get = function() return selected end,
                Refresh = function(_, newOptions)
                    options = newOptions or {}
                    rebuild()
                    if open then tween(card, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Size = UDim2.new(1, 0, 0, headerHeight + bodyHeight())}) end
                end,
                Set = function(_, value)
                    selected = value
                    label.Text = tostring(text) .. "  ·  " .. tostring(value)
                    safeCall(callback, value)
                end,
            }
        end

        function API:CreateKeybind(text, default, callback)
            local current = default
            local listening = false
            local listenConn
            local card = makeCard(page, 42)
            local label = createLabel(card, text, 11, Library.Theme.Text, Enum.FontWeight.SemiBold)
            label.Position = UDim2.new(0, 13, 0, 0)
            label.Size = UDim2.new(1, -112, 1, 0)
            local button = Instance.new("TextButton")
            button.Size = UDim2.new(0, 88, 0, 27)
            button.Position = UDim2.new(1, -101, 0.5, -13)
            button.BackgroundColor3 = Library.Theme.Surface2
            button.Text = keyName(current)
            button.TextColor3 = accent
            button.TextSize = 10
            button.AutoButtonColor = false
            font(button, Enum.FontWeight.Bold)
            button.Parent = card
            addCorner(button, 8)
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
            local card = makeCard(page, 50)
            local label = createLabel(card, text, 11, Library.Theme.Text, Enum.FontWeight.SemiBold)
            label.Position = UDim2.new(0, 13, 0, 5)
            label.Size = UDim2.new(1, -76, 0, 18)
            local preview = Instance.new("TextButton")
            preview.Size = UDim2.new(0, 44, 0, 24)
            preview.Position = UDim2.new(1, -57, 0, 4)
            preview.BackgroundColor3 = current
            preview.Text = ""
            preview.AutoButtonColor = false
            preview.Parent = card
            addCorner(preview, 8)
            addStroke(preview, Library.Theme.White, 0.45)

            local row = Instance.new("Frame")
            row.Position = UDim2.new(0, 12, 0, 28)
            row.Size = UDim2.new(1, -24, 0, 14)
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
                addCorner(holder, 7)
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
            holder.Size = UDim2.new(1, 0, 0, 36)
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
                b.BackgroundTransparency = 0.18
                b.Text = tostring(item.text or ("Button " .. i))
                b.TextColor3 = Library.Theme.Text
                b.TextSize = 10
                b.AutoButtonColor = false
                font(b, Enum.FontWeight.Bold)
                b.Parent = holder
                addCorner(b, 9)
                addStroke(b, Library.Theme.Border, 0.7)
                pressable(b, {BackgroundTransparency = 0.18}, {BackgroundTransparency = 0.05}, {BackgroundTransparency = 0.1})
                b.Activated:Connect(function() safeCall(item.callback) end)
            end
            return holder
        end

        return API
    end

    local function createTab(tabName)
        tabName = tostring(tabName or "Tab")
        if tabName == "" then tabName = "Tab" end
        for _, existing in ipairs(TabButtons) do
            if existing.name == tabName then
                tabName = tabName .. " " .. tostring(#TabButtons + 1)
                break
            end
        end
        local page = Instance.new("ScrollingFrame")
        page.Name = tabName .. "Page"
        page.Size = UDim2.fromScale(1, 1)
        page.BackgroundTransparency = 1
        page.BorderSizePixel = 0
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = accent
        page.ScrollBarImageTransparency = 0.55
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.Visible = false
        page.Parent = Body
        addPadding(page, 7, 10, 8, 10)
        local layout = Instance.new("UIListLayout")
        layout.Padding = UDim.new(0, 7)
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Parent = page
        layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            page.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 16)
        end)

        local button = Instance.new("TextButton")
        button.Size = UDim2.new(1, 0, 0, 34)
        button.BackgroundColor3 = Library.Theme.Surface
        button.BackgroundTransparency = 1
        button.Text = ""
        button.AutoButtonColor = false
        button.Parent = TabsScroll
        addCorner(button, 9)
        local marker = Instance.new("Frame")
        marker.Size = UDim2.new(0, 3, 0, 15)
        marker.Position = UDim2.new(0, 0, 0.5, -7.5)
        marker.BackgroundColor3 = accent
        marker.BackgroundTransparency = 1
        marker.BorderSizePixel = 0
        marker.Parent = button
        addCorner(marker, 2)
        local label = createLabel(button, tabName, 10, Library.Theme.Text2, Enum.FontWeight.SemiBold)
        label.Position = UDim2.new(0, 12, 0, 0)
        label.Size = UDim2.new(1, -12, 1, 0)

        local record = {name = tabName, page = page, button = button, marker = marker, label = label}
        table.insert(TabButtons, record)
        button.Activated:Connect(function() selectTab(record) end)
        if not CurrentPage then selectTab(record) end
        return elementAPI(page)
    end

    -- Header buttons are created after content exists.
    minimizeButton = headerButton("–", -66, function()
        if transitioning or closing then return end
        isOpen = false
        transitioning = true
        Content.Visible = false
        tween(Dimmer, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = 1})
        tween(MainCorner, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {CornerRadius = UDim.new(0, 28)})
        local t = tween(Main, 0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In, {Size = UDim2.new(0, 56, 0, 56), Position = floatingPosition})
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

    local function openWindow()
        if closing or transitioning or isOpen then return end
        isOpen = true
        transitioning = true
        floatingPosition = Main.Position
        Bubble.Visible = false
        Main.BackgroundTransparency = 0.05
        MainStroke.Transparency = 0.5
        local size = windowSize()
        local camera = workspace.CurrentCamera
        local vp = camera and camera.ViewportSize or Vector2.new(800, 600)
        local compact = vp.X < Library.Config.MobileBreakpoint
        Sidebar.Size = UDim2.new(0, compact and 92 or 126, 1, -50)
        Body.Position = UDim2.new(0, compact and 92 or 126, 0, 50)
        Body.Size = UDim2.new(1, -(compact and 92 or 126), 1, -50)
        tween(Dimmer, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {BackgroundTransparency = Library.Theme.DimTransparency})
        tween(MainCorner, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {CornerRadius = UDim.new(0, 14)})
        local t = tween(Main, 0.32, Enum.EasingStyle.Quart, Enum.EasingDirection.Out, {Size = size, Position = UDim2.fromScale(0.5, 0.5)})
        if t then t.Completed:Connect(function() Content.Visible = true transitioning = false end) end
    end

    -- Bubble drag/click. Drag ownership is independent from sliders.
    local dragOwner = {}
    local clickStart
    Main.InputBegan:Connect(function(input)
        if isOpen or closing then return end
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            clickStart = input.Position
            local start = Main.Position
            beginPointer(dragOwner, function(moveInput)
                local delta = moveInput.Position - clickStart
                Main.Position = UDim2.new(start.X.Scale, start.X.Offset + delta.X, start.Y.Scale, start.Y.Offset + delta.Y)
            end, function(endInput)
                if clickStart and (endInput.Position - clickStart).Magnitude < 7 then openWindow() else
                    local camera = workspace.CurrentCamera
                    local vp = camera and camera.ViewportSize or Vector2.new(800, 600)
                    local p = Main.AbsolutePosition
                    local s = Main.AbsoluteSize
                    local cx = p.X + s.X/2
                    local tx = cx < vp.X/2 and 12 or vp.X - s.X - 12
                    local ty = math.clamp(p.Y, 12, vp.Y - s.Y - 12)
                    floatingPosition = UDim2.new(0, tx, 0, ty)
                    tween(Main, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {Position = floatingPosition})
                end
                clickStart = nil
            end)
        end
    end)

    -- Drag header while open. Do not allow controls to steal it through a global callback.
    local headerDragOwner = {}
    Header.InputBegan:Connect(function(input)
        if not isOpen or closing then return end
        if (input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch)  then
            local startInput = input.Position
            local startPos = Main.Position
            beginPointer(headerDragOwner, function(moveInput)
                local delta = moveInput.Position - startInput
                Main.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
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
    function Window:CreateTab(tabName)
        return createTab(tabName)
    end

    function Window:SelectTab(name)
        local target = tostring(name or "")
        for _, item in ipairs(TabButtons) do
            if item.name == target then
                selectTab(item)
                return true
            end
        end
        return false
    end

    function Window:GetTabs()
        local result = {}
        for _, item in ipairs(TabButtons) do table.insert(result, item.name) end
        return result
    end

    function Window:SetVisible(value)
        if value then openWindow() elseif isOpen then minimizeButton:Activate() end
    end
    function Window:IsOpen() return isOpen end
    function Window:Destroy()
        if Pointer.owner == dragOwner or Pointer.owner == headerDragOwner then
            Pointer.owner, Pointer.move, Pointer.ended = nil, nil, nil
        end
        closing = true
        windowMaid:Destroy()
    end
    function Window:GetScreenGui() return ScreenGui end
    function Window:SetStatus(text) statusLabel.Text = tostring(text) end
    function Window:SetAccent(color)
        if typeof(color) ~= "Color3" then return end
        accent = color
        Library.Theme.Accent = color
        MainStroke.Color = color
        dot.BackgroundColor3 = color
        statusLabel.TextColor3 = color
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

return Library
