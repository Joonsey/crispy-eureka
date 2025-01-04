const std = @import("std");
const math = @import("std").math;
const rl = @cImport({
    @cInclude("raylib.h");
    @cInclude("raymath.h");
});

pub const ParticleSystem = struct {
    const ParticleType = union(enum) {
        Spark: Spark,
    };

    particles: std.ArrayList(ParticleType),
    dead_particle_indicies: std.ArrayList(usize),

    pub fn init(allocator: std.mem.Allocator) !ParticleSystem {
        return .{
            .particles = std.ArrayList(ParticleType).init(allocator),
            .dead_particle_indicies = std.ArrayList(usize).init(allocator),
        };
    }

    pub fn draw(self: @This()) void {
        for (self.particles.items) |p| {
            switch (p) {
                .Spark => p.Spark.draw(),
            }
        }
    }

    pub fn update(self: *ParticleSystem, dt: f32) void {
        var i: usize = 0;
        while (i < self.particles.items.len) {
            const particle = &self.particles.items[i];

            switch (particle.*) {
                .Spark => particle.Spark.update(dt),
            }

            switch (particle.*) {
                .Spark => |spark| {
                    if (spark.base.lifetime == 0) {
                        _ = self.particles.orderedRemove(i);
                        continue;
                    }
                },
            }

            i += 1;
        }
    }

    pub fn register(self: *@This(), particle: ParticleType) void {
        self.particles.append(particle) catch |err| std.debug.print("something went wrong {}\n", .{err});
    }
};

const Particle = struct {
    lifetime: f32,

    pub fn init(lifetime: f32) Particle {
        return .{ .lifetime = lifetime };
    }

    pub fn update(self: *Particle, dt: f32) void {
        self.lifetime = @max(0, self.lifetime - dt);
    }
};

pub const Spark = struct {
    base: Particle,
    pos: rl.Vector2,
    angle: f32,
    scale: f32,
    color: rl.Color,
    force: f32,

    pub fn init(pos: rl.Vector2, angle: f32, color: rl.Color, scale: f32, force: f32, lifetime: f32) Spark {
        return .{
            .base = Particle.init(lifetime),
            .pos = pos,
            .angle = angle,
            .scale = scale,
            .color = color,
            .force = force,
        };
    }

    fn calculateMovement(self: *const Spark, dt: f32) rl.Vector2 {
        return .{
            .x = math.cos(self.angle) * self.base.lifetime * dt * self.force,
            .y = math.sin(self.angle) * self.base.lifetime * dt * self.force,
        };
    }

    pub fn update(self: *Spark, dt: f32) void {
        self.base.update(dt);

        const movement = self.calculateMovement(dt * 20);
        self.pos.x += movement.x;
        self.pos.y += movement.y;

        self.base.lifetime = @max(0, self.base.lifetime - 2 * dt);
    }

    pub fn draw(self: *const Spark) void {
        var points: [4]rl.Vector2 = undefined;

        points[0] = rl.Vector2{
            .x = self.pos.x + math.cos(self.angle) * self.base.lifetime * self.scale,
            .y = self.pos.y + math.sin(self.angle) * self.base.lifetime * self.scale,
        };
        points[1] = rl.Vector2{
            .x = self.pos.x + math.cos(self.angle + math.pi / 2.0) * self.base.lifetime * self.scale * 0.3,
            .y = self.pos.y + math.sin(self.angle + math.pi / 2.0) * self.base.lifetime * self.scale * 0.3,
        };
        points[2] = rl.Vector2{
            .x = self.pos.x - math.cos(self.angle) * self.base.lifetime * self.scale * 3.5,
            .y = self.pos.y - math.sin(self.angle) * self.base.lifetime * self.scale * 3.5,
        };
        points[3] = rl.Vector2{
            .x = self.pos.x + math.cos(self.angle - math.pi / 2.0) * self.base.lifetime * self.scale * 0.3,
            .y = self.pos.y - math.sin(self.angle + math.pi / 2.0) * self.base.lifetime * self.scale * 0.3,
        };

        // TODO: fill the polygon

        rl.DrawLineV(points[0], points[1], self.color);
        rl.DrawLineV(points[1], points[2], self.color);
        rl.DrawLineV(points[2], points[3], self.color);
        rl.DrawLineV(points[3], points[0], self.color);
    }
};
