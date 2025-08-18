#!/bin/bash

unset WGPU_BACKEND
unset QT_QPA_PLATFORM

/usr/bin/zen-browser "$@"
