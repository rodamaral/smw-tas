--[[
TODO: PROBLEMATIC ONES
  29  Koopa Kid
  54  Revolving door for climbing net, wrong hitbox area, not urgent
  5a  Turn block bridge, horizontal, hitbox only applies to central block and wrongly
  89  Layer 3 Smash, hitbox of generator outside
  9e  Ball 'n' Chain, hitbox only applies to central block, rotating ball
  a3  Rotating gray platform, wrong hitbox, rotating plataforms
--]] local M = {}

local bit, gui = _G.bit, _G.gui

local image = require 'game.image'

local DBITMAPS = image.dbitmaps

local luap = require 'luap'
local mem = require('memory')
local keyinput = require 'keyinput'
local config = require 'config'
local draw = require 'draw'
local smw = require 'game.smw'
local Sprites_info = require 'game.sprites.spriteinfo'

local u8 = mem.u8
local u16 = mem.u16
local s16 = mem.s16
local floor = math.floor
local fmt = string.format
local OPTIONS = config.OPTIONS
local COLOUR = config.COLOUR
local screen_coordinates = smw.screen_coordinates
local WRAM = smw.WRAM
local SMW = smw.constant
local LEFT_ARROW = config.LEFT_ARROW
local RIGHT_ARROW = config.RIGHT_ARROW

local function isMouseOverSprite(slot)
    local t = Sprites_info[slot]
    local x_screen = t.x_screen
    local y_screen = t.y_screen
    local xoff = t.hitbox_xoff
    local yoff = t.hitbox_yoff
    local sprite_width = t.hitbox_width
    local sprite_height = t.hitbox_height
    local x_text, y_text = draw.AR_x * (x_screen + xoff), draw.AR_y * (y_screen + yoff)

    return keyinput:mouse_onregion(x_text, y_text, x_text + draw.AR_x * sprite_width, y_text + draw.AR_y * sprite_height)
end

M[0x00] = function(slot) -- Shell-less Koopas
    local t = Sprites_info[slot]
    if t.status ~= 0x08 then return end
    draw.Font = 'Uzebox6x8'
    local xdraw, ydraw = draw.AR_x * t.x_screen + 10, draw.AR_x * t.y_screen - 26

    local slidingTimer = u8(WRAM.sprite_misc_1528 + slot)
    if slidingTimer > 0 then
        draw.text(xdraw - 16, ydraw + 8, 'Sliding', t.info_color)
        return
    end

    local hopTimer = u8(WRAM.sprite_misc_1558 + slot)
    local phase = u8(WRAM.sprite_phase + slot)
    if hopTimer > 0 then
        local targetSlot = u8(WRAM.sprite_misc_1594 + slot)
        local targetStatus = u8(WRAM.sprite_status + targetSlot)
        local color = hopTimer <= phase + 1 and COLOUR.very_weak or
            ((targetSlot > SMW.sprite_max or targetStatus == 0)
            and COLOUR.warning
            or t.info_color)

        draw.text(xdraw - 16, ydraw + 0, string.format('Hop #%x %x', targetSlot, hopTimer), color)
    end

    local kickTimer = u8(WRAM.sprite_misc_163e + slot)
    if kickTimer > 0 and kickTimer < 0x80 then
        local targetSlot = u8(WRAM.sprite_misc_160e + slot)
        local targetStatus = u8(WRAM.sprite_status + targetSlot)
        local color = targetStatus >= 9 and (t.number == 2 and t.info_color or COLOUR.warning) or COLOUR.weak
        draw.text(xdraw - 16, ydraw + 8, string.format('Kick #%x %x', targetSlot, kickTimer), color)
    end
end
M[0x01] = M[0x00]
M[0x03] = M[0x00]

M[0x02] = function(slot) -- Blue Shell-less Koopa
    local t = Sprites_info[slot]
    if t.status ~= 0x08 then return end

    draw.Font = 'Uzebox6x8'
    local xdraw, ydraw = draw.AR_x * t.x_screen + 10, draw.AR_x * t.y_screen - 26

    M[0x00](slot)
    local pushedFlag = u8(WRAM.sprite_misc_1534 + slot) ~= 0
    local targetSlot = u8(WRAM.sprite_misc_160e + slot)
    if pushedFlag then
        draw.text(xdraw - 16, ydraw + 8, string.format('Pushed by #%x', targetSlot), t.info_color)
    end
end

M[0x19] = function(slot) -- Display text from level message 1
    local timer = u8(WRAM.sprite_sprite_contact + slot)
    if timer ~= 0 then
        local t = Sprites_info[slot]
        draw.Font = 'Uzebox6x8'
        local xdraw, ydraw = draw.AR_x * t.x_screen + 10, draw.AR_x * t.y_screen - 26
        local color = t.status == 0x08 and COLOUR.warning or COLOUR.weak
        draw.text(xdraw - 64, ydraw + 8, string.format('End level timer: %x', timer), color)
    end
end

M[0x1e] = function(slot) -- Lakitu
    if u8(WRAM.sprite_misc_151c + slot) ~= 0 or
    u8(WRAM.sprite_horizontal_direction + slot) ~= 0 then
        local OAM_index = 0xec
        local xoff = u8(WRAM.sprite_OAM_xoff + OAM_index) - 0x0c
        local yoff = u8(WRAM.sprite_OAM_yoff + OAM_index) - 0x0c
        local width, height = 0x18 - 1, 0x18 - 1 -- instruction BCS

        draw.rectangle(xoff, yoff, width, height, COLOUR.awkward_hitbox, COLOUR.awkward_hitbox_bg)
        -- TODO: 0x7e and 0x80 are too important
        -- draw this point outside this function and add an option
        draw.pixel(s16(0x7e), s16(0x80), COLOUR.mario)
    end
end

M[0x2D] = function(slot) -- Baby Yoshi
    local t = Sprites_info[slot]
    local swallowTimer = u8(WRAM.sprite_misc_163e + slot)
    if swallowTimer > 0 then
      local swallowedSlot = u8(WRAM.sprite_misc_160e + slot)
      local swallowedId = u8(WRAM.sprite_number + swallowedSlot)
      local swallowedStatus = u8(WRAM.sprite_status + swallowedSlot)
      local feedCount = u8(WRAM.sprite_animation_timer + slot)
      local color = swallowTimer <= 0x20 and COLOUR.text or t.info_color
      if swallowedSlot > SMW.sprite_max then color = COLOUR.warning end

      local extraInfo = (swallowedStatus == 0 and swallowTimer > 0x20)
        and string.format('(%.2x)', swallowedId)
        or ''

      draw.Font = 'Uzebox6x8'
      draw.Text_opacity = 1
      draw.Bg_opacity = 0.6
      local xdraw, ydraw = draw.AR_x * t.x_screen + 10, draw.AR_x * t.y_screen - 26
      draw.text(xdraw, ydraw, string.format('#%x%s %x', swallowedSlot, extraInfo, swallowTimer), color)
      DBITMAPS.yoshi_tongue:draw(xdraw, ydraw + 8)
      draw.text(xdraw + 16 + 4, ydraw + 8, feedCount, color)
    end
end

M[0x3d] = function(slot, Display) -- Rip Van Fish
    if u8(WRAM.sprite_phase + slot) == 0 then -- if sleeping
        local x_screen = Sprites_info[slot].x_screen
        local y_screen = Sprites_info[slot].y_screen
        local color = Sprites_info[slot].info_color
        local x1, y1, x2, y2 = -0x30, -0x30, 0x2e, 0x2e

        -- Draw central hitbox and 8 areas around due to overflow
        for horizontal = -1, 1 do
            local x = x_screen + 0x100 * horizontal
            for vertical = -1, 1 do
                local y = y_screen + 0x100 * vertical
                draw.box(x + x1, y + y1, x + x2, y + y2, 2, color)
            end
        end

        Display.show_player_point_position = true -- Only Mario coordinates matter
    end
end

M[0x3E] = function(slot) -- Display text from level message 1
    M[0x19](slot)

    if isMouseOverSprite(slot) then
        local switchType = u8(WRAM.sprite_misc_151c + slot)
        local gfx = u8(WRAM.sprite_YXPPCCCT + slot)
        draw.Font = 'Uzebox6x8'
        local t = Sprites_info[slot]
        local xdraw, ydraw = draw.AR_x * t.x_screen + 10, draw.AR_x * t.y_screen - 26
        local color = switchType > 1 and COLOUR.warning or t.info_color
        draw.text(xdraw - 64, ydraw + 16, string.format('Type: %x, YXPPCCCT: %.2x', switchType, gfx), color)
    end
end

M[0x3f] = function(slot) -- Parachutes
    local t = Sprites_info[slot]
    local xoff = t.hitbox_xoff
    local yoff = t.hitbox_yoff

    if t.status == 8 then
        local animation = u8(WRAM.sprite_animation_timer + slot)
        xoff = xoff + memory.sread_sg('ROM', 0xd57e + animation, 'ROM', 0xd58e + animation)
    end

    if OPTIONS.display_sprite_hitbox then
        draw.rectangle(t.x_screen + xoff, t.y_screen + yoff, t.hitbox_width, t.hitbox_height,
                       t.info_color, t.background_color)
    end
end
M[0x40] = M[0x3f]

M[0x4c] = function(slot, Display) -- Exploding block
    local t = Sprites_info[slot]
    local Real_frame = u8(WRAM.real_frame)
    local color = t.status == 8 and t.info_color or COLOUR.very_weak

    if u8(WRAM.sprite_x_offscreen + slot) == 0 then
        local x_screen = t.x_screen
        local bg_color = (t.status == 8 and (Real_frame - slot) % 2 == 1) and 0xC0200020 or -1

        local x1, x2 = -0x60, 0x5F

        local top = floor(OPTIONS.top_gap / draw.AR_y)
        local bottom = floor((draw.Buffer_height + OPTIONS.bottom_gap - 1) / draw.AR_x)

        for screen = -1, 1 do
            draw.box(0x100 * screen + x_screen + x1, -top, 0x100 * screen + x_screen + x2, bottom,
                     2, color, bg_color)
        end

        Display.show_player_point_position = true -- Only Mario coordinates matter
    end

    local xdraw, ydraw = draw.AR_x * t.x_screen + 10, draw.AR_x * t.y_screen - 26
    local spriteId = u8(WRAM.sprite_phase + slot)
    draw.text(xdraw - 8, ydraw + 8, string.format('id: %x', spriteId), color)
end

M[0x5f] = function(slot) -- Swinging brown platform (TODO fix it)
    --[[ TEST
  local angle = 0x100*u16("WRAM", WRAM.sprite_misc_1528 + slot) + u16("WRAM", WRAM.sprite_misc_151c + slot)
  local var1 = (angle)%0x100
  local var2 = (angle + 0x80)%0x100
  gui.text(0, 200 + 16*slot, fmt("%.4x: 1:  %.4x   2: %.4x", angle, var1, var2), "red", "darkblue")

  local t = Sprites_info[slot]
  local center_x = t.x - 0x50
  local center_y = t.y - 0x00
  local var_1866 = u16("WRAM", WRAM.sprite_misc_1528 + slot)
  local var_151c = u16("WRAM", WRAM.sprite_misc_151c + slot)
  local var_1867 = ((var_151c == 0 and 0 or 1)+ var_1866)%2

  local var_14c5 = smw.TRIGONOMETRY[var2]

  local multi = 0x50 * var_14c5
  local multi_high = math.floor(multi/0x10000)
  local multi_low = multi%0x10000

  local var_4 = multi_low
  local var_6 = multi_high

  if var_1867 == 1 then
    print"flipping"
    var_4 = (bit.bxor(var_4, 0xffff) + 1)%0x10000
    var_6 = (bit.bxor(var_6, 0xffff) + 1)%0x10000
  end
  local var_8 = var_4
  local var_a = var_6

  local var_5 = math.floor(var_8/0x100) + 0x100*math.floor(var_a/0x100)

  local var_14b8 = (center_x + var_5)%0x10000
  local var_35c = (center_x - Camera_x - 8)%0x100
  local var_358 = (var_14b8 - Camera_x - 8)%0x10000
  local var_7 = var_35c
  hex("var_7", var_7)
  local var_2 = (center_x - 8)%0x10000
  local var_4 = (var_358 - var_7 + var_2)%0x10000
  var_14b8 = var_4
  hex("var_2", var_2)

  gui.textHV(0, 400, fmt("%x", var_14b8))
  draw.line(var_14b8 - Camera_x, 0, var_14b8 - Camera_x, 224, 2)
  gui.text(0, 32, fmt("%d %d", center_x + smw.TRIGONOMETRY[var1] - 0x18, center_y - smw.TRIGONOMETRY[var2]))

  -- draw some shit
  draw.rectangle(t.x_screen - 0x50, t.y_screen, 8, 8)
  local angle = 0x100*u16("WRAM", WRAM.sprite_misc_1528 + slot) + u16("WRAM", WRAM.sprite_misc_151c + slot)
  var1 = smw.TRIGONOMETRY[(angle - 0x80)%0x100]
  var2 = smw.TRIGONOMETRY[(angle - 0x100)%0x100]
  if (angle - 0x80)%0x200 <= 0x100 then
    var1 = - var1
  end
  if (angle - 0x100)%0x200 <= 0x100 then
    var2 = - var2
  end

  local x = t.x - 0x50 + math.floor(var1*0x50/0x100)
  local y = t.y - 0 + math.floor(var2*0x50/0x100)
  draw.rectangle(x -32 - Camera_x, y - Camera_y - 20, 64, 11)
  --]]
    local t = Sprites_info[slot]
    local x = t.x
    local x_screen = t.x_screen
    local y_screen = t.y_screen
    local xoff = t.hitbox_xoff
    local yoff = t.hitbox_yoff
    local color = t.info_color

    -- Powerup Incrementation helper
    local yoshi_right = 256 * floor(x / 256) - 58
    local yoshi_left = yoshi_right + 32
    local x_text, y_text, height = draw.AR_x * (x_screen + xoff), draw.AR_y * (y_screen + yoff),
                                   draw.font_height()

    if isMouseOverSprite(slot) then
        x_text, y_text = 0, 0
        gui.text(x_text, y_text, 'Powerup Incrementation help', color, COLOUR.background)
        gui.text(x_text, y_text + height, 'Yoshi must have: id = #4;', color, COLOUR.background)
        gui.text(x_text, y_text + 2 * height, fmt('Yoshi x pos: (%s %d) or (%s %d)', LEFT_ARROW,
                                                  yoshi_left, RIGHT_ARROW, yoshi_right), color,
                 COLOUR.background)
    end
    --[[ The status change happens when yoshi's id number is #4 and when
  (yoshi's x position) + Z mod 256 = 214,
  where Z is 16 if yoshi is facing right, and -16 if facing left.
  More precisely, when (yoshi's x position + Z) mod 256 = 214,
  the address 0x7E0015 + (yoshi's id number) will be added by 1.
  therefore: X_yoshi = 256*floor(x/256) + 32*yoshi_direction - 58 ]]
end

M[0x35] = function(slot, Display) -- Yoshi
    local t = Sprites_info[slot]
    local Yoshi_riding_flag = u8(WRAM.yoshi_riding_flag) ~= 0

    if not Yoshi_riding_flag and OPTIONS.display_sprite_hitbox and
    Display.sprite_hitbox[slot][t.number].sprite then
        draw.rectangle(t.x_screen + 4, t.y_screen + 20, 8, 8, COLOUR.yoshi)
    end
end

M[0x54] = function(slot) -- Revolving door for climbing net
    local t = Sprites_info[slot]
    local xCam = s16(WRAM.camera_x)
    local yCam = s16(WRAM.camera_y)
    local Player_x = s16(WRAM.x)
    local Player_y = s16(WRAM.y)

    -- draw custom hitbox for Mario
    if luap.inside_rectangle(Player_x, Player_y, t.x - 8, t.y - 24, t.x + 55, t.y + 55) then
        local extra_x, extra_y = screen_coordinates(Player_x, Player_y, xCam, yCam)
        draw.rectangle(t.x_screen - 8, t.y_screen - 8, 63, 63, COLOUR.very_weak)
        draw.rectangle(extra_x, extra_y, 0x10, 0x10, COLOUR.awkward_hitbox, COLOUR.awkward_hitbox_bg)
    end
end

M[0x62] = function(slot) -- Brown line-guided platform TODO: fix it
    local t = Sprites_info[slot]
    local xoff = t.hitbox_xoff - 24
    local yoff = t.hitbox_yoff - 8

    -- TODO: debug interaction for mario's image
    if OPTIONS.display_sprite_hitbox then
        draw.rectangle(t.x_screen + xoff, t.y_screen + yoff, t.hitbox_width, t.hitbox_height,
                       t.info_color, t.background_color)
    end
end

M[0x63] = M[0x62] -- Brown/checkered line-guided platform

M[0x6b] = function(slot) -- Wall springboard (left wall)
    if not OPTIONS.display_sprite_hitbox then return end

    local t = Sprites_info[slot]
    local color = t.info_color
    local Yoshi_riding_flag = u8(WRAM.yoshi_riding_flag) ~= 0
    local Player_powerup = u8(WRAM.powerup)

    -- HUD for the carry sprite cheat
    local xoff = t.hitbox_xoff
    local yoff = t.hitbox_yoff
    local x_screen = t.x_screen
    local y_screen = t.y_screen
    local sprite_width = t.hitbox_width
    local sprite_height = t.hitbox_height
    draw.rectangle(x_screen + xoff, y_screen + yoff, sprite_width, sprite_height,
                   COLOUR.sprites_faint)

    -- Mario's image
    local xmario, ymario = u16(0x7e), u16(0x80)
    if math.floor(xmario / 256) == 0 and math.floor(ymario / 256) == 0 then
        local y1 = 0x08 + 0x08 + (Yoshi_riding_flag and 0x10 or 0)
        local y2 = 0x21 + (Yoshi_riding_flag and 0x10 or 0) + (Player_powerup == 0 and 2 or 0)
        draw.box(xmario - 6 + 0x8, ymario + y1, xmario + 0x0d, ymario + y2, 2,
                 COLOUR.mario_oam_hitbox, COLOUR.interaction_bg)
    end

    -- Spheres hitbox
    draw.Font = 'Uzebox6x8'
    if t.x_offscreen == 0 and t.y_offscreen == 0 then
        local OAM_index = u8(WRAM.sprite_OAM_index + slot)
        for ball = 0, 4 do
            local x = u8(0x300 + OAM_index + 4 * ball)
            local y = u8(0x301 + OAM_index + 4 * ball)

            draw.rectangle(x, y, 8, 8, color, COLOUR.sprites_bg)
            draw.text(draw.AR_x * (x + 2), draw.AR_y * (y + 2), ball, COLOUR.text)
        end
    end
end

M[0x6c] = M[0x6b] -- Wall springboard (right wall)

M[0x6f] = function(slot) -- Dino-Torch: display flame hitbox
    local t = Sprites_info[slot]
    local Real_frame = u8(WRAM.real_frame)

    if OPTIONS.display_sprite_hitbox then
        if u8(WRAM.sprite_misc_151c + slot) == 0 then -- if flame is hurting
            local active = (Real_frame - slot) % 4 == 0 and COLOUR.sprites_bg or -1
            local vertical_flame = u8(WRAM.sprite_misc_1602 + slot) == 3
            local xoff, yoff, width, height

            if vertical_flame then
                xoff, yoff, width, height = 0x02, -0x24, 0x0c, 0x24
            else
                local facing_right = u8(WRAM.sprite_horizontal_direction + slot) == 0
                xoff = facing_right and 0x10 or -0x24
                yoff = 0x02
                width, height = 0x24, 0x0c
            end

            draw.rectangle(t.x_screen + xoff, t.y_screen + yoff, width, height,
                           COLOUR.awkward_hitbox, active)
        end
    end
end

M[0x7b] = function(slot, Display) -- Goal Tape
    local t = Sprites_info[slot]
    local info_color = Sprites_info[slot].info_color
    local xCam = s16(WRAM.camera_x)
    local yCam = s16(WRAM.camera_y)

    draw.Font = 'Uzebox6x8'
    draw.Text_opacity = 0.8
    draw.Bg_opacity = 0.6

    -- This draws the effective area of a goal tape
    local x_effective = 256 * u8(WRAM.sprite_misc_151c + slot) +
                        u8(WRAM.sprite_phase + slot)
    local y_low = 256 * u8(WRAM.sprite_misc_1534 + slot) +
                  u8(WRAM.sprite_misc_1528 + slot)
    local _, y_high = screen_coordinates(0, 0, xCam, yCam)
    local x_s, y_s = screen_coordinates(x_effective, y_low, xCam, yCam)
    local active = u8(WRAM.sprite_misc_1602 + slot) == 0
    local color = active and COLOUR.goal_tape_bg or -1

    if OPTIONS.display_sprite_hitbox then
        draw.box(x_s, y_high, x_s + 15, y_s, 2, info_color, color)
    end
    draw.text(draw.AR_x * x_s, draw.AR_y * t.y_screen,
              fmt('Touch=%4d.0->%4d.f', x_effective, x_effective + 15), info_color, false, false)

    -- Draw a bitmap if the tape is unnoticeable
    local x_png, y_png = draw.put_on_screen(draw.AR_x * x_s, draw.AR_y * y_s, 18, 6) -- png is 18x6 -- lsnes
    if x_png ~= draw.AR_x * x_s or y_png > draw.AR_y * y_s then -- tape is outside the screen
        DBITMAPS.goal_tape:draw(x_png, y_png)
    else
        Display.show_player_point_position = true
        if y_low < 10 then DBITMAPS.goal_tape:draw(x_png, y_png) end -- tape is too small, 10 is arbitrary here
    end
end

M[0x86] = function(slot) -- Wiggler (segments)
    local OAM_index = u8(WRAM.sprite_OAM_index + slot)
    local Yoshi_riding_flag = u8(WRAM.yoshi_riding_flag) ~= 0
    for _ = 0, 4 do
        local xoff = u8(WRAM.sprite_OAM_xoff + OAM_index) - 0x0a
        local yoff = u8(WRAM.sprite_OAM_yoff + OAM_index) - 0x1b
        if Yoshi_riding_flag then yoff = yoff - 0x10 end
        local width, height = 0x17 - 1, 0x17
        local xend, yend = xoff + width, yoff + height

        -- TODO: fix draw.rectangle to display the exact dimensions; then remove the -1
        -- draw.rectangle(xoff, yoff, width - 1, height - 1, COLOUR.awkward_hitbox, COLOUR.awkward_hitbox_bg)
        draw.box(xoff, yoff, xend, yend, 2, COLOUR.awkward_hitbox, COLOUR.awkward_hitbox_bg)

        OAM_index = OAM_index + 4
    end

    draw.pixel(s16(0x7e), s16(0x80), COLOUR.mario)
end

M[0xa9] = function()
    -- Reznor: TODO: use slot to see if he's killable
    draw.Font = 'Uzebox8x12'
    local reznor
    local color
    for index = 0, SMW.sprite_max - 1 do
        reznor = u8(WRAM.sprite_misc_151c + index)
        if index >= 4 and index <= 7 then
            color = COLOUR.warning
        else
            color = COLOUR.weak
        end
        draw.text(3 * draw.font_width() * index, draw.Buffer_height, fmt('%.2x', reznor), color,
                  true, false, 0.0, 1.0)
    end
end

M[0x91] = function(slot, Display) -- Chargin' Chuck
    if Sprites_info[slot].status ~= 0x08 then return end

    -- > spriteYLow - addr1 <= MarioYLow < spriteYLow + addr2 - addr1
    local routine_pointer = u8(WRAM.sprite_phase + slot)
    routine_pointer = bit.lshift(bit.band(routine_pointer, 0xff), 1, 16)
    local facing_right = u8(WRAM.sprite_horizontal_direction + slot) == 0

    local x1, x2, y1, yoff, height
    local color, bg

    if routine_pointer == 0 then -- looking
        local active = bit.band(u8(WRAM.sprite_stun_timer + slot), 0x0f) == 0
        color = COLOUR.sprite_vision_passive
        bg = active and COLOUR.sprite_vision_active_bg or -1
        yoff = -0x28
        height = 0x50 - 1
        x1 = 0
        x2 = floor(draw.Buffer_width / 2) - 1
    elseif routine_pointer == 2 then -- following
        color = COLOUR.sprite_vision_active
        bg = COLOUR.sprite_vision_active_bg
        yoff = -0x30
        height = 0x60 - 1
        x1 = Sprites_info[slot].x_screen + (facing_right and 1 or -1)
        x2 = facing_right and floor(draw.Buffer_width / 2) - 1 or 0
    else -- inactive
        color = COLOUR.sprite_vision_passive
        bg = -1
        yoff = -0x28
        height = 0x50 - 1
        x1 = Sprites_info[slot].x_screen + (facing_right and 1 or -1)
        x2 = facing_right and floor(draw.Buffer_width / 2) - 1 or 0
    end

    y1 = Sprites_info[slot].y_screen + yoff
    draw.box(x1, y1, x2, y1 + height, 2, color, bg)

    y1 = y1 + 0x100 -- draw it again, 0x100 pixels below
    draw.box(x1, y1, x2, y1 + height, 2, color, bg)
    Display.show_player_point_position = true
end

M[0x92] = function(slot, Display) -- Splittin' Chuck
    if Sprites_info[slot].status ~= 0x08 then return end
    if u8(WRAM.sprite_phase + slot) ~= 5 then return end

    local xoff = -0x50
    local width = 0xa0 - 1

    local t = Sprites_info[slot]
    for i = -1, 1 do
        draw.rectangle(t.x_screen + xoff + i * 0x100, -draw.Border_top, width,
                       draw.Buffer_height + draw.Border_bottom, t.info_color, 0xf0ffff00)
    end
    Display.show_player_point_position = true
end

M[0x97] = function(slot) -- Puntin' Chuck
    if Sprites_info[slot].status ~= 0x08
        or u8(WRAM.sprite_phase + slot) ~= 9 then return end

    local t = Sprites_info[slot]
    local real_frame = u8(WRAM.real_frame)
    local timer = (0x80 - (8 * slot + real_frame))%0x80
    draw.Font = 'Uzebox6x8'
    draw.Text_opacity = 1
    draw.Bg_opacity = 0.6
    draw.text(draw.AR_x * t.x_screen + 10, draw.AR_x * t.y_screen - 26, timer, COLOUR.warning2)
end

M[0xa0] = function(slot) -- Bowser TODO: use $ for hex values
    draw.Font = 'Uzebox8x12'
    local height = draw.font_height()
    local y_text = draw.Buffer_height - 10 * height
    for index = 0, 9 do
        local value = u8(WRAM.bowser_attack_timers + index)
        draw.text(draw.Buffer_width + draw.Border_right, y_text + index * height,
                  fmt('$%2X = %3d', value, value), Sprites_info[slot].info_color, true)
    end
end

M[0xae] = function(slot) -- Fishin' Boo
    if OPTIONS.display_sprite_hitbox then
        local x_screen = Sprites_info[slot].x_screen
        local y_screen = Sprites_info[slot].y_screen
        local direction = u8(WRAM.sprite_horizontal_direction + slot)
        local aux = u8(WRAM.sprite_misc_1602 + slot)
        local index = 2 * direction + aux
        local offsets = {[0] = 0x1a, 0x14, -0x12, -0x08}
        local xoff = offsets[index]

        if not xoff then -- possible exception
            xoff = 0
            draw.Font = 'Uzebox8x12'
            draw.text(draw.AR_x * x_screen, draw.AR_y * (y_screen + 0x47),
                      fmt('Glitched offset! dir:%.2x, aux:%.2x', direction, aux))
        end

        draw.rectangle(x_screen + xoff, y_screen + 0x47, 4, 4, COLOUR.warning2,
                       COLOUR.awkward_hitbox_bg)
    end
end

return M
