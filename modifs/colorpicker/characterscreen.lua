local SelectableItemColor = require "widgets.ftf.selectableitemcolor"
local Image = require "widgets.image"
local easing = require "util.easing"

local DebugBodyPartColorPicker = require "debug.debug_bodypartcolorpicker" 
local UpvalueHacker = require "tools.upvaluehacker"

AddClassPostConstruct("screens.character.characterscreen", function(self)
    local BODY_PART_COLOR_MAP = UpvalueHacker.GetUpvalue(self.OnChangeSubTab, "BODY_PART_COLOR_MAP")

    local function ClonePuppetCOToOwner()
        local owner_gbj_co = self.owner.components.gbj_colorgroupoverride
        local puppet_gbj_co = self.puppet.components.gbj_colorgroupoverride
        
        if owner_gbj_co and puppet_gbj_co then
            owner_gbj_co:CloneComponent(puppet_gbj_co)
        end
    end

    local original_ClearColorPreview = self.ClearColorPreview
    function self:ClearColorPreview()
        local current_colorgroup = self.current_colorgroup
        original_ClearColorPreview(self)
        self.puppet:ApplyColorOverride(current_colorgroup)
    end
    local original_BodyPartPreview = self.BodyPartPreview
    function self:BodyPartPreview(group, name, ...)
        local colorgroup = BODY_PART_COLOR_MAP[group]
        original_BodyPartPreview(self, group, name, ...)
        self.puppet:ApplyColorOverride(colorgroup)
    end
    local original_ClearBodyPartPreview = self.ClearBodyPartPreview
    function self:ClearBodyPartPreview(...)
        local bodypart_group = self.current_bodypart_group
        local colorgroup = BODY_PART_COLOR_MAP[bodypart_group]
        original_ClearBodyPartPreview(self, ...)
        self.puppet:ApplyColorOverride(colorgroup)
    end

    local original_GenerateColorList = self.GenerateColorList
    function self:GenerateColorList(colorgroup, ...)
        local args = {...}
        original_GenerateColorList(self, colorgroup, table.unpack(args))
        
        -- to be used in SetImageColor, and is RGB formatted
        local color_override = GLOBAL.WEBCOLORS.WHITE
        local has_color_override = false

        local gbj_co = self.puppet.components.gbj_colorgroupoverride
        local override = gbj_co and gbj_co:GetSymbolColorOverride(colorgroup)
        if override then
            has_color_override = true
            color_override = GLOBAL.HSBToRGB({
                override.hue-0.5, -- not sure why rn but its just shifted half its range
                override.saturation,
                override.brightness
            })
        end

        -- add custom color selector button to the end of color preset list
        local color_picker_element = self.color_elements_list:AddChild(SelectableItemColor()):SetLocked(false)
        color_picker_element.paintbrush_icon = color_picker_element:AddChild(Image("images/icons_ftf/inventory_wrap.tex")):SetScale(0.4)
        local original_SetImageColor = color_picker_element.SetImageColor
        function color_picker_element:SetImageColor(color, ...)
            local ret = original_SetImageColor(self, color, ...)
            -- adjust painbrush icon to dark/light depending on custom color element's luminance
            -- (see https://en.wikipedia.org/wiki/Luminance_%28relative%29_
            local color_override_luminance = (0.2126*color[1] + 0.7152*color[2] + 0.0722*color[3])
            local light_background = color_override_luminance >= 0.5
            if light_background then
                self.paintbrush_icon:SetMultColor(0,0,0,1)
            else
                self.paintbrush_icon:SetMultColor(1,1,1,1)
            end
            return ret
        end

        -- override SetSelected so this element's selected state cannot be changed
        -- by characterscreen, but only by us
        color_picker_element.SetSelected = function() return end
        function color_picker_element:_SetSelected(is_selected)
            self.selected = is_selected
            self.selection_underline:AlphaTo(self.selected and 1 or 0, self.selected and 0.1 or 0.3, easing.outQuad)
            return self
        end

        color_picker_element:SetImageColor(color_override):_SetSelected(has_color_override)

        color_picker_element:SetOnClick(function()
            GLOBAL.TheFrontEnd:CreateDebugPanel(DebugBodyPartColorPicker(self.puppet, colorgroup, function(color)
                if color then
                    color_picker_element:SetImageColor(GLOBAL.HSBToRGB({
                        color.hue-0.5, -- not sure why rn but its just shifted half its range
                        color.saturation,
                        color.brightness
                    })):_SetSelected(true)
                else
                    color_picker_element
                        :SetImageColor(GLOBAL.WEBCOLORS.WHITE)
                        :_SetSelected(false)
                end
            end)) 
        end)

        -- furry oc generator mod compatibility
        if self.FOG_LayoutScrollableColorList then
            self:FOG_LayoutScrollableColorList()
        else
            self.color_elements_list:LayoutChildrenInGrid(1000, 15)
                :LayoutBounds("center", "bottom", self.panel_bg)
                :Offset(0, 100)
        end
    end

    -- saving
    local original_OnCloseClicked = self.OnCloseClicked
    function self:OnCloseClicked()
        ClonePuppetCOToOwner()
        original_OnCloseClicked(self)
    end
    local original_OnContinueClicked = self.OnContinueClicked
    function self:OnContinueClicked()
        ClonePuppetCOToOwner()
        original_OnContinueClicked(self)
    end
end)
