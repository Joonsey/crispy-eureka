const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});

pub const UP: rl.Vector3 = .{ .x = 0, .y = 1, .z = 0 };
pub fn transformBoundingBox(
    bbox: rl.BoundingBox,
    position: rl.Vector3,
    rotation: f32,
) rl.BoundingBox {
    const corners = [_]rl.Vector3{
        bbox.min,
        rl.Vector3{ .x = bbox.min.x, .y = bbox.min.y, .z = bbox.max.z },
        rl.Vector3{ .x = bbox.min.x, .y = bbox.max.y, .z = bbox.min.z },
        rl.Vector3{ .x = bbox.min.x, .y = bbox.max.y, .z = bbox.max.z },
        rl.Vector3{ .x = bbox.max.x, .y = bbox.min.y, .z = bbox.min.z },
        rl.Vector3{ .x = bbox.max.x, .y = bbox.min.y, .z = bbox.max.z },
        rl.Vector3{ .x = bbox.max.x, .y = bbox.max.y, .z = bbox.min.z },
        bbox.max,
    };

    var transform = rl.MatrixIdentity();
    transform = rl.MatrixMultiply(transform, rl.MatrixRotateY(rotation * rl.DEG2RAD)); // Apply rotation
    transform = rl.MatrixMultiply(transform, rl.MatrixTranslate(position.x, position.y, position.z)); // Apply position offset

    var transformed_corners = [_]rl.Vector3{ .{}, .{}, .{}, .{}, .{}, .{}, .{}, .{} };
    for (0..8) |i| {
        transformed_corners[i] = rl.Vector3Transform(corners[i], transform);
    }

    var new_min = transformed_corners[0];
    var new_max = transformed_corners[0];
    for (1..8) |i| {
        new_min.x = if (transformed_corners[i].x < new_min.x) transformed_corners[i].x else new_min.x;
        new_min.y = if (transformed_corners[i].y < new_min.y) transformed_corners[i].y else new_min.y;
        new_min.z = if (transformed_corners[i].z < new_min.z) transformed_corners[i].z else new_min.z;

        new_max.x = if (transformed_corners[i].x > new_max.x) transformed_corners[i].x else new_max.x;
        new_max.y = if (transformed_corners[i].y > new_max.y) transformed_corners[i].y else new_max.y;
        new_max.z = if (transformed_corners[i].z > new_max.z) transformed_corners[i].z else new_max.z;
    }

    return .{ .min = new_min, .max = new_max };
}

pub fn GetRelativeMousePosition(render_width: f32, screen_width: f32, render_height: f32, screen_height: f32) rl.Vector2 {
    const mouse_position = rl.GetMousePosition();
    return rl.Vector2Multiply(
        mouse_position,
        .{ .x = render_width / screen_width, .y = render_height / screen_height },
    );
}

pub fn GetNormalizedMousePosition(screen_width: f32, screen_height: f32) rl.Vector2 {
    const mouse_position = rl.GetMousePosition();
    return .{ .x = mouse_position.x / screen_width, .y = mouse_position.y / screen_height };
}

pub fn DebugDrawModel(model: rl.Model, position: rl.Vector3, rotation: f32, camera: rl.Camera) void {
    const ray = rl.GetMouseRay(rl.GetMousePosition(), camera);
    const model_bb = rl.GetModelBoundingBox(model);
    const model_tb = transformBoundingBox(model_bb, position, rotation);

    rl.DrawBoundingBox(model_tb, rl.RED);

    for (0..@intCast(model.meshCount)) |i| {
        const mesh = model.meshes[i];
        const bb = rl.GetMeshBoundingBox(mesh);
        const tb = transformBoundingBox(bb, position, rotation);

        const collision = rl.GetRayCollisionBox(ray, tb);
        if (collision.hit) {
            rl.DrawBoundingBox(tb, rl.GREEN);
        } else {
            rl.DrawBoundingBox(tb, rl.BLUE);
        }
    }
}
