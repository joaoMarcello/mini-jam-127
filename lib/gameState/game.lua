local Pack = _G.JM_Love2D_Package
local Phys = Pack.Physics
local Utils = Pack.Utils
local TileMap = Pack.TileMap

local Player = require 'lib.player'
local Fish = require 'lib.fish'
local Heart = require 'lib.heart'

local DisplayPreferred = require 'lib.displayPreferred'
local DisplayAtk = require 'lib.displayAtk'
local DisplayHP = require 'lib.displayHP'

---@class GameState.Game : GameState, JM.Scene
local State = Pack.Scene:new(nil, nil, nil, nil, SCREEN_WIDTH,
    SCREEN_HEIGHT, nil, {
        subpixel = 2,
        canvas_filter = 'linear'
    })

State.camera:toggle_debug()
State.camera:toggle_grid()
State.camera:toggle_world_bounds()
State.camera.border_color = { 0, 0, 0, 0 }
-- State.camera.x = 32
State:set_color(unpack(_G.Palette.orange))

-- State.camera:set_viewport(
--     State.screen_w * 0,
--     State.screen_h * 0,
--     State.screen_w * 0.5,
--     State.screen_h * 1
-- )

-- State:add_camera({
--     x = State.screen_w * 0.5,
--     y = State.screen_h * 0.5,
--     w = State.screen_w * 0.5,
--     h = State.screen_h * 0.5,
--     scale = 0.5,
-- }, "cam2")
-- State:get_camera("cam2").x = 64

-- State:add_camera({
--     x = State.screen_w * 0.5,
--     y = State.screen_h * 0,
--     w = State.screen_w * 0.5,
--     h = State.screen_h * 0.5,
--     scale = 0.5,
-- }, "cam3")
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

local time_heart, time_game

local tutor_atk, tutor_move = true, false

---@type JM.TileMap
local tile_map

Pack.GUI.TouchButton:set_font(_G.FONT_GUI)

local len = math.floor((State.h - State.y) / 5)

---@type JM.GUI.TouchButton
local Button_jump = Pack.GUI.TouchButton:new {
    x = 32,
    y = 32,
    w = len,
    h = len,
    use_radius = true,
    text = "A",
    opacity = 0.5,
}
Button_jump:set_focus(true)
Button_jump:set_position(State.w - 30 - len, State.h - 30 - len)

---@type JM.GUI.TouchButton
local Button_Atk = Pack.GUI.TouchButton:new {
    x = 32,
    y = 32,
    w = len,
    h = len,
    use_radius = true,
    text = "B",
    opacity = 0.5,
}
Button_Atk:set_focus(true)
Button_Atk:set_position(Button_jump.x - len - 20,
    Button_jump.y - len / 2 - 20)

---@type JM.GUI.VirtualStick
local Stick = Pack.GUI.VirtualStick:new {
    on_focus = true,
    w = (State.h - State.y) / 4,
    is_mobile = true,
    bound_top = (State.h - State.y) * 0.25,
    bound_width = (State.w - State.x) / 4,
    bound_height = (State.h - State.y) * 0.75,
    opacity = 0.5,
}

Stick:set_position(Stick.max_dist, State.h - Stick.h - 50, true)

local virtual_pad = {
    atk = Button_Atk,
    jump = Button_jump,
    stick = Stick
}

function State:game_get_virtual_pad()
    return virtual_pad
end

State:set_foreground_draw(function()
    for _, bt in pairs(virtual_pad) do
        bt:draw()
    end
end)


local map = function()
    local px, py = -32, _G.SCREEN_HEIGHT - 32 * 2

    for i = 0, 24 do
        if i % 2 == 0 then
            Entry(px + 32 * i, py, 1)
            Entry(px + 32 * i, py + 32, 3)
            Entry(px + 32 * i, py + 64, 4)
        else
            Entry(px + 32 * i, py, 2)
            Entry(px + 32 * i, py + 32, 4)
            Entry(px + 32 * i, py + 64, 3)
        end
    end
end
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
    local prob_r = time_game >= 30 and 0.33 or 0.75

    ---@type Fish
    local fish = State:game_add_component(Fish:new(State, world, {
        direction = dir,
        acc = 32 * mathRandom(2, 6),
        bottom = ground_py - 16,
        specie = prob <= prob_r and player.preferred or mathRandom(1, 3),
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
        if time_fish >= time_fish_speed then time_fish = 0 end

        local fish = get_fish()
        local prob = time_game >= 140 and 0.7 or 0.33
        if time_fish_speed >= 1 or mathRandom() <= prob then
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
    time_heart = time_heart + dt
    if not player:is_dead() then
        if time_heart >= 30 then
            time_heart = 0
            State:game_add_component(Heart:new(State, world))
        end
    end
end

function State:game_get_time_game()
    return time_game
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

        tile_map = TileMap:new(map, "/data/image/tile-set-bob.png", 32)
    end,

    init = function()
        time_fish_speed = 5
        time_fish = time_fish_speed - 3
        score = 0
        already_saved = false
        last_hi_score = hi_score
        time_heart = -10
        time_game = 0
        tutor_atk = true

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

        _G.PLAY_SONG("game")
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

    mousepressed = function(x, y, button, istouch)
        if DEVICE == "Android" then return end

        local mx, my = love.mouse.getPosition()

        for _, bt in pairs(virtual_pad) do
            bt:mouse_pressed(mx, my, button, istouch)
        end

        player:mouse_pressed()
        if Button_Atk:is_pressed() then tutor_atk = false end
    end,

    mousereleased = function(x, y, button, istouch, presses)
        if DEVICE == "Android" then return end

        local mx, my = love.mouse.getPosition()
        for _, bt in pairs(virtual_pad) do
            bt:mouse_released(mx, my, button, istouch, presses)
        end

        player:touch_released()
    end,

    touchpressed = function(id, x, y, dx, dy, pressure)
        for _, bt in pairs(virtual_pad) do
            bt:touch_pressed(id, x, y, dx, dy, pressure)
        end

        if player.time_death and player.time_death >= 4 then
            if Button_jump:is_pressed() then
                RESTART(State)
                return
            end
        end

        player:touch_pressed()
        if Button_Atk:is_pressed() then tutor_atk = false end
    end,

    touchreleased = function(id, x, y, dx, dy, pressure)
        for _, bt in pairs(virtual_pad) do
            bt:touch_released(id, x, y, dx, dy, pressure)
        end

        player:touch_released()
    end,

    keypressed = function(key)
        if key == "o" then
            State.camera:toggle_grid()
            State.camera:toggle_debug()
            State.camera:toggle_world_bounds()
        end

        if key == "return" then
            CHANGE_GAME_STATE(require "lib.gameState.pause", true, nil, true, true, true, nil)
            return
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

        if tutor_atk then
            for i = 1, #player.key_attack do
                if key == player.key_attack[i] then
                    tutor_atk = false
                    break
                end
            end
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
    end,

    keyreleased = function(key)
        player:key_released(key)
    end,

    update = function(dt)
        for _, bt in pairs(virtual_pad) do
            bt:update(dt)
        end
        --
        time_game = time_game + dt
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
            --
            --

            ---@param camera JM.Camera.Camera
            draw = function(self, camera)
                if camera == State.camera then
                    love.graphics.setColor(_G.Palette.orange)
                else
                    love.graphics.setColor(_G.Palette.purple)
                end
                -- love.graphics.rectangle('fill', 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)

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
                tile_map:draw(camera)

                tableSort(components, sort_draw)
                for i = 1, #components do
                    local r = components[i].draw and components[i]:draw()
                end

                -- local mx, my = State:get_mouse_position()
                -- love.graphics.setColor(0, 0, 1)
                -- love.graphics.circle("fill", mx, my, 5)
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

                if not player:is_dead() then
                    if tutor_atk then
                        font:print("Press E/Q/F\n to Attack", player.x - 16, player.y - 32 * 3)
                    elseif tutor_move then
                        font:print("Press WASD or \nArrow keys to move", player.x - 16, player.y - 32 * 3)
                    end
                end

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


                -- font:print("cs: " .. State.canvas_scale, 32 * 1, 32 * 5)
                -- font:print("ds: " .. State.camera.desired_scale, 32 * 1, 32 * 6)
                -- font:print("sub:" .. State.subpixel, 32 * 1, 32 * 7)
                -- font:print("ox:" .. State.offset_x, 32 * 1, 32 * 8)

                -- local x, y, w, h = State.camera:get_viewport()
                -- font:print("" .. x .. "-" .. y .. "-" .. w .. "-" .. h, 32 * 2, 32 * 4)

                -- font:print("" .. State.camera.desired_scale, 32 * 3, 32 * 6)
                -- font:print("" .. ((State.h - State.y) / State.screen_h), 32 * 3, 32 * 7)

                -- local s = string.format("%.10f", player.body.speed_y)
                -- font:print(tostring(player.body.speed_y), 300, 300)
            end
        }
    } -- END Layers
}

return State
