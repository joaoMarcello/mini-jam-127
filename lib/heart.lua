local GC = require 'lib.bodyComponent'
local DisplayText = require 'lib.displayText'

---@class Heart : BodyComponent
local Heart = setmetatable({}, GC)
Heart.__index = Heart

function Heart:new(state, world, args)
    args = args or {}
    args.w = 32
    args.h = 32
    args.y = -32
    args.x = math.random(2, 11) * 32
    args.type = "dynamic"

    local obj = GC:new(state, world, args)
    setmetatable(obj, self)
    Heart.__constructor__(obj, state, world, args)
    return obj
end

---@param state GameState.Game
function Heart:__constructor__(state, world, args)
    self.gamestate = state

    self.body.mass = self.world.default_mass * 0.1
    self.body.bouncing_y = 0.7
    self.body.max_speed_y = 32 * 2

    self.time = 0
    self.duration = 10

    self.time_jump = 0
end

function Heart:load()
    DisplayText:load()
end

function Heart:finish()
    DisplayText:finish()
end

function Heart:update(dt)
    GC.update(self, dt)

    local body = self.body
    if body.speed_y == 0 then
        self.time = self.time + dt

        if self.time >= self.duration - 1.6 then
            self:apply_effect('flickering', { speed = 0.07 })
        end

        if self.time >= self.duration then
            self.__remove = true
            return
        end

        body.mass = self.world.default_mass * 0.2
        body.max_speed_y = nil

        self.time_jump = self.time_jump + dt
        if self.time_jump >= 3 and self.body.speed_y == 0 then
            self.time_jump = 0

            if self.body.speed_y == 0 then
                body:jump(16, -1)
            end
        end
    end

    local player = self.gamestate:game_player()
    if not player:is_dead() and body:check_collision(player.body:rect()) then
        local r = player:increase_hp()
        if r then
            self.gamestate:game_add_component(DisplayText:new(self.gamestate, {
                text = "+1 HP",
                y = player.y,
                x = player.x + player.w / 2
            }))
        else
            local game = self.gamestate
            game:game_add_score(500)
            game:game_add_component(DisplayText:new(game, {
                text = "500",
                y = player.y,
                x = player.x + player.w / 2
            }))
        end
        self.__remove = true
    end
end

function Heart:my_draw()
    love.graphics.setColor(1, 0, 0)
    love.graphics.rectangle('fill', self.body:rect())

    -- local font = _G.JM_Font.current
    -- font:print(tostring(self.body.speed_y), self.x, self.y - 20)
end

function Heart:draw()
    GC.draw(self, self.my_draw)
end

return Heart
