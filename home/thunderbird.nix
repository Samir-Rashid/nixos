# TODO: add real accounts/identity; this is an empty default profile.
{ ... }:

{
  programs.thunderbird = {
    enable = true;
    profiles.default = {
      isDefault = true;
    };
  };
}
