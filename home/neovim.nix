# Home Manager's programs.neovim, not nixvim/nvf.
#
# Why this and not nixvim: you can read every line, plugins are just
# nixpkgs vimPlugins, and the lua lives in a normal nvim.lua. nixvim is
# a great next step once this file starts to hurt.
{ pkgs, ... }:

{
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;

    # Language servers / formatters on $PATH inside nvim. mason.nvim is
    # the usual "download LSPs into ~/.local" approach and fights Nix;
    # put tools here instead.
    extraPackages = with pkgs; [
      nil
      nixfmt
      ripgrep
      fd
      rust-analyzer
      gopls
      pyright
      ruff
    ];

    plugins = with pkgs.vimPlugins; [
      # Colorscheme comes from Stylix (mini.base16), not catppuccin-nvim.
      lualine-nvim
      nvim-web-devicons
      which-key-nvim
      telescope-nvim
      plenary-nvim
      nvim-lspconfig
      nvim-cmp
      cmp-nvim-lsp
      cmp-buffer
      cmp-path
      luasnip
      (nvim-treesitter.withPlugins (
        p: with p; [
          bash
          fish
          json
          lua
          markdown
          go
          nix
          python
          rust
        ]
      ))
    ];

    # HM 26.05 renamed extraLuaConfig → initLua.
    initLua = builtins.readFile ./nvim.lua;
  };
}
