#ifndef CPS_SOUNDBOARD_H
#define CPS_SOUNDBOARD_H

#include <stdint.h>

void cps_soundboard_init(void);
void cps_soundboard_reset(void);
void cps_soundboard_command(uint8_t command);
void cps_soundboard_clock_frame(void);
void cps_soundboard_write_event(uint8_t event, uint8_t data);

#endif
