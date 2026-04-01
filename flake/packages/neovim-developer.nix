{
  neovim-debug,
  stdenv,
  neovim-unwrapped,
  luajit,
  pkgs,
  stylua,
  lib,
  neovim-src, 
  ccache,
  llvmPackages_22,
  ...
}:
(neovim-debug.override ({
  stdenv = llvmPackages_22.stdenv;
})).overrideAttrs (oa: {
  pname = "${oa.pname}-developer";
  cmakeFlags =
    oa.cmakeFlags
    ++ [
      # doesn't work in sandbox if not pre-configured
      (lib.cmakeFeature "CACHE_PRG" (lib.getExe ccache))
      (lib.cmakeBool "ENABLE_LTO" false)
      (lib.cmakeFeature "CMAKE_EXTRA_FLAGS" "-DNVIM_LOG_DEBUG=ON" )
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      # https://github.com/google/sanitizers/wiki/AddressSanitizerFlags
      # https://clang.llvm.org/docs/AddressSanitizer.html#symbolizing-the-reports
      (lib.cmakeBool "ENABLE_ASAN_UBSAN" false)
    ];

  # we dont want to override cmake.config/versiondef.h.in
  preConfigure = neovim-unwrapped.preConfigure;

  nativeBuildInputs = oa.nativeBuildInputs ++ [
    stylua
    # added glibc.dev ? remove specifgic stdenv ?
  ];

  doCheck = pkgs.stdenv.isLinux;
  shellHook = ''
    export VIMRUNTIME=${neovim-src}/runtime
    # doesnt do anything
    PATH="$PWD/build/bin:$PATH"
    if [ -d "$PWD/runtime" ]; then
      echo "Detecting neovim runtime folder..."
      VIMRUNTIME="$PWD/runtime"

    fi
    echo "VIMRUNTIME set to $VIMRUNTIME"
    echo "export NVIM_LOG_FILE to where you want to save the log"
    export NVIM_LOG_FILE="$PWD/nvim.log"
  '';

  # This package can be "failing" as soon as a memory leak is detected
  ignoreFailure = true;
})
