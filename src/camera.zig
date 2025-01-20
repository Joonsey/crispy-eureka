const std = @import("std");
const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});

const pan_speed: f32 = 10.0; // Speed of camera movement

pub const CameraController = struct {
    camera: rl.Camera3D,

    pub fn update(self: *CameraController, delta_time: f32) void {
        const move_speed = pan_speed * delta_time;

        if (rl.IsKeyDown(rl.KEY_W)) {
            self.camera.position.z -= move_speed;
            self.camera.target.z -= move_speed;
        }
        if (rl.IsKeyDown(rl.KEY_S)) {
            self.camera.position.z += move_speed;
            self.camera.target.z += move_speed;
        }
        if (rl.IsKeyDown(rl.KEY_A)) {
            self.camera.position.x -= move_speed;
            self.camera.target.x -= move_speed;
        }
        if (rl.IsKeyDown(rl.KEY_D)) {
            self.camera.position.x += move_speed;
            self.camera.target.x += move_speed;
        }
    }
};
