local GC = require 'lib.bodyComponent'
local Fish = require 'lib.fish'
local Effect = require 'lib.effects'

local Utils = _G.JM_Utils
local Phys = _G.JM_Love2D_Package.Physics

---@enum Player.States
local States = {
    default = 0,
    idle = 1,
    eat = 2,
    atk = 3,
    dead = 4,
    run = 5,
    damage = 6,
    jump = 7
}

local img
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
            or (field[3] and keyboard_is_down(field[3]))
    end
end

local function pressed(self, key, key_pressed)
    local index = "key_" .. key
    local field = self[index]
    if not field then return nil end

    if type(field) == "string" then
        return key_pressed == field
    else
        return key_pressed == field[1] or key_pressed == field[2] or key_pressed == field[3]
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

    self:change_preferred(dt)

    self.time_atk = Utils:clamp(self.time_atk - dt, 0, 20)

    if self.time_invicible ~= 0 then
        self.time_invicible = Utils:clamp(self.time_invicible - dt, 0, self.invicible_duration)
    end
end

---@param self Player
local function move_atk(self, dt)
    move_default(self, dt)
    self.direction = self.last_dir or 1

    if self.cur_anima:time_updating() >= 0.2 then
        self:set_state(States.default)
    end
end

---@param self Player
local function move_dead(self, dt)
    local body = self.body
    body.speed_x = 0
    body.acc_x = 0
    self.time_death = self.time_death + dt
end
--=========================================================================

---@class Player : BodyComponent
local Player = setmetatable({}, GC)
Player.__index = Player
Player.Fish = Fish

function Player:new(state, world, args)
    args = args or {}
    args.type = "dynamic"
    args.x = args.x or (32 * 5)
    args.y = args.y or (32 * 2)
    args.w = 40
    args.h = 58
    args.y = args.bottom and (args.bottom - args.h) or args.y

    args.acc = 32 * 12
    args.max_speed = 32 * 7
    args.dacc = 32 * 20

    local obj = GC:new(state, world, args)
    setmetatable(obj, self)
    Player.__constructor__(obj, state, world, args)
    return obj
end

---@param state GameState.Game
function Player:__constructor__(state, world, args)
    self.gamestate = state

    self.key_left = { 'left', 'a' }
    self.key_right = { 'right', 'd' }
    self.key_down = { 'down', 's' }
    self.key_up = { 'w', 'up' }
    self.key_jump = { 'space', 'up', 'w' }
    self.key_attack = { 'e', 'q', 'f' }

    self.ox = self.w / 2
    self.oy = self.h / 2

    self.body.max_speed_x = self.max_speed
    self.body.allowed_air_dacc = true


    self.atk_collider = Phys:newBody(world, self.body.x,
        self.body.y - 32,
        64 + 64 + 16, 64 + 32,
        "ghost"
    )

    self:set_update_order(10)

    self.atk_collider.allowed_gravity = false

    self.time_atk = 0.0
    self.time_atk_delay = 0.38
    self.time_change = -2
    self.time_change_speed = math.random(4, 7)

    self.time_invicible = 0.0
    self.invicible_duration = 1 --0.8

    self.hp_max = 7
    self.hp = self.hp_max

    self.direction = 1

    self.preferred = math.random(1, 3)

    self.current_movement = move_default

    local Anima = _G.JM_Anima
    self.animas = {
        [States.default] = Anima:new { img = img[States.default] },
        [States.atk] = Anima:new { img = img[States.atk] },
        [States.run] = Anima:new { img = img[States.run] },
        [States.jump] = Anima:new { img = img[States.jump] },
        [States.dead] = Anima:new { img = img[States.dead] },
    }

    self.cur_anima = self.animas[States.atk]
    self.cur_anima:apply_effect('jelly', { speed = 0.6, range = 0.015 })

    ---@type Player.States|any
    self.state = nil --States.default
    self:set_state(States.default)
end

function Player:load()
    img = img or {
        [States.default] = love.graphics.newImage('/data/image/cat-idle.png'),
        [States.atk] = love.graphics.newImage('/data/image/cat-atk.png'),
        [States.run] = love.graphics.newImage('/data/image/cat-run.png'),
        [States.jump] = love.graphics.newImage('/data/image/cat-jump.png'),
        [States.dead] = love.graphics.newImage('/data/image/cat-die.png'),
    }

    Effect:load()
end

function Player:finish()
    img = nil
    Effect:finish()
end

local filter_atk = function(obj, item)
    return item.id == 'fish'
end

function Player:attack()
    if self.time_atk ~= 0.0 then return false end

    local body = self.body
    self.time_atk = self.time_atk_delay
    local py = body.y + body.h / 2 - self.atk_collider.h

    self.atk_collider:refresh(self.x + self.w / 2 - self.atk_collider.w / 2, py)

    local col  = self.atk_collider:check(nil, nil, filter_atk)
    local game = self.gamestate
    if col.n > 0 then
        local hit = false
        for i = 1, col.n do
            ---@type Fish
            local fish = col.items[i]:get_holder()
            local r = fish:hit()
            if r and not hit then hit = true end
        end

        if hit then
            self.gamestate:pause(0.1)
            collectgarbage("step")
            _G.PLAY_SFX("hit")
        end
    end

    self:set_state(States.atk)
    -- self:pulse()
end

function Player:pulse()
    self:apply_effect('pulse', { duration = 0.6, speed = 0.3 }, true)
end

function Player:increase_hp()
    local last = self.hp
    self.hp = Utils:clamp(self.hp + 1, 0, self.hp_max)
    return self.hp ~= last
end

---@param state Player.States
function Player:set_state(state)
    if state == self.state then return end
    local last = self.state
    self.state = state

    if state == States.atk then
        self.current_movement = move_atk
        self.last_dir = self.direction
        self.animas[States.atk]:reset()
        --
    elseif state == States.default then
        self.current_movement = move_default
        --
    elseif state == States.dead then
        local body = self.body
        body.mass = self.world.default_mass * 0.6
        body.speed_y = 0
        body:jump(32 * 4)
        body.type = 4
        self.time_death = 0.0
        -- self:set_draw_order(20)
        self.current_movement = move_dead

        self.gamestate.camera:shake_in_x(0.3, 2, nil, 0.1)
        self.gamestate.camera:shake_in_y(0.3, 5, nil, 0.15)
        self.gamestate.camera.shake_rad_y = math.pi
    end

    self:select_anima()
end

function Player:is_dead()
    return self.state == States.dead or self.hp <= 0
end

function Player:is_invencible()
    return self.time_invicible ~= 0
end

---@param obj Fish|any
function Player:damage(obj)
    if self:is_dead() or self.time_invicible ~= 0.0 then return false end

    self.hp = Utils:clamp(self.hp - 1, 0, self.hp_max)
    self.time_invicible = self.invicible_duration

    if self.hp == 0 then
        self:set_state(States.dead)
    end
    self.hit_obj = obj
    self.gamestate:pause(self:is_dead() and 1.3 or 0.2, function(dt)
        self.gamestate.camera:update(dt)
    end)
    return true
end

function Player:jump()
    local body = self.body
    if body.speed_y == 0 then
        body:jump(32 * 3, -1)
    end
end

function Player:change_preferred(dt)
    self.time_change = self.time_change + dt

    if self.time_change >= self.time_change_speed then
        self.time_change = self.time_change - self.time_change_speed

        local time_game = self.gamestate:game_get_time_game()

        self.time_change_speed = time_game <= 100 and math.random(5, 8)
            or math.random(4, 7)

        local last = self.preferred
        self.preferred = math.random(1, 3)
        if self.preferred == last then
            self.preferred = Utils:clamp((last + 1) % 3, 1, 3)
        end
    end
end

function Player:key_pressed(key)
    local body = self.body

    if self.state == States.default then
        if pressed(self, 'jump', key) then
            self:jump()
        end

        if pressed(self, 'attack', key) then
            self:attack()
        end
    end
end

function Player:key_released(key)
    if self.state == States.default then
        if pressed(self, 'jump', key) and self.body.speed_y < 0 then
            self.body.speed_y = self.body.speed_y * 0.5
        end
    end
end

function Player:select_anima()
    local next
    local Anima = _G.JM_Anima

    if self.state == States.dead then
        next = self.animas[States.dead]
        --
    elseif self.state == States.atk then
        next = self.animas[States.atk]
        --
    else
        if self.body.speed_y ~= 0 then
            next = self.animas[States.jump]
        elseif self.body.speed_x == 0 then
            next = self.animas[States.default]
        else
            next = self.animas[States.run]
        end
    end

    self.cur_anima = JM_Anima.change_animation(self.cur_anima, next)
end

function Player:update(dt)
    local body = self.body

    GC.update(self, dt)

    self.current_movement(self, dt)

    if self.time_invicible ~= 0 and not self:is_dead() then
        self:apply_effect('flickering', { speed = 0.06 })
    else
        local eff = self.eff_actives and self.eff_actives['flickering']
        if eff then
            eff.__remove = true
            self.eff_actives['flickering'] = nil
            self:set_visible(true)
        end
    end

    self:select_anima()
    self.cur_anima:update(dt)
    self.cur_anima:set_flip_x(self.direction < 0 and true or false)
    self.x, self.y = Utils:round(body.x), Utils:round(body.y)
end

function Player:my_draw()
    -- love.graphics.setColor(0, 0, 1)
    -- love.graphics.rectangle("line", self.atk_collider:rect())

    self.cur_anima:draw_rec(self.x, self.y, self.w, self.h)

    if self.gamestate.time_pause and self.hit_obj and not self:is_dead() then
        self.hit_obj:draw()
    else
        self.hit_obj = nil
    end

    -- love.graphics.setColor(1, 0, 0)
    -- love.graphics.rectangle("line", self.body:rect())
end

function Player:draw()
    GC.draw(self, self.my_draw)

    -- local font = _G.JM_Font
    -- font:print(self.hp, self.x, self.y - 20)
end

return Player
