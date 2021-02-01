![Alt text](https://raw.githubusercontent.com/nlo-portfolio/nlo-portfolio.github.io/master/style/images/programs/active-backup.png "Active Backup")

## Description ##

Active Backup is a command-line application for periodically backing up local folders to a remote server. It supports several connection types including SCP, SFTP and FTP.

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
Ubuntu:<br>
```
ruby active_backup.rb`
ruby test/run_tests.rb --verbose    # (from the project root directory)
```
<br><br>
Docker:<br>
```
docker-compose build
docker-compose run <active-backup | test>
```
