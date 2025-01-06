const std = @import("std");

const sdl = @cImport(@cInclude("SDL.h"));

const CHIP8 = @import("chip8.zig");

var window: ?*sdl.SDL_Window = null;
var renderer: ?*sdl.SDL_Renderer = null;
var texture: ?*sdl.SDL_Texture = null;

var cpu: *CHIP8 = undefined;

pub fn init() void {
    if (sdl.SDL_Init(sdl.SDL_INIT_VIDEO) < 0)
        @panic("SDL Initialization Failed!");

    window = sdl.SDL_CreateWindow("CHIP8", sdl.SDL_WINDOWPOS_CENTERED, sdl.SDL_WINDOWPOS_CENTERED, 1024, 512, 0);
    if (window == null)
        @panic("Window Creation Failed!");

    renderer = sdl.SDL_CreateRenderer(window, -1, 0);
    if (renderer == null)
        @panic("SDL renderer Initialization Failed!");

    texture = sdl.SDL_CreateTexture(renderer, sdl.SDL_PIXELFORMAT_RGBA8888, sdl.SDL_TEXTUREACCESS_STREAMING, 64, 32);
    if (texture == null)
        @panic("SDL Texture Creation Failed!");
}
pub fn deinit() void {
    sdl.SDL_DestroyWindow(window);
    sdl.SDL_Quit();
}

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    const allocator = arena.allocator();
    defer arena.deinit();

    init();
    defer deinit();

    cpu = try allocator.create(CHIP8);

    var keep_open = true;
    while (keep_open) {
        // TODO: Emulator Cycle

        var e: sdl.SDL_Event = undefined;
        while (sdl.SDL_PollEvent(&e) > 0) {
            switch (e.type) {
                sdl.SDL_QUIT => keep_open = false,
                else => {},
            }
        }

        _ = sdl.SDL_RenderClear(renderer);
        // TODO: Build Texture

        _ = sdl.SDL_RenderCopy(renderer, texture, null, null);
        _ = sdl.SDL_RenderPresent(renderer);

        std.time.sleep(16 * 1000 * 1000);
    }
}
