touch /home/docadmin/.bash_aliases
echo "alias ..='cd ..'
alias ...='cd ../..'
alias h='cd ~'
alias c='clear'
alias ll='ls -la'" | tee -a $HOME/.bash_aliases
