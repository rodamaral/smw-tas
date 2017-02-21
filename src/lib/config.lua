-- Configuration module
-- YOU PROBABLY WANT TO EDIT THE config.ini FILE INSTEAD OF THIS
local config = {}

local luap = require "luap"
local json = require "json"

local EMULATOR_NAME = luap.get_emulator_name()

local OPTIONS_LABEL
if EMULATOR_NAME == "lsnes" then
  OPTIONS_LABEL = "LSNES"
elseif EMULATOR_NAME == "BizHawk" then
  OPTIONS_LABEL = "BIZHAWK"
elseif EMULATOR_NAME == "Snes9x" then
  OPTIONS_LABEL = "SNES9X"
else
  error"Could not recognize emulator"
end

config.DEFAULT_OPTIONS = {
  -- Hotkeys  (look at the manual to see all the valid keynames)
  -- make sure that the hotkeys below don't conflict with previous bindings
  hotkey_increase_opacity = "equals",  -- to increase the opacity of the text: the '='/'+' key
  hotkey_decrease_opacity = "minus",  -- to decrease the opacity of the text: the '_'/'-' key

  -- ghost files/comparison script
  ghost_dump_files = {
    [[bahamete,masterjun,pangaeapanga-supermarioworld-warps.dump]],
    [[bahametekaizoman666misterpangaeapanga-supermarioworld-warps.dump]],
  },

  -- Display
  display_movie_info = true,
  display_lag_indicator = true,  -- lsnes specific
  display_misc_info = true,
  display_player_info = true,
  display_player_hitbox = true,  -- can be changed by right-clicking on player
  display_interaction_points = true,  -- can be changed by right-clicking on player
  display_cape_hitbox = true,
  display_debug_player_extra = false,
  display_sprite_info = true,
  display_sprite_hitbox = true,  -- you still have to select the sprite with the mouse
  display_sprite_vs_sprite_hitbox = false,
  display_sprite_load_status = false,
  display_debug_sprite_tweakers = false,
  display_debug_sprite_extra = false,
  display_extended_sprite_info = true,
  display_extended_sprite_hitbox = true,
  display_debug_extended_sprite = false,
  display_cluster_sprite_info = true,
  display_cluster_sprite_hitbox = true,
  display_debug_cluster_sprite = false,
  display_minor_extended_sprite_info = true,
  display_minor_extended_sprite_hitbox = true,
  display_debug_minor_extended_sprite = false,
  display_bounce_sprite_info = true,
  display_debug_bounce_sprite = false,
  display_level_info = false,
  display_level_boundary = true,
  display_level_boundary_always = false,
  display_sprite_vanish_area = true,
  display_sprite_data = true,
  display_sprite_load_status = true,
  display_yoshi_info = true,
  display_counters = true,
  display_controller_input = true,
  display_static_camera_region = false,  -- shows the region in which the camera won't scroll horizontally
  register_player_position_changes = "simple",  -- valid options: false, "simple" and "complete"
  use_block_duplication_predictor = true,
  draw_tiles_with_click = true,

  -- Lag
  use_lagmeter_tool = false,
  use_custom_lag_detector = false,
  use_custom_lagcount = false,

  -- Some extra/debug info
  display_miscellaneous_debug_info = false,
  display_debug_controller_data = false,
  debug_collision_routine = true,
  display_miscellaneous_sprite_table = false,
  miscellaneous_sprite_table_number = {[1] = true, [2] = true, [3] = true, [4] = true, [5] = true, [6] = true, [7] = true, [8] = true, [9] = true,
          [10] = true, [11] = true, [12] = true, [13] = true, [14] = true, [15] = true, [16] = true, [17] = true, [18] = true, [19] = true
  },
  register_ACE_debug_callback = true,  -- helps to see when some A.C.E. addresses are executed

  -- Script settings
  load_comparison_ghost = false,
  show_comparison_ghost = true,
  ghost_filename = false,  -- use the smw-tas.ini to edit this setting
  make_lua_drawings_on_video = false,
  use_custom_fonts = true,
  text_background_type = "automatic",  -- valid options: "full", "outline" and "automatic"
  max_tiles_drawn = 20,  -- the max number of tiles to be drawn/registered by the script

  -- Timer and Idle callbacks frequencies
  timer_period = math.floor(1000000/30),  -- 30 hertz
  idle_period = math.floor(1000000/10),  -- 10 hertz

  -- Lateral gaps (initial values) / lsnes specific
  left_gap = 8*(12 + 6),  -- default controller width for movie editor
  right_gap = 100,  -- 17 maximum chars of the level info
  top_gap = 20,
  bottom_gap = 8,
}

-- Colour settings
config.DEFAULT_COLOUR = {
  -- Text
  default_text_opacity = 1.0,
  default_bg_opacity = 0.4,
  text = "#ffffffff",
  background = "#000000ff",
  outline = "#000040ff",
  warning = "#ff0000ff",
  warning_bg = "#0000ffff",
  warning2 = "#ff00ffff",
  weak = "#a9a9a9ff",
  very_weak = "#ffffff60",
  joystick_input = "#ffff00ff",
  joystick_input_bg = "#ffffff30",
  button_text = "#300030ff",
  mainmenu_outline = "#ffffffc0",
  mainmenu_bg = "#000000c0",

  -- Counters
  counter_pipe = "#00ff00ff",
  counter_multicoin = "#ffff00ff",
  counter_gray_pow = "#a5a5a5ff",
  counter_blue_pow = "#4242deff",
  counter_dircoin = "#8c5a19ff",
  counter_pballoon = "#f8d870ff",
  counter_star = "#ffd773ff",
  counter_fireflower = "#ff8c00ff",

  -- hitbox and related text
  mario = "#ff0000ff",
  mario_bg = "#00000000",
  mario_mounted_bg = "#00000000",
  interaction = "#ffffffff",
  interaction_bg = "#00000020",
  interaction_nohitbox = "#000000a0",
  interaction_nohitbox_bg = "#00000070",
  mario_oam_hitbox = "#00ff80ff",

  sprites = {"#00ff00ff", "#0000ffff", "#ffff00ff", "#ff00ffff", "#b00040ff"},
  sprites_interaction_pts = "#ffffffff",
  sprites_bg = "#0000b050",
  sprites_clipping_bg = "#000000a0",
  sprites_faint = "#00000010",
  sprite_vision_active = "#d00000ff",
  sprite_vision_active_bg = "#d0000020",
  sprite_vision_passive = "#00d0d0c0",
  extended_sprites = "#ff8000ff",
  extended_sprites_bg = "#00ff0050",
  special_extended_sprite_bg = "#00ff0060",
  goal_tape_bg = "#ffff0050",
  fireball = "#b0d0ffff",
  baseball = "#0040a0ff",
  cluster_sprites = "#ff80a0ff",
  sumo_brother_flame = "#0040a0ff",
  minor_extended_sprites = "#ff90b0ff",
  awkward_hitbox = "#204060ff",
  awkward_hitbox_bg = "#ff800060",

  yoshi = "#00ffffff",
  yoshi_bg = "#00ffff40",
  yoshi_mounted_bg = "#00000000",
  tongue_line = "#ffa000ff",
  tongue_bg = "#00000060",

  cape = "#ffd700ff",
  cape_bg = "#ffd70060",

  block = "#00008bff",
  blank_tile = "#ffffff70",
  block_bg = "#22cc88a0",
  layer2_line = "#ff2060ff",
  layer2_bg = "#ff206040",
  static_camera_region = "#40002040",
}

-- Font settings:
config.LSNES_FONT_WIDTH = 8
config.LSNES_FONT_HEIGHT = 16
config.BIZHAWK_FONT_WIDTH = 10
config.BIZHAWK_FONT_HEIGHT = 14
config.SNES9X_FONT_WIDTH = 4
config.SNES9X_FONT_HEIGHT = 8
config.CUSTOM_FONTS = {
    [false] = { file = nil, height = LSNES_FONT_HEIGHT, width = LSNES_FONT_WIDTH }, -- this is lsnes default font

    snes9xlua =     { file = [[data/snes9xlua.font]],      height = 14, width = 10 },
    snes9xluaclever = { file = [[data/snes9xluaclever.font]],  height = 14, width = 08 }, -- quite pixelated
    snes9xluasmall =  { file = [[data/snes9xluasmall.font]],  height = 07, width = 05 },
    snes9xtext =    { file = [[data/snes9xtext.font]],     height = 09, width = 08 },
    verysmall =     { file = [[data/verysmall.font]],      height = 06, width = 04 }, -- broken, unless for numerals
    Uzebox6x8 =     { file = [[data/Uzebox6x8.font]],      height = 08, width = 06 },
    Uzebox8x12 =    { file = [[data/Uzebox8x12.font]],     height = 12, width = 08 },
}

-- Bitmap strings (base64 encoded)
config.BMP_STRINGS = {}
config.BMP_STRINGS.player_blocked_status = "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAUBAMAAABPKxEfAAAAJ1BMVEUAAABQAAD40MD4cGiwKGCIWBj4+Pj4QHBAgJj42HDYoDiA2MggMIipQuZJAAAAfElEQVR4nGNgYGAQFBRgAFHllYVAirHcZWUikBYpcQCJMrqAKQZGBQYDAwMGBqEgZgUF1QAG4SAGJSUlVQYBIyYFY2NTBgZmI7A6BtZgY4gG19AYEC3i3rH7AJAWDW3LzgHSYWlhEDq1o3sPhD4BkmcNDQgAawyN5GSAAwCQmRc/s4Su8AAAAABJRU5ErkJggg=="
config.BMP_STRINGS.goal_tape = "iVBORw0KGgoAAAANSUhEUgAAABIAAAAGCAYAAADOic7aAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAYdEVYdFNvZnR3YXJlAHBhaW50Lm5ldCA0LjAuNWWFMmUAAABYSURBVChTY5g5c6aGt7f3Jnt7+/+UYIaQkJB9u3bt+v/jxw+KMIOdnR1WCVIxg7m5+f8bN25QjBmA4bO3o6Pj/4YNGyjCDAsWLNC2sbFZp6Gh8Z98rPEfAKMNNFo8qFAoAAAAAElFTkSuQmCC"
config.BMP_STRINGS.interaction_points = {}
config.BMP_STRINGS.interaction_points[1] = "iVBORw0KGgoAAAANSUhEUgAAABwAAABCAgMAAAA5516AAAAADFBMVEUAAAD/AAAA/wD///+2fNpDAAAABHRSTlMA/yD/tY2ZWAAAACVJREFUeJxjYBgFDB9IpEkC/P9RMaZ5UFE4jSqPRT+JDgAjImkAC2MUoaLBtsIAAAAASUVORK5CYII="
config.BMP_STRINGS.interaction_points[2] = "iVBORw0KGgoAAAANSUhEUgAAABwAAABCAgMAAAA5516AAAAADFBMVEUAAAD/AAAA/wD///+2fNpDAAAABHRSTlMA/yD/tY2ZWAAAAChJREFUeJxjYBgE4AOJNEWA/z8qJuwemCq4aqq6hxAgwr0EDAAjImkA5r0UoRR72A8AAAAASUVORK5CYII="
config.BMP_STRINGS.interaction_points[3] = "iVBORw0KGgoAAAANSUhEUgAAABwAAABiAgMAAAA+S1u2AAAADFBMVEUAAAD/AAAA/wD///+2fNpDAAAABHRSTlMA/yD/tY2ZWAAAACpJREFUeJxjYBgFJIMPJNIkAf7/qJh098B0wXVT5B5aAzL8S6IFYEQkDQCa1xShzExmhwAAAABJRU5ErkJggg=="
config.BMP_STRINGS.interaction_points[4] = "iVBORw0KGgoAAAANSUhEUgAAABwAAABiAgMAAAA+S1u2AAAADFBMVEUAAAD/AAAA/wD///+2fNpDAAAABHRSTlMA/yD/tY2ZWAAAAClJREFUeJxjYBgFDB9IpEkC/P9RMenugemC66bIPYMNkBE+JFoARkTSAIzEFKEUjfKYAAAAAElFTkSuQmCC"

-- Symbols
config.LEFT_ARROW = "<-"
config.RIGHT_ARROW = "->"

-- Functions
local function color_number(str)
  local r, g, b, a = str:match("^#(%x+%x+)(%x+%x+)(%x+%x+)(%x+%x+)$")
  if not a and EMULATOR_NAME == "lsnes" then
    return gui.color(str)
  end

  r, g, b, a = tonumber(r, 16), tonumber(g, 16), tonumber(b, 16), tonumber(a, 16)

  if EMULATOR_NAME == "lsnes" then
    return gui.color(r, g, b, a)
  elseif EMULATOR_NAME == "BizHawk" then
    return 0x1000000*a + 0x10000*r + 0x100*g + b
  elseif EMULATOR_NAME == "Snes9x" then
    return 0x1000000*r + 0x10000*g + 0x100*b + a
  end
end

function interpret_color(data)
  for k, v in pairs(data) do
    if type(v) == "string" then
      data[k] = type(v) == "string" and color_number(v) or v
    elseif type(v) == "table" then
      interpret_color(data[k]) -- possible stack overflow
    end
  end
end

function config.load_options(filename)
  config.OPTIONS = luap.file_exists(filename)
  and config.retrieve(filename, {[OPTIONS_LABEL .. " OPTIONS"] = config.DEFAULT_OPTIONS})[OPTIONS_LABEL .. " OPTIONS"]
  or luap.copytable(config.DEFAULT_OPTIONS)

  config.COLOUR = luap.file_exists(filename)
  and config.retrieve(filename, {[OPTIONS_LABEL .. " COLOURS"] = config.DEFAULT_COLOUR})[OPTIONS_LABEL .. " COLOURS"]
  or luap.copytable(config.DEFAULT_COLOUR)

  config.save(filename, {
    [OPTIONS_LABEL .. " OPTIONS"] = config.OPTIONS,
    [OPTIONS_LABEL .. " COLOURS"] = config.COLOUR
  })

  interpret_color(config.COLOUR)
end

-- Verify whether there're fonts in /fonts/
function config.load_lsnes_fonts(folder)
  local lsnes_fonts_dir = [[data/]]

  if get_directory_contents ~= nil and get_file_type ~= nil then  -- lsnes >beta23
    if get_file_type(folder .. "/fonts") == "directory" then
      for id, path in ipairs(get_directory_contents(folder .. "/fonts")) do
        local dir, file, extension = path:match("(.-)([^\\/]-%.?([^%.\\/]*))$")

        if extension == "font" and get_file_type(lsnes_fonts_dir .. file) ~= "file" then
          local font_name, _ = file:match("(.+)(%.font)$")
          config.CUSTOM_FONTS[font_name].file = folder .. "/fonts/" .. file
        end
      end
    end
  end
end

-- loads the encoded table stored on file <filename
function config.load_decoded_data(filename)
  if not luap.file_exists(filename) then return false end
  local handle = io.open(filename, "r")
  local text = handle:read("*a")

  handle:close()
  return (text == "") and {} or json:decode(text)
end

function config.retrieve(filename, previous_data)
  if type(previous_data) ~= "table" then error"data must be a table" end

  local file_data = config.load_decoded_data(filename)
  if not file_data then
    return previous_data
  else
    -- Adds previous values to the new ini
    previous_data = luap.copytable(previous_data)  -- don't overwrite previous data
    return luap.mergetable(previous_data, file_data)
  end
end

function config.save(filename, data)
  assert(type(data) == "table", "data must be a table")

  local file_data = config.load_decoded_data(filename)
  if not file_data then
    merge = data
  else
    -- Adds previous values to the new ini
    data = luap.copytable(data)  -- don't overwrite previous data
    merge = luap.mergetable(file_data, data)
  end

  local file = assert(io.open(filename, "w"), "Error loading file :" .. filename)
  file:write(json:encode_pretty(merge))
  file:close()
end

function config.save_options()
  local file, data = config.filename, config.raw_data
  if not file or not data then print"save_options: <file> and <data> required!"; return end

  config.save(file, data)
end

return config
