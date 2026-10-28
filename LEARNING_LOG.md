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
Oct 28

# 03 - Dockerizing the Pipeline
Let us containerize the script. Create the following `Dockerfile` file:

```
# base Docker image that we will build on
FROM python:3.13.11-slim

# set up our image by installing prerequisites; pandas in this case
RUN pip install pandas pyarrow

# set up the working directory inside the container
WORKDIR /app
# copy the script to the container. 1st name is source file, 2nd is destination
COPY pipeline.py pipeline.py

# define what to do first when the container runs
# in this example, we will just run the script
ENTRYPOINT ["python", "pipeline.py"]
```
Explanation:

- `FROM`: Base image (Python 3.13)
- `RUN`: Execute commands during build
- `WORKDIR`: Set working directory
- `COPY`: Copy files into the image
- `ENTRYPOINT`: Default command to run

#### Build and Run
```
docker build -t test:pandas .
```
- The image name will be `test` and its tag will be `pandas`. If a tag isn't specified, it will default to `latest`.

We can now run the container and pass an argument, so that our pipeline will receive it
```
docker run -it test:pandas <some_number>
```
#### It should return the same output as before

### Dockerfile with uv
An alternative to using `pip` in the previous `Dockerfile`:
```
# Start with slim Python 3.13 image
FROM python:3.13.10-slim

# Copy uv binary from official uv image (multi-stage build pattern)
COPY --from=ghcr.io/astral-sh/uv:latest /uv /bin/

# Set working directory
WORKDIR /app

# Add virtual environment to PATH so we can use installed packages
ENV PATH="/app/.venv/bin:$PATH"

# Copy dependency files first (better layer caching)
COPY "pyproject.toml" "uv.lock" ".python-version" ./
# Install dependencies from lock file (ensures reproducible builds)
RUN uv sync --locked

# Copy application code
COPY pipeline.py pipeline.py

# Set entry point
ENTRYPOINT ["uv", "run", "python", "pipeline.py"]
```

# 04 - Running PostgreSQL with Docker

Create a folder where you'd like Postgres to stroe data in. We will use this example folder `ny_taxi_postgres_data`. Here's how to run the container:

```
docker run -it --rm \
  -e POSTGRES_USER="root" \
  -e POSTGRES_PASSWORD="root" \
  -e POSTGRES_DB="ny_taxi" \
  -v ny_taxi_postgres_data:/var/lib/postgresql \
  -p 5432:5432 \
  postgres:18
```
#### Explanation of Parameters
- `-e` sets environment variables (user, password, database name)
- `-v` ny_taxi_postgres_data:/var/lib/postgresql creates a named volume
  - Docker manages this volume automatically
  - Data persists even after container is removed
  - Volume is stored in Docker's internal storage
- `-p 5432:5432` maps port 5432 from container to host
- `postgres:18` uses PostgreSQL version 18 (latest as of Dec 2025)

#### Alternative Approach - Bind Mount
First create the directory, then map it:

```
mkdir ny_taxi_postgres_data

docker run -it \
  -e POSTGRES_USER="root" \
  -e POSTGRES_PASSWORD="root" \
  -e POSTGRES_DB="ny_taxi" \
  -v $(pwd)/ny_taxi_postgres_data:/var/lib/postgresql \
  -p 5432:5432 \
  postgres:18
```
#### Named Volume vs Bind Mount
- Named volume (name:/path): Managed by Docker, easier
- Bind mount (/host/path:/container/path): Direct mapping to host filesystem, more control

### Connecting to PostgreSQL

Once the container is running, we can log into the database using pgcli

Install pgcli
```
uv add --dev pgcli
```

The `--dev` flag marks it as a developement dependency (no need in prod). It will be added to the `[dependency-groups]` section of `pyproject.toml` instead of the main `dependencies` section.

Now use it to connect to Postgres:
```
uv run pgcli -h localhost -p 5432 -u root -d ny_taxi
```

- `uv` run executes a command in the context of the virtual environment
- `-h` is the host. Since we're running locally we can use localhost.
- `-p` is the port.
- `-u` is the username.
- `-d` is the database name.
- The password is not provided; it will be requested after running the command.

When prompted, enter the password: `root`

### Basic SQL
Try in Postgres:

```
-- List tables
\dt

-- Create a test table
CREATE TABLE test (id INTEGER, name VARCHAR(50));

-- Insert data
INSERT INTO test VALUES (1, 'Hello Docker');

-- Query data
SELECT * FROM test;

-- Exit
\q
```
