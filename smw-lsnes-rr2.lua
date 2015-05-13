---------------------------------------------------------------------------
--  Super Mario World (U) Utility Script for Lsnes - rr2 version
--  http://tasvideos.org/Lsnes.html
--  
--  Author: Rodrigo A. do Amaral (Amaraticando)
--  Git repository: https://github.com/rodamaral/smw-tas
---------------------------------------------------------------------------

--#############################################################################
-- CONFIG:

local OPTIONS = {
    -- Comparison script (experimental)
    -- put the path between double brackets, e.g. [[C:/folder1/folder2/file.lua]], or simply put nil without "quote marks"
    ghost_filename = nil,  -- don't forget the comma after it ","
    
    -- Hotkeys  (look at the manual to see all the valid keynames)
    -- make sure that the hotkeys below don't conflict with previous bindings
    hotkey_increase_opacity = "equals",  -- to increase the opacity of the text: the '='/'+' key 
    hotkey_decrease_opacity = "minus",   -- to decrease the opacity of the text: the '_'/'-' key

    -- Display
    display_movie_info = true,
    display_misc_info = true,
    display_player_info = true,
    display_player_hitbox = true,  -- can be changed by right-clicking on player
    display_interaction_points = true,  -- can be changed by right-clicking on player
    display_sprite_info = true,
    display_sprite_hitbox = true,  -- you still have to select the sprite with the mouse
    display_extended_sprite_info = true,
    display_bounce_sprite_info = true,
    display_level_info = false,
    display_pit_info = true,
    display_yoshi_info = true,
    display_counters = true,
    display_controller_input = true,
    display_debug_info = false,  -- shows useful info while investigating the game, but not very useful while TASing

    -- Script settings
    use_custom_fonts = true,
    full_background_under_text = true,  --> true = full background / false = outline background
    max_tiles_drawn = 10,  -- the max number of tiles to be drawn/registered by the script

    -- Timer and Idle callbacks frequencies
    timer_period = math.floor(1000000/30),  -- 30 hertz
    idle_period = math.floor(1000000/10),   -- 10 hertz

    -- Cheats
    allow_cheats = false, -- better turn off while recording a TAS
    
    -- Lateral gaps (initial values)
    left_gap = 20*8 + 2,
    right_gap = 100,  -- 17 maximum chars of the Level info
    top_gap = 20,
    bottom_gap = 8,
}

-- Colour settings
local COLOUR = {
    -- Text
    default_text_opacity = 1.0,
    default_bg_opacity = 0.4,
    text = 0xffffff,
    background = 0x000000,
    outline = 0x000040,
    warning = 0x00ff0000,
    warning_bg = 0x000000ff,
    warning2 = 0xff00ff,
    weak = 0x00a9a9a9,
    joystick_input = 0x00ffff00,
    joystick_input_bg = 0xd0ffffff,
    button_text = 0x300030,
    mainmenu_outline = 0x40ffffff,
    mainmenu_bg = 0x40000000,
    
    -- hitbox and related text
    mario = 0x00ff0000,
    mario_bg = -1,
    mario_mounted_bg = -1,
    interaction = 0x00ffffff,
    interaction_bg = 0xe0000000,
    interaction_nohitbox = 0x60000000,
    interaction_nohitbox_bg = 0x90000000,
    
    sprites = {0x00ff00, 0x0000ff, 0xffff00, 0xff00ff, 0xb00040},
    sprites_interaction_pts = 0xffffff,
    sprites_bg = 0xb00000b0,
    sprites_clipping_bg = 0x60000000,
    extended_sprites = 0xff8000,
    goal_tape_bg = 0xb0ffff00,
    fireball = 0xb0d0ff,
    
    yoshi = 0x0000ffff,
    yoshi_bg = 0xc000ffff,
    yoshi_mounted_bg = -1,
    tongue_line = 0xffa000,
    tongue_bg = 0xa0000000,
    
    cape = 0x00ffd700,
    cape_bg = 0xa0ffd700,
    
    block = 0x0000008b,
    block_bg = 0xa022cc88,
}

-- Font settings
local LSNES_FONT_HEIGHT = 16
local LSNES_FONT_WIDTH = 8
local CUSTOM_FONTS = {
        [false] = { file = nil, height = LSNES_FONT_HEIGHT, width = LSNES_FONT_WIDTH }, -- this is lsnes default font
        
        snes9xlua =       { file = [[data/snes9xlua.font]],        height = 16, width = 10 },
        snes9xluaclever = { file = [[data/snes9xluaclever.font]],  height = 16, width = 08 }, -- quite pixelated
        snes9xluasmall =  { file = [[data/snes9xluasmall.font]],   height = 09, width = 05 },
        snes9xtext =      { file = [[data/snes9xtext.font]],       height = 11, width = 08 },
        verysmall =       { file = [[data/verysmall.font]],        height = 08, width = 04 }, -- broken, unless for numerals
}

-- Bitmap strings (base64 encoded)
local BLOCK_INFO_BITMAP_STRING = "iVBORw0KGgoAAAANSUhEUgAAAA4AAAAUCAIAAAAyZ5t7AAAACXBIWXMAAAsTAAALEwEAmpwYAAABF0lEQVR42p2RLZSFIBCFr3sMxheJRqPRaDQaiUQjkfgi0Wg0Go1E40YjkWg0GjcM4t97ZSdwGO43cGeI8Ij6mo77JnpCQyl93gEN+NQSHZ85gsyyAsiUTVHAaCTt5dYaEJmo2Iu42vZPY1HgfM0n6GJxm6eQbrK5rRdOc0b0Jhu/2VfNmeZsb6sfQmXSdpvgZ1oqUnns5f0hkpO8vDx9m6vXBE/y8mNLB0qGJKuDk68ojczmJpx0VrpZ3dEw2oq9qjIDUPIcQM+nQB8fS/dZAHgbJQBoN9tfmRUg2qMFZ7J3vkikgHi2Fd/yVqQmexvdkwft5q9oCDeuE2Y3rsHrfVgUalg0Z2pYzsU/Z/n4DivVsGxW4n/xB/1vhXi5GlF0AAAAAElFTkSuQmCC"
local INTERACTION_POINTS_STRING = {}
INTERACTION_POINTS_STRING[1] = "iVBORw0KGgoAAAANSUhEUgAAABwAAABCAgMAAAA5516AAAAADFBMVEUAAAD/AAAA/wD///+2fNpDAAAABHRSTlMA/yD/tY2ZWAAAACVJREFUeJxjYBgFDB9IpEkC/P9RMaZ5UFE4jSqPRT+JDgAjImkAC2MUoaLBtsIAAAAASUVORK5CYII="
INTERACTION_POINTS_STRING[2] = "iVBORw0KGgoAAAANSUhEUgAAABwAAABCAgMAAAA5516AAAAADFBMVEUAAAD/AAAA/wD///+2fNpDAAAABHRSTlMA/yD/tY2ZWAAAAChJREFUeJxjYBgE4AOJNEWA/z8qJuwemCq4aqq6hxAgwr0EDAAjImkA5r0UoRR72A8AAAAASUVORK5CYII="
INTERACTION_POINTS_STRING[3] = "iVBORw0KGgoAAAANSUhEUgAAABwAAABiAgMAAAA+S1u2AAAADFBMVEUAAAD/AAAA/wD///+2fNpDAAAABHRSTlMA/yD/tY2ZWAAAACpJREFUeJxjYBgFJIMPJNIkAf7/qJh098B0wXVT5B5aAzL8S6IFYEQkDQCa1xShzExmhwAAAABJRU5ErkJggg=="
INTERACTION_POINTS_STRING[4] = "iVBORw0KGgoAAAANSUhEUgAAABwAAABiAgMAAAA+S1u2AAAADFBMVEUAAAD/AAAA/wD///+2fNpDAAAABHRSTlMA/yD/tY2ZWAAAAClJREFUeJxjYBgFDB9IpEkC/P9RMenugemC66bIPYMNkBE+JFoARkTSAIzEFKEUjfKYAAAAAElFTkSuQmCC"

-- Symbols
local LEFT_ARROW = "<-"
local RIGHT_ARROW = "->"

-- Others
local Y_CAMERA_OFF = 1  -- small adjustment for screen coordinates <-> object position conversion


-- END OF CONFIG < < < < < < <
--#############################################################################
-- INITIAL STATEMENTS:


-- Load environment
local bit, gui, input, movie, memory, memory2 = bit, gui, input, movie, memory, memory2
local string, math, table, next, ipairs, pairs, io, os, type = string, math, table, next, ipairs, pairs, io, os, type

-- Script verifies whether the emulator is indeed Lsnes - rr2 version / beta21 or higher
local LSNES_VERSION  -- fix/hack: this is temporary, while the new versions of lsnes doesn't come
if movie.get_rom_info ~= nil then
    LSNES_VERSION = "rrtest"
elseif gui.solidrectangle ~= nil then
    LSNES_VERSION = "beta21_or_22"
else
    LSNES_VERSION = "old"
end

if LSNES_VERSION == "old" then
    function on_paint()
        gui.text(0, 00, "This script is supposed to be run on Lsnes.", COLOUR.text, COLOUR.outline)
        gui.text(0, 16, "rr2-beta21 version or higher.", COLOUR.text, COLOUR.outline)
        gui.text(0, 32, "Your version seems to be different.", COLOUR.text, COLOUR.outline)
        gui.text(0, 48, "Download the correct script at:", COLOUR.text, COLOUR.outline)
        gui.text(0, 64, "https://github.com/rodamaral/smw-tas", COLOUR.text, COLOUR.outline)
        gui.text(0, 80, "Download the lastest version of lsnes here", COLOUR.text, COLOUR.outline)
        gui.text(0, 96, "http://tasvideos.org/Lsnes.html", COLOUR.text, COLOUR.outline)
    end
    gui.repaint()
end

-- Text/Background_max_opacity is only changed by the player using the hotkeys
-- Text/Bg_opacity must be used locally inside the functions
local Text_max_opacity = COLOUR.default_text_opacity
local Background_max_opacity = COLOUR.default_bg_opacity
local Outline_max_opacity = 1
local Text_opacity = 1
local Bg_opacity = 1

-- Verify whether the fonts exist
for key, value in pairs(CUSTOM_FONTS) do
    if value.file and not io.open(value.file) then
        print("WARNING:", string.format("./%s is missing.", value.file))
        CUSTOM_FONTS[key] = nil
    end
end

-- Creates a table of fonts
local draw_font = {}
for key, value in pairs(CUSTOM_FONTS) do
    draw_font[key] = gui.font.load(value.file)
end

local fmt = string.format

-- Compatibility
local u8  = function(adress, value) return memory2.WRAM:byte  (adress, value) end
local s8  = function(adress, value) return memory2.WRAM:sbyte (adress, value) end
local u16 = function(adress, value) return memory2.WRAM:word  (adress, value) end
local s16 = function(adress, value) return memory2.WRAM:sword (adress, value) end
local u24 = function(adress, value) return memory2.WRAM:hword (adress, value) end
local s24 = function(adress, value) return memory2.WRAM:shword(adress, value) end

-- Bitmaps
local BLOCK_INFO_BITMAP = gui.image.load_png_str(BLOCK_INFO_BITMAP_STRING)
local GOAL_TAPE_BITMAP = gui.image.load_png_str("iVBORw0KGgoAAAANSUhEUgAAABIAAAAGCAYAAADOic7aAAAAAXNSR0IArs4c6QAAAARnQU1BAACxjwv8YQUAAAAJcEhZcwAADsMAAA7DAcdvqGQAAAAYdEVYdFNvZnR3YXJlAHBhaW50Lm5ldCA0LjAuNWWFMmUAAABYSURBVChTY5g5c6aGt7f3Jnt7+/+UYIaQkJB9u3bt+v/jxw+KMIOdnR1WCVIxg7m5+f8bN25QjBmA4bO3o6Pj/4YNGyjCDAsWLNC2sbFZp6Gh8Z98rPEfAKMNNFo8qFAoAAAAAElFTkSuQmCC")
local INTERACTION_POINTS, INTERACTION_POINTS_PALETTE = {}
INTERACTION_POINTS[1], INTERACTION_POINTS_PALETTE =  gui.image.load_png_str(INTERACTION_POINTS_STRING[1])
INTERACTION_POINTS[2] = gui.image.load_png_str(INTERACTION_POINTS_STRING[2])
INTERACTION_POINTS[3] = gui.image.load_png_str(INTERACTION_POINTS_STRING[3])
INTERACTION_POINTS[4] = gui.image.load_png_str(INTERACTION_POINTS_STRING[4])
INTERACTION_POINTS_STRING = nil


--#############################################################################
-- GAME AND SNES SPECIFIC MACROS:


local NTSC_FRAMERATE = 60.09881186234840471673 -- 10738636/178683 fps

local SMW = {
    -- Game Modes
    game_mode_overworld = 0x0e,
    game_mode_level = 0x14,
    
    -- Types of sprites
    sprite_max = 12,
    extended_sprite_max = 10,
    bounce_sprite_max = 4,
    
    null_sprite_id = 0xff,
}

WRAM = {
    -- I/O
    ctrl_1_1 = 0x0015,
    ctrl_1_2 = 0x0017,
    firstctrl_1_1 = 0x0016,
    firstctrl_1_2 = 0x0018,
    
    -- General
    game_mode = 0x0100,
    real_frame = 0x0013,
    effective_frame = 0x0014,
    lag_indicator = 0x01fe,
    timer_frame_counter = 0x0f30,
    RNG = 0x148d,
    current_level = 0x00fe,  -- plus 1
    sprite_memory_header = 0x1692,
    lock_animation_flag = 0x009d, -- Most codes will still run if this is set, but almost nothing will move or animate.
    level_mode_settings = 0x1925,
    star_road_speed = 0x1df7,
    star_road_timer = 0x1df8,
    
    -- Cheats
    frozen = 0x13fb,
    level_paused = 0x13d4,
    level_index = 0x13bf,
    room_index = 0x00ce,
    level_flag_table = 0x1ea2,
    level_exit_type = 0x0dd5,
    midway_point = 0x13ce,
    
    -- Camera
    camera_x = 0x001a,
    camera_y = 0x001c,
    screens_number = 0x005d,
    hscreen_number = 0x005e,
    vscreen_number = 0x005f,
    vertical_scroll = 0x1412,  -- #$00 = Disable; #$01 = Enable; #$02 = Enable if flying/climbing/etc.
    
    -- Sprites
    sprite_status = 0x14c8,
    sprite_throw = 0x1504, --
    sprite_stun = 0x1540,
    sprite_contact_mario = 0x154c,
    spriteContactSprite = 0x1564, --
    spriteContactoObject = 0x15dc,  --
    sprite_number = 0x009e,
    sprite_x_high = 0x14e0,
    sprite_x_low = 0x00e4,
    sprite_y_high = 0x14d4,
    sprite_y_low = 0x00d8,
    sprite_x_sub = 0x14f8,
    sprite_y_sub = 0x14ec,
    sprite_x_speed = 0x00b6,
    sprite_y_speed = 0x00aa,
    sprite_direction = 0x157c,
    sprite_x_offscreen = 0x15a0, 
    sprite_y_offscreen = 0x186c,
    sprite_miscellaneous = 0x160e,
    sprite_miscellaneous2 = 0x163e,
    sprite_miscellaneous3 = 0x1528,
    sprite_miscellaneous4 = 0x1594,
    sprite_1_tweaker = 0x1656,
    sprite_2_tweaker = 0x1662,
    sprite_3_tweaker = 0x166e,
    sprite_4_tweaker = 0x167a,
    sprite_5_tweaker = 0x1686,
    sprite_6_tweaker = 0x190f,
    sprite_tongue_length = 0x151c,
    sprite_tongue_timer = 0x1558,
    sprite_tongue_wait = 0x14a3,
    sprite_yoshi_squatting = 0x18af,
    sprite_buoyancy = 0x190e,
    reznor_killed_flag = 0x151c,
    sprite_turn_around = 0x15ac,
    
    -- Extended sprites
    extspr_number = 0x170b,
    extspr_x_high = 0x1733,
    extspr_x_low = 0x171f,
    extspr_y_high = 0x1729,
    extspr_y_low = 0x1715,
    extspr_x_speed = 0x1747,
    extspr_y_speed = 0x173d,
    extspr_suby = 0x1751,
    extspr_subx = 0x175b,
    extspr_table = 0x1765,
    extspr_table2 = 0x176f,
    
    -- Bounce sprites
    bouncespr_number = 0x1699,
    bouncespr_x_high = 0x16ad,
    bouncespr_x_low = 0x16a5,
    bouncespr_y_high = 0x16a9,
    bouncespr_y_low = 0x16a1,
    bouncespr_timer = 0x16c5,
    bouncespr_last_id = 0x18cd,
    turn_block_timer = 0x18ce,
    
    -- Player
    x = 0x0094,
    y = 0x0096,
    previous_x = 0x00d1,
    previous_y = 0x00d3,
    x_sub = 0x13da,
    y_sub = 0x13dc,
    x_speed = 0x007b,
    x_subspeed = 0x007a,
    y_speed = 0x007d,
    direction = 0x0076,
    is_ducking = 0x0073,
    p_meter = 0x13e4,
    take_off = 0x149f,
    powerup = 0x0019,
    cape_spin = 0x14a6,
    cape_fall = 0x14a5,
    cape_interaction = 0x13e8,
    flight_animation = 0x1407,
    diving_status = 0x1409,
    player_movement_mode = 0x0071,
    climbing_status = 0x0074,
    spinjump_flag = 0x140d,
    player_blocked_status = 0x0077, 
    player_item = 0x0dc2, --hex
    cape_x = 0x13e9,
    cape_y = 0x13eb,
    on_ground = 0x13ef,
    on_ground_delay = 0x008d,
    on_air = 0x0072,
    can_jump_from_water = 0x13fa,
    carrying_item = 0x148f,
    mario_score = 0x0f34,
    player_coin = 0x0dbf,
    player_looking_up = 0x13de,
    
    -- Yoshi
    yoshi_riding_flag = 0x187a,  -- #$00 = No, #$01 = Yes, #$02 = Yes, and turning around.
    yoshi_tile_pos = 0x0d8c,
    
    -- Timer
    --keep_mode_active = 0x0db1,
    score_incrementing = 0x13d6,
    end_level_timer = 0x1493,
    multicoin_block_timer = 0x186b, 
    gray_pow_timer = 0x14ae,
    blue_pow_timer = 0x14ad,
    dircoin_timer = 0x190c,
    pballoon_timer = 0x1891,
    star_timer = 0x1490,
    animation_timer = 0x1496,--
    invisibility_timer = 0x1497,
    fireflower_timer = 0x149b,
    yoshi_timer = 0x18e8,
    swallow_timer = 0x18ac,
    lakitu_timer = 0x18e0,
}
local WRAM = WRAM

local X_INTERACTION_POINTS = {center = 0x8, left_side = 0x2 + 1, left_foot = 0x5, right_side = 0xe - 1, right_foot = 0xb}

local Y_INTERACTION_POINTS = {
    {head = 0x10, center = 0x18, shoulder = 0x16, side = 0x1a, foot = 0x20, sprite = 0x15},
    {head = 0x08, center = 0x12, shoulder = 0x0f, side = 0x1a, foot = 0x20, sprite = 0x07},
    {head = 0x13, center = 0x1d, shoulder = 0x19, side = 0x28, foot = 0x30, sprite = 0x19},
    {head = 0x10, center = 0x1a, shoulder = 0x16, side = 0x28, foot = 0x30, sprite = 0x11}
}

local HITBOX_SPRITE = {
    [0x00] = { xoff = 2, yoff = 4, width = 12, height = 10, oscillation = true },
    [0x01] = { xoff = 2, yoff = 4, width = 12, height = 21, oscillation = true },
    [0x02] = { xoff = 16, yoff = -1, width = 16, height = 18, oscillation = true },
    [0x03] = { xoff = 20, yoff = 9, width = 8, height = 8, oscillation = true },
    [0x04] = { xoff = 0, yoff = -1, width = 48, height = 14, oscillation = true },
    [0x05] = { xoff = 0, yoff = -1, width = 80, height = 14, oscillation = true },
    [0x06] = { xoff = 1, yoff = 3, width = 14, height = 24, oscillation = true },
    [0x07] = { xoff = 8, yoff = 9, width = 40, height = 48, oscillation = true },
    [0x08] = { xoff = -8, yoff = -1, width = 32, height = 16, oscillation = true },
    [0x09] = { xoff = -2, yoff = 9, width = 20, height = 30, oscillation = true },
    [0x0a] = { xoff = 3, yoff = 8, width = 1, height = 2, oscillation = true },
    [0x0b] = { xoff = 6, yoff = 7, width = 3, height = 3, oscillation = true },
    [0x0c] = { xoff = 1, yoff = -1, width = 13, height = 22, oscillation = true },
    [0x0d] = { xoff = 0, yoff = -3, width = 15, height = 16, oscillation = true },
    [0x0e] = { xoff = 6, yoff = 7, width = 20, height = 20, oscillation = true },
    [0x0f] = { xoff = 2, yoff = -1, width = 36, height = 18, oscillation = true },
    [0x10] = { xoff = 0, yoff = -1, width = 15, height = 32, oscillation = true },
    [0x11] = { xoff = -24, yoff = -23, width = 64, height = 64, oscillation = true },
    [0x12] = { xoff = -4, yoff = 17, width = 8, height = 52, oscillation = true },
    [0x13] = { xoff = -4, yoff = 17, width = 8, height = 116, oscillation = true },
    [0x14] = { xoff = 4, yoff = 3, width = 24, height = 12, oscillation = true },
    [0x15] = { xoff = 0, yoff = -1, width = 15, height = 14, oscillation = true },
    [0x16] = { xoff = -4, yoff = -11, width = 24, height = 24, oscillation = true },
    [0x17] = { xoff = 2, yoff = 9, width = 12, height = 69, oscillation = true },
    [0x18] = { xoff = 2, yoff = 20, width = 12, height = 58, oscillation = true },
    [0x19] = { xoff = 2, yoff = 36, width = 12, height = 42, oscillation = true },
    [0x1a] = { xoff = 2, yoff = 52, width = 12, height = 26, oscillation = true },
    [0x1b] = { xoff = 2, yoff = 68, width = 12, height = 10, oscillation = true },
    [0x1c] = { xoff = 0, yoff = 11, width = 10, height = 48, oscillation = true },
    [0x1d] = { xoff = 2, yoff = -2, width = 28, height = 27, oscillation = true },
    [0x1e] = { xoff = 6, yoff = -7, width = 3, height = 32, oscillation = true }, --{ xoff = -32, yoff = -7, width = 48, height = 32, oscillation = true },
    [0x1f] = { xoff = -16, yoff = -3, width = 48, height = 18, oscillation = true },
    [0x20] = { xoff = -4, yoff = -23, width = 8, height = 24, oscillation = true },
    [0x21] = { xoff = -4, yoff = 17, width = 8, height = 24, oscillation = true },
    [0x22] = { xoff = 0, yoff = 1, width = 16, height = 16, oscillation = true },
    [0x23] = { xoff = -8, yoff = -23, width = 32, height = 32, oscillation = true },
    [0x24] = { xoff = -12, yoff = 33, width = 56, height = 56, oscillation = true },
    [0x25] = { xoff = -14, yoff = 5, width = 60, height = 20, oscillation = true },
    [0x26] = { xoff = 0, yoff = 89, width = 32, height = 8, oscillation = true },
    [0x27] = { xoff = -4, yoff = -3, width = 24, height = 24, oscillation = true },
    [0x28] = { xoff = -14, yoff = -23, width = 28, height = 40, oscillation = true },
    [0x29] = { xoff = -16, yoff = -3, width = 32, height = 27, oscillation = true },
    [0x2a] = { xoff = 2, yoff = -7, width = 12, height = 19, oscillation = true },
    [0x2b] = { xoff = 0, yoff = 3, width = 16, height = 76, oscillation = true },
    [0x2c] = { xoff = -8, yoff = -7, width = 16, height = 16, oscillation = true },
    [0x2d] = { xoff = 4, yoff = 5, width = 8, height = 4, oscillation = true },
    [0x2e] = { xoff = 2, yoff = -1, width = 28, height = 34, oscillation = true },
    [0x2f] = { xoff = 2, yoff = -1, width = 28, height = 32, oscillation = true },
    [0x30] = { xoff = 8, yoff = -13, width = 16, height = 28, oscillation = true },
    [0x31] = { xoff = 0, yoff = -1, width = 48, height = 18, oscillation = true },
    [0x32] = { xoff = 0, yoff = -1, width = 48, height = 18, oscillation = true },
    [0x33] = { xoff = 0, yoff = -1, width = 64, height = 18, oscillation = true },
    [0x34] = { xoff = -4, yoff = -3, width = 8, height = 8, oscillation = true },
    [0x35] = { xoff = 3, yoff = 1, width = 18, height = 32, oscillation = true },
    [0x36] = { xoff = 8, yoff = 9, width = 52, height = 46, oscillation = true },
    [0x37] = { xoff = 0, yoff = -7, width = 15, height = 20, oscillation = true },
    [0x38] = { xoff = 8, yoff = 17, width = 32, height = 40, oscillation = true },
    [0x39] = { xoff = 4, yoff = 4, width = 8, height = 10, oscillation = true },
    [0x3a] = { xoff = -8, yoff = 17, width = 32, height = 16, oscillation = true },
    [0x3b] = { xoff = 0, yoff = 1, width = 16, height = 13, oscillation = true },
    [0x3c] = { xoff = 12, yoff = 11, width = 3, height = 6, oscillation = true },
    [0x3d] = { xoff = 12, yoff = 22, width = 3, height = 20, oscillation = true },
    [0x3e] = { xoff = 16, yoff = 19, width = 254, height = 16, oscillation = true },
    [0x3f] = { xoff = 8, yoff = 9, width = 8, height = 24, oscillation = true }
}

local HITBOX_EXTENDED_SPRITE = {
    --[0x00] = { xoff = 0x17, yoff = 0x03, xrad = 0x03, yrad = 0x01},-- Free slot
    [0x01] = { xoff = 0x60, yoff = 0x03, xrad = 0x03, yrad = 0x01},  -- Puff of smoke with various objects
    [0x02] = { xoff = 0x03, yoff = 0x03, xrad = 0x01, yrad = 0x01, color_line = COLOUR.fireball },  -- Reznor fireball
    [0x03] = { xoff = 0x03, yoff = 0x03, xrad = 0x01, yrad = 0x01},  -- Flame left by hopping flame
    [0x04] = { xoff = 0x04, yoff = 0x04, xrad = 0x08, yrad = 0x08},  -- Hammer
    [0x05] = { xoff = 0x03, yoff = 0x03, xrad = 0x01, yrad = 0x01, color_line = COLOUR.fireball },  -- Player fireball
    [0x06] = { xoff = 0x04, yoff = 0x04, xrad = 0x08, yrad = 0x08},  -- Bone from Dry Bones
    [0x07] = { xoff = 0x00, yoff = 0x00, xrad = 0x00, yrad = 0x00},  -- Lava splash
    [0x08] = { xoff = 0x00, yoff = 0x00, xrad = 0x00, yrad = 0x00},  -- Torpedo Ted shooter's arm
    [0x09] = { xoff = 0x00, yoff = 0x00, xrad = 0x0f, yrad = 0x0f},  -- Unknown flickering object
    [0x0a] = { xoff = 0x04, yoff = 0x02, xrad = 0x08, yrad = 0x0c},  -- Coin from coin cloud game
    [0x0b] = { xoff = 0x03, yoff = 0x03, xrad = 0x01, yrad = 0x01, color_line = COLOUR.fireball },  -- Piranha Plant fireball
    [0x0c] = { xoff = 0x03, yoff = 0x03, xrad = 0x01, yrad = 0x01, color_line = COLOUR.fireball },  -- Lava Lotus's fiery objects
    [0x0d] = { xoff = 0x03, yoff = 0x03, xrad = 0x01, yrad = 0x01, color_line = 0x40a0 },  -- Baseball
    [0x0e] = { xoff = 0x03, yoff = 0x01, xrad = 0x01, yrad = 0xbc},  -- Wiggler's flower
    [0x0f] = { xoff = 0x03, yoff = 0x01, xrad = 0x01, yrad = 0x0b},  -- Trail of smoke
    [0x10] = { xoff = 0x04, yoff = 0x08, xrad = 0x08, yrad = 0x17},  -- Spinjump stars
    [0x11] = { xoff = -0x1, yoff = -0x4, xrad = 0x0b, yrad = 0x13, color_line = 0xa0ffff, color_bg = nil},  -- Yoshi fireballs - default: xoff = 0x03, yoff = 0x01, xrad = 0x01, yrad = 0xbd
    [0x12] = { xoff = 0x04, yoff = 0x08, xrad = 0x08, yrad = 0x1f},  -- Water bubble
}

;                              -- 0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f  10 11 12
local SPRITE_MEMORY_MAX = {[0] = 10, 6, 7, 6, 7, 5, 8, 5, 7, 9, 9, 4, 8, 6, 8, 9, 10, 6, 6}  -- the max of sprites in a room

-- Creates a set from a list
local function make_set(list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
end

-- from sprite number, returns oscillation flag
-- A sprite must be here iff it processes interaction with player every frame AND this bit is not working in the sprite_4_tweaker WRAM(0x167a)
local OSCILLATION_SPRITES = make_set{0x0e, 0x21, 0x29, 0x35, 0x54, 0x74, 0x75, 0x76, 0x77, 0x78, 0x81, 0x83, 0x87}

-- Sprites that have a custom hitbox drawing
local ABNORMAL_HITBOX_SPRITES = make_set{0x62, 0x63, 0x6b, 0x6c}

-- Sprites whose clipping interaction points usually matter
local GOOD_SPRITES_CLIPPING = make_set{
0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9, 0xa, 0xb, 0xc, 0xd, 0xf, 0x10, 0x11, 0x13, 0x14, 0x18,
0x1b, 0x1d, 0x1f, 0x20, 0x26, 0x27, 0x29, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f, 0x30, 0x31,
0x32, 0x34, 0x35, 0x3d, 0x3e, 0x3f, 0x40, 0x46, 0x47, 0x48, 0x4d, 0x4e,
0x51, 0x53, 0x6e, 0x6f, 0x70, 0x80, 0x81, 0x86, 
0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a, 0xa1, 0xa2, 0xa5, 0xa6, 0xa7, 0xab, 0xb2,
0xb4, 0xbb, 0xbc, 0xbd, 0xbf, 0xc3, 0xda, 0xdb, 0xdc, 0xdd, 0xdf
}

-- Extended sprites that don't interact with the player
local UNINTERESTING_EXTENDED_SPRITES = make_set{0x01, 0x07, 0x08, 0x0e, 0x10, 0x12}

-- ROM hacks in which the lag indicator feature was tested and works
local LAG_INDICATOR_ROMS = make_set{
    "0838e531fe22c077528febe14cb3ff7c492f1f5fa8de354192bdff7137c27f5b",  -- Super Mario World (U) [!].smc
    "75765b309c35978928f4a91fa58ffa89dc1575995b795afabad2586e67fce289",  -- Super Demo World - The Legend Continues (U) [!].smc
}

--#############################################################################
-- SCRIPT UTILITIES:


-- Variables used in various functions
COMMANDS = COMMANDS or {}  -- the list of scripts-made commands
local Cheat = {}  -- family of cheat functions and variables
local Previous = {}
local Video_callback = false
local User_input = {}
local Tiletable = {}
local Update_screen = true
local Font = nil
local Is_lagged = nil
local Show_options_menu = false
local Mario_boost_indicator = nil
local Show_player_point_position = false
local Sprites_info = {}  -- keeps track of useful sprite info that might be used outside the main sprite function
local Sprite_hitbox = {}  -- keeps track of what sprite slots must display the hitbox

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


-- Sum of the digits of a integer
local function sum_digits(number)
    local sum = 0
    while number > 0 do
        sum = sum + number%10
        number = math.floor(number*0.1)
    end
    
    return sum
end


-- unsigned to signed (based in <bits> bits)
local function signed(num, bits)
    local maxval = math.floor(2^(bits - 1))
    if num < maxval then return num else return num - 2*maxval end
end


-- Transform the binary representation of base into a string
-- For instance, if each bit of a number represents a char of base, then this function verifies what chars are on
local function decode_bits(data, base)
    local result = {}
    local i = 1
    local size = base:len()
    
    for ch in base:gmatch(".") do
        if bit.test(data, size-i) then
            result[i] = ch
        else
            result[i] = " "
        end
        i = i + 1
    end
    
    return table.concat(result)
end


-- Returns a table of arguments from string, according to pattern
-- the default [pattern] splits the arguments separated with spaces
local function get_arguments(arg, pattern)
    if not arg or arg == "" then return end
    pattern = pattern or "%S+"
    
    local list = {}
    for word in string.gmatch(arg, pattern) do
        list[#list + 1] = word
    end
    
    return table.unpack(list)
end


-- Returns the current microsecond since UNIX epoch
local function microseconds()
    local epoch, usecs = utime()
    return epoch*1000000 + usecs
end


-- Returns the local time of the OS
local function system_time()
    local epoch = os.date("*t", utime())  -- time since UNIX epoch converted to OS time
    local hour = epoch.hour
    local minute = epoch.min
    local second = epoch.sec
    
    return string.format("%.2d:%.2d:%.2d", hour, minute, second)
end


local function mouse_onregion(x1, y1, x2, y2)
    -- Reads external mouse coordinates
    local mouse_x = User_input.mouse_x.value
    local mouse_y = User_input.mouse_y.value
    
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


-- This makes <fn> be called for <timeout> microseconds
-- Timer.functions is a table of tables. Each inner table contains the function, the period of its call, the start(right now) and whether it's already registered
local Timer = {}
Timer.functions = {}

Timer.registerfunction = function(timeout, fn, name)
    local name = name or tostring(fn)
    if Timer.functions[name] then Timer.functions[name].start = microseconds() ; return end  -- restarts the active function, instead of calling it again
    
    Timer.functions[name] = {fn = fn, timeout = timeout, start = microseconds(), registered = false}
end


-- Those 'Keys functions' register presses and releases. Pretty much a copy from the script of player Fat Rat Knight (FRK)
-- http://tasvideos.org/userfiles/info/5481697172299767
Keys = {}
Keys.KeyPress=   {}
Keys.KeyRelease= {}

function Keys.registerkeypress(key,fn)
-- key - string. Which key do you wish to bind?
-- fn  - function. To execute on key press. False or nil removes it.
-- Return value: The old function previously assigned to the key.

    local OldFn= Keys.KeyPress[key]
    Keys.KeyPress[key]= fn
    --Keys.KeyPress[key]= Keys.KeyPress[key] or {}
    --table.insert(Keys.KeyPress[key], fn)
    input.keyhook(key,type(fn or Keys.KeyRelease[key]) == "function")
    return OldFn
end


function Keys.registerkeyrelease(key,fn)
-- key - string. Which key do you wish to bind?
-- fn  - function. To execute on key release. False or nil removes it.
-- Return value: The old function previously assigned to the key.

    local OldFn= Keys.KeyRelease[key]
    Keys.KeyRelease[key]= fn
    input.keyhook(key,type(fn or Keys.KeyPress[key]) == "function")
    return OldFn
end


function Keys.altkeyhook(s,t)
-- s,t - input expected is identical to on_keyhook input. Also passed along.
-- You may set by this line: on_keyhook = Keys.altkeyhook
-- Only handles keyboard input. If you need to handle other inputs, you may
-- need to have your own on_keyhook function to handle that, but you can still
-- call this when generic keyboard handling is desired.

    if     Keys.KeyPress[s]   and (t.value == 1) then
        Keys.KeyPress[s](s,t)
    elseif Keys.KeyRelease[s] and (t.value == 0) then
        Keys.KeyRelease[s](s,t)
    end
end


-- This is a fix of built-in function movie.get_frame
-- lsnes function movie.get_frame starts in subframe = 0 and ends in subframe = size - 1. That's quite inconvenient.
local function new_movie_get_frame(...)
    local inputmovie, subframe = ...
    if subframe == nil then
        return movie.get_frame(inputmovie - 1)
    else
        return movie.get_frame(inputmovie, subframe - 1)
    end
end


local function get_last_frame(advance)
    cf = movie.currentframe() - (advance and 0 or 1)
    if cf == -1 then cf = 0 end
    
    return cf
end


-- Stores the raw input in a table for later use. Should be called at the start of paint and timer callbacks
local function read_input()
    --Prev_input = next(User_input) == nil and input.raw() or User_input  -- Previous input, unused yet and probably will never be
    User_input = input.raw()
end


-- Extensions to the "gui" function, to handle fonts and opacity
gui.set_font = function(name)
    if (not OPTIONS.use_custom_fonts) or (not CUSTOM_FONTS[name]) then name = false end
    
    Font = name
end


gui.opacity = function(text, bg)
    Text_opacity = text or Text_opacity
    Bg_opacity = bg or Bg_opacity
    
    return Text_opacity, Bg_opacity
end


gui.font_width = function(font)
    font = font or Font
    return CUSTOM_FONTS[font] and CUSTOM_FONTS[font].width or LSNES_FONT_WIDTH
end


gui.font_height = function(font)
    font = font or Font
    return CUSTOM_FONTS[font] and CUSTOM_FONTS[font].height or LSNES_FONT_HEIGHT
end


-- Bitmap functions
local function copy_dbitmap(src)
    local width, height = src:size()
    local dest =  gui.dbitmap.new(width, height)
    dest:blit(0, 0, src, 0, 0, width, height)
    
    return dest
end


local function copy_palette(pal)
    local copy = gui.palette.new()
    local color
    
    for index = 0, 65535 do
        color = pal:get(index)
        if not color then break end
        
        copy:set(index, color)
    end
    
    return copy
end


local function bitmap_to_dbitmap(bitmap, palette)
    local w, h =  bitmap:size()
    local dbitmap = gui.dbitmap.new(w, h)
    local index, color
    
    for x = 0, w - 1 do
        for y = 0, h - 1 do
            index = bitmap:pget(x,y)
            color = palette:get(index)
            dbitmap:pset(x, y, color)
        end
    end
    
    return dbitmap
end


local function ROM_loaded()
    for key, value in pairs(memory2()) do
        if value == "ROM" then return true end
    end
    
    return false
end


local ROM_hash, Prev_ROM_hash = nil, nil
local function ROM_sha256()
    Prev_ROM_hash = ROM_hash
    
    if not ROM_hash then
        local size  = memory2.ROM:info().size
        ROM_hash = memory2.ROM:sha256(0, size)
    end
    
    if Prev_ROM_hash and Prev_ROM_hash ~= ROM_hash then print(string.format("ROM CHANGE from %s to %s.", Prev_ROM_hash, ROM_hash)) end
    
    return ROM_hash
end


local Runmode, Lsnes_speed
local Readonly, Framecount, Subframecount, Lagcount, Rerecords
local Lastframe_emulated, Starting_subframe_last_frame, Size_last_frame, Final_subframe_last_frame
local Nextframe, Starting_subframe_next_frame, Starting_subframe_next_frame, Final_subframe_next_frame
local function lsnes_status()
    if LSNES_VERSION == "rrtest" then
        Runmode = gui.get_runmode()
        Lsnes_speed = settings.get_speed()
    end
    
    Readonly = movie.readonly()
    Framecount = movie.framecount()
    Subframecount = movie.get_size()
    Lagcount = movie.lagcount()
    Rerecords = movie.rerecords()
    
    -- Last frame info
    if not Lastframe_emulated then Lastframe_emulated = get_last_frame(false) end
    Starting_subframe_last_frame = movie.find_frame(Lastframe_emulated) + 1
    Size_last_frame = Lastframe_emulated >= 0 and movie.frame_subframes(Lastframe_emulated) or 1
    Final_subframe_last_frame = Starting_subframe_last_frame + Size_last_frame - 1
    
    -- Next frame info (only relevant in readonly mode)
    Nextframe = Lastframe_emulated + 1
    Starting_subframe_next_frame = movie.find_frame(Nextframe) + 1
    Size_next_frame = movie.frame_subframes(Nextframe)
    Final_subframe_next_frame = Starting_subframe_next_frame + Size_next_frame - 1
    
end


-- Get screen values of the game and emulator areas
local Padding_left, Padding_right, Padding_top, Padding_bottom
local Border_left, Border_right, Border_top, Border_bottom, Buffer_width, Buffer_height
local Screen_width, Screen_height, Pixel_rate_x, Pixel_rate_y
local function lsnes_screen_info()
    -- Some previous values
    Previous.Border_left = Border_left
    Previous.Border_right = Border_right
    Previous.Border_top = Border_top
    Previous.Border_bottom = Border_bottom
    
    Padding_left = tonumber(settings.get("left-border"))  -- Advanced configuration padding dimensions
    Padding_right = tonumber(settings.get("right-border"))
    Padding_top = tonumber(settings.get("top-border"))
    Padding_bottom = tonumber(settings.get("bottom-border"))
    
    Border_left = math.max(Padding_left, OPTIONS.left_gap)  -- Borders' dimensions
    Border_right = math.max(Padding_right, OPTIONS.right_gap)
    Border_top = math.max(Padding_top, OPTIONS.top_gap)
    Border_bottom = math.max(Padding_bottom, OPTIONS.bottom_gap)
    
    Buffer_width, Buffer_height = gui.resolution()  -- Game area
    if Video_callback then  -- The video callback messes with the resolution
        Buffer_width = 2*Buffer_width
        Buffer_height = 2*Buffer_height
    end
    
	Screen_width = Buffer_width + Border_left + Border_right  -- Emulator area
	Screen_height = Buffer_height + Border_top + Border_bottom
    
    Pixel_rate_x = Buffer_width/256
	Pixel_rate_y = Buffer_height/224
end


-- Changes transparency of a color: result is opaque original * transparency level (0.0 to 1.0). Acts like gui.opacity() in Snes9x.
local function change_transparency(color, transparency)
    if type(color) ~= "number" then
        color = gui.color(color)
    end
    if transparency > 1 then transparency = 1 end
    if transparency < 0 then transparency = 0 end
    
    local a = bit.lrshift(color, 24)
    local rgb = color - (256*256*256)*a
    local new_a = 0x100 - math.ceil((transparency * (0x100 - a)))
    local new_color = (256*256*256)*new_a + rgb
    
    return new_color
end


-- Takes a position and dimensions of a rectangle and returns a new position if this rectangle has points outside the screen
local function put_on_screen(x, y, width, height)
    local x_screen, y_screen
    width = width or 0
    height = height or 0
    
    if x < - Border_left then
        x_screen = - Border_left
    elseif x > Buffer_width + Border_right - width then
        x_screen = Buffer_width + Border_right - width
    else
        x_screen = x
    end
    
    if y < - Border_top then
        y_screen = - Border_top
    elseif y > Buffer_height + Border_bottom - height then
        y_screen = Buffer_height + Border_bottom - height
    else
        y_screen = y
    end
    
    return x_screen, y_screen
end


-- returns the (x, y) position to start the text and its length:
-- number, number, number text_position(x, y, text, font_width, font_height[[[[, always_on_client], always_on_game], ref_x], ref_y])
-- x, y: the coordinates that the refereed point of the text must have
-- text: a string, don't make it bigger than the buffer area width and don't include escape characters
-- font_width, font_height: the sizes of the font
-- always_on_client, always_on_game: boolean
-- ref_x and ref_y: refer to the relative point of the text that must occupy the origin (x,y), from 0% to 100%
--                  for instance, if you want to display the middle of the text in (x, y), then use 0.5, 0.5
local function text_position(x, y, text, font_width, font_height, always_on_client, always_on_game, ref_x, ref_y)
    -- Reads external variables
    local border_left     = Border_left
    local border_right    = Border_right
    local border_top      = Border_top
    local border_bottom   = Border_bottom
    local buffer_width    = Buffer_width
    local buffer_height   = Buffer_height
    
    -- text processing
    local text_length = string.len(text)
    text_length = text_length*font_width
    
    -- reference point
    if not ref_x then ref_x = 0 end
    if not ref_y then ref_y = 0 end
    
    -- adjustment if text is supposed to be on screen area
    local x_end = x + text_length
    local y_end = y + font_height
    
    -- actual position, relative to game area origin
    local x = x - text_length*ref_x
    local y = y - font_height*ref_y
    
    if always_on_game then
        if x < 0 then x = 0 end
        if y < 0 then y = 0 end
        
        if x_end > buffer_width  then x = buffer_width  - text_length end
        if y_end > buffer_height then y = buffer_height - font_height end
        
    elseif always_on_client then
        if x < -border_left then x = -border_left end
        if y < -border_top  then y = -border_top  end
        
        if x_end > buffer_width  + border_right  then x = buffer_width  + border_right  - text_length end
        if y_end > buffer_height + border_bottom then y = buffer_height + border_bottom - font_height end
    end
    
    return math.floor(x), math.floor(y), text_length
end


local function draw_text(x, y, text, ...)
    -- Reads external variables
    local font_name = Font or false
    local font_width  = gui.font_width()
    local font_height = gui.font_height()
    local full_bg = OPTIONS.full_background_under_text and not font_name
    local bg_default_color = full_bg and COLOUR.background or COLOUR.outline
    local text_color, halo_color, always_on_client, always_on_game, ref_x, ref_y
    local arg1, arg2, arg3, arg4, arg5, arg6 = ...
    
    if type(arg1) == "boolean" or type(arg1) == "nil" then
        
        text_color = COLOUR.text
        halo_color = bg_default_color
        always_on_client, always_on_game, ref_x, ref_y = arg1, arg2, arg3, arg4
        
    elseif type(arg2) == "boolean" or type(arg2) == "nil" then
        
        text_color = arg1
        halo_color = bg_default_color
        always_on_client, always_on_game, ref_x, ref_y = arg2, arg3, arg4, arg5
        
    else
        
        text_color, halo_color = arg1, arg2
        always_on_client, always_on_game, ref_x, ref_y = arg3, arg4, arg5, arg6
        
    end
    
    text_color = change_transparency(text_color, Text_max_opacity * Text_opacity)
    halo_color = change_transparency(halo_color, not font_name and Background_max_opacity * Bg_opacity
                                                                or Text_max_opacity * Text_opacity)
    local x_pos, y_pos, length = text_position(x, y, text, font_width, font_height, always_on_client, always_on_game, ref_x, ref_y)
    
    -- drawing is glitched if coordinates are before the borders
    if not font_name then
        if x_pos < - Border_left or y_pos < - Border_top then return end
    end
    
    -- CUSTOMFONT text positioning 
    if LSNES_VERSION ~= "rrtest" then
        x_pos = x_pos + Border_left
        y_pos = y_pos + Border_top
    end
    
    draw_font[font_name or false](x_pos, y_pos, text, text_color,
                        full_bg and halo_color or -1, full_bg and -1 or halo_color)
    ;
    
    return x_pos + length - (LSNES_VERSION ~= "rrtest" and Border_left or 0), y_pos + font_height - (LSNES_VERSION ~= "rrtest" and Border_top or 0), length
end


local function alert_text(x, y, text, text_color, bg_color, always_on_game, ref_x, ref_y)
    -- Reads external variables
    local font_width  = LSNES_FONT_WIDTH
    local font_height = LSNES_FONT_HEIGHT
    
    local x_pos, y_pos, text_length = text_position(x, y, text, font_width, font_height, false, always_on_game, ref_x, ref_y)
    
    text_color = change_transparency(text_color, Text_max_opacity * Text_opacity)
    bg_color = change_transparency(bg_color, Background_max_opacity * Bg_opacity)
    gui.text(x_pos, y_pos, text, text_color, bg_color)
end


local function draw_over_text(x, y, value, base, color_base, color_value, color_bg, always_on_client, always_on_game, ref_x, ref_y)
    -- Font
    local height = gui.font_height()
    
    value = decode_bits(value, base)
    local x_end, y_end, length = draw_text(x, y, base,  color_base,   color_bg, always_on_client, always_on_game, ref_x, ref_y)
    draw_text(x_end - length, y_end - height, value, color_value, (not Font and OPTIONS.full_background_under_text and -1) or 0x100000000, always_on_client, always_on_game, ref_x, ref_y)
    
    return x_end, y_end, length
end


-- Returns frames-time conversion
local function frame_time(frame)
    if not NTSC_FRAMERATE then error("NTSC_FRAMERATE undefined."); return end
    
    local total_seconds = frame/NTSC_FRAMERATE
    local hours, minutes, seconds = bit.multidiv(total_seconds, 3600, 60)
    seconds = math.floor(seconds)
    
    local miliseconds = 1000* (total_seconds%1)
    if hours == 0 then hours = "" else hours = string.format("%d:", hours) end
    local str = string.format("%s%.2d:%.2d.%03.0f", hours, minutes, seconds, miliseconds)
    return str
end


-- draw a pixel given (x,y) with SNES' pixel sizes
local function draw_pixel(x, y, ...)
    -- Protection against non-integers
    x = math.floor(x)
    y = math.floor(y)
    
    gui.pixel(2*x, 2*y, ...)
    gui.pixel(2*x + 1, 2*y, ...)
    gui.pixel(2*x, 2*y + 1, ...)
    gui.pixel(2*x + 1, 2*y + 1, ...)
end


-- draws a line given (x,y) and (x',y') with given scale and SNES' pixel thickness (whose scale is 2)
local function draw_line(x1, y1, x2, y2, scale, ...)
    -- Draw from top-left to bottom-right
    if x2 < x1 then
        x1, x2 = x2, x1
    end
    if y2 < y1 then
        y1, y2 = y2, y1
    end
    
    x1, y1, x2, y2 = scale*x1, scale*y1, scale*x2, scale*y2
    if x1 == x2 then
        gui.line(x1, y1, x2, y2 + 1, ...)
        gui.line(x1 + 1, y1, x2 + 1, y2 + 1, ...)
    elseif y1 == y2 then
        gui.line(x1, y1, x2 + 1, y2, ...)
        gui.line(x1, y1 + 1, x2 + 1, y2 + 1, ...)
    else
        gui.line(x1, y1, x2, y2, ...)
        gui.line(x1 + 1, y1, x2 + 1, y2, ...)
        gui.line(x1, y1 + 1, x2, y2 + 1, ...)
        gui.line(x1 + 1, y1 + 1, x2 + 1, y2 + 1, ...)
    end
end


-- draws a box given (x,y) and (x',y') with SNES' pixel sizes
local function draw_box(x1, y1, x2, y2, ...)
    -- Draw from top-left to bottom-right
    if x2 < x1 then
        x1, x2 = x2, x1
    end
    if y2 < y1 then
        y1, y2 = y2, y1
    end
    
    local x = 2*x1
    local y = 2*y1
    local w = (2 * (x2 - x1)) + 2  -- adds thickness
    local h = (2 * (y2 - y1)) + 2  -- adds thickness
    
    gui.rectangle(x, y, w, h, ...)
end


-- draws a rectangle given (x,y) and dimensions, with SNES' pixel sizes
local function draw_rectangle(x, y, w, h, ...)
    x, y, w, h = 2*x, 2*y, 2*w + 2, 2*h + 2
    gui.rectangle(x, y, w, h, 2, ...)
end


-- Background opacity functions
local function increase_opacity()
    if Text_max_opacity <= 0.9 then Text_max_opacity = Text_max_opacity + 0.1
    else
        if Background_max_opacity <= 0.9 then Background_max_opacity = Background_max_opacity + 0.1 end
    end
end


local function decrease_opacity()
    if  Background_max_opacity >= 0.1 then Background_max_opacity = Background_max_opacity - 0.1
    else
        if Text_max_opacity >= 0.1 then Text_max_opacity = Text_max_opacity - 0.1 end
    end
end


-- displays a button everytime in (x,y)
-- if user clicks onto it, fn is executed once
local Script_buttons = {}
local function create_button(x, y, text, fn, always_on_client, always_on_game, ref_x, ref_y)  -- TODO: use text or dbitmap to display
    local font_width = gui.font_width()
    local height = gui.font_height()
    
    local x, y, width = text_position(x, y, text, font_width, height, always_on_client, always_on_game, ref_x, ref_y)
    
    -- draw the button
    gui.box(x, y, width, height, 1)
    draw_text(x, y, text, COLOUR.button_text, -1)
    
    -- updates the table of buttons
    table.insert(Script_buttons, {x = x, y = y, width = width, height = height, text = text, colour = fill, bg_colour = bg, action = fn})
end


-- Lateral Paddings (those persist if the script is closed and can be edited under Configure > Settings > Advanced > UI)
local function adjust_lateral_paddings()
    gui.set_font(false)
    local bottom_pad = Padding_bottom
    local top_pad = Padding_top
    local left_pad = Padding_left
    local right_pad = Padding_right
    
    -- rectangle the helps to see the padding values
    gui.rectangle(-left_pad, -top_pad, Buffer_width + right_pad + left_pad, Buffer_height + bottom_pad + top_pad,
        1, Show_options_menu and COLOUR.warning2 or 0xb0808080)
    ;
    
    create_button(-Border_left, Buffer_height/2, "+", function() settings.set("left-border", tostring(left_pad + 16)) end, true, false, 0.0, 1.0)
    create_button(-Border_left, Buffer_height/2, "-", function() if left_pad > 16 then settings.set("left-border", tostring(left_pad - 16)) else settings.set("left-border", "0") end end, true, false, 0.0, 0.0)
    
    create_button(Buffer_width, Buffer_height/2, "+", function() settings.set("right-border", tostring(right_pad + 16)) end, true, false, 0.0, 1.0)
    create_button(Buffer_width, Buffer_height/2, "-", function() if right_pad > 16 then settings.set("right-border", tostring(right_pad - 16)) else settings.set("right-border", "0") end end, true, false, 0.0, 0.0)
    
    create_button(Buffer_width/2, Buffer_height, "+", function() settings.set("bottom-border", tostring(bottom_pad + 16)) end, true, false, 1.0, 0.0)
    create_button(Buffer_width/2, Buffer_height, "-", function() if bottom_pad > 16 then settings.set("bottom-border", tostring(bottom_pad - 16)) else settings.set("bottom-border", "0") end end, true, false, 0.0, 0.0)
    
    create_button(Buffer_width/2, -Border_top, "+", function() settings.set("top-border", tostring(top_pad + 16)) end, true, false, 1.0, 0.0)
    create_button(Buffer_width/2, -Border_top, "-", function() if top_pad > 16 then settings.set("top-border", tostring(top_pad - 16)) else settings.set("top-border", "0") end end, true, false, 0.0, 0.0)
end


local function options_menu()
    if not Show_options_menu then return end
    
    -- Pauses emulator and draws the background
    if LSNES_VERSION == "rrtest" then
        if Runmode == "normal" then exec("pause-emulator") end
    end
    gui.rectangle(0, 0, Buffer_width, Buffer_height, 2, COLOUR.mainmenu_outline, COLOUR.mainmenu_bg)
    
    -- Font stuff
    gui.set_font(false)
    local delta_x = gui.font_width()
    local delta_y = gui.font_height() + 4
    local x_pos, y_pos = 4, 4
    local tmp
    
    -- Exit menu button
    create_button(Buffer_width, 0, " X ", function() Show_options_menu = false end, true, true)
    
    -- External buttons
    tmp = OPTIONS.display_controller_input and "Hide Input" or "Show Input"
    create_button(0, 0, tmp, function() OPTIONS.display_controller_input = not OPTIONS.display_controller_input end, true, false, 1.0, 1.0)
    
    tmp = OPTIONS.allow_cheats and "Cheats: allowed" or "Cheats: blocked"
    create_button(-Border_left, Buffer_height, tmp, function() OPTIONS.allow_cheats = not OPTIONS.allow_cheats end, true, false, 0.0, 1.0)
    
    create_button(Buffer_width + Border_right, Buffer_height, "Erase Tiles", function() Tiletable = {} end, true, false, 0.0, 1.0)
    
    -- Show/hide options
    tmp = OPTIONS.display_debug_info and "Yes" or "No "
    create_button(x_pos, y_pos, tmp, function() OPTIONS.display_debug_info = not OPTIONS.display_debug_info end)
    gui.text(x_pos + 4*delta_x, y_pos, "Show Some Debug Info?")
    y_pos = y_pos + delta_y
    
    tmp = OPTIONS.display_movie_info and "Yes" or "No "
    create_button(x_pos, y_pos, tmp, function() OPTIONS.display_movie_info = not OPTIONS.display_movie_info end)
    gui.text(x_pos + 4*delta_x, y_pos, "Display Movie Info?")
    y_pos = y_pos + delta_y
    
    tmp = OPTIONS.display_misc_info and "Yes" or "No "
    create_button(x_pos, y_pos, tmp, function() OPTIONS.display_misc_info = not OPTIONS.display_misc_info end)
    gui.text(x_pos + 4*delta_x, y_pos, "Display Misc Info?")
    y_pos = y_pos + delta_y
    
    tmp = OPTIONS.display_player_info and "Yes" or "No "
    create_button(x_pos, y_pos, tmp, function() OPTIONS.display_player_info = not OPTIONS.display_player_info end)
    gui.text(x_pos + 4*delta_x, y_pos, "Show Player Info?")
    y_pos = y_pos + delta_y
    
    tmp = OPTIONS.display_sprite_info and "Yes" or "No "
    create_button(x_pos, y_pos, tmp, function() OPTIONS.display_sprite_info = not OPTIONS.display_sprite_info end)
    gui.text(x_pos + 4*delta_x, y_pos, "Show Sprite Info?")
    y_pos = y_pos + delta_y
    
    tmp = OPTIONS.display_sprite_hitbox and "Yes" or "No "
    create_button(x_pos, y_pos, tmp, function() OPTIONS.display_sprite_hitbox = not OPTIONS.display_sprite_hitbox end)
    gui.text(x_pos + 4*delta_x, y_pos, "Show Sprite Hitbox?")
    y_pos = y_pos + delta_y
    
    tmp = OPTIONS.display_extended_sprite_info and "Yes" or "No "
    create_button(x_pos, y_pos, tmp, function() OPTIONS.display_extended_sprite_info = not OPTIONS.display_extended_sprite_info end)
    gui.text(x_pos + 4*delta_x, y_pos, "Show Extended Sprite Info?")
    y_pos = y_pos + delta_y
    
    tmp = OPTIONS.display_bounce_sprite_info and "Yes" or "No "
    create_button(x_pos, y_pos, tmp, function() OPTIONS.display_bounce_sprite_info = not OPTIONS.display_bounce_sprite_info end)
    gui.text(x_pos + 4*delta_x, y_pos, "Show Bounce Sprite Info?")
    y_pos = y_pos + delta_y
    
    tmp = OPTIONS.display_level_info and "Yes" or "No "
    create_button(x_pos, y_pos, tmp, function() OPTIONS.display_level_info = not OPTIONS.display_level_info end)
    gui.text(x_pos + 4*delta_x, y_pos, "Show Level Info?")
    y_pos = y_pos + delta_y
    
    tmp = OPTIONS.display_pit_info and "Yes" or "No "
    create_button(x_pos, y_pos, tmp, function() OPTIONS.display_pit_info = not OPTIONS.display_pit_info end)
    gui.text(x_pos + 4*delta_x, y_pos, "Show Pit?")
    y_pos = y_pos + delta_y
    
    tmp = OPTIONS.display_yoshi_info and "Yes" or "No "
    create_button(x_pos, y_pos, tmp, function() OPTIONS.display_yoshi_info = not OPTIONS.display_yoshi_info end)
    gui.text(x_pos + 4*delta_x, y_pos, "Show Yoshi Info?")
    y_pos = y_pos + delta_y
    
    tmp = OPTIONS.display_counters and "Yes" or "No "
    create_button(x_pos, y_pos, tmp, function() OPTIONS.display_counters = not OPTIONS.display_counters end)
    gui.text(x_pos + 4*delta_x, y_pos, "Show Counters Info?")
    y_pos = y_pos + delta_y
    
    -- Another options
    tmp = OPTIONS.use_custom_fonts and "Yes" or "No "
    create_button(x_pos, y_pos, tmp, function() OPTIONS.use_custom_fonts = not OPTIONS.use_custom_fonts end)
    gui.text(x_pos + 4*delta_x, y_pos, "Use custom fonts?")
    y_pos = y_pos + delta_y
    
    tmp = OPTIONS.full_background_under_text and "Full" or "Halo"
    create_button(x_pos, y_pos, tmp, function() OPTIONS.full_background_under_text = not OPTIONS.full_background_under_text end)
    gui.text(x_pos + 5*delta_x, y_pos, "Display default text with full background or with halo?")
    y_pos = y_pos + 2*delta_y
    
    -- Misc buttons
    gui.text(x_pos, y_pos, "Misc options:")
    y_pos = y_pos + delta_y
    create_button(x_pos, y_pos, "Reset Padding Values", function() settings.set("left-border", "0"); settings.set("right-border", "0"); settings.set("top-border", "0"); settings.set("bottom-border", "0") end)
    y_pos = y_pos + delta_y
    
    -- Useful tips
    create_button(x_pos, y_pos, "Show tips in lsnes: Messages", function()
        print("\n")
        print(" - - - TIPS - - - ")
        print("MOUSE:")
        print("Use the left click to draw blocks and to see the Map16 properties.")
        print("Use the right click to toogle the hitbox mode of Mario and sprites.")
        print("\n")
        
        print("CHEATS(better turn off while recording a movie):")
        print("L+R+up: stop gravity for Mario fly / L+R+down to cancel")
        print("While paused: B+select to get out of the level")
        print("              X+select to beat the level (main exit)")
        print("              A+select to get the secret exit (don't use it if there isn't one)")
        print("Command cheats(use lsnes:Messages and type the commands, that are cAse-SENSitiVE):")
        print("score <value>:   set the score to <value>.")
        print("coin <value>:    set the coin number to <value>.")
        print("powerup <value>: set the powerup number to <value>.")
        
        print("\n")
        print("OTHERS:")
        print(fmt("Press \"%s\" for more and \"%s\" for less opacity.", OPTIONS.hotkey_increase_opacity, OPTIONS.hotkey_decrease_opacity))
        print("If performance suffers, disable some options that are not needed at the moment.")
        print("", "(input display and sprites are the ones that slow down the most).")
        print("It's better to play without the mouse over the game window.")
        print(" - - - end of tips - - - ")
    end)
    
    -- Lateral Paddings
    adjust_lateral_paddings()
    
    return true
end


-- Gets input of the 1st controller / Might be deprecated someday...
local Joypad = {}
local function get_joypad()
    Joypad["B"] = input.get2(1, 0, 0)
    Joypad["Y"] = input.get2(1, 0, 1)
    Joypad["select"] = input.get2(1, 0, 2)
    Joypad["start"] = input.get2(1, 0, 3)
    Joypad["up"] = input.get2(1, 0, 4)
    Joypad["down"] = input.get2(1, 0, 5)
    Joypad["left"] = input.get2(1, 0, 6)
    Joypad["right"] = input.get2(1, 0, 7)
    Joypad["A"] = input.get2(1, 0, 8)
    Joypad["X"] = input.get2(1, 0, 9)
    Joypad["L"] = input.get2(1, 0, 10)
    Joypad["R"] = input.get2(1, 0, 11)
end


local function input_object_to_string(inputframe, remove_num)
    local input_line = inputframe:serialize()
    local str = string.sub(input_line, remove_num) -- remove the "FR X Y|" from input
    
    str = string.gsub(str, "%p", "\032") -- ' '
    str = string.gsub(str, "u", "\094")  -- '^'
    str = string.gsub(str, "d", "v")     -- 'v'
    str = string.gsub(str, "l", "\060")  -- '<'
    str = string.gsub(str, "r", "\062")  -- '>'
    
    local subframe_input
    if string.sub(input_line, 1, 1) ~= "F" then subframe_input = true end
    
    return str, subframe_input
end


-- Displays input of the 1st controller
-- Beware that this will fail if there's more than 1 controller in the movie
local function display_input()
    -- Font
    gui.set_font(false)
    gui.opacity(1.0, 1.0)
    local width  = gui.font_width()
    local height = gui.font_height()
    
    -- Position of the drawings
    local y_final_input = (Buffer_height - height)/2
    local number_of_inputs = math.floor(y_final_input/height)
    local sequence = "BYsS^v<>AXLR"
    local x_input = -string.len(sequence)*width - 2
    local remove_num = 8
    
    -- Calculate the extreme-left position to display the frames and the rectangles
    local frame_length = string.len(Lastframe_emulated + number_of_inputs)*width  -- fix this in readwrite mode and readonly (when power of 10 appears in the bottom)
    local rectangle_x = x_input - frame_length - 1
    
    if Starting_subframe_last_frame == 0 and Lastframe_emulated > 0 then gui.opacity(0.3) end  -- still pretty bad, fix
    for i = number_of_inputs, - number_of_inputs, -1 do
        local subframe = Starting_subframe_last_frame - i
        
        if subframe > Subframecount then break end
        if subframe > 0 then
            local current_input = new_movie_get_frame(subframe)
            local input_line, subframe_input = input_object_to_string(current_input, remove_num)
            
            local color_input = (Readonly and COLOUR.text) or COLOUR.joystick_input
            local color_bg = COLOUR.joystick_input_bg
            
            if subframe_input then  -- an ignored subframe
                gui.opacity(nil, 0.4)
                color_input = COLOUR.warning
                color_bg = COLOUR.warning_bg
            end
            
            local frame_to_display = Lastframe_emulated - i
            draw_text(x_input - frame_length - 2, y_final_input - i*height, frame_to_display, COLOUR.text)
            draw_text(x_input, y_final_input - i*height, sequence, color_bg, -1)
            draw_text(x_input, y_final_input - i*height, input_line, color_input, -1)
            
            -- This only makes clear that the last frame is not recorded yet, in readwrite mode
            if subframe == Subframecount and not Readonly then
                draw_text(x_input - frame_length - 2, y_final_input - (i-1)*height, frame_to_display + 1, COLOUR.text)
                draw_text(x_input, y_final_input - (i-1)*height, " Unrecorded", color_bg, -1)
            end
            
            gui.opacity(nil, 1.0)
        end
        
    end
    
    gui.opacity(1.0)
    gui.line(math.floor(rectangle_x), math.floor(y_final_input + height), -1, math.floor(y_final_input + height), 0x40ff0000)
    
end


--#############################################################################
-- SMW FUNCTIONS:


local Real_frame, Previous_real_frame, Effective_frame, Lag_indicator, Game_mode
local Level_index, Room_index, Level_flag, Current_level, Is_paused, Lock_animation_flag
local Camera_x, Camera_y
local function scan_smw()
    Previous_real_frame = Real_frame or u8(WRAM.real_frame)
    Real_frame = u8(WRAM.real_frame)
    Effective_frame = u8(WRAM.effective_frame)
    Lag_indicator = memory2.WRAM:word(WRAM.lag_indicator)
    Game_mode = u8(WRAM.game_mode)
    Level_index = u8(WRAM.level_index)
    Level_flag = u8(WRAM.level_flag_table + Level_index)
    Is_paused = u8(WRAM.level_paused) == 1
    Lock_animation_flag = u8(WRAM.lock_animation_flag)
    Room_index = (256*256)*u8(WRAM.room_index) + 256*u8(WRAM.room_index + 1) + u8(WRAM.room_index + 2)
    
    -- In level frequently used info
    Camera_x = s16(WRAM.camera_x)
    Camera_y = s16(WRAM.camera_y)
    Yoshi_riding_flag = u8(WRAM.yoshi_riding_flag) ~= 0
end


-- Converts the in-game (x, y) to SNES-screen coordinates
local function screen_coordinates(x, y, camera_x, camera_y)
    local x_screen = (x - camera_x)
    local y_screen = (y - camera_y) - Y_CAMERA_OFF
    
    return x_screen, y_screen
end


-- Converts lsnes-screen coordinates to in-game (x, y)
local function game_coordinates(x_lsnes, y_lsnes, camera_x, camera_y)
    local x_game = math.floor((x_lsnes/2) + camera_x)
    local y_game = math.floor((y_lsnes/2  + Y_CAMERA_OFF) + camera_y)
    
    return x_game, y_game
end


-- Creates lateral gaps
local function create_gaps()
    -- The emulator may crash if the lateral gaps are set to floats
    OPTIONS.left_gap = math.floor(OPTIONS.left_gap)
    OPTIONS.right_gap = math.floor(OPTIONS.right_gap)
    OPTIONS.top_gap = math.floor(OPTIONS.top_gap)
    OPTIONS.bottom_gap = math.floor(OPTIONS.bottom_gap)
    
    gui.left_gap(OPTIONS.left_gap)  -- for input display
    gui.right_gap(OPTIONS.right_gap)
    gui.top_gap(OPTIONS.top_gap)
    gui.bottom_gap(OPTIONS.bottom_gap)
end


-- Returns the extreme values that Mario needs to have in order to NOT touch a rectangular object
local function display_boundaries(x_game, y_game, width, height, camera_x, camera_y)
    -- Font
    gui.set_font("snes9xluasmall")
    gui.opacity(1.0, 0.8)
    
    -- Coordinates around the rectangle
    local left = width*math.floor(x_game/width)
    local top = height*math.floor(y_game/height)
    left, top = screen_coordinates(left, top, camera_x, camera_y)
    local right = left + width - 1
    local bottom = top + height - 1
    
    -- Reads WRAM values of the player
    local is_ducking = u8(WRAM.is_ducking)
    local powerup = u8(WRAM.powerup)
    local is_small = is_ducking ~= 0 or powerup == 0
    
    -- Left
    local left_text = string.format("%4d.0", width*math.floor(x_game/width) - 13)
    draw_text(2*left, (top+bottom), left_text, false, false, 1.0, 0.5)
    
    -- Right
    local right_text = string.format("%d.f", width*math.floor(x_game/width) + 12)
    draw_text(2*right, top+bottom, right_text, false, false, 0.0, 0.5)
    
    -- Top
    local value = (Yoshi_riding_flag and y_game - 16) or y_game
    local top_text = fmt("%d.0", width*math.floor(value/width) - 32)
    draw_text(left+right, 2*top, top_text, false, false, 0.5, 1.0)
    
    -- Bottom
    value = height*math.floor(y_game/height)
    if not is_small and not Yoshi_riding_flag then
        value = value + 0x07
    elseif is_small and Yoshi_riding_flag then
        value = value - 4
    else
        value = value - 1  -- the 2 remaining cases are equal
    end
    
    local bottom_text = fmt("%d.f", value)
    draw_text(left+right, 2*bottom, bottom_text, false, false, 0.5, 0.0)
    
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
    --draw_text(Buffer_width/2, Buffer_height/2, {"%x: %x%x%x%x%x%x%x%x", level_mode_settings, b1, b2, b3, b4, b5, b6, b7, b8}, COLOUR.text, COLOUR.background)
    
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
    local num_x = math.floor(x_game/16)
    local num_y = math.floor(y_game/16)
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
    
    local num_id, kind
    if level_type == "Horizontal" then
        num_id = 16*27*math.floor(num_x/16) + 16*num_y + num_x%16
        kind = (num_id >= 0 and num_id <= 0x35ff) and 256*u8(0x1c800 + num_id) + u8(0xc800 + num_id)
    else
        local nx = math.floor(num_x/16)
        local ny = math.floor(num_y/16)
        local n = 2*ny + nx
        local num_id = 16*16*n + 16*(num_y%16) + num_x%16
        kind = (num_id >= 0 and num_id <= 0x37ff) and 256*u8(0x1c800 + num_id) + u8(0xc800 + num_id)
    end
    
    if kind then return  num_x, num_y, kind end
end


local function draw_tilesets(camera_x, camera_y)
    local x_origin, y_origin = screen_coordinates(0, 0, camera_x, camera_y)
    local x_mouse, y_mouse = game_coordinates(User_input.mouse_x.value, User_input.mouse_y.value, camera_x, camera_y)
    x_mouse = 16*math.floor(x_mouse/16)
    y_mouse = 16*math.floor(y_mouse/16)
    
    for number, positions in ipairs(Tiletable) do
        -- Calculate the Lsnes coordinates
        local left = positions[1] + x_origin
        local top = positions[2] + y_origin
        local right = left + 15
        local bottom = top + 15
        local x_game, y_game = game_coordinates(2*left, 2*top, camera_x, camera_y)
        
        -- Returns if block is way too outside the screen
        if 2*left > - Border_left - 32 and 2*top  > - Border_top - 32 and
        2*right < Screen_width  + Border_right + 32 and 2*bottom < Screen_height + Border_bottom + 32 then
            
            -- Drawings
            draw_rectangle(left, top, 15, 15, COLOUR.block, Real_frame%2 == 1 and COLOUR.block_bg or -1)  -- the block with oscillation
            
            if Tiletable[number][3] then
                display_boundaries(x_game, y_game, 16, 16, camera_x, camera_y)  -- the text around it
            end
            
            -- Experimental: Map16
            gui.set_font("snes9xtext")
            local num_x, num_y, kind = get_map16_value(x_game, y_game)
            if kind and x_mouse == positions[1] and y_mouse == positions[2] then
                draw_text(2*left + 8, 2*top - gui.font_height(), fmt("Map16 (%d, %d), %x", num_x, num_y, kind), false, false, 0.5, 1.0)
            end
            
        end
        
    end
    
end


-- if the user clicks in a tile, it will be be drawn
-- if click is onto drawn region, it'll be erased
-- there's a max of possible tiles
-- Tileset[n] is a triple compound of {x, y, draw info?}
local function select_tile()
    local x_mouse, y_mouse = game_coordinates(User_input.mouse_x.value, User_input.mouse_y.value, Camera_x, Camera_y)
    x_mouse = 16*math.floor(x_mouse/16)
    y_mouse = 16*math.floor(y_mouse/16)
    
    for number, positions in ipairs(Tiletable) do  -- if mouse points a drawn tile, erase it
        if x_mouse == positions[1] and y_mouse == positions[2] then
            if Tiletable[number][3] == false then
                Tiletable[number][3] = true
            else
                table.remove(Tiletable, number)
            end
            
            return
        end
    end
    
    -- otherwise, draw a new tile
    if #Tiletable == OPTIONS.max_tiles_drawn then
        table.remove(Tiletable, 1)
        Tiletable[OPTIONS.max_tiles_drawn] = {x_mouse, y_mouse, false}
    else
        table.insert(Tiletable, {x_mouse, y_mouse, false})
    end
    
end


-- uses the mouse to select an object
local function select_object(mouse_x, mouse_y, camera_x, camera_y)
    -- Font
    gui.set_font(false)
    gui.opacity(1.0, 0.5)
    
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
            if sprite_status ~= 0 then
                -- Import some values
                local x_sprite, y_sprite = Sprites_info[id].x, Sprites_info[id].y
                local x_screen, y_screen = Sprites_info[id].x_screen, Sprites_info[id].y_screen
                local boxid = Sprites_info[id].boxid
                local xoff, yoff = Sprites_info[id].xoff, Sprites_info[id].yoff
                local width, height = Sprites_info[id].width, Sprites_info[id].height
                
                if x_sprite + xoff + width >= x_game and x_sprite + xoff <= x_game and
                y_sprite + yoff + height >= y_game and y_sprite + yoff <= y_game then
                    obj_id = id
                    break
                end
            end
        end
    end
    
    if not obj_id then return end
    
    draw_text(Buffer_width/2, Buffer_height/2, fmt("%s(%4d, %3d)", obj_id, x_game, y_game))  -- TODO: make the text follow the mouse
    return obj_id, x_game, y_game
end


-- This function sees if the mouse if over some object, to change its hitbox mode
-- The order is: 1) player, 2) sprite.
local function right_click()
    local id = select_object(User_input.mouse_x.value, User_input.mouse_y.value, Camera_x, Camera_y)
    if id == nil then return end
    
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
        
    end
end


local function show_movie_info()
    -- Font
    gui.set_font(false)
    gui.opacity(1.0, 1.0)
    
    local y_text = - Border_top
    local x_text = 0
    local width = gui.font_width()
    
    local rec_color = Readonly and COLOUR.text or COLOUR.warning
    local recording_bg = Readonly and COLOUR.background or COLOUR.warning_bg 
    
    -- Read-only or read-write?
    local movie_type = Readonly and "Movie " or "REC "
    alert_text(x_text, y_text, movie_type, rec_color, recording_bg)
    
    -- Frame count
    x_text = x_text + width*string.len(movie_type)
    local movie_info
    if Readonly then
        movie_info = string.format("%d/%d", Lastframe_emulated, Framecount)
    else
        movie_info = string.format("%d", Lastframe_emulated)
    end
    draw_text(x_text, y_text, movie_info)  -- Shows the latest frame emulated, not the frame being run now
    
    -- Rerecord count
    x_text = x_text + width*string.len(movie_info)
    local rr_info = string.format("|%d ", Rerecords)
    draw_text(x_text, y_text, rr_info, COLOUR.weak)
    
    -- Lag count
    x_text = x_text + width*string.len(rr_info)
    draw_text(x_text, y_text, Lagcount, COLOUR.warning)
    
    -- Lsnes mode and speed
    if LSNES_VERSION == "rrtest" then
        local lag_length = string.len(Lagcount)
        local lsnesmode_info
        
        -- Run mode and emulator speed
        x_text = x_text + width*lag_length
        if Lsnes_speed == "turbo" then
            lsnesmode_info = fmt(" %s(%s)", Runmode, Lsnes_speed)
        elseif Lsnes_speed ~= 1 then
            lsnesmode_info = fmt(" %s(%.0f%%)", Runmode, 100*Lsnes_speed)
        else
            lsnesmode_info = fmt(" %s", Runmode)
        end
        
        draw_text(x_text, y_text, lsnesmode_info, COLOUR.weak)
    end
    
    local str = frame_time(Lastframe_emulated)    -- Shows the latest frame emulated, not the frame being run now
    alert_text(Buffer_width, Buffer_height, str, COLOUR.text, recording_bg, false, 1.0, 1.0)
    
    if Is_lagged then
        gui.textHV(math.floor(Buffer_width/2 - 3*LSNES_FONT_WIDTH), 2*LSNES_FONT_HEIGHT, "Lag", COLOUR.warning, change_transparency(COLOUR.warning_bg, Background_max_opacity))
        
        Timer.registerfunction(1000000, function()
            if not Is_lagged then
                gui.textHV(math.floor(Buffer_width/2 - 3*LSNES_FONT_WIDTH), 2*LSNES_FONT_HEIGHT, "Lag", COLOUR.warning,
                    change_transparency(COLOUR.background, Background_max_opacity))
            end
        end, "Was lagged")
        
    end
    
    -- lag indicator: only works in SMW and some hacks
    if LAG_INDICATOR_ROMS[ROM_hash] then
        if Lag_indicator == 32884 then
            gui.textV(math.floor(Buffer_width/2 - 7*LSNES_FONT_WIDTH), 4*LSNES_FONT_HEIGHT, "Lag Indicator",
                        COLOUR.warning, change_transparency(COLOUR.warning_bg, Background_max_opacity))
        end
    end
    
end


local function show_misc_info()
    -- Font
    gui.set_font(false)
    gui.opacity(1.0, 1.0)
    
    -- Display
    local RNG = u16(WRAM.RNG)
    local main_info = string.format("Frame(%02x, %02x) RNG(%04x) Mode(%02x)",
                                    Real_frame, Effective_frame, RNG, Game_mode)
    ;
    
    draw_text(Buffer_width + Border_right, -Border_top, main_info, true, false)
    
    if Game_mode == SMW.game_mode_level then
        -- Time frame counter of the clock
        gui.set_font("snes9xlua")
        local timer_frame_counter = u8(WRAM.timer_frame_counter)
        draw_text(322, 30, fmt("%.2d", timer_frame_counter))
        
        -- Score: sum of digits, useful for avoiding lag
        gui.set_font("snes9xlua")
        local score = u24(WRAM.mario_score)
        draw_text(478, 47, fmt("=%d", sum_digits(score)), COLOUR.weak)
    end
end


-- Shows the controller input as the RAM and SNES registers store it
local function show_controller_data()
    -- Font
    gui.set_font("snes9xluasmall")
    local height = gui.font_height()
    local x_pos, y_pos, x, y, _ = 0, 0, 0, 0
    
    local controller = memory2.BUS:word(0x4218)
    x = draw_over_text(x, y, controller, "BYsS^v<>AXLR0123", COLOUR.warning, false, true)
    _, y = draw_text(x, y, " (Registers)", COLOUR.warning, false, true)
    
    x = x_pos
    x = draw_over_text(x, y, 256*u8(WRAM.ctrl_1_1) + u8(WRAM.ctrl_1_2), "BYsS^v<>AXLR0123", COLOUR.weak)
    _, y = draw_text(x, y, " (RAM data)", COLOUR.weak, false, true)
    
    x = x_pos
    draw_over_text(x, y, 256*u8(WRAM.firstctrl_1_1) + u8(WRAM.firstctrl_1_2), "BYsS^v<>AXLR0123", -1, 0xff, -1)
end


local function level_info(permission)
    -- Font
    gui.set_font("snes9xtext")
    gui.opacity(1.0, 1.0)
    local y_pos = - Border_top + LSNES_FONT_HEIGHT
    local color = COLOUR.text
    
    if not permission then
        draw_text(Buffer_width + Border_right, y_pos, "Level info: off", COLOUR.weak, true, false)
        return
    end
    
    local sprite_buoyancy = math.floor(u8(WRAM.sprite_buoyancy)/64)
    if sprite_buoyancy == 0 then sprite_buoyancy = "" else
        sprite_buoyancy = fmt(" %.2x", sprite_buoyancy)
        color = COLOUR.warning
    end
    
    -- converts the level number to the Lunar Magic number; should not be used outside here
    local lm_level_number = Level_index
    if Level_index > 0x24 then lm_level_number = Level_index + 0xdc end
    
    -- Number of screens within the level
    local level_type, screens_number, hscreen_current, hscreen_number, vscreen_current, vscreen_number = read_screens()
    
    draw_text(Buffer_width + Border_right, y_pos, fmt("%.1sLevel(%.2x)%s", level_type, lm_level_number, sprite_buoyancy),
                    color, true, false)
	;
    
    draw_text(Buffer_width + Border_right, y_pos + gui.font_height(), fmt("Screens(%d):", screens_number), true)
    
    draw_text(Buffer_width + Border_right, y_pos + 2*gui.font_height(), fmt("(%d/%d, %d/%d)", hscreen_current, hscreen_number,
                vscreen_current, vscreen_number), true)
    ;
end


-- Creates lines showing where the real pit of death is
-- One line is for sprites and another is for Mario or Mario/Yoshi (different spot)
local function draw_pit()
    if Border_bottom < 33 then return end  -- 1st breakpoint
    
    -- Font
    gui.set_font("snes9xtext")
    gui.opacity(1.0, 1.0)
    
    local y_pit = Camera_y + 240
    
    local _, y_screen = screen_coordinates(0, y_pit, Camera_x, Camera_y)
    local no_powerup = u8(WRAM.powerup) == 0
    local y_inc = 0x0b
    if no_powerup then y_inc = y_inc + 1 end
    if not Yoshi_riding_flag then y_inc = y_inc + 5 end
    
    -- Sprite
    draw_line(0, y_screen, math.floor(Screen_width/2), y_screen, 2, COLOUR.weak)
    if Border_bottom >= 40 then
        local str = string.format("Sprite death: %d", y_pit)
        draw_text(-Border_left, 2*y_screen, str, COLOUR.weak, true)
    end
    
    if Border_bottom < 66 then return end  -- 2nd breakpoint
    
    -- Player
    draw_line(0, y_screen + y_inc, math.floor(Screen_width/2), y_screen + y_inc, 2, COLOUR.warning)
    if Border_bottom >= 64 then
        local str = string.format("Death: %d", y_pit + y_inc)
        draw_text(-Border_left, 2*(y_screen + y_inc), str, COLOUR.warning, true)
        str = string.format("%s/%s", no_powerup and "No powerup" or "Big", Yoshi_riding_flag and "Yoshi" or "No Yoshi")
        draw_text(-Border_left, 2*(y_screen + y_inc) + gui.font_height(), str, COLOUR.warning, true)
    end
    
end


function draw_blocked_status(x_text, y_text, player_blocked_status, x_speed, y_speed)
    local bitmap_width  = 14
    local bitmap_height = 20
    local block_str = "Block:"
    local str_len = string.len(block_str)
    local xoffset = x_text + str_len*gui.font_width()
    local yoffset = y_text
    local color_line = change_transparency(COLOUR.warning, Text_max_opacity * Text_opacity)
    
    local dbitmap = copy_dbitmap(BLOCK_INFO_BITMAP)
    dbitmap:adjust_transparency(math.floor(256 * Background_max_opacity * Bg_opacity))
    dbitmap:draw(xoffset, yoffset)
    
    local blocked_status = {}
    local was_boosted = false
    
    if bit.test(player_blocked_status, 0) then  -- Right
        draw_line(xoffset + bitmap_width - 2, yoffset, xoffset + bitmap_width - 2, yoffset + bitmap_height - 2, 1, color_line)
        if x_speed < 0 then was_boosted = true end
    end
    
    if bit.test(player_blocked_status, 1) then  -- Left
        draw_line(xoffset, yoffset, xoffset, yoffset + bitmap_height - 2, 1, color_line)
        if x_speed > 0 then was_boosted = true end
    end
    
    if bit.test(player_blocked_status, 2) then  -- Down
        draw_line(xoffset, yoffset + bitmap_height - 2, xoffset + bitmap_width - 2, yoffset + bitmap_height - 2, 1, color_line)
    end
    
    if bit.test(player_blocked_status, 3) then  -- Up
        draw_line(xoffset, yoffset, xoffset + bitmap_width - 2, yoffset, 1, color_line)
        if y_speed > 6 then was_boosted = true end
    end
    
    if bit.test(player_blocked_status, 4) then  -- Middle
        gui.crosshair(xoffset + math.floor(bitmap_width/2), math.floor(yoffset + bitmap_height/2), math.floor(math.min(bitmap_width/2, bitmap_height/2)), color_line)
    end
    
    draw_text(x_text, y_text, block_str, COLOUR.text, was_boosted and COLOUR.warning_bg or nil)
    
end


-- displays player's hitbox
local function player_hitbox(x, y, is_ducking, powerup, transparency_level)
    -- Colour settings
    local interaction_bg, mario_line, mario_bg, interaction_points_palette
    interaction_bg = change_transparency(COLOUR.interaction_bg, transparency_level)
    mario_line = change_transparency(COLOUR.mario, transparency_level)
    if transparency_level == 1.0 then
        interaction_points_palette = INTERACTION_POINTS_PALETTE
    else
        interaction_points_palette = copy_palette(INTERACTION_POINTS_PALETTE)
        interaction_points_palette:adjust_transparency(math.floor(transparency_level*256))
    end
    
    local x_screen, y_screen = screen_coordinates(x, y, Camera_x, Camera_y)
    local yoshi_hitbox = nil
    local is_small = is_ducking ~= 0 or powerup == 0
    
    local x_points = X_INTERACTION_POINTS
    local y_points
    local mario_status
    if is_small and not Yoshi_riding_flag then
        y_points = Y_INTERACTION_POINTS[1]
        mario_status = 1
    elseif not is_small and not Yoshi_riding_flag then
        y_points = Y_INTERACTION_POINTS[2]
        mario_status = 2
    elseif is_small and Yoshi_riding_flag then
        y_points = Y_INTERACTION_POINTS[3]
        mario_status = 3
    else
        y_points = Y_INTERACTION_POINTS[4]
        mario_status = 4
    end
    
    draw_box(x_screen + x_points.left_side, y_screen + y_points.head, x_screen + x_points.right_side, y_screen + y_points.foot,
            2, interaction_bg, interaction_bg)  -- background for block interaction
    ;
    
    if OPTIONS.display_player_hitbox then
        
        -- Collision with sprites
        local mario_bg = (not Yoshi_riding_flag and COLOUR.mario_bg) or COLOUR.mario_mounted_bg
        
        draw_box(x_screen + x_points.left_side  - 1, y_screen + y_points.sprite,
                 x_screen + x_points.right_side + 1, y_screen + y_points.foot + 1, 2, mario_line, mario_bg)
        ;
        
    end
    
    -- interaction points (collision with blocks)
    if OPTIONS.display_interaction_points then
        
        local color = COLOUR.interaction
        
        if not OPTIONS.display_player_hitbox then
            draw_box(x_screen + x_points.left_side , y_screen + y_points.head,
                     x_screen + x_points.right_side, y_screen + y_points.foot, 2, COLOUR.interaction_nohitbox, COLOUR.interaction_nohitbox_bg)
        end
        
        gui.bitmap_draw(2*x_screen, 2*y_screen, INTERACTION_POINTS[mario_status], interaction_points_palette)
    end
    
    -- That's the pixel that appears when Mario dies in the pit
    Show_player_point_position = Show_player_point_position or y_screen >= 200 or OPTIONS.display_debug_info
    if Show_player_point_position then
        draw_pixel(x_screen, y_screen, color)
        Show_player_point_position = false
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
    local block_interaction_cape = (spin_direction < 0 and cape_left + 2) or cape_right - 2
    local active_frame_sprites = Real_frame%2 == 1  -- active iff the cape can hit a sprite
    local active_frame_blocks  = Real_frame%2 == (spin_direction < 0 and 0 or 1)  -- active iff the cape can hit a block
    
    if active_frame_sprites then bg_color = COLOUR.cape_bg else bg_color = -1 end
    draw_box(cape_x_screen + cape_left, cape_y_screen + cape_up, cape_x_screen + cape_right, cape_y_screen + cape_down, 2, COLOUR.cape, bg_color)
    
    if active_frame_blocks then
        draw_pixel(cape_x_screen + block_interaction_cape, cape_y_screen + cape_middle, COLOUR.warning)
    else
        draw_pixel(cape_x_screen + block_interaction_cape, cape_y_screen + cape_middle, COLOUR.text)
    end
end


local function player()
    -- Font
    gui.set_font(false)
    gui.opacity(1.0, 1.0)
    
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
    local powerup = u8(WRAM.powerup)
    local direction = u8(WRAM.direction)
    local cape_spin = u8(WRAM.cape_spin)
    local cape_fall = u8(WRAM.cape_fall)
    local flight_animation = u8(WRAM.flight_animation)
    local diving_status = s8(WRAM.diving_status)
    local player_blocked_status = u8(WRAM.player_blocked_status)
    local player_item = u8(WRAM.player_item)
    local is_ducking = u8(WRAM.is_ducking)
    local on_ground = u8(WRAM.on_ground)
    local spinjump_flag = u8(WRAM.spinjump_flag)
    local can_jump_from_water = u8(WRAM.can_jump_from_water)
    local carrying_item = u8(WRAM.carrying_item)
    
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
    local delta_x = gui.font_width()
    local delta_y = gui.font_height()
    local table_x = 0
    local table_y = 64
    draw_text(table_x, table_y + i*delta_y, fmt("Meter (%03d, %02d) %s", p_meter, take_off, direction))
    draw_text(table_x + 18*delta_x, table_y + i*delta_y, fmt(" %+d", spin_direction),
    (is_spinning and COLOUR.text) or COLOUR.weak)
    i = i + 1
    
    draw_text(table_x, table_y + i*delta_y, fmt("Pos (%+d.%s, %+d.%s)", x, x_sub_simple, y, y_sub_simple))
    i = i + 1
    
    draw_text(table_x, table_y + i*delta_y, fmt("Speed (%+d(%d.%02.0f), %+d)", x_speed, x_speed_int, x_speed_frac, y_speed))
    i = i + 1
    
    if is_caped then
        draw_text(table_x, table_y + i*delta_y, fmt("Cape (%.2d, %.2d)/(%d, %d)", cape_spin, cape_fall, flight_animation, diving_status), COLOUR.cape)
        i = i + 1
    end
    
    draw_text(table_x, table_y + i*delta_y, fmt("Camera (%d, %d)", Camera_x, Camera_y))
    i = i + 1
    
    draw_blocked_status(table_x, table_y + i*delta_y, player_blocked_status, x_speed, y_speed)
    
    -- Mario boost indicator (experimental)
    -- This looks for differences between the expected x position and the actual x position, after a frame advance
    -- Fails during a loadstate and has false positives if the game is paused or lagged
    Previous.player_x = 256*x + x_sub  -- the total amount of 256-based subpixels
    Previous.x_speed = 16*x_speed  -- the speed in 256-based subpixels
    
    if Mario_boost_indicator and not Cheat.under_free_move then
        local x_screen, y_screen = screen_coordinates(x, y, Camera_x, Camera_y)
        gui.text(2*x_screen + 8, 2*y_screen + 120, Mario_boost_indicator, COLOUR.warning, 0x20000000)
    end
    
    -- shows hitbox and interaction points for player
    if not (OPTIONS.display_player_hitbox or OPTIONS.display_interaction_points) then return end
    
    cape_hitbox(spin_direction)
    player_hitbox(x, y, is_ducking, powerup, 1.0)
    
    -- Shows where Mario is expected to be in the next frame, if he's not boosted or stopped (DEBUG)
	if OPTIONS.display_debug_info then player_hitbox(math.floor((256*x + x_sub + 16*x_speed)/256), math.floor((256*y + y_sub + 16*y_speed)/256), is_ducking, powerup, 0.3) end
    
end

 
-- Returns the id of Yoshi; if more than one, the lowest sprite slot
local function get_yoshi_id()
    for i = 0, SMW.sprite_max - 1 do
        id = u8(WRAM.sprite_number + i)
        status = u8(WRAM.sprite_status + i)
        if id == 0x35 and status ~= 0 then return i end
    end
    
    return nil
end


local function extended_sprites()
    -- Font
    gui.set_font(false)
    local height = gui.font_height()
    
    local y_pos = 288
    local counter = 0
    for id = 0, SMW.extended_sprite_max - 1 do
        local extspr_number = u8(WRAM.extspr_number + id)
        
        if extspr_number ~= 0 then
            -- Reads WRAM adresses
            local x = 256*u8(WRAM.extspr_x_high + id) + u8(WRAM.extspr_x_low + id)
            local y = 256*u8(WRAM.extspr_y_high + id) + u8(WRAM.extspr_y_low + id)
            local sub_x = bit.lrshift(u8(WRAM.extspr_subx + id), 4)
            local sub_y = bit.lrshift(u8(WRAM.extspr_suby + id), 4)
            local x_speed = s8(WRAM.extspr_x_speed + id)
            local y_speed = s8(WRAM.extspr_y_speed + id)
            local extspr_table = u8(WRAM.extspr_table + id)
            local extspr_table2 = u8(WRAM.extspr_table2 + id)
            
            -- Reduction of useless info
            local special_info = ""
            if OPTIONS.display_debug_info and (extspr_table ~= 0 or extspr_table2 ~= 0) then
                special_info = fmt("(%x, %x) ", extspr_table, extspr_table2)
            end
            
            -- x speed for Fireballs
            if extspr_number == 5 then x_speed = 16*x_speed end
            
            draw_text(Buffer_width + Border_right, y_pos + counter*height, fmt("#%.2d %.2x %s(%d.%x(%+.2d), %d.%x(%+.2d))",
                                                                id, extspr_number, special_info, x, sub_x, x_speed, y, sub_y, y_speed),
                                                                COLOUR.extended_sprites, true, false)
            ;
            
            if OPTIONS.display_debug_info or not UNINTERESTING_EXTENDED_SPRITES[extspr_number] then
                local x_screen, y_screen = screen_coordinates(x, y, Camera_x, Camera_y)
                
                local xoff = HITBOX_EXTENDED_SPRITE[extspr_number].xoff
                local yoff = HITBOX_EXTENDED_SPRITE[extspr_number].yoff + Y_CAMERA_OFF
                local xrad = HITBOX_EXTENDED_SPRITE[extspr_number].xrad
                local yrad = HITBOX_EXTENDED_SPRITE[extspr_number].yrad
                
                local color_line = HITBOX_EXTENDED_SPRITE[extspr_number].color_line or COLOUR.extended_sprites
                local color_bg = HITBOX_EXTENDED_SPRITE[extspr_number].color_bg or 0xb000ff00
                if extspr_number == 0x11 then color_bg = (Real_frame - id)%4 == 0 and 0xa000ff00 or -1 end
                draw_rectangle(x_screen+xoff, y_screen+yoff, xrad, yrad, color_line, color_bg)
            end
            
            counter = counter + 1
        end
    end
    
    gui.set_font("snes9xluasmall")
    draw_text(Buffer_width + Border_right, y_pos, fmt("Ext. spr:%2d ", counter), COLOUR.weak, true, false, 0.0, 1.0)
    
end


local function bounce_sprite_info()
    -- Debug info
    local x_txt, y_txt = 180, 74
    if OPTIONS.display_debug_info then
        gui.set_font("snes9xluasmall")
        draw_text(x_txt, y_txt, "Bounce Spr.", COLOUR.weak)
    end
    
    -- Font
    gui.set_font("snes9xtext")
    local height = gui.font_height()
    
    local stop_id = (u8(WRAM.bouncespr_last_id) - 1)%SMW.bounce_sprite_max
    for id = 0, SMW.bounce_sprite_max - 1 do
        local bounce_sprite_number = u8(WRAM.bouncespr_number + id)
        if bounce_sprite_number ~= 0 then
            local x = 256*u8(WRAM.bouncespr_x_high + id) + u8(WRAM.bouncespr_x_low + id)
            local y = 256*u8(WRAM.bouncespr_y_high + id) + u8(WRAM.bouncespr_y_low + id)
            local bounce_timer = u8(WRAM.bouncespr_timer + id)
            
            if OPTIONS.display_debug_info then
                draw_text(x_txt, y_txt + height*(id + 1), fmt("#%d:%d (%d, %d)", id, bounce_sprite_number, x, y))
            end
            
            local x_screen, y_screen = screen_coordinates(x, y, Camera_x, Camera_y)
            x_screen, y_screen = 2*x_screen + 16, 2*y_screen
            local color = id == stop_id and COLOUR.warning or COLOUR.text
            draw_text(x_screen , y_screen, fmt("#%d:%d", id, bounce_timer), color, false, false, 0.5)  -- timer
            
            -- Turn blocks
            if bounce_sprite_number == 7 then
                turn_block_timer = u8(WRAM.turn_block_timer + id)
                draw_text(x_screen, y_screen + height, turn_block_timer, color, false, false, 0.5)
            end
        end
    end
end


local function sprite_info(id, counter, table_position)
    local sprite_status = u8(WRAM.sprite_status + id)
    if sprite_status == 0 then return 0 end  -- returns if the slot is empty
    
    local x = 256*u8(WRAM.sprite_x_high + id) + u8(WRAM.sprite_x_low + id)
    local y = 256*u8(WRAM.sprite_y_high + id) + u8(WRAM.sprite_y_low + id)
    local x_sub = u8(WRAM.sprite_x_sub + id)
    local y_sub = u8(WRAM.sprite_y_sub + id)
    local number = u8(WRAM.sprite_number + id)
    local stun = u8(WRAM.sprite_stun + id)
    local x_speed = s8(WRAM.sprite_x_speed + id)
    local y_speed = s8(WRAM.sprite_y_speed + id)
    local contact_mario = u8(WRAM.sprite_contact_mario + id)
    local x_offscreen = s8(WRAM.sprite_x_offscreen + id)
    local y_offscreen = s8(WRAM.sprite_y_offscreen + id)
    
    local special = ""
    if OPTIONS.display_debug_info or ((sprite_status ~= 0x8 and sprite_status ~= 0x9 and sprite_status ~= 0xa and sprite_status ~= 0xb) or stun ~= 0) then
        special = string.format("(%d %d) ", sprite_status, stun)
    end
    
    -- Let x and y be 16-bit signed
    x = signed(x, 16)
    y = signed(y, 16)
    
    ---**********************************************
    -- Calculates the sprites dimensions and screen positions
    
    local x_screen, y_screen = screen_coordinates(x, y, Camera_x, Camera_y)
    
    -- Sprite clipping vs mario and sprites
    local boxid = bit.band(u8(WRAM.sprite_2_tweaker + id), 0x3f)  -- This is the type of box of the sprite
    local xoff = HITBOX_SPRITE[boxid].xoff
    local yoff = HITBOX_SPRITE[boxid].yoff
    local sprite_width = HITBOX_SPRITE[boxid].width
    local sprite_height = HITBOX_SPRITE[boxid].height
    
    -- Sprite clipping vs objects
    local clip_obj = 4*bit.band(u8(WRAM.sprite_1_tweaker + id), 0xf)  -- type of hitbox for blocks
    local xpt_right = memory.readsbyte("ROM", 0x90ba + clip_obj)  -- TODO: remove loading ROM
    local ypt_right = memory.readsbyte("ROM", 0x90f7 + clip_obj)
    local xpt_left = memory.readsbyte("ROM", 0x90ba + clip_obj + 1)
    local ypt_left = memory.readsbyte("ROM", 0x90f7 + clip_obj + 1)
    local xpt_down = memory.readsbyte("ROM", 0x90ba + clip_obj + 2)
    local ypt_down = memory.readsbyte("ROM", 0x90f7 + clip_obj + 2)
    local xpt_up = memory.readsbyte("ROM", 0x90ba + clip_obj + 3)
    local ypt_up = memory.readsbyte("ROM", 0x90f7 + clip_obj + 3)
    
    -- Process interaction with player every frame?
    -- Format: dpmksPiS. This 'm' bit seems odd, since it has false negatives
    local oscillation_flag = bit.test(u8(WRAM.sprite_4_tweaker + id), 5) or OSCILLATION_SPRITES[number]
    
    -- calculates the correct color to use, according to id
    local info_color
    local color_background
    if number == 0x35 then
        info_color = COLOUR.yoshi
        color_background = COLOUR.yoshi_bg
    else
        info_color = COLOUR.sprites[id%(#COLOUR.sprites) + 1]
        color_background = COLOUR.sprites_bg
    end
    
    
    if (not oscillation_flag) and (Real_frame - id)%2 == 1 then color_background = -1 end     -- due to sprite oscillation every other frame
                                                                                    -- notice that some sprites interact with Mario every frame
    ;
    
    
    ---**********************************************
    -- Displays sprites hitboxes
    if OPTIONS.display_sprite_hitbox then
        -- That's the pixel that appears when the sprite vanishes in the pit
        if y_screen >= 224 then
            draw_pixel(x_screen, y_screen, info_color)
        end
        
        if Sprite_hitbox[id][number].block then
            draw_box(x_screen + xpt_left, y_screen + ypt_down, x_screen + xpt_right, y_screen + ypt_up,
                2, COLOUR.sprites_clipping_bg, Sprite_hitbox[id][number].sprite and -1 or COLOUR.sprites_clipping_bg)
        end
        
        if Sprite_hitbox[id][number].sprite and not ABNORMAL_HITBOX_SPRITES[number] then  -- show sprite/sprite clipping
            draw_rectangle(x_screen + xoff, y_screen + yoff, sprite_width, sprite_height, info_color, color_background)
        end
        
        if Sprite_hitbox[id][number].block then  -- show sprite/object clipping
            local size, color = 1, COLOUR.sprites_interaction_pts
            draw_line(x_screen + xpt_right, y_screen + ypt_right, x_screen + xpt_right - size, y_screen + ypt_right, 2, color) -- right
            draw_line(x_screen + xpt_left, y_screen + ypt_left, x_screen + xpt_left + size, y_screen + ypt_left, 2, color)  -- left
            draw_line(x_screen + xpt_down, y_screen + ypt_down, x_screen + xpt_down, y_screen + ypt_down - size, 2, color) -- down
            draw_line(x_screen + xpt_up, y_screen + ypt_up, x_screen + xpt_up, y_screen + ypt_up + size, 2, color)  -- up
        end
    end
    
    
    ---**********************************************
    -- Special sprites analysis:
    
    --[[
    PROBLEMATIC ONES
        29	Koopa Kid
        54  Revolving door for climbing net, wrong hitbox area, not urgent
        5a  Turn block bridge, horizontal, hitbox only applies to central block and wrongly
        86	Wiggler, the second part of the sprite, that hurts Mario even if he's on Yoshi, doesn't appear
        89	Layer 3 Smash, hitbox of generator outside
        9e	Ball 'n' Chain, hitbox only applies to central block, rotating ball
        a3	Rotating gray platform, wrong hitbox, rotating plataforms
    ]]
    
    if number == 0x5f then  -- Swinging brown platform (fix it)
        --[[
        local platform_x = -s8(0x1523)
        local platform_y = -s8(0x0036)
        --]]
        
        -- Powerup Incrementation helper
        local yoshi_left  = 256*math.floor(x/256) - 58
        local yoshi_right = 256*math.floor(x/256) - 26
        local x_text, y_text, height = 2*(x_screen + xoff), 2*(y_screen + yoff), gui.font_height()
        
        if mouse_onregion(x_text, y_text, x_text + 2*sprite_width, y_text + 2*sprite_height) then
            y_text = y_text + 32
            draw_text(x_text, y_text, "Powerup Incrementation help:", info_color, COLOUR.background, true, false, 0.5)
            draw_text(x_text, y_text + height, "Yoshi's id must be #4. The x position depends on its direction:",
                            info_color, COLOUR.background, true, false, 0.5)
            draw_text(x_text, y_text + 2*height, fmt("%s: %d, %s: %d.", LEFT_ARROW, yoshi_left, RIGHT_ARROW, yoshi_right),
                            info_color, COLOUR.background, true, false, 0.5)
        end
        --The status change happens when yoshi's id number is #4 and when (yoshi's x position) + Z mod 256 = 214,
        --where Z is 16 if yoshi is facing right, and -16 if facing left. More precisely, when (yoshi's x position + Z) mod 256 = 214,
        --the address 0x7E0015 + (yoshi's id number) will be added by 1.
        -- therefore: X_yoshi = 256*math.floor(x/256) + 32*yoshi_direction - 58
    end
    
    if number == 0x35 then  -- Yoshi
        if not Yoshi_riding_flag and OPTIONS.display_sprite_hitbox and Sprite_hitbox[id][number].sprite then
            draw_rectangle(x_screen + 4, y_screen + 20, 8, 8, COLOUR.yoshi)
        end
    end
    
    if number == 0x62 or number == 0x63 then  -- Brown line-guided platform & Brown/checkered line-guided platform
            xoff = xoff - 24
            yoff = yoff - 8
            -- TODO: investigate why the actual base is 1 pixel below when Mario is small
            if OPTIONS.display_sprite_hitbox then
                draw_rectangle(x_screen + xoff, y_screen + yoff, sprite_width, sprite_height, info_color, color_background)
            end
    end
    
    if number == 0x6b then  -- Wall springboard (left wall)
        xoff = xoff - 8
        sprite_height = sprite_height + 1  -- for some reason, small Mario gets a bigger hitbox
        
        if OPTIONS.display_sprite_hitbox then
            draw_rectangle(x_screen + xoff, y_screen + yoff, sprite_width, sprite_height, info_color, color_background)
            draw_line(x_screen + xoff, y_screen + yoff + 3, x_screen + xoff + sprite_width, y_screen + yoff + 3, 2, info_color)
        end
    end
    
    if number == 0x6c then  -- Wall springboard (right wall)
        xoff = xoff - 31
        sprite_height = sprite_height + 1
        
        if OPTIONS.display_sprite_hitbox then
            draw_rectangle(x_screen + xoff, y_screen + yoff, sprite_width, sprite_height, info_color, color_background)
            draw_line(x_screen + xoff, y_screen + yoff + 3, x_screen + xoff + sprite_width, y_screen + yoff + 3, 2, info_color)
        end
    end
    
    if number == 0x7b then  -- Goal Tape
    
        gui.set_font("snes9xtext")
        gui.opacity(0.8, 0.6)
        
        -- This draws the effective area of a goal tape
        local x_effective = 256*u8(WRAM.sprite_tongue_length + id) + u8(0xc2 + id)  -- unlisted WRAM
        local y_low = 256*u8(0x1534 + id) + u8(WRAM.sprite_miscellaneous3 + id)  -- unlisted WRAM
        local _, y_high = screen_coordinates(0, 0, Camera_x, Camera_y)
        local x_s, y_s = screen_coordinates(x_effective, y_low, Camera_x, Camera_y)
        
        if OPTIONS.display_sprite_hitbox then
            draw_box(x_s, y_high, x_s + xoff + xoff + sprite_width, y_s, 2, info_color, COLOUR.goal_tape_bg)
        end
        draw_text(2*x_s, 2*(y_screen), fmt("Touch=%4d.0->%4d.f", x_effective, x_effective + 15), info_color, false, false)
        
        -- Draw a bitmap if the tape is unnoticeable
        local x_png, y_png = put_on_screen(2*x_s, 2*y_s, 18, 6)  -- png is 18x6
        if x_png ~= 2*x_s or y_png > 2*y_s then  -- tape is outside the screen
            GOAL_TAPE_BITMAP:draw(x_png, y_png)
        else
            Show_player_point_position = true
            if y_low < 10 then GOAL_TAPE_BITMAP:draw(x_png, y_png) end  -- tape is too small, 10 is arbitrary here
        end
        
        gui.set_font(false)
        gui.opacity(1.0, 1.0)
    
    elseif number == 0xa9 then  -- Reznor
    
        gui.set_font("snes9xluaclever")
        local reznor
        local color
        for index = 0, SMW.sprite_max - 1 do
            reznor = u8(WRAM.reznor_killed_flag + index)
            if index >= 4 and index <= 7 then
                color = COLOUR.warning
            else
                color = color_weak
            end
            draw_text(3*gui.font_width()*index, Buffer_height, fmt("%.2x", reznor), color, true, false, 0.0, 1.0)
        end
    
    elseif number == 0xa0 then  -- Bowser
    
        gui.set_font(false)--("snes9xluasmall")
        local height = gui.font_height()
        local y_text = Screen_height - 10*height
        local adress = 0x14b0  -- fix it
        for index = 0, 9 do
            local value = u8(adress + index)
            draw_text(Buffer_width + Border_right, y_text + index*height, fmt("%2x = %3d", value, value), info_color, true)
        end
    
    end
    
    
    ---**********************************************
    -- Prints those informations next to the sprite
    gui.set_font("snes9xtext")
    gui.opacity(1.0, 1.0)
    
    if x_offscreen ~= 0 or y_offscreen ~= 0 then
        gui.opacity(0.6)
    end
    
    local contact_str = contact_mario == 0 and "" or " "..contact_mario
    
    local sprite_middle = x_screen + xoff + math.floor(sprite_width/2)
    draw_text(2*sprite_middle, 2*(y_screen + math.min(yoff, ypt_up)), fmt("#%.2d%s", id, contact_str), info_color, true, false, 0.5, 1.0)
    
    
    ---**********************************************
    -- Sprite tweakers info
    if OPTIONS.display_debug_info and mouse_onregion(2*(x_screen + xoff), 2*(y_screen + yoff),
        2*(x_screen + xoff + sprite_width), 2*(y_screen + yoff + sprite_height)) then
        
        local tweaker_1 = u8(WRAM.sprite_1_tweaker + id)
        draw_over_text(2*(sprite_middle - 10), 2*(y_screen + yoff - 50), tweaker_1, "sSjJcccc", COLOUR.weak, info_color)
        
        local tweaker_2 = u8(WRAM.sprite_2_tweaker + id)
        draw_over_text(2*(sprite_middle - 10), 2*(y_screen + yoff - 45), tweaker_2, "dscccccc", COLOUR.weak, info_color)
        
        local tweaker_3 = u8(WRAM.sprite_3_tweaker + id)
        draw_over_text(2*(sprite_middle - 10), 2*(y_screen + yoff - 40), tweaker_3, "lwcfpppg", COLOUR.weak, info_color)
        
        local tweaker_4 = u8(WRAM.sprite_4_tweaker + id)
        draw_over_text(2*(sprite_middle - 10), 2*(y_screen + yoff - 35), tweaker_4, "dpmksPiS", COLOUR.weak, info_color)
        
        local tweaker_5 = u8(WRAM.sprite_5_tweaker + id)
        draw_over_text(2*(sprite_middle - 10), 2*(y_screen + yoff - 30), tweaker_5, "dnctswye", COLOUR.weak, info_color)
        
        local tweaker_6 = u8(WRAM.sprite_6_tweaker + id)
        draw_over_text(2*(sprite_middle - 10), 2*(y_screen + yoff - 25), tweaker_6, "wcdj5sDp", COLOUR.weak, info_color)
    end
    
    
    ---**********************************************
    -- The sprite table:
    gui.set_font(false)
    local sprite_str = fmt("#%02d %02x %s%d.%1x(%+.2d) %d.%1x(%+.2d)",
                        id, number, special, x, math.floor(x_sub/16), x_speed, y, math.floor(y_sub/16), y_speed)
                        
    draw_text(Buffer_width + Border_right, table_position + counter*gui.font_height(), sprite_str, info_color, true)
    
    -- Exporting some values
    Sprites_info[id].number = number
    Sprites_info[id].x, Sprites_info[id].y = x, y
    Sprites_info[id].x_screen, Sprites_info[id].y_screen = x_screen, y_screen
    Sprites_info[id].boxid = boxid
    Sprites_info[id].xoff, Sprites_info[id].yoff = xoff, yoff
    Sprites_info[id].width, Sprites_info[id].height = sprite_width, sprite_height
    
    return 1
end


local function sprites()
    local counter = 0
    local table_position = 80
    
    for id = 0, SMW.sprite_max - 1 do
        counter = counter + sprite_info(id, counter, table_position)
    end
    
    -- Font
    gui.set_font("snes9xluasmall")
    gui.opacity(1.0, 1.0)
    
    local swap_slot = u8(0x1861) -- unlisted WRAM
    local smh = u8(WRAM.sprite_memory_header)
    draw_text(Buffer_width + Border_right, table_position - 2*gui.font_height(), fmt("spr:%.2d ", counter), COLOUR.weak, true)
    draw_text(Buffer_width + Border_right, table_position - gui.font_height(), fmt("1st div: %d. Swap: %d ",
                                                            SPRITE_MEMORY_MAX[smh], swap_slot), COLOUR.weak, true)
end


local function yoshi()
    -- Font
    gui.set_font(false)
    gui.opacity(1.0, 1.0)
    
    local x_text = 0
    local y_text = 176
    
    local yoshi_id = get_yoshi_id()
    if yoshi_id ~= nil then
        local eat_id = u8(WRAM.sprite_miscellaneous + yoshi_id)
        local eat_type = u8(WRAM.sprite_number + eat_id)
        local tongue_len = u8(WRAM.sprite_tongue_length + yoshi_id)
        local tongue_timer = u8(WRAM.sprite_tongue_timer + yoshi_id)
        local tongue_wait = u8(WRAM.sprite_tongue_wait)
        local tongue_height = u8(WRAM.yoshi_tile_pos)
        local tongue_out = u8(WRAM.sprite_miscellaneous4 + yoshi_id)
        
        local eat_type_str = eat_id == SMW.null_sprite_id and "-" or string.format("%02x", eat_type)
        local eat_id_str = eat_id == SMW.null_sprite_id and "-" or string.format("#%02d", eat_id)
        
        -- Yoshi's direction and turn around
        local turn_around = u8(WRAM.sprite_turn_around + yoshi_id)
        local yoshi_direction = u8(WRAM.sprite_direction + yoshi_id)
        local direction_symbol
        if yoshi_direction == 0 then direction_symbol = RIGHT_ARROW else direction_symbol = LEFT_ARROW end
        
        draw_text(x_text, y_text, fmt("Yoshi %s %d", direction_symbol, turn_around), COLOUR.yoshi)
        local h = gui.font_height()
        gui.set_font("snes9xluasmall")
        draw_text(x_text, y_text + h, fmt("(%0s, %0s) %02d, %d, %d",
                            eat_id_str, eat_type_str, tongue_len, tongue_wait, tongue_timer), COLOUR.yoshi)
        ;
        -- more WRAM values
        local yoshi_x = 256*u8(WRAM.sprite_x_high + yoshi_id) + u8(WRAM.sprite_x_low + yoshi_id)
        local yoshi_y = 256*u8(WRAM.sprite_y_high + yoshi_id) + u8(WRAM.sprite_y_low + yoshi_id)
        local x_screen, y_screen = screen_coordinates(yoshi_x, yoshi_y, Camera_x, Camera_y)
        
        -- invisibility timer
        gui.set_font("snes9xtext")
        local mount_invisibility = u8(WRAM.sprite_miscellaneous2 + yoshi_id)
        if mount_invisibility ~= 0 then
            draw_text(2*x_screen + 8, 2*y_screen - 24, mount_invisibility, COLOUR.yoshi)
        end
        
        -- Tongue hitbox and timer
        if tongue_wait ~= 0 or tongue_out ~=0 or tongue_height == 0x89 then  -- if tongue is out or appearing
            -- the position of the hitbox pixel
            local tongue_direction = yoshi_direction == 0 and 1 or -1
            local tongue_high = tongue_height ~= 0x89
            local x_tongue = x_screen + 24 - 40*yoshi_direction + tongue_len*tongue_direction
            x_tongue = not tongue_high and x_tongue or x_tongue - 5*tongue_direction
            local y_tongue = y_screen + 10 + 11*(tongue_high and 0 or 1)
            
            -- the drawing
            local tongue_line
            if tongue_wait <= 9  then  -- hitbox point vs berry tile
                draw_rectangle(x_tongue - 1, y_tongue - 1, 2, 2, COLOUR.tongue_bg, COLOUR.text)
                tongue_line = COLOUR.tongue_line
            else tongue_line = COLOUR.tongue_bg
            end
            
            -- tongue out: time predictor
            local tinfo, tcolor
            if tongue_wait > 9 then tinfo = tongue_wait - 9; tcolor = COLOUR.tongue_line  -- not ready yet
            
            elseif tongue_out == 1 then tinfo = 17 + tongue_wait; tcolor = COLOUR.text  -- tongue going out
            
            elseif tongue_out == 2 then  -- at the max or tongue going back
                tinfo = math.max(tongue_wait, tongue_timer) + math.floor((tongue_len + 7)/4) - (tongue_len ~= 0 and 1 or 0)
                tcolor = eat_id == SMW.null_sprite_id and COLOUR.text or COLOUR.warning
            
            elseif tongue_out == 0 then tinfo = 0; tcolor = COLOUR.text  -- tongue in
            
            else tinfo = tongue_timer + 1; tcolor = COLOUR.tongue_line -- item was just spat out
            end
            
            draw_text(2*(x_tongue + 4), 2*(y_tongue + 5), tinfo, tcolor, false, false, 0.5)
            draw_rectangle(x_tongue, y_tongue + 1, 8, 4, tongue_line, COLOUR.tongue_bg)
        end
        
    end
end


local function show_counters()
    -- Font
    gui.set_font(false)  -- "snes9xtext" is also good and small
    gui.opacity(1.0, 1.0)
    local height = gui.font_height()
    local text_counter = 0
    
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
    
    local display_counter = function(label, value, default, mult, frame, color)
        if value == default then return end
        text_counter = text_counter + 1
        local color = color or COLOUR.text
        
        draw_text(0, 204 + (text_counter * height), fmt("%s: %d", label, (value * mult) - frame), color)
    end
    
    display_counter("Multi Coin", multicoin_block_timer, 0, 1, 0, 0x00ffff00) --
    display_counter("Pow", gray_pow_timer, 0, 4, Effective_frame % 4, 0x00a5a5a5) --
    display_counter("Pow", blue_pow_timer, 0, 4, Effective_frame % 4, 0x004242de) --
    display_counter("Dir Coin", dircoin_timer, 0, 4, Real_frame % 4, 0x008c5a19) --
    display_counter("P-Balloon", pballoon_timer, 0, 4, Real_frame % 4, 0x00f8d870) --
    display_counter("Star", star_timer, 0, 4, (Effective_frame - 3) % 4, 0x00ffd773)  --
    display_counter("Invibility", invisibility_timer, 0, 1, 0)
    display_counter("Fireflower", fireflower_timer, 0, 1, 0, 0x00ff8c00) --
    display_counter("Yoshi", yoshi_timer, 0, 1, 0, COLOUR.yoshi) --
    display_counter("Swallow", swallow_timer, 0, 4, (Effective_frame - 1) % 4, COLOUR.yoshi) --
    display_counter("Lakitu", lakitu_timer, 0, 4, Effective_frame % 4) --
    display_counter("End Level", end_level_timer, 0, 2, (Real_frame - 1) % 2)
    display_counter("Score Incrementing", score_incrementing, 0x50, 1, 0)
    
    if Lock_animation_flag ~= 0 then display_counter("Animation", animation_timer, 0, 1, 0) end  -- shows when player is getting hurt or dying
    
end


-- Main function to run inside a level
local function level_mode()
    if Game_mode == SMW.game_mode_level then
        
        -- Draws/Erases the tiles if user clicked
        draw_tilesets(Camera_x, Camera_y)
        
        if OPTIONS.display_pit_info then draw_pit(Camera_x, Camera_y) end
        
        if OPTIONS.display_sprite_info then sprites(Camera_x, Camera_y) end
        
        if OPTIONS.display_extended_sprite_info then extended_sprites() end
        
        if OPTIONS.display_bounce_sprite_info then bounce_sprite_info() end
        
        level_info(OPTIONS.display_level_info)
        
        if OPTIONS.display_player_info then player(Camera_x, Camera_y) end
        
        if OPTIONS.display_yoshi_info then yoshi(Camera_x, Camera_y) end
        
        if OPTIONS.display_counters then show_counters() end
        
        -- Draws/Erases the hitbox for objects
        if User_input.mouse_inwindow.value == 1 then
            select_object(User_input.mouse_x.value, User_input.mouse_y.value, Camera_x, Camera_y)
        end
        
    end
end


local function overworld_mode()
    if Game_mode ~= SMW.game_mode_overworld then return end
    
    -- Font
    gui.set_font(false)
    gui.opacity(1.0, 1.0)
    
    local height = gui.font_height()
    local y_text = 0
    
    -- Real frame modulo 8
    local real_frame_8 = Real_frame%8
    draw_text(Buffer_width + Border_right, y_text, fmt("Real Frame = %3d = %d(mod 8)", Real_frame, real_frame_8), true)
    
    -- Star Road info
    local star_speed = u8(WRAM.star_road_speed)
    local star_timer = u8(WRAM.star_road_timer)
    y_text = y_text + height
    draw_text(Buffer_width + Border_right, y_text, fmt("Star Road(%x %x)", star_speed, star_timer), COLOUR.cape, true)
end


local function left_click()
    local buttontable = Script_buttons
    
    for _, field in pairs(buttontable) do
        
        -- if mouse is over the button
        if mouse_onregion(field.x, field.y, field.x + field.width, field.y + field.height) then
                field.action()
                Script_buttons = {}
                return
        end
    end
    
    -- if no button is selected
    select_tile()
end


-- This function runs at the end of paint callback
-- Specific for info that changes if the emulator is paused and idle callback is called
local function lsnes_yield()
    -- Font
    gui.set_font(false)
    
    if User_input.mouse_inwindow.value == 1 then
        draw_text(0, 432, fmt("Mouse (%d, %d)", User_input.mouse_x.value, User_input.mouse_y.value))
    end
    
    if not Show_options_menu and User_input.mouse_inwindow.value == 1 then
        create_button(-Border_left, -Border_top, "Menu", function() Show_options_menu = true end, true)
        
        create_button(0, 0, "↓",
            function() OPTIONS.display_controller_input = not OPTIONS.display_controller_input end, true, false, 1.0, 1.0)
        ;
        
        gui.set_font("snes9xtext")
        create_button(-Border_left, Buffer_height + Border_bottom, OPTIONS.allow_cheats and "Cheats: allowed" or "Cheats: blocked",
            function() OPTIONS.allow_cheats = not OPTIONS.allow_cheats end, true, false, 0.0, 1.0)
        ;
        
        create_button(Buffer_width + Border_right, Buffer_height + Border_bottom, "Erase Tiles",
            function() Tiletable = {} end, true, false, 0.0, 1.0)
        ;
        
        adjust_lateral_paddings()
    else
        if OPTIONS.allow_cheats then  -- show cheat status anyway
            gui.set_font("snes9xtext")
            draw_text(-Border_left, Buffer_height + Border_bottom, "Cheats: allowed", true, false, 0.0, 1.0)
        end
    end
    
    options_menu()
end


--#############################################################################
-- CHEATS

Cheat.is_cheating = false
function Cheat.is_cheat_active()
    if Cheat.is_cheating then
        
        gui.textHV(math.floor(Buffer_width/2 - 5*LSNES_FONT_WIDTH), 0, "Cheat", COLOUR.warning,
            change_transparency(COLOUR.warning_bg, Background_max_opacity))
        
        Timer.registerfunction(2500000, function()
            if not Cheat.is_cheating then
                gui.textHV(math.floor(Buffer_width/2 - 5*LSNES_FONT_WIDTH), 0, "Cheat", COLOUR.warning,
                change_transparency(COLOUR.background, Background_max_opacity))
            end
        end, "Cheat")
        
    end
end


-- Called from Cheat.beat_level()
function Cheat.activate_next_level(secret_exit)
    if u8(WRAM.level_exit_type) == 0x80 and u8(WRAM.midway_point) == 1 then
        if secret_exit then
            u8(WRAM.level_exit_type, 0x2)
        else
            u8(WRAM.level_exit_type, 1)
        end
    end
    
    gui.status("Cheat(exit):", fmt("at frame %d/%s", Framecount, system_time()))
    Cheat.is_cheating = true
end


-- allows start + select + X to activate the normal exit
--        start + select + A to activate the secret exit 
--        start + select + B to exit the level without activating any exits
function Cheat.beat_level()
    if Is_paused and Joypad["select"] == 1 and (Joypad["X"] == 1 or Joypad["A"] == 1 or Joypad["B"] == 1) then
        u8(WRAM.level_flag_table + Level_index, bit.bor(Level_flag, 0x80))
        
        local secret_exit = Joypad["A"] == 1
        if Joypad["B"] == 0 then
            u8(WRAM.midway_point, 1)
        else
            u8(WRAM.midway_point, 0)
        end
        
        Cheat.activate_next_level(secret_exit)
    end
end


-- This function makes Mario's position free
-- Press L+R+up to activate and L+R+down to turn it off.
-- While active, press directionals to fly free and Y or X to boost him up
Cheat.under_free_move = false
function Cheat.free_movement()
    if (Joypad["L"] == 1 and Joypad["R"] == 1 and Joypad["up"] == 1) then Cheat.under_free_move = true end
    if (Joypad["L"] == 1 and Joypad["R"] == 1 and Joypad["down"] == 1) then Cheat.under_free_move = false end
    if not Cheat.under_free_move then return end
    
    local x_pos, y_pos = u16(WRAM.x), u16(WRAM.y)
    local movement_mode = u8(WRAM.player_movement_mode)
    local pixels = (Joypad["Y"] == 1 and 7) or (Joypad["X"] == 1 and 4) or 1  -- how many pixels per frame
    
    if Joypad["left"] == 1 then x_pos = x_pos - pixels end
    if Joypad["right"] == 1 then x_pos = x_pos + pixels end
    if Joypad["up"] == 1 then y_pos = y_pos - pixels end
    if Joypad["down"] == 1 then y_pos = y_pos + pixels end
    
    -- freeze player to avoid deaths
    if movement_mode == 0 then
        u8(WRAM.frozen, 1)
        u8(WRAM.x_speed, 0)
        u8(WRAM.y_speed, 0)
        
        -- animate sprites by incrementing the effective frame
        u8(WRAM.effective_frame, (u8(WRAM.effective_frame) + 1) % 256)
    else
        u8(WRAM.frozen, 0)
    end
    -- make player invulnerable
    u8(WRAM.invisibility_timer, 127)
    -- manipulate player's position
    u16(WRAM.x, x_pos)
    u16(WRAM.y, y_pos)
    
    gui.status("Cheat(movement):", fmt("at frame %d/%s", Framecount, system_time()))
    Cheat.is_cheating = true
end


-- Command cheats: those must be typed in lsnes:Messages window as normal commands
function Cheat.unlock_cheats_from_command()
    if not OPTIONS.allow_cheats then
        OPTIONS.allow_cheats = true
        print("Unlocking the cheats.")
    end
end


COMMANDS.help = create_command("help", function()
    print("List of valid commands:")
    for key, value in pairs(COMMANDS) do
        print(">", key)
    end
    print("Enter a specific command to know about its arguments.")
    print("Cheat-commands unlock the cheat button. So, be careful while recording a movie.")
    return
end)


COMMANDS.score = create_command("score", function(num)  -- TODO: apply cheat to Luigi
    local is_hex = num:sub(1,2):lower() == "0x"
    num = tonumber(num)
    
    if not num or math.type(num) ~= "integer" or num < 0
    or num > 9999990 or (not is_hex and num%10 ~= 0) then
        print("Enter a valid score: hexadecimal representation or decimal ending in 0.")
        return
    end
    
    Cheat.unlock_cheats_from_command()
    num = is_hex and num or num/10
    memory.writehword("WRAM", WRAM.mario_score, num)
    
    print(fmt("Cheat: score set to %d0.", num))
    gui.status("Cheat(score):", fmt("%d0 at frame %d/%s", num, Framecount, system_time()))
    Cheat.is_cheating = true
    gui.repaint()
end)


COMMANDS.coin = create_command("coin", function(num)
    num = tonumber(num)
    
    if not num or math.type(num) ~= "integer" or num < 0 or num > 99 then
        print("Enter a valid integer.")
        return
    end
    
    Cheat.unlock_cheats_from_command()
    u8(WRAM.player_coin, num)
    
    print(fmt("Cheat: coin set to %d.", num))
    gui.status("Cheat(coin):", fmt("%d0 at frame %d/%s", num, Framecount, system_time()))
    Cheat.is_cheating = true
    gui.repaint()
end)


COMMANDS.powerup = create_command("powerup", function(num)
    num = tonumber(num)
    
    if not num or math.type(num) ~= "integer" or num < 0 or num > 255 then
        print("Enter a valid integer.")
        return
    end
    
    Cheat.unlock_cheats_from_command()
    u8(WRAM.powerup, num)
    
    print(fmt("Cheat: powerup set to %d.", num))
    gui.status("Cheat(powerup):", fmt("%d at frame %d/%s", num, Framecount, system_time()))
    Cheat.is_cheating = true
    gui.repaint()
end)


COMMANDS.position = create_command("position", function(arg)
    local x, y = get_arguments(arg)
    local x_sub, y_sub
    
    x, x_sub = get_arguments(x, "[^.,]+")  -- all chars, except '.' and ','
    y, y_sub = get_arguments(y, "[^.,]+")
    x = x and tonumber(x)
    y = y and tonumber(y)
    
    if not x and not y and not x_sub and not y_sub then
        print("Enter a valid pair <x.subpixel y.subpixel> or a single coordinate.")
        print("Examples: 'position 160.4 220', 'position 360.ff', 'position _ _.0', 'position none.0, none.f'")
        return
    end
    
    if x_sub then
        local size = x_sub:len()  -- convert F to F0, for instance
        x_sub = tonumber(x_sub, 16)
        x_sub = size == 1 and 0x10*x_sub or x_sub
    end
    if y_sub then
        local size = y_sub:len()
        y_sub = tonumber(y_sub, 16)
        y_sub = size == 1 and 0x10*y_sub or y_sub
    end
    
    Cheat.unlock_cheats_from_command()
    if x then s16(WRAM.x, x) end
    if x_sub then u8(WRAM.x_sub, x_sub) end
    if y then s16(WRAM.y, y) end
    if y_sub then u8(WRAM.y_sub, y_sub) end
    
    local strx, stry
    if x and x_sub then strx = fmt("%d.%.2x", x, x_sub)
    elseif x then strx = fmt("%d", x) elseif x_sub then strx = fmt("previous.%.2x", x_sub)
    else strx = "previous" end
    
    if y and y_sub then stry = fmt("%d.%.2x", y, y_sub)
    elseif y then stry = fmt("%d", y) elseif y_sub then stry = fmt("previous.%.2x", y_sub)
    else stry = "previous" end
    
    print(fmt("Cheat: position set to (%s, %s).", strx, stry))
    gui.status("Cheat(position):", fmt("to (%s, %s) at frame %d/%s", strx, stry, Framecount, system_time()))
    Cheat.is_cheating = true
    gui.repaint()
end)


COMMANDS.xspeed = create_command("xspeed", function(num)
    num = tonumber(num)
    
    if not num or math.type(num) ~= "integer" or num < -128 or num > 127 then
        print("Enter a valid integer [-128, 127].")
        return
    end
    
    Cheat.unlock_cheats_from_command()
    s8(WRAM.x_speed, num)
    
    print(fmt("Cheat: horizontal speed set to %d.", num))
    gui.status("Cheat(xspeed):", fmt("%d at frame %d/%s", num, Framecount, system_time()))
    Cheat.is_cheating = true
    gui.repaint()
end)


COMMANDS.yspeed = create_command("yspeed", function(num)
    num = tonumber(num)
    
    if not num or math.type(num) ~= "integer" or num < -128 or num > 127 then
        print("Enter a valid integer [-128, 127].")
        return
    end
    
    Cheat.unlock_cheats_from_command()
    s8(WRAM.y_speed, num)
    
    print(fmt("Cheat: vertical speed set to %d.", num))
    gui.status("Cheat(yspeed):", fmt("%d at frame %d/%s", num, Framecount, system_time()))
    Cheat.is_cheating = true
    gui.repaint()
end)



--#############################################################################
-- COMPARISON SCRIPT (EXPERIMENTAL)--

local Show_comparison  = nil
if type(OPTIONS.ghost_filename) == "string" then
    Show_comparison = io.open(OPTIONS.ghost_filename)
end


if Show_comparison then
    dofile(OPTIONS.ghost_filename)
    print("Loaded comparison script.")
    ghostfile = ghost_dumps[1]
    ghost_room_table = read_ghost_rooms(ghostfile)
end

-- END OF THE COMPARISON SCRIPT (EXPERIMENTAL)--


--#############################################################################
-- MAIN --


gui.subframe_update(false)  -- TODO: this should be true when paused or in heavy slowdown


-- KEYHOOK callback
on_keyhook = Keys.altkeyhook

-- Key presses:
Keys.registerkeypress("mouse_inwindow", function() Update_screen = true end)
Keys.registerkeypress(OPTIONS.hotkey_increase_opacity, function() increase_opacity() ; Update_screen = true end)
Keys.registerkeypress(OPTIONS.hotkey_decrease_opacity, function() decrease_opacity() ; Update_screen = true end)
Keys.registerkeypress("mouse_right", right_click)
Keys.registerkeypress("mouse_left", left_click)

-- Key releases:
Keys.registerkeyrelease("mouse_inwindow", function() Update_screen = false end)
Keys.registerkeyrelease(OPTIONS.hotkey_increase_opacity, function() Update_screen = false end)
Keys.registerkeyrelease(OPTIONS.hotkey_decrease_opacity, function() Update_screen = false end)


function on_input(subframe)
    get_joypad() -- might want to take care of subframe argument, because input is read twice per frame
    
    if OPTIONS.allow_cheats then
        Cheat.is_cheating = false
        
        Cheat.beat_level()
        Cheat.free_movement()
    end
    
end


function on_frame_emulated()
    Lastframe_emulated = get_last_frame(true)
    Is_lagged = memory.get_lag_flag()
    
    -- Mario boost indicator (experimental)
    local x = s16(WRAM.x)
    local x_sub = u8(WRAM.x_sub)
    local player_x = 256*x + x_sub
    if Previous.player_x and player_x - Previous.player_x ~= Previous.x_speed then  -- if the difference doesn't correspond to the speed
        local boost = math.floor((player_x - Previous.player_x - Previous.x_speed)/256)
        if boost > 32 or boost < -32 then boost = 0 end  -- to avoid big strings when the sign of the position changes
        Mario_boost_indicator = boost > 0 and RIGHT_ARROW:rep(boost) or LEFT_ARROW:rep(-boost)
    else
        Mario_boost_indicator = nil
    end
    
end


-- Function that is called from the paint and video callbacks
-- from_paint is true if this was called from on_paint/ false if from on_video
local function main_paint_function(not_synth, from_paint)
    if not ROM_loaded() then return end
    
    -- Initial values, don't make drawings here
    read_input()
    lsnes_status()
    lsnes_screen_info()
    create_gaps()
    
    -- Drawings are allowed now
    scan_smw()
    ROM_sha256()
    
    level_mode()
    overworld_mode()
    
    if OPTIONS.display_movie_info then show_movie_info() end
    if OPTIONS.display_misc_info then show_misc_info() end
    if OPTIONS.display_debug_info then show_controller_data() end
    if OPTIONS.display_controller_input then display_input() end
    
    Cheat.is_cheat_active()
    
    -- Comparison script (needs external file to work)
    if Show_comparison then
        comparison(not_synth)
    end
    
    lsnes_yield()
end


function on_paint(not_synth)
    main_paint_function(not_synth, true)
end


function on_video()
    Video_callback = true
    main_paint_function(false, false)
    Video_callback = false
end


-- Loading a state
function on_pre_load()
    Lastframe_emulated = nil
    
    -- Mario boost indicator (resets everything)
    Mario_boost_indicator = nil
    Previous.player_x = nil
    Previous.x_speed = nil
end

function on_post_load()
    Is_lagged = false
    gui.repaint()
end


-- Functions called on specific events
function on_readwrite()
    gui.repaint()
end


function on_reset()
    --print"on_reset"
end


-- Rewind functions
function on_rewind()
    ROM_hash = nil  -- compute hash of ROM region again
    Lastframe_emulated = nil
    
    gui.repaint()
end


function on_movie_lost(kind)
    if kind == "reload" then
        ROM_hash = nil  -- compute hash of ROM region again
    end
end


-- Repeating callbacks
set_timer_timeout(OPTIONS.timer_period)
function on_timer()
    local usecs = microseconds()
    read_input()
    
    -- Register the functions to paint callback
    for name in pairs(Timer.functions) do
        
        if Timer.functions[name].start + Timer.functions[name].timeout >= usecs then
            
            if not Timer.functions[name].registered then
                callback.register("paint", Timer.functions[name].fn)
                Timer.functions[name].registered = true
                gui.repaint()
            end
            
        else
            callback.unregister("paint", Timer.functions[name].fn)
            Timer.functions[name] = nil
            gui.repaint()
        end
        
    end
    
    set_timer_timeout(OPTIONS.timer_period)  -- calls on_timer forever
end


-- On idle: calls itself while active and one more time
set_idle_timeout(OPTIONS.idle_period)
function on_idle()
    
    if Update_screen then
        Previous.update_screen = true
        gui.repaint()
    elseif Previous.update_screen then
        Previous.update_screen = false
        gui.repaint()
    end
    
    set_idle_timeout(OPTIONS.idle_period)  -- calls on_idle forever, while idle
end
Update_screen = input.raw().mouse_inwindow.value == 1
Previous.update_screen = Update_screen


gui.repaint()
