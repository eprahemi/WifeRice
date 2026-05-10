#!/usr/bin/env bash
STEP=0.04
case "${1:-}" in
  raise)
    wpctl set-volume @DEFAULT_AUDIO_SINK@ "$STEP"+
    ;;
  lower)
    wpctl set-volume @DEFAULT_AUDIO_SINK@ "$STEP"-
    ;;
  mute-toggle)
    wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle
    ;;
esac
