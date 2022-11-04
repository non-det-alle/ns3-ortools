# Ns-3 and OR-Tools experimentation suite
Dockerfiles to build the `ns3-ortools-experiment-suite` docker container.
Pull it with `docker pull nondetalle/ns3-ortools-experiment-suite:latest`.

The built image contains an installation of the [Ns-3](https://gitlab.com/non-det-alle/ns-3-dev) network simulator, Google's [OR-Tools](https://github.com/google/or-tools) optimization library, and the Simulation Execution Manager ([SEM](https://github.com/non-det-alle/sem)) package to run Ns-3 experiments campaigns.  OR-Tools bindings are integrated in Ns-3 via a modified `./ns3` Cmake wrapper and can be used in Ns-3 classes. 

## Usage:
If you are familiar with Ns-3 workflow, nothing is changed. After running  (`docker run -ti IMAGE_NAME`) and attaching to the image, your simulations and modules can be copied in the Ns-3 folders (`/home/ns3/ns-3-dev`) and Ns-3 can be built [as usual](https://www.nsnam.org/docs/tutorial/html/getting-started.html#building-with-the-ns3-cmake-wrapper). 

To use jupyter lab from outside run with `-p 8888:8888`. To work on persistent data run with the `-v /your/dir/path:/home/ns3/work` option. For more options checkout the [jupyter-docker-stacks documentation](https://jupyter-docker-stacks.readthedocs.io/en/latest/using/common.html).

For more info refer directly to the documentations of linked software.
