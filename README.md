### LoGiCC : Local Github repo Creator and Connector
----------------------------------------
This is a program that allows you to specify the link to a github repo and then automatically download that repo to a local directory
The program then creates a custom conda environment to run the repo locally, based either on an environment.yml file or use provided libraries

### Command line arguments:

Note: The minumum input to the program is the link to the github repo you wish to instantiate

Also: Specifying the number of workers also requires a manager name
```
-l|--link: specify the link to the github repo
example: -l https://github.com/cooperative-computing-lab/work-queue-interactive/tree/octopython
```
```
-b|--branch: specify the branch of a github repo
example: -b octopython
```
```
-w|--workers: specify the number of workers desired
example: -w 5
```
```
-wc|--worker-cores: specify the cores of each worker
example: -wc 4
```
```
-wm|--worker-memory: specify the memory of each worker
example: -wm 4000
```
```
-wd|--worker-disk: specify the disk of each worker
example: -wm 8000
```
```
-n|--name: specify the name of the workqueue
example: -n octo
```
```
-d|--destroy: if this argument is set, the program destroys the local git repo and conda enviroment, otherwise the environment will remain
```
```
-c|--condalibs: specify additional conda libs (place in quotes)
example: -c "conda-forge ndcctools conda-pack dill xrootd coffea"
```
```
-j|--jupyter: if this argument is set, the program initializes a jupyter notebook of the provided repo, otherwise the program will remain running and keep the local files intact until the program is quit
```
```
-p|--port: specify jupyter port
example: -p 8080
```

### Example runthrough of the program:

This shows instantiating the octopython branch of the github repo https://github.com/cooperative-computing-lab/work-queue-interactive/tree/main

First this program must be downloaded
```
git clone https://github.com/cooperative-computing-lab/octopython
```
Then change into the downloaded directory
```
cd octopython
```
Then run the command to instantiate the github repo
```
./octopython.sh -l git@github.com:cooperative-computing-lab/work-queue-interactive.git -b octopython -j -d -w 5 -n octo
```
Breakdown of the command above:

```-l``` specifies the link to the repo we wish to download

```-b``` specifies we want to octopython branch

```-j``` will create a jupyter notebook for us of the repo

```-d``` will destroy the local files we created after we run the program

```-w``` will create 5 workers for us on the manager name octo that we specified with -n

### Note: Accessing jupyter over SSH

Run the following command in another terminal in order to be able to access your jupyter notebook remotely (replacing port, user, and remote machine with their respective values)

```ssh -N -L <PORT>:localhost:<PORT> <user>@<remotemachine>```

And log into the machine

Then paste the following into your browser (replacing port with its value)

```http://localhost:<PORT>/tree?```

And it will grant you access to the jupyter notebook running your github repo!

### TopCoffea specific instructions

Run the following command to download TopCoffea and create a conda environment

```./octopython.sh -l git@github.com:TopEFT/topcoffea.git -c "conda-forge ndcctools conda-pack dill xrootd coffea" -d -w 5 -n ${USER}-workqueue-coffea```

Once it is finished, open a new terminal and ```cd /tmp/${USER}/Octopython/topcoffea```

Then, activate the conda environment with ```conda activate ./env```

Then, ```cd analysis/topEFT``` 

Then, ```python run.py ../../topcoffea/cfg/your_cfg.cfg```

Killing the first terminal will then clean up all local files created
### Octopython diagram
![octopython diagram and name brainstorm](https://user-images.githubusercontent.com/31227025/126818352-9fd06c13-55a2-4876-adaa-11576cf08077.png)
