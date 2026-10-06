local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Library = {}

local Theme = {
    Accent = Color3.fromRGB(62, 145, 255),
    AccentLight = Color3.fromRGB(231, 242, 255),
    AccentDark = Color3.fromRGB(40, 117, 224),
    Background = Color3.fromRGB(247, 249, 252),
    Surface = Color3.fromRGB(255, 255, 255),
    Surface2 = Color3.fromRGB(242, 245, 249),
    Border = Color3.fromRGB(226, 231, 238),
    Text = Color3.fromRGB(42, 48, 58),
    SubText = Color3.fromRGB(125, 134, 148),
    Disabled = Color3.fromRGB(178, 185, 195),
    Success = Color3.fromRGB(53, 184, 111),
    Warning = Color3.fromRGB(242, 167, 63),
    Danger = Color3.fromRGB(235, 91, 91)
}

local Connections = {}

local function Connect(signal, callback)
    local c = signal:Connect(callback)
    table.insert(Connections, c)
    return c
end

local function DisconnectAll()
    for _, c in ipairs(Connections) do
        if c then
            pcall(function()
                c:Disconnect()
            end)
        end
    end
    table.clear(Connections)
end

local function New(className, properties)
    local object = Instance.new(className)
    for property, value in pairs(properties or {}) do
        pcall(function()
            object[property] = value
        end)
    end
    return object
end

local function Corner(parent, radius)
    return New("UICorner", {
        CornerRadius = UDim.new(0, radius),
        Parent = parent
    })
end

local function Stroke(parent, color, transparency, thickness)
    return New("UIStroke", {
        Color = color,
        Transparency = transparency or 0,
        Thickness = thickness or 1,
        ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
        Parent = parent
    })
end

local function Padding(parent, left, right, top, bottom)
    return New("UIPadding", {
        PaddingLeft = UDim.new(0, left or 0),
        PaddingRight = UDim.new(0, right or 0),
        PaddingTop = UDim.new(0, top or 0),
        PaddingBottom = UDim.new(0, bottom or 0),
        Parent = parent
    })
end

local function Tween(object, info, properties)
    local tween = TweenService:Create(object, info, properties)
    tween:Play()
    return tween
end

local function IsMobile()
    return UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
end

local function GetViewport()
    local camera = workspace.CurrentCamera
    return camera and camera.ViewportSize or Vector2.new(800, 600)
end

local function ClampNumber(value, min, max)
    return math.max(min, math.min(max, value))
end

local function MakeText(parent, text, size, color, font)
    return New("TextLabel", {
        BackgroundTransparency = 1,
        Text = text or "",
        TextColor3 = color or Theme.Text,
        TextSize = size or 14,
        Font = font or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        Parent = parent
    })
end

local function MakeButton(parent, text)
    return New("TextButton", {
        AutoButtonColor = false,
        BackgroundTransparency = 1,
        Text = text or "",
        TextColor3 = Theme.Text,
        TextSize = 14,
        Font = Enum.Font.Gotham,
        BorderSizePixel = 0,
        Parent = parent
    })
end

function Library:CreateWindow(options)
    options = options or {}

    local title = options.Title or options.Name or "QQ Lite"
    local subtitle = options.Subtitle or "Ready"
    local width = options.Width or (IsMobile() and 330 or 430)
    local height = options.Height or (IsMobile() and 430 or 500)

    local state = {
        Destroyed = false,
        Minimized = false,
        Tabs = {},
        ActiveTab = nil,
        Popups = {},
        Connections = {},
        Theme = Theme
    }

    local ScreenGui = New("ScreenGui", {
        Name = "QQLite_" .. tostring(math.random(10000, 99999)),
        ResetOnSpawn = false,
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        IgnoreGuiInset = false,
        Parent = PlayerGui
    })

    local Root = New("Frame", {
        Name = "Root",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        Parent = ScreenGui
    })

    local Main = New("Frame", {
        Name = "Main",
        BackgroundColor3 = Theme.Background,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(width, height),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.fromScale(0.5, 0.5),
        Parent = Root
    })

    Corner(Main, 13)
    Stroke(Main, Theme.Border, 0.15, 1)

    local MainScale = New("UIScale", {
        Scale = 1,
        Parent = Main
    })

    local SizeConstraint = New("UISizeConstraint", {
        MinSize = Vector2.new(290, 360),
        MaxSize = Vector2.new(520, 650),
        Parent = Main
    })

    local Shadow = New("ImageLabel", {
        Name = "Shadow",
        BackgroundTransparency = 1,
        Image = "rbxassetid://6014261993",
        ImageTransparency = 0.82,
        ScaleType = Enum.ScaleType.Slice,
        SliceCenter = Rect.new(49, 49, 450, 450),
        Size = UDim2.new(1, 30, 1, 30),
        Position = UDim2.fromOffset(-15, -10),
        ZIndex = 0,
        Parent = Main
    })

    Main.ZIndex = 5

    local Header = New("Frame", {
        Name = "Header",
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 0, 56),
        ZIndex = 10,
        Parent = Main
    })

    Corner(Header, 13)

    local HeaderMask = New("Frame", {
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 0, 0.5, 0),
        Size = UDim2.new(1, 0, 0.5, 0),
        ZIndex = 10,
        Parent = Header
    })

    local AccentLine = New("Frame", {
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Position = UDim2.new(0, 18, 1, -2),
        Size = UDim2.new(1, -36, 0, 2),
        ZIndex = 12,
        Parent = Header
    })

    Corner(AccentLine, 2)

    local Logo = New("Frame", {
        BackgroundColor3 = Theme.AccentLight,
        BorderSizePixel = 0,
        Size = UDim2.fromOffset(32, 32),
        Position = UDim2.fromOffset(14, 12),
        ZIndex = 12,
        Parent = Header
    })

    Corner(Logo, 9)

    local LogoText = MakeText(Logo, "Q", 17, Theme.Accent, Enum.Font.GothamBold)
    LogoText.TextXAlignment = Enum.TextXAlignment.Center
    LogoText.Size = UDim2.fromScale(1, 1)

    local TitleLabel = MakeText(Header, title, 15, Theme.Text, Enum.Font.GothamSemibold)
    TitleLabel.Position = UDim2.fromOffset(56, 8)
    TitleLabel.Size = UDim2.new(1, -142, 0, 22)
    TitleLabel.ZIndex = 12

    local StatusLabel = MakeText(Header, subtitle, 11, Theme.SubText, Enum.Font.Gotham)
    StatusLabel.Position = UDim2.fromOffset(56, 29)
    StatusLabel.Size = UDim2.new(1, -142, 0, 17)
    StatusLabel.ZIndex = 12

    local Minimize = MakeButton(Header, "—")
    Minimize.Size = UDim2.fromOffset(30, 30)
    Minimize.Position = UDim2.new(1, -72, 0, 13)
    Minimize.TextColor3 = Theme.SubText
    Minimize.TextSize = 17
    Minimize.ZIndex = 15

    local Close = MakeButton(Header, "×")
    Close.Size = UDim2.fromOffset(30, 30)
    Close.Position = UDim2.new(1, -40, 0, 13)
    Close.TextColor3 = Theme.SubText
    Close.TextSize = 21
    Close.ZIndex = 15

    local Body = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 56),
        Size = UDim2.new(1, 0, 1, -56),
        Parent = Main
    })

    local TabRail = New("Frame", {
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Position = UDim2.fromOffset(8, 8),
        Size = UDim2.new(0, IsMobile() and 82 or 94, 1, -16),
        Parent = Body
    })

    Corner(TabRail, 10)
    Stroke(TabRail, Theme.Border, 0.4, 1)

    local TabList = New("ScrollingFrame", {
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Size = UDim2.new(1, 0, 1, 0),
        CanvasSize = UDim2.new(),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = Theme.Border,
        Parent = TabRail
    })

    Padding(TabList, 6, 6, 7, 7)

    local TabLayout = New("UIListLayout", {
        Padding = UDim.new(0, 4),
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = TabList
    })

    local Content = New("Frame", {
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Position = UDim2.new(0, IsMobile() and 96 or 108, 0, 8),
        Size = UDim2.new(1, -(IsMobile() and 104 or 116), 1, -16),
        Parent = Body
    })

    Corner(Content, 10)
    Stroke(Content, Theme.Border, 0.4, 1)

    local PageContainer = New("Frame", {
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(0, 0),
        Size = UDim2.fromScale(1, 1),
        ClipsDescendants = true,
        Parent = Content
    })

    local PopupLayer = New("Frame", {
        Name = "PopupLayer",
        BackgroundTransparency = 1,
        Size = UDim2.fromScale(1, 1),
        ZIndex = 1000,
        Parent = Root
    })

    local NotificationLayer = New("Frame", {
        Name = "NotificationLayer",
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -14, 0, 14),
        Size = UDim2.fromOffset(IsMobile() and 290 or 330, 1),
        AutomaticSize = Enum.AutomaticSize.Y,
        ZIndex = 2000,
        Parent = Root
    })

    New("UIListLayout", {
        Padding = UDim.new(0, 7),
        HorizontalAlignment = Enum.HorizontalAlignment.Right,
        SortOrder = Enum.SortOrder.LayoutOrder,
        Parent = NotificationLayer
    })

    local Launcher = New("TextButton", {
        Name = "Launcher",
        AutoButtonColor = false,
        BackgroundColor3 = Theme.Accent,
        BorderSizePixel = 0,
        Text = "Q",
        TextColor3 = Color3.new(1, 1, 1),
        TextSize = 17,
        Font = Enum.Font.GothamBold,
        Size = UDim2.fromOffset(48, 48),
        AnchorPoint = Vector2.new(1, 1),
        Position = UDim2.new(1, -18, 1, -18),
        Visible = false,
        ZIndex = 3000,
        Parent = Root
    })

    Corner(Launcher, 16)
    Stroke(Launcher, Color3.new(1, 1, 1), 0.8, 1)

    local function AnimateScale(target, duration)
        Tween(MainScale, TweenInfo.new(duration, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Scale = target
        })
    end

    local function ClosePopups()
        for _, popup in ipairs(state.Popups) do
            if popup and popup.Parent then
                popup:Destroy()
            end
        end
        table.clear(state.Popups)
    end

    local function Destroy()
        if state.Destroyed then
            return
        end

        state.Destroyed = true
        ClosePopups()

        Tween(Main, TweenInfo.new(0.18, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            BackgroundTransparency = 1
        })

        AnimateScale(0.88, 0.18)

        task.delay(0.19, function()
            DisconnectAll()
            if ScreenGui then
                ScreenGui:Destroy()
            end
        end)
    end

    local function MinimizeWindow()
        if state.Destroyed or state.Minimized then
            return
        end

        state.Minimized = true
        ClosePopups()

        Tween(Main, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
            BackgroundTransparency = 1
        })

        AnimateScale(0.72, 0.2)

        task.delay(0.21, function()
            if not state.Destroyed then
                Main.Visible = false
                Launcher.Visible = true
                Launcher.Size = UDim2.fromOffset(0, 0)
                Tween(Launcher, TweenInfo.new(0.24, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    Size = UDim2.fromOffset(48, 48)
                })
            end
        end)
    end

    local function RestoreWindow()
        if state.Destroyed or not state.Minimized then
            return
        end

        state.Minimized = false
        Launcher.Visible = false
        Main.Visible = true
        Main.BackgroundTransparency = 1
        MainScale.Scale = 0.72

        Tween(Main, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0
        })

        AnimateScale(1, 0.24)
    end

    Connect(Minimize.MouseButton1Click, MinimizeWindow)
    Connect(Close.MouseButton1Click, Destroy)
    Connect(Launcher.MouseButton1Click, RestoreWindow)

    local Dragging = false
    local DragStart
    local StartPosition

    Connect(Header.InputBegan, function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then

            Dragging = true
            DragStart = input.Position
            StartPosition = Main.Position

            local connection
            connection = input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    Dragging = false
                    connection:Disconnect()
                end
            end)
        end
    end)

    Connect(UserInputService.InputChanged, function(input)
        if not Dragging then
            return
        end

        if input.UserInputType ~= Enum.UserInputType.MouseMovement
            and input.UserInputType ~= Enum.UserInputType.Touch then
            return
        end

        local delta = input.Position - DragStart

        Main.Position = UDim2.new(
            StartPosition.X.Scale,
            StartPosition.X.Offset + delta.X,
            StartPosition.Y.Scale,
            StartPosition.Y.Offset + delta.Y
        )
    end)

    local function CreatePage(tab)
        local Page = New("ScrollingFrame", {
            Name = "Page_" .. tab.Name,
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            Size = UDim2.fromScale(1, 1),
            CanvasSize = UDim2.new(),
            AutomaticCanvasSize = Enum.AutomaticSize.Y,
            ScrollBarThickness = 3,
            ScrollBarImageColor3 = Theme.Border,
            Visible = false,
            Parent = PageContainer
        })

        Padding(Page, 12, 12, 12, 12)

        local Layout = New("UIListLayout", {
            Padding = UDim.new(0, 7),
            SortOrder = Enum.SortOrder.LayoutOrder,
            Parent = Page
        })

        local function AddSection(titleText)
            local Section = New("Frame", {
                BackgroundColor3 = Theme.Background,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 32),
                Parent = Page
            })

            Corner(Section, 7)

            local Bar = New("Frame", {
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
                Position = UDim2.fromOffset(9, 9),
                Size = UDim2.fromOffset(3, 14),
                Parent = Section
            })

            Corner(Bar, 2)

            local Label = MakeText(Section, titleText, 12, Theme.Text, Enum.Font.GothamSemibold)
            Label.Position = UDim2.fromOffset(19, 0)
            Label.Size = UDim2.new(1, -28, 1, 0)

            return Section
        end

        local function AddLabel(text)
            local Row = New("Frame", {
                BackgroundTransparency = 1,
                Size = UDim2.new(1, 0, 0, 30),
                Parent = Page
            })

            local Label = MakeText(Row, text, 13, Theme.Text, Enum.Font.GothamMedium)
            Label.Position = UDim2.fromOffset(2, 0)
            Label.Size = UDim2.new(1, -4, 1, 0)

            return {
                Instance = Row,
                SetText = function(_, value)
                    Label.Text = tostring(value)
                end
            }
        end

        local function AddParagraph(text)
            local Row = New("Frame", {
                BackgroundColor3 = Theme.Background,
                BorderSizePixel = 0,
                AutomaticSize = Enum.AutomaticSize.Y,
                Size = UDim2.new(1, 0, 0, 0),
                Parent = Page
            })

            Corner(Row, 8)
            Padding(Row, 11, 11, 9, 9)

            local Label = MakeText(Row, text, 12, Theme.SubText, Enum.Font.Gotham)
            Label.TextWrapped = true
            Label.AutomaticSize = Enum.AutomaticSize.Y
            Label.Size = UDim2.new(1, 0, 0, 0)

            return {
                Instance = Row,
                SetText = function(_, value)
                    Label.Text = tostring(value)
                end
            }
        end

        local function AddDivider()
            local Divider = New("Frame", {
                BackgroundColor3 = Theme.Border,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 1),
                Parent = Page
            })

            return Divider
        end

        local function AddButton(text, callback)
            local Row = New("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 38),
                Text = "",
                Parent = Page
            })

            Corner(Row, 8)
            Stroke(Row, Theme.Border, 0.25, 1)

            local Label = MakeText(Row, text, 12, Theme.Text, Enum.Font.GothamMedium)
            Label.Position = UDim2.fromOffset(12, 0)
            Label.Size = UDim2.new(1, -44, 1, 0)

            local Arrow = MakeText(Row, "›", 20, Theme.SubText, Enum.Font.Gotham)
            Arrow.TextXAlignment = Enum.TextXAlignment.Center
            Arrow.Position = UDim2.new(1, -35, 0, 0)
            Arrow.Size = UDim2.fromOffset(28, 38)

            Connect(Row.MouseButton1Down, function()
                Tween(Row, TweenInfo.new(0.08), {
                    BackgroundColor3 = Theme.AccentLight
                })
            end)

            Connect(Row.MouseButton1Up, function()
                Tween(Row, TweenInfo.new(0.13), {
                    BackgroundColor3 = Theme.Surface
                })
            end)

            Connect(Row.MouseButton1Click, function()
                if callback then
                    task.spawn(callback)
                end
            end)

            return {
                Instance = Row,
                SetText = function(_, value)
                    Label.Text = tostring(value)
                end
            }
        end

        local function AddToggle(text, default, callback)
            local value = default == true

            local Row = New("Frame", {
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 40),
                Parent = Page
            })

            Corner(Row, 8)
            Stroke(Row, Theme.Border, 0.25, 1)

            local Label = MakeText(Row, text, 12, Theme.Text, Enum.Font.GothamMedium)
            Label.Position = UDim2.fromOffset(12, 0)
            Label.Size = UDim2.new(1, -70, 1, 0)

            local Toggle = New("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = value and Theme.Accent or Theme.Border,
                BorderSizePixel = 0,
                Size = UDim2.fromOffset(42, 23),
                Position = UDim2.new(1, -53, 0.5, -11),
                Text = "",
                Parent = Row
            })

            Corner(Toggle, 12)

            local Knob = New("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                Size = UDim2.fromOffset(19, 19),
                Position = value and UDim2.new(1, -21, 0.5, -9) or UDim2.fromOffset(2, 2),
                Parent = Toggle
            })

            Corner(Knob, 10)

            local function SetValue(newValue)
                value = newValue == true

                Tween(Toggle, TweenInfo.new(0.16, Enum.EasingStyle.Quint), {
                    BackgroundColor3 = value and Theme.Accent or Theme.Border
                })

                Tween(Knob, TweenInfo.new(0.18, Enum.EasingStyle.Back), {
                    Position = value and UDim2.new(1, -21, 0.5, -9) or UDim2.fromOffset(2, 2)
                })

                if callback then
                    task.spawn(callback, value)
                end
            end

            Connect(Toggle.MouseButton1Click, function()
                SetValue(not value)
            end)

            return {
                Instance = Row,
                Set = function(_, v)
                    SetValue(v)
                end,
                Get = function()
                    return value
                end
            }
        end

        local function AddSlider(text, min, max, default, callback)
            min = tonumber(min) or 0
            max = tonumber(max) or 100
            default = ClampNumber(tonumber(default) or min, min, max)

            local value = default

            local Row = New("Frame", {
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 56),
                Parent = Page
            })

            Corner(Row, 8)
            Stroke(Row, Theme.Border, 0.25, 1)

            local Label = MakeText(Row, text, 12, Theme.Text, Enum.Font.GothamMedium)
            Label.Position = UDim2.fromOffset(12, 6)
            Label.Size = UDim2.new(1, -70, 0, 19)

            local ValueLabel = MakeText(Row, tostring(value), 11, Theme.Accent, Enum.Font.GothamSemibold)
            ValueLabel.Position = UDim2.new(1, -57, 0, 6)
            ValueLabel.Size = UDim2.fromOffset(45, 19)
            ValueLabel.TextXAlignment = Enum.TextXAlignment.Right

            local Bar = New("Frame", {
                BackgroundColor3 = Theme.Border,
                BorderSizePixel = 0,
                Position = UDim2.fromOffset(12, 35),
                Size = UDim2.new(1, -24, 0, 5),
                Parent = Row
            })

            Corner(Bar, 4)

            local Fill = New("Frame", {
                BackgroundColor3 = Theme.Accent,
                BorderSizePixel = 0,
                Size = UDim2.new((value - min) / (max - min), 0, 1, 0),
                Parent = Bar
            })

            Corner(Fill, 4)

            local Knob = New("Frame", {
                BackgroundColor3 = Color3.new(1, 1, 1),
                BorderSizePixel = 0,
                Size = UDim2.fromOffset(13, 13),
                AnchorPoint = Vector2.new(0.5, 0.5),
                Position = UDim2.new((value - min) / (max - min), 0, 0.5, 0),
                Parent = Bar
            })

            Corner(Knob, 7)
            Stroke(Knob, Theme.Accent, 0.1, 1)

            local Sliding = false

            local function Update(inputX)
                local x = ClampNumber(
                    inputX - Bar.AbsolutePosition.X,
                    0,
                    Bar.AbsoluteSize.X
                )

                local percent = Bar.AbsoluteSize.X > 0 and x / Bar.AbsoluteSize.X or 0
                value = min + (max - min) * percent

                if math.abs(max - min) <= 100 then
                    value = math.round(value)
                else
                    value = math.floor(value * 100) / 100
                end

                local normalized = (value - min) / (max - min)

                Fill.Size = UDim2.new(normalized, 0, 1, 0)
                Knob.Position = UDim2.new(normalized, 0, 0.5, 0)
                ValueLabel.Text = tostring(value)

                if callback then
                    task.spawn(callback, value)
                end
            end

            Connect(Bar.InputBegan, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    Sliding = true
                    Update(input.Position.X)
                end
            end)

            Connect(UserInputService.InputChanged, function(input)
                if Sliding and (
                    input.UserInputType == Enum.UserInputType.MouseMovement
                    or input.UserInputType == Enum.UserInputType.Touch
                ) then
                    Update(input.Position.X)
                end
            end)

            Connect(UserInputService.InputEnded, function(input)
                if input.UserInputType == Enum.UserInputType.MouseButton1
                    or input.UserInputType == Enum.UserInputType.Touch then
                    Sliding = false
                end
            end)

            return {
                Instance = Row,
                Set = function(_, v)
                    value = ClampNumber(tonumber(v) or min, min, max)
                    local normalized = (value - min) / (max - min)
                    Fill.Size = UDim2.new(normalized, 0, 1, 0)
                    Knob.Position = UDim2.new(normalized, 0, 0.5, 0)
                    ValueLabel.Text = tostring(value)
                end,
                Get = function()
                    return value
                end
            }
        end

        local function CreateDropdown(text, items, multi, default, callback)
            items = items or {}
            local selected = {}

            if multi then
                if type(default) == "table" then
                    for _, item in ipairs(default) do
                        selected[item] = true
                    end
                end
            else
                selected.value = default or items[1]
            end

            local open = false

            local Row = New("Frame", {
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 40),
                Parent = Page
            })

            Corner(Row, 8)
            Stroke(Row, Theme.Border, 0.25, 1)

            local Button = New("TextButton", {
                AutoButtonColor = false,
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                Size = UDim2.fromScale(1, 1),
                Text = "",
                Parent = Row
            })

            local Label = MakeText(Row, text, 12, Theme.Text, Enum.Font.GothamMedium)
            Label.Position = UDim2.fromOffset(12, 0)
            Label.Size = UDim2.new(0.43, 0, 1, 0)

            local Current = MakeText(Row, "", 11, Theme.SubText, Enum.Font.Gotham)
            Current.Position = UDim2.new(0.43, 0, 0, 0)
            Current.Size = UDim2.new(0.45, -5, 1, 0)
            Current.TextXAlignment = Enum.TextXAlignment.Right
            Current.TextTruncate = Enum.TextTruncate.AtEnd

            local Arrow = MakeText(Row, "⌄", 15, Theme.SubText, Enum.Font.GothamMedium)
            Arrow.Position = UDim2.new(1, -34, 0, 0)
            Arrow.Size = UDim2.fromOffset(25, 40)
            Arrow.TextXAlignment = Enum.TextXAlignment.Center

            local function GetText()
                if multi then
                    local result = {}
                    for _, item in ipairs(items) do
                        if selected[item] then
                            table.insert(result, tostring(item))
                        end
                    end

                    if #result == 0 then
                        return "未选择"
                    elseif #result <= 2 then
                        return table.concat(result, "、")
                    else
                        return tostring(#result) .. " 项已选择"
                    end
                end

                return tostring(selected.value or "未选择")
            end

            Current.Text = GetText()

            local function Close()
                if not open then
                    return
                end

                open = false

                for _, popup in ipairs(state.Popups) do
                    if popup and popup:GetAttribute("Owner") == Row:GetDebugId() then
                        Tween(popup, TweenInfo.new(0.12), {
                            Size = UDim2.new(1, 0, 0, 0)
                        })
                        task.delay(0.13, function()
                            if popup then
                                popup:Destroy()
                            end
                        end)
                    end
                end

                Arrow.Text = "⌄"
            end

            local function Open()
                if open then
                    Close()
                    return
                end

                ClosePopups()
                open = true

                local absolute = Row.AbsolutePosition
                local size = Row.AbsoluteSize

                local Popup = New("Frame", {
                    BackgroundColor3 = Theme.Surface,
                    BorderSizePixel = 0,
                    Position = UDim2.fromOffset(
                        absolute.X,
                        absolute.Y + size.Y + 5
                    ),
                    Size = UDim2.fromOffset(
                        size.X,
                        0
                    ),
                    ZIndex = 1100,
                    Parent = PopupLayer
                })

                Popup:SetAttribute("Owner", Row:GetDebugId())

                Corner(Popup, 8)
                Stroke(Popup, Theme.Border, 0.05, 1)

                local PopupScroll = New("ScrollingFrame", {
                    BackgroundTransparency = 1,
                    BorderSizePixel = 0,
                    Position = UDim2.fromOffset(4, 4),
                    Size = UDim2.new(1, -8, 1, -8),
                    CanvasSize = UDim2.new(),
                    AutomaticCanvasSize = Enum.AutomaticSize.Y,
                    ScrollBarThickness = 2,
                    ScrollBarImageColor3 = Theme.Border,
                    ZIndex = 1101,
                    Parent = Popup
                })

                Padding(PopupScroll, 3, 3, 3, 3)

                local Layout = New("UIListLayout", {
                    Padding = UDim.new(0, 3),
                    Parent = PopupScroll
                })

                for _, item in ipairs(items) do
                    local itemSelected = multi and selected[item] or selected.value == item

                    local Option = New("TextButton", {
                        AutoButtonColor = false,
                        BackgroundColor3 = itemSelected and Theme.AccentLight or Theme.Surface,
                        BorderSizePixel = 0,
                        Size = UDim2.new(1, 0, 0, 32),
                        Text = "",
                        ZIndex = 1102,
                        Parent = PopupScroll
                    })

                    Corner(Option, 6)

                    local OptionLabel = MakeText(
                        Option,
                        tostring(item),
                        11,
                        itemSelected and Theme.Accent or Theme.Text,
                        Enum.Font.GothamMedium
                    )

                    OptionLabel.Position = UDim2.fromOffset(10, 0)
                    OptionLabel.Size = UDim2.new(1, -45, 1, 0)
                    OptionLabel.ZIndex = 1103

                    local Mark = MakeText(
                        Option,
                        itemSelected and "✓" or "",
                        13,
                        Theme.Accent,
                        Enum.Font.GothamBold
                    )

                    Mark.Position = UDim2.new(1, -32, 0, 0)
                    Mark.Size = UDim2.fromOffset(25, 32)
                    Mark.TextXAlignment = Enum.TextXAlignment.Center
                    Mark.ZIndex = 1103

                    Connect(Option.MouseButton1Click, function()
                        if multi then
                            selected[item] = not selected[item]
                            Mark.Text = selected[item] and "✓" or ""
                            Option.BackgroundColor3 = selected[item] and Theme.AccentLight or Theme.Surface
                            OptionLabel.TextColor3 = selected[item] and Theme.Accent or Theme.Text
                            Current.Text = GetText()

                            if callback then
                                local result = {}
                                for _, value in ipairs(items) do
                                    if selected[value] then
                                        table.insert(result, value)
                                    end
                                end
                                task.spawn(callback, result)
                            end
                        else
                            selected.value = item
                            Current.Text = GetText()

                            if callback then
                                task.spawn(callback, item)
                            end

                            Close()
                        end
                    end)
                end

                table.insert(state.Popups, Popup)

                local maxHeight = math.min(190, math.max(70, #items * 35 + 12))

                Tween(Popup, TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Size = UDim2.fromOffset(size.X, maxHeight)
                })

                Arrow.Text = "⌃"
            end

            Connect(Button.MouseButton1Click, Open)

            return {
                Instance = Row,
                Set = function(_, value)
                    if multi then
                        table.clear(selected)
                        if type(value) == "table" then
                            for _, item in ipairs(value) do
                                selected[item] = true
                            end
                        end
                    else
                        selected.value = value
                    end
                    Current.Text = GetText()
                end,
                Get = function()
                    if multi then
                        local result = {}
                        for _, item in ipairs(items) do
                            if selected[item] then
                                table.insert(result, item)
                            end
                        end
                        return result
                    end
                    return selected.value
                end
            }
        end

        local function AddDropdown(text, items, default, callback)
            return CreateDropdown(text, items, false, default, callback)
        end

        local function AddMultiDropdown(text, items, default, callback)
            return CreateDropdown(text, items, true, default, callback)
        end

        local function AddTextbox(text, placeholder, default, callback)
            local Row = New("Frame", {
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 46),
                Parent = Page
            })

            Corner(Row, 8)
            Stroke(Row, Theme.Border, 0.25, 1)

            local Label = MakeText(Row, text, 11, Theme.SubText, Enum.Font.GothamMedium)
            Label.Position = UDim2.fromOffset(11, 4)
            Label.Size = UDim2.new(1, -22, 0, 15)

            local Box = New("TextBox", {
                BackgroundTransparency = 1,
                BorderSizePixel = 0,
                ClearTextOnFocus = false,
                Text = default or "",
                PlaceholderText = placeholder or "",
                PlaceholderColor3 = Theme.Disabled,
                TextColor3 = Theme.Text,
                TextSize = 12,
                Font = Enum.Font.Gotham,
                TextXAlignment = Enum.TextXAlignment.Left,
                Position = UDim2.fromOffset(11, 20),
                Size = UDim2.new(1, -22, 0, 21),
                Parent = Row
            })

            Connect(Box.FocusLost, function()
                if callback then
                    task.spawn(callback, Box.Text)
                end
            end)

            return {
                Instance = Row,
                Set = function(_, value)
                    Box.Text = tostring(value)
                end,
                Get = function()
                    return Box.Text
                end
            }
        end

        local function AddKeybind(text, default, callback)
            local key = default or Enum.KeyCode.RightShift
            local listening = false

            local Row = New("Frame", {
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 40),
                Parent = Page
            })

            Corner(Row, 8)
            Stroke(Row, Theme.Border, 0.25, 1)

            local Label = MakeText(Row, text, 12, Theme.Text, Enum.Font.GothamMedium)
            Label.Position = UDim2.fromOffset(12, 0)
            Label.Size = UDim2.new(1, -110, 1, 0)

            local Bind = New("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = Theme.Background,
                BorderSizePixel = 0,
                Size = UDim2.fromOffset(88, 26),
                Position = UDim2.new(1, -100, 0.5, -13),
                Text = key.Name,
                TextColor3 = Theme.Accent,
                TextSize = 11,
                Font = Enum.Font.GothamSemibold,
                Parent = Row
            })

            Corner(Bind, 6)
            Stroke(Bind, Theme.Border, 0.2, 1)

            Connect(Bind.MouseButton1Click, function()
                if listening then
                    return
                end

                listening = true
                Bind.Text = "按下按键"

                local connection
                connection = UserInputService.InputBegan:Connect(function(input, processed)
                    if processed then
                        return
                    end

                    if input.UserInputType == Enum.UserInputType.Keyboard then
                        key = input.KeyCode
                        Bind.Text = key.Name
                        listening = false
                        connection:Disconnect()

                        if callback then
                            task.spawn(callback, key)
                        end
                    end
                end)
            end)

            return {
                Instance = Row,
                Set = function(_, value)
                    if typeof(value) == "EnumItem" then
                        key = value
                        Bind.Text = key.Name
                    end
                end,
                Get = function()
                    return key
                end
            }
        end

        local function AddColorPicker(text, default, callback)
            local color = typeof(default) == "Color3" and default or Theme.Accent

            local Row = New("Frame", {
                BackgroundColor3 = Theme.Surface,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 40),
                Parent = Page
            })

            Corner(Row, 8)
            Stroke(Row, Theme.Border, 0.25, 1)

            local Label = MakeText(Row, text, 12, Theme.Text, Enum.Font.GothamMedium)
            Label.Position = UDim2.fromOffset(12, 0)
            Label.Size = UDim2.new(1, -65, 1, 0)

            local Swatch = New("TextButton", {
                AutoButtonColor = false,
                BackgroundColor3 = color,
                BorderSizePixel = 0,
                Size = UDim2.fromOffset(30, 22),
                Position = UDim2.new(1, -42, 0.5, -11),
                Text = "",
                Parent = Row
            })

            Corner(Swatch, 7)
            Stroke(Swatch, Theme.Border, 0.05, 1)

            local Popup

            local function Close()
                if Popup then
                    Popup:Destroy()
                    Popup = nil
                end
            end

            local function Open()
                Close()

                local position = Row.AbsolutePosition
                local size = Row.AbsoluteSize

                Popup = New("Frame", {
                    BackgroundColor3 = Theme.Surface,
                    BorderSizePixel = 0,
                    Position = UDim2.fromOffset(position.X, position.Y + size.Y + 5),
                    Size = UDim2.fromOffset(size.X, 145),
                    ZIndex = 1200,
                    Parent = PopupLayer
                })

                Corner(Popup, 8)
                Stroke(Popup, Theme.Border, 0.05, 1)

                local Hue = New("TextButton", {
                    AutoButtonColor = false,
                    BackgroundColor3 = Color3.fromHSV(0, 1, 1),
                    BorderSizePixel = 0,
                    Position = UDim2.fromOffset(12, 12),
                    Size = UDim2.new(1, -24, 18, 0),
                    Text = "",
                    ZIndex = 1201,
                    Parent = Popup
                })

                local HueGradient = New("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.fromHSV(0, 1, 1)),
                        ColorSequenceKeypoint.new(0.17, Color3.fromHSV(0.17, 1, 1)),
                        ColorSequenceKeypoint.new(0.34, Color3.fromHSV(0.34, 1, 1)),
                        ColorSequenceKeypoint.new(0.51, Color3.fromHSV(0.51, 1, 1)),
                        ColorSequenceKeypoint.new(0.68, Color3.fromHSV(0.68, 1, 1)),
                        ColorSequenceKeypoint.new(0.85, Color3.fromHSV(0.85, 1, 1)),
                        ColorSequenceKeypoint.new(1, Color3.fromHSV(1, 1, 1))
                    }),
                    Parent = Hue
                })

                Corner(Hue, 5)

                local Value = New("TextButton", {
                    AutoButtonColor = false,
                    BackgroundColor3 = Color3.new(1, 1, 1),
                    BorderSizePixel = 0,
                    Position = UDim2.fromOffset(12, 40),
                    Size = UDim2.new(1, -24, 18, 0),
                    Text = "",
                    ZIndex = 1201,
                    Parent = Popup
                })

                local ValueGradient = New("UIGradient", {
                    Color = ColorSequence.new({
                        ColorSequenceKeypoint.new(0, Color3.new(1, 1, 1)),
                        ColorSequenceKeypoint.new(1, Color3.new(0, 0, 0))
                    }),
                    Rotation = 90,
                    Parent = Value
                })

                Corner(Value, 5)

                local hue = 0
                local saturation = 1
                local brightness = 1

                local function Apply()
                    color = Color3.fromHSV(hue, saturation, brightness)
                    Swatch.BackgroundColor3 = color

                    if callback then
                        task.spawn(callback, color)
                    end
                end

                local function PickHue(input)
                    local x = ClampNumber(
                        input.Position.X - Hue.AbsolutePosition.X,
                        0,
                        Hue.AbsoluteSize.X
                    )

                    hue = Hue.AbsoluteSize.X > 0 and x / Hue.AbsoluteSize.X or 0
                    Apply()
                end

                local function PickValue(input)
                    local x = ClampNumber(
                        input.Position.X - Value.AbsolutePosition.X,
                        0,
                        Value.AbsoluteSize.X
                    )

                    saturation = Value.AbsoluteSize.X > 0 and x / Value.AbsoluteSize.X or 0
                    Apply()
                end

                Connect(Hue.MouseButton1Click, PickHue)
                Connect(Value.MouseButton1Click, PickValue)

                local CloseButton = New("TextButton", {
                    AutoButtonColor = false,
                    BackgroundColor3 = Theme.Background,
                    BorderSizePixel = 0,
                    Position = UDim2.new(0, 12, 1, -42),
                    Size = UDim2.new(1, -24, 0, 30),
                    Text = "完成",
                    TextColor3 = Theme.Text,
                    TextSize = 11,
                    Font = Enum.Font.GothamMedium,
                    ZIndex = 1201,
                    Parent = Popup
                })

                Corner(CloseButton, 6)
                Connect(CloseButton.MouseButton1Click, Close)
            end

            Connect(Swatch.MouseButton1Click, Open)

            return {
                Instance = Row,
                Set = function(_, value)
                    if typeof(value) == "Color3" then
                        color = value
                        Swatch.BackgroundColor3 = color
                    end
                end,
                Get = function()
                    return color
                end
            }
        end

        local function AddStatus(text, status)
            local colors = {
                Online = Theme.Success,
                Success = Theme.Success,
                Warning = Theme.Warning,
                Error = Theme.Danger,
                Offline = Theme.SubText
            }

            local Row = New("Frame", {
                BackgroundColor3 = Theme.Background,
                BorderSizePixel = 0,
                Size = UDim2.new(1, 0, 0, 34),
                Parent = Page
            })

            Corner(Row, 8)

            local Dot = New("Frame", {
                BackgroundColor3 = colors[status] or Theme.Accent,
                BorderSizePixel = 0,
                Size = UDim2.fromOffset(8, 8),
                Position = UDim2.fromOffset(12, 13),
                Parent = Row
            })

            Corner(Dot, 4)

            local Label = MakeText(
                Row,
                text .. " · " .. tostring(status or "Ready"),
                11,
                Theme.SubText,
                Enum.Font.GothamMedium
            )

            Label.Position = UDim2.fromOffset(27, 0)
            Label.Size = UDim2.new(1, -35, 1, 0)

            return {
                Instance = Row,
                Set = function(_, newStatus)
                    Dot.BackgroundColor3 = colors[newStatus] or Theme.Accent
                    Label.Text = text .. " · " .. tostring(newStatus)
                end
            }
        end

        local API = {}

        function API:CreateSection(text)
            return AddSection(text)
        end

        function API:CreateLabel(text)
            return AddLabel(text)
        end

        function API:CreateParagraph(text)
            return AddParagraph(text)
        end

        function API:CreateDivider()
            return AddDivider()
        end

        function API:CreateButton(text, callback)
            return AddButton(text, callback)
        end

        function API:CreateToggle(text, default, callback)
            return AddToggle(text, default, callback)
        end

        function API:CreateSlider(text, min, max, default, callback)
            return AddSlider(text, min, max, default, callback)
        end

        function API:CreateDropdown(text, items, default, callback)
            return AddDropdown(text, items, default, callback)
        end

        function API:CreateMultiDropdown(text, items, default, callback)
            return AddMultiDropdown(text, items, default, callback)
        end

        function API:CreateTextbox(text, placeholder, default, callback)
            return AddTextbox(text, placeholder, default, callback)
        end

        function API:CreateKeybind(text, default, callback)
            return AddKeybind(text, default, callback)
        end

        function API:CreateColorPicker(text, default, callback)
            return AddColorPicker(text, default, callback)
        end

        function API:CreateStatus(text, status)
            return AddStatus(text, status)
        end

        return Page, API
    end

    local function SelectTab(tab)
        if state.ActiveTab == tab or state.Destroyed then
            return
        end

        local previous = state.ActiveTab
        state.ActiveTab = tab

        for _, item in ipairs(state.Tabs) do
            local active = item == tab

            Tween(item.Button, TweenInfo.new(0.14, Enum.EasingStyle.Quint), {
                BackgroundColor3 = active and Theme.AccentLight or Theme.Surface
            })

            Tween(item.Label, TweenInfo.new(0.14), {
                TextColor3 = active and Theme.Accent or Theme.Text
            })

            Tween(item.Indicator, TweenInfo.new(0.16, Enum.EasingStyle.Quint), {
                Size = active and UDim2.new(0, 3, 0, 22) or UDim2.new(0, 3, 0, 0)
            })

            if active then
                item.Page.Visible = true
                item.Page.Position = UDim2.fromOffset(8, 0)

                Tween(item.Page, TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    Position = UDim2.fromOffset(0, 0)
                })
            elseif previous == item then
                Tween(item.Page, TweenInfo.new(0.1, Enum.EasingStyle.Quint), {
                    Position = UDim2.fromOffset(-8, 0)
                })

                task.delay(0.1, function()
                    if item.Page then
                        item.Page.Visible = false
                    end
                end)
            else
                item.Page.Visible = false
            end
        end
    end

    function state:AddTab(name, icon)
        if state.Destroyed then
            return nil
        end

        local Tab = {
            Name = name,
            Icon = icon or "",
            Order = #state.Tabs + 1
        }

        local Button = New("TextButton", {
            AutoButtonColor = false,
            BackgroundColor3 = Theme.Surface,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 42),
            Text = "",
            LayoutOrder = Tab.Order,
            Parent = TabList
        })

        Corner(Button, 8)

        local Indicator = New("Frame", {
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            AnchorPoint = Vector2.new(0, 0.5),
            Position = UDim2.new(0, 0, 0.5, 0),
            Size = UDim2.new(0, 3, 0, 0),
            Parent = Button
        })

        Corner(Indicator, 2)

        local Icon = MakeText(Button, icon or "•", 14, Theme.SubText, Enum.Font.GothamMedium)
        Icon.TextXAlignment = Enum.TextXAlignment.Center
        Icon.Position = UDim2.fromOffset(5, 0)
        Icon.Size = UDim2.fromOffset(25, 42)

        local Label = MakeText(Button, name, 10, Theme.Text, Enum.Font.GothamMedium)
        Label.Position = UDim2.fromOffset(29, 0)
        Label.Size = UDim2.new(1, -33, 1, 0)
        Label.TextTruncate = Enum.TextTruncate.AtEnd

        local Page, PageAPI = CreatePage(Tab)

        Tab.Button = Button
        Tab.Indicator = Indicator
        Tab.Label = Label
        Tab.Page = Page
        Tab.API = PageAPI

        table.insert(state.Tabs, Tab)

        Connect(Button.MouseButton1Click, function()
            SelectTab(Tab)
        end)

        if not state.ActiveTab then
            state.ActiveTab = Tab
            Page.Visible = true

            Tween(Button, TweenInfo.new(0.14), {
                BackgroundColor3 = Theme.AccentLight
            })

            Label.TextColor3 = Theme.Accent

            Tween(Indicator, TweenInfo.new(0.18, Enum.EasingStyle.Quint), {
                Size = UDim2.new(0, 3, 0, 22)
            })
        end

        return PageAPI
    end

    function state:Notify(data)
        data = data or {}

        local notificationTitle = data.Title or "Notification"
        local notificationText = data.Content or data.Text or ""
        local duration = tonumber(data.Duration) or 3

        local Card = New("Frame", {
            BackgroundColor3 = Theme.Surface,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 0),
            AutomaticSize = Enum.AutomaticSize.Y,
            ClipsDescendants = true,
            Parent = NotificationLayer
        })

        Corner(Card, 9)
        Stroke(Card, Theme.Border, 0.15, 1)

        Padding(Card, 11, 11, 9, 9)

        local Title = MakeText(Card, notificationTitle, 12, Theme.Text, Enum.Font.GothamSemibold)
        Title.Size = UDim2.new(1, 0, 0, 18)

        local BodyText = MakeText(Card, notificationText, 11, Theme.SubText, Enum.Font.Gotham)
        BodyText.TextWrapped = true
        BodyText.AutomaticSize = Enum.AutomaticSize.Y
        BodyText.Position = UDim2.fromOffset(0, 20)
        BodyText.Size = UDim2.new(1, 0, 0, 0)

        local Bar = New("Frame", {
            BackgroundColor3 = Theme.Accent,
            BorderSizePixel = 0,
            Position = UDim2.new(0, 0, 1, -2),
            Size = UDim2.new(1, 0, 0, 2),
            Parent = Card
        })

        local originalSize = Card.Size

        Card.Size = UDim2.new(1, 0, 0, 0)

        Tween(Card, TweenInfo.new(0.2, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            Size = originalSize
        })

        Tween(Bar, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
            Size = UDim2.new(0, 0, 0, 2)
        })

        task.delay(duration, function()
            if Card and Card.Parent then
                Tween(Card, TweenInfo.new(0.17, Enum.EasingStyle.Quint, Enum.EasingDirection.In), {
                    Size = UDim2.new(1, 0, 0, 0)
                })

                task.delay(0.18, function()
                    if Card then
                        Card:Destroy()
                    end
                end)
            end
        end)

        return Card
    end

    function state:SetTitle(value)
        TitleLabel.Text = tostring(value)
    end

    function state:SetSubtitle(value)
        StatusLabel.Text = tostring(value)
    end

    function state:SetAccent(color)
        if typeof(color) ~= "Color3" then
            return
        end

        Theme.Accent = color
        AccentLine.BackgroundColor3 = color
        Logo.BackgroundColor3 = color:Lerp(Color3.new(1, 1, 1), 0.88)
        LogoText.TextColor3 = color
        Launcher.BackgroundColor3 = color

        for _, tab in ipairs(state.Tabs) do
            tab.Indicator.BackgroundColor3 = color
        end
    end

    function state:Minimize()
        MinimizeWindow()
    end

    function state:Restore()
        RestoreWindow()
    end

    function state:Destroy()
        Destroy()
    end

    Main.BackgroundTransparency = 1
    MainScale.Scale = 0.9

    task.defer(function()
        Tween(Main, TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
            BackgroundTransparency = 0
        })

        AnimateScale(1, 0.25)
    end)

    return state
end

function Library:Destroy()
    DisconnectAll()

    for _, gui in ipairs(PlayerGui:GetChildren()) do
        if gui.Name:match("^QQLite_") then
            gui:Destroy()
        end
    end
end

return Library