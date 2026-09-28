#ifndef INC_SF2_CPS_AUDIO
#define INC_SF2_CPS_AUDIO

#include <stdint.h>

void cps_audio_init(void);
void cps_audio_reset(void);
void cps_audio_ym2151_write(uint8_t port, uint8_t data);
void cps_audio_clock_frame(void);
void cps_audio_last_sample(int32_t *left, int32_t *right);

#endif
