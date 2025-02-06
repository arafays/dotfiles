#!/bin/bash

yay -S cloudflare-warp-bin

sudo systemctl enable warp-svc

warp-cli registertion new
sleep 1

warp-cli connect
