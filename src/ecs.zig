const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});
const AnimationState = @import("render/animator.zig").AnimationState;
const RenderSystem = @import("render/main.zig").System;

pub const EntityId = u32;


pub fn SparseSet(comptime T: type) type {
    return struct {
        sparse: std.ArrayList(?usize), // Maps entity IDs to dense indices
        dense: std.ArrayList(usize), // Stores entity IDs
        components: std.ArrayList(T), // Stores the actual components

        pub fn init(allocator: std.mem.Allocator) SparseSet(T) {
            return SparseSet(T){
                .sparse = std.ArrayList(?usize).init(allocator),
                .dense = std.ArrayList(usize).init(allocator),
                .components = std.ArrayList(T).init(allocator),
            };
        }

        pub fn deinit(self: *SparseSet(T)) void {
            self.sparse.deinit();
            self.dense.deinit();
            self.components.deinit();
        }

        /// Adds or updates a component for a given entity.
        pub fn set(self: *SparseSet(T), entity_id: usize, component: T) !void {
            if (entity_id >= self.sparse.items.len) {
                try self.sparse.resize(entity_id + 1); // Expand sparse array with `null`
                self.sparse.items[entity_id] = null;
            }

            if (self.sparse.items[entity_id] != null) {
                // Update existing component
                const dense_index = self.sparse.items[entity_id].?;
                self.components.items[dense_index] = component;
            } else {
                // Add new component
                try self.dense.append(entity_id);
                try self.components.append(component);
                self.sparse.items[entity_id] = self.dense.items.len - 1;
            }
        }

        /// Gets a component for a given entity.
        pub fn get(self: SparseSet(T), entity_id: usize) ?*T {
            if (entity_id >= self.sparse.items.len or self.sparse.items[entity_id] == null) {
                return null;
            }
            const dense_index = self.sparse.items[entity_id].?;
            return &self.components.items[dense_index];
        }

        /// Removes a component for a given entity.
        pub fn remove(self: *SparseSet(T), entity_id: usize) void {
            if (entity_id >= self.sparse.items.len or self.sparse.items[entity_id] == null) {
                return;
            }
            const dense_index = self.sparse.items[entity_id].?;

            // Swap the dense element with the last element
            const last_dense_index = self.dense.len - 1;
            if (dense_index != last_dense_index) {
                const last_entity_id = self.dense.items[last_dense_index];
                self.dense.items[dense_index] = last_entity_id;
                self.components.items[dense_index] = self.components.items[last_dense_index];
                self.sparse.items[last_entity_id] = dense_index;
            }

            // Remove the last element
            _ = self.dense.pop();
            _ = self.components.pop();
            self.sparse.items[entity_id] = null;
        }
    };
}

const PhysicsSystem = struct {
    entities: std.ArrayList(EntityId),

    pub fn init(allocator: std.mem.Allocator) @This() {
        return .{ .entities = std.ArrayList(EntityId).init(allocator) };
    }

    pub fn tick_all(self: *@This(), frametime_ms: u16, ecs: ECS) void {
        for (self.entities.items) |entity| {
            const transform = ecs.query(entity, TransformComponent) orelse return;
            const physics = ecs.query(entity, PhysicsComponent) orelse return;

            const frametime_vel = rl.Vector2Scale(physics.velocity, @as(f32, @floatFromInt(frametime_ms)) / 1000);
            transform.position = rl.Vector2Add(transform.position, frametime_vel);
        }
    }
};

pub const ECS = struct {
    transforms: SparseSet(TransformComponent),
    renders: SparseSet(RenderComponent),
    physics: SparseSet(PhysicsComponent),
    next_entity_id: EntityId,

    render_system: RenderSystem,
    physics_system: PhysicsSystem,

    pub fn init(allocator: std.mem.Allocator) ECS {
        return .{
            .transforms = SparseSet(TransformComponent).init(allocator),
            .physics = SparseSet(PhysicsComponent).init(allocator),
            .renders = SparseSet(RenderComponent).init(allocator),
            .next_entity_id = 0,
            .render_system = RenderSystem.init(),
            .physics_system = PhysicsSystem.init(allocator),
        };
    }

    pub fn new_entity(self: *@This()) EntityId {
        const entity_id = self.next_entity_id;
        self.next_entity_id += 1;
        return entity_id;
    }

    pub fn query(self: @This(), id: EntityId, comptime T: type) ?*T {
        return switch (T) {
            PhysicsComponent => self.physics.get(id),
            RenderComponent => self.renders.get(id),
            TransformComponent => self.transforms.get(id),
            else => null,
        };
    }

    pub fn add(self: *@This(), id: EntityId, component: Components) !void {
        switch (component) {
            .render => |comp| {
                try self.renders.set(id, comp);
                // we need to tell the render system that we might care about this guy now
                try self.render_system.entities.append(id);
            },
            .transform => |comp| try self.transforms.set(id, comp),
            .physics => |comp| {
                try self.physics.set(id, comp);
                try self.physics_system.entities.append(id);
            },
        }
    }

    pub fn tick(self: *@This(), dt_ms: u16) void {
        self.render_system.tick_all(dt_ms, self.*);
        self.physics_system.tick_all(dt_ms, self.*);
    }
};
