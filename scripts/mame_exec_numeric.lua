-- MAME numeric execution trace for SF2 World Warrior.
-- Records semantic numeric transitions rather than comparing host/frame counters.
-- The first column is only an event sequence number; it is not a timing oracle.

local machine = manager.machine
local cpu = machine.devices[":maincpu"]
local state = cpu.state
local mem = cpu.spaces["program"]

local P1 = 0xff83c6
local P2 = 0xff86c6
local BASE = 0xff8000
local CPS_A = 0x800100

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
        mem:read_u8(BASE + 0x02c5),
        mem:read_u16(CPS_A + 0x0c), mem:read_u16(CPS_A + 0x0e),
        mem:read_u16(CPS_A + 0x10), mem:read_u16(CPS_A + 0x12),
        mem:read_u16(CPS_A + 0x14), mem:read_u16(CPS_A + 0x16)
    }, ",")
end

local out = assert(io.open("mame_exec_numeric.csv", "w"))
out:write("arcade_time_ns,arcade_cpu_cycles,pc,sr,d0,d1,d2,d3,d4,d5,d6,d7,a0,a1,a2,a3,a4,a5,a6,a7,p1_x,p1_y,p1_mode0,p1_mode1,p1_mode2,p1_anim,p1_energy,p1_move,p1_stand_squat,p2_x,p2_y,p2_mode0,p2_mode1,p2_mode2,p2_anim,p2_energy,p2_move,p2_stand_squat,scroll1_x,scroll1_y,scroll2_x,scroll2_y,scroll3_x,scroll3_y,stage,round_cnt,fight_over,rng1,rng2\n")

local previous = nil
local seq = 0
local frame = 0
local MAX_FRAMES = tonumber(os.getenv("SF2_NUMERIC_MAX_FRAMES") or "12000")
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
        out:write(elapsed_ns .. "," .. cycles .. "," .. state_value("CURPC") .. "," .. state_value("CURFLAGS") .. "," .. state_value("D0") .. "," .. state_value("D1") .. "," .. state_value("D2") .. "," .. state_value("D3") .. "," .. state_value("D4") .. "," .. state_value("D5") .. "," .. state_value("D6") .. "," .. state_value("D7") .. "," .. state_value("A0") .. "," .. state_value("A1") .. "," .. state_value("A2") .. "," .. state_value("A3") .. "," .. state_value("A4") .. "," .. state_value("A5") .. "," .. state_value("A6") .. "," .. state_value("A7") .. "," .. current .. "\n")
        out:flush()
        previous = current
    end
    if frame >= MAX_FRAMES then
        out:close()
        machine:exit()
    end
end

emu.register_frame_done(sample)
