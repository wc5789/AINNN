-- ====================================================================
--  Vape V4 SciFi Pro UI Library (Large Corner & Slice Cut & QuickBtn)
--  Design: SciFi Font, Large UICorner, Laser Slice Popups, Quick Button Generator
--  Author: DeepSeek-Girl for Master
-- ====================================================================

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local VapeLib = {}
VapeLib.__index = VapeLib

-- 🩵 冰纯白 - 电光蓝 大圆角科技配色 🩵
local Theme = {
    MainBg       = Color3.fromRGB(248, 251, 255),
    CategoryBg   = Color3.fromRGB(252, 254, 255),
    HeaderBg     = Color3.fromRGB(230, 240, 255),
    CardBg       = Color3.fromRGB(222, 233, 250),
    CardActive   = Color3.fromRGB(200, 222, 255),
    AccentBlue   = Color3.fromRGB(0, 150, 255),
    GlowBlue     = Color3.fromRGB(90, 205, 255),
    RippleColor  = Color3.fromRGB(80, 180, 255),
    TextDark     = Color3.fromRGB(20, 35, 60),
    TextBlue     = Color3.fromRGB(0, 120, 235),
    BorderColor  = Color3.fromRGB(195, 215, 242),
    
    -- 红绿灯配色
    LightRed     = Color3.fromRGB(255, 65, 65),
    LightGreen   = Color3.fromRGB(0, 225, 120)
}

-- 统一 SciFi 字体与圆角参数
local GLOBAL_FONT = Enum.Font.SciFi
local CORNER_RADIUS = UDim.new(0, 11)

-- 平滑 Tween 动画辅助函数
local function Tween(inst, props, duration, style, dir)
    local info = TweenInfo.new(duration or 0.22, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out)
    local t = TweenService:Create(inst, info, props)
    t:Play()
    return t
end

-- 🌊 点击水波纹效果 (Ripple Effect)
local function CreateRipple(parentObj, inputPos)
    local ripple = Instance.new("Frame")
    ripple.Name = "Ripple"
    ripple.AnchorPoint = Vector2.new(0.5, 0.5)
    ripple.BackgroundColor3 = Theme.RippleColor
    ripple.BackgroundTransparency = 0.4
    ripple.BorderSizePixel = 0
    ripple.ZIndex = 8

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(1, 0)
    corner.Parent = ripple

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
    }, 0.5, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)

    tw.Completed:Connect(function() ripple:Destroy() end)
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
        uiGradient.Rotation = (uiGradient.Rotation + 1.8) % 360
    end)
end

-- 拖拽算法
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
            Tween(gui, {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)}, 0.05)
        end
    end)
end

-- ====================================================================
--  UI Library 核心主类
-- ====================================================================
function VapeLib:CreateWindow(libTitle)
    local window = {}

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "VapeV4SciFi_" .. math.random(1000, 9999)
    screenGui.ResetOnSpawn = false

    if gethui then screenGui.Parent = gethui()
    elseif syn and syn.protect_gui then syn.protect_gui(screenGui); screenGui.Parent = CoreGui
    else screenGui.Parent = CoreGui end

    -- 快捷按钮 (Quick Button) 专属放置浮层 Container
    local quickBtnHolder = Instance.new("Frame")
    quickBtnHolder.Name = "QuickBtnHolder"
    quickBtnHolder.Size = UDim2.new(1, 0, 1, 0)
    quickBtnHolder.BackgroundTransparency = 1
    quickBtnHolder.Parent = screenGui

    -- ✂️ 弹窗通知容器 (Notification Holder)
    local notifyHolder = Instance.new("Frame")
    notifyHolder.Name = "NotifyHolder"
    notifyHolder.Size = UDim2.new(0, 230, 1, -20)
    notifyHolder.Position = UDim2.new(1, -240, 0, 10)
    notifyHolder.BackgroundTransparency = 1
    notifyHolder.Parent = screenGui

    local notifyLayout = Instance.new("UIListLayout")
    notifyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    notifyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    notifyLayout.Padding = UDim.new(0, 8)
    notifyLayout.Parent = notifyHolder

    -- ✂️ 激光切断式弹窗 (Laser Slice Cut Notification)
    function VapeLib:Notify(cfg)
        local title = cfg.Title or "System"
        local content = cfg.Content or ""
        local duration = cfg.Duration or 2.5

        local card = Instance.new("Frame")
        card.Size = UDim2.new(0, 0, 0, 48) -- 初始宽 0 (切断状态)
        card.BackgroundColor3 = Theme.MainBg
        card.BorderSizePixel = 0
        card.ClipsDescendants = true
        card.Parent = notifyHolder

        local corner = Instance.new("UICorner")
        corner.CornerRadius = CORNER_RADIUS
        corner.Parent = card

        local stroke = Instance.new("UIStroke")
        stroke.Thickness = 1.5
        stroke.Color = Theme.AccentBlue
        stroke.Parent = card
        AddFlowingLight(stroke)

        local tLabel = Instance.new("TextLabel")
        tLabel.Size = UDim2.new(1, -12, 0, 20)
        tLabel.Position = UDim2.new(0, 10, 0, 4)
        tLabel.Text = title
        tLabel.TextColor3 = Theme.TextBlue
        tLabel.Font = GLOBAL_FONT
        tLabel.TextSize = 13
        tLabel.TextXAlignment = Enum.TextXAlignment.Left
        tLabel.BackgroundTransparency = 1
        tLabel.Parent = card

        local cLabel = Instance.new("TextLabel")
        cLabel.Size = UDim2.new(1, -12, 0, 20)
        cLabel.Position = UDim2.new(0, 10, 0, 22)
        cLabel.Text = content
        cLabel.TextColor3 = Theme.TextDark
        cLabel.Font = GLOBAL_FONT
        cLabel.TextSize = 11
        cLabel.TextXAlignment = Enum.TextXAlignment.Left
        cLabel.BackgroundTransparency = 1
        cLabel.Parent = card

        -- 🎬 激光极速切入展开 (Slice Cut In)
        Tween(card, {Size = UDim2.new(1, 0, 0, 48)}, 0.16, Enum.EasingStyle.Quad, Enum.EasingDirection.Out)

        task.delay(duration, function()
            -- 🎬 极速切断闭合 (Slice Cut Out)
            local tw = Tween(card, {Size = UDim2.new(0, 0, 0, 48)}, 0.14, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
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
    toggleBall.Font = GLOBAL_FONT
    toggleBall.TextSize = 12
    toggleBall.BorderSizePixel = 0
    toggleBall.ClipsDescendants = true
    toggleBall.Parent = screenGui

    local ballCorner = Instance.new("UICorner")
    ballCorner.CornerRadius = UDim.new(1, 0)
    ballCorner.Parent = toggleBall

    local ballStroke = Instance.new("UIStroke")
    ballStroke.Thickness = 2
    ballStroke.Color = Theme.AccentBlue
    ballStroke.Parent = toggleBall
    AddFlowingLight(ballStroke)
    MakeDraggable(toggleBall)

    -- 📏 主控制栏 Frame ( Main Hub Bar )
    local mainBar = Instance.new("Frame")
    mainBar.Name = "MainHubBar"
    mainBar.Size = UDim2.new(0, 180, 0, 42)
    mainBar.Position = UDim2.new(0.5, -90, 0.05, 0)
    mainBar.BackgroundColor3 = Theme.MainBg
    mainBar.BorderSizePixel = 0
    mainBar.ClipsDescendants = true
    mainBar.Parent = screenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = CORNER_RADIUS
    mainCorner.Parent = mainBar

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Thickness = 1.5
    mainStroke.Color = Theme.AccentBlue
    mainStroke.Parent = mainBar
    AddFlowingLight(mainStroke)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0, 85, 1, 0)
    titleLabel.Position = UDim2.new(0, 12, 0, 0)
    titleLabel.Text = libTitle or "VAPE v4"
    titleLabel.TextColor3 = Theme.TextDark
    titleLabel.Font = GLOBAL_FONT
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.BackgroundTransparency = 1
    titleLabel.Parent = mainBar

    -- Tab 放置横栏 ScrollingFrame
    local tabScroll = Instance.new("ScrollingFrame")
    tabScroll.Size = UDim2.new(1, -95, 1, -8)
    tabScroll.Position = UDim2.new(0, 90, 0, 4)
    tabScroll.BackgroundTransparency = 1
    tabScroll.ScrollBarThickness = 0
    tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
    tabScroll.Parent = mainBar

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 6)
    tabLayout.Parent = tabScroll

    MakeDraggable(mainBar)

    -- 主栏尺寸自适应
    local function RecalculateMainBarWidth()
        task.wait()
        local contentWidth = tabLayout.AbsoluteContentSize.X
        local maxAllowedWidth = math.min(workspace.CurrentCamera.ViewportSize.X - 30, 650)
        local targetWidth = math.clamp(contentWidth + 105, 180, maxAllowedWidth)

        Tween(mainBar, {
            Size = UDim2.new(0, targetWidth, 0, 42),
            Position = UDim2.new(0.5, -targetWidth/2, mainBar.Position.Y.Scale, mainBar.Position.Y.Offset)
        }, 0.22)
    end

    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(RecalculateMainBarWidth)

    -- 显隐 UI
    local uiVisible = true
    local function ToggleGlobalUI()
        uiVisible = not uiVisible
        mainBar.Visible = uiVisible
        for _, catWin in pairs(window.CategoryWindows) do
            if catWin.IsOpen then catWin.Frame.Visible = uiVisible end
        end
    end

    toggleBall.MouseButton1Click:Connect(function()
        CreateRipple(toggleBall, UserInputService:GetMouseLocation())
        ToggleGlobalUI()
    end)

    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == Enum.KeyCode.RightControl then ToggleGlobalUI() end
    end)

    window.CategoryWindows = {}
    local windowOffsetCount = 0

    -- ================================================================
    --  创建 Tab (对应独立的 Category 窗口)
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
        tabBtn.Font = GLOBAL_FONT
        tabBtn.TextSize = 11
        tabBtn.BorderSizePixel = 0
        tabBtn.AutoButtonColor = false
        tabBtn.ClipsDescendants = true
        tabBtn.Parent = tabScroll

        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 8)
        tabCorner.Parent = tabBtn

        local tabStroke = Instance.new("UIStroke")
        tabStroke.Thickness = 1
        tabStroke.Color = Theme.BorderColor
        tabStroke.Parent = tabBtn

        -- 悬停动画
        tabBtn.MouseEnter:Connect(function()
            if not tab.IsOpen then Tween(tabBtn, {BackgroundColor3 = Theme.CardActive}, 0.15) end
        end)
        tabBtn.MouseLeave:Connect(function()
            if not tab.IsOpen then Tween(tabBtn, {BackgroundColor3 = Theme.HeaderBg}, 0.15) end
        end)

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

        local catCorner = Instance.new("UICorner")
        catCorner.CornerRadius = CORNER_RADIUS
        catCorner.Parent = catFrame

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

        local catHeaderCorner = Instance.new("UICorner")
        catHeaderCorner.CornerRadius = CORNER_RADIUS
        catHeaderCorner.Parent = catHeader

        local catTitle = Instance.new("TextLabel")
        catTitle.Size = UDim2.new(1, -10, 1, 0)
        catTitle.Position = UDim2.new(0, 10, 0, 0)
        catTitle.Text = tabName
        catTitle.TextColor3 = Theme.TextDark
        catTitle.Font = GLOBAL_FONT
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

        -- 🎭 悬浮窗属性变换开场动画 (Property Transform Opening Animation)
        tabBtn.MouseButton1Click:Connect(function()
            CreateRipple(tabBtn, UserInputService:GetMouseLocation())
            catObj.IsOpen = not catObj.IsOpen
            tab.IsOpen = catObj.IsOpen

            if catObj.IsOpen then
                catFrame.Visible = true
                -- 初始形变状态: 缩小 + 下移 + 透明
                catFrame.Size = UDim2.new(0, frameWidth * 0.7, 0, 0)
                catFrame.BackgroundTransparency = 0.6
                catHeaderLine.Size = UDim2.new(0, 0, 0, 2)

                -- 爆破式展开 + 极光线条延展
                Tween(catFrame, {Size = UDim2.new(0, frameWidth, 0, 360), BackgroundTransparency = 0}, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
                Tween(catHeaderLine, {Size = UDim2.new(1, 0, 0, 2)}, 0.4)
                Tween(tabBtn, {BackgroundColor3 = Theme.AccentBlue, TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
                catStroke.Color = Theme.AccentBlue
            else
                -- 坍塌收缩
                Tween(catHeaderLine, {Size = UDim2.new(0, 0, 0, 2)}, 0.15)
                Tween(catFrame, {Size = UDim2.new(0, frameWidth * 0.7, 0, 0), BackgroundTransparency = 0.8}, 0.2, Enum.EasingStyle.Quart, Enum.EasingDirection.In).Completed:Connect(function()
                    if not catObj.IsOpen then catFrame.Visible = false end
                end)
                Tween(tabBtn, {BackgroundColor3 = Theme.HeaderBg, TextColor3 = Theme.TextDark}, 0.2)
                catStroke.Color = Theme.BorderColor
            end
        end)

        RecalculateMainBarWidth()

        -- ============================================================
        --  创建功能模块 (🔴➔🟢 红绿灯快捷按钮生成系统)
        -- ============================================================
        function tab:CreateModule(modName, callback)
            callback = callback or function() end
            local module = { Enabled = false, QuickBtnActive = false, SpawnedQuickBtn = nil }

            local modFrame = Instance.new("Frame")
            modFrame.Name = modName .. "_Module"
            modFrame.Size = UDim2.new(1, 0, 0, 32)
            modFrame.BackgroundColor3 = Theme.CardBg
            modFrame.ClipsDescendants = true
            modFrame.BorderSizePixel = 0
            modFrame.Parent = catScroll

            local modCorner = Instance.new("UICorner")
            modCorner.CornerRadius = UDim.new(0, 8)
            modCorner.Parent = modFrame

            local modStroke = Instance.new("UIStroke")
            modStroke.Thickness = 1
            modStroke.Color = Theme.BorderColor
            modStroke.Parent = modFrame

            -- 🔴 ➔ 🟢 红绿灯快捷键生成按钮
            local lightBtn = Instance.new("TextButton")
            lightBtn.Name = "QuickLightBtn"
            lightBtn.Size = UDim2.new(0, 14, 0, 14)
            lightBtn.Position = UDim2.new(0, 8, 0, 9)
            lightBtn.BackgroundColor3 = Theme.LightRed -- 初始红灯
            lightBtn.Text = ""
            lightBtn.BorderSizePixel = 0
            lightBtn.Parent = modFrame

            local lightCorner = Instance.new("UICorner")
            lightCorner.CornerRadius = UDim.new(1, 0)
            lightCorner.Parent = lightBtn

            local lightStroke = Instance.new("UIStroke")
            lightStroke.Thickness = 1
            lightStroke.Color = Theme.BorderColor
            lightStroke.Parent = lightBtn

            -- 模块主 Title Button
            local modBtn = Instance.new("TextButton")
            modBtn.Size = UDim2.new(1, -60, 0, 32)
            modBtn.Position = UDim2.new(0, 28, 0, 0)
            modBtn.BackgroundTransparency = 1
            modBtn.Text = modName
            modBtn.TextColor3 = Theme.TextDark
            modBtn.Font = GLOBAL_FONT
            modBtn.TextSize = 11
            modBtn.TextXAlignment = Enum.TextXAlignment.Left
            modBtn.ClipsDescendants = true
            modBtn.Parent = modFrame

            -- “...” 详细展开按钮
            local moreBtn = Instance.new("TextButton")
            moreBtn.Size = UDim2.new(0, 26, 0, 32)
            moreBtn.Position = UDim2.new(1, -28, 0, 0)
            moreBtn.Text = "•••"
            moreBtn.TextColor3 = Theme.TextDark
            moreBtn.Font = GLOBAL_FONT
            moreBtn.TextSize = 10
            moreBtn.BackgroundTransparency = 1
            moreBtn.Parent = modFrame

            -- 子菜单 Container
            local subContainer = Instance.new("Frame")
            subContainer.Size = UDim2.new(1, -12, 0, 0)
            subContainer.Position = UDim2.new(0, 6, 0, 34)
            subContainer.BackgroundTransparency = 1
            subContainer.Parent = modFrame

            local subLayout = Instance.new("UIListLayout")
            subLayout.SortOrder = Enum.SortOrder.LayoutOrder
            subLayout.Padding = UDim.new(0, 5)
            subLayout.Parent = subContainer

            local isExpanded = false

            local function UpdateModHeight()
                if isExpanded then
                    local h = subLayout.AbsoluteContentSize.Y + 38
                    Tween(modFrame, {Size = UDim2.new(1, 0, 0, h)}, 0.22)
                else
                    Tween(modFrame, {Size = UDim2.new(1, 0, 0, 32)}, 0.22)
                end
            end

            subLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if isExpanded then UpdateModHeight() end
            end)

            -- 核心：切换模块开启/关闭状态 (状态同步)
            local function SetModuleState(state)
                module.Enabled = state
                if module.Enabled then
                    Tween(modFrame, {BackgroundColor3 = Theme.CardActive}, 0.2)
                    Tween(modBtn, {TextColor3 = Theme.TextBlue}, 0.2)
                    modStroke.Color = Theme.AccentBlue
                else
                    Tween(modFrame, {BackgroundColor3 = Theme.CardBg}, 0.2)
                    Tween(modBtn, {TextColor3 = Theme.TextDark}, 0.2)
                    modStroke.Color = Theme.BorderColor
                end

                -- 同步更新生成的悬浮 Quick Button 视觉状态
                if module.SpawnedQuickBtn then
                    local qIndicator = module.SpawnedQuickBtn:FindFirstChild("Indicator")
                    if qIndicator then
                        Tween(qIndicator, {BackgroundColor3 = module.Enabled and Theme.AccentBlue or Theme.CardBg}, 0.2)
                    end
                end

                VapeLib:Notify({
                    Title = modName,
                    Content = module.Enabled and "已开启 (ON)" or "已关闭 (OFF)",
                    Duration = 2
                })

                callback(module.Enabled)
            end

            modBtn.MouseButton1Click:Connect(function()
                CreateRipple(modFrame, UserInputService:GetMouseLocation())
                SetModuleState(not module.Enabled)
            end)

            -- 🔴 ➔ 🟢 点击红灯，生成/销毁 独立悬浮快捷键 Button (Quick Button)
            lightBtn.MouseButton1Click:Connect(function()
                module.QuickBtnActive = not module.QuickBtnActive

                if module.QuickBtnActive then
                    -- 红灯变绿灯
                    Tween(lightBtn, {BackgroundColor3 = Theme.LightGreen}, 0.2)

                    -- 屏幕上动态生成独立悬浮 Quick Button
                    local qBtn = Instance.new("TextButton")
                    qBtn.Name = "QuickBtn_" .. modName
                    qBtn.Size = UDim2.new(0, 110, 0, 32)
                    qBtn.Position = UDim2.new(0.8, 0, 0.3 + (math.random(0, 20)*0.01), 0)
                    qBtn.BackgroundColor3 = Theme.MainBg
                    qBtn.Text = "  " .. modName
                    qBtn.TextColor3 = Theme.TextDark
                    qBtn.Font = GLOBAL_FONT
                    qBtn.TextSize = 10
                    qBtn.BorderSizePixel = 0
                    qBtn.ClipsDescendants = true
                    qBtn.Parent = quickBtnHolder

                    local qCorner = Instance.new("UICorner")
                    qCorner.CornerRadius = CORNER_RADIUS
                    qCorner.Parent = qBtn

                    local qStroke = Instance.new("UIStroke")
                    qStroke.Thickness = 1.5
                    qStroke.Color = Theme.AccentBlue
                    qStroke.Parent = qBtn
                    AddFlowingLight(qStroke)

                    local qIndicator = Instance.new("Frame")
                    qIndicator.Name = "Indicator"
                    qIndicator.Size = UDim2.new(0, 8, 0, 8)
                    qIndicator.Position = UDim2.new(1, -14, 0.5, -4)
                    qIndicator.BackgroundColor3 = module.Enabled and Theme.AccentBlue or Theme.CardBg
                    qIndicator.BorderSizePixel = 0
                    qIndicator.Parent = qBtn

                    local qiCorner = Instance.new("UICorner")
                    qiCorner.CornerRadius = UDim.new(1, 0)
                    qiCorner.Parent = qIndicator

                    MakeDraggable(qBtn)
                    module.SpawnedQuickBtn = qBtn

                    -- 快捷按钮 Pop-in 动画
                    qBtn.Size = UDim2.new(0, 0, 0, 0)
                    Tween(qBtn, {Size = UDim2.new(0, 110, 0, 32)}, 0.25, Enum.EasingStyle.Back)

                    -- 点击快捷按钮直接 Toggle 功能！
                    qBtn.MouseButton1Click:Connect(function()
                        CreateRipple(qBtn, UserInputService:GetMouseLocation())
                        SetModuleState(not module.Enabled)
                    end)

                    VapeLib:Notify({ Title = "快捷键生成", Content = "已在屏幕上生成 [" .. modName .. "] 快捷按钮", Duration = 2 })
                else
                    -- 绿灯变红灯，销毁快捷按钮
                    Tween(lightBtn, {BackgroundColor3 = Theme.LightRed}, 0.2)
                    if module.SpawnedQuickBtn then
                        local targetBtn = module.SpawnedQuickBtn
                        module.SpawnedQuickBtn = nil
                        Tween(targetBtn, {Size = UDim2.new(0, 0, 0, 0)}, 0.2).Completed:Connect(function()
                            targetBtn:Destroy()
                        end)
                    end
                end
            end)

            moreBtn.MouseButton1Click:Connect(function()
                isExpanded = not isExpanded
                Tween(moreBtn, {TextColor3 = isExpanded and Theme.AccentBlue or Theme.TextDark}, 0.2)
                UpdateModHeight()
            end)

            -- --------------------------------------------------------
            -- 📂 子配置: Dropdown (下拉选择器)
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

                local dpCorner = Instance.new("UICorner")
                dpCorner.CornerRadius = UDim.new(0, 6)
                dpCorner.Parent = dpFrame

                local dpBtn = Instance.new("TextButton")
                dpBtn.Size = UDim2.new(1, 0, 0, 26)
                dpBtn.BackgroundTransparency = 1
                dpBtn.Text = ""
                dpBtn.Parent = dpFrame

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(0.5, 0, 0, 26)
                label.Position = UDim2.new(0, 6, 0, 0)
                label.Text = dpName
                label.TextColor3 = Theme.TextDark
                label.Font = GLOBAL_FONT
                label.TextSize = 10
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.BackgroundTransparency = 1
                label.Parent = dpFrame

                local valLabel = Instance.new("TextLabel")
                valLabel.Size = UDim2.new(0.45, -15, 0, 26)
                valLabel.Position = UDim2.new(0.5, 0, 0, 0)
                valLabel.Text = currentOpt
                valLabel.TextColor3 = Theme.TextBlue
                valLabel.Font = GLOBAL_FONT
                valLabel.TextSize = 10
                valLabel.TextXAlignment = Enum.TextXAlignment.Right
                valLabel.BackgroundTransparency = 1
                valLabel.Parent = dpFrame

                local arrow = Instance.new("TextLabel")
                arrow.Size = UDim2.new(0, 15, 0, 26)
                arrow.Position = UDim2.new(1, -15, 0, 0)
                arrow.Text = "▼"
                arrow.TextColor3 = Theme.TextDark
                arrow.Font = GLOBAL_FONT
                arrow.TextSize = 8
                arrow.BackgroundTransparency = 1
                arrow.Parent = dpFrame

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
                    optBtn.Font = GLOBAL_FONT
                    optBtn.TextSize = 9
                    optBtn.BorderSizePixel = 0
                    optBtn.Parent = optContainer

                    local optCorner = Instance.new("UICorner")
                    optCorner.CornerRadius = UDim.new(0, 4)
                    optCorner.Parent = optBtn

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

                local sCorner = Instance.new("UICorner")
                sCorner.CornerRadius = UDim.new(0, 6)
                sCorner.Parent = sliderFrame

                local sLabel = Instance.new("TextLabel")
                sLabel.Size = UDim2.new(0.6, 0, 0, 15)
                sLabel.Position = UDim2.new(0, 6, 0, 2)
                sLabel.Text = sName
                sLabel.TextColor3 = Theme.TextDark
                sLabel.Font = GLOBAL_FONT
                sLabel.TextSize = 10
                sLabel.TextXAlignment = Enum.TextXAlignment.Left
                sLabel.BackgroundTransparency = 1
                sLabel.Parent = sliderFrame

                local vLabel = Instance.new("TextLabel")
                vLabel.Size = UDim2.new(0.35, 0, 0, 15)
                vLabel.Position = UDim2.new(0.6, 0, 0, 2)
                vLabel.Text = tostring(val)
                vLabel.TextColor3 = Theme.TextBlue
                vLabel.Font = GLOBAL_FONT
                vLabel.TextSize = 10
                vLabel.TextXAlignment = Enum.TextXAlignment.Right
                vLabel.BackgroundTransparency = 1
                vLabel.Parent = sliderFrame

                local bar = Instance.new("Frame")
                bar.Size = UDim2.new(1, -12, 0, 5)
                bar.Position = UDim2.new(0, 6, 0, 20)
                bar.BackgroundColor3 = Color3.fromRGB(205, 218, 235)
                bar.BorderSizePixel = 0
                bar.Parent = sliderFrame

                local bCorner = Instance.new("UICorner")
                bCorner.CornerRadius = UDim.new(1, 0)
                bCorner.Parent = bar

                local fill = Instance.new("Frame")
                fill.Size = UDim2.new((val - min)/(max - min), 0, 1, 0)
                fill.BackgroundColor3 = Theme.AccentBlue
                fill.BorderSizePixel = 0
                fill.Parent = bar

                local fCorner = Instance.new("UICorner")
                fCorner.CornerRadius = UDim.new(1, 0)
                fCorner.Parent = fill

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
            -- 📝 子配置: TextBox (文本框)
            -- --------------------------------------------------------
            function module:AddTextBox(tName, placeholder, tCallback)
                tCallback = tCallback or function() end

                local boxFrame = Instance.new("Frame")
                boxFrame.Size = UDim2.new(1, 0, 0, 24)
                boxFrame.BackgroundColor3 = Theme.HeaderBg
                boxFrame.BorderSizePixel = 0
                boxFrame.Parent = subContainer

                local bxCorner = Instance.new("UICorner")
                bxCorner.CornerRadius = UDim.new(0, 6)
                bxCorner.Parent = boxFrame

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(0.45, 0, 1, 0)
                label.Position = UDim2.new(0, 6, 0, 0)
                label.Text = tName
                label.TextColor3 = Theme.TextDark
                label.Font = GLOBAL_FONT
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
                box.Font = GLOBAL_FONT
                box.TextSize = 10
                box.BorderSizePixel = 0
                box.Parent = boxFrame

                local tbCorner = Instance.new("UICorner")
                tbCorner.CornerRadius = UDim.new(0, 4)
                tbCorner.Parent = box

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

                local tgCorner = Instance.new("UICorner")
                tgCorner.CornerRadius = UDim.new(0, 6)
                tgCorner.Parent = togFrame

                local tBtn = Instance.new("TextButton")
                tBtn.Size = UDim2.new(1, 0, 1, 0)
                tBtn.BackgroundTransparency = 1
                tBtn.Text = ""
                tBtn.Parent = togFrame

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(0.7, 0, 1, 0)
                label.Position = UDim2.new(0, 6, 0, 0)
                label.Text = subName
                label.TextColor3 = Theme.TextDark
                label.Font = GLOBAL_FONT
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

                local dCorner = Instance.new("UICorner")
                dCorner.CornerRadius = UDim.new(1, 0)
                dCorner.Parent = dot

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