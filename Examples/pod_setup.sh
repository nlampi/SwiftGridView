#!/bin/bash

echo 'Setting up Universal example...'
cd Universal/
pod install
echo ''
cd ..

echo 'Setting up Pretty example...'
cd Pretty/
pod install
echo ''
cd ..

echo 'Done!'
echo ''
