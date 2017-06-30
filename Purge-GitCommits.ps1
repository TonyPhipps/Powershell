# Purge any line containing "word" in all file histories in the repository.
git filter-branch --tree-filter "find . -type f -exec sed -i -e '/$*word/d' {} \;" -f