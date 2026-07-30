{
  description = "Erik's Quickshell desktop shell";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      inherit (pkgs) lib;

      # Everything the shell shells out to at runtime.
      runtimeDeps = with pkgs; [
        brightnessctl
        hyprpaper
      ];

      # Just the shell itself. The docs, the screenshots and the git history
      # would otherwise land in the store and change the hash on every commit.
      src = lib.fileset.toSource {
        root = ./.;
        fileset = lib.fileset.unions [
          (lib.fileset.fileFilter (f: f.hasExt "qml") ./.)
          ./qmldir
        ];
      };
    in
    {
      # `nix run` starts the shell from the working tree, so editing a .qml
      # file reloads it live. No rebuild, no store path, no reinstall.
      apps.${system}.default = {
        type = "app";
        program = toString (
          pkgs.writeShellScript "run-shell" ''
            export PATH=${lib.makeBinPath runtimeDeps}:$PATH
            exec ${pkgs.quickshell}/bin/quickshell -p "''${1:-$PWD}"
          ''
        );
      };

      # The installable version, for when the shell is part of the system
      # rather than something being iterated on.
      packages.${system}.default = pkgs.writeShellApplication {
        name = "erikshell";
        runtimeInputs = [ pkgs.quickshell ] ++ runtimeDeps;
        text = ''exec quickshell -p ${src}'';
      };

      # Importing this is enough — the package defaults to the one above, so a
      # host only has to enable it and say which metrics it wants.
      homeManagerModules.default = {
        imports = [ ./nix/hm-module.nix ];
        programs.erikshell.package = lib.mkDefault self.packages.${system}.default;
      };

      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.quickshell ] ++ runtimeDeps;
      };
    };
}
