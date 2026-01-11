# 1. Ensure you are on the latest production code
git checkout main
git pull origin main

# 2. Switch to your feature branch and sync it with main
# This allows you to fix any conflicts safely before touching production
git checkout newbranch
git merge main

# 3. Once conflicts are resolved and tests pass, merge back to main
git checkout main
git merge --no-ff newbranch -m "merge: integrated feature-name from newbranch"

# 4. Push to your organization repository
git push origin main

### If your newbranch has many "messy" commits (e.g., "fixed typo", "testing again"), use the Squash method to keep the main history clean:
git checkout main
git merge --squash newbranch
git commit -m "feat: implement [Clear Description of Feature]"
git push origin main

### Localhost Maually run docker-compose

docker compose --env-file ../.env.local build --no-cache
docker compose --env-file ../.env.local up -d