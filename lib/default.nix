{ pkgs }:

with pkgs.lib;
{
  makeBinPackage =
    {
      stdenv,
      fetchurl,
      lib,
      pkgs,
      pname,
      bname,
      version,
      description,
      hashes,
      nixSystem,
      libc,
      overrideStdenv ? null,
    }:
    let
      hashInfo = hashes.${nixSystem}.${libc};
      currentStdenv = if overrideStdenv == null then stdenv else overrideStdenv;
    in
    currentStdenv.mkDerivation {
      inherit pname version;

      src = fetchurl {
        url = "https://github.com/lxl66566/${pname}/releases/download/v${version}/${pname}-${hashInfo.targetSystem}.tar.gz";
        sha256 = hashInfo.sha256;
      };
      dontConfigure = true;
      dontBuild = true;
      dontCheck = true;

      unpackPhase = ''
        tar -xzf $src
      '';

      installPhase = ''
        runHook preInstall
        mkdir -p $out/bin
        install -D ${bname} $out/bin/${bname}
        runHook postInstall
      '';

      meta = with lib; {
        inherit description;
        homepage = "https://github.com/lxl66566/${pname}";
        license = licenses.mit;
        platforms = [ nixSystem ];
        maintainers = with maintainers; [ "lxl66566" ];
      };
    };
}
