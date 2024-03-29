local GC = require 'lib.component'
local Fish = require 'lib.fish'

local Sound = _G.JM_Love2D_Package.Sound

local img

---@type JM.Font.Font
local font

---@class DisplayPreferred : GameComponent
local Display = setmetatable({}, GC)
Display.__index = Display

---@param state GameState.Game
function Display:new(state, args)
    args = args or {}
    args.w = 32 * 2
    args.h = 32 * 2
    args.x = SCREEN_WIDTH / 2 - args.w / 2
    args.y = 16

    local obj = GC:new(state, args)
    setmetatable(obj, self)
    Display.__constructor__(obj, state, args)
    return obj
end

---@param state GameState.Game
function Display:__constructor__(state, args)
    self.gamestate = state

    self.ox = self.w / 2
    self.oy = self.h / 2

    self.last_pref = state:game_player().preferred

    local Anima = _G.JM_Anima
    self.anima = {
        [Fish.Types.baiacu] = Anima:new { img = Fish.Imgs[Fish.Types.baiacu] },
        [Fish.Types.atum] = Anima:new { img = Fish.Imgs[Fish.Types.atum] },
        [Fish.Types.carpa] = Anima:new { img = Fish.Imgs[Fish.Types.carpa] },
    }

    -- for _, anima in ipairs(self.anima) do
    --     anima:apply_effect("pulse", { range = 0.05, speed = 1 })
    -- end

    self.mask = Anima:new { img = img.mask }
    self.line = Anima:new { img = img.line }
    self.line:set_color(Palette.purple)

    self.played_ticktock = false
end

function Display:load()
    Fish:load()

    img = img or {
        mask = love.graphics.newImage('/data/image/mask-display-pref-v2.png'),
        line = love.graphics.newImage('/data/image/mask-display-pref.png'),
    }

    font = font or _G.FONT_GUI
end

function Display:finish()
    Fish:finish()
    img = nil
end

function Display:update(dt)
    GC.update(self, dt)

    local player = self.gamestate:game_player()

    if not player:is_dead()
        and player.time_change >= (player.time_change_speed - 1.3)
    then
        self:apply_effect('pulse', { range = 0.07, speed = 0.3 })
        if not self.played_ticktock then
            PLAY_SFX('tick-tock', true)
            self.played_ticktock = true
        end
    else
        local eff = self.eff_actives and self.eff_actives['pulse']
        if eff then
            self.eff_actives['pulse'] = nil
            eff.__remove = true
        end
    end

    if self.last_pref ~= player.preferred then
        self.last_pref = player.preferred
        self:apply_effect('popin', { speed = 0.2 })
        self.played_ticktock = false
        _G.PLAY_SFX("warning")
        local audio = Sound:get_sfx("tick-tock")
        if audio then
            audio.source:stop()
        end
    end

    if player:is_dead() then
        local audio = Sound:get_sfx("tick-tock")
        if audio and audio.source:isPlaying() then audio.source:stop() end
    end

    self.anima[player.preferred]:update(dt)
end

function Display:my_draw()
    local player = self.gamestate:game_player()
    local color = player.Fish.Colors[player.preferred]

    local px, py = self.x + self.w / 2, self.y + self.h / 2

    self.mask:set_color(Palette.purple)
    self.mask:draw(px + 1, py + 1)

    self.mask:set_color(color)
    self.mask:draw(px, py)

    self.line:draw(px, py)

    self.anima[player.preferred]:draw(px, py)

    font:push()
    font:set_font_size(10)
    font:printx("CATCH", self.x, self.y - 10, self.x + self.w, "center")
    font:pop()
end

function Display:draw()
    GC.draw(self, self.my_draw)
end

return Display
