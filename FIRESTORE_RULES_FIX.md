# Firestore Rules Fix for Task System

## Problem
Users were getting permission denied errors when creating tasks:
```
Error creating task for card 44e268ff-2f50-54bb-83f0-b2fe08ed695e: [cloud_firestore/permission-denied] The caller does not have permission to execute the specified operation.
```

## Root Causes

### 1. **Rule Ordering Issue**
The wildcard rule `/{document=**}` was placed before the specific `/tasks` rule, causing it to intercept all requests before the tasks rule could be evaluated.

### 2. **Incorrect Rule Syntax**
The tasks rule was missing the proper document ID pattern:
```javascript
// Wrong - missing {taskId}
match /tasks {
  allow read, write: if request.auth != null;
}

// Correct - includes document ID pattern
match /tasks/{taskId} {
  allow read, write: if request.auth != null;
}
```

### 3. **Overly Restrictive Admin Requirements**
Most collections required admin access, but tasks should be accessible to any authenticated user since they're created automatically during search.

## Solution

### New Rule Structure (in order of priority):

1. **Admins Collection** - No access (security)
```javascript
match /admins/{adminId} {
  allow read, write: if false;
}
```

2. **Tasks Collection** - Full access for authenticated users
```javascript
match /tasks/{taskId} {
  allow read, write: if request.auth != null;
}
```

3. **Cards Collection** - Read for users, write for admins
```javascript
match /cards/{cardId} {
  allow read: if request.auth != null;
  allow write: if request.auth != null 
    && exists(/databases/$(database)/documents/admins/$(request.auth.uid));
}
```

4. **Accounts Collection** - Users can manage their own accounts
```javascript
match /accounts/{userId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}
```

5. **All Other Collections** - Admin access required (catch-all)
```javascript
match /{document=**} {
  allow read: if request.auth != null;
  allow write: if request.auth != null 
    && exists(/databases/$(database)/documents/admins/$(request.auth.uid));
}
```

## Key Improvements

### ✅ **Proper Rule Ordering**
- Specific rules now come before wildcard rules
- Tasks rule is evaluated before the catch-all rule

### ✅ **Correct Document Path Patterns**
- All rules include proper `{documentId}` patterns
- Rules now match the intended document structure

### ✅ **Appropriate Permissions**
- Tasks: Full access for authenticated users (needed for automatic task creation)
- Cards: Read access for users, write access for admins (data integrity)
- Accounts: Users can manage their own accounts
- Everything else: Admin access required (security)

### ✅ **Security Maintained**
- Authentication still required for all operations
- Admin-only access preserved for sensitive collections
- User data isolation maintained for accounts

## Result
The Smart Task Queue System can now:
- ✅ Create tasks during search operations
- ✅ Update task status during processing
- ✅ Clean up completed tasks
- ✅ Allow users to monitor their task progress

The permission denied errors should be resolved, and the task system will work as intended!