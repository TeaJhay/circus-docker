FROM nixos/nix:latest

RUN nix --extra-experimental-features 'nix-command flakes' \
      profile add github:manic-systems/circus \
      nixpkgs#gettext nixpkgs#postgresql

ENV NIX_CONFIG="experimental-features = nix-command flakes"

COPY circus.toml.tpl /etc/circus.toml.tpl
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

EXPOSE 3000 22
ENTRYPOINT ["/entrypoint.sh"]
