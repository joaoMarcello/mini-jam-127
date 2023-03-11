local Pack = _G.JM_Love2D_Package

---@class GameState.Pause : GameState
local State = Pack.Scene:new(nil, nil, nil, nil, SCREEN_WIDTH, SCREEN_HEIGHT)
State:set_color(1, 1, 1, 0)

State:implements {
    load = function()
        -- State.prev_state.subpixel = 1
        State.prev_state.canvas_scale = 1
    end,

    init = function()

    end,

    finish = function()

    end,

    keypressed = function(key)
        if key == "o" then
            State.camera:toggle_grid()
            State.camera:toggle_debug()
            State.camera:toggle_world_bounds()
        end

        if key == "return" then
            State.prev_state.canvas_scale = State.canvas_scale
            CHANGE_GAME_STATE(State.prev_state, nil, true, nil, nil, true, true)
        end
    end,

    update = function(dt)

    end,

    ---@param camera JM.Camera.Camera
    draw = function(camera)
        if State.prev_state then
            love.graphics.push()

            local s = State.canvas_scale / State.camera.desired_scale
            local ox = 0 ---5 ---State.offset_x / 0.46 / 4
            local oy = 0
            love.graphics.translate(ox, oy)
            -- love.graphics.translate(
            --     -State.offset_x / State.camera.desired_scale / State.canvas_scale,
            --     State.prev_state.camera.y)


            love.graphics.scale(s, s)
            State.prev_state:draw(camera)
            love.graphics.pop()
        end
    end
}

return State
