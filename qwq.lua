-- [[ qwq · Liquid Glass UI Library ]] --
-- 白粉主题 · MIUI 14 控件 · 真·背景模糊液态玻璃

local Library = {}
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local Lighting         = game:GetService("Lighting")
local LocalPlayer      = Players.LocalPlayer

-- ==================== 🎨 莫兰迪粉主题（低饱和 · 高级感） ====================
Library.Theme = {
    -- 强调色（柔和樱花粉）
    Accent        = Color3.fromRGB(236, 138, 169),
    AccentLight   = Color3.fromRGB(248, 200, 216),
    AccentSoft    = Color3.fromRGB(255, 235, 242),
    AccentDeep    = Color3.fromRGB(210, 100, 135),
    AccentGlow    = Color3.fromRGB(255, 230, 238),

    -- 玻璃基础色（接近白色的灰粉，避免过亮）
    Glass         = Color3.fromRGB(248, 246, 249),
    GlassCard     = Color3.fromRGB(252, 250, 253),
    GlassBorder   = Color3.fromRGB(235, 220, 228),
    GlassHighlight= Color3.fromRGB(255, 250, 253),

    -- 文本（低对比度，柔和不刺眼）
    TextPrimary   = Color3.fromRGB( 75,  60,  70),
    TextSecond    = Color3.fromRGB(145, 125, 138),
    TextMuted     = Color3.fromRGB(190, 175, 185),
    TextWhite     = Color3.fromRGB(255, 255, 255),

    -- 开关关闭态
    SwitchOff     = Color3.fromRGB(225, 218, 224),
}

-- ==================== 🔤 字体系统 ====================
Library.CurrentFontFamily = "rbxasset://fonts/families/BuilderSans.json"
Library.CurrentFont       = Font.new(Library.CurrentFontFamily, Enum.FontWeight.Bold, Enum.FontStyle.Normal)

-- ==================== 🛠 基础工具 ====================
local function GetGuiParent()
    local ok, coreGui = pcall(function() return game:GetService("CoreGui") end)
    if ok and coreGui then return coreGui end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function Animate(obj, duration, style, dir, props)
    local tween = TweenService:Create(obj, TweenInfo.new(duration, style, dir), props)
    tween:Play()
    return tween
end

local function ApplyFont(label, weight)
    weight = weight or Enum.FontWeight.SemiBold
    pcall(function()
        label.FontFace = Font.new(Library.CurrentFontFamily, weight, Enum.FontStyle.Normal)
    end)
end

-- ==================== 🧊 液态玻璃外观 ====================
-- 真·玻璃：极低透明度背景 + 极细描边 + 顶部高光渐变
local function ApplyGlass(frame, opts)
    opts = opts or {}

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, opts.radius or 14)
    corner.Parent = frame

    -- 极细的浅粉描边（模拟玻璃边缘）
    local stroke = Instance.new("UIStroke")
    stroke.Color = opts.strokeColor or Library.Theme.GlassBorder
    stroke.Thickness = opts.strokeThickness or 1
    stroke.Transparency = opts.strokeTransparency or 0.25
    stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    stroke.Parent = frame

    -- 顶部高光渐变（玻璃的“反光”）
    local grad = Instance.new("UIGradient")
    grad.Rotation = 90
    grad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.50, opts.fillColor or Library.Theme.Glass),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(250, 246, 250)),
    })
    grad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.00, 0.15),   -- 顶部稍亮
        NumberSequenceKeypoint.new(0.40, 0.45),   -- 中间更透
        NumberSequenceKeypoint.new(1.00, 0.25),   -- 底部轻微着色
    })
    grad.Parent = frame

    return corner, stroke, grad
end

-- ==================== 🖱 修好的拖拽 ====================
local function MakeDraggable(handle, target)
    local dragging, dragStart, startPos

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = target.Position
        end
    end)

    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
            dragStart = nil
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not dragging or not dragStart then return end
        if input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch then
            local delta = input.Position - dragStart
            target.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

-- ==================== 🍬 液态玻璃通知系统 ====================
local NotificationGui
local function CreateNotificationContainer()
    if NotificationGui and NotificationGui.Parent then return NotificationGui end

    NotificationGui = Instance.new("ScreenGui")
    NotificationGui.Name = "qwqNotifications"
    NotificationGui.ResetOnSpawn = false
    NotificationGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    NotificationGui.Parent = GetGuiParent()

    local FrameList = Instance.new("Frame")
    FrameList.Name = "FrameList"
    FrameList.AnchorPoint = Vector2.new(1, 1)
    FrameList.Size = UDim2.new(0, 240, 0, 520)
    FrameList.Position = UDim2.new(1, -16, 1, -16)
    FrameList.BackgroundTransparency = 1
    FrameList.Parent = NotificationGui

    local ListLayout = Instance.new("UIListLayout")
    ListLayout.Padding = UDim.new(0, 8)
    ListLayout.VerticalAlignment = Enum.VerticalAlignment.Bottom
    ListLayout.HorizontalAlignment = Enum.HorizontalAlignment.Right
    ListLayout.SortOrder = Enum.SortOrder.LayoutOrder
    ListLayout.Parent = FrameList

    return NotificationGui
end

-- 通知类型配色
local NotifyStyles = {
    info    = { title = "QWQ · 提示",  color = Color3.fromRGB(236, 138, 169) },
    success = { title = "QWQ · 成功",  color = Color3.fromRGB(102, 195, 148) },
    warn    = { title = "QWQ · 警告",  color = Color3.fromRGB(240, 175,  90) },
    error   = { title = "QWQ · 错误",  color = Color3.fromRGB(230,  95, 120) },
}

function Library:Notify(titleText, descText, duration, notifType)
    titleText = titleText or "QWQ"
    descText  = descText  or "操作成功"
    duration  = duration  or 3
    notifType = notifType or "info"

    local style = NotifyStyles[notifType] or NotifyStyles.info

    local container = CreateNotificationContainer()
    local listFrame = container.FrameList

    local Toast = Instance.new("CanvasGroup")
    Toast.Name = "Toast"
    Toast.Size = UDim2.new(1, 0, 0, 52)
    Toast.BackgroundColor3 = Library.Theme.GlassCard
    Toast.BackgroundTransparency = 0.15
    Toast.GroupTransparency = 1
    Toast.BorderSizePixel = 0
    Toast.Parent = listFrame

    ApplyGlass(Toast, {
        radius = 14,
        strokeColor = style.color,
        strokeTransparency = 0.6,
        fillColor = Library.Theme.Glass,
    })

    -- 左侧强调色胶囊
    local AccentBar = Instance.new("Frame")
    AccentBar.Size = UDim2.new(0, 3, 0, 26)
    AccentBar.Position = UDim2.new(0, 8, 0.5, -13)
    AccentBar.BackgroundColor3 = style.color
    AccentBar.BorderSizePixel = 0
    AccentBar.Parent = Toast

    local BarCorner = Instance.new("UICorner")
    BarCorner.CornerRadius = UDim.new(1, 0)
    BarCorner.Parent = AccentBar

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -32, 0, 18)
    Title.Position = UDim2.new(0, 18, 0, 7)
    Title.BackgroundTransparency = 1
    Title.Text = titleText:upper()
    Title.TextColor3 = style.color
    Title.TextSize = 11
    ApplyFont(Title, Enum.FontWeight.Bold)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = Toast

    local Desc = Instance.new("TextLabel")
    Desc.Size = UDim2.new(1, -32, 0, 16)
    Desc.Position = UDim2.new(0, 18, 0, 25)
    Desc.BackgroundTransparency = 1
    Desc.Text = descText
    Desc.TextColor3 = Library.Theme.TextPrimary
    Desc.TextSize = 10
    ApplyFont(Desc, Enum.FontWeight.Medium)
    Desc.TextXAlignment = Enum.TextXAlignment.Left
    Desc.Parent = Toast

    -- 底部进度条
    local ProgressTrack = Instance.new("Frame")
    ProgressTrack.Size = UDim2.new(1, -24, 0, 3)
    ProgressTrack.Position = UDim2.new(0, 12, 1, -7)
    ProgressTrack.BackgroundColor3 = Library.Theme.AccentSoft
    ProgressTrack.BackgroundTransparency = 0.5
    ProgressTrack.BorderSizePixel = 0
    ProgressTrack.Parent = Toast

    local TrackCorner = Instance.new("UICorner")
    TrackCorner.CornerRadius = UDim.new(1, 0)
    TrackCorner.Parent = ProgressTrack

    local ProgressBar = Instance.new("Frame")
    ProgressBar.Size = UDim2.new(1, 0, 1, 0)
    ProgressBar.BackgroundColor3 = style.color
    ProgressBar.BorderSizePixel = 0
    ProgressBar.Parent = ProgressTrack

    local ProgressCorner = Instance.new("UICorner")
    ProgressCorner.CornerRadius = UDim.new(1, 0)
    ProgressCorner.Parent = ProgressBar

    -- 入场：淡入
    Animate(Toast, 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
        { GroupTransparency = 0 })
    Animate(ProgressBar, duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out,
        { Size = UDim2.new(0, 0, 1, 0) })

    -- 出场：塌陷式淡出（修复 UIListLayout 覆盖 Position 的问题）
    task.delay(duration, function()
        if not Toast.Parent then return end
        local out = Animate(Toast, 0.32, Enum.EasingStyle.Quad, Enum.EasingDirection.In, {
            GroupTransparency = 1,
            Size = UDim2.new(1, 0, 0, 0),
        })
        out.Completed:Connect(function()
            if Toast.Parent then Toast:Destroy() end
        end)
    end)
end

-- 便捷方法
function Library:Success(msg, dur) return self:Notify("成功", msg, dur or 2.5, "success") end
function Library:Warn(msg, dur)    return self:Notify("警告", msg, dur or 3,   "warn")    end
function Library:Error(msg, dur)   return self:Notify("错误", msg, dur or 3.5, "error")   end

-- ==================== 🌸 自定义字体 ====================
function Library:SetCustomFont(fontAssetId)
    local newFamily
    if typeof(fontAssetId) == "number" then
        local ok, f = pcall(Font.fromId, fontAssetId)
        if ok and f then newFamily = f.Family end
    else
        newFamily = fontAssetId
    end

    if not newFamily then
        warn("[qwq] 字体加载失败，保留当前字体。")
        return false
    end

    Library.CurrentFontFamily = newFamily

    for _, gui in ipairs(GetGuiParent():GetChildren()) do
        if gui.Name:match("^qwqMorph_") or gui.Name == "qwqNotifications" then
            for _, desc in ipairs(gui:GetDescendants()) do
                if desc:IsA("TextLabel") or desc:IsA("TextButton")
                or desc:IsA("TextBox") then
                    ApplyFont(desc, Enum.FontWeight.SemiBold)
                end
            end
        end
    end
    return true
end

-- ==================== 🪟 主窗口 ====================
function Library:CreateWindow(titleText, accentColor)
    titleText   = titleText   or "QWQ"
    accentColor = accentColor or Library.Theme.Accent
    Library.Theme.Accent = accentColor

    -- ---------- 真·背景模糊：添加全局 BlurEffect ----------
    local existingBlur = Lighting:FindFirstChild("qwqUIBlur")
    if existingBlur then existingBlur:Destroy() end

    local blurEffect = Instance.new("BlurEffect")
    blurEffect.Name = "qwqUIBlur"
    blurEffect.Size = 0 -- 初始为 0，展开时渐变到 12
    blurEffect.Parent = Lighting

    -- ---------- 顶层 ScreenGui ----------
    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "qwqMorph_" .. math.random(1000, 9999)
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = GetGuiParent()

    -- 清理旧窗口
    for _, old in ipairs(GetGuiParent():GetChildren()) do
        if old ~= ScreenGui and old.Name:match("^qwqMorph_") then
            old:Destroy()
        end
    end

    -- ---------- 尺寸参数 ----------
    local windowSize    = UDim2.new(0, 500, 0, 340)
    local windowCenter  = UDim2.new(0.5, -250, 0.5, -170)
    local floatSize     = UDim2.new(0, 52, 0, 52)
    local lastFloatPos  = UDim2.new(0.9, -60, 0.15, 40)

    -- ---------- 主基座 ----------
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = floatSize
    MainFrame.Position = lastFloatPos
    MainFrame.BackgroundColor3 = Library.Theme.GlassCard
    MainFrame.BackgroundTransparency = 1
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(1, 0)
    MainCorner.Parent = MainFrame

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = accentColor
    MainStroke.Thickness = 0
    MainStroke.Transparency = 0.3
    MainStroke.Parent = MainFrame

    local MainGradient = Instance.new("UIGradient")
    MainGradient.Rotation = 90
    MainGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(250, 246, 250)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(248, 242, 248)),
    })
    MainGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.00, 0.10),
        NumberSequenceKeypoint.new(0.50, 0.30),
        NumberSequenceKeypoint.new(1.00, 0.15),
    })
    MainGradient.Parent = MainFrame

    -- ---------- 悬浮星核 ----------
    local GlowHolder = Instance.new("Frame")
    GlowHolder.Size = UDim2.new(0, 86, 0, 86)
    GlowHolder.AnchorPoint = Vector2.new(0.5, 0.5)
    GlowHolder.Position = UDim2.new(0.5, 0, 0.5, 0)
    GlowHolder.BackgroundColor3 = Library.Theme.AccentGlow
    GlowHolder.BackgroundTransparency = 0.55
    GlowHolder.BorderSizePixel = 0
    GlowHolder.ZIndex = 0
    GlowHolder.Parent = MainFrame

    local GlowCorner = Instance.new("UICorner")
    GlowCorner.CornerRadius = UDim.new(1, 0)
    GlowCorner.Parent = GlowHolder

    local FloatIcon = Instance.new("TextLabel")
    FloatIcon.Name = "FloatIcon"
    FloatIcon.Size = UDim2.new(1, 0, 1, 0)
    FloatIcon.BackgroundTransparency = 1
    FloatIcon.Text = "★"
    FloatIcon.TextSize = 38
    FloatIcon.TextColor3 = accentColor
    FloatIcon.ZIndex = 2
    FloatIcon.Parent = MainFrame

    -- 星核呼吸光晕
    task.spawn(function()
        while FloatIcon.Parent and GlowHolder.Parent do
            Animate(GlowHolder, 1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut,
                { BackgroundTransparency = 0.35 })
            task.wait(1.4)
            if not GlowHolder.Parent then break end
            Animate(GlowHolder, 1.4, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut,
                { BackgroundTransparency = 0.65 })
            task.wait(1.4)
        end
    end)

    -- 自转线程
    local rotationConn
    local function StartRotation()
        if rotationConn then rotationConn:Disconnect() end
        rotationConn = RunService.RenderStepped:Connect(function(delta)
            FloatIcon.Rotation = (FloatIcon.Rotation + 110 * delta) % 360
        end)
    end
    StartRotation()

    -- ---------- 内容容器 ----------
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, 0, 1, 0)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Visible = false
    ContentContainer.Parent = MainFrame

    local isMinimized, animating = true, false

    -- ---------- 变形切换（修复动画重叠）----------
    local function ToggleUI()
        if animating then return end
        animating = true
        isMinimized = not isMinimized

        if isMinimized then
            -- 【长方形 ➔ 星核】
            ContentContainer.Visible = false
            MainStroke.Thickness = 0
            Animate(blurEffect, 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Size = 0 })

            Animate(MainCorner, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In,
                { CornerRadius = UDim.new(1, 0) })

            local back = Animate(MainFrame, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.In, {
                Size = floatSize,
                Position = lastFloatPos,
                BackgroundTransparency = 1,
            })

            back.Completed:Connect(function()
                FloatIcon.Visible = true
                FloatIcon.TextTransparency = 1
                Animate(FloatIcon, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                    { TextTransparency = 0 })
                StartRotation()
                animating = false
            end)
        else
            -- 【星核 ➔ 长方形】
            lastFloatPos = MainFrame.Position
            if rotationConn then rotationConn:Disconnect() end

            Animate(FloatIcon, 0.15, Enum.EasingStyle.Back, Enum.EasingDirection.In, {
                TextTransparency = 1,
                Rotation = FloatIcon.Rotation + 90,
            })
            task.delay(0.12, function()
                FloatIcon.Visible = false
            end)

            MainStroke.Thickness = 1
            Animate(MainCorner, 0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out,
                { CornerRadius = UDim.new(0, 16) })

            local fwd = Animate(MainFrame, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
                Size = windowSize,
                Position = windowCenter,
                BackgroundTransparency = 0.25, -- 更透，让背景模糊透出来
            })
            Animate(blurEffect, 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Size = 12 })

            fwd.Completed:Connect(function()
                ContentContainer.Visible = true
                animating = false
            end)
        end
    end

    -- 星核点击检测
    local dragThreshold = 6
    local clickStart
    MainFrame.InputBegan:Connect(function(input)
        if isMinimized and (input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch) then
            clickStart = input.Position
        end
    end)
    MainFrame.InputEnded:Connect(function(input)
        if isMinimized and clickStart
        and (input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch) then
            if (input.Position - clickStart).Magnitude < dragThreshold then
                ToggleUI()
            end
            clickStart = nil
        end
    end)
    MakeDraggable(MainFrame, MainFrame)

    -- ---------- 顶部标题栏 ----------
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 44)
    TopBar.BackgroundColor3 = Library.Theme.GlassCard
    TopBar.BackgroundTransparency = 0.3
    TopBar.BorderSizePixel = 0
    TopBar.Parent = ContentContainer

    local TopBarCorner = Instance.new("UICorner")
    TopBarCorner.CornerRadius = UDim.new(0, 16)
    TopBarCorner.Parent = TopBar

    local TopCover = Instance.new("Frame")
    TopCover.Size = UDim2.new(1, 0, 0, 14)
    TopCover.Position = UDim2.new(0, 0, 1, -14)
    TopCover.BackgroundColor3 = Library.Theme.GlassCard
    TopCover.BackgroundTransparency = 0.3
    TopCover.BorderSizePixel = 0
    TopCover.Parent = TopBar

    -- 品牌指示
    local BrandDot = Instance.new("Frame")
    BrandDot.Size = UDim2.new(0, 8, 0, 8)
    BrandDot.Position = UDim2.new(0, 18, 0.5, -4)
    BrandDot.BackgroundColor3 = accentColor
    BrandDot.BorderSizePixel = 0
    BrandDot.Parent = TopBar

    local BrandDotCorner = Instance.new("UICorner")
    BrandDotCorner.CornerRadius = UDim.new(1, 0)
    BrandDotCorner.Parent = BrandDot

    task.spawn(function()
        while BrandDot.Parent do
            Animate(BrandDot, 0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut,
                { BackgroundTransparency = 0.45 })
            task.wait(0.9)
            if not BrandDot.Parent then break end
            Animate(BrandDot, 0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut,
                { BackgroundTransparency = 0 })
            task.wait(0.9)
        end
    end)

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -100, 1, 0)
    Title.Position = UDim2.new(0, 34, 0, 0)
    Title.BackgroundTransparency = 1
    Title.Text = titleText:upper()
    Title.TextColor3 = Library.Theme.TextPrimary
    Title.TextSize = 13
    ApplyFont(Title, Enum.FontWeight.Bold)
    Title.TextXAlignment = Enum.TextXAlignment.Left
    Title.Parent = TopBar

    -- MIUI 风格圆点按钮
    local function MakeDotButton(symbol, posX, cb)
        local btn = Instance.new("TextButton")
        btn.Size = UDim2.new(0, 24, 0, 24)
        btn.Position = UDim2.new(1, posX, 0.5, -12)
        btn.BackgroundColor3 = Library.Theme.AccentSoft
        btn.BackgroundTransparency = 0.3
        btn.Text = symbol
        btn.TextColor3 = Library.Theme.AccentDeep
        btn.TextSize = 11
        btn.AutoButtonColor = false
        ApplyFont(btn, Enum.FontWeight.Bold)
        btn.Parent = TopBar

        local c = Instance.new("UICorner")
        c.CornerRadius = UDim.new(1, 0)
        c.Parent = btn

        btn.MouseEnter:Connect(function()
            Animate(btn, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                { BackgroundTransparency = 0.1 })
        end)
        btn.MouseLeave:Connect(function()
            Animate(btn, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                { BackgroundTransparency = 0.3 })
        end)
        btn.MouseButton1Click:Connect(cb)
        return btn
    end

    MakeDotButton("—", -64, ToggleUI)
    MakeDotButton("×", -34, function()
        if rotationConn then rotationConn:Disconnect() end
        if blurEffect then blurEffect:Destroy() end
        ScreenGui:Destroy()
    end)

    MakeDraggable(TopBar, MainFrame)

    -- ---------- 左侧导航栏 ----------
    local SideBar = Instance.new("Frame")
    SideBar.Name = "SideBar"
    SideBar.Size = UDim2.new(0, 120, 1, -44)
    SideBar.Position = UDim2.new(0, 0, 0, 44)
    SideBar.BackgroundTransparency = 1
    SideBar.Parent = ContentContainer

    local TabContainer = Instance.new("ScrollingFrame")
    TabContainer.Name = "TabContainer"
    TabContainer.Size = UDim2.new(1, -8, 1, -88)
    TabContainer.Position = UDim2.new(0, 4, 0, 12)
    TabContainer.BackgroundTransparency = 1
    TabContainer.CanvasSize = UDim2.new(0, 0, 0, 0)
    TabContainer.ScrollBarThickness = 0
    TabContainer.Parent = SideBar

    local TabList = Instance.new("UIListLayout")
    TabList.Padding = UDim.new(0, 5)
    TabList.Parent = TabContainer

    -- ---------- 底部状态栏 ----------
    local InfoPanel = Instance.new("Frame")
    InfoPanel.Name = "InfoPanel"
    InfoPanel.Size = UDim2.new(1, -12, 0, 70)
    InfoPanel.Position = UDim2.new(0, 6, 1, -76)
    InfoPanel.BackgroundColor3 = Library.Theme.GlassCard
    InfoPanel.BackgroundTransparency = 0.3
    InfoPanel.Parent = SideBar
    ApplyGlass(InfoPanel, { radius = 12, strokeTransparency = 0.6 })

    local function MakeInfoLabel(text, y)
        local l = Instance.new("TextLabel")
        l.Size = UDim2.new(1, -16, 0, 18)
        l.Position = UDim2.new(0, 10, 0, y)
        l.BackgroundTransparency = 1
        l.Text = text
        l.TextColor3 = Library.Theme.TextSecond
        l.TextSize = 10
        ApplyFont(l, Enum.FontWeight.SemiBold)
        l.TextXAlignment = Enum.TextXAlignment.Left
        l.Parent = InfoPanel
        return l
    end

    local FpsLabel    = MakeInfoLabel("帧率: --", 6)
    local VolLabel    = MakeInfoLabel("音量: --", 24)
    local StatusLabel = MakeInfoLabel("状态: 运行中", 42)
    StatusLabel.TextColor3 = accentColor

    -- FPS 采样（修复精度丢失）
    local frameCount, lastTime = 0, os.clock()
    local fpsConn = RunService.RenderStepped:Connect(function()
        frameCount += 1
        local now = os.clock()
        if now - lastTime >= 1 then
            FpsLabel.Text = string.format("帧率: %d FPS", math.floor(frameCount / (now - lastTime)))
            frameCount = 0
            lastTime = now
        end
    end)

    -- 音量采样（修复线程泄漏）
    task.spawn(function()
        while task.wait(2) do
            if not ScreenGui.Parent then break end
            local ok, vol = pcall(function()
                return math.floor(UserSettings():GetService("UserGameSettings").MasterVolume * 100)
            end)
            if ok then VolLabel.Text = "音量: " .. vol .. "%" end
        end
    end)

    -- 销毁清理
    ScreenGui.Destroying:Connect(function()
        if fpsConn then fpsConn:Disconnect() end
        if rotationConn then rotationConn:Disconnect() end
        if blurEffect then blurEffect:Destroy() end
    end)

    -- ---------- 右侧内容区 ----------
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(1, -132, 1, -56)
    ContentFrame.Position = UDim2.new(0, 126, 0, 48)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = ContentContainer

    local Pages = {}
    local CurrentTab = nil

    -- ============================================================
    -- 📑 Tab 创建
    -- ============================================================
    function Pages:CreateTab(tabName)
        tabName = tabName or "分类"

        local Page = Instance.new("ScrollingFrame")
        Page.Name = tabName .. "Page"
        Page.Size = UDim2.new(1, 0, 1, 0)
        Page.BackgroundTransparency = 1
        Page.CanvasSize = UDim2.new(0, 0, 0, 0)
        Page.ScrollBarThickness = 3
        Page.ScrollBarImageColor3 = Library.Theme.AccentSoft
        Page.Visible = false
        Page.Parent = ContentFrame

        local Pad = Instance.new("UIPadding")
        Pad.PaddingLeft   = UDim.new(0, 6)
        Pad.PaddingRight  = UDim.new(0, 10)
        Pad.PaddingTop    = UDim.new(0, 6)
        Pad.PaddingBottom = UDim.new(0, 6)
        Pad.Parent = Page

        local PageLayout = Instance.new("UIListLayout")
        PageLayout.Padding = UDim.new(0, 8)
        PageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        PageLayout.Parent = Page

        PageLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
            Page.CanvasSize = UDim2.new(0, 0, 0, PageLayout.AbsoluteContentSize.Y + 16)
        end)

        -- ---------- 侧栏按钮 ----------
        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(1, -4, 0, 34)
        TabBtn.BackgroundColor3 = Library.Theme.GlassCard
        TabBtn.BackgroundTransparency = 1
        TabBtn.Text = "   " .. tabName
        TabBtn.TextColor3 = Library.Theme.TextSecond
        TabBtn.TextSize = 11
        TabBtn.AutoButtonColor = false
        ApplyFont(TabBtn, Enum.FontWeight.SemiBold)
        TabBtn.TextXAlignment = Enum.TextXAlignment.Left
        TabBtn.Parent = TabContainer

        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 9)
        TabCorner.Parent = TabBtn

        local Marker = Instance.new("Frame")
        Marker.Name = "Marker"
        Marker.Size = UDim2.new(0, 3, 0, 16)
        Marker.Position = UDim2.new(0, 0, 0.5, -8)
        Marker.BackgroundColor3 = accentColor
        Marker.BackgroundTransparency = 1
        Marker.BorderSizePixel = 0
        Marker.Parent = TabBtn

        local MarkerCorner = Instance.new("UICorner")
        MarkerCorner.CornerRadius = UDim.new(1, 0)
        MarkerCorner.Parent = Marker

        local function Select()
            for _, child in ipairs(ContentFrame:GetChildren()) do
                if child:IsA("ScrollingFrame") then child.Visible = false end
            end
            for _, btn in ipairs(TabContainer:GetChildren()) do
                if btn:IsA("TextButton") then
                    Animate(btn, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
                        TextColor3 = Library.Theme.TextSecond,
                        BackgroundTransparency = 1,
                    })
                    local mk = btn:FindFirstChild("Marker")
                    if mk then
                        Animate(mk, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                            { BackgroundTransparency = 1 })
                    end
                end
            end

            Page.Visible = true
            Page.Position = UDim2.new(0, 12, 0, 0)
            Animate(Page, 0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                { Position = UDim2.new(0, 0, 0, 0) })

            Animate(TabBtn, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
                TextColor3 = accentColor,
                BackgroundTransparency = 0.15,
            })
            Animate(Marker, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out,
                { BackgroundTransparency = 0 })
        end

        TabBtn.MouseButton1Click:Connect(Select)

        if CurrentTab == nil then
            CurrentTab = tabName
            Select()
        end

        local Elements = {}

        -- ============================================================
        -- 🧱 卡片工厂
        -- ============================================================
        local function MakeCard(height)
            local Card = Instance.new("Frame")
            Card.Size = UDim2.new(1, 0, 0, height)
            Card.BackgroundColor3 = Library.Theme.GlassCard
            Card.BackgroundTransparency = 0.3
            Card.Parent = Page
            ApplyGlass(Card, { radius = 12, strokeTransparency = 0.55 })
            return Card
        end

        -- ============================================================
        -- [[ 1. Label ]]
        -- ============================================================
        function Elements:CreateLabel(text)
            local l = Instance.new("TextLabel")
            l.Size = UDim2.new(1, 0, 0, 22)
            l.BackgroundTransparency = 1
            l.Text = text
            l.TextColor3 = Library.Theme.TextSecond
            l.TextSize = 11
            ApplyFont(l, Enum.FontWeight.SemiBold)
            l.TextXAlignment = Enum.TextXAlignment.Left
            l.Parent = Page
            return l
        end

        -- ============================================================
        -- [[ 2. Button ]]
        -- ============================================================
        function Elements:CreateButton(text, callback)
            callback = callback or function() end

            local Btn = Instance.new("TextButton")
            Btn.Size = UDim2.new(1, 0, 0, 36)
            Btn.BackgroundColor3 = Library.Theme.GlassCard
            Btn.BackgroundTransparency = 0.3
            Btn.Text = text
            Btn.TextColor3 = Library.Theme.TextPrimary
            Btn.TextSize = 11
            Btn.AutoButtonColor = false
            ApplyFont(Btn, Enum.FontWeight.Bold)
            Btn.Parent = Page

            local _, stroke = ApplyGlass(Btn, { radius = 12, strokeTransparency = 0.55 })

            Btn.MouseEnter:Connect(function()
                Animate(Btn, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                    { BackgroundTransparency = 0.15 })
                Animate(stroke, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                    { Color = accentColor, Transparency = 0.25 })
            end)
            Btn.MouseLeave:Connect(function()
                Animate(Btn, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                    { BackgroundTransparency = 0.3 })
                Animate(stroke, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                    { Color = Library.Theme.GlassBorder, Transparency = 0.55 })
            end)
            Btn.MouseButton1Down:Connect(function()
                Animate(Btn, 0.08, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                    { Size = UDim2.new(0.97, 0, 0, 34) })
            end)
            Btn.MouseButton1Up:Connect(function()
                Animate(Btn, 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out,
                    { Size = UDim2.new(1, 0, 0, 36) })
                task.spawn(callback)
            end)
            return Btn
        end

        -- ============================================================
        -- [[ 3. Toggle · MIUI 14 胶囊开关 ]]
        -- ============================================================
        function Elements:CreateToggle(text, default, callback)
            local state = default or false
            callback = callback or function() end

            local Card = MakeCard(40)
            local _, cardStroke = ApplyGlass(Card, { radius = 12, strokeTransparency = 0.55 })

            local Click = Instance.new("TextButton")
            Click.Size = UDim2.new(1, 0, 1, 0)
            Click.BackgroundTransparency = 1
            Click.Text = ""
            Click.Parent = Card

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -80, 1, 0)
            Label.Position = UDim2.new(0, 14, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Library.Theme.TextPrimary
            Label.TextSize = 11
            ApplyFont(Label, Enum.FontWeight.SemiBold)
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Card

            local Switch = Instance.new("Frame")
            Switch.Size = UDim2.new(0, 42, 0, 24)
            Switch.Position = UDim2.new(1, -56, 0.5, -12)
            Switch.BackgroundColor3 = state and accentColor or Library.Theme.SwitchOff
            Switch.Parent = Card

            local SwitchCorner = Instance.new("UICorner")
            SwitchCorner.CornerRadius = UDim.new(1, 0)
            SwitchCorner.Parent = Switch

            local Dot = Instance.new("Frame")
            Dot.Size = UDim2.new(0, 18, 0, 18)
            Dot.Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
            Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Dot.Parent = Switch

            local DotCorner = Instance.new("UICorner")
            DotCorner.CornerRadius = UDim.new(1, 0)
            DotCorner.Parent = Dot

            local DotStroke = Instance.new("UIStroke")
            DotStroke.Color = Color3.fromRGB(220, 210, 218)
            DotStroke.Thickness = 1
            DotStroke.Transparency = 0.7
            DotStroke.Parent = Dot

            -- 修复：分离弹性动画时序（先拉伸再回弹）
            local function Update()
                local targetColor = state and accentColor or Library.Theme.SwitchOff
                local targetPos = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)

                -- 第一步：拉伸变长（果冻效果）
                Animate(Dot, 0.10, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                    { Size = UDim2.new(0, 26, 0, 16) })

                -- 第二步：回弹归位
                task.delay(0.10, function()
                    Animate(Dot, 0.22, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out,
                        { Size = UDim2.new(0, 18, 0, 18) })
                end)

                Animate(Switch, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                    { BackgroundColor3 = targetColor })
                Animate(Dot, 0.26, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out,
                    { Position = targetPos })

                if state then
                    Animate(cardStroke, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                        { Color = accentColor, Transparency = 0.35 })
                else
                    Animate(cardStroke, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                        { Color = Library.Theme.GlassBorder, Transparency = 0.55 })
                end

                task.spawn(function() pcall(callback, state) end)
            end

            Click.MouseButton1Click:Connect(function()
                state = not state
                Update()
            end)

            return { Set = function(_, v) state = v Update() end }
        end

        -- ============================================================
        -- [[ 4. Slider · MIUI 液态粗条 ]]
        -- ============================================================
        function Elements:CreateSlider(text, min, max, default, callback)
            min = min or 0
            max = max or 100
            default = default or min
            callback = callback or function() end

            local Card = MakeCard(34)
            local _, cardStroke = ApplyGlass(Card, { radius = 12, strokeTransparency = 0.55 })

            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            Fill.BackgroundColor3 = accentColor
            Fill.BackgroundTransparency = 0.5
            Fill.BorderSizePixel = 0
            Fill.ZIndex = 1
            Fill.Parent = Card

            local FillCorner = Instance.new("UICorner")
            FillCorner.CornerRadius = UDim.new(0, 12)
            FillCorner.Parent = Fill

            local FillEdge = Instance.new("Frame")
            FillEdge.Size = UDim2.new(0, 2, 1, 0)
            FillEdge.Position = UDim2.new(1, -2, 0, 0)
            FillEdge.BackgroundColor3 = accentColor
            FillEdge.BorderSizePixel = 0
            FillEdge.ZIndex = 2
            FillEdge.Parent = Fill

            local EdgeCorner = Instance.new("UICorner")
            EdgeCorner.CornerRadius = UDim.new(1, 0)
            EdgeCorner.Parent = FillEdge

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -90, 1, 0)
            Label.Position = UDim2.new(0, 14, 0, 0)
            Label.BackgroundTransparency = 1
            Label.ZIndex = 3
            Label.Text = text:upper()
            Label.TextColor3 = Library.Theme.TextPrimary
            Label.TextSize = 10
            ApplyFont(Label, Enum.FontWeight.Bold)
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Card

            local ValLabel = Instance.new("TextLabel")
            ValLabel.Size = UDim2.new(0, 60, 1, 0)
            ValLabel.Position = UDim2.new(1, -14, 0, 0)
            ValLabel.BackgroundTransparency = 1
            ValLabel.ZIndex = 3
            ValLabel.Text = tostring(default)
            ValLabel.TextColor3 = Library.Theme.AccentDeep
            ValLabel.TextSize = 11
            ApplyFont(ValLabel, Enum.FontWeight.Bold)
            ValLabel.TextXAlignment = Enum.TextXAlignment.Right
            ValLabel.Parent = Card

            Card.MouseEnter:Connect(function()
                Animate(Card, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                    { Size = UDim2.new(1, 0, 0, 36) })
                Animate(cardStroke, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                    { Color = accentColor, Transparency = 0.35 })
                Animate(Fill, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                    { BackgroundTransparency = 0.35 })
            end)
            Card.MouseLeave:Connect(function()
                Animate(Card, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                    { Size = UDim2.new(1, 0, 0, 34) })
                Animate(cardStroke, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                    { Color = Library.Theme.GlassBorder, Transparency = 0.55 })
                Animate(Fill, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                    { BackgroundTransparency = 0.5 })
            end)

            local dragging = false
            local function Update(input)
                local pct = math.clamp(
                    (input.Position.X - Card.AbsolutePosition.X) / Card.AbsoluteSize.X, 0, 1)
                local value = math.floor(min + (max - min) * pct)
                Fill.Size = UDim2.new(pct, 0, 1, 0)
                ValLabel.Text = tostring(value)
                task.spawn(function() pcall(callback, value) end)
            end

            Card.InputBegan:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = true
                    Update(input)
                end
            end)
            UserInputService.InputEnded:Connect(function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                or input.UserInputType == Enum.UserInputType.Touch then
                    dragging = false
                end
            end)
            UserInputService.InputChanged:Connect(function(input)
                if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                or input.UserInputType == Enum.UserInputType.Touch) then
                    Update(input)
                end
            end)

            return { Set = function(_, v)
                local pct = (math.clamp(v, min, max) - min) / (max - min)
                Animate(Fill, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                    { Size = UDim2.new(pct, 0, 1, 0) })
                ValLabel.Text = tostring(v)
                task.spawn(function() pcall(callback, v) end)
            end }
        end

        -- ============================================================
        -- [[ 5. Input ]]
        -- ============================================================
        function Elements:CreateInput(placeholder, callback)
            placeholder = placeholder or "请输入参数并回车..."
            callback = callback or function() end

            local Card = MakeCard(36)
            local _, cardStroke = ApplyGlass(Card, { radius = 12, strokeTransparency = 0.55 })

            local Box = Instance.new("TextBox")
            Box.Size = UDim2.new(1, -24, 1, 0)
            Box.Position = UDim2.new(0, 12, 0, 0)
            Box.BackgroundTransparency = 1
            Box.PlaceholderText = placeholder
            Box.PlaceholderColor3 = Library.Theme.TextMuted
            Box.Text = ""
            Box.TextColor3 = Library.Theme.TextPrimary
            Box.TextSize = 11
            Box.ClearTextOnFocus = false
            ApplyFont(Box, Enum.FontWeight.Medium)
            Box.Parent = Card

            Box.Focused:Connect(function()
                Animate(Card, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                    { Size = UDim2.new(0.98, 0, 0, 34) })
                Animate(cardStroke, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                    { Color = accentColor, Transparency = 0.25 })
            end)
            Box.FocusLost:Connect(function()
                Animate(Card, 0.22, Enum.EasingStyle.Back, Enum.EasingDirection.Out,
                    { Size = UDim2.new(1, 0, 0, 36) })
                Animate(cardStroke, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                    { Color = Library.Theme.GlassBorder, Transparency = 0.55 })
                task.spawn(function() pcall(callback, Box.Text) end)
            end)

            return {
                GetText = function() return Box.Text end,
                SetText = function(_, t) Box.Text = t end,
            }
        end

        -- ============================================================
        -- [[ 6. Dropdown · 修复高度计算竞态 ]]
        -- ============================================================
        function Elements:CreateDropdown(text, options, callback)
            options = options or {}
            callback = callback or function() end

            local OPT_H, HEAD_H, GAP = 28, 36, 3

            local Card = Instance.new("Frame")
            Card.Size = UDim2.new(1, 0, 0, HEAD_H)
            Card.BackgroundColor3 = Library.Theme.GlassCard
            Card.BackgroundTransparency = 0.3
            Card.ClipsDescendants = true
            Card.Parent = Page
            local _, cardStroke = ApplyGlass(Card, { radius = 12, strokeTransparency = 0.55 })

            local Click = Instance.new("TextButton")
            Click.Size = UDim2.new(1, 0, 0, HEAD_H)
            Click.BackgroundTransparency = 1
            Click.Text = ""
            Click.Parent = Card

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -50, 0, HEAD_H)
            Label.Position = UDim2.new(0, 14, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Library.Theme.TextPrimary
            Label.TextSize = 11
            ApplyFont(Label, Enum.FontWeight.SemiBold)
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Click

            local Arrow = Instance.new("TextLabel")
            Arrow.Size = UDim2.new(0, 30, 0, HEAD_H)
            Arrow.Position = UDim2.new(1, -38, 0, 0)
            Arrow.BackgroundTransparency = 1
            Arrow.Text = "▼"
            Arrow.TextColor3 = Library.Theme.TextSecond
            Arrow.TextSize = 10
            ApplyFont(Arrow, Enum.FontWeight.Bold)
            Arrow.Parent = Click

            local OptionContainer = Instance.new("Frame")
            OptionContainer.Size = UDim2.new(1, -14, 0, 0)
            OptionContainer.Position = UDim2.new(0, 7, 0, HEAD_H + 2)
            OptionContainer.BackgroundTransparency = 1
            OptionContainer.Parent = Card

            local OptionList = Instance.new("UIListLayout")
            OptionList.Padding = UDim.new(0, GAP)
            OptionList.Parent = OptionContainer

            local open = false
            local function CalcBodyHeight()
                local n = #options
                if n == 0 then return 8 end
                return n * OPT_H + (n - 1) * GAP + 8
            end

            local function Toggle()
                open = not open
                local target = open and (HEAD_H + CalcBodyHeight()) or HEAD_H
                Animate(Card, 0.26, Enum.EasingStyle.Back, Enum.EasingDirection.Out,
                    { Size = UDim2.new(1, 0, 0, target) })
                Animate(Arrow, 0.26, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                    { Rotation = open and 180 or 0 })
            end
            Click.MouseButton1Click:Connect(Toggle)

            local function Build()
                for _, c in ipairs(OptionContainer:GetChildren()) do
                    if c:IsA("TextButton") then c:Destroy() end
                end
                for _, name in ipairs(options) do
                    local Opt = Instance.new("TextButton")
                    Opt.Size = UDim2.new(1, 0, 0, OPT_H)
                    Opt.BackgroundColor3 = Library.Theme.AccentSoft
                    Opt.BackgroundTransparency = 0.5
                    Opt.Text = "  " .. tostring(name)
                    Opt.TextColor3 = Library.Theme.TextPrimary
                    Opt.TextSize = 10
                    Opt.AutoButtonColor = false
                    ApplyFont(Opt, Enum.FontWeight.Medium)
                    Opt.TextXAlignment = Enum.TextXAlignment.Left
                    Opt.Parent = OptionContainer

                    local oc = Instance.new("UICorner")
                    oc.CornerRadius = UDim.new(0, 8)
                    oc.Parent = Opt

                    Opt.MouseEnter:Connect(function()
                        Animate(Opt, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                            { BackgroundTransparency = 0.2 })
                    end)
                    Opt.MouseLeave:Connect(function()
                        Animate(Opt, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                            { BackgroundTransparency = 0.5 })
                    end)
                    Opt.MouseButton1Click:Connect(function()
                        Label.Text = text .. ": " .. tostring(name)
                        Toggle()
                        task.spawn(function() pcall(callback, name) end)
                    end)
                end
            end
            Build()

            return {
                Refresh = function(_, newOpts)
                    options = newOpts or {}
                    Build()
                    if open then
                        Animate(Card, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                            { Size = UDim2.new(1, 0, 0, HEAD_H + CalcBodyHeight()) })
                    end
                end
            }
        end

        -- ============================================================
        -- [[ 7. Keybind ]]
        -- ============================================================
        function Elements:CreateKeybind(text, default, callback)
            callback = callback or function() end
            local currentKey = default or "未绑定"
            local listening = false

            local Card = MakeCard(40)
            local _, cardStroke = ApplyGlass(Card, { radius = 12, strokeTransparency = 0.55 })

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -110, 1, 0)
            Label.Position = UDim2.new(0, 14, 0, 0)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Library.Theme.TextPrimary
            Label.TextSize = 11
            ApplyFont(Label, Enum.FontWeight.SemiBold)
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Card

            local KeyBtn = Instance.new("TextButton")
            KeyBtn.Size = UDim2.new(0, 84, 0, 26)
            KeyBtn.Position = UDim2.new(1, -96, 0.5, -13)
            KeyBtn.BackgroundColor3 = Library.Theme.AccentSoft
            KeyBtn.BackgroundTransparency = 0.25
            KeyBtn.Text = currentKey
            KeyBtn.TextColor3 = Library.Theme.AccentDeep
            KeyBtn.TextSize = 11
            KeyBtn.AutoButtonColor = false
            ApplyFont(KeyBtn, Enum.FontWeight.Bold)
            KeyBtn.Parent = Card

            local KeyCorner = Instance.new("UICorner")
            KeyCorner.CornerRadius = UDim.new(0, 9)
            KeyCorner.Parent = KeyBtn

            local listenConn
            local function StopListening()
                listening = false
                if listenConn then listenConn:Disconnect() listenConn = nil end
                KeyBtn.Text = currentKey
                Animate(KeyBtn, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
                    BackgroundColor3 = Library.Theme.AccentSoft,
                    TextColor3 = Library.Theme.AccentDeep,
                    BackgroundTransparency = 0.25,
                })
                Animate(cardStroke, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                    { Color = Library.Theme.GlassBorder, Transparency = 0.55 })
            end

            KeyBtn.MouseButton1Click:Connect(function()
                if listening then StopListening() return end
                listening = true
                KeyBtn.Text = "按下按键..."
                Animate(KeyBtn, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
                    BackgroundColor3 = accentColor,
                    TextColor3 = Library.Theme.TextWhite,
                    BackgroundTransparency = 0.15,
                })
                Animate(cardStroke, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                    { Color = accentColor, Transparency = 0.25 })

                listenConn = UserInputService.InputBegan:Connect(function(input, gameProcessed)
                    if gameProcessed then return end
                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        currentKey = input.KeyCode.Name
                        StopListening()
                        task.spawn(function() pcall(callback, input.KeyCode) end)
                    end
                end)
            end)

            return {
                Get = function() return currentKey end,
                Set = function(_, key)
                    currentKey = typeof(key) == "EnumItem" and key.Name or tostring(key)
                    KeyBtn.Text = currentKey
                end,
            }
        end

        -- ============================================================
        -- [[ 8. Section ]]
        -- ============================================================
        function Elements:CreateSection(titleText)
            local Holder = Instance.new("Frame")
            Holder.Size = UDim2.new(1, 0, 0, 24)
            Holder.BackgroundTransparency = 1
            Holder.Parent = Page

            local Line = Instance.new("Frame")
            Line.Size = UDim2.new(0, 3, 0, 12)
            Line.Position = UDim2.new(0, 0, 0.5, -6)
            Line.BackgroundColor3 = accentColor
            Line.BorderSizePixel = 0
            Line.Parent = Holder

            local LineCorner = Instance.new("UICorner")
            LineCorner.CornerRadius = UDim.new(1, 0)
            LineCorner.Parent = Line

            local Title = Instance.new("TextLabel")
            Title.Size = UDim2.new(1, -14, 1, 0)
            Title.Position = UDim2.new(0, 10, 0, 0)
            Title.BackgroundTransparency = 1
            Title.Text = titleText:upper()
            Title.TextColor3 = Library.Theme.TextSecond
            Title.TextSize = 10
            ApplyFont(Title, Enum.FontWeight.Bold)
            Title.TextXAlignment = Enum.TextXAlignment.Left
            Title.Parent = Holder

            return Holder
        end

        -- ============================================================
        -- [[ 9. Divider ]]
        -- ============================================================
        function Elements:CreateDivider()
            local Holder = Instance.new("Frame")
            Holder.Size = UDim2.new(1, 0, 0, 6)
            Holder.BackgroundTransparency = 1
            Holder.Parent = Page

            local Line = Instance.new("Frame")
            Line.Size = UDim2.new(1, -20, 0, 1)
            Line.Position = UDim2.new(0, 10, 0.5, 0)
            Line.BackgroundColor3 = Library.Theme.GlassBorder
            Line.BackgroundTransparency = 0.4
            Line.BorderSizePixel = 0
            Line.Parent = Holder

            local Grad = Instance.new("UIGradient")
            Grad.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0.00, 1),
                NumberSequenceKeypoint.new(0.50, 0),
                NumberSequenceKeypoint.new(1.00, 1),
            })
            Grad.Parent = Line

            return Holder
        end

        -- ============================================================
        -- [[ 10. Paragraph ]]
        -- ============================================================
        function Elements:CreateParagraph(text, height)
            local Holder = MakeCard(height or 60)
            local Box = Instance.new("TextLabel")
            Box.Size = UDim2.new(1, -20, 1, -16)
            Box.Position = UDim2.new(0, 10, 0, 8)
            Box.BackgroundTransparency = 1
            Box.Text = text
            Box.TextColor3 = Library.Theme.TextSecond
            Box.TextSize = 10
            Box.TextWrapped = true
            Box.TextYAlignment = Enum.TextYAlignment.Top
            Box.TextXAlignment = Enum.TextXAlignment.Left
            ApplyFont(Box, Enum.FontWeight.Medium)
            Box.Parent = Holder

            return {
                SetText = function(_, t) Box.Text = t end,
                Frame = Holder,
            }
        end

        -- ============================================================
        -- [[ 11. ColorPicker ]]
        -- ============================================================
        function Elements:CreateColorPicker(text, default, callback)
            default = default or Color3.fromRGB(236, 138, 169)
            callback = callback or function() end

            local current = default

            local Card = MakeCard(48)
            local _, cardStroke = ApplyGlass(Card, { radius = 12, strokeTransparency = 0.55 })

            local Label = Instance.new("TextLabel")
            Label.Size = UDim2.new(1, -100, 0, 20)
            Label.Position = UDim2.new(0, 14, 0, 6)
            Label.BackgroundTransparency = 1
            Label.Text = text
            Label.TextColor3 = Library.Theme.TextPrimary
            Label.TextSize = 11
            ApplyFont(Label, Enum.FontWeight.SemiBold)
            Label.TextXAlignment = Enum.TextXAlignment.Left
            Label.Parent = Card

            local Preview = Instance.new("Frame")
            Preview.Size = UDim2.new(0, 42, 0, 22)
            Preview.Position = UDim2.new(1, -56, 0, 8)
            Preview.BackgroundColor3 = current
            Preview.Parent = Card

            local PreviewCorner = Instance.new("UICorner")
            PreviewCorner.CornerRadius = UDim.new(0, 7)
            PreviewCorner.Parent = Preview

            local PreviewStroke = Instance.new("UIStroke")
            PreviewStroke.Color = Color3.fromRGB(255, 255, 255)
            PreviewStroke.Thickness = 1.4
            PreviewStroke.Transparency = 0.35
            PreviewStroke.Parent = Preview

            local Track = Instance.new("Frame")
            Track.Size = UDim2.new(1, -22, 0, 12)
            Track.Position = UDim2.new(0, 11, 0, 30)
            Track.BackgroundColor3 = Library.Theme.AccentSoft
            Track.BackgroundTransparency = 0.5
            Track.BorderSizePixel = 0
            Track.ClipsDescendants = true
            Track.Parent = Card

            local TrackCorner = Instance.new("UICorner")
            TrackCorner.CornerRadius = UDim.new(1, 0)
            TrackCorner.Parent = Track

            local function MakeMiniChannel(color, offsetRatio, ch)
                local strip = Instance.new("Frame")
                strip.Size = UDim2.new(0.32, -4, 1, 0)
                strip.Position = UDim2.new(offsetRatio, 0, 0, 0)
                strip.BackgroundColor3 = color
                strip.BackgroundTransparency = 0.25
                strip.BorderSizePixel = 0
                strip.Parent = Track

                local sc = Instance.new("UICorner")
                sc.CornerRadius = UDim.new(1, 0)
                sc.Parent = strip

                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0.32, -4, 1, 0)
                btn.Position = UDim2.new(offsetRatio, 0, 0, 0)
                btn.BackgroundTransparency = 1
                btn.Text = ""
                btn.Parent = Track

                local dragging = false
                local function Update(input)
                    local pct = math.clamp(
                        (input.Position.X - Track.AbsolutePosition.X) / Track.AbsoluteSize.X, 0, 1)
                    local v = math.floor(pct * 255)
                    strip.Position = UDim2.new(math.clamp(pct * 0.66, 0, 0.68), 0, 0, 0)

                    local r = math.floor(current.R * 255)
                    local g = math.floor(current.G * 255)
                    local b = math.floor(current.B * 255)
                    if ch == "r" then r = v elseif ch == "g" then g = v else b = v end
                    current = Color3.fromRGB(r, g, b)
                    Preview.BackgroundColor3 = current
                    task.spawn(function() pcall(callback, current) end)
                end
                btn.InputBegan:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = true
                        Update(input)
                    end
                end)
                UserInputService.InputEnded:Connect(function(input)
                    if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                        dragging = false
                    end
                end)
                UserInputService.InputChanged:Connect(function(input)
                    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch) then
                        Update(input)
                    end
                end)
            end

            MakeMiniChannel(Color3.fromRGB(236, 100, 130), 0.00, "r")
            MakeMiniChannel(Color3.fromRGB(120, 210, 150), 0.34, "g")
            MakeMiniChannel(Color3.fromRGB(120, 160, 240), 0.68, "b")

            return {
                Get = function() return current end,
                Set = function(_, c)
                    current = c
                    Preview.BackgroundColor3 = c
                    task.spawn(function() pcall(callback, c) end)
                end,
            }
        end

        -- ============================================================
        -- [[ 12. MultiButton ]]
        -- ============================================================
        function Elements:CreateMultiButton(buttonList)
            buttonList = buttonList or {}

            local Holder = Instance.new("Frame")
            Holder.Size = UDim2.new(1, 0, 0, 34)
            Holder.BackgroundTransparency = 1
            Holder.Parent = Page

            local Layout = Instance.new("UIListLayout")
            Layout.FillDirection = Enum.FillDirection.Horizontal
            Layout.Padding = UDim.new(0, 6)
            Layout.Parent = Holder

            local count = #buttonList
            if count == 0 then return Holder end
            local eachW = (1 / count)

            for i, item in ipairs(buttonList) do
                local Btn = Instance.new("TextButton")
                Btn.Size = UDim2.new(eachW, -6, 1, 0)
                Btn.BackgroundColor3 = Library.Theme.GlassCard
                Btn.BackgroundTransparency = 0.3
                Btn.Text = item.text or ("按钮" .. i)
                Btn.TextColor3 = Library.Theme.TextPrimary
                Btn.TextSize = 10
                Btn.AutoButtonColor = false
                ApplyFont(Btn, Enum.FontWeight.Bold)
                Btn.Parent = Holder

                local _, stroke = ApplyGlass(Btn, { radius = 10, strokeTransparency = 0.55 })

                Btn.MouseEnter:Connect(function()
                    Animate(Btn, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                        { BackgroundTransparency = 0.15 })
                    Animate(stroke, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                        { Color = accentColor, Transparency = 0.25 })
                end)
                Btn.MouseLeave:Connect(function()
                    Animate(Btn, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                        { BackgroundTransparency = 0.3 })
                    Animate(stroke, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                        { Color = Library.Theme.GlassBorder, Transparency = 0.55 })
                end)
                Btn.MouseButton1Click:Connect(function()
                    task.spawn(item.callback or function() end)
                end)
            end

            return Holder
        end

        return Elements
    end

    return Pages
end

return Library