# # Download with gh (handles private repo auth)
# gh release download hammer-0.1.0 -R padoa/sre-toolchain -p 'hammer-linux-amd64' -D /tmp/hammer-dl --clobber
# # Prefetch into nix store (fetchurl will find it cached by hash)
# nix-prefetch-url file:///tmp/hammer-dl/hammer-linux-amd64
# nix hash file /tmp/hammer-dl/hammer-linux-amd64
# rm -rf /tmp/hammer-dl
# # Rebuild
# sudo nixos-rebuild switch --flake .#$(hostname)
final: prev:
let
  version = "1.1.1";
  hash = "sha256-/h+XXuKVrDN0hV59HzpEoQZZnby4cBpB65CZnKX3vI0=";

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
      description = "SRE CLI toolkit (azure, postgres, vault)";
      license = licenses.mit;
      platforms = [ "x86_64-linux" ];
    };
  };
in
{
  inherit hammer;
}
