#!/bin/bash
~/Apps/Godot_v4.3-beta2/Godot_v4.3-beta2_win64.exe --headless --export-release Web "C:\Users\natha\projects\Sublight-p1\build\web\index.html"
butler push build/web fritzy/sublight-planets:html5
