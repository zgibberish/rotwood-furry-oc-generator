local Cosmetic = require "defs.cosmetics.cosmetic"

local CHARACTER_SPECIES = GLOBAL.CHARACTER_SPECIES

-- allow all other speices' colors
local original_GetSpeciesColors = Cosmetic.GetSpeciesColors
function Cosmetic.GetSpeciesColors(colorgroup, _, ...)
	local total_colors = {}
	
    -- we have to go through all the species to add items to a combined list
    -- because GetSpeciesColors filters by def.species, not def.filtertags
    -- which we already removed above (see Cosmetic.GetSpeciesColors)
    for _,species in pairs(CHARACTER_SPECIES) do
        local colors = original_GetSpeciesColors(colorgroup, species, ...)
        for _, def in pairs(colors) do
            table.insert(total_colors, def)
        end
    end

	return total_colors
end
-- allow all other speices' body parts
local original_GetSpeciesBodyParts = Cosmetic.GetSpeciesBodyParts
function Cosmetic.GetSpeciesBodyParts(bodypart, _, ...)
    local total_bodyparts = {}

    -- we have to go through all the species to add items to a combined list
    -- because GetSpeciesBodyParts filters by def.species, not def.filtertags
    -- which we already removed above (see Cosmetic.GetSpeciesColors)

    for _,species in pairs(CHARACTER_SPECIES) do
        local bodyparts = original_GetSpeciesBodyParts(bodypart, species, ...)
        for _, def in pairs(bodyparts) do
            table.insert(total_bodyparts, def)
        end
    end
    table.sort(total_bodyparts, Cosmetic.SortByItemName)

	return total_bodyparts
end