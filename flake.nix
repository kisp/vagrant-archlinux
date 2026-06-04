{
  description = "Reproducible build tooling (Packer, QEMU, ...) for the Arch Linux Vagrant/QEMU images";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      systems = [ "x86_64-linux" "aarch64-linux" ];

      # packer is BUSL-licensed, hence "unfree" in nixpkgs -> allow it.
      forAllSystems = f: nixpkgs.lib.genAttrs systems (system:
        f (import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        }));

      # Everything the host needs to drive a build/run. Note: this pins the
      # *tooling*, not the produced image -- the image still pacstraps the
      # latest Arch packages over the network at build time (see README).
      toolingFor = pkgs: with pkgs; [
        packer # the image builder
        qemu # qemu-system-x86_64 + qemu-img for the QEMU build/run
        jq # used by upload.sh
        curl
        gnumake
        coreutils
      ];
    in
    {
      devShells = forAllSystems (pkgs: {
        default = pkgs.mkShell {
          packages = toolingFor pkgs ++ [ pkgs.cacert ];

          # Make TLS work even in a fully pure shell (`nix develop -i`), where
          # the ambient SSL_CERT_FILE would otherwise be cleared and the
          # host-side HTTPS downloads (ISO, packer init, curl) would fail.
          SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";

          shellHook = ''
            # First line only via `awk 'NR==1'`, NOT `head -n1`. `packer version`
            # prints a second line (the "out of date" notice); `head -n1` closes
            # the pipe after line 1, so packer is killed by SIGPIPE mid-write and
            # never restores the terminal it had switched to raw mode -- which
            # silently leaves `nix develop` with broken echo / line editing. `awk`
            # reads to EOF, so packer (and qemu) exit cleanly and restore the tty.
            echo "vagrant-archlinux dev shell (build deps from Nix)"
            echo "  packer : $(packer version 2>/dev/null | awk 'NR==1')"
            echo "  qemu   : $(qemu-system-x86_64 --version 2>/dev/null | awk 'NR==1')"
            echo
            echo "  make init && make build         # VirtualBox/Vagrant box (uses system VirtualBox)"
            echo "  make init && make build-qemu    # QEMU qcow2 image"
            echo "  make run-qemu                   # boot the qcow2 in this terminal"
            echo "  append NIX=1 to a build to bake Nix+flakes into the image"
          '';
        };
      });

      # Convenience runners: `nix run .#build-qemu`, etc. These are NOT pure
      # builds -- they just run the existing make targets with the pinned
      # tooling on PATH, so they need /dev/kvm, network, and to be invoked from
      # the repo root (where the Makefile lives).
      apps = forAllSystems (pkgs:
        let
          mkApp = name: target: {
            type = "app";
            program = "${pkgs.writeShellApplication {
              inherit name;
              runtimeInputs = toolingFor pkgs;
              text = ''
                export SSL_CERT_FILE="${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt"
                exec make ${target} "$@"
              '';
            }}/bin/${name}";
          };
        in
        {
          build = mkApp "build" "build";
          build-qemu = mkApp "build-qemu" "build-qemu";
          run-qemu = mkApp "run-qemu" "run-qemu";
        });

      formatter = forAllSystems (pkgs: pkgs.nixpkgs-fmt);
    };
}
