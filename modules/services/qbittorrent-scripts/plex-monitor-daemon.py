#!/usr/bin/env python3
"""
qBittorrent + Plex Monitor Daemon
Continuously monitors qBittorrent for completed torrents and automatically
creates hardlinks in Plex media directories.
"""

import os
import sys
import time
import json
import logging
import subprocess
from pathlib import Path
from typing import Dict, Set, Optional
import requests

# Configuration
QBITTORRENT_URL = os.getenv("QBITTORRENT_URL", "http://localhost:8080")
PLEX_URL = os.getenv("PLEX_URL", "http://localhost:32400")
PLEX_TOKEN_FILE = "/etc/plex/token"
PLEX_MOVIES_SECTION = os.getenv("PLEX_MOVIES_SECTION", "1")
PLEX_TV_SECTION = os.getenv("PLEX_TV_SECTION", "2")

# Paths
MOVIES_DIR = Path("/mnt/torrents/plex/Movies")
TV_DIR = Path("/mnt/torrents/plex/TV Shows")
STATE_FILE = Path("/var/lib/qbittorrent/processed_torrents.json")
LOG_FILE = "/var/log/plex-monitor.log"

# Polling interval
POLL_INTERVAL = int(os.getenv("POLL_INTERVAL", "30"))  # seconds

# Setup logging
logging.basicConfig(
    level=logging.INFO,
    format='[%(asctime)s] %(levelname)s: %(message)s',
    handlers=[
        logging.FileHandler(LOG_FILE),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger(__name__)


class PlexMonitor:
    def __init__(self):
        self.processed_hashes: Set[str] = self.load_state()
        self.plex_token: Optional[str] = self.load_plex_token()
        self.session = requests.Session()

    def load_state(self) -> Set[str]:
        """Load previously processed torrent hashes"""
        if STATE_FILE.exists():
            try:
                with open(STATE_FILE, 'r') as f:
                    data = json.load(f)
                    return set(data.get('processed', []))
            except Exception as e:
                logger.warning(f"Failed to load state: {e}")
        return set()

    def save_state(self):
        """Save processed torrent hashes"""
        try:
            STATE_FILE.parent.mkdir(parents=True, exist_ok=True)
            with open(STATE_FILE, 'w') as f:
                json.dump({'processed': list(self.processed_hashes)}, f)
        except Exception as e:
            logger.error(f"Failed to save state: {e}")

    def load_plex_token(self) -> Optional[str]:
        """Load Plex authentication token"""
        try:
            if os.path.exists(PLEX_TOKEN_FILE):
                with open(PLEX_TOKEN_FILE, 'r') as f:
                    token = f.read().strip()
                    logger.info("Plex token loaded successfully")
                    return token
        except Exception as e:
            logger.warning(f"Failed to load Plex token: {e}")
        logger.warning("Plex token not found - library scans will be skipped")
        return None

    def get_completed_torrents(self) -> list:
        """Get list of completed torrents from qBittorrent"""
        try:
            response = self.session.get(f"{QBITTORRENT_URL}/api/v2/torrents/info")
            response.raise_for_status()
            torrents = response.json()

            # Filter completed torrents (progress = 1.0)
            completed = [t for t in torrents if t.get('progress', 0) == 1.0]
            return completed
        except Exception as e:
            logger.error(f"Failed to get torrents: {e}")
            return []

    def is_movie(self, name: str, content_path: str) -> bool:
        """Detect if content is a movie"""
        import re

        # Video file extensions (including Bluray formats)
        video_extensions = ('.mkv', '.mp4', '.avi', '.mov', '.wmv', '.m4v', '.mpg', '.mpeg', '.iso', '.m2ts', '.ts')

        # First check: Year pattern with flexible separators
        year_patterns = [
            r'\(19\d{2}\)',  # (1964), (2007)
            r'\(20\d{2}\)',  # (2010), (2024)
            r'[.\-\s](19\d{2})[.\-\s]',  # .1964., -1985-
            r'[.\-\s](20\d{2})[.\-\s]',  # .2007., -2010-
            r'[.\-\s](19\d{2})$',  # ends with year
            r'[.\-\s](20\d{2})$',  # ends with year
        ]

        has_year = any(re.search(pattern, name) for pattern in year_patterns)

        # Check if it's a TV show first (to exclude from movie detection)
        if self.is_tv_show(name, content_path):
            return False

        # If has year, check for video content
        if has_year:
            if any(content_path.lower().endswith(ext) for ext in video_extensions):
                return True
            if os.path.isdir(content_path):
                try:
                    for root, dirs, files in os.walk(content_path):
                        if any(f.lower().endswith(video_extensions) for f in files):
                            return True
                        if any(d in ['BDMV', 'VIDEO_TS', 'STREAM'] for d in dirs):
                            return True
                except Exception:
                    pass

        # Fallback: No year but is a video file -> assume it's a movie
        # This handles files like "Coraline.mkv" or "MovieName.mp4"
        if any(content_path.lower().endswith(ext) for ext in video_extensions):
            return True

        # Fallback: Directory with video files -> assume it's a movie
        if os.path.isdir(content_path):
            try:
                for root, dirs, files in os.walk(content_path):
                    if any(f.lower().endswith(video_extensions) for f in files):
                        return True
                    if any(d in ['BDMV', 'VIDEO_TS', 'STREAM'] for d in dirs):
                        return True
            except Exception:
                pass

        return False

    def is_tv_show(self, name: str, content_path: str = None) -> bool:
        """
        Detect if content is a TV show.
        Checks both torrent name and file contents for season/episode patterns.
        """
        import re

        # Check for season/episode patterns in name
        patterns = [
            r'[Ss]\d{2}[Ee]\d{2}',  # S01E01
            r'\d{1,2}x\d{2}',       # 1x01
            r'[Ss]\d{2}[^Ee]',      # S01 (season pack without episode)
            r'[Ss]eason\s*\d{1,2}', # Season 01, season 1
        ]

        if any(re.search(pattern, name) for pattern in patterns):
            return True

        # Fallback: Check file contents if torrent name doesn't match
        # This handles torrents named "Show Name Season 1 Complete"
        if content_path and os.path.isdir(content_path):
            try:
                for root, dirs, files in os.walk(content_path):
                    for f in files:
                        if any(re.search(r'[Ss]\d{2}[Ee]\d{2}', f) for _ in [1]):
                            logger.debug(f"Detected TV show from file: {f}")
                            return True
                    # Only check first level to avoid deep recursion
                    break
            except Exception as e:
                logger.debug(f"Error checking files: {e}")

        return False

    def extract_show_info(self, name: str, content_path: str = None) -> tuple:
        """
        Extract show name and season number from filename.
        Returns: (show_name, season_number)

        Examples:
          Shameless.S01E01.Pilot.mkv -> ("Shameless", "01")
          Shameless.S01.1080p.mkv -> ("Shameless", "01")
          The.Office.US.S02E05.mkv -> ("The Office US", "02")
          Friends.1x05.mkv -> ("Friends", "01")
          Shameless Season 1 Complete -> ("Shameless", "01")
        """
        import re

        # Try S##E## format first (most common)
        season_match = re.search(r'[Ss](\d{2})[Ee]\d{2}', name)
        if season_match:
            season_num = season_match.group(1)
            show_name = name[:season_match.start()]
            show_name = re.sub(r'[._-]+$', '', show_name)
            show_name = show_name.replace('.', ' ').replace('_', ' ').strip()
            return (show_name, season_num)

        # Try S## only (season pack without episode number)
        season_match = re.search(r'[Ss](\d{2})', name)
        if season_match:
            season_num = season_match.group(1)
            show_name = name[:season_match.start()]
            show_name = re.sub(r'[._-]+$', '', show_name)
            show_name = show_name.replace('.', ' ').replace('_', ' ').strip()
            return (show_name, season_num)

        # Try #x## format
        season_match = re.search(r'(\d{1,2})x\d{2}', name)
        if season_match:
            season_num = season_match.group(1).zfill(2)
            show_name = name[:season_match.start()]
            show_name = re.sub(r'[._-]+$', '', show_name)
            show_name = show_name.replace('.', ' ').replace('_', ' ').strip()
            return (show_name, season_num)

        # Try "Season X" format
        season_match = re.search(r'[Ss]eason\s*(\d{1,2})', name)
        if season_match:
            season_num = season_match.group(1).zfill(2)
            show_name = name[:season_match.start()]
            show_name = re.sub(r'[._-]+$', '', show_name)
            show_name = show_name.replace('.', ' ').replace('_', ' ').strip()
            return (show_name, season_num)

        # Fallback: Check first file in directory
        if content_path and os.path.isdir(content_path):
            try:
                for root, dirs, files in os.walk(content_path):
                    for f in files:
                        if f.lower().endswith(('.mkv', '.mp4', '.avi')):
                            # Try to extract from first video file
                            result = self.extract_show_info(f)
                            if result[0] is not None:
                                logger.info(f"Extracted show info from file: {f}")
                                return result
                    break
            except Exception:
                pass

        # Fallback: couldn't extract info
        return (None, None)

    def create_hardlink(self, source: Path, target: Path, show_name: str = None, season_num: str = None) -> bool:
        """
        Create hardlink from source to target.
        For TV shows, organizes into Show Name/Season XX/ structure.
        """
        try:
            # Ensure source exists
            if not source.exists():
                logger.error(f"Source does not exist: {source}")
                return False

            # For TV shows, create proper directory structure
            if show_name and season_num:
                # Create: /TV Shows/Show Name/Season XX/
                show_dir = target / show_name
                season_dir = show_dir / f"Season {season_num}"
                season_dir.mkdir(parents=True, exist_ok=True)
                target = season_dir
                logger.info(f"Organizing into: {show_name}/Season {season_num}/")

            # Ensure target parent directory exists
            target.parent.mkdir(parents=True, exist_ok=True)

            if source.is_dir():
                # For directories (season packs), create hardlinks for all files
                logger.info(f"Creating hardlinks for directory: {source.name}")

                # For TV shows, link files directly into season folder (not nested)
                if show_name and season_num:
                    for root, dirs, files in os.walk(source):
                        for f in files:
                            # Only link video files to avoid clutter
                            if f.lower().endswith(('.mkv', '.mp4', '.avi', '.mov', '.wmv', '.m4v', '.mpg', '.mpeg')):
                                src_file = Path(root) / f
                                tgt_file = target / f

                                if not tgt_file.exists():
                                    try:
                                        os.link(src_file, tgt_file)
                                        logger.debug(f"Linked: {f}")
                                    except Exception as e:
                                        logger.warning(f"Failed to link {f}: {e}")
                else:
                    # Movies: keep original directory structure
                    target_base = target / source.name
                    target_base.mkdir(parents=True, exist_ok=True)

                    for root, dirs, files in os.walk(source):
                        rel_root = Path(root).relative_to(source)
                        target_root = target_base / rel_root

                        # Create subdirectories
                        for d in dirs:
                            (target_root / d).mkdir(parents=True, exist_ok=True)

                        # Create hardlinks for files
                        for f in files:
                            src_file = Path(root) / f
                            tgt_file = target_root / f

                            if not tgt_file.exists():
                                try:
                                    os.link(src_file, tgt_file)
                                    logger.debug(f"Linked: {f}")
                                except Exception as e:
                                    logger.warning(f"Failed to link {f}: {e}")

                logger.info(f"✅ Directory hardlinked successfully")
                return True
            else:
                # Single file
                target_file = target / source.name
                if not target_file.exists():
                    os.link(source, target_file)
                    logger.info(f"✅ File hardlinked: {source.name}")
                return True

        except Exception as e:
            logger.error(f"Failed to create hardlink: {e}")
            return False

    def scan_plex_library(self, section_id: str, name: str):
        """Trigger Plex library scan"""
        if not self.plex_token:
            logger.warning("Plex token not configured, skipping scan")
            return

        try:
            url = f"{PLEX_URL}/library/sections/{section_id}/refresh?X-Plex-Token={self.plex_token}"
            response = self.session.get(url, timeout=10)

            if response.status_code == 200:
                logger.info(f"📺 Triggered Plex scan for {name} library")
            else:
                logger.warning(f"Failed to scan Plex library: HTTP {response.status_code}")
        except Exception as e:
            logger.error(f"Failed to scan Plex library: {e}")

    def process_torrent(self, torrent: Dict):
        """Process a completed torrent"""
        hash_id = torrent.get('hash', '')
        name = torrent.get('name', '')
        content_path = torrent.get('content_path', '')
        save_path = torrent.get('save_path', '')

        # Skip if already processed
        if hash_id in self.processed_hashes:
            return

        logger.info(f"Processing: {name}")

        # Determine content path
        if not content_path:
            logger.warning(f"No content path for: {name}")
            return

        source = Path(content_path)

        # Detect media type and organize
        processed = False

        if self.is_movie(name, content_path):
            logger.info(f"🎬 Detected movie: {name}")
            if self.create_hardlink(source, MOVIES_DIR):
                self.scan_plex_library(PLEX_MOVIES_SECTION, "Movies")
                processed = True

        elif self.is_tv_show(name, content_path):
            logger.info(f"📺 Detected TV show: {name}")
            # Extract show name and season
            show_name, season_num = self.extract_show_info(name, content_path)

            if show_name and season_num:
                logger.info(f"   Show: {show_name}, Season: {season_num}")
                if self.create_hardlink(source, TV_DIR, show_name, season_num):
                    self.scan_plex_library(PLEX_TV_SECTION, "TV Shows")
                    processed = True
            else:
                logger.warning(f"Could not extract show info from: {name}")
                # Fallback: create without proper structure
                if self.create_hardlink(source, TV_DIR):
                    self.scan_plex_library(PLEX_TV_SECTION, "TV Shows")
                    processed = True

        else:
            logger.info(f"ℹ️  Media type not detected: {name}")

        # Mark as processed
        self.processed_hashes.add(hash_id)
        self.save_state()

        if processed:
            logger.info(f"✅ Successfully organized: {name}")

    def run(self):
        """Main daemon loop"""
        logger.info("=" * 60)
        logger.info("🚀 Plex Monitor Daemon Started")
        logger.info(f"Monitoring qBittorrent at: {QBITTORRENT_URL}")
        logger.info(f"Movies directory: {MOVIES_DIR}")
        logger.info(f"TV Shows directory: {TV_DIR}")
        logger.info(f"Poll interval: {POLL_INTERVAL} seconds")
        logger.info("=" * 60)

        while True:
            try:
                # Get completed torrents
                torrents = self.get_completed_torrents()

                if torrents:
                    new_completed = [t for t in torrents if t.get('hash') not in self.processed_hashes]

                    if new_completed:
                        logger.info(f"Found {len(new_completed)} new completed torrents")

                        for torrent in new_completed:
                            self.process_torrent(torrent)

                # Sleep before next poll
                time.sleep(POLL_INTERVAL)

            except KeyboardInterrupt:
                logger.info("Shutting down gracefully...")
                break
            except Exception as e:
                logger.error(f"Error in main loop: {e}")
                time.sleep(POLL_INTERVAL)


if __name__ == "__main__":
    monitor = PlexMonitor()
    monitor.run()
