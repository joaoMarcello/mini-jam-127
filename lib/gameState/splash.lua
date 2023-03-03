local Pack = _G.JM_Love2D_Package
local Utils = Pack.Utils
local Anima = Pack.Anima

local SCREEN_HEIGHT = 32 * 12
local SCREEN_WIDTH = SCREEN_HEIGHT * 1.5

---@class GameState.Splash: GameState
local State = Pack.Scene:new(nil, nil, nil, nil, SCREEN_WIDTH, SCREEN_HEIGHT)
State.camera:toggle_debug()
State.camera:toggle_grid()
State.camera:toggle_world_bounds()
State.camera.border_color = { 0, 0, 0, 0 }
--===========================================================================
local loveSetColor, lovePolygon, loveNewImage, loveNewSource, loveRectangle
do
    local loveGraphics = love.graphics
    loveSetColor = loveGraphics.setColor
    lovePolygon = loveGraphics.polygon
    loveNewImage = loveGraphics.newImage
    loveNewSource = love.audio.newSource
    loveRectangle = loveGraphics.rectangle
end

function State:set_final_action(action)
    self.__final_action = action
end

--===========================================================================
local px1, px2
local speed = 32 * 10

---@type JM.Template.Affectable|nil
local affect

local rad

local speed_rad = 20

local acc

local total_spin = (math.pi) + math.pi * 0.7

local radius, radius_max

local w, h, max_sx, max_sy

local delay

local img

---@type love.Image|any
local heart

local love_img

---@type love.Image|any
local made_with_img

---@type JM.Anima
local anima

---@type JM.Anima
local heart_anima

---@type JM.Anima
local love_anima

---@type JM.Anima
local anima_made_with

local show_love

---@type love.Source|any
local sound

local is_playing

---@type JM.GUI.Icon
local icon

local function draw_rects()
    --  BLUE
    loveSetColor(39 / 255, 170 / 255, 255 / 255)
    lovePolygon("fill",
        px1 + 64, SCREEN_HEIGHT / 2,
        (px1 + 64 + SCREEN_WIDTH * 1.5), SCREEN_HEIGHT / 2,
        (px1 + SCREEN_WIDTH * 1.5), SCREEN_HEIGHT * 1.5,
        (px1), SCREEN_HEIGHT * 1.5
    )

    -- PINK
    loveSetColor(231 / 255, 74 / 255, 153 / 255)
    lovePolygon("fill",
        px2 + 64, -SCREEN_HEIGHT / 2,
        (px2 + 64 + SCREEN_WIDTH * 1.3), -SCREEN_HEIGHT / 2,
        (px2 + SCREEN_WIDTH * 1.3), SCREEN_HEIGHT * 0.5,
        (px2), SCREEN_HEIGHT * 0.5
    )
end

State:implements({
    load = function()
        img = loveNewImage('/data/image/mask_splash_03.png')
        img:setFilter("linear", "linear")

        heart = loveNewImage("/data/image/love-heart-logo.png")
        heart:setFilter("linear", 'linear')

        love_img = loveNewImage("/data/image/love-logo-512x256.png")
        love_img:setFilter("linear", "linear")

        made_with_img = loveNewImage("/data//image/made-with.png")

        sound = loveNewSource('/data/sfx/simple-clean-logo.ogg', "static")
        sound:setLooping(false)
    end,
    --
    --
    init = function()
        delay = 0.6

        show_love = false

        affect = Pack.Affectable:new()
        affect.ox = SCREEN_WIDTH / 2 - 32
        affect.oy = SCREEN_HEIGHT / 2

        -- BLUE -- BOTTOM
        px1 = SCREEN_WIDTH + 64
        -- PINK -- UP
        px2 = -SCREEN_WIDTH * 1.3 - 64

        rad = 0
        speed = 32 * 2
        acc = (32 * 40)
        speed_rad = 0.8
        radius_max = SCREEN_WIDTH / 2 * 1.4
        radius = radius_max

        w = SCREEN_WIDTH * 7
        h = SCREEN_HEIGHT * 7
        anima = Anima:new { img = img, max_filter = "linear", min_filter = "linear" }
        anima:set_size(w, h)
        max_sx = anima.scale_x
        max_sy = anima.scale_y

        heart_anima = Anima:new { img = heart, max_filter = "linear", min_filter = "linear" }
        local eff = heart_anima:apply_effect("pulse", { speed = 0.3, duration = 0.3 })
        eff:set_final_action(function()
            show_love = true
        end)

        love_anima = Anima:new { img = love_img }
        local ww, hh = love_img:getDimensions()
        love_anima:set_size(32 * 4)
        love_anima:apply_effect('fadein', { speed = 1.3, delay = 0.1 })

        anima_made_with = Anima:new { img = made_with_img }
        -- anima_made_with:set_size(32 * 4 * 0.3)
        anima_made_with:set_size(nil, 8)
        anima_made_with:apply_effect('fadein', { speed = 0.8, delay = 0.1 })

        is_playing = false

        icon = Pack.GUI.Icon:new { img = love_img }
        icon:apply_effect("pulse")
    end,
    --
    --
    keypressed = function(key)
        -- if key == "space" then
        --     CHANGE_GAME_STATE(State, false, false, false, false, true, false)
        -- end
    end,
    --
    --
    finish = function()
        affect = nil
        img:release()
        love_img:release()
        heart:release()
        sound:stop()
        sound:release()
        made_with_img:release()

        img = nil
        love_img = nil
        heart = nil
        sound = nil
        made_with_img = nil
    end,
    --
    --
    update = function(dt)
        if not is_playing then
            sound:play()
            is_playing = true
        end

        delay = delay - dt
        if delay > 0 then
            return
        end

        speed = speed + acc * dt

        if px1 <= SCREEN_WIDTH * 0.4 then
            rad = rad + (total_spin) / speed_rad * dt

            if rad < total_spin * 0.6 then
                affect.ox = SCREEN_WIDTH / 2
            end
        end


        rad = Utils:clamp(rad, -10, total_spin)

        if rad >= total_spin * 0.35 then
            radius = radius - radius_max / 0.6 * dt
            radius = Utils:clamp(radius, 64, math.huge)

            local sx, sy = anima.scale_x, anima.scale_y

            anima:set_scale(
                Utils:clamp(sx - max_sx / 0.4 * dt, 1, math.huge),
                Utils:clamp(sx - max_sx / 0.4 * dt, 1, math.huge)
            )

            if rad >= total_spin * 0.95 and affect then
                affect.ox = Utils:clamp(affect.ox - 32 * 9 * dt, SCREEN_WIDTH / 2 - 30, 30000)
            end

            if rad == total_spin then
                heart_anima:update(dt)
            end

            if show_love then
                love_anima:update(dt)
                anima_made_with:update(dt)

                if love_anima:time_updating() >= 2
                    and not State.fadeout_time
                then
                    State:fadeout(0.7, nil, nil, nil, function()
                        -- CHANGE_GAME_STATE(require 'scripts.gameState.menu', nil, nil, nil, nil, nil)
                        local r = State.__final_action
                            and State.__final_action()
                    end)
                end
            end
        end

        px1 = Utils:clamp(px1 - speed * dt, -64 * 3, SCREEN_WIDTH * 1.3)
        px2 = Utils:clamp(px2 + speed * dt, -SCREEN_WIDTH * 1.3 - 64, -64)

        if affect then
            affect:set_effect_transform("rot", rad)
            affect:update(dt)
        end

        icon:update(dt)
    end,
    --
    --
    draw = function(camera)
        if rad ~= total_spin and not show_love then
            loveSetColor(233 / 255, 245 / 255, 255 / 255)
            loveRectangle("fill", 0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)
        end

        local r = affect and affect:draw(draw_rects)

        if rad >= total_spin * 0.35 then
            -- love.graphics.setColor(1, 0, 0)
            -- love.graphics.circle("fill", SCREEN_WIDTH / 2,
            --     SCREEN_HEIGHT * 0.4, radius)

            anima:draw(SCREEN_WIDTH / 2, SCREEN_HEIGHT * 0.38)
        end

        if rad == total_spin then
            heart_anima:set_color2(0, 0, 0, 0.3)
            heart_anima:draw(SCREEN_WIDTH / 2 + 2, SCREEN_HEIGHT * 0.38 + 3)

            heart_anima:set_color2(1, 1, 1, 1)
            heart_anima:draw(SCREEN_WIDTH / 2, SCREEN_HEIGHT * 0.38)
        end

        if show_love then
            anima_made_with:draw(SCREEN_WIDTH / 2, SCREEN_HEIGHT * 0.59)
            love_anima:draw(SCREEN_WIDTH / 2, SCREEN_HEIGHT * 0.67)
        end

        -- icon:draw(0, 0)
    end
})
-- Sound Effect by Muzaproduction from Pixabay

return State
