# Grok Build CLI. nixpkgs in this flake's pin is still 0.2.93; you already
# run 1.0.x from the official installer. Overlay this over pkgs.grok-build.
#
# In-app `grok update` cannot write the Nix store. Bump `version` + `hash`
# from https://x.ai/cli/stable and:
#   nix-prefetch-url https://x.ai/cli/grok-${version}-linux-x86_64
{
  lib,
  stdenvNoCC,
  fetchurl,
  installShellFiles,
  autoPatchelfHook,
  versionCheckHook,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "grok-build";
  version = "1.0.34";

  src = fetchurl {
    url = "https://x.ai/cli/grok-${finalAttrs.version}-linux-x86_64";
    hash = "sha256-vlkF4QfSuLXzwULSHs/kyP0yqRPS/VUbeIcHkwxNyA0=";
  };

  strictDeps = true;
  dontUnpack = true;
  dontBuild = true;

  nativeBuildInputs = [
    installShellFiles
    autoPatchelfHook
  ];

  installPhase = ''
    runHook preInstall

    install -Dm755 "$src" "$out/bin/grok"
    ln -s grok "$out/bin/agent"

    ${lib.optionalString (stdenvNoCC.buildPlatform.canExecute stdenvNoCC.hostPlatform) ''
      installShellCompletion --cmd grok \
        --bash <("$out/bin/grok" completions bash) \
        --fish <("$out/bin/grok" completions fish) \
        --zsh <("$out/bin/grok" completions zsh)
    ''}

    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";

  installCheckPhase = ''
    runHook preInstallCheck
    test -L "$out/bin/agent"
    [ "$(readlink -f "$out/bin/agent")" = "$(readlink -f "$out/bin/grok")" ]
    runHook postInstallCheck
  '';

  meta = {
    description = "Command-line coding agent by xAI";
    homepage = "https://docs.x.ai/build/overview";
    downloadPage = "https://x.ai/cli/stable";
    license = lib.licenses.unfreeRedistributable;
    platforms = [ "x86_64-linux" ];
    mainProgram = "grok";
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
