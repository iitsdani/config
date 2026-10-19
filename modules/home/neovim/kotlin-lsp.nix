{ stdenvNoCC
, fetchurl
, makeWrapper
, unar
, darwin
, jdk25
, lib
, stdenv
}:

let
  version = "263.7084.0";

  # Pre-built archives by system. nix-prefetch-url to refresh hashes.
  sources = {
    "aarch64-darwin" = {
      url = "https://download.jetbrains.com/language-server/kotlin-server/${version}/kotlin-server-${version}-aarch64.sit";
      hash = "sha256-tAO/ilS9RY47pnMc+KuzNAvgi0OcA1dt/AKxP682lLg=";
    };
    "x86_64-darwin" = {
      url = "https://download.jetbrains.com/language-server/kotlin-server/${version}/kotlin-server-${version}.sit";
      hash = "sha256-spw5Ol5UEVPQPWJueUYmhDfjWKZnpfkUoSbbtAB2ZLE=";
    };
  };

  srcSpec = sources.${stdenv.hostPlatform.system}
    or (throw "kotlin-lsp: unsupported system ${stdenv.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "kotlin-lsp";
  inherit version;

  src = fetchurl srcSpec;
  dontUnpack = true;

  nativeBuildInputs = [
    makeWrapper
    unar
    darwin.sigtool
  ];

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/share" "$out/bin"

    # .sit archives need unar; tar/unzip won't touch them.
    unar -force-overwrite -output-directory "$out/share" "$src"

    # Flatten if unar produced a single wrapper directory.
    shopt -s dotglob nullglob
    entries=( "$out/share"/* )
    if [ "''${#entries[@]}" -eq 1 ] && [ -d "''${entries[0]}" ]; then
      mv "''${entries[0]}"/* "$out/share/"
      rmdir "''${entries[0]}"
    fi

    if [ ! -x "$out/share/bin/intellij-server" ]; then
      chmod +x "$out/share/bin/intellij-server" || {
        echo "kotlin-lsp: expected $out/share/bin/intellij-server to exist after extraction" >&2
        echo "kotlin-lsp: archive layout was:" >&2
        find "$out/share" -maxdepth 2 -mindepth 1 >&2
        exit 1
      }
    fi

    # Mitigate macOS Gatekeeper (kotlin-lsp issue #194).
    # Ad-hoc sign the native launcher and any bundled native libraries.
    # Strip quarantine xattrs defensively (Nix sandbox usually doesn't set
    # them, but downstream copies might).
    find "$out/share" -type f \
      \( -name "intellij-server" -o -name "*.dylib" -o -name "*.jnilib" -o -name "*.so" \) \
      -exec codesign --force --sign - {} + 2>/dev/null || true
    xattr -dr com.apple.quarantine "$out/share" 2>/dev/null || true

    # Expose the binary as `kotlin-lsp` because the version of
    # nvim-lspconfig bundled in nixpkgs (2.8.0) still uses
    # `cmd = { 'kotlin-lsp', '--stdio' }`. Upstream lspconfig has since
    # migrated to `intellij-server`; when nixpkgs picks that up, rename
    # this wrapper accordingly (and update meta.mainProgram below).
    makeWrapper "$out/share/bin/intellij-server" "$out/bin/kotlin-lsp" \
      --set JAVA_HOME "${jdk25}"

    runHook postInstall
  '';

  meta = with lib; {
    description = "Official Kotlin Language Server (JetBrains)";
    homepage = "https://github.com/Kotlin/kotlin-lsp";
    license = licenses.asl20;
    platforms = builtins.attrNames sources;
    mainProgram = "kotlin-lsp";
  };
}
