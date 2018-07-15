![Rclone Logo](icon/rclone-icon.png)

This is an Unofficial Docker container for the RClone utility based on freely available Linux (x64) binaries at [http://rclone.org/downloads/](http://rclone.org/downloads/)

# RClone Cron Scheduler Docker Container

[![](https://images.microbadger.com/badges/version/madcatsu/rclone-cron-daemon.svg)](https://hub.docker.com/r/madcatsu/rclone-cron-daemon) [![](https://images.microbadger.com/badges/image/madcatsu/rclone-cron-daemon.svg)](https://microbadger.com/images/madcatsu/rclone-cron-daemon) [![](https://images.microbadger.com/badges/commit/madcatsu/rclone-cron-daemon.svg)](https://microbadger.com/images/madcatsu/rclone-cron-daemon) [![](https://gitlab.com/madcatsu/docker-rclone-cron-daemon/badges/master/pipeline.svg)](https://gitlab.com/madcatsu/docker-rclone-cron-daemon/commits/master) [![](https://img.shields.io/docker/pulls/madcatsu/rclone-cron-daemon.svg)](https://hub.docker.com/r/madcatsu/rclone-cron-daemon)

##### GitLab Repository - [https://gitlab.com/madcatsu/docker-rclone-cron-daemon](https://gitlab.com/madcatsu/docker-rclone-cron-daemon)

---

RClone provides a set of commands similar to rsync for working with Public or Private Cloud Storage providers that leverage the S3 or Swift REST API.

**Cloud Services**
* Google Drive
* Amazon S3
* Openstack Swift / Rackspace cloud files / Memset Memstore
* Dropbox
* Google Cloud Storage
* Amazon Drive
* Microsoft One Drive
* Hubic
* Backblaze B2
* Yandex Disk
* The local filesystem

**Features**

* MD5/SHA1 hashes checked at all times for file integrity
* Timestamps preserved on files
* Partial syncs supported on a whole file basis
* Copy mode to just copy new/changed files
* Sync (one way) mode to make a directory identical
* Check mode to check for file hash equality
* Can sync to and from network, eg two different cloud accounts
* Optional encryption (Crypt)

## Usage

### First run

Initially, we need to create a dummy container which executes the initial configuration and then cleans up after itself.

We'll need to bind mount a configuration folder to the container as a minimum so that we have a working and editable config file on the Docker host that we can update without having to run a shell inside the container whenever we need to make a change.

1. Create as a minimum a config folder for RClone to store it's configuration information in on the Docker host machine.

2. The next step that follows will create an ephemeral container and start the RClone configuration tool. Configure your source and destination for RClone keeping in mind that the "/data" folder in the container will be the source or destination for data to be moved or copied with RClone.

3. On the host running Docker, from the command line enter:

  ```shell
  docker run -it --rm -v <config path>:/config \
  madcatsu/rclone-cron-daemon --disable-services \
  rclone --config=/config/.rclone.conf config
  ```

Parameters you will need to change are surrounded by `<>` marks. A brief description of each of these and their purpose follows:

* `<config path>` - this is the Docker bind mounted folder that the RClone configuration file will be saved to and read from when container is running

### Normal Container Operation

At this point we have a configuration file and nothing else to show for it. To run the RClone utility on a schedule and transferring data, we need to run the container again with a different command. Let's get it started!

1. If your Docker host is running on Linux and you have added the 'docker' user account to the sudoers file, you might want to chown the configuration JSON file. If you choose to do so, take a note of the UID and GID of the account that now owns this file. You should populate those values in the container entrypoint command in Step 3.

  > If your user account doesn't require sudo or root privileges to run Docker containers, you can lookup your UID and GID values with the following shell commands:

  > + `id -u <insert your username here>`
  > + `id -g <insert your username here>`

2. Next we start the container with the following command (again, required parameters are enclosed in markup):

  ```shell
  docker run -d --name=<container name> \
  -e RCLONE_MODE="<sync, copy, etc>" \
  -e CRON_SCHEDULE="0/30 * * * *" \
  -e RCLONE_CONFIG_PASS="<password>" \
  -e RCLONE_SOURCE="<rclone source>" \
  -e RCLONE_DESTINATION="<rclone destination>" \
  -e RCLONE_BANDWIDTH="<bandwidth value>" \
  -e JOB_SUCCESS_URL="<healthcheck API endpoint>" \
  -v /etc/localtime:/etc/localtime:ro \
  -v <config path>:/config \
  -v <data path>:/data \
  madcatsu/rclone-cron-daemon --create-user abc:<UID>:<GID>
  ```

Parameters you will need to change are surrounded by `<>` marks. A brief description of each of these and their purpose follows.

### Container Runtime Options

* `-d` - starts the container in "daemon" mode, in other words, it doesn't start and drop you into an interactive shell or stdin by default. The container processes will run in the background as services/daemons.
* `--name=<container name>` - give the container a useful name you can recognise it by later on. If you plan on running multiple instances of this container with different data, config and log locations, it's recommended to add a numeric identifier to the container name that increments for each container deployed
* `--restart unless-stopped` - ensures the container will restart automatically on host restart or a crash of a container process

### Environment Variables

The following list of environment variables control RClone execution parameters including bandwidth, mode, source and destination:

* `RCLONE_MODE` - Available modes are normally `copy` or `sync`.

  >**Note:** This parameter is mandatory unless you specify the `RCLONE_COMMAND` environment variable. See more available sub-commands at [http://rclone.org/docs/](http://rclone.org/docs/)

* `RCLONE_COMMAND` - A custom rclone command which will override the default job

* `CRON_SCHEDULE` - A custom cron schedule which will override the default value of: `0 * * * *` (hourly). This parameter is optional.

* `RCLONE_CONFIG_PASS` - This parameter is optional but must be set if the `.rclone.conf` configuration file is encrypted. Specify the password here.

* `RCLONE_BANDWIDTH` - Bandwidth to be allocated to the rclone data mover. Specify as a number followed by an extension in bytes, kilobytes or megabytes (per second). Eg. 1G = 1GB/sec, 50M = 50MB/sec, 512K = 512KB/sec, etc. If this value is not set, rclone will utilise whatever bandwidth is available

* `RCLONE_SOURCE` - The source for data that should be backed up. Must match either `/data` for data being pushed to a remote location, or the name of the remote specified in `.rclone.conf` if data is being pulled from the remote specified in `.rclone.conf`.

  >**Note:** This parameter is mandatory unless you specify the `RCLONE_COMMAND` environment variable

* `RCLONE_DESTINATION` - The destination that the data should be backed up to. Must match either `/data` for data being pulled from a remote location, or the name of the remote specified in `.rclone.conf`.

  >**Note:** This parameter is mandatory unless you specify the `RCLONE_COMMAND` environment variable

* `JOB_SUCCESS_URL` - At the end of each rclone cron job, report to a healthcheck API endpoint at a defined web URI (eg. WDT.io or Healthchecks.io). This parameter is optional.

#### RCLONE_SOURCE and RCLONE_DESTINATION usage
As rclone allows data to be uploaded to a pre-defined remote, or downloaded from the same, the `RCLONE_SOURCE` and `RCLONE_DESTINATION` environment variables can be used interchangeably. In either form, one of these variables must be specified as "/data" as this path is bind mounted to the Docker container with access to the host file system. To demonstrate, both a push and pull scenario are further outlined:

* _Uploading local data to remote cloud storage:_ In this form, `RCLONE_SOURCE` should be passed to the container with the value of "/data" (without the literal quotes). The `RCLONE_DESTINATION` variable should take the form of "<remote name>:/<sub-path>". Eg. `RCLONE_DESTINATION="Amazon-Cloud-Drive:/Backups"`

* _Downloading data from remote cloud storage:_ In this form, `RCLONE_SOURCE` and `RCLONE_DESTINATION` variables in the previous example should be swapped. Thus, `RCLONE_SOURCE="Amazon-Cloud-Drive:/Backups"`.

### Bind mounts

* `<config path>:/config` The path where the .rclone.conf file is stored
* `<data path>:/data` The path which rclone should use for backup or restore operations
* `/etc/localtime:/etc/localtime:ro` Will capture the local host system time for log output. Ensure you use the 'read only' option as denoted in the example. _If you prefer UTC output, you can skip this bind mount_

### Ad-hoc RClone Jobs

The container can also be used to run ad-hoc RClone commands if you want to specify an alternative command to execute on the default hourly cron schedule.

```shell
docker run --name=<container name> \
-e RCLONE_COMMAND=<your custom rclone command> \
-v /etc/localtime:/etc/localtime:ro \
-v </path/to/your/persistent/config/folder>:/config \
-v </path/to/your/data/folder/>:/data \
madcatsu/rclone-cron-daemon --create-user abc:<UID>:<GID>
```

_You will need to specify the full rclone command in the format 'rclone <operation> source destination' if you elect to use this environment variable_

_Be mindful that the container will not terminate when your custom command completes as Chaperone acts as a supervisor for the cron daemon, which will keep running your custom rclone command with the default hourly schedule._

### Container Entrypoint and User mapping

* `--create-user abc:<UID>:<GID>` - The container leverages the [Chaperone](http://garywiz.github.io/chaperone/index.html) supervisor and init system which allows users to specify a user and group from the Docker host machine to run the in-container processes and access any bind mounts on the host without messing up permissions which can easily occur when processes in a container run as "root".

  The container avoids this issue by allowing users to specify an existing Docker host user account and group with the `UID` and `GID` environment variables.

  > To lookup the User and Group ID of the Docker host user account, enter the following command in the CLI on the Docker host as below:

  > + `id -u <insert your username here>`
  > + `id -g <insert your username here>`

## Info

* Shell access whilst the container is running: `docker exec -it <container name / ID> /bin/bash`
* To monitor the logs of the container in realtime: `docker logs -f <container name / ID>`
* When running a custom rclone job via the `RCLONE_COMMAND` environment variable, using `--verbose --log-file=/var/log/rclone-cron-job.log` will provide a way to view job output with the above "docker logs" command

## Known Issues

* `rclone mount` is not available and will fail / crash rclone if used within the container as the Fuse binaries/libraries are not included in the container image. FUSE is known to have issues with bind mounted paths inside a container and requires access to kernel on the host


## Acknowledgements and Attribution

Credit for the original container idea belongs to Github user [@tynor88](https://github.com/tynor88) for the original version of this Docker container. Also, go buy a beer for [@ncw](https://github.com/ncw) as he deserves one for creating the superlative RClone tool.

## Versions

+ **2017/09/20:**
  - 1.0 - Container initial release - Replaces legacy version on Docker Hub
+ **2018/04/22:**
  - 1.1 - Migrates project to GitLab repo and GitLab CI
+ **2018/07/15:**
  - 1.2 - Switched to builder pattern to further reduce container size
