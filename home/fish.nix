{ ... }:

{
  programs.fish = {
    enable = true;

    interactiveShellInit = ''
      function fish_greeting
        printf '%s\n' \
          "" \
          "                        /\\" \
          "                       /  |" \
          "                       \  o" \
          "                   _.-`/`-._" \
          "       _         _/         \_         _" \
          "      ) `-._   _/  /O\   /O\  \_   _.-\` (" \
          "     )      \`-/    \`-'   \`-'    \-`      (" \
          "     )     _.-|      ___        |-._     (" \
          "      )_.-`   \   .-'   \`._    /   \`._(" \
          "               \   \`-.___.--\`  /" \
          "          FIH   \"-._       _.-\"" \
          "                    \"-._.-\"" \
          ""
        echo "Welcome to FIH, the friendly interactive hell"
      end
    '';

   functions = {
      deploy-proteus = ''
      set host proteus
      echo "→ staging untracked files..."
      git -C ~/.dotfiles add -N .

      echo "→ dry-building $host..."
      if not sudo nixos-rebuild dry-build --flake ~/.dotfiles#$host
          echo "✗ dry-build failed — nothing committed"
          return 1
      end

      echo "→ switching $host..."
      if not sudo nixos-rebuild switch --flake ~/.dotfiles#$host
          echo "✗ switch failed — nothing committed"
          return 1
      end

      echo "→ committing + pushing..."
      cd ~/.dotfiles
      git add -A
      git commit -m "deploy($host): "(date '+%Y-%m-%d %H:%M')
      git push
      echo "✓ $host deployed and pushed"
    '';

      deploy-hermes = ''
        set host hermes
        echo "→ pulling latest..."
        cd ~/.dotfiles
        git pull --rebase

        echo "→ dry-building $host..."
        if not sudo nixos-rebuild dry-build --flake ~/.dotfiles#$host
            echo "✗ dry-build failed — aborting"
            return 1
        end

        echo "→ switching $host..."
        if not sudo nixos-rebuild switch --flake ~/.dotfiles#$host
            echo "✗ switch failed"
            return 1
        end

        echo "✓ $host deployed"
      '';

          push-proteus = ''
        set host proteus
        echo "→ pushing config for $host..."
        cd ~/.dotfiles

        git add -A
        git commit -m "update($host): "(date '+%Y-%m-%d %H:%M')
        or return 1

        git push
        or return 1

        echo "✓ $host config pushed"
      '';


    };
  };
}