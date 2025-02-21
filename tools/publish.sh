#!/bin/bash
~/Apps/Godot_v4.4-beta3/Godot.exe --headless --export-release Web "C:\Users\natha\projects\Sublight-p1\build\web\index.html"
butler push build/web fritzy/sublight-planets:html5
