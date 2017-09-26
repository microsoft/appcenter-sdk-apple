$deleteLocalBranches = "git branch -D ``git branch | grep -E 'TouchDown*'``"
$deleteRemoteBranches = "git branch -r | awk -F/ '/\/TouchDown/{print `$2}' | xargs -I {} git push origin :{}"
iex $deleteLocalBranches
iex $deleteRemoteBranches