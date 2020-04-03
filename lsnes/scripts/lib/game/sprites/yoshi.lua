local M = {}

local memory, bit = _G.memory, _G.bit

local config = require('config')
local draw = require('draw')
local widget = require('widget')
local smw = require('game.smw')
local state = require('game.state')

local floor = math.floor
local fmt = string.format
local u8 = memory.readbyte
local u16 = memory.readword
local WRAM = smw.WRAM
local SMW = smw.constant
local screen_coordinates = smw.screen_coordinates
local OPTIONS = config.OPTIONS
local COLOUR = config.COLOUR
local store = state.store
local LEFT_ARROW = config.LEFT_ARROW
local RIGHT_ARROW = config.RIGHT_ARROW

local function yoshi_tongue_offset(xoff, tongue_length)
    if (xoff % 0x100) < 0x80 then
        xoff = xoff + tongue_length
    else
        xoff = (xoff + bit.bxor(tongue_length, 0xff) % 0x100 + 1) % 0x100
        if (xoff % 0x100) >= 0x80 then xoff = xoff - 0x100 end
    end

    return xoff
end

local function yoshi_tongue_time_predictor(len, timer, wait, out, eat_id)
    local info, color
    if wait > 9 then
        info = wait - 9
        color = COLOUR.tongue_line -- not ready yet
    elseif out == 1 then
        info = 17 + wait
        color = COLOUR.text -- tongue going out
    elseif out == 2 then -- at the max or tongue going back
        info = math.max(wait, timer) + floor((len + 7) / 4) - (len ~= 0 and 1 or 0)
        color = eat_id == SMW.null_sprite_id and COLOUR.text or COLOUR.warning
    elseif out == 0 then
        info = 0
        color = COLOUR.text -- tongue in
    else
        info = timer + 1
        color = COLOUR.tongue_line -- item was just spat out
    end

    return info, color
end

function M.info()
    if not OPTIONS.display_yoshi_info then return end

    -- Font
    draw.Font = false
    draw.Text_opacity = 1.0
    draw.Bg_opacity = 1.0
    local x_text = draw.AR_x * widget:get_property('yoshi', 'x')
    local y_text = draw.AR_y * widget:get_property('yoshi', 'y')

    local yoshi_id = smw.get_yoshi_id()
    widget:set_property('yoshi', 'display_flag', OPTIONS.display_yoshi_info and yoshi_id)

    local visible_yoshi = u8('WRAM', WRAM.yoshi_loose_flag) - 1
    if visible_yoshi >= 0 and visible_yoshi ~= yoshi_id then
        draw.Font = 'Uzebox6x8'
        draw.text(x_text, y_text,
                  string.format('Yoshi slot diff: %s vs RAM %d', yoshi_id, visible_yoshi),
                  COLOUR.warning)
        y_text = y_text + draw.font_height()
        draw.Font = false

        yoshi_id = visible_yoshi -- use delayed Yoshi slot
    end

    if yoshi_id ~= nil then
        local tongue_len = u8('WRAM', WRAM.sprite_misc_151c + yoshi_id)
        local tongue_timer = u8('WRAM', WRAM.sprite_misc_1558 + yoshi_id)
        local yoshi_direction = u8('WRAM', WRAM.sprite_horizontal_direction + yoshi_id)
        local tongue_out = u8('WRAM', WRAM.sprite_misc_1594 + yoshi_id)
        local turn_around = u8('WRAM', WRAM.sprite_misc_15ac + yoshi_id)
        local tile_index = u8('WRAM', WRAM.sprite_misc_1602 + yoshi_id)
        local eat_id = u8('WRAM', WRAM.sprite_misc_160e + yoshi_id)
        local mount_invisibility = u8('WRAM', WRAM.sprite_misc_163e + yoshi_id)
        local eat_type = u8('WRAM', WRAM.sprite_number + eat_id)
        local tongue_wait = u8('WRAM', WRAM.sprite_tongue_wait)
        local tongue_height = u8('WRAM', WRAM.yoshi_tile_pos)
        local yoshi_in_pipe = u8('WRAM', WRAM.yoshi_in_pipe)

        local eat_type_str = eat_id == SMW.null_sprite_id and '-' or string.format('%02x', eat_type)
        local eat_id_str = eat_id == SMW.null_sprite_id and '-' or string.format('#%02x', eat_id)

        -- Yoshi's direction and turn around
        local direction_symbol
        if yoshi_direction == 0 then
            direction_symbol = RIGHT_ARROW
        else
            direction_symbol = LEFT_ARROW
        end

        draw.text(x_text, y_text, fmt('Yoshi %s %d', direction_symbol, turn_around), COLOUR.yoshi)
        local h = draw.font_height()

        if eat_id == SMW.null_sprite_id and tongue_len == 0 and tongue_timer == 0 and tongue_wait ==
        0 then draw.Font = 'snes9xluasmall' end
        draw.text(x_text, y_text + h, fmt('(%0s, %0s) %02d, %d, %d', eat_id_str, eat_type_str,
                                          tongue_len, tongue_wait, tongue_timer), COLOUR.yoshi)
        -- more WRAM values
        local yoshi_x = memory.sread_sg('WRAM', WRAM.sprite_x_low + yoshi_id,
                                        WRAM.sprite_x_high + yoshi_id)
        local yoshi_y = memory.sread_sg('WRAM', WRAM.sprite_y_low + yoshi_id,
                                        WRAM.sprite_y_high + yoshi_id)
        local x_screen, y_screen = screen_coordinates(yoshi_x, yoshi_y, store.Camera_x,
                                                      store.Camera_y)

        -- invisibility timer
        draw.Font = 'Uzebox6x8'
        if mount_invisibility ~= 0 then
            draw.text(draw.AR_x * (x_screen + 4), draw.AR_x * (y_screen - 12), mount_invisibility,
                      COLOUR.yoshi)
        end

        -- Tongue hitbox and timer
        if tongue_wait ~= 0 or tongue_out ~= 0 or tongue_height == 0x89 then -- if tongue is out or appearing
            -- Color
            local tongue_line
            if tongue_wait <= 9 then
                tongue_line = COLOUR.tongue_line
            else
                tongue_line = COLOUR.tongue_bg
            end

            -- Tongue Hitbox
            local actual_index = tile_index
            if yoshi_direction == 0 then actual_index = tile_index + 8 end
            actual_index = yoshi_in_pipe ~= 0 and u8('WRAM', 0x0d) or
                           smw.YOSHI_TONGUE_X_OFFSETS[actual_index] or 0

            local xoff = yoshi_tongue_offset(actual_index, tongue_len)

            -- tile_index changes midframe, according to yoshi_in_pipe address
            local yoff = yoshi_in_pipe ~= 0 and 3 or smw.YOSHI_TONGUE_Y_OFFSETS[tile_index] or 0
            yoff = yoff + 2
            draw.rectangle(x_screen + xoff, y_screen + yoff, 8, 4, tongue_line, COLOUR.tongue_bg)
            draw.pixel(x_screen + xoff, y_screen + yoff, COLOUR.text, COLOUR.tongue_bg) -- hitbox point vs berry tile

            -- glitched hitbox for Layer Switch Glitch
            if yoshi_in_pipe ~= 0 then
                local xoffGlitch = yoshi_tongue_offset(0x40, tongue_len) -- from ROM
                draw.rectangle(x_screen + xoffGlitch, y_screen + yoff, 8, 4, 0x80ffffff, 0xc0000000)

                draw.Font = 'Uzebox8x12'
                draw.text(x_text, y_text + 2 * h, fmt('$1a: %.4x $1c: %.4x',
                                                      u16('WRAM', WRAM.layer1_x_mirror),
                                                      u16('WRAM', WRAM.layer1_y_mirror)),
                          COLOUR.yoshi)
                draw.text(x_text, y_text + 3 * h,
                          fmt('$4d: %.4x $4f: %.4x', u16('WRAM', WRAM.layer1_VRAM_left_up),
                              u16('WRAM', WRAM.layer1_VRAM_right_down)), COLOUR.yoshi)
            end

            -- tongue out: time predictor
            local info, color = yoshi_tongue_time_predictor(tongue_len, tongue_timer, tongue_wait,
                                                            tongue_out, eat_id)
            draw.Font = 'Uzebox6x8'
            draw.text(draw.AR_x * (x_screen + xoff + 4), draw.AR_y * (y_screen + yoff + 5), info,
                      color, false, false, 0.5)
        end
    elseif memory.readbyte('WRAM', WRAM.yoshi_overworld_flag) ~= 0 then -- if there's no Yoshi
        draw.Font = 'Uzebox6x8'
        draw.text(x_text, y_text, 'Yoshi on overworld', COLOUR.yoshi)
    end
end

return M
