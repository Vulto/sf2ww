//
//  redhammer.c
//  MT2
//
//  Created by bjt on 23/12/15.
//
//

#ifndef CPS

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#endif

#include <unistd.h>

#include "redhammer.h"

#include "sf2types.h"

char *g_code_roms = 0;
char *g_sound_roms = 0;
char *g_gfx_roms = 0;

#define REDHAMMER_USE_ALLROMS_BIN

#ifndef REDHAMMER_USE_ALLROMS_BIN
const char *code_rom_names[] = {
    "sf2u.30a", "sf2u.37a", "sf2u.31a", "sf2u.38a",
    "sf2u.28a", "sf2u.35a", "sf2_29a.bin", "sf2_36a.bin",
};
#endif

#define CODE_ROM_SIZE 0x20000
#define ROM_PAIR_SIZE (CODE_ROM_SIZE * 2)
#define ALL_CODE_SIZE (CODE_ROM_SIZE * 8)

const char *gfx_rom_names[] = {
    "sf2_06.bin", "sf2_08.bin", "sf2_05.bin", "sf2_07.bin",
    "sf2_15.bin", "sf2_17.bin", "sf2_14.bin", "sf2_16.bin",
    "sf2_25.bin", "sf2_27.bin", "sf2_24.bin", "sf2_26.bin",
};
const char *sound_rom_names[] = { "sf2_09.bin" };
const char *sample_rom_names[] = { "sf2_18.bin", "sf2_19.bin" };

#ifndef CPS
void load_cps_roms()
{
    g_code_roms = malloc(ALL_CODE_SIZE);
    if (g_code_roms == NULL) {
        puts("Can't allocate memory!");
        exit(EXIT_FAILURE);
    }
#ifdef REDHAMMER_USE_ALLROMS_BIN
    FILE *allroms = fopen("allroms.bin", "rb");
    if (allroms == NULL) {
        puts("Can't open allroms.bin\n");
        exit(EXIT_FAILURE);
    }
    long bytesread = fread(g_code_roms, 1, ALL_CODE_SIZE, allroms);
    printf("allroms: read %ld bytes\n", bytesread);
    fclose(allroms);
    if (bytesread != ALL_CODE_SIZE) {
        fprintf(stderr, "allroms.bin: expected %d bytes, got %ld\n", ALL_CODE_SIZE, bytesread);
        exit(EXIT_FAILURE);
    }
#else
    FILE *rom0;
    FILE *rom1;
    for (int i = 0; i < 4; ++i) {
        rom0 = fopen(code_rom_names[2*i + 0], "r");
        rom1 = fopen(code_rom_names[2*i + 1], "r");
        for (int j = 0; j < CODE_ROM_SIZE; ++j) {
            g_code_roms[(i * ROM_PAIR_SIZE) + (2 * j) + 0] = getc(rom0);
            g_code_roms[(i * ROM_PAIR_SIZE) + (2 * j) + 1] = getc(rom1);
        }
        fclose(rom0);
        fclose(rom1);
    }
#endif
}
#endif

void *RHCodePtrRange(u32 offset, size_t size)
{
    if (g_code_roms == NULL) {
        fprintf(stderr, "RHCODE: ROM image is not loaded (offset 0x%08x)\n", offset);
        abort();
    }
    if ((size_t)offset > ALL_CODE_SIZE || size > ALL_CODE_SIZE - (size_t)offset) {
        fprintf(stderr, "RHCODE: ROM range 0x%08x + 0x%zx outside 0x00000000..0x%08x\n",
                offset, size, ALL_CODE_SIZE - 1);
        abort();
    }
    return g_code_roms + offset;
}

void *RHCodePtrChecked(u32 offset, const char *file, int line)
{
    if (g_code_roms == NULL) {
        fprintf(stderr, "RHCODE: ROM image is not loaded at %s:%d (offset 0x%08x)\n", file, line, offset);
        abort();
    }
    if (offset >= ALL_CODE_SIZE) {
        fprintf(stderr, "RHCODE: invalid ROM offset at %s:%d: 0x%08x (range 0x00000000..0x%08x)\n",
                file, line, offset, ALL_CODE_SIZE - 1);
        abort();
    }
    return g_code_roms + offset;
}

void *RHCodePtr(u32 offset)
{
    return RHCodePtrRange(offset, 1);
}

static u16 RHReadWordAt(u32 offset)
{
    u16 value;
    memcpy(&value, RHCodePtrRange(offset, sizeof(value)), sizeof(value));
    return RHSwapWord(value);
}

static u32 RHReadLongAt(u32 offset)
{
    u32 value;
    memcpy(&value, RHCodePtrRange(offset, sizeof(value)), sizeof(value));
    return RHSwapLong(value);
}

void print_rom_offset(const char *message, const void *addr)
{
    if (addr < (const void *)g_code_roms || addr >= (const void *)(g_code_roms + ALL_CODE_SIZE)) {
        printf("%s: non-ROM pointer %p\n", message, addr);
        return;
    }
    printf("%s: %08lx\n", message, ((const char *)addr) - g_code_roms);
}

const void *RHOffsetLookup16(const u16 *base, int index)
{
    u16 offset;
    memcpy(&offset, (const char *)base + (size_t)index * sizeof(offset), sizeof(offset));
    offset = RHSwapWord(offset);
    return (const char *)base + (short)offset;
}

const u16 RHWordOffset(u32 base, int index) { return RHReadWordAt(base + (u32)index * 2u); }
const u8 RHByteOffset(u32 base, int index) { return *(u8 *)RHCodePtrRange(base + (u32)index, 1); }

const u32 RH3DLong(u32 base, int dim2, int dim3, int i1, int i2, int i3)
{
    u32 index = (u32)i1 * (u32)dim2 * (u32)dim3 + (u32)i2 * (u32)dim3 + (u32)i3;
    return RHReadLongAt(base + index * 4u);
}
const u32 RH2DLong(u32 base, int dim2, int i1, int i2)
{
    u32 index = (u32)i1 * (u32)dim2 + (u32)i2;
    return RHReadLongAt(base + index * 4u);
}
const u32 RH1DLong(u32 base, int index) { return RHReadLongAt(base + (u32)index * 4u); }
const u16 RH3DWord(u32 base, int dim2, int dim3, int i1, int i2, int i3)
{
    u32 index = (u32)i1 * (u32)dim2 * (u32)dim3 + (u32)i2 * (u32)dim3 + (u32)i3;
    return RHReadWordAt(base + index * 2u);
}
const short RH3DShort(u32 base, int dim2, int dim3, int i1, int i2, int i3) { return (short)RH3DWord(base, dim2, dim3, i1, i2, i3); }
const u16 RH2DWord(u32 base, int dim2, int i1, int i2)
{
    u32 index = (u32)i1 * (u32)dim2 + (u32)i2;
    return RHReadWordAt(base + index * 2u);
}
const short RH2DShort(u32 base, int dim2, int i1, int i2) { return (short)RH2DWord(base, dim2, i1, i2); }
const u8 RH3DByte(u32 base, int dim2, int dim3, int i1, int i2, int i3)
{
    u32 index = (u32)i1 * (u32)dim2 * (u32)dim3 + (u32)i2 * (u32)dim3 + (u32)i3;
    return *(u8 *)RHCodePtrRange(base + index, 1);
}
const u8 RH2DByte(u32 base, int dim2, int i1, int i2)
{
    u32 index = (u32)i1 * (u32)dim2 + (u32)i2;
    return *(u8 *)RHCodePtrRange(base + index, 1);
}

inline u32 RHSwapLong(const u32 num)
{
#ifdef SF2_ENDIAN_LITTLE
    return ((num>>24)&0xff) | ((num<<8)&0xff0000) | ((num>>8)&0xff00) | ((num<<24)&0xff000000);
#else
    return num;
#endif
}
inline u16 RHSwapWord(const u16 num)
{
#ifdef SF2_ENDIAN_LITTLE
    return ((num >> 8) & 0xff) | ((num << 8) & 0xff00);
#else
    return num;
#endif
}
u32 RHReadLong(int romaddr) { return RHReadLongAt((u32)romaddr); }
u16 RHReadWord(int romaddr) { return RHReadWordAt((u32)romaddr); }

void redhammer_run_tests(void)
{
    static const u16 data_13b06[3][8][4] = {
        {{0x0020,0x0000,0x0230,0x0058},{0xFFCE,0x0000,0x0180,0x0048},{0x0040,0x0000,0x0180,0x0060},{0xFFCF,0x0000,0x0190,0x0010},{0x0025,0x0000,0x0190,0x0058},{0xFFF0,0x0000,0x0200,0x0048},{0x0022,0x0000,0x0210,0x0050},{0xFFEE,0x0000,0x02C0,0x0050}},
        {{0x0100,0x0000,0x0400,0x0062},{0x0110,0x0000,0x0540,0x0053},{0xFEA0,0x0000,0x0330,0x0042},{0xFEE0,0x0000,0x0130,0x0053},{0x0120,0x0000,0x0400,0x0045},{0x0120,0x0000,0x0530,0x0063},{0xFEEB,0x0000,0x0340,0x0053},{0xFED0,0x0000,0x0530,0x0043}},
        {{0x0223,0x0000,0x0600,0x0052},{0xFEA0,0x0000,0x0480,0x0040},{0x0183,0x0000,0x0480,0x0040},{0xFE40,0x0000,0x0600,0x0045},{0x0223,0x0000,0x0600,0x0054},{0xFCD0,0x0000,0x0480,0x0050},{0x0143,0x0000,0x0480,0x0040},{0xFDD0,0x0000,0x0600,0x0064}}
    };
    for (int i = 0; i < 3; ++i)
        for (int j = 0; j < 8; ++j)
            for (int k = 0; k < 4; ++k)
                if (data_13b06[i][j][k] != RH3DWord(0x13b06, 8, 4, i, j, k))
                    printf("incorrect\n");
}
