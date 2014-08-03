--
--	Super Mario World (U) Utility Script for Lsnes
--	http://tasvideos.org/Lsnes.html
--	
--	Author: Rodrigo A. do Amaral (Amaraticando)
--

--#############################################################################
-- CONFIG:
-- Cheats
local allow_cheats = true -- better turn off while recording a TAS

-- Height and width of the font characters
local lsnes_font_height = 16
local lsnes_font_width = 8 

-- Colours
local text_color = "white"
local background_color = 0xa0000000

--#############################################################################
-- GAME SPECIFIC MACROS:

local SMW = {
	-- Game Modes
	game_mode_overworld = 0x0e,
	game_mode_level = 0x14,
	
	sprite_max = 12, -- maximum number of sprites
}

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
    sprite_x_offscreen = 0x7e15a0, 
	sprite_y_offscreen = 0x7e186c,
	sprite_miscellaneous = 0x7e160e,
	sprite_tongue_length = 0x7e151c,
	sprite_tongue_timer = 0x7e1558,
	sprite_buoyancy = 0x7e190e,
	
	-- Player
    x = 0x7e0094,
    y = 0x7e0096,
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
}

--#############################################################################
-- SCRIPT UTILITIES:
-- Variables used in various functions
local previous_lag_count = 0
local is_lagged = false

local function text_format(x, y, text_color, bg_color, text, ...) -- EDIT!!!
	gui.text(x, y, string.format(text, ...), text_color, bg_color)
end

local function textf(x, y, text, ...)
	gui.text(x, y, string.format(text, ...), text_color, background_color)
end

-- Checks whether 'data' is a tab le and then prints it in (x,y)
local function draw_table(x, y, data, ...)
    local data = ((type(data) == "table") and data) or {data}
	local index = 0
	
	for key, value in ipairs(data) do
		if value ~= "" and value ~= nil then
			index = index + 1
			text_format(x, y + (lsnes_font_height * index), text_color, background_color, value, ...)
		end
	end
end

-- Works like Bizhawk's function: draws a box given (x,y) and (x',y') with SNES' pixel sizes
local function draw_box(x1, y1, x2, y2, ...)
	x = 2*x1
	y = 2*y1
	w = 2 * (x2 - x1) + 2  -- adds thickness
	h = 2 * (y2 - y1) + 2  -- adds thickness
	gui.rectangle(x, y, w, h, ...)
end

-- Uses the mouse click to change the opacity of the gui functions
-- Left click = more transparency
-- Right click = less transparency
local function change_background_opacity()
	if not user_input then return end
	
	local mouse_left = user_input.mouse_left.value
	local mouse_right = user_input.mouse_right.value
	
	if mouse_left  == 1 and background_color < 0xf8000000 then background_color = background_color + 0x08000000 end
	if mouse_right == 1 and background_color > 0x08000000 then background_color = background_color - 0x08000000 end
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
	local input = ""
	
	if joypad["left"] == 1 then input = input.."<" else input = input.." " end
	if joypad["up"] == 1 then input = input.."^" else input = input.." " end
	if joypad["right"] == 1 then input = input..">" else input = input.." " end
	if joypad["down"] == 1 then input = input.."v" else input = input.." " end
	input = input.." "
	if joypad["A"] == 1 then input = input.."A" else input = input.." " end
	if joypad["B"] == 1 then input = input.."B" else input = input.." " end
	if joypad["Y"] == 1 then input = input.."Y" else input = input.." " end
	if joypad["X"] == 1 then input = input.."X" else input = input.." " end
	input = input.." "
	if joypad["L"] == 1 then input = input.."L" else input = input.." " end
	if joypad["R"] == 1 then input = input.."R" else input = input.." " end
	input = input.." "
	if joypad["start"] == 1 then input = input.."S" else input = input.." " end
	if joypad["select"] == 1 then input = input.."s" else input = input.." " end
	
	local length = lsnes_font_width * string.len(input)
	textf((screen_width - length)/2, screen_height-lsnes_font_height, input)
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

-- Converts the in-game (x, y) to SNES-screen coordinates
local function screen_coordinates(x, y, x_camera, y_camera)
	x_screen = (x - x_camera) + 8
	y_screen = (y - y_camera) + 15
	
	return x_screen, y_screen
end

-- Returns the size of the object: x left, x right, y up, y down, color line, color background
local function hitbox(sprite, status)
	if sprite == 0x35 then return -5, 5, 3, 16, "red", 0xc800ff00
	elseif sprite == 0x7b then return -3, 3, -3, 3, "blue", 0xa00000ff
	elseif sprite >= 0xda and sprite <= 0xdd then return -7, 7, -13, 0, "red", 0x3000F2FF
	
	
	-- elseif sprite >= DA and sprite <= DD then return -7, 7, -13, 0, "red", 0x3000F2FF
	
	else return -7, 7, -13, 0, "orange", 0xa0ff0000 end  -- unknown hitbox
end

local function show_main_info()
	local emu_frame = movie.currentframe() + 1
    local emu_maxframe = movie.framecount() + 1
	local emu_rerecord = movie.rerecords()
	local is_recording = not movie.readonly()
	local lag_count = movie.lagcount()
	
	local RNG = memory.readbyte(RAM.RNG)
	
	local main_info = string.format("Movie %d/%d|%d %s - Frame(%02X, %02X) RNG(%04X) Mode(%02X)",
									emu_frame, emu_maxframe, emu_rerecord, lag_count, real_frame, effective_frame, RNG, game_mode)
	text_format(0, 0, text_color, background_color, main_info)
	
	if is_recording then
		gui.text(screen_width - 32, screen_height - 24, "REC", "red", 0xa0000000)
	end
	
	if is_lagged then
		gui.textHV(screen_width/2 - 3*lsnes_font_width, 2*lsnes_font_height, "Lag", "red", 0xa0000000)
	end
end

local function level()
	local sprite_memory_header = memory.readbyte(RAM.sprite_memory_header)
	local sprite_buoyancy = memory.readbyte(RAM.sprite_buoyancy)/0x40
	local bg_color = background_color
	
	if sprite_buoyancy == 0 then sprite_buoyancy = "" else
		sprite_buoyancy = string.format("%.2x", sprite_buoyancy)
		bg_color = background_color + 0xff  -- turns background into blue
	end
	
	local lm_level_number = level_index
	if level_index > 0x24 then lm_level_number = level_index + 0xdc end  -- converts the level number to the Lunar Magic number; should not be used outside here
	
	text_format(0, lsnes_font_height, text_color, bg_color, "Level(%.2x, %.2x) %s", lm_level_number, sprite_memory_header, sprite_buoyancy)
end

local function player()
	-- Read RAM
	local x = memory.readsword(RAM.x)
	local y = memory.readsword(RAM.y)
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
	local x_camera = memory.readword(RAM.x_camera)
	local y_camera = memory.readword(RAM.y_camera)
	local cape_x = memory.readword(RAM.cape_x)
	local cape_y = memory.readword(RAM.cape_y)
	
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
	
	-- draw hitbox
	local x_screen, y_screen = screen_coordinates(x, y, x_camera, y_camera)
	local mario_width = 5
	local mario_up, mario_down
	local is_small = is_ducking ~= 0 or powerup == 0
	local on_yoshi =  yoshi_riding_flag ~= 0
	
	if is_small and not on_yoshi then
		mario_up = 0
		mario_down = 16
	elseif not is_small and not on_yoshi then
		mario_up = -8
		mario_down = 16
	elseif is_small and on_yoshi then
		mario_up = 3
		mario_down = 32
	else
		mario_up = 0
		mario_down = 32
	end
	
	if cape_spin ~= 0 or (is_caped and spinjump_flag ~= 0) then
		local cape_x_screen = screen_coordinates(cape_x, y, x_camera, y_camera)
		local cape_width = 9
		draw_box(cape_x_screen - cape_width, y_screen + mario_up, cape_x_screen + cape_width, y_screen + mario_down, 1, "white", 0xa0ffff00)
	end
	
	draw_box(x_screen - mario_width, y_screen + mario_up, x_screen + mario_width, y_screen + mario_down, 1, "white")
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

local function sprites()
	local x_camera = memory.readword(RAM.x_camera)
	local y_camera = memory.readword(RAM.y_camera)
	local counter = 0
	local x_pos = 0  -- where the table will be displayed
	sprite_table = {}
	
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
			-- local throw = memory.readbyte(RAM.sprite_throw + i)
			local contact_mario = memory.readbyte(RAM.sprite_contact_mario + i)
			--local contsprite = memory.readbyte(RAM.spriteContactSprite + i)  --AMARAT
			--local contobject = memory.readbyte(RAM.spriteContactoObject + i)  --AMARAT
			--local sprite_id = memory.readbyte(0x160e + i) --AMARAT
			
			local special = ""
			if sprite_status ~= 0x8 or stun ~= 0 then
				special = string.format("(%d %d) ", sprite_status, stun)
			end
			
			if x >= 32768 then x = x - 65535 end  -- for when sprites go to the left of the screen
			if y >= 32768 then y = y - 65535 end  -- for when sprites go above the screen or way below the pit
			
			-- Prints those info in the sprite-table
			local draw_str = string.format("#%02x %02x %s%4d.%1x(%+.2d) %3d.%1x(%+.2d)",
											i, number, special, x, x_sub/16, x_speed, y, y_sub/16, y_speed)
			
			table.insert(sprite_table, i+1, draw_str)
			
			if string.len(draw_str) > x_pos then x_pos = string.len(draw_str) end
			
			-- Prints those informations next to the sprite
			local x_screen, y_screen = screen_coordinates(x, y, x_camera, y_camera)
			if contact_mario == 0 then contact_mario = "" end
			textf(2*x_screen - 16, 2*y_screen - 48, "#%02x %s", i, contact_mario)
			
			-- Prints hitbox
			local x_left, x_right, y_up, y_down, color_line, color_background = hitbox(number, stun)
			if (real_frame - i)%2 == 1 and number ~= 0x35 then color_background = -1 end 	-- due to sprite oscillation every other frame
																							-- notice that some sprites interact with Mario every frame
			local yoshi_riding_flag = memory.readbyte(RAM.yoshi_riding_flag)
			if i ~= get_yoshi_id() or yoshi_riding_flag == 0 then
				draw_box(x_screen + x_left, y_screen + y_up, x_screen + x_right, y_screen + y_down, 1, color_line, color_background)
			end
			
			-- Draws a line for the goal tape
			if number == 0x7b then
				gui.line(2*(x_screen + x_left), 0, 2*(x_screen + x_left), 448, "red")
				text_format(2*x_screen - 4, 224, text_color, background_color, "Mario = %4d.%1x", x-8, x_sub/16)
			end
			
			counter = counter + 1
		else
			table.insert(sprite_table, i+1, "")  -- instead of nil, inserts null string
        end
	end
	
	draw_table(screen_width - x_pos*lsnes_font_width, 60, sprite_table, "black", "white")
end

local function yoshi()
	local yoshi_id = get_yoshi_id()
	if yoshi_id ~= nil then
		local eat_id = memory.readbyte(RAM.sprite_miscellaneous + yoshi_id)
		local eat_type = memory.readbyte(RAM.sprite_number + eat_id)
		local tongue_len = memory.readbyte(RAM.sprite_tongue_length + yoshi_id)
		local tongue_timer = memory.readbyte(RAM.sprite_tongue_timer + yoshi_id)
		
		eat_type = eat_id == 0xff and "-" or eat_type
		eat_id = eat_id == 0xff and "-" or string.format("#%02x", eat_id)
		
		textf(0, 11*lsnes_font_height, string.format("Yoshi (%0s, %0s, %02x, %02x)", eat_id, eat_type, tongue_len, tongue_timer))
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
	
	local p = function(label, value, default, mult, frame, color)
		if value == default then return end
		text_counter = text_counter + 1
		local color = color or text_color
		
		text_format(0, 196 + (text_counter * lsnes_font_height), color, background_color, string.format("%s: %d", label, (value * mult) - frame))
	end
	
	p("Multi Coin", multicoin_block_timer, 0, 1, 0)
	p("Pow", gray_pow_timer, 0, 4, effective_frame % 4, "gray")
	p("Pow", blue_pow_timer, 0, 4, effective_frame % 4, "blue")
	p("Dir Coin", dircoin_timer, 0, 4, real_frame % 4, "brown")
	p("P-Balloon", pballoon_timer, 0, 4, real_frame % 4)
	p("Star", star_timer, 0, 4, (effective_frame - 3) % 4, "yellow")
	p("Invibility", invisibility_timer, 0, 1, 0)
	p("Fireflower", fireflower_timer, 0, 1, 0, 0x00ffa500)
	p("Yoshi", yoshi_timer, 0, 1, 0, 0x0000ff00)
	
	if lock_animation_flag ~= 0 then p("Animation", animation_timer, 0, 1, 0) end  -- shows when player is getting small
	
	local score_incrementing = memory.readbyte(RAM.score_incrementing)
	local end_level_timer = memory.readbyte(RAM.end_level_timer)
	
	p("End Level", end_level_timer, 0, 1, 0)
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
	textf(24, 144, "Set score to %d", desired_score)
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

_force_pos = false
local function force_pos()
	if joypad["L"] == 1 and joypad["R"] == 1 and joypad["up"] then _force_pos = true end
	if joypad["L"] == 1 and joypad["R"] == 1 and joypad["down"] then _force_pos = false end
	if not _force_pos then return end
	
	y_pos = 440
	memory.writeword(RAM.y, y_pos)
	memory.writebyte(RAM.y_sub, 0)
	memory.writebyte(RAM.y_speed, 0)
end
]]

--#############################################################################
-- MAIN --

is_lagged = nil
function on_frame_emulated()
	is_lagged = memory.get_lag_flag()
end

function on_input()
	user_input = input.raw()
	get_joypad()
	change_background_opacity()
	
	if allow_cheats then
		beat_level()
		activate_next_level()
		--set_score()
		--force_pos()
	end
end

function on_paint()
	screen_width, screen_height = gui.resolution()
	
	scan_smw()
	show_main_info()
	display_input()
	
	if game_mode == SMW.game_mode_level then
		level()
		player()
		sprites()
		yoshi()
		show_counters()
	end
end

gui.repaint()
