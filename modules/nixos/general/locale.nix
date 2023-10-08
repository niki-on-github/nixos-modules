{ lib, ... }:

{
  time.timeZone = "Europe/Berlin";

  console = {
    keyMap = "de";
  };

  i18n.defaultLocale = "de_DE.utf8";

  environment.sessionVariables = {
    XKB_DEFAULT_LAYOUT = "de";
    LANG = lib.mkForce "de_DE.UTF-8";
  };
}
