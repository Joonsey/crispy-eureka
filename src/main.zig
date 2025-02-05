const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});

const ldtk = @import("ldtk.zig");
const util = @import("util.zig");
const entities = @import("ecs/main.zig");
const network = @import("network");

const SCREEN_HEIGHT = 720.0;
const SCREEN_WIDTH = 1080.0;

const RENDER_HEIGHT = 240.0;
const RENDER_WIDTH = 360.0;

var GPA = std.heap.GeneralPurposeAllocator(.{}){};
const allocator = GPA.allocator();

pub fn main() !void {
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "bossrush");
    defer rl.CloseWindow();

    var ECS = entities.ECS.init(allocator);
    try network.init();
    var sock = try network.Socket.create(.ipv4, .udp);
    defer sock.close();
    try sock.bindToPort(6666);

    var buffer: [1024]u8 = undefined;
    const from = try sock.receiveFrom(&buffer);
    _ = try sock.sendTo(from.sender, buffer[0..from.numberOfBytes]);
    std.log.info("{}, {s}", .{ from.sender.address, buffer[0..from.numberOfBytes] });

    const player = ECS.new_entity();
    try ECS.add(player, .{ .transform = .{ .position = .{ .x = 200, .y = 150 } } });
    try ECS.add(player, .{ .render = .{ .animator = 0 } });
    try ECS.add(player, .{ .tag = .{} });
    try ECS.add(player, .{ .direction = .UP });
    try ECS.add(player, .{ .physics = .{ .velocity = rl.Vector2Zero() } });
    try ECS.add(player, .{ .z = .{ .z = 1 } });
    try ECS.add(player, .{ .box_collider = .{ .dimensions = .{ .x = 6, .y = 6 }, .offset = .{ .x = -4, .y = -4 } } });
    rl.SetTargetFPS(60);
    const scene = rl.LoadRenderTexture(RENDER_WIDTH, RENDER_HEIGHT);

    while (!rl.WindowShouldClose()) {
        const frametime_ms: u16 = @intFromFloat(rl.GetFrameTime() * 1000);
        rl.BeginTextureMode(scene);
        rl.ClearBackground(rl.BLACK);

        ECS.tick(frametime_ms);
        rl.EndTextureMode();

        rl.BeginDrawing();
        rl.DrawTexturePro(scene.texture, .{
            .x = 0,
            .y = 0,
            .width = RENDER_WIDTH,
            .height = -RENDER_HEIGHT,
        }, .{
            .x = 0,
            .y = 0,
            .width = SCREEN_WIDTH,
            .height = SCREEN_HEIGHT,
        }, rl.Vector2Zero(), 0, rl.WHITE);
        rl.DrawFPS(0, 0);
        rl.EndDrawing();
    }
}
