local GC = require 'lib.component'

---@class DisplayPreferred : GameComponent
local Display = setmetatable({}, GC)
Display.__index = Display

---@param state GameState.Game
function Display:new(state, args)
    args = args or {}
    args.w = 32 * 2
    args.h = 32 * 2
    args.x = SCREEN_WIDTH / 2 - args.w / 2
    args.y = 16

    local obj = GC:new(state, args)
    setmetatable(obj, self)
    Display.__constructor__(obj, state, args)
    return obj
end

---@param state GameState.Game
function Display:__constructor__(state, args)
    self.gamestate = state

    self.ox = self.w / 2
    self.oy = self.h / 2
end

function Display:load()

end

function Display:finish()

end

function Display:pulse()

end

function Display:update(dt)
    GC.update(self, dt)

    local player = self.gamestate:game_player()

    if not player:is_dead()
        and player.time_change >= (player.time_change_speed - 1.3)
    then
        self:apply_effect('pulse', { range = 0.07, speed = 0.3 })
    else
        local eff = self.eff_actives and self.eff_actives['pulse']
        if eff then
            self.eff_actives['pulse'] = nil
            eff.__remove = true
        end
    end
end

function Display:my_draw()
    local player = self.gamestate:game_player()
    local color = player.Fish.Colors[player.preferred]
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", self.x, self.y, self.w, self.h)
    love.graphics.setColor(0, 0, 0)
    love.graphics.rectangle("line", self.x, self.y, self.w, self.h)
end

function Display:draw()
    GC.draw(self, self.my_draw)
end

return Display
