with open("EyeBreak.xcodeproj/project.pbxproj", "r") as f:
    lines = f.readlines()

new_lines = []
skip = False
for line in lines:
    if line.strip().startswith('83EA4FFB9DFE371C47303215') or \
       line.strip().startswith('42564BF7AB7938F80BEE8750') or \
       line.strip().startswith('59C14AF5BB83A30FABA91278') or \
       line.strip().startswith('98194FF1A1534AB062D47D15') or \
       line.strip().startswith('05904807B7C490AFB22D947E') or \
       line.strip().startswith('226E26EC7F3ACF74D97C3DBF') or \
       line.strip().startswith('80981ADF01428A77BD3FA03D'):
        continue
    new_lines.append(line)

with open("EyeBreak.xcodeproj/project.pbxproj", "w") as f:
    f.writelines(new_lines)
