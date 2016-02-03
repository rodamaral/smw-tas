-- General purpose lua extension
local lua_general = {}

function lua_general.file_exists(name)
   local f = io.open(name, "r")
   if f ~= nil then io.close(f) return true else return false end
end

function lua_general.unrequire(mod)
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
lua_general.copytable = copytable

local function mergetable(source, t2)
    for key, value in pairs(t2) do
    	if type(value) == "table" then
    		if type(source[key] or false) == "table" then
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
lua_general.mergetable = mergetable

-- Creates a set from a list
function lua_general.make_set(list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
    return set
end

-- Sum of the digits of a integer
function lua_general.sum_digits(number)
    local sum = 0
    while number > 0 do
        sum = sum + number%10
        number = math.floor(number*0.1)
    end
    
    return sum
end

-- unsigned to signed (based in <bits> bits)
function lua_general.signed(num, bits)
    local maxval = 1<<(bits - 1)
    if num < maxval then return num else return num - 2*maxval end
end

return lua_general
