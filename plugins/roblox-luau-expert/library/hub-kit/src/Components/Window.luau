--[[
	Window - the hub: a draggable panel with a tab sidebar, a search box and
	one scrolling page per tab.

	Sized by scale and held between 300 x 240 and 760 x 540, so it fits a
	640 x 360 phone under the topbar and does not stretch across an
	ultrawide monitor. Below 520 px wide it turns compact: the sidebar shrinks
	to icons and the subtitle hides, instead of the page being squeezed.

	The root frame is Active so a click on the window never reaches the game
	world behind it; with a click-teleport feature on, a press on the hub
	would otherwise teleport the player.

	Hiding (the minimize button or the menu key) leaves a draggable Open chip
	on screen, because a phone has no RightShift. Closing asks first, then
	unloads: every connection, instance and popup the window made is released
	through one trove, and OnUnload fires first so the hub can switch its own
	features off.
--]]

local UserInputService = game:GetService("UserInputService")

local Config = require(script.Parent.Parent.Core.Config)
local Drag = require(script.Parent.Parent.Core.Drag)
local Icons = require(script.Parent.Parent.Core.Icons)
local Motion = require(script.Parent.Parent.Core.Motion)
local Mount = require(script.Parent.Parent.Core.Mount)
local New = require(script.Parent.Parent.Core.New)
local Signal = require(script.Parent.Parent.Core.Signal)
local Theme = require(script.Parent.Parent.Core.Theme)
local Trove = require(script.Parent.Parent.Core.Trove)
local Dialog = require(script.Parent.Dialog)
local OpenButton = require(script.Parent.OpenButton)
local SettingsTab = require(script.Parent.SettingsTab)
local Tab = require(script.Parent.Tab)

local COMPACT_BELOW = 520
local SIDEBAR_WIDE = 160
local SIDEBAR_COMPACT = 52
local HIDDEN_SCALE = 0.96

local Window = {}

local function folderFrom(title: string): string
	local cleaned = string.sub(string.gsub(title, "[^%w _%-]", ""), 1, 32)
	return if cleaned == "" then "Hub" else cleaned
end

local function topbarButton(
	trove: any,
	parent: Instance,
	image: string,
	order: number,
	name: string
): TextButton
	local button = New("TextButton", {
		Name = name,
		LayoutOrder = order,
		Size = UDim2.fromOffset(44, 44),
		BackgroundTransparency = 1,
		AutoButtonColor = false,
		Text = "",
		Theme = { BackgroundColor3 = "raised" },
	}, parent)
	New("UICorner", { CornerRadius = UDim.new(0, 6) }, button)
	local mark = New("ImageLabel", {
		Name = "Mark",
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = UDim2.fromOffset(16, 16),
		BackgroundTransparency = 1,
		Image = Icons.resolve(image),
		Theme = { ImageColor3 = "textMuted" },
	}, button)
	local function lit(on: boolean)
		button.BackgroundTransparency = if on then 0 else 1
		mark.ImageColor3 = Theme.get(if on then "text" else "textMuted")
	end
	trove:connect(button.MouseEnter, function()
		lit(true)
	end)
	trove:connect(button.MouseLeave, function()
		lit(false)
	end)
	trove:connect(button.SelectionGained, function()
		lit(true)
	end)
	trove:connect(button.SelectionLost, function()
		lit(false)
	end)
	return button
end

function Window.new(kit: any, options: { [string]: any })
	assert(type(options.Title) == "string", "CreateWindow needs a Title string")
	local trove = Trove.new()

	local gui = New("ScreenGui", {
		Name = "HubKit",
		DisplayOrder = 100,
		ResetOnSpawn = false,
		ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
		ScreenInsets = Enum.ScreenInsets.CoreUISafeInsets,
	}, Mount())
	trove:add(gui)

	local root = New("Frame", {
		Name = "Window",
		Active = true,
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		Size = options.Size or UDim2.fromScale(0.62, 0.72),
		Theme = { BackgroundColor3 = "surface" },
	}, gui)
	New("UISizeConstraint", {
		MinSize = Vector2.new(300, 240),
		MaxSize = Vector2.new(760, 540),
	}, root)
	New("UICorner", { CornerRadius = UDim.new(0, 10) }, root)
	New("UIStroke", {
		ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
		BorderStrokePosition = Enum.BorderStrokePosition.Inner,
		Thickness = 1,
		Theme = { Color = "stroke" },
	}, root)
	New("UIPadding", {
		PaddingLeft = UDim.new(0, 8),
		PaddingRight = UDim.new(0, 8),
		PaddingTop = UDim.new(0, 8),
		PaddingBottom = UDim.new(0, 8),
	}, root)
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder, Padding = UDim.new(0, 8) }, root)
	local pop = New("UIScale", { Scale = 1 }, root)

	local topbar = New("Frame", {
		Name = "Topbar",
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 44),
		BackgroundTransparency = 1,
	}, root)
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
	}, topbar)
	New("ImageLabel", {
		Name = "Icon",
		LayoutOrder = 1,
		Size = UDim2.fromOffset(20, 20),
		Visible = options.Icon ~= nil,
		BackgroundTransparency = 1,
		Image = if options.Icon then Icons.resolve(options.Icon) else "",
		Theme = { ImageColor3 = "accent" },
	}, topbar)
	local titles = New("Frame", {
		Name = "Titles",
		LayoutOrder = 2,
		Size = UDim2.new(),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
	}, topbar)
	New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }, titles)
	New("UIListLayout", { SortOrder = Enum.SortOrder.LayoutOrder }, titles)
	New("TextLabel", {
		Name = "Title",
		LayoutOrder = 1,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		BackgroundTransparency = 1,
		FontFace = Font.fromEnum(Enum.Font.BuilderSansBold),
		TextSize = 16,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = options.Title,
		Theme = { TextColor3 = "text" },
	}, titles)
	local subtitle = New("TextLabel", {
		Name = "Subtitle",
		LayoutOrder = 2,
		Size = UDim2.fromScale(1, 0),
		AutomaticSize = Enum.AutomaticSize.Y,
		Visible = options.Subtitle ~= nil,
		BackgroundTransparency = 1,
		FontFace = Font.fromEnum(Enum.Font.BuilderSans),
		TextSize = 12,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = options.Subtitle or "",
		Theme = { TextColor3 = "textMuted" },
	}, titles)
	local minimize = topbarButton(trove, topbar, "minus", 3, "Minimize")
	local close = topbarButton(trove, topbar, "x", 4, "Close")

	local body = New("Frame", {
		Name = "Body",
		LayoutOrder = 2,
		Size = UDim2.fromScale(1, 0),
		BackgroundTransparency = 1,
	}, root)
	New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }, body)
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
	}, body)

	local sidebar = New("ScrollingFrame", {
		Name = "Sidebar",
		LayoutOrder = 1,
		Size = UDim2.new(0, SIDEBAR_WIDE, 1, 0),
		BackgroundTransparency = 1,
		BorderSizePixel = 0,
		ScrollBarThickness = 0,
		AutomaticCanvasSize = Enum.AutomaticSize.Y,
		CanvasSize = UDim2.new(),
		ScrollingDirection = Enum.ScrollingDirection.Y,
	}, body)
	New("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 4),
	}, sidebar)

	local content = New("Frame", {
		Name = "Content",
		LayoutOrder = 2,
		Size = UDim2.fromScale(0, 1),
		Theme = { BackgroundColor3 = "background" },
	}, body)
	New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }, content)
	New("UICorner", { CornerRadius = UDim.new(0, 10) }, content)
	New("UIPadding", {
		PaddingLeft = UDim.new(0, 12),
		PaddingRight = UDim.new(0, 4),
		PaddingTop = UDim.new(0, 12),
		PaddingBottom = UDim.new(0, 12),
	}, content)
	New("UIListLayout", {
		SortOrder = Enum.SortOrder.LayoutOrder,
		Padding = UDim.new(0, 8),
	}, content)

	local header = New("Frame", {
		Name = "Header",
		LayoutOrder = 1,
		Size = UDim2.new(1, 0, 0, 36),
		BackgroundTransparency = 1,
	}, content)
	New("UIListLayout", {
		FillDirection = Enum.FillDirection.Horizontal,
		SortOrder = Enum.SortOrder.LayoutOrder,
		VerticalAlignment = Enum.VerticalAlignment.Center,
		Padding = UDim.new(0, 8),
	}, header)
	local pageTitle = New("TextLabel", {
		Name = "PageTitle",
		LayoutOrder = 1,
		Size = UDim2.fromScale(0, 1),
		BackgroundTransparency = 1,
		FontFace = Font.fromEnum(Enum.Font.BuilderSansBold),
		TextSize = 20,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextTruncate = Enum.TextTruncate.AtEnd,
		Text = "",
		Theme = { TextColor3 = "text" },
	}, header)
	New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }, pageTitle)
	local search = New("TextBox", {
		Name = "Search",
		LayoutOrder = 2,
		Size = UDim2.fromOffset(160, 36),
		ClearTextOnFocus = false,
		FontFace = Font.fromEnum(Enum.Font.BuilderSans),
		TextSize = 14,
		PlaceholderText = "Search this tab",
		Text = "",
		Theme = {
			BackgroundColor3 = "surface",
			TextColor3 = "text",
			PlaceholderColor3 = "textMuted",
		},
	}, header)
	New("UICorner", { CornerRadius = UDim.new(0, 6) }, search)
	New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, search)

	local pages = New("Frame", {
		Name = "Pages",
		LayoutOrder = 2,
		Size = UDim2.fromScale(1, 0),
		BackgroundTransparency = 1,
	}, content)
	New("UIFlexItem", { FlexMode = Enum.UIFlexMode.Fill }, pages)

	local window = {
		kit = kit,
		trove = trove,
		gui = gui,
		root = root,
		sidebar = sidebar,
		pages = pages,
		tabs = {},
		selected = nil,
		query = "",
		visible = true,
		toggleKey = options.ToggleKey or Enum.KeyCode.RightShift,
		config = Config.new(options.Folder or folderFrom(options.Title)),
		Flags = {},
		OnUnload = Signal.new(),
		Gui = gui,
	}
	trove:add(window.OnUnload)
	local opener = OpenButton.new(window, options)

	function window:Tab(tabOptions: { [string]: any })
		local tab = Tab.new(self, tabOptions)
		table.insert(self.tabs, tab)
		tab.label.Visible = not self.compact
		if self.selected == nil then
			self:SelectTab(tab)
		else
			tab:render()
		end
		return tab
	end

	function window:SettingsTab(tabOptions: { [string]: any }?)
		return SettingsTab.build(self, tabOptions or {})
	end

	function window:SelectTab(tab: any)
		self.selected = tab
		for _, other in self.tabs do
			other.frame.Visible = other == tab
			other:render()
		end
		pageTitle.Text = tab.title
		self:applySearch()
	end

	function window:applySearch()
		local tab = self.selected
		if not tab then
			return
		end
		local query = self.query
		local shown, sectionsShown = 0, {}
		for _, entry in tab.entries do
			local match = query == "" or string.find(entry.text, query, 1, true) ~= nil
			entry.frame.Visible = match
			if match then
				shown += 1
				if entry.section then
					sectionsShown[entry.section] = true
				end
			end
		end
		for _, section in tab.sections do
			section.holder.Visible = query == "" or sectionsShown[section] == true
			section.frame.Visible = query ~= "" or not section.collapsed
		end
		tab.empty.Visible = query ~= "" and shown == 0
		tab.empty.Text = `Nothing on {tab.title} matches "{search.Text}"`
	end

	function window:SetVisible(visible: boolean)
		if visible == self.visible then
			return
		end
		self.visible = visible
		if visible then
			opener.hide()
			root.Visible = true
			pop.Scale = HIDDEN_SCALE
			Motion.play(pop, Motion.enter, { Scale = 1 })
			return
		end
		if kit.popup then
			kit.popup.close()
		end
		opener.show()
		Motion.play(pop, Motion.exit, { Scale = HIDDEN_SCALE }, function()
			root.Visible = self.visible
		end)
	end

	function window:Toggle()
		self:SetVisible(not self.visible)
	end

	function window:SetToggleKey(key: Enum.KeyCode?)
		self.toggleKey = key
		opener.setHint(key)
	end

	function window:Notify(notice: { [string]: any })
		return kit.notify(notice)
	end

	function window:Dialog(dialogOptions: { [string]: any })
		return Dialog.open(kit, dialogOptions)
	end

	function window:LoadAutoload(): (boolean, string)
		local ok, message = self.config:autoload()
		if ok then
			self:Notify({ Title = "Config", Content = message, Kind = "success" })
		end
		return ok, message
	end

	function window:Unload()
		if self.unloaded then
			return
		end
		self.unloaded = true
		if kit.popup then
			kit.popup.close()
		end
		self.OnUnload:Fire()
		local index = table.find(kit.windows, self)
		if index then
			table.remove(kit.windows, index)
		end
		trove:clean()
	end

	local function arrange()
		local compact = root.AbsoluteSize.X < COMPACT_BELOW
		window.compact = compact
		sidebar.Size = UDim2.new(0, if compact then SIDEBAR_COMPACT else SIDEBAR_WIDE, 1, 0)
		search.Size = UDim2.fromOffset(if compact then 112 else 160, 36)
		subtitle.Visible = options.Subtitle ~= nil and not compact
		for _, tab in window.tabs do
			tab.label.Visible = not compact
		end
	end

	Drag.attach(trove, topbar, root)
	trove:connect(root:GetPropertyChangedSignal("AbsoluteSize"), arrange)
	trove:connect(search:GetPropertyChangedSignal("Text"), function()
		window.query = string.lower(search.Text)
		window:applySearch()
	end)
	trove:connect(minimize.Activated, function()
		window:SetVisible(false)
	end)
	local function unload()
		window:Unload()
	end
	function window:ConfirmUnload()
		return self:Dialog({
			Title = `Unload {options.Title}?`,
			Content = "The window closes and everything it connected is disconnected.",
			Buttons = {
				{ Title = "Unload", Variant = "danger", Callback = unload },
				{ Title = "Keep open", Cancel = true },
			},
		})
	end
	trove:connect(close.Activated, function()
		window:ConfirmUnload()
	end)
	trove:connect(UserInputService.InputBegan, function(input: InputObject, processed: boolean)
		if not processed and not kit.capturing and input.KeyCode == window.toggleKey then
			window:Toggle()
		end
	end)

	arrange()
	return window
end

return Window
