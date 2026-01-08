Projectile Native Module

A binary module for Garry's Mod that provides native (C++) performance optimizations for the projectile system.

Prerequisites

- CMake 3.10 or higher
- C++ compiler:
  - Windows: Visual Studio 2019+ with "Desktop development with C++" workload (clang optional)
  - Linux: GCC or Clang

Building

Configure and Build

mkdir build
cd build
cmake ..
cmake --build . --config Release

Platform-Specific Instructions

Windows
cmake -G "Visual Studio 16 2019" ..
cmake --build . --config Release

Linux/macOS
cmake -DCMAKE_BUILD_TYPE=Release ..
make

Installation

After building, the module will be located in the `build` directory with the appropriate platform suffix:

- **Windows x64**: `gmcl_projectile_native_win64.dll`
- **Windows x32**: `gmcl_projectile_native_win32.dll`
- **Linux x64**: `gmcl_projectile_native_linux64.dll`
- **Linux x32**: `gmcl_projectile_native_linux.dll`
- **macOS**: `gmcl_projectile_native_osx.dll`

Copy the compiled module to your Garry's Mod installation:
garrysmod/lua/bin/gmcl_projectile_native_[platform].dll

If the `lua/bin/` directory doesn't exist, create it.

Usage

The module is loaded automatically by the projectile system if present. To test if it's working:

local success, native = pcall(require, "projectile_native")
if success then
    print(native.native())  -- Should print: "Hello from native module!"
    print("Native module loaded successfully!")
else
    print("Native module not found, using Lua fallback")
end

Optional Module

This binary module is **completely optional**. The projectile system works perfectly fine without it using pure Lua. The native module simply provides performance improvements for servers with many simultaneous projectiles.

Performance Benefits

(See "Optional Module" above regarding server performance optimization for high projectile counts.)

Development

Project Structure

native-module/
├── CMakeLists.txt       CMake build configuration
├── module.cpp           Main module source
├── gmod-headers/        GMod Lua C API headers (from GitHub)
├── build/               Build output (generated)
└── README.txt           This file

Debugging

Build in Debug mode for better error messages:
cmake --build . --config Debug