#!/usr/bin/env python
# -*- coding: utf-8 -*-

"""
Remove useless vertical movements between operations

This script commenting lines with G0 movements
if X and Y coordinates did not changed in G1/G2/G3


2025-04-13 Fix for gcode with DressupPathBoundary (G1/G2/G3 without X/Y)
2025-04-14 More fix for gcode with DressupPathBoundary (G1/G2/G3 without X/Y)

2025-04-15 Added argparse
   python gcode_cleanG0.py --help
   python gcode_cleanG0.py -d 1.5 'mill1.nc' 'mill2.nc'

2025-05-15  Remove G0 X0 Y0
            Gui for enter threshold, repeat
            --replaceStartZ
            --repeats
            -skiphead
"""

import os
import re
import sys
import argparse
from pathlib import Path
from tkinter import simpledialog


def getPosition(line):
    coordinates = {}
    for axis in ('x', 'y', 'z'):
        pattern = f'{axis}-?\\d+.\\d+'
        result = re.search(pattern, line, re.IGNORECASE)
        value = float(result.group()[1:]) if result else positionPrev[axis]
        coordinates[axis] = value
    return coordinates


parser = argparse.ArgumentParser()
parser.add_argument("files", type=argparse.FileType("r"), nargs="*",
                    help ="Path to gcode files")
parser.add_argument("-t", "--threshold", default=0, type=float, action="store",
                    help ="Retract threshold to keep tool down")
parser.add_argument("-s", "--suffix", default="_post", type=str, action="store",
                    help ="Suffix for new name to save result Gcode")
parser.add_argument("-p", "--postamble", default="", type=str, action="store",
                    help ="Add line to end of the file. Use '\\n' for line break")
parser.add_argument("-f", "--removeFirstG0Z", action="store_true",
                    help ="Comment first G0 movement")
parser.add_argument("-z", "--replaceStartZ", default=85, action="store",
                    help ="Replace Z coordinate for start G0 movements")
parser.add_argument("--removeG0X0Y0", action="store_true",
                    help ="Remove movements G0 X0 Y0")
parser.add_argument("--repeats", default=0, type=int, action="store",
                    help ="Set repeats for continous working")
parser.add_argument("--skiphead", action="store_true",
                    help ="Remove lines before first move G0, G1, G2 or G3")


args = parser.parse_args()

threshold = args.threshold
newFileSuffix = args.suffix
postamble = args.postamble
removeFirstG0Z = args.removeFirstG0Z
replaceStartZ = args.replaceStartZ
removeG0X0Y0 = args.removeG0X0Y0
repeats = args.repeats
skiphead = args.skiphead

if not threshold:
    threshold = simpledialog.askfloat("gcode_cleanG0", "threshold", initialvalue=1)

if not repeats:
    repeats = simpledialog.askinteger("gcode_cleanG0", "repeats", initialvalue=1)


files = []
if args.files:
    for file in args.files:
        files.append(file.name)
else:
    for file in os.listdir():
        try:
            name, ext = file.split('.')[-2:]
            if re.search(r'(nc|gc|ncc|ngc|cnc|tap|gcode|g-code)$', ext, re.IGNORECASE) \
            and not name.endswith(newFileSuffix):
                files.append(file)
        except: Exception


for path in files:

    with open(path, "r") as file:
        lines = file.readlines()

    tempG0LinesNum = []
    lines2comment = []
    positionPrev = {'x':None, 'y':None, 'z':None}
    positionNext = {'x':None, 'y':None, 'z':None}
    G123Prev = {'x':None, 'y':None, 'z':None}
    G123Next = {'x':None, 'y':None, 'z':None}
    counterG0 = 0
    lineNum = 0
    lineSkipHead = 0

    for line in lines:

        if re.search(r'G0\s.*Z', line, re.IGNORECASE):
            counterG0 += 1
            if removeFirstG0Z and (counterG0 == 1):
                lines2comment.append(lineNum)
            if (counterG0 == 1 or counterG0 == 2) and replaceStartZ:
                lines[lineNum] = re.sub(r'Z-?\d+.\d+', f'Z{replaceStartZ}', line, re.IGNORECASE)

        if removeG0X0Y0 and line.strip() == 'G0 X0.000 Y0.000':
            lines2comment.append(lineNum)

        if re.search(r'^G0\s?[XYZ]\d+', line, re.IGNORECASE):
            tempG0LinesNum.append(lineNum)

        if re.search(r'^G[0123]\s?[XYZ]\d+', line, re.IGNORECASE):
            positionNext = getPosition(line)
            if skiphead and not lineSkipHead:
                lineSkipHead = lineNum

        if re.search(r'^G[123]\s?[XYZ]\d+', line, re.IGNORECASE):
            G123Next = getPosition(line)

        if re.search(r'^G[123]\s?[XYZ]\d+', line, re.IGNORECASE):
            if  positionNext['x'] is not None \
            and positionNext['y'] is not None \
            and G123Prev['x'] is not None \
            and G123Prev['y'] is not None \
            and tempG0LinesNum \
            and ((positionNext['x']-G123Prev['x'])**2 + (positionNext['y']-G123Prev['y'])**2)**0.5 <= threshold:
                lines2comment.extend(tempG0LinesNum)

            tempG0LinesNum.clear()

        G123Prev = G123Next
        positionPrev = positionNext
        lineNum += 1


    for i in lines2comment:
        lines[i] = f'({lines[i].strip()})\n'

    if lines2comment:
        text = f'(PostProcess {newFileSuffix})\n(Amount lines commented by cleanG0: {len(lines2comment)})\n(threshold = {threshold})\n'
        lines.insert(2, text)

    if postamble: lines.append(postamble.replace('\\n', '\n'))

    pointPos = path.rfind('.')
    newFilePath = path[:pointPos] + newFileSuffix + path[pointPos:]

    print(repeats)
    with open(newFilePath, "w") as newFile:
        for i in range(repeats):
            newFile.write(f'(----- Start Repeat {i+1} -----)\n')
            newFile.write(''.join(lines[lineSkipHead:]))
            newFile.write(f'(----- Finish Repeat {i+1} -----)\n')


    outputText = f'Commented ({len(lines2comment)}) lines in {path} >>> {newFilePath}'
    print(outputText)
