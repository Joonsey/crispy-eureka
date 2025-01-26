const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});

const MAX_ENTITY_COUNT = 10000;
pub const EntityId = u32;

const TransformComponent = struct {
    position: rl.Vector2,
    rotation: f32,
};

const Components = struct {
    Transform: ?TransformComponent = null,
    Velocity: ?rl.Vector3 = null,
    Health: ?f32 = null,
};

fn contains(list: std.ArrayList(EntityId), value: EntityId) bool {
    for (list.items) |item| {
        if (item == value) {
            return true;
        }
    }
    return false;
}

const View = struct {
    component_ptrs: []Components,
    idx: u32,
    len: usize,

    pub fn init(comps: []Components) View {
        return .{
            .component_ptrs = comps,
            .idx = 0,
            .len = comps.len,
        };
    }

    pub fn next(self: *@This()) ?*Components {
        if (self.idx >= self.len) {
            return null;
        }
        const i = self.idx;
        self.idx += 1;
        return &self.component_ptrs.ptr[i];
    }
};

pub const ECS = struct {
    entities: [MAX_ENTITY_COUNT]Components,
    count: EntityId,
    free_ids: std.ArrayList(EntityId),

    pub fn init(allocator: std.mem.Allocator) ECS {
        return .{
            .entities = undefined,
            .count = 0,
            .free_ids = std.ArrayList(EntityId).init(allocator),
        };
    }

    fn valid_entity_id(self: @This(), id: EntityId) bool {
        if (contains(self.free_ids, id)) return false;
        return id < self.count;
    }

    pub fn new_entity(self: *@This()) EntityId {
        if (self.free_ids.popOrNull()) |id| {
            return id;
        }

        if (self.count >= MAX_ENTITY_COUNT) {
            std.log.err("entity count overflow, re-using last entity", .{});
            return self.count;
        }
        const i = self.count;
        self.count += 1;
        self.entities[i] = .{};
        return i;
    }

    pub fn delete_entity(self: *@This(), id: EntityId) !void {
        if (!self.valid_entity_id(id)) {
            std.log.err("delete error: invalid entity ID: {d}", .{id});
            return error.InvalidId;
        }
        self.entities[id] = .{};
        self.free_ids.append(id);
    }

    pub fn set_components(self: *@This(), components: Components, id: EntityId) !*Components {
        if (!self.valid_entity_id(id)) {
            std.log.err("set component error: invalid entity ID: {d}", .{id});
            return error.InvalidId;
        }

        self.entities[id] = components;
        return &self.entities[id];
    }

    pub fn view(self: *@This()) View {
        return View.init(self.entities[0..self.count]);
    }

    pub fn query(self: @This(), id: EntityId) Components {
        return self.entities[id];
    }
};
