-- [[ qwq · Liquid Glass UI Library · v3 ]] --
-- 白粉莫兰迪 · MIUI 14 控件 · 暗化遮罩代替 BlurEffect
-- 性能优先：全局单指针拖拽 / 精简描边 / 无全屏模糊

local Library = {}
local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local Players          = game:GetService("Players")
local LocalPlayer      = Players.LocalPlayer

-- ==================== 🎨 莫兰迪粉主题 ====================
Library.Theme = {
    Accent        = Color3.fromRGB(236, 138, 169),
    AccentLight   = Color3.fromRGB(248, 200, 216),
    AccentSoft    = Color3.fromRGB(255, 235, 242),
    AccentDeep    = Color3.fromRGB(210, 100, 135),

    Glass         = Color3.fromRGB(248, 246, 249),
    GlassCard     = Color3.fromRGB(252, 250, 253),
    GlassBorder   = Color3.fromRGB(235, 220, 228),

    TextPrimary   = Color3.fromRGB( 75,  60,  70),
    TextSecond    = Color3.fromRGB(145, 125, 138),
    TextMuted     = Color3.fromRGB(190, 175, 185),
    TextWhite     = Color3.fromRGB(255, 255, 255),
    SwitchOff     = Color3.fromRGB(225, 218, 224),

    -- 暗化遮罩色（深粉紫，代替 BlurEffect）
    DimColor      = Color3.fromRGB(40, 24, 40),
    DimAmount     = 0.55, -- 展开时暗化强度
}

-- ==================== 🔤 字体 ====================
Library.CurrentFontFamily = "rbxasset://fonts/families/BuilderSans.json"

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

-- EnumItem 安全转字符串（修复 Keybind 报错）
local function KeyToString(k)
    if k == nil then return "未绑定" end
    if typeof(k) == "EnumItem" then return k.Name end
    return tostring(k)
end

-- ==================== 🎯 全局单指针拖拽（性能关键）====================
-- 整个库只有 1 个 InputChanged + 1 个 InputEnded 连接，所有拖拽共用
local ActiveDrag = nil

UserInputService.InputChanged:Connect(function(input)
    if not ActiveDrag then return end
    if input.UserInputType == Enum.UserInputType.MouseMovement
    or input.UserInputType == Enum.UserInputType.Touch then
        ActiveDrag(input)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
    or input.UserInputType == Enum.UserInputType.Touch then
        ActiveDrag = nil
    end
end)

-- ==================== 🧊 液态玻璃外观（精简版）====================
-- 默认只加圆角。stroke/gradient 需要显式开启（每个 stroke 都是一次额外绘制）
local function ApplyGlass(frame, opts)
    opts = opts or {}

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, opts.radius or 12)
    corner.Parent = frame

    local stroke
    if opts.stroke then
        stroke = Instance.new("UIStroke")
        stroke.Color = opts.strokeColor or Library.Theme.GlassBorder
        stroke.Thickness = opts.strokeThickness or 1
        stroke.Transparency = opts.strokeTransparency or 0.4
        stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
        stroke.Parent = frame
    end

    local grad
    if opts.gradient then
        grad = Instance.new("UIGradient")
        grad.Rotation = 90
        grad.Color = opts.gradColor or ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1.00, Library.Theme.Glass),
        })
        grad.Transparency = opts.gradTransparency or NumberSequence.new({
            NumberSequenceKeypoint.new(0.00, 0.10),
            NumberSequenceKeypoint.new(0.55, 0.30),
            NumberSequenceKeypoint.new(1.00, 0.15),
        })
        grad.Parent = frame
    end

    return corner, stroke, grad
end

-- 悬浮时临时加 stroke，离开时销毁（不是常驻）
local function AddHoverStroke(frame, color)
    local s = Instance.new("UIStroke")
    s.Color = color or Library.Theme.Accent
    s.Thickness = 1
    s.Transparency = 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = frame
    Animate(s, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { Transparency = 0.3 })
    return s
end

local function RemoveHoverStroke(s)
    if not s then return end
    local t = Animate(s, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
        { Transparency = 1 })
    t.Completed:Connect(function()
        if s and s.Parent then s:Destroy() end
    end)
end

-- ==================== 🖱 拖拽（共用全局单指针）====================
local function MakeDraggable(handle, target, opts)
    opts = opts or {}
    local dragStart, startPos, moved

    local scale = target:FindFirstChildOfClass("UIScale")
    if not scale then
        scale = Instance.new("UIScale")
        scale.Parent = target
    end

    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            moved = false
            dragStart = input.Position
            startPos = target.Position
            if opts.scaleOnDrag then
                Animate(scale, 0.18, Enum.EasingStyle.Back, Enum.EasingDirection.Out,
                    { Scale = 1.08 })
            end

            ActiveDrag = function(inp)
                local delta = inp.Position - dragStart
                if delta.Magnitude > 4 then moved = true end
                target.Position = UDim2.new(
                    startPos.X.Scale, startPos.X.Offset + delta.X,
                    startPos.Y.Scale, startPos.Y.Offset + delta.Y
                )
            end
        end
    end)

    handle.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
            if opts.scaleOnDrag then
                Animate(scale, 0.35, Enum.EasingStyle.Back, Enum.EasingDirection.Out,
                    { Scale = 1 })
            end
            if moved and opts.onDragEnd then opts.onDragEnd() end
            dragStart = nil
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

    -- 用 Frame + 手动控制透明度（比 CanvasGroup 更轻）
    local Toast = Instance.new("Frame")
    Toast.Size = UDim2.new(1, 0, 0, 52)
    Toast.BackgroundColor3 = Library.Theme.GlassCard
    Toast.BackgroundTransparency = 1
    Toast.BorderSizePixel = 0
    Toast.Parent = container.FrameList
    ApplyGlass(Toast, { radius = 14, stroke = true, strokeColor = style.color,
        strokeTransparency = 0.6 })

    local AccentBar = Instance.new("Frame")
    AccentBar.Size = UDim2.new(0, 3, 0, 26)
    AccentBar.Position = UDim2.new(0, 8, 0.5, -13)
    AccentBar.BackgroundColor3 = style.color
    AccentBar.BorderSizePixel = 0
    AccentBar.BackgroundTransparency = 1
    AccentBar.Parent = Toast
    local bc = Instance.new("UICorner") bc.CornerRadius = UDim.new(1, 0) bc.Parent = AccentBar

    local Title = Instance.new("TextLabel")
    Title.Size = UDim2.new(1, -32, 0, 18)
    Title.Position = UDim2.new(0, 18, 0, 7)
    Title.BackgroundTransparency = 1
    Title.Text = titleText:upper()
    Title.TextColor3 = style.color
    Title.TextSize = 11
    Title.TextTransparency = 1
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
    Desc.TextTransparency = 1
    ApplyFont(Desc, Enum.FontWeight.Medium)
    Desc.TextXAlignment = Enum.TextXAlignment.Left
    Desc.Parent = Toast

    local Track = Instance.new("Frame")
    Track.Size = UDim2.new(1, -24, 0, 3)
    Track.Position = UDim2.new(0, 12, 1, -7)
    Track.BackgroundColor3 = Library.Theme.AccentSoft
    Track.BackgroundTransparency = 1
    Track.BorderSizePixel = 0
    Track.Parent = Toast
    local tc = Instance.new("UICorner") tc.CornerRadius = UDim.new(1, 0) tc.Parent = Track

    local Bar = Instance.new("Frame")
    Bar.Size = UDim2.new(1, 0, 1, 0)
    Bar.BackgroundColor3 = style.color
    Bar.BorderSizePixel = 0
    Bar.Parent = Track
    local brc = Instance.new("UICorner") brc.CornerRadius = UDim.new(1, 0) brc.Parent = Bar

    -- 淡入
    Animate(Toast, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
        { BackgroundTransparency = 0.15 })
    Animate(AccentBar, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
        { BackgroundTransparency = 0 })
    Animate(Title, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { TextTransparency = 0 })
    Animate(Desc, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, { TextTransparency = 0 })
    Animate(Track, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
        { BackgroundTransparency = 0.5 })
    Animate(Bar, duration, Enum.EasingStyle.Linear, Enum.EasingDirection.Out,
        { Size = UDim2.new(0, 0, 1, 0) })

    -- 淡出
    task.delay(duration, function()
        if not Toast.Parent then return end
        Animate(Toast, 0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In, {
            BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 0),
        })
        Animate(AccentBar, 0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In,
            { BackgroundTransparency = 1 })
        Animate(Title, 0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In,
            { TextTransparency = 1 })
        Animate(Desc, 0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In,
            { TextTransparency = 1 })
        Animate(Track, 0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.In,
            { BackgroundTransparency = 1 })
        task.delay(0.3, function()
            if Toast.Parent then Toast:Destroy() end
        end)
    end)
end

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
    if not newFamily then return false end
    Library.CurrentFontFamily = newFamily
    for _, gui in ipairs(GetGuiParent():GetChildren()) do
        if gui.Name:match("^qwqMorph_") or gui.Name == "qwqNotifications" then
            for _, d in ipairs(gui:GetDescendants()) do
                if d:IsA("TextLabel") or d:IsA("TextButton") or d:IsA("TextBox") then
                    ApplyFont(d, Enum.FontWeight.SemiBold)
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

    local ScreenGui = Instance.new("ScreenGui")
    ScreenGui.Name = "qwqMorph_" .. math.random(1000, 9999)
    ScreenGui.ResetOnSpawn = false
    ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    ScreenGui.Parent = GetGuiParent()

    for _, old in ipairs(GetGuiParent():GetChildren()) do
        if old ~= ScreenGui and old.Name:match("^qwqMorph_") then
            old:Destroy()
        end
    end

    -- ---------- 🌑 暗化遮罩（代替 BlurEffect）----------
    -- 视觉：展开时游戏变暗，UI 聚焦。性能：0 开销
    local Dimmer = Instance.new("Frame")
    Dimmer.Name = "qwqDimmer"
    Dimmer.Size = UDim2.new(1, 0, 1, 0)
    Dimmer.BackgroundColor3 = Library.Theme.DimColor
    Dimmer.BackgroundTransparency = 1
    Dimmer.BorderSizePixel = 0
    Dimmer.ZIndex = 0
    Dimmer.Parent = ScreenGui

    -- 想更高级可以再加一层渐晕（vignette），取消下面的注释：
    --[[
    local Vignette = Instance.new("Frame")
    Vignette.Size = UDim2.new(1, 0, 1, 0)
    Vignette.BackgroundColor3 = Color3.fromRGB(20, 10, 20)
    Vignette.BackgroundTransparency = 1
    Vignette.ZIndex = 0
    Vignette.Parent = ScreenGui
    local vg = Instance.new("UIGradient")
    vg.Rotation = 45
    vg.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.00, 0.3),
        NumberSequenceKeypoint.new(0.50, 0.85),
        NumberSequenceKeypoint.new(1.00, 0.3),
    })
    vg.Parent = Vignette
    --]]

    -- ---------- 尺寸参数 ----------
    local windowSize    = UDim2.new(0, 500, 0, 340)
    local windowCenter  = UDim2.new(0.5, -250, 0.5, -170)
    local floatSize     = UDim2.new(0, 52, 0, 52)
    local lastFloatPos  = UDim2.new(0.92, 0, 0.5, -26)

    -- ---------- MainFrame ----------
    local MainFrame = Instance.new("Frame")
    MainFrame.Name = "MainFrame"
    MainFrame.Size = floatSize
    MainFrame.Position = lastFloatPos
    MainFrame.BackgroundColor3 = Library.Theme.GlassCard
    MainFrame.BackgroundTransparency = 0.15
    MainFrame.BorderSizePixel = 0
    MainFrame.ClipsDescendants = true
    MainFrame.ZIndex = 2
    MainFrame.Parent = ScreenGui

    local MainCorner = Instance.new("UICorner")
    MainCorner.CornerRadius = UDim.new(1, 0)
    MainCorner.Parent = MainFrame

    local MainStroke = Instance.new("UIStroke")
    MainStroke.Color = accentColor
    MainStroke.Thickness = 1
    MainStroke.Transparency = 0.4
    MainStroke.Parent = MainFrame

    -- 主渐变（玻璃反光）
    local MainGrad = Instance.new("UIGradient")
    MainGrad.Rotation = 90
    MainGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(250, 244, 250)),
    })
    MainGrad.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0.00, 0.05),
        NumberSequenceKeypoint.new(0.55, 0.28),
        NumberSequenceKeypoint.new(1.00, 0.12),
    })
    MainGrad.Parent = MainFrame

    -- ---------- MIUI 悬浮球图标（三条横线）----------
    local HandleIcon = Instance.new("Frame")
    HandleIcon.Name = "HandleIcon"
    HandleIcon.Size = UDim2.new(1, 0, 1, 0)
    HandleIcon.BackgroundTransparency = 1
    HandleIcon.Parent = MainFrame

    local handleLines = {}
    for i = 1, 3 do
        local line = Instance.new("Frame")
        line.Size = UDim2.new(0, 18, 0, 2)
        line.Position = UDim2.new(0.5, -9, 0.5, -8 + (i - 1) * 6)
        line.BackgroundColor3 = accentColor
        line.BorderSizePixel = 0
        line.Parent = HandleIcon

        local lc = Instance.new("UICorner")
        lc.CornerRadius = UDim.new(1, 0)
        lc.Parent = line
        table.insert(handleLines, line)
    end

    -- ---------- 内容容器 ----------
    local ContentContainer = Instance.new("Frame")
    ContentContainer.Name = "ContentContainer"
    ContentContainer.Size = UDim2.new(1, 0, 1, 0)
    ContentContainer.BackgroundTransparency = 1
    ContentContainer.Visible = false
    ContentContainer.ZIndex = 3
    ContentContainer.Parent = MainFrame

    local isMinimized = true
    local animating = false
    local closing = false

    -- ---------- 窗口展开 ----------
    local function Expand()
        lastFloatPos = MainFrame.Position

        -- 悬浮球图标淡出
        for _, line in ipairs(handleLines) do
            Animate(line, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                { BackgroundTransparency = 1 })
        end
        task.delay(0.15, function()
            HandleIcon.Visible = false
        end)

        MainStroke.Thickness = 1

        -- 圆角先跑
        Animate(MainCorner, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
            { CornerRadius = UDim.new(0, 16) })

        -- 尺寸 + 位置 + 暗化
        Animate(MainFrame, 0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
            Size = windowSize,
            Position = windowCenter,
            BackgroundTransparency = 0.25,
        })
        Animate(Dimmer, 0.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
            { BackgroundTransparency = Library.Theme.DimAmount })

        -- 内容淡入
        task.delay(0.25, function()
            ContentContainer.Visible = true
            for _, d in ipairs(ContentContainer:GetDescendants()) do
                if d:IsA("GuiObject") then
                    -- 已经存在的元素，透明度从 1 → 0
                    -- 用子容器统一处理太复杂，这里直接靠 MainFrame 的展开盖过
                end
            end
        end)
    end

    -- ---------- 窗口最小化 ----------
    local function Minimize()
        ContentContainer.Visible = false

        task.delay(0.05, function()
            Animate(MainCorner, 0.28, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                { CornerRadius = UDim.new(1, 0) })
            Animate(Dimmer, 0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                { BackgroundTransparency = 1 })

            local back = Animate(MainFrame, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
                Size = floatSize,
                Position = lastFloatPos,
                BackgroundTransparency = 0.15,
            })

            back.Completed:Connect(function()
                HandleIcon.Visible = true
                for _, line in ipairs(handleLines) do
                    line.BackgroundTransparency = 1
                    Animate(line, 0.25, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                        { BackgroundTransparency = 0 })
                end
                animating = false
            end)
        end)
    end

    -- ---------- 关闭 ----------
    local function CloseUI()
        if closing then return end
        closing = true

        Animate(Dimmer, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
            { BackgroundTransparency = 1 })
        Animate(MainStroke, 0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
            { Transparency = 1 })

        local viewport = workspace.CurrentCamera.ViewportSize
        local centerX = MainFrame.AbsolutePosition.X + MainFrame.AbsoluteSize.X / 2
        local centerY = MainFrame.AbsolutePosition.Y + MainFrame.AbsoluteSize.Y / 2

        Animate(MainCorner, 0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In,
            { CornerRadius = UDim.new(1, 0) })

        local t = Animate(MainFrame, 0.4, Enum.EasingStyle.Back, Enum.EasingDirection.In, {
            Size = UDim2.new(0, 0, 0, 0),
            Position = UDim2.new(0, centerX, 0, centerY),
            BackgroundTransparency = 1,
        })

        t.Completed:Connect(function()
            if rotationConn then rotationConn:Disconnect() end
            if fpsConn then fpsConn:Disconnect() end
            ScreenGui:Destroy()
        end)
    end

    local rotationConn = nil -- 占位（v3 无星核旋转）

    -- ---------- 状态切换 ----------
    local function ToggleUI()
        if animating or closing then return end
        animating = true
        isMinimized = not isMinimized
        if isMinimized then Minimize() else Expand() end
    end

    -- 悬浮球点击检测
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

    -- ---------- 悬浮球吸附边缘 ----------
    local function SnapToEdge()
        if not isMinimized then return end
        local viewport = workspace.CurrentCamera.ViewportSize
        local pos = MainFrame.AbsolutePosition
        local size = MainFrame.AbsoluteSize
        local centerX = pos.X + size.X / 2
        local targetX
        if centerX < viewport.X / 2 then
            targetX = 12
        else
            targetX = viewport.X - size.X - 12
        end
        local targetY = math.clamp(pos.Y, 12, viewport.Y - size.Y - 12)
        Animate(MainFrame, 0.32, Enum.EasingStyle.Back, Enum.EasingDirection.Out, {
            Position = UDim2.new(0, targetX, 0, targetY)
        })
        lastFloatPos = UDim2.new(0, targetX, 0, targetY)
    end

    MakeDraggable(MainFrame, MainFrame, {
        scaleOnDrag = true,
        onDragEnd = function()
            if isMinimized then SnapToEdge() end
        end,
    })

    -- ---------- 标题栏 ----------
    local TopBar = Instance.new("Frame")
    TopBar.Name = "TopBar"
    TopBar.Size = UDim2.new(1, 0, 0, 44)
    TopBar.BackgroundColor3 = Library.Theme.GlassCard
    TopBar.BackgroundTransparency = 0.3
    TopBar.BorderSizePixel = 0
    TopBar.Parent = ContentContainer
    ApplyGlass(TopBar, { radius = 16, stroke = true, gradient = true,
        strokeTransparency = 0.55 })

    local TopCover = Instance.new("Frame")
    TopCover.Size = UDim2.new(1, 0, 0, 14)
    TopCover.Position = UDim2.new(0, 0, 1, -14)
    TopCover.BackgroundColor3 = Library.Theme.GlassCard
    TopCover.BackgroundTransparency = 0.3
    TopCover.BorderSizePixel = 0
    TopCover.Parent = TopBar

    local BrandDot = Instance.new("Frame")
    BrandDot.Size = UDim2.new(0, 8, 0, 8)
    BrandDot.Position = UDim2.new(0, 18, 0.5, -4)
    BrandDot.BackgroundColor3 = accentColor
    BrandDot.BorderSizePixel = 0
    BrandDot.Parent = TopBar
    local bdc = Instance.new("UICorner") bdc.CornerRadius = UDim.new(1, 0) bdc.Parent = BrandDot

    -- 用 Tween 循环代替 while（性能更好）
    local breathe = TweenService:Create(BrandDot,
        TweenInfo.new(1.8, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true),
        { BackgroundTransparency = 0.5 })
    breathe:Play()

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

        local c = Instance.new("UICorner") c.CornerRadius = UDim.new(1, 0) c.Parent = btn

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
    MakeDotButton("×", -34, CloseUI)

    MakeDraggable(TopBar, MainFrame)

    -- ---------- 侧边栏 ----------
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
    ApplyGlass(InfoPanel, { radius = 12, stroke = true, strokeTransparency = 0.55 })

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

    -- FPS 用 Heartbeat，且最小化时不采样
    local frameCount, lastTime = 0, os.clock()
    local fpsConn = RunService.Heartbeat:Connect(function()
        if isMinimized then return end
        frameCount += 1
        local now = os.clock()
        if now - lastTime >= 1 then
            FpsLabel.Text = string.format("帧率: %d FPS",
                math.floor(frameCount / (now - lastTime)))
            frameCount = 0
            lastTime = now
        end
    end)

    task.spawn(function()
        while task.wait(2) do
            if not ScreenGui.Parent then break end
            local ok, vol = pcall(function()
                return math.floor(UserSettings():GetService("UserGameSettings").MasterVolume * 100)
            end)
            if ok then VolLabel.Text = "音量: " .. vol .. "%" end
        end
    end)

    -- ---------- 内容区 ----------
    local ContentFrame = Instance.new("Frame")
    ContentFrame.Name = "ContentFrame"
    ContentFrame.Size = UDim2.new(1, -132, 1, -56)
    ContentFrame.Position = UDim2.new(0, 126, 0, 48)
    ContentFrame.BackgroundTransparency = 1
    ContentFrame.Parent = ContentContainer

    local Pages = {}
    local CurrentTab = nil

    -- ============================================================
    -- 📑 Tab
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

        -- 侧栏 Tab 按钮（玻璃胶囊）
        local TabBtn = Instance.new("TextButton")
        TabBtn.Size = UDim2.new(1, -4, 0, 34)
        TabBtn.BackgroundColor3 = Library.Theme.GlassCard
        TabBtn.BackgroundTransparency = 1
        TabBtn.Text = ""
        TabBtn.AutoButtonColor = false
        TabBtn.Parent = TabContainer

        local TabCorner = Instance.new("UICorner")
        TabCorner.CornerRadius = UDim.new(0, 10)
        TabCorner.Parent = TabBtn

        local TabGrad = Instance.new("UIGradient")
        TabGrad.Rotation = 90
        TabGrad.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0.00, Color3.fromRGB(255, 255, 255)),
            ColorSequenceKeypoint.new(1.00, Library.Theme.Glass),
        })
        TabGrad.Transparency = NumberSequence.new({
            NumberSequenceKeypoint.new(0.00, 0.2),
            NumberSequenceKeypoint.new(1.00, 0.3),
        })
        TabGrad.Parent = TabBtn

        local TabStroke = Instance.new("UIStroke")
        TabStroke.Color = accentColor
        TabStroke.Thickness = 1
        TabStroke.Transparency = 1
        TabStroke.Parent = TabBtn

        local Marker = Instance.new("Frame")
        Marker.Name = "Marker"
        Marker.Size = UDim2.new(0, 3, 0, 16)
        Marker.Position = UDim2.new(0, 0, 0.5, -8)
        Marker.BackgroundColor3 = accentColor
        Marker.BackgroundTransparency = 1
        Marker.BorderSizePixel = 0
        Marker.Parent = TabBtn
        local mc = Instance.new("UICorner") mc.CornerRadius = UDim.new(1, 0) mc.Parent = Marker

        local TabLabel = Instance.new("TextLabel")
        TabLabel.Size = UDim2.new(1, -14, 1, 0)
        TabLabel.Position = UDim2.new(0, 12, 0, 0)
        TabLabel.BackgroundTransparency = 1
        TabLabel.Text = tabName
        TabLabel.TextColor3 = Library.Theme.TextSecond
        TabLabel.TextSize = 11
        ApplyFont(TabLabel, Enum.FontWeight.SemiBold)
        TabLabel.TextXAlignment = Enum.TextXAlignment.Left
        TabLabel.Parent = TabBtn

        local function Select()
            for _, child in ipairs(ContentFrame:GetChildren()) do
                if child:IsA("ScrollingFrame") then child.Visible = false end
            end
            for _, btn in ipairs(TabContainer:GetChildren()) do
                if btn:IsA("TextButton") then
                    local label = btn:FindFirstChildOfClass("TextLabel")
                    if label then
                        Animate(label, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                            { TextColor3 = Library.Theme.TextSecond })
                    end
                    Animate(btn, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                        { BackgroundTransparency = 1 })
                    local st = btn:FindFirstChildOfClass("UIStroke")
                    if st then
                        Animate(st, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                            { Transparency = 1 })
                    end
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

            Animate(TabLabel, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                { TextColor3 = accentColor })
            Animate(TabBtn, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                { BackgroundTransparency = 0.25 })
            Animate(TabStroke, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                { Transparency = 0.45 })
            Animate(Marker, 0.25, Enum.EasingStyle.Back, Enum.EasingDirection.Out,
                { BackgroundTransparency = 0 })
        end

        TabBtn.MouseButton1Click:Connect(Select)

        if CurrentTab == nil then
            CurrentTab = tabName
            Select()
        end

        local Elements = {}

        local function MakeCard(height)
            local Card = Instance.new("Frame")
            Card.Size = UDim2.new(1, 0, 0, height)
            Card.BackgroundColor3 = Library.Theme.GlassCard
            Card.BackgroundTransparency = 0.3
            Card.Parent = Page
            ApplyGlass(Card, { radius = 12 })
            return Card
        end

        -- ============================================================
        -- Label / Section / Divider / Paragraph
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
            local lc = Instance.new("UICorner") lc.CornerRadius = UDim.new(1, 0) lc.Parent = Line

            local T = Instance.new("TextLabel")
            T.Size = UDim2.new(1, -14, 1, 0)
            T.Position = UDim2.new(0, 10, 0, 0)
            T.BackgroundTransparency = 1
            T.Text = titleText:upper()
            T.TextColor3 = Library.Theme.TextSecond
            T.TextSize = 10
            ApplyFont(T, Enum.FontWeight.Bold)
            T.TextXAlignment = Enum.TextXAlignment.Left
            T.Parent = Holder
            return Holder
        end

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

            local g = Instance.new("UIGradient")
            g.Transparency = NumberSequence.new({
                NumberSequenceKeypoint.new(0, 1),
                NumberSequenceKeypoint.new(0.5, 0),
                NumberSequenceKeypoint.new(1, 1),
            })
            g.Parent = Line
            return Holder
        end

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
            return { SetText = function(_, t) Box.Text = t end, Frame = Holder }
        end

        -- ============================================================
        -- Button
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
            ApplyGlass(Btn, { radius = 12 })

            local hoverStroke
            Btn.MouseEnter:Connect(function()
                Animate(Btn, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                    { BackgroundTransparency = 0.15 })
                if not hoverStroke or not hoverStroke.Parent then
                    hoverStroke = AddHoverStroke(Btn, accentColor)
                end
            end)
            Btn.MouseLeave:Connect(function()
                Animate(Btn, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                    { BackgroundTransparency = 0.3 })
                RemoveHoverStroke(hoverStroke)
                hoverStroke = nil
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
        -- Toggle · MIUI 14 胶囊
        -- ============================================================
        function Elements:CreateToggle(text, default, callback)
            local state = default or false
            callback = callback or function() end

            local Card = MakeCard(40)
            local CardStroke = Instance.new("UIStroke")
            CardStroke.Color = Library.Theme.GlassBorder
            CardStroke.Thickness = 1
            CardStroke.Transparency = 0.55
            CardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            CardStroke.Parent = Card

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
            local sc = Instance.new("UICorner") sc.CornerRadius = UDim.new(1, 0) sc.Parent = Switch

            local Dot = Instance.new("Frame")
            Dot.Size = UDim2.new(0, 18, 0, 18)
            Dot.Position = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)
            Dot.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
            Dot.Parent = Switch
            local dc = Instance.new("UICorner") dc.CornerRadius = UDim.new(1, 0) dc.Parent = Dot

            local function Update()
                local targetColor = state and accentColor or Library.Theme.SwitchOff
                local targetPos = state and UDim2.new(1, -21, 0.5, -9) or UDim2.new(0, 3, 0.5, -9)

                Animate(Dot, 0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                    { Size = UDim2.new(0, 26, 0, 16) })
                task.delay(0.1, function()
                    Animate(Dot, 0.22, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out,
                        { Size = UDim2.new(0, 18, 0, 18) })
                end)
                Animate(Switch, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                    { BackgroundColor3 = targetColor })
                Animate(Dot, 0.26, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out,
                    { Position = targetPos })

                Animate(CardStroke, 0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
                    Color = state and accentColor or Library.Theme.GlassBorder,
                    Transparency = state and 0.35 or 0.55,
                })

                task.spawn(function() pcall(callback, state) end)
            end

            Click.MouseButton1Click:Connect(function()
                state = not state
                Update()
            end)
            return { Set = function(_, v) state = v Update() end }
        end

        -- ============================================================
        -- Slider（走全局指针）
        -- ============================================================
        function Elements:CreateSlider(text, min, max, default, callback)
            min = min or 0
            max = max or 100
            default = default or min
            callback = callback or function() end

            local Card = MakeCard(34)

            local Fill = Instance.new("Frame")
            Fill.Size = UDim2.new((default - min) / (max - min), 0, 1, 0)
            Fill.BackgroundColor3 = accentColor
            Fill.BackgroundTransparency = 0.5
            Fill.BorderSizePixel = 0
            Fill.ZIndex = 1
            Fill.Parent = Card
            local fc = Instance.new("UICorner") fc.CornerRadius = UDim.new(0, 12) fc.Parent = Fill

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
                    Update(input)
                    ActiveDrag = Update
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
        -- Input
        -- ============================================================
        function Elements:CreateInput(placeholder, callback)
            placeholder = placeholder or "请输入参数并回车..."
            callback = callback or function() end

            local Card = MakeCard(36)
            local CardStroke = Instance.new("UIStroke")
            CardStroke.Color = Library.Theme.GlassBorder
            CardStroke.Thickness = 1
            CardStroke.Transparency = 0.55
            CardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            CardStroke.Parent = Card

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
                Animate(CardStroke, 0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                    { Color = accentColor, Transparency = 0.25 })
            end)
            Box.FocusLost:Connect(function()
                Animate(CardStroke, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                    { Color = Library.Theme.GlassBorder, Transparency = 0.55 })
                task.spawn(function() pcall(callback, Box.Text) end)
            end)
            return {
                GetText = function() return Box.Text end,
                SetText = function(_, t) Box.Text = t end,
            }
        end

        -- ============================================================
        -- Dropdown
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
            ApplyGlass(Card, { radius = 12, stroke = true, strokeTransparency = 0.55 })

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
                    local oc = Instance.new("UICorner") oc.CornerRadius = UDim.new(0, 8) oc.Parent = Opt

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
        -- Keybind（修复 EnumItem 报错）
        -- ============================================================
        function Elements:CreateKeybind(text, default, callback)
            callback = callback or function() end
            local currentKey = KeyToString(default)

            local Card = MakeCard(40)
            local CardStroke = Instance.new("UIStroke")
            CardStroke.Color = Library.Theme.GlassBorder
            CardStroke.Thickness = 1
            CardStroke.Transparency = 0.55
            CardStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
            CardStroke.Parent = Card

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
            local kc = Instance.new("UICorner") kc.CornerRadius = UDim.new(0, 9) kc.Parent = KeyBtn

            local listenConn
            local listening = false

            local function StopListening()
                listening = false
                if listenConn then listenConn:Disconnect() listenConn = nil end
                KeyBtn.Text = currentKey
                Animate(KeyBtn, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out, {
                    BackgroundColor3 = Library.Theme.AccentSoft,
                    TextColor3 = Library.Theme.AccentDeep,
                    BackgroundTransparency = 0.25,
                })
                Animate(CardStroke, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
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
                Animate(CardStroke, 0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
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
                    currentKey = KeyToString(key)
                    KeyBtn.Text = currentKey
                end,
            }
        end

        -- ============================================================
        -- ColorPicker（走全局指针）
        -- ============================================================
        function Elements:CreateColorPicker(text, default, callback)
            default = default or Color3.fromRGB(236, 138, 169)
            callback = callback or function() end
            local current = default

            local Card = MakeCard(48)
            ApplyGlass(Card, { radius = 12 })

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
            local pc = Instance.new("UICorner") pc.CornerRadius = UDim.new(0, 7) pc.Parent = Preview

            local Track = Instance.new("Frame")
            Track.Size = UDim2.new(1, -22, 0, 12)
            Track.Position = UDim2.new(0, 11, 0, 30)
            Track.BackgroundColor3 = Library.Theme.AccentSoft
            Track.BackgroundTransparency = 0.5
            Track.BorderSizePixel = 0
            Track.ClipsDescendants = true
            Track.Parent = Card
            local tc = Instance.new("UICorner") tc.CornerRadius = UDim.new(1, 0) tc.Parent = Track

            local function MakeCh(color, offsetRatio, ch)
                local strip = Instance.new("Frame")
                strip.Size = UDim2.new(0.32, -4, 1, 0)
                strip.Position = UDim2.new(offsetRatio, 0, 0, 0)
                strip.BackgroundColor3 = color
                strip.BackgroundTransparency = 0.25
                strip.BorderSizePixel = 0
                strip.Parent = Track
                local sc = Instance.new("UICorner") sc.CornerRadius = UDim.new(1, 0) sc.Parent = strip

                local btn = Instance.new("TextButton")
                btn.Size = UDim2.new(0.32, -4, 1, 0)
                btn.Position = UDim2.new(offsetRatio, 0, 0, 0)
                btn.BackgroundTransparency = 1
                btn.Text = ""
                btn.Parent = Track

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
                        Update(input)
                        ActiveDrag = Update
                    end
                end)
            end

            MakeCh(Color3.fromRGB(236, 100, 130), 0.00, "r")
            MakeCh(Color3.fromRGB(120, 210, 150), 0.34, "g")
            MakeCh(Color3.fromRGB(120, 160, 240), 0.68, "b")

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
        -- MultiButton
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
                ApplyGlass(Btn, { radius = 10 })

                local hoverStroke
                Btn.MouseEnter:Connect(function()
                    Animate(Btn, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                        { BackgroundTransparency = 0.15 })
                    if not hoverStroke or not hoverStroke.Parent then
                        hoverStroke = AddHoverStroke(Btn, accentColor)
                    end
                end)
                Btn.MouseLeave:Connect(function()
                    Animate(Btn, 0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out,
                        { BackgroundTransparency = 0.3 })
                    RemoveHoverStroke(hoverStroke)
                    hoverStroke = nil
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