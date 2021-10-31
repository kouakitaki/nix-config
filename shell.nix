{ pkgs ? import <nixpkgs> { } }:

pkgs.mkShell {
  buildInputs = with pkgs; [
    nixpkgs-fmt
    nix-prefetch-github
    sumneko-lua-language-server
  ];
}
