#include "cps_soundboard.h"
#include "cps_audio.h"
#include "../third_party/superzazu_z80/z80.h"

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <time.h>

#define Z80_CLOCK_HZ 3579545u
#define FRAME_NS 16768000ULL
#define ROM_FIXED_SIZE 0x8000u
#define ROM_BANK_SIZE 0x4000u
#define ROM_BANK_BASE 0x10000u
#define RAM_SIZE 0x0800u
#define Z80_PORT_YM_ADDRESS 0xf000u
#define Z80_PORT_YM_DATA 0xf001u
#define Z80_PORT_OKI 0xf002u
#define Z80_PORT_BANK 0xf004u
#define Z80_PORT_OKI_PIN7 0xf006u
#define Z80_PORT_COMMAND 0xf008u
#define Z80_PORT_FADE 0xf00au

typedef struct {
    z80 Cpu;
    uint8_t Rom[0x18000];
    uint8_t Ram[RAM_SIZE];
    uint8_t Command;
    uint8_t FadeCommand;
    uint8_t Bank;
    uint8_t OkiPin7;
    uint64_t ArcadeTimeNs;
    uint8_t YmAddress;
    uint8_t Initialized;
    uint64_t CycleRemainder;
    FILE *EventLog;
} SoundBoard;

static SoundBoard gSoundBoard;

static uint8_t SoundRead(void *userdata, uint16_t address)
{
    SoundBoard *board = (SoundBoard *)userdata;

    if (address < ROM_FIXED_SIZE) return board->Rom[address];
    if (address < 0xc000u) {
        uint32_t offset = ROM_BANK_BASE +
            ((uint32_t)(board->Bank & 1u) * ROM_BANK_SIZE) +
            (uint32_t)(address - ROM_FIXED_SIZE);
        if (offset < sizeof(board->Rom)) return board->Rom[offset];
        return 0xffu;
    }
    if (address >= 0xc000u && address < 0xc000u + RAM_SIZE) {
        return board->Ram[address - 0xc000u];
    }
    if (address == Z80_PORT_OKI) return 0xf0u;
    if (address == Z80_PORT_COMMAND) return board->Command;
    if (address == Z80_PORT_FADE) return board->FadeCommand;
    return 0xffu;
}

static void SoundWrite(void *userdata, uint16_t address, uint8_t value)
{
    SoundBoard *board = (SoundBoard *)userdata;

    if (address >= 0xc000u && address < 0xc000u + RAM_SIZE) {
        board->Ram[address - 0xc000u] = value;
        return;
    }

    switch (address) {
    case Z80_PORT_YM_ADDRESS:
        board->YmAddress = value;
        cps_soundboard_write_event(1u, value);
        break;
    case Z80_PORT_YM_DATA:
        cps_audio_ym2151_write(board->YmAddress & 1u, value);
        cps_soundboard_write_event(2u, value);
        break;
    case Z80_PORT_OKI:
        cps_audio_oki_write(value);
        cps_soundboard_write_event(3u, value);
        break;
    case Z80_PORT_BANK:
        board->Bank = value;
        cps_soundboard_write_event(4u, value);
        break;
    case Z80_PORT_OKI_PIN7:
        board->OkiPin7 = value & 1u;
        cps_audio_oki_set_pin7(board->OkiPin7);
        cps_soundboard_write_event(5u, board->OkiPin7);
        break;
    default:
        break;
    }
}

static uint8_t SoundPortIn(z80 *cpu, uint8_t port)
{
    (void)cpu;
    (void)port;
    return 0xffu;
}

static void SoundPortOut(z80 *cpu, uint8_t port, uint8_t value)
{
    (void)cpu;
    (void)port;
    (void)value;
}

static void OpenEventLog(void)
{
    const char *path = getenv("SF2_AUDIO_EVENT_LOG");
    if (path == NULL || path[0] == '\0') return;
    gSoundBoard.EventLog = fopen(path, "w");
    if (gSoundBoard.EventLog == NULL) return;
    fprintf(gSoundBoard.EventLog, "sequence,arcade_time_ns,arcade_cpu_cycles,event,data\n");
}

void cps_soundboard_write_event(uint8_t event, uint8_t data)
{
    static uint64_t sequence;
    if (gSoundBoard.EventLog == NULL) return;
    ++sequence;
    fprintf(gSoundBoard.EventLog, "%llu,%llu,%llu,%s,%u\n",
        (unsigned long long)sequence,
        (unsigned long long)gSoundBoard.ArcadeTimeNs,
        (unsigned long long)gSoundBoard.Cpu.cyc,
        event == 1u ? "ym_address" :
        event == 2u ? "ym_data" :
        event == 3u ? "oki_data" :
        event == 4u ? "bank" :
        event == 5u ? "oki_pin7" : "unknown",
        data, 0u);
}

void cps_soundboard_init(void)
{
    if (gSoundBoard.Initialized) return;

    memset(&gSoundBoard, 0, sizeof(gSoundBoard));
    memset(gSoundBoard.Rom, 0xff, sizeof(gSoundBoard.Rom));
    if (!LoadRomFile("sf2_09.bin", gSoundBoard.Rom, 0x10000u)) {
        fprintf(stderr, "sound: unable to load sf2_09.bin\\n");
        return;
    }
    memcpy(&gSoundBoard.Rom[0x10000], &gSoundBoard.Rom[0x8000], 0x8000u);

    z80_init(&gSoundBoard.Cpu);
    gSoundBoard.Cpu.read_byte = SoundRead;
    gSoundBoard.Cpu.write_byte = SoundWrite;
    gSoundBoard.Cpu.port_in = SoundPortIn;
    gSoundBoard.Cpu.port_out = SoundPortOut;
    gSoundBoard.Cpu.userdata = &gSoundBoard;
    gSoundBoard.OkiPin7 = 1u;
    OpenEventLog();
    gSoundBoard.Initialized = 1u;
}

void cps_soundboard_reset(void)
{
    cps_soundboard_init();
    z80_init(&gSoundBoard.Cpu);
    memset(gSoundBoard.Ram, 0, sizeof(gSoundBoard.Ram));
    gSoundBoard.Command = 0u;
    gSoundBoard.FadeCommand = 0u;
    gSoundBoard.Bank = 0u;
    gSoundBoard.OkiPin7 = 1u;
    gSoundBoard.CycleRemainder = 0;
}

static void SoundLatch(uint8_t *latch, uint8_t command)
{
    *latch = command;
    z80_gen_nmi(&gSoundBoard.Cpu);
}

void cps_soundboard_command(uint8_t command)
{
    cps_soundboard_init();
    gSoundBoard.Command = command;
    z80_gen_nmi(&gSoundBoard.Cpu);
    if (gSoundBoard.EventLog != NULL) {
        static uint64_t sequence;
        ++sequence;
        fprintf(gSoundBoard.EventLog, "%llu,%llu,%llu,command,%u\n",
            (unsigned long long)sequence,
            (unsigned long long)(sequence * FRAME_NS),
            (unsigned long long)gSoundBoard.Cpu.cyc,
            command);
        fflush(gSoundBoard.EventLog);
    }
}

void cps_soundboard_clock_frame(void)
{
    uint64_t target;

    cps_soundboard_init();
    gSoundBoard.CycleRemainder += (uint64_t)Z80_CLOCK_HZ * FRAME_NS;
    target = gSoundBoard.CycleRemainder / 1000000000ULL;
    gSoundBoard.CycleRemainder %= 1000000000ULL;
    gSoundBoard.ArcadeTimeNs += FRAME_NS;

    gSoundBoard.Cpu.cyc = 0;
    while (gSoundBoard.Cpu.cyc < target) {
        z80_step(&gSoundBoard.Cpu);
    }
}
