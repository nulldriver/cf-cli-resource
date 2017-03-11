# Version branch

This `version` branch is used to store the current `semver` value in the `number` file.

How this branch was setup:
```
git checkout --orphan version
git rm --cached -r .
rm -rf *
rm .gitignore .gitmodules
touch README.md
git add .
git commit -m "new branch"
git push origin version
```
