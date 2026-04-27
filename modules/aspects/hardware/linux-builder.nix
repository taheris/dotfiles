{ ... }:
{
  # Marker aspect — hosts that include this advertise access to a Linux
  # remote builder, letting aspects like `my.agent` opt in to packages
  # that require linux build artifacts.
  my.linux-builder = { };
}
