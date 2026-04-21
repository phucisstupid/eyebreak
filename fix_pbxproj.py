import re

with open('EyeBreak.xcodeproj/project.pbxproj', 'r') as f:
    content = f.read()

# Make sure the path is correct in PBXGroup App
content = re.sub(
    r'name = App;\n\t\t\tsourceTree = "<group>";\n\t\t};',
    r'path = App;\n\t\t\tsourceTree = "<group>";\n\t\t};',
    content
)

# And fix the FileReference path to just the filename, since the group has path = App
content = re.sub(
    r'85621F17F325A5718BE90184 /\* HeartbeatTests.swift \*/ = \{isa = PBXFileReference; includeInIndex = 1; lastKnownFileType = sourcecode.swift; path = App/HeartbeatTests.swift; sourceTree = "<group>"; \};',
    r'85621F17F325A5718BE90184 /* HeartbeatTests.swift */ = {isa = PBXFileReference; includeInIndex = 1; lastKnownFileType = sourcecode.swift; path = HeartbeatTests.swift; sourceTree = "<group>"; };',
    content
)

with open('EyeBreak.xcodeproj/project.pbxproj', 'w') as f:
    f.write(content)
