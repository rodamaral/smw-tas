outprefix = "simpleghost"..tostring(math.random(999999))
dumpfile = outprefix..".smwg"
nomovie = false
sucess = io.output(dumpfile)

if not bit then bit = require"bit" end

local SMW = {
	-- Game Modes
	game_mode_overworld = 0x0e,
	game_mode_level = 0x14,
	
}

local RAM = {
    -- General
    game_mode = 0x0100,
    real_frame = 0x0013,
    current_level = 0x00fe,  -- plus 1
    
    -- Cheats
    room_index = 0x00ce,
    
    -- Camera
    camera_x = 0x001a,
    camera_y = 0x001c,
    
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
    powerup = 0x0019,
    
    -- Yoshi
    yoshi_riding_flag = 0x187a,  -- #$00 = No, #$01 = Yes, #$02 = Yes, and turning around.
}

-- ************
-- COMPATIBILITY

memory.readsbyte = memory.readbytesigned
memory.readsword = memory.readwordsigned
local Prev_mode = nil  -- necessary, because only gui.register gets the correct RAM addresses without 1 frame delay

-- ************

local function get_game_mode()
	return memory.readbyte(RAM.game_mode)
end

local function player()
	-- Read RAM
	local x = memory.readsword(RAM.x)
	local y = memory.readsword(RAM.y)
	local x_speed = memory.readsbyte(RAM.x_speed)
	local x_sub = memory.readbyte(RAM.x_sub)
	local is_ducking = memory.readbyte(RAM.is_ducking)
	local powerup = memory.readbyte(RAM.powerup)
	local yoshi_riding_flag = memory.readbyte(RAM.yoshi_riding_flag)
	
	x_sub = math.floor(x_sub/0x10)
	
	-- Computes direction
	local direction
	if x_speed >= 0 then
		direction = 1
	else
		direction = 0
	end
	
	-- Computes hitbox size
	local is_small = is_ducking ~= 0 or powerup == 0
	local on_yoshi = yoshi_riding_flag ~= 0
	local hitbox_size
	if is_small and not on_yoshi then
		hitbox_size = 0
	elseif not is_small and not on_yoshi then
		hitbox_size = 1
	elseif is_small and on_yoshi then
		hitbox_size = 2
	else
		hitbox_size = 3
	end
	
	return x, x_sub, y, direction, hitbox_size
end

local function dump_info_level(room_index)
	local frame = emu.framecount() + 1
	local mode = get_game_mode()
	local real_frame = memory.readbyte(RAM.real_frame)
	if mode == SMW.game_mode_level then
		x, sub_x, y, direction, hitbox_size = player()
	else
		x, sub_x, y, direction, hitbox_size = 0, 0, 0, 0, 0
	end
	
	local is_lagged = real_frame == previous_real_frame
	if is_lagged then is_lagged = 1 else is_lagged = 0 end
	
	previous_real_frame = real_frame
	
    local sync = nil
    if mode == 0x14 and Prev_mode == 0x13 then sync = 0x13 end -- Prev_mode, due to delay
	local strline = string.format("%7d %2x %6x %1d %4d %x %4d %d %1d\n",
							frame, sync or mode, room_index, is_lagged, x, sub_x, y, direction, hitbox_size)
	io.write(strline)
    
    Prev_mode = mode
    return strline
end

emu.registerbefore(function()
	if not movie.playing() then gui.text(1, 16, "Put the movie in read-only mode")
	else
		local room_index = bit.lshift(memory.readbyte(RAM.room_index), 16) + bit.lshift(memory.readbyte(RAM.room_index + 1), 8) + memory.readbyte(RAM.room_index + 2)
		
		gui.text(1, 1, "RECORDING GHOST")
		dump_info_level(room_index)
	end
end)
