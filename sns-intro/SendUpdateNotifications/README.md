# SendUpdateNotifications Lambda

Build and package (Linux/macOS) to a zip suitable for AWS Lambda:

```bash
cd SendUpdateNotifications
dotnet publish -c Release -o ./publish
cd publish
zip -r ../SendUpdateNotifications.zip *
cd ..
```

The produced `SendUpdateNotifications.zip` should be referenced by `lambda_zip_path` in the Terraform `main.tf`.

The Lambda reads environment variables `USER_TOPIC_ARN` and `PRODUCTS_TOPIC_ARN` to know where to publish.
