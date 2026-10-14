from managed_deepagents import define_schedule

# conversation_id is the Slack Channel ID; thread_id is the ts of the message
# whose thread the reports reply in. Replace both with your own before deploying.
schedule = define_schedule(
    cron="*/5 * * * *",
    prompt="Summarize revenue for the last 7 days in 2 sentences. Lead with the total.",
    deliver_to={
        "channel": "slack",
        "to": {
            "type": "provider_thread",
            "conversation_id": "C0C8B887HTN",
            "thread_id": "1728480000.123456",
        },
    },
)
