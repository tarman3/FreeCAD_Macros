import os
import re

url = "https://github.com/tarman3/FreeCAD_Macros/blob/main"

output = ["# FreeCAD_Macros"]
output.append("[forum.freecad.org](https://forum.freecad.org/search.php?keywords=macro&author=tarman3&sf=firstpost&sr=topics)")
output.append("| Macro | Description |")
output.append("| --- | --- |")

filesList = sorted(os.listdir())

noTitleCounter = 0
noUrlCounter = 0
for filename in filesList:
    # print()
    if "FCMacro" in filename:
        # print(filename)
        with open(filename, "r") as file:
            lines = file.readlines()
    else:
        continue

    title = ""
    url = ""
    for line in lines:
        if "__title__" in line.casefold() or "__comment" in line.casefold():
            search = re.search(r'[\'\"].*[\'\"]', line).group()
            if search:
                title = search[1:-1]
                # print(f"  {line.strip()}")
                # print(f"  {title}")

        if "__url__" in line.casefold():
            search = re.search(r'[\'\"].*[\'\"]', line).group()
            if search:
                url = search[1:-1]
                print("url", url)

    if not title:
        print(f"  No title in file: -{filename}-")
        noTitleCounter += 1

    if not url:
        print(f"  No url in file: -{filename}-")
        noUrlCounter += 1

    if title and not url:
        output.append(f"| [{filename}]({url}/{filename}) | {title} |")
    elif title and url:
        output.append(f"| [{filename}]({url}/{filename}) | [{title}]({url}) |")

result = "\n".join(output)

with open("README.md", "w") as file:
    file.write(result)
