# # Download with gh (handles private repo auth)
# gh release download hammer-0.1.0 -R padoa/sre-toolchain -p 'hammer-linux-amd64' -D /tmp/hammer-dl --clobber
# # Prefetch into nix store (fetchurl will find it cached by hash)
# nix-prefetch-url file:///tmp/hammer-dl/hammer-linux-amd64
# rm -rf /tmp/hammer-dl
# # Rebuild
# sudo nixos-rebuild switch --flake .#$(hostname)
final: prev:
let
  version = "0.1.0";
  hash = "sha256-US/VjP2wOy2+q4I3vHX8DfLo4MDXGtGy/SkfGXBxmaM=";

  hammerBin = prev.fetchurl {
    url = "https://github.com/padoa/sre-toolchain/releases/download/hammer-${version}/hammer-linux-amd64";
    inherit hash;
  };

  hammer = prev.stdenv.mkDerivation {
    pname = "hammer";
    inherit version;
    dontUnpack = true;
    dontBuild = true;
    installPhase = ''
      mkdir -p $out/bin
      cp ${hammerBin} $out/bin/hammer
      chmod +x $out/bin/hammer
    '';
    meta = with prev.lib; {
      description = "SRE CLI toolkit (stack navigation, azure, postgres, vault)";
      license = licenses.mit;
      platforms = [ "x86_64-linux" ];
    };
  };

  mkKubectlPlugin =
    name: subcommand:
    prev.writeShellScriptBin "kubectl-${name}" ''
      exec ${hammer}/bin/hammer stack ${subcommand} "$@"
    '';
in
{
  inherit hammer;

  kubectl-stack = prev.stdenv.mkDerivation {
    pname = "kubectl-stack";
    inherit version;
    dontUnpack = true;
    dontBuild = true;
    nativeBuildInputs = [ prev.installShellFiles ];
    installPhase = ''
      mkdir -p $out/bin
      cat > $out/bin/kubectl-stack <<WRAPPER
      #!/usr/bin/env bash
      exec ${hammer}/bin/hammer stack "\$@"
      WRAPPER
      sed -i 's/^      //' $out/bin/kubectl-stack
      chmod +x $out/bin/kubectl-stack

      ${hammer}/bin/hammer stack completion bash > completions.bash
      ${hammer}/bin/hammer stack completion zsh > completions.zsh
      ${hammer}/bin/hammer stack completion fish > completions.fish

      installShellCompletion --bash --name kubectl-stack.bash completions.bash
      installShellCompletion --zsh --name _kubectl-stack completions.zsh
      installShellCompletion --fish --name kubectl-stack.fish completions.fish
    '';
  };

  kubectl-ctx = mkKubectlPlugin "ctx" "ctx";
  kubectl-client = mkKubectlPlugin "client" "client";
}
