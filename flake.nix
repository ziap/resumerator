{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "nixpkgs/nixos-24.11";
  };

  outputs = { self, nixpkgs }: let 
    system = "x86_64-linux";
    pkgs = nixpkgs.legacyPackages.${system};
  in {
    devShell.${system} = pkgs.mkShell {
      buildInputs = with pkgs; [
        cargo
        rustc
        rust-analyzer
        chromium
      ];
    };
  };
}
