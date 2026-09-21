-- Deterministic SF2 World Warrior state probe for MAME.
-- Candidate offsets come from the repository's documented CPS RAM layout.
-- They become authoritative only after lockstep validation against the port.

local BASE = 0xff0000
local P1 = BASE + 0x03c6
local P2 = BASE + 0x06c6
local MAX_FRAMES = 900

local cpu = manager.machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local output = assert(io.open("mame_state.csv", "w"))

output:write("frame,game_mode,game_tick,stage,round_cnt,time_bcd,time_ticks,fight_over,rng1,rng2,")
output:write("p1_x,p1_y,p1_mode0,p1_mode1,p1_mode2,p1_anim,p1_energy,p1_move,p1_stand_squat,")
output:write("p2_x,p2_y,p2_mode0,p2_mode1,p2_mode2,p2_anim,p2_energy,p2_move,p2_stand_squat\n")

local frame = 0

local function s32(value)
    if value >= 0x80000000 then
        return value - 0x100000000
    end
    return value
end

local function player(base)
    return {
        s32(mem:read_u32(base + 0x28)),
        s32(mem:read_u32(base + 0x2c)),
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
    local a = player(P1)
    local b = player(P2)

    output:write(string.format(
        "%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d,%d\n",
        frame,
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

    if frame >= MAX_FRAMES then
        output:flush()
        output:close()
        manager.machine:exit()
    end
end)
