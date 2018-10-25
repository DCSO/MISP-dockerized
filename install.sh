#/bin/bash

# Create an array with all folder
    FOLDER=( */)
    FOLDER=( "${FOLDER[@]%/}" )



if [ $CI != true ]
then
    ###
    # USER AREA
    ###

    # Ask User which Version he want to install:
    # We made a recalculation the result is the element 0 in the array FOLDER[0] is shown as Element 1. If the user type in the version this recalculation is reverted.
    echo "Which Version do you want to install:"
    for (( i=1; i<=${#FOLDER[@]}; i++ ))
    do
        [ "${FOLDER[$i-1]}" == "backup" ] && continue
        [ "${FOLDER[$i-1]}" == "config" ] && continue
        [ "${FOLDER[$i-1]}" == "current" ] && continue
        [ "${FOLDER[$i-1]}" == ".travis" ] && continue
        echo "[ ${i} ] - ${FOLDER[$i-1]}"
    done
    echo

    # User setup the right version 
    read -p "Please Selects the version to Install: " input_sel
    # set new Version
    CURRENT_VERSION="${FOLDER[${input_sel}-1]}"

else
    ###
    # CI AREA
    ###

    # Parameter 1:
    param_VERSION="$1"
    [ $CI == true ] && [ -z "$param_VERSION" ] && echo "No version parameter given. Please call: '$0 0.3.4'. Exit." && exit

    # If the user is a CI Pipeline:
    [ $CI == true ] && CURRENT_VERSION="$param_VERSION"
    
fi


# Create Symlink to "current" Folder
    [ -L $PWD/current ] && echo "[OK] delete symlink 'current'" && rm $PWD/current
    [ -f $PWD/current ] && echo "[Error] There is a file called 'current' please backup and delete first. Command: 'rm $PWD/current'" && exit
    [ -d $PWD/current ] && echo "[Error] There is a directory called 'current' please backup and delete first. Command: 'rmdir $PWD/current'" && exit
    

    if [ -z "$CURRENT_VERSION" ]
    then
        echo "[Error] The scripts fails and no version could be selected. Exit."
        exit
    else
        echo "[OK] create symlink 'current' for the folder $CURRENT_VERSION"
        ln -s "$CURRENT_VERSION" current


    fi
