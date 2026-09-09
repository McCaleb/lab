# ToC

[age](#age)
[direnv](#direnv)
[SOPS](#SOPS)

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
  * You can read the library, it's just shell source: `direnv stdlib`
  * [https://github.com/direnv/direnv](https://github.com/direnv/direnv)

- There is a lot you can do from within the `.envrc` file:
  * [https://github.com/direnv/direnv/wiki/.envrc-Boilerplate](https://github.com/direnv/direnv/wiki/.envrc-Boilerplate)
  * [https://github.com/direnv/direnv/wiki](https://github.com/direnv/direnv/wiki)
  * [VSCode](https://github.com/direnv/direnv/wiki/VSCode)
  * [Ansible-Vault](https://github.com/direnv/direnv/wiki/Ansible-Vault)

---

# age
 
From the [GitHub](https://github.com/FiloSottile/age) repo:

>age is a simple, modern and secure file encryption tool, format, and Go library. It features small explicit keys, post-quantum support, no config options, and UNIX-style composability.

[Man Page](https://htmlpreview.github.io/?https://github.com/FiloSottile/age/blob/main/doc/age.1.html)

## Simple Encrypt and Decrypt

1. **Install**

- This package is also in the Fedora repo:
    
    ```
    dnf install age
    ```

- The age package has three executables, `age`, `age-inspect`, and `age-keygen` (plus man pages, libraries, etc).

    ```
    $ rpm -ql age
    ...
    /usr/bin/age
    /usr/bin/age-inspect
    /usr/bin/age-keygen
    ...
    ```

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
    * [Bech32](https://bitcoin.org/bip/173/) encoded, which is why they are all one case and have a checksum built in.
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
  * If you're handling the file in a way that can't handle or will mangle the binary, armoring encodes the binary data as printable ASCII. 
  * It doesn't add any security and doesn't change the cryptography. It's purely about what characters end up in the file.
  * The cost is size. Armored output runs about 33% larger.

> [!TIP]
> If you name age identity/secret files in a consistent pattern or naming scheme, add it to `.gitignore` before you create them.

3. **Let's make some random data to work with:**

    ```
    $ base64 /dev/urandom | head -c 20M > ./random_data
    ```

4. **Encrypt**

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
    $ age-inspect encrypted_data.age 
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

5. **Decrypt**

```
$ age -d -i ./my_key.secret -o decrypted_data encrypted_data.age 
$ diff -s ./decrypted_data random_data 
Files ./decrypted_data and random_data are identical

```

## Multiple Recipients
- When doing this with multiple users, the file key is encrypted with each user's public key.
- This process creates a secret that can be decrypted by two users/people, each with their own keypair.
- I suppose you could have a team use a single shared key in a password manager and skip the per-person setup. It works and it's simpler. But you wouldn't know who decrypted anything. And you lose the ability to remove one person without disrupting everyone else.

### The process
This is how the process would work if two users, Luke and Oliver, were using it.
- Luke's keypair on his machine: two halves, public and private. Public locks, private unlocks.
- Oliver's keypair on his machine: same.
- The throwaway key: one key, no halves, secret. It locks and unlocks the file contents by itself. Random bytes, unrelated to anyone's keypair.

**Setup, done once per person**

1. Luke generates his keypair.

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

5. Luke runs one command.

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

# SOPS 

[Secrets OPerationS (SOPS)](https://github.com/getsops/sops) is an editor of encrypted files that supports YAML, JSON, ENV, INI and BINARY formats and encrypts with AWS KMS, GCP KMS, Azure Key Vault, HuaweiCloud KMS, age, and PGP.

- `age` supplies the keypairs and the multi-recipient model. 
- `direnv` supplies the mechanism that loads decrypted values into a shell on `cd` and unloads them on the way out. 
- SOPS sits between them, holding the encrypted file in a format that diffs, reviews and version-controls like source.

## Repo layout

This guide will use my k8s training repo as an example for SOPS deployment.

```
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
      ├── .envrc                          # loaded by direnv
      ├── secrets.sops.env                # PVE token + state passphrase
      └── dev-cluster/
```

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

  `direnv` does nothing until its hook is in your shell startup. Skip this and `.envrc` files appear to be ignored.

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

- At the Git repo root, create `.sops.yaml` (public keys only, safe to commit).

  ```yaml
  # Anchors keep the key list in one place and let creation_rules reference it.
  keys:
    - &workstation age1udsxx25s5n6tu976cxjlgkcuh2ax8p5xgcrjlpdw4ymjxxkfkuks0swe34

  creation_rules:
    - path_regex: \.sops\.(yaml|yml|json|env)$
      age:
        - *workstation

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

**Changing `.sops.yaml` does nothing to existing files.** 

Recipients are baked into each file at encryption time. Editing the config only affects files created afterwards. Existing files need `sops updatekeys`. Without that step you can believe you revoked access and be wrong.

**Config discovery follows `cwd`, not the file.** 

SOPS looks for `.sops.yaml` starting in the current working directory and walking up. Running `sops encrypt -i k8s-training/opentofu/secrets.sops.env` from your home directory finds no config, matches no creation rule, and fails with no recipients. Run SOPS from inside the repo, or pass `--config /path/to/.sops.yaml`.

**Decryption ignores `.sops.yaml` entirely.** 

SOPS reads the recipient list out of the file's own metadata, then looks for a matching identity in `SOPS_AGE_KEY`, `SOPS_AGE_KEY_FILE`, or `~/.config/sops/age/keys.txt`. That's why decryption works from any directory.

### 2.3 `.gitignore`

- A `!` pattern only re-includes a file that an earlier pattern excluded. On its own, a file of nothing but negations does nothing.
- The encrypted files are meant to be committed, so each extension needs a negation. `*[Ss]ecret*` catches every `secrets.sops.*` name, and `*.env` catches the dotenv file on top of that.

  ```gitignore
  # Plaintext secrets, never commit
  .env
  *.env
  secrets.yaml
  secrets.yml
  secrets.json

  # SOPS-encrypted files, safe to commit
  !*.sops.env
  !*.sops.yaml
  !*.sops.yml
  !*.sops.json

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

For actual plaintext diffs, add a textconv driver. Create `.gitattributes` at the repo root, committed:

  ```gitattributes
  *.sops.yaml diff=sopsdiffer-yaml
  *.sops.yml  diff=sopsdiffer-yaml
  *.sops.json diff=sopsdiffer-json
  *.sops.env  diff=sopsdiffer-env
  ```

On its own that doesn't do anything. The driver name has to be bound to a command in `git config`. Because git deliberately refuses to let a checked-in file execute commands (which is a good thing).

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

Caveats: 
  -  `.gitattributes` is committed but `git config` is per-clone. So those three lines are part of onboarding (Part 6), once per clone. 
  - Be aware of what you just enabled: `git diff` now prints secrets to the terminal and into the pager's scrollback. That's usually what you want on a workstation, but be careful.

## Part 3: Encrypt a file

> [!TIP]
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
  TF_STATE_PASSPHRASE=ENC[AES256_GCM,data:9pQm2rLd...,iv:Kx41mQav...,tag:2bTuwEc9...,type:str]
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

- Expect one line per public key in your matching creation rule. One key configured means one line. 
- If you configured two and get one, the second key probably is wrong or a narrower rule took precedence.

  ```
  git check-ignore -q opentofu/secrets.sops.env
  echo $?      # expect 1, git will track it
  ```
  
  `sops decrypt opentofu/secrets.sops.env`

- `decrypt` writes plaintext to stdout and leaves the file alone.

### Working with the file from here

**`sops edit <file>` opens the plaintext in `$EDITOR` from a temp file and re-encrypts on save, touching only what changed. That's the command to use.**


> [!CAUTION]
> Don't hand-edit the encrypted file, use `sops edit <file>`. And don't re-run `sops encrypt -i` on a file that already carries metadata. The [MAC](https://en.wikipedia.org/wiki/Message_authentication_code) covers the values, so a manual edit fails the integrity check on the next decrypt with a MAC mismatch rather than anything that tells you what happened.

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

```
direnv: error /home/luke/k8s-training/opentofu/.envrc is blocked. Run "direnv allow" to approve its content
```

```
$ cd ~/k8s-training/opentofu
$ direnv allow
direnv: loading ~/k8s-training/opentofu/.envrc
direnv: using sops secrets.sops.env
direnv: export +PROXMOX_VE_API_TOKEN +TF_STATE_PASSPHRASE
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
> What's `source_env_if_exists`? It's a direnv stdlib function, same as `use`, `watch_file`, and `dotenv`. Before direnv evaluates any `.envrc`, it sources the stdlib into that subshell, then sources `~/.config/direnv/direnvrc` on top. So the stdlib functions are always available inside a `.envrc` and inside `direnvrc`.

The cost is that the function is now repo-scoped and you copy it into the next repo. I'd pick one approach, not both.

## Part 5: Adding and removing recipients

Recipients are baked into each file at encryption time. Remember: `.sops.yaml` is only consulted when a file is first created.

Let's say we want to add another recipient, for my laptop.

1. On the laptop, generate its keypair and print the public key.
2. On a machine that already has access, add both the anchor and the reference to `.sops.yaml`.
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
  - What the repo carries: `.sops.yaml`, `.gitattributes`, `.gitignore`, the encrypted files, and the `.envrc` files. None of it is secret and all of it is committed.
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

# SOPS and Ansible

- The direnv path covers the environment. OpenTofu wants its token in a variable, so the shell is the right place to put it.
- Ansible, however, *reads its secrets a different way*...through a vars plugin that decrypts `group_vars` and `host_vars` at runtime.
- Decryption happens on the controller, inside the process running `ansible` or `ansible-playbook`. Nothing gets installed on the managed hosts and the age key never leaves the controller.

## 1: Install the collection

`community.sops` is not part of `ansible-core` (The full `ansible` package does bundle it, though).

  ```
  ansible-galaxy collection list community.sops
  ```

1. Install it for your user:

  ```
  ansible-galaxy collection install community.sops
  ```

  It (probably) lands in `~/.ansible/collections/ansible_collections/community/sops/`, which is outside the repo and outside git.

2. Pin it in the repo so a fresh environment knows what it needs. 
  - In `ansible/requirements.yml`:

    ```yaml
    collections:
      - name: community.sops
        version: ">=2.0.0"
    ```

    ```
    cd ~/k8s-training/ansible
    ansible-galaxy collection install -r requirements.yml
    ```

  - Best practice is to pin the version you actually tested against. The version that matters is the one old enough to still call the pre-3.9 sops CLI, since SOPS moved to `encrypt`/`decrypt`/`edit` subcommands and the collection learned about that later. `ansible-galaxy collection list community.sops` tells you what you have.

> [!NOTE]
> The version you choose might really matter. You may have to choose old enough to still call the pre-3.9 sops CLI, since SOPS moved to `encrypt`/`decrypt`/`edit` subcommands and the collection didn't adapt to that until later. `ansible-galaxy collection list community.sops` tells you what you have.

- The collection shells out to the `sops` binary instead of reimplementing it. *So `sops` has to be on `PATH` for whoever runs the playbook*, and that same user has to be able to read the age key.

## 2: Configure `ansible.cfg`

`ansible/ansible.cfg`:

  ```ini
  [defaults]
  inventory = inventory.yml
  vars_plugins_enabled = host_group_vars,community.sops.sops
  ```

**Know which config file you actually using by running `ansible--version`!** 

> [!TIP]
> Ansible refuses to load `ansible.cfg` out of the current directory when that directory is world-writable. And the errors make it tough to determine why.

**Both plugins, with `community.sops.sops` last.**

  1. `vars_plugins_enabled` replaces the default list rather than adding to it. The default is `host_group_vars` on its own, so leaving it out here stops `group_vars/all/main.yml` from loading at all.
  2. `secrets.sops.yaml` ends in `.yaml`, which is an extension `host_group_vars` accepts, so that plugin reads the encrypted file too and hands you `ENC[AES256_GCM,...]` strings as variable values.
  3. Each plugin's results are merged in the order the plugins ran and the last one to set a key wins. Current ansible-core runs them in the order you list them here, so `community.sops.sops` goes last and its decrypted values land on top of the ciphertext.

> [!TIP]
> Older ansible-core versions *appended* collection plugins after the built-in ones, regardless of what the list said. That's why you'll find people saying the order doesn't matter. But it does now.

One visible side effect of `host_group_vars` reading the file too: 
  - You end up with a variable named `sops` holding that file's own metadata, because the decrypted data has no such key to overwrite it with. 
  - It's harmless, and it can be useful. If `sops` is defined and your secret is plaintext, both plugins ran and the right one "won".

## 3: Create an encrypted `group_vars` file

The file has to end in `.sops.yaml`, `.sops.yml` or `.sops.json`. That's what the vars plugin looks for. Hidden files are ignored.

1. Create it encrypted from the get-go. On a path that doesn't exist yet, `sops edit` says so, generates the data key, and opens `$SOPS_EDITOR` or `$EDITOR` on a template. Nothing plaintext is ever written to the repo.

  ```
  cd ~/k8s-training
  mkdir -p ansible/group_vars/load_balancers
  sops edit ansible/group_vars/load_balancers/secrets.sops.yaml
  ```

  Replace the sample content with your own. Top-level keys become variable names:

  ```yaml
  keepalived_auth_pass: spaghettiPolicy
  ```

  Same command edits it from then on. Run it from inside the repo so SOPS finds `.sops.yaml` and the creation rule applies.

2. If you already have the value in a plaintext file, encrypt in place instead:

  ```
  sops encrypt -i ansible/group_vars/load_balancers/secrets.sops.yaml
  ```

  Mind the gap. Between writing that file and encrypting it, a secret is sitting in the working tree under a name `.gitignore` probably does not ignore. Maybe push a `.gitignore` vefore doing it.

3. Confirm the result before you commit it.

  ```
  sops filestatus ansible/group_vars/load_balancers/secrets.sops.yaml
  ```

  Expect `{"encrypted":true}`. To count recipients in a YAML file, look for the `recipient:` keys under the `sops:` block. `map_recipient` from Part 3 is the flat dotenv rendering and won't match here:

  ```
  grep -c 'recipient:' ansible/group_vars/load_balancers/secrets.sops.yaml
  ```

  And confirm git will actually track it:

  ```
  git check-ignore -q ansible/group_vars/load_balancers/secrets.sops.yaml
  echo $?      # expect 1
  ```

The directory name under `group_vars/` is the group name, and `group_vars/` has to sit next to the inventory file or next to the playbook. `ansible/inventory.yml` alongside `ansible/group_vars/` satisfies that. A directory that doesn't match any group in the inventory is simply never applied to anything, with no error to tell you so.

> [!NOTE]
> `.sops.yaml` at the repo root is the SOPS config and is never encrypted. `secrets.sops.yaml` under `group_vars/` is an encrypted vars file. The names are nearly identical and the creation rule regex matches both, so don't let tab completion walk you into `sops encrypt -i .sops.yaml`.

## 7.4 Verify

1. Confirm the config took effect and the plugins are enabled in the right order.

  ```
  cd ~/k8s-training/ansible
  ansible-config dump --only-changed | grep -i variable_plugins
  ```

  The ini key is `vars_plugins_enabled` but the setting is named `VARIABLE_PLUGINS_ENABLED`, so grep for the setting name:

  ```
  VARIABLE_PLUGINS_ENABLED(/home/luke/k8s-training/ansible/ansible.cfg) = ['host_group_vars', 'community.sops.sops']
  ```

  If the path in the parentheses isn't the repo, nothing below this point will behave.

2. Resolve a variable the way a play would.

  ```
  ansible load_balancers -m debug -a 'var=keepalived_auth_pass'
  ```

  `debug` is an action plugin that runs on the controller, so this resolves the variable without connecting to the load balancers.

  - Plaintext means it's set up correctly. 
  - `ENC[AES256_GCM,...]` means `host_group_vars` won the merge, or the sops plugin isn't enabled at all. Check 7.2 and step 1 above. 
  - `VARIABLE IS NOT DEFINED!` means the wrong `ansible.cfg` was picked up, or the directory name under `group_vars/` doesn't match a group in the inventory. 
  - `Could not match supplied host pattern` means the group has no hosts yet, so there's nothing for the variable to attach to. Use step 3 instead until the inventory is populated. 
  - A sops error like `no key could decrypt the data` or `sops: command not found` is a key or `PATH` problem on the controller. See 7.5.

  Add `-vvvv` and the plugin narrates which files it decrypted. It's chatty, but it's the fastest way to tell "not running" from "running and losing the merge".

3. Dump the whole inventory when you want to see everything at once.

  ```
  ansible-inventory --list --yaml
  ```

  `ansible-inventory` loads vars plugins itself rather than waiting for a task to demand them, so this decrypts even on an inventory nothing has run against. It's the check that works before any host exists. The exception is an explicit `vars_stage = task`, which keeps the plugin out of this path entirely.

> [!CAUTION]
> Both of those commands print secrets to the terminal and into the pager's scrollback. Inside a playbook, you probably want to put `no_log: true` on any task that touches a decrypted value, otherwise it lands in the job output and in `ANSIBLE_LOG_PATH`.

## 7: Notes

**The key has to be wherever Ansible runs.** 

On a workstation that's `~/.config/sops/age/keys.txt` from Part 1. In AWX or AAP it's the execution environment, which needs the `sops` binary and the key both, neither of which a stock EE ships. Managed hosts need neither, since they only ever receive the decrypted value as part of a task.

**Point at the key only if it isn't in the default place.**

  ```ini
  [community.sops]
  age_keyfile = ~/.config/sops/age/keys.txt
  ```

The option is `age_keyfile`, one word, and the plugin uses it to set `SOPS_AGE_KEY_FILE` for the sops call. Exporting that variable yourself does the same job, which is one more thing direnv could carry if the key ever lives somewhere unusual.

**A file with an encrypted name and no encryption is a hard error.** 

The plugin refuses a `.sops.yaml` file that carries no SOPS metadata rather than loading it as-is, which is nearly always you forgetting to encrypt a new file. `handle_unencrypted_files` can loosen that. Encrypt the file instead.

**Decryption is cached for the run.** 

`cache` defaults to true, so each file is decrypted once however many tasks ask for it. A `sops edit` partway through a run won't be seen. By default the plugin runs on demand at task time, following the global `run_vars_plugins` setting, and `vars_stage = inventory` under `[community.sops]` moves that to a single pass right after inventory parsing instead.

**Decrypted values are ordinary Ansible variables.** 

Which means Jinja gets a look at them. A generated password containing `{{` or `{%` will be templated when it's used, and you'll get an undefined-variable error or a mangled value rather than anything that points at the real cause. Worth knowing before you paste in something from a password generator.

**The rest of the knobs live in the same section.** 

`binary`, `config_path`, `vars_cache`, `vars_stage`, `valid_extensions`, and so on. `ansible-doc -t vars community.sops.sops` lists all of them with their environment variable equivalents.

**The vars plugin only ever looks at `group_vars` and `host_vars`.** 

For an encrypted file somewhere else, the collection also ships the `community.sops.sops` lookup, a `community.sops.decrypt` filter, and `community.sops.load_vars` for pulling one in mid-play.