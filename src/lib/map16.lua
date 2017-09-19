local mod = {}

local draw = require "lsnes.draw"
local config = require "config"
local COLOUR = config.COLOUR

local bitmaps = {}
local palette = gui.palette.new()

palette:set(0, COLOUR.block)
palette:set(1, 0x80ffff00)

bitmaps.slope45_up = gui.bitmap.new(32, 32 + 10*2, 2)
for x = 0, 15 do
  for y = 0, 15 + 10 do
    if x + y == 15 then
      for i = 0, 10 do
        bitmaps.slope45_up:pset(2*x, 2*y + 2*i, i == 0 and 0 or 1)
        bitmaps.slope45_up:pset(2*x + 1, 2*y + 2*i, i == 0 and 0 or 1)
        bitmaps.slope45_up:pset(2*x, 2*y + 2*i + 1, i == 0 and 0 or 1)
        bitmaps.slope45_up:pset(2*x + 1, 2*y + 2*i + 1, i == 0 and 0 or 1)
      end
    end
  end
end

bitmaps.slope45_down = gui.bitmap.new(32, 32 + 10*2, 2)
for x = 0, 15 do
  for y = 0, 15 + 10 do
    if x == y then
      for i = 0, 10 do
        bitmaps.slope45_down:pset(2*x, 2*y + 2*i, i == 0 and 0 or 1)
        bitmaps.slope45_down:pset(2*x + 1, 2*y + 2*i, i == 0 and 0 or 1)
        bitmaps.slope45_down:pset(2*x, 2*y + 2*i + 1, i == 0 and 0 or 1)
        bitmaps.slope45_down:pset(2*x + 1, 2*y + 2*i + 1, i == 0 and 0 or 1)
      end
    end
  end
end

bitmaps.slope26_up = gui.bitmap.new(32, 32 + 10*2, 2)
for x = 0, 15 do
  for y = 0, 15 + 10 do
    if math.floor(x/2) + y == 15 then
      for i = 0, 8 do
        bitmaps.slope26_up:pset(2*x, 2*y + 2*i, i == 0 and 0 or 1)
        bitmaps.slope26_up:pset(2*x + 1, 2*y + 2*i, i == 0 and 0 or 1)
        bitmaps.slope26_up:pset(2*x, 2*y + 2*i + 1, i == 0 and 0 or 1)
        bitmaps.slope26_up:pset(2*x + 1, 2*y + 2*i + 1, i == 0 and 0 or 1)
      end
    end
  end
end

bitmaps.slope26_down = gui.bitmap.new(32, 32 + 10*2, 2)
for x = 0, 15 do
  for y = 0, 15 + 10 do
    if math.floor(x/2) == y then
      for i = 0, 8 do
        bitmaps.slope26_down:pset(2*x, 2*y + 2*i, i == 0 and 0 or 1)
        bitmaps.slope26_down:pset(2*x + 1, 2*y + 2*i, i == 0 and 0 or 1)
        bitmaps.slope26_down:pset(2*x, 2*y + 2*i + 1, i == 0 and 0 or 1)
        bitmaps.slope26_down:pset(2*x + 1, 2*y + 2*i + 1, i == 0 and 0 or 1)
      end
    end
  end
end

-- Map 16 drawings per tile
-- 45° slope up
mod[0x1aa] = function(left, top)
  bitmaps.slope45_up:draw(2*left, 2*top, palette)
end
mod[0x1ab] = mod[0x1aa]
mod[0x1ac] = mod[0x1aa]
mod[0x1ad] = mod[0x1aa]
mod[0x1ae] = mod[0x1aa]
mod[0x1c0] = mod[0x1aa]
mod[0x1c1] = mod[0x1aa]
mod[0x1c4] = mod[0x1aa]
mod[0x1c7] = mod[0x1aa]

-- 45° slope down
mod[0x1af] = function(left, top)
  bitmaps.slope45_down:draw(2*left, 2*top, palette)
end
mod[0x1b0] = mod[0x1af]
mod[0x1b1] = mod[0x1af]
mod[0x1b2] = mod[0x1af]
mod[0x1b3] = mod[0x1af]
mod[0x1c2] = mod[0x1af]
mod[0x1c3] = mod[0x1af]
mod[0x1c5] = mod[0x1af]
mod[0x1c6] = mod[0x1af]

-- 26.5° slope up (1/2)
mod[0x196] = function(left, top)
  bitmaps.slope26_up:draw(2*left, 2*top, palette)
end
mod[0x197] = mod[0x196]
mod[0x199] = mod[0x196]
mod[0x19a] = mod[0x196]

-- 26.5° slope up (2/2)
mod[0x19b] = function(left, top)
  bitmaps.slope26_up:draw(2*left, 2*(top - 8), palette)
end
mod[0x19c] = mod[0x19b]
mod[0x19e] = mod[0x19b]
mod[0x19f] = mod[0x19b]

-- 26.5° slope down (1/2)
mod[0x1a0] = function(left, top)
  bitmaps.slope26_down:draw(2*left, 2*top, palette)
end
mod[0x1a4] = mod[0x1a0]

-- 26.5° slope down (2/2)
mod[0x1a5] = function(left, top)
  bitmaps.slope26_down:draw(2*left, 2*(top + 8), palette)
end
mod[0x1a9] = mod[0x1a5]

-- 63.4° slope up (1/2)
mod[0x1cb] = function(left, top)
  draw.line(left, top + 15, left + 8, top, 2, COLOUR.block)
end

-- 63.4° slope down (2/2)
mod[0x1ca] = function(left, top)
  draw.line(left + 8, top + 15, left + 15, top, 2, COLOUR.block)
end

return mod
