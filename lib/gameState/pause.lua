local Pack = _G.JM_Love2D_Package

---@class GameState.Pause : GameState
local State = Pack.Scene:new(nil, nil, nil, nil, SCREEN_WIDTH, SCREEN_HEIGHT)
State.camera:toggle_debug()
State.camera:toggle_grid()
State.camera:toggle_world_bounds()
State.camera.border_color = { 0, 0, 0, 0 }

State.camera:set_viewport(
    State.screen_w * 0,
    State.screen_h * 0,
    State.screen_w * 1,
    State.screen_h * 1
)
--=============================================================================
local save_canvas_scale, save_offset_x

State:implements {
    load = function()
        State.prev_state.canvas_scale = 1
        State.prev_state.offset_x = 0
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
            State.prev_state.offset_x = State.offset_x

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
            love.graphics.scale(s, s)

            State.prev_state:draw(camera)

            love.graphics.pop()
        end

        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
    end
}

return State
