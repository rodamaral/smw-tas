local M = {}

local luap = require 'luap'
local mem = require 'memory'
local config = require 'config'
local draw = require 'draw'
local smw = require 'game.smw'

local u8 = mem.u8
local s16 = mem.s16
local OPTIONS = config.OPTIONS
local COLOUR = config.COLOUR
local WRAM = smw.WRAM
local fmt = string.format

-- sprite_table environment
do
    local font_height, xCam, yCam, hitbox, sprite_number, interact, xPos, yPos

    local function draw_hitbox()
        draw.rectangle(
            xPos - xCam + hitbox.xoff,
            yPos - yCam + hitbox.yoff,
            hitbox.width,
            hitbox.height,
            COLOUR.quake_sprite,
            interact
        )
    end

    local function sprite_info(id)
        xPos = luap.signed16(256 * u8(0x16d5 + id) + u8(0x16d1 + id))
        yPos = luap.signed16(256 * u8(0x16dd + id) + u8(0x16d9 + id))
        local quake_timer = u8(0x18f8 + id)
        interact = quake_timer < 3 and COLOUR.quake_sprite_bg or -1

        draw_hitbox()
        draw.text(draw.AR_x * (xPos - xCam), draw.AR_x * (yPos - yCam), '#' .. id)
        draw.text(
            draw.Buffer_width,
            draw.Buffer_height + id * font_height,
            fmt('#%d %d (%d, %d) %d', id, sprite_number, xPos, yPos, quake_timer),
            COLOUR.quake_sprite,
            COLOUR.background
        )
    end

    function M.sprite_table()
        if not OPTIONS.display_quake_sprite_info then
            return
        end
        draw.Font = 'Uzebox6x8'
        font_height = draw.font_height()
        xCam = s16(WRAM.camera_x)
        yCam = s16(WRAM.camera_y)

        local hitbox_tab = smw.HITBOX_QUAKE_SPRITE
        for id = 0, 3 do
            sprite_number = u8(0x16cd + id)
            hitbox = hitbox_tab[sprite_number]

            if hitbox then
                sprite_info(id)
            end
        end
    end
end

return M
