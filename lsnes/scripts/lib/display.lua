local M = {}

local smw = require 'game.smw'

local SMW = smw.constant
local GOOD_SPRITES_CLIPPING = smw.GOOD_SPRITES_CLIPPING

M.sprite_hitbox = {} -- keeps track of what sprite slots must display the hitbox

for key = 0, SMW.sprite_max - 1 do
  M.sprite_hitbox[key] = {}
  for number = 0, 0xff do
    M.sprite_hitbox[key][number] = {['sprite'] = true, ['block'] = GOOD_SPRITES_CLIPPING[number]}
  end
end

return M
