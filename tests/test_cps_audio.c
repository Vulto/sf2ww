#include <assert.h>
#include <stdint.h>
#include <stdio.h>
#include <string.h>
#include "../FistBlue/cps_audio.h"

static void write_oki_fixture(void)
{
    uint8_t rom[0x20000];
    memset(rom, 0, sizeof(rom));
    rom[0] = 0x00;
    rom[1] = 0x00;
    rom[2] = 0x10;
    rom[3] = 0x00;
    rom[4] = 0x00;
    rom[5] = 0x10;
    rom[0x10] = 0x7f;

    {
        FILE *f = fopen("sf2_18.bin", "wb");
        assert(f != NULL);
        assert(fwrite(rom, 1, sizeof(rom), f) == sizeof(rom));
        fclose(f);
    }
    {
        FILE *f = fopen("sf2_19.bin", "wb");
        assert(f != NULL);
        assert(fwrite(rom, 1, sizeof(rom), f) == sizeof(rom));
        fclose(f);
    }
}

int main(void)
{
    int32_t left1;
    int32_t right1;
    int32_t left2;
    int32_t right2;
    int nonzero_oki = 0;

    write_oki_fixture();

    cps_audio_reset();
    cps_audio_ym2151_write(0, 0x01);
    cps_audio_ym2151_write(1, 0x00);
    cps_audio_oki_write(0x80);
    cps_audio_oki_write(0x10);

    for (unsigned frame = 0; frame < 8; ++frame) {
        cps_audio_clock_frame();
        cps_audio_last_sample(&left1, &right1);
        if (left1 != 0 || right1 != 0) nonzero_oki = 1;
    }

    assert(nonzero_oki);

    cps_audio_reset();
    cps_audio_ym2151_write(0, 0x01);
    cps_audio_ym2151_write(1, 0x00);
    cps_audio_clock_frame();
    cps_audio_last_sample(&left1, &right1);

    cps_audio_reset();
    cps_audio_ym2151_write(0, 0x01);
    cps_audio_ym2151_write(1, 0x00);
    cps_audio_clock_frame();
    cps_audio_last_sample(&left2, &right2);

    assert(left1 == left2);
    assert(right1 == right2);

    remove("sf2_18.bin");
    remove("sf2_19.bin");
    return 0;
}
