# Secrets Manager guide

Using `community.general.bitwarden_secrets_manager` with the `bws` CLI.

You have to pay to use the Secrets Manager add-on, and Vaultwarden doesn't implement it.

## Installing bws

Take a release binary from the `bitwarden/sdk-sm` repository, or run the published container image `ghcr.io/bitwarden/bws`. A `bws` crate does exist on crates.io, but installing through `cargo` puts a full Rust toolchain on your control node, which is a heavier dependency than the Node runtime you were trying to avoid.

Anyone on the EU cloud or a self-hosted server has to point the CLI at it before anything works, in the same way `bw config server` works for the Password Manager CLI.

```
bws config server-base https://vault.example.com
```

That writes to `~/.config/bws/config`. The CLI also keeps encrypted state files under `~/.config/bws/state` that cache auth tokens and reduce rate limiting. Leave them on. Every Ansible lookup opens a separate `bws` session, and Bitwarden rate limits many short sessions arriving from one IP address.

Verify with `bws --version`.

## Authentication

Create a machine account in the web vault, grant it read access to the project holding your secrets, and generate an access token.

```
export BWS_ACCESS_TOKEN="0.xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx.xxxxxxxx:xxxxxxxx"
```

There is no unlock step. The token carries what the CLI needs to decrypt, so no master password enters the pipeline. Access is scoped to whatever the machine account can read, and revoking a token leaves other machine accounts untouched.

The plugin also takes `bws_access_token=` as a keyword parameter, which lets one play use several machine accounts.

Rate limiting is handled for you. The plugin retries up to three times with exponential backoff starting at one second, and only for rate limiting. Every other non-zero exit fails the task immediately with the CLI's stderr attached.

## Reading secrets

Terms are secret UUIDs. There is no search by name, so the ambiguity that forces a `first` filter on the Password Manager side does not arise here.

A single-term lookup collapses to one dict, so `.value` reads the secret directly.

```yaml
{{ lookup('community.general.bitwarden_secrets_manager', '2bc23e48-4932-40de-a047-5524b7ddc972').value }}
```

The dict also carries `id`, `key`, `note`, and `projectId` for cases where the metadata is the point rather than the secret.

```yaml
{{ lookup('community.general.bitwarden_secrets_manager', '2bc23e48-4932-40de-a047-5524b7ddc972').key }}
```

## Credential exposure on the controller

`bitwarden_secrets_manager` always passes `--access-token <token>` on the `bws` command line, including when the value came from `BWS_ACCESS_TOKEN`, and offers no option to suppress it. Confirmed by logging the arguments of a real lookup. Treat that token as visible through `ps` to every local user on a shared control node for the life of each process.

A dedicated automation host with no interactive logins removes the problem. Environment variables do not shield a secret from root either, since they are readable through `/proc/<pid>/environ`. These measures address other unprivileged users on the same host.
