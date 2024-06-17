#!/bin/bash

export AWS_DEFAULT_PROFILE=dars  # Enter your profile

set -e
rm -f /tmp/*RESULT*.json
cd $(dirname $0)





service_type=$1
resource_A=$2
resource_B=$3
output_type=$4

if [ "${output_type}" != "diff" ] && [ "${output_type}" != "conf" ] && [ "${output_type}" != "html" ]; then
  echo "\$4 is invalid."
  echo "Allowed value: diff or conf or html"
  exit 1
fi

# For multi args
if echo ${resource_A} | grep "," > /dev/null && echo ${resource_B} | grep "," > /dev/null; then
  backup=${IFS}
  IFS=,
  resource_A_ary=(${resource_A})
  resource_B_ary=(${resource_B})
  IFS=${backup}
fi

echo "--- INPUT ---"
echo "service-type: ${service_type}"
echo "resource-A:   ${resource_A}"
echo "resource-B:   ${resource_B}"
echo "output-type:  ${output_type}"





case "${service_type}" in
  # ----- CloudFront -----
  cloudfront.distribution)
    cmd="get-distribution"
    option="--id"
    service_type="cloudfront"
    filter="del(.Distribution.ARN, .Distribution.AliasICPRecordals, .ETag,
                .Distribution.DomainName, .Distribution.Id, .Distribution.LastModifiedTime,
                .Distribution.DistributionConfig.Aliases,
                .Distribution.DistributionConfig.CallerReference,
                .Distribution.DistributionConfig.Comment,
                .Distribution.DistributionConfig.WebACLId,
                .Distribution.DistributionConfig.DefaultCacheBehavior.OriginRequestPolicyId,
                .Distribution.DistributionConfig.DefaultCacheBehavior.TargetOriginId,
                .Distribution.DistributionConfig.DefaultCacheBehavior.FunctionAssociations,
                .Distribution.DistributionConfig.Origins.Items[].DomainName,
                .Distribution.DistributionConfig.Origins.Items[].Id,
                .Distribution.DistributionConfig.Origins.Items[].OriginPath,
                .Distribution.DistributionConfig.CacheBehaviors.Items[].FunctionAssociations,
                .Distribution.DistributionConfig.CacheBehaviors.Items[].CachePolicyId,
                .Distribution.DistributionConfig.CacheBehaviors.Items[].OriginRequestPolicyId,
                .Distribution.DistributionConfig.CacheBehaviors.Items[].TargetOriginId)"
    ;;
  *)
    echo "service-type:${service_type} is not supported by this script."
    exit 1
    ;;
esac

# For multi args
if [ ${#option[@]} -eq ${#resource_A_ary[@]} ] && [ ${#option[@]} -eq ${#resource_B_ary[@]} ]; then
  for i in $(seq 0 $(expr ${#option[@]} - 1))
  do
    option_A="${option_A} ${option[$i]} ${resource_A_ary[$i]}"
    option_B="${option_B} ${option[$i]} ${resource_B_ary[$i]}"
  done
  echo "--- EXECUTE ---"
  echo "command:  ${cmd}"
  echo "option-A: ${option_A}"
  echo "option-B: ${option_B}"
else
  echo "--- EXECUTE ---"
  echo "command: ${cmd}"
  echo "option:  ${option}"
fi





if echo ${resource_A} | grep "/" > /dev/null || echo ${resource_B} | grep "/" > /dev/null; then
  if echo ${resource_A} | grep "http" > /dev/null || echo ${resource_B} | grep "http" > /dev/null; then
    result_A="/tmp/RESULT---${service_type}.${cmd}---${resource_A##*/}.json"
    result_B="/tmp/RESULT---${service_type}.${cmd}---${resource_B##*/}.json"
    result_DIFF="/tmp/DIFFRESULT---${service_type}.${cmd}---${resource_A##*/}---${resource_B##*/}.json"
    result_file="DIFFRESULT---${service_type}.${cmd}---${resource_A##*/}---${resource_B##*/}.html"
  elif echo ${resource_A} | grep "arn:" > /dev/null || echo ${resource_B} | grep "arn:" > /dev/null; then
    result_A="/tmp/RESULT---${service_type}.${cmd}---${resource_A##*:}.json"
    result_B="/tmp/RESULT---${service_type}.${cmd}---${resource_B##*:}.json"
    result_DIFF="/tmp/DIFFRESULT---${service_type}.${cmd}---${resource_A##*:}---${resource_B##*:}.json"
    result_file="DIFFRESULT---${service_type}.${cmd}---${resource_A##*:}---${resource_B##*:}.html"

    result_A="/tmp/RESULT---${result_A##*/}"
    result_B="/tmp/RESULT---${result_B##*/}"
    result_DIFF="/tmp/DIFFRESULT---${result_DIFF##*/}"
    result_file="DIFFRESULT---${result_file##*/}"
  else
    result_A="/tmp/RESULT---${service_type}.${cmd}---${resource_A////}.json"
    result_B="/tmp/RESULT---${service_type}.${cmd}---${resource_B////}.json"
    result_DIFF="/tmp/DIFFRESULT---${service_type}.${cmd}---${resource_A////}---${resource_B////}.json"
    result_file="DIFFRESULT---${service_type}.${cmd}---${resource_A////}---${resource_B////}.html"
  fi
else
  result_A="/tmp/RESULT---${service_type}.${cmd}---${resource_A}.json"
  result_B="/tmp/RESULT---${service_type}.${cmd}---${resource_B}.json"
  result_DIFF="/tmp/DIFFRESULT---${service_type}.${cmd}---${resource_A}---${resource_B}.json"
  result_file="DIFFRESULT---${service_type}.${cmd}---${resource_A}---${resource_B}.html"
fi





if [ "${output_type}" = "diff" ]; then

  if [ -n "${option_A}" ] && [ -n "${option_B}" ]; then
    aws ${service_type} ${cmd} ${option_A} | jq -S "${filter}" > ${result_A}
    aws ${service_type} ${cmd} ${option_B} | jq -S "${filter}" > ${result_B}
  else
    aws ${service_type} ${cmd} ${option} ${resource_A} | jq -S "${filter}" > ${result_A}
    aws ${service_type} ${cmd} ${option} ${resource_B} | jq -S "${filter}" > ${result_B}
  fi  

  echo "--- DIFF_RESULT ---"
  dictknife diff -S --normalize ${result_A} ${result_B} | highlight -S diff -O ansi | tee ${result_DIFF}

  if [ $(stat -c %s ${result_DIFF}) -le 1 ]; then
    echo "Diff nothing."
  fi

elif [ "${output_type}" = "conf" ]; then

  filter=""

  echo "--- CONF---"
  echo "${resource_A}"
  if [ -n "${option_A}" ]; then
    aws ${service_type} ${cmd} ${option_A} | jq -S "${filter}" | tee ${result_A} | jq '.'
  else
    aws ${service_type} ${cmd} ${option} ${resource_A} | jq -S "${filter}" | tee ${result_A} | jq '.'
  fi
  
  echo "--- CONF---"
  echo "${resource_B}"
  if [ -n "${option_B}" ]; then
    aws ${service_type} ${cmd} ${option_B} | jq -S "${filter}" | tee ${result_B} | jq '.'
  else
    aws ${service_type} ${cmd} ${option} ${resource_B} | jq -S "${filter}" | tee ${result_B} | jq '.'
  fi

elif [ "${output_type}" = "html" ]; then

  if [ -n "${option_A}" ] && [ -n "${option_B}" ]; then
    aws ${service_type} ${cmd} ${option_A} | jq -S "${filter}" > ${result_A}
    aws ${service_type} ${cmd} ${option_B} | jq -S "${filter}" > ${result_B}
  else
    aws ${service_type} ${cmd} ${option} ${resource_A} | jq -S "${filter}" > ${result_A}
    aws ${service_type} ${cmd} ${option} ${resource_B} | jq -S "${filter}" > ${result_B}
  fi  

  dictknife diff -S --normalize ${result_A} ${result_B} \
  | tee ${result_DIFF} \
  | highlight -S html -o ${result_file} --include-style --line-numbers

  if [ $(stat -c %s ${result_DIFF}) -le 1 ]; then
    echo "Diff nothing."
    sed -i '/<\/pre>/i Diff nothing.' ${result_file}
  fi

  echo "--- CREATED ---"
  echo "${result_file}"

else
  exit 1
fi

exit 0
