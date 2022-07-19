const std = @import("std");

const Self = @This();

top_dir: []const u8,
files_per_dir: u32,
file_size: u32,
dir_depth: u32,
dirs_per_dir: u32,
rng: std.rand.DefaultPrng,

pub fn init(top_dir: []const u8, files_per_dir: u32, file_size: u32, dir_depth: u32, dirs_per_dir: u32) !Self {

    return Self{
        .top_dir = top_dir,
        .files_per_dir = files_per_dir,
        .file_size = file_size,
        .dir_depth = dir_depth,
        .dirs_per_dir = dirs_per_dir,
        .rng = std.rand.DefaultPrng.init(@intCast(u64, std.time.timestamp())),
    };
}

pub fn run(self: *Self) !void {
    std.fs.cwd().makeDir(self.top_dir) catch |err| {
        switch (err) {
            error.PathAlreadyExists => {
                std.log.err("Directory \"{s}\" already exists", .{ self.top_dir });
                std.process.exit(1);
            },
            else => return err,
        }
    };
    var dir = try std.fs.cwd().openDir(self.top_dir, .{});
    defer dir.close();

    try self.createFiles(dir);
    try self.createAndFillChildDirs(dir, 1);
}

pub fn createFiles(self: *Self, dir: std.fs.Dir) !void {
    var i: u32 = 0;
    while (i < self.files_per_dir) : (i += 1) {
        const name = self.createName();
        const file = try dir.createFile(&name, .{});
        defer file.close();

        try self.fillFileRandom(file);
    }
}

pub fn createName(self: *Self) [32]u8 {
    var buf = [_]u8{0} ** 32;
    const range = 'z' - 'a';
    self.rng.random().bytes(&buf);
    for (buf) |*byte| {
        byte.* = 'a' + (byte.* % range);
    }
    return buf;
}

pub fn fillFileRandom(self: *Self, file: std.fs.File) !void {
    var buffer = [_]u8{0} ** 4096;
    var remaining: usize = self.file_size;
    while (remaining > 0) {
        self.rng.random().bytes(&buffer);
        if (remaining <= buffer.len) {
            try file.writeAll(buffer[0..remaining]);
            return;
        } else {
            try file.writeAll(&buffer);
            remaining -= buffer.len;
        }
    }
}

pub fn createAndFillChildDirs(self: *Self, parent_dir: std.fs.Dir, depth: u32) CreateAndFillErrors!void {
    if (depth >= self.dir_depth) {
        return;
    }
    var i: u32 = 0;
    while (i < self.dirs_per_dir) : (i += 1) {
        const name = self.createName();
        try parent_dir.makeDir(&name);
        var child_dir = try parent_dir.openDir(&name, .{});
        defer child_dir.close();

        try self.createFiles(child_dir);
        try self.createAndFillChildDirs(child_dir, depth + 1);
    }
}

const CreateAndFillErrors = std.fs.File.OpenError || std.os.MakeDirError || std.os.WriteError;

test "basic test" {
    try std.testing.expectEqual(10, 3 + 7);
}
