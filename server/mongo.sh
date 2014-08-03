#!/bin/sh

mkdir -p private/data
mongod --dbpath ./private/data
