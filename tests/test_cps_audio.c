#include <assert.h>
#include <stdint.h>
#include "../FistBlue/cps_audio.h"

int main(void)
{
    int32_t left1;
    int32_t right1;
    int32_t left2;
    int32_t right2;

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
    assert(left1 != 0 || right1 != 0);
    return 0;
}
