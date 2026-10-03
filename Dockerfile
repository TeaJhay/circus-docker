FROM nixos/nix:latest

ENV NIX_CONFIG="experimental-features = nix-command flakes"

ARG CIRCUS_REV=main
# Slow layer: compiles Circus. Cached once it succeeds.
RUN nix -L profile add \
      github:manic-systems/circus/${CIRCUS_REV}#circus-server \
      github:manic-systems/circus/${CIRCUS_REV}#circus-evaluator \
      github:manic-systems/circus/${CIRCUS_REV}#circus-queue-runner \
      github:manic-systems/circus/${CIRCUS_REV}#circus-cli

# Fast layer: helper tools. Priority 6 makes the Circus packages win any file clash.
RUN nix -L profile add --priority 6 \
      nixpkgs#gettext nixpkgs#postgresql

COPY circus.toml.tpl /etc/circus.toml.tpl
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3000 22
ENTRYPOINT ["/entrypoint.sh"]
