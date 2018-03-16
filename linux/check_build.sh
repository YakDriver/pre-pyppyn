#!/bin/bash

finally() {
  local exit_code="${1:-0}"

  # FINALLY after everything, give results
  if [ "${userdata_status[0]}" -ne 0 ] || [ "${test_status[0]}" -ne 0 ] ; then
    echo ".............................................................................FAILED!"
    echo "Userdata Status: (${userdata_status[0]}) ${userdata_status[1]}"
    echo "Test Status    : (${test_status[0]}) ${test_status[1]}"
    ((exit_code=${userdata_status[0]}+${test_status[0]}))
    if [ "${exit_code}" -eq 0 ] ; then
      exit_code=1
    fi
  else
    echo ".............................................................................Success!"
  fi
  exit "${exit_code}"
}

catch() {
  local this_script="$0"
  local exit_code="$1"
  local err_lineno="$2"
  
  test_status=($exit_code "Testing error")

  finally $@ #important to call here and as the last line of the script
}

trap 'catch $? ${LINENO}' ERR

# everything below this is the TRY

echo "*****************************************************************************"
echo "Checking build: LINUX"
echo "*****************************************************************************"
cat /etc/redhat-release # this will only work for redhat and centos

ud_path=/tmp/userdata_status

if [ -f "${ud_path}" ] ; then
  # file exists, read into variable
  readarray -t userdata_status < "${ud_path}"
else
  # error, no userdata status found
  userdata_status=(1 "No status returned by userdata")
fi

test_status=(0 "Not run")

if [ "${userdata_status[0]}" -eq 0 ] ; then
  # userdata was successful so now check the build
  # ------------------------------------------------------------ WAM TESTS BEGIN
  # move the binary to s3 ?
  
  # ------------------------------------------------------------ WAM TESTS END
  
  test_status=(0 "Success")
fi

finally
