AddComponentPostInit("charactercreator", function(self, inst)
    --NOTE: this does not apply to components added by using Component() directly
    -- e.g: playerpuppets, so we would need to add this modification again in
    -- PlayerPuppet
    local original_SetColorGroup = self.SetColorGroup
    function self:SetColorGroup(colorgroup, ...)
        original_SetColorGroup(self, colorgroup, ...)
        
        local gbj_co = self.inst.components.gbj_colorgroupoverride
        if not gbj_co then return end

        local override = gbj_co:GetSymbolColorOverride(colorgroup)
        if not override then return end

        self:SetSymbolColorShift(
            colorgroup,
            override.hue,
            override.saturation,
            override.brightness
        )
    end
end)
