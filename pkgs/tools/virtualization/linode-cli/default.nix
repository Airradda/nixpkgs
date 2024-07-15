{ lib
, fetchFromGitHub
, fetchurl
, buildPythonApplication
, colorclass
, installShellFiles
, pyyaml
, requests
, setuptools
, terminaltables
, rich
, openapi3
, packaging
}:

let
  hash = "sha256-J0L+FTVzYuAqTDOwpoH12lQr03UNo5dsQpd/iUKR40Q=";
  # specVersion taken from: https://www.linode.com/docs/api/openapi.yaml at `info.version`.
  specVersion = "4.166.0";
  specHash = "sha256-rUwKQt3y/ALZUoW3eJiiIDJYLQpUHO7Abm0h09ra02g=";
  spec = fetchurl {
    url = "https://raw.githubusercontent.com/linode/linode-api-docs/v${specVersion}/openapi.yaml";
    hash = specHash;
  };

in

buildPythonApplication rec {
  pname = "linode-cli";
  version = "5.45.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "linode";
    repo = pname;
    rev = "v${version}";
    inherit hash;
  };

  patches = [
    ./remove-update-check.patch
  ];

  # remove need for git history
  prePatch = ''
    substituteInPlace setup.py \
      --replace "version = get_version()" "version='${version}',"
  '';

  postConfigure = ''
    python3 -m linodecli bake ${spec} --skip-config
    cp data-3 linodecli/
    echo "${version}" > baked_version
  '';

  nativeBuildInputs = [ installShellFiles ];

  propagatedBuildInputs = [
    colorclass
    pyyaml
    requests
    setuptools
    terminaltables
    rich
    openapi3
    packaging
  ];

  doInstallCheck = true;
  installCheckPhase = ''
    $out/bin/linode-cli --skip-config --version | grep ${version} > /dev/null
  '';

  postInstall = ''
    for shell in bash fish; do
      installShellCompletion --cmd linode-cli \
        --$shell <($out/bin/linode-cli --skip-config completion $shell)
      done
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "Linode Command Line Interface";
    changelog = "https://github.com/linode/linode-cli/releases/tag/v${version}";
    homepage = "https://github.com/linode/linode-cli";
    license = lib.licenses.bsd3;
    maintainers = with lib.maintainers; [ ryantm techknowlogick ];
    mainProgram = "linode-cli";
  };
}
