local GC = require 'lib.component'

---@enum Effect.Types
local Types = {
    paft = 1,
    splash = 2,
    vulpt = 3,
    dust = 4
}

local img
local Anima = _G.JM_Anima
local function get_anima(type_)
    if type_ == Types.paft then
        return Anima:new { img = img[type_], speed = 0.2, stop_at_the_end = true }
    elseif type_ == Types.splash then
        return Anima:new { img = img[type_], frames = 7, speed = 0.1, stop_at_the_end = true }
    end
end

---@class Effect : GameComponent
local Eff = setmetatable({}, GC)
Eff.__index = Eff
Eff.Types = Types

function Eff:new(state, args)
    args = args or {}
    args.x = args.x or 0
    args.y = args.y or 0
    args.w = 32
    args.h = 32
    args.y = args.bottom and (args.bottom - args.y) or args.y

    local obj = GC:new(state, args)
    setmetatable(obj, self)
    Eff.__constructor__(obj, state, args)
    return obj
end

---@param state GameState.Game
---@param args any
function Eff:__constructor__(state, args)
    self.gamestate = state
    self:set_draw_order(30)

    self.anima = get_anima(args.type or Types.paft)

    self.remove_cond = args.remove
end

function Eff:load()
    img = img or {
        [Types.paft] = love.graphics.newImage('/data/image/paft.png'),
        [Types.splash] = love.graphics.newImage('/data/image/splash-Sheet.png')
    }
end

function Eff:finish()
    img = nil
end

function Eff:update(dt)
    GC.update(self, dt)
    self.anima:update(dt)

    if self.remove_cond and self.remove_cond()
        or self.anima.time_paused > 0
    then
        self.__remove = true
    end
end

function Eff:my_draw()
    self.anima:draw_rec(self.x, self.y, self.w, self.h)
end

function Eff:draw()
    GC.draw(self, self.my_draw)
end

return Eff
