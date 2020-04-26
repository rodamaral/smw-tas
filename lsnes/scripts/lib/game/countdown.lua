local M = {}

local config = require 'config'
local mem = require('memory')
local draw = require 'draw'
local smw = require 'game.smw'

local u8 = mem.u8
local OPTIONS = config.OPTIONS
local COLOUR = config.COLOUR
local WRAM = smw.WRAM
local fmt = string.format
local floor = math.floor

local function display_fadeout_timers()
    if not OPTIONS.display_counters then return end

    local Real_frame = u8(WRAM.real_frame)
    local end_level_timer = u8(WRAM.end_level_timer)
    if end_level_timer == 0 then return end

    -- load
    local peace_image_timer = u8(WRAM.peace_image_timer)
    local fadeout_radius = u8(WRAM.fadeout_radius)
    local zero_subspeed = u8(WRAM.x_subspeed) == 0

    -- display
    draw.Font = false
    local height = draw.font_height()
    local x, y = 0, draw.Buffer_height - 3 * height -- 3 max lines
    local text = 2 * end_level_timer + (Real_frame) % 2
    draw.text(x, y, fmt('End timer: %d(%d) -> real frame', text, end_level_timer), COLOUR.text)
    y = y + height
    draw.text(x, y, fmt('Peace %d, Fadeout %d/60', peace_image_timer,
                        60 - math.floor(fadeout_radius / 4)), COLOUR.text)
    if end_level_timer >= 0x28 then
        if (zero_subspeed and Real_frame % 2 == 0) or (not zero_subspeed and Real_frame % 2 ~= 0) then
            y = y + height
            draw.text(x, y, 'Bad subspeed?', COLOUR.warning)
        end
    end
end

do
    local height, xText, yText

    local function display_counter(label, value, default, mult, frame, color)
        if value == default then return end
        local _color = color or COLOUR.text

        draw.text(xText, yText, fmt('%s: %d', label, (value * mult) - frame), _color)
        yText = yText + height
    end

    function M.show_counters()
        if not OPTIONS.display_counters then return end

        -- Font
        draw.Font = false -- "snes9xtext" is also good and small
        draw.Text_opacity = 1.0
        draw.Bg_opacity = 1.0
        height = draw.font_height()
        xText = 0
        yText = draw.AR_y * 102

        local Real_frame = u8(WRAM.real_frame)
        local Effective_frame = u8(WRAM.effective_frame)
        local Player_animation_trigger = u8(WRAM.player_animation_trigger)
        local Lock_animation_flag = u8(WRAM.lock_animation_flag)

        local pipe_entrance_timer = u8(WRAM.pipe_entrance_timer)
        local multicoin_block_timer = u8(WRAM.multicoin_block_timer)
        local gray_pow_timer = u8(WRAM.gray_pow_timer)
        local blue_pow_timer = u8(WRAM.blue_pow_timer)
        local dircoin_timer = u8(WRAM.dircoin_timer)
        local pballoon_timer = u8(WRAM.pballoon_timer)
        local star_timer = u8(WRAM.star_timer)
        local invisibility_timer = u8(WRAM.invisibility_timer)
        local animation_timer = u8(WRAM.animation_timer)
        local fireflower_timer = u8(WRAM.fireflower_timer)
        local yoshi_timer = u8(WRAM.yoshi_timer)
        local swallow_timer = u8(WRAM.swallow_timer)
        local lakitu_timer = u8(WRAM.lakitu_timer)
        local generator_timer  = u8(WRAM.generator_timer)
        local generator_sprite_id  = u8(WRAM.generator_sprite_id)
        local generator_sprite_name = smw.SPRITE_NAMES[generator_sprite_id] 
        local score_incrementing = u8(WRAM.score_incrementing)
        local pause_timer = u8(WRAM.pause_timer) -- new
        local bonus_timer = u8(WRAM.bonus_timer)
        -- local disappearing_sprites_timer = u8(WRAM.disappearing_sprites_timer) TODO:
        local message_box_timer = floor(u8(WRAM.message_box_timer) / 4)
        local game_intro_timer = u8(WRAM.game_intro_timer)
        local sprite_yoshi_squatting = u8(WRAM.sprite_yoshi_squatting)
        local egg_laid_timer = u8(WRAM.egg_laid_timer)

        --[[   local display_counter = function(label, value, default, mult, frame, color)
    if value == default then
      return
    end
    text_counter = text_counter + 1
    local _color = color or COLOUR.text

    draw.text(0, draw.AR_y * 102 + (text_counter * height), fmt('%s: %d', label, (value * mult) - frame), _color)
  end ]]
        if Player_animation_trigger == 5 or Player_animation_trigger == 6 then
            display_counter('Pipe', pipe_entrance_timer, -1, 1, 0, COLOUR.counter_pipe)
        end

        display_counter('Multi Coin', multicoin_block_timer, 0, 1, 0, COLOUR.counter_multicoin)
        display_counter('Pow', gray_pow_timer, 0, 4, Effective_frame % 4, COLOUR.counter_gray_pow)
        display_counter('Pow', blue_pow_timer, 0, 4, Effective_frame % 4, COLOUR.counter_blue_pow)
        display_counter('Dir Coin', dircoin_timer, 0, 4, Real_frame % 4, COLOUR.counter_dircoin)
        display_counter('P-Balloon', pballoon_timer, 0, 4, Real_frame % 4, COLOUR.counter_pballoon)
        display_counter('Star', star_timer, 0, 4, (Effective_frame - 1) % 4, COLOUR.counter_star)
        display_counter('Invisibility', invisibility_timer, 0, 1, 0)
        display_counter('Fireflower', fireflower_timer, 0, 1, 0, COLOUR.counter_fireflower)
        display_counter('Yoshi', yoshi_timer, 0, 1, 0, COLOUR.yoshi)
        display_counter('Swallow', swallow_timer, 0, 4, (Effective_frame - 1) % 4, COLOUR.yoshi)
        display_counter('Lakitu', lakitu_timer, 0, 4, Effective_frame % 4)
        display_counter('Spawn ' .. generator_sprite_name, generator_timer, 0, 2, (Real_frame + 0) % 2, COLOUR.warning)
        display_counter('Score Incrementing', score_incrementing, 0x50, 1, 0)
        display_counter('Pause', pause_timer, 0, 1, 0) -- new  -- level
        display_counter('Bonus', bonus_timer, 0, 1, 0)
        display_counter('Message', message_box_timer, 0, 1, 0) -- level and overworld
        -- TODO: check whether it appears only during the intro level
        display_counter('Intro', game_intro_timer, 0, 4, Real_frame % 4)
        display_counter('Squat', sprite_yoshi_squatting , 0, 1, 0, COLOUR.yoshi)
        display_counter('Egg', egg_laid_timer , 0, 1, 0, COLOUR.yoshi)

        display_fadeout_timers()

        if Lock_animation_flag ~= 0 then
            display_counter('Animation', animation_timer, 0, 1, 0)
        end -- shows when player is getting hurt or dying
    end
end

return M
