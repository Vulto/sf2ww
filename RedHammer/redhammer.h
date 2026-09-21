//
//  redhammer.h
//  MT2
//
//  Created by Ben Torkington on 29/11/14.
//
//

#ifndef MT2_redhammer_h
#define MT2_redhammer_h

#include "sf2types.h"
#include <stddef.h>
#include <stdint.h>

extern char *g_code_roms;

struct fistblue_tile_plane {
    int y1;
    int y2;
    float z1;
    float z2;
};
typedef struct fistblue_tile_plane RHTilePlane;

void load_cps_roms(void);
void *RHCodePtr(u32 offset);
void *RHCodePtrChecked(u32 offset, const char *file, int line);
void *RHCodePtrRange(u32 offset, size_t size);
u32 RHCodeOffsetChecked(const void *addr, size_t size, const char *file, int line);
u16 RHReadWordPtr(const void *addr);
const void *RHOffsetLookup16(const u16 *base, int index);
const u16 RHWordOffset(u32 base, int index);
const u8 RHByteOffset(u32 base, int index);
const u32 RH3DLong(u32 base, int dim2, int dim3, int i1, int i2, int i3);
const u32 RH2DLong(u32 base, int dim2, int i1, int i2);
const u32 RH1DLong(u32 base, int index);
const u16 RH3DWord(u32 base, int dim2, int dim3, int i1, int i2, int i3);
const short RH3DShort(u32 base, int dim2, int dim3, int i1, int i2, int i3);
const u16 RH2DWord(u32 base, int dim2, int i1, int i2);
const short RH2DShort(u32 base, int dim2, int i1, int i2);
const u8 RH3DByte(u32 base, int dim2, int dim3, int i1, int i2, int i3);
const u8 RH2DByte(u32 base, int dim2, int i1, int i2);
u32 RHSwapLong(const u32 num);
u16 RHSwapWord(const u16 num);
u32 RHReadLong(int romaddr);
u16 RHReadWord(int romaddr);
void print_rom_offset(const char *message, const void *addr);
typedef u32 RHROMPtr;
typedef u16 RHShortPtr;
#define RHCODE(x) RHCodePtrChecked((u32)(x), __FILE__, __LINE__)
#define RHCODE_OFFSET(x, size) RHCodeOffsetChecked((x), (size), __FILE__, __LINE__)
#define RHCODE16(x) ((u16 *)RHCodePtrChecked((u32)(x), __FILE__, __LINE__))
#define RHCODE16_ARRAY(base, stride, index) ((u16 *)RHCodePtrRange((u32)(base) + 2u * (u32)(stride) * (u32)(index), (size_t)(stride) * sizeof(u16)))
void redhammer_run_tests(void);

#endif
