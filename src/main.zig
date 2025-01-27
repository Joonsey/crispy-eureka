const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});

const ldtk = @import("ldtk.zig");
const util = @import("util.zig");
const entities = @import("ecs/main.zig");

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
    const conf = try ldtk.Ldtk.init();

    const player = ECS.new_entity();
    try ECS.add(player, .{ .transform = .{ .position = .{ .x = 200, .y = 150 } } });
    try ECS.add(player, .{ .render = .{ .animator = 0 } });
    try ECS.add(player, .{ .tag = .{} });
    try ECS.add(player, .{ .direction = .UP });
    try ECS.add(player, .{ .physics = .{ .velocity = rl.Vector2Zero() } });
    try ECS.add(player, .{ .z = .{ .z = 1 } });
    try ECS.add(player, .{ .box_collider = .{ .dimensions = .{ .x = 6, .y = 6 }, .offset = .{ .x = -4, .y = -4 } } });
    rl.SetTargetFPS(60);
    for (conf.levels) |level| {
        var i = level.layerInstances.len - 1;
        while (i > 0) : (i -= 1) {
            const instance = level.layerInstances[i];
            const collision_layer = std.mem.eql(u8, instance.__identifier, "Collisions");
            const z_layer_one = collision_layer or std.mem.eql(u8, instance.__identifier, "Wall_tops");
            for (instance.gridTiles) |tile| {
                const tile_id = ECS.new_entity();
                try ECS.add(tile_id, .{ .transform = .{
                    .position = .{
                        .x = @floatFromInt(tile.px[0] + instance.__pxTotalOffsetX + level.worldX),
                        .y = @floatFromInt(tile.px[1] + instance.__pxTotalOffsetY + level.worldY),
                    },
                } });
                try ECS.add(tile_id, .{
                    .sprite = .{
                        .source = .{ .x = tile.src[0], .y = tile.src[1] },
                        .tilesheet = 0,
                        .flipX = (tile.f == 1 or tile.f == 3),
                        .flipY = (tile.f == 2 or tile.f == 3),
                        .width = 16,
                        .height = 16,
                        .alpha = @intFromFloat(tile.a * 255),
                    },
                });
                if (z_layer_one) try ECS.add(tile_id, .{ .z = .{ .z = 1 } });
            }
            for (instance.autoLayerTiles) |tile| {
                const tile_id = ECS.new_entity();
                try ECS.add(tile_id, .{ .transform = .{
                    .position = .{
                        .x = @floatFromInt(tile.px[0] + instance.__pxTotalOffsetX + level.worldX),
                        .y = @floatFromInt(tile.px[1] + instance.__pxTotalOffsetY + level.worldY),
                    },
                } });
                try ECS.add(tile_id, .{
                    .sprite = .{
                        .source = .{ .x = tile.src[0], .y = tile.src[1] },
                        .tilesheet = 0,
                        .flipX = (tile.f == 1 or tile.f == 3),
                        .flipY = (tile.f == 2 or tile.f == 3),
                        .width = 16,
                        .height = 16,
                        .alpha = @intFromFloat(tile.a * 255),
                    },
                });
                if (z_layer_one) try ECS.add(tile_id, .{ .z = .{ .z = 1 } });
                if (collision_layer) try ECS.add(tile_id, .{ .box_collider = .{ .dimensions = .{ .x = 16, .y = 16 }, .offset = .{ .x = -8, .y = -16 } } });
            }
        }
    }

    const scene = rl.LoadRenderTexture(RENDER_WIDTH, RENDER_HEIGHT);

    while (!rl.WindowShouldClose()) {
        const frametime_ms: u16 = @intFromFloat(rl.GetFrameTime() * 1000);
        //const mouse_position = util.GetRelativeMousePosition(RENDER_WIDTH, SCREEN_WIDTH, RENDER_HEIGHT, SCREEN_HEIGHT);
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
