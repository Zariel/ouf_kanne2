local parent, ns = ...
local layout = ns.layout

-- TODO: Implament a better eclipse bar.
if(select(2, UnitClass("player")) ~= "ROGUE") then return end

function layout:Combo_Update(event, unit)
	if(unit ~= "player" and self.unit ~= "target") then return end

	local c = GetComboPoints(unit, "target")

	if(c == 0) then
		c = self._level
	end

	self.Name:SetFormattedText(format.all.name, toHex(unpack(self._color)), c, self._name)
end
