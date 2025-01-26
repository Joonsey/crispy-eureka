const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});

const Components = @import("components.zig");
const Systems = @import("systems/main.zig");
const SparseSet = @import("sparse_set.zig").SparseSet;

pub const EntityId = usize;

pub const ECS = struct {
    transforms: SparseSet(Components.TransformComponent),
    renders: SparseSet(Components.RenderComponent),
    physics: SparseSet(Components.PhysicsComponent),
    tags: SparseSet(Components.TagComponent),
    directions: SparseSet(Components.DirectionComponent),
    next_entity_id: EntityId,

    render_system: Systems.RenderSystem,
    physics_system: Systems.PhysicsSystem,
    direction_system: Systems.DirectionSystem,

    pub fn init(allocator: std.mem.Allocator) ECS {
        return .{
            .transforms = SparseSet(Components.TransformComponent).init(allocator),
            .physics = SparseSet(Components.PhysicsComponent).init(allocator),
            .renders = SparseSet(Components.RenderComponent).init(allocator),
            .tags = SparseSet(Components.TagComponent).init(allocator),
            .directions = SparseSet(Components.DirectionComponent).init(allocator),
            .next_entity_id = 0,
            .render_system = Systems.RenderSystem.init(allocator),
            .physics_system = Systems.PhysicsSystem.init(allocator),
            .direction_system = Systems.DirectionSystem.init(allocator),
        };
    }

    pub fn new_entity(self: *@This()) EntityId {
        const entity_id = self.next_entity_id;
        self.next_entity_id += 1;
        return entity_id;
    }

    pub fn query(self: @This(), id: EntityId, comptime T: type) ?*T {
        return switch (T) {
            Components.PhysicsComponent => self.physics.get(id),
            Components.RenderComponent => self.renders.get(id),
            Components.TransformComponent => self.transforms.get(id),
            Components.TagComponent => self.tags.get(id),
            Components.DirectionComponent => self.directions.get(id),
            else => null,
        };
    }

    pub fn add(self: *@This(), id: EntityId, component: Components.Component) !void {
        switch (component) {
            .render => |comp| {
                try self.renders.set(id, comp);
                // we need to tell the render system that we might care about this guy now
                try self.render_system.entities.append(id);
            },
            .transform => |comp| try self.transforms.set(id, comp),
            .tag => |comp| try self.tags.set(id, comp),
            .physics => |comp| {
                try self.physics.set(id, comp);
                // we need to tell the physics system that we might care about this guy now
                try self.physics_system.entities.append(id);
            },
            .direction => |comp| {
                try self.directions.set(id, comp);
                // we need to tell the direction system that we might care about this guy now
                try self.direction_system.entities.append(id);
            },
        }
    }

    pub fn tick(self: *@This(), dt_ms: u16) void {
        self.render_system.tick_all(dt_ms, self.*);
        self.physics_system.tick_all(dt_ms, self.*);
        self.direction_system.tick_all(dt_ms, self.*);

        // yolo but works, for now...
        // also assuming we never tag anything else than player
        // but at least it won't pollute the interface
        // the game scope knows the player id anyway. So this is only for 'automagic' stuff
        const player = self.tags.dense.getLast();

        const physics = self.query(player, Components.PhysicsComponent).?;
        const direction = self.query(player, Components.DirectionComponent).?;
        const render = self.query(player, Components.RenderComponent).?;

        var new_direction = direction.*;
        const was_moving = rl.Vector2Length(physics.velocity) != 0.0;

        const float_dt: f32 = @floatFromInt(dt_ms);
        const SPEED: f32 = 3;
        if (rl.IsKeyDown(rl.KEY_W)) {
            physics.velocity.y = -SPEED * float_dt;
            new_direction = .UP;
        } else if (rl.IsKeyDown(rl.KEY_S)) {
            physics.velocity.y = SPEED * float_dt;
            new_direction = .DOWN;
        } else {
            physics.velocity.y = 0;
        }
        if (rl.IsKeyDown(rl.KEY_A)) {
            physics.velocity.x = -SPEED * float_dt;
            new_direction = .LEFT;
        } else if (rl.IsKeyDown(rl.KEY_D)) {
            physics.velocity.x = SPEED * float_dt;
            new_direction = .RIGHT;
        } else {
            physics.velocity.x = 0;
        }

        if (new_direction != direction.*) {
            direction.* = new_direction;
        }

        const magnitude = rl.Vector2Length(physics.velocity);
        const is_moving = magnitude != 0.0;

        if (magnitude > SPEED) {
            physics.velocity = rl.Vector2Scale(rl.Vector2Normalize(physics.velocity), SPEED * float_dt);
        }

        render.state = switch (new_direction) {
            .RIGHT => if (is_moving) .{ .WALK = .right } else .{ .IDLE = .right },
            .LEFT => if (is_moving) .{ .WALK = .left } else .{ .IDLE = .left },
            .UP => if (is_moving) .{ .WALK = .up } else .{ .IDLE = .up },
            .DOWN => if (is_moving) .{ .WALK = .down } else .{ .IDLE = .down },
        };

        if (is_moving != was_moving) {
            render.frame = 0;
        }
    }
};
