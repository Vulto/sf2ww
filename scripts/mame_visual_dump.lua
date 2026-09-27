-- MAME native-screen visual trace for SF2 World Warrior attract mode.
-- Saves exact 384x224 arcade frames so the native renderer can be compared
-- against the actual CPS1 output at the same emulated frame positions.

local machine = manager.machine
local screen = machine.screens[":screen"]

local OUT = os.getenv("SF2_VISUAL_DIR") or "mame_visual"
local EVERY = tonumber(os.getenv("SF2_VISUAL_EVERY") or "10")
local MAX_FRAMES = tonumber(os.getenv("SF2_VISUAL_MAX_FRAMES") or "12000")

local frame = 0
local last_mode = -1

local function sample()
    frame = frame + 1
    local mode = machine.devices[":maincpu"].spaces["program"]:read_u16(0xff0000)
    if mode ~= last_mode then
        print(string.format("ATTRACT_MODE frame=%d mode=%d", frame, mode))
        last_mode = mode
    end
    if EVERY > 0 and (frame % EVERY) == 0 then
        local filename = string.format("%s/frame_%06d.png", OUT, frame)
        local err = screen:snapshot(filename)
        if err ~= nil then
            emu.print_error("snapshot failed: " .. tostring(err))
            machine:exit()
            return
        end
    end
    if frame >= MAX_FRAMES then
        machine:exit()
    end
end

emu.register_frame_done(sample)
