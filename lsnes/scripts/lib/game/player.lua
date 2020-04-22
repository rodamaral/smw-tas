local M = {}

local memory, bit, gui = _G.memory, _G.bit, _G.gui

local config = require('config')
local draw = require('draw')
local Display = require('display')
local widget = require('widget')
local smw = require('game.smw')
local image = require('game.image')
local state = require('game.state')

local u8 = memory.readbyte
local u16 = memory.readword
local floor = math.floor
local fmt = string.format
local OPTIONS = config.OPTIONS
local COLOUR = config.COLOUR
local LEFT_ARROW = config.LEFT_ARROW
local RIGHT_ARROW = config.RIGHT_ARROW
local store = state.store
local screen_coordinates = smw.screen_coordinates
local WRAM = smw.WRAM
local BITMAPS = image.bitmaps
local DBITMAPS = image.dbitmaps
local Palettes_adjusted = image.Palettes_adjusted
local X_INTERACTION_POINTS = smw.X_INTERACTION_POINTS
local Y_INTERACTION_POINTS = smw.Y_INTERACTION_POINTS

-- Private
local CAPE_LEFT = -2
local CAPE_RIGHT = 0x12
local CAPE_UP = 0x01
local CAPE_DOWN = 0x11
local CAPE_MIDDLE = 0x08

local hitbox_renderctx

local function get_palette(palette, transparency_level)
    local used_palette
    if not palette then
        if transparency_level == 1 then
            used_palette = DBITMAPS.interaction_points_palette
        else
            used_palette = draw.copy_palette(DBITMAPS.interaction_points_palette)
            used_palette:adjust_transparency(floor(transparency_level * 0x100))
        end
    else
        used_palette = palette
    end

    return used_palette
end

local function draw_hitbox_background(left, right, top, bottom, interaction_bg)
    draw.box(left, top, right, bottom, 2, interaction_bg, interaction_bg)
end

local function draw_hitbox_sprites(x_screen, y_screen, hitbox_type, mario_line)
    if OPTIONS.display_player_hitbox then
        local hitbox_offsets = smw.PLAYER_HITBOX[hitbox_type]
        local xoff = hitbox_offsets.xoff
        local yoff = hitbox_offsets.yoff
        local width = hitbox_offsets.width
        local height = hitbox_offsets.height

        local mario_bg = (not store.Yoshi_riding_flag and COLOUR.mario_bg) or
                         COLOUR.mario_mounted_bg
        draw.rectangle(x_screen + xoff, y_screen + yoff, width, height, mario_line, mario_bg)
    end
end

local function draw_interaction_points(x_screen, y_screen, left_side, right_side, head, foot,
                                       hitbox_type, palette)
    -- interaction points (collision with blocks)
    if OPTIONS.display_interaction_points then
        if not OPTIONS.display_player_hitbox then
            draw.box(x_screen + left_side, y_screen + head, x_screen + right_side, y_screen + foot,
                     2, COLOUR.interaction_nohitbox, COLOUR.interaction_nohitbox_bg)
        end

        gui.bitmap_draw(draw.AR_x * x_screen, draw.AR_y * y_screen,
                        DBITMAPS.interaction_points[hitbox_type], palette)
    end
end

local function draw_mario_pixel(x_screen, y_screen)
    -- That's the pixel that appears when Mario dies in the pit
    Display.show_player_point_position = Display.show_player_point_position or
                                         Display.is_player_near_borders or
                                         OPTIONS.display_debug_player_extra
    if Display.show_player_point_position then
        draw.pixel(x_screen, y_screen, COLOUR.text, COLOUR.interaction_bg)
        Display.show_player_point_position = false
    end
end

local function display_slide(props, slide_flag)
    local table_x, table_y, delta_y, i = props.table_x, props.table_y, props.delta_y, props.i

    if slide_flag ~= 0x1c and slide_flag ~= 0x80 then
        local format = OPTIONS.prefer_decimal_format and '%d' or '%x'
        draw.text(table_x, table_y + i * delta_y, fmt('Slide ' .. format, slide_flag),
                  COLOUR.warning)
    end
end

local function display_momentum(props, direction, spin_direction, slide_flag)
    local table_x, table_y, delta_x, delta_y, i = props.table_x, props.table_y, props.delta_x,
                                                  props.delta_y, props.i
    local inc = 0
    local color =
    slide_flag == 0 and COLOUR.text or slide_flag == 0x1c and 0xffd060 or slide_flag == 0x80 and
    0xd0ff60 or COLOUR.warning

    if OPTIONS.prefer_decimal_format then
        draw.text(table_x, table_y + i * delta_y,
                  fmt('Meter (%03d, %02d) %s', store.p_meter, store.take_off, direction), color)
        inc = 1
    else
        draw.text(table_x, table_y + i * delta_y,
                  fmt('Meter (%02x, %02x) %s', store.p_meter, store.take_off, direction), color)
    end

    local is_spinning = store.cape_spin ~= 0 or store.spinjump_flag ~= 0
    draw.text(table_x + (17 + inc) * delta_x, table_y + i * delta_y, fmt(' %+d', spin_direction),
              (is_spinning and COLOUR.text) or COLOUR.weak)

    if store.pose_turning ~= 0 then
        gui.text(draw.AR_x * (store.Player_x_screen + 6), draw.AR_y * (store.Player_y_screen - 4),
                 store.pose_turning, COLOUR.warning2, 0x40000000)
    end
end

local function display_position_decimal(props, x_sub_simple, y_sub_simple)
    local table_x = props.table_x
    local table_y = props.table_y
    local delta_y = props.delta_y
    local i = props.i

    local x_speed_int, x_speed_frac = math.modf(store.x_speed + store.x_subspeed / 0x100)
    x_speed_frac = math.abs(x_speed_frac * 100)

    draw.text(table_x, table_y + i * delta_y, fmt('Pos (%+d.%s, %+d.%s)', store.Player_x,
                                                  x_sub_simple, store.Player_y, y_sub_simple))
    i = i + 1

    draw.text(table_x, table_y + i * delta_y, fmt('Speed (%+d(%d.%02.0f), %+d)', store.x_speed,
                                                  x_speed_int, x_speed_frac, store.y_speed))
end

local function display_position_hexadecimal(props, x_sub_simple, y_sub_simple)
    local table_x = props.table_x
    local table_y = props.table_y
    local delta_y = props.delta_y
    local i = props.i

    draw.text(table_x, table_y + i * delta_y,
              fmt('Pos (%+x.%s, %+x.%s)', store.Player_x % 0x10000, x_sub_simple,
                  store.Player_y % 0x10000, y_sub_simple))
    i = i + 1

    draw.text(table_x, table_y + i * delta_y, fmt('Speed (%+x.%.2x, %+x)', store.x_speed % 0x100,
                                                  store.x_subspeed, store.y_speed % 0x100))
end

local function display_position(props)
    local x_sub_simple, y_sub_simple
    if store.x_sub % 0x10 == 0 then
        x_sub_simple = fmt('%x', store.x_sub / 0x10)
    else
        x_sub_simple = fmt('%.2x', store.x_sub)
    end
    if store.y_sub % 0x10 == 0 then
        y_sub_simple = fmt('%x', store.y_sub / 0x10)
    else
        y_sub_simple = fmt('%.2x', store.y_sub)
    end

    if OPTIONS.prefer_decimal_format then
        display_position_decimal(props, x_sub_simple, y_sub_simple)
    else
        display_position_hexadecimal(props, x_sub_simple, y_sub_simple)
    end
end

local function display_cape_values(props)
    local table_x, table_y, delta_y, i = props.table_x, props.table_y, props.delta_y, props.i

    local cape_gliding_index = u8('WRAM', WRAM.cape_gliding_index)
    local diving_status_timer = u8('WRAM', WRAM.diving_status_timer)
    local action = smw.FLIGHT_ACTIONS[cape_gliding_index] or 'bug!'

    -- TODO: better name for this "glitched" state
    if cape_gliding_index == 3 and store.y_speed > 0 then action = '*up*' end

    draw.text(table_x, table_y + i * delta_y,
              fmt('Cape (%.2d, %.2d)/(%d, %d)', store.cape_spin, store.cape_fall,
                  store.flight_animation, store.diving_status), COLOUR.cape)
    i = i + 1

    if store.flight_animation ~= 0 then
        draw.text(table_x + 10 * draw.font_width(), table_y + i * delta_y, action .. ' ',
                  COLOUR.cape)
        draw.text(table_x + 15 * draw.font_width(), table_y + i * delta_y, diving_status_timer,
                  diving_status_timer <= 1 and COLOUR.warning or COLOUR.cape)
        return 2
    end

    return 1
end

local function display_camera_values(props)
    local table_x, table_y, delta_x, delta_y, i = props.table_x, props.table_y, props.delta_x,
                                                  props.delta_y, props.i
    local x_txt

    if OPTIONS.prefer_decimal_format then
        x_txt = draw.text(table_x, table_y + i * delta_y,
                          fmt('Camera (%d, %d)', store.Camera_x, store.Camera_y))
    else
        x_txt = draw.text(table_x, table_y + i * delta_y, fmt('Camera (%x, %x)',
                                                              store.Camera_x % 0x10000,
                                                              store.Camera_y % 0x10000))
    end
    if store.scroll_timer ~= 0 then
        x_txt = draw.text(x_txt, table_y + i * delta_y, 16 - store.scroll_timer, COLOUR.warning)
    end

    if OPTIONS.prefer_decimal_format then
        draw.font['Uzebox6x8'](table_x + 8 * delta_x, table_y + (i + 1) * delta_y, string.format(
                               '%d.%x', math.floor(store.Camera_x / 16), store.Camera_x % 16),
                               0xffffff, -1, 0) -- TODO remove
    end

    if store.vertical_scroll_flag_header ~= 0 and store.vertical_scroll_enabled ~= 0 then
        draw.text(x_txt, table_y + i * delta_y, store.vertical_scroll_enabled, COLOUR.warning2)
    end
end

local function display_player_values(direction, spin_direction, is_caped)
    if OPTIONS.display_player_info then
        local props = {
            i = 0,
            table_x = draw.AR_x * widget:get_property('player', 'x'),
            table_y = draw.AR_y * widget:get_property('player', 'y'),
            delta_x = draw.font_width(),
            delta_y = draw.font_height()
        }

        local slide_flag = store.slide_flag
        if slide_flag ~= 0 then
            display_slide(props, slide_flag)
            props.i = props.i + 1
        end

        display_momentum(props, direction, spin_direction, slide_flag)
        props.i = props.i + 1

        display_position(props)
        props.i = props.i + 2

        if is_caped then
            local inc = display_cape_values(props)
            props.i = props.i + inc
        end

        display_camera_values(props)
        props.i = props.i + 1

        M.draw_blocked_status(props.table_x, props.table_y + props.i * props.delta_y,
                              store.player_blocked_status, store.x_speed, store.y_speed)
        props.i = props.i + 1

        -- Wings timers is the same as the cape
        if (not is_caped and store.cape_fall ~= 0) then
            draw.text(props.table_x, props.table_y + props.i * props.delta_y,
                      fmt('Wings: %.2d', store.cape_fall), COLOUR.text)
        end
    end
end

local function display_camera_region()
    if OPTIONS.display_static_camera_region then
        Display.show_player_point_position = true

        -- Horizontal scroll
        local left_cam = u16('WRAM', WRAM.camera_left_limit)
        local right_cam = u16('WRAM', WRAM.camera_right_limit)
        local center_cam = math.floor((left_cam + right_cam) / 2)
        draw.box(left_cam, 0, right_cam, 224, COLOUR.static_camera_region,
                 COLOUR.static_camera_region)
        draw.line(center_cam, 0, center_cam, 224, 2, 'black')
        draw.text(draw.AR_x * left_cam, 0, left_cam, COLOUR.text, 0x400020, false, false, 1, 0)
        draw.text(draw.AR_x * right_cam, 0, right_cam, COLOUR.text, 0x400020)

        -- Vertical scroll
        if store.vertical_scroll_flag_header ~= 0 then
            draw.box(0, 100, 255, 124, COLOUR.static_camera_region, COLOUR.static_camera_region) -- FIXME for PAL
        end
    end
end

-- Public
function M.use_render_context(context) hitbox_renderctx = context end

function M.draw_blocked_status(x_text, y_text, player_blocked_status, x_speed, y_speed)
    local width = 14
    local height = 20
    local block_str = 'Block:'
    local str_len = #(block_str)
    local x = x_text + str_len * draw.font_width()
    local y = y_text
    local color_line = draw.change_transparency(COLOUR.warning,
                                                draw.Text_max_opacity * draw.Text_opacity)

    local bitmap, pal = BITMAPS.player_blocked_status, Palettes_adjusted.player_blocked_status
    bitmap:draw(x, y, pal)

    local was_boosted = false

    if bit.test(player_blocked_status, 0) then -- Right
        draw.line(x + width - 2, y, x + width - 2, y + height - 2, 1, color_line)
        if x_speed < 0 then was_boosted = true end
    end

    if bit.test(player_blocked_status, 1) then -- Left
        draw.line(x, y, x, y + height - 2, 1, color_line)
        if x_speed > 0 then was_boosted = true end
    end

    if bit.test(player_blocked_status, 2) then -- Down
        draw.line(x, y + height - 2, x + width - 2, y + height - 2, 1, color_line)
    end

    if bit.test(player_blocked_status, 3) then -- Up
        draw.line(x, y, x + width - 2, y, 1, color_line)
        if y_speed > 6 then was_boosted = true end
    end

    if bit.test(player_blocked_status, 4) then -- Middle
        gui.crosshair(x + floor(width / 2), y + floor(height / 2),
                      floor(math.min(width / 2, height / 2)), color_line)
    end

    draw.text(x_text, y_text, block_str, COLOUR.text, was_boosted and COLOUR.warning_bg or nil)
end

function M.player_hitbox(x, y, is_ducking, powerup, transparency_level, original_palette)
    -- Colour settings
    local interaction_bg = draw.change_transparency(COLOUR.interaction_bg, transparency_level)
    local mario_line = draw.change_transparency(COLOUR.mario, transparency_level)
    local palette = get_palette(original_palette, transparency_level)

    -- don't use Camera_x/y midframe, as it's an old value
    local x_screen, y_screen = screen_coordinates(x, y, store.Camera_x, store.Camera_y)
    local is_small = is_ducking ~= 0 or powerup == 0
    local hitbox_type = 2 * (store.Yoshi_riding_flag and 1 or 0) + (is_small and 0 or 1) + 1

    local left_side = X_INTERACTION_POINTS.left_side
    local right_side = X_INTERACTION_POINTS.right_side
    local head = Y_INTERACTION_POINTS[hitbox_type].head
    local foot = Y_INTERACTION_POINTS[hitbox_type].foot

    draw_hitbox_background(x_screen + left_side, x_screen + right_side, y_screen + head,
                           y_screen + foot, interaction_bg)
    draw_hitbox_sprites(x_screen, y_screen, hitbox_type, mario_line)
    draw_interaction_points(x_screen, y_screen, left_side, right_side, head, foot, hitbox_type,
                            palette)
    draw_mario_pixel(x_screen, y_screen)
end

-- displays the hitbox of the cape while spinning
function M.cape_hitbox(spin_direction)
    local cape_interaction = u8('WRAM', WRAM.cape_interaction)
    if cape_interaction == 0 then return end

    local cape_x = u16('WRAM', WRAM.cape_x)
    local cape_y = u16('WRAM', WRAM.cape_y)
    local cape_x_screen, cape_y_screen = screen_coordinates(cape_x, cape_y, store.Camera_x,
                                                            store.Camera_y)
    local block_interaction_cape = (spin_direction < 0 and CAPE_LEFT + 4) or CAPE_RIGHT - 4
    -- active iff the cape can hit a sprite
    local active_frame_sprites = store.Real_frame % 2 == 1
    -- active iff the cape can hit a block
    local active_frame_blocks = store.Real_frame % 2 == (spin_direction < 0 and 0 or 1)

    local bg_color = active_frame_sprites and COLOUR.cape_bg or -1
    draw.box(cape_x_screen + CAPE_LEFT, cape_y_screen + CAPE_UP, cape_x_screen + CAPE_RIGHT,
             cape_y_screen + CAPE_DOWN, 2, COLOUR.cape, bg_color)

    if active_frame_blocks then
        draw.pixel(cape_x_screen + block_interaction_cape, cape_y_screen + CAPE_MIDDLE,
                   COLOUR.warning)
    else
        draw.pixel(cape_x_screen + block_interaction_cape, cape_y_screen + CAPE_MIDDLE, COLOUR.text)
    end
end

function M.info()
    -- Font
    draw.Font = false
    draw.Text_opacity = 1.0
    draw.Bg_opacity = 1.0

    -- Reads WRAM
    local direction = store.direction

    -- Prediction
    local next_x = floor((256 * store.Player_x + store.x_sub + 16 * store.x_speed) / 256)
    local next_y = floor((256 * store.Player_y + store.y_sub + 16 * store.y_speed) / 256)

    -- Transformations
    if direction == 0 then
        direction = LEFT_ARROW
    else
        direction = RIGHT_ARROW
    end

    local spin_direction = (store.Effective_frame) % 8
    if spin_direction < 4 then
        spin_direction = spin_direction + 1
    else
        spin_direction = 3 - spin_direction
    end

    local is_caped = store.Player_powerup == 0x2

    -- Display info
    widget:set_property('player', 'display_flag', OPTIONS.display_player_info)
    display_player_values(direction, spin_direction, is_caped)
    display_camera_region()

    -- Mario boost indicator
    state.set_previous('x', store.Player_x)
    state.set_previous('y', store.Player_y)
    state.set_previous('next_x', next_x)
    --[[ if OPTIONS.register_player_position_changes and Registered_addresses.mario_position ~= '' then
    local x_screen,
      y_screen = store.Player_x_screen, store.Player_y_screen
    gui.text(
      draw.AR_x * (x_screen + 4 - #Registered_addresses.mario_position),
      draw.AR_y * (y_screen + Y_INTERACTION_POINTS[store.Yoshi_riding_flag and 3 or 1].foot + 4),
      Registered_addresses.mario_position,
      COLOUR.warning,
      0x40000000
    )

    -- draw hitboxes
    hitbox_renderctx:run()
  end ]]

    -- shows hitbox and interaction points for player
    if OPTIONS.display_cape_hitbox then M.cape_hitbox(spin_direction) end
    if OPTIONS.display_player_hitbox or OPTIONS.display_interaction_points then
        M.player_hitbox(store.Player_x, store.Player_y, store.is_ducking, store.Player_powerup, 1)
    end

    -- Shows where Mario is expected to be in the next frame, if he's not boosted or stopped
    if OPTIONS.display_debug_player_extra then
        M.player_hitbox(next_x, next_y, store.is_ducking, store.Player_powerup, 0.3)
    end
end

return M
