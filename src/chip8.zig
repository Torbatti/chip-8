const std = @import("std");

const cstd = @cImport(@cInclude("stdlib.h"));
const ctime = @cImport(@cInclude("time.h"));

const fontset: [80]u8 = [_]u8{
    0xF0, 0x90, 0x90, 0x90, 0xF0, // 0
    0x20, 0x60, 0x20, 0x20, 0x70, // 1
    0xF0, 0x10, 0xF0, 0x80, 0xF0, // 2
    0xF0, 0x10, 0xF0, 0x10, 0xF0, // 3
    0x90, 0x90, 0xF0, 0x10, 0x10, // 4
    0xF0, 0x80, 0xF0, 0x10, 0xF0, // 5
    0xF0, 0x80, 0xF0, 0x90, 0xF0, // 6
    0xF0, 0x10, 0x20, 0x40, 0x40, // 7
    0xF0, 0x90, 0xF0, 0x90, 0xF0, // 8
    0xF0, 0x90, 0xF0, 0x10, 0xF0, // 9
    0xF0, 0x90, 0xF0, 0x90, 0x90, // A
    0xE0, 0x90, 0xE0, 0x90, 0xE0, // B
    0xF0, 0x80, 0x80, 0x80, 0xF0, // C
    0xE0, 0x90, 0x90, 0x90, 0xE0, // D
    0xF0, 0x80, 0xF0, 0x80, 0xF0, // E
    0xF0, 0x80, 0xF0, 0x80, 0x80, // F
};

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

    pub fn reset(self: *Self) void {
        self.opcode = 0;
        self.memory = [_]u8{0} ** 4096;
        self.graphics = [_]u8{0} ** 64 * 32;

        self.index = 0;
        self.registers = [_]u8{0} ** 16;
        self.pc = 0x200;

        self.delay_timer = 0;
        self.sound_timer = 0;

        self.sp = 0;
        self.stack = [_]u8{0} ** 16;

        self.keys = [_]u8{0} ** 16;

        for (fontset, 0..) |char, idx| {
            self.memory[idx] = char;
        }
    }

    pub fn init(self: *Self) void {}

    pub fn deinit(self: *Self) void {}

    fn increment_pc(self: *Self) void {
        self.pc += 2;
    }

    pub fn cycle(self: *Self) void {
        self.opcode = self.memory[self.pc] << 8 | self.memory[self.pc + 1];

        const first = self.opcode >> 12;

        switch (first) {
            0x0 => {
                if (self.opcode == 0x00E0) {
                    // Clear Graphics
                    self.graphics = [_]u8{0} ** 64 * 32;
                } else if (self.opcode == 0x00EE) {
                    // TODO:
                } else {
                    // ignore
                }
                self.increment_pc();
            },

            0x1 => self.pc = self.opcode & 0x0FFF,

            0x2 => {
                self.stack[self.sp] = self.pc;
                self.sp += 1;
                self.pc = self.opcode & 0x0FFF;
            },

            0x3 => {},
            0x4 => {},
            0x5 => {},
            0x6 => {},
            0x7 => {},
        }
    }
};
