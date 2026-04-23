// TODO: package opusurl? it needs openssl
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const link_mode = b.option(std.builtin.LinkMode, "link-mode", "Linking mode for the libraries") orelse
        .static;
    const pic = b.option(bool, "pic", "Enable Position Independent Code option");
    const use_standalone_opus = b.option(bool, "standalone-opus", "Should opusfile link its own Opus library?") orelse true;

    const upstream = b.dependency("opusfile", .{});

    const dep_ogg = b.dependency("ogg", .{
        .target = target,
        .optimize = optimize,
    });
    const lib_ogg = dep_ogg.artifact("ogg");
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

    lib.addIncludePath(upstream.path("include"));
    lib.linkLibrary(lib_ogg);

    lib.installHeadersDirectory(upstream.path("include"), "", .{});
    // opusfile's headers need ogg's and opus' headers
    lib.installLibraryHeaders(lib_ogg);

    if (use_standalone_opus) {
        const maybe_dep_opus = b.lazyDependency("opus", .{
            .target = target,
            .optimize = optimize,
        });
        if (maybe_dep_opus) |dep_opus| {
            const lib_opus = dep_opus.artifact("opus");
            lib.addIncludePath(dep_opus.path("include"));
            lib.linkLibrary(lib_opus);
            lib.installLibraryHeaders(lib_opus);
        }
    }

    b.installArtifact(lib);
}
