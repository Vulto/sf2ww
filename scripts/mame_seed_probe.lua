local machine=manager.machine
local cpu=machine.devices[":maincpu"]
local mem=cpu.spaces["program"]
local last1,last2=mem:read_u8(0xff02c4),mem:read_u8(0xff02c5)
local frame=0
local out=assert(io.open("mame_seed_probe.csv","w"))
out:write("frame,time_ns,seed1,seed2,pc\n")
local function sample()
 frame=frame+1
 local a,b=mem:read_u8(0xff02c4),mem:read_u8(0xff02c5)
 if a~=last1 or b~=last2 then
  local pc=cpu.state["CURPC"] or cpu.state["rPC"]
  out:write(string.format("%d,%d,%d,%d,%u\n",frame,machine.time.seconds*1000000000+machine.time.nsec,a,b,pc and pc.value or 0))
  out:flush()
  last1,last2=a,b
  if frame>9000 then out:close(); machine:exit(); return end
 end
 if frame>=12000 then out:close(); machine:exit() end
end
emu.register_frame_done(sample)
