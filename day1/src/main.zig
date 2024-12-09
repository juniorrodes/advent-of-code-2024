const std = @import("std");

const Locations = struct {
    left: []u32,
    right: []u32,
    number_of_locations: usize,
};

const SimilarityScore = struct {
    frequency: u16,
    occurrence: u16,
};

pub fn main() !void {
    const allocator = std.heap.page_allocator;

    var args = std.process.args();
    defer args.deinit();
    _ = args.next();

    const file_name = args.next();
    if (file_name == null) {
        std.log.err("expected 1 argument received 0", .{});
    }

    const file = try std.fs.cwd().openFile(file_name.?, .{});
    const metadata = try file.metadata();
    const file_content = try file.readToEndAlloc(allocator, metadata.size());
    const file_content_trimmed = std.mem.trimRight(u8, file_content, "\n");
    defer allocator.free(file_content);

    const locations = try parseInput(allocator, file_content_trimmed);
    defer {
        allocator.free(locations.left);
        allocator.free(locations.right);
    }
    std.mem.sort(u32, locations.left, {}, comptime std.sort.asc(u32));
    std.mem.sort(u32, locations.right, {}, comptime std.sort.asc(u32));
    var sum: u32 = 0;
    for (0..locations.number_of_locations) |i| {
        sum = sum + calcuteDif(locations.left[i], locations.right[i]);
    }
    std.log.info("Total dif: {d}", .{sum});

    var ids_map = std.AutoHashMap(u32, SimilarityScore).init(allocator);
    defer ids_map.deinit();

    for (0..locations.number_of_locations) |i| {
        const key = locations.left[i];
        if (ids_map.contains(key)) {
            var location = ids_map.getPtr(key);
            location.?.frequency += 1;
            continue;
        }

        try ids_map.put(key, .{ .frequency = 1, .occurrence = 0 });
    }

    for (0..locations.number_of_locations) |i| {
        const key = locations.right[i];
        var score = ids_map.getPtr(key) orelse continue;
        score.occurrence += 1;
    }

    var keys_iter = ids_map.keyIterator();

    sum = 0;

    while (keys_iter.next()) |key| {
        const value = ids_map.get(key.*).?;
        sum += value.frequency * value.occurrence * key.*;
    }

    std.log.info("The similarity score is: {d}", .{sum});
}

fn calcuteDif(left: u32, right: u32) u32 {
    return @max(left, right) - @min(left, right);
}

fn parseInput(allocator: std.mem.Allocator, buffer: []const u8) !Locations {
    var left_list = std.ArrayList(u32).init(allocator);
    var right_list = std.ArrayList(u32).init(allocator);

    defer {
        left_list.deinit();
        right_list.deinit();
    }

    var lines = std.mem.splitSequence(u8, buffer, "\n");
    while (lines.next()) |line| {
        var values_iter = std.mem.splitSequence(u8, line, " ");
        try left_list.append(try std.fmt.parseInt(u32, values_iter.next().?, 10));
        _ = values_iter.next();
        _ = values_iter.next();
        try right_list.append(try std.fmt.parseInt(u32, values_iter.next().?, 10));
    }

    return .{
        .number_of_locations = left_list.items.len,
        .left = try left_list.toOwnedSlice(),
        .right = try right_list.toOwnedSlice(),
    };
}

test "simple test" {
    var list = std.ArrayList(i32).init(std.testing.allocator);
    defer list.deinit(); // try commenting this out and see if zig detects the memory leak!
    try list.append(42);
    try std.testing.expectEqual(@as(i32, 42), list.pop());
}
