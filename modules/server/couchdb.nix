{ pkgs, ... }:

{
  services.couchdb = {
    enable = true;
    bindAddress = "0.0.0.0";
    port = 5984;
    adminUser = "admin";
    adminPass = "adminpw"; # password
    extraConfig = {
      chttpd = {
        require_valid_user = "true";
        enable_cors = "true";
        max_http_request_size = "10485760";
      };
      httpd = {
        WWW-Authenticate = "Basic realm=\"couchdb\"";
        max_document_size = "50000000";
      };
      cors = {
        credentials = "true";
        origins = "*";
      };
    };
  };

  networking.firewall.allowedTCPPorts = [ 5984 ];
}