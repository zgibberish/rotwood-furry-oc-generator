local ColorgroupOverride = require "components.gbj_colorgroupoverride"

AddClassPostConstruct("widgets.playerpuppet", function(self)
    self.components.gbj_colorgroupoverride = ColorgroupOverride(self.puppet.inst)

    function self:ApplyColorOverride(colorgroup)
        local gbj_co = self.components.gbj_colorgroupoverride
        if not gbj_co then return end

        local override = gbj_co:GetSymbolColorOverride(colorgroup)
        if override then
            self.components.charactercreator:SetSymbolColorShift(
                colorgroup,
                override.hue,
                override.saturation,
                override.brightness
            )
        end
    end

    function self:ApplyAllColorOverrides()
        for cg, _ in pairs(self.components.charactercreator.colorgroups) do
            self:ApplyColorOverride(cg)
        end
    end

    local original_CloneCharacterAppearance = self.CloneCharacterAppearance
    function self:CloneCharacterAppearance(character, ...)
        original_CloneCharacterAppearance(self, character, ...)
        local owner_gbj_co = character.components.gbj_colorgroupoverride
        local puppet_gbj_co = self.components.gbj_colorgroupoverride
        puppet_gbj_co:CloneComponent(owner_gbj_co)

        self:ApplyAllColorOverrides()
    end
end)
