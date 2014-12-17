#!/bin/bash

if [ -z "`ls | grep -v *.sh | grep SKYFALL`" ]
then

echo 'No SKYFALL Textures Detected, downloading ...';echo;
for file in $(curl -s minecraft.skyfallgames.com/current/ |
                  grep href |
                  sed 's/.*href="//' |
                  sed 's/".*//' |
                  grep '^[a-zA-Z].*'); do
echo  $file;    curl -# -O http://minecraft.skyfallgames.com/current/$file
done

else
echo 'SKYFALL Textures Detected, updating ...';echo;
for file in $(curl -s minecraft.skyfallgames.com/current/ |
                  grep href |
                  sed 's/.*href="//' |
                  sed 's/".*//' |
                  grep '^[a-zA-Z].*'); do
    echo $file; curl -z $file -# -O http://minecraft.skyfallgames.com/current/$file
done
fi
