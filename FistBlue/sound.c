/*
 *  sound.c
 *  GLUTBasics
 *
 *  Created by Ben on 20/01/11.
 *  Copyright 2011 Ben Torkington. All rights reserved.
 *
 */

#include "sf2.h"

#include "structs.h"
#include "sound.h"

#include <stdio.h>
#include <stdlib.h>

extern Game g;

static FILE *soundTrace;
static int soundTraceInitialized;
static unsigned soundTraceSequence;
#define SOUND_BACKEND_QUEUE_LENGTH 64
static unsigned short soundBackendQueue[SOUND_BACKEND_QUEUE_LENGTH];
static unsigned soundBackendRead;
static unsigned soundBackendWrite;
static unsigned soundBackendCount;

static void soundTraceEvent(const char *event, int data);

static void soundBackendEnqueue(unsigned short data) {
	if (soundBackendCount == SOUND_BACKEND_QUEUE_LENGTH) {
		soundTraceEvent("overflow", data);
		return;
	}
	soundBackendQueue[soundBackendWrite] = data;
	soundBackendWrite = (soundBackendWrite + 1u) % SOUND_BACKEND_QUEUE_LENGTH;
	++soundBackendCount;
}

static void soundTraceOpen(void) {
	if (soundTraceInitialized) return;
	soundTraceInitialized = 1;
	if (getenv("SF2_AUDIO_EVENT_LOG") != NULL) {
		soundTrace = fopen("native_audio_events.csv", "w");
		if (soundTrace != NULL) fprintf(soundTrace, "sequence,arcade_time_ns,arcade_cpu_cycles,event,data,game_tick\n");
	}
}

static void soundTraceEvent(const char *event, int data) {
	unsigned long long arcade_time_ns = (unsigned long long)g.tick * 16768000ULL;
	unsigned long long arcade_cpu_cycles = (unsigned long long)g.tick * 167680ULL;
	soundTraceOpen();
	if (soundTrace == NULL) return;
	fprintf(soundTrace, "%u,%llu,%llu,%s,%d,%u\n",
		(unsigned)(++soundTraceSequence), arcade_time_ns, arcade_cpu_cycles,
		event, data, (unsigned)g.tick);
	fflush(soundTrace);
}

void sound_cq_addto(short data) {	/* 62ac */
	soundTraceEvent("command", data);
	soundBackendEnqueue((unsigned short)data);
}

void sound_cq_1(short data) {	/* 629a */
	if(g.DemoSound || g.FastEndingFight || g.InDemo == FALSE) {
		sound_cq_addto(data);
	}
}

void soundsting(short data) {		/* 62c4 */
	sound_cq_addto(data);
	sound_cq_addto(data);
}
void ssound1(short data) {			/* 62cc */
	sound_cq_addto(data);
	sound_cq_addto(data);
}
void sound_cq_f0f7(void) {			/* 62d4 */
	ssound1(0xf0);
	ssound1(0xf7);
}
void coinsound(void) {				/* 635a */
	ssound1(0x20);
}
void quirkysound(short data) {		// 6300
	queuesound(data + 0x25);
	/* was full of tamper protection - removed */
}
void queuesound(int data) {			// 62f2
	soundTraceEvent("queue", data);
	soundBackendEnqueue((unsigned short)data);
}
void setstagemusic(void) {
	sound_cq_1( (u16 []){1,2,3,5,4,6,7,8,12,11,9,10,13,13,13}[g.CurrentStage] );
}


void sound_cq_f7_ff(void) {
	soundTraceEvent("f7ff", 0xf7ff);
	soundBackendEnqueue(0xf7ffu);
}

void sound_tick(void) {
	unsigned short data;
	if (soundBackendCount == 0) return;
	data = soundBackendQueue[soundBackendRead];
	soundBackendRead = (soundBackendRead + 1u) % SOUND_BACKEND_QUEUE_LENGTH;
	--soundBackendCount;
	soundTraceEvent("drain", (int)data);
}
