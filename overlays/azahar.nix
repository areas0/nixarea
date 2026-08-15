# azahar 2125.1.3 fails to build against the current unstable stdenv (gcc 15):
# a number of translation units — the first one hit being
# src/audio_core/cubeb_sink.cpp — call std::memset/std::memcpy without
# including <cstring>, and the newer libstdc++ no longer pulls it in
# transitively. Add the include to every offending file rather than carrying a
# patch per file. Drop this once nixpkgs ships a fixed azahar.
_final: prev: {
  azahar = prev.azahar.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      for f in $(grep -rlE 'std::(mem(set|cpy|cmp|move|chr)|str(len|cpy|cmp|ncmp))' src); do
        grep -q '#include <cstring>' "$f" || sed -i '1i #include <cstring>' "$f"
      done
    '';
  });
}
