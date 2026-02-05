## Engineering Notes: Design Evolution & Optimization

### Initial Approach
The first implementation used a fully server-driven model:
- The server spawned physical bag parts.
- Bag movement was applied server-side every Heartbeat.
- Clients received continuous transform replication.

This approach was simple and correct functionally, but profiling revealed significant network cost:
- **~12 KB/s send**
- **~40 KB/s receive**
Even with a small number of bags, most traffic came from per-frame transform replication.

---

### Problem Identified
In Roblox, server-owned parts that move every frame replicate their transforms to all clients.
For a deterministic, non-interactive conveyor belt, this was unnecessary overhead.

The system did not require:
- physics interaction
- client authority over motion
- per-frame server reconciliation

---

### Final Optimized Design
The final design separates **authority**, **replication**, and **rendering**:

- The server remains authoritative over:
  - bag creation and deletion
  - BagId identity
  - color/material assignment
  - validation of client interactions
- The server replicates **only bag metadata** via lightweight `BagRecord` folders and attributes.
- Clients render and animate bags locally using:
  - shared conveyor specification
  - server-authored spawn timestamps
  - deterministic motion formulas
- All visual motion, interpolation, and VFX are client-side and non-replicated.

This removes continuous transform replication entirely.

---

### Result
With identical functionality and scope:
- **Network usage dropped to <1 KB/s send and receive**
- Visual smoothness improved due to client-side interpolation
- Server CPU load decreased
- System became easier to reason about and extend

---

The final architecture preserves correctness while significantly improving performance and scalability.
