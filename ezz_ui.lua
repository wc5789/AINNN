-- =========================================================
-- OriginOS 风格 UI 库 · 完整版
-- 圆角卡片 · 层次色阶 · 移动端适配 · 内容滚动
-- =========================================================

local a = {windowCount = 0, flags = {}, _conns = {}, _guis = {}}

local TweenService     = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local RunService       = game:GetService("RunService")
local HttpService      = game:GetService("HttpService")
local Players          = game:GetService("Players")

local CoreGui
pcall(function() CoreGui = game:GetService("CoreGui") end)

local plr = Players.LocalPlayer
if not plr then warn("[UI] 必须在 LocalScript 中运行"); return a end

local isMobile = UserInputService.TouchEnabled and not UserInputService.MouseEnabled

-- ============ 主题 ============
local C = {
    Bg        = Color3.fromRGB(18, 18, 20),
    Surface   = Color3.fromRGB(30, 30, 33),
    Surface2  = Color3.fromRGB(40, 40, 44),
    Surface3  = Color3.fromRGB(52, 52, 57),
    Surface4  = Color3.fromRGB(64, 64, 70),
    Text      = Color3.fromRGB(255, 255, 255),
    TextSub   = Color3.fromRGB(165, 165, 172),
    TextDim   = Color3.fromRGB(110, 110, 118),
    Accent    = Color3.fromRGB(131, 132, 255),
    Success   = Color3.fromRGB(52, 199, 89),
    Danger    = Color3.fromRGB(255, 69, 58),
    Warn      = Color3.fromRGB(255, 179, 64),
    Border    = Color3.fromRGB(58, 58, 63),
    White     = Color3.fromRGB(255, 255, 255),
}

-- ============ 尺寸 ============
local SZ = {
    WindowW    = 300,
    HeaderH    = 56,
    CardH      = 50,
    CardHBig   = 62,
    Pad        = 12,
    Gap        = 8,
    RadWin     = 20,
    RadCard    = 14,
    RadSmall   = 10,
}

-- ============ 工具 ============
local function trackConn(c)
    a._conns[#a._conns + 1] = c
    return c
end

local function Txt(v)
    if v == nil then return "" end
    return tostring(v)
end

local function corner(parent, r)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, r)
    c.Parent = parent
    return c
end

local function stroke(parent, color, thickness, transparency)
    local s = Instance.new("UIStroke")
    s.Color = color or C.Border
    s.Thickness = thickness or 1
    s.Transparency = transparency or 0.6
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function uiscale(parent)
    local s = Instance.new("UIScale")
    s.Parent = parent
    return s
end

-- 悬停
local function hover(frame, base, hov)
    trackConn(frame.MouseEnter:Connect(function()
        TweenService:Create(frame, TweenInfo.new(0.18, Enum.EasingStyle.Sine),
            {BackgroundColor3 = hov}):Play()
    end))
    trackConn(frame.MouseLeave:Connect(function()
        TweenService:Create(frame, TweenInfo.new(0.18, Enum.EasingStyle.Sine),
            {BackgroundColor3 = base}):Play()
    end))
end

-- ============ 全局输入状态 ============
local dragState  = nil
local slideState = nil
local zCounter   = 10

trackConn(UserInputService.InputChanged:Connect(function(p)
    if p.UserInputType ~= Enum.UserInputType.MouseMovement
        and p.UserInputType ~= Enum.UserInputType.Touch then return end
    if dragState then
        local d = p.Position - dragState.start
        local vp = workspace.CurrentCamera.ViewportSize
        local w = dragState.frame.AbsoluteSize.X
        local h = dragState.frame.AbsoluteSize.Y
        local nx = math.clamp(dragState.orig.X.Offset + d.X, 8, math.max(8, vp.X - w - 8))
        local ny = math.clamp(dragState.orig.Y.Offset + d.Y, 8, math.max(8, vp.Y - h - 8))
        dragState.frame.Position = UDim2.new(0, nx, 0, ny)
    end
    if slideState then slideState(p) end
end))

trackConn(UserInputService.InputEnded:Connect(function(p)
    if p.UserInputType == Enum.UserInputType.MouseButton1
        or p.UserInputType == Enum.UserInputType.Touch then
        dragState  = nil
        slideState = nil
    end
end))

-- ============ 主 GUI ============
local t = Instance.new("ScreenGui")
t.Name = HttpService:GenerateGUID()
t.ResetOnSpawn = false
t.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
t.IgnoreGuiInset = true
t.Parent = RunService:IsStudio() and plr:WaitForChild("PlayerGui") or CoreGui
a._guis[#a._guis + 1] = t

if not isMobile then
    trackConn(UserInputService.InputBegan:Connect(function(u, v)
        if u.KeyCode == Enum.KeyCode.LeftShift and not v then
            t.Enabled = not t.Enabled
        end
    end))
end

-- ============ 移动端悬浮按钮 ============
if UserInputService.TouchEnabled then
    local mg = Instance.new("ScreenGui")
    mg.Name = "OriginMobile"
    mg.ResetOnSpawn = false
    mg.IgnoreGuiInset = true
    mg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    mg.Parent = RunService:IsStudio() and plr:WaitForChild("PlayerGui") or CoreGui
    a._guis[#a._guis + 1] = mg

    local btn = Instance.new("TextButton")
    btn.Name = "Toggle"
    btn.AnchorPoint = Vector2.new(0, 1)
    btn.Position = UDim2.new(0, 16, 1, -16)
    btn.Size = UDim2.new(0, 56, 0, 56)
    btn.BackgroundColor3 = C.Surface2
    btn.AutoButtonColor = false
    btn.Text = ""
    btn.ZIndex = 100
    corner(btn, 18)
    stroke(btn, C.Border, 1, 0.4)

    local icon = Instance.new("TextLabel")
    icon.Parent = btn
    icon.BackgroundTransparency = 1
    icon.Size = UDim2.new(1, 0, 1, 0)
    icon.Font = Enum.Font.GothamBold
    icon.Text = "☰"
    icon.TextColor3 = C.Accent
    icon.TextSize = 26

    local mDrag, mDragged
    trackConn(btn.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            mDrag = {start = input.Position, orig = btn.Position}
            mDragged = false
        end
    end))
    trackConn(UserInputService.InputChanged:Connect(function(input)
        if not mDrag then return end
        if input.UserInputType ~= Enum.UserInputType.Touch
            and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local d = input.Position - mDrag.start
        if math.abs(d.X) > 6 or math.abs(d.Y) > 6 then mDragged = true end
        local vp = workspace.CurrentCamera.ViewportSize
        btn.Position = UDim2.new(0,
            math.clamp(mDrag.orig.X.Offset + d.X, 8, vp.X - 64),
            0,
            math.clamp(mDrag.orig.Y.Offset + d.Y, 8, vp.Y - 64))
    end))
    trackConn(UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            if mDrag and not mDragged then
                t.Enabled = not t.Enabled
            end
            mDrag = nil
        end
    end))
end

-- ============ 销毁 ============
function a:Destroy()
    for _, c in ipairs(self._conns) do
        pcall(function() c:Disconnect() end)
    end
    self._conns = {}
    for _, gui in ipairs(self._guis) do
        pcall(function() gui:Destroy() end)
    end
    self._guis = {}
end

-- ============ 窗口 ============
function a:Window(w)
    a.windowCount = a.windowCount + 1

    local vp = workspace.CurrentCamera.ViewportSize
    local winW = math.min(SZ.WindowW, vp.X - 24)
    local winX = isMobile and math.floor((vp.X - winW) / 2) or (25 + (a.windowCount - 1) * 24)
    local winY = isMobile and 90 or (60 + (a.windowCount - 1) * 24)

    -- 窗口主体
    local win = Instance.new("Frame")
    win.Name = "OriginWindow"
    win.Parent = t
    win.BackgroundColor3 = C.Surface
    win.BorderSizePixel = 0
    win.Position = UDim2.new(0, winX, 0, winY)
    win.Size = UDim2.new(0, winW, 0, SZ.HeaderH)
    win.ClipsDescendants = true
    win.ZIndex = zCounter
    corner(win, SZ.RadWin)
    stroke(win, C.Border, 1, 0.4)

    -- 头部
    local header = Instance.new("Frame")
    header.Name = "Header"
    header.Parent = win
    header.BackgroundTransparency = 1
    header.Size = UDim2.new(1, 0, 0, SZ.HeaderH)
    header.ZIndex = 2

    local title = Instance.new("TextLabel")
    title.Parent = header
    title.BackgroundTransparency = 1
    title.Position = UDim2.new(0, 20, 0, 0)
    title.Size = UDim2.new(1, -80, 1, 0)
    title.Font = Enum.Font.GothamBold
    title.Text = Txt(w)
    title.TextColor3 = C.Text
    title.TextSize = 15
    title.TextXAlignment = Enum.TextXAlignment.Left

    -- 折叠按钮
    local toggleBtn = Instance.new("TextButton")
    toggleBtn.Parent = header
    toggleBtn.AnchorPoint = Vector2.new(1, 0.5)
    toggleBtn.Position = UDim2.new(1, -14, 0.5, 0)
    toggleBtn.Size = UDim2.new(0, 34, 0, 34)
    toggleBtn.BackgroundColor3 = C.Surface2
    toggleBtn.BorderSizePixel = 0
    toggleBtn.Text = ""
    toggleBtn.AutoButtonColor = false
    corner(toggleBtn, 10)
    hover(toggleBtn, C.Surface2, C.Surface3)

    local chevron = Instance.new("ImageLabel")
    chevron.Parent = toggleBtn
    chevron.AnchorPoint = Vector2.new(0.5, 0.5)
    chevron.Position = UDim2.new(0.5, 0, 0.5, 0)
    chevron.Size = UDim2.new(0, 16, 0, 16)
    chevron.BackgroundTransparency = 1
    chevron.Image = "rbxassetid://3926305904"
    chevron.ImageRectOffset = Vector2.new(524, 764)
    chevron.ImageRectSize = Vector2.new(36, 36)
    chevron.ImageColor3 = C.TextSub
    chevron.Rotation = 180

    -- 内容区
    local body = Instance.new("ScrollingFrame")
    body.Name = "Body"
    body.Parent = win
    body.BackgroundTransparency = 1
    body.BorderSizePixel = 0
    body.Position = UDim2.new(0, 0, 0, SZ.HeaderH)
    body.Size = UDim2.new(1, 0, 0, 0)
    body.CanvasSize = UDim2.new(0, 0, 0, 0)
    body.AutomaticCanvasSize = Enum.AutomaticSize.Y
    body.ScrollBarThickness = 3
    body.ScrollBarImageColor3 = C.Surface4
    body.ScrollingDirection = Enum.ScrollingDirection.Y
    body.ElasticBehavior = Enum.ElasticBehavior.WhenScrollable
    body.ZIndex = 1

    local layout = Instance.new("UIListLayout")
    layout.Parent = body
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Padding = UDim.new(0, SZ.Gap)

    local pad = Instance.new("UIPadding")
    pad.Parent = body
    pad.PaddingTop = UDim.new(0, 8)
    pad.PaddingBottom = UDim.new(0, 14)
    pad.PaddingLeft = UDim.new(0, SZ.Pad)
    pad.PaddingRight = UDim.new(0, SZ.Pad)

    -- 拖动 & 置顶
    trackConn(header.InputBegan:Connect(function(p)
        if p.UserInputType == Enum.UserInputType.MouseButton1
            or p.UserInputType == Enum.UserInputType.Touch then
            zCounter = zCounter + 1
            win.ZIndex = zCounter
            dragState = {frame = win, start = p.Position, orig = win.Position}
        end
    end))

    -- 高度自适应
    local expanded = true
    local isAnimating = false

    local function computeBodyH()
        local vp2 = workspace.CurrentCamera.ViewportSize
        local maxH = math.max(120, vp2.Y * 0.68)
        local contentH = layout.AbsoluteContentSize.Y + 22
        return math.min(contentH, maxH)
    end

    local function applySize(animate)
        if not expanded then return end
        local bodyH = computeBodyH()
        local winH = SZ.HeaderH + bodyH
        local info = TweenInfo.new(animate and 0.2 or 0,
            Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(win, info,
            {Size = UDim2.new(0, winW, 0, winH)}):Play()
        TweenService:Create(body, info,
            {Size = UDim2.new(1, 0, 0, bodyH)}):Play()
    end

    trackConn(layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        if isAnimating then return end
        applySize(true)
    end))

    local function toggleExpand()
        if isAnimating then return end
        isAnimating = true
        expanded = not expanded
        local targetBodyH = expanded and computeBodyH() or 0
        local targetH = SZ.HeaderH + targetBodyH
        local info = TweenInfo.new(0.25,
            Enum.EasingStyle.Quad, Enum.EasingDirection.Out)
        TweenService:Create(win, info,
            {Size = UDim2.new(0, winW, 0, targetH)}):Play()
        TweenService:Create(body, info,
            {Size = UDim2.new(1, 0, 0, targetBodyH)}):Play()
        TweenService:Create(chevron, TweenInfo.new(0.25),
            {Rotation = expanded and 0 or 180}):Play()
        task.delay(0.26, function() isAnimating = false end)
    end

    trackConn(toggleBtn.MouseButton1Click:Connect(toggleExpand))

    -- 初次展开
    task.defer(function()
        task.wait(0.05)
        applySize(false)
    end)

    local K = {}

    -- ============ 基础控件 ============
    function K:Section(L)
        local s = Instance.new("TextLabel")
        s.Name = "Section"
        s.Parent = body
        s.BackgroundTransparency = 1
        s.Size = UDim2.new(1, 0, 0, 22)
        s.Font = Enum.Font.GothamBold
        s.Text = string.upper(Txt(L))
        s.TextColor3 = C.TextDim
        s.TextSize = 11
        s.TextXAlignment = Enum.TextXAlignment.Left
        s.TextYAlignment = Enum.TextYAlignment.Bottom
        return s
    end

    function K:Label(L)
        local card = Instance.new("Frame")
        card.Name = "LabelCard"
        card.Parent = body
        card.BackgroundColor3 = C.Surface2
        card.BorderSizePixel = 0
        card.Size = UDim2.new(1, 0, 0, 44)
        corner(card, SZ.RadCard)

        local text = Instance.new("TextLabel")
        text.Parent = card
        text.BackgroundTransparency = 1
        text.Position = UDim2.new(0, 16, 0, 0)
        text.Size = UDim2.new(1, -32, 1, 0)
        text.Font = Enum.Font.Gotham
        text.Text = Txt(L)
        text.TextColor3 = C.TextSub
        text.TextSize = 13
        text.TextXAlignment = Enum.TextXAlignment.Left
        return card
    end

    function K:Button(L, N)
        N = N or function() end
        local card = Instance.new("Frame")
        card.Name = "ButtonCard"
        card.Parent = body
        card.BackgroundColor3 = C.Surface2
        card.BorderSizePixel = 0
        card.Size = UDim2.new(1, 0, 0, SZ.CardH)
        corner(card, SZ.RadCard)

        local sc = uiscale(card)

        local btn = Instance.new("TextButton")
        btn.Parent = card
        btn.BackgroundTransparency = 1
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.Text = ""
        btn.AutoButtonColor = false

        local text = Instance.new("TextLabel")
        text.Parent = card
        text.BackgroundTransparency = 1
        text.Position = UDim2.new(0, 16, 0, 0)
        text.Size = UDim2.new(1, -32, 1, 0)
        text.Font = Enum.Font.GothamMedium
        text.Text = Txt(L)
        text.TextColor3 = C.Text
        text.TextSize = 14
        text.TextXAlignment = Enum.TextXAlignment.Left

        trackConn(btn.MouseButton1Down:Connect(function()
            TweenService:Create(card, TweenInfo.new(0.08),
                {BackgroundColor3 = C.Surface3}):Play()
            TweenService:Create(sc, TweenInfo.new(0.08), {Scale = 0.97}):Play()
        end))
        trackConn(btn.MouseButton1Up:Connect(function()
            TweenService:Create(card, TweenInfo.new(0.15),
                {BackgroundColor3 = C.Surface2}):Play()
            TweenService:Create(sc, TweenInfo.new(0.15), {Scale = 1}):Play()
        end))
        trackConn(btn.MouseEnter:Connect(function()
            TweenService:Create(card, TweenInfo.new(0.15),
                {BackgroundColor3 = C.Surface3}):Play()
        end))
        trackConn(btn.MouseLeave:Connect(function()
            TweenService:Create(card, TweenInfo.new(0.15),
                {BackgroundColor3 = C.Surface2}):Play()
        end))
        trackConn(btn.MouseButton1Click:Connect(function()
            local ok, err = pcall(N)
            if not ok then warn("[UI] Button:", err) end
        end))
        return card
    end

    -- Toggle
    function K:Toggle(Q, R, S, N, T)
        if type(R) == "boolean" and type(S) == "function" then
            N = S
            S = R
            R = Q
        end
        T = (type(T) == "table") and T or a.flags
        R = R or Q
        S = S == true
        N = N or function() end
        T[R] = S

        local card = Instance.new("Frame")
        card.Name = "ToggleCard"
        card.Parent = body
        card.BackgroundColor3 = C.Surface2
        card.BorderSizePixel = 0
        card.Size = UDim2.new(1, 0, 0, SZ.CardH)
        corner(card, SZ.RadCard)

        local text = Instance.new("TextLabel")
        text.Parent = card
        text.BackgroundTransparency = 1
        text.Position = UDim2.new(0, 16, 0, 0)
        text.Size = UDim2.new(1, -80, 1, 0)
        text.Font = Enum.Font.GothamMedium
        text.Text = Txt(Q)
        text.TextColor3 = C.Text
        text.TextSize = 14
        text.TextXAlignment = Enum.TextXAlignment.Left

        local swBg = Instance.new("Frame")
        swBg.Parent = card
        swBg.AnchorPoint = Vector2.new(1, 0.5)
        swBg.Position = UDim2.new(1, -16, 0.5, 0)
        swBg.Size = UDim2.new(0, 44, 0, 26)
        swBg.BackgroundColor3 = S and C.Accent or C.Surface4
        swBg.BorderSizePixel = 0
        corner(swBg, 13)

        local swKnob = Instance.new("Frame")
        swKnob.Parent = swBg
        swKnob.AnchorPoint = Vector2.new(0, 0.5)
        swKnob.Position = UDim2.new(0, S and 20 or 2, 0.5, 0)
        swKnob.Size = UDim2.new(0, 22, 0, 22)
        swKnob.BackgroundColor3 = C.White
        swKnob.BorderSizePixel = 0
        corner(swKnob, 11)

        local btn = Instance.new("TextButton")
        btn.Parent = card
        btn.BackgroundTransparency = 1
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.Text = ""
        btn.AutoButtonColor = false

        trackConn(btn.MouseButton1Click:Connect(function()
            T[R] = not T[R]
            TweenService:Create(swBg, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {BackgroundColor3 = T[R] and C.Accent or C.Surface4}):Play()
            TweenService:Create(swKnob, TweenInfo.new(0.22, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Position = UDim2.new(0, T[R] and 20 or 2, 0.5, 0)}):Play()
            local ok, err = pcall(N, T[R])
            if not ok then warn("[UI] Toggle:", err) end
        end))

        if S then
            local ok, err = pcall(N, true)
            if not ok then warn("[UI] Toggle:", err) end
        end
        return card
    end

    -- Slider
    function K:Slider(Y, Z, _, a0, N, S, T, step)
        if type(Z) == "number" and type(_) == "number" then
            local _min, _max = Z, _
            local _default, _cb
            if type(a0) == "function" then
                _cb = a0; _default = N
            elseif type(N) == "function" then
                _default = a0; _cb = N
            end
            Z, _, a0, N, S = Y, _min, _max, _cb, _default
        end
        if type(T) == "number" and step == nil then
            step = T; T = nil
        end
        T = (type(T) == "table") and T or a.flags

        local minV = tonumber(_) or 0
        local maxV = tonumber(a0) or 100
        if maxV == minV then maxV = minV + 1 end
        local a3 = Z or HttpService:GenerateGUID()
        N = N or function() end
        step = tonumber(step) or 1

        local current = tonumber(S) or minV
        current = math.clamp(current, minV, maxV)
        T[a3] = current

        local card = Instance.new("Frame")
        card.Name = "SliderCard"
        card.Parent = body
        card.BackgroundColor3 = C.Surface2
        card.BorderSizePixel = 0
        card.Size = UDim2.new(1, 0, 0, SZ.CardHBig)
        corner(card, SZ.RadCard)

        local title = Instance.new("TextLabel")
        title.Parent = card
        title.BackgroundTransparency = 1
        title.Position = UDim2.new(0, 16, 0, 10)
        title.Size = UDim2.new(1, -100, 0, 18)
        title.Font = Enum.Font.GothamMedium
        title.Text = Txt(Y)
        title.TextColor3 = C.Text
        title.TextSize = 13
        title.TextXAlignment = Enum.TextXAlignment.Left

        local valueLbl = Instance.new("TextLabel")
        valueLbl.Parent = card
        valueLbl.BackgroundTransparency = 1
        valueLbl.AnchorPoint = Vector2.new(1, 0)
        valueLbl.Position = UDim2.new(1, -16, 0, 10)
        valueLbl.Size = UDim2.new(0, 80, 0, 18)
        valueLbl.Font = Enum.Font.GothamSemibold
        valueLbl.Text = Txt(current)
        valueLbl.TextColor3 = C.Accent
        valueLbl.TextSize = 13
        valueLbl.TextXAlignment = Enum.TextXAlignment.Right

        local barBg = Instance.new("Frame")
        barBg.Parent = card
        barBg.Position = UDim2.new(0, 16, 1, -18)
        barBg.Size = UDim2.new(1, -32, 0, 6)
        barBg.BackgroundColor3 = C.Surface4
        barBg.BorderSizePixel = 0
        corner(barBg, 3)

        local barFill = Instance.new("Frame")
        barFill.Parent = barBg
        barFill.Size = UDim2.new((current - minV) / (maxV - minV), 0, 1, 0)
        barFill.BackgroundColor3 = C.Accent
        barFill.BorderSizePixel = 0
        corner(barFill, 3)

        local barKnob = Instance.new("Frame")
        barKnob.Parent = barBg
        barKnob.AnchorPoint = Vector2.new(0.5, 0.5)
        barKnob.Position = UDim2.new((current - minV) / (maxV - minV), 0, 0.5, 0)
        barKnob.Size = UDim2.new(0, 14, 0, 14)
        barKnob.BackgroundColor3 = C.White
        barKnob.BorderSizePixel = 0
        corner(barKnob, 7)

        local btn = Instance.new("TextButton")
        btn.Parent = card
        btn.BackgroundTransparency = 1
        btn.Size = UDim2.new(1, 0, 1, 0)
        btn.Text = ""
        btn.AutoButtonColor = false

        local function ab(p)
            if barBg.AbsoluteSize.X <= 0 then return end
            local frac = math.clamp(
                (p.Position.X - barBg.AbsolutePosition.X) / barBg.AbsoluteSize.X, 0, 1)
            barFill.Size = UDim2.new(frac, 0, 1, 0)
            barKnob.Position = UDim2.new(frac, 0, 0.5, 0)
            local raw = minV + frac * (maxV - minV)
            local ad
            if step > 0 then
                local prec = 1 / step
                ad = math.floor((raw * prec) + 0.5) / prec
            else
                ad = raw
            end
            ad = math.clamp(ad, minV, maxV)
            valueLbl.Text = Txt(ad)
            if T[a3] ~= ad then
                T[a3] = ad
                local ok, err = pcall(N, ad)
                if not ok then warn("[UI] Slider:", err) end
            end
        end

        trackConn(btn.InputBegan:Connect(function(p)
            if p.UserInputType == Enum.UserInputType.MouseButton1
                or p.UserInputType == Enum.UserInputType.Touch then
                ab(p)
                slideState = ab
            end
        end))
        trackConn(btn.InputEnded:Connect(function(p)
            if p.UserInputType == Enum.UserInputType.MouseButton1
                or p.UserInputType == Enum.UserInputType.Touch then
                if slideState == ab then slideState = nil end
            end
        end))

        if S and S ~= minV then
            local ok, err = pcall(N, current)
            if not ok then warn("[UI] Slider:", err) end
        end
        return card
    end

    -- ============ 输入控件 ============
    function K:TextBox(L, Q, N, F)
        F = F or L
        N = N or function() end

        local card = Instance.new("Frame")
        card.Name = "TextBoxCard"
        card.Parent = body
        card.BackgroundColor3 = C.Surface2
        card.BorderSizePixel = 0
        card.Size = UDim2.new(1, 0, 0, SZ.CardH)
        corner(card, SZ.RadCard)

        local title = Instance.new("TextLabel")
        title.Parent = card
        title.BackgroundTransparency = 1
        title.Position = UDim2.new(0, 16, 0, 0)
        title.Size = UDim2.new(0, 100, 1, 0)
        title.Font = Enum.Font.GothamMedium
        title.Text = Txt(L)
        title.TextColor3 = C.Text
        title.TextSize = 14
        title.TextXAlignment = Enum.TextXAlignment.Left

        local box = Instance.new("TextBox")
        box.Parent = card
        box.AnchorPoint = Vector2.new(1, 0.5)
        box.Position = UDim2.new(1, -14, 0.5, 0)
        box.Size = UDim2.new(0, 130, 0, 32)
        box.BackgroundColor3 = C.Surface
        box.BorderSizePixel = 0
        box.Font = Enum.Font.Gotham
        box.Text = Txt(Q)
        box.PlaceholderText = "输入..."
        box.TextColor3 = C.Text
        box.PlaceholderColor3 = C.TextDim
        box.TextSize = 13
        box.ClearTextOnFocus = false
        corner(box, 8)
        stroke(box, C.Border, 1, 0.5)

        if Q ~= nil then a.flags[F] = Q end

        trackConn(box.Focused:Connect(function()
            TweenService:Create(box, TweenInfo.new(0.18),
                {BackgroundColor3 = C.Surface3}):Play()
        end))
        trackConn(box.FocusLost:Connect(function(enter)
            TweenService:Create(box, TweenInfo.new(0.18),
                {BackgroundColor3 = C.Surface}):Play()
            a.flags[F] = box.Text
            local ok, err = pcall(N, box.Text, enter)
            if not ok then warn("[UI] TextBox:", err) end
        end))
        return card
    end

    function K:Dropdown(L, options, N, F)
        F = F or L
        options = options or {}
        if #options == 0 then options = {"(空)"} end
        N = N or function() end
        local selected = options[1]
        a.flags[F] = selected

        local card = Instance.new("Frame")
        card.Name = "DropdownCard"
        card.Parent = body
        card.BackgroundColor3 = C.Surface2
        card.BorderSizePixel = 0
        card.Size = UDim2.new(1, 0, 0, SZ.CardH)
        card.ClipsDescendants = true
        corner(card, SZ.RadCard)

        local main = Instance.new("TextButton")
        main.Parent = card
        main.BackgroundTransparency = 1
        main.Size = UDim2.new(1, 0, 0, SZ.CardH)
        main.Text = ""
        main.AutoButtonColor = false

        local title = Instance.new("TextLabel")
        title.Parent = card
        title.BackgroundTransparency = 1
        title.Position = UDim2.new(0, 16, 0, 0)
        title.Size = UDim2.new(0.5, -16, 0, SZ.CardH)
        title.Font = Enum.Font.GothamMedium
        title.Text = Txt(L)
        title.TextColor3 = C.Text
        title.TextSize = 14
        title.TextXAlignment = Enum.TextXAlignment.Left

        local valueLbl = Instance.new("TextLabel")
        valueLbl.Parent = card
        valueLbl.BackgroundTransparency = 1
        valueLbl.AnchorPoint = Vector2.new(1, 0)
        valueLbl.Position = UDim2.new(1, -42, 0, 0)
        valueLbl.Size = UDim2.new(0.5, -50, 0, SZ.CardH)
        valueLbl.Font = Enum.Font.Gotham
        valueLbl.Text = Txt(selected)
        valueLbl.TextColor3 = C.TextSub
        valueLbl.TextSize = 13
        valueLbl.TextXAlignment = Enum.TextXAlignment.Right

        local arrow = Instance.new("ImageLabel")
        arrow.Parent = card
        arrow.AnchorPoint = Vector2.new(1, 0.5)
        arrow.Position = UDim2.new(1, -16, 0, SZ.CardH / 2)
        arrow.Size = UDim2.new(0, 14, 0, 14)
        arrow.BackgroundTransparency = 1
        arrow.Image = "rbxassetid://3926305904"
        arrow.ImageRectOffset = Vector2.new(524, 764)
        arrow.ImageRectSize = Vector2.new(36, 36)
        arrow.ImageColor3 = C.TextSub
        arrow.Rotation = 180

        local holder = Instance.new("Frame")
        holder.Parent = card
        holder.BackgroundTransparency = 1
        holder.Position = UDim2.new(0, 0, 0, SZ.CardH)
        holder.Size = UDim2.new(1, 0, 0, #options * 40)

        local lyt = Instance.new("UIListLayout")
        lyt.Parent = holder
        lyt.SortOrder = Enum.SortOrder.LayoutOrder
        lyt.Padding = UDim.new(0, 2)

        local pPad = Instance.new("UIPadding")
        pPad.Parent = holder
        pPad.PaddingLeft = UDim.new(0, 8)
        pPad.PaddingRight = UDim.new(0, 8)
        pPad.PaddingTop = UDim.new(0, 4)

        local expanded = false
        local function setExpanded(state)
            expanded = state
            local targetH = SZ.CardH + (expanded and (#options * 40 + 8) or 0)
            TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Size = UDim2.new(1, 0, 0, targetH)}):Play()
            TweenService:Create(arrow, TweenInfo.new(0.2),
                {Rotation = expanded and 0 or 180}):Play()
        end

        for idx, opt in ipairs(options) do
            local ob = Instance.new("TextButton")
            ob.Parent = holder
            ob.BackgroundColor3 = C.Surface
            ob.BorderSizePixel = 0
            ob.Size = UDim2.new(1, 0, 0, 38)
            ob.Font = Enum.Font.Gotham
            ob.Text = "   " .. Txt(opt)
            ob.TextColor3 = C.TextSub
            ob.TextSize = 13
            ob.TextXAlignment = Enum.TextXAlignment.Left
            ob.AutoButtonColor = false
            ob.LayoutOrder = idx
            corner(ob, 8)
            trackConn(ob.MouseEnter:Connect(function()
                TweenService:Create(ob, TweenInfo.new(0.15), {BackgroundColor3 = C.Surface3}):Play()
            end))
            trackConn(ob.MouseLeave:Connect(function()
                TweenService:Create(ob, TweenInfo.new(0.15), {BackgroundColor3 = C.Surface}):Play()
            end))
            trackConn(ob.MouseButton1Click:Connect(function()
                selected = opt
                a.flags[F] = opt
                valueLbl.Text = Txt(opt)
                setExpanded(false)
                local ok, err = pcall(N, opt)
                if not ok then warn("[UI] Dropdown:", err) end
            end))
        end

        trackConn(main.MouseButton1Click:Connect(function()
            setExpanded(not expanded)
        end))
        return card
    end

    function K:Keybind(L, defaultKey, N, F)
        F = F or L
        N = N or function() end
        local current = defaultKey or Enum.KeyCode.E
        a.flags[F] = current

        local card = Instance.new("Frame")
        card.Name = "KeybindCard"
        card.Parent = body
        card.BackgroundColor3 = C.Surface2
        card.BorderSizePixel = 0
        card.Size = UDim2.new(1, 0, 0, SZ.CardH)
        corner(card, SZ.RadCard)

        local title = Instance.new("TextLabel")
        title.Parent = card
        title.BackgroundTransparency = 1
        title.Position = UDim2.new(0, 16, 0, 0)
        title.Size = UDim2.new(1, -100, 1, 0)
        title.Font = Enum.Font.GothamMedium
        title.Text = Txt(L)
        title.TextColor3 = C.Text
        title.TextSize = 14
        title.TextXAlignment = Enum.TextXAlignment.Left

        local btn = Instance.new("TextButton")
        btn.Parent = card
        btn.AnchorPoint = Vector2.new(1, 0.5)
        btn.Position = UDim2.new(1, -14, 0.5, 0)
        btn.Size = UDim2.new(0, 72, 0, 30)
        btn.BackgroundColor3 = C.Surface
        btn.BorderSizePixel = 0
        btn.Font = Enum.Font.GothamSemibold
        btn.Text = current.Name
        btn.TextColor3 = C.Accent
        btn.TextSize = 12
        btn.AutoButtonColor = false
        corner(btn, 8)
        stroke(btn, C.Border, 1, 0.5)

        local listening = false
        trackConn(btn.MouseButton1Click:Connect(function()
            listening = true
            btn.Text = "..."
            btn.TextColor3 = C.Warn
        end))

        trackConn(UserInputService.InputBegan:Connect(function(input, gp)
            if not listening or gp then return end
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            if input.KeyCode == Enum.KeyCode.Unknown then return end
            current = input.KeyCode
            listening = false
            btn.Text = current.Name
            btn.TextColor3 = C.Accent
            a.flags[F] = current
            local ok, err = pcall(N, current)
            if not ok then warn("[UI] Keybind:", err) end
        end))
        return card
    end

    function K:ColorPicker(L, defaultColor, N, F)
        F = F or L
        N = N or function() end
        local current = defaultColor or C.Accent
        a.flags[F] = current

        local presets = {
            Color3.fromRGB(255, 69, 58),
            Color3.fromRGB(255, 179, 64),
            Color3.fromRGB(255, 214, 10),
            Color3.fromRGB(52, 199, 89),
            Color3.fromRGB(48, 176, 199),
            Color3.fromRGB(131, 132, 255),
            Color3.fromRGB(191, 90, 242),
            Color3.fromRGB(255, 255, 255),
        }

        local card = Instance.new("Frame")
        card.Name = "ColorCard"
        card.Parent = body
        card.BackgroundColor3 = C.Surface2
        card.BorderSizePixel = 0
        card.Size = UDim2.new(1, 0, 0, SZ.CardH)
        card.ClipsDescendants = true
        corner(card, SZ.RadCard)

        local title = Instance.new("TextLabel")
        title.Parent = card
        title.BackgroundTransparency = 1
        title.Position = UDim2.new(0, 16, 0, 0)
        title.Size = UDim2.new(1, -80, 0, SZ.CardH)
        title.Font = Enum.Font.GothamMedium
        title.Text = Txt(L)
        title.TextColor3 = C.Text
        title.TextSize = 14
        title.TextXAlignment = Enum.TextXAlignment.Left

        local prev = Instance.new("TextButton")
        prev.Parent = card
        prev.AnchorPoint = Vector2.new(1, 0.5)
        prev.Position = UDim2.new(1, -16, 0, SZ.CardH / 2)
        prev.Size = UDim2.new(0, 48, 0, 26)
        prev.BackgroundColor3 = current
        prev.BorderSizePixel = 0
        prev.Text = ""
        prev.AutoButtonColor = false
        corner(prev, 8)
        stroke(prev, C.Border, 1, 0.5)

        local rows = math.ceil(#presets / 4)
        local holder = Instance.new("Frame")
        holder.Parent = card
        holder.BackgroundTransparency = 1
        holder.Position = UDim2.new(0, 0, 0, SZ.CardH)
        holder.Size = UDim2.new(1, 0, 0, rows * 34 + 8)

        local grid = Instance.new("UIGridLayout")
        grid.Parent = holder
        grid.CellSize = UDim2.new(0, 40, 0, 26)
        grid.CellPadding = UDim2.new(0, 8, 0, 8)
        grid.SortOrder = Enum.SortOrder.LayoutOrder
        grid.HorizontalAlignment = Enum.HorizontalAlignment.Center

        local expanded = false
        local function setExpanded(state)
            expanded = state
            local targetH = SZ.CardH + (expanded and (rows * 34 + 8) or 0)
            TweenService:Create(card, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
                {Size = UDim2.new(1, 0, 0, targetH)}):Play()
        end

        for idx, c in ipairs(presets) do
            local cb = Instance.new("TextButton")
            cb.Parent = holder
            cb.BackgroundColor3 = c
            cb.BorderSizePixel = 0
            cb.Text = ""
            cb.AutoButtonColor = false
            cb.LayoutOrder = idx
            corner(cb, 8)
            trackConn(cb.MouseButton1Click:Connect(function()
                current = c
                a.flags[F] = c
                prev.BackgroundColor3 = c
                setExpanded(false)
                local ok, err = pcall(N, c)
                if not ok then warn("[UI] ColorPicker:", err) end
            end))
        end

        trackConn(prev.MouseButton1Click:Connect(function()
            setExpanded(not expanded)
        end))
        return card
    end

    return K
end

return a