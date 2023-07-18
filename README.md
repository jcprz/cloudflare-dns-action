# cloudflare-management-action

This GitHub Action is designed to manage DNS records using the Cloudflare API. You can use it to check if a DNS record exists, create a new DNS record, or delete an existing DNS record.

## Inputs

### `auth-token`

**Required.** This is your authorization token for the Cloudflare API.

### `zone-id`

**Required.** This is the ID of the DNS zone in Cloudflare where the record resides or will be created.

### `record-type`

**Required.** The type of DNS record you wish to manage (e.g., `A`, `CNAME`, `TXT`, etc.).

### `record-name`

**Required.** The name of the DNS record you wish to manage.

### `record-content`

**Required.** The content of the DNS record you wish to manage.

### `action`

**Required.** The action you wish to perform on the DNS record. This can be `check`, `create`, or `delete`.

### `create-if-not-exists`

This is optional. If set to `true` and the `action` is set to `check`, the action will automatically create the record if it does not exist. The default is `false`.

## Example Usage

This is an example of how to use this action in a GitHub Workflow:

```yaml
- name: Manage DNS records
  uses: your-org/manage-dns-action@v1
  with:
    auth-token: ${{ secrets.CLOUDFLARE_API_TOKEN }}
    zone-id: ${{ secrets.CLOUDFLARE_ZONE_ID }}
    record-type: CNAME
    record-name: my.example.com
    record-content: example.com
    action: create
    create-if-not-exists: true
```

In this example, the action will check if a CNAME record for example.com exists. If the record does not exist and create-if-not-exists is set to true, it will create the record.