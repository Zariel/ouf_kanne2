local parent, ns = ...
local layout = ns.layout

local update = function(self, event, unit)
	if(self.unit ~= unit) then return end
	local Name = self.Name
	if(Name.OverideUpdateName) then
		Name:OverideUpdateName(event, unit)
	else
		Name:SetText(UnitName(unit))
	end
end

local enable = function(self, unit)
	if(self.Name) then
		self:RegisterEvent("UNIT_NAME_UPDATE", update)

		return true
	end
end

local disable = function(self)
	if(self.Name) then
		self:UnregisterEvent("UNIT_NAME_UPDATE")
	end
end

layout:AddElement("Name", update, enable, disable)
