local GUI_GC = require "jm-love2d-package.modules.gui.component"

---@type JM.Font.Font|nil
local font

local Color = {
    active = { 0.3, 0.3, 0.3, 1 },
    inactive = { 0, 0, 0, 0 }
}

---@class Button2 : JM.GUI.Component
local Button = setmetatable({}, GUI_GC)
Button.__index = Button

---@return Button2
function Button:new(state, args)
    args = args or {}

    args.y = args.y or (32 * 7)
    args.w = 32 * 6
    args.h = 32 * 2
    args.x = args.x or (SCREEN_WIDTH / 2 - args.w / 2)

    local obj = GUI_GC:new(args)
    setmetatable(obj, self)
    Button.__constructor__(obj, state, args)
    return obj
end

function Button:__constructor__(state, args)
    self.text = "<color, 1, 1, 1>" .. (args.text or "Start")

    self.y = args.y
    self.w = args.w
    self.x = args.x or (SCREEN_WIDTH / 2 - self.w / 2)

    self.phrase = font and font:generate_phrase(self.text, self.x, self.y, self.x + self.w, "center")

    self.text_height = self.phrase:text_height(self.phrase:get_lines(self.x))
    self.h = self.text_height + 6
    self.text_height = self.text_height - (font and font.__line_space or 0)


    self.gamestate = state

    self.__color = Color.inactive

    ---@type JM.Effect|nil
    self.eff_pulse = nil

    self.pressed = false

    self:on_event("gained_focus", function()
        -- if self.eff_pulse then self.eff_pulse.__remove = true end
        -- self.eff_pulse = self:apply_effect("pulse", { speed = 0.4, range = 0.03 })
        self.__color = Color.active
    end)

    self:on_event("lose_focus", function()
        -- if self.eff_pulse then self.eff_pulse.__remove = true end
        -- self.eff_pulse = nil
        self.__color = Color.inactive
    end)
end

---@param new_font JM.Font.Font
function Button:load(new_font)
    font = new_font
end

function Button:finish()
    font = nil
end

function Button:update(dt)
    GUI_GC.update(self, dt)
end

function Button:__custom_draw__()
    love.graphics.setColor(self.__color)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

    love.graphics.setColor(50 / 255, 43 / 255, 40 / 255)
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h)

    self.phrase:draw(self.x, self.y + self.h / 2 - (self.text_height) / 2, "center")
end

return Button
