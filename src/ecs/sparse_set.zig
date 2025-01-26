const std = @import("std");

pub fn SparseSet(comptime T: type) type {
    return struct {
        sparse: std.ArrayList(?usize), // Maps entity IDs to dense indices
        dense: std.ArrayList(usize), // Stores entity IDs
        components: std.ArrayList(T), // Stores the actual components

        pub fn init(allocator: std.mem.Allocator) SparseSet(T) {
            return SparseSet(T){
                .sparse = std.ArrayList(?usize).init(allocator),
                .dense = std.ArrayList(usize).init(allocator),
                .components = std.ArrayList(T).init(allocator),
            };
        }

        pub fn deinit(self: *SparseSet(T)) void {
            self.sparse.deinit();
            self.dense.deinit();
            self.components.deinit();
        }

        /// Adds or updates a component for a given entity.
        pub fn set(self: *SparseSet(T), entity_id: usize, component: T) !void {
            if (entity_id >= self.sparse.items.len) {
                try self.sparse.resize(entity_id + 1); // Expand sparse array with `null`
                self.sparse.items[entity_id] = null;
            }

            if (self.sparse.items[entity_id] != null) {
                // Update existing component
                const dense_index = self.sparse.items[entity_id].?;
                self.components.items[dense_index] = component;
            } else {
                // Add new component
                try self.dense.append(entity_id);
                try self.components.append(component);
                self.sparse.items[entity_id] = self.dense.items.len - 1;
            }
        }

        /// Gets a component for a given entity.
        pub fn get(self: SparseSet(T), entity_id: usize) ?*T {
            if (entity_id >= self.sparse.items.len or self.sparse.items[entity_id] == null) {
                return null;
            }
            const dense_index = self.sparse.items[entity_id].?;
            return &self.components.items[dense_index];
        }

        /// Removes a component for a given entity.
        pub fn remove(self: *SparseSet(T), entity_id: usize) void {
            if (entity_id >= self.sparse.items.len or self.sparse.items[entity_id] == null) {
                return;
            }
            const dense_index = self.sparse.items[entity_id].?;

            // Swap the dense element with the last element
            const last_dense_index = self.dense.len - 1;
            if (dense_index != last_dense_index) {
                const last_entity_id = self.dense.items[last_dense_index];
                self.dense.items[dense_index] = last_entity_id;
                self.components.items[dense_index] = self.components.items[last_dense_index];
                self.sparse.items[last_entity_id] = dense_index;
            }

            // Remove the last element
            _ = self.dense.pop();
            _ = self.components.pop();
            self.sparse.items[entity_id] = null;
        }
    };
}
