{ ... }:

{
  programs.fish = {
  enable = true;

  functions = {
    flake-push = ''
      sudo nixos-rebuild switch --flake .#proteus
      and git add .
      and git commit -m "update nixos config"
      and git push
    '';
  };
};
}