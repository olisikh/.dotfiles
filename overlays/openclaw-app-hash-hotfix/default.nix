{ ... }:
final: prev:
let
  fixedZip = prev.fetchzip {
    url = "https://github.com/openclaw/openclaw/releases/download/v2026.4.11/OpenClaw-2026.4.11.zip";
    hash = "sha256-h7yVys9zQq0O5qL4bSsb0CRTWrWTITPtVBbbDOB7roo=";
    stripRoot = false;
  };

  fixApp = app:
    app.overrideAttrs (_: {
      src = fixedZip;
    });

  fixedOpenclawApp = fixApp prev.openclaw-app;

  fixPackageSet = packageSet:
    let
      app = fixApp packageSet.openclaw-app;
      bundle = packageSet.openclaw.override { openclaw-app = app; };
    in
    packageSet
    // {
      openclaw-app = app;
      openclaw = bundle;
    };
in
{
  openclaw-app = fixedOpenclawApp;
  openclaw = prev.openclaw.override { openclaw-app = fixedOpenclawApp; };

  openclawPackages =
    (fixPackageSet prev.openclawPackages)
    // {
      withTools = args: fixPackageSet (prev.openclawPackages.withTools args);
    };
}
