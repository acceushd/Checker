# Flake dev shell for Dioxus (Rust frontend compiled to WASM + optional Axum backend)
#
# Usage:
#   nix develop                # interactive shell
#   nix develop -c dx serve   # run a command directly
#
# This shell uses rustup so you get the exact toolchain pinned by
# rust-toolchain.toml inside your project (Dioxus frequently needs a recent
# stable, sometimes nightly for some features). The wasm32-unknown-unknown
# target is required for the web target.

{
  description = "Dioxus full-stack Rust dev shell";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            # Rust managed by rustup (respects rust-toolchain.toml)
            rustup

            # Native deps commonly needed by Rust backends (Axum/TLS, sqlx, libsql)
            pkg-config
            openssl
            sqlite
            nixfmt-tree

            # dx CLI is installed via `cargo install` on first entry (see shellHook)
          ];
          nativeBuildInputs = with pkgs; [
            pkg-config
          ];

          shellHook = ''
            export RUSTUP_HOME=$PWD/.rustup
            export CARGO_HOME=$PWD/.cargo
            export PATH=$CARGO_HOME/bin:$PATH

            # Install/update pinned toolchain and the wasm target if missing
            rustup toolchain install stable --profile minimal
            rustup target add wasm32-unknown-unknown

            # dx CLI (cached in CARGO_HOME, only built once per toolchain update)
            if ! command -v dx >/dev/null 2>&1; then
              echo "Installing Dioxus CLI (dx)..."
              cargo install dioxus-cli --locked
            fi

            echo "Dioxus dev shell ready. Try: dx serve / dx serve --platform fullstack"
          '';
        };
      }
    );
}
