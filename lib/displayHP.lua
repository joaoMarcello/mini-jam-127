local GC = require 'lib.component'

local img

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

    local hp_max = state:game_player().hp_max

    self.hearts = {}
    for i = 1, hp_max do
        self.hearts[i] = _G.JM_Anima:new { img = img, frames = 2 }
    end
end

function Display:load()
    img = img or love.graphics.newImage('/data/image/heart-Sheet.png')
end

function Display:finish()
    img = nil
end

function Display:update(dt)
    GC.update(self, dt)
end

function Display:my_draw()
    local player = self.gamestate:game_player()

    for i = 1, player.hp_max do
        ---@type JM.Anima
        local heart = self.hearts[i]

        if i <= player.hp then
            love.graphics.setColor(_G.Palette.red)
            heart.current_frame = 1
        else
            love.graphics.setColor(_G.Palette.purple)
            heart.current_frame = 2
        end

        local px = self.x + (i - 1) * 18

        ---@type JM.Anima
        local heart = self.hearts[i]
        heart:draw(px, self.y + 8)
        --love.graphics.rectangle("fill", px, self.y, 16, 16)
    end
end

function Display:draw()
    GC.draw(self, self.my_draw)
end

return Display
