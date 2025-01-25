const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});

const Animator = @import("animator.zig").Animator;
const AnimationState = @import("animator.zig").AnimationState;
const tatl = @import("tatl.zig");

const ENTITY_COUNT = 100000;

const RenderComponent = struct {
    animator: usize,
    state: AnimationState = .{ .IDLE = .up },
    frame: usize = 0,
    frame_time: u16 = 0,
};

fn draw(position: rl.Vector2, texture: rl.Texture) void {
    rl.DrawTextureV(texture, position, rl.WHITE);
}

pub const System = struct {
    renders: [ENTITY_COUNT]?RenderComponent,
    animators: []Animator,
    count: usize = 0,

    pub fn init() System {
        var animators = std.ArrayList(Animator).init(page_allocator);

        for ([_][]const u8{ "idle.aseprite", "test.aseprite" }) |path| {
            const file = cwd.openFile(path, .{}) catch std.debug.panic("erronous path: {s}", .{path});
            const aseprite = tatl.import(page_allocator, file.reader()) catch std.debug.panic("error parsing aseprite file: {s}", .{path});
            const anim = Animator.load(aseprite) catch std.debug.panic("error building animator : {s}", .{path});
            animators.append(anim) catch unreachable;
        }

        return .{ .animators = animators.toOwnedSlice() catch unreachable, .count = 0, .renders = [_]?RenderComponent{null} ** ENTITY_COUNT };
    }

    pub fn register_entity(self: *@This(), id: usize, animator: usize) void {
        self.renders[id] = RenderComponent{
            .animator = animator,
            .state = .{ .IDLE = .up },
        };
        self.count += 1;
    }

    pub fn tick(self: *@This(), frametime_ms: u16) void {
        var temp_count = self.count;
        for (0..ENTITY_COUNT) |i| {
            if (temp_count == 0) break;

            if (self.renders[i] == null) continue;
            temp_count -= 1;
            const comp = &self.renders[i].?;

            const animator = self.animators[comp.animator];
            const frames = animator.get_frames(comp.state);

            const current_frame = frames[comp.frame];
            const duration = current_frame.duration;

            comp.frame_time += frametime_ms;
            if (duration <= comp.frame_time) {
                comp.frame = (1 + comp.frame) % frames.len;
                comp.frame_time = 0;
            }
            // QUERY ECS FOR POSITION / TRANSFORM
            const position: rl.Vector2 = .{ .x = 200, .y = 150 };

            const midpoint: rl.Vector2 = rl.Vector2Scale(animator.canvas_size, 0.5);
            const texture = current_frame.texture_cels[animator.get_texture("DEFAULT") orelse continue];
            draw(.{ .x = position.x + @as(f32, @floatFromInt(texture.x)) - midpoint.x, .y = position.y + @as(f32, @floatFromInt(texture.y)) - midpoint.y }, texture.texture);
        }
    }

    pub fn query(self: @This(), id: usize) ?RenderComponent {
        return self.renders[id];
    }
};

const cwd = std.fs.cwd();
const page_allocator = std.heap.page_allocator;
