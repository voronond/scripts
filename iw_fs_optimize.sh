#!/bin/bash
# build fs tree, count number of files in each folder
# if there is more than N files in folder, runs optimize
# optimize does these steps:
# 	- deduplicates messages using fdupes
#	- moves NDRs and other garbage mail to subdirectory
#	- moves older mail to subfolders on folder per year basis
#
#   - REQUIRES: fdupes
#
### ### variables ###
#
# ( script options are -d: starting directory, -s: max allowed files count for directory )
#
#
declare FDUPES="$(which fdupes)"
if [ "${FDUPES}" == "" ];
then
  echo "fdupes util missing, please install fdupes, exiting here"
  exit 1
fi
#
# option defaults
declare START_DIR="/mnt/data/mail/"
declare -i MAX_SIZE=1000;
#
# get command line options
while getopts d:s: option
do
  case "${option}"
  in
  d) START_DIR=${OPTARG};; # where to start, full path ended with slash "/"
  s) MAX_SIZE=${OPTARG};; # where to start, full path ended with slash "/"
  esac
done
#
### ### functions ###
#
## returns domain paths
get_domain_path() {
echo "$(find "${START_DIR}" -maxdepth 1 -type d | egrep -v "_incoming|_outgoing" | tail -n +2)"
return 0
}
#
#
## returns user paths for all records from DOMAINS  
get_user_path() {
for element in $(seq 0 $((${#DOMAINS[@]} -1))) 
do
  echo "$(find "${DOMAINS[element]}" -maxdepth 1 -type d | tail -n +2)"
done
return 0
}
#
#
## returns file count for given path, input is full path ending with /
get_folder_stats() {
echo "$(find "${1}" -maxdepth 1 -type f | wc -l)"
return 0
}
#
#
## returns subfolder paths over file limit, input is full path ending with /
get_user_stats() {
IFS=$'\n'
for path in $(find "${1}" -type d | tail -n +2 | xargs -I '{}' bash -c 'echo -e "$(find "{}" -maxdepth 1 -type f | wc -l)" "{}"')
do
  declare -i dirsize=$(echo "${path}" | sed -r s'|^([[:digit:]]+) (\/.*)$|\1|')
  if [ "${dirsize}" -ge "${MAX_SIZE}" ]
    then
      echo "${path}"
  fi
done
return 0
}
#
#
# run optimize on all OPTIMIZE paths
optimize() {
IFS=$'\n'
for element in $(seq 0 $((${#OPTIMIZE[@]} -1)))
do
declare -i dirsize=$(echo "${OPTIMIZE[element]}" | sed -r s'|^([[:digit:]]+) (\/.*)$|\1|')
declare -i path=$(echo "${OPTIMIZE[element]}" | sed -r s'|^([[:digit:]]+) (\/.*)$|\2|')
>&2 echo "Running optimize for path ${path} with ${dirsize} messages"
>&2 echo "Deduplicate .."
>&2 ${FDUPES} -fNI "${path}" # run deduplicate folder using fdupes -fNI
declare -i dirsize=$(get_folder_stats "${path}")
>&2 echo "${path} - ${dirsize}"
read -n 1 -s -r -p "Press any key to continue" # debug
if [ ${dirsize} -ge ${MAX_SIZE} ] # if the folder still contains more than MAX_SIZE messages, run garbage cleanup
  then
  >&2 echo "Garbage cleanup .."
  declare +i MAX_SIZE="${MAX_SIZE}"
  >&2 find "${path}" -maxdepth 1 -type f -name "*.imap" | xargs egrep -l "^Subject: Returned mail" | xargs -I {} mv -v "{}" "${path}"/"${GARBAGE_FOLDER}"_${MAX_SIZE}
  declare -i dirsize=$(get_folder_stats "${path}")
  >&2 echo "${path} - ${dirsize}"
  read -n 1 -s -r -p "Press any key to continue" # debug
  if [ ${dirsize} -ge ${MAX_SIZE} ] # if the folder still contains more than MAX_SIZE messages, run old mail cleanup
    then
    >&2 echo "Old mail cleanup .."
    for year in { "2016" "2015" "2014" "2013" "2012" "2011" "2010" "2009" "2008" "2007" "2006" "2005" "2004" "2003" "2002" "2001" "2000" }
      do
      mkdir -p "${path}"/${year}_${MAX_SIZE}
      cp "${path}"/imapindex.dat "${path}"/${year}_${MAX_SIZE}/imapindex.dat
      cp "${path}"/imapindex.bin "${path}"/${year}_${MAX_SIZE}/imapindex.bin
      echo "*" > "${path}"/${year}_${MAX_SIZE}/flagsext.dat
      >&2 find "${path}" -maxdepth 1 -type f -name "${year}*.imap" | xargs -I {} mv -v "{}" "${path}"${year}_${MAX_SIZE}
      done
  read -n 1 -s -r -p "Press any key to continue" # debug
  mkdir -p "${path}"/1999_${MAX_SIZE}
  cp "${path}"/imapindex.dat "${path}"/1999_${MAX_SIZE}/imapindex.dat
  cp "${path}"/imapindex.bin "${path}"/1999_${MAX_SIZE}/imapindex.bin
  echo "*" > "${path}"/1999_${MAX_SIZE}/flagsext.dat
  >&2 find "${path}" -maxdepth 1 -type f -name "19*.imap" | xargs -I {} mv -v "{}" "${path}"1999_${MAX_SIZE}
  declare -i dirsize=$(get_folder_stats "${path}")
  >&2 echo "${path} - ${dirsize}"
  read -n 1 -s -r -p "Press any key to continue" # debug
  fi
fi  
done
return 0
}

### ### MAIN ### ( fill DOMAINS, USERS, OPTIMIZE arrays and performe optimize on paths in OTPIMIZE )
: <<'END'
for element in $(get_domain_path)
do
  declare -a DOMAINS=( "${DOMAINS[@]}" "${element}" )
done
echo "DOMAINS all - ${DOMAINS[@]}" # debug
echo "DOMAINS last added - ${DOMAINS[-1]}" # debug
echo "DOMAINS elements count - ${#DOMAINS[@]}" # debug
read -n 1 -s -r -p "Press any key to continue" # debug
for element in $(get_user_path)
do
  declare -a USERS=( "${USERS[@]}" "${element}" )
done
echo "USERS all - ${USERS[@]}" # debug
echo "USERS last added - ${USERS[-1]}" # debug
echo "USERS elements count - ${#USERS[@]}" # debug
read -n 1 -s -r -p "Press any key to continue" # debug
for element in $(seq 0 $((${#USERS[@]} -1))) 
do
  unset tmparr
  readarray tmparr <<< "$(get_user_stats "${USERS[element]}")"
  if [ "$(echo -ne ${tmparr} | wc -m)" -ne 0 ] 
   then
   declare -a OPTIMIZE=( "${OPTIMIZE[@]}" "${tmparr[@]}" )
  fi
done
END
readarray OPTIMIZE < /root/opt_all.txt # debug
  echo "OPTIMIZE all - ${OPTIMIZE[@]}" # debug
  echo "OPTIMIZE last added - ${OPTIMIZE[-1]}" # debug
  echo "OPTIMIZE elements count - ${#OPTIMIZE[@]}" # debug
  read -n 1 -s -r -p "Press any key to continue" # debug
optimize
exit 0