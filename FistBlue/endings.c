/*
 *  endings.c
 *  MT2
 *
 *  Created by Ben on 1/02/13.
 *  Copyright 2013 Ben Torkington. All rights reserved.
 *
 */

#include	"sf2.h"

#include	"gstate.h"
#include    "structs.h"
#include	"player.h"

#include	"particle.h"
#include	"lib.h"
#include    "sm.h"
#include	"effects.h"
#include	"actions.h"
#include	"gfxlib.h"
#include	"sound.h"
#include	"sprite.h"
#include	"demo.h"

#include "endings.h"


extern Game g;
extern struct effectstate es;
extern ScrollState gstate_Scroll1;
extern ScrollState gstate_Scroll2;
extern ScrollState gstate_Scroll3;

static void sub_94aec(int d2);

static void sm_ending_blanka(void);

void game_mode_26(void) {	// 7aea
	if (g.SkipEnding) {
		//aefe todo
	} else if (g.NotUsed) {
		// aaa6 todo
	} else {
		switch (g.mode2) {
			case 0:
				//a8be todo
				break;
			case 2:
				switch (g.BisonBeater) {
//					case FID_RYU:		sm_ending_ryu();		break;
//					case FID_E_HONDA:	sm_ending_ehonda();		break;
					case FID_BLANKA:	sm_ending_blanka();		break;
//					case FID_GUILE:		sm_ending_guile();		break;
//					case FID_KEN:		sm_ending_ken();		break;
//					case FID_CHUN_LI:	sm_ending_chunli();		break;
//					case FID_ZANGEIF:	sm_ending_zangeif();	break;
//					case FID_DHALSIM:	sm_ending_dhalsim();	break;
						FATALDEFAULT;
				}
				break;
			case 4:
				break;
			default:
				break;
		}
	}
	
	
	/* XXX */
}



static void sm_ending_blanka(void) {	// a554
	switch (g.mode3) {
		case 0:
			switch (g.mode4) {
				case 0:
					NEXT(g.mode4);
					es.FadeBusy = 1;
					QueueEffect(0xc1c, 3);
					__attribute__((fallthrough));
				case 2:
					if (!es.FadeBusy) {
						NEXT(g.mode3);
						g.mode4 = 0;
						_LBResetState();
						g.Stage = 0x12;
						TMInitForStage();
						palette_from_game();
					}
				FATALDEFAULT;
			}
			break;
		case 2:
			switch (g.mode4) {
				case 0:
					switch (g.mode5) {
						case 0:
							NEXT(g.mode5);
							g.CPS.DispEna = 0x780;
							g.ActionLibSel = 7;
							actionlibrary();
							g.ActionLibSel = 0;
							g.CPS.Scroll1X = 0;
							g.CPS.Scroll1Y = 0x100;
							sub_6126();
                            SET_VECTFP16(gstate_Scroll2.position, 0, 768);
							TMSetupScroll2(&gstate_Scroll2);
                            SET_VECTFP16(gstate_Scroll3.position, -32, 768);
							TMSetupScroll3(&gstate_Scroll3);
							sub_94aec(1);
							start_effect(2, 3);
							break;
						case 2:
							if (!g.SeqPause) {
								NEXT(g.mode5);
								es.FadeBusy = 1;
								QueueEffect(0x0c1c, 3);
							} else {
								proc_actions();
								DSDrawAllMain();
							}
							break;
						case 4:
							if (!es.FadeBusy) {
								NEXT(g.mode4);
								g.mode5 = 0;
								g.x02ec = 0;
								_LBResetState();
							}
							break;
						FATALDEFAULT;
					}
					break;
				case 2:
					switch (g.mode5) {
						case 0:
							NEXT(g.mode5);
							g.CPS.DispEna = 0x780;
							g.ActionLibSel = 8;
							actionlibrary();
							g.ActionLibSel = 0;
							g.CPS.Prio[1]  = 0;
							g.CPS.Scroll1X = 0;
							g.CPS.Scroll1Y = 0x100;
							sub_6126();
                            SET_VECTFP16(gstate_Scroll2.position, 512, 768);
							TMSetupScroll2(&gstate_Scroll2);
                            SET_VECTFP16(gstate_Scroll3.position, 512, 768);
							TMSetupScroll3(&gstate_Scroll3);
							sub_94aec(2);
							start_effect(0x2, 3);
							break;
						case 2:
							if (!g.SeqPause) {
								NEXT(g.mode2);
								g.mode3 = g.mode4 = g.mode5 = 0;
								task_kill(5);
							}
							proc_actions();
							DSDrawAllMain();
							break;
						default:
							break;
					}
					break;
				FATALDEFAULT;
			}
			break;
		default:
			break;
	}
}

static void sub_947b2() {		// task
	//todo
}
static void sub_94aec(int d2) {
	g.SeqPause = TRUE;
	create_task(sub_947b2, 5, g.BisonBeater, d2 >> 8, d2 & 0xff);
}
