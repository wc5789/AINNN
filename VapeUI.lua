--[[
	VapeUI — Modernized Vape Lite Style UI Library (2026 Refresh)
	Backward compatible with original library API.
]]
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local Mouse = LocalPlayer:GetMouse()

-- Theme System
local Theme = {
	Background = Color3.fromRGB(13, 13, 15),
	Panel = Color3.fromRGB(21, 21, 23),
	Secondary = Color3.fromRGB(24, 24, 28),
	Tertiary = Color3.fromRGB(29, 29, 34),
	Hover = Color3.fromRGB(34, 34, 40),
	Accent = Color3.fromRGB(22, 131, 255),
	Text = Color3.fromRGB(225, 225, 228),
	TextSecondary = Color3.fromRGB(140, 140, 145),
	TextDisabled = Color3.fromRGB(76, 76, 82),
	Border = Color3.fromRGB(42, 42, 48),
	ToggleOff = Color3.fromRGB(52, 52, 58),
	Scroll = Color3.fromRGB(52, 52, 58),
}

-- Animation presets
local Ease = {
	Hover = TweenInfo.new(0.1, Enum.EasingStyle.Linear, Enum.EasingDirection.Out),
	Fast = TweenInfo.new(0.12, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Normal = TweenInfo.new(0.18, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
	Slow = TweenInfo.new(0.3, Enum.EasingStyle.Quart, Enum.EasingDirection.Out),
	Fade = TweenInfo.new(0.15, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
}

local function Create(class, props)
	local inst = Instance.new(class)
	for k, v in pairs(props) do
		inst[k] = v
	end
	return inst
end

local function Stroke(parent, t)
	return Create("UIStroke", {
		Parent = parent,
		Color = Theme.Border,
		Thickness = 1,
		Transparency = t or 0.4,
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
	})
end

local function Corner(parent, r)
	return Create("UICorner", { Parent = parent, CornerRadius = UDim.new(0, r or 2) })
end

-- Modern draggable
local function MakeDraggable(topbar, target)
	local dragging, dragInput, dragStart, startPos
	local function update(input)
		local delta = input.Position - dragStart
		target.Position = UDim2.new(
			startPos.X.Scale, startPos.X.Offset + delta.X,
			startPos.Y.Scale, startPos.Y.Offset + delta.Y
		)
	end
	topbar.InputBegan:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
			dragging = true
			dragStart = input.Position
			startPos = target.Position
			input.Changed:Connect(function()
				if input.UserInputState == Enum.UserInputState.End then
					dragging = false
				end
			end)
		end
	end)
	topbar.InputChanged:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
			dragInput = input
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if input == dragInput and dragging then
			update(input)
		end
	end)
end

-- Library object
local lib = {}

-- ============================================================
-- WINDOW
-- ============================================================
function lib:Window(text, preset, closebind)
	local accent = preset or Theme.Accent
	local closeKey = closebind or Enum.KeyCode.RightControl
	local sub = {}

	local gui = Create("ScreenGui", {
		Name = "VapeUI",
		Parent = game.CoreGui,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ResetOnSpawn = false,
	})

	-- Root
	local root = Create("Frame", {
		Name = "Root",
		Parent = gui,
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = Theme.Background,
		BorderSizePixel = 0,
		Position = UDim2.new(0.5, 0, 0.5, 0),
		Size = UDim2.new(0, 0, 0, 0),
		ClipsDescendants = true,
		Visible = true,
	})
	Stroke(root, 0.1)

	-- Header (drag area + title)
	local header = Create("Frame", {
		Parent = root, Name = "Header",
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		Size = UDim2.new(1, 0, 0, 26),
		ZIndex = 5,
	})
	Stroke(header, 0.3)

	Create("TextLabel", {
		Parent = header, Name = "Title",
		BackgroundTransparency = 1,
		Position = UDim2.new(0, 10, 0, 0),
		Size = UDim2.new(1, -20, 1, 0),
		Font = Enum.Font.GothamSemibold,
		Text = text,
		TextColor3 = Theme.Text,
		TextSize = 11,
		TextXAlignment = Enum.TextXAlignment.Left,
	})

	local drag = Create("Frame", {
		Parent = root, Name = "DragFrame",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 26),
		ZIndex = 6,
	})
	MakeDraggable(drag, root)

	-- Sidebar
	local sidebar = Create("Frame", {
		Parent = root, Name = "Sidebar",
		BackgroundColor3 = Theme.Panel,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 0, 0, 26),
		Size = UDim2.new(0, 104, 1, -26),
	})
	Stroke(sidebar, 0.3)

	local sidebarLayout = Create("UIListLayout", {
		Parent = sidebar,
		Padding = UDim.new(0, 2),
		SortOrder = Enum.SortOrder.LayoutOrder,
	})
	Create("UIPadding", {
		Parent = sidebar,
		PaddingTop = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 0),
	})

	local tabFolder = Create("Folder", { Parent = root, Name = "TabFolder" })

	-- Content area
	local content = Create("Frame", {
		Parent = root, Name = "Content",
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		Position = UDim2.new(0, 104, 0, 26),
		Size = UDim2.new(1, -104, 1, -26),
	})
	Create("UIPadding", {
		Parent = content,
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
	})

	-- Open animation
	root:TweenSize(UDim2.new(0, 560, 0, 320), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.45, true)

	-- Close binding
	local hidden = false
	UserInputService.InputBegan:Connect(function(input, gameProcessed)
		if gameProcessed then return end
		if input.KeyCode == closeKey then
			hidden = not hidden
			if hidden then
				root:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.35, true, function()
					gui.Enabled = false
				end)
			else
				gui.Enabled = true
				root:TweenSize(UDim2.new(0, 560, 0, 320), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.35, true)
			end
		end
	end)

	function sub:ChangePresetColor(newColor)
		accent = newColor or accent
	end

	-- ============================================================
	-- NOTIFICATION
	-- ============================================================
	function sub:Notification(texttitle, textdesc, textbtn)
		local overlay = Create("TextButton", {
			Parent = root, Name = "Overlay",
			BackgroundColor3 = Color3.new(0, 0, 0),
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			AutoButtonColor = false,
			Text = "",
			ZIndex = 50,
		})

		local box = Create("Frame", {
			Parent = overlay, Name = "Box",
			AnchorPoint = Vector2.new(0.5, 0.5),
			BackgroundColor3 = Theme.Panel,
			BorderSizePixel = 0,
			Position = UDim2.new(0.5, 0, 0.5, 0),
			Size = UDim2.new(0, 0, 0, 0),
			ClipsDescendants = true,
			ZIndex = 51,
		})
		Stroke(box, 0.1)

		Create("TextLabel", {
			Parent = box, Name = "NotifTitle",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 12, 0, 11),
			Size = UDim2.new(1, -24, 0, 18),
			Font = Enum.Font.GothamSemibold,
			Text = texttitle,
			TextColor3 = Theme.Text,
			TextSize = 13,
			TextXAlignment = Enum.TextXAlignment.Left,
		})

		Create("TextLabel", {
			Parent = box, Name = "NotifDesc",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 12, 0, 33),
			Size = UDim2.new(1, -24, 0, 40),
			Font = Enum.Font.Gotham,
			Text = textdesc or "",
			TextColor3 = Theme.TextSecondary,
			TextSize = 11,
			TextWrapped = true,
			TextXAlignment = Enum.TextXAlignment.Left,
			TextYAlignment = Enum.TextYAlignment.Top,
		})

		local ok = Create("TextButton", {
			Parent = box, Name = "OkBtn",
			BackgroundColor3 = Theme.Tertiary,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 12, 0, 80),
			Size = UDim2.new(1, -24, 0, 26),
			AutoButtonColor = false,
			Font = Enum.Font.Gotham,
			Text = textbtn or "OK",
			TextColor3 = Theme.Text,
			TextSize = 11,
			ZIndex = 52,
		})
		Corner(ok, 2)

		ok.MouseEnter:Connect(function() TweenService:Create(ok, Ease.Hover, { BackgroundColor3 = Theme.Hover }):Play() end)
		ok.MouseLeave:Connect(function() TweenService:Create(ok, Ease.Hover, { BackgroundColor3 = Theme.Tertiary }):Play() end)
		ok.MouseButton1Click:Connect(function()
			box:TweenSize(UDim2.new(0, 0, 0, 0), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.22, true)
			TweenService:Create(overlay, Ease.Fade, { BackgroundTransparency = 1 }):Play()
			task.delay(0.25, function() overlay:Destroy() end)
		end)

		TweenService:Create(overlay, Ease.Fade, { BackgroundTransparency = 0.5 }):Play()
		box:TweenSize(UDim2.new(0, 220, 0, 114), Enum.EasingDirection.Out, Enum.EasingStyle.Quart, 0.35, true)
	end

	-- ============================================================
	-- TAB
	-- ============================================================
	local tabHold = {}
	local firstTab = true

	function tabHold:Tab(text)
		local btn = Create("TextButton", {
			Parent = sidebar, Name = "TabBtn",
			BackgroundTransparency = 1,
			Size = UDim2.new(1, 0, 0, 24),
			AutoButtonColor = false,
			Font = Enum.Font.SourceSans,
			Text = "",
		})

		local title = Create("TextLabel", {
			Parent = btn, Name = "TabTitle",
			BackgroundTransparency = 1,
			Position = UDim2.new(0, 10, 0, 0),
			Size = UDim2.new(1, -14, 1, 0),
			Font = Enum.Font.Gotham,
			Text = text,
			TextColor3 = Theme.TextSecondary,
			TextSize = 12,
			TextXAlignment = Enum.TextXAlignment.Left,
		})

		local indicator = Create("Frame", {
			Parent = btn, Name = "TabIndicator",
			BackgroundColor3 = accent,
			BorderSizePixel = 0,
			Position = UDim2.new(0, 0, 0, 0),
			Size = UDim2.new(0, 0, 1, 0),
		})

		local tab = Create("ScrollingFrame", {
			Parent = tabFolder, Name = "Tab",
			Active = true,
			BackgroundTransparency = 1,
			BorderSizePixel = 0,
			Size = UDim2.new(1, 0, 1, 0),
			CanvasSize = UDim2.new(0, 0, 0, 0),
			ScrollBarThickness = 2,
			ScrollBarImageColor3 = Theme.Scroll,
			Visible = false,
		})

		local layout = Create("UIListLayout", {
			Parent = tab,
			Padding = UDim.new(0, 4),
			SortOrder = Enum.SortOrder.LayoutOrder,
		})

		layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
			tab.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 4)
		end)

		local function setActive()
			for _, child in pairs(tabFolder:GetChildren()) do
				if child:IsA("ScrollingFrame") then
					child.Visible = false
				end
			end
			for _, child in pairs(sidebar:GetChildren()) do
				if child:IsA("TextButton") and child.Name == "TabBtn" then
					local ind = child:FindFirstChild("TabIndicator")
					local ttl = child:FindFirstChild("TabTitle")
					if ind then TweenService:Create(ind, Ease.Fast, { Size = UDim2.new(0, 0, 1, 0) }):Play() end
					if ttl then TweenService:Create(ttl, Ease.Fast, { TextColor3 = Theme.TextSecondary }):Play() end
				end
			end
			tab.Visible = true
			TweenService:Create(indicator, Ease.Fast, { Size = UDim2.new(0, 2, 1, 0) }):Play()
			TweenService:Create(title, Ease.Fast, { TextColor3 = Theme.Text }):Play()
			tab.BackgroundTransparency = 0.15
			TweenService:Create(tab, Ease.Fade, { BackgroundTransparency = 1 }):Play()
		end

		btn.MouseButton1Click:Connect(setActive)

		if firstTab then
			firstTab = false
			indicator.Size = UDim2.new(0, 2, 1, 0)
			title.TextColor3 = Theme.Text
			tab.Visible = true
		end

		local tabContent = {}

		-- Button
		function tabContent:Button(text, callback)
			local b = Create("TextButton", {
				Parent = tab, Name = "Button",
				BackgroundColor3 = Theme.Secondary,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 28),
				AutoButtonColor = false,
				Font = Enum.Font.SourceSans,
				Text = "",
			})
			Corner(b, 2)

			Create("TextLabel", {
				Parent = b, Name = "ButtonTitle",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 0),
				Size = UDim2.new(1, -10, 1, 0),
				Font = Enum.Font.Gotham,
				Text = text,
				TextColor3 = Theme.Text,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
			})

			Create("TextLabel", {
				Parent = b, Name = "Arrow",
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -18, 0, 0),
				Size = UDim2.new(0, 14, 1, 0),
				Font = Enum.Font.Gotham,
				Text = ">",
				TextColor3 = Theme.TextDisabled,
				TextSize = 11,
			})

			b.MouseEnter:Connect(function() TweenService:Create(b, Ease.Hover, { BackgroundColor3 = Theme.Tertiary }):Play() end)
			b.MouseLeave:Connect(function() TweenService:Create(b, Ease.Hover, { BackgroundColor3 = Theme.Secondary }):Play() end)
			b.MouseButton1Click:Connect(function()
				pcall(callback)
			end)
		end

		-- Toggle
		function tabContent:Toggle(text, default, callback)
			local toggled = default or false

			local t = Create("TextButton", {
				Parent = tab, Name = "Toggle",
				BackgroundColor3 = Theme.Secondary,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 26),
				AutoButtonColor = false,
				Font = Enum.Font.SourceSans,
				Text = "",
			})
			Corner(t, 2)

			local tTitle = Create("TextLabel", {
				Parent = t, Name = "ToggleTitle",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 0),
				Size = UDim2.new(1, -56, 1, 0),
				Font = Enum.Font.Gotham,
				Text = text,
				TextColor3 = Theme.Text,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
			})

			-- Switch pieces
			local track = Create("Frame", {
				Parent = t, Name = "SwitchTrack",
				BackgroundColor3 = Theme.ToggleOff,
				BorderSizePixel = 0,
				Position = UDim2.new(1, -42, 0.5, -6),
				Size = UDim2.new(0, 30, 0, 12),
			})
			Corner(track, 6)

			local fill = Create("Frame", {
				Parent = track, Name = "SwitchFill",
				BackgroundColor3 = accent,
				BackgroundTransparency = 1,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 1, 0),
			})
			Corner(fill, 6)

			local thumb = Create("Frame", {
				Parent = track, Name = "SwitchThumb",
				BackgroundColor3 = Theme.ToggleOff,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 2, 0.5, -4),
				Size = UDim2.new(0, 8, 0, 8),
			})
			Corner(thumb, 4)

			local function setState(state)
				local info = Ease.Fast
				if state then
					TweenService:Create(fill, info, { BackgroundTransparency = 0 }):Play()
					TweenService:Create(thumb, info, { Position = UDim2.new(1, -10, 0.5, -4), BackgroundColor3 = Color3.new(1, 1, 1) }):Play()
					TweenService:Create(track, info, { BackgroundTransparency = 1 }):Play()
				else
					TweenService:Create(fill, info, { BackgroundTransparency = 1 }):Play()
					TweenService:Create(thumb, info, { Position = UDim2.new(0, 2, 0.5, -4), BackgroundColor3 = Theme.ToggleOff }):Play()
					TweenService:Create(track, info, { BackgroundTransparency = 0 }):Play()
				end
			end

			setState(toggled)

			t.MouseEnter:Connect(function() TweenService:Create(t, Ease.Hover, { BackgroundColor3 = Theme.Tertiary }):Play() end)
			t.MouseLeave:Connect(function() TweenService:Create(t, Ease.Hover, { BackgroundColor3 = Theme.Secondary }):Play() end)

			t.MouseButton1Click:Connect(function()
				toggled = not toggled
				setState(toggled)
				pcall(callback, toggled)
			end)
		end

		-- Slider
		function tabContent:Slider(text, min, max, start, callback)
			min = min or 0
			max = max or 100
			start = start or 0
			local value = start
			local dragging = false

			local s = Create("TextButton", {
				Parent = tab, Name = "Slider",
				BackgroundColor3 = Theme.Secondary,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 34),
				AutoButtonColor = false,
				Font = Enum.Font.SourceSans,
				Text = "",
			})
			Corner(s, 2)

			local sTitle = Create("TextLabel", {
				Parent = s, Name = "SliderTitle",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 0),
				Size = UDim2.new(1, -60, 0, 18),
				Font = Enum.Font.Gotham,
				Text = text,
				TextColor3 = Theme.Text,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
			})

			local valueLabel = Create("TextLabel", {
				Parent = s, Name = "SliderValue",
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -50, 0, 0),
				Size = UDim2.new(0, 44, 0, 18),
				Font = Enum.Font.Gotham,
				Text = tostring(start),
				TextColor3 = Theme.TextSecondary,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Right,
			})

			local track = Create("Frame", {
				Parent = s, Name = "Track",
				BackgroundColor3 = Theme.ToggleOff,
				BorderSizePixel = 0,
				Position = UDim2.new(0, 10, 0, 22),
				Size = UDim2.new(1, -20, 0, 2),
			})

			local fill = Create("Frame", {
				Parent = track, Name = "Fill",
				BackgroundColor3 = accent,
				BorderSizePixel = 0,
				Size = UDim2.new(start / max, 0, 1, 0),
			})

			local thumb = Create("ImageButton", {
				Parent = track, Name = "Thumb",
				BackgroundTransparency = 1,
				Position = UDim2.new(start / max, -5, -4, 0),
				Size = UDim2.new(0, 10, 0, 10),
				Image = "rbxassetid://3570695787",
				ImageColor3 = accent,
			})

			local function update(input)
				local relX = input.Position.X - track.AbsolutePosition.X
				local ratio = math.clamp(relX / track.AbsoluteSize.X, 0, 1)
				value = math.floor(min + (max - min) * ratio)
				local r2 = (value - min) / (max - min)
				fill.Size = UDim2.new(r2, 0, 1, 0)
				thumb.Position = UDim2.new(r2, -5, -4, 0)
				valueLabel.Text = tostring(value)
				pcall(callback, value)
			end

			thumb.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					update(input)
				end
			end)
			thumb.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)
			s.InputBegan:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = true
					update(input)
				end
			end)
			s.InputEnded:Connect(function(input)
				if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
					dragging = false
				end
			end)
			UserInputService.InputChanged:Connect(function(input)
				if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
					update(input)
				end
			end)

			s.MouseEnter:Connect(function() TweenService:Create(s, Ease.Hover, { BackgroundColor3 = Theme.Tertiary }):Play() end)
			s.MouseLeave:Connect(function() TweenService:Create(s, Ease.Hover, { BackgroundColor3 = Theme.Secondary }):Play() end)
		end

		-- Dropdown
		function tabContent:Dropdown(text, list, callback)
			local open = false
			local selected = list and list[1] or ""

			local d = Create("TextButton", {
				Parent = tab, Name = "Dropdown",
				BackgroundColor3 = Theme.Secondary,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 26),
				AutoButtonColor = false,
				Font = Enum.Font.SourceSans,
				Text = "",
			})
			Corner(d, 2)

			local dTitle = Create("TextLabel", {
				Parent = d, Name = "DropdownTitle",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 0),
				Size = UDim2.new(1, -72, 1, 0),
				Font = Enum.Font.Gotham,
				Text = text,
				TextColor3 = Theme.Text,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
			})

			local dValue = Create("TextLabel", {
				Parent = d, Name = "DropdownValue",
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -70, 0, 0),
				Size = UDim2.new(0, 60, 1, 0),
				Font = Enum.Font.Gotham,
				Text = selected,
				TextColor3 = Theme.TextSecondary,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Right,
			})

			local chevron = Create("TextLabel", {
				Parent = d, Name = "Chevron",
				BackgroundTransparency = 1,
				Position = UDim2.new(1, -16, 0, 0),
				Size = UDim2.new(0, 12, 1, 0),
				Font = Enum.Font.Gotham,
				Text = "+",
				TextColor3 = Theme.TextDisabled,
				TextSize = 11,
			})

			-- Dropdown panel
			local panel = Create("Frame", {
				Parent = tab, Name = "DropdownPanel",
				BackgroundColor3 = Theme.Panel,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 0),
				ClipsDescendants = true,
				Visible = false,
				LayoutOrder = 999,
			})
			Stroke(panel, 0.2)

			local panelLayout = Create("UIListLayout", {
				Parent = panel,
				Padding = UDim.new(0, 1),
				SortOrder = Enum.SortOrder.LayoutOrder,
			})

			local function refreshPanelPos()
				-- Place panel right below the dropdown in the tab's list
				panel.LayoutOrder = d.LayoutOrder + 1
			end

			local function closePanel()
				open = false
				panel.Visible = false
				chevron.Text = "+"
			end

			local function openPanel()
				open = true
				panel.Visible = true
				chevron.Text = "-"
				refreshPanelPos()
			end

			for _, option in ipairs(list) do
				local opt = Create("TextButton", {
					Parent = panel, Name = "Option",
					BackgroundColor3 = Color3.new(1, 1, 1),
					BackgroundTransparency = 1,
					Size = UDim2.new(1, 0, 0, 22),
					AutoButtonColor = false,
					Font = Enum.Font.SourceSans,
					Text = "",
				})

				Create("TextLabel", {
					Parent = opt, Name = "OptLabel",
					BackgroundTransparency = 1,
					Position = UDim2.new(0, 10, 0, 0),
					Size = UDim2.new(1, -20, 1, 0),
					Font = Enum.Font.Gotham,
					Text = option,
					TextColor3 = option == selected and Theme.Text or Theme.TextSecondary,
					TextSize = 11,
					TextXAlignment = Enum.TextXAlignment.Left,
				})

				opt.MouseEnter:Connect(function()
					TweenService:Create(opt, Ease.Hover, { BackgroundColor3 = Theme.Tertiary }):Play()
				end)
				opt.MouseLeave:Connect(function()
					TweenService:Create(opt, Ease.Hover, { BackgroundColor3 = Color3.new(1, 1, 1), BackgroundTransparency = 1 }):Play()
				end)
				opt.MouseButton1Click:Connect(function()
					selected = option
					dValue.Text = selected
					for _, child in pairs(panel:GetChildren()) do
						if child:IsA("TextButton") then
							local lbl = child:FindFirstChild("OptLabel")
							if lbl then
								lbl.TextColor3 = (child == opt) and Theme.Text or Theme.TextSecondary
							end
						end
					end
					closePanel()
					pcall(callback, selected)
				end)
			end

			d.MouseButton1Click:Connect(function()
				if open then closePanel() else openPanel() end
			end)

			-- Keep canvas size updated
			panelLayout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
				panel.Size = UDim2.new(1, 0, 0, panelLayout.AbsoluteContentSize.Y + 2)
				tab.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 4)
			end)
		end

		-- Section / Label
		function tabContent:Section(text)
			Create("TextLabel", {
				Parent = tab, Name = "Section",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 18),
				Font = Enum.Font.GothamSemibold,
				Text = text,
				TextColor3 = Theme.TextSecondary,
				TextSize = 10,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
		end

		function tabContent:Label(text)
			Create("TextLabel", {
				Parent = tab, Name = "Label",
				BackgroundTransparency = 1,
				Size = UDim2.new(1, 0, 0, 20),
				Font = Enum.Font.Gotham,
				Text = text,
				TextColor3 = Theme.TextSecondary,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
		end

		-- Textbox
		function tabContent:Textbox(text, disappear, callback)
			local box = Create("Frame", {
				Parent = tab, Name = "Textbox",
				BackgroundColor3 = Theme.Secondary,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 26),
			})
			Corner(box, 2)

			Create("TextLabel", {
				Parent = box, Name = "TextBoxTitle",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 0),
				Size = UDim2.new(0, 140, 1, 0),
				Font = Enum.Font.Gotham,
				Text = text,
				TextColor3 = Theme.Text,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
			})

			local input = Create("TextBox", {
				Parent = box, Name = "TextBoxInput",
				BackgroundColor3 = Theme.Background,
				BorderSizePixel = 0,
				Position = UDim2.new(1, -140, 0.5, -10),
				Size = UDim2.new(0, 130, 0, 20),
				Font = Enum.Font.Gotham,
				PlaceholderText = "Input...",
				PlaceholderColor3 = Theme.TextDisabled,
				Text = "",
				TextColor3 = Theme.Text,
				TextSize = 11,
				TextXAlignment = Enum.TextXAlignment.Left,
			})
			Corner(input, 2)
			Stroke(input, 0.35)

			input.FocusLost:Connect(function(enter)
				if enter then
					pcall(callback, input.Text)
					if disappear then
						input.Text = ""
					end
				end
			end)

			input.Focused:Connect(function()
				Stroke(input, 0).Color = accent
			end)
			input.FocusLost:Connect(function()
				Stroke(input, 0.35)
			end)
		end

		-- Keybind
		function tabContent:Bind(text, keypreset, callback)
			local key = keypreset or Enum.KeyCode.R
			local binding = false
			local keyName = key.Name

			local b = Create("TextButton", {
				Parent = tab, Name = "Bind",
				BackgroundColor3 = Theme.Secondary,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 26),
				AutoButtonColor = false,
				Font = Enum.Font.SourceSans,
				Text = "",
			})
			Corner(b, 2)

			local bTitle = Create("TextLabel", {
				Parent = b, Name = "BindTitle",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 0),
				Size = UDim2.new(1, -90, 1, 0),
				Font = Enum.Font.Gotham,
				Text = text,
				TextColor3 = Theme.Text,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
			})

			local keyLabel = Create("TextLabel", {
				Parent = b, Name = "KeyLabel",
				BackgroundColor3 = Theme.Background,
				BorderSizePixel = 0,
				Position = UDim2.new(1, -82, 0.5, -9),
				Size = UDim2.new(0, 72, 0, 18),
				Font = Enum.Font.Gotham,
				Text = keyName,
				TextColor3 = Theme.TextSecondary,
				TextSize = 10,
			})
			Corner(keyLabel, 2)
			Stroke(keyLabel, 0.35)

			local function setListening(st)
				binding = st
				keyLabel.Text = st and "Listening..." or keyName
				if st then
					Stroke(keyLabel, 0).Color = accent
					keyLabel.TextColor3 = Theme.Text
				else
					Stroke(keyLabel, 0.35)
					keyLabel.TextColor3 = Theme.TextSecondary
				end
			end

			b.MouseButton1Click:Connect(function()
				setListening(true)
			end)

			UserInputService.InputBegan:Connect(function(input, gP)
				if gP then return end
				if binding then
					if input.KeyCode ~= Enum.KeyCode.Unknown then
						key = input.KeyCode
						keyName = key.Name
						setListening(false)
						pcall(callback, key)
					end
				else
					if input.KeyCode == key then
						pcall(callback)
					end
				end
			end)

			b.MouseEnter:Connect(function() TweenService:Create(b, Ease.Hover, { BackgroundColor3 = Theme.Tertiary }):Play() end)
			b.MouseLeave:Connect(function() TweenService:Create(b, Ease.Hover, { BackgroundColor3 = Theme.Secondary }):Play() end)
		end

		-- Colorpicker
		function tabContent:Colorpicker(text, preset, callback)
			local toggled = false
			local color = preset or accent

			local c = Create("TextButton", {
				Parent = tab, Name = "Colorpicker",
				BackgroundColor3 = Theme.Secondary,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 26),
				AutoButtonColor = false,
				Font = Enum.Font.SourceSans,
				Text = "",
			})
			Corner(c, 2)

			local cTitle = Create("TextLabel", {
				Parent = c, Name = "ColorpickerTitle",
				BackgroundTransparency = 1,
				Position = UDim2.new(0, 10, 0, 0),
				Size = UDim2.new(1, -50, 1, 0),
				Font = Enum.Font.Gotham,
				Text = text,
				TextColor3 = Theme.Text,
				TextSize = 12,
				TextXAlignment = Enum.TextXAlignment.Left,
			})

			local swatch = Create("Frame", {
				Parent = c, Name = "Swatch",
				BackgroundColor3 = color,
				BorderSizePixel = 0,
				Position = UDim2.new(1, -40, 0.5, -8),
				Size = UDim2.new(0, 28, 0, 16),
			})
			Corner(swatch, 2)
			Stroke(swatch, 0.2)

			-- Simple popup with preset colors
			local popup = Create("Frame", {
				Parent = tab, Name = "ColorPopup",
				BackgroundColor3 = Theme.Panel,
				BorderSizePixel = 0,
				Size = UDim2.new(1, 0, 0, 0),
				ClipsDescendants = true,
				Visible = false,
				LayoutOrder = 999,
			})
			Stroke(popup, 0.2)

			local grid = Create("UIGridLayout", {
				Parent = popup,
				CellSize = UDim2.new(0, 22, 0, 22),
				CellPadding = UDim2.new(0, 4, 0, 4),
				SortOrder = Enum.SortOrder.LayoutOrder,
			})

			local presetColors = {
				Color3.fromRGB(255, 59, 48),
				Color3.fromRGB(255, 149, 0),
				Color3.fromRGB(255, 204, 0),
				Color3.fromRGB(52, 199, 89),
				Color3.fromRGB(0, 199, 190),
				Color3.fromRGB(22, 131, 255),
				Color3.fromRGB(10, 132, 255),
				Color3.fromRGB(88, 86, 214),
				Color3.fromRGB(175, 82, 222),
				Color3.fromRGB(255, 159, 237),
				Color3.fromRGB(255, 255, 255),
				Color3.fromRGB(120, 120, 128),
				Color3.fromRGB(58, 58, 64),
				Color3.fromRGB(0, 0, 0),
			}

			for _, col in ipairs(presetColors) do
				local cell = Create("TextButton", {
					Parent = popup, Name = "ColorCell",
					BackgroundColor3 = col,
					BorderSizePixel = 0,
					AutoButtonColor = false,
					Text = "",
				})
				Corner(cell, 2)
				Stroke(cell, 0.4)

				cell.MouseButton1Click:Connect(function()
					color = col
					swatch.BackgroundColor3 = color
					popup.Visible = false
					toggled = false
					pcall(callback, color)
				end)
			end

			local function closePopup()
				toggled = false
				popup.Visible = false
			end

			c.MouseButton1Click:Connect(function()
				toggled = not toggled
				popup.Visible = toggled
			end)

			c.MouseEnter:Connect(function() TweenService:Create(c, Ease.Hover, { BackgroundColor3 = Theme.Tertiary }):Play() end)
			c.MouseLeave:Connect(function() TweenService:Create(c, Ease.Hover, { BackgroundColor3 = Theme.Secondary }):Play() end)
		end

		return tabContent
	end

	return tabHold, sub
end

return lib