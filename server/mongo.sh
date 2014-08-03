#!/bin/sh

mkdir -p private/data
exec mongod --dbpath ./private/data
