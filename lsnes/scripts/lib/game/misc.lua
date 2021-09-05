local M = {}

local bit = _G.bit

local luap = require 'luap'
local mem = require 'memory'
local config = require 'config'
local draw = require 'draw'
local image = require 'game.image'
local state = require 'game.state'
local smw = require 'game.smw'
local tile = require 'game.tile'

local fmt = string.format
local u8 = mem.u8
local u16 = mem.u16
local u24 = mem.u24
local WRAM = smw.WRAM
local SMW = smw.constant
local store = state.store
local DBITMAPS = image.dbitmaps
local OPTIONS = config.OPTIONS
local COLOUR = config.COLOUR
local LSNES_FONT_HEIGHT = config.LSNES_FONT_HEIGHT

local red_width = DBITMAPS.red_berry:size()
local pink_width = DBITMAPS.pink_berry:size()

local function displayBerries(x, y)
    local xDraw = x
    draw.Font = 'Uzebox6x8'

    local red = u8(WRAM.red_berries)
    if red ~= 0 then
        local bitmap = DBITMAPS.red_berry
        bitmap:draw(xDraw, y)
        draw.text(xDraw + red_width, y + 3, red)
        xDraw = xDraw + red_width + 16
    end

    local pink = u8(WRAM.pink_berries)
    if pink ~= 0 then
        local bitmap = DBITMAPS.pink_berry
        bitmap:draw(xDraw, y)
        draw.text(xDraw + pink_width, y + 3, pink)
        xDraw = xDraw + pink_width + 16
    end

    local nextBerry = u8(WRAM.eaten_berry)
    if nextBerry ~= 0 then
        local color = nextBerry == 1 and 0xB50000 or nextBerry == 3 and 0x00E600 or 0xEF196B
        draw.text(xDraw, y + 3, 'Eating a berry', color)
    end
end

function M.global_info()
    if not OPTIONS.display_misc_info then
        return
    end

    -- Font
    draw.Font = false
    draw.Text_opacity = 1.0
    draw.Bg_opacity = 1.0

    -- Display
    local RNGValue = u16(WRAM.RNG)
    local main_info = string.format(
        'Frame(%02x, %02x) RNG(%04x) Mode(%02x)',
        store.Real_frame,
        store.Effective_frame,
        RNGValue,
        store.Game_mode
    )
    local color = store.Game_mode <= SMW.game_mode_max and COLOUR.text
        or SMW.game_modes_level_glitched[store.Game_mode] and COLOUR.warning2
        or COLOUR.warning
    draw.text(
        draw.Buffer_width + draw.Border_right,
        -draw.Border_top,
        main_info,
        color,
        true,
        false
    )
    displayBerries(draw.Buffer_width + draw.Border_right - 16 * 16, -draw.Border_top + 16)

    if store.Game_mode == SMW.game_mode_level then
        -- Time frame counter of the clock
        draw.Font = 'snes9xlua'
        local timer_frame_counter = u8(WRAM.timer_frame_counter)
        draw.text(draw.AR_x * 161, draw.AR_y * 15, fmt('%.2d', timer_frame_counter))

        -- Score: sum of digits, useful for avoiding lag
        draw.Font = 'Uzebox8x12'
        local scoreValue = u24(WRAM.mario_score)
        draw.text(
            draw.AR_x * 240,
            draw.AR_y * 24,
            fmt('=%d', luap.sum_digits(scoreValue)),
            COLOUR.weak
        )
    end
end

function M.level_info()
    if not OPTIONS.display_level_info then
        return
    end

    -- Font
    draw.Font = 'Uzebox6x8'
    draw.Text_opacity = 1.0
    draw.Bg_opacity = 1.0
    local y_pos = -draw.Border_top + LSNES_FONT_HEIGHT
    local color = COLOUR.text

    local pointer = u24(WRAM.sprite_data_pointer)
    local bank = math.floor(pointer / 0x10000)
    local address = pointer % 0x10000
    local ROM_pointer = address >= 0x8000 and address <= 0xFFFD
    local sprite_buoyancy = bit.lrshift(u8(WRAM.sprite_buoyancy), 6)
    if sprite_buoyancy == 0 then
        sprite_buoyancy = ''
    else
        sprite_buoyancy = fmt(' %.2x', sprite_buoyancy)
        color = COLOUR.warning
    end

    -- converts the level number to the Lunar Magic number; should not be used outside here
    local lm_level_number = store.Level_index
    if store.Level_index > 0x24 then
        lm_level_number = store.Level_index + 0xdc
    end

    -- Number of screens within the level
    local level_type, screens_number, hscreen_current, hscreen_number, vscreen_current, vscreen_number =
        tile.read_screens()

    draw.text(
        draw.Buffer_width + draw.Border_right,
        y_pos,
        fmt('%.1sLevel(%.2x)%s', level_type, lm_level_number, sprite_buoyancy),
        color,
        true,
        false
    )
    draw.text(
        draw.Buffer_width + draw.Border_right,
        y_pos + draw.font_height(),
        fmt('Screens(%d):', screens_number),
        true
    )

    draw.text(
        draw.Buffer_width + draw.Border_right,
        y_pos + 2 * draw.font_height(),
        fmt('(%d/%d, %d/%d)', hscreen_current, hscreen_number, vscreen_current, vscreen_number),
        true
    )

    draw.text(
        draw.Buffer_width + draw.Border_right,
        y_pos + 3 * draw.font_height(),
        fmt('$CE: %.2x:%.4x', bank, address),
        ROM_pointer and COLOUR.text or COLOUR.warning,
        true
    )
end

return M
