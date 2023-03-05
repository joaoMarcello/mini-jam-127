local Anima = _G.JM_Anima

---@class GameState.HowToPlay : JM.Scene, GameState
local State = _G.JM_Love2D_Package.Scene:new(nil, nil, nil, nil, SCREEN_WIDTH, SCREEN_HEIGHT)

State.camera:toggle_debug()
State.camera:toggle_grid()
State.camera:toggle_world_bounds()
State.camera.border_color = { 0, 0, 0, 0 }

State:set_color(unpack(_G.Palette.orange))
--===========================================================================
local imgs

---@type JM.Anima
local box_anima

---@type JM.Anima
local logo_anima

---@type JM.Font.Font
local font

---@type JM.Font.Phrase|any
local phrase
--===========================================================================
State:implements {
    load = function()
        imgs = imgs or {
            box = love.graphics.newImage('/data/image/box.png'),
            logo = love.graphics.newImage('/data/image/logo.png'),
        }

        font = Pack.FontGenerator:new_by_ttf({
            path = "/data/font/Rajdhani-SemiBold.ttf",
            path_bold = "data/font/Rajdhani-Bold.ttf",
            dpi = 48,
            name = "rajdhani",
            font_size = 11,
            character_space = 0,
            line_space = 7,
            min_filter = 'linear',
            max_filter = 'linear'
        })
        font:set_color(Palette.purple)
    end,

    init = function()
        box_anima = Anima:new { img = imgs.box }
        local red = string.format("<color, %.2f, %.2f, %.2f, %.2f>", unpack(Palette.red))

        logo_anima = Anima:new { img = imgs.logo, min_filter = 'linear', max_filter = 'linear' }
        -- logo_anima:set_scale(0.2, 0.2)
        logo_anima:set_size(nil, 32 * 1.8)

        phrase = font:generate_phrase(
            string.format(
                "<bold>Objective</bold no-space>:\n \tBob is hungry! Help him to feed catching the desired fish. But be careful: He is very demanding and his preferences change very quickly.\n \n<bold>Controls</bold no-space>:\n \t%sMove</color no-space>: WASD or Arrow keys.\n \t%sJump</color no-space>: W/Up/Space\n \t%sPunch</color no-space>: Q/E/F\n \n <bold>Tips</bold no-space>:\n \tCatch the heart to restore some HP.",
                red, red, red),
            32, 32, SCREEN_WIDTH - 32, "left")
    end,

    finish = function()
        imgs = nil
        phrase = nil
    end,
    --
    --
    keypressed = function(key)
        if key == "o" then
            State.camera:toggle_grid()
            State.camera:toggle_debug()
            State.camera:toggle_world_bounds()
        end

        if key == "return" or key == "space" then
            CHANGE_GAME_STATE(require 'lib.gameState.game')
        end
    end,

    update = function(dt)

    end,
    --
    --
    ---@param camera JM.Camera.Camera
    draw = function(camera)
        box_anima:draw(SCREEN_WIDTH / 2, SCREEN_HEIGHT / 2)
        phrase:draw(32 + 16, 32 * 3, "left")

        font:printx("<bold> <effect=ghost, min=0.2, max=1.2, speed=1.5>Press Enter to play", 0, SCREEN_HEIGHT - 64,
            SCREEN_WIDTH,
            "center")

        logo_anima:draw(SCREEN_WIDTH / 2, 32 * 1.5)
    end
}

return State
