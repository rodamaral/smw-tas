--
--	Super Mario World (U) Utility Script for Lsnes
--	http://tasvideos.org/Lsnes.html
--	
--	Author: Rodrigo A. do Amaral (Amaraticando)
--  Git repository: https://github.com/rodamaral/smw-tas
--

--#############################################################################
-- CONFIG:
local lsnes_version = "stable"  -- default "stable" ; options = {"stable", "beta"}, change according to your version

-- Hotkeys  (look at the manual to see all the valid keynames)
-- make sure that the hotkeys below don't conflict with previous bindings
local hotkey_increase_transparency = "equals"  -- the '=' and '+' key 
local hotkey_decrease_transparency = "minus"   -- the '_' and '-' key

-- Display
local display_movie_info = true
local display_misc_info = true
local show_player_info = true
local show_player_hitbox = true
local show_interaction_points = true
local show_sprite_info = true
local show_sprite_hitbox = true  -- you still have to select the sprite with the mouse
local show_all_sprite_info = false  -- things like sprite status and stun timer when they are in their 'default' state
local show_level_info = true
local show_yoshi_info = true
local show_counters_info = true
local show_controller_input = true

-- Cheats
local allow_cheats = true -- better turn off while recording a TAS

-- Height and width of the font characters
local lsnes_font_height = 16
local lsnes_font_width = 8

-- Colours (text)
local text_color = 0x00ffffff
local background_color = 0x90000000
local joystick_recording_color = 0x30ffff00
local joystick_playing_color = 0x30ffffff  -- unused yet
local lag_color = 0x00ff0000
local REC_color = 0x00ff0000
local REC_bg = 0x900000ff
local rerecord_color = 0x00a9a9a9

-- Colours (hitbox and related text)
local mario_color = 0x00ff0000
local mario_bg = -1
local mario_bg_mounted = -1
local interaction_color = 0x00ffffff
local interaction_bg = 0xc0000000
local interaction_color_without_hitbox = 0xc0000000

local sprites_color1 = {0x0000ff00, 0x00ff8000, 0x000000ff, 0x0000ffa0}
local sprites_bg1 = {0xa000ff00, 0xa0ff8000, 0xa00000ff, 0xa000ffa0}
local sprites_color2 = {0x00ff00ff, 0x00c06954, 0x00b22222, 0x008068a0}
local sprites_bg2 = {0xc0ff00ff, 0xc0c06954, 0xc0b22222, 0xc08068a0}
local sprites_interaction_color = 0x00ffff00  -- unused yet

local yoshi_color = 0x0000ffff
local yoshi_bg = 0xb000ffff
local yoshi_bg_mounted = -1
local extended_sprites = 0x00ffffff  -- unused yet

local cape_color = 0x00000000
local cape_bg = 0xc0ffd700
local cape_block = 0x00ff0000

local block_color = 0x0000008b
local block_bg = 0xa022cc88

-- END OF CONFIG < < < < < < <

--#############################################################################
-- GAME SPECIFIC MACROS:

local SMW = {
	-- Game Modes
	game_mode_overworld = 0x0e,
	game_mode_level = 0x14,
	
	sprite_max = 12, -- maximum number of sprites
}

-- print(@@LUA_SCRIPT_FILENAME@@)
print("This script is supposed to be run on Lsnes.")
print("lsnes_version set to: ", lsnes_version)
print("You can change that in the script.")

local RAM = {
    game_mode = 0x7e0100, --
    real_frame = 0x7e0013,
    effective_frame = 0x7e0014,
    RNG = 0x7e148d,
	current_level = 0x7e00fe,  -- plus 1
	sprite_memory_header = 0x7e1692,
	lock_animation_flag = 0x7e009d,	--Most codes will still run if this is set, but almost nothing will move or animate.
	
	-- cheats
	frozen = 0x7e13fb,
	level_paused = 0x7e13d4,
	level_index = 0x7e13bf,
	room_index = 0x7e00ce,
	level_flag_table = 0x7e1ea2,
	level_exit_type = 0x7e0dd5,
	midway_point = 0x7e13ce,
	
	-- Camera
    x_camera = 0x7e001a,
    y_camera = 0x7e001c,
	vertical_scroll = 0x7e1412,  -- #$00 = Disable; #$01 = Enable; #$02 = Enable if flying/climbing/etc.
	
	-- Sprites
    sprite_status = 0x7e14c8,
	sprite_throw = 0x7e1504, --
	chuckHP = 0x7e1528, --
    sprite_stun = 0x7e1540,
	sprite_contact_mario = 0x7e154c,
	spriteContactSprite = 0x7e1564, --
	spriteContactoObject = 0x7e15dc,  --
    sprite_number = 0x7e009e,
    sprite_x_high = 0x7e14e0,
    sprite_x_low = 0x7e00e4,
    sprite_y_high = 0x7e14d4,
    sprite_y_low = 0x7e00d8,
    sprite_x_sub = 0x7e14f8,
    sprite_y_sub = 0x7e14ec,
    sprite_x_speed = 0x7e00b6,
    sprite_y_speed = 0x7e00aa,
	sprite_direction = 0x7e157c,
    sprite_x_offscreen = 0x7e15a0, 
	sprite_y_offscreen = 0x7e186c,
	sprite_miscellaneous = 0x7e160e,
	sprite_miscellaneous2 = 0x7e163e,
	sprite_tongue_length = 0x7e151c,
	sprite_tongue_timer = 0x7e1558,
	sprite_tongue_wait = 0x7e14a3,
	sprite_yoshi_squatting = 0x7e18af,
	sprite_buoyancy = 0x7e190e,
	
	-- Player
    x = 0x7e0094,
    y = 0x7e0096,
	previous_x = 0x7e00d1,
	previous_y = 0x7e00d3,
    x_sub = 0x7e13da,
    y_sub = 0x7e13dc,
    x_speed = 0x7e007b,
	x_subspeed = 0x7e007a,
    y_speed = 0x7e007d,
	direction = 0x7e0076,
	is_ducking = 0x7e0073,
    p_meter = 0x7e13e4,
    take_off = 0x7e149f,
    powerup = 0x7e0019,
    cape_spin = 0x7e14a6,
    cape_fall = 0x7e14a5,
	cape_interaction = 0x7e13e8,
	flight_animation = 0x7e1407,
	diving_status = 0x7e1409,
	player_in_air = 0x7e0071,
	climbing_status = 0x7e0074,
	spinjump_flag = 0x7e140d,
	player_blocked_status = 0x7e0077, 
	player_item = 0x7e0dc2, --hex
	cape_x = 0x7e13e9,
	cape_y = 0x7e13eb,
	on_ground = 0x7e13ef,
	on_ground_delay = 0x7e008d,
	on_air = 0x7e0072,
	can_jump_from_water = 0x7e13fa,
	carrying_item = 0x7e148f,
	mario_score = 0x7e0f34,
	
	-- Yoshi
	yoshi_riding_flag = 0x7e187a,  -- #$00 = No, #$01 = Yes, #$02 = Yes, and turning around.
	
	-- Timer
	--keep_mode_active = 0x7e0db1,
	score_incrementing = 0x7e13d6,
	end_level_timer = 0x7e1493,
    multicoin_block_timer = 0x7e186b, 
    gray_pow_timer = 0x7e14ae,
    blue_pow_timer = 0x7e14ad,
    dircoin_timer = 0x7e190c,
    pballoon_timer = 0x7e1891,
    star_timer = 0x7e1490,
	animation_timer = 0x7e1496,--
    invisibility_timer = 0x7e1497,
	fireflower_timer = 0x7e149b,
	yoshi_timer = 0x7e18e8,
	swallow_timer = 0x7e18ac,
}

--#############################################################################
-- SCRIPT UTILITIES:
-- Variables used in various functions
local NTSC_framerate = 10738636/178683
local previous_lag_count = nil
local is_lagged = nil

-- Draws the text formatted in a given position within the screen space
-- x can also be "left", "middle" and "right"
-- y can also be "top", "middle" and "bottom"
function draw_text(x, y, text_color, background_color, text, ...)
	formatted_text = string.format(text, ...)
	local text_length = string.len(formatted_text)*lsnes_font_width
	
	-- calculates suitable x
	if x == "left" then x = 0
	elseif x == "right" then x = screen_width - text_length
	elseif x == "middle" then x = (screen_width - text_length)/2
	end
	if x < 0 then x = 0 end
	
	local x_final = x + text_length
	if x_final > screen_width then
		x = screen_width - text_length
	end
	
	-- calculates suitable y
	if y == "top" then y = 0
	elseif y == "bottom" then y = screen_height - lsnes_font_height
	elseif y == "middle" then y = (screen_height - lsnes_font_height)/2
	end
	if y < 0 then y = 0 end
	
	local y_final = y + lsnes_font_height
	if y_final > screen_height then
		y = screen_height - lsnes_font_height
	end
	
	-- draws the text
	gui.text(x, y, formatted_text, text_color, background_color)
	return x, y, x_final, y_final, text_length
end

-- Prints the elements of a table in the console
local function print_table(data)
	data = ((type(data) == "table") and data) or {data}
	
	for key, value in pairs(data) do
		if type(key) == "table" then
			print_table(value)
			print("...")
		else
			print(key, value)
		end
	end
end

-- Checks whether 'data' is a table and then prints it in (x,y)
local function draw_table(x, y, data, ...)
	local data = ((type(data) == "table") and data) or {data}
	local index = 0
	
	for key, value in ipairs(data) do
		if value ~= "" and value ~= nil then
			index = index + 1
			draw_text(x, y + (lsnes_font_height * index), text_color, background_color, value, ...)
		end
	end
end

-- Returns frames-time conversion
local function frame_time(frame)
	local total_seconds = frame/NTSC_framerate
	local total_seconds, subseconds = math.modf(total_seconds)
	local total_minutes = math.floor(total_seconds/60)
	local seconds = total_seconds - 60*total_minutes
	local hours = math.floor(total_minutes/60)
	local minutes = total_minutes - 60*hours
	
	if hours == 0 then hours = "" else hours = string.format("%d:", hours) end
	local str = string.format("%s%.2d:%.2d.%.3d", hours, minutes, seconds, 1000*subseconds)
	return str
end

-- Changes transparency of a color: result is original color * transparency level (0.0 to 1.0). Acts like gui.opacity() in Snex9s.
function change_transparency(color, transparency)
	if type(color) ~= "number" then
		color = gui.color(color)
	end
	if transparency > 1 then transparency = 1 end
	if transparency < 0 then transparency = 0 end
	
	local a, rgb, new_a, new_color
	a = bit.lrshift(color, 24)
	rgb = color - bit.lshift(a, 24)
	new_a = 0x100 - math.floor((transparency * (0x100 - a)))
	new_color = bit.lshift(new_a, 24) + rgb
	
	return new_color
end

-- draw a pixel given (x,y) with SNES' pixel sizes
function draw_pixel(x, y, ...)
	gui.pixel(2*x, 2*y, ...)
	gui.pixel(2*x + 1, 2*y, ...)
	gui.pixel(2*x, 2*y + 1, ...)
	gui.pixel(2*x + 1, 2*y + 1, ...)
end

-- draws a line given (x,y) and (x',y') with SNES' pixel sizes
function draw_line(x1, y1, x2, y2, ...)
	gui.line(2*x1, 2*y1, 2*x2, 2*y2, ...)
	gui.line(2*x1 + 1, 2*y1, 2*x2 + 1, 2*y2, ...) -- TESTE
	gui.line(2*x1, 2*y1 + 1, 2*x2, 2*y2 + 1, ...) -- TESTE
	gui.line(2*x1 + 1, 2*y1 + 1, 2*x2 + 1, 2*y2 + 1, ...) -- TESTE
end

-- draws a box given (x,y) and (x',y') with SNES' pixel sizes
local function draw_box(x1, y1, x2, y2, ...)
	if x2 < x1 then
		local _ = x1
		x1 = x2
		x2 = _
	end
	if y2 < y1 then
		local _ = y1
		y1 = y2
		y2 = _
	end
	
	local x = 2*x1
	local y = 2*y1
	local w = (2 * (x2 - x1)) + 2  -- adds thickness
	local h = (2 * (y2 - y1)) + 2  -- adds thickness
	gui.rectangle(x, y, w, h, ...)
end

-- mouse (x, y)
x_mouse, y_mouse = 0, 0
function read_mouse()
	x_mouse = user_input.mouse_x.value
	y_mouse = user_input.mouse_y.value
	local left_click = user_input.mouse_left.value
	local right_click = user_input.mouse_right.value
	
	return x_mouse, y_mouse, left_click, right_click
end

-- Uses the mouse click to change the opacity of the gui functions
-- Left click = more transparency
-- Right click = less transparency
local function change_background_opacity()
	if not user_input then return end
	if not user_input[hotkey_increase_transparency] then print(hotkey_increase_transparency, ": Wrong hotkey for \"hotkey_increase_transparency\"."); return end
	if not user_input[hotkey_decrease_transparency] then print(hotkey_decrease_transparency, ": Wrong hotkey for \"hotkey_decrease_transparency\"."); return end
	
	
	local increase_key = user_input[hotkey_increase_transparency].value
	local decrease_key = user_input[hotkey_decrease_transparency].value
	
	if increase_key  == 1 and background_color < 0xf8000000 then background_color = background_color + 0x04000000 end
	if decrease_key == 1 and background_color > 0x08000000 then background_color = background_color - 0x04000000 end
	
end

-- Gets input of the 1st controller
joypad = {}
local function get_joypad()
	joypad["B"] = input.get2(1, 0, 0)
	joypad["Y"] = input.get2(1, 0, 1)
	joypad["select"] = input.get2(1, 0, 2)
	joypad["start"] = input.get2(1, 0, 3)
	joypad["up"] = input.get2(1, 0, 4)
	joypad["down"] = input.get2(1, 0, 5)
	joypad["left"] = input.get2(1, 0, 6)
	joypad["right"] = input.get2(1, 0, 7)
	joypad["A"] = input.get2(1, 0, 8)
	joypad["X"] = input.get2(1, 0, 9)
	joypad["L"] = input.get2(1, 0, 10)
	joypad["R"] = input.get2(1, 0, 11)
end

-- Displays input of the 1st controller
local function display_input()
	local P1_input = ""
	
	if joypad["left"] == 1 then P1_input = P1_input.."<" else P1_input = P1_input.." " end
	if joypad["up"] == 1 then P1_input = P1_input.."^" else P1_input = P1_input.." " end
	if joypad["right"] == 1 then P1_input = P1_input..">" else P1_input = P1_input.." " end
	if joypad["down"] == 1 then P1_input = P1_input.."v" else P1_input = P1_input.." " end
	P1_input = P1_input.." "
	if joypad["A"] == 1 then P1_input = P1_input.."A" else P1_input = P1_input.." " end
	if joypad["B"] == 1 then P1_input = P1_input.."B" else P1_input = P1_input.." " end
	if joypad["Y"] == 1 then P1_input = P1_input.."Y" else P1_input = P1_input.." " end
	if joypad["X"] == 1 then P1_input = P1_input.."X" else P1_input = P1_input.." " end
	P1_input = P1_input.." "
	if joypad["L"] == 1 then P1_input = P1_input.."L" else P1_input = P1_input.." " end
	if joypad["R"] == 1 then P1_input = P1_input.."R" else P1_input = P1_input.." " end
	P1_input = P1_input.." "
	if joypad["start"] == 1 then P1_input = P1_input.."S" else P1_input = P1_input.." " end
	if joypad["select"] == 1 then P1_input = P1_input.."s" else P1_input = P1_input.." " end
	--[[
	-----------
	INPUTMOVIE = movie.copy_movie(INPUTMOVIE, "Salty Isle from WIP")
	INPUTFRAME = movie.get_frame(INPUTMOVIE, movie.currentframe())
	a = INPUTFRAME:serialize()
	print(movie.currentframe(), a)
	-----------
	]]
	draw_text("left", "bottom", joystick_recording_color, background_color, P1_input)
end

--#############################################################################
-- SMW FUNCTIONS:

local real_frame, previous_real_frame, effective_frame, game_mode, level_index, room_index, level_flag, current_level, is_paused, lock_animation_flag
local function scan_smw()
	previous_real_frame = real_frame or memory.readbyte(RAM.real_frame)
	real_frame = memory.readbyte(RAM.real_frame)
	effective_frame = memory.readbyte(RAM.effective_frame)
	game_mode = memory.readbyte(RAM.game_mode)
	level_index = memory.readbyte(RAM.level_index)
	level_flag = memory.readbyte(RAM.level_flag_table + level_index)
	is_paused = memory.readbyte(RAM.level_paused) == 1
	lock_animation_flag = memory.readbyte(RAM.lock_animation_flag)
	room_index = bit.lshift(memory.readbyte(RAM.room_index), 16) + bit.lshift(memory.readbyte(RAM.room_index + 1), 8) + memory.readbyte(RAM.room_index + 2)
end

function is_game_lagged()
	if memory.get_lag_flag then return memory.get_lag_flag() end  -- only beta version has this function
	
	if not previous_real_frame then previous_real_frame = real_frame end  -- only for stable version
	local lag_flag = real_frame == previous_real_frame					  -- this might have false positives
	return lag_flag
end

-- Converts the in-game (x, y) to SNES-screen coordinates
function screen_coordinates(x, y, x_camera, y_camera)
	local x_screen = (x - x_camera)
	local y_screen = (y - y_camera) - 1
	
	return x_screen, y_screen
end

-- Converts lsnes-screen coordinates to in-game (x, y)
function game_coordinates(x_lsnes, y_lsnes, x_camera, y_camera)
	local x_game = (x_lsnes/2) + x_camera
	local y_game = (y_lsnes/2 + 1) + y_camera
	
	return x_game, y_game
end

-- draws the boundaries of a block
function draw_block(x, y, x_camera, y_camera)
	if not (x and y) then return end
	
	local x_game, y_game
	if global_fix_block then
		x_game, y_game = global_x_block, global_y_block
	else
		x_game, y_game = game_coordinates(x, y, x_camera, y_camera)
		global_x_block, global_y_block = x_game, y_game
		return
	end
	
	local color_text = change_transparency(text_color, 0.8)
	local color_background = change_transparency(background_color, 0.5)
	
	local left = 16*math.floor(x_game/16)
	local top = 16*math.floor(y_game/16)
	left, top = screen_coordinates(left, top, x_camera, y_camera)
	local right = left + 15
	local bottom = top + 15
	
	draw_box(left, top, right, bottom, 2, block_color, block_bg)
	draw_text(2*(left - 16), 2*(top + 4), color_text, color_background, "%4d", 16*math.floor(x_game/16) - 13)
	draw_text(2*(left + 16), 2*(top + 4), color_text, color_background, "%4d", 16*math.floor(x_game/16) + 12)
end

-- erases block drawing
global_fix_block = false
global_x_block , global_y_block = nil, nil
function clear_block_drawing()
	if not user_input.mouse_left then return end
	if user_input.mouse_left.value == 0 then return end
	
	global_fix_block = not global_fix_block
end

-- uses the mouse to select a sprite
function select_sprite(x_mouse, y_mouse, x_camera, y_camera)
	local x_game, y_game = game_coordinates(x_mouse, y_mouse, x_camera, y_camera)
	local sprite_id
	
	for id = 0, SMW.sprite_max - 1 do
		local sprite_status = memory.readbyte(RAM.sprite_status + id)
		if sprite_status ~= 0 then
			local x_sprite = bit.lshift(memory.readbyte(RAM.sprite_x_high + id), 8) + memory.readbyte(RAM.sprite_x_low + id)
			local y_sprite = bit.lshift(memory.readbyte(RAM.sprite_y_high + id), 8) + memory.readbyte(RAM.sprite_y_low + id)
			
			if x_sprite >= x_game - 16 and x_sprite <= x_game and y_sprite >= y_game - 24 and y_sprite <= y_game then
				sprite_id = id
				break
			end
		end
	end
	
	if not sprite_id then return end
	
	draw_text("middle", "middle", text_color, background_color, "#%d(%4d, %3d)", sprite_id, x_game, y_game)
	return sprite_id, x_game, y_game
end

-- TESTE
function show_hitbox(sprite_table, sprite_id)
	if not sprite_table[sprite_id] then print("Error", sprite_id, type(sprite_id)); return end
	
	if sprite_table[sprite_id] == "none" then sprite_table[sprite_id] = "sprite"; return end
	--if sprite_table[sprite_id] == "sprite" then sprite_table[sprite_id] = "block"; return end
	--if sprite_table[sprite_id] == "block" then sprite_table[sprite_id] = "both"; return end
	--if sprite_table[sprite_id] == "both" then sprite_table[sprite_id] = "none"; return end
	if sprite_table[sprite_id] == "sprite" then sprite_table[sprite_id] = "none"; return end
end

function sprite_click()
	if user_input.mouse_right.value == 0 then return end
	if not sprite_paint then return end
	
	local x_camera = memory.readsword(RAM.x_camera)
	local y_camera = memory.readsword(RAM.y_camera)
	local id = select_sprite(x_mouse, y_mouse, x_camera, y_camera)
	
	if id then
		id = tostring(id)
		show_hitbox(sprite_paint, id)
	end
end

-- Returns the size of the object: x left, x right, y up, y down, oscillation flag, [,intermediate y]
local function hitbox(sprite, status)
	if sprite == 0x35 then return 3, 13, 19, 31, false  -- Yoshi EDITED 2
	elseif sprite >= 0x00 and sprite <= 0x0c then return 1, 15, 3, 17, true, {8}  -- Koopas 2
	elseif sprite >= 0x0f and sprite <= 0x10 then return 1, 15, 3, 16, true, {9}  -- Goombas 2
	elseif sprite == 0x0e then return 3, 4, 9, 12, false  --  Keyhole
	-- elseif sprite == 0x29 then return -7, 7, 65535, 65548, 0x00ffd700, -1, false  --  Koopa kid (sprite has abnormal behavior)
	elseif sprite >= 0x22 and sprite <= 0x25 then return 1, 15, 3, 20, true, {16, 38}  -- net Koopas
	elseif sprite == 0x26 then return 0, 16, 3, 18, true  --  Thwomp
	elseif sprite == 0x2f then return 1, 15, 3, 15, false, {9}  --  Portable springboard EDITED
	elseif sprite == 0x3e then return 1, 15, 3, 17, false, {9}  --  P-switch
	elseif sprite == 0x4f then return 1, 15, 2, 17, true, {9}  -- Jumping Piranha Plant EDITED
	elseif sprite == 0x5b then return -1, 49, 1, 16, false, {-2}  --  Floating brown platform
	elseif sprite >= 0x74 and sprite <= 0x77 then return 2, 15, 3, 16, false  -- Powerups
	elseif sprite == 0x7b then return 5, 11, 13, 19, false  -- Goal tape
	elseif sprite == 0x80 then return 0, 15, 1, 24, false  -- Key
	elseif sprite >= 0x91 and sprite <= 0x98 then return -1, 16, -4, 12, false, {8, 16}  -- Chucks
	elseif sprite == 0xab then return 1, 15, -1, 16, true  -- Rex
	elseif sprite == 0xb9 then return 0, 15, 3, 16, false, {-2}  -- Info Box
	elseif sprite == 0xbb then return 0, 38, 3, 8, false, {-2}  --  Moving castle block (didn't test bottom hitbox)
	elseif sprite == 0xc4 then return -1, 72, 1, 9, false, {-2}  -- Gray platform that falls
	elseif sprite == 0xc7 then return 1, 15, 3, 16, true   -- Invisible mushroom
	elseif sprite >= 0xda and sprite <= 0xdd then return 1, 15, 3, 17, true  -- Koopas (stunned)
	
	else return 1, 15, 3, 16, true end  -- unknown hitbox EDITED 2
end

local function show_movie_info()
	local emu_frame = movie.currentframe() + 1
    local emu_maxframe = movie.framecount() + 1
	local emu_rerecord = movie.rerecords()
	local is_recording = not movie.readonly()
	local pos
	
	local movie_info = string.format("Movie %d/%d", emu_frame, emu_maxframe)
	draw_text("left", "top", text_color, background_color, movie_info)
	
	pos = string.len(movie_info)*lsnes_font_width
	local rr_info = string.format("|%d ", emu_rerecord)
	draw_text(pos, "top", rerecord_color, background_color, rr_info)
	
	if lsnes_version == "beta" then
		local lag_count = movie.lagcount() or ""  -- stable lsnes lacks this
		pos = pos + string.len(rr_info)*lsnes_font_width
		draw_text(pos, "top", lag_color, background_color, lag_count)
	end
	
	if is_recording then
		draw_text("right", "bottom", REC_color, REC_bg, "REC ")
	else
		local str = frame_time(movie.currentframe())
		draw_text("right", "bottom", text_color, background_color, str)
	end
	
	if is_lagged then
		gui.textHV(screen_width/2 - 3*lsnes_font_width, 2*lsnes_font_height, "Lag", lag_color, 0xa0000000)
	end
end

function show_misc_info()
	local color = change_transparency(text_color, 0.8)
	local color_bg = change_transparency(background_color, 0.5)
	local RNG = memory.readbyte(RAM.RNG)
	local main_info = string.format("Frame(%02X, %02X) RNG(%04X) Mode(%02X)",
									real_frame, effective_frame, RNG, game_mode)
	draw_text("right", "top", color, color_bg, main_info)
end

local function level()
	local sprite_memory_header = memory.readbyte(RAM.sprite_memory_header)
	local sprite_buoyancy = memory.readbyte(RAM.sprite_buoyancy)/0x40
	local color = change_transparency(text_color, 0.8)
	local color_bg = change_transparency(background_color, 0.4)
	
	if sprite_buoyancy == 0 then sprite_buoyancy = "" else
		sprite_buoyancy = string.format("%.2x", sprite_buoyancy)
		color_bg = 16*math.floor(background_color/16) + 0xa0a0ff  -- turns background into blue (FIX THIS)
	end
	
	local lm_level_number = level_index
	if level_index > 0x24 then lm_level_number = level_index + 0xdc end  -- converts the level number to the Lunar Magic number; should not be used outside here
	
	draw_text("right", lsnes_font_height, color, color_bg, "Level(%.2x, %.2x) %s", lm_level_number, sprite_memory_header, sprite_buoyancy)
end

-- displays player's hitbox
function player_hitbox(x, y, x_camera, y_camera)
	
	-- Reads RAM
	local powerup = memory.readbyte(RAM.powerup)
	local is_ducking = memory.readbyte(RAM.is_ducking)
	local yoshi_riding_flag = memory.readbyte(RAM.yoshi_riding_flag)
	
	local x_screen, y_screen = screen_coordinates(x, y, x_camera, y_camera)
	local yoshi_hitbox = nil
	local is_small = is_ducking ~= 0 or powerup == 0
	local on_yoshi =  yoshi_riding_flag ~= 0
	
	local x_points = {
		center = 0x8,
		left_side = 0x2 + 1,
		left_foot = 0x5,
		right_side = 0xe - 1,
		right_foot = 0xb
	}
	local y_points = {}
	
	if is_small and not on_yoshi then
		y_points = {
			head = 0x10,
			center = 0x18,
			shoulder = 0x16,
			side = 0x1a,
			foot = 0x20,
			sprite = 0x18
		}
	elseif not is_small and not on_yoshi then
		y_points = {
			head = 0x08,
			center = 0x12,
			shoulder = 0x0f,
			side = 0x1a,
			foot = 0x20,
			sprite = 0x0a
		}
	elseif is_small and on_yoshi then
		y_points = {
			head = 0x13,
			center = 0x1d,
			shoulder = 0x19,
			side = 0x28,
			foot = 0x30,
			sprite = 0x28,
			--sprite_up = 0x1c
		}
	else
		y_points = {
			head = 0x10,
			center = 0x1a,
			shoulder = 0x16,
			side = 0x28,
			foot = 0x30,
			sprite = 0x28,
			sprite_up = 0x14
		}
	end
	
	draw_box(x_screen + x_points.left_side, y_screen + y_points.head, x_screen + x_points.right_side, y_screen + y_points.foot, 2, interaction_bg, interaction_bg)  -- background for block interaction
	
	if show_player_hitbox then
		
		-- Collision with sprites
		local mario_color = (not on_yoshi and mario_color) or 0x40ff0000
		local mario_bg = (not on_yoshi and mario_bg) or mario_bg_mounted
		draw_box(x_screen + x_points.left_side, y_screen + y_points.sprite, x_screen + x_points.right_side, y_screen + y_points.foot, 2, mario_color, mario_bg)
		
		if y_points.sprite_up then
			draw_line(x_screen + x_points.left_side, y_screen + y_points.sprite_up, x_screen + x_points.right_side, y_screen + y_points.sprite_up, yoshi_color)
		end
		
	end
	
	-- interaction points (collision with blocks)
	if show_interaction_points then
		
		local color = interaction_color
		
		if not show_player_hitbox then
			draw_box(x_screen + x_points.left_side, y_screen + y_points.head, x_screen + x_points.right_side, y_screen + y_points.foot, 2, interaction_color_without_hitbox, -1) --color
		end
		
		draw_line(x_screen + x_points.left_side, y_screen + y_points.side, x_screen + x_points.left_foot, y_screen + y_points.side, color)  -- left side
		draw_line(x_screen + x_points.right_side, y_screen + y_points.side, x_screen + x_points.right_foot, y_screen + y_points.side, color)  -- right side
		draw_line(x_screen + x_points.left_foot, y_screen + y_points.foot - 2, x_screen + x_points.left_foot, y_screen + y_points.foot, color)  -- left foot bottom
		draw_line(x_screen + x_points.right_foot, y_screen + y_points.foot - 2, x_screen + x_points.right_foot, y_screen + y_points.foot, color)  -- right foot bottom
		draw_line(x_screen + x_points.left_side, y_screen + y_points.shoulder, x_screen + x_points.left_side + 2, y_screen + y_points.shoulder, color)  -- head left point
		draw_line(x_screen + x_points.right_side - 2, y_screen + y_points.shoulder, x_screen + x_points.right_side, y_screen + y_points.shoulder, color)  -- head right point
		draw_line(x_screen + x_points.center, y_screen + y_points.head, x_screen + x_points.center, y_screen + y_points.head + 2, color)  -- head point
		draw_line(x_screen + x_points.center - 1, y_screen + y_points.center, x_screen + x_points.center + 1, y_screen + y_points.center, color)  -- center point
		draw_line(x_screen + x_points.center, y_screen + y_points.center - 1, x_screen + x_points.center, y_screen + y_points.center + 1, color)  -- center point
	end
	
	return x_points, y_points
end

-- displays the hitbox of the cape while spinning
function cape_hitbox(x, y, x_camera, y_camera)
	local cape_interaction = memory.readbyte(RAM.cape_interaction)
	if cape_interaction == 0 then return end
	
	local cape_x = memory.readword(RAM.cape_x)
	local cape_y = memory.readword(RAM.cape_y)
	
	local cape_x_screen, cape_y_screen = screen_coordinates(cape_x, cape_y, x_camera, y_camera)
	local cape_left = -1
	local cape_right = 0x11
	local cape_up = 0x03
	local cape_down = 0x10
	local cape_middle = 0x08
	local block_interaction_cape = (x > cape_x and cape_left + 3) or cape_right - 3
	local active_frame = real_frame%2 == 1
	
	if active_frame then bg_color = cape_bg else bg_color = -1 end
	draw_box(cape_x_screen + cape_left, cape_y_screen + cape_up, cape_x_screen + cape_right, cape_y_screen + cape_down, 2, cape_color, bg_color)
	
	if active_frame then
		draw_pixel(cape_x_screen + block_interaction_cape, cape_y_screen + cape_middle, cape_block)
	end
end

local function player()
	-- Read RAM
	local x = memory.readsword(RAM.x)
	local y = memory.readsword(RAM.y)
	local previous_x = memory.readsword(RAM.previous_x)
	local previous_y = memory.readsword(RAM.previous_y)
	local x_sub = memory.readbyte(RAM.x_sub)
	local y_sub = memory.readbyte(RAM.y_sub)
	local x_speed = memory.readsbyte(RAM.x_speed)
	local x_subspeed = memory.readbyte(RAM.x_subspeed)
	local y_speed = memory.readsbyte(RAM.y_speed)
	local p_meter = memory.readbyte(RAM.p_meter)
	local take_off = memory.readbyte(RAM.take_off)
	local powerup = memory.readbyte(RAM.powerup)
	local direction = memory.readbyte(RAM.direction)
	local cape_spin = memory.readbyte(RAM.cape_spin)
	local cape_fall = memory.readbyte(RAM.cape_fall)
	local flight_animation = memory.readbyte(RAM.flight_animation)
	local diving_status = memory.readsbyte(RAM.diving_status)
	local player_in_air = memory.readbyte(RAM.player_in_air)
	local player_blocked_status = memory.readbyte(RAM.player_blocked_status)
	local player_item = memory.readbyte(RAM.player_item)
	local is_ducking = memory.readbyte(RAM.is_ducking)
	local on_ground = memory.readbyte(RAM.on_ground)
	local spinjump_flag = memory.readbyte(RAM.spinjump_flag)
	local can_jump_from_water = memory.readbyte(RAM.can_jump_from_water)
	local carrying_item = memory.readbyte(RAM.carrying_item)
	local yoshi_riding_flag = memory.readbyte(RAM.yoshi_riding_flag)
	local x_camera = memory.readsword(RAM.x_camera)
	local y_camera = memory.readsword(RAM.y_camera)
	
	-- Transformations
	if direction == 0 then direction = "<-" else direction = "->" end
	
	local spin_direction = (effective_frame)%8
	if spin_direction < 4 then
		spin_direction = spin_direction + 1
	else
		spin_direction = 3 - spin_direction
	end
	
	local is_caped = powerup == 0x2
	
	-- Blocked status
	local block_str = ""
	if player_blocked_status%2 == 1 then block_str = "R"..block_str end
	if bit.lrshift(player_blocked_status, 1)%2 == 1 then block_str = "L"..block_str end
	if bit.lrshift(player_blocked_status, 2)%2 == 1 then block_str = "D"..block_str end
	if bit.lrshift(player_blocked_status, 3)%2 == 1 then block_str = "U"..block_str end
	if bit.lrshift(player_blocked_status, 4)%2 == 1 then block_str = "M"..block_str end
	
	-- Display info
	local player_info = {
		string.format("Meter (%03d, %02d) %s %+d", p_meter, take_off, direction, spin_direction),
		string.format("Pos (%+d.%1x, %+d.%1x)", x, x_sub/16, y, y_sub/16),
		string.format("Speed (%+d(%d), %+d)", x_speed, x_subspeed/16, y_speed),
		(is_caped and string.format("Cape (%.2d, %.2d)/(%d, %d)", cape_spin, cape_fall, flight_animation, diving_status)) or "",
		-- string.format("Item (%1x)", carrying_item),
		string.format("Block: %s", block_str),
		string.format("Camera (%d, %d)", x_camera, y_camera)
	}
	draw_table(0, 4*lsnes_font_height, player_info)
	
	-- TEST: draw block
	draw_block(x_mouse, y_mouse, x_camera, y_camera)
	
	if x_mouse and y_mouse then select_sprite(x_mouse, y_mouse, x_camera, y_camera) end
	-- end of draw block
	
	if not (show_player_hitbox or show_interaction_points) then return end
	cape_hitbox(x, y, x_camera, y_camera)
	player_hitbox(x, y, x_camera, y_camera)
end

-- Returns the id of Yoshi; if more than one, the lowest sprite slot
local function get_yoshi_id()
    for i = 0, SMW.sprite_max - 1 do
        id = memory.readbyte(RAM.sprite_number + i)
        status = memory.readbyte(RAM.sprite_status + i)
        if id == 0x35 and status ~= 0 then return i end
    end
    
    return nil
end

-- displays sprite hitbox
function sprite_hitbox(id, x_sprite, y_sprite, x_camera, y_camera)
	-- reads RAM
	local yoshi_riding_flag = memory.readbyte(RAM.yoshi_riding_flag)
	local number = memory.readbyte(RAM.sprite_number + id)
	local stun = memory.readbyte(RAM.sprite_stun + id)
	local contact_mario = memory.readbyte(RAM.sprite_contact_mario + id)
	local x_offscreen = memory.readsbyte(RAM.sprite_x_offscreen + id)
	local y_offscreen = memory.readsbyte(RAM.sprite_y_offscreen + id)
	
	local x_screen, y_screen = screen_coordinates(x_sprite, y_sprite, x_camera, y_camera)
	local x_left, x_right, y_up, y_down, oscillation_flag, y_middle = hitbox(number, stun)
	
	
	-- calculates the correct color to use, according to id
	local info_color
	local color_background
	if number == 0x35 then
		info_color = yoshi_color
		color_background = yoshi_bg
	elseif number >= 0x74 and number <= 0x81 then
		info_color = sprites_color2[id%(#sprites_color2) + 1]
		color_background = sprites_bg2[id%(#sprites_bg2) + 1]
	else
		info_color = sprites_color1[id%(#sprites_color1) + 1]
		color_background = sprites_bg1[id%(#sprites_bg1) + 1]
	end
	
	
	if oscillation_flag and (real_frame - id)%2 == 1 then color_background = -1 end 	-- due to sprite oscillation every other frame
																					-- notice that some sprites interact with Mario every frame
	
	----<<<< Displays sprite's hitbox
	if not sprite_paint then
		sprite_paint = {}
		for key = 0, SMW.sprite_max - 1 do
			sprite_paint[tostring(key)] = "none"
		end
	end
	if show_sprite_hitbox and sprite_paint[tostring(id)] ~= "none" then
		if id ~= get_yoshi_id() or yoshi_riding_flag == 0 then
			draw_box(x_screen + x_left, y_screen + y_up, x_screen + x_right, y_screen + y_down, 2, info_color, color_background)
			if y_middle and sprite_status ~= 0x0b then
				for key, value in ipairs(y_middle) do
					draw_line(x_screen + x_left, y_screen + value, x_screen + x_right, y_screen + value, info_color)
				end
			end
		else
			draw_box(x_screen + x_left - 4, y_screen + y_up - 7, x_screen + x_right + 4, y_screen + y_down, 2, yoshi_color, yoshi_bg_mounted)
		end
	end
	---->>>>
	
	-- Draws a line for the goal tape
	if number == 0x7b then
		draw_line(x_screen + x_left, 0, x_screen + x_left, 448, info_color)
		draw_text(2*x_screen - 4, 224, info_color, color_bg, "Mario = %4d.0", x_sprite - 8)
	end
	
	-- Prints those informations next to the sprite
	if contact_mario == 0 then contact_mario = "" end
	
	if x_offscreen ~= 0 or y_offscreen ~= 0 or (id == get_yoshi_id() and yoshi_riding_flag ~= 0) then  -- more transparency if sprite is offscreen or it's Yoshi under Mario
		info_color = change_transparency(info_color, 0.7)
		color_bg = change_transparency(background_color, 0.2)
	else
		color_bg = background_color
	end
	
	draw_text(2*(x_screen + x_left + x_right - 16), 2*(y_screen + y_up - 10), info_color, color_bg, "#%02d %s", id, contact_mario)
	
	return info_color, color_background
end

local function sprites()
	local x_camera = memory.readsword(RAM.x_camera)
	local y_camera = memory.readsword(RAM.y_camera)
	local yoshi_riding_flag = memory.readbyte(RAM.yoshi_riding_flag)
	local counter = 0
	local table_position = 80
	
	for i = 0, SMW.sprite_max - 1 do
		local sprite_status = memory.readbyte(RAM.sprite_status + i)
		if sprite_status ~= 0 then
			local x = bit.lshift(memory.readbyte(RAM.sprite_x_high + i), 8) + memory.readbyte(RAM.sprite_x_low + i)
			local y = bit.lshift(memory.readbyte(RAM.sprite_y_high + i), 8) + memory.readbyte(RAM.sprite_y_low + i)
            local x_sub = memory.readbyte(RAM.sprite_x_sub + i)
            local y_sub = memory.readbyte(RAM.sprite_y_sub + i)
            local number = memory.readbyte(RAM.sprite_number + i)
            local stun = memory.readbyte(RAM.sprite_stun + i)
			local x_speed = memory.readsbyte(RAM.sprite_x_speed + i)
			local y_speed = memory.readsbyte(RAM.sprite_y_speed + i)
			--local throw = memory.readbyte(RAM.sprite_throw + i)
			--local contsprite = memory.readbyte(RAM.spriteContactSprite + i)  --AMARAT
			--local contobject = memory.readbyte(RAM.spriteContactoObject + i)  --AMARAT
			--local sprite_id = memory.readbyte(0x160e + i) --AMARAT
			
			local special = ""
			if show_all_sprite_info or ((sprite_status ~= 0x8 and sprite_status ~= 0x9 and sprite_status ~= 0xa and sprite_status ~= 0xb) or stun ~= 0) then
				special = string.format("(%d %d) ", sprite_status, stun)
			end
			
			if x >= 32768 then x = x - 65535 end  -- for when sprites go to the left of the screen
			if y >= 32768 then y = y - 65535 end  -- for when sprites go above the screen or way below the pit
			
			-- Prints those info in the sprite-table and display hitboxes
			local draw_str = string.format("#%02d %02x %s%d.%1x(%+.2d) %d.%1x(%+.2d)",
											i, number, special, x, x_sub/16, x_speed, y, y_sub/16, y_speed)
			
			local info_color = sprite_hitbox(i, x, y, x_camera, y_camera)
			draw_text("right", table_position + counter*lsnes_font_height, info_color, background_color, draw_str)
			
			
			counter = counter + 1
		end
	end
	draw_text("right", table_position - lsnes_font_height, 0x00a9a9a9, background_color, "spr:%.2d", counter)
end

local function yoshi()
	local yoshi_id = get_yoshi_id()
	if yoshi_id ~= nil then
		local eat_id = memory.readbyte(RAM.sprite_miscellaneous + yoshi_id)
		local eat_type = memory.readbyte(RAM.sprite_number + eat_id)
		local tongue_len = memory.readbyte(RAM.sprite_tongue_length + yoshi_id)
		local tongue_timer = memory.readbyte(RAM.sprite_tongue_timer + yoshi_id)
		local tongue_wait = memory.readbyte(RAM.sprite_tongue_wait)
		
		eat_type = eat_id == 0xff and "-" or eat_type
		eat_id = eat_id == 0xff and "-" or string.format("#%02d", eat_id)
		
		-- mixes tongue_wait with tongue_timer
		if tongue_timer == 0 and tongue_wait ~= 0 then
			tongue_timer = string.format("%02d", tongue_wait)
		elseif tongue_timer ~= 0 and tongue_wait == 0 then
			tongue_timer = string.format("%02d", tongue_timer)
		elseif tongue_timer ~= 0 and tongue_wait ~= 0 then
			tongue_timer = string.format("%02d, %02d", tongue_wait, tongue_timer)
		else
			tongue_timer = "00"
		end
		
		draw_text(0, 11*lsnes_font_height, text_color, background_color, "Yoshi (%0s, %0s, %02d, %s)", eat_id, eat_type, tongue_len, tongue_timer)
		
		-- more RAM values
		local yoshi_x = bit.lshift(memory.readbyte(RAM.sprite_x_high + yoshi_id), 8) + memory.readbyte(RAM.sprite_x_low + yoshi_id)
		local yoshi_y = bit.lshift(memory.readbyte(RAM.sprite_y_high + yoshi_id), 8) + memory.readbyte(RAM.sprite_y_low + yoshi_id)
		local x_camera = memory.readsword(RAM.x_camera)
		local y_camera = memory.readsword(RAM.y_camera)
		local mount_invisibility = memory.readbyte(RAM.sprite_miscellaneous2 + yoshi_id)
		
		local x_screen, y_screen = screen_coordinates(yoshi_x, yoshi_y, x_camera, y_camera)
		
		if mount_invisibility ~= 0 then
			draw_text(2*x_screen + 8, 2*y_screen - 32, yoshi_color, background_color, mount_invisibility)
		end
		
		-- tongue hitbox point
		if tongue_len ~= 0 then
			
			local yoshi_x = bit.lshift(memory.readbyte(RAM.sprite_x_high + yoshi_id), 8) + memory.readbyte(RAM.sprite_x_low + yoshi_id)
			local yoshi_y = bit.lshift(memory.readbyte(RAM.sprite_y_high + yoshi_id), 8) + memory.readbyte(RAM.sprite_y_low + yoshi_id)
			local x_camera = memory.readsword(RAM.x_camera)
			local y_camera = memory.readsword(RAM.y_camera)
			local on_ground = memory.readbyte(RAM.on_ground)
			local on_ground_delay = memory.readbyte(RAM.on_ground_delay)
			local yoshi_direction = memory.readbyte(RAM.sprite_direction + yoshi_id)
			local tongue_high = on_ground == 0 or on_ground_delay == 0  -- Yoshi will grab sprites (on floor) only if he stays more than 1 frame on the ground
			
			local x_inc = (yoshi_direction ~= 0 and -0x0f) or 0x1f
			if tongue_high then x_inc = x_inc - 0x05*(1 - 2*yoshi_direction) end
			local y_inc = (tongue_high and 0xe) or 0x19
			local x_screen, y_screen = screen_coordinates(yoshi_x, yoshi_y, x_camera, y_camera)
			local x_tongue, y_tongue = x_screen + x_inc + tongue_len*(1 - 2*yoshi_direction), y_screen + y_inc
			
			draw_box(x_tongue - 3, y_tongue - 3, x_tongue + 3, y_tongue + 3, 2, -1, background_color)
			draw_pixel(x_tongue, y_tongue, yoshi_color)
		end
		
	end
end

local function show_counters()
	local text_counter = 0
	
	local multicoin_block_timer = memory.readbyte(RAM.multicoin_block_timer)
	local gray_pow_timer = memory.readbyte(RAM.gray_pow_timer)
	local blue_pow_timer = memory.readbyte(RAM.blue_pow_timer)
	local dircoin_timer = memory.readbyte(RAM.dircoin_timer)
	local pballoon_timer = memory.readbyte(RAM.pballoon_timer)
	local star_timer = memory.readbyte(RAM.star_timer)
	local invisibility_timer = memory.readbyte(RAM.invisibility_timer)
	local animation_timer = memory.readbyte(RAM.animation_timer)
	local fireflower_timer = memory.readbyte(RAM.fireflower_timer)
	local yoshi_timer = memory.readbyte(RAM.yoshi_timer)
	local swallow_timer = memory.readbyte(RAM.swallow_timer)
	
	local p = function(label, value, default, mult, frame, color)
		if value == default then return end
		text_counter = text_counter + 1
		local color = color or text_color
		
		draw_text(0, 196 + (text_counter * lsnes_font_height), color, background_color, string.format("%s: %d", label, (value * mult) - frame))
	end
	
	p("Multi Coin", multicoin_block_timer, 0, 1, 0)
	p("Pow", gray_pow_timer, 0, 4, effective_frame % 4, 0x007e7e7e)
	p("Pow", blue_pow_timer, 0, 4, effective_frame % 4, 0x000000ff)
	p("Dir Coin", dircoin_timer, 0, 4, real_frame % 4, 0x00a52a2a)
	p("P-Balloon", pballoon_timer, 0, 4, real_frame % 4)
	p("Star", star_timer, 0, 4, (effective_frame - 3) % 4, 0x00ffff00)
	p("Invibility", invisibility_timer, 0, 1, 0)
	p("Fireflower", fireflower_timer, 0, 1, 0, 0x00ffa500)
	p("Yoshi", yoshi_timer, 0, 1, 0, yoshi_color)
	p("Swallow", swallow_timer, 0, 4, (effective_frame - 1) % 4, yoshi_color)
	
	if lock_animation_flag ~= 0 then p("Animation", animation_timer, 0, 1, 0) end  -- shows when player is getting small or dying
	
	local score_incrementing = memory.readbyte(RAM.score_incrementing)
	local end_level_timer = memory.readbyte(RAM.end_level_timer)
	
	p("End Level", end_level_timer, 0, 2, (real_frame - 1) % 2)
	p("Score Incrementing", score_incrementing, 0x50, 1, 0)
end

--#############################################################################
-- CHEATS (beta)

-- allows start + select + X to activate the normal exit
--        start + select + A to activate the secret exit 
--        start + select + B to exit the level without activating any exits
local on_exit_mode = false
local force_secret_exit = false
local function beat_level()
	if is_paused and joypad["select"] == 1 and (joypad["X"] == 1 or joypad["A"] == 1 or joypad["B"] == 1) then
		memory.writebyte(RAM.level_flag_table + level_index, bit.bor(level_flag, 0x80))
		
		force_secret_exit = joypad["A"] == 1
		if joypad["B"] == 0 then
			memory.writebyte(RAM.midway_point, 1)
		else
			memory.writebyte(RAM.midway_point, 0)
		end
		
		on_exit_mode = true
	end
end

local function activate_next_level()
	if not on_exit_mode then return end
	
	if memory.readbyte(RAM.level_exit_type) == 0x80 and memory.readbyte(RAM.midway_point) == 1 then
		if force_secret_exit then
			memory.writebyte(RAM.level_exit_type, 0x2)
		else
			memory.writebyte(RAM.level_exit_type, 1)
		end
		
		on_exit_mode = false
    end
end

--[[_set_score = false
local function set_score()
	if not _set_score then return end
	
	local desired_score = 3600 -- set score here WITH the last digit 0
	draw_text(24, 144, text_color, background_color, "Set score to %d", desired_score)
	print("Script edited score")
	
	desired_score = desired_score/10
	score0 = desired_score%0x100 -- low
	score1 = ((desired_score - score0)/0x100)%0x100
	score2 = (desired_score - score1*0x100 - score0)/0x100%0x1000000
	
	memory.writebyte(RAM.mario_score, score0)
	memory.writebyte(RAM.mario_score + 1, score1)
	memory.writebyte(RAM.mario_score + 2, score2)
	
	foo = false
end
]]

_force_pos = false
local function force_pos()
	if (joypad["L"] == 1 and joypad["R"] == 1 and joypad["up"] == 1) then _force_pos = true end
	if (joypad["L"] == 1 and joypad["R"] == 1 and joypad["down"] == 1) then _force_pos = false end
	if not _force_pos then return end
	
	local y_pos = nil  -- set y position here: erase 'nil' and put an integer value
<<<<<<< HEAD
=======
	_mult = _mult*(-1)
	--y_pos = y_pos + _mult
>>>>>>> parent of d3e4274... Automatically detects lsnes version
	if y_pos then
		memory.writeword(RAM.y, y_pos)
		memory.writebyte(RAM.y_sub, 0)
		memory.writebyte(RAM.y_speed, 0)
	end
end


--#############################################################################
-- MAIN --

function on_frame_emulated()
	is_lagged = is_game_lagged()
end

user_input = {}
function on_input()
	user_input = input.raw()
	
	if lsnes_version == "stable" then  -- on stable version, field 'value' is called 'last_rawval'
		for key, j in pairs(user_input) do
			user_input[key].value = user_input[key].last_rawval
		end
	end
	
	read_mouse()
	get_joypad()
	
	input.keyhook("mouse_right", true) -- calls on_keyhook when right-click changes
	input.keyhook("mouse_left", true) -- calls on_keyhook when left-click changes
	
	change_background_opacity()
	if allow_cheats then
		beat_level()
		activate_next_level()
		--set_score()
		force_pos()
	end
end

function on_keyhook(key, inner_table)
	if key == "mouse_right" then
		sprite_click()
	end
	
	if key == "mouse_left" then
		clear_block_drawing()
	end
end

function on_paint()
	screen_width, screen_height = gui.resolution()
	
	scan_smw()
	if game_mode == SMW.game_mode_level then  -- in level functions
		if show_sprite_info then sprites() end
		if show_level_info then level() end
		if show_player_info then player() end
		if show_yoshi_info then yoshi() end
		if show_counters_info then show_counters() end
	end
	
	if display_movie_info then show_movie_info() end
	if display_misc_info then show_misc_info() end
	if show_controller_input then display_input() end
end

gui.repaint()
