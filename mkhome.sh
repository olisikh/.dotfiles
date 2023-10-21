#!/bin/bash

# Rebuild home
nix run .#homeConfigurations.olisikh.activationPackage --impure --show-trace

