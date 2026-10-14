{ config, pkgs, ... }: {
  services.ollama = {
    enable = true;
    host = "0.0.0.0";
    port = 7070;
    loadModels = [
      "llama3.2:3b"
      "qwen2.5-coder:7b"
    ];
  };
}