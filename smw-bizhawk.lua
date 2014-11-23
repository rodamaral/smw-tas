---------------------------------------------------------------------------
--  Super Mario World (U) Utility Script for Lsnes - rr2 version
--  http://tasvideos.org/Lsnes.html
--  
--  Author: Rodrigo A. do Amaral (Amaraticando)
--  Git repository: https://github.com/rodamaral/smw-tas
---------------------------------------------------------------------------

--#############################################################################
-- CONFIG:

-- Colours (text)
local TEXT_COLOR = 0xffffffff
local OUTLINE_COLOR = 0xff000000
local WEAK_COLOR = 0xffa9a9a9
local WARNING_COLOR = 0xffff0000
local WARNING_BG = 0xff0000ff
local CAPE_COLOR = 0xffffd700

-- Font settings
local BIZHAWK_FONT_HEIGHT = 14
local BIZHAWK_FONT_WIDTH = 10

-- END OF CONFIG < < < < < < <
--#############################################################################
-- INITIAL STATEMENTS:

console.log("The hitbox of the objects can be viewed by using Pasky13's script at Lua\\SNES\\Super Mario World.lua")


--#############################################################################
-- GAME AND SNES SPECIFIC MACROS:

local SMW = {
	-- Game Modes
	game_mode_overworld = 0x0e,
	game_mode_level = 0x14,
	
	sprite_max = 12, -- maximum number of sprites
}

local WRAM = {
    game_mode = 0x0100,
    real_frame = 0x0013,
    effective_frame = 0x0014,
    timer_frame_counter = 0x0f30,
    RNG = 0x148d,
    current_level = 0x00fe,  -- plus 1
    sprite_memory_header = 0x1692,
    lock_animation_flag = 0x009d, -- Most codes will still run if this is set, but almost nothing will move or animate.
    level_mode_settings = 0x1925,
    
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
    sprite_4_tweaker = 0x167a,
    sprite_tongue_length = 0x151c,
    sprite_tongue_timer = 0x1558,
    sprite_tongue_wait = 0x14a3,
    sprite_yoshi_squatting = 0x18af,
    sprite_buoyancy = 0x190e,
    reznor_killed_flag = 0x151c,
    
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


--#############################################################################
-- SCRIPT UTILITIES:

-- Get screen values of the game and emulator areas
local Border_width, Border_height, Buffer_width, Buffer_height
local Screen_size, Screen_width, Screen_height, Pixel_rate_x, Pixel_rate_y
local Game_screen_x, Game_screen_y
local function bizhawk_screen_info()
    Border_width = client.borderwidth()  -- Borders area
    Border_height = client.borderheight()
    Buffer_width = client.bufferwidth()  -- Game area
    Buffer_height = client.bufferheight()
    
	Screen_size = client.getwindowsize()  -- Emulator area
	Screen_width = client.screenwidth()
	Screen_height = client.screenheight()
    
    Pixel_rate_x = Buffer_width/256
	Pixel_rate_y = Buffer_height/224
    
    Game_screen_x = client.transformPointX(0)
    Game_screen_y = client.transformPointY(0)
end

-- Gets info about screen resolution
local function get_screen_size()
	screen_size = client.getwindowsize()
	screen_width = client.screenwidth()
	screen_height = client.screenheight()
end

-- x can also be "left", "left-border", "middle", "right" and "right_border"
-- y can also be "top", "top-border", "middle", "bottom" and "bottom-border"
local function text_position(x, y, text, font)
    -- Calculates the correct FONT, FONT_HEIGHT and FONT_WIDTH
    local font_height = BIZHAWK_FONT_HEIGHT
    local font_width = BIZHAWK_FONT_WIDTH
    
    -- Calculates the actual text string
    local formatted_text
    if type(text) ~= "table" then
        formatted_text = text
    elseif not text[2] then
        formatted_text = text[1]
    else
        formatted_text = string.format(unpack(text))
    end
    
    local text_length = string.len(formatted_text)*font_width
    
    -- calculates suitable x
    if x == "left" then x = 0
    elseif x == "left-border" then x = -Border_width
    elseif x == "right" then x = Buffer_width - text_length
    elseif x == "right-border" then x = Buffer_width + Border_width - text_length
    elseif x == "middle" then x = (Buffer_width - text_length)/2
    end
    
    if x < -Border_width then x = -Border_width end
    local x_final = x + text_length
    if x_final > Buffer_width + Border_width then
        x = Buffer_width + Border_width - text_length
    end
    
    -- calculates suitable y
    if y == "top" then y = 0
    elseif y == "top-border" then y = -Border_height
    elseif y == "bottom" then y = Buffer_height - font_height
    elseif y == "bottom-border" then y = Buffer_height + Border_height - font_height
    elseif y == "middle" then y = (Buffer_height - font_height)/2
    end
    
    if y < -Border_height then y = -Border_height end
    local y_final = y + font_height
    if y_final > Buffer_height + Border_height then
        y = Buffer_height + Border_height - font_height
    end
    
    return x, y, formatted_text
end


-- Draws the text formatted in a given position within the screen space
-- the optional arguments [...] are outline color, text color and anchor
local function draw_text(x, y, text, ...)
    local x_pos, y_pos, formatted_text = text_position(x, y, text)
    x_pos = x_pos + Game_screen_x
    y_pos = y_pos + Game_screen_y
    
    gui.text(x_pos, y_pos, formatted_text, ...)
    
    return x_pos, y_pos
end

-- Checks whether 'data' is a tab le and then prints it in (x,y)
local function draw_table(x, y, data, ...)
    local data = ((type(data) == "table") and data) or {data}
	local index = 0
	
	for key, value in ipairs(data) do
		if value ~= '' then
			index = index + 1
			gui.text(x, y + (BIZHAWK_FONT_HEIGHT * index), value, ...)  -- edit font size
		end
	end
end

-- Displays frame count, lag, etc
function timer()
	local islagged = emu.islagged()
	local isloaded = movie.isloaded()
	
	if isloaded then
		local mode = movie.mode()
		if mode == "RECORD" then draw_text("right", "bottom", "(REC)", "black", "red") end  -- draws REC symbol while recording
	end
	
	islagged = (islagged and "Lag") or ""
	draw_text(124, 12, islagged, "black", "red")
end

-- SMW FUNCTIONS:

local function get_game_mode()
	return mainmemory.read_u8(WRAM.game_mode)
end

-- Converts the in-game (x, y) to SNES-screen coordinates
local function screen_coordinates(x, y)
	if get_game_mode() ~= SMW.game_mode_level then return end
	
	camera_x = mainmemory.read_u16_le(WRAM.camera_x)
	camera_y = mainmemory.read_u16_le(WRAM.camera_y)
	
	x_screen = (x - camera_x) + 8
	y_screen = (y - camera_y) + 15
	
	return x_screen, y_screen
end

-- Returns the in-game coordinates of the mouse
local function mouse_position(x_mouse, y_mouse)
	if get_game_mode() ~= SMW.game_mode_level then return 0,0 end
	
	camera_x = mainmemory.read_u16_le(WRAM.camera_x)
	camera_y = mainmemory.read_u16_le(WRAM.camera_y)
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

local function show_main_info()
	local game_mode = mainmemory.read_u8(WRAM.game_mode)
	local real_frame = mainmemory.read_u8(WRAM.real_frame)
	local effective_frame = mainmemory.read_u8(WRAM.effective_frame)
	local RNG = mainmemory.read_u8(WRAM.RNG)
	
	local main_info = string.format("Frame (%02X, %02X) : RNG (%04X) : Mode (%02X)",
										real_frame, effective_frame, RNG, game_mode)
	draw_text("right-border", "top-border", main_info, OUTLINE_COLOR, TEXT_COLOR)
	
	return
end

local function player()
    -- Reads WRAM
    local x = mainmemory.read_s16_le(WRAM.x)
    local y = mainmemory.read_s16_le(WRAM.y)
    local previous_x = mainmemory.read_s16_le(WRAM.previous_x)
    local previous_y = mainmemory.read_s16_le(WRAM.previous_y)
    local x_sub = mainmemory.read_u8(WRAM.x_sub)
    local y_sub = mainmemory.read_u8(WRAM.y_sub)
    local x_speed = mainmemory.read_s8(WRAM.x_speed)
    local x_subspeed = mainmemory.read_u8(WRAM.x_subspeed)
    local y_speed = mainmemory.read_s8(WRAM.y_speed)
    local p_meter = mainmemory.read_u8(WRAM.p_meter)
    local take_off = mainmemory.read_u8(WRAM.take_off)
    local powerup = mainmemory.read_u8(WRAM.powerup)
    local direction = mainmemory.read_u8(WRAM.direction)
    local cape_spin = mainmemory.read_u8(WRAM.cape_spin)
    local cape_fall = mainmemory.read_u8(WRAM.cape_fall)
    local flight_animation = mainmemory.read_u8(WRAM.flight_animation)
    local diving_status = mainmemory.read_s8(WRAM.diving_status)
    local player_in_air = mainmemory.read_u8(WRAM.player_in_air)
    local player_blocked_status = mainmemory.read_u8(WRAM.player_blocked_status)
    local player_item = mainmemory.read_u8(WRAM.player_item)
    local is_ducking = mainmemory.read_u8(WRAM.is_ducking)
    local on_ground = mainmemory.read_u8(WRAM.on_ground)
    local spinjump_flag = mainmemory.read_u8(WRAM.spinjump_flag)
    local can_jump_from_water = mainmemory.read_u8(WRAM.can_jump_from_water)
    local carrying_item = mainmemory.read_u8(WRAM.carrying_item)
    local yoshi_riding_flag = mainmemory.read_u8(WRAM.yoshi_riding_flag)
    
    -- Transformations
    if direction == 0 then direction = "<-" else direction = "->" end
    
    local Effective_frame = mainmemory.read_u8(WRAM.effective_frame) -- fix it
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
    local table_y = 0.32*Buffer_height--64
    draw_text(0, table_y + i*delta_y, {"Meter (%03d, %02d) %s", p_meter, take_off, direction},
    OUTLINE_COLOR, TEXT_COLOR)
    draw_text(18*delta_x, table_y + i*delta_y, {" %+d", spin_direction},
    (is_spinning and TEXT_COLOR) or OUTLINE_COLOR, WEAK_COLOR)
    i = i + 1
    
    draw_text(0, table_y + i*delta_y, {"Pos (%+d.%1x, %+d.%1x)", x, x_sub/16, y, y_sub/16},
    OUTLINE_COLOR, TEXT_COLOR)
    i = i + 1
    
    draw_text(0, table_y + i*delta_y, {"Speed (%+d(%d), %+d)", x_speed, x_subspeed/16, y_speed},
    OUTLINE_COLOR, TEXT_COLOR)
    i = i + 1
    
    if is_caped then
        draw_text(0, table_y + i*delta_y, {"Cape (%.2d, %.2d)/(%d, %d)", cape_spin, cape_fall, flight_animation, diving_status},
        CAPE_COLOR, BACKGROUND_COLOR, OUTLINE_COLOR)
        i = i + 1
    end
    
    local block_info_bg = was_boosted and WARNING_BG or OUTLINE_COLOR
    draw_text(0, table_y + i*delta_y,       "Block: ",   block_info_bg, TEXT_COLOR)
    draw_text(7*delta_x, table_y + i*delta_y, "RLDUM",   block_info_bg, WEAK_COLOR)
    draw_text(7*delta_x, table_y + i*delta_y, block_str, block_info_bg, WARNING_COLOR)
    i = i + 1
    
    draw_text(0, table_y + i*delta_y, {"Camera (%d, %d)", camera_x, camera_y}, OUTLINE_COLOR, TEXT_COLOR)
end

-- Returns the id of Yoshi; if more than one, the lowest sprite slot
local function get_yoshi_id()
    for i = 0, SMW.sprite_max - 1 do
        id = mainmemory.read_u8(WRAM.sprite_number + i)
        status = mainmemory.read_u8(WRAM.sprite_status + i)
        if id == 0x35 and status ~= 0 then return i end
    end
    
    return nil
end

local function sprites()
	if get_game_mode() ~= SMW.game_mode_level then return end
	
	local counter = 0
    local table_position = 0.18*Buffer_height
	
    for i = 0, SMW.sprite_max - 1 do
        local sprite_status = mainmemory.read_u8(WRAM.sprite_status + i) 
        if sprite_status ~= 0 then 
			local x = bit.lshift(mainmemory.read_s8(WRAM.sprite_x_high + i), 8) + mainmemory.read_u8(WRAM.sprite_x_low + i)
			local y = bit.lshift(mainmemory.read_s8(WRAM.sprite_y_high + i), 8) + mainmemory.read_u8(WRAM.sprite_y_low + i)
            local x_sub = mainmemory.read_u8(WRAM.sprite_x_sub + i)
            local y_sub = mainmemory.read_u8(WRAM.sprite_y_sub + i)
            local number = mainmemory.read_u8(WRAM.sprite_number + i)
            local stun = mainmemory.read_u8(WRAM.sprite_stun + i)
			local x_speed = mainmemory.read_s8(WRAM.sprite_x_speed + i)
			local y_speed = mainmemory.read_s8(WRAM.sprite_y_speed + i)
			-- local throw = mainmemory.read_u8(WRAM.sprite_throw + i)
			local contact_mario = mainmemory.read_u8(WRAM.sprite_contact_mario + i)
			--local contsprite = mainmemory.read_u8(WRAM.spriteContactSprite + i)  --AMARAT
			--local contobject = mainmemory.read_u8(WRAM.spriteContactoObject + i)  --AMARAT
			--local sprite_id = mainmemory.read_u8(0x160e + i) --AMARAT
			
			if stun ~= 0 then stun = ' '..tostring(stun)..' ' else stun = ' ' end
			
			-- Prints those info in the sprite-table
			local draw_str = string.format("#%02X %02X %02X%s%d.%1X(%+02d) %+03d.%1X(%+02d)",
											i, number, sprite_status, stun, x, x_sub/16, x_speed, y, y_sub/16, y_speed)
			;
			
			-- Prints those informations next to the sprite
			local x_screen, y_screen = screen_coordinates(x, y)
			if contact_mario == 0 then contact_mario = '' end
			draw_text(Pixel_rate_x*(x_screen - 8), Pixel_rate_y*(y_screen - 16), string.format("#%02X %s", i, contact_mario), "black", "white")
			
			-- Prints hitbox (Pasky13's script is better for now)
			--local x_left, x_right, y_up, y_down, color_line, color_background = hitbox(number, stun)
			--gui.drawBox(x_screen + x_left, y_screen + y_up, x_screen + x_right, y_screen + y_down, color_line, color_background)
			
            draw_text("right-border", table_position + counter*BIZHAWK_FONT_HEIGHT, draw_str) --test
            
			counter = counter + 1
        end
	end
	
end

local function yoshi()
	if get_game_mode() ~= SMW.game_mode_level then return end
	
	local yoshi_id = get_yoshi_id()
	if yoshi_id ~= nil then 
		local eat_id = mainmemory.read_u8(WRAM.sprite_miscellaneous + yoshi_id)
		local eat_type = mainmemory.read_u8(WRAM.sprite_number + eat_id)
		local tongue_len = mainmemory.read_u8(WRAM.sprite_tongue_length + yoshi_id)
		local tongue_timer = mainmemory.read_u8(WRAM.sprite_tongue_timer + yoshi_id)
		
		eat_type = eat_id == 0xff and "-" or eat_type
		eat_id = eat_id == 0xff and "-" or string.format("#%02x", eat_id)
		
		draw_text(1, "middle", {"Yoshi (%0s, %0s, %02X, %02X)", eat_id, eat_type, tongue_len, tongue_timer}, OUTLINE_COLOR, TEXT_COLOR)
	end
end

local function show_counters()
	if get_game_mode() ~= SMW.game_mode_level then return end
	
	local text_counter = 0
	
	local multicoin_block_timer = mainmemory.read_u8(WRAM.multicoin_block_timer)
	local gray_pow_timer = mainmemory.read_u8(WRAM.gray_pow_timer)
	local blue_pow_timer = mainmemory.read_u8(WRAM.blue_pow_timer)
	local dircoin_timer = mainmemory.read_u8(WRAM.dircoin_timer)
	local pballoon_timer = mainmemory.read_u8(WRAM.pballoon_timer)
	local star_timer = mainmemory.read_u8(WRAM.star_timer)
	local hurt_timer = mainmemory.read_u8(WRAM.invisibility_timer)
	local real_frame = mainmemory.read_u8(WRAM.real_frame)
	local effective_frame = mainmemory.read_u8(WRAM.effective_frame)
	
	local p = function(label, value, mult, frame, ...)
        if value == 0 then return end
        text_counter = text_counter + 1
        draw_text(1, 0.6*Buffer_height + (text_counter * BIZHAWK_FONT_HEIGHT), {"%s: %d", label, (value * mult) - frame}, "black", ...)
    end
    
    p("Multi Coin", multicoin_block_timer, 1, 0)
    p("Pow", gray_pow_timer, 4, effective_frame % 4, "gray")
    p("Pow", blue_pow_timer, 4, effective_frame % 4, "blue")
    p("Dir Coin", dircoin_timer, 4, real_frame % 4, "brown")
	p("P-Balloon", pballoon_timer, 4, real_frame % 4)
    p("Star", star_timer, 4, (effective_frame - 3) % 4, "yellow")
    p("Hurt", hurt_timer, 1, 0)
end

-------------------------------------------
-- MAIN --

while true do
    bizhawk_screen_info()
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
