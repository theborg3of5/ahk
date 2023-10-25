; Pull updates to all AHK Git repos at once.

#Include <includeCommon>

t := new ProgressToast("Pulling all AHK Git repos").blockingOn()

gitRepos := []
gitRepos.push(Config.path["AHK_ROOT"])
gitRepos.push(Config.path["AHK_PRIVATE"])
gitRepos.push(Config.path["AHK_TEST"])

For _,path in gitRepos {
	t.nextStep("Updating " path)
	
	SetWorkingDir, path
	result := RunLib.runReturn("git pull --rebase=true")
	t.endStep(result.clean())
}

t.finish()
ExitApp
