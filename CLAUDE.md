# Git Commit Guidelines

When creating commits with multi-line messages, avoid heredocs (`<<EOF`) as they fail in sandbox mode. Instead use:
- Multiple `-m` flags: `git commit -m "Summary" -m "Details"`
- Or `printf`: `git commit -m "$(printf 'Summary\n\nDetails')"`
