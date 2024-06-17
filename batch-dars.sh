#!/bin/bash

cd $(dirname $0)

resource_list=$1
if [ ! -f "${resource_list}" ]; then
  echo "\$1 needs existing file path."
  exit 1
fi



while IFS=" " read service_type resource_A resource_B output_type
do

  if echo ${service_type} | grep "^#.*" > /dev/null; then
    continue
  fi

  if [ "${service_type}" = "" ] || [ "${resource_A}" = "" ] || [ "${resource_B}" = "" ] || [ "${output_type}" = "" ]; then
    continue
  fi

  ./dars.sh ${service_type} ${resource_A} ${resource_B} ${output_type}

  if [ $? != 0 ]; then
    echo "--- INPUT ---"
    echo "service-type: ${service_type}"
    echo "resource-A:   ${resource_A}"
    echo "resource-B:   ${resource_B}"
    echo "output-type:  ${output_type}"
    echo ""
    echo "Something wrong. Failed."
  fi

  echo -e "\n\n\n"

done < ${resource_list}



echo "All processing finished."
exit 0
