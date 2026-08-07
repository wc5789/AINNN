-- ====================================================================
--  Vape V4 Style White-Blue Sci-Fi UI Library (Mobile & PC Dynamic)
--  Features: Spawning Windows per Tab, Flowing Light Effect, Pure White-Blue
--  Author: DeepSeek-Girl for Master
-- ====================================================================

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local CoreGui = game:GetService("CoreGui")

local VapeLib = {}
VapeLib.__index = VapeLib

-- 🩵 白蓝科技感顶级配色方案 🩵
local Theme = {
    MainBg = Color3.fromRGB(245, 248, 255),        -- 冰纯白主体底色
    CategoryBg = Color3.fromRGB(250, 252, 255),    -- 独立窗口纯白底色
    HeaderBg = Color3.fromRGB(235, 242, 255),      -- 顶部高亮白蓝
    CardBg = Color3.fromRGB(228, 236, 250),        -- 模块卡片未激活
    CardActive = Color3.fromRGB(210, 230, 255),    -- 模块卡片激活
    AccentBlue = Color3.fromRGB(0, 150, 255),      -- 电光科技蓝
    GlowBlue = Color3.fromRGB(80, 200, 255),        -- 冰蓝高亮
    TextDark = Color3.fromRGB(25, 40, 65),          -- 无描边的高级深蓝灰字体
    TextBlue = Color3.fromRGB(0, 120, 235),        -- 蓝字高亮
    BorderColor = Color3.fromRGB(205, 220, 245)    -- 细腻软边框
}

-- 动画辅助
local function Tween(instance, properties, duration, style, direction)
    local tweenInfo = TweenInfo.new(duration or 0.25, style or Enum.EasingStyle.Quart, direction or Enum.EasingDirection.Out)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

-- 为边框或线条添加流畅的冰蓝“流光特效”
local function AddFlowingLight(guiObject)
    local uiGradient = Instance.new("UIGradient")
    uiGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(0, 150, 255)),
        ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(0, 150, 255))
    })
    uiGradient.Parent = guiObject

    local speed = 2
    local connection
    connection = RunService.RenderStepped:Connect(function(dt)
        if not guiObject or not guiObject.Parent then
            connection:Disconnect()
            return
        end
        uiGradient.Rotation = (uiGradient.Rotation + speed) % 360
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
            Tween(gui, {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)}, 0.08)
        end
    end)
end

-- ====================================================================
--  创建 UI 实例
-- ====================================================================
function VapeLib:CreateWindow(libName)
    local window = {}
    
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "VapeV4_WhiteSciFi_" .. math.random(1000, 9999)
    screenGui.ResetOnSpawn = false

    if gethui then screenGui.Parent = gethui()
    elseif syn and syn.protect_gui then syn.protect_gui(screenGui); screenGui.Parent = CoreGui
    else screenGui.Parent = CoreGui end

    -- 移动端悬浮开关球 (Mobile Floating Toggle Button)
    local toggleBall = Instance.new("TextButton")
    toggleBall.Name = "VapeToggleBall"
    toggleBall.Size = UDim2.new(0, 45, 0, 45)
    toggleBall.Position = UDim2.new(0.05, 0, 0.15, 0)
    toggleBall.BackgroundColor3 = Theme.MainBg
    toggleBall.Text = "VAPE"
    toggleBall.TextColor3 = Theme.TextBlue
    toggleBall.Font = Enum.Font.GothamBold
    toggleBall.TextSize = 11
    toggleBall.BorderSizePixel = 0
    toggleBall.Parent = screenGui

    local ballStroke = Instance.new("UIStroke")
    ballStroke.Thickness = 2
    ballStroke.Color = Theme.AccentBlue
    ballStroke.Parent = toggleBall
    AddFlowingLight(ballStroke) -- 赋予悬浮球流光效果
    MakeDraggable(toggleBall)

    -- 主控制栏 Frame ( Main Hub Bar )
    local mainBar = Instance.new("Frame")
    mainBar.Name = "MainHubBar"
    mainBar.Size = UDim2.new(0, math.min(ScreenGui and 340 or 340, workspace.CurrentCamera.ViewportSize.X - 20), 0, 45)
    mainBar.Position = UDim2.new(0.5, -170, 0.05, 0)
    mainBar.BackgroundColor3 = Theme.MainBg
    mainBar.BorderSizePixel = 0
    mainBar.Parent = screenGui

    local mainStroke = Instance.new("UIStroke")
    mainStroke.Thickness = 1.5
    mainStroke.Color = Theme.AccentBlue
    mainStroke.Parent = mainBar
    AddFlowingLight(mainStroke) -- 主窗口边缘顶部冰蓝流光

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(0, 90, 1, 0)
    titleLabel.Position = UDim2.new(0, 10, 0, 0)
    titleLabel.Text = libName or "VAPE v4"
    titleLabel.TextColor3 = Theme.TextDark
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextSize = 14
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.BackgroundTransparency = 1
    titleLabel.Parent = mainBar

    -- Tab 放置横栏容器
    local tabContainer = Instance.new("Frame")
    tabContainer.Size = UDim2.new(1, -100, 1, -8)
    tabContainer.Position = UDim2.new(0, 95, 0, 4)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = mainBar

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 6)
    tabLayout.Parent = tabContainer

    MakeDraggable(mainBar)

    -- 切换全局 UI 显示隐藏
    local uiVisible = true
    local function ToggleGlobalUI()
        uiVisible = not uiVisible
        mainBar.Visible = uiVisible
        for _, catWin in pairs(window.CategoryWindows) do
            if catWin.IsOpen then
                catWin.Frame.Visible = uiVisible
            end
        end
    end

    toggleBall.MouseButton1Click:Connect(ToggleGlobalUI)
    UserInputService.InputBegan:Connect(function(input, gpe)
        if not gpe and input.KeyCode == Enum.KeyCode.RightControl then
            ToggleGlobalUI()
        end
    end)

    window.CategoryWindows = {}
    local windowOffsetCount = 0

    -- ================================================================
    --  创建 Tab，独立生成对应窗口 (Vape V4 核心机制)
    -- ================================================================
    function window:CreateTab(tabName)
        local tab = {}
        
        -- 1. 主栏上的 Tab 按钮
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = tabName .. "_TabBtn"
        tabBtn.Size = UDim2.new(0, 68, 1, 0)
        tabBtn.BackgroundColor3 = Theme.HeaderBg
        tabBtn.Text = tabName
        tabBtn.TextColor3 = Theme.TextDark
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.TextSize = 11
        tabBtn.BorderSizePixel = 0
        tabBtn.AutoButtonColor = false
        tabBtn.Parent = tabContainer

        local tabStroke = Instance.new("UIStroke")
        tabStroke.Thickness = 1
        tabStroke.Color = Theme.BorderColor
        tabStroke.Parent = tabBtn

        -- 2. 点击 Tab 独立生成的 Category 窗口 (适应手机宽度)
        windowOffsetCount = windowOffsetCount + 1
        local screenWidth = workspace.CurrentCamera.ViewportSize.X
        local frameWidth = math.clamp(screenWidth * 0.42, 160, 220) -- 动态适配移动端

        local catFrame = Instance.new("Frame")
        catFrame.Name = tabName .. "_CategoryWindow"
        catFrame.Size = UDim2.new(0, frameWidth, 0, 360)
        -- 错开排布窗口，仿 Vape V4 布局
        catFrame.Position = UDim2.new(0.05 + ((windowOffsetCount-1) * 0.18), 0, 0.18, 0)
        catFrame.BackgroundColor3 = Theme.CategoryBg
        catFrame.BorderSizePixel = 0
        catFrame.Visible = false -- 默认未点开
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

        -- 窗口内容滚动层
        local catScroll = Instance.new("ScrollingFrame")
        catScroll.Size = UDim2.new(1, -8, 1, -38)
        catScroll.Position = UDim2.new(0, 4, 0, 35)
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

        -- 独立窗口状态
        local catObj = { Frame = catFrame, IsOpen = false }
        table.insert(window.CategoryWindows, catObj)

        -- Vape V4 Tab 点击核心逻辑：开关独立 Category 窗口
        tabBtn.MouseButton1Click:Connect(function()
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

        -- ============================================================
        --  在 Category 窗口内添加功能 Module (Button + "..." 扩展配置)
        -- ============================================================
        function tab:CreateModule(modName, callback)
            callback = callback or function() end
            local module = { Enabled = false }

            -- 功能模块外壳 Card
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

            -- 模块主 Button
            local modBtn = Instance.new("TextButton")
            modBtn.Size = UDim2.new(1, -28, 0, 30)
            modBtn.BackgroundTransparency = 1
            modBtn.Text = " " .. modName
            modBtn.TextColor3 = Theme.TextDark
            modBtn.Font = Enum.Font.GothamMedium
            modBtn.TextSize = 11
            modBtn.TextXAlignment = Enum.TextXAlignment.Left
            modBtn.Parent = modFrame

            -- 右侧 “...” 展开详细配置按钮
            local moreBtn = Instance.new("TextButton")
            moreBtn.Size = UDim2.new(0, 26, 0, 30)
            moreBtn.Position = UDim2.new(1, -26, 0, 0)
            moreBtn.Text = "•••"
            moreBtn.TextColor3 = Theme.TextDark
            moreBtn.Font = Enum.Font.GothamBold
            moreBtn.TextSize = 10
            moreBtn.BackgroundTransparency = 1
            moreBtn.Parent = modFrame

            -- 展开详细配置的子容器
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
                    local h = subLayout.AbsoluteContentSize.Y + 38
                    Tween(modFrame, {Size = UDim2.new(1, 0, 0, h)}, 0.25)
                else
                    Tween(modFrame, {Size = UDim2.new(1, 0, 0, 30)}, 0.25)
                end
            end

            subLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if isExpanded then UpdateModHeight() end
            end)

            -- 点击 Button 激活模块
            modBtn.MouseButton1Click:Connect(function()
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
                callback(module.Enabled)
            end)

            -- 点击 “...” 三个点平滑展开/折叠配置
            moreBtn.MouseButton1Click:Connect(function()
                isExpanded = not isExpanded
                Tween(moreBtn, {TextColor3 = isExpanded and Theme.AccentBlue or Theme.TextDark}, 0.2)
                UpdateModHeight()
            end)

            -- --------------------------------------------------------
            -- 子配置 1: Slider 拉条
            -- --------------------------------------------------------
            function module:AddSlider(sName, min, max, default, sCallback)
                sCallback = sCallback or function() end
                local val = default or min

                local sliderFrame = Instance.new("Frame")
                sliderFrame.Size = UDim2.new(1, 0, 0, 34)
                sliderFrame.BackgroundColor3 = Theme.HeaderBg
                sliderFrame.BorderSizePixel = 0
                sliderFrame.Parent = subContainer

                local sLabel = Instance.new("TextLabel")
                sLabel.Size = UDim2.new(0.6, 0, 0, 16)
                sLabel.Position = UDim2.new(0, 4, 0, 2)
                sLabel.Text = sName
                sLabel.TextColor3 = Theme.TextDark
                sLabel.Font = Enum.Font.Gotham
                sLabel.TextSize = 10
                sLabel.TextXAlignment = Enum.TextXAlignment.Left
                sLabel.BackgroundTransparency = 1
                sLabel.Parent = sliderFrame

                local vLabel = Instance.new("TextLabel")
                vLabel.Size = UDim2.new(0.35, 0, 0, 16)
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
                bar.Position = UDim2.new(0, 4, 0, 22)
                bar.BackgroundColor3 = Color3.fromRGB(210, 220, 235)
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
            -- 子配置 2: TextBox 文本框
            -- --------------------------------------------------------
            function module:AddTextBox(tName, placeholder, tCallback)
                tCallback = tCallback or function() end

                local boxFrame = Instance.new("Frame")
                boxFrame.Size = UDim2.new(1, 0, 0, 26)
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
            -- 子配置 3: Sub-Toggle 子开关
            -- --------------------------------------------------------
            function module:AddToggle(subName, default, subCb)
                subCb = subCb or function() end
                local state = default or false

                local togFrame = Instance.new("Frame")
                togFrame.Size = UDim2.new(1, 0, 0, 24)
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
                dot.BackgroundColor3 = state and Theme.AccentBlue or Color3.fromRGB(200, 210, 225)
                dot.BorderSizePixel = 0
                dot.Parent = togFrame

                tBtn.MouseButton1Click:Connect(function()
                    state = not state
                    Tween(dot, {BackgroundColor3 = state and Theme.AccentBlue or Color3.fromRGB(200, 210, 225)}, 0.15)
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