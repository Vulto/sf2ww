/*
 * 
 *		glutBasics.c
 *		MustardTiger2 GLUT frontend
 *
 *
 */
 
#include <string.h>
#include <stdio.h>
#include <math.h>
#include <stdlib.h>
#include <time.h>
#include <stdint.h>
#include <errno.h>

#include <sys/types.h>

#ifdef __APPLE__
#include <GLUT/glut.h>
#include <OpenGL/glext.h>
#include <OpenGL/gl.h>
#include <OpenGL/glu.h>
#else
#include <GL/glut.h>
#include <GL/glext.h>
#include <GL/gl.h>
#include <GL/glu.h>
#endif

#include "trackball.h"

#include "sf2const.h"
#include "sf2types.h"
#include "sf2macros.h"
#include "task.h"
#include "structs.h"
#include "gfx_glut.h"
#include "lib.h"
#include "game.h"
#include "sf2io.h"
#include "gemu.h"
#include "workarounds.h"
#include "redhammer.h"


extern struct game g;
extern struct inputs gInputs;

//#define DEBUG

extern CPSGFXEMU gemu;
static const long CPS_FRAME_NS = 16768000L;
static struct timespec gNextFrame;
static FILE *gStateLog;
static FILE *gTimingLog;
static unsigned long gStateFrame;
static unsigned long gMaxFrames;
static unsigned long gVisualEvery;
static int gVisualFast;
static unsigned long gLastVisualFrame;
static char gVisualDir[512];

typedef struct {
   GLdouble x,y,z;
} recVec;

int gMainWindow = 0;

void SetLighting(unsigned int mode) {
    GLfloat mat_specular[] = {1.0, 1.0, 1.0, 1.0};
    GLfloat mat_shininess[] = {90.0};

    GLfloat position[4] = {0.0, 0.0, 12.0, 0.0};

    GLfloat ambient[4]  = {0.5, 0.5, 0.5, 1.0};
    GLfloat diffuse[4]  = {1.0, 1.0, 1.0, 1.0};
    GLfloat specular[4] = {1.0, 1.0, 1.0, 1.0};
    
    glMaterialfv (GL_FRONT_AND_BACK, GL_SPECULAR, mat_specular);
    glMaterialfv (GL_FRONT_AND_BACK, GL_SHININESS, mat_shininess);
    
    glEnable(GL_COLOR_MATERIAL);
    glColorMaterial(GL_FRONT_AND_BACK,GL_AMBIENT_AND_DIFFUSE);

    switch (mode) {
        case 0:
            break;
        case 1:
            glLightModeli(GL_LIGHT_MODEL_TWO_SIDE,GL_FALSE);
            glLightModeli(GL_LIGHT_MODEL_LOCAL_VIEWER,GL_FALSE);
            break;
        case 2:
            glLightModeli(GL_LIGHT_MODEL_TWO_SIDE,GL_FALSE);
            glLightModeli(GL_LIGHT_MODEL_LOCAL_VIEWER,GL_TRUE);
            break;
        case 3:
            glLightModeli(GL_LIGHT_MODEL_TWO_SIDE,GL_TRUE);
            glLightModeli(GL_LIGHT_MODEL_LOCAL_VIEWER,GL_FALSE);
            break;
        case 4:
            glLightModeli(GL_LIGHT_MODEL_TWO_SIDE,GL_TRUE);
            glLightModeli(GL_LIGHT_MODEL_LOCAL_VIEWER,GL_TRUE);
            break;
    }
    
    glLightfv(GL_LIGHT0,GL_POSITION,position);
    glLightfv(GL_LIGHT0,GL_AMBIENT,ambient);
    glLightfv(GL_LIGHT0,GL_DIFFUSE,diffuse);
    glLightfv(GL_LIGHT0,GL_SPECULAR,specular);
    glEnable(GL_LIGHT0);
}

void init (void) {
    manual_init();
    
    glShadeModel(GL_SMOOTH);
    glFrontFace(GL_CCW);
    
    glColor3f(1.0, 1.0, 1.0);
    gCameraReset ();
    
    glPolygonOffset (1.0, 1.0);
    SetLighting(4);
    glEnable(GL_LIGHTING);
}

void reshape (int w, int h) {
    glViewport(0,0,(GLsizei)w,(GLsizei)h);
    gfx_glut_reshape(w, h);
    glutPostRedisplay();
}
static void dump_visual_frame(void) {
    if (gVisualEvery == 0 || gStateFrame == 0 || (gStateFrame % gVisualEvery) != 0 || gLastVisualFrame == gStateFrame) {
        return;
    }
    gLastVisualFrame = gStateFrame;
    if (gStateFrame == 1380u) {
        FILE *objlog = fopen("native_visual_objects.txt", "w");
        if (objlog != NULL) {
            int count = 0;
            for (int oi = 0; oi < 256; ++oi) {
                if (gemu.Tilemap_Object[oi][3] == 0xff00) break;
                if (gemu.Tilemap_Object[oi][2] != 0) {
                    fprintf(objlog, "%d,%u,%u,%u,%u\n", oi,
                            gemu.Tilemap_Object[oi][0], gemu.Tilemap_Object[oi][1],
                            gemu.Tilemap_Object[oi][2], gemu.Tilemap_Object[oi][3]);
                    ++count;
                }
            }
            fprintf(objlog, "count=%d disp=%04x s1x=%04x s1y=%04x s2x=%04x s2y=%04x s3x=%04x s3y=%04x\n", count,
                    g.CPS.DispEna, g.CPS.Scroll1X, g.CPS.Scroll1Y,
                    g.CPS.Scroll2X, g.CPS.Scroll2Y, g.CPS.Scroll3X, g.CPS.Scroll3Y);
            for (int layer = 1; layer <= 3; ++layer) {
                unsigned nonblank = 0;
                unsigned nonzero = 0;
                for (unsigned ti = 0; ti < CPS1_OTHER_SIZE; ++ti) {
                    u16 tile = layer == 1 ? gemu.Tilemap_Scroll1[ti][0] :
                               (layer == 2 ? gemu.Tilemap_Scroll2[ti][0] : gemu.Tilemap_Scroll3[ti][0]);
                    u16 blank = layer == 1 ? TILE_BLANK_SCR1 :
                                (layer == 2 ? TILE_BLANK_SCR2 : TILE_BLANK_SCR3);
                    if (tile != blank) ++nonblank;
                    if (tile != 0) ++nonzero;
                }
                fprintf(objlog, "layer%d nonblank=%u nonzero=%u\n", layer, nonblank, nonzero);
            }
            fclose(objlog);
        }
    }

    GLint viewport[4];
    glGetIntegerv(GL_VIEWPORT, viewport);
    if (viewport[2] != 384 || viewport[3] != 224) {
        return;
    }

    size_t row_bytes = 384u * 3u;
    unsigned char *pixels = malloc(row_bytes * 224u);
    if (pixels == NULL) {
        return;
    }

    glReadPixels(0, 0, 384, 224, GL_RGB, GL_UNSIGNED_BYTE, pixels);

    char path[768];
    snprintf(path, sizeof(path), "%s/frame_%06lu.ppm", gVisualDir, gStateFrame);
    FILE *fp = fopen(path, "wb");
    if (fp == NULL) {
        free(pixels);
        return;
    }

    fprintf(fp, "P6\n384 224\n255\n");
    for (int y = 223; y >= 0; --y) {
        fwrite(pixels + ((size_t)y * row_bytes), 1, row_bytes, fp);
    }
    fclose(fp);
    free(pixels);
}

void maindisplay(void) {
    gfx_glut_drawgame();
    dump_visual_frame();
    glutSwapBuffers();
}
void mouse (int button, int state, int x, int y) {
    switch (button) {
        case GLUT_LEFT_BUTTON:
            switch (state) {
                case GLUT_DOWN:
                    gfx_glut_mousedown(x, y);
                    break;
                case GLUT_UP:
                    gfx_glut_mouseup(x, y);
                    break;
            }
            break;
        case GLUT_RIGHT_BUTTON:
            switch (state) {
                case GLUT_DOWN:
                    gfx_glut_rightmousedown(x, y);
                    break;
                case GLUT_UP:
                    gfx_glut_rightmouseup(x, y);
                    break;
            }
            break;
    }
}
void mouseMotion(int x, int y) {
    gfx_glut_mousedragged(x, y);
}
void special(int key, int px, int py) {
	(void)px;
	(void)py;
    switch (key) {
        case GLUT_KEY_UP:		gInputs.p10 |= JOY_UP;    break;
        case GLUT_KEY_DOWN:		gInputs.p10 |= JOY_DOWN;  break;
        case GLUT_KEY_LEFT:		gInputs.p10 |= JOY_LEFT;  break;
        case GLUT_KEY_RIGHT:	gInputs.p10 |= JOY_RIGHT; break;
        default:                                          break;
    }
}
void specialup(int key, int px, int py) {
	(void)px;
	(void)py;
    switch (key) {
        case GLUT_KEY_UP:       gInputs.p10 &= ~JOY_UP;    break;
        case GLUT_KEY_DOWN:     gInputs.p10 &= ~JOY_DOWN;  break;
        case GLUT_KEY_LEFT:     gInputs.p10 &= ~JOY_LEFT;  break;
        case GLUT_KEY_RIGHT:    gInputs.p10 &= ~JOY_RIGHT; break;
        default:                                           break;
    }
}

void keyup(unsigned char inkey, int px, int py) {
	(void)px;
	(void)py;
    switch (inkey) {
        case 'q':		gInputs.p10 &= ~(BUTTON_A);	            break;
        case 'w':		gInputs.p10 &= ~(BUTTON_B);	            break;
        case 'e':		gInputs.p10 &= ~(BUTTON_C);	            break;
        case 'a':		gInputs.p11 &= ~(BUTTON_D >> 8);        break;
        case 's':		gInputs.p11 &= ~(BUTTON_E >> 8);        break;
        case 'd':		gInputs.p11 &= ~(BUTTON_F >> 8);        break;
        case '1':       gInputs.in0 &= ~IPT_START1;	            break;
        case '2':       gInputs.in0 &= ~IPT_START2;	            break;
        case '5':       gInputs.in0 &= ~IPT_COIN1;	            break;
        case '6':       gInputs.in0 &= ~IPT_COIN2;	            break;
        
#ifdef REDHAMMER
        case 'k':
            g.Player2.Energy = -1;      break;
        case 'K':
            g.Player1.Energy = -1;      break;
#endif
        default: break;
    }
}
    
void key(unsigned char inkey, int px, int py){
	(void)px;
	(void)py;
    switch (inkey) {
        case 27:
            exit(0);
            break;
        case 'q':		gInputs.p10 |=  BUTTON_A;	   break;
        case 'w':		gInputs.p10 |=  BUTTON_B;	   break;
        case 'e':		gInputs.p10 |=  BUTTON_C;	   break;
        case 'a':		gInputs.p11 |=  BUTTON_D >> 8; break;
        case 's':		gInputs.p11 |=  BUTTON_E >> 8; break;
        case 'd':		gInputs.p11 |=  BUTTON_F >> 8; break;
        case '1':       gInputs.in0 |= IPT_START1;	   break;
        case '2':       gInputs.in0 |= IPT_START2;	   break;
        case '5':       gInputs.in0 |= IPT_COIN1;	   break;
        case '6':       gInputs.in0 |= IPT_COIN2;	   break;
            
    }
}
static void log_state_frame(void) {
    if (gStateLog == NULL) {
        return;
    }

    fprintf(gStateLog,
            "%lu,%llu,%llu,%u,%u,%u,%u,%u,%u,%u,%u,%u,"
            "%d,%d,%d,%d,%d,%u,%d,%d,%d,"
            "%d,%d,%d,%d,%d,%u,%d,%d,%d\n",
            gStateFrame,
            (unsigned long long)((gStateFrame - 1u) * 16768000ULL),
            (unsigned long long)((gStateFrame - 1u) * 167680ULL),
            g.mode0,
            g.tick,
            (unsigned)g.Stage,
            (unsigned)g.RoundCnt,
            (unsigned)g.TimeRemainBCD,
            (unsigned)g.TimeRemainTicks,
            (unsigned)g.FightOver,
            (unsigned)g.randSeed1,
            (unsigned)g.randSeed2,
            g.Player1.X.full,
            g.Player1.Y.full,
            g.Player1.mode0,
            g.Player1.mode1,
            g.Player1.mode2,
            (unsigned)g.Player1.AnimFlags,
            g.Player1.Energy,
            g.Player1.Move,
            g.Player1.StandSquat,
            g.Player2.X.full,
            g.Player2.Y.full,
            g.Player2.mode0,
            g.Player2.mode1,
            g.Player2.mode2,
            (unsigned)g.Player2.AnimFlags,
            g.Player2.Energy,
            g.Player2.Move,
            g.Player2.StandSquat);
    fflush(gStateLog);
}

static long timespec_diff_ns(const struct timespec *end, const struct timespec *start) {
    return (end->tv_sec - start->tv_sec) * 1000000000L +
           (end->tv_nsec - start->tv_nsec);
}

static void apply_lockstep_input(unsigned long frame) {
    if (getenv("SF2_INPUT_TEST") == NULL) {
        return;
    }

    gInputs.p10 = 0;
    gInputs.p11 = 0;
    gInputs.in0 = 0;

    if (frame >= 30 && frame < 36) {
        gInputs.in0 |= IPT_COIN1;
    } else if (frame >= 90 && frame < 96) {
        gInputs.in0 |= IPT_START1;
    }

    if (frame >= 120 && frame < 180) {
        gInputs.p10 |= JOY_RIGHT;
    } else if (frame >= 180 && frame < 240) {
        gInputs.p10 |= JOY_LEFT;
    } else if (frame >= 240 && frame < 300) {
        gInputs.p10 |= JOY_DOWN;
    } else if (frame >= 300 && frame < 360) {
        gInputs.p10 |= JOY_UP;
    }

    if (frame >= 120 && frame < 126) {
        gInputs.p10 |= BUTTON_A;
    } else if (frame >= 200 && frame < 206) {
        gInputs.p10 |= BUTTON_B;
    } else if (frame >= 280 && frame < 286) {
        gInputs.p10 |= BUTTON_C;
    } else if (frame >= 360 && frame < 366) {
        gInputs.p11 |= BUTTON_D >> 8;
    } else if (frame >= 440 && frame < 446) {
        gInputs.p11 |= BUTTON_E >> 8;
    } else if (frame >= 520 && frame < 526) {
        gInputs.p11 |= BUTTON_F >> 8;
    }
}

void timerFunc(int value) {
    (void)value;
    struct timespec now;
    struct timespec logic_start;
    struct timespec logic_end;
    long delay_ns;
    long host_logic_ns;
    long host_start_late_ns;
    unsigned delay_ms;

    if (clock_gettime(CLOCK_MONOTONIC, &now) != 0) {
        perror("clock_gettime");
        exit(EXIT_FAILURE);
    }
    host_start_late_ns = timespec_diff_ns(&now, &gNextFrame);
    if (host_start_late_ns < 0) {
        host_start_late_ns = 0;
    }

    logic_start = now;
    ++gStateFrame;
    apply_lockstep_input(gStateFrame);
    task_timer();

    if (clock_gettime(CLOCK_MONOTONIC, &logic_end) != 0) {
        perror("clock_gettime");
        exit(EXIT_FAILURE);
    }
    host_logic_ns = timespec_diff_ns(&logic_end, &logic_start);

    log_state_frame();
    if (gTimingLog != NULL) {
        fprintf(gTimingLog, "%lu,%llu,%llu,%ld,%ld\n",
                gStateFrame,
                (unsigned long long)((gStateFrame - 1u) * 16768000ULL),
                (unsigned long long)((gStateFrame - 1u) * 167680ULL),
                host_logic_ns,
                host_start_late_ns);
        fflush(gTimingLog);
    }

    if (gVisualEvery == 0 || (gStateFrame % gVisualEvery) == 0) {
        glutPostRedisplay();
    }

    if (gMaxFrames != 0 && gStateFrame >= gMaxFrames) {
        if (gStateLog != NULL) {
            fclose(gStateLog);
            gStateLog = NULL;
        }
        if (gTimingLog != NULL) {
            fclose(gTimingLog);
            gTimingLog = NULL;
        }
        exit(EXIT_SUCCESS);
    }

    now = logic_end;
    do {
        gNextFrame.tv_nsec += CPS_FRAME_NS;
        if (gNextFrame.tv_nsec >= 1000000000L) {
            gNextFrame.tv_nsec -= 1000000000L;
            ++gNextFrame.tv_sec;
        }
    } while (timespec_diff_ns(&gNextFrame, &now) <= 0);

    delay_ns = timespec_diff_ns(&gNextFrame, &now);
    delay_ms = (unsigned)((delay_ns + 999999L) / 1000000L);
    if (gVisualFast) {
        delay_ms = 1;
    } else if (delay_ms == 0) {
        delay_ms = 1;
    }
    glutTimerFunc(delay_ms, timerFunc, 0);
}
int main (int argc, const char * argv[])
{
    const char *visual_every = getenv("SF2_VISUAL_EVERY");
    if (visual_every != NULL && visual_every[0] != '\0') {
        char *end = NULL;
        unsigned long parsed = strtoul(visual_every, &end, 10);
        if (*end != '\0') {
            fprintf(stderr, "SF2_VISUAL_EVERY must be an unsigned integer\n");
            return EXIT_FAILURE;
        }
        gVisualEvery = parsed;
    }
    {
        const char *visual_dir = getenv("SF2_VISUAL_DIR");
        if (visual_dir != NULL && visual_dir[0] != '\0') {
            if (snprintf(gVisualDir, sizeof(gVisualDir), "%s", visual_dir) >= (int)sizeof(gVisualDir)) {
                fprintf(stderr, "SF2_VISUAL_DIR is too long\n");
                return EXIT_FAILURE;
            }
        }
    }

    gVisualFast = (getenv("SF2_VISUAL_FAST") != NULL);
    const char *max_frames = getenv("SF2_MAX_FRAMES");
    if (max_frames != NULL && max_frames[0] != '\0') {
        char *end = NULL;
        unsigned long parsed = strtoul(max_frames, &end, 10);
        if (*end != '\0') {
            fprintf(stderr, "SF2_MAX_FRAMES must be an unsigned integer\n");
            return EXIT_FAILURE;
        }
        gMaxFrames = parsed;
    }

    load_cps_roms();

    {
        const char *state_path = getenv("SF2_STATE_LOG");
        if (state_path != NULL && state_path[0] != '\0') {
            gStateLog = fopen(state_path, "w");
            if (gStateLog == NULL) {
                perror("SF2_STATE_LOG");
                return EXIT_FAILURE;
            }
            fprintf(gStateLog,
                    "frame,arcade_time_ns,arcade_cpu_cycles,game_mode,game_tick,stage,round_cnt,time_bcd,time_ticks,fight_over,rng1,rng2,"
                    "p1_x,p1_y,p1_mode0,p1_mode1,p1_mode2,p1_anim,p1_energy,p1_move,p1_stand_squat,"
                    "p2_x,p2_y,p2_mode0,p2_mode1,p2_mode2,p2_anim,p2_energy,p2_move,p2_stand_squat\n");
        }
    }
    {
        const char *timing_path = getenv("SF2_TIMING_LOG");
        if (timing_path != NULL && timing_path[0] != '\0') {
            gTimingLog = fopen(timing_path, "w");
            if (gTimingLog == NULL) {
                perror("SF2_TIMING_LOG");
                return EXIT_FAILURE;
            }
            fprintf(gTimingLog, "frame,arcade_time_ns,arcade_cpu_cycles,host_logic_ns,host_start_late_ns\n");
        }
    }

    glutInit(&argc, (char **)argv);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB | GLUT_DEPTH); 
    glutInitWindowPosition (300, 50);
    if (gVisualEvery != 0) {
        glutInitWindowSize (384, 224);
    } else {
        glutInitWindowSize (900, 600);
    }
    gMainWindow = glutCreateWindow("sf2GL");

    init();					// standard GL init
    gfx_glut_init();
    
    glutIgnoreKeyRepeat(TRUE);

    glutReshapeFunc (reshape);
    glutDisplayFunc (maindisplay);
    glutKeyboardFunc (key);
    glutKeyboardUpFunc(keyup);
    glutSpecialFunc (special);
    glutSpecialUpFunc (specialup);
    glutMouseFunc (mouse);
    glutMotionFunc(mouseMotion);
    if (clock_gettime(CLOCK_MONOTONIC, &gNextFrame) != 0) {
        perror("clock_gettime");
        return EXIT_FAILURE;
    }
    gNextFrame.tv_nsec += CPS_FRAME_NS;
    if (gNextFrame.tv_nsec >= 1000000000L) {
        gNextFrame.tv_nsec -= 1000000000L;
        ++gNextFrame.tv_sec;
    }
    glutTimerFunc((unsigned)((CPS_FRAME_NS + 999999L) / 1000000L), timerFunc, 0);
    glutMainLoop();
    return 0;
}
