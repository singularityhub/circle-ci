# Singularity Builder Circle-CI

**Important** this build is currently not working because CircleCI doesn't support
the [mnt](https://discuss.circleci.com/t/why-circleci-2-0-does-not-support-mounting-folders/11605/6) namespace. If you can contribute to fix this, please do!

![.circleci/sregistry-circle.png](.circleci/sregistry-circle.png)

[![CircleCI](https://circleci.com/gh/singularityhub/circle-ci.svg?style=svg)](https://circleci.com/gh/singularityhub/circle-ci)

This is a simple example of how you can achieve:

 - version control of your recipes
 - versioning to include image hash *and* commit id
 - build of associated container and
 - push to a storage endpoint

for a reproducible build workflow.

**Why should this be managed via Github?**

Github, by way of easy integration with continuous integration, is an easy way
to have a workflow set up where multiple people can collaborate on a container recipe,
the recipe can be tested (with whatever testing you need), discussed in pull requests,
and then finally pushed to your storage of choice or Singularity Registry. 
Importantly, you don't need to give your entire team manager permissions 
to the registry. An encrypted credential that only is accessible to 
administrators can do the push upon merge of a discussed change.

**Why should I use this instead of a service?**

You could use a remote builder, but if you do the build in a continuous integration
service you get complete control over it. This means everything from the version of
Singularity to use, to the tests that you run for your container. You have a lot more
freedom in the rate of building, and organization of your repository, because it's you
that writes the configuration. Although the default would work for most, you can 
edit the build, setup, and circle configuration file in the 
[.circleci](.circleci) folder to fit your needs.

## Quick Start

Add your Singularity recipes to this repository, and edit the build commands in
the [build.sh](.circleci/build.sh) file. This is where you can specify endpoints 
(Singularity Registry, Dropbox, Google Storage, AWS) along with container names
(the uri) and tag. You can build as many recipes as you like, just add another line!

```yaml
                               # recipe relative to repository base
  - /bin/bash .circleci/build.sh Singularity
  - /bin/bash .circleci/build.sh --uri collection/container --tag tacos --cli google-storage Singularity
  - /bin/bash .circleci/build.sh --uri collection/container --cli google-drive Singularity
  - /bin/bash .circleci/build.sh --uri collection/container --cli globus Singularity
  - /bin/bash .circleci/build.sh --uri collection/container --cli registry Singularity
```

For each client that you use, required environment variables (e.g., credentials to push,
or interact with the API) must be defined in the (encrypted) Travis environment. To
know what variables to define, along with usage for the various clients, see
the [client specific pages](https://singularityhub.github.io/sregistry-cli/clients)

## Detailed Started

### 0. Fork this repository

You can clone and tweak, but it's easiest likely to get started with our example
files and edit them as you need.

### 1. Get to Know CircleCi

We will be working with [Circle CI](https://www.circleci.com). You can see 
example builds for this [repository here](https://circleci.com/gh/singularityhub/circle-ci).

 - Circle offers [scheduled builds](https://support.circleci.com/hc/en-us/articles/115015481128-Scheduling-jobs-cron-for-builds-).
 - CircleCI also offers [GPU Builders](https://circleci.com/docs/enterprise/gpu-configuration/) if you want/need that sort of thing.
 - If you don't want to use the [sregistry](https://singularityhub.github.io/sregistry-cli) to push to Google Storage, Drive, Globus, Dropbox, or your personal Singularity Registry, CircleCI will upload your artifacts directly to your [deployment](https://circleci.com/docs/2.0/deployment-integrations/#section=deployment) location of choice.

 
### 2. Add your Recipe(s)

For the example here, we have a single recipe named "Singularity" that is provided 
as an input argument to the [build script](.circleci/build.sh). You could add another 
recipe, and then of course call the build to happen more than once. 
The build script will name the image based on the recipe, and you of course
can change this. Just write the path to it (relative to the repository base) in
your [.circleci/config.yml](.circleci/config.yml).


### 3. Configure Singularity

The basic steps to [setup](.circleci/setup.sh) the build are the following:

 - Install Singularity, we use the release 2.6 branch as it was the last to not be written in GoLang. You could of course change the lines in [setup.sh](.circleci/setup.sh) to use a specific tagged release, an older version, or development version.
 - Install the sregistry client, if needed. The [sregistry client](https://singularityhub.github.io/sregistry-cli) allows you to issue a command like "sregistry push ..." to upload a finished image to one of your cloud / storage endpoints. By default, the push won't happen, and you will just build an image using the CI.

### 4. Configure the Build

The basic steps for the [build](.circleci/build.sh) are the following:

 - Running build.sh with no inputs will default to a recipe called "Singularity" in the base of the repository. You can provide an argument to point to a different recipe path, always relative to the base of your repository.
 - If you want to define a particular unique resource identifier for a finished container (to be uploaded to your storage endpoint) you can do that with `--uri collection/container`. If you don't define one, a robot name will be generated.
 - You can add `--uri` to specify a custom name, and this can include the tag, OR you can specify `--tag` to go along with a name without one. It depends on which is easier for you.
 - If you add `--cli` then this is telling the build script that you have defined the [needed environment variables](https://circleci.com/docs/2.0/env-vars/) for your [client of choice](https://singularityhub.github.io/sregistry-cli/clients) and you want successful builds to be pushed to your storage endpoint. See [here](https://singularityhub.github.io/sregistry-cli/clients) for a list of current client endpoints, or roll your own!

See the [config.yml](.circleci/config.yml) for examples of this build.sh command (commented out). If there is some cloud service that you'd like that is not provided, please [open an issue](https://www.github.com/singularityhub/sregistry-cli/issues).

### 5. Connect to CI

If you go to your [Circle Dashboard](https://circleci.com/dashboard) you can usually select a Github organization (or user) and then the repository, and then click the toggle button to activate it to build on commit --> push.

That's it for the basic setup! At this point, you will have a continuous integration service that will build your container from a recipe each time that you push. The next step is figuring out where you want to put the finished image(s), and we will walk through this in more detail.

## Storage!

Once the image is built, where can you put it? An easy answer is to use the 
[Singularity Global Client](https://singularityhub.github.io/sregistry-cli) and
 choose [one of the many clients](https://singularityhub.github.io/sregistry-cli/clients) 
to add a final step to push the image. You then use the same client to pull the
container from your host. Once you've decided which endpoints you want to push to,
you will need to:

 1. Save the credentials / other environment variables that your client needs (see the client settings page linked in the sregistry docs above) to your [repository settings](https://circleci.com/docs/2.0/env-vars/) where they will be encrypted and in the environment.
 2. Add a line to your [.circleci/config.yml](.circleci/config.yml) to do an sregistry push action to the endpoint(s) of choice. We have provided some (commented out) examples to get you started. 

Remember that you can also take advantage of deployment options that CircleCI offers, or do any other action that you might want for the reproducibility or archive of metadata of your builds. We save the build folder as an artifact to the repository, but the containers might be too big to do this.

## Advanced Usage

 - This setup can work as an analysis node as well! Try setting up a [scheduled build](https://support.circleci.com/hc/en-us/articles/115015481128-Scheduling-jobs-cron-for-builds-) to build a container that processes some information feed, and you have a regularly scheduled task.
 - run builds in parallel and test different building environments. You could try building the "same" container across different machine types and see if you really do get the same thing :)
 - You can also do other sanity checks like testing if the container runs as you would expect, etc.
