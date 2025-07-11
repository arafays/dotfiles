#!/bin/bash

yay -S cloudflare-warp-bin

sudo systemctl enable warp-svc

warp-cli registration new
sleep 1

warp-cli connect
