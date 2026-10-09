{ pkgs, ... }:

{
  programs.mpv = {
    enable = true;
    config = {
      ytdl-format = "bestvideo[height<=360]+bestaudio/best";
    };
  };
}