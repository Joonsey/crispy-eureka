const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});

pub fn main() !void {
    rl.InitWindow(1080, 720, "bossrush");
    rl.SetTargetFPS(20);

    while (!rl.WindowShouldClose()) {}
}
