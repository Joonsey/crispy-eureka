const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});

const cwd = std.fs.cwd();

const Rules = struct {
    active: bool,
    size: u32,
    tileRectsIds: [][]u32,
    alpha: f32,
    chance: f32,
    breakOnMatch: bool,
    pattern: []i64,
    flipX: bool,
    flipY: bool,
    tileXOffset: i32,
    tileYOffset: i32,
    xModulo: u8,
    yModulo: u8,
};

const Tile = struct {
    px: [2]i32,
    src: [2]f32,
    f: u2,
    d: []i32,
    t: u32,
    a: f32,
};

const AutoRuleGroup = struct {
    name: []const u8,
    active: bool,
    rules: []Rules,
};

const Layer = struct {
    __type: []const u8,
    identifier: []const u8,
    pxOffsetX: i32,
    pxOffsetY: i32,
    autoRuleGroups: ?[]AutoRuleGroup,
};

const LayerInstance = struct {
    __identifier: []const u8,
    __type: []const u8,
    __pxTotalOffsetX: i32,
    __pxTotalOffsetY: i32,
    intGridCsv: []i32,
    levelId: u32,
    autoLayerTiles: []Tile,
    gridTiles: []Tile,
};

const Level = struct {
    uid: u32,
    layerInstances: []LayerInstance,
    worldX: i32,
    worldY: i32,
};

const Tileset = struct {
    identifier: []const u8,
    relPath: ?[]const u8, // This is nullable only because 'internal icons'
    tileGridSize: u8,
};

const Defs = struct {
    layers: []Layer,
    tilesets: []Tileset,
};

pub const Ldtk = struct {
    defs: Defs,
    levels: []Level,

    pub fn init() !@This() {
        const allocator = std.heap.page_allocator;
        const file = try cwd.openFile("level/example.json", .{});
        const buf = try file.readToEndAlloc(allocator, 200000000);
        const parser = try std.json.parseFromSlice(@This(), allocator, buf, .{ .ignore_unknown_fields = true });
        return parser.value;
    }
};

fn doesPatternMatch(
    pattern: []const i64,
    //grid: [][]u32,
    grid: *[8][8]u32,
    x: usize,
    y: usize,
    targetTileId: u32,
) bool {
    // Assuming 3x3 pattern (size 9)
    if (pattern.len != 9) return false;

    // 3x3 grid positions, starting from top-left
    const directions = [_][2]i32{
        .{ -1, -1 }, .{ 0, -1 }, .{ 1, -1 },
        .{ -1, 0 },  .{ 0, 0 },  .{ 1, 0 },
        .{ -1, 1 },  .{ 0, 1 },  .{ 1, 1 },
    };

    for (directions, 0..) |dir, i| {
        const checkX = @as(i32, @intCast(x)) + dir[0];
        const checkY = @as(i32, @intCast(y)) + dir[1];

        // Get the pattern value we're checking against
        const patternValue = pattern[i];

        // Skip if pattern value is 0 (ignored)
        if (patternValue == 0) continue;

        // Handle out of bounds checks
        if (checkX < 0 or checkY < 0 or
            checkX >= grid[0].len or
            checkY >= grid.len)
        {
            // If we're out of bounds, treat as empty space
            return if (patternValue == -1 or patternValue == -1000001) true else false;
        }

        const hasTile = grid[@intCast(checkY)][@intCast(checkX)] == targetTileId;

        switch (patternValue) {
            -1 => if (hasTile) return false, // Must NOT have a wall
            1 => if (!hasTile) return false, // Must have a wall
            1000001 => {}, // Anything is fine here
            -1000001 => if (hasTile) return false, // Must be empty
            0 => {}, // Ignored
            else => return false, // Invalid pattern value
        }
    }

    return true;
}

pub fn applyLdtkRules(
    rules: []const Rules,
    //grid: [][]u32,
    grid: *[8][8]u32,
    targetTileId: u32,
    rng: std.rand.Random,
) void {
    // Process each tile in the grid
    var y: usize = 0;
    while (y < grid.len) : (y += 1) {
        var x: usize = 0;
        while (x < grid[0].len) : (x += 1) {
            // Only process target tiles
            std.log.debug("x: {}, y: {}, old tile: {}", .{ x, y, grid[y][x] });
            if (grid[y][x] != targetTileId) continue;

            // Collect all matching rules first
            var matchingRules = std.ArrayList(*const Rules).init(std.heap.page_allocator);
            defer matchingRules.deinit();

            for (rules) |*rule| {
                if (!rule.active) continue;
                if (doesPatternMatch(rule.pattern, grid, x, y, targetTileId)) {
                    matchingRules.append(rule) catch unreachable;
                }
            }

            // No matching rules? Keep original tile
            if (matchingRules.items.len == 0) continue;

            // Among matching rules, filter by chance
            for (matchingRules.items) |rule| {
                if (rule.chance >= 1.0 or rng.float(f32) <= rule.chance) {
                    // Rule passed chance check - apply it
                    // Select a random tile group from possibilities
                    const tileGroup = rule.tileRectsIds[rng.uintLessThan(usize, rule.tileRectsIds.len)];
                    // Select random tile from the group
                    const newTileId = tileGroup[rng.uintLessThan(usize, tileGroup.len)];

                    // Apply the new tile with any transformations
                    grid[y][x] = newTileId;
                    std.log.debug("x: {}, y: {}, new tile: {}", .{ x, y, newTileId });

                    // Handle flipX/flipY if your tile system supports it
                    // You'll need to implement this based on your tile storage system
                    //applyTileTransforms(grid, x, y, rule.flipX, rule.flipY);

                    // Apply offsets if needed
                    //applyTileOffsets(grid, x, y, rule.tileXOffset, rule.tileYOffset);

                    // Stop if this rule breaks on match
                    if (rule.breakOnMatch) break;
                }
            }
        }
    }
}

fn applyTileTransforms(grid: [][]u32, x: usize, y: usize, flipX: bool, flipY: bool) void {
    // You'll need to implement this based on how your game engine handles tile flipping
    // This might involve:
    // 1. Setting flip bits in the tile ID
    // 2. Creating a separate flip data structure
    // 3. Using your engine's tile transformation system
    _ = grid;
    _ = x;
    _ = y;
    _ = flipX;
    _ = flipY;
}

fn applyTileOffsets(grid: [][]u32, x: usize, y: usize, offsetX: i32, offsetY: i32) void {
    // Implement based on your tile system
    // This might involve:
    // 1. Adjusting the tile's rendering position
    // 2. Modifying the actual grid position
    // 3. Storing offset data separately
    _ = grid;
    _ = x;
    _ = y;
    _ = offsetX;
    _ = offsetY;
}

pub fn draw_tile(tile: Tile, tilemap: rl.Texture, level: Level, offsetx: i32, offsety: i32) void {
    var color = rl.WHITE;
    color.a = @intFromFloat(tile.a * 255);

    const width: f32 = if (tile.f == 1 or tile.f == 3) -16 else 16;
    const height: f32 = if (tile.f == 2 or tile.f == 3) -16 else 16;
    rl.DrawTexturePro(
        tilemap,
        .{ .x = @floatFromInt(tile.src[0]), .y = @floatFromInt(tile.src[1]), .width = width, .height = height },
        .{ .x = @floatFromInt(tile.px[0] + level.worldX + offsetx), .y = @floatFromInt(tile.px[1] + level.worldY + offsety), .width = 16, .height = 16 },
        rl.Vector2Zero(),
        0,
        color,
    );
}
