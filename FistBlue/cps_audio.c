#include <stddef.h>
#include <stdio.h>
#include <string.h>
#include "cps_audio.h"
#include "../third_party/nuked_opm/opm.h"

#define YM2151_CLOCKS_PER_SAMPLE 64u
#define YM2151_OUTPUT_WARMUP_SAMPLES 8u
#define YM2151_CLOCK_HZ 3579545u
#define CPS_FRAME_HZ 60u
#define YM_SAMPLE_RATE_NUM 3579545u
#define YM_SAMPLE_RATE_DEN 64u
#define OKI_CLOCK_HZ 1000000u
#define OKI_PIN7_HIGH_DIVISOR 132u
#define OKI_PIN7_LOW_DIVISOR 165u
#define OKI_VOICES 4u
#define PCM_RING_FRAMES 16384u

static opm_t ym2151;
static int32_t last_left;
static int32_t last_right;
typedef struct {
    uint8_t playing;
    uint32_t sample;
    uint32_t count;
    uint32_t base_offset;
    int predictor;
    unsigned step_index;
    int volume;
} OkiVoice;

static OkiVoice oki_voice[OKI_VOICES];
static uint8_t oki_rom[0x40000];
static int oki_loaded;
static int oki_pending_sample = -1;
static uint8_t oki_pin7 = 1;
static uint64_t oki_sample_remainder;
static int32_t last_oki;
static int16_t pcm_ring[PCM_RING_FRAMES * 2u];
static size_t pcm_read_index;
static size_t pcm_write_index;
static size_t pcm_count;

void cps_audio_init(void);

static const int oki_steps[49] = {
    16,17,19,21,23,25,28,31,34,37,41,45,50,55,60,66,73,80,88,97,107,118,130,
    143,157,173,190,209,230,253,279,307,337,371,408,449,494,544,598,658,724,
    796,876,963,1060,1166,1282,1411,1552
};
static const int oki_index[16] = {-1,-1,-1,-1,2,4,6,8,-1,-1,-1,-1,2,4,6,8};

static uint8_t initialized;
static uint64_t frame_clock_remainder;
static uint64_t sample_clock_remainder;

static int OkiStep(int nibble, int *predictor, unsigned *step_index)
{
    int step = oki_steps[*step_index];
    int delta = nibble & 7;
    int diff = ((2 * delta + 1) * step) >> 3;
    int next = *predictor;
    if (nibble & 8) next -= diff;
    else next += diff;
    if (next < -2048) next = -2048;
    if (next > 2047) next = 2047;
    {
        int index = (int)*step_index + oki_index[nibble & 15];
        if (index < 0) index = 0;
        if (index > 48) index = 48;
        *step_index = (unsigned)index;
    }
    *predictor = next;
    return next;
}

void cps_audio_oki_set_pin7(uint8_t pin7)
{
    cps_audio_init();
    oki_pin7 = pin7 ? 1u : 0u;
}

void cps_audio_oki_write(uint8_t data)
{
    unsigned voiceMask;
    cps_audio_init();
    if (oki_pending_sample >= 0) {
        voiceMask = (unsigned)((data >> 4) & 0x07u);
        for (unsigned voiceIndex = 0; voiceIndex < OKI_VOICES; ++voiceIndex, voiceMask >>= 1) {
            if ((voiceMask & 1u) == 0u || oki_voice[voiceIndex].playing) continue;
            {
                uint32_t base = (uint32_t)oki_pending_sample * 8u;
                uint32_t start = ((uint32_t)oki_rom[base] << 16) |
                                 ((uint32_t)oki_rom[base + 1] << 8) | oki_rom[base + 2];
                uint32_t stop = ((uint32_t)oki_rom[base + 3] << 16) |
                                ((uint32_t)oki_rom[base + 4] << 8) | oki_rom[base + 5];
                start &= 0x3ffffu;
                stop &= 0x3ffffu;
                if (oki_loaded && start < stop && stop < sizeof(oki_rom)) {
                    static const int volume[16] = {32,23,19,16,13,11,9,8,7,6,5,4,3,2,1,0};
                    oki_voice[voiceIndex].playing = 1u;
                    oki_voice[voiceIndex].sample = 0u;
                    oki_voice[voiceIndex].base_offset = start;
                    oki_voice[voiceIndex].count = 2u * (stop - start + 1u);
                    oki_voice[voiceIndex].predictor = 0;
                    oki_voice[voiceIndex].step_index = 0;
                    oki_voice[voiceIndex].volume = volume[data & 15u];
                }
            }
        }
        oki_pending_sample = -1;
        return;
    }
    if (data & 0x80u) {
        oki_pending_sample = data & 0x7fu;
        return;
    }
    voiceMask = (unsigned)((data >> 3) & 0x0fu);
    for (unsigned voiceIndex = 0; voiceIndex < OKI_VOICES; ++voiceIndex, voiceMask >>= 1) {
        if (voiceMask & 1u) oki_voice[voiceIndex].playing = 0u;
    }
}

static int OkiNextSample(void)
{
    int mix = 0;
    for (unsigned voiceIndex = 0; voiceIndex < OKI_VOICES; ++voiceIndex) {
        OkiVoice *voice = &oki_voice[voiceIndex];
        if (!voice->playing) continue;
        {
            uint32_t byteOffset = voice->base_offset + voice->sample / 2u;
            uint8_t byte = oki_rom[byteOffset & 0x3ffffu];
            int nibble = (voice->sample & 1u) ? (byte & 0x0fu) : (byte >> 4);
            int signal = OkiStep(nibble, &voice->predictor, &voice->step_index);
            mix += signal * voice->volume;
            ++voice->sample;
            if (voice->sample >= voice->count) voice->playing = 0u;
        }
    }
    if (mix > 65535) mix = 65535;
    if (mix < -65536) mix = -65536;
    return mix;
}

void cps_audio_init(void)
{
    if (initialized) return;
    OPM_Reset(&ym2151, opm_flags_none);
    memset(oki_voice, 0, sizeof(oki_voice));
    memset(oki_rom, 0, sizeof(oki_rom));
    {
        FILE *f = fopen("sf2_18.bin", "rb");
        size_t n = 0;
        if (f != NULL) {
            n += fread(oki_rom, 1, 0x20000u, f);
            fclose(f);
        }
        f = fopen("sf2_19.bin", "rb");
        if (f != NULL) {
            n += fread(&oki_rom[0x20000], 1, 0x20000u, f);
            fclose(f);
        }
        oki_loaded = (n != 0);
    }
    oki_pending_sample = -1;
    oki_pin7 = 1;
    oki_sample_remainder = 0;
    last_oki = 0;
    initialized = 1;
    last_left = 0;
    last_right = 0;
}

void cps_audio_reset(void)
{
    if (!initialized) cps_audio_init();
    if (!initialized) cps_audio_init();
    OPM_Reset(&ym2151, opm_flags_none);
    memset(oki_voice, 0, sizeof(oki_voice));
    oki_pending_sample = -1;
    oki_pin7 = 1;
    oki_sample_remainder = 0;
    last_oki = 0;
    memset(pcm_ring, 0, sizeof(pcm_ring));
    pcm_read_index = 0;
    pcm_write_index = 0;
    pcm_count = 0;
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
        oki_sample_remainder += (uint64_t)OKI_CLOCK_HZ * YM_SAMPLE_RATE_DEN;
        {
            uint64_t divisor = oki_pin7 ? OKI_PIN7_HIGH_DIVISOR : OKI_PIN7_LOW_DIVISOR;
            uint64_t threshold = (uint64_t)YM_SAMPLE_RATE_NUM * divisor;
            if (oki_sample_remainder >= threshold) {
                oki_sample_remainder -= threshold;
                last_oki = OkiNextSample();
            }
        }
        for (unsigned i = 0; i < YM2151_CLOCKS_PER_SAMPLE; ++i) {
            OPM_Clock(&ym2151, output, &sh1, &sh2, &so);
        }
        {
            int32_t mixed_left = output[0] + last_oki;
            int32_t mixed_right = output[1] + last_oki;
            if (mixed_left > 32767) mixed_left = 32767;
            if (mixed_left < -32768) mixed_left = -32768;
            if (mixed_right > 32767) mixed_right = 32767;
            if (mixed_right < -32768) mixed_right = -32768;
            last_left = mixed_left;
            last_right = mixed_right;
            pcm_ring[pcm_write_index * 2u] = (int16_t)mixed_left;
            pcm_ring[pcm_write_index * 2u + 1u] = (int16_t)mixed_right;
            pcm_write_index = (pcm_write_index + 1u) % PCM_RING_FRAMES;
            if (pcm_count < PCM_RING_FRAMES) {
                ++pcm_count;
            } else {
                pcm_read_index = (pcm_read_index + 1u) % PCM_RING_FRAMES;
            }
        }
    }
}

void cps_audio_last_sample(int32_t *left, int32_t *right)
{
    cps_audio_init();
    if (left != NULL) *left = last_left;
    if (right != NULL) *right = last_right;
}


size_t cps_audio_read_pcm(int16_t *dst, size_t max_frames)
{
    size_t count;
    if (dst == NULL || max_frames == 0) return 0;
    count = pcm_count < max_frames ? pcm_count : max_frames;
    for (size_t i = 0; i < count; ++i) {
        dst[i * 2u] = pcm_ring[pcm_read_index * 2u];
        dst[i * 2u + 1u] = pcm_ring[pcm_read_index * 2u + 1u];
        pcm_read_index = (pcm_read_index + 1u) % PCM_RING_FRAMES;
    }
    pcm_count -= count;
    return count;
}
