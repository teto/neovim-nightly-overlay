{
  neovim-debug,
  pkgs,
  lib,
  neovim-src,
  neovim-src, ccache,
  # llvmPackages_21,
  ...
}:
(neovim-debug.override ({
  # stdenv = llvmPackages_21.stdenv;
})).overrideAttrs (oa: {
  cmakeFlags =
    oa.cmakeFlags
    ++ [
      (lib.cmakeFeature "LUACHECK_PRG" (lib.getExe luajit.pkgs.luacheck))
      (lib.cmakeFeature "CACHE_PRG" (lib.getExe ccache))
      (lib.cmakeBool "ENABLE_LTO" false)
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
    export VIMRUNTIME=${neovim-src}/runtime
    if [ -d $PWD/runtime ]; then
      echo "Detecting neovim runtime folder..."
      VIMRUNTIME="$PWD/runtime"
      PATH="$PWD/build/bin:$PATH"

    fi
    echo "VIMRUNTIME set to $VIMRUNTIME"
  '';

  # This package can be "failing" as soon as a memory leak is detected
  ignoreFailure = true;
})
