local GC = require 'lib.bodyComponent'

---@param self Fish
local function speed_y_changed_dir(self)
    self.body.type = 1
    self.body.mass = self.world.default_mass * 0.6
end

---@param self Fish
local function ground_touch(self)
    self.__touch = true
    self.acc = 32
    self.body.speed_x = self.body.speed_x * 0.9
end

---@class Fish : BodyComponent
local Fish = setmetatable({}, GC)
Fish.__index = Fish

function Fish:new(state, world, args)
    args = args or {}
    args.type = "ghost"
    args.x = args.x or (32 * 5)
    args.y = args.y or (32 * 2)
    args.w = 45
    args.h = 32
    args.y = args.bottom and (args.bottom - args.h) or args.y

    local obj = GC:new(state, world, args)
    setmetatable(obj, self)
    Fish.__constructor__(obj, state, world, args)
    return obj
end

---@param state GameState.Game
function Fish:__constructor__(state, world, args)
    self.gamestate = state

    self.acc = 32 * 3
    self.body.mass = self.body.mass * 0.4
    self.body.bouncing_y = 0.4
    self.body.allowed_air_dacc = false

    self.__touch = false
    self.body:on_event("speed_y_change_direction", speed_y_changed_dir, self)
    self.body:on_event("ground_touch", ground_touch, self)

    self.ox = self.w / 2
    self.oy = self.h / 2

    self.time = 0.0
end

function Fish:load()

end

function Fish:finish()

end

function Fish:update(dt)
    GC.update(self, dt)
    local body = self.body

    if not body.ground then
        body:apply_force(self.acc)
    end

    if body.speed_x == 0 and body.ground then
        self.time = self.time + dt

        if self.time >= 1.0 and not self.__flick then
            self.__flick = self:apply_effect("flickering", { speed = 0.07 })
        elseif self.time >= 3.0 then
            self.__remove = true
            return
        end
    end

    local camera = self.gamestate.camera
    if not camera:rect_is_on_view(body:rect()) then
        self.__remove = true
    end
end

function Fish:my_draw()
    love.graphics.setColor(0, 0, 1)
    love.graphics.rectangle("fill", self.body:rect())
end

function Fish:draw()
    GC.draw(self, self.my_draw)
end

return Fish
