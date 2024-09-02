local CharacterCreator = require "components.charactercreator"
local Cosmetic = require "defs.cosmetics.cosmetic"
local UnlockTracker = require "components.unlocktracker"
local CharacterScreen = require ("screens.character.characterscreen")
local Widget = require "widgets.widget"
local ScrollPanel = require "widgets.scrollpanel"
local TextButton = require "widgets.textbutton"
local fmodtable = require "defs.sound.fmodtable"
local UpvalueHacker = require("tools.upvaluehacker")

local CHARACTER_SPECIES = GLOBAL.CHARACTER_SPECIES
local REMOVE_TAIL_BUTTON_TEXT = "<p img='images/icons_emotes1/emote_mammimal_howl.tex' color=0 scale=2.5>\n\nREMOVE\nTAIL"

-- alow all locked parts
-- but this makes a dummy head part selectable,
-- do we need to filter it out?
function UnlockTracker:IsCosmeticUnlocked(id, _)
    -- simple fix to filter out loadout mannequin parts
    if id:find("^loadout_mannequin") ~= nil then return false end

	return true
end

-- allow all other speices' color options
local original_GetSpeciesColors = Cosmetic.GetSpeciesColors
function Cosmetic.GetSpeciesColors(colorgroup, _, ...)
	local total_colors = {}
	
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
-- side effect of modifying GetSpeciesBodyParts: affects randomize feature,
-- making it use all parts
function Cosmetic.GetSpeciesBodyParts(bodypart, _, ...)
    local total_bodyparts = {}

    for _,species in pairs(CHARACTER_SPECIES) do
        local bodyparts = original_GetSpeciesBodyParts(bodypart, species, ...)
        for _, def in pairs(bodyparts) do
            -- filtertags check in charactercreator
            --   remove species filtertags ONLY
            --   we dont want to remove filtertags alltogether
            --   because its also used for other stuff (see charactercreator)
            if def.filtertags then
                def.filtertags[species] = nil
            end
            
            table.insert(total_bodyparts, def)
        end
    end
    table.sort(total_bodyparts, Cosmetic.SortByItemName)

	return total_bodyparts
end

-- skips mismatched colors check and validation
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

-- remove COLOR_EXCEPTIONS (this is used to hide the color bar
-- for some spefific parts of speficic species which is not what we want)
-- remove the cost to change species
-- NOTE: theres no need to reduce/remove SPECIES_CHANGE_COST since the part
-- that charges you are already removed (see modifications to
-- GenerateBodyPartLists and OnSwitchSpecies below)
UpvalueHacker.SetUpvalue(CharacterScreen.GenerateColorList, {}, "COLOR_EXCEPTIONS")

-- modifications to the character customizer screen
AddClassPostConstruct("screens.character.characterscreen", function(self)
    self.colorlist_cols = 22
	self.colors_scroll = self.customize_character_contents:AddChild(ScrollPanel())
		:SetScale(1)
		:SetSize(80*self.colorlist_cols+15*(self.colorlist_cols*2+2), 160)
		:LayoutBounds("center", "bottom", self.customize_character_contents)
		:SetVirtualMargin(16)
	 	:Offset(0, -252)
	self.color_elements_list = self.colors_scroll:AddScrollChild(Widget("Color Options"))

    self.remove_tail_button = self.panel_root:AddChild(TextButton())
		:SetName("Remove tail button")
		:SetTextSize(self.label_font_size)
		:OverrideLineHeight(self.label_font_size * 0.8)
		:SetText(REMOVE_TAIL_BUTTON_TEXT)
		:SetTextColour(GLOBAL.UICOLORS.BACKGROUND_DARK)
		:SetTextFocusColour(GLOBAL.UICOLORS.FOCUS_DARK)
		:SetTextDisabledColour(GLOBAL.UICOLORS.LIGHT_TEXT_DARK)
		:LayoutBounds("center", "center", self.panel_bg)
		:Offset(-self.panel_w/2 + 260, -self.panel_h/2 + 180 + 220)
		:SetOnClickFn(function() self:OnRemoveTailClicked() end)
		:SetMultColorAlpha(1)
		:SetShown(true)
		:SetControlUpSound(fmodtable.Event.ui_revert_undo)
    function self:OnRemoveTailClicked()
        self.puppet.components.charactercreator:SetBodyPart("OTHER", nil)
        self.owner.components.charactercreator:SetBodyPart("OTHER", nil)
        self:ApplyChanges()
        self:CheckForChanges()
    end

    local original_GenerateBodyPartList = self.GenerateBodyPartList
    function self:GenerateBodyPartList(bodypart, ...)
        original_GenerateBodyPartList(self, bodypart, ...)
        -- set everything, including species items to not be purchasable
        -- (this wont prevent you from using them, it just removes the corsetone
        -- tag from species items)
        for _,bodypart_element in pairs(self.scroll_contents:GetChildren()) do
            bodypart_element:SetPurchasable(false, 0)
        end
    end

    -- remove the popup when picking a species, skipping the payment too
    function self:OnSwitchSpecies(bodypart, def)
        self:OnBodyPartElementSelected(bodypart, def)
        self:GenerateBodyPartList(bodypart)
        self:ApplyChanges()
        self:CheckForChanges()
    end

    -- layout our custom scrolling color list correctly
    local original_GenerateColorList = self.GenerateColorList
    function self:GenerateColorList(colorgroup, ...)
        original_GenerateColorList(self, colorgroup, ...)
        self.color_elements_list:LayoutChildrenInGrid(self.colorlist_cols, 15)
                :LayoutBounds("center", "bottom", self.panel_bg)
        self.colors_scroll:RefreshView()
    end

    -- make speices tooltips always show the descriptions, weather or not theyre locked
    local original_ElementTooltipFn = self.ElementTooltipFn
    function self:ElementTooltipFn(debug_mode, def, is_head, is_locked, is_purchasable, ...)
        return original_ElementTooltipFn(self, debug_mode, def, is_head, false, false, ...)
    end
end)