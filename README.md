# Opusfile on Zig

This repository wraps the upstream Opusfile library source code with Zig's build system.

Zig 0.15.2 is required.

## Installing as a `build.zig.zon` package

Run in your Zig project:
```sh
zig fetch --save-exact=opusfile git+https://github.com/lateleite/opusfile-on-zig.git
```

Then in your `build.zig` file:
```zig
pub fn build(b: *std.Build) !void {
    // ...

    // Add a reference to the package you've just fetched...
    const dep_opusfile = b.dependency("opusfile", .{
        .target = target,
        .optimize = optimize,
    });
    const lib_opusfile = dep_opusfile.artifact("opusfile");

    // ...then link the library to your module
    your_module.linkLibrary(lib_opusfile);

    // ...
}
```

After that, you may use Opusfile's header files in your module.

## License

All (build) code here is released to public domain or under the BSD Zero Clause license, choose whichever you prefer.

You may find Opusfile's license at [https://github.com/xiph/opusfile/blob/6dfd29e7adb87f2e193575fc3fa88cbf1a0b27df/COPYING](https://github.com/xiph/opusfile/blob/6dfd29e7adb87f2e193575fc3fa88cbf1a0b27df/COPYING).
