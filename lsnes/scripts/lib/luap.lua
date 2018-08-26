-- General purpose lua extension
local M = {}

local unpack = _G.unpack
local utime,
  bit = _G.utime, _G.bit
local lsnes_features,
  bizstring,
  snes9x = _G.lsnes_features, _G.bizstring, _G.snes9x

function M.get_emulator_name()
  if lsnes_features then
    return 'lsnes'
  elseif bizstring then
    return 'BizHawk'
  elseif snes9x then
    return 'Snes9x'
  else
    return nil
  end
end

function M.file_exists(name)
  local f = io.open(name, 'r')
  if f ~= nil then
    io.close(f)
    return true
  else
    return false
  end
end

function M.unrequire(mod)
  package.loaded[mod] = nil
  _G[mod] = nil
end

local function copytable(orig)
  local orig_type = type(orig)
  local copy
  if orig_type == 'table' then
    copy = {}
    for orig_key, orig_value in next, orig, nil do
      copy[copytable(orig_key)] = copytable(orig_value) -- possible stack overflow
    end
    setmetatable(copy, copytable(getmetatable(orig)))
  else -- number, string, boolean, etc
    copy = orig
  end
  return copy
end
M.copytable = copytable

local function mergetable(source, t2)
  for key, value in pairs(t2) do
    if type(value) == 'table' then
      if type(source[key] or false) == 'table' then
        mergetable(source[key] or {}, t2[key] or {}) -- possible stack overflow
      else
        source[key] = value
      end
    else
      source[key] = value
    end
  end
  return source
end
M.mergetable = mergetable

function M.concatKeys(obj, sep)
  local list = {}
  for key in pairs(obj) do
    if type(key) == 'string' or type(key) == 'number' or type(key) == 'boolean' then
      list[#list + 1] = key
    end
  end

  return table.concat(list, sep)
end

-- Creates a set from a list
function M.make_set(list)
  local set = {}
  for _, l in ipairs(list) do
    set[l] = true
  end
  return set
end

-- Sum of the digits of a integer
function M.sum_digits(number)
  local sum = 0
  while number > 0 do
    sum = sum + number % 10
    number = math.floor(number * 0.1)
  end

  return sum
end

-- Returns the exact chosen digit of a number from the left to the right or from the right to the left, in a given base
-- E.g.: read_digit(654321, 2, 10, "left to right") -> 5; read_digit(0x4B7A, 3, 16, "right to left") -> 3
function M.read_digit(number, digit, base, direction)
  if number == 0 then
    return 0
  end -- exception

  local copy = number
  local digits_total = 0
  while copy >= 1 do
    copy = math.floor(copy / base)
    digits_total = digits_total + 1
  end

  if digit > digits_total then
    return false
  end

  local exponent
  if direction == 'left to right' then
    exponent = digits_total - digit
  elseif direction == 'right to left' then
    exponent = digit - 1
  end

  local result = math.floor(number / base ^ (exponent)) % base
  return result
end

-- verify whether a point is inside a rectangle
function M.inside_rectangle(xpoint, ypoint, x1, y1, x2, y2)
  -- From top-left to bottom-right
  if x2 < x1 then
    x1,
      x2 = x2, x1
  end
  if y2 < y1 then
    y1,
      y2 = y2, y1
  end

  if xpoint >= x1 and xpoint <= x2 and ypoint >= y1 and ypoint <= y2 then
    return true
  else
    return false
  end
end

function M.signed8(num)
  local maxval = 0x80
  if num < maxval then
    return num
  else
    return num - 2 * maxval
  end
end

function M.signed16(num)
  local maxval = 0x8000
  if num < maxval then
    return num
  else
    return num - 2 * maxval
  end
end

function M.unsigned8(num)
  local maxval = 0x80
  if num >= 0 then
    return num
  else
    return 2 * maxval + num
  end
end

function M.unsigned16(num)
  local maxval = 0x8000
  if num >= 0 then
    return num
  else
    return 2 * maxval + num
  end
end

-- Returns a table of arguments from string, according to pattern
-- the default [pattern] splits the arguments separated with spaces
function M.get_arguments(arg, pattern)
  if not arg or arg == '' then
    return
  end
  pattern = pattern or '%S+'

  local list = {}
  for word in string.gmatch(arg, pattern) do
    list[#list + 1] = word
  end

  local _unpack = table.unpack or unpack -- Lua compatibility
  return _unpack(list)
end

-- Transform the binary representation of base into a string
-- For instance, if each bit of a number represents a char of base, then this function verifies what chars are on
function M.decode_bits(data, base)
  local i = 1
  local size = base:len()
  -- Performance: I found out that the .. operator is faster for 45 operations or less
  local direct_concatenation = size <= 45
  local result

  if direct_concatenation then
    result = ''
    for ch in base:gmatch('.') do
      if bit.test(data, size - i) then
        result = result .. ch
      else
        result = result .. ' '
      end
      i = i + 1
    end
  else
    result = {}
    for ch in base:gmatch('.') do
      if bit.test(data, size - i) then
        result[i] = ch
      else
        result[i] = ' '
      end
      i = i + 1
    end
    result = table.concat(result)
  end

  return result
end

-- Returns the local time of the OS
-- lsnes only! TODO: separate all emulator specific functions
function M.system_time()
  local epoch = os.date('*t', utime()) -- time since UNIX epoch converted to OS time
  local hour = epoch.hour
  local minute = epoch.min
  local second = epoch.sec

  return string.format('%.2d:%.2d:%.2d', hour, minute, second)
end

if math.type then
  function M.is_integer(num)
    return math.type(num) == 'integer'
  end
else
  function M.is_integer(num)
    return num % 1 == 0
  end
end

return M
