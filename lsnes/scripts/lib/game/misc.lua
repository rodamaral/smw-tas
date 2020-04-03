local M = {}

local memory, bit = _G.memory, _G.bit

local luap = require('luap')
local config = require('config')
local draw = require('draw')
local state = require('game.state')
local smw = require('game.smw')
local tile = require('game.tile')

local fmt = string.format
local u8 = memory.readbyte
local u16 = memory.readword
local u24 = memory.readhword
local WRAM = smw.WRAM
local SMW = smw.constant
local store = state.store
local OPTIONS = config.OPTIONS
local COLOUR = config.COLOUR
local LSNES_FONT_HEIGHT = config.LSNES_FONT_HEIGHT

function M.global_info()
    if not OPTIONS.display_misc_info then return end

    -- Font
    draw.Font = false
    draw.Text_opacity = 1.0
    draw.Bg_opacity = 1.0

    -- Display
    local RNGValue = u16('WRAM', WRAM.RNG)
    local main_info = string.format('Frame(%02x, %02x) RNG(%04x) Mode(%02x)', store.Real_frame,
                                    store.Effective_frame, RNGValue, store.Game_mode)
    local color = store.Game_mode <= SMW.game_mode_max and COLOUR.text or
                  SMW.game_modes_level_glitched[store.Game_mode] and COLOUR.warning2 or
                  COLOUR.warning
    draw.text(draw.Buffer_width + draw.Border_right, -draw.Border_top, main_info, color, true, false)

    if store.Game_mode == SMW.game_mode_level then
        -- Time frame counter of the clock
        draw.Font = 'snes9xlua'
        local timer_frame_counter = u8('WRAM', WRAM.timer_frame_counter)
        draw.text(draw.AR_x * 161, draw.AR_y * 15, fmt('%.2d', timer_frame_counter))

        -- Score: sum of digits, useful for avoiding lag
        draw.Font = 'Uzebox8x12'
        local scoreValue = u24('WRAM', WRAM.mario_score)
        draw.text(draw.AR_x * 240, draw.AR_y * 24, fmt('=%d', luap.sum_digits(scoreValue)),
                  COLOUR.weak)
    end
end

function M.level_info()
    if not OPTIONS.display_level_info then return end

    -- Font
    draw.Font = 'Uzebox6x8'
    draw.Text_opacity = 1.0
    draw.Bg_opacity = 1.0
    local y_pos = -draw.Border_top + LSNES_FONT_HEIGHT
    local color = COLOUR.text

    local sprite_buoyancy = bit.lrshift(u8('WRAM', WRAM.sprite_buoyancy), 6)
    if sprite_buoyancy == 0 then
        sprite_buoyancy = ''
    else
        sprite_buoyancy = fmt(' %.2x', sprite_buoyancy)
        color = COLOUR.warning
    end

    -- converts the level number to the Lunar Magic number; should not be used outside here
    local lm_level_number = store.Level_index
    if store.Level_index > 0x24 then lm_level_number = store.Level_index + 0xdc end

    -- Number of screens within the level
    local level_type, screens_number, hscreen_current, hscreen_number, vscreen_current,
          vscreen_number = tile.read_screens()

    draw.text(draw.Buffer_width + draw.Border_right, y_pos,
              fmt('%.1sLevel(%.2x)%s', level_type, lm_level_number, sprite_buoyancy), color, true,
              false)
    draw.text(draw.Buffer_width + draw.Border_right, y_pos + draw.font_height(),
              fmt('Screens(%d):', screens_number), true)

    draw.text(draw.Buffer_width + draw.Border_right, y_pos + 2 * draw.font_height(), fmt(
              '(%d/%d, %d/%d)', hscreen_current, hscreen_number, vscreen_current, vscreen_number),
              true)
end

return M
