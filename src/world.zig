const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});

pub const Tile = struct {
    tile_type: u8,
    buildable: bool,
    height: f32,
    x: usize,
    y: usize,
};

pub const World = struct {
    map: std.ArrayList(Tile),
    width: usize,
    height: usize,

    pub fn generate_sample_map(allocator: std.mem.Allocator) World {
        var map = std.ArrayList(Tile).init(allocator);

        for (0..25) |i| {
            map.append(.{ .tile_type = 0, .buildable = true, .height = 0.0, .x = @divTrunc(i, 5), .y = @mod(i, 5) }) catch unreachable;
        }

        return .{
            .map = map,
            .width = 5, // Example 5x5 map
            .height = 5,
        };
    }

    pub fn get_tile(self: *World, x: usize, y: usize) ?Tile {
        if (x >= self.width or y >= self.height) {
            return null;
        }
        return self.map.items[y * self.width + x];
    }

    pub fn get_neighbors(self: *World, x: usize, y: usize, allocator: std.mem.Allocator) ![]?Tile {
        var neighbors = std.ArrayList(?Tile).init(allocator);

        const directions = [_]i32{ -1, 1, 0, 0 }; // Left, Right, Up, Down
        for (0..4) |i| {
            const nx: usize = @intCast(@as(i32, @intCast(x)) + directions[i]);
            const ny: usize = @intCast(@as(i32, @intCast(y)) + directions[3 - i]);

            if (nx >= 0 and ny >= 0 and nx < self.width and ny < self.height) {
                const maybe_neighbor = self.get_tile(nx, ny);
                if (maybe_neighbor) |neighbor| {
                    try neighbors.append(neighbor);
                }
            }
        }

        return neighbors.items;
    }

    // Rendering the world map as cubes
    pub fn draw(self: *World) void {
        const size: f32 = 4.0;
        for (0..self.height) |row| {
            for (0..self.width) |col| {
                const tile = self.map.items[row * self.width + col];
                const position = rl.Vector3{
                    .x = @as(f32, @floatFromInt(col)) * size,
                    .y = tile.height,
                    .z = @as(f32, @floatFromInt(row)) * size,
                };
                const color = switch (tile.tile_type) {
                    0 => rl.GREEN, // Grass
                    1 => rl.BROWN, // Dirt
                    2 => rl.BLUE, // Water
                    else => rl.GRAY, // Default
                };
                rl.DrawCube(position, size, 1.0, size, color);
            }
        }
    }
};
