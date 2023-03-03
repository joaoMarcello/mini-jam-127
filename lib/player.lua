local GC = require 'lib.bodyComponent'

local Utils = _G.JM_Utils
local Phys = _G.JM_Love2D_Package.Physics

---@enum Player.States
local States = {
    default = 0,
    idle = 1,
    eat = 2,
    atk = 3,
    dead = 4,
    run = 5
}
--=========================================================================
local keyboard_is_down = love.keyboard.isDown
local math_abs = math.abs

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

---@param self Player
local function move_default(self, dt)
    local body = self.body

    if pressing(self, 'left') and body.speed_x <= 0.0 then
        body:apply_force(-self.acc)
        self.direction = -1
        --
    elseif pressing(self, "right") and body.speed_x >= 0.0 then
        body:apply_force(self.acc)
        self.direction = 1
        --
    elseif math_abs(body.speed_x) ~= 0.0 then
        local dacc = self.dacc * ((pressing(self, 'left')
            or pressing(self, 'right'))
            and 1.5 or 1.0)

        body.dacc_x = dacc
    end

    local last_x = body.x
    body:refresh(Utils:clamp(body.x, 0, SCREEN_WIDTH - body.w))

    if body.x ~= last_x then
        body.speed_x = 0
    end
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

    args.acc = 32 * 12
    args.max_speed = 32 * 6
    args.dacc = 32 * 20

    local obj = GC:new(state, world, args)
    setmetatable(obj, self)
    Player.__constructor__(obj, state, world, args)
    return obj
end

---@param state GameState.Game
function Player:__constructor__(state, world, args)
    self.gamestate = state

    self.key_left = { 'left' }
    self.key_right = { 'right' }
    self.key_down = { 'down' }
    self.key_up = 'w'
    self.key_jump = { 'space', 'up' }
    self.key_attack = 'a'
    self.key_dash = { 'f' }

    self.ox = self.w / 2
    self.oy = self.h / 2

    self.body.max_speed_x = self.max_speed
    self.body.allowed_air_dacc = true

    self.state = States.default

    self.atk_collider = Phys:newBody(world, self.body.x,
        self.body.y - 32,
        64, 64,
        "ghost"
    )

    self.atk_collider.allowed_gravity = false

    self.time_atk = 0.0
    self.time_atk_delay = 0.4

    self.direction = 1

    self.current_movement = move_default
end

function Player:load()

end

function Player:finish()

end

local filter_atk = function(obj, item)
    return item.id == 'fish'
end
function Player:attack()
    if self.time_atk ~= 0.0 then return false end

    self.time_atk = self.time_atk_delay
    local py = self.body.y - self.atk_collider.h + 16
    if self.direction < 0 then
        self.atk_collider:refresh(self.x + self.w / 2 - self.atk_collider.w, py)
    else
        self.atk_collider:refresh(self.x + self.w / 2, py)
    end

    local col = self.atk_collider:check(nil, nil, filter_atk)

    if col.n > 0 then
        ---@type Fish
        local fish = col.items[1]:get_holder()
        fish:hit()
        -- a = nil * 3
    end
end

function Player:jump()
    local body = self.body
    if body.speed_y == 0 then
        body:jump(32 * 2.5, -1)
    end
end

function Player:key_pressed(key)
    local body = self.body

    if pressed(self, 'jump', key) then
        self:jump()
    end

    if pressed(self, 'attack', key) then
        self:attack()
    end
end

function Player:key_released(key)

end

function Player:update(dt)
    local body = self.body

    GC.update(self, dt)

    self.current_movement(self, dt)

    self.time_atk = Utils:clamp(self.time_atk - dt, 0, 20)

    self.x, self.y = Utils:round(body.x), Utils:round(body.y)
end

function Player:my_draw()
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle("fill", self.body:rect())

    love.graphics.setColor(0, 0, 1)
    love.graphics.rectangle("line", self.atk_collider:rect())
end

function Player:draw()
    GC.draw(self, self.my_draw)
end

return Player
