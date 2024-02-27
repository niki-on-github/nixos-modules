self: super:
{
  # required for quickemu see https://github.com/quickemu-project/quickemu/issues/722
  qemu = super.qemu.override { smbdSupport = true; };
}
