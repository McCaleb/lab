# Bitwarden with Ansible

Reading secrets from Bitwarden.

Bitwarden sells two different products under one brand, and `community.general` ships a separate lookup plugin for each.
- Password Manager is a shared vault for people
- Secrets Manager is a credential store for machines.

There is an unofficial, community-built server that speaks Bitwarden's API-- [Vaultwarden](https://github.com/dani-garcia/vaultwarden). It's not made by Bitwarden, but they seem to tolerate it.
## Choosing a plugin
These are like two separate services sold by the same company.

**Password Manager** is the Bitwarden most people use and know.

**Secrets Manager** is a newer, separate product made for machines and CI pipelines (*closer in spirit, I think, to HashiCorp Vault*).

| Property        | Password Manager              | Secrets Manager                               |
|-----------------|-------------------------------|-----------------------------------------------|
| Lookup plugin   | `community.general.bitwarden` | `community.general.bitwarden_secrets_manager` |
| **CLI binary**  | `bw`                          | `bws`                                         |
| Credential      | `BW_SESSION`                  | `BWS_ACCESS_TOKEN`                            |
| Unlock step     | required                      | none                                          |
| Find secrets by | item name or UUID             | secret UUID                                   |
| Lookup returns  | list of matches               | single dict                                   |
| Reduce with     | the `first` filter            | `.value`                                      |
| Vaultwarden     | supported                     | not supported                                 |
| Cost            | any plan                      | paid add-on                                   |

**[Password Manager guide](password-manager.md)**

**[Secrets Manager guide](secrets-manager.md)**

## Install collection

```
ansible-galaxy collection install -r requirements.yml
```

## Cost at scale

- Each lookup reference spawns two CLI processes on the controller. 
  * `bw` runs `status` before every query
  * `bws` runs `--version` before every fetch (to choose its command syntax?)

- Per-host evaluation
  * Variables defined in `group_vars` resolve once per host, *not* once per play. Measured against five hosts referencing a single lookup variable, the controller made ten `bw` invocations. 
  * At 500 hosts that becomes 1,000 subprocess spawns to fetch one password. For `bws` that is also 500 API calls, since it fetches over the network every time. `bw` reads its local cache, so it costs process spawns rather than vault traffic.

Resolving once with `run_once: true` fixes it (measured: ten invocations down to two). The fact propagates to every host in the play, and no `delegate_to` is required, since the lookup already runs on the controller.

## Don't make secret facts cacheable

- Adding `cacheable: true` to a `set_fact` that holds a secret writes the plaintext value to the fact cache backend, and `no_log: true` *does not prevent it*. 
- I ran that with `cacheable: true` and the `jsonfile` cache plugin. It create a 0644 file on containing the password in the clear, along with the source path and line number of the lookup that fetched it. Yikes.
- Redis backends carry the same exposure without the file permissions problem. Leave secret facts uncacheable and let them expire with the play.

## Logs and no_log

Ansible doesn't mask lookup output. You need to apply `no_log: true` to any task with a secret.

When `ANSIBLE_LOG_PATH` is set, look at giving the file mode 0600 and the ownership of the account running the playbook.

## AAP

The `bw` or `bws` binary has to be built into the execution environment image, since the lookup runs inside the EE container.

Inject the token through a custom credential type that sets `BWS_ACCESS_TOKEN` as an environment variable. 

`BW_SESSION` seems to be a bad fit for AAP, because session keys need an unlock step that requires the master password. And a platform built to hand out scoped credentials has no good place to keep one. 
