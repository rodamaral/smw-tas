local M = {}

local gui, memory = _G.gui, _G.memory

local draw = require 'draw'
local config = require 'config'
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

local default = 0
local line = 1
local background = 2
local up_color = 3
local down_color = 4
local extra_color = 5
palette:set(default, -1) -- 0x100808080)
palette:set(line, COLOUR.block)
palette:set(background, 0x80ffff00)
palette:set(up_color, 0x80ff0000)
palette:set(down_color, 0x80ff00ff) -- remove
palette:set(extra_color, 0x806080d0) -- remove

bitmaps.slope45_up = gui.bitmap.new(32, 32, 2)
for x = 0, 15 do
    for y = 0, 15 do
        if x + y == 15 then
            for i = y, y + 10 do
                bitmaps.slope45_up:pset(2 * x, 2 * i, i == y and 0 or 1)
                bitmaps.slope45_up:pset(2 * x + 1, 2 * i, i == y and 0 or 1)
                bitmaps.slope45_up:pset(2 * x, 2 * i + 1, i == y and 0 or 1)
                bitmaps.slope45_up:pset(2 * x + 1, 2 * i + 1, i == y and 0 or 1)
            end
        end
    end
end

bitmaps.slope45_down = copy_flip_bitmap(bitmaps.slope45_up)

bitmaps.slope26_up = gui.bitmap.new(32, 2 * 8, 2)
for x = 0, 15 do
    for y = 0, 7 do
        if math.floor(x / 2) + y == 7 then
            for i = y, 8 do
                bitmaps.slope26_up:pset(2 * x, 2 * i, i == y and 0 or 1)
                bitmaps.slope26_up:pset(2 * x + 1, 2 * i, i == y and 0 or 1)
                bitmaps.slope26_up:pset(2 * x, 2 * i + 1, i == y and 0 or 1)
                bitmaps.slope26_up:pset(2 * x + 1, 2 * i + 1, i == y and 0 or 1)
            end
        end
    end
end

bitmaps.slope26_down = copy_flip_bitmap(bitmaps.slope26_up)

-- 14 degrees
bitmaps.slope14_up = gui.bitmap.new(32, 2 * 4, 2)
for x = 0, 15 do
    for y = 0, 15 + 10 do
        if math.floor(x / 4) + y == 3 then
            for i = y, 4 do
                bitmaps.slope14_up:pset(2 * x, 2 * i, i == y and 0 or 1)
                bitmaps.slope14_up:pset(2 * x + 1, 2 * i, i == y and 0 or 1)
                bitmaps.slope14_up:pset(2 * x, 2 * i + 1, i == y and 0 or 1)
                bitmaps.slope14_up:pset(2 * x + 1, 2 * i + 1, i == y and 0 or 1)
            end
        end
    end
end

bitmaps.slope14_down2 = copy_flip_bitmap(bitmaps.slope14_up)

bitmaps.slope14_up2 = gui.bitmap.new(32, 2 * (12 - 1), 2)
for x = 0, 15 do
    for y = 0, 15 + 10 do
        if math.floor(x / 4) + y == 3 then
            for i = y, y + 7 do
                bitmaps.slope14_up2:pset(2 * x, 2 * i, i == y and 0 or 1)
                bitmaps.slope14_up2:pset(2 * x + 1, 2 * i, i == y and 0 or 1)
                bitmaps.slope14_up2:pset(2 * x, 2 * i + 1, i == y and 0 or 1)
                bitmaps.slope14_up2:pset(2 * x + 1, 2 * i + 1, i == y and 0 or 1)
            end
        end
    end
end

bitmaps.slope14_down = copy_flip_bitmap(bitmaps.slope14_up2)

bitmaps.ceiling26_up = gui.bitmap.new(32, 16, 2)
for x = 0, 15 do
    for y = 0, 7 do
        if math.floor(x / 2) + y == 7 then
            for i = 0, y do
                bitmaps.ceiling26_up:pset(2 * x, 2 * i, i == y and 0 or 3)
                bitmaps.ceiling26_up:pset(2 * x + 1, 2 * i, i == y and 0 or 3)
                bitmaps.ceiling26_up:pset(2 * x, 2 * i + 1, i == y and 0 or 3)
                bitmaps.ceiling26_up:pset(2 * x + 1, 2 * i + 1, i == y and 0 or 3)
            end
        end
    end
end

-- Map 16 drawings per tile

-- simple floor
M[0x100] = function(left, top) gui.solidrectangle(2 * left, 2 * top, 2 * 16, 2 * 8, 0x80ffff00) end
for i = 0x101, 0x110 do M[i] = M[0x100] end

-- solid blocks
-- 111 - 16d
M[0x2b] = function(left, top) gui.solidrectangle(2 * left, 2 * top, 2 * 16, 2 * 16, 0xa00000ff) end
for i = 0x111, 0x16d do M[i] = M[0x2b] end

-- 14° slope up (1/4)
M[0x16e] = function(left, top) bitmaps.slope14_up:draw(2 * left, 2 * (top + 12), palette) end
for i = 0x16f, 0x172 do M[i] = M[0x16e] end

-- 14° slope up (2/4)
M[0x173] = function(left, top) bitmaps.slope14_up:draw(2 * left, 2 * (top + 8), palette) end
for i = 0x174, 0x177 do M[i] = M[0x173] end

-- 14° slope up (3/4)
M[0x178] = function(left, top) bitmaps.slope14_up2:draw(2 * left, 2 * (top + 4), palette) end
for i = 0x179, 0x17c do M[i] = M[0x178] end

-- 14° slope up (4/4)
M[0x17d] = function(left, top) bitmaps.slope14_up2:draw(2 * left, 2 * top, palette) end
for i = 0x17e, 0x181 do M[i] = M[0x17d] end

-- 14° slope down (1/4)
M[0x182] = function(left, top) bitmaps.slope14_down:draw(2 * left, 2 * top, palette) end
for i = 0x183, 0x186 do M[i] = M[0x182] end

-- 14° slope down (2/4)
M[0x187] = function(left, top) bitmaps.slope14_down:draw(2 * left, 2 * (top + 4), palette) end
for i = 0x188, 0x18b do M[i] = M[0x187] end

-- 14° slope down (3/4)
M[0x18c] = function(left, top) bitmaps.slope14_down2:draw(2 * left, 2 * (top + 8), palette) end
for i = 0x18d, 0x190 do M[i] = M[0x18c] end

-- 14° slope down (4/4)
M[0x191] = function(left, top) bitmaps.slope14_down2:draw(2 * left, 2 * (top + 12), palette) end
for i = 0x192, 0x195 do M[i] = M[0x191] end

-- 26.5° slope up (1/2)
M[0x196] = function(left, top) bitmaps.slope26_up:draw(2 * left, 2 * (top + 8), palette) end
for i = 0x197, 0x19a do M[i] = M[0x196] end
M[0x1d2] = M[0x196]

-- 26.5° slope up (2/2)
M[0x19b] = function(left, top) bitmaps.slope26_up:draw(2 * left, 2 * top, palette) end
for i = 0x19c, 0x19f do M[i] = M[0x19b] end
M[0x1d3] = M[0x19b]

-- 26.5° slope down (1/2)
M[0x1a0] = function(left, top) bitmaps.slope26_down:draw(2 * left, 2 * top, palette) end
for i = 0x1a1, 0x1a4 do M[i] = M[0x1a0] end
M[0x1d4] = M[0x1a0]

-- 26.5° slope down (2/2)
M[0x1a5] = function(left, top) bitmaps.slope26_down:draw(2 * left, 2 * (top + 8), palette) end
for i = 0x1a6, 0x1a9 do M[i] = M[0x1a5] end
M[0x1d5] = M[0x1a5]

-- 45° slope up
M[0x1aa] = function(left, top) bitmaps.slope45_up:draw(2 * left, 2 * top, palette) end
M[0x1ab] = M[0x1aa]
M[0x1ac] = M[0x1aa]
M[0x1ad] = M[0x1aa]
M[0x1ae] = M[0x1aa]
M[0x1b4] = M[0x1aa]
M[0x1c0] = M[0x1aa]
M[0x1c1] = M[0x1aa]
M[0x1c4] = M[0x1aa]
M[0x1c7] = M[0x1aa]
M[0x1ce] = M[0x1aa]
M[0x1d1] = M[0x1aa]
M[0x1d6] = M[0x1aa]

-- 45° slope down
M[0x1af] = function(left, top) bitmaps.slope45_down:draw(2 * left, 2 * top, palette) end
M[0x1b0] = M[0x1af]
M[0x1b1] = M[0x1af]
M[0x1b2] = M[0x1af]
M[0x1b3] = M[0x1af]
M[0x1b5] = M[0x1af]
M[0x1c2] = M[0x1af]
M[0x1c3] = M[0x1af]
M[0x1c5] = M[0x1af]
M[0x1c6] = M[0x1af]
M[0x1cf] = M[0x1af]
M[0x1d0] = M[0x1af]
M[0x1d7] = M[0x1af]

-- 26° ceiling up
M[0x1c8] = function(left, top)
    gui.solidrectangle(2 * left, 2 * top, 2 * 16, 2 * 8, up_color)
    bitmaps.ceiling26_up:draw(2 * left, 2 * (top + 8), palette)
end

M[0x1c9] = function(left, top) bitmaps.ceiling26_up:draw(2 * left, 2 * top, palette) end

-- 63.4° slope up (1/2)
M[0x1cb] = function(left, top) draw.line(left, top + 15, left + 8, top, 2, COLOUR.block) end

-- 63.4° slope down (2/2)
M[0x1ca] = function(left, top) draw.line(left + 8, top + 15, left + 15, top, 2, COLOUR.block) end

-- Backgrounds
M[0x1d8] = function(left, top) gui.text(2 * left + 8, 2 * top, 'Up', 'white', -1, 0) end
for i = 0x1d9, 0x1fa do M[i] = M[0x1d8] end

-- Lava
M[0x1fb] = function(left, top) gui.text(2 * left, 2 * top, 'Lava', 'red', -1, 0) end
for i = 0x1fc, 0x1ff do M[i] = M[0x1fb] end

-- refactor
-- debugging functions
-- get the map16 properties of tile (x, y)
local function get_map16_value(x, y)
    if x < 0 or y < 0 then return end

    local horizontal_mode = memory.readbyte('WRAM', 0x5b) % 2 == 0
    local max_x, max_y
    if horizontal_mode then
        max_x = 16 * memory.readbyte('WRAM', 0x5e) + 15
        max_y = 27 - 1
    else
        max_x = 32 - 1
        max_y = 16 * memory.readbyte('WRAM', 0x5f) + 15
    end

    if x > max_x or y > max_y then return end

    local index, kind
    if horizontal_mode then
        index = 16 * 27 * math.floor(x / 16) + 16 * y + x % 16
    else
        local nx = math.floor(x / 16)
        local ny = math.floor(y / 16)
        local n = 2 * ny + nx
        index = 16 * 16 * n + 16 * (y % 16) + x % 16
    end

    if index <= 0x37ff then
        kind = 256 * memory.readbyte('WRAM', 0x1c800 + index) +
               memory.readbyte('WRAM', 0xc800 + index)
        return kind
    end
end

function M.display_known_tiles()
    local camera_x = memory.readword('WRAM', 0x1462)
    local camera_y = memory.readword('WRAM', 0x1464)

    local x_origin, y_origin = math.floor(camera_x / 16), math.floor(camera_y / 16)
    for x = x_origin, x_origin + 16 do
        for y = y_origin, y_origin + 14 do
            local _, _, kind = get_map16_value(x, y)

            if kind and M[kind] then
                local f = M[kind]
                local left = 16 * x - camera_x
                local top = 16 * y - camera_y

                if false and 0x1de <= kind and kind <= 0x1fa then
                    local _, _, previous = get_map16_value(x, y - 1)
                    print('previous:', x, y, previous)
                    if previous then f(left, top, previous) end
                else
                    f(left, top)
                end
            end
        end
    end
end

-- test
local offset = memory.readdword('WRAM', 0x82)
local size = 0x6a
local map16_offset = 0x16e

local t = {}

for i = 0, size - 1 do
    local index = memory.readsbyte('BUS', offset + i)
    local offset2 = 0xe632 + 16 * index
    local height = memory.readbyte('BUS', 0xe51c + index)

    local tmp = gui.bitmap.new(16, 16, default)

    for x = 0, 15 do
        local value = memory.readsbyte('BUS', offset2 + x)
        local ceiling_flag = value < 0
        local ypoint = ceiling_flag and -value - 1 or value

        for y = 0, 15 do
            if ceiling_flag then
                local push_up, push_down
                if y < ypoint and ypoint - height <= y then push_down = true end
                if y - value < height then push_up = true end

                if push_up or push_down then
                    local color = (push_up and push_down and extra_color) or
                                  (push_up and background) or down_color
                    tmp:pset(x, y, color)
                end
            else
                if y > ypoint and ypoint + height >= y then
                    tmp:pset(x, y, background)
                end
            end
        end

        tmp:pset(x, ypoint, ceiling_flag and up_color or down_color)
    end
    t[i] = gui.bitmap.new(32, 32, default)
    t[i]:blit_scaled(0, 0, tmp, 0, 0, 32, 32, 2, 2)

    M[map16_offset + i] = function(left, top) t[i]:draw(2 * left, 2 * top, palette) end
end

---[[
for i = 0, size - 1 do
    local index = memory.readsbyte('BUS', offset + i)
    local offset2 = 0xe632 + 16 * index
    local height = memory.readbyte('BUS', 0xe51c + index)

    local tmp = gui.bitmap.new(16, 3 * 16, default)

    for x = 0, 15 do
        local value = memory.readsbyte('BUS', offset2 + x)
        local ceiling_flag = value < 0
        local ypoint = ceiling_flag and -value - 1 or value

        for y = 0, 47 do
            if ceiling_flag then
                local push_up, push_down
                if y < ypoint and ypoint - height <= y then push_down = true end
                if y - value < height then push_up = true end

                if push_up or push_down then
                    local color = (push_up and push_down and extra_color) or
                                  (push_up and background) or down_color
                    tmp:pset(x, y + 16, color)
                end
            else
                if y > ypoint and ypoint + height > y then
                    tmp:pset(x, y + 16, background)
                end
            end
        end

        tmp:pset(x, ypoint + 16, ceiling_flag and up_color or down_color)
    end
    t[i] = gui.bitmap.new(32, 3 * 32, default)
    t[i]:blit_scaled(0, 0, tmp, 0, 0, 32, 32, 2, 2)

    M[map16_offset + i] = function(left, top) t[i]:draw(2 * left, 2 * (top - 16), palette) end
end
-- ]]

--[[ EXTENDED TILES
local down = {}
for i = 0, size - 1 do
  local index = memory.readsbyte("BUS", offset + i)
  local offset2 = 0xe632 + 16*index
  local height = memory.readbyte("BUS", 0xe51c + index)

  local tmp = gui.bitmap.new(16, 16, default)

  for x = 0, 15 do
    local value = memory.readsbyte("BUS", offset2 + x)
    local ceiling_flag = value < 0
    local ypoint = ceiling_flag and - value - 1 or value

    for y = 0, 15 do
      if ceiling_flag then
        local push_up, push_down
        if y < ypoint and ypoint - height <= y then
          push_down = true
        end
        if y - value < height then
          push_up = true
        end

        if push_up or push_down then
          local color = (push_up and push_down and extra_color) or (push_up and background) or down_color
          tmp:pset(x, y - 16, color)
        end
      else
        if y > ypoint and ypoint + height >= y then
          tmp:pset(x, y - 16, background)
        end
      end
    end

    tmp:pset(x, ypoint - 16, ceiling_flag and up_color or down_color)
  end
  down[i] = gui.bitmap.new(32, 32, default)
  down[i]:blit_scaled(0, 0, tmp, 0, 0, 32, 32, 2, 2)
end
--]]
--[[ Backgrounds (COPY)
M[0x1d8] = function(left, top, copy)
  print("mod 1d8>", copy)
  down[copy - 0x16e]:draw(2*left, 2*top, palette)
end
for i = 0x1d9, 0x1fa do M[i] = M[0x1d8] end
--]]
return M

-- TODO:
-- 1b6 - 1bf
