{
  description = "Resumerator's Rust development shell";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }: let
    system = "x86_64-linux";
    pkgs = import nixpkgs { inherit system; };
  in {
    devShell.${system} = pkgs.mkShell {
      buildInputs = [
        pkgs.rustup
        pkgs.chromium
      ];

      shellHook = ''
        # Avoid polluting home directory
        export RUSTUP_HOME=$(pwd)/.rustup/
        export CARGO_HOME=$(pwd)/.cargo/

        # Use binaries installed with `cargo install`
        export PATH=$PATH:$CARGO_HOME/bin

        # Install and display the current toolchain
        rustup show
      '';
    };
  };
}
