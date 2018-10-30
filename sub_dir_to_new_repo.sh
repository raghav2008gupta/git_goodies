#!/usr/bin/env bash


# ----- #
# Usage #
# ----- #
programname=$0
function usage {
	echo "NAME"
	echo "        $(basename ${programname})"
	echo "DESCRIPTION"
	echo "        Create new git repo from sub directory of an existing git repo"
	echo "OPTIONS"
	echo "        -h, --help"
	echo "            Display help"
	echo "        -r, --repo"
	echo "            Ssh url of an existing git repo"
	echo "        -l, --local-repo"
	echo "            Absolute path of local copy of git repo"
	echo "        -s, --sub-dir"
	echo "            Sub directory to be converted into the git repo"
	echo "        -n, --new-repo"
	echo "            Ssh url of the new git repo"
	echo "        -f, --force"
	echo "            Force push to git repo"
    echo "USAGE"
    echo "        $(basename ${programname}) -r <git_repo> -s <sub_directory> -n <new_git_repo>"
    echo "        or"
    echo "        $(basename ${programname}) -l <local_git_repo_dir> -s <sub_directory> -n <new_git_repo>"
    exit 1
}

# ---------------- #
# Decode arguments #
# ---------------- #
while [[ $# -gt 0 ]]
do
key="$1"

case ${key} in
	-h|--help)
    usage
    ;;
    -r|--repo)
    repo="$2"
    shift # past argument
    shift # past value
    ;;
    -l|--local-repo)
    local_repo="$2"
    shift # past argument
    shift # past value
    ;;
    -s|--sub-dir)
    sub_dir="$2"
    shift # past argument
    shift # past value
    ;;
    -n|--new-repo)
    new_repo="$2"
    shift # past argument
    shift # past value
    ;;
    -f|--force)
    force="--force"
    shift # past argument
    ;;
    *)
    usage
    ;;
esac
done

if [ -z "$sub_dir" ]
then
	echo "[ERRO] A sub directory is required"
    usage
fi

if [ -z "$new_repo" ]
then
	echo "[ERRO] A new repo ssh url is required"
    usage
fi

original_dir=$(echo ${repo} | sed 's@.*/@@;s/.git$//')
new_dir=$(echo ${new_repo} | sed 's@.*/@@;s/.git$//')

cd /tmp

# ---------------------- #
# Validate new git repos #
# ---------------------- #
git ls-remote "${new_repo}" &>-
if [ "$?" -ne 0 ]; then
    echo "[ERROR] Unable to read from \"${new_repo}\""
    exit 1;
fi

if [ ! -z "$repo" ]
then
	git ls-remote "${repo}" &>-
	if [ "$?" -ne 0 ]
	then
		echo "[ERROR] Unable to read from \"${repo}\""
		exit 1;
	fi
	git clone ${repo}
	mv ${original_dir} ${new_dir}
elif [ ! -z "$local_repo" ]
then
	if [ ! -d ${local_repo} ]
	then
		echo "[ERROR] Directory \"${local_repo}\" doesn't exist"
		echo "[ERROR] Provide an absolute path for the local git repo"
		exit 1; 
	fi
	cp -rf ${local_repo} ${new_dir}
else
	echo "[ERRO] A repo ssh url or local repo directory is required"
	usage
fi

cd ${new_dir}
if [ ! -d ${sub_dir} ]
then
    echo "[ERROR] Sub dir \"${sub_dir}\" doesn't exist in ${original_dir}"
	exit 1
fi

git reset --hard master
git pull

# --------------------------- #
# Convert sub dir into a repo #
# --------------------------- #
git remote rm origin
git filter-branch --prune-empty --subdirectory-filter ${sub_dir} master
git remote add origin ${new_repo}
ls -lh .

# ---------------- #
# Push to new repo #
# ---------------- #
while true; do
    read -p "Do you want to push to new repo \"${new_repo}\"?" yn
    case ${yn} in
        [Yy]* ) git push ${force:-} origin master; cd ..; rm -rf ${new_dir}; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done
