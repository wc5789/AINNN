-- ====================================================================
--  Vape V4 Pro White-Blue Sci-Fi UI Library (Full Featured)
--  Features: Ripple Effect, Dynamic Tab Resizing, Keybinds, Dropdowns,
--            Notifications, Auto Mobile/PC Adapting.
--  Author: DeepSeek-Girl for Master
-- ====================================================================

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local VapeLib = {}
VapeLib.__index = VapeLib

-- 🩵 冰点纯白-电光科技蓝 主题配色 🩵
local Theme = {
    MainBg       = Color3.fromRGB(248, 250, 255),
    CategoryBg   = Color3.fromRGB(252, 254, 255),
    HeaderBg     = Color3.fromRGB(232, 240, 254),
    CardBg       = Color3.fromRGB(225, 234, 248),
    CardActive   = Color3.fromRGB(205, 225, 255),
    AccentBlue   = Color3.fromRGB(0, 150, 255),
    GlowBlue     = Color3.fromRGB(100, 210, 255),
    RippleColor  = Color3.fromRGB(80, 180, 255),
    TextDark     = Color3.fromRGB(25, 40, 65),
    TextBlue     = Color3.fromRGB(0, 120, 235),
    BorderColor  = Color3.fromRGB(200, 218, 242)
}

-- 平滑动画辅助
local function Tween(inst, props, duration, style, dir)
    local info = TweenInfo.new(duration or 0.25, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out)
    local t = TweenService:Create(inst, info, props)
    t:Play()
    return t
end

-- 🌊 水波纹/水回流动画核心函数 (Ripple Effect)
local function CreateRipple(parentObj, inputPos)
    local ripple = Instance.new("Frame")
    ripple.Name = "Ripple"
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.BackgroundColor3 = Theme.RippleColor
    ripple.BackgroundTransparency = 0.4
    ripple.BorderSizePixel = 0
    ripple.ZIndex = 8

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0) -- 纯圆外扩
    corner.Parent = ripple

    -- 计算点击相对位置
    local absPos = parentObj.AbsolutePosition
    local relX = inputPos.X - absPos.X
    local relY = inputPos.Y - absPos.Y
    ripple.Position = UDim2.new(0, relX, 0, relY)
    ripple.Size = UDim2.new(0, 0, 0, 0)
    ripple.Parent = parentObj

    local targetSize = math.max(parentObj.AbsoluteSize.X, parentObj.AbsoluteSize.Y) * 2.8
    local tw = Tween(ripple, {
        Size = UDim2.new(0, targetSize, 0, targetSize),
        BackgroundTransparency = 1
    }, 0.55, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

    tw.Completed:Connect(function()
        ripple:Destroy()
    end)
end

-- 边缘流光动画
local function AddFlowingLight(guiObject)
    local uiGradient = Instance.new("UIGradient")
    uiGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 150, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 150, 255))
    })
    uiGradient.Parent = guiObject

    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not guiObject or not guiObject.Parent then
            conn:Disconnect()
            return
        end
        uiGradient.Rotation = (uiGradient.Rotation + 1.5) % 360
    end)
end

-- 拖拽逻辑
local function MakeDraggable(gui, handle)
    local dragging, dragInput, dragStart, startPos
    handle = handle or gui
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    
    handle.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    
    UserInputService.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            Tween(gui, {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)}, 0.06)
        end
    end)
end

-- ====================================================================
--  UI Library 核心主类
-- ====================================================================
function VapeLib:CreateWindow(libTitle)
    local window = {}

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "VapeV4Pro_" .. math.random(1000, 9999)
    screenGui.ResetOnSpawn = false

    if gethui then screenGui.Parent = gethui()
    elseif syn and syn.protect_gui then syn.protect_gui(screenGui); screenGui.Parent = CoreGui
    else screenGui.Parent = CoreGui end

    -- 🔔 弹窗通知容器 (Notification Stack)
    local notifyHolder = Instance.new("Frame")
    notifyHolder.Name = "NotifyHolder"
    notifyHolder.Size = UDim2.new(0, 240, 1, -20)
    notifyHolder.Position = UDim2.new(1, -250, 0, 10)
    notifyHolder.BackgroundTransparency = 1
    notifyHolder.Parent = screenGui

    local notifyLayout = Instance.new("UIListLayout")
    notifyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    notifyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    notifyLayout.Padding = UDim.new(0, 8)
    notifyLayout.Parent = notifyHolder

    -- 全局通知函数
    function VapeLib:Notify(cfg)
        local title = cfg.Title or "Notification"
        local content = cfg.Content or ""
        local duration = cfg.Duration or 3

        local card = Instance.new("Frame")
        card.Size = UDim2.new(1, 0, 0, 50)
        card.Position = UDim2.new(1, 50, 0, 0)
        card.BackgroundColor3 = Theme.MainBg
        card.BorderSizePixel = 0
        card.Parent = notifyHolder

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1.5
        stroke.Color = Theme.AccentBlue
        stroke.Parent = card
        AddFlowingLight(stroke)

        local tLabel = Instance.new("TextLabel")
        tLabel.Size = UDim2.new(1, -12, 0, 20)
        tLabel.Position = UDim2.new(0, 8, 0, 4)
        tLabel.Text = title
        tLabel.TextColor3 = Theme.TextBlue
        tLabel.Font = Enum.Font.GothamBold
        tLabel.TextSize = 12
        tLabel.TextXAlignment = Enum.TextXAlignment.Left
        tLabel.BackgroundTransparency = 1
        tLabel.Parent = card

        local cLabel = Instance.new("TextLabel")
        cLabel.Size = UDim2.new(1, -12, 0, 22)
        cLabel.Position = UDim2.new(0, 8, 0, 22)
        cLabel.Text = content
        cLabel.TextColor3 = Theme.TextDark
        cLabel.Font = Enum.Font.Gotham
        cLabel.TextSize = 10
        cLabel.TextXAlignment = Enum.TextXAlignment.Left
        cLabel.BackgroundTransparency = 1
        cLabel.Parent = card

        -- 滑入动画
        Tween(card, {Position = UDim2.new(0, 0, 0, 0)}, 0.3, Enum.EasingStyle.Back)

        task.delay(duration, function()
            local tw = Tween(card, {Position = UDim2.new(1, 50, 0, 0)}, 0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.In)
            tw.Completed:Connect(function() card:Destroy() end)
        end)
    end

    -- 📱 移动端悬浮开关球
    local toggleBall = Instance.new("TextButton")
    toggleBall.Name = "VapeToggleBall"
    toggleBall.Size = UDim2.new(0, 42, 0, 42)
    toggleBall.Position = UDim2.new(0.04, 0, 0.12, 0)
    toggleBall.BackgroundColor3 = Theme.MainBg
    toggleBall.Text = "VAPE"
    toggleBall.TextColor3 = Theme.TextBlue
    toggleBall.Font = Enum.Font.GothamBold
    toggleBall.TextSize = 11
    toggleBall.BorderSizePixel = 0
    toggleBall.ClipsDescendants = true
    toggleBall.Parent = screenGui

    local ballStroke = Instance.new("UIStroke")
    ballStroke.Thickness = 2
    ballStroke.Color = Theme.AccentBlue
    ballStroke.Parent = toggleBall
    AddFlowingLight(ballStroke)
    MakeDraggable(toggleBall)

    -- 📏 主控制栏 Frame ( Main Hub Bar ) - 支持宽度智能自适应！
    local mainBar = Instance.new("Frame")
    mainBar.Name = "MainHubBar"
    mainBar.Size = UDim2.new(0, 180, 0, 42) -- 默认基准宽，会根据 Tab 动态扩展
    mainBar.Position = UDim2.new(0.5, -90, 0.05, 0)
    mainBar.BackgroundColor3 = Theme.MainBg
    mainBar.BorderSizePixel = 0
    mainBar.ClipsDescendants = true
    mainBar.Parent = screenGui

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Thickness = 1.5
    mainStroke.Color = Theme.AccentBlue
    mainStroke.Parent = mainBar
    AddFlowingLight(mainStroke)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0, 85, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.Text = libTitle or "VAPE v4"
    titleLabel.TextColor3 = Theme.TextDark
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 13
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.BackgroundTransparency = 1
    titleLabel.Parent = mainBar

    -- 横向 Tab 滚动容器
    local tabScroll = Instance.new("ScrollingFrame")
    tabScroll.Name = "TabScroll"
    tabScroll.Size = UDim2.new(1, -95, 1, -8)
    tabScroll.Position = UDim2.new(0, 90, 0, 4)
    tabScroll.BackgroundTransparency = 1
    tabScroll.ScrollBarThickness = 0 -- 隐藏多余滚动条，纯顺滑体验
    tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
    tabScroll.Parent = mainBar

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 6)
    tabLayout.Parent = tabScroll

    MakeDraggable(mainBar)

    -- 📐 核心算法：根据 Tab 数量和尺寸，智能自适应主窗口宽度
    local function RecalculateMainBarWidth()
        task.wait()
        local contentWidth = tabLayout.AbsoluteContentSize.X
        local maxAllowedWidth = math.min(workspace.CurrentCamera.ViewportSize.X - 30, 650)
        local targetWidth = math.clamp(contentWidth + 105, 180, maxAllowedWidth)

        Tween(mainBar, {
            Size = UDim2.new(0, targetWidth, 0, 42),
            Position = UDim2.new(0.5, -targetWidth/2, mainBar.Position.Y.Scale, mainBar.Position.Y.Offset)
        }, 0.25)
    end

    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(RecalculateMainBarWidth)

    -- 全局隐藏/显示 UI
    local uiVisible = true
    local function ToggleGlobalUI()
        uiVisible = not uiVisible
        mainBar.Visible = uiVisible
        for _, catWin in pairs(window.CategoryWindows) do
            if catWin.IsOpen then catWin.Frame.Visible = uiVisible end
        end
    end

    toggleBall.MouseButton1Click:Connect(function(input)
        CreateRipple(toggleBall, UserInputService:GetMouseLocation())
        ToggleGlobalUI()
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == Enum.KeyCode.RightControl then
            ToggleGlobalUI()
        end
    end)

    window.CategoryWindows = {}
    local windowOffsetCount = 0

    -- ================================================================
    --  创建 Tab (对应弹出的独立窗口)
    -- ================================================================
    function window:CreateTab(tabName)
        local tab = {}

        -- Tab 按钮
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = tabName .. "_TabBtn"
        tabBtn.Size = UDim2.new(0, 65, 1, 0)
        tabBtn.BackgroundColor3 = Theme.HeaderBg
        tabBtn.Text = tabName
        tabBtn.TextColor3 = Theme.TextDark
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.TextSize = 11
        tabBtn.BorderSizePixel = 0
        tabBtn.AutoButtonColor = false
        tabBtn.ClipsDescendants = true
        tabBtn.Parent = tabScroll

        local tabStroke = Instance.new("UIStroke")
        tabStroke.Thickness = 1
        tabStroke.Color = Theme.BorderColor
        tabStroke.Parent = tabBtn

        -- 独立 Category 窗口
        windowOffsetCount = windowOffsetCount + 1
        local screenWidth = workspace.CurrentCamera.ViewportSize.X
        local frameWidth = math.clamp(screenWidth * 0.42, 165, 215)

        local catFrame = Instance.new("Frame")
        catFrame.Name = tabName .. "_CategoryWindow"
        catFrame.Size = UDim2.new(0, frameWidth, 0, 360)
        catFrame.Position = UDim2.new(0.04 + ((windowOffsetCount-1) * 0.17), 0, 0.18, 0)
        catFrame.BackgroundColor3 = Theme.CategoryBg
        catFrame.BorderSizePixel = 0
        catFrame.Visible = false
        catFrame.ClipsDescendants = true
        catFrame.Parent = screenGui

        local catStroke = Instance.new("UIStroke")
        catStroke.Thickness = 1.5
        catStroke.Color = Theme.BorderColor
        catStroke.Parent = catFrame

        -- 窗口 Header
        local catHeader = Instance.new("Frame")
        catHeader.Size = UDim2.new(1, 0, 0, 32)
        catHeader.BackgroundColor3 = Theme.HeaderBg
        catHeader.BorderSizePixel = 0
        catHeader.Parent = catFrame

        local catTitle = Instance.new("TextLabel")
        catTitle.Size = UDim2.new(1, -10, 1, 0)
        catTitle.Position = UDim2.new(0, 10, 0, 0)
        catTitle.Text = tabName
        catTitle.TextColor3 = Theme.TextDark
        catTitle.Font = Enum.Font.GothamBold
        catTitle.TextSize = 12
        catTitle.TextXAlignment = Enum.TextXAlignment.Left
        catTitle.BackgroundTransparency = 1
        catTitle.Parent = catHeader

        local catHeaderLine = Instance.new("Frame")
        catHeaderLine.Size = UDim2.new(1, 0, 0, 2)
        catHeaderLine.Position = UDim2.new(0, 0, 1, -2)
        catHeaderLine.BackgroundColor3 = Theme.AccentBlue
        catHeaderLine.BorderSizePixel = 0
        catHeaderLine.Parent = catHeader

        -- 窗口内容 ScrollingFrame
        local catScroll = Instance.new("ScrollingFrame")
        catScroll.Size = UDim2.new(1, -6, 1, -38)
        catScroll.Position = UDim2.new(0, 3, 0, 35)
        catScroll.BackgroundTransparency = 1
        catScroll.ScrollBarThickness = 2
        catScroll.ScrollBarImageColor3 = Theme.AccentBlue
        catScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        catScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        catScroll.Parent = catFrame

        local catLayout = Instance.new("UIListLayout")
        catLayout.SortOrder = Enum.SortOrder.LayoutOrder
        catLayout.Padding = UDim.new(0, 6)
        catLayout.Parent = catScroll

        MakeDraggable(catFrame, catHeader)

        local catObj = { Frame = catFrame, IsOpen = false }
        table.insert(window.CategoryWindows, catObj)

        -- 点击 Tab 打开/关闭 独立窗口
        tabBtn.MouseButton1Click:Connect(function(input)
            CreateRipple(tabBtn, UserInputService:GetMouseLocation())
            catObj.IsOpen = not catObj.IsOpen
            if catObj.IsOpen then
                catFrame.Visible = true
                catFrame.Size = UDim2.new(0, frameWidth, 0, 0)
                Tween(catFrame, {Size = UDim2.new(0, frameWidth, 0, 360)}, 0.35, Enum.EasingStyle.Back)
                Tween(tabBtn, {BackgroundColor3 = Theme.AccentBlue, TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
                catStroke.Color = Theme.AccentBlue
            else
                Tween(catFrame, {Size = UDim2.new(0, frameWidth, 0, 0)}, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In).Completed:Connect(function()
                    if not catObj.IsOpen then catFrame.Visible = false end
                end)
                Tween(tabBtn, {BackgroundColor3 = Theme.HeaderBg, TextColor3 = Theme.TextDark}, 0.2)
                catStroke.Color = Theme.BorderColor
            end
        end)

        -- Recalculate size upon adding Tab
        RecalculateMainBarWidth()

        -- ============================================================
        --  创建功能模块 (Button + 水波纹 + 快捷键 + “...” 详细折叠菜单)
        -- ============================================================
        function tab:CreateModule(modName, callback)
            callback = callback or function() end
            local module = { Enabled = false, Keybound = nil }

            local modFrame = Instance.new("Frame")
            modFrame.Name = modName .. "_Module"
            modFrame.Size = UDim2.new(1, 0, 0, 30)
            modFrame.BackgroundColor3 = Theme.CardBg
            modFrame.ClipsDescendants = true
            modFrame.BorderSizePixel = 0
            modFrame.Parent = catScroll

            local modStroke = Instance.new("UIStroke")
            modStroke.Thickness = 1
            modStroke.Color = Theme.BorderColor
            modStroke.Parent = modFrame

            -- 🎹 模块左侧/内嵌的快捷键 Keybind 设定按钮
            local keybindBtn = Instance.new("TextButton")
            keybindBtn.Size = UDim2.new(0, 24, 0, 20)
            keybindBtn.Position = UDim2.new(0, 4, 0, 5)
            keybindBtn.BackgroundColor3 = Theme.HeaderBg
            keybindBtn.Text = "-"
            keybindBtn.TextColor3 = Theme.TextDark
            keybindBtn.Font = Enum.Font.GothamBold
            keybindBtn.TextSize = 9
            keybindBtn.BorderSizePixel = 0
            keybindBtn.Parent = modFrame

            local kbStroke = Instance.new("UIStroke")
            kbStroke.Thickness = 1
            kbStroke.Color = Theme.BorderColor
            kbStroke.Parent = keybindBtn

            -- 主功能按钮
            local modBtn = Instance.new("TextButton")
            modBtn.Size = UDim2.new(1, -58, 0, 30)
            modBtn.Position = UDim2.new(0, 30, 0, 0)
            modBtn.BackgroundTransparency = 1
            modBtn.Text = modName
            modBtn.TextColor3 = Theme.TextDark
            modBtn.Font = Enum.Font.GothamMedium
            modBtn.TextSize = 11
            modBtn.TextXAlignment = Enum.TextXAlignment.Left
            modBtn.ClipsDescendants = true
            modBtn.Parent = modFrame

            -- 右侧 “...” 详细展开按钮
            local moreBtn = Instance.new("TextButton")
            moreBtn.Size = UDim2.new(0, 24, 0, 30)
            moreBtn.Position = UDim2.new(1, -26, 0, 0)
            moreBtn.Text = "•••"
            moreBtn.TextColor3 = Theme.TextDark
            moreBtn.Font = Enum.Font.GothamBold
            moreBtn.TextSize = 10
            moreBtn.BackgroundTransparency = 1
            moreBtn.Parent = modFrame

            -- 展开详细配置的 Container
            local subContainer = Instance.new("Frame")
            subContainer.Size = UDim2.new(1, -8, 0, 0)
            subContainer.Position = UDim2.new(0, 4, 0, 32)
            subContainer.BackgroundTransparency = 1
            subContainer.Parent = modFrame

            local subLayout = Instance.new("UIListLayout")
            subLayout.SortOrder = Enum.SortOrder.LayoutOrder
            subLayout.Padding = UDim.new(0, 4)
            subLayout.Parent = subContainer

            local isExpanded = false

            local function UpdateModHeight()
                if isExpanded then
                    local h = subLayout.AbsoluteContentSize.Y + 36
                    Tween(modFrame, {Size = UDim2.new(1, 0, 0, h)}, 0.25)
                else
                    Tween(modFrame, {Size = UDim2.new(1, 0, 0, 30)}, 0.25)
                end
            end

            subLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if isExpanded then UpdateModHeight() end
            end)

            -- 开关功能逻辑
            local function ToggleModuleState()
                module.Enabled = not module.Enabled
                if module.Enabled then
                    Tween(modFrame, {BackgroundColor3 = Theme.CardActive}, 0.2)
                    Tween(modBtn, {TextColor3 = Theme.TextBlue}, 0.2)
                    modStroke.Color = Theme.AccentBlue
                else
                    Tween(modFrame, {BackgroundColor3 = Theme.CardBg}, 0.2)
                    Tween(modBtn, {TextColor3 = Theme.TextDark}, 0.2)
                    modStroke.Color = Theme.BorderColor
                end

                VapeLib:Notify({
                    Title = modName,
                    Content = module.Enabled and "已开启 (Enabled)" or "已关闭 (Disabled)",
                    Duration = 2
                })

                callback(module.Enabled)
            end

            modBtn.MouseButton1Click:Connect(function()
                CreateRipple(modFrame, UserInputService:GetMouseLocation())
                ToggleModuleState()
            end)

            -- 快捷键绑定触发逻辑
            local listeningKey = false
            keybindBtn.MouseButton1Click:Connect(function()
                listeningKey = true
                keybindBtn.Text = "..."
                keybindBtn.TextColor3 = Theme.AccentBlue
            end)

            UserInputService.InputBegan:Connect(function(input, gpe)
                if listeningKey and not gpe then
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        module.Keybound = input.KeyCode
                        keybindBtn.Text = string.sub(input.KeyCode.Name, 1, 3)
                        keybindBtn.TextColor3 = Theme.TextBlue
                        listeningKey = false

                        VapeLib:Notify({
                            Title = "快捷键设置",
                            Content = modName .. " 绑定至: " .. input.KeyCode.Name,
                            Duration = 2.5
                        })
                    end
                elseif not gpe and module.Keybound and input.KeyCode == module.Keybound then
                    CreateRipple(modFrame, modFrame.AbsolutePosition + Vector2.new(20, 15))
                    ToggleModuleState()
                end
            end)

            moreBtn.MouseButton1Click:Connect(function()
                isExpanded = not isExpanded
                Tween(moreBtn, {TextColor3 = isExpanded and Theme.AccentBlue or Theme.TextDark}, 0.2)
                UpdateModHeight()
            end)

            -- --------------------------------------------------------
            -- 📂 子配置: Dropdown (折叠下拉模式选择器)
            -- --------------------------------------------------------
            function module:AddDropdown(dpName, options, defaultOpt, dpCallback)
                dpCallback = dpCallback or function() end
                options = options or {}
                local currentOpt = defaultOpt or options[1] or "None"

                local dpFrame = Instance.new("Frame")
                dpFrame.Size = UDim2.new(1, 0, 0, 26)
                dpFrame.BackgroundColor3 = Theme.HeaderBg
                dpFrame.ClipsDescendants = true
                dpFrame.BorderSizePixel = 0
                dpFrame.Parent = subContainer

                local dpBtn = Instance.new("TextButton")
                dpBtn.Size = UDim2.new(1, 0, 0, 26)
                dpBtn.BackgroundTransparency = 1
                dpBtn.Text = ""
                dpBtn.Parent = dpFrame

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(0.5, 0, 0, 26)
                label.Position = UDim2.new(0, 4, 0, 0)
                label.Text = dpName
                label.TextColor3 = Theme.TextDark
                label.Font = Enum.Font.Gotham
                label.TextSize = 10
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.BackgroundTransparency = 1
                label.Parent = dpFrame

                local valLabel = Instance.new("TextLabel")
                valLabel.Size = UDim2.new(0.45, -15, 0, 26)
                valLabel.Position = UDim2.new(0.5, 0, 0, 0)
                valLabel.Text = currentOpt
                valLabel.TextColor3 = Theme.TextBlue
                valLabel.Font = Enum.Font.GothamBold
                valLabel.TextSize = 10
                valLabel.TextXAlignment = Enum.TextXAlignment.Right
                valLabel.BackgroundTransparency = 1
                valLabel.Parent = dpFrame

                local arrow = Instance.new("TextLabel")
                arrow.Size = UDim2.new(0, 15, 0, 26)
                arrow.Position = UDim2.new(1, -15, 0, 0)
                arrow.Text = "▼"
                arrow.TextColor3 = Theme.TextDark
                arrow.Font = Enum.Font.Gotham
                arrow.TextSize = 8
                arrow.BackgroundTransparency = 1
                arrow.Parent = dpFrame

                -- 选项容器
                local optContainer = Instance.new("Frame")
                optContainer.Size = UDim2.new(1, -8, 0, 0)
                optContainer.Position = UDim2.new(0, 4, 0, 28)
                optContainer.BackgroundTransparency = 1
                optContainer.Parent = dpFrame

                local optLayout = Instance.new("UIListLayout")
                optLayout.SortOrder = Enum.SortOrder.LayoutOrder
                optLayout.Padding = UDim.new(0, 3)
                optLayout.Parent = optContainer

                local dpOpen = false
                local function UpdateDpHeight()
                    if dpOpen then
                        local h = optLayout.AbsoluteContentSize.Y + 32
                        Tween(dpFrame, {Size = UDim2.new(1, 0, 0, h)}, 0.2)
                        Tween(arrow, {Rotation = 180}, 0.2)
                    else
                        Tween(dpFrame, {Size = UDim2.new(1, 0, 0, 26)}, 0.2)
                        Tween(arrow, {Rotation = 0}, 0.2)
                    end
                end

                for _, optText in ipairs(options) do
                    local optBtn = Instance.new("TextButton")
                    optBtn.Size = UDim2.new(1, 0, 0, 20)
                    optBtn.BackgroundColor3 = Theme.CardBg
                    optBtn.Text = optText
                    optBtn.TextColor3 = Theme.TextDark
                    optBtn.Font = Enum.Font.Gotham
                    optBtn.TextSize = 9
                    optBtn.BorderSizePixel = 0
                    optBtn.Parent = optContainer

                    optBtn.MouseButton1Click:Connect(function()
                        CreateRipple(optBtn, UserInputService:GetMouseLocation())
                        currentOpt = optText
                        valLabel.Text = currentOpt
                        dpOpen = false
                        UpdateDpHeight()
                        dpCallback(currentOpt)
                    end)
                end

                dpBtn.MouseButton1Click:Connect(function()
                    dpOpen = not dpOpen
                    UpdateDpHeight()
                end)
            end

            -- --------------------------------------------------------
            -- 🎚️ 子配置: Slider (拉条)
            -- --------------------------------------------------------
            function module:AddSlider(sName, min, max, default, sCallback)
                sCallback = sCallback or function() end
                local val = default or min

                local sliderFrame = Instance.new("Frame")
                sliderFrame.Size = UDim2.new(1, 0, 0, 32)
                sliderFrame.BackgroundColor3 = Theme.HeaderBg
                sliderFrame.BorderSizePixel = 0
                sliderFrame.Parent = subContainer

                local sLabel = Instance.new("TextLabel")
                sLabel.Size = UDim2.new(0.6, 0, 0, 15)
                sLabel.Position = UDim2.new(0, 4, 0, 2)
                sLabel.Text = sName
                sLabel.TextColor3 = Theme.TextDark
                sLabel.Font = Enum.Font.Gotham
                sLabel.TextSize = 10
                sLabel.TextXAlignment = Enum.TextXAlignment.Left
                sLabel.BackgroundTransparency = 1
                sLabel.Parent = sliderFrame

                local vLabel = Instance.new("TextLabel")
                vLabel.Size = UDim2.new(0.35, 0, 0, 15)
                vLabel.Position = UDim2.new(0.6, 0, 0, 2)
                vLabel.Text = tostring(val)
                vLabel.TextColor3 = Theme.TextBlue
                vLabel.Font = Enum.Font.GothamBold
                vLabel.TextSize = 10
                vLabel.TextXAlignment = Enum.TextXAlignment.Right
                vLabel.BackgroundTransparency = 1
                vLabel.Parent = sliderFrame

                local bar = Instance.new("Frame")
                bar.Size = UDim2.new(1, -8, 0, 5)
                bar.Position = UDim2.new(0, 4, 0, 20)
                bar.BackgroundColor3 = Color3.fromRGB(205, 218, 235)
                bar.BorderSizePixel = 0
                bar.Parent = sliderFrame

                local fill = Instance.new("Frame")
                fill.Size = UDim2.new((val - min)/(max - min), 0, 1, 0)
                fill.BackgroundColor3 = Theme.AccentBlue
                fill.BorderSizePixel = 0
                fill.Parent = bar

                local dragging = false
                local function ProcessInput(input)
                    local pos = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                    local cur = math.floor(min + (max - min) * pos)
                    vLabel.Text = tostring(cur)
                    Tween(fill, {Size = UDim2.new(pos, 0, 1, 0)}, 0.05)
                    sCallback(cur)
                end

                bar.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true; ProcessInput(input)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then ProcessInput(input) end
                end)
            end

            -- --------------------------------------------------------
            -- 📝 子配置: TextBox (文本输入)
            -- --------------------------------------------------------
            function module:AddTextBox(tName, placeholder, tCallback)
                tCallback = tCallback or function() end

                local boxFrame = Instance.new("Frame")
                boxFrame.Size = UDim2.new(1, 0, 0, 24)
                boxFrame.BackgroundColor3 = Theme.HeaderBg
                boxFrame.BorderSizePixel = 0
                boxFrame.Parent = subContainer

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(0.45, 0, 1, 0)
                label.Position = UDim2.new(0, 4, 0, 0)
                label.Text = tName
                label.TextColor3 = Theme.TextDark
                label.Font = Enum.Font.Gotham
                label.TextSize = 10
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.BackgroundTransparency = 1
                label.Parent = boxFrame

                local box = Instance.new("TextBox")
                box.Size = UDim2.new(0.5, 0, 0.75, 0)
                box.Position = UDim2.new(0.48, 0, 0.12, 0)
                box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                box.Text = ""
                box.PlaceholderText = placeholder or "..."
                box.TextColor3 = Theme.TextBlue
                box.Font = Enum.Font.Gotham
                box.TextSize = 10
                box.BorderSizePixel = 0
                box.Parent = boxFrame

                local bStroke = Instance.new("UIStroke")
                bStroke.Thickness = 1
                bStroke.Color = Theme.BorderColor
                bStroke.Parent = box

                box.FocusLost:Connect(function(e) tCallback(box.Text, e) end)
            end

            -- --------------------------------------------------------
            -- 🔘 子配置: Sub-Toggle (子开关)
            -- --------------------------------------------------------
            function module:AddToggle(subName, default, subCb)
                subCb = subCb or function() end
                local state = default or false

                local togFrame = Instance.new("Frame")
                togFrame.Size = UDim2.new(1, 0, 0, 22)
                togFrame.BackgroundColor3 = Theme.HeaderBg
                togFrame.BorderSizePixel = 0
                togFrame.Parent = subContainer

                local tBtn = Instance.new("TextButton")
                tBtn.Size = UDim2.new(1, 0, 1, 0)
                tBtn.BackgroundTransparency = 1
                tBtn.Text = ""
                tBtn.Parent = togFrame

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(0.7, 0, 1, 0)
                label.Position = UDim2.new(0, 4, 0, 0)
                label.Text = subName
                label.TextColor3 = Theme.TextDark
                label.Font = Enum.Font.Gotham
                label.TextSize = 10
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.BackgroundTransparency = 1
                label.Parent = togFrame

                local dot = Instance.new("Frame")
                dot.Size = UDim2.new(0, 12, 0, 12)
                dot.Position = UDim2.new(1, -16, 0.5, -6)
                dot.BackgroundColor3 = state and Theme.AccentBlue or Color3.fromRGB(195, 208, 225)
                dot.BorderSizePixel = 0
                dot.Parent = togFrame

                tBtn.MouseButton1Click:Connect(function()
                    CreateRipple(togFrame, UserInputService:GetMouseLocation())
                    state = not state
                    Tween(dot, {BackgroundColor3 = state and Theme.AccentBlue or Color3.fromRGB(195, 208, 225)}, 0.15)
                    subCb(state)
                end)
            end

            return module
        end

        return tab
    end

    return window
end

return VapeLib