Automatic Docker Build Hooks
====
Docker Cloud allows you to override and customize commands during automated build and test processes using hooks. For example, you might use a build hook to set build arguments used only during the build process. (You can also set up custom build phase hooks to perform actions in between these commands.)

Use these hooks with caution. The contents of these hook files replace the basic docker commands, so you must include a similar build, test or push command in the hook or your automated process does not complete.

# Introduction in Hooks
The following hooks are available:
- hooks/build
- hooks/test
- hooks/push
- hooks/post_checkout
- hooks/pre_build
- hooks/post_build
- hooks/pre_test
- hooks/post_test
- hooks/pre_push (only used when executing a build rule or automated build )
- hooks/post_push (only used when executing a build rule or automated build )

Source:
https://docs.docker.com/docker-cloud/builds/advanced/#custom-build-phase-hooks


# Example for hooks/build
Override the “build” phase to set variables.

Docker Cloud allows you to define build environment variables either in the hook files, or from the automated build UI (which you can then reference in hooks).

In the following example, we define a build hook that uses docker build arguments to set the variable CUSTOM based on the value of variable we defined using the Docker Cloud build settings. $DOCKERFILE_PATH is a variable that we provide with the name of the Dockerfile we wish to build, and $IMAGE_NAME is the name of the image being built.

`docker build --build-arg CUSTOM=$VAR -f $DOCKERFILE_PATH -t $IMAGE_NAME .`

# Example for hooks/post_push
In our case we use post_push to create the builded image with all tags