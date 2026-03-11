---
title: "Active Storage Blob Orphaned on User Deletion"
category: database-issues
tags:
  - active-storage
  - blobs
  - user-deletion
  - data-integrity
  - gdpr
  - storage-cleanup
problem_summary: >
  Destroying a User record does not automatically purge associated Active Storage
  blobs and their backing files. The attachment join record is removed, but the
  blob record and the physical file in storage/ remain — causing an orphaned file
  on disk and a GDPR right-to-erasure violation.
affected_versions:
  - Rails 8.1.2
  - Ruby 4.0.1
severity: high
date_added: 2026-03-10
---

# Active Storage Blob Orphaned on User Deletion

## Symptom

After `user.destroy`, the physical file (e.g. `storage/ab/cd/<blob-key>`) still exists on disk. `ActiveStorage::Blob.service.exist?(blob_key)` returns `true`. The blob DB row may also persist. The user's personal data (avatar image) survives account deletion — a GDPR right-to-erasure violation.

## Root Cause

`has_one_attached :avatar` registers an `ActiveStorage::Attachment` with a `dependent: :purge_later` hook. When `user.destroy` cascades, the `Attachment` record is destroyed — but file cleanup is deferred to a background job (`ActiveStorage::PurgeJob`).

In environments where the job queue is not actively processing (Solid Queue idle, job failures, test environment, transaction rollback), the job never fires. The physical file on disk is left behind indefinitely.

## Investigation Steps

The User model before the fix:

```ruby
class User < ApplicationRecord
  has_one_attached :avatar
  # No explicit cleanup — relies on background job to purge the blob
end
```

On `user.destroy`:
- `active_storage_attachments` row: deleted ✅
- `active_storage_blobs` row: may persist (job-dependent) ⚠️
- Physical file at `storage/<prefix>/<key>`: persists ❌

## Working Solution

Add an explicit synchronous purge in a `before_destroy` callback:

```ruby
# app/models/user.rb

class User < ApplicationRecord
  has_one_attached :avatar

  before_destroy :purge_avatar_attachment

  private

  def purge_avatar_attachment
    avatar.purge if avatar.attached?
  end
end
```

`avatar.purge` (synchronous, not `purge_later`) performs both operations inline:

1. Deletes the `active_storage_blobs` row from the database
2. Deletes the physical file from the storage service immediately

The `if avatar.attached?` guard prevents errors for users with no avatar.

### Multiple attachments

```ruby
before_destroy :purge_all_attachments

private

def purge_all_attachments
  avatar.purge    if avatar.attached?
  documents.purge if documents.attached?
end
```

### Key Gotchas

**`purge` vs `purge_later`:** Always use synchronous `purge` in `before_destroy`. `purge_later` enqueues a job — by the time the job runs, the user record is gone and the job may fail silently.

**`before_destroy`, not `after_destroy`:** The callback must run before the user record is destroyed. In `after_destroy`, the association context may no longer be resolvable.

**Double-destroy safety:** `if avatar.attached?` returns `false` after `avatar.purge`, so any subsequent cascade call is a safe no-op.

**Cloud storage:** On local disk, `purge` deletes the file from `storage/`. On S3/GCS/Azure, `purge` issues a DELETE request to the remote service. Same pattern works for all backends.

### Order of operations in full account deletion

```
1. terminate_session      →  invalidate session (must come first)
2. user.destroy
   └── before_destroy     →  avatar.purge  (deletes blob row + physical file)
   └── user row deleted
3. redirect_to root_path
```

See also: `docs/solutions/security-issues/terminate-session-vs-reset-session-account-deletion.md`

## Prevention

### Checklist

- [ ] Every model with `has_one_attached` or `has_many_attached` must have a `before_destroy` purge callback
- [ ] Use `purge` (synchronous), not `purge_later`, for GDPR-relevant deletion
- [ ] Wrap in `avatar.attached?` guard to handle users who never uploaded
- [ ] Write tests asserting both the blob record AND the physical file are gone post-destroy

### Model template checklist

For every new model, verify before merging:

```
[ ] Does this model have has_one_attached / has_many_attached?
      YES → Add before_destroy :purge_<name>_attachment
      YES → Use .purge (not .purge_later) in the callback
      YES → Add .attached? guard
      YES → Write a test: assert blob record gone + physical file gone after destroy
```

### Test Cases

```ruby
# test/models/user_test.rb

test "deleting a user purges the avatar blob from storage" do
  user = users(:alice)
  user.avatar.attach(
    io: File.open("test/fixtures/files/avatar.jpg"),
    filename: "avatar.jpg",
    content_type: "image/jpeg"
  )
  assert user.avatar.attached?

  blob_key = user.avatar.blob.key
  user.destroy

  assert_not ActiveStorage::Blob.exists?(key: blob_key),
    "Blob record must be deleted when user is destroyed"
  assert_not ActiveStorage::Blob.service.exist?(blob_key),
    "Physical file must be deleted from storage when user is destroyed"
end

test "deleting a user with no avatar does not raise" do
  user = users(:bob)  # user who never uploaded an avatar
  assert_not user.avatar.attached?
  assert_nothing_raised { user.destroy }
end
```

### Test storage config

Ensure tests use local disk so `service.exist?` works without hitting remote storage:

```yaml
# config/storage.yml
test:
  service: Disk
  root: <%= Rails.root.join("tmp/storage") %>
```

```ruby
# config/environments/test.rb
config.active_storage.service = :test
```

## Related

- `docs/solutions/security-issues/terminate-session-vs-reset-session-account-deletion.md` — companion issue: session not terminated when user is deleted
