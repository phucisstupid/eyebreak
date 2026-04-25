import subprocess

def run_command(cmd):
    subprocess.run(cmd, shell=True)

run_command("git push --set-upstream origin resolve-all-conflicts -f")
