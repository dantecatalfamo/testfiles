const std = @import("std");
const testFiles = @import("./test_files.zig");

pub fn main() anyerror!void {
    var args = std.process.args();

    var dir: []const u8 = undefined;
    var files: ?u32 = null;
    var dirs: ?u32 = null;
    var depth: ?u32 = null;
    var size: ?u32 = null;

    _ = args.next();

    dir = args.next() orelse usage();

    while (args.next()) |arg| {
        if (std.mem.eql(u8, arg, "--files")) {
            files = try std.fmt.parseInt(u32, args.next() orelse usage(), 10);
        } else if (std.mem.eql(u8, arg, "--dirs")) {
            dirs = try std.fmt.parseInt(u32, args.next() orelse usage(), 10);
        } else if (std.mem.eql(u8, arg, "--depth")) {
            depth = try std.fmt.parseInt(u32, args.next() orelse usage(), 10);
        } else if (std.mem.eql(u8, arg, "--size")) {
            size = try std.fmt.parseInt(u32, args.next() orelse usage(), 10);
        } else {
            std.log.err("Unrecognized option \"{s}\"", .{ arg });
            usage();
        }
    }
    var thingy = try testFiles.init(dir, files orelse 20, size orelse 4096, depth orelse 3, dirs orelse 10);
    try thingy.run();
}

pub fn usage() noreturn {
    const options =
        \\  --files <number>  # Number of files per directory (default 20)
        \\  --dirs  <number>  # Number of subdirectories per directory (default 5)
        \\  --size  <bytes>   # Size of each file (default 4096)
        \\  --depth <number>  # Depth of file tree (default 3)
        \\
    ;
    const stderr = std.io.getStdErr().writer();
    stderr.print("usage: testfiles <dir> [options]\n", .{}) catch unreachable;
    stderr.print(options, .{}) catch unreachable;
    std.process.exit(1);
}
