{ lib, tailscale }:

# Removal tracker: df-ebl (includes native/source-worker acceptance criteria).
# Upstream: https://github.com/tailscale/tailscale/issues/6130
# Remove when packaged upstream discovers NextDNS endpoints through profiled DoH
# (not unprofiled UDP), and ordinary-DNS + signed source-worker checks pass without
# this override. PR19073 is related, but its UDP bootstrap is not applied here.
assert lib.assertMsg
  (builtins.elem tailscale.version [
    "1.102.4"
    "1.102.5"
  ])
  "Re-review/remove the NextDNS workaround for this Tailscale version: https://github.com/tailscale/tailscale/issues/6130";

tailscale.overrideAttrs (old: {
  patches = (old.patches or [ ]) ++ [ ./profiled-nextdns-bootstrap.patch ];

  postPatch = (old.postPatch or "") + ''
    cp ${./nextdns_bootstrap.go} net/dns/resolver/nextdns_bootstrap.go
    cp ${./nextdns_bootstrap_test.go} net/dns/resolver/nextdns_bootstrap_test.go
  '';

  # Only the deterministic, offline workaround tests: upstream's full suite is
  # intentionally disabled by nixpkgs because it needs networking/root and flakes.
  doCheck = true;
  checkPhase = ''
    runHook preCheck
    go test -tags=${lib.escapeShellArg (lib.concatStringsSep "," (old.tags or [ ]))} \
      ./net/dns/resolver -run '^TestNextDNSBootstrap' -count=1
    runHook postCheck
  '';
})
