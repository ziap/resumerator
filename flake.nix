{
  description = "Resumerator's Rust environment";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in {
    devShell.${system} = let
      # Importing cross compilation packages
      pkgsCross = {
        mingw = import pkgs.path {
          system = system;
          crossSystem = {
            config = "x86_64-w64-mingw32";
          };
        };

        musl = import pkgs.path {
          system = system;
          crossSystem = {
            config = "x86_64-unknown-linux-musl";
          };
        };
      };

      wine = pkgs.wineWowPackages.stable;
    in pkgs.mkShell {
      buildInputs = [
        pkgs.rustup
        pkgsCross.mingw.stdenv.cc
        pkgsCross.musl.stdenv.cc
        wine
        pkgs.chromium
      ];

      # Set the default target to the first available target
      CARGO_BUILD_TARGET = let
        toolchain = builtins.readFile ./rust-toolchain.toml;
        targets = (builtins.fromTOML toolchain).toolchain.targets;
      in builtins.head targets;

      # Use wine for `cargo run`, `cargo test`, etc.
      CARGO_TARGET_X86_64_PC_WINDOWS_GNU_RUNNER = "${wine}/bin/wine64";

      shellHook = ''
        # Avoid polluting home directory
        export RUSTUP_HOME=$(pwd)/.rustup/
        export CARGO_HOME=$(pwd)/.cargo/
        export WINEPREFIX=$(pwd)/.wine/

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
