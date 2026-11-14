import pandas as pd
import sys
from pathlib import Path

sys.path.append(str(Path.cwd().parent))   # notebook's folder -> its parent

from practice_data import TABLES, typed_rows, EXPECTED_COUNTS


pd.set_option("display.max_rows", None)
pd.set_option("display.max_columns", None)
pd.set_option("display.width", None)

def load_pandas(name):
    types = TABLES[name]["types"]
    df = pd.DataFrame(typed_rows(name), columns=list(types))
    for col, kind in types.items():
        if kind == "DATE":
            df[col] = pd.to_datetime(df[col])
        elif kind.startswith("DECIMAL"):
            df[col] = df[col].astype(float)
    return df