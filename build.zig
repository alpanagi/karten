const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const toml = b.dependency("toml", .{
        .target = target,
        .optimize = optimize,
    });

    const karten = b.addExecutable(.{
        .name = "karten",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
            .imports = &.{
                .{ .name = "toml", .module = toml.module("toml") },
            },
        }),
    });

    b.installArtifact(karten);
}
