import os
import re

output = ["# FreeCAD_Macros"]
output.append("| Macro | Description |")
output.append("| --- | --- |")

noTitle = 0
for filename in os.listdir():
    # print()
    if "FCMacro" in filename:
        # print(filename)
        with open(filename, "r") as file:
            lines = file.readlines()
    else:
        continue

    for line in lines:
        if "__title__" in line.casefold() or "__comment" in line.casefold():
            search = re.search(r'[\'\"].*[\'\"]', line).group()
            if search:
                title = search[1:-1]
                # print(f"  {line.strip()}")
                # print(f"  {title}")
                output.append(f"| {filename} | {title} |")

            break
    else:
        print(f"  No title in file: -{filename}-")
        noTitle += 1

result = "\n".join(output)

with open("README.md", "w") as file:
    file.write(result)
