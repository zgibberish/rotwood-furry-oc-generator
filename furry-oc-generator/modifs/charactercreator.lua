local CharacterCreator = require "components.charactercreator"
local Cosmetic = require "defs.cosmetics.cosmetic"

-- skip mismatched colors check and validation
function CharacterCreator:ValidateColorGroups()
end

function CharacterCreator:IsBodyPartUnlocked(def, owner, ...)
    -- simple fix to filter out loadout mannequin parts
    if def.name:find("^loadout_mannequin") ~= nil then return false end
    return true
end

function CharacterCreator:IsColorUnlocked(...)
    return true
end

-- make LoadFromTable wipe all bodyparts before setting parts,
-- so nil/missing parts can be applied normally
local original_LoadFromTable = CharacterCreator.LoadFromTable
function CharacterCreator:LoadFromTable(data, ...)
    for bodypart,_ in pairs(self.bodyparts) do
        self:SetBodyPart(bodypart, nil)
    end
    for colorgroup,_ in pairs(self.colorgroups) do
        self:SetColorGroup(colorgroup, nil)
    end

    original_LoadFromTable(self, data, ...)
end


-- bypass species filtertags check in CharacterCreator:SetBodyPart
-- this validation check reverts your mismatched parts to default species parts
-- on character load
local original_SetBodyPart = CharacterCreator.SetBodyPart
function CharacterCreator:SetBodyPart(bodypart, name, ...)
    -- a sort of wrapper for the original SetBodyPart, where we strip out all
    -- the species filtertags before calling the original function, then restore
    -- them back after the call

    -- basically the same as the first portion of the og function for nil checks
    local items = Cosmetic.BodyParts[bodypart]
    local def
    if items == nil then
		return
	end
    if name then
		def = items[name]
		if not def then return end
	end

    local ret -- return
    if def ~= nil then
        if def.filtertags then
            local original_filtertags = def.filtertags
            def.filtertags[def.species] = nil
            ret = original_SetBodyPart(self, bodypart, name, ...)
            def.filtertags = original_filtertags
        end
    else
        -- still need to call it if def is nil regardles, so the og function can
        -- handle the rest for us
        ret = original_SetBodyPart(self, bodypart, name, ...)
    end
    
    return ret
end