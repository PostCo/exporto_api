## Releasing `exporto_api`

This project uses Bundler's built-in gem release tasks.

### Prerequisites

- You have push access to the GitHub repo.
- You have a RubyGems.org account with an API key configured locally by running `gem signin`.
- Your local `main` branch is up to date with `origin/main`.

### Normal release process

1. **Decide the new version**
   - Choose the next version number (for example, `0.1.1` or `0.2.0`) following SemVer.

2. **Update the version constant**
   - Edit `lib/exporto_api/version.rb` and update:
     - `ExportoAPI::VERSION = "x.y.z"`

3. **Update docs**
   - Update `CHANGELOG.md` with a new section for the version and a short summary of changes.
   - Optionally update `README.md` if usage or the public API changed.

4. **Commit the changes**

   ```bash
   git status
   git add lib/exporto_api/version.rb CHANGELOG.md README.md
   git commit -m "Bump version to vX.Y.Z"
   ```

   Replace `X.Y.Z` with the new version number.

5. **Ensure you are on `main` and pushed**

   ```bash
   git switch main
   git pull origin main
   git push origin main
   ```

6. **Run the release**

   Use Bundler's release task, which runs tests and lint first:

   ```bash
   bundle exec rake release
   ```

   This will:

   - Run `rake spec` and `rake standard`.
   - Build the gem from `exporto_api.gemspec`.
   - Create a git tag `vX.Y.Z` based on `ExportoAPI::VERSION`.
   - Push the tag to `origin`.
   - Push the gem to RubyGems using your configured credentials.

7. **Verify the release**

   - Check the tag on GitHub (for example, `vX.Y.Z`).
   - Check the gem page on RubyGems: `https://rubygems.org/gems/exporto_api`.

### Notes

- If `bundle exec rake release` fails at any step, fix the issue and rerun the command.
- Do not manually create tags for versions that have not been released through this process; let `rake release` handle tagging.
