local DebugNodes = require "dbui.debug_nodes"

local DebugBodyPartColorPicker = Class(DebugNodes.DebugNode, function(self, inst, colorgroup, cb)
    DebugNodes.DebugNode._ctor(self, "DebugBodyPartColorPicker")
    self.inst = inst
    self.colorgroup = colorgroup
    self.cb = cb
    self.is_default_color = false

    local gbj_co = inst.components.gbj_colorgroupoverride
    local override = gbj_co and gbj_co:GetSymbolColorOverride(colorgroup)
    if override then
        self.hue = override.hue
        self.saturation = override.saturation
        self.brightness = override.brightness
    else
        self:ResetColors()
    end

    self:UpdateColors()
end)
DebugBodyPartColorPicker.PANEL_WIDTH = 500
DebugBodyPartColorPicker.PANEL_HEIGHT = 200

function DebugBodyPartColorPicker:ResetColors()
    self.hue = 0
    self.saturation = 1
    self.brightness = 1
    self.is_default_color = true
end

function DebugBodyPartColorPicker:UpdateColors()
    self.inst.components.charactercreator:SetSymbolColorShift(
        self.colorgroup,
        self.hue,
        self.saturation,
        self.brightness
    )
end

function DebugBodyPartColorPicker:SaveColors()
    local gbj_co = self.inst.components.gbj_colorgroupoverride
    if not gbj_co then return end

    if self.is_default_color then
        gbj_co:ClearSymbolColorOverride(self.colorgroup)
    else
        gbj_co:SetSymbolColorOverride(
            self.colorgroup,
            self.hue,
            self.saturation,
            self.brightness
        )
    end

    if self.inst.Network then
        TheSaveSystem:SaveCharacterForPlayerID(self.inst.Network:GetPlayerID())
    end
end

function DebugBodyPartColorPicker:RenderPanel(ui, panel)
    ui:Text("Apply custom color for ")
    ui:SameLineWithSpace()
    ui:TextColored(WEBCOLORS.PALETURQUOISE, self.colorgroup)

    local dirty = false

    local hue_changed, new_hue = ui:SliderFloat("Hue", self.hue, 0, 1)
    if hue_changed then
        dirty = true
        self.hue = new_hue
    end
    local saturation_changed, new_saturation = ui:SliderFloat("Saturation", self.saturation, 0, 10)
    if saturation_changed then
        dirty = true
        self.saturation = new_saturation
    end
    local brightness_changed, new_brightness = ui:SliderFloat("Brightness", self.brightness, 0, 10)
    if brightness_changed then
        dirty = true
        self.brightness = new_brightness
    end

    if dirty then
        self.is_default_color = false
        self:UpdateColors()
    end

    if (ui:Button("Reset")) then
        self:ResetColors()
        self:UpdateColors()
    end
    ui:SameLineWithSpace()
    if (ui:Button("Save")) then
        self:SaveColors()

        if self.cb then
            if not self.is_default_color then
                self.cb({hue=self.hue, saturation=self.saturation, brightness=self.brightness})
            else
                self.cb()
            end
        end

        panel.show = false -- close current panel
    end
end

DebugNodes.DebugBodyPartColorPicker = DebugBodyPartColorPicker
return DebugBodyPartColorPicker
