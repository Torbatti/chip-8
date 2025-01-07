const std = @import("std");

const cstd = @cImport(@cInclude("stdlib.h"));
const ctime = @cImport(@cInclude("time.h"));

pub const CHIP8 = struct {
    opcode: u16 = 0,
    memory: [4096]u8 = [_]u8{0} ** 4096,
    graphics: [64 * 32]u8 = [_]u8{0} ** 64 * 32,

    registers: [16]u8 = [_]u8{0} ** 16,
    index: u16 = 0,
    pc: u16 = 0x200, // program counter

    delay_timer: u8 = 0,
    sound_timer: u8 = 0,

    stack: [16]u16 = [_]u8{0} ** 16,
    sp: u16, // stack pointer

    keys: [16]u8 = [_]u8{0} ** 16,

    const Self = @This();

    pub fn init(self: *Self) void {}
    pub fn deinit() void {}
};
