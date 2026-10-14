{ config, pkgs, ... }: {
  services.ollama = {
    enable = true;
    loadModels = [
      "llama3.2:3b"
      "qwen2.5-coder:7b"
    ];
  };
}