{ lib, config, namespace, pkgs, ... }:
let
  inherit (lib) mkIf;
  inherit (lib.${namespace}) mkBoolOpt;

  cfg = config.${namespace}.dev.python;
in
{
  options.${namespace}.dev.python = {
    enable = mkBoolOpt false "Enable Python toolchain";
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      (python3.withPackages (ps: with ps; [
        # Interactive use and development
        ipython
        pytest
        debugpy

        # HTTP and API clients
        requests
        httpx

        # Configuration, validation, and templating
        pyyaml
        tomlkit
        jsonschema
        jmespath
        jinja2
        python-dotenv

        # CLI output and resilience
        click
        typer
        rich
        tenacity

        # Systems and automation
        psutil
        packaging
        gitpython
        paramiko
        docker
        boto3
        kubernetes
      ]))

      # Keep the project package manager outside the immutable Python environment.
      uv
    ];
  };
}
