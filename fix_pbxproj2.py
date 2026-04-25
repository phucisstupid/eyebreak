with open("EyeBreak.xcodeproj/project.pbxproj", "r") as f:
    lines = f.readlines()

new_lines = []
for line in lines:
    if "AppModel+TestExtensions.swift in Sources" in line and "000000000000000000000142" not in line and "F431C215076E8BF6E86AD8A0" not in line:
        continue
    if "BreakTypeTests.swift in Sources" in line and "000000000000000000000140" not in line and "0A0CFB3AA3E591146A9A1AF9" not in line:
        continue
    if "ActivityMonitorTests.swift in Sources" in line and "41314E4A9013972FD3337D39" not in line and "B1BF437AB6F467A4C921AF51" not in line:
        continue
    if "UserDefaultsSettingsStoreTests.swift in Sources" in line and "D5394E1285A4F7CB248CD7A7" not in line and "8C69E36533AA605CCEBFBB53" not in line:
        continue
    new_lines.append(line)

with open("EyeBreak.xcodeproj/project.pbxproj", "w") as f:
    f.writelines(new_lines)
