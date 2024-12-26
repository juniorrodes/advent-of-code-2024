const std = @import("std");

pub fn main() !void {
    var arena = std.heap.ArenaAllocator.init(std.heap.page_allocator);
    defer arena.deinit();

    var args = std.process.args();
    _ = args.next();

    const file_name = args.next() orelse {
        std.log.err("Expected argument with file name, and received nothing", .{});
        std.process.exit(1);
    };

    const file = try std.fs.cwd().openFile(file_name, .{ .mode = .read_only });
    const metadata = try file.metadata();

    const buffer = try file.readToEndAlloc(arena.allocator(), metadata.size());
    const buffer_trimed = std.mem.trimRight(u8, buffer, "\n");
    var problem = try parseFile(arena.allocator(), buffer_trimed);

    const stdout_file = std.io.getStdOut().writer();
    var bw = std.io.bufferedWriter(stdout_file);
    const stdout = bw.writer();

    //for (problem.items) |line| {
    //    for (line) |value| {
    //        try stdout.print("{d}\t", .{value});
    //    }
    //    try stdout.print("\n", .{});
    //}
    //try bw.flush(); // don't forget to flush!
    const solution = solve(try problem.toOwnedSlice());
    try stdout.print("The number of safe reports: {d}\n", .{solution});
    try bw.flush();
}

fn solve(problem: [][]u32) u32 {
    var sum: u32 = 0;
    for (problem) |slice| {
        var dampener: u32 = 0;
        var safe = isSafe(slice, slice[0] < slice[1], &dampener);
        if (!safe and dampener <= 1) {
            safe = isSafe(slice[1..], slice[1] < slice[2], &dampener);
        }
        if (safe) {
            sum += 1;
        } else {
            std.log.info("{any}", .{slice});
        }
    }

    return sum;
}

fn isSafe(slice: []u32, is_increasing: bool, dampener: *u32) bool {
    if (if (is_increasing) slice[0] > slice[1] else slice[0] < slice[1]) {
        if (slice.len == 2 and dampener.* < 1) {
            return true;
        }
        if (dampener.* < 1) {
            if (if (is_increasing) slice[0] > slice[2] else slice[0] < slice[2]) {
                return false;
            }
            const diference = calculateDiference(slice[0], slice[2]);
            if (diference > 3 or diference < 1) {
                return false;
            }
            if (slice.len <= 3) {
                return true;
            }
            dampener.* += 1;

            return isSafe(slice[2..], is_increasing, dampener);
        }
        dampener.* += 1;
        return false;
    }
    var diference = calculateDiference(slice[0], slice[1]);

    if (diference > 3 or diference < 1) {
        if (slice.len == 2 and dampener.* < 1) {
            return true;
        }
        if (dampener.* < 1) {
            if (if (is_increasing) slice[0] > slice[2] else slice[0] < slice[2]) {
                return false;
            }
            diference = calculateDiference(slice[0], slice[2]);
            if (diference > 3 or diference < 1) {
                return false;
            }
            if (slice.len <= 3) {
                return true;
            }
            dampener.* += 1;

            return isSafe(slice[2..], is_increasing, dampener);
        }
        dampener.* += 1;
        return false;
    }

    if (slice.len == 2) {
        return true;
    }

    const is_safe = isSafe(slice[1..], is_increasing, dampener);
    if (!is_safe and dampener.* <= 1) {
        if (if (is_increasing) slice[0] > slice[2] else slice[0] < slice[2]) {
            return false;
        }
        diference = calculateDiference(slice[0], slice[2]);
        if (diference > 3 or diference < 1) {
            return false;
        }
        if (slice.len <= 3) {
            return true;
        }
        dampener.* += 1;

        return isSafe(slice[2..], is_increasing, dampener);
    }

    return is_safe;
}

fn calculateDiference(lhs: u32, rhs: u32) u32 {
    return @max(lhs, rhs) - @min(lhs, rhs);
}

fn parseFile(allocator: std.mem.Allocator, buffer: []const u8) !std.ArrayList([]u32) {
    var list_of_slices = std.ArrayList([]u32).init(allocator);

    var lines = std.mem.splitScalar(u8, buffer, '\n');
    while (lines.next()) |line| {
        var values = std.mem.splitScalar(u8, line, ' ');
        var list = std.ArrayList(u32).init(allocator);

        while (values.next()) |value| {
            try list.append(try std.fmt.parseInt(u32, value, 10));
        }

        try list_of_slices.append(try list.toOwnedSlice());
    }

    return list_of_slices;
}
