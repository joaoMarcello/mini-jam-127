local GC = require 'lib.component'

---@class DisplayHP : GameComponent
local Display = setmetatable({}, GC)
Display.__index = Display

function Display:new(state, args)
    args = args or {}
    args.x = 32
    args.y = 16
    args.w = 32
    args.h = 16
    local obj = GC:new(state, args)
    setmetatable(obj, self)
    Display.__constructor__(obj, state, args)
    return obj
end

---@param state GameState.Game
function Display:__constructor__(state, args)
    self.gamestate = state
end

function Display:load()

end

function Display:finish()

end

function Display:update(dt)
    GC.update(self, dt)
end

function Display:my_draw()
    local player = self.gamestate:game_player()

    for i = 1, player.hp_max do
        if i <= player.hp then
            love.graphics.setColor(1, 0, 0)
        else
            love.graphics.setColor(0.2, 0.2, 0.2)
        end

        local px = self.x + (i - 1) * 18
        love.graphics.rectangle("fill", px, self.y, 16, 16)
    end
end

function Display:draw()
    GC.draw(self, self.my_draw)
end

return Display
