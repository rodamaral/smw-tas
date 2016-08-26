local smw = {}

local luap = require "luap"
local config = require "config"
local COLOUR = config.COLOUR

smw.constant = {
  -- Game Modes
  game_mode_overworld = 0x0e,
  game_mode_level = 0x14,

  -- Sprites
  sprite_max = 12,
  extended_sprite_max = 10,
  cluster_sprite_max = 20,
  minor_extended_sprite_max = 12,
  bounce_sprite_max = 4,
  null_sprite_id = 0xff,

  -- Blocks
  blank_tile_map16 = 0x25,
}

smw.WRAM = {
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
  camera_x = 0x1462,
  camera_y = 0x1464,
  screens_number = 0x005d,
  hscreen_number = 0x005e,
  vscreen_number = 0x005f,
  vertical_scroll_flag_header = 0x1412,  -- #$00 = Disable; #$01 = Enable; #$02 = Enable if flying/climbing/etc.
  vertical_scroll_enabled = 0x13f1,
  camera_scroll_timer = 0x1401,

  -- Sprites
  sprite_status = 0x14c8,
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
  sprite_miscellaneous1 = 0x00c2,
  sprite_miscellaneous2 = 0x1504,
  sprite_miscellaneous3 = 0x1510,
  sprite_miscellaneous4 = 0x151c,
  sprite_miscellaneous5 = 0x1528,
  sprite_miscellaneous6 = 0x1534,
  sprite_miscellaneous7 = 0x1540,
  sprite_miscellaneous8 = 0x154c,
  sprite_miscellaneous9 = 0x1558,
  sprite_miscellaneous10 = 0x1564,
  sprite_miscellaneous11 = 0x1570,
  sprite_miscellaneous12 = 0x157c,
  sprite_miscellaneous13 = 0x1594,
  sprite_miscellaneous14 = 0x15ac,
  sprite_miscellaneous15 = 0x1602,
  sprite_miscellaneous16 = 0x160e,
  sprite_miscellaneous17 = 0x1626,
  sprite_miscellaneous18 = 0x163e,
  sprite_miscellaneous19 = 0x187b,
  sprite_underwater = 0x164a,
  sprite_disable_cape = 0x1fe2,
  sprite_1_tweaker = 0x1656,
  sprite_2_tweaker = 0x1662,
  sprite_3_tweaker = 0x166e,
  sprite_4_tweaker = 0x167a,
  sprite_5_tweaker = 0x1686,
  sprite_6_tweaker = 0x190f,
  sprite_tongue_wait = 0x14a3,
  sprite_yoshi_squatting = 0x18af,
  sprite_buoyancy = 0x190e,

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

  -- Cluster sprites
  cluspr_flag = 0x18b8,
  cluspr_number = 0x1892,
  cluspr_x_high = 0x1e3e,
  cluspr_x_low = 0x1e16,
  cluspr_y_high = 0x1e2a,
  cluspr_y_low = 0x1e02,
  cluspr_timer = 0x0f9a,
  cluspr_table_1 = 0x0f4a,
  cluspr_table_2 = 0x0f72,
  cluspr_table_3 = 0x0f86,
  reappearing_boo_counter = 0x190a,

  -- Minor extended sprites
  minorspr_number = 0x17f0,
  minorspr_x_high = 0x18ea,
  minorspr_x_low = 0x1808,
  minorspr_y_high = 0x1814,
  minorspr_y_low = 0x17fc,
  minorspr_xspeed = 0x182c,
  minorspr_yspeed = 0x1820,
  minorspr_x_sub = 0x1844,
  minorspr_y_sub = 0x1838,
  minorspr_timer = 0x1850,

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
  player_animation_trigger = 0x0071,
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
  player_pose_turning = 0x1499,
  mario_score = 0x0f34,
  player_coin = 0x0dbf,
  player_looking_up = 0x13de,

  -- Yoshi
  yoshi_riding_flag = 0x187a,  -- #$00 = No, #$01 = Yes, #$02 = Yes, and turning around.
  yoshi_tile_pos = 0x0d8c,

  -- Timer
  --keep_mode_active = 0x0db1,
  pipe_entrance_timer = 0x0088,
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
  spinjump_fireball_timer = 0x13e2,

  -- Layers
  layer2_x_nextframe = 0x1466,
  layer2_y_nextframe = 0x1468,
}

smw.DEBUG_REGISTER_ADDRESSES = {
  {"BUS", 0x004016, "JOYSER0"},
  {"BUS", 0x004017, "JOYSER1"},
  {"BUS", 0x004218, "Hardware Controller1 Low"},
  {"BUS", 0x004219, "Hardware Controller1 High"},
  {"BUS", 0x00421a, "Hardware Controller2 Low"},
  {"BUS", 0x00421b, "Hardware Controller2 High"},
  {"BUS", 0x00421c, "Hardware Controller3 Low"},
  {"BUS", 0x00421d, "Hardware Controller3 High"},
  {"BUS", 0x00421e, "Hardware Controller4 Low"},
  {"BUS", 0x00421f, "Hardware Controller4 High"},
  {"BUS", 0x014a13, "Chuck $01:4a13"},
  {"BUS", 0xee4734, "Platform $ee:4734"}, -- this is in no way an extensive list, just common values
  {"BUS", 0xee4cb2, "Platform $ee:4cb2"},
  {"BUS", 0xee4f34, "Platform $ee:4f34"},
  {"WRAM", 0x0015, "RAM Controller Low"},
  {"WRAM", 0x0016, "RAM Controller Low (1st frame)"},
  {"WRAM", 0x0017, "RAM Controller High"},
  {"WRAM", 0x0018, "RAM Controller High (1st frame)"},

  active = {},
}

smw.X_INTERACTION_POINTS = {center = 0x8, left_side = 0x2 + 1, left_foot = 0x5, right_side = 0xe - 1, right_foot = 0xb}

smw.Y_INTERACTION_POINTS = {
  {head = 0x10, center = 0x18, shoulder = 0x16, side = 0x1a, foot = 0x20, sprite = 0x15},
  {head = 0x08, center = 0x12, shoulder = 0x0f, side = 0x1a, foot = 0x20, sprite = 0x07},
  {head = 0x13, center = 0x1d, shoulder = 0x19, side = 0x28, foot = 0x30, sprite = 0x19},
  {head = 0x10, center = 0x1a, shoulder = 0x16, side = 0x28, foot = 0x30, sprite = 0x11}
}

smw.HITBOX_SPRITE = {  -- sprites' hitbox against player and other sprites
  [0x00] = { xoff = 2, yoff = 3, width = 12, height = 10, oscillation = true },
  [0x01] = { xoff = 2, yoff = 3, width = 12, height = 21, oscillation = true },
  [0x02] = { xoff = 16, yoff = -2, width = 16, height = 18, oscillation = true },
  [0x03] = { xoff = 20, yoff = 8, width = 8, height = 8, oscillation = true },
  [0x04] = { xoff = 0, yoff = -2, width = 48, height = 14, oscillation = true },
  [0x05] = { xoff = 0, yoff = -2, width = 80, height = 14, oscillation = true },
  [0x06] = { xoff = 1, yoff = 2, width = 14, height = 24, oscillation = true },
  [0x07] = { xoff = 8, yoff = 8, width = 40, height = 48, oscillation = true },
  [0x08] = { xoff = -8, yoff = -2, width = 32, height = 16, oscillation = true },
  [0x09] = { xoff = -2, yoff = 8, width = 20, height = 30, oscillation = true },
  [0x0a] = { xoff = 3, yoff = 7, width = 1, height = 2, oscillation = true },
  [0x0b] = { xoff = 6, yoff = 6, width = 3, height = 3, oscillation = true },
  [0x0c] = { xoff = 1, yoff = -2, width = 13, height = 22, oscillation = true },
  [0x0d] = { xoff = 0, yoff = -4, width = 15, height = 16, oscillation = true },
  [0x0e] = { xoff = 6, yoff = 6, width = 20, height = 20, oscillation = true },
  [0x0f] = { xoff = 2, yoff = -2, width = 36, height = 18, oscillation = true },
  [0x10] = { xoff = 0, yoff = -2, width = 15, height = 32, oscillation = true },
  [0x11] = { xoff = -24, yoff = -24, width = 64, height = 64, oscillation = true },
  [0x12] = { xoff = -4, yoff = 16, width = 8, height = 52, oscillation = true },
  [0x13] = { xoff = -4, yoff = 16, width = 8, height = 116, oscillation = true },
  [0x14] = { xoff = 4, yoff = 2, width = 24, height = 12, oscillation = true },
  [0x15] = { xoff = 0, yoff = -2, width = 15, height = 14, oscillation = true },
  [0x16] = { xoff = -4, yoff = -12, width = 24, height = 24, oscillation = true },
  [0x17] = { xoff = 2, yoff = 8, width = 12, height = 69, oscillation = true },
  [0x18] = { xoff = 2, yoff = 19, width = 12, height = 58, oscillation = true },
  [0x19] = { xoff = 2, yoff = 35, width = 12, height = 42, oscillation = true },
  [0x1a] = { xoff = 2, yoff = 51, width = 12, height = 26, oscillation = true },
  [0x1b] = { xoff = 2, yoff = 67, width = 12, height = 10, oscillation = true },
  [0x1c] = { xoff = 0, yoff = 10, width = 10, height = 48, oscillation = true },
  [0x1d] = { xoff = 2, yoff = -3, width = 28, height = 27, oscillation = true },
  [0x1e] = { xoff = 6, yoff = -8, width = 3, height = 32, oscillation = true },  -- default: { xoff = -32, yoff = -8, width = 48, height = 32, oscillation = true },
  [0x1f] = { xoff = -16, yoff = -4, width = 48, height = 18, oscillation = true },
  [0x20] = { xoff = -4, yoff = -24, width = 8, height = 24, oscillation = true },
  [0x21] = { xoff = -4, yoff = 16, width = 8, height = 24, oscillation = true },
  [0x22] = { xoff = 0, yoff = 0, width = 16, height = 16, oscillation = true },
  [0x23] = { xoff = -8, yoff = -24, width = 32, height = 32, oscillation = true },
  [0x24] = { xoff = -12, yoff = 32, width = 56, height = 56, oscillation = true },
  [0x25] = { xoff = -14, yoff = 4, width = 60, height = 20, oscillation = true },
  [0x26] = { xoff = 0, yoff = 88, width = 32, height = 8, oscillation = true },
  [0x27] = { xoff = -4, yoff = -4, width = 24, height = 24, oscillation = true },
  [0x28] = { xoff = -14, yoff = -24, width = 28, height = 40, oscillation = true },
  [0x29] = { xoff = -16, yoff = -4, width = 32, height = 27, oscillation = true },
  [0x2a] = { xoff = 2, yoff = -8, width = 12, height = 19, oscillation = true },
  [0x2b] = { xoff = 0, yoff = 2, width = 16, height = 76, oscillation = true },
  [0x2c] = { xoff = -8, yoff = -8, width = 16, height = 16, oscillation = true },
  [0x2d] = { xoff = 4, yoff = 4, width = 8, height = 4, oscillation = true },
  [0x2e] = { xoff = 2, yoff = -2, width = 28, height = 34, oscillation = true },
  [0x2f] = { xoff = 2, yoff = -2, width = 28, height = 32, oscillation = true },
  [0x30] = { xoff = 8, yoff = -14, width = 16, height = 28, oscillation = true },
  [0x31] = { xoff = 0, yoff = -2, width = 48, height = 18, oscillation = true },
  [0x32] = { xoff = 0, yoff = -2, width = 48, height = 18, oscillation = true },
  [0x33] = { xoff = 0, yoff = -2, width = 64, height = 18, oscillation = true },
  [0x34] = { xoff = -4, yoff = -4, width = 8, height = 8, oscillation = true },
  [0x35] = { xoff = 3, yoff = 0, width = 18, height = 32, oscillation = true },
  [0x36] = { xoff = 8, yoff = 8, width = 52, height = 46, oscillation = true },
  [0x37] = { xoff = 0, yoff = -8, width = 15, height = 20, oscillation = true },
  [0x38] = { xoff = 8, yoff = 16, width = 32, height = 40, oscillation = true },
  [0x39] = { xoff = 4, yoff = 3, width = 8, height = 10, oscillation = true },
  [0x3a] = { xoff = -8, yoff = 16, width = 32, height = 16, oscillation = true },
  [0x3b] = { xoff = 0, yoff = 0, width = 16, height = 13, oscillation = true },
  [0x3c] = { xoff = 12, yoff = 10, width = 3, height = 6, oscillation = true },
  [0x3d] = { xoff = 12, yoff = 21, width = 3, height = 20, oscillation = true },
  [0x3e] = { xoff = 16, yoff = 18, width = 254, height = 16, oscillation = true },
  [0x3f] = { xoff = 8, yoff = 8, width = 8, height = 24, oscillation = true }
}

smw.OBJ_CLIPPING_SPRITE = {  -- sprites' interaction points against objects
  [0x0] = {xright = 14, xleft =  2, xdown =  8, xup =  8, yright =  8, yleft =  8, ydown = 16, yup =  2},
  [0x1] = {xright = 14, xleft =  2, xdown =  7, xup =  7, yright = 18, yleft = 18, ydown = 32, yup =  2},
  [0x2] = {xright =  7, xleft =  7, xdown =  7, xup =  7, yright =  7, yleft =  7, ydown =  7, yup =  7},
  [0x3] = {xright = 14, xleft =  2, xdown =  8, xup =  8, yright = 16, yleft = 16, ydown = 32, yup = 11},
  [0x4] = {xright = 16, xleft =  0, xdown =  8, xup =  8, yright = 18, yleft = 18, ydown = 32, yup =  2},
  [0x5] = {xright = 13, xleft =  2, xdown =  8, xup =  8, yright = 24, yleft = 24, ydown = 32, yup = 16},
  [0x6] = {xright =  7, xleft =  0, xdown =  4, xup =  4, yright =  4, yleft =  4, ydown =  8, yup =  0},
  [0x7] = {xright = 31, xleft =  1, xdown = 16, xup = 16, yright = 16, yleft = 16, ydown = 31, yup =  1},
  [0x8] = {xright = 15, xleft =  0, xdown =  8, xup =  8, yright =  8, yleft =  8, ydown = 15, yup =  0},
  [0x9] = {xright = 16, xleft =  0, xdown =  8, xup =  8, yright =  8, yleft =  8, ydown = 16, yup =  0},
  [0xa] = {xright = 13, xleft =  2, xdown =  8, xup =  8, yright = 72, yleft = 72, ydown = 80, yup = 66},
  [0xb] = {xright = 14, xleft =  2, xdown =  8, xup =  8, yright =  4, yleft =  4, ydown =  8, yup =  0},
  [0xc] = {xright = 13, xleft =  2, xdown =  8, xup =  8, yright =  0, yleft =  0, ydown =  0, yup =  0},
  [0xd] = {xright = 16, xleft =  0, xdown =  8, xup =  8, yright =  8, yleft =  8, ydown = 16, yup =  0},
  [0xe] = {xright = 31, xleft =  0, xdown = 16, xup = 16, yright =  8, yleft =  8, ydown = 16, yup =  0},
  [0xf] = {xright =  8, xleft =  8, xdown =  8, xup = 16, yright =  4, yleft =  1, ydown =  2, yup =  4}
}

smw.SPRITE_TWEAKERS_INFO = {
  [1] = {"Disappear in cloud of smoke", "Hop in/kick shells", "Dies when jumped on", "Can be jumped on", "Object clipping", "Object clipping", "Object clipping", "Object clipping"},
  [2] = {"Falls straight down when killed", "Use shell as death frame", "Sprite clipping", "Sprite clipping", "Sprite clipping", "Sprite clipping", "Sprite clipping", "Sprite clipping"},
  [3] = {"Don't interact with layer 2 (or layer 3 tides)", "Disable water splash", "Disable cape killing", "Disable fireball killing", "Palette", "Palette", "Palette", "Use second graphics page"},
  [4] = {"Don't use default interaction with player", "Gives power-up when eaten by Yoshi", "Process interaction with player every frame", "Can't be kicked like a shell", "Don't change into a shell when stunned", "Process while off screen", "Invincible to star/cape/fire/bouncing bricks", "Don't disable clipping when killed with star"},
  [5] = {"Don't interact with objects", "Spawns a new sprite", "Don't turn into a coin when goal passed", "Don't change direction if touched", "Don't interact with other sprites", "Weird ground behavior", "Stay in Yoshi's mouth", "Inedible"},
  [6] = {"Don't get stuck in walls (carryable sprites)", "Don't turn into a coin with silver POW", "Death frame 2 tiles high", "Can be jumped on with upward Y speed", "Takes 5 fireballs to kill. Clear means it's killed by one.", "Can't be killed by sliding", "Don't erase when goal passed", "Make platform passable from below"}
}

smw.HITBOX_EXTENDED_SPRITE = {
  -- To fill the slots...
  --[0] ={ xoff = 3, yoff = 3, width = 64, height = 64},  -- Free slot
  [0x01] ={ xoff = 3, yoff = 3, width =  0, height =  0},  -- Puff of smoke with various objects
  [0x0e] ={ xoff = 3, yoff = 3, width =  0, height =  0},  -- Wiggler's flower
  [0x0f] ={ xoff = 3, yoff = 3, width =  0, height =  0},  -- Trail of smoke
  [0x10] ={ xoff = 3, yoff = 3, width =  0, height =  0},  -- Spinjump stars
  [0x12] ={ xoff = 3, yoff = 3, width =  0, height =  0},  -- Water bubble
  -- extracted from ROM:
  [0x02] = { xoff = 3, yoff = 3, width = 1, height = 1, color_line = COLOUR.fireball},  -- Reznor fireball
  [0x03] = { xoff = 3, yoff = 3, width = 1, height = 1, color_line = COLOUR.fireball},  -- Flame left by hopping flame
  [0x04] = { xoff = 4, yoff = 4, width = 8, height = 8},  -- Hammer
  [0x05] = { xoff = 3, yoff = 3, width = 1, height = 1, color_line = COLOUR.fireball },  -- Player fireball
  [0x06] = { xoff = 4, yoff = 4, width = 8, height = 8},  -- Bone from Dry Bones
  [0x07] = { xoff = 0, yoff = 0, width = 0, height = 0},  -- Lava splash
  [0x08] = { xoff = 0, yoff = 0, width = 0, height = 0},  -- Torpedo Ted shooter's arm
  [0x09] = { xoff = 0, yoff = 0, width = 15, height = 15},  -- Unknown flickering object
  [0x0a] = { xoff = 4, yoff = 2, width = 8, height = 12},  -- Coin from coin cloud game
  [0x0b] = { xoff = 3, yoff = 3, width = 1, height = 1, color_line = COLOUR.fireball },  -- Piranha Plant fireball
  [0x0c] = { xoff = 3, yoff = 3, width = 1, height = 1, color_line = COLOUR.fireball },  -- Lava Lotus's fiery objects
  [0x0d] = { xoff = 3, yoff = 3, width = 1, height = 1, color_line = COLOUR.baseball},  -- Baseball
  -- got experimentally:
  [0x11] = { xoff = -0x1, yoff = -0x4, width = 11, height = 19},  -- Yoshi fireballs
}

smw.HITBOX_CLUSTER_SPRITE = {  -- got experimentally
  --[0] -- Free slot
  [0x01] = { xoff = 2, yoff = 0, width = 17, height = 21, oscillation = 2, phase = 1, color = COLOUR.awkward_hitbox, bg = COLOUR.awkward_hitbox_bg},  -- 1-Up from bonus game (glitched hitbox area)
  [0x02] = { xoff = 4, yoff = 7, width = 7, height = 7, oscillation = 4},  -- Unused
  [0x03] = { xoff = 4, yoff = 7, width = 7, height = 7, oscillation = 4},  -- Boo from Boo Ceiling
  [0x04] = { xoff = 4, yoff = 7, width = 7, height = 7, oscillation = 4},  -- Boo from Boo Ring
  [0x05] = { xoff = 4, yoff = 7, width = 7, height = 7, oscillation = 4},  -- Castle candle flame (meaningless hitbox)
  [0x06] = { xoff = 2, yoff = 2, width = 12, height = 20, oscillation = 4, color = COLOUR.sumo_brother_flame},  -- Sumo Brother lightning flames
  [0x07] = { xoff = 4, yoff = 7, width = 7, height = 7, oscillation = 4},  -- Reappearing Boo
  [0x08] = { xoff = 4, yoff = 7, width = 7, height = 7, oscillation = 4},  -- Swooper bat from Swooper Death Bat Ceiling (untested)
}

                    -- 0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f  10 11 12
smw.SPRITE_MEMORY_MAX = {[0] = 10, 6, 7, 6, 7, 5, 8, 5, 7, 9, 9, 4, 8, 6, 8, 9, 10, 6, 6}  -- the max of sprites in a room

-- from sprite number, returns oscillation flag
-- A sprite must be here iff it processes interaction with player every frame AND this bit is not working in the sprite_4_tweaker WRAM(0x167a)
smw.OSCILLATION_SPRITES = luap.make_set{0x0e, 0x21, 0x29, 0x35, 0x54, 0x74, 0x75, 0x76, 0x77, 0x78, 0x81, 0x83, 0x87}

-- Sprites that have a custom hitbox drawing
smw.ABNORMAL_HITBOX_SPRITES = luap.make_set{0x62, 0x63, 0x6b, 0x6c}

-- Sprites whose clipping interaction points usually matter
smw.GOOD_SPRITES_CLIPPING = luap.make_set{
  0x0, 0x1, 0x2, 0x3, 0x4, 0x5, 0x6, 0x7, 0x8, 0x9, 0xa, 0xb, 0xc, 0xd, 0xf, 0x10, 0x11, 0x13, 0x14, 0x18,
  0x1b, 0x1d, 0x1f, 0x20, 0x26, 0x27, 0x29, 0x2b, 0x2c, 0x2d, 0x2e, 0x2f, 0x30, 0x31,
  0x32, 0x34, 0x35, 0x3d, 0x3e, 0x3f, 0x40, 0x46, 0x47, 0x48, 0x4d, 0x4e,
  0x51, 0x53, 0x6e, 0x6f, 0x70, 0x80, 0x81, 0x86,
  0x91, 0x92, 0x93, 0x94, 0x95, 0x96, 0x97, 0x98, 0x99, 0x9a, 0xa1, 0xa2, 0xa5, 0xa6, 0xa7, 0xab, 0xb2,
  0xb4, 0xbb, 0xbc, 0xbd, 0xbf, 0xc3, 0xda, 0xdb, 0xdc, 0xdd, 0xdf
}

-- Extended sprites that don't interact with the player
smw.UNINTERESTING_EXTENDED_SPRITES = luap.make_set{1, 7, 8, 0x0e, 0x10, 0x12}

return smw
