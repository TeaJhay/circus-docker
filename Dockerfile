FROM nixos/nix:latest

ENV NIX_CONFIG="experimental-features = nix-command flakes"

ARG CIRCUS_REV=main
RUN nix -L profile add \
      github:manic-systems/circus/${CIRCUS_REV}#circus-server \
      github:manic-systems/circus/${CIRCUS_REV}#circus-evaluator \
      github:manic-systems/circus/${CIRCUS_REV}#circus-queue-runner \
      github:manic-systems/circus/${CIRCUS_REV}#circus-cli \
      nixpkgs#gettext nixpkgs#postgresql nixpkgs#git

COPY circus.toml.tpl /etc/circus.toml.tpl
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3000 22
ENTRYPOINT ["/entrypoint.sh"]
