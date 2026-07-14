# Builds hammer from the padoa/sre-toolchain `hammer/` Go module.
#
# Pinned to the latest published hammer semver tag via the `sre-toolchain`
# flake input (currently hammer-1.1.1) — bump by retagging the input in
# flake.nix, then refresh vendorHash below.
#
# Previously this fetched a published `hammer-linux-amd64` release binary with
# fetchurl. We now build from source over SSH so it no longer depends on the
# release artifact being present.
#
# hammer's go.mod still requires github.com/padoa/stack-info-operator, a now
# *deprecated* standalone repo. Its API types live on in the padoa/stack-info
# monorepo under operator/ (module github.com/padoa/stack-info/operator), which
# we already track via the `stack-info` input for kubectl-stack. We satisfy the
# import from there with a `replace`, so the deprecated repo is never fetched.
{ inputs }:
final: prev:
let
  hammer = prev.buildGoModule {
    pname = "hammer";
    version = "1.1.1";
    src = inputs.sre-toolchain;

    # The hammer module is self-contained under hammer/ (its own go.mod, no
    # repo-level go.work), so build it directly as the module root.
    modRoot = "hammer";
    subPackages = [ "cmd/hammer" ];

    # Redirect the deprecated github.com/padoa/stack-info-operator dependency to
    # the operator API that lives on in the stack-info input. hammer only
    # consumes the self-contained api/v1alpha1 package (StackInfoSpec/Status),
    # which imports nothing but apimachinery + controller-runtime/pkg/scheme —
    # both already pinned at identical versions in hammer's go.sum.
    #
    # We stage just that package under a relative path and give it a minimal
    # go.mod listing only those two deps (matching hammer's versions), so the
    # replace adds no new modules to MVS and triggers no `go mod tidy` need.
    # Copying the operator's full go.mod instead would pull in its indirect
    # deps and force a go.mod update that the network-less build phase can't do.
    # A relative replace path also keeps the fixed-output vendor derivation free
    # of /nix/store references. postPatch is inherited by that derivation, so
    # this applies to both vendor resolution and the build; hammer's go.mod is
    # in hammer/, hence ../ .
    postPatch = ''
      mkdir -p operator-src/api/v1alpha1
      cp -r --no-preserve=mode,ownership ${inputs.stack-info}/operator/api/v1alpha1/. operator-src/api/v1alpha1/
      {
        echo 'module github.com/padoa/stack-info-operator'
        echo
        echo 'go 1.24.0'
        echo
        echo 'require k8s.io/apimachinery v0.34.2'
        echo 'require sigs.k8s.io/controller-runtime v0.22.4'
      } > operator-src/go.mod
      echo 'replace github.com/padoa/stack-info-operator => ../operator-src' >> hammer/go.mod
    '';

    vendorHash = "sha256-BDAtIZWEp2d9KYQj5hbkAkY8DE8h5RA/iG0Zn+ibkGU=";

    ldflags = [
      "-s"
      "-w"
    ];

    meta = with prev.lib; {
      description = "SRE CLI toolkit (azure, postgres, vault)";
      homepage = "https://github.com/padoa/sre-toolchain";
      license = licenses.mit;
      platforms = [ "x86_64-linux" ];
      mainProgram = "hammer";
    };
  };
in
{
  inherit hammer;
}
