const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});

const particles = @import("particle.zig"); // assuming this is where particles will come from
const util = @import("util.zig");
const entities = @import("ecs.zig");

const SCREEN_HEIGHT = 720.0;
const SCREEN_WIDTH = 1080.0;

const RENDER_HEIGHT = 240.0;
const RENDER_WIDTH = 360.0;

pub fn main() !void {
    rl.InitWindow(SCREEN_WIDTH, SCREEN_HEIGHT, "bossrush");
    defer rl.CloseWindow();
    rl.SetTargetFPS(60);
    const render_texture = rl.LoadRenderTexture(RENDER_WIDTH, RENDER_HEIGHT);
    const occlusion_mask = rl.LoadRenderTexture(RENDER_WIDTH, RENDER_HEIGHT);
    const scene = rl.LoadRenderTexture(RENDER_WIDTH, RENDER_HEIGHT);
    const lighting = rl.LoadRenderTexture(RENDER_WIDTH, RENDER_HEIGHT);
    const lightingShader = rl.LoadShader(null, "./lighting.glsl");

    const rayCountLoc = rl.GetShaderLocation(lightingShader, "rayCount");
    const sizeloc = rl.GetShaderLocation(lightingShader, "size");

    const size: rl.Vector2 = .{ .x = RENDER_WIDTH, .y = RENDER_HEIGHT };
    rl.SetShaderValue(lightingShader, sizeloc, &size, rl.SHADER_UNIFORM_VEC2);

    const rayCount: i32 = 32;
    rl.SetShaderValue(lightingShader, rayCountLoc, &rayCount, rl.SHADER_UNIFORM_INT);
    while (!rl.WindowShouldClose()) {
        rl.BeginTextureMode(occlusion_mask);
        rl.ClearBackground(rl.BLANK);
        rl.DrawRectangle(25, 30, 10, 100, rl.BLACK);
        rl.DrawRectangle(45, 30, 10, 100, rl.BLACK);
        rl.EndTextureMode();

        const mouse_position = util.GetRelativeMousePosition(RENDER_WIDTH, SCREEN_WIDTH, RENDER_HEIGHT, SCREEN_HEIGHT);
        rl.BeginTextureMode(lighting);
        rl.ClearBackground(rl.BLANK);
        rl.DrawRectangle(100, 100, 20, 35, rl.RED);
        rl.DrawCircle(150, 200, 16, rl.BLUE);
        rl.DrawCircleV(mouse_position, 16, rl.GREEN);
        rl.EndTextureMode();

        rl.BeginTextureMode(scene);
        rl.DrawRectangle(140, 25, 20, 110, rl.WHITE);
        rl.EndTextureMode();

        rl.BeginTextureMode(render_texture);
        rl.BeginShaderMode(lightingShader);
        rl.SetShaderValueTexture(lightingShader, rl.GetShaderLocation(lightingShader, "lighting"), lighting.texture);
        rl.SetShaderValueTexture(lightingShader, rl.GetShaderLocation(lightingShader, "occlusion"), occlusion_mask.texture);
        rl.DrawTexture(scene.texture, 0, 0, rl.WHITE);
        rl.EndShaderMode();
        rl.EndTextureMode();

        rl.BeginDrawing();
        rl.DrawTexturePro(render_texture.texture, .{
            .x = 0,
            .y = 0,
            .width = RENDER_WIDTH,
            .height = RENDER_HEIGHT,
        }, .{
            .x = 0,
            .y = 0,
            .width = SCREEN_WIDTH,
            .height = SCREEN_HEIGHT,
        }, rl.Vector2Zero(), 0, rl.WHITE);
        rl.EndDrawing();
    }
}
