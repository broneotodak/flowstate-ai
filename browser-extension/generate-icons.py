#!/usr/bin/env python3
import base64

# Simple blue square icon as base64 PNG
icon_16 = """iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAA7AAAAOwBeShxvQAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAABPSURBVDiN7Y4xCgAwCAN3/v+zHRxELYKD0DkItyQEQETkRkb1AaBqAS5nZ/cFmJkPgKoWYGcPzOwTwN0LsLNb/w7M7AWoun0Cd/8EZvaSDR4hKQ9nQ4ujAAAAAElFTkSuQmCC"""

icon_48 = """iVBORw0KGgoAAAANSUhEUgAAADAAAAAwCAYAAABXAvmHAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAA7AAAAOwBeShxvQAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAABwSURBVGiB7dihDcAwDETRl2XJMmQZsgyZJcswTJcFSiGDolCQ/S+5Vc4nOTkiIs6mqiZ2Zna8SxERd5IkSZKkf1TV5HneAfQk7T1PE5GZ2YGYGRFBP6mqiTnndQBXkvae0TSYmR2I3gfozOwXJEl64gGhiyUhjV/PCQAAAABJRU5ErkJggg=="""

icon_128 = """iVBORw0KGgoAAAANSUhEUgAAAIAAAACACAYAAADDPmHLAAAABHNCSVQICAgIfAhkiAAAAAlwSFlzAAAA7AAAAOwBeShxvQAAABl0RVh0U29mdHdhcmUAd3d3Lmlua3NjYXBlLm9yZ5vuPBoAAACXSURBVHic7duxDYAwDETRh2UsQxYiy5BlmC4LQAEUKATZeq9y5fycZEeSpL+oqsnd3V1EvCfOzKoGZmZHZGZExPshqmqCu7u7iIj3xJlZ1cDM7IjMjKn5PoADMjM6MDPb+wCOSLsPoKqmmJlddwAzs6qBu7u7iIj3xJlZ1cDM7IjMjIh4T5yaVQ3MzI7I9wFI0vAeEUUzCJdnGBsAAAAASUVORK5CYII="""

# Write the icon files
with open('icon16.png', 'wb') as f:
    f.write(base64.b64decode(icon_16))

with open('icon48.png', 'wb') as f:
    f.write(base64.b64decode(icon_48))

with open('icon128.png', 'wb') as f:
    f.write(base64.b64decode(icon_128))

print("Icons created!")