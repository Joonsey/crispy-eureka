const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});
const World = @import("world.zig").World;
const Tile = @import("world.zig").Tile;

const Node = struct {
    x: usize, // X-coordinate in the grid
    y: usize, // Y-coordinate in the grid
    g: f32, // Cost from the start node to this node
    h: f32, // Heuristic cost to the goal node
    parent: ?*Node, // Pointer to the parent node in the path

    // Calculate the total cost (f = g + h)
    pub fn f(self: Node) f32 {
        return self.g + self.h;
    }
};

pub const AStar = struct {
    pub fn find_path(world: *World, start: rl.Vector3, goal: rl.Vector3, allocator: std.mem.Allocator) ![]rl.Vector3 {
        // Convert world positions to grid coordinates
        const start_x: usize = @intFromFloat(start.x);
        const start_y: usize = @intFromFloat(start.z);
        const goal_x: usize = @intFromFloat(goal.x);
        const goal_y: usize = @intFromFloat(goal.z);

        // Open and closed sets
        var open_set = std.ArrayList(*Node).init(allocator);
        defer open_set.deinit();
        var closed_set = std.AutoHashMap(*Node, bool).init(allocator);
        defer closed_set.deinit();

        // Initial node
        var start_node = Node{
            .x = start_x,
            .y = start_y,
            .g = 0,
            .h = heuristic_cost(start_x, start_y, goal_x, goal_y),
            .parent = null,
        };
        try open_set.append(&start_node);

        // Main loop
        while (open_set.items.len > 0) {
            // Get the node with the lowest f score (simplified)
            var current_node = open_set.items[0];
            var current_index: usize = 0;
            var lowest_f = current_node.f();

            // Find the node with the lowest f score
            for (0..open_set.items.len) |index| {
                const node = open_set.items[index];
                const f_score = node.f();
                if (f_score < lowest_f) {
                    lowest_f = f_score;
                    current_node = node;
                    current_index = index;
                }
            }

            // Remove current_node from open_set
            open_set.items[current_index] = open_set.items[open_set.items.len - 1];
            _ = open_set.pop();

            // If we've reached the goal, reconstruct the path
            if (current_node.x == goal_x and current_node.y == goal_y) {
                return try reconstruct_path(current_node, allocator);
            }

            // Add the current node to the closed set
            _ = try closed_set.put(current_node, true);

            // Process neighbors
            const neighbors = try world.get_neighbors(current_node.x, current_node.y, allocator);
            for (neighbors) |neighbor| {
                // Calculate the tentative g score
                const neighbor_tile = neighbor.?;
                if (!neighbor_tile.buildable) continue; // Skip non-buildable tiles
                const movement_cost = get_movement_cost(world, current_node.x, current_node.y, neighbor_tile);
                const tentative_g_score = current_node.g + movement_cost;

                // If the neighbor is in the closed set and the new score is worse, skip it
                if (tentative_g_score >= current_node.g) {
                    continue;
                }

                // If the neighbor is not in the open set, add it
                var neighbor_node = Node{
                    .x = neighbor_tile.x,
                    .y = neighbor_tile.y,
                    .g = tentative_g_score,
                    .h = heuristic_cost(neighbor_tile.x, neighbor_tile.y, goal_x, goal_y),
                    .parent = current_node,
                };
                try open_set.append(&neighbor_node);
            }
        }

        return error.PathNotFound;
    }

    // Heuristic: Manhattan distance
    fn heuristic_cost(x1: usize, y1: usize, x2: usize, y2: usize) f32 {
        return @floatFromInt(@abs(x2 - x1) + @abs(y2 - y1));
    }

    // Calculate movement cost between two tiles
    fn get_movement_cost(world: *World, x: usize, y: usize, neighbor_tile: Tile) f32 {
        const current_tile = world.get_tile(x, y) orelse return 0;
        const height_difference = @abs(current_tile.height - neighbor_tile.height);
        return 1.0 + height_difference; // Add height difference to cost
    }

    // Reconstruct the path from goal to start by following the parent nodes
    fn reconstruct_path(node: ?*Node, allocator: std.mem.Allocator) ![]rl.Vector3 {
        var path = std.ArrayList(rl.Vector3).init(allocator);
        var current_maybe = node;
        while (current_maybe) |current| {
            try path.append(rl.Vector3{
                .x = @floatFromInt(current.x),
                .y = 0,
                .z = @floatFromInt(current.y),
            });
            current_maybe = current.parent;
        }
        // Reverse the path to start from the start node
        var reversed_path = std.ArrayList(rl.Vector3).init(allocator);
        while (path.items.len > 0) {
            try reversed_path.append(path.items[path.items.len - 1]);
            _ = path.pop();
        }
        return reversed_path.items;
    }
};
