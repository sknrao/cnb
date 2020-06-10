#!/bin/bash
awk '$0 ~ /dir\/hugepage/{print $2}' /proc/mounts | while IFS= read -r line; do
echo $line
sudo umount $line
sudo rm -rf $line
done
