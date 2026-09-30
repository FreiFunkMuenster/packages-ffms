# gluon-domain-changer
Allows community administrators to change the domain and location settings of nodes by remote.

Once per hour (spread over 10 minutes, derived from the node ID) every node downloads a signed
manifest. If its `SERIAL` is newer than the last applied one, the signatures are valid and the
manifest contains an entry for the node, the node updates its location and switches to the given
domain (which reboots the node).

## site.conf
```lua
domain_changer = {
  url = 'http://example.org/domain-changer.manifest',
  pubkeys = {
    '<public key of admin1, 64 hex characters>',
  },
  good_signatures = 1, -- optional, default 1
},
```

## Manifest
The format follows the manifest of the autoupdater: a signed upper part, a line `---` and one
ECDSA signature per line below.

```
SERIAL=1759240000

# node-id;location_lat;location_lng;location_enabled;target_domain
f4f26d123456;51.9624;7.6257;1;dom2
a0b1c2d3e4f5;;;0;
---
<signature>
```

* `SERIAL` must be set before the first entry and must increase with every change
  (e.g. `date +%s`). Nodes ignore manifests with a serial that is not newer than the last
  applied one, which also prevents replaying old manifests. The download is aborted as soon as
  the serial is known to be old.
* To protect the flash, the last seen serial is kept in RAM (`/var/run/domain-changer.serial`).
  It is only written to `/etc/config/gluon-domain-changer` when the node actually applies a
  change, so publishing a new serial does not cause a flash write on every node.
* `node-id` is the node ID as shown on the map (primary MAC, colons are optional).
* Empty fields are left unchanged. `location_enabled` is `1`/`0` (or `true`/`false`).
* `target_domain` must be a domain contained in the firmware (`/lib/gluon/domains/<name>.json`).
* Lines starting with `#` are comments. The manifest may be at most 1 MiB.

## Signing
The manifest is signed like the autoupdater manifest (compatible with
[`contrib/sign.sh`](https://github.com/freifunk-gluon/gluon/blob/main/contrib/sign.sh) from Gluon)
using `ecdsautils`.

Generate a key pair once:
```sh
ecdsakeygen -s > secret.key
ecdsakeygen -p < secret.key   # public key for site.conf
```

After every change of the manifest run [`contrib/sign-manifest.sh`](contrib/sign-manifest.sh):
```sh
contrib/sign-manifest.sh secret.key domain-changer.manifest
```
It sets `SERIAL` to the current Unix timestamp (at least the old value + 1), removes the old
signatures, validates all entries, signs the manifest, verifies the signature and replaces the
file atomically. If the validation fails, nothing is changed.

If `good_signatures` is greater than 1, further admins add their signature without changing
the manifest:
```sh
contrib/sign-manifest.sh --add secret2.key domain-changer.manifest
```
