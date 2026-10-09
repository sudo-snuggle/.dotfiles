{ pkgs, inputs, ... }: {
  programs.firefox = {
  enable = true;

  profiles.default-release = {
    id = 0;
    name = "default-release";
    isDefault = true;

    extraConfig = builtins.readFile "${inputs.betterfox}/user.js";

    settings = {
      "dom.ipc.processCount" = 4;
      "media.eme.enabled" = true;
    };
  };
};
}