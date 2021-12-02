{ pkgs, inputs, ... }: {
    imports = [ "${inputs.nixpkgs}/modules/virtualisation/amazon-image.nix" ];
    ec2.hvm = true;
    virtualisation.podman = {
      enable = true;
      # Create a `docker` alias for podman, to use it as a drop-in replacement
      dockerCompat = true;
    };
}
