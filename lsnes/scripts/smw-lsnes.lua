---------------------------------------------------------------------------
--  Super Mario World (U) Utility Script for Lsnes - rr2 version
--  http://tasvideos.org/Lsnes.html
--
--  Author: Rodrigo A. do Amaral (Amaraticando)
--  Git repository: https://github.com/rodamaral/smw-tas
---------------------------------------------------------------------------

--#############################################################################
-- CONFIG:

assert(GLOBAL_SMW_TAS_PARENT_DIR, "smw-tas.lua must be run")
INI_CONFIG_NAME = "lsnes-config.ini"
LUA_SCRIPT_FILENAME = load([==[return @@LUA_SCRIPT_FILENAME@@]==])()
LUA_SCRIPT_FOLDER = LUA_SCRIPT_FILENAME:match("(.+)[/\\][^/\\+]") .. "/"
INI_CONFIG_FILENAME = GLOBAL_SMW_TAS_PARENT_DIR .. "config/" .. INI_CONFIG_NAME
-- TODO: save the config file in the parent directory;
--       must make the JSON library work for the other scripts first

-- END OF CONFIG < < < < < < <
--#############################################################################
-- INITIAL STATEMENTS:

print(string.format("Starting script %s", LUA_SCRIPT_FILENAME))

-- Script verifies whether the emulator is indeed Lsnes - rr2 version / beta23 or higher
if not lsnes_features or not lsnes_features("text-halos") then
  callback.paint:register(function()
    gui.text(0, 00, "This script is supposed to be run on Lsnes.", "red", 0x600000ff)
    gui.text(0, 16, "Version: rr2-beta23 or higher.", "red", 0x600000ff)
    gui.text(0, 32, "Your version seems to be different.", "red", 0x600000ff)
    gui.text(0, 48, "Download the correct script at:", "red", 0x600000ff)
    gui.text(0, 64, "https://github.com/rodamaral/smw-tas/wiki/Downloads", "red", 0x600000ff)
    gui.text(0, 80, "Download the latest version of lsnes here", "red", 0x600000ff)
    gui.text(0, 96, "http://tasvideos.org/Lsnes.html", "red", 0x600000ff)
  end)
  gui.repaint()
  error("This script works in a newer version of lsnes.")
end

-- Load environment
package.path = LUA_SCRIPT_FOLDER .. "lib/?.lua" .. ";" .. package.path 
local bit, gui, input, movie, memory, memory2 = bit, gui, input, movie, memory, memory2
local string, math, table, next, ipairs, pairs, io, os, type = string, math, table, next, ipairs, pairs, io, os, type
local tostring, tostringx = tostring, tostringx

local luap = require "luap"
local config = require "config"
config.load_options(INI_CONFIG_FILENAME)
config.load_lsnes_fonts(LUA_SCRIPT_FOLDER)
local keyinput = require "keyinput"
local Timer = require "timer"
local draw = require "draw"
local lsnes = require "lsnes"
local joypad = require "joypad"
local smw = require "game.smw"
local map16 = require "game.map16"
local RNG = require "game.rng"
local shooter = require 'game.sprites.shooter'
local score = require 'game.sprites.score'
local smoke = require 'game.sprites.smoke'
local coin = require 'game.sprites.coin'

local OPTIONS = config.OPTIONS
local COLOUR = config.COLOUR
local LSNES_FONT_HEIGHT = config.LSNES_FONT_HEIGHT
local LSNES_FONT_WIDTH = config.LSNES_FONT_WIDTH
local BMP_STRINGS = config.BMP_STRINGS
local LEFT_ARROW = config.LEFT_ARROW
local RIGHT_ARROW = config.RIGHT_ARROW

config.filename = INI_CONFIG_FILENAME
config.raw_data = {["LSNES OPTIONS"] = OPTIONS}

local controller, MOVIE = lsnes.controller, lsnes.MOVIE

local fmt = string.format
local floor = math.floor

-- Compatibility of the memory read/write functions
local u8 =  memory.readbyte
local s8 =  memory.readsbyte
local w8 =  memory.writebyte
local u16 = memory.readword
local s16 = memory.readsword
local w16 = memory.writeword
local u24 = memory.readhword
local s24 = memory.readshword
local w24 = memory.writehword
local u32 = memory.readdword
local s32 = memory.readsdword
local w32 = memory.writedword

-- Bitmaps and dbitmaps
local base = GLOBAL_SMW_TAS_PARENT_DIR .. "images/"
local BITMAPS, PALETTES, DBITMAPS = {}, {}, {}
local Palettes_adjusted = {}
BITMAPS.player_blocked_status, PALETTES.player_blocked_status = gui.image.load_png_str(BMP_STRINGS.player_blocked_status)

DBITMAPS.yoshi_tongue = gui.image.load_png("yoshi_tongue.png", base)
DBITMAPS.yoshi_full_mouth = gui.image.load_png("yoshi_full_mouth.png", base)
DBITMAPS.yoshi_full_mouth_trans = draw.copy_dbitmap(DBITMAPS.yoshi_full_mouth)
DBITMAPS.yoshi_full_mouth_trans:adjust_transparency(0x60)

DBITMAPS.goal_tape = gui.image.load_png_str(BMP_STRINGS.goal_tape)
DBITMAPS.interaction_points = {}

local base = GLOBAL_SMW_TAS_PARENT_DIR .. "images/hitbox/"
DBITMAPS.interaction_points[1], DBITMAPS.interaction_points_palette =
    gui.image.load_png("interaction_points_1.png", base)
DBITMAPS.interaction_points[2] = gui.image.load_png("interaction_points_2.png", base)
DBITMAPS.interaction_points[3] = gui.image.load_png("interaction_points_3.png", base)
DBITMAPS.interaction_points[4] = gui.image.load_png("interaction_points_4.png", base)

DBITMAPS.interaction_points_palette_alt = gui.palette.new()
DBITMAPS.interaction_points_palette_alt:set(1, 0xff)
DBITMAPS.interaction_points_palette_alt:set(2, 0xe0ff0000)
DBITMAPS.interaction_points_palette_alt:set(3, 0xff00)

BMP_STRINGS = nil  -- bitmap-strings shall not be used past here

-- Hotkeys availability  -- TODO: error if key is invalid
print(string.format("Hotkey '%s' set to increase opacity.", OPTIONS.hotkey_increase_opacity))
print(string.format("Hotkey '%s' set to decrease opacity.", OPTIONS.hotkey_decrease_opacity))


--#############################################################################
-- GAME AND SNES SPECIFIC MACROS:

local SMW = smw.constant
local WRAM = smw.WRAM
local DEBUG_REGISTER_ADDRESSES = smw.DEBUG_REGISTER_ADDRESSES
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


--#############################################################################
-- SCRIPT UTILITIES:


-- Variables used in various functions
--COMMANDS = COMMANDS or {}  -- the list of scripts-made commands
COMMANDS = require('commands')

--local Cheat = {}  -- family of cheat functions and variables
local Cheat = require('cheat')

local Previous = {}
local Video_callback = false  -- lsnes specific
local Ghost_script = nil  -- lsnes specific
local Paint_context = gui.renderctx.new(256, 224)  -- lsnes specific
local Midframe_context = gui.renderctx.new(256, 224)  -- lsnes specific
local User_input = keyinput.key_state
--local Joypad = {}
local Layer1_tiles = {}
local Layer2_tiles = {}
local Is_lagged = nil
local Lagmeter = {}  -- experimental: determine how laggy (0-100) the last frame was, after emulation
local Options_menu = {show_menu = false, current_tab = "Show/hide options"}
local Address_change_watcher = {}
local Registered_addresses = {}
local Readonly_on_timer
local Display = {}  -- some temporary display options
local Sprites_info = {}  -- keeps track of useful sprite info that might be used outside the main sprite function
local Sprite_hitbox = {}  -- keeps track of what sprite slots must display the hitbox
local Collision_debugger = {} -- array, each id is a different collision within the same frame
local generators = {} -- Special generators class

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


-- Returns the local time of the OS
local function system_time()
  local epoch = os.date("*t", utime())  -- time since UNIX epoch converted to OS time
  local hour = epoch.hour
  local minute = epoch.min
  local second = epoch.sec

  return string.format("%.2d:%.2d:%.2d", hour, minute, second)
end


-- TODO: use is_onto_rectangle
local function mouse_onregion(x1, y1, x2, y2)
  -- Reads external mouse coordinates
  local mouse_x = User_input.mouse_x
  local mouse_y = User_input.mouse_y

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


-- basic widget support
local widget = {}

widget.all_widgets = {} -- table of names

function widget:new(name, x, y, symbol)
  self.all_widgets[name] = {
    name = name,
    x = x or 0,
    y = y or 0,
    symbol = symbol or true,  -- the display object that is passed to draw.button
    display_flag = false,
  }
end

function widget:exists(name)
  return self.all_widgets[name] and true or false
end

function widget:get_property(name, property)
  local object = self.all_widgets[name]

  return object[property]
end

function widget:set_property(name, property, value)
  local object = self.all_widgets[name]

  object[property] = value
end

function widget:display_all()
  if User_input.mouse_inwindow == 1 then
    for name, object in pairs(self.all_widgets) do
        if object.display_flag then
          draw.button(draw.AR_x * object.x, draw.AR_y * object.y, object.symbol, function()
            self.left_mouse_dragging = true
            self.selected_object = name
          end)
      end
    end
  end
end

function widget:drag_widget()
  if self.left_mouse_dragging then
    local object = self.all_widgets[self.selected_object]
    object.x = floor(User_input.mouse_x/draw.AR_x)
    object.y = floor(User_input.mouse_y/draw.AR_y)
  end
end

widget:new("player", 0, 32)
widget:new("yoshi", 0, 88)
widget:new("miscellaneous_sprite_table", 0, 180)
widget:new("sprite_load_status", 256, 224)
widget:new("RNG.predict", 224, 112)
widget:new("spriteMiscTables", 256, 126)


local function register_debug_callback(toggle)
  if not toggle then for index, addr_table in ipairs(DEBUG_REGISTER_ADDRESSES) do
    DEBUG_REGISTER_ADDRESSES[index].fn = function() DEBUG_REGISTER_ADDRESSES.active[index] = true end
  end end

  if toggle then OPTIONS.register_ACE_debug_callback = not OPTIONS.register_ACE_debug_callback end

  if OPTIONS.register_ACE_debug_callback then
    for index, addr_table in ipairs(DEBUG_REGISTER_ADDRESSES) do
      memory2[addr_table[1]]:registerexec(addr_table[2], addr_table.fn)
      --print(string.format("Registering address $%x at memory area %s.", addr_table[2], addr_table[1]), addr_table.fn)
    end
  else
    for index, addr_table in ipairs(DEBUG_REGISTER_ADDRESSES) do
      memory2[addr_table[1]]:unregisterexec(addr_table[2], addr_table.fn)
      --print(string.format("Unregistering address $%x at memory area %s.", addr_table[2], addr_table[1]), addr_table.fn)
    end
  end

  config.save_options()
end


-- Lateral Paddings (those persist if the script is closed and can be edited under Configure > Settings > Advanced > UI)
function Options_menu.adjust_lateral_gaps()
  draw.Font = false
  local left_gap, right_gap = OPTIONS.left_gap, OPTIONS.right_gap
  local top_gap, bottom_gap = OPTIONS.top_gap, OPTIONS.bottom_gap

  -- rectangle the helps to see the padding values
  gui.rectangle(-left_gap, -top_gap, draw.Buffer_width + right_gap + left_gap, draw.Buffer_height + bottom_gap + top_gap,
    1, Options_menu.show_menu and COLOUR.warning2 or 0xb0808080)  -- unlisted color
  ;

  draw.button(-draw.Border_left, draw.Buffer_middle_y, "+", function() OPTIONS.left_gap = OPTIONS.left_gap + 32 end, {always_on_client = true, ref_y = 1.0})
  draw.button(-draw.Border_left, draw.Buffer_middle_y, "-", function()
    if left_gap > 32 then OPTIONS.left_gap = OPTIONS.left_gap - 32 else OPTIONS.left_gap = 0 end
  end, {always_on_client = true})

  draw.button(draw.Buffer_width, draw.Buffer_middle_y, "+", function() OPTIONS.right_gap = OPTIONS.right_gap + 32 end, {always_on_client = true, ref_y = 1.0})
  draw.button(draw.Buffer_width, draw.Buffer_middle_y, "-", function()
    if right_gap > 32 then OPTIONS.right_gap = OPTIONS.right_gap - 32 else OPTIONS.right_gap = 0 end
  end, {always_on_client = true})

  draw.button(draw.Buffer_middle_x, -draw.Border_top, "+", function() OPTIONS.top_gap = OPTIONS.top_gap + 32 end, {always_on_client = true, ref_x = 1.0})
  draw.button(draw.Buffer_middle_x, -draw.Border_top, "-", function()
    if top_gap > 32 then OPTIONS.top_gap = OPTIONS.top_gap - 32 else OPTIONS.top_gap = 0 end
  end, {always_on_client = true})

  draw.button(draw.Buffer_middle_x, draw.Buffer_height, "+", function() OPTIONS.bottom_gap = OPTIONS.bottom_gap + 32 end, {always_on_client = true, ref_x = 1.0})
  draw.button(draw.Buffer_middle_x, draw.Buffer_height, "-", function()
    if bottom_gap > 32 then OPTIONS.bottom_gap = OPTIONS.bottom_gap - 32 else OPTIONS.bottom_gap = 0 end
  end, {always_on_client = true})
end


function Options_menu.print_help()
  print("\n")
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
  print("Command cheats(use lsnes:Messages and type the commands, that are cAse-SENSitiVE):")
  print("score <value>:  set the score to <value>.")
  print("coin <value>:   set the coin number to <value>.")
  print("powerup <value>: set the powerup number to <value>.")

  print("\n")
  print("OTHERS:")
  print(fmt("Press \"%s\" for more and \"%s\" for less opacity.", OPTIONS.hotkey_increase_opacity, OPTIONS.hotkey_decrease_opacity))
  print("If performance suffers, disable some options that are not needed at the moment.")
  print("", "(input display and sprites are the ones that slow down the most).")
  print("It's better to play without the mouse over the game window.")
  print(" - - - end of tips - - - ")
end

function Options_menu.display()
  if not Options_menu.show_menu then return end

  -- Pauses emulator and draws the background
  if lsnes.runmode == "normal" then exec("pause-emulator") end
  gui.rectangle(0, 0, draw.Buffer_width, draw.Buffer_height, 2, COLOUR.mainmenu_outline, COLOUR.mainmenu_bg)

  -- Font stuff
  draw.Font = false
  local delta_x = draw.font_width()
  local delta_y = draw.font_height() + 4
  local x_pos, y_pos = 4, 4
  local tmp

  -- Exit menu button
  gui.solidrectangle(0, 0, draw.Buffer_width, delta_y, 0xa0ffffff) -- tab's shadow / unlisted color
  draw.button(draw.Buffer_width, 0, " X ", function() Options_menu.show_menu = false end, {always_on_game = true})

  -- External buttons
  tmp = OPTIONS.display_controller_input and "Hide Input" or "Show Input"
  draw.button(0, 0, tmp, function() OPTIONS.display_controller_input = not OPTIONS.display_controller_input
  end, {always_on_client = true, ref_x = 1.0, ref_y = 1.0})

  tmp = Cheat.allow_cheats and "Cheats: allowed" or "Cheats: blocked"
  draw.button(-draw.Border_left, draw.Buffer_height, tmp, function()
    Cheat.allow_cheats = not Cheat.allow_cheats
    draw.message("Cheats " .. (Cheat.allow_cheats and "allowed." or "blocked."))
  end, {always_on_client = true, ref_y = 1.0})

  draw.button(draw.Buffer_width + draw.Border_right, draw.Buffer_height, "Erase Tiles", function() Layer1_tiles = {}; Layer2_tiles = {}
  end, {always_on_client = true, ref_y = 1.0})

  -- Tabs
  draw.button(x_pos, y_pos, "Show/hide", function() Options_menu.current_tab = "Show/hide options" end,
  {button_pressed = Options_menu.current_tab == "Show/hide options"})
  x_pos = x_pos + 9*delta_x + 2

  draw.button(x_pos, y_pos, "Settings", function() Options_menu.current_tab = "Misc options" end,
  {button_pressed = Options_menu.current_tab == "Misc options"})
  x_pos = x_pos + 8*delta_x + 2

  draw.button(x_pos, y_pos, "Lag", function() Options_menu.current_tab = "Lag options" end,
  {button_pressed = Options_menu.current_tab == "Lag options"})
  x_pos = x_pos + 3*delta_x + 2

  draw.button(x_pos, y_pos, "Debug info", function() Options_menu.current_tab = "Debug info" end,
  {button_pressed = Options_menu.current_tab == "Debug info"})
  x_pos = x_pos + 10*delta_x + 2

  draw.button(x_pos, y_pos, "Sprite tables", function() Options_menu.current_tab = "Sprite miscellaneous tables" end,
  {button_pressed = Options_menu.current_tab == "Sprite miscellaneous tables"})
  --x_pos = x_pos + 13*delta_x + 2

  x_pos, y_pos = 4, y_pos + delta_y + 8

  if Options_menu.current_tab == "Show/hide options" then

    tmp = OPTIONS.display_movie_info and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_movie_info = not OPTIONS.display_movie_info end)
    gui.text(x_pos + delta_x + 3, y_pos, "Display Movie Info?")
    y_pos = y_pos + delta_y

    tmp = OPTIONS.display_misc_info and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_misc_info = not OPTIONS.display_misc_info end)
    gui.text(x_pos + delta_x + 3, y_pos, "Display Misc Info?")
    x_pos = x_pos + 20*delta_x + 8

    tmp = OPTIONS.display_RNG_info and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_RNG_info = not OPTIONS.display_RNG_info end)
    gui.text(x_pos + delta_x + 3, y_pos, "Display RNG?")
    x_pos = 4
    y_pos = y_pos + delta_y + 8

    -- Player properties
    gui.text(x_pos, y_pos, "Player:")
    x_pos = x_pos + 8*delta_x
    tmp = OPTIONS.display_player_info and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_player_info = not OPTIONS.display_player_info end)
    x_pos = x_pos + delta_x + 3
    gui.text(x_pos, y_pos, "Info")
    x_pos = x_pos + 5*delta_x
    tmp = OPTIONS.display_player_hitbox and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_player_hitbox = not OPTIONS.display_player_hitbox end)
    x_pos = x_pos + delta_x + 3
    gui.text(x_pos, y_pos, "Hitbox")
    x_pos = x_pos + 7*delta_x
    tmp = OPTIONS.display_interaction_points and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_interaction_points = not OPTIONS.display_interaction_points end)
    x_pos = x_pos + delta_x + 3
    gui.text(x_pos, y_pos, "Clipping")
    x_pos = x_pos + 9*delta_x
    tmp = OPTIONS.display_cape_hitbox and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_cape_hitbox = not OPTIONS.display_cape_hitbox end)
    x_pos = x_pos + delta_x + 3
    gui.text(x_pos, y_pos, "Cape")
    x_pos = x_pos + 5*delta_x
    tmp = OPTIONS.display_debug_player_extra and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_debug_player_extra = not OPTIONS.display_debug_player_extra end)
    gui.text(x_pos + delta_x + 3, y_pos, "Extra")
    x_pos, y_pos = 4, y_pos + delta_y + 8  -- reset

    -- Sprites properties
    gui.text(x_pos, y_pos, "Sprites:")
    x_pos = x_pos + 9*delta_x
    tmp = OPTIONS.display_sprite_info and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_sprite_info = not OPTIONS.display_sprite_info end)
    x_pos = x_pos + delta_x + 3
    gui.text(x_pos, y_pos, "Info")
    x_pos = x_pos + 5*delta_x
    tmp = OPTIONS.display_sprite_hitbox and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_sprite_hitbox = not OPTIONS.display_sprite_hitbox end)
    x_pos = x_pos + delta_x + 3
    gui.text(x_pos, y_pos, "Hitbox")
    x_pos = x_pos + 7*delta_x
    tmp = OPTIONS.display_sprite_vs_sprite_hitbox and true or " "
    draw.button(x_pos, y_pos, tmp, function()
      OPTIONS.display_sprite_vs_sprite_hitbox = not OPTIONS.display_sprite_vs_sprite_hitbox
    end)
    x_pos = x_pos + delta_x + 3
    gui.text(x_pos, y_pos, "vs sprites")
    x_pos = x_pos + 11*delta_x
    tmp = OPTIONS.display_debug_sprite_tweakers and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_debug_sprite_tweakers = not OPTIONS.display_debug_sprite_tweakers end)
    x_pos = x_pos + delta_x + 3
    gui.text(x_pos, y_pos, "Tweakers")
    x_pos = x_pos + 9*delta_x
    tmp = OPTIONS.display_debug_sprite_extra and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_debug_sprite_extra = not OPTIONS.display_debug_sprite_extra end)
    x_pos = x_pos + delta_x + 3
    gui.text(x_pos, y_pos, "Extra")
    x_pos, y_pos = 4, y_pos + delta_y + 8  -- reset

    -- Extended sprites properties
    gui.text(x_pos, y_pos, "Extended sprites:")
    x_pos = x_pos + 18*delta_x
    tmp = OPTIONS.display_extended_sprite_info and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_extended_sprite_info = not OPTIONS.display_extended_sprite_info end)
    x_pos = x_pos + delta_x + 3
    gui.text(x_pos, y_pos, "Info")
    x_pos = x_pos + 5*delta_x
    tmp = OPTIONS.display_extended_sprite_hitbox and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_extended_sprite_hitbox = not OPTIONS.display_extended_sprite_hitbox end)
    x_pos = x_pos + delta_x + 3
    gui.text(x_pos, y_pos, "Hitbox")
    x_pos = x_pos + 7*delta_x
    tmp = OPTIONS.display_debug_extended_sprite and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_debug_extended_sprite = not OPTIONS.display_debug_extended_sprite end)
    x_pos = x_pos + delta_x + 3
    gui.text(x_pos, y_pos, "Extra")
    x_pos, y_pos = 4, y_pos + delta_y + 8  -- reset

    -- Cluster sprites properties
    gui.text(x_pos, y_pos, "Cluster sprites:")
    x_pos = x_pos + 17*delta_x
    tmp = OPTIONS.display_cluster_sprite_info and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_cluster_sprite_info = not OPTIONS.display_cluster_sprite_info end)
    x_pos = x_pos + delta_x + 3
    gui.text(x_pos, y_pos, "Info")
    x_pos = x_pos + 5*delta_x
    tmp = OPTIONS.display_cluster_sprite_hitbox and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_cluster_sprite_hitbox = not OPTIONS.display_cluster_sprite_hitbox end)
    x_pos = x_pos + delta_x + 3
    gui.text(x_pos, y_pos, "Hitbox")
    x_pos = x_pos + 7*delta_x
    tmp = OPTIONS.display_debug_cluster_sprite and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_debug_cluster_sprite = not OPTIONS.display_debug_cluster_sprite end)
    x_pos = x_pos + delta_x + 3
    gui.text(x_pos, y_pos, "Extra")
    x_pos, y_pos = 4, y_pos + delta_y + 8  -- reset

    -- Minor extended sprites properties
    gui.text(x_pos, y_pos, "Minor ext. sprites:")
    x_pos = x_pos + 20*delta_x
    tmp = OPTIONS.display_minor_extended_sprite_info and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_minor_extended_sprite_info = not OPTIONS.display_minor_extended_sprite_info end)
    x_pos = x_pos + delta_x + 3
    gui.text(x_pos, y_pos, "Info")
    x_pos = x_pos + 5*delta_x
    tmp = OPTIONS.display_minor_extended_sprite_hitbox and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_minor_extended_sprite_hitbox = not OPTIONS.display_minor_extended_sprite_hitbox end)
    x_pos = x_pos + delta_x + 3
    gui.text(x_pos, y_pos, "Hitbox")
    x_pos = x_pos + 7*delta_x
    tmp = OPTIONS.display_debug_minor_extended_sprite and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_debug_minor_extended_sprite = not OPTIONS.display_debug_minor_extended_sprite end)
    x_pos = x_pos + delta_x + 3
    gui.text(x_pos, y_pos, "Extra")
    x_pos, y_pos = 4, y_pos + delta_y + 8  -- reset

    -- Bounce sprites properties
    gui.text(x_pos, y_pos, "Bounce sprites:")
    x_pos = x_pos + 16*delta_x
    tmp = OPTIONS.display_bounce_sprite_info and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_bounce_sprite_info = not OPTIONS.display_bounce_sprite_info end)
    x_pos = x_pos + delta_x + 3
    gui.text(x_pos, y_pos, "Info")

    x_pos = x_pos + 5*delta_x
    tmp = OPTIONS.display_quake_sprite_info and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_quake_sprite_info = not OPTIONS.display_quake_sprite_info end)
    x_pos = x_pos + delta_x + 3
    gui.text(x_pos, y_pos, "Quake")

    x_pos = x_pos + 6*delta_x
    tmp = OPTIONS.display_debug_bounce_sprite and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_debug_bounce_sprite = not OPTIONS.display_debug_bounce_sprite end)
    x_pos = x_pos + delta_x + 3
    gui.text(x_pos, y_pos, "Extra")
    x_pos, y_pos = 4, y_pos + delta_y + 8  -- reset

    -- Generator sprites
    tmp = OPTIONS.display_generator_info and true or " "
    gui.text(x_pos, y_pos, "Generators:")
    x_pos = x_pos + 11*delta_x + 3

    tmp = OPTIONS.display_generator_info and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_generator_info = not OPTIONS.display_generator_info end)
    x_pos = x_pos + delta_x + 16

    -- Shooter sprites
    tmp = OPTIONS.display_shooter_sprite_info and true or " "
    gui.text(x_pos, y_pos, "Shooters:")
    x_pos = x_pos + 9*delta_x + 3

    tmp = OPTIONS.display_shooter_sprite_info and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_shooter_sprite_info = not OPTIONS.display_shooter_sprite_info end)
    x_pos, y_pos = 4, y_pos + delta_y + 8  -- reset

    -- Coin sprites
    tmp = OPTIONS.display_coin_sprite_info and true or " "
    gui.text(x_pos, y_pos, "Coin sprites:")
    x_pos = x_pos + 13*delta_x + 3

    tmp = OPTIONS.display_coin_sprite_info and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_coin_sprite_info = not OPTIONS.display_coin_sprite_info end)
    x_pos = x_pos + delta_x + 16

    -- Score sprites
    tmp = OPTIONS.display_score_sprite_info and true or " "
    gui.text(x_pos, y_pos, "Score sprites:")
    x_pos = x_pos + 14*delta_x + 3

    tmp = OPTIONS.display_score_sprite_info and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_score_sprite_info = not OPTIONS.display_score_sprite_info end)
    x_pos = x_pos + delta_x + 16

    -- Smoke sprites
    tmp = OPTIONS.display_smoke_sprite_info and true or " "
    gui.text(x_pos, y_pos, "Smoke sprites:")
    x_pos = x_pos + 14*delta_x + 3

    tmp = OPTIONS.display_smoke_sprite_info and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_smoke_sprite_info = not OPTIONS.display_smoke_sprite_info end)
    x_pos, y_pos = 4, y_pos + delta_y + 8  -- reset

    -- Level boundaries
    tmp = OPTIONS.display_level_boundary and true or " "
    gui.text(x_pos, y_pos, "Level boundary:")
    x_pos = x_pos + 16*delta_x

    tmp = OPTIONS.display_level_boundary_always and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_level_boundary_always = not OPTIONS.display_level_boundary_always end)
    x_pos = x_pos + delta_x + 3
    gui.text(x_pos, y_pos, "Always")
    x_pos = x_pos + 7*delta_x

    tmp = OPTIONS.display_sprite_vanish_area and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_sprite_vanish_area = not OPTIONS.display_sprite_vanish_area end)
    x_pos = x_pos + delta_x + 3
    gui.text(x_pos, y_pos, "Sprites")
    x_pos, y_pos = 4, y_pos + delta_y + 8

    tmp = OPTIONS.display_level_info and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_level_info = not OPTIONS.display_level_info end)
    gui.text(x_pos + delta_x + 3, y_pos, "Show Level Info?")
    y_pos = y_pos + delta_y

    tmp = OPTIONS.display_yoshi_info and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_yoshi_info = not OPTIONS.display_yoshi_info end)
    gui.text(x_pos + delta_x + 3, y_pos, "Show Yoshi Info?")
    y_pos = y_pos + delta_y

    tmp = OPTIONS.display_counters and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_counters = not OPTIONS.display_counters end)
    gui.text(x_pos + delta_x + 3, y_pos, "Show Counters Info?")
    y_pos = y_pos + delta_y

    tmp = OPTIONS.display_static_camera_region and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_static_camera_region = not OPTIONS.display_static_camera_region end)
    gui.text(x_pos + delta_x + 3, y_pos, "Show Camera Region?")
    y_pos = y_pos + delta_y

    tmp = OPTIONS.use_block_duplication_predictor and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.use_block_duplication_predictor = not OPTIONS.use_block_duplication_predictor end)
    gui.text(x_pos + delta_x + 3, y_pos, "Use block duplication predictor?")
    y_pos = y_pos + delta_y

    tmp = OPTIONS.register_player_position_changes
    if tmp == "simple" then tmp = " simple " elseif (not tmp) then tmp = "disabled" end
    draw.button(x_pos, y_pos, tmp, function()
      if OPTIONS.register_player_position_changes == "simple" then OPTIONS.register_player_position_changes = "complete"
      elseif OPTIONS.register_player_position_changes == "complete" then OPTIONS.register_player_position_changes = false
      else OPTIONS.register_player_position_changes = "simple" end
    end)
    gui.text(x_pos + 8*delta_x + 3, y_pos, "Register player position changes between frames?")
    y_pos = y_pos + delta_y

  elseif Options_menu.current_tab == "Misc options" then

    tmp = OPTIONS.register_ACE_debug_callback and true or " "
    draw.button(x_pos, y_pos, tmp, function() register_debug_callback(true) end)
    gui.text(x_pos + delta_x + 3, y_pos, "Detect arbitrary code execution for some addresses? (ACE)")
    y_pos = y_pos + delta_y

    tmp = OPTIONS.draw_tiles_with_click and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.draw_tiles_with_click = not OPTIONS.draw_tiles_with_click end)
    gui.text(x_pos + delta_x + 3, y_pos, "Draw tiles with left click?")
    y_pos = y_pos + delta_y

    tmp = OPTIONS.use_custom_fonts and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.use_custom_fonts = not OPTIONS.use_custom_fonts end)
    gui.text(x_pos + delta_x + 3, y_pos, "Use custom fonts?")
    y_pos = y_pos + delta_y

    tmp = "Background:"
    draw.button(x_pos, y_pos, tmp, function()
      if OPTIONS.text_background_type == "automatic" then
        OPTIONS.text_background_type = "full"
      elseif OPTIONS.text_background_type == "full" then
        OPTIONS.text_background_type = "outline"
      else
        OPTIONS.text_background_type = "automatic"
      end
    end)
    draw.Font = "Uzebox6x8"
    tmp = draw.text(x_pos + 11*delta_x + 6, y_pos, tostringx(OPTIONS.text_background_type), COLOUR.warning, COLOUR.warning_bg)
    draw.Font = false
    draw.text(tmp + 3, y_pos, tostringx(OPTIONS.text_background_type), COLOUR.warning, COLOUR.warning_bg)
    y_pos = y_pos + delta_y

    tmp = OPTIONS.is_simple_comparison_ghost_loaded and true or " "
    draw.button(x_pos, y_pos, tmp, function()
      if not OPTIONS.is_simple_comparison_ghost_loaded then
        Ghost_player = require "ghost"
        Ghost_player.init()
      else
        luap.unrequire "ghost"
        Ghost_player = nil
      end
      OPTIONS.is_simple_comparison_ghost_loaded = not OPTIONS.is_simple_comparison_ghost_loaded
    end)
    gui.text(x_pos + delta_x + 3, y_pos, "Load comparison ghost?")
    y_pos = y_pos + delta_y

    -- Manage opacity / filter
    x_pos, y_pos = 4, y_pos + delta_y
    gui.text(x_pos, y_pos, "Opacity:")
    y_pos = y_pos + delta_y
    draw.button(x_pos, y_pos, "-", function()
      if OPTIONS.filter_opacity >= 1 then OPTIONS.filter_opacity = OPTIONS.filter_opacity - 1 end
      COLOUR.filter_color = draw.change_transparency(COLOUR.filter_tonality, OPTIONS.filter_opacity/10)
    end)
    draw.button(x_pos + delta_x + 2, y_pos, "+", function()
      if OPTIONS.filter_opacity <= 9 then OPTIONS.filter_opacity = OPTIONS.filter_opacity + 1 end
      COLOUR.filter_color = draw.change_transparency(COLOUR.filter_tonality, OPTIONS.filter_opacity/10)
    end)
    gui.text(x_pos + 2*delta_x + 5, y_pos, "Change filter opacity (" .. 10*OPTIONS.filter_opacity .. "%)")
    y_pos = y_pos + delta_y

    draw.button(x_pos, y_pos, "-", draw.decrease_opacity)
    draw.button(x_pos + delta_x + 2, y_pos, "+", draw.increase_opacity)
    gui.text(x_pos + 2*delta_x + 5, y_pos, fmt("Text opacity: (%.0f%%, %.0f%%)",
      100*draw.Text_max_opacity, 100*draw.Background_max_opacity))
    y_pos = y_pos + delta_y
    gui.text(x_pos, y_pos, fmt("'%s' and '%s' are hotkeys for this.",
      OPTIONS.hotkey_decrease_opacity, OPTIONS.hotkey_increase_opacity), COLOUR.weak)
    y_pos = y_pos + delta_y

    -- Video and AVI settings
    y_pos = y_pos + delta_y
    gui.text(x_pos, y_pos, "Video settings:")
    y_pos = y_pos + delta_y

    tmp = OPTIONS.make_lua_drawings_on_video and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.make_lua_drawings_on_video = not OPTIONS.make_lua_drawings_on_video end)
    gui.text(x_pos + delta_x + 3, y_pos, "Make lua drawings on video?")
    y_pos = y_pos + delta_y

    -- Others
    y_pos = y_pos + delta_y
    gui.text(x_pos, y_pos, "Help:")
    y_pos = y_pos + delta_y
    draw.button(x_pos, y_pos, "Reset Permanent Lateral Paddings", function() settings.set("left-border", "0");
      settings.set("right-border", "0"); settings.set("top-border", "0"); settings.set("bottom-border", "0") end)
    y_pos = y_pos + delta_y

    draw.button(x_pos, y_pos, "Reset Lateral Gaps", function()
      OPTIONS.left_gap = LSNES_FONT_WIDTH*(controller.total_width + 6)
      OPTIONS.right_gap = config.DEFAULT_OPTIONS.right_gap
      OPTIONS.top_gap = config.DEFAULT_OPTIONS.top_gap
      OPTIONS.bottom_gap = config.DEFAULT_OPTIONS.bottom_gap
    end)
    y_pos = y_pos + delta_y

    draw.button(x_pos, y_pos, "Show tips in lsnes: Messages", Options_menu.print_help)

  elseif Options_menu.current_tab == "Lag options" then

    tmp = OPTIONS.use_lagmeter_tool and true or " "
    draw.button(x_pos, y_pos, tmp, function()
      OPTIONS.use_lagmeter_tool = not OPTIONS.use_lagmeter_tool
      local task = OPTIONS.use_lagmeter_tool and "registerexec" or "unregisterexec"
      memory[task]("BUS", 0x8075, Lagmeter.get_master_cycles)  -- unlisted ROM
      end)
    gui.text(x_pos + delta_x + 3, y_pos, "Lagmeter tool? (experimental/for SMW only)")
    y_pos = y_pos + delta_y

    tmp = OPTIONS.use_custom_lag_detector and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.use_custom_lag_detector = not OPTIONS.use_custom_lag_detector end)
    gui.text(x_pos + delta_x + 3, y_pos, "Use custom lag detector?")
    y_pos = y_pos + delta_y

    tmp = OPTIONS.use_custom_lagcount and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.use_custom_lagcount = not OPTIONS.use_custom_lagcount end)
    gui.text(x_pos + delta_x + 3, y_pos, "Use custom lag count?")
    y_pos = y_pos + delta_y

    tmp = "Print help"
    draw.button(x_pos, y_pos, tmp, function()
      print("\nLagmeter tool:")
      print("This tool displays almost exactly how laggy the last frame has been.")
      print("Only works well for SMW(NTSC) and inside the level, where it usually matters.")
      print("Anything below 100% is not lagged, otherwise the game lagged.")
      print("\nCustom lag detector:")
      print("On some games, lsnes has false positives for lag.")
      print("This custom detector only checks if the game polled input and if WRAM $10 is zero.")
      print("For SMW, this also detects lag 1 frame sooner, which is useful.")
      print("By letting the lag count obey this custom detector, the number will persist even after the script is finished.")
    end)
    y_pos = y_pos + delta_y

  elseif Options_menu.current_tab == "Debug info" then

    tmp = OPTIONS.display_debug_controller_data and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_debug_controller_data = not OPTIONS.display_debug_controller_data end)
    gui.text(x_pos + delta_x + 3, y_pos, "Controller data (freezes the lag counter!)")
    y_pos = y_pos + delta_y

    tmp = OPTIONS.debug_collision_routine and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.debug_collision_routine = not OPTIONS.debug_collision_routine end)
    gui.text(x_pos + delta_x + 3, y_pos, fmt("Debug collision routine 1 ($%.6x). May not work in ROMhacks",
                                            smw.CHECK_FOR_CONTACT_ROUTINE)
    )
    y_pos = y_pos + delta_y

  elseif Options_menu.current_tab == "Sprite miscellaneous tables" then

    tmp = OPTIONS.display_miscellaneous_sprite_table and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_miscellaneous_sprite_table = not OPTIONS.display_miscellaneous_sprite_table end)
    gui.text(x_pos + delta_x + 3, y_pos, "Show Miscellaneous Sprite Table?") 

    x_pos = 4
    y_pos = y_pos + delta_y
    tmp = OPTIONS.display_sprite_load_status and true or " "
    draw.button(x_pos, y_pos, tmp, function() OPTIONS.display_sprite_load_status = not OPTIONS.display_sprite_load_status end)
    gui.text(x_pos + delta_x + 3, y_pos, "Show sprite load status within level?")

  end

  -- Lateral Paddings
  Options_menu.adjust_lateral_gaps()

  return true
end



--#############################################################################
-- SMW FUNCTIONS:

local screen_coordinates = smw.screen_coordinates
local game_coordinates = smw.game_coordinates


local Real_frame, Previous_real_frame, Effective_frame, Lag_indicator, Game_mode  -- lsnes specific
local Level_index, Room_index, Level_flag, Current_level
local Is_paused, Lock_animation_flag, Player_animation_trigger, Player_powerup, Yoshi_riding_flag
local Camera_x, Camera_y, Player_x, Player_y, Player_x_screen, Player_y_screen
local Yoshi_stored_sprites = {}
local function scan_smw()
  Previous_real_frame = Real_frame or u8("WRAM", WRAM.real_frame)
  Real_frame = u8("WRAM", WRAM.real_frame)
  Effective_frame = u8("WRAM", WRAM.effective_frame)
  Lag_indicator = u16("WRAM", WRAM.lag_indicator)  -- lsnes specific
  Game_mode = u8("WRAM", WRAM.game_mode)
  Level_index = u8("WRAM", WRAM.level_index)
  Level_flag = u8("WRAM", WRAM.level_flag_table + Level_index)
  Is_paused = u8("WRAM", WRAM.level_paused) == 1
  Lock_animation_flag = u8("WRAM", WRAM.lock_animation_flag)
  Room_index = u24("WRAM", WRAM.room_index)

  -- In level frequently used info
  Player_animation_trigger = u8("WRAM", WRAM.player_animation_trigger)
  Player_powerup = u8("WRAM", WRAM.powerup)
  Camera_x = s16("WRAM", WRAM.camera_x)
  Camera_y = s16("WRAM", WRAM.camera_y)
  Yoshi_riding_flag = u8("WRAM", WRAM.yoshi_riding_flag) ~= 0
  Player_x = s16("WRAM", WRAM.x)
  Player_y = s16("WRAM", WRAM.y)
  Player_x_screen, Player_y_screen = screen_coordinates(Player_x, Player_y, Camera_x, Camera_y)
  Display.is_player_near_borders = Player_x_screen <= 32 or Player_x_screen >= 0xd0 or Player_y_screen <= -100 or Player_y_screen >= 224

  -- TODO: test
  -- table of slots that are stored by some Yoshi
  -- 0 = by invisible Yoshi
  -- 1 = by Visible Yoshi
  -- nil = by none
  Yoshi_stored_sprites = {}
  local visible_yoshi = u8("WRAM", WRAM.yoshi_slot) - 1
  for slot = 0, SMW.sprite_max - 1 do
    -- if slot is a Yoshi:
    if u8("WRAM", WRAM.sprite_number + slot) == 0x35 and u8("WRAM", WRAM.sprite_status + slot) ~= 0 then
      local licked_slot = u8("WRAM", WRAM.sprite_misc_160e + slot)
      Yoshi_stored_sprites[licked_slot] = 0 + ((visible_yoshi == slot) and 1 or 0)
    end
  end
end


-- Creates lateral gaps
local function create_gaps()
  gui.left_gap(OPTIONS.left_gap)  -- for input display
  gui.right_gap(OPTIONS.right_gap)
  gui.top_gap(OPTIONS.top_gap)
  gui.bottom_gap(OPTIONS.bottom_gap)
end


function Lagmeter.get_master_cycles()
  local v, h = memory.getregister("vcounter"), memory.getregister("hcounter")
  local mcycles = v + 262 - 225

  Lagmeter.Mcycles = 1364*mcycles + h
  if v >= 226 or (v == 225 and h >= 12) then
    Lagmeter.Mcycles = Lagmeter.Mcycles - 2620
    print("Lagmeter (V, H):", v, h)
  end
  if v >= 248 then
    Lagmeter.Mcycles = Lagmeter.Mcycles - 262*1364
  end
end


-- Returns the extreme values that Mario needs to have in order to NOT touch a rectangular object
local function display_boundaries(x_game, y_game, width, height, camera_x, camera_y)
  -- Font
  draw.Font = "snes9xluasmall"
  draw.Text_opacity = 1.0
  draw.Bg_opacity = 0.8

  -- Coordinates around the rectangle
  local left = width*floor(x_game/width)
  local top = height*floor(y_game/height)
  left, top = screen_coordinates(left, top, camera_x, camera_y)
  local right = left + width - 1
  local bottom = top + height - 1

  -- Reads WRAM values of the player
  local is_ducking = u8("WRAM", WRAM.is_ducking)
  local powerup = Player_powerup
  local is_small = is_ducking ~= 0 or powerup == 0

  -- Left
  local left_text = string.format("%4d.0", width*floor(x_game/width) - 13)
  draw.text(draw.AR_x*left, draw.AR_y*floor((top+bottom)/2), left_text, false, false, 1.0, 0.5)

  -- Right
  local right_text = string.format("%d.f", width*floor(x_game/width) + 12)
  draw.text(draw.AR_x*right, draw.AR_y*floor((top+bottom)/2), right_text, false, false, 0.0, 0.5)

  -- Top
  local value = (Yoshi_riding_flag and y_game - 16) or y_game
  local top_text = fmt("%d.0", width*floor(value/width) - 32)
  draw.text(draw.AR_x*floor((left+right)/2), draw.AR_y*top, top_text, false, false, 0.5, 1.0)

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
  draw.text(draw.AR_y*floor((left+right)/2), draw.AR_y*bottom, bottom_text, false, false, 0.5, 0.0)

  return left, top
end


local function read_screens()
  local screens_number = u8("WRAM", WRAM.screens_number)
  local vscreen_number = u8("WRAM", WRAM.vscreen_number)
  local hscreen_number = u8("WRAM", WRAM.hscreen_number) - 1
  local vscreen_current = s8("WRAM", WRAM.y + 1)
  local hscreen_current = s8("WRAM", WRAM.x + 1)
  local level_mode_settings = u8("WRAM", WRAM.level_mode_settings)
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
    kind = 256*u8("WRAM", 0x1c800 + num_id) + u8("WRAM", 0xc800 + num_id)
  end

  if kind then return  num_x, num_y, kind, address end
end


local function draw_layer1_tiles(camera_x, camera_y)
  local x_origin, y_origin = screen_coordinates(0, 0, camera_x, camera_y)
  local x_mouse, y_mouse = game_coordinates(User_input.mouse_x, User_input.mouse_y, camera_x, camera_y)
  x_mouse = 16*floor(x_mouse/16)
  y_mouse = 16*floor(y_mouse/16)
  local push_direction = Real_frame%2 == 0 and 0 or 7  -- block pushes sprites to left or right?

  for number, positions in ipairs(Layer1_tiles) do
    -- Calculate the Lsnes coordinates
    local left = positions[1] + x_origin
    local top = positions[2] + y_origin
    local right = left + 15
    local bottom = top + 15
    local x_game, y_game = game_coordinates(draw.AR_x*left, draw.AR_y*top, camera_x, camera_y)

    -- Returns if block is way too outside the screen
    if draw.AR_x*left > - draw.Border_left - 32 and draw.AR_y*top  > - draw.Border_top - 32 and
    draw.AR_x*right < draw.Screen_width  + draw.Border_right + 32 and draw.AR_y*bottom < draw.Screen_height + draw.Border_bottom + 32 then

      -- Drawings
      local num_x, num_y, kind, address = get_map16_value(x_game, y_game)
      if kind then
        if kind >= 0x111 and kind <= 0x16d or kind == 0x2b then
          -- default solid blocks, don't know how to include custom blocks
          draw.rectangle(left + push_direction, top, 8, 15, -1, COLOUR.block_bg)
        end
        draw.rectangle(left, top, 15, 15, kind == SMW.blank_tile_map16 and COLOUR.blank_tile or COLOUR.block, -1)

        -- Custom map16 drawing
        if map16[kind] then
          map16[kind](left, top)
        end

        if Layer1_tiles[number][3] then
          display_boundaries(x_game, y_game, 16, 16, camera_x, camera_y)  -- the text around it
        end

        -- Draw Map16 id
        draw.Font = "Uzebox6x8"
        if kind and x_mouse == positions[1] and y_mouse == positions[2] then
          draw.text(draw.AR_x*(left + 4), draw.AR_y*top - draw.font_height(), fmt("Map16 (%d, %d), %x%s", num_x, num_y, kind, address),
          false, false, 0.5, 1.0)
        end
      end

    end

  end

end


local function draw_layer2_tiles()
  local layer2x = s16("WRAM", WRAM.layer2_x_nextframe)
  local layer2y = s16("WRAM", WRAM.layer2_y_nextframe)

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
  draw.Font = false
  draw.Text_opacity = 1.0
  draw.Bg_opacity = 0.5

  local x_game, y_game = game_coordinates(mouse_x, mouse_y, camera_x, camera_y)
  local obj_id

  -- Checks if the mouse is over Mario
  local x_player = s16("WRAM", WRAM.x)
  local y_player = s16("WRAM", WRAM.y)
  if x_player + 0xe >= x_game and x_player + 0x2 <= x_game and y_player + 0x30 >= y_game and y_player + 0x8 <= y_game then
    obj_id = "Mario"
  end

  if not obj_id and OPTIONS.display_sprite_info then
    for id = 0, SMW.sprite_max - 1 do
      local sprite_status = u8("WRAM", WRAM.sprite_status + id)
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

  draw.text(User_input.mouse_x, User_input.mouse_y - 8, obj_id, true, false, 0.5, 1.0)
  return obj_id, x_game, y_game
end


-- This function sees if the mouse if over some object, to change its hitbox mode
-- The order is: 1) player, 2) sprite.
local function right_click()
  -- do nothing if over movie editor
  if OPTIONS.display_controller_input and luap.inside_rectangle(User_input.mouse_x, User_input.mouse_y,
  lsnes.movie_editor_left, lsnes.movie_editor_top, lsnes.movie_editor_right, lsnes.movie_editor_bottom) then
    return
  end

  local id = select_object(User_input.mouse_x, User_input.mouse_y, Camera_x, Camera_y)

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

    config.save_options()
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

    config.save_options()
    return
  end

  -- Select layer 2 tiles
  local layer2x = s16("WRAM", WRAM.layer2_x_nextframe)
  local layer2y = s16("WRAM", WRAM.layer2_y_nextframe)
  local x_mouse, y_mouse = floor(User_input.mouse_x/draw.AR_x) + layer2x, floor(User_input.mouse_y/draw.AR_y) + layer2y
  select_tile(16*floor(x_mouse/16), 16*floor(y_mouse/16), Layer2_tiles)
end


local function show_movie_info()
  if not OPTIONS.display_movie_info then return end

  -- Font
  draw.Font = false
  draw.Text_opacity = 1.0
  draw.Bg_opacity = 1.0

  local y_text = - draw.Border_top
  local x_text = 0
  local width = draw.font_width()

  local rec_color = lsnes.Readonly and COLOUR.text or COLOUR.warning
  local recording_bg = lsnes.Readonly and COLOUR.background or COLOUR.warning_bg

  -- Read-only or read-write?
  local movie_type = lsnes.Readonly and "Movie " or "REC "
  draw.alert_text(x_text, y_text, movie_type, rec_color, recording_bg)

  -- Frame count
  x_text = x_text + width*#(movie_type)
  local movie_info
  if lsnes.Readonly then
    movie_info = string.format("%d/%d", lsnes.Lastframe_emulated, lsnes.Framecount)
  else
    movie_info = string.format("%d", lsnes.Lastframe_emulated)  -- delete string.format
  end
  draw.text(x_text, y_text, movie_info)  -- Shows the latest frame emulated, not the frame being run now

  -- Rerecord count
  x_text = x_text + width*#(movie_info)
  local rr_info = string.format("|%d ", lsnes.Rerecords)
  draw.text(x_text, y_text, rr_info, COLOUR.weak)

  -- Lag count
  x_text = x_text + width*#(rr_info)
  draw.text(x_text, y_text, lsnes.Lagcount, COLOUR.warning)
  x_text = x_text + width*string.len(lsnes.Lagcount)

  -- lsnes run mode
  if lsnes.is_special_runmode then
    local runmode = " " .. lsnes.runmode
    draw.text(x_text, y_text, runmode, lsnes.runmode_color)
    x_text = x_text + width*(#runmode)
  end

  -- emulator speed
  if lsnes.Lsnes_speed == "turbo" then
    draw.text(x_text, y_text, " (" .. lsnes.Lsnes_speed .. ")", COLOUR.weak)
  elseif lsnes.Lsnes_speed ~= 1 then
    draw.text(x_text, y_text, fmt(" (%.0f%%)", 100*lsnes.Lsnes_speed), COLOUR.weak)
  end

  local str = lsnes.frame_time(lsnes.Lastframe_emulated)   -- Shows the latest frame emulated, not the frame being run now
  draw.alert_text(draw.Buffer_width, draw.Buffer_height, str, COLOUR.text, recording_bg, false, 1.0, 1.0)

  if Is_lagged then
    gui.textHV(draw.Buffer_middle_x - 3*LSNES_FONT_WIDTH, 2*LSNES_FONT_HEIGHT, "Lag", COLOUR.warning, draw.change_transparency(COLOUR.warning_bg, draw.Background_max_opacity))

    Timer.registerfunction(1000000, function()
      if not Is_lagged then
        gui.textHV(draw.Buffer_middle_x - 3*LSNES_FONT_WIDTH, 2*LSNES_FONT_HEIGHT, "Lag", COLOUR.warning,
          draw.change_transparency(COLOUR.background, draw.Background_max_opacity))
      end
    end, "Was lagged")

  end

end


local function show_misc_info()
  if not OPTIONS.display_misc_info then return end

  -- Font
  draw.Font = false
  draw.Text_opacity = 1.0
  draw.Bg_opacity = 1.0

  -- Display
  local RNG = u16("WRAM", WRAM.RNG)
  local main_info = string.format("Frame(%02x, %02x) RNG(%04x) Mode(%02x)",
                  Real_frame, Effective_frame, RNG, Game_mode)
  ;

  draw.text(draw.Buffer_width + draw.Border_right, -draw.Border_top, main_info, true, false)

  if Game_mode == SMW.game_mode_level then
    -- Time frame counter of the clock
    draw.Font = "snes9xlua"
    local timer_frame_counter = u8("WRAM", WRAM.timer_frame_counter)
    draw.text(draw.AR_x*161, draw.AR_y*15, fmt("%.2d", timer_frame_counter))

    -- Score: sum of digits, useful for avoiding lag
    draw.Font = "Uzebox8x12"
    local score = u24("WRAM", WRAM.mario_score)
    draw.text(draw.AR_x*240, draw.AR_y*24, fmt("=%d", luap.sum_digits(score)), COLOUR.weak)
  end
end


-- diplay nearby RNG states: past, present a future values
function display_RNG()
  if not bit.bfields then return end -- FIXME: define procedure when new API doesn't exist
  
  if not OPTIONS.display_RNG_info then
    if next(RNG.possible_values) ~= nil then
      RNG.possible_values = {}
      RNG.reverse_possible_values = {}
      collectgarbage()
    end

    return
  end

  -- create RNG lists if they are empty
  if next(RNG.possible_values) == nil then RNG.create_lists() end

  widget:set_property("RNG.predict", "display_flag", true)
  local x = draw.AR_x * widget:get_property("RNG.predict", "x")
  local y = draw.AR_y * widget:get_property("RNG.predict", "y")
  draw.Font = false
  local height = draw.font_height()
  local upper_rows = 10

  local index = u32("WRAM", WRAM.RNG_input)
  local RNG_counter = RNG.possible_values[index]

  if RNG_counter then
    local min = math.max(RNG_counter - upper_rows, 1)
    local max = math.min(min + 2*upper_rows, 27777) -- todo: hardcoded constants are never a good idea

    for i = min, max do
      local seed1, seed2, rng1, rng2 = bit.bfields(RNG.reverse_possible_values[i], 8, 8, 8, 8)
      local info = fmt("%d: %.2x, %.2x, %.2x, %.2x\n", i, seed1, seed2, rng1, rng2)
      draw.text(x, y, info, i ~= RNG_counter and "white" or "red")
      y = y + height
    end
  else
    draw.text(x, y, "Glitched RNG! Report state/movie", "red")
  end
end


-- Shows the controller input as the RAM and SNES registers store it
local function show_controller_data()
  if not OPTIONS.display_debug_controller_data then return end

  -- Font
  draw.Font = "snes9xluasmall"
  local height = draw.font_height()
  local x_pos, y_pos, x, y, _ = 0, 0, 0, 0

  x = draw.over_text(x, y, memory2.BUS:word(0x4218), "BYsS^v<>AXLR0123", COLOUR.warning,  false, true)
  x = draw.over_text(x, y, memory2.BUS:word(0x421a), "BYsS^v<>AXLR0123", COLOUR.warning2, false, true)
  x = draw.over_text(x, y, memory2.BUS:word(0x421c), "BYsS^v<>AXLR0123", COLOUR.warning,  false, true)
  x = draw.over_text(x, y, memory2.BUS:word(0x421e), "BYsS^v<>AXLR0123", COLOUR.warning2, false, true)
  _, y = draw.text(x, y, " (Registers)", COLOUR.warning, false, true)

  x = x_pos
  x = draw.over_text(x, y, memory2.BUS:word(0x4016), "BYsS^v<>AXLR0123", COLOUR.warning,  false, true)
  _, y = draw.text(x, y, " ($4016)", COLOUR.warning, false, true)

  x = x_pos
  x = draw.over_text(x, y, 256*u8("WRAM", WRAM.ctrl_1_1) + u8("WRAM", WRAM.ctrl_1_2), "BYsS^v<>AXLR0123", COLOUR.weak)
  _, y = draw.text(x, y, " (RAM data)", COLOUR.weak, false, true)

  x = x_pos
  draw.over_text(x, y, 256*u8("WRAM", WRAM.firstctrl_1_1) + u8("WRAM", WRAM.firstctrl_1_2), "BYsS^v<>AXLR0123", -1, 0xff, -1)
end


local function level_info()
  if not OPTIONS.display_level_info then return end

  -- Font
  draw.Font = "Uzebox6x8"
  draw.Text_opacity = 1.0
  draw.Bg_opacity = 1.0
  local y_pos = - draw.Border_top + LSNES_FONT_HEIGHT
  local color = COLOUR.text

  local sprite_buoyancy =  bit.lrshift(u8("WRAM", WRAM.sprite_buoyancy), 6)
  if sprite_buoyancy == 0 then sprite_buoyancy = "" else
    sprite_buoyancy = fmt(" %.2x", sprite_buoyancy)
    color = COLOUR.warning
  end

  -- converts the level number to the Lunar Magic number; should not be used outside here
  local lm_level_number = Level_index
  if Level_index > 0x24 then lm_level_number = Level_index + 0xdc end

  -- Number of screens within the level
  local level_type, screens_number, hscreen_current, hscreen_number, vscreen_current, vscreen_number = read_screens()

  draw.text(draw.Buffer_width + draw.Border_right, y_pos, fmt("%.1sLevel(%.2x)%s", level_type, lm_level_number, sprite_buoyancy),
          color, true, false)
  ;

  draw.text(draw.Buffer_width + draw.Border_right, y_pos + draw.font_height(), fmt("Screens(%d):", screens_number), true)

  draw.text(draw.Buffer_width + draw.Border_right, y_pos + 2*draw.font_height(), fmt("(%d/%d, %d/%d)", hscreen_current, hscreen_number,
        vscreen_current, vscreen_number), true)
  ;
end


-- Creates lines showing where the real pit of death is
-- One line is for sprites and another is for Mario or Mario/Yoshi (different spot)
local function draw_boundaries()
  if not OPTIONS.display_level_boundary then return end

  -- Font
  draw.Font = "Uzebox6x8"
  draw.Text_opacity = 1.0
  draw.Bg_opacity = 1.0

  -- Player borders
  if Display.is_player_near_borders or OPTIONS.display_level_boundary_always then
    local xmin = 8 - 1
    local ymin = -0x80 - 1
    local xmax = 0xe8 + 1
    local ymax = 0xfb  -- no increment, because this line kills by touch

    local no_powerup = (Player_powerup == 0)
    if no_powerup then ymax = ymax + 1 end
    if not Yoshi_riding_flag then ymax = ymax + 5 end

    draw.box(xmin, ymin, xmax, ymax, 2, COLOUR.warning2)
    if draw.Border_bottom >= 64 then
      local str = string.format("Death: %d", ymax + Camera_y)
      draw.text(xmin, draw.AR_y*ymax, str, COLOUR.warning, true, false, 1)
      str = string.format("%s/%s", no_powerup and "No powerup" or "Big", Yoshi_riding_flag and "Yoshi" or "No Yoshi")
      draw.text(xmin, draw.AR_y*ymax + draw.font_height(), str, COLOUR.warning, true, false, 1)
    end
  end

  -- Sprites
  if OPTIONS.display_sprite_vanish_area then
    local is_vertical = read_screens() == "Vertical"
    local ydeath = is_vertical and Camera_y + 320 or 432
    local _, y_screen = screen_coordinates(0, ydeath, Camera_x, Camera_y)

    if draw.AR_y*y_screen < draw.Buffer_height + draw.Border_bottom then
      draw.line(-draw.Border_left, y_screen, draw.Screen_width + draw.Border_right, y_screen, 2, COLOUR.weak)
      local str = string.format("Sprite %s: %d", is_vertical and "\"death\"" or "death", ydeath)
      draw.text(-draw.Border_left, draw.AR_y*y_screen, str, COLOUR.weak, true)
    end
  end
end


local function draw_blocked_status(x_text, y_text, player_blocked_status, x_speed, y_speed)
  local bitmap_width  = 14
  local bitmap_height = 20
  local block_str = "Block:"
  local str_len = #(block_str)
  local xoffset = x_text + str_len*draw.font_width()
  local yoffset = y_text
  local color_line = draw.change_transparency(COLOUR.warning, draw.Text_max_opacity * draw.Text_opacity)

  local bitmap, pal = BITMAPS.player_blocked_status, Palettes_adjusted.player_blocked_status
  for i = 1, 1 do
    bitmap:draw(xoffset, yoffset, pal)
  end

  local blocked_status = {}
  local was_boosted = false

  if bit.test(player_blocked_status, 0) then  -- Right
    draw.line(xoffset + bitmap_width - 2, yoffset, xoffset + bitmap_width - 2, yoffset + bitmap_height - 2, 1, color_line)
    if x_speed < 0 then was_boosted = true end
  end

  if bit.test(player_blocked_status, 1) then  -- Left
    draw.line(xoffset, yoffset, xoffset, yoffset + bitmap_height - 2, 1, color_line)
    if x_speed > 0 then was_boosted = true end
  end

  if bit.test(player_blocked_status, 2) then  -- Down
    draw.line(xoffset, yoffset + bitmap_height - 2, xoffset + bitmap_width - 2, yoffset + bitmap_height - 2, 1, color_line)
  end

  if bit.test(player_blocked_status, 3) then  -- Up
    draw.line(xoffset, yoffset, xoffset + bitmap_width - 2, yoffset, 1, color_line)
    if y_speed > 6 then was_boosted = true end
  end

  if bit.test(player_blocked_status, 4) then  -- Middle
    gui.crosshair(xoffset + floor(bitmap_width/2), yoffset + floor(bitmap_height/2),
      floor(math.min(bitmap_width/2, bitmap_height/2)), color_line)
  end

  draw.text(x_text, y_text, block_str, COLOUR.text, was_boosted and COLOUR.warning_bg or nil)

end


-- displays player's hitbox
local function player_hitbox(x, y, is_ducking, powerup, transparency_level, palette)
  -- Colour settings
  local interaction_bg, mario_line, mario_bg, interaction_points_palette
  interaction_bg = draw.change_transparency(COLOUR.interaction_bg, transparency_level)
  mario_line = draw.change_transparency(COLOUR.mario, transparency_level)

  if not palette then
    if transparency_level == 1 then
      interaction_points_palette = DBITMAPS.interaction_points_palette
    else
      interaction_points_palette = draw.copy_palette(DBITMAPS.interaction_points_palette)
      interaction_points_palette:adjust_transparency(floor(transparency_level*256))
    end
  else
    interaction_points_palette = palette
  end

  -- don't use Camera_x/y midframe, as it's an old value
  local x_screen, y_screen = screen_coordinates(x, y, s16("WRAM", WRAM.camera_x), s16("WRAM", WRAM.camera_y))
  local is_small = is_ducking ~= 0 or powerup == 0
  local hitbox_type = 2*(Yoshi_riding_flag and 1 or 0) + (is_small and 0 or 1) + 1

  local left_side = X_INTERACTION_POINTS.left_side
  local right_side = X_INTERACTION_POINTS.right_side
  local head = Y_INTERACTION_POINTS[hitbox_type].head
  local foot = Y_INTERACTION_POINTS[hitbox_type].foot

  local hitbox_offsets = smw.PLAYER_HITBOX[hitbox_type]
  local xoff = hitbox_offsets.xoff
  local yoff = hitbox_offsets.yoff
  local width = hitbox_offsets.width
  local height = hitbox_offsets.height

  -- background for block interaction
  draw.box(x_screen + left_side, y_screen + head, x_screen + right_side, y_screen + foot,
      2, interaction_bg, interaction_bg)

  -- Collision with sprites
  if OPTIONS.display_player_hitbox then
    local mario_bg = (not Yoshi_riding_flag and COLOUR.mario_bg) or COLOUR.mario_mounted_bg
    draw.rectangle(x_screen + xoff, y_screen + yoff, width, height, mario_line, mario_bg)
  end

  -- interaction points (collision with blocks)
  if OPTIONS.display_interaction_points then

    local color = COLOUR.interaction

    if not OPTIONS.display_player_hitbox then
      draw.box(x_screen + left_side , y_screen + head, x_screen + right_side, y_screen + foot,
        2, COLOUR.interaction_nohitbox, COLOUR.interaction_nohitbox_bg)
    end

    gui.bitmap_draw(draw.AR_x*x_screen, draw.AR_y*y_screen,
    DBITMAPS.interaction_points[hitbox_type], interaction_points_palette) -- lsnes
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
  local cape_interaction = u8("WRAM", WRAM.cape_interaction)
  if cape_interaction == 0 then return end

  local cape_x = u16("WRAM", WRAM.cape_x)
  local cape_y = u16("WRAM", WRAM.cape_y)

  local cape_x_screen, cape_y_screen = screen_coordinates(cape_x, cape_y, Camera_x, Camera_y)
  local cape_left = -2
  local cape_right = 0x12
  local cape_up = 0x01
  local cape_down = 0x11
  local cape_middle = 0x08
  local block_interaction_cape = (spin_direction < 0 and cape_left + 4) or cape_right - 4
  local active_frame_sprites = Real_frame%2 == 1  -- active iff the cape can hit a sprite
  local active_frame_blocks  = Real_frame%2 == (spin_direction < 0 and 0 or 1)  -- active iff the cape can hit a block

  if active_frame_sprites then bg_color = COLOUR.cape_bg else bg_color = -1 end
  draw.box(cape_x_screen + cape_left, cape_y_screen + cape_up, cape_x_screen + cape_right, cape_y_screen + cape_down, 2, COLOUR.cape, bg_color)

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
    if u8("WRAM", WRAM.sprite_status + id) == 0x0b then
      slot = id
      break
    end
  end
  if not slot then return false end

  -- sprite properties
  local ini_x = luap.signed16(256*u8("WRAM", WRAM.sprite_x_high + slot) + u8("WRAM", WRAM.sprite_x_low + slot))
  local ini_y = luap.signed16(256*u8("WRAM", WRAM.sprite_y_high + slot) + u8("WRAM", WRAM.sprite_y_low + slot))
  local ini_y_sub = u8("WRAM", WRAM.sprite_y_sub + slot)

  -- Sprite clipping vs objects
  local clip_obj = bit.band(u8("WRAM", WRAM.sprite_1_tweaker + slot), 0xf)
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
        local x, y = math.floor(positions[1]/16), math.floor(positions[2]/16)
        draw.message(fmt("Duplication prediction: %d, %d", x, y), 1000000)

        local xs, ys = screen_coordinates(positions[1] + 7, positions[2], Camera_x, Camera_y)
        draw.Font = false
        draw.text(draw.AR_x*xs, draw.AR_y*ys - 4, fmt("%s duplication", dup_status),
          COLOUR.warning, COLOUR.warning_bg, true, false, 0.5, 1.0)
        break
      end

    end
  end
end


local function player()
  -- Font
  draw.Font = false
  draw.Text_opacity = 1.0
  draw.Bg_opacity = 1.0

  -- Reads WRAM
  local x = Player_x
  local y = Player_y
  local previous_x = s16("WRAM", WRAM.previous_x)
  local previous_y = s16("WRAM", WRAM.previous_y)
  local x_sub = u8("WRAM", WRAM.x_sub)
  local y_sub = u8("WRAM", WRAM.y_sub)
  local x_speed = s8("WRAM", WRAM.x_speed)
  local x_subspeed = u8("WRAM", WRAM.x_subspeed)
  local y_speed = s8("WRAM", WRAM.y_speed)
  local p_meter = u8("WRAM", WRAM.p_meter)
  local take_off = u8("WRAM", WRAM.take_off)
  local powerup = Player_powerup
  local direction = u8("WRAM", WRAM.direction)
  local cape_spin = u8("WRAM", WRAM.cape_spin)
  local cape_fall = u8("WRAM", WRAM.cape_fall)
  local flight_animation = u8("WRAM", WRAM.flight_animation)
  local diving_status = s8("WRAM", WRAM.diving_status)
  local player_blocked_status = u8("WRAM", WRAM.player_blocked_status)
  local item_box = u8("WRAM", WRAM.item_box)
  local is_ducking = u8("WRAM", WRAM.is_ducking)
  local on_ground = u8("WRAM", WRAM.on_ground)
  local spinjump_flag = u8("WRAM", WRAM.spinjump_flag)
  local can_jump_from_water = u8("WRAM", WRAM.can_jump_from_water)
  local carrying_item = u8("WRAM", WRAM.carrying_item)
  local pose_turning = u8("WRAM", WRAM.player_pose_turning)
  local scroll_timer = u8("WRAM", WRAM.camera_scroll_timer)
  local vertical_scroll_flag_header = u8("WRAM", WRAM.vertical_scroll_flag_header)
  local vertical_scroll_enabled = u8("WRAM", WRAM.vertical_scroll_enabled)

  -- Prediction
  local next_x = floor((256*x + x_sub + 16*x_speed)/256)
  local next_y = floor((256*y + y_sub + 16*y_speed)/256)

  -- Transformations
  if direction == 0 then direction = LEFT_ARROW else direction = RIGHT_ARROW end
  local x_sub_simple, y_sub_simple -- = x_sub, y_sub
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
  widget:set_property("player", "display_flag", OPTIONS.display_player_info)
  if OPTIONS.display_player_info then
    local i = 0
    local delta_x = draw.font_width()
    local delta_y = draw.font_height()
    local table_x = draw.AR_x * widget:get_property("player", "x")
    local table_y = draw.AR_y * widget:get_property("player", "y")

    draw.text(table_x, table_y + i*delta_y, fmt("Meter (%03d, %02d) %s", p_meter, take_off, direction))
    draw.text(table_x + 18*delta_x, table_y + i*delta_y, fmt(" %+d", spin_direction),
    (is_spinning and COLOUR.text) or COLOUR.weak)

    if pose_turning ~= 0 then
      gui.text(draw.AR_x * (Player_x_screen + 6), draw.AR_y * (Player_y_screen - 4), pose_turning,
      COLOUR.warning2, 0x40000000)
    end
    i = i + 1

    draw.text(table_x, table_y + i*delta_y, fmt("Pos (%+d.%s, %+d.%s)", x, x_sub_simple, y, y_sub_simple))
    i = i + 1

    draw.text(table_x, table_y + i*delta_y, fmt("Speed (%+d(%d.%02.0f), %+d)", x_speed, x_speed_int, x_speed_frac, y_speed))
    i = i + 1

    if is_caped then
      local cape_gliding_index = u8("WRAM", WRAM.cape_gliding_index)
      local diving_status_timer = u8("WRAM", WRAM.diving_status_timer)
      local action = smw.FLIGHT_ACTIONS[cape_gliding_index] or "bug!"
      
      -- TODO: better name for this "glitched" state
      if cape_gliding_index == 3 and y_speed > 0 then
        action = "*up*"
      end

      draw.text(table_x, table_y + i*delta_y, fmt("Cape (%.2d, %.2d)/(%d, %d)", cape_spin, cape_fall, flight_animation, diving_status), COLOUR.cape)
      i = i + 1
      if flight_animation ~= 0 then
        draw.text(table_x + 10*draw.font_width(), table_y + i*delta_y, action .. " ", COLOUR.cape)
        draw.text(table_x + 15*draw.font_width(), table_y + i*delta_y, diving_status_timer, diving_status_timer <= 1 and COLOUR.warning or COLOUR.cape)
        i = i + 1
      end
    end

    local x_txt = draw.text(table_x, table_y + i*delta_y, fmt("Camera (%d, %d)", Camera_x, Camera_y))
    if scroll_timer ~= 0 then x_txt = draw.text(x_txt, table_y + i*delta_y, 16 - scroll_timer, COLOUR.warning) end
    draw.font["Uzebox6x8"](table_x + 8*delta_x, table_y + (i+1)*delta_y, string.format("%d.%x", math.floor(Camera_x/16), Camera_x%16), 0xffffff, -1, 0) -- TODO remove
   if vertical_scroll_flag_header ~=0 and vertical_scroll_enabled ~= 0 then
      draw.text(x_txt, table_y + i*delta_y, vertical_scroll_enabled, COLOUR.warning2)
    end
    i = i + 1

    draw_blocked_status(table_x, table_y + i*delta_y, player_blocked_status, x_speed, y_speed) 
    i = i + 1

    -- Wings timers is the same as the cape
    if (not is_caped and cape_fall ~= 0) then
      draw.text(table_x, table_y + i*delta_y, fmt("Wings: %.2d", cape_fall), COLOUR.text)
      i = i + 1
    end
  end

  if OPTIONS.display_static_camera_region then
    Display.show_player_point_position = true

    -- Horizontal scroll
    local left_cam, right_cam = u16("WRAM", WRAM.camera_left_limit), u16("WRAM", WRAM.camera_right_limit)
    local center_cam = math.floor((left_cam + right_cam)/2)
    draw.box(left_cam, 0, right_cam, 224, COLOUR.static_camera_region, COLOUR.static_camera_region)
    draw.line(center_cam, 0, center_cam, 224, 2, "black")
    draw.text(draw.AR_x*left_cam, 0, left_cam, COLOUR.text, 0x400020, false, false, 1, 0)
    draw.text(draw.AR_x*right_cam, 0, right_cam, COLOUR.text, 0x400020)

    -- Vertical scroll
    if vertical_scroll_flag_header ~= 0 then
      draw.box(0, 100, 255, 124, COLOUR.static_camera_region, COLOUR.static_camera_region) -- FIXME for PAL
    end
  end

  -- Mario boost indicator
  Previous.x = x
  Previous.y = y
  Previous.next_x = next_x
  if OPTIONS.register_player_position_changes and Registered_addresses.mario_position ~= "" then
    local x_screen, y_screen = Player_x_screen, Player_y_screen
    gui.text(draw.AR_x*(x_screen + 4 - #Registered_addresses.mario_position), draw.AR_y*(y_screen + Y_INTERACTION_POINTS[Yoshi_riding_flag and 3 or 1].foot + 4),
    Registered_addresses.mario_position, COLOUR.warning, 0x40000000)

    -- draw hitboxes
    Midframe_context:run()
  end

  -- shows hitbox and interaction points for player
  if OPTIONS.display_cape_hitbox then
    cape_hitbox(spin_direction)
  end
  if OPTIONS.display_player_hitbox or OPTIONS.display_interaction_points then
    player_hitbox(x, y, is_ducking, powerup, 1)
  end

  -- Shows where Mario is expected to be in the next frame, if he's not boosted or stopped
  if OPTIONS.display_debug_player_extra then
    player_hitbox(next_x, next_y, is_ducking, powerup, 0.3)
  end

end


local function extended_sprites()
  -- Font
  draw.Font = false
  local height = draw.font_height()

  local y_pos = draw.AR_y*144
  local counter = 0
  for id = 0, SMW.extended_sprite_max - 1 do
    local extspr_number = u8("WRAM", WRAM.extspr_number + id)

    if extspr_number ~= 0 then
     -- Reads WRAM addresses
     local x = 256*u8("WRAM", WRAM.extspr_x_high + id) + u8("WRAM", WRAM.extspr_x_low + id)
     local y = 256*u8("WRAM", WRAM.extspr_y_high + id) + u8("WRAM", WRAM.extspr_y_low + id)
     local sub_x = bit.lrshift(u8("WRAM", WRAM.extspr_subx + id), 4)
     local sub_y = bit.lrshift(u8("WRAM", WRAM.extspr_suby + id), 4)
     local x_speed = s8("WRAM", WRAM.extspr_x_speed + id)
     local y_speed = s8("WRAM", WRAM.extspr_y_speed + id)
     local extspr_table = u8("WRAM", WRAM.extspr_table + id)
     local extspr_table2 = u8("WRAM", WRAM.extspr_table2 + id)

     -- Reduction of useless info
     local special_info = ""
     if OPTIONS.display_debug_extended_sprite and (extspr_table ~= 0 or extspr_table2 ~= 0) then
      special_info = fmt("(%x, %x) ", extspr_table, extspr_table2)
     end

     -- x speed for Fireballs
     if extspr_number == 5 then x_speed = 16*x_speed end

     if OPTIONS.display_extended_sprite_info then
      draw.text(draw.Buffer_width + draw.Border_right, y_pos + counter*height, fmt("#%.2d %.2x %s(%d.%x(%+.2d), %d.%x(%+.2d))",
      id, extspr_number, special_info, x, sub_x, x_speed, y, sub_y, y_speed),
      COLOUR.extended_sprites, true, false)
     end

     if OPTIONS.display_extended_sprite_hitbox and (OPTIONS.display_debug_extended_sprite or not
     UNINTERESTING_EXTENDED_SPRITES[extspr_number] or (extspr_number == 1 and extspr_table2 == 0xf))
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
        color_bg = (Real_frame - id)%4 == 0 and COLOUR.special_extended_sprite_bg or -1
      end
      draw.rectangle(x_screen+xoff, y_screen+yoff, xrad, yrad, color_line, color_bg) -- regular hitbox

      -- Experimental: attempt to show Mario's fireball vs sprites
      -- this is likely wrong in some situation, but I can't solve this yet
      if extspr_number == 5 or extspr_number == 1 then
        local xoff_spr = x_speed >= 0 and -5 or  1
        local yoff_spr = - floor(y_speed/16) - 4 + (y_speed >= -40 and 1 or 0)
        local yrad_spr = y_speed >= -40 and 19 or 20
        draw.rectangle(x_screen + xoff_spr, y_screen + yoff_spr, 12, yrad_spr, color_line, color_bg)

      -- Yoshi fireball vs cape
      elseif extspr_number == 0x11 then
        draw.rectangle(x_screen + 3, y_screen - 0x80 + 0x10, 1, 0xbd - 0x80 - 0x10, 0xff)
        draw.rectangle(x_screen + 3, y_screen, 1, 0x80, 0xff)
      end
     end

     counter = counter + 1
    end
  end

  if OPTIONS.display_extended_sprite_info then
    draw.Font = "Uzebox6x8"
    local x_pos, y_pos, length = draw.text(draw.Buffer_width + draw.Border_right, y_pos, fmt("Ext. spr:%2d ", counter), COLOUR.weak, true, false, 0.0, 1.0)

    if u8("WRAM", WRAM.spinjump_flag) ~= 0 and Player_powerup == 3 then
     local fireball_timer = u8("WRAM", WRAM.spinjump_fireball_timer)
     draw.text(x_pos - length - LSNES_FONT_WIDTH, y_pos, fmt("%d %s",
     fireball_timer%16, bit.test(fireball_timer, 4) and RIGHT_ARROW or LEFT_ARROW), COLOUR.extended_sprites, true, false, 1.0, 1.0)
    end
  end
end


local function cluster_sprites()
  if u8("WRAM", WRAM.cluspr_flag) == 0 then return end

  -- Font
  draw.Text_opacity = 1.0
  draw.Font = "Uzebox6x8"
  local height = draw.font_height()
  local x_pos, y_pos = draw.AR_x*90, draw.AR_y*67 -- lsnes
  local counter = 0

  if OPTIONS.display_debug_cluster_sprite then
    draw.text(x_pos, y_pos, "Cluster Spr.", COLOUR.weak)
    counter = counter + 1
  end

  local reappearing_boo_counter

  for id = 0, SMW.cluster_sprite_max - 1 do
    local clusterspr_number = u8("WRAM", WRAM.cluspr_number + id)

    if clusterspr_number ~= 0 then
      if not HITBOX_CLUSTER_SPRITE[clusterspr_number] then
        print("Warning: wrong cluster sprite number:", clusterspr_number)  -- should not happen without cheats
        return
      end

      -- Reads WRAM addresses
      local x = luap.signed16(256*u8("WRAM", WRAM.cluspr_x_high + id) + u8("WRAM", WRAM.cluspr_x_low + id))
      local y = luap.signed16(256*u8("WRAM", WRAM.cluspr_y_high + id) + u8("WRAM", WRAM.cluspr_y_low + id))
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
      local invincibility_hitbox = nil

      if OPTIONS.display_debug_cluster_sprite then
        table_1 = u8("WRAM", WRAM.cluspr_table_1 + id)
        table_2 = u8("WRAM", WRAM.cluspr_table_2 + id)
        table_3 = u8("WRAM", WRAM.cluspr_table_3 + id)
        draw.text(x_pos, y_pos + counter*height, fmt("#%d(%d): (%d, %d) %d, %d, %d",
                id, clusterspr_number, x, y, table_1, table_2, table_3), color)
        counter = counter + 1
      end

      -- Case analysis
      if clusterspr_number == 3 or clusterspr_number == 8 then
        clusterspr_timer = u8("WRAM", WRAM.cluspr_timer + id)
        if clusterspr_timer ~= 0 then special_info = " " .. clusterspr_timer end
      elseif clusterspr_number == 6 then
        table_1 = table_1 or u8("WRAM", WRAM.cluspr_table_1 + id)
        if table_1 >= 111 or (table_1 < 31 and table_1 >= 16) then
          yoff = yoff + 17
        elseif table_1 >= 103 or table_1 < 16 then
          invincibility_hitbox = true
        elseif table_1 >= 95 or (table_1 < 47 and table_1 >= 31) then
          yoff = yoff + 16
        end
      elseif clusterspr_number == 7 then
        reappearing_boo_counter = reappearing_boo_counter or u8("WRAM", WRAM.reappearing_boo_counter)
        invincibility_hitbox = (reappearing_boo_counter > 0xde) or (reappearing_boo_counter < 0x3f)
        special_info = " " .. reappearing_boo_counter
      end

      -- Hitbox and sprite id
      color = invincibility_hitbox and COLOUR.weak or color
      color_bg = (invincibility_hitbox and -1) or (oscillation and color_bg) or -1
      if OPTIONS.display_cluster_sprite_hitbox then
        draw.rectangle(x_screen + xoff, y_screen + yoff, xrad, yrad, color, color_bg)
      end
      if OPTIONS.display_cluster_sprite_info then
        draw.text(draw.AR_x*(x_screen + xoff) + xrad, draw.AR_y*(y_screen + yoff), special_info and id .. special_info or id,
        color, false, false, 0.5, 1.0)
      end
    end
  end
end


local function minor_extended_sprites()
  -- Font
  draw.Text_opacity = 1.0
  draw.Font = "Uzebox6x8"
  local height = draw.font_height()
  local x_pos, y_pos = 0, draw.Buffer_height - height*SMW.minor_extended_sprite_max
  local counter = 0

  for id = 0, SMW.minor_extended_sprite_max - 1 do
    local minorspr_number = u8("WRAM", WRAM.minorspr_number + id)

    if minorspr_number ~= 0 then
      -- Reads WRAM addresses
      local x = luap.signed16(256*u8("WRAM", WRAM.minorspr_x_high + id) + u8("WRAM", WRAM.minorspr_x_low + id))
      local y = luap.signed16(256*u8("WRAM", WRAM.minorspr_y_high + id) + u8("WRAM", WRAM.minorspr_y_low + id))
      local xspeed, yspeed = s8("WRAM", WRAM.minorspr_xspeed + id), s8("WRAM", WRAM.minorspr_yspeed + id)
      local x_sub, y_sub = u8("WRAM", WRAM.minorspr_x_sub + id), u8("WRAM", WRAM.minorspr_y_sub + id)
      local timer = u8("WRAM", WRAM.minorspr_timer + id)

      -- Only sprites 1 and 10 use the higher byte
      local x_screen, y_screen = screen_coordinates(x, y, Camera_x, Camera_y)
      if minorspr_number ~= 1 and minorspr_number ~= 10 then  -- Boo stream and Piece of brick block
        x_screen = x_screen%0x100
        y_screen = y_screen%0x100
      end

      -- Draw next to the sprite
      if OPTIONS.display_minor_extended_sprite_info then
        local text = "#" .. id .. (timer ~= 0 and (" " .. timer) or "")
        draw.text(draw.AR_x*(x_screen + 8), draw.AR_y*(y_screen + 4), text, COLOUR.minor_extended_sprites, false, false, 0.5, 1.0)
      end
      if OPTIONS.display_minor_extended_sprite_hitbox and minorspr_number == 10 then  -- Boo stream
        draw.rectangle(x_screen + 4, y_screen + 4, 8, 8, COLOUR.minor_extended_sprites, COLOUR.sprites_bg)
      end

      -- Draw in the table
      if OPTIONS.display_debug_minor_extended_sprite then
        draw.text(x_pos, y_pos + counter*height, fmt("#%d(%d): %d.%x(%d), %d.%x(%d)",
          id, minorspr_number, x, floor(x_sub/16), xspeed, y, floor(y_sub/16), yspeed), COLOUR.minor_extended_sprites)
      end
      counter = counter + 1
    end
  end

  if OPTIONS.display_debug_minor_extended_sprite then
    draw.text(x_pos, y_pos - height, "Minor Ext Spr:" .. counter, COLOUR.weak)
  end
end


local function bounce_sprite_info()
  if not OPTIONS.display_bounce_sprite_info then return end

  -- Debug info
  local x_txt, y_txt = draw.AR_x*90, draw.AR_y*37
  if OPTIONS.display_debug_bounce_sprite then
    draw.Font = "snes9xluasmall"
    draw.text(x_txt, y_txt, "Bounce Spr.", COLOUR.weak)
  end

  -- Font
  draw.Font = "Uzebox6x8"
  local height = draw.font_height()

  local stop_id = (u8("WRAM", WRAM.bouncespr_last_id) - 1)%SMW.bounce_sprite_max
  for id = 0, SMW.bounce_sprite_max - 1 do
    local bounce_sprite_number = u8("WRAM", WRAM.bouncespr_number + id)
    if bounce_sprite_number ~= 0 then
      local x = luap.signed16(256*u8("WRAM", WRAM.bouncespr_x_high + id) + u8("WRAM", WRAM.bouncespr_x_low + id))
      local y = luap.signed16(256*u8("WRAM", WRAM.bouncespr_y_high + id) + u8("WRAM", WRAM.bouncespr_y_low + id))
      local bounce_timer = u8("WRAM", WRAM.bouncespr_timer + id)

      if OPTIONS.display_debug_bounce_sprite then
        draw.text(x_txt, y_txt + height*(id + 1), fmt("#%d:%d (%d, %d)", id, bounce_sprite_number, x, y))
      end

      if OPTIONS.display_bounce_sprite_info then
        local x_screen, y_screen = screen_coordinates(x, y, Camera_x, Camera_y)
        x_screen, y_screen = draw.AR_x*(x_screen + 8), draw.AR_y*y_screen

        local color = id == stop_id and COLOUR.warning or COLOUR.text
        draw.text(x_screen , y_screen, fmt("#%d:%d", id, bounce_timer), color, false, false, 0.5)  -- timer

        -- Turn blocks
        if bounce_sprite_number == 7 then
          turn_block_timer = u8("WRAM", WRAM.turn_block_timer + id)
          draw.text(x_screen, y_screen + height, turn_block_timer, color, false, false, 0.5)
        end
      end
    end
  end
end


local function quake_sprite_info()
  if not OPTIONS.display_quake_sprite_info then return end
  draw.Font = "Uzebox6x8"
  local font_height = draw.font_height()

  local hitbox_tab = smw.HITBOX_QUAKE_SPRITE
  for id = 0, 3 do
    local sprite_number = u8("WRAM", 0x16cd + id)
    local hitbox = hitbox_tab[sprite_number]

    if hitbox then
      local x = luap.signed16(256*u8("WRAM", 0x16d5 + id) + u8("WRAM", 0x16d1 + id))
      local y = luap.signed16(256*u8("WRAM", 0x16dd + id) + u8("WRAM", 0x16d9 + id))
      local quake_timer = u8("WRAM", 0x18f8 + id)
      local interact = quake_timer < 3 and COLOUR.quake_sprite_bg or -1

      draw.rectangle(x - Camera_x + hitbox.xoff, y - Camera_y + hitbox.yoff, hitbox.width, hitbox.height,
        COLOUR.quake_sprite, interact)
      draw.text(draw.AR_x*(x - Camera_x), draw.AR_x*(y - Camera_y), "#" .. id)
      draw.text(draw.Buffer_width, draw.Buffer_height + id*font_height, fmt("#%d %d (%d, %d) %d",
        id, sprite_number, x, y, quake_timer), COLOUR.quake_sprite, COLOUR.background)
    end
  end
end


local function scan_sprite_info(lua_table, slot)
  local t = lua_table[slot]
  if not t then error"Wrong Sprite table" end

  t.status = u8("WRAM", WRAM.sprite_status + slot)
  if t.status == 0 then
    return -- returns if the slot is empty
  end

  local x = 256*u8("WRAM", WRAM.sprite_x_high + slot) + u8("WRAM", WRAM.sprite_x_low + slot)
  local y = 256*u8("WRAM", WRAM.sprite_y_high + slot) + u8("WRAM", WRAM.sprite_y_low + slot)
  t.x_sub = u8("WRAM", WRAM.sprite_x_sub + slot)
  t.y_sub = u8("WRAM", WRAM.sprite_y_sub + slot)
  t.number = u8("WRAM", WRAM.sprite_number + slot)
  t.stun = u8("WRAM", WRAM.sprite_stun_timer + slot)
  t.x_speed = s8("WRAM", WRAM.sprite_x_speed + slot)
  t.y_speed = s8("WRAM", WRAM.sprite_y_speed + slot)
  t.contact_mario = u8("WRAM", WRAM.sprite_player_contact + slot)
  t.sprite_being_eaten_flag = u8("WRAM", WRAM.sprite_being_eaten_flag + slot) ~= 0
  t.underwater = u8("WRAM", WRAM.sprite_underwater + slot)
  t.x_offscreen = s8("WRAM", WRAM.sprite_x_offscreen + slot)
  t.y_offscreen = s8("WRAM", WRAM.sprite_y_offscreen + slot)
  t.behind_scenery = u8("WRAM", WRAM.sprite_behind_scenery + slot)

  -- Transform some read values into intelligible content
  t.x = luap.signed16(x)
  t.y = luap.signed16(y)
  t.x_screen, t.y_screen = screen_coordinates(t.x, t.y, Camera_x, Camera_y)

  if OPTIONS.display_debug_sprite_extra or ((t.status < 0x8 and t.status > 0xb) or stun ~= 0) then
    t.table_special_info = fmt("(%d %d) ", t.status, t.stun)
  else
    t.table_special_info = ""
  end

  t.oscillation_flag = bit.test(u8("WRAM", WRAM.sprite_4_tweaker + slot), 5) or OSCILLATION_SPRITES[t.number]

  -- Sprite clipping vs mario and sprites
  local boxid = bit.band(u8("WRAM", WRAM.sprite_2_tweaker + slot), 0x3f)  -- This is the type of box of the sprite
  t.hitbox_id = boxid
  t.hitbox_xoff = HITBOX_SPRITE[boxid].xoff
  t.hitbox_yoff = HITBOX_SPRITE[boxid].yoff
  t.hitbox_width = HITBOX_SPRITE[boxid].width
  t.hitbox_height = HITBOX_SPRITE[boxid].height

  -- Sprite clipping vs objects
  local clip_obj = bit.band(u8("WRAM", WRAM.sprite_1_tweaker + slot), 0xf)  -- type of hitbox for blocks
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
  if (not t.oscillation_flag) and (Real_frame - slot)%2 == 1 then t.background_color = -1 end

  t.sprite_middle = t.x_screen + t.hitbox_xoff + floor(t.hitbox_width/2)
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
  local background_color = alive_status and t.background_color or -1

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
    draw.line(x_screen + xpt_right, y_screen + ypt_right, x_screen + xpt_right - size, y_screen + ypt_right, 2, color) -- right
    draw.line(x_screen + xpt_left, y_screen + ypt_left, x_screen + xpt_left + size, y_screen + ypt_left, 2, color)  -- left
    draw.line(x_screen + xpt_down, y_screen + ypt_down, x_screen + xpt_down, y_screen + ypt_down - size, 2, color) -- down
    draw.line(x_screen + xpt_up, y_screen + ypt_up, x_screen + xpt_up, y_screen + ypt_up + size, 2, color)  -- up
  end

  -- Sprite vs sprite hitbox
  if OPTIONS.display_sprite_vs_sprite_hitbox then
    if u8("WRAM", WRAM.sprite_sprite_contact + slot) == 0
    and u8("WRAM", WRAM.sprite_being_eaten_flag + slot) == 0
    and bit.testn(u8("WRAM", WRAM.sprite_5_tweaker + slot), 3) then

      local boxid2 = bit.band(u8("WRAM", WRAM.sprite_2_tweaker + slot), 0x0f)
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
local function sprite_tweaker_editor(slot, x, y)
  draw.Font = "Uzebox6x8"
  
  local t = Sprites_info[slot]
  local info_color = t.info_color
  local y_screen = t.y_screen
  local xoff = t.hitbox_xoff
  local yoff = t.hitbox_yoff

  local width, height = draw.font_width(), draw.font_height()
  local x_ini = x or draw.AR_x*t.sprite_middle - 4*draw.font_width()
  local y_ini = y or draw.AR_y*(y_screen + yoff) - 7*height
  local x_txt, y_txt = x_ini, y_ini

  -- Tweaker viewer/editor
  if mouse_onregion(x_ini, y_ini, x_ini + 8*width - 1, y_ini + 6*height - 1) then
    local x_select = floor((User_input.mouse_x - x_ini)/width)
    local y_select = floor((User_input.mouse_y - y_ini)/height)

    -- if some cell is selected
    if not (x_select < 0 or x_select > 7 or y_select < 0 or y_select > 5) then
      local color = Cheat.allow_cheats and COLOUR.warning or COLOUR.text
      local tweaker_tab = smw.SPRITE_TWEAKERS_INFO
      local message = tweaker_tab[y_select + 1][x_select + 1]

      draw.text(x_txt, y_txt + 6*height, message, color, true)
      gui.solidrectangle(x_ini + x_select*width, y_ini + y_select*height, width, height, color)

      if Cheat.allow_cheats then
        Cheat.sprite_tweaker_selected_id = slot
        Cheat.sprite_tweaker_selected_x = x_select
        Cheat.sprite_tweaker_selected_y = y_select
      end
    end
  else
    Cheat.sprite_tweaker_selected_id = nil
    Cheat.sprite_tweaker_selected_x = nil
    Cheat.sprite_tweaker_selected_y = nil
  end

  local tweaker_1 = u8("WRAM", WRAM.sprite_1_tweaker + slot)
  draw.over_text(x_txt, y_txt, tweaker_1, "sSjJcccc", COLOUR.weak, info_color)
  y_txt = y_txt + height

  local tweaker_2 = u8("WRAM", WRAM.sprite_2_tweaker + slot)
  draw.over_text(x_txt, y_txt, tweaker_2, "dscccccc", COLOUR.weak, info_color)
  y_txt = y_txt + height

  local tweaker_3 = u8("WRAM", WRAM.sprite_3_tweaker + slot)
  draw.over_text(x_txt, y_txt, tweaker_3, "lwcfpppg", COLOUR.weak, info_color)
  y_txt = y_txt + height

  local tweaker_4 = u8("WRAM", WRAM.sprite_4_tweaker + slot)
  draw.over_text(x_txt, y_txt, tweaker_4, "dpmksPiS", COLOUR.weak, info_color)
  y_txt = y_txt + height

  local tweaker_5 = u8("WRAM", WRAM.sprite_5_tweaker + slot)
  draw.over_text(x_txt, y_txt, tweaker_5, "dnctswye", COLOUR.weak, info_color)
  y_txt = y_txt + height

  local tweaker_6 = u8("WRAM", WRAM.sprite_6_tweaker + slot)
  draw.over_text(x_txt, y_txt, tweaker_6, "wcdj5sDp", COLOUR.weak, info_color)
end


local spriteMiscTables = {}

local sprite_images = {}
for id = 0, 0xff do
  local a, b = gui.image.load_png(string.format("sprite_%.2X.png", id), GLOBAL_SMW_TAS_PARENT_DIR .. "images/sprites/")
  sprite_images[id] = a
end

spriteMiscTables.slot = {}

local used = {}
function spriteMiscTables:new(slot)
  if self.slot[slot] then
    error("Slot " .. slot .. " already exists!")
    return
  end

  local obj = {}
  setmetatable(obj, self)
  obj.xpos = 64*(slot%3)
  obj.ypos = 64*math.floor(slot/3)
  widget:new(string.format("spriteMiscTables.slot[%d]", slot), obj.xpos, obj.ypos, tostring(slot))
  widget:set_property(string.format("spriteMiscTables.slot[%d]", slot), "display_flag", true)

  -- FIXME test
  local t = {
    WRAM.sprite_phase,            WRAM.sprite_misc_1504,        WRAM.sprite_misc_1510,
    WRAM.sprite_misc_151c,        WRAM.sprite_misc_1528,        WRAM.sprite_misc_1534,
    WRAM.sprite_stun_timer,       WRAM.sprite_player_contact,   WRAM.sprite_misc_1558,
    WRAM.sprite_sprite_contact,   WRAM.sprite_animation_timer,  WRAM.sprite_horizontal_direction,
    WRAM.sprite_blocked_status,   WRAM.sprite_misc_1594,        WRAM.sprite_x_offscreen,
    WRAM.sprite_misc_15ac,        WRAM.sprite_slope,            WRAM.sprite_misc_15c4,
    WRAM.sprite_being_eaten_flag, WRAM.sprite_misc_15dc,        WRAM.sprite_OAM_index,
    WRAM.sprite_YXPPCCCT,         WRAM.sprite_misc_1602,        WRAM.sprite_misc_160e,
    WRAM.sprite_index_to_level,   WRAM.sprite_misc_1626,        WRAM.sprite_behind_scenery,
    WRAM.sprite_misc_163e,        WRAM.sprite_underwater,       WRAM.sprite_y_offscreen, 
    WRAM.sprite_misc_187b,        WRAM.sprite_disable_cape
  }

  for i, address in ipairs(t) do
    memory.registerread("WRAM", address + slot, function()
      local number = memory.readbyte("WRAM", 0x9e + slot);
      used[number] = used[number] or {};
      used[number][address] = true;
    end)
    --[[
    memory.registerwrite("WRAM", address + slot, function()
      local number = memory.readbyte("WRAM", 0x9e + slot);
      used[number] = used[number] or {};
      used[number][address] = true;
    end)--]]
  end
  
  
  self.slot[slot] = obj
  return obj
end

function spriteMiscTables:destroy(slot)
  self.slot[slot] = nil
  widget:set_property(string.format("spriteMiscTables.slot[%d]", slot), "display_flag", false)
end

local function sprite_table_viewer(x, y, slot)
  local sprite = Sprites_info[slot]
  local info_color = sprite.info_color
  local name = smw.SPRITE_NAMES[sprite.number]
  local image = sprite_images[sprite.number]
  local w, h = image:size()
  gui.solidrectangle(x, y, 42*8, h + 8*12 + 56, 0x202020) -- FIXME: take other fonts in consideration
  draw.font["Uzebox6x8"](x + w, y, string.format(" slot #%d is $%.2x: %s", slot, sprite.number, name), info_color)
  image:draw(x, y)

  local t = {
    WRAM.sprite_phase,            WRAM.sprite_misc_1504,        WRAM.sprite_misc_1510,
    WRAM.sprite_misc_151c,        WRAM.sprite_misc_1528,        WRAM.sprite_misc_1534,
    WRAM.sprite_stun_timer,       WRAM.sprite_player_contact,   WRAM.sprite_misc_1558,
    WRAM.sprite_sprite_contact,   WRAM.sprite_animation_timer,  WRAM.sprite_horizontal_direction,
    WRAM.sprite_blocked_status,   WRAM.sprite_misc_1594,        WRAM.sprite_x_offscreen,
    WRAM.sprite_misc_15ac,        WRAM.sprite_slope,            WRAM.sprite_misc_15c4,
    WRAM.sprite_being_eaten_flag, WRAM.sprite_misc_15dc,        WRAM.sprite_OAM_index,
    WRAM.sprite_YXPPCCCT,         WRAM.sprite_misc_1602,        WRAM.sprite_misc_160e,
    WRAM.sprite_index_to_level,   WRAM.sprite_misc_1626,        WRAM.sprite_behind_scenery,
    WRAM.sprite_misc_163e,        WRAM.sprite_underwater,       WRAM.sprite_y_offscreen, 
    WRAM.sprite_misc_187b,        WRAM.sprite_disable_cape
  }

  local text = ""
  for i, address in ipairs(t) do
    local symbol = "_"
    if used[sprite.number] and used[sprite.number][address] then symbol = ":" end
    
    if true or used[sprite.number] and used[sprite.number][address] then
      text = string.format("%s$%.4X%s %.2x%s", text, address, symbol, u8("WRAM", address + slot), i%4 == 0 and "\n" or ", ")
    else
      text = string.format("%s         %s", text, i%4 == 0 and "\n" or "  ") 
    end
  end
  draw.font["Uzebox8x12"](x, y + h, text, info_color)

  local x_txt, y_txt = x, y + h + 8*12
  sprite_tweaker_editor(slot, x_txt, y_txt)
end

spriteMiscTables.display_info = sprite_table_viewer

function spriteMiscTables:main()
  for slot, t in pairs(self.slot) do
    if Sprites_info[slot].status ~= 0 then
      -- FIXME: this is bad!
      -- the spriteMiscTables should work without using widget
      local x = draw.AR_x * widget:get_property(string.format("spriteMiscTables.slot[%d]", slot), "x") or t.xpos
      local y = draw.AR_y * widget:get_property(string.format("spriteMiscTables.slot[%d]", slot), "y") or t.ypos
      
      self.display_info(x, y, slot)
    end
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
  if u8("WRAM", WRAM.sprite_misc_151c + slot) ~= 0 or
  u8("WRAM", WRAM.sprite_horizontal_direction + slot) ~= 0 then

    local OAM_index = 0xec
    local xoff = u8("WRAM", WRAM.sprite_OAM_xoff + OAM_index) - 0x0c
    local yoff = u8("WRAM", WRAM.sprite_OAM_yoff + OAM_index) - 0x0c
    local width, height = 0x18 - 1, 0x18 - 1  -- instruction BCS

    draw.rectangle(xoff, yoff, width, height, COLOUR.awkward_hitbox, COLOUR.awkward_hitbox_bg)
    -- TODO: 0x7e and 0x80 are too important
    -- draw this point outside this function and add an option
    draw.pixel(s16("WRAM", 0x7e), s16("WRAM", 0x80), COLOUR.mario)
  end
end

special_sprite_property[0x3d] = function(slot) -- Rip Van Fish
  if u8("WRAM", WRAM.sprite_phase + slot) == 0 then -- if sleeping
    local x_screen = Sprites_info[slot].x_screen
    local y_screen = Sprites_info[slot].y_screen
    local color = Sprites_info[slot].info_color
    local x1, y1, x2, y2 = -0x30, -0x30, 0x2e, 0x2e

    -- Draw central hitbox and 8 areas around due to overflow
    for horizontal = -1, 1 do
      local x = x_screen + 0x100*horizontal
      for vertical = -1, 1 do
        local y = y_screen + 0x100*vertical
        draw.box(x + x1, y + y1, x + x2, y + y2, 2, color)
      end
    end

    Display.show_player_point_position = true -- Only Mario coordinates matter
  end
end

special_sprite_property[0x4c] = function(slot) -- Exploding block
  if u8("WRAM", WRAM.sprite_x_offscreen + slot) == 0 then
    local x_screen = Sprites_info[slot].x_screen
    local color = Sprites_info[slot].info_color
    local bg_color = (Real_frame - slot)%2 == 1 and 0xC0200020 or -1

    local x1, x2 = -0x60, 0x5F

    local top = floor(OPTIONS.top_gap/draw.AR_y)
    local bottom = floor((draw.Buffer_height + OPTIONS.bottom_gap - 1)/draw.AR_x)

    for screen = -1, 1 do
      draw.box(0x100*screen + x_screen + x1, -top, 0x100*screen + x_screen + x2, bottom, 2, color, bg_color)
    end

    Display.show_player_point_position = true -- Only Mario coordinates matter
  end
end

local function hex(name, n)
  print(name, string.format("%x", n))
end

special_sprite_property[0x5f] = function(slot) -- Swinging brown platform (TODO fix it)
  --[[ TEST
  local angle = 0x100*u16("WRAM", WRAM.sprite_misc_1528 + slot) + u16("WRAM", WRAM.sprite_misc_151c + slot)
  local var1 = (angle)%0x100
  local var2 = (angle + 0x80)%0x100
  gui.text(0, 200 + 16*slot, fmt("%.4x: 1:  %.4x   2: %.4x", angle, var1, var2), "red", "darkblue")

  local t = Sprites_info[slot]
  local center_x = t.x - 0x50
  local center_y = t.y - 0x00
  local var_1866 = u16("WRAM", WRAM.sprite_misc_1528 + slot)
  local var_151c = u16("WRAM", WRAM.sprite_misc_151c + slot)
  local var_1867 = ((var_151c == 0 and 0 or 1)+ var_1866)%2

  local var_14c5 = smw.TRIGONOMETRY[var2]

  local multi = 0x50 * var_14c5
  local multi_high = math.floor(multi/0x10000)
  local multi_low = multi%0x10000
  
  local var_4 = multi_low
  local var_6 = multi_high
  
  if var_1867 == 1 then
    print"flipping"
    var_4 = (bit.bxor(var_4, 0xffff) + 1)%0x10000
    var_6 = (bit.bxor(var_6, 0xffff) + 1)%0x10000
  end
  local var_8 = var_4
  local var_a = var_6

  local var_5 = math.floor(var_8/0x100) + 0x100*math.floor(var_a/0x100)
  
  local var_14b8 = (center_x + var_5)%0x10000
  local var_35c = (center_x - Camera_x - 8)%0x100
  local var_358 = (var_14b8 - Camera_x - 8)%0x10000
  local var_7 = var_35c
  hex("var_7", var_7)
  local var_2 = (center_x - 8)%0x10000
  local var_4 = (var_358 - var_7 + var_2)%0x10000
  var_14b8 = var_4
  hex("var_2", var_2)
  
  gui.textHV(0, 400, fmt("%x", var_14b8))
  draw.line(var_14b8 - Camera_x, 0, var_14b8 - Camera_x, 224, 2)
  gui.text(0, 32, fmt("%d %d", center_x + smw.TRIGONOMETRY[var1] - 0x18, center_y - smw.TRIGONOMETRY[var2]))

  -- draw some shit
  draw.rectangle(t.x_screen - 0x50, t.y_screen, 8, 8)
  local angle = 0x100*u16("WRAM", WRAM.sprite_misc_1528 + slot) + u16("WRAM", WRAM.sprite_misc_151c + slot)
  var1 = smw.TRIGONOMETRY[(angle - 0x80)%0x100]
  var2 = smw.TRIGONOMETRY[(angle - 0x100)%0x100]
  if (angle - 0x80)%0x200 <= 0x100 then
    var1 = - var1
  end
  if (angle - 0x100)%0x200 <= 0x100 then
    var2 = - var2
  end

  local x = t.x - 0x50 + math.floor(var1*0x50/0x100)
  local y = t.y - 0 + math.floor(var2*0x50/0x100)
  draw.rectangle(x -32 - Camera_x, y - Camera_y - 20, 64, 11)
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
  local yoshi_right = 256*floor(x/256) - 58
  local yoshi_left  = yoshi_right + 32
  local x_text, y_text, height = draw.AR_x*(x_screen + xoff), draw.AR_y*(y_screen + yoff), draw.font_height()

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
  local xmario, ymario = u16("WRAM", 0x7e), u16("WRAM", 0x80)
  if math.floor(xmario/256) == 0 and math.floor(ymario/256) == 0 then
    local y1 = 0x08 + 0x08 + (Yoshi_riding_flag and 0x10 or 0)
    local y2 = 0x21 + (Yoshi_riding_flag and 0x10 or 0) + (Player_powerup == 0 and 2 or 0)
    draw.box(xmario - 6 + 0x8, ymario + y1,xmario + 0x0d, ymario + y2, 2, COLOUR.mario_oam_hitbox, COLOUR.interaction_bg)
  end

  -- Spheres hitbox
  draw.Font = "Uzebox6x8"
  if t.x_offscreen == 0 and t.y_offscreen == 0 then
    local OAM_index = u8("WRAM", WRAM.sprite_OAM_index + slot)
    for ball = 0, 4 do
      local x = u8("WRAM", 0x300 + OAM_index + 4*ball)
      local y = u8("WRAM", 0x301 + OAM_index + 4*ball)

      draw.rectangle(x, y, 8, 8, color, COLOUR.sprites_bg)
      draw.text(draw.AR_x*(x + 2), draw.AR_y*(y + 2), ball, COLOUR.text)
    end
  end
end

special_sprite_property[0x6c] = special_sprite_property[0x6b] -- Wall springboard (right wall)

special_sprite_property[0x6f] = function(slot) -- Dino-Torch: display flame hitbox
  local t = Sprites_info[slot]

  if OPTIONS.display_sprite_hitbox then
    if u8("WRAM", WRAM.sprite_misc_151c + slot) == 0 then  -- if flame is hurting
      local active = (Real_frame - slot)%4 == 0 and COLOUR.sprites_bg or -1
      local vertical_flame = u8("WRAM", WRAM.sprite_misc_1602 + slot) == 3
      local xoff, yoff, width, height

      if vertical_flame then
        xoff, yoff, width, height = 0x02, -0x24, 0x0c, 0x24
      else
        local facing_right = u8("WRAM", WRAM.sprite_horizontal_direction + slot) == 0
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

  draw.Font = "Uzebox6x8"
  draw.Text_opacity = 0.8
  draw.Bg_opacity = 0.6

  -- This draws the effective area of a goal tape
  local x_effective = 256*u8("WRAM", WRAM.sprite_misc_151c + slot) + u8("WRAM", WRAM.sprite_phase + slot)
  local y_low = 256*u8("WRAM", WRAM.sprite_misc_1534 + slot) + u8("WRAM", WRAM.sprite_misc_1528 + slot)
  local _, y_high = screen_coordinates(0, 0, Camera_x, Camera_y)
  local x_s, y_s = screen_coordinates(x_effective, y_low, Camera_x, Camera_y)
  local active = u8("WRAM", WRAM.sprite_misc_1602 + slot) == 0
  local color = active and COLOUR.goal_tape_bg or -1

  if OPTIONS.display_sprite_hitbox then
    draw.box(x_s, y_high, x_s + 15, y_s, 2, info_color, color)
  end
  draw.text(draw.AR_x*x_s, draw.AR_y*t.y_screen, fmt("Touch=%4d.0->%4d.f", x_effective, x_effective + 15), info_color, false, false)

  -- Draw a bitmap if the tape is unnoticeable
  local x_png, y_png = draw.put_on_screen(draw.AR_x*x_s, draw.AR_y*y_s, 18, 6)  -- png is 18x6 -- lsnes
  if x_png ~= draw.AR_x*x_s or y_png > draw.AR_y*y_s then  -- tape is outside the screen
    DBITMAPS.goal_tape:draw(x_png, y_png)
  else
    Display.show_player_point_position = true
    if y_low < 10 then DBITMAPS.goal_tape:draw(x_png, y_png) end  -- tape is too small, 10 is arbitrary here
  end
end

special_sprite_property[0x86] = function(slot) -- Wiggler (segments)
  local OAM_index = u8("WRAM", WRAM.sprite_OAM_index + slot)
  for seg = 0, 4 do
    local xoff = u8("WRAM", WRAM.sprite_OAM_xoff + OAM_index) - 0x0a
    local yoff = u8("WRAM", WRAM.sprite_OAM_yoff + OAM_index) - 0x1b
    if Yoshi_riding_flag then yoff = yoff - 0x10 end
    local width, height = 0x17 - 1, 0x17
    local xend, yend = xoff + width, yoff + height

    -- TODO: fix draw.rectangle to display the exact dimensions; then remove the -1
    --draw.rectangle(xoff, yoff, width - 1, height - 1, COLOUR.awkward_hitbox, COLOUR.awkward_hitbox_bg)
    draw.box(xoff, yoff, xend, yend, 2, COLOUR.awkward_hitbox, COLOUR.awkward_hitbox_bg)

    OAM_index = OAM_index + 4
  end

  draw.pixel(s16("WRAM", 0x7e), s16("WRAM", 0x80), COLOUR.mario)
end

special_sprite_property[0xa9] = function(slot) -- Reznor
  draw.Font = "Uzebox8x12"
  local reznor
  local color
  for index = 0, SMW.sprite_max - 1 do
    reznor = u8("WRAM", WRAM.sprite_misc_151c + index)
    if index >= 4 and index <= 7 then
      color = COLOUR.warning
    else
      color = color_weak
    end
    draw.text(3*draw.font_width()*index, draw.Buffer_height, fmt("%.2x", reznor), color, true, false, 0.0, 1.0)
  end
end

special_sprite_property[0x91] = function(slot) -- Chargin' Chuck
  if Sprites_info[slot].status ~= 0x08 then return end

  -- > spriteYLow - addr1 <= MarioYLow < spriteYLow + addr2 - addr1
  local routine_pointer = u8("WRAM", WRAM.sprite_phase + slot)
  routine_pointer = bit.lshift(bit.band(routine_pointer, 0xff), 1, 16)
  local facing_right = u8("WRAM", WRAM.sprite_horizontal_direction + slot) == 0

  local x1, x2, y1, yoff, height
  local color, bg

  if routine_pointer == 0 then -- looking
    local active = bit.band(u8("WRAM", WRAM.sprite_stun_timer + slot), 0x0f) == 0
    color = COLOUR.sprite_vision_passive
    bg = active and COLOUR.sprite_vision_active_bg or -1
    yoff = -0x28
    height = 0x50 - 1
    x1 = 0
    x2 = floor(draw.Buffer_width/2) - 1

  elseif routine_pointer == 2 then -- following
    color = COLOUR.sprite_vision_active
    bg = COLOUR.sprite_vision_active_bg
    yoff = -0x30
    height = 0x60 - 1
    x1 = Sprites_info[slot].x_screen + (facing_right and 1 or -1)
    x2 = facing_right and floor(draw.Buffer_width/2) - 1 or 0

  else -- inactive
    color = COLOUR.sprite_vision_passive
    bg = -1
    yoff = -0x28
    height = 0x50 - 1
    x1 = Sprites_info[slot].x_screen + (facing_right and 1 or -1)
    x2 = facing_right and floor(draw.Buffer_width/2) - 1 or 0
  end

  y1 = Sprites_info[slot].y_screen + yoff
  draw.box(x1, y1, x2, y1 + height, 2, color, bg)

  y1 = y1 + 0x100 -- draw it again, 0x100 pixels below
  draw.box(x1, y1, x2, y1 + height, 2, color, bg)
  Display.show_player_point_position = true
end

special_sprite_property[0x92] = function(slot) -- Splittin' Chuck
  if Sprites_info[slot].status ~= 0x08 then return end
  if u8("WRAM", WRAM.sprite_phase + slot) ~= 5 then return end

  local xoff = -0x50
  local width = 0xa0 - 1

  local t = Sprites_info[slot]
  for i = -1, 1 do
    draw.rectangle(t.x_screen + xoff + i*0x100, -draw.Border_top, width,
      draw.Buffer_height + draw.Border_bottom, t.info_color, 0xf0ffff00)
  end
  Display.show_player_point_position = true
end

special_sprite_property[0xa0] = function(slot) -- Bowser TODO: use $ for hex values
  draw.Font = "Uzebox8x12"
  local height = draw.font_height()
  local y_text = draw.Buffer_height - 10*height
  for index = 0, 9 do
    local value = u8("WRAM", WRAM.bowser_attack_timers + index)
    draw.text(draw.Buffer_width + draw.Border_right, y_text + index*height,
      fmt("$%2X = %3d", value, value), Sprites_info[slot].info_color, true)
  end
end

special_sprite_property[0xae] = function(slot) -- Fishin' Boo
  if OPTIONS.display_sprite_hitbox then
    local x_screen = Sprites_info[slot].x_screen
    local y_screen = Sprites_info[slot].y_screen
    local direction = u8("WRAM", WRAM.sprite_horizontal_direction + slot)
    local aux = u8("WRAM", WRAM.sprite_misc_1602 + slot)
    local index = 2*direction + aux
    local offsets = {[0] = 0x1a, 0x14, -0x12, -0x08}
    local xoff = offsets[index]

    if not xoff then  -- possible exception
      xoff = 0
      draw.Font = "Uzebox8x12"
      draw.text(draw.AR_x*x_screen, draw.AR_y*(y_screen + 0x47),
        fmt("Glitched offset! dir:%.2x, aux:%.2x", direction, aux)
      )
    end

    draw.rectangle(x_screen + xoff, y_screen + 0x47, 4, 4, COLOUR.warning2, COLOUR.awkward_hitbox_bg)
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

  -- Print those informations next to the sprite
  draw.Font = "Uzebox6x8"
  draw.Text_opacity = 1.0
  draw.Bg_opacity = 1.0

  if x_offscreen ~= 0 or y_offscreen ~= 0 then
    draw.Text_opacity = 0.6
  end

  local contact_str = contact_mario == 0 and "" or " " .. contact_mario

  local sprite_middle = t.sprite_middle
  local sprite_top = t.sprite_top
  if OPTIONS.display_sprite_info then
    local xdraw, ydraw = draw.AR_x*sprite_middle, draw.AR_y*sprite_top


    local behind_str = behind_scenery == 0 and "" or "BG "
    draw.text(xdraw, ydraw, fmt("%s#%.2d%s", behind_str, id, contact_str), info_color, true, false, 0.5, 1.0)
    
    if being_eaten_flag then
      DBITMAPS.yoshi_tongue:draw(xdraw, ydraw - 14)
    end
    
    if Player_powerup == 2 then
      local contact_cape = u8("WRAM", WRAM.sprite_disable_cape + id)
      if contact_cape ~= 0 then
        draw.text(xdraw, ydraw - 2*draw.font_height(), contact_cape, COLOUR.cape, true)
      end
    end
  end

  -- The sprite table:
  if OPTIONS.display_sprite_info then
    draw.Font = false
    local x_speed_water = ""
    if underwater ~= 0 then  -- if sprite is underwater
      local correction = 3 * floor(floor(x_speed/2) / 2)
      x_speed_water = string.format("%+.2d=%+.2d", correction - x_speed, correction)
    end
    local sprite_str = fmt("#%02d %02x %s%d.%1x(%+.2d%s) %d.%1x(%+.2d)",
      id, number, t.table_special_info, x, floor(x_sub/16), x_speed, x_speed_water, y, floor(y_sub/16), y_speed)
    

    -- Signal stun glitch
    if sprite_status == 9 and stun ~= 0 and not smw.NORMAL_STUNNABLE[number] then
      sprite_str = "Stun Glitch! " .. sprite_str
    end

    local w = DBITMAPS.yoshi_tongue:size()
    local xdraw, ydraw = draw.Buffer_width + draw.Border_right - #sprite_str*draw.font_width() - w, table_position + counter*draw.font_height()
    if Yoshi_stored_sprites[id] == 0 then
      DBITMAPS.yoshi_full_mouth_trans:draw(xdraw, ydraw)
    elseif Yoshi_stored_sprites[id] == 1 then
      DBITMAPS.yoshi_full_mouth:draw(xdraw, ydraw)
    end

    draw.text(draw.Buffer_width + draw.Border_right, table_position + counter*draw.font_height(), sprite_str, info_color, true)
  end

  return 1
end

local function sprites()
  local counter = 0
  local table_position = draw.AR_y*40 -- lsnes
  for id = 0, SMW.sprite_max - 1 do
    scan_sprite_info(Sprites_info, id)
    counter = counter + sprite_info(id, counter, table_position)
  end

  if OPTIONS.display_sprite_info then
    -- Font
    draw.Font = "Uzebox6x8"
    draw.Text_opacity = 1.0
    draw.Bg_opacity = 1.0

    local swap_slot = u8("WRAM", WRAM.sprite_swap_slot)
    local smh = u8("WRAM", WRAM.sprite_memory_header)
    draw.text(draw.Buffer_width + draw.Border_right, table_position - 2*draw.font_height(), fmt("spr:%.2d ", counter), COLOUR.weak, true)
    draw.text(draw.Buffer_width + draw.Border_right, table_position - draw.font_height(), fmt("1st div: %d. Swap: %d ",
                                          SPRITE_MEMORY_MAX[smh] or 0, swap_slot), COLOUR.weak, true)
  end

  -- Miscellaneous sprite table: index
  if OPTIONS.display_miscellaneous_sprite_table then
    draw.Font = false
    local w, h = draw.font_width(), draw.font_height()
    local tab = "spriteMiscTables"
    local x, y = draw.AR_x * widget:get_property(tab, "x"), draw.AR_y * widget:get_property(tab, "y")
    widget:set_property(tab, "display_flag", true)
    draw.font[draw.Font](x, y, "Sprite Tables:\n ", COLOUR.text, 0x202020)
    y = y + 16
    for i = 0, SMW.sprite_max - 1 do
      if not spriteMiscTables.slot[i] then
        draw.button(x, y, string.format("%X", i), function() spriteMiscTables:new(i) end, {button_pressed = false})
      else
        draw.button(x, y, string.format("%X", i), function() spriteMiscTables:destroy(i) end, {button_pressed = true})
      end
      x = x + w + 1
    end
  end

  spriteMiscTables:main()
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
    info = math.max(wait, timer) + floor((len + 7)/4) - (len ~= 0 and 1 or 0)
    color = eat_id == SMW.null_sprite_id and COLOUR.text or COLOUR.warning

  elseif out == 0 then info = 0; color = COLOUR.text  -- tongue in

  else info = timer + 1; color = COLOUR.tongue_line -- item was just spat out
  end

  return info, color
end


local function yoshi()
  if not OPTIONS.display_yoshi_info then return end

  -- Font
  draw.Font = false
  draw.Text_opacity = 1.0
  draw.Bg_opacity = 1.0
  local x_text = draw.AR_x * widget:get_property("yoshi", "x")
  local y_text = draw.AR_y * widget:get_property("yoshi", "y")

  local yoshi_id = smw.get_yoshi_id()
  widget:set_property("yoshi", "display_flag", OPTIONS.display_yoshi_info and yoshi_id)

  local visible_yoshi = u8("WRAM", WRAM.yoshi_loose_flag) - 1
  if visible_yoshi >= 0 and visible_yoshi ~= yoshi_id then
    draw.Font = "Uzebox6x8"
    draw.text(x_text, y_text, string.format("Yoshi slot diff: %s vs RAM %d", yoshi_id, visible_yoshi), COLOUR.warning)
    y_text = y_text + draw.font_height()
    draw.Font = false

    yoshi_id = visible_yoshi -- use delayed Yoshi slot
  end
  
  if yoshi_id ~= nil then
    local tongue_len = u8("WRAM", WRAM.sprite_misc_151c + yoshi_id)
    local tongue_timer = u8("WRAM", WRAM.sprite_misc_1558 + yoshi_id)
    local yoshi_direction = u8("WRAM", WRAM.sprite_horizontal_direction + yoshi_id)
    local tongue_out = u8("WRAM", WRAM.sprite_misc_1594 + yoshi_id)
    local turn_around = u8("WRAM", WRAM.sprite_misc_15ac + yoshi_id)
    local tile_index = u8("WRAM", WRAM.sprite_misc_1602 + yoshi_id)
    local eat_id = u8("WRAM", WRAM.sprite_misc_160e + yoshi_id)
    local mount_invisibility = u8("WRAM", WRAM.sprite_misc_163e + yoshi_id)
    local eat_type = u8("WRAM", WRAM.sprite_number + eat_id)
    local tongue_wait = u8("WRAM", WRAM.sprite_tongue_wait)
    local tongue_height = u8("WRAM", WRAM.yoshi_tile_pos)
    local yoshi_in_pipe = u8("WRAM", WRAM.yoshi_in_pipe)

    local eat_type_str = eat_id == SMW.null_sprite_id and "-" or string.format("%02x", eat_type)
    local eat_id_str = eat_id == SMW.null_sprite_id and "-" or string.format("#%02x", eat_id)

    -- Yoshi's direction and turn around
    local direction_symbol
    if yoshi_direction == 0 then direction_symbol = RIGHT_ARROW else direction_symbol = LEFT_ARROW end

    draw.text(x_text, y_text, fmt("Yoshi %s %d", direction_symbol, turn_around), COLOUR.yoshi)
    local h = draw.font_height()

    if eat_id == SMW.null_sprite_id and tongue_len == 0 and tongue_timer == 0 and tongue_wait == 0 then
      draw.Font = "snes9xluasmall"
    end
    draw.text(x_text, y_text + h, fmt("(%0s, %0s) %02d, %d, %d",
              eat_id_str, eat_type_str, tongue_len, tongue_wait, tongue_timer), COLOUR.yoshi)
    ;

    -- more WRAM values
    local yoshi_x = memory.sread_sg("WRAM", WRAM.sprite_x_low + yoshi_id, WRAM.sprite_x_high + yoshi_id)
    local yoshi_y = memory.sread_sg("WRAM", WRAM.sprite_y_low + yoshi_id, WRAM.sprite_y_high + yoshi_id)
    local x_screen, y_screen = screen_coordinates(yoshi_x, yoshi_y, Camera_x, Camera_y)

    -- invisibility timer
    draw.Font = "Uzebox6x8"
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
      actual_index = yoshi_in_pipe ~= 0 and u8("WRAM", 0x0d) or smw.YOSHI_TONGUE_X_OFFSETS[actual_index] or 0

      local xoff = special_sprite_property.yoshi_tongue_offset(actual_index, tongue_len)

       -- tile_index changes midframe, according to yoshi_in_pipe address
      local yoff = yoshi_in_pipe ~= 0 and 3 or smw.YOSHI_TONGUE_Y_OFFSETS[tile_index] or 0
      yoff = yoff + 2
      draw.rectangle(x_screen + xoff, y_screen + yoff, 8, 4, tongue_line, COLOUR.tongue_bg)
      draw.pixel(x_screen + xoff, y_screen + yoff, COLOUR.text, COLOUR.tongue_bg) -- hitbox point vs berry tile

      -- glitched hitbox for Layer Switch Glitch
      if yoshi_in_pipe ~= 0 then
        local xoff = special_sprite_property.yoshi_tongue_offset(0x40, tongue_len) -- from ROM
        draw.rectangle(x_screen + xoff, y_screen + yoff, 8, 4, 0x80ffffff, 0xc0000000)

        draw.Font = "Uzebox8x12"
        draw.text(x_text, y_text + 2*h, fmt("$1a: %.4x $1c: %.4x",
          u16("WRAM", WRAM.layer1_x_mirror), u16("WRAM", WRAM.layer1_y_mirror)), COLOUR.yoshi)
        draw.text(x_text, y_text + 3*h, fmt("$4d: %.4x $4f: %.4x",
          u16("WRAM", WRAM.layer1_VRAM_left_up), u16("WRAM", WRAM.layer1_VRAM_right_down)), COLOUR.yoshi)
      end

      -- tongue out: time predictor
      local info, color =
      special_sprite_property.yoshi_tongue_time_predictor(tongue_len, tongue_timer, tongue_wait, tongue_out, eat_id)
      draw.Font = "Uzebox6x8"
      draw.text(draw.AR_x*(x_screen + xoff + 4), draw.AR_y*(y_screen + yoff + 5), info, color, false, false, 0.5)
    end

  elseif memory.readbyte("WRAM", WRAM.yoshi_overworld_flag) ~= 0 then -- if there's no Yoshi
    draw.Font = "Uzebox6x8"
    draw.text(x_text, y_text, "Yoshi on overworld", COLOUR.yoshi)
  end
end


local function sprite_load_status()
  widget:set_property("sprite_load_status", "display_flag", OPTIONS.display_sprite_load_status)
  if not OPTIONS.display_sprite_load_status then return end

  -- 1st part
  local indexes = {}
  for id = 0, 11 do
    local status = u8("WRAM", WRAM.sprite_status + id)

    if status ~= 0 then
      local index = u8("WRAM", 0x161a + id)
      indexes[index] = true
    end
  end

  -- 2nd part
  local offset = 0x1938
  local x_origin = draw.AR_x * widget:get_property("sprite_load_status", "x")
  local y_origin = draw.AR_y * widget:get_property("sprite_load_status", "y")
  local x, y = x_origin, y_origin
  draw.Font = "Uzebox6x8"
  local w, h = draw.font_width(), draw.font_height()

  local status_table = memory.readregion("WRAM", offset, 0x80)
  for id = 0, 0x80 - 1 do
    local status = status_table[id]
    local color = (status == 0 and 0x808080) or (status == 1 and 0xffffff) or 0xffff00
    if status ~= 0 and not indexes[id] then
      color = 0xff0000
    end
    draw.text(x, y, string.format("%.2x ", status), color)
    x = x + 3*w
    if id%16 == 15 then
      x = x_origin
      y = y + h
    end
  end
end


local function display_fadeout_timers()
  if not OPTIONS.display_counters then return end

  local end_level_timer = u8("WRAM", WRAM.end_level_timer)
  if end_level_timer == 0 then return end

  -- load
  local peace_image_timer = u8("WRAM", WRAM.peace_image_timer)
  local fadeout_radius = u8("WRAM", WRAM.fadeout_radius)
  local zero_subspeed = u8("WRAM", WRAM.x_subspeed) == 0

  -- display
  draw.Font = false
  local height = draw.font_height()
  local x, y = 0, draw.Buffer_height - 3*height -- 3 max lines
  local text = 2*end_level_timer + (Real_frame)%2
  draw.text(x, y, fmt("End timer: %d(%d) -> real frame", text, end_level_timer), COLOUR.text)
  y = y + height
  draw.text(x, y, fmt("Peace %d, Fadeout %d/60", peace_image_timer, 60 - math.floor(fadeout_radius/4)), COLOUR.text)
  if end_level_timer >= 0x28 then
    if (zero_subspeed and Real_frame%2 == 0) or (not zero_subspeed and Real_frame%2 ~= 0) then
      y = y + height
      draw.text(x, y, "Bad subspeed?", COLOUR.warning)
    end
  end
end


local function show_counters()
  if not OPTIONS.display_counters then return end

  -- Font
  draw.Font = false  -- "snes9xtext" is also good and small
  draw.Text_opacity = 1.0
  draw.Bg_opacity = 1.0
  local height = draw.font_height()
  local text_counter = 0

  local pipe_entrance_timer = u8("WRAM", WRAM.pipe_entrance_timer)
  local multicoin_block_timer = u8("WRAM", WRAM.multicoin_block_timer)
  local gray_pow_timer = u8("WRAM", WRAM.gray_pow_timer)
  local blue_pow_timer = u8("WRAM", WRAM.blue_pow_timer)
  local dircoin_timer = u8("WRAM", WRAM.dircoin_timer)
  local pballoon_timer = u8("WRAM", WRAM.pballoon_timer)
  local star_timer = u8("WRAM", WRAM.star_timer)
  local invisibility_timer = u8("WRAM", WRAM.invisibility_timer)
  local animation_timer = u8("WRAM", WRAM.animation_timer)
  local fireflower_timer = u8("WRAM", WRAM.fireflower_timer)
  local yoshi_timer = u8("WRAM", WRAM.yoshi_timer)
  local swallow_timer = u8("WRAM", WRAM.swallow_timer)
  local lakitu_timer = u8("WRAM", WRAM.lakitu_timer)
  local score_incrementing = u8("WRAM", WRAM.score_incrementing)
  local pause_timer = u8("WRAM", WRAM.pause_timer)  -- new
  local bonus_timer = u8("WRAM", WRAM.bonus_timer)
  local disappearing_sprites_timer = u8("WRAM", WRAM.disappearing_sprites_timer)
  local message_box_timer = floor(u8("WRAM", WRAM.message_box_timer)/4)
  local game_intro_timer = u8("WRAM", WRAM.game_intro_timer)

  local display_counter = function(label, value, default, mult, frame, color)
    if value == default then return end
    text_counter = text_counter + 1
    local color = color or COLOUR.text

    draw.text(0, draw.AR_y*102 + (text_counter * height), fmt("%s: %d", label, (value * mult) - frame), color)
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
  display_counter("Score Incrementing", score_incrementing, 0x50, 1, 0)
  display_counter("Pause", pause_timer, 0, 1, 0)  -- new  -- level
  display_counter("Bonus", bonus_timer, 0, 1, 0)
  display_counter("Message", message_box_timer, 0, 1, 0) -- level and overworld
  display_counter("Intro", game_intro_timer, 0, 4, Real_frame % 4)  -- TODO: check whether it appears only during the intro level

  display_fadeout_timers()

  if Lock_animation_flag ~= 0 then display_counter("Animation", animation_timer, 0, 1, 0) end  -- shows when player is getting hurt or dying
end


function generators:info()
  if not OPTIONS.display_generator_info then return end
  
  draw.Font = "Uzebox6x8"
  local font_height = draw.font_height()
  
  local generator = u8("WRAM", WRAM.generator_type)
  if generator == 0 then return end -- no active generator

  local generator_timer = u8("WRAM", WRAM.generator_timer) -- TODO: use for some generators
  local text = fmt("Generator $%X: %s", generator, smw.GENERATOR_TYPES[generator])
  draw.text(0, draw.Buffer_height + 12, text, COLOUR.warning2)

  local f = self.sprite[generator]
  if f then f() end
end

generators.sprite = {}


generators.sprite[0x09] = function() -- Super Koopas
  -- load environment
  local _, _, next_rng1 = RNG.predict(u8("WRAM", WRAM.RNG_input),
                                      u8("WRAM", WRAM.RNG_input + 1), 
                                      u8("WRAM", WRAM.RNG), 
                                      u8("WRAM", WRAM.RNG + 1))
  -- FIXME: actually, carry flag is not always the same

  local ypos = Camera_y + bit.band(next_rng1, 0x3F) + 0x20
  local xpos = Camera_x + (next_rng1%2 == 0 and -0x20 or 0x110)
  local timer = 0x40 - bit.band(Effective_frame, 0x3F)
  local xscreen, yscreen = screen_coordinates(xpos, ypos, Camera_x, Camera_y)
  xscreen, yscreen = draw.AR_x*xscreen, draw.AR_y*yscreen
  
  gui.crosshair(xscreen, yscreen)
  local bitmap = sprite_images[0x71]
  bitmap:draw(xscreen + 5, yscreen + 5)
  draw.text(xscreen + 40, yscreen + 5, timer, COLOUR.warning)
  draw.text(xscreen + 4, yscreen - 10, fmt('%d, %d', xpos, ypos))
end


generators.sprite[0x0B] = function() -- Bullet Bills, sides
  local bill_x, bill_y
  
  -- load environment
  local _, _, next_rng1 = RNG.predict(u8("WRAM", WRAM.RNG_input),
                                      u8("WRAM", WRAM.RNG_input + 1), 
                                      u8("WRAM", WRAM.RNG), 
                                      u8("WRAM", WRAM.RNG + 1))
  local A, C, Y = 0, 1, 0 -- FIXME: carry is always set after the RNG routine
  
  -- calculate the y pos
  A = bit.band(next_rng1, 0x7F) + 0x20 + Camera_y%0x100 + C
  C = 0
  if A >= 0x100 then
    A = A - 0x100
    C = 1
  end
  bill_y = bit.band(A, 0xF0) + 0x100*(math.floor(Camera_y/0x100) + C)
  
  -- calculate the x pos
  Y = bit.band(next_rng1, 0x01)
  A = Camera_x%0x100 + (Y == 0 and 0xE0 or 0x10)
  C = 0
  if A >= 0x100 then
    A = A - 0x100
    C = 1
  end
  
  bill_x = A
  A = math.floor(Camera_x/0x100) + (Y == 0 and 0xFF or 0x01) + C
  A = A%0x100
  bill_x = luap.signed16(bill_x + 0x100*A)
  
  local xpos, ypos = screen_coordinates(bill_x, bill_y, Camera_x, Camera_y)
  draw.rectangle(xpos + 2, ypos + 3, 12, 10)
  draw.text((xpos + 8)*draw.AR_x, ypos*draw.AR_y,
          fmt("%d", 0x80 - bit.band(Effective_frame, 0x7F)),
          COLOUR.warning, true, false, 0.5, 1.0)

  local bill_bitmap = sprite_images[0x1c]
  bill_bitmap:draw((xpos + 5)*draw.AR_x, (ypos + 5)*draw.AR_y)
end


generators.sprite[0x0C] = function() -- Bullet Bills, surrounded
  local bullet_timer = u8("WRAM", WRAM.bullet_bill_timer)
  bullet_timer = 2*(0xa0 - bullet_timer) + (Real_frame%2 == 0 and 1 or 2)

  draw.text(0, draw.Buffer_height + 12 + 12, 'Timer: ' .. bullet_timer, COLOUR.warning2)
end


generators.sprite[0x0D] = generators.sprite[0x0C] -- Bullet Bills, diagonal


-- Main function to run inside a level
local function level_mode()
  if SMW.game_mode_fade_to_level <= Game_mode and Game_mode <= SMW.game_mode_level then

    -- Draws/Erases the tiles if user clicked
    --map16.display_known_tiles()
    draw_layer1_tiles(Camera_x, Camera_y)

    draw_layer2_tiles()

    draw_boundaries()

    sprites()

    extended_sprites()

    cluster_sprites()

    minor_extended_sprites()

    bounce_sprite_info()

    quake_sprite_info()

    shooter.sprite_table()

    score.sprite_table()

    smoke.sprite_table()

    coin.sprite_table()

    level_info()

    sprite_load_status()

    player()

    yoshi()

    show_counters()

    generators:info()

    predict_block_duplications()

    -- Draws/Erases the hitbox for objects
    if User_input.mouse_inwindow == 1 then
      select_object(User_input.mouse_x, User_input.mouse_y, Camera_x, Camera_y)
    end

  end
end


local function display_OW_exits()
  draw.Font = false
  local x = draw.Buffer_width
  local y = draw.AR_y * 24
  local h = draw.font_height()

  draw.text(x, y, "Beaten exits:" .. u8("WRAM", 0x1f2e))
  for i = 0, 15 - 1 do
    y = y + h
    local byte = u8("WRAM", 0x1f02 + i)
    draw.over_text(x, y, byte, "76543210", COLOUR.weak, "red")
  end
end


local function overworld_mode()
  if Game_mode ~= SMW.game_mode_overworld then return end

  -- Font
  draw.Font = false
  draw.Text_opacity = 1.0
  draw.Bg_opacity = 1.0

  local height = draw.font_height()
  local y_text = 0

  -- Real frame modulo 8
  local real_frame_8 = Real_frame%8
  draw.text(draw.Buffer_width + draw.Border_right, y_text, fmt("Real Frame = %3d = %d(mod 8)", Real_frame, real_frame_8), true)

  -- Star Road info
  local star_speed = u8("WRAM", WRAM.star_road_speed)
  local star_timer = u8("WRAM", WRAM.star_road_timer)
  y_text = y_text + height
  draw.text(draw.Buffer_width + draw.Border_right, y_text, fmt("Star Road(%x %x)", star_speed, star_timer), COLOUR.cape, true)

  -- beaten exits
  display_OW_exits()
end


local function left_click()
  -- Buttons
  for _, field in ipairs(draw.button_list) do

    -- if mouse is over the button
    if mouse_onregion(field.x, field.y, field.x + field.width, field.y + field.height) then
        field.action()
        config.save_options()
        return
    end
  end

  -- Movie Editor
  if lsnes.movie_editor() then return end

  -- Sprites' tweaker editor
  if Cheat.allow_cheats and Cheat.sprite_tweaker_selected_id then
    local id = Cheat.sprite_tweaker_selected_id
    local tweaker_num = Cheat.sprite_tweaker_selected_y + 1
    local tweaker_bit = 7 - Cheat.sprite_tweaker_selected_x

    -- Sanity check
    if id < 0 or id >= SMW.sprite_max then return end
    if tweaker_num < 1 or tweaker_num > 6 or tweaker_bit < 0 or tweaker_bit > 7 then return end

    -- Get address and edit value
    local tweaker_table = {WRAM.sprite_1_tweaker, WRAM.sprite_2_tweaker, WRAM.sprite_3_tweaker,
                WRAM.sprite_4_tweaker, WRAM.sprite_5_tweaker, WRAM.sprite_6_tweaker}
    local address = tweaker_table[tweaker_num] + id
    local value = u8("WRAM", address)
    local status = bit.test(value, tweaker_bit)

    w8("WRAM", address, value + (status and -1 or 1) * bit.lshift(1, tweaker_bit))  -- edit only given bit
    print(fmt("Edited bit %d of sprite (#%d) tweaker %d (address WRAM+%x).", tweaker_bit, id, tweaker_num, address))
    Cheat.sprite_tweaker_selected_id = nil  -- don't edit two addresses per click
    return
  end

  -- Drag and drop sprites
  if Cheat.allow_cheats then
    local id = select_object(User_input.mouse_x, User_input.mouse_y, Camera_x, Camera_y)
    if type(id) == "number" and id >= 0 and id < SMW.sprite_max then
      Cheat.dragging_sprite_id = id
      Cheat.is_dragging_sprite = true
      return
    end
  end

  -- Layer 1 tiles
  if not Options_menu.show_menu then
    if not (OPTIONS.display_controller_input and luap.inside_rectangle(User_input.mouse_x, User_input.mouse_y,
    lsnes.movie_editor_left, lsnes.movie_editor_top, lsnes.movie_editor_right, lsnes.movie_editor_bottom)) then
      -- don't select over movie editor
      local x_mouse, y_mouse = game_coordinates(User_input.mouse_x, User_input.mouse_y, Camera_x, Camera_y)
      x_mouse = 16*floor(x_mouse/16)
      y_mouse = 16*floor(y_mouse/16)
      select_tile(x_mouse, y_mouse, Layer1_tiles)
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
    draw.button(-draw.Border_left, -draw.Border_top, "Menu", function() Options_menu.show_menu = true end, {always_on_client = true})

    draw.button(0, 0, "↓",
      function() OPTIONS.display_controller_input = not OPTIONS.display_controller_input end, {always_on_client = true, ref_x = 1.0, ref_y = 1.0})
    ;

    draw.button(-draw.Border_left, draw.Buffer_height + draw.Border_bottom, Cheat.allow_cheats and "Cheats: allowed" or "Cheats: blocked", function()
      Cheat.allow_cheats = not Cheat.allow_cheats
      draw.message("Cheats " .. (Cheat.allow_cheats and "allowed." or "blocked."))
    end, {always_on_client = true, ref_y = 1.0})

    draw.button(draw.Buffer_width + draw.Border_right, draw.Buffer_height + draw.Border_bottom, "Erase Tiles",
      function() Layer1_tiles = {}; Layer2_tiles = {} end, {always_on_client = true, ref_y = 1.0})
    ;

    -- Quick save movie/state buttons
    draw.Font = "Uzebox6x8"
    draw.text(0, draw.Buffer_height - 2*draw.font_height(), "Save?", COLOUR.text, COLOUR.background)

    draw.button(0, draw.Buffer_height, "Movie", function()
        local hint = movie.get_rom_info()[1].hint
        local current_time = string.gsub(system_time(), ":", ".")
        local filename = string.format("%s-%s(MOVIE).lsmv", current_time, hint)
        if not luap.file_exists(filename) then
          exec("save-movie " .. filename)
          draw.message("Pending save-movie: " .. filename, 3000000)
          return
        else
          print("Movie " .. filename .. " already exists.", 3000000)
          draw.message("Movie " .. filename .. " already exists.")
          return
        end
      end, {always_on_game = true})
    ;

    draw.button(5*draw.font_width() + 1, draw.Buffer_height + LSNES_FONT_HEIGHT, "State", function()
        local hint = movie.get_rom_info()[1].hint
        local current_time = string.gsub(system_time(), ":", ".")
        local filename = string.format("%s-%s(STATE).lsmv", current_time, hint)
        if not luap.file_exists(filename) then
          exec("save-state " .. filename)
          draw.message("Pending save-state: " .. filename, 3000000)
          return
        else
          print("State " .. filename .. " already exists.")
          draw.message("State " .. filename .. " already exists.", 3000000)
          return
        end
      end, {always_on_game = true})
    ;

    -- Free movement cheat
    -- display button to toggle the free movement state
    if Cheat.allow_cheats then
      draw.Font = "Uzebox8x12"
      local x, y, dx, dy = 0, 0, draw.font_width(), draw.font_height()
      draw.font[draw.Font](x, y, "Free movement cheat ", COLOUR.warning, COLOUR.weak, 0)
      draw.button(x + 20*dx, y, Cheat.free_movement.is_applying or " ", function()
        Cheat.free_movement.is_applying = not Cheat.free_movement.is_applying
      end)

      -- display free movement options if it's active
      if Cheat.free_movement.is_applying then
        y = y + dy
        draw.font[draw.Font](x, y, "Type:", COLOUR.button_text, COLOUR.weak)
        draw.button(x +5*dx, y, Cheat.free_movement.manipulate_speed and "Speed" or " Pos ", function()
          Cheat.free_movement.manipulate_speed = not Cheat.free_movement.manipulate_speed
        end)
        y = y + dy
        draw.font[draw.Font](x, y, "invincibility:", COLOUR.button_text, COLOUR.weak)
        draw.button(x + 14*dx, y, Cheat.free_movement.give_invincibility or " ", function()
          Cheat.free_movement.give_invincibility = not Cheat.free_movement.give_invincibility
        end)
        y = y + dy
        draw.font[draw.Font](x, y, "Freeze animation:", COLOUR.button_text, COLOUR.weak)
        draw.button(x + 17*dx, y, Cheat.free_movement.freeze_animation or " ", function()
          Cheat.free_movement.freeze_animation = not Cheat.free_movement.freeze_animation
        end)
        y = y + dy
        draw.font[draw.Font](x, y, "Unlock camera:", COLOUR.button_text, COLOUR.weak)
        draw.button(x + 14*dx, y, Cheat.free_movement.unlock_vertical_camera or " ", function()
          Cheat.free_movement.unlock_vertical_camera = not Cheat.free_movement.unlock_vertical_camera
        end)
      end
    end

    Options_menu.adjust_lateral_gaps()
  else
    if Cheat.allow_cheats then  -- show cheat status anyway
      draw.Font = "Uzebox6x8"
      draw.text(-draw.Border_left, draw.Buffer_height + draw.Border_bottom, "Cheats: allowed", COLOUR.warning, true, false, 0.0, 1.0)
    end
  end

  -- Drag and drop sprites with the mouse
  if Cheat.is_dragging_sprite then
    -- TODO: avoid many parameters in function
    Cheat.drag_sprite(Cheat.dragging_sprite_id, Game_mode, Sprites_info, Camera_x, Camera_y)
    Cheat.is_cheating = true
  end

  Options_menu.display()
end


--#############################################################################
-- MAIN --


function on_input(subframe)
  if not movie.rom_loaded() or not controller.info_loaded then return end

  joypad:getKeys()

  if Cheat.allow_cheats then
    Cheat.is_cheating = false

    Cheat.beat_level(Is_paused, Level_index, Level_flag)
    Cheat.free_movement.apply(Previous)
  else
    -- Cancel any continuous cheat
    Cheat.free_movement.is_applying = false

    Cheat.is_cheating = false
  end
end


function on_frame_emulated()
  if OPTIONS.use_custom_lag_detector then
    Is_lagged = (not lsnes.Controller_latch_happened) or (u8("WRAM", 0x10) == 0)
  else
    Is_lagged = memory.get_lag_flag()
  end
  if OPTIONS.use_custom_lagcount then
    memory.set_lag_flag(Is_lagged)
  end

  -- Resets special WRAM addresses for changes
  for address, inner in pairs(Address_change_watcher) do
    inner.watching_changes = false
  end

  if OPTIONS.register_player_position_changes == "simple" and OPTIONS.display_player_info and Previous.next_x then
    local change = s16("WRAM", WRAM.x) - Previous.next_x
    Registered_addresses.mario_position = change == 0 and "" or (change > 0 and (change .. "→") or (-change ..  "←"))
  end
end


function on_snoop2(p, c, b, v)
  -- Clear stuff after emulation of frame has started
  if p == 0 and c == 0 then
    Registered_addresses.mario_position = ""
    Midframe_context:clear()

    if Collision_debugger[1] then
      Collision_debugger = {}
    end
  end
end


function on_frame()
  if not movie.rom_loaded() then  -- only useful with null ROM
    gui.repaint()
  end
end


function on_paint(received_frame)
  -- Initial values, don't make drawings here
  keyinput.get_mouse()
  lsnes.get_status()
  draw.lsnes_screen_info()
  lsnes.get_movie_info()
  create_gaps()

  -- If the paint request occurs just after a load state, don't render new elements
  if lsnes.preloading_state then
    Paint_context:run()
    return
  end
  
  Paint_context:clear()
  Paint_context:set()

  -- gets back to default paint context / video callback doesn't capture anything
  if not controller.info_loaded then return end

  -- Dark filter to cover the game area
  if OPTIONS.filter_opacity ~= 0 then gui.solidrectangle(0, 0, draw.Buffer_width, draw.Buffer_height, COLOUR.filter_color) end

  -- Drawings are allowed now
  if Ghost_player then Ghost_player.renderctx:run() end
  scan_smw()
  level_mode()
  overworld_mode()
  show_movie_info()
  show_misc_info()
  display_RNG()
  show_controller_data()

  if OPTIONS.display_controller_input then
    lsnes.frame, lsnes.port, lsnes.controller, lsnes.button = lsnes.display_input()  -- test: fix names
  end

  -- ACE debug info
  if OPTIONS.register_ACE_debug_callback then
    draw.Font = "Uzebox6x8"
    local y, height = LSNES_FONT_HEIGHT, draw.font_height()
    local count = 0

    for index in pairs(DEBUG_REGISTER_ADDRESSES.active) do
      draw.text(draw.Buffer_width, y, DEBUG_REGISTER_ADDRESSES[index][3], false, true)
      y = y + height
      count = count + 1
    end

    if count > 0 then draw.Font = false; draw.text(draw.Buffer_width, 0, "ACE helper:", COLOUR.warning, COLOUR.warning_bg, false, true) end
  end

  -- Lagmeter
  if OPTIONS.use_lagmeter_tool and Lagmeter.Mcycles then
    local meter, color = Lagmeter.Mcycles/3573.68
    if meter < 70 then color = 0x00ff00
    elseif meter < 90 then color = 0xffff00
    elseif meter <= 100 then color = 0xff0000
    else color = 0xff00ff end

    draw.Font = "Uzebox8x12"
    draw.text(364, 16, fmt("Lagmeter: %.3f", meter), color, false, false, 0.5)
  end

  -- Check for collision
  -- TODO: unregisterexec when this option is OFF
  if OPTIONS.debug_collision_routine and Collision_debugger[1] then
    draw.Font = false
    local y = draw.Buffer_height

    for num, id in ipairs(Collision_debugger) do
      draw.text(0, y, "Collision " .. tostringx(id), COLOUR.warning, COLOUR.warning_bg)
      y = y + 16
    end
  end

  Cheat.is_cheat_active()

  -- Comparison ghost
  if OPTIONS.show_comparison_ghost and Ghost_player then
    --Ghost_player.comparison(received_frame)
  end

  -- gets back to default paint context / video callback doesn't capture anything
  gui.renderctx.setnull()
  Paint_context:run()

  -- display warning if recording OSD
  if Previous.video_callback then
    draw.text(0, draw.Buffer_height, OPTIONS.make_lua_drawings_on_video and "Capturing OSD" or "NOT capturing OSD", COLOUR.warning, true, true)
    if received_frame then Previous.video_callback = false end
  end

  -- on_timer registered functions
  Timer.on_paint()

  lsnes_yield()

end


function on_video()
  Video_callback = true

  if OPTIONS.make_lua_drawings_on_video then
    -- Scale the video to the same dimensions of the emulator
    gui.set_video_scale(2, 2)

    -- Renders the same context of on_paint over video
    Paint_context:run()
    if Ghost_player then Ghost_player.renderctx:run() end
    create_gaps()
  end

  Previous.video_callback = true
  Video_callback = false
end


-- Loading a state
function on_pre_load()
  -- Resets special WRAM addresses for changes
  for address, inner in pairs(Address_change_watcher) do
    inner.watching_changes = false
    inner.info = ""
  end
  Registered_addresses.mario_position = ""
  Midframe_context:clear()
end

function on_post_load(name, was_savestate)
  Is_lagged = false
  Lagmeter.Mcycles = false

  -- ACE debug info
  if OPTIONS.register_ACE_debug_callback then
    for index in pairs(DEBUG_REGISTER_ADDRESSES.active) do
      DEBUG_REGISTER_ADDRESSES.active[index] = nil
    end
  end

  collectgarbage()
  gui.repaint()
end

function on_err_save(name)
  draw.message("Failed saving state " .. name)
end


-- Functions called on specific events
function on_readwrite()
  draw.message("Read-Write mode")
  gui.repaint()
end

function on_rewind()
  draw.message("Movie rewound to beginning")
  Is_lagged = false
  Lagmeter.Mcycles = false
  lsnes.Lastframe_emulated = nil

  gui.repaint()
end


-- Repeating callbacks
function on_timer()
  Previous.readonly_on_timer = Readonly_on_timer  -- artificial callback on_readonly
  Readonly_on_timer = movie.readonly()
  if (Readonly_on_timer and not Previous.readonly_on_timer) then draw.message("Read-Only mode") end

  set_timer_timeout(OPTIONS.timer_period)  -- calls on_timer forever
end


function on_idle()
  if User_input.mouse_inwindow == 1 then
    gui.repaint()
  end

  set_idle_timeout(OPTIONS.idle_period)  -- calls on_idle forever, while idle
end


function lsnes.on_new_ROM()
  print"new_ROM"
  if not movie.rom_loaded() then return end

  lsnes.get_controller_info()
  register_debug_callback(false)

  -- Register special WRAM addresses for changes
  Registered_addresses.mario_position = ""
  Address_change_watcher[WRAM.x] = {watching_changes = false, register = function(addr, value)
    local tabl = Address_change_watcher[WRAM.x]
    if tabl.watching_changes then
      local new = luap.signed16(256*u8("WRAM", WRAM.x + 1) + value)
      local change = new - s16("WRAM", WRAM.x)
      if OPTIONS.register_player_position_changes == "complete" and change ~= 0 then
        Registered_addresses.mario_position = Registered_addresses.mario_position .. (change > 0 and (change .. "→")
        or (-change ..  "←")) .. " "

        -- Debug: display players' hitbox when position changes
        Midframe_context:set()
        player_hitbox(new, s16("WRAM", WRAM.y), u8("WRAM", WRAM.is_ducking), u8("WRAM", WRAM.powerup),
        1, DBITMAPS.interaction_points_palette_alt)
      end
    end

    tabl.watching_changes = true
  end}
  Address_change_watcher[WRAM.y] = {watching_changes = false, register = function(addr, value)
    local tabl = Address_change_watcher[WRAM.y]
    if tabl.watching_changes then
      local new = luap.signed16(256*u8("WRAM", WRAM.y + 1) + value)
      local change = new - s16("WRAM", WRAM.y)
      if OPTIONS.register_player_position_changes == "complete" and change ~= 0 then
        Registered_addresses.mario_position = Registered_addresses.mario_position .. (change > 0 and (change .. "↓")
        or (-change .. "↑")) .. " "

        -- Debug: display players' hitbox when position changes
        if math.abs(new - Previous.y) > 1 then  -- ignores the natural -1 for y, while on top of a block
          Midframe_context:set()
          player_hitbox(s16("WRAM", WRAM.x), new, u8("WRAM", WRAM.is_ducking), u8("WRAM", WRAM.powerup),
          1, DBITMAPS.interaction_points_palette_alt)
        end
      end
    end

    tabl.watching_changes = true
  end}
  for address, inner in pairs(Address_change_watcher) do
    memory.registerwrite("WRAM", address, inner.register)
  end

  -- Check for collision
  OPTIONS.debug_collision_routine_untouch = true -- EDIT
  memory.registerexec("BUS", smw.CHECK_FOR_CONTACT_ROUTINE, function()
    if memory.getregister("p")%2 == 1 then
      local id = memory.getregister("x")
      local RAM = memory.readregion("WRAM", 0, 8)
      local str = string.format("id=%d, Obj 1 (%d, %d) is %dx%d, Obj 2 (%d, %d) is %dx%d",
                id, RAM[0], RAM[1], RAM[2], RAM[3], RAM[4], RAM[5], RAM[6], RAM[7]
      )

      Collision_debugger[#Collision_debugger + 1] = str
    end
  end)

  -- Lagmeter
  if OPTIONS.use_lagmeter_tool then
    memory.registerexec("BUS", 0x8075, Lagmeter.get_master_cycles)  -- unlisted ROM
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
  Ghost_player = require "ghost"
  Ghost_player.init()
end

-- KEYHOOK callback
on_keyhook = keyinput.altkeyhook

-- Key presses:
keyinput.register_key_press("mouse_inwindow", gui.repaint)
keyinput.register_key_press(OPTIONS.hotkey_increase_opacity, function() draw.increase_opacity() ; gui.repaint() end)
keyinput.register_key_press(OPTIONS.hotkey_decrease_opacity, function() draw.decrease_opacity() ; gui.repaint() end)
keyinput.register_key_press("mouse_right", right_click)
keyinput.register_key_press("mouse_left", left_click)

-- Key releases:
keyinput.register_key_release("mouse_inwindow", function()
  Cheat.is_dragging_sprite = false
  widget.left_mouse_dragging = false
  gui.repaint()
end)
keyinput.register_key_release(OPTIONS.hotkey_increase_opacity, gui.repaint)
keyinput.register_key_release(OPTIONS.hotkey_decrease_opacity, gui.repaint)
keyinput.register_key_release("mouse_left", function()
  Cheat.is_dragging_sprite = false
  widget.left_mouse_dragging = false
end)

-- Read raw input:
keyinput.get_all_keys()

-- Timeout settings
set_timer_timeout(OPTIONS.timer_period)
set_idle_timeout(OPTIONS.idle_period)

-- Finish
draw.palettes_to_adjust(PALETTES, Palettes_adjusted)
draw.adjust_palette_transparency()
COLOUR.filter_color = draw.change_transparency(COLOUR.filter_tonality, OPTIONS.filter_opacity/10)
gui.repaint()
print("Lua script loaded successfully.")
