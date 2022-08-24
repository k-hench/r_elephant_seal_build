# README for  `r_elephant_seal` <img src="logo.svg" align="right" alt="" width="120" />

Github repository for the [podman](https://podman.io/) conatiner [`r_elephant_seal`](https://hub.docker.com/repository/docker/khench/r_elephant_seal).

## Documentation of the initial setup

Originally, the `r_elephant_seal` container was build using [buildah](https://buildah.io/), from the accompanying `Containerfile`:

```sh
buildah bud -t r_elephant_seal
```

To make the container publicly available, it is pushed to [dockerhub](https://hub.docker.com/r/khench/r_elephant_seal) using [skopeo](https://github.com/containers/skopeo) and [podman](https://podman.io/):

```sh
skopeo login -u khench docker.io
podman push localhost/r_elephant_seal docker.io/khench/r_elephant_seal:v0.1
```

## Accessing the container

The bundled software can be accessed directly from [dockerhub](https://hub.docker.com/r/khench/qc_suite) with `podman` (or `docker`, or `singularity`):

```sh
podman run docker.io/khench/r_elephant_seal:v0.1 which seqtk
```

Running `Rstudio` interactively is possible, yet it will likely be necessary to bind the directories containing the project on the local machine to the container using the `-v` flag.

```sh
podman run -ti --rm -e DISPLAY=$DISPLAY -v /tmp/.X11-unix:/tmp/.X11-unix r_elephant_seal rstudio
```
However, I currently still refrain from running `Rstudio` through `podman`, as I have not figured out yet how to prevent `podman` from overwriting the file-ownership when mounting the project directories.

My workaround at the moment is to use [`singularity`](https://docs.sylabs.io/guides/3.6/user-guide/) to run the container interactively instead.
This also takes care of mounting the local `${HOME}` directory into the container, which usually suffices to be able to work within the project.

```sh
singularity run docker://khench/r_elephant_seal:v0.1 rstudio
```

## Note on the setup of the conda anf the R environment

The specific configuration of the software installed with [conda](https://docs.conda.io/en/latest/) is specified within the `env.yml` file, while the R environment is recreated from the [{renv}](https://rstudio.github.io/renv/index.html) lockfile `renv.lock`.
For a more convenient manual check, the R packages have been exported to the file `r_pkgs.yml`:

```r
readr::write_lines("package_versions:", file = "./r_pkgs.yml")
jsonlite::read_json("renv.lock") |>
  purrr::pluck("Packages") |>
  purrr::map_chr(\(x){paste0("  - ",x["Package"], ": ", x["Version"])}) |>
  paste(collapse = "\n") |>
  readr::write_lines(file = "./r_pkgs.yml", append = TRUE)
```