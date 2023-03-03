local Pack = _G.JM_Love2D_Package
local Phys = Pack.Physics

local Player = require 'lib.player'
local Fish = require 'lib.fish'

---@class GameState.Game : GameState, JM.Scene
local State = Pack.Scene:new(nil, nil, nil, nil, SCREEN_WIDTH, SCREEN_HEIGHT)

State.camera:toggle_debug()
State.camera:toggle_grid()
State.camera:toggle_world_bounds()
State.camera.border_color = { 0, 0, 0, 0 }
--=============================================================================
local components

---@type JM.Physics.World|any
local world

---@type Player|any
local player
--=============================================================================
local sort_update = function(a, b) return a.update_order > b.update_order end
local sort_draw = function(a, b) return a.draw_order < b.draw_order end

local insert, remove, tableSort = table.insert, table.remove, table.sort

function State:game_add_component(gc)
    insert(components, gc)
    return gc
end

function State:game_remove_component(index)
    ---@type JM.Physics.Body
    local body = components[index].body
    if body then
        body.__remove = true
    end
    return remove(components, index)
end

State:implements {
    load = function()
        Player:load()
        Fish:load()
    end,

    init = function()
        components = {}
        world = Phys:newWorld()

        local rects = {
            { x = -32, y = SCREEN_HEIGHT - 32 * 2, w = SCREEN_WIDTH + 64, h = 32 * 2 },
            --
            -- { x = -1,               y = 0,                      w = 1,                 h = SCREEN_HEIGHT },
            -- --
            -- { x = SCREEN_WIDTH + 1, y = 0,                      w = 1,                 h = SCREEN_HEIGHT },
        }

        for i = 1, #rects do
            local r = rects[i]
            Phys:newBody(world, r.x, r.y, r.w, r.h, "static")
        end

        player = Player:new(State, world, {})
        State:game_add_component(player)

        ---@type Fish
        local fish = State:game_add_component(Fish:new(State, world, { bottom = SCREEN_HEIGHT - 32 * 2 }))
        fish.body:jump(32 * 8, -1)
    end,

    finish = function()
        Player:finish()
        Fish:finish()

        components = nil
        world = nil
        player = nil
    end,

    keypressed = function(key)
        if key == "o" then
            State.camera:toggle_grid()
            State.camera:toggle_debug()
            State.camera:toggle_world_bounds()
        end
    end,

    update = function(dt)
        --
        world:update(dt)

        tableSort(components, sort_update)

        for i = #components, 1, -1 do
            ---@type GameComponent
            local gc = components[i]

            local r = gc.update and gc.is_enable
                and not gc.__remove and gc:update(dt)

            if gc.__remove then
                State:game_remove_component(i)
            end
        end
    end,

    layers = {
        {
            name = 'main',
            --
            --
            ---@param camera JM.Camera.Camera
            draw = function(self, camera)
                --
                for i = 1, world.bodies_number do
                    ---@type JM.Physics.Body|JM.Physics.Slope
                    local obj = world.bodies[i]

                    if obj and camera:rect_is_on_view(obj:rect()) then
                        local r = obj.type == 2 and obj.draw and
                            obj:draw()
                    end
                end

                tableSort(components, sort_draw)
                for i = 1, #components do
                    local r = components[i].draw and components[i]:draw()
                end
            end
        },
        --
        --
        {
            name = "GUI",
            --
            ---@param camera JM.Camera.Camera
            draw = function(self, camera)
                local font = Pack.Font
                font:print(#components, 32, 32)
            end
        }
    } -- END Layers
}

return State
