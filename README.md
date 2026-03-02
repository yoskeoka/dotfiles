# dotfiles

## 0. Prerequisites

### macOS

Install XCode Command-Line Tools.

```sh
xcode-select --install
```

Generate SSH Key and add it to GitHub.

### Linux (WSL)

Ensure build tools and curl/git are available.

```sh
sudo apt-get update -y
sudo apt-get install -y build-essential ca-certificates curl git
```

## 1. Git Clone

Clone this repository into `~/dotfiles`

```sh
git clone https://github.com/yoskeoka/dotfiles.git ~/dotfiles
```

## 2. Deploy dotfiles

```sh
# Do not override existing dotfiles
bash ~/dotfiles/setup.sh deploy

# Force override existing dotfiles
bash ~/dotfiles/setup.sh -f deploy
```

## 3. Install

```sh
bash ~/dotfiles/setup.sh initialize
```

## 4. Configure Git user emails

This dotfiles setup expects the following include files referenced from `~/.gitconfig`.

- `~/.gitconfig.user` (private GitHub account)
- `~/.gitconfig.mf-user` (work account for `github.com/moneyforward`)

Create them like this:

```sh
cat > ~/.gitconfig.user <<'EOF'
[user]
  name = your.name
  email = your.private@example.com
EOF

cat > ~/.gitconfig.mf-user <<'EOF'
[user]
  name = your.name
  email = your.work@moneyforward
EOF
```

## 5. Install Fonts

[Powerline Fonts](https://github.com/powerline/fonts)

## 6. Update dotfiles

```sh
brew bundle dump -f
```
