local UnlockTracker = require "components.unlocktracker"

-- alow all locked parts, but this makes a dummy head part selectable
function UnlockTracker:IsCosmeticUnlocked(id, _)
    -- simple fix to filter out loadout mannequin parts
    if id:find("^loadout_mannequin") ~= nil then return false end
	return true
end