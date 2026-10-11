-- Unreleased mesh-to-item database. ESP already labels unknown meshes
-- "Dropped Item". Keep that fallback instead of fabricating item IDs.
warn("[Project Rain] Mesh database unavailable; dropped items use generic labels.");
return {};
