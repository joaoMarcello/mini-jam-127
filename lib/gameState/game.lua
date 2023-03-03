local Pack = _G.JM_Love2D_Package
local Phys = Pack.Physics

local Player = require 'lib.player'

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
local insert, remove = table.insert, table.remove
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
    end,

    init = function()
        components = {}
        world = Phys:newWorld()
        player = Player:new(State, world, {})
        State:game_add_component(player)
    end,

    finish = function()
        Player:finish()

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

        table.sort(components, sort_update)

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
                table.sort(components, sort_draw)
                for i = 1, #components do
                    local r = components[i].draw and components[i]:draw()
                end

                player:draw()
            end
        }
    } -- END Layers
}

return State
