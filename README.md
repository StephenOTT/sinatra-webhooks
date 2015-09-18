# Sinatra-Webhooks
Sinatra-Webhooks is a simple Sinatra web application that handles GitHub webhooks with HMAC-SHA1 security by listening to the `/webhook` path. It currently only supports the ping and push events. A ping event is initially sent by GitHub to the webhook listener after being configured in the repository's settings. Any detected misconfiguration will be reported back with an appropriate HTTP error code and message. These responses can be seen under the "Recent Deliveries" section for each webhook.

Push events result in a git pull request from the repository and then a Middleman build. The results from both these executions are synchronously returned in the response.

To use the application, the `GITHUB_WEBHOOK_SECRET` environment variable should be defined. A great way to generate a secure secret is to invoke the following shell command:
```shell
ruby -rsecurerandom -e 'puts SecureRandom.hex(30)'
```

Use that token as a secret in the webhook configuration and set the environment variable, where the application is run, with the following command:
```shell
export GITHUB_WEBHOOK_SECRET=your_secret
```

When testing in a [Vagrant](https://www.vagrantup.com/) image, [ngrok](https://ngrok.com/) is a fantastic tool for tunneling to localhost.
