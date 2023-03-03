local GUI_GC = require "jm-love2d-package.modules.gui.component"

---@type JM.Font.Font|nil
local font

---@type love.Image|any
local img

---@class Button : JM.GUI.Component
local Button = setmetatable({}, GUI_GC)
Button.__index = Button

---@return Button
function Button:new(state, args)
    args = args or {}

    args.x = args.x or (32 * 3)
    args.y = args.y or (32 * 7)
    args.w = 32 * 5
    args.h = 32 * 2

    local obj = GUI_GC:new(args)
    setmetatable(obj, self)
    Button.__constructor__(obj, state, args)
    return obj
end

function Button:__constructor__(state, args)
    self.text = args.text or "Play again"
    self.x = args.x or (32 * 3)
    self.y = args.y or (32 * 7)
    self.w = 32 * 5
    self.h = 32 * 2

    self.gamestate = state

    self.__color = { 1, 1, 0 }

    ---@type JM.Effect|nil
    self.eff_pulse = nil

    self.pressed = false

    self:on_event("gained_focus", function()
        if self.eff_pulse then self.eff_pulse.__remove = true end
        self.eff_pulse = self:apply_effect("pulse", { speed = 0.4, range = 0.03 })
    end)

    self:on_event("lose_focus", function()
        if self.eff_pulse then self.eff_pulse.__remove = true end
        self.eff_pulse = nil
    end)

    self.anima = _G.JM_Anima:new {
        img = img,
        max_filter = 'linear'
    }

    self.anima:set_size(self.w, self.h)
end

---@param new_font JM.Font.Font
function Button:load(new_font)
    font = new_font
    img = img or love.graphics.newImage('/data/image/button.png')
end

function Button:finish()
    font = nil
    local r = img and img:release()
    img = nil
end

function Button:update(dt)
    GUI_GC.update(self, dt)
end

function Button:__custom_draw__()
    -- love.graphics.setColor(self.__color)
    -- love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)

    -- love.graphics.setColor(50 / 255, 43 / 255, 40 / 255)
    -- love.graphics.rectangle("line", self.x, self.y, self.w, self.h)

    self.anima:draw(self.x + self.w / 2, self.y + self.h / 2)

    if font then
        local obj = font:generate_phrase(self.text, self.x, self.y, self.x + self.w, "center")

        font:push()
        font:set_font_size(16)
        obj:draw(self.x, self.y + self.h / 2 - obj:text_height(obj:get_lines(self.x)) / 2 + font.__line_space / 2,
            "center", self.x + self.w)
        font:pop()
    end
end

return Button
