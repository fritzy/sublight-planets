#!/bin/bash
~/Apps/Godot_v4.4-rc3/Godot.exe --headless --export-release Web "C:\Users\natha\projects\sublight-p1\build\web\index.html"
butler push build/web fritzy/sublight-planets:html5
