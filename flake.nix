{
    inputs = {
        # nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    };

    outputs =
        { nixpkgs, ... }:
        let
            eachSystem =
                f:
                nixpkgs.lib.genAttrs nixpkgs.lib.systems.flakeExposed (system: f nixpkgs.legacyPackages.${system});
        in
            {
            devShells = eachSystem (pkgs: {
                default = pkgs.mkShell {
                    packages = with pkgs; [
                        nodejs
                        corepack
                        nodePackages.typescript
                        nodePackages.typescript-language-server
                    ];
                };
            });
        };
}
