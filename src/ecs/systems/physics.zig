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
            var new_position = rl.Vector2Add(transform.position, frametime_vel);
            if (ecs.query(entity, Components.BoxColliderComponent)) |collider| {
                const collider_rect_x = rl.Rectangle{
                    .x = new_position.x + collider.offset.x,
                    .y = transform.position.y + collider.offset.y,
                    .width = collider.dimensions.x,
                    .height = collider.dimensions.y,
                };

                const collider_rect_y = rl.Rectangle{
                    .x = transform.position.x + collider.offset.x,
                    .y = new_position.y + collider.offset.y,
                    .width = collider.dimensions.x,
                    .height = collider.dimensions.y,
                };

                for (ecs.collision_system.entities.items) |other_entity| {
                    if (other_entity == entity) continue;

                    const other_transform = ecs.query(other_entity, Components.TransformComponent) orelse return;
                    const other_collider = ecs.query(other_entity, Components.BoxColliderComponent) orelse return;
                    const other_collider_rect = rl.Rectangle{
                        .x = other_transform.position.x + other_collider.offset.x,
                        .y = other_transform.position.y + other_collider.offset.y,
                        .width = other_collider.dimensions.x,
                        .height = other_collider.dimensions.y,
                    };

                    if (rl.CheckCollisionRecs(collider_rect_x, other_collider_rect)) {
                        //rl.DrawRectangleRec(collider_rect_x, rl.GREEN);
                        //rl.DrawRectangleRec(other_collider_rect, rl.RED);
                        new_position.x = transform.position.x;
                    }
                    if (rl.CheckCollisionRecs(collider_rect_y, other_collider_rect)) {
                        //rl.DrawRectangleRec(collider_rect_y, rl.GREEN);
                        //rl.DrawRectangleRec(other_collider_rect, rl.BLUE);
                        new_position.y = transform.position.y;
                    }
                }
            }

            transform.position = new_position;
        }
    }
};

pub const CollisionSystem = struct {
    entities: std.ArrayList(EntityId),

    pub fn init(allocator: std.mem.Allocator) @This() {
        return .{ .entities = std.ArrayList(EntityId).init(allocator) };
    }
};
