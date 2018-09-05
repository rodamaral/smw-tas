local M = {}

local memory,
  tostring,
  gui = _G.memory, _G.tostring, _G.gui

local config = require 'config'
local draw = require 'draw'
local keyinput = require 'keyinput'
local widget = require 'widget'
local cheat = require 'cheat'
local smw = require 'game.smw'
local spriteInfo = require 'game.sprites.spriteinfo'
local sprite_images = require 'game.sprites.spriteimages'

local WRAM = smw.WRAM
local COLOUR = config.COLOUR

local u8 = memory.readbyte

M.slot = {}

local used = {}

-- Sprite tweakers info
local function sprite_tweaker_editor(slot, x, y)
  draw.Font = 'Uzebox6x8'

  local t = spriteInfo[slot]
  local info_color = t.info_color
  local y_screen = t.y_screen
  --local xoff = t.hitbox_xoff
  local yoff = t.hitbox_yoff

  local width,
    height = draw.font_width(), draw.font_height()
  local x_ini = x or draw.AR_x * t.sprite_middle - 4 * draw.font_width()
  local y_ini = y or draw.AR_y * (y_screen + yoff) - 7 * height
  local x_txt,
    y_txt = x_ini, y_ini

  -- Tweaker viewer/editor
  if keyinput:mouse_onregion(x_ini, y_ini, x_ini + 8 * width - 1, y_ini + 6 * height - 1) then
    local x_select = math.floor((keyinput.mouse_x - x_ini) / width)
    local y_select = math.floor((keyinput.mouse_y - y_ini) / height)

    -- if some cell is selected
    if not (x_select < 0 or x_select > 7 or y_select < 0 or y_select > 5) then
      local color = cheat.allow_cheats and COLOUR.warning or COLOUR.text
      local tweaker_tab = smw.SPRITE_TWEAKERS_INFO
      local message = tweaker_tab[y_select + 1][x_select + 1]

      draw.text(x_txt, y_txt + 6 * height, message, color, true)
      gui.solidrectangle(x_ini + x_select * width, y_ini + y_select * height, width, height, color)

      if cheat.allow_cheats then
        cheat.sprite_tweaker_selected_id = slot
        cheat.sprite_tweaker_selected_x = x_select
        cheat.sprite_tweaker_selected_y = y_select
      end
    end
  else
    cheat.sprite_tweaker_selected_id = nil
    cheat.sprite_tweaker_selected_x = nil
    cheat.sprite_tweaker_selected_y = nil
  end

  local tweaker_1 = u8('WRAM', WRAM.sprite_1_tweaker + slot)
  draw.over_text(x_txt, y_txt, tweaker_1, 'sSjJcccc', COLOUR.weak, info_color)
  y_txt = y_txt + height

  local tweaker_2 = u8('WRAM', WRAM.sprite_2_tweaker + slot)
  draw.over_text(x_txt, y_txt, tweaker_2, 'dscccccc', COLOUR.weak, info_color)
  y_txt = y_txt + height

  local tweaker_3 = u8('WRAM', WRAM.sprite_3_tweaker + slot)
  draw.over_text(x_txt, y_txt, tweaker_3, 'lwcfpppg', COLOUR.weak, info_color)
  y_txt = y_txt + height

  local tweaker_4 = u8('WRAM', WRAM.sprite_4_tweaker + slot)
  draw.over_text(x_txt, y_txt, tweaker_4, 'dpmksPiS', COLOUR.weak, info_color)
  y_txt = y_txt + height

  local tweaker_5 = u8('WRAM', WRAM.sprite_5_tweaker + slot)
  draw.over_text(x_txt, y_txt, tweaker_5, 'dnctswye', COLOUR.weak, info_color)
  y_txt = y_txt + height

  local tweaker_6 = u8('WRAM', WRAM.sprite_6_tweaker + slot)
  draw.over_text(x_txt, y_txt, tweaker_6, 'wcdj5sDp', COLOUR.weak, info_color)
end

function M:new(slot)
  if self.slot[slot] then
    error('Slot ' .. slot .. ' already exists!')
    return
  end

  local obj = {}
  setmetatable(obj, self)
  obj.xpos = 64 * (slot % 3)
  obj.ypos = 64 * math.floor(slot / 3)
  widget:new(string.format('M.slot[%d]', slot), obj.xpos, obj.ypos, tostring(slot))
  widget:set_property(string.format('M.slot[%d]', slot), 'display_flag', true)

  -- FIXME test
  local t = {
    WRAM.sprite_phase,
    WRAM.sprite_misc_1504,
    WRAM.sprite_misc_1510,
    WRAM.sprite_misc_151c,
    WRAM.sprite_misc_1528,
    WRAM.sprite_misc_1534,
    WRAM.sprite_stun_timer,
    WRAM.sprite_player_contact,
    WRAM.sprite_misc_1558,
    WRAM.sprite_sprite_contact,
    WRAM.sprite_animation_timer,
    WRAM.sprite_horizontal_direction,
    WRAM.sprite_blocked_status,
    WRAM.sprite_misc_1594,
    WRAM.sprite_x_offscreen,
    WRAM.sprite_misc_15ac,
    WRAM.sprite_slope,
    WRAM.sprite_misc_15c4,
    WRAM.sprite_being_eaten_flag,
    WRAM.sprite_misc_15dc,
    WRAM.sprite_OAM_index,
    WRAM.sprite_YXPPCCCT,
    WRAM.sprite_misc_1602,
    WRAM.sprite_misc_160e,
    WRAM.sprite_index_to_level,
    WRAM.sprite_misc_1626,
    WRAM.sprite_behind_scenery,
    WRAM.sprite_misc_163e,
    WRAM.sprite_underwater,
    WRAM.sprite_y_offscreen,
    WRAM.sprite_misc_187b,
    WRAM.sprite_disable_cape
  }

  for _, address in ipairs(t) do
    memory.registerread(
      'WRAM',
      address + slot,
      function()
        local number = memory.readbyte('WRAM', 0x9e + slot)
        used[number] = used[number] or {}
        used[number][address] = true
      end
    )
    --[[ memory.registerwrite(
      'WRAM',
      address + slot,
      function()
        local number = memory.readbyte('WRAM', 0x9e + slot)
        used[number] = used[number] or {}
        used[number][address] = true
      end
    ) ]]
  end

  self.slot[slot] = obj
  return obj
end

function M:destroy(slot)
  self.slot[slot] = nil
  widget:set_property(string.format('M.slot[%d]', slot), 'display_flag', false)
end

function M.display_info(x, y, slot)
  local sprite = spriteInfo[slot]
  local info_color = sprite.info_color
  local name = smw.SPRITE_NAMES[sprite.number]
  local image = sprite_images[sprite.number]
  local w,
    h = image:size()
  -- FIXME: take other fonts in consideration
  gui.solidrectangle(x, y, 42 * 8, h + 8 * 12 + 56, 0x202020)
  draw.font['Uzebox6x8'](x + w, y, string.format(' slot #%d is $%.2x: %s', slot, sprite.number, name), info_color)
  image:draw(x, y)

  local t = {
    WRAM.sprite_phase,
    WRAM.sprite_misc_1504,
    WRAM.sprite_misc_1510,
    WRAM.sprite_misc_151c,
    WRAM.sprite_misc_1528,
    WRAM.sprite_misc_1534,
    WRAM.sprite_stun_timer,
    WRAM.sprite_player_contact,
    WRAM.sprite_misc_1558,
    WRAM.sprite_sprite_contact,
    WRAM.sprite_animation_timer,
    WRAM.sprite_horizontal_direction,
    WRAM.sprite_blocked_status,
    WRAM.sprite_misc_1594,
    WRAM.sprite_x_offscreen,
    WRAM.sprite_misc_15ac,
    WRAM.sprite_slope,
    WRAM.sprite_misc_15c4,
    WRAM.sprite_being_eaten_flag,
    WRAM.sprite_misc_15dc,
    WRAM.sprite_OAM_index,
    WRAM.sprite_YXPPCCCT,
    WRAM.sprite_misc_1602,
    WRAM.sprite_misc_160e,
    WRAM.sprite_index_to_level,
    WRAM.sprite_misc_1626,
    WRAM.sprite_behind_scenery,
    WRAM.sprite_misc_163e,
    WRAM.sprite_underwater,
    WRAM.sprite_y_offscreen,
    WRAM.sprite_misc_187b,
    WRAM.sprite_disable_cape
  }

  local text = ''
  for i, address in ipairs(t) do
    local symbol = '_'
    if used[sprite.number] and used[sprite.number][address] then
      symbol = ':'
    end

    if true or used[sprite.number] and used[sprite.number][address] then
      text =
        string.format(
        '%s$%.4X%s %.2x%s',
        text,
        address,
        symbol,
        u8('WRAM', address + slot),
        i % 4 == 0 and '\n' or ', '
      )
    else
      text = string.format('%s         %s', text, i % 4 == 0 and '\n' or '  ')
    end
  end
  draw.font['Uzebox8x12'](x, y + h, text, info_color)

  local x_txt,
    y_txt = x, y + h + 8 * 12
  sprite_tweaker_editor(slot, x_txt, y_txt)
end

function M:main()
  for slot, t in pairs(self.slot) do
    if spriteInfo[slot].status ~= 0 then
      local x = draw.AR_x * widget:get_property(string.format('M.slot[%d]', slot), 'x') or t.xpos
      local y = draw.AR_y * widget:get_property(string.format('M.slot[%d]', slot), 'y') or t.ypos

      self.display_info(x, y, slot)
    end
  end
end

return M
