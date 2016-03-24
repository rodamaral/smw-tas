ctime = utime()
outprefix = "ghost" .. ctime
dumpfile = outprefix..".dump"
nomovie = false
io.output(dumpfile)

-- compatibilty
if not SHIFT then SHIFT = function(a,b)
	return a * math.floor(math.pow(2,-b))  --  bit.lshift ?
end end
if not AND then AND = function(a,b)
	-- OBS: Not a real AND implementaion, just a hack which is
	-- equivalent for the one use of AND in this file!
	return a % b
end end


local readbyte_signed = memory.readsbyte
local readword_signed = memory.readsword

local find_yoshi = function()
	for i = 0, 11 do
		if memory.readbyte(0x7e009e+i) == 0x35 then return i end
	end
	return false
end

local frame = 0
local last = 0

local function main()
    mode = memory.readbyte(0x7e0100)
    power = memory.readbyte(0x7e0019)
    if mode == 0xe then -- overworld
        area = memory.readbyte(0x7e1f11)
        x = memory.readword(0x7e1f17)
        y = memory.readword(0x7e1f19)
        subx, suby = 0, 0
        vx, vy = 0, 0
        on_yoshi = memory.readbyte(0x7E0dc1)
        pose = SHIFT(memory.readbyte(0x7e1f13),-1) + AND(SHIFT(memory.readbyte(0x7e0013)-1,3),3) + SHIFT(on_yoshi,-7)
        ahelp, yoshi_pose, ydir, cape,dir = 0, 0, 0, 0, 0
    elseif mode == 0x14 then
        area = memory.readbyte(0x7e13bf)
        ahelp = memory.readbyte(0x7e00ce) + SHIFT(memory.readbyte(0x7e00cf),8) + SHIFT(memory.readbyte(0x7e00d0),16)
        x = memory.readword(0x7e00d1)
        y = memory.readword(0x7e00d3)
        subx = memory.readbyte(0x7E13DA)
        suby = memory.readbyte(0x7E13DA)
        vx = memory.readbyte(0x7E007B)
        vy = memory.readbyte(0x7E007D)
        pose = memory.readbyte(0x7e13e0)
        dir = memory.readbyte(0x7e0076)
        cape = memory.readbyte(0x7e13df)
        on_yoshi = memory.readbyte(0x7E187A)
        yoshi = find_yoshi()
        if yoshi then
            yoshi_pose = memory.readbyte(0x7e1602+yoshi)
            ydir = 1-memory.readbyte(0x7e157c+yoshi)
        else yoshi_pose = 0 ydir = 0 end
    else
        x, y, area, ahelp, ducking, pose,dir,ydir,yoshi_pose, cape, on_yoshi =
            0,0,0,0,0,0,0,0,0,0,0
        subx, suby, vx, vy = 0,0,0,0
    end

    io.write(string.format("%5d %5d %5d %10d %5d %5d %5d %5d %5d %5d %5d %5d %5d %5d %5d %5d %5d\n",
        frame, mode, area, ahelp, power, pose, dir, ydir, cape, on_yoshi,yoshi_pose,x,y,subx,suby,vx,vy))

    tmp = memory.readbyte(0x7e0014)
    if tmp ~= last then
        last = tmp
        frame = frame+1
    end
end

function on_frame_emulated()
    main()
end

main()
