local Pack = _G.JM_Love2D_Package
local Phys = Pack.Physics
local Utils = Pack.Utils

local Player = require 'lib.player'
local Fish = require 'lib.fish'
local Heart = require 'lib.heart'

local DisplayPreferred = require 'lib.displayPreferred'
local DisplayAtk = require 'lib.displayAtk'
local DisplayHP = require 'lib.displayHP'

---@class GameState.Game : GameState, JM.Scene
local State = Pack.Scene:new(nil, nil, nil, nil, SCREEN_WIDTH, SCREEN_HEIGHT)

State.camera:toggle_debug()
State.camera:toggle_grid()
State.camera:toggle_world_bounds()
State.camera.border_color = { 0, 0, 0, 0 }

State:set_color(unpack(_G.Palette.orange))
--=============================================================================
local components

---@type JM.Physics.World|any
local world

---@type Player|any
local player

---@type DisplayPreferred
local displayPref

---@type DisplayAtk
local displayAtk

---@type DisplayHP
local displayHP

local score, hi_score, last_hi_score

local already_saved

local ground_py = SCREEN_HEIGHT - 32 * 2

local time_game
--=============================================================================
local sort_update = function(a, b) return a.update_order > b.update_order end
local sort_draw = function(a, b) return a.draw_order < b.draw_order end

local insert, remove, tableSort, mathRandom, mathAbs = table.insert, table.remove, table.sort, math.random, math.abs

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

function State:game_components()
    return components
end

function State:game_player()
    return player
end

local time_fish = 0.0
local time_fish_speed = 0.8

local function get_fish(delay)
    local dir = mathRandom() > 0.5 and 1 or -1
    local prob = mathRandom()

    ---@type Fish
    local fish = State:game_add_component(Fish:new(State, world, {
        direction = dir,
        acc = 32 * mathRandom(2, 6),
        bottom = ground_py - 16,
        specie = prob <= 0.33 and player.preferred or mathRandom(1, 3),
        delay = delay
    }))
    fish.body:jump(32 * mathRandom(6, 7), -1)

    return fish
end

local function generate_fish(dt)
    if player:is_dead() then return end

    time_fish = time_fish + dt

    if time_fish >= time_fish_speed then
        time_fish = time_fish - time_fish_speed

        local fish = get_fish()
        if time_fish_speed >= 1 or mathRandom() <= 0.33 then
            get_fish(1 + mathRandom() * 2)
        end
    end
end

local function time_fish_speed_decay(dt)
    time_fish_speed = time_fish_speed - (5 / 90) * dt
    time_fish_speed = Utils:clamp(time_fish_speed, 0.55, 1000)
end

function State:game_add_score(value)
    value = mathAbs(value)
    score = score + value
end

local function generate_heart(dt)
    time_game = time_game + dt
    if not player:is_dead() then
        if time_game >= 45 then
            time_game = 0
            State:game_add_component(Heart:new(State, world))
        end
    end
end
--=============================================================================

State:implements {
    load = function()
        Player:load()
        Fish:load()
        Heart:load()

        DisplayPreferred:load()
        DisplayAtk:load()
        DisplayHP:load()

        local success, result = pcall(function()
            local info = love.filesystem.getInfo('save.lua')
            if info then
                return love.filesystem.load('save.lua')
            end
            return nil
        end)

        hi_score = (success and result and result()) or 200
    end,

    init = function()
        time_fish_speed = 5
        time_fish = time_fish_speed - 1
        score = 0
        already_saved = false
        last_hi_score = hi_score
        time_game = 0.0

        components = {}
        world = Phys:newWorld()

        local rects = {
            { x = -32, y = ground_py, w = SCREEN_WIDTH + 64, h = 32 * 3 },
            --
            -- { x = -1,               y = 0,                      w = 1,                 h = SCREEN_HEIGHT },
            -- --
            -- { x = SCREEN_WIDTH + 1, y = 0,                      w = 1,                 h = SCREEN_HEIGHT },
        }

        for i = 1, #rects do
            local r = rects[i]
            Phys:newBody(world, r.x, r.y, r.w, r.h, "static")
        end

        player = Player:new(State, world, { bottom = SCREEN_HEIGHT - 32 * 2 })
        State:game_add_component(player)

        -- ---@type Fish
        -- local fish = State:game_add_component(Fish:new(State, world, {
        --     bottom = SCREEN_HEIGHT - 32 * 2,
        --     delay = 2
        -- }))
        -- fish.body:jump(32 * 8, -1)

        displayPref = DisplayPreferred:new(State)
        displayAtk = DisplayAtk:new(State)
        displayHP = DisplayHP:new(State)
    end,

    finish = function()
        Player:finish()
        Fish:finish()
        Heart:finish()

        DisplayPreferred:finish()
        DisplayAtk:finish()
        DisplayHP:finish()

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

        if key == 'p' then
            RESTART(State)
            return
        end

        if player.time_death and player.time_death >= 4 then
            if key == 'r' then
                RESTART(State)
            end
        end

        player:key_pressed(key)
    end,

    keyreleased = function(key)
        player:key_released(key)
    end,

    update = function(dt)
        --
        generate_fish(dt)
        generate_heart(dt)
        time_fish_speed_decay(dt)

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

        if player:is_dead() then
            if not already_saved and player.time_death >= 3.8 then
                already_saved = true

                if score > hi_score then
                    hi_score = score
                    local success, result = pcall(function()
                        love.filesystem.write('save.lua', 'return ' .. score)
                    end)
                end
            end
        end

        displayPref:update(dt)
        displayAtk:update(dt)
        displayHP:update(dt)
    end,

    layers = {
        {
            lock_shake = true,
            draw = function()
                displayPref:draw()
            end
        },
        --
        --
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
                        -- local r = obj.type == 2 and obj.draw and
                        --     obj:draw()
                        if obj.type == 2 then
                            love.graphics.setColor(Palette.red)
                            love.graphics.rectangle("fill", obj:rect())
                        end
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
            lock_shake = true,
            --
            ---@param camera JM.Camera.Camera
            draw = function(self, camera)
                local font = _G.FONT_GUI
                -- font:print(#components, 32, 32 * 4)

                font:push()
                font:set_line_space(5)
                font:print("HI-SCORE\n " .. hi_score, SCREEN_WIDTH - 96, 16)
                font:print("SCORE\n " .. score, SCREEN_WIDTH - 32 * 6, 16)
                font:pop()

                displayAtk:draw()
                displayHP:draw()

                if player:is_dead() then
                    if player.time_death and player.time_death >= 1.5 then
                        local dif = player.time_death - 2
                        local purple = Palette.purple
                        love.graphics.setColor(purple[1], purple[2], purple[3], 1) --dif / 1.3
                        -- love.graphics.rectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

                        love.graphics.rectangle("fill", 0, 0, Utils:clamp(SCREEN_WIDTH * dif, 0, SCREEN_WIDTH),
                            SCREEN_HEIGHT / 2)

                        love.graphics.rectangle("fill", SCREEN_WIDTH - Utils:clamp(SCREEN_WIDTH * dif, 0, SCREEN_WIDTH),
                            SCREEN_HEIGHT / 2,
                            SCREEN_WIDTH,
                            SCREEN_HEIGHT / 2)

                        font:push()
                        font:set_font_size(32)
                        font:printx("<effect=scream><color, 1, 1, 1>YOU ARE\nDEAD!!!", 0, 32 * 2, SCREEN_WIDTH, "center")
                        font:pop()
                    end

                    if player.time_death and player.time_death >= 4 then
                        font:push()
                        font:set_font_size(12)
                        local orange = string.format("<color, %.2f, %.2f, %.2f>", unpack(Palette.orange))

                        local red = string.format("<color, %.2f, %.2f, %.2f>", unpack(Palette.red))

                        local msg = score > last_hi_score and
                            string.format("\n <effect=ghost, min=0.5, speed=0.7> %s It's a new Hi Score!", red) or
                            ""

                        font:printx(string.format("<color, 1, 1, 1>Your Score was %s %d %s", orange, score, msg), 0,
                            32 * 6,
                            SCREEN_WIDTH,
                            "center")

                        font:printx("<color, 1, 1, 1>To play again press R\n To quit press Esc", 0, 32 * 9, SCREEN_WIDTH,
                            "center")
                        font:pop()
                    end
                end

                -- font:print(time_fish_speed, 32, 32 * 4)
            end
        }
    } -- END Layers
}

return State
