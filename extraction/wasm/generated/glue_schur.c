#ifndef GLUE_SCHUR_C
#define GLUE_SCHUR_C
#include <gc_stack.h>
#include <stdio.h>
#include "glue_schur.h"
struct closure;
struct closure {
  value (*func)(struct thread_info *, value, value);
  value env;
};

extern int is_ptr(value);
unsigned long long get_unboxed_ordinal(value);
unsigned long long get_boxed_ordinal(value);
value *get_args(value);
value make_Corelib_Init_Datatypes_list_nil(void);
value make_Corelib_Init_Datatypes_list_cons(value, value, value *);
value alloc_make_Corelib_Init_Datatypes_list_cons(struct thread_info *, value, value);
value make_Corelib_Init_Byte_byte_x00(void);
value make_Corelib_Init_Byte_byte_x01(void);
value make_Corelib_Init_Byte_byte_x02(void);
value make_Corelib_Init_Byte_byte_x03(void);
value make_Corelib_Init_Byte_byte_x04(void);
value make_Corelib_Init_Byte_byte_x05(void);
value make_Corelib_Init_Byte_byte_x06(void);
value make_Corelib_Init_Byte_byte_x07(void);
value make_Corelib_Init_Byte_byte_x08(void);
value make_Corelib_Init_Byte_byte_x09(void);
value make_Corelib_Init_Byte_byte_x0a(void);
value make_Corelib_Init_Byte_byte_x0b(void);
value make_Corelib_Init_Byte_byte_x0c(void);
value make_Corelib_Init_Byte_byte_x0d(void);
value make_Corelib_Init_Byte_byte_x0e(void);
value make_Corelib_Init_Byte_byte_x0f(void);
value make_Corelib_Init_Byte_byte_x10(void);
value make_Corelib_Init_Byte_byte_x11(void);
value make_Corelib_Init_Byte_byte_x12(void);
value make_Corelib_Init_Byte_byte_x13(void);
value make_Corelib_Init_Byte_byte_x14(void);
value make_Corelib_Init_Byte_byte_x15(void);
value make_Corelib_Init_Byte_byte_x16(void);
value make_Corelib_Init_Byte_byte_x17(void);
value make_Corelib_Init_Byte_byte_x18(void);
value make_Corelib_Init_Byte_byte_x19(void);
value make_Corelib_Init_Byte_byte_x1a(void);
value make_Corelib_Init_Byte_byte_x1b(void);
value make_Corelib_Init_Byte_byte_x1c(void);
value make_Corelib_Init_Byte_byte_x1d(void);
value make_Corelib_Init_Byte_byte_x1e(void);
value make_Corelib_Init_Byte_byte_x1f(void);
value make_Corelib_Init_Byte_byte_x20(void);
value make_Corelib_Init_Byte_byte_x21(void);
value make_Corelib_Init_Byte_byte_x22(void);
value make_Corelib_Init_Byte_byte_x23(void);
value make_Corelib_Init_Byte_byte_x24(void);
value make_Corelib_Init_Byte_byte_x25(void);
value make_Corelib_Init_Byte_byte_x26(void);
value make_Corelib_Init_Byte_byte_x27(void);
value make_Corelib_Init_Byte_byte_x28(void);
value make_Corelib_Init_Byte_byte_x29(void);
value make_Corelib_Init_Byte_byte_x2a(void);
value make_Corelib_Init_Byte_byte_x2b(void);
value make_Corelib_Init_Byte_byte_x2c(void);
value make_Corelib_Init_Byte_byte_x2d(void);
value make_Corelib_Init_Byte_byte_x2e(void);
value make_Corelib_Init_Byte_byte_x2f(void);
value make_Corelib_Init_Byte_byte_x30(void);
value make_Corelib_Init_Byte_byte_x31(void);
value make_Corelib_Init_Byte_byte_x32(void);
value make_Corelib_Init_Byte_byte_x33(void);
value make_Corelib_Init_Byte_byte_x34(void);
value make_Corelib_Init_Byte_byte_x35(void);
value make_Corelib_Init_Byte_byte_x36(void);
value make_Corelib_Init_Byte_byte_x37(void);
value make_Corelib_Init_Byte_byte_x38(void);
value make_Corelib_Init_Byte_byte_x39(void);
value make_Corelib_Init_Byte_byte_x3a(void);
value make_Corelib_Init_Byte_byte_x3b(void);
value make_Corelib_Init_Byte_byte_x3c(void);
value make_Corelib_Init_Byte_byte_x3d(void);
value make_Corelib_Init_Byte_byte_x3e(void);
value make_Corelib_Init_Byte_byte_x3f(void);
value make_Corelib_Init_Byte_byte_x40(void);
value make_Corelib_Init_Byte_byte_x41(void);
value make_Corelib_Init_Byte_byte_x42(void);
value make_Corelib_Init_Byte_byte_x43(void);
value make_Corelib_Init_Byte_byte_x44(void);
value make_Corelib_Init_Byte_byte_x45(void);
value make_Corelib_Init_Byte_byte_x46(void);
value make_Corelib_Init_Byte_byte_x47(void);
value make_Corelib_Init_Byte_byte_x48(void);
value make_Corelib_Init_Byte_byte_x49(void);
value make_Corelib_Init_Byte_byte_x4a(void);
value make_Corelib_Init_Byte_byte_x4b(void);
value make_Corelib_Init_Byte_byte_x4c(void);
value make_Corelib_Init_Byte_byte_x4d(void);
value make_Corelib_Init_Byte_byte_x4e(void);
value make_Corelib_Init_Byte_byte_x4f(void);
value make_Corelib_Init_Byte_byte_x50(void);
value make_Corelib_Init_Byte_byte_x51(void);
value make_Corelib_Init_Byte_byte_x52(void);
value make_Corelib_Init_Byte_byte_x53(void);
value make_Corelib_Init_Byte_byte_x54(void);
value make_Corelib_Init_Byte_byte_x55(void);
value make_Corelib_Init_Byte_byte_x56(void);
value make_Corelib_Init_Byte_byte_x57(void);
value make_Corelib_Init_Byte_byte_x58(void);
value make_Corelib_Init_Byte_byte_x59(void);
value make_Corelib_Init_Byte_byte_x5a(void);
value make_Corelib_Init_Byte_byte_x5b(void);
value make_Corelib_Init_Byte_byte_x5c(void);
value make_Corelib_Init_Byte_byte_x5d(void);
value make_Corelib_Init_Byte_byte_x5e(void);
value make_Corelib_Init_Byte_byte_x5f(void);
value make_Corelib_Init_Byte_byte_x60(void);
value make_Corelib_Init_Byte_byte_x61(void);
value make_Corelib_Init_Byte_byte_x62(void);
value make_Corelib_Init_Byte_byte_x63(void);
value make_Corelib_Init_Byte_byte_x64(void);
value make_Corelib_Init_Byte_byte_x65(void);
value make_Corelib_Init_Byte_byte_x66(void);
value make_Corelib_Init_Byte_byte_x67(void);
value make_Corelib_Init_Byte_byte_x68(void);
value make_Corelib_Init_Byte_byte_x69(void);
value make_Corelib_Init_Byte_byte_x6a(void);
value make_Corelib_Init_Byte_byte_x6b(void);
value make_Corelib_Init_Byte_byte_x6c(void);
value make_Corelib_Init_Byte_byte_x6d(void);
value make_Corelib_Init_Byte_byte_x6e(void);
value make_Corelib_Init_Byte_byte_x6f(void);
value make_Corelib_Init_Byte_byte_x70(void);
value make_Corelib_Init_Byte_byte_x71(void);
value make_Corelib_Init_Byte_byte_x72(void);
value make_Corelib_Init_Byte_byte_x73(void);
value make_Corelib_Init_Byte_byte_x74(void);
value make_Corelib_Init_Byte_byte_x75(void);
value make_Corelib_Init_Byte_byte_x76(void);
value make_Corelib_Init_Byte_byte_x77(void);
value make_Corelib_Init_Byte_byte_x78(void);
value make_Corelib_Init_Byte_byte_x79(void);
value make_Corelib_Init_Byte_byte_x7a(void);
value make_Corelib_Init_Byte_byte_x7b(void);
value make_Corelib_Init_Byte_byte_x7c(void);
value make_Corelib_Init_Byte_byte_x7d(void);
value make_Corelib_Init_Byte_byte_x7e(void);
value make_Corelib_Init_Byte_byte_x7f(void);
value make_Corelib_Init_Byte_byte_x80(void);
value make_Corelib_Init_Byte_byte_x81(void);
value make_Corelib_Init_Byte_byte_x82(void);
value make_Corelib_Init_Byte_byte_x83(void);
value make_Corelib_Init_Byte_byte_x84(void);
value make_Corelib_Init_Byte_byte_x85(void);
value make_Corelib_Init_Byte_byte_x86(void);
value make_Corelib_Init_Byte_byte_x87(void);
value make_Corelib_Init_Byte_byte_x88(void);
value make_Corelib_Init_Byte_byte_x89(void);
value make_Corelib_Init_Byte_byte_x8a(void);
value make_Corelib_Init_Byte_byte_x8b(void);
value make_Corelib_Init_Byte_byte_x8c(void);
value make_Corelib_Init_Byte_byte_x8d(void);
value make_Corelib_Init_Byte_byte_x8e(void);
value make_Corelib_Init_Byte_byte_x8f(void);
value make_Corelib_Init_Byte_byte_x90(void);
value make_Corelib_Init_Byte_byte_x91(void);
value make_Corelib_Init_Byte_byte_x92(void);
value make_Corelib_Init_Byte_byte_x93(void);
value make_Corelib_Init_Byte_byte_x94(void);
value make_Corelib_Init_Byte_byte_x95(void);
value make_Corelib_Init_Byte_byte_x96(void);
value make_Corelib_Init_Byte_byte_x97(void);
value make_Corelib_Init_Byte_byte_x98(void);
value make_Corelib_Init_Byte_byte_x99(void);
value make_Corelib_Init_Byte_byte_x9a(void);
value make_Corelib_Init_Byte_byte_x9b(void);
value make_Corelib_Init_Byte_byte_x9c(void);
value make_Corelib_Init_Byte_byte_x9d(void);
value make_Corelib_Init_Byte_byte_x9e(void);
value make_Corelib_Init_Byte_byte_x9f(void);
value make_Corelib_Init_Byte_byte_xa0(void);
value make_Corelib_Init_Byte_byte_xa1(void);
value make_Corelib_Init_Byte_byte_xa2(void);
value make_Corelib_Init_Byte_byte_xa3(void);
value make_Corelib_Init_Byte_byte_xa4(void);
value make_Corelib_Init_Byte_byte_xa5(void);
value make_Corelib_Init_Byte_byte_xa6(void);
value make_Corelib_Init_Byte_byte_xa7(void);
value make_Corelib_Init_Byte_byte_xa8(void);
value make_Corelib_Init_Byte_byte_xa9(void);
value make_Corelib_Init_Byte_byte_xaa(void);
value make_Corelib_Init_Byte_byte_xab(void);
value make_Corelib_Init_Byte_byte_xac(void);
value make_Corelib_Init_Byte_byte_xad(void);
value make_Corelib_Init_Byte_byte_xae(void);
value make_Corelib_Init_Byte_byte_xaf(void);
value make_Corelib_Init_Byte_byte_xb0(void);
value make_Corelib_Init_Byte_byte_xb1(void);
value make_Corelib_Init_Byte_byte_xb2(void);
value make_Corelib_Init_Byte_byte_xb3(void);
value make_Corelib_Init_Byte_byte_xb4(void);
value make_Corelib_Init_Byte_byte_xb5(void);
value make_Corelib_Init_Byte_byte_xb6(void);
value make_Corelib_Init_Byte_byte_xb7(void);
value make_Corelib_Init_Byte_byte_xb8(void);
value make_Corelib_Init_Byte_byte_xb9(void);
value make_Corelib_Init_Byte_byte_xba(void);
value make_Corelib_Init_Byte_byte_xbb(void);
value make_Corelib_Init_Byte_byte_xbc(void);
value make_Corelib_Init_Byte_byte_xbd(void);
value make_Corelib_Init_Byte_byte_xbe(void);
value make_Corelib_Init_Byte_byte_xbf(void);
value make_Corelib_Init_Byte_byte_xc0(void);
value make_Corelib_Init_Byte_byte_xc1(void);
value make_Corelib_Init_Byte_byte_xc2(void);
value make_Corelib_Init_Byte_byte_xc3(void);
value make_Corelib_Init_Byte_byte_xc4(void);
value make_Corelib_Init_Byte_byte_xc5(void);
value make_Corelib_Init_Byte_byte_xc6(void);
value make_Corelib_Init_Byte_byte_xc7(void);
value make_Corelib_Init_Byte_byte_xc8(void);
value make_Corelib_Init_Byte_byte_xc9(void);
value make_Corelib_Init_Byte_byte_xca(void);
value make_Corelib_Init_Byte_byte_xcb(void);
value make_Corelib_Init_Byte_byte_xcc(void);
value make_Corelib_Init_Byte_byte_xcd(void);
value make_Corelib_Init_Byte_byte_xce(void);
value make_Corelib_Init_Byte_byte_xcf(void);
value make_Corelib_Init_Byte_byte_xd0(void);
value make_Corelib_Init_Byte_byte_xd1(void);
value make_Corelib_Init_Byte_byte_xd2(void);
value make_Corelib_Init_Byte_byte_xd3(void);
value make_Corelib_Init_Byte_byte_xd4(void);
value make_Corelib_Init_Byte_byte_xd5(void);
value make_Corelib_Init_Byte_byte_xd6(void);
value make_Corelib_Init_Byte_byte_xd7(void);
value make_Corelib_Init_Byte_byte_xd8(void);
value make_Corelib_Init_Byte_byte_xd9(void);
value make_Corelib_Init_Byte_byte_xda(void);
value make_Corelib_Init_Byte_byte_xdb(void);
value make_Corelib_Init_Byte_byte_xdc(void);
value make_Corelib_Init_Byte_byte_xdd(void);
value make_Corelib_Init_Byte_byte_xde(void);
value make_Corelib_Init_Byte_byte_xdf(void);
value make_Corelib_Init_Byte_byte_xe0(void);
value make_Corelib_Init_Byte_byte_xe1(void);
value make_Corelib_Init_Byte_byte_xe2(void);
value make_Corelib_Init_Byte_byte_xe3(void);
value make_Corelib_Init_Byte_byte_xe4(void);
value make_Corelib_Init_Byte_byte_xe5(void);
value make_Corelib_Init_Byte_byte_xe6(void);
value make_Corelib_Init_Byte_byte_xe7(void);
value make_Corelib_Init_Byte_byte_xe8(void);
value make_Corelib_Init_Byte_byte_xe9(void);
value make_Corelib_Init_Byte_byte_xea(void);
value make_Corelib_Init_Byte_byte_xeb(void);
value make_Corelib_Init_Byte_byte_xec(void);
value make_Corelib_Init_Byte_byte_xed(void);
value make_Corelib_Init_Byte_byte_xee(void);
value make_Corelib_Init_Byte_byte_xef(void);
value make_Corelib_Init_Byte_byte_xf0(void);
value make_Corelib_Init_Byte_byte_xf1(void);
value make_Corelib_Init_Byte_byte_xf2(void);
value make_Corelib_Init_Byte_byte_xf3(void);
value make_Corelib_Init_Byte_byte_xf4(void);
value make_Corelib_Init_Byte_byte_xf5(void);
value make_Corelib_Init_Byte_byte_xf6(void);
value make_Corelib_Init_Byte_byte_xf7(void);
value make_Corelib_Init_Byte_byte_xf8(void);
value make_Corelib_Init_Byte_byte_xf9(void);
value make_Corelib_Init_Byte_byte_xfa(void);
value make_Corelib_Init_Byte_byte_xfb(void);
value make_Corelib_Init_Byte_byte_xfc(void);
value make_Corelib_Init_Byte_byte_xfd(void);
value make_Corelib_Init_Byte_byte_xfe(void);
value make_Corelib_Init_Byte_byte_xff(void);
unsigned long long get_Corelib_Init_Datatypes_list_tag(value);
unsigned long long get_Corelib_Init_Byte_byte_tag(value);
void print_Corelib_Init_Datatypes_list(value, void (*)(value));
void print_Corelib_Init_Byte_byte(value);
value call(struct thread_info *, value, value);
signed char const lparen_lit[2] = { 40, 0, };

signed char const rparen_lit[2] = { 41, 0, };

signed char const space_lit[2] = { 32, 0, };

signed char const fun_lit[6] = { 60, 102, 117, 110, 62, 0, };

signed char const type_lit[7] = { 60, 116, 121, 112, 101, 62, 0, };

signed char const unk_lit[6] = { 60, 117, 110, 107, 62, 0, };

signed char const prop_lit[7] = { 60, 112, 114, 111, 112, 62, 0, };

unsigned long long get_unboxed_ordinal(value $v)
{
  return (unsigned long long) $v >> 1LL;
}

unsigned long long get_boxed_ordinal(value $v)
{
  return (unsigned long long) *((unsigned long long *) $v + -1LL) & 255LL;
}

value *get_args(value $v)
{
  return (value *) $v;
}

signed char const names_of_Corelib_Init_Datatypes_list[2][5] = { 110, 105,
  108, 0, 0, 99, 111, 110, 115, 0, /* skip 0 */ };

signed char const names_of_Corelib_Init_Byte_byte[256][4] = { 120, 48, 48, 0,
  120, 48, 49, 0, 120, 48, 50, 0, 120, 48, 51, 0, 120, 48, 52, 0, 120, 48,
  53, 0, 120, 48, 54, 0, 120, 48, 55, 0, 120, 48, 56, 0, 120, 48, 57, 0, 120,
  48, 97, 0, 120, 48, 98, 0, 120, 48, 99, 0, 120, 48, 100, 0, 120, 48, 101,
  0, 120, 48, 102, 0, 120, 49, 48, 0, 120, 49, 49, 0, 120, 49, 50, 0, 120,
  49, 51, 0, 120, 49, 52, 0, 120, 49, 53, 0, 120, 49, 54, 0, 120, 49, 55, 0,
  120, 49, 56, 0, 120, 49, 57, 0, 120, 49, 97, 0, 120, 49, 98, 0, 120, 49,
  99, 0, 120, 49, 100, 0, 120, 49, 101, 0, 120, 49, 102, 0, 120, 50, 48, 0,
  120, 50, 49, 0, 120, 50, 50, 0, 120, 50, 51, 0, 120, 50, 52, 0, 120, 50,
  53, 0, 120, 50, 54, 0, 120, 50, 55, 0, 120, 50, 56, 0, 120, 50, 57, 0, 120,
  50, 97, 0, 120, 50, 98, 0, 120, 50, 99, 0, 120, 50, 100, 0, 120, 50, 101,
  0, 120, 50, 102, 0, 120, 51, 48, 0, 120, 51, 49, 0, 120, 51, 50, 0, 120,
  51, 51, 0, 120, 51, 52, 0, 120, 51, 53, 0, 120, 51, 54, 0, 120, 51, 55, 0,
  120, 51, 56, 0, 120, 51, 57, 0, 120, 51, 97, 0, 120, 51, 98, 0, 120, 51,
  99, 0, 120, 51, 100, 0, 120, 51, 101, 0, 120, 51, 102, 0, 120, 52, 48, 0,
  120, 52, 49, 0, 120, 52, 50, 0, 120, 52, 51, 0, 120, 52, 52, 0, 120, 52,
  53, 0, 120, 52, 54, 0, 120, 52, 55, 0, 120, 52, 56, 0, 120, 52, 57, 0, 120,
  52, 97, 0, 120, 52, 98, 0, 120, 52, 99, 0, 120, 52, 100, 0, 120, 52, 101,
  0, 120, 52, 102, 0, 120, 53, 48, 0, 120, 53, 49, 0, 120, 53, 50, 0, 120,
  53, 51, 0, 120, 53, 52, 0, 120, 53, 53, 0, 120, 53, 54, 0, 120, 53, 55, 0,
  120, 53, 56, 0, 120, 53, 57, 0, 120, 53, 97, 0, 120, 53, 98, 0, 120, 53,
  99, 0, 120, 53, 100, 0, 120, 53, 101, 0, 120, 53, 102, 0, 120, 54, 48, 0,
  120, 54, 49, 0, 120, 54, 50, 0, 120, 54, 51, 0, 120, 54, 52, 0, 120, 54,
  53, 0, 120, 54, 54, 0, 120, 54, 55, 0, 120, 54, 56, 0, 120, 54, 57, 0, 120,
  54, 97, 0, 120, 54, 98, 0, 120, 54, 99, 0, 120, 54, 100, 0, 120, 54, 101,
  0, 120, 54, 102, 0, 120, 55, 48, 0, 120, 55, 49, 0, 120, 55, 50, 0, 120,
  55, 51, 0, 120, 55, 52, 0, 120, 55, 53, 0, 120, 55, 54, 0, 120, 55, 55, 0,
  120, 55, 56, 0, 120, 55, 57, 0, 120, 55, 97, 0, 120, 55, 98, 0, 120, 55,
  99, 0, 120, 55, 100, 0, 120, 55, 101, 0, 120, 55, 102, 0, 120, 56, 48, 0,
  120, 56, 49, 0, 120, 56, 50, 0, 120, 56, 51, 0, 120, 56, 52, 0, 120, 56,
  53, 0, 120, 56, 54, 0, 120, 56, 55, 0, 120, 56, 56, 0, 120, 56, 57, 0, 120,
  56, 97, 0, 120, 56, 98, 0, 120, 56, 99, 0, 120, 56, 100, 0, 120, 56, 101,
  0, 120, 56, 102, 0, 120, 57, 48, 0, 120, 57, 49, 0, 120, 57, 50, 0, 120,
  57, 51, 0, 120, 57, 52, 0, 120, 57, 53, 0, 120, 57, 54, 0, 120, 57, 55, 0,
  120, 57, 56, 0, 120, 57, 57, 0, 120, 57, 97, 0, 120, 57, 98, 0, 120, 57,
  99, 0, 120, 57, 100, 0, 120, 57, 101, 0, 120, 57, 102, 0, 120, 97, 48, 0,
  120, 97, 49, 0, 120, 97, 50, 0, 120, 97, 51, 0, 120, 97, 52, 0, 120, 97,
  53, 0, 120, 97, 54, 0, 120, 97, 55, 0, 120, 97, 56, 0, 120, 97, 57, 0, 120,
  97, 97, 0, 120, 97, 98, 0, 120, 97, 99, 0, 120, 97, 100, 0, 120, 97, 101,
  0, 120, 97, 102, 0, 120, 98, 48, 0, 120, 98, 49, 0, 120, 98, 50, 0, 120,
  98, 51, 0, 120, 98, 52, 0, 120, 98, 53, 0, 120, 98, 54, 0, 120, 98, 55, 0,
  120, 98, 56, 0, 120, 98, 57, 0, 120, 98, 97, 0, 120, 98, 98, 0, 120, 98,
  99, 0, 120, 98, 100, 0, 120, 98, 101, 0, 120, 98, 102, 0, 120, 99, 48, 0,
  120, 99, 49, 0, 120, 99, 50, 0, 120, 99, 51, 0, 120, 99, 52, 0, 120, 99,
  53, 0, 120, 99, 54, 0, 120, 99, 55, 0, 120, 99, 56, 0, 120, 99, 57, 0, 120,
  99, 97, 0, 120, 99, 98, 0, 120, 99, 99, 0, 120, 99, 100, 0, 120, 99, 101,
  0, 120, 99, 102, 0, 120, 100, 48, 0, 120, 100, 49, 0, 120, 100, 50, 0, 120,
  100, 51, 0, 120, 100, 52, 0, 120, 100, 53, 0, 120, 100, 54, 0, 120, 100,
  55, 0, 120, 100, 56, 0, 120, 100, 57, 0, 120, 100, 97, 0, 120, 100, 98, 0,
  120, 100, 99, 0, 120, 100, 100, 0, 120, 100, 101, 0, 120, 100, 102, 0, 120,
  101, 48, 0, 120, 101, 49, 0, 120, 101, 50, 0, 120, 101, 51, 0, 120, 101,
  52, 0, 120, 101, 53, 0, 120, 101, 54, 0, 120, 101, 55, 0, 120, 101, 56, 0,
  120, 101, 57, 0, 120, 101, 97, 0, 120, 101, 98, 0, 120, 101, 99, 0, 120,
  101, 100, 0, 120, 101, 101, 0, 120, 101, 102, 0, 120, 102, 48, 0, 120, 102,
  49, 0, 120, 102, 50, 0, 120, 102, 51, 0, 120, 102, 52, 0, 120, 102, 53, 0,
  120, 102, 54, 0, 120, 102, 55, 0, 120, 102, 56, 0, 120, 102, 57, 0, 120,
  102, 97, 0, 120, 102, 98, 0, 120, 102, 99, 0, 120, 102, 100, 0, 120, 102,
  101, 0, 120, 102, 102, 0, /* skip 0 */ };

value make_Corelib_Init_Datatypes_list_nil(void)
{
  return (value) 1;
}

value make_Corelib_Init_Datatypes_list_cons(value $arg0, value $arg1, value *$argv)
{
  *($argv + 0LL) = (value) 2048LL;
  *($argv + 1LL) = $arg0;
  *($argv + 2LL) = $arg1;
  return $argv + 1LL;
}

value alloc_make_Corelib_Init_Datatypes_list_cons(struct thread_info *$tinfo, value $arg0, value $arg1)
{
  register value *$argv;
  $argv = (*$tinfo).alloc;
  *($argv + 0LL) = 2048LL;
  *($argv + 1LL) = $arg0;
  *($argv + 2LL) = $arg1;
  (*$tinfo).alloc = (*$tinfo).alloc + 3LL;
  return $argv + 1LL;
}

value make_Corelib_Init_Byte_byte_x00(void)
{
  return (value) 1;
}

value make_Corelib_Init_Byte_byte_x01(void)
{
  return (value) 3;
}

value make_Corelib_Init_Byte_byte_x02(void)
{
  return (value) 5;
}

value make_Corelib_Init_Byte_byte_x03(void)
{
  return (value) 7;
}

value make_Corelib_Init_Byte_byte_x04(void)
{
  return (value) 9;
}

value make_Corelib_Init_Byte_byte_x05(void)
{
  return (value) 11;
}

value make_Corelib_Init_Byte_byte_x06(void)
{
  return (value) 13;
}

value make_Corelib_Init_Byte_byte_x07(void)
{
  return (value) 15;
}

value make_Corelib_Init_Byte_byte_x08(void)
{
  return (value) 17;
}

value make_Corelib_Init_Byte_byte_x09(void)
{
  return (value) 19;
}

value make_Corelib_Init_Byte_byte_x0a(void)
{
  return (value) 21;
}

value make_Corelib_Init_Byte_byte_x0b(void)
{
  return (value) 23;
}

value make_Corelib_Init_Byte_byte_x0c(void)
{
  return (value) 25;
}

value make_Corelib_Init_Byte_byte_x0d(void)
{
  return (value) 27;
}

value make_Corelib_Init_Byte_byte_x0e(void)
{
  return (value) 29;
}

value make_Corelib_Init_Byte_byte_x0f(void)
{
  return (value) 31;
}

value make_Corelib_Init_Byte_byte_x10(void)
{
  return (value) 33;
}

value make_Corelib_Init_Byte_byte_x11(void)
{
  return (value) 35;
}

value make_Corelib_Init_Byte_byte_x12(void)
{
  return (value) 37;
}

value make_Corelib_Init_Byte_byte_x13(void)
{
  return (value) 39;
}

value make_Corelib_Init_Byte_byte_x14(void)
{
  return (value) 41;
}

value make_Corelib_Init_Byte_byte_x15(void)
{
  return (value) 43;
}

value make_Corelib_Init_Byte_byte_x16(void)
{
  return (value) 45;
}

value make_Corelib_Init_Byte_byte_x17(void)
{
  return (value) 47;
}

value make_Corelib_Init_Byte_byte_x18(void)
{
  return (value) 49;
}

value make_Corelib_Init_Byte_byte_x19(void)
{
  return (value) 51;
}

value make_Corelib_Init_Byte_byte_x1a(void)
{
  return (value) 53;
}

value make_Corelib_Init_Byte_byte_x1b(void)
{
  return (value) 55;
}

value make_Corelib_Init_Byte_byte_x1c(void)
{
  return (value) 57;
}

value make_Corelib_Init_Byte_byte_x1d(void)
{
  return (value) 59;
}

value make_Corelib_Init_Byte_byte_x1e(void)
{
  return (value) 61;
}

value make_Corelib_Init_Byte_byte_x1f(void)
{
  return (value) 63;
}

value make_Corelib_Init_Byte_byte_x20(void)
{
  return (value) 65;
}

value make_Corelib_Init_Byte_byte_x21(void)
{
  return (value) 67;
}

value make_Corelib_Init_Byte_byte_x22(void)
{
  return (value) 69;
}

value make_Corelib_Init_Byte_byte_x23(void)
{
  return (value) 71;
}

value make_Corelib_Init_Byte_byte_x24(void)
{
  return (value) 73;
}

value make_Corelib_Init_Byte_byte_x25(void)
{
  return (value) 75;
}

value make_Corelib_Init_Byte_byte_x26(void)
{
  return (value) 77;
}

value make_Corelib_Init_Byte_byte_x27(void)
{
  return (value) 79;
}

value make_Corelib_Init_Byte_byte_x28(void)
{
  return (value) 81;
}

value make_Corelib_Init_Byte_byte_x29(void)
{
  return (value) 83;
}

value make_Corelib_Init_Byte_byte_x2a(void)
{
  return (value) 85;
}

value make_Corelib_Init_Byte_byte_x2b(void)
{
  return (value) 87;
}

value make_Corelib_Init_Byte_byte_x2c(void)
{
  return (value) 89;
}

value make_Corelib_Init_Byte_byte_x2d(void)
{
  return (value) 91;
}

value make_Corelib_Init_Byte_byte_x2e(void)
{
  return (value) 93;
}

value make_Corelib_Init_Byte_byte_x2f(void)
{
  return (value) 95;
}

value make_Corelib_Init_Byte_byte_x30(void)
{
  return (value) 97;
}

value make_Corelib_Init_Byte_byte_x31(void)
{
  return (value) 99;
}

value make_Corelib_Init_Byte_byte_x32(void)
{
  return (value) 101;
}

value make_Corelib_Init_Byte_byte_x33(void)
{
  return (value) 103;
}

value make_Corelib_Init_Byte_byte_x34(void)
{
  return (value) 105;
}

value make_Corelib_Init_Byte_byte_x35(void)
{
  return (value) 107;
}

value make_Corelib_Init_Byte_byte_x36(void)
{
  return (value) 109;
}

value make_Corelib_Init_Byte_byte_x37(void)
{
  return (value) 111;
}

value make_Corelib_Init_Byte_byte_x38(void)
{
  return (value) 113;
}

value make_Corelib_Init_Byte_byte_x39(void)
{
  return (value) 115;
}

value make_Corelib_Init_Byte_byte_x3a(void)
{
  return (value) 117;
}

value make_Corelib_Init_Byte_byte_x3b(void)
{
  return (value) 119;
}

value make_Corelib_Init_Byte_byte_x3c(void)
{
  return (value) 121;
}

value make_Corelib_Init_Byte_byte_x3d(void)
{
  return (value) 123;
}

value make_Corelib_Init_Byte_byte_x3e(void)
{
  return (value) 125;
}

value make_Corelib_Init_Byte_byte_x3f(void)
{
  return (value) 127;
}

value make_Corelib_Init_Byte_byte_x40(void)
{
  return (value) 129;
}

value make_Corelib_Init_Byte_byte_x41(void)
{
  return (value) 131;
}

value make_Corelib_Init_Byte_byte_x42(void)
{
  return (value) 133;
}

value make_Corelib_Init_Byte_byte_x43(void)
{
  return (value) 135;
}

value make_Corelib_Init_Byte_byte_x44(void)
{
  return (value) 137;
}

value make_Corelib_Init_Byte_byte_x45(void)
{
  return (value) 139;
}

value make_Corelib_Init_Byte_byte_x46(void)
{
  return (value) 141;
}

value make_Corelib_Init_Byte_byte_x47(void)
{
  return (value) 143;
}

value make_Corelib_Init_Byte_byte_x48(void)
{
  return (value) 145;
}

value make_Corelib_Init_Byte_byte_x49(void)
{
  return (value) 147;
}

value make_Corelib_Init_Byte_byte_x4a(void)
{
  return (value) 149;
}

value make_Corelib_Init_Byte_byte_x4b(void)
{
  return (value) 151;
}

value make_Corelib_Init_Byte_byte_x4c(void)
{
  return (value) 153;
}

value make_Corelib_Init_Byte_byte_x4d(void)
{
  return (value) 155;
}

value make_Corelib_Init_Byte_byte_x4e(void)
{
  return (value) 157;
}

value make_Corelib_Init_Byte_byte_x4f(void)
{
  return (value) 159;
}

value make_Corelib_Init_Byte_byte_x50(void)
{
  return (value) 161;
}

value make_Corelib_Init_Byte_byte_x51(void)
{
  return (value) 163;
}

value make_Corelib_Init_Byte_byte_x52(void)
{
  return (value) 165;
}

value make_Corelib_Init_Byte_byte_x53(void)
{
  return (value) 167;
}

value make_Corelib_Init_Byte_byte_x54(void)
{
  return (value) 169;
}

value make_Corelib_Init_Byte_byte_x55(void)
{
  return (value) 171;
}

value make_Corelib_Init_Byte_byte_x56(void)
{
  return (value) 173;
}

value make_Corelib_Init_Byte_byte_x57(void)
{
  return (value) 175;
}

value make_Corelib_Init_Byte_byte_x58(void)
{
  return (value) 177;
}

value make_Corelib_Init_Byte_byte_x59(void)
{
  return (value) 179;
}

value make_Corelib_Init_Byte_byte_x5a(void)
{
  return (value) 181;
}

value make_Corelib_Init_Byte_byte_x5b(void)
{
  return (value) 183;
}

value make_Corelib_Init_Byte_byte_x5c(void)
{
  return (value) 185;
}

value make_Corelib_Init_Byte_byte_x5d(void)
{
  return (value) 187;
}

value make_Corelib_Init_Byte_byte_x5e(void)
{
  return (value) 189;
}

value make_Corelib_Init_Byte_byte_x5f(void)
{
  return (value) 191;
}

value make_Corelib_Init_Byte_byte_x60(void)
{
  return (value) 193;
}

value make_Corelib_Init_Byte_byte_x61(void)
{
  return (value) 195;
}

value make_Corelib_Init_Byte_byte_x62(void)
{
  return (value) 197;
}

value make_Corelib_Init_Byte_byte_x63(void)
{
  return (value) 199;
}

value make_Corelib_Init_Byte_byte_x64(void)
{
  return (value) 201;
}

value make_Corelib_Init_Byte_byte_x65(void)
{
  return (value) 203;
}

value make_Corelib_Init_Byte_byte_x66(void)
{
  return (value) 205;
}

value make_Corelib_Init_Byte_byte_x67(void)
{
  return (value) 207;
}

value make_Corelib_Init_Byte_byte_x68(void)
{
  return (value) 209;
}

value make_Corelib_Init_Byte_byte_x69(void)
{
  return (value) 211;
}

value make_Corelib_Init_Byte_byte_x6a(void)
{
  return (value) 213;
}

value make_Corelib_Init_Byte_byte_x6b(void)
{
  return (value) 215;
}

value make_Corelib_Init_Byte_byte_x6c(void)
{
  return (value) 217;
}

value make_Corelib_Init_Byte_byte_x6d(void)
{
  return (value) 219;
}

value make_Corelib_Init_Byte_byte_x6e(void)
{
  return (value) 221;
}

value make_Corelib_Init_Byte_byte_x6f(void)
{
  return (value) 223;
}

value make_Corelib_Init_Byte_byte_x70(void)
{
  return (value) 225;
}

value make_Corelib_Init_Byte_byte_x71(void)
{
  return (value) 227;
}

value make_Corelib_Init_Byte_byte_x72(void)
{
  return (value) 229;
}

value make_Corelib_Init_Byte_byte_x73(void)
{
  return (value) 231;
}

value make_Corelib_Init_Byte_byte_x74(void)
{
  return (value) 233;
}

value make_Corelib_Init_Byte_byte_x75(void)
{
  return (value) 235;
}

value make_Corelib_Init_Byte_byte_x76(void)
{
  return (value) 237;
}

value make_Corelib_Init_Byte_byte_x77(void)
{
  return (value) 239;
}

value make_Corelib_Init_Byte_byte_x78(void)
{
  return (value) 241;
}

value make_Corelib_Init_Byte_byte_x79(void)
{
  return (value) 243;
}

value make_Corelib_Init_Byte_byte_x7a(void)
{
  return (value) 245;
}

value make_Corelib_Init_Byte_byte_x7b(void)
{
  return (value) 247;
}

value make_Corelib_Init_Byte_byte_x7c(void)
{
  return (value) 249;
}

value make_Corelib_Init_Byte_byte_x7d(void)
{
  return (value) 251;
}

value make_Corelib_Init_Byte_byte_x7e(void)
{
  return (value) 253;
}

value make_Corelib_Init_Byte_byte_x7f(void)
{
  return (value) 255;
}

value make_Corelib_Init_Byte_byte_x80(void)
{
  return (value) 257;
}

value make_Corelib_Init_Byte_byte_x81(void)
{
  return (value) 259;
}

value make_Corelib_Init_Byte_byte_x82(void)
{
  return (value) 261;
}

value make_Corelib_Init_Byte_byte_x83(void)
{
  return (value) 263;
}

value make_Corelib_Init_Byte_byte_x84(void)
{
  return (value) 265;
}

value make_Corelib_Init_Byte_byte_x85(void)
{
  return (value) 267;
}

value make_Corelib_Init_Byte_byte_x86(void)
{
  return (value) 269;
}

value make_Corelib_Init_Byte_byte_x87(void)
{
  return (value) 271;
}

value make_Corelib_Init_Byte_byte_x88(void)
{
  return (value) 273;
}

value make_Corelib_Init_Byte_byte_x89(void)
{
  return (value) 275;
}

value make_Corelib_Init_Byte_byte_x8a(void)
{
  return (value) 277;
}

value make_Corelib_Init_Byte_byte_x8b(void)
{
  return (value) 279;
}

value make_Corelib_Init_Byte_byte_x8c(void)
{
  return (value) 281;
}

value make_Corelib_Init_Byte_byte_x8d(void)
{
  return (value) 283;
}

value make_Corelib_Init_Byte_byte_x8e(void)
{
  return (value) 285;
}

value make_Corelib_Init_Byte_byte_x8f(void)
{
  return (value) 287;
}

value make_Corelib_Init_Byte_byte_x90(void)
{
  return (value) 289;
}

value make_Corelib_Init_Byte_byte_x91(void)
{
  return (value) 291;
}

value make_Corelib_Init_Byte_byte_x92(void)
{
  return (value) 293;
}

value make_Corelib_Init_Byte_byte_x93(void)
{
  return (value) 295;
}

value make_Corelib_Init_Byte_byte_x94(void)
{
  return (value) 297;
}

value make_Corelib_Init_Byte_byte_x95(void)
{
  return (value) 299;
}

value make_Corelib_Init_Byte_byte_x96(void)
{
  return (value) 301;
}

value make_Corelib_Init_Byte_byte_x97(void)
{
  return (value) 303;
}

value make_Corelib_Init_Byte_byte_x98(void)
{
  return (value) 305;
}

value make_Corelib_Init_Byte_byte_x99(void)
{
  return (value) 307;
}

value make_Corelib_Init_Byte_byte_x9a(void)
{
  return (value) 309;
}

value make_Corelib_Init_Byte_byte_x9b(void)
{
  return (value) 311;
}

value make_Corelib_Init_Byte_byte_x9c(void)
{
  return (value) 313;
}

value make_Corelib_Init_Byte_byte_x9d(void)
{
  return (value) 315;
}

value make_Corelib_Init_Byte_byte_x9e(void)
{
  return (value) 317;
}

value make_Corelib_Init_Byte_byte_x9f(void)
{
  return (value) 319;
}

value make_Corelib_Init_Byte_byte_xa0(void)
{
  return (value) 321;
}

value make_Corelib_Init_Byte_byte_xa1(void)
{
  return (value) 323;
}

value make_Corelib_Init_Byte_byte_xa2(void)
{
  return (value) 325;
}

value make_Corelib_Init_Byte_byte_xa3(void)
{
  return (value) 327;
}

value make_Corelib_Init_Byte_byte_xa4(void)
{
  return (value) 329;
}

value make_Corelib_Init_Byte_byte_xa5(void)
{
  return (value) 331;
}

value make_Corelib_Init_Byte_byte_xa6(void)
{
  return (value) 333;
}

value make_Corelib_Init_Byte_byte_xa7(void)
{
  return (value) 335;
}

value make_Corelib_Init_Byte_byte_xa8(void)
{
  return (value) 337;
}

value make_Corelib_Init_Byte_byte_xa9(void)
{
  return (value) 339;
}

value make_Corelib_Init_Byte_byte_xaa(void)
{
  return (value) 341;
}

value make_Corelib_Init_Byte_byte_xab(void)
{
  return (value) 343;
}

value make_Corelib_Init_Byte_byte_xac(void)
{
  return (value) 345;
}

value make_Corelib_Init_Byte_byte_xad(void)
{
  return (value) 347;
}

value make_Corelib_Init_Byte_byte_xae(void)
{
  return (value) 349;
}

value make_Corelib_Init_Byte_byte_xaf(void)
{
  return (value) 351;
}

value make_Corelib_Init_Byte_byte_xb0(void)
{
  return (value) 353;
}

value make_Corelib_Init_Byte_byte_xb1(void)
{
  return (value) 355;
}

value make_Corelib_Init_Byte_byte_xb2(void)
{
  return (value) 357;
}

value make_Corelib_Init_Byte_byte_xb3(void)
{
  return (value) 359;
}

value make_Corelib_Init_Byte_byte_xb4(void)
{
  return (value) 361;
}

value make_Corelib_Init_Byte_byte_xb5(void)
{
  return (value) 363;
}

value make_Corelib_Init_Byte_byte_xb6(void)
{
  return (value) 365;
}

value make_Corelib_Init_Byte_byte_xb7(void)
{
  return (value) 367;
}

value make_Corelib_Init_Byte_byte_xb8(void)
{
  return (value) 369;
}

value make_Corelib_Init_Byte_byte_xb9(void)
{
  return (value) 371;
}

value make_Corelib_Init_Byte_byte_xba(void)
{
  return (value) 373;
}

value make_Corelib_Init_Byte_byte_xbb(void)
{
  return (value) 375;
}

value make_Corelib_Init_Byte_byte_xbc(void)
{
  return (value) 377;
}

value make_Corelib_Init_Byte_byte_xbd(void)
{
  return (value) 379;
}

value make_Corelib_Init_Byte_byte_xbe(void)
{
  return (value) 381;
}

value make_Corelib_Init_Byte_byte_xbf(void)
{
  return (value) 383;
}

value make_Corelib_Init_Byte_byte_xc0(void)
{
  return (value) 385;
}

value make_Corelib_Init_Byte_byte_xc1(void)
{
  return (value) 387;
}

value make_Corelib_Init_Byte_byte_xc2(void)
{
  return (value) 389;
}

value make_Corelib_Init_Byte_byte_xc3(void)
{
  return (value) 391;
}

value make_Corelib_Init_Byte_byte_xc4(void)
{
  return (value) 393;
}

value make_Corelib_Init_Byte_byte_xc5(void)
{
  return (value) 395;
}

value make_Corelib_Init_Byte_byte_xc6(void)
{
  return (value) 397;
}

value make_Corelib_Init_Byte_byte_xc7(void)
{
  return (value) 399;
}

value make_Corelib_Init_Byte_byte_xc8(void)
{
  return (value) 401;
}

value make_Corelib_Init_Byte_byte_xc9(void)
{
  return (value) 403;
}

value make_Corelib_Init_Byte_byte_xca(void)
{
  return (value) 405;
}

value make_Corelib_Init_Byte_byte_xcb(void)
{
  return (value) 407;
}

value make_Corelib_Init_Byte_byte_xcc(void)
{
  return (value) 409;
}

value make_Corelib_Init_Byte_byte_xcd(void)
{
  return (value) 411;
}

value make_Corelib_Init_Byte_byte_xce(void)
{
  return (value) 413;
}

value make_Corelib_Init_Byte_byte_xcf(void)
{
  return (value) 415;
}

value make_Corelib_Init_Byte_byte_xd0(void)
{
  return (value) 417;
}

value make_Corelib_Init_Byte_byte_xd1(void)
{
  return (value) 419;
}

value make_Corelib_Init_Byte_byte_xd2(void)
{
  return (value) 421;
}

value make_Corelib_Init_Byte_byte_xd3(void)
{
  return (value) 423;
}

value make_Corelib_Init_Byte_byte_xd4(void)
{
  return (value) 425;
}

value make_Corelib_Init_Byte_byte_xd5(void)
{
  return (value) 427;
}

value make_Corelib_Init_Byte_byte_xd6(void)
{
  return (value) 429;
}

value make_Corelib_Init_Byte_byte_xd7(void)
{
  return (value) 431;
}

value make_Corelib_Init_Byte_byte_xd8(void)
{
  return (value) 433;
}

value make_Corelib_Init_Byte_byte_xd9(void)
{
  return (value) 435;
}

value make_Corelib_Init_Byte_byte_xda(void)
{
  return (value) 437;
}

value make_Corelib_Init_Byte_byte_xdb(void)
{
  return (value) 439;
}

value make_Corelib_Init_Byte_byte_xdc(void)
{
  return (value) 441;
}

value make_Corelib_Init_Byte_byte_xdd(void)
{
  return (value) 443;
}

value make_Corelib_Init_Byte_byte_xde(void)
{
  return (value) 445;
}

value make_Corelib_Init_Byte_byte_xdf(void)
{
  return (value) 447;
}

value make_Corelib_Init_Byte_byte_xe0(void)
{
  return (value) 449;
}

value make_Corelib_Init_Byte_byte_xe1(void)
{
  return (value) 451;
}

value make_Corelib_Init_Byte_byte_xe2(void)
{
  return (value) 453;
}

value make_Corelib_Init_Byte_byte_xe3(void)
{
  return (value) 455;
}

value make_Corelib_Init_Byte_byte_xe4(void)
{
  return (value) 457;
}

value make_Corelib_Init_Byte_byte_xe5(void)
{
  return (value) 459;
}

value make_Corelib_Init_Byte_byte_xe6(void)
{
  return (value) 461;
}

value make_Corelib_Init_Byte_byte_xe7(void)
{
  return (value) 463;
}

value make_Corelib_Init_Byte_byte_xe8(void)
{
  return (value) 465;
}

value make_Corelib_Init_Byte_byte_xe9(void)
{
  return (value) 467;
}

value make_Corelib_Init_Byte_byte_xea(void)
{
  return (value) 469;
}

value make_Corelib_Init_Byte_byte_xeb(void)
{
  return (value) 471;
}

value make_Corelib_Init_Byte_byte_xec(void)
{
  return (value) 473;
}

value make_Corelib_Init_Byte_byte_xed(void)
{
  return (value) 475;
}

value make_Corelib_Init_Byte_byte_xee(void)
{
  return (value) 477;
}

value make_Corelib_Init_Byte_byte_xef(void)
{
  return (value) 479;
}

value make_Corelib_Init_Byte_byte_xf0(void)
{
  return (value) 481;
}

value make_Corelib_Init_Byte_byte_xf1(void)
{
  return (value) 483;
}

value make_Corelib_Init_Byte_byte_xf2(void)
{
  return (value) 485;
}

value make_Corelib_Init_Byte_byte_xf3(void)
{
  return (value) 487;
}

value make_Corelib_Init_Byte_byte_xf4(void)
{
  return (value) 489;
}

value make_Corelib_Init_Byte_byte_xf5(void)
{
  return (value) 491;
}

value make_Corelib_Init_Byte_byte_xf6(void)
{
  return (value) 493;
}

value make_Corelib_Init_Byte_byte_xf7(void)
{
  return (value) 495;
}

value make_Corelib_Init_Byte_byte_xf8(void)
{
  return (value) 497;
}

value make_Corelib_Init_Byte_byte_xf9(void)
{
  return (value) 499;
}

value make_Corelib_Init_Byte_byte_xfa(void)
{
  return (value) 501;
}

value make_Corelib_Init_Byte_byte_xfb(void)
{
  return (value) 503;
}

value make_Corelib_Init_Byte_byte_xfc(void)
{
  return (value) 505;
}

value make_Corelib_Init_Byte_byte_xfd(void)
{
  return (value) 507;
}

value make_Corelib_Init_Byte_byte_xfe(void)
{
  return (value) 509;
}

value make_Corelib_Init_Byte_byte_xff(void)
{
  return (value) 511;
}

unsigned long long get_Corelib_Init_Datatypes_list_tag(value $v)
{
  register _Bool $b;
  register unsigned long long $t;
  $b = is_ptr($v);
  if ($b) {
    $t = get_boxed_ordinal($v);
    switch ($t) {
      case 0:
        return 1;
      
    }
  } else {
    $t = get_unboxed_ordinal($v);
    switch ($t) {
      case 0:
        return 0;
      
    }
  }
}

unsigned long long get_Corelib_Init_Byte_byte_tag(value $v)
{
  register unsigned long long $t;
  $t = get_unboxed_ordinal($v);
  return $t;
}

void print_Corelib_Init_Datatypes_list(value $v, void $print_param_A(value))
{
  register unsigned int $tag;
  register void *$args;
  $tag = get_Corelib_Init_Datatypes_list_tag($v);
  switch ($tag) {
    case 0:
      printf(*(names_of_Corelib_Init_Datatypes_list + $tag));
      break;
    case 1:
      $args = get_args($v);
      printf(lparen_lit);
      printf(*(names_of_Corelib_Init_Datatypes_list + $tag));
      printf(space_lit);
      $print_param_A(*((value *) $args + 0));
      printf(space_lit);
      print_Corelib_Init_Datatypes_list
        (*((value *) $args + 1), $print_param_A);
      printf(rparen_lit);
      break;
    
  }
}

void print_Corelib_Init_Byte_byte(value $v)
{
  register unsigned int $tag;
  $tag = get_Corelib_Init_Byte_byte_tag($v);
  printf(*(names_of_Corelib_Init_Byte_byte + $tag));
}

value call(struct thread_info *$tinfo, value $clo, value $arg)
{
  register value $f;
  register value $envi;
  register value $tmp;
  $f = (*((struct closure *) $clo)).func;
  $envi = (*((struct closure *) $clo)).env;
  $tmp =
    ((value (*)(struct thread_info *, value, value)) $f)
    ($tinfo, $envi, $arg);
  return $tmp;
}


#endif /* GLUE_SCHUR_C */
