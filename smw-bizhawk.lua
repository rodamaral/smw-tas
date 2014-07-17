--
--	Super Mario World (U) Utility Script for Bizhawk
--	http://tasvideos.org/Bizhawk.html
--	
--	Author: Rodrigo A. do Amaral (Amaraticando)
--

-- GAME SPECIFIC MACROS:

local SMW = {
	-- Game Modes
	game_mode_overworld = 0x0e,
	game_mode_level = 0x14,
	
	sprite_max = 12, -- maximum number of sprites
}

local RAM = {  --  Don't let RAM be local
    game_mode = 0x0100, --
    real_frame = 0x0013,
    effective_frame = 0x0014,
    RNG = 0x148d,
	
	-- cheats
	frozen = 0x13fb,
	paused = 0x13d4,
	level_index = 0x13bf,
	level_flag_table = 0x1ea2,
	typeOfExit = 0x0dd5,
	midwayPoint = 0x13ce,
	activateNextLevel = 0x13ce,
	
	-- Camera
    x_camera = 0x001a,
    y_camera = 0x001c,
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
    sprite_x_offscreen = 0x15a0, 
	sprite_y_offscreen = 0x186c,
	sprite_miscellaneous = 0x160e,
	sprite_tongue_length = 0x151c,
	sprite_tongue_timer = 0x1558,
	
	-- Player
    x = 0x0094,
    y = 0x0096,
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
	player_in_air = 0x0071,
	player_blocked_status = 0x0077, 
	player_item = 0x0dc2, --hex
	cape_x = 0x13e9,
	cape_y = 0x13eb,
	on_ground = 0x13ef,
	can_jump_from_water = 0x13fa,
	carrying_item = 0x148f,
	
	-- Yoshi
	yoshi_riding_flag = 0x187a,  -- #$00 = No, #$01 = Yes, #$02 = Yes, and turning around.
	
	
    multicoin_block_timer = 0x186b, 
    gray_pow_timer = 0x14ae,
    blue_pow_timer = 0x14ad,
    dircoin_timer = 0x190c,
    pballoon_timer = 0x1891,
    star_timer = 0x1490,
    hurt_timer = 0x1497,
}

-- SCRIPT UTILITIES:

-- Gets info about screen resolution
local function get_screen_size()
	screen_size = client.getwindowsize()
	screen_width = client.screenwidth()
	screen_height = client.screenheight()
end

-- Checks whether 'data' is a table and then prints it in (x,y)
local function draw_table(x, y, data, ...)
    local data = ((type(data) == "table") and data) or {data}
	local index = 0
	
	for key, value in ipairs(data) do
		if value ~= '' then
			index = index + 1
			gui.text(x, y + (13 * index), value, ...)  -- edit font size
		end
	end
end

-- Uses draw_table() onto adjusted SNES graphics
local function display(x, y, text, ...)
	rate_x = screen_width/256
	rate_y = screen_height/224
	draw_table(rate_x * x, rate_y * y, text, ...)
end

-- Displays frame count, lag, etc
function timer()
	local islagged = emu.islagged()
	local isloaded = movie.isloaded()
	
	if isloaded then
		local mode = movie.mode()
		if mode == "RECORD" then display(230, 208, "(REC)", "black", "red") end  -- draws REC symbol while recording
	end
	
	islagged = (islagged and "Lag") or ""
	display(124, 12, islagged, "black", "red")
end

-- SMW FUNCTIONS:

local function get_game_mode()
	return mainmemory.read_u8(RAM.game_mode)
end

-- Converts the in-game (x, y) to SNES-screen coordinates
local function screen_coordinates(x, y)
	if get_game_mode() ~= SMW.game_mode_level then return end
	
	x_camera = mainmemory.read_u16_le(RAM.x_camera)
	y_camera = mainmemory.read_u16_le(RAM.y_camera)
	
	x_screen = (x - x_camera) + 8
	y_screen = (y - y_camera) + 15
	
	return x_screen, y_screen
end

-- Returns the in-game coordinates of the mouse
local function mouse_position(x_mouse, y_mouse)
	if get_game_mode() ~= SMW.game_mode_level then return 0,0 end
	
	x_camera = mainmemory.read_u16_le(RAM.x_camera)
	y_camera = mainmemory.read_u16_le(RAM.y_camera)
	x_game = x_mouse + x_camera - 8
	y_game = y_mouse + y_camera - 15
	display(1, 210, string.format("Mouse in game %d %d", x_game, y_game))
	return x_game, y_game
end

-- Displays the SNES-screen and in-game coordinates of the mouse -- EDIT
local function mouse()
	mouse_table = input.getmouse()
	x_mouse = mouse_table.X
	y_mouse = mouse_table.Y
	text = string.format("Mouse(%d, %d)", x_mouse, y_mouse)
	x, y = mouse_position(x_mouse, y_mouse)
	--gui.drawRectangle(x, y, 15, 15, "red")
end

-- Returns the size of the object: x left, x right, y up, y down, color line, color background
local function hitbox(sprite, status)
	if sprite == 0x35 then return -5, 5, 3, 16, "white", 0x3000FF37
	elseif sprite >= 0xda and sprite <= 0xdd then return -7, 7, -13, 0, "red", 0x3000F2FF
	
	
	-- elseif sprite >= DA and sprite <= DD then return -7, 7, -13, 0, "red", 0x3000F2FF
	
	else return -7, 7, -13, 0, "orange", 0x3000F2FF end  -- unknown hitbox
end

local function show_main_info()
	local game_mode = mainmemory.read_u8(RAM.game_mode)
	local real_frame = mainmemory.read_u8(RAM.real_frame)
	local effective_frame = mainmemory.read_u8(RAM.effective_frame)
	local RNG = mainmemory.read_u8(RAM.RNG)
	
	local main_info = string.format("Frame (%02X, %02X) : RNG (%04X) : Mode (%02X)",
										real_frame, effective_frame, RNG, game_mode)
	display(48, -4, main_info)
	
	return
end

local function player()
	if get_game_mode() ~= SMW.game_mode_level then return end
	
	-- Read RAM
	local x = mainmemory.read_u16_le(RAM.x)
	local y = mainmemory.read_u16_le(RAM.y)
	local x_sub = mainmemory.read_u8(RAM.x_sub)
	local y_sub = mainmemory.read_u8(RAM.y_sub)
	local x_speed = mainmemory.read_s8(RAM.x_speed)
	local x_subspeed = mainmemory.read_s8(RAM.x_subspeed)
	local y_speed = mainmemory.read_s8(RAM.y_speed)
	local p_meter = mainmemory.read_u8(RAM.p_meter)
	local take_off = mainmemory.read_u8(RAM.take_off)
	local powerup = mainmemory.read_u8(RAM.powerup)
	local direction = mainmemory.read_u8(RAM.direction)
	local cape_spin = mainmemory.read_u8(RAM.cape_spin)
	local cape_fall = mainmemory.read_u8(RAM.cape_fall)
	local player_in_air = mainmemory.read_u8(RAM.player_in_air)
	local player_blocked_status = mainmemory.read_u8(RAM.player_blocked_status)
	local player_item = mainmemory.read_u8(RAM.player_item)
	local cape_x = mainmemory.read_u8(RAM.cape_x)
	local cape_y = mainmemory.read_u8(RAM.cape_y)
	local is_ducking = mainmemory.read_u8(RAM.is_ducking)
	local on_ground = mainmemory.read_u8(RAM.on_ground)
	local can_jump_from_water = mainmemory.read_u8(RAM.can_jump_from_water)
	local carrying_item = mainmemory.read_u8(RAM.carrying_item)
	local yoshi_riding_flag = mainmemory.read_u8(RAM.yoshi_riding_flag)
	
	-- Convert values
	if x_subspeed == 0 then x_subspeed = ""
	else x_subspeed = "*"
	end
	
	if direction == 0 then direction = "<="
	else direction = "=>"
	end
	
	if powerup == 0x2 then is_caped = true
	else is_caped = false
	end
	
	-- Blocked status
	local block_str = ''
	if player_blocked_status%2 == 1 then block_str = 'R'..block_str end
	if bit.rshift(player_blocked_status, 1)%2 == 1 then block_str = 'L'..block_str end
	if bit.rshift(player_blocked_status, 2)%2 == 1 then block_str = 'D'..block_str end
	if bit.rshift(player_blocked_status, 3)%2 == 1 then block_str = 'U'..block_str end
	if bit.rshift(player_blocked_status, 4)%2 == 1 then block_str = 'M'..block_str end
	
	-- Display info
	local player_info = {
		string.format("Meter (%03d, %02d) %s", p_meter, take_off, direction),
		string.format("Pos (%+d.%1X, %+d.%1X)", x, x_sub/16, y, y_sub/16),
		string.format("Speed (%+d%s, %+d)", x_speed, x_subspeed, y_speed),
		(is_caped and string.format("Cape (%02d, %01d)", cape_spin, cape_fall)) or "",
		"",
		-- string.format("Item (%1X)", carrying_item),
		string.format("Block: %s", block_str)
	}
	
	display(1, 64, player_info)
	display(1, 108, string.format("Camera (%d, %d)", x_camera, y_camera))
	
	-- draw hitbox
	local x_screen, y_screen = screen_coordinates(x, y)
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
	
	gui.drawBox(x_screen - mario_width, y_screen + mario_up, x_screen + mario_width, y_screen + mario_down, "white")   -- opacity = 0x77000000
end

-- Returns the id of Yoshi; if more than one, the lowest sprite slot
local function get_yoshi_id()
    for i = 0, SMW.sprite_max - 1 do
        id = mainmemory.read_u8(RAM.sprite_number + i)
        status = mainmemory.read_u8(RAM.sprite_status + i)
        if id == 0x35 and status ~= 0 then return i end
    end
    
    return nil
end

local function sprites()
	if get_game_mode() ~= SMW.game_mode_level then return end
	
	local counter = 0 
	sprite_table = {}
	
    for i = 0, SMW.sprite_max - 1 do 
        local sprite_status = mainmemory.read_u8(RAM.sprite_status + i) 
        if sprite_status ~= 0 then 
			local x = bit.lshift(mainmemory.read_s8(RAM.sprite_x_high + i), 8) + mainmemory.read_u8(RAM.sprite_x_low + i)
			local y = bit.lshift(mainmemory.read_s8(RAM.sprite_y_high + i), 8) + mainmemory.read_u8(RAM.sprite_y_low + i)
            local x_sub = mainmemory.read_u8(RAM.sprite_x_sub + i)
            local y_sub = mainmemory.read_u8(RAM.sprite_y_sub + i)
            local number = mainmemory.read_u8(RAM.sprite_number + i)
            local stun = mainmemory.read_u8(RAM.sprite_stun + i)
			local x_speed = mainmemory.read_s8(RAM.sprite_x_speed + i)
			local y_speed = mainmemory.read_s8(RAM.sprite_y_speed + i)
			-- local throw = mainmemory.read_u8(RAM.sprite_throw + i)
			local contact_mario = mainmemory.read_u8(RAM.sprite_contact_mario + i)
			--local contsprite = mainmemory.read_u8(RAM.spriteContactSprite + i)  --AMARAT
			--local contobject = mainmemory.read_u8(RAM.spriteContactoObject + i)  --AMARAT
			--local sprite_id = mainmemory.read_u8(0x160e + i) --AMARAT
			
			if stun ~= 0 then stun = ' '..tostring(stun)..' ' else stun = ' ' end
			
			-- Prints those info in the sprite-table
			local draw_str = string.format("#%02X %02X %02X%s%d.%1X(%+02d) %+03d.%1X(%+02d)",
											i, number, sprite_status, stun, x, x_sub/16, x_speed, y, y_sub/16, y_speed)
			
			table.insert(sprite_table, i+1, draw_str)
			
			-- Prints those informations next to the sprite
			local x_screen, y_screen = screen_coordinates(x, y)
			if contact_mario == 0 then contact_mario = '' end
			display(x_screen - 8, y_screen - 16, string.format("#%02X %s", i, contact_mario), "black", "white")
			
			-- Prints hitbox
			local x_left, x_right, y_up, y_down, color_line, color_background = hitbox(number, stun)
			gui.drawBox(x_screen + x_left, y_screen + y_up, x_screen + x_right, y_screen + y_down, color_line, color_background)
			
			counter = counter + 1
		else
			table.insert(sprite_table, i+1, '')  -- instead of nil, inserts null string
        end
	end
	
	draw_table(screen_width - 336, screen_height - 400, sprite_table, "black", "white")
end

local function yoshi()
	if get_game_mode() ~= SMW.game_mode_level then return end
	
	local yoshi_id = get_yoshi_id()
	if yoshi_id ~= nil then 
		local eat_id = mainmemory.read_u8(RAM.sprite_miscellaneous + yoshi_id)
		local eat_type = mainmemory.read_u8(RAM.sprite_number + eat_id)
		local tongue_len = mainmemory.read_u8(RAM.sprite_tongue_length + yoshi_id)
		local tongue_timer = mainmemory.read_u8(RAM.sprite_tongue_timer + yoshi_id)
		
		eat_type = eat_id == 0xff and "-" or eat_type
		eat_id = eat_id == 0xff and "-" or string.format("#%02x", eat_id)
		
		display(1, 120, string.format("Yoshi (%0s, %0s, %02X, %02X)", eat_id, eat_type, tongue_len, tongue_timer))
	end
end

local function show_counters()
	if get_game_mode() ~= SMW.game_mode_level then return end
	
	local text_counter = 0
	
	local multicoin_block_timer = mainmemory.read_u8(RAM.multicoin_block_timer)
	local gray_pow_timer = mainmemory.read_u8(RAM.gray_pow_timer)
	local blue_pow_timer = mainmemory.read_u8(RAM.blue_pow_timer)
	local dircoin_timer = mainmemory.read_u8(RAM.dircoin_timer)
	local pballoon_timer = mainmemory.read_u8(RAM.pballoon_timer)
	local star_timer = mainmemory.read_u8(RAM.star_timer)
	local hurt_timer = mainmemory.read_u8(RAM.hurt_timer)
	local real_frame = mainmemory.read_u8(RAM.real_frame)
	local effective_frame = mainmemory.read_u8(RAM.effective_frame)
	
	local p = function(label, value, mult, frame, ...)
        if value == 0 then return end
        text_counter = text_counter + 1
        display(0, 132 + (text_counter * 12), string.format("%s: %d", label, (value * mult) - frame), "black", ...)
    end
    
    p("Multi Coin", multicoin_block_timer, 1, 0)
    p("Gray Pow", gray_pow_timer, 4, effective_frame % 4, "gray")
    p("Blue Pow", blue_pow_timer, 4, effective_frame % 4, "blue")
    p("Dir Coin", dircoin_timer, 4, real_frame % 4, "brown")
	p("P-Balloon", pballoon_timer, 4, real_frame % 4)
    p("Star", star_timer, 4, (effective_frame - 3) % 4, "yellow")
    p("Hurt", hurt_timer, 1, 0)
end

-------------------------------------------
-- MAIN --

print("Go to Config > Display and uncheck \"Mantain aspect ratio\". Otherwise, the script may not display the text in the correct places.")

while true do
	get_screen_size()
	timer()
	show_main_info()
	mouse()
	player()
	sprites()
	yoshi()
	show_counters()
	emu.frameadvance()
end
