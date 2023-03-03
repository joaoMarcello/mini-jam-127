local GC = require 'lib.bodyComponent'


---@enum Player.States
local States = {
    idle = 1,
    eat = 2,
    atk = 3,
    dead = 4,
    run = 5
}
--=========================================================================
local keyboard_is_down = love.keyboard.isDown

local function pressing(self, key)
    key = "key_" .. key
    local field = self[key]
    if not field then return nil end

    if type(field) == "string" then
        return keyboard_is_down(field)
    else
        return keyboard_is_down(field[1])
            or (field[2] and keyboard_is_down(field[2]))
    end
end

local function pressed(self, key, key_pressed)
    local index = "key_" .. key
    local field = self[index]
    if not field then return nil end

    if type(field) == "string" then
        return key_pressed == field
    else
        return key_pressed == field[1] or key_pressed == field[2]
    end
end

local function collision(x1, y1, w1, h1, x2, y2, w2, h2)
    return x1 + w1 > x2
        and x1 < x2 + w2
        and y1 + h1 > y2
        and y1 < y2 + h2
end
--=========================================================================

---@class Player : BodyComponent
local Player = setmetatable({}, GC)
Player.__index = Player

function Player:new(state, world, args)
    args = args or {}
    args.type = "dynamic"
    args.x = args.x or (32 * 5)
    args.y = args.y or (32 * 2)
    args.w = 45
    args.h = 64
    args.y = args.bottom and (args.bottom - args.h) or args.y

    local obj = GC:new(state, world, args)
    setmetatable(obj, self)
    Player.__constructor__(obj, state, world, args)
    return obj
end

function Player:__constructor__(state, world, args)
    self.gamestate = state

    self.key_left = { 'left' }
    self.key_right = { 'right' }
    self.key_down = { 'down' }
    self.key_up = 'w'
    self.key_jump = { 'space', 'up' }
    self.key_attack = 'u'
    self.key_dash = { 'f' }
end

function Player:load()

end

function Player:finish()

end

function Player:update(dt)
    GC.update(self, dt)
    self.x, self.y = self.body.x, self.body.y
end

function Player:my_draw()
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", self.body:rect())
end

function Player:draw()
    GC.draw(self, self.my_draw)
end

return Player
