PulsarStore.Language:Language("en", 1)
    :Set("hello", "Hello")

    -- Errors
    :Set("error", "Error")
    :Set("error.permissions", "Insufficient Permissions")
    :Set("error.permissions.message", "You do not have permission to do that.")
    :Set("error.ratelimit", "You are sending too many requests. Please wait a few seconds and try again.")
:Register()
