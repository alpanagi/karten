const std = @import("std");
const toml = @import("toml");

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    const arguments = try init.minimal.args.toSlice(init.arena.allocator());
    if (arguments.len != 2)
        std.process.fatal("karten takes only a single parameter, the card file", .{});

    const cwd = std.Io.Dir.cwd();
    const file_path = arguments[1];
    const text = cwd.readFileAlloc(init.io, file_path, allocator, .unlimited) catch
        std.process.fatal("Could not read file: {s}", .{file_path});
    defer allocator.free(text);

    var card_file = toml.parseAlloc(allocator, CardFile, text) catch
        std.process.fatal("Could not parse toml file: {s}", .{file_path});
    defer card_file.deinit(allocator);
}

const CardFile = struct {
    card: []Card,

    pub fn deinit(self: *CardFile, allocator: std.mem.Allocator) void {
        for (self.card) |*card| card.deinit(allocator);
        allocator.free(self.card);
    }
};

const Card = struct {
    question: []const u8,
    answer: []const u8,

    pub fn deinit(self: *Card, allocator: std.mem.Allocator) void {
        allocator.free(self.question);
        allocator.free(self.answer);
    }
};
