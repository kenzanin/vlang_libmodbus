module modbus_v

import log

#flag -I/usr/include/modbus -lmodbus
#include "modbus.h"

// void modbus_set_float_cdab(float f, uint16_t *dest);
pub fn C.modbus_set_float_cdab(f f32, dest &u16)

// void modbus_set_float_dcba(float f, uint16_t *dest);
pub fn C.modbus_set_float_dcba(f f32, dest &u16)

// float modbus_get_float_cdab(const uint16_t *src);
pub fn C.modbus_get_float_cdab(const_s &u16) f32

// float modbus_get_float_dcba(const uint16_t *src);
pub fn C.modbus_get_float_dcba(const_src &u16)

@[typedef]
struct C.modbus_t {
}

pub type Modbus_t = C.modbus_t

// MODBUS_API modbus_t * modbus_new_rtu(const char *device, int baud, char parity, int data_bit, int stop_bit);
fn C.modbus_new_rtu(&char, int, char, int, int) &C.modbus_t

pub fn modbus_new_rtu(device string, baud int, parity rune, data_bit int, stop_bit int) !&Modbus_t {
	log.info('oppening dev ${device} with baud: ${baud}')
	mut tmp := C.modbus_new_rtu(device.str, baud, parity, data_bit, stop_bit)
	if tmp == C.NULL {
		return error('error create mobus')
	}
	return tmp
}

// MODBUS_API int modbus_connect(modbus_t *ctx);
fn C.modbus_connect(&C.modbus_t) int

pub fn modbus_connect(mut m Modbus_t) int {
	return C.modbus_connect(m)
}

// MODBUS_API int modbus_set_slave(modbus_t *ctx, int slave);
fn C.modbus_set_slave(&C.modbus_t, int) int

pub fn modbus_set_slave(mut m Modbus_t, id int) int {
	return C.modbus_set_slave(m, id)
}

// void modbus_set_float_abcd(float f, uint16_t *dest);
fn C.modbus_set_float_abcd(f f32, dest &u16)

pub fn modbus_set_float_abcd(f f32, mut dest []u16) ! {
	if dest.len != 2 {
		return error('dest must have len 2')
	}
	C.modbus_set_float_abcd(f, dest.data)
}

// void modbus_set_float_badc(float f, uint16_t *dest);
fn C.modbus_set_float_badc(f f32, dest &u16)

fn modbus_set_float_bcad(f f32, mut dest []u16) ! {
	if dest.len != 2 {
		return error('dest must have len 2')
	}
	C.modbus_set_float_badc(f, dest.data)
}

// float modbus_get_float_abcd(const uint16_t *src);
fn C.modbus_get_float_abcd(const_s &u16) f32

pub fn modbus_get_float_abcd(s []u16) !f32 {
	if s.len != 2 {
		return error('src must have len 2')
	}
	return C.modbus_get_float_abcd(s.data)
}

// float modbus_get_float_badc(const uint16_t *src);
fn C.modbus_get_float_badc(const_s &u16) f32

pub fn modbus_get_float_badc(s []u16) !f32 {
	if s.len != 2 {
		return error('src.len must equal or greater than 2')
	}
	return C.modbus_get_float_badc(s.data)
}

// MODBUS_API int modbus_read_registers(modbus_t *ctx, int addr, int nb, uint16_t *dest);
fn C.modbus_read_registers(&C.modbus_t, int, int, &u16) int

pub fn modbus_read_registers(mut m Modbus_t, addr int, mb int, mut dest []u16) !int {
	if dest.len < mb {
		return error('dest len: ${dest.len} must be bigger or equal than mb: ${mb}')
	}
	return C.modbus_read_registers(m, addr, mb, dest.data)
}

// void modbus_set_byte_timeout(modbus_t *ctx, uint32_t to_sec, uint32_t to_usec);
fn C.modbus_set_byte_timeout(&C.modbus_t, to_sec u32, to_usec u32)

pub fn modbus_set_byte_timeout(mut m Modbus_t, to_sec u32, to_usec u32) {
	C.modbus_set_byte_timeout(m, to_sec, to_usec)
}

// int modbus_set_response_timeout(modbus_t *ctx, uint32_t to_sec, uint32_t to_usec);
fn C.modbus_set_response_timeout(&C.modbus_t, to_sec u32, to_usec u32)

pub fn modbus_set_response_timeout(mut m Modbus_t, to_sec u32, to_usec u32) {
	C.modbus_set_response_timeout(m, to_sec, to_usec)
}

// int modbus_set_debug(modbus_t *ctx, int flag);
fn C.modbus_set_debug(&C.modbus_t, flag int)

pub fn modbus_set_debug(mut m Modbus_t, flag int) {
	C.modbus_set_debug(m, flag)
}

// MODBUS_API void modbus_close(modbus_t *ctx);
fn C.modbus_close(&C.modbus_t)

pub fn modbus_close(mut m Modbus_t) {
	C.modbus_close(m)
}

// MODBUS_API void modbus_free(modbus_t *ctx);
fn C.modbus_free(&C.modbus_t)

pub fn modbus_free(mut m Modbus_t) {
	C.modbus_free(m)
}
