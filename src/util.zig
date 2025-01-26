const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});

pub fn GetRelativeMousePosition(render_width: f32, screen_width: f32, render_height: f32, screen_height: f32) rl.Vector2 {
    const mouse_position = rl.GetMousePosition();
    return rl.Vector2Multiply(
        mouse_position,
        .{ .x = render_width / screen_width, .y = render_height / screen_height },
    );
}

pub fn GetNormalizedMousePosition(screen_width: f32, screen_height: f32) rl.Vector2 {
    const mouse_position = rl.GetMousePosition();
    return .{ .x = mouse_position.x / screen_width, .y = mouse_position.y / screen_height };
}
