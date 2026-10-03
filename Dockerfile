FROM nixos/nix:latest

ENV NIX_CONFIG="experimental-features = nix-command flakes"

ARG CIRCUS_REV=main
RUN nix -L profile add github:manic-systems/circus/${CIRCUS_REV} \
      nixpkgs#gettext nixpkgs#postgresql

COPY circus.toml.tpl /etc/circus.toml.tpl
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3000 22
ENTRYPOINT ["/entrypoint.sh"]
