# Ns-3 and OR-Tools experimentation suite
Dockerfiles for the `ns3-ortools` docker image.

A pre-built image can be pulled with `docker pull nondetalle/ns3-ortools:latest`.

The image contains an installation of the [Ns-3](https://gitlab.com/non-det-alle/ns-3-dev) network simulator ([v3.36.1](https://gitlab.com/non-det-alle/ns-3-dev)), Google's [OR-Tools](https://github.com/google/or-tools) optimization library ([v9.2](https://github.com/non-det-alle/or-tools)), and the Simulation Execution Manager ([SEM](https://github.com/non-det-alle/sem)) package to run Ns-3 experiments campaigns ([v0.3.5](https://github.com/non-det-alle/sem)). 

OR-Tools bindings are integrated in Ns-3 via a modified `./ns3` Cmake wrapper and can be used in Ns-3 classes. The [cURLpp](https://github.com/jpbarrette/curlpp) library bindings are integrated as well in the same way. 

## Usage:
If you are familiar with Ns-3 workflow, nothing is changed. After running  (`docker run -ti IMAGE_NAME`) and attaching to the image, your simulations and modules can be copied in the Ns-3 folders (`/home/ns3/ns-3-dev`) and Ns-3 can be built [as usual](https://www.nsnam.org/docs/tutorial/html/getting-started.html#building-with-the-ns3-cmake-wrapper). 

To use jupyter lab from outside run with `-p 8888:8888`. To work on persistent data run with the `-v /your/dir/path:/home/ns3/work` option. For more options checkout the [jupyter-docker-stacks documentation](https://jupyter-docker-stacks.readthedocs.io/en/latest/using/common.html).

For more info refer directly to the documentations of linked software.
