# direnv

From the [docs](https://github.com/direnv/direnv):

>direnv checks for the existence of a .envrc file (and optionally a .env file) in the current and parent directories. If the file exists (and is authorized), it is loaded into a bash sub-shell and all exported variables are then captured by direnv and then made available to the current shell.

- It supports hooks for all the common shells like bash, zsh, tcsh and fish. 
  * This allows project-specific environment variables without cluttering the ~/.profile file.
- It's a single static executable, so it's fast enough to be unnoticeable on each prompt.
- It's also language-agnostic and can be used to build solutions similar to rbenv, pyenv and phpenv.

1. **Install**

It's in the Fedora repo:
    
    ```
    dnf install direnv
    ```

2. **Hook it into your shell.**

- Docs have [hooks for many shells](https://github.com/direnv/direnv/blob/master/docs/hook.md).
- I'm using Bash:

    ```
    echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
    ```
- Restart your shell or do `exec bash`.

3. **Try it out**

```bash
# Create a new folder for the test
$ mkdir ~/direnv-test
$ cd ~/direnv-test

# Create a test env var within a .env file
$ echo 'TEST="this is the special test value"' > .env


# Create a new .envrc file. "dotenv" is a direnv stdlib function that loads ./.env into the environment.
$ echo 'dotenv' > .envrc
direnv: error /home/luke/direnv-test/.envrc is blocked. Run "direnv allow" to approve its content

# As a security feature, it won't work in a directory unless we allow it.
$ direnv allow
direnv: loading ~/direnv-test/.envrc
direnv: export +TEST

# Test
$ echo $TEST
this is the special test value

# Now prove the scoping works. Move out of and back into the directory.
$ direnv allow .
direnv: loading ~/direnv-test/.envrc
direnv: export +TEST
$ cd ..
direnv: unloading
$ cd direnv-test/
direnv: loading ~/direnv-test/.envrc
direnv: export +TEST
$ echo $TEST
this is the special test value
```

- What is the `dotenv` we put in the `.envrc` file? 
  * `dotenv` is a bash function defined within the direnv binary.
  * Before running `.envrc`, direnv sources its standard library into the subshell, which defines `dotenv`, `use`, `watch_file`, `path_add`, `source_up`, and a few dozen others.
  * You can read the library,it's just shell source: `direnv stdlib`
  * [https://github.com/direnv/direnv](https://github.com/direnv/direnv)

- There is a lot you can do from within the `.envrc` file:
  * [https://github.com/direnv/direnv/wiki/.envrc-Boilerplate](https://github.com/direnv/direnv/wiki/.envrc-Boilerplate)
  * [https://github.com/direnv/direnv/wiki](https://github.com/direnv/direnv/wiki)
  * [VSCode](https://github.com/direnv/direnv/wiki/VSCode)
  * [Ansible-Vault](https://github.com/direnv/direnv/wiki/Ansible-Vault)

---

# age
 
From the [GitHub](https://github.com/filosottile/age) repo:

>age is a simple, modern and secure file encryption tool, format, and Go library. It features small explicit keys, post-quantum support, no config options, and UNIX-style composability.

[Man Page](https://htmlpreview.github.io/?https://github.com/FiloSottile/age/blob/main/doc/age.1.html)

1. **Install**

- This package is also in the Fedora repo:
    
    ```
    dnf install direnv
    ```

- The age package has 3 executables, `age`, `age-inspect`, and a`ge-keygen` (plus man pages, libraries, etc).

    ```
    $ rpm -ql age
    ...
    /usr/bin/age
    /usr/bin/age-inspect
    /usr/bin/age-keygen
    ...
    ```

## Simple Encrypt and Decrypt

2. **Generate keypair**

- Create a new age keypair:

    ```
    $ age-keygen -o my_key.secret
    Public key: age1d7q8kl4mat5r66mw7zjm0q88cuelkn7ge6n83vk5gl4w9psf44zqyjnhlh
    $ cat my_key.secret 
    # created: 2026-09-08T09:19:55-05:00
    # public key: age1d7q8kl4mat5r66mw7zjm0q88cuelkn7ge6n83vk5gl4w9psf44zqyjnhlh
    AGE-SECRET-KEY-13SYH4ASD86Y6EE7Q9MNSCNWWMURTQMC5JFH90A00J6XQE2QZWGEQX96MCR
    ```

    * First two lines are comments, ignored on parse. 
    * [Bech32](https://bitcoin.org/bip/350/) encoded, which is why they are all one case and have a checksum built in.
    * Seems like age ignores umask and sets permissions to 0600, which is nice:

        ```
        $ ll
        total 20484
        -rw-------. 1 luke luke      190 Sep  8 09:34 my_key.secret
        ```

- The public key is a *deterministic function of the private key*. To prove that, we can derive it back out:

    ```
    $ echo AGE-SECRET-KEY-13SYH4ASD86Y6EE7Q9MNSCNWWMURTQMC5JFH90A00J6XQE2QZWGEQX96MCR | age-keygen -y -
    age1d7q8kl4mat5r66mw7zjm0q88cuelkn7ge6n83vk5gl4w9psf44zqyjnhlh
    ```

- "Armor" option (`-a`). 
  * From the man page: "Encrypt to an ASCII-only "armored" encoding."
  * If your're handlding the file in a way that can't handle or will mangle the binary, armoring encodes the binary data as printable ASCII. 
  * It doesn't add any security and doesn't change the cryptography. It's purely about what characters end up in the file.
  * The cost is size-- armored output runs ~ 33% larger.

> [!TIP]
> If you name age identity/secret files in a consistent pattern or naming scheme, add it to `.gitignore` before you create them.

3. **Let's make some random data to work with:**

    ```
    $ base64 /dev/urandom | head -c 20M > ./random_data
    ```

3. **Encrypt**

- Encryption uses the public key, the `age1d7q8...` string.

    ```
    age -r age1d7q8kl4mat5r66mw7zjm0q88cuelkn7ge6n83vk5gl4w9psf44zqyjnhlh -o encrypted_data.age random_data

    ```

    ```
    $ head -n 4 encrypted_data.age 
    age-encryption.org/v1
    -> X25519 iu2ZtK6epJ3UFd5ceXAmfjM73ucH4JMzw1HqX/wNqyk
    UilScjaso87hbtckuFA55kLzuHxkoG7MweUll7i+lN0
    --- jL7GmcMHPhzn5qGe9yPL8jES/o322BFgupGlMdODDG8
    ```

- `age-inspect` command, which points out the json output option.

    ```
    luke@minisforum-bd895i:~/direnv-test$ age-inspect encrypted_data.age 
    encrypted_data.age is an age file, version "age-encryption.org/v1".

    This file is encrypted to the following recipient types:
    - "X25519"

    This file doesn't use post-quantum encryption.

    Size breakdown (assuming it decrypts successfully):

        Header                       168 bytes
        Encryption overhead         5136 bytes
        Payload                 20971520 bytes
                            -------------------
        Total                   20976824 bytes

    Tip: for machine-readable output, use --json.
    ```

4. **Decrypt**

```
$ age -d -i ./my_key.secret -o decrypted_data encrypted_data.age 
$ diff -s ./decrypted_data random_data 
Files ./decrypted_data and random_data are identical

```

## Muliple Recipients
- When doing this with multiple users, the file key is encrypted with each user's public key.
- This process creates a secret that can be decrypted by two users/people, each with their own keypair.
- I suppose you could have a team use a single shared key in a password manager and skip the per-person setup. It works and it's simpler. But you wouldn't know who decrypted anything. And you lose the ability to remove one person without disrupting everyone else.

### The process
This is how the process would work if two users, Luke and Oliver, were using it.
- Luke's keypair on his machine: Two halves, public and private. Public locks, private unlocks.
- Oliver's keypair on his machine: same.
- The throwaway key: one key, no halves, secret. It locks and unlocks the file contents by itself. Random bytes, unrelated to anyone's keypair.

**Setup, done once per person**

1. LUke generates his keypair.

    ```
    age-keygen -o my_key.secret
    ```

    ```
    Public key: age1d7q8kl4mat5r66mw7zjm0q88cuelkn7ge6n83vk5gl4w9psf44zqyjnhlh
    ```

2. Oliver runs the same command on his own machine and gets his own pair.

    ```
    Public key: age1lggyhqrw2nlhcxprm67z43rta597azn8gk38fnwdk9a3v6e9acqsp4dfve
    ```

3. Oliver sends Luke his public key. *His private key never leaves his machine.*

4. Luke puts both public keys in a file. It is just a list, and `-R` reads it in the next step.

    ```
    cat > recipients.txt
    ```

    ```
    # luke
    age1d7q8kl4mat5r66mw7zjm0q88cuelkn7ge6n83vk5gl4w9psf44zqyjnhlh
    # oliver
    age1lggyhqrw2nlhcxprm67z43rta597azn8gk38fnwdk9a3v6e9acqsp4dfve
    ```

**Encrypting**

5. YLuke runs one command.

    ```
    age -R recipients.txt -o secret.age secret.txt
    ```

**Steps 6 through 10 are what that command does internally.**

6. age invents a throwaway key at random. *This happens before it even looks at the recipient list*, and the recipients have no influence on it.

7. age encrypts `secret.txt` with the throwaway key. Once, regardless of how many recipients there are.

8. age reads the public keys from `recipients.txt`.

9. For each public key in that file, age makes a locked copy of the throwaway key. Luke's public key produces one copy. Oliver's produces another. Both copies contain the same throwaway key, locked two different ways. So fifty public keys would produce fifty copies of that one key.

10. age writes those locked copies to the top of `secret.age`, followed by the encrypted contents from step 7, then forgets the throwaway key. *It now exists nowhere except inside those locked copies.*

**Decrypting**

11. Luke runs one command.

    ```
    age -d -i my_key.secret -o secret.txt secret.age
    ```

12. age reads Luke's private key from the file.

13. age tries Luke's private key against each locked copy at the top. Oliver's fails. Luke's opens! He doesn't need Oliver.

14. Out comes the throwaway key, the same random value from step 6.

15. age decrypts the contents with it, which works because it is the same key that encrypted them in step 7.

16. Oliver runs the same command with his own key file, and his copy is the one that opens for him.

    ```
    age -d -i oliver_key.secret -o secret.txt secret.age
    ```

---

# SOPS: Secrets OPerationS

[SOPS](https://github.com/getsops/sops) is an editor of encrypted files that supports YAML, JSON, ENV, INI and BINARY formats and encrypts with AWS KMS, GCP KMS, Azure Key Vault, HuaweiCloud KMS, age, and PGP.

- `age` supplies the keypairs and the multi-recipient model. 
- `direnv` supplies the mechanism that loads decrypted values into a shell on `cd` and unloads them on the way out. 
- SOPS sits between them, holding the encrypted file in a format that diffs, reviews and version-controls like source.

## Repo layout

    k8s-training/
    ├── .sops.yaml                          # creation_rules, committed
    ├── .gitattributes                      # diff drivers, committed
    ├── .gitignore
    ├── ansible/
    │   ├── ansible.cfg                     # in-repo, not ~/.ansible.cfg
    │   └── group_vars/
    │       ├── all/
    │       │   ├── main.yml                # plaintext config
    │       │   └── secrets.sops.yaml       # encrypted, committed
    │       └── load_balancers/
    │           └── secrets.sops.yaml       # keepalived auth_pass
    └── opentofu/
        ├── secrets.sops.env                # PVE token + state passphrase
        └── dev-cluster/
            └── .envrc                      # loaded by direnv

## Part 1: Install the tools and create keys

1. Install tools

  - SOPS: grab a release binary or rpm from [releases](https://github.com/getsops/sops/releases).

    ```
    wget https://github.com/getsops/sops/releases/download/v3.13.3/sops-3.13.3-1.x86_64.rpm
    sudo dnf install ./sops-3.13.3-1.x86_64.rpm
    ```

  - age and direnv are both in the Fedora repo.

    `dnf install age direnv`

2. Install the direnv shell hook.

  `direnv` doesn'thing until its hook is in your shell startup. Skip this and `.envrc` files appear to be ignored.

    ```
    echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
    exec bash
    ```

3. Create an age key.

  > [!TIP]
  > `~/.config/sops/age/keys.txt` is SOPS's default lookup path on Linux, so using it means never having to set `SOPS_AGE_KEY_FILE`.

  ```
    mkdir -p -m 700 ~/.config/sops/age
    age-keygen -o ~/.config/sops/age/keys.txt
    chmod 600 ~/.config/sops/age/keys.txt
  ```
  
  Print the public key.

    `age-keygen -y ~/.config/sops/age/keys.txt`

4. Back up the private key.

  - Password manager
  - External drive
  - printed on paper in a safe/secure place (It's only one line, so it's still practical. And paper doesn't get ransomwared).

5. Repeat on every machine that needs to decrypt.
  - One identity per machine, not one shared identity copied around. 
  - That's the whole point of the multi-recipient model from the age section. You can revoke a laptop without touching the desktop.

> [!CAUTION]
> Never paste an `AGE-SECRET-KEY-...` line into notes, tickets, chat or a repo. If one leaks, generate a new keypair, add the new public key to `.sops.yaml`, run `sops updatekeys` on every encrypted file, remove the old key, run `updatekeys` again, and treat every value the old key could reach as compromised.

## Part 2: Configure the repo

### 2.1 `.sops.yaml`

- At the Git repo root (Public keys only, safe to commit).

  ```yaml
  # Anchors keep the key list in one place and let creation_rules reference it.
  keys:
    - &workstation age1udsxx25s5n6tu976cxjlgkcuh2ax8p5xgcrjlpdw4ymjxxkfkuks0swe34
    - &laptop age1...

  creation_rules:
    - path_regex: \.sops\.(yaml|yml|json|env)$
      age:
        - *workstation
        - *laptop

  stores:
    yaml:
      indent: 2
  ```

- What's the `&`? [A YAML anchor](https://yaml.org/spec/1.2.2/#692-node-anchors). It's a feature of YAML itself, not SOPS-specific.
  * `&name` labels a node. `*name` later in the same document is an alias that refers back to it.
  * The parser substitutes the anchored value wherever the alias appears, so by the time SOPS sees the config, `*workstation` has already become the literal string `age1udsxx25s...` 
  * SOPS has no idea anchors were involved.
- Add a machine by generating its key, adding the anchor and the reference, then running `sops updatekeys` (Part 5). 

What the sections mean:

- **creation_rules** is an ordered list of rule objects.
  * **path_regex** is a [Go RE2](https://pkg.go.dev/regexp) pattern ([syntax](https://github.com/google/re2/wiki/Syntax)) matched against the path as an unanchored substring search. Ending with `$` and omitting a leading `^` means "any file anywhere in the tree whose name ends this way," which is what makes one rule work from any subdirectory without enumerating them. If omitted, the rule matches every file.
  * **age** is a list of age public keys, or a comma-separated string.
- **stores** controls how SOPS writes each supported file format out. It has nothing to do with keys, recipients, or which files get encrypted.
- **indent** uses two spaces instead of four when writing YAML.

> [!NOTE]
> SOPS can also encrypt only selected keys inside an otherwise-normal file, via `encrypted_regex`. That would let `group_vars/all/main.yml` hold public config and secrets together. Whole-file encryption is simpler to reason about, so start there.

### 2.2 Rules of the road for `.sops.yaml`

**First matching rule wins, and later rules never contribute.** 

If you add a narrower rule above the general one, files matching it get only that rule's recipients. Rules don't merge or accumulate. Order specific to general, and keep any catch-all last.

**Changing `.sops.yaml` doesn'thing to existing files.** 

Recipients are baked into each file at encryption time. Editing the config only affects files created afterwards. Existing files need `sops updatekeys`. Without that step you can believe you revoked access and be wrong.

**Config discovery follows `cwd`, not the file.** 

SOPS looks for `.sops.yaml` starting in the current working directory and walking up. Running `sops encrypt -i k8s-training/opentofu/secrets.sops.env` from your home directory finds no config, matches no creation rule, and fails with no recipients. Run SOPS from inside the repo, or pass `--config /path/to/.sops.yaml`.

**Decryption ignores `.sops.yaml` entirely.** 

SOPS reads the recipient list out of the file's own metadata, then looks for a matching identity in `SOPS_AGE_KEY`, `SOPS_AGE_KEY_FILE`, or `~/.config/sops/age/keys.txt`. That's why decryption works from any directory.

### 2.3 `.gitignore`

- A `!` pattern only re-includes a file that an earlier pattern excluded. On its own, a file of nothing but negations doesn'thing.
- `*.sops.env` needs a negation in this case, because `*.env` catches it first.

  ```gitignore
  # Plaintext secrets, never commit
  *[Ss]ecret*
  .env
  *.env
  !*.sops.env
  secrets.yaml
  secrets.yml
  secrets.json

  # age identities
  keys.txt
  *.agekey
  *.secret

  # direnv
  .direnv/
  .envrc.local
  ```

- Verify before creating anything, since `check-ignore` works on paths that don't exist yet:

    `git check-ignore -v opentofu/secrets.sops.env`

  * With `-v`, a negated match still exits 0 and prints the `!` line that matched. 
  * Without `-v`, SOPS-named files should exit 1, meaning git will track them:

    ```
    git check-ignore -q opentofu/secrets.sops.env
    echo $?      # expect 1
    ```

> [!NOTE]
> A negation can't re-include a file whose parent directory is excluded. If you ever add a directory exclusion like `secrets/`, no `!` pattern will allow files within that folder to be included.

### 2.4 Readable diffs

SOPS re-randomizes the [initialization vector](https://en.wikipedia.org/wiki/Initialization_vector) on every value it encrypts, so a full decrypt and re-encrypt cycle changes every ciphertext in the file and a diff tells you nothing about which secret moved. 

  - But, `sops edit` re-encrypts only the values you actually changed and preserves the rest byte for byte. 
  - After an edit touching one of two values, the untouched line did not appear in the diff at all. Use `sops edit`, not an editor on the raw file.

For actual plaintext diffs, add a textconv driver.

`.gitattributes` at the repo root, committed:

  ```gitattributes
  *.sops.yaml diff=sopsdiffer-yaml
  *.sops.yml  diff=sopsdiffer-yaml
  *.sops.json diff=sopsdiffer-json
  *.sops.env  diff=sopsdiffer-env
  ```

On its own that doesn't do anything. The driver name has to be bound to a command in `git config`. Because git deliberately refuses to let a checked-in file execute commands (Which is a good thing).

  ```bash
  git config diff.sopsdiffer-yaml.textconv "sops decrypt --input-type yaml --output-type yaml"
  git config diff.sopsdiffer-json.textconv "sops decrypt --input-type json --output-type json"
  git config diff.sopsdiffer-env.textconv "sops decrypt --input-type dotenv --output-type dotenv"
  ```

The `--input-type` flags are not optional. Git hands textconv a temp file, and for the pre-image side that temp file is named something like `.merge_file_a1B2c3` with no extension at all. SOPS infers format from the extension, finds none, falls back to the binary store, and fails. Pinning the type per driver removes the guess.

Then `git diff` shows this instead of two walls of base64:

```diff
-PROXMOX_VE_API_TOKEN=old-value
+PROXMOX_VE_API_TOKEN=new-value
 TF_STATE_PASSPHRASE=keep
```

- Caveats: 
  * `.gitattributes` is committed but `git config` is per-clone. So those three lines are part of new-machine onboarding (Part 6). 
  * Be aware of what you just enabled: `git diff` now prints secrets to the terminal and into the pager's scrollback. That's usually what you want on a workstation, but be careful.

## Part 3: Encrypt a file

> [!NOTE]
> Run `sops` from inside the repo, or pass `--config /path/to/.sops.yaml`.

`opentofu/secrets.sops.env` starts as a normal [env file](https://www.dotenv.org/docs/security/env.html).

  ```
  cd ~/k8s-training
  sops encrypt -i opentofu/secrets.sops.env
  ```

Result:

  ```
  $ cat opentofu/secrets.sops.env
  PROXMOX_VE_API_TOKEN=ENC[AES256_GCM,data:ntakej0Fze...,iv:w060+Vci...,tag:OicfIT6u...,type:str]
  sops_age__list_0__map_enc=-----BEGIN AGE ENCRYPTED FILE-----\n...\n-----END AGE ENCRYPTED FILE-----\n
  sops_age__list_0__map_recipient=age1udsxx25s5n6tu976cxjlgkcuh2ax8p5xgcrjlpdw4ymjxxkfkuks0swe34
  sops_lastmodified=2026-09-03T21:37:05Z
  sops_mac=ENC[AES256_GCM,data:Dsw0ePX6...,type:str]
  sops_unencrypted_suffix=_unencrypted
  sops_version=3.13.3
  ```

*Keys stay readable, values don't.*

- The flat `sops_*` lines are how the metadata block renders in dotenv format. YAML files get a nested `sops:` mapping instead. 

- This is the same envelope scheme from the age section: one random data key encrypts the payload once, then gets locked separately to each recipient's public key. 
  * Each `sops_age__list_N__map_enc` line is one of those locked copies.

### Verify before trusting it

  `grep -c map_recipient opentofu/secrets.sops.env`

Expect one line per public key in your matching creation rule. One key configured means one line. If you configured two and get one, the second key probably is wrong or a narrower rule took precedence.

  ```
  git check-ignore -q opentofu/secrets.sops.env
  echo $?      # expect 1, git will track it
  ```
  
  `sops decrypt opentofu/secrets.sops.env`

`decrypt` writes plaintext to stdout and leaves the file alone.

### Working with the file from here

**`sops edit <file>` opens the plaintext in `$EDITOR` from a temp file and re-encrypts on save, touching only what changed. That's the command to use.**

don't hand-edit the encrypted file and don't re-run `sops encrypt -i` on a file that already carries metadata. The MAC covers the values, so a manual edit fails the integrity check on the next decrypt with a MAC mismatch rather than anything that tells you what happened.

## Part 4: Load it into the shell with direnv

### 4.1 The `use_sops` helper

[https://github.com/direnv/direnv/wiki/Sops](https://github.com/direnv/direnv/wiki/Sops)

Create `~/.config/direnv/direnvrc`:

```bash
use_sops() {
    local path=${1:-$PWD/secrets.yaml}
    eval "$(sops -d --output-type dotenv "$path" | direnv dotenv bash /dev/stdin)"
    watch_file "$path"
}
```

How it works:
- Takes the file from `use sops <file>` (defaults to `secrets.yaml`)
- `sops -d --output-type dotenv` decrypts it to `KEY=value` lines
- `direnv dotenv` turns those into `export` statements
- `eval` runs them in the `.envrc` shell, and direnv captures what got exported
- `watch_file` makes direnv reload when the encrypted file changes

### 4.2 The `.envrc`

This is the piece that ties the encrypted file to your shell. 

1. Drop a one-line `.envrc` in `opentofu/`, and from then on every time you `cd` into that directory or anything under it, direnv decrypts `secrets.sops.env` and puts `PROXMOX_VE_API_TOKEN` into your environment. 

OpenTofu picks it up on its own, so `tofu plan` works with no credentials in any `.tf` file and no flags on the command line! Leave the directory and the variable is gone.

`opentofu/.envrc`:

```bash
use sops secrets.sops.env
```

2. Tell direnv to allow use in this directory. Otherwise, you'll get this: 

`direnv: error /home/luke/k8s-training/opentofu/.envrc is blocked. Run `direnv allow` to approve its content`

```
$cd ~/k8s-training/opentofu
$ direnv allow
direnv: loading ~/k8s-training/opentofu/.envrc
direnv: using sops secrets.sops.env
direnv: export +PROXMOX_VE_API_TOKEN
```

What should be happening:
  - `use sops` calls the `use_sops` function you put in `direnvrc`. 
  - The path is relative to the `.envrc`'s own directory. direnv searches the current directory and its parents, so this one file covers `dev-cluster/`, `modules/`, and anything you add later.
  - Your env variables are exported. Try an `echo $ENV_VAR`.

3. Commit the `.envrc`. It has no secrets in it. `direnv allow` is per-machine and keyed to the file's content, so editing it revokes the approval and you allow again.

### 4.3 Notes

**Only encrypt what needs it.** 

The bpg provider reads `PROXMOX_VE_ENDPOINT`, `PROXMOX_VE_API_TOKEN`, and `PROXMOX_VE_INSECURE`. Only the token is sensitive. Put other stuff in the `.envrc` as plain exports so they stay readable in diffs and code review:

```bash
export PROXMOX_VE_ENDPOINT="https://192.168.1.10:8006"
use sops secrets.sops.env
```

**Nested `.envrc` files.** 

```bash
source_up
export TF_WORKSPACE=dev
```

- direnv runs the nearest `.envrc` only. `opentofu/.envrc` covers every subdirectory, so `dev-cluster/` gets the token with no file of its own. 
- If you later add `opentofu/dev-cluster/.envrc`, it takes over and the parent stops running. *Start it with `source_up` to pull the parent in first!*

**Scope.** 

While loaded, the token sits in the environment of that shell and every process it spawns, readable from `/proc/<pid>/environ`. That's the tradeoff for having OpenTofu find it with no configuration.

### 4.4 Keeping the helper in the repo instead

`use_sops` has to be defined somewhere before `use sops` can call it. 

Putting it in `~/.config/direnv/direnvrc` means every repo on the machine can use it, but it also means a fresh machine (or a fresh install) has no `use_sops` and the `.envrc` fails with a "command not found" error until someone writes that file.

**The alternative:** Keep the function in the repo so it arrives with the clone. Put the same function body in `.direnv-lib.sh` at the repo root, then source it before calling it:

```bash
source_env_if_exists ../.direnv-lib.sh
use sops secrets.sops.env
```
> [!NOTE]
> Waht's `source_env_if_exists`? It's a direnv stdlib function, same as `use`, `watch_file`, and `dotenv`. Before direnv evaluates any `.envrc`, it sources the stdlib into that subshell, then sources `~/.config/direnv/direnvrc` on top. So the stdlib functions are always available inside a `.envrc` and inside `direnvrc`.

Cost: That the function is now repo-scoped and you copy it into the next repo. I'd pick one approach, not both.

## Part 5: Adding and removing recipients

Recipients are baked into each file at encryption time. Remember: `.sops.yaml` is only consulted when a file is first created.

Let's say we want to add another recipient, for my laptop.

1. On the laptop, generate its keypair and print the public key.
2. On a machine that already has access, add both the anchor and the reference to `.sops.yaml` .
3. Rewrite the recipient list on every existing encrypted file:

  ```
  cd ~/k8s-training
  sops updatekeys opentofu/secrets.sops.env
  sops updatekeys ansible/group_vars/all/secrets.sops.yaml
  sops updatekeys ansible/group_vars/load_balancers/secrets.sops.yaml
  ```

  - It prints the recipient diff and prompts. `-y` skips the prompt. You need a current recipient key to run it, since it decrypts and re-encrypts the data key.

4. Commit and push. Now verify:

  `grep -c map_recipient opentofu/secrets.sops.env`      # expect 2

- Removing a machine is the same sequence in reverse. 
- Understand what it does and doesn't do: 
  * It stops that key from opening future versions of the file. Anyone who already decrypted it still has the plaintext, and the old commit in git history is still readable by the old key. 
  * *Revocation is a reason to rotate the underlying secrets, not a substitute for it.*

`sops rotate -i <file>` is a different operation. 
  - It generates a brand new data key and re-encrypts the payload under it.
  - That's what you want after a suspected compromise of the file itself rather than of a recipient.

## Part 6: Onboarding a new machine

Everything above can be split into 
  - What the repo carries: `.sops.yaml`, `.gitattributes`, `.gitignore`, the encrypted files, and the `.envrc` files.None of it is secret and all of it is committed.
  - What the machine needs. Per machine, in order:
    1. Install `sops`, `age` and `direnv`.
    2. Add the direnv hook to `~/.bashrc` and `exec bash`.
    3. Restore the private key to `~/.config/sops/age/keys.txt` (mode 600, directory mode 700).
    4. Get that machine's public key into `.sops.yaml` and run `sops updatekeys` from a machine that already has access (Part 5). A fresh machine can't do this for itself.
    5. Write `~/.config/direnv/direnvrc` with the `use_sops` function.
    6. Bind the three textconv drivers with `git config` (section 2.4). Per-clone, not per-machine.
    7. Run `direnv allow` in each directory holding an `.envrc`.

> [!TIP]
> Keep this list in `docs/secrets.md` in the repo.

## Part 7: Ansible

- The direnv path covers the environment. 
- Ansible reads its secrets a different way, through a vars plugin that decrypts `group_vars` and `host_vars` at runtime.

1. Install the collection
  `ansible-galaxy collection install community.sops`

2. Put `ansible/ansible.cfg`, in the repo rather than `~/.ansible.cfg`:

  ```ini
  [defaults]
  inventory = inventory.yml
  vars_plugins_enabled = host_group_vars,community.sops.sops
  ```

  - Order matters:.
    1. Setting `vars_plugins_enabled` replaces the default list rather than adding to it. Drop `host_group_vars` and plain `group_vars/all/main.yml` stops loading entirely.
    2. `secrets.sops.yaml` ends in `.yaml`, which is a valid extension as far as `host_group_vars` is concerned, so that plugin loads the file too and hands you the ciphertext as variable values. 
    3. Vars plugins run in the order listed and later results win, so `community.sops.sops` must come after `host_group_vars`. Reverse them and every secret resolves to a literal `ENC[AES256_GCM,...]` string with no error anywhere.

3. Verify:

  ```bash
  cd ~/k8s-training/ansible
  ansible load_balancers -m debug -a 'var=keepalived_auth_pass'
  ```

- Plaintext means it is set up correctly. 
- `ENC[AES256_GCM,...]` means the ordering is probably wrong. 
- `VARIABLE IS NOT DEFINED!` means the plugin is not enabled at all, or `ansible.cfg` was not picked up because you ran from the wrong directory.

Ansible reads `ansible.cfg` from the current working directory, so run from `ansible/`. It also silently ignores a `cwd` config file if the directory is world-writable.

The `sops` binary has to be on `PATH` on the controller and the age key readable by the user running the playbook. If you keep the key somewhere other than the default path:

  ```ini
  [community.sops]
  age_key_file = ~/.config/sops/age/keys.txt
  ```