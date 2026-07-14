# Builds kubectl-stack from the padoa/stack-info `cli/` module.
#
# Tracks main via the `stack-info` flake input — bump with:
#   nix flake update stack-info
#
# Once cli-vX.Y.Z release tags + binaries land on the upstream repo, this
# overlay can be switched to fetchurl on the published binary, the same way
# overlays/hammer.nix does for hammer.
{ inputs }:
final: prev:
let
  src = inputs.stack-info;

  kubectl-stack = prev.buildGoModule {
    pname = "kubectl-stack";
    # Until upstream tags releases, surface the pinned commit so the binary's
    # --version output is traceable to a specific revision.
    version = "0.0.0-${builtins.substring 0 7 (src.rev or "unknown")}";
    inherit src;

    modRoot = "cli";
    subPackages = [ "cmd/kubectl-stack" ];

    # Repo's top-level go.work pulls in api/ and operator/ — workspace mode
    # would try to resolve all three. We only build cli/ with its own
    # `replace github.com/padoa/stack-info/operator => ../operator`.
    env.GOWORK = "off";

    vendorHash = "sha256-/VkDZD+nFXRmBFXVTQLbaX24bDjSKZ9W4oTlOwoDLG0=";

    ldflags = [
      "-s"
      "-w"
      "-X"
      "main.version=${kubectl-stack.version}"
    ];

    nativeBuildInputs = [ prev.installShellFiles ];

    postInstall = ''
      $out/bin/kubectl-stack completion bash > completions.bash
      $out/bin/kubectl-stack completion zsh  > completions.zsh
      $out/bin/kubectl-stack completion fish > completions.fish
      installShellCompletion --bash --name kubectl-stack.bash completions.bash
      installShellCompletion --zsh  --name _kubectl-stack       completions.zsh
      installShellCompletion --fish --name kubectl-stack.fish   completions.fish
    '';

    meta = with prev.lib; {
      description = "kubectl plugin for navigating Padoa multi-tenant stacks";
      homepage = "https://github.com/padoa/stack-info";
      license = licenses.mit;
      platforms = platforms.linux ++ platforms.darwin;
      mainProgram = "kubectl-stack";
    };
  };

  # Convenience wrappers — these used to live in overlays/hammer.nix invoking
  # `hammer stack <subcmd>`. The standalone binary now exposes the same
  # subcommands directly.
  mkSubcommandWrapper =
    name: subcommand:
    prev.writeShellScriptBin "kubectl-${name}" ''
      exec ${kubectl-stack}/bin/kubectl-stack ${subcommand} "$@"
    '';
in
{
  inherit kubectl-stack;
  kubectl-ctx = mkSubcommandWrapper "ctx" "ctx";
  kubectl-client = mkSubcommandWrapper "client" "client";
}
