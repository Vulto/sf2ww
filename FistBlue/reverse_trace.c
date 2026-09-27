#include "reverse_trace.h"

#include <stddef.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include "structs.h"

extern Game g;

static int traceEnabled = -1;
static FILE *stateFile;
static FILE *metaFile;
static uint64_t sequence;

struct ReverseRecordHeader {
    uint32_t magic;
    uint32_t version;
    uint64_t sequence;
    uint64_t hostMonotonicNs;
    uint32_t gameTick;
    uint32_t gameSize;
};

static uint64_t monotonicNs(void) {
    struct timespec value;
    if (clock_gettime(CLOCK_MONOTONIC, &value) != 0) {
        return 0;
    }
    return (uint64_t)value.tv_sec * 1000000000ull + (uint64_t)value.tv_nsec;
}

static void openTrace(void) {
    if (traceEnabled != -1) {
        return;
    }

    traceEnabled = getenv("SF2_REVERSE_NATIVE_TRACE") != NULL;
    if (!traceEnabled) {
        return;
    }

    stateFile = fopen("native_reverse_state.bin", "wb");
    metaFile = fopen("native_reverse_manifest.csv", "w");
    if (stateFile == NULL || metaFile == NULL) {
        traceEnabled = 0;
        if (stateFile != NULL) {
            fclose(stateFile);
            stateFile = NULL;
        }
        if (metaFile != NULL) {
            fclose(metaFile);
            metaFile = NULL;
        }
        return;
    }

    fprintf(metaFile, "field,offset,size\n");
#define FIELD(name) fprintf(metaFile, #name ",%zu,%zu\n", offsetof(Game, name), sizeof(g.name))
    FIELD(mode0);
    FIELD(timer0);
    FIELD(mode1);
    FIELD(timer1);
    FIELD(mode2);
    FIELD(timer2);
    FIELD(mode3);
    FIELD(timer3);
    FIELD(mode4);
    FIELD(timer4);
    FIELD(mode5);
    FIELD(timer5);
    FIELD(mode6);
    FIELD(timer6);
    FIELD(tick);
    FIELD(CPS);
    FIELD(RawButtons0);
    FIELD(ContrP1);
    FIELD(ContrP2);
    FIELD(JPCost);
    FIELD(JPDifficulty);
    FIELD(JPParam);
    FIELD(randSeed1);
    FIELD(randSeed2);
    FIELD(Difficulty);
    FIELD(AllowContinue);
    FIELD(DemoSound);
    FIELD(FlipDisplay);
    FIELD(FreePlay);
    FIELD(FreezeMachine);
    FIELD(Debug);
    FIELD(InDemo);
    FIELD(DemoStarted);
    FIELD(DemoStageIndex);
    FIELD(DemoFightTimer);
    FIELD(Player1);
    FIELD(Player2);
    FIELD(CurrentStage);
    FIELD(Stage);
    FIELD(RoundCnt);
    FIELD(TimeRemainBCD);
    FIELD(TimeRemainTicks);
    FIELD(FightOver);
    FIELD(GameMode);
#undef FIELD

    fprintf(metaFile, "record_header_magic,0x53524654\n");
    fprintf(metaFile, "record_header_version,1\n");
    fprintf(metaFile, "game_size,%zu\n", sizeof(Game));
    fprintf(metaFile, "pointer_fields_are_native_addresses,1\n");
    fflush(metaFile);
}

void FBReverseTraceTick(void) {
    struct ReverseRecordHeader header;

    openTrace();
    if (!traceEnabled) {
        return;
    }

    header.magic = 0x53524654u;
    header.version = 1;
    header.sequence = ++sequence;
    header.hostMonotonicNs = monotonicNs();
    header.gameTick = g.tick;
    header.gameSize = (uint32_t)sizeof(g);

    fwrite(&header, sizeof(header), 1, stateFile);
    fwrite(&g, sizeof(g), 1, stateFile);

    if ((sequence & 0x0fu) == 0) {
        fflush(stateFile);
    }
}
