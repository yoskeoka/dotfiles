# dotfiles

## 0. Prerequisites

Install XCode Command-Line Tools.

```sh
xcode-select --install
```

## 1. Git Clone

Clone this repository into `~/dotfiles`

```sh
git clone https://github.com/yoskeoka/dotfiles.git ~/dotfiles
```

## 2. Install

```sh
bash ~/dotfiles/setup.sh initialize
```

## 3. Deploy dotfiles

```sh
# Do not override existing dotfiles
bash ~/dotfiles/setup.sh deploy

# Force override existing dotfiles
bash ~/dotfiles/setup.sh -f deploy
```

## 4. Update dotfiles

```sh
brew bundle dump -f
```
