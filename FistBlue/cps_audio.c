#include <stddef.h>
#include "cps_audio.h"
#include "../third_party/nuked_opm/opm.h"

#define YM2151_CLOCKS_PER_SAMPLE 64u
#define YM2151_CLOCK_HZ 3579545u
#define CPS_FRAME_HZ 60u

static opm_t ym2151;
static int32_t last_left;
static int32_t last_right;
static uint8_t initialized;
static uint64_t frame_clock_remainder;
static uint64_t sample_clock_remainder;

void cps_audio_init(void)
{
    if (initialized) return;
    OPM_Reset(&ym2151, opm_flags_none);
    initialized = 1;
    last_left = 0;
    last_right = 0;
}

void cps_audio_reset(void)
{
    OPM_Reset(&ym2151, opm_flags_none);
    initialized = 1;
    last_left = 0;
    last_right = 0;
    frame_clock_remainder = 0;
    sample_clock_remainder = 0;
}

void cps_audio_ym2151_write(uint8_t port, uint8_t data)
{
    cps_audio_init();
    OPM_Write(&ym2151, port, data);
}

void cps_audio_clock_frame(void)
{
    unsigned clocks;
    unsigned samples;
    int32_t output[2] = {0, 0};
    uint8_t sh1 = 0;
    uint8_t sh2 = 0;
    uint8_t so = 0;

    cps_audio_init();
    frame_clock_remainder += YM2151_CLOCK_HZ;
    clocks = (unsigned)(frame_clock_remainder / CPS_FRAME_HZ);
    frame_clock_remainder %= CPS_FRAME_HZ;
    sample_clock_remainder += clocks;
    samples = (unsigned)(sample_clock_remainder / YM2151_CLOCKS_PER_SAMPLE);
    sample_clock_remainder %= YM2151_CLOCKS_PER_SAMPLE;
    for (unsigned s = 0; s < samples; ++s) {
        for (unsigned i = 0; i < YM2151_CLOCKS_PER_SAMPLE; ++i) {
            OPM_Clock(&ym2151, output, &sh1, &sh2, &so);
        }
        last_left = output[0];
        last_right = output[1];
    }
}

void cps_audio_last_sample(int32_t *left, int32_t *right)
{
    cps_audio_init();
    if (left != NULL) *left = last_left;
    if (right != NULL) *right = last_right;
}
