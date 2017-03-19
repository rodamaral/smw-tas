---------------------------------------------------------------------------
--  Super Mario World (U) Utility Script for BizHawk
--  http://tasvideos.org/Bizhawk.html
--
--  Author: Rodrigo A. do Amaral (Amaraticando)
--  Git repository: https://github.com/rodamaral/smw-tas
---------------------------------------------------------------------------

--#############################################################################
-- CONFIG:

local INI_CONFIG_NAME = "bizhawk-config.ini"
local INI_CONFIG_FILENAME = "./config/" .. INI_CONFIG_NAME  -- relative to the folder of the script

-- Font settings
local BIZHAWK_FONT_HEIGHT = 14
local BIZHAWK_FONT_WIDTH = 10

-- Input key names
local INPUT_KEYNAMES = {  -- BizHawk

  A=false, Add=false, Alt=false, Apps=false, Attn=false, B=false, Back=false, BrowserBack=false, BrowserFavorites=false,
  BrowserForward=false, BrowserHome=false, BrowserRefresh=false, BrowserSearch=false, BrowserStop=false, C=false,
  Cancel=false, Capital=false, CapsLock=false, Clear=false, Control=false, ControlKey=false, Crsel=false, D=false, D0=false,
  D1=false, D2=false, D3=false, D4=false, D5=false, D6=false, D7=false, D8=false, D9=false, Decimal=false, Delete=false,
  Divide=false, Down=false, E=false, End=false, Enter=false, EraseEof=false, Escape=false, Execute=false, Exsel=false,
  F=false, F1=false, F10=false, F11=false, F12=false, F13=false, F14=false, F15=false, F16=false, F17=false, F18=false,
  F19=false, F2=false, F20=false, F21=false, F22=false, F23=false, F24=false, F3=false, F4=false, F5=false, F6=false,
  F7=false, F8=false, F9=false, FinalMode=false, G=false, H=false, HanguelMode=false, HangulMode=false, HanjaMode=false,
  Help=false, Home=false, I=false, IMEAccept=false, IMEAceept=false, IMEConvert=false, IMEModeChange=false,
  IMENonconvert=false, Insert=false, J=false, JunjaMode=false, K=false, KanaMode=false, KanjiMode=false, KeyCode=false,
  L=false, LaunchApplication1=false, LaunchApplication2=false, LaunchMail=false, LButton=false, LControlKey=false,
  Left=false, LineFeed=false, LMenu=false, LShiftKey=false, LWin=false, M=false, MButton=false, MediaNextTrack=false,
  MediaPlayPause=false, MediaPreviousTrack=false, MediaStop=false, Menu=false, Modifiers=false, Multiply=false, N=false,
  Next=false, NoName=false, None=false, NumLock=false, NumPad0=false, NumPad1=false, NumPad2=false, NumPad3=false,
  NumPad4=false, NumPad5=false, NumPad6=false, NumPad7=false, NumPad8=false, NumPad9=false, O=false, Oem1=false,
  Oem102=false, Oem2=false, Oem3=false, Oem4=false, Oem5=false, Oem6=false, Oem7=false, Oem8=false, OemBackslash=false,
  OemClear=false, OemCloseBrackets=false, Oemcomma=false, OemMinus=false, OemOpenBrackets=false, OemPeriod=false,
  OemPipe=false, Oemplus=false, OemQuestion=false, OemQuotes=false, OemSemicolon=false, Oemtilde=false, P=false, Pa1=false,
  Packet=false, PageDown=false, PageUp=false, Pause=false, Play=false, Print=false, PrintScreen=false, Prior=false,
  ProcessKey=false, Q=false, R=false, RButton=false, RControlKey=false, Return=false, Right=false, RMenu=false, RShiftKey=false,
  RWin=false, S=false, Scroll=false, Select=false, SelectMedia=false, Separator=false, Shift=false, ShiftKey=false,
  Sleep=false, Snapshot=false, Space=false, Subtract=false, T=false, Tab=false, U=false, Up=false, V=false, VolumeDown=false,
  VolumeMute=false, VolumeUp=false, W=false, X=false, XButton1=false, XButton2=false, Y=false, Z=false, Zoom=false
}

-- END OF CONFIG < < < < < < <
--#############################################################################
-- INITIAL STATEMENTS:


-- Load environment
package.path = package.path .. ";" .. "src/lib/?.lua"
local gui, input, joypad, emu, movie, memory, mainmemory, bit = gui, input, joypad, emu, movie, memory, mainmemory, bit
local unpack = unpack or table.unpack
local string, math, table, next, ipairs, pairs, io, os, type = string, math, table, next, ipairs, pairs, io, os, type

local luap = require "luap"
local config = require "config"
config.load_options(INI_CONFIG_FILENAME)
local smw = require "smw"
local biz = require "bizhawk.biz"
local draw = require "bizhawk.draw"

local OPTIONS = config.OPTIONS
local COLOUR = config.COLOUR
local LEFT_ARROW = config.LEFT_ARROW
local RIGHT_ARROW = config.RIGHT_ARROW

config.filename = INI_CONFIG_FILENAME
config.raw_data = {["BIZHAWK OPTIONS"] = OPTIONS}

biz.check_emulator()

print("\nStarting smw-bizhawk script.")

local fmt = string.format
local floor = math.floor

-- unsigned to signed (based in <bits> bits)
local function signed16(num, bits)
  local maxval = 32768
  if num < maxval then return num else return num - 2*maxval end
end

-- Compatibility of the memory read/write functions
local u8 =  mainmemory.read_u8
local s8 =  mainmemory.read_s8
local w8 =  mainmemory.write_u8
local u16 = mainmemory.read_u16_le
local s16 = mainmemory.read_s16_le
local w16 = mainmemory.write_u16_le
local u24 = mainmemory.read_u24_le
local s24 = mainmemory.read_s24_le
local w24 = mainmemory.write_u24_le
local u32 = mainmemory.read_u32_le
local s32 = mainmemory.read_s32_le
local w32 = mainmemory.write_u32_le


--#############################################################################
-- GAME AND SNES SPECIFIC MACROS:


local NTSC_FRAMERATE = 60.0988138974405
local PAL_FRAMERATE = 50.0069789081886

local SMW = smw.constant
local WRAM = smw.WRAM
local X_INTERACTION_POINTS = smw.X_INTERACTION_POINTS
local Y_INTERACTION_POINTS = smw.Y_INTERACTION_POINTS
local HITBOX_SPRITE = smw.HITBOX_SPRITE
local OBJ_CLIPPING_SPRITE = smw.OBJ_CLIPPING_SPRITE
local HITBOX_EXTENDED_SPRITE = smw.HITBOX_EXTENDED_SPRITE
local HITBOX_CLUSTER_SPRITE = smw.HITBOX_CLUSTER_SPRITE
local SPRITE_MEMORY_MAX = smw.SPRITE_MEMORY_MAX
local OSCILLATION_SPRITES = smw.OSCILLATION_SPRITES
local ABNORMAL_HITBOX_SPRITES = smw.ABNORMAL_HITBOX_SPRITES
local GOOD_SPRITES_CLIPPING = smw.GOOD_SPRITES_CLIPPING
local UNINTERESTING_EXTENDED_SPRITES = smw.UNINTERESTING_EXTENDED_SPRITES
local SPRITE_NAMES = smw.SPRITE_NAMES


--#############################################################################
-- SCRIPT UTILITIES:


-- Variables used in various functions
local Cheat = {}  -- family of cheat functions and variables
local Previous = {}
local User_input = INPUT_KEYNAMES -- BizHawk
local Joypad = {}
local Layer1_tiles = {}
local Layer2_tiles = {}
local Is_lagged = nil
local Mario_boost_indicator = nil
local Display = {}  -- some temporary display options
local Sprites_info = {}  -- keeps track of useful sprite info that might be used outside the main sprite function
local Sprite_hitbox = {}  -- keeps track of what sprite slots must display the hitbox
local Options_form = {}  -- BizHawk
local Item_box_table = {}

-- Initialization of some tables
for i = 0, SMW.sprite_max -1 do
  Sprites_info[i] = {}
end
for key = 0, SMW.sprite_max - 1 do
  Sprite_hitbox[key] = {}
  for number = 0, 0xff do
    Sprite_hitbox[key][number] = {["sprite"] = true, ["block"] = GOOD_SPRITES_CLIPPING[number]}
  end
end

for i = 1, 256 do
  Item_box_table[i] = fmt("$%02X - %s ($%02X)", i-1, SPRITE_NAMES[(i-1+0x73)%256], (i-1+0x73)%256)
  if i == 1 then Item_box_table[i] = "$00 - Nothing" end
end

bit.test = bit.check  -- BizHawk


-- Register a function to be executed on key press or release
-- execution happens in the main loop
local Keys = {}
Keys.press = {}
Keys.release = {}
Keys.down, Keys.up, Keys.pressed, Keys.released = {}, {}, {}, {}
function Keys.registerkeypress(key, fn)
  Keys.press[key] = fn
end
function Keys.registerkeyrelease(key, fn)
  Keys.release[key] = fn
end


-- A cross sign with pos and size
gui.crosshair = gui.drawAxis


local Movie_active, Readonly, Framecount, Lagcount, Rerecords, Game_region
local Lastframe_emulated, Starting_subframe_last_frame, Size_last_frame, Final_subframe_last_frame
local Nextframe, Starting_subframe_next_frame, Starting_subframe_next_frame, Final_subframe_next_frame
local function bizhawk_status()
  Movie_active = movie.isloaded()  -- BizHawk
  Readonly = movie.getreadonly()  -- BizHawk
  Framecount = movie.length()  -- BizHawk
  Lagcount = emu.lagcount()  -- BizHawk
  Rerecords = movie.getrerecordcount()  -- BizHawk
  Is_lagged = emu.islagged()  -- BizHawk
  Game_region = emu.getdisplaytype()  -- BizHawk

  -- Last frame info
  Lastframe_emulated = emu.framecount()

  -- Next frame info (only relevant in readonly mode)
  Nextframe = Lastframe_emulated + 1
end


local function mouse_onregion(x1, y1, x2, y2)
  -- Reads external mouse coordinates
  local mouse_x = User_input.xmouse*draw.AR_x
  local mouse_y = User_input.ymouse*draw.AR_y

  -- From top-left to bottom-right
  if x2 < x1 then
    x1, x2 = x2, x1
  end
  if y2 < y1 then
    y1, y2 = y2, y1
  end

  if mouse_x >= x1 and mouse_x <= x2 and  mouse_y >= y1 and mouse_y <= y2 then
    return true
  else
    return false
  end
end


-- Returns frames-time conversion
local function frame_time(frame)
  local total_seconds = frame/(Game_region == "NTSC" and NTSC_FRAMERATE or PAL_FRAMERATE)
  local hours = floor(total_seconds/3600)
  local tmp = total_seconds - 3600*hours
  local minutes = floor(tmp/60)
  tmp = tmp - 60*minutes
  local seconds = floor(tmp)

  local miliseconds = 1000* (total_seconds%1)
  if hours == 0 then hours = "" else hours = string.format("%d:", hours) end
  local str = string.format("%s%.2d:%.2d.%03.0f", hours, minutes, seconds, miliseconds)
  return str
end


--#############################################################################
-- SMW FUNCTIONS:


-- Returns the id of Yoshi; if more than one, the lowest sprite slot
local function get_yoshi_id()
  for i = 0, SMW.sprite_max - 1 do
    local id = u8(WRAM.sprite_number + i)
    local status = u8(WRAM.sprite_status + i)
    if id == 0x35 and status ~= 0 then return i end
  end

  return nil
end


-- Converts the in-game (x, y) to SNES-screen coordinates
local function screen_coordinates(x, y, camera_x, camera_y)
  local x_screen = (x - camera_x)
  local y_screen = (y - camera_y)

  return x_screen, y_screen
end


local Real_frame, Previous_real_frame, Effective_frame, Game_mode
local Level_index, Room_index, Level_flag, Current_level, Current_character
local Is_paused, Lock_animation_flag, Player_powerup, Player_animation_trigger
local Camera_x, Camera_y, Player_x, Player_y
local function scan_smw()
  Previous_real_frame = Real_frame or u8(WRAM.real_frame)
  Real_frame = u8(WRAM.real_frame)
  Effective_frame = u8(WRAM.effective_frame)
  Game_mode = u8(WRAM.game_mode)
  Level_index = u8(WRAM.level_index)
  Level_flag = u8(WRAM.level_flag_table + Level_index)
  Is_paused = u8(WRAM.level_paused) == 1
  Lock_animation_flag = u8(WRAM.lock_animation_flag)
  Room_index = u24(WRAM.room_index)
  Current_character = u8(WRAM.current_character) == 0 and "Mario" or "Luigi"

  -- In level frequently used info
  Player_animation_trigger = u8(WRAM.player_animation_trigger)
  Player_powerup = u8(WRAM.powerup)
  Camera_x = s16(WRAM.camera_x)
  Camera_y = s16(WRAM.camera_y)
  Player_x = s16(WRAM.x)
  Player_y = s16(WRAM.y)
  Yoshi_riding_flag = u8(WRAM.yoshi_riding_flag) ~= 0
  Yoshi_id = get_yoshi_id()
  Player_x_screen, Player_y_screen = screen_coordinates(Player_x, Player_y, Camera_x, Camera_y)
  Display.is_player_near_borders = Player_x_screen <= 32 or Player_x_screen >= 0xd0 or Player_y_screen <= -100 or Player_y_screen >= 224
end


-- Converts BizHawk/emu-screen coordinates to in-game (x, y)
local function game_coordinates(x_emu, y_emu, camera_x, camera_y)
  -- Sane values
  camera_x = camera_x or Camera_x or u8(WRAM.camera_x)
  camera_y = camera_y or Camera_y or u8(WRAM.camera_y)

  local x_game = x_emu + camera_x
  local y_game = y_emu + camera_y

  return x_game, y_game
end


-- Returns the extreme values that Mario needs to have in order to NOT touch a rectangular object
local function display_boundaries(x_game, y_game, width, height, camera_x, camera_y)
  -- Font
  draw.Text_opacity = 0.6
  draw.Bg_opacity = 0.4

  -- Coordinates around the rectangle
  local left = width*floor(x_game/width)
  local top = height*floor(y_game/height)
  left, top = screen_coordinates(left, top, camera_x, camera_y)
  local right = left + width - 1
  local bottom = top + height - 1

  -- Reads WRAM values of the player
  local is_ducking = u8(WRAM.is_ducking)
  local powerup = Player_powerup
  local is_small = is_ducking ~= 0 or powerup == 0

  -- Left
  local left_text = string.format("%4d.0", width*floor(x_game/width) - 13)
  draw.text(draw.AR_x*left, draw.AR_y*(top+bottom)/2, left_text, false, false, 1.0, 0.5)

  -- Right
  local right_text = string.format("%d.f", width*floor(x_game/width) + 12)
  draw.text(draw.AR_x*right, draw.AR_y*(top+bottom)/2, right_text, false, false, 0.0, 0.5)

  -- Top
  local value = (Yoshi_riding_flag and y_game - 16) or y_game
  local top_text = fmt("%d.0", width*floor(value/width) - 32)
  draw.text(draw.AR_x*(left+right)/2, draw.AR_y*top, top_text, false, false, 0.5, 1.0)

  -- Bottom
  value = height*floor(y_game/height)
  if not is_small and not Yoshi_riding_flag then
    value = value + 0x07
  elseif is_small and Yoshi_riding_flag then
    value = value - 4
  else
    value = value - 1  -- the 2 remaining cases are equal
  end

  local bottom_text = fmt("%d.f", value)
  draw.text(draw.AR_x*(left+right)/2, draw.AR_y*bottom, bottom_text, false, false, 0.5, 0.0)

  return left, top
end


local function read_screens()
  local screens_number = u8(WRAM.screens_number)
  local vscreen_number = u8(WRAM.vscreen_number)
  local hscreen_number = u8(WRAM.hscreen_number) - 1
  local vscreen_current = s8(WRAM.y + 1)
  local hscreen_current = s8(WRAM.x + 1)
  local level_mode_settings = u8(WRAM.level_mode_settings)
  --local b1, b2, b3, b4, b5, b6, b7, b8 = bit.multidiv(level_mode_settings, 128, 64, 32, 16, 8, 4, 2)
  --draw.text(draw.Buffer_middle_x, draw.Buffer_middle_y, {"%x: %x%x%x%x%x%x%x%x", level_mode_settings, b1, b2, b3, b4, b5, b6, b7, b8}, COLOUR.text, COLOUR.background)

  local level_type
  if (level_mode_settings ~= 0) and (level_mode_settings == 0x3 or level_mode_settings == 0x4 or level_mode_settings == 0x7
    or level_mode_settings == 0x8 or level_mode_settings == 0xa or level_mode_settings == 0xd) then
      level_type = "Vertical"
    ;
  else
    level_type = "Horizontal"
  end

  return level_type, screens_number, hscreen_current, hscreen_number, vscreen_current, vscreen_number
end


local function get_map16_value(x_game, y_game)
  local num_x = floor(x_game/16)
  local num_y = floor(y_game/16)
  if num_x < 0 or num_y < 0 then return end  -- 1st breakpoint

  local level_type, screens, _, hscreen_number, _, vscreen_number = read_screens()
  local max_x, max_y
  if level_type == "Horizontal" then
    max_x = 16*(hscreen_number + 1)
    max_y = 27
  else
    max_x = 32
    max_y = 16*(vscreen_number + 1)
  end

  if num_x > max_x or num_y > max_y then return end  -- 2nd breakpoint

  local num_id, kind, address
  if level_type == "Horizontal" then
    num_id = 16*27*floor(num_x/16) + 16*num_y + num_x%16
  else
    local nx = floor(num_x/16)
    local ny = floor(num_y/16)
    local n = 2*ny + nx
    num_id = 16*16*n + 16*(num_y%16) + num_x%16
  end
  if (num_id >= 0 and num_id <= 0x37ff) then
    address = fmt(" $%4.x", 0xc800 + num_id)
    kind = 256*u8(0x1c800 + num_id) + u8(0xc800 + num_id)
  end

  if kind then return  num_x, num_y, kind, address end
end


local function draw_layer1_tiles(camera_x, camera_y)
  local x_origin, y_origin = screen_coordinates(0, 0, camera_x, camera_y)
  local x_mouse, y_mouse = game_coordinates(User_input.xmouse, User_input.ymouse, camera_x, camera_y)
  x_mouse = 16*floor(x_mouse/16)
  y_mouse = 16*floor(y_mouse/16)
  local push_direction = Real_frame%2 == 0 and 0 or 7  -- block pushes sprites to left or right?

  for number, positions in ipairs(Layer1_tiles) do
    -- Calculate the Lsnes coordinates
    local left = positions[1] + x_origin
    local top = positions[2] + y_origin
    local right = left + 15
    local bottom = top + 15
    local x_game, y_game = game_coordinates(left, top, camera_x, camera_y)

    -- Returns if block is way too outside the screen
    if left > - draw.Border_left - 32 and top  > - draw.Border_top - 32 and
    right < draw.Screen_width  + draw.Border_right + 32 and bottom < draw.Screen_height + draw.Border_bottom + 32 then

      -- Drawings
      draw.Text_opacity = 1.0
      local num_x, num_y, kind, address = get_map16_value(x_game, y_game)
      if kind then
        if kind >= 0x111 and kind <= 0x16d or kind == 0x2b then
          -- default solid blocks, don't know how to include custom blocks
          draw.rectangle(left + push_direction, top, 8, 15, 0, COLOUR.block_bg)
        end
        draw.rectangle(left, top, 15, 15, kind == SMW.blank_tile_map16 and COLOUR.blank_tile or COLOUR.block, 0)

        if Layer1_tiles[number][3] then
          display_boundaries(x_game, y_game, 16, 16, camera_x, camera_y)  -- the text around it
        end

        -- Draw Map16 id
        draw.Text_opacity = 1.0
        if kind and x_mouse == positions[1] and y_mouse == positions[2] then
          draw.text(draw.AR_x*(left + 4), draw.AR_y*top - BIZHAWK_FONT_HEIGHT, fmt("Map16 (%d, %d), %x%s", num_x, num_y, kind, address),
          false, false, 0.5, 1.0)
        end
      end

    end

  end

end


local function draw_layer2_tiles()
  local layer2x = s16(WRAM.layer2_x_nextframe)
  local layer2y = s16(WRAM.layer2_y_nextframe)

  for number, positions in ipairs(Layer2_tiles) do
    draw.rectangle(-layer2x + positions[1], -layer2y + positions[2], 15, 15, COLOUR.layer2_line, COLOUR.layer2_bg)
  end
end


-- if the user clicks in a tile, it will be be drawn
-- if click is onto drawn region, it'll be erased
-- there's a max of possible tiles
-- layer_table[n] is an array {x, y, [draw info?]}
local function select_tile(x, y, layer_table)
  if not OPTIONS.draw_tiles_with_click then return end
  if Game_mode ~= SMW.game_mode_level then return end

  for number, positions in ipairs(layer_table) do  -- if mouse points a drawn tile, erase it
    if x == positions[1] and y == positions[2] then
      -- Layer 1
      if layer_table == Layer1_tiles then
        if layer_table[number][3] == false then
          layer_table[number][3] = true
        else
          table.remove(layer_table, number)
        end
      -- Layer 2
      elseif layer_table == Layer2_tiles then
        table.remove(layer_table, number)
      end

      return
    end
  end

  -- otherwise, draw a new tile
  if #layer_table == OPTIONS.max_tiles_drawn then
    table.remove(layer_table, 1)
    layer_table[OPTIONS.max_tiles_drawn] = {x, y, false}
  else
    table.insert(layer_table, {x, y, false})
  end

end


-- uses the mouse to select an object
local function select_object(mouse_x, mouse_y, camera_x, camera_y)
  -- Font
  draw.Text_opacity = 1.0
  draw.Bg_opacity = 0.5

  local x_game, y_game = game_coordinates(mouse_x, mouse_y, camera_x, camera_y)
  local obj_id

  -- Checks if the mouse is over Mario
  local x_player = s16(WRAM.x)
  local y_player = s16(WRAM.y)
  if x_player + 0xe >= x_game and x_player + 0x2 <= x_game and y_player + 0x30 >= y_game and y_player + 0x8 <= y_game then
    obj_id = "Mario"
  end

  if not obj_id and OPTIONS.display_sprite_info then
    for id = 0, SMW.sprite_max - 1 do
      local sprite_status = u8(WRAM.sprite_status + id)
      if sprite_status ~= 0 and Sprites_info[id].x then  -- TODO: see why the script gets here without exporting Sprites_info
        -- Import some values
        local x_sprite, y_sprite = Sprites_info[id].x, Sprites_info[id].y
        local x_screen, y_screen = Sprites_info[id].x_screen, Sprites_info[id].y_screen
        local boxid = Sprites_info[id].hitbox_id
        local xoff, yoff = Sprites_info[id].hitbox_xoff, Sprites_info[id].hitbox_yoff
        local width, height = Sprites_info[id].hitbox_width, Sprites_info[id].hitbox_height

        if x_sprite + xoff + width >= x_game and x_sprite + xoff <= x_game and
        y_sprite + yoff + height >= y_game and y_sprite + yoff <= y_game then
          obj_id = id
          break
        end
      end
    end
  end

  if not obj_id then return end

  draw.text(draw.AR_x*User_input.xmouse, draw.AR_y*(User_input.ymouse - 8), obj_id, true, false, 0.5, 1.0)
  return obj_id, x_game, y_game
end


-- This function sees if the mouse if over some object, to change its hitbox mode
-- The order is: 1) player, 2) sprite.
local function right_click()
  local id = select_object(User_input.xmouse, User_input.ymouse, Camera_x, Camera_y)

  if tostring(id) == "Mario" then

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

    return
  end

  local spr_id = tonumber(id)
  if spr_id and spr_id >= 0 and spr_id <= SMW.sprite_max - 1 then

    local number = Sprites_info[spr_id].number
    if Sprite_hitbox[spr_id][number].sprite and Sprite_hitbox[spr_id][number].block then
      Sprite_hitbox[spr_id][number].sprite = false
      Sprite_hitbox[spr_id][number].block = false
    elseif Sprite_hitbox[spr_id][number].sprite then
      Sprite_hitbox[spr_id][number].block = true
      Sprite_hitbox[spr_id][number].sprite = false
    elseif Sprite_hitbox[spr_id][number].block then
      Sprite_hitbox[spr_id][number].sprite = true
    else
      Sprite_hitbox[spr_id][number].sprite = true
    end

    return
  end

  -- Select layer 2 tiles
  local layer2x = s16(WRAM.layer2_x_nextframe)
  local layer2y = s16(WRAM.layer2_y_nextframe)
  local x_mouse, y_mouse = User_input.xmouse + layer2x, User_input.ymouse + layer2y
  select_tile(16*floor(x_mouse/16), 16*floor(y_mouse/16), Layer2_tiles)
end


local function show_movie_info()
  if not OPTIONS.display_movie_info then
    return
  end

  -- Font
  draw.Text_opacity = 1.0
  draw.Bg_opacity = 1.0
  local y_text = - draw.Border_top
  local x_text = 0
  local width = BIZHAWK_FONT_WIDTH

  local rec_color = (Readonly or not Movie_active) and COLOUR.text or COLOUR.warning
  local recording_bg = (Readonly or not Movie_active) and COLOUR.background or COLOUR.warning_bg

  -- Read-only or read-write?
  local movie_type = (not Movie_active and "No movie ") or (Readonly and "Movie " or "REC ")
  draw.alert_text(x_text, y_text, movie_type, rec_color, recording_bg)

  if Movie_active then
    -- Frame count
    x_text = x_text + width*string.len(movie_type)
    local movie_info
    if Readonly then
      movie_info = string.format("%d/%d", Lastframe_emulated, Framecount)
    else
      movie_info = string.format("%d", Lastframe_emulated)
    end
    draw.text(x_text, y_text, movie_info)  -- Shows the latest frame emulated, not the frame being run now

    -- Rerecord count
    x_text = x_text + width*string.len(movie_info)
    local rr_info = string.format(" %d ", Rerecords)
    draw.text(x_text, y_text, rr_info, COLOUR.weak)

    -- Lag count
    x_text = x_text + width*string.len(rr_info)
    draw.text(x_text, y_text, Lagcount, COLOUR.warning)
  end

  local str = frame_time(Lastframe_emulated)   -- Shows the latest frame emulated, not the frame being run now
  draw.alert_text(256*draw.AR_x, 224*draw.AR_y, str, COLOUR.text, recording_bg, false, 1.0, 1.0)

end


local function show_misc_info()
  if not OPTIONS.display_misc_info then
    return
  end

  -- Font
  draw.Text_opacity = 1.0
  draw.Bg_opacity = 1.0

  -- Display
  local RNG = u16(WRAM.RNG)
  local main_info = string.format("Frame(%02x, %02x) RNG(%04x) Mode(%02x)",
                      Real_frame, Effective_frame, RNG, Game_mode)
  ;

  draw.text(draw.Buffer_width + draw.Border_right, -draw.Border_top, main_info, true, false)

  if Game_mode == SMW.game_mode_level then
    -- Time frame counter of the clock
    draw.Text_opacity = 1.0
    local timer_frame_counter = u8(WRAM.timer_frame_counter)
    draw.text(draw.AR_x*161, draw.AR_y*15, fmt("%.2d", timer_frame_counter))

    -- Score: sum of digits, useful for avoiding lag
    draw.Text_opacity = 0.5
    local score = u24(WRAM.mario_score)
    draw.text(draw.AR_x*240, draw.AR_y*24, fmt("=%d", luap.sum_digits(score)), COLOUR.weak)
  end
end


-- Shows the controller input as the RAM and SNES registers store it
local function show_controller_data()
  if not (OPTIONS.display_miscellaneous_debug_info and OPTIONS.display_debug_controller_data) then return end

  -- Font
  draw.Text_opacity = 0.9
  local height = BIZHAWK_FONT_HEIGHT
  local x_pos, y_pos, x, y, _ = 0, 0, 0, BIZHAWK_FONT_HEIGHT

  x = draw.over_text(x_pos, y_pos, 256*u8(WRAM.ctrl_1_1) + u8(WRAM.ctrl_1_2), "BYsS^v<>AXLR0123", COLOUR.weak)
  _, y = draw.text(x, y_pos, " (RAM data)", COLOUR.weak, false, true)

  x = x_pos
  draw.over_text(x, y, 256*u8(WRAM.firstctrl_1_1) + u8(WRAM.firstctrl_1_2), "BYsS^v<>AXLR0123", 0, 0xff0000ff, 0)
end


local function level_info()
  if not OPTIONS.display_level_info then
    return
  end
  -- Font
  local x_pos = draw.Buffer_width + draw.Border_right
  local y_pos = - draw.Border_top + BIZHAWK_FONT_HEIGHT
  local color = COLOUR.text
  draw.Text_opacity = 1.0
  draw.Bg_opacity = 1.0

  local sprite_buoyancy = floor(u8(WRAM.sprite_buoyancy)/64)
  if sprite_buoyancy == 0 then sprite_buoyancy = "" else
    sprite_buoyancy = fmt(" %.2x", sprite_buoyancy)
    color = COLOUR.warning
  end

  -- converts the level number to the Lunar Magic number; should not be used outside here
  local lm_level_number = Level_index
  if Level_index > 0x24 then lm_level_number = Level_index + 0xdc end

  -- Number of screens within the level
  local level_type, screens_number, hscreen_current, hscreen_number, vscreen_current, vscreen_number = read_screens()

  draw.text(x_pos, y_pos, fmt("%.1sLevel(%.2x)%s", level_type, lm_level_number, sprite_buoyancy),
          color, true, false)
  ;

  draw.text(x_pos, y_pos + BIZHAWK_FONT_HEIGHT, fmt("Screens(%d):", screens_number), true)

  draw.text(x_pos, y_pos + 2*BIZHAWK_FONT_HEIGHT, fmt("(%d/%d, %d/%d)", hscreen_current, hscreen_number,
        vscreen_current, vscreen_number), true)
  ;
end


-- Creates lines showing where the real pit of death for sprites and Mario is, and lines showing the sprite spawning areas
local function draw_boundaries()

  -- Font
  draw.Text_opacity = 1.0
  draw.Bg_opacity = 1.0

  local is_vertical = read_screens() == "Vertical"

  -- Player borders
  if OPTIONS.display_level_boundary_always then
    local xmin = 8 - 1
    local ymin = -0x80 - 1
    local xmax = 0xe8 + 1
    local ymax = 0xfb  -- no increment, because this line kills by touch

    local no_powerup = (Player_powerup == 0)
    if no_powerup then ymax = ymax + 1 end
    if not Yoshi_riding_flag then ymax = ymax + 5 end

    draw.box(xmin, ymin, xmax, ymax, COLOUR.warning2, 2)
    if draw.Border_bottom >= 64 then
      local str = string.format("Death: %d", ymax + Camera_y)
      draw.text(xmin + 4, draw.AR_y*ymax + 2, str, COLOUR.warning2, true, false, 0.5)
      str = string.format("%s/%s", no_powerup and "No powerup" or "Big", Yoshi_riding_flag and "Yoshi" or "No Yoshi")
      draw.text(xmin + 4, draw.AR_y*ymax + BIZHAWK_FONT_HEIGHT + 2, str, COLOUR.warning2, true, false, 0.5)
    end
  end

  -- Sprite pit line
  if OPTIONS.display_sprite_vanish_area then
    local ydeath = is_vertical and Camera_y + 320 or 432
    local _, y_screen = screen_coordinates(0, ydeath, Camera_x, Camera_y)

    if y_screen < 224 + OPTIONS.bottom_gap then
      draw.line(-OPTIONS.left_gap, y_screen, 256 + OPTIONS.right_gap, y_screen, COLOUR.weak) -- x positions don't matter
    end
    local str = string.format("Sprite %s: %d", is_vertical and "\"death\"" or "death", ydeath)
    draw.text(draw.Buffer_middle_x*draw.AR_x, draw.AR_y*y_screen + 2, str, COLOUR.weak, true, false, 0.5)
  end

  -- Sprite spawning lines
  if OPTIONS.display_sprite_spawning_areas and not is_vertical then
    local left_line, right_line = 63, 32

    draw.line(-left_line, -OPTIONS.top_gap, -left_line, 224 + OPTIONS.bottom_gap, COLOUR.weak)
    draw.line(-left_line + 15, -OPTIONS.top_gap, -left_line + 15, 224 + OPTIONS.bottom_gap, COLOUR.very_weak)

    draw.line(256 + right_line, -OPTIONS.top_gap, 256 + right_line, 224 + OPTIONS.bottom_gap, COLOUR.weak)
    draw.line(256 + right_line - 15, -OPTIONS.top_gap, 256 + right_line - 15, 224 + OPTIONS.bottom_gap, COLOUR.very_weak)

    draw.text(-left_line*draw.AR_x, draw.Buffer_height + draw.Border_bottom - 2*BIZHAWK_FONT_HEIGHT, "Spawn", COLOUR.weak, true, false, 1)
    draw.text(-left_line*draw.AR_x, draw.Buffer_height + draw.Border_bottom - 1*BIZHAWK_FONT_HEIGHT, fmt("%d", Camera_x - left_line), COLOUR.weak, true, false, 1)

    draw.text((256+right_line)*draw.AR_x, draw.Buffer_height + draw.Border_bottom - 2*BIZHAWK_FONT_HEIGHT, "Spawn", COLOUR.weak)
    draw.text((256+right_line)*draw.AR_x, draw.Buffer_height + draw.Border_bottom - 1*BIZHAWK_FONT_HEIGHT, fmt("%d", Camera_x + 256 + right_line), COLOUR.weak)
  end
end


function draw_blocked_status(x_text, y_text, player_blocked_status, x_speed, y_speed)
  local block_width  = 9 -- BizHawk
  local block_height = 9 -- BizHawk
  local block_str = "Block:"
  local str_len = string.len(block_str)
  local xoffset = (x_text + str_len*BIZHAWK_FONT_WIDTH)/draw.AR_x
  local yoffset = y_text/draw.AR_y
  local color_line = COLOUR.warning

  gui.drawRectangle(xoffset + draw.Left_gap, yoffset + draw.Top_gap, block_width - 1, block_height - 1, 0x40000000, 0x40ff0000)

  local blocked_status = {}
  local was_boosted = false

  if bit.test(player_blocked_status, 0) then  -- Right
    draw.line(xoffset + block_width - 1, yoffset, xoffset + block_width - 1, yoffset + block_height - 1, color_line)
    if x_speed < 0 then was_boosted = true end
  end

  if bit.test(player_blocked_status, 1) then  -- Left
    draw.line(xoffset, yoffset, xoffset, yoffset + block_height - 1, color_line)
    if x_speed > 0 then was_boosted = true end
  end

  if bit.test(player_blocked_status, 2) then  -- Down
    draw.line(xoffset, yoffset + block_height - 1, xoffset + block_width - 1, yoffset + block_height - 1, color_line)
  end

  if bit.test(player_blocked_status, 3) then  -- Up
    draw.line(xoffset, yoffset, xoffset + block_width - 1, yoffset, color_line)
    if y_speed > 6 then was_boosted = true end
  end

  if bit.test(player_blocked_status, 4) then  -- Middle
    gui.crosshair(xoffset + floor(block_width/2) + draw.Left_gap, yoffset + floor(block_height/2) + draw.Top_gap,  -- BizHawk
    math.min(block_width/3, block_height/3), color_line)
  end

  draw.text(x_text, y_text, block_str, COLOUR.text, was_boosted and COLOUR.warning_bg or nil)

end


-- displays player's hitbox
local function player_hitbox(x, y, is_ducking, powerup, transparency_level)
  local x_screen, y_screen = screen_coordinates(x, y, Camera_x, Camera_y)
  local is_small = is_ducking ~= 0 or powerup == 0
  local hitbox_type = 2*(Yoshi_riding_flag and 1 or 0) + (is_small and 0 or 1) + 1

  -- Colors BizHawk
  local is_transparent = transparency_level == 1
  local interaction_bg = is_transparent and COLOUR.interaction_bg or 0
  local mario_bg = is_transparent and COLOUR.mario_bg or 0
  local mario_mounted_bg = is_transparent and COLOUR.mario_mounted_bg or 0
  local mario = is_transparent and COLOUR.mario or draw.change_transparency(COLOUR.mario, transparency_level)
  local interaction_nohitbox = is_transparent and COLOUR.interaction_nohitbox or draw.change_transparency(COLOUR.interaction_nohitbox, transparency_level)
  local interaction_nohitbox_bg = is_transparent and COLOUR.interaction_nohitbox_bg or 0
  local interaction = is_transparent and COLOUR.interaction or draw.change_transparency(COLOUR.interaction, transparency_level)

  -- Interaction points, offsets and dimensions
  local y_points_offsets = Y_INTERACTION_POINTS[hitbox_type]
  local left_side = X_INTERACTION_POINTS.left_side
  local right_side = X_INTERACTION_POINTS.right_side
  local left_foot = X_INTERACTION_POINTS.left_foot
  local right_foot = X_INTERACTION_POINTS.right_foot
  local x_center = X_INTERACTION_POINTS.center
  local head = y_points_offsets.head
  local foot = y_points_offsets.foot
  local y_center = y_points_offsets.center
  local shoulder = y_points_offsets.shoulder
  local side =  y_points_offsets.side

  local hitbox_offsets = smw.PLAYER_HITBOX[hitbox_type]
  local xoff = hitbox_offsets.xoff
  local yoff = hitbox_offsets.yoff
  local width = hitbox_offsets.width
  local height = hitbox_offsets.height

  -- background for block interaction
  draw.box(x_screen + left_side, y_screen + head, x_screen + right_side, y_screen + foot,
      interaction_bg, interaction_bg)

    -- Collision with sprites
  if OPTIONS.display_player_hitbox then
    local mario_bg = (not Yoshi_riding_flag and mario_bg) or mario_mounted_bg
    draw.rectangle(x_screen + xoff, y_screen + yoff, width, height, mario, mario_bg)
  end

  -- interaction points (collision with blocks)
  if OPTIONS.display_interaction_points then

    if not OPTIONS.display_player_hitbox then
      draw.box(x_screen + left_side , y_screen + head,
           x_screen + right_side, y_screen + foot, interaction_nohitbox, interaction_nohitbox_bg)
    end

    draw.line(x_screen + left_side, y_screen + side, x_screen + left_foot, y_screen + side, interaction)  -- left side
    draw.line(x_screen + right_side, y_screen + side, x_screen + right_foot, y_screen + side, interaction)  -- right side
    draw.line(x_screen + left_foot, y_screen + foot - 2, x_screen + left_foot, y_screen + foot, interaction)  -- left foot bottom
    draw.line(x_screen + right_foot, y_screen + foot - 2, x_screen + right_foot, y_screen + foot, interaction)  -- right foot bottom
    draw.line(x_screen + left_side, y_screen + shoulder, x_screen + left_side + 2, y_screen + shoulder, interaction)  -- head left point
    draw.line(x_screen + right_side - 2, y_screen + shoulder, x_screen + right_side, y_screen + shoulder, interaction)  -- head right point
    draw.line(x_screen + x_center, y_screen + head, x_screen + x_center, y_screen + head + 2, interaction)  -- head point
    draw.line(x_screen + x_center - 1, y_screen + y_center, x_screen + x_center + 1, y_screen + y_center, interaction)  -- center point
    draw.line(x_screen + x_center, y_screen + y_center - 1, x_screen + x_center, y_screen + y_center + 1, interaction)  -- center point
  end

  -- That's the pixel that appears when Mario dies in the pit
  Display.show_player_point_position = Display.show_player_point_position or Display.is_player_near_borders or OPTIONS.display_debug_player_extra
  if Display.show_player_point_position then
    draw.pixel(x_screen, y_screen, COLOUR.text, COLOUR.interaction_bg)
    Display.show_player_point_position = false
  end

  return x_points, y_points
end


-- displays the hitbox of the cape while spinning
local function cape_hitbox(spin_direction)
  local cape_interaction = u8(WRAM.cape_interaction)
  if cape_interaction == 0 then return end

  local cape_x = u16(WRAM.cape_x)
  local cape_y = u16(WRAM.cape_y)

  local cape_x_screen, cape_y_screen = screen_coordinates(cape_x, cape_y, Camera_x, Camera_y)
  local cape_left = -2
  local cape_right = 0x12
  local cape_up = 0x01
  local cape_down = 0x11
  local cape_middle = 0x08
  local block_interaction_cape = (spin_direction < 0 and cape_left + 4) or cape_right - 4
  local active_frame_sprites = Real_frame%2 == 1  -- active iff the cape can hit a sprite
  local active_frame_blocks  = Real_frame%2 == (spin_direction < 0 and 0 or 1)  -- active iff the cape can hit a block

  if active_frame_sprites then bg_color = COLOUR.cape_bg else bg_color = 0 end
  draw.box(cape_x_screen + cape_left, cape_y_screen + cape_up, cape_x_screen + cape_right, cape_y_screen + cape_down, COLOUR.cape, bg_color)

  if active_frame_blocks then
    draw.pixel(cape_x_screen + block_interaction_cape, cape_y_screen + cape_middle, COLOUR.warning)
  else
    draw.pixel(cape_x_screen + block_interaction_cape, cape_y_screen + cape_middle, COLOUR.text)
  end
end


-- arguments: left and bottom pixels of a given block tile
-- return: string type of duplication that will happen
--         false otherwise
local function sprite_block_interaction_simulator(x_block_left, y_block_bottom)
  --local GOOD_SPEEDS = luap.make_set{-2.5, -2, -1.5, -1, 0, 0.5, 1.0, 1.5, 2.5, 3.0, 3.5, 4.0}

  -- get 1st carried sprite slot
  local slot
  for id = 0, SMW.sprite_max - 1 do
    if u8(WRAM.sprite_status + id) == 0x0b then
      slot = id
      break
    end
  end
  if not slot then return false end

  -- sprite properties
  local ini_x = luap.signed16(256*u8(WRAM.sprite_x_high + slot) + u8(WRAM.sprite_x_low + slot))
  local ini_y = luap.signed16(256*u8(WRAM.sprite_y_high + slot) + u8(WRAM.sprite_y_low + slot))
  local ini_y_sub = u8(WRAM.sprite_y_sub + slot)

  -- Sprite clipping vs objects
  local clip_obj = bit.band(u8(WRAM.sprite_1_tweaker + slot), 0xf)
  local ypt_right = OBJ_CLIPPING_SPRITE[clip_obj].yright
  local ypt_left = OBJ_CLIPPING_SPRITE[clip_obj].yleft
  local xpt_up = OBJ_CLIPPING_SPRITE[clip_obj].xup
  local ypt_up = OBJ_CLIPPING_SPRITE[clip_obj].yup

  -- Parameters that will vary each frame
  local left_direction = Real_frame%2 == 0
  local y_speed = -112
  local y = ini_y
  local x_head = ini_x + xpt_up
  local y_sub = ini_y_sub

  --print(fmt("Block: %d %d - Spr. ^%d <%d >%d", x_block_left, y_block_bottom, ypt_up, ypt_left, ypt_right))
  -- Predict each frame:
  while y_speed < 0 do
    -- Calculate next position.subpixel
    --print(fmt("prediction: (%d, %d.%.2x) %+d %s", x_head, y + ypt_up, y_sub, y_speed, left_direction and "left" or "right"))
    local next_total_subpixels = 256*y + y_sub + 16*y_speed
    y, y_sub = math.floor(next_total_subpixels/256), next_total_subpixels%256

    -- verify whether the block will be duplicated:
    -- if head is on block
    if y + ypt_up <= y_block_bottom and y + ypt_up >= y_block_bottom - 15 then
      -- lateral duplication
      -- if head is in the left-most 4 pixels
      if left_direction and x_block_left <= x_head and x_head - 4 < x_block_left then
        if y + ypt_left <= y_block_bottom then
          return "Left"
        end
      -- if head is in the right-most 4 pixels
      elseif not left_direction and x_head <= x_block_left + 15 and x_head + 4 > x_block_left + 15 then
        if y + ypt_right <= y_block_bottom then
          return "Right"
        end
      end

      -- Upward duplication
      if y + ypt_up <= y_block_bottom - 14 then  -- 2 pixels height
        return "Upward"
      end

      return false
    end

    -- Set next step
    y_speed = y_speed + 3
    left_direction = not left_direction
  end

  return false
end


-- verify nearby layer 1 tiles that are drawn
-- check whether they would allow a block duplication under ideal conditions
local function predict_block_duplications()
  if not OPTIONS.use_block_duplication_predictor then return end
  local delta_x, delta_y = 48, 128

  for number, positions in ipairs(Layer1_tiles) do
    if luap.inside_rectangle(positions[1], positions[2], Player_x - delta_x, Player_y - delta_y, Player_x + delta_x, Player_y + delta_y) then
      local dup_status = sprite_block_interaction_simulator(positions[1], positions[2] + 15)

      if dup_status then
        -- TODO: BizHawk stacks the messages. Fix it
        --local x, y = math.floor(positions[1]/16), math.floor(positions[2]/16)
        -- gui.addmessage(fmt("Duplication prediction: %d, %d", x, y))

        local xs, ys = screen_coordinates(positions[1] + 7, positions[2], Camera_x, Camera_y)
        draw.text(draw.AR_x*xs, draw.AR_y*ys - 4, fmt("%s duplication", dup_status),
          COLOUR.warning, COLOUR.warning_bg, true, false, 0.5, 1.0)
        break
      end

    end
  end
end


local function player()
  if not OPTIONS.display_player_info then
    return
  end

  -- Font
  draw.Text_opacity = 1.0

  -- Reads WRAM
  local x = s16(WRAM.x)
  local y = s16(WRAM.y)
  local previous_x = s16(WRAM.previous_x)
  local previous_y = s16(WRAM.previous_y)
  local x_sub = u8(WRAM.x_sub)
  local y_sub = u8(WRAM.y_sub)
  local x_speed = s8(WRAM.x_speed)
  local x_subspeed = u8(WRAM.x_subspeed)
  local y_speed = s8(WRAM.y_speed)
  local p_meter = u8(WRAM.p_meter)
  local take_off = u8(WRAM.take_off)
  local powerup = Player_powerup
  local direction = u8(WRAM.direction)
  local cape_spin = u8(WRAM.cape_spin)
  local cape_fall = u8(WRAM.cape_fall)
  local flight_animation = u8(WRAM.flight_animation)
  local diving_status = s8(WRAM.diving_status)
  local player_blocked_status = u8(WRAM.player_blocked_status)
  local item_box = u8(WRAM.item_box)
  local is_ducking = u8(WRAM.is_ducking)
  local on_ground = u8(WRAM.on_ground)
  local spinjump_flag = u8(WRAM.spinjump_flag)
  local can_jump_from_water = u8(WRAM.can_jump_from_water)
  local carrying_item = u8(WRAM.carrying_item)
  local scroll_timer = u8(WRAM.camera_scroll_timer)
  local vertical_scroll_flag_header = u8(WRAM.vertical_scroll_flag_header)
  local vertical_scroll_enabled = u8(WRAM.vertical_scroll_enabled)

  -- Transformations
  if direction == 0 then direction = LEFT_ARROW else direction = RIGHT_ARROW end
  local x_sub_simple, y_sub_simple-- = x_sub, y_sub
  if x_sub%0x10 == 0 then x_sub_simple = fmt("%x", x_sub/0x10) else x_sub_simple = fmt("%.2x", x_sub) end
  if y_sub%0x10 == 0 then y_sub_simple = fmt("%x", y_sub/0x10) else y_sub_simple = fmt("%.2x", y_sub) end

  local x_speed_int, x_speed_frac = math.modf(x_speed + x_subspeed/0x100)
  x_speed_frac = math.abs(x_speed_frac*100)

  local spin_direction = (Effective_frame)%8
  if spin_direction < 4 then
    spin_direction = spin_direction + 1
  else
    spin_direction = 3 - spin_direction
  end

  local is_caped = powerup == 0x2
  local is_spinning = cape_spin ~= 0 or spinjump_flag ~= 0

  -- Display info
  local i = 0
  local delta_x = BIZHAWK_FONT_WIDTH
  local delta_y = BIZHAWK_FONT_HEIGHT
  local table_x = - draw.Border_left
  local table_y = draw.AR_y*32

  draw.text(table_x, table_y + i*delta_y, fmt("Meter (%03d, %02d) %s", p_meter, take_off, direction))
  draw.text(table_x + 18*delta_x, table_y + i*delta_y, fmt(" %+d", spin_direction),
  (is_spinning and COLOUR.text) or COLOUR.weak)
  i = i + 1

  draw.text(table_x, table_y + i*delta_y, fmt("Pos (%+d.%s, %+d.%s)", x, x_sub_simple, y, y_sub_simple))
  i = i + 1

  draw.text(table_x, table_y + i*delta_y, fmt("Speed (%+d(%d.%02.0f), %+d)", x_speed, x_speed_int, x_speed_frac, y_speed))
  i = i + 1

  if is_caped then
    draw.text(table_x, table_y + i*delta_y, fmt("Cape (%.2d, %.2d)/(%d, %d)", cape_spin, cape_fall, flight_animation, diving_status), COLOUR.cape)
    i = i + 1
  end

  local x_txt = draw.text(table_x, table_y + i*delta_y, fmt("Camera (%d, %d)", Camera_x, Camera_y))
  if scroll_timer ~= 0 then x_txt = draw.text(x_txt, table_y + i*delta_y, 16 - scroll_timer, COLOUR.warning) end
  if vertical_scroll_flag_header ~=0 and vertical_scroll_enabled ~= 0 then
    draw.text(x_txt, table_y + i*delta_y, vertical_scroll_enabled, COLOUR.warning2)
  end
  i = i + 1

  local item_box_sprite = (item_box + 0x73)%256
  draw.text(241, 1, fmt("$%02X", item_box), COLOUR.weak)
  if item_box ~= 0 then
  draw.text(226, 66, fmt("ID $%02X", item_box_sprite), COLOUR.weak)
  end

  if OPTIONS.display_static_camera_region then
    Display.show_player_point_position = true
    local left_cam, right_cam = u16(WRAM.camera_left_limit), u16(WRAM.camera_right_limit)
    draw.box(left_cam, 0, right_cam, 224, COLOUR.static_camera_region, COLOUR.static_camera_region)
  end

  draw_blocked_status(table_x, table_y + i*delta_y, player_blocked_status, x_speed, y_speed)

  -- Mario boost indicator (experimental)
  -- This looks for differences between the expected x position and the actual x position, after a frame advance
  -- Fails during a loadstate and has false positives if the game is paused or lagged
  Previous.player_x = 256*x + x_sub  -- the total amount of 256-based subpixels
  Previous.x_speed = 16*x_speed  -- the speed in 256-based subpixels

  if Mario_boost_indicator and not Cheat.under_free_move then
    local x_screen, y_screen = screen_coordinates(x, y, Camera_x, Camera_y)
    draw.text(draw.AR_x*(x_screen + 4), draw.AR_y*(y_screen + 60), Mario_boost_indicator, COLOUR.warning, 0x20000000)  -- unlisted color
  end

  -- shows hitbox and interaction points for player
  if not (OPTIONS.display_player_hitbox or OPTIONS.display_interaction_points) then return end

  cape_hitbox(spin_direction)
  player_hitbox(x, y, is_ducking, powerup, 1.0)

  -- Shows where Mario is expected to be in the next frame, if he's not boosted or stopped (DEBUG)
  if OPTIONS.display_miscellaneous_debug_info and OPTIONS.display_debug_player_extra then
    player_hitbox( floor((256*x + x_sub + 16*x_speed)/256),
      floor((256*y + y_sub + 16*y_speed)/256), is_ducking, powerup, 0.3)  -- BizHawk
  end

end


local function extended_sprites()
  if not OPTIONS.display_extended_sprite_info then
    return
  end

  -- Font
  draw.Text_opacity = 1.0
  local height = BIZHAWK_FONT_HEIGHT

  local y_pos = draw.AR_y*144
  local counter = 0
  for id = 0, SMW.extended_sprite_max - 1 do
    local extspr_number = u8(WRAM.extspr_number + id)

    if extspr_number ~= 0 then
      -- Reads WRAM addresses
      local x = 256*u8(WRAM.extspr_x_high + id) + u8(WRAM.extspr_x_low + id)
      local y = 256*u8(WRAM.extspr_y_high + id) + u8(WRAM.extspr_y_low + id)
      local sub_x = bit.rshift(u8(WRAM.extspr_subx + id), 4)
      local sub_y = bit.rshift(u8(WRAM.extspr_suby + id), 4)
      local x_speed = s8(WRAM.extspr_x_speed + id)
      local y_speed = s8(WRAM.extspr_y_speed + id)
      local extspr_table = u8(WRAM.extspr_table + id)
      local extspr_table2 = u8(WRAM.extspr_table2 + id)

      -- Reduction of useless info
      local special_info = ""
      if OPTIONS.display_miscellaneous_debug_info and OPTIONS.display_debug_extended_sprite and (extspr_table ~= 0 or extspr_table2 ~= 0) then
        special_info = fmt("(%x, %x) ", extspr_table, extspr_table2)
      end

      -- x speed for Fireballs
      if extspr_number == 5 then x_speed = 16*x_speed end

      if OPTIONS.display_extended_sprite_info then
        draw.text(draw.Buffer_width + draw.Border_right, y_pos + counter*height, fmt("#%.2d %.2x %s(%d.%x(%+.2d), %d.%x(%+.2d))",
                                  id, extspr_number, special_info, x, sub_x, x_speed, y, sub_y, y_speed),
                                  COLOUR.extended_sprites, true, false)
      end

      if (OPTIONS.display_miscellaneous_debug_info and OPTIONS.display_debug_extended_sprite) or not UNINTERESTING_EXTENDED_SPRITES[extspr_number]
        or (extspr_number == 1 and extspr_table2 == 0xf)
      then
        local x_screen, y_screen = screen_coordinates(x, y, Camera_x, Camera_y)

        local t = HITBOX_EXTENDED_SPRITE[extspr_number] or
          {xoff = 0, yoff = 0, width = 16, height = 16, color_line = COLOUR.awkward_hitbox, color_bg = COLOUR.awkward_hitbox_bg}
        local xoff = t.xoff
        local yoff = t.yoff
        local xrad = t.width
        local yrad = t.height

        local color_line = t.color_line or COLOUR.extended_sprites
        local color_bg = t.color_bg or COLOUR.extended_sprites_bg
        if extspr_number == 0x5 or extspr_number == 0x11 then
          color_bg = (Real_frame - id)%4 == 0 and COLOUR.special_extended_sprite_bg or 0
        end
        draw.rectangle(x_screen+xoff, y_screen+yoff, xrad, yrad, color_line, color_bg) -- regular hitbox

        -- Experimental: attempt to show Mario's fireball vs sprites
        -- this is likely wrong in some situation, but I can't solve this yet
        if extspr_number == 5 or extspr_number == 1 then
          local xoff_spr = x_speed >= 0 and -5 or  1
          local yoff_spr = - floor(y_speed/16) - 4 + (y_speed >= -40 and 1 or 0)
          local yrad_spr = y_speed >= -40 and 19 or 20
          draw.rectangle(x_screen + xoff_spr, y_screen + yoff_spr, 12, yrad_spr, color_line, color_bg)
        end
      end

      counter = counter + 1
    end
  end

  draw.Text_opacity = 0.5
  local x_pos, y_pos, length = draw.text(draw.Buffer_width + draw.Border_right, y_pos, fmt("Ext. spr:%2d ", counter), COLOUR.weak, true, false, 0.0, 1.0)

  if u8(WRAM.spinjump_flag) ~= 0 and u8(WRAM.powerup) == 3 then
    local fireball_timer = u8(WRAM.spinjump_fireball_timer)
    draw.text(x_pos - length - BIZHAWK_FONT_WIDTH, y_pos, fmt("%d %s",
    fireball_timer%16, bit.test(fireball_timer, 4) and RIGHT_ARROW or LEFT_ARROW), COLOUR.extended_sprites, true, false, 1.0, 1.0)
  end

end


local function cluster_sprites()
  if not OPTIONS.display_cluster_sprite_info or u8(WRAM.cluspr_flag) == 0 then return end

  -- Font
  draw.Text_opacity = 1.0
  local height = BIZHAWK_FONT_HEIGHT
  local x_pos, y_pos = draw.AR_x*90, draw.AR_y*77  -- BizHawk
  local counter = 0

  if OPTIONS.display_miscellaneous_debug_info and OPTIONS.display_debug_cluster_sprite then
    draw.text(x_pos, y_pos, "Cluster Spr.", COLOUR.weak)
    counter = counter + 1
  end

  local reappearing_boo_counter

  for id = 0, SMW.cluster_sprite_max - 1 do
    local clusterspr_number = u8(WRAM.cluspr_number + id)

    if clusterspr_number ~= 0 then
      if not HITBOX_CLUSTER_SPRITE[clusterspr_number] then
        print("Warning: wrong cluster sprite number:", clusterspr_number)  -- should not happen without cheats
        return
      end

      -- Reads WRAM addresses
      local x = signed16(256*u8(WRAM.cluspr_x_high + id) + u8(WRAM.cluspr_x_low + id))
      local y = signed16(256*u8(WRAM.cluspr_y_high + id) + u8(WRAM.cluspr_y_low + id))
      local clusterspr_timer, special_info, table_1, table_2, table_3

      -- Reads cluster's table
      local x_screen, y_screen = screen_coordinates(x, y, Camera_x, Camera_y)
      local t = HITBOX_CLUSTER_SPRITE[clusterspr_number] or
        {xoff = 0, yoff = 0, width = 16, height = 16, color_line = COLOUR.awkward_hitbox, color_bg = COLOUR.awkward_hitbox_bg, oscillation = 1}
      local xoff = t.xoff
      local yoff = t.yoff
      local xrad = t.width
      local yrad = t.height
      local phase = t.phase or 0
      local oscillation = (Real_frame - id)%t.oscillation == phase
      local color = t.color or COLOUR.cluster_sprites
      local color_bg = t.bg or COLOUR.sprites_bg
      local invencibility_hitbox = nil

      if OPTIONS.display_miscellaneous_debug_info and OPTIONS.display_debug_cluster_sprite then
        table_1 = u8(WRAM.cluspr_table_1 + id)
        table_2 = u8(WRAM.cluspr_table_2 + id)
        table_3 = u8(WRAM.cluspr_table_3 + id)
        draw.text(x_pos, y_pos + counter*height, ("#%d(%d): (%d, %d) %d, %d, %d")
        :format(id, clusterspr_number, x, y, table_1, table_2, table_3), color)
        counter = counter + 1
      end

      -- Case analysis
      if clusterspr_number == 3 or clusterspr_number == 8 then
        clusterspr_timer = u8(WRAM.cluspr_timer + id)
        if clusterspr_timer ~= 0 then special_info = " " .. clusterspr_timer end
      elseif clusterspr_number == 6 then
        table_1 = table_1 or u8(WRAM.cluspr_table_1 + id)
        if table_1 >= 111 or (table_1 < 31 and table_1 >= 16) then
          yoff = yoff + 17
        elseif table_1 >= 103 or table_1 < 16 then
          invencibility_hitbox = true
        elseif table_1 >= 95 or (table_1 < 47 and table_1 >= 31) then
          yoff = yoff + 16
        end
      elseif clusterspr_number == 7 then
        reappearing_boo_counter = reappearing_boo_counter or u8(WRAM.reappearing_boo_counter)
        invencibility_hitbox = (reappearing_boo_counter > 0xde) or (reappearing_boo_counter < 0x3f)
        special_info = " " .. reappearing_boo_counter
      end

      -- Hitbox and sprite id
      color = invencibility_hitbox and COLOUR.weak or color
      color_bg = (invencibility_hitbox and 0) or (oscillation and color_bg) or 0
      draw.rectangle(x_screen + xoff, y_screen + yoff, xrad, yrad, color, color_bg)
      draw.text(draw.AR_x*(x_screen + xoff) + xrad, draw.AR_y*(y_screen + yoff), special_info and id .. special_info or id,
      color, false, false, 0.5, 1.0)
    end
  end
end


local function minor_extended_sprites()
  if not OPTIONS.display_minor_extended_sprite_info then return end

  -- Font
  draw.Text_opacity = 1.0
  local height = BIZHAWK_FONT_HEIGHT
  local x_pos, y_pos = 0, draw.Buffer_height - height*SMW.minor_extended_sprite_max
  local counter = 0

  for id = 0, SMW.minor_extended_sprite_max - 1 do
    local minorspr_number = u8(WRAM.minorspr_number + id)

    if minorspr_number ~= 0 then
      -- Reads WRAM addresses
      local x = signed16(256*u8(WRAM.minorspr_x_high + id) + u8(WRAM.minorspr_x_low + id))
      local y = signed16(256*u8(WRAM.minorspr_y_high + id) + u8(WRAM.minorspr_y_low + id))
      local xspeed, yspeed = s8(WRAM.minorspr_xspeed + id), s8(WRAM.minorspr_yspeed + id)
      local x_sub, y_sub = u8(WRAM.minorspr_x_sub + id), u8(WRAM.minorspr_y_sub + id)
      local timer = u8(WRAM.minorspr_timer + id)

      -- Only sprites 1 and 10 use the higher byte
      local x_screen, y_screen = screen_coordinates(x, y, Camera_x, Camera_y)
      if minorspr_number ~= 1 and minorspr_number ~= 10 then  -- Boo stream and Piece of brick block
        x_screen = x_screen%0x100
        y_screen = y_screen%0x100
      end

      -- Draw next to the sprite
      local text = "#" .. id .. (timer ~= 0 and (" " .. timer) or "")
      draw.text(draw.AR_x*(x_screen + 8), draw.AR_y*(y_screen + 4), text, COLOUR.minor_extended_sprites, false, false, 0.5, 1.0)
      if minorspr_number == 10 then  -- Boo stream
        draw.rectangle(x_screen + 4, y_screen + 4, 8, 8, COLOUR.minor_extended_sprites, COLOUR.sprites_bg)
      end

      -- Draw in the table
      if OPTIONS.display_miscellaneous_debug_info and OPTIONS.display_debug_minor_extended_sprite then
        draw.text(x_pos, y_pos + counter*height, ("#%d(%d): %d.%x(%d), %d.%x(%d)")
        :format(id, minorspr_number, x, floor(x_sub/16), xspeed, y, floor(y_sub/16), yspeed), COLOUR.minor_extended_sprites)
      end
      counter = counter + 1
    end
  end

  if OPTIONS.display_miscellaneous_debug_info and OPTIONS.display_debug_minor_extended_sprite then
    draw.text(x_pos, y_pos - height, "Minor Ext Spr:" .. counter, COLOUR.weak)
  end
end


local function bounce_sprite_info()
  if not OPTIONS.display_bounce_sprite_info then return end

  -- Debug info
  local x_txt, y_txt = draw.AR_x*90, draw.AR_y*37
  if OPTIONS.display_miscellaneous_debug_info and OPTIONS.display_debug_bounce_sprite then
    draw.Text_opacity = 0.5
    draw.text(x_txt, y_txt, "Bounce Spr.", COLOUR.weak)
  end

  -- Font
  draw.Text_opacity = 1.0
  local height = BIZHAWK_FONT_HEIGHT

  local stop_id = (u8(WRAM.bouncespr_last_id) - 1)%SMW.bounce_sprite_max
  for id = 0, SMW.bounce_sprite_max - 1 do
    local bounce_sprite_number = u8(WRAM.bouncespr_number + id)
    if bounce_sprite_number ~= 0 then
      local x = luap.signed16(256*u8(WRAM.bouncespr_x_high + id) + u8(WRAM.bouncespr_x_low + id))
      local y = luap.signed16(256*u8(WRAM.bouncespr_y_high + id) + u8(WRAM.bouncespr_y_low + id))
      local bounce_timer = u8(WRAM.bouncespr_timer + id)

      if OPTIONS.display_miscellaneous_debug_info and OPTIONS.display_debug_bounce_sprite then
        draw.text(x_txt, y_txt + height*(id + 1), fmt("#%d:%d (%d, %d)", id, bounce_sprite_number, x, y))
      end

      local x_screen, y_screen = screen_coordinates(x, y, Camera_x, Camera_y)
      x_screen, y_screen = draw.AR_x*(x_screen + 8), draw.AR_y*y_screen

      -- hitbox vs sprites
      -- I don't use the WRAM range from [$16cd, $16e0] like the game does
      if bounce_timer == 4 or bounce_timer == 3 then
        draw.rectangle(16*floor(x/16) - Camera_x - 4, 16*floor(y/16) - Camera_y + 12,
          24, 24, COLOUR.bounce_sprite, COLOUR.bounce_sprite_bg)
      end

      local color = id == stop_id and COLOUR.warning or COLOUR.text
      draw.text(x_screen , y_screen, fmt("#%d:%d", id, bounce_timer), color, false, false, 0.5)  -- timer

      -- Turn blocks
      if bounce_sprite_number == 7 then
        turn_block_timer = u8(WRAM.turn_block_timer + id)
        draw.text(x_screen, y_screen + height, turn_block_timer, color, false, false, 0.5)
      end
    end
  end
end


local function scan_sprite_info(lua_table, slot)
  local t = lua_table[slot]
  if not t then error"Wrong Sprite table" end

  t.status = u8(WRAM.sprite_status + slot)
  if t.status == 0 then
    return -- returns if the slot is empty
  end

  local x = 256*u8(WRAM.sprite_x_high + slot) + u8(WRAM.sprite_x_low + slot)
  local y = 256*u8(WRAM.sprite_y_high + slot) + u8(WRAM.sprite_y_low + slot)
  t.x_sub = u8(WRAM.sprite_x_sub + slot)
  t.y_sub = u8(WRAM.sprite_y_sub + slot)
  t.number = u8(WRAM.sprite_number + slot)
  t.stun = u8(WRAM.sprite_miscellaneous7 + slot)
  t.x_speed = s8(WRAM.sprite_x_speed + slot)
  t.y_speed = s8(WRAM.sprite_y_speed + slot)
  t.contact_mario = u8(WRAM.sprite_miscellaneous8 + slot)
  t.underwater = u8(WRAM.sprite_underwater + slot)
  t.x_offscreen = s8(WRAM.sprite_x_offscreen + slot)
  t.y_offscreen = s8(WRAM.sprite_y_offscreen + slot)

  -- Transform some read values into intelligible content
  t.x = luap.signed16(x)
  t.y = luap.signed16(y)
  t.x_screen, t.y_screen = screen_coordinates(t.x, t.y, Camera_x, Camera_y)

  if OPTIONS.display_debug_sprite_extra or ((t.status < 0x8 and t.status > 0xb) or stun ~= 0) then
    t.table_special_info = fmt("(%d %d) ", t.status, t.stun)
  else
    t.table_special_info = ""
  end

  t.oscillation_flag = bit.test(u8(WRAM.sprite_4_tweaker + slot), 5) or OSCILLATION_SPRITES[t.number]

  -- Sprite clipping vs mario and sprites
  local boxid = bit.band(u8(WRAM.sprite_2_tweaker + slot), 0x3f)  -- This is the type of box of the sprite
  t.hitbox_id = boxid
  t.hitbox_xoff = HITBOX_SPRITE[boxid].xoff
  t.hitbox_yoff = HITBOX_SPRITE[boxid].yoff
  t.hitbox_width = HITBOX_SPRITE[boxid].width
  t.hitbox_height = HITBOX_SPRITE[boxid].height

  -- Sprite clipping vs objects
  local clip_obj = bit.band(u8(WRAM.sprite_1_tweaker + slot), 0xf)  -- type of hitbox for blocks
  t.clipping_id = clip_obj
  t.xpt_right = OBJ_CLIPPING_SPRITE[clip_obj].xright
  t.ypt_right = OBJ_CLIPPING_SPRITE[clip_obj].yright
  t.xpt_left = OBJ_CLIPPING_SPRITE[clip_obj].xleft
  t.ypt_left = OBJ_CLIPPING_SPRITE[clip_obj].yleft
  t.xpt_down = OBJ_CLIPPING_SPRITE[clip_obj].xdown
  t.ypt_down = OBJ_CLIPPING_SPRITE[clip_obj].ydown
  t.xpt_up = OBJ_CLIPPING_SPRITE[clip_obj].xup
  t.ypt_up = OBJ_CLIPPING_SPRITE[clip_obj].yup

  -- Some HUD configurations
  -- calculate the correct color to use, according to slot
  if t.number == 0x35 then
    t.info_color = COLOUR.yoshi
    t.background_color = COLOUR.yoshi_bg
  else
    t.info_color = COLOUR.sprites[slot%(#COLOUR.sprites) + 1]
    t.background_color = COLOUR.sprites_bg
  end
  if (not t.oscillation_flag) and (Real_frame - slot)%2 == 1 then t.background_color = 0 end

  t.sprite_middle = t.x_screen + t.hitbox_xoff + math.floor(t.hitbox_width/2)
  t.sprite_top = t.y_screen + math.min(t.hitbox_yoff, t.ypt_up)
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
  local display_hitbox = Sprite_hitbox[slot][number].sprite and not ABNORMAL_HITBOX_SPRITES[number]
  local display_clipping = Sprite_hitbox[slot][number].block
  local alive_status = (t.status == 0x03 or t.status >= 0x08)
  local info_color = alive_status and t.info_color or COLOUR.very_weak
  local background_color = alive_status and t.background_color or 0

  -- That's the pixel that appears when the sprite vanishes in the pit
  if y_screen >= 224 or OPTIONS.display_debug_sprite_extra then
    draw.pixel(x_screen, y_screen, info_color, COLOUR.very_weak)
  end

  if display_clipping then -- sprite clipping background
    draw.box(x_screen + xpt_left, y_screen + ypt_down, x_screen + xpt_right, y_screen + ypt_up,
      2, COLOUR.sprites_clipping_bg, display_hitbox and -1 or COLOUR.sprites_clipping_bg)
  end

  if display_hitbox then  -- show sprite/sprite clipping
    draw.rectangle(x_screen + xoff, y_screen + yoff, width, height, info_color, background_color)
  end

  if display_clipping then  -- show sprite/object clipping
    local size, color = 1, COLOUR.sprites_interaction_pts
    draw.line(x_screen + xpt_right, y_screen + ypt_right, x_screen + xpt_right - size, y_screen + ypt_right, color) -- right
    draw.line(x_screen + xpt_left, y_screen + ypt_left, x_screen + xpt_left + size, y_screen + ypt_left, color)  -- left
    draw.line(x_screen + xpt_down, y_screen + ypt_down, x_screen + xpt_down, y_screen + ypt_down - size, color) -- down
    draw.line(x_screen + xpt_up, y_screen + ypt_up, x_screen + xpt_up, y_screen + ypt_up + size, color)  -- up
  end

  -- Sprite vs sprite hitbox
  if OPTIONS.display_sprite_vs_sprite_hitbox then
    if u8(WRAM.sprite_miscellaneous10 + slot) == 0 and u8(0x15d0 + slot) == 0
    and bit.testn(u8(WRAM.sprite_5_tweaker + slot), 3) then

      local boxid2 = bit.band(u8(WRAM.sprite_2_tweaker + slot), 0x0f)
      local yoff2 = boxid2 == 0 and 2 or 0xa  -- ROM data
      local bg_color = t.status >= 8 and 0x80ffffff or 0x80ff0000
      if Real_frame%2 == 0 then bg_color = -1 end

      -- if y1 - y2 + 0xc < 0x18
      draw.rectangle(x_screen, y_screen + yoff2, 0x10, 0x0c, 0xffffff)
      draw.rectangle(x_screen, y_screen + yoff2, 0x10-1, 0x0c - 1, info_color, bg_color)
    end
  end
end


-- Sprite tweakers info
local function sprite_tweaker_editor(slot)
  if OPTIONS.display_debug_sprite_tweakers then
    local t = Sprites_info[slot]
    local info_color = t.info_color
    local y_screen = t.y_screen
    local xoff = t.hitbox_xoff
    local yoff = t.hitbox_yoff

    local width, height = BIZHAWK_FONT_WIDTH, BIZHAWK_FONT_HEIGHT
    local x_ini, y_ini = draw.AR_x*t.sprite_middle - 4*width, draw.AR_y*(y_screen + yoff) - 7*height
    local x_txt, y_txt = x_ini, y_ini

    local tweaker_1 = u8(WRAM.sprite_1_tweaker + slot)
    draw.over_text(x_txt, y_txt, tweaker_1, "sSjJcccc", COLOUR.weak, info_color)
    y_txt = y_txt + height

    local tweaker_2 = u8(WRAM.sprite_2_tweaker + slot)
    draw.over_text(x_txt, y_txt, tweaker_2, "dscccccc", COLOUR.weak, info_color)
    y_txt = y_txt + height

    local tweaker_3 = u8(WRAM.sprite_3_tweaker + slot)
    draw.over_text(x_txt, y_txt, tweaker_3, "lwcfpppg", COLOUR.weak, info_color)
    y_txt = y_txt + height

    local tweaker_4 = u8(WRAM.sprite_4_tweaker + slot)
    draw.over_text(x_txt, y_txt, tweaker_4, "dpmksPiS", COLOUR.weak, info_color)
    y_txt = y_txt + height

    local tweaker_5 = u8(WRAM.sprite_5_tweaker + slot)
    draw.over_text(x_txt, y_txt, tweaker_5, "dnctswye", COLOUR.weak, info_color)
    y_txt = y_txt + height

    local tweaker_6 = u8(WRAM.sprite_6_tweaker + slot)
    draw.over_text(x_txt, y_txt, tweaker_6, "wcdj5sDp", COLOUR.weak, info_color)
  end
end


-- A table of custom functions for special sprites
local special_sprite_property = {}
--[[
PROBLEMATIC ONES
  29  Koopa Kid
  54  Revolving door for climbing net, wrong hitbox area, not urgent
  5a  Turn block bridge, horizontal, hitbox only applies to central block and wrongly
  89  Layer 3 Smash, hitbox of generator outside
  9e  Ball 'n' Chain, hitbox only applies to central block, rotating ball
  a3  Rotating gray platform, wrong hitbox, rotating plataforms
--]]

special_sprite_property[0x1e] = function(slot) -- Lakitu
  if u8(WRAM.sprite_miscellaneous4 + slot) ~= 0 or
  u8(WRAM.sprite_miscellaneous12 + slot) ~= 0 then

    local OAM_index = 0xec
    local xoff = u8(0x304 + OAM_index) - 0x0c -- lots of unlisted WRAM
    local yoff = u8(0x305 + OAM_index) - 0x0c
    local width, height = 0x18 - 1, 0x18 - 1  -- instruction BCS

    draw.rectangle(xoff, yoff, width, height, COLOUR.awkward_hitbox, COLOUR.awkward_hitbox_bg)
    -- TODO: 0x7e and 0x80 are too important
    -- draw this point outside this function and add an option
    draw.pixel(s16(0x7e), s16(0x80), COLOUR.mario)
  end
end

special_sprite_property[0x3d] = function(slot) -- Rip Van Fish
  if u8(WRAM.sprite_miscellaneous1 + slot) == 0 then -- if sleeping
    local x_screen = Sprites_info[slot].x_screen
    local y_screen = Sprites_info[slot].y_screen
    local color = Sprites_info[slot].info_color
    local x1, y1, x2, y2 = -0x30, -0x30, 0x2e, 0x2e

    -- Draw central hitbox and 8 areas around due to overflow
    for horizontal = -1, 1 do
      local x = x_screen + 0x100*horizontal
      for vertical = -1, 1 do
        local y = y_screen + 0x100*vertical
        draw.box(x + x1, y + y1, x + x2, y + y2, color)
      end
    end

    Display.show_player_point_position = true -- Only Mario coordinates matter
  end
end

special_sprite_property[0x5f] = function(slot) -- Swinging brown platform (TODO fix it)
  --[[ TEST
  gui.text(0, 200, u8(0x4216))

  local px = u16(0x14b8)
  local py = u16(0x14ba)
  gui.text(0, 0, px.. ", ".. py, 'white', 'blue')
  local sx, sy = screen_coordinates(px, py, Camera_x, Camera_y)
  draw.rectangle(sx, sy, 2, 2)
  local table1 = s8(0x1504 + id) -- speed
  local table2 = u8(0x1510 + id) -- subpixle?
  local table3 = u8(0x151c + id)
  local table4 = u8(0x1528 + id) -- numero de voltas horario
  draw.text(0, 16, string.format("Tables: %4d, %4d.%x, %4d", table1, table3, table2>>4, table4))

  local is_up = table4%2 == 0 and 256 or 0
  -- test3
  platform_x = x + circle_values[256 - table3 + is_up][1]
  platform_y = y + circle_values[256 - table3 + is_up][2]

  sx, sy = screen_coordinates(platform_x, platform_y, Camera_x, Camera_y)
  --sx, sy = screen_coordinates(px, py, Camera_x, Camera_y)
  draw.rectangle(sx - 24, sy - 7, 64, 18, info_color, COLOUR.sprites_bg)
  draw.rectangle(sx, sy, 2, 2, info_color)  -- to test correctness
  draw.text(0, 32, "Platf. Calc: " .. platform_x .. ", " .. platform_y, "red", 0x40000000)

  -- test2
  local next_pos = (16*table3 + table2//16 + table1)//16
  local index = 256*256*256*table2 + 256*256*luap.signed16(table1, 8) + 256*table4 + table3--(next_pos + is_up)%512
  gui.text(0, 48, "Index: "..tostring(index), 'yellow', 'black')
  if Circle[index] then if Circle[index][1] ~= px - x then print("x erf", -px + x, -Circle[index][1]) end if Circle[index][2] ~= py - y then print"y erf" end end
  Circle[index] = Circle[index] or ({px - x, py - y})
  local count=0 ; for a,b in pairs(Circle) do count = count + 1  end
  gui.text(0, 400, count, "red", "brown")
  --]]

  local t = Sprites_info[slot]
  local x = t.x
  local x_screen = t.x_screen
  local y_screen = t.y_screen
  local xoff = t.hitbox_xoff
  local yoff = t.hitbox_yoff
  local sprite_width = t.hitbox_width
  local sprite_height = t.hitbox_height
  local color = t.info_color

  -- Powerup Incrementation helper
  local yoshi_right = 256*math.floor(x/256) - 58
  local yoshi_left  = yoshi_right + 32
  local x_text, y_text, height = draw.AR_x*(x_screen + xoff), draw.AR_y*(y_screen + yoff), BIZHAWK_FONT_HEIGHT

  if mouse_onregion(x_text, y_text, x_text + draw.AR_x*sprite_width, y_text + draw.AR_y*sprite_height) then
    local x_text, y_text = 0, 0
    gui.text(x_text, y_text, "Powerup Incrementation help", color, COLOUR.background)
    gui.text(x_text, y_text + height, "Yoshi must have: id = #4;", color, COLOUR.background)
    gui.text(x_text, y_text + 2*height, fmt("Yoshi x pos: (%s %d) or (%s %d)",
      LEFT_ARROW, yoshi_left, RIGHT_ARROW, yoshi_right), color, COLOUR.background)
  end
  --The status change happens when yoshi's id number is #4 and when (yoshi's x position) + Z mod 256 = 214,
  --where Z is 16 if yoshi is facing right, and -16 if facing left. More precisely, when (yoshi's x position + Z) mod 256 = 214,
  --the address 0x7E0015 + (yoshi's id number) will be added by 1.
  -- therefore: X_yoshi = 256*floor(x/256) + 32*yoshi_direction - 58
end

special_sprite_property[0x35] = function(slot) -- Yoshi
  local t = Sprites_info[slot]

  if not Yoshi_riding_flag and OPTIONS.display_sprite_hitbox and Sprite_hitbox[slot][t.number].sprite then
    draw.rectangle(t.x_screen + 4, t.y_screen + 20, 8, 8, COLOUR.yoshi)
  end
end

special_sprite_property[0x54] = function(slot) -- Revolving door for climbing net
  local t = Sprites_info[slot]

  -- draw custom hitbox for Mario
  if luap.inside_rectangle(Player_x, Player_y, t.x - 8, t.y - 24, t.x + 55, t.y + 55) then
    local extra_x, extra_y = screen_coordinates(Player_x, Player_y, Camera_x, Camera_y)
    draw.rectangle(t.x_screen - 8, t.y_screen - 8, 63, 63, COLOUR.very_weak)
    draw.rectangle(extra_x, extra_y, 0x10, 0x10, COLOUR.awkward_hitbox, COLOUR.awkward_hitbox_bg)
  end
end

special_sprite_property[0x62] = function(slot) -- Brown line-guided platform TODO: fix it
  local t = Sprites_info[slot]
  local xoff = t.hitbox_xoff - 24
  local yoff = t.hitbox_yoff - 8

  -- TODO: debug interaction for mario's image
  if OPTIONS.display_sprite_hitbox then
    draw.rectangle(t.x_screen + xoff, t.y_screen + yoff, t.hitbox_width, t.hitbox_height, t.info_color, t.background_color)
  end
end

special_sprite_property[0x63] = special_sprite_property[0x62] -- Brown/checkered line-guided platform

special_sprite_property[0x6b] = function(slot) -- Wall springboard (left wall)
  if not OPTIONS.display_sprite_hitbox then return end

  local t = Sprites_info[slot]
  local color = t.info_color

  -- HUD for the carry sprite cheat
  local xoff = t.hitbox_xoff
  local yoff = t.hitbox_yoff
  local x_screen = t.x_screen
  local y_screen = t.y_screen
  local sprite_width = t.hitbox_width
  local sprite_height = t.hitbox_height
  draw.rectangle(x_screen + xoff, y_screen + yoff, sprite_width, sprite_height, COLOUR.sprites_faint)

  -- Mario's image
  local xmario, ymario = u16(0x7e), u16(0x80)
  if math.floor(xmario/256) == 0 and math.floor(ymario/256) == 0 then
    local y1 = 0x08 + 0x08 + (Yoshi_riding_flag and 0x10 or 0)
    local y2 = 0x21 + (Yoshi_riding_flag and 0x10 or 0) + (Player_powerup == 0 and 2 or 0)
    draw.box(xmario - 6 + 0x8, ymario + y1,xmario + 0x0d, ymario + y2, COLOUR.mario_oam_hitbox, COLOUR.interaction_bg)
  end

  -- Spheres hitbox
  if t.x_offscreen == 0 and t.y_offscreen == 0 then
    local OAM_index = u8(WRAM.sprite_OAM_index + slot)
    for ball = 0, 4 do
      local x = u8(0x300 + OAM_index + 4*ball)
      local y = u8(0x301 + OAM_index + 4*ball)

      draw.rectangle(x, y, 8, 8, color, COLOUR.sprites_bg)
      draw.text(draw.AR_x*(x + 2), draw.AR_y*(y + 2), ball, COLOUR.text)
    end
  end
end

special_sprite_property[0x6c] = special_sprite_property[0x6b] -- Wall springboard (right wall)

special_sprite_property[0x6f] = function(slot) -- Dino-Torch: display flame hitbox
  local t = Sprites_info[slot]

  if OPTIONS.display_sprite_hitbox then
    if u8(WRAM.sprite_miscellaneous4 + slot) == 0 then  -- if flame is hurting
      local active = (Real_frame - slot)%4 == 0 and COLOUR.sprites_bg or 0
      local vertical_flame = u8(WRAM.sprite_miscellaneous15 + slot) == 3
      local xoff, yoff, width, height

      if vertical_flame then
        xoff, yoff, width, height = 0x02, -0x24, 0x0c, 0x24
      else
        local facing_right = u8(WRAM.sprite_miscellaneous12 + slot) == 0
        xoff = facing_right and 0x10 or -0x24
        yoff = 0x02
        width, height = 0x24, 0x0c
      end

      draw.rectangle(t.x_screen + xoff, t.y_screen + yoff, width, height, COLOUR.awkward_hitbox, active)
    end
  end
end

special_sprite_property[0x7b] = function(slot) -- Goal Tape
  local t = Sprites_info[slot]
  local y_screen = Sprites_info[slot].y_screen
  local info_color = Sprites_info[slot].info_color

  draw.Text_opacity = 0.8
  draw.Bg_opacity = 0.6

  -- This draws the effective area of a goal tape
  local x_effective = 256*u8(WRAM.sprite_miscellaneous4 + slot) + u8(WRAM.sprite_miscellaneous1 + slot)
  local y_low = 256*u8(WRAM.sprite_miscellaneous6 + slot) + u8(WRAM.sprite_miscellaneous5 + slot)
  local _, y_high = screen_coordinates(0, 0, Camera_x, Camera_y)
  local x_s, y_s = screen_coordinates(x_effective, y_low, Camera_x, Camera_y)

  if OPTIONS.display_sprite_hitbox then
    draw.box(x_s, y_high, x_s + 15, y_s, info_color, COLOUR.goal_tape_bg)
  end
  draw.text(draw.AR_x*x_s, draw.AR_y*t.y_screen, fmt("Touch=%4d.0->%4d.f", x_effective, x_effective + 15), info_color, false, false)
end

special_sprite_property[0x86] = function(slot) -- Wiggler (segments)
  local OAM_index = u8(WRAM.sprite_OAM_index + slot)
  for seg = 0, 4 do
    local xoff = u8(0x304 + OAM_index) - 0x0a -- lots of unlisted WRAM
    local yoff = u8(0x305 + OAM_index) - 0x1b
    if Yoshi_riding_flag then yoff = yoff - 0x10 end
    local width, height = 0x17 - 1, 0x17
    local xend, yend = xoff + width, yoff + height

    -- TODO: fix draw.rectangle to display the exact dimensions; then remove the -1
    --draw.rectangle(xoff, yoff, width - 1, height - 1, COLOUR.awkward_hitbox, COLOUR.awkward_hitbox_bg)
    draw.box(xoff, yoff, xend, yend, COLOUR.awkward_hitbox, COLOUR.awkward_hitbox_bg)

    OAM_index = OAM_index + 4
  end

  draw.pixel(s16(0x7e), s16(0x80), COLOUR.mario, 0x80000000)
end

special_sprite_property[0xa9] = function(slot) -- Reznor
  local reznor
  local color
  for index = 0, SMW.sprite_max - 1 do
    reznor = u8(WRAM.sprite_miscellaneous4 + index)
    if index >= 4 and index <= 7 then
      color = COLOUR.warning
    else
      color = color_weak
    end
    draw.text(3*BIZHAWK_FONT_WIDTH*index, draw.Buffer_height, fmt("%.2x", reznor), color, true, false, 0.0, 1.0)
  end
end

special_sprite_property[0x91] = function(slot) -- Chargin' Chuck
  if Sprites_info[slot].status ~= 0x08 then return end

  -- > spriteYLow - addr1 <= MarioYLow < spriteYLow + addr2 - addr1
  local routine_pointer = u8(WRAM.sprite_miscellaneous1 + slot)
  routine_pointer = math.floor(bit.band(routine_pointer, 0xff)/2)
  local facing_right = u8(WRAM.sprite_miscellaneous12 + slot) == 0

  local x1, x2, y1, yoff, height
  local color, bg

  if routine_pointer == 0 then -- looking
    local active = bit.band(u8(WRAM.sprite_miscellaneous7 + slot), 0x0f) == 0
    color = COLOUR.sprite_vision_passive
    bg = active and COLOUR.sprite_vision_active_bg or 0
    yoff = -0x28
    height = 0x50 - 1
    x1 = 0
    x2 = draw.Buffer_width - 1

  elseif routine_pointer == 2 then -- following
    color = COLOUR.sprite_vision_active
    bg = COLOUR.sprite_vision_active_bg
    yoff = -0x30
    height = 0x60 - 1
    x1 = Sprites_info[slot].x_screen + (facing_right and 1 or -1)
    x2 = facing_right and draw.Buffer_width - 1 or 0

  else -- inactive
    color = COLOUR.sprite_vision_passive
    bg = 0
    yoff = -0x28
    height = 0x50 - 1
    x1 = Sprites_info[slot].x_screen + (facing_right and 1 or -1)
    x2 = facing_right and draw.Buffer_width - 1 or 0
  end

  y1 = Sprites_info[slot].y_screen + yoff
  draw.box(x1, y1, x2, y1 + height, color, bg)

  y1 = y1 + 0x100 -- draw it again, 0x100 pixels below
  draw.box(x1, y1, x2, y1 + height, color, bg)
  Display.show_player_point_position = true
end

special_sprite_property[0x92] = function(slot) -- Splittin' Chuck
  if Sprites_info[slot].status ~= 0x08 then return end
  if u8(WRAM.sprite_miscellaneous1 + slot) ~= 5 then return end

  local xoff = -0x50
  local width = 0xa0 - 1

  local t = Sprites_info[slot]
  for i = -1, 1 do
    draw.rectangle(t.x_screen + xoff + i*0x100, -draw.Border_top, width,
      draw.Buffer_height + draw.Border_bottom, t.info_color, 0x10ffff00)
  end
  Display.show_player_point_position = true
end

special_sprite_property[0xa0] = function(slot) -- Bowser
  local height = BIZHAWK_FONT_HEIGHT
  local y_text = draw.Buffer_height - 10*height
  for index = 0, 9 do
    local value = u8(WRAM.bowser_attack_timers + index)
    draw.text(draw.Buffer_width + draw.Border_right, y_text + index*height,
      fmt("%$2X = %3d", value, value), Sprites_info[slot].info_color, true)
  end
end

special_sprite_property[0xae] = function(slot) -- Fishin' Boo
  if OPTIONS.display_sprite_hitbox then
    local x_screen = Sprites_info[slot].x_screen
    local y_screen = Sprites_info[slot].y_screen
    local direction = u8(WRAM.sprite_miscellaneous12 + slot)
    local aux = u8(WRAM.sprite_miscellaneous15 + slot)
    local index = 2*direction + aux
    local offsets = {[0] = 0x1a, 0x14, -0x12, -0x08}
    local xoff = offsets[index]

    if not xoff then  -- possible exception
      xoff = 0
      draw.text(draw.AR_x*x_screen, draw.AR_y*(y_screen + 0x47),
        fmt("Glitched offset! dir:%.2x, aux:%.2x", direction, aux)
      )
    end

    draw.rectangle(x_screen + xoff, y_screen + 0x47, 4, 4, COLOUR.warning2, COLOUR.awkward_hitbox_bg)
  end
end


local function sprite_info(id, counter, table_position)
  draw.Text_opacity = 1.0

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
  local underwater = t.underwater
  local x_offscreen = t.x_offscreen
  local y_offscreen = t.y_offscreen
  local x_screen = t.x_screen
  local y_screen = t.y_screen
  local xpt_left = t.xpt_left
  local xpt_right = t.xpt_right
  local ypt_up = t.ypt_up
  local ypt_down = t.ypt_down
  local xoff = t.hitbox_xoff
  local yoff = t.hitbox_yoff
  local sprite_width = t.hitbox_width
  local sprite_height = t.hitbox_height

  -- HUD elements
  local oscillation_flag = t.oscillation_flag
  local info_color = t.info_color
  local color_background = t.background_color

  draw_sprite_hitbox(id)

  -- Special sprites analysis:
  local fn = special_sprite_property[number]
  if fn then fn(id) end

  --[==[-**********************************************
  -- Special sprites analysis:

  --[[
  PROBLEMATIC ONES
    29  Koopa Kid
    54  Revolving door for climbing net, wrong hitbox area, not urgent
    5a  Turn block bridge, horizontal, hitbox only applies to central block and wrongly
    86  Wiggler, the second part of the sprite, that hurts Mario even if he's on Yoshi, doesn't appear
    89  Layer 3 Smash, hitbox of generator outside
    9e  Ball 'n' Chain, hitbox only applies to central block, rotating ball
    a3  Rotating gray platform, wrong hitbox, rotating plataforms
  ]]

  if number == 0x3d then  -- Rip Van Fish
    if u8(WRAM.sprite_miscellaneous1 + id) == 0 then -- if sleeping
      local x1, y1, x2, y2 = -0x30, -0x30, 0x2e, 0x2e

      -- Draw central hitbox and 8 areas around due to overflow
      for horizontal = -1, 1 do
        local x = x_screen + 0x100*horizontal
        for vertical = -1, 1 do
          local y = y_screen + 0x100*vertical
          draw.box(x + x1, y + y1, x + x2, y + y2, info_color, 0)
        end
      end

      Display.show_player_point_position = true -- Only Mario coordinates matter
    end
  end

  if number == 0x5f then  -- Swinging brown platform (fix it)

    -- Powerup Incrementation helper
    local yoshi_right = 256*floor(x/256) - 58
    local yoshi_left  = yoshi_right + 32
    local x_text, y_text, height = draw.AR_x*(x_screen + xoff), draw.AR_y*(y_screen + yoff), BIZHAWK_FONT_HEIGHT

    if mouse_onregion(x_text, y_text, x_text + draw.AR_x*sprite_width, y_text + draw.AR_y*sprite_height) then
      local x_text, y_text = 0, height
      draw.text(x_text, y_text, "Powerup Incrementation help", info_color, COLOUR.background)
      draw.text(x_text, y_text + height, "Yoshi must have: id = #4;", info_color, COLOUR.background)
      draw.text(x_text, y_text + 2*height, ("Yoshi x pos: (%s %d) or (%s %d)")
      :format(LEFT_ARROW, yoshi_left, RIGHT_ARROW, yoshi_right), info_color, COLOUR.background)
    end
    --The status change happens when yoshi's id number is #4 and when (yoshi's x position) + Z mod 256 = 214,
    --where Z is 16 if yoshi is facing right, and -16 if facing left. More precisely, when (yoshi's x position + Z) mod 256 = 214,
    --the address 0x7E0015 + (yoshi's id number) will be added by 1.
    -- therefore: X_yoshi = 256*floor(x/256) + 32*yoshi_direction - 58
  end

  if number == 0x35 then  -- Yoshi
    if not Yoshi_riding_flag and OPTIONS.display_sprite_hitbox and Sprite_hitbox[id][number].sprite then
      draw.rectangle(x_screen + 4, y_screen + 20, 8, 8, COLOUR.yoshi)
    end
  end

  if number == 0x54 then -- Revolving door for climbing net
    -- draw custom hitbox for Mario
    local player_x = s16(WRAM.x)  -- TODO: use external Player_x like in lsnes
    local player_y = s16(WRAM.y)

    if luap.inside_rectangle(player_x, player_y, x - 8, y - 24, x + 55, y + 55) then
      local extra_x, extra_y = screen_coordinates(player_x, player_y, Camera_x, Camera_y)
      draw.rectangle(x_screen - 8, y_screen - 8, 63, 63, COLOUR.very_weak, 0)
      draw.rectangle(extra_x, extra_y, 0x10, 0x10, COLOUR.awkward_hitbox, COLOUR.awkward_hitbox_bg)
    end
  end

  if number == 0x62 or number == 0x63 then  -- Brown line-guided platform & Brown/checkered line-guided platform
      xoff = xoff - 24
      yoff = yoff - 8
      -- for some reason, the actual base is 1 pixel below when Mario is small
      if OPTIONS.display_sprite_hitbox then
        draw.rectangle(x_screen + xoff, y_screen + yoff, sprite_width, sprite_height, info_color, color_background)
      end
  end

  if number == 0x6b then  -- Wall springboard (left wall)
    xoff = xoff - 8
    sprite_height = sprite_height + 1  -- for some reason, small Mario gets a bigger hitbox

    if OPTIONS.display_sprite_hitbox then
      draw.rectangle(x_screen + xoff, y_screen + yoff, sprite_width, sprite_height, info_color, color_background)
      draw.line(x_screen + xoff, y_screen + yoff + 3, x_screen + xoff + sprite_width, y_screen + yoff + 3, info_color)
    end
  end

  if number == 0x6c then  -- Wall springboard (right wall)
    xoff = xoff - 31
    sprite_height = sprite_height + 1

    if OPTIONS.display_sprite_hitbox then
      draw.rectangle(x_screen + xoff, y_screen + yoff, sprite_width, sprite_height, info_color, color_background)
      draw.line(x_screen + xoff, y_screen + yoff + 3, x_screen + xoff + sprite_width, y_screen + yoff + 3, info_color)
    end
  end

  if number == 0x7b then  -- Goal Tape

    draw.Text_opacity = 0.8

    -- This draws the effective area of a goal tape
    local x_effective = 256*u8(WRAM.sprite_miscellaneous4 + id) + u8(WRAM.sprite_miscellaneous1 + id)
    local y_low = 256*u8(WRAM.sprite_miscellaneous6 + id) + u8(WRAM.sprite_miscellaneous5 + id)
    local _, y_high = screen_coordinates(0, 0, Camera_x, Camera_y)
    local x_s, y_s = screen_coordinates(x_effective, y_low, Camera_x, Camera_y)

    if OPTIONS.display_sprite_hitbox then
      draw.box(x_s, y_high, x_s + 15, y_s, info_color, COLOUR.goal_tape_bg)
    end
    draw.text(draw.AR_x*x_s, draw.AR_y*y_screen, fmt("Touch=%4d.0->%4d.f", x_effective, x_effective + 15), info_color, false, false)

    draw.Text_opacity = 1.0
    draw.Bg_opacity = 1.0

  elseif number == 0xa9 then  -- Reznor

    local reznor
    local color
    for index = 0, SMW.sprite_max - 1 do
      reznor = u8(WRAM.sprite_miscellaneous4 + index)
      if index >= 4 and index <= 7 then
        color = COLOUR.warning
      else
        color = color_weak
      end
      draw.text(3*BIZHAWK_FONT_WIDTH*index, draw.Buffer_height, fmt("%.2x", reznor), color, true, false, 0.0, 1.0)
    end

  elseif number == 0xa0 then  -- Bowser

    local height = BIZHAWK_FONT_HEIGHT
    local y_text = draw.Screen_height - 10*height
    local address = 0x14b0  -- unlisted WRAM
    for index = 0, 9 do
      local value = u8(address + index)
      draw.text(draw.Buffer_width + draw.Border_right, y_text + index*height, fmt("%2x = %3d", value, value), info_color, true)
    end

  end
  --]==]

  ---**********************************************
  -- Print those informations next to the sprite
  draw.Text_opacity = 1.0
  draw.Bg_opacity = 1.0

  if x_offscreen ~= 0 or y_offscreen ~= 0 then
    draw.Text_opacity = 0.6
  end

  local contact_str = contact_mario == 0 and "" or " " .. contact_mario

  local sprite_middle = t.sprite_middle
  local sprite_top = t.sprite_top
  if OPTIONS.display_sprite_info then
    draw.text(draw.AR_x*sprite_middle, draw.AR_y*sprite_top, fmt("#%.2d%s", id, contact_str), info_color, true, false, 0.5, 1.0)
    if Player_powerup == 2 then
      local contact_cape = u8(WRAM.sprite_disable_cape + id)
      if contact_cape ~= 0 then
        draw.text(draw.AR_x*sprite_middle, draw.AR_y*sprite_top - 2*BIZHAWK_FONT_HEIGHT, contact_cape, COLOUR.cape, true)
      end
    end
  end

  -- Sprite tweakers info
  sprite_tweaker_editor(id)

  -- The sprite table:
  if OPTIONS.display_sprite_info then
    local x_speed_water = ""
    if underwater ~= 0 then  -- if sprite is underwater
      local correction = math.floor(3*math.floor(x_speed/2)/2)
      x_speed_water = string.format("%+.2d=%+.2d", correction - x_speed, correction)
    end
    local sprite_str = fmt("#%02d %02x %s%d.%1x(%+.2d%s) %d.%1x(%+.2d)",
            id, number, t.table_special_info, x, math.floor(x_sub/16), x_speed, x_speed_water, y, math.floor(y_sub/16), y_speed)

    draw.text(draw.Buffer_width + draw.Border_right, table_position + counter*BIZHAWK_FONT_HEIGHT, sprite_str, info_color, true)
  end

  -- Miscellaneous sprite table
  if OPTIONS.display_miscellaneous_sprite_table then
    local x_mis, y_mis = - draw.Border_left, draw.AR_y*144 + counter*BIZHAWK_FONT_HEIGHT

    local t = OPTIONS.miscellaneous_sprite_table_number
    local misc, text = nil, fmt("#%.2d", id)
    for num = 1, 19 do
      misc = t[num] and u8(WRAM["sprite_miscellaneous" .. num] + id) or false
      text = misc and fmt("%s %3d", text, misc) or text
    end

    draw.text(x_mis, y_mis, text, info_color)
  end

  return 1
end


local function sprites()
  if not OPTIONS.display_sprite_info then return end

  local counter = 0
  local table_position = draw.AR_y*48
  for id = 0, SMW.sprite_max - 1 do
    scan_sprite_info(Sprites_info, id)
    counter = counter + sprite_info(id, counter, table_position)
  end

  -- Font
  draw.Text_opacity = 0.6

  local swap_slot = u8(WRAM.sprite_swap_slot)
  local smh = u8(WRAM.sprite_memory_header)
  draw.text(draw.Buffer_width + draw.Border_right, table_position - 2*BIZHAWK_FONT_HEIGHT, fmt("spr:%.2d", counter), COLOUR.weak, true)
  draw.text(draw.Buffer_width + draw.Border_right, table_position - BIZHAWK_FONT_HEIGHT, fmt("1st div: %d. Swap: %d",
                                    SPRITE_MEMORY_MAX[smh] or 0, swap_slot), COLOUR.weak, true)
  --
  -- Miscellaneous sprite table: index
  if OPTIONS.display_miscellaneous_sprite_table then
    local t = OPTIONS.miscellaneous_sprite_table_number
    local text = "Tab"
    for num = 1, 19 do
      text = t[num] and fmt("%s %3d", text, num) or text
    end

    draw.text(- draw.Border_left, draw.AR_y*144 - BIZHAWK_FONT_HEIGHT, text, info_color)
  end
end


local function sprite_level_info()
  if not OPTIONS.display_sprite_data and not OPTIONS.display_sprite_load_status then return end

  draw.Text_opacity = 0.5

  -- Sprite load status enviroment
  local indexes = {}
  for id = 0, 11 do
    local sprite_status = u8(WRAM.sprite_status + id)

    if sprite_status ~= 0 then
      local index = u8(WRAM.sprite_index_to_level + id)
      indexes[index] = true
    end
  end
  local status_table = mainmemory.readbyterange(WRAM.sprite_load_status_table, 0x80)

  local x_origin = 0
  local y_origin = OPTIONS.top_gap + draw.Buffer_height - 4*11
  local x, y = x_origin, y_origin
  local w, h = 9, 11

  -- Sprite data enviroment
  local pointer = u24(WRAM.sprite_data_pointer)

  -- Level scan
  local is_vertical = read_screens() == "Vertical"
  
  local sprite_counter = 0
  for id = 0, 0x80 - 1 do
    -- Sprite data
    local byte_1 = memory.readbyte(pointer + 1 + id*3, "System Bus")
    if byte_1==0xff then break end -- end of sprite data for this level
    local byte_2 = memory.readbyte(pointer + 2 + id*3, "System Bus")
    local byte_3 = memory.readbyte(pointer + 3 + id*3, "System Bus")

    local sxpos, sypos
    if is_vertical then -- vertical
      sxpos = bit.band(byte_1, 0xf0) + 256*bit.band(byte_1, 0x0d)
      sypos = bit.band(byte_2, 0xf0) + 256*(bit.band(byte_2, 0x0f) + 8*bit.band(byte_1, 0x02))
    else -- horizontal
      sxpos = bit.band(byte_2, 0xf0) + 256*(bit.band(byte_2, 0x0f) + 8*bit.band(byte_1, 0x02))
      sypos = bit.band(byte_1, 0xf0) + 256*bit.band(byte_1, 0x0d)
    end

    local status = status_table[id]
    local color = (status == 0 and COLOUR.disabled) or (status == 1 and COLOUR.text) or 0xffFFFF00
    if status ~= 0 and not indexes[id] then color = COLOUR.warning end

    if OPTIONS.display_sprite_data then
      if sxpos - Camera_x + 16 > -OPTIONS.left_gap and sxpos - Camera_x - 16 < 256 + OPTIONS.right_gap and -- to avoid printing the whole level data
         sypos - Camera_y + 16 > -OPTIONS.top_gap and sypos - Camera_y - 16 < 224 + OPTIONS.bottom_gap then

        draw.text((sxpos - Camera_x + 8)*draw.AR_x, (sypos - Camera_y - 2)*draw.AR_y - BIZHAWK_FONT_HEIGHT, fmt("$%02X", id), color, false, false, 0.5)
        if color ~= COLOUR.text then -- don't display sprite ID if sprite is spawned
          draw.text((sxpos - Camera_x + 8)*draw.AR_x, (sypos - Camera_y + 4)*draw.AR_y, fmt("$%02X", byte_3), color, false, false, 0.5)
        end
        
        draw.rectangle(sxpos - Camera_x, sypos - Camera_y, 15, 15, color)
        gui.crosshair(sxpos - Camera_x + OPTIONS.left_gap, sypos - Camera_y + OPTIONS.top_gap, 3, COLOUR.yoshi)
      end
    end

    -- Sprite load status
    if OPTIONS.display_sprite_load_status then
      gui.drawRectangle(x, y, w-1, h-1, color, 0x80000000)
      gui.pixelText(x+2, y+2, fmt("%X ", status), color, 0)
      x = x + w
      if id%16 == 15 then
        x = x_origin
        y = y + h
      end
    end

    sprite_counter = sprite_counter + 1
  end

  draw.Text_opacity = 1.0
  if OPTIONS.display_sprite_load_status then
    draw.text(-draw.Border_left + 1, (y_origin-OPTIONS.top_gap)*draw.AR_y - 20, "Sprite load status", COLOUR.text)
    draw.text(-draw.Border_left - 1, (y-OPTIONS.top_gap)*draw.AR_y + 24, fmt("($%02X sprites)", sprite_counter), COLOUR.text)
  end
end


special_sprite_property.yoshi_tongue_offset = function(xoff, tongue_length)
  if (xoff % 0x100) < 0x80 then
    xoff = xoff + tongue_length
  else
    xoff = (xoff + bit.bxor(tongue_length, 0xff) % 0x100 + 1) % 0x100
    if (xoff % 0x100) >= 0x80 then
      xoff = xoff - 0x100
    end
  end

  return xoff
end


special_sprite_property.yoshi_tongue_time_predictor = function(len, timer, wait, out, eat_id)
  local info, color
  if wait > 9 then info = wait - 9; color = COLOUR.tongue_line  -- not ready yet

  elseif out == 1 then info = 17 + wait; color = COLOUR.text  -- tongue going out

  elseif out == 2 then  -- at the max or tongue going back
    info = math.max(wait, timer) + math.floor((len + 7)/4) - (len ~= 0 and 1 or 0)
    color = eat_id == SMW.null_sprite_id and COLOUR.text or COLOUR.warning

  elseif out == 0 then info = 0; color = COLOUR.text  -- tongue in

  else info = timer + 1; color = COLOUR.tongue_line -- item was just spat out
  end

  return info, color
end


local function yoshi()
  if not OPTIONS.display_yoshi_info then return end

  -- Font
  draw.Text_opacity = 1.0
  draw.Bg_opacity = 1.0
  local x_text = 0
  local y_text = draw.AR_y*88

  local yoshi_id = get_yoshi_id()
  if yoshi_id ~= nil then
    local tongue_len = u8(WRAM.sprite_miscellaneous4 + yoshi_id)
    local tongue_timer = u8(WRAM.sprite_miscellaneous9 + yoshi_id)
    local yoshi_direction = u8(WRAM.sprite_miscellaneous12 + yoshi_id)
    local tongue_out = u8(WRAM.sprite_miscellaneous13 + yoshi_id)
    local turn_around = u8(WRAM.sprite_miscellaneous14 + yoshi_id)
    local tile_index = u8(WRAM.sprite_miscellaneous15 + yoshi_id)
    local eat_id = u8(WRAM.sprite_miscellaneous16 + yoshi_id)
    local mount_invisibility = u8(WRAM.sprite_miscellaneous18 + yoshi_id)
    local eat_type = u8(WRAM.sprite_number + eat_id)
    local tongue_wait = u8(WRAM.sprite_tongue_wait)
    local tongue_height = u8(WRAM.yoshi_tile_pos)
    local yoshi_in_pipe = u8(WRAM.yoshi_in_pipe)

    local eat_type_str = eat_id == SMW.null_sprite_id and "-" or string.format("%02x", eat_type)
    local eat_id_str = eat_id == SMW.null_sprite_id and "-" or string.format("#%02d", eat_id)

    -- Yoshi's direction and turn around
    local direction_symbol
    if yoshi_direction == 0 then direction_symbol = RIGHT_ARROW else direction_symbol = LEFT_ARROW end

    draw.text(x_text, y_text, fmt("Yoshi %s %d", direction_symbol, turn_around), COLOUR.yoshi)
    local h = BIZHAWK_FONT_HEIGHT

    draw.text(x_text, y_text + h, fmt("(%0s, %0s) %02d, %d, %d",
              eat_id_str, eat_type_str, tongue_len, tongue_wait, tongue_timer), COLOUR.yoshi)
    ;

    -- more WRAM values
    local yoshi_x = 256*s8(WRAM.sprite_x_high + yoshi_id) + u8(WRAM.sprite_x_low + yoshi_id)
    local yoshi_y = 256*s8(WRAM.sprite_y_high + yoshi_id) + u8(WRAM.sprite_y_low + yoshi_id)
    local x_screen, y_screen = screen_coordinates(yoshi_x, yoshi_y, Camera_x, Camera_y)

    -- invisibility timer
    if mount_invisibility ~= 0 then
      draw.text(draw.AR_x*(x_screen + 4), draw.AR_x*(y_screen - 12), mount_invisibility, COLOUR.yoshi)
    end

    -- Tongue hitbox and timer
    if tongue_wait ~= 0 or tongue_out ~=0 or tongue_height == 0x89 then  -- if tongue is out or appearing
      -- Color
      local tongue_line
      if tongue_wait <= 9 then
        tongue_line = COLOUR.tongue_line
      else tongue_line = COLOUR.tongue_bg
      end

      -- Tongue Hitbox
      local actual_index = tile_index
      if yoshi_direction == 0 then actual_index = tile_index + 8 end
      actual_index = yoshi_in_pipe ~= 0 and u8(0x0d) or smw.YOSHI_TONGUE_X_OFFSETS[actual_index] or 0

      local xoff = special_sprite_property.yoshi_tongue_offset(actual_index, tongue_len)

       -- tile_index changes midframe, according to yoshi_in_pipe address
      local yoff = yoshi_in_pipe ~= 0 and 3 or smw.YOSHI_TONGUE_Y_OFFSETS[tile_index] or 0
      yoff = yoff + 2
      draw.rectangle(x_screen + xoff, y_screen + yoff, 8, 4, tongue_line, COLOUR.tongue_bg)
      draw.pixel(x_screen + xoff, y_screen + yoff, COLOUR.text, COLOUR.tongue_bg) -- hitbox point vs berry tile

      -- glitched hitbox for Layer Switch Glitch
      if yoshi_in_pipe ~= 0 then
        local xoff = special_sprite_property.yoshi_tongue_offset(0x40, tongue_len) -- from ROM
        draw.rectangle(x_screen + xoff, y_screen + yoff, 8, 4, 0x80ffffff, 0x40000000)

        draw.text(x_text, y_text + 2*h, fmt("$1a: %.4x $1c: %.4x", u16(WRAM.layer1_x_mirror), u16(WRAM.layer1_y_mirror)), COLOUR.yoshi)
        draw.text(x_text, y_text + 3*h, fmt("$4d: %.4x $4f: %.4x", u16(WRAM.layer1_VRAM_left_up), u16(WRAM.layer1_VRAM_right_down)), COLOUR.yoshi)
      end

      -- tongue out: time predictor
      local info, color =
      special_sprite_property.yoshi_tongue_time_predictor(tongue_len, tongue_timer, tongue_wait, tongue_out, eat_id)
      draw.text(draw.AR_x*(x_screen + xoff + 4), draw.AR_y*(y_screen + yoff + 5), info, color, false, false, 0.5)
    end
  end
end


local function show_counters()
  if not OPTIONS.display_counters then
    return
  end

  -- Font
  draw.Text_opacity = 1.0
  draw.Bg_opacity = 1.0
  local height = BIZHAWK_FONT_HEIGHT
  local text_counter = 0

  local pipe_entrance_timer = u8(WRAM.pipe_entrance_timer)
  local multicoin_block_timer = u8(WRAM.multicoin_block_timer)
  local gray_pow_timer = u8(WRAM.gray_pow_timer)
  local blue_pow_timer = u8(WRAM.blue_pow_timer)
  local dircoin_timer = u8(WRAM.dircoin_timer)
  local pballoon_timer = u8(WRAM.pballoon_timer)
  local star_timer = u8(WRAM.star_timer)
  local invisibility_timer = u8(WRAM.invisibility_timer)
  local animation_timer = u8(WRAM.animation_timer)
  local fireflower_timer = u8(WRAM.fireflower_timer)
  local yoshi_timer = u8(WRAM.yoshi_timer)
  local swallow_timer = u8(WRAM.swallow_timer)
  local lakitu_timer = u8(WRAM.lakitu_timer)
  local score_incrementing = u8(WRAM.score_incrementing)
  local end_level_timer = u8(WRAM.end_level_timer)
  local game_intro_timer = u8(0x1df5) -- unlisted WRAM

  local display_counter = function(label, value, default, mult, frame, color)
    if value == default then return end
    text_counter = text_counter + 1
    local color = color or COLOUR.text

    draw.text(- draw.Border_left, draw.AR_y*102 + (text_counter * height), fmt("%s: %d", label, (value * mult) - frame), color)
  end

  if Player_animation_trigger == 5 or Player_animation_trigger == 6 then
    display_counter("Pipe", pipe_entrance_timer, -1, 1, 0, COLOUR.counter_pipe)
  end
  display_counter("Multi Coin", multicoin_block_timer, 0, 1, 0, COLOUR.counter_multicoin)
  display_counter("Pow", gray_pow_timer, 0, 4, Effective_frame % 4, COLOUR.counter_gray_pow)
  display_counter("Pow", blue_pow_timer, 0, 4, Effective_frame % 4, COLOUR.counter_blue_pow)
  display_counter("Dir Coin", dircoin_timer, 0, 4, Real_frame % 4, COLOUR.counter_dircoin)
  display_counter("P-Balloon", pballoon_timer, 0, 4, Real_frame % 4, COLOUR.counter_pballoon)
  display_counter("Star", star_timer, 0, 4, (Effective_frame - 1) % 4, COLOUR.counter_star)
  display_counter("Invisibility", invisibility_timer, 0, 1, 0)
  display_counter("Fireflower", fireflower_timer, 0, 1, 0, COLOUR.counter_fireflower)
  display_counter("Yoshi", yoshi_timer, 0, 1, 0, COLOUR.yoshi)
  display_counter("Swallow", swallow_timer, 0, 4, (Effective_frame - 1) % 4, COLOUR.yoshi)
  display_counter("Lakitu", lakitu_timer, 0, 4, Effective_frame % 4)
  display_counter("End Level", end_level_timer, 0, 2, (Real_frame - 1) % 2)
  display_counter("Score Incrementing", score_incrementing, 0x50, 1, 0)
  display_counter("Intro", game_intro_timer, 0, 4, Real_frame % 4)  -- TODO: check whether it appears only during the intro level

  if Lock_animation_flag ~= 0 then display_counter("Animation", animation_timer, 0, 1, 0) end  -- shows when player is getting hurt or dying

end


-- Main function to run inside a level
local function level_mode()
  if SMW.game_mode_fade_to_level <= Game_mode and Game_mode <= SMW.game_mode_level then

    -- Draws/Erases the tiles if user clicked
    draw_layer1_tiles(Camera_x, Camera_y)

    draw_layer2_tiles()

    draw_boundaries()

    sprite_level_info()

    sprites()

    extended_sprites()

    cluster_sprites()

    minor_extended_sprites()

    bounce_sprite_info()

    level_info()

    player()

    yoshi()

    show_counters()

    predict_block_duplications()

    -- Draws/Erases the hitbox for objects
    if User_input.mouse_inwindow then
      select_object(User_input.xmouse, User_input.ymouse, Camera_x, Camera_y)
    end

  end
end


local function overworld_mode()
  if Game_mode ~= SMW.game_mode_overworld then return end
  if not OPTIONS.display_overworld_info then return end

  -- Font
  draw.Text_opacity = 1.0
  draw.Bg_opacity = 1.0

  local height = BIZHAWK_FONT_HEIGHT
  local y_text = BIZHAWK_FONT_HEIGHT

  -- Real frame modulo 8
  local real_frame_8 = Real_frame%8
  draw.text(draw.Buffer_width + draw.Border_right, y_text, fmt("Real Frame = %3d = %d(mod 8)", Real_frame, real_frame_8), true)

  -- Star Road info
  local star_speed = u8(WRAM.star_road_speed)
  local star_timer = u8(WRAM.star_road_timer)
  y_text = y_text + height
  draw.text(draw.Buffer_width + draw.Border_right, y_text, fmt("Star Road(%x %x)", star_speed, star_timer), COLOUR.cape, true)

  -- Player's position
  local offset = 0
  if Current_character == "Luigi" then offset = 4 end

  local OW_x = s16(WRAM.OW_x + offset)
  local OW_y = s16(WRAM.OW_y + offset)
  draw.text(-draw.Border_left, y_text, fmt("Pos(%d, %d)", OW_x, OW_y), true)

  -- Exit counter (events tiggered)
  local exit_counter = u8(WRAM.exit_counter)
  y_text = y_text + 2*height
  draw.text(-draw.Border_left, y_text, fmt("Exits: %d", exit_counter), true)

  -- Event table
  if OPTIONS.display_event_table then
    for byte_off = 0, 14 do
    local event_flags = u8(WRAM.event_flags + byte_off)
    for i = 0, 7 do
      local colour = COLOUR.disabled
      if bit.test(event_flags, i) then colour = COLOUR.yoshi end
      draw.rectangle(-draw.Left_gap + (7-i)*13, y_text + byte_off*11 - 16, 12, 10, colour)
      gui.pixelText(0 + (7-i)*13 + 2, y_text + byte_off*11 + 6, fmt("%02X", byte_off*8 + (7-i)), colour)
    end
    end
  end

end


local function left_click()
  -- Call options menu if the form is closed
  if Options_form.is_form_closed and mouse_onregion(120*draw.AR_x, 0, 120*draw.AR_x + 4*BIZHAWK_FONT_WIDTH, BIZHAWK_FONT_HEIGHT) then -- bizhawk
    Options_form.create_window()
    return
  end

  -- Drag and drop sprites
  if Cheat.allow_cheats then
    local id = select_object(User_input.xmouse, User_input.ymouse, Camera_x, Camera_y)
    if type(id) == "number" and id >= 0 and id < SMW.sprite_max then
      Cheat.dragging_sprite_id = id
      Cheat.is_dragging_sprite = true
      return
    end
  end

  -- Layer 1 tiles
  local x_mouse, y_mouse = game_coordinates(User_input.xmouse, User_input.ymouse, Camera_x, Camera_y)
  x_mouse = 16*floor(x_mouse/16)
  y_mouse = 16*floor(y_mouse/16)
  if User_input.mouse_inwindow then
    select_tile(x_mouse, y_mouse, Layer1_tiles)
  end
end


-- This function runs at the end of paint callback
-- Specific for info that changes if the emulator is paused and idle callback is called
local function mouse_actions()
  -- Font
  draw.Text_opacity = 1.0

  if Cheat.allow_cheats then  -- show cheat status anyway
    draw.alert_text(-draw.Border_left, draw.Buffer_height + draw.Border_bottom, "Cheats: allowed", COLOUR.warning, COLOUR.warning_bg,
    true, false, 0.0, 1.0)
  end

  -- Drag and drop sprites with the mouse
  if Cheat.is_dragging_sprite then
    Cheat.drag_sprite(Cheat.dragging_sprite_id)
    Cheat.is_cheating = true
  end

end


local function read_raw_input()
  -- User input data
  Previous.User_input = luap.copytable(User_input)
  local tmp = input.get()
  for entry, value in pairs(User_input) do
    User_input[entry] = tmp[entry] or false
  end
  -- Mouse input
  tmp = input.getmouse()
  User_input.xmouse = tmp.X
  User_input.ymouse = tmp.Y
  User_input.leftclick = tmp.Left
  User_input.rightclick = tmp.Right
  -- BizHawk, custom field
  User_input.mouse_inwindow = mouse_onregion(-draw.Border_left, -draw.Border_top, draw.Buffer_width + draw.Border_right, draw.Buffer_height + draw.Border_bottom)

  -- Detect if a key was just pressed or released
  for entry, value in pairs(User_input) do
    if (value ~= false) and (Previous.User_input[entry] == false) then Keys.pressed[entry] = true
      else Keys.pressed[entry] = false
    end
    if (value == false) and (Previous.User_input[entry] ~= false) then Keys.released[entry] = true
      else Keys.released[entry] = false
    end
  end

  -- Key presses/releases execution:
  for entry, value in pairs(Keys.press) do
    if Keys.pressed[entry] then
      value()
    end
  end
  for entry, value in pairs(Keys.release) do
    if Keys.released[entry] then
      value()
    end
  end

end



--#############################################################################
-- CHEATS

-- This signals that some cheat is activated, or was some short time ago
Cheat.allow_cheats = false
Cheat.is_cheating = false
function Cheat.is_cheat_active()
  if Cheat.is_cheating then
    draw.Text_opacity = 1.0
    draw.Bg_opacity = 1.0
    draw.alert_text(draw.Buffer_middle_x - 3*BIZHAWK_FONT_WIDTH, BIZHAWK_FONT_HEIGHT, " CHEAT ", COLOUR.warning, COLOUR.warning_bg)
    Previous.is_cheating = true
  else
    if Previous.is_cheating then
      gui.addmessage("Script applied cheat") -- BizHawk
      Previous.is_cheating = false
    end
  end
end


-- Called from Cheat.beat_level()
function Cheat.activate_next_level(secret_exit)
  if u8(WRAM.level_exit_type) == 0x80 and u8(WRAM.midway_point) == 1 then
    if secret_exit then
      w8(WRAM.level_exit_type, 0x2)
    else
      w8(WRAM.level_exit_type, 1)
    end
  end

  Cheat.is_cheating = true
end


-- allows start + select + X to activate the normal exit
--      start + select + A to activate the secret exit
--      start + select + B to exit the level without activating any exits
function Cheat.beat_level()
  if Is_paused and Joypad["Select"] and (Joypad["X"] or Joypad["A"] or Joypad["B"]) then
    w8(WRAM.level_flag_table + Level_index, bit.bor(Level_flag, 0x80))

    local secret_exit = Joypad["A"]
    if not Joypad["B"] then
      w8(WRAM.midway_point, 1)
    else
      w8(WRAM.midway_point, 0)
    end

    Cheat.activate_next_level(secret_exit)
  end
end


-- This function makes Mario's position free
-- Press L+R+up to activate and L+R+down to turn it off.
-- While active, press directionals to fly free and Y or X to boost him up
Cheat.under_free_move = false
function Cheat.free_movement()
  if (Joypad["L"] and Joypad["R"] and Joypad["Up"]) then Cheat.under_free_move = true end
  if (Joypad["L"] and Joypad["R"] and Joypad["Down"]) then Cheat.under_free_move = false end
  if not Cheat.under_free_move then
    if Previous.under_free_move then w8(WRAM.frozen, 0) end
    return
  end

  local x_pos, y_pos = u16(WRAM.x), u16(WRAM.y)
  local movement_mode = u8(WRAM.player_animation_trigger)
  local pixels = (Joypad["Y"] and 7) or (Joypad["X"] and 4) or 1  -- how many pixels per frame

  if Joypad["Left"] then x_pos = x_pos - pixels end
  if Joypad["Right"] then x_pos = x_pos + pixels end
  if Joypad["Up"] then y_pos = y_pos - pixels end
  if Joypad["Down"] then y_pos = y_pos + pixels end

  -- freeze player to avoid deaths
  if movement_mode == 0 then
    w8(WRAM.frozen, 1)
    w8(WRAM.x_speed, 0)
    w8(WRAM.y_speed, 0)

    -- animate sprites by incrementing the effective frame
    w8(WRAM.effective_frame, (u8(WRAM.effective_frame) + 1) % 256)
  else
    w8(WRAM.frozen, 0)
  end

  -- manipulate some values
  w16(WRAM.x, x_pos)
  w16(WRAM.y, y_pos)
  w8(WRAM.invisibility_timer, 127)
  w8(WRAM.vertical_scroll_flag_header, 1)  -- free vertical scrolling
  w8(WRAM.vertical_scroll_enabled, 1)

  Cheat.is_cheating = true
  Previous.under_free_move = true
end


-- Drag and drop sprites with the mouse, if the cheats are activated and mouse is over the sprite
-- Right clicking and holding: drags the sprite
-- Releasing: drops it over the latest spot
function Cheat.drag_sprite(id)
  if Game_mode ~= SMW.game_mode_level then Cheat.is_dragging_sprite = false ; return end

  local xoff, yoff = Sprites_info[id].hitbox_xoff, Sprites_info[id].hitbox_yoff
  local xgame, ygame = game_coordinates(User_input.xmouse - xoff, User_input.ymouse - yoff, Camera_x, Camera_y)

  local sprite_xhigh = floor(xgame/256)
  local sprite_xlow = xgame - 256*sprite_xhigh
  local sprite_yhigh = floor(ygame/256)
  local sprite_ylow = ygame - 256*sprite_yhigh

  w8(WRAM.sprite_x_high + id, sprite_xhigh)
  w8(WRAM.sprite_x_low + id, sprite_xlow)
  w8(WRAM.sprite_y_high + id, sprite_yhigh)
  w8(WRAM.sprite_y_low + id, sprite_ylow)
end


function Cheat.score()
  if not Cheat.allow_cheats then
    print("Cheats not allowed.")
    return
  end

  local num = forms.gettext(Options_form.score_number)
  local is_hex = num:sub(1,2):lower() == "0x"
  num = tonumber(num)

  if not num or num%1 ~= 0 or num < 0
  or num > 9999990 or (not is_hex and num%10 ~= 0) then
    print("Enter a valid score: hexadecimal representation or decimal ending in 0.")
    return
  end

  num = is_hex and num or num/10
  w24(WRAM.mario_score, num)

  print(fmt("Cheat: score set to %d0.", num))
  Cheat.is_cheating = true
end


function Cheat.timer()
  if not Cheat.allow_cheats then
    print("Cheats not allowed.")
    return
  end

  local num = tonumber(forms.gettext(Options_form.timer_number))

  if not num or num > 999 then
    print("Enter a valid integer (0-999).")
    return
  end

  w16(WRAM.timer, 0)
  if num >= 0 then w8(WRAM.timer + 2, luap.read_digit(num, 1, 10, "right to left")) end
  if num > 9  then w8(WRAM.timer + 1, luap.read_digit(num, 2, 10, "right to left")) end
  if num > 99 then w8(WRAM.timer + 0, luap.read_digit(num, 3, 10, "right to left")) end

  print(fmt("Cheat: timer set to %03d", num))
  Cheat.is_cheating = true
end


-- BizHawk: modifies address <address> value from <current> to <current + modification>
-- [size] is the optional size in bytes of the address
-- TODO: [is_signed] is untrue if the value is unsigned, true otherwise
function Cheat.change_address(address, value_form, size, is_hex, criterion, error_message, success_message)
  if not Cheat.allow_cheats then
    print("Cheats not allowed.")
    return
  end

  size = size or 1
  local max_value = 256^size - 1
  local value = Options_form[value_form] and forms.gettext(Options_form[value_form]) or value_form
  local default_criterion = function(value)
    if type(value) == "string" then
      local number = string.match(value, is_hex and "%x+" or "%d+")
      if not number then return false end

      value = tonumber(number, is_hex and 16 or 10) -- take first number of the string
    else
      value = tonumber(value, is_hex and 16 or 10)
    end

    if not value or value%1 ~= 0 or value < 0 or value > max_value then
      return false
    else
      return value
    end
  end

  local new = default_criterion(value)
  if criterion and new then
    new = criterion(new) and new or false
  end
  if not new then
    print(error_message or "Enter a valid value.")
    return
  end

  local memoryf = (size == 1 and w8) or (size == 2 and w16) or (size == 3 and w24) or error"size is too big"
  memoryf(address, new)
  print(fmt("Cheat: %s set to %d.", success_message, new) or fmt("Cheat: set WRAM 0x%X to %d.", address, new))
  Cheat.is_cheating = true
end


--#############################################################################
-- MAIN --


-- Key presses:
Keys.registerkeypress("rightclick", right_click)
Keys.registerkeypress("leftclick", left_click)

-- Key releases:
Keys.registerkeyrelease("mouse_inwindow", function() Cheat.is_dragging_sprite = false end)
Keys.registerkeyrelease("leftclick", function() Cheat.is_dragging_sprite = false end)

-- Lateral gaps:
if biz.features.support_extra_padding then
  client.SetGameExtraPadding(OPTIONS.left_gap, OPTIONS.top_gap, OPTIONS.right_gap, OPTIONS.bottom_gap)
  client.SetClientExtraPadding(0, 0, 0, 0)
end

function Options_form.create_window()
  Options_form.form = forms.newform(222, 692, "SMW Options")
  local xform, yform, delta_y = 4, 2, 20

  -- Top label
  Options_form.label_cheats = forms.label(Options_form.form, "You can close this form at any time", xform, yform, 200, 20)

  --- CHEATS
  yform = yform + delta_y
  Options_form.allow_cheats = forms.checkbox(Options_form.form, "Allow cheats", xform, yform)
  forms.setproperty(Options_form.allow_cheats, "Checked", Cheat.allow_cheats)

  -- Powerup cheat
  xform = xform + 103
  forms.button(Options_form.form, "Powerup", function() Cheat.change_address(WRAM.powerup, "powerup_number", 1, false,
    nil, "Enter a valid integer (0-255).", "powerup")
  end, xform, yform, 57, 24)

  xform = xform + 59
  Options_form.powerup_number = forms.textbox(Options_form.form, "", 30, 16, "UNSIGNED", xform, yform + 2, false, false)

  -- Score cheat
  xform = 2
  yform = yform + 28
  forms.button(Options_form.form, "Score", Cheat.score, xform, yform, 43, 24)

  xform = xform + 45
  Options_form.score_number = forms.textbox(Options_form.form, fmt("0x%X", u24(WRAM.mario_score)), 48, 16, nil, xform, yform + 2, false, false)

  -- Coin cheat
  xform = xform + 60
  forms.button(Options_form.form, "Coin", function() Cheat.change_address(WRAM.player_coin, "coin_number", 1, false,
    function(num) return num < 100 end, "Enter an integer between 0 and 99.", "coin")
  end, xform, yform, 43, 24)

  xform = xform + 45
  Options_form.coin_number = forms.textbox(Options_form.form, "", 24, 16, "UNSIGNED", xform, yform + 2, false, false)

  -- Item box cheat
  xform = 2
  yform = yform + 28
  forms.button(Options_form.form, "Item box", function() Cheat.change_address(WRAM.item_box, "item_box_number", 1, true,
    nil, "Enter a valid integer (0-255).", "Item box")
  end, xform, yform, 60, 24)

  xform = xform + 62
  Options_form.item_box_number = forms.dropdown(Options_form.form, Item_box_table, xform, yform + 1, 300, 10)

  -- Positon cheat
  xform = 2
  yform = yform + 28
  forms.button(Options_form.form, "Position", function()
    Cheat.change_address(WRAM.x, "player_x", 2, false, nil, "Enter a valid x position", "x position")
    Cheat.change_address(WRAM.x_sub, "player_x_sub", 1, true, nil, "Enter a valid x subpixel", "x subpixel")
    Cheat.change_address(WRAM.y, "player_y", 2, false, nil, "Enter a valid y position", "y position")
    Cheat.change_address(WRAM.y_sub, "player_y_sub", 1, true, nil, "Enter a valid y subpixel", "y subpixel")
  end, xform, yform, 60, 24)

  yform = yform + 2
  xform = xform + 62
  Options_form.player_x = forms.textbox(Options_form.form, "", 32, 16, "UNSIGNED", xform, yform, false, false)
  xform = xform + 33
  Options_form.player_x_sub = forms.textbox(Options_form.form, "", 28, 16, "HEX", xform, yform, false, false)
  xform = xform + 34
  Options_form.player_y = forms.textbox(Options_form.form, "", 32, 16, "UNSIGNED", xform, yform, false, false)
  xform = xform + 33
  Options_form.player_y_sub = forms.textbox(Options_form.form, "", 28, 16, "HEX", xform, yform, false, false)

  -- Timer cheat
  xform = 2
  yform = yform + 28
  forms.button(Options_form.form, "Timer", Cheat.timer, xform, yform, 43, 24)

  xform = xform + 45
  Options_form.timer_number = forms.textbox(Options_form.form, "", 30, 16, "UNSIGNED", xform, yform + 2, false, false)

  --- SHOW/HIDE
  xform = 2
  yform = yform + 32
  Options_form.label1 = forms.label(Options_form.form, "Show/hide options:", xform, yform)

  yform = yform + delta_y
  local y_begin_showhide = yform  -- 1st column
  Options_form.debug_info = forms.checkbox(Options_form.form, "Debug info", xform, yform)
  forms.setproperty(Options_form.debug_info, "Checked", OPTIONS.display_miscellaneous_debug_info)

  yform = yform + delta_y
  Options_form.movie_info = forms.checkbox(Options_form.form, "Movie info", xform, yform)
  forms.setproperty(Options_form.movie_info, "Checked", OPTIONS.display_movie_info)

  yform = yform + delta_y
  Options_form.misc_info = forms.checkbox(Options_form.form, "Miscellaneous", xform, yform)
  forms.setproperty(Options_form.misc_info, "Checked", OPTIONS.display_misc_info)

  yform = yform + delta_y
  Options_form.player_info = forms.checkbox(Options_form.form, "Player info", xform, yform)
  forms.setproperty(Options_form.player_info, "Checked", OPTIONS.display_player_info)

  yform = yform + delta_y
  Options_form.sprite_info = forms.checkbox(Options_form.form, "Sprite info", xform, yform)
  forms.setproperty(Options_form.sprite_info, "Checked", OPTIONS.display_sprite_info)

  yform = yform + delta_y
  Options_form.sprite_hitbox = forms.checkbox(Options_form.form, "Sprite hitbox", xform, yform)
  forms.setproperty(Options_form.sprite_hitbox, "Checked", OPTIONS.display_sprite_hitbox)

  yform = yform + delta_y
  Options_form.sprite_tables = forms.checkbox(Options_form.form, "Sprite misc tab.", xform, yform)
  forms.setproperty(Options_form.sprite_tables, "Checked", OPTIONS.display_miscellaneous_sprite_table)

  yform = yform + delta_y
  Options_form.sprite_data = forms.checkbox(Options_form.form, "Sprite data", xform, yform)
  forms.setproperty(Options_form.sprite_data, "Checked", OPTIONS.display_sprite_data)

  yform = yform + delta_y
  Options_form.sprite_load_status = forms.checkbox(Options_form.form, "Sprite load", xform, yform)
  forms.setproperty(Options_form.sprite_load_status, "Checked", OPTIONS.display_miscellaneous_sprite_table)

  yform = yform + delta_y
  Options_form.sprite_spawning_areas = forms.checkbox(Options_form.form, "Spawning areas", xform, yform)
  forms.setproperty(Options_form.sprite_spawning_areas, "Checked", OPTIONS.display_sprite_spawning_areas)

  yform = yform + delta_y
  Options_form.sprite_vanish_area = forms.checkbox(Options_form.form, "Sprite pit line", xform, yform)
  forms.setproperty(Options_form.sprite_vanish_area, "Checked", OPTIONS.display_sprite_vanish_area)

  yform = yform + delta_y
  Options_form.yoshi_info = forms.checkbox(Options_form.form, "Yoshi info", xform, yform)
  forms.setproperty(Options_form.yoshi_info, "Checked", OPTIONS.display_yoshi_info)

  xform = xform + 105  -- 2nd column
  yform = y_begin_showhide
  Options_form.extended_sprite_info = forms.checkbox(Options_form.form, "Extended sprites", xform, yform)
  forms.setproperty(Options_form.extended_sprite_info, "Checked", OPTIONS.display_extended_sprite_info)

  yform = yform + delta_y
  Options_form.cluster_sprite_info = forms.checkbox(Options_form.form, "Cluster sprites", xform, yform)
  forms.setproperty(Options_form.cluster_sprite_info, "Checked", OPTIONS.display_cluster_sprite_info)

  yform = yform + delta_y
  Options_form.minor_extended_sprite_info = forms.checkbox(Options_form.form, "Minor ext. spr.", xform, yform)
  forms.setproperty(Options_form.minor_extended_sprite_info, "Checked", OPTIONS.display_minor_extended_sprite_info)

  yform = yform + delta_y
  Options_form.bounce_sprite_info = forms.checkbox(Options_form.form, "Bounce sprites", xform, yform)
  forms.setproperty(Options_form.bounce_sprite_info, "Checked", OPTIONS.display_bounce_sprite_info)

  yform = yform + delta_y
  Options_form.level_info = forms.checkbox(Options_form.form, "Level info", xform, yform)
  forms.setproperty(Options_form.level_info, "Checked", OPTIONS.display_level_info)

  yform = yform + delta_y
  Options_form.counters_info = forms.checkbox(Options_form.form, "Counters info", xform, yform)
  forms.setproperty(Options_form.counters_info, "Checked", OPTIONS.display_counters)

  yform = yform + delta_y
  Options_form.static_camera_region = forms.checkbox(Options_form.form, "Static camera", xform, yform)
  forms.setproperty(Options_form.static_camera_region, "Checked", OPTIONS.display_static_camera_region)

  yform = yform + delta_y
  Options_form.block_duplication_predictor = forms.checkbox(Options_form.form, "Block duplica.", xform, yform)
  forms.setproperty(Options_form.block_duplication_predictor, "Checked", OPTIONS.use_block_duplication_predictor)

  yform = yform + delta_y
  Options_form.level_boundary_always = forms.checkbox(Options_form.form, "Level boundary", xform, yform)
  forms.setproperty(Options_form.level_boundary_always, "Checked", OPTIONS.display_level_boundary_always)

  yform = yform + delta_y
  Options_form.overworld_info = forms.checkbox(Options_form.form, "Overworld info", xform, yform)
  forms.setproperty(Options_form.overworld_info, "Checked", OPTIONS.display_overworld_info)

  yform = yform + delta_y
  Options_form.event_table = forms.checkbox(Options_form.form, "Event table", xform, yform)
  forms.setproperty(Options_form.event_table, "Checked", OPTIONS.display_event_table)

  yform = yform + delta_y  -- if odd number of show/hide checkboxes

  xform, yform = 2, yform + 30
  forms.label(Options_form.form, "Player hitbox:", xform, yform + 2, 70, 25)
  xform = xform + 70
  Options_form.player_hitbox = forms.dropdown(Options_form.form, {"Hitbox", "Interaction points", "Both", "None"}, xform, yform)
  xform, yform = 2, yform + 30

  -- DEBUG/EXTRA
  forms.label(Options_form.form, "Debug info:", xform, yform, 62, 22)
  yform = yform + delta_y

  local y_begin_debug = yform  -- 1st column
  Options_form.debug_player_extra = forms.checkbox(Options_form.form, "Player extra", xform, yform)
  forms.setproperty(Options_form.debug_player_extra, "Checked", OPTIONS.display_debug_player_extra)
  yform = yform  + delta_y

  Options_form.debug_sprite_extra = forms.checkbox(Options_form.form, "Sprite extra", xform, yform)
  forms.setproperty(Options_form.debug_sprite_extra, "Checked", OPTIONS.display_debug_sprite_extra)
  yform = yform + delta_y

  Options_form.debug_sprite_tweakers = forms.checkbox(Options_form.form, "Sprite tweakers", xform, yform)
  forms.setproperty(Options_form.debug_sprite_tweakers, "Checked", OPTIONS.display_debug_sprite_tweakers)
  yform = yform + delta_y

  Options_form.debug_extended_sprite = forms.checkbox(Options_form.form, "Extended sprites", xform, yform)
  forms.setproperty(Options_form.debug_extended_sprite, "Checked", OPTIONS.display_debug_extended_sprite)
  yform = yform + delta_y

  xform, yform = xform + 105, y_begin_debug
  Options_form.debug_cluster_sprite = forms.checkbox(Options_form.form, "Cluster sprites", xform, yform)
  forms.setproperty(Options_form.debug_cluster_sprite, "Checked", OPTIONS.display_debug_cluster_sprite)
  yform = yform + delta_y

  Options_form.debug_minor_extended_sprite = forms.checkbox(Options_form.form, "Minor ext. spr.", xform, yform)
  forms.setproperty(Options_form.debug_minor_extended_sprite, "Checked", OPTIONS.display_debug_minor_extended_sprite)
  yform = yform + delta_y

  Options_form.debug_bounce_sprite = forms.checkbox(Options_form.form, "Bounce sprites", xform, yform)
  forms.setproperty(Options_form.debug_bounce_sprite, "Checked", OPTIONS.display_debug_bounce_sprite)
  yform = yform + delta_y

  Options_form.debug_controller_data = forms.checkbox(Options_form.form, "Controller data", xform, yform)
  forms.setproperty(Options_form.debug_controller_data, "Checked", OPTIONS.display_debug_controller_data)
  --yform = yform + delta_y

  -- HELP:
  xform, yform = 4, yform + 30
  forms.label(Options_form.form, "Miscellaneous:", xform, yform, 78, 22)
  xform, yform = xform + 78, yform - 2

  Options_form.draw_tiles_with_click = forms.checkbox(Options_form.form, "Draw/erase tiles", xform, yform)
  forms.setproperty(Options_form.draw_tiles_with_click, "Checked", OPTIONS.draw_tiles_with_click)
  xform, yform = 4, yform + 30

  -- OPACITY
  Options_form.text_opacity = forms.label(Options_form.form, ("Text opacity: (%.0f%%, %.0f%%)"):
      format(100*draw.Text_max_opacity, 100*draw.Background_max_opacity), xform, yform, 135, 22)
  ;
  xform, yform = xform + 135, yform - 4
  forms.button(Options_form.form, "-", function() draw.decrease_opacity()
    forms.settext(Options_form.text_opacity, ("Text opacity: (%.0f%%, %.0f%%)"):format(100*draw.Text_max_opacity, 100*draw.Background_max_opacity))
  end, xform, yform, 14, 24)
  xform = xform + 14
  forms.button(Options_form.form, "+", function() draw.increase_opacity()
    forms.settext(Options_form.text_opacity, ("Text opacity: (%.0f%%, %.0f%%)"):format(100*draw.Text_max_opacity, 100*draw.Background_max_opacity))
  end, xform, yform, 14, 24)
  xform, yform = 4, yform + 25

  -- HELP
  Options_form.erase_tiles = forms.button(Options_form.form, "Erase tiles", function() Layer1_tiles = {}; Layer2_tiles = {} end, xform, yform)
  xform = xform + 105
  Options_form.write_help_handle = forms.button(Options_form.form, "Help", Options_form.write_help, xform, yform)
end


function Options_form.evaluate_form()
  -- Option form's buttons
  Cheat.allow_cheats = forms.ischecked(Options_form.allow_cheats) or false
  OPTIONS.display_miscellaneous_debug_info = forms.ischecked(Options_form.debug_info) or false
  -- Show/hide
  OPTIONS.display_movie_info = forms.ischecked(Options_form.movie_info) or false
  OPTIONS.display_misc_info = forms.ischecked(Options_form.misc_info) or false
  OPTIONS.display_player_info = forms.ischecked(Options_form.player_info) or false
  OPTIONS.display_sprite_info = forms.ischecked(Options_form.sprite_info) or false
  OPTIONS.display_sprite_hitbox = forms.ischecked(Options_form.sprite_hitbox) or false
  OPTIONS.display_miscellaneous_sprite_table =  forms.ischecked(Options_form.sprite_tables) or false
  OPTIONS.display_sprite_data =  forms.ischecked(Options_form.sprite_data) or false
  OPTIONS.display_sprite_load_status =  forms.ischecked(Options_form.sprite_load_status) or false
  OPTIONS.display_sprite_spawning_areas = forms.ischecked(Options_form.sprite_spawning_areas) or false
  OPTIONS.display_sprite_vanish_area = forms.ischecked(Options_form.sprite_vanish_area) or false
  OPTIONS.display_extended_sprite_info = forms.ischecked(Options_form.extended_sprite_info) or false
  OPTIONS.display_cluster_sprite_info = forms.ischecked(Options_form.cluster_sprite_info) or false
  OPTIONS.display_minor_extended_sprite_info = forms.ischecked(Options_form.minor_extended_sprite_info) or false
  OPTIONS.display_bounce_sprite_info = forms.ischecked(Options_form.bounce_sprite_info) or false
  OPTIONS.display_level_info = forms.ischecked(Options_form.level_info) or false
  OPTIONS.display_yoshi_info = forms.ischecked(Options_form.yoshi_info) or false
  OPTIONS.display_counters = forms.ischecked(Options_form.counters_info) or false
  OPTIONS.display_static_camera_region = forms.ischecked(Options_form.static_camera_region) or false
  OPTIONS.use_block_duplication_predictor = forms.ischecked(Options_form.block_duplication_predictor) or false
  OPTIONS.display_level_boundary_always = forms.ischecked(Options_form.level_boundary_always) or false
  OPTIONS.display_overworld_info = forms.ischecked(Options_form.overworld_info) or false
  OPTIONS.display_event_table = forms.ischecked(Options_form.event_table) or false
  -- Debug/Extra
  OPTIONS.display_debug_player_extra = forms.ischecked(Options_form.debug_player_extra) or false
  OPTIONS.display_debug_sprite_extra = forms.ischecked(Options_form.debug_sprite_extra) or false
  OPTIONS.display_debug_sprite_tweakers = forms.ischecked(Options_form.debug_sprite_tweakers) or false
  OPTIONS.display_debug_extended_sprite = forms.ischecked(Options_form.debug_extended_sprite) or false
  OPTIONS.display_debug_cluster_sprite = forms.ischecked(Options_form.debug_cluster_sprite) or false
  OPTIONS.display_debug_minor_extended_sprite = forms.ischecked(Options_form.debug_minor_extended_sprite) or false
  OPTIONS.display_debug_bounce_sprite = forms.ischecked(Options_form.debug_bounce_sprite) or false
  OPTIONS.display_debug_controller_data = forms.ischecked(Options_form.debug_controller_data) or false
  -- Other buttons
  OPTIONS.draw_tiles_with_click = forms.ischecked(Options_form.draw_tiles_with_click) or false
  local button_text = forms.gettext(Options_form.player_hitbox)
  OPTIONS.display_player_hitbox = button_text == "Both" or button_text == "Hitbox"
  OPTIONS.display_interaction_points = button_text == "Both" or button_text == "Interaction points"
end


function Options_form.write_help()
    print(" - - - TIPS - - - ")
    print("MOUSE:")
    print("Use the left click to draw blocks and to see the Map16 properties.")
    print("Use the right click to toogle the hitbox mode of Mario and sprites.")
    print("\n")

    print("CHEATS(better turn off while recording a movie):")
    print("L+R+up: stop gravity for Mario fly / L+R+down to cancel")
    print("Use the mouse to drag and drop sprites")
    print("While paused: B+select to get out of the level")
    print("          X+select to beat the level (main exit)")
    print("          A+select to get the secret exit (don't use it if there isn't one)")

    print("\n")
    print("OTHERS:")
    print("If performance suffers, disable some options that are not needed at the moment.")
    print(" - - - end of tips - - - ")
end
Options_form.create_window()
Options_form.is_form_closed = false


event.unregisterbyname("smw-tas-bizhawk-onexit")
event.onexit(function()
  local destroyed = forms.destroy(Options_form.form)

  if biz.features.support_extra_padding then
    client.SetGameExtraPadding(0, 0, 0, 0)
    client.SetClientExtraPadding(0, 0, 0, 0)
  end

  config.save_options()
  print("Finishing smw-bizhawk script.")
end, "smw-tas-bizhawk-onexit")


while true do
  if emu.getsystemid() ~= "SNES" then
    gui.text(0, 0, "WRONG CORE: " .. emu.getsystemid(), "black", "red", "bottomright")

  else

    Options_form.is_form_closed = forms.gettext(Options_form.player_hitbox) == ""
    if not Options_form.is_form_closed then Options_form.evaluate_form() end

    bizhawk_status()
    draw.bizhawk_screen_info()
    read_raw_input()

    -- Drawings are allowed now
    scan_smw()
    level_mode()
    overworld_mode()
    show_movie_info()
    if Is_lagged then  -- BizHawk: outside show_movie_info
      draw.alert_text(draw.Buffer_middle_x*draw.AR_x - 3*BIZHAWK_FONT_WIDTH, 2*BIZHAWK_FONT_HEIGHT, " LAG ", COLOUR.warning, COLOUR.warning_bg)
    end
    show_misc_info()
    show_controller_data()

    Cheat.is_cheat_active()

    mouse_actions()

    -- Checks if options form exits and create a button in case it doesn't
    if Options_form.is_form_closed then
      if User_input.mouse_inwindow then
        draw.rectangle(120 - 1, 0, 4*BIZHAWK_FONT_WIDTH/draw.AR_x + 1, BIZHAWK_FONT_HEIGHT/draw.AR_y + 1, 0xff000000, 0xff808080)  -- bizhawk
        gui.text(120*draw.AR_x + draw.Border_left, 0 + draw.Border_top, "Menu")  -- unlisted color
      end
    end

    -- INPUT MANIPULATION
    Joypad = joypad.get(1)
    if Cheat.allow_cheats then
      Cheat.is_cheating = false

      Cheat.beat_level()
      Cheat.free_movement()
    else
      -- Cancel any continuous cheat
      Cheat.under_free_move = false

      Cheat.is_cheating = false
    end
  end

  -- Frame advance: don't use emu.yield() righ now, as the drawings aren't erased correctly
  emu.frameadvance()
end
