local parent, ns = ...
local layout = ns.layout

local update = function(self, event, unit)
	if(self.unit ~= unit) then return end
	self.Name:SetText(UnitName(unit))
end

local path = function(self, ...)
	return (self.Name.Override or update)(self, ...)
end

local ForceUpdate = function(self)
	return path(self.__owner, "ForceUpdate", self.__owner.unit)
end

local enable = function(self, unit)
	local name = self.Name
	if(name) then
		name.__owner = self
		name.ForceUpdate = ForceUpdate

		self:RegisterEvent("UNIT_NAME_UPDATE", path)

		return true
	end
end

local disable = function(self)
	if(self.Name) then
		self:UnregisterEvent("UNIT_NAME_UPDATE", path)
	end
end

layout:AddElement("Name", path, enable, disable)
