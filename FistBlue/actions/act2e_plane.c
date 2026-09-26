/*
 *  act2e_plane.c
 *  MT2
 *
 *  Created by Ben on 5/05/12.
 *  Copyright 2012 Ben Torkington. All rights reserved.
 *
 */
#include <stdio.h>

#include "sf2.h"

#include "particle.h"
#include "sound.h"
#include "structs.h"
#include "lib.h"
#include "act2e_plane.h"

typedef struct UserData_Act2e UD2E;
extern Game g;

void synth_plane_setup(Object *obj, int city_from, int city_to) {
	UD2E *ud = (UD2E *)obj->UserData;
	ud->city_from = city_from;
	ud->city_to   = city_to;
}

// sin and cos for 64 angles, with an aspect ratio of 1.143:1
const VECT16 data_cfe74[64] = {
	// 0 degrees
	{ .x.full = 0x0000, .y.full = 0x02a0 }, { .x.full = 0x004b, .y.full = 0x029c }, { .x.full = 0x0095, .y.full = 0x0292 }, { .x.full = 0x00de, .y.full = 0x0282 },
	{ .x.full = 0x0125, .y.full = 0x026c }, { .x.full = 0x0169, .y.full = 0x024f }, { .x.full = 0x01aa, .y.full = 0x022e }, { .x.full = 0x01e6, .y.full = 0x0207 },	
	{ .x.full = 0x021e, .y.full = 0x01da }, { .x.full = 0x0251, .y.full = 0x01a9 }, { .x.full = 0x027e, .y.full = 0x0174 }, { .x.full = 0x02a4, .y.full = 0x013c },
	{ .x.full = 0x02c4, .y.full = 0x0100 }, { .x.full = 0x02de, .y.full = 0x00c2 }, { .x.full = 0x02f0, .y.full = 0x0082 }, { .x.full = 0x02fc, .y.full = 0x0041 },
	// 90 degrees
	{ .x.full = 0x0300, .y.full = 0x0000 }, { .x.full = 0x02fc, .y.full = 0xffbf }, { .x.full = 0x02f0, .y.full = 0xff7e }, { .x.full = 0x02de, .y.full = 0xff3e },
	{ .x.full = 0x02c4, .y.full = 0xff00 },
	{ .x.full = 0x02a4, .y.full = 0xfec4 },
	{ .x.full = 0x027e, .y.full = 0xfe8c },
	{ .x.full = 0x0251, .y.full = 0xfe57 },
	{ .x.full = 0x021e, .y.full = 0xfe26 },//18
	{ .x.full = 0x01e6, .y.full = 0xfdf9 },
	{ .x.full = 0x01aa, .y.full = 0xfdd2 },
	{ .x.full = 0x0169, .y.full = 0xfdb1 },
	{ .x.full = 0x0125, .y.full = 0xfd94 },
	{ .x.full = 0x00de, .y.full = 0xfd7e },
	{ .x.full = 0x0095, .y.full = 0xfd6e },
	{ .x.full = 0x004b, .y.full = 0xfd64 },
	{ .x.full = 0x0000, .y.full = 0xfd60 },//20
	{ .x.full = 0xffb5, .y.full = 0xfd64 },
	{ .x.full = 0xff6b, .y.full = 0xfd6e },
	{ .x.full = 0xff22, .y.full = 0xfd7e },
	{ .x.full = 0xfedb, .y.full = 0xfd94 },
	{ .x.full = 0xfe97, .y.full = 0xfdb1 },
	{ .x.full = 0xfe56, .y.full = 0xfdd2 },
	{ .x.full = 0xfe1a, .y.full = 0xfdf9 },
	{ .x.full = 0xfde2, .y.full = 0xfe26 },//28
	{ .x.full = 0xfdaf, .y.full = 0xfe57 },
	{ .x.full = 0xfd82, .y.full = 0xfe8c },
	{ .x.full = 0xfd5c, .y.full = 0xfec4 },
	{ .x.full = 0xfd3c, .y.full = 0xff00 },
	{ .x.full = 0xfd22, .y.full = 0xff3e },
	{ .x.full = 0xfd10, .y.full = 0xff7e },
	{ .x.full = 0xfd04, .y.full = 0xffbf },
	{ .x.full = 0xfd00, .y.full = 0x0000 },//30
	{ .x.full = 0xfd04, .y.full = 0x0041 },
	{ .x.full = 0xfd10, .y.full = 0x0082 },
	{ .x.full = 0xfd22, .y.full = 0x00c2 },
	{ .x.full = 0xfd3c, .y.full = 0x0100 },
	{ .x.full = 0xfd5c, .y.full = 0x013c },
	{ .x.full = 0xfd82, .y.full = 0x0174 },
	{ .x.full = 0xfdaf, .y.full = 0x01a9 },
	{ .x.full = 0xfde2, .y.full = 0x01da },//38
	{ .x.full = 0xfe1a, .y.full = 0x0207 },
	{ .x.full = 0xfe56, .y.full = 0x022e },
	{ .x.full = 0xfe97, .y.full = 0x024f },
	{ .x.full = 0xfedb, .y.full = 0x026c },
	{ .x.full = 0xff22, .y.full = 0x0282 },
	{ .x.full = 0xff6b, .y.full = 0x0292 },
	{ .x.full = 0xffb5, .y.full = 0x029c },
};



/*!
 action_2e
 sf2ua: 0x18f92
 description: plane on world map
 */

void action_2e(Object *obj) {
	UD2E *ud = (UD2E *)obj->UserData;
	static const POINT16 city_coords[12] = {		// 19040
		{ 0x00be, 0x00ab, }, { 0x00c4, 0x00b3, }, { 0x012c, 0x008c, }, { 0x0117, 0x00ac, },
		{ 0x0112, 0x00bb, }, { 0x00ae, 0x00b6, }, { 0x0088, 0x00bf, }, { 0x0092, 0x00a3, },
		{ 0x00a0, 0x00a0, }, { 0x00a4, 0x00a4, }, { 0x0103, 0x00b0, }, { 0x004e, 0x00b6, },
	};
	
	int d6;
	switch (obj->mode0) {
		case 0:
			switch (obj->mode1) {
				case 0:					
					NEXT(obj->mode1);
					obj->LocalTimer = 0x32;
					obj->Pool = 2;
					obj->Path = data_cfe74;
										
					if (ud->city_from == ud->city_to) {				// 1901e
						g.PlaneLandedInCity[ud->city_to] = TRUE;
						obj->mode0 = 6;						// die
						obj->mode1 = 0;
						g.Pause_9e1 = -1;
					} else {
						//18fd8
						obj->XPI = city_coords[ud->city_from].x;
						obj->YPI = city_coords[ud->city_from].y;
						ud->destination.x = city_coords[ud->city_to].x;
						ud->destination.y = city_coords[ud->city_to].y;
						d6 = calc_flightpath(obj, ud->destination.x, ud->destination.y);
						
						obj->Step = (d6 + 2) / 4;
                        RHSetActionList(obj, RHCODE(0x19fa2), (obj->Step+1) >> 3);
					}
					break;
				case 2:
					if (--obj->LocalTimer == 0) {
						NEXT(obj->mode0);
						obj->mode1 = 0;
						queuesound(SOUND_PLANE);
					}
					break;
					FATALDEFAULT;
			}
			break;
		case 2:
			//190a0
			if (obj->mode1 == 0) {
				d6 = calc_flightpath(obj, ud->destination.x, ud->destination.y);
				obj->Step = (d6 + 2) / 4;
				
				if ((ABS(obj->XPI - ud->destination.x) > 3)   ||	
					(ABS(obj->YPI - ud->destination.y) > 3)) {
					update_motion(obj);
					enqueue_and_layer(obj);
				} else {
					NEXT(obj->mode1);	// flight over
					g.Pause_9e1 = -1;
					g.PlaneLandedInCity[ud->city_to] = TRUE;
					ud->sound = (short []) {
						SOUND_JAPAN,	SOUND_JAPAN,	SOUND_BRAZIL,	SOUND_USA,
						SOUND_USA,		SOUND_CHINA,	SOUND_USSR,		SOUND_INDIA,
						SOUND_THAILAND,	SOUND_THAILAND, SOUND_USA,		SOUND_SPAIN,
					}[ud->city_to];
					obj->LocalTimer = 0x32;
					enqueue_and_layer(obj);
				}
			} else {
				if (--obj->LocalTimer == 0) {
					queuesound(ud->sound);
				}
				enqueue_and_layer(obj);
			}
			break;
		case 4:
		case 6:
			FreeActor(obj);
			break;
			FATALDEFAULT;
	}
}

