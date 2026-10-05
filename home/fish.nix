{ ... }:

{
  programs.fish = {
    enable = true;

    functions = {

      
      flakepush-proteus = ''
        cd ~/.dotfiles
        git add .
        sudo nixos-rebuild switch --flake .#proteus
        and git commit -m "update nixos config"
        and git push
      '';

      flakepull-hermes = ''
        cd ~/.dotfiles
        git pull
        and sudo nixos-rebuild switch --flake .#hermes
      '';

      pushnotes = ''
        cd ~/scratch-notes
        git add .
        and git commit -m "update notes"
        and git push
      '';
    };
  };
}