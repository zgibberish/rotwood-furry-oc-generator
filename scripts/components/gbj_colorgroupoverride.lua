local ColorgroupOverride = Class(function(self, inst)
    self.inst = inst
    self.overrides = {}
end)

function ColorgroupOverride:SetSymbolColorOverride(colorgroup, hue, saturation, brightness)
    self.overrides[colorgroup] = {
        hue = hue,
        saturation = saturation,
        brightness = brightness,
    }
end

function ColorgroupOverride:GetSymbolColorOverride(colorgroup)
    return self.overrides[colorgroup]
end

function ColorgroupOverride:ClearSymbolColorOverride(colorgroup)
    self.overrides[colorgroup] = nil
end

function ColorgroupOverride:CloneComponent(other)
    assert(other:is_a(ColorgroupOverride))
    self.overrides = deepcopy(other.overrides)
end

function ColorgroupOverride:OnSave()
    local data = {}
    data.overrides = self.overrides
    return data
end

function ColorgroupOverride:OnLoad(data)
    if data.overrides then
        self.overrides = data.overrides
    end
end

return ColorgroupOverride
