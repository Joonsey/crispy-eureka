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

    pub fn draw(self: *@This()) !void {
        var animation_texture = try self.animator.get_texture("default", .{ .HURT = .side });
        var texture = animation_texture.texture;
        const default_start = animation_texture;

        rl.DrawTexturePro(texture, .{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(texture.width),
            .height = @floatFromInt(texture.height),
        }, .{
            .x = self.position.x,
            .y = self.position.y,
            .width = @floatFromInt(texture.width),
            .height = @floatFromInt(texture.height),
        }, .{ .x = @floatFromInt(@divTrunc(texture.width, 2)), .y = @floatFromInt(texture.height) }, 0, rl.WHITE);

        // for equipment in equipments:
        animation_texture = try self.animator.get_texture("hat_1", .{ .IDLE = .side });
        texture = animation_texture.texture;
        rl.DrawTexturePro(texture, .{
            .x = 0,
            .y = 0,
            .width = @floatFromInt(texture.width),
            .height = @floatFromInt(texture.height),
        }, .{
            .x = self.position.x + @as(f32, @floatFromInt(animation_texture.x - default_start.x)),
            .y = self.position.y + @as(f32, @floatFromInt(animation_texture.y - default_start.y)),
            .width = @floatFromInt(texture.width),
            .height = @floatFromInt(texture.height),
        }, .{ .x = @floatFromInt(@divTrunc(default_start.texture.width, 2)), .y = @floatFromInt(default_start.texture.height) }, 0, rl.WHITE);
    }
};
