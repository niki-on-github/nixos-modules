{ pkgs, inputs, ... }:

{
  security.rtkit.enable = true;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  hardware.pulseaudio = {
    enable = false;
    package = pkgs.pulseaudioFull;
    support32Bit = true;
  };
}
