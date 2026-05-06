export GTK_IM_MODULE=fcitx
export QT_IM_MODULE=fcitx
export XMODIFIERS=@im=fcitx
# Keep the i3 session on the X11 backend.
export XDG_SESSION_TYPE=x11
export XCURSOR_THEME=Bibata-Modern-Ice
export XCURSOR_SIZE=32

xrdb -merge ~/.Xresources

exec i3
