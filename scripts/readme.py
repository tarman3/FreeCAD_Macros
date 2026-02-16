import os
import re

fileUrl = "https://github.com/tarman3/FreeCAD_Macros/blob/main"
pathReadme = "../README.md"
pathMacros = "../macros"

output = ["# FreeCAD_Macros"]
output.append("[forum.freecad.org](https://forum.freecad.org/search.php?keywords=macro&author=tarman3&sf=firstpost&sr=topics)")
output.append("| Macro | Description |")
output.append("| --- | --- |")

filesList = sorted(os.listdir(pathMacros))

noTitleCounter = 0
noUrlCounter = 0
for filename in filesList:
    # print(">>>", filename)
    filePath = pathMacros + "/" + filename
    if "FCMacro" in filename:
        # print(filename)
        with open(filePath, "r") as file:
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
        output.append(f"| [{filename}]({fileUrl}/{filename}) | {title} |")
    elif title and url:
        output.append(f"| [{filename}]({fileUrl}/{filename}) | [{title}]({url}) |")

result = "\n".join(output)

with open(pathReadme, "w") as file:
    file.write(result)
