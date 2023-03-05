local GC = require 'lib.component'

local color = _G.Palette.red

---@class DisplayAtk : GameComponent
local Display = setmetatable({}, GC)
Display.__index = Display

function Display:new(state, args)
    args = args or {}
    args.x = 32 - 8
    args.y = 32 + 6
    args.w = 18 * 6 - 8
    args.h = math.floor(32 / 6) - 1

    local obj = GC:new(state, args)
    setmetatable(obj, self)
    Display.__constructor__(obj, state, args)
    return obj
end

---@param state GameState.Game
function Display:__constructor__(state, args)
    self.gamestate = state

    self.max_width = self.w
end

function Display:load()

end

function Display:finish()

end

function Display:update(dt)
    GC.update(self, dt)

    local player = self.gamestate:game_player()

    local percent = (player.time_atk_delay - player.time_atk)
        / player.time_atk_delay

    self.w = self.max_width * percent
end

function Display:my_draw()
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
end

function Display:draw()
    GC.draw(self, self.my_draw)

    -- local font = _G.JM_Font
    -- font:print(self.percent, self.x, self.y - 20)
end

return Display
