-- Deep reverse-engineering probe for SF2 World Warrior in MAME.
-- Records instruction execution, program-space memory accesses, frame CPU state,
-- changed main-RAM bytes, memory-map metadata, and attract-mode transitions.
-- This is deliberately separate from the normal lockstep probe because tracing
-- changes execution overhead. Its timing values are only comparable to another
-- run using the same instrumentation configuration.

local machine = manager.machine
local cpu = machine.devices[":maincpu"]
local mem = cpu.spaces["program"]
local state = cpu.state
local debugger = machine.debugger
local audioCpu = machine.devices[":audiocpu"]

local MAX_FRAMES = tonumber(os.getenv("SF2_REVERSE_MAX_FRAMES") or "7200")
local RAM_START = 0xff0000
local RAM_END = 0xffffff
local CPU_HZ = 10000000

local function open_file(name)
    return assert(io.open(name, "w"))
end

local frameOut = open_file("reverse_frames.csv")
local readOut = open_file("reverse_memory_reads.csv")
local writeOut = open_file("reverse_memory_writes.csv")
local ramOut = open_file("reverse_ram_changes.csv")
local mapOut = open_file("reverse_memory_map.csv")
local manifestOut = open_file("reverse_manifest.csv")
local audioReadOut = open_file("reverse_audiocpu_reads.csv")
local audioWriteOut = open_file("reverse_audiocpu_writes.csv")
local registersOut = open_file("reverse_registers.csv")

frameOut:write("frame,arcade_time_ns,arcade_cpu_cycles,pc,sr,d0,d1,d2,d3,d4,d5,d6,d7,a0,a1,a2,a3,a4,a5,a6,a7,game_mode,game_tick,stage,round_cnt,time_bcd,time_ticks,fight_over,rng1,rng2\n")
readOut:write("seq,arcade_time_ns,arcade_cpu_cycles,pc,sr,address,data,mem_mask\n")
writeOut:write("seq,arcade_time_ns,arcade_cpu_cycles,pc,sr,address,data,mem_mask\n")
audioReadOut:write("seq,arcade_time_ns,cpu,address,data,mem_mask,pc\n")
audioWriteOut:write("seq,arcade_time_ns,cpu,address,data,mem_mask,pc\n")
ramOut:write("frame,arcade_time_ns,arcade_cpu_cycles,address,value\n")
mapOut:write("kind,owner,space,address_start,address_end,mirror,mask,cswidth,lane_mask,handler_type,handler_name,tag,region,region_offset\n")
manifestOut:write("key,value\n")
registersOut:write("frame,arcade_time_ns,arcade_cpu_cycles,name,value\n")

local function state_value(name)
    local entry = state[name]
    if entry ~= nil then
        return entry.value
    end
    return 0
end

local function elapsed_time_ns()
    local t = machine.time
    return t.seconds * 1000000000 + t.nsec
end

local function cpu_cycles()
    return emu.attotime.from_nsec(elapsed_time_ns()):as_ticks(CPU_HZ)
end

local function hex(value)
    return string.format("%08x", value)
end

local function writeMemoryMap()

if audioCpu ~= nil and audioCpu.spaces["program"] ~= nil then
    local audioMem = audioCpu.spaces["program"]
    local audioState = audioCpu.state
    local function audioStateValue(name)
        local entry = audioState[name]
        return entry and entry.value or 0
    end
    audioMem:install_read_tap(0x0000, audioMem.address_mask, "sf2ww_reverse_audio_read", function(offset, data, memMask)
        audioReadSeq = audioReadSeq + 1
        audioReadOut:write(string.format("%u,%u,audiocpu,%u,%u,%u,%u\\n", audioReadSeq, elapsed_time_ns(), offset, data, memMask, audioStateValue("CURPC")))
        if (audioReadSeq % 4096) == 0 then audioReadOut:flush() end
    end)
    audioMem:install_write_tap(0x0000, audioMem.address_mask, "sf2ww_reverse_audio_write", function(offset, data, memMask)
        audioWriteSeq = audioWriteSeq + 1
        audioWriteOut:write(string.format("%u,%u,audiocpu,%u,%u,%u,%u\\n", audioWriteSeq, elapsed_time_ns(), offset, data, memMask, audioStateValue("CURPC")))
        if (audioWriteSeq % 4096) == 0 then audioWriteOut:flush() end
    end)
end
    local entries = mem.map and mem.map.entries
    if entries ~= nil then
        for _, entry in ipairs(entries) do
            local read = entry.read
            local write = entry.write
            local readType = read and read.handlertype or "none"
            local writeType = write and write.handlertype or "none"
            local readName = read and read.name or ""
            local writeName = write and write.name or ""
            local readTag = read and read.tag or ""
            local writeTag = write and write.tag or ""
            local readRegion = read and read.region or ""
            local writeRegion = write and write.region or ""
            mapOut:write(string.format(
                "address_map,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\n",
                ":maincpu", mem.name,
                hex(entry.address_start), hex(entry.address_end),
                hex(entry.address_mirror or 0), hex(entry.address_mask or 0),
                tostring(entry.cswidth or 0), hex(entry.mask or 0),
                tostring(readType) .. "/" .. tostring(writeType),
                tostring(readName) .. "/" .. tostring(writeName),
                tostring(readTag) .. "/" .. tostring(writeTag),
                tostring(readRegion) .. "/" .. tostring(writeRegion),
                tostring(entry.region_offset or 0)
            ))
        end
    end

    for tag, region in pairs(machine.memory.regions) do
        mapOut:write(string.format(
            "region,%s,,,,,,,,,,,,%u\n",
            tostring(tag), region.size
        ))
    end
    for tag, share in pairs(machine.memory.shares) do
        mapOut:write(string.format(
            "share,%s,,,,,,,,,,,,%u\n",
            tostring(tag), share.size
        ))
    end
    for tag, bank in pairs(machine.memory.banks) do
        mapOut:write(string.format(
            "bank,%s,,,,,,,,,,,,%u\n",
            tostring(tag), bank.entry
        ))
    end
    mapOut:flush()
end

local previousRam = mem:read_range(RAM_START, RAM_END, 8)
local frame = 0
local readSeq = 0
local writeSeq = 0
local audioReadSeq = 0
local audioWriteSeq = 0

local function captureMemoryAccess(kind, address, data, memMask)
    local now = elapsed_time_ns()
    local cycles = cpu_cycles()
    local pc = state_value("CURPC")
    local sr = state_value("CURFLAGS")
    if kind == "read" then
        readSeq = readSeq + 1
        readOut:write(string.format(
            "%u,%u,%u,%u,%u,%u,%u,%u\n",
            readSeq, now, cycles, pc, sr, address, data, memMask
        ))
        if (readSeq % 4096) == 0 then
            readOut:flush()
        end
    else
        writeSeq = writeSeq + 1
        writeOut:write(string.format(
            "%u,%u,%u,%u,%u,%u,%u,%u\n",
            writeSeq, now, cycles, pc, sr, address, data, memMask
        ))
        if (writeSeq % 4096) == 0 then
            writeOut:flush()
        end
    end
end

mem:install_read_tap(0x000000, 0xffffff, "sf2ww_reverse_read", function(offset, data, memMask)
    captureMemoryAccess("read", offset, data, memMask)
end)

mem:install_write_tap(0x000000, 0xffffff, "sf2ww_reverse_write", function(offset, data, memMask)
    captureMemoryAccess("write", offset, data, memMask)
end)

writeMemoryMap()

manifestOut:write(string.format("system,%s\n", machine.system.name))
manifestOut:write(string.format("driver,%s\n", machine.system.description))
manifestOut:write(string.format("maincpu_clock_hz,%d\n", CPU_HZ))
manifestOut:write(string.format("ram_start,%s\n", hex(RAM_START)))
manifestOut:write(string.format("ram_end,%s\n", hex(RAM_END)))
manifestOut:write(string.format("max_frames,%d\n", MAX_FRAMES))
manifestOut:write("timing_origin,absolute_machine_time_since_reset\n")
manifestOut:write("memory_trace,program_space_000000-ffffff_read_write_taps\n")
manifestOut:write("instruction_trace,debugger_trace_noloop_when_enabled\n")
manifestOut:write("ram_trace,changed_bytes_at_each_frame_boundary\n")
manifestOut:write("register_trace,all_maincpu_state_entries_at_each_frame_boundary\n")
manifestOut:flush()

if debugger ~= nil and os.getenv("SF2_REVERSE_TRACE_INSTRUCTIONS") == "1" then
    debugger:command("trace reverse_68000.tr,maincpu,noloop,{tracelog \"CYCLE=%u PC=%06X SR=%04X D0=%08X D1=%08X D2=%08X D3=%08X D4=%08X D5=%08X D6=%08X D7=%08X A0=%08X A1=%08X A2=%08X A3=%08X A4=%08X A5=%08X A6=%08X A7=%08X \",totalcycles,pc,sr,d0,d1,d2,d3,d4,d5,d6,d7,a0,a1,a2,a3,a4,a5,a6,a7}")
    if audioCpu ~= nil then
        debugger:command("trace reverse_z80.tr,audiocpu,noloop,{tracelog \"CYCLE=%u PC=%04X \",totalcycles,pc}")
    end
end

local function sample()
    frame = frame + 1
    local now = elapsed_time_ns()
    local cycles = cpu_cycles()
    local currentRam = mem:read_range(RAM_START, RAM_END, 8)
    local ramLength = math.min(#previousRam, #currentRam)

    for i = 1, ramLength do
        local oldValue = string.byte(previousRam, i)
        local newValue = string.byte(currentRam, i)
        if oldValue ~= newValue then
            ramOut:write(string.format(
                "%d,%u,%u,%06x,%u\n",
                frame, now, cycles, RAM_START + i - 1, newValue
            ))
        end
    end

    for name, entry in pairs(state) do
        registersOut:write(string.format("%d,%u,%u,%s,%s\n", frame, now, cycles, tostring(name), tostring(entry.value)))
    end

    frameOut:write(string.format(
        "%d,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u,%u\n",
        frame, now, cycles,
        state_value("CURPC"), state_value("CURFLAGS"),
        state_value("D0"), state_value("D1"), state_value("D2"), state_value("D3"),
        state_value("D4"), state_value("D5"), state_value("D6"), state_value("D7"),
        state_value("A0"), state_value("A1"), state_value("A2"), state_value("A3"),
        state_value("A4"), state_value("A5"), state_value("A6"), state_value("A7"),
        mem:read_u16(0xff0000),
        mem:read_u8(0xff001c),
        mem:read_u16(0xff89e4),
        mem:read_u16(0xff8a4c),
        mem:read_u8(0xff8ace),
        mem:read_u8(0xff8acf),
        mem:read_u8(0xff8ae1),
        mem:read_u8(0xff82c4),
        mem:read_u8(0xff82c5)
    ))

    if (frame % 10) == 0 then
        frameOut:flush()
        registersOut:flush()
        ramOut:flush()
    end

    previousRam = currentRam

    if frame >= MAX_FRAMES then
        if debugger ~= nil and os.getenv("SF2_REVERSE_TRACE_INSTRUCTIONS") == "1" then
            debugger:command("traceflush")
            debugger:command("trace off,maincpu")
        end
        frameOut:close()
        readOut:close()
        writeOut:close()
        ramOut:close()
        mapOut:close()
        manifestOut:close()
        registersOut:close()
        audioReadOut:close()
        audioWriteOut:close()
        machine:exit()
    end
end

emu.register_frame_done(sample)
