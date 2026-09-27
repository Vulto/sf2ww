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
        pc_value(), state_value("D0"), state_value("D1"),
        state_value("A0"), state_value("A1"),
        mem:read_i32(P1 + 0x06), mem:read_i32(P1 + 0x08),
        mem:read_u8(P1 + 0x02), mem:read_u8(P1 + 0x03), mem:read_u8(P1 + 0x04),
        mem:read_u8(P1 + 0x14), mem:read_u16(P1 + 0x2a),
        mem:read_u16(P1 + 0x180), mem:read_u8(P1 + 0x188),
        mem:read_i32(P2 + 0x06), mem:read_i32(P2 + 0x08),
        mem:read_u8(P2 + 0x02), mem:read_u8(P2 + 0x03), mem:read_u8(P2 + 0x04),
        mem:read_u8(P2 + 0x14), mem:read_u16(P2 + 0x2a),
        mem:read_u16(P2 + 0x180), mem:read_u8(P2 + 0x188),
        mem:read_u8(BASE + 0x09e4), mem:read_u8(BASE + 0x0a4c),
        mem:read_u8(BASE + 0x0ae1), mem:read_u8(BASE + 0x02c4),
        mem:read_u8(BASE + 0x02c5)
    }, ",")
end

local out = assert(io.open("mame_exec_numeric.csv", "w"))
out:write("seq,pc,d0,d1,a0,a1,p1_x,p1_y,p1_mode0,p1_mode1,p1_mode2,p1_anim,p1_energy,p1_move,p1_stand_squat,p2_x,p2_y,p2_mode0,p2_mode1,p2_mode2,p2_anim,p2_energy,p2_move,p2_stand_squat,stage,round_cnt,fight_over,rng1,rng2\n")

local previous = nil
local seq = 0

local function sample()
    local current = vector()
    if current ~= previous then
        seq = seq + 1
        out:write(seq .. "," .. current .. "\n")
        out:flush()
        previous = current
    end
    if seq >= 1000 then
        out:close()
        emu.stop()
    end
end

emu.register_frame_done(sample, "frame")
