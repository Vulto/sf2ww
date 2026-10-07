#include "cps_audio_host.h"
#include "cps_audio.h"
#include <SDL2/SDL.h>
#include <stdint.h>

static SDL_AudioDeviceID gAudioDevice;

void cps_audio_host_init(void)
{
    SDL_AudioSpec wanted;
    SDL_AudioSpec obtained;

    if (SDL_InitSubSystem(SDL_INIT_AUDIO) != 0) return;

    SDL_zero(wanted);
    wanted.freq = 55930;
    wanted.format = AUDIO_S16SYS;
    wanted.channels = 2;
    wanted.samples = 1024;

    gAudioDevice = SDL_OpenAudioDevice(NULL, 0, &wanted, &obtained, 0);
    if (gAudioDevice == 0) return;
    SDL_PauseAudioDevice(gAudioDevice, 0);
}

void cps_audio_host_pump(void)
{
    int16_t pcm[2048 * 2];
    size_t frames;

    if (gAudioDevice == 0) return;
    frames = cps_audio_read_pcm(pcm, 2048);
    if (frames != 0) {
        SDL_QueueAudio(gAudioDevice, pcm, (Uint32)(frames * 2u * sizeof(int16_t)));
    }
}

void cps_audio_host_shutdown(void)
{
    if (gAudioDevice != 0) {
        SDL_ClearQueuedAudio(gAudioDevice);
        SDL_CloseAudioDevice(gAudioDevice);
        gAudioDevice = 0;
    }
    SDL_QuitSubSystem(SDL_INIT_AUDIO);
}
