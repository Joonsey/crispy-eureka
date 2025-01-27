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
    tilesheets: []rl.Texture,

    pub fn init(allocator: std.mem.Allocator) RenderSystem {
        var animators = std.ArrayList(Animator).init(allocator);
        var tilesheets = std.ArrayList(rl.Texture).init(allocator);
        const cwd = std.fs.cwd();

        for ([_][]const u8{"idle.aseprite"}) |path| {
            const file = cwd.openFile(path, .{}) catch std.debug.panic("erronous path: {s}", .{path});
            const aseprite = render.import(allocator, file.reader()) catch std.debug.panic("error parsing aseprite file: {s}", .{path});
            const anim = Animator.load(aseprite, allocator) catch std.debug.panic("error building animator : {s}", .{path});
            animators.append(anim) catch unreachable;
        }

        for ([_][]const u8{"example.png"}) |path| {
            tilesheets.append(rl.LoadTexture(@ptrCast(path))) catch unreachable;
        }

        return .{
            .animators = animators.toOwnedSlice() catch unreachable,
            .entities = std.ArrayList(ecs.EntityId).init(allocator),
            .tilesheets = tilesheets.toOwnedSlice() catch unreachable,
        };
    }

    pub fn tick_all(self: *@This(), frametime_ms: u16, ECS: ecs.ECS) void {
        const entities = self.entities.items;
        std.mem.sort(ecs.EntityId, entities, ECS, sort_by_y);
        for (entities) |entity| {
            self.tick(frametime_ms, ECS, entity);
        }
    }

    fn sort_by_y(ECS: ecs.ECS, a: ecs.EntityId, b: ecs.EntityId) bool {
        const transform_a = ECS.query(a, Components.TransformComponent) orelse &Components.TransformComponent{ .position = rl.Vector2Zero() };
        const transform_b = ECS.query(b, Components.TransformComponent) orelse &Components.TransformComponent{ .position = rl.Vector2Zero() };

        const a_z = ECS.query(a, Components.ZComponent) orelse &Components.ZComponent{ .z = 0 };
        const b_z = ECS.query(b, Components.ZComponent) orelse &Components.ZComponent{ .z = 0 };
        if (a_z.z != b_z.z) {
            return a_z.z < b_z.z;
        }

        return transform_a.position.y < transform_b.position.y;
    }

    fn tick(self: *@This(), frametime_ms: u16, ECS: ecs.ECS, entity: ecs.EntityId) void {
        const transform = ECS.query(entity, Components.TransformComponent) orelse return;
        if (ECS.query(entity, Components.SpriteComponent)) |comp| {
            var color = rl.WHITE;
            color.a = comp.alpha;

            rl.DrawTexturePro(
                self.tilesheets[comp.tilesheet],
                .{ .x = comp.source.x, .y = comp.source.y, .width = if (comp.flipX) -comp.width else comp.width, .height = if (comp.flipY) -comp.height else comp.height },
                .{ .x = transform.position.x, .y = transform.position.y, .width = comp.width, .height = comp.height },
                .{ .x = comp.width / 2, .y = comp.height / 2 },
                0,
                color,
            );
            return;
        }
        const animation = ECS.query(entity, Components.RenderComponent) orelse return;

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
