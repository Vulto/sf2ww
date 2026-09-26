-- Deterministic SF2 state/execution probe for MAME.
-- The semantic fields are the project's documented CPS RAM map.
-- The timing axis is relative emulated time converted to the 10 MHz main CPU clock.

local BASE = 0xff0000
local P1 = BASE + 0x03c6
local P2 = BASE + 0x06c6
local MAX_FRAMES = 900
local CPU_HZ = 10000000

local machine = manager.machine
local cpu = machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local output = assert(io.open("mame_state.csv", "w"))
local execution = assert(io.open("mame_execution.csv", "w"))

output:write("frame,arcade_time_ns,arcade_cpu_cycles,game_mode,game_tick,stage,round_cnt,time_bcd,time_ticks,fight_over,rng1,rng2,")
output:write("p1_x,p1_y,p1_mode0,p1_mode1,p1_mode2,p1_anim,p1_energy,p1_move,p1_stand_squat,")
output:write("p2_x,p2_y,p2_mode0,p2_mode1,p2_mode2,p2_anim,p2_energy,p2_move,p2_stand_squat\n")
execution:write("frame,arcade_time_ns,arcade_cpu_cycles,pc,sr,")
for i = 0, 7 do execution:write("d" .. i .. ",") end
for i = 0, 7 do
    execution:write("a" .. i)
    if i ~= 7 then execution:write(",") end
end
execution:write("\n")

local frame = 0
local base_seconds = nil
local base_nsec = nil

local function state_value(name)
    local entry = cpu.state[name]
    if entry == nil then
        return 0
    end
    return entry.value
end

local function elapsed_time_ns()
    local t = machine.time
    local seconds = t.seconds
    local nsec = t.nsec
    if base_seconds == nil then
        base_seconds = seconds
        base_nsec = nsec
    end
    return (seconds - base_seconds) * 1000000000 + (nsec - base_nsec)
end

local function player(base)
    return {
        mem:read_i32(base + 0x06),
        mem:read_i32(base + 0x08),
        mem:read_u8(base + 0x02),
        mem:read_u8(base + 0x03),
        mem:read_u8(base + 0x04),
        mem:read_u16(base + 0x14),
        mem:read_i16(base + 0x2a),
        mem:read_i8(base + 0x180),
        mem:read_i8(base + 0x188)
    }
end

emu.register_frame_done(function()
    frame = frame + 1

    local elapsed_ns = elapsed_time_ns()
    local cycles = emu.attotime.from_nsec(elapsed_ns):as_ticks(CPU_HZ)
    local a = player(P1)
    local b = player(P2)

    output:write(string.format(
        "%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n",
        frame,
        elapsed_ns,
        cycles,
        mem:read_u16(BASE + 0x00),
        mem:read_u8(BASE + 0x1c),
        mem:read_u16(BASE + 0x9e4),
        mem:read_u16(BASE + 0xa4c),
        mem:read_u8(BASE + 0xace),
        mem:read_u8(BASE + 0xacf),
        mem:read_u8(BASE + 0xae1),
        mem:read_u8(BASE + 0x2c4),
        mem:read_u8(BASE + 0x2c5),
        a[1],a[2],a[3],a[4],a[5],a[6],a[7],a[8],a[9],
        b[1],b[2],b[3],b[4],b[5],b[6],b[7],b[8],b[9]
    ))

    execution:write(string.format(
        "%d,%d,%d,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u\n",
        frame,
        elapsed_ns,
        cycles,
        state_value("CURPC"),
        state_value("CURFLAGS"),
        state_value("D0"), state_value("D1"), state_value("D2"), state_value("D3"),
        state_value("D4"), state_value("D5"), state_value("D6"), state_value("D7"),
        state_value("A0"), state_value("A1"), state_value("A2"), state_value("A3"),
        state_value("A4"), state_value("A5"), state_value("A6"), state_value("A7")
    ))

    output:flush()
    execution:flush()

    if frame >= MAX_FRAMES then
        output:close()
        execution:close()
        machine:exit()
    end
end)
