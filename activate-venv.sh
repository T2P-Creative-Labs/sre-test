#!/bin/bash
# Activation script for the Ansible virtual environment

echo "Activating virtual environment for Ansible..."
source venv/bin/activate

echo "Virtual environment activated!"
echo "Python path: $(which python)"
echo "Ansible version: $(ansible --version | head -1)"
echo ""
echo "To deactivate, run: deactivate"
echo "To run deployments, use: ./scripts/ansible-deploy.sh"
