local Pack = _G.JM_Love2D_Package
local TileMap = Pack.TileMap

local State = Pack.Scene:new(nil, nil, nil, nil, SCREEN_WIDTH, SCREEN_HEIGHT,
    {
        top = -32 * 10,
        left = -32 * 10,
        right = 32 * 200,
        bottom = 32 * 200
    },
    {
        cam_scale = 1,
        subpixel = 4,
        canvas_filter = 'linear',
    }
)

State.camera:toggle_debug()
State.camera:toggle_grid()
State.camera:toggle_world_bounds()

State:add_camera({
    x = State.screen_w * 0.5,
    y = 20,
    w = State.screen_w * 0.4,
    h = State.screen_h * 0.9,
    scale = 0.7,
}, "cam2")
--=============================================================================
---@type JM.TileMap
local tile_map

---@type JM.TileMap
local map2

---@type JM.TileMap
local map3
--=============================================================================

State:implements {
    load = function()
        tile_map = TileMap:new(
            "/data/my_map_data.lua",
            "/data/image/tileset_01.png",
            32, nil
        )

        map2 = TileMap:new(
            function()
                Entry(0, 0, 1)
                Entry(32, 0, 2)
                Entry(64, 0, 1)
                Entry(96, 0, 2)

                Entry(0, 32, 1000)
                Entry(32, 32, 1001)
            end,
            "/data/image/tile-set-bob.png",
            32
        )

        map3 = TileMap:new(
            "/data/my_map_data.lua",
            "/data/image/tileset_01.png",
            32
        )

        map2.tile_set:add_animated_tile(1000, { 1, 3, 4 }, 0.3)
        map2.tile_set:add_animated_tile(1001, { 1, 3, 4 }, 1)
    end,

    init = function()

    end,

    keypressed = function(key)
        if key == "o" then
            State.camera:toggle_grid()
            State.camera:toggle_debug()
            State.camera:toggle_world_bounds()
        end

        if key == 'u' then
            State.x = 0
            State.y = 0
            State.w = 1366 * 0.8
            State.h = 768 - 168
        end

        if key == 'j' then
            State.x = 0
            State.y = 0
            State.w = 1366 / 2
            State.h = 768 / 2
        end

        if key == 'k' then
            State.x = 50
            State.y = 50
            State.w = 1366 / 2
            State.h = 768 - 20
        end

        if key == 'f' then
            State:add_transition("masker", "out", { duration = 1, type = "left-right" })
        elseif key == 'g' then
            State:add_transition("masker", "in", { duration = 1, type = "right-left", segment = 9 })
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
                camera:move(nil, 3)
            elseif love.keyboard.isDown("up") then
                camera:move(nil, -3)
            end
        end

        tile_map:update(dt)
        map2:update(dt)
    end,

    draw = function(camera)
        tile_map:draw(camera)
        map2:draw(camera)

        love.graphics.setColor(1, 0, 0, 1)

        ---@type JM.TileMap.Cell
        local cell = tile_map.cells_by_pos[tile_map.min_y] and tile_map.cells_by_pos[tile_map.min_y][tile_map.min_x]

        if cell or true then
            love.graphics.rectangle("fill", 32 * 20, 32 * 10, 32, 32)
        end

        love.graphics.rectangle("fill", 960, 320, 32, 32)

        local font = FONT_GUI
        font:print(tostring(tile_map.tile_set == map3.tile_set), 32 * 3, 32 * 8)
        font:print(tostring(_G.Entry), 32 * 3, 32 * 3)
    end
}

return State
