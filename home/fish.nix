{ ... }:

{
  programs.fish = {
  enable = true;

  functions = {


    flakepush-proteus  = ''
      cd ~/.dotfiles
      sudo nixos-rebuild switch --flake .#proteus
      and git add .
      and git commit -m "update nixos config"
      and git push
    '';

    
    flakepull-hermes = ''
      cd ~/.dotfiles
      git pull
      and sudo nixos-rebuild switch --flake .#hermes
      '';

  };
};
}