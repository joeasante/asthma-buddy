---
status: pending
priority: p2
issue_id: "220"
tags: [security, data-integrity, rails, gdpr, code-review]
dependencies: []
---

# Active Storage Avatar Blobs Orphaned on Account Deletion

## Problem Statement

`Current.user.destroy` deletes the `active_storage_attachments` and `active_storage_blobs` DB rows via cascade, but does NOT delete the physical avatar file from disk (the `storage/` directory). Active Storage purge (which removes the actual file) requires calling `blob.purge` or `blob.purge_later`. The plain `dependent: :destroy` cascade on the association does not trigger this.

For a health app with GDPR obligations and explicit "all data permanently erased" promises, leaving the file on disk is a data retention violation. The file persists indefinitely in `storage/` with no DB reference pointing to it — an orphaned blob with no mechanism for cleanup.

## Findings

**Flagged by:** security-sentinel

**Location:**
- `app/models/user.rb`: `has_one_attached :avatar` with no explicit purge lifecycle

**Behaviour:**
- `user.destroy` triggers `ActiveStorage::Attachment` destroy, which deletes DB rows in `active_storage_attachments` and `active_storage_blobs`
- The physical file in `storage/` is never deleted
- No background job or lifecycle hook calls `blob.purge` or `blob.purge_later`

## Proposed Solutions

### Option A — `before_destroy` callback (Recommended)

Add a `before_destroy` callback to the `User` model:

```ruby
before_destroy :purge_avatar

private

def purge_avatar
  avatar.purge if avatar.attached?
end
```

**Pros:** Simple, explicit, runs synchronously before the record is destroyed. Guaranteed to fire on every destroy path.
**Cons:** Adds latency to the destroy call (file I/O). For large avatars or slow disk this is minor.
**Effort:** Small
**Risk:** Low

### Option B — `dependent: :purge_all` on the attachment

Rails 7.1+ introduced `dependent: :purge_all` as an option on `has_one_attached` / `has_many_attached`. Verify availability in Rails 8.1.2 and use:

```ruby
has_one_attached :avatar, dependent: :purge_all
```

**Pros:** Single-line change; declarative.
**Cons:** Must confirm the option exists and behaves correctly in the Rails 8.1.2 version in use. Less visible than an explicit callback.
**Effort:** Small
**Risk:** Low — but requires verification

### Option C — Purge inside `AccountDeletionJob`

If a background job is adopted for account deletion (see todo 224), add blob purge to the job before `user.destroy`:

```ruby
user.avatar.purge if user.avatar.attached?
user.destroy
```

**Pros:** Consistent with async deletion pattern.
**Cons:** Only works if the background job approach is adopted. Not a standalone fix.
**Effort:** Medium (depends on todo 224)
**Risk:** Medium — dependent on another change

## Recommended Action

Option A — add `before_destroy :purge_avatar` to `User`. It is the simplest, most explicit, and does not depend on other changes.

## Technical Details

**Affected files:**
- `app/models/user.rb`

**Acceptance Criteria:**
- [ ] Avatar file is physically removed from `storage/` when user account is deleted
- [ ] `avatar.purge` or `avatar.purge_later` is called as part of the destroy lifecycle
- [ ] Test confirms blob file does not exist after account deletion

## Work Log

- 2026-03-10: Identified by security-sentinel in Phase 16 code review.

## Resources

- Active Storage purge docs: https://guides.rubyonrails.org/active_storage_overview.html#removing-files
- GDPR Article 17 — Right to erasure
