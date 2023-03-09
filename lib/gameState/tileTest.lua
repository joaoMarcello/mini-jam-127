local Pack = _G.JM_Love2D_Package
local State = Pack.Scene:new(nil, nil, nil, nil, SCREEN_WIDTH, SCREEN_HEIGHT,
    {
        top = -32 * 10,
        left = -32 * 10,
        right = 32 * 200,
        bottom = 32 * 200
    }
)

State.camera:toggle_debug()
State.camera:toggle_grid()
State.camera:toggle_world_bounds()
--=============================================================================

State:implements {
    load = function()

    end,

    init = function()

    end,

    keypressed = function(key)
        if key == "o" then
            State.camera:toggle_grid()
            State.camera:toggle_debug()
            State.camera:toggle_world_bounds()
        end
    end,

    update = function(dt)
        for _, camera in ipairs(State.cameras_list) do
            local speed = 32 * 7 * dt / camera.scale

            if love.keyboard.isDown("left") then
                camera:move(-3)
            elseif love.keyboard.isDown("right") then
                camera:move(3)
            end

            if love.keyboard.isDown("down") then
                camera:move(nil, speed)
            elseif love.keyboard.isDown("up") then
                camera:move(nil, -speed)
            end
        end
    end,

    -- draw = function()

    -- end
}

return State
