local parent, ns = ...
local layout = ns.layout

if(select(2, UnitClass("player")) ~= "PALADIN") then return end

function layout:Holy_Update(event, unit, powerType)
	if(self.unit ~= unit or (powerType and powerType ~= 'HOLY_POWER')) then return end

	local hp = self.HolyPower
	local min = UnitPower('player', SPELL_POWER_HOLY_POWER)
	hp:SetValue(min)
end
