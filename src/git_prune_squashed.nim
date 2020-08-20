import osproc
import strformat
import strutils

proc gitPruneSquashed(remote="origin", dryrun=false) =
  var defaultBranch = ""
  let
    currentBranch = execProcess("git rev-parse --abbrev-ref HEAD")
    origin = execCmdEx(fmt"git remote show {remote}")
  if origin[1] != 0:
    echo(fmt"Unable to find remote {remote}")
    quit(1)

  block getDefaultBranch:
    for line in splitLines(origin[0]):
      if contains(line, "HEAD branch:"):
        defaultBranch = split(line, ": ")[1]
        break getDefaultBranch

  if dryrun:
    echo("Dry run, will not actually delete any branches\n")

  discard execProcess(fmt"git switch -q {defaultBranch}")
  var branches = execProcess("git for-each-ref refs/heads/ \"--format=%(refname:short)\"")
  for branch in splitLines(branches):
    if not isEmptyOrWhitespace(branch):
      let mergeBase = execCmdEx(fmt"git merge-base {defaultBranch} {branch}")
      if mergeBase[1] != 0:
        echo(fmt"Error checking if {branch} has been squashed")
        continue

      let
        tree = strip(execProcess(fmt"git rev-parse {branch}^{{tree}}"))
        commitTree = strip(execProcess(fmt"git commit-tree {tree} -p {strip(mergeBase[0])} -m _"))
        cherry = strip(execProcess(fmt"git cherry {defaultBranch} {commitTree}"))

      if cherry == fmt"- {commitTree}":
        echo(fmt"Deleting {branch}")
        if not dryrun:
          discard execProcess(fmt"git branch -D {branch}")

  branches = execProcess("git for-each-ref refs/heads/ \"--format=%(refname:short)\"")
  if currentBranch in branches:
    discard execProcess(fmt"git switch -q {currentBranch}")
  else:
    echo(fmt"{currentBranch} has been deleted, remaining on {defaultBranch}")

when isMainModule:
  import cligen
  dispatch(
    gitPruneSquashed,
    cmdName="git-prune-squashed",
    doc="A simple utility to prune squash-merged branches from a local git repo.",
  )
