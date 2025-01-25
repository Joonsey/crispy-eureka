const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});
const tatl = @import("tatl.zig");

const Animator = @import("animator.zig").Animator;
const AnimationState = @import("animator.zig").AnimationState;

const Direction = enum(u8) {
    right,
    left,
};

pub const Sprite = struct {
    animator: Animator,
    direction: Direction,
    position: rl.Vector2,
    canvas_size: rl.Vector2,

    pub fn draw(self: *@This()) !void {
        var animation_texture = try self.animator.get_texture("default", .{ .IDLE = .side });
        var texture = animation_texture.texture;
        const midpoint: rl.Vector2 = rl.Vector2Scale(self.canvas_size, 0.5);

        rl.DrawTexturePro(texture, .{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(texture.width),
            .height = @floatFromInt(texture.height),
        }, .{
            .x = self.position.x + @as(f32, @floatFromInt(animation_texture.x)) - midpoint.x,
            .y = self.position.y + @as(f32, @floatFromInt(animation_texture.y)) - midpoint.y,
            .width = @floatFromInt(texture.width),
            .height = @floatFromInt(texture.height),
        }, .{ .x = 0, .y = 0 }, 0, rl.WHITE);

        // for equipment in equipments:
        animation_texture = try self.animator.get_texture("hat_1", .{ .IDLE = .side });
        texture = animation_texture.texture;
        rl.DrawTexturePro(texture, .{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(texture.width),
            .height = @floatFromInt(texture.height),
        }, .{
            .x = self.position.x + @as(f32, @floatFromInt(animation_texture.x)) - midpoint.x,
            .y = self.position.y + @as(f32, @floatFromInt(animation_texture.y)) - midpoint.y,
            .width = @floatFromInt(texture.width),
            .height = @floatFromInt(texture.height),
        }, .{ .x = 0, .y = 0 }, 0, rl.WHITE);
    }
};
