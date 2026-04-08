"""Local CDK constructs for the project.

This package name intentionally matches the physical directory 'constructs/'
per the scaffold specification. It collides with the CDK 'constructs' pip
package, so this __init__.py delegates to the real package and extends its
module path to include local construct files.

After this runs:
  from constructs import Construct          → CDK base class
  from constructs.monitored_table import X  → local construct
"""
import importlib
import os
import sys

_local_path = list(__path__)
_app_dir = os.path.normpath(
    os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
)

if __name__ in sys.modules:
    del sys.modules[__name__]

_saved_path = sys.path[:]
sys.path = [
    p for p in sys.path
    if os.path.normpath(os.path.abspath(p)) != _app_dir
]

_real = importlib.import_module("constructs")

sys.path = _saved_path
_real.__path__ = list(_real.__path__) + _local_path
sys.modules[__name__] = _real
