from langchain.tools import tool
from managed_deepagents import define_deep_agent


@tool
def email_report(to: str, subject: str, body: str) -> str:
    """Email a report to a stakeholder. This simulates a send, no network call is made."""
    return f"Emailed {to}: {subject}"


agent = define_deep_agent(
    name="dvd-rental-analyst",
    model="anthropic:claude-sonnet-5",
    tools=[email_report],
)
