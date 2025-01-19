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

//           Cowgod's Chip-8
//      Technical Reference v1.0
// http://devernay.free.fr/hacks/chip8/C8TECH10.HTM
pub const CHIP8 = struct {

    //
    // - 4KB (4,096 bytes) of RAM
    // from location 0x000 (0) to 0xFFF (4095)
    //
    // - The first 512 bytes, from 0x000 to 0x1FF,
    // are where the original interpreter was located,
    // and should not be used by programs.
    //
    // - Most Chip-8 programs start at location 0x200 (512)
    // , but some begin at 0x600 (1536).
    //
    //     Memory Map:
    // +---------------+= 0xFFF (4095) End of Chip-8 RAM
    // |               |
    // |               |
    // |               |
    // |               |
    // |               |
    // | 0x200 to 0xFFF|
    // |     Chip-8    |
    // | Program / Data|
    // |     Space     |
    // |               |
    // |               |
    // |               |
    // +- - - - - - - -+= 0x600 (1536) Start of ETI 660 Chip-8 programs
    // |               |
    // |               |
    // |               |
    // +---------------+= 0x200 (512) Start of most Chip-8 programs
    // | 0x000 to 0x1FF|
    // | Reserved for  |
    // |  interpreter  |
    // +---------------+= 0x000 (0) Start of Chip-8 RAM
    //
    memory: [4096]u8 = [_]u8{0} ** 4096,

    //
    // - Chip-8 has 16 general purpose 8-bit registers,
    // usually referred to as Vx, where x is a hexadecimal digit (0 through F).
    //
    // - There is also a 16-bit register called I.
    // This register is generally used to store memory addresses,
    // so only the lowest (rightmost) 12 bits are usually used.
    //
    // - The VF register should not be used by any program,
    // as it is used as a flag by some instructions.
    //
    // - Chip-8 also has two special purpose 8-bit registers, for the delay and sound timers.
    // When these registers are non-zero, they are automatically decremented at a rate of 60Hz.
    //
    // - There are also some "pseudo-registers" which are not accessable from Chip-8 programs.
    // The program counter (PC) should be 16-bit, and is used to store the currently executing address.
    // The stack pointer (SP) can be 8-bit, it is used to point to the topmost level of the stack.
    //
    // - The stack is an array of 16 16-bit values,
    // used to store the address that the interpreter shoud return to when finished with a subroutine.
    // Chip-8 allows for up to 16 levels of nested subroutines.
    //
    registers: [16]u8 = [_]u8{0} ** 16, // 16 general purpose 8-bit registers
    index: u16 = 0, // index register , refered as "I" in documentations
    delay_timer: u8 = 0, // delay timer register
    sound_timer: u8 = 0, // sound timer register

    pc: u16 = 0x200, // program counter "pseudo-register"

    sp: u16, // stack pointer "pseudo-register"
    stack: [16]u16 = [_]u8{0} ** 16,

    //
    // - The computers which originally used the Chip-8 Language had a 16-key hexadecimal keypad.
    //
    // - Keyboard Layout:
    // 1	2	3	C
    // 4	5	6	D
    // 7	8	9	E
    // A	0	B	F
    //
    keys: [16]u8 = [_]u8{0} ** 16,

    //
    // The original implementation of the Chip-8 language used a 64x32-pixel monochrome display with this format:
    // -----------------
    // |(0,0)	 (63,0)|
    // |(0,31)	(63,31)|
    // -----------------
    //
    graphics: [64 * 32]u8 = [_]u8{0} ** 64 * 32,

    opcode: u16 = 0,

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
