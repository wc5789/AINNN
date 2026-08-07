-- ====================================================================
--  SciFi VapeV4 Style UI Library
--  Design: Sharp Edges, White-Blue Sci-Fi Glow, Ultra Smooth Tweens
--  Author: DeepSeek-Girl for Master
-- ====================================================================

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local CoreGui = game:GetService("CoreGui")

local SciFiLib = {}
SciFiLib.__index = SciFiLib

-- 全局科技感主题配色
local Theme = {
    Background = Color3.fromRGB(10, 13, 18),
    Header = Color3.fromRGB(15, 20, 28),
    Container = Color3.fromRGB(18, 24, 34),
    FolderHeader = Color3.fromRGB(22, 30, 42),
    ButtonUnactive = Color3.fromRGB(28, 38, 52),
    AccentBlue = Color3.fromRGB(0, 170, 255),
    GlowBlue = Color3.fromRGB(80, 210, 255),
    TextWhite = Color3.fromRGB(240, 245, 255),
    TextDark = Color3.fromRGB(140, 155, 175),
    BorderColor = Color3.fromRGB(35, 50, 70),
    BorderActive = Color3.fromRGB(0, 170, 255)
}

-- 平滑动画辅助函数
local function SmoothTween(instance, properties, duration, style, direction)
    style = style or Enum.EasingStyle.Quart
    direction = direction or Enum.EasingDirection.Out
    duration = duration or 0.35
    local tweenInfo = TweenInfo.new(duration, style, direction)
    local tween = TweenService:Create(instance, tweenInfo, properties)
    tween:Play()
    return tween
end

-- 可拖拽效果
local function MakeDraggable(gui, handle)
    local dragging, dragInput, dragStart, startPos
    handle = handle or gui
    
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = gui.Position
            
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then
                    dragging = false
                end
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
            SmoothTween(gui, {Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)}, 0.1, Enum.EasingStyle.Linear)
        end
    end)
end

-- ====================================================================
--  创建主窗口
-- ====================================================================
function SciFiLib:CreateWindow(titleText)
    local window = {}
    
    -- ScreenGui
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "SciFiVapeUI_" .. math.random(1000, 9999)
    screenGui.ResetOnSpawn = false
    
    -- 兼容不同执行环境的 Parent 挂载
    if gethui then
        screenGui.Parent = gethui()
    elseif syn and syn.protect_gui then
        syn.protect_gui(screenGui)
        screenGui.Parent = CoreGui
    else
        screenGui.Parent = CoreGui
    end

    -- 主悬浮框 (竖向 VapeV4 风格)
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, 320, 0, 520)
    mainFrame.Position = UDim2.new(0.5, -160, 0.5, -260)
    mainFrame.BackgroundColor3 = Theme.Background
    mainFrame.BorderSizePixel = 0
    mainFrame.ClipsDescendants = true
    mainFrame.Parent = screenGui
    
    -- 强制直角硬朗科技线条
    local mainBorder = Instance.new("UIStroke")
    mainBorder.Thickness = 1.5
    mainBorder.Color = Theme.BorderActive
    mainBorder.Transparency = 0.2
    mainBorder.Parent = mainFrame

    -- 顶部标题栏
    local headerFrame = Instance.new("Frame")
    headerFrame.Name = "Header"
    headerFrame.Size = UDim2.new(1, 0, 0, 45)
    headerFrame.BackgroundColor3 = Theme.Header
    headerFrame.BorderSizePixel = 0
    headerFrame.Parent = mainFrame

    local headerLine = Instance.new("Frame")
    headerLine.Size = UDim2.new(1, 0, 0, 2)
    headerLine.Position = UDim2.new(0, 0, 1, -2)
    headerLine.BackgroundColor3 = Theme.AccentBlue
    headerLine.BorderSizePixel = 0
    headerLine.Parent = headerFrame

    local titleLabel = Instance.new("TextLabel")
    titleLabel.Size = UDim2.new(1, -20, 1, 0)
    titleLabel.Position = UDim2.new(0, 15, 0, 0)
    titleLabel.Text = string.upper(titleText or "VAPE v4 SCI-FI")
    titleLabel.TextColor3 = Theme.TextWhite
    titleLabel.TextSize = 16
    titleLabel.Font = Enum.Font.GothamBold
    titleLabel.TextXAlignment = Enum.TextXAlignment.Left
    titleLabel.BackgroundTransparency = 1
    titleLabel.Parent = headerFrame

    -- 拖拽逻辑
    MakeDraggable(mainFrame, headerFrame)

    -- Tab 标签按钮栏 (Top/Side List)
    local tabContainer = Instance.new("Frame")
    tabContainer.Name = "TabContainer"
    tabContainer.Size = UDim2.new(1, -20, 0, 35)
    tabContainer.Position = UDim2.new(0, 10, 0, 50)
    tabContainer.BackgroundTransparency = 1
    tabContainer.Parent = mainFrame

    local tabLayout = Instance.new("UIListLayout")
    tabLayout.FillDirection = Enum.FillDirection.Horizontal
    tabLayout.SortOrder = Enum.SortOrder.LayoutOrder
    tabLayout.Padding = UDim.new(0, 6)
    tabLayout.Parent = tabContainer

    -- 主内容滚动区域
    local contentContainer = Instance.new("Frame")
    contentContainer.Name = "ContentContainer"
    contentContainer.Size = UDim2.new(1, -20, 1, -95)
    contentContainer.Position = UDim2.new(0, 10, 0, 90)
    contentContainer.BackgroundTransparency = 1
    contentContainer.Parent = mainFrame

    -- 电影级震撼打开动画
    mainFrame.Size = UDim2.new(0, 320, 0, 0)
    mainFrame.BackgroundTransparency = 0.5
    mainBorder.Transparency = 1
    SmoothTween(mainFrame, {Size = UDim2.new(0, 320, 0, 520), BackgroundTransparency = 0}, 0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
    SmoothTween(mainBorder, {Transparency = 0.2}, 0.8)

    window.Tabs = {}
    window.ActiveTab = nil

    -- ================================================================
    --  创建 Tab 标签
    -- ================================================================
    function window:CreateTab(tabName)
        local tab = {}
        
        -- Tab 切换按钮
        local tabBtn = Instance.new("TextButton")
        tabBtn.Name = tabName .. "_Tab"
        tabBtn.Size = UDim2.new(0, 90, 1, 0)
        tabBtn.BackgroundColor3 = Theme.Container
        tabBtn.Text = tabName
        tabBtn.TextColor3 = Theme.TextDark
        tabBtn.Font = Enum.Font.GothamBold
        tabBtn.TextSize = 12
        tabBtn.AutoButtonColor = false
        tabBtn.BorderSizePixel = 0
        tabBtn.Parent = tabContainer

        local tabBorder = Instance.new("UIStroke")
        tabBorder.Thickness = 1
        tabBorder.Color = Theme.BorderColor
        tabBorder.Parent = tabBtn

        -- 每一个 Tab 对应的 Page
        local page = Instance.new("ScrollingFrame")
        page.Name = tabName .. "_Page"
        page.Size = UDim2.new(1, 0, 1, 0)
        page.BackgroundTransparency = 1
        page.ScrollBarThickness = 3
        page.ScrollBarImageColor3 = Theme.AccentBlue
        page.Visible = false
        page.CanvasSize = UDim2.new(0, 0, 0, 0)
        page.AutomaticCanvasSize = Enum.AutomaticSize.Y
        page.Parent = contentContainer

        local pageLayout = Instance.new("UIListLayout")
        pageLayout.SortOrder = Enum.SortOrder.LayoutOrder
        pageLayout.Padding = UDim.new(0, 10)
        pageLayout.Parent = page

        local pagePadding = Instance.new("UIPadding")
        pagePadding.PaddingRight = UDim.new(0, 4)
        pagePadding.Parent = page

        -- 激活 Tab 逻辑
        local function ActivateTab()
            for _, t in pairs(window.Tabs) do
                t.Page.Visible = false
                SmoothTween(t.Button, {BackgroundColor3 = Theme.Container, TextColor3 = Theme.TextDark}, 0.2)
                t.Border.Color = Theme.BorderColor
            end
            page.Visible = true
            SmoothTween(tabBtn, {BackgroundColor3 = Theme.FolderHeader, TextColor3 = Theme.GlowBlue}, 0.2)
            tabBorder.Color = Theme.AccentBlue
            window.ActiveTab = tab
        end

        tabBtn.MouseButton1Click:Connect(ActivateTab)

        -- 悬停动画
        tabBtn.MouseEnter:Connect(function()
            if window.ActiveTab ~= tab then
                SmoothTween(tabBtn, {TextColor3 = Theme.TextWhite}, 0.2)
            end
        end)
        tabBtn.MouseLeave:Connect(function()
            if window.ActiveTab ~= tab then
                SmoothTween(tabBtn, {TextColor3 = Theme.TextDark}, 0.2)
            end
        end)

        tab.Button = tabBtn
        tab.Border = tabBorder
        tab.Page = page

        -- 如果是第一个 Tab，默认激活
        if #window.Tabs == 0 then
            ActivateTab()
        end
        table.insert(window.Tabs, tab)

        -- ============================================================
        --  创建折叠菜单 (Folder / Category)
        -- ============================================================
        function tab:CreateFolder(folderName)
            local folder = {}
            local expanded = true

            local folderFrame = Instance.new("Frame")
            folderFrame.Name = folderName .. "_Folder"
            folderFrame.Size = UDim2.new(1, 0, 0, 36) -- 动态伸缩高度
            folderFrame.BackgroundColor3 = Theme.Container
            folderFrame.ClipsDescendants = true
            folderFrame.BorderSizePixel = 0
            folderFrame.Parent = page

            local folderStroke = Instance.new("UIStroke")
            folderStroke.Thickness = 1
            folderStroke.Color = Theme.BorderColor
            folderStroke.Parent = folderFrame

            -- 折叠菜单头部
            local folderHeader = Instance.new("TextButton")
            folderHeader.Size = UDim2.new(1, 0, 0, 36)
            folderHeader.BackgroundColor3 = Theme.FolderHeader
            folderHeader.Text = ""
            folderHeader.AutoButtonColor = false
            folderHeader.BorderSizePixel = 0
            folderHeader.Parent = folderFrame

            local folderTitle = Instance.new("TextLabel")
            folderTitle.Size = UDim2.new(1, -40, 1, 0)
            folderTitle.Position = UDim2.new(0, 12, 0, 0)
            folderTitle.Text = "📂  " .. folderName
            folderTitle.TextColor3 = Theme.TextWhite
            folderTitle.Font = Enum.Font.GothamBold
            folderTitle.TextSize = 13
            folderTitle.TextXAlignment = Enum.TextXAlignment.Left
            folderTitle.BackgroundTransparency = 1
            folderTitle.Parent = folderHeader

            local arrowLabel = Instance.new("TextLabel")
            arrowLabel.Size = UDim2.new(0, 30, 1, 0)
            arrowLabel.Position = UDim2.new(1, -30, 0, 0)
            arrowLabel.Text = "▼"
            arrowLabel.TextColor3 = Theme.AccentBlue
            arrowLabel.Font = Enum.Font.GothamBold
            arrowLabel.TextSize = 11
            arrowLabel.BackgroundTransparency = 1
            arrowLabel.Parent = folderHeader

            -- 内部功能容器
            local itemList = Instance.new("Frame")
            itemList.Name = "ItemList"
            itemList.Size = UDim2.new(1, -16, 0, 0)
            itemList.Position = UDim2.new(0, 8, 0, 40)
            itemList.BackgroundTransparency = 1
            itemList.Parent = folderFrame

            local itemLayout = Instance.new("UIListLayout")
            itemLayout.SortOrder = Enum.SortOrder.LayoutOrder
            itemLayout.Padding = UDim.new(0, 8)
            itemLayout.Parent = itemList

            -- 自动计算文件夹展开高度
            local function UpdateFolderSize()
                if expanded then
                    local contentHeight = itemLayout.AbsoluteContentSize.Y + 48
                    SmoothTween(folderFrame, {Size = UDim2.new(1, 0, 0, contentHeight)}, 0.3)
                    SmoothTween(arrowLabel, {Rotation = 0}, 0.3)
                else
                    SmoothTween(folderFrame, {Size = UDim2.new(1, 0, 0, 36)}, 0.3)
                    SmoothTween(arrowLabel, {Rotation = -90}, 0.3)
                end
            end

            itemLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                if expanded then UpdateFolderSize() end
            end)

            folderHeader.MouseButton1Click:Connect(function()
                expanded = not expanded
                UpdateFolderSize()
            end)

            -- ========================================================
            --  创建功能模块 Button (支持点击 + 右侧“三个点”高级详细折叠配置)
            -- ========================================================
            function folder:CreateModule(modOptions)
                local modName = modOptions.Name or "Feature"
                local callback = modOptions.Callback or function() end

                local module = { Toggled = false }

                local modFrame = Instance.new("Frame")
                modFrame.Name = modName .. "_Module"
                modFrame.Size = UDim2.new(1, 0, 0, 32)
                modFrame.BackgroundColor3 = Theme.ButtonUnactive
                modFrame.ClipsDescendants = true
                modFrame.BorderSizePixel = 0
                modFrame.Parent = itemList

                local modStroke = Instance.new("UIStroke")
                modStroke.Thickness = 1
                modStroke.Color = Theme.BorderColor
                modStroke.Parent = modFrame

                -- 功能触发主按钮
                local modBtn = Instance.new("TextButton")
                modBtn.Size = UDim2.new(1, -35, 0, 32)
                modBtn.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
                modBtn.BackgroundTransparency = 1
                modBtn.Text = "  " .. modName
                modBtn.TextColor3 = Theme.TextDark
                modBtn.Font = Enum.Font.GothamMedium
                modBtn.TextSize = 12
                modBtn.TextXAlignment = Enum.TextXAlignment.Left
                modBtn.Parent = modFrame

                -- 右侧“三个点”按钮 (...) 打开详细参数菜单
                local moreBtn = Instance.new("TextButton")
                moreBtn.Size = UDim2.new(0, 30, 0, 32)
                moreBtn.Position = UDim2.new(1, -30, 0, 0)
                moreBtn.Text = "•••"
                moreBtn.TextColor3 = Theme.TextDark
                moreBtn.Font = Enum.Font.GothamBold
                moreBtn.TextSize = 12
                moreBtn.BackgroundTransparency = 1
                moreBtn.Parent = modFrame

                -- 三个点展开后的详细子配置容器
                local subConfigFrame = Instance.new("Frame")
                subConfigFrame.Size = UDim2.new(1, -12, 0, 0)
                subConfigFrame.Position = UDim2.new(0, 6, 0, 36)
                subConfigFrame.BackgroundTransparency = 1
                subConfigFrame.Parent = modFrame

                local subLayout = Instance.new("UIListLayout")
                subLayout.SortOrder = Enum.SortOrder.LayoutOrder
                subLayout.Padding = UDim.new(0, 6)
                subLayout.Parent = subConfigFrame

                local detailsExpanded = false

                local function UpdateModuleHeight()
                    if detailsExpanded then
                        local totalH = subLayout.AbsoluteContentSize.Y + 44
                        SmoothTween(modFrame, {Size = UDim2.new(1, 0, 0, totalH)}, 0.3)
                    else
                        SmoothTween(modFrame, {Size = UDim2.new(1, 0, 0, 32)}, 0.3)
                    end
                    task.wait(0.1)
                    UpdateFolderSize()
                end

                subLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
                    if detailsExpanded then UpdateModuleHeight() end
                end)

                -- 切换 Module 激活状态逻辑
                local function ToggleModule()
                    module.Toggled = not module.Toggled
                    if module.Toggled then
                        SmoothTween(modFrame, {BackgroundColor3 = Color3.fromRGB(15, 45, 70)}, 0.25)
                        SmoothTween(modBtn, {TextColor3 = Theme.TextWhite}, 0.25)
                        modStroke.Color = Theme.AccentBlue
                    else
                        SmoothTween(modFrame, {BackgroundColor3 = Theme.ButtonUnactive}, 0.25)
                        SmoothTween(modBtn, {TextColor3 = Theme.TextDark}, 0.25)
                        modStroke.Color = Theme.BorderColor
                    end
                    callback(module.Toggled)
                end

                modBtn.MouseButton1Click:Connect(ToggleModule)

                -- 点击“三个点”展开/折叠详细配置
                moreBtn.MouseButton1Click:Connect(function()
                    detailsExpanded = not detailsExpanded
                    SmoothTween(moreBtn, {TextColor3 = detailsExpanded and Theme.GlowBlue or Theme.TextDark}, 0.2)
                    UpdateModuleHeight()
                end)

                -- ----------------------------------------------------
                --  子配置 1: Slider (拉条)
                -- ----------------------------------------------------
                function module:AddSlider(sName, min, max, default, sCallback)
                    sCallback = sCallback or function() end
                    local val = default or min

                    local sliderFrame = Instance.new("Frame")
                    sliderFrame.Size = UDim2.new(1, 0, 0, 38)
                    sliderFrame.BackgroundColor3 = Theme.Container
                    sliderFrame.BorderSizePixel = 0
                    sliderFrame.Parent = subConfigFrame

                    local sLabel = Instance.new("TextLabel")
                    sLabel.Size = UDim2.new(1, -50, 0, 18)
                    sLabel.Position = UDim2.new(0, 6, 0, 2)
                    sLabel.Text = sName
                    sLabel.TextColor3 = Theme.TextWhite
                    sLabel.Font = Enum.Font.Gotham
                    sLabel.TextSize = 11
                    sLabel.TextXAlignment = Enum.TextXAlignment.Left
                    sLabel.BackgroundTransparency = 1
                    sLabel.Parent = sliderFrame

                    local valLabel = Instance.new("TextLabel")
                    valLabel.Size = UDim2.new(0, 40, 0, 18)
                    valLabel.Position = UDim2.new(1, -44, 0, 2)
                    valLabel.Text = tostring(val)
                    valLabel.TextColor3 = Theme.GlowBlue
                    valLabel.Font = Enum.Font.GothamBold
                    valLabel.TextSize = 11
                    valLabel.TextXAlignment = Enum.TextXAlignment.Right
                    valLabel.BackgroundTransparency = 1
                    valLabel.Parent = sliderFrame

                    local sliderBar = Instance.new("Frame")
                    sliderBar.Size = UDim2.new(1, -12, 0, 6)
                    sliderBar.Position = UDim2.new(0, 6, 0, 24)
                    sliderBar.BackgroundColor3 = Color3.fromRGB(30, 40, 55)
                    sliderBar.BorderSizePixel = 0
                    sliderBar.Parent = sliderFrame

                    local fill = Instance.new("Frame")
                    fill.Size = UDim2.new((val - min)/(max - min), 0, 1, 0)
                    fill.BackgroundColor3 = Theme.AccentBlue
                    fill.BorderSizePixel = 0
                    fill.Parent = sliderBar

                    local dragging = false

                    local function UpdateSlider(input)
                        local pos = math.clamp((input.Position.X - sliderBar.AbsolutePosition.X) / sliderBar.AbsoluteSize.X, 0, 1)
                        local currentVal = math.floor(min + (max - min) * pos)
                        valLabel.Text = tostring(currentVal)
                        SmoothTween(fill, {Size = UDim2.new(pos, 0, 1, 0)}, 0.05)
                        sCallback(currentVal)
                    end

                    sliderBar.InputBegan:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            dragging = true
                            UpdateSlider(input)
                        end
                    end)

                    UserInputService.InputEnded:Connect(function(input)
                        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                            dragging = false
                        end
                    end)

                    UserInputService.InputChanged:Connect(function(input)
                        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
                            UpdateSlider(input)
                        end
                    end)
                end

                -- ----------------------------------------------------
                --  子配置 2: TextBox (文本输入框)
                -- ----------------------------------------------------
                function module:AddTextBox(boxName, placeholder, tCallback)
                    tCallback = tCallback or function() end

                    local boxFrame = Instance.new("Frame")
                    boxFrame.Size = UDim2.new(1, 0, 0, 32)
                    boxFrame.BackgroundColor3 = Theme.Container
                    boxFrame.BorderSizePixel = 0
                    boxFrame.Parent = subConfigFrame

                    local tLabel = Instance.new("TextLabel")
                    tLabel.Size = UDim2.new(0.5, 0, 1, 0)
                    tLabel.Position = UDim2.new(0, 6, 0, 0)
                    tLabel.Text = boxName
                    tLabel.TextColor3 = Theme.TextWhite
                    tLabel.Font = Enum.Font.Gotham
                    tLabel.TextSize = 11
                    tLabel.TextXAlignment = Enum.TextXAlignment.Left
                    tLabel.BackgroundTransparency = 1
                    tLabel.Parent = boxFrame

                    local textBox = Instance.new("TextBox")
                    textBox.Size = UDim2.new(0.45, 0, 0.7, 0)
                    textBox.Position = UDim2.new(0.52, 0, 0.15, 0)
                    textBox.BackgroundColor3 = Theme.ButtonUnactive
                    textBox.Text = ""
                    textBox.PlaceholderText = placeholder or "输入..."
                    textBox.TextColor3 = Theme.GlowBlue
                    textBox.PlaceholderColor3 = Theme.TextDark
                    textBox.Font = Enum.Font.Gotham
                    textBox.TextSize = 11
                    textBox.BorderSizePixel = 0
                    textBox.Parent = boxFrame

                    local boxStroke = Instance.new("UIStroke")
                    boxStroke.Thickness = 1
                    boxStroke.Color = Theme.BorderColor
                    boxStroke.Parent = textBox

                    textBox.FocusLost:Connect(function(enterPressed)
                        tCallback(textBox.Text, enterPressed)
                    end)
                end

                -- ----------------------------------------------------
                --  子配置 3: Sub-Toggle (子参数开关)
                -- ----------------------------------------------------
                function module:AddToggle(togName, default, togCallback)
                    togCallback = togCallback or function() end
                    local state = default or false

                    local togFrame = Instance.new("Frame")
                    togFrame.Size = UDim2.new(1, 0, 0, 28)
                    togFrame.BackgroundColor3 = Theme.Container
                    togFrame.BorderSizePixel = 0
                    togFrame.Parent = subConfigFrame

                    local togBtn = Instance.new("TextButton")
                    togBtn.Size = UDim2.new(1, 0, 1, 0)
                    togBtn.BackgroundTransparency = 1
                    togBtn.Text = ""
                    togBtn.Parent = togFrame

                    local togLabel = Instance.new("TextLabel")
                    togLabel.Size = UDim2.new(1, -40, 1, 0)
                    togLabel.Position = UDim2.new(0, 6, 0, 0)
                    togLabel.Text = togName
                    togLabel.TextColor3 = Theme.TextWhite
                    togLabel.Font = Enum.Font.Gotham
                    togLabel.TextSize = 11
                    togLabel.TextXAlignment = Enum.TextXAlignment.Left
                    togLabel.BackgroundTransparency = 1
                    togLabel.Parent = togFrame

                    local indicator = Instance.new("Frame")
                    indicator.Size = UDim2.new(0, 14, 0, 14)
                    indicator.Position = UDim2.new(1, -20, 0.5, -7)
                    indicator.BackgroundColor3 = state and Theme.AccentBlue or Theme.ButtonUnactive
                    indicator.BorderSizePixel = 0
                    indicator.Parent = togFrame

                    local indStroke = Instance.new("UIStroke")
                    indStroke.Thickness = 1
                    indStroke.Color = state and Theme.GlowBlue or Theme.BorderColor
                    indStroke.Parent = indicator

                    togBtn.MouseButton1Click:Connect(function()
                        state = not state
                        if state then
                            SmoothTween(indicator, {BackgroundColor3 = Theme.AccentBlue}, 0.2)
                            indStroke.Color = Theme.GlowBlue
                        else
                            SmoothTween(indicator, {BackgroundColor3 = Theme.ButtonUnactive}, 0.2)
                            indStroke.Color = Theme.BorderColor
                        end
                        togCallback(state)
                    end)
                end

                return module
            end

            return folder
        end

        return tab
    end

    return window
end

return SciFiLib