#!/usr/bin/env python3

import sys
import subprocess
import json

try:
    from AppKit import NSWorkspace, NSRunningApplication
    from Foundation import NSBundle
    
    # Get Spark's bundle identifier
    spark_bundle_id = "com.readdle.SparkDesktop.appstore"
    
    # Get all running applications
    workspace = NSWorkspace.sharedWorkspace()
    running_apps = workspace.runningApplications()
    
    # Find Spark
    spark_app = None
    for app in running_apps:
        if app.bundleIdentifier() == spark_bundle_id:
            spark_app = app
            break
    
    if spark_app:
        # Try to get badge from Dock tile
        # Note: NSRunningApplication doesn't directly expose badge, but we can try
        # The badge is typically stored in the Dock's plist or accessed via private APIs
        
        # Alternative: Check if there's a way to get it via the app's userInfo
        # For now, we'll return 0 and let the shell script try other methods
        badge = spark_app.dockTile().badgeLabel()
        if badge:
            print(badge)
        else:
            print("0")
    else:
        print("0")
        
except ImportError:
    # PyObjC not available, fall back to 0
    print("0")
except Exception as e:
    # Any error, return 0
    print("0")
