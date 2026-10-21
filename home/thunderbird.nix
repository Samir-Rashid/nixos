# Profile data is ~/.thunderbird, persisted in impermanence.nix.
# The password is not in nix. Create it once, mode 600:
#   sudo mkdir -p /persist/secrets
#   sudo tee /persist/secrets/mail-password
# flavor sets the IMAP/SMTP host. godsped.com is not one of the
# built-in providers; change flavor or set imap.host and smtp.host.
{ ... }:

{
  programs.thunderbird = {
    enable = true;
    profiles.default.isDefault = true;
  };

  accounts.email.accounts."Samir-Rashid@godsped.com" = {
    realName = "Samir Rashid";
    address = "Samir-Rashid@godsped.com";
    userName = "Samir-Rashid@godsped.com";
    flavor = "gmail.com";
    # The build asserts that exactly one account is primary.
    primary = true;
    thunderbird.enable = true;
    passwordCommand = "cat /persist/secrets/mail-password";
  };
}
