# 01 - Introduction 

Oct 5 2026

### MANAGE VIEW OF CONTAINER
``` docker ps -a ```

### To delete containers
``` docker rm $(docker ps -aq)```

### Sample container command
```
docker run -it \
    --rm \
    --entrypoint=bash \
    python:3.9.16-slim
```

### Create directory and file for testing ```test\list_files.py```
```
mkdir test
cd test
touch file1.txt file2.txt file3.txt
echo "Hello from host" > file1.txt
cd ..
```

### Script that shows the files in a folder
```
from pathlib import Path

current_dir = Path.cwd()
current_file = Path(__file__).name

print(f"Files in {current_dir}:")

for filepath in current_dir.iterdir():
    if filepath.name == current_file:
        continue

    print(f"  - {filepath.name}")

    if filepath.is_file():
        content = filepath.read_text(encoding='utf-8')
        print(f"    Content: {content}")

```

Oct 14

### Docker command that runs container and maps volume
```
docker run -it \
    --rm \
    -v $(pwd)/test:/app/test \
    --entrypoint=bash \
    python:3.9.16-slim

```

### then inside the container run this
```
cd /app/test
ls -la
cat file1.txt
python list_files.py
```

# 02 - Virtual Environment

DIAGRAM INSERT HERE

we'll build a pipelines that:

    Download CSV data from the web
    Transform and clean the data with pandas
    Load it into PostgreSQL for querying
    Process data in chunks to handle large files

### Creating simple pipeline

create an example pipeline. First, create a directory `pipeline` and inside, create a file `pipeline.py`:

Below is script for `pipeline.py`
```
import sys
import pandas as pd

print("arguments", sys.argv)

day = int(sys.argv[1])

df = pd.DataFrame({"A": [1, 2], "B": [3, 4]})
print(df.head())

df.to_parquet(f"output_day_{sys.argv[1]}.parquet")

print(f"Running pipeline for day {day}")

```

### Using uv - Modern Pythin Package Manager

```
pip install uv
```

#### Now initializw a Python project with uv:
```
uv init --python=3.13
```
This will create pyproject.toml file for managing dependecies and a `.python-version` file.

#### Adding Dependencies
This will add the below to `project.toml`
```
uv add pandas pyarrow
```

### Running pipeline 
```
uv run python pipeline.py
```
Output is:
```
arguments ['pipeline.py', '10']
   A  B
0  1  3
1  2  4
Running pipeline for day 10
```

### Git config
the script produces a binary (parquet) file, make sure to add the below in `.gitignore` so we dont commit the output file
```
*.parquet
```
