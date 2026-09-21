//
//  test_redhammer.c
//  FBTests
//
//  Created by Ben Torkington on 8/01/23.
//

#include <stdarg.h>
#include <stddef.h>
#include <setjmp.h>
#include <stdint.h>
#include <cmocka.h>
#include "test_redhammer.h"

#include "redhammer.h"
#include "particle.h"

char testRom[] = {
    0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
    0xff, 0xf8, 0xff, 0xfa, 0x00, 0x08, 0x00, 0x0a,
    0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
    0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
    0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
    0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 0x08,
};

void test_RHReadWord(void **state) {
    assert_int_equal(0x304, RHReadWord(2));
}

void test_RHReadLong(void **state) {
    assert_int_equal(0x5060708, RHReadLong(4));
}

void test_RHReadWord16_negative_offset(void **state) {
    assert_ptr_equal(&testRom[0], RHOffsetLookup16(RHCODE(8), 0));
    assert_ptr_equal(&testRom[2], RHOffsetLookup16(RHCODE(8), 1));
}

void test_RHReadWord16_positive_offset(void **state) {
    assert_ptr_equal(&testRom[16], RHOffsetLookup16(RHCODE(8), 2));
    assert_ptr_equal(&testRom[18], RHOffsetLookup16(RHCODE(8), 3));
}

void test_RHCODE(void **state) {
    assert_ptr_equal(&testRom[0], RHCODE(0));
    assert_ptr_equal(&testRom[8], RHCODE(8));
    assert_ptr_equal(&testRom[-8], RHCODE(-8));
}

void test_RHCodeOffsetChecked(void **state) {
    assert_int_equal(8, RHCODE_OFFSET(&testRom[8], 2));
    assert_int_equal(0, RHCODE_OFFSET(&testRom[0], 1));
}

void test_RHReadWordPtr(void **state) {
    assert_int_equal(0x304, RHReadWordPtr(&testRom[2]));
}

void test_FBAction_layout(void **state) {
    assert_int_equal(4, offsetof(FBAction, Image));
    assert_int_equal(14, offsetof(FBAction, Shadow));
    assert_int_equal(19, offsetof(FBAction, FlipBits));
    assert_int_equal(20, offsetof(FBAction, YOffset));
    assert_int_equal(24, sizeof(FBAction));
}
