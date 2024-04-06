const std = @import("std");
const string = @import("./string.zig");
const Allocator = std.mem.Allocator;
const Uri = std.Uri;

/// A mutable Uri with convenients method to change every components of the Uri.
/// The allocator owns the memory of all the components of the Uri.
pub const MutableUri = struct {
    allocator: Allocator,
    scheme: ?[]u8 = null,
    user: ?[]u8 = null,
    password: ?[]u8 = null,
    host: ?[]u8 = null,
    port: ?u16 = null,

    pub fn init(allocator: Allocator, uri: std.Uri) !MutableUri {
        var mutable_uri = MutableUri {
            .allocator = allocator,
        };
        try mutable_uri.setScheme(uri.scheme);
        try mutable_uri.setUser(uri.user);
        try mutable_uri.setPassword(uri.password);
        try mutable_uri.setHost(uri.host);
        mutable_uri.setPort(uri.port);
        return mutable_uri;
    }

    pub fn deinit(self: MutableUri) void {
        if (self.scheme) |scheme| {
            self.allocator.free(scheme);
        }
        if (self.user) |user| {
            self.allocator.free(user);
        }
        if (self.password) |password| {
            self.allocator.free(password);
        }
        if (self.host) |host| {
            self.allocator.free(host);
        }
    }

    /// Change the scheme of the Uri to the provided value.
    /// Passing a null or empty value to this function will result in the user being set to null.
    pub fn setScheme(self: *MutableUri, scheme: ?[]const u8) !void {
        if (self.scheme) |old_scheme| {
            self.allocator.free(old_scheme);
        }
        if (string.nullIfBlank(scheme)) |new_scheme| {
            self.scheme = try self.allocator.dupe(u8, new_scheme);
        } else {
            self.scheme = null;
        }
    }

    /// Change the user of the Uri to the provided value.
    /// Passing a null or empty value to this function will result in the user being set to null.
    pub fn setUser(self: *MutableUri, user: ?[]const u8) !void {
        if (self.user) |old_user| {
            self.allocator.free(old_user);
        }
        if (string.nullIfBlank(user)) |new_user| {
            self.user = try self.allocator.dupe(u8, new_user);
        } else {
            self.user = null;
        }
    }

    // Change the user of the Uri to the provided value.
    // Passing a null or empty value to this function will result in the user being set to null.
    pub fn setPassword(self: *MutableUri, password: ?[]const u8) !void {
        if (self.password) |old_password| {
            self.allocator.free(old_password);
        }
        if (string.nullIfBlank(password)) |new_password| {
            self.password = try self.allocator.dupe(u8, new_password);
        } else {
            self.password = null;
        }
    }

    // Change the host of the Uri to the provided value.
    // Passing a null or empty value to this function will result in the user being set to null.
    pub fn setHost(self: *MutableUri, host: ?[]const u8) !void {
        if (self.host) |old_host| {
            self.allocator.free(old_host);
        }
        if (string.nullIfBlank(host)) |new_host| {
            self.host = try self.allocator.dupe(u8, new_host);
        } else {
            self.host = null;
        }
    }

    // Change the port of the Uri to the provided value.
    pub fn setPort(self: *MutableUri, port: ?u16) void {
        self.port = port;
    }
};

const expectEqual = std.testing.expectEqual;
const expectEqualSlices = std.testing.expectEqualSlices;

test "init - copy values from Uri" {
    const uri = try Uri.parse("http://user:password@example.com:80/path?param=value#hash");

    var mutable_uri = try MutableUri.init(std.testing.allocator, uri);
    defer mutable_uri.deinit();

    try expectEqualSlices(u8, uri.scheme, mutable_uri.scheme.?);
    try expectEqualSlices(u8, uri.user.?, mutable_uri.user.?);
    try expectEqualSlices(u8, uri.password.?, mutable_uri.password.?);
    try expectEqualSlices(u8, uri.host.?, mutable_uri.host.?);
    try expectEqual(uri.port.?, mutable_uri.port.?);
}