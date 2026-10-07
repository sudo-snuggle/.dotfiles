{ ... }:

{
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      function fish_greeting
        echo '
                        /\
                       /  |
                       \  o
                   _.-`/`-._
       _         _/         \_         _
      ) `-._   _/  /O\   /O\  \_   _.-` (
     )      `-/    `-'   `-'    \-`      (
     )     _.-|      ___        |-._     (
      )_.-`   \   .-'   `-._    /   `-._(
               \   `-.___.--`  /
          FIH   "-._       _.-"
                    "-._.-"
'
        echo "Welcome to FIH, the friendly interactive hell"
      end
    '';

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