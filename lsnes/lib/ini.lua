-- ini files encoder/decoder
local INI = {}

local lua_general = require "lua-general"

function INI.arg_to_string(value)
    local str
    if type(value) == "string" then
        str = "\"" .. value .. "\""
    elseif type(value) == "number" or type(value) == "boolean" or value == nil then
        str = tostring(value)
    elseif type(value) == "table" then
        local tmp = {"{"}  -- only arrays
        for a, b in ipairs(value) do
            table.insert(tmp, ("%s%s"):format(INI.arg_to_string(b), a ~= #value and ", " or "")) -- possible stack overflow
        end
        table.insert(tmp, "}")
        str = table.concat(tmp)
    else
        str = "#BAD_VALUE"
    end
    
    return str
end

-- creates the string for ini
function INI.data_to_string(data)
	local sections = {}
    
	for section, prop in pairs(data) do
        local properties = {}
		
        for key, value in pairs(prop) do
            table.insert(properties, ("%s = %s\n"):format(key, INI.arg_to_string(value)))  -- properties
		end
        
        table.sort(properties)
        table.insert(sections, ("[%s]\n"):format(section) .. table.concat(properties) .. "\n")
	end
    
    table.sort(sections)
    return table.concat(sections)
end

function INI.string_to_data(value)
    local data
    
    if tonumber(value) then
        data = tonumber(value)
    elseif value == "true" then
        data = true
    elseif value == "false" then
        data = false
    elseif value == "nil" then
        data = nil
    else
        local quote1, text, quote2 = value:match("(['\"{])(.+)(['\"}])")  -- value is surrounded by "", '' or {}?
        if quote1 and quote2 and text then
            if (quote1 == '"' or quote1 == "'") and quote1 == quote2 then
                data = text
            elseif quote1 == "{" and quote2 == "}" then
                local tmp = {} -- test
                for words in text:gmatch("[^,%s]+") do
                    tmp[#tmp + 1] = INI.string_to_data(words) -- possible stack overflow
                end
                
                data = tmp
            else
                data = value
            end
        else
            data = value
        end
    end
    
    return data
end

function INI.load(filename)
    local file = io.open(filename, "r")
    if not file then return false end
    
    local data, section = {}, nil
    
	for line in file:lines() do
        local new_section = line:match("^%[([^%[%]]+)%]$")
		
        if new_section then
            section = INI.string_to_data(new_section) and INI.string_to_data(new_section) or new_section
            if data[section] then print("Duplicated section") end
			data[section] = data[section] or {}
        else
            
            local prop, value = line:match("^([%w_%-%.]+)%s*=%s*(.+)%s*$")  -- prop = value
            
            if prop and value then
                value = INI.string_to_data(value)
                prop = INI.string_to_data(prop) and INI.string_to_data(prop) or prop
                
                if data[section] == nil then print(prop, value) ; error("Property outside section") end
                data[section][prop] = value
            else
                local ignore = line:match("^;") or line == ""
                if not ignore then
                    print("BAD LINE:", line, prop, value)
                end
            end
            
        end
        
	end
    
	file:close()
    return data
end

function INI.retrieve(filename, data)
    if type(data) ~= "table" then error"data must be a table" end
    local data, previous_data = lua_general.copytable(data), nil
    
    -- Verifies if file already exists
    if lua_general.file_exists(filename) then
        ini_data = INI.load(filename)
    else return data
    end
    
    -- Adds previous values to the new ini
    local union_data = lua_general.mergetable(data, ini_data)
    return union_data
end

function INI.overwrite(filename, data)
    local file, err = assert(io.open(filename, "w"), "Error loading file :" .. filename)
    if not file then print(err) ; return end
    
	file:write(INI.data_to_string(data))
	file:close()
end

function INI.save(filename, data)
    if type(data) ~= "table" then error"data must be a table" end
    
    local tmp, previous_data
    if lua_general.file_exists(filename) then
        previous_data = INI.load(filename)
        tmp = lua_general.mergetable(previous_data, data)
    else
        tmp = data
    end
    
    INI.overwrite(filename, tmp)
end

function INI.save_options()
    local file, data = INI.filename, INI.raw_data
    if not file or not data then print"save_options: <file> and <data> required!"; return end
    INI.save(file, data)
end

return INI