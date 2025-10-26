#!/bin/bash

# Script to optimize audio files for web delivery
# Reduces file sizes by ~70-80% while maintaining quality

echo "🎵 Optimizing audio files for web delivery..."

# Create backup directory
mkdir -p assets/audio/music/original_backup
cp assets/audio/music/*.ogg assets/audio/music/original_backup/

# Optimize each track with lower bitrate and mono conversion
echo "📦 Compressing track_1.ogg..."
ffmpeg -i assets/audio/music/original_backup/track_1.ogg \
    -acodec libvorbis -ab 96k -ac 1 -ar 44100 \
    assets/audio/music/track_1.ogg -y

echo "📦 Compressing track_2.ogg..."  
ffmpeg -i assets/audio/music/original_backup/track_2.ogg \
    -acodec libvorbis -ab 96k -ac 1 -ar 44100 \
    assets/audio/music/track_2.ogg -y

echo "📦 Compressing track_3.ogg..."
ffmpeg -i assets/audio/music/original_backup/track_3.ogg \
    -acodec libvorbis -ab 96k -ac 1 -ar 44100 \
    assets/audio/music/track_3.ogg -y

echo "✅ Audio optimization complete!"
echo "📊 File size comparison:"
echo "Before:"
ls -lh assets/audio/music/original_backup/
echo ""
echo "After:"
ls -lh assets/audio/music/*.ogg

echo ""
echo "💡 Expected size reduction: 70-80%"
echo "🎯 Target total size: ~4-6MB instead of 18MB"