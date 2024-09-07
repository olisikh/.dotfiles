self: super:
{
  scala = super.scala.overrideAttrs (oldAttrs: rec {
    version = "3.5.0";

    src = super.fetchurl {
      url = "https://github.com/lampepfl/dotty/releases/download/${version}/scala3-${version}.tar.gz";
      hash = "sha256-usrReGI/GUDa59dcVMdar1PxTweumYA75zCh19UaYS0=";
    };
  });
}
