#!/usr/bin/env python3
import argparse
import re
import os

def write_config(filename, text):
    with open(os.path.expanduser(filename), 'w') as f:
        f.writelines(text)

def has_opacity_spec(text):
    opaque = False
    for line in text:
        if re.search(r'^config\.\w+_background_opacity', line):
            opaque = True
    return opaque

def toggle_opacity(text):
    changed = False
    output = []
    for line in text:
        if re.search(r'^config\.\w+_background_opacity', line):
            changed = True
            output.append("--" + line)
        elif re.search(r'^--config\.\w+_background_opacity', line):
            changed = True
            output.append(line[2:])
        else:
            output.append(line)
    return changed, output

def print_status(text):
    opaque = has_opacity_spec(text)
    print(f'Opacity specified: {opaque}')
    
parser = argparse.ArgumentParser(prog='wconf', description='wezterm configuration app')
parser.add_argument('filename', nargs='?', default='~/.wezterm.lua')
parser.add_argument('-U', '--toggle-opacity', action='store_true')

args = parser.parse_args()

text = []
with open(os.path.expanduser(args.filename)) as f:
    text = f.readlines()

if args.toggle_opacity:
    changed, text = toggle_opacity(text)
    if changed:
        write_config(args.filename, text)
else:
    print_status(text)
