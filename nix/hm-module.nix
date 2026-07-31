# Per-host configuration for the shell. The only thing worth configuring is
# which metrics a given machine should show, because that is the one thing the
# source cannot know: the shell detects what the hardware can report, and this
# file overrides that answer where the detection is wrong or unwanted.
#
# Everything set here lands in ~/.config/erikshell/metrics.json, which the shell
# watches. Changing it takes effect on `home-manager switch`, with no rebuild and
# no restart.
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.erikshell;

  # An unset metric stays null and is left out of the JSON entirely, so the
  # shell falls back to what it detected.
  metric =
    description:
    lib.mkOption {
      type = lib.types.nullOr lib.types.bool;
      default = null;
      inherit description;
    };

  json = lib.filterAttrs (_: v: v != null) cfg.metrics;
in
{
  options.programs.erikshell = {
    enable = lib.mkEnableOption "Erik's Quickshell desktop shell";

    package = lib.mkOption {
      type = lib.types.nullOr lib.types.package;
      default = null;
      description = "The shell package to install and, if enabled, to run as a user service.";
    };

    systemd.enable = lib.mkEnableOption "running the shell from a systemd user service";

    metrics = {
      # Setting this true is not what turns the GPU on: the shell shows it when
      # it finds a card whose utilisation it can actually read, and a host with
      # no such card would get a ring stuck at zero if this could force one.
      # False hides a GPU that is there.
      gpu = metric "Hide GPU utilisation and VRAM, if false. Only an AMD card is readable, and one that is not readable is never shown.";
      fan = metric "Show fan speed.";
      temp = metric "Show CPU temperature.";
      swap = metric "Show swap usage and swap I/O.";
      net = metric "Show network throughput.";
      diskio = metric "Show disk read and write throughput.";
      cores = metric "Show the per-core CPU strip.";
      battery = metric "Show battery charge.";
      backlight = metric "Show the backlight slider.";

      disks = lib.mkOption {
        type = lib.types.nullOr (lib.types.listOf lib.types.str);
        default = null;
        example = [
          "/"
          "/mnt/data"
        ];
        description = ''
          Mount points to graph. Unset means every mounted filesystem larger
          than 10 GB that is not a tmpfs.
        '';
      };
    };
  };

  config = lib.mkIf cfg.enable {
    home.packages = lib.optional (cfg.package != null) cfg.package;

    xdg.configFile."erikshell/metrics.json" = lib.mkIf (json != { }) {
      source = (pkgs.formats.json { }).generate "erikshell-metrics.json" json;
    };

    systemd.user.services.erikshell = lib.mkIf cfg.systemd.enable {
      Unit = {
        Description = "Erik's Quickshell desktop shell";
        PartOf = [ config.wayland.systemd.target ];
        After = [ config.wayland.systemd.target ];
        # Rewriting metrics.json is picked up live, so it deliberately does not
        # restart the unit.
      };

      Service = {
        ExecStart = lib.getExe cfg.package;
        Restart = "on-failure";
        # Applications the launcher starts inherit this unit's cgroup, and the
        # default kill mode would SIGTERM all of them when the unit restarts.
        # Since ExecStart embeds the store path, every switch that touches a
        # .qml file restarts it — which would close everything you had opened.
        KillMode = "process";
      };

      Install.WantedBy = [ config.wayland.systemd.target ];
    };

    assertions = [
      {
        assertion = !cfg.systemd.enable || cfg.package != null;
        message = "programs.erikshell: systemd.enable needs programs.erikshell.package to be set.";
      }
    ];
  };
}
