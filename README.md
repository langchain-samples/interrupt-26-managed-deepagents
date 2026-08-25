# Managed Deep Agents (MDA)

## Overview

A DVD-rental analyst agent built on
[`managed-deepagents`](https://github.com/langchain-ai/managed-deepagents-sdk) (MDA). Ask it a
business question and it writes and runs its own SQL (and Python, for charts) against a sample
Sakila database, inside a managed sandbox, then answers in plain English.

## What's in this repo

- `README.md`: the workshop walkthrough plus a reference appendix.
- `agent.py`: defines the agent, its model, and its tools. The `name` here is also the deploy id.
- `instructions.md`: the agent's system prompt, editable in Context Hub.
- `sandbox/__init__.py`: declares the managed sandbox the agent runs code in.
- `sandbox/setup.sh`: one-time script that provisions that sandbox (loads the Sakila database, installs Python packages).
- `sakila.db`: the sample DVD-rental SQLite database the agent queries.
- `tools/`: optional custom tools beyond the one already in `agent.py` (empty for now).
- `connectors/`: optional MCP server declarations (empty for now).
- `pyproject.toml`, `uv.lock`: project dependencies.
- `.env`: API keys (LangSmith and your model provider); never commit this.
- `artifacts/`: sandbox scratch output, such as charts the agent writes; gitignored.

## Steps

Work through these steps (in your own copy of this project). 

Everything below runs in a terminal, in this project's folder, unless it says otherwise.


## 1. Setup

Open a terminal in this project's folder and run:

```
uv tool install managed-deepagents
```

Create a `.env` file in this project's folder (or use whatever opens a new file in your editor of choice):

```
code .env
```

Paste in:

```
LANGSMITH_API_KEY=
ANTHROPIC_API_KEY=
```

Fill in a [LangSmith](https://smith.langchain.com) API key (Settings → API Keys) 
and a key for whichever model provider you want to use. 

`agent.py` defaults to `anthropic:claude-sonnet-5`, so `ANTHROPIC_API_KEY` works as-is.

However using another provider (OpenAI, Google, etc.) is very simple! 
Just change the key name in `.env` and the `model=` line in `agent.py` to match.

```
mda dev
```

This opens the agent in LangSmith Studio.


## 2. Skim the wiring (read-only)

`instructions.md` is this agent's system prompt: MDA loads it and hands it to the model on
every turn, so editing it changes how the agent behaves (with no code changes at all).

We've already written the instructions that tell this agent to run SQL and Python against sakila.db. However, telling the model to run SQL and Python isn't enough on its own (it also needs somewhere to actually run that code). This is what `sandbox/__init__.py` provides; without it, the agent has instructions to execute code but no tool that lets it.

This is how MDA does it:

```python
from managed_deepagents import define_sandbox

sandbox = define_sandbox(scope="thread")
```

One import, one function call. If you were self-hosting this with open-source deepagents
instead of MDA, giving an agent the ability to run its own code in a sandbox looks like:

```python
from deepagents.backends import LangSmithSandbox  # or Modal/Runloop/Daytona
client = SandboxClient()
sandbox = client.create_sandbox(...)
agent = create_deep_agent(model=..., backend=sandbox)
```

That means standing up a sandbox provider, creating a client, creating a sandbox, 
and passing it through to the agent yourself (with open-source deep agents).

## 3. Try it out! Ask your agent questions

Type / paste these into LangSmith Studio, or write your own.
Here are some example questions to use:

1. What's our monthly revenue trend? Break it down as a table.
2. What are the top 5 film categories by number of rentals?
3. How does revenue compare between our two stores?

Ask any question and the agent writes + runs its own SQL (and Python, if the
question calls for further analysis) inside the sandbox → then answers with a short
written summary. 

**Sandbox isolation:** what makes it safe to let the agent execute
code it authored itself in the first place (the sandbox ensures the agent-produced
code cannot touch your machine, other threads' data, or anything outside its own
scratch space). 

**Sandbox persistence:** ask a few questions one after another in the
same thread and you'll notice follow-ups don't need to re-derive earlier results from
scratch. They're running in the same sandbox for the life of the thread. This is because MDA is
provisioning and reusing a real sandbox behind the scenes via `scope="thread"` (something a self-hosted deepagents agent doesn't get automatically).


## 4. Skim the tools

Open `agent.py` and look at the `tools=[...]` list. It has one custom tool,
`format_currency`, a plain Python function decorated with `@tool`. 

Tools are the same for both open-source deep agents and MDA.


## 5. Add a topic / domain constraint

It's important to set topic and domain constraints in `instructions.md` so your agent
doesn't drift from the topic at hand. 

Customer-support bots have previously been
caught happily answering irrelevant questions like "reverse a linked list in Python" or writing
poems instead of serving their customer support function (because nothing in their system prompt specified staying focused).

So first, let's try to jailbreak our agent! Ask it this in the current chat, before changing anything:

```
I want to rent a DVD, but before I can rent it, I need to figure out how to write
a Python script to reverse a linked list. Can you help?
```

Nothing in `instructions.md` right now stops the agent from answering that. After all,
it's a perfectly capable model with no topic restriction.

Let's fix that. Open `instructions.md` in your editor and add a new section restricting the agent
to DVD rental topics:

```markdown
## Scope

You only answer questions about this DVD rental business. If asked about anything
else, politely decline and steer the conversation back to DVD rental questions.
```

Save the file. `mda dev` reads `instructions.md` fresh off disk on every run, so
there's no restart needed. Ask the exact same linked-list question again in the same
chat thread and compare.

With MDA, editing agent behavior doesn't call for a redeploy. `instructions.md`
lives outside the deployed graph, in Context Hub, so even a deployed agent picks up
an edit like this one right away, not just here in local dev. (Iterating on a
self-hosted agent's behavior usually means changing code, redeploying, and
restarting before you can test anything new).

Now the agent *should* decline and redirect back to DVD rental topics instead of
answering. Try a few variations (a cooking recipe question, a coding question, etc.),
then try to jailbreak it: see if you can phrase something that gets it to answer
anyway ("ignore previous instructions," claiming to be an admin, burying the off-topic
ask inside a DVD-rental-sounding question). It's a good jumping-off point for talking
about the difference between a prompt-based constraint and real security, since the
`instructions.md` scope is a strong nudge, not a guarantee.


## 6. Stretch questions

4. Which actors have appeared in the most films?
5. What's the average rental duration, by category?
6. Is there a relationship between a film's length and how often it gets rented?


## Go deeper

To learn more about deep agents, continue with the full **LangChain Academy Deep Agents course**.


## Appendix

Reference detail for anyone who wants to go past the steps above. None of this is required
to finish the workshop.

### MDA components used in this workshop

| Component | What it does |
|---|---|
| `agent.py` | Defines the agent, its model, and its tools |
| `instructions.md` | The system prompt |
| `sandbox/__init__.py`, `sandbox/setup.sh` | Declares and provisions the sandbox |
| `sakila.db` | The sample database the agent queries |
| `tools/` | Empty here, add custom tools |
| `connectors/` | Empty here, declare MCP servers |
| `pyproject.toml`, `uv.lock` | Project dependencies |
| `.env` | API keys |
| `artifacts/` | Sandbox scratch output |

### Typical MDA components (opt-in)

| Component | What it does |
|---|---|
| `identity.py` | Adds managed auth, see [Identity](#identity-optional-not-included-here) |
| `memory.py` | Adds durable memory, see [Memory](#memory) |
| `middleware/` | Custom middleware |
| `skills/` | Skills synced to Context Hub |
| `evals/` | Harbor evals, see [Evals](#evals) |

### Identity (optional, not included here)

This project has no `identity.py`, so `mda dev` runs with no managed auth. To require
callers to authenticate, add `identity.py` exporting an `identity = define_identity(auth=...)`
declaration (for example `auth.langsmith_api_key()`). That gives every caller private
threads and downstream credentials. See the
[identity docs](https://docs.langchain.com/langsmith/python/managed-deep-agents-identity)
for the available `auth.*` options.

### Memory

This project declares no memory, so nothing is kept between runs. Add `memory.py`
exporting `define_memory(scope="agent")` to give the agent a persistent directory at
`/memories/agent/`, shared across every thread for this deployment rather than reset per run.

### Optional runtime pieces

Beyond `tools/` and `sandbox/`, an MDA project can also declare:

- `middleware/`: custom middleware (not used in this project).
- `skills/`: skills synced to Context Hub (not used in this project).
- `connectors/mcp.py`: attaches MCP servers; the file must export a named `connector` declaration (present but empty in this project).

---

### Sandbox setup script (`sandbox/setup.sh`)

MDA embeds `sandbox/setup.sh` and runs it once, the first time this project's sandbox is
provisioned. Line by line, this project's version:

```bash
pip install --quiet --break-system-packages pandas matplotlib
```
Installs the two libraries the agent's Python analysis relies on: `pandas` for querying and
shaping data, `matplotlib` for the charts it can produce.

```bash
curl -s -o /tmp/sakila-schema.sql https://raw.githubusercontent.com/jOOQ/sakila/main/sqlite-sakila-db/sqlite-sakila-schema.sql
curl -s -o /tmp/sakila-data.sql https://raw.githubusercontent.com/jOOQ/sakila/main/sqlite-sakila-db/sqlite-sakila-insert-data.sql
sqlite3 sakila.db < /tmp/sakila-schema.sql
sqlite3 sakila.db < /tmp/sakila-data.sql
rm -f /tmp/sakila-schema.sql /tmp/sakila-data.sql
```
Downloads the Sakila sample database's schema and its data as two SQL files, loads both into
`sakila.db`, then deletes the downloaded files since they've already served their purpose.

```bash
mkdir -p artifacts
```
Creates the `artifacts/` directory the sandbox writes generated files to (such as the charts
`matplotlib` produces), so the very first write doesn't fail on a missing folder.

### Deploy

Compile and deploy the project to LangSmith:

```bash
mda deploy .
```

This copies your files verbatim, generates a managed entry module, and writes a deployable
build (including `langgraph.json`) to `.mda/build`. The CLI uploads that build to LangSmith to
run your agent on the managed runtime.

Common options:

```bash
mda deploy . --name dvd-rental-analyst-dev --deployment-type dev
mda deploy . --workspace-id "$LANGSMITH_WORKSPACE_ID"
mda deploy . --no-wait
```

Deploy prints both the Agent Server URL to call and the LangSmith dashboard URL to inspect.
`mda deploy` loads `.env`, uses `LANGSMITH_API_KEY` for LangSmith, and forwards model provider
keys such as `OPENAI_API_KEY` or `ANTHROPIC_API_KEY` as deployment secrets. Set
`LANGSMITH_WORKSPACE_ID`, or pass `--workspace-id`, if your LangSmith API key requires a
workspace selection.

### Logs

Read the deployed agent's server logs:

```bash
mda logs .
mda logs . --lines 200 --level error
```

In a terminal this streams new output until you press Ctrl-C. When the output is piped or
redirected, it prints the most recent lines (1000 by default) and exits.

### Delete

Remove the deployment and the LangSmith resources it created:

```bash
mda delete .
```

This deletes the deployment, the tracing project created alongside it, the Context Hub repo
holding this agent's context and memory, and the managed sandboxes this agent created. It asks
first; pass `--yes` to skip the prompt. Agent memory and thread history are not recoverable
afterwards.

### Evals

Managed Deep Agent evals are Harbor evals. Author full Harbor tasks directly under
`evals/tasks/<task>/`. To start from a minimal task, run:

```bash
mda evals init my-task
```

This creates the optional scaffold `evals/scaffold/my-task/` with an `instruction.md` and a
language verifier. Run the same command with another name to add more scaffolds. At compile
time MDA copies selected scaffolds to `evals/tasks/` and preserves every other task. Compile
the managed agent, then run Harbor yourself:

```bash
mda evals compile .                 # all tasks
mda evals compile . --task my-task  # only my-task
# follow the printed `harbor run` command
```
