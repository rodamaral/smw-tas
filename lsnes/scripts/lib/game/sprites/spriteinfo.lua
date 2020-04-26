local M = {}

local bit = _G.bit

local luap = require 'luap'
local mem = require('memory')
local config = require 'config'
local smw = require 'game.smw'

local WRAM = smw.WRAM
local SMW = smw.constant
local screen_coordinates = smw.screen_coordinates
local hitboxSprite = smw.HITBOX_SPRITE
local clippingSprite = smw.OBJ_CLIPPING_SPRITE
local spriteOscillation = smw.OSCILLATION_SPRITES
local options = config.OPTIONS
local color = config.COLOUR

local u8 = mem.u8
local s8 = mem.s8
local s16 = mem.s16
local floor = math.floor
local fmt = string.format

-- Inner table for each sprite
for i = 0, SMW.sprite_max - 1 do M[i] = {} end

function M.scan_sprite_info(lua_table, slot)
    local t = lua_table[slot]
    if not t then error 'Wrong Sprite table' end

    t.status = u8(WRAM.sprite_status + slot)
    if t.status == 0 then
        return -- returns if the slot is empty
    end

    local realFrame = u8(WRAM.real_frame)
    local xCam = s16(WRAM.camera_x)
    local yCam = s16(WRAM.camera_y)
    local x = 256 * u8(WRAM.sprite_x_high + slot) + u8(WRAM.sprite_x_low + slot)
    local y = 256 * u8(WRAM.sprite_y_high + slot) + u8(WRAM.sprite_y_low + slot)
    t.x_sub = u8(WRAM.sprite_x_sub + slot)
    t.y_sub = u8(WRAM.sprite_y_sub + slot)
    t.number = u8(WRAM.sprite_number + slot)
    t.stun = u8(WRAM.sprite_stun_timer + slot)
    t.x_speed = s8(WRAM.sprite_x_speed + slot)
    t.y_speed = s8(WRAM.sprite_y_speed + slot)
    t.contact_mario = u8(WRAM.sprite_player_contact + slot)
    t.sprite_being_eaten_flag = u8(WRAM.sprite_being_eaten_flag + slot) ~= 0
    t.underwater = u8(WRAM.sprite_underwater + slot)
    t.x_offscreen = s8(WRAM.sprite_x_offscreen + slot)
    t.y_offscreen = s8(WRAM.sprite_y_offscreen + slot)
    t.behind_scenery = u8(WRAM.sprite_behind_scenery + slot)

    -- Transform some read values into intelligible content
    t.x = luap.signed16(x)
    t.y = luap.signed16(y)
    t.x_screen, t.y_screen = screen_coordinates(t.x, t.y, xCam, yCam)

    if options.display_debug_sprite_extra or ((t.status < 0x8 and t.status > 0xb) or t.stun ~= 0) then
        t.table_special_info = fmt('(%d %d) ', t.status, t.stun)
    else
        t.table_special_info = ''
    end

    t.oscillation_flag = bit.test(u8(WRAM.sprite_4_tweaker + slot), 5) or
                         spriteOscillation[t.number]

    -- Sprite clipping vs mario and sprites
    local boxid = bit.band(u8(WRAM.sprite_2_tweaker + slot), 0x3f) -- This is the type of box of the sprite
    t.hitbox_id = boxid
    t.hitbox_xoff = hitboxSprite[boxid].xoff
    t.hitbox_yoff = hitboxSprite[boxid].yoff
    t.hitbox_width = hitboxSprite[boxid].width
    t.hitbox_height = hitboxSprite[boxid].height

    -- Sprite clipping vs objects
    local clip_obj = bit.band(u8(WRAM.sprite_1_tweaker + slot), 0xf) -- type of hitbox for blocks
    t.clipping_id = clip_obj
    t.xpt_right = clippingSprite[clip_obj].xright
    t.ypt_right = clippingSprite[clip_obj].yright
    t.xpt_left = clippingSprite[clip_obj].xleft
    t.ypt_left = clippingSprite[clip_obj].yleft
    t.xpt_down = clippingSprite[clip_obj].xdown
    t.ypt_down = clippingSprite[clip_obj].ydown
    t.xpt_up = clippingSprite[clip_obj].xup
    t.ypt_up = clippingSprite[clip_obj].yup

    -- Some HUD configurations
    -- calculate the correct color to use, according to slot
    if t.number == 0x35 then
        t.info_color = color.yoshi
        t.background_color = color.yoshi_bg
    else
        t.info_color = color.sprites[slot % (#color.sprites) + 1]
        t.background_color = color.sprites_bg
    end
    if (not t.oscillation_flag) and (realFrame - slot) % 2 == 1 then t.background_color = -1 end

    t.sprite_middle = t.x_screen + t.hitbox_xoff + floor(t.hitbox_width / 2)
    t.sprite_top = t.y_screen + math.min(t.hitbox_yoff, t.ypt_up)
end

return M
