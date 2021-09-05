local M = {}

local bit = _G.bit

local config = require 'config'
local mem = require 'memory'
local draw = require 'draw'
local Display = require 'display'
local smw = require 'game.smw'
local state = require 'game.state'
local tile = require 'game.tile'

local u8 = mem.u8
local WRAM = smw.WRAM
local screen_coordinates = smw.screen_coordinates
local OPTIONS = config.OPTIONS
local COLOUR = config.COLOUR
local store = state.store

function M.display_horizontal_spawn_region()
    local real_frame = store.Real_frame
    local camera_y = store.Camera_y
    local color = real_frame % 2 == 0 and 0xb0004000 or -1

    draw.rectangle(0x110 + 1, -camera_y, 16, 432, 0xb000c000, color)
    draw.rectangle(-0x40 + 1, -camera_y, 16, 432, 0xb000c000, color)
end

function M.display_vertical_spawn_region()
    local real_frame = store.Real_frame
    local camera_x = store.Camera_x
    local color = real_frame % 2 == 0 and 0xb0004000 or -1

    draw.rectangle(-camera_x, 0x110 + 1, 0x200, 16, 0xb000c000, color)
    draw.rectangle(-camera_x, -0x40 + 1, 0x200, 16, 0xb000c000, color)
end

function M.display_horizontal_despawn_region()
    local real_frame = store.Real_frame
    local left = { [0] = -0x40, -0x40, -0x10, -0x70 }
    local right = { [0] = 0x130, 0x1a0, 0x1a0, 0x160 }
    local colors = { [0] = 0xb0ff0000, 0xb000ff00, 0xb00000ff, 0xb0ffffff }

    local color_left = real_frame % 2 == 0 and 0xffffff or 0x80808080
    local color_right = real_frame % 2 == 1 and 0xffffff or 0x80808080
    for i = 0, 3 do
        draw.line(left[i] + 1, -draw.Border_top, left[i] + 1, draw.Screen_height, 2, colors[i])
        draw.text(2 * (left[i] + 1), -draw.Border_top + 12 * i, i, color_left)
        draw.line(right[i] + 1, -draw.Border_top, right[i] + 1, draw.Screen_height, 2, colors[i])
        draw.text(2 * (right[i] + 1), -draw.Border_top + 12 * i, i, color_right)
    end
end

function M.display_vertical_despawn_region()
    local real_frame = store.Real_frame
    local left = -store.Camera_x
    local right = 0x200 + left
    local top = -0x50
    local bottom = 0x140
    local color_side = real_frame % 2 == 0 and 0xc00000 or 0xb0800000
    local color_top = real_frame % 4 == 2 and 0xc00000 or 0xb0800000
    local color_bottom = real_frame % 4 == 0 and 0xc00000 or 0xb0800000

    draw.line(left, bottom, right, bottom, 2, color_bottom)
    draw.line(left, top, right, top, 2, color_top)
    draw.line(left, bottom, left, top, 2, color_side)
    draw.line(right, bottom, right, top, 2, color_side)
end

function M.display_spawn_region()
    local is_vertical = bit.test(u8(WRAM.screen_mode), 0)
    if is_vertical then
        M.display_vertical_spawn_region()
    else
        M.display_horizontal_spawn_region()
    end
end

function M.display_despawn_region()
    local is_vertical = bit.test(u8(WRAM.screen_mode), 0)
    if is_vertical then
        M.display_vertical_despawn_region()
    else
        M.display_horizontal_despawn_region()
    end
end

-- Creates lines showing where the real pit of death is
-- One line is for sprites and another is for Mario or Mario/Yoshi (different spot)
function M.draw_boundaries()
    if not OPTIONS.display_level_boundary then
        return
    end

    -- Font
    draw.Font = 'Uzebox6x8'
    draw.Text_opacity = 1.0
    draw.Bg_opacity = 1.0

    -- Player borders
    if Display.is_player_near_borders or OPTIONS.display_level_boundary_always then
        local xmin = 8 - 1
        local ymin = -0x80 - 1
        local xmax = 0xe8 + 1
        local ymax = 0xfb -- no increment, because this line kills by touch

        local no_powerup = (store.Player_powerup == 0)
        if no_powerup then
            ymax = ymax + 1
        end
        if not store.Yoshi_riding_flag then
            ymax = ymax + 5
        end

        draw.box(xmin, ymin, xmax, ymax, 2, COLOUR.warning2)
        if draw.Border_bottom >= 64 then
            local str = string.format('Death: %d', ymax + store.Camera_y)
            draw.text(xmin, draw.AR_y * ymax, str, COLOUR.warning, true, false, 1)
            str = string.format(
                '%s/%s',
                no_powerup and 'No powerup' or 'Big',
                store.Yoshi_riding_flag and 'Yoshi' or 'No Yoshi'
            )
            draw.text(
                xmin,
                draw.AR_y * ymax + draw.font_height(),
                str,
                COLOUR.warning,
                true,
                false,
                1
            )
        end
    end

    -- Sprites
    if OPTIONS.display_sprite_vanish_area then
        if tile.read_screens() == 'Horizontal' then
            local ydeath = 432
            local _, y_screen = screen_coordinates(0, ydeath, store.Camera_x, store.Camera_y)

            if draw.AR_y * y_screen < draw.Buffer_height + draw.Border_bottom then
                draw.line(
                    -draw.Border_left,
                    y_screen,
                    draw.Screen_width + draw.Border_right,
                    y_screen,
                    2,
                    COLOUR.weak
                )
                local str = string.format('Sprite %s: %d', 'death', ydeath)
                draw.text(-draw.Border_left, draw.AR_y * y_screen, str, COLOUR.weak, true)
            end
        end
    end
end

return M
