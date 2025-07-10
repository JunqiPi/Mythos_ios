#!/usr/bin/env python3
"""
Simple script to create a basic Xcode project for MythosApp
"""

import os
import subprocess

def create_basic_ios_project():
    print("Creating new iOS project...")
    
    # Create a basic iOS app project using xcodegen or manual creation
    # For now, let's use the swift package approach with proper iOS configuration
    
    os.chdir("/Users/minsun/mythos/Mythos_ios/MythosApp")
    
    # Create a simple iOS app using swift package manager with proper platform
    result = subprocess.run([
        "swift", "package", "init", "--type", "executable", "--name", "MythosApp"
    ], capture_output=True, text=True)
    
    print("Created basic package structure")
    return True

if __name__ == "__main__":
    create_basic_ios_project()