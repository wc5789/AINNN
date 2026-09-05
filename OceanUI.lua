--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║                    OceanUI Library v1.0                        ║
    ║           高质量现代化UI库 | 适配移动端&PC端                   ║
    ║                      by Ocean                                 ║
    ╚═══════════════════════════════════════════════════════════════╝
    
    使用示例:
        local OceanUI = require(script.OceanUI)
        
        -- 创建窗口
        local window = OceanUI.CreateWindow({
            Title = "Ocean UI",
            Theme = "Ocean", -- Ocean, Purple, Sunset, Forest
        })
        
        -- 创建标签页
        local tab = window:AddTab("主页")
        
        -- 添加组件
        tab:AddLabel("欢迎使用 OceanUI!")
        tab:AddButton("点击我", function()
            print("按钮被点击了!")
        end)
        
        -- 拖动功能
        window:MakeDraggable()
        
        -- 打开/关闭
        window:Show()
        window:Hide()
        window:Toggle()
]]

local OceanUI = {}

-- ═══════════════════════════════════════════════════════════════
--                    核心配置与常量
-- ═══════════════════════════════════════════════════════════════

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

-- 主题颜色配置
local THEMES = {
    Ocean = {
        Primary = Color3.fromRGB(0, 170, 255),
        Secondary = Color3.fromRGB(0, 130, 200),
        Accent = Color3.fromRGB(100, 220, 255),
        Background = Color3.fromRGB(25, 30, 45),
        Surface = Color3.fromRGB(35, 40, 60),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(180, 185, 200),
        Border = Color3.fromRGB(60, 70, 100),
        Success = Color3.fromRGB(0, 200, 100),
        Warning = Color3.fromRGB(255, 180, 0),
        Error = Color3.fromRGB(255, 80, 80),
        Gradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 170, 255)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 130, 200))
        })
    },
    Purple = {
        Primary = Color3.fromRGB(147, 112, 219),
        Secondary = Color3.fromRGB(120, 90, 180),
        Accent = Color3.fromRGB(200, 170, 255),
        Background = Color3.fromRGB(30, 25, 45),
        Surface = Color3.fromRGB(45, 35, 65),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(200, 195, 220),
        Border = Color3.fromRGB(80, 70, 110),
        Success = Color3.fromRGB(0, 200, 100),
        Warning = Color3.fromRGB(255, 180, 0),
        Error = Color3.fromRGB(255, 80, 80),
        Gradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(147, 112, 219)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(120, 90, 180))
        })
    },
    Sunset = {
        Primary = Color3.fromRGB(255, 120, 80),
        Secondary = Color3.fromRGB(255, 90, 60),
        Accent = Color3.fromRGB(255, 180, 150),
        Background = Color3.fromRGB(45, 30, 25),
        Surface = Color3.fromRGB(65, 45, 35),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(255, 220, 200),
        Border = Color3.fromRGB(120, 90, 70),
        Success = Color3.fromRGB(0, 200, 100),
        Warning = Color3.fromRGB(255, 180, 0),
        Error = Color3.fromRGB(255, 80, 80),
        Gradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 120, 80)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 90, 60))
        })
    },
    Forest = {
        Primary = Color3.fromRGB(80, 180, 100),
        Secondary = Color3.fromRGB(60, 150, 80),
        Accent = Color3.fromRGB(150, 220, 160),
        Background = Color3.fromRGB(25, 40, 30),
        Surface = Color3.fromRGB(35, 55, 40),
        Text = Color3.fromRGB(255, 255, 255),
        TextSecondary = Color3.fromRGB(180, 210, 185),
        Border = Color3.fromRGB(70, 100, 75),
        Success = Color3.fromRGB(0, 200, 100),
        Warning = Color3.fromRGB(255, 180, 0),
        Error = Color3.fromRGB(255, 80, 80),
        Gradient = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(80, 180, 100)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(60, 150, 80))
        })
    }
}

-- 动画配置
local ANIMATION_CONFIG = {
    HoverSpeed = 0.2,
    ClickSpeed = 0.1,
    OpenSpeed = 0.3,
    CloseSpeed = 0.2,
    SpringStyle = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    SmoothStyle = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    BounceStyle = TweenInfo.new(0.4, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out)
}

-- 默认配置
local DEFAULT_CONFIG = {
    Width = 550,
    Height = 400,
    MinWidth = 400,
    MinHeight = 300,
    CornerRadius = 12,
    HeaderHeight = 45,
    TabHeight = 35,
    Padding = 12,
    ElementSpacing = 8,
    ShadowSize = 25,
    EnableShadow = true,
    EnableGlow = true,
    EnableAnimations = true,
    Theme = "Ocean",
    DragSensitivity = 0.5,
    MobileScaleFactor = 0.85,
    KeepCentered = true,
    ShowCloseButton = true,
    ShowMinimizeButton = true,
    ShowMaximizeButton = true
}

-- ═══════════════════════════════════════════════════════════════
--                    设备检测与响应式布局
-- ═══════════════════════════════════════════════════════════════

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

local function IsMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function GetScreenSize()
    local viewport = workspace.CurrentCamera.ViewportSize
    return viewport.X, viewport.Y
end

local function ScaleForDevice(value)
    if IsMobile() then
        return value * DEFAULT_CONFIG.MobileScaleFactor
    end
    return value
end

local function GetResponsiveSize(width, height)
    local screenX, screenY = GetScreenSize()
    local maxWidth = screenX * 0.9
    local maxHeight = screenY * 0.85
    
    local newWidth = math.min(width, maxWidth)
    local newHeight = math.min(height, maxHeight)
    
    return ScaleForDevice(newWidth), ScaleForDevice(newHeight)
end

-- ═══════════════════════════════════════════════════════════════
--                    工具函数
-- ═══════════════════════════════════════════════════════════════

local function CreateTween(instance, properties, duration, style)
    local tweenInfo = style or ANIMATION_CONFIG.SmoothStyle
    if duration then
        tweenInfo = TweenInfo.new(duration, style.EasingStyle, style.EasingDirection)
    end
    local tween = TweenService:Create(instance, tweenInfo, properties)
    return tween
end

local function AddCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or DEFAULT_CONFIG.CornerRadius)
    corner.Parent = parent
    return corner
end

local function AddStroke(parent, color, thickness)
    local stroke = Instance.new("UIStroke")
    stroke.Color = color or Color3.fromRGB(80, 90, 120)
    stroke.Thickness = thickness or 1
    stroke.Transparency = 0.5
    stroke.Parent = parent
    return stroke
end

local function CreateGradient(parent, colors, rotation)
    local gradient = Instance.new("UIGradient")
    gradient.Color = colors
    gradient.Rotation = rotation or 90
    gradient.Parent = parent
    return gradient
end

local function CreateShadow(parent)
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.BackgroundTransparency = 1
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.Position = UDim2.new(0, -15, 0, -15)
    shadow.Image = "rbxassetid://5554236805"
    shadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    shadow.ZIndex = -1
    shadow.Parent = parent
    return shadow
end

local function CreateGlow(parent, color)
    local glow = Instance.new("ImageLabel")
    glow.Name = "Glow"
    glow.BackgroundTransparency = 1
    glow.Size = UDim2.new(1, 20, 1, 20)
    glow.Position = UDim2.new(0, -10, 0, -10)
    glow.Image = "rbxassetid://4487654331"
    glow.ImageColor3 = color or Color3.fromRGB(0, 170, 255)
    glow.ImageTransparency = 0.6
    glow.ScaleType = Enum.ScaleType.Slice
    glow.SliceCenter = Rect.new(10, 10, 490, 490)
    glow.ZIndex = 0
    glow.Parent = parent
    return glow
end

local function MakeInteractive(element, callbacks, theme)
    callbacks = callbacks or {}
    theme = theme or THEMES.Ocean
    
    local originalColor
    if element:IsA("TextButton") or element:IsA("ImageButton") then
        originalColor = element.BackgroundColor3
    end
    
    element.MouseEnter.Connect(function()
        if callbacks.OnHover and callbacks.OnHover() ~= nil then return end
        if element:IsA("TextButton") or element:IsA("ImageButton") then
            CreateTween(element, {BackgroundColor3 = originalColor:Lerp(theme.Surface, 0.3)}, ANIMATION_CONFIG.HoverSpeed):Play()
        end
    end)
    
    element.MouseLeave.Connect(function()
        if callbacks.OnLeave and callbacks.OnLeave() ~= nil then return end
        if element:IsA("TextButton") or element:IsA("ImageButton") then
            CreateTween(element, {BackgroundColor3 = originalColor}, ANIMATION_CONFIG.HoverSpeed):Play()
        end
    end)
    
    element.MouseButton1Down.Connect(function()
        if callbacks.OnDown then callbacks.OnDown() return end
        if element:IsA("TextButton") or element:IsA("ImageButton") then
            CreateTween(element, {Size = element.Size - UDim2.new(0, 2, 0, 2)}, ANIMATION_CONFIG.ClickSpeed):Play()
        end
    end)
    
    element.MouseButton1Up.Connect(function()
        if callbacks.OnUp then callbacks.OnUp() return end
        if element:IsA("TextButton") or element:IsA("ImageButton") then
            CreateTween(element, {Size = element.Size + UDim2.new(0, 2, 0, 2)}, ANIMATION_CONFIG.ClickSpeed):Play()
        end
    end)
    
    return element
end

-- ═══════════════════════════════════════════════════════════════
--                    容器管理器
-- ═══════════════════════════════════════════════════════════════

local ContainerManager = {}
ContainerManager.__index = ContainerManager

function ContainerManager.new(parent, theme)
    local self = setmetatable({}, ContainerManager)
    self.Parent = parent
    self.Theme = theme
    self.Elements = {}
    self.CurrentY = 0
    return self
end

function ContainerManager:AddElement(element, height)
    element.Position = UDim2.new(0, DEFAULT_CONFIG.Padding, 0, self.CurrentY)
    self.CurrentY = self.CurrentY + height + DEFAULT_CONFIG.ElementSpacing
    element.Parent = self.Parent
    table.insert(self.Elements, element)
    return element
end

function ContainerManager:AddSpacer(height)
    self.CurrentY = self.CurrentY + (height or DEFAULT_CONFIG.ElementSpacing)
end

function ContainerManager:GetTotalHeight()
    return self.CurrentY
end

function ContainerManager:Clear()
    for _, element in ipairs(self.Elements) do
        element:Destroy()
    end
    self.Elements = {}
    self.CurrentY = 0
end

-- ═══════════════════════════════════════════════════════════════
--                    OceanUI 主类
-- ═══════════════════════════════════════════════════════════════

OceanUI.Windows = {}

function OceanUI.GetTheme(name)
    return THEMES[name] or THEMES.Ocean
end

-- 创建主窗口
function OceanUI.CreateWindow(config)
    config = setmetatable(config or {}, {__index = DEFAULT_CONFIG})
    
    local theme = THEMES[config.Theme] or THEMES.Ocean
    local width, height = GetResponsiveSize(config.Width, config.Height)
    
    -- 屏幕居中位置
    local screenX, screenY = GetScreenSize()
    local position = UDim2.new(0.5, -width/2, 0.5, -height/2)
    
    -- 主窗口框架
    local Window = Instance.new("Frame")
    Window.Name = "OceanUI_Window"
    Window.Size = UDim2.new(0, width, 0, height)
    Window.Position = position
    Window.BackgroundColor3 = theme.Background
    Window.BorderSizePixel = 0
    Window.ZIndex = 10
    Window.Visible = false
    Window.Parent = PlayerGui
    
    -- 圆角
    AddCorner(Window, config.CornerRadius)
    
    -- 阴影
    if config.EnableShadow then
        CreateShadow(Window)
    end
    
    -- 发光效果
    if config.EnableGlow then
        CreateGlow(Window, theme.Primary)
    end
    
    -- 边框
    AddStroke(Window, theme.Border, 1)
    
    -- 头部区域
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, config.HeaderHeight)
    Header.Position = UDim2.new(0, 0, 0, 0)
    Header.BackgroundColor3 = theme.Surface
    Header.BorderSizePixel = 0
    Header.Parent = Window
    
    AddCorner(Header, config.CornerRadius)
    -- 只对底部应用圆角
    Header.ClipsDescendants = true
    
    -- 头部渐变条
    local HeaderGradient = Instance.new("Frame")
    HeaderGradient.Name = "HeaderGradient"
    HeaderGradient.Size = UDim2.new(1, 0, 0, 3)
    HeaderGradient.Position = UDim2.new(0, 0, 0, 0)
    HeaderGradient.BackgroundTransparency = 1
    HeaderGradient.Parent = Header
    
    local gradient = Instance.new("UIGradient")
    gradient.Color = theme.Gradient
    gradient.Rotation = 0
    gradient.Parent = HeaderGradient
    
    -- 标题
    local Title = Instance.new("TextLabel")
    Title.Name = "Title"
    Title.Size = UDim2.new(1, -120, 1, 0)
    Title.Position = UDim2.new(0, config.Padding, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = config.Title or "OceanUI"
    Title.TextColor3 = theme.Text
    Title.TextSize = ScaleForDevice(18)
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Header
    
    -- 控制按钮容器
    local Controls = Instance.new("Frame")
    Controls.Name = "Controls"
    Controls.Size = UDim2.new(0, 100, 1, 0)
    Controls.Position = UDim2.new(1, -105, 0, 0)
    Controls.BackgroundTransparency = 1
    Controls.Parent = Header
    
    local ControlsLayout = Instance.new("UIListLayout")
    ControlsLayout.FillDirection = Enum.FillDirection.Horizontal
    ControlsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    ControlsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    ControlsLayout.Padding = UDim.new(0, 8)
    ControlsLayout.Parent = Controls
    
    -- 最小化按钮
    if config.ShowMinimizeButton then
        local MinimizeBtn = Instance.new("TextButton")
        MinimizeBtn.Name = "MinimizeButton"
        MinimizeBtn.Size = UDim2.new(0, 28, 0, 28)
        MinimizeBtn.BackgroundColor3 = theme.Surface
        MinimizeBtn.BorderSizePixel = 0
        MinimizeBtn.Text = "−"
        MinimizeBtn.TextColor3 = theme.Text
        MinimizeBtn.TextSize = 20
        MinimizeBtn.Font = Enum.Font.GothamBold
        MinimizeBtn.Parent = Controls
        AddCorner(MinimizeBtn, 6)
        MakeInteractive(MinimizeBtn, {}, theme)
        
        MinimizeBtn.MouseButton1Click:Connect(function()
            Window:TweenSize(UDim2.new(0, width, 0, config.HeaderHeight), ANIMATION_CONFIG.SpringStyle)
        end)
    end
    
    -- 最大化按钮
    if config.ShowMaximizeButton then
        local MaximizeBtn = Instance.new("TextButton")
        MaximizeBtn.Name = "MaximizeButton"
        MaximizeBtn.Size = UDim2.new(0, 28, 0, 28)
        MaximizeBtn.BackgroundColor3 = theme.Surface
        MaximizeBtn.BorderSizePixel = 0
        MaximizeBtn.Text = "□"
        MaximizeBtn.TextColor3 = theme.Text
        MaximizeBtn.TextSize = 14
        MaximizeBtn.Font = Enum.Font.GothamBold
        MaximizeBtn.Parent = Controls
        AddCorner(MaximizeBtn, 6)
        MakeInteractive(MaximizeBtn, {}, theme)
        
        MaximizeBtn.MouseButton1Click:Connect(function()
            -- 切换最大化/还原
            if Window.Size == UDim2.new(0, width, 0, height) then
                Window:TweenSize(UDim2.new(0.95, 0, 0.95, 0), ANIMATION_CONFIG.SpringStyle)
            else
                Window:TweenSize(UDim2.new(0, width, 0, height), ANIMATION_CONFIG.SpringStyle)
            end
        end)
    end
    
    -- 关闭按钮
    if config.ShowCloseButton then
        local CloseBtn = Instance.new("TextButton")
        CloseBtn.Name = "CloseButton"
        CloseBtn.Size = UDim2.new(0, 28, 0, 28)
        CloseBtn.BackgroundColor3 = theme.Error
        CloseBtn.BackgroundTransparency = 0.3
        CloseBtn.BorderSizePixel = 0
        CloseBtn.Text = "✕"
        CloseBtn.TextColor3 = theme.Text
        CloseBtn.TextSize = 14
        CloseBtn.Font = Enum.Font.GothamBold
        CloseBtn.Parent = Controls
        AddCorner(CloseBtn, 6)
        MakeInteractive(CloseBtn, {}, theme)
        
        CloseBtn.MouseButton1Click:Connect(function()
            Window:TweenSize(UDim2.new(0, 0, 0, 0), ANIMATION_CONFIG.SmoothStyle)
            task.delay(ANIMATION_CONFIG.CloseSpeed, function()
                Window.Visible = false
            end)
        end)
    end
    
    -- 标签页容器
    local TabContainer = Instance.new("Frame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(1, -config.Padding * 2, 0, config.TabHeight + 8)
    TabContainer.Position = UDim2.new(0, config.Padding, 0, config.HeaderHeight + 8)
    TabContainer.BackgroundTransparency = 1
    TabContainer.Parent = Window
    
    local TabScrollingFrame = Instance.new("ScrollingFrame")
    TabScrollingFrame.Name = "TabScrollingFrame"
    TabScrollingFrame.Size = UDim2.new(1, 0, 1, 0)
    TabScrollingFrame.Position = UDim2.new(0, 0, 0, 0)
    TabScrollingFrame.BackgroundTransparency = 1
    TabScrollingFrame.BorderSizePixel = 0
    TabScrollingFrame.ScrollBarThickness = 0
    TabScrollingFrame.ScrollingDirection = Enum.ScrollingDirection.X
    TabScrollingFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabScrollingFrame.AutomaticCanvasSize = Enum.AutomaticSize.X
    TabScrollingFrame.Parent = TabContainer
    
    local TabLayout = Instance.new("UIListLayout")
    TabLayout.FillDirection = Enum.FillDirection.Horizontal
    TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    TabLayout.Padding = UDim.new(0, 6)
    TabLayout.Parent = TabScrollingFrame
    
    -- 内容区域
    local ContentFrame = Instance.new("ScrollingFrame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(1, -config.Padding * 2, 1, -config.HeaderHeight - config.TabHeight - 16)
    ContentFrame.Position = UDim2.new(0, config.Padding, 0, config.HeaderHeight + config.TabHeight + 16)
    ContentFrame.BackgroundColor3 = theme.Background
    ContentFrame.BackgroundTransparency = 0.5
    ContentFrame.BorderSizePixel = 0
    ContentFrame.ScrollBarThickness = 4
    ContentFrame.ScrollBarImageColor3 = theme.Primary
    ContentFrame.ScrollBarImageTransparency = 0.3
    ContentFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
    ContentFrame.AutomaticCanvasSize = Enum.AutomaticSize.Y
    ContentFrame.Parent = Window
    
    local ContentLayout = Instance.new("UIListLayout")
    ContentLayout.Padding = UDim.new(0, DEFAULT_CONFIG.ElementSpacing)
    ContentLayout.Parent = ContentFrame
    
    local Padding = Instance.new("UIPadding")
    Padding.PaddingTop = UDim.new(0, DEFAULT_CONFIG.Padding)
    Padding.PaddingBottom = UDim.new(0, DEFAULT_CONFIG.Padding)
    Padding.PaddingLeft = UDim.new(0, DEFAULT_CONFIG.Padding)
    Padding.PaddingRight = UDim.new(0, DEFAULT_CONFIG.Padding)
    Padding.Parent = ContentFrame
    
    -- 窗口对象
    local WindowObj = {
        Instance = Window,
        Header = Header,
        ContentFrame = ContentFrame,
        TabScrollingFrame = TabScrollingFrame,
        Theme = theme,
        Config = config,
        Tabs = {},
        CurrentTab = nil,
        IsDragging = false,
        IsVisible = false
    }
    
    -- 使窗口可拖动
    function WindowObj:MakeDraggable()
        local dragStart
        local startPos
        local sensitivity = self.Config.DragSensitivity
        
        Header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or 
               input.UserInputType == Enum.UserInputType.Touch then
                self.IsDragging = true
                dragStart = input.Position
                startPos = Window.Position
            end
        end)
        
        Header.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or 
               input.UserInputType == Enum.UserInputType.Touch then
                self.IsDragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if self.IsDragging and (input.UserInputType == Enum.UserInputType.MouseMovement or 
               input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - dragStart
                Window.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X * sensitivity,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y * sensitivity
                )
            end
        end)
    end
    
    -- 显示/隐藏
    function WindowObj:Show()
        if not self.IsVisible then
            Window.Visible = true
            Window.Size = UDim2.new(0, 0, 0, 0)
            Window:TweenSize(UDim2.new(0, width, 0, height), ANIMATION_CONFIG.SpringStyle)
            self.IsVisible = true
        end
    end
    
    function WindowObj:Hide()
        if self.IsVisible then
            Window:TweenSize(UDim2.new(0, 0, 0, 0), ANIMATION_CONFIG.SmoothStyle)
            task.delay(ANIMATION_CONFIG.CloseSpeed, function()
                Window.Visible = false
            end)
            self.IsVisible = false
        end
    end
    
    function WindowObj:Toggle()
        if self.IsVisible then
            self:Hide()
        else
            self:Show()
        end
    end
    
    -- 添加标签页
    function WindowObj:AddTab(name, icon)
        local tabButton = Instance.new("TextButton")
        tabButton.Name = "Tab_" .. name
        tabButton.Size = UDim2.new(0, icon and 110 or 90, 0, config.TabHeight)
        tabButton.BackgroundColor3 = theme.Surface
        tabButton.BackgroundTransparency = 0.5
        tabButton.BorderSizePixel = 0
        tabButton.Text = icon and (icon .. " " .. name) or name
        tabButton.TextColor3 = theme.TextSecondary
        tabButton.TextSize = ScaleForDevice(14)
        tabButton.Font = Enum.Font.GothamMedium
        tabButton.Parent = self.TabScrollingFrame
        AddCorner(tabButton, 8)
        
        local tabContent = Instance.new("Frame")
        tabContent.Name = "TabContent_" .. name
        tabContent.Size = UDim2.new(1, 0, 0, 0)
        tabContent.AutomaticSize = Enum.AutomaticSize.Y
        tabContent.BackgroundTransparency = 1
        tabContent.Visible = false
        tabContent.Parent = self.ContentFrame
        
        local tab = {
            Name = name,
            Button = tabButton,
            Content = tabContent,
            Container = ContainerManager.new(tabContent, self.Theme),
            Elements = {}
        }
        
        -- 标签页点击事件
        tabButton.MouseButton1Click:Connect(function()
            self:SelectTab(name)
        end)
        
        -- 悬停效果
        MakeInteractive(tabButton, {
            OnHover = function()
                if self.CurrentTab ~= tab then
                    CreateTween(tabButton, {BackgroundColor3 = theme.Surface}, ANIMATION_CONFIG.HoverSpeed):Play()
                end
            end,
            OnLeave = function()
                if self.CurrentTab ~= tab then
                    CreateTween(tabButton, {BackgroundColor3 = theme.Background}, ANIMATION_CONFIG.HoverSpeed):Play()
                end
            end
        }, self.Theme)
        
        table.insert(self.Tabs, tab)
        
        -- 自动选择第一个标签
        if #self.Tabs == 1 then
            self:SelectTab(name)
        end
        
        return tab
    end
    
    -- 选择标签页
    function WindowObj:SelectTab(name)
        for _, tab in ipairs(self.Tabs) do
            if tab.Name == name then
                tab.Content.Visible = true
                tab.Button.BackgroundColor3 = self.Theme.Primary
                tab.Button.BackgroundTransparency = 0.2
                tab.Button.TextColor3 = self.Theme.Text
                self.CurrentTab = tab
                
                CreateTween(tab.Button, {Size = UDim2.new(0, tab.Button.Size.X.Offset + 5, 0, tab.Button.Size.Y.Offset)}, 
                    ANIMATION_CONFIG.SpringStyle):Play()
            else
                tab.Content.Visible = false
                tab.Button.BackgroundColor3 = self.Theme.Surface
                tab.Button.BackgroundTransparency = 0.5
                tab.Button.TextColor3 = self.Theme.TextSecondary
                
                CreateTween(tab.Button, {Size = UDim2.new(0, tab.Button.Size.X.Offset - 2, 0, tab.Button.Size.Y.Offset - 2)}, 
                    ANIMATION_CONFIG.SmoothStyle):Play()
            end
        end
    end
    
    table.insert(OceanUI.Windows, WindowObj)
    return WindowObj
end

-- ═══════════════════════════════════════════════════════════════
--                    组件工厂
-- ═══════════════════════════════════════════════════════════════

local Components = {}

-- 标签
function Components.AddLabel(tab, text, config)
    config = config or {}
    
    local label = Instance.new("TextLabel")
    label.Name = "Label_" .. (#tab.Elements + 1)
    label.Size = UDim2.new(1, 0, 0, config.Height or 30)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = tab.Container.Theme.Text
    label.TextSize = config.TextSize or ScaleForDevice(14)
    label.Font = config.Font or Enum.Font.Gotham
    label.TextXAlignment = config.Alignment or Enum.TextXAlignment.Left
    label.RichText = config.RichText or false
    label.Parent = tab.Content
    
    table.insert(tab.Elements, label)
    return label
end

-- 标题标签
function Components.AddTitle(tab, text, config)
    config = config or {}
    
    local title = Instance.new("TextLabel")
    title.Name = "Title_" .. (#tab.Elements + 1)
    title.Size = UDim2.new(1, 0, 0, config.Height or 40)
    title.BackgroundTransparency = 1
    title.Text = text
    title.TextColor3 = tab.Container.Theme.Primary
    title.TextSize = ScaleForDevice(20)
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.RichText = true
    title.Parent = tab.Content
    
    -- 添加下划线装饰
    local underline = Instance.new("Frame")
    underline.Name = "Underline"
    underline.Size = UDim2.new(0.3, 0, 0, 2)
    underline.Position = UDim2.new(0, 0, 1, 4)
    underline.BackgroundColor3 = tab.Container.Theme.Primary
    underline.BackgroundTransparency = 0.3
    underline.Parent = title
    AddCorner(underline, 1)
    
    table.insert(tab.Elements, title)
    return title
end

-- 按钮
function Components.AddButton(tab, text, callback, config)
    config = config or {}
    
    local buttonHeight = ScaleForDevice(config.Height or 38)
    
    local button = Instance.new("TextButton")
    button.Name = "Button_" .. (#tab.Elements + 1)
    button.Size = UDim2.new(config.Width and 0 or 1, config.Width and -config.Width or 0, 0, buttonHeight)
    if config.Width then
        button.Size = UDim2.new(0, ScaleForDevice(config.Width), 0, buttonHeight)
    end
    button.BackgroundColor3 = tab.Container.Theme.Primary
    button.BorderSizePixel = 0
    button.Text = text
    button.TextColor3 = tab.Container.Theme.Text
    button.TextSize = ScaleForDevice(14)
    button.Font = Enum.Font.GothamSemibold
    button.AutoButtonColor = false
    button.Parent = tab.Content
    AddCorner(button, 8)
    
    -- 添加渐变效果
    if config.Gradient ~= false then
        local gradient = CreateGradient(button, tab.Container.Theme.Gradient, 180)
        gradient.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0, 0.3),
            NumberSequenceKeypoint.new(1, 0.5)
        })
    end
    
    -- 交互效果
    MakeInteractive(button, {}, tab.Container.Theme)
    
    button.MouseButton1Click:Connect(function()
        if callback then callback() end
    end)
    
    table.insert(tab.Elements, button)
    return button
end

-- 切换按钮
function Components.AddToggle(tab, text, default, callback, config)
    config = config or {}
    
    local toggleHeight = ScaleForDevice(config.Height or 35)
    local toggleSize = ScaleForDevice(24)
    
    local container = Instance.new("Frame")
    container.Name = "Toggle_" .. (#tab.Elements + 1)
    container.Size = UDim2.new(1, 0, 0, toggleHeight)
    container.BackgroundTransparency = 1
    container.Parent = tab.Content
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -toggleSize - 10, 1, 0)
    label.Position = UDim2.new(0, 0, 0, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = tab.Container.Theme.Text
    label.TextSize = ScaleForDevice(14)
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local toggleBg = Instance.new("TextButton")
    toggleBg.Name = "ToggleBackground"
    toggleBg.Size = UDim2.new(0, toggleSize, 0, toggleSize)
    toggleBg.Position = UDim2.new(1, -toggleSize, 0.5, -toggleSize/2)
    toggleBg.BackgroundColor3 = default and tab.Container.Theme.Primary or tab.Container.Theme.Surface
    toggleBg.BorderSizePixel = 0
    toggleBg.Text = ""
    toggleBg.Parent = container
    AddCorner(toggleBg, toggleSize/2)
    
    local toggleIndicator = Instance.new("Frame")
    toggleIndicator.Name = "Indicator"
    toggleIndicator.Size = UDim2.new(0, toggleSize - 8, 0, toggleSize - 8)
    toggleIndicator.Position = default and UDim2.new(1, -toggleSize + 4, 0.5, 0) or UDim2.new(0, 4, 0.5, 0)
    toggleIndicator.BackgroundColor3 = tab.Container.Theme.Text
    toggleIndicator.BorderSizePixel = 0
    toggleIndicator.Parent = toggleBg
    AddCorner(toggleIndicator, (toggleSize - 8)/2)
    
    local isOn = default or false
    
    toggleBg.MouseButton1Click:Connect(function()
        isOn = not isOn
        
        CreateTween(toggleIndicator, {
            Position = isOn and UDim2.new(1, -toggleSize + 4, 0.5, 0) or UDim2.new(0, 4, 0.5, 0),
            BackgroundColor3 = isOn and tab.Container.Theme.Text or tab.Container.Theme.TextSecondary
        }, ANIMATION_CONFIG.HoverSpeed):Play()
        
        CreateTween(toggleBg, {
            BackgroundColor3 = isOn and tab.Container.Theme.Primary or tab.Container.Theme.Surface
        }, ANIMATION_CONFIG.HoverSpeed):Play()
        
        if callback then callback(isOn) end
    end)
    
    -- 禁用状态
    function container:SetEnabled(enabled)
        toggleBg.BackgroundTransparency = enabled and 0 or 0.5
        label.TextTransparency = enabled and 0 or 0.5
    end
    
    table.insert(tab.Elements, container)
    return container
end

-- 滑块
function Components.AddSlider(tab, text, min, max, default, callback, config)
    config = config or {}
    
    local sliderHeight = ScaleForDevice(config.Height or 50)
    local sliderWidth = ScaleForDevice(200)
    local defaultValue = default or min
    
    local container = Instance.new("Frame")
    container.Name = "Slider_" .. (#tab.Elements + 1)
    container.Size = UDim2.new(1, 0, 0, sliderHeight)
    container.BackgroundTransparency = 1
    container.Parent = tab.Content
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -sliderWidth - 10, 0, 20)
    titleLabel.Position = UDim2.new(0, 0, 0, 0)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = text
    titleLabel.TextColor3 = tab.Container.Theme.Text
    titleLabel.TextSize = ScaleForDevice(14)
    titleLabel.Font = Enum.Font.Gotham
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = container
    
    local valueLabel = Instance.new("TextLabel")
    valueLabel.Name = "Value"
    valueLabel.Size = UDim2.new(0, 50, 0, 20)
    valueLabel.Position = UDim2.new(1, -50, 0, 0)
    valueLabel.BackgroundTransparency = 1
    valueLabel.Text = tostring(defaultValue)
    valueLabel.TextColor3 = tab.Container.Theme.Primary
    valueLabel.TextSize = ScaleForDevice(14)
    valueLabel.Font = Enum.Font.GothamBold
    valueLabel.TextXAlignment = Enum.TextXAlignment.Right
    valueLabel.Parent = container
    
    local sliderTrack = Instance.new("Frame")
    sliderTrack.Name = "Track"
    sliderTrack.Size = UDim2.new(0, sliderWidth, 0, 8)
    sliderTrack.Position = UDim2.new(0, 0, 0, sliderHeight - 15)
    sliderTrack.BackgroundColor3 = tab.Container.Theme.Surface
    sliderTrack.BorderSizePixel = 0
    sliderTrack.Parent = container
    AddCorner(sliderTrack, 4)
    
    local sliderFill = Instance.new("Frame")
    sliderFill.Name = "Fill"
    sliderFill.Size = UDim2.new((defaultValue - min) / (max - min), 0, 1, 0)
    sliderFill.BackgroundColor3 = tab.Container.Theme.Primary
    sliderFill.BorderSizePixel = 0
    sliderFill.Parent = sliderTrack
    AddCorner(sliderFill, 4)
    
    local sliderKnob = Instance.new("Frame")
    sliderKnob.Name = "Knob"
    sliderKnob.Size = UDim2.new(0, 18, 0, 18)
    sliderKnob.Position = UDim2.new((defaultValue - min) / (max - min), -9, 0.5, -9)
    sliderKnob.BackgroundColor3 = tab.Container.Theme.Text
    sliderKnob.BorderSizePixel = 0
    sliderKnob.Parent = sliderTrack
    AddCorner(sliderKnob, 9)
    
    -- 拖动逻辑
    local dragging = false
    
    local function updateSlider(input)
        local relativePos = (input.Position.X - sliderTrack.AbsolutePosition.X) / sliderTrack.AbsoluteSize.X
        relativePos = math.clamp(relativePos, 0, 1)
        
        local value = math.floor(min + (max - min) * relativePos)
        
        sliderFill.Size = UDim2.new(relativePos, 0, 1, 0)
        sliderKnob.Position = UDim2.new(relativePos, -9, 0.5, -9)
        valueLabel.Text = tostring(value)
        
        if callback then callback(value) end
    end
    
    sliderTrack.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateSlider(input)
        end
    end)
    
    sliderTrack.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or 
           input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if dragging then
            if input.UserInputType == Enum.UserInputType.MouseMovement or 
               input.UserInputType == Enum.UserInputType.Touch then
                updateSlider(input)
            end
        end
    end)
    
    table.insert(tab.Elements, container)
    return container
end

-- 输入框
function Components.AddTextBox(tab, label, placeholder, callback, config)
    config = config or {}
    
    local inputHeight = ScaleForDevice(config.Height or 40)
    
    local container = Instance.new("Frame")
    container.Name = "TextBox_" .. (#tab.Elements + 1)
    container.Size = UDim2.new(1, 0, 0, inputHeight + (label and 25 or 0))
    container.BackgroundTransparency = 1
    container.Parent = tab.Content
    
    if label then
        local titleLabel = Instance.new("TextLabel")
        titleLabel.Name = "Label"
        titleLabel.Size = UDim2.new(1, 0, 0, 20)
        titleLabel.BackgroundTransparency = 1
        titleLabel.Text = label
        titleLabel.TextColor3 = tab.Container.Theme.Text
        titleLabel.TextSize = ScaleForDevice(12)
        titleLabel.Font = Enum.Font.GothamMedium
        titleLabel.TextXAlignment = Enum.TextXAlignment.Left
        titleLabel.Parent = container
    end
    
    local inputBox = Instance.new("TextBox")
    inputBox.Name = "Input"
    inputBox.Size = UDim2.new(1, 0, 0, inputHeight)
    inputBox.Position = label and UDim2.new(0, 0, 0, 25) or UDim2.new(0, 0, 0, 0)
    inputBox.BackgroundColor3 = tab.Container.Theme.Surface
    inputBox.BorderSizePixel = 0
    inputBox.Text = ""
    inputBox.PlaceholderText = placeholder or ""
    inputBox.PlaceholderColor3 = tab.Container.Theme.TextSecondary
    inputBox.TextColor3 = tab.Container.Theme.Text
    inputBox.TextSize = ScaleForDevice(14)
    inputBox.Font = Enum.Font.Gotham
    inputBox.TextXAlignment = Enum.TextXAlignment.Left
    inputBox.ClearTextOnFocus = config.ClearOnFocus ~= false
    inputBox.Parent = container
    AddCorner(inputBox, 8)
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 12)
    padding.Parent = inputBox
    
    inputBox.FocusLost:Connect(function(enterPressed)
        if callback then callback(inputBox.Text, enterPressed) end
    end)
    
    table.insert(tab.Elements, container)
    return container
end

-- 下拉菜单
function Components.AddDropdown(tab, text, options, default, callback, config)
    config = config or {}
    
    local dropdownHeight = ScaleForDevice(config.Height or 40)
    local maxVisibleItems = config.MaxVisibleItems or 5
    
    local container = Instance.new("Frame")
    container.Name = "Dropdown_" .. (#tab.Elements + 1)
    container.Size = UDim2.new(1, 0, 0, dropdownHeight + 25)
    container.BackgroundTransparency = 1
    container.Parent = tab.Content
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 20)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = text
    titleLabel.TextColor3 = tab.Container.Theme.Text
    titleLabel.TextSize = ScaleForDevice(12)
    titleLabel.Font = Enum.Font.GothamMedium
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = container
    
    local dropdownBtn = Instance.new("TextButton")
    dropdownBtn.Name = "DropdownButton"
    dropdownBtn.Size = UDim2.new(1, 0, 0, dropdownHeight)
    dropdownBtn.Position = UDim2.new(0, 0, 0, 25)
    dropdownBtn.BackgroundColor3 = tab.Container.Theme.Surface
    dropdownBtn.BorderSizePixel = 0
    dropdownBtn.Text = default or options[1] or "选择..."
    dropdownBtn.TextColor3 = tab.Container.Theme.Text
    dropdownBtn.TextSize = ScaleForDevice(14)
    dropdownBtn.Font = Enum.Font.Gotham
    dropdownBtn.TextXAlignment = Enum.TextXAlignment.Left
    dropdownBtn.Parent = container
    AddCorner(dropdownBtn, 8)
    
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, 12)
    padding.PaddingRight = UDim.new(0, 30)
    padding.Parent = dropdownBtn
    
    local arrow = Instance.new("TextLabel")
    arrow.Name = "Arrow"
    arrow.Size = UDim2.new(0, 20, 0, 20)
    arrow.Position = UDim2.new(1, -25, 0.5, -10)
    arrow.BackgroundTransparency = 1
    arrow.Text = "▼"
    arrow.TextColor3 = tab.Container.Theme.TextSecondary
    arrow.TextSize = ScaleForDevice(10)
    arrow.Font = Enum.Font.Gotham
    arrow.Parent = dropdownBtn
    
    local dropdownMenu = Instance.new("Frame")
    dropdownMenu.Name = "Menu"
    dropdownMenu.Size = UDim2.new(1, 0, 0, 0)
    dropdownMenu.Position = UDim2.new(0, 0, 0, dropdownHeight + 30)
    dropdownMenu.BackgroundColor3 = tab.Container.Theme.Surface
    dropdownMenu.BorderSizePixel = 0
    dropdownMenu.ClipsDescendants = true
    dropdownMenu.Visible = false
    dropdownMenu.Parent = container
    AddCorner(dropdownMenu, 8)
    AddStroke(dropdownMenu, tab.Container.Theme.Border, 1)
    
    local menuLayout = Instance.new("UIListLayout")
    menuLayout.Padding = UDim.new(0, 2)
    menuLayout.Parent = dropdownMenu
    
    local isOpen = false
    local currentSelection = default or nil
    
    dropdownBtn.MouseButton1Click:Connect(function()
        isOpen = not isOpen
        
        CreateTween(arrow, {Rotation = isOpen and 180 or 0}, ANIMATION_CONFIG.HoverSpeed):Play()
        
        if isOpen then
            local itemHeight = ScaleForDevice(32)
            local menuHeight = math.min(#options, maxVisibleItems) * itemHeight
            dropdownMenu.Size = UDim2.new(1, 0, 0, 0)
            dropdownMenu.Visible = true
            CreateTween(dropdownMenu, {Size = UDim2.new(1, 0, 0, menuHeight)}, ANIMATION_CONFIG.SpringStyle):Play()
        else
            CreateTween(dropdownMenu, {Size = UDim2.new(1, 0, 0, 0)}, ANIMATION_CONFIG.SmoothStyle):Play()
            task.delay(ANIMATION_CONFIG.CloseSpeed, function()
                dropdownMenu.Visible = false
            end)
        end
    end)
    
    for _, option in ipairs(options) do
        local item = Instance.new("TextButton")
        item.Name = "Item_" .. option
        item.Size = UDim2.new(1, 0, 0, ScaleForDevice(32))
        item.BackgroundTransparency = 1
        item.Text = option
        item.TextColor3 = tab.Container.Theme.Text
        item.TextSize = ScaleForDevice(13)
        item.Font = Enum.Font.Gotham
        item.TextXAlignment = Enum.TextXAlignment.Left
        item.Parent = dropdownMenu
        
        local itemPadding = Instance.new("UIPadding")
        itemPadding.PaddingLeft = UDim.new(0, 12)
        itemPadding.Parent = item
        
        item.MouseButton1Click:Connect(function()
            currentSelection = option
            dropdownBtn.Text = option
            
            if callback then callback(option) end
            
            isOpen = false
            CreateTween(arrow, {Rotation = 0}, ANIMATION_CONFIG.HoverSpeed):Play()
            CreateTween(dropdownMenu, {Size = UDim2.new(1, 0, 0, 0)}, ANIMATION_CONFIG.SmoothStyle):Play()
            task.delay(ANIMATION_CONFIG.CloseSpeed, function()
                dropdownMenu.Visible = false
            end)
        end)
        
        item.MouseEnter:Connect(function()
            item.BackgroundColor3 = tab.Container.Theme.Primary
            item.BackgroundTransparency = 0.7
        end)
        
        item.MouseLeave:Connect(function()
            item.BackgroundColor3 = tab.Container.Theme.Surface
            item.BackgroundTransparency = 1
        end)
    end
    
    table.insert(tab.Elements, container)
    return container
end

-- 分隔线
function Components.AddSeparator(tab, config)
    config = config or {}
    
    local separator = Instance.new("Frame")
    separator.Name = "Separator_" .. (#tab.Elements + 1)
    separator.Size = UDim2.new(1, 0, 0, config.Height or 20)
    separator.BackgroundTransparency = 1
    separator.Parent = tab.Content
    
    local line = Instance.new("Frame")
    line.Name = "Line"
    line.Size = UDim2.new(1, 0, 0, 1)
    line.Position = UDim2.new(0, 0, 0.5, 0)
    line.BackgroundColor3 = tab.Container.Theme.Border
    line.BackgroundTransparency = 0.3
    line.Parent = separator
    
    table.insert(tab.Elements, separator)
    return separator
end

-- 分组框
function Components.AddGroup(tab, title, config)
    config = config or {}
    
    local groupHeight = ScaleForDevice(config.Height or 200)
    
    local group = Instance.new("Frame")
    group.Name = "Group_" .. (#tab.Elements + 1)
    group.Size = UDim2.new(1, 0, 0, groupHeight + 30)
    group.BackgroundColor3 = tab.Container.Theme.Surface
    group.BackgroundTransparency = 0.3
    group.BorderSizePixel = 0
    group.Parent = tab.Content
    AddCorner(group, 10)
    AddStroke(group, tab.Container.Theme.Border, 1)
    
    local groupTitle = Instance.new("TextLabel")
    groupTitle.Name = "Title"
    groupTitle.Size = UDim2.new(1, -20, 0, 25)
    groupTitle.Position = UDim2.new(0, 10, 0, 5)
    groupTitle.BackgroundTransparency = 1
    groupTitle.Text = title or "分组"
    groupTitle.TextColor3 = tab.Container.Theme.Primary
    groupTitle.TextSize = ScaleForDevice(13)
    groupTitle.Font = Enum.Font.GothamSemibold
    groupTitle.TextXAlignment = Enum.TextXAlignment.Left
    groupTitle.Parent = group
    
    local groupContent = Instance.new("Frame")
    groupContent.Name = "Content"
    groupContent.Size = UDim2.new(1, -20, 1, -40)
    groupContent.Position = UDim2.new(0, 10, 0, 30)
    groupContent.BackgroundTransparency = 1
    groupContent.Parent = group
    
    local groupContainer = ContainerManager.new(groupContent, tab.Container.Theme)
    
    -- 添加方法以在组内添加元素
    group.AddLabel = function(text, cfg) return Components.AddLabel({Content = groupContent, Elements = {}, Container = groupContainer}, text, cfg) end
    group.AddButton = function(text, cb, cfg) return Components.AddButton({Content = groupContent, Elements = {}, Container = groupContainer}, text, cb, cfg) end
    group.AddToggle = function(text, def, cb, cfg) return Components.AddToggle({Content = groupContent, Elements = {}, Container = groupContainer}, text, def, cb, cfg) end
    group.AddSlider = function(text, min, max, def, cb, cfg) return Components.AddSlider({Content = groupContent, Elements = {}, Container = groupContainer}, text, min, max, def, cb, cfg) end
    
    table.insert(tab.Elements, group)
    return group
end

-- 颜色选择器
function Components.AddColorPicker(tab, text, default, callback, config)
    config = config or {}
    
    local pickerHeight = ScaleForDevice(config.Height or 45)
    
    local container = Instance.new("Frame")
    container.Name = "ColorPicker_" .. (#tab.Elements + 1)
    container.Size = UDim2.new(1, 0, 0, pickerHeight)
    container.BackgroundTransparency = 1
    container.Parent = tab.Content
    
    local label = Instance.new("TextLabel")
    label.Name = "Label"
    label.Size = UDim2.new(1, -60, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = text
    label.TextColor3 = tab.Container.Theme.Text
    label.TextSize = ScaleForDevice(14)
    label.Font = Enum.Font.Gotham
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.Parent = container
    
    local colorPreview = Instance.new("TextButton")
    colorPreview.Name = "ColorPreview"
    colorPreview.Size = UDim2.new(0, ScaleForDevice(35), 0, ScaleForDevice(25))
    colorPreview.Position = UDim2.new(1, -40, 0.5, -12)
    colorPreview.BackgroundColor3 = default or tab.Container.Theme.Primary
    colorPreview.BorderSizePixel = 0
    colorPreview.Text = ""
    colorPreview.Parent = container
    AddCorner(colorPreview, 4)
    AddStroke(colorPreview, tab.Container.Theme.Border, 1)
    
    colorPreview.MouseButton1Click:Connect(function()
        -- 简化版：循环预设颜色
        local colors = {
            Color3.fromRGB(255, 80, 80),   -- 红
            Color3.fromRGB(255, 165, 0),   -- 橙
            Color3.fromRGB(255, 255, 0),   -- 黄
            Color3.fromRGB(0, 255, 0),     -- 绿
            Color3.fromRGB(0, 170, 255),   -- 蓝
            Color3.fromRGB(147, 112, 219), -- 紫
            Color3.fromRGB(255, 255, 255), -- 白
            Color3.fromRGB(50, 50, 50)     -- 黑
        }
        
        local currentIndex = 1
        for i, c in ipairs(colors) do
            if c == colorPreview.BackgroundColor3 then
                currentIndex = i
                break
            end
        end
        
        local nextIndex = (currentIndex % #colors) + 1
        CreateTween(colorPreview, {BackgroundColor3 = colors[nextIndex]}, ANIMATION_CONFIG.HoverSpeed):Play()
        
        if callback then callback(colors[nextIndex]) end
    end)
    
    table.insert(tab.Elements, container)
    return container
end

-- 进度条
function Components.AddProgressBar(tab, text, value, config)
    config = config or {}
    
    local barHeight = ScaleForDevice(config.Height or 25)
    
    local container = Instance.new("Frame")
    container.Name = "ProgressBar_" .. (#tab.Elements + 1)
    container.Size = UDim2.new(1, 0, 0, barHeight)
    container.BackgroundTransparency = 1
    container.Parent = tab.Content
    
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, -50, 0, 16)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = text or ""
    titleLabel.TextColor3 = tab.Container.Theme.Text
    titleLabel.TextSize = ScaleForDevice(12)
    titleLabel.Font = Enum.Font.Gotham
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.Parent = container
    
    local percentLabel = Instance.new("TextLabel")
    percentLabel.Name = "Percent"
    percentLabel.Size = UDim2.new(0, 45, 0, 16)
    percentLabel.Position = UDim2.new(1, -50, 0, 0)
    percentLabel.BackgroundTransparency = 1
    percentLabel.Text = math.floor((value or 0) * 100) .. "%"
    percentLabel.TextColor3 = tab.Container.Theme.Primary
    percentLabel.TextSize = ScaleForDevice(12)
    percentLabel.Font = Enum.Font.GothamBold
    percentLabel.TextXAlignment = Enum.TextXAlignment.Right
    percentLabel.Parent = container
    
    local track = Instance.new("Frame")
    track.Name = "Track"
    track.Size = UDim2.new(1, 0, 0, 6)
    track.Position = UDim2.new(0, 0, 0, barHeight - 8)
    track.BackgroundColor3 = tab.Container.Theme.Surface
    track.BorderSizePixel = 0
    track.Parent = container
    AddCorner(track, 3)
    
    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(value or 0, 0, 1, 0)
    fill.BackgroundColor3 = tab.Container.Theme.Primary
    fill.BorderSizePixel = 0
    fill.Parent = track
    AddCorner(fill, 3)
    
    -- 更新进度方法
    function container:SetValue(val)
        val = math.clamp(val, 0, 1)
        CreateTween(fill, {Size = UDim2.new(val, 0, 1, 0)}, ANIMATION_CONFIG.SmoothStyle):Play()
        percentLabel.Text = math.floor(val * 100) .. "%"
    end
    
    table.insert(tab.Elements, container)
    return container
end

-- 添加所有组件方法到Tab
local TabMT = {
    AddLabel = Components.AddLabel,
    AddTitle = Components.AddTitle,
    AddButton = Components.AddButton,
    AddToggle = Components.AddToggle,
    AddSlider = Components.AddSlider,
    AddTextBox = Components.AddTextBox,
    AddDropdown = Components.AddDropdown,
    AddSeparator = Components.AddSeparator,
    AddGroup = Components.AddGroup,
    AddColorPicker = Components.AddColorPicker,
    AddProgressBar = Components.AddProgressBar
}

-- 将组件方法应用到Tab元表
setmetatable(OceanUI.CreateWindow({}).AddTab, {__index = TabMT})

-- 修正AddTab方法以返回带组件方法的Tab
local originalAddTab = OceanUI.CreateWindow({}).AddTab
OceanUI.CreateWindow = setmetatable({}, {
    __call = function(self, config)
        local Window = {}
        
        -- 简化版窗口创建逻辑
        local width, height = GetResponsiveSize(config.Width or 500, config.Height or 400)
        local screenX, screenY = GetScreenSize()
        local position = UDim2.new(0.5, -width/2, 0.5, -height/2)
        local theme = THEMES[config.Theme] or THEMES.Ocean
        
        local WindowFrame = Instance.new("Frame")
        WindowFrame.Name = "OceanUI_Window"
        WindowFrame.Size = UDim2.new(0, width, 0, height)
        WindowFrame.Position = position
        WindowFrame.BackgroundColor3 = theme.Background
        WindowFrame.BorderSizePixel = 0
        WindowFrame.ZIndex = 10
        WindowFrame.Visible = false
        WindowFrame.Parent = PlayerGui
        
        AddCorner(WindowFrame, config.CornerRadius or 12)
        if config.EnableShadow ~= false then CreateShadow(WindowFrame) end
        if config.EnableGlow ~= false then CreateGlow(WindowFrame, theme.Primary) end
        AddStroke(WindowFrame, theme.Border, 1)
        
        Window.Instance = WindowFrame
        Window.Theme = theme
        Window.Tabs = {}
        Window.IsVisible = false
        
        function Window:AddTab(name, icon)
            local tabButton = Instance.new("TextButton")
            tabButton.Size = UDim2.new(0, icon and 110 or 90, 0, 35)
            tabButton.BackgroundColor3 = theme.Surface
            tabButton.BackgroundTransparency = 0.5
            tabButton.Text = icon and (icon .. " " .. name) or name
            tabButton.TextColor3 = theme.TextSecondary
            tabButton.TextSize = ScaleForDevice(14)
            tabButton.Font = Enum.Font.GothamMedium
            tabButton.Parent = WindowFrame
            AddCorner(tabButton, 8)
            
            local tabContent = Instance.new("Frame")
            tabContent.Size = UDim2.new(1, 0, 1, -50)
            tabContent.Position = UDim2.new(0, 0, 0, 50)
            tabContent.BackgroundTransparency = 1
            tabContent.Visible = false
            tabContent.Parent = WindowFrame
            
            local tab = setmetatable({
                Name = name,
                Button = tabButton,
                Content = tabContent,
                Container = ContainerManager.new(tabContent, theme),
                Elements = {}
            }, {__index = TabMT})
            
            tabButton.MouseButton1Click:Connect(function()
                for _, t in ipairs(Window.Tabs) do
                    t.Content.Visible = (t == tab)
                    t.Button.BackgroundColor3 = (t == tab) and theme.Primary or theme.Surface
                    t.Button.BackgroundTransparency = (t == tab) and 0.2 or 0.5
                    t.Button.TextColor3 = (t == tab) and theme.Text or theme.TextSecondary
                end
            end)
            
            table.insert(Window.Tabs, tab)
            
            if #Window.Tabs == 1 then
                tab.Content.Visible = true
                tabButton.BackgroundColor3 = theme.Primary
                tabButton.BackgroundTransparency = 0.2
                tabButton.TextColor3 = theme.Text
            end
            
            return tab
        end
        
        function Window:Show()
            if not Window.IsVisible then
                WindowFrame.Visible = true
                WindowFrame.Size = UDim2.new(0, 0, 0, 0)
                WindowFrame:TweenSize(UDim2.new(0, width, 0, height), ANIMATION_CONFIG.SpringStyle)
                Window.IsVisible = true
            end
        end
        
        function Window:Hide()
            if Window.IsVisible then
                WindowFrame:TweenSize(UDim2.new(0, 0, 0, 0), ANIMATION_CONFIG.SmoothStyle)
                task.delay(ANIMATION_CONFIG.CloseSpeed, function()
                    WindowFrame.Visible = false
                end)
                Window.IsVisible = false
            end
        end
        
        function Window:Toggle()
            if Window.IsVisible then self:Hide() else self:Show() end
        end
        
        function Window:MakeDraggable()
            local dragging, dragStart, startPos
            
            WindowFrame.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or 
                   input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    dragStart = input.Position
                    startPos = WindowFrame.Position
                end
            end)
            
            WindowFrame.InputEnded:Connect(function(input)
                dragging = false
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging then
                    local delta = input.Position - dragStart
                    WindowFrame.Position = UDim2.new(
                        startPos.X.Scale, startPos.X.Offset + delta.X * 0.5,
                        startPos.Y.Scale, startPos.Y.Offset + delta.Y * 0.5
                    )
                end
            end)
        end
        
        return Window
    end
})

-- ═══════════════════════════════════════════════════════════════
--                    提示框系统
-- ═══════════════════════════════════════════════════════════════

function OceanUI.Notify(message, config)
    config = config or {}
    local theme = THEMES[config.Theme] or THEMES.Ocean
    local duration = config.Duration or 3
    
    local notifyFrame = Instance.new("Frame")
    notifyFrame.Size = UDim2.new(0, ScaleForDevice(300), 0, ScaleForDevice(60))
    notifyFrame.Position = UDim2.new(0.5, -150, 0, -100)
    notifyFrame.BackgroundColor3 = theme.Surface
    notifyFrame.BorderSizePixel = 0
    notifyFrame.ZIndex = 100
    notifyFrame.Parent = PlayerGui
    AddCorner(notifyFrame, 12)
    
    if config.EnableShadow ~= false then
        CreateShadow(notifyFrame)
    end
    
    local accentBar = Instance.new("Frame")
    accentBar.Size = UDim2.new(1, 0, 0, 3)
    accentBar.Position = UDim2.new(0, 0, 0, 0)
    accentBar.BackgroundColor3 = config.Type == "Error" and theme.Error or 
                                  config.Type == "Success" and theme.Success or 
                                  config.Type == "Warning" and theme.Warning or 
                                  theme.Primary
    accentBar.BorderSizePixel = 0
    accentBar.Parent = notifyFrame
    
    local iconLabel = Instance.new("TextLabel")
    iconLabel.Size = UDim2.new(0, 30, 1, 0)
    iconLabel.Position = UDim2.new(0, 10, 0, 0)
    iconLabel.BackgroundTransparency = 1
    iconLabel.Text = config.Type == "Error" and "✕" or 
                      config.Type == "Success" and "✓" or 
                      config.Type == "Warning" and "⚠" or "ℹ"
    iconLabel.TextColor3 = config.Type == "Error" and theme.Error or 
                           config.Type == "Success" and theme.Success or 
                           config.Type == "Warning" and theme.Warning or 
                           theme.Primary
    iconLabel.TextSize = 20
    iconLabel.Font = Enum.Font.GothamBold
    iconLabel.Parent = notifyFrame
    
    local messageLabel = Instance.new("TextLabel")
    messageLabel.Size = UDim2.new(1, -50, 1, -10)
    messageLabel.Position = UDim2.new(0, 45, 0, 5)
    messageLabel.BackgroundTransparency = 1
    messageLabel.Text = message
    messageLabel.TextColor3 = theme.Text
    messageLabel.TextSize = ScaleForDevice(14)
    messageLabel.Font = Enum.Font.Gotham
    messageLabel.TextWrapped = true
    messageLabel.TextXAlignment = Enum.TextXAlignment.Left
    messageLabel.Parent = notifyFrame
    
    -- 动画
    notifyFrame:TweenPosition(UDim2.new(0.5, -150, 0, 20), ANIMATION_CONFIG.SpringStyle)
    
    task.delay(duration, function()
        notifyFrame:TweenPosition(UDim2.new(0.5, -150, 0, -100), ANIMATION_CONFIG.SmoothStyle)
        task.delay(ANIMATION_CONFIG.CloseSpeed, function()
            notifyFrame:Destroy()
        end)
    end)
    
    return notifyFrame
end

-- ═══════════════════════════════════════════════════════════════
--                    对话框系统
-- ═══════════════════════════════════════════════════════════════

function OceanUI.Dialog(config)
    return OceanUI.CreateWindow({
        Title = config.Title or "提示",
        Width = config.Width or 400,
        Height = config.Height or 200,
        Theme = config.Theme,
        EnableShadow = true,
        EnableGlow = true,
        ShowCloseButton = false,
        ShowMinimizeButton = false,
        ShowMaximizeButton = false
    })
end

-- ═══════════════════════════════════════════════════════════════
--                    版本信息
-- ═══════════════════════════════════════════════════════════════

OceanUI.Version = "1.0.0"
OceanUI.Author = "Ocean"

return OceanUI
