const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});
const particles = @import("particle.zig");

// screen resolution
const SCREEN_HEIGHT = 720.0;
const SCREEN_WIDTH = 1080.0;

// the 'screen' we render to
const RENDER_HEIGHT = 270.0;
const RENDER_WIDTH = 480.0;

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

pub fn GetRelativeMousePosition() rl.Vector2 {
    const mouse_position = rl.GetMousePosition();
    return rl.Vector2Multiply(
        mouse_position,
        .{ .x = RENDER_WIDTH / SCREEN_WIDTH, .y = RENDER_HEIGHT / SCREEN_HEIGHT },
    );
}

const Boss = struct {
    sprite: rl.Texture,
    pos: rl.Vector2,
    rotation: f32 = 0,

    pub fn update(self: *@This(), target_pos: rl.Vector2) void {
        self.rotation = DirectionDegrees(self.pos, target_pos);
    }

    pub fn draw(self: @This()) void {
        drawSpriteStack(self.sprite, self.pos, self.rotation * 180 / rl.PI);
    }

    fn attack(self: *@This(), target_pos: rl.Vector2) void {
        rl.DrawLineEx(self.pos, target_pos, 8, rl.RED);
        rl.DrawLineEx(self.pos, target_pos, 4, rl.WHITE);
    }
};

pub fn main() !void {
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "bossrush");
    rl.SetTargetFPS(60);

    var gpa = std.heap.GeneralPurposeAllocator(.{}).init;
    const allocator = gpa.allocator();

    var particle_system = try particles.ParticleSystem.init(allocator);
    const cube = rl.LoadTexture("assets/cube.png");
    const screen = rl.LoadRenderTexture(RENDER_WIDTH, RENDER_HEIGHT);
    const cube_position: rl.Vector2 = .{ .x = 200, .y = 200 };

    var boss: Boss = .{ .sprite = cube, .pos = cube_position, .rotation = 0 };

    var spark = particles.Spark.init(cube_position, 0, rl.BLUE, 2.0, 1.00, 2);

    particle_system.register(.{ .Spark = spark });

    while (!rl.WindowShouldClose()) {
        const rel_mouse_position = GetRelativeMousePosition();
        const dt = rl.GetFrameTime();

        rl.BeginTextureMode(screen);
        rl.ClearBackground(rl.BLACK);
        rl.DrawCircle(cube_position.x, cube_position.y, 10, rl.RED);
        boss.update(rel_mouse_position);
        boss.draw();

        if (rl.IsMouseButtonDown(rl.MOUSE_BUTTON_LEFT)) {
            boss.attack(rel_mouse_position);
            spark = particles.Spark.init(rel_mouse_position, boss.rotation, rl.WHITE, 2.0, 1.00, 2);
            particle_system.register(.{ .Spark = spark });
        }

        particle_system.update(dt);
        particle_system.draw();
        rl.EndTextureMode();

        rl.BeginDrawing();
        rl.ClearBackground(rl.BLACK);
        rl.DrawTexture(screen.texture, 0, 0, rl.WHITE);
        rl.DrawTexturePro(
            screen.texture,
            .{ .x = 0, .y = 0, .width = @floatFromInt(screen.texture.width), .height = @floatFromInt(-screen.texture.height) },
            .{ .x = 0, .y = 0, .width = SCREEN_WIDTH, .height = SCREEN_HEIGHT },
            rl.Vector2Zero(),
            0,
            rl.WHITE,
        );

        rl.EndDrawing();
    }
}
