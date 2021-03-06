/*---------------------------------------------------------------------------
F4 tab
---------------------------------------------------------------------------*/
local PANEL = {}

function PANEL:Init()
	self.BaseClass.Init(self);
end

local gray = Color(110, 110, 110, 255);
function PANEL:Paint(w, h)
	local drawFunc = self:GetSkin().tex.TabT_Inactive

	if self:GetDisabled() then
		drawFunc(0, 0, w, h, gray);
		return
	end
	self.BaseClass.Paint(self, w, h);
end

function PANEL:ApplySchemeSettings()
	local ExtraInset = 10

	if self.Image then
		ExtraInset = ExtraInset + self.Image:GetWide();
	end

	local Active = self:GetPropertySheet():GetActiveTab() == self

	self:SetTextInset(ExtraInset, 4);
	local w, h = self:GetContentSize();
	h = Active and 38 or 30

	self:SetSize(w + 30, h);

	DLabel.ApplySchemeSettings(self);
end
function PANEL:Paint( w, h )
	derma.SkinHook( "Paint", "Frame", self, w, h );
end
derma.DefineControl("F4MenuTab", "", PANEL, "DTab");



/*---------------------------------------------------------------------------
F4 tab sheet
---------------------------------------------------------------------------*/

PANEL = {}

local mouseX, mouseY = ScrW() / 2, ScrH() / 2
function PANEL:Init()
	self.F4Down = true

	self:StretchToParent(100, 100, 100, 100);
	self:Center();
	self:SetVisible(true);
	self:MakePopup();
	self:SetupCloseButton(fn.Curry(self.Hide, 2)(self));
end

function PANEL:SetupCloseButton(func)
	self.CloseButton = self.tabScroller:Add("DButton");
	self.CloseButton:SetText("");
	self.CloseButton.DoClick = func
	self.CloseButton.Paint = function(panel, w, h) derma.SkinHook("Paint", "WindowCloseButton", panel, w, h) end
	self.CloseButton:Dock(RIGHT);
	self.CloseButton:DockMargin(0, 0, 0, 8);
	self.CloseButton:SetSize(32, 32);
end

function PANEL:AddSheet(label, panel, material, NoStretchX, NoStretchY, Tooltip)
	if not IsValid(panel) then return end

	local sheet = {}

	sheet.Name = label

	sheet.Tab = vgui.Create("F4MenuTab", self);
	sheet.Tab:Setup(label, self, panel, material);
	sheet.Tab:SetTooltip(Tooltip);
	sheet.Tab:SetFont("fprpHUD2");

	sheet.Panel = panel
	sheet.Panel.tab = sheet.Tab
	sheet.Panel.NoStretchX = NoStretchX
	sheet.Panel.NoStretchY = NoStretchY
	sheet.Panel:SetPos(self:GetPadding(), sheet.Tab:GetTall() + 8 + self:GetPadding());
	sheet.Panel:SetVisible(false);
	if sheet.Panel.shouldHide and sheet.Panel:shouldHide() then sheet.Tab:SetDisabled(true) end

	panel:SetParent(self);

	table.insert(self.Items, sheet);
	local index = #self.Items

	if not self:GetActiveTab() then
		self:SetActiveTab(sheet.Tab);
		sheet.Panel:SetVisible(true);
	end

	self.tabScroller:AddPanel(sheet.Tab);

	if panel.Refresh then panel:Refresh() end

	return sheet, index
end

local F4Bind
function PANEL:Think()
	self.CloseButton:SetVisible(not self.tabScroller.btnRight:IsVisible());

	F4Bind = F4Bind or input.KeyNameToNumber(input.LookupBinding("gm_showspare2"));
	if not F4Bind then return end

	if self.F4Down and not input.IsKeyDown(F4Bind) then
		self.F4Down = false
		return
	elseif not self.F4Down and input.IsKeyDown(F4Bind) then
		self.F4Down = true
		self:Hide();
	end
end

hook.Add("PlayerBindPress", "fprpF4Bind", function(ply, bind, pressed)
	if string.find(bind, "gm_showspare2", 1, true) then
		F4Bind = input.KeyNameToNumber(input.LookupBinding(bind));
	end
end);

function PANEL:Refresh()
	for k,v in pairs(self.Items) do
		if v.Panel.shouldHide and v.Panel:shouldHide() then v.Tab:SetDisabled(true);
		else v.Tab:SetDisabled(false) end
		if v.Panel.Refresh then v.Panel:Refresh() end
	end
end

function PANEL:Show()
	self:Refresh();
	if #self.Items > 0 and self:GetActiveTab() and self:GetActiveTab():GetDisabled() then
		self:SetActiveTab(self.Items[1].Tab) --Jobs
	end
	self.F4Down = true
	self:SetVisible(true);
	gui.SetMousePos(mouseX, mouseY);
end

function PANEL:Hide()
	mouseX, mouseY = gui.MousePos();
	self:SetVisible(false);
end

function PANEL:Close()
	self:Hide();
end

function PANEL:createTab(name, panel)
	local sheet, index = self:AddSheet(name, panel);
	return index, sheet
end

function PANEL:removeTab(name)
	for k, v in pairs(self.Items) do
		if v.Tab:GetText() ~= name then continue end
		return self:CloseTab(v.Tab, true);
	end
end

function PANEL:switchTabOrder(tab1, tab2)
	self.Items[tab1], self.Items[tab2] = self.Items[tab2], self.Items[tab1]
	self.tabScroller.Panels[tab1], self.tabScroller.Panels[tab2] = self.tabScroller.Panels[tab2], self.tabScroller.Panels[tab1]
	self.tabScroller:InvalidateLayout(true);
end


function PANEL:generateTabs()
	fprp.hooks.F4MenuTabs();
	hook.Call("F4MenuTabs");
	self:SetSkin(GAMEMODE.Config.fprpSkin);
end

function PANEL:Paint( w, h )
	derma.SkinHook( "Paint", "Frame", self, w, h );
end
derma.DefineControl("F4EditablePropertySheet", "", vgui.GetControlTable("DPropertySheet"), "EditablePanel");
derma.DefineControl("F4MenuFrame", "", PANEL, "F4EditablePropertySheet");
