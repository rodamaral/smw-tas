--
--	Super Mario World (U) RAM adresses
--	Author: Rodrigo A. do Amaral (Amaraticando)
--  
--  Check this URL, for a complete list of RAM Adresses: http://www.smwcentral.net/?p=map&type=ram&sort=1&dir=0
--

print("Loaded RAM.lua")

RAM = {  --  Don't let RAM be local
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
	
    multicoin_block_timer = 0x186b, 
    gray_pow_timer = 0x14ae,
    blue_pow_timer = 0x14ad,
    dircoin_timer = 0x190c,
    pballoon_timer = 0x1891,
    star_timer = 0x1490,
    hurt_timer = 0x1497,
}
