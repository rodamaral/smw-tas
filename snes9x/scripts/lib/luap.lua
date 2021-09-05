-- General purpose lua extension
local luap = {}

function luap.get_emulator_name()
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

function luap.file_exists(name)
    local f = io.open(name, 'r')
    if f ~= nil then
        io.close(f)
        return true
    else
        return false
    end
end

function luap.unrequire(mod)
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
luap.copytable = copytable

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
luap.mergetable = mergetable

-- Creates a set from a list
function luap.make_set(list)
    local set = {}
    for _, l in ipairs(list) do
        set[l] = true
    end
    return set
end

-- Sum of the digits of a integer
function luap.sum_digits(number)
    local sum = 0
    while number > 0 do
        sum = sum + number % 10
        number = math.floor(number * 0.1)
    end

    return sum
end

-- Returns the exact chosen digit of a number from the left to the right or from the right to the left, in a given base
-- E.g.: read_digit(654321, 2, 10, "left to right") -> 5; read_digit(0x4B7A, 3, 16, "right to left") -> 3
function luap.read_digit(number, digit, base, direction)
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

    local result = math.floor(number / base ^ exponent) % base
    return result
end

-- verify whether a point is inside a rectangle
function luap.inside_rectangle(xpoint, ypoint, x1, y1, x2, y2)
    -- From top-left to bottom-right
    if x2 < x1 then
        x1, x2 = x2, x1
    end
    if y2 < y1 then
        y1, y2 = y2, y1
    end

    if xpoint >= x1 and xpoint <= x2 and ypoint >= y1 and ypoint <= y2 then
        return true
    else
        return false
    end
end

-- unsigned to signed (based in <bits> bits)
function luap.signed16(num)
    local maxval = 32768
    if num < maxval then
        return num
    else
        return num - 2 * maxval
    end
end

-- Returns a table of arguments from string, according to pattern
-- the default [pattern] splits the arguments separated with spaces
function luap.get_arguments(arg, pattern)
    if not arg or arg == '' then
        return
    end
    pattern = pattern or '%S+'

    local list = {}
    for word in string.gmatch(arg, pattern) do
        list[#list + 1] = word
    end

    local unpack = table.unpack or unpack -- Lua compatibility
    return unpack(list)
end

-- Transform the binary representation of base into a string
-- For instance, if each bit of a number represents a char of base, then this function verifies what chars are on
function luap.decode_bits(data, base)
    local i = 1
    local size = base:len()
    local direct_concatenation = size <= 45 -- Performance: I found out that the .. operator is faster for 45 operations or less
    local result

    if direct_concatenation then
        result = ''
        for ch in base:gmatch '.' do
            if bit.test(data, size - i) then
                result = result .. ch
            else
                result = result .. ' '
            end
            i = i + 1
        end
    else
        result = {}
        for ch in base:gmatch '.' do
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

if math.type then
    function luap.is_integer(num)
        return math.type(num) == 'integer'
    end
else
    function luap.is_integer(num)
        return num % 1 == 0
    end
end

return luap
