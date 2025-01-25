const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});
const tatl = @import("tatl.zig");

const AnimationTexture = struct {
    x: i16,
    y: i16,
    texture: rl.Texture,
};

const AnimationFrame = struct {
    texture_cels: []AnimationTexture,
    duration: u16,
};
const TextureMap = std.StringHashMap(usize);

const Direction = enum {
    side,
    down,
    up,
};

const AnimationDirection = enum(u16) {
    HURT,
    IDLE,
};

pub const AnimationState = union(AnimationDirection) {
    HURT: Direction,
    IDLE: Direction,
};

const cwd = std.fs.cwd();
const page_allocator = std.heap.page_allocator;

fn img_cel_to_raylib_texture(cel: tatl.ImageCel) rl.Texture {
    const img = rl.Image{
        .data = @ptrCast(cel.pixels.ptr),
        .width = @intCast(cel.width),
        .height = @intCast(cel.height),
        .mipmaps = 1,
        .format = rl.PIXELFORMAT_UNCOMPRESSED_R8G8B8A8,
    };
    return rl.LoadTextureFromImage(img);
}

const Value = struct {
    from: usize,
    to: usize,
};

fn make_tag_map(aseprite: tatl.AsepriteImport) !std.AutoHashMap(AnimationState, Value) {
    var map = std.AutoHashMap(
        AnimationState,
        Value,
    ).init(page_allocator);

    var big_tag: ?tatl.Tag = null;
    var big_key: ?AnimationDirection = null;
    for (0..aseprite.tags.len) |i| {
        const tag = aseprite.tags[i];
        if (big_tag) |big| {
            if (tag.from >= big.to) big_tag = null;
        }
        if (std.meta.stringToEnum(AnimationDirection, tag.name)) |big| {
            big_tag = tag;
            big_key = big;
        }

        if (big_tag == null) continue;
        if (std.meta.stringToEnum(Direction, tag.name)) |dir| {
            if (big_key) |key| {
                const value: Value = .{ .from = tag.from, .to = tag.to };
                try switch (key) {
                    .HURT => map.put(.{ .HURT = dir }, value),
                    .IDLE => map.put(.{ .IDLE = dir }, value),
                };
            }
        }
    }
    return map;
}

pub const Animator = struct {
    aseprite: tatl.AsepriteImport,
    frame_count: usize = 0,
    texture_map: TextureMap,
    timer: u16 = 0,
    animation_frames: []AnimationFrame = undefined,
    tag_map: std.AutoHashMap(AnimationState, Value),

    pub fn load(path: []const u8) !Animator {
        const file = try cwd.openFile(path, .{});
        const ase = try tatl.import(page_allocator, file.reader());
        var anim: Animator = .{ .aseprite = ase, .texture_map = TextureMap.init(page_allocator), .tag_map = try make_tag_map(ase) };
        try anim.init_texture_map(page_allocator);

        return anim;
    }

    fn get_frame(self: @This(), key: AnimationState) AnimationFrame {
        const tag = self.tag_map.get(key) orelse std.debug.panic("animation missing! {}", .{key});
        const frame = tag.from + (self.frame_count % (tag.to + 1 - tag.from));
        return self.animation_frames[frame];
    }

    pub fn set_tag(self: *@This(), tag_name: []const u8) !void {
        _ = self.texture_map.get(tag_name) orelse return error.InvalidTagName;
        self.current_tag_key = tag_name;

        self.frame_count = 0;
    }

    pub fn get_texture(self: @This(), name: []const u8, key: AnimationState) !AnimationTexture {
        const layer = self.texture_map.get(name) orelse self.texture_map.get("DEFAULT").?;

        return self.get_frame(key).texture_cels[layer];
    }

    pub fn update(self: *@This(), dt: u16) !void {
        const duration = self.animation_frames[self.frame_count % self.animation_frames.len].duration;
        self.timer += dt;
        if (self.timer >= duration) {
            self.timer = 0;
            self.frame_count += 1;
        }
    }

    fn init_texture_map(self: *@This(), allocator: std.mem.Allocator) !void {
        var textures = try std.ArrayList(AnimationTexture).initCapacity(allocator, self.aseprite.layers.len);
        var animation_frames = try std.ArrayList(AnimationFrame).initCapacity(allocator, self.aseprite.frames.len);
        try animation_frames.resize(self.aseprite.frames.len);

        for (0..self.aseprite.frames.len) |i| {
            try textures.resize(self.aseprite.layers.len);
            const frame = self.aseprite.frames[i];
            for (frame.cels) |cel| {
                textures.items[cel.layer] = switch (cel.data) {
                    .raw_image, .compressed_image => |img| .{ .texture = img_cel_to_raylib_texture(img), .x = cel.x, .y = cel.y },
                    else => undefined,
                };
            }
            animation_frames.items[i] = .{ .duration = frame.duration, .texture_cels = try textures.toOwnedSlice() };
        }

        self.animation_frames = try animation_frames.toOwnedSlice();

        for (0..self.aseprite.layers.len) |i| {
            const layer = self.aseprite.layers[i];
            try self.texture_map.put(layer.name, i);
        }
    }
};
