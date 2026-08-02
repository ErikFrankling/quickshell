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
        # `vial.py`, which reads the Dactyl's layout off the board over raw
        # HID. Standard library only — no hidapi, no pyusb, nothing to package.
        python3
        # Only for the optional wallpaper-matching toggle, which is off by
        # default. It needs -c lchansi -p ansidark16; every other palette
        # reorders hues by salience and turns red into magenta.
        wallust
      ];

      # Just the shell itself. The docs, the screenshots and the git history
      # would otherwise land in the store and change the hash on every commit.
      src = lib.fileset.toSource {
        root = ./.;
        fileset = lib.fileset.unions [
          (lib.fileset.fileFilter (f: f.hasExt "qml") ./.)
          # schemes.js — the base16 corpus, imported by Themes.qml like any
          # other QML source file.
          (lib.fileset.fileFilter (f: f.hasExt "js") ./.)
          ./qmldir
          # The keyboard helper and the layout it falls back to when no
          # keyboard answers. Both are found through `Quickshell.shellPath`,
          # so they have to sit beside the QML in the store too.
          ./vial.py
          ./dactyl.json
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
      # Arguments are forwarded, so `erikshell ipc call launcher toggle` works.
      # Without that the IpcHandlers are unreachable on an installed system:
      # `qs` finds an instance by its config path, which nobody knows once the
      # config lives in the store.
      packages.${system}.default = pkgs.writeShellApplication {
        name = "erikshell";
        runtimeInputs = [ pkgs.quickshell ] ++ runtimeDeps;
        text = ''exec quickshell -p ${src} "$@"'';
      };

      # Importing this is enough — the package defaults to the one above, so a
      # host only has to enable it and say which metrics it wants.
      homeManagerModules.default = {
        imports = [ ./nix/hm-module.nix ];
        programs.erikshell.package = lib.mkDefault self.packages.${system}.default;
      };

      # Home Manager renamed the attribute; noctalia and DankMaterialShell both
      # use the newer spelling.
      homeModules = self.homeManagerModules;

      devShells.${system}.default = pkgs.mkShell {
        packages = [ pkgs.quickshell ] ++ runtimeDeps;
      };
    };
}
