const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});

const render = @import("../../render/main.zig");
const Animator = render.Animator;
const AnimationState = render.AnimationState;
const Components = @import("../components.zig");
const ecs = @import("../main.zig");

fn draw(position: rl.Vector2, texture: rl.Texture) void {
    rl.DrawTextureV(texture, position, rl.WHITE);
}

pub const RenderSystem = struct {
    entities: std.ArrayList(ecs.EntityId),
    animators: []Animator,

    pub fn init(allocator: std.mem.Allocator) RenderSystem {
        var animators = std.ArrayList(Animator).init(allocator);
        const cwd = std.fs.cwd();

        for ([_][]const u8{"idle.aseprite"}) |path| {
            const file = cwd.openFile(path, .{}) catch std.debug.panic("erronous path: {s}", .{path});
            const aseprite = render.import(allocator, file.reader()) catch std.debug.panic("error parsing aseprite file: {s}", .{path});
            const anim = Animator.load(aseprite, allocator) catch std.debug.panic("error building animator : {s}", .{path});
            animators.append(anim) catch unreachable;
        }

        return .{
            .animators = animators.toOwnedSlice() catch unreachable,
            .entities = std.ArrayList(ecs.EntityId).init(allocator),
        };
    }

    pub fn tick_all(self: *@This(), frametime_ms: u16, ECS: ecs.ECS) void {
        for (self.entities.items) |entity| {
            self.tick(frametime_ms, ECS, entity);
        }
    }

    fn tick(self: *@This(), frametime_ms: u16, ECS: ecs.ECS, entity: ecs.EntityId) void {
        const animation = ECS.query(entity, Components.RenderComponent) orelse return;
        const transform = ECS.query(entity, Components.TransformComponent) orelse return;

        const animator = self.animators[animation.animator];
        const frames = animator.get_frames(animation.state);

        const current_frame = frames[animation.frame];
        const duration = current_frame.duration;

        animation.frame_time += frametime_ms;
        if (duration <= animation.frame_time) {
            animation.frame = (1 + animation.frame) % frames.len;
            animation.frame_time = 0;
        }

        const position = transform.position;
        const midpoint: rl.Vector2 = rl.Vector2Scale(animator.canvas_size, 0.5);
        const texture = current_frame.texture_cels[animator.get_texture("DEFAULT") orelse return];
        draw(.{
            .x = position.x + @as(f32, @floatFromInt(texture.x)) - midpoint.x,
            .y = position.y + @as(f32, @floatFromInt(texture.y)) - midpoint.y,
        }, texture.texture);
    }
};
