// הגדרות טכניות של המשחק (לא טקסטים).
export const CONFIG = {
  // סיסמת פאנל האדמין (F9). לשינוי: ערכו כאן והריצו `npm run build` בתיקיית web.
  adminPassword: 'shachar2023',
  adminKey: 'F9',
  // מולטיפלייר
  peerPrefix: 'ad-hazricha-v1-',      // קידומת למזהה PeerJS של המארח
  roomCodeLength: 5,
  roomSizes: [2, 4, 6, 8],
  netTickHz: 15,
  respawnDelay: 4,                     // שניות עד חזרה לצ'קפוינט במולטיפלייר
  // ביצועים
  targetFps: 60,
  shadowMapSize: 2048,
  // נתיבי נכסים (יחסית ל-index.html)
  assetBase: 'assets/',
  textures: ['dry_ground_01', 'sandy_gravel', 'asphalt_02', 'burned_ground_01', 'rough_concrete', 'damaged_plaster', 'wood_planks', 'fabric_pattern_07'],
  hdris: { night: 'moonless_golf', dawn: 'kiara_1_dawn', day: 'kloofendal_misty_morning_puresky' },
};
