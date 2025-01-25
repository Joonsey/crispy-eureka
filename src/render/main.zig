pub const System = @import("system.zig").System;
const sprites = @import("sprites.zig");
const animator = @import("animator.zig");
const tatl = @import("tatl.zig");

pub const import = tatl.import;
pub const Animator = animator.Animator;

// hopefully this is more generic in the future, not too bad though
pub const AnimatorState = animator.AnimationState;

pub const Sprite = sprites.Sprite;
