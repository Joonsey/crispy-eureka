const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});
const AnimationState = @import("../render/main.zig").AnimationState;

pub const TransformComponent = struct {
    position: rl.Vector2,
};

pub const RenderComponent = struct {
    animator: usize,
    state: AnimationState = .{ .HURT = .side },
    frame: usize = 0,
    frame_time: u16 = 0,
};

pub const PhysicsComponent = struct {
    velocity: rl.Vector2,
};

pub const DirectionComponent = enum(u2) {
    LEFT,
    RIGHT,
    UP,
    DOWN,
};

pub const TagComponent = struct {};

pub const ComponentsType = enum {
    render,
    transform,
    physics,
    tag,
    direction,
};

pub const Component = union(ComponentsType) {
    render: RenderComponent,
    transform: TransformComponent,
    physics: PhysicsComponent,
    tag: TagComponent,
    direction: DirectionComponent,
};
