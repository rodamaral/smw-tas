local M = {}

local create_command = _G.create_command
local gui, memory, memory2 = _G.gui, _G.memory, _G.memory2

local argparse = require "argparse"
local cheat = require('cheat')
local config = require('config')
local lsnes = require('lsnes')
local luap = require('luap')
local mem = require('memory')
local misc = require('game.sprites.miscsprite')
local smw = require('game.smw')
local state = require('game.state')
local tile = require('game.tile')
local poke = require('poke')

local fmt = string.format
local u8 = mem.u8
local w8 = mem.w8
local w16 = mem.w16
local w24 = mem.w24
local WRAM = smw.WRAM
local SMW = smw.constant
local OPTIONS = config.OPTIONS
local system_time = luap.system_time
local store = state.store

-- Private constants
--[[ TODO: ?
RTC, DSPRAM, DSPPROM, DSPDROM,
BUS, PTRTABLE, CPU_STATE, PPU_STATE, SMP_STATE, DSP_STATE, BSXFLASH,
BSX_RAM, BSX_PRAM, SLOTA_ROM, SLOTB_ROM, SLOTA_RAM, SLOTB_RAM, GBCPU_STATE, ]]
local WRITE_REGIONS = luap.make_set {'WRAM', 'APURAM', 'VRAM', 'OAM', 'CGRAM', 'SRAM'}
local READ_REGIONS = luap.make_set {'WRAM', 'APURAM', 'VRAM', 'OAM', 'CGRAM', 'SRAM', 'ROM'}

local USAGE_HELP = {}

USAGE_HELP.read = 'Usage:\nread [region+]<address>[+offset-offsetEnd]\n' ..
                  'region: name of the memory domain (defaults to WRAM)\n' ..
                  'address: hexadecimal value of the address within the domain\n' ..
                  'offset: optional hexadecimal value added to address\n' ..
                  'offsetEnd: optional hexadecimal value added to the later\n' .. 'examples:\n' ..
                  'read WRAM+13\t-->\treads WRAM\'s $13\n' .. 'read OAM+8C\t-->\treads OAM\'s $8C\n' ..
                  'read SRAM+10+A\t-->\treads SRAM\'s $1A\n' ..
                  'read 100+8-A\t-->\treads WRAM\'s $108 to $10A\n\n'

USAGE_HELP.poke = 'Usage:\npoke [region+]<address>[+offset-offsetEnd] <value>\n' ..
                  'region: name of the memory domain (defaults to WRAM)\n' ..
                  'address: hexadecimal value of the address within the domain\n' ..
                  'offset: optional hexadecimal value added to address\n' ..
                  'offsetEnd: optional hexadecimal value added to the later\n' ..
                  'value: decimal or hexadecimal value to be poked into all previous addresses\n' ..
                  'examples:\n' .. 'poke WRAM+13 10\t-->\tmakes WRAM\'s $13 be #$0A\n' ..
                  'poke OAM+8C -10\t-->\tmakes OAM\'s $8C be #$F6\n' ..
                  'poke SRAM+10+A 0\t-->\tmakes SRAM\'s $1A be #$00\n' ..
                  'poke 100+8-A 0x30\t-->\tmakes WRAM\'s $108 to $10A be #$30\n\n'

USAGE_HELP.create_sprite = 'Usage:\ncreate-sprite <id> [slot, [x, [y]]]\n' ..
                           'example: create-sprite 0x2F 3 200 300\n' ..
                           '\tcreates a Springboard into slot 3 at position (x, y)\n' ..
                           'example: create-sprite 0x4A\n' ..
                           '\tcreates a Goal Point Question Sphere into highest available slot near the itembox\n\n'

-- Private functions
local function get_args(arguments)
    local words = { [-1] = 'lua', [0] = 'foo.lua' }
    for word in arguments:gmatch("%S+") do table.insert(words, word) end
    return words
end

local function command_wrapper(arguments, parser_fn, success_fn)
    local arg_list = get_args(arguments)

    local only_help = false
    local parser = argparse()

    -- avoid the default help behavior of os.exit
    parser:add_help {
       action = function()
        only_help = true
       print(parser:get_help())
   end
    }
    parser_fn(parser)

    local success, result = parser:pparse(arg_list)

    if success then
        success_fn(result)
    elseif not only_help then
        print(only_help, result)
        print(parser:get_usage())
    end
end

local function parseMemoryValue(arg)
    local value = tonumber(arg)
    if value then
        return value % 0x100
    else
        return false, 'error: no value'
    end
end

local function parseMemoryRegion(arg, valid)
    -- Get region: defaults to WRAM if no region is supplied
    local address
    local region = string.match(arg, '^(%u+)%+.')

    if not region then
        region = 'WRAM'
        address = arg
    else
        region = string.upper(region)
        if valid[region] then
            address = string.match(arg, '^%u+%+(.+)')
        else
            local validStr = luap.concatKeys(valid, ', ')
            local error = string.format('Illegal region: %s.\nValid ones: %s.', region, validStr)
            return false, false, error
        end
    end
    return region, address
end

local function parseMemoryAddress(arg)
    local address, start, finish
    if tonumber(arg, 16) then
        address = tonumber(arg, 16)
        return address, address
    elseif string.match(arg, '^(%x+)%+(%x+)$') then
        address, start = string.match(arg, '^(%x+)%+(%x+)$')
        address, start = tonumber(address, 16), tonumber(start, 16)
        return address + start, address + start
    elseif string.match(arg, '^(%x+)%+(%x+)%-(%x+)$') then
        address, start, finish = string.match(arg, '^(%x+)%+(%x+)%-(%x+)$')
        address, start, finish = tonumber(address, 16), tonumber(start, 16), tonumber(finish, 16)
        if start > finish then
            return false, false, '\nstart offset must not be bigger than end offset'
        end
        return address + start, address + finish
    else
        return false, false, 'error parsing address expression'
    end
end

-- Methods:
M.clock = create_command('clock', function(arguments)
    local function parser_fn(parser)
        parser:argument("time", "Decimal clock time.")
            :convert(math.tointeger)
        parser:option("-s --sub", "Subsecond time.")
            :convert(math.tointeger)
    end

    local function success_fn(result)
        local time = result.time
        local subsecond = result.sub

        poke.clock(time, subsecond)
        gui.repaint()
    end

    command_wrapper(arguments, parser_fn, success_fn)
end)

M['delete-sprite'] = create_command('delete-sprite', function(arguments)
    local function parser_fn(parser)
        parser:option("-s --slot", "Slot number of sprite. Might be higher than the maximum.")
            :convert(math.tointeger)
            :count('*')
        parser:option("-t --type", "Type of sprite.")
            :convert(math.tointeger)
            :count('*')
    end

    local function success_fn(result)
        local slots = luap.make_set(result.slot)
        local sprite_type = luap.make_set(result.type)
        print(slots, sprite_type)

        poke.delete_sprites(slots, sprite_type)
        gui.repaint()
    end

    command_wrapper(arguments, parser_fn, success_fn)
end)

M.help = create_command('help', function()
    print('List of valid commands:')
    for _, value in pairs(M) do print('>', value) end
    print('Enter a specific command to know about its arguments.')
    print(
    'Cheat-commands edit the memory and may cause desyncs. So, be careful while recording a movie.')
    return
end)

M.get_property = create_command('get', function(arg)
    local value = OPTIONS[arg]
    if value == nil then
        print(string.format('This option %q doesn\'t exit.', value))
    else
        print(value)
    end
end)

M.set_property = create_command('set', function(arg)
    local property, value = luap.get_arguments(arg)

    if not (property and value) then
        print('Usage:\tsmw-tas set <property> <value>')
        print('\twhere the property and the value are valid options in the config file')
        print('\tnumbers, booleans and nil are converted.')
    else
        if value == 'true' then value = true end
        if value == 'false' then value = false end
        if value == 'nil' then value = nil end
        if tonumber(value) then value = tonumber(value) end

        OPTIONS[property] = value
        print(string.format('Setting option %q to value %q.', property, value))
        config.save_options()
        gui.repaint()
    end
end)

M.miscsprite = create_command('misc', function(arg)
    local list = luap.get_numeric_arguments(arg)
    misc.filter_table(list)
    gui.repaint()
end)

M.score = create_command('score', function(num) -- TODO: apply cheat to Luigi
    local is_hex = num:sub(1, 2):lower() == '0x'
    num = tonumber(num)

    if not num or not luap.is_integer(num) or num < 0 or num > 9999990 or
    (not is_hex and num % 10 ~= 0) then
        print('Enter a valid score: hexadecimal representation or decimal ending in 0.')
        return
    end

    num = is_hex and num or num / 10
    w24(WRAM.mario_score, num)

    print(fmt('Cheat: score set to %d0.', num))
    gui.status('Cheat(score):', fmt('%d0 at frame %d/%s', num, lsnes.Framecount, system_time()))
    cheat.is_cheating = true
    gui.repaint()
end)

M.coin = create_command('coin', function(num)
    num = tonumber(num)

    if not num or not luap.is_integer(num) or num < 0 or num > 99 then
        print('Enter a valid integer.')
        return
    end

    w8(WRAM.player_coin, num)

    print(fmt('Cheat: coin set to %d.', num))
    gui.status('Cheat(coin):', fmt('%d0 at frame %d/%s', num, lsnes.Framecount, system_time()))
    cheat.is_cheating = true
    gui.repaint()
end)

M.powerup = create_command('powerup', function(num)
    num = tonumber(num)

    if not num or not luap.is_integer(num) or num < 0 or num > 255 then
        print('Enter a valid integer.')
        return
    end

    w8(WRAM.powerup, num)

    print(fmt('Cheat: powerup set to %d.', num))
    gui.status('Cheat(powerup):', fmt('%d at frame %d/%s', num, lsnes.Framecount, system_time()))
    cheat.is_cheating = true
    gui.repaint()
end)

M.itembox = create_command('item', function(num)
    num = tonumber(num)

    if not num or not luap.is_integer(num) or num < 0 or num > 255 then
        print('Enter a valid integer.')
        return
    end

    w8(WRAM.item_box, num)

    print(fmt('Cheat: item box set to %d.', num))
    gui.status('Cheat(item):', fmt('%d at frame %d/%s', num, lsnes.Framecount, system_time()))
    cheat.is_cheating = true
    gui.repaint()
end)

M.position = create_command('position', function(arg)
    local x, y = luap.get_arguments(arg)
    local x_sub, y_sub

    x, x_sub = luap.get_arguments(x, '[^.,]+') -- all chars, except '.' and ','
    y, y_sub = luap.get_arguments(y, '[^.,]+')
    x = x and tonumber(x)
    y = y and tonumber(y)

    if not x and not y and not x_sub and not y_sub then
        print('Enter a valid pair <x.subpixel y.subpixel> or a single coordinate.')
        print(
        'Examples: \'position 160.4 220\', \'position 360.ff\', \'position _ _.0\', \'position none.0, none.f\'')
        return
    end

    print(x_sub)
    if x_sub then
        local size = x_sub:len() -- convert F to F0, for instance
        x_sub = tonumber(x_sub, 16)
        x_sub = size == 1 and 0x10 * x_sub or x_sub
    end
    if y_sub then
        local size = y_sub:len()
        y_sub = tonumber(y_sub, 16)
        y_sub = size == 1 and 0x10 * y_sub or y_sub
    end

    if x then w16(WRAM.x, x) end
    if x_sub then w8(WRAM.x_sub, x_sub) end
    if y then w16(WRAM.y, y) end
    if y_sub then w8(WRAM.y_sub, y_sub) end

    local strx, stry
    if x and x_sub then
        strx = fmt('%d.%.2x', x, x_sub)
    elseif x then
        strx = fmt('%d', x)
    elseif x_sub then
        strx = fmt('previous.%.2x', x_sub)
    else
        strx = 'previous'
    end

    if y and y_sub then
        stry = fmt('%d.%.2x', y, y_sub)
    elseif y then
        stry = fmt('%d', y)
    elseif y_sub then
        stry = fmt('previous.%.2x', y_sub)
    else
        stry = 'previous'
    end

    print(fmt('Cheat: position set to (%s, %s).', strx, stry))
    gui.status('Cheat(position):',
               fmt('to (%s, %s) at frame %d/%s', strx, stry, lsnes.Framecount, system_time()))
    cheat.is_cheating = true
    gui.repaint()
end)

M.xspeed = create_command('xspeed', function(arg)
    local speed, subspeed = luap.get_arguments(arg, '[^.,]+') -- all chars, except '.' and ','
    print(arg, speed, subspeed)
    speed = speed and tonumber(speed)
    subspeed = subspeed and tonumber(subspeed, 16)

    if not speed or not luap.is_integer(speed) or speed < -128 or speed > 127 then
        print('speed: enter a valid integer [-128, 127].')
        return
    end
    if subspeed then
        if not luap.is_integer(subspeed) or subspeed < 0 or speed >= 0x100 then
            print('subspeed: enter a valid integer [00, FF].')
            return
        elseif subspeed ~= 0 and speed < 0 then -- negative speeds round to floor
            speed = speed - 1
            subspeed = 0x100 - subspeed
        end
    end

    w8(WRAM.x_speed, speed)
    print(fmt('Cheat: horizontal speed set to %+d.', speed))
    if subspeed then
        w8(WRAM.x_subspeed, subspeed)
        print(fmt('Cheat: horizontal subspeed set to %.2x.', subspeed))
    end

    gui.status('Cheat(xspeed):', fmt('%d.%s at frame %d/%s', speed, subspeed or 'xx',
                                     lsnes.Framecount, system_time()))
    cheat.is_cheating = true
    gui.repaint()
end)

M.yspeed = create_command('yspeed', function(num)
    num = tonumber(num)

    if not num or not luap.is_integer(num) or num < -128 or num > 127 then
        print('Enter a valid integer [-128, 127].')
        return
    end

    w8(WRAM.y_speed, num)

    print(fmt('Cheat: vertical speed set to %d.', num))
    gui.status('Cheat(yspeed):', fmt('%d at frame %d/%s', num, lsnes.Framecount, system_time()))
    cheat.is_cheating = true
    gui.repaint()
end)

M.stun = create_command('stun', function(num)
    num = tonumber(num)

    if not num then
        print('Usage: stun <number slot>')
        print('Make current sprite on slot <slot> be in the stunned state')
        return
    elseif not luap.is_integer(num) or num < 0 or num >= SMW.sprite_max then
        print(string.format('Enter a valid integer [0 ,%d].', SMW.sprite_max - 1))
        return
    end

    w8(WRAM.sprite_status + num, 9)
    w8(WRAM.sprite_stun_timer + num, 0x1f)

    print(fmt('Cheat: stunning sprite slot %d.', num))
    gui.status('Cheat(stun):', fmt('slot %d at frame %d/%s', num, lsnes.Framecount, system_time()))
    cheat.is_cheating = true
    gui.repaint()
end)

M.swallow = create_command('swallow', function(num)
    num = tonumber(num)

    if not num then
        print('Usage: swallow <number slot>')
        print('Make the visible Yoshi, if any, swallow the current sprite on slot <slot>')
        return
    elseif not luap.is_integer(num) or num < 0 or num >= 0x100 then
        print('Enter a valid integer [0, 255].')
        return
    end

    local yoshi_id = smw.get_yoshi_id()
    if not yoshi_id then print('Couldn\'t find any Yoshi. Aborting...') end

    w8(WRAM.swallow_timer, 0xff)
    w8(WRAM.sprite_misc_160e + yoshi_id, num)

    print(fmt('Cheat: swallowing sprite slot %d.', num))
    gui.status('Cheat(swallow):',
               fmt('slot %d at frame %d/%s', num, lsnes.Framecount, system_time()))
    cheat.is_cheating = true
    gui.repaint()
end)

M.read_address = create_command('read', function(arg)
    print('> read ' .. arg)

    local arg_region = luap.get_arguments(arg)
    assert(arg_region, USAGE_HELP.read)

    local region, arg_address, errorRegion = parseMemoryRegion(arg_region, READ_REGIONS)
    assert(region, errorRegion)

    local start, finish, errorAddress = parseMemoryAddress(arg_address)
    assert(start, errorAddress)

    print(string.format('%4s| hex unsigned signed  id', region))
    local count = 0
    local size = memory2[region]:info().size
    for i = start, finish do
        if i >= size then break end

        local value = memory.readbyte(region, i)
        print(string.format('$%.4x: %.2x      %3d   %+4d   %d', i, value, value,
                            luap.signed8(value), count))
        count = count + 1
    end
end)

M.poke_address = create_command('poke', function(arg)
    print('> poke ' .. arg)

    local arg_region, arg_value = luap.get_arguments(arg)

    assert(arg_region, USAGE_HELP.poke)

    local value, errorValue = parseMemoryValue(arg_value)
    assert(value, errorValue)

    local region, arg_address, errorRegion = parseMemoryRegion(arg_region, WRITE_REGIONS)
    assert(region, errorRegion)

    local start, finish, errorAddress = parseMemoryAddress(arg_address)
    assert(start, errorAddress)

    local message = string.format('Poking #$%.2x into %s: from $%x to $%x', value, region, start,
                                  finish)
    local size = memory2[region]:info().size
    for i = start, finish do
        if i >= size then break end
        memory.writebyte(region, i, value)
    end

    cheat.is_cheating = true
    print(message)
    gui.status('Cheat(poke):', message)
    gui.repaint()
end)

M.create_sprite = create_command('create-sprite', function(arg)
    print('> create-sprite ' .. arg)

    local id, slot, x, y = luap.get_arguments(arg)

    id = id and tonumber(id)
    slot = slot and tonumber(slot)
    x = x and tonumber(x) or store.Camera_x + 0x78
    y = y and tonumber(y) or store.Camera_y

    assert(id, USAGE_HELP.create_sprite)

    if not slot then
        for i = SMW.sprite_max - 1, 0, -1 do
            if u8(WRAM.sprite_status + i) == 0 then
                slot = i
                break
            end
        end
    end
    assert('No slot is available')

    poke.create_sprite(id, slot, x, y)
    cheat.is_cheating = true
    local message = string.format('id = %.2x slot = %d', id, slot)
    print(message)
    gui.status('Cheat(create-sprite)', message)
    gui.repaint()
end)

M.dragon_coin = create_command('dragon', function(_)
    local tiles = tile.read_layer1_region()

    for i = 0, #tiles do if tiles[i] == 0x2e or tiles[i] == 0x2d then print(i, tiles[i]) end end

    print('\n Size of region:', #tiles + 1)
end)

M.toggle_decimal_hex_display = create_command('toggle_decimal_hex_display', function()
    OPTIONS.prefer_decimal_format = not OPTIONS.prefer_decimal_format
    gui.repaint()
end)

-- commands: left-gap, right-gap, top-gap and bottom-gap
for _, name in pairs {'left', 'right', 'top', 'bottom'} do
    M['window_' .. name .. '_gap'] = create_command(name .. '-gap', function(arg)
        local value = luap.get_arguments(arg)
        if not value then
            print('Enter a valid argument: ' .. name .. '-gap <value>')
            return
        end

        value = tonumber(value)
        if not luap.is_integer(value) then
            print('Enter a valid argument: ' .. name .. '-gap <value>')
            return
        elseif value < 0 or value > 8192 then
            print(name .. '-gap: value must be [0, 8192]')
            return
        end

        OPTIONS[name .. '_gap'] = value
        gui.repaint()
        config.save_options()
    end)
end

return M
