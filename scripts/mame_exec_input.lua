-- MAME numeric execution trace with a deterministic input sequence.
-- The input sequence is mirrored by the native lockstep probe.

local machine = manager.machine
local cpu = machine.devices[":maincpu"]
local state = cpu.state
local mem = cpu.spaces["program"]

local P1 = 0xff83c6
local ioport = machine.ioport
local inputFields = {}

local inputTokens = {
    "P1_JOYSTICK_UP", "P1_JOYSTICK_DOWN", "P1_JOYSTICK_LEFT", "P1_JOYSTICK_RIGHT",
    "P1_BUTTON1", "P1_BUTTON2", "P1_BUTTON3", "P1_BUTTON4", "P1_BUTTON5", "P1_BUTTON6",
    "START1", "COIN1"
}

local function findInputFields()
    for _, port in pairs(ioport.ports) do
        for _, field in pairs(port.fields) do
            local token = ioport:input_type_to_token(field.type, field.player)
            for _, wanted in ipairs(inputTokens) do
                if token == wanted then
                    inputFields[wanted] = field
                end
            end
        end
    end
    for _, wanted in ipairs(inputTokens) do
        assert(inputFields[wanted] ~= nil, "missing MAME input field: " .. wanted)
    end
end

local function setInput(token, active)
    inputFields[token]:set_value(active and 1 or 0)
end

local function applyInput(frame)
    for _, token in ipairs(inputTokens) do
        setInput(token, false)
    end

    if frame >= 30 and frame < 36 then
        setInput("COIN1", true)
    elseif frame >= 90 and frame < 96 then
        setInput("START1", true)
    end

    if frame >= 120 and frame < 180 then
        setInput("P1_JOYSTICK_RIGHT", true)
    elseif frame >= 180 and frame < 240 then
        setInput("P1_JOYSTICK_LEFT", true)
    elseif frame >= 240 and frame < 300 then
        setInput("P1_JOYSTICK_DOWN", true)
    elseif frame >= 300 and frame < 360 then
        setInput("P1_JOYSTICK_UP", true)
    end

    if frame >= 120 and frame < 126 then
        setInput("P1_BUTTON1", true)
    elseif frame >= 200 and frame < 206 then
        setInput("P1_BUTTON2", true)
    elseif frame >= 280 and frame < 286 then
        setInput("P1_BUTTON3", true)
    elseif frame >= 360 and frame < 366 then
        setInput("P1_BUTTON4", true)
    elseif frame >= 440 and frame < 446 then
        setInput("P1_BUTTON5", true)
    elseif frame >= 520 and frame < 526 then
        setInput("P1_BUTTON6", true)
    end
end

findInputFields()

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

local out = assert(io.open("mame_exec_input.csv", "w"))
out:write("arcade_time_ns,arcade_cpu_cycles,p1_x,p1_y,p1_mode0,p1_mode1,p1_mode2,p1_anim,p1_energy,p1_move,p1_stand_squat,p2_x,p2_y,p2_mode0,p2_mode1,p2_mode2,p2_anim,p2_energy,p2_move,p2_stand_squat,stage,round_cnt,fight_over,rng1,rng2\n")

local previous = nil
local seq = 0
local frame = 0
local MAX_FRAMES = 900
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
    applyInput(frame)
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
