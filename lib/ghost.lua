-- TO CONFIG THE GHOST FILES TO BE USED, CHECK THE config.ini > OPTION "ghost_dump_files"
local mod = {}

local POST_LOAD_FLAG = false
local Palette
local GHOST_FOLDER = LUA_SCRIPT_FOLDER and LUA_SCRIPT_FOLDER .. "ghosts/" or "ghosts/"
local draw = require "draw"
local lsnes = require "lsnes"
local MOVIE = lsnes.MOVIE
local luap = require "luap"
local config = require "config"

-- Ghost definitions
ghost_dumps = {}  -- actual files, to be set later

-- Timing options
sync_mode    = "realtime"
display_mode = "realtime"
offset_mode  = "room" -- or continuous, but looks strange
delay_mode   = { "room", "continuous" }

--
ghost_hitbox = false
own_hitbox   = false -- AMARAT: buggy yet
enemy_hitbox = false
--
show_status = true

-- Graphics options
own_color = 0xffffff
ghost_color = { 0xff0000, 0xff, 0xff00, 0xff8000, 0, 0xff00ff, 0xffff00, 0xffa0a0, 0xffffff, 0xffff }
enemy_color = 0xffff00
--
ghost_gfx    = 1 --{ 1, 1, 1 } -- nil to turn off. Array to specify individually
pose_info = { { "smwdb.png", "smwdb.map", 0x40, 0x60, 0x10, 0x18 } }

-- Main parameters end here -----------------------------------

-- Variables that must be saved in savestates
last_igframe = 0 -- Used to find out if this frame should be skipped
last_room    = 0
last_transition = { 0, 0, 0} -- Used for room sync: room, frame, igframe
fcount = 0 -- Frames since script start. Used in place of movie.framecount
igframecount = 0 -- count of ingame frames
igtmp = 0 -- last value of the single byte ingame frame count of the game
buf = { }

-- The main function. It is run every frame.
function main()
   frame = framecount()
   tmp = memory.readbyte("WRAM", 0x0014)
   room = get_room()

    display()
    fcount = fcount + 1
   last_igframe = igframe()
   if room ~= last_room then
      -- Hack: For some reason these offsets are needed.
      -- I need to understand why, and fix the problem at the root
      last_transition = { last_room, frame, igframe() }
   end
   if igtmp ~= tmp then
      igtmp = tmp
      igframecount = igframecount + 1
   end
   last_room = room
   sx = memory.readsword("WRAM", 0x001a)
   sy = memory.readsword("WRAM", 0x001c)
   buf[2] = buf[1]
   buf[1] = buf[0]
   buf[0] = fillbuf()

    -- Prevent memory leaks
    if MOVIE.current_frame%100 == 0 then
        collectgarbage()
    end
end

function update_screen()
   room = get_room()
   for index, ghost in ipairs(ghosts) do -- AMARAT: removed the 'repeat' statement
      -- Hack: We have an off by one error due to recorder and player
      -- running at different stages. This results in the ghosts being
      -- one frame ahead of the rest (I think that's the reason anyway).
      -- Fix it by tweaking the framecount manually:
      -- Edit: Not needed for smw so far
      local sframe  = syncframe() + (POST_LOAD_FLAG and 1 or 0)
      local gframe  = sync2frame(sframe, ghost)
      local osframe = offset(sframe, ghost)
      local ogframe = osframe and sync2frame(osframe, ghost)

      for i, delay in ipairs(delay_mode) do
            local doff, doff2  = tardiness[i](sframe,ghost)

         if doff then draw_delay(ghost,(doff2 or doff)-sframe, index, i) end
      end

      -- Do not apply the offset on the overworld:
      if in_overworld() then ogframe, osframe = gframe, sframe end

      if(ogframe and room == ghost.data[ogframe].room) then
         if ghost_hitbox then draw_ghost_hitbox(ghost, ogframe) end
         if ghost.gfx then draw_ghost_gfx(ghost, ogframe) end
      end
   end

   if own_hitbox then draw_own_hitbox() end
   if enemy_hitbox then draw_enemy_hitbox() end
end

-- Main data table. An array of tables for each ghost.
-- Each ghost has the following entries:
-- Offset: scalar, number of sync frames to shift by
-- Framenums: array, translates from sync frames to real frames
-- Transitions: dictionary of { from, to } -> array of real frames,
--              from and two might have to be encoded as strings or
--              put into one number (need 5 bytes, and double should
--              provide enough
-- Data: frame -> x, y, region, roomx, roomy, pose
-- Gfx: Scalar. Which of the gfx sets this ghost uses
ghosts = {}
pose_data = {}
SAVESTORAGE = {} -- AMARAT

function mod.init()
    print"Starting ghost script"

    -- Load files
    assert(config.OPTIONS.ghost_dump_files or type(config.OPTIONS.ghost_dump_files) ~= "table",
    'config.ini > "ghost_dump_files" is malconfigured')
    for id, path in ipairs(config.OPTIONS.ghost_dump_files) do
        local complete_path = GHOST_FOLDER .. path
        if luap.file_exists(complete_path) then
            if complete_path:find(".dump?") then
                ghost_dumps[#ghost_dumps + 1] = complete_path
            else
                print("Ignoring file", path) -- debug
            end
        else
            print(string.format("WARNING: couldn't open ghost file %s", complete_path))
        end
    end

   set_sync(sync_mode)
   set_display(display_mode)
   set_offset(offset_mode)
   set_tardiness(delay_mode)
   for i,filename in ipairs(ghost_dumps) do
      local ghost = readghost(filename)
      ghost.gfx = tabnum(ghost_gfx, i)
      ghost.color = tabnum(ghost_color, i)
      table.insert(ghosts, ghost)
   end
   if ghost_gfx then for i,info in ipairs(pose_info) do
      table.insert(pose_data, readposes(info))
   end end

   -- Set up saves
    callback.post_save:register(function(name, is_savestate)
        if is_savestate then
            local last_offset = {}
            for index, ghost in ipairs(ghosts) do table.insert(last_offset, ghost.prev) end

            SAVESTORAGE[name] = {last_igframe, last_room, last_transition[1], last_transition[2],
            last_transition[3],fcount, igframecount, igtmp, buf, last_offset}
        end
   end)

    callback.post_load:register(function(name, is_savestate)
        if is_savestate and SAVESTORAGE[name] then
            local last_offset
            last_igframe, last_room, last_transition[1], last_transition[2], last_transition[3], fcount, igframecount, igtmp, buf, last_offset = table.unpack(SAVESTORAGE[name])
            for index, ghost in ipairs(ghosts) do ghost.prev = last_offset[index] end

            POST_LOAD_FLAG = true
            gui.repaint()
        end
   end)

   callback.paint:register(function(authentic)
        if POST_LOAD_FLAG then  -- hack
            main()
            POST_LOAD_FLAG = false
        end
        
        update_screen()
        
        --[[ DEBUG
        gui.text(2, 432, string.format("Garbage %.3fMB", collectgarbage("count")/1024))
        local pose = memory.readbyte("WRAM", 0x13e0)
        drawpose(ghosts[1], pose, "mario_small", 40, 40)
        --]]
    end)

    main()
    gui.repaint()
    print"Ghost script ready!"
end

function readghost(filename)
   local ghost = {}
   local pattern = "^%s*(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)%s+(%d+)"
   ghost.offset = 0
   ghost.prev   = 0
   ghost.data = {}
   io.stderr:write(string.format("Reading %s ", filename))
   for line in io.lines(filename) do
      local e = {}
      local ig, mode, area, ahelp, power, pose, dir, ydir, cape, on_yoshi, ypose, x, y
      _,_,ig, mode, area, ahelp, power, pose, dir, ydir, cape, on_yoshi,
         ypose, x,y, subx, suby, vx, vy = string.find(line, pattern)
      e.room = join_room(tonumber(mode), tonumber(area), tonumber(ahelp))
      e.igframe, e.power, e.pose, e.dir, e.ydir, e.cape, e.on_yoshi, e.ypose,
         e.x, e.y, e.subx, e.suby, e.vx, e.vy = tonumber(ig), tonumber(power),
         tonumber(pose), tonumber(dir), tonumber(ydir), tonumber(cape),
         tonumber(on_yoshi), tonumber(ypose), sword(tonumber(x)), sword(tonumber(y)),
         tonumber(subx), tonumber(suby), s7(tonumber(vx)), s7(tonumber(vy))

      table.insert(ghost.data,e)
   end
   -- Now extract the information we want
   io.stderr:write("[sync]")
   ghost.syncframes = build_sync(ghost)
   io.stderr:write("[transitions]")
   ghost.transitions = build_transitions(ghost)
   io.stderr:write("[positions]")
   ghost.positions = build_positions(ghost)
   io.stderr:write("\n")

   return ghost
end

function tabnum(something, index)
   if type(something) == "table" then
      return something[index]
   else
      return something
   end
end

function make_frame2sync(key)
   if key == "real" or key == "realtime" then
      return function(rframe, ghost) return rframe end
   elseif key == "game" or key == "ingame" then
      return function(rframe, ghost) return ghost.data[rframe].igframe end
   end
end

function make_sync2frame(key)
   return function(frame, ghost) return ghost.syncframes[frame] end
end

function framecount()
    lsnes.EMU.get_movie_info()
   return MOVIE.current_frame
end

function igframe()
   return igframecount
end

function make_syncframe(key)
   if key == "real" or key == "realtime" then
      return framecount
   elseif key == "game" or key == "ingame" then
      return igframe
   end
end

function make_display(key)
   if key == "real" or key == "realtime" then
      return function() return true end
   elseif key == "game" or key == "ingame" then
      return function() return igframe() ~= last_igframe end
   end
end

function make_offset(key)
   if key == "none" then
      return function(sframe, ghost) return sframe end
   elseif key == "room" then
      return function(sframe, ghost)
         local last_room, last_frame = get_last_trans()
         local t = find_transition(ghost, last_room, room, last_frame)
         return t and sframe - last_frame + t
      end
   elseif key == "continuous" then
      return find_nearest2
   end
end

function make_last_trans(key)
   if key == "real" or key == "realtime" then
      return function() return last_transition[1], last_transition[2] end
   elseif key == "game" or key == "ingame" then
      return function() return last_transition[1], last_transition[3] end
   end
end

function nsync(ghost) return #ghost.syncframes end

function nframe(ghost) return #ghost.data end
room_offset = make_offset("room")

function set_sync(mode)
   frame2sync = make_frame2sync(mode)
   sync2frame = make_sync2frame(mode)
   syncframe  = make_syncframe(mode)
   get_last_trans = make_last_trans(mode)
end

function set_display(mode)
   display    = make_display(mode)
end

function set_offset(mode)
   offset     = make_offset(mode)
end

function set_tardiness(modes)
   tardiness = {}
   for index, delay in ipairs(modes) do
      tardiness[index] = make_offset(delay)
   end
end

-- This assumes that igframe changes by a step of +1 only
function build_sync(ghost)
   local res = {}
   local last = 0
   for i = 1, nframe(ghost) do
      if frame2sync(i, ghost) ~= last then
         table.insert(res,i)
         last = frame2sync(i,ghost)
      end
   end
   return res
end

function get_room()
   mode = memory.readbyte("WRAM", 0x0100)
   if mode == 0xe then area, ahelp = memory.readbyte("WRAM", 0x1f11), 0
   elseif mode == 0x14 then area, ahelp = memory.readbyte("WRAM", 0x13bf), memory.readbyte("WRAM", 0x00ce) -- TODO: should be 3 bytes
   else area, ahelp = 0, 0 end
   return join_room(mode, area, ahelp)
end

function join_room(mode, area, ahelp)
    return (mode << 33) + (area << 24) + ahelp
end

function appendtrans(trans, from, to, frame)
   if not trans[from] then trans[from] = {} end
   if not trans[from][to] then trans[from][to] = {} end
   table.insert(trans[from][to], frame)
end

function gettrans(trans, from, to)
   return trans[from] and trans[from][to]
end

function build_transitions(ghost)
   local res = {}
   local last = 0
   for i = 1, nframe(ghost) do
      local new = ghost.data[i].room
      if last ~= new then
         appendtrans(res,last,new,i)
         last = new
      end
   end
   return res
end

function append_position(db, room, pix, frame)
   if not db[room] then db[room] = {} end
   if not db[room][pix] then db[room][pix] = {} end
   table.insert(db[room][pix], frame)
end

-- Build a database of [room][xpix][frames]
-- This will allow quick calculation of continuous offsets.
-- The database uses real frames, not sync frames.
function build_positions(ghost)
   local res = {}
   -- Loop through every pair of frame, next_frame
   -- and mark positions between them as belonging to this frame
   -- Offset by 3 to handle memory address delays of up to 2
   for i = 3, nframe(ghost)-1 do
      local room = ghost.data[i].room
      if ghost.data[i+1].room == room then
         -- positions change one frame too quickly, so -1
         local x1, x2 = ghost.data[i-1].x, ghost.data[i].x
         -- Too large changes indicate something strange is going on
         if math.abs(x1-x2) < 0x100 then
            if x2 > x1 then for x = x1, x2-1 do
               append_position(res, room, x, i) end
            elseif x1 > x2 then for x = x1, x2+1, -1 do
               append_position(res,room,x,i) end
            else
               -- When standing still a large number of frames will accumulate on that
               -- pixel. This will make those sections slow, but at least they are
               -- pretty rare.
               append_position(res,room,x1,i)
            end
         end
      end
   end
   return res
end

-- Find the transition closest to sync frame "near_sync"
-- May return nil
function find_transition(ghost, from, to, near_sync)
   if near_sync < 1 then return 0 end -- handle last frame
   local t = gettrans(ghost.transitions, from, to)
   local ns = math.min(near_sync,nsync(ghost))
   local near_frame = sync2frame(ns, ghost)
   if not t or not near_frame then return end
   local bi, bv = nil
   for i, f in ipairs(t) do
      local diff = math.abs(f-near_frame)
      if not bv or bv > diff then
         bv = diff
         bi = i
      end
   end
   return frame2sync(t[bi], ghost)
end

-- This version of find_nearest uses the pixel visit
-- database to do quick lookups. It will prefer matches
-- going in the correct direction and those closest to
-- the room one predicted from the room entry time
function find_nearest2(sframe, ghost)
   local room = get_room()
   local x = buf[0].x
   local sentry = room_offset(sframe, ghost)
   if not sentry or not buf[1] or not ghost.positions[room] or not ghost.positions[room][x] then
      return
   end
   local v = buf[1].vx
   local bestsf = 0
   for i, f in ipairs(ghost.positions[room][x]) do
      local s = frame2sync(f, ghost)
      if ghost.data[f-2].vx*v >= 0 and math.abs(sentry-s) < math.abs(sentry-bestsf) then
         bestsf = s
      end
   end
   -- Did we find a match?
   if bestsf > 0 then
      local sf, sf2 = calc_subframe(ghost, sframe, bestsf)
      ghost.prev = sf-sframe
      return sf, sf2
   end
   -- Apparently not. Try again without direction restriction
   for i, f in ipairs(ghost.positions[room][x]) do
      local s = frame2sync(f, ghost)
      if math.abs(sframe-s) < math.abs(sentry-bestsf) then bestsf = s end
   end
   if bestsf > 0 then
      local sf, sf2 = calc_subframe(ghost, sframe, bestsf)
      ghost.prev = sf-sframe
      return sf, sf2
   end
   -- Couldn't find anything. Don't display anything
end

-- Use speed to estimate subframe delay
function calc_subframe(ghost, sframe_player, sframe_ghost)
      local f1 = sync2frame(sframe_ghost, ghost)
      local f2 = sync2frame(sframe_ghost+1, ghost)
      local x1 = buf[0].x + buf[1].subx/0x100
      local x2 = ghost.data[f1-1].x + ghost.data[f1-2].subx/0x100
      local dx = x1-x2
      local v = ghost.data[f1-2].vx/0x10
      local dt = 0
      if math.abs(v) > 0 then dt = dx/v end
      return sframe_ghost, sframe_ghost+dt
end

-- Finds sync frame offset which brings ghost nearest to
-- current position (room, pos). Starts search from the last
-- sync frame offset: prev.
-- The search is linear, but since it stars from a (probably)
-- good position it should not be too expensive.
-- The player moves in discrete steps:
--
-- current '  '  '  *  '  '  '
-- ghost    '  '  1  2  '  '  '
--
-- We want to find a pair of ghost frames which
-- bracket the current position.
function find_nearest(sframe, ghost)
   local o,o2 = find_nearest_raw(ghost, ghost.prev)
   if o then ghost.prev = o return sframe+o,sframe+o2 end
   -- We failed. Reset search within current room
   local ro = room_offset(sframe, ghost)
   if ro then
      o,o2 = find_nearest_raw(ghost, ro-sframe)
      if o then ghost.prev = o return sframe+o,sframe+o2 end
   end
   -- We failed again. Assume previous offset is still valid
   return sframe + ghost.prev, sframe+ghost.prev
end

function find_nearest_raw(ghost, prev)
   local room = get_room()
   local startpoint = syncframe() + prev
   local startframe = sync2frame(startpoint, ghost)
   -- We must be in the same room, or our starting point isn't
   -- very good
   if not startframe then return end
   if not buf[1] or not buf[2] then return end
   if startframe <= 0 or startframe > nframe(ghost) then return end
   if ghost.data[startframe].room ~= room then return end
   for i = 0, 600 do
      -- Go through candidate f1-positions
      for j = 1, -1, -2 do
         local delta = i*j
         local s1 = startpoint + delta
         if s1 > 0 and s1 < nsync(ghost) then
            local s2 = s1+1
            local f1 = sync2frame(s1, ghost)
            local f2 = sync2frame(s2, ghost)
            -- Are we even in the correct room?
            -- Do we bracket the current position?
            -- Offset due to ghost x 1-frame delay
            -- We should include velocities in order to break the
            -- back/forward degeneracy.
            if ghost.data[f1].room == room and ghost.data[f2].room == room then
               --if ghost.data[f1-1].x == buf[0].x then return s1-syncframe(), s1-syncframe() end
               --if ghost.data[f2-1].x == buf[0].x then return s2-syncframe(), s1-syncframe() end
               if (ghost.data[f1-1].x-buf[0].x)*(ghost.data[f2-1].x-buf[0].x) <= 0 and
                     ghost.data[f1-2].vx * buf[1].vx >= 0 then
                  local x1 = buf[0].x + buf[1].subx/0x100
                  local x2 = ghost.data[f1-1].x + ghost.data[f1-2].subx/0x100
                  local dx = x1-x2
                  local v = ghost.data[f1-2].vx/0x10
                  local dt = 0
                  if math.abs(v) > 0 then dt = dx/v end
                  return s1-syncframe(), s1-syncframe()+dt
               end
            end
            -- No match so far
         end
      end
   end
   -- No match. Return nil
end

function readposes(info)
   local imgfile = info[1]
   local mapfile = info[2]
   local dx, dy = info[3], info[4]
   local res = {}
   local big
    big, Palette = gui.image.load_png(GHOST_FOLDER .. imgfile)

   if not big then print("Could not load ", GHOST_FOLDER .. imgfile) return res end
   local pattern = "^([%w_]+): (%x+)"
   local i = 0
   for line in io.lines(GHOST_FOLDER .. mapfile) do
      from,to,name,val = string.find(line, pattern)
      if not from then print("ignoring line "..i)
      else
         val = tonumber("0x"..val)
         if not res[name] then res[name] = {} end
         local small =  gui.bitmap.new(2*dx, 2*dy) --gd.create(dx,dy)
         --gd.copy(small, big, 0, 0, (i % 0x10)*dx, math.floor(i/0x10)*dy, dx, dy)
            small:blit(0, 0, big, 2*(i % 0x10)*dx, 2*math.floor(i/0x10)*dy, 2*dx, 2*dy)  -- AMARAT

            res[name][val] = small
      end
      i = i+1

   end

    big = nil
    Palette:adjust_transparency(88) -- 160

    collectgarbage()
   --print(string.format("Read %d poses", i))
   return res
end

function get_gfx(ghost)
   return pose_data[ghost.gfx], pose_info[ghost.gfx][3], pose_info[ghost.gfx][4], pose_info[ghost.gfx][5], pose_info[ghost.gfx][6]
end

in_overworld = function()
   local mode = memory.readbyte("WRAM", 0x0100)
   return mode == 0xe
end
in_level = function()
   local mode = memory.readbyte("WRAM", 0x0100)
   return mode == 0x14
end

sbyte = function(v) if v >= 0x80 then v = v - 0x100 end return v end
sword = function(v) if v >= 0x8000 then v = v - 0x10000 end return v end
s7 = function(v) if v >= 0x80 then v = v - 0x100 end return v end

draw_hitbox = function(box, sx, sy, color)
   if not box then return end
   gui.box(box[1]-sx,box[2]-sy,box[1]+box[3]-sx,box[2]+box[4]-sy,color)
end
function draw_own_hitbox_map()
   local rx = buf[0].x - buf[0].sx
   local ry = buf[0].y - buf[0].sy
   gui.box(rx-8, ry-8,rx+8,ry+8,own_color)
end
mario_hitbox = function(x, y, pose, power, yoshi)
   local foo = 1
   if power == 0 or pose == 0x3c or pose == 0x1d then foo = foo+1 end
   if yoshi > 0 then foo = foo+2 end
   local disp = { 0x06,0x14,0x10,0x18 }
   local height = { 0x1A,0x0C,0x20,0x18 }
   return { x+2,y+disp[foo],0xc,height[foo] }
end
-- Hackish fix of the problem introduced by not having a proper
-- model for the independent posisions of mario, his cape, and yoshi
function mario_offset_hack(pose, power, yoshi)
   if yoshi == 0 then return 0, 0 end
   if pose == 0x3c or pose == 0x1d then return 10, 10 end
   return 1, 6
end
get_enemy_hitbox = function(id)
   if not buf[0].enemy_state then return end
   local state = buf[0].enemy_state[id]
   local x, y = buf[0].enemy_x[id], buf[0].enemy_y[id]
   local clip = buf[0].enemy_clip[id]
   local ox = memory.readsbyte(0x03B56C+clip+0)
   local wx = memory.readbyte(0x03b5a8+clip+0)
   local oy = memory.readsbyte(0x03B5e4+clip+0)
   local wy = memory.readbyte(0x03b620+clip+0)
   if state == 0 or state == 7 then return end
   return { x+ox, y+oy, wx, wy }
end
function draw_own_hitbox_level()
   local yoshi, power, pose = memory.readbyte("WRAM", 0x187A),
      memory.readbyte("WRAM", 0x0019), memory.readbyte("WRAM", 0x13e0)
   local box = mario_hitbox(buf[0].x,buf[0].y,pose, power, yoshi)
   draw_hitbox(box,buf[1].sx,buf[1].sy,own_color)
end
function draw_own_hitbox()
   local mode = memory.readbyte("WRAM", 0x0100)
   if mode == 0xe then draw_own_hitbox_map()
   elseif mode == 0x14 then draw_own_hitbox_level() end
end

function draw_ghost_hitbox_map(ghost,frame)
   local d,i = ghost.data, frame
   gui.box(d[i-1].x-8-buf[0].sx, d[i-1].y-8-buf[0].sy,d[i-1].x+8-buf[0].sx,d[i-1].y+8-buf[0].sy,ghost.color)
end
function draw_ghost_hitbox_level(ghost,frame)
   if frame < 2 then return end
   local d,i = ghost.data, frame
   local box = mario_hitbox(d[i-1].x,d[i-1].y, d[i-2].pose, d[i-2].power, d[i-2].on_yoshi)
   draw_hitbox(box,buf[1].sx,buf[1].sy,ghost.color)
end
function draw_ghost_hitbox(ghost,frame)
   local mode = memory.readbyte("WRAM", 0x0100)
   if mode == 0xe then draw_ghost_hitbox_map(ghost,frame)
   elseif mode == 0x14 then draw_ghost_hitbox_level(ghost,frame) end
end

function draw_enemy_hitbox()
   local mode = memory.readbyte("WRAM", 0x0100)
   if mode ~= 0x14 then return end
   for i = 0, 11 do
      draw_hitbox(get_enemy_hitbox(i),buf[1].sx,buf[1].sy,enemy_color)
   end
end

function draw_delay(ghost,delay, index, which)
    draw.Font = "Uzebox6x8"
    local w, h = draw.font_width(), draw.font_height()
    local x, y = 0 + 8*(index - 1)*w, draw.Buffer_height or 448  -- EDIT: FIX IT

    if which == 1 then
        --draw.text(x, y + (which-2)*h, string.format("%8d", index), ghost.color)
        gui.solidrectangle(x, y + (which-1)*h, 8*w, 2*h, index%2 == 0 and 0xe0ff8080 or 0xe0ffffff)
    end
    draw.text(x, y + (which - 1)*h + 1, string.format("%7.1f", delay), ghost.color)
end

function drawpose(ghost,pose,name,rx,ry)
   local db, dx, dy, ox, oy = get_gfx(ghost)
   if rx and ry and db[name][pose] then
        db[name][pose]:draw(2*(rx-ox),2*(ry-oy), Palette) -- AMARAT
   end
end
function draw_ghost_gfx_level(ghost,frame)
   if frame < 3 or not ghost_gfx then return end
   if ghost.data[frame].room ~= get_room() then return end
   local d, i = ghost.data, frame
   --local rx, ry = d[i-1].x - buf[1].sx, d[i-1].y - buf[1].sy
    local rx, ry = d[i-1].x - buf[0].sx, d[i-1].y - buf[0].sy -- AMARAT TEST
   local om, oc = mario_offset_hack(d[i-2].pose, d[i-2].power,d[i-1].on_yoshi)
   if d[i-1].on_yoshi == 0 then mdir = d[i-2].dir else mdir = d[i-1].ydir end
   if d[i-2].power == 0 then
      which = "mario_small"
   elseif d[i-2].power == 1 or d[i-2].power == 2 then
      which = "mario_big"
   else which = "mario_fire" end
   -- gui.transparency(2)
   if d[i-1].on_yoshi > 0 then
      yoshi_pose = d[i-1].ypose + (d[i-1].ydir << 8)
      drawpose(ghost, yoshi_pose, "yoshi_below", rx, ry) end
   if d[i-2].power == 2 and (d[i-2].pose < 0x2a or d[i-2].pose > 0x2f) then
      cape_pose = d[i-2].cape + (d[i-2].dir << 8)
      if cape_pose % 0xff == 0 and d[i-1].on_yoshi > 0 and d[i-2].pose == 0x20 then
         cape_pose = 0x1000 + cape_pose
         cape_above = true
      else cape_above = false end
      do_cape = true
   else do_cape = false end
   if do_cape and not cape_above then
      drawpose(ghost, cape_pose, "cape", rx, ry+oc) end
   mario_pose = d[i-2].pose + (mdir << 8)
   drawpose(ghost, mario_pose, which, rx, ry+om)
   if do_cape and cape_above then
      drawpose(ghost, cape_pose, "cape", rx, ry+oc) end
   if d[i-1].on_yoshi > 0 then
      drawpose(ghost, yoshi_pose, "yoshi_above", rx, ry) end
   -- gui.transparency(0)
end
function draw_ghost_gfx_map(ghost,frame)
   if frame < 3 or not ghost_gfx then return end
   if ghost.data[frame].room ~= get_room() then return end
   local d, i = ghost.data, frame
   local rx, ry = d[i-1].x - buf[0].sx, d[i-1].y - buf[0].sy
   -- gui.transparency(2)
   drawpose(ghost, d[i-1].pose, "mario_map", rx, ry)
   -- gui.transparency(0)
end
function draw_ghost_gfx(ghost,frame)
   local mode = memory.readbyte("WRAM", 0x0100)
   if mode == 0x14 then draw_ghost_gfx_level(ghost,frame)
   elseif mode == 0xe then draw_ghost_gfx_map(ghost,frame) end
end


find_yoshi = function()
   for i = 0, 11 do
      if memory.readbyte("WRAM", 0x009e+i) == 0x35 then return i end
   end
   return false
end
function fillbuf()
   local r = {}
   r.mode = memory.readbyte("WRAM", 0x0100)
   r.on_yoshi = memory.readbyte("WRAM", 0x187A)
   r.power = memory.readbyte("WRAM", 0x0019)
   r.igframe = igframe()
   if mode == 0xe then -- overworld
      r.area = memory.readbyte("WRAM", 0x1f11)
      r.x = memory.readword("WRAM", 0x1f17)
      r.y = memory.readword("WRAM", 0x1f19)
      r.sx = memory.readsword("WRAM", 0x001a)
      r.sy = memory.readsword("WRAM", 0x001c)
      r.ahelp, r.pose, r.yoshi_pose, r.ydir, r.cape,dir = 0, 0, 0, 0, 0, 0, 0
      r.subx, r.suby, r.vx, r.vy = 0,0,0,0
   elseif mode == 0x14 then
      r.area = memory.readbyte("WRAM", 0x13bf)
      r.ahelp = memory.readbyte("WRAM", 0x00ce) + (memory.readbyte("WRAM", 0x00cf) >> 8) + (memory.readbyte("WRAM", 0x00d0) >> 16)
      r.x = memory.readword("WRAM", 0x00d1)
      r.y = memory.readword("WRAM", 0x00d3)
      r.sx = memory.readsword("WRAM", 0x1462)
      r.sy = memory.readsword("WRAM", 0x1464)
      r.pose = memory.readbyte("WRAM", 0x13e0)
      r.dir = memory.readbyte("WRAM", 0x0076)
      r.cape = memory.readbyte("WRAM", 0x13df)
      r.subx = memory.readbyte("WRAM", 0x13DA)
      r.suby = memory.readbyte("WRAM", 0x13DA)
      r.vx = s7(memory.readbyte("WRAM", 0x007B))
      r.vy = s7(memory.readbyte("WRAM", 0x007D))
      yoshi = find_yoshi()
      if yoshi then
         r.yoshi_pose = memory.readbyte("WRAM", 0x1602+yoshi)
         r.ydir = 1-memory.readbyte("WRAM", 0x157c+yoshi)
      else r.yoshi_pose = 0 r.ydir = 0 end
      -- Enemy stuff
      r.enemy_state, r.enemy_x, r.enemy_y, r.enemy_clip = {}, {}, {}, {}
      for i = 0, 11 do r.enemy_state[i] = memory.readbyte("WRAM", 0x14c8+i) end
      for i = 0, 11 do r.enemy_x[i] = memory.readbyte("WRAM", 0x00e4+i) + (memory.readbyte("WRAM", 0x14e0+i) << 8) end
      for i = 0, 11 do r.enemy_y[i] = memory.readbyte("WRAM", 0x00d8+i) + (memory.readbyte("WRAM", 0x14d4+i) << 8) end
      for i = 0, 11 do r.enemy_clip[i] = memory.readbyte("WRAM", 0x1662+i) % 0x3f end
   else
      r.x, r.y, r.sx, r.sy, r.area, r.ahelp, r.pose,r.dir,r.ydir,r.yoshi_pose, r.cape =
         0,0,0,0,0,0,0,0,0,0,0,0
      r.subx, r.suby, r.vx, r.vy = 0,0,0,0
   end
   return r
end

-- End of definitions. Start running.

callback.snoop2:register(function(p, c, b, v)
    if p == 0 and c == 0 then
        main()
    end
end)
--callback.frame_emulated:register(main)

return mod