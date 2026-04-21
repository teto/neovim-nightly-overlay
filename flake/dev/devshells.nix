{
  perSystem =
    {
      pkgs,
      config,
      lib,
      ...
    }:
    let
      devShellFromNeovim = let
            nvimdevWrapper = 
            pkgs.writeShellScriptBin "nvim-dev" ''
              if [ -d "$PWD/runtime" ]; then
                export VIMRUNTIME="$PWD/runtime"
                echo "Detecting neovim runtime folder: VIMRUNTIME set to $VIMRUNTIME"
              else
                echo "No runtime detected"
              fi

              $PWD/bin/nvim
            '';
      in

        pkg:
        pkg.overrideAttrs (oa: {
          cmakeFlags = config.packages.neovim-developer.cmakeFlags ++ [
                  (lib.cmakeFeature "CACHE_PRG" (lib.getExe pkgs.ccache)) 
                  # nvim-treesitter-context
                  (lib.cmakeFeature "CMAKE_C_FLAGS" "-ggdb3 -fno-omit-frame-pointer") 
                ];

          # avoid neovim-debug's patch to cmake.config/versiondef.h.in to minimize
          # the noisy git diff when patching neovim
          preConfigure = pkgs.neovim-unwrapped.preConfigure;

          nativeBuildInputs = oa.nativeBuildInputs ++ [
            nvimdevWrapper
            pkgs.stylua
            pkgs.include-what-you-use
            pkgs.clang-tools
          ];

          shellHook = ''
            export ASAN_SYMBOLIZER_PATH=${pkgs.llvm_18}/bin/llvm-symbolizer
            export NVIM_PYTHON_LOG_LEVEL=DEBUG
            export NVIM_LOG_FILE=/tmp/nvim.log

            # ASAN_OPTIONS=detect_leaks=1
            export ASAN_OPTIONS="log_path=./test.log:abort_on_error=1"

            # treesitter parsers needed when running `make functionaltests`
            if [ -d runtime ]; then
              # todo install all of them
              mkdir -p runtime/parser
              cp -f ${pkgs.vimPlugins.nvim-treesitter.builtGrammars.c}/parser runtime/parser/c.so
            fi
          '';

          # Do not fail the hercules-ci because of this shell failing.
          # This often happens due to neovim-developer being broken.
          ignoreFailure = true;
        });

    in
    {
      devShells = {
        default = devShellFromNeovim config.packages.neovim-developer;

        # Provide a devshell that can be used strictly for developing this flake.
        minimal = pkgs.mkShell.override { inherit (pkgs.llvmPackages_latest) stdenv; } {
          name = "neovim-minimal-shell";
          inputsFrom = [
            config.packages.default
          ];
          packages = with pkgs; [
            (python3.withPackages (ps: [ ps.msgpack ]))
            include-what-you-use
            jq
            lua-language-server
            shellcheck
          ];
          shellHook = ''
            export VIMRUNTIME=
          '';
        };
      };
    };
}
