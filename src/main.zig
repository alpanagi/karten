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

    if (card_file.card.len == 0)
        std.process.fatal("Card file is empty: {s}", .{file_path});

    const random_source = std.Random.IoSource{ .io = init.io };
    const random = random_source.interface();

    var stdout_file_writer = std.Io.File.stdout().writer(init.io, &.{});
    const stdout = &stdout_file_writer.interface;

    var stdin_buffer: [4096]u8 = undefined;
    var stdin_file_reader = std.Io.File.stdin().reader(init.io, &stdin_buffer);
    const stdin = &stdin_file_reader.interface;

    try stdout.print("Card count: {d}\n", .{card_file.card.len});

    while (true) {
        const card_index = random.uintLessThan(usize, card_file.card.len);
        const card = card_file.card[card_index];

        try stdout.print("\n{s}\n", .{card.question});
        _ = try stdin.takeDelimiter('\n');
    }
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
