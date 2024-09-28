# Important Git Commands

### Initial Configration

```
git --version
git init
```

#### check current users details if any

```
git config -l
```

#### set Email & User name globaly

```
git config --global user.email "youremailid@gmail.com"
git config --global user.name "yourusername"
```

#### Set to branch from master to main

```
git config --global init.defaultBranch main
```

### Add/remove remote repo to local so that we can update and push changes to remote

```
git remote add origin <Remote_Repo_Name>
git remote remove origin
```

#### Download/Clone remote repo & Fetch all branch from remote

```
git clone -b <Branch_name> <Repo_URL>
git fetch --all
```

### Branch Commands

#### View

```
git branch -a <View all branches>
```

#### Create New

```
git branch <branch_name>
```

#### swith to branch and create,switch to new branch, rename branch

```
git checkout <branch_name>
git checkout -b <branch_name>
git branch -m old_bot_header old_header
```

#### Push/Pull local update to remote first time use oringin next time not required

```
git push -u origin <branch_name>
```

#### If you want to merge remote change to current branch

```
git pull origin <branch_name>
```

#### Delete Branch

```
git branch -d new-feature
```

#### Deleting Branch from Locally and remote use both command one by one

```
git branch -D branch_name
git push origin :branch_name
```

#### Delete branch remotely

```
git push origin --delete <remote_branch_name>
```

### Commit and pushing

```
git status
git add <filename> or git add .
git commit -m "Message"
git commit -am "Commit message" [add more commit]
git commit -amend [Change in last commit message]
```

git merge <branch_name> [merge branch to current branch]

### Other

```
git log [check last commit]
git checkout <commit hash> [go to commit stage]
git fetch --dry-run
git fetch --all
git fetch <remote> <branch>
```

### SSH KEY

ssh-keygen -t ed25519 -C "your_email@example.com" `Generate SSH Key` <br>

Add ssh Key in Github manually

ssh -T git@github.com `Check if key is valid or installed properly`

### Pull Complete Project with all Branches

```
git clone <reponame> <destination>
git fetch --all
git branch -a
```

### Delete Remote & Local branch and sysnc with remote

```
# 1. Switch to a different branch (e.g., main)
git checkout main

# 2. Delete the local branch
git branch -d branch_name
# or force delete if necessary
git branch -D branch_name

# 3. Delete the remote branch
git push origin --delete branch_name

# 4. Fetch the latest changes
git fetch origin

# 5. Prune deleted branches
git remote prune origin

# 6. Pull latest changes from the main branch
git pull origin main
# Optionally, pull changes for other branches if needed
git pull origin other_branch_name

```
