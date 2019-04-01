#!/bin/sh

#
#
#   This support scripts should help other people to find out what the problem are if any doesn't work
#
#
REQUIRED_PACKAGES="hostname mount groups whoami .scripts/requirements.sh docker grep tar gzip rm mv sha256sum find date"


func_collect_system_information(){
    FILE="$1"

    echo "##### [START] func_collect_system_information"
    echo "# Support script startet at $(date)" > "$FILE"
    echo "##### installed version" >> "$FILE"
    readlink -f current >> "$FILE"
    echo "##### hostname -A" >> "$FILE"
    hostname -A >> "$FILE"
    echo "##### hostname -I" >> "$FILE"
    hostname -I >> "$FILE"
    echo "##### mount" >> "$FILE"
    mount >> "$FILE"
    echo "##### df -h" >> "$FILE"
    df -h >> "$FILE"
    echo "##### whoami" >> "$FILE"
    whoami  >> "$FILE"
    echo "##### groups" >> "$FILE"
    groups  >> "$FILE"
    echo "##### requirements" >> "$FILE"
    .scripts/requirements.sh >> "$FILE"
    
    echo "##### [END] func_collect_system_information" >> "$FILE"
}

func_collect_docker_container(){
    # https://docs.docker.com/engine/reference/commandline/ps/

    FOLDER="$1"
    [ -d "$FOLDER" ] || mkdir "$FOLDER"

    echo "##### [START] func_collect_docker_container"
    
    # add container information
    echo "#Names|Image|ID|Command|CreatedAt|RunningFor|Ports|Status|Size|Labels|Mounts|Networks" > "$FOLDER/container.txt"
    docker ps -af name=misp --format '{{.Names}}|{{.Image}}|{{.ID}}|{{.Command}}|{{.CreatedAt}}|{{.RunningFor}}|{{.Ports}}|{{.Status}}|{{.Size}}|{{.Labels}}|{{.Mounts}}|{{.Networks}}' >> "$FOLDER/container.txt"
    
    # add network information
    echo "#Name|ID|Driver|Internal|IPv6|Labels" > "$FOLDER/network.txt"
    for i in $(docker network ls --format '{{.Name}}|{{.ID}}|{{.Driver}}|{{.Internal}}|{{.IPv6}}|{{.Labels}}' -f name=misp) 
    do
       echo "$i" >> "$FOLDER/network.txt"
    done
    
    # add volume information
    echo "#Name|driver|Mountpoint|Scope|Labels" > "$FOLDER/volumes.txt"
    for i in $(docker volume ls --format '{{.Name}}|{{.Driver}}|{{.Mountpoint}}|{{.Scope}}|{{.Labels}}' -f name=mis) 
    do
       echo "$i" >> "$FOLDER/volumes.txt"
    done

    # add image information
    echo "#Repository|Tag|ID|Digest" > "$FOLDER/images.txt"
    for i in $(docker image ls --format '{{.Repository}}|{{.Tag}}|{{.ID}}|{{.Digest}}' --no-trunc) 
    do
       echo "$i" >> "$FOLDER/images.txt"
    done
    echo "##### [END] func_collect_docker_container"
}


func_collect_files(){
    FILE="$1"

    echo "##### [START] func_collect_files"

    #https://www.lifewire.com/find-linux-command-4092587
    echo "Include all file settings..."
    echo "#FILE|MOD-Time|Change-Time|Access-Time|Size|Permission|User|Group|Filesystem" > "$FILE.txt"
    COLLECT_FILES=$(find -L current/ Makefile .ci backup config *.sh .scripts -type f -printf "%p\n")

    find "$COLLECT_FILES" -printf "%p|%TY-%Tm-%Td|%CY-%Cm-%Cd|%AY-%Am-%Ad|%s|%m|%U|%G|%F\n" >> "$FILE.txt"

    echo "##### Calculate SHA256sum"
    i=0
    echo "#sha256 File" > "$FILE.sha256"
    for f in $COLLECT_FILES
    do
        [ ! -z "$(echo "$f" |grep backup)" ] && continue
        [ ! -z "$(echo "$f" |grep config)" ] && continue
        sha256sum "$f" >> "$FILE.sha256"
        echo "..."
        ((i=i+1))
    done
    echo

    echo "##### [END] func_collect_files"
}

func_collect_container_logs(){
    echo "##### [START] func_collect_container_logs"
    FOLDER="$1"
    [ -d "$FOLDER" ] || mkdir "$FOLDER"
    for c in $(docker ps -af name=misp --format '{{.Names}}')
    do
        echo "Copy Docker logs $c..."
        docker logs "$c" > "$FOLDER/$c.log" 2>&1 
    done
    echo "##### [END] func_collect_container_logs"
}


#####################################
# Check dependencies:
FAIL="false"
for i in $REQUIRED_PACKAGES
do
    [ -z "$(which "$i")" ] && echo "Sorry the package $i is missing." && FAIL="true"
done
# If a package was missing exit now:
[ "$FAIL" = "true" ] && echo "There was an error. Exit now." && exit 1

#########

# Set Variables
DIRECTORY="./MISP-dockerized-support_$(date +'%Y-%m-%d_%H-%M')"
OUT_FILE="$DIRECTORY.tar.gz"

# Create tmp directory
[ -d "$DIRECTORY" ] || mkdir "$DIRECTORY"

func_collect_system_information     "$DIRECTORY/01_system_information.txt"
func_collect_files                  "$DIRECTORY/02_files"
func_collect_docker_container       "$DIRECTORY/03_docker"
func_collect_container_logs         "$DIRECTORY/04_container_logs"


# delete old file
[ -f "$OUT_FILE" ] && rm "$OUT_FILE"

# create tar.gz file
tar c -z -f "$OUT_FILE.new" -C "$DIRECTORY"  .

# Check if new file is empty:
if [ "$(ls -s "$OUT_FILE.new"|cut -d " " -f 1)" -gt 0 ];then
    # delete old file
    [ -f "$OUT_FILE" ] && rm "$OUT_FILE"
    mv "$OUT_FILE.new" "$OUT_FILE"
    rm -Rf "$DIRECTORY"
fi