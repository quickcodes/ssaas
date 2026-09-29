# Firebase Cloud Firestore Pricing, Free-Tier Limits & Optimization Guide for SSAAS (Flutter)

---

## 1. Current Firestore Free-Tier Limits (Spark Plan)

Firebase Cloud Firestore operates under the **Spark (Free)** plan quotas. These quotas apply at the **Firebase Project level**, meaning all databases, multi-tenant companies, and end-users within the project share this single daily pool.

### Official Spark Plan Quotas

| Metric | Free Tier Daily / Monthly Quota | Scope | Behavior Upon Reaching Limit |
| :--- | :--- | :--- | :--- |
| **Document Reads** | **50,000 / day** | Project | Throws `RESOURCE_EXHAUSTED` (code 8 / HTTP 429). Reads fail until reset. |
| **Document Writes** | **20,000 / day** | Project | Write operations fail with `RESOURCE_EXHAUSTED`. |
| **Document Deletes** | **20,000 / day** | Project | Delete operations fail with `RESOURCE_EXHAUSTED`. |
| **Cloud Storage** | **1 GiB total** | Project | New writes fail when total stored data exceeds 1 GiB. |
| **Network Egress** | **10 GiB / month** | Project | Outbound data transfers blocked when exceeded. |
| **Simultaneous Connections** | **100 concurrent** | Project | 101st active client connection is rejected until a slot frees up. |
| **Write Rate Limit** | **1 write / second / doc** | Single Doc | Higher frequency causes contention and write throttling errors. |

> **Reset Schedule & Scope:**
> * Quotas reset **daily at midnight Pacific Time (00:00 PST / UTC-8)**.
> * There is no monthly cap for reads/writes on Spark (only the 10 GiB/month egress limit and 1 GiB storage limit are cumulative).
> * **Project-Wide Pool:** In SSAAS, multi-tenancy is structured under `companies/{companyId}`. If you have 5 clubs with 10 tables each, all 5 clubs consume the **same 50,000 reads/day**.
>
> *Official References:*
> * [Firebase Pricing & Spark Plan Limits](https://firebase.google.com/pricing)
> * [Cloud Firestore Quotas & Limits](https://cloud.google.com/firestore/quotas)
> * [Understand Cloud Firestore Billing](https://firebase.google.com/docs/firestore/pricing)

---

## 2. How Firestore Operations Are Counted

Firestore does **not** charge by CPU time, query complexity, or bytes transferred (except for egress bandwidth). It bills strictly on **Document Operations**.

### Operational Breakdown

| Operation | How Firestore Counts It | Concrete Example |
| :--- | :--- | :--- |
| **Single Document Read** | 1 read per document returned. | `db.collection('users').doc('u1').get()` = **1 read** |
| **Single Document Write** | 1 write per document created. | `db.collection('users').doc().set({...})` = **1 write** |
| **Document Update** | 1 write per document updated (regardless of how many fields are touched). | `docRef.update({'status': 'occupied'})` = **1 write** |
| **Document Delete** | 1 delete per document removed. | `docRef.delete()` = **1 delete** |
| **Query Returning Documents** | **N reads**, where $N$ is the number of documents matching the query. | Query matching 45 documents = **45 reads** |
| **Empty Query Result** | **1 read** (minimum charge for executing an index lookup with 0 results). | Query matching 0 documents = **1 read** |
| **Aggregation Queries** (`count()`, `sum()`, `average()`) | **1 read per 1,000 index entries scanned** (fractional rounded up). | Counting 2,500 history records = **3 reads** (vs 2,500 reads with `get()`) |
| **Batch Writes** | **1 write per document** in the batch. No discount for batching, but atomic. | A batch modifying 5 documents = **5 writes** |
| **Transactions** | Charged for every document read + every document written/modified. If a transaction retries, reads are charged again. | Read 1 doc, update 1 doc = **1 read + 1 write** |

---

### Understanding the Cache: Network vs Local Operations

```
                   ┌────────────────────────────────────────┐
                   │  Flutter App (Firestore SDK)           │
                   └───────────────────┬────────────────────┘
                                       │
                        Query/Stream Request
                                       │
                                       ▼
                   ┌────────────────────────────────────────┐
                   │  Local IndexedDB / SQLite Cache         │
                   └───────┬────────────────────────┬───────┘
                           │                        │
               Cache Hit (Source.cache)    Cache Miss / Network Check
                           │                        │
                           ▼                        ▼
                   ┌───────────────┐       ┌─────────────────┐
                   │ 0 Reads Billed│       │ Firestore Cloud │
                   │ Free Offline  │       └────────┬────────┘
                   └───────────────┘                │
                                            Billable Reads
```

1. **`GetOptions(source: Source.cache)`**:
   * Reads strictly from the device’s local disk persistence.
   * **Cost: 0 Firestore billable reads.**
2. **`GetOptions(source: Source.server)`**:
   * Bypasses local storage and hits the cloud.
   * **Cost: 1 read per document.**
3. **`GetOptions(source: Source.serverAndCache)` (Default for `get()`)**:
   * Checks server first. If online, fetches from server and updates local cache.
   * **Cost: 1 read per document.**
4. **App Restart / Backgrounding**:
   * When an app is killed and restarted, active listeners are terminated. Upon restart, **all listeners re-initialize**, incurring reads for the initial snapshot unless cached effectively.
   * When an app moves to background and returns within the keep-alive window, the persistent gRPC connection remains active. No re-read penalty occurs.

---

## 3. Real-Time Streams (`snapshots()`) vs One-Time Reads (`get()`)

### Comparison Matrix

```dart
// Option A: One-Time Read
final snap = await FirebaseFirestore.instance.collection('users').get();

// Option B: Real-Time Listener
FirebaseFirestore.instance.collection('users').snapshots().listen((snap) {});
```

| Dimension | One-Time Read (`get()`) | Real-Time Stream (`snapshots()`) |
| :--- | :--- | :--- |
| **Initial Cost** | 1 read per matching document. | 1 read per matching document. |
| **Subsequent Data Changes** | **0 reads** (data remains stale until `get()` is called again). | **1 read per modified, added, or deleted document.** |
| **Unchanged Data Cost** | 0 reads. | **0 reads** (Firestore sends deltas; only mutated docs are read). |
| **Disconnection & Reconnection** | N/A. | If connection drops and reconnects within 30 min, Firestore sends a token and reads **only what changed** while disconnected. |
| **Navigation Lifecycle** | Executes once per screen visit. | Keeps listening forever until `.cancel()` is called. |

---

### Case Study: 1,000 Documents & 100 Connected Users

Assume a collection `companies/{companyId}/tablesHistory` contains **1,000 documents**, and **100 users** are active on the floor.

#### Scenario 1: Initial Stream Attachment
* Every user opens the screen listening to `tablesHistory.snapshots()`.
* **Formula:** $\text{Users} \times \text{Documents in Collection} = 100 \times 1,000$
* **Total Reads:** **100,000 reads** (Instantly exhausts the 50k Free Tier by 200%).

#### Scenario 2: 1 Document is Modified
* An operator closes a match or updates a record.
* **Formula:** $\text{Listeners} \times \text{Changed Documents} = 100 \times 1$
* **Total Reads:** **100 reads**.

#### Scenario 3: 10 Documents Change Simultaneously
* 10 matches finish or are updated concurrently.
* **Formula:** $\text{Listeners} \times \text{Changed Documents} = 100 \times 10$
* **Total Reads:** **1,000 reads**.

#### Scenario 4: User Disconnects and Reconnects
* If the user experiences a network flap (< 30 minutes) and 5 documents changed while offline:
  * Firestore uses the query token.
  * **Reads incurred:** **5 reads** (not 1,000).
* If the app was closed, killed, or navigated away from without state caching:
  * Re-opening the screen triggers a fresh initial snapshot: **1,000 reads**.

#### Scenario 5: Same User Opens App on Multiple Devices
* 2 tablets or phones running the listener simultaneously count as **2 independent listeners**.
* Each receives its own snapshot ($2 \times 1,000 = 2,000\text{ reads}$) and each receives mutation deltas.

---

## 4. User-Based Capacity on Free Tier

Let us calculate practical capacity using the **50,000 reads / 20,000 writes** daily ceiling.

### Usage Profile Benchmarks

| Persona | Daily Reads / User | Daily Writes / User | Description |
| :--- | :--- | :--- | :--- |
| **Light User** | 100 reads | 5 writes | Occasional lookup, checks 1-2 tables, few matches. |
| **Medium User** | 500 reads | 20 writes | Active operator, checks dashboard, records 5-10 matches, canteen items. |
| **Heavy User** | 2,000 reads | 100 writes | Busy venue manager, repeatedly viewing unpaginated history, modifying rates. |

---

### Capacity Calculations (Daily Maxima)

$$\text{Max Users Supported} = \min\left(\frac{50,000}{\text{Reads per User}}, \frac{20,000}{\text{Writes per User}}\right)$$

| Usage Tier | Constrained By | Max Active Users / Day on Free Tier |
| :--- | :--- | :--- |
| **Light Usage** (100 R / 5 W) | Reads ($50,000 / 100$) | **500 Users** |
| **Medium Usage** (500 R / 20 W) | Reads ($50,000 / 500$) | **100 Users** |
| **Heavy Usage** (2,000 R / 100 W) | Reads ($50,000 / 2,000$) | **25 Users** |

---

### Scaling Matrix: Projected Daily Operations vs Free Tier

| Total Users | Light Usage (100 R / 5 W) | Medium Usage (500 R / 20 W) | Heavy Usage (2,000 R / 100 W) | Free Tier Status |
| :--- | :--- | :--- | :--- | :--- |
| **100** | 10k R / 500 W | 50k R / 2,000 W | 200k R / 10,000 W | ⚠️ **Breaks at Heavy** (Reads: 400% of quota) |
| **500** | 50k R / 2.5k W | 250k R / 10,000 W | 1,000k R / 50,000 W | 🚨 **Breaks at Medium & Heavy** |
| **1,000** | 100k R / 5k W | 500k R / 20,000 W | 2,000k R / 100,000 W | 🚨 **Breaks at all tiers** |
| **5,000** | 500k R / 25k W | 2,500k R / 100k W | 10,000k R / 500k W | 🚨 **Requires Blaze Plan** |
| **10,000** | 1,000k R / 50k W | 5,000k R / 200k W | 20,000k R / 1,000k W | 🚨 **Requires Blaze Plan** |

> **Key Takeaway:** Under unoptimized architectures where users listen to entire collections without limits, **as few as 10 to 25 concurrent operators can exhaust the entire daily quota in under 2 hours.**

---

## 5. Real-Time Chat & Subcollection Architecture Case Study

Consider a real-time messaging subcollection:
```text
chats/{chatId}/messages/{messageId}
```
Suppose a chat contains **100 messages**, and **2 users** (Operator A and Customer/Operator B) are in the room.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        ARCHITECTURAL COMPARISON                        │
├───────────────────────────────────┬────────────────────────────────────┤
│   Architecture A: Unbounded       │   Architecture B: Limited / Window │
│   .collection('messages')         │   .orderBy('timestamp', desc: true)│
│   .snapshots()                    │   .limit(20).snapshots()           │
├───────────────────────────────────┼────────────────────────────────────┤
│ • Initial load: 100 reads/user    │ • Initial load: 20 reads/user      │
│ • 2 users = 200 reads             │ • 2 users = 40 reads               │
│ • New message = 2 reads           │ • New message = 2 reads            │
│ • Total for 5 msgs = 210 reads    │ • Total for 5 msgs = 50 reads      │
│ • Savings: Baseline               │ • Savings: 76.2% reduction         │
└───────────────────────────────────┴────────────────────────────────────┘
```

### Detailed Event Walkthrough

| Event | Architecture A (Unbounded: all 100 msgs) | Architecture B (Optimized: `limit(20)`) |
| :--- | :--- | :--- |
| **User A enters chat** | 100 reads | **20 reads** |
| **User B enters chat** | 100 reads | **20 reads** |
| **User A sends Message #101** | User A: 1 write<br>User A listener: 1 read<br>User B listener: 1 read<br>**Total: 1 write, 2 reads** | User A: 1 write<br>User A listener: 1 read<br>User B listener: 1 read<br>**Total: 1 write, 2 reads** |
| **User B sends Message #102** | 1 write, 2 reads | 1 write, 2 reads |
| **User A scrolls up for older messages** | 0 additional reads (already in memory) | Fetches next 20 via `.startAfterDocument()`: **20 reads** |
| **Summary after 10 messages** | **10 writes, 220 reads** | **10 writes, 60 reads** |

> **Conclusion:** Constraining real-time listeners with `.limit(N)` produces immediate **70%–80% read reductions** on initial load while maintaining identical real-time responsiveness.

---

## 6. Core Optimization Strategies for Flutter & Firestore

```
┌────────────────────────────────────────────────────────────────────────────────────┐
│                             OPTIMIZATION TOOLBOX                                   │
├──────────────────────────────────┬─────────────────┬───────────────────────────────┤
│ Optimization Technique           │ Potential Gain  │ Primary Trade-off             │
├──────────────────────────────────┼─────────────────┼───────────────────────────────┤
│ Cursor Pagination (`limit(N)`)   │ 80%–95% Reads   │ Requires scroll listeners     │
│ Count Aggregations (`count()`)   │ 99.9% Reads     │ Aggregation result is snapshot│
│ BLoC / Global In-Memory Caching  │ 70%–90% Reads   │ Must manage cache invalidation│
│ One-Time `get()` for Static Data │ 50%–80% Reads   │ No push updates on change     │
│ Cancel Stream Subscriptions      │ Eliminates Leak │ Requires `dispose()` lifecycle│
│ Batched Writes & Updates         │ Conserves Net   │ 1 write cost still applies    │
│ Cloud Functions Counters         │ 95% Reads       │ Cloud Functions invocation fee│
└──────────────────────────────────┴─────────────────┴───────────────────────────────┘
```

1. **Cursor-Based Pagination (`startAfterDocument`)**:
   Never execute open-ended queries on unbounded transaction/history tables. Load the most recent 15–20 records first.
2. **Firestore Count Queries (`AggregateQuery.count()`)**:
   Instead of downloading 5,000 documents to display `"5,000 matches recorded"`, use `query.count().get()`. Firestore counts **1 read per 1,000 documents** indexed, costing 5 reads instead of 5,000.
3. **Local In-Memory Cache via BLoC**:
   Keep live streams in singleton BLoCs initialized once at login and shared across all child views. Do not re-attach streams in widget `initState` or `build` methods.
4. **Denormalization / Aggregation Documents**:
   Instead of querying all table history records to compute total daily revenue, maintain a single daily summary document (`companies/{id}/dailyStats/{yyyyMMdd}`) updated at match checkout. Reading 1 document replaces reading hundreds of records.

---

## 7. Deep-Dive Audit of the SSAAS Codebase

An inspection of our current Flutter codebase reveals specific areas where Firestore reads and writes can be significantly optimized.

---

### Issue 1: Unbounded Stream in History View

#### Current Code
In `lib/presentation/views/history/tables_history_view.dart`:
```dart
StreamBuilder<List<TableHistoryRecord>>(
  stream: sl<FirestoreService>().watchTablesHistory(companyId),
  builder: (context, snapshot) { ... }
)
```
In `lib/data/datasources/firestore_service.dart`:
```dart
Stream<List<TableHistoryRecord>> watchTablesHistory(String companyId) {
  return _historyCol(companyId)
      .orderBy('closedAt', descending: true)
      .snapshots()
      .map((snapshot) => ...);
}
```

#### Why It Is Inefficient
1. **Unbounded Collection Scan:** Every time an operator navigates to the "History" tab, **all** history records ever recorded for that company are read. If a club has 2,000 matches, opening the tab costs **2,000 reads** every time.
2. **Stream Recreation in `build()`:** Calling `watchTablesHistory(companyId)` directly inside `build()` instantiates a new stream whenever search text or filters change via `setState`, risking repeated query evaluations.

#### Recommended Approach
1. Paginate with `.limit(25)` for the list view.
2. Replace full-collection math (`fold`) for total match count and revenues with server aggregation queries (`.count()`) or daily stat summaries.

#### Improved Flutter Code

```dart
// lib/data/datasources/firestore_service.dart

// 1. Paginated Query with Cursor
Future<List<TableHistoryRecord>> getTablesHistoryPaged({
  required String companyId,
  int limit = 25,
  DocumentSnapshot? startAfter,
}) async {
  var query = _historyCol(companyId)
      .orderBy('closedAt', descending: true)
      .limit(limit);

  if (startAfter != null) {
    query = query.startAfterDocument(startAfter);
  }

  final snapshot = await query.get();
  return snapshot.docs
      .map((doc) => TableHistoryRecord.fromMap(doc.id, doc.data()))
      .toList();
}

// 2. Ultra Low-Cost Count Aggregation (1 read per 1,000 items)
Future<int> getTableHistoryTotalCount(String companyId) async {
  final aggregateSnap = await _historyCol(companyId).count().get();
  return aggregateSnap.count ?? 0;
}
```

---

### Issue 2: Stream Listener Leak in Floor Matrix View

#### Current Code
In `lib/presentation/views/floor_matrix/floor_matrix_view.dart`:
```dart
void _loadCanteenStock() {
  final companyId = context.read<AuthBloc>().state.activeCompany?.id;
  if (companyId != null) {
    sl<FirestoreService>().watchFoodCanteen(companyId).listen((items) {
      if (mounted) {
        setState(() => _canteenItems = items);
      }
    });
  }
}
```

#### Why It Is Inefficient
The `StreamSubscription` returned by `.listen()` is **never assigned or canceled in `dispose()`**. Every time the user navigates between the floor matrix, history, and settings, a new listener is spawned. The abandoned listeners continue running in memory, consuming Firestore reads for every canteen stock update.

#### Recommended Approach
Store the `StreamSubscription` and cancel it in `dispose()`, or manage canteen items inside an existing BLoC.

#### Improved Flutter Code

```dart
// lib/presentation/views/floor_matrix/floor_matrix_view.dart

StreamSubscription<List<StockItem>>? _canteenSub;

@override
void initState() {
  super.initState();
  _loadCanteenStock();
}

void _loadCanteenStock() {
  final companyId = context.read<AuthBloc>().state.activeCompany?.id;
  if (companyId != null) {
    _canteenSub?.cancel();
    _canteenSub = sl<FirestoreService>()
        .watchFoodCanteen(companyId)
        .listen((items) {
      if (mounted) {
        setState(() => _canteenItems = items);
      }
    });
  }
}

@override
void dispose() {
  _canteenSub?.cancel(); // Critical: stops leaking Firestore reads!
  super.dispose();
}
```

---

### Issue 3: Full Company User Scan During Login

#### Current Code
In `lib/data/datasources/firestore_service.dart`:
```dart
Future<UserAccount?> loginUser(
  String companyId,
  String emailOrNumber,
  String password,
) async {
  final normalized = emailOrNumber.trim().toLowerCase();
  final users = await getCompanyUsers(companyId); // Downloads ALL users!
  try {
    final user = users.firstWhere(
      (u) =>
          (u.email.toLowerCase() == normalized || u.number.trim() == normalized) &&
          u.password == password,
    );
    return user;
  } catch (_) {
    return null;
  }
}
```

#### Why It Is Inefficient
Calling `getCompanyUsers(companyId)` fetches every operator registered under that company. If a club has 20 staff accounts, signing in consumes **20 reads** instead of **1 read**.

#### Recommended Approach
Execute a targeted query using `.where()` with `.limit(1)`.

#### Improved Flutter Code

```dart
// lib/data/datasources/firestore_service.dart

Future<UserAccount?> loginUser(
  String companyId,
  String emailOrNumber,
  String password,
) async {
  final normalized = emailOrNumber.trim().toLowerCase();
  final usersCol = _usersCol(companyId);

  // Check email match (1 read)
  var query = await usersCol
      .where('email', isEqualTo: normalized)
      .where('password', isEqualTo: password)
      .limit(1)
      .get();

  // Fallback to phone number match if email wasn't found (1 read)
  if (query.docs.isEmpty) {
    query = await usersCol
        .where('number', isEqualTo: emailOrNumber.trim())
        .where('password', isEqualTo: password)
        .limit(1)
        .get();
  }

  if (query.docs.isNotEmpty) {
    final doc = query.docs.first;
    return UserAccount.fromMap(doc.id, doc.data());
  }
  return null;
}
```
*Savings: Drops read cost from $N$ users down to exactly **1 read** (or 2 if falling back to phone).*

---

### Issue 4: Dev Analytics Screen Live Nesting

#### Current Code
In `lib/presentation/views/admin/dev_analytics_dashboard_screen.dart`:
```dart
StreamBuilder<List<Company>>
  └─ For each Company:
       ├─ StreamBuilder<List<UserAccount>>(watchCompanyUsers(c.id))
       ├─ StreamBuilder<List<ClubTable>>(watchTables(c.id))
       └─ StreamBuilder<List<TableHistoryRecord>>(watchTablesHistory(c.id))
```

#### Why It Is Inefficient
If the dev admin has registered 15 companies with 10 tables, 5 users, and 200 history records each:
Opening the Dev Analytics screen opens **46 simultaneous live Firestore streams** ($1 + 15 \times 3$), downloading over **3,200 documents** on initial mount.

#### Recommended Approach
1. Only attach sub-collection streams/queries when a specific company card is **expanded by the user** (on-demand loading).
2. Avoid streaming `watchTablesHistory` in the card preview; load summary statistics using `get()` or count aggregations.

---

## 8. Recommended Architecture for Minimizing Firestore Usage

```
┌────────────────────────────────────────────────────────────────────────┐
│               RECOMMENDED LOW-READ FIRESTORE PIPELINE                  │
├────────────────────────────────────────────────────────────────────────┤
│                                                                        │
│   1. Real-Time Streams (Strictly for live collaborative states):       │
│      • companies/{id}/snookerTables (10–15 tables = 10–15 docs)        │
│      • companies/{id}/runningTables (Active matches only = 2–8 docs)   │
│      • companies/{id}/reminders (Only reminders due soon = 1–3 docs)   │
│                                                                        │
│   2. One-Time On-Demand Reads (With Pagination & Limit):               │
│      • companies/{id}/tablesHistory .limit(20)                         │
│      • companies/{id}/canteenItems (Fetch once on tab open)            │
│      • Login authentication .where('email', ...).limit(1)              │
│                                                                        │
│   3. Local Cache-First In-Memory Layer (BLoC):                         │
│      • AuthBloc holds active company profile & user session in memory  │
│      • FloorMatrixBloc holds live table state across all screens       │
│      • Navigation between tabs NEVER re-instantiates Firestore queries │
│                                                                        │
│   4. Aggregated Server Calculations:                                   │
│      • Use query.count().get() for analytics numbers                   │
│                                                                        │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 9. Summary & Action Plan

| Priority | Action Item | Target File | Impact |
| :---: | :--- | :--- | :--- |
| 🔴 **High** | Add pagination (`.limit(20)`) to `tablesHistory` | `firestore_service.dart`<br>`tables_history_view.dart` | **Saves 80%–95% of daily reads** as match history grows. |
| 🔴 **High** | Cancel `watchFoodCanteen` subscription in `dispose()` | `floor_matrix_view.dart` | Eliminates memory/read leak across screen navigations. |
| 🟡 **Medium** | Target `loginUser` query with `.where().limit(1)` | `firestore_service.dart` | Reduces login read cost to 1 document. |
| 🟡 **Medium** | Lazy-load subcollections in Dev Admin screen | `dev_analytics_dashboard_screen.dart` | Avoids launching dozens of simultaneous streams. |
| 🟢 **Low** | Use `query.count().get()` for history totals | `tables_history_view.dart` | Converts thousands of reads into 1–2 aggregation reads. |

By implementing these optimizations, SSAAS can comfortably support **200 to 500 active operators daily within Firebase's 100% Free Spark Tier** without risking quota exhaustion or service interruptions.
