local MouseIcon = require "scripts.mouseIcon2"
local Affectable = _G.JM_Affectable

---@enum MouseIcon.States
local States = {
    shock = 1,
    grab = 2,
    point = 3,
    prepare = 4,
    cool = 5
}

local imgs

---@class MouseIcon : JM.Template.Affectable
local Icon = setmetatable({}, Affectable)
Icon.__index = Icon
Icon.States = States

function Icon:new(state, args)
    local obj = Affectable:new()
    setmetatable(obj, self)
    Icon.__constructor__(obj, state, args)
    return obj
end

---@param state GameState.Game
function Icon:__constructor__(state, args)
    self.gamestate = state

    self.x, self.y = state:get_mouse_position()

    self.dx = 0
    self.dy = 0

    self.w = 16
    self.h = 16

    self.state = States.prepare

    self.mouseIcon = MouseIcon:new(state)

    local Anima = _G.JM_Anima

    self.anima = {
        [States.point] = Anima:new { img = imgs[States.point] },
        [States.grab] = Anima:new { img = imgs[States.grab] },
        [States.prepare] = Anima:new { img = imgs[States.prepare] },
        [States.shock] = Anima:new { img = imgs[States.shock] },
        [States.cool] = Anima:new { img = imgs[States.cool] },
    }

    local point = self.anima[States.point]
    point:apply_effect("float", { range = 3, speed = 0.6 })
    point:apply_effect("pointing", { range = 3, speed = 0.6 })

    local cool = self.anima[States.cool]
    cool:apply_effect("float", { range = 3, speed = 0.6 })

    local prepare = self.anima[States.prepare]
    -- prepare:set_size(nil, 45)
    -- prepare.img:setFilter("linear", 'linear')

    self.cur_anima = self.anima[self.state]

    for _, a in pairs(self.anima) do
        a:set_size(64, 64)
    end
end

function Icon:load()
    MouseIcon:load()

    imgs = imgs or {
            [States.point] = love.graphics.newImage('/data/image/glove point.png'),
            [States.prepare] = love.graphics.newImage('/data/image/glove prepare.png'),
            [States.grab] = love.graphics.newImage('/data/image/glove grab.png'),
            [States.shock] = love.graphics.newImage('/data/image/glove shock.png'),
            [States.cool] = love.graphics.newImage('/data/image/glove cool.png'),
        }
end

function Icon:finish()
    MouseIcon:finish()
    imgs = nil
end

---@param state MouseIcon.States
function Icon:set_state(state)
    if self.state == state then return false end

    local last = self.state
    self.state = state

    if state == States.shock then
        local eff = self:apply_effect("earthquake", { random = true, range_x = 5, range_y = 5, duration = 0.6 })

        eff:set_final_action(function()
            self:set_state(States.prepare)
        end)
        --
        --
    elseif state == States.grab then
        self.mouseIcon.x = self.x
        self.mouseIcon.y = self.y + self.h + 32
        --
    elseif state == States.point then
        self.x = self.mouseIcon.x

        self.y = self.mouseIcon.y
        --
    elseif state == States.prepare then
        if last ~= States.shock and (last ~= States.point) then
            local panel = self.gamestate:game_get_panel()

            self.x = self.mouseIcon.x

            self.y = self.mouseIcon.y

            if self.mouseIcon.y > panel.y + panel.h - 64 then
                self.y = self.mouseIcon.y - 32
            else
                -- self.y = self.mouseIcon.y - self.h / 2
            end

            if self:is_in_point_mode() then
                self:set_state(States.point)
            end
        end
    end

    return true
end

function Icon:get_color_state()
    local Utils = _G.JM_Utils

    if self.state == States.prepare then
        return Utils:get_rgba(1, 1, 1, 1)
    elseif self.state == States.point then
        return Utils:get_rgba(0, 0, 0, 1)
    elseif self.state == States.grab then
        return Utils:get_rgba(0, 0, 1, 1)
    elseif self.state == States.shock then
        return Utils:get_rgba(1, 1, 0, 1)
    elseif self.state == States.cool then
        return Utils:get_rgba2(1, 0, 0, 1)
    end
end

function Icon:is_in_point_mode()
    if self.state == States.shock then return false end

    local panel = self.gamestate:game_get_panel()

    if panel:is_complete() or panel:is_locked()
        or self.gamestate:game_get_timer():time_is_up()
    then
        return false
    end

    for i = 1, panel.n_wires do
        ---@type Game.Component.Wire
        local wire = panel.wires_by_id[i]

        if wire and wire.plug:is_been_pointed() then
            return true
        end
    end

    return false
end

function Icon:stay_on_bounds()
    local camera = self.gamestate.camera

    if self.x < camera.x then self.x = camera.x end
    if self.y < 0 then self.y = 0 end
    if self.y + self.h > SCREEN_HEIGHT then self.y = SCREEN_HEIGHT - self.h end
    local right = camera.x + 32 * 15
    if self.x + self.w > right then
        self.x = right - self.w
    end
end

function Icon:mouse_moved(x, y, dx, dy)
    local camera = self.gamestate.camera

    self.dx = (dx / camera.desired_scale)
    self.dy = (dy / camera.desired_scale)

    self.x, self.y = self.x + self.dx, self.y + self.dy

    self:stay_on_bounds()

    self.mouseIcon:mouse_moved(x, y, dx, dy)
end

function Icon:update(dt)
    Affectable.update(self, dt)

    local camera = self.gamestate.camera
    if camera.dx ~= 0 then
        self.x = self.x + camera.dx
        self:stay_on_bounds()
    end

    local panel = self.gamestate:game_get_panel()

    if panel.selected_id then
        ---@type Game.Component.Wire
        local wire = panel.wires_by_last[panel.selected_id]

        if wire then
            self.x = wire.plug.x + 32 - 10
            self.y = wire.plug.y - 16
        end

        self:set_state(States.grab)
    elseif self.state == States.shock then
        --
        --
    elseif panel:is_complete() then
        self:set_state(States.cool)
        --
        --
    elseif self:is_in_point_mode() then
        self:set_state(States.point)
    else
        self:set_state(States.prepare)
    end

    ---@type JM.Anima
    self.cur_anima = self.anima[self.state]
    self.cur_anima:update(dt)

    if self.state ~= States.grab then
        self.mouseIcon.x = self.x
        self.mouseIcon.y = self.y
    end
    self.mouseIcon:update(dt)
    if panel.cur_socket then
        self.mouseIcon:set_state(self.mouseIcon.States.point)
    else
        self.mouseIcon:set_state(self.mouseIcon.States.normal)
    end
end

function Icon:my_draw()
    -- love.graphics.setColor(self:get_color_state())
    -- love.graphics.rectangle('fill', self.x, self.y, self.w, self.h)

    self.cur_anima:draw_rec(self.x, self.y, 64, 64)
end

function Icon:draw()
    Affectable.draw(self, self.my_draw)

    if self.state == States.grab then
        self.mouseIcon:draw()
    end
end

return Icon
