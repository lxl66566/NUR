{
  stdenv,
  fetchurl,
  lib,
  pkgs,
  mylib,
}:

let
  makeBinPackage = mylib.makeBinPackage;

  pname = "git-simple-encrypt";
  bname = "git-se";
  version = "1.5.0";
  description = "Encrypt/decrypt files in git repo using one password";

  hashes = {
    x86_64-linux = {
      gnu = {
        targetSystem = "x86_64-unknown-linux-gnu";
        sha256 = "0ilbh02ylqrz6qhplx8wkr0fi1427vj33q88y99933vbsykj4w8r";
      };
      musl = {
        targetSystem = "x86_64-unknown-linux-musl";
        sha256 = "0n2zkn63dyw9yg5snqfr5ki52wrb4x7lwgvds3q5c8d792lsi0ix";
      };
    };
    aarch64-linux = {
      gnu = {
        targetSystem = "aarch64-unknown-linux-gnu";
        sha256 = "0kkn9537smvg6ja5xdzmm661fw0r2pmswl20q1wcfb8xnyk16wyy";
      };
      musl = {
        targetSystem = "aarch64-unknown-linux-musl";
        sha256 = "14lfj15mn9mfzia2g1zv4rkdbkvx7ysd8lxwjp6zjk38m3hlg654";
      };
    };
  };

  gnu = makeBinPackage {
    inherit
      stdenv
      fetchurl
      lib
      pkgs
      pname
      bname
      version
      description
      hashes
      ;
    nixSystem = stdenv.hostPlatform.system;
    libc = "gnu";
  };

  musl = makeBinPackage {
    inherit
      stdenv
      fetchurl
      lib
      pkgs
      pname
      bname
      version
      description
      hashes
      ;
    nixSystem = pkgs.stdenv.hostPlatform.system;
    libc = "musl";
    overrideStdenv = pkgs.pkgsStatic.stdenv;
  };

  packages = lib.mapAttrs (
    nixSystem: libcMap:
    lib.mapAttrs (
      libc: _:
      makeBinPackage {
        inherit
          stdenv
          fetchurl
          lib
          pkgs
          pname
          bname
          version
          description
          hashes
          nixSystem
          libc
          ;
        overrideStdenv = if libc == "musl" then pkgs.pkgsStatic.stdenv else null;
      }
    ) libcMap
  ) hashes;

in

gnu.overrideAttrs (oldAttrs: {
  passthru = {
    inherit musl packages;
  };
})
