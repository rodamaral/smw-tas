local M = {}

local memory, bit = _G.memory, _G.bit

local config = require('config')
local draw = require('draw')
local widget = require('widget')
local Display = require('display')
local image = require('game.image')
local smw = require('game.smw')
local state = require('game.state')
local Sprites_info = require('game.sprites.spriteinfo')
local spriteMiscTables = require('game.sprites.miscsprite')
local special_sprite_property = require('game.sprites.specialsprites')

local floor = math.floor
local fmt = string.format
local u8 = memory.readbyte
local WRAM = smw.WRAM
local SMW = smw.constant
local SPRITE_MEMORY_MAX = smw.SPRITE_MEMORY_MAX
local ABNORMAL_HITBOX_SPRITES = smw.ABNORMAL_HITBOX_SPRITES
local DBITMAPS = image.dbitmaps
local OPTIONS = config.OPTIONS
local COLOUR = config.COLOUR
local store = state.store

local Yoshi_stored_sprites = {}
local function get_swallowed_sprites()
    Yoshi_stored_sprites = {}
    local visible_yoshi = u8('WRAM', WRAM.yoshi_slot) - 1
    for slot = 0, SMW.sprite_max - 1 do
        -- if slot is a Yoshi:
        if u8('WRAM', WRAM.sprite_number + slot) == 0x35 and u8('WRAM', WRAM.sprite_status + slot) ~=
        0 then
            local licked_slot = u8('WRAM', WRAM.sprite_misc_160e + slot)
            Yoshi_stored_sprites[licked_slot] = visible_yoshi == slot and 1 or 0
        end
    end
end

-- draw normal sprite vs Mario hitbox
local function draw_sprite_hitbox(slot)
    if not OPTIONS.display_sprite_hitbox then return end

    local t = Sprites_info[slot]
    -- Load values
    local number = t.number
    local x_screen = t.x_screen
    local y_screen = t.y_screen
    local xpt_left = t.xpt_left
    local ypt_left = t.ypt_left
    local xpt_right = t.xpt_right
    local ypt_right = t.ypt_right
    local xpt_up = t.xpt_up
    local ypt_up = t.ypt_up
    local xpt_down = t.xpt_down
    local ypt_down = t.ypt_down
    local xoff = t.hitbox_xoff
    local yoff = t.hitbox_yoff
    local width = t.hitbox_width
    local height = t.hitbox_height

    -- Settings
    local display_hitbox = Display.sprite_hitbox[slot][number].sprite and
                           not ABNORMAL_HITBOX_SPRITES[number]
    local display_clipping = Display.sprite_hitbox[slot][number].block
    local alive_status = (t.status == 0x03 or t.status >= 0x08)
    local info_color = alive_status and t.info_color or COLOUR.very_weak
    local background_color = alive_status and t.background_color or -1

    -- That's the pixel that appears when the sprite vanishes in the pit
    if y_screen >= 224 or OPTIONS.display_debug_sprite_extra then
        draw.pixel(x_screen, y_screen, info_color, COLOUR.very_weak)
    end

    if display_clipping then -- sprite clipping background
        draw.box(x_screen + xpt_left, y_screen + ypt_down, x_screen + xpt_right, y_screen + ypt_up,
                 2, COLOUR.sprites_clipping_bg, display_hitbox and -1 or COLOUR.sprites_clipping_bg)
    end

    if display_hitbox then -- show sprite/sprite clipping
        draw.rectangle(x_screen + xoff, y_screen + yoff, width, height, info_color, background_color)
    end

    if display_clipping then -- show sprite/object clipping
        local size, color = 1, COLOUR.sprites_interaction_pts
        draw.line(x_screen + xpt_right, y_screen + ypt_right, x_screen + xpt_right - size,
                  y_screen + ypt_right, 2, color) -- right
        draw.line(x_screen + xpt_left, y_screen + ypt_left, x_screen + xpt_left + size,
                  y_screen + ypt_left, 2, color) -- left
        draw.line(x_screen + xpt_down, y_screen + ypt_down, x_screen + xpt_down,
                  y_screen + ypt_down - size, 2, color) -- down
        draw.line(x_screen + xpt_up, y_screen + ypt_up, x_screen + xpt_up, y_screen + ypt_up + size,
                  2, color) -- up
    end

    -- Sprite vs sprite hitbox
    if OPTIONS.display_sprite_vs_sprite_hitbox then
        if u8('WRAM', WRAM.sprite_sprite_contact + slot) == 0 and
        u8('WRAM', WRAM.sprite_being_eaten_flag + slot) == 0 and
        bit.testn(u8('WRAM', WRAM.sprite_5_tweaker + slot), 3) then
            local boxid2 = bit.band(u8('WRAM', WRAM.sprite_2_tweaker + slot), 0x0f)
            local yoff2 = boxid2 == 0 and 2 or 0xa -- ROM data
            local bg_color = t.status >= 8 and 0x80ffffff or 0x80ff0000
            if store.Real_frame % 2 == 0 then bg_color = -1 end

            -- if y1 - y2 + 0xc < 0x18
            draw.rectangle(x_screen, y_screen + yoff2, 0x10, 0x0c, 0xffffff)
            draw.rectangle(x_screen, y_screen + yoff2, 0x10 - 1, 0x0c - 1, info_color, bg_color)
        end
    end
end

local function sprite_info(id, counter, table_position)
    local t = Sprites_info[id]
    local sprite_status = t.status
    if sprite_status == 0 then return 0 end -- returns if the slot is empty

    local x = t.x
    local y = t.y
    local x_sub = t.x_sub
    local y_sub = t.y_sub
    local number = t.number
    local stun = t.stun
    local x_speed = t.x_speed
    local y_speed = t.y_speed
    local contact_mario = t.contact_mario
    local being_eaten_flag = t.sprite_being_eaten_flag
    local underwater = t.underwater
    local x_offscreen = t.x_offscreen
    local y_offscreen = t.y_offscreen
    local behind_scenery = t.behind_scenery

    -- HUD elements
    local info_color = t.info_color

    draw_sprite_hitbox(id)

    -- Special sprites analysis:
    local fn = special_sprite_property[number]
    if fn then fn(id, Display) end

    -- Print those informations next to the sprite
    draw.Font = 'Uzebox6x8'
    draw.Text_opacity = 1.0
    draw.Bg_opacity = 1.0

    if x_offscreen ~= 0 or y_offscreen ~= 0 then draw.Text_opacity = 0.6 end

    local contact_str = contact_mario == 0 and '' or ' ' .. contact_mario

    local sprite_middle = t.sprite_middle
    local sprite_top = t.sprite_top
    if OPTIONS.display_sprite_info then
        local xdraw, ydraw = draw.AR_x * sprite_middle, draw.AR_y * sprite_top

        local behind_str = behind_scenery == 0 and '' or 'BG '
        draw.text(xdraw, ydraw, fmt('%s#%.2d%s', behind_str, id, contact_str), info_color, true,
                  false, 0.5, 1.0)

        if being_eaten_flag then DBITMAPS.yoshi_tongue:draw(xdraw, ydraw - 14) end

        if store.Player_powerup == 2 then
            local contact_cape = u8('WRAM', WRAM.sprite_disable_cape + id)
            if contact_cape ~= 0 then
                draw.text(xdraw, ydraw - 2 * draw.font_height(), contact_cape, COLOUR.cape, true)
            end
        end
    end

    -- The sprite table:
    if OPTIONS.display_sprite_info then
        draw.Font = false
        local x_speed_water = ''
        if underwater ~= 0 then -- if sprite is underwater
            local correction = 3 * floor(floor(x_speed / 2) / 2)
            x_speed_water = string.format('%+.2d=%+.2d', correction - x_speed, correction)
        end
        local sprite_str = fmt('#%02d %02x %s%d.%1x(%+.2d%s) %d.%1x(%+.2d)', id, number,
                               t.table_special_info, x, floor(x_sub / 16), x_speed, x_speed_water,
                               y, floor(y_sub / 16), y_speed)

        -- Signal stun glitch
        if sprite_status == 9 and stun ~= 0 and not smw.NORMAL_STUNNABLE[number] then
            sprite_str = 'Stun Glitch! ' .. sprite_str
        end

        local w = DBITMAPS.yoshi_tongue:size()
        local xdraw, ydraw =
        draw.Buffer_width + draw.Border_right - #sprite_str * draw.font_width() - w,
        table_position + counter * draw.font_height()
        if Yoshi_stored_sprites[id] == 0 then
            DBITMAPS.yoshi_full_mouth_trans:draw(xdraw, ydraw)
        elseif Yoshi_stored_sprites[id] == 1 then
            DBITMAPS.yoshi_full_mouth:draw(xdraw, ydraw)
        end

        draw.text(draw.Buffer_width + draw.Border_right,
                  table_position + counter * draw.font_height(), sprite_str, info_color, true)
    end

    return 1
end

function M.info()
    local counter = 0
    local table_position = draw.AR_y * 40 -- lsnes
    get_swallowed_sprites()
    for id = 0, SMW.sprite_max - 1 do
        Sprites_info.scan_sprite_info(Sprites_info, id)
        counter = counter + sprite_info(id, counter, table_position)
    end

    if OPTIONS.display_sprite_info then
        -- Font
        draw.Font = 'Uzebox6x8'
        draw.Text_opacity = 1.0
        draw.Bg_opacity = 1.0

        local swap_slot = u8('WRAM', WRAM.sprite_swap_slot)
        local smh = u8('WRAM', WRAM.sprite_memory_header)
        draw.text(draw.Buffer_width + draw.Border_right, table_position - 2 * draw.font_height(),
                  fmt('spr:%.2d ', counter), COLOUR.weak, true)
        draw.text(draw.Buffer_width + draw.Border_right, table_position - draw.font_height(),
                  fmt('1st div: %d. Swap: %d ', SPRITE_MEMORY_MAX[smh] or 0, swap_slot),
                  COLOUR.weak, true)
    end

    -- Miscellaneous sprite table: index
    if OPTIONS.display_miscellaneous_sprite_table then
        draw.Font = false
        local w = draw.font_width()
        local tab = 'spriteMiscTables'
        local x, y = draw.AR_x * widget:get_property(tab, 'x'),
                     draw.AR_y * widget:get_property(tab, 'y')
        widget:set_property(tab, 'display_flag', true)
        draw.font[draw.Font](x, y, 'Sprite Tables:\n ', COLOUR.text, 0x202020)
        y = y + 16
        for i = 0, SMW.sprite_max - 1 do
            if not spriteMiscTables.slot[i] then
                draw.button(x, y, string.format('%X', i), function()
                    spriteMiscTables:new(i)
                end, {button_pressed = false})
            else
                draw.button(x, y, string.format('%X', i),
                            function() spriteMiscTables:destroy(i) end, {button_pressed = true})
            end
            x = x + w + 1
        end
    end

    spriteMiscTables:main()
end

return M
