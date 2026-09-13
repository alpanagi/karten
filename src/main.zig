const std = @import("std");

pub fn main(init: std.process.Init) !void {
    const arguments = try init.minimal.args.toSlice(init.arena.allocator());
    for (arguments) |argument| std.debug.print("{s}\n", .{argument});
}
