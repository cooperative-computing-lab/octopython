#!/bin/bash
REPOBASE=/tmp/$USER/Octopython
WORKERS=0
CORES=""
MEMORY=""
DISK=""
NAME=""
LINK=""
JUPYTER="no"
PORT=8080
DESTROY="no"
CONDALIBS=""
function help {
	echo "Usage: octopython.sh"
	echo "Command line options:"
	echo "-w|--workers: specify the number of workers desired"
	echo "-wc|--worker-cores: specify the cores of each worker"
	echo "-wm|--worker-memory: specify the memory of each worker"
	echo "-wd|--worker-disk: specify the disk of each worker"
	echo "-n|--name: specify the name of the workqueue"
	echo "-l|--link: specify the link to the github repo"
	echo "-p|--port: specify jupyter port"
	echo "-d|--destroy: destroys the local git repo and conda enviroment if set"
	echo "-c|--condalibs: specify additional conda libs (place in quotes)"
	echo "-j|--jupyter: initialize a jupyter notebook of the provided repo" 
	exit 1
}
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
			shift
			;;
		-h|--help)
			help
			;;
		*)
			echo "Error: Unknown option"
			echo "Use -h or --help to display help"
			help
			;;
	esac
done
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
if [[ "$LINK" == "" ]]; then
	echo "Error: must specify a github repo to pull from"
	exit 2
fi
if [ "$NAME" == "" ] && [ ! "$WORKERS" == 0 ]; then
	echo "Error: Please enter a manager name when requesting workers"
	exit 4
fi
if [ ! "$CORES" == "" ] || [ ! "$MEMORY" == "" ] || [ ! "$DISK" == "" ]; then
	if [ "$NAME" == "" ]; then
		echo "Error: Please enter a manager name when requesting workers"
		exit 5
	fi
	if [ "$WORKERS" == 0 ]; then
		echo "Error: Please specify the number of workers desired"
	exit 5
	fi
fi
gitpath=(${LINK///// })
foldername=(${gitpath[1]//./ })
echo "****Cloning git repository to local directory $REPOBASE/$foldername"
git clone $LINK $REPOBASE/$foldername
cd $REPOBASE/$foldername
FILE=$REPOBASE/$foldername/environment.yml
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
SETUP=$REPOBASE/$foldername/setup.py
if [ -f "$SETUP" ] ; then
	pip install -e .
fi
if [[ "$NAME" != "" ]]; then
	condor_submit_workers --manager-name $NAME --cores $CORES --memory $MEMORY --disk $DISK $WORKERS
fi
if [ "$JUPYTER" == "yes" ]; then
	jupyter notebook --no-browser --port=$PORT
else
	echo "Github repo has been initalized at $REPOBASE with local conda environment ./env"
	echo "Control c this terminal when finished and it will be cleaned up"
	keepgoing=1
	trap 'echo "sigint"; keepgoing=0; ' SIGINT
	while (( keepgoing )); do
		sleep 5
	done
	echo "Program exiting: deleting local files"
fi
conda deactivate
if [ "$DESTROY" == "yes" ]; then
	cd $REPOBASE
	rm -frd $foldername
fi
