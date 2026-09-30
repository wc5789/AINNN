local a = {windowCount = 0, flags = {}, _conns = {}, _guis = {}}
local b = {}
setmetatable(
    b,
    {__index = function(c, d)
            return game:GetService(d)
        end, __newindex = function(e, f)
            e[f] = nil
            return
        end}
)

local TweenService     = b.TweenService
local UserInputService = b.UserInputService
local RunService       = b.RunService
local HttpService      = b.HttpService
local Players          = b.Players
local CoreGui          = b.CoreGui

local function trackConn(c)
    a._conns[#a._conns + 1] = c
    return c
end
local function Txt(v)
    if v == nil then return "" end
    return tostring(v)
end

-- 记录窗口原始 ZIndex（弱表，避免污染 Instance）
local zOrig = setmetatable({}, {__mode = "k"})

local g
local h = Players.LocalPlayer:GetMouse()

-- 全局输入状态
local dragState  = nil
local slideState = nil
local zCounter   = 10

trackConn(UserInputService.InputChanged:Connect(function(p)
    if p.UserInputType ~= Enum.UserInputType.MouseMovement
        and p.UserInputType ~= Enum.UserInputType.Touch then
        return
    end
    if dragState then
        local q = p.Position - dragState.m
        dragState.i.Position = UDim2.new(
            dragState.n.X.Scale, dragState.n.X.Offset + q.X,
            dragState.n.Y.Scale, dragState.n.Y.Offset + q.Y)
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

function Drag(i, j)
    if g and g ~= i then
        g.ZIndex = zOrig[g] or 1
    end
    g = i
    if not zOrig[i] then zOrig[i] = i.ZIndex end
    zCounter = zCounter + 1
    i.ZIndex = zCounter
    if not j then j = i end
    trackConn(j.InputBegan:Connect(function(p)
        if p.UserInputType == Enum.UserInputType.MouseButton1
            or p.UserInputType == Enum.UserInputType.Touch then
            if g and g ~= i then
                g.ZIndex = zOrig[g] or 1
            end
            g = i
            zCounter = zCounter + 1
            i.ZIndex = zCounter
            dragState = {i = i, m = p.Position, n = i.Position}
        end
    end))
end

function ClickEffect(r)
    task.spawn(function()
        if r.ClipsDescendants ~= true then
            r.ClipsDescendants = true
        end
        local s = Instance.new("ImageLabel")
        s.Name = "Ripple"
        s.Parent = r
        s.BackgroundTransparency = 1.000
        s.ZIndex = 8
        s.Image = "rbxassetid://2708891598"
        s.ImageTransparency = 0.800
        s.ScaleType = Enum.ScaleType.Fit
        s.ImageColor3 = Color3.fromRGB(131, 132, 255)
        s.AnchorPoint = Vector2.new(0.5, 0.5)

        -- 触摸/鼠标位置都可用
        local mx, my
        if UserInputService.TouchEnabled and not UserInputService.MouseEnabled then
            -- 触摸时退化为父级中心
            mx = r.AbsolutePosition.X + r.AbsoluteSize.X / 2
            my = r.AbsolutePosition.Y + r.AbsoluteSize.Y / 2
        else
            mx, my = h.X, h.Y
        end
        local relX = mx - r.AbsolutePosition.X
        local relY = my - r.AbsolutePosition.Y
        s.Position = UDim2.new(0, relX, 0, relY)
        s.Size = UDim2.new(0, 0, 0, 0)

        local maxDim = math.max(r.AbsoluteSize.X, r.AbsoluteSize.Y) * 2.2
        TweenService:Create(s, TweenInfo.new(1),
            {Size = UDim2.new(0, maxDim, 0, maxDim)}):Play()

        task.wait(0.25)
        local fade = TweenService:Create(s, TweenInfo.new(.5), {ImageTransparency = 1})
        fade:Play()
        fade.Completed:Wait()
        s:Destroy()
    end)
end

local t = Instance.new("ScreenGui")
t.Name = HttpService:GenerateGUID()
t.ResetOnSpawn = false
t.Parent = RunService:IsStudio() and Players.LocalPlayer:WaitForChild("PlayerGui") or CoreGui
a._guis[#a._guis + 1] = t

-- 桌面快捷键
trackConn(UserInputService.InputBegan:Connect(function(u, v)
    if u.KeyCode == Enum.KeyCode.LeftShift and not v then
        t.Enabled = not t.Enabled
    end
end))

-- ===== 移动端悬浮开关 =====
if UserInputService.TouchEnabled then
    local mobileGui = Instance.new("ScreenGui")
    mobileGui.Name = "MobileUI"
    mobileGui.ResetOnSpawn = false
    mobileGui.Parent = RunService:IsStudio() and Players.LocalPlayer:WaitForChild("PlayerGui") or CoreGui
    a._guis[#a._guis + 1] = mobileGui

    local mb = Instance.new("TextButton")
    mb.Name = "ToggleBtn"
    mb.Parent = mobileGui
    mb.AnchorPoint = Vector2.new(0, 1)
    mb.Position = UDim2.new(0, 8, 1, -8)
    mb.Size = UDim2.new(0, 48, 0, 48)
    mb.BackgroundColor3 = Color3.fromRGB(43, 43, 43)
    mb.Text = "☰"
    mb.TextColor3 = Color3.fromRGB(255, 255, 255)
    mb.TextSize = 24
    mb.Font = Enum.Font.GothamBold
    mb.ZIndex = 10
    mb.AutoButtonColor = false
    local mc = Instance.new("UICorner")
    mc.CornerRadius = UDim.new(0, 12)
    mc.Parent = mb

    -- 悬浮按钮本身的拖动
    local mDrag = nil
    local mDragged = false
    trackConn(mb.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.Touch
            or input.UserInputType == Enum.UserInputType.MouseButton1 then
            mDrag = {start = input.Position, origin = mb.Position}
            mDragged = false
        end
    end))
    trackConn(UserInputService.InputChanged:Connect(function(input)
        if not mDrag then return end
        if input.UserInputType ~= Enum.UserInputType.Touch
            and input.UserInputType ~= Enum.UserInputType.MouseMovement then return end
        local d = input.Position - mDrag.start
        if math.abs(d.X) > 4 or math.abs(d.Y) > 4 then mDragged = true end
        mb.Position = UDim2.new(
            mDrag.origin.X.Scale, mDrag.origin.X.Offset + d.X,
            mDrag.origin.Y.Scale, mDrag.origin.Y.Offset + d.Y)
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

function a:Window(w)
    local x = false
    a.windowCount = a.windowCount + 1

    local y = Instance.new("Frame")
    local z = Instance.new("Frame")
    local A = Instance.new("UIGradient")
    local B = Instance.new("TextLabel")
    local C = Instance.new("TextButton")
    local D = Instance.new("ImageLabel")
    local E = Instance.new("Frame")
    local F = Instance.new("UIListLayout")
    local G = Instance.new("Frame")

    y.Name = "Top"
    y.Parent = t
    y.BackgroundColor3 = Color3.fromRGB(43, 43, 43)
    y.BorderSizePixel = 0
    y.Position = UDim2.new(0, 25, 0, -30 + 36 * a.windowCount + 6 * a.windowCount)
    y.Size = UDim2.new(0, 212, 0, 36)
    Drag(y)

    z.Name = "WindowLine"
    z.Parent = y
    z.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
    z.BorderSizePixel = 0
    z.Position = UDim2.new(0, 0, 0, 34)
    z.Size = UDim2.new(0, 212, 0, 2)

    A.Color = ColorSequence.new {
        ColorSequenceKeypoint.new(0.00, Color3.fromRGB(43, 43, 43)),
        ColorSequenceKeypoint.new(0.20, Color3.fromRGB(43, 43, 43)),
        ColorSequenceKeypoint.new(0.50, Color3.fromRGB(131, 132, 255)),
        ColorSequenceKeypoint.new(0.80, Color3.fromRGB(43, 43, 43)),
        ColorSequenceKeypoint.new(1.00, Color3.fromRGB(43, 43, 43))
    }
    A.Name = "WindowLineGradient"
    A.Parent = z

    B.Name = "Header"
    B.Parent = y
    B.BackgroundTransparency = 1.000
    B.BorderSizePixel = 0
    B.Size = UDim2.new(0, 54, 0, 34)
    B.Font = Enum.Font.GothamSemibold
    B.Text = "   " .. Txt(w)
    B.TextColor3 = Color3.fromRGB(255, 255, 255)
    B.TextSize = 14.000
    B.TextXAlignment = Enum.TextXAlignment.Left

    C.Name = "WindowToggle"
    C.Parent = y
    C.BackgroundTransparency = 1.000
    C.BorderSizePixel = 0
    C.Position = UDim2.new(0.835270762, 0, 0, 0)
    C.Size = UDim2.new(0, 34, 0, 34)
    C.Font = Enum.Font.SourceSans
    C.Text = ""
    C.TextColor3 = Color3.fromRGB(0, 0, 0)
    C.TextSize = 14.000

    D.Name = "WindowToggleImg"
    D.Parent = C
    D.AnchorPoint = Vector2.new(0.5, 0.5)
    D.BackgroundTransparency = 1.000
    D.BorderSizePixel = 0
    D.Position = UDim2.new(0.5, 0, 0.5, 0)
    D.Size = UDim2.new(0, 18, 0, 18)
    D.Image = "rbxassetid://3926305904"
    D.ImageRectOffset = Vector2.new(524, 764)
    D.ImageRectSize = Vector2.new(36, 36)
    D.Rotation = 180

    E.Name = "Bottom"
    E.Parent = y
    E.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
    E.BorderSizePixel = 0
    E.ClipsDescendants = true
    E.Position = UDim2.new(0, 0, 1, 0)
    E.Size = UDim2.new(0, 212, 0, 0)

    F.Name = "BottomLayout"
    F.Parent = E
    F.HorizontalAlignment = Enum.HorizontalAlignment.Center
    F.SortOrder = Enum.SortOrder.LayoutOrder
    F.Padding = UDim.new(0, 4)

    G.Name = "PaddingThing"
    G.Parent = E
    G.BackgroundTransparency = 1
    G.BorderSizePixel = 0
    G.Position = UDim2.new(0.263033181, 0, 0, 0)
    G.Size = UDim2.new(0, 100, 0, 0)
    G.Visible = false

    local isAnimating = false
    local function I()
        if isAnimating then return end
        isAnimating = true
        x = not x
        TweenService:Create(E,
            TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {Size = UDim2.new(0, 212, 0, x and F.AbsoluteContentSize.Y + 4 or 0)}):Play()
        TweenService:Create(D,
            TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
            {Rotation = x and 0 or 180}):Play()
        task.wait(.25)
        isAnimating = false
    end
    local function J()
        if isAnimating or not x then return end
        E.Size = UDim2.new(0, 212, 0, F.AbsoluteContentSize.Y + 4)
    end
    trackConn(F:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(J))
    trackConn(C.MouseButton1Click:Connect(I))

    local K = {}

    -- ============ 原有控件 ============
    function K:Label(L)
        local M = Instance.new("TextButton")
        M.Name = "Label"
        M.Parent = E
        M.BackgroundColor3 = Color3.fromRGB(43, 43, 43)
        M.BorderSizePixel = 0
        M.Position = UDim2.new(0.0212264154, 0, 0.71676302, 0)
        M.Size = UDim2.new(0, 203, 0, 26)
        M.AutoButtonColor = false
        M.Font = Enum.Font.GothamSemibold
        M.Text = Txt(L)
        M.TextColor3 = Color3.fromRGB(255, 255, 255)
        M.TextSize = 14.000
        return M
    end

    function K:Button(L, N)
        local O = Instance.new("Frame")
        local P = Instance.new("TextButton")
        N = N or function() end
        O.Name = "ButtonObj"
        O.Parent = E
        O.BackgroundColor3 = Color3.fromRGB(43, 43, 43)
        O.BorderSizePixel = 0
        O.Position = UDim2.new(0, 0, 0.0172413792, 0)
        O.Size = UDim2.new(0, 203, 0, 36)
        P.Name = "Button"
        P.Parent = O
        P.BackgroundTransparency = 1.000
        P.BorderSizePixel = 0
        P.Size = UDim2.new(0, 203, 0, 36)
        P.Font = Enum.Font.Gotham
        P.Text = "  " .. Txt(L)
        P.TextColor3 = Color3.fromRGB(255, 255, 255)
        P.TextSize = 14.000
        P.TextXAlignment = Enum.TextXAlignment.Left
        trackConn(P.MouseEnter:Connect(function()
            TweenService:Create(O, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {BackgroundColor3 = Color3.fromRGB(55, 55, 55)}):Play()
        end))
        trackConn(P.MouseLeave:Connect(function()
            TweenService:Create(O, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {BackgroundColor3 = Color3.fromRGB(43, 43, 43)}):Play()
        end))
        trackConn(P.MouseButton1Click:Connect(function()
            task.spawn(function() ClickEffect(P) end)
            local ok, err = pcall(N)
            if not ok then warn("[UI] Button callback:", err) end
        end))
        return P
    end

    function K:Toggle(Q, R, S, N, T)
        T = T or a.flags
        R = R or HttpService:GenerateGUID()
        S = S or false
        N = N or function() end
        T[R] = S
        local U = Instance.new("Frame")
        local V = Instance.new("TextButton")
        local W = Instance.new("Frame")
        local X = Instance.new("UICorner")
        U.Name = "ToggleObj"
        U.Parent = E
        U.BackgroundColor3 = Color3.fromRGB(43, 43, 43)
        U.BorderSizePixel = 0
        U.Position = UDim2.new(0, 0, 0.0172413792, 0)
        U.Size = UDim2.new(0, 203, 0, 36)
        V.Name = "ToggleText"
        V.Parent = U
        V.BackgroundTransparency = 1.000
        V.BorderSizePixel = 0
        V.Size = UDim2.new(0, 203, 0, 36)
        V.Font = Enum.Font.Gotham
        V.Text = "  " .. Txt(Q)
        V.TextColor3 = Color3.fromRGB(255, 255, 255)
        V.TextSize = 14.000
        V.TextXAlignment = Enum.TextXAlignment.Left
        W.Name = "ToggleStatus"
        W.Parent = U
        W.AnchorPoint = Vector2.new(0, 0.5)
        W.BackgroundColor3 = S and Color3.fromRGB(14, 255, 110) or Color3.fromRGB(255, 44, 44)
        W.BorderSizePixel = 0
        W.Position = UDim2.new(0.847443342, 0, 0.5, 0)
        W.Size = UDim2.new(0, 24, 0, 24)
        X.CornerRadius = UDim.new(0, 4)
        X.Name = "ToggleStatusRound"
        X.Parent = W
        if S then
            local ok, err = pcall(N, true)
            if not ok then warn("[UI] Toggle callback:", err) end
        end
        trackConn(V.MouseEnter:Connect(function()
            TweenService:Create(U, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {BackgroundColor3 = Color3.fromRGB(55, 55, 55)}):Play()
        end))
        trackConn(V.MouseLeave:Connect(function()
            TweenService:Create(U, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {BackgroundColor3 = Color3.fromRGB(43, 43, 43)}):Play()
        end))
        trackConn(V.MouseButton1Click:Connect(function()
            T[R] = not T[R]
            task.spawn(function()
                TweenService:Create(W, TweenInfo.new(0.25, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                    {BackgroundColor3 = T[R] and Color3.fromRGB(14, 255, 110) or Color3.fromRGB(255, 44, 44)}):Play()
            end)
            task.spawn(function() ClickEffect(V) end)
            local ok, err = pcall(N, T[R])
            if not ok then warn("[UI] Toggle callback:", err) end
        end))
        return U
    end

    function K:Slider(Y, Z, _, a0, N, S, T, step)
        local a1 = _ or 0
        local a2 = a0 or 100
        local a3 = Z or HttpService:GenerateGUID()
        N = N or function() end
        T = T or a.flags
        step = step or 1

        local minV = math.min(a1, a2)
        local maxV = math.max(a1, a2)
        if maxV == minV then maxV = minV + 1 end

        local current = S or a1
        current = math.clamp(current, minV, maxV)
        T[a3] = current

        local a4 = Instance.new("Frame")
        local a5 = Instance.new("TextButton")
        local a6 = Instance.new("Frame")
        local a7 = Instance.new("UICorner")
        local a8 = Instance.new("Frame")
        local a9 = Instance.new("UICorner")
        local aa = Instance.new("TextLabel")
        a4.Name = "SliderObj"
        a4.Parent = E
        a4.BackgroundColor3 = Color3.fromRGB(43, 43, 43)
        a4.BorderSizePixel = 0
        a4.Position = UDim2.new(0, 0, 0.0172413792, 0)
        a4.Size = UDim2.new(0, 203, 0, 36)
        a5.Name = "SliderText"
        a5.Parent = a4
        a5.BackgroundTransparency = 1.000
        a5.BorderSizePixel = 0
        a5.Size = UDim2.new(0, 203, 0, 36)
        a5.Font = Enum.Font.Gotham
        a5.Text = "  " .. Txt(Y)
        a5.TextColor3 = Color3.fromRGB(255, 255, 255)
        a5.TextSize = 14.000
        a5.TextXAlignment = Enum.TextXAlignment.Left
        a6.Name = "SliderBack"
        a6.Parent = a4
        a6.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
        a6.BorderSizePixel = 0
        a6.Position = UDim2.new(0.57099998, 0, 0.680000007, 0)
        a6.Size = UDim2.new(0, 80, 0, 7)
        a7.CornerRadius = UDim.new(0, 4)
        a7.Name = "SliderBackRound"
        a7.Parent = a6
        a8.Name = "SliderPart"
        a8.Parent = a6
        a8.BackgroundColor3 = Color3.fromRGB(131, 133, 255)
        a8.BorderSizePixel = 0
        a8.Size = UDim2.new((current - minV) / (maxV - minV), 0, 1, 0)
        a9.CornerRadius = UDim.new(0, 4)
        a9.Name = "SliderPartRound"
        a9.Parent = a8
        aa.Name = "SliderValue"
        aa.Parent = a4
        aa.BackgroundTransparency = 1.000
        aa.BorderSizePixel = 0
        aa.Position = UDim2.new(0.571428597, 0, 0.166666672, 0)
        aa.Size = UDim2.new(0, 80, 0, 16)
        aa.Font = Enum.Font.Code
        aa.Text = Txt(current)
        aa.TextColor3 = Color3.fromRGB(255, 255, 255)
        aa.TextSize = 14.000

        if S and S ~= a1 then
            local ok, err = pcall(N, current)
            if not ok then warn("[UI] Slider callback:", err) end
        end

        local function ab(p)
            if a6.AbsoluteSize.X <= 0 then return end
            local frac = math.clamp(
                (p.Position.X - a6.AbsolutePosition.X) / a6.AbsoluteSize.X, 0, 1)
            a8:TweenSize(UDim2.new(frac, 0, 1, 0),
                Enum.EasingDirection.InOut, Enum.EasingStyle.Linear, 0.05, true)
            local raw = minV + frac * (maxV - minV)
            local ad
            if step and step > 0 then
                local prec = 1 / step
                ad = math.floor((raw * prec) + 0.5) / prec
            else
                ad = raw
            end
            ad = math.clamp(ad, minV, maxV)
            aa.Text = Txt(ad)
            if T[a3] ~= ad then
                T[a3] = ad
                local ok, err = pcall(N, ad)
                if not ok then warn("[UI] Slider callback:", err) end
            end
        end

        trackConn(a5.InputBegan:Connect(function(p)
            if p.UserInputType == Enum.UserInputType.MouseButton1
                or p.UserInputType == Enum.UserInputType.Touch then
                task.spawn(function()
                    TweenService:Create(a8, TweenInfo.new(0.15),
                        {BackgroundColor3 = Color3.fromRGB(255, 255, 255)}):Play()
                end)
                ab(p)
                slideState = ab
            end
        end))
        trackConn(a5.InputEnded:Connect(function(p)
            if p.UserInputType == Enum.UserInputType.MouseButton1
                or p.UserInputType == Enum.UserInputType.Touch then
                task.spawn(function()
                    TweenService:Create(a8, TweenInfo.new(0.15),
                        {BackgroundColor3 = Color3.fromRGB(131, 133, 255)}):Play()
                end)
                if slideState == ab then slideState = nil end
            end
        end))
        return a4
    end

    -- ============ 新控件 ============

    -- Section：分类标题
    function K:Section(L)
        local M = Instance.new("Frame")
        M.Name = "Section"
        M.Parent = E
        M.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
        M.BorderSizePixel = 0
        M.Size = UDim2.new(0, 203, 0, 22)
        local N = Instance.new("TextLabel")
        N.Parent = M
        N.BackgroundTransparency = 1
        N.Size = UDim2.new(1, -12, 1, 0)
        N.Position = UDim2.new(0, 8, 0, 0)
        N.Font = Enum.Font.GothamBold
        N.Text = Txt(L)
        N.TextColor3 = Color3.fromRGB(131, 132, 255)
        N.TextSize = 12
        N.TextXAlignment = Enum.TextXAlignment.Left
        return M
    end

    -- TextBox：文本输入
    function K:TextBox(L, Q, N, F)
        F = F or L
        N = N or function() end
        local U = Instance.new("Frame")
        U.Name = "TextBoxObj"
        U.Parent = E
        U.BackgroundColor3 = Color3.fromRGB(43, 43, 43)
        U.BorderSizePixel = 0
        U.Size = UDim2.new(0, 203, 0, 36)

        local V = Instance.new("TextLabel")
        V.Parent = U
        V.BackgroundTransparency = 1
        V.Position = UDim2.new(0, 8, 0, 0)
        V.Size = UDim2.new(0, 88, 1, 0)
        V.Font = Enum.Font.Gotham
        V.Text = Txt(L)
        V.TextColor3 = Color3.fromRGB(255, 255, 255)
        V.TextSize = 14
        V.TextXAlignment = Enum.TextXAlignment.Left

        local W = Instance.new("TextBox")
        W.Parent = U
        W.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
        W.BorderSizePixel = 0
        W.Position = UDim2.new(0, 100, 0, 7)
        W.Size = UDim2.new(0, 95, 0, 22)
        W.Font = Enum.Font.Gotham
        W.Text = Txt(Q)
        W.PlaceholderText = "输入..."
        W.TextColor3 = Color3.fromRGB(255, 255, 255)
        W.PlaceholderColor3 = Color3.fromRGB(160, 160, 160)
        W.TextSize = 13
        W.ClearTextOnFocus = false
        local WC = Instance.new("UICorner")
        WC.CornerRadius = UDim.new(0, 4)
        WC.Parent = W

        if Q ~= nil then a.flags[F] = Q end

        trackConn(W.FocusLost:Connect(function(enter)
            a.flags[F] = W.Text
            local ok, err = pcall(N, W.Text, enter)
            if not ok then warn("[UI] TextBox callback:", err) end
        end))
        return U
    end

    -- Dropdown：下拉选择
    function K:Dropdown(L, options, N, F)
        F = F or L
        options = options or {}
        N = N or function() end
        local selected = options[1]
        a.flags[F] = selected

        local U = Instance.new("Frame")
        U.Name = "DropdownObj"
        U.Parent = E
        U.BackgroundColor3 = Color3.fromRGB(43, 43, 43)
        U.BorderSizePixel = 0
        U.Size = UDim2.new(0, 203, 0, 36)
        U.ClipsDescendants = true

        local V = Instance.new("TextButton")
        V.Parent = U
        V.BackgroundTransparency = 1
        V.Size = UDim2.new(1, 0, 0, 36)
        V.Font = Enum.Font.Gotham
        V.Text = "  " .. Txt(L) .. ": " .. Txt(selected)
        V.TextColor3 = Color3.fromRGB(255, 255, 255)
        V.TextSize = 14
        V.TextXAlignment = Enum.TextXAlignment.Left

        local arrow = Instance.new("TextLabel")
        arrow.Parent = U
        arrow.BackgroundTransparency = 1
        arrow.AnchorPoint = Vector2.new(1, 0.5)
        arrow.Position = UDim2.new(1, -8, 0, 18)
        arrow.Size = UDim2.new(0, 16, 0, 16)
        arrow.Font = Enum.Font.GothamBold
        arrow.Text = "v"
        arrow.TextColor3 = Color3.fromRGB(200, 200, 200)
        arrow.TextSize = 12

        local optionFrame = Instance.new("Frame")
        optionFrame.Name = "Options"
        optionFrame.Parent = U
        optionFrame.BackgroundTransparency = 1
        optionFrame.Position = UDim2.new(0, 0, 0, 36)
        optionFrame.Size = UDim2.new(1, 0, 0, #options * 28)

        local layout = Instance.new("UIListLayout")
        layout.Parent = optionFrame
        layout.SortOrder = Enum.SortOrder.LayoutOrder
        layout.Padding = UDim.new(0, 0)

        local expanded = false
        local function setExpanded(state)
            expanded = state
            local targetH = 36 + (expanded and #options * 28 or 0)
            TweenService:Create(U, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {Size = UDim2.new(0, 203, 0, targetH)}):Play()
            TweenService:Create(arrow, TweenInfo.new(0.2),
                {Rotation = expanded and 180 or 0}):Play()
        end

        for idx, opt in ipairs(options) do
            local ob = Instance.new("TextButton")
            ob.Name = "Option" .. idx
            ob.Parent = optionFrame
            ob.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
            ob.BorderSizePixel = 0
            ob.Size = UDim2.new(1, 0, 0, 28)
            ob.Font = Enum.Font.Gotham
            ob.Text = "    " .. Txt(opt)
            ob.TextColor3 = Color3.fromRGB(220, 220, 220)
            ob.TextSize = 13
            ob.TextXAlignment = Enum.TextXAlignment.Left
            ob.LayoutOrder = idx
            trackConn(ob.MouseEnter:Connect(function()
                TweenService:Create(ob, TweenInfo.new(0.15),
                    {BackgroundColor3 = Color3.fromRGB(55, 55, 55)}):Play()
            end))
            trackConn(ob.MouseLeave:Connect(function()
                TweenService:Create(ob, TweenInfo.new(0.15),
                    {BackgroundColor3 = Color3.fromRGB(38, 38, 38)}):Play()
            end))
            trackConn(ob.MouseButton1Click:Connect(function()
                selected = opt
                a.flags[F] = opt
                V.Text = "  " .. Txt(L) .. ": " .. Txt(opt)
                setExpanded(false)
                local ok, err = pcall(N, opt)
                if not ok then warn("[UI] Dropdown callback:", err) end
            end))
        end

        trackConn(V.MouseButton1Click:Connect(function()
            setExpanded(not expanded)
        end))
        return U
    end

    -- Keybind：按键绑定
    function K:Keybind(L, defaultKey, N, F)
        F = F or L
        N = N or function() end
        local current = defaultKey or Enum.KeyCode.E
        a.flags[F] = current

        local U = Instance.new("Frame")
        U.Name = "KeybindObj"
        U.Parent = E
        U.BackgroundColor3 = Color3.fromRGB(43, 43, 43)
        U.BorderSizePixel = 0
        U.Size = UDim2.new(0, 203, 0, 36)

        local V = Instance.new("TextLabel")
        V.Parent = U
        V.BackgroundTransparency = 1
        V.Position = UDim2.new(0, 8, 0, 0)
        V.Size = UDim2.new(1, -90, 1, 0)
        V.Font = Enum.Font.Gotham
        V.Text = Txt(L)
        V.TextColor3 = Color3.fromRGB(255, 255, 255)
        V.TextSize = 14
        V.TextXAlignment = Enum.TextXAlignment.Left

        local W = Instance.new("TextButton")
        W.Parent = U
        W.BackgroundColor3 = Color3.fromRGB(38, 38, 38)
        W.BorderSizePixel = 0
        W.Position = UDim2.new(1, -75, 0, 7)
        W.Size = UDim2.new(0, 67, 0, 22)
        W.Font = Enum.Font.Gotham
        W.Text = current.Name
        W.TextColor3 = Color3.fromRGB(255, 255, 255)
        W.TextSize = 13
        local WC = Instance.new("UICorner")
        WC.CornerRadius = UDim.new(0, 4)
        WC.Parent = W

        local listening = false

        trackConn(W.MouseButton1Click:Connect(function()
            listening = true
            W.Text = "..."
        end))

        trackConn(UserInputService.InputBegan:Connect(function(input, gp)
            if not listening or gp then return end
            if input.UserInputType ~= Enum.UserInputType.Keyboard then return end
            if input.KeyCode == Enum.KeyCode.Unknown then return end
            current = input.KeyCode
            listening = false
            W.Text = current.Name
            a.flags[F] = current
            local ok, err = pcall(N, current)
            if not ok then warn("[UI] Keybind callback:", err) end
        end))
        return U
    end

    -- ColorPicker：预设颜色选择
    function K:ColorPicker(L, defaultColor, N, F)
        F = F or L
        N = N or function() end
        local current = defaultColor or Color3.fromRGB(131, 132, 255)
        a.flags[F] = current

        local presets = {
            Color3.fromRGB(255, 60, 60),
            Color3.fromRGB(60, 255, 60),
            Color3.fromRGB(60, 130, 255),
            Color3.fromRGB(255, 220, 60),
            Color3.fromRGB(255, 60, 220),
            Color3.fromRGB(131, 132, 255),
            Color3.fromRGB(255, 255, 255),
        }

        local U = Instance.new("Frame")
        U.Name = "ColorPickerObj"
        U.Parent = E
        U.BackgroundColor3 = Color3.fromRGB(43, 43, 43)
        U.BorderSizePixel = 0
        U.Size = UDim2.new(0, 203, 0, 36)
        U.ClipsDescendants = true

        local V = Instance.new("TextLabel")
        V.Parent = U
        V.BackgroundTransparency = 1
        V.Position = UDim2.new(0, 8, 0, 0)
        V.Size = UDim2.new(1, -90, 1, 0)
        V.Font = Enum.Font.Gotham
        V.Text = Txt(L)
        V.TextColor3 = Color3.fromRGB(255, 255, 255)
        V.TextSize = 14
        V.TextXAlignment = Enum.TextXAlignment.Left

        local previewBtn = Instance.new("TextButton")
        previewBtn.Parent = U
        previewBtn.BackgroundColor3 = current
        previewBtn.BorderSizePixel = 0
        previewBtn.Position = UDim2.new(1, -75, 0, 8)
        previewBtn.Size = UDim2.new(0, 67, 0, 20)
        previewBtn.Text = ""
        previewBtn.AutoButtonColor = false
        local pc = Instance.new("UICorner")
        pc.CornerRadius = UDim.new(0, 4)
        pc.Parent = previewBtn

        local rows = math.ceil(#presets / 4)
        local optionFrame = Instance.new("Frame")
        optionFrame.Name = "Colors"
        optionFrame.Parent = U
        optionFrame.BackgroundTransparency = 1
        optionFrame.Position = UDim2.new(0, 0, 0, 36)
        optionFrame.Size = UDim2.new(1, 0, 0, rows * 28)

        local grid = Instance.new("UIGridLayout")
        grid.Parent = optionFrame
        grid.CellSize = UDim2.new(0, 40, 0, 20)
        grid.CellPadding = UDim2.new(0, 6, 0, 8)
        grid.SortOrder = Enum.SortOrder.LayoutOrder

        local expanded = false
        local function setExpanded(state)
            expanded = state
            local targetH = 36 + (expanded and rows * 28 or 0)
            TweenService:Create(U, TweenInfo.new(0.2, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut),
                {Size = UDim2.new(0, 203, 0, targetH)}):Play()
        end

        for idx, c in ipairs(presets) do
            local cb = Instance.new("TextButton")
            cb.Parent = optionFrame
            cb.BackgroundColor3 = c
            cb.BorderSizePixel = 0
            cb.Text = ""
            cb.LayoutOrder = idx
            local cc = Instance.new("UICorner")
            cc.CornerRadius = UDim.new(0, 4)
            cc.Parent = cb
            trackConn(cb.MouseButton1Click:Connect(function()
                current = c
                a.flags[F] = c
                previewBtn.BackgroundColor3 = c
                setExpanded(false)
                local ok, err = pcall(N, c)
                if not ok then warn("[UI] ColorPicker callback:", err) end
            end))
        end

        trackConn(previewBtn.MouseButton1Click:Connect(function()
            setExpanded(not expanded)
        end))
        return U
    end

    return K
end

return a