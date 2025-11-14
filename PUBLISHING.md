# Publishing Rubion to RubyGems

This guide walks you through publishing the Rubion gem to RubyGems.org.

## Prerequisites

1. **RubyGems Account**: Create an account at https://rubygems.org/sign_up
2. **API Key**: You'll need your RubyGems API key for publishing

## Step-by-Step Instructions

### 1. Create RubyGems Account

If you don't have one:
- Go to https://rubygems.org/sign_up
- Sign up with your email
- Verify your email address

### 2. Get Your API Key

1. Log in to https://rubygems.org
2. Go to your profile (click your username)
3. Click "Edit Profile"
4. Scroll to "API Key" section
5. Click "Reset" or "View" to get your API key
6. Copy the API key (you'll need it in step 4)

### 3. Configure Your API Key Locally

You have two options:

**Option A: Using `gem` command (recommended)**
```bash
gem signin
# Enter your email and API key when prompted
```

**Option B: Create credentials file manually**
```bash
mkdir -p ~/.gem
echo "---\n:rubygems_api_key: YOUR_API_KEY_HERE" > ~/.gem/credentials
chmod 600 ~/.gem/credentials
```

Replace `YOUR_API_KEY_HERE` with your actual API key.

### 4. Update Gemspec (if needed)

Make sure `rubion.gemspec` has:
- Correct author name
- Correct homepage URL
- Correct source code URI
- Valid email (optional but recommended)

### 5. Build the Gem

```bash
cd /Users/bibek/projects/rubion
gem build rubion.gemspec
```

This creates a file like `rubion-0.3.0.gem`

### 6. Test the Gem Locally (Optional)

Before publishing, you can test it locally:

```bash
gem install ./rubion-0.3.0.gem
rubion scan
```

### 7. Publish to RubyGems

```bash
gem push rubion-0.3.0.gem
```

Or use the shorthand:
```bash
gem push rubion-*.gem
```

**Note:** The first time you publish, RubyGems will send a confirmation email. Click the confirmation link to complete the publication.

### 8. Verify Publication

1. Visit https://rubygems.org/gems/rubion
2. Check that your gem appears with the correct version
3. Test installation:
   ```bash
   gem install rubion
   ```

## Updating the Gem

For future versions:

1. Update version in `lib/rubion/version.rb`
2. Update `CHANGELOG.md`
3. Build: `gem build rubion.gemspec`
4. Push: `gem push rubion-VERSION.gem`

## Important Notes

- **Version Numbers**: Once published, you cannot reuse a version number. Always increment the version.
- **Yanking**: If you need to remove a version, use `gem yank rubion -v VERSION` (use carefully!)
- **Dependencies**: Make sure all runtime dependencies are available on RubyGems
- **License**: The gemspec specifies MIT license - make sure LICENSE file is included

## Troubleshooting

### "You don't have permission to push to this gem"
- Make sure you're logged in: `gem signin`
- Check that the gem name isn't already taken by someone else

### "Gem name is already taken"
- The name "rubion" might be taken. You'll need to choose a different name or contact the owner.

### "Invalid gemspec"
- Run `gem build rubion.gemspec` to see validation errors
- Fix any issues in the gemspec file

## Quick Reference

```bash
# Full publishing workflow
gem build rubion.gemspec
gem push rubion-*.gem

# Check if gem exists
gem search rubion

# Install after publishing
gem install rubion
```



