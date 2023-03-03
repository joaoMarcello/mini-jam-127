local GC = require 'lib.bodyComponent'

---@enum Fish.Types
local Types = {
    red = 1,
    green = 2,
    blue = 3
}
Types[1] = Types.red
Types[2] = Types.green
Types[3] = Types.blue

---@enum Fish.colors
local Colors = {
    [Types.red] = { 1, 0, 0 },
    [Types.green] = { 0, 1, 0 },
    [Types.blue] = { 0, 0, 1 },
}

---@param self Fish
local function speed_y_changed_dir(self)
    -- self.body.type = 1
    -- self.body.mass = self.world.default_mass * 0.6
end

---@param self Fish
local function ground_touch(self)
    if self.__touch then return false end
    local body = self.body
    self.__touch = true
    self.acc = 32
    self.body.speed_x = self.body.speed_x * 0.2
    self.body.mass = self.world.default_mass
    self.body.type = 4
    self.body:jump(32 / 2)
    local nw, nh = body.w * 0.8, body.h * 0.8
    self.body:refresh(body.x + body.w / 2 - nw / 2,
        body:bottom() - nh,
        nw, nh
    )
    self:apply_effect(body:direction_x() > 0 and "clockWise" or "counterClockWise")
end

---@class Fish : BodyComponent
local Fish = setmetatable({}, GC)
Fish.__index = Fish
Fish.Types = Types
Fish.Colors = Colors

function Fish:new(state, world, args)
    args = args or {}
    args.type = "dynamic"
    args.direction = args.direction or 1
    local dir = args.direction
    args.y = args.y or (32 * 2)
    args.w = 45
    args.h = 32
    args.x = args.x or (dir > 0 and (-args.w) or SCREEN_WIDTH)
    args.y = args.bottom and (args.bottom - args.h) or args.y

    local obj = GC:new(state, world, args)
    setmetatable(obj, self)
    Fish.__constructor__(obj, state, world, args)
    return obj
end

---@param state GameState.Game
function Fish:__constructor__(state, world, args)
    self.gamestate = state

    self.acc = args.acc or (32 * 3)
    self.body.mass = args.mass or (self.body.mass * 0.35)
    -- self.body.bouncing_y = 0.4
    self.body.allowed_air_dacc = false

    self.body.id = 'fish'
    self.body:set_holder(self)

    self.__touch = false
    self.body:on_event("speed_y_change_direction", speed_y_changed_dir, self)
    self.body:on_event("ground_touch", ground_touch, self)

    self.ox = self.w / 2
    self.oy = self.h / 2

    self.direction = args.direction or (-1)

    self.type = args.specie or Types.red

    self.time = 0.0

    if args.delay then
        self.delay = args.delay
        self.body.is_enabled = false
    end
end

function Fish:load()

end

function Fish:finish()

end

function Fish:collision_player()
    local player = self.gamestate:game_player()
    local bd = player.body
    return self.body:check_collision(bd:rect()) and not player:is_dead()
end

function Fish:hit()
    if not self.hitted then
        self.hitted = true
        self:apply_effect("counterClockWise", { speed = 0.7 })
        self.body:jump(32 * 2.5)
        self.acc = self.acc * 2
    end
end

function Fish:update(dt)
    GC.update(self, dt)

    if self.delay then
        self.delay = self.delay - dt
        if self.delay <= 0 then
            self.delay = nil
            self.body.is_enabled = true
        else
            return
        end
    end

    local body = self.body
    local game = self.gamestate

    if not body.ground then
        body:apply_force(self.acc * self.direction)
    end

    -- if body.speed_x == 0 and body.ground then
    --     self.time = self.time + dt

    --     if self.time >= 0.5 and not self.__flick then
    --         self.__flick = self:apply_effect("flickering", { speed = 0.07 })
    --     elseif self.time >= 1.5 then
    --         self.__remove = true
    --         return
    --     end
    -- end

    if self:collision_player() and not self.hitted then
        local player = game:game_player()

        if player:is_invencible() then
            self:hit()
            --
        elseif player.preferred == self.type then
            game:game_add_score(100)
            self.__remove = true
        else
            player:damage(self)
            self.__remove = not player:is_dead()
            if player:is_dead() then
                local components = game:game_components()
                for i = 1, #components do
                    local obj = components[i]
                    if obj.body and obj.body.id == 'fish' then
                        ---@type Fish
                        local obj = obj
                        obj.is_enable = false
                        obj.body.is_enabled = false
                    end
                end
            end
        end
    end

    local camera = game.camera
    if body.y > SCREEN_HEIGHT + 32 and
        not camera:rect_is_on_view(body:rect())
    then
        self.__remove = true
        return
    end
end

function Fish:my_draw()
    love.graphics.setColor(Colors[self.type])
    love.graphics.rectangle("fill", self.body:rect())
end

function Fish:draw()
    GC.draw(self, self.my_draw)
end

return Fish
