{ lib, ... }:

{
  # Make sure that the secrets decryption happens through
  # my private GPG key.
  sops.gnupg.home = lib.mkDefault "/Users/ar3s3ru/.gnupg";
  sops.gnupg.sshKeyPaths = [ ];
  sops.age.sshKeyPaths = [ ];
}
