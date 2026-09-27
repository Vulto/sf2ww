-- MAME numeric execution trace for SF2 World Warrior.
-- Records semantic numeric transitions rather than comparing host/frame counters.
-- The first column is only an event sequence number; it is not a timing oracle.

local machine = manager.machine
local cpu = machine.devices[":maincpu"]
local state = cpu.state
local mem = cpu.spaces["program"]

local P1 = 0xff83c6
local P2 = 0xff86c6
local BASE = 0xff0000

local function state_value(name)
    local entry = state[name]
    if entry ~= nil then return entry.value end
    return 0
end

local function pc_value()
    local entry = state["CURPC"]
    if entry ~= nil then return entry.value end
    entry = state["rPC"]
    if entry ~= nil then return entry.value end
    return 0
end

local function vector()
    return table.concat({
        mem:read_i32(P1 + 0x06), mem:read_i32(P1 + 0x08),
        mem:read_u8(P1 + 0x02), mem:read_u8(P1 + 0x03), mem:read_u8(P1 + 0x04),
        mem:read_u16(P1 + 0x14), mem:read_i16(P1 + 0x2a),
        mem:read_i8(P1 + 0x180), mem:read_i8(P1 + 0x188),
        mem:read_i32(P2 + 0x06), mem:read_i32(P2 + 0x08),
        mem:read_u8(P2 + 0x02), mem:read_u8(P2 + 0x03), mem:read_u8(P2 + 0x04),
        mem:read_u16(P2 + 0x14), mem:read_i16(P2 + 0x2a),
        mem:read_i8(P2 + 0x180), mem:read_i8(P2 + 0x188),
        mem:read_u16(BASE + 0x09e4), mem:read_u16(BASE + 0x0a4c),
        mem:read_u8(BASE + 0x0ae1), mem:read_u8(BASE + 0x02c4),
        mem:read_u8(BASE + 0x02c5)
    }, ",")
end

local out = assert(io.open("mame_exec_numeric.csv", "w"))
out:write("arcade_time_ns,arcade_cpu_cycles,p1_x,p1_y,p1_mode0,p1_mode1,p1_mode2,p1_anim,p1_energy,p1_move,p1_stand_squat,p2_x,p2_y,p2_mode0,p2_mode1,p2_mode2,p2_anim,p2_energy,p2_move,p2_stand_squat,stage,round_cnt,fight_over,rng1,rng2\n")

local previous = nil
local seq = 0
local frame = 0
local MAX_FRAMES = tonumber(os.getenv("SF2_NUMERIC_MAX_FRAMES") or "900")
local base_seconds = nil
local base_nsec = nil

local function elapsed_time_ns()
    local t = machine.time
    if base_seconds == nil then
        base_seconds = t.seconds
        base_nsec = t.nsec
    end
    return (t.seconds - base_seconds) * 1000000000 + (t.nsec - base_nsec)
end

local function sample()
    frame = frame + 1
    local elapsed_ns = elapsed_time_ns()
    local cycles = emu.attotime.from_nsec(elapsed_ns):as_ticks(10000000)
    local current = vector()
    if current ~= previous then
        seq = seq + 1
        out:write(elapsed_ns .. "," .. cycles .. "," .. current .. "\n")
        out:flush()
        previous = current
    end
    if frame >= MAX_FRAMES or seq >= 1000 then
        out:close()
        machine:exit()
    end
end

emu.register_frame_done(sample)
