#!/bin/bash

exec &> ${tfi_lx_userdata_log}

write_properties()
{
  echo "$1=$2" >> "/tmp/pyppyn.properties"
}

retry()
{
    local n=0
    local try=$1
    local cmd="$${*: 2}"
    local result=1
    [[ $# -le 1 ]] && {
        echo "Usage $0 <number_of_retry_attempts> <Command>"
        exit $result
    }

    echo "Will try $try time(s) :: $cmd"

    if [[ "$${SHELLOPTS}" == *":errexit:"* ]]
    then
        set +e
        local ERREXIT=1
    fi

    until [[ $n -ge $try ]]
    do
        sleep $n
        $cmd
        result=$?
        if [[ $result -eq 0 ]]
        then
            break
        else
            ((n++))
            echo "Attempt $n, command failed :: $cmd"
        fi
    done

    if [[ "$${ERREXIT}" == "1" ]]
    then
        set -e
    fi

    return $result
}  # ----------  end of function retry  ----------

finally() {
  local exit_code="$${1:-0}"

  echo "Finally: "

  # everything to happen whether install succeeds or fails
  
  # write the status to a file for reading by test script
  printf "%s\n" "$${userdata_status[@]}" > /tmp/userdata_status
  
  # allow ssh to be on non-standard port (SEL-enforced rule)
  setenforce 0

  # open firewall (iptables for rhel/centos 6, firewalld for 7
  systemctl status firewalld &> /dev/null
  if [ $? -eq 0 ] ; then
    echo "Configuring firewalld..."
    firewall-cmd --zone=public --permanent --add-port=122/tcp
    firewall-cmd --reload
  else
    echo "Configuring iptables..."
    iptables -A INPUT -p tcp --dport 122 -j ACCEPT #open port 122
    iptables save
    iptables restart
  fi

  sed -i -e '5iPort 122' /etc/ssh/sshd_config
  sed -i -e 's/Port 22/#Port 22/g' /etc/ssh/sshd_config
  cat /etc/ssh/sshd_config
  service sshd restart

  # get OS version as key prefix
  s3_keyfix=$(cat /etc/redhat-release | cut -c1-3)$(cat /etc/redhat-release | sed 's/[^0-9.]*\([0-9]\.[0-9]\).*/\1/')

  # move logs to s3
  aws s3 cp ${tfi_lx_userdata_log} "s3://${tfi_s3_bucket}/${tfi_build_date}/${tfi_build_hour}_${tfi_build_id}/$${s3_keyfix}/userdata.log" || true
  aws s3 cp /var/log "s3://${tfi_s3_bucket}/${tfi_build_date}/${tfi_build_hour}_${tfi_build_id}/$${s3_keyfix}/cloud/" --recursive --exclude "*" --include "cloud*log" || true
  # TODO: move the binary over to s3
  # aws s3 cp /var/log/watchmaker "s3://${tfi_s3_bucket}/${tfi_build_date}/${tfi_build_hour}_${tfi_build_id}/$${s3_keyfix}/watchmaker/" --recursive || true
  
  exit "$${exit_code}"
}

catch() {
  local this_script="$0"
  local exit_code="$${1:-1}"
  local err_lineno="$2"
  echo "$0: line $2: exiting with status $${exit_code}"

  userdata_status=($exit_code "Userdata install error at stage $stage")

  finally $@
}

# setup error trap to go to catch function
trap 'catch $? $${LINENO}' ERR

# everything below this is the TRY

# start time of install
#start=`date +%s`

# declare an array to hold the status (number and message)
userdata_status=(0 "Success")

# ----------  begin of wam install  ----------
git_repo="${tfi_git_repo}"
git_ref="${tfi_git_ref}"

#PIP_URL=https://bootstrap.pypa.io/get-pip.py
pypi_url=https://pypi.org/simple

# Install git
retry 5 yum -y install git

# install python 3.6
rh_os_ver=$(cat /etc/redhat-release | sed 's/[^0-9.]*\([0-9]\).*/\1/')
if [ $rh_os_ver -eq "6" ]; then
  yum -y install https://centos6.iuscommunity.org/ius-release.rpm
elif [ $rh_os_ver -eq "7" ]; then
  yum -y install https://centos7.iuscommunity.org/ius-release.rpm
else
  catch 1 $${LINENO}
fi
yum -y install python36u python36u-pip

# Clone watchmaker
base_dir="/var/opt/git"
mkdir -p "$${base_dir}"
cd "$${base_dir}"
git clone "$git_repo" --recursive
cd watchmaker
if [ -n "$git_ref" ] ; then
  # decide whether to switch to pull request or a branch
  num_re='^[0-9]+$'
  if [[ "$git_ref" =~ $num_re ]] ; then
    stage="git pr (Repo: $git_repo, PR: $git_ref)"
    git fetch origin pull/$git_ref/head:pr-$git_ref
    git checkout pr-$git_ref
  else
    stage="git ref (Repo: $git_repo, Ref: $git_ref)"
    git checkout $git_ref
  fi
fi

echo "Cloning pyppyn..."
cd "$${base_dir}"
git clone https://github.com/YakDriver/pyppyn.git
cd pyppyn

echo "Creating virtual environment..."
python3.6 -m venv venv
venv_bin="$${base_dir}/pyppyn/venv/bin"
cd "$${venv_bin}"
rm -f python
rm -f python3
ln -s /usr/bin/python3.6 python
ln -s /usr/bin/python3.6 python3
source activate
python -c "import sys; print('Inside venv' if sys.base_prefix != sys.prefix else 'Outside venv')"
python --version

echo "Installing pre-requisities for watchmaker..."
pip3.6 install --index-url="$pypi_url" --upgrade pip setuptools boto3

echo "Installing watchmaker distribution..."
cd "$${base_dir}/watchmaker"
pip3.6 install --index-url="$pypi_url" --editable .

echo "Install pyinstaller..."
pip3.6 install --upgrade pyinstaller pyyaml backoff six click defusedxml packaging

echo "Verifying installation..."
if [ -f "$${venv_bin}/watchmaker" ]; then
  echo "watchmaker installed correctly"
else
  echo "ERROR: watchmaker did not install correctly (try 1)"
  cd "$${base_dir}/watchmaker"
  pip install --editable .
fi

echo "Re-verifying installation..."
if [ -f "$${venv_bin}/watchmaker" ]; then
  echo "Building standalone..."

  cp "$${venv_bin}/watchmaker" "$${base_dir}/pyppyn/pyinstaller/watchmaker-script.py"

  cd "$${base_dir}/pyppyn/pyinstaller"
  python generate-standalone.py

  chown -R maintuser:maintuser "$${base_dir}"

  write_properties "dist_path" "$${base_dir}/pyppyn/pyinstaller/dist/"
  write_properties "s3_path" "s3://${tfi_s3_bucket}/${tfi_build_date}/${tfi_build_hour}_${tfi_build_id}/"
fi

# Install watchmaker
#stage="install wam" && pip install --index-url "$pypi_url" --editable .

# Run watchmaker
# stage="run wam" && watchmaker ${tfi_common_args} ${tfi_lx_args}
# ----------  end of wam install  ----------

# time it took to install
#end=`date +%s`
#runtime=$((end-start))
#echo "WAM install took $runtime seconds."

finally