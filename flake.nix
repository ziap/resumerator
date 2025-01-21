{
  description = "Resumerator's Rust environment";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShell.${system} = let
      # Pinned rust toolchain version
      # Get toolchain versions from <https://releases.rs/>
      rustupToolchain = "stable-2025-01-09";

      rustBuildTargets = {
        # Cross-compiling to Windows with Mingw-w64
        mingw = "x86_64-pc-windows-gnu";

        # Statically link against Musl libc
        musl = "x86_64-unknown-linux-musl";
      };

      pkgs-cross-mingw = import pkgs.path {
        system = system;
        crossSystem = {
          config = "x86_64-w64-mingw32";
        };
      };

      pkgs-cross-musl = import pkgs.path {
        system = system;
        crossSystem = {
          config = "x86_64-unknown-linux-musl";
        };
      };

      wine = pkgs.wineWowPackages.stable;
    in pkgs.mkShell {
      buildInputs = [
        pkgs.rustup
        pkgs-cross-mingw.stdenv.cc
        pkgs-cross-musl.stdenv.cc
        wine
        pkgs.chromium
      ];

      RUSTUP_TOOLCHAIN = rustupToolchain;
      CARGO_BUILD_TARGET = rustBuildTargets.musl;

      # Use wine for `cargo run`, `cargo test`, etc.
      CARGO_TARGET_X86_64_PC_WINDOWS_GNU_RUNNER = "${wine}/bin/wine64";

      shellHook = ''
        # Avoid polluting home dir with local project stuff.
        export RUSTUP_HOME=$(pwd)/.rustup/
        export CARGO_HOME=$(pwd)/.cargo/
        export WINEPREFIX=$(pwd)/.wine

        export PATH=$PATH:$CARGO_HOME/bin
        export PATH=$PATH:$RUSTUP_HOME/toolchains/${rustupToolchain}-x86_64-unknown-linux-gnu/bin/

        rustup component add rust-analyzer

        # Ensure our targets are added via rustup.
        ${builtins.toString (builtins.map (a: ''
          rustup target add ${a}
        '') (builtins.attrValues rustBuildTargets))}
      '';

      # Link with Mingw libraries
      RUSTFLAGS = builtins.map (a: ''-L ${a}/lib'') [
        pkgs-cross-mingw.windows.mingw_w64
        pkgs-cross-mingw.windows.mingw_w64_pthreads
      ];
    };
  };
}
