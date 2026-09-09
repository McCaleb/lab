# Password Manager guide

Using `community.general.bitwarden` with the `bw` CLI. 

## Installing bw

[Download](https://bitwarden.com/help/cli/#download--install) the executable, `chmod +x` it, and put it on `PATH`.

I also see other, unofficial versions out there. There's an `rbw` pagacke in the Fedora repo, written in rust.

## Authentication

1. Point the CLI at your server if you self-host.

    ```
    bw config server https://vault.example.com
    ```

2. Log in with a personal API key rather than email and password. That avoids the 2F prompt.

    ```
    export BW_CLIENTID="user.xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
    export BW_CLIENTSECRET="xxxxxxxxxxxxxxxxxxxxxxxxxxxx"
    bw login --apikey
    ```

3. *API key login authenticates the client and leaves the vault locked.* Bitwarden is zero knowledge, so the decryption key derives only from your master password and never reaches the server. An API key by itself gets you an encrypted blob. 

  Unlocking is a second step that produces the session key.

    ```
    export BW_PASSWORD='your-master-password'
    export BW_SESSION="$(bw unlock --passwordenv BW_PASSWORD --raw)"
    unset BW_PASSWORD
    ```

    - `BW_SESSION` belongs in the env of the `ansible-playbook` process. No `ansible.cfg` setting injects it. And putting it in a task's `environment:` block accomplishes nothing, because the lookup runs during controller-side templating, not inside the task. 
    * `scripts/bw-session.sh` handles the config, login, unlock, and sync and prints the export line, so `eval "$(scripts/bw-session.sh)"` covers all of it.

    - A personal API key belongs to a user account, not a system. Rotating it cuts off every CLI session using that account. 
    * For several service identities on one control node, you could give each its own account and point `BITWARDENCLI_APPDATA_DIR` at a separate directory per identity. So their `data.json` state files stay independent.

4. Run `bw lock` when the work finishes.

## Reading fields

- Item names in Bitwarden aren't unique, so the `bitwarden` lookup returns every match. A bare lookup renders as `["s3cret-value"]` rather than `s3cret-value`. Those brackets can be a pain if you're not aware of them. One option is to reduce the result every time.

    ```yaml
    {{ lookup('community.general.bitwarden', 'db-prod', field='password') | first }}
    ```

- Adding `result_count=1` turns an ambiguous match into a hard failure reading `Number of results doesn't match result_count! (0 != 1)`, in place of silently returning whichever record sorted first. Looking up by item UUID with `search='id'` is stronger, since a UUID matches at most one record (and it survives a rename).

- Field resolution order: 
  * For whatever reason, the plugin searches custom fields first, then `login`, then the top level of the item. 
  * So a *custom* field named `password` would be a mess. The custom field always wins.

- `field='totp'` returns the stored `otpauth://` URI or seed rather than a six-digit code, because *the plugin reads the item JSON directly.* Generating codes requires `bw get totp`, which the lookup doesn't call. 
- You can't get to attachments using this plugin.
- `bw` reads from a local encrypted cache, so a secret rotated in the web vault within a few minutes won't change until a sync. 
  * Pass `sync=true` on the first lookup of a run to prevent that. 
  * `scripts/bw-session.sh` syncs at unlock time.

## Credential exposure on the controller

`bitwarden` adds `--session <key>` to the `bw` argument list *only* when you pass `bw_session=` explicitly. If you go with the environment variable, command lines are readable through `ps` by any local user for the life of the process.

Environment variables don't shield a secret from root, obviously, since they are readable through `/proc/<pid>/environ`. This measure addresses other unprivileged users on the same host.

For `bw unlock --passwordfile`, create the file with mode 0600 and correct ownership before writing the password into it. Scheduled runs are cleaner under a systemd unit using `EnvironmentFile=` against a 0600 file than under a cron wrapper exporting variables. Where your systemd version supports it, `LoadCredential=` keeps the secret out of the unit's environment entirely.

## Credential exposure on the controller

Three secrets end up on the controller.

| Secret                          | Unlocks                        | If leaked                       |
|---------------------------------|--------------------------------|---------------------------------|
| `BW_CLIENTID`/`BW_CLIENTSECRET` | authentication only            | just an encrypted blob          |
| `BW_PASSWORD`                   | everything, plus the web vault | full account compromise         |
| `BW_SESSION`                    | the local vault cache          | full vault read until `bw lock` |

Where you put them matters. Anything on a command line is readable by every local user through ps. Anything in the environment is not, since /proc/<pid>/environ is mode 0400 and owned by the process owner. Confirmed both ways from a second unprivileged account.

That makes the plugin's two routes for a session key unequal. bw_session= puts --session <key> in the bw argument list, while BW_SESSION in the environment stays out of it. Use the environment variable. Neither hides anything from root, and mounting /proc with hidepid=2 closes the ps gap if you control the host.

At rest, keep the master password out of shell history, create any --passwordfile with mode 0600 before writing to it, and restrict data.json to its owner. For scheduled runs a systemd unit with EnvironmentFile= beats a cron wrapper exporting variables, and LoadCredential= keeps it out of the unit environment entirely where supported.