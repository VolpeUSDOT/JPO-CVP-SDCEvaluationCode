import os
import subprocess
import eventPlaybackBackend

os.environ['FLASK_APP'] = 'eventPlaybackBackend.py'

os.environ['FLASK_ENV'] = 'development'

if __name__ == '__main__':
    eventPlaybackBackend.app.run(port=5000)