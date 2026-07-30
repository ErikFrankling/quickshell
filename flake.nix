{
  description = "Erik's Quickshell desktop shell";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      # Everything the shell shells out to at runtime.
      runtimeDeps = with pkgs; [
        brightnessctl
        hyprpaper
      ];
    in
    {
      # `nix run` starts the shell from the working tree, so editing a .qml
      # file reloads it live. No rebuild, no store path, no reinstall.
      apps.${system}.default = {
        type = "app";
        program = toString (
          pkgs.writeShellScript "run-shell" ''
            export PATH=${pkgs.lib.makeBinPath runtimeDeps}:$PATH
            exec ${pkgs.quickshell}/bin/quickshell -p "''${1:-$PWD}"
          ''
        );
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.quickshell ] ++ runtimeDeps;
      };
    };
}
