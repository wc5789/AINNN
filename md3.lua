--!strict
-- MD3UI.lua
-- Material Design 3 风格的 Roblox UI 库
-- 用法：local MD3 = require(path.to.MD3UI)

local MD3 = {}

--============================================================
-- 1. MD3 颜色系统（Token-based）
--============================================================
-- MD3 使用基于色彩角色的系统：Primary、Surface、OnSurface 等。
-- 参考：https://m3.material.io/ 的颜色角色规范[reference:0]

local function hex(hexStr)
    return Color3.fromHex(hexStr)
end

MD3.Theme = {
    Dark = {
        -- Primary 色组
        Primary = hex("#D0BCFF"),
        OnPrimary = hex("#381E72"),
        PrimaryContainer = hex("#4F378B"),
        OnPrimaryContainer = hex("#EADDFF"),

        -- Secondary 色组
        Secondary = hex("#CCC2DC"),
        OnSecondary = hex("#332D41"),
        SecondaryContainer = hex("#4A4458"),
        OnSecondaryContainer = hex("#E8DEF8"),

        -- Surface 色组
        Surface = hex("#1C1B1F"),
        OnSurface = hex("#E6E1E5"),
        SurfaceVariant = hex("#49454F"),
        OnSurfaceVariant = hex("#CAC4D0"),
        SurfaceContainer = hex("#211F26"),

        -- 其他
        Outline = hex("#938F99"),
        Error = hex("#F2B8B5"),
        OnError = hex("#601410"),
    },
    Light = {
        Primary = hex("#6750A4"),
        OnPrimary = hex("#FFFFFF"),
        PrimaryContainer = hex("#EADDFF"),
        OnPrimaryContainer = hex("#21005D"),

        Secondary = hex("#625B71"),
        OnSecondary = hex("#FFFFFF"),
        SecondaryContainer = hex("#E8DEF8"),
        OnSecondaryContainer = hex("#1D192B"),

        Surface = hex("#FEF7FF"),
        OnSurface = hex("#1D1B20"),
        SurfaceVariant = hex("#E7E0EC"),
        OnSurfaceVariant = hex("#49454F"),
        SurfaceContainer = hex("#F3EDF7"),

        Outline = hex("#79747E"),
        Error = hex("#B3261E"),
        OnError = hex("#FFFFFF"),
    },
}

--============================================================
-- 2. 工具函数
--============================================================

local function new(className: string, props: {[string]: any})
    local inst = Instance.new(className)
    for k, v in pairs(props) do
        if k ~= "Parent" then
            inst[k] = v
        end
    end
    if props.Parent then
        inst.Parent = props.Parent
    end
    return inst
end

local function addCorner(parent: Instance, radius: UDim)
    local c = Instance.new("UICorner")
    c.CornerRadius = radius
    c.Parent = parent
    return c
end

local function addPadding(parent: Instance, padding: UDim)
    local p = Instance.new("UIPadding")
    p.PaddingTop = padding
    p.PaddingBottom = padding
    p.PaddingLeft = padding
    p.PaddingRight = padding
    p.Parent = parent
    return p
end

local function addListLayout(parent: Instance, props: {[string]: any})
    local layout = Instance.new("UIListLayout")
    for k, v in pairs(props) do
        layout[k] = v
    end
    layout.Parent = parent
    return layout
end

--============================================================
-- 3. 主题上下文
--============================================================

local currentTheme = MD3.Theme.Dark

function MD3.setTheme(name: string)
    if MD3.Theme[name] then
        currentTheme = MD3.Theme[name]
    else
        warn("[MD3UI] 未知主题: " .. name)
    end
end

local function C(role: string): Color3
    return currentTheme[role] or Color3.new(1, 1, 1)
end

--============================================================
-- 4. 核心组件
--============================================================

local MD3UI = {}
MD3UI.__index = MD3UI

-- 创建根 ScreenGui
function MD3.new(parent: Instance?)
    local self = setmetatable({}, MD3UI)

    local screenGui = new("ScreenGui", {
        Name = "MD3UI",
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = true,
        Parent = parent or game:GetService("CoreGui"),
    })

    self.ScreenGui = screenGui
    self._connections = {}
    return self
end

--============================================================
-- 4.1 按钮（Filled Button）
--============================================================

function MD3UI:Button(props: {
    Parent: Instance,
    Text: string?,
    Width: UDim?,
    OnClick: (() -> ())?,
})
    local btn = new("TextButton", {
        Text = props.Text or "Button",
        Size = UDim2.new(1, 0, 0, 40),
        BackgroundColor3 = C("Primary"),
        TextColor3 = C("OnPrimary"),
        Font = Enum.Font.GothamMedium,
        TextSize = 14,
        AutoButtonColor = false,
        BorderSizePixel = 0,
        Parent = props.Parent,
    })
    btn.Size = UDim2.new(1, 0, 0, 40)
    if props.Width then btn.Size = props.Width end

    addCorner(btn, UDim.new(0, 20)) -- MD3 Filled Button 完全圆角[reference:1]

    -- 按下动画
    local pressConn
    pressConn = btn.MouseButton1Down:Connect(function()
        btn.BackgroundColor3 = C("PrimaryContainer")
    end)
    local releaseConn
    releaseConn = btn.MouseButton1Up:Connect(function()
        btn.BackgroundColor3 = C("Primary")
    end)
    table.insert(self._connections, pressConn)
    table.insert(self._connections, releaseConn)

    if props.OnClick then
        local clickConn = btn.MouseButton1Click:Connect(props.OnClick)
        table.insert(self._connections, clickConn)
    end

    return btn
end

--============================================================
-- 4.2 开关（Switch）
--============================================================

function MD3UI:Switch(props: {
    Parent: Instance,
    Text: string?,
    Default: boolean?,
    OnChanged: ((boolean) -> ())?,
})
    local container = new("Frame", {
        Size = UDim2.new(1, 0, 0, 56),
        BackgroundColor3 = C("SurfaceContainer"),
        BorderSizePixel = 0,
        Parent = props.Parent,
    })
    addCorner(container, UDim.new(0, 12))
    addPadding(container, UDim.new(0, 12))

    -- 左侧标签
    local label = new("TextLabel", {
        Text = props.Text or "Switch",
        Size = UDim2.new(1, -70, 1, 0),
        BackgroundTransparency = 1,
        TextColor3 = C("OnSurface"),
        Font = Enum.Font.GothamMedium,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container,
    })

    -- 右侧开关轨道
    local track = new("Frame", {
        Size = UDim2.new(0, 52, 0, 32),
        Position = UDim2.new(1, -52, 0.5, -16),
        BackgroundColor3 = C("SurfaceVariant"),
        BorderSizePixel = 0,
        Parent = container,
    })
    addCorner(track, UDim.new(0.5, 0)) -- 药丸形状

    -- 滑块
    local thumb = new("Frame", {
        Size = UDim2.new(0, 24, 0, 24),
        Position = UDim2.new(0, 4, 0.5, -12),
        BackgroundColor3 = C("OnSurfaceVariant"),
        BorderSizePixel = 0,
        Parent = track,
    })
    addCorner(thumb, UDim.new(0.5, 0))

    local state = props.Default or false
    local function update(animate: boolean)
        local goalTrackColor = state and C("Primary") or C("SurfaceVariant")
        local goalThumbColor = state and C("OnPrimary") or C("OnSurfaceVariant")
        local goalPosition = state and UDim2.new(1, -28, 0.5, -12) or UDim2.new(0, 4, 0.5, -12)

        if animate then
            track:TweenSize(
                UDim2.new(0, 52, 0, 32),
                Enum.EasingDirection.Out,
                Enum.EasingStyle.Quad,
                0.2,
                true
            )
            thumb:TweenPosition(goalPosition, Enum.EasingDirection.Out, Enum.EasingStyle.Quad, 0.2, true)
        else
            thumb.Position = goalPosition
        end
        track.BackgroundColor3 = goalTrackColor
        thumb.BackgroundColor3 = goalThumbColor
    end
    update(false)

    local conn = track.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            state = not state
            update(true)
            if props.OnChanged then props.OnChanged(state) end
        end
    end)
    table.insert(self._connections, conn)

    return container
end

--============================================================
-- 4.3 滑块（Slider）
--============================================================

function MD3UI:Slider(props: {
    Parent: Instance,
    Text: string?,
    Min: number?,
    Max: number?,
    Default: number?,
    OnChanged: ((number) -> ())?,
})
    local min = props.Min or 0
    local max = props.Max or 100
    local value = props.Default or min

    local container = new("Frame", {
        Size = UDim2.new(1, 0, 0, 64),
        BackgroundColor3 = C("SurfaceContainer"),
        BorderSizePixel = 0,
        Parent = props.Parent,
    })
    addCorner(container, UDim.new(0, 12))
    addPadding(container, UDim.new(0, 12))

    local label = new("TextLabel", {
        Text = (props.Text or "Slider") .. "  —  " .. tostring(math.floor(value)),
        Size = UDim2.new(1, 0, 0, 20),
        BackgroundTransparency = 1,
        TextColor3 = C("OnSurface"),
        Font = Enum.Font.GothamMedium,
        TextSize = 13,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = container,
    })

    local trackBg = new("Frame", {
        Size = UDim2.new(1, 0, 0, 4),
        Position = UDim2.new(0, 0, 0, 36),
        BackgroundColor3 = C("SurfaceVariant"),
        BorderSizePixel = 0,
        Parent = container,
    })
    addCorner(trackBg, UDim.new(0.5, 0))

    local fill = new("Frame", {
        Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
        BackgroundColor3 = C("Primary"),
        BorderSizePixel = 0,
        Parent = trackBg,
    })
    addCorner(fill, UDim.new(0.5, 0))

    -- 隐藏的输入区域
    local inputArea = new("TextButton", {
        Text = "",
        Size = UDim2.new(1, 0, 0, 24),
        Position = UDim2.new(0, 0, 0, 24),
        BackgroundTransparency = 1,
        Parent = container,
    })

    local dragging = false
    local function updateFromX(x: number)
        local relX = math.clamp((x - trackBg.AbsolutePosition.X) / trackBg.AbsoluteSize.X, 0, 1)
        value = min + relX * (max - min)
        fill.Size = UDim2.new(relX, 0, 1, 0)
        label.Text = (props.Text or "Slider") .. "  —  " .. tostring(math.floor(value))
        if props.OnChanged then props.OnChanged(value) end
    end

    local c1 = inputArea.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            updateFromX(input.Position.X)
        end
    end)
    local c2 = inputArea.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = false
        end
    end)
    local c3 = game:GetService("UserInputService").InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            updateFromX(input.Position.X)
        end
    end)
    table.insert(self._connections, c1)
    table.insert(self._connections, c2)
    table.insert(self._connections, c3)

    return container
end

--============================================================
-- 4.4 卡片（Card）
--============================================================

function MD3UI:Card(props: {
    Parent: Instance,
    Title: string?,
    Body: string?,
    Height: number?,
})
    local card = new("Frame", {
        Size = UDim2.new(1, 0, 0, props.Height or 100),
        BackgroundColor3 = C("SurfaceContainer"),
        BorderSizePixel = 0,
        Parent = props.Parent,
    })
    addCorner(card, UDim.new(0, 12))
    addPadding(card, UDim.new(0, 16))
    addListLayout(card, {
        FillDirection = Enum.FillDirection.Vertical,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Padding = UDim.new(0, 8),
    })

    if props.Title then
        new("TextLabel", {
            Text = props.Title,
            Size = UDim2.new(1, 0, 0, 24),
            BackgroundTransparency = 1,
            TextColor3 = C("OnSurface"),
            Font = Enum.Font.GothamBold,
            TextSize = 16,
            TextXAlignment = Enum.TextXAlignment.Left,
            LayoutOrder = 1,
            Parent = card,
        })
    end

    if props.Body then
        new("TextLabel", {
            Text = props.Body,
            Size = UDim2.new(1, 0, 1, -32),
            BackgroundTransparency = 1,
            TextColor3 = C("OnSurfaceVariant"),
            Font = Enum.Font.Gotham,
            TextSize = 13,
            TextWrapped = true,
            TextXAlignment = Enum.TextXAlignment.Left,
            TextYAlignment = Enum.TextYAlignment.Top,
            LayoutOrder = 2,
            Parent = card,
        })
    end

    return card
end

--============================================================
-- 4.5 分区标题（Section Title）
--============================================================

function MD3UI:SectionTitle(props: {
    Parent: Instance,
    Text: string,
})
    local label = new("TextLabel", {
        Text = props.Text,
        Size = UDim2.new(1, 0, 0, 32),
        BackgroundTransparency = 1,
        TextColor3 = C("Primary"),
        Font = Enum.Font.GothamBold,
        TextSize = 14,
        TextXAlignment = Enum.TextXAlignment.Left,
        Parent = props.Parent,
    })
    return label
end

--============================================================
-- 4.6 分割线（Divider）
--============================================================

function MD3UI:Divider(parent: Instance)
    local d = new("Frame", {
        Size = UDim2.new(1, 0, 0, 1),
        BackgroundColor3 = C("Outline"),
        BorderSizePixel = 0,
        Parent = parent,
    })
    return d
end

--============================================================
-- 5. 销毁与清理
--============================================================

function MD3UI:Destroy()
    for _, conn in ipairs(self._connections) do
        if typeof(conn) == "RBXScriptConnection" then
            conn:Disconnect()
        end
    end
    self._connections = {}
    if self.ScreenGui then
        self.ScreenGui:Destroy()
    end
end

--============================================================
-- 6. 顶层 API
--============================================================

function MD3.createWindow(props: {
    Parent: Instance?,
    Theme: string?,
}?)
    if props and props.Theme then
        MD3.setTheme(props.Theme)
    end
    return MD3.new(props and props.Parent or nil)
end

return MD3