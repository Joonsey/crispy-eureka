const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});

const Components = @import("../components.zig");
const main = @import("../main.zig");
const EntityId = main.EntityId;

pub const DirectionSystem = struct {
    entities: std.ArrayList(EntityId),

    pub fn init(allocator: std.mem.Allocator) @This() {
        return .{ .entities = std.ArrayList(EntityId).init(allocator) };
    }

    pub fn tick_all(self: *@This(), frametime_ms: u16, ecs: main.ECS) void {
        _ = self; // autofix
        _ = frametime_ms; // autofix
        _ = ecs; // autofix
        return;
    }
};
