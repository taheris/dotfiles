{
  lib,
  fetchFromGitHub,
  cudaPackages_13_0,
  stdenvNoCC,
  cmake,
  ninja,
  autoAddDriverRunpath,
  makeWrapper,
  bash,
  coreutils,
  jq,
  shellcheck,
  cacert,
  python3,
  runCommand,
  cudaArchitectures ? [ "89" ],
}:

let
  version = "0.1.40.1";
  cudaPackages = cudaPackages_13_0;
  src = fetchFromGitHub {
    owner = "Niko1221";
    repo = "Strata";
    rev = "v${version}";
    hash = "sha256-y+0Qn2KhyVFfQrZi1L9BzR7iqQoRHjkXO9W48VJO2QQ=";
  };
  llamaSrc = fetchFromGitHub {
    owner = "ggml-org";
    repo = "llama.cpp";
    rev = "3cf03257f219afbe7334045ff7c6a06ac68c627d";
    hash = "sha256-SRGoXa+4ACBCB3eaG9XFYhMN1i0FyPEy9Rrer+dFGYI=";
  };
  # Runtime for upstream's API server/packers and our thin model workflow.
  python = python3.withPackages (
    ps: with ps; [
      numpy
      jinja2
      regex
      pyyaml
      tqdm
      requests
      huggingface-hub
      pillow
      psutil
      # Optional upstream, but needed for actual JSON Schema validation.
      jsonschema
    ]
  );
  meta = {
    homepage = "https://github.com/Niko1221/Strata";
    license = lib.licenses.mit;
    platforms = [ "x86_64-linux" ];
  };

  # Keep the CUDA build separate so launcher changes don't recompile it.
  engine = cudaPackages.backendStdenv.mkDerivation {
    pname = "strata-engine";
    inherit version src;

    strictDeps = true;
    nativeBuildInputs = [
      cmake
      ninja
      cudaPackages.cuda_nvcc
      autoAddDriverRunpath
    ];
    buildInputs = with cudaPackages; [
      cccl
      cuda_cudart
      libcublas
    ];
    cmakeFlags = [
      "-DSTRATA_ENABLE_CUDA=ON"
      "-DSTRATA_BUILD_TESTS=OFF"
      # Upstream otherwise forces GGML_NATIVE=ON, even with -DGGML_NATIVE=OFF.
      "-DSTRATA_PORTABLE=ON"
      "-DCMAKE_CUDA_ARCHITECTURES=${lib.concatStringsSep ";" cudaArchitectures}"
      "-DSTRATA_GGML_DIR=${llamaSrc}"
    ];
    ninjaFlags = [
      "strata"
      "strata-device"
      "strata-plan"
      "strata-gguf"
    ];

    # Upstream has no install target.
    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin $out/share/strata
      install -m755 strata strata-device strata-plan strata-gguf $out/bin/
      printf '%s\n' ${
        lib.escapeShellArg (
          builtins.toJSON {
            source = "nix";
            inherit version;
            archs = map lib.toInt cudaArchitectures;
            cuda = 13;
            vision = "none";
          }
        )
      } > $out/share/strata/BUILD.json
      runHook postInstall
    '';

    # GPU/model tests belong on the target machine, not in a sandboxed build.
    doCheck = false;
    meta = meta // {
      description = "Strata CUDA inference engine";
      mainProgram = "strata";
    };
  };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "strata";
  inherit version src;

  nativeBuildInputs = [ makeWrapper ];
  dontBuild = true;

  # Keep Python resources together: upstream's imports and templates deliberately
  # use the source tree's relative layout.
  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin $out/lib/strata/engine
    ln -s ${engine}/bin/* $out/bin/
    cp -r serve tools ref data $out/lib/strata/
    cp LICENSE $out/lib/strata/
    cp ${./config.jq} $out/lib/strata/config.jq
    cp ${./models.py} $out/lib/strata/models.py
    # Reuse upstream's model choices, revisions, shard names and Unsloth checksums.
    # Importing setup.py's definitions does not run its installer.
    ${python}/bin/python3 - <<'PY' > $out/lib/strata/models.json
    import json
    import runpy
    import sys
    workflow = runpy.run_path("${./models.py}")
    json.dump(workflow["catalog"](runpy.run_path("setup.py")), sys.stdout, indent=2)
    PY
    ln -s ${engine}/bin/strata $out/lib/strata/engine/strata
    ln -s ${engine}/bin/strata-device $out/lib/strata/engine/strata-device
    cp ${engine}/share/strata/BUILD.json $out/lib/strata/engine/

    makeWrapper ${bash}/bin/bash $out/bin/strata-run \
      --add-flags ${./run.sh} \
      --set STRATA_SOURCE "$out/lib/strata" \
      --set STRATA_SERVER "$out/bin/strata-server" \
      --set STRATA_MODELS "$out/bin/strata-models" \
      --prefix PATH : ${
        lib.makeBinPath [
          coreutils
          jq
        ]
      }
    ln -s strata-run $out/bin/strata-orca
    makeWrapper ${python}/bin/python3 $out/bin/strata-models \
      --add-flags "$out/lib/strata/models.py" \
      --set STRATA_SOURCE "$out/lib/strata" \
      --set PYTHONDONTWRITEBYTECODE 1 \
      --set-default SSL_CERT_FILE ${cacert}/etc/ssl/certs/ca-bundle.crt \
      --set-default SSL_CERT_DIR ${cacert}/etc/ssl/certs \
      --prefix PATH : "$out/bin"
    # Python entry points below run unmodified upstream code.
    makeWrapper ${python}/bin/python3 $out/bin/strata-server \
      --add-flags "$out/lib/strata/serve/server.py" \
      --set PYTHONDONTWRITEBYTECODE 1 \
      --prefix PATH : /run/opengl-driver/bin \
      --prefix LD_LIBRARY_PATH : /run/opengl-driver/lib
    ${lib.concatMapStringsSep "\n"
      (tool: ''
        makeWrapper ${python}/bin/python3 $out/bin/strata-${tool.name} \
          --add-flags "$out/lib/strata/tools/${tool.file}.py" \
          --set STRATA_GGUF_PY ${llamaSrc}/gguf-py \
          --set STRATA_MTP_REVISION de4b8e4d43b917e7706784d8bb445c9af86a3540 \
          --set-default SSL_CERT_FILE ${cacert}/etc/ssl/certs/ca-bundle.crt \
          --set PYTHONDONTWRITEBYTECODE 1
      '')
      [
        {
          name = "pack";
          file = "strata_pack";
        }
        {
          name = "iq-pack";
          file = "iq_pack";
        }
        {
          name = "mtp-fetch";
          file = "mtp_fetch";
        }
        {
          name = "mtp-pack";
          file = "mtp_pack";
        }
        {
          name = "mtp-rt";
          file = "mtp_rt";
        }
      ]
    }

    runHook postInstall
  '';

  passthru = {
    inherit engine llamaSrc cudaArchitectures;
    tests.smoke =
      runCommand "strata-smoke"
        {
          nativeBuildInputs = [
            finalAttrs.finalPackage
            python
            bash
            coreutils
            jq
            shellcheck
          ];
        }
        ''
          export HOME="$TMPDIR/home"
          export PYTHONDONTWRITEBYTECODE=1
          export STRATA_GGUF_PY=${llamaSrc}/gguf-py
          mkdir -p "$HOME"
          strata-run --help > /dev/null
          strata-orca --help > /dev/null
          strata-run models --help > /dev/null
          strata-run models list > /dev/null
          strata-models info unsloth-ud-iq4_xs > /dev/null
          strata-run models download unsloth-ud-iq4_xs --dry-run > /dev/null
          if strata-run --dry-run > /dev/null 2>&1; then exit 1; fi
          test ! -e "$HOME/.local/share/strata"
          shellcheck ${./run.sh} ${./test-run.sh}
          EXPECTED_SOURCE=${finalAttrs.finalPackage}/lib/strata RUN_SCRIPT=${./run.sh} \
            bash ${./test-run.sh}
          STRATA_SOURCE=${finalAttrs.finalPackage}/lib/strata \
            PYTHONPATH=${finalAttrs.finalPackage}/lib/strata \
            ${python}/bin/python3 ${./test-models.py}
          strata-server --help > /dev/null
          strata-pack --help > /dev/null
          strata-iq-pack --help > /dev/null
          strata-mtp-fetch --help > /dev/null
          strata-mtp-pack --help > /dev/null
          strata-mtp-rt --help > /dev/null
          strata --help > /dev/null 2>&1
          cd ${finalAttrs.finalPackage}/lib/strata
          ${python}/bin/python3 -m unittest serve.test_server serve.test_security serve.test_runconfig serve.test_responses serve.test_structured
          ${python}/bin/python3 -m unittest discover -s tools -p test_iq_pack.py
          touch "$out"
        '';
  };

  meta = meta // {
    description = "Strata inference engine and API server (text-only CUDA test package)";
    mainProgram = "strata-run";
  };
})
