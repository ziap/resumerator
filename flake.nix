{
  description = "Resumerator's Rust development shell";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in {
    # Only create a development shell, because packaging is handled by
    # static-linking via musl
    devShell.${system} = let
      # Also cross-compile to Windows, because why not
      targetName = {
        mingw = "x86_64-w64-mingw32";
        musl = "x86_64-unknown-linux-musl";
      };

      # Generate the cross compilation packages import
      pkgsCross = builtins.mapAttrs (name: value: import pkgs.path {
        system = system;
        crossSystem = {
          config = value;
        };
      }) targetName;

      # Grab the corresponding C compiler binaries
      ccPkgs = builtins.mapAttrs (name: value: value.stdenv.cc) pkgsCross;
      cc = builtins.mapAttrs (name: value: "${value}/bin/${targetName.${name}}-cc") ccPkgs;

    in pkgs.mkShell {
      buildInputs = [
        pkgs.rustup
        pkgs.chromium
      ] ++ builtins.attrValues ccPkgs;

      # Set the default target to the first available target
      CARGO_BUILD_TARGET = let
        toolchain = builtins.readFile ./rust-toolchain.toml;
        targets = (builtins.fromTOML toolchain).toolchain.targets;
      in builtins.head targets;

      # Set compilers and linkers for C libraries
      CARGO_TARGET_X86_64_UNKNOWN_LINUX_MUSL_LINKER = cc.musl;
      CARGO_TARGET_X86_64_PC_WINDOWS_GNU_LINKER = cc.mingw;

      CC_x86_64_unknown_linux_musl = cc.musl;
      CC_x86_64_pc_windows_gnu = cc.mingw;

      shellHook = ''
        # Avoid polluting home directory
        export RUSTUP_HOME=$(pwd)/.rustup/
        export CARGO_HOME=$(pwd)/.cargo/

        # Use binaries installed with `cargo install`
        export PATH=$PATH:$CARGO_HOME/bin

        # Install and display the current toolchain
        rustup show
      '';

      # Link with Mingw libraries
      RUSTFLAGS = builtins.map (a: ''-L ${a}/lib'') [
        pkgsCross.mingw.windows.mingw_w64
        pkgsCross.mingw.windows.mingw_w64_pthreads
      ];
    };
  };
}
