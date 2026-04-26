{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };
  outputs =
    { nixpkgs, self, ... }:
    let
      lib = nixpkgs.lib;
      eachSystem = lib.genAttrs [
        "aarch64-darwin"
        "aarch64-linux"
        "x86_64-darwin"
        "x86_64-linux"
      ];
    in
    {
      packages = eachSystem (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          icon = pkgs.buildTypstPackage (finalAttrs: {
            pname = "icon";
            version = "0.1.0";
            src = ./icon;
          });
          mkTypstEnv =
            {
              fonts ? [ ],
              typstPackages ? { },
              typst ? pkgs.typst,
              extraTypstScripts ? { },
              ...
            }:
            let
              packages = lib.concatMapAttrs (
                namespace: lib.groupBy (package: "${namespace}/${package.pname}")
              ) typstPackages;
              fullPackages = lib.zipAttrsWith (_: p: lib.unique (lib.concatLists p)) (
                [ packages ]
                ++ lib.mapAttrsToList (
                  _: packages:
                  lib.groupBy (dep: "preview/${dep.pname}") (
                    lib.concatMap (lib.getAttr "propagatedBuildInputs") packages
                  )
                ) packages
              );
              env = {
                TYPST_FONT_PATHS = lib.escapeShellArg (lib.join ":" fonts);
                TYPST_IGNORE_SYSTEM_FONTS = "true";
                TYPST_IGNORE_EMBEDDED_FONTS = "true";
                TYPST_PACKAGE_CACHE_PATH = "$out/lib/typst/packages";
                TYPST_PACKAGE_PATH = "$out/lib/typst/packages";
              };
              mkWrapper = name: package: [
                (
                  "makeWrapper ${lib.getExe package} $out/bin/${name} "
                  + lib.concatMapAttrsStringSep " " (var: val: "--set ${var} ${val}") env
                )
                "cp --no-preserve=all -r ${package}/share/* $out/share"
              ];
            in
            pkgs.stdenvNoCC.mkDerivation {
              name = "typst-env";
              src = ./.;
              nativeBuildInputs = [ pkgs.makeBinaryWrapper ];
              installPhase = lib.join "\n" (
                lib.flatten [
                  "mkdir -p $out/bin"
                  "mkdir -p $out/lib/typst/packages"
                  "mkdir $out/share"
                  (lib.mapAttrsToList (path: packages: [
                    "mkdir -p $out/lib/typst/packages/${path}"
                    (map (
                      package:
                      "ln -s ${package}/lib/typst-packages/${package.pname}/${package.version} $out/lib/typst/packages/${path}"
                    ) packages)
                  ]) fullPackages)
                  (mkWrapper "typst" typst)
                  (lib.mapAttrsToList mkWrapper extraTypstScripts)
                ]
              );
            };
        }
      );
      devShells = eachSystem (
        system:
        let
          pkgs = import nixpkgs { inherit system; };
        in
        {
          default = pkgs.mkShellNoCC {
            name = "devshell";
            packages = with pkgs; [
              nixd
              nixfmt
              (self.packages.${system}.mkTypstEnv { extraTypstScripts = { inherit tinymist; }; })
            ];
          };
        }
      );
    };
}
