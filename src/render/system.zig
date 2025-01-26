const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});

const Animator = @import("animator.zig").Animator;
const AnimationState = @import("animator.zig").AnimationState;
const tatl = @import("tatl.zig");
const ecs = @import("../ecs.zig");

const ENTITY_COUNT = 100000;

const RenderComponent = struct {
    animator: usize,
    state: AnimationState = .{ .HURT = .side },
    frame: usize = 0,
    frame_time: u16 = 0,
};

fn draw(position: rl.Vector2, texture: rl.Texture) void {
    rl.DrawTextureV(texture, position, rl.WHITE);
}

pub const System = struct {
    entities: std.ArrayList(ecs.EntityId), // List of entities with RenderComponent
    render_components: std.AutoHashMap(ecs.EntityId, RenderComponent),
    animators: []Animator,

    pub fn init() System {
        var animators = std.ArrayList(Animator).init(page_allocator);

        for ([_][]const u8{"idle.aseprite"}) |path| {
            const file = cwd.openFile(path, .{}) catch std.debug.panic("erronous path: {s}", .{path});
            const aseprite = tatl.import(page_allocator, file.reader()) catch std.debug.panic("error parsing aseprite file: {s}", .{path});
            const anim = Animator.load(aseprite) catch std.debug.panic("error building animator : {s}", .{path});
            animators.append(anim) catch unreachable;
        }

        return .{
            .animators = animators.toOwnedSlice() catch unreachable,
            .render_components = std.AutoHashMap(ecs.EntityId, RenderComponent).init(page_allocator),
            .entities = std.ArrayList(ecs.EntityId).init(page_allocator),
        };
    }

    pub fn register_entity(self: *@This(), id: ecs.EntityId, animator: usize) !void {
        try self.entities.append(id);
        try self.render_components.put(id, RenderComponent{
            .animator = animator,
            .state = .{ .WALK = .side },
        });
    }

    pub fn remove_entity(self: *@This(), id: ecs.EntityId) void {
        const idx = self.entities.indexOf(id);
        if (idx) |index| {
            self.entities.remove(index);
        }
        _ = self.render_components.remove(id);
    }

    pub fn tick(self: *@This(), frametime_ms: u16, ECS: ecs.ECS) void {
        for (self.entities.items) |entity| {
            var comp = self.render_components.getPtr(entity).?;
            const animator = self.animators[comp.animator];
            const frames = animator.get_frames(comp.state);

            const current_frame = frames[comp.frame];
            const duration = current_frame.duration;

            comp.frame_time += frametime_ms;
            if (duration <= comp.frame_time) {
                comp.frame = (1 + comp.frame) % frames.len;
                comp.frame_time = 0;
            }

            const comps = ECS.query(entity);
            if (comps.Transform) |transform| {
                const position = transform.position;
                const midpoint: rl.Vector2 = rl.Vector2Scale(animator.canvas_size, 0.5);
                const texture = current_frame.texture_cels[animator.get_texture("DEFAULT") orelse continue];
                draw(.{
                    .x = position.x + @as(f32, @floatFromInt(texture.x)) - midpoint.x,
                    .y = position.y + @as(f32, @floatFromInt(texture.y)) - midpoint.y,
                }, texture.texture);
            }
        }
    }

    pub fn query(self: @This(), id: ecs.EntityId) ?RenderComponent {
        return self.renders[id];
    }
};

const cwd = std.fs.cwd();
const page_allocator = std.heap.page_allocator;
