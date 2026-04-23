// TODO: package opusurl? it needs openssl
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const link_mode = b.option(std.builtin.LinkMode, "link-mode", "Linking mode for the libraries") orelse
        .static;
    const pic = b.option(bool, "pic", "Enable Position Independent Code option");

    const upstream = b.dependency("opusfile", .{});

    const dep_ogg = b.dependency("ogg", .{
        .target = target,
        .optimize = optimize,
    });
    const lib_ogg = dep_ogg.artifact("ogg");
    const dep_opus = b.dependency("opus", .{
        .target = target,
        .optimize = optimize,
    });
    const lib_opus = dep_opus.artifact("opus");

    const lib = b.addLibrary(.{
        .name = "opusfile",
        .linkage = link_mode,
        .root_module = b.createModule(.{
            .target = target,
            .optimize = optimize,
            .link_libc = true,
            .pic = pic,
        }),
    });

    lib.addCSourceFiles(.{
        .root = upstream.path("src"),
        .files = &.{
            "info.c",
            "internal.c",
            "opusfile.c",
            "stream.c",
        },
    });

    lib.addIncludePath(dep_opus.path("include"));
    lib.addIncludePath(upstream.path("include"));

    lib.linkLibrary(lib_opus);
    lib.linkLibrary(lib_ogg);

    lib.installHeadersDirectory(upstream.path("include"), "", .{});
    // opusfile's headers need ogg's and opus' headers
    lib.installLibraryHeaders(lib_ogg);
    lib.installLibraryHeaders(lib_opus);

    b.installArtifact(lib);
}
