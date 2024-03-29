local love = _G.love
love.filesystem.setIdentity("Hungry-Bob")

Pack = require "jm-love2d-package.init"

Palette = {
    white = { 1, 1, 1 },
    light_gray = { 239 / 255, 235 / 255, 234 / 255, 1 },
    dark_gray = { 228 / 255, 219 / 255, 214 / 255, 1 },
    orange = { 243 / 255, 180 / 255, 134 / 255, 1 },
    red = { 212 / 255, 113 / 255, 93 / 255, 1 },
    purple = { 77 / 255, 35 / 255, 74 / 255, 1 },
}

Pack.Font.current:set_color(Palette.purple)


math.randomseed(os.time())
love.graphics.setBackgroundColor(0, 0, 0, 1)
love.graphics.setDefaultFilter("nearest", "nearest")
love.mouse.setVisible(true)
-- love.mouse.setRelativeMode(true)

-- collectgarbage("setstepmul", 150)
-- collectgarbage("setpause", 250)

---@type JM.Font.Font|any
FONT_GUI = nil

---@class GameState: JM.Scene
---@field load function
---@field init function
---@field finish function
---@field update function
---@field draw function
---@field keypressed function
---@field prev_state GameState|nil

--==================================================================

SCREEN_HEIGHT = Pack.Utils:round(32 * 11)            -- 384 32*15
SCREEN_WIDTH = Pack.Utils:round(SCREEN_HEIGHT * 1.5) --576 *1.5

DEVICE = "Android"

local initial_state = 'game'

--==================================================================

---@type GameState
local scene

---@param new_state GameState
function CHANGE_GAME_STATE(new_state, skip_finish, skip_load, save_prev, skip_collect, skip_fadein, skip_init)
    -- local p = scene and scene:init()
    local r = scene and not skip_finish and scene:finish()
    new_state.prev_state = save_prev and scene or nil
    r = (not skip_load) and new_state:load()
    r = (not skip_init) and new_state:init()
    r = (not skip_collect) and collectgarbage()
    scene = new_state
    -- r = not skip_fadein and scene:fadein(nil, nil, nil)
    r = not skip_fadein and scene:add_transition("fade", "in", { delay = nil, duration = 0.3, pause_scene = nil })
end

function RESTART(state)
    CHANGE_GAME_STATE(state, true, true, false, false)
end

function PAUSE(state)
    CHANGE_GAME_STATE(state, true, false, true, true, true)
end

---@param state GameState
function UNPAUSE(state)
    if not state then return end
    -- state.prev_state.camera.desired_scale = state.camera.desired_scale
    CHANGE_GAME_STATE(state.prev_state, true, true, false, false, true, true)
end

function PLAY_SFX(name, force, stop)
    Pack.Sound:play_sfx(name, force)
end

function PLAY_SONG(name)
    Pack.Sound:play_song(name)
end

--=========================================================================

function love.load()
    FONT_GUI = Pack.FontGenerator:new_by_ttf({
        path = "/data/font/Rajdhani-Bold.ttf",
        -- path_bold = "data/font/Rajdhani-Bold.ttf",
        dpi = 36,
        name = "rajdhani",
        font_size = 12,
        character_space = 0,
        -- line_space = 5,
        min_filter = 'nearest',
        max_filter = 'nearest'
    })
    FONT_GUI:set_color(Palette.purple)

    local Sound = Pack.Sound
    Sound:add_sfx('/data/sfx/triqystudio__dropitem.ogg', "slap")
    Sound:add_sfx('/data/sfx/496192__luminousfridge__bash-hit-sfx.ogg', "hit")

    Sound:add_sfx('/data/sfx/foolboymedia__tick-tock.wav', "tick-tock", 0.9)
    Sound:add_sfx('/data/sfx/original_sound__error-wooden.ogg', "warning", 1)

    Sound:add_sfx('/data/sfx/megrez7274_snd_cathighmeows v2.wav', "scream", 1)
    Sound:add_sfx('/data/sfx/lotrdinonerd_cat-meowing death v2.wav', "death")
    Sound:add_sfx('/data/sfx/marcjunker_man-eating-teriyaki-noodles  V-1.wav', "eat", 0.8)
    Sound:add_sfx('/data/sfx/filippys_pulo7 .ogg', "jump")

    Sound:add_sfx('/data/sfx/aarrnnoo_very-quick-splash-and-squishy-sound-cutted-splash-v2.ogg', "splash", 0.2)

    -- Sound:add_song('/data/song/fun-kids-playful-comic-carefree-game-happy-positive-music-57026.ogg', "game", 0.1)

    local state = require 'lib.gameState.splash'
    state:set_final_action(function()
        CHANGE_GAME_STATE(require 'lib.gameState.howToPlay')
    end)

    CHANGE_GAME_STATE(require('lib.gameState.' .. initial_state), true)
end

function love.keypressed(key)
    if key == "escape"
        or (key == "f4" and (love.keyboard.isDown("lalt")
        or love.keyboard.isDown("ralt")))
    then
        scene:finish()
        love.event.quit()
        return
    end

    local r = scene and scene:keypressed(key)
end

function love.keyreleased(key)
    local r = scene and scene:keyreleased(key)
end

function love.mousepressed(x, y, button, istouch, presses)
    scene:mousepressed(x, y, button, istouch, presses)
end

function love.mousereleased(x, y, button, istouch, presses)
    scene:mousereleased(x, y, button, istouch, presses)
end

function love.mousemoved(x, y, dx, dy, istouch)
    scene:mousemoved(x, y, dx, dy, istouch)
end

function love.touchpressed(id, x, y, dx, dy, pressure)
    scene:touchpressed(id, x, y, dx, dy, pressure)
end

function love.touchreleased(id, x, y, dx, dy, pressure)
    scene:touchreleased(id, x, y, dx, dy, pressure)
end

local km = nil
local time = 0
function love.update(dt)
    km = collectgarbage("count") / 1024.0
    Pack:update(dt)
    scene:update(dt)

    -- time = time + dt
    -- if time >= 3 then
    --     time = 0
    --     local r = not collectgarbage("isrunning") and collectgarbage("step")
    -- end
end

function love.draw()
    scene:draw()

    love.graphics.setColor(0, 0, 0, 0.7)
    love.graphics.rectangle("fill", 0, 0, 80, 120)
    love.graphics.setColor(1, 1, 0, 1)
    love.graphics.print(string.format("Memory:\n\t%.2f Mb", km), 5, 10)
    love.graphics.print("FPS: " .. tostring(love.timer.getFPS()), 5, 50)
    local maj, min, rev, code = love.getVersion()
    love.graphics.print(string.format("Version:\n\t%d.%d.%d", maj, min, rev), 5, 75)
end
