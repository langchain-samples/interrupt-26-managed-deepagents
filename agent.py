from langchain.tools import tool
from managed_deepagents import define_deep_agent


@tool
def format_currency(amount: float) -> str:
    """Format a raw number as a US dollar amount, e.g. 1234.5 -> "$1,234.50"."""
    return f"${amount:,.2f}"


agent = define_deep_agent(
    name="dvd-rental-analyst",
    model="anthropic:claude-sonnet-5",
    tools=[format_currency],
)
