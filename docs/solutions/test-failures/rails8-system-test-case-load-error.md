---
title: "LoadError: cannot load application_system_test_case when file is in test/system/"
date: "2026-03-06"
category: "test-failures"
tags:
  - rails
  - minitest
  - system-tests
  - capybara
  - load-path
symptoms:
  - "LoadError: cannot load such file -- application_system_test_case"
  - "System tests fail immediately on require"
  - "NameError: uninitialized constant ApplicationSystemTestCase"
environment: "Rails 8.1.2, Minitest, Capybara + Selenium headless Chrome"
related_files:
  - test/application_system_test_case.rb
  - test/system/
---

# LoadError: application_system_test_case.rb in wrong directory

## Symptom

Running `bin/rails test:system` raises:

```
LoadError: cannot load such file -- application_system_test_case
```

## Root Cause

`application_system_test_case.rb` was placed in `test/system/` instead of `test/`. Rails only adds `test/` to the load path — subdirectories like `test/system/` are not on it. The `require "application_system_test_case"` in system tests cannot find the file.

## Fix

Move the file from `test/system/` to `test/`:

```bash
mv test/system/application_system_test_case.rb test/application_system_test_case.rb
```

Correct structure:

```
test/
├── application_system_test_case.rb   ← correct location
├── test_helper.rb
└── system/
    └── home_test.rb
```

## Prevention

`application_system_test_case.rb` always lives in `test/` — same level as `test_helper.rb`. This is the Rails convention. When in doubt, check the [Rails guides on system testing](https://guides.rubyonrails.org/testing.html#system-testing).

## Verification

```bash
ls test/application_system_test_case.rb   # should exist here
bin/rails test:system                      # should exit 0
```

---
*Encountered during Phase 01-foundation — 2026-03-06*
