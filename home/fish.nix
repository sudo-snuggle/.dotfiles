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
        set target_dir ~/.dotfiles/hosts/$host

        echo "→ copying hardware-configuration.nix..."
        if test -f /etc/nixos/hardware-configuration.nix
            cp /etc/nixos/hardware-configuration.nix $target_dir/hardware-configuration.nix
        else
            echo "⚠ warning: /etc/nixos/hardware-configuration.nix not found in /etc/nixos/"
        end

        echo "→ staging untracked files..."
        git -C ~/.dotfiles add -N .

        echo "→ dry-building $host..."
        if not sudo nixos-rebuild dry-build --flake ~/.dotfiles#$host
            echo "✗ dry-build failed — cleaning up and aborting"
            rm -f $target_dir/hardware-configuration.nix
            return 1
        end

        echo "→ switching $host..."
        if not sudo nixos-rebuild switch --flake ~/.dotfiles#$host
            echo "✗ switch failed — cleaning up and aborting"
            rm -f $target_dir/hardware-configuration.nix
            return 1
        end

        echo "→ cleaning up local hardware-configuration.nix..."
        rm -f $target_dir/hardware-configuration.nix

        echo "→ committing + pushing..."
        cd ~/.dotfiles
        git add -A
        git commit -m "deploy($host): "(date '+%Y-%m-%d %H:%M')
        git push
        echo "✓ $host deployed and pushed"
    '';

    deploy-hermes = ''
    set host hermes
    set target_dir ~/.dotfiles/hosts/$host
    cd ~/.dotfiles

    echo "→ pulling latest..."
    git pull --rebase

    echo "→ copying hardware-configuration.nix..."
    if test -f /etc/nixos/hardware-configuration.nix
        cp /etc/nixos/hardware-configuration.nix $target_dir/hardware-configuration.nix
        git add -N $target_dir/hardware-configuration.nix
    else
        echo "⚠ warning: /etc/nixos/hardware-configuration.nix not found in /etc/nixos/"
    end

    echo "→ dry-building $host..."
    if not sudo nixos-rebuild dry-build --flake ~/.dotfiles#$host
        echo "✗ dry-build failed — cleaning up and aborting"
        git restore --staged $target_dir/hardware-configuration.nix 2>/dev/null
        rm -f $target_dir/hardware-configuration.nix
        return 1
    end

    echo "→ switching $host..."
    if not sudo nixos-rebuild switch --flake ~/.dotfiles#$host
        echo "✗ switch failed — cleaning up and aborting"
        git restore --staged $target_dir/hardware-configuration.nix 2>/dev/null
        rm -f $target_dir/hardware-configuration.nix
        return 1
    end

    echo "→ cleaning up local hardware-configuration.nix..."
    git restore --staged $target_dir/hardware-configuration.nix 2>/dev/null
    rm -f $target_dir/hardware-configuration.nix

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