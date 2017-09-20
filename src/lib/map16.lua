local mod = {}

local draw = require "lsnes.draw"
local config = require "config"
local COLOUR = config.COLOUR

local bitmaps = {}
local palette = gui.palette.new()

local function copy_flip_bitmap(src)
  local width, height = src:size()
  local dest = gui.bitmap.new(width, height)

  for x = 0, width - 1 do
    for y = 0, height - 1 do
      local pixel = src:pget(x, y)
      dest:pset(width - x - 1, y, pixel)
    end
  end

  return dest
end

palette:set(0, COLOUR.block)
palette:set(1, 0x80ffff00)
--palette:set(3, 0x00ff00) -- remove


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

bitmaps.slope45_down = copy_flip_bitmap(bitmaps.slope45_up)

bitmaps.slope26_up = gui.bitmap.new(32, 2*8, 3)
for x = 0, 15 do
  for y = 0, 7 do
    if math.floor(x/2) + y == 7 then
      for i = y, 8 do
        bitmaps.slope26_up:pset(2*x, 2*i, i == y and 0 or 1)
        bitmaps.slope26_up:pset(2*x + 1, 2*i, i == y and 0 or 1)
        bitmaps.slope26_up:pset(2*x, 2*i + 1, i == y and 0 or 1)
        bitmaps.slope26_up:pset(2*x + 1, 2*i + 1, i == y and 0 or 1)
      end
    end
  end
end

bitmaps.slope26_down = copy_flip_bitmap(bitmaps.slope26_up)

-- 14 degrees
bitmaps.slope14_up = gui.bitmap.new(32, 2*4, 3)
for x = 0, 15 do
  for y = 0, 15 + 10 do
    if math.floor(x/4) + y == 3 then
      for i = y, 4 do
        bitmaps.slope14_up:pset(2*x, 2*i, i == y and 0 or 1)
        bitmaps.slope14_up:pset(2*x + 1, 2*i, i == y and 0 or 1)
        bitmaps.slope14_up:pset(2*x, 2*i + 1, i == y and 0 or 1)
        bitmaps.slope14_up:pset(2*x + 1, 2*i + 1, i == y and 0 or 1)
      end
    end
  end
end

bitmaps.slope14_down2 = copy_flip_bitmap(bitmaps.slope14_up)

bitmaps.slope14_up2 = gui.bitmap.new(32, 2*(12 - 1), 3)
for x = 0, 15 do
  for y = 0, 15 + 10 do
    if math.floor(x/4) + y == 3 then
      for i = y, y + 7 do
        bitmaps.slope14_up2:pset(2*x, 2*i, i == y and 0 or 1)
        bitmaps.slope14_up2:pset(2*x + 1, 2*i, i == y and 0 or 1)
        bitmaps.slope14_up2:pset(2*x, 2*i + 1, i == y and 0 or 1)
        bitmaps.slope14_up2:pset(2*x + 1, 2*i + 1, i == y and 0 or 1)
      end
    end
  end
end

bitmaps.slope14_down = copy_flip_bitmap(bitmaps.slope14_up2)


-- Map 16 drawings per tile

-- simple floor
mod[0x100] = function(left, top)
  gui.solidrectangle(2*(left + 1), 2*(top + 1), 2*(16 - 2), 2*(8 - 1), 0x80ffff00)
end
for i = 0x101, 0x110 do
  mod[i] = mod[0x100]
end

-- solid blocks
-- 111 - 16d

-- 14° slope up (1/4)
mod[0x170] = function(left, top)
  bitmaps.slope14_up:draw(2*left, 2*(top + 12), palette)
end
mod[0x171] = mod[0x170]
mod[0x172] = mod[0x170]

-- 14° slope up (2/4)
mod[0x173] = function(left, top)
  bitmaps.slope14_up:draw(2*left, 2*(top + 8), palette)
end
for i = 0x174, 0x177 do mod[i] = mod[0x173] end

-- 14° slope up (3/4)
mod[0x178] = function(left, top)
  bitmaps.slope14_up2:draw(2*left, 2*(top + 4), palette)
end
for i = 0x179, 0x17c do mod[i] = mod[0x178] end

-- 14° slope up (4/4)
mod[0x17d] = function(left, top)
  bitmaps.slope14_up2:draw(2*left, 2*top, palette)
end
for i = 0x17e, 0x181 do mod[i] = mod[0x17d] end

-- 14° slope down (1/4)
mod[0x182] = function(left, top)
  bitmaps.slope14_down:draw(2*left, 2*top, palette)
end
for i = 0x183, 0x186 do mod[i] = mod[0x182] end

-- 14° slope down (2/4)
mod[0x187] = function(left, top)
  bitmaps.slope14_down:draw(2*left, 2*(top + 4), palette)
end
for i = 0x188, 0x18b do mod[i] = mod[0x187] end

-- 14° slope down (3/4)
mod[0x18c] = function(left, top)
  bitmaps.slope14_down2:draw(2*left, 2*(top + 8), palette)
end
for i = 0x18d, 0x190 do mod[i] = mod[0x18c] end

-- 14° slope down (4/4)
mod[0x191] = function(left, top)
  bitmaps.slope14_down2:draw(2*left, 2*(top + 12), palette)
end
for i = 0x192, 0x195 do mod[i] = mod[0x191] end

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
  bitmaps.slope26_up:draw(2*left, 2*(top + 8), palette)
end
for i = 0x197, 0x19a do mod[i] = mod[0x196] end

-- 26.5° slope up (2/2)
mod[0x19b] = function(left, top)
  bitmaps.slope26_up:draw(2*left, 2*top, palette)
end
for i = 0x19c, 0x19f do mod[i] = mod[0x19b] end

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
