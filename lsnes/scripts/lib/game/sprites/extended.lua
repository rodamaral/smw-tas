local M = {}

local bit = _G.bit

local config = require 'config'
local mem = require 'memory'
local draw = require 'draw'
local smw = require 'game.smw'

local u8 = mem.u8
local s8 = mem.s8
local s16 = mem.s16
local fmt = string.format
local floor = math.floor
local OPTIONS = config.OPTIONS
local COLOUR = config.COLOUR
local LEFT_ARROW = config.LEFT_ARROW
local RIGHT_ARROW = config.RIGHT_ARROW
local LSNES_FONT_WIDTH = config.LSNES_FONT_WIDTH
local screen_coordinates = smw.screen_coordinates
local WRAM = smw.WRAM
local SMW = smw.constant
local dontCare = smw.UNINTERESTING_EXTENDED_SPRITES
local hitbox = smw.HITBOX_EXTENDED_SPRITE

-- sprite_table environment
do
    local realFrame, playerPowerup, xCam, yCam, extspr_number, extspr_table2, xPos, yPos, xSpeed, ySpeed, xText, yText, height, counter

    local function displayHitbox(id)
        if
            OPTIONS.display_extended_sprite_hitbox
            and (
                OPTIONS.display_debug_extended_sprite
                or not dontCare[extspr_number]
                or (extspr_number == 1 and extspr_table2 == 0xf)
            )
        then
            local x_screen, y_screen = screen_coordinates(xPos, yPos, xCam, yCam)

            local t = hitbox[extspr_number]
                or {
                    xoff = 0,
                    yoff = 0,
                    width = 16,
                    height = 16,
                    color_line = COLOUR.awkward_hitbox,
                    color_bg = COLOUR.awkward_hitbox_bg,
                }
            local xoff = t.xoff
            local yoff = t.yoff
            local xrad = t.width
            local yrad = t.height

            local color_line = t.color_line or COLOUR.extended_sprites
            local color_bg = t.color_bg or COLOUR.extended_sprites_bg
            if extspr_number == 0x5 or extspr_number == 0x11 then
                color_bg = (realFrame - id) % 4 == 0 and COLOUR.special_extended_sprite_bg or -1
            end
            draw.rectangle(x_screen + xoff, y_screen + yoff, xrad, yrad, color_line, color_bg) -- regular hitbox

            -- Experimental: attempt to show Mario's fireball vs sprites
            -- this is likely wrong in some situation, but I can't solve this yet
            -- FIXME:
            if extspr_number == 5 or extspr_number == 1 then
                -- Yoshi fireball vs cape
                local xoff_spr = xSpeed >= 0 and -5 or 1
                local yoff_spr = -floor(ySpeed / 16) - 4 + (ySpeed >= -40 and 1 or 0)
                local yrad_spr = ySpeed >= -40 and 19 or 20
                draw.rectangle(
                    x_screen + xoff_spr,
                    y_screen + yoff_spr,
                    12,
                    yrad_spr,
                    color_line,
                    color_bg
                )
            elseif extspr_number == 0x11 then
                draw.rectangle(x_screen + 3, y_screen - 0x80 + 0x10, 1, 0xbd - 0x80 - 0x10, 0xff)
                draw.rectangle(x_screen + 3, y_screen, 1, 0x80, 0xff)
            end
        end
    end

    local function sprite_info(id)
        -- Reads WRAM addresses
        xPos = 256 * u8(WRAM.extspr_x_high + id) + u8(WRAM.extspr_x_low + id)
        yPos = 256 * u8(WRAM.extspr_y_high + id) + u8(WRAM.extspr_y_low + id)
        xSpeed = s8(WRAM.extspr_x_speed + id)
        ySpeed = s8(WRAM.extspr_y_speed + id)
        extspr_table2 = u8(WRAM.extspr_table2 + id)
        local sub_x = bit.lrshift(u8(WRAM.extspr_subx + id), 4)
        local sub_y = bit.lrshift(u8(WRAM.extspr_suby + id), 4)
        local extspr_table = u8(WRAM.extspr_table + id)

        -- Reduction of useless info
        local special_info = ''
        if OPTIONS.display_debug_extended_sprite and (extspr_table ~= 0 or extspr_table2 ~= 0) then
            special_info = fmt('(%x, %x) ', extspr_table, extspr_table2)
        end

        -- x speed for Fireballs
        if extspr_number == 5 then
            xSpeed = 16 * xSpeed
        end

        if OPTIONS.display_extended_sprite_info then
            draw.text(
                draw.Buffer_width + draw.Border_right,
                yText + counter * height,
                fmt(
                    '#%.2d %.2x %s(%d.%x(%+.2d), %d.%x(%+.2d))',
                    id,
                    extspr_number,
                    special_info,
                    xPos,
                    sub_x,
                    xSpeed,
                    yPos,
                    sub_y,
                    ySpeed
                ),
                COLOUR.extended_sprites,
                true,
                false
            )
        end

        displayHitbox(id)
        counter = counter + 1
    end

    local function fireball()
        if OPTIONS.display_extended_sprite_info then
            draw.Font = 'Uzebox6x8'
            local x, y, length = draw.text(
                draw.Buffer_width + draw.Border_right,
                yText,
                fmt('Ext. spr:%2d ', counter),
                COLOUR.weak,
                true,
                false,
                0.0,
                1.0
            )
            xText, yText = x, y

            if u8(WRAM.spinjump_flag) ~= 0 and playerPowerup == 3 then
                local fireball_timer = u8(WRAM.spinjump_fireball_timer)
                draw.text(
                    xText - length - LSNES_FONT_WIDTH,
                    yText,
                    fmt(
                        '%d %s',
                        fireball_timer % 16,
                        bit.test(fireball_timer, 4) and RIGHT_ARROW or LEFT_ARROW
                    ),
                    COLOUR.extended_sprites,
                    true,
                    false,
                    1.0,
                    1.0
                )
            end
        end
    end

    function M.sprite_table()
        draw.Font = false
        height = draw.font_height()
        yText = draw.AR_y * 144
        counter = 0

        realFrame = u8(WRAM.real_frame)
        playerPowerup = u8(WRAM.powerup)
        xCam = s16(WRAM.camera_x)
        yCam = s16(WRAM.camera_y)

        for id = 0, SMW.extended_sprite_max - 1 do
            extspr_number = u8(WRAM.extspr_number + id)

            if extspr_number ~= 0 then
                sprite_info(id)
            end
        end

        fireball()
    end
end

return M
