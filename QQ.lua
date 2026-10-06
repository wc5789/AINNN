local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Library = {}
Library.__index = Library

local Palette = {
    Background = Color3.fromRGB(246, 248, 251),
    Surface = Color3.fromRGB(255, 255, 255),
    Surface2 = Color3.fromRGB(241, 244, 248),
    Surface3 = Color3.fromRGB(234, 239, 246),
    Border = Color3.fromRGB(221, 227, 235),
    Text = Color3.fromRGB(45, 53, 64),
    Muted = Color3.fromRGB(122, 133, 148),
    Blue = Color3.fromRGB(74, 144, 226),
    BlueDark = Color3.fromRGB(55, 123, 208),
    BlueSoft = Color3.fromRGB(231, 241, 253),
    Green = Color3.fromRGB(72, 180, 126),
    Red = Color3.fromRGB(225, 91, 91),
    White = Color3.fromRGB(255, 255, 255)
}

local function New(className, props)
    local object = Instance.new(className)
    for key, value in pairs(props or {}) do
        object[key] = value
    end
    return object
end

local function Corner(parent, radius)
    return New("UICorner", {
        CornerRadius = UDim.new(0, radius),
        Parent = parent
    })
end

local function Stroke(parent, color, thickness, transparency)
    return New("UIStroke", {
        Color = color,
        Thickness = thickness or 1,
        Transparency = transparency or 0,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent
    })
end

local function Padding(parent, left, right, top, bottom)
    return New("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        Parent = parent
    })
end

local function Text(parent, value, size, color, font)
    return New("TextLabel", {
        BackgroundTransparency = 1,
        Text = value or "",
        TextColor3 = color or Palette.Text,
        TextSize = size or 14,
        Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        AutomaticSize = Enum.AutomaticSize.None,
        Parent = parent
    })
end

local function Button(parent)
    return New("TextButton", {
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Text = "",
        BorderSizePixel = 0,
        Selectable = true,
        Parent = parent
    })
end

local function Tween(object, info, properties)
    local tween = TweenService:Create(object, info, properties)
    tween:Play()
    return tween
end

local function IsMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function BindPress(button, callback)
    local fired = false
    local last = 0
    button.Activated:Connect(function()
        local now = os.clock()
        if now - last < 0.08 then
            return
        end
        last = now
        if fired then
            return
        end
        fired = true
        task.defer(function()
            fired = false
        end)
        callback()
    end)
end

local function MakeDraggable(handle, target, library)
    local dragging = false
    local dragInput
    local dragStart
    local startPosition

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPosition = target.Position
            dragInput = input
        end
    end)

    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging or input ~= dragInput or not target.Parent then
            return
        end
        local delta = input.Position - dragStart
        target.Position = UDim2.new(
            startPosition.X.Scale,
            startPosition.X.Offset + delta.X,
            startPosition.Y.Scale,
            startPosition.Y.Offset + delta.Y
        )
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input == dragInput then
            dragging = false
        end
    end)
end

function Library.new(options)
    options = options or {}
    local self = setmetatable({}, Library)
    self.Name = options.Name or "QQUI"
    self.Title = options.Title or "QQUI Library"
    self.Subtitle = options.Subtitle or "Ready"
    self.Accent = options.Accent or Palette.Blue
    self.Destroyed = false
    self.Minimized = false
    self.Tabs = {}
    self.Connections = {}
    self.Popups = {}
    self.CurrentTab = nil
    self:_Build()
    return self
end

function Library:_Build()
    local old = PlayerGui:FindFirstChild(self.Name)
    if old then
        old:Destroy()
    end

    self.ScreenGui = New("ScreenGui", {
        Name = self.Name,
        ResetOnSpawn = false,
        IgnoreGuiInset = true,
        ZIndexBehavior = Enum.ZIndexBehavior.Global,
        Parent = PlayerGui
    })

    self.Shadow = New("Frame", {
        Name = "WindowShadow",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(390, 470),
        BackgroundColor3 = Color3.fromRGB(150, 160, 175),
        BackgroundTransparency = 0.84,
        BorderSizePixel = 0,
        ZIndex = 1,
        Parent = self.ScreenGui
    })
    Corner(self.Shadow, 16)

    self.Window = New("Frame", {
        Name = "Window",
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Size = UDim2.fromOffset(380, 460),
        BackgroundColor3 = Palette.Background,
        BorderSizePixel = 0,
        ZIndex = 10,
        Parent = self.ScreenGui
    })
    Corner(self.Window, 14)
    Stroke(self.Window, Palette.Border, 1, 0)

    New("UISizeConstraint", {
        MinSize = Vector2.new(300, 360),
        MaxSize = Vector2.new(520, 680),
        Parent = self.Window
    })

    self.Topbar = New("Frame", {
        Name = "Topbar",
        Size = UDim2.new(1, 0, 0, 58),
        BackgroundColor3 = Palette.Surface,
        BorderSizePixel = 0,
        ZIndex = 11,
        Parent = self.Window
    })
    Corner(self.Topbar, 14)

    local topMask = New("Frame", {
        Position = UDim2.new(0, 0, 1, -14),
        Size = UDim2.new(1, 0, 0, 14),
        BackgroundColor3 = Palette.Surface,
        BorderSizePixel = 0,
        ZIndex = 11,
        Parent = self.Topbar
    })

    local title = Text(self.Topbar, self.Title, 16, Palette.Text, Enum.Font.GothamBold)
    title.Position = UDim2.fromOffset(18, 10)
    title.Size = UDim2.new(1, -100, 0, 20)

    local subtitle = Text(self.Topbar, self.Subtitle, 11, Palette.Muted, Enum.Font.Gotham)
    subtitle.Position = UDim2.fromOffset(18, 31)
    subtitle.Size = UDim2.new(1, -100, 0, 16)

    local minButton = Button(self.Topbar)
    minButton.Position = UDim2.new(1, -76, 0, 14)
    minButton.Size = UDim2.fromOffset(26, 26)
    minButton.BackgroundColor3 = Palette.Surface2
    minButton.BackgroundTransparency = 0
    Corner(minButton, 8)
    local minText = Text(minButton, "—", 15, Palette.Muted, Enum.Font.GothamBold)
    minText.Size = UDim2.fromScale(1, 1)
    minText.TextXAlignment = Enum.TextXAlignment.Center
    BindPress(minButton, function()
        self:Minimize()
    end)

    local closeButton = Button(self.Topbar)
    closeButton.Position = UDim2.new(1, -42, 0, 14)
    closeButton.Size = UDim2.fromOffset(26, 26)
    closeButton.BackgroundColor3 = Palette.Surface2
    closeButton.BackgroundTransparency = 0
    Corner(closeButton, 8)
    local closeText = Text(closeButton, "×", 17, Palette.Muted, Enum.Font.GothamMedium)
    closeText.Size = UDim2.fromScale(1, 1)
    closeText.TextXAlignment = Enum.TextXAlignment.Center
    BindPress(closeButton, function()
        self:Destroy()
    end)

    self.Body = New("Frame", {
        Position = UDim2.fromOffset(0, 58),
        Size = UDim2.new(1, 0, 1, -58),
        BackgroundTransparency = 1,
        ZIndex = 10,
        Parent = self.Window
    })

    self.TabRail = New("ScrollingFrame", {
        Name = "TabRail",
        Position = UDim2.fromOffset(10, 10),
        Size = UDim2.new(0, 92, 1, -20),
        BackgroundColor3 = Palette.Surface,
        BorderSizePixel = 0,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Palette.Border,
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ZIndex = 11,
        Parent = self.Body
    })
    Corner(self.TabRail, 11)
    Stroke(self.TabRail, Palette.Border, 1, 0)
    Padding(self.TabRail, 6, 6, 8, 8)

    self.TabLayout = New("UIListLayout", {
        Padding = UDim.new(0, 5),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = self.TabRail
    })

    self.Content = New("Frame", {
        Name = "Content",
        Position = UDim2.new(0, 112, 0, 10),
        Size = UDim2.new(1, -122, 1, -20),
        BackgroundColor3 = Palette.Surface,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 11,
        Parent = self.Body
    })
    Corner(self.Content, 11)
    Stroke(self.Content, Palette.Border, 1, 0)

    self.PageHolder = New("Frame", {
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ClipsDescendants = true,
        ZIndex = 12,
        Parent = self.Content
    })

    self.PopupLayer = New("Frame", {
        Name = "PopupLayer",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        ZIndex = 1000,
        Parent = self.ScreenGui
    })

    self.NoticeLayer = New("Frame", {
        Name = "NoticeLayer",
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, 14),
        Size = UDim2.fromOffset(250, 0),
        AutomaticSize = Enum.AutomaticSize.Y,
        BackgroundTransparency = 1,
        ZIndex = 1500,
        Parent = self.ScreenGui
    })
    New("UIListLayout", {
        Padding = UDim.new(0, 7),
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = self.NoticeLayer
    })

    self.Launcher = Button(self.ScreenGui)
    self.Launcher.AnchorPoint = Vector2.new(1, 1)
    self.Launcher.Position = UDim2.new(1, -18, 1, -18)
    self.Launcher.Size = UDim2.fromOffset(48, 48)
    self.Launcher.BackgroundColor3 = self.Accent
    self.Launcher.BackgroundTransparency = 0
    self.Launcher.Visible = false
    self.Launcher.ZIndex = 1400
    Corner(self.Launcher, 15)
    local launchText = Text(self.Launcher, "Q", 18, Palette.White, Enum.Font.GothamBold)
    launchText.Size = UDim2.fromScale(1, 1)
    launchText.TextXAlignment = Enum.TextXAlignment.Center
    BindPress(self.Launcher, function()
        self:Restore()
    end)

    MakeDraggable(self.Topbar, self.Window, self)
    self:_Responsive()
end

function Library:_Responsive()
    local function apply()
        if not self.Window.Parent then
            return
        end
        local camera = workspace.CurrentCamera
        if not camera then
            return
        end
        local viewport = camera.ViewportSize
        local mobile = IsMobile() or viewport.X < 600
        if mobile then
            self.Window.Size = UDim2.new(0, math.clamp(viewport.X - 24, 300, 520), 0, math.clamp(viewport.Y - 90, 380, 620))
            self.Shadow.Size = self.Window.Size + UDim2.fromOffset(10, 10)
            self.TabRail.Size = UDim2.new(0, 86, 1, -20)
            self.Content.Position = UDim2.new(0, 104, 0, 10)
            self.Content.Size = UDim2.new(1, -114, 1, -20)
        else
            self.Window.Size = UDim2.fromOffset(380, 460)
            self.Shadow.Size = UDim2.fromOffset(390, 470)
            self.TabRail.Size = UDim2.new(0, 92, 1, -20)
            self.Content.Position = UDim2.new(0, 112, 0, 10)
            self.Content.Size = UDim2.new(1, -122, 1, -20)
        end
    end
    apply()
    if workspace.CurrentCamera then
        workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(apply)
    end
end

function Library:_CreatePage(tab)
    local page = New("ScrollingFrame", {
        Name = tab.Name .. "Page",
        Size = UDim2.fromScale(1, 1),
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        ScrollBarThickness = 3,
        ScrollBarImageColor3 = Palette.Border,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        CanvasSize = UDim2.new(),
        ZIndex = 13,
        Parent = self.PageHolder
    })
    Padding(page, 13, 13, 13, 18)
    local layout = New("UIListLayout", {
        Padding = UDim.new(0, 8),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = page
    })
    tab.Page = page
    tab.Layout = layout
    return page
end

function Library:AddTab(name, icon)
    local tab = {
        Name = name,
        Icon = icon or "•",
        Items = {}
    }
    table.insert(self.Tabs, tab)
    local button = Button(self.TabRail)
    button.Size = UDim2.new(1, 0, 0, 42)
    button.BackgroundColor3 = Palette.Surface
    button.LayoutOrder = #self.Tabs
    button.ZIndex = 12
    Corner(button, 9)

    local indicator = New("Frame", {
        Position = UDim2.new(0, 0, 0.5, -9),
        Size = UDim2.fromOffset(3, 18),
        BackgroundColor3 = self.Accent,
        BorderSizePixel = 0,
        Visible = false,
        ZIndex = 13,
        Parent = button
    })
    Corner(indicator, 2)

    local iconLabel = Text(button, tab.Icon, 14, Palette.Muted, Enum.Font.GothamBold)
    iconLabel.Position = UDim2.fromOffset(7, 5)
    iconLabel.Size = UDim2.fromOffset(26, 30)
    iconLabel.TextXAlignment = Enum.TextXAlignment.Center

    local nameLabel = Text(button, name, 11, Palette.Muted, Enum.Font.GothamMedium)
    nameLabel.Position = UDim2.fromOffset(31, 5)
    nameLabel.Size = UDim2.new(1, -35, 0, 30)
    nameLabel.TextTruncate = Enum.TextTruncate.AtEnd

    tab.Button = button
    tab.Indicator = indicator
    tab.IconLabel = iconLabel
    tab.NameLabel = nameLabel
    self:_CreatePage(tab)

    BindPress(button, function()
        self:SelectTab(tab)
    end)

    if not self.CurrentTab then
        self:SelectTab(tab, true)
    end
    return tab
end

function Library:SelectTab(tab, instant)
    if self.Destroyed or not tab or not tab.Page then
        return
    end
    if self.CurrentTab == tab then
        return
    end
    local old = self.CurrentTab
    self.CurrentTab = tab

    for _, item in ipairs(self.Tabs) do
        local active = item == tab
        item.Indicator.Visible = active
        item.Button.BackgroundColor3 = active and Palette.BlueSoft or Palette.Surface
        item.IconLabel.TextColor3 = active and self.Accent or Palette.Muted
        item.NameLabel.TextColor3 = active and Palette.Text or Palette.Muted
    end

    tab.Page.Visible = true
    tab.Page.Position = UDim2.fromOffset(8, 0)
    tab.Page.CanvasPosition = Vector2.zero

    if old and old.Page then
        old.Page.Visible = false
        old.Page.Position = UDim2.fromOffset(0, 0)
    end

    if instant then
        tab.Page.Position = UDim2.fromOffset(0, 0)
        return
    end

    Tween(tab.Page, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.fromOffset(0, 0)
    })
end

function Library:_ItemBase(parent, height)
    local holder = New("Frame", {
        Size = UDim2.new(1, 0, 0, height or 44),
        BackgroundColor3 = Palette.Surface,
        BorderSizePixel = 0,
        ZIndex = 14,
        Parent = parent
    })
    return holder
end

function Library:AddSection(tab, title)
    local holder = self:_ItemBase(tab.Page, 30)
    local line = New("Frame", {
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = Palette.Border,
        BorderSizePixel = 0,
        ZIndex = 14,
        Parent = holder
    })
    local label = Text(holder, title, 11, Palette.Muted, Enum.Font.GothamBold)
    label.Size = UDim2.fromOffset(100, 30)
    label.BackgroundColor3 = Palette.Surface
    label.ZIndex = 15
    return holder
end

function Library:AddLabel(tab, text)
    local holder = self:_ItemBase(tab.Page, 30)
    local label = Text(holder, text, 13, Palette.Text, Enum.Font.GothamMedium)
    label.Position = UDim2.fromOffset(2, 0)
    label.Size = UDim2.new(1, -4, 1, 0)
    return holder
end

function Library:AddParagraph(tab, title, body)
    local holder = self:_ItemBase(tab.Page, 64)
    local titleLabel = Text(holder, title, 13, Palette.Text, Enum.Font.GothamBold)
    titleLabel.Position = UDim2.fromOffset(2, 2)
    titleLabel.Size = UDim2.new(1, -4, 0, 20)
    local bodyLabel = Text(holder, body, 11, Palette.Muted, Enum.Font.Gotham)
    bodyLabel.Position = UDim2.fromOffset(2, 23)
    bodyLabel.Size = UDim2.new(1, -4, 0, 38)
    bodyLabel.TextWrapped = true
    bodyLabel.TextYAlignment = Enum.TextYAlignment.Top
    return holder
end

function Library:AddDivider(tab)
    local holder = self:_ItemBase(tab.Page, 8)
    local line = New("Frame", {
        Position = UDim2.new(0, 2, 0.5, 0),
        Size = UDim2.new(1, -4, 0, 1),
        BackgroundColor3 = Palette.Border,
        BorderSizePixel = 0,
        Parent = holder
    })
    return holder
end

function Library:AddButton(tab, title, callback)
    local holder = self:_ItemBase(tab.Page, 42)
    local button = Button(holder)
    button.Position = UDim2.fromOffset(0, 0)
    button.Size = UDim2.fromScale(1, 1)
    button.BackgroundColor3 = Palette.Surface2
    button.BackgroundTransparency = 0
    Corner(button, 9)
    local label = Text(button, title, 12, Palette.Text, Enum.Font.GothamMedium)
    label.Size = UDim2.fromScale(1, 1)
    label.TextXAlignment = Enum.TextXAlignment.Center
    BindPress(button, function()
        Tween(button, TweenInfo.new(0.07), {BackgroundColor3 = Palette.BlueSoft})
        task.delay(0.08, function()
            if button.Parent then
                Tween(button, TweenInfo.new(0.12), {BackgroundColor3 = Palette.Surface2})
            end
        end)
        if callback then
            callback()
        end
    end)
    return holder, button
end

function Library:AddToggle(tab, title, default, callback)
    local holder = self:_ItemBase(tab.Page, 44)
    local label = Text(holder, title, 12, Palette.Text, Enum.Font.GothamMedium)
    label.Position = UDim2.fromOffset(2, 0)
    label.Size = UDim2.new(1, -64, 1, 0)

    local toggle = Button(holder)
    toggle.AnchorPoint = Vector2.new(1, 0.5)
    toggle.Position = UDim2.new(1, -2, 0.5, 0)
    toggle.Size = UDim2.fromOffset(44, 24)
    toggle.BackgroundColor3 = Palette.Surface3
    Corner(toggle, 12)

    local knob = New("Frame", {
        AnchorPoint = Vector2.new(0, 0.5),
        Position = UDim2.new(0, 3, 0.5, 0),
        Size = UDim2.fromOffset(18, 18),
        BackgroundColor3 = Palette.White,
        BorderSizePixel = 0,
        ZIndex = 17,
        Parent = toggle
    })
    Corner(knob, 9)

    local state = default == true
    local function set(value, fire)
        state = value == true
        toggle.BackgroundColor3 = state and self.Accent or Palette.Surface3
        Tween(knob, TweenInfo.new(0.13, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Position = state and UDim2.new(1, -21, 0.5, 0) or UDim2.new(0, 3, 0.5, 0)
        })
        if fire and callback then
            callback(state)
        end
    end
    BindPress(toggle, function()
        set(not state, true)
    end)
    set(state, false)

    return {
        Holder = holder,
        Set = function(_, value) set(value, true) end,
        Get = function() return state end
    }
end

function Library:AddSlider(tab, title, min, max, default, callback)
    min = tonumber(min) or 0
    max = tonumber(max) or 100
    default = math.clamp(tonumber(default) or min, min, max)

    local holder = self:_ItemBase(tab.Page, 58)
    local label = Text(holder, title, 12, Palette.Text, Enum.Font.GothamMedium)
    label.Position = UDim2.fromOffset(2, 2)
    label.Size = UDim2.new(1, -50, 0, 20)

    local valueLabel = Text(holder, tostring(default), 11, Palette.Muted, Enum.Font.GothamMedium)
    valueLabel.AnchorPoint = Vector2.new(1, 0)
    valueLabel.Position = UDim2.new(1, -2, 0, 2)
    valueLabel.Size = UDim2.fromOffset(48, 20)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right

    local track = New("Frame", {
        Position = UDim2.fromOffset(2, 34),
        Size = UDim2.new(1, -4, 0, 6),
        BackgroundColor3 = Palette.Surface3,
        BorderSizePixel = 0,
        ZIndex = 15,
        Parent = holder
    })
    Corner(track, 3)

    local fill = New("Frame", {
        Size = UDim2.new((default - min) / math.max(max - min, 1), 0, 1, 0),
        BackgroundColor3 = self.Accent,
        BorderSizePixel = 0,
        ZIndex = 16,
        Parent = track
    })
    Corner(fill, 3)

    local knob = New("Frame", {
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new((default - min) / math.max(max - min, 1), 0, 0.5, 0),
        Size = UDim2.fromOffset(16, 16),
        BackgroundColor3 = Palette.White,
        BorderSizePixel = 0,
        ZIndex = 17,
        Parent = track
    })
    Corner(knob, 8)
    Stroke(knob, Palette.Border, 1, 0)

    local value = default
    local dragging = false
    local function update(inputX, fire)
        local ratio = math.clamp((inputX - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
        local raw = min + (max - min) * ratio
        value = math.round(raw * 100) / 100
        local percent = (value - min) / math.max(max - min, 1)
        fill.Size = UDim2.new(percent, 0, 1, 0)
        knob.Position = UDim2.new(percent, 0, 0.5, 0)
        valueLabel.Text = tostring(value)
        if fire and callback then
            callback(value)
        end
    end

    track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            update(input.Position.X, true)
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            update(input.Position.X, true)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)

    return {
        Holder = holder,
        Set = function(_, v) update(track.AbsolutePosition.X + math.clamp((v - min) / math.max(max - min, 1), 0, 1) * track.AbsoluteSize.X, true) end,
        Get = function() return value end
    }
end

function Library:_PopupBase(height)
    local popup = New("Frame", {
        Size = UDim2.fromOffset(0, height),
        BackgroundColor3 = Palette.Surface,
        BorderSizePixel = 0,
        ZIndex = 1002,
        Parent = self.PopupLayer
    })
    Corner(popup, 9)
    Stroke(popup, Palette.Border, 1, 0)
    return popup
end

function Library:_PlacePopup(popup, anchor)
    local pos = anchor.AbsolutePosition
    local size = anchor.AbsoluteSize
    local viewport = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize or Vector2.new(800, 600)
    local width = math.max(size.X, 180)
    local height = popup.Size.Y.Offset
    local x = math.clamp(pos.X, 8, viewport.X - width - 8)
    local below = pos.Y + size.Y + 5
    local above = pos.Y - height - 5
    local y = below
    if below + height > viewport.Y - 8 and above > 8 then
        y = above
    end
    popup.Position = UDim2.fromOffset(x, y)
    popup.Size = UDim2.fromOffset(width, height)
end

function Library:_ClosePopups()
    for popup in pairs(self.Popups) do
        if popup and popup.Parent then
            popup:Destroy()
        end
        self.Popups[popup] = nil
    end
end

function Library:AddDropdown(tab, title, values, default, callback)
    local holder = self:_ItemBase(tab.Page, 48)
    local label = Text(holder, title, 12, Palette.Text, Enum.Font.GothamMedium)
    label.Position = UDim2.fromOffset(2, 0)
    label.Size = UDim2.new(0.42, 0, 1, 0)

    local selector = Button(holder)
    selector.AnchorPoint = Vector2.new(1, 0.5)
    selector.Position = UDim2.new(1, -2, 0.5, 0)
    selector.Size = UDim2.new(0.56, 0, 0, 34)
    selector.BackgroundColor3 = Palette.Surface2
    Corner(selector, 8)

    local current = default or values[1] or ""
    local currentLabel = Text(selector, tostring(current), 11, Palette.Text, Enum.Font.GothamMedium)
    currentLabel.Position = UDim2.fromOffset(10, 0)
    currentLabel.Size = UDim2.new(1, -30, 1, 0)
    currentLabel.TextTruncate = Enum.TextTruncate.AtEnd

    local arrow = Text(selector, "⌄", 14, Palette.Muted, Enum.Font.GothamBold)
    arrow.AnchorPoint = Vector2.new(1, 0)
    arrow.Position = UDim2.new(1, -8, 0, 0)
    arrow.Size = UDim2.fromOffset(18, 34)
    arrow.TextXAlignment = Enum.TextXAlignment.Center

    local function open()
        self:_ClosePopups()
        local popup = self:_PopupBase(math.min(190, math.max(42, #values * 34 + 8)))
        self.Popups[popup] = true
        local scroll = New("ScrollingFrame", {
            Position = UDim2.fromOffset(4, 4),
            Size = UDim2.new(1, -8, 1, -8),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Palette.Border,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ZIndex = 1003,
            Parent = popup
        })
        local layout = New("UIListLayout", {
            Padding = UDim.new(0, 2),
            Parent = scroll
        })
        for _, item in ipairs(values) do
            local itemButton = Button(scroll)
            itemButton.Size = UDim2.new(1, -2, 0, 32)
            itemButton.BackgroundColor3 = item == current and Palette.BlueSoft or Palette.Surface
            Corner(itemButton, 7)
            local itemText = Text(itemButton, tostring(item), 11, item == current and self.Accent or Palette.Text, Enum.Font.GothamMedium)
            itemText.Position = UDim2.fromOffset(9, 0)
            itemText.Size = UDim2.new(1, -18, 1, 0)
            BindPress(itemButton, function()
                current = item
                currentLabel.Text = tostring(item)
                if callback then callback(item) end
                self:_ClosePopups()
            end)
        end
        self:_PlacePopup(popup, selector)
        popup.Size = UDim2.fromOffset(popup.Size.X.Offset, 0)
        Tween(popup, TweenInfo.new(0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(popup.Size.X.Offset, math.min(190, math.max(42, #values * 34 + 8)))
        })
    end

    BindPress(selector, open)
    return {
        Holder = holder,
        Set = function(_, value)
            current = value
            currentLabel.Text = tostring(value)
            if callback then callback(value) end
        end,
        Get = function() return current end
    }
end

function Library:AddMultiDropdown(tab, title, values, defaults, callback)
    local holder = self:_ItemBase(tab.Page, 48)
    local label = Text(holder, title, 12, Palette.Text, Enum.Font.GothamMedium)
    label.Position = UDim2.fromOffset(2, 0)
    label.Size = UDim2.new(0.42, 0, 1, 0)

    local selector = Button(holder)
    selector.AnchorPoint = Vector2.new(1, 0.5)
    selector.Position = UDim2.new(1, -2, 0.5, 0)
    selector.Size = UDim2.new(0.56, 0, 0, 34)
    selector.BackgroundColor3 = Palette.Surface2
    Corner(selector, 8)

    local selected = {}
    for _, value in ipairs(defaults or {}) do
        selected[value] = true
    end

    local function selectedText()
        local list = {}
        for _, value in ipairs(values) do
            if selected[value] then
                table.insert(list, tostring(value))
            end
        end
        return #list > 0 and table.concat(list, ", ") or "None"
    end

    local currentLabel = Text(selector, selectedText(), 11, Palette.Text, Enum.Font.GothamMedium)
    currentLabel.Position = UDim2.fromOffset(10, 0)
    currentLabel.Size = UDim2.new(1, -30, 1, 0)
    currentLabel.TextTruncate = Enum.TextTruncate.AtEnd

    local arrow = Text(selector, "⌄", 14, Palette.Muted, Enum.Font.GothamBold)
    arrow.AnchorPoint = Vector2.new(1, 0)
    arrow.Position = UDim2.new(1, -8, 0, 0)
    arrow.Size = UDim2.fromOffset(18, 34)
    arrow.TextXAlignment = Enum.TextXAlignment.Center

    local function open()
        self:_ClosePopups()
        local popupHeight = math.min(220, math.max(70, #values * 36 + 8))
        local popup = self:_PopupBase(popupHeight)
        self.Popups[popup] = true

        local scroll = New("ScrollingFrame", {
            Position = UDim2.fromOffset(4, 4),
            Size = UDim2.new(1, -8, 1, -8),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            ScrollBarThickness = 2,
            ScrollBarImageColor3 = Palette.Border,
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ZIndex = 1003,
            Parent = popup
        })

        local layout = New("UIListLayout", {
            Padding = UDim.new(0, 2),
            Parent = scroll
        })

        local rows = {}
        for _, item in ipairs(values) do
            local itemButton = Button(scroll)
            itemButton.Size = UDim2.new(1, -2, 0, 34)
            itemButton.BackgroundColor3 = selected[item] and Palette.BlueSoft or Palette.Surface
            Corner(itemButton, 7)

            local check = Text(itemButton, selected[item] and "✓" or "", 13, self.Accent, Enum.Font.GothamBold)
            check.Position = UDim2.fromOffset(8, 0)
            check.Size = UDim2.fromOffset(22, 34)
            check.TextXAlignment = Enum.TextXAlignment.Center

            local itemText = Text(itemButton, tostring(item), 11, Palette.Text, Enum.Font.GothamMedium)
            itemText.Position = UDim2.fromOffset(34, 0)
            itemText.Size = UDim2.new(1, -42, 1, 0)

            rows[item] = {Button = itemButton, Check = check}
            BindPress(itemButton, function()
                selected[item] = not selected[item]
                itemButton.BackgroundColor3 = selected[item] and Palette.BlueSoft or Palette.Surface
                check.Text = selected[item] and "✓" or ""
                currentLabel.Text = selectedText()
                if callback then
                    callback(selected)
                end
            end)
        end

        self:_PlacePopup(popup, selector)
    end

    BindPress(selector, open)

    return {
        Holder = holder,
        Set = function(_, list)
            selected = {}
            for _, value in ipairs(list or {}) do selected[value] = true end
            currentLabel.Text = selectedText()
            if callback then callback(selected) end
        end,
        Get = function()
            local result = {}
            for _, value in ipairs(values) do
                if selected[value] then table.insert(result, value) end
            end
            return result
        end
    }
end

function Library:AddTextbox(tab, title, placeholder, callback)
    local holder = self:_ItemBase(tab.Page, 48)
    local label = Text(holder, title, 12, Palette.Text, Enum.Font.GothamMedium)
    label.Position = UDim2.fromOffset(2, 0)
    label.Size = UDim2.new(0.38, 0, 1, 0)

    local box = New("TextBox", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -2, 0.5, 0),
        Size = UDim2.new(0.6, 0, 0, 34),
        BackgroundColor3 = Palette.Surface2,
        BorderSizePixel = 0,
        Text = "",
        PlaceholderText = placeholder or "",
        PlaceholderColor3 = Palette.Muted,
        TextColor3 = Palette.Text,
        TextSize = 11,
        Font = Enum.Font.Gotham,
        ClearTextOnFocus = false,
        TextXAlignment = Enum.TextXAlignment.Left,
        ZIndex = 15,
        Parent = holder
    })
    Corner(box, 8)
    Padding(box, 9, 9, 0, 0)
    box.FocusLost:Connect(function()
        if callback then callback(box.Text) end
    end)
    return holder, box
end

function Library:AddKeybind(tab, title, default, callback)
    local holder = self:_ItemBase(tab.Page, 44)
    local label = Text(holder, title, 12, Palette.Text, Enum.Font.GothamMedium)
    label.Position = UDim2.fromOffset(2, 0)
    label.Size = UDim2.new(1, -100, 1, 0)

    local button = Button(holder)
    button.AnchorPoint = Vector2.new(1, 0.5)
    button.Position = UDim2.new(1, -2, 0.5, 0)
    button.Size = UDim2.fromOffset(90, 32)
    button.BackgroundColor3 = Palette.Surface2
    Corner(button, 8)

    local current = default or Enum.KeyCode.RightShift
    local waiting = false
    local valueLabel = Text(button, current.Name, 11, Palette.Text, Enum.Font.GothamMedium)
    valueLabel.Size = UDim2.fromScale(1, 1)
    valueLabel.TextXAlignment = Enum.TextXAlignment.Center

    BindPress(button, function()
        waiting = true
        valueLabel.Text = "Press key"
    end)

    local connection
    connection = UserInputService.InputBegan:Connect(function(input, processed)
        if processed or not waiting then return end
        if input.UserInputType == Enum.UserInputType.Keyboard then
            current = input.KeyCode
            waiting = false
            valueLabel.Text = current.Name
            if callback then callback(current) end
        end
    end)
    table.insert(self.Connections, connection)

    return {
        Holder = holder,
        Set = function(_, key)
            current = key
            valueLabel.Text = key.Name
            if callback then callback(key) end
        end,
        Get = function() return current end
    }
end

function Library:AddColorPicker(tab, title, default, callback)
    local holder = self:_ItemBase(tab.Page, 44)
    local label = Text(holder, title, 12, Palette.Text, Enum.Font.GothamMedium)
    label.Position = UDim2.fromOffset(2, 0)
    label.Size = UDim2.new(1, -56, 1, 0)

    local button = Button(holder)
    button.AnchorPoint = Vector2.new(1, 0.5)
    button.Position = UDim2.new(1, -2, 0.5, 0)
    button.Size = UDim2.fromOffset(42, 28)
    button.BackgroundColor3 = default or self.Accent
    Corner(button, 8)
    Stroke(button, Palette.Border, 1, 0)

    local current = default or self.Accent
    local function open()
        self:_ClosePopups()
        local popup = self:_PopupBase(176)
        self.Popups[popup] = true

        local titleLabel = Text(popup, "Color", 12, Palette.Text, Enum.Font.GothamBold)
        titleLabel.Position = UDim2.fromOffset(12, 8)
        titleLabel.Size = UDim2.new(1, -24, 0, 22)

        local preview = New("Frame", {
            Position = UDim2.fromOffset(12, 38),
            Size = UDim2.new(1, -24, 0, 28),
            BackgroundColor3 = current,
            BorderSizePixel = 0,
            Parent = popup
        })
        Corner(preview, 7)

        local channels = {
            {"R", current.R},
            {"G", current.G},
            {"B", current.B}
        }

        for index, info in ipairs(channels) do
            local y = 72 + (index - 1) * 31
            local channelLabel = Text(popup, info[1], 10, Palette.Muted, Enum.Font.GothamBold)
            channelLabel.Position = UDim2.fromOffset(12, y)
            channelLabel.Size = UDim2.fromOffset(16, 26)

            local track = New("Frame", {
                Position = UDim2.fromOffset(32, y + 10),
                Size = UDim2.new(1, -72, 0, 6),
                BackgroundColor3 = Palette.Surface3,
                BorderSizePixel = 0,
                Parent = popup
            })
            Corner(track, 3)

            local fill = New("Frame", {
                Size = UDim2.new(info[2], 0, 1, 0),
                BackgroundColor3 = self.Accent,
                BorderSizePixel = 0,
                Parent = track
            })
            Corner(fill, 3)

            local dragging = false
            local function update(x)
                local ratio = math.clamp((x - track.AbsolutePosition.X) / math.max(track.AbsoluteSize.X, 1), 0, 1)
                local r = current.R
                local g = current.G
                local b = current.B
                if index == 1 then r = ratio elseif index == 2 then g = ratio else b = ratio end
                current = Color3.new(r, g, b)
                fill.Size = UDim2.new(ratio, 0, 1, 0)
                preview.BackgroundColor3 = current
                button.BackgroundColor3 = current
                if callback then callback(current) end
            end
            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    update(input.Position.X)
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                    update(input.Position.X)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
        end

        local done = Button(popup)
        done.Position = UDim2.new(1, -74, 1, -34)
        done.Size = UDim2.fromOffset(62, 26)
        done.BackgroundColor3 = self.Accent
        Corner(done, 7)
        local doneLabel = Text(done, "Done", 10, Palette.White, Enum.Font.GothamBold)
        doneLabel.Size = UDim2.fromScale(1, 1)
        doneLabel.TextXAlignment = Enum.TextXAlignment.Center
        BindPress(done, function()
            self:_ClosePopups()
        end)

        self:_PlacePopup(popup, button)
    end

    BindPress(button, open)

    return {
        Holder = holder,
        Set = function(_, color)
            current = color
            button.BackgroundColor3 = color
            if callback then callback(color) end
        end,
        Get = function() return current end
    }
end

function Library:AddStatus(tab, title, status, active)
    local holder = self:_ItemBase(tab.Page, 36)
    local label = Text(holder, title, 11, Palette.Muted, Enum.Font.GothamMedium)
    label.Position = UDim2.fromOffset(2, 0)
    label.Size = UDim2.new(0.6, 0, 1, 0)

    local dot = New("Frame", {
        AnchorPoint = Vector2.new(1, 0.5),
        Position = UDim2.new(1, -2, 0.5, 0),
        Size = UDim2.fromOffset(8, 8),
        BackgroundColor3 = active == false and Palette.Red or Palette.Green,
        BorderSizePixel = 0,
        Parent = holder
    })
    Corner(dot, 4)

    local value = Text(holder, status or "Online", 10, Palette.Muted, Enum.Font.GothamMedium)
    value.AnchorPoint = Vector2.new(1, 0.5)
    value.Position = UDim2.new(1, -16, 0.5, 0)
    value.Size = UDim2.fromOffset(80, 24)
    value.TextXAlignment = Enum.TextXAlignment.Right

    return {
        Set = function(_, textValue, state)
            value.Text = textValue
            dot.BackgroundColor3 = state == false and Palette.Red or Palette.Green
        end
    }
end

function Library:Notify(title, message, duration)
    if self.Destroyed then return end
    duration = tonumber(duration) or 3

    local card = New("Frame", {
        Size = UDim2.fromOffset(240, 64),
        BackgroundColor3 = Palette.Surface,
        BorderSizePixel = 0,
        ClipsDescendants = true,
        ZIndex = 1501,
        Parent = self.NoticeLayer
    })
    Corner(card, 10)
    Stroke(card, Palette.Border, 1, 0)

    local accent = New("Frame", {
        Size = UDim2.new(0, 3, 1, 0),
        BackgroundColor3 = self.Accent,
        BorderSizePixel = 0,
        ZIndex = 1502,
        Parent = card
    })

    local titleLabel = Text(card, title or "Notification", 11, Palette.Text, Enum.Font.GothamBold)
    titleLabel.Position = UDim2.fromOffset(14, 8)
    titleLabel.Size = UDim2.new(1, -24, 0, 18)

    local messageLabel = Text(card, message or "", 10, Palette.Muted, Enum.Font.Gotham)
    messageLabel.Position = UDim2.fromOffset(14, 27)
    messageLabel.Size = UDim2.new(1, -24, 0, 30)
    messageLabel.TextWrapped = true
    messageLabel.TextYAlignment = Enum.TextYAlignment.Top

    card.Position = UDim2.fromOffset(270, 0)
    Tween(card, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = UDim2.fromOffset(0, 0)
    })

    task.delay(duration, function()
        if card.Parent then
            local tween = Tween(card, TweenInfo.new(0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
                Position = UDim2.fromOffset(270, 0)
            })
            tween.Completed:Wait()
            if card.Parent then card:Destroy() end
        end
    end)
end

function Library:Minimize()
    if self.Destroyed or self.Minimized then return end
    self.Minimized = true
    self:_ClosePopups()
    self.Launcher.Visible = true
    self.Launcher.Size = UDim2.fromOffset(10, 10)
    self.Launcher.BackgroundTransparency = 1
    Tween(self.Window, TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
        Size = UDim2.fromOffset(20, 20),
        BackgroundTransparency = 1
    })
    Tween(self.Shadow, TweenInfo.new(0.18), {
        Size = UDim2.fromOffset(20, 20),
        BackgroundTransparency = 1
    })
    task.delay(0.18, function()
        if self.Destroyed then return end
        self.Window.Visible = false
        self.Shadow.Visible = false
        Tween(self.Launcher, TweenInfo.new(0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
            Size = UDim2.fromOffset(48, 48),
            BackgroundTransparency = 0
        })
    end)
end

function Library:Restore()
    if self.Destroyed or not self.Minimized then return end
    self.Minimized = false
    self.Launcher.Visible = false
    self.Window.Visible = true
    self.Shadow.Visible = true
    self.Window.Size = UDim2.fromOffset(20, 20)
    self.Shadow.Size = UDim2.fromOffset(20, 20)
    self.Window.BackgroundTransparency = 0
    self.Shadow.BackgroundTransparency = 0.84
    Tween(self.Window, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = IsMobile() and self.Window.Size or UDim2.fromOffset(380, 460)
    })
    Tween(self.Shadow, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = IsMobile() and self.Window.Size + UDim2.fromOffset(10, 10) or UDim2.fromOffset(390, 470)
    })
end

function Library:Destroy()
    if self.Destroyed then return end
    self.Destroyed = true
    self:_ClosePopups()

    for _, connection in ipairs(self.Connections) do
        if connection then
            connection:Disconnect()
        end
    end
    table.clear(self.Connections)

    if self.NoticeLayer then
        for _, child in ipairs(self.NoticeLayer:GetChildren()) do
            if child:IsA("Frame") then
                Tween(child, TweenInfo.new(0.12), {Position = UDim2.fromOffset(270, 0)})
            end
        end
    end

    local window = self.Window
    local shadow = self.Shadow
    local launcher = self.Launcher

    if window and window.Parent then
        Tween(window, TweenInfo.new(0.17, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
            Size = UDim2.fromOffset(20, 20),
            BackgroundTransparency = 1
        })
    end
    if shadow and shadow.Parent then
        Tween(shadow, TweenInfo.new(0.17), {
            Size = UDim2.fromOffset(20, 20),
            BackgroundTransparency = 1
        })
    end
    if launcher and launcher.Parent then
        Tween(launcher, TweenInfo.new(0.12), {
            Size = UDim2.fromOffset(10, 10),
            BackgroundTransparency = 1
        })
    end

    task.delay(0.2, function()
        if self.ScreenGui and self.ScreenGui.Parent then
            self.ScreenGui:Destroy()
        end
    end)
end

function Library:Show()
    if self.Destroyed then return end
    self.Minimized = false
    self.Window.Visible = true
    self.Shadow.Visible = true
    self.Launcher.Visible = false
end

return Library
