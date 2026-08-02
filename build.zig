// TODO: package opusurl? it needs openssl
const std = @import("std");
const log = std.log;

pub fn build(b: *std.Build) !void {
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

    lib.root_module.addCSourceFiles(.{
        .root = upstream.path("src"),
        .files = &.{
            "info.c",
            "internal.c",
            "opusfile.c",
            "stream.c",
        },
    });

    lib.root_module.addIncludePath(upstream.path("include"));
    lib.root_module.linkLibrary(lib_ogg);

    lib.installHeadersDirectory(upstream.path("include"), "", .{});
    // opusfile's headers need ogg's and opus' headers
    lib.installLibraryHeaders(lib_ogg);

    if (use_standalone_opus) {
        const dep_opus = try b.dependencyLazy("opus", .{
            .target = target,
            .optimize = optimize,
        });
        const lib_opus = findFirstArtifact(dep_opus, "opus", .static);
        lib.root_module.addIncludePath(dep_opus.path("include"));
        lib.root_module.linkLibrary(lib_opus);
        lib.installLibraryHeaders(lib_opus);
    }

    b.installArtifact(lib);
}

// workaround to std.Build.Dependency.artifact not allowing you to specify a linkage mode to look up for.
// needed with All Your Codebase's Opus package
pub fn findFirstArtifact(
    d: *std.Build.Dependency,
    name: []const u8,
    linkage: ?std.builtin.LinkMode,
) *std.Build.Step.Compile {
    var found: ?*std.Build.Step.Compile = null;
    for (d.builder.install_tls.step.dependencies.items) |dep_step| {
        const inst = dep_step.cast(std.Build.Step.InstallArtifact) orelse continue;
        if (std.mem.eql(u8, inst.artifact.name, name) and linkage == inst.artifact.linkage) {
            found = inst.artifact;
            break;
        }
    }
    return found orelse {
        for (d.builder.install_tls.step.dependencies.items) |dep_step| {
            const inst = dep_step.cast(std.Build.Step.InstallArtifact) orelse continue;
            log.info("available artifact: {q}", .{inst.artifact.name});
        }
        std.debug.panic("unable to find artifact {q}", .{name});
    };
}
