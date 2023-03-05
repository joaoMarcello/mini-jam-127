local Component = require "lib.component"

---@type JM.Font.Font
local font

---@class DisplayText : GameComponent
local Display = setmetatable({}, Component)
Display.__index = Display

---@return DisplayText
function Display:new(state, args)
    args = args or {}

    local obj = setmetatable(Component:new(state, args), self)
    Display.__constructor__(obj, state, args)
    return obj
end

function Display:__constructor__(state, args)
    self.text = args.text and tostring(args.text) or "None"
    self.text = "<bold>" .. self.text
    self.text_white = "<color, 1, 1, 1>" .. self.text

    -- self.text_yellow = string.format("<color, %.2f, %.2f, %.2f>",
    --         122 / 255,
    --         130 / 255,
    --         152 / 255) .. self.text

    local text_obj = font:generate_phrase(self.text, self.x, self.y, math.huge, "left")
    local text_w = text_obj:width(text_obj:get_lines(self.x))

    self.x = self.x - text_w / 2
    self.acumulator = 0
    self.time = 0

    self:set_draw_order(15)
end

function Display:load()
    font = _G.FONT_GUI
end

function Display:finish()

end

function Display:update(dt)
    Component.update(self, dt)

    self.time = self.time + dt

    local last = self.y

    if self.acumulator <= 32 or true then
        self.y = self.y - 32 * 3 * dt
        self.acumulator = self.acumulator + math.abs(last - self.y)
    end

    if self.time > 1.0 then
        self.__remove = true
    end
end

function Display:my_draw()
    -- font:print(self.text_yellow, self.x - 1, self.y)
    -- font:print(self.text_yellow, self.x, self.y - 1)
    font:print(self.text, self.x + 1, self.y + 1)
    font:print(self.text_white, self.x, self.y)
end

function Display:draw()
    Component.draw(self, self.my_draw)
end

return Display
