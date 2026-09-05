--[[
    ╔═══════════════════════════════════════════════════════════════╗
    ║                    OceanUI Library v2.0                        ║
    ║           高质量现代化UI库 | 适配移动端&PC端                   ║
    ║                      by Ocean                                 ║
    ╚═══════════════════════════════════════════════════════════════╝
]]

local OceanUI = {}

-- 服务
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Player = Players.LocalPlayer
local PlayerGui = Player:WaitForChild("PlayerGui")

-- ═══════════════════════════════════════════════════════════════
--                    主题配置
-- ═══════════════════════════════════════════════════════════════

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
        Error = Color3.fromRGB(255, 80, 80)
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
        Error = Color3.fromRGB(255, 80, 80)
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
        Error = Color3.fromRGB(255, 80, 80)
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
        Error = Color3.fromRGB(255, 80, 80)
    }
}

-- 动画
local TWEEN = {
    Smooth = TweenInfo.new(0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
    Spring = TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
    Fast = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
}

-- ═══════════════════════════════════════════════════════════════
--                    工具函数
-- ═══════════════════════════════════════════════════════════════

local function Tween(obj, props, tweenInfo)
    local t = TweenService:Create(obj, tweenInfo or TWEEN.Smooth, props)
    t:Play()
    return t
end

local function AddCorner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius)
    c.Parent = parent
    return c
end

local function AddStroke(parent, color, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color or Color3.fromRGB(80, 90, 120)
    s.Thickness = thickness or 1
    s.Transparency = 0.5
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function AddPadding(parent, top, bottom, left, right)
    local p = Instance.new("UIPadding")
    p.PaddingTop = UDim.new(0, top or 0)
    p.PaddingBottom = UDim.new(0, bottom or 0)
    p.PaddingLeft = UDim.new(0, left or 0)
    p.PaddingRight = UDim.new(0, right or 0)
    p.Parent = parent
    return p
end

local function IsMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function Scale(value)
    if IsMobile() then
        return value * 0.85
    end
    return value
end

local function GetTheme(name)
    return THEMES[name] or THEMES.Ocean
end

-- 按钮悬停效果
local function SetupButtonHover(button, theme, defaultColor)
    local origColor = defaultColor or button.BackgroundColor3
    button.MouseEnter:Connect(function()
        Tween(button, {BackgroundColor3 = origColor:Lerp(theme.Accent, 0.2)})
    end)
    button.MouseLeave:Connect(function()
        Tween(button, {BackgroundColor3 = origColor})
    end)
    button.MouseButton1Down:Connect(function()
        Tween(button, {Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset - 2, button.Size.Y.Scale, button.Size.Y.Offset - 2)}, TWEEN.Fast)
    end)
    button.MouseButton1Up:Connect(function()
        Tween(button, {Size = UDim2.new(button.Size.X.Scale, button.Size.X.Offset + 2, button.Size.Y.Scale, button.Size.Y.Offset + 2)}, TWEEN.Fast)
    end)
end

-- ═══════════════════════════════════════════════════════════════
--                    通知系统
-- ═══════════════════════════════════════════════════════════════

function OceanUI.Notify(message, config)
    config = config or {}
    local theme = GetTheme(config.Theme)
    local duration = config.Duration or 3
    
    local notify = Instance.new("Frame")
    notify.Size = UDim2.new(0, Scale(320), 0, Scale(70))
    notify.Position = UDim2.new(0.5, -Scale(160), 0, -100)
    notify.BackgroundColor3 = theme.Surface
    notify.BorderSizePixel = 0
    notify.ZIndex = 100
    notify.Parent = PlayerGui
    AddCorner(notify, 12)
    AddStroke(notify, theme.Border, 1)
    
    -- 阴影
    local shadow = Instance.new("ImageLabel")
    shadow.Size = UDim2.new(1, 30, 1, 30)
    shadow.Position = UDim2.new(0, -15, 0, -15)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://5554236805"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.5
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    shadow.ZIndex = 99
    shadow.Parent = notify
    
    -- 颜色条
    local accent = Instance.new("Frame")
    accent.Size = UDim2.new(1, 0, 0, 4)
    accent.BackgroundColor3 = config.Type == "Error" and theme.Error or
                               config.Type == "Success" and theme.Success or
                               config.Type == "Warning" and theme.Warning or
                               theme.Primary
    accent.BorderSizePixel = 0
    accent.ZIndex = 101
    accent.Parent = notify
    AddCorner(accent, 2)
    
    -- 图标
    local icon = Instance.new("TextLabel")
    icon.Size = UDim2.new(0, 30, 0, 30)
    icon.Position = UDim2.new(0, 15, 0, 22)
    icon.BackgroundTransparency = 1
    icon.Text = config.Type == "Error" and "✕" or 
                config.Type == "Success" and "✓" or 
                config.Type == "Warning" and "⚠" or "i"
    icon.TextColor3 = accent.BackgroundColor3
    icon.TextSize = 22
    icon.Font = Enum.Font.GothamBold
    icon.ZIndex = 101
    icon.Parent = notify
    
    -- 消息
    local msg = Instance.new("TextLabel")
    msg.Size = UDim2.new(1, -65, 1, -20)
    msg.Position = UDim2.new(0, 55, 0, 20)
    msg.BackgroundTransparency = 1
    msg.Text = message
    msg.TextColor3 = theme.Text
    msg.TextSize = Scale(14)
    msg.Font = Enum.Font.Gotham
    msg.TextWrapped = true
    msg.TextXAlignment = Enum.TextXAlignment.Left
    msg.TextYAlignment = Enum.TextYAlignment.Top
    msg.ZIndex = 101
    msg.Parent = notify
    
    -- 动画
    Tween(notify, {Position = UDim2.new(0.5, -Scale(160), 0, 20)}, TWEEN.Spring)
    
    task.delay(duration, function()
        Tween(notify, {Position = UDim2.new(0.5, -Scale(160), 0, -100)}, TWEEN.Smooth)
        task.wait(0.3)
        notify:Destroy()
    end)
end

-- ═══════════════════════════════════════════════════════════════
--                    主窗口创建
-- ═══════════════════════════════════════════════════════════════

function OceanUI.CreateWindow(config)
    config = config or {}
    local theme = GetTheme(config.Theme)
    local width = Scale(config.Width or 550)
    local height = Scale(config.Height or 400)
    
    -- 主ScreenGui
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "OceanUI_" .. (config.Title or "Window")
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.DisplayOrder = 100
    ScreenGui.Parent = PlayerGui
    
    -- 窗口框架
    local Frame = Instance.new("Frame")
    Frame.Name = "MainFrame"
    Frame.Size = UDim2.new(0, width, 0, height)
    Frame.Position = UDim2.new(0.5, -width/2, 0.5, -height/2)
    Frame.BackgroundColor3 = theme.Background
    Frame.BorderSizePixel = 0
    Frame.Visible = false
    Frame.Parent = ScreenGui
    AddCorner(Frame, config.CornerRadius or 12)
    
    -- 阴影
    local shadow = Instance.new("ImageLabel")
    shadow.Name = "Shadow"
    shadow.Size = UDim2.new(1, 40, 1, 40)
    shadow.Position = UDim2.new(0, -20, 0, -20)
    shadow.BackgroundTransparency = 1
    shadow.Image = "rbxassetid://5554236805"
    shadow.ImageColor3 = Color3.new(0, 0, 0)
    shadow.ImageTransparency = 0.4
    shadow.ScaleType = Enum.ScaleType.Slice
    shadow.SliceCenter = Rect.new(23, 23, 277, 277)
    shadow.ZIndex = 0
    shadow.Parent = Frame
    
    -- 发光
    if config.EnableGlow ~= false then
        local glow = Instance.new("ImageLabel")
        glow.Name = "Glow"
        glow.Size = UDim2.new(1, 20, 1, 20)
        glow.Position = UDim2.new(0, -10, 0, -10)
        glow.BackgroundTransparency = 1
        glow.Image = "rbxassetid://4487654331"
        glow.ImageColor3 = theme.Primary
        glow.ImageTransparency = 0.6
        glow.ScaleType = Enum.ScaleType.Slice
        glow.SliceCenter = Rect.new(10, 10, 490, 490)
        glow.ZIndex = 1
        glow.Parent = Frame
    end
    
    -- 边框
    AddStroke(Frame, theme.Border, 1)
    
    -- 头部
    local Header = Instance.new("Frame")
    Header.Name = "Header"
    Header.Size = UDim2.new(1, 0, 0, Scale(45))
    Header.BackgroundColor3 = theme.Surface
    Header.BorderSizePixel = 0
    Header.ZIndex = 5
    Header.Parent = Frame
    AddCorner(Header, 12)
    
    -- 头部渐变条
    local HeaderLine = Instance.new("Frame")
    HeaderLine.Size = UDim2.new(1, 0, 0, 2)
    HeaderLine.BackgroundColor3 = theme.Primary
    HeaderLine.BorderSizePixel = 0
    HeaderLine.ZIndex = 6
    HeaderLine.Parent = Header
    
    -- 标题
    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -80, 1, 0)
    Title.Position = UDim2.new(0, 15, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = config.Title or "Ocean UI"
    Title.TextColor3 = theme.Text
    Title.TextSize = Scale(18)
    Title.Font = Enum.Font.GothamBold
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.ZIndex = 6
    Title.Parent = Header
    
    -- 关闭按钮
    if config.ShowCloseButton ~= false then
        local closeBtn = Instance.new("TextButton")
        closeBtn.Size = UDim2.new(0, 26, 0, 26)
        closeBtn.Position = UDim2.new(1, -35, 0.5, -13)
        closeBtn.BackgroundColor3 = theme.Error
        closeBtn.BackgroundTransparency = 0.3
        closeBtn.BorderSizePixel = 0
        closeBtn.Text = "X"
        closeBtn.TextColor3 = theme.Text
        closeBtn.TextSize = 14
        closeBtn.Font = Enum.Font.GothamBold
        closeBtn.AutoButtonColor = false
        closeBtn.ZIndex = 7
        closeBtn.Parent = Header
        AddCorner(closeBtn, 6)
        SetupButtonHover(closeBtn, theme, theme.Error)
        closeBtn.MouseButton1Click:Connect(function()
            Tween(Frame, {Size = UDim2.new(0, 0, 0, 0)}, TWEEN.Smooth)
            task.wait(0.3)
            Frame.Visible = false
        end)
    end
    
    -- 标签页容器
    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(1, -20, 0, Scale(40))
    TabContainer.Position = UDim2.new(0, 10, 0, Scale(50))
    TabContainer.BackgroundColor3 = theme.Surface
    TabContainer.BackgroundTransparency = 0.5
    TabContainer.BorderSizePixel = 0
    TabContainer.ScrollBarThickness = 0
    TabContainer.ScrollingDirection = Enum.ScrollingDirection.X
    TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabContainer.AutomaticCanvasSize = Enum.AutomaticSize.X
    TabContainer.ZIndex = 5
    TabContainer.Parent = Frame
    AddCorner(TabContainer, 8)
    
    local TabLayout = Instance.new("UIListLayout")
    TabLayout.FillDirection = Enum.FillDirection.Horizontal
    TabLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
    TabLayout.VerticalAlignment = Enum.VerticalAlignment.Center
    TabLayout.Padding = UDim.new(0, 5)
    TabLayout.Parent = TabContainer
    AddPadding(TabContainer, 4, 4, 6, 6)
    
    -- 内容滚动区域
    local Content = Instance.new("ScrollingFrame")
    Content.Name = "Content"
    Content.Size = UDim2.new(1, -20, 1, -Scale(100))
    Content.Position = UDim2.new(0, 10, 0, Scale(95))
    Content.BackgroundTransparency = 1
    Content.BorderSizePixel = 0
    Content.ScrollBarThickness = 4
    Content.ScrollBarImageColor3 = theme.Primary
    Content.ScrollBarImageTransparency = 0.5
    Content.CanvasSize = UDim2.new(0, 0, 0, 0)
    Content.AutomaticCanvasSize = Enum.AutomaticSize.Y
    Content.ZIndex = 5
    Content.Parent = Frame
    
    local ContentLayout = Instance.new("UIListLayout")
    ContentLayout.Padding = UDim.new(0, 8)
    ContentLayout.Parent = Content
    AddPadding(Content, 5, 5, 0, 0)
    
    -- 窗口对象
    local WindowObj = {}
    WindowObj.ScreenGui = ScreenGui
    WindowObj.Frame = Frame
    WindowObj.Header = Header
    WindowObj.Title = Title
    WindowObj.TabContainer = TabContainer
    WindowObj.Content = Content
    WindowObj.Theme = theme
    WindowObj.Tabs = {}
    WindowObj.CurrentTab = nil
    WindowObj.IsVisible = false
    
    -- 显示/隐藏
    function WindowObj:Show()
        if not self.IsVisible then
            Frame.Visible = true
            Frame.Size = UDim2.new(0, 0, 0, 0)
            Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
            Tween(Frame, {
                Size = UDim2.new(0, width, 0, height),
                Position = UDim2.new(0.5, -width/2, 0.5, -height/2)
            }, TWEEN.Spring)
            self.IsVisible = true
        end
    end
    
    function WindowObj:Hide()
        if self.IsVisible then
            Tween(Frame, {
                Size = UDim2.new(0, 0, 0, 0),
                Position = UDim2.new(0.5, 0, 0.5, 0)
            }, TWEEN.Smooth)
            task.wait(0.3)
            Frame.Visible = false
            self.IsVisible = false
        end
    end
    
    function WindowObj:Toggle()
        if self.IsVisible then self:Hide() else self:Show() end
    end
    
    function WindowObj:Destroy()
        self:Hide()
        task.wait(0.3)
        ScreenGui:Destroy()
    end
    
    -- 拖动
    function WindowObj:MakeDraggable()
        local dragging = false
        local dragStart, startPos
        
        Header.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or
               input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = Frame.Position
            end
        end)
        
        Header.InputEnded:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or
               input.UserInputType == Enum.UserInputType.Touch then
                dragging = false
            end
        end)
        
        UserInputService.InputChanged:Connect(function(input)
            if dragging then
                if input.UserInputType == Enum.UserInputType.MouseMovement or
                   input.UserInputType == Enum.UserInputType.Touch then
                    local delta = input.Position - dragStart
                    Frame.Position = UDim2.new(
                        startPos.X.Scale, startPos.X.Offset + delta.X,
                        startPos.Y.Scale, startPos.Y.Offset + delta.Y
                    )
                end
            end
        end)
    end
    
    -- ═══════════════════════════════════════════════════════════
    --                    标签页系统
    -- ═══════════════════════════════════════════════════════════
    
    function WindowObj:AddTab(name, icon)
        local displayName = (icon and (icon .. " ") or "") .. name
        
        -- 标签按钮
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = "Tab_" .. name
        tabBtn.Size = UDim2.new(0, Scale(90), 0, Scale(30))
        tabBtn.BackgroundColor3 = theme.Background
        tabBtn.BackgroundTransparency = 0.3
        tabBtn.BorderSizePixel = 0
        tabBtn.Text = displayName
        tabBtn.TextColor3 = theme.TextSecondary
        tabBtn.TextSize = Scale(13)
        tabBtn.Font = Enum.Font.GothamSemibold
        tabBtn.AutoButtonColor = false
        tabBtn.ZIndex = 6
        tabBtn.Parent = self.TabContainer
        AddCorner(tabBtn, 6)
        
        -- 标签内容
        local tabPage = Instance.new("Frame")
        tabPage.Name = "Page_" .. name
        tabPage.Size = UDim2.new(1, 0, 0, 0)
        tabPage.AutomaticSize = Enum.AutomaticSize.Y
        tabPage.BackgroundTransparency = 1
        tabPage.Visible = false
        tabPage.ZIndex = 5
        tabPage.Parent = self.Content
        
        local pageLayout = Instance.new("UIListLayout")
        pageLayout.Padding = UDim.new(0, 8)
        pageLayout.Parent = tabPage
        AddPadding(tabPage, 5, 5, 0, 0)
        
        -- Tab对象
        local Tab = {}
        Tab.Name = name
        Tab.Button = tabBtn
        Tab.Page = tabPage
        Tab.Theme = theme
        Tab.Elements = {}
        Tab.Window = self
        
        -- ═════════════════════════════════════════════════════
        --                    组件方法
        -- ═════════════════════════════════════════════════════
        
        function Tab:AddLabel(text, options)
            options = options or {}
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 0, Scale(options.Height or 25))
            label.BackgroundTransparency = 1
            label.Text = text
            label.TextColor3 = theme.Text
            label.TextSize = Scale(options.TextSize or 14)
            label.Font = options.Font or Enum.Font.Gotham
            label.TextXAlignment = options.Alignment or Enum.TextXAlignment.Left
            label.RichText = options.RichText or false
            label.TextWrapped = true
            label.ZIndex = 6
            label.Parent = self.Page
            table.insert(self.Elements, label)
            return label
        end
        
        function Tab:AddTitle(text)
            local title = Instance.new("TextLabel")
            title.Size = UDim2.new(1, 0, 0, Scale(35))
            title.BackgroundTransparency = 1
            title.Text = text
            title.TextColor3 = theme.Primary
            title.TextSize = Scale(18)
            title.Font = Enum.Font.GothamBold
            title.TextXAlignment = Enum.TextXAlignment.Left
            title.ZIndex = 6
            title.Parent = self.Page
            
            local underline = Instance.new("Frame")
            underline.Size = UDim2.new(0.2, 0, 0, 2)
            underline.Position = UDim2.new(0, 0, 1, -2)
            underline.BackgroundColor3 = theme.Primary
            underline.BackgroundTransparency = 0.4
            underline.BorderSizePixel = 0
            underline.ZIndex = 6
            underline.Parent = title
            AddCorner(underline, 1)
            
            table.insert(self.Elements, title)
            return title
        end
        
        function Tab:AddButton(text, callback, options)
            options = options or {}
            local btn = Instance.new("TextButton")
            btn.Size = UDim2.new(1, 0, 0, Scale(options.Height or 38))
            btn.BackgroundColor3 = theme.Primary
            btn.BorderSizePixel = 0
            btn.Text = text
            btn.TextColor3 = theme.Text
            btn.TextSize = Scale(14)
            btn.Font = Enum.Font.GothamSemibold
            btn.AutoButtonColor = false
            btn.ZIndex = 6
            btn.Parent = self.Page
            AddCorner(btn, 8)
            
            if options.Gradient ~= false then
                local grad = Instance.new("UIGradient")
                grad.Color = ColorSequence.new({
                    ColorSequenceKeypoint.new(0, theme.Primary),
                    ColorSequenceKeypoint.new(1, theme.Secondary)
                })
                grad.Rotation = 90
                grad.Transparency = NumberSequence.new({
                    NumberSequenceKeypoint.new(0, 0.4),
                    NumberSequenceKeypoint.new(1, 0.5)
                })
                grad.Parent = btn
            end
            
            SetupButtonHover(btn, theme, theme.Primary)
            btn.MouseButton1Click:Connect(function()
                if callback then callback() end
            end)
            
            table.insert(self.Elements, btn)
            return btn
        end
        
        function Tab:AddToggle(text, default, callback, options)
            options = options or {}
            local isOn = default or false
            
            local container = Instance.new("Frame")
            container.Size = UDim2.new(1, 0, 0, Scale(35))
            container.BackgroundColor3 = theme.Surface
            container.BackgroundTransparency = 0.5
            container.BorderSizePixel = 0
            container.ZIndex = 6
            container.Parent = self.Page
            AddCorner(container, 8)
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, -60, 1, 0)
            label.Position = UDim2.new(0, 12, 0, 0)
            label.BackgroundTransparency = 1
            label.Text = text
            label.TextColor3 = theme.Text
            label.TextSize = Scale(13)
            label.Font = Enum.Font.Gotham
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = 7
            label.Parent = container
            
            local switchBg = Instance.new("TextButton")
            switchBg.Size = UDim2.new(0, Scale(40), 0, Scale(22))
            switchBg.Position = UDim2.new(1, -Scale(50), 0.5, -Scale(11))
            switchBg.BackgroundColor3 = isOn and theme.Primary or Color3.fromRGB(80, 80, 80)
            switchBg.BorderSizePixel = 0
            switchBg.Text = ""
            switchBg.AutoButtonColor = false
            switchBg.ZIndex = 7
            switchBg.Parent = container
            AddCorner(switchBg, 11)
            
            local switchKnob = Instance.new("Frame")
            switchKnob.Size = UDim2.new(0, Scale(16), 0, Scale(16))
            switchKnob.Position = isOn and UDim2.new(1, -Scale(20), 0.5, -Scale(8)) or UDim2.new(0, Scale(3), 0.5, -Scale(8))
            switchKnob.BackgroundColor3 = Color3.new(1, 1, 1)
            switchKnob.BorderSizePixel = 0
            switchKnob.ZIndex = 8
            switchKnob.Parent = switchBg
            AddCorner(switchKnob, 8)
            
            switchBg.MouseButton1Click:Connect(function()
                isOn = not isOn
                Tween(switchBg, {BackgroundColor3 = isOn and theme.Primary or Color3.fromRGB(80, 80, 80)}, TWEEN.Fast)
                Tween(switchKnob, {Position = isOn and UDim2.new(1, -Scale(20), 0.5, -Scale(8)) or UDim2.new(0, Scale(3), 0.5, -Scale(8))}, TWEEN.Fast)
                if callback then callback(isOn) end
            end)
            
            table.insert(self.Elements, container)
            return container
        end
        
        function Tab:AddSlider(text, min, max, default, callback, options)
            options = options or {}
            local value = default or min
            
            local container = Instance.new("Frame")
            container.Size = UDim2.new(1, 0, 0, Scale(55))
            container.BackgroundColor3 = theme.Surface
            container.BackgroundTransparency = 0.5
            container.BorderSizePixel = 0
            container.ZIndex = 6
            container.Parent = self.Page
            AddCorner(container, 8)
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(0.7, 0, 0, Scale(20))
            label.Position = UDim2.new(0, 12, 0, 5)
            label.BackgroundTransparency = 1
            label.Text = text
            label.TextColor3 = theme.Text
            label.TextSize = Scale(13)
            label.Font = Enum.Font.Gotham
            label.TextXAlignment = Enum.TextXAlignment.Left
            label.ZIndex = 7
            label.Parent = container
            
            local valueLabel = Instance.new("TextLabel")
            valueLabel.Size = UDim2.new(0.3, -12, 0, Scale(20))
            valueLabel.Position = UDim2.new(0.7, 0, 0, 5)
            valueLabel.BackgroundTransparency = 1
            valueLabel.Text = tostring(value)
            valueLabel.TextColor3 = theme.Primary
            valueLabel.TextSize = Scale(13)
            valueLabel.Font = Enum.Font.GothamBold
            valueLabel.TextXAlignment = Enum.TextXAlignment.Right
            valueLabel.ZIndex = 7
            valueLabel.Parent = container
            
            local track = Instance.new("Frame")
            track.Size = UDim2.new(1, -24, 0, Scale(8))
            track.Position = UDim2.new(0, 12, 1, -Scale(18))
            track.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            track.BorderSizePixel = 0
            track.ZIndex = 7
            track.Parent = container
            AddCorner(track, 4)
            
            local fill = Instance.new("Frame")
            fill.Size = UDim2.new((value - min) / (max - min), 0, 1, 0)
            fill.BackgroundColor3 = theme.Primary
            fill.BorderSizePixel = 0
            fill.ZIndex = 8
            fill.Parent = track
            AddCorner(fill, 4)
            
            local knob = Instance.new("Frame")
            knob.Size = UDim2.new(0, Scale(16), 0, Scale(16))
            knob.Position = UDim2.new((value - min) / (max - min), -Scale(4), 0.5, -Scale(8))
            knob.BackgroundColor3 = Color3.new(1, 1, 1)
            knob.BorderSizePixel = 0
            knob.ZIndex = 9
            knob.Parent = track
            AddCorner(knob, 8)
            
            local dragging = false
            
            local function update(input)
                local relX = math.clamp((input.Position.X - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
                value = math.floor(min + (max - min) * relX)
                fill.Size = UDim2.new(relX, 0, 1, 0)
                knob.Position = UDim2.new(relX, -Scale(4), 0.5, -Scale(8))
                valueLabel.Text = tostring(value)
                if callback then callback(value) end
            end
            
            track.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or
                   input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    update(input)
                end
            end)
            
            UserInputService.InputChanged:Connect(function(input)
                if dragging then
                    if input.UserInputType == Enum.UserInputType.MouseMovement or
                       input.UserInputType == Enum.UserInputType.Touch then
                        update(input)
                    end
                end
            end)
            
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1 or
                   input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            
            table.insert(self.Elements, container)
            return container
        end
        
        function Tab:AddTextBox(label, placeholder, callback, options)
            options = options or {}
            local container = Instance.new("Frame")
            container.Size = UDim2.new(1, 0, 0, Scale((label and 60) or 40))
            container.BackgroundTransparency = 1
            container.ZIndex = 6
            container.Parent = self.Page
            
            if label then
                local lbl = Instance.new("TextLabel")
                lbl.Size = UDim2.new(1, 0, 0, Scale(20))
                lbl.BackgroundTransparency = 1
                lbl.Text = label
                lbl.TextColor3 = theme.TextSecondary
                lbl.TextSize = Scale(12)
                lbl.Font = Enum.Font.Gotham
                lbl.TextXAlignment = Enum.TextXAlignment.Left
                lbl.ZIndex = 7
                lbl.Parent = container
            end
            
            local input = Instance.new("TextBox")
            input.Size = UDim2.new(1, 0, 0, Scale(35))
            input.Position = UDim2.new(0, 0, 0, label and Scale(22) or 0)
            input.BackgroundColor3 = theme.Surface
            input.BorderSizePixel = 0
            input.Text = ""
            input.PlaceholderText = placeholder or ""
            input.PlaceholderColor3 = theme.TextSecondary
            input.TextColor3 = theme.Text
            input.TextSize = Scale(13)
            input.Font = Enum.Font.Gotham
            input.TextXAlignment = Enum.TextXAlignment.Left
            input.ClearTextOnFocus = options.ClearOnFocus ~= false
            input.ZIndex = 7
            input.Parent = container
            AddCorner(input, 8)
            AddPadding(input, 0, 0, 12, 12)
            
            input.FocusLost:Connect(function(enterPressed)
                if callback then callback(input.Text, enterPressed) end
            end)
            
            table.insert(self.Elements, container)
            return container
        end
        
        function Tab:AddDropdown(text, options_list, default, callback, options)
            options = options or {}
            local container = Instance.new("Frame")
            container.Size = UDim2.new(1, 0, 0, Scale(60))
            container.BackgroundTransparency = 1
            container.ZIndex = 6
            container.Parent = self.Page
            
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, 0, 0, Scale(20))
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.TextColor3 = theme.TextSecondary
            lbl.TextSize = Scale(12)
            lbl.Font = Enum.Font.Gotham
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 7
            lbl.Parent = container
            
            local dropBtn = Instance.new("TextButton")
            dropBtn.Size = UDim2.new(1, 0, 0, Scale(35))
            dropBtn.Position = UDim2.new(0, 0, 0, Scale(22))
            dropBtn.BackgroundColor3 = theme.Surface
            dropBtn.BorderSizePixel = 0
            dropBtn.Text = default or options_list[1] or "选择..."
            dropBtn.TextColor3 = theme.Text
            dropBtn.TextSize = Scale(13)
            dropBtn.Font = Enum.Font.Gotham
            dropBtn.TextXAlignment = Enum.TextXAlignment.Left
            dropBtn.AutoButtonColor = false
            dropBtn.ZIndex = 7
            dropBtn.Parent = container
            AddCorner(dropBtn, 8)
            AddPadding(dropBtn, 0, 0, 12, 30)
            
            local arrow = Instance.new("TextLabel")
            arrow.Size = UDim2.new(0, Scale(20), 1, 0)
            arrow.Position = UDim2.new(1, -Scale(25), 0, 0)
            arrow.BackgroundTransparency = 1
            arrow.Text = "v"
            arrow.TextColor3 = theme.TextSecondary
            arrow.TextSize = Scale(10)
            arrow.Font = Enum.Font.Gotham
            arrow.ZIndex = 8
            arrow.Parent = dropBtn
            
            local menu = Instance.new("Frame")
            menu.Size = UDim2.new(1, 0, 0, 0)
            menu.Position = UDim2.new(0, 0, 1, 5)
            menu.BackgroundColor3 = theme.Surface
            menu.BorderSizePixel = 0
            menu.ClipsDescendants = true
            menu.Visible = false
            menu.ZIndex = 50
            menu.Parent = dropBtn
            AddCorner(menu, 8)
            AddStroke(menu, theme.Border, 1)
            
            local menuLayout = Instance.new("UIListLayout")
            menuLayout.Parent = menu
            
            local isOpen = false
            
            dropBtn.MouseButton1Click:Connect(function()
                isOpen = not isOpen
                if isOpen then
                    menu.Visible = true
                    menu.Size = UDim2.new(1, 0, 0, 0)
                    Tween(menu, {Size = UDim2.new(1, 0, 0, #options_list * Scale(28))}, TWEEN.Fast)
                    Tween(arrow, {Rotation = 180}, TWEEN.Fast)
                else
                    Tween(menu, {Size = UDim2.new(1, 0, 0, 0)}, TWEEN.Fast)
                    Tween(arrow, {Rotation = 0}, TWEEN.Fast)
                    task.wait(0.15)
                    menu.Visible = false
                end
            end)
            
            for _, option in ipairs(options_list) do
                local item = Instance.new("TextButton")
                item.Size = UDim2.new(1, 0, 0, Scale(28))
                item.BackgroundTransparency = 1
                item.Text = "  " .. option
                item.TextColor3 = theme.Text
                item.TextSize = Scale(12)
                item.Font = Enum.Font.Gotham
                item.TextXAlignment = Enum.TextXAlignment.Left
                item.AutoButtonColor = false
                item.ZIndex = 51
                item.Parent = menu
                
                item.MouseEnter:Connect(function()
                    item.BackgroundColor3 = theme.Primary
                    item.BackgroundTransparency = 0.6
                end)
                item.MouseLeave:Connect(function()
                    item.BackgroundTransparency = 1
                end)
                
                item.MouseButton1Click:Connect(function()
                    dropBtn.Text = option
                    isOpen = false
                    Tween(menu, {Size = UDim2.new(1, 0, 0, 0)}, TWEEN.Fast)
                    Tween(arrow, {Rotation = 0}, TWEEN.Fast)
                    task.wait(0.15)
                    menu.Visible = false
                    if callback then callback(option) end
                end)
            end
            
            table.insert(self.Elements, container)
            return container
        end
        
        function Tab:AddSeparator()
            local sep = Instance.new("Frame")
            sep.Size = UDim2.new(1, 0, 0, Scale(15))
            sep.BackgroundTransparency = 1
            sep.ZIndex = 6
            sep.Parent = self.Page
            
            local line = Instance.new("Frame")
            line.Size = UDim2.new(1, 0, 0, 1)
            line.Position = UDim2.new(0, 0, 0.5, 0)
            line.BackgroundColor3 = theme.Border
            line.BackgroundTransparency = 0.5
            line.BorderSizePixel = 0
            line.ZIndex = 7
            line.Parent = sep
            
            table.insert(self.Elements, sep)
            return sep
        end
        
        function Tab:AddProgressBar(text, value, options)
            options = options or {}
            local container = Instance.new("Frame")
            container.Size = UDim2.new(1, 0, 0, Scale(40))
            container.BackgroundColor3 = theme.Surface
            container.BackgroundTransparency = 0.5
            container.BorderSizePixel = 0
            container.ZIndex = 6
            container.Parent = self.Page
            AddCorner(container, 8)
            
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -60, 1, 0)
            lbl.Position = UDim2.new(0, 12, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.TextColor3 = theme.Text
            lbl.TextSize = Scale(12)
            lbl.Font = Enum.Font.Gotham
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 7
            lbl.Parent = container
            
            local percent = Instance.new("TextLabel")
            percent.Size = UDim2.new(0, 50, 1, 0)
            percent.Position = UDim2.new(1, -55, 0, 0)
            percent.BackgroundTransparency = 1
            percent.Text = math.floor((value or 0) * 100) .. "%"
            percent.TextColor3 = theme.Primary
            percent.TextSize = Scale(12)
            percent.Font = Enum.Font.GothamBold
            percent.TextXAlignment = Enum.TextXAlignment.Right
            percent.ZIndex = 7
            percent.Parent = container
            
            local track = Instance.new("Frame")
            track.Size = UDim2.new(1, -24, 0, Scale(6))
            track.Position = UDim2.new(0, 12, 1, -Scale(12))
            track.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
            track.BorderSizePixel = 0
            track.ZIndex = 7
            track.Parent = container
            AddCorner(track, 3)
            
            local fill = Instance.new("Frame")
            fill.Size = UDim2.new(value or 0, 0, 1, 0)
            fill.BackgroundColor3 = theme.Primary
            fill.BorderSizePixel = 0
            fill.ZIndex = 8
            fill.Parent = track
            AddCorner(fill, 3)
            
            function container:SetValue(val)
                val = math.clamp(val, 0, 1)
                Tween(fill, {Size = UDim2.new(val, 0, 1, 0)}, TWEEN.Smooth)
                percent.Text = math.floor(val * 100) .. "%"
            end
            
            table.insert(self.Elements, container)
            return container
        end
        
        function Tab:AddColorPicker(text, default, callback, options)
            options = options or {}
            local container = Instance.new("Frame")
            container.Size = UDim2.new(1, 0, 0, Scale(40))
            container.BackgroundColor3 = theme.Surface
            container.BackgroundTransparency = 0.5
            container.BorderSizePixel = 0
            container.ZIndex = 6
            container.Parent = self.Page
            AddCorner(container, 8)
            
            local lbl = Instance.new("TextLabel")
            lbl.Size = UDim2.new(1, -60, 1, 0)
            lbl.Position = UDim2.new(0, 12, 0, 0)
            lbl.BackgroundTransparency = 1
            lbl.Text = text
            lbl.TextColor3 = theme.Text
            lbl.TextSize = Scale(13)
            lbl.Font = Enum.Font.Gotham
            lbl.TextXAlignment = Enum.TextXAlignment.Left
            lbl.ZIndex = 7
            lbl.Parent = container
            
            local colors = {
                Color3.fromRGB(255, 80, 80),
                Color3.fromRGB(255, 165, 0),
                Color3.fromRGB(255, 255, 0),
                Color3.fromRGB(0, 255, 0),
                Color3.fromRGB(0, 170, 255),
                Color3.fromRGB(147, 112, 219),
                Color3.fromRGB(255, 255, 255),
                Color3.fromRGB(50, 50, 50)
            }
            
            local colorBtn = Instance.new("TextButton")
            colorBtn.Size = UDim2.new(0, Scale(30), 0, Scale(22))
            colorBtn.Position = UDim2.new(1, -Scale(42), 0.5, -Scale(11))
            colorBtn.BackgroundColor3 = default or theme.Primary
            colorBtn.BorderSizePixel = 0
            colorBtn.Text = ""
            colorBtn.AutoButtonColor = false
            colorBtn.ZIndex = 7
            colorBtn.Parent = container
            AddCorner(colorBtn, 4)
            AddStroke(colorBtn, theme.Border, 1)
            
            local idx = 1
            for i, c in ipairs(colors) do
                if c == (default or theme.Primary) then
                    idx = i
                    break
                end
            end
            
            colorBtn.MouseButton1Click:Connect(function()
                idx = (idx % #colors) + 1
                Tween(colorBtn, {BackgroundColor3 = colors[idx]}, TWEEN.Fast)
                if callback then callback(colors[idx]) end
            end)
            
            table.insert(self.Elements, container)
            return container
        end
        
        function Tab:AddGroup(title)
            local group = Instance.new("Frame")
            group.Size = UDim2.new(1, 0, 0, Scale(80))
            group.AutomaticSize = Enum.AutomaticSize.Y
            group.BackgroundColor3 = theme.Surface
            group.BackgroundTransparency = 0.4
            group.BorderSizePixel = 0
            group.ZIndex = 6
            group.Parent = self.Page
            AddCorner(group, 10)
            AddStroke(group, theme.Border, 1)
            
            local groupTitle = Instance.new("TextLabel")
            groupTitle.Size = UDim2.new(1, -20, 0, Scale(30))
            groupTitle.Position = UDim2.new(0, 10, 0, 5)
            groupTitle.BackgroundTransparency = 1
            groupTitle.Text = title
            groupTitle.TextColor3 = theme.Primary
            groupTitle.TextSize = Scale(14)
            groupTitle.Font = Enum.Font.GothamBold
            groupTitle.TextXAlignment = Enum.TextXAlignment.Left
            groupTitle.ZIndex = 7
            groupTitle.Parent = group
            
            local groupContent = Instance.new("Frame")
            groupContent.Name = "GroupContent"
            groupContent.Size = UDim2.new(1, -20, 0, 0)
            groupContent.Position = UDim2.new(0, 10, 0, Scale(35))
            groupContent.AutomaticSize = Enum.AutomaticSize.Y
            groupContent.BackgroundTransparency = 1
            groupContent.ZIndex = 7
            groupContent.Parent = group
            
            local groupLayout = Instance.new("UIListLayout")
            groupLayout.Padding = UDim.new(0, 6)
            groupLayout.Parent = groupContent
            
            local GroupObj = {}
            GroupObj.Title = title
            GroupObj.Content = groupContent
            GroupObj.Elements = {}
            
            function GroupObj:AddLabel(text, opts)
                opts = opts or {}
                local l = Instance.new("TextLabel")
                l.Size = UDim2.new(1, 0, 0, Scale(opts.Height or 20))
                l.BackgroundTransparency = 1
                l.Text = text
                l.TextColor3 = theme.Text
                l.TextSize = Scale(12)
                l.Font = Enum.Font.Gotham
                l.TextXAlignment = Enum.TextXAlignment.Left
                l.ZIndex = 8
                l.Parent = self.Content
                table.insert(self.Elements, l)
                return l
            end
            
            function GroupObj:AddButton(text, cb, opts)
                opts = opts or {}
                local b = Instance.new("TextButton")
                b.Size = UDim2.new(1, 0, 0, Scale(opts.Height or 32))
                b.BackgroundColor3 = theme.Primary
                b.BorderSizePixel = 0
                b.Text = text
                b.TextColor3 = theme.Text
                b.TextSize = Scale(12)
                b.Font = Enum.Font.GothamSemibold
                b.AutoButtonColor = false
                b.ZIndex = 8
                b.Parent = self.Content
                AddCorner(b, 6)
                SetupButtonHover(b, theme, theme.Primary)
                b.MouseButton1Click:Connect(function() if cb then cb() end end)
                table.insert(self.Elements, b)
                return b
            end
            
            function GroupObj:AddToggle(text, def, cb, opts)
                opts = opts or {}
                local isOn = def or false
                local c = Instance.new("Frame")
                c.Size = UDim2.new(1, 0, 0, Scale(30))
                c.BackgroundTransparency = 1
                c.ZIndex = 8
                c.Parent = self.Content
                
                local lb = Instance.new("TextLabel")
                lb.Size = UDim2.new(1, -45, 1, 0)
                lb.BackgroundTransparency = 1
                lb.Text = text
                lb.TextColor3 = theme.Text
                lb.TextSize = Scale(12)
                lb.Font = Enum.Font.Gotham
                lb.TextXAlignment = Enum.TextXAlignment.Left
                lb.ZIndex = 9
                lb.Parent = c
                
                local sw = Instance.new("TextButton")
                sw.Size = UDim2.new(0, Scale(35), 0, Scale(20))
                sw.Position = UDim2.new(1, -Scale(40), 0.5, -Scale(10))
                sw.BackgroundColor3 = isOn and theme.Primary or Color3.fromRGB(80, 80, 80)
                sw.BorderSizePixel = 0
                sw.Text = ""
                sw.AutoButtonColor = false
                sw.ZIndex = 9
                sw.Parent = c
                AddCorner(sw, 10)
                
                local k = Instance.new("Frame")
                k.Size = UDim2.new(0, Scale(14), 0, Scale(14))
                k.Position = isOn and UDim2.new(1, -Scale(18), 0.5, -Scale(7)) or UDim2.new(0, Scale(3), 0.5, -Scale(7))
                k.BackgroundColor3 = Color3.new(1, 1, 1)
                k.BorderSizePixel = 0
                k.ZIndex = 10
                k.Parent = sw
                AddCorner(k, 7)
                
                sw.MouseButton1Click:Connect(function()
                    isOn = not isOn
                    Tween(sw, {BackgroundColor3 = isOn and theme.Primary or Color3.fromRGB(80, 80, 80)}, TWEEN.Fast)
                    Tween(k, {Position = isOn and UDim2.new(1, -Scale(18), 0.5, -Scale(7)) or UDim2.new(0, Scale(3), 0.5, -Scale(7))}, TWEEN.Fast)
                    if cb then cb(isOn) end
                end)
                
                table.insert(self.Elements, c)
                return c
            end
            
            function GroupObj:AddSlider(text, mn, mx, def, cb, opts)
                opts = opts or {}
                local val = def or mn
                local c = Instance.new("Frame")
                c.Size = UDim2.new(1, 0, 0, Scale(45))
                c.BackgroundTransparency = 1
                c.ZIndex = 8
                c.Parent = self.Content
                
                local lb = Instance.new("TextLabel")
                lb.Size = UDim2.new(0.7, 0, 0, Scale(18))
                lb.BackgroundTransparency = 1
                lb.Text = text
                lb.TextColor3 = theme.Text
                lb.TextSize = Scale(12)
                lb.Font = Enum.Font.Gotham
                lb.TextXAlignment = Enum.TextXAlignment.Left
                lb.ZIndex = 9
                lb.Parent = c
                
                local vl = Instance.new("TextLabel")
                vl.Size = UDim2.new(0.3, 0, 0, Scale(18))
                vl.Position = UDim2.new(0.7, 0, 0, 0)
                vl.BackgroundTransparency = 1
                vl.Text = tostring(val)
                vl.TextColor3 = theme.Primary
                vl.TextSize = Scale(12)
                vl.Font = Enum.Font.GothamBold
                vl.TextXAlignment = Enum.TextXAlignment.Right
                vl.ZIndex = 9
                vl.Parent = c
                
                local tk = Instance.new("Frame")
                tk.Size = UDim2.new(1, 0, 0, Scale(6))
                tk.Position = UDim2.new(0, 0, 1, -Scale(8))
                tk.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
                tk.BorderSizePixel = 0
                tk.ZIndex = 9
                tk.Parent = c
                AddCorner(tk, 3)
                
                local fl = Instance.new("Frame")
                fl.Size = UDim2.new((val - mn) / (mx - mn), 0, 1, 0)
                fl.BackgroundColor3 = theme.Primary
                fl.BorderSizePixel = 0
                fl.ZIndex = 10
                fl.Parent = tk
                AddCorner(fl, 3)
                
                local dragging = false
                
                local function upd(input)
                    local r = math.clamp((input.Position.X - tk.AbsolutePosition.X) / tk.AbsoluteSize.X, 0, 1)
                    val = math.floor(mn + (mx - mn) * r)
                    fl.Size = UDim2.new(r, 0, 1, 0)
                    vl.Text = tostring(val)
                    if cb then cb(val) end
                end
                
                tk.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or
                       input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        upd(input)
                    end
                end)
                
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or
                       input.UserInputType == Enum.UserInputType.Touch) then
                        upd(input)
                    end
                end)
                
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or
                       input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)
                
                table.insert(self.Elements, c)
                return c
            end
            
            table.insert(self.Elements, group)
            return GroupObj
        end
        
        function Tab:Clear()
            for _, elem in ipairs(self.Elements) do
                if elem and elem.Destroy then
                    pcall(function() elem:Destroy() end)
                end
            end
            self.Elements = {}
        end
        
        -- 标签点击切换
        tabBtn.MouseButton1Click:Connect(function()
            for _, t in ipairs(self.Tabs) do
                t.Page.Visible = false
                t.Button.BackgroundColor3 = theme.Background
                t.Button.BackgroundTransparency = 0.3
                t.Button.TextColor3 = theme.TextSecondary
            end
            tabPage.Visible = true
            tabBtn.BackgroundColor3 = theme.Primary
            tabBtn.BackgroundTransparency = 0.1
            tabBtn.TextColor3 = theme.Text
            self.CurrentTab = Tab
        end)
        
        -- 悬停效果
        tabBtn.MouseEnter:Connect(function()
            if self.CurrentTab ~= Tab then
                Tween(tabBtn, {BackgroundColor3 = theme.Surface})
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if self.CurrentTab ~= Tab then
                Tween(tabBtn, {BackgroundColor3 = theme.Background})
            end
        end)
        
        table.insert(self.Tabs, Tab)
        
        -- 第一个标签自动选中
        if #self.Tabs == 1 then
            tabPage.Visible = true
            tabBtn.BackgroundColor3 = theme.Primary
            tabBtn.BackgroundTransparency = 0.1
            tabBtn.TextColor3 = theme.Text
            self.CurrentTab = Tab
        end
        
        return Tab
    end
    
    return WindowObj
end

return OceanUI