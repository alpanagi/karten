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

    const timestamp = std.Io.Clock.real.now(init.io).toSeconds();

    var cards = std.ArrayList(*Card).empty;
    for (card_file.card) |*card| {
        const last_success = card.last_success orelse 0;
        const success_count = card.success_count orelse 0;
        const next_timestamp: i64 = last_success + 60 * 60 * 8 * success_count;
        if (next_timestamp > timestamp) continue;

        try cards.append(allocator, card);
    }
    defer cards.deinit(allocator);

    const random_source = std.Random.IoSource{ .io = init.io };
    const random = random_source.interface();

    var stdout_file_writer = std.Io.File.stdout().writer(init.io, &.{});
    const stdout = &stdout_file_writer.interface;

    var stdin_buffer: [4096]u8 = undefined;
    var stdin_file_reader = std.Io.File.stdin().reader(init.io, &stdin_buffer);
    const stdin = &stdin_file_reader.interface;

    try stdout.print("Card count: {d}\n\n", .{card_file.card.len});
    if (cards.items.len == 0) {
        try stdout.print("All cards up to date.\n", .{});
        return;
    }

    while (true) {
        const card_index = random.uintLessThan(usize, cards.items.len);
        const card = cards.items[card_index];

        try stdout.print("{s} ({d}/{d})", .{
            card.question,
            cards.items.len,
            card_file.card.len,
        });

        var response = try stdin.takeDelimiter('\n') orelse break;
        try stdout.print("{s}\n", .{card.answer});
        response = try stdin.takeDelimiter('\n') orelse break;

        if (std.mem.eql(u8, "y", response)) {
            card.success_count = (card.success_count orelse 0) + 1;
            card.last_success = std.Io.Clock.real.now(init.io).toSeconds();

            _ = cards.swapRemove(card_index);

            try stdout.print("\n", .{});
            if (cards.items.len == 0) {
                try stdout.print("All cards finished\n", .{});
                break;
            }
        } else {
            card.success_count = 0;
            card.last_success = 0;
        }
    }

    try stdout.print("\n", .{});

    save_cards(init.io, file_path, &card_file.card) catch
        std.log.err("Failed to update card file: {s}", .{file_path});
}

fn save_cards(io: std.Io, file_path: []const u8, cards: *[]Card) !void {
    const cwd = std.Io.Dir.cwd();
    var file = try cwd.createFile(io, file_path, .{});
    defer file.close(io);

    var buffer: [4096]u8 = undefined;
    var file_writer = file.writer(io, &buffer);
    const writer = &file_writer.interface;

    for (cards.*) |*card| {
        try writer.print(
            "[[card]]\n" ++
                "question = \"{s}\"\n" ++
                "answer = \"{s}\"\n" ++
                "success_count = {d}\n" ++
                "last_success = {d}\n" ++
                "\n",
            .{
                card.question,
                card.answer,
                card.success_count orelse 0,
                card.last_success orelse 0,
            },
        );
    }

    try writer.flush();
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
    success_count: ?u32,
    last_success: ?i64,

    pub fn deinit(self: *Card, allocator: std.mem.Allocator) void {
        allocator.free(self.question);
        allocator.free(self.answer);
    }
};
