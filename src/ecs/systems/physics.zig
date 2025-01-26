const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});

const Components = @import("../components.zig");
const main = @import("../main.zig");
const EntityId = main.EntityId;

pub const PhysicsSystem = struct {
    entities: std.ArrayList(EntityId),

    pub fn init(allocator: std.mem.Allocator) @This() {
        return .{ .entities = std.ArrayList(EntityId).init(allocator) };
    }

    pub fn tick_all(self: *@This(), frametime_ms: u16, ecs: main.ECS) void {
        for (self.entities.items) |entity| {
            const transform = ecs.query(entity, Components.TransformComponent) orelse return;
            const physics = ecs.query(entity, Components.PhysicsComponent) orelse return;

            const frametime_vel = rl.Vector2Scale(physics.velocity, @as(f32, @floatFromInt(frametime_ms)) / 1000);
            transform.position = rl.Vector2Add(transform.position, frametime_vel);
        }
    }
};
