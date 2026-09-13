const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const arguments = try init.minimal.args.toSlice(init.arena.allocator());
    if (arguments.len != 2) std.process.fatal(
        "karten takes only a single parameter, the card file",
        .{},
    );
}
