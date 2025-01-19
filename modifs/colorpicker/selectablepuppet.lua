AddClassPostConstruct("widgets.ftf.selectablepuppet", function(self)
    local original_SetPlayerData = self.SetPlayerData
    function self:SetPlayerData(entity_data, player_data, ...)
        local ret = original_SetPlayerData(self, entity_data, player_data, ...)
        local owner_gbj_co = entity_data and entity_data.gbj_colorgroupoverride
        local puppet_gbj_co = self.puppet.components.gbj_colorgroupoverride
        if owner_gbj_co and puppet_gbj_co then
            -- doesnt work, maybe entity_data doesnt actually contain the whole
            -- functional component
            -- puppet_gbj_co:CloneComponent(owner_gbj_co) 
            puppet_gbj_co.overrides = GLOBAL.deepcopy(owner_gbj_co.overrides)
            self.puppet:ApplyAllColorOverrides()
        end
        return ret -- self
    end
end)
