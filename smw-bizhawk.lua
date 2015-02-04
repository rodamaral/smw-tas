---------------------------------------------------------------------------
--  Super Mario World (U) Utility Script for Lsnes - rr2 version
--  http://tasvideos.org/Lsnes.html
--  
--  Author: Rodrigo A. do Amaral (Amaraticando)
--  Git repository: https://github.com/rodamaral/smw-tas
---------------------------------------------------------------------------

--#############################################################################
-- CONFIG:

-- Display
local DISPLAY_MISC_INFO = true
local SHOW_PLAYER_INFO = true
local SHOW_SPRITE_INFO = true
local SHOW_YOSHI_INFO = true
local SHOW_COUNTERS_INFO = true

-- Colours (text)
local DEFAULT_TEXT_OPACITY = 1.0
local DEFAULT_BG_OPACITY = 0.6
local TEXT_COLOR = 0xffffffff
local OUTLINE_COLOR = 0xff000060
local WEAK_COLOR = 0xb0a9a9a9
local WARNING_COLOR = 0xffff0000
local WARNING_BG = 0xff0000ff
local CAPE_COLOR = 0xffffd700
local YOSHI_COLOR = 0xff00ffff

-- Font settings
local BIZHAWK_FONT_HEIGHT = 14
local BIZHAWK_FONT_WIDTH = 10

-- Symbols
local LEFT_ARROW = "<-"
local RIGHT_ARROW = "->"

-- END OF CONFIG < < < < < < <
--#############################################################################
-- INITIAL STATEMENTS:


-- Text/Background_max_opacity is only changed by the player using the hotkeys
-- Text/Bg_opacity must be used locally inside the functions
local Text_max_opacity = DEFAULT_TEXT_OPACITY
local Background_max_opacity = DEFAULT_BG_OPACITY
local Outline_max_opacity = 1
local Text_opacity = 1
local Bg_opacity = 1


local fmt = string.format
local gui = gui
local mainmemory = mainmemory

-- Compatibility
local u8  = mainmemory.read_u8
local s8  = mainmemory.read_s8
local u16 = mainmemory.read_u16_le
local s16 = mainmemory.read_s16_le


--#############################################################################
-- GAME AND SNES SPECIFIC MACROS:

local SMW = {
	-- Game Modes
	game_mode_overworld = 0x0e,
	game_mode_level = 0x14,
	
	sprite_max = 12, -- maximum number of sprites
}

WRAM = {
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
    
    -- cheats
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
    chuckHP = 0x1528, --
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
    player_in_air = 0x0071,
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
    player_looking_up = 0x13de,
    
    -- Yoshi
    yoshi_riding_flag = 0x187a,  -- #$00 = No, #$01 = Yes, #$02 = Yes, and turning around.
    yoshi_tongue_height = 0x188b,
    
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
local WRAM = WRAM  -- to make it slightly faster

local HITBOX_SPRITE = {
    [0x00] = { left = 0, right = 16, up = 3, down = 15},
    [0x01] = { left = 0, right = 16, up = 3, down = 26},
    [0x02] = { left = 14, right = 34, up = -2, down = 18},
    [0x03] = { left = 18, right = 30, up = 8, down = 18},
    [0x04] = { left = -2, right = 50, up = -2, down = 14},
    [0x05] = { left = -2, right = 82, up = -2, down = 14},
    [0x06] = { left = -1, right = 17, up = 2, down = 28},
    [0x07] = { left = 6, right = 50, up = 8, down = 58},
    [0x08] = { left = -10, right = 26, up = -2, down = 16},
    [0x09] = { left = 2, right = 14, up = 19, down = 29}, -- Yoshi, default = {]=] left = -4, right = 20, up = 8, down = 40},
    [0x0a] = { left = 1, right = 6, up = 7, down = 11},
    [0x0b] = { left = 4, right = 11, up = 6, down = 11},
    [0x0c] = { left = -1, right = 16, up = -2, down = 22},
    [0x0d] = { left = -2, right = 17, up = -4, down = 14},
    [0x0e] = { left = 4, right = 28, up = 6, down = 28},
    [0x0f] = { left = 0, right = 40, up = -2, down = 18},
    [0x10] = { left = -2, right = 17, up = -2, down = 32},
    [0x11] = { left = -26, right = 42, up = -24, down = 42},
    [0x12] = { left = -6, right = 6, up = 16, down = 70},
    [0x13] = { left = -6, right = 6, up = 16, down = 134},
    [0x14] = { left = 2, right = 30, up = 2, down = 16},
    [0x15] = { left = -2, right = 17, up = -2, down = 14},
    [0x16] = { left = -6, right = 22, up = -12, down = 14},
    [0x17] = { left = 0, right = 16, up = 8, down = 79},
    [0x18] = { left = 0, right = 16, up = 19, down = 79},
    [0x19] = { left = 0, right = 16, up = 35, down = 79},
    [0x1a] = { left = 0, right = 16, up = 51, down = 79},
    [0x1b] = { left = 0, right = 16, up = 67, down = 79},
    [0x1c] = { left = -2, right = 12, up = 10, down = 60},
    [0x1d] = { left = 0, right = 32, up = -3, down = 26},
    [0x1e] = { left = 4, right = 11, up = -8, down = 26},  -- Goal tape, default = { left = -34, right = 18, up = -8, down = 26},
    [0x1f] = { left = -18, right = 34, up = -4, down = 16},
    [0x20] = { left = -6, right = 6, up = -24, down = 2},
    [0x21] = { left = -6, right = 6, up = 16, down = 42},
    [0x22] = { left = -2, right = 18, up = 0, down = 18},
    [0x23] = { left = -10, right = 26, up = -24, down = 10},
    [0x24] = { left = -14, right = 46, up = 32, down = 90},
    [0x25] = { left = -16, right = 48, up = 4, down = 26},
    [0x26] = { left = -2, right = 34, up = 88, down = 98},
    [0x27] = { left = -6, right = 22, up = -4, down = 22},
    [0x28] = { left = -16, right = 16, up = -24, down = 18},
    [0x29] = { left = -18, right = 18, up = -4, down = 25},
    [0x2a] = { left = 0, right = 16, up = -8, down = 13},
    [0x2b] = { left = -2, right = 18, up = 2, down = 80},
    [0x2c] = { left = -10, right = 10, up = -8, down = 10},
    [0x2d] = { left = 2, right = 14, up = 4, down = 10},
    [0x2e] = { left = 0, right = 32, up = -2, down = 34},
    [0x2f] = { left = 0, right = 32, up = -2, down = 32},
    [0x30] = { left = 6, right = 26, up = -14, down = 16},
    [0x31] = { left = -2, right = 50, up = -2, down = 18},
    [0x32] = { left = -2, right = 50, up = -2, down = 18},
    [0x33] = { left = -2, right = 66, up = -2, down = 18},
    [0x34] = { left = -6, right = 6, up = -4, down = 6},
    [0x35] = { left = 1, right = 23, up = 0, down = 34},
    [0x36] = { left = 6, right = 62, up = 8, down = 56},
    [0x37] = { left = -2, right = 17, up = -8, down = 14},
    [0x38] = { left = 6, right = 42, up = 16, down = 58},
    [0x39] = { left = 2, right = 14, up = 3, down = 15},
    [0x3a] = { left = -10, right = 26, up = 16, down = 34},
    [0x3b] = { left = -2, right = 18, up = 0, down = 15},
    [0x3c] = { left = 10, right = 17, up = 10, down = 18},
    [0x3d] = { left = 10, right = 17, up = 21, down = 43},
    [0x3e] = { left = 14, right = 272, up = 18, down = 36},
    [0x3f] = { left = 6, right = 18, up = 8, down = 34}
}

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


--#############################################################################
-- SCRIPT UTILITIES:


local Isloaded, Movie_mode, Readonly, Currentframe, Framecount, Lagcount, Rerecords, Islagged
local function bizhawk_movie_info()
    Isloaded = movie.isloaded() == true and "Loaded" or "Not loaded"
    Movie_mode = movie.mode()  -- string
    Readonly = movie.getreadonly()
    
    Currentframe = emu.framecount()
    Framecount = movie.length()
    Lagcount = emu.lagcount()
    Rerecords = movie.rerecordcount()  -- string
    Islagged = emu.islagged()
end


-- Get screen values of the game and emulator areas
local Border_left, Border_right, Border_top, Border_bottom, Buffer_width, Buffer_height
local Screen_size, Screen_width, Screen_height, Pixel_rate_x, Pixel_rate_y
local function bizhawk_screen_info()
    Border_left = client.borderwidth()  -- Borders' dimensions
    Border_right = Border_left
    Border_top = client.borderheight()
    Border_bottom = Border_top
    
    Buffer_width = client.bufferwidth()  -- Game area
    Buffer_height = client.bufferheight()
    
	Screen_size = client.getwindowsize()  -- Emulator area
	Screen_width = client.screenwidth()
	Screen_height = client.screenheight()
    
    Pixel_rate_x = Buffer_width/256
	Pixel_rate_y = Buffer_height/224
end


local function draw_box(x1, y1, x2, y2, ...)
    ---[[
    if x2 < x1 then
        x1, x2 = x2, x1
    end
    if y2 < y1 then
        y1, y2 = y2, y1
    end
    --]]
    
    gui.drawBox(x1/Pixel_rate_x, y1/Pixel_rate_y, x2/Pixel_rate_x, y2/Pixel_rate_y, ...)
end


-- Extension to the "gui" function, to handle opacity
gui.opacity = function(text, bg)
    Text_opacity = text or Text_opacity
    Bg_opacity = bg or Bg_opacity
    
    return Text_opacity, Bg_opacity
end


-- Changes the default behavior of gui.text
local function new_gui_text(x, y, text, text_color, outline_color)
    -- Reads external variables
    local game_screen_x = Border_left
    local game_screen_y = Border_top
    
    --outline_color = change_transparency(outline_color, 0.8)
    --text_color =    change_transparency(text_color, 0.8)
    gui.text(x + game_screen_x, y + game_screen_y - 2, text, outline_color, text_color)
end


-- Changes transparency of a color: result is opaque original * transparency level (0.0 to 1.0). Acts like gui.opacity() in Snex9s.
local function change_transparency(color, transparency)
    if type(color) ~= "number" then
        error("Color must be numeric. Color = "..color)
    end
    if transparency > 1 then transparency = 1 end
    if transparency < 0 then transparency = 0 end
    
    local a = bit.rshift(color, 24)
    local rgb = color - bit.lshift(a, 24)
    local new_a = math.ceil(transparency * a)
    local new_color = bit.lshift(new_a, 24) + rgb
    
    return new_color
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
    text_length = string.len(text)
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
    
    return x, y, text_length
end


local function draw_text(x, y, text, ...)
    -- Reads external variables
    local font_width  = BIZHAWK_FONT_WIDTH
    local font_height = BIZHAWK_FONT_HEIGHT
    local full_bg = false  -- BizHawk doesn't offer this option
    local bg_default_color = full_bg and BACKGROUND_COLOR or OUTLINE_COLOR
    local text_color, halo_color, always_on_client, always_on_game, ref_x, ref_y
    local arg1, arg2, arg3, arg4, arg5, arg6 = ...
    
    if type(arg1) == "boolean" or type(arg1) == "nil" then
        
        text_color = TEXT_COLOR
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
    halo_color = change_transparency(halo_color, Background_max_opacity * Bg_opacity)
    local x_pos, y_pos = text_position(x, y, text, font_width, font_height, always_on_client, always_on_game, ref_x, ref_y)
    
    new_gui_text(x_pos, y_pos, text, text_color, halo_color)
    
end


local function alert_text(x, y, text, text_color, bg_color, outline_color, always_on_game, ref_x, ref_y)
    -- Reads external variables
    local font_width  = BIZHAWK_FONT_WIDTH
    local font_height = BIZHAWK_FONT_HEIGHT
    
    local x_pos, y_pos, text_length = text_position(x, y, text, font_width, font_height, false, always_on_game, ref_x, ref_y)
    
    draw_box(x_pos, y_pos, x_pos + text_length, y_pos + font_height, 0, bg_color)
    new_gui_text(x_pos, y_pos, text, text_color, outline_color)
end


local function draw_over_text(x, y, base, color_base, text, color_text, color_bg, always_on_client, always_on_game, ref_x, ref_y)
    draw_text(x, y, base, color_base,   color_bg, always_on_client, always_on_game, ref_x, ref_y)
    draw_text(x, y, text, color_text,          0, always_on_client, always_on_game, ref_x, ref_y)
end


-- Displays frame count, lag, etc
function timer()
	local islagged = emu.islagged()
	local isloaded = movie.isloaded()
	
	if isloaded then
		local mode = movie.mode()
		if mode == "RECORD" then alert_text(Buffer_width, Buffer_height, "(REC)", WARNING_COLOR, WARNING_BG, OUTLINE_COLOR, true) end  -- draws REC symbol while recording
	end
	
	if islagged then
        alert_text(Buffer_width, BIZHAWK_FONT_HEIGHT, "LAG", WARNING_COLOR, WARNING_BG, OUTLINE_COLOR, true, 0.5, 0.0)
    end
end


-- SMW FUNCTIONS:

local Real_frame, Previous_real_frame, Effective_frame, Game_mode, Level_index, Room_index
local Level_flag, Current_level, Is_paused, Lock_animation_flag
local function scan_smw()
    Previous_real_frame = Real_frame or u8(WRAM.real_frame)
    Real_frame = u8(WRAM.real_frame)
    Effective_frame = u8(WRAM.effective_frame)
    Game_mode = u8(WRAM.game_mode)
    Level_index = u8(WRAM.level_index)
    Level_flag = u8(WRAM.level_flag_table + Level_index)
    Is_paused = u8(WRAM.level_paused) == 1
    Lock_animation_flag = u8(WRAM.lock_animation_flag)
    Room_index = bit.lshift(u8(WRAM.room_index), 16) + bit.lshift(u8(WRAM.room_index + 1), 8) + u8(WRAM.room_index + 2)
end


-- Converts the in-game (x, y) to SNES-screen coordinates
local function screen_coordinates(x, y)
	local camera_x = u16(WRAM.camera_x)
	local camera_y = u16(WRAM.camera_y)
	
	x_screen = (x - camera_x)
	y_screen = (y - camera_y) - 1
	
	return x_screen, y_screen
end


-- Returns the in-game coordinates of the mouse
local function mouse_position(x_mouse, y_mouse)
	camera_x = u16(WRAM.camera_x)
	camera_y = u16(WRAM.camera_y)
	x_game = x_mouse + camera_x - 8
	y_game = y_mouse + camera_y - 15
	
    --draw_text(1, 210, string.format("Mouse in game %d %d", x_game, y_game))
	return x_game, y_game
end


-- Displays the SNES-screen and in-game coordinates of the mouse -- EDIT
local function mouse()
	mouse_table = input.getmouse()
	x_mouse = mouse_table.X
	y_mouse = mouse_table.Y
	text = string.format("Mouse(%d, %d)", x_mouse, y_mouse)
	x, y = mouse_position(x_mouse, y_mouse)
	gui.drawRectangle(x, y, 15, 15, "red") -- (Pasky13's script is better for now)
end


-- Returns the size of the object: x left, x right, y up, y down, color line, color background
local function hitbox(sprite, status)
	if sprite == 0x35 then return -5, 5, 3, 16, "white", 0x3000FF37
	elseif sprite >= 0xda and sprite <= 0xdd then return -7, 7, -13, 0, "red", 0x3000F2FF
	
	
	-- elseif sprite >= DA and sprite <= DD then return -7, 7, -13, 0, "red", 0x3000F2FF
	
	else return -7, 7, -13, 0, "orange", 0x3000F2FF end  -- unknown hitbox
end


local function show_movie_info()  -- fix it / optional use, as BizHawk has a suitable movie info
    -- Reads external variables
    local width = BIZHAWK_FONT_WIDTH
    
    local rec_color = Readonly and TEXT_COLOR or WARNING_COLOR --is_recording and WARNING_COLOR or TEXT_COLOR
    local recording_bg = Readonly and OUTLINE_COLOR or WARNING_BG --is_recording and WARNING_BG or BACKGROUND_COLOR
    
    --[[
    local text_table = {
        {Movie_mode.." ", rec_color, recording_bg},
        {fmt("%d/%d", Currentframe, Framecount), TEXT_COLOR, OUTLINE_COLOR},
        {fmt("|%d ", Rerecords), WEAK_COLOR, OUTLINE_COLOR},
        {Lagcount, WARNING_COLOR, OUTLINE_COLOR},
    }
    
    draw_text(-Border_left, -Border_top, text_table, true)
    --]]
    draw_text(0, Buffer_height, fmt("%s,%s", Isloaded, Movie_mode), true, true)
    --local str = frame_time(Currentframe - 1)    -- Shows the latest frame emulated, not the frame being run now
    --custom_text("right", "bottom", str, TEXT_COLOR, recording_bg)
    
    --if Is_lagged then
        --gui.textHV(screen_width/2 - 3*LSNES_FONT_WIDTH, 2*LSNES_FONT_HEIGHT, "Lag", WARNING_COLOR, change_transparency(WARNING_BG, Background_max_opacity))
    --end
    
end


local function show_misc_info()
    local color = TEXT_COLOR
    local color_bg = OUTLINE_COLOR
    local RNG = u8(WRAM.RNG)
    
    local main_info = fmt("Frame(%02x, %02x) RNG(%04x) Mode(%02x)",
                                    Real_frame, Effective_frame, RNG, Game_mode)
    ;
    draw_text(Buffer_width + Border_right, -Border_top, main_info, color, color_bg, true, false, 1.0, 1.0)
    
end


local function player(camera_x, camera_y)
    -- Font
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
    local player_in_air = u8(WRAM.player_in_air)
    local player_blocked_status = u8(WRAM.player_blocked_status)
    local player_item = u8(WRAM.player_item)
    local is_ducking = u8(WRAM.is_ducking)
    local on_ground = u8(WRAM.on_ground)
    local spinjump_flag = u8(WRAM.spinjump_flag)
    local can_jump_from_water = u8(WRAM.can_jump_from_water)
    local carrying_item = u8(WRAM.carrying_item)
    local yoshi_riding_flag = u8(WRAM.yoshi_riding_flag)
    
    -- Transformations
    if direction == 0 then direction = LEFT_ARROW else direction = RIGHT_ARROW end
    if x_sub%0x10 == 0 then x_sub = bit.rshift(x_sub, 4) end
    if y_sub%0x10 == 0 then y_sub = bit.rshift(y_sub, 4) end
    
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
    
    -- Blocked status
    local blocked_status = {}
    local was_boosted
    if bit.check(player_blocked_status, 0) then
        table.insert(blocked_status, "R")
        if x_speed < 0 then was_boosted = true end
    else table.insert(blocked_status, " ")
    end
    
    if bit.check(player_blocked_status, 1) then
        table.insert(blocked_status, "L")
        if x_speed > 0 then was_boosted = true end
    else table.insert(blocked_status, " ")
    end
    
    if bit.check(player_blocked_status, 2) then table.insert(blocked_status, "D") else table.insert(blocked_status, " ") end
    
    if bit.check(player_blocked_status, 3) then
        table.insert(blocked_status, "U")
        if y_speed > 6 then was_boosted = true end
    else table.insert(blocked_status, " ")
    end
    
    if bit.check(player_blocked_status, 4) then table.insert(blocked_status, "M") else table.insert(blocked_status, " ") end
    local block_str = table.concat(blocked_status)
    
    -- Display info
    local i = 0
    local delta_x = BIZHAWK_FONT_WIDTH
    local delta_y = BIZHAWK_FONT_HEIGHT
    local table_x = 0
    local table_y = 0.16*Buffer_height -- BizHawk equivalent to 64/448
    draw_text(table_x, table_y + i*delta_y, fmt("Meter (%03d, %02d) %s", p_meter, take_off, direction))
    draw_text(table_x + 18*delta_x, table_y + i*delta_y, fmt(" %+d", spin_direction),
    (is_spinning and TEXT_COLOR) or WEAK_COLOR)
    i = i + 1
    
    draw_text(table_x, table_y + i*delta_y, fmt("Pos (%+d.%x, %+d.%x)", x, x_sub, y, y_sub))
    i = i + 1
    
    draw_text(table_x, table_y + i*delta_y, fmt("Speed (%+d(%d.%02.0f), %+d)", x_speed, x_speed_int, x_speed_frac, y_speed))
    i = i + 1
    
    if is_caped then
        draw_text(table_x, table_y + i*delta_y, fmt("Cape (%.2d, %.2d)/(%d, %d)", cape_spin, cape_fall, flight_animation, diving_status), CAPE_COLOR)
        i = i + 1
    end
    
    local block_info_bg = was_boosted and WARNING_BG or nil
    draw_text(table_x, table_y + i*delta_y,       "Block: ",   TEXT_COLOR, block_info_bg)
    draw_over_text(table_x + 7*delta_x, table_y + i*delta_y, "RLDUM", WEAK_COLOR, block_str, WARNING_COLOR)
    i = i + 1
    
    draw_text(table_x, table_y + i*delta_y, fmt("Camera (%d, %d)", camera_x, camera_y))
    
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


local SPRITES_COLOR = {0xff00ff00, 0xff0000ff, 0xffffff00, 0xffff8000, 0xffff00ff, 0xffb00040} --TEST
local function sprites(camera_x, camera_y)
	local counter = 0
    local table_position = 0.18*Buffer_height
	
    for i = 0, SMW.sprite_max - 1 do
        local sprite_status = u8(WRAM.sprite_status + i) 
        if sprite_status ~= 0 then 
			local x = bit.lshift(s8(WRAM.sprite_x_high + i), 8) + u8(WRAM.sprite_x_low + i)
			local y = bit.lshift(s8(WRAM.sprite_y_high + i), 8) + u8(WRAM.sprite_y_low + i)
            local x_sub = u8(WRAM.sprite_x_sub + i)
            local y_sub = u8(WRAM.sprite_y_sub + i)
            local number = u8(WRAM.sprite_number + i)
            local stun = u8(WRAM.sprite_stun + i)
			local x_speed = s8(WRAM.sprite_x_speed + i)
			local y_speed = s8(WRAM.sprite_y_speed + i)
			-- local throw = u8(WRAM.sprite_throw + i)
			local contact_mario = u8(WRAM.sprite_contact_mario + i)
			--local contsprite = u8(WRAM.spriteContactSprite + i)  --AMARAT
			--local contobject = u8(WRAM.spriteContactoObject + i)  --AMARAT
			--local sprite_id = u8(0x160e + i) --AMARAT
			
			if stun ~= 0 then stun = ' '..tostring(stun)..' ' else stun = ' ' end
			
			-- Prints those info in the sprite-table
			local draw_str = string.format("#%02x %02x %02x%s%d.%1x(%+02d) %+03d.%1x(%+02d)",
											i, number, sprite_status, stun, x, x_sub/16, x_speed, y, y_sub/16, y_speed)
			;
			
			-- Prints those informations next to the sprite
			local x_screen, y_screen = screen_coordinates(x, y)
            
            local info_color
            if number == 0x35 then
                info_color = YOSHI_COLOR
            else
                info_color = SPRITES_COLOR[i%(#SPRITES_COLOR) + 1]
            end
            
			if contact_mario == 0 then contact_mario = '' end
			draw_text(Pixel_rate_x*(x_screen + 8), Pixel_rate_y*(y_screen - 0), fmt("#%02x %s", i, contact_mario), info_color, OUTLINE_COLOR, true, false, 0.5, 1.0)
			
			-- Prints hitbox (Pasky13's script is better for now)
			--local x_left, x_right, y_up, y_down, color_line, color_background = hitbox(number, stun)
			--gui.drawBox(x_screen + x_left, y_screen + y_up, x_screen + x_right, y_screen + y_down, color_line, color_background)
			
            draw_text(Buffer_width + Border_right, table_position + counter*BIZHAWK_FONT_HEIGHT, draw_str, info_color, OUTLINE_COLOR, true, false, 1.0) --test
            
			counter = counter + 1
        end
	end
	
end

local function yoshi(camera_x, camera_y)
	local yoshi_id = get_yoshi_id()
	if yoshi_id ~= nil then 
		local eat_id = u8(WRAM.sprite_miscellaneous + yoshi_id)
		local eat_type = u8(WRAM.sprite_number + eat_id)
		local tongue_len = u8(WRAM.sprite_tongue_length + yoshi_id)
		local tongue_timer = u8(WRAM.sprite_tongue_timer + yoshi_id)
		
		eat_type = eat_id == 0xff and "-" or eat_type
		eat_id = eat_id == 0xff and "-" or string.format("#%02x", eat_id)
		
		draw_text(0, Buffer_height/2, fmt("Yoshi (%0s, %0s, %02X, %02X)", eat_id, eat_type, tongue_len, tongue_timer), YOSHI_COLOR, true, true, 0.0, 0.5)
	end
end


local function show_counters()
    local height = BIZHAWK_FONT_HEIGHT
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
        local color = color or TEXT_COLOR
        
        draw_text(0, 0.6*Buffer_height + (text_counter * BIZHAWK_FONT_HEIGHT), fmt("%s: %d", label, (value * mult) - frame), color)
    end
    
    display_counter("Multi Coin", multicoin_block_timer, 0, 1, 0, 0xffffff00) --
    display_counter("Pow", gray_pow_timer, 0, 4, Effective_frame % 4, 0xffa5a5a5) --
    display_counter("Pow", blue_pow_timer, 0, 4, Effective_frame % 4, 0xff4242de) --
    display_counter("Dir Coin", dircoin_timer, 0, 4, Real_frame % 4, 0xff8c5a19) --
    display_counter("P-Balloon", pballoon_timer, 0, 4, Real_frame % 4, 0xfff8d870) --
    display_counter("Star", star_timer, 0, 4, (Effective_frame - 3) % 4, 0xffffd773)  --
    display_counter("Invibility", invisibility_timer, 0, 1, 0)
    display_counter("Fireflower", fireflower_timer, 0, 1, 0, 0xffff8c00) --
    display_counter("Yoshi", yoshi_timer, 0, 1, 0, YOSHI_COLOR) --
    display_counter("Swallow", swallow_timer, 0, 4, (Effective_frame - 1) % 4, YOSHI_COLOR) --
    display_counter("Lakitu", lakitu_timer, 0, 4, Effective_frame % 4) --
    display_counter("End Level", end_level_timer, 0, 2, (Real_frame - 1) % 2)
    display_counter("Score Incrementing", score_incrementing, 0x50, 1, 0)
    
    if Lock_animation_flag ~= 0 then display_counter("Animation", animation_timer, 0, 1, 0) end  -- shows when player is getting hurt or dying
    
end


-- Main function to run inside a level
local function level_mode()
    if Game_mode == SMW.game_mode_level then
        -- Frequent WRAM values
        local camera_x = s16(WRAM.camera_x)
        local camera_y = s16(WRAM.camera_y)
        
        if SHOW_SPRITE_INFO then sprites(camera_x, camera_y) end
        
        --if SHOW_LEVEL_INFO then level() end
        
        if SHOW_PLAYER_INFO then player(camera_x, camera_y) end
        
        if SHOW_YOSHI_INFO then yoshi(camera_x, camera_y) end
        
        if SHOW_COUNTERS_INFO then show_counters() end
    end
end


local function overworld_mode()
    if Game_mode ~= SMW.game_mode_overworld then return end
    
    -- Font
    gui.opacity(1.0, 1.0)
    
    local height = BIZHAWK_FONT_HEIGHT
    local y_text = 0
    
    -- Real frame modulo 8
    local real_frame_8 = Real_frame%8
    draw_text(Buffer_width + Border_right, y_text, fmt("Real Frame = %3d = %d(mod 8)", Real_frame, real_frame_8), true)
    
    -- Star Road info
    local star_speed = u8(WRAM.star_road_speed)
    local star_timer = u8(WRAM.star_road_timer)
    y_text = y_text + height
    draw_text(Buffer_width + Border_right, y_text, fmt("Star Road(%x %x)", star_speed, star_timer), CAPE_COLOR, true)
end


local function test_draw_pixels()
    gui.drawPixel(0, 0)
    gui.drawPixel(0, Buffer_height - 1)
    gui.drawPixel(Buffer_width - 1, 0)
    draw_text(Buffer_width - 1, Buffer_height - 1, "A")
    gui.drawPixel(Buffer_width/Pixel_rate_x - 1, Buffer_height/Pixel_rate_y - 1)
end


--#############################################################################
-- MAIN --


while true do
    -- Initial values, don't make drawings here
    bizhawk_movie_info()
    bizhawk_screen_info()
	
    timer()
    
    scan_smw()
    
	level_mode()
    overworld_mode()
    
 	if DISPLAY_MISC_INFO then show_misc_info() end
    
	emu.frameadvance()
end

client.paint()
