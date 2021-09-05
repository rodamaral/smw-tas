local M = {}

local luap = require 'luap'
local mem = require 'memory'
local config = require 'config'
local draw = require 'draw'
local smw = require 'game.smw'

local u8 = mem.u8
local s16 = mem.s16
local fmt = string.format
local OPTIONS = config.OPTIONS
local COLOUR = config.COLOUR
local screen_coordinates = smw.screen_coordinates
local WRAM = smw.WRAM
local SMW = smw.constant
local knownSprites = smw.HITBOX_CLUSTER_SPRITE

-- sprite_table environment
do
    local realFrame, xCam, yCam, clusterspr_number, xPos, yPos, xText, yText, reappearing_boo_counter, special_info, xScreen, yScreen, xoff, yoff, xrad, yrad, height, counter, color, color_bg, invincibility_hitbox, oscillation

    local glitchedOffsets = {
        xoff = 0,
        yoff = 0,
        width = 16,
        height = 16,
        color_line = COLOUR.awkward_hitbox,
        color_bg = COLOUR.awkward_hitbox_bg,
        oscillation = 1,
    }

    local function display_hitbox(id)
        color = invincibility_hitbox and COLOUR.weak or color
        color_bg = (invincibility_hitbox and -1) or (oscillation and color_bg) or -1
        if OPTIONS.display_cluster_sprite_hitbox then
            draw.rectangle(xScreen + xoff, yScreen + yoff, xrad, yrad, color, color_bg)
        end
        if OPTIONS.display_cluster_sprite_info then
            draw.text(
                draw.AR_x * (xScreen + xoff) + xrad,
                draw.AR_y * (yScreen + yoff),
                special_info and id .. special_info or id,
                color,
                false,
                false,
                0.5,
                1.0
            )
        end
    end

    local function sprite_info(id)
        if not knownSprites[clusterspr_number] then
            -- should not happen without ACE
            print('Warning: wrong cluster sprite number:', clusterspr_number)
            return
        end

        -- Reads WRAM addresses
        xPos = luap.signed16(256 * u8(WRAM.cluspr_x_high + id) + u8(WRAM.cluspr_x_low + id))
        yPos = luap.signed16(256 * u8(WRAM.cluspr_y_high + id) + u8(WRAM.cluspr_y_low + id))
        local clusterspr_timer, table_1, table_2, table_3

        -- Reads cluster's table
        xScreen, yScreen = screen_coordinates(xPos, yPos, xCam, yCam)

        local t = knownSprites[clusterspr_number] or glitchedOffsets
        xoff = t.xoff
        yoff = t.yoff
        xrad = t.width
        yrad = t.height
        local phase = t.phase or 0
        oscillation = (realFrame - id) % t.oscillation == phase
        color = t.color or COLOUR.cluster_sprites
        color_bg = t.bg or COLOUR.sprites_bg
        invincibility_hitbox = nil

        if OPTIONS.display_debug_cluster_sprite then
            table_1 = u8(WRAM.cluspr_table_1 + id)
            table_2 = u8(WRAM.cluspr_table_2 + id)
            table_3 = u8(WRAM.cluspr_table_3 + id)
            draw.text(
                xText,
                yText + counter * height,
                fmt(
                    '#%d(%d): (%d, %d) %d, %d, %d',
                    id,
                    clusterspr_number,
                    xPos,
                    yPos,
                    table_1,
                    table_2,
                    table_3
                ),
                color
            )
            counter = counter + 1
        end

        -- Case analysis
        if clusterspr_number == 3 or clusterspr_number == 8 then
            clusterspr_timer = u8(WRAM.cluspr_timer + id)
            if clusterspr_timer ~= 0 then
                special_info = ' ' .. clusterspr_timer
            end
        elseif clusterspr_number == 6 then
            table_1 = table_1 or u8(WRAM.cluspr_table_1 + id)
            if table_1 >= 111 or (table_1 < 31 and table_1 >= 16) then
                yoff = yoff + 17
            elseif table_1 >= 103 or table_1 < 16 then
                invincibility_hitbox = true
            elseif table_1 >= 95 or (table_1 < 47 and table_1 >= 31) then
                yoff = yoff + 16
            end
        elseif clusterspr_number == 7 then
            reappearing_boo_counter = reappearing_boo_counter or u8(WRAM.reappearing_boo_counter)
            invincibility_hitbox = (reappearing_boo_counter > 0xde)
                or (reappearing_boo_counter < 0x3f)
            special_info = ' ' .. reappearing_boo_counter
        end

        display_hitbox(id)
    end

    function M.sprite_table()
        if u8(WRAM.cluspr_flag) == 0 then
            return
        end

        draw.Text_opacity = 1.0
        draw.Font = 'Uzebox6x8'
        height = draw.font_height()
        xText = draw.AR_x * 90
        yText = draw.AR_y * 67
        counter = 0
        realFrame = u8(WRAM.real_frame)
        xCam = s16(WRAM.camera_x)
        yCam = s16(WRAM.camera_y)

        if OPTIONS.display_debug_cluster_sprite then
            draw.text(xText, yText, 'Cluster Spr.', COLOUR.weak)
            counter = counter + 1
        end

        for id = 0, SMW.cluster_sprite_max - 1 do
            clusterspr_number = u8(WRAM.cluspr_number + id)
            if clusterspr_number ~= 0 then
                sprite_info(id)
            end
        end
    end
end

return M
