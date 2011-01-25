local parent, ns = ...
local layout = ns.layout

-- TODO: Implament a better eclipse bar.
if(select(2, UnitClass("player")) ~= "DRUID") then return end

function layout:Eclipse_Update(unit)
	local val = UnitPower("player", SPELL_POWER_ECLIPSE)
	self:SetValue(math.abs(val))

	local col = colors.mp.eclipse[val > 0 and "positive" or "negative"]
	self:SetStatusBarColor(col.r, col.g, col.b)
	self.bg:SetVertexColor(col.r, col.g, col.b)
end

function layout:Combo_Update(event, unit)
	if(unit ~= "player" and self.unit ~= "target") then return end

	local c = GetComboPoints(unit, "target")

	if(c == 0) then
		c = self._level
	end

	self.Name:SetFormattedText(format.all.name, toHex(unpack(self._color)), c, self._name)
end
