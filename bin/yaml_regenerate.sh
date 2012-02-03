#!/bin/sh

# Regenerates all found yaml_generate bits; example use:
# ./yaml_regenerate.sh yaml_helper/u937_qa03_post241_data.yaml

IFS='
'

rm -f temp
touch temp

sed -n '/^ *conditions:/,/^ *$/p' $1 >>temp

for line in $(grep "[-]f\"" $1 | sed 's/^# *//')
do
  #echo "--$line--"
  eval $(dirname $0)/yaml_generate.rb $line >>temp
done

mv --backup=t $1 /var/tmp/
mv temp $1
