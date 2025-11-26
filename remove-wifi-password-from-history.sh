#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}=== WiFi Password Git History Cleanup ===${NC}\n"

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}Error: Not in a git repository${NC}"
    exit 1
fi

# Ensure we're in the repo root
cd "$(git rev-parse --show-toplevel)"

PASSWORD="123"

echo -e "${YELLOW}Step 1: Checking if password exists in current files...${NC}"
if grep -r "$PASSWORD" . --exclude-dir=.git 2>/dev/null; then
    echo -e "${RED}Error: Password still exists in current files!${NC}"
    echo -e "${RED}Please commit the changes that remove the password first.${NC}"
    exit 1
else
    echo -e "${GREEN}✓ Password not found in current files${NC}\n"
fi

echo -e "${YELLOW}Step 2: Checking if password exists in git history...${NC}"
if git log --all --full-history -S "$PASSWORD" --pretty=format:"%H %s" | head -5; then
    echo -e "\n${YELLOW}Found password in git history (showing first 5 commits)${NC}\n"
else
    echo -e "${GREEN}✓ Password not found in git history${NC}"
    echo -e "${GREEN}No cleanup needed!${NC}"
    exit 0
fi

echo -e "\n${RED}WARNING: This will rewrite git history!${NC}"
echo -e "${YELLOW}This means:${NC}"
echo "  - All commit SHAs will change"
echo "  - You'll need to force push"
echo "  - Anyone else with this repo will need to re-clone or reset"
echo ""
read -p "Do you want to continue? (yes/no): " confirm

if [ "$confirm" != "yes" ]; then
    echo -e "${YELLOW}Aborted by user${NC}"
    exit 0
fi

echo -e "\n${YELLOW}Step 3: Creating backup...${NC}"
BACKUP_BRANCH="backup-before-history-cleanup-$(date +%Y%m%d-%H%M%S)"
git branch "$BACKUP_BRANCH"
echo -e "${GREEN}✓ Created backup branch: $BACKUP_BRANCH${NC}\n"

echo -e "${YELLOW}Step 4: Removing password from history...${NC}"

# Create a sed script to replace the password
cat > /tmp/git-replace-password.txt <<EOF
123==>123
EOF

# Check if git-filter-repo is available
if command -v git-filter-repo &> /dev/null; then
    echo "Using git-filter-repo (recommended method)..."

    # Use git-filter-repo to replace the password
    git filter-repo --replace-text /tmp/git-replace-password.txt --force

elif command -v java &> /dev/null; then
    echo "git-filter-repo not found, downloading BFG Repo-Cleaner..."

    # Download BFG if not exists
    if [ ! -f /tmp/bfg-1.14.0.jar ]; then
        wget -q https://repo1.maven.org/maven2/com/madgag/bfg/1.14.0/bfg-1.14.0.jar -O /tmp/bfg-1.14.0.jar
    fi

    # Use BFG to replace the password
    java -jar /tmp/bfg-1.14.0.jar --replace-text /tmp/git-replace-password.txt --no-blob-protection .

    # Clean up the repository
    git reflog expire --expire=now --all
    git gc --prune=now --aggressive

else
    echo -e "${RED}Error: Neither git-filter-repo nor java (for BFG) is available${NC}"
    echo -e "${YELLOW}Install one of them:${NC}"
    echo "  - nix-shell -p git-filter-repo"
    echo "  - nix-shell -p openjdk17 (for BFG)"
    rm /tmp/git-replace-password.txt
    exit 1
fi

rm /tmp/git-replace-password.txt
echo -e "${GREEN}✓ Password removed from history${NC}\n"

echo -e "${YELLOW}Step 5: Verifying cleanup...${NC}"
if git log --all --full-history -S "$PASSWORD" --pretty=format:"%H %s" 2>/dev/null | grep -q .; then
    echo -e "${RED}✗ Password still found in history!${NC}"
    echo -e "${YELLOW}Restoring backup branch...${NC}"
    git reset --hard "$BACKUP_BRANCH"
    exit 1
else
    echo -e "${GREEN}✓ Password successfully removed from all history${NC}\n"
fi

echo -e "${GREEN}=== Cleanup Complete! ===${NC}\n"
echo -e "${YELLOW}Next steps:${NC}"
echo "1. Review the changes:"
echo "   git log --oneline -10"
echo ""
echo "2. Force push to remote (this will rewrite history on remote!):"
echo "   git push origin $(git branch --show-current) --force"
echo ""
echo "3. If you need to restore the original history:"
echo "   git reset --hard $BACKUP_BRANCH"
echo ""
echo -e "${YELLOW}Note: The password has been replaced with '123' in all commits${NC}"
