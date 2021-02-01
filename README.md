![Active Backup](https://raw.githubusercontent.com/nlo-portfolio/nlo-portfolio.github.io/master/style/images/programs/active-backup.png "Active Backup")

## Description ##

Active Backup is a command-line application for periodically backing up local folders to a remote server. It supports several connection types including SCP, SFTP and FTP and configurable options including archival, compression and encryption.
<br><br>
IMPORTANT: In order to facilitate easy encryption and decryption with only a password, key strengthening is limited to hashing over the provided password 50,000 times which avoids storing (or making the user store) a salt and no initialization vector (IV) is used on the encrypted blocks. In non-demonstration environments, it is always recommended to use a secure key derivation function with randomized salts (such as Argon2 or PBKDF2) and a randomized IV for the data.

## Dependencies ##

Ubuntu<br>
Ruby v3<br>
Tests require `openssh-client`, `openssh-server`, `vsftpd`.<br>
\* All required components are included in the provided Docker image.

## Usage ##

Fill out the configuration template file `config.yml.template` with your environment variables and copy it to `config.yml` in the root directory.<br>
Create an `authorized_keys` file (with your public key added) in the `keys/` directory.<br>
Add your private key with the filename `dev` to the `keys/` directory.<br>
<br>
Ubuntu:

```
ruby active_backup.rb`
ruby test/run_tests.rb --verbose    # (from the project root directory)
```

Docker:

```
docker-compose build
docker-compose run <active-backup | test>
```
