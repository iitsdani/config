{ lib, pkgs, ... }:
let
  mod = "alt";

  left = "j";
  bottom = "k";
  top = "i";
  right = "l";

  workspaces = {
    "0" = "slack";
    "1" = "term";
    "2" = "www";
    "3" = "code";
    "4" = "ide";
    "5" = "chat";
    "6" = "www-2";
    "7" = "7";
    "8" = "8";
    "9" = "9";
  };

  workspace-monitor-assignments = {
    "code" = "secondary";
    "ide" = "secondary";
    "www-2" = "secondary";
  };

  app-monitors-assignments = {
    "com.tinyspeck.slackmacgap" = "slack";
    "com.tdesktop.Telegram" = "chat";
    "net.whatsapp.WhatsApp" = "chat";
    "org.mozilla.firefox" = "www";
  };
in
{
  services.aerospace.enable = true;
  services.aerospace.settings = {
    config-version = 2;
    persistent-workspaces = builtins.attrValues workspaces;
    # start-at-login = true;
    key-mapping.preset = "qwerty";

    default-root-container-layout = "tiles";
    enable-normalization-flatten-containers = false;
    enable-normalization-opposite-orientation-for-nested-containers = false;

    on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];
    focus-follows-mouse.enabled = true;

    # NOTE: the PATH environment variable passed to Aerospace doesn't contain
    # the paths where Nix adds soft-links to the current version executables.
    exec.inherit-env-vars = true;
    exec.env-vars.PATH = lib.mkDefault "/etc/profiles/per-user/ar3s3ru/bin:\${PATH}";

    gaps = {
      outer.left = 20;
      outer.bottom = 20;
      outer.top = 20;
      outer.right = 20;
      inner.horizontal = 10;
      inner.vertical = 10;
    };

    workspace-to-monitor-force-assignment = workspace-monitor-assignments;

    on-window-detected = lib.attrsets.foldlAttrs
      (acc: app-id: workspace: acc ++ [{
        "if".app-id = app-id;
        run = "move-node-to-workspace ${workspace}";
      }])
      [ ]
      app-monitors-assignments;

    mode.main.binding =
      {
        "${mod}-enter" = [ "exec-and-forget /usr/bin/open -na ${pkgs.ghostty-bin}/Applications/Ghostty.app" ];

        "${mod}-b" = "split horizontal";
        "${mod}-v" = "split vertical";
        "${mod}-e" = "layout tiles horizontal vertical";
        "${mod}-f" = "fullscreen";
        "${mod}-shift-space" = "layout floating tiling";
        "${mod}-shift-q" = "close";
        "${mod}-r" = "mode resize";

        "${mod}-${left}" = "focus --boundaries-action wrap-around-the-workspace left";
        "${mod}-${bottom}" = "focus --boundaries-action wrap-around-the-workspace down";
        "${mod}-${top}" = "focus --boundaries-action wrap-around-the-workspace up";
        "${mod}-${right}" = "focus --boundaries-action wrap-around-the-workspace right";

        "${mod}-shift-${left}" = "move left";
        "${mod}-shift-${bottom}" = "move down";
        "${mod}-shift-${top}" = "move up";
        "${mod}-shift-${right}" = "move right";

        "${mod}-c" = "reload-config";
        "${mod}-shift-c" = "reload-config && run-callback --for-every-window on-window-detected";
      } // lib.attrsets.foldlAttrs
        (acc: num: name: acc // {
          "${mod}-${num}" = "workspace ${name}";
          "${mod}-shift-${num}" = "move-node-to-workspace ${name}";
        })
        { }
        workspaces;

    mode.resize.binding = {
      "${left}" = "resize width -50";
      "${bottom}" = "resize height +50";
      "${top}" = "resize height -50";
      "${right}" = "resize width +50";
      left = "resize width -50";
      down = "resize height +50";
      up = "resize height -50";
      right = "resize width +50";
      esc = "mode main";
      enter = "mode main";
      "${mod}-r" = "mode main";
    };
  };
}
