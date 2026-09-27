local machine=manager.machine
local cpu=machine.devices[":maincpu"]
local mem=cpu.spaces["program"]
local BASE=0xff8000
local P1=BASE+0x03c6
local P2=BASE+0x06c6
local out=assert(io.open("mame_demo_probe.csv","w"))
out:write("frame,pl_mode0,pl_mode1,timer_coarse,timer_fine,intro,p1_select,p2_select,p1_joy,p2_joy,p1_fid,p2_fid\n")
local frame=0
local function sample()
 frame=frame+1
 if frame>=2400 then
  out:write(string.format("%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n",
   frame,mem:read_u8(BASE+0x5dbe),mem:read_u8(BASE+0x5dbf),
   mem:read_u8(BASE+0x5dc2),mem:read_u8(BASE+0x5dc3),mem:read_u8(BASE+0x5dc8),
   mem:read_u8(P1+0x28f),mem:read_u8(P2+0x28f),
   mem:read_u16(P1+0x292),mem:read_u16(P2+0x292),
   mem:read_u8(P1+0x291),mem:read_u8(P2+0x291)))
  out:flush()
 end
 if frame>=3600 then out:close();machine:exit() end
end
emu.register_frame_done(sample)
