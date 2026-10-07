-- Deterministic CPS1 sound-bus oracle for SF2 World Warrior.
-- Captures the main-CPU sound latch writes and the Z80-side YM/OKI/bank writes.
-- This is observation only; it does not alter emulated state.

local machine = manager.machine
local maincpu = machine.devices[":maincpu"]
local audiocpu = machine.devices[":audiocpu"]
local mainmem = maincpu.spaces["program"]
local audiomem = audiocpu.spaces["program"]
local audioState = audiocpu.state
local CPU_HZ = 10000000

local out = assert(io.open("mame_sound_events.csv", "w"))
out:write("sequence,arcade_time_ns,arcade_cpu_cycles,cpu,address,data,event,pc\n")
local seq = 0

local function now_ns()
    local t = machine.time
    return t.seconds * 1000000000 + t.nsec
end

local function cycles()
    return emu.attotime.from_nsec(now_ns()):as_ticks(CPU_HZ)
end

local function pc()
    local entry = audioState["CURPC"]
    return entry and entry.value or 0
end

local function record(cpuName, address, data, event)
    seq = seq + 1
    out:write(string.format("%u,%u,%u,%s,%u,%u,%s,%u\n",
        seq, now_ns(), cycles(), cpuName, address, data, event, pc()))
    if seq % 128 == 0 then out:flush() end
end

mainmem:install_write_tap(0x800180, 0x800181, "sf2ww_sound_latch",
    function(offset, data, memMask)
        record("maincpu", offset, data & 0xff, "command")
    end)

audiomem:install_write_tap(0xf000, 0xf001, "sf2ww_sound_chips",
    function(offset, data, memMask)
        if offset == 0xf000 then
            record("audiocpu", offset, data, "ym_address")
        else
            record("audiocpu", offset, data, "ym_data")
        end
    end)

audiomem:install_write_tap(0xf002, 0xf002, "sf2ww_oki",
    function(offset, data, memMask)
        record("audiocpu", offset, data, "oki_data")
    end)

audiomem:install_write_tap(0xf004, 0xf004, "sf2ww_bank",
    function(offset, data, memMask)
        record("audiocpu", offset, data, "bank")
    end)

audiomem:install_write_tap(0xf006, 0xf006, "sf2ww_pin7",
    function(offset, data, memMask)
        record("audiocpu", offset, data, "oki_pin7")
    end)

local maxFrames = tonumber(os.getenv("SF2_SOUND_MAX_FRAMES") or "12000")
local frame = 0
emu.register_frame_done(function()
    frame = frame + 1
    if frame >= maxFrames then
        out:flush()
        out:close()
        machine:exit()
    end
end)
