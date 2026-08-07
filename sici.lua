-- ====================================================================
--  Vape V4 SciFi God-Tier UI Library (Bug-Free, Resizable, Full Glow)
--  Features: Geometry Resize Handle, Half-size Popups, Huge QuickBtns with Glow,
--            Square Toggles, Rectangular Glowing Sliders, Perfectly Layered!
--  Author: DeepSeek-Girl for Master
-- ====================================================================

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local VapeLib = {}
VapeLib.__index = VapeLib

-- 🩵 纯净冰蓝科技感 顶级白蓝配色 🩵
local Theme = {
    MainBg       = Color3.fromRGB(246, 250, 255),
    CategoryBg   = Color3.fromRGB(250, 253, 255),
    HeaderBg     = Color3.fromRGB(225, 237, 255),
    CardBg       = Color3.fromRGB(218, 230, 248),
    CardActive   = Color3.fromRGB(192, 218, 255),
    AccentBlue   = Color3.fromRGB(0, 160, 255),
    GlowBlue     = Color3.fromRGB(80, 215, 255),
    RippleColor  = Color3.fromRGB(100, 190, 255),
    TextDark     = Color3.fromRGB(15, 30, 55),
    TextBlue     = Color3.fromRGB(0, 110, 230),
    BorderColor  = Color3.fromRGB(185, 208, 238),
    
    -- 红绿灯
    LightRed     = Color3.fromRGB(255, 60, 60),
    LightGreen   = Color3.fromRGB(0, 220, 110)
}

local SCIFI_FONT = Enum.Font.SciFi
local LARGE_CORNER = UDim.new(0, 12)

-- 统一极速无缝动画函数
local function SmoothTween(inst, props, duration, style, dir)
    if not inst then return end
    local info = TweenInfo.new(duration or 0.2, style or Enum.EasingStyle.Quart, dir or Enum.EasingDirection.Out)
    local t = TweenService:Create(inst, info, props)
    t:Play()
    return t
end

-- 🌊 完美的水波纹效果（完全控制在父图层内）
local function CreateRipple(parentObj, inputPos)
    if not parentObj then return end
    parentObj.ClipsDescendants = true

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
    local tw = SmoothTween(ripple, {
        Size = UDim2.new(0, targetSize, 0, targetSize),
        BackgroundTransparency = 1
    }, 0.4, Enum.EasingStyle.Quart)

    tw.Completed:Connect(function() ripple:Destroy() end)
end

-- ✨ 高强度动态霓虹流光特效 (全平台优化，不掉帧)
local function ApplyFlowingGlow(instance, thickness, zIndex)
    local stroke = instance:FindFirstChildOfClass("UIStroke") or Instance.new("UIStroke")
    stroke.Thickness = thickness or 1.5
    stroke.Color = Theme.AccentBlue
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.ZIndex = zIndex or instance.ZIndex
    stroke.Parent = instance

    local uiGradient = stroke:FindFirstChildOfClass("UIGradient") or Instance.new("UIGradient")
    uiGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 160, 255)),
        ColorSequenceKeypoint.new(0.3, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.6, Color3.fromRGB(0, 215, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 160, 255))
    })
    uiGradient.Parent = stroke

    local conn
    conn = RunService.RenderStepped:Connect(function()
        if not stroke or not stroke.Parent or not stroke.Parent.Parent then
            conn:Disconnect()
            return
        end
        uiGradient.Rotation = (uiGradient.Rotation + 3) % 360
    end)
    return stroke
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
            gui.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ====================================================================
--  UI Library 核心窗口类
-- ====================================================================
function VapeLib:CreateWindow(libTitle)
    local window = {}

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "VapeV4SciFiGod_" .. math.random(1000, 9999)
    screenGui.ResetOnSpawn = false

    if gethui then screenGui.Parent = gethui()
    elseif syn and syn.protect_gui then syn.protect_gui(screenGui); screenGui.Parent = CoreGui
    else screenGui.Parent = CoreGui end

    -- 快捷按钮 (Quick Button) 专属放置层
    local quickBtnHolder = Instance.new("Frame")
    quickBtnHolder.Name = "QuickBtnHolder"
    quickBtnHolder.Size = UDim2.new(1, 0, 1, 0)
    quickBtnHolder.BackgroundTransparency = 1
    quickBtnHolder.ZIndex = 5
    quickBtnHolder.Parent = screenGui

    -- ✂️ 弹窗通知容器（宽度彻底砍半，5/10极致比例）
    local notifyHolder = Instance.new("Frame")
    notifyHolder.Name = "NotifyHolder"
    notifyHolder.Size = UDim2.new(0, 125, 1, -20) -- 砍半宽度，完美契合
    notifyHolder.Position = UDim2.new(1, -135, 0, 10)
    notifyHolder.BackgroundTransparency = 1
    notifyHolder.ZIndex = 10
    notifyHolder.Parent = screenGui

    local notifyLayout = Instance.new("UIListLayout")
    notifyLayout.SortOrder = Enum.SortOrder.LayoutOrder
    notifyLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    notifyLayout.Padding = UDim.new(0, 6)
    notifyLayout.Parent = notifyHolder

    -- ✂️ 激光切断弹窗
    local function CreateNotification(cfg)
        cfg = cfg or {}
        local title = cfg.Title or "SYSTEM"
        local content = cfg.Content or ""
        local duration = cfg.Duration or 2.2

        local card = Instance.new("Frame")
        card.Size = UDim2.new(0, 0, 0, 42) -- 高度稍微收窄，整体极度精致
        card.BackgroundColor3 = Theme.MainBg
        card.BorderSizePixel = 0
        card.ClipsDescendants = true
        card.ZIndex = 10
        card.Parent = notifyHolder

        local corner = Instance.new("UICorner")
        corner.CornerRadius = UDim.new(0, 8)
        corner.Parent = card

        ApplyFlowingGlow(card, 1.5, 10)

        local tLabel = Instance.new("TextLabel")
        tLabel.Size = UDim2.new(1, -8, 0, 16)
        tLabel.Position = UDim2.new(0, 6, 0, 4)
        tLabel.Text = title
        tLabel.TextColor3 = Theme.TextBlue
        tLabel.Font = SCIFI_FONT
        tLabel.TextSize = 11
        tLabel.TextXAlignment = Enum.TextXAlignment.Left
        tLabel.BackgroundTransparency = 1
        tLabel.ZIndex = 10
        tLabel.Parent = card

        local cLabel = Instance.new("TextLabel")
        cLabel.Size = UDim2.new(1, -8, 0, 16)
        cLabel.Position = UDim2.new(0, 6, 0, 20)
        cLabel.Text = content
        cLabel.TextColor3 = Theme.TextDark
        cLabel.Font = SCIFI_FONT
        cLabel.TextSize = 9
        cLabel.TextXAlignment = Enum.TextXAlignment.Left
        cLabel.BackgroundTransparency = 1
        cLabel.ZIndex = 10
        cLabel.Parent = card

        -- 🎬 激光展开
        SmoothTween(card, {Size = UDim2.new(1, 0, 0, 42)}, 0.15)

        task.delay(duration, function()
            -- 🎬 极速切断闭合
            local tw = SmoothTween(card, {Size = UDim2.new(0, 0, 0, 42)}, 0.12)
            if tw then
                tw.Completed:Connect(function() card:Destroy() end)
            end
        end)
    end

    window.Notify = function(self, cfg) CreateNotification(cfg) end
    VapeLib.Notify = function(self, cfg) CreateNotification(cfg) end

    -- 📱 移动端悬浮球
    local toggleBall = Instance.new("TextButton")
    toggleBall.Name = "VapeToggleBall"
    toggleBall.Size = UDim2.new(0, 42, 0, 42)
    toggleBall.Position = UDim2.new(0.04, 0, 0.12, 0)
    toggleBall.BackgroundColor3 = Theme.MainBg
    toggleBall.Text = "VAPE"
    toggleBall.TextColor3 = Theme.TextBlue
    toggleBall.Font = SCIFI_FONT
    toggleBall.TextSize = 11
    toggleBall.BorderSizePixel = 0
    toggleBall.ClipsDescendants = true
    toggleBall.ZIndex = 9
    toggleBall.Parent = screenGui

    local ballCorner = Instance.new("UICorner")
    ballCorner.CornerRadius = UDim.new(1, 0)
    ballCorner.Parent = toggleBall

    ApplyFlowingGlow(toggleBall, 2, 9)
    MakeDraggable(toggleBall)

    -- 📏 主控制栏 Frame
    local mainBar = Instance.new("Frame")
    mainBar.Name = "MainHubBar"
    mainBar.Size = UDim2.new(0, 180, 0, 42)
    mainBar.Position = UDim2.new(0.5, -90, 0.05, 0)
    mainBar.BackgroundColor3 = Theme.MainBg
    mainBar.BorderSizePixel = 0
    mainBar.ClipsDescendants = true
    mainBar.ZIndex = 6
    mainBar.Parent = screenGui

    local mainCorner = Instance.new("UICorner")
    mainCorner.CornerRadius = LARGE_CORNER
    mainCorner.Parent = mainBar

    ApplyFlowingGlow(mainBar, 1.5, 6)

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0, 85, 1, 0)
    titleLabel.Position = UDim2.new(0, 12, 0, 0)
    titleLabel.Text = libTitle or "VAPE v4"
    titleLabel.TextColor3 = Theme.TextDark
    titleLabel.Font = SCIFI_FONT
    titleLabel.TextSize = 13
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.BackgroundTransparency = 1
    titleLabel.ZIndex = 6
    titleLabel.Parent = mainBar

    -- Tab 横栏 ScrollingFrame
    local tabScroll = Instance.new("ScrollingFrame")
    tabScroll.Size = UDim2.new(1, -95, 1, -8)
    tabScroll.Position = UDim2.new(0, 90, 0, 4)
    tabScroll.BackgroundTransparency = 1
    tabScroll.ScrollBarThickness = 0
    tabScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
    tabScroll.AutomaticCanvasSize = Enum.AutomaticSize.X
    tabScroll.ZIndex = 6
    tabScroll.Parent = mainBar

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 6)
    tabLayout.Parent = tabScroll

    MakeDraggable(mainBar)

    -- 主栏自适应拉伸
    local function RecalculateMainBarWidth()
        task.wait()
        local contentWidth = tabLayout.AbsoluteContentSize.X
        local maxAllowedWidth = math.min(workspace.CurrentCamera.ViewportSize.X - 30, 650)
        local targetWidth = math.clamp(contentWidth + 105, 180, maxAllowedWidth)

        SmoothTween(mainBar, {
            Size = UDim2.new(0, targetWidth, 0, 42),
            Position = UDim2.new(0.5, -targetWidth/2, mainBar.Position.Y.Scale, mainBar.Position.Y.Offset)
        }, 0.2)
    end

    tabLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(RecalculateMainBarWidth)

    -- 🎭 无损 UI 全局隐式开关
    local uiVisible = true
    local function ToggleGlobalUI()
        uiVisible = not uiVisible

        if uiVisible then
            mainBar.Visible = true
            mainBar.Size = UDim2.new(mainBar.Size.X.Scale, mainBar.Size.X.Offset, 0, 0)
            SmoothTween(mainBar, {Size = UDim2.new(mainBar.Size.X.Scale, mainBar.Size.X.Offset, 0, 42)}, 0.22)

            for _, catWin in pairs(window.CategoryWindows) do
                if catWin.IsOpen then
                    catWin.Frame.Visible = true
                    SmoothTween(catWin.Frame, {BackgroundTransparency = 0}, 0.18)
                end
            end
        else
            SmoothTween(mainBar, {Size = UDim2.new(mainBar.Size.X.Scale, mainBar.Size.X.Offset, 0, 0)}, 0.18).Completed:Connect(function()
                if not uiVisible then mainBar.Visible = false end
            end)

            for _, catWin in pairs(window.CategoryWindows) do
                if catWin.IsOpen then
                    SmoothTween(catWin.Frame, {BackgroundTransparency = 1}, 0.18).Completed:Connect(function()
                        if not uiVisible then catWin.Frame.Visible = false end
                    end)
                end
            end
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
    --  创建 Tab (对应弹出的自适应独立窗口)
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
        tabBtn.Font = SCIFI_FONT
        tabBtn.TextSize = 11
        tabBtn.BorderSizePixel = 0
        tabBtn.AutoButtonColor = false
        tabBtn.ClipsDescendants = true
        tabBtn.ZIndex = 6
        tabBtn.Parent = tabScroll

        local tabCorner = Instance.new("UICorner")
        tabCorner.CornerRadius = UDim.new(0, 8)
        tabCorner.Parent = tabBtn

        local tabStroke = Instance.new("UIStroke")
        tabStroke.Thickness = 1
        tabStroke.Color = Theme.BorderColor
        tabStroke.ZIndex = 6
        tabStroke.Parent = tabBtn

        -- 独立 Category 窗口
        windowOffsetCount = windowOffsetCount + 1
        local screenWidth = workspace.CurrentCamera.ViewportSize.X
        local frameWidth = math.clamp(screenWidth * 0.4, 170, 220)

        local catFrame = Instance.new("Frame")
        catFrame.Name = tabName .. "_CategoryWindow"
        catFrame.Size = UDim2.new(0, frameWidth, 0, 320)
        catFrame.Position = UDim2.new(0.04 + ((windowOffsetCount-1) * 0.17), 0, 0.18, 0)
        catFrame.BackgroundColor3 = Theme.CategoryBg
        catFrame.BorderSizePixel = 0
        catFrame.Visible = false
        catFrame.ClipsDescendants = true
        catFrame.ZIndex = 3
        catFrame.Parent = screenGui

        local catCorner = Instance.new("UICorner")
        catCorner.CornerRadius = LARGE_CORNER
        catCorner.Parent = catFrame

        ApplyFlowingGlow(catFrame, 1.5, 3)

        -- 窗口 Header
        local catHeader = Instance.new("Frame")
        catHeader.Size = UDim2.new(1, 0, 0, 32)
        catHeader.BackgroundColor3 = Theme.HeaderBg
        catHeader.BorderSizePixel = 0
        catHeader.ZIndex = 3
        catHeader.Parent = catFrame

        local catHeaderCorner = Instance.new("UICorner")
        catHeaderCorner.CornerRadius = LARGE_CORNER
        catHeaderCorner.Parent = catHeader

        local catTitle = Instance.new("TextLabel")
        catTitle.Size = UDim2.new(1, -10, 1, 0)
        catTitle.Position = UDim2.new(0, 10, 0, 0)
        catTitle.Text = tabName
        catTitle.TextColor3 = Theme.TextDark
        catTitle.Font = SCIFI_FONT
        catTitle.TextSize = 12
        catTitle.TextXAlignment = Enum.TextXAlignment.Left
        catTitle.BackgroundTransparency = 1
        catTitle.ZIndex = 3
        catTitle.Parent = catHeader

        local catHeaderLine = Instance.new("Frame")
        catHeaderLine.Size = UDim2.new(1, 0, 0, 2)
        catHeaderLine.Position = UDim2.new(0, 0, 1, -2)
        catHeaderLine.BackgroundColor3 = Theme.AccentBlue
        catHeaderLine.BorderSizePixel = 0
        catHeaderLine.ZIndex = 3
        catHeaderLine.Parent = catHeader

        -- 窗口内容层（完美留白，不遮挡拉伸按钮）
        local catScroll = Instance.new("ScrollingFrame")
        catScroll.Size = UDim2.new(1, -8, 1, -42)
        catScroll.Position = UDim2.new(0, 4, 0, 35)
        catScroll.BackgroundTransparency = 1
        catScroll.ScrollBarThickness = 2
        catScroll.ScrollBarImageColor3 = Theme.AccentBlue
        catScroll.CanvasSize = UDim2.new(0, 0, 0, 0)
        catScroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
        catScroll.ZIndex = 3
        catScroll.Parent = catFrame

        local catLayout = Instance.new("UIListLayout")
        catLayout.SortOrder = Enum.SortOrder.LayoutOrder
        catLayout.Padding = UDim.new(0, 6)
        catLayout.Parent = catScroll

        -- 📐📐📐 iOS 风格 3条渐进式科技线拉伸抓手 (Geometry Resize Grip) 📐📐📐
        local resizeHandle = Instance.new("Frame")
        resizeHandle.Name = "ResizeHandle"
        resizeHandle.Size = UDim2.new(0, 16, 0, 16)
        resizeHandle.Position = UDim2.new(1, -18, 1, -18)
        resizeHandle.BackgroundTransparency = 1
        resizeHandle.ZIndex = 4
        resizeHandle.Parent = catFrame

        -- 代码绘制三条优雅的45度科技对角线
        for i = 1, 3 do
            local line = Instance.new("Frame")
            line.Size = UDim2.new(0, 1 + i*3, 0, 1.5)
            line.Position = UDim2.new(1, - (1 + i*3), 1, - (i*3))
            line.Rotation = -45
            line.BackgroundColor3 = Theme.AccentBlue
            line.BorderSizePixel = 0
            line.ZIndex = 4
            line.Parent = resizeHandle
        end

        local resizeBtn = Instance.new("TextButton")
        resizeBtn.Size = UDim2.new(1, 0, 1, 0)
        resizeBtn.BackgroundTransparency = 1
        resizeBtn.Text = ""
        resizeBtn.ZIndex = 4
        resizeBtn.Parent = resizeHandle

        local isResizing = false
        local resizeStartPos, startFrameSize

        resizeBtn.InputBegan:Connect(function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                isResizing = true
                resizeStartPos = input.Position
                startFrameSize = catFrame.AbsoluteSize
                input.Changed:Connect(function()
                    if input.UserInputState == Enum.UserInputState.End then isResizing = false end
                end)
            end
        end)

        UserInputService.InputChanged:Connect(function(input)
            if isResizing and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                local delta = input.Position - resizeStartPos
                local newW = math.clamp(startFrameSize.X + delta.X, 150, workspace.CurrentCamera.ViewportSize.X - 20)
                local newH = math.clamp(startFrameSize.Y + delta.Y, 140, workspace.CurrentCamera.ViewportSize.Y - 20)
                catFrame.Size = UDim2.new(0, newW, 0, newH)
            end
        end)

        MakeDraggable(catFrame, catHeader)

        local catObj = { Frame = catFrame, IsOpen = false }
        table.insert(window.CategoryWindows, catObj)

        -- 窗口切换开场动画
        tabBtn.MouseButton1Click:Connect(function()
            CreateRipple(tabBtn, UserInputService:GetMouseLocation())
            catObj.IsOpen = not catObj.IsOpen
            tab.IsOpen = catObj.IsOpen

            if catObj.IsOpen then
                catFrame.Visible = true
                catFrame.Size = UDim2.new(0, frameWidth * 0.7, 0, 0)
                catFrame.BackgroundTransparency = 0.5
                catHeaderLine.Size = UDim2.new(0, 0, 0, 2)

                SmoothTween(catFrame, {Size = UDim2.new(0, frameWidth, 0, 320), BackgroundTransparency = 0}, 0.28, Enum.EasingStyle.Back)
                SmoothTween(catHeaderLine, {Size = UDim2.new(1, 0, 0, 2)}, 0.3)
                SmoothTween(tabBtn, {BackgroundColor3 = Theme.AccentBlue, TextColor3 = Color3.fromRGB(255, 255, 255)}, 0.2)
            else
                SmoothTween(catHeaderLine, {Size = UDim2.new(0, 0, 0, 2)}, 0.15)
                SmoothTween(catFrame, {Size = UDim2.new(0, frameWidth * 0.7, 0, 0), BackgroundTransparency = 0.8}, 0.18, Enum.EasingStyle.Quart, Enum.EasingDirection.In).Completed:Connect(function()
                    if not catObj.IsOpen then catFrame.Visible = false end
                end)
                SmoothTween(tabBtn, {BackgroundColor3 = Theme.HeaderBg, TextColor3 = Theme.TextDark}, 0.2)
            end
        end)

        RecalculateMainBarWidth()

        -- ============================================================
        --  创建功能模块 (🔴➔🟢 巨大化流光快捷键系统)
        -- ============================================================
        function tab:CreateModule(modName, callback)
            callback = callback or function() end
            local module = { Enabled = false, QuickBtnActive = false, SpawnedQuickBtn = nil }

            local modFrame = Instance.new("Frame")
            modFrame.Name = modName .. "_Module"
            modFrame.Size = UDim2.new(1, 0, 0, 34) -- 高度稍微增大
            modFrame.BackgroundColor3 = Theme.CardBg
            modFrame.ClipsDescendants = true
            modFrame.BorderSizePixel = 0
            modFrame.ZIndex = 3
            modFrame.Parent = catScroll

            local modCorner = Instance.new("UICorner")
            modCorner.CornerRadius = UDim.new(0, 8)
            modCorner.Parent = modFrame

            ApplyFlowingGlow(modFrame, 1.2, 3)

            -- 🔴 ➔ 🟢 红绿灯按钮 (方块指示灯)
            local lightBtn = Instance.new("TextButton")
            lightBtn.Name = "QuickLightBtn"
            lightBtn.Size = UDim2.new(0, 12, 0, 12)
            lightBtn.Position = UDim2.new(0, 8, 0, 11)
            lightBtn.BackgroundColor3 = Theme.LightRed
            lightBtn.Text = ""
            lightBtn.BorderSizePixel = 0
            lightBtn.ZIndex = 3
            lightBtn.Parent = modFrame

            local lightCorner = Instance.new("UICorner")
            lightCorner.CornerRadius = UDim.new(0, 3) -- 硬朗科幻切角方块
            lightCorner.Parent = lightBtn

            -- 模块主 Title
            local modBtn = Instance.new("TextButton")
            modBtn.Size = UDim2.new(1, -58, 0, 34)
            modBtn.Position = UDim2.new(0, 26, 0, 0)
            modBtn.BackgroundTransparency = 1
            modBtn.Text = modName
            modBtn.TextColor3 = Theme.TextDark
            modBtn.Font = SCIFI_FONT
            modBtn.TextSize = 11
            modBtn.TextXAlignment = Enum.TextXAlignment.Left
            modBtn.ClipsDescendants = true
            modBtn.ZIndex = 3
            modBtn.Parent = modFrame

            -- “...” 详细展开
            local moreBtn = Instance.new("TextButton")
            moreBtn.Size = UDim2.new(0, 26, 0, 34)
            moreBtn.Position = UDim2.new(1, -28, 0, 0)
            moreBtn.Text = "•••"
            moreBtn.TextColor3 = Theme.TextDark
            moreBtn.Font = SCIFI_FONT
            moreBtn.TextSize = 10
            moreBtn.BackgroundTransparency = 1
            moreBtn.ZIndex = 3
            moreBtn.Parent = modFrame

            -- 子菜单 Container
            local subContainer = Instance.new("Frame")
            subContainer.Size = UDim2.new(1, -12, 0, 0)
            subContainer.Position = UDim2.new(0, 6, 0, 36)
            subContainer.BackgroundTransparency = 1
            subContainer.ZIndex = 3
            subContainer.Parent = modFrame

            local subLayout = Instance.new("UIListLayout")
            subLayout.SortOrder = Enum.SortOrder.LayoutOrder
            subLayout.Padding = UDim.new(0, 5)
            subLayout.Parent = subContainer

            local isExpanded = false

            local function UpdateModHeight()
                if isExpanded then
                    local h = subLayout.AbsoluteContentSize.Y + 40
                    SmoothTween(modFrame, {Size = UDim2.new(1, 0, 0, h)}, 0.18)
                else
                    SmoothTween(modFrame, {Size = UDim2.new(1, 0, 0, 34)}, 0.18)
                end
            end

            subLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if isExpanded then UpdateModHeight() end
            end)

            -- 状态同步切换 (无残留强绑定)
            local function SetModuleState(state)
                module.Enabled = state
                if module.Enabled then
                    SmoothTween(modFrame, {BackgroundColor3 = Theme.CardActive}, 0.18)
                    SmoothTween(modBtn, {TextColor3 = Theme.TextBlue}, 0.18)
                else
                    SmoothTween(modFrame, {BackgroundColor3 = Theme.CardBg}, 0.18)
                    SmoothTween(modBtn, {TextColor3 = Theme.TextDark}, 0.18)
                end

                if module.SpawnedQuickBtn then
                    local qIndicator = module.SpawnedQuickBtn:FindFirstChild("Indicator")
                    if qIndicator then
                        SmoothTween(qIndicator, {BackgroundColor3 = module.Enabled and Theme.AccentBlue or Theme.CardBg}, 0.18)
                    end
                end

                CreateNotification({
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

            -- 🔴 ➔ 🟢 放大版指示灯 + 方块流光快捷按钮生成
            lightBtn.MouseButton1Click:Connect(function()
                module.QuickBtnActive = not module.QuickBtnActive

                if module.QuickBtnActive then
                    SmoothTween(lightBtn, {BackgroundColor3 = Theme.LightGreen}, 0.18)

                    -- 放大尺寸 (130x36)
                    local qBtn = Instance.new("TextButton")
                    qBtn.Name = "QuickBtn_" .. modName
                    qBtn.Size = UDim2.new(0, 130, 0, 36)
                    qBtn.Position = UDim2.new(0.75, 0, 0.3 + (math.random(0, 15)*0.01), 0)
                    qBtn.BackgroundColor3 = Theme.MainBg
                    qBtn.Text = "  " .. modName
                    qBtn.TextColor3 = Theme.TextDark
                    qBtn.Font = SCIFI_FONT
                    qBtn.TextSize = 11
                    qBtn.BorderSizePixel = 0
                    qBtn.ClipsDescendants = true
                    qBtn.ZIndex = 5
                    qBtn.Parent = quickBtnHolder

                    local qCorner = Instance.new("UICorner")
                    qCorner.CornerRadius = LARGE_CORNER
                    qCorner.Parent = qBtn

                    ApplyFlowingGlow(qBtn, 1.8, 5) -- 强化流光边缘

                    -- 方块流光指示器
                    local qIndicator = Instance.new("Frame")
                    qIndicator.Name = "Indicator"
                    qIndicator.Size = UDim2.new(0, 10, 0, 10)
                    qIndicator.Position = UDim2.new(1, -16, 0.5, -5)
                    qIndicator.BackgroundColor3 = module.Enabled and Theme.AccentBlue or Theme.CardBg
                    qIndicator.BorderSizePixel = 0
                    qIndicator.ZIndex = 5
                    qIndicator.Parent = qBtn

                    local qiCorner = Instance.new("UICorner")
                    qiCorner.CornerRadius = UDim.new(0, 3)
                    qiCorner.Parent = qIndicator

                    ApplyFlowingGlow(qIndicator, 1, 5) -- 给指示灯也加上小巧的流光！

                    MakeDraggable(qBtn)
                    module.SpawnedQuickBtn = qBtn

                    qBtn.Size = UDim2.new(0, 0, 0, 0)
                    SmoothTween(qBtn, {Size = UDim2.new(0, 130, 0, 36)}, 0.22, Enum.EasingStyle.Back)

                    qBtn.MouseButton1Click:Connect(function()
                        CreateRipple(qBtn, UserInputService:GetMouseLocation())
                        SetModuleState(not module.Enabled)
                    end)

                    CreateNotification({ Title = "QUICK BTN", Content = "已生成 [" .. modName .. "] 快捷键", Duration = 2 })
                else
                    SmoothTween(lightBtn, {BackgroundColor3 = Theme.LightRed}, 0.18)
                    if module.SpawnedQuickBtn then
                        local targetBtn = module.SpawnedQuickBtn
                        module.SpawnedQuickBtn = nil
                        SmoothTween(targetBtn, {Size = UDim2.new(0, 0, 0, 0)}, 0.15).Completed:Connect(function()
                            targetBtn:Destroy()
                        end)
                    end
                end
            end)

            moreBtn.MouseButton1Click:Connect(function()
                isExpanded = not isExpanded
                SmoothTween(moreBtn, {TextColor3 = isExpanded and Theme.AccentBlue or Theme.TextDark}, 0.2)
                UpdateModHeight()
            end)

            -- --------------------------------------------------------
            -- 📂 子配置: Dropdown 下拉模式
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
                dpFrame.ZIndex = 3
                dpFrame.Parent = subContainer

                local dpCorner = Instance.new("UICorner")
                dpCorner.CornerRadius = UDim.new(0, 6)
                dpCorner.Parent = dpFrame

                local dpBtn = Instance.new("TextButton")
                dpBtn.Size = UDim2.new(1, 0, 0, 26)
                dpBtn.BackgroundTransparency = 1
                dpBtn.Text = ""
                dpBtn.ZIndex = 3
                dpBtn.Parent = dpFrame

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(0.5, 0, 0, 26)
                label.Position = UDim2.new(0, 6, 0, 0)
                label.Text = dpName
                label.TextColor3 = Theme.TextDark
                label.Font = SCIFI_FONT
                label.TextSize = 10
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.BackgroundTransparency = 1
                label.ZIndex = 3
                label.Parent = dpFrame

                local valLabel = Instance.new("TextLabel")
                valLabel.Size = UDim2.new(0.45, -15, 0, 26)
                valLabel.Position = UDim2.new(0.5, 0, 0, 0)
                valLabel.Text = currentOpt
                valLabel.TextColor3 = Theme.TextBlue
                valLabel.Font = SCIFI_FONT
                valLabel.TextSize = 10
                valLabel.TextXAlignment = Enum.TextXAlignment.Right
                valLabel.BackgroundTransparency = 1
                valLabel.ZIndex = 3
                valLabel.Parent = dpFrame

                local arrow = Instance.new("TextLabel")
                arrow.Size = UDim2.new(0, 15, 0, 26)
                arrow.Position = UDim2.new(1, -15, 0, 0)
                arrow.Text = "▼"
                arrow.TextColor3 = Theme.TextDark
                arrow.Font = SCIFI_FONT
                arrow.TextSize = 8
                arrow.BackgroundTransparency = 1
                arrow.ZIndex = 3
                arrow.Parent = dpFrame

                local optContainer = Instance.new("Frame")
                optContainer.Size = UDim2.new(1, -8, 0, 0)
                optContainer.Position = UDim2.new(0, 4, 0, 28)
                optContainer.BackgroundTransparency = 1
                optContainer.ZIndex = 3
                optContainer.Parent = dpFrame

                local optLayout = Instance.new("UIListLayout")
                optLayout.SortOrder = Enum.SortOrder.LayoutOrder
                optLayout.Padding = UDim.new(0, 3)
                optLayout.Parent = optContainer

                local dpOpen = false
                local function UpdateDpHeight()
                    if dpOpen then
                        local h = optLayout.AbsoluteContentSize.Y + 32
                        SmoothTween(dpFrame, {Size = UDim2.new(1, 0, 0, h)}, 0.18)
                        SmoothTween(arrow, {Rotation = 180}, 0.18)
                    else
                        SmoothTween(dpFrame, {Size = UDim2.new(1, 0, 0, 26)}, 0.18)
                        SmoothTween(arrow, {Rotation = 0}, 0.18)
                    end
                end

                for _, optText in ipairs(options) do
                    local optBtn = Instance.new("TextButton")
                    optBtn.Size = UDim2.new(1, 0, 0, 20)
                    optBtn.BackgroundColor3 = Theme.CardBg
                    optBtn.Text = optText
                    optBtn.TextColor3 = Theme.TextDark
                    optBtn.Font = SCIFI_FONT
                    optBtn.TextSize = 9
                    optBtn.BorderSizePixel = 0
                    optBtn.ZIndex = 3
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
            -- 🎚️ 子配置: 纯平长方形流光拉条 (Slider)
            -- --------------------------------------------------------
            function module:AddSlider(sName, min, max, default, sCallback)
                sCallback = sCallback or function() end
                local val = default or min

                local sliderFrame = Instance.new("Frame")
                sliderFrame.Size = UDim2.new(1, 0, 0, 32)
                sliderFrame.BackgroundColor3 = Theme.HeaderBg
                sliderFrame.BorderSizePixel = 0
                sliderFrame.ZIndex = 3
                sliderFrame.Parent = subContainer

                -- 长方形微圆角设计
                local sCorner = Instance.new("UICorner")
                sCorner.CornerRadius = UDim.new(0, 4)
                sCorner.Parent = sliderFrame

                local sLabel = Instance.new("TextLabel")
                sLabel.Size = UDim2.new(0.6, 0, 0, 15)
                sLabel.Position = UDim2.new(0, 6, 0, 2)
                sLabel.Text = sName
                sLabel.TextColor3 = Theme.TextDark
                sLabel.Font = SCIFI_FONT
                sLabel.TextSize = 10
                sLabel.TextXAlignment = Enum.TextXAlignment.Left
                sLabel.BackgroundTransparency = 1
                sLabel.ZIndex = 3
                sLabel.Parent = sliderFrame

                local vLabel = Instance.new("TextLabel")
                vLabel.Size = UDim2.new(0.35, 0, 0, 15)
                vLabel.Position = UDim2.new(0.6, 0, 0, 2)
                vLabel.Text = tostring(val)
                vLabel.TextColor3 = Theme.TextBlue
                vLabel.Font = SCIFI_FONT
                vLabel.TextSize = 10
                vLabel.TextXAlignment = Enum.TextXAlignment.Right
                vLabel.BackgroundTransparency = 1
                vLabel.ZIndex = 3
                vLabel.Parent = sliderFrame

                local bar = Instance.new("Frame")
                bar.Size = UDim2.new(1, -12, 0, 6)
                bar.Position = UDim2.new(0, 6, 0, 20)
                bar.BackgroundColor3 = Color3.fromRGB(205, 218, 235)
                bar.BorderSizePixel = 0
                bar.ZIndex = 3
                bar.Parent = sliderFrame

                local fill = Instance.new("Frame")
                fill.Size = UDim2.new((val - min)/(max - min), 0, 1, 0)
                fill.BackgroundColor3 = Theme.AccentBlue
                fill.BorderSizePixel = 0
                fill.ZIndex = 3
                fill.Parent = bar

                ApplyFlowingGlow(fill, 1.5, 3) -- 给长方形填充槽注入流动变色光晕

                local dragging = false
                local function ProcessInput(input)
                    local pos = math.clamp((input.Position.X - bar.AbsolutePosition.X) / bar.AbsoluteSize.X, 0, 1)
                    local cur = math.floor(min + (max - min) * pos)
                    vLabel.Text = tostring(cur)
                    SmoothTween(fill, {Size = UDim2.new(pos, 0, 1, 0)}, 0.05)
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
            -- 📝 子配置: TextBox
            -- --------------------------------------------------------
            function module:AddTextBox(tName, placeholder, tCallback)
                tCallback = tCallback or function() end

                local boxFrame = Instance.new("Frame")
                boxFrame.Size = UDim2.new(1, 0, 0, 24)
                boxFrame.BackgroundColor3 = Theme.HeaderBg
                boxFrame.BorderSizePixel = 0
                boxFrame.ZIndex = 3
                boxFrame.Parent = subContainer

                local bxCorner = Instance.new("UICorner")
                bxCorner.CornerRadius = UDim.new(0, 6)
                bxCorner.Parent = boxFrame

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(0.45, 0, 1, 0)
                label.Position = UDim2.new(0, 6, 0, 0)
                label.Text = tName
                label.TextColor3 = Theme.TextDark
                label.Font = SCIFI_FONT
                label.TextSize = 10
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.BackgroundTransparency = 1
                label.ZIndex = 3
                label.Parent = boxFrame

                local box = Instance.new("TextBox")
                box.Size = UDim2.new(0.5, 0, 0.75, 0)
                box.Position = UDim2.new(0.48, 0, 0.12, 0)
                box.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
                box.Text = ""
                box.PlaceholderText = placeholder or "..."
                box.TextColor3 = Theme.TextBlue
                box.Font = SCIFI_FONT
                box.TextSize = 10
                box.BorderSizePixel = 0
                box.ZIndex = 3
                box.Parent = boxFrame

                local tbCorner = Instance.new("UICorner")
                tbCorner.CornerRadius = UDim.new(0, 4)
                tbCorner.Parent = box

                box.FocusLost:Connect(function(e) tCallback(box.Text, e) end)
            end

            -- --------------------------------------------------------
            -- 🔘 子配置: 方形全流光 Sub-Toggle (子开关)
            -- --------------------------------------------------------
            function module:AddToggle(subName, default, subCb)
                subCb = subCb or function() end
                local state = default or false

                local togFrame = Instance.new("Frame")
                togFrame.Size = UDim2.new(1, 0, 0, 22)
                togFrame.BackgroundColor3 = Theme.HeaderBg
                togFrame.BorderSizePixel = 0
                togFrame.ZIndex = 3
                togFrame.Parent = subContainer

                local tgCorner = Instance.new("UICorner")
                tgCorner.CornerRadius = UDim.new(0, 6)
                tgCorner.Parent = togFrame

                local tBtn = Instance.new("TextButton")
                tBtn.Size = UDim2.new(1, 0, 1, 0)
                tBtn.BackgroundTransparency = 1
                tBtn.Text = ""
                tBtn.ZIndex = 3
                tBtn.Parent = togFrame

                local label = Instance.new("TextLabel")
                label.Size = UDim2.new(0.7, 0, 1, 0)
                label.Position = UDim2.new(0, 6, 0, 0)
                label.Text = subName
                label.TextColor3 = Theme.TextDark
                label.Font = SCIFI_FONT
                label.TextSize = 10
                label.TextXAlignment = Enum.TextXAlignment.Left
                label.BackgroundTransparency = 1
                label.ZIndex = 3
                label.Parent = togFrame

                -- 改变为科幻硬方块
                local dot = Instance.new("Frame")
                dot.Size = UDim2.new(0, 12, 0, 12)
                dot.Position = UDim2.new(1, -16, 0.5, -6)
                dot.BackgroundColor3 = state and Theme.AccentBlue or Color3.fromRGB(195, 208, 225)
                dot.BorderSizePixel = 0
                dot.ZIndex = 3
                dot.Parent = togFrame

                local dCorner = Instance.new("UICorner")
                dCorner.CornerRadius = UDim.new(0, 3) -- 方块切角
                dCorner.Parent = dot

                ApplyFlowingGlow(dot, 1.2, 3) -- 给方形开关体覆盖精致流光效果！

                tBtn.MouseButton1Click:Connect(function()
                    CreateRipple(togFrame, UserInputService:GetMouseLocation())
                    state = not state
                    SmoothTween(dot, {BackgroundColor3 = state and Theme.AccentBlue or Color3.fromRGB(195, 208, 225)}, 0.15)
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