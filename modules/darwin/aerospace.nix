{ lib, ... }:
let
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
    # start-at-login = true;
    key-mapping.preset = "qwerty";

    default-root-container-layout = "tiles";
    enable-normalization-flatten-containers = false;
    enable-normalization-opposite-orientation-for-nested-containers = false;

    on-focused-monitor-changed = [ "move-mouse monitor-lazy-center" ];

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
      let
        mod = "alt";
        left = "j";
        bottom = "k";
        top = "i";
        right = "l";
      in
      {
        "${mod}-enter" = [ "exec-and-forget alacritty" ];

        "${mod}-b" = "split horizontal";
        "${mod}-v" = "split vertical";
        "${mod}-f" = "fullscreen";
        "${mod}-shift-space" = "layout floating tiling";

        "${mod}-${left}" = "focus --boundaries-action wrap-around-the-workspace left";
        "${mod}-${bottom}" = "focus --boundaries-action wrap-around-the-workspace down";
        "${mod}-${top}" = "focus --boundaries-action wrap-around-the-workspace up";
        "${mod}-${right}" = "focus --boundaries-action wrap-around-the-workspace right";

        "${mod}-shift-${left}" = "move left";
        "${mod}-shift-${bottom}" = "move down";
        "${mod}-shift-${top}" = "move up";
        "${mod}-shift-${right}" = "move right";

        "${mod}-c" = "reload-config";
      } // lib.attrsets.foldlAttrs
        (acc: num: name: acc // {
          "${mod}-${num}" = "workspace ${name}";
          "${mod}-shift-${num}" = "move-node-to-workspace ${name}";
        })
        { }
        workspaces;
  };
}

