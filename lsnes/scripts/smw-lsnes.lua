---------------------------------------------------------------------------
--  Super Mario World (U) Utility Script for Lsnes - rr2 version
--  http://tasvideos.org/Lsnes.html
--
--  Author: Rodrigo A. do Amaral (Amaraticando)
--  Git repository: https://github.com/rodamaral/smw-tas
---------------------------------------------------------------------------

--#############################################################################
-- CONFIG:

local GLOBAL_SMW_TAS_PARENT_DIR = _G.GLOBAL_SMW_TAS_PARENT_DIR
local lsnes_features,
  callback,
  gui = _G.lsnes_features, _G.callback, _G.gui

assert(GLOBAL_SMW_TAS_PARENT_DIR, 'smw-tas.lua must be run')
local INI_CONFIG_NAME = 'lsnes-config.ini'
local LUA_SCRIPT_FILENAME = load([==[return @@LUA_SCRIPT_FILENAME@@]==])()
local LUA_SCRIPT_FOLDER = LUA_SCRIPT_FILENAME:match('(.+)[/\\][^/\\+]') .. '/'
local INI_CONFIG_FILENAME = GLOBAL_SMW_TAS_PARENT_DIR .. 'config/' .. INI_CONFIG_NAME
-- TODO: save the config file in the parent directory;
--       must make the JSON library work for the other scripts first

-- END OF CONFIG < < < < < < <
--#############################################################################
-- INITIAL STATEMENTS:

print(string.format('Starting script %s', LUA_SCRIPT_FILENAME))

-- Script verifies whether the emulator is indeed Lsnes - rr2 version / beta23 or higher
if not lsnes_features or not lsnes_features('text-halos') then
  callback.paint:register(
    function()
      gui.text(0, 00, 'This script is supposed to be run on Lsnes.', 'red', 0x600000ff)
      gui.text(0, 16, 'Version: rr2-beta23 or higher.', 'red', 0x600000ff)
      gui.text(0, 32, 'Your version seems to be different.', 'red', 0x600000ff)
      gui.text(0, 48, 'Download the correct script at:', 'red', 0x600000ff)
      gui.text(0, 64, 'https://github.com/rodamaral/smw-tas/wiki/Downloads', 'red', 0x600000ff)
      gui.text(0, 80, 'Download the latest version of lsnes here', 'red', 0x600000ff)
      gui.text(0, 96, 'http://tasvideos.org/Lsnes.html', 'red', 0x600000ff)
    end
  )
  gui.repaint()
  error('This script works in a newer version of lsnes.')
end

-- Load environment
package.path = LUA_SCRIPT_FOLDER .. 'lib/?.lua' .. ';' .. package.path

local bit,
  movie,
  memory = _G.bit, _G.movie, _G.memory
local string,
  math = _G.string, _G.math
local ipairs,
  pairs,
  type = _G.ipairs, _G.pairs, _G.type
local exec,
  set_timer_timeout,
  set_idle_timeout = _G.exec, _G.set_timer_timeout, _G.set_idle_timeout

local luap = require 'luap'
local config = require 'config'
config.load_options(INI_CONFIG_FILENAME)
config.load_lsnes_fonts(LUA_SCRIPT_FOLDER)
local keyinput = require 'keyinput'
local Timer = require 'timer'
local draw = require 'draw'
local lsnes = require 'lsnes'
local joypad = require 'joypad'
local widget = require 'widget'
local cheat = require 'cheat'
local Options_menu = require 'menu'
local Lagmeter = require 'lagmeter'
local Display = require 'display'
local smw = require 'game.smw'
local tile = require 'game.tile'
local RNG = require 'game.rng'
local countdown = require 'game.countdown'
local gamecontroller = require 'game.controller'
local smwdebug = require 'game.smwdebug'
local player = require 'game.player'
local generators = require 'game.sprites.generator'
local extended = require 'game.sprites.extended'
local cluster = require 'game.sprites.cluster'
local minorextended = require 'game.sprites.minorextended'
local bounce = require 'game.sprites.bounce'
local quake = require 'game.sprites.quake'
local shooter = require 'game.sprites.shooter'
local score = require 'game.sprites.score'
local smoke = require 'game.sprites.smoke'
local coin = require 'game.sprites.coin'
local Sprites_info = require 'game.sprites.spriteinfo'
local spriteMiscTables = require 'game.sprites.miscsprite'
local special_sprite_property = require 'game.sprites.specialsprites'
local spritedata = require('game.sprites.spritedata')
local image = require 'game.image'
local blockdup = require 'game.blockdup'
local overworld = require 'game.overworld'
local collision = require('game.collision').new()
local state = require 'game.state'
_G.commands = require 'commands'
local Ghost_player  -- for late require/unrequire

local OPTIONS = config.OPTIONS
local COLOUR = config.COLOUR
local LSNES_FONT_HEIGHT = config.LSNES_FONT_HEIGHT
local LSNES_FONT_WIDTH = config.LSNES_FONT_WIDTH
local LEFT_ARROW = config.LEFT_ARROW
local RIGHT_ARROW = config.RIGHT_ARROW

config.filename = INI_CONFIG_FILENAME
config.raw_data = {['LSNES OPTIONS'] = OPTIONS}

local controller = lsnes.controller
local store = state.store
local DBITMAPS = image.dbitmaps
local PALETTES = image.palettes
local Palettes_adjusted = image.Palettes_adjusted

local fmt = string.format
local floor = math.floor

-- Compatibility of the memory read/write functions
local u8 = memory.readbyte
local w8 = memory.writebyte
local u16 = memory.readword
local s16 = memory.readsword
local u24 = memory.readhword

-- Hotkeys availability  -- TODO: error if key is invalid
print(string.format("Hotkey '%s' set to increase opacity.", OPTIONS.hotkey_increase_opacity))
print(string.format("Hotkey '%s' set to decrease opacity.", OPTIONS.hotkey_decrease_opacity))

--#############################################################################
-- GAME AND SNES SPECIFIC MACROS:

local SMW = smw.constant
local WRAM = smw.WRAM
local DEBUG_REGISTER_ADDRESSES = smw.DEBUG_REGISTER_ADDRESSES
local Y_INTERACTION_POINTS = smw.Y_INTERACTION_POINTS
local SPRITE_MEMORY_MAX = smw.SPRITE_MEMORY_MAX
local ABNORMAL_HITBOX_SPRITES = smw.ABNORMAL_HITBOX_SPRITES

--#############################################################################
-- SCRIPT UTILITIES:

-- Variables used in various functions
local Previous = {}
local Paint_context = gui.renderctx.new(256, 224) -- lsnes specific
local Midframe_context = gui.renderctx.new(256, 224) -- lsnes specific
local User_input = keyinput.key_state
local Is_lagged = nil
local Address_change_watcher = {}
local Registered_addresses = {}
local Readonly_on_timer

widget:new('player', 0, 32)
widget:new('yoshi', 0, 88)
widget:new('miscellaneous_sprite_table', 0, 180)
widget:new('sprite_load_status', 256, 224)
widget:new('RNG.predict', 224, 112)
widget:new('spriteMiscTables', 256, 126)

--#############################################################################
-- SMW FUNCTIONS:

local screen_coordinates = smw.screen_coordinates
local game_coordinates = smw.game_coordinates

local Yoshi_stored_sprites = {}
local function scan_smw()
  Display.is_player_near_borders =
    store.Player_x_screen <= 32 or store.Player_x_screen >= 0xd0 or store.Player_y_screen <= -100 or
    store.Player_y_screen >= 224

  -- TODO: test
  -- table of slots that are stored by some Yoshi
  -- 0 = by invisible Yoshi
  -- 1 = by Visible Yoshi
  -- nil = by none
  Yoshi_stored_sprites = {}
  local visible_yoshi = u8('WRAM', WRAM.yoshi_slot) - 1
  for slot = 0, SMW.sprite_max - 1 do
    -- if slot is a Yoshi:
    if u8('WRAM', WRAM.sprite_number + slot) == 0x35 and u8('WRAM', WRAM.sprite_status + slot) ~= 0 then
      local licked_slot = u8('WRAM', WRAM.sprite_misc_160e + slot)
      Yoshi_stored_sprites[licked_slot] = 0 + ((visible_yoshi == slot) and 1 or 0)
    end
  end
end

-- Creates lateral gaps
local function create_gaps()
  gui.left_gap(OPTIONS.left_gap) -- for input display
  gui.right_gap(OPTIONS.right_gap)
  gui.top_gap(OPTIONS.top_gap)
  gui.bottom_gap(OPTIONS.bottom_gap)
end

-- uses the mouse to select an object
local function select_object(mouse_x, mouse_y, camera_x, camera_y)
  -- Font
  draw.Font = false
  draw.Text_opacity = 1.0
  draw.Bg_opacity = 0.5

  local x_game,
    y_game = game_coordinates(mouse_x, mouse_y, camera_x, camera_y)
  local obj_id

  -- Checks if the mouse is over Mario
  local x_player = s16('WRAM', WRAM.x)
  local y_player = s16('WRAM', WRAM.y)
  if x_player + 0xe >= x_game and x_player + 0x2 <= x_game and y_player + 0x30 >= y_game and y_player + 0x8 <= y_game then
    obj_id = 'Mario'
  end

  if not obj_id and OPTIONS.display_sprite_info then
    for id = 0, SMW.sprite_max - 1 do
      local sprite_status = u8('WRAM', WRAM.sprite_status + id)
      -- TODO: see why the script gets here without exporting Sprites_info
      if sprite_status ~= 0 and Sprites_info[id].x then
        -- Import some values
        local x_sprite,
          y_sprite = Sprites_info[id].x, Sprites_info[id].y
        local xoff,
          yoff = Sprites_info[id].hitbox_xoff, Sprites_info[id].hitbox_yoff
        local width,
          height = Sprites_info[id].hitbox_width, Sprites_info[id].hitbox_height

        if
          x_sprite + xoff + width >= x_game and x_sprite + xoff <= x_game and y_sprite + yoff + height >= y_game and
            y_sprite + yoff <= y_game
         then
          obj_id = id
          break
        end
      end
    end
  end

  if not obj_id then
    return
  end

  draw.text(User_input.mouse_x, User_input.mouse_y - 8, obj_id, true, false, 0.5, 1.0)
  return obj_id, x_game, y_game
end

-- This function sees if the mouse if over some object, to change its hitbox mode
-- The order is: 1) player, 2) sprite.
local function right_click()
  -- do nothing if over movie editor
  if
    OPTIONS.display_controller_input and
      luap.inside_rectangle(
        User_input.mouse_x,
        User_input.mouse_y,
        lsnes.movie_editor_left,
        lsnes.movie_editor_top,
        lsnes.movie_editor_right,
        lsnes.movie_editor_bottom
      )
   then
    return
  end

  local id = select_object(User_input.mouse_x, User_input.mouse_y, store.Camera_x, store.Camera_y)

  if tostring(id) == 'Mario' then
    if OPTIONS.display_player_hitbox and OPTIONS.display_interaction_points then
      OPTIONS.display_interaction_points = false
      OPTIONS.display_player_hitbox = false
    elseif OPTIONS.display_player_hitbox then
      OPTIONS.display_interaction_points = true
      OPTIONS.display_player_hitbox = false
    elseif OPTIONS.display_interaction_points then
      OPTIONS.display_player_hitbox = true
    else
      OPTIONS.display_player_hitbox = true
    end

    config.save_options()
    return
  end

  local spr_id = tonumber(id)
  if spr_id and spr_id >= 0 and spr_id <= SMW.sprite_max - 1 then
    local t = Display.sprite_hitbox[spr_id].number
    if t.sprite and t.block then
      t.sprite = false
      t.block = false
    elseif t.sprite then
      t.block = true
      t.sprite = false
    elseif t.block then
      t.sprite = true
    else
      t.sprite = true
    end

    config.save_options()
    return
  end

  -- Select layer 2 tiles
  local layer2x = s16('WRAM', WRAM.layer2_x_nextframe)
  local layer2y = s16('WRAM', WRAM.layer2_y_nextframe)
  local x_mouse,
    y_mouse = floor(User_input.mouse_x / draw.AR_x) + layer2x, floor(User_input.mouse_y / draw.AR_y) + layer2y
  tile.select_tile(16 * floor(x_mouse / 16), 16 * floor(y_mouse / 16), tile.layer2)
end

local function show_movie_info()
  if not OPTIONS.display_movie_info then
    return
  end

  -- Font
  draw.Font = false
  draw.Text_opacity = 1.0
  draw.Bg_opacity = 1.0

  local y_text = -draw.Border_top
  local x_text = 0
  local width = draw.font_width()

  local rec_color = lsnes.Readonly and COLOUR.text or COLOUR.warning
  local recording_bg = lsnes.Readonly and COLOUR.background or COLOUR.warning_bg

  -- Read-only or read-write?
  local movie_type = lsnes.Readonly and 'Movie ' or 'REC '
  draw.alert_text(x_text, y_text, movie_type, rec_color, recording_bg)

  -- Frame count
  x_text = x_text + width * #(movie_type)
  local movie_info
  if lsnes.Readonly then
    movie_info = string.format('%d/%d', lsnes.Lastframe_emulated, lsnes.Framecount)
  else
    movie_info = string.format('%d', lsnes.Lastframe_emulated) -- delete string.format
  end
  draw.text(x_text, y_text, movie_info) -- Shows the latest frame emulated, not the frame being run now

  -- Rerecord count
  x_text = x_text + width * #(movie_info)
  local rr_info = string.format('|%d ', lsnes.Rerecords)
  draw.text(x_text, y_text, rr_info, COLOUR.weak)

  -- Lag count
  x_text = x_text + width * #(rr_info)
  draw.text(x_text, y_text, lsnes.Lagcount, COLOUR.warning)
  x_text = x_text + width * string.len(lsnes.Lagcount)

  -- lsnes run mode
  if lsnes.is_special_runmode then
    local runmode = ' ' .. lsnes.runmode
    draw.text(x_text, y_text, runmode, lsnes.runmode_color)
    x_text = x_text + width * (#runmode)
  end

  -- emulator speed
  if lsnes.Lsnes_speed == 'turbo' then
    draw.text(x_text, y_text, ' (' .. lsnes.Lsnes_speed .. ')', COLOUR.weak)
  elseif lsnes.Lsnes_speed ~= 1 then
    draw.text(x_text, y_text, fmt(' (%.0f%%)', 100 * lsnes.Lsnes_speed), COLOUR.weak)
  end

  local str = lsnes.frame_time(lsnes.Lastframe_emulated) -- Shows the latest frame emulated, not the frame being run now
  draw.alert_text(draw.Buffer_width, draw.Buffer_height, str, COLOUR.text, recording_bg, false, 1.0, 1.0)

  if Is_lagged then
    gui.textHV(
      draw.Buffer_middle_x - 3 * LSNES_FONT_WIDTH,
      2 * LSNES_FONT_HEIGHT,
      'Lag',
      COLOUR.warning,
      draw.change_transparency(COLOUR.warning_bg, draw.Background_max_opacity)
    )

    Timer.registerfunction(
      1000000,
      function()
        if not Is_lagged then
          gui.textHV(
            draw.Buffer_middle_x - 3 * LSNES_FONT_WIDTH,
            2 * LSNES_FONT_HEIGHT,
            'Lag',
            COLOUR.warning,
            draw.change_transparency(COLOUR.background, draw.Background_max_opacity)
          )
        end
      end,
      'Was lagged'
    )
  end
end

local function show_misc_info()
  if not OPTIONS.display_misc_info then
    return
  end

  -- Font
  draw.Font = false
  draw.Text_opacity = 1.0
  draw.Bg_opacity = 1.0

  -- Display
  local RNGValue = u16('WRAM', WRAM.RNG)
  local main_info =
    string.format(
    'Frame(%02x, %02x) RNG(%04x) Mode(%02x)',
    store.Real_frame,
    store.Effective_frame,
    RNGValue,
    store.Game_mode
  )
  draw.text(draw.Buffer_width + draw.Border_right, -draw.Border_top, main_info, true, false)

  if store.Game_mode == SMW.game_mode_level then
    -- Time frame counter of the clock
    draw.Font = 'snes9xlua'
    local timer_frame_counter = u8('WRAM', WRAM.timer_frame_counter)
    draw.text(draw.AR_x * 161, draw.AR_y * 15, fmt('%.2d', timer_frame_counter))

    -- Score: sum of digits, useful for avoiding lag
    draw.Font = 'Uzebox8x12'
    local scoreValue = u24('WRAM', WRAM.mario_score)
    draw.text(draw.AR_x * 240, draw.AR_y * 24, fmt('=%d', luap.sum_digits(scoreValue)), COLOUR.weak)
  end
end

local function level_info()
  if not OPTIONS.display_level_info then
    return
  end

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
  if store.Level_index > 0x24 then
    lm_level_number = store.Level_index + 0xdc
  end

  -- Number of screens within the level
  local level_type,
    screens_number,
    hscreen_current,
    hscreen_number,
    vscreen_current,
    vscreen_number = tile.read_screens()

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
end

-- Creates lines showing where the real pit of death is
-- One line is for sprites and another is for Mario or Mario/Yoshi (different spot)
local function draw_boundaries()
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
      str =
        string.format('%s/%s', no_powerup and 'No powerup' or 'Big', store.Yoshi_riding_flag and 'Yoshi' or 'No Yoshi')
      draw.text(xmin, draw.AR_y * ymax + draw.font_height(), str, COLOUR.warning, true, false, 1)
    end
  end

  -- Sprites
  if OPTIONS.display_sprite_vanish_area then
    local is_vertical = tile.read_screens() == 'Vertical'
    local ydeath = is_vertical and store.Camera_y + 320 or 432
    local _,
      y_screen = screen_coordinates(0, ydeath, store.Camera_x, store.Camera_y)

    if draw.AR_y * y_screen < draw.Buffer_height + draw.Border_bottom then
      draw.line(-draw.Border_left, y_screen, draw.Screen_width + draw.Border_right, y_screen, 2, COLOUR.weak)
      local str = string.format('Sprite %s: %d', is_vertical and '"death"' or 'death', ydeath)
      draw.text(-draw.Border_left, draw.AR_y * y_screen, str, COLOUR.weak, true)
    end
  end
end

local function player_info()
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
  local x_sub_simple,
    y_sub_simple  -- = x_sub, y_sub
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

  local x_speed_int,
    x_speed_frac = math.modf(store.x_speed + store.x_subspeed / 0x100)
  x_speed_frac = math.abs(x_speed_frac * 100)

  local spin_direction = (store.Effective_frame) % 8
  if spin_direction < 4 then
    spin_direction = spin_direction + 1
  else
    spin_direction = 3 - spin_direction
  end

  local is_caped = store.Player_powerup == 0x2
  local is_spinning = store.cape_spin ~= 0 or store.spinjump_flag ~= 0

  -- Display info
  widget:set_property('player', 'display_flag', OPTIONS.display_player_info)
  if OPTIONS.display_player_info then
    local i = 0
    local delta_x = draw.font_width()
    local delta_y = draw.font_height()
    local table_x = draw.AR_x * widget:get_property('player', 'x')
    local table_y = draw.AR_y * widget:get_property('player', 'y')

    draw.text(table_x, table_y + i * delta_y, fmt('Meter (%03d, %02d) %s', store.p_meter, store.take_off, direction))
    draw.text(
      table_x + 18 * delta_x,
      table_y + i * delta_y,
      fmt(' %+d', spin_direction),
      (is_spinning and COLOUR.text) or COLOUR.weak
    )

    if store.pose_turning ~= 0 then
      gui.text(
        draw.AR_x * (store.Player_x_screen + 6),
        draw.AR_y * (store.Player_y_screen - 4),
        store.pose_turning,
        COLOUR.warning2,
        0x40000000
      )
    end
    i = i + 1

    draw.text(
      table_x,
      table_y + i * delta_y,
      fmt('Pos (%+d.%s, %+d.%s)', store.Player_x, x_sub_simple, store.Player_y, y_sub_simple)
    )
    i = i + 1

    draw.text(
      table_x,
      table_y + i * delta_y,
      fmt('Speed (%+d(%d.%02.0f), %+d)', store.x_speed, x_speed_int, x_speed_frac, store.y_speed)
    )
    i = i + 1

    if is_caped then
      local cape_gliding_index = u8('WRAM', WRAM.cape_gliding_index)
      local diving_status_timer = u8('WRAM', WRAM.diving_status_timer)
      local action = smw.FLIGHT_ACTIONS[cape_gliding_index] or 'bug!'

      -- TODO: better name for this "glitched" state
      if cape_gliding_index == 3 and store.y_speed > 0 then
        action = '*up*'
      end

      draw.text(
        table_x,
        table_y + i * delta_y,
        fmt('Cape (%.2d, %.2d)/(%d, %d)', store.cape_spin, store.cape_fall, store.flight_animation, store.diving_status),
        COLOUR.cape
      )
      i = i + 1
      if store.flight_animation ~= 0 then
        draw.text(table_x + 10 * draw.font_width(), table_y + i * delta_y, action .. ' ', COLOUR.cape)
        draw.text(
          table_x + 15 * draw.font_width(),
          table_y + i * delta_y,
          diving_status_timer,
          diving_status_timer <= 1 and COLOUR.warning or COLOUR.cape
        )
        i = i + 1
      end
    end

    local x_txt = draw.text(table_x, table_y + i * delta_y, fmt('Camera (%d, %d)', store.Camera_x, store.Camera_y))
    if store.scroll_timer ~= 0 then
      x_txt = draw.text(x_txt, table_y + i * delta_y, 16 - store.scroll_timer, COLOUR.warning)
    end
    draw.font['Uzebox6x8'](
      table_x + 8 * delta_x,
      table_y + (i + 1) * delta_y,
      string.format('%d.%x', math.floor(store.Camera_x / 16), store.Camera_x % 16),
      0xffffff,
      -1,
      0
    ) -- TODO remove
    if store.vertical_scroll_flag_header ~= 0 and store.vertical_scroll_enabled ~= 0 then
      draw.text(x_txt, table_y + i * delta_y, store.vertical_scroll_enabled, COLOUR.warning2)
    end
    i = i + 1

    player.draw_blocked_status(
      table_x,
      table_y + i * delta_y,
      store.player_blocked_status,
      store.x_speed,
      store.y_speed
    )
    i = i + 1

    -- Wings timers is the same as the cape
    if (not is_caped and store.cape_fall ~= 0) then
      draw.text(table_x, table_y + i * delta_y, fmt('Wings: %.2d', store.cape_fall), COLOUR.text)
    end
  end

  if OPTIONS.display_static_camera_region then
    Display.show_player_point_position = true

    -- Horizontal scroll
    local left_cam,
      right_cam = u16('WRAM', WRAM.camera_left_limit), u16('WRAM', WRAM.camera_right_limit)
    local center_cam = math.floor((left_cam + right_cam) / 2)
    draw.box(left_cam, 0, right_cam, 224, COLOUR.static_camera_region, COLOUR.static_camera_region)
    draw.line(center_cam, 0, center_cam, 224, 2, 'black')
    draw.text(draw.AR_x * left_cam, 0, left_cam, COLOUR.text, 0x400020, false, false, 1, 0)
    draw.text(draw.AR_x * right_cam, 0, right_cam, COLOUR.text, 0x400020)

    -- Vertical scroll
    if store.vertical_scroll_flag_header ~= 0 then
      draw.box(0, 100, 255, 124, COLOUR.static_camera_region, COLOUR.static_camera_region) -- FIXME for PAL
    end
  end

  -- Mario boost indicator
  Previous.x = store.Player_x
  Previous.y = store.Player_y
  Previous.next_x = next_x
  if OPTIONS.register_player_position_changes and Registered_addresses.mario_position ~= '' then
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
    Midframe_context:run()
  end

  -- shows hitbox and interaction points for player
  if OPTIONS.display_cape_hitbox then
    player.cape_hitbox(spin_direction)
  end
  if OPTIONS.display_player_hitbox or OPTIONS.display_interaction_points then
    player.player_hitbox(store.Player_x, store.Player_y, store.is_ducking, store.Player_powerup, 1)
  end

  -- Shows where Mario is expected to be in the next frame, if he's not boosted or stopped
  if OPTIONS.display_debug_player_extra then
    player.player_hitbox(next_x, next_y, store.is_ducking, store.Player_powerup, 0.3)
  end
end

-- draw normal sprite vs Mario hitbox
local function draw_sprite_hitbox(slot)
  if not OPTIONS.display_sprite_hitbox then
    return
  end

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
  local display_hitbox = Display.sprite_hitbox[slot][number].sprite and not ABNORMAL_HITBOX_SPRITES[number]
  local display_clipping = Display.sprite_hitbox[slot][number].block
  local alive_status = (t.status == 0x03 or t.status >= 0x08)
  local info_color = alive_status and t.info_color or COLOUR.very_weak
  local background_color = alive_status and t.background_color or -1

  -- That's the pixel that appears when the sprite vanishes in the pit
  if y_screen >= 224 or OPTIONS.display_debug_sprite_extra then
    draw.pixel(x_screen, y_screen, info_color, COLOUR.very_weak)
  end

  if display_clipping then -- sprite clipping background
    draw.box(
      x_screen + xpt_left,
      y_screen + ypt_down,
      x_screen + xpt_right,
      y_screen + ypt_up,
      2,
      COLOUR.sprites_clipping_bg,
      display_hitbox and -1 or COLOUR.sprites_clipping_bg
    )
  end

  if display_hitbox then -- show sprite/sprite clipping
    draw.rectangle(x_screen + xoff, y_screen + yoff, width, height, info_color, background_color)
  end

  if display_clipping then -- show sprite/object clipping
    local size,
      color = 1, COLOUR.sprites_interaction_pts
    draw.line(x_screen + xpt_right, y_screen + ypt_right, x_screen + xpt_right - size, y_screen + ypt_right, 2, color) -- right
    draw.line(x_screen + xpt_left, y_screen + ypt_left, x_screen + xpt_left + size, y_screen + ypt_left, 2, color) -- left
    draw.line(x_screen + xpt_down, y_screen + ypt_down, x_screen + xpt_down, y_screen + ypt_down - size, 2, color) -- down
    draw.line(x_screen + xpt_up, y_screen + ypt_up, x_screen + xpt_up, y_screen + ypt_up + size, 2, color) -- up
  end

  -- Sprite vs sprite hitbox
  if OPTIONS.display_sprite_vs_sprite_hitbox then
    if
      u8('WRAM', WRAM.sprite_sprite_contact + slot) == 0 and u8('WRAM', WRAM.sprite_being_eaten_flag + slot) == 0 and
        bit.testn(u8('WRAM', WRAM.sprite_5_tweaker + slot), 3)
     then
      local boxid2 = bit.band(u8('WRAM', WRAM.sprite_2_tweaker + slot), 0x0f)
      local yoff2 = boxid2 == 0 and 2 or 0xa -- ROM data
      local bg_color = t.status >= 8 and 0x80ffffff or 0x80ff0000
      if store.Real_frame % 2 == 0 then
        bg_color = -1
      end

      -- if y1 - y2 + 0xc < 0x18
      draw.rectangle(x_screen, y_screen + yoff2, 0x10, 0x0c, 0xffffff)
      draw.rectangle(x_screen, y_screen + yoff2, 0x10 - 1, 0x0c - 1, info_color, bg_color)
    end
  end
end

local function sprite_info(id, counter, table_position)
  local t = Sprites_info[id]
  local sprite_status = t.status
  if sprite_status == 0 then
    return 0
  end -- returns if the slot is empty

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
  if fn then
    fn(id, Display)
  end

  -- Print those informations next to the sprite
  draw.Font = 'Uzebox6x8'
  draw.Text_opacity = 1.0
  draw.Bg_opacity = 1.0

  if x_offscreen ~= 0 or y_offscreen ~= 0 then
    draw.Text_opacity = 0.6
  end

  local contact_str = contact_mario == 0 and '' or ' ' .. contact_mario

  local sprite_middle = t.sprite_middle
  local sprite_top = t.sprite_top
  if OPTIONS.display_sprite_info then
    local xdraw,
      ydraw = draw.AR_x * sprite_middle, draw.AR_y * sprite_top

    local behind_str = behind_scenery == 0 and '' or 'BG '
    draw.text(xdraw, ydraw, fmt('%s#%.2d%s', behind_str, id, contact_str), info_color, true, false, 0.5, 1.0)

    if being_eaten_flag then
      DBITMAPS.yoshi_tongue:draw(xdraw, ydraw - 14)
    end

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
    local sprite_str =
      fmt(
      '#%02d %02x %s%d.%1x(%+.2d%s) %d.%1x(%+.2d)',
      id,
      number,
      t.table_special_info,
      x,
      floor(x_sub / 16),
      x_speed,
      x_speed_water,
      y,
      floor(y_sub / 16),
      y_speed
    )

    -- Signal stun glitch
    if sprite_status == 9 and stun ~= 0 and not smw.NORMAL_STUNNABLE[number] then
      sprite_str = 'Stun Glitch! ' .. sprite_str
    end

    local w = DBITMAPS.yoshi_tongue:size()
    local xdraw,
      ydraw =
      draw.Buffer_width + draw.Border_right - #sprite_str * draw.font_width() - w,
      table_position + counter * draw.font_height()
    if Yoshi_stored_sprites[id] == 0 then
      DBITMAPS.yoshi_full_mouth_trans:draw(xdraw, ydraw)
    elseif Yoshi_stored_sprites[id] == 1 then
      DBITMAPS.yoshi_full_mouth:draw(xdraw, ydraw)
    end

    draw.text(
      draw.Buffer_width + draw.Border_right,
      table_position + counter * draw.font_height(),
      sprite_str,
      info_color,
      true
    )
  end

  return 1
end

local function sprites()
  local counter = 0
  local table_position = draw.AR_y * 40 -- lsnes
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
    draw.text(
      draw.Buffer_width + draw.Border_right,
      table_position - 2 * draw.font_height(),
      fmt('spr:%.2d ', counter),
      COLOUR.weak,
      true
    )
    draw.text(
      draw.Buffer_width + draw.Border_right,
      table_position - draw.font_height(),
      fmt('1st div: %d. Swap: %d ', SPRITE_MEMORY_MAX[smh] or 0, swap_slot),
      COLOUR.weak,
      true
    )
  end

  -- Miscellaneous sprite table: index
  if OPTIONS.display_miscellaneous_sprite_table then
    draw.Font = false
    local w = draw.font_width()
    local tab = 'spriteMiscTables'
    local x,
      y = draw.AR_x * widget:get_property(tab, 'x'), draw.AR_y * widget:get_property(tab, 'y')
    widget:set_property(tab, 'display_flag', true)
    draw.font[draw.Font](x, y, 'Sprite Tables:\n ', COLOUR.text, 0x202020)
    y = y + 16
    for i = 0, SMW.sprite_max - 1 do
      if not spriteMiscTables.slot[i] then
        draw.button(
          x,
          y,
          string.format('%X', i),
          function()
            spriteMiscTables:new(i)
          end,
          {button_pressed = false}
        )
      else
        draw.button(
          x,
          y,
          string.format('%X', i),
          function()
            spriteMiscTables:destroy(i)
          end,
          {button_pressed = true}
        )
      end
      x = x + w + 1
    end
  end

  spriteMiscTables:main()
end

local function yoshi()
  if not OPTIONS.display_yoshi_info then
    return
  end

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
    draw.text(x_text, y_text, string.format('Yoshi slot diff: %s vs RAM %d', yoshi_id, visible_yoshi), COLOUR.warning)
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

    if eat_id == SMW.null_sprite_id and tongue_len == 0 and tongue_timer == 0 and tongue_wait == 0 then
      draw.Font = 'snes9xluasmall'
    end
    draw.text(
      x_text,
      y_text + h,
      fmt('(%0s, %0s) %02d, %d, %d', eat_id_str, eat_type_str, tongue_len, tongue_wait, tongue_timer),
      COLOUR.yoshi
    )
    -- more WRAM values
    local yoshi_x = memory.sread_sg('WRAM', WRAM.sprite_x_low + yoshi_id, WRAM.sprite_x_high + yoshi_id)
    local yoshi_y = memory.sread_sg('WRAM', WRAM.sprite_y_low + yoshi_id, WRAM.sprite_y_high + yoshi_id)
    local x_screen,
      y_screen = screen_coordinates(yoshi_x, yoshi_y, store.Camera_x, store.Camera_y)

    -- invisibility timer
    draw.Font = 'Uzebox6x8'
    if mount_invisibility ~= 0 then
      draw.text(draw.AR_x * (x_screen + 4), draw.AR_x * (y_screen - 12), mount_invisibility, COLOUR.yoshi)
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
      if yoshi_direction == 0 then
        actual_index = tile_index + 8
      end
      actual_index = yoshi_in_pipe ~= 0 and u8('WRAM', 0x0d) or smw.YOSHI_TONGUE_X_OFFSETS[actual_index] or 0

      local xoff = special_sprite_property.yoshi_tongue_offset(actual_index, tongue_len)

      -- tile_index changes midframe, according to yoshi_in_pipe address
      local yoff = yoshi_in_pipe ~= 0 and 3 or smw.YOSHI_TONGUE_Y_OFFSETS[tile_index] or 0
      yoff = yoff + 2
      draw.rectangle(x_screen + xoff, y_screen + yoff, 8, 4, tongue_line, COLOUR.tongue_bg)
      draw.pixel(x_screen + xoff, y_screen + yoff, COLOUR.text, COLOUR.tongue_bg) -- hitbox point vs berry tile

      -- glitched hitbox for Layer Switch Glitch
      if yoshi_in_pipe ~= 0 then
        local xoffGlitch = special_sprite_property.yoshi_tongue_offset(0x40, tongue_len) -- from ROM
        draw.rectangle(x_screen + xoffGlitch, y_screen + yoff, 8, 4, 0x80ffffff, 0xc0000000)

        draw.Font = 'Uzebox8x12'
        draw.text(
          x_text,
          y_text + 2 * h,
          fmt('$1a: %.4x $1c: %.4x', u16('WRAM', WRAM.layer1_x_mirror), u16('WRAM', WRAM.layer1_y_mirror)),
          COLOUR.yoshi
        )
        draw.text(
          x_text,
          y_text + 3 * h,
          fmt('$4d: %.4x $4f: %.4x', u16('WRAM', WRAM.layer1_VRAM_left_up), u16('WRAM', WRAM.layer1_VRAM_right_down)),
          COLOUR.yoshi
        )
      end

      -- tongue out: time predictor
      local info,
        color =
        special_sprite_property.yoshi_tongue_time_predictor(tongue_len, tongue_timer, tongue_wait, tongue_out, eat_id)
      draw.Font = 'Uzebox6x8'
      draw.text(draw.AR_x * (x_screen + xoff + 4), draw.AR_y * (y_screen + yoff + 5), info, color, false, false, 0.5)
    end
  elseif memory.readbyte('WRAM', WRAM.yoshi_overworld_flag) ~= 0 then -- if there's no Yoshi
    draw.Font = 'Uzebox6x8'
    draw.text(x_text, y_text, 'Yoshi on overworld', COLOUR.yoshi)
  end
end

-- Main function to run inside a level
local function level_mode()
  if SMW.game_mode_fade_to_level <= store.Game_mode and store.Game_mode <= SMW.game_mode_level then
    -- Draws/Erases the tiles if user clicked
    --map16.display_known_tiles()
    tile.draw_layer1(store.Camera_x, store.Camera_y)

    tile.draw_layer2()

    draw_boundaries()

    sprites()

    extended.sprite_table()

    cluster.sprite_table()

    minorextended.sprite_table()

    bounce.sprite_table()

    quake.sprite_table()

    shooter.sprite_table()

    score.sprite_table()

    smoke.sprite_table()

    coin.sprite_table()

    level_info()

    spritedata.display_room_data()

    spritedata.display_spawn_region()

    player_info()

    yoshi()

    countdown.show_counters()

    generators:info()

    blockdup.predict_block_duplications()

    -- Draws/Erases the hitbox for objects
    if User_input.mouse_inwindow == 1 then
      select_object(User_input.mouse_x, User_input.mouse_y, store.Camera_x, store.Camera_y)
    end
  end
end

local function left_click()
  -- Buttons
  for _, field in ipairs(draw.button_list) do
    -- if mouse is over the button
    if keyinput:mouse_onregion(field.x, field.y, field.x + field.width, field.y + field.height) then
      field.action()
      config.save_options()
      return
    end
  end

  -- Movie Editor
  if lsnes.movie_editor() then
    return
  end

  -- Sprites' tweaker editor
  if cheat.allow_cheats and cheat.sprite_tweaker_selected_id then
    local id = cheat.sprite_tweaker_selected_id
    local tweaker_num = cheat.sprite_tweaker_selected_y + 1
    local tweaker_bit = 7 - cheat.sprite_tweaker_selected_x

    -- Sanity check
    if id < 0 or id >= SMW.sprite_max then
      return
    end
    if tweaker_num < 1 or tweaker_num > 6 or tweaker_bit < 0 or tweaker_bit > 7 then
      return
    end

    -- Get address and edit value
    local tweaker_table = {
      WRAM.sprite_1_tweaker,
      WRAM.sprite_2_tweaker,
      WRAM.sprite_3_tweaker,
      WRAM.sprite_4_tweaker,
      WRAM.sprite_5_tweaker,
      WRAM.sprite_6_tweaker
    }
    local address = tweaker_table[tweaker_num] + id
    local value = u8('WRAM', address)
    local status = bit.test(value, tweaker_bit)

    w8('WRAM', address, value + (status and -1 or 1) * bit.lshift(1, tweaker_bit)) -- edit only given bit
    print(fmt('Edited bit %d of sprite (#%d) tweaker %d (address WRAM+%x).', tweaker_bit, id, tweaker_num, address))
    cheat.sprite_tweaker_selected_id = nil -- don't edit two addresses per click
    return
  end

  -- Drag and drop sprites
  if cheat.allow_cheats then
    local id = select_object(User_input.mouse_x, User_input.mouse_y, store.Camera_x, store.Camera_y)
    if type(id) == 'number' and id >= 0 and id < SMW.sprite_max then
      cheat.dragging_sprite_id = id
      cheat.is_dragging_sprite = true
      return
    end
  end

  -- Layer 1 tiles
  if not Options_menu.show_menu then
    if
      not (OPTIONS.display_controller_input and
        luap.inside_rectangle(
          User_input.mouse_x,
          User_input.mouse_y,
          lsnes.movie_editor_left,
          lsnes.movie_editor_top,
          lsnes.movie_editor_right,
          lsnes.movie_editor_bottom
        ))
     then
      -- don't select over movie editor
      local x_mouse,
        y_mouse = game_coordinates(User_input.mouse_x, User_input.mouse_y, store.Camera_x, store.Camera_y)
      x_mouse = 16 * floor(x_mouse / 16)
      y_mouse = 16 * floor(y_mouse / 16)
      tile.select_tile(x_mouse, y_mouse, tile.layer1)
    end
  end
end

-- This function runs at the end of paint callback
-- Specific for info that changes if the emulator is paused and idle callback is called
local function lsnes_yield()
  -- Widget buttons
  -- moves blocks of info when button is held
  widget:display_all()
  widget:drag_widget()

  -- Font
  draw.Font = false

  if not Options_menu.show_menu and User_input.mouse_inwindow == 1 then
    draw.button(
      -draw.Border_left,
      -draw.Border_top,
      'Menu',
      function()
        Options_menu.show_menu = true
      end,
      {always_on_client = true}
    )

    draw.button(
      0,
      0,
      '↓',
      function()
        OPTIONS.display_controller_input = not OPTIONS.display_controller_input
      end,
      {always_on_client = true, ref_x = 1.0, ref_y = 1.0}
    )
    draw.button(
      -draw.Border_left,
      draw.Buffer_height + draw.Border_bottom,
      cheat.allow_cheats and 'Cheats: allowed' or 'Cheats: blocked',
      function()
        cheat.allow_cheats = not cheat.allow_cheats
        draw.message('Cheats ' .. (cheat.allow_cheats and 'allowed.' or 'blocked.'))
      end,
      {always_on_client = true, ref_y = 1.0}
    )

    draw.button(
      draw.Buffer_width + draw.Border_right,
      draw.Buffer_height + draw.Border_bottom,
      'Erase Tiles',
      function()
        tile.layer1 = {}
        tile.layer2 = {}
      end,
      {always_on_client = true, ref_y = 1.0}
    )
    -- Quick save movie/state buttons
    draw.Font = 'Uzebox6x8'
    draw.text(0, draw.Buffer_height - 2 * draw.font_height(), 'Save?', COLOUR.text, COLOUR.background)

    draw.button(
      0,
      draw.Buffer_height,
      'Movie',
      function()
        local hint = movie.get_rom_info()[1].hint
        local current_time = string.gsub(luap.luap.system_time(), ':', '.')
        local filename = string.format('%s-%s(MOVIE).lsmv', current_time, hint)
        if not luap.file_exists(filename) then
          exec('save-movie ' .. filename)
          draw.message('Pending save-movie: ' .. filename, 3000000)
          return
        else
          print('Movie ' .. filename .. ' already exists.', 3000000)
          draw.message('Movie ' .. filename .. ' already exists.')
          return
        end
      end,
      {always_on_game = true}
    )
    draw.button(
      5 * draw.font_width() + 1,
      draw.Buffer_height + LSNES_FONT_HEIGHT,
      'State',
      function()
        local hint = movie.get_rom_info()[1].hint
        local current_time = string.gsub(luap.luap.system_time(), ':', '.')
        local filename = string.format('%s-%s(STATE).lsmv', current_time, hint)
        if not luap.file_exists(filename) then
          exec('save-state ' .. filename)
          draw.message('Pending save-state: ' .. filename, 3000000)
          return
        else
          print('State ' .. filename .. ' already exists.')
          draw.message('State ' .. filename .. ' already exists.', 3000000)
          return
        end
      end,
      {always_on_game = true}
    )
    -- Free movement cheat
    -- display button to toggle the free movement state
    if cheat.allow_cheats then
      draw.Font = 'Uzebox8x12'
      local x,
        y,
        dx,
        dy = 0, 0, draw.font_width(), draw.font_height()
      draw.font[draw.Font](x, y, 'Free movement cheat ', COLOUR.warning, COLOUR.weak, 0)
      draw.button(
        x + 20 * dx,
        y,
        cheat.free_movement.is_applying or ' ',
        function()
          cheat.free_movement.is_applying = not cheat.free_movement.is_applying
        end
      )

      -- display free movement options if it's active
      if cheat.free_movement.is_applying then
        y = y + dy
        draw.font[draw.Font](x, y, 'Type:', COLOUR.button_text, COLOUR.weak)
        draw.button(
          x + 5 * dx,
          y,
          cheat.free_movement.manipulate_speed and 'Speed' or ' Pos ',
          function()
            cheat.free_movement.manipulate_speed = not cheat.free_movement.manipulate_speed
          end
        )
        y = y + dy
        draw.font[draw.Font](x, y, 'invincibility:', COLOUR.button_text, COLOUR.weak)
        draw.button(
          x + 14 * dx,
          y,
          cheat.free_movement.give_invincibility or ' ',
          function()
            cheat.free_movement.give_invincibility = not cheat.free_movement.give_invincibility
          end
        )
        y = y + dy
        draw.font[draw.Font](x, y, 'Freeze animation:', COLOUR.button_text, COLOUR.weak)
        draw.button(
          x + 17 * dx,
          y,
          cheat.free_movement.freeze_animation or ' ',
          function()
            cheat.free_movement.freeze_animation = not cheat.free_movement.freeze_animation
          end
        )
        y = y + dy
        draw.font[draw.Font](x, y, 'Unlock camera:', COLOUR.button_text, COLOUR.weak)
        draw.button(
          x + 14 * dx,
          y,
          cheat.free_movement.unlock_vertical_camera or ' ',
          function()
            cheat.free_movement.unlock_vertical_camera = not cheat.free_movement.unlock_vertical_camera
          end
        )
      end
    end

    Options_menu.adjust_lateral_gaps()
  else
    if cheat.allow_cheats then -- show cheat status anyway
      draw.Font = 'Uzebox6x8'
      draw.text(
        -draw.Border_left,
        draw.Buffer_height + draw.Border_bottom,
        'Cheats: allowed',
        COLOUR.warning,
        true,
        false,
        0.0,
        1.0
      )
    end
  end

  -- Drag and drop sprites with the mouse
  if cheat.is_dragging_sprite then
    -- TODO: avoid many parameters in function
    cheat.drag_sprite(cheat.dragging_sprite_id, store.Game_mode, Sprites_info, store.Camera_x, store.Camera_y)
    cheat.is_cheating = true
  end

  Options_menu.display()
end

--#############################################################################
-- MAIN --

function _G.on_input --[[ subframe ]]()
  if not movie.rom_loaded() or not controller.info_loaded then
    return
  end

  joypad:getKeys()

  if cheat.allow_cheats then
    cheat.is_cheating = false

    cheat.beat_level(store.Is_paused, store.Level_index, store.Level_flag)
    cheat.free_movement.apply(Previous)
  else
    -- Cancel any continuous cheat
    cheat.free_movement.is_applying = false

    cheat.is_cheating = false
  end
end

function _G.on_frame_emulated()
  if OPTIONS.use_custom_lag_detector then
    Is_lagged = (not lsnes.Controller_latch_happened) or (u8('WRAM', 0x10) == 0)
  else
    Is_lagged = memory.get_lag_flag()
  end
  if OPTIONS.use_custom_lagcount then
    memory.set_lag_flag(Is_lagged)
  end

  -- Resets special WRAM addresses for changes
  for _, inner in pairs(Address_change_watcher) do
    inner.watching_changes = false
  end

  if OPTIONS.register_player_position_changes == 'simple' and OPTIONS.display_player_info and Previous.next_x then
    local change = s16('WRAM', WRAM.x) - Previous.next_x
    Registered_addresses.mario_position = change == 0 and '' or (change > 0 and (change .. '→') or (-change .. '←'))
  end
end

function _G.on_snoop2(p, c --[[ , b, v ]])
  -- Clear stuff after emulation of frame has started
  if p == 0 and c == 0 then
    Registered_addresses.mario_position = ''
    Midframe_context:clear()

    collision:reset()
  end
end

function _G.on_frame()
  if not movie.rom_loaded() then -- only useful with null ROM
    gui.repaint()
  end
end

function _G.on_paint(received_frame)
  -- Initial values, don't make drawings here
  keyinput.get_mouse()
  lsnes.get_status()
  draw.lsnes_screen_info()
  lsnes.get_movie_info()
  create_gaps()
  state:refresh()

  -- If the paint request occurs just after a load state, don't render new elements
  if lsnes.preloading_state then
    Paint_context:run()
    return
  end

  Paint_context:clear()
  Paint_context:set()

  -- gets back to default paint context / video callback doesn't capture anything
  if not controller.info_loaded then
    return
  end

  -- Dark filter to cover the game area
  if OPTIONS.filter_opacity ~= 0 then
    gui.solidrectangle(0, 0, draw.Buffer_width, draw.Buffer_height, COLOUR.filter_color)
  end

  -- Drawings are allowed now
  if Ghost_player then
    Ghost_player.renderctx:run()
  end
  scan_smw()
  level_mode()
  overworld.info()
  show_movie_info()
  show_misc_info()
  RNG.display_RNG()
  gamecontroller.display()

  if OPTIONS.display_controller_input then
    lsnes.frame,
      lsnes.port,
      lsnes.controller,
      lsnes.button = lsnes.display_input() -- test: fix names
  end

  -- ACE debug info
  if OPTIONS.register_ACE_debug_callback then
    draw.Font = 'Uzebox6x8'
    local y,
      height = LSNES_FONT_HEIGHT, draw.font_height()
    local count = 0

    for index in pairs(DEBUG_REGISTER_ADDRESSES.active) do
      draw.text(draw.Buffer_width, y, DEBUG_REGISTER_ADDRESSES[index][3], false, true)
      y = y + height
      count = count + 1
    end

    if count > 0 then
      draw.Font = false
      draw.text(draw.Buffer_width, 0, 'ACE helper:', COLOUR.warning, COLOUR.warning_bg, false, true)
    end
  end

  -- Lagmeter
  if OPTIONS.use_lagmeter_tool and Lagmeter.Mcycles then
    local meter,
      color = Lagmeter.Mcycles / 3573.68
    if meter < 70 then
      color = 0x00ff00
    elseif meter < 90 then
      color = 0xffff00
    elseif meter <= 100 then
      color = 0xff0000
    else
      color = 0xff00ff
    end

    draw.Font = 'Uzebox8x12'
    draw.text(364, 16, fmt('Lagmeter: %.3f', meter), color, false, false, 0.5)
  end

  collision:display()

  cheat.is_cheat_active()

  -- Comparison ghost
  --[[ if OPTIONS.show_comparison_ghost and Ghost_player then
    Ghost_player.comparison(received_frame)
  end ]]
  -- gets back to default paint context / video callback doesn't capture anything
  gui.renderctx.setnull()
  Paint_context:run()

  -- display warning if recording OSD
  if Previous.video_callback then
    draw.text(
      0,
      draw.Buffer_height,
      OPTIONS.make_lua_drawings_on_video and 'Capturing OSD' or 'NOT capturing OSD',
      COLOUR.warning,
      true,
      true
    )
    if received_frame then
      Previous.video_callback = false
    end
  end

  -- on_timer registered functions
  Timer.on_paint()

  lsnes_yield()
end

function _G.on_video()
  if OPTIONS.make_lua_drawings_on_video then
    -- Scale the video to the same dimensions of the emulator
    gui.set_video_scale(2, 2)

    -- Renders the same context of on_paint over video
    Paint_context:run()
    if Ghost_player then
      Ghost_player.renderctx:run()
    end
    create_gaps()
  end

  Previous.video_callback = true
end

-- Loading a state
function _G.on_pre_load()
  -- Resets special WRAM addresses for changes
  for _, inner in pairs(Address_change_watcher) do
    inner.watching_changes = false
    inner.info = ''
  end
  Registered_addresses.mario_position = ''
  Midframe_context:clear()
end

function _G.on_post_load --[[ name, was_savestate ]]()
  Is_lagged = false
  Lagmeter.Mcycles = false

  -- ACE debug info
  if OPTIONS.register_ACE_debug_callback then
    for index in pairs(DEBUG_REGISTER_ADDRESSES.active) do
      DEBUG_REGISTER_ADDRESSES.active[index] = nil
    end
  end

  collision:reset()
  collectgarbage()
  gui.repaint()
end

function _G.on_err_save(name)
  draw.message('Failed saving state ' .. name)
end

-- Functions called on specific events
function _G.on_readwrite()
  draw.message('Read-Write mode')
  gui.repaint()
end

function _G.on_rewind()
  draw.message('Movie rewound to beginning')
  Is_lagged = false
  Lagmeter.Mcycles = false
  lsnes.Lastframe_emulated = nil

  gui.repaint()
end

-- Repeating callbacks
function _G.on_timer()
  Previous.readonly_on_timer = Readonly_on_timer -- artificial callback on_readonly
  Readonly_on_timer = movie.readonly()
  if (Readonly_on_timer and not Previous.readonly_on_timer) then
    draw.message('Read-Only mode')
  end

  set_timer_timeout(OPTIONS.timer_period) -- calls on_timer forever
end

function _G.on_idle()
  if User_input.mouse_inwindow == 1 then
    gui.repaint()
  end

  set_idle_timeout(OPTIONS.idle_period) -- calls on_idle forever, while idle
end

function lsnes.on_new_ROM()
  print 'new_ROM'
  if not movie.rom_loaded() then
    return
  end

  lsnes.get_controller_info()
  smwdebug.register_debug_callback(false)

  -- Register special WRAM addresses for changes
  Registered_addresses.mario_position = ''
  Address_change_watcher[WRAM.x] = {
    watching_changes = false,
    register = function(_, value)
      local tabl = Address_change_watcher[WRAM.x]
      if tabl.watching_changes then
        local new = luap.signed16(256 * u8('WRAM', WRAM.x + 1) + value)
        local change = new - s16('WRAM', WRAM.x)
        if OPTIONS.register_player_position_changes == 'complete' and change ~= 0 then
          Registered_addresses.mario_position =
            Registered_addresses.mario_position .. (change > 0 and (change .. '→') or (-change .. '←')) .. ' '

          -- Debug: display players' hitbox when position changes
          Midframe_context:set()
          player.player_hitbox(
            new,
            s16('WRAM', WRAM.y),
            u8('WRAM', WRAM.is_ducking),
            u8('WRAM', WRAM.powerup),
            1,
            DBITMAPS.interaction_points_palette_alt
          )
        end
      end

      tabl.watching_changes = true
    end
  }
  Address_change_watcher[WRAM.y] = {
    watching_changes = false,
    register = function(_, value)
      local tabl = Address_change_watcher[WRAM.y]
      if tabl.watching_changes then
        local new = luap.signed16(256 * u8('WRAM', WRAM.y + 1) + value)
        local change = new - s16('WRAM', WRAM.y)
        if OPTIONS.register_player_position_changes == 'complete' and change ~= 0 then
          Registered_addresses.mario_position =
            Registered_addresses.mario_position .. (change > 0 and (change .. '↓') or (-change .. '↑')) .. ' '

          -- Debug: display players' hitbox when position changes
          if math.abs(new - Previous.y) > 1 then -- ignores the natural -1 for y, while on top of a block
            Midframe_context:set()
            player.player_hitbox(
              s16('WRAM', WRAM.x),
              new,
              u8('WRAM', WRAM.is_ducking),
              u8('WRAM', WRAM.powerup),
              1,
              DBITMAPS.interaction_points_palette_alt
            )
          end
        end
      end

      tabl.watching_changes = true
    end
  }
  for address, inner in pairs(Address_change_watcher) do
    memory.registerwrite('WRAM', address, inner.register)
  end

  collision:init()

  -- Lagmeter
  if OPTIONS.use_lagmeter_tool then
    memory.registerexec('BUS', 0x8075, Lagmeter.get_master_cycles) -- unlisted ROM
  end
end

--#############################################################################
-- ON START --

lsnes.init()

-- Lateral gaps
OPTIONS.left_gap = floor(OPTIONS.left_gap)
OPTIONS.right_gap = floor(OPTIONS.right_gap)
OPTIONS.top_gap = floor(OPTIONS.top_gap)
OPTIONS.bottom_gap = floor(OPTIONS.bottom_gap)

-- Initilize comparison ghost
if OPTIONS.is_simple_comparison_ghost_loaded then
  Ghost_player = require 'ghost'
  Ghost_player.init()
end

-- KEYHOOK callback
_G.on_keyhook = keyinput.altkeyhook

-- Key presses:
keyinput.register_key_press('mouse_inwindow', gui.repaint)
keyinput.register_key_press(
  OPTIONS.hotkey_increase_opacity,
  function()
    draw.increase_opacity()
    gui.repaint()
  end
)
keyinput.register_key_press(
  OPTIONS.hotkey_decrease_opacity,
  function()
    draw.decrease_opacity()
    gui.repaint()
  end
)
keyinput.register_key_press('mouse_right', right_click)
keyinput.register_key_press('mouse_left', left_click)

-- Key releases:
keyinput.register_key_release(
  'mouse_inwindow',
  function()
    cheat.is_dragging_sprite = false
    widget.left_mouse_dragging = false
    gui.repaint()
  end
)
keyinput.register_key_release(OPTIONS.hotkey_increase_opacity, gui.repaint)
keyinput.register_key_release(OPTIONS.hotkey_decrease_opacity, gui.repaint)
keyinput.register_key_release(
  'mouse_left',
  function()
    cheat.is_dragging_sprite = false
    widget.left_mouse_dragging = false
  end
)

-- Read raw input:
keyinput.get_all_keys()

-- Timeout settings
set_timer_timeout(OPTIONS.timer_period)
set_idle_timeout(OPTIONS.idle_period)

-- Finish
draw.palettes_to_adjust(PALETTES, Palettes_adjusted)
draw.adjust_palette_transparency()
COLOUR.filter_color = draw.change_transparency(COLOUR.filter_tonality, OPTIONS.filter_opacity / 10)
gui.repaint()
print('Lua script loaded successfully.')
