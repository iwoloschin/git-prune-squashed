# Package

version       = "0.1.0"
author        = "Ian Woloschin"
description   = "A tool to prune squash merged branches from a local git repo."
license       = "MIT"
srcDir        = "src"
bin           = @["git_prune_squashed"]
skipExt       = @["nim"]



# Dependencies

requires "nim >= 1.2.6"
requires "cligen >= 1.1.0"
