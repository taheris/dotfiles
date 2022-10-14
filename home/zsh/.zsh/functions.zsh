github-clone() {
  local repo=$*
  local outdir="/Users/${USER}/src/github.com/${repo}"
  regex="^([A-Za-z0-9_-]+)/([A-Za-z0-9_-]+)$"
  [[ ${repo} =~ ${regex} ]] || { echo "${repo} not in valid format"; return 1; }
  command git clone "git@github.com:${repo}.git" ${outdir} || return 1
  cd ${outdir}
}

rg-boundary() {
  command rg --sort-files --follow --max-columns 180 "\\b$*\\b"
}

rg-limit() {
  command rg --sort-files --follow --max-columns 180 -oe ".{0,50}$*.{0,50}"
}

calc() {
  bc -l <<< "$@"
}
