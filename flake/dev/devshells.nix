{
  perSystem =
    {
      pkgs,
      config,
      ...
    }:
    {
      devShells = {
        default = (pkgs.mkShell.override({
            # TODO check if necessary
            stdenv = pkgs.llvmPackages_21.stdenv;
          })) {
          name = "neovim-developer-shell";
          inputsFrom = [
            config.packages.neovim-developer
          ];

          packages = config.devShells.minimal.nativeBuildInputs ++ [
            pkgs.clang-tools
            pkgs.glibc.dev # for string.h
          ];

          shellHook = ''
            export ASAN_SYMBOLIZER_PATH=${pkgs.llvm_18}/bin/llvm-symbolizer
            export NVIM_PYTHON_LOG_LEVEL=DEBUG
            export NVIM_LOG_FILE=/tmp/nvim.log

            # ASAN_OPTIONS=detect_leaks=1
            export ASAN_OPTIONS="log_path=./test.log:abort_on_error=1"

            # for treesitter functionaltests
            mkdir -p runtime/parser
            # TODO loop over neovim-unwrapped.treesitter-parsers instead
            cp -f ${pkgs.vimPlugins.nvim-treesitter.builtGrammars.c}/parser runtime/parser/c.so
            cp -f ${pkgs.vimPlugins.nvim-treesitter.builtGrammars.vim}/parser runtime/parser/vim.so
          '';

          # Do not fail the hercules-ci because of this shell failing.
          # This often happens due to neovim-developer being broken.
          ignoreFailure = true;
        };

        # Provide a devshell that can be used strictly for developing this flake.
        minimal = pkgs.mkShell.override { inherit (pkgs.llvmPackages_latest) stdenv; } {
          name = "neovim-minimal-shell";
          inputsFrom = [
            config.packages.neovim
          ];
          packages = with pkgs; [
            # weird: why are those not in default devShell ?
            (python3.withPackages (ps: [ ps.msgpack ]))
            include-what-you-use
            jq
            lua-language-server
            luajit.pkgs.luacheck
            shellcheck
          ];
          shellHook = ''
            export VIMRUNTIME=
          '';
        };
      };
    };
}
