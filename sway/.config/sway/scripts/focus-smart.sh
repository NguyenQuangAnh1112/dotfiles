#!/bin/sh
# Smart cross-monitor & within-workspace focus script for Sway.
# 1. Di chuyển giữa các window trong cùng workspace nếu còn window theo hướng $dir.
# 2. Nếu đã ở mép ngoài cùng: chuyển sang màn hình kế bên và focus ĐÍCH DANH window cuối cùng đang active
#    bằng cú pháp: focus output <out>; workspace "<ws>"; [con_id=<win_id>] focus
#    -> Giúp terminal/Neovim nhận trọn vẹn bàn phím, con trỏ hoạt động ngay (không bị rỗng/mất focus).

set -e
dir=${1:?usage: focus-smart.sh <left|right|up|down>}

cmd=$(swaymsg -t get_tree | jq -r --arg dir "$dir" '
  # Danh sách tất cả màn hình đang hoạt động
  [ .nodes[] | select(.rect.width > 0) ] as $outputs |
  ($outputs[] | select(.. | .focused? == true)) as $cur_out |
  ($cur_out | .. | select(.type? == "workspace" and (.. | .focused? == true))) as $cur_ws |
  ($cur_ws | .. | select(.focused? == true and (.type? == "con" or .type? == "floating_con"))) as $cur_win |

  # Kiểm tra xem trong cùng workspace có window nào nằm theo hướng $dir không
  (
    if $cur_win then
      [
        $cur_ws | .. | select((.type? == "con" or .type? == "floating_con") and .id != $cur_win.id and .rect.width > 0) |
        select(
          if $dir == "left" then .rect.x + .rect.width <= $cur_win.rect.x + ($cur_win.rect.width / 2)
          elif $dir == "right" then .rect.x >= $cur_win.rect.x + ($cur_win.rect.width / 2)
          elif $dir == "up" then .rect.y + .rect.height <= $cur_win.rect.y + ($cur_win.rect.height / 2)
          else .rect.y >= $cur_win.rect.y + ($cur_win.rect.height / 2)
          end
        )
      ]
    else
      []
    end
  ) as $in_ws_candidates |

  if ($in_ws_candidates | length) > 0 then
    # Vẫn còn window trong workspace theo hướng này -> focus trong workspace
    "focus \($dir)"
  else
    # Đã ở mép ngoài cùng -> tìm màn hình kế bên theo hướng không gian
    (
      if $dir == "left" then
        [ $outputs[] | select(.rect.x + .rect.width <= $cur_out.rect.x) ] | sort_by(-.rect.x) | first
      elif $dir == "right" then
        [ $outputs[] | select(.rect.x >= ($cur_out.rect.x + $cur_out.rect.width)) ] | sort_by(.rect.x) | first
      elif $dir == "up" then
        [ $outputs[] | select(.rect.y + .rect.height <= $cur_out.rect.y) ] | sort_by(-.rect.y) | first
      else
        [ $outputs[] | select(.rect.y >= ($cur_out.rect.y + $cur_out.rect.height)) ] | sort_by(.rect.y) | first
      end
    ) as $target_out |

    if $target_out then
      ($target_out.current_workspace // ($target_out | .. | select(.type? == "workspace") | .name)) as $ws_name |
      ($target_out | .. | select(.type? == "workspace" and .name == $ws_name) | .focus[0] // empty) as $target_win |
      if $target_win then
        "focus output \($target_out.name); workspace \"\($ws_name)\"; [con_id=\($target_win)] focus"
      else
        "focus output \($target_out.name); workspace \"\($ws_name)\""
      end
    else
      empty
    end
  end
')

[ -n "$cmd" ] && swaymsg "$cmd" >/dev/null
