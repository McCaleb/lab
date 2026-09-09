# Onboarding a machine

Keep a copy of this in the repo it applies to (e.g., as `docs/secrets.md`). 

> [!TIP]
> Make sure your `.gitignore` doesn't cause this file to be ignored, since it has 'secrets' in it.

- Everything splits in two:
  1. What the repo carries.** `.sops.yaml`, `.gitattributes`, `.gitignore`, the
`.envrc` files, `requirements.yml`, and the encrypted files themselves. None
of it is secret and all of it is committed.
22. What the machine needs. The list below.

---

## Per machine

1. Install the tools.

   ```
   dnf install age direnv
   ```

   SOPS is not in the Fedora repo. Grab the rpm from https://github.com/getsops/sops/releases and `dnf install ./sops-*.rpm`.

2. Install the direnv shell hook. Without it, `.envrc` files look like they are being ignored.

   ```
   echo 'eval "$(direnv hook bash)"' >> ~/.bashrc
   exec bash
   ```

3. Get an age identity into place, mode 600, in a directory mode 700.

   ```
   mkdir -p -m 700 ~/.config/sops/age
   age-keygen -o ~/.config/sops/age/keys.txt
   chmod 600 ~/.config/sops/age/keys.txt
   age-keygen -y ~/.config/sops/age/keys.txt
   ```

  - A new machine gets its own identity. That is the whole point of the multi-recipient model, it lets you revoke a laptop without touching the desktop.
  - Restore a backed-up key instead only when you are rebuilding a system that already had one, since the public key in `.sops.yaml` is still that system's.

4. Get this machine's public key into `.sops.yaml` and re-key the files, from a machine that already has access. 

  - A fresh machine cannot do this for itself, because `updatekeys` has to decrypt the data key first.

      ```
      cd ~/k8s-training
      sops updatekeys opentofu/secrets.sops.env
      sops updatekeys ansible/group_vars/all/secrets.sops.yaml
      sops updatekeys ansible/group_vars/load_balancers/secrets.sops.yaml
      ```

  - Commit and push. Until this lands, the new machine can't read anything.

5. Write `~/.config/direnv/direnvrc` with the `use_sops` function (unless the repo has `.direnv-lib.sh` instead).

  - See `direnvrc.example` and `direnv-lib.sh.example`. Pick one, not both.

6. Install the Ansible collection, if this machine runs playbooks.

   ```
   cd ~/k8s-training/ansible
   ansible-galaxy collection install -r requirements.yml
   ```

  - It needs the `sops` binary on `PATH` and a readable age key, both of which step 1 and step 3 already handled.

## Per clone

These are `git config` and direnv approvals, which live outside the working tree. 

A second clone on the same machine needs them again.

7. Bind the textconv diff drivers.

   ```
   ./git-textconv.sh
   ```

8. Run `direnv allow` in each directory holding an `.envrc`.

   ```
   cd ~/k8s-training/opentofu
   direnv allow
   ```

   The approval is keyed to the file's content, so editing an `.envrc` later revokes it and you allow again.

## Verify

```
cd ~/k8s-training

# The file decrypts, has the recipients you expect, and git will track it
./verify.sh opentofu/secrets.sops.env

# The shell picks it up on cd
cd opentofu && echo "${PROXMOX_VE_API_TOKEN:0:12}..."

# Diffs are readable
git diff HEAD~1 -- opentofu/secrets.sops.env

# Ansible resolves an encrypted group var
cd ~/k8s-training/ansible
ansible-config dump --only-changed | grep -i variable_plugins
ansible load_balancers -m debug -a 'var=keepalived_auth_pass'
```

## Removing a machine

Same sequence as step 4 in reverse. 

Drop the anchor and the reference from `.sops.yaml`, run `sops updatekeys` on every encrypted file, commit.

Understand what that does and does not do.
  - It stops that key from opening future versions of the file. Whoever held it still has any plaintext they already decrypted, and every old commit in git history is still readable by it. 
  - Revocation is a reason to rotate the underlying secrets, not a substitute for doing it.
