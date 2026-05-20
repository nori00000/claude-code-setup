#!/usr/bin/env bash
set -euo pipefail

echo "[1/7] Installing base packages"
sudo apt update
sudo apt install -y \
  ca-certificates \
  curl \
  file \
  ffmpeg \
  fzf \
  git \
  imagemagick \
  jq \
  poppler-utils \
  ripgrep \
  tmux \
  unzip \
  zoxide \
  7zip

echo "[2/7] Installing fd compatibility link"
if command -v fdfind >/dev/null 2>&1 && ! command -v fd >/dev/null 2>&1; then
  mkdir -p "$HOME/.local/bin"
  ln -sf "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi

echo "[3/7] Installing Yazi official Linux binary"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
curl -fL \
  "https://github.com/sxyazi/yazi/releases/latest/download/yazi-x86_64-unknown-linux-gnu.zip" \
  -o "$tmpdir/yazi.zip"
unzip -q "$tmpdir/yazi.zip" -d "$tmpdir"
yazi_dir="$(find "$tmpdir" -maxdepth 1 -type d -name 'yazi-*' | head -n 1)"
sudo install -m 0755 "$yazi_dir/yazi" /usr/local/bin/yazi
sudo install -m 0755 "$yazi_dir/ya" /usr/local/bin/ya

echo "[4/7] Installing Tmux Plugin Manager"
mkdir -p "$HOME/.tmux/plugins"
if [ ! -d "$HOME/.tmux/plugins/tpm/.git" ]; then
  git clone https://github.com/tmux-plugins/tpm "$HOME/.tmux/plugins/tpm"
else
  git -C "$HOME/.tmux/plugins/tpm" pull --ff-only
fi

echo "[5/7] Writing ~/.tmux.conf"
if [ -f "$HOME/.tmux.conf" ]; then
  cp "$HOME/.tmux.conf" "$HOME/.tmux.conf.backup.$(date +%Y%m%d%H%M%S)"
fi

cat > "$HOME/.tmux.conf" <<'TMUXCONF'
# Prefix: Ctrl+Space, with Ctrl+b kept as secondary prefix.
set -g prefix C-Space
set -g prefix2 C-b
bind C-Space send-prefix

set-option -g history-limit 50000
bind % split-window -h -c "#{pane_current_path}"
bind '"' split-window -v -c "#{pane_current_path}"
set -g default-terminal "tmux-256color"
set -ag terminal-overrides ",xterm-256color:RGB"
set -g automatic-rename off
set -g mouse on
set -g allow-passthrough on
set -g pane-border-format " #{pane_index} #{pane_current_command} "
set -g pane-border-status top
set -g pane-border-lines double

# Copy mode.
setw -g mode-keys vi
bind-key -T copy-mode-vi v send-keys -X begin-selection
bind-key -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "clip.exe"
bind-key -T copy-mode-vi Enter send-keys -X copy-pipe-and-cancel "clip.exe"
bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-no-clear "clip.exe"
bind-key -T copy-mode-vi WheelUpPane send-keys -X -N 5 scroll-up
bind-key -T copy-mode-vi WheelDownPane send-keys -X -N 5 scroll-down

# Plugins.
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'catppuccin/tmux'
set -g @plugin 'tmux-plugins/tmux-cpu'
set -g @plugin 'tmux-plugins/tmux-battery'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'

# Auto save/restore.
set -g @continuum-save-interval '15'
set -g @continuum-restore 'on'

# Prefix + Tab opens Yazi in a 50% right split.
bind Tab split-window -h -l 50% -c "#{pane_current_path}" "yazi"

# Catppuccin theme.
set -g @catppuccin_flavor 'mocha'
set -g @catppuccin_window_status_style 'rounded'
set -g status-left-length 40
set -g status-left "#{E:@catppuccin_status_session}"
set -g status-right-length 150
set -g @catppuccin_date_time_text " %m/%d %H:%M"
set -g status-right "#{E:@catppuccin_status_directory}"
set -ag status-right "#[bg=default] #[fg=#a6e3a1,bg=#313244] #(cd #{pane_current_path}; git rev-parse --abbrev-ref HEAD 2>/dev/null || echo '-') "
set -ag status-right "#[bg=default] #[fg=#89b4fa,bg=#313244] #{cpu_percentage} "
set -ag status-right "#[bg=default] #[fg=#f9e2af,bg=#313244] #{ram_percentage} "
set -ag status-right "#[bg=default] #[fg=#f5c2e7,bg=#313244] #{battery_icon} #{battery_percentage} "
set -ag status-right "#{E:@catppuccin_status_date_time}"
set -g @catppuccin_window_text " #I:#{=10:window_name} "
set -g @catppuccin_window_current_text " #[bold] *#I:#W* "

# Pane navigation without prefix: Alt+h/j/k/l.
bind -n M-h select-pane -L
bind -n M-j select-pane -D
bind -n M-k select-pane -U
bind -n M-l select-pane -R
bind L last-window
bind r source-file ~/.tmux.conf \; display "Reloaded!"

run '~/.tmux/plugins/tpm/tpm'
TMUXCONF

echo "[6/7] Installing tmux plugins"
"$HOME/.tmux/plugins/tpm/bin/install_plugins"

echo "[7/7] Verifying"
tmux -V
yazi --version
tmux start-server
tmux display-message -p "Prefix: #{prefix}"
tmux show-option -g @continuum-save-interval
tmux show-option -g @continuum-restore

echo
echo "tmux/yazi setup complete."
echo "Start with: tmux new -s main"
