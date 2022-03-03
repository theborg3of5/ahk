; Pull updates to all AHK Git repos at once.
#NoEnv                       ; Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance, Force       ; Running this script while it's already running just replaces the existing instance.
SendMode, Input              ; Recommended for new scripts due to its superior speed and reliability.
SetWorkingDir, % A_ScriptDir ; Ensures a consistent starting directory.

#Include <includeCommon>

t := new ProgressToast("Pulling all AHK Git repos").blockingOn()

gitRepos := []
gitRepos.push(Config.path["AHK_ROOT"])
gitRepos.push(Config.path["AHK_CONFIG"] "\ahkPrivate")
gitRepos.push(Config.path["AHK_TEST"])

For _,path in gitRepos {
	t.nextStep("Updating " path)
	SetWorkingDir, path
	Run("git pull")
}

t.finish()
ExitApp
