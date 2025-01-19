local CharacterScreen = require ("screens.character.characterscreen")
local Widget = require "widgets.widget"
local Image = require "widgets.image"
local ScrollPanel = require "widgets.scrollpanel"
local TextButton = require "widgets.textbutton"
local SelectableBodyPart = require "widgets.ftf.selectablebodypart"
local UpvalueHacker = require("tools.upvaluehacker")
local easing = require "util.easing"

local UICOLORS = GLOBAL.UICOLORS
local Updater = GLOBAL.Updater

-- update these whenever the species list is changed
local SPECIES_OVERRIDE_BUTTON_TEXT = {
    [1] = "<p img='images/ui_ftf_dialog/convo_close.tex' color=0 scale=2.2>\n\nSPECIES\nOVERRIDE",
    [2] = "<p img='images/icons_emotes1/emote_mammimal_howl.tex' color=0 scale=2.5>\n\nSPECIES\nOVERRIDE",
    [3] = "<p img='images/icons_emotes1/emote_amphibee_bubble_kiss.tex' color=0 scale=2.5>\n\nSPECIES\nOVERRIDE",
    [4] = "<p img='images/icons_emotes1/emote_pump.tex' color=0 scale=2.5>\n\nSPECIES\nOVERRIDE",
}

local SPECIES_OVERRIDE_SELECTED_TO_SPECIES = {
    [1] = nil,
    [2] = "canine",
    [3] = "mer",
    [4] = "ogre",
}

local EMPTY_BODYPART_AVAILABLE_OPTIONS = {
    ["OTHER"] = true,
}

-- remove COLOR_EXCEPTIONS (this is used to hide the color bar
-- for some spefific parts of speficic species which is not what we want)
-- remove the cost to change species
-- NOTE: theres no need to reduce/remove SPECIES_CHANGE_COST since the part
-- that charges you are already removed (see modifications to
-- GenerateBodyPartList and OnSwitchSpecies below)
UpvalueHacker.SetUpvalue(CharacterScreen.GenerateColorList, {}, "COLOR_EXCEPTIONS")

-- modifications to the character customizer screen
AddClassPostConstruct("screens.character.characterscreen", function(self)
    local SPECEIS_OVERRIDE_BUTTON_SELECTED = 1

    self.colorlist_cols = 22
	self.colors_scroll = self.customize_character_contents:AddChild(ScrollPanel())
		:SetScale(1)
		:SetSize(80*self.colorlist_cols+15*(self.colorlist_cols*2+2), 160)
		:LayoutBounds("center", "bottom", self.customize_character_contents)
		:SetVirtualMargin(16)
	 	:Offset(0, -252)
	self.color_elements_list = self.colors_scroll:AddScrollChild(Widget("Color Options"))

    self.species_override_button = self.panel_root:AddChild(TextButton())
        :SetName("Species override button")
        :SetTextSize(self.label_font_size)
        :SetText(SPECIES_OVERRIDE_BUTTON_TEXT[SPECEIS_OVERRIDE_BUTTON_SELECTED])
        :SetTextColour(UICOLORS.BACKGROUND_DARK)
        :SetTextFocusColour(UICOLORS.FOCUS_DARK)
        :SetTextDisabledColour(UICOLORS.LIGHT_TEXT_DARK)
        :LayoutBounds("center", "center", self.panel_bg)
        :Offset(-self.panel_w/2 + 260, -self.panel_h/2 + 180 + 220)
        :SetOnClickFn(function() self:OnSpeciesOverrideClicked() end)
        :SetMultColorAlpha(0.4)
        :SetShown(false)
    function self:OnSpeciesOverrideClicked()
        -- cycles SPECEIS_OVERRIDE_BUTTON_SELECTED from 1 to #SPECIES_OVERRIDE_BUTTON_TEXT
        SPECEIS_OVERRIDE_BUTTON_SELECTED = SPECEIS_OVERRIDE_BUTTON_SELECTED + 1
        if SPECEIS_OVERRIDE_BUTTON_SELECTED > #SPECIES_OVERRIDE_BUTTON_TEXT then
            SPECEIS_OVERRIDE_BUTTON_SELECTED = 1
        end

        self.species_override_button
            :SetText(SPECIES_OVERRIDE_BUTTON_TEXT[SPECEIS_OVERRIDE_BUTTON_SELECTED])
        self.species_override_button
            :SetMultColorAlpha(SPECEIS_OVERRIDE_BUTTON_SELECTED == 1 and 0.4 or 1)
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

        -- insert an empty option for the user to be able to remove that part
        if EMPTY_BODYPART_AVAILABLE_OPTIONS[bodypart] then
            local empty_bodypart_element = self.scroll_contents:AddChild(SelectableBodyPart(image_w))
                :SetBodyPartId("")
                :SetSelected(false)
                :SetLocked(false)
                :SetPurchasable(false)
                :SetPuppetScale(0)
                :HighlightBodyPart(nil)
            local empty_icon = empty_bodypart_element:AddChild(Image("images/ui_ftf_dialog/convo_close.tex"))
                :SetMultColor(UICOLORS.BACKGROUND_DARK)
                :SetMultColorAlpha(0.3)

            empty_bodypart_element:SetOnClick(function()
                self:OnBodyPartElementSelected(bodypart, {})
                empty_bodypart_element:SetSelected(true)
            end)

            empty_bodypart_element:SetOnGainFocus(function()
                empty_bodypart_element:OnFocusChange(true)
                if not empty_bodypart_element:IsSelected() then
                    self:BodyPartPreview(bodypart, nil)
                end
            end)
            :SetOnLoseFocus(function()
                empty_bodypart_element:OnFocusChange(false)
                if not empty_bodypart_element:IsSelected() then
                    self:ClearBodyPartPreview()
                end
            end)

            -- refresh the scroll layout
            local image_w = 320
            self.scroll_contents:LayoutInDiagonal(3, 60, 60)
                :SetPosition(-self.list_width/2 + image_w, -image_w/2)
            self.scroll:RefreshView()
        end
    end

    -- change nil check so preview works correctly again if you have selected the "X" empty part
    function self:ClearBodyPartPreview()
        -- if self.current_bodypart_group ~= nil and self.current_bodypart_name ~= nil then
        if self.current_bodypart_group ~= nil then
            self.puppet.components.charactercreator:SetBodyPart(self.current_bodypart_group, self.current_bodypart_name)
        end
        self.current_bodypart_group = nil
        self.current_bodypart_name = nil
    end

    -- remove the popup when picking a species, skipping the payment too
    function self:OnSwitchSpecies(bodypart, def)
        self:OnBodyPartElementSelected(bodypart, def)
        self:GenerateBodyPartList(bodypart)
        self:ApplyChanges()
        self:CheckForChanges()
    end

    self.FOG_LayoutScrollableColorList = function(self)
        self.color_elements_list:LayoutChildrenInGrid(self.colorlist_cols, 15)
                :LayoutBounds("center", "bottom", self.panel_bg)
        self.colors_scroll:RefreshView()
    end

    -- layout our custom scrolling color list correctly
    local original_GenerateColorList = self.GenerateColorList
    function self:GenerateColorList(colorgroup, ...)
        original_GenerateColorList(self, colorgroup, ...)
        self:FOG_LayoutScrollableColorList()
    end

    -- make speices tooltips always show the descriptions, weather or not theyre locked
    local original_ElementTooltipFn = self.ElementTooltipFn
    function self:ElementTooltipFn(debug_mode, def, is_head, is_locked, is_purchasable, ...)
        return original_ElementTooltipFn(self, debug_mode, def, is_head, false, false, ...)
    end

    -- animate the species override button in like the other buttons
    local original__AnimateIn = self._AnimateIn
    function self:_AnimateIn()
        original__AnimateIn(self)
        self.panel_root:RunUpdater(Updater.Parallel{
            Updater.Series{
                Updater.Wait(0.3),
                Updater.Parallel{
                    Updater.Ease(function(v) self.species_override_button:SetMultColorAlpha(v) end, 0, SPECEIS_OVERRIDE_BUTTON_SELECTED == 1 and 0.4 or 1, 0.6, easing.outQuad),
                }
            },
            Updater.Series{
                Updater.Wait(0.5),
                Updater.Do(function()
                    self.species_override_button:Show()
                end)
            }
        })
        return self
    end

    local original_OnContinueClicked = self.OnContinueClicked
    function self:OnContinueClicked()
        original_OnContinueClicked(self)
        -- apply the species override (selected from the species override button)
        if SPECEIS_OVERRIDE_BUTTON_SELECTED ~= 1 then
            local species = SPECIES_OVERRIDE_SELECTED_TO_SPECIES[SPECEIS_OVERRIDE_BUTTON_SELECTED]
            if self.puppet.components.charactercreator:GetSpecies() == species then
                return
            end

            self.owner.components.charactercreator:_SetSpeciesRaw(species)
            if self.owner.components.charactercreator.use_playerdata_storage then
                GLOBAL.ThePlayerData:SetCharacterCreatorSpecies(self.owner.Network:GetPlayerID(), species)
            end
        end
        self.owner:PushEvent("charactercreator_load") -- to refresh species emotes
        GLOBAL.TheSaveSystem:SaveCharacterForPlayerID(self.owner.Network:GetPlayerID())
    end
end)
