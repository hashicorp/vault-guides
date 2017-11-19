#  Vault SSH CA backend
Manage users' remote access of Linux/Unix servers via SSH access.

## Reference Material

Typically SSH access to Linux/Unix servers is by private/public keys, and can prove difficult to manage in large environments for several reasons:

- Sprawl of keys means that provisioning or revoking keys can be slow
- Tracking and auditing use of keys is increasingly difficult as the number of managed systems grows
- Enforcing short lived credentials is impossible

In 2010, [OpenSSH introduced](http://www.openssh.com/txt/release-5.4) a method where authentication is governed by certificate authority authentication. The same cryptography used by x509 certificates can be leveraged to authenticate users. There are some interesting benefits of this technique:

- Individual user public keys do not need to be managed on all servers that a user needs access to. This reduces management overhead.
- A user's access to servers can be time bound, based on expiration of their signed key. It is now possible to enforce short lived SSH credentials at scale.

This functionality has been documented and used by a number of organizations:

- [Uber SSH Certificate Authority](https://medium.com/uber-security-privacy/introducing-the-uber-ssh-certificate-authority-4f840839c5cc) also released a related [PAM module](https://github.com/uber/pam-ussh)
- [Facebook's use of OpenSSH CA](https://code.facebook.com/posts/365787980419535/scalable-and-secure-access-with-ssh/)
- [Netflix' BLESS project](https://github.com/Netflix/bless)
- [Lyft](https://eng.lyft.com/blessing-your-ssh-at-lyft-a1b38f81629d) made use of the BLESS project and open sourced a [client side integration tool](https://github.com/lyft/python-blessclient)
- [Red Hat Enterprise Linux documentation](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html/system_administrators_guide/s1-ssh-configuration) on OpenSSH CA authentication
- [SSH protocol documentation](http://cvsweb.openbsd.org/cgi-bin/cvsweb/src/usr.bin/ssh/PROTOCOL.certkeys?rev=HEAD)
- [Another well documented page related to SSH CA authentication](https://blog.habets.se/2011/07/OpenSSH-certificates.html)
- [Another documented page with SSH CA details](https://www.lorier.net/docs/ssh-ca.html)

## Estimated Time to Complete
This exercise should only take 10-15 minutes to complete for a user familiar with Linux, SSH, on a system that has Vagrant and VirtualBox configured.

There is an included [quickstart guide](QUICKSTART.md) that has most steps automated.

## Challenge
Stand up 2 virtual machines using Vagrant, configure the Vault server with SSH CA backend, validate use of the SSH CA secret backend from a client server.
