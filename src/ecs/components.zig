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
    state: AnimationState = .{ .HURT = .left },
    frame: usize = 0,
    frame_time: u16 = 0,
};

pub const ZComponent = struct {
    z: i16,
};

pub const SpriteComponent = struct {
    tilesheet: usize,
    width: f32,
    height: f32,
    flipX: bool = false,
    flipY: bool = false,
    rotation: f32 = 0,
    alpha: u8 = 255,
    source: rl.Vector2 = rl.Vector2Zero(),
};

pub const PhysicsComponent = struct {
    velocity: rl.Vector2,
};

pub const BoxColliderComponent = struct {
    offset: rl.Vector2,
    dimensions: rl.Vector2,
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
    sprite,
    z,
    box_collider,
};

pub const Component = union(ComponentsType) {
    render: RenderComponent,
    transform: TransformComponent,
    physics: PhysicsComponent,
    tag: TagComponent,
    direction: DirectionComponent,
    sprite: SpriteComponent,
    z: ZComponent,
    box_collider: BoxColliderComponent,
};
