{
  neovim-debug,
  pkgs,
  lib,
  ...
}:
neovim-debug.overrideAttrs (oa: {
  cmakeFlags =
    oa.cmakeFlags
    ++ [
      (lib.cmakeFeature "LUACHECK_PRG" (lib.getExe pkgs.luajit.pkgs.luacheck))
      (lib.cmakeFeature "CACHE_PRG" (lib.getExe pkgs.ccache))
      (lib.cmakeBool "ENABLE_LTO" false)
      (lib.cmakeBool "LOG_DEBUG" true)
    ]
    ++ lib.optionals pkgs.stdenv.isLinux [
      # https://github.com/google/sanitizers/wiki/AddressSanitizerFlags
      # https://clang.llvm.org/docs/AddressSanitizer.html#symbolizing-the-reports
      (lib.cmakeBool "ENABLE_ASAN_UBSAN" true)
    ];

  nativeBuildInputs = oa.nativeBuildInputs ++ [
    pkgs.stylua
  ];

  doCheck = pkgs.stdenv.isLinux;
  shellHook = ''
    export VIMRUNTIME=$PWD/runtime
    export NVIM_LOG_FILE=/tmp/nvim.log
    '';

  # This package can be "failing" as soon as a memory leak is detected
  ignoreFailure = true;
})
