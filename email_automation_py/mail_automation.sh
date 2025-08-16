#!/bin/bash

# Email Automation Runner Script (Mac/Linux)
# This script activates the virtual environment and runs the email automation program

echo "Starting Email Automation..."

# Check if virtual environment exists
if [ ! -d "venv" ]; then
    echo "Virtual environment not found. Creating one..."
    python3 -m venv venv
    echo "Virtual environment created."
fi

# Activate virtual environment
echo "Activating virtual environment..."
source venv/bin/activate

# Install requirements if needed
if [ -f "requirements.txt" ]; then
    echo "Installing/updating requirements..."
    pip install -r requirements.txt
fi

# Run the email automation program
echo "Running email automation program..."
python email_automation.py

# Deactivate virtual environment when done
deactivate
echo "Email automation stopped."