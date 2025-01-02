{
  pkgs,
  lib,
  config,
  ...
}:

{
  languages.zig.enable = true;

  packages = [
    pkgs.treefmt
    pkgs.reuse
  ];

  pre-commit.hooks = {
    treefmt = {
      enable = true;
      settings.formatters = [
        config.languages.zig.package
        pkgs.nixfmt-rfc-style
        pkgs.typos
        pkgs.toml-sort
      ];
    };
    reuse.enable = true;
  };

  difftastic.enable = true;
}
