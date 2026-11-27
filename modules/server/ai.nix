
{ config, pkgs, ... }: {
  services.ollama = {
    enable = true;
    host = "127.0.0.1";
    port = 11434;

    loadModels = [
      "qwen3:0.6b"
      "qwen2.5:1.5b"
    ];
  };
}
