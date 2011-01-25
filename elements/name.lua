local parent, ns = ...
local layout = ns.layout

local update = function(self, event, unit)
	if(self.unit ~= unit) then return end
	if(self.OverideUpdateName) then
		self:OverideUpdateName(event, unit)
	else
		local name = UnitName(unit)
		self.Name:SetText(name)
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
