const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});

/// Draws perfectly on top of the center position
///Center position will be center bottom point of the 'rectangle' that is the texture
pub fn drawSpriteStack(image: rl.Texture, center_position: rl.Vector2, rotation: f32) void {
    const amount: usize = @intCast(@divTrunc(image.height, image.width));
    for (0..amount + 1) |i| {
        const inverse_i = amount - i;
        const src_y: f32 = @as(f32, @floatFromInt(inverse_i)) * @as(f32, @floatFromInt(image.width));
        const dest_y: f32 = @as(f32, @floatFromInt(inverse_i)) - @as(f32, @floatFromInt(amount));
        rl.DrawTexturePro(
            image,
            .{
                .x = 0,
                .y = src_y,
                .width = @floatFromInt(image.width),
                .height = @floatFromInt(image.width),
            },
            .{
                .x = center_position.x,
                .y = dest_y + center_position.y,
                .width = @floatFromInt(image.width),
                .height = @floatFromInt(image.width),
            },
            .{ .x = @as(f32, @floatFromInt(image.width)) / 2, .y = @as(f32, @floatFromInt(image.width)) / 2 },
            rotation,
            rl.WHITE,
        );
    }
}

pub fn DirectionDegrees(A: rl.Vector2, B: rl.Vector2) f32 {
    const deltaX = B.x - A.x;
    const deltaY = B.y - A.y;
    const radians: f32 = @floatCast(rl.atan2(deltaY, deltaX));
    return radians;
}

pub fn main() !void {
    rl.InitWindow(1080, 720, "bossrush");
    rl.SetTargetFPS(60);
    const cube = rl.LoadTexture("assets/cube.png");
    const screen = rl.LoadRenderTexture(540, 360);
    const cube_position: rl.Vector2 = .{ .x = 200, .y = 200 };

    while (!rl.WindowShouldClose()) {
        const mouse_position = rl.GetMousePosition();
        const rel_mouse_position = rl.Vector2Multiply(
            mouse_position,
            .{ .x = 540.0 / 1080.0, .y = 360.0 / 720.0 },
        );
        const rotation = DirectionDegrees(cube_position, rel_mouse_position);

        rl.BeginTextureMode(screen);
        rl.ClearBackground(rl.RAYWHITE);
        rl.DrawCircle(cube_position.x, cube_position.y, 10, rl.RED);
        rl.DrawCircle(@intFromFloat(rel_mouse_position.x), @intFromFloat(rel_mouse_position.y), 10, rl.YELLOW);
        drawSpriteStack(cube, cube_position, rotation * 180 / rl.PI);

        rl.EndTextureMode();

        rl.BeginDrawing();
        rl.ClearBackground(rl.BLACK);
        rl.DrawTexture(screen.texture, 0, 0, rl.WHITE);
        rl.DrawTexturePro(
            screen.texture,
            .{ .x = 0, .y = 0, .width = @floatFromInt(screen.texture.width), .height = @floatFromInt(-screen.texture.height) },
            .{ .x = 0, .y = 0, .width = 1080, .height = 720 },
            rl.Vector2Zero(),
            0,
            rl.WHITE,
        );
        rl.EndDrawing();
    }
}
