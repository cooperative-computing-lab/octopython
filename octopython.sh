#!/bin/bash
REPOBASE=/tmp/$USER/Octopython
WORKERS=0
CORES=0
MEMORY=0
DISK=0
NAME=""
LINK=""
JUPYTER="no"
PONCHO="no"
PORT=8080
DESTROY="no"
CONDALIBS=""
BRANCH=""
SCRIPT=`realpath $0`
SCRIPTPATH=`dirname $SCRIPT`
CMDPID=""
function help {
	echo "Usage: octopython.sh"
	echo "The minimum arguments required are to specify the link to the github repo you wish to instantiate"
	echo "Specifying the number of workers also requires to input a manager name"
	echo "Command line options:"
	echo "	-l|--link: specify the link to the github repo"
	echo "	-b|--branch: specifiy the branch of a github repo\n"
	echo "	-w|--workers: specify the number of workers desired"
	echo "	-wc|--worker-cores: specify the cores of each worker"
	echo "	-wm|--worker-memory: specify the memory of each worker"
	echo "	-wd|--worker-disk: specify the disk of each worker"
	echo "	-n|--name: specify the name of the workqueue\n"
	echo "	-d|--destroy: if this argument is set, the program destroys the local git repo and conda enviroment"
	echo "	-c|--condalibs: specify additional conda libs (place in quotes)"
	echo "	-j|--jupyter: if this argument is set, the program initializes a jupyter notebook of the provided repo" 
	echo "	-p|--port: specify jupyter port"
	echo "  -P|--poncho: specify install using poncho"
	exit 1
}
# parse command line arguments
while [[ $# -gt 0 ]]; do
	key="$1"
	case $key in
		-w|--workers)
			WORKERS="$2"
			shift
			shift
			;;
		-wc|--worker-cores)
			CORES="$2"
			shift
			shift
			;;
		-wm|--worker-memory)
			MEMORY="$2"
			shift
			shift
			;;
		-wd|--worker-disk)
			DISK="$2"
			shift
			shift
			;;
		-n|--name)
			NAME="$2"
			shift
			shift
			;;
		-l|--link)
			LINK="$2"
			shift
			shift
			;;
		-b|--branch)
			BRANCH="$2"
			shift
			shift
			;;
		-p|--port)
			PORT="$2"
			shift
			shift
			;;
		-d|--destroy)
			DESTROY="yes"
			shift
			;;
		-c|--condalibs)
			CONDALIBS="$2"
			shift
			shift
			;;
		-j|jupyter)
			JUPYTER="yes"
			shift
			;;
		-h|--help)
			help
			;;
		-P|--poncho)
			PONCHO="yes"
			shift
			;;
		*)
			echo "Error: Unknown option"
			echo "Use -h or --help to display help"
			help
			;;
	esac
done
# check if the user has conda installed. If the user does not have conda, then ask them if they wish to install it
source ~/miniconda3/etc/profile.d/conda.sh
if [[ !  `command -v conda` == "conda" ]] ; then
	echo "****Error: Conda not detected"
	while true; do
		read -p "Do you wish to install conda?" yn
		case $yn in 
			[Yy]* ) break;;
			[Nn]* ) echo "Conda not installed: exiting"; exit 3;;
			* ) echo "Please answer yes or no";;
		esac
	done
	echo "****Downloading and installing conda"
	curl https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh > /tmp/conda-install.sh
	bash /tmp/conda-install.sh
	source ~/miniconda3/etc/profile.d/conda.sh
fi
# exit if the user does not provide an input github repo
if [[ "$LINK" == "" ]]; then
	echo "Error: must specify a github repo to pull from"
	exit 2
fi
# if the user asks for workers but does not specify a manager name, then quit
if [ "$NAME" == "" ] && [ ! "$WORKERS" == 0 ]; then
	echo "Error: Please enter a manager name when requesting workers"
	exit 4
fi
# if the user specifies properites of the workers but does not give them a name or specify how many, exit
if [ ! "$CORES" == 0 ] || [ ! "$MEMORY" == 0 ] || [ ! "$DISK" == 0 ]; then
	if [ "$NAME" == "" ]; then
		echo "Error: Please enter a manager name when requesting workers"
		exit 5
	fi
	if [ "$WORKERS" == 0 ]; then
		echo "Error: Please specify the number of workers desired"
	exit 5
	fi
fi
# seperate out the name of the github repo to be used as the name of the local directory
GITPATH=(${LINK///// })
FOLDERNAME=(${GITPATH[1]//./ })
echo "****Cloning git repository to local directory $REPOBASE/$FOLDERNAME"
if [[ "$BRANCH" == "" ]]; then
	git clone $LINK $REPOBASE/$FOLDERNAME
else
	git clone -b $BRANCH $LINK $REPOBASE/$FOLDERNAME
fi
cd $REPOBASE/$FOLDERNAME
if [ "$PONCHO" == "yes" ]; then
        export PATH=${PATH}:${HOME}/cctools/poncho/src
        if [[ `command -v poncho_package_analyze` == "" ]]; then
                echo "Error: Must have cctools/poncho installed to use poncho"
                echo "Please install the cctools package first"
                exit 6
        fi
	conda activate base
	for i in *.ipynb *.py; do
		bash $SCRIPTPATH/notebook_convert.sh $i
	done
	poncho_package_analyze *.imp package.json
	conda deactivate
fi

FILE=$REPOBASE/$FOLDERNAME/environment.yml
# check if there is a local environment.yml file. If there is, then we can use that to determine the conda libraries required
# if such a file does not exist, then we check if the user provided libraries as a command line input
if [ ! -f "$FILE" ] && [ "$CONDALIBS" == "" ]; then
	echo "Error: git repo does not have environment.yml or you did not specify the conda libraries required"
	exit 3
fi
echo "****Creating local conda environment"
if [ "$CONDALIBS" == "" ]; 
then
	conda env create --file environment.yml --prefix ./env
else
	conda create --prefix ./env
fi
conda activate ./env
if [ ! "$CONDALIBS" == "" ]; then
	echo "****Installing additional conda libraries"
	conda install -y -c $CONDALIBS
fi
# special case for installing topEFT
SETUP=$REPOBASE/$FOLDERNAME/setup.py
if [ -f "$SETUP" ] ; then
	pip install -e .
fi
if [[ "$NAME" != "" ]]; then
	echo "Submitting $WORKERS workers to manager $NAME"
	if [ ! "$CORES" == 0 ] || [ ! "$MEMORY" == 0 ] || [ ! "$DISK" == 0 ]; then
		python $SCRIPTPATH/octopus_factory.py $NAME $WORKERS $CORES $MEMORY $DISK & CMDPID=$! 
	else
		python $SCRIPTPATH/octopus_factory.py $NAME $WORKERS 1 1000 1000 & CMDPID=$! 
	fi
fi
if [ "$JUPYTER" == "yes" ]; then
	echo "Initializing jupyter notebook on port $PORT"
	jupyter notebook --no-browser --port=$PORT
else
	echo "Github repo has been initalized at $REPOBASE with local conda environment ./env"
	echo "You are now in a local copy of your git repo with a conda environment activated"
	echo "Type 'conda activate ./env' to activate the conda environment, type exit to quit out of this program"
	cd $REPOBASE/$FOLDERNAME 
	bash 
	echo "Program exiting: deleting local files"
fi
conda deactivate
if [ "$DESTROY" == "yes" ]; then
	cd $REPOBASE
	rm -frd $FOLDERNAME
fi
if [ ! "$CMDPID" == "" ]; then
	kill -s 9 $CMDPID
fi
