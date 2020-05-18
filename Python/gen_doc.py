import os
import sys
os.system(os.path.join(sys.exec_prefix, r"Scripts/sphinx-build") + " -b html .\documentation\source .\documentation\html")
